/*
  Copyright (C) 2007  Know Gate S.L. All rights reserved.
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

package com.knowgate.addrbook;

import java.util.Map;
import java.util.Date;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;

import java.sql.Types;
import java.sql.Timestamp;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.acl.ACLUser;
import com.knowgate.acl.ACLGroup;
import com.knowgate.acl.ACLDomain;
import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.hipergate.datamodel.ImportLoader;
import com.knowgate.hipergate.datamodel.ColumnList;
import com.knowgate.hipergate.datamodel.ModelManager;
import com.knowgate.workareas.WorkArea;

/**
 * <p>Load fellow data from a single source</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */
public class FellowLoader implements ImportLoader {

  private Object[] aValues;

  private PreparedStatement oFellwUpdt, oFellwInsr,
                            oUserUpdt, oUserInsr,
                            oTitleInsr, oTitleUpdt,
                            oFellwLook, oFellwWook,
                            oGroupInsr;
  private HashMap oFellwCompanyMap, oFellwDivisionMap, oFellwDepartmentMap, oFellwLocationMap;
  private int iLastDomainId;
  private String sLastGroupId, sLastGroupNm;
  private ModelManager oModMan;

  public FellowLoader() {
    aValues = new Object[ColumnNames.length];
    for (int c = aValues.length - 1; c >= 0; c--) aValues[c] = null;
    iLastDomainId = 0;
    sLastGroupId = "";
    sLastGroupNm = "";
    oFellwCompanyMap=oFellwDivisionMap=oFellwDepartmentMap=oFellwLocationMap=null;
    oModMan = null;
  }

  // ---------------------------------------------------------------------------

