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

package com.knowgate.hipergate;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.acl.ACL;
import com.knowgate.acl.ACLDomain;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

import java.sql.SQLException;
import java.sql.Statement;

import java.io.IOException;

/**
 * @author Sergio Montoro
 * @version 4.0
 */

public class Shop extends DBPersist {
  public Shop() {
     super(DB.k_shops, "Shop");
  }

  public Shop(JDCConnection oConn, String sShopId) throws SQLException {
     super(DB.k_shops, "Shop");

     load (oConn, new Object[]{sShopId});
  }

  //----------------------------------------------------------------------------

  /**
   * Delete Shop including all its orders, categories and products.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {

    Statement oStmt;
    String sRootCat;
    String sBundlesCat;    
    boolean bRetVal;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Shop.delete([Connection], " + getStringNull(DB.gu_root_cat, "null") + ")");
      DebugFile.incIdent();
    }

    oStmt = oConn.createStatement();

    if (DBBind.exists(oConn, DB.k_returned_invoices, "U")) {
      sSQL = "DELETE FROM " + DB.k_x_orders_invoices + " WHERE " + DB.gu_invoice + " IN (SELECT "+DB.gu_invoice+" FROM " + DB.k_returned_invoices + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      sSQL = "DELETE FROM " + DB.k_invoice_lines + " WHERE " + DB.gu_invoice + " IN (SELECT "+DB.gu_returned+" FROM " + DB.k_returned_invoices + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      sSQL = "DELETE FROM " + DB.k_returned_invoices + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
    }

    if (DBBind.exists(oConn, DB.k_invoices, "U")) {
      sSQL = "DELETE FROM " + DB.k_x_orders_invoices + " WHERE " + DB.gu_invoice + " IN (SELECT "+DB.gu_invoice+" FROM " + DB.k_invoices + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      sSQL = "DELETE FROM " + DB.k_invoice_lines + " WHERE " + DB.gu_invoice + " IN (SELECT "+DB.gu_invoice+" FROM " + DB.k_invoices + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      sSQL = "DELETE FROM " + DB.k_invoices + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
    }

    if (DBBind.exists(oConn, DB.k_despatch_advices, "U")) {
      sSQL = "DELETE FROM " + DB.k_x_orders_despatch + " WHERE " + DB.gu_despatch + " IN (SELECT "+DB.gu_despatch+" FROM " + DB.k_despatch_advices + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);

      sSQL = "DELETE FROM " + DB.k_despatch_lines + " WHERE " + DB.gu_despatch + " IN (SELECT "+DB.gu_despatch+" FROM " + DB.k_despatch_advices + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      sSQL = "DELETE FROM " + DB.k_despatch_advices + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
    }

    sSQL = "DELETE FROM " + DB.k_order_lines + " WHERE " + DB.gu_order + " IN (SELECT "+DB.gu_order+" FROM " + DB.k_orders + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "')";
    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
    oStmt.executeUpdate(sSQL);

    sSQL = "DELETE FROM " + DB.k_orders + " WHERE " + DB.gu_shop + "='" + getString(DB.gu_shop) + "'";
    if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
    oStmt.executeUpdate(sSQL);

    oStmt.close();

    sRootCat = getString(DB.gu_root_cat);
    sBundlesCat = getStringNull(DB.gu_bundles_cat,null);

    bRetVal = super.delete(oConn);

    if (bRetVal)
      try {
        bRetVal = Category.delete(oConn, sRootCat);
        if (null!=sBundlesCat) bRetVal = Category.delete(oConn, sBundlesCat);
      } catch (IOException ioe) {
        bRetVal = false;
        throw new SQLException ("IOException " + ioe.getMessage());
      }
    if (DebugFile.trace) {
      DebugFile.writeln("End Shop.delete() : " + String.valueOf(bRetVal));
      DebugFile.incIdent();
    }

    return bRetVal;
  }

  //----------------------------------------------------------------------------

   public boolean store(JDCConnection oConn) throws SQLException {

     if (!AllVals.containsKey(DB.gu_shop))
      put(DB.gu_shop, Gadgets.generateUUID());

    if (!AllVals.containsKey(DB.bo_active))
      put(DB.bo_active, (short)1);

     return super.store(oConn);
   } // store

   //----------------------------------------------------------------------------

	/**
	 * Store Shop creating Root and Bundles categories for it if necessary
	 * @throws SQLException
	 */
    public boolean store(JDCConnection oConn, String sParentCategoryId) throws SQLException {
      boolean bRetVal;
      Category oRootCat;
      Category oBundlesCat;
      ACLDomain oDomain;

      if (DebugFile.trace) {
        DebugFile.writeln("Begin Shop.store([Connection], " + sParentCategoryId + ")");
        DebugFile.incIdent();
      }

      if (sParentCategoryId==null)
        throw new java.lang.IllegalArgumentException("Parent category Identifier cannot be null");

      if (sParentCategoryId.length()==0)
        throw new java.lang.IllegalArgumentException("Parent category Identifier cannot be empty");

      if (!AllVals.containsKey(DB.gu_shop))
        put(DB.gu_shop, Gadgets.generateUUID());

      if (!AllVals.containsKey(DB.bo_active))
        put(DB.bo_active, (short)1);

      oDomain = new ACLDomain(oConn, getInt(DB.id_domain));

      if (!AllVals.containsKey(DB.gu_root_cat)) {
        if (DebugFile.trace) DebugFile.writeln("creating shops category for domain " + String.valueOf(getInt(DB.id_domain)));

        oRootCat = new Category(Category.store(oConn, null, sParentCategoryId, Category.makeName(oConn, getString(DB.nm_shop)), getShort(DB.bo_active), (short)0, oDomain.getString(DB.gu_owner), null, null));
        oRootCat.setUserPermissions(oConn, oDomain.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
        oRootCat.setGroupPermissions(oConn, oDomain.getString(DB.gu_admins), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);

        if (sAuditUsr.length()>0 && !sAuditUsr.equals(oDomain.getString(DB.gu_owner))) {
          oRootCat.setUserPermissions(oConn, sAuditUsr, ACL.PERMISSION_MODIFY, (short)0, (short)0);
        }
        put(DB.gu_root_cat, oRootCat.getString(DB.gu_category));
      }
      else {
        oRootCat = new Category(getString(DB.gu_root_cat));
        if (!oRootCat.isChildOf(oConn, sParentCategoryId));
          throw new IllegalArgumentException("Root Category is not a child of specified Parent Category");
      }

      if (!AllVals.containsKey(DB.gu_bundles_cat)) {
        if (DebugFile.trace) DebugFile.writeln("creating bundles category for domain " + String.valueOf(getInt(DB.id_domain)));

        oBundlesCat = new Category(Category.store(oConn, null, sParentCategoryId, Category.makeName(oConn, getString(DB.nm_shop)+"_BUNDLES"), getShort(DB.bo_active), (short)0, oDomain.getString(DB.gu_owner), null, null));
        oBundlesCat.setUserPermissions(oConn, oDomain.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
        oBundlesCat.setGroupPermissions(oConn, oDomain.getString(DB.gu_admins), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);

        if (sAuditUsr.length()>0 && !sAuditUsr.equals(oDomain.getString(DB.gu_owner))) {
          oBundlesCat.setUserPermissions(oConn, sAuditUsr, ACL.PERMISSION_MODIFY, (short)0, (short)0);
        }
        put(DB.gu_bundles_cat, oBundlesCat.getString(DB.gu_category));
      }
      else {
        oBundlesCat = new Category(getString(DB.gu_bundles_cat));
        if (!oBundlesCat.isChildOf(oConn, sParentCategoryId));
          throw new IllegalArgumentException("Bundles Category is not a child of specified Parent Category");
      }

      bRetVal = super.store(oConn);

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Shop.store() : "+String.valueOf(bRetVal));
      }

	  return bRetVal;
    } // store

    // ----------------------------------------------------------

    public void expandCategories(JDCConnection oConn) throws SQLException {
      Category oRootCat = new Category(DB.gu_root_cat);
      oRootCat.expand(oConn);
    } // expandCategories

   // **********************************************************
   // Constantes Publicas

   public static final short ClassId = 40;

}
