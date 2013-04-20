/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

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

package com.knowgate.workareas;

import java.io.IOException;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import java.util.Locale;
import java.util.WeakHashMap;

import java.text.DateFormat;
import java.text.SimpleDateFormat;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.*;

import com.knowgate.addrbook.Room;
import com.knowgate.addrbook.Meeting;
import com.knowgate.addrbook.Fellow;

import com.knowgate.crm.Company;
import com.knowgate.crm.Contact;
import com.knowgate.crm.Supplier;
import com.knowgate.crm.DistributionList;

import com.knowgate.projtrack.Project;

import com.knowgate.dataxslt.db.*;

import com.knowgate.hipermail.AdHocMailing;

import com.knowgate.hipergate.Image;
import com.knowgate.hipergate.QueryByForm;
import com.knowgate.hipergate.Shop;

import com.knowgate.scheduler.Job;

/**
 * <p>WorkArea</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
@SuppressWarnings("serial")
public class WorkArea extends DBPersist {

  private static WeakHashMap oParams;

  /**
   * Create empty WorkArea.
   */
  public WorkArea() {
    super(DB.k_workareas, "WorkArea");
    oParams = new WeakHashMap();
  }

  // ----------------------------------------------------------

  /**
   * Load WorkArea from database
   * @param oConn Database Conenction
   * @param sIdWorkArea GUID of WorkArea to be loaded
   * @throws SQLException
   */
  public WorkArea(JDCConnection oConn, String sIdWorkArea) throws SQLException {
    super(DB.k_workareas, "WorkArea");

    oParams = new WeakHashMap();

    Object aWrkA[] = { sIdWorkArea };

    load (oConn,aWrkA);
  }

  // ----------------------------------------------------------

  /**
   * <p>Delete a WorkArea and all its associated data.</p>
   * USE THIS METHOD WITH EXTREME CARE. AS IT WILL DELETE DATA FROM EVERY TABLE
   * CONTAINING A gu_workarea COLUMN MATCHING THE DELETED WORKAREA GUID.<br><br>
   * Deletion takes place by delegating it in other objects delete() method.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    return WorkArea.delete(oConn, getString(DB.gu_workarea));
  }

  // ----------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException {

	if (null!=oParams) oParams.clear();

    // Si no se especificó un identificador para el área de trabajo
    // entonces añadirlo autimaticamente
    if (!AllVals.containsKey(DB.gu_workarea))
      put(DB.gu_workarea, Gadgets.generateUUID());

    return super.store(oConn);
  }

  // ----------------------------------------------------------

  public int getUserAppMask(JDCConnection oConn, String sUserId) throws SQLException {
    return WorkArea.getUserAppMask(oConn, getString(DB.gu_workarea), sUserId);
  }

  // ----------------------------------------------------------

  /**
   * <p>Users that may have access to this WorkArea</p>
   * Get a list of users that have any kind of access to this WorkArea.
   * The list is taken by querying k_x_group_user table looking for users
   * that belong to any of the five permissions groups of the WorkArea
   * {admins,powusers,users,guests,other}
   * @return A DBSubset with columns gu_user,tx_nickname,nm_user,tx_surname1,tx_surname2,bo_searchable,tx_main_email
   * @throws SQLException
   */
  public DBSubset getUsers(JDCConnection oConn) throws SQLException {
    Object oGroups[] = { get(DB.gu_admins), get(DB.gu_powusers), get(DB.gu_users), get(DB.gu_guests), get(DB.gu_other) };
    DBSubset oUsers = new DBSubset(DB.k_users + " u",
                                   "u." + DB.gu_user +",u." + DB.tx_nickname + ",u." + DB.nm_user + ",u." + DB.tx_surname1 + ",u." + DB.tx_surname2 + ",u." + DB.bo_searchable + ",u." + DB.tx_main_email,
                                   "EXISTS (SELECT x." + DB.gu_user + " FROM " + DB.k_x_group_user + " x WHERE " + DB.gu_user + "=u." + DB.gu_user + " AND x." + DB.gu_acl_group + " IN (?,?,?,?,?)) ORDER BY 3,4,5", 4);
    oUsers.load(oConn, oGroups);

    return oUsers;
  }

  // **********************************************************
  // Static Methods

  /**
   * <p>Delete a WorkArea and all its associated data.</p>
   * USE THIS METHOD WITH EXTREME CARE. AS IT WILL DELETE DATA FROM EVERY TABLE
   * CONTAINING A gu_workarea COLUMN MATCHING THE DELETED WORKAREA GUID.<br><br>
   * Deletion takes place by delegating it in other objects delete() method.<br><br>
   * In this order:<br>
   * <table border=1 cellpadding=4>
   * <tr><td>k_activities</td></tr>
   * <tr><td>k_x_activity_audience</td></tr>
   * <tr><td>DELETE k_sms_audit</td></tr>
   * <tr><td>DELETE k_sms_audit</td></tr>
   * <tr><td>DELETE k_syndentries</td></tr>
   * <tr><td>DELETE k_x_portlet_user</td></tr>
   * <tr><td>QueryByForm.delete</td></tr>
   * <tr><td>MicrositeDB.delete</td></tr>
   * <tr><td>PageSetDB.delete</td></tr>
   * <tr><td>DELETE k_images</td></tr>
   * <tr><td>DELETE k_global_black_list</td></tr>
   * <tr><td>DistributionList.delete</td></tr>
   * <tr><td>Meeting.delete</td></tr>
   * <tr><td>Fellow.delete</td></tr>
   * <tr><td>DELETE k_lu_fellow_titles</td></tr>
   * <tr><td>DELETE k_fellows_lookup</td></tr>
   * <tr><td>Room.delete</td></tr><tr>
   * <tr><td>DELETE k_rooms_lookup</td></tr>
   * <tr><td>DELETE k_to_do</td></tr>
   * <tr><td>DELETE k_to_do_lookup</td></tr>
   * <tr><td>DELETE k_phone_calls</td></tr>
   * <tr><td>DELETE k_sales_men</td></tr>
   * <tr><td>DELETE k_sales_men_lookup</td></tr>
   * <tr><td>DELETE k_bulkloads</td></tr>
   * <tr><td>Supplier.delete</td></tr>
   * <tr><td>Company.delete</td></tr>
   * <tr><td>DELETE k_companies_lookup</td></tr>
   * <tr><td>DELETE k_contacts_lookup</td></tr>
   * <tr><td>DELETE k_oportunities_lookup</td></tr>
   * <tr><td>DELETE k_welcome_packs_lookup</td></tr>
   * <tr><td>Project.delete</td></tr>
   * <tr><td>DELETE k_projects_lookup</td></tr>
   * <tr><td>DELETE k_duties_lookup </td></tr>
   * <tr><td>DELETE k_bugs_lookup </td></tr>
   * <tr><td>DELETE k_invoices</td></tr>
   * <tr><td>DELETE k_invoice_lines</td></tr>
   * <tr><td>DELETE k_invoices_lookup</td></tr>
   * <tr><td>DELETE k_invoices_next</td></tr>
   * <tr><td>DELETE k_returned_invoices</td></tr>
   * <tr><td>DELETE k_x_order_invoices</td></tr>
   * <tr><td>DELETE k_despatch_advices</td></tr>
   * <tr><td>DELETE k_despatch_lines</td></tr>
   * <tr><td>DELETE k_despatch_advices_lookup</td></tr>
   * <tr><td>DELETE k_x_orders_despatch</td></tr>
   * <tr><td>DELETE k_despatch_next</td></tr>
   * <tr><td>DELETE k_orders</td></tr>
   * <tr><td>DELETE k_order_lines</td></tr>
   * <tr><td>DELETE k_orders_lookup</td></tr>
   * <tr><td>DELETE k_quotations</td></tr>
   * <tr><td>DELETE k_quotation_lines</td></tr>
   * <tr><td>DELETE k_x_quotations_orders</td></tr>
   * <tr><td>DELETE k_quotation_next</td></tr>
   * <tr><td>DELETE k_warehouses</td></tr>
   * <tr><td>DELETE k_sale_points</td></tr>
   * <tr><td>DELETE k_lu_business_states</td></tr>
   * <tr><td>DELETE k_business_states</td></tr>
   * <tr><td>Shop.delete</td></tr>
   * <tr><td>DELETE k_events</td></tr>
   * <tr><td>Job.delete</td></tr>
   * <tr><td>DELETE k_lu_meta_attrs</td></tr>
   * <tr><td>DELETE k_addresses</td></tr>
   * <tr><td>DELETE k_addresses_lookup</td></tr>
   * <tr><td>DELETE k_thesauri_lookup</td></tr>
   * <tr><td>DELETE k_bank_accounts</td></tr>
   * <tr><td>DELETE k_bank_accounts_lookup</td></tr>
   * <tr><td>DELETE k_urls</td></tr>
   * <tr><td>DELETE k_x_app_workarea</td></tr>
   * <tr><td>DELETE k_workareas</td></tr>
   * </table>
   * @param oConn Database Connection
   * @param sWrkAreaGUID GUID of WorkArea to be deleted.
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sWrkAreaGUID) throws SQLException {
    CallableStatement oCall;
    Statement oStmt;
    PreparedStatement oPtmt;
    ResultSet oRSet;
    DBSubset oItems;
    String sSQL;
    int iItems;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.delete([Connection], " + sWrkAreaGUID + ")");
      DebugFile.incIdent();
    }

	if (null!=oParams) oParams.clear();

    // -----------------------------------------------------------------------------------
    // Verificar que la WorkArea realmente existe antes de empezar a borrar y tambien
    // evitar que una inyección maliciosa de SQL en el parámetro sWrkAreaGUID pudiera
    // borrar más registros de los debidos

    oPtmt = oConn.prepareStatement("SELECT "+DB.gu_workarea+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"=?",
                                   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oPtmt.setString(1, sWrkAreaGUID);
    oRSet = oPtmt.executeQuery();
    boolean bExists = oRSet.next();
    oRSet.close();
    oPtmt.close();

    if (!bExists) {
      if (DebugFile.trace) {
        DebugFile.writeln("workarea " + sWrkAreaGUID + " not found");
        DebugFile.decIdent();
        DebugFile.writeln("End WorkArea.delete() : false");
      }
      return false;
    }

    // -----------------------------------------------------------------------------------
    // Nuevo para v6.0
    // Borrar las entradas de feeds RSS

    if (DBBind.exists(oConn, DB.k_syndentries, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_syndentries + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_syndentries + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'");
    
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Nuevo para v5.0
    // Borrar las actividades

    if (DBBind.exists(oConn, DB.k_activities, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_activity_audience + " WHERE " + DB.gu_activity + " IN (SELECT " + DB.gu_activity +" FROM " + DB.k_activities+ " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'))");

      oStmt.executeUpdate("DELETE FROM " + DB.k_x_activity_audience + " WHERE " + DB.gu_activity + " IN (SELECT " + DB.gu_activity +" FROM " + DB.k_activities+ " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')");
    
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_activities + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_activities + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'");
    
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Nuevo para v5.0
    // Borrar los SMS

    if (DBBind.exists(oConn, DB.k_sms_audit, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_sms_audit + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_sms_audit + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'");
    
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar los e-mails

	if (DBBind.exists(oConn, DB.k_adhoc_mailings, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_adhoc_mailings_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "')");
      oStmt.executeUpdate("DELETE FROM " + DB.k_adhoc_mailings_lookup + " WHERE  " + DB.gu_owner + "='" + sWrkAreaGUID + "'");
      oStmt.close();
      DBSubset oMailings = new DBSubset(DB.k_adhoc_mailings, DB.gu_mailing, DB.gu_workarea+"=?", 1000);
      int iMailings = oMailings.load(oConn, new Object[]{sWrkAreaGUID});
      AdHocMailing oAdhc = new AdHocMailing();
      for (int m=0; m<iMailings; m++) {
      	oAdhc.load(oConn, new Object[]{oMailings.getString(DB.gu_mailing,m)});
      	oAdhc.delete(oConn);
      } // next
	} // fi

    if (DBBind.exists(oConn, DB.k_mime_msgs, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + " IN (SELECT " + DB.gu_mimemsg + " FROM k_mime_msgs WHERE gu_workarea='" + sWrkAreaGUID + "') AND " + DB.id_class + "=822)");

      oStmt.executeUpdate("DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + " IN (SELECT " + DB.gu_mimemsg + " FROM k_mime_msgs WHERE gu_workarea='" + sWrkAreaGUID + "') AND " + DB.id_class + "=822");

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_inet_addrs + " WHERE " + DB.gu_mimemsg + " IN (SELECT " + DB.gu_mimemsg + " FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'))");

      oStmt.executeUpdate("DELETE FROM " + DB.k_inet_addrs + " WHERE " + DB.gu_mimemsg + " IN (SELECT " + DB.gu_mimemsg + " FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')");

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + " IN (SELECT " + DB.gu_mimemsg + " FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'))");

      oStmt.executeUpdate("DELETE FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + " IN (SELECT " + DB.gu_mimemsg + " FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')");

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_mime_msgs + " WHERE  " + DB.gu_workarea + "='" + sWrkAreaGUID + "'");

      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar las preferencias de usuario para portlets

    if (DBBind.exists(oConn, DB.k_x_portlet_user, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_portlet_user + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_x_portlet_user + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'");

      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar las consultas

    if (DBBind.exists(oConn, DB.k_queries, "U")) {
      oItems = new DBSubset (DB.k_queries, DB.gu_query, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);

      for (int p=0;p<iItems; p++)
        QueryByForm.delete(oConn, oItems.getString(0, p));
    }
    // -----------------------------------------------------------------------------------

    // Borrar los pagesets
    if (DBBind.exists(oConn, DB.k_pagesets, "U")) {
      oItems = new DBSubset (DB.k_pagesets, DB.gu_pageset, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int p=0;p<iItems; p++)
        PageSetDB.delete(oConn, oItems.getString(0,p));
    }

    // -----------------------------------------------------------------------------------

    // Borrar los microsites
    if (DBBind.exists(oConn, DB.k_microsites, "U")) {
      oItems = new DBSubset (DB.k_microsites, DB.gu_microsite, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int p=0;p<iItems; p++)
        new MicrositeDB(oConn, oItems.getString(0,p)).delete(oConn);
    }

    // -----------------------------------------------------------------------------------
    // Nuevo para la v2.1
    // Borrar las imagenes

    if (DBBind.exists(oConn, DB.k_images, "U")) {
      oItems = new DBSubset (DB.k_images, DB.gu_image, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int p=0;p<iItems; p++)
        new Image(oConn, oItems.getString(0,p)).delete(oConn);
    }

    // -----------------------------------------------------------------------------------
    // Borrar las listas

    if (DBBind.exists(oConn, DB.k_global_black_list, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_global_black_list + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')");
      oStmt.executeUpdate("DELETE FROM " + DB.k_global_black_list + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'");
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_lists, "U")) {
      oItems = new DBSubset (DB.k_lists, DB.gu_list, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int p=0;p<iItems; p++)
        DistributionList.delete(oConn, oItems.getString(0,p));
    }
    // -----------------------------------------------------------------------------------

    // Borrar actividades, compañeros y salas

    if (DBBind.exists(oConn, DB.k_meetings, "U")) {
      oItems = new DBSubset (DB.k_meetings, DB.gu_meeting, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int c=0;c<iItems; c++)
        Meeting.delete(oConn, oItems.getString(0,c));
    }

    if (DBBind.exists(oConn, DB.k_fellows, "U")) {
      oItems = new DBSubset (DB.k_fellows, DB.gu_fellow, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int c=0;c<iItems; c++)
        Fellow.delete(oConn, oItems.getString(0,c));
    }

    if (DBBind.exists(oConn, DB.k_lu_fellow_titles, "U")) {
      oStmt = oConn.createStatement();
      sSQL = "DELETE FROM " + DB.k_lu_fellow_titles + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_fellows_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_fellows_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_rooms, "U")) {
      oItems = new DBSubset (DB.k_rooms, DB.nm_room, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int c=0;c<iItems; c++)
        Room.delete(oConn, oItems.getString(0,c), sWrkAreaGUID);
    }

    if (DBBind.exists(oConn, DB.k_rooms_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_rooms_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar ToDo Lists

    if (DBBind.exists(oConn, DB.k_to_do, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_to_do + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_to_do_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_to_do_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar llamadas de teléfono

    if (DBBind.exists(oConn, DB.k_phone_calls, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_phone_calls + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar el datawarehouse de direcciones

    if (DBBind.exists(oConn, DB.k_member_address, "U")) {

      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

      sSQL = "DELETE FROM " + DB.k_member_address + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);

      oStmt.close();
    }

    // -----------------------------------------------------------------------------------

    // Borrar los Vendedores
    if (DBBind.exists(oConn, DB.k_sales_men, "U")) {
      oItems = new DBSubset (DB.k_sales_men, DB.gu_sales_man, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT k_sp_del_sales_man (?))");
         oPtmt = oConn.prepareStatement("SELECT k_sp_del_sales_man (?)");
         for (int c=0;c<iItems; c++) {
           oPtmt.setString(1, oItems.getString(0,c));
           oPtmt.executeQuery();
         } // next
         oPtmt.close();
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_sales_man (?) })");
         oCall = oConn.prepareCall("{call k_sp_del_sales_man (?)}");
         for (int c=0;c<iItems; c++) {
           oCall.setString(1, oItems.getString(0,c));
           oCall.execute();
         } // next
         oCall.close();
      }
    } // fi (DBMS_POSTGRESQL)

    if (DBBind.exists(oConn, DB.k_sales_men_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_sales_men_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Nuevo para la v5.5, borrar los lotes de carga
    if (DBBind.exists(oConn, DB.k_bulkloads, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_bulkloads + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }    
    	
    // -----------------------------------------------------------------------------------
    // Nuevo para la v4.0, borrar los proveedores
    if (DBBind.exists(oConn, DB.k_suppliers, "U")) {
      oItems = new DBSubset (DB.k_suppliers, DB.gu_supplier, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int c=0;c<iItems; c++)
        Supplier.delete(oConn, oItems.getString(0,c));
    }


    // -----------------------------------------------------------------------------------
    // Borrar las compañías, cada compañía borrará en cascada sus individuos asociados

    if (DBBind.exists(oConn, DB.k_companies, "U")) {
      oItems = new DBSubset (DB.k_companies, DB.gu_company, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int c=0;c<iItems; c++)
        Company.delete(oConn, oItems.getString(0,c));
    }

    // Borrar los contactos, puede haber contactos individuales no asociados a ninguna compañia
    if (DBBind.exists(oConn, DB.k_contacts, "U")) {
      oItems = new DBSubset (DB.k_contacts, DB.gu_contact, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int c=0;c<iItems; c++)
        Contact.delete(oConn, oItems.getString(0,c));
    }

    if (DBBind.exists(oConn, DB.k_companies_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_companies_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_contacts_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_contacts_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_oportunities_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_oportunities_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_welcome_packs_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_welcome_packs_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------

    // Borrar los proyectos, cada proyecto borrará en cascada sus incidencias y tareas
    if (DBBind.exists(oConn, DB.k_projects, "U")) {
      oItems = new DBSubset (DB.k_projects, DB.gu_project, DB.gu_owner + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int p=0;p<iItems; p++)
        Project.delete(oConn, oItems.getString(0,p));
    }

    if (DBBind.exists(oConn, DB.k_projects_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_projects_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_duties_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_duties_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_bugs_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_bugs_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar las tiendas, cada tienda borrará en cascada sus categorías y productos

    if (DBBind.exists(oConn, DB.k_invoices, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

      sSQL = "DELETE FROM " + DB.k_x_orders_invoices + " WHERE " + DB.gu_order + " IN (SELECT "+DB.gu_order+" FROM "+DB.k_orders+" WHERE "+DB.gu_workarea+"='"+sWrkAreaGUID + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_invoice_lines + " WHERE " + DB.gu_invoice + " IN (SELECT "+DB.gu_invoice+" FROM "+DB.k_invoices+" WHERE "+DB.gu_workarea+"='"+sWrkAreaGUID + "') OR "+DB.gu_invoice+" IN (SELECT "+DB.gu_invoice+" FROM "+DB.k_returned_invoices+" WHERE "+DB.gu_workarea+"='"+sWrkAreaGUID + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_invoice_schedules + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_invoices + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_invoices_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_invoices_next, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_invoices_next + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_despatch_advices, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

      sSQL = "DELETE FROM " + DB.k_x_orders_despatch + " WHERE " + DB.gu_despatch + " IN (SELECT "+DB.gu_despatch+" FROM "+DB.k_despatch_advices+" WHERE "+DB.gu_workarea+"='"+sWrkAreaGUID + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_despatch_lines + " WHERE " + DB.gu_despatch + " IN (SELECT "+DB.gu_despatch+" FROM "+DB.k_despatch_advices+" WHERE "+DB.gu_workarea+"='"+sWrkAreaGUID + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_despatch_advices + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_despatch_advices_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_despatch_next, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_despatch_next + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_orders, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

      sSQL = "DELETE FROM " + DB.k_order_lines + " WHERE " + DB.gu_order + " IN (SELECT "+DB.gu_order+" FROM "+DB.k_orders+" WHERE "+DB.gu_workarea+"='"+sWrkAreaGUID + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_orders + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_orders_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    //-------------------
	// Nuevo para la v5.0

    if (DBBind.exists(oConn, DB.k_quotations, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

	  DBSubset oPagSets = new DBSubset(DB.k_quotations, DB.gu_pageset, DB.gu_workarea+"=? AND "+DB.gu_pageset+" IS NOT NULL", 100);
	  int nPagSets = oPagSets.load(oConn, new Object[]{sWrkAreaGUID});
	  for (int p=0; p<nPagSets; p++) PageSetDB.delete(oConn, oPagSets.getString(0,p));

      sSQL = "DELETE FROM " + DB.k_x_quotations_orders + " WHERE " + DB.gu_quotation + " IN (SELECT "+DB.gu_quotation+" FROM "+DB.k_quotations+" WHERE "+DB.gu_workarea+"='"+sWrkAreaGUID + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_quotation_lines + " WHERE " + DB.gu_quotation + " IN (SELECT "+DB.gu_quotation+" FROM "+DB.k_quotations+" WHERE "+DB.gu_workarea+"='"+sWrkAreaGUID + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_quotations + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_quotations_next + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
    }

    //-------------------
	// Nuevo para la v4.0

	if (DBBind.exists(oConn, DB.k_warehouses, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

      sSQL = "DELETE FROM " + DB.k_warehouses + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      oStmt.close();
	}

	if (DBBind.exists(oConn, DB.k_sale_points, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

      sSQL = "DELETE FROM " + DB.k_sale_points + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      oStmt.close();
	}

	// Fin nuevo para la v4.0
	
    if (DBBind.exists(oConn, DB.k_business_states, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

      sSQL = "DELETE FROM " + DB.k_business_states + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      sSQL = "DELETE FROM " + DB.k_lu_business_states + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_shops, "U")) {
      oItems = new DBSubset (DB.k_shops, DB.gu_shop, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int s=0;s<iItems; s++)
        new Shop(oConn, oItems.getString(0,s)).delete(oConn);
    }

    // -----------------------------------------------------------------------------------
    // Nuevos para la v4.0, borrar los eventos

    if (DBBind.exists(oConn, DB.k_events, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_events + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      oStmt.close();
    }


    // -----------------------------------------------------------------------------------
    // Borrar los jobs

    if (DBBind.exists(oConn, DB.k_jobs, "U")) {
      oItems = new DBSubset (DB.k_jobs, DB.gu_job, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      for (int s=0;s<iItems; s++)
        Job.delete(oConn, oItems.getString(0,s));
    }

    // -----------------------------------------------------------------------------------
    // Borrar los eventos

    if (DBBind.exists(oConn, DB.k_events, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_events + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------

    // Borrar campos definidos por los usuarios
    if (DBBind.exists(oConn, DB.k_lu_meta_attrs, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_lu_meta_attrs + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar las direcciones

    oStmt = oConn.createStatement();
    try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

    sSQL = "UPDATE " + DB.k_orders + " SET " + DB.gu_ship_addr + "=NULL WHERE " + DB.gu_ship_addr + " IN (SELECT " + DB.gu_address + " FROM " + DB.k_addresses + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')";
    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
    oStmt.execute(sSQL);

    sSQL = "UPDATE " + DB.k_orders + " SET " + DB.gu_bill_addr + "=NULL WHERE " + DB.gu_bill_addr + " IN (SELECT " + DB.gu_address + " FROM " + DB.k_addresses + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')";
    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
    oStmt.execute(sSQL);

    sSQL = "DELETE FROM " + DB.k_x_contact_addr + " WHERE " + DB.gu_address + " IN (SELECT " + DB.gu_address + " FROM " + DB.k_addresses + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')";
    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
    oStmt.execute(sSQL);

    sSQL = "DELETE FROM " + DB.k_x_company_addr + " WHERE " + DB.gu_address + " IN (SELECT " + DB.gu_address + " FROM " + DB.k_addresses + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')";
    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
    oStmt.execute(sSQL);

    sSQL = "DELETE FROM " + DB.k_addresses + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
    oStmt.execute(sSQL);

    sSQL = "DELETE FROM " + DB.k_addresses_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
    oStmt.execute(sSQL);

    oStmt.close();

    // -----------------------------------------------------------------------------------

    // Borrar las entradas del tesauro
    if (DBBind.exists(oConn, DB.k_thesauri, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

      // Primero los sinonimos
      sSQL = "DELETE FROM " + DB.k_thesauri + " WHERE " + DB.bo_mainterm + "=0 AND " + DB.gu_rootterm + " IN (SELECT " + DB.gu_rootterm + " FROM " + DB.k_thesauri_root + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')";

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);

      // Luego los términos principales
      sSQL = "DELETE FROM " + DB.k_thesauri + " WHERE " + DB.gu_rootterm + " IN (SELECT " + DB.gu_rootterm + " FROM " + DB.k_thesauri_root + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "')";

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);

      // Finalmente los terminos raiz
      sSQL = "DELETE FROM " + DB.k_thesauri_root + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);

      oStmt.close();
    }

    // Borrar los lookups del tesauro
    if (DBBind.exists(oConn, DB.k_thesauri_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_thesauri_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar las cuentas bancarias

    if (DBBind.exists(oConn, DB.k_bank_accounts, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_bank_accounts + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_bank_accounts_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_bank_accounts_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    // -----------------------------------------------------------------------------------
    // Borrar los cursos
    // nuevo v2.2

    if (DBBind.exists(oConn, DB.k_absentisms_lookup, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_absentisms_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_subjects, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_subjects_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      sSQL = "DELETE FROM " + DB.k_subjects + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_courses, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_courses_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      oStmt.close();

      oItems = new DBSubset (DB.k_courses, DB.gu_course, DB.gu_workarea + "='" + sWrkAreaGUID + "'", 100);
      iItems = oItems.load(oConn);
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oPtmt = oConn.prepareStatement("SELECT k_sp_del_course(?)");
        for (int c=0; c<iItems; c++) {
          oPtmt.setString(1, oItems.getString(0,c));
          oPtmt.executeQuery();
        }
        oPtmt.close();
      }
      else {
        oCall = oConn.prepareCall("{call k_sp_del_course (?)}");
       for (int c=0;c<iItems; c++) {
         oCall.setString(1, oItems.getString(0,c));
         oCall.execute();
       }
       oCall.close();
      } // fi (DBMS_POSTGRESQL)
    } // fi (exists(DB.k_courses))

    if (DBBind.exists(oConn, DB.k_education_institutions, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_education_institutions + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      oStmt.close();    	
	}

    if (DBBind.exists(oConn, DB.k_education_degree, "U")) {
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_education_degree + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);   	
      sSQL = "DELETE FROM " + DB.k_education_degree_lookup + " WHERE " + DB.gu_owner + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      oStmt.close();    	
	}

    // Borrar las campañas
    // Nuevo para la v4.0 
    if (DBBind.exists(oConn, DB.k_campaigns, "U")) {
      
      // Los registros de la tabla k_x_campaign_lists no es preciso eliminarlos aquí
      // porque ya habrán sido eliminados en la llamada al método DistributionList.delete()
	  // Las oportunidades asociadas a la campaña tampoco es preciso borrarlas aquí
	  // puesto que ya han sido eliminadas como efecto lateral de eliminar los contactos

      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_campaign_targets + " WHERE " + DB.gu_campaign + " IN (SELECT "+DB.gu_campaign+" FROM "+DB.k_campaigns+" WHERE "+DB.gu_workarea+"='"+sWrkAreaGUID+"')";
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      oStmt.close();
      
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_campaigns + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      oStmt.close();	  
    }

    // Borrar las URLs
    // Nuevo para la 5.5
    if (DBBind.exists(oConn, DB.k_urls, "U")) {
            
      oStmt = oConn.createStatement();
      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}
      sSQL = "DELETE FROM " + DB.k_urls + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      oStmt.close();
    }
    
    // -----------------------------------------------------------------------------------
    // Borrar la workarea en si misma
    oStmt = oConn.createStatement();
    try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(30); } catch (SQLException sqle) {}

    sSQL = "DELETE FROM " + DB.k_x_app_workarea + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
    oStmt.executeUpdate(sSQL);

    sSQL = "DELETE FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'";
    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
    oStmt.executeUpdate(sSQL);
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.delete() : true");
    }

    return true;
  } // delete()

  // ----------------------------------------------------------

  /**
   * Whether all capitals mode is activated for this WorkArea or not
   * @since 4.0
   */
  public boolean allCaps() {
	if (isNull(DB.bo_allcaps))
	  return false;
	else
	  return getShort(DB.bo_allcaps) != (short) 0;
  }

  // ----------------------------------------------------------

  /**
   * Whether all capitals mode is activated for this WorkArea or not
   * @since 4.0
   */
  public boolean allowDuplicatedIdentityDocuments() {
	if (isNull(DB.bo_dup_id_docs))
	  return true;
	else
	  return getShort(DB.bo_dup_id_docs) != (short) 0;
  }

  // ----------------------------------------------------------

  /**
   * Whether autonumeric contact references must be generated
   * @since 4.0
   */
  public boolean autoNumericContactReferences() {
	if (isNull(DB.bo_cnt_autoref))
	  return false;
	else
	  return getShort(DB.bo_cnt_autoref) != (short) 0;
  }

  // ----------------------------------------------------------

  /**
   * Whether all capitals mode is activated for a WorkArea or not
   * @param oConn Connection
   * @param sWorkArea String WorkArea GUID
   * @throws SQLException
   * @since 4.0
   */
  public static boolean allCaps(Connection oConn, String sWorkArea) throws SQLException {
	String sKey = sWorkArea+":"+DB.bo_allcaps;
	if (oParams==null) oParams = new WeakHashMap();
	if (oParams.containsKey(sKey)) {
	  return ((Boolean) oParams.get(sKey)).booleanValue();
	} else {
      Short oAllCaps = DBCommand.queryShort(oConn, "SELECT "+DB.bo_allcaps+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"='"+sWorkArea+"'");
	  if (oAllCaps==null) {
	  	oParams.put(sKey, new Boolean(false));
	    return false;
	  }
	  else if (oAllCaps.shortValue()!=(short)0) {
	  	oParams.put(sKey, new Boolean(true));
		return true;
	  } else {
	  	oParams.put(sKey, new Boolean(false));
		return false;
	  }
    } 
  } // allCaps

  // ----------------------------------------------------------

  /**
   * Whether duplicated identity documents are allowed for a WorkArea or not
   * @param oConn Connection
   * @param sWorkArea String WorkArea GUID
   * @throws SQLException
   * @since 4.0
   */
  public static boolean allowDuplicatedIdentityDocuments(Connection oConn, String sWorkArea) throws SQLException {
	String sKey = sWorkArea+":"+DB.bo_dup_id_docs;
	if (oParams==null) oParams = new WeakHashMap();
	if (oParams.containsKey(sKey)) {
	  return ((Boolean) oParams.get(sKey)).booleanValue();
	} else {
      Short oAllCaps = DBCommand.queryShort(oConn, "SELECT "+DB.bo_dup_id_docs+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"='"+sWorkArea+"'");
	  if (oAllCaps==null) {
	  	oParams.put(sKey, new Boolean(true));
	    return true;
	  }
	  else if (oAllCaps.shortValue()!=(short)0) {
	  	oParams.put(sKey, new Boolean(true));
		return true;
	  } else {
	  	oParams.put(sKey, new Boolean(false));
		return false;
	  }
    } 
  } // allowDuplicatedIdentityDocuments

  // ----------------------------------------------------------

  /**
   * Whether autonumeric contact references are generated for a WorkArea or not
   * @param oConn Connection
   * @param sWorkArea String WorkArea GUID
   * @throws SQLException
   * @since 4.0
   */
  public static boolean autoNumericContactReferences(Connection oConn, String sWorkArea) throws SQLException {
	String sKey = sWorkArea+":"+DB.bo_cnt_autoref;
	if (oParams==null) oParams = new WeakHashMap();
	if (oParams.containsKey(sKey)) {
	  return ((Boolean) oParams.get(sKey)).booleanValue();
	} else {
      Short oAllCaps = DBCommand.queryShort(oConn, "SELECT "+DB.bo_cnt_autoref+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"='"+sWorkArea+"'");
	  if (oAllCaps==null) {
	  	oParams.put(sKey, new Boolean(false));
	    return false;
	  }
	  else if (oAllCaps.shortValue()!=(short)0) {
	  	oParams.put(sKey, new Boolean(true));
		return true;
	  } else {
	  	oParams.put(sKey, new Boolean(false));
		return false;
	  }
    } 
  } // autoNumericContactReferences

  // ----------------------------------------------------------

  /**
   * Whether academic courses must be added to objetives lookup of opportunities
   * @param oConn Connection
   * @param sWorkArea String WorkArea GUID
   * @throws SQLException
   * @since 7.0
   */
  public static boolean saveAcademicCoursesAsOportunityObjetives(Connection oConn, String sWorkArea) throws SQLException {
	String sKey = sWorkArea+":"+DB.bo_acrs_oprt;
	if (oParams==null) oParams = new WeakHashMap();
	if (oParams.containsKey(sKey)) {
	  return ((Boolean) oParams.get(sKey)).booleanValue();
	} else {
      Short oAcrsOprt = DBCommand.queryShort(oConn, "SELECT "+DB.bo_acrs_oprt+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"='"+sWorkArea+"'");
	  if (oAcrsOprt==null) {
	  	oParams.put(sKey, new Boolean(false));
	    return false;
	  }
	  else if (oAcrsOprt.shortValue()!=(short)0) {
	  	oParams.put(sKey, new Boolean(true));
		return true;
	  } else {
	  	oParams.put(sKey, new Boolean(false));
		return false;
	  }
    } 
  } // saveAcademicCoursesAsOportunityObjetives
  
  // ----------------------------------------------------------

  /**
   * <p>Delete a WorkArea, its associated data and working directories.</p>
   * USE THIS METHOD WITH EXTREME CARE. AS IT WILL DELETE DATA FROM EVERY TABLE
   * CONTAINING A gu_workarea COLUMN MATCHING THE DELETED WORKAREA GUID.<br><br>
   * @param oConn Database Connection
   * @param sWrkAreaGUID GUID of WorkArea to be deleted
   * @param oProps Properties Colection containing "storage" and "workareasput" properties.<br>
   * /storage/domains/<i>nnnn</i>/workareas/<i>sWrkAreaGUID</i> and
   * /workareasput/<i>sWrkAreaGUID</i> will be taken as base directories for deleting
   * WorkArea files.<br>
   * javamode property will determine whether directories shall be deleted witha tomic operating
   * systems calls or by Pure Java functions.
   * @return <b>true</b> if specified WorkArea GUID was found and deleted at k_workareas,
   * <b>false</b> if specified WorkArea GUID was not found.
   * @throws IOException
   * @throws SQLException
   * @see com.knowgate.dfs.FileSystem.delete(String)
   */
  public static boolean delete (JDCConnection oConn,
                                String sWrkAreaGUID,
                                java.util.Properties oProps) throws Exception, IOException, SQLException {

    final String s = System.getProperty("file.separator");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.delete([Connection], " + sWrkAreaGUID + ", " + "[Properties])");
      DebugFile.incIdent();
    }

    int iDomainId = 0;

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.id_domain + " FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "='" + sWrkAreaGUID + "'");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.id_domain + " FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sWrkAreaGUID);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      iDomainId = oRSet.getInt(1);
    oRSet.close();
    oStmt.close();

    boolean bRetVal = false;

    if (0!=iDomainId) {
      FileSystemWorkArea oFS = new FileSystemWorkArea(oProps);

      bRetVal = delete(oConn, sWrkAreaGUID);

      if (bRetVal) {
        if (null != oProps.getProperty("workareasput"))
          oFS.rmworkpath(sWrkAreaGUID);

        if (null != oProps.getProperty("storage"))
          oFS.rmstorpath(iDomainId, sWrkAreaGUID);

      } // fi (bRetVal)
    } // fi(0!=iDomainId)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  // ----------------------------------------------------------

  /**
   * Get path_logo field from k_workareas table
   * @param oConn JDCConnection
   * @param sWrkAId String GUID of WorkArea
   * @return String Value of field path_logo
   * @throws SQLException
   */
  public static String getPath (JDCConnection oConn, String sWrkAId) throws SQLException {
    String sWrkAPath;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.getPath([Connection], " + sWrkAId + ")");
      DebugFile.incIdent();
    }

    PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.path_logo + " FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sWrkAId);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sWrkAPath = oRSet.getString(1);
    else
      sWrkAPath = null;
    oRSet.close();
    oRSet = null;
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.getPath() : " + (sWrkAPath!=null ? sWrkAPath : "null"));
    }

    return sWrkAPath;
  } // getPath

  // ----------------------------------------------------------

  /**
   * <p>Check if given user belongs to the administrators' group of a WorkArea</p>
   * @param oConn JDCConnection
   * @param guWorkArea String GUID of WorkArea
   * @param sUserId GUID of User
   * @throws SQLException
   */
  public static boolean isAdmin(JDCConnection oConn, String guWorkArea, String sUserId) throws SQLException {
    int iIsAdmin;
    CallableStatement oCall;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.isAdmin([Connection], " + guWorkArea + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_ORACLE:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call k_is_workarea_admin ('" + guWorkArea + "','" + sUserId + "',?)})");

        oCall = oConn.prepareCall("{ call k_is_workarea_admin (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.DECIMAL);
        oCall.execute();
        iIsAdmin = oCall.getBigDecimal(3).intValue();
        oCall.close();
        break;

      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_MYSQL:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call k_is_workarea_admin ('" + guWorkArea + "','" + sUserId + "',?)})");

        oCall = oConn.prepareCall("{ call k_is_workarea_admin (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.INTEGER);
        oCall.execute();
        iIsAdmin = oCall.getInt(3);
        oCall.close();
        break;

      default:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT x." + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " x, " + DB.k_x_app_workarea + " w WHERE x." + DB.gu_acl_group + "=w." + DB.gu_admins + " AND x." + DB.gu_user + "='" + sUserId + "' AND w." + DB.gu_workarea + "='" + guWorkArea + "')");

        oStmt = oConn.prepareStatement("SELECT x." + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " x, " + DB.k_x_app_workarea + " w WHERE x." + DB.gu_acl_group + "=w." + DB.gu_admins + " AND x." + DB.gu_user + "=? AND w." + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sUserId);
        oStmt.setString(2, guWorkArea);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          iIsAdmin = 1;
        else
          iIsAdmin = 0;
        oRSet.close();
        oStmt.close();
        break;
    } // end switch

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.isAdmin() : " + String.valueOf(0!=iIsAdmin));
    }

    return (0!=iIsAdmin);
  } // isAdmin()

  // ----------------------------------------------------------

  /**
   * <p>Check if given user belongs to the power users' group of a WorkArea</p>
   * @param oConn JDCConnection
   * @param guWorkArea String GUID of WorkArea
   * @param sUserId GUID of User
   * @throws SQLException
   */

  public static boolean isPowerUser(JDCConnection oConn, String guWorkArea, String sUserId) throws SQLException {
    int iIsPowerUser;
    CallableStatement oCall;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.isPowerUser([Connection], " + guWorkArea + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_ORACLE:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call k_is_workarea_poweruser ('" + guWorkArea + "','" + sUserId + "',?)})");

        oCall = oConn.prepareCall("{ call k_is_workarea_poweruser (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.DECIMAL);
        oCall.execute();
        iIsPowerUser = oCall.getBigDecimal(3).intValue();
        oCall.close();
        break;

      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_MYSQL:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call k_is_workarea_poweruser ('" + guWorkArea + "','" + sUserId + "',?)})");

        oCall = oConn.prepareCall("{ call k_is_workarea_poweruser (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.INTEGER);
        oCall.execute();
        iIsPowerUser = oCall.getInt(3);
        oCall.close();
        break;

      default:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT x." + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " x, " + DB.k_x_app_workarea + " w WHERE x." + DB.gu_acl_group + "=w." + DB.gu_powusers + " AND x." + DB.gu_user + "='" + sUserId + "' AND w." + DB.gu_workarea + "='" + guWorkArea + "')");

        oStmt = oConn.prepareStatement("SELECT x." + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " x, " + DB.k_x_app_workarea + " w WHERE x." + DB.gu_acl_group + "=w." + DB.gu_powusers + " AND x." + DB.gu_user + "=? AND w." + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sUserId);
        oStmt.setString(2, guWorkArea);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          iIsPowerUser = 1;
        else
          iIsPowerUser = 0;
        oRSet.close();
        oStmt.close();
        break;
    } // end switch

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.isPowerUser() : " + String.valueOf(0!=iIsPowerUser));
    }

    return (0!=iIsPowerUser);

  } // isPowerUser()

  // ----------------------------------------------------------

  /**
   * <p>Check if given user belongs to the users' group of a WorkArea</p>
   * @param oConn JDCConnection
   * @param guWorkArea String GUID of WorkArea
   * @param sUserId GUID of User
   * @throws SQLException
   */

  public static boolean isUser(JDCConnection oConn, String guWorkArea, String sUserId) throws SQLException {
    int iIsUser;
    CallableStatement oCall;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.isUser([Connection], " + guWorkArea + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_ORACLE:

        oCall = oConn.prepareCall("{ call k_is_workarea_user (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.DECIMAL);
        oCall.execute();
        iIsUser = oCall.getBigDecimal(3).intValue();
        oCall.close();
        break;

      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_MYSQL:

        oCall = oConn.prepareCall("{ call k_is_workarea_user (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.INTEGER);
        oCall.execute();
        iIsUser = oCall.getInt(3);
        oCall.close();
        break;

      default:
        oStmt = oConn.prepareStatement("SELECT x." + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " x, " + DB.k_x_app_workarea + " w WHERE x." + DB.gu_acl_group + "=w." + DB.gu_users + " AND x." + DB.gu_user + "=? AND w." + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sUserId);
        oStmt.setString(2, guWorkArea);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          iIsUser = 1;
        else
          iIsUser = 0;
        oRSet.close();
        oStmt.close();
        break;
    } // end switch

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.isUser() : " + String.valueOf(0!=iIsUser));
    }

    return (0!=iIsUser);
  } // iIsUser()

  // ----------------------------------------------------------

  /**
   * <p>Check if given user belongs to the guests' group of a WorkArea</p>
   * @param oConn JDCConnection
   * @param guWorkArea String GUID of WorkArea
   * @param sUserId GUID of User
   * @throws SQLException
   */

  public static boolean isGuest(JDCConnection oConn, String guWorkArea, String sUserId) throws SQLException {
    int iIsGuest;
    CallableStatement oCall;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.isGuest([Connection], " + guWorkArea + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_ORACLE:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call k_is_workarea_guest ('" + guWorkArea + "','" + sUserId + "',?)})");

        oCall = oConn.prepareCall("{ call k_is_workarea_guest (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.DECIMAL);
        oCall.execute();
        iIsGuest = oCall.getBigDecimal(3).intValue();
        oCall.close();
        break;

      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_MYSQL:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call k_is_workarea_guest ('" + guWorkArea + "','" + sUserId + "',?)})");

        oCall = oConn.prepareCall("{ call k_is_workarea_guest (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.INTEGER);
        oCall.execute();
        iIsGuest = oCall.getInt(3);
        oCall.close();
        break;

      default:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT x." + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " x, " + DB.k_x_app_workarea + " w WHERE x." + DB.gu_acl_group + "=w." + DB.gu_guests + " AND x." + DB.gu_user + "='" + sUserId + "' AND w." + DB.gu_workarea + "='" + guWorkArea + "')");

        oStmt = oConn.prepareStatement("SELECT x." + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " x, " + DB.k_x_app_workarea + " w WHERE x." + DB.gu_acl_group + "=w." + DB.gu_guests + " AND x." + DB.gu_user + "=? AND w." + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sUserId);
        oStmt.setString(2, guWorkArea);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          iIsGuest = 1;
        else
          iIsGuest = 0;
        oRSet.close();
        oStmt.close();
        break;
    } // end switch

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.isGuest() : " + String.valueOf(0!=iIsGuest));
    }

    return (0!=iIsGuest);
  } // iIsGuest()

  // ----------------------------------------------------------

  /**
   * <p>Check if given user belongs to any permissions group associated with a WorkArea</p>
   * This is equivalent to doing [isAdmin() Or isPowerUser() Or isUser() Or isGuest()]
   * but faster to compute than the previous expresion
   * @param oConn JDCConnection
   * @param guWorkArea String GUID of WorkArea
   * @param sUserId GUID of User
   * @throws SQLException
   * @since 4.0
   */

  public static boolean isAnyRole(JDCConnection oConn, String guWorkArea, String sUserId) throws SQLException {
    int iIsAnyRole;
    CallableStatement oCall;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.iIsAnyRole([Connection], " + guWorkArea + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_ORACLE:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call k_is_workarea_anyrole ('" + guWorkArea + "','" + sUserId + "',?)})");

        oCall = oConn.prepareCall("{ call k_is_workarea_anyrole (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.DECIMAL);
        oCall.execute();
        iIsAnyRole = oCall.getBigDecimal(3).intValue();
        oCall.close();
        break;

      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_MYSQL:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call k_is_workarea_anyrole ('" + guWorkArea + "','" + sUserId + "',?)})");

        oCall = oConn.prepareCall("{ call k_is_workarea_anyrole (?,?,?)}");

        oCall.setString(1, guWorkArea);
        oCall.setString(2, sUserId);
        oCall.registerOutParameter(3, Types.INTEGER);
        oCall.execute();
        iIsAnyRole = oCall.getInt(3);
        oCall.close();
        break;

      default:

        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT x." + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " x, " + DB.k_x_app_workarea + " w WHERE (x." + DB.gu_acl_group + "=w." + DB.gu_guests + " OR x." + DB.gu_acl_group + "=w." + DB.gu_users + " OR x." + DB.gu_acl_group + "=w." + DB.gu_powusers + " OR x." + DB.gu_acl_group + "=w." + DB.gu_admins + " OR x." + DB.gu_acl_group + "=w." + DB.gu_other +") AND x." + DB.gu_user + "='" + sUserId + "' AND w." + DB.gu_workarea + "='" + guWorkArea + "')");

        oStmt = oConn.prepareStatement("SELECT x." + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " x, " + DB.k_x_app_workarea + " w WHERE (x." + DB.gu_acl_group + "=w." + DB.gu_guests + " OR x." + DB.gu_acl_group + "=w." + DB.gu_users + " OR x." + DB.gu_acl_group + "=w." + DB.gu_powusers + " OR x." + DB.gu_acl_group + "=w." + DB.gu_admins + " OR x." + DB.gu_acl_group + "=w." + DB.gu_other +") AND x." + DB.gu_user + "=? AND w." + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sUserId);
        oStmt.setString(2, guWorkArea);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          iIsAnyRole = 1;
        else
          iIsAnyRole = 0;
        oRSet.close();
        oStmt.close();
        break;
    } // end switch

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.isAnyRole() : " + String.valueOf(0!=iIsAnyRole));
    }

    return (0!=iIsAnyRole);
  } // isAnyRole()

  // ----------------------------------------------------------

  /**
   * <p>Get applications bitmask for a user at a given WorkArea</p>
   * The bitmask is a 32 bits integer with one bit per application.
   * A bit set to one means that the application is available for the user,
   * if it s set to zero then the application is not available.
   * Applications bits positions are as follows:
   * <TABLE><TR><TD>Bit Number</TD><TD>Application Name</TD></TR>
   * <TR><TD>10</TD><TD>Incidents Tracker</TD></TR>
   * <TR><TD>11</TD><TD>Duty Manager</TD></TR>
   * <TR><TD>12</TD><TD>Project Manager</TD></TR>
   * <TR><TD>13</TD><TD>Mailwire</TD></TR>
   * <TR><TD>14</TD><TD>Web Builder</TD></TR>
   * <TR><TD>15</TD><TD>Virtual Disk</TD></TR>
   * <TR><TD>16</TD><TD>Contact & Sales Management</TD></TR>
   * <TR><TD>17</TD><TD>Collaborative Tools</TD></TR>
   * <TR><TD>18</TD><TD>Marketing Tools</TD></TR>
   * <TR><TD>19</TD><TD>Directory</TD></TR>
   * <TR><TD>20</TD><TD>Shop</TD></TR>
   * <TR><TD>21</TD><TD>Hipermail</TD></TR>
   * <TR><TD>22</TD><TD>Training</TD></TR>
   * <TR><TD>23</TD><TD>Wiki</TD></TR>
   * <TR><TD>24</TD><TD>Passwords Manager</TD></TR>
   * <TR><TD>25</TD><TD>Surveys</TD></TR>
   * <TR><TD>30</TD><TD>Configuration & Administration</TD></TR>
   * </TABLE>
   * @return integer with one bit for each application signaling its availability for the user
   * @throws SQLException
   */
  public static int getUserAppMask(JDCConnection oConn, String guWorkArea, String sUserId) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.getUserAppMask([Connection], " + guWorkArea + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    DBSubset oApps = new DBSubset(DB.k_x_app_workarea,
                                  DB.id_app + "," + DB.gu_admins + "," + DB.gu_powusers + "," + DB.gu_users + "," + DB.gu_guests + "," + DB.gu_other,
                                  DB.gu_workarea + "=?", 30);
    int iApps = oApps.load(oConn, new Object[] { guWorkArea });
    int iAppMask = 0;
    String sGrp;

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " WHERE " + DB.gu_user + "='" + sUserId + "')");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.gu_acl_group + " FROM " + DB.k_x_group_user + " WHERE " + DB.gu_user + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(10); } catch (SQLException sqle) {}

    oStmt.setString(1, sUserId);

    ResultSet oRSet = oStmt.executeQuery();

    while (oRSet.next()) {
      sGrp = oRSet.getString(1);
      for (int a=0; a<iApps; a++)
        if (sGrp.equals(oApps.get(1,a)) || sGrp.equals(oApps.get(2,a)) || sGrp.equals(oApps.get(3,a)) || sGrp.equals(oApps.get(4,a)) || sGrp.equals(oApps.get(5,a)))
          iAppMask |= (1<<oApps.getInt(0,a));
    } // wend
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.getUserAppMask() : " + String.valueOf(iAppMask));
    }

    return iAppMask;
  } // getUserAppMask()

  // ----------------------------------------------------------

  /**
   * <p>Checks whether or not a user has access rights for a given WorkArea and Application</p>
   * @param oConn JDBC database connection
   * @param guWorkArea WorkArea GUID
   * @param isApp Application Identifier
   * @return boolean
   * @throws SQLException
   * @since 5.0
   */
  public static boolean getUserAppAccess(JDCConnection oConn, String guWorkArea, String sUserId, int idApp)
  	throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.getUserAppAccess([Connection], " + guWorkArea + "," + sUserId + "," + String.valueOf(idApp) + ")");
      DebugFile.incIdent();
    }

    boolean bHasAccess = false;

	PreparedStatement oStmt;
	ResultSet oRSet;
	String guAdmins=null, guPowUsrs=null, guUsrs=null, guGuests=null, guOther=null;
	
	oStmt = oConn.prepareStatement("SELECT " + DB.gu_admins + "," + DB.gu_powusers + "," + DB.gu_users + "," + DB.gu_guests + "," + DB.gu_other + " FROM " + DB.k_x_app_workarea + " WHERE " + DB.gu_workarea + "=? AND " + DB.id_app +" =?",
								   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	oStmt.setString(1, guWorkArea);
	oStmt.setInt(1, idApp);	
	oRSet = oStmt.executeQuery();
	if (oRSet.next()) {
	  guAdmins = oRSet.getString(1);
	  guPowUsrs= oRSet.getString(2);
	  guUsrs   = oRSet.getString(3);
	  guGuests = oRSet.getString(4);
	  guOther  = oRSet.getString(5);
	} // fi
	oRSet.close();
	oStmt.close();
	
	if (guAdmins!=null || guPowUsrs!=null || guUsrs!=null || guGuests!=null || guOther!=null) {
	  String sGroupList = "";
	  if (guAdmins!=null)  sGroupList = "'"+guAdmins+"'";
	  if (guPowUsrs!=null) sGroupList += (sGroupList.length()==0 ? "" : ",")+"'"+guPowUsrs+"'";
	  if (guUsrs!=null)    sGroupList += (sGroupList.length()==0 ? "" : ",")+"'"+guUsrs+"'";
	  if (guGuests!=null)  sGroupList += (sGroupList.length()==0 ? "" : ",")+"'"+guGuests+"'";
	  if (guOther!=null)   sGroupList += (sGroupList.length()==0 ? "" : ",")+"'"+guOther+"'";

	  oStmt = oConn.prepareStatement("SELECT NULL FROM "+DB.k_x_group_user+" WHERE "+DB.gu_user+"=? AND "+
									 DB.gu_acl_group+" IN ("+sGroupList+")",
								     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  oStmt.setString(1, sUserId);
	  oRSet = oStmt.executeQuery();
	  bHasAccess = oRSet.next();
	  oRSet.close();
	  oStmt.close();
	} // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.getUserAppAccess() : " + String.valueOf(bHasAccess));
    }

	return bHasAccess;
  } // getUserAppAccess

  // ----------------------------------------------------------

  public static String getIdFromName(JDCConnection oConn, int iDomainId, String sWorkAreaNm) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.getIdFromName([JDCConnection], " + String.valueOf(iDomainId) + "," + sWorkAreaNm + ")");
      DebugFile.incIdent();
    }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_ORACLE:
        sRetVal = getUIdFromName(oConn, new Integer(iDomainId), sWorkAreaNm, "k_get_workarea_id");
        break;

      default:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_workarea+ " FROM " + DB.k_workareas + " WHERE " + DB.nm_workarea + "='" + sWorkAreaNm + "' AND " + DB.id_domain + "=" + String.valueOf(iDomainId) +" AND " + DB.bo_active + "<>0)");

        oStmt = oConn.prepareStatement("SELECT " + DB.gu_workarea+ " FROM " + DB.k_workareas + " WHERE " + DB.nm_workarea + "=? AND " + DB.id_domain + "=? AND " + DB.bo_active + "<>0", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sWorkAreaNm);
        oStmt.setInt(2, iDomainId);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          sRetVal = oRSet.getString(1);
        else
          sRetVal = null;
        oRSet.close();
        oStmt.close();
        break;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.getIdFromName() : " + sRetVal);
    }

    return sRetVal;
  } // getIdFromName

  // ----------------------------------------------------------

  public static String getIdFromName(Connection oConn, int iDomainId, String sWorkAreaNm) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.getIdFromName([Connection], " + String.valueOf(iDomainId) + "," + sWorkAreaNm + ")");
      DebugFile.incIdent();
    }

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_workarea+ " FROM " + DB.k_workareas + " WHERE " + DB.nm_workarea + "='" + sWorkAreaNm + "' AND " + DB.id_domain + "=" + String.valueOf(iDomainId) +" AND " + DB.bo_active + "<>0)");

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_workarea+ " FROM " + DB.k_workareas + " WHERE " + DB.nm_workarea + "=? AND " + DB.id_domain + "=? AND " + DB.bo_active + "<>0", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sWorkAreaNm);
    oStmt.setInt(2, iDomainId);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.getIdFromName() : " + sRetVal);
    }

    return sRetVal;
  } // getIdFromName

  // ----------------------------------------------------------

  /**
   * Get value of tx_date_format column at k_workareas table for given WorkArea
   * @param oConn JDBC database connection
   * @param sWorkAreaGuid WorkArea GUID
   * @return Short date format (like yyyy-MM-dd) or <b>null</b> if no WorkArea with such GUID was found
   * @throws SQLException
   * @since 4.0
   */
  public static String getDateFormat(Connection oConn, String sWorkAreaGuid) throws SQLException {
    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    String sRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.getDateFormat([Connection], " + sWorkAreaGuid + ")");
      DebugFile.incIdent();
    }

	if (oParams==null) oParams = new WeakHashMap();
	if (oParams.containsKey("tx_date_format")) {
      sRetVal = (String) oParams.get("tx_date_format");
	} else {

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.tx_date_format + " FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "='" + sWorkAreaGuid);

      try {
        oStmt = oConn.prepareStatement("SELECT " + DB.tx_date_format + " FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sWorkAreaGuid);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          sRetVal = oRSet.getString(1);
          oParams.put("tx_date_format", sRetVal);
        }
        else {
          sRetVal = null;
        }
      } catch (SQLException sqle) {
        DebugFile.writeln("SQLException "+sqle.getMessage());
        sRetVal = "yyyy-MM-dd";
      } finally {
        if (null!=oRSet) oRSet.close();
        if (null!=oStmt) oStmt.close();      
      }
	} // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkArea.getDateFormat() : " + sRetVal);
    }

    return sRetVal;

  } // getDateFormat

  // ----------------------------------------------------------

  /**
   * <p>Get SimpleDateFormat objects based on the values of tx_date_format and id_locale columns from k_workareas table</p>
   * @param oConn JDBC database connection
   * @param sWorkAreaGuid WorkArea GUID
   * @return If tx_date_format is not null then its value is used as a pattern for the SimpleDateFormat,
   * if tx_date_format is null then the SimpleDateFormat is created according to the Locale specified at id_locale,
   * if both tx_date_format and id_locale are null then pattern yyyy-MM-dd is used as default,
   * if no WorkArea with given GUID is found then <b>null</b> is returned
   * @throws SQLException
   * @since 4.0
   */

  public static SimpleDateFormat getSimpleDateFormat(Connection oConn, String sWorkAreaGuid)
  	throws SQLException {

    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    SimpleDateFormat oRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkArea.getSimpleDateFormat([Connection], " + sWorkAreaGuid + ")");
      DebugFile.incIdent();
    }

	if (oParams==null) oParams = new WeakHashMap();
	if (oParams.containsKey("sdf_date_format")) {
      oRetVal = (SimpleDateFormat) oParams.get("sdf_date_format");
	} else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.tx_date_format + "," + DB.id_locale + " FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "='" + sWorkAreaGuid);

      try {
        oStmt = oConn.prepareStatement("SELECT " + DB.tx_date_format + "," + DB.id_locale + " FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sWorkAreaGuid);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          String sFmt = oRSet.getString(1);
          if (oRSet.wasNull()) {
		    String sLoc = oRSet.getString(2);
		    if (oRSet.wasNull()) {
              oRetVal = new SimpleDateFormat("yyyy-MM-dd");
		    } else {
		  	  oRetVal = (SimpleDateFormat) DateFormat.getDateInstance(DateFormat.SHORT, new Locale(sLoc));
		    }
          } else {
            oRetVal = new SimpleDateFormat(sFmt);
          }
          oParams.put("sdf_date_format", oRetVal);
        }
        else {
          oRetVal = null;      
        }
      } catch (SQLException sqle) {
        DebugFile.writeln("SQLException "+sqle.getMessage());
        oRetVal = new SimpleDateFormat("yyyy-MM-dd");
      } finally {
        if (null!=oRSet) oRSet.close();
        if (null!=oStmt) oStmt.close();      
      }
	} // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (oRetVal==null)
        DebugFile.writeln("End WorkArea.getSimpleDateFormat() : null");
	  else
        DebugFile.writeln("End WorkArea.getSimpleDateFormat() : " + oRetVal.toString());
    }

    return oRetVal;
  } // getSimpleDateFormat

  // ----------------------------------------------------------

  public static final short ClassId = 5;
}