  /**
   * Create FellowLoader and call prepare() on Connection
   * @param oConn Connection
   * @throws SQLException
   */
  public FellowLoader(Connection oConn) throws SQLException {
    prepare(oConn, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * Set all column values to null
   */
  public void setAllColumnsToNull() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin FellowLoader.setAllColumnsToNull()");
      DebugFile.incIdent();
    }

    for (int c=aValues.length-1; c>=0; c--)
      aValues[c] = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FellowLoader.setAllColumnsToNull()");
    }
  } // setAllColumnsToNull

  // ---------------------------------------------------------------------------

  /**
   * <p>Get column index at ColumnNames array given its name</p>
   * This method performs binary search assuming that ColumnNames is sorted in
   * ascending order
   * @param sColumnName String Column name (case insensitive)
   * @return int Column index or -1 if not found
   */
   public int getColumnIndex(String sColumnName) {
    int iIndex = Arrays.binarySearch(ColumnNames, sColumnName, String.CASE_INSENSITIVE_ORDER);
    if (iIndex<0) iIndex=-1;
    return iIndex;
  }

  // ---------------------------------------------------------------------------

  public int columnCount() {
    return aValues.length;
  }

  // ---------------------------------------------------------------------------

  public String[] columnNames() throws IllegalStateException {
    return ColumnNames;
  }

  // ---------------------------------------------------------------------------

   /**
    * Put value for a given column
    * @param iColumnIndex Column index [0..getColumnCount()-1]
    * @param oValue Value for column
    * @throws ArrayIndexOutOfBoundsException
    */
   public void put(int iColumnIndex, Object oValue)
     throws ArrayIndexOutOfBoundsException {
     aValues[iColumnIndex] = oValue;
   }

   // ---------------------------------------------------------------------------

   /**
    * <p>Put value for a given column</p>
    * If a previous value already exists then it is replaced
    * @param sColumnName Column name (case sensitive)
    * @param oValue Value for column
    * @throws ArrayIndexOutOfBoundsException
    */
   public void put(String sColumnName, Object oValue)
     throws ArrayIndexOutOfBoundsException {
     int iColumnIndex = getColumnIndex(sColumnName.toLowerCase());
     if (-1==iColumnIndex) throw new ArrayIndexOutOfBoundsException("Cannot find column named "+sColumnName);
     aValues[iColumnIndex] = oValue;
   }

   // ---------------------------------------------------------------------------

   /**
    * Put all values from a map on their corresponding columns matching by name
    * @param oValues Map
    */
   public void putAll(Map oValues) {
     int iColumnIndex;
     String sColumnName;
     if (DebugFile.trace) {
       DebugFile.writeln("Begin FellowLoader.putAll()");
       DebugFile.incIdent();
     }
     Iterator oIter = oValues.keySet().iterator();
     while (oIter.hasNext()) {
       sColumnName = (String) oIter.next();
       iColumnIndex = getColumnIndex(sColumnName.toLowerCase());
       if (iColumnIndex>0) {
         Object oVal = oValues.get(sColumnName);
         if (oVal==null)
           aValues[iColumnIndex] = null;
         else if  (oVal.getClass().getName().startsWith("[L")) {
           aValues[iColumnIndex] = java.lang.reflect.Array.get(oVal,0);
         } else {
           aValues[iColumnIndex] = oVal;
         }
         if (DebugFile.trace) DebugFile.writeln(sColumnName.toLowerCase()+"="+aValues[iColumnIndex]);
       } else {
         if (DebugFile.trace) DebugFile.writeln(sColumnName + " not found");
       }// fi (iColumnIndex)
     } // wend
     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End FellowLoader.putAll()");
     }
   } // putAll

   // ---------------------------------------------------------------------------

   /**
    * Get column by index
    * @param iColumnIndex int Colunm index [0..getColumnCount()-1]
    * @return Object Column value
    * @throws ArrayIndexOutOfBoundsException
    */
   public Object get(int iColumnIndex)
     throws ArrayIndexOutOfBoundsException {
     return aValues[iColumnIndex];
   } // get

   // ---------------------------------------------------------------------------

   /**
    * Get column by name
    * @param sColumnName String Column name (case sensitive)
    * @return Object Column value
    * @throws ArrayIndexOutOfBoundsException If no column with sucjh name was found
    */
   public Object get(String sColumnName)
     throws ArrayIndexOutOfBoundsException {
     int iColumnIndex = getColumnIndex(sColumnName.toLowerCase());
     if (-1==iColumnIndex) throw new ArrayIndexOutOfBoundsException("Cannot find column named "+sColumnName);
     return aValues[iColumnIndex];
   }

   // ---------------------------------------------------------------------------

   private String getColNull (int iColIndex)
     throws ArrayIndexOutOfBoundsException,ClassCastException {
     if (DebugFile.trace) {
       if (iColIndex<0 || iColIndex>=aValues.length)
         throw new ArrayIndexOutOfBoundsException("FellowLoader.getColNull() column index "+String.valueOf(iColIndex)+" must be in the range between 0 and "+String.valueOf(aValues.length));
       DebugFile.writeln("FellowLoader.getColNull("+String.valueOf(iColIndex)+") : "+aValues[iColIndex]);
     }
     String sRetVal;
     if (null==aValues[iColIndex])
       sRetVal = null;
     else {
       try {
         sRetVal = aValues[iColIndex].toString();
       } catch (ClassCastException cce){
         if (aValues[iColIndex]==null)
           throw new ClassCastException("FellowLoader.getColNull("+String.valueOf(iColIndex)+") could not cast null to String");
         else
           throw new ClassCastException("FellowLoader.getColNull("+String.valueOf(iColIndex)+") could not cast "+aValues[iColIndex].getClass().getName()+" "+aValues[iColIndex]+" to String");
       }
       if (sRetVal.length()==0 || sRetVal.equalsIgnoreCase("null"))
         sRetVal = null;
     }
     return sRetVal;
  } // getColNull

   // ---------------------------------------------------------------------------

   /**
    * <p>Prepare statements for execution</p>
    * This method needs to be called only once if the default constructor was used.<br>
    * If ContactLoader(Connection) constructor was used, there is no need to call prepare()
    * and a SQLException will be raised if the attempt is made.<br>
    * It is neccesary to call close() always for prepared instances as a failure
    * to do so will leave open cursors on the database causing it eventually to stop.
    * @param oConn Connection Open JDBC database connection
    * @param oColList ColumnList This parameter is ignored
    * @throws SQLException
    */
   public void prepare(Connection oConn, ColumnList oColList)
     throws SQLException {

     if (DebugFile.trace) {
       DebugFile.writeln("Begin FellowLoader.prepare()");
       DebugFile.incIdent();
     }

     oFellwCompanyMap=new HashMap();
     oFellwDivisionMap=new HashMap();
     oFellwDepartmentMap=new HashMap();
     oFellwLocationMap=new HashMap();

     oUserInsr = oConn.prepareStatement("INSERT INTO k_users (dt_created,id_domain,tx_nickname,tx_pwd,tx_pwd_sign,bo_change_pwd,bo_searchable,bo_active,len_quota,max_quota,tp_account,id_account,dt_last_update,dt_last_visit,dt_cancel,tx_main_email,tx_alt_email,nm_user,tx_surname1,tx_surname2,tx_challenge,tx_reply,dt_pwd_expires,gu_category,gu_workarea,nm_company,de_title,id_gender,dt_birth,ny_age,marital_status,tx_education,icq_id,sn_passport,tp_passport,tx_comments,gu_user) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
     oUserUpdt = oConn.prepareStatement("UPDATE k_users SET id_domain=?,tx_nickname=?,tx_pwd=?,tx_pwd_sign=?,bo_change_pwd=?,bo_searchable=?,bo_active=?,len_quota=?,max_quota=?,tp_account=?,id_account=?,dt_last_update=?,dt_last_visit=?,dt_cancel=?,tx_main_email=?,tx_alt_email=?,nm_user=?,tx_surname1=?,tx_surname2=?,tx_challenge=?,tx_reply=?,dt_pwd_expires=?,gu_category=?,gu_workarea=?,nm_company=?,de_title=?,id_gender=?,dt_birth=?,ny_age=?,marital_status=?,tx_education=?,icq_id=?,sn_passport=?,tp_passport=?,tx_comments=? WHERE gu_user=?");
     
     oFellwInsr = oConn.prepareStatement("INSERT INTO k_fellows (gu_workarea,id_domain,dt_modified,tx_company,id_ref,tx_name,tx_surname,de_title,id_gender,sn_passport,tp_passport,tx_dept,tx_division,tx_location,tx_email,work_phone,home_phone,mov_phone,ext_phone,tx_timezone,tx_comments,gu_fellow,dt_created) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
     oFellwUpdt = oConn.prepareStatement("UPDATE k_fellows gu_workarea=?,id_domain=?,dt_modified=?,tx_company=?,id_ref=?,tx_name=?,tx_surname=?,de_title=?,id_gender=?,sn_passport=?,tp_passport=?,tx_dept=?,tx_division=?,tx_location=?,tx_email=?,work_phone=?,home_phone=?,mov_phone=?,ext_phone=?,tx_timezone=?,tx_comments=? WHERE gu_fellow=?");
     
     oTitleInsr = oConn.prepareStatement("INSERT INTO k_lu_fellow_titles (id_title,tp_title,id_boss,im_salary_max,im_salary_min,de_title,gu_workarea) VALUES (?,?,?,?,?,?,?)");
     oTitleUpdt = oConn.prepareStatement("UPDATE k_lu_fellow_titles SET id_title=?,tp_title=?,id_boss=?,im_salary_max=?,im_salary_min=? WHERE de_title=? AND gu_workarea=?");

     oFellwLook = oConn.prepareStatement("SELECT NULL FROM k_fellows_lookup WHERE gu_owner=? AND id_section=? AND vl_lookup=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
     oFellwWook = oConn.prepareStatement("INSERT INTO k_fellows_lookup (gu_owner,id_section,pg_lookup,vl_lookup,"+ImportLoader.LOOUKP_TR_COLUMNS+") VALUES(?,?,?,?"+Gadgets.repeat(",?",ImportLoader.LOOUKP_TR_COUNT)+")");

     oGroupInsr= oConn.prepareStatement("INSERT INTO k_x_group_user (gu_user,gu_acl_group) VALUES(?,?)");

	 oModMan = new ModelManager();

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End FellowLoader.prepare()");
     }
   } // prepare

   // ---------------------------------------------------------------------------

   public void close() throws SQLException {
     if (null!=oFellwCompanyMap)    { oFellwCompanyMap.clear(); oFellwCompanyMap=null; }
     if (null!=oFellwDivisionMap)   { oFellwDivisionMap.clear(); oFellwDivisionMap=null; }
     if (null!=oFellwDepartmentMap) { oFellwDepartmentMap.clear(); oFellwDepartmentMap=null; }
     if (null!=oFellwLocationMap)   { oFellwLocationMap.clear(); oFellwLocationMap=null; }
     if (null!=oGroupInsr) { oGroupInsr.close(); oGroupInsr=null; }
     if (null!=oFellwLook) { oFellwLook.close(); oFellwLook=null; }
     if (null!=oFellwWook) { oFellwWook.close(); oFellwWook=null; }
     if (null!=oTitleUpdt) { oTitleUpdt.close(); oTitleUpdt=null; }
     if (null!=oTitleInsr) { oTitleInsr.close(); oFellwInsr=null; }
     if (null!=oFellwUpdt) { oFellwUpdt.close(); oFellwUpdt=null; }
     if (null!=oFellwInsr) { oFellwInsr.close(); oFellwInsr=null; }
     if (null!=oUserUpdt ) { oUserUpdt.close();  oUserUpdt=null; }
     if (null!=oUserInsr ) { oUserInsr.close();  oUserInsr=null; }
   } // close

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
   * @param oInsStmt PreparedStatement
   * @param oCacheMap HashMap
   * @throws SQLException
   */
  private void addLookUp(String sSection, String sValue, Connection oConn,
                         PreparedStatement oSelStmt, PreparedStatement oInsStmt,
                         HashMap oCacheMap) throws SQLException {
    String sTr;
    char[] aTr;
    final String EmptyStr = "";
    boolean bExistsLookup;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FellowLoader.addLookUp("+sSection+","+sValue+","+
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
          oInsStmt.setObject(1, get(gu_workarea), Types.CHAR);
          oInsStmt.setString(2, sSection);
          oInsStmt.setInt(3, DBLanguages.nextLookuUpProgressive(oConn, "k_fellows_lookup", (String) get(gu_workarea), sSection));
          oInsStmt.setObject(4, sValue, Types.VARCHAR);
          for (int t=5; t<5+LOOUKP_TR_COUNT; t++) oInsStmt.setString(t, sTr);
          oInsStmt.executeUpdate();
        } // fi (!bExistsLookup)
        oCacheMap.put(sValue, sValue);
      } // fi (!oCacheMap.containsKey(sValue))
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FellowLoader.addLookUp()");
    }
  } // addLookUp
  
   // ---------------------------------------------------------------------------

   public void store(Connection oConn, String sWorkArea, int iFlags)
     throws SQLException,IllegalArgumentException,NullPointerException,
            ClassCastException,NumberFormatException {

     if (oUserInsr==null || oUserUpdt==null)
       throw new SQLException("Invalid command sequece. Must call FellowLoader.prepare() before FellowLoader.store()");

     if (!test(iFlags,MODE_APPEND) && !test(iFlags,MODE_UPDATE))
       throw new IllegalArgumentException("FellowLoader.store() Flags bitmask must contain either MODE_APPEND, MODE_UPDATE or both");

	 if (null==aValues[gu_workarea] && null!=aValues[id_domain] && null!=aValues[nm_workarea]) {
	   aValues[gu_workarea] = WorkArea.getIdFromName(oConn, Integer.parseInt(aValues[id_domain].toString()), getColNull(nm_workarea));
	 }

     if (null==getColNull(id_domain)) {
       if (sWorkArea==null && null==get(gu_workarea)) {
         throw new NullPointerException("FellowLoader.store() id_domain cannot be null");
       } else if (null!=get(gu_workarea)) {
         aValues[id_domain] = ACLDomain.forWorkArea(oConn, (String) get(gu_workarea));
       } else {
         aValues[id_domain] = ACLDomain.forWorkArea(oConn, sWorkArea);       
       }
     } // fi

	 if (null==aValues[tx_main_email] && null==aValues[tx_email])
       throw new NullPointerException("FellowLoader.store() tx_main_email or tx_email cannot be null");
	 if (null==aValues[tx_main_email]) aValues[tx_main_email] = aValues[tx_email];
	 if (null==aValues[tx_email]) aValues[tx_email] = aValues[tx_main_email];
	 if (!Gadgets.checkEMail(getColNull(tx_main_email)))
       throw new IllegalArgumentException("FellowLoader.store() Illegal tx_main_email syntax "+get(tx_main_email));
	 if (!Gadgets.checkEMail(getColNull(tx_email)))
       throw new IllegalArgumentException("FellowLoader.store() Illegal tx_email syntax "+get(tx_main_email));

	 if (null==aValues[tx_company]) aValues[tx_company] = aValues[nm_company];
	 if (null==aValues[nm_company]) aValues[nm_company] = aValues[tx_company];

     if (DebugFile.trace) {
       DebugFile.writeln("Begin FellowLoader.store([Connection],"+sWorkArea+","+String.valueOf(iFlags)+")");
       DebugFile.incIdent();
       StringBuffer oRow = new StringBuffer();
       oRow.append('{');
       oRow.append(ColumnNames[0]+"=");
       oRow.append(aValues[0]==null ? "null" : aValues[0]);
       for (int d=1; d<aValues.length; d++) {
         oRow.append(","+ColumnNames[d]+"=");
         oRow.append(aValues[d]==null ? "null" : aValues[d]);
       } // next
       oRow.append('}');
       DebugFile.writeln(oRow.toString());
     }

     int iAffected = 0;
     Timestamp tsNow = new Timestamp(new Date().getTime());
     int iDomainId = Integer.parseInt(get(id_domain).toString());

     if (null==get(gu_workarea)) {
       if (DebugFile.trace) DebugFile.writeln("setting workarea to "+sWorkArea);
       put(gu_workarea, sWorkArea);
     } else {
       if (DebugFile.trace) DebugFile.writeln("workarea for current record is "+getColNull(gu_workarea));
     }

	 String sUserGuid;
     if (null==getColNull(gu_user) && null!=getColNull(tx_main_email)) {
       sUserGuid = ACLUser.getIdFromEmail(oConn, getColNull(tx_main_email));
       put(gu_user, sUserGuid);
       if (DebugFile.trace && sUserGuid!=null) DebugFile.writeln("setting user GUID to "+sUserGuid);       
     }

     if (null==getColNull(gu_user) && null!=getColNull(tx_nickname)) {
	   sUserGuid = ACLUser.getIdFromNick(oConn, iDomainId, getColNull(tx_nickname));
       put(gu_user, sUserGuid);
       if (DebugFile.trace && sUserGuid!=null) DebugFile.writeln("setting user GUID to "+sUserGuid);       
     }

     if (aValues[tx_nickname]==null) {
       put(tx_nickname, getColNull(tx_main_email).substring(0,getColNull(tx_main_email).indexOf('@')));
       if (DebugFile.trace) DebugFile.writeln("setting tx_nickname to "+aValues[tx_nickname]);              
     }

     if (test(iFlags,WRITE_LOOKUPS)) {
        addLookUp("tx_company", getColNull(tx_company), oConn, oFellwLook, oFellwWook, oFellwCompanyMap);
        addLookUp("tx_division", getColNull(tx_division), oConn, oFellwLook, oFellwWook, oFellwDivisionMap);
        addLookUp("tx_dept", getColNull(tx_dept), oConn, oFellwLook, oFellwWook, oFellwDepartmentMap);
        addLookUp("tx_location ", getColNull(tx_location ), oConn, oFellwLook, oFellwWook, oFellwLocationMap);
		if (aValues[de_title]!=null) {
		  oTitleUpdt.setString(1, getColNull(id_title));
		  oTitleUpdt.setString(2, getColNull(tp_title));
		  oTitleUpdt.setString(3, getColNull(id_boss));
		  if (aValues[im_salary_max]!=null)		  
		    oTitleUpdt.setFloat(4, Float.parseFloat(get(im_salary_max).toString()));
		  else
		  	oTitleUpdt.setNull(4, Types.FLOAT);
		  if (aValues[im_salary_min]!=null)		  
		    oTitleUpdt.setFloat(5, Float.parseFloat(get(im_salary_min).toString()));
		  else
		  	oTitleUpdt.setNull(5, Types.FLOAT);
		  oTitleUpdt.setString(6, getColNull(de_title));
		  oTitleUpdt.setString(7, getColNull(gu_workarea));
		  iAffected = oTitleUpdt.executeUpdate();
		  if (0==iAffected) {
		    oTitleInsr.setString(1, getColNull(id_title));
		    oTitleInsr.setString(2, getColNull(tp_title));
		    oTitleInsr.setString(3, getColNull(id_boss));
		    if (aValues[im_salary_max]!=null)		  
		      oTitleInsr.setFloat(4, Float.parseFloat(get(im_salary_max).toString()));
		    else
		  	  oTitleInsr.setNull(4, Types.FLOAT);
		    if (aValues[im_salary_min]!=null)		  
		      oTitleInsr.setFloat(5, Float.parseFloat(get(im_salary_min).toString()));
		    else
		  	  oTitleInsr.setNull(5, Types.FLOAT);
		    oTitleInsr.setString(6, getColNull(de_title));
		    oTitleInsr.setString(7, getColNull(gu_workarea));
		    oTitleInsr.executeUpdate();
		  }
		} // fi (de_title)
     } // if (test(WRITE_LOOKUPS))

     if (test(iFlags,MODE_UPDATE) && null!=getColNull(gu_user)) {
        oUserUpdt.setInt(1, iDomainId);
        oUserUpdt.setObject(2, get(tx_nickname), Types.VARCHAR);
        oUserUpdt.setObject(3, get(tx_pwd), Types.VARCHAR);
        oUserUpdt.setObject(4, get(tx_pwd_sign), Types.VARCHAR);
        oUserUpdt.setObject(5, get(bo_change_pwd), Types.SMALLINT);
        oUserUpdt.setObject(6, get(bo_searchable), Types.SMALLINT);
        oUserUpdt.setObject(7, get(bo_active), Types.SMALLINT);
        oUserUpdt.setObject(8, get(len_quota), Types.DECIMAL);
        oUserUpdt.setObject(9, get(max_quota), Types.DECIMAL);
        oUserUpdt.setObject(10, get(tp_account), Types.CHAR);
        oUserUpdt.setObject(11, get(id_account), Types.CHAR);
        if (aValues[dt_last_update]==null)
          oUserUpdt.setTimestamp(12, tsNow);
        else
          oUserUpdt.setObject(12, aValues[dt_last_update], Types.TIMESTAMP);
        if (aValues[dt_last_visit]==null)
          oUserUpdt.setNull(13, Types.TIMESTAMP);
        else
          oUserUpdt.setObject(13, aValues[dt_last_visit], Types.TIMESTAMP);
        if (aValues[dt_cancel]==null)
          oUserUpdt.setNull(14, Types.TIMESTAMP);
        else
          oUserUpdt.setObject(14, aValues[dt_cancel], Types.TIMESTAMP);
        oUserUpdt.setObject(15, get(tx_main_email), Types.VARCHAR);
        oUserUpdt.setObject(16, get(tx_alt_email), Types.VARCHAR);
        oUserUpdt.setObject(17, get(nm_user), Types.VARCHAR);
        oUserUpdt.setObject(18, get(tx_surname1), Types.VARCHAR);
        oUserUpdt.setObject(19, get(tx_surname2), Types.VARCHAR);
        oUserUpdt.setObject(20, get(tx_challenge), Types.VARCHAR);
        oUserUpdt.setObject(21, get(tx_reply), Types.VARCHAR);
        if (aValues[dt_pwd_expires]==null)
          oUserUpdt.setNull(22, Types.TIMESTAMP);
        else
          oUserUpdt.setObject(22, aValues[dt_pwd_expires], Types.TIMESTAMP);
        oUserUpdt.setObject(23, get(gu_category), Types.CHAR);
        oUserUpdt.setObject(24, get(gu_workarea), Types.CHAR);
        oUserUpdt.setObject(25, get(nm_company), Types.VARCHAR);
        oUserUpdt.setObject(26, get(de_title), Types.VARCHAR);
        oUserUpdt.setObject(27, get(id_gender), Types.CHAR);
        if (aValues[dt_birth]==null)
          oUserUpdt.setNull(28, Types.TIMESTAMP);
        else
          oUserUpdt.setObject(28, aValues[dt_birth], Types.TIMESTAMP);
        oUserUpdt.setObject(29, get(ny_age), Types.SMALLINT);
        oUserUpdt.setObject(30, get(marital_status), Types.CHAR);
        oUserUpdt.setObject(31, get(tx_education), Types.VARCHAR);
        oUserUpdt.setObject(32, get(icq_id), Types.VARCHAR);
        oUserUpdt.setObject(33, get(sn_passport), Types.VARCHAR);
        oUserUpdt.setObject(34, get(tp_passport), Types.VARCHAR);
        oUserUpdt.setObject(35, get(tx_comments), Types.VARCHAR);
        oUserUpdt.setString(36, getColNull(gu_user));
        iAffected = oUserUpdt.executeUpdate();
      }

      if (0==iAffected && test(iFlags,MODE_APPEND)) {
        aValues[gu_user] = Gadgets.generateUUID();
        oUserInsr.setTimestamp(1, tsNow);
        oUserInsr.setInt(2, iDomainId);
        oUserInsr.setObject(3, get(tx_nickname), Types.VARCHAR);
        oUserInsr.setObject(4, get(tx_pwd), Types.VARCHAR);
        oUserInsr.setObject(5, get(tx_pwd_sign), Types.VARCHAR);
        oUserInsr.setObject(6, get(bo_change_pwd), Types.SMALLINT);
        oUserInsr.setObject(7, get(bo_searchable), Types.SMALLINT);
        oUserInsr.setObject(8, get(bo_active), Types.SMALLINT);
        oUserInsr.setObject(9, get(len_quota), Types.DECIMAL);
        oUserInsr.setObject(10, get(max_quota), Types.DECIMAL);
        oUserInsr.setObject(11, get(tp_account), Types.CHAR);
        oUserInsr.setObject(12, get(id_account), Types.CHAR);
        if (aValues[dt_last_update]==null)
          oUserInsr.setTimestamp(13, tsNow);
        else
          oUserInsr.setObject(13, aValues[dt_last_update], Types.TIMESTAMP);
        if (aValues[dt_last_visit]==null)
          oUserInsr.setNull(14, Types.TIMESTAMP);
        else
          oUserInsr.setObject(14, aValues[dt_last_visit], Types.TIMESTAMP);
        if (aValues[dt_cancel]==null)
          oUserInsr.setNull(15, Types.TIMESTAMP);
        else
          oUserInsr.setObject(15, aValues[dt_cancel], Types.TIMESTAMP);
        oUserInsr.setObject(16, get(tx_main_email), Types.VARCHAR);
        oUserInsr.setObject(17, get(tx_alt_email), Types.VARCHAR);
        oUserInsr.setObject(18, get(nm_user), Types.VARCHAR);
        oUserInsr.setObject(19, get(tx_surname1), Types.VARCHAR);
        oUserInsr.setObject(20, get(tx_surname2), Types.VARCHAR);
        oUserInsr.setObject(21, get(tx_challenge), Types.VARCHAR);
        oUserInsr.setObject(22, get(tx_reply), Types.VARCHAR);
        if (aValues[dt_pwd_expires]==null)
          oUserInsr.setNull(23, Types.TIMESTAMP);
        else
          oUserInsr.setObject(23, aValues[dt_pwd_expires], Types.TIMESTAMP);
        oUserInsr.setObject(24, get(gu_category), Types.CHAR);
        oUserInsr.setObject(25, get(gu_workarea), Types.CHAR);
        oUserInsr.setObject(26, get(nm_company), Types.VARCHAR);
        oUserInsr.setObject(27, get(de_title), Types.VARCHAR);
        oUserInsr.setObject(28, get(id_gender), Types.CHAR);
        if (aValues[dt_birth]==null)
          oUserInsr.setNull(29, Types.TIMESTAMP);
        else
          oUserInsr.setObject(29, aValues[dt_birth], Types.TIMESTAMP);
        oUserInsr.setObject(30, get(ny_age), Types.SMALLINT);
        oUserInsr.setObject(31, get(marital_status), Types.CHAR);
        oUserInsr.setObject(32, get(tx_education), Types.VARCHAR);
        oUserInsr.setObject(33, get(icq_id), Types.VARCHAR);
        oUserInsr.setObject(34, get(sn_passport), Types.VARCHAR);
        oUserInsr.setObject(35, get(tp_passport), Types.VARCHAR);
        oUserInsr.setObject(36, get(tx_comments), Types.VARCHAR);
        oUserInsr.setString(37, getColNull(gu_user));
        oUserInsr.execute();
        oModMan.setConnection(oConn);
		try {
	      oModMan.createCategoriesForUser(getColNull(gu_user));
        } catch (java.io.IOException ioe) {
          throw new SQLException("IOException "+ioe.getMessage());
        } 
      }

      if (null==aValues[gu_acl_group] && null!=aValues[nm_acl_group]) {
        if (iDomainId==iLastDomainId && sLastGroupNm.equals(aValues[nm_acl_group])) {
          put (gu_acl_group, sLastGroupId);
        } else {
          put(gu_acl_group, ACLGroup.getIdFromName(oConn, iDomainId, getColNull(nm_acl_group)));
          iLastDomainId=iDomainId;
          sLastGroupNm=getColNull(nm_acl_group);
          sLastGroupId=getColNull(gu_acl_group);
        }
      }

      if (null!=aValues[gu_acl_group]) {
        oGroupInsr.setString(1, getColNull(gu_user));
        oGroupInsr.setString(1, getColNull(gu_acl_group));
        try {
          oGroupInsr.execute();
        } catch (SQLException ignore) {
          if (DebugFile.trace)
            DebugFile.writeln("FellowLoader.store() User "+getColNull(tx_nickname)+"("+getColNull(gu_user)+") already exists at group "+getColNull(nm_acl_group)+"("+getColNull(gu_acl_group)+")");
        }
      } // fi

      if (test(iFlags,MODE_UPDATE)) {
        oFellwUpdt.setObject(1, get(gu_workarea), Types.CHAR);
        oFellwUpdt.setInt(2, iDomainId);
        oFellwUpdt.setTimestamp(3, tsNow);
        oFellwUpdt.setObject(4, get(tx_company), Types.VARCHAR);
        oFellwUpdt.setObject(5, get(id_ref), Types.VARCHAR);
		if (aValues[tx_name]!=null)
          oFellwUpdt.setObject(6, get(tx_name), Types.VARCHAR);
		else if (aValues[nm_user]!=null)
          oFellwUpdt.setObject(6, get(nm_user), Types.VARCHAR);
        else if (aValues[tx_nickname]!=null)
          oFellwUpdt.setObject(6, get(tx_nickname), Types.VARCHAR);
		else
		  oFellwUpdt.setNull(6, Types.VARCHAR);
		if (aValues[tx_surname]!=null)
          oFellwUpdt.setObject(7, get(tx_surname), Types.VARCHAR);
		else if (aValues[tx_surname1]!=null)
          oFellwUpdt.setObject(7, Gadgets.left(get(tx_surname1)+(aValues[tx_surname2]!=null ? " "+get(tx_surname2) : ""),100), Types.VARCHAR);
		else
		  oFellwUpdt.setNull(7, Types.VARCHAR);
        oFellwUpdt.setObject(8, get(de_title), Types.VARCHAR);
        oFellwUpdt.setObject(9, get(id_gender), Types.VARCHAR);
        oFellwUpdt.setObject(10, get(sn_passport), Types.VARCHAR);
        oFellwUpdt.setObject(11, get(tp_passport), Types.VARCHAR);
        oFellwUpdt.setObject(12, get(tx_dept), Types.VARCHAR);
        oFellwUpdt.setObject(13, get(tx_division), Types.VARCHAR);
        oFellwUpdt.setObject(14, get(tx_location), Types.VARCHAR);
        if (aValues[tx_email]!=null)
          oFellwUpdt.setObject(15, get(tx_email), Types.VARCHAR);
        else if (aValues[tx_main_email]!=null)
          oFellwUpdt.setObject(15, get(tx_main_email), Types.VARCHAR);
        oFellwUpdt.setObject(16, get(work_phone), Types.VARCHAR);
        oFellwUpdt.setObject(17, get(home_phone), Types.VARCHAR);
        oFellwUpdt.setObject(18, get(mov_phone), Types.VARCHAR);
        oFellwUpdt.setObject(19, get(ext_phone), Types.VARCHAR);
        oFellwUpdt.setObject(20, get(tx_timezone), Types.VARCHAR);
        oFellwUpdt.setObject(21, get(tx_comments), Types.VARCHAR);
        oFellwUpdt.setObject(22, get(gu_user), Types.CHAR);
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");
        iAffected = oFellwUpdt.executeUpdate();
        if (DebugFile.trace) DebugFile.writeln("affected rows "+String.valueOf(iAffected));
      } // fi (MODE_UPDATE)
      
      if (0==iAffected && test(iFlags,MODE_APPEND)) {
        oFellwInsr.setObject(1, get(gu_workarea), Types.CHAR);
        oFellwInsr.setInt(2, iDomainId);
        oFellwInsr.setTimestamp(3, tsNow);
        oFellwInsr.setObject(4, get(tx_company), Types.VARCHAR);
        oFellwInsr.setObject(5, get(id_ref), Types.VARCHAR);
		if (aValues[tx_name]!=null)
          oFellwInsr.setObject(6, get(tx_name), Types.VARCHAR);
		else if (aValues[nm_user]!=null)
          oFellwInsr.setObject(6, get(nm_user), Types.VARCHAR);
        else if (aValues[tx_nickname]!=null)
          oFellwInsr.setObject(6, get(tx_nickname), Types.VARCHAR);
		else
		  oFellwInsr.setNull(6, Types.VARCHAR);
		if (aValues[tx_surname]!=null)
          oFellwInsr.setObject(7, get(tx_surname), Types.VARCHAR);
		else if (aValues[tx_surname1]!=null)
          oFellwInsr.setObject(7, Gadgets.left(get(tx_surname1)+(aValues[tx_surname2]!=null ? " "+get(tx_surname2) : ""),100), Types.VARCHAR);
		else
		  oFellwInsr.setNull(7, Types.VARCHAR);
        oFellwInsr.setObject(8, get(de_title), Types.VARCHAR);
        oFellwInsr.setObject(9, get(id_gender), Types.VARCHAR);
        oFellwInsr.setObject(10, get(sn_passport), Types.VARCHAR);
        oFellwInsr.setObject(11, get(tp_passport), Types.VARCHAR);
        oFellwInsr.setObject(12, get(tx_dept), Types.VARCHAR);
        oFellwInsr.setObject(13, get(tx_division), Types.VARCHAR);
        oFellwInsr.setObject(14, get(tx_location), Types.VARCHAR);
        if (aValues[tx_email]!=null)
          oFellwInsr.setObject(15, get(tx_email), Types.VARCHAR);
        else if (aValues[tx_main_email]!=null)
          oFellwInsr.setObject(15, get(tx_main_email), Types.VARCHAR);
        else
          oFellwInsr.setNull(15, Types.VARCHAR);
        oFellwInsr.setObject(16, get(work_phone), Types.VARCHAR);
        oFellwInsr.setObject(17, get(home_phone), Types.VARCHAR);
        oFellwInsr.setObject(18, get(mov_phone), Types.VARCHAR);
        oFellwInsr.setObject(19, get(ext_phone), Types.VARCHAR);
        oFellwInsr.setObject(20, get(tx_timezone), Types.VARCHAR);
        oFellwInsr.setObject(21, get(tx_comments), Types.VARCHAR);
        oFellwInsr.setObject(22, get(gu_user), Types.CHAR);
        oFellwInsr.setTimestamp(23, tsNow);
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.execute()");
        oFellwInsr.execute();
      } // fi (iAffected=0 && MODE_APPEND)

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End FellowLoader.store()");
      }
   } // store

  // ---------------------------------------------------------------------------

  public static final int MODE_APPEND = ImportLoader.MODE_APPEND;
  public static final int MODE_UPDATE = ImportLoader.MODE_UPDATE;
  public static final int MODE_APPENDUPDATE = ImportLoader.MODE_APPENDUPDATE;
  public static final int WRITE_LOOKUPS = ImportLoader.WRITE_LOOKUPS;

   // ---------------------------------------------------------------------------

  // Keep this list sorted
  private static final String[] ColumnNames = {"", "bo_active","bo_change_pwd","bo_searchable","de_title","dt_birth","dt_cancel","dt_created","dt_last_update","dt_last_visit","dt_modified","dt_pwd_expires","ext_phone","gu_acl_group","gu_category","gu_fellow","gu_user","gu_workarea","home_phone","icq_id","id_account","id_boss","id_domain","id_gender","id_ref","id_title","im_salary_max","im_salary_min","len_quota","marital_status","max_quota","mov_phone","nm_acl_group","nm_company","nm_user","nm_workarea","ny_age","sn_passport","tp_account","tp_passport","tp_title","tx_alt_email","tx_challenge","tx_comments","tx_company","tx_dept","tx_division","tx_education","tx_email","tx_location","tx_main_email","tx_name","tx_nickname","tx_pwd","tx_pwd_sign","tx_reply","tx_surname","tx_surname1","tx_surname2","tx_timezone","work_phone" };

  // Keep these column indexes in sync with ColumnNames array
  public static int bo_active = 1;
  public static int bo_change_pwd = 2;
  public static int bo_searchable = 3;
  public static int de_title = 4;
  public static int dt_birth = 5;
  public static int dt_cancel = 6;
  public static int dt_created = 7;
  public static int dt_last_update = 8;
  public static int dt_last_visit = 9;
  public static int dt_modified = 10;
  public static int dt_pwd_expires = 11;
  public static int ext_phone = 12;
  public static int gu_acl_group = 13;
  public static int gu_category = 14;
  public static int gu_fellow = 15;
  public static int gu_user = 16;
  public static int gu_workarea = 17;
  public static int home_phone = 18;
  public static int icq_id = 19;
  public static int id_account = 20;
  public static int id_boss = 21;
  public static int id_domain = 22;
  public static int id_gender = 23;
  public static int id_ref = 24;
  public static int id_title = 25;
  public static int im_salary_max = 26;
  public static int im_salary_min = 27;
  public static int len_quota = 28;
  public static int marital_status = 29;
  public static int max_quota = 30;
  public static int mov_phone = 31;
  public static int nm_acl_group = 32;
  public static int nm_company = 33;
  public static int nm_user = 34;
  public static int nm_workarea = 35;
  public static int ny_age = 36;
  public static int sn_passport = 37;
  public static int tp_account = 38;
  public static int tp_passport = 39;
  public static int tp_title = 40;
  public static int tx_alt_email = 41;
  public static int tx_challenge = 42;
  public static int tx_comments = 43;
  public static int tx_company = 44;
  public static int tx_dept = 45;
  public static int tx_division = 46;
  public static int tx_education = 47;
  public static int tx_email = 48;
  public static int tx_location = 49;
  public static int tx_main_email = 50;
  public static int tx_name = 51;
  public static int tx_nickname = 52;
  public static int tx_pwd = 53;
  public static int tx_pwd_sign = 54;
  public static int tx_reply = 55;
  public static int tx_surname = 56;
  public static int tx_surname1 = 57;
  public static int tx_surname2 = 58;
  public static int tx_timezone = 59;
  public static int work_phone = 60;


}
