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

package com.knowgate.hipermail;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.CallableStatement;

import java.io.File;
import java.io.IOException;

import java.util.Date;
import java.util.Arrays;
import java.util.ArrayList;

import org.apache.oro.text.regex.Pattern;
import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.MalformedPatternException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.FileSystem;

public class AdHocMailing extends DBPersist {

  private String[] aRecipients;
  private String[] aBlackList;


  public AdHocMailing() {
  	super(DB.k_adhoc_mailings, "AdHocMailing");
  	aBlackList = null;
  	aRecipients = null;
  }

  public AdHocMailing(JDCConnection oConn, String sGuAdHocMailing)
  	throws SQLException {
  	super(DB.k_adhoc_mailings, "AdHocMailing");
  	aBlackList = null;
  	aRecipients = null;
	load(oConn, new Object[]{sGuAdHocMailing});
  }
  
  public boolean load(JDCConnection oConn, int iPgMailing, String sGuWorkArea)
  	throws SQLException {
  	String sGuMaiiling = DBCommand.queryStr(oConn, "SELECT "+DB.gu_mailing+" FROM "+DB.k_adhoc_mailings+" WHERE "+DB.pg_mailing+"="+String.valueOf(iPgMailing)+" AND "+DB.gu_workarea+"='"+sGuWorkArea+"'");
    if (null==sGuMaiiling)
      return false;
    else
      return super.load(oConn, sGuMaiiling);
  }
  
  private String[] concatArrays(String[] a1, String a2[]) {
	final int l1 = a1.length;
	final int l2 = a2.length;
	final int ll = l1+l2;
	String[] aRetVal = Arrays.copyOf(a1, ll);
    for (int e=0; e<l2; e++) aRetVal[e+l1] = a2[e];
    return aRetVal;
  } // concatArrays

  public String[] getBlackList() {
    return aBlackList;
  }

  public void addBlackList(String[] aEMails)
  	throws MalformedPatternException {
    if (aEMails!=null) {
      if (aEMails.length>0) {
      	if (aBlackList==null) {
      	  aBlackList = aEMails;
      	} else {
      	  aBlackList = concatArrays(aBlackList, aEMails);
      	} // fi (aRecipients!=null)
      	final int nBlackList = aBlackList.length;
      	Arrays.sort(aBlackList, String.CASE_INSENSITIVE_ORDER);
      }
    }
  } // addBlackList

  public void clearRecipients() {
    aRecipients = null;
  }

  public String[] getRecipients() {
    return aRecipients;
  }

  public String getAllowPattern() {
  	return getStringNull(DB.tx_allow_regexp, "");
  }

  public void setAllowPattern(String sAllowPattern) {
  	replace(DB.tx_allow_regexp, sAllowPattern);
  }

  public String getDenyPattern() {
  	return getStringNull(DB.tx_deny_regexp, "");
  }

  public void setDenyPattern(String sDenyPattern) {
  	replace(DB.tx_deny_regexp, sDenyPattern);
  }

