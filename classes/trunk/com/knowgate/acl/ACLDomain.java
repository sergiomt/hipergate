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

package com.knowgate.acl;

import java.io.IOException;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;

import com.knowgate.workareas.WorkArea;
import com.knowgate.hipergate.Category;

/**
 *
 * <p>Security Domain Management Functions</p>
 * @author Sergio Montoro Ten
 * @version 2.1
 */

public final class ACLDomain extends DBPersist {

  /**
   * Default constructor
   */
  public ACLDomain() {
    super(DB.k_domains, "ACLDomain");
  }

  // ----------------------------------------------------------

  /**
   * <p>Constructs ACLDomain and load attributes from k_domains table</p>
   * @param oConn Database Connection
   * @param iIdDomain Domain Identifier (id_domain field at k_domains table)
   * @throws SQLException
   */
  public ACLDomain(JDCConnection oConn, int iIdDomain) throws SQLException {
    super(DB.k_domains, "ACLDomain");

    Object aDom[] = { new Integer(iIdDomain) };

    load (oConn,aDom);
  }

  // ----------------------------------------------------------

  /**
   * @see DBPersist#store(JDCConnection)
   */
  public boolean store(JDCConnection oConn) throws SQLException {

    if (!AllVals.containsKey(DB.id_domain)) {
      put(DB.id_domain, DBBind.nextVal(oConn, "seq_" + DB.k_domains));
    }

    return super.store(oConn);
  } // store

  // ----------------------------------------------------------

  /**
   * @see ACLDomain#delete(JDCConnection,int)
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    try {
      return ACLDomain.delete(oConn, getInt(DB.id_domain));
    } catch (IOException ioe) {
      throw new SQLException ("IOException " + ioe.getMessage());
    }
  }

  /**
   * <p>Fully delete a domain and ALL its associated data</p>
   * <p>This method will perform the following actions<br>
   * 1. Delete WorkAreas from this domain<br>
   * 2. Delete categories owned by users of this domain<br>
   * 3. Delete Security groups from domain<br>
   * 4. Delete domain users<br>
   * @param oConn Database Connection
   * @param iDomainId Domain Identifier
   * @return
   * @throws SQLException
   * @throws IOException
   * @see com.knowgate.acl.ACLUser#delete(JDCConnection,String)
   * @see com.knowgate.hipergate.Category#delete(JDCConnection,String)
   * @see com.knowgate.workareas.WorkArea#delete(JDCConnection,String)
   */
  public static boolean delete(JDCConnection oConn, int iDomainId) throws SQLException,IOException {
    PreparedStatement oStmt;
    DBSubset oWrks, oCats, oGrps, oUsrs;
    int iWrks, iCats, iGrps, iUsrs;
    int iAffected;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACLDomain.delete([Connection], " + String.valueOf(iDomainId) + ")");
      DebugFile.incIdent();
    }

    // Delete workareas associated with domain
    if (DBBind.exists(oConn, DB.k_workareas,"U")) {
      oWrks = new DBSubset(DB.k_workareas, DB.gu_workarea, DB.id_domain + "=" + String.valueOf(iDomainId), 8);
      iWrks = oWrks.load(oConn);

      for (int w=0; w<iWrks; w++)
        WorkArea.delete(oConn, oWrks.getString(0,w));

      oWrks = null;
    } // fi(exists(DB.k_workareas))

