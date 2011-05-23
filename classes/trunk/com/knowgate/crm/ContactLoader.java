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

package com.knowgate.crm;

import java.util.Date;
import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;
import java.util.Arrays;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.dataobjs.DB;
import com.knowgate.crm.DistributionList;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipergate.Address;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.hipergate.datamodel.ColumnList;
import com.knowgate.hipergate.datamodel.ImportLoader;

/**
 * <p>Load Contact, Company and Address data from a single source</p>
 * Contact loader creates or updates simultaneously registers at k_companies,
 * k_contacts and k_addresses tables and the links between them k_x_contact_addr.
 * @author Sergio Montoro Ten
 * @version 6.0
 */
public final class ContactLoader implements ImportLoader {

  // ---------------------------------------------------------------------------

  private Object[] aValues;
  private PreparedStatement oCompUpdt, oContUpdt, oAddrUpdt;
  private PreparedStatement oCompInst, oContInst, oAddrInst, oContAddr, oCompAddr;
  private PreparedStatement oCompLook, oContLook, oAddrLook;
  private PreparedStatement oCompWook, oContWook, oAddrWook;
  private PreparedStatement oCompName, oContPort, oContMail;
  private PreparedStatement oAddrComp, oAddrCont;
  private HashMap<String,DistributionList> oListsMap;
  private HashMap<String,String> oCompSectorsMap, oCompStatusMap, oCompTypesMap;
  private HashMap<String,String> oContGendersMap, oContStatusMap, oContDeptsMap, oContDivsMap, oContTitlesMap;
  private HashMap<String,String> oAddrLocsMap, oAddrTypesMap, oAddrSalutMap;

  // ---------------------------------------------------------------------------

  private void init() {
    aValues = new Object[ColumnNames.length];
    Arrays.fill(aValues, null);
    oCompInst=oContInst=oAddrInst=oContAddr=oCompAddr=null;
    oCompUpdt=oContUpdt=oAddrUpdt=null;
    oCompLook=oContLook=oAddrLook=null;
    oListsMap = new HashMap<String,DistributionList>();
    oCompSectorsMap = new HashMap<String,String>();
    oCompStatusMap = new HashMap<String,String>();
    oCompTypesMap = new HashMap<String,String>();
    oContGendersMap = new HashMap<String,String>();
    oContStatusMap = new HashMap<String,String>();
    oContDeptsMap = new HashMap<String,String>();
    oContDivsMap = new HashMap<String,String>();
    oContTitlesMap = new HashMap<String,String>();
    oAddrLocsMap = new HashMap<String,String>();
    oAddrTypesMap = new HashMap<String,String>();
    oAddrSalutMap = new HashMap<String,String>();
  }

  // ---------------------------------------------------------------------------

  /**
   * Default construtor
   */
  public ContactLoader() {
    init();
  }

  // ---------------------------------------------------------------------------

  /**
   * Create ContactLoader and call prepare() on Connection
   * @param oConn Connection
   * @throws SQLException
   */
  public ContactLoader(Connection oConn) throws SQLException {
    init();
    prepare(oConn, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * Set all column values to null
   */
  public void setAllColumnsToNull() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin ContactLoader.setAllColumnsToNull()");
      DebugFile.incIdent();
    }

    Arrays.fill(aValues, null);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ContactLoader.setAllColumnsToNull()");
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
      DebugFile.writeln("Begin ContactLoader.putAll()");
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
      DebugFile.writeln("End ContactLoader.putAll()");
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
      DebugFile.writeln("Begin ContactLoader.prepare()");
      DebugFile.incIdent();
    }

