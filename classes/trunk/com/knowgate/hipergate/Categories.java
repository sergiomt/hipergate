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

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.acl.ACLDomain;

/**
 * Singleton manager for Categories Tree
 * @author Sergio Montoro Ten
 * @version 4.0
 */
public class Categories {

  public Categories() {
    iRootsCount = -1;
    sRootsNamedTables = DB.k_categories + " c, " + DB.k_cat_labels + " n," + DB.k_cat_root + " r";
    sRootsNamedFields =  "c." + DB.gu_category + ", c." + DB.nm_category + ", " + DBBind.Functions.ISNULL + "(n." + DB.tr_category + ",''), c." + DB.nm_icon + ", c." + DB.nm_icon2;
    sRootsNamedFilter = "n." + DB.gu_category + "=c." + DB.gu_category + " AND c." + DB.gu_category + "=r." + DB.gu_category + " AND n." + DB.id_language + "=?";

    sChildNamedTables = DB.v_cat_tree_labels ;
    sChildNamedFields =  DB.gu_category + "," + DB.nm_category + "," + DB.tr_category + ", " + DB.nm_icon + ", " + DB.nm_icon2;
    sChildNamedFilter =  DB.gu_parent_cat + "=? AND (" + DB.id_language + "=? OR " + DB.id_language + " IS NULL)";
  }

  //----------------------------------------------------------------------------

  /**
   * Clear root categories cache.
   * Root category names are loaded once and then cached into a static variable.
   * Use this method for forcing reload of categories from database on next call
   * to getRoots() or getRootsNamed().
   */
  public void clearCache() {
    oRootsLoaded = false;
  }

  // ----------------------------------------------------------

  /**
   * <p>Expand Category Childs into k_cat_expand table</p>
   * @param oConn Database Connection
   * @param sRootCategoryId GUID of Category to expand.
   * @throws SQLException
   */
  public static void expand (JDCConnection oConn, String sRootCategoryId) throws SQLException {
    Category oRoot = new Category(sRootCategoryId);
    oRoot.expand(oConn);
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Get root category for a given Domain</p>
   * The root Category for a Domain will be the one such that nm_category=nm_domain
   * @param oConn Database Connection
   * @param iDomain Domain Numeric Identifier
   * @return Category GUID or <b>null</b> if root Category for Domain was not found.
   * @throws SQLException
   */
  public Category forDomain(JDCConnection oConn, int iDomain) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    Category oRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Categories.forDomain([Connection], " + String.valueOf(iDomain) + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_category + " FROM " + DB.k_categories + " WHERE " + DB.nm_category + "=(SELECT " + DB.nm_domain + " FROM " + DB.k_domains + " WHERE " + DB.id_domain + "=?)");
    }

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_category + " FROM " + DB.k_categories + " WHERE " + DB.nm_category + "=(SELECT " + DB.nm_domain + " FROM " + DB.k_domains + " WHERE " + DB.id_domain + "=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt(1, iDomain);

    oRSet = oStmt.executeQuery();

    if (oRSet.next())
      oRetVal = new Category(oConn, oRSet.getString(1));
    else
      oRetVal = null;

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Categories.forDomain() : " + (oRetVal==null ? "null" : "[Category]"));
    }

