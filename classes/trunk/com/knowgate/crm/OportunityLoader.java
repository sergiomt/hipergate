/*
  Copyright (C) 2010  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

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

package com.knowgate.crm;

import java.sql.Types;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.ResultSetMetaData;
import java.sql.PreparedStatement;

import java.util.Date;
import java.util.Arrays;
import java.util.HashMap;

import com.knowgate.dataobjs.DB;
import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.hipergate.datamodel.ColumnList;
import com.knowgate.hipergate.datamodel.ImportLoader;

public class OportunityLoader implements ImportLoader {

    private Object[] aValues;
    private PreparedStatement oOprtUpdt=null;
    private PreparedStatement oOprtInst=null;
    private PreparedStatement oContGuid=null;
    private PreparedStatement oMmbrGuid=null;
    private PreparedStatement oCompGuid=null;
    private PreparedStatement oCompByNm=null;
    private PreparedStatement oOprtLook=null;
    private HashMap<String,String> oStatusMap = null;
    private HashMap<String,String> oObjectiveMap = null;
    private HashMap<String,String> oOriginMap = null;
    private HashMap<String,String> oStatusTranslations = null;
    private HashMap<String,String> oObjectiveTranslations = null;
    private HashMap<String,String> oOriginTranslations = null;

    public OportunityLoader() {
      aValues = new Object[ColumnNames.length];
      Arrays.fill(aValues, null);
    }

	public int columnCount() {
	  return aValues.length;
	}

	public String[] columnNames() throws IllegalStateException {
	  return ColumnNames;
	}

	public Object get(int iColumnIndex) throws ArrayIndexOutOfBoundsException {
      return aValues[iColumnIndex];
	}

	public Object get(String sColumnName) throws ArrayIndexOutOfBoundsException {
      int iColumnIndex = getColumnIndex(sColumnName.toLowerCase());
      if (-1==iColumnIndex) throw new ArrayIndexOutOfBoundsException("Cannot find column named "+sColumnName);
      return aValues[iColumnIndex];
	}

	public int getColumnIndex(String sColumnName) {
      int iIndex = Arrays.binarySearch(ColumnNames, sColumnName, String.CASE_INSENSITIVE_ORDER);
      if (iIndex<0) iIndex=-1;
      return iIndex;
	}

	public void put(int iColumnIndex, Object oValue) throws ArrayIndexOutOfBoundsException {
      aValues[iColumnIndex] = oValue;
	}

    // ---------------------------------------------------------------------------

	public void put(String sColumnName, Object oValue) throws ArrayIndexOutOfBoundsException {
      int iColumnIndex = getColumnIndex(sColumnName.toLowerCase());
      if (-1==iColumnIndex) throw new ArrayIndexOutOfBoundsException("Cannot find column named "+sColumnName);
      aValues[iColumnIndex] = oValue;
	}

    // ---------------------------------------------------------------------------

	public void setAllColumnsToNull() {
	  if (null!=aValues) Arrays.fill(aValues, null);
	}

    // ---------------------------------------------------------------------------

	public void prepare(Connection oConn, ColumnList oCols) throws SQLException {
      oStatusMap = new HashMap<String,String>();
      oObjectiveMap = new HashMap<String,String>();
      oOriginMap = new HashMap<String,String>();
	  oOprtInst = oConn.prepareStatement("INSERT INTO "+DB.k_oportunities+"(gu_writer,gu_workarea,bo_private,dt_created,dt_modified,dt_next_action,dt_last_call,lv_interest,gu_campaign,gu_company,gu_contact,tx_company,tx_contact,tl_oportunity,tp_oportunity,tp_origin,im_revenue,im_cost,id_status,id_objetive,tx_cause,tx_note,gu_oportunity,nu_oportunities) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,1)");
	  oOprtUpdt = oConn.prepareStatement("UPDATE "+DB.k_oportunities+" SET gu_writer=?,gu_workarea=?,bo_private=?,dt_created=?,dt_modified=?,dt_next_action=?,dt_last_call=?,lv_interest=?,gu_campaign=?,gu_company=?,gu_contact=?,tx_company=?,tx_contact=?,tl_oportunity=?,tp_oportunity=?,tp_origin=?,im_revenue=?,im_cost=?,id_status=?,id_objetive=?,tx_cause=?,tx_note=? WHERE gu_oportunity=?");
	  oContGuid = oConn.prepareStatement("SELECT "+DB.gu_contact+" FROM "+DB.k_contacts+" WHERE "+DB.gu_workarea+"=? AND ("+DB.sn_passport+"=? OR "+DB.id_ref+"=?)");
	  oMmbrGuid = oConn.prepareStatement("SELECT "+DB.gu_contact+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"=? AND "+DB.tx_email+"=?");
	  oCompGuid = oConn.prepareStatement("SELECT "+DB.gu_company+" FROM "+DB.k_contacts+" WHERE "+DB.gu_contact+"=?");
	  oCompByNm = oConn.prepareStatement("SELECT "+DB.gu_company+" FROM "+DB.k_companies+" WHERE "+DB.gu_workarea+"=? AND "+DB.nm_legal+"=?");
      oOprtLook = oConn.prepareStatement("SELECT NULL FROM k_oportunities_lookup WHERE gu_owner=? AND id_section=? AND vl_lookup=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);

	}

    // ---------------------------------------------------------------------------

	public void close() throws SQLException {
	  Arrays.fill(aValues, null);

	  if (oStatusMap!=null) oStatusMap.clear();
	  if (oObjectiveMap!=null) oObjectiveMap.clear();
	  if (oOriginMap!=null) oOriginMap.clear();

	  if (oStatusTranslations!=null) oStatusTranslations.clear();
      oStatusTranslations = null;
      if (oObjectiveTranslations!=null) oObjectiveTranslations.clear();
      oObjectiveTranslations = null;
      if (oOriginTranslations!=null) oOriginTranslations.clear();
      oOriginTranslations = null;
	  
	  if (null!=oOprtLook) oOprtLook.close();
	  if (null!=oCompByNm) oCompByNm.close();
	  if (null!=oCompGuid) oCompGuid.close();
	  if (null!=oMmbrGuid) oMmbrGuid.close();
	  if (null!=oContGuid) oContGuid.close();
	  if (null!=oOprtUpdt) oOprtUpdt.close();
	  if (null!=oOprtInst) oOprtInst.close();
	}

    // ---------------------------------------------------------------------------

    private static boolean test(int iInputValue, int iBitMask) {
      return (iInputValue&iBitMask)!=0;
    } // test

    // ---------------------------------------------------------------------------
  
    /**
     * Add a lookup value to a table
     * @param sSection String Section. Usually the name of the column at the base table
     * @param sValue String Internal hidden value of the lookup
     * @param oConn Connection
     * @param oSelStmt PreparedStatement
     * @param oCacheMap HashMap
     * @throws SQLException
     */
    private void addLookUp(String sTable, String sSection, String sValue, Connection oConn,
                           PreparedStatement oSelStmt, HashMap<String,String> oCacheMap) throws SQLException {
      String sTr;
      char[] aTr;
      final String EmptyStr = "";
      boolean bExistsLookup;
  
      if (DebugFile.trace) {
        DebugFile.writeln("Begin OportunityLoader.addLookUp("+sTable+","+sSection+","+sValue+","+
                          "[Connection],[PreparedStatement],[PreparedStatement],[HashMap]");
        DebugFile.incIdent();
      }
  
      if (null==sValue) sValue = EmptyStr;
      if (!EmptyStr.equals(sValue)) {
        if (!oCacheMap.containsKey(sValue)) {
          oSelStmt.setObject(1, get(gu_workarea), Types.CHAR);
          oSelStmt.setString(2, sSection);
          oSelStmt.setString(3, sValue);
          ResultSet oRSet = oSelStmt.executeQuery();
          bExistsLookup = oRSet.next();
          oRSet.close();
          if (!bExistsLookup) {
            aTr = sValue.toLowerCase().toCharArray();
            aTr[0] = Character.toUpperCase(aTr[0]);
            sTr = new String(aTr);
  		  HashMap<String,String> oTranslatMap = new HashMap<String,String>(DBLanguages.SupportedLanguages.length*2);
  		  for (int l=0; l<DBLanguages.SupportedLanguages.length; l++) oTranslatMap.put(DBLanguages.SupportedLanguages[l], sTr);
  
   		  DBLanguages.addLookup (oConn, sTable, (String) get(gu_workarea), sSection, sValue, oTranslatMap);
                                     
          } // fi (!bExistsLookup)
          oCacheMap.put(sValue, sValue);
        } // fi (!oCacheMap.containsKey(sValue))
      }
  
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End OportunityLoader.addLookUp()");
      }
    } // addLookUp

    // ---------------------------------------------------------------------------

    private String getCompanyGuid(Connection oConn, String sContactGuid, String sNmLegal, String sWorkArea) 
      throws SQLException {
      String sCompGuid;
	  oCompGuid.setString(1, sContactGuid);
      ResultSet oRSet = oCompGuid.executeQuery();
      if (oRSet.next()) {
      	sCompGuid = oRSet.getString(1);
      	if (oRSet.wasNull()) {
      	  oRSet.close();
      	  oCompByNm.setString(1, sWorkArea);
      	  oCompByNm.setString(2, sNmLegal);
      	  oRSet = oCompByNm.executeQuery();
      	  if (oRSet.next()) {
      	    sCompGuid = oRSet.getString(1);
      		if (oRSet.wasNull()) sCompGuid = null;
      	  } else {
      	    sCompGuid = null;
      	  }
      	  oRSet.close();
      	}
      } else {
        oRSet.close();
      	sCompGuid = null;
      }
      return sCompGuid;
    } // getCompanyGuid

    // ---------------------------------------------------------------------------

    private String getContactGuid(Connection oConn,
  								String sContactPassport,
  								String sContactEmail,
  								String sContactIdRef,
  								String sWorkArea)
      throws SQLException {
      ResultSet oRSet;
      String sContGuid;

      if (DebugFile.trace) {
        DebugFile.writeln("Begin OportunityLoader.getContactGuid([Connection],"+sContactPassport+","+sContactEmail+","+sContactIdRef+","+sWorkArea+")");
        DebugFile.incIdent();
      }

      oContGuid.setString(1, sWorkArea);
      oContGuid.setString(2, sContactPassport);
      oContGuid.setString(3, sContactIdRef);
      oRSet = oContGuid.executeQuery();
      if (oRSet.next()) {
      	sContGuid = oRSet.getString(1);
      	oRSet.close();
      } else {
      	oRSet.close();
        oMmbrGuid.setString(1, sWorkArea);
        oMmbrGuid.setString(2, sContactEmail);
        oRSet = oMmbrGuid.executeQuery();
		if (oRSet.next())
      	  sContGuid = oRSet.getString(1);
      	else
      	  sContGuid = null;
      	oRSet.close();      	
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End OportunityLoader.getContactGuid() : "+sContGuid);
      }
      
    return sContGuid;      
  } // getContactGuid

  // ---------------------------------------------------------------------------

  private String getColNull (int iColIndex)
    throws ArrayIndexOutOfBoundsException,ClassCastException {
    if (DebugFile.trace) {
      if (iColIndex<0 || iColIndex>=aValues.length)
        throw new ArrayIndexOutOfBoundsException("OportunityLoader.getColNull() column index "+String.valueOf(iColIndex)+" must be in the range between 0 and "+String.valueOf(aValues.length));
      DebugFile.writeln("OportunityLoader.getColNull("+String.valueOf(iColIndex)+") : "+aValues[iColIndex]);
    }
    String sRetVal;
    if (null==aValues[iColIndex])
      sRetVal = null;
    else {
      try {
        sRetVal = aValues[iColIndex].toString();
      } catch (ClassCastException cce){
        if (aValues[iColIndex]==null)
          throw new ClassCastException("OportunityLoader.getColNull("+String.valueOf(iColIndex)+") could not cast null to String");
        else
          throw new ClassCastException("OportunityLoader.getColNull("+String.valueOf(iColIndex)+") could not cast "+aValues[iColIndex].getClass().getName()+" "+aValues[iColIndex]+" to String");
      }
      if (sRetVal.length()==0 || sRetVal.equalsIgnoreCase("null"))
        sRetVal = null;
    }
    return sRetVal;
  } // getColNull

  // ---------------------------------------------------------------------------

	public void store(Connection oConn, String sWorkArea, int iFlags)
	  throws SQLException, IllegalArgumentException, NullPointerException {
      if (null==sWorkArea)
        throw new NullPointerException("OportunityLoader.store() Default WorkArea cannot be null");

	  if (oStatusTranslations==null) {
	  	oStatusTranslations = new HashMap<String,String>();
	  	PreparedStatement oStTr = oConn.prepareStatement("SELECT * FROM "+DB.k_oportunities_lookup+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"='"+DB.id_status+"'");
	    oStTr.setString(1, sWorkArea);
	    ResultSet oRsTr = oStTr.executeQuery();
	    ResultSetMetaData oRsMd = oRsTr.getMetaData();
	    final int nCols = oRsMd.getColumnCount();
	    while (oRsTr.next()) {
	      String sVl = oRsTr.getString(4);
	      for (int c=5; c<=nCols; c++) {
	      	String sTr = oRsTr.getString(5);
	      	if (oRsTr.wasNull()) {
	      	  if (!oStatusTranslations.containsKey(sTr)) {
	      	  	oStatusTranslations.put(sTr, sVl);
	      	  }
	      	}
	      }
	    } // wend
	    oRsTr.close();
	    oStTr.close();
	  } // fi

	  if (oObjectiveTranslations==null) {
	  	oObjectiveTranslations = new HashMap<String,String>();
	  	PreparedStatement oStTr = oConn.prepareStatement("SELECT * FROM "+DB.k_oportunities_lookup+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"='"+DB.id_objetive+"'");
	    oStTr.setString(1, sWorkArea);
	    ResultSet oRsTr = oStTr.executeQuery();
	    ResultSetMetaData oRsMd = oRsTr.getMetaData();
	    final int nCols = oRsMd.getColumnCount();
	    while (oRsTr.next()) {
	      String sVl = oRsTr.getString(4);
	      for (int c=5; c<=nCols; c++) {
	      	String sTr = oRsTr.getString(5);
	      	if (oRsTr.wasNull()) {
	      	  if (!oObjectiveTranslations.containsKey(sTr)) {
	      	  	oObjectiveTranslations.put(sTr, sVl);
	      	  }
	      	}
	      }
	    } // wend
	    oRsTr.close();
	    oStTr.close();
	  } // fi

	  if (oOriginTranslations==null) {
	  	oOriginTranslations = new HashMap<String,String>();
	  	PreparedStatement oStTr = oConn.prepareStatement("SELECT * FROM "+DB.k_oportunities_lookup+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"='"+DB.tp_origin+"'");
	    oStTr.setString(1, sWorkArea);
	    ResultSet oRsTr = oStTr.executeQuery();
	    ResultSetMetaData oRsMd = oRsTr.getMetaData();
	    final int nCols = oRsMd.getColumnCount();
	    while (oRsTr.next()) {
	      String sVl = oRsTr.getString(4);
	      for (int c=5; c<=nCols; c++) {
	      	String sTr = oRsTr.getString(5);
	      	if (oRsTr.wasNull()) {
	      	  if (!oOriginTranslations.containsKey(sTr)) {
	      	  	oOriginTranslations.put(sTr, sVl);
	      	  }
	      	}
	      }
	    } // wend
	    oRsTr.close();
	    oStTr.close();
	  } // fi

      int iAffected = 0;

      if (test(iFlags,MODE_UPDATE)) {
        oOprtUpdt.setString(1, getColNull(gu_writer));
        oOprtUpdt.setString(2, sWorkArea);
        if (aValues[bo_private]==null)
          oOprtUpdt.setShort(3, (short) 0);
        else
          oOprtUpdt.setObject(3, aValues[bo_private], Types.SMALLINT);
        oOprtUpdt.setTimestamp(4, new Timestamp(new Date().getTime()));
        oOprtUpdt.setNull(5, Types.TIMESTAMP);
        if (aValues[dt_next_action]==null)
          oOprtUpdt.setNull(6, Types.TIMESTAMP);
        else
          oOprtUpdt.setObject(6, aValues[dt_last_call], Types.TIMESTAMP);
        if (aValues[dt_last_call]==null)
          oOprtUpdt.setNull(7, Types.TIMESTAMP);
        else
          oOprtUpdt.setObject(7, aValues[dt_last_call], Types.TIMESTAMP);
        if (aValues[lv_interest]==null)
          oOprtUpdt.setNull(8, Types.SMALLINT);
        else
          oOprtUpdt.setObject(8, aValues[lv_interest], Types.SMALLINT);
        oOprtUpdt.setString(9, getColNull(gu_campaign));
        if (aValues[gu_contact]==null)
          aValues[gu_contact]=getContactGuid(oConn, (String) aValues[sn_passport], (String) aValues[tx_email], (String) aValues[id_ref], sWorkArea);
        if (aValues[gu_contact]==null) 
          throw new IllegalArgumentException("OportunityLoader.store() gu_contact not specified and no value can be found matching by contact passport, reference or e-mail");
        oOprtUpdt.setString(11, getColNull(gu_contact));
        if (aValues[gu_company]==null)
          aValues[gu_company]=getCompanyGuid(oConn, (String) aValues[gu_contact], (String) aValues[tx_company], sWorkArea);
        oOprtUpdt.setString(10, getColNull(gu_company));
        if (aValues[tx_company]==null && aValues[gu_company]!=null)
		  aValues[tx_company]=DBCommand.queryStr(oConn, "SELECT "+DB.nm_legal+" FROM "+DB.k_companies+" WHERE "+DB.gu_company+"='"+aValues[gu_company]+"'");
        oOprtUpdt.setString(12, getColNull(tx_company));
        if (aValues[tx_contact]==null) {
          String[] aFullName = DBCommand.queryStrs(oConn, "SELECT "+DB.tx_name+","+DB.tx_surname+" FROM "+DB.k_contacts+" WHERE "+DB.gu_contact+"='"+aValues[gu_contact]+"'");
          if (aFullName!=null)
            aValues[tx_contact]=((aFullName[0]==null ? "" : aFullName[0])+" "+(aFullName[1]==null ? "" : aFullName[1])).trim();
        }
        oOprtUpdt.setString(13, getColNull(tx_contact));
        if (aValues[tl_oportunity]==null) {
          String sTl = (String) aValues[tx_contact];
          if (aValues[id_objetive]!=null)
          	sTl += " "+aValues[id_objetive];
          aValues[tl_oportunity] = Gadgets.left(sTl,128);
        }
        oOprtUpdt.setString(14, getColNull(tl_oportunity));
        oOprtUpdt.setString(15, getColNull(tp_oportunity));

        if (aValues[tp_origin]==null) {
          oOprtUpdt.setNull(16, Types.VARCHAR);
        } else {
          if (oOriginTranslations.containsKey(aValues[tp_origin]))
          	aValues[tp_origin]=oOriginTranslations.get(aValues[tp_origin]);
          oOprtUpdt.setString(16, getColNull(tp_origin));
        }
        if (test(iFlags,WRITE_LOOKUPS) && aValues[tp_origin]!=null) {
          addLookUp("k_oportunities_lookup", "tp_origin", getColNull(tp_origin), oConn, oOprtLook, oOriginMap);
        }

        if (aValues[im_revenue]==null)
          oOprtUpdt.setNull(17, Types.FLOAT);
        else
          oOprtUpdt.setObject(17, aValues[im_revenue], Types.FLOAT);        	

        if (aValues[im_cost]==null)
          oOprtUpdt.setNull(18, Types.FLOAT);
        else
          oOprtUpdt.setObject(18, aValues[im_cost], Types.FLOAT);

        if (aValues[id_status]==null) {
          oOprtUpdt.setNull(19, Types.VARCHAR);
        } else {
          if (oStatusTranslations.containsKey(aValues[id_status]))
          	aValues[id_status]=oStatusTranslations.get(aValues[id_status]);
          oOprtUpdt.setString(19, getColNull(id_status));
        }
        if (test(iFlags,WRITE_LOOKUPS) && aValues[id_status]!=null) {
          addLookUp("k_oportunities_lookup", "id_status", getColNull(id_status), oConn, oOprtLook, oStatusMap);
        }

        if (aValues[id_objetive]==null) {
          oOprtUpdt.setNull(20, Types.VARCHAR);
        } else {
          if (oObjectiveTranslations.containsKey(aValues[id_objetive]))
          	aValues[id_status]=oObjectiveTranslations.get(aValues[id_objetive]);
          oOprtUpdt.setString(20, getColNull(id_objetive));
        }
        if (test(iFlags,WRITE_LOOKUPS) && aValues[id_objetive]!=null) {
          addLookUp("k_oportunities_lookup", "id_objetive", getColNull(id_objetive), oConn, oOprtLook, oObjectiveMap);
        }

        oOprtUpdt.setString(21, getColNull(tx_cause));
        oOprtUpdt.setString(22, getColNull(tx_note));
        if (aValues[gu_oportunity]==null)
          aValues[gu_oportunity]=Gadgets.generateUUID();
        oOprtUpdt.setString(23, getColNull(gu_oportunity));
        iAffected = oOprtUpdt.executeUpdate();        
      }
      
	  if (0==iAffected && test(iFlags,MODE_APPEND)) {
        oOprtInst.setString(1, getColNull(gu_writer));
        oOprtInst.setString(2, sWorkArea);
        if (aValues[bo_private]==null)
          oOprtInst.setShort(3, (short) 0);
        else
          oOprtInst.setObject(3, aValues[bo_private], Types.SMALLINT);
        oOprtInst.setTimestamp(4, new Timestamp(new Date().getTime()));
        oOprtInst.setNull(5, Types.TIMESTAMP);
        if (aValues[dt_next_action]==null)
          oOprtInst.setNull(6, Types.TIMESTAMP);
        else
          oOprtInst.setObject(6, aValues[dt_last_call], Types.TIMESTAMP);
        if (aValues[dt_last_call]==null)
          oOprtInst.setNull(7, Types.TIMESTAMP);
        else
          oOprtInst.setObject(7, aValues[dt_last_call], Types.TIMESTAMP);
        if (aValues[lv_interest]==null)
          oOprtInst.setNull(8, Types.SMALLINT);
        else
          oOprtInst.setObject(8, aValues[lv_interest], Types.SMALLINT);
        oOprtInst.setString(9, getColNull(gu_campaign));
        if (aValues[gu_contact]==null)
          aValues[gu_contact]=getContactGuid(oConn, (String) aValues[sn_passport], (String) aValues[tx_email], (String) aValues[id_ref], sWorkArea);
        if (aValues[gu_contact]==null) 
          throw new IllegalArgumentException("OportunityLoader.store() gu_contact not specified and no value can be found matching by contact passport, reference or e-mail");
        oOprtInst.setString(11, getColNull(gu_contact));
        if (aValues[gu_company]==null)
          aValues[gu_company]=getCompanyGuid(oConn, (String) aValues[gu_contact], (String) aValues[tx_company], sWorkArea);
        oOprtInst.setString(10, getColNull(gu_company));
        if (aValues[tx_company]==null && aValues[gu_company]!=null)
		  aValues[tx_company]=DBCommand.queryStr(oConn, "SELECT "+DB.nm_legal+" FROM "+DB.k_companies+" WHERE "+DB.gu_company+"='"+aValues[gu_company]+"'");
        oOprtInst.setString(12, getColNull(tx_company));
        if (aValues[tx_contact]==null) {
          String[] aFullName = DBCommand.queryStrs(oConn, "SELECT "+DB.tx_name+","+DB.tx_surname+" FROM "+DB.k_contacts+" WHERE "+DB.gu_contact+"='"+aValues[gu_contact]+"'");
          if (aFullName!=null)
            aValues[tx_contact]=((aFullName[0]==null ? "" : aFullName[0])+" "+(aFullName[1]==null ? "" : aFullName[1])).trim();
        }
        oOprtInst.setString(13, getColNull(tx_contact));
        if (aValues[tl_oportunity]==null) {
          String sTl = (String) aValues[tx_contact];
          if (aValues[id_objetive]!=null)
          	sTl += " "+aValues[id_objetive];
          aValues[tl_oportunity] = Gadgets.left(sTl,128);
        }
        oOprtInst.setString(14, getColNull(tl_oportunity));
        oOprtInst.setString(15, getColNull(tp_oportunity));

        if (aValues[tp_origin]==null) {
          oOprtInst.setNull(16, Types.VARCHAR);
        } else {
          if (oOriginTranslations.containsKey(aValues[tp_origin]))
          	aValues[tp_origin]=oOriginTranslations.get(aValues[tp_origin]);
          oOprtInst.setString(16, getColNull(tp_origin));
        }
        if (test(iFlags,WRITE_LOOKUPS) && aValues[tp_origin]!=null) {
          addLookUp("k_oportunities_lookup", "tp_origin", getColNull(tp_origin), oConn, oOprtLook, oOriginMap);
        }

        if (aValues[im_revenue]==null)
          oOprtInst.setNull(17, Types.FLOAT);
        else
          oOprtInst.setObject(17, aValues[im_revenue], Types.FLOAT);        	

        if (aValues[im_cost]==null)
          oOprtInst.setNull(18, Types.FLOAT);
        else
          oOprtInst.setObject(18, aValues[im_cost], Types.FLOAT);

        if (aValues[id_status]==null) {
          oOprtInst.setNull(19, Types.VARCHAR);
        } else {
          if (oStatusTranslations.containsKey(aValues[id_status]))
          	aValues[id_status]=oStatusTranslations.get(aValues[id_status]);
          oOprtInst.setString(19, getColNull(id_status));
        }
        if (test(iFlags,WRITE_LOOKUPS) && aValues[id_status]!=null) {
          addLookUp("k_oportunities_lookup", "id_status", getColNull(id_status), oConn, oOprtLook, oStatusMap);
        }

        if (aValues[id_objetive]==null) {
          oOprtInst.setNull(20, Types.VARCHAR);
        } else {
          if (oObjectiveTranslations.containsKey(aValues[id_objetive]))
          	aValues[id_status]=oObjectiveTranslations.get(aValues[id_objetive]);
          oOprtInst.setString(20, getColNull(id_objetive));
        }
        if (test(iFlags,WRITE_LOOKUPS) && aValues[id_objetive]!=null) {
          addLookUp("k_oportunities_lookup", "id_objetive", getColNull(id_objetive), oConn, oOprtLook, oObjectiveMap);
        }

        oOprtInst.setString(21, getColNull(tx_cause));
        oOprtInst.setString(22, getColNull(tx_note));
        if (aValues[gu_oportunity]==null)
          aValues[gu_oportunity]=Gadgets.generateUUID();
        oOprtInst.setString(23, getColNull(gu_oportunity));
        iAffected = oOprtInst.executeUpdate();
	  }
	} // store
	
  // ---------------------------------------------------------------------------

  public static final int MODE_APPEND = ImportLoader.MODE_APPEND;
  public static final int MODE_UPDATE = ImportLoader.MODE_UPDATE;
  public static final int MODE_APPENDUPDATE = ImportLoader.MODE_APPENDUPDATE;
  public static final int WRITE_LOOKUPS = ImportLoader.WRITE_LOOKUPS;

  // ---------------------------------------------------------------------------

  // Keep this list sorted
  private static final String[] ColumnNames = { "", "bo_private","dt_created","dt_last_call","dt_modified","dt_next_action","gu_campaign","gu_company","gu_contact","gu_oportunity","gu_workarea","gu_writer","id_objetive","id_ref","id_status","im_cost","im_revenue","lv_interest","sn_passport","tl_oportunity","tp_oportunity","tp_origin","tx_cause","tx_company","tx_contact","tx_email","tx_note"};

  public static int bo_private = 1;
  public static int dt_created = 2;
  public static int dt_last_call = 3;
  public static int dt_modified = 4;
  public static int dt_next_action = 5;
  public static int gu_campaign = 6;
  public static int gu_company = 7;
  public static int gu_contact = 8;
  public static int gu_oportunity = 9;
  public static int gu_workarea = 10;
  public static int gu_writer = 11;
  public static int id_objetive = 12;
  public static int id_ref = 13;
  public static int id_status = 14;
  public static int im_cost = 15;
  public static int im_revenue = 16;
  public static int lv_interest = 17;
  public static int sn_passport = 18;
  public static int tl_oportunity = 19;
  public static int tp_oportunity = 20;
  public static int tp_origin = 21;
  public static int tx_cause = 22;
  public static int tx_company = 23;
  public static int tx_contact = 24;
  public static int tx_email = 25;
  public static int tx_note = 26;	
}
