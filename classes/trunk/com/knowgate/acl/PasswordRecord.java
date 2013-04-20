/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

package com.knowgate.acl;

import java.security.AccessControlException;

import java.io.IOException;
import java.io.Serializable;
import java.io.UnsupportedEncodingException;

import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import java.util.Date;
import java.util.ArrayList;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Base64Decoder;
import com.knowgate.misc.Base64Encoder;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipergate.Category;

public class PasswordRecord extends DBPersist {

  private static final long serialVersionUID = 5L;

  private String sRC4Key;
  
  private ArrayList<PasswordRecordLine> aRecordLines;

  public PasswordRecord() {
    super(DB.k_user_pwd, "PasswordRecord");
  	aRecordLines = new ArrayList<PasswordRecordLine>();
  }
  
  public PasswordRecord(String sKey) {
    super (DB.k_user_pwd, "PasswordRecord");
  	aRecordLines = new ArrayList<PasswordRecordLine>();
  	setKey(sKey);  	
  }
  
  public void setKey (String sKey) throws NullPointerException {
    if (null==sKey) throw new NullPointerException("PasswordRecord.setKey() Key value may not be null");
    sRC4Key = sKey;
  }

  public Object getValueOf (String sLineId) throws ClassNotFoundException, IOException {
  	Object oVal = null;
  	for (PasswordRecordLine rcl : aRecordLines) {
	  if (rcl.getId().equals(sLineId)) {
		switch (rcl.getType()) {
		  case PasswordRecordLine.TYPE_BIN:
			if (rcl.getFileName()==null)
			  oVal = rcl.getBinaryValue();
			else if (rcl.getFileName().equals("null"))
			  oVal = rcl.getBinaryValue();
			else {
		      Class oCls = null;
			  try {
				  oCls = Class.forName(rcl.getFileName());
			  } catch (ClassNotFoundException e) {
				oVal = rcl.getBinaryValue();
			  }
			  if (oCls!=null)
				oVal = rcl.getObjectValue();
			}
		    break;
		  default:
			oVal = rcl.getValue();
			break;
		}
	  	if (oVal!=null) break;
	  } // fi
  	} // next
  	return oVal;
  } // getValueOf

  public PasswordRecordLine getLine (String sLineId) {
    for (PasswordRecordLine rcl : aRecordLines) {
	  if (rcl.getId().equals(sLineId))
		return rcl;
	} // next
	return null;
  } // getLine
  
  public PasswordRecordLine addLine(String sId, char cType, String sLabel) {
	PasswordRecordLine aNewLine = new PasswordRecordLine(sId, cType, sLabel);
	aRecordLines.add(aNewLine);
	return aNewLine;
  }

  public PasswordRecordLine addLine(String sId, char cType, String sLabel, String sValue) {
	PasswordRecordLine aNewLine = new PasswordRecordLine(sId, cType, sLabel, sValue);
	aRecordLines.add(aNewLine);
	return aNewLine;
  }

  public PasswordRecordLine addLine(String sId, char cType, String sLabel, byte[] aValue) {
	PasswordRecordLine aNewLine = new PasswordRecordLine(sId, cType, sLabel);
	aNewLine.setBinaryValue(sId, aValue);
	aRecordLines.add(aNewLine);
	return aNewLine;
  }

  public PasswordRecordLine addLine(String sId, String sLabel, Serializable oValue) throws IOException {
	PasswordRecordLine aNewLine = new PasswordRecordLine(sId, PasswordRecordLine.TYPE_BIN, sLabel);
	aNewLine.setObjectValue(oValue);
	aRecordLines.add(aNewLine);
	return aNewLine;
  }
  
  public ArrayList<PasswordRecordLine> lines() {
    return aRecordLines;
  }
  