	// Delete black lists from this domain
    if (DBBind.exists(oConn, DB.k_global_black_list, "U")) {
      oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_global_black_list + " WHERE " + DB.id_domain + "=?");
      oStmt.setInt(1, iDomainId);
      oStmt.executeUpdate();
      oStmt.close();
    }
	
    // Delete thesauri entries from this domain
    if (DBBind.exists(oConn, DB.k_thesauri, "U")) {

      // Delete synonyms first
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_thesauri + " WHERE " + DB.bo_mainterm + "=0 AND " + DB.gu_rootterm + " IN (SELECT " + DB.gu_rootterm + " FROM " + DB.k_thesauri_root + " WHERE " + DB.id_domain + "=" + String.valueOf(iDomainId) + "))");

      oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_thesauri + " WHERE " + DB.bo_mainterm + "=0 AND " + DB.gu_rootterm + " IN (SELECT " + DB.gu_rootterm + " FROM " + DB.k_thesauri_root + " WHERE " + DB.id_domain + "=?)");
      oStmt.setInt(1, iDomainId);
      oStmt.executeUpdate();
      oStmt.close();

      // Then delete rest of main terms
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_thesauri + " WHERE " + DB.gu_rootterm + " IN (SELECT " + DB.gu_rootterm + " FROM " + DB.k_thesauri_root + " WHERE " + DB.id_domain + "=" + String.valueOf(iDomainId) + "))");

      oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_thesauri + " WHERE " + DB.gu_rootterm + " IN (SELECT " + DB.gu_rootterm + " FROM " + DB.k_thesauri_root + " WHERE " + DB.id_domain + "=?)");
      oStmt.setInt(1, iDomainId);
      oStmt.executeUpdate();
      oStmt.close();

      // Delete root terms
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_thesauri_root + " WHERE " + DB.id_domain + "=?)");

      oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_thesauri_root + " WHERE " + DB.id_domain + "=?");
      oStmt.setInt(1, iDomainId);
      oStmt.executeUpdate();
      oStmt.close();
    }

    // Delete all categories owned by users of this domain
    if (DBBind.exists(oConn, DB.k_categories,"U")) {

      oCats = new DBSubset(DB.k_categories + " c," + DB.k_users + " u" , "c." + DB.gu_category,
                           "u."+ DB.id_domain + "=" + String.valueOf(iDomainId) + " AND c." + DB.gu_owner + "=u." + DB.gu_user, 8);

      iCats = oCats.load(oConn);

      for (int c=0; c<iCats; c++)
        Category.delete(oConn, oCats.getString(0,c));

      oCats = null;
    } // fi(exists(DB.k_categories))

	// New for v4.0, delete events
    if (DBBind.exists(oConn, DB.k_events, "U")) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_events + " WHERE " + DB.id_domain + "="+String.valueOf(iDomainId)+")");
      oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_events + " WHERE " + DB.id_domain + "=?");
      oStmt.setInt(1, iDomainId);
      oStmt.executeUpdate();
      oStmt.close();      
    }
    	
    // Prevent foreign key violations on deleting administrator user and groups
    oStmt = oConn.prepareStatement("UPDATE " + DB.k_domains + " SET " + DB.gu_owner + "=NULL," + DB.gu_admins + "=NULL WHERE " + DB.id_domain + "=?");
    oStmt.setInt(1, iDomainId);
    oStmt.executeUpdate();
    oStmt.close();

    // Delete security groups
    if (DBBind.exists(oConn, DB.k_acl_groups,"U")) {
      oGrps = new DBSubset(DB.k_acl_groups, DB.gu_acl_group, DB.id_domain + "=" + String.valueOf(iDomainId), 8);
      iGrps = oGrps.load(oConn);

      for (int g=0; g<iGrps; g++)
        ACLGroup.delete(oConn, oGrps.getString(0,g));

      oGrps = null;
    } // fi(exists(DB.k_acl_groups))

    // Delete user
    if (DBBind.exists(oConn, DB.k_users,"U")) {

      oUsrs = new DBSubset(DB.k_users, DB.gu_user, DB.id_domain + "=" + String.valueOf(iDomainId), 8);
      iUsrs = oUsrs.load(oConn);

      for (int g=0; g<iUsrs; g++)
        ACLUser.delete(oConn, oUsrs.getString(0,g));

      oUsrs = null;
    } // fi(exists(DB.k_users))

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_domains + " WHERE " + DB.id_domain + "=" + String.valueOf(iDomainId));

    oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_domains + " WHERE " + DB.id_domain + "=?");
    oStmt.setInt(1, iDomainId);
    iAffected = oStmt.executeUpdate();
    oStmt.close();
    oStmt = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ACLDomain.delete() : " + String.valueOf(iAffected>0 ? true : false));
    }

    return iAffected>0 ? true : false;
  } // delete()

  // ----------------------------------------------------------

  /**
   * Get Domain to which a given WorkArea belongs
   * @param oConn JDCConnection
   * @param sWorkAreaId String WorkArea GUID
   * @return Integer Domain Id. or <b>null</b> if no WorkArea with such GUID was found
   * @throws SQLException
   */
  public static Integer forWorkArea(Connection oConn, String sWorkAreaId)
      throws SQLException {

    Integer iDom;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.id_domain+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sWorkAreaId);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      iDom = new Integer(oRSet.getObject(1).toString());
    else
      iDom = null;
    oRSet.close();
    oStmt.close();
    return iDom;
  } // forWorkArea

  // ----------------------------------------------------------

  /**
   * Get Domain to which a given WorkArea belongs
   * @param oConn JDCConnection
   * @param sWorkAreaId String WorkArea GUID
   * @return Integer Domain Id. or <b>null</b> if no WorkArea with such GUID was found
   * @throws SQLException
   */
  public static Integer forWorkArea(JDCConnection oConn, String sWorkAreaId)
    throws SQLException {
    return forWorkArea((Connection) oConn, sWorkAreaId);
  } // forWorkArea

  // ----------------------------------------------------------

  /**
   * <p>Gets domain identifier given its name</p>
   * <p>Calls k_get_domain_id stored procedure and gets id_domaingiven nm_domain
   * @param oConn Database Connection
   * @param sDomainNm Domain name (nm_domain from k_domains table)
   * @return Domain Identifier
   * @throws SQLException
   */
  public static int getIdFromName(JDCConnection oConn, String sDomainNm) throws SQLException {
    CallableStatement oCall;
    PreparedStatement oStmt;
    ResultSet oRSet;
    int iDomainId;

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_MYSQL:
      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_ORACLE:
        oCall = oConn.prepareCall("{call k_get_domain_id (?,?)}");
        oCall.setString(1, sDomainNm);
        oCall.registerOutParameter(2, java.sql.Types.INTEGER);
        oCall.execute();
        iDomainId = oCall.getInt(2);
        oCall.close();
        oCall = null;
        break;

      default:
        oStmt = oConn.prepareStatement("SELECT " + DB.id_domain + " FROM " + DB.k_domains + " WHERE " + DB.nm_domain + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sDomainNm);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          iDomainId = oRSet.getInt(1);
        else
          iDomainId = 0;
        oRSet.close();
        oStmt.close();
    } // end switch()

    return iDomainId;
  }

  // ---------------------------------------------------------------------------

  private static void printUsage() {
    System.out.println("");
    System.out.println("Usage:");
    System.out.println("ACLDomain list emails id_domain");
  }

  public static void main(String[] argv)
      throws SQLException, NumberFormatException {

    if (argv.length!=3) {
      printUsage();
    }
    else if (!argv[1].equalsIgnoreCase("list") || !argv[1].equalsIgnoreCase("emails")) {
      printUsage();
    }
    else {
      DBBind oDBB = new DBBind();
      JDCConnection oCon = oDBB.getConnection("ACLDomain_main");
      Statement oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      ResultSet oRst = oStm.executeQuery("SELECT " + DB.tx_main_email + " FROM " + DB.k_users + " WHERE " + DB.id_domain + "=" + argv[2] + " AND " + DB.bo_active + "<>0");

      while (oRst.next()) {
        System.out.println(oRst.getString(1));
      } // wend

      oRst.close();
      oStm.close();
      oCon.close("ACLDomain_main");

      oDBB.connectionPool().close();
      oDBB = null;
    }
  } // main

  // ---------------------------------------------------------------------------

  public static final short ClassId = 1;

} // ACLDomain