  public void addRecipients(String[] aEMails)
  	throws ArrayIndexOutOfBoundsException,MalformedPatternException {
	String sAllowPattern, sDenyPattern;
    ArrayList<String> oRecipientsWithoutDuplicates;
    boolean bAllowed;

	Pattern oAllowPattern=null, oDenyPattern=null;
	Perl5Matcher oMatcher = new Perl5Matcher();
	Perl5Compiler oCompiler = new Perl5Compiler();
		
    if (aEMails!=null) {
      if (aEMails.length>0) {
      	if (aRecipients==null) {
      	  aRecipients = aEMails;
      	} else {
      	  aRecipients = concatArrays(aRecipients, aEMails);
      	} // fi (aRecipients!=null)
      	final int nRecipients = aRecipients.length;
      	Arrays.sort(aRecipients, String.CASE_INSENSITIVE_ORDER);
		
		oRecipientsWithoutDuplicates = new ArrayList<String>(nRecipients);

	  	sAllowPattern = getAllowPattern();
	  	sDenyPattern = getDenyPattern();
	  	
	  	if (sAllowPattern.length()>0) {
	  	  oAllowPattern = oCompiler.compile(sAllowPattern, Perl5Compiler.CASE_INSENSITIVE_MASK);
	  	}

	  	if (sDenyPattern.length()>0) {
	  	  oDenyPattern = oCompiler.compile(sDenyPattern, Perl5Compiler.CASE_INSENSITIVE_MASK);
	  	}
	  	  
	    for (int r=0; r<nRecipients-1; r++) {
		  bAllowed = true;
		  try {
		    if (sAllowPattern.length()>0) bAllowed &= oMatcher.matches(aRecipients[r], oAllowPattern);
		  } catch (ArrayIndexOutOfBoundsException aiob) {
		  	throw new ArrayIndexOutOfBoundsException("Gadgets.matches("+aRecipients[r]+","+sAllowPattern+")");
		  }
		  try {
		  if (sDenyPattern.length()>0) bAllowed &= !oMatcher.matches(aRecipients[r], oDenyPattern);
		  } catch (ArrayIndexOutOfBoundsException aiob) {
		  	throw new ArrayIndexOutOfBoundsException("Gadgets.matches("+aRecipients[r]+","+sDenyPattern+")");
		  }
		  if (bAllowed) {
	  	    if (!aRecipients[r].equalsIgnoreCase(aRecipients[r+1])) {
	  	      if (aBlackList==null) {
	  	        if (aRecipients[r].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[r].trim());
	  	      } else if (Arrays.binarySearch(aBlackList, aRecipients[r].toLowerCase(), String.CASE_INSENSITIVE_ORDER)<0) {
	  	        if (aRecipients[r].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[r].trim());
	  	      } // fi
	  	    } // fi
	  	  } // fi bAllowed
	    } // next      

	    bAllowed=true;
		try {
	      if (sAllowPattern.length()>0) bAllowed &= Gadgets.matches(aRecipients[nRecipients-1], sAllowPattern);
		} catch (ArrayIndexOutOfBoundsException aiob) {
		  throw new ArrayIndexOutOfBoundsException("Gadgets.matches("+aRecipients[nRecipients-1]+","+sAllowPattern+")");
		}
		try {
	      if (sDenyPattern.length()>0) bAllowed &= !Gadgets.matches(aRecipients[nRecipients-1], sDenyPattern);
		} catch (ArrayIndexOutOfBoundsException aiob) {
		  throw new ArrayIndexOutOfBoundsException("Gadgets.matches("+aRecipients[nRecipients-1]+","+sDenyPattern+")");
		}
	    if (bAllowed) {
	      if (aBlackList==null) {
	        if (aRecipients[nRecipients-1].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[nRecipients-1].trim());
	      } else if (Arrays.binarySearch(aBlackList, aRecipients[nRecipients-1].toLowerCase(), String.CASE_INSENSITIVE_ORDER)<0) {
	  	    if (aRecipients[nRecipients-1].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[nRecipients-1].trim());
	      }
	    } // fi (bAllowed)

	    aRecipients = oRecipientsWithoutDuplicates.toArray(new String[oRecipientsWithoutDuplicates.size()]);
	    	  
      } // fi (aEMails != {})
    } // fi (aEMails != null)

  } // addRecipients

  public boolean store (JDCConnection oConn)
  	throws SQLException {
    
    Date dtNow = new Date();
    
    if (!AllVals.containsKey(DB.dt_modified) && AllVals.containsKey(DB.gu_mailing))
      put (DB.dt_modified, dtNow);
    if (!AllVals.containsKey(DB.gu_mailing))
      put (DB.gu_mailing, Gadgets.generateUUID());
    if (!AllVals.containsKey(DB.pg_mailing)) {
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL || oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL)
        put (DB.pg_mailing, DBBind.nextVal(oConn, "seq_k_adhoc_mail"));
      else
        put (DB.pg_mailing, DBBind.nextVal(oConn, "seq_k_adhoc_mailings"));
    }
    	
    if (!AllVals.containsKey(DB.dt_created))
      put (DB.dt_created, dtNow);
    if (AllVals.containsKey(DB.tx_email_from))
      if (!Gadgets.checkEMail(getString(DB.tx_email_from)))
      	throw new SQLException ("AdHocMailing.store() invalid syntax for tx_email_from address "+getString(DB.tx_email_from));
    if (AllVals.containsKey(DB.tx_email_reply))
      if (!Gadgets.checkEMail(getString(DB.tx_email_reply)))
      	throw new SQLException ("AdHocMailing.store() invalid syntax for tx_email_from address "+getString(DB.tx_email_from));

