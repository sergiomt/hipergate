/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

package com.knowgate.acl;

import java.util.Map;
import java.util.Date;
import java.util.Arrays;
import java.util.Iterator;

import java.sql.Types;
import java.sql.Timestamp;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;

import com.knowgate.acl.ACLUser;
import com.knowgate.acl.ACLGroup;
import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.hipergate.datamodel.ImportLoader;
import com.knowgate.hipergate.datamodel.ColumnList;
import com.knowgate.hipergate.datamodel.ModelManager;
import com.knowgate.workareas.WorkArea;

/**
 * <p>Load user data from a single source</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public final class UserLoader implements ImportLoader {

  private Object[] aValues;

  private PreparedStatement oUserUpdt, oUserInsr, oGroupInsr;
  private int iLastDomainId;
  private String sLastGroupId, sLastGroupNm;
  private ModelManager oModMan;

  public UserLoader() {
    aValues = new Object[ColumnNames.length];
    for (int c = aValues.length - 1; c >= 0; c--) aValues[c] = null;
    iLastDomainId = 0;
    sLastGroupId = "";
    sLastGroupNm = "";
    oModMan = null;
  }

  // ---------------------------------------------------------------------------

  /**
   * Create UserLoader and call prepare() on Connection
   * @param oConn Connection
   * @throws SQLException
   */
  public UserLoader(Connection oConn) throws SQLException {
    prepare(oConn, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * Set all column values to null
   */
  public void setAllColumnsToNull() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin UserLoader.setAllColumnsToNull()");
      DebugFile.incIdent();
    }

    for (int c=aValues.length-1; c>=0; c--)
      aValues[c] = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End UserLoader.setAllColumnsToNull()");
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
       DebugFile.writeln("Begin UserLoader.putAll()");
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
       DebugFile.writeln("End UserLoader.putAll()");
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
         throw new ArrayIndexOutOfBoundsException("UserLoader.getColNull() column index "+String.valueOf(iColIndex)+" must be in the range between 0 and "+String.valueOf(aValues.length));
       DebugFile.writeln("UserLoader.getColNull("+String.valueOf(iColIndex)+") : "+aValues[iColIndex]);
     }
     String sRetVal;
     if (null==aValues[iColIndex])
       sRetVal = null;
     else {
       try {
         sRetVal = aValues[iColIndex].toString();
       } catch (ClassCastException cce){
         if (aValues[iColIndex]==null)
           throw new ClassCastException("UserLoader.getColNull("+String.valueOf(iColIndex)+") could not cast null to String");
         else
           throw new ClassCastException("UserLoader.getColNull("+String.valueOf(iColIndex)+") could not cast "+aValues[iColIndex].getClass().getName()+" "+aValues[iColIndex]+" to String");
       }
       if (sRetVal.length()==0 || sRetVal.equalsIgnoreCase("null"))
         sRetVal = null;
     }
     return sRetVal;
  } // getColNull

   // ---------------------------------------------------------------------------

   private static boolean test(int iInputValue, int iBitMask) {
     return (iInputValue&iBitMask)!=0;
   } // test

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
       DebugFile.writeln("Begin UserLoader.prepare()");
       DebugFile.incIdent();
     }

     oUserInsr = oConn.prepareStatement("INSERT INTO k_users (dt_created,id_domain,tx_nickname,tx_pwd,tx_pwd_sign,bo_change_pwd,bo_searchable,bo_active,len_quota,max_quota,tp_account,id_account,dt_last_update,dt_last_visit,dt_cancel,tx_main_email,tx_alt_email,nm_user,tx_surname1,tx_surname2,tx_challenge,tx_reply,dt_pwd_expires,gu_category,gu_workarea,nm_company,de_title,id_gender,dt_birth,ny_age,marital_status,tx_education,icq_id,sn_passport,tp_passport,tx_comments,gu_user) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
     oUserUpdt = oConn.prepareStatement("UPDATE k_users SET id_domain=?,tx_nickname=?,tx_pwd=?,tx_pwd_sign=?,bo_change_pwd=?,bo_searchable=?,bo_active=?,len_quota=?,max_quota=?,tp_account=?,id_account=?,dt_last_update=?,dt_last_visit=?,dt_cancel=?,tx_main_email=?,tx_alt_email=?,nm_user=?,tx_surname1=?,tx_surname2=?,tx_challenge=?,tx_reply=?,dt_pwd_expires=?,gu_category=?,gu_workarea=?,nm_company=?,de_title=?,id_gender=?,dt_birth=?,ny_age=?,marital_status=?,tx_education=?,icq_id=?,sn_passport=?,tp_passport=?,tx_comments=? WHERE gu_user=?");
     oGroupInsr= oConn.prepareStatement("INSERT INTO k_x_group_user (gu_user,gu_acl_group) VALUES(?,?)");

     oModMan = new ModelManager();

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End UserLoader.prepare()");
     }
   }

   // ---------------------------------------------------------------------------

   public void close() throws SQLException {
     if (null!=oGroupInsr) { oGroupInsr.close();  oGroupInsr=null; }
     if (null!=oUserUpdt ) { oUserUpdt.close();  oUserUpdt=null; }
     if (null!=oUserInsr ) { oUserInsr.close();  oUserInsr=null; }
   }

   // ---------------------------------------------------------------------------

   public void store(Connection oConn, String sWorkArea, int iFlags)
     throws SQLException,IllegalArgumentException,NullPointerException,
            ClassCastException,NumberFormatException {

     if (oUserInsr==null || oUserUpdt==null)
       throw new SQLException("Invalid command sequece. Must call UserLoader.prepare() before UserLoader.store()");

     if (!test(iFlags,MODE_APPEND) && !test(iFlags,MODE_UPDATE))
       throw new IllegalArgumentException("UserLoader.store() Flags bitmask must contain either MODE_APPEND, MODE_UPDATE or both");

	 if (null==aValues[gu_workarea] && null!=aValues[id_domain] && null!=aValues[nm_workarea]) {
	   aValues[gu_workarea] = WorkArea.getIdFromName(oConn, Integer.parseInt(aValues[id_domain].toString()), getColNull(nm_workarea));
	 }
	 
     if (null==aValues[id_domain]) {
       if (sWorkArea==null && null==get(gu_workarea)) {
         throw new NullPointerException("UserLoader.store() id_domain cannot be null");
       } else if (null!=get(gu_workarea)) {
         aValues[id_domain] = ACLDomain.forWorkArea(oConn, (String) get(gu_workarea));
       } else {
         aValues[id_domain] = ACLDomain.forWorkArea(oConn, sWorkArea);       
       }
     } // fi

	 if (null==getColNull(tx_main_email)) {
       throw new NullPointerException("UserLoader.store() tx_main_email cannot be null");
	 } else if (!Gadgets.checkEMail(getColNull(tx_main_email))) {	   
       throw new IllegalArgumentException("UserLoader.store() Illegal tx_main_email syntax "+get(tx_main_email));
	 }

     if (DebugFile.trace) {
       DebugFile.writeln("Begin UserLoader.store([Connection],"+sWorkArea+","+String.valueOf(iFlags)+")");
       DebugFile.incIdent();
       StringBuffer oRow = new StringBuffer();
       oRow.append('{');
       for (int d=1; d<aValues.length; d++) {
         oRow.append((d>1 ? "," : "")+ColumnNames[d]+"=");
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
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");
        iAffected = oUserUpdt.executeUpdate();
        if (DebugFile.trace) DebugFile.writeln("affected rows "+String.valueOf(iAffected));
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
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.execute()");
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
            DebugFile.writeln("UserLoader.store() User "+getColNull(tx_nickname)+"("+getColNull(gu_user)+") already exists at group "+getColNull(nm_acl_group)+"("+getColNull(gu_acl_group)+")");
            oGroupInsr.close();
            oGroupInsr= oConn.prepareStatement("INSERT INTO k_x_group_user (gu_user,gu_acl_group) VALUES(?,?)");
        }
      } // fi

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End UserLoader.store()");
      }
   } // store

  // ---------------------------------------------------------------------------

  public static final int MODE_APPEND = ImportLoader.MODE_APPEND;
  public static final int MODE_UPDATE = ImportLoader.MODE_UPDATE;
  public static final int MODE_APPENDUPDATE = ImportLoader.MODE_APPENDUPDATE;

   // ---------------------------------------------------------------------------

  // Keep this list sorted
  private static final String[] ColumnNames = { "","bo_active","bo_change_pwd","bo_searchable","de_title","dt_birth","dt_cancel","dt_created","dt_last_update","dt_last_visit","dt_pwd_expires","gu_acl_group","gu_category","gu_user","gu_workarea","icq_id","id_account","id_domain","id_gender","len_quota","marital_status","max_quota","nm_acl_group","nm_company","nm_user","nm_workarea","ny_age","sn_passport","tp_account","tp_passport","tx_alt_email","tx_challenge","tx_comments","tx_education","tx_main_email","tx_nickname","tx_pwd","tx_pwd_sign","tx_reply","tx_surname1","tx_surname2"};

  // Keep these column indexes in sync with ColumnNames array
  public static int bo_active= 1;
  public static int bo_change_pwd= 2;
  public static int bo_searchable= 3;
  public static int de_title= 4;
  public static int dt_birth= 5;
  public static int dt_cancel= 6;
  public static int dt_created= 7;
  public static int dt_last_update= 8;
  public static int dt_last_visit= 9;
  public static int dt_pwd_expires= 10;
  public static int gu_acl_group= 11;
  public static int gu_category= 12;
  public static int gu_user= 13;
  public static int gu_workarea= 14;
  public static int icq_id= 15;
  public static int id_account= 16;
  public static int id_domain= 17;
  public static int id_gender= 18;
  public static int len_quota= 19;
  public static int marital_status= 20;
  public static int max_quota= 21;
  public static int nm_acl_group= 22;
  public static int nm_company= 23;
  public static int nm_user= 24;
  public static int nm_workarea= 25;
  public static int ny_age= 26;
  public static int sn_passport= 27;
  public static int tp_account= 28;
  public static int tp_passport= 29;
  public static int tx_alt_email= 30;
  public static int tx_challenge= 31;
  public static int tx_comments= 32;
  public static int tx_education= 33;
  public static int tx_main_email= 34;
  public static int tx_nickname= 35;
  public static int tx_pwd= 36;
  public static int tx_pwd_sign= 37;
  public static int tx_reply= 38;
  public static int tx_surname1= 39;
  public static int tx_surname2= 40;

}