    return oRetVal;
  } // forDomain()

  //----------------------------------------------------------------------------

  /**
   * <p>Get shared files category for a given Domain</p>
   * The shared files Category for a Domain will be the child of the root category for domain
   * which nm_category = nm_domain + "_SHARED"
   * @param oConn Database Connection
   * @param iDomain Domain Numeric Identifier
   * @return Category GUID or <b>null</b> if shared files Category for Domain was not found.
   * @throws SQLException
   * @since 4.0
   */
   
  public Category getSharedFilesCategoryForDomain(JDCConnection oConn, int iDomain)
  	throws SQLException {
    
    Category oDomainShared;
    
    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACLDomain.getSharedFilesCategory([Connection])");
      DebugFile.incIdent();
    }

	ACLDomain oDomain = new ACLDomain();
	
	if (oDomain.load(oConn, new Object[]{new Integer(iDomain)})) {
	
      Category oDomainRoot = forDomain(oConn, iDomain);
    
      if (null!=oDomainRoot) {
    
	    String sSQL = "SELECT c." +  DB.gu_category + " FROM " + DB.k_categories + " c," + DB.k_cat_tree + " t WHERE c." + DB.gu_category + "=t." + DB.gu_child_cat + " AND t." + DB.gu_parent_cat + "=? AND c." + DB.nm_category + "=?";
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

	    PreparedStatement oStmt = oConn.prepareStatement (sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

	    oStmt.setString (1, oDomainRoot.getString(DB.gu_category));
	    oStmt.setString (2, oDomain.getString(DB.nm_domain) + "_SHARED");

	    ResultSet oRSet = oStmt.executeQuery();

	    if (oRSet.next())
	      oDomainShared = new Category(oConn,oRSet.getString(1)); 
	    else
	      oDomainShared = null;
	      
	    oRSet.close();
	    oRSet = null;
	    oStmt.close();
	    oStmt = null;
      } else {
      	if (DebugFile.trace) DebugFile.writeln("Root category for domain "+String.valueOf(iDomain)+" not found");
      	oDomainShared = null;
      }// fi (oDomainRoot)
    } else {
      if (DebugFile.trace) DebugFile.writeln("Domain "+String.valueOf(iDomain)+" not found");
      oDomainShared = null;
    }// fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (oDomainShared==null)
	    DebugFile.writeln("End ACLDomain.getSharedFilesCategory() : null");
      else
	    DebugFile.writeln("End ACLDomain.getSharedFilesCategory() : " + oDomainShared.getString(DB.gu_category));
    }
    
	return oDomainShared;
  } // getSharedFilesCategoryForDomain

  //----------------------------------------------------------------------------

  /**
   * <p>Get root categories as a DBSubset.</p>
   * Root categories are those present at k_cat_root table.<br>
   * It is recommended to use this criteria instead of seeking those categories
   * not present as childs at k_cat_tree. Selecting from k_cat_root is much faster
   * than scanning the k_cat_tree table.
   * @param oConn Database Connection
   * @return A single column DBSubset containing th GUID of root categories.
   * @throws SQLException
   */
  public DBSubset getRoots(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Categories.getRoots([Connection])");
      DebugFile.incIdent();
    }

    oRoots = new DBSubset(DB.k_cat_root,DB.gu_category,"",10);
    iRootsCount = oRoots.load (oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Categories.getRoots()");
    }

    return oRoots;
  } // getRoots

  //----------------------------------------------------------------------------

  /**
   * Get root categories count.
   * @throws IllegalStateException If getRoots() or getRootsNamed() have not
   * been called prior to getRootsCount()
   */
  public int getRootsCount() throws IllegalStateException {
    if (-1==iRootsCount) throw new IllegalStateException("Must call getRoots() or getRootsNamed() prior to getRootsCount()");

    return iRootsCount;
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Get Root Caetgories and their names as a DBSubset</p>
   * Categories not having any translation at k_cat_labels will not be retrieved.<br>
   * Root Category Names are loaded once and then cached internally as a static object.<br>
   * Use clearCahce() method for refreshing root categories from database.
   * @param oConn Database Connection
   * @param sLanguage Language for category label retrieval.
   * @param iOrderBy Column for order by { ORDER_BY_NONE, ORDER_BY_NEUTRAL_NAME, ORDER_BY_LOCALE_NAME }
   * @return A DBSubset with the following columns:<br>
   * <table border=1 cellpadding=4>
   * <tr><td><b>gu_category</b></td><td><b>nm_category</b></td><td><b>tr_category</b></td><td><b>nm_icon</b></td><td><b>nm_icon2</b></td></tr>
   * <tr><td>Category GUID</td><td>Category Internal Name</td><td>Category Translated Label</td><td>Icon for Closed Folder</td><td>Icon for Opened Folder</td></tr>
   * </table>
   * @throws SQLException
   */
  public DBSubset getRootsNamed(JDCConnection oConn, String sLanguage, int iOrderBy) throws SQLException {

    sRootsNamedFields =  "c." + DB.gu_category + ", c." + DB.nm_category + ", " + DBBind.Functions.ISNULL + "(n." + DB.tr_category + ",''), c." + DB.nm_icon + ", c." + DB.nm_icon2;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Categories.getRootsNamed([Connection], " + sLanguage + String.valueOf(iOrderBy) + ")");
      DebugFile.incIdent();
    }

    if (!oRootsLoaded) {
      Object[] aLang = { sLanguage };

      if (iOrderBy>0)
        oRootsNamed = new DBSubset (sRootsNamedTables, sRootsNamedFields, sRootsNamedFilter + " ORDER BY " + iOrderBy, 16);
      else
        oRootsNamed = new DBSubset (sRootsNamedTables, sRootsNamedFields, sRootsNamedFilter, 16);

      iRootsCount = oRootsNamed.load(oConn, aLang);
      oRootsLoaded = true;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Categories.getRootsNamed()");
    }

    return oRootsNamed;
  } // getRootsNamed()

  //----------------------------------------------------------------------------

  /**
   * <p>Get first level childs for a given category.</p>
   * Categories not having any translation at k_cat_labels will not be retrieved.
   * @param oConn Database Connection
   * @param idParent Parent Category
   * @param sLanguage Language for label retrieval
   * @param iOrderBy Column for order by { ORDER_BY_NONE, ORDER_BY_NEUTRAL_NAME, ORDER_BY_LOCALE_NAME }
   * @return A DBSubset with the following columns:<br>
   * <table border=1 cellpadding=4>
   * <tr><td><b>gu_category</b></td><td><b>nm_category</b></td><td><b>tr_category</b></td><td><b>nm_icon</b></td><td><b>nm_icon2</b></td></tr>
   * <tr><td>Category GUID</td><td>Category Internal Name</td><td>Category Translated Label</td><td>Icon for Closed Folder</td><td>Icon for Opened Folder</td></tr>
   * </table>
   * @throws SQLException
   */
  public DBSubset getChildsNamed(JDCConnection oConn, String idParent, String sLanguage, int iOrderBy) throws SQLException {

    long lElapsed = 0;

    if (DebugFile.trace) {
      lElapsed = System.currentTimeMillis();
      DebugFile.writeln("Begin Categories.getChildsNamed([Connection], " + (idParent==null ? "null" : idParent) + "," + (sLanguage==null ? "null" : sLanguage) + "," + String.valueOf(iOrderBy) + ")");
      DebugFile.incIdent();
    }

    Object[] aParams = { idParent, sLanguage, idParent, idParent, sLanguage };
    DBSubset oChilds;

    if (iOrderBy>0)
      oChilds = new DBSubset (sChildNamedTables, sChildNamedFields, sChildNamedFilter +
                              " UNION SELECT " +
                              "c." + DB.gu_category + ",c." + DB.nm_category + ",c." + DB.nm_category + "," +
                              "c." + DB.nm_icon + ",c." + DB.nm_icon2 + " FROM " + DB.k_categories + " c, " +
                              DB.k_cat_tree + " t WHERE c." + DB.gu_category + "=t." + DB.gu_child_cat + " AND " +
                              "t." + DB.gu_parent_cat + "=? AND c." +  DB.gu_category + " NOT IN " +
                              "(SELECT " + DB.gu_category + " FROM " + sChildNamedTables + " WHERE " + sChildNamedFilter + ") ORDER BY " + iOrderBy, 32);
    else
      oChilds = new DBSubset (sChildNamedTables, sChildNamedFields, sChildNamedFilter +
                              " UNION SELECT " +
                              "c." + DB.gu_category + ",c." + DB.nm_category + ",c." + DB.nm_category + ", " +
                              "c." + DB.nm_icon + ",c." + DB.nm_icon2 + " FROM " + DB.k_categories + " c, " +
                              DB.k_cat_tree + " t WHERE c." + DB.gu_category + "=t." + DB.gu_child_cat + " AND " +
                              "t." + DB.gu_parent_cat + "=? AND c." +  DB.gu_category + " NOT IN " +
                              "(SELECT " + DB.gu_category + " FROM " + sChildNamedTables + " WHERE " + sChildNamedFilter + ")", 32);

    int iChilds = oChilds.load(oConn, aParams);

    if (DebugFile.trace) {
      DebugFile.writeln(String.valueOf(iChilds) + " childs readed in " + String.valueOf(System.currentTimeMillis()-lElapsed) + " ms");
      DebugFile.decIdent();
      DebugFile.writeln("End Categories.getChildsNamed()");
    }

    return oChilds;
  } // getChildsNamed()

  // ----------------------------------------------------------

  /**
   * <p>Remove object from all Categories</p>
   * Removing an object from a Category does not delete it.
   * @param oConn Database Connection
   * @param sIdObject Object GUID
   * @param iClassId Object Class Numeric Identifier
   * @return A Positive integer if the  object was present
   * at any category or 0 if the object was not present
   * at any category.
   * @throws SQLException
   * @since 4.0
   */
  public static int removeObject(JDCConnection oConn, String sIdObject, int iClassId) throws SQLException {
     int iRetVal;
     PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + "=? AND " + DB.id_class + "=?");
     oStmt.setString(1, sIdObject);
     oStmt.setInt(2, iClassId);
     iRetVal = oStmt.executeUpdate();
     oStmt.close();
     return iRetVal;
  } // removeObject

  //----------------------------------------------------------------------------

  private DBSubset oRoots;

  private DBSubset oRootsNamed;
  private boolean oRootsLoaded;
  private int iRootsCount;
  private String sRootsNamedTables;
  private String sRootsNamedFields;
  private String sRootsNamedFilter;

  private String sChildNamedTables;
  private String sChildNamedFields;
  private String sChildNamedFilter;
  private String sChildNamedNoLang;

  public static final int ORDER_BY_NONE = 0;
  public static final int ORDER_BY_ID = 1;
  public static final int ORDER_BY_NEUTRAL_NAME = 2;
  public static final int ORDER_BY_LOCALE_NAME = 3;
}