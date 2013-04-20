/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.hipergate.QueryByForm;

/**
 * <p>Distribution List</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class DistributionList extends DBPersist {

  public DistributionList() {
    super(DB.k_lists, "DistributionList");
  }

  /**
   * Create and load distribution list
   * @param oConn JDCConnection HDBC Connection
   * @param sListGUID String List GUID
   * @throws SQLException
   */
  public DistributionList(JDCConnection oConn, String sListGUID) throws SQLException {
    super(DB.k_lists, "DistributionList");
    load(oConn, new Object[]{sListGUID});
  }

  // ----------------------------------------------------------

  /**
   * Create a distribution list and load its by name
   * @param oConn JDCConnection JDBC Connection
   * @param sListDesc String List Description
   * @param sWorkAreaGUID String GUID of WorkArea to which list belongs
   * @throws SQLException
   */
  public DistributionList(JDCConnection oConn, String sListDesc, String sWorkAreaGUID) throws SQLException {
    super(DB.k_lists, "DistributionList");

    String sListGUID;
    PreparedStatement oStmt;
    
    if (null==sWorkAreaGUID) {
      oStmt = oConn.prepareStatement("SELECT "+DB.gu_list+" FROM "+DB.k_lists+" WHERE "+DB.de_list+"=?",
                                    ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sListDesc);
    } else {
      oStmt = oConn.prepareStatement("SELECT "+DB.gu_list+" FROM "+DB.k_lists+" WHERE "+DB.gu_workarea+"=? AND "+DB.de_list+"=?",
                                    ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sWorkAreaGUID);
      oStmt.setString(2, sListDesc);
    }
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sListGUID = oRSet.getString(1);
    else
      sListGUID = null;
    oRSet.close();
    oStmt.close();

    if (null!=sListGUID)
      load(oConn, new Object[]{sListGUID});
  }

  // ----------------------------------------------------------

  /**
   * Count active members of this list
   * @param oConn JDBC Database Connection
   * @return Count of members of this list which bo_active field is not zero.
   * @throws SQLException
   */
  public int memberCount(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.memberCount([Connection])");
      DebugFile.incIdent();
    }

    String sSQL;
    String sTableName;
    String sWhere;
    Statement oStmt;
    ResultSet oRSet;
    int iCount;

    String sBlackList = blackList(oConn);
	 
    if (getShort(DB.tp_list)==TYPE_DYNAMIC) {
	  String sQrySpec = DBCommand.queryStr(oConn, "SELECT "+DB.nm_queryspec+" FROM "+DB.k_queries+" WHERE "+DB.gu_query+"='"+getStringNull(DB.gu_query,"")+"'");
	  if (null==sQrySpec) sQrySpec = "";
      if (sQrySpec.equals("peticiones"))
        sTableName = "v_oportunity_contact_address";
      else if (sQrySpec.equals("contacts"))
      	sTableName = DB.v_contact_address;
      else
    	sTableName = DB.k_member_address;

      QueryByForm oQBF = new QueryByForm(oConn, sTableName, "m", getStringNull(DB.gu_query,""));

      sWhere = "m." + DB.gu_workarea + "='" + getString(DB.gu_workarea) + "' AND ";
      sWhere+= "(" + oQBF.composeSQL() + ") AND ";
      sWhere+= " NOT EXISTS (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " b WHERE b." + DB.gu_list + "='" + sBlackList + "' AND b." + DB.tx_email + "=m." + DB.tx_email + ")";

      oQBF = null;
    }
    else {
      sTableName = DB.k_x_list_members;
      sWhere = "m." + DB.gu_list + "='" + getString(DB.gu_list) + "' AND ";
      sWhere+= "m." + DB.bo_active + "<>0 ";

      if (getShort(DB.tp_list)!=TYPE_BLACK)
        sWhere+= " AND NOT EXISTS (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " b WHERE b." + DB.gu_list + "='" + sBlackList + "' AND b." + DB.tx_email + "=m." + DB.tx_email + ")";
    }

    sSQL = "SELECT COUNT(*) FROM " + sTableName + " m WHERE " + sWhere;

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

    oRSet = oStmt.executeQuery(sSQL);

    oRSet.next();

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE)
      iCount = oRSet.getBigDecimal(1).intValue();
    else
      iCount = oRSet.getInt(1);

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.memberCount()");
    }

    return iCount;
  } // memberCount

  // ----------------------------------------------------------

  /**
   * Get e-mail address for all active members
   * @param oConn JDBC Database Connection
   * @return String with e-mail addresses delimited by commas
   * @throws SQLException
   * @throws IllegalStateException
   */
  public String activeMembers(JDCConnection oConn)
    throws SQLException,IllegalStateException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.activeMembers([Connection])");
      if (isNull(DB.tp_list))
        throw new IllegalStateException("DistributionList.activeMembers() list type not set");
      DebugFile.incIdent();
    }

    String sSQL;
    String sTableName;
    String sWhere;
    StringBuffer oBuffer;
    Statement oStmt;
    ResultSet oRSet;

    String sBlackList = blackList(oConn);
	String sQrySpec = DBCommand.queryStr(oConn, "SELECT "+DB.nm_queryspec+" FROM "+DB.k_queries+" WHERE "+DB.gu_query+"='"+getStringNull(DB.gu_query,"")+"'");
	if (null==sQrySpec) sQrySpec = "";

    if (getShort(DB.tp_list)==TYPE_DYNAMIC) {
      if (sQrySpec.equals("peticiones"))
        sTableName = "v_oportunity_contact_address";
      else if (sQrySpec.equals("contacts"))
        sTableName = DB.v_contact_address;
      else
        sTableName = DB.k_member_address;

      QueryByForm oQBF = new QueryByForm(oConn, sTableName, "m", getStringNull(DB.gu_query,""));

      sWhere = "m." + DB.gu_workarea + "='" + getString(DB.gu_workarea) + "' AND ";
      sWhere+= "(" + oQBF.composeSQL() + ") AND ";
      sWhere+= " NOT EXISTS (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " b WHERE b." + DB.gu_list + "='" + sBlackList + "' AND b." + DB.tx_email + "=m." + DB.tx_email + ")";

      oQBF = null;
    }
    else {
      sTableName = DB.k_x_list_members;
      sWhere = "m." + DB.gu_list + "='" + getString(DB.gu_list) + "' AND ";
      sWhere+= "m." + DB.bo_active + "<>0 ";

      if (getShort(DB.tp_list)!=TYPE_BLACK)
        sWhere+= " AND NOT EXISTS (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " b WHERE b." + DB.gu_list + "='" + sBlackList + "' AND b." + DB.tx_email + "=m." + DB.tx_email + ")";
    }

    sSQL = "SELECT " + DB.tx_email + " FROM " + sTableName + " m WHERE " + sWhere;

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

    oRSet = oStmt.executeQuery(sSQL);

    try { oRSet.setFetchSize(500); }  catch (SQLException sqle) { /* ignore */}

    oBuffer = new StringBuffer(4096);

    if (oRSet.next())
      oBuffer.append(oRSet.getString(1));

    while (oRSet.next()) {
      oBuffer.append(",");
      oBuffer.append(oRSet.getString(1));
    } // wend

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.activeMembers()");
    }

    return oBuffer.toString();
  } // activeMembers

  // ----------------------------------------------------------

  /**
   * Get GUIDs for all active contacts
   * @param oConn JDBC Database Connection
   * @return String with GUIDs delimited by commas
   * @throws SQLException
   */

  public String activeContacts(JDCConnection oConn) throws SQLException {

    if (getShort(DB.tp_list)==TYPE_DIRECT)
      throw new SQLException ("Contacts cannot be directly retrived for DIRECT lists");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.activeContacts([Connection])");
      DebugFile.incIdent();
    }

    String sSQL;
    String sTableName = null;
    String sWhere = null;
    StringBuffer oBuffer;
    Statement oStmt;
    ResultSet oRSet;

    String sBlackList = blackList(oConn);

	String sQrySpec = DBCommand.queryStr(oConn, "SELECT "+DB.nm_queryspec+" FROM "+DB.k_queries+" WHERE "+DB.gu_query+"='"+getStringNull(DB.gu_query,"")+"'");
	if (null==sQrySpec) sQrySpec = "";

    if (getShort(DB.tp_list)==TYPE_DYNAMIC) {
      if (sQrySpec.equals("peticiones"))
        sTableName = "v_oportunity_contact_address";
      else if (sQrySpec.equals("contacts"))
        sTableName = DB.v_contact_address;
      else
        sTableName = DB.k_member_address;

      QueryByForm oQBF = new QueryByForm(oConn, sTableName, "m", getStringNull(DB.gu_query,""));

      sWhere = "m." + DB.gu_workarea + "='" + getString(DB.gu_workarea) + "' AND ";
      sWhere+= "(" + oQBF.composeSQL() + ") AND " + DB.gu_contact + " IS NOT NULL AND ";
      sWhere+= " NOT EXISTS (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " b WHERE b." + DB.gu_list + "='" + sBlackList + "' AND b." + DB.tx_email + "=m." + DB.tx_email + ")";

      oQBF = null;
    }
    else if (getShort(DB.tp_list)!=TYPE_DIRECT) {
      sTableName = DB.k_x_list_members;
      sWhere = "m." + DB.gu_list + "='" + getString(DB.gu_list) + "' AND ";
      sWhere+= "m." + DB.bo_active + "<>0 AND " + DB.gu_contact + " IS NOT NULL ";

      if (getShort(DB.tp_list)!=TYPE_BLACK)
        sWhere+= " AND NOT EXISTS (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " b WHERE b." + DB.gu_list + "='" + sBlackList + "' AND b." + DB.tx_email + "=m." + DB.tx_email + ")";
    }

    sSQL = "SELECT " + DB.gu_contact + " FROM " + sTableName + " m WHERE " + sWhere;

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    try { oStmt.setQueryTimeout(120); }  catch (SQLException sqle) { /* ignore */}

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

    oRSet = oStmt.executeQuery(sSQL);

    try { oRSet.setFetchSize(500); }  catch (SQLException sqle) { /* ignore */}

    oBuffer = new StringBuffer(4096);

    if (oRSet.next())
      oBuffer.append(oRSet.getString(1));

    while (oRSet.next()) {
      oBuffer.append(",");
      oBuffer.append(oRSet.getString(1));
    } // wend

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.activeContacts()");
    }

    return oBuffer.toString();
  }

  // ----------------------------------------------------------

  /**
   * Get GUIDs for all active companies
   * @param oConn JDBC Database Connection
   * @return String with GUIDs delimited by commas
   * @throws SQLException
   */

  public String activeCompanies(JDCConnection oConn) throws SQLException {

    if (getShort(DB.tp_list)==TYPE_DIRECT)
      throw new SQLException ("Companies cannot be directly retrived for DIRECT lists");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.activeCompanies([Connection])");
      DebugFile.incIdent();
    }

    String sBlackList = blackList(oConn);

    String sSQL;
    String sTableName;
    String sWhere;
    StringBuffer oBuffer;
    Statement oStmt;
    ResultSet oRSet;

	String sQrySpec = DBCommand.queryStr(oConn, "SELECT "+DB.nm_queryspec+" FROM "+DB.k_queries+" WHERE "+DB.gu_query+"='"+getStringNull(DB.gu_query,"")+"'");
	if (null==sQrySpec) sQrySpec = "";

    if (getShort(DB.tp_list)==TYPE_DYNAMIC) {
      if (sQrySpec.equals("peticiones"))
        sTableName = "v_oportunity_contact_address";
      else if (sQrySpec.equals("contacts"))
          sTableName = DB.v_contact_address;
      else
        sTableName = DB.k_member_address;

      QueryByForm oQBF = new QueryByForm(oConn, sTableName, "m", getStringNull(DB.gu_query,""));

      sWhere = "m." + DB.gu_workarea + "='" + getString(DB.gu_workarea) + "' AND ";
      sWhere+= "(" + oQBF.composeSQL() + ") AND " + DB.gu_company + " IS NOT NULL AND ";
      sWhere+= " NOT EXISTS (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " b WHERE b." + DB.gu_list + "='" + sBlackList + "' AND b." + DB.tx_email + "=m." + DB.tx_email + ")";

      oQBF = null;
    }
    else {
      sTableName = DB.k_x_list_members;
      sWhere = "m." + DB.gu_list + "='" + getString(DB.gu_list) + "' AND ";
      sWhere+= "m." + DB.bo_active + "<>0 AND " + DB.gu_company + " IS NOT NULL ";

      if (getShort(DB.tp_list)!=TYPE_BLACK)
        sWhere+= " AND NOT EXISTS (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " b WHERE b." + DB.gu_list + "='" + sBlackList + "' AND b." + DB.tx_email + "=m." + DB.tx_email + ")";
    }

    sSQL = "SELECT " + DB.gu_company + " FROM " + sTableName + " m WHERE " + sWhere;

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

    oRSet = oStmt.executeQuery(sSQL);

    try { oRSet.setFetchSize(500); }  catch (SQLException sqle) { /* ignore */}

    oBuffer = new StringBuffer(4096);

    if (oRSet.next())
      oBuffer.append(oRSet.getString(1));

    while (oRSet.next()) {
      oBuffer.append(",");
      oBuffer.append(oRSet.getString(1));
    } // wend

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.activeCompanies()");
    }

    return oBuffer.toString();
  } // activeCompanies

  // ----------------------------------------------------------

  /**
   * <p>Find out if list contains a particular member</p>
   * Member is searched at k_x_list_members table either at gu_company and
   * gu_contact or tx_email. If list is Dynamic or Static, member is searched at
   * gu_company and gu_contact. If list is Direct or Black, member is searched at tx_email
   * @param oConn Database Connection
   * @param sMember If this is a Static or Dynamic list then sMember must be the GUID of Contact or Company searched.<br>
   * If this is a Direct or Black list then sMember must be an e-mail address.
   * @return <b>true</b> if sMember is contained in list.<br>
   * Take into account that the member may be unactive or blocked and still be contained at the list.<br>
   * Unactive (k_x_list_members.bo_active=0) and blocked (present at black list) members should not receive any e-mails.
   * @throws SQLException
   */
  public boolean contains (JDCConnection oConn, String sMember) throws SQLException {
    boolean bRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;
    QueryByForm oQBF;
	String sTableName;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.contains([Connection], " + sMember + ")");
      DebugFile.incIdent();
    }

    switch (getShort(DB.tp_list)) {

      case TYPE_DYNAMIC:
		String sQrySpec = DBCommand.queryStr(oConn, "SELECT "+DB.nm_queryspec+" FROM "+DB.k_queries+" WHERE "+DB.gu_query+"='"+getStringNull(DB.gu_query,"")+"'");
	    if (null==sQrySpec) sQrySpec = "";
        if (sQrySpec.equals("peticiones"))
          sTableName = "v_oportunity_contact_address";
        else if (sQrySpec.equals("contacts"))
            sTableName = DB.v_contact_address;
        else
          sTableName = DB.k_member_address;

        oQBF = new QueryByForm(oConn, sTableName, "ma", getString (DB.gu_query));

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM " + sTableName + " ma WHERE ma." + DB.gu_workarea + "=? AND (ma." + DB.gu_contact + "='" + sMember + "' OR ma." + DB.gu_company + "='" + sMember + "') AND (" + oQBF.composeSQL() + "))");

        oStmt = oConn.prepareStatement("SELECT NULL FROM " + sTableName + " ma WHERE ma." + DB.gu_workarea + "=? AND (ma." + DB.gu_contact + "=? OR ma." + DB.gu_company + "=?) AND (" + oQBF.composeSQL() + ")", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

        oStmt.setString(1, getString(DB.gu_workarea));
        oStmt.setString(2, sMember);
        oStmt.setString(3, sMember);
        oRSet = oStmt.executeQuery();
        bRetVal = oRSet.next();
        oRSet.close();
        oStmt.close();

        oQBF = null;
        break;

      case TYPE_STATIC:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + getString(DB.gu_list) + "' AND (" + DB.gu_contact + "='" + sMember + "' OR " + DB.gu_company + "='" + sMember + "'))");

        oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "=? AND (" + DB.gu_contact + "=? OR " + DB.gu_company + "=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, getString(DB.gu_list));
        oStmt.setString(2, sMember);
        oStmt.setString(3, sMember);
        oRSet = oStmt.executeQuery();
        bRetVal = oRSet.next();
        oRSet.close();
        oStmt.close();
        break;

      case TYPE_DIRECT:
      case TYPE_BLACK:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "=? AND " + DB.tx_email + "='" + sMember + "')");

        oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "=? AND " + DB.tx_email + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, getString(DB.gu_list));
        oStmt.setString(2, sMember);
        oRSet = oStmt.executeQuery();
        bRetVal = oRSet.next();
        oRSet.close();
        oStmt.close();
        break;

      default:
        throw new java.lang.IllegalArgumentException("DistributionList.contains() invalid value of tp_list property");
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.contains() : " + String.valueOf(bRetVal));
    }
    return bRetVal;
  }

  // ----------------------------------------------------------

  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    boolean bRetVal = super.load(oConn, PKVals);
    if (bRetVal) {
      String sGuCategory = DBCommand.queryStr(oConn, "SELECT "+DB.gu_category+" FROM "+DB.k_x_cat_objs+" WHERE "+DB.gu_object+"='"+getString(DB.gu_list)+"'");
      if (null!=sGuCategory) put(DB.gu_category, sGuCategory);
    }
    return bRetVal;
  } // load

  // ----------------------------------------------------------

  public boolean load(JDCConnection oConn, String sGuList) throws SQLException {
    boolean bRetVal = super.load(oConn, sGuList);
    if (bRetVal) {
      String sGuCategory = DBCommand.queryStr(oConn, "SELECT "+DB.gu_category+" FROM "+DB.k_x_cat_objs+" WHERE "+DB.gu_object+"='"+sGuList+"'");
      if (null!=sGuCategory) put(DB.gu_category, sGuCategory);
    }
    return bRetVal;
  } // load
  
  // ----------------------------------------------------------

  /**
   * <p>Store DistributionList</p>
   * Automatically generates gu_list GUID if not explicitly set.
   * If value gu_category is set then this list is added to that category
   * and removed from any previous category to which it belonged.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin DistributionList.store([JDCConnection])");
	  DebugFile.incIdent();
	  DebugFile.writeln("gu_category="+getStringNull(DB.gu_category,"null"));
	}
	
	boolean bRetVal;
    if (!AllVals.containsKey(DB.gu_list)) {
      put(DB.gu_list, Gadgets.generateUUID());
	  bRetVal = super.store(oConn);
    } else {
	  bRetVal = super.store(oConn);
	  DBCommand.executeUpdate(oConn, "DELETE FROM "+DB.k_x_cat_objs+" WHERE "+DB.gu_object+"='"+getString(DB.gu_list)+"'");		
    }
    if (!isNull(DB.gu_category))
	  DBCommand.executeUpdate(oConn, "INSERT INTO "+DB.k_x_cat_objs+" ("+DB.gu_category+","+DB.gu_object+","+DB.id_class+","+DB.bi_attribs+","+DB.od_position+") VALUES ('"+getString(DB.gu_category)+"','"+getString(DB.gu_list)+"',"+String.valueOf(DistributionList.ClassId)+",0,0)");

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End DistributionList.store()");
	}

    return bRetVal;
  } // store()

  // ----------------------------------------------------------

  public boolean delete(JDCConnection oConn) throws SQLException {
    return DistributionList.delete(oConn, getString(DB.gu_list));
  } // delete()

  // ----------------------------------------------------------

  /**
   * <p>Get associated Black List GUID</p>
   * The Black List is that witch tp_list=BLACK_LIST AND gu_query=this.gu_list
   * @param oConn Database Connection
   * @return Black List GUID or <b>null</b> if there is no associated Black List.
   * @throws SQLException
   * @throws IllegalStateException if this DistributionList has not been previously loaded
   */
  public String blackList(JDCConnection oConn) throws SQLException, IllegalStateException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sBlackListId;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.blackList([Connection])");
      if (isNull(DB.gu_workarea))
        throw new IllegalStateException("DistributionList.blackList() workarea is not set");
      if (isNull(DB.gu_list))
        throw new IllegalStateException("DistributionList.blackList() list GUID is not set");
      DebugFile.incIdent();
    }

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_workarea + "=? AND " + DB.tp_list + "=" + String.valueOf(TYPE_BLACK) + " AND " + DB.gu_query + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oStmt.setString(1, getString(DB.gu_workarea));
    oStmt.setString(2, getString(DB.gu_list));

    oRSet = oStmt.executeQuery();

    if (oRSet.next())
      sBlackListId = oRSet.getString(1);
    else
      sBlackListId = null;

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.blackList() : " + (sBlackListId!=null ? sBlackListId : "null"));
    }

    return sBlackListId;
  } // blackList()

  // ----------------------------------------------------------

  /**
   * <p>Add Contact e-mails to Static, Direct or Black List</p>
   * If Contact has several addresses then all of them are added to the list
   * @param oConn Database Connection
   * @param Contact GUID
   * @return Black List GUID or <b>null</b> if there is no associated Black List.
   * @throws SQLException
   * @throws IllegalStateException if this DistributionList has not been previously loaded
   * @since 5.0
   */
  public int addContact(Connection oConn, String sContactGUID)
  	throws IllegalStateException,SQLException {
    
    if (isNull(DB.gu_list)) throw new IllegalStateException("DistributionList.addContact() List GUID not set");
    if (isNull(DB.gu_workarea)) throw new IllegalStateException("DistributionList.addContact() List Work Area not set");
    if (isNull(DB.tp_list)) throw new IllegalStateException("DistributionList.addContact() List Type not set");
	if (getShort(DB.tp_list)==TYPE_DYNAMIC) throw new SQLException ("DistributionList.addContact() Dynamic list "+getString(DB.gu_list)+" does not allow manual addition of contact members");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.addContact([JDCConnection], "+sContactGUID+")");
      DebugFile.incIdent();
    }
  	
	int iAffected = DBCommand.executeUpdate(oConn, "INSERT INTO "+DB.k_x_list_members+" (gu_list,tx_email,tx_name,tx_surname,mov_phone,dt_created,gu_company,gu_contact) SELECT '"+getString(DB.gu_list)+"',"+DBBind.Functions.ISNULL+"(tx_email,'"+sContactGUID+"@hasnoemailaddress.net'),tx_name,tx_surname,mov_phone,dt_created,gu_company,gu_contact FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+getString(DB.gu_workarea)+"' AND "+DB.gu_contact+"='"+sContactGUID+"' AND "+DB.gu_contact+" NOT IN (SELECT "+DB.gu_contact+" FROM "+DB.k_x_list_members+" WHERE "+DB.gu_list+"='"+getString(DB.gu_list)+"') AND ("+DB.tx_email+" IS NOT NULL OR "+DB.mov_phone+" IS NOT NULL)");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.addContact() : "+String.valueOf(iAffected));
    }

	return iAffected;
  } // addContact

  // ----------------------------------------------------------

  /**
   * <p>Add Contact e-mails to Static, Direct or Black List</p>
   * If Contact has several addresses then all of them are added to the list
   * @param oConn Database Connection
   * @param Contact GUID
   * @return Black List GUID or <b>null</b> if there is no associated Black List.
   * @throws SQLException
   * @throws IllegalStateException if this DistributionList has not been previously loaded
   * @since 6.0
   */
  public int addCompany(Connection oConn, String sCompanyGUID)
  	throws IllegalStateException,SQLException {
    
    if (isNull(DB.gu_list)) throw new IllegalStateException("DistributionList.addContact() List GUID not set");
    if (isNull(DB.gu_workarea)) throw new IllegalStateException("DistributionList.addContact() List Work Area not set");
    if (isNull(DB.tp_list)) throw new IllegalStateException("DistributionList.addContact() List Type not set");
	if (getShort(DB.tp_list)==TYPE_DYNAMIC) throw new SQLException ("DistributionList.addContact() Dynamic list "+getString(DB.gu_list)+" does not allow manual addition of contact members");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.addCompany([JDCConnection], "+sCompanyGUID+")");
      DebugFile.incIdent();
    }
  	
	int iAffected = DBCommand.executeUpdate(oConn, "INSERT INTO "+DB.k_x_list_members+" (gu_list,tx_email,tx_name,tx_surname,mov_phone,dt_created,gu_company,gu_contact) SELECT '"+getString(DB.gu_list)+"',"+DBBind.Functions.ISNULL+"(tx_email,'"+sCompanyGUID+"@hasnoemailaddress.net'),tx_name,tx_surname,mov_phone,dt_created,gu_company,NULL FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+getString(DB.gu_workarea)+"' AND "+DB.gu_company+"='"+sCompanyGUID+"' AND "+DB.gu_company+" NOT IN (SELECT "+DB.gu_company+" FROM "+DB.k_x_list_members+" WHERE "+DB.gu_list+"='"+getString(DB.gu_list)+"') AND ("+DB.tx_email+" IS NOT NULL OR "+DB.mov_phone+" IS NOT NULL)");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.addCompany() : "+String.valueOf(iAffected));
    }

	return iAffected;
  } // addCompany
  
  // ----------------------------------------------------------

  /**
   * <p>Append members of a list to this DistributionList.<p>
   * Members that where already present are not touched.
   * Results are placed at this DistributionList.
   * @param oConn Database Connection
   * @param sListGUID GUID of DistributionList to be appended
   * @throws SQLException
   * @throws IllegalArgumentException If sListGUID==null
   * @throws IllegalStateException If this.gu_list is not set
   * @throws ClassCastException If this DistributionList type is DYNAMIC
   */
  public void append(JDCConnection oConn, String sListGUID) throws SQLException,IllegalArgumentException,IllegalStateException,ClassCastException {
    Statement oInsrt;
    String sSQL;
    String  sColumnList;
    String sTableName;
    DistributionList oAppendedList;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.append([Connection], " + (sListGUID!=null ? sListGUID : "null") + ")");
      DebugFile.incIdent();
    }

    if (null==sListGUID)
      throw new IllegalArgumentException("list id cannot be null");

    if (null==get(DB.gu_list))
      throw new IllegalStateException("list id not set");

    if (getShort(DB.tp_list)==DistributionList.TYPE_DYNAMIC)
      throw new ClassCastException("append operation not supported for Dynamic lists");

    if (sListGUID.equals(getString(DB.gu_list))) return;

    oAppendedList = new DistributionList(oConn, sListGUID);

    // *******************************************************************
    // Añadir los miembros que no estuviesen ya presentes en la lista base

    oInsrt = oConn.createStatement();

    if (oAppendedList.getShort(DB.tp_list)==TYPE_DYNAMIC) {

	  String sQrySpec = DBCommand.queryStr(oConn, "SELECT "+DB.nm_queryspec+" FROM "+DB.k_queries+" WHERE "+DB.gu_query+"='"+oAppendedList.getStringNull(DB.gu_query,"")+"'");
	  if (null==sQrySpec) sQrySpec = "";

      if (sQrySpec.equals("peticiones"))
        sTableName = "v_oportunity_contact_address";
      else if (sQrySpec.equals("contacts"))
        sTableName = DB.v_contact_address;
      else
        sTableName = DB.k_member_address;

      // Componer la sentencia SQL de filtrado de datos a partir de la definición de la consulta almacenada en la tabla k_queries
      QueryByForm oQBF = new QueryByForm(oConn, sTableName, "ma", oAppendedList.getStringNull(DB.gu_query,""));
      sColumnList = DB.mov_phone + "," + DB.tx_email + "," + DB.tx_name + "," + DB.tx_surname + "," + DB.tx_salutation + "," + DB.gu_company + "," + DB.gu_contact;

      sSQL = "INSERT INTO " + DB.k_x_list_members + " ("+DB.gu_list+"," + sColumnList + ") " +
             "SELECT '" + getString(DB.gu_list) + "'," + sColumnList + " FROM " + sTableName  + " ma WHERE ma.gu_workarea='" + oAppendedList.getString(DB.gu_workarea) + "' AND (" + oQBF.composeSQL() + ") AND " +
             "ma." + DB.tx_email + " NOT IN (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + getString(DB.gu_list) + "')";
    }

    else {

      sColumnList = DB.tx_email + "," + DB.tx_name + "," + DB.tx_surname + "," + DB.tx_salutation + "," + DB.bo_active + "," + DB.gu_company + "," + DB.gu_contact + "," + DB.id_format;

      sSQL = "INSERT INTO " + DB.k_x_list_members + " ("+DB.gu_list+"," + sColumnList + ") " +
             "SELECT '" + getString(DB.gu_list) + "'," + sColumnList + " FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + sListGUID + "' AND " +
             DB.tx_email + " NOT IN (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + getString(DB.gu_list) + "')";

    }

    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");

    oInsrt.execute(sSQL);
    oInsrt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.append()");
    }
  } // append

  // ----------------------------------------------------------

  /**
   * Overwrite members of this DistributionList with members of given DistributionList.
   * Members of sListGUID not present at this list are NOT appended.
   * @param oConn Database Connection
   * @throws SQLException
   * @throws IllegalArgumentException If sListGUID==null
   * @throws IllegalStateException If this.gu_list is not set
   * @throws ClassCastException If this DistributionList type is DYNAMIC
   */
  public void overwrite(JDCConnection oConn, String sListGUID) throws SQLException,IllegalArgumentException,ClassCastException,IllegalStateException {
    Statement oInsrt;
    PreparedStatement oUpdt;
    ResultSet oRSet;
    String sSQL;
    String  sColumnList;
    String sTableName;
    DistributionList oAppendedList;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.overwrite([Connection], " + (sListGUID!=null ? sListGUID : "null") + ")");
      DebugFile.incIdent();
    }

    if (null==sListGUID)
      throw new IllegalArgumentException("list id cannot be null");

    if (null==get(DB.gu_list))
      throw new IllegalStateException("list id not set");

    if (getShort(DB.tp_list)==DistributionList.TYPE_DYNAMIC)
      throw new ClassCastException("overwrite operation not supported for Dynamic lists");

    if (sListGUID.equals(getString(DB.gu_list))) return;

    oAppendedList = new DistributionList(oConn, sListGUID);

    sColumnList = DB.mov_phone + DB.tx_email + "," + DB.tx_name + "," + DB.tx_surname + "," + DB.tx_salutation + "," + DB.bo_active + "," + DB.gu_company + "," + DB.gu_contact + "," + DB.id_format;

    // ************************************************************************************
    // Actualizar los miembros de la lista a añadir que ya estén presentes en la lista base

    // Preparar la sentencia de actualización de registros en la lista base
    sSQL = "UPDATE " + DB.k_x_list_members + " SET " + DB.tx_name + "=?," + DB.tx_surname + "=?," + DB.tx_salutation + "=?," + DB.bo_active + "=?," + DB.gu_company + "=?," + DB.gu_contact + "=?," + DB.id_format + "=? WHERE " + DB.gu_list + "='" + getString(DB.gu_list) + "' AND " + DB.tx_email + "=?";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

    oUpdt = oConn.prepareStatement(sSQL);

    // Preparar la sentencia para leer registros comunes en la lista añadida
    oInsrt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oInsrt.setQueryTimeout(60); }  catch (SQLException sqle) { /* ignore */}

    if (oAppendedList.getShort(DB.tp_list)==TYPE_DYNAMIC) {

	  String sQrySpec = DBCommand.queryStr(oConn, "SELECT "+DB.nm_queryspec+" FROM "+DB.k_queries+" WHERE "+DB.gu_query+"='"+oAppendedList.getStringNull(DB.gu_query,"")+"'");
	  if (null==sQrySpec) sQrySpec = "";

      if (sQrySpec.equals("peticiones"))
        sTableName = "v_oportunity_contact_address";
      else if (sQrySpec.equals("contacts"))
        sTableName = DB.v_contact_address;
      else
        sTableName = DB.k_member_address;

      QueryByForm oQBF = new QueryByForm(oConn, sTableName, "b", oAppendedList.getStringNull(DB.gu_query,""));

      sSQL = "SELECT b." + DB.tx_name + ",b." + DB.tx_surname + ",b." + DB.tx_salutation + ",1,b." + DB.gu_company + ",b." + DB.gu_contact + ",'TXT', a." + DB.tx_email + " FROM " + DB.k_x_list_members + " a, " + sTableName + " b WHERE a." + DB.gu_list + "='" + getString(DB.gu_list) + "' AND b." + DB.gu_workarea + "='" + oAppendedList.getString(DB.gu_workarea) + "' AND (" + oQBF.composeSQL() + ") AND a." + DB.tx_email + "=b." + DB.tx_email;

    } else {

      sSQL = "SELECT b." + DB.tx_name + ",b." + DB.tx_surname + ",b." + DB.tx_salutation + ",b." + DB.bo_active + ",b." + DB.gu_company + ",b." + DB.gu_contact + ",b." + DB.id_format + ", a." + DB.tx_email + " FROM " + DB.k_x_list_members + " a, " + DB.k_x_list_members + " b WHERE a." + DB.gu_list + "='" + getString(DB.gu_list) + "' AND b." + DB.gu_list + "='" + sListGUID + "' AND a." + DB.tx_email + "=b." + DB.tx_email;

    }

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

    oRSet = oInsrt.executeQuery(sSQL);

    // Recorrer los registros de la lista añadida que ya estén en la lista base
    // y actualizar sus campos con los valores de la lista añadida.
    while (oRSet.next()) {
      oUpdt.setObject(1, oRSet.getObject(1), Types.VARCHAR);  // tx_name
      oUpdt.setObject(2, oRSet.getObject(2), Types.VARCHAR);  // tx_surname
      oUpdt.setObject(3, oRSet.getObject(3), Types.VARCHAR);  // tx_salutation
      oUpdt.setObject(4, oRSet.getObject(4), Types.SMALLINT); // bo_active
      oUpdt.setObject(5, oRSet.getObject(5), Types.VARCHAR);  // gu_company
      oUpdt.setObject(6, oRSet.getObject(6), Types.VARCHAR);  // gu_contact
      oUpdt.setObject(7, oRSet.getObject(7), Types.VARCHAR);  // id_format
      oUpdt.setObject(8, oRSet.getObject(8), Types.VARCHAR);  // tx_email
      oUpdt.executeUpdate();
    } // wend

    oInsrt.close();
    oUpdt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.overwrite()");
    }
  } // overwrite

  // ----------------------------------------------------------

  /**
   * Remove from this DistributionList those members present at given DistributionList.
   * @param oConn Database Connection
   * @throws SQLException
   * @throws IllegalArgumentException If sListGUID==null
   * @throws IllegalStateException If this.gu_list is not set
   * @throws ClassCastException If this DistributionList type is DYNAMIC
   */
  public void substract(JDCConnection oConn, String sListGUID) throws SQLException,IllegalArgumentException,IllegalStateException,ClassCastException {
    String sSQL;
    Statement oDlte;
    String sTableName;
    DistributionList oAppendedList;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.substract([Connection], " + (sListGUID!=null ? sListGUID : "null") + ")");
      DebugFile.incIdent();
    }

    if (null==sListGUID)
      throw new IllegalArgumentException("list id cannot be null");

    if (null==get(DB.gu_list))
      throw new IllegalStateException("list id not set");

    if (getShort(DB.tp_list)==DistributionList.TYPE_DYNAMIC)
      throw new ClassCastException("substract operation not supported for Dynamic lists");

    oAppendedList = new DistributionList(oConn, sListGUID);

    if (sListGUID.equals(getString(DB.gu_list)))

      sSQL = "DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + getString(DB.gu_list) + "'";

    else if (oAppendedList.getShort(DB.tp_list)==TYPE_DYNAMIC) {

	  String sQrySpec = DBCommand.queryStr(oConn, "SELECT "+DB.nm_queryspec+" FROM "+DB.k_queries+" WHERE "+DB.gu_query+"='"+oAppendedList.getStringNull(DB.gu_query,"")+"'");
	  if (null==sQrySpec) sQrySpec = "";

      if (sQrySpec.equals("peticiones"))
        sTableName = "v_oportunity_contact_address";
      else if (sQrySpec.equals("contacts"))
        sTableName = DB.v_contact_address;
      else
        sTableName = DB.k_member_address;

      QueryByForm oQBF = new QueryByForm(oConn, sTableName, "ma", oAppendedList.getStringNull(DB.gu_query,""));

      sSQL = "DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + getString(DB.gu_list) + "' AND " + DB.tx_email + " IN (SELECT " + DB.tx_email + " FROM " + sTableName + " ma WHERE ma." + DB.gu_workarea + "='" + oAppendedList.getString(DB.gu_workarea) + "' AND (" + oQBF.composeSQL() + "))";
    }

    else

      sSQL = "DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + getString(DB.gu_list) + "' AND " + DB.tx_email + " IN (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + sListGUID + "')";

    oDlte = oConn.createStatement();

    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");

    oDlte.execute(sSQL);

    oDlte.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.substract()");
    }
  } // substract

  // ----------------------------------------------------------

  /**
   * Clone this DistributionList.
   * The associated Black List, if it exists, is also cloned and associated to the new clone.
   * @param oConn Database Connection
   * @return New DistributionList GUID
   * @throws SQLException
   */
  public String clone(JDCConnection oConn) throws SQLException {
    String sSQL;
    String sCloneId;
    Statement oStmt;
    DistributionList oClone;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.clone()");
      DebugFile.incIdent();
    }

    oClone = new DistributionList(oConn, getString(DB.gu_list));

    oClone.remove(DB.gu_list);
    oClone.store(oConn);

    sCloneId = oClone.getString(DB.gu_list);

    oStmt = oConn.createStatement();
	if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(60);

    sSQL = "INSERT INTO " + DB.k_x_list_members + "(gu_list,tx_email,tx_name,tx_surname,tx_salutation,bo_active,tp_member,gu_company,gu_contact,id_format) SELECT '" + oClone.getString(DB.gu_list) + "',tx_email,tx_name,tx_surname,tx_salutation,bo_active,tp_member,gu_company,gu_contact,id_format FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + getString(DB.gu_list) + "'";

    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");

    oStmt.execute(sSQL);

    String sBlackList = blackList(oConn);

    if (null!=sBlackList) {
      oClone = new DistributionList(oConn, sBlackList);

      oClone.remove(DB.gu_list);
      oClone.replace(DB.gu_query, sCloneId);
      oClone.store(oConn);

      sSQL = "INSERT INTO " + DB.k_x_list_members + "(gu_list,tx_email,tx_name,tx_surname,tx_salutation,bo_active,tp_member,gu_company,gu_contact,id_format) SELECT '" + oClone.getString(DB.gu_list) + "',tx_email,tx_name,tx_surname,tx_salutation,bo_active,tp_member,gu_company,gu_contact,id_format FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + sBlackList + "'";

      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");

      oStmt.execute(sSQL);
    } // fi(sBlackList)

    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.clone() : " + sCloneId);
    }
    return sCloneId;
  } // clone

  // ----------------------------------------------------------

  /**
   * <p>Delete duplicated e-mails from a static or direct list.</p>
   * This method calls k_sp_del_duplicates stored procedure for PostgreSQL, MySQL and Microsoft SQL Server.
   * For Oracle a direct DELETE statement is executed using ROWID for removing duplicate e-mails.
   * @param oConn Database Connection
   * @return Count of deleted members
   * @throws SQLException If the list type is not STATIC or DIRECT.
   * @throws IllegalStateException is this DistributionList has not been previously loaded
   * @throws UnsupportedOperationException if the underlying RDBMS is not PostgreSQL, MySQL, SQL Server or Oracle.
   * @since 6.0
   */
  public int deleteDuplicates(JDCConnection oConn) throws SQLException,IllegalStateException,UnsupportedOperationException {
  
  	int iDeleted = 0;
  	ResultSet oRSet;
    PreparedStatement oStmt;
    CallableStatement oCall;

    if (isNull(DB.tp_list))
	  throw new IllegalStateException("DistributionList.deleteDuplicates() List must be loaded before attempting to delete duplicates");
    
    if (getShort(DB.tp_list)!=TYPE_STATIC && getShort(DB.tp_list)!=TYPE_DIRECT)
	  throw new SQLException("DistributionList.deleteDuplicates() is only allowed for static or direct lists");
  
	switch (oConn.getDataBaseProduct()) {
	  case JDCConnection.DBMS_POSTGRESQL:
	    oStmt = oConn.prepareStatement("SELECT k_sp_del_duplicates(?)");
	    oStmt.setString(1, getString(DB.gu_list));
	    oRSet = oStmt.executeQuery();
		oRSet.next();
		iDeleted = oRSet.getInt(1);
		oStmt.close();
		break;
	  case JDCConnection.DBMS_MSSQL:
	  case JDCConnection.DBMS_MYSQL:
	  	oCall = oConn.prepareCall("{ call k_sp_del_duplicates(?,?) }");
        oCall.setString(1, getString(DB.gu_list));
        oCall.registerOutParameter(2, java.sql.Types.INTEGER);
        oCall.execute();
        iDeleted = oCall.getInt(2);
        oCall.close();
        break;
      case JDCConnection.DBMS_ORACLE:
	    oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_x_list_members+" WHERE "+DB.gu_list+"=? AND ROWID NOT IN (SELECT MAX(ROWID) FROM "+DB.k_x_list_members+" WHERE "+DB.gu_list+"=? GROUP BY "+DB.tx_email+")");
	    oStmt.setString(1, getString(DB.gu_list));
	    oStmt.setString(2, getString(DB.gu_list));
	    iDeleted = oStmt.executeUpdate();
		oStmt.close();
		break;
	  default:
	    throw new java.lang.UnsupportedOperationException("DistributionList.deleteDuplicates() Unsuppoted RDBMS");
	}
	return iDeleted;
  } // deleteDuplicates

  // ----------------------------------------------------------

  /**
   * Print List Members to a String.
   * @param oConn Database Connection
   * @param bPrintHeader <b>true</b> if column names are to be printed at first row.
   * @return Comma delimited String with one Member per line.
   * @throws SQLException
   */
  public String print(JDCConnection oConn, boolean bPrintHeader) throws SQLException {
    String sSQL;
    String sColumnList;
    String sTableName;
    String sWhere;
    StringBuffer oBuffer;
    Statement oStmt;
    ResultSet oRSet;
    Object oFld;

    // Imprime los miembros de una lista en formato de texto delimitado por comas

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.print([Connection])");
      DebugFile.incIdent();
    }

    oBuffer = new StringBuffer();

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    sColumnList = "m." + DB.tx_email + ",m." + DB.tx_name + ",m." + DB.tx_surname + ",m." + DB.tx_salutation + ",m." + DB.bo_active + ",m." + DB.gu_company + ",m." + DB.gu_contact + ",m." + DB.dt_modified;

    if (getShort(DB.tp_list)==TYPE_DYNAMIC) {
	  String sQrySpec = DBCommand.queryStr(oConn, "SELECT "+DB.nm_queryspec+" FROM "+DB.k_queries+" WHERE "+DB.gu_query+"='"+getStringNull(DB.gu_query,"")+"'");
	  if (null==sQrySpec) sQrySpec = "";

      if (sQrySpec.equals("peticiones"))
        sTableName = "v_oportunity_contact_address";
      else if (sQrySpec.equals("contacts"))
        sTableName = DB.v_contact_address;
      else
        sTableName = DB.k_member_address;

      QueryByForm oQBF = new QueryByForm(oConn, sTableName, "m", getStringNull(DB.gu_query,""));

      sWhere = "m." + DB.gu_workarea + "='" + getString(DB.gu_workarea) + "' AND (" + oQBF.composeSQL() + ")";

      oQBF = null;

    } else {
      sTableName = DB.k_x_list_members;
      sWhere = "m." + DB.gu_list + "='" + getString(DB.gu_list) + "'";
    }

    sSQL = "SELECT " + sColumnList + " FROM " + sTableName + " m WHERE " + sWhere;

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

    oRSet = oStmt.executeQuery(sSQL);

    try { oRSet.setFetchSize(500); }  catch (SQLException sqle) { /* ignore */}

	try {
      if (bPrintHeader) oBuffer.append(Gadgets.replace(sColumnList,"m\\.","") + "\n");
	} catch (Exception mpe) { /* ignore */}

    while (oRSet.next()) {
      oBuffer.append(oRSet.getString(1));
      oBuffer.append(",");

      oFld = oRSet.getObject(2); // tx_name
      if (!oRSet.wasNull()) oBuffer.append(oFld);
      oBuffer.append(",");

      oFld = oRSet.getObject(3); // tx_surname
      if (!oRSet.wasNull()) oBuffer.append(oFld);
      oBuffer.append(",");

      oFld = oRSet.getObject(4); // tx_salutation
      if (!oRSet.wasNull()) oBuffer.append(oFld);
      oBuffer.append(",");

      oBuffer.append(String.valueOf(oRSet.getShort(5)));
      oBuffer.append(",");

      oFld = oRSet.getObject(6); // gu_company
      if (!oRSet.wasNull()) oBuffer.append(oFld);
      oBuffer.append(",");

      oFld = oRSet.getObject(7); // gu_contact
      if (!oRSet.wasNull()) oBuffer.append(oFld);
      oBuffer.append(",");

      oBuffer.append(oRSet.getString(8));
      oBuffer.append("\n");
    } // wend

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.print()");
    }

    return oBuffer.toString();
  } // print()

  // ----------------------------------------------------------

  // **********************************************************
  // Static Methods

  /**
   * Delete Distribution List
   * Call k_sp_del_list stored procedure.<br>
   * Associated Black List (if present) is also deleted.
   * @param oConn Database Connection
   * @param sListGUID GUID of DistributionList to be deleted
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sListGUID) throws SQLException {
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributionList.delete([Connection]," + sListGUID + ")");
      DebugFile.incIdent();
    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      Statement oStmt = oConn.createStatement();
      oStmt.executeQuery("SELECT k_sp_del_list ('" + sListGUID + "')");
      oStmt.close();
      bRetVal = true;
    } else {
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_list ('" + sListGUID + "') }");
      bRetVal = oCall.execute();
      oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributionList.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete()

  // **********************************************************
  // Public Constants

  public static final short ClassId = 96;

  public static final short TYPE_STATIC=(short)1;
  public static final short TYPE_DYNAMIC=(short)2;
  public static final short TYPE_DIRECT=(short)3;
  public static final short TYPE_BLACK=(short)4;
}