    if (oCompUpdt!=null || oCompInst!=null || oCompLook!=null || oCompWook!=null || oContAddr!=null || oContAddr!=null) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new SQLException("Either ContactLoader.prepare() has already been called or statements were not properly closed","HY010");
    }

    oCompUpdt = oConn.prepareStatement("UPDATE k_companies SET nm_legal=?,gu_workarea=?,nm_commercial=?,dt_modified=?,dt_founded=?,id_legal=?,id_sector=?,id_status=?,id_ref=?,tp_company=?,gu_geozone=?,nu_employees=?,im_revenue=?,gu_sales_man=?,tx_franchise=?,de_company=? WHERE gu_company=? OR (nm_legal=? AND gu_workarea=?)");
    oCompInst = oConn.prepareStatement("INSERT INTO k_companies (nm_legal,gu_workarea,nm_commercial,dt_modified,dt_founded,id_legal,id_sector,id_status,id_ref,tp_company,gu_geozone,nu_employees,im_revenue,gu_sales_man,tx_franchise,de_company,gu_company) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    oCompLook = oConn.prepareStatement("SELECT NULL FROM k_companies_lookup WHERE gu_owner=? AND id_section=? AND vl_lookup=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oCompName = oConn.prepareStatement("SELECT gu_company FROM k_companies WHERE nm_legal=? AND gu_workarea=?",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oContUpdt = oConn.prepareStatement("UPDATE k_contacts SET gu_workarea=?,tx_nickname=?,tx_pwd=?,tx_challenge=?,tx_reply=?,dt_pwd_expires=?,dt_modified=?,gu_writer=?,gu_company=?,id_status=?,id_ref=?,tx_name=?,tx_surname=?,de_title=?,id_gender=?,dt_birth=?,ny_age=?,sn_passport=?,tp_passport=?,sn_drivelic=?,dt_drivelic=?,tx_dept=?,tx_division=?,gu_geozone=?,id_nationality=?,tx_comments=?,id_batch=? WHERE gu_contact=? OR (tx_name=? AND tx_surname=? AND gu_workarea=?)");
    oContInst = oConn.prepareStatement("INSERT INTO k_contacts (gu_workarea,tx_nickname,tx_pwd,tx_challenge,tx_reply,dt_pwd_expires,dt_modified,gu_writer,gu_company,id_status,id_ref,tx_name,tx_surname,de_title,id_gender,dt_birth,ny_age,sn_passport,tp_passport,sn_drivelic,dt_drivelic,tx_dept,tx_division,gu_geozone,id_nationality,tx_comments,id_batch,gu_contact) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    oContLook = oConn.prepareStatement("SELECT NULL FROM k_contacts_lookup WHERE gu_owner=? AND id_section=? AND vl_lookup=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oContPort = oConn.prepareStatement("SELECT gu_contact FROM k_contacts WHERE sn_passport=? AND gu_workarea=?",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oAddrUpdt = oConn.prepareStatement("UPDATE k_addresses SET ix_address=?,gu_workarea=?,bo_active=?,dt_modified=?,tp_location=?,nm_company=?,tp_street=?,nm_street=?,nu_street=?,tx_addr1=?,tx_addr2=?,id_country=?,nm_country=?,id_state=?,nm_state=?,mn_city=?,zipcode=?,work_phone=?,direct_phone=?,home_phone=?,mov_phone=?,fax_phone=?,other_phone=?,po_box=?,tx_email=?,tx_email_alt=?,url_addr=?,coord_x=?,coord_y=?,contact_person=?,tx_salutation=?,id_ref=?,tx_remarks=? WHERE gu_address=? OR (tx_email=? AND gu_workarea=?)");
    oAddrInst = oConn.prepareStatement("INSERT INTO k_addresses (ix_address,gu_workarea,bo_active,dt_modified,tp_location,nm_company,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,tx_email_alt,url_addr,coord_x,coord_y,contact_person,tx_salutation,id_ref,tx_remarks,gu_address) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    oAddrLook = oConn.prepareStatement("SELECT NULL FROM k_addresses_lookup WHERE gu_owner=? AND id_section=? AND vl_lookup=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oAddrComp = oConn.prepareStatement("SELECT a.gu_address FROM k_addresses a, k_x_company_addr x WHERE a.gu_address=x.gu_address AND a.gu_workarea=? AND a.ix_address=? AND x.gu_company=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oAddrCont = oConn.prepareStatement("SELECT a.gu_address FROM k_addresses a, k_x_contact_addr x WHERE a.gu_address=x.gu_address AND a.gu_workarea=? AND a.ix_address=? AND x.gu_contact=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);

    oContAddr = oConn.prepareStatement("INSERT INTO k_x_contact_addr (gu_contact,gu_address) VALUES(?,?)");
    oCompAddr = oConn.prepareStatement("INSERT INTO k_x_company_addr (gu_company,gu_address) VALUES(?,?)");

	oContMail = oConn.prepareStatement("SELECT gu_contact FROM k_member_address WHERE gu_workarea=? AND tx_email=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
		
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ContactLoader.prepare()");
    }
  } // prepare

  // ---------------------------------------------------------------------------

  /**
   * <p>Close prepared statements</p>
   * This method must always be called before object is destroyed or else
   * @throws SQLException
   */
  public void close()
    throws SQLException {

    oCompSectorsMap.clear();
    oCompStatusMap.clear();
    oCompTypesMap.clear();
    oContGendersMap.clear();
    oContStatusMap.clear();
    oContDeptsMap.clear();
    oContDivsMap.clear();
    oContTitlesMap.clear();
    oAddrLocsMap.clear();
    oAddrTypesMap.clear();
    oAddrSalutMap.clear();

	if (oContMail!=null) { oContMail.close(); oContMail=null; }

    if (oAddrComp!=null) { oAddrComp.close(); oAddrComp=null; }
    if (oAddrCont!=null) { oAddrCont.close(); oAddrCont=null; }

    if (oCompAddr!=null) { oCompAddr.close(); oCompAddr=null; }
    if (oContAddr!=null) { oContAddr.close(); oContAddr=null; }

    if (oCompUpdt!=null) { oCompUpdt.close(); oCompUpdt=null; }
    if (oCompInst!=null) { oCompInst.close(); oCompInst=null; }
    if (oCompLook!=null) { oCompLook.close(); oCompLook=null; }
    if (oCompName!=null) { oCompName.close(); oCompName=null; }

    if (oContUpdt!=null) { oContUpdt.close(); oContUpdt=null; }
    if (oContInst!=null) { oContInst.close(); oContInst=null; }
    if (oContLook!=null) { oContLook.close(); oContLook=null; }
    if (oContPort!=null) { oContPort.close(); oContPort=null; }

    if (oAddrUpdt!=null) { oAddrUpdt.close(); oAddrUpdt=null; }
    if (oAddrInst!=null) { oAddrInst.close(); oAddrInst=null; }
    if (oAddrLook!=null) { oAddrLook.close(); oAddrLook=null; }
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
      DebugFile.writeln("Begin ContactLoader.addLookUp("+sTable+","+sSection+","+sValue+","+
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
      DebugFile.writeln("End ContactLoader.addLookUp()");
    }
  } // addLookUp

  // ---------------------------------------------------------------------------

  private String getCompanyGuid(Connection oConn, Object sCompanyLegalname, Object sWorkArea)
    throws SQLException {
    String sCompGuid;
    oCompName.setObject(1, sCompanyLegalname, Types.VARCHAR);
    oCompName.setObject(2, sWorkArea, Types.VARCHAR);
    ResultSet oRSet = oCompName.executeQuery();
    if (oRSet.next())
      sCompGuid = oRSet.getString(1);
    else
      sCompGuid = null;
    oRSet.close();
    if (null==sCompGuid)
      sCompGuid = Gadgets.generateUUID();
    return sCompGuid;
  } // getCompanyGuid

  // ---------------------------------------------------------------------------

  private String getContactGuid(Connection oConn, Object sContactPassport, Object sWorkArea)
    throws SQLException {
    String sContGuid;
    oContPort.setObject(1, sContactPassport, Types.VARCHAR);
    oContPort.setObject(2, sWorkArea, Types.VARCHAR);
    ResultSet oRSet = oContPort.executeQuery();
    if (oRSet.next())
      sContGuid = oRSet.getString(1);
    else
      sContGuid = null;
    oRSet.close();
    if (null==sContGuid)
      sContGuid = Gadgets.generateUUID();
    return sContGuid;
  } // getContactGuid

  // ---------------------------------------------------------------------------

  private String getContactForEmail(Connection oConn, Object sEmail, Object sWorkArea)
    throws SQLException {
    String sContGuid;
    oContMail.setObject(1, sWorkArea, Types.VARCHAR);
    oContMail.setObject(2, sEmail, Types.VARCHAR);
    ResultSet oRSet = oContMail.executeQuery();
    if (oRSet.next())
      sContGuid = oRSet.getString(1);
    else
      sContGuid = null;
    oRSet.close();
    return sContGuid;
  } // getContactForEmail

  // ---------------------------------------------------------------------------

  private String getAddressGuid(Connection oConn, Object oIxAddr, Object oGuWrkA,
                                Object oGuCont, Object oGuComp, int iFlags)
    throws SQLException {
    String sAddrGuid;
    ResultSet oRSet;
    if (oIxAddr==null) return Gadgets.generateUUID();
    if (test(iFlags, WRITE_CONTACTS)) {
      oAddrCont.setObject(1, oGuWrkA, Types.CHAR);
      oAddrCont.setObject(2, oIxAddr, Types.INTEGER);
      oAddrCont.setObject(3, oGuCont, Types.CHAR);
      oRSet = oAddrCont.executeQuery();
      if (oRSet.next())
        sAddrGuid = oRSet.getString(1);
      else
        sAddrGuid = null;
      oRSet.close();
    } else {
      oAddrComp.setObject(1, oGuWrkA, Types.CHAR);
      oAddrComp.setObject(2, oIxAddr, Types.INTEGER);
      oAddrComp.setObject(3, oGuComp, Types.CHAR);
      oRSet = oAddrComp.executeQuery();
      if (oRSet.next())
        sAddrGuid = oRSet.getString(1);
      else
        sAddrGuid = null;
      oRSet.close();
    }
    if (null==sAddrGuid) sAddrGuid = Gadgets.generateUUID();
    return sAddrGuid;
  } // getAddressGuid

  // ---------------------------------------------------------------------------

  private String getColNull (int iColIndex)
    throws ArrayIndexOutOfBoundsException,ClassCastException {
    if (DebugFile.trace) {
      if (iColIndex<0 || iColIndex>=aValues.length)
        throw new ArrayIndexOutOfBoundsException("ContactLoader.getColNull() column index "+String.valueOf(iColIndex)+" must be in the range between 0 and "+String.valueOf(aValues.length));
      DebugFile.writeln("ContactLoader.getColNull("+String.valueOf(iColIndex)+") : "+aValues[iColIndex]);
    }
    String sRetVal;
    if (null==aValues[iColIndex])
      sRetVal = null;
    else {
      try {
        sRetVal = aValues[iColIndex].toString();
      } catch (ClassCastException cce){
        if (aValues[iColIndex]==null)
          throw new ClassCastException("ContactLoader.getColNull("+String.valueOf(iColIndex)+") could not cast null to String");
        else
          throw new ClassCastException("ContactLoader.getColNull("+String.valueOf(iColIndex)+") could not cast "+aValues[iColIndex].getClass().getName()+" "+aValues[iColIndex]+" to String");
      }
      if (sRetVal.length()==0 || sRetVal.equalsIgnoreCase("null"))
        sRetVal = null;
    }
    return sRetVal;
  } // getColNull

  // ---------------------------------------------------------------------------

  /**
   * Store properties curently held in RAM into the database
   * @param oConn Opened JDBC connection
   * @param sWorkArea String GUID of WorkArea to which inserted data will belong
   * @param iFlags int A boolean combination of {MODE_APPEND|MODE_UPDATE|WRITE_COMPANIES|WRITE_CONTACTS|WRITE_ADDRESSES|WRITE_LOOKUPS|NO_DUPLICATED_NAMES|NO_DUPLICATED_MAILS}
   * @throws SQLException
   * @throws IllegalArgumentException
   * @throws NullPointerException
   * @throws ClassCastException
   */
  public void store(Connection oConn, String sWorkArea, int iFlags)
    throws SQLException,IllegalArgumentException,NullPointerException,ClassCastException {

	DistributionList oDistribList = null;
	short iListType = 0;

    if (oCompUpdt==null || oContUpdt==null || oAddrUpdt==null)
      throw new SQLException("Invalid command sequece. Must call ContactLoader.prepare() before ContactLoader.store()");

    if (!test(iFlags,MODE_APPEND) && !test(iFlags,MODE_UPDATE))
      throw new IllegalArgumentException("ContactLoader.store() Flags bitmask must contain either MODE_APPEND, MODE_UPDATE or both");

    if (!test(iFlags,WRITE_COMPANIES) && !test(iFlags,WRITE_CONTACTS))
      throw new IllegalArgumentException("ContactLoader.store() Flags bitmask must contain either WRITE_COMPANIES, WRITE_CONTACTS or both");

    if (null==sWorkArea)
      throw new NullPointerException("ContactLoader.store() Default WorkArea cannot be null");

    if (null==getColNull(gu_company) && test(iFlags,WRITE_COMPANIES) && test(iFlags,MODE_UPDATE) && !test(iFlags,MODE_APPEND))
      throw new NullPointerException("ContactLoader.store() gu_company cannot be null when using UPDATE mode");

    if (null==getColNull(gu_contact) && test(iFlags,WRITE_CONTACTS) && test(iFlags,MODE_UPDATE) && !test(iFlags,MODE_APPEND))
      throw new NullPointerException("ContactLoader.store() gu_contact cannot be null when using UPDATE mode");

    if (null==getColNull(gu_address) && test(iFlags,WRITE_ADDRESSES) && test(iFlags,MODE_UPDATE) && !test(iFlags,MODE_APPEND))
      throw new NullPointerException("ContactLoader.store() gu_address cannot be null when using UPDATE mode");

    if (test(iFlags,ADD_TO_LIST)) {
	  if (!test(iFlags,MODE_APPEND))
        throw new IllegalArgumentException("ContactLoader.store() MODE_APPEND is required if ADD_TO_LIST is set");
	  if (!test(iFlags,WRITE_CONTACTS) && !test(iFlags,WRITE_COMPANIES))
        throw new IllegalArgumentException("ContactLoader.store() WRITE_CONTACTS or WRITE_COMPANIES are required if ADD_TO_LIST is set");
	  if (!test(iFlags,WRITE_ADDRESSES))
        throw new IllegalArgumentException("ContactLoader.store() WRITE_ADDRESSES is required if ADD_TO_LIST is set");
	  if (get(gu_list)==null) {
        throw new IllegalArgumentException("ContactLoader.store() value for gu_list column is required if ADD_TO_LIST is set");
      } else {
		if (oListsMap.containsKey(get(gu_list))) {
		  oDistribList = oListsMap.get(get(gu_list));
		  iListType = oDistribList.getShort("tp_list");
		  if (iListType!=DistributionList.TYPE_STATIC &&
		  	  iListType!=DistributionList.TYPE_DIRECT &&
		  	  iListType!=DistributionList.TYPE_BLACK)
            throw new IllegalArgumentException("ContactLoader.store() type for list "+get(gu_list)+" must be either STATIC, DIRECT or BLACK but it is "+String.valueOf(iListType));
		} else {
	      PreparedStatement oList = oConn.prepareStatement("SELECT tp_list FROM k_lists WHERE gu_workarea=? AND gu_list=?",
															 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
		  oList.setString(1, sWorkArea);
		  oList.setObject(2, get(gu_list), Types.CHAR);
		  ResultSet oRist = oList.executeQuery();
		  boolean bFoundList = oRist.next();
		  if (bFoundList) {
		  	iListType = oRist.getShort(1);
		  	oDistribList = new DistributionList();
		  	oDistribList.put("gu_list", get(gu_list));
		  	oDistribList.put("tp_list", iListType);
		  	oDistribList.put("gu_workarea", sWorkArea);
			oListsMap.put(getColNull(gu_list), oDistribList);
		  }
		  oRist.close();
		  oList.close();
		  if (!bFoundList)
            throw new IllegalArgumentException("ContactLoader.store() List "+get(gu_list)+" not found for Work Area "+sWorkArea+" at table l_lists");
		  if (iListType!=DistributionList.TYPE_STATIC &&
		  	  iListType!=DistributionList.TYPE_DIRECT &&
		  	  iListType!=DistributionList.TYPE_BLACK)
            throw new IllegalArgumentException("ContactLoader.store() type for list "+get(gu_list)+" must be either STATIC, DIRECT or BLACK but it is "+String.valueOf(iListType));
	    } // fi (containsKey(gu_list))
	  } // fi (gu_list)
    } // fi (ADD_TO_LIST)

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ContactLoader.store([Connection],"+sWorkArea+","+
		               (test(iFlags, MODE_APPEND) ? "MODE_APPEND" : "")+
		               (test(iFlags, MODE_UPDATE) ? "|MODE_UPDATE" : "")+
		               (test(iFlags, WRITE_LOOKUPS) ? "|WRITE_LOOKUPS" : "")+
		               (test(iFlags, WRITE_CONTACTS) ? "|WRITE_CONTACTS" : "")+
		               (test(iFlags, WRITE_ADDRESSES) ? "|WRITE_ADDRESSES" : "")+
		               (test(iFlags, NO_DUPLICATED_NAMES) ? "|NO_DUPLICATED_NAMES" : "")+
		               (test(iFlags, NO_DUPLICATED_MAILS) ? "|NO_DUPLICATED_MAILS" : "")+
		               (test(iFlags, ADD_TO_LIST) ? "|ADD_TO_LIST" : "")+")");
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

    int iAffected;
    Timestamp tsNow = new Timestamp(new Date().getTime());

    if (null==get(gu_workarea)) {
      if (DebugFile.trace) DebugFile.writeln("setting workarea to "+sWorkArea);
      put(gu_workarea, sWorkArea);
    } else {
      if (DebugFile.trace) DebugFile.writeln("workarea for current record is "+getColNull(gu_workarea));
    }
    if (test(iFlags,WRITE_COMPANIES) && getColNull(gu_company)==null && getColNull(nm_legal)!=null)
      put(gu_company, getCompanyGuid(oConn, aValues[nm_legal], get(gu_workarea)));

    if (test(iFlags,WRITE_CONTACTS) && getColNull(gu_contact)==null) {
      if (test(iFlags,ALLOW_DUPLICATED_PASSPORTS) && !test(iFlags,NO_DUPLICATED_MAILS)) {
        put(gu_contact, Gadgets.generateUUID());
      } else if (test(iFlags,NO_DUPLICATED_MAILS)) {
        put(gu_contact, getContactForEmail(oConn, aValues[tx_email], get(gu_workarea)));
        if (getColNull(gu_contact)==null && !test(iFlags,ALLOW_DUPLICATED_PASSPORTS))
          put(gu_contact, getContactGuid(oConn, aValues[sn_passport], get(gu_workarea)));
      } else if (!test(iFlags,ALLOW_DUPLICATED_PASSPORTS)) {
        put(gu_contact, getContactGuid(oConn, aValues[sn_passport], get(gu_workarea)));
      } else {
        put(gu_contact, Gadgets.generateUUID());
      }
    }

    if (test(iFlags,WRITE_ADDRESSES) && aValues[gu_address]==null)
      put(gu_address, getAddressGuid(oConn, aValues[ix_address], get(gu_workarea), get(gu_contact), get(gu_company), iFlags));

    if (test(iFlags,WRITE_COMPANIES) && (getColNull(gu_company)!=null || getColNull(nm_legal)!=null)) {
      if (test(iFlags,WRITE_LOOKUPS)) {
        addLookUp("k_companies_lookup", "id_sector", getColNull(id_sector), oConn, oCompLook, oCompSectorsMap);
        addLookUp("k_companies_lookup", "id_status", getColNull(id_company_status), oConn, oCompLook, oCompStatusMap);
        addLookUp("k_companies_lookup", "tp_company", getColNull(tp_company), oConn, oCompLook, oCompTypesMap);
      } // if (test(WRITE_LOOKUPS))

      iAffected = 0;
      if ((test(iFlags,MODE_UPDATE) || test(iFlags,WRITE_CONTACTS)) &&
          (getColNull(nm_legal)!=null || getColNull(gu_company)!=null)) {
        if (DebugFile.trace) DebugFile.writeln("COMPANY MODE_UPDATE AND IS NOT NEW COMPANY");
        oCompUpdt.setString(1, getColNull(nm_legal));
         if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(2, "+aValues[gu_workarea]+", Types.CHAR)");
        oCompUpdt.setObject(2, aValues[gu_workarea], Types.CHAR);
        oCompUpdt.setString(3, getColNull(nm_commercial));
        if (aValues[dt_modified]==null)
          oCompUpdt.setTimestamp(4, tsNow);
        else {
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(4, "+aValues[dt_modified]+", Types.TIMESTAMP)");
          oCompUpdt.setObject(4, aValues[dt_modified], Types.TIMESTAMP);
        }
        if (aValues[dt_founded]==null)
          oCompUpdt.setNull(5, Types.TIMESTAMP);
        else {
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(5, "+aValues[dt_founded]+", Types.TIMESTAMP)");
          oCompUpdt.setObject(5, aValues[dt_founded], Types.TIMESTAMP);
        }
        oCompUpdt.setString(6, getColNull(id_legal));
        oCompUpdt.setString(7, getColNull(id_sector));
        oCompUpdt.setString(8, getColNull(id_company_status));
        oCompUpdt.setString(9, getColNull(id_company_ref));
        oCompUpdt.setString(10, getColNull(tp_company));
        oCompUpdt.setString(11, getColNull(gu_geozone));
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(12, "+aValues[nu_employees]+", Types.INTEGER)");
        oCompUpdt.setObject(12, aValues[nu_employees], Types.INTEGER);
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(13, "+aValues[im_revenue]+", Types.FLOAT)");
        oCompUpdt.setObject(13, aValues[im_revenue], Types.FLOAT);
        oCompUpdt.setString(14, getColNull(gu_sales_man));
        oCompUpdt.setString(15, getColNull(tx_franchise));
        oCompUpdt.setString(16, getColNull(de_company));
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(17,"+aValues[gu_company]+")");
        oCompUpdt.setString(17, (String) aValues[gu_company]);
        oCompUpdt.setString(18, (String) aValues[nm_legal]);
        oCompUpdt.setString(19, (String) aValues[gu_workarea]);
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate(oCompUpdt)");
        iAffected = oCompUpdt.executeUpdate();
        if (DebugFile.trace) DebugFile.writeln("affected="+String.valueOf(iAffected));

        if (test(iFlags,ADD_TO_LIST) && iListType==DistributionList.TYPE_DIRECT) {
          PreparedStatement oUdlm = oConn.prepareStatement("UPDATE "+DB.k_x_list_members+" SET "+
			    				    DB.dt_modified+"=?,"+DB.tx_name+"=?,"+DB.tx_surname+"=?,"+
			    				    DB.mov_phone+"=? WHERE "+DB.gu_list+"=? AND "+DB.tx_email+"=?");
	      oUdlm.setTimestamp(1, new Timestamp(new Date().getTime()));
	      oUdlm.setObject(2, get(tx_name), Types.VARCHAR);
		  oUdlm.setObject(3, get(tx_surname), Types.VARCHAR);
		  oUdlm.setObject(4, get(mov_phone), Types.VARCHAR);
		  oUdlm.setObject(5, get(gu_list), Types.CHAR);
		  oUdlm.setObject(6, get(tx_email), Types.VARCHAR);
		  oUdlm.executeUpdate();
		  oUdlm.close();
        }

      }

      if (test(iFlags,MODE_APPEND) && (iAffected==0)) {
        if (DebugFile.trace) DebugFile.writeln("COMPANY MODE_APPEND AND affected=0");
        oCompInst.setString(1, getColNull(nm_legal));
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(2, "+aValues[gu_workarea]+" "+getColNull(gu_workarea)+", Types.CHAR)");
        oCompInst.setObject(2, aValues[gu_workarea], Types.CHAR);
        oCompInst.setString(3, getColNull(nm_commercial));
        if (aValues[dt_modified]==null) {
          oCompInst.setTimestamp(4, tsNow);
        } else {
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(4, "+aValues[dt_modified]+", Types.TIMESTAMP)");
          oCompInst.setObject(4, aValues[dt_modified], Types.TIMESTAMP);
        }
        if (aValues[dt_founded]==null) {
          oCompInst.setNull(5, Types.TIMESTAMP);
        } else {
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(5, "+aValues[dt_founded]+", Types.TIMESTAMP)");
          oCompInst.setObject(5, aValues[dt_founded], Types.TIMESTAMP);
        }
        oCompInst.setString(6, getColNull(id_legal));
        oCompInst.setString(7, getColNull(id_sector));
        oCompInst.setString(8, getColNull(id_company_status));
        oCompInst.setString(9, getColNull(id_company_ref));
        oCompInst.setString(10, getColNull(tp_company));
        oCompInst.setString(11, getColNull(gu_geozone));
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(12, "+aValues[nu_employees]+", Types.INTEGER)");
        oCompInst.setObject(12, aValues[nu_employees], Types.INTEGER);
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(13, "+aValues[im_revenue]+", Types.FLOAT)");
        oCompInst.setObject(13, aValues[im_revenue], Types.FLOAT);
        oCompInst.setString(14, getColNull(gu_sales_man));
        oCompInst.setString(15, getColNull(tx_franchise));
        oCompInst.setString(16, getColNull(de_company));
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(17,"+aValues[gu_company]+")");
        oCompInst.setString(17, (String) aValues[gu_company]);
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate(oCompInst)");
        iAffected = oCompInst.executeUpdate();
        if (DebugFile.trace) DebugFile.writeln("affected="+String.valueOf(iAffected));
      }
    } // fi (test(iFlags,WRITE_COMPANIES) && (getColNull(gu_company)!=null || getColNull(nm_legal)!=null))

    if (test(iFlags,WRITE_CONTACTS)) {
      if (test(iFlags,WRITE_LOOKUPS)) {
        addLookUp("k_contacts_lookup", "id_status", getColNull(id_contact_status), oConn, oContLook, oContStatusMap);
        addLookUp("k_contacts_lookup", "de_title", getColNull(de_title), oConn, oContLook, oContTitlesMap);
        addLookUp("k_contacts_lookup", "id_gender", getColNull(id_gender), oConn, oContLook, oContGendersMap);
        addLookUp("k_contacts_lookup", "tx_dept", getColNull(tx_dept), oConn, oContLook, oContDeptsMap);
        addLookUp("k_contacts_lookup", "tx_division", getColNull(tx_division), oConn, oContLook, oContDivsMap);
      } // if (test(WRITE_LOOKUPS))

      iAffected = 0;
      if (DebugFile.trace) DebugFile.writeln("MODE_UPDATE="+String.valueOf(test(iFlags,MODE_UPDATE))+" "+(getColNull(sn_passport)==null ? "sn_passport IS NULL" : "sn_passport IS NOT NULL")+" "+(getColNull(gu_contact)==null ? "gu_contact IS NULL" : "gu_contact IS NOT NULL"));
      if (test(iFlags,MODE_UPDATE) && (getColNull(sn_passport)!=null || getColNull(gu_contact)!=null)) {
        if (DebugFile.trace) DebugFile.writeln("CONTACT MODE_UPDATE AND IS NOT NEW CONTACT");
        oContUpdt.setObject(1, aValues[gu_workarea], Types.CHAR);
        oContUpdt.setString(2, getColNull(tx_nickname));
        oContUpdt.setString(3, getColNull(tx_pwd));
        oContUpdt.setString(4, getColNull(tx_challenge));
        oContUpdt.setString(5, getColNull(tx_reply));
        oContUpdt.setObject(6, aValues[dt_pwd_expires], Types.TIMESTAMP);
        if (aValues[dt_modified]==null)
          oContUpdt.setTimestamp(7, tsNow);
        else
          oContUpdt.setObject(7, aValues[dt_modified], Types.TIMESTAMP);
        oContUpdt.setString(8, getColNull(gu_writer));
        if (test(iFlags,WRITE_COMPANIES))
          oContUpdt.setString(9, getColNull(gu_company));
        else
          oContUpdt.setNull(9,Types.CHAR);
        oContUpdt.setString(10, getColNull(id_contact_status));
        oContUpdt.setString(11, getColNull(id_contact_ref));
        oContUpdt.setString(12, getColNull(tx_name));
        oContUpdt.setString(13, getColNull(tx_surname));
        oContUpdt.setString(14, getColNull(de_title));
        oContUpdt.setString(15, getColNull(id_gender));
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(16, "+aValues[dt_birth]+", Types.TIMESTAMP)");
        if (null==aValues[dt_birth])
          oContUpdt.setNull(16, Types.TIMESTAMP);
        else if (aValues[dt_birth].getClass().getName().equals("java.util.Date"))
          oContUpdt.setObject(16, new Timestamp(((java.util.Date)aValues[dt_birth]).getTime()), Types.TIMESTAMP);
        else
          oContUpdt.setObject(16, aValues[dt_birth], Types.TIMESTAMP);        	
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(17, "+aValues[ny_age]+", Types.INTEGER)");
        oContUpdt.setObject(17, aValues[ny_age], Types.INTEGER);
        oContUpdt.setString(18, getColNull(sn_passport));
        oContUpdt.setString(19, getColNull(tp_passport));
        oContUpdt.setString(20, getColNull(sn_drivelic));
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(21, "+aValues[dt_drivelic]+", Types.TIMESTAMP)");
        oContUpdt.setObject(21, aValues[dt_drivelic], Types.TIMESTAMP);
        oContUpdt.setString(22, getColNull(tx_dept));
        oContUpdt.setString(23, getColNull(tx_division));
        oContUpdt.setString(24, getColNull(gu_geozone));
        if (getColNull(id_nationality)==null)
          oContUpdt.setNull(25, Types.CHAR);
		else
          oContUpdt.setString(25, getColNull(id_nationality));

        if (getColNull(tx_comments)==null) {
          oContUpdt.setNull(26, Types.VARCHAR);
        } else {
          oContUpdt.setString(26, Gadgets.left((String) aValues[tx_comments], 254));
        }
        if (getColNull(id_batch)==null) {
          oContUpdt.setNull(27, Types.VARCHAR);
        } else {
          oContUpdt.setString(27, Gadgets.left((String) aValues[id_batch], 32));
        }
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(28,"+aValues[gu_contact]+")");

        oContUpdt.setString(28, (String) aValues[gu_contact]);
        if (test(iFlags,NO_DUPLICATED_NAMES)) {
          oContUpdt.setString(29, getColNull(tx_name));
          oContUpdt.setString(30, getColNull(tx_surname));
          oContUpdt.setString(31, (String) aValues[gu_workarea]);
        } else {
          oContUpdt.setNull(29, Types.VARCHAR);
          oContUpdt.setNull(30, Types.VARCHAR);
          oContUpdt.setNull(31, Types.CHAR);
        }
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate(oContUpdt)");
          iAffected = oContUpdt.executeUpdate();
        if (DebugFile.trace) DebugFile.writeln("affected="+String.valueOf(iAffected));
      } // fi (MODE_UPDATE && !bIsNewContact)

      if (test(iFlags,MODE_APPEND)) {
      	if (iAffected==0) {
          if (DebugFile.trace) DebugFile.writeln("CONTACT MODE_APPEND AND affected=0");
          oContInst.setObject(1, aValues[gu_workarea], Types.CHAR);
          oContInst.setString(2, getColNull(tx_nickname));
          oContInst.setString(3, getColNull(tx_pwd));
          oContInst.setString(4, getColNull(tx_challenge));
          oContInst.setString(5, getColNull(tx_reply));
          oContInst.setObject(6, aValues[dt_pwd_expires], Types.TIMESTAMP);
          if (aValues[dt_modified]==null)
            oContInst.setTimestamp(7, tsNow);
          else
            oContInst.setObject(7, aValues[dt_modified], Types.TIMESTAMP);
          oContInst.setString(8, getColNull(gu_writer));
          if (test(iFlags,WRITE_COMPANIES))
            oContInst.setString(9, getColNull(gu_company));
          else
            oContInst.setNull(9,Types.CHAR);
          oContInst.setString(10, getColNull(id_contact_status));
          oContInst.setString(11, getColNull(id_contact_ref));
          oContInst.setString(12, getColNull(tx_name));
          oContInst.setString(13, getColNull(tx_surname));
          oContInst.setString(14, getColNull(de_title));
          oContInst.setString(15, getColNull(id_gender));
          if (null==aValues[dt_birth])
            oContInst.setNull(16, Types.TIMESTAMP);
          else if (aValues[dt_birth].getClass().getName().equals("java.util.Date"))
            oContInst.setObject(16, new Timestamp(((java.util.Date)aValues[dt_birth]).getTime()), Types.TIMESTAMP);
          else
            oContInst.setObject(16, aValues[dt_birth], Types.TIMESTAMP);
          oContInst.setObject(17, aValues[ny_age], Types.INTEGER);
          oContInst.setString(18, getColNull(sn_passport));
          oContInst.setString(19, getColNull(tp_passport));
          oContInst.setString(20, getColNull(sn_drivelic));
          oContInst.setObject(21, aValues[dt_drivelic], Types.TIMESTAMP);
          oContInst.setString(22, getColNull(tx_dept));
          oContInst.setString(23, getColNull(tx_division));
          oContInst.setString(24, getColNull(gu_geozone));
          if (getColNull(id_nationality)==null)
            oContInst.setNull(25, Types.CHAR);
		  else
            oContInst.setString(25, getColNull(id_nationality));

          if (getColNull(tx_comments)==null) {
            oContInst.setNull(26, Types.VARCHAR);
          } else {
            oContInst.setString(26, Gadgets.left((String) aValues[tx_comments], 254));
          }
          if (getColNull(id_batch)==null) {
            oContInst.setNull(27, Types.VARCHAR);
          } else {
            oContInst.setString(27, Gadgets.left((String) aValues[id_batch], 32));
          }          
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(28,"+aValues[gu_contact]+")");
          oContInst.setString(28, (String) aValues[gu_contact]);
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate(oContInst)");
          iAffected = oContInst.executeUpdate();
          if (DebugFile.trace) DebugFile.writeln("affected="+String.valueOf(iAffected));
        } // fi (iAffected==0)
      } // fi (MODE_APPEND)
    } // fi (WRITE_CONTACTS)

    if (test(iFlags,WRITE_LOOKUPS)) {
      addLookUp("k_addresses_lookup", "tp_location", getColNull(tp_location), oConn, oAddrLook, oAddrLocsMap);
      addLookUp("k_addresses_lookup", "tp_street", getColNull(tp_street), oConn, oAddrLook, oAddrTypesMap);
      addLookUp("k_addresses_lookup", "tx_salutation", getColNull(tx_salutation), oConn, oAddrLook, oAddrSalutMap);
    } // if (test(WRITE_LOOKUPS))

    iAffected = 0;
    if (test(iFlags,MODE_UPDATE) && getColNull(gu_address)!=null) {
      if (DebugFile.trace) DebugFile.writeln("ADDRESS MODE_UPDATE AND IS NOT NEW ADDRESS");

      if (null!=aValues[ix_address])
        oAddrUpdt.setObject(1, aValues[ix_address], Types.INTEGER);
      else {
        if (test(iFlags,WRITE_CONTACTS))
          oAddrUpdt.setInt(1, Address.nextLocalIndex(oConn, "k_x_contact_addr", "gu_contact", (String) aValues[gu_contact]));
        else
          oAddrUpdt.setInt(1, Address.nextLocalIndex(oConn, "k_x_company_addr", "gu_company", (String) aValues[gu_company]));
      }
      oAddrUpdt.setObject(2, aValues[gu_workarea], Types.CHAR);
      if (null!=aValues[bo_active])
        oAddrUpdt.setObject(3, aValues[bo_active], Types.SMALLINT);
      else
        oAddrUpdt.setShort(3, (short)1);
      if (aValues[dt_modified]==null)
        oAddrUpdt.setTimestamp(4, tsNow);
      else
        oAddrUpdt.setObject(4, aValues[dt_modified], Types.TIMESTAMP);
      oAddrUpdt.setString(5, getColNull(tp_location));
      if (test(iFlags,WRITE_COMPANIES))
        oAddrUpdt.setString(6, (String) (getColNull(nm_commercial)==null ? getColNull(nm_legal) : aValues[nm_commercial]));
      else
        oAddrUpdt.setNull(6,Types.VARCHAR);
      oAddrUpdt.setString(7, getColNull(tp_street));
      oAddrUpdt.setString(8, getColNull(nm_street));
      oAddrUpdt.setString(9, getColNull(nu_street));
      oAddrUpdt.setString(10, getColNull(tx_addr1));
      oAddrUpdt.setString(11, getColNull(tx_addr2));
      oAddrUpdt.setString(12, getColNull(id_country));
      oAddrUpdt.setString(13, getColNull(nm_country));
      oAddrUpdt.setString(14, getColNull(id_state));
      oAddrUpdt.setString(15, getColNull(nm_state));
      oAddrUpdt.setString(16, getColNull(mn_city));
      if (getColNull(zipcode)==null)
        oAddrUpdt.setNull(17, Types.VARCHAR);
      else
        oAddrUpdt.setString(17, getColNull(zipcode));
      oAddrUpdt.setString(18, getColNull(work_phone));
      oAddrUpdt.setString(19, getColNull(direct_phone));
      oAddrUpdt.setString(20, getColNull(home_phone));
      oAddrUpdt.setString(21, getColNull(mov_phone));
      oAddrUpdt.setString(22, getColNull(fax_phone));
      oAddrUpdt.setString(23, getColNull(other_phone));
      oAddrUpdt.setString(24, getColNull(po_box));
      oAddrUpdt.setString(25, getColNull(tx_email));
      oAddrUpdt.setString(26, getColNull(tx_email_alt));
      oAddrUpdt.setString(27, getColNull(url_addr));
      oAddrUpdt.setObject(28, aValues[coord_x], Types.FLOAT);
      oAddrUpdt.setObject(29, aValues[coord_y], Types.FLOAT);
      oAddrUpdt.setString(30, getColNull(contact_person));
      oAddrUpdt.setString(31, getColNull(tx_salutation));
      oAddrUpdt.setString(32, getColNull(id_address_ref));
      oAddrUpdt.setString(33, getColNull(tx_remarks));
      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(34,"+aValues[gu_address]+")");
      oAddrUpdt.setString(34, (String) aValues[gu_address]);
      if (test(iFlags,NO_DUPLICATED_MAILS)) {
        oAddrUpdt.setString(35, getColNull(tx_email));
        oAddrUpdt.setString(36, (String) aValues[gu_workarea]);
      } else {
        oAddrUpdt.setNull(35, Types.VARCHAR);
        oAddrUpdt.setNull(36, Types.CHAR);
      }
      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate(oAddrUpdt)");
      iAffected = oAddrUpdt.executeUpdate();
      if (DebugFile.trace) DebugFile.writeln("affected="+String.valueOf(iAffected));
    }

    if (test(iFlags,MODE_APPEND)) {
      if (iAffected==0) {
        if (DebugFile.trace) DebugFile.writeln("ADDRESS MODE_APPEND AND affected=0");

        if (null!=aValues[ix_address])
          oAddrInst.setObject(1, aValues[ix_address], Types.INTEGER);
        else
          oAddrInst.setInt(1, Address.nextLocalIndex(oConn, "k_x_contact_addr", "gu_contact", (String) aValues[gu_contact]));
        oAddrInst.setString(2, (String) aValues[gu_workarea]);
        if (null!=aValues[bo_active])
          oAddrInst.setObject(3, aValues[bo_active], Types.SMALLINT);
        else
          oAddrInst.setShort(3, (short)1);
        if (aValues[dt_modified]==null)
          oAddrInst.setTimestamp(4, tsNow);
        else
          oAddrInst.setObject(4, aValues[dt_modified], Types.TIMESTAMP);
        oAddrInst.setString(5, getColNull(tp_location));
        if (test(iFlags,WRITE_COMPANIES))
          oAddrInst.setString(6, (String) (getColNull(nm_commercial)==null ? getColNull(nm_legal) : aValues[nm_commercial]));
        else
          oAddrInst.setNull(6,Types.VARCHAR);
        oAddrInst.setString(7, getColNull(tp_street));
        oAddrInst.setString(8, getColNull(nm_street));
        oAddrInst.setString(9, getColNull(nu_street));
        oAddrInst.setString(10, getColNull(tx_addr1));
        oAddrInst.setString(11, getColNull(tx_addr2));
        oAddrInst.setString(12, getColNull(id_country));
        oAddrInst.setString(13, getColNull(nm_country));
        oAddrInst.setString(14, getColNull(id_state));
        oAddrInst.setString(15, getColNull(nm_state));
        oAddrInst.setString(16, getColNull(mn_city));
        if (getColNull(zipcode)==null)
          oAddrInst.setNull(17, Types.VARCHAR);
        else
          oAddrInst.setString(17, getColNull(zipcode));
        oAddrInst.setString(18, Gadgets.left(getColNull(work_phone),16));
        oAddrInst.setString(19, Gadgets.left(getColNull(direct_phone),16));
        oAddrInst.setString(20, Gadgets.left(getColNull(home_phone),16));
        oAddrInst.setString(21, Gadgets.left(getColNull(mov_phone),16));
        oAddrInst.setString(22, Gadgets.left(getColNull(fax_phone),16));
        oAddrInst.setString(23, Gadgets.left(getColNull(other_phone),16));
        oAddrInst.setString(24, getColNull(po_box));
        oAddrInst.setString(25, getColNull(tx_email));
        oAddrInst.setString(26, getColNull(tx_email_alt));
        oAddrInst.setString(27, getColNull(url_addr));
        oAddrInst.setObject(28, aValues[coord_x], Types.FLOAT);
        oAddrInst.setObject(29, aValues[coord_y], Types.FLOAT);
        oAddrInst.setString(30, getColNull(contact_person));
        oAddrInst.setString(31, getColNull(tx_salutation));
        oAddrInst.setString(32, getColNull(id_address_ref));
        oAddrInst.setString(33, getColNull(tx_remarks));
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(34,"+aValues[gu_address]+")");
        oAddrInst.setString(34, (String) aValues[gu_address]);
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate(oAddrInst)");
        iAffected = oAddrInst.executeUpdate();
        
        if (DebugFile.trace) DebugFile.writeln("affected="+String.valueOf(iAffected));

        if (test(iFlags,WRITE_COMPANIES) && !test(iFlags,WRITE_CONTACTS)) {
          if (DebugFile.trace) DebugFile.writeln("Writting link between company and address");
          oCompAddr.setString(1, (String) aValues[gu_company]);
          oCompAddr.setString(2, (String) aValues[gu_address]);
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate(oCompAddr)");
          oCompAddr.executeUpdate();
        } else if (test(iFlags,WRITE_CONTACTS)) {
          if (DebugFile.trace) DebugFile.writeln("Writting link between contact and address");
          oContAddr.setString(1, (String) aValues[gu_contact]);
          oContAddr.setString(2, (String) aValues[gu_address]);
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate(oContAddr)");
          oContAddr.executeUpdate();
        }

        if (test(iFlags,ADD_TO_LIST)) {
          if (test(iFlags,WRITE_CONTACTS))
	        oDistribList.addContact(oConn, (String) aValues[gu_contact]);
	      else if (test(iFlags,WRITE_COMPANIES))
	        oDistribList.addCompany(oConn, (String) aValues[gu_company]);	      	
	    } 
      } else {
        if (test(iFlags,ADD_TO_LIST)) {
          PreparedStatement oMmbr;
          PreparedStatement oUdlm;
          if (test(iFlags,WRITE_CONTACTS)) {
            oMmbr = oConn.prepareStatement("SELECT NULL FROM k_x_list_members WHERE gu_list=? AND gu_contact=?",
        							       ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
			oMmbr.setObject(1, get(gu_list), Types.CHAR);
			oMmbr.setObject(2, get(gu_contact), Types.CHAR);
			ResultSet oRmbr = oMmbr.executeQuery();
			boolean bMmbrExists = oRmbr.next();
			oRmbr.close();
			oMmbr.close();
			if (bMmbrExists) {
			  if (iListType==DistributionList.TYPE_DIRECT) {
			    oUdlm = oConn.prepareStatement("UPDATE "+DB.k_x_list_members+" SET "+
			    						  DB.dt_modified+"=?,"+DB.tx_name+"=?,"+DB.tx_surname+"=?,"+
			    						  DB.mov_phone+"=? WHERE "+DB.gu_list+"=? AND "+DB.tx_email+"=?");
			    oUdlm.setTimestamp(1, new Timestamp(new Date().getTime()));
			    oUdlm.setObject(2, get(tx_name), Types.VARCHAR);
			    oUdlm.setObject(3, get(tx_surname), Types.VARCHAR);
			    oUdlm.setObject(4, get(mov_phone), Types.VARCHAR);
			    oUdlm.setObject(5, get(gu_list), Types.CHAR);
			    oUdlm.setObject(6, get(tx_email), Types.VARCHAR);
			    oUdlm.executeUpdate();
			    oUdlm.close();
			  }
		  	} else {
			  oDistribList.addContact(oConn, (String) aValues[gu_contact]);
			}
          } else if (test(iFlags,WRITE_COMPANIES)) {
            oMmbr = oConn.prepareStatement("SELECT NULL FROM k_x_list_members WHERE gu_list=? AND gu_company=?",
        							       ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
			oMmbr.setObject(1, get(gu_list), Types.CHAR);
			oMmbr.setObject(2, get(gu_company), Types.CHAR);
			ResultSet oRmbr = oMmbr.executeQuery();
			boolean bMmbrExists = oRmbr.next();
			oRmbr.close();
			oMmbr.close();
			if (bMmbrExists) {
			  if (iListType==DistributionList.TYPE_DIRECT) {
			    oUdlm = oConn.prepareStatement("UPDATE "+DB.k_x_list_members+" SET "+
			    						  DB.dt_modified+"=?,"+DB.mov_phone+"=? "+
			    						  "WHERE "+DB.gu_list+"=? AND "+DB.tx_email+"=?");
			    oUdlm.setTimestamp(1, new Timestamp(new Date().getTime()));
			    oUdlm.setObject(4, get(mov_phone), Types.VARCHAR);
			    oUdlm.setObject(5, get(gu_list), Types.CHAR);
			    oUdlm.setObject(6, get(tx_email), Types.VARCHAR);
			    oUdlm.executeUpdate();
			    oUdlm.close();
			  }
		  	} else {
			  oDistribList.addCompany(oConn, (String) aValues[gu_company]);
			}
          }
	    }      
      } // fi (iAffected==0)
    } // fi test(iFlags,MODE_APPEND))

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ContactLoader.store()");
    }
  } // store

  // ---------------------------------------------------------------------------

  public static final int MODE_APPEND = ImportLoader.MODE_APPEND;
  public static final int MODE_UPDATE = ImportLoader.MODE_UPDATE;
  public static final int MODE_APPENDUPDATE = ImportLoader.MODE_APPENDUPDATE;
  public static final int WRITE_LOOKUPS = ImportLoader.WRITE_LOOKUPS;

  public static final int WRITE_COMPANIES = 32;
  public static final int WRITE_CONTACTS = 64;
  public static final int WRITE_ADDRESSES = 128;
  public static final int NO_DUPLICATED_NAMES = 256;
  public static final int NO_DUPLICATED_MAILS = 512;
  public static final int ALLOW_DUPLICATED_PASSPORTS = 2048;
  public static final int ADD_TO_LIST = 1024;

  // ---------------------------------------------------------------------------

  // Keep this list sorted
  private static final String[] ColumnNames = { "", "bo_active","bo_change_pwd","bo_private","contact_person","coord_x"  ,"coord_y"  ,"de_company" ,"de_title","direct_phone","dt_birth","dt_created","dt_drivelic","dt_founded","dt_modified","dt_pwd_expires","fax_phone","gu_address","gu_company","gu_contact","gu_geozone","gu_list","gu_sales_man","gu_workarea","gu_writer","home_phone","id_address_ref","id_batch","id_company_ref","id_company_status","id_contact_ref","id_contact_status","id_country","id_gender","id_legal","id_nationality","id_sector","id_state","im_revenue","ix_address","mn_city","mov_phone","nm_commercial","nm_company","nm_country","nm_legal","nm_state","nm_street","nu_employees","nu_street","ny_age","other_phone","po_box","sn_drivelic","sn_passport","tp_company","tp_location","tp_passport","tp_street","tx_addr1","tx_addr2","tx_challenge","tx_comments","tx_dept","tx_division","tx_email","tx_email_alt","tx_franchise","tx_name","tx_nickname","tx_pwd","tx_remarks","tx_reply","tx_salutation","tx_surname","url_addr","work_phone","zipcode"};

  // ---------------------------------------------------------------------------

  // Keep these column indexes in sync with ColumnNames array
  public static int bo_active =1;
  public static int bo_change_pwd =2;
  public static int bo_private =3;
  public static int contact_person =4;
  public static int coord_x =5;
  public static int coord_y =6;
  public static int de_company =7;
  public static int de_title =8;
  public static int direct_phone =9;
  public static int dt_birth =10;
  public static int dt_created =11;
  public static int dt_drivelic =12;
  public static int dt_founded =13;
  public static int dt_modified =14;
  public static int dt_pwd_expires =15;
  public static int fax_phone =16;
  public static int gu_address =17;
  public static int gu_company =18;
  public static int gu_contact =19;
  public static int gu_geozone =20;
  public static int gu_list =21; 
  public static int gu_sales_man =22;
  public static int gu_workarea =23;
  public static int gu_writer =24;
  public static int home_phone =25;
  public static int id_address_ref =26;
  public static int id_batch =27;
  public static int id_company_ref =28;
  public static int id_company_status =29;
  public static int id_contact_ref =30;
  public static int id_contact_status =31;
  public static int id_country =32;
  public static int id_gender =33;
  public static int id_legal =34;
  public static int id_nationality =35;
  public static int id_sector =36;
  public static int id_state =37;
  public static int im_revenue =38;
  public static int ix_address =39;
  public static int mn_city =40;
  public static int mov_phone =41;
  public static int nm_commercial =42;
  //public static int nm_company =43;
  public static int nm_country =44;
  public static int nm_legal =45;
  public static int nm_state =46;
  public static int nm_street =47;
  public static int nu_employees =48;
  public static int nu_street =49;
  public static int ny_age =50;
  public static int other_phone =51;
  public static int po_box =52;
  public static int sn_drivelic =53;
  public static int sn_passport =54;
  public static int tp_company =55;
  public static int tp_location =56;
  public static int tp_passport =57;
  public static int tp_street =58;
  public static int tx_addr1 =59;
  public static int tx_addr2 =60;
  public static int tx_challenge =61;
  public static int tx_comments =62;
  public static int tx_dept =63;
  public static int tx_division =64;
  public static int tx_email =65;
  public static int tx_email_alt =66;
  public static int tx_franchise =67;
  public static int tx_name =68;
  public static int tx_nickname =69;
  public static int tx_pwd =70;
  public static int tx_remarks =71;
  public static int tx_reply =72;
  public static int tx_salutation =73;
  public static int tx_surname =74;
  public static int url_addr =75;
  public static int work_phone =76;
  public static int zipcode =77;
}