    return super.store(oConn);
  }

  public void clone(JDCConnection oConn, String sProtocol, String sWorkAreasPut, AdHocMailing oSource)
  	throws IOException, SQLException {
	
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin AdHocMailing.clone([JDCConnection], "+sProtocol+","+sWorkAreasPut+","+String.valueOf(oSource.getInt(DB.pg_mailing))+")");
	  DebugFile.incIdent();
	}

	Date dtNow = new Date();	

  	clone(oSource);
  	remove(DB.id_status);
  	remove(DB.dt_execution);
  	replace(DB.dt_modified, dtNow);
  	replace(DB.gu_mailing, Gadgets.generateUUID());
  	try {
  	  if (Gadgets.matches(oSource.getString(DB.nm_mailing),".+\\x20\\x28\\d+\\x29")) {
	    int iLPar = oSource.getString(DB.nm_mailing).lastIndexOf('(')+1;
	    int iRPar = oSource.getString(DB.nm_mailing).lastIndexOf(')');
	    int nCopy = Integer.parseInt(oSource.getString(DB.nm_mailing).substring(iLPar,iRPar));
  	    int iSpace = oSource.getString(DB.nm_mailing).lastIndexOf(' ');
  	    replace(DB.nm_mailing, oSource.getString(DB.nm_mailing).substring(0, iSpace)+" ("+String.valueOf(++nCopy)+")");
  	  } else {
  	    replace(DB.nm_mailing, oSource.getString(DB.nm_mailing)+" (2)");  	
  	  }
  	} catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) { }
  	if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL || oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
  	  replace(DB.pg_mailing, DBBind.nextVal(oConn, "seq_k_adhoc_mail"));
  	else
  	  replace(DB.pg_mailing, DBBind.nextVal(oConn, "seq_k_adhoc_mailings"));
  	store(oConn);
  	setCreationDate(oConn, dtNow);

	final String sSep = sProtocol.startsWith("file:") ? File.separator : "/";
	
    String sSourceDir =  sWorkAreasPut + oSource.getString(DB.gu_workarea) + sSep + "apps" + sSep + "Hipermail" + sSep + "html" + sSep + Gadgets.leftPad(String.valueOf(oSource.getInt(DB.pg_mailing)), '0', 5);
    String sTargetDir =  sWorkAreasPut + getString(DB.gu_workarea) + sSep + "apps" + sSep + "Hipermail" + sSep + "html" + sSep + Gadgets.leftPad(String.valueOf(getInt(DB.pg_mailing)), '0', 5);

	try {
	  FileSystem oFs = new FileSystem();
	  oFs.mkdirs(sProtocol+sTargetDir);
	  oFs.copy(sProtocol+sSourceDir, sProtocol+sTargetDir);
	} catch (Exception xcpt) {
	  if (DebugFile.trace) {
	    DebugFile.decIdent();
	    DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
	  }
	  throw new IOException(xcpt.getMessage(), xcpt);
	}
	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End AdHocMailing.clone() : "+String.valueOf(getInt(DB.pg_mailing)));
	}
  } // clone  

  public boolean delete(JDCConnection oConn) throws SQLException {
    DBBind oDbb = (DBBind) oConn.getPool().getDatabaseBinding();
    
	final String sSep = oDbb.getProperty("fileprotocol","file://").startsWith("file:") ? File.separator : "/";
    String sSourceDir =  oDbb.getPropertyPath("workareasput") + getString(DB.gu_workarea) + sSep + "apps" + sSep + "Hipermail" + sSep + "html" + sSep + Gadgets.leftPad(String.valueOf(getInt(DB.pg_mailing)), '0', 5);
	try {
	  FileSystem oFs = new FileSystem();
	  oFs.rmdir(oDbb.getProperty("fileprotocol","file://")+sSourceDir);
	} catch (Exception xcpt) {
	  if (DebugFile.trace) {
	    DebugFile.decIdent();
	    DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
	  }
	  throw new SQLException(xcpt.getMessage(), xcpt);
	}

	boolean bRetVal;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      Statement oStmt = oConn.createStatement();
      oStmt.executeQuery("SELECT k_sp_del_adhoc_mailing ('" + getString(DB.gu_mailing) + "')");
      oStmt.close();
      bRetVal = true;
    } else {
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_adhoc_mailing ('" + getString(DB.gu_mailing) + "') }");
      bRetVal = oCall.execute();
      oCall.close();
    }
    return bRetVal;    
  }
  	
  public static final short ClassId = 811;

}