  protected void parse() throws ArrayIndexOutOfBoundsException,AccessControlException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin Passwordrecord.parse()");
  	  DebugFile.incIdent();
  	}

  	  if (!isNull("tx_lines")) {
  	  	
  	    String sLines;
  	    String[] aLines = null;
  	    final String sEncMethod = getStringNull(DB.id_enc_method,"RC4");

  	    if (DebugFile.trace) {
  	      DebugFile.writeln("id_enc_method="+sEncMethod);
  	    }

  	    if (sEncMethod.equalsIgnoreCase("RC4")) {
  	      byte[] byLines = Base64Decoder.decodeToBytes(getString(DB.tx_lines));
  	  	  try {
  	  	    sLines = new String(new RC4(sRC4Key).rc4(byLines),"UTF-8");
  	  	  } catch (UnsupportedEncodingException neverthrown) { sLines = ""; }
  	  	  aLines = Gadgets.split(sLines,'\n');
  	    } else if (sEncMethod.equalsIgnoreCase("NONE")) {
  	      aLines = Gadgets.split(getString(DB.tx_lines),'\n');
  	    } // fi

  	  	if (aLines!=null) {

  	  	  if (!aLines[0].startsWith("# Password record")) {
  	        if (DebugFile.trace) {
  	          DebugFile.writeln("AccessControlException Invalid password or encryption method");
  	          DebugFile.decIdent();
  	        }
  	  	  	throw new AccessControlException("Invalid password or encryption method"); 
  	  	  } // fi # Password record

  	  	  for (int l=1; l<aLines.length; l++) {
  	  		if (aLines[l].trim().length()>0) {
  	  	      String[] aLine = Gadgets.split(aLines[l],'|');
  	  	      if (aLine.length<3)
  	  	    	throw new ArrayIndexOutOfBoundsException("Parsing line "+String.valueOf(l)+" "+aLines[l]);
  	  	      PasswordRecordLine oRecLin = new PasswordRecordLine(aLine[0],aLine[1].charAt(0),aLine[2]);
  	  	      if (aLine[1].charAt(0)==PasswordRecordLine.TYPE_BIN) {
  	  	    	int i2ndSlash = aLine[3].indexOf('/',1);    	  	    	  
  	  	        oRecLin.setFileName(aLine[3].substring(1, i2ndSlash));
  	  	        oRecLin.setValue(aLine[1].charAt(0), aLine[3].substring(++i2ndSlash));
  	  	      } else {
  	  	        oRecLin.setValue(aLine[1].charAt(0), aLine[3]);
  	  	      }
  	  	      aRecordLines.add(oRecLin);
  	  		} //fi
  	  	  } // next

  	  	} // fi (aLines)
  	  } // fi (tx_lines)

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End Passwordrecord.parse()");
  	}
  } // parse

  public boolean load (JDCConnection oConn, Object[] aPK)
  	throws SQLException, AccessControlException {
	boolean bRetVal = false;
	String sPK = null;
  	if (aPK.length==1) {
	  bRetVal = super.load(oConn, aPK);
      aRecordLines.clear();
	  if (bRetVal) parse();
  	} else if (aPK.length==2) {
  	  PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_pwd+" FROM "+DB.k_user_pwd+" WHERE "+DB.gu_user+"=? AND ("+DB.tl_pwd+"=? OR "+DB.id_pwd+"=?)");
  	  oStmt.setObject(1, aPK[0], Types.CHAR);
  	  oStmt.setObject(2, aPK[1], Types.CHAR);
  	  oStmt.setObject(3, aPK[1], Types.CHAR);
  	  ResultSet oRSet = oStmt.executeQuery();
  	  if (oRSet.next())
  	    sPK = oRSet.getString(1);
  	  oRSet.close();
  	  oStmt.close();
  	  if (sPK!=null) bRetVal = load(oConn, new Object[]{sPK});
  	}
  	return bRetVal;
  } // load

  public boolean load (JDCConnection oConn, String sPk)
  	throws SQLException, AccessControlException {
  	return load(oConn, new Object[]{sPk});
  }
  	
  public boolean store (JDCConnection oConn)
  	throws SQLException, AccessControlException, IllegalArgumentException, NullPointerException {

	boolean bIsNew = isNull(DB.gu_pwd);
	if (!bIsNew) bIsNew = !exists(oConn);

  	if (isNull(DB.gu_pwd)) {
  	  put (DB.gu_pwd, Gadgets.generateUUID());
  	}
  	
  	StringBuffer oLines = new StringBuffer("# Password record v5.0\n");
  	int nLines = 0;
  	for (PasswordRecordLine rcl : aRecordLines) {
  	  if (++nLines>1) oLines.append("\n");
  	  oLines.append(rcl.toString());
  	} // next
  	  
  	if (!bIsNew) {
  	  replace(DB.dt_modified, new Timestamp(new Date().getTime()));
  	}
 
 	if (isNull(DB.id_enc_method)) put(DB.id_enc_method, "RC4");
 	
 	if (getString(DB.id_enc_method).equalsIgnoreCase("RC4")) {
      if (null==sRC4Key) throw new NullPointerException("PasswordRecord.store() RC4 Key value may not be null");
  	  try {
  	  	RC4 oRc4 = new RC4(sRC4Key);
  	    replace(DB.tx_lines, Base64Encoder.encode(oRc4.rc4(Gadgets.dechomp(oLines.toString(),'\n').getBytes("UTF-8"))));
      } catch (UnsupportedEncodingException neverthrown) { }
 	}
    else if (getString(DB.id_enc_method).equalsIgnoreCase("NONE"))
      replace(DB.tx_lines, Gadgets.dechomp(oLines.toString(),'\n'));
	else {
	  throw new IllegalArgumentException("Invalid encoding method "+getString(DB.id_enc_method));
	}

    boolean bRetVal = super.store(oConn);
    
    if (bIsNew) {
      String sCatName;

	  sCatName = DBCommand.queryStr(oConn, "SELECT d."+DB.nm_domain+",'_',u."+DB.tx_nickname+",'_pwds' FROM "+DB.k_domains+" d,"+DB.k_users+" u WHERE d."+DB.id_domain+"=u."+DB.id_domain+" AND u."+DB.gu_user+"='"+getString(DB.gu_user)+"'");
			
	  String sPwdsCat = DBCommand.queryStr(oConn, "SELECT "+DB.gu_category+" FROM "+DB.k_categories+" c, " + DB.k_cat_tree+ " t WHERE c."+DB.gu_category+"=t."+DB.gu_child_cat+" AND t."+DB.gu_parent_cat+" IN (SELECT "+DB.gu_category+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+getString(DB.gu_user)+"') AND c."+DB.nm_category+"='"+sCatName+"'");
      
      if (null!=sPwdsCat) {
        Category oPwdsCat = new Category(sPwdsCat);
        Integer oPos = DBCommand.queryMaxInt(oConn, DB.od_position, DB.k_x_cat_objs,
        									 DB.gu_category+"='"+sPwdsCat+"'");
        if (null==oPos) oPos = new Integer(1); else oPos = new Integer(oPos.intValue()+1);
        oPwdsCat.addObject(oConn, getString(DB.gu_pwd), ClassId, 0, oPos.intValue());
      } // fi
    } // fi
    return bRetVal;
  } // store

  public boolean store (JDCConnection oConn, String sGuCategory)
  	throws SQLException, AccessControlException, IllegalArgumentException, NullPointerException {

	boolean bIsNew = isNull(DB.gu_pwd);
	if (!bIsNew) bIsNew = !exists(oConn);

  	if (isNull(DB.gu_pwd)) {
  	  put (DB.gu_pwd, Gadgets.generateUUID());
  	}
  	
  	StringBuffer oLines = new StringBuffer("# Password record v5.0\n");
  	int nLines = 0;
  	for (PasswordRecordLine rcl : aRecordLines) {
  	  if (++nLines>1) oLines.append("\n");
  	  oLines.append(rcl);
  	} // next
  	  
 	if (isNull(DB.id_enc_method)) put(DB.id_enc_method, "RC4");
 	
 	if (getString(DB.id_enc_method).equalsIgnoreCase("RC4")) {
      if (null==sRC4Key) throw new NullPointerException("PasswordRecord.store() RC4 Key value may not be null");
  	  try {
  	  	RC4 oRc4 = new RC4(sRC4Key);
  	    replace(DB.tx_lines, Base64Encoder.encode(oRc4.rc4(Gadgets.dechomp(oLines.toString(),'\n').getBytes("UTF-8"))));
      } catch (UnsupportedEncodingException neverthrown) { }
 	}
    else if (getString(DB.id_enc_method).equalsIgnoreCase("NONE"))
      replace(DB.tx_lines, Gadgets.dechomp(oLines.toString(),'\n'));
	else {
	  throw new IllegalArgumentException("Invalid encoding method "+getString(DB.id_enc_method));
	}

    boolean bRetVal = super.store(oConn);
    
    if (bIsNew) {
      if (null!=sGuCategory) {
        Category oPwdsCat = new Category(sGuCategory);
        Integer oPos = DBCommand.queryMaxInt(oConn, DB.od_position, DB.k_x_cat_objs,
        									 DB.gu_category+"='"+sGuCategory+"'");
        if (null==oPos) oPos = new Integer(1); else oPos = new Integer(oPos.intValue()+1);
        oPwdsCat.addObject(oConn, getString(DB.gu_pwd), ClassId, 0, oPos.intValue());
      } // fi
    } // fi
    return bRetVal;
  } // store

  public boolean delete (JDCConnection oConn)
  	throws SQLException {
	return delete (oConn, getString(DB.gu_pwd));
  }

  public static boolean delete (JDCConnection oConn, String sGuPwd)
  	throws SQLException {
  
    DBCommand.executeUpdate(oConn, "DELETE FROM "+DB.k_x_cat_objs+" WHERE "+DB.gu_object+"='"+sGuPwd+"'");

    int iAffected = DBCommand.executeUpdate(oConn, "DELETE FROM "+DB.k_user_pwd+" WHERE "+DB.gu_pwd+"='"+sGuPwd+"'");

	return (iAffected>0);
  }

  public String toString() {
    StringBuffer oStr = new StringBuffer(lines().size()*255);
    int nLine = 0;
    for (PasswordRecordLine l : lines()) {
      if (++nLine>1) oStr.append('\n');
      oStr.append(l.toString());
    } // next
    return oStr.toString();
  } // toString
  
  // **********************************************************
  // Public Constants

  public static final short ClassId = 14;

}
