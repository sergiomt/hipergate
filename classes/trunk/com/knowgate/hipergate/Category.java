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

import java.io.File;
import java.io.IOException;
import java.io.FileInputStream;

import java.util.Properties;

import java.util.LinkedList;
import java.util.ListIterator;
import java.util.NoSuchElementException;
import java.util.StringTokenizer;

import java.sql.Types;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.DatabaseMetaData;

import com.knowgate.debug.DebugFile;
import com.knowgate.acl.ACL;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;

import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.FileSystem;

import com.knowgate.hipergate.DBLanguages;

/**
 * Categories from k_categories database table
 * @author Sergio Montoro Ten
 * @version 6.0
 */
public class Category  extends DBPersist {

  /**
   * Create empty Category
   */
  public Category() {
    super(DB.k_categories, "Category");
    oFS = null;
  }

  // ----------------------------------------------------------

  /**
   * Create Category and set gu_category.
   * @param sIdCategory Category GUID
   * @throws SQLException
   */
  public Category(String sIdCategory) throws SQLException {
    super(DB.k_categories,"Category");

    put(DB.gu_category, sIdCategory);
    oFS = null;
  }

  // ----------------------------------------------------------

  /**
   * Load Category from database
   * @param oConn Database Connection
   * @param sIdCategory Category GUID
   * @throws SQLException
   */
  public Category(JDCConnection oConn, String sIdCategory) throws SQLException {
    super(DB.k_categories,"Category");

    Object aCatg[] = { sIdCategory };

    load (oConn,aCatg);
    oFS = null;
  }

  // ----------------------------------------------------------

  protected Category(String sTableName, String sClassName) {
    super(sTableName, sClassName);
    oFS = null;
  }

  // ==========================================================

  /**
   * <p>Get a list of all parents or childs of a Category.</p>
   * All levels up or down are scanned recursively.
   * @param oConn Database Connection
   * @param iDirection BROWSE_UP for browsing parents or BROWSE_DOWN for browsing childs.
   * @param iOrder BROWSE_TOPDOWN first element on the list will be the top most parent,
   * BROWSE_BOTTOMUP first element on the list will be the deepest child.
   * @return LinkedList of Category objects.
   * @throws SQLException
   */
  public LinkedList<Category> browse (JDCConnection oConn, int iDirection, int iOrder) throws SQLException {
    String sCatId = getString(DB.gu_category);
    String sNeighbour;
    boolean bDoNext;
    PreparedStatement oCstm;
    PreparedStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    
    LinkedList<Category> oCatList = new LinkedList<Category>();
    Category oCatg;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.browse([Connection], ...)");      
      DebugFile.incIdent();
      DebugFile.writeln((iDirection==Category.BROWSE_UP ? DB.gu_child_cat : DB.gu_parent_cat) + "=" + sCatId);
    }

	oCstm = oConn.prepareStatement("SELECT * FROM "+DB.k_categories+" WHERE "+DB.gu_category+"=?",
	                               ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    if (iDirection==Category.BROWSE_UP) {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_parent_cat + " FROM " + DB.k_cat_tree + " WHERE " + DB.gu_child_cat + "=?)");
      oStmt = oConn.prepareStatement("SELECT " + DB.gu_parent_cat + " FROM " + DB.k_cat_tree + " WHERE " + DB.gu_child_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_child_cat + " FROM " + DB.k_cat_tree + " WHERE " + DB.gu_parent_cat + "=?)");
      oStmt = oConn.prepareStatement("SELECT " + DB.gu_child_cat + " FROM " + DB.k_cat_tree + " WHERE " + DB.gu_parent_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    }

    do {

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(1, " + sCatId + ")");

      oStmt.setString(1, sCatId);
      oRSet = oStmt.executeQuery();
      bDoNext = oRSet.next();

      if (bDoNext) {
        sNeighbour = oRSet.getString(1);
        if (DebugFile.trace) DebugFile.writeln("do next is true with "+(iDirection==Category.BROWSE_UP ? DB.gu_parent_cat : DB.gu_child_cat) + "=" + sNeighbour);
      }
      else {
        sNeighbour = "";
        if (DebugFile.trace) DebugFile.writeln("do next is false");
      }

      oRSet.close();

      if (bDoNext) {
        if (sCatId.equals(sNeighbour)) {
          bDoNext = false;
        }
        else {
          // Do not replace this code by new Category(oConn, sNeighbour);
          // It is being called from Product.getShopId which JDCConnection
          // does not have any metadata for calling the Category constructor
          oCstm.setString(1, sNeighbour);
          oRSet = oCstm.executeQuery();
          oRSet.next();
          oMDat = oRSet.getMetaData();
          int nCols = oMDat.getColumnCount();                    
          oCatg = new Category();
          for (int c=1; c<=nCols; c++) {
			switch (oMDat.getColumnType(c)) {
			  case Types.CHAR:
			  case Types.NCHAR:
			  case Types.VARCHAR:
			  case Types.NVARCHAR:
			  case Types.LONGVARCHAR:
			  	oCatg.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getString(c));
			  	break;
			  case Types.DATE:
			  case Types.TIMESTAMP:
			  	oCatg.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getDate(c));
			  	break;
			  case Types.SMALLINT:			  	
			  	oCatg.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getShort(c));
			  	break;
			  case Types.INTEGER:			  	
			  	oCatg.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getInt(c));
			  	break;
			  case Types.NUMERIC:
			  case Types.DECIMAL:
			  	oCatg.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getBigDecimal(c));
			  	break;
			  case Types.REAL:			  	
			  case Types.FLOAT:			  	
			  	oCatg.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getFloat(c));
			  	break;
			  case Types.DOUBLE:			  	
			  	oCatg.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getDouble(c));
			  	break;
			  default:
			  	oCatg.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
			} // end switch
          } // next
          oRSet.close();          

          if (iDirection==Category.BROWSE_UP)
            if (iOrder==Category.BROWSE_BOTTOMUP)
              oCatList.addLast(oCatg);
            else
              oCatList.addFirst(oCatg);
          else
            if (iOrder==Category.BROWSE_BOTTOMUP)
              oCatList.addFirst(oCatg);
            else
              oCatList.addLast(oCatg);

          sCatId = sNeighbour;
        } // fi(sCatId==sNeighbour)
      } // fi (bDoNext)
    } while (bDoNext);

    oStmt.close();
    oCstm.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.browse() : " + String.valueOf(oCatList.size()));
    }

    return oCatList;
  } // browse

  // ----------------------------------------------------------

  /**
   * <p>Compose a path to Category by concatenating all parents names.</p>
   * Calls k_sp_get_cat_path.<br>
   * Category parents are found and each parent name is extracted.<br>
   * Then parent names are contenated in order separated by slash '/' characters.<br>
   * This method is usefull when creating a physical directory path for files
   * belonging to Products contained in a Category. This way the directory paths can
   * mimmic the category tree structure.
   * @param oConn Database Connection
   * @return String with Category parent names concatenated with slash '/' characters.
   * For example "ROOT/DOMAINS/SYSTEM/SYSTEM_APPS/SYSTEM_apps_webbuilder"
   * @throws SQLException
   */
  public String getPath(Connection oConn) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    CallableStatement oCall;
    DatabaseMetaData oMDat;
    String sPath;
    String sDBMS;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.getPath([Connection])" );
      DebugFile.incIdent();
      DebugFile.writeln("gu_category=" + get(DB.gu_category));
    }

    try {
      oMDat = oConn.getMetaData();
      if (null==oMDat)
        sDBMS = "unknown";
      else
        sDBMS = oConn.getMetaData().getDatabaseProductName();
    }
    catch (NullPointerException npe) {
      sDBMS = "unknown";
    }

      if (sDBMS.equals("PostgreSQL")) {
        oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT k_sp_get_cat_path('" + getStringNull(DB.gu_category, "null") + "'))");

        oRSet = oStmt.executeQuery("SELECT k_sp_get_cat_path ('" + getString(DB.gu_category) + "')");
        oRSet.next();
        sPath = oRSet.getString(1);
        oRSet.close();
        oStmt.close();
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("{call k_sp_get_cat_path ('" + getStringNull(DB.gu_category, "null") + "',?)}");

        oCall = oConn.prepareCall("{call k_sp_get_cat_path (?,?)}");
        oCall.setString(1, getString(DB.gu_category));
        oCall.registerOutParameter(2, java.sql.Types.VARCHAR);
        oCall.execute();
        sPath = oCall.getString(2);
        oCall.close();
      }
    // End SQLException

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.getPath() : " + sPath);
    }

    return sPath;
  } // getPath()

  // ----------------------------------------------------------

  /**
   * <p>Delete Category and all its childs.</p>
   * First delete all Products and Companies contained in Category, including
   * physical disk files associted with Products and Company attachments.<br>
   * Then call k_sp_del_category_r stored procedure and perform recursive
   * deletion of all childs.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    try {
      return Category.delete(oConn, getString(DB.gu_category));
    } catch (IOException ioe) {
      throw new SQLException("IOException " + ioe.getMessage());
    }
  } // delete

  // ----------------------------------------------------------

  /**
   * <p>Add object to Category.</p>
   * The object GUID and numeric class identifier is inserted at k_x_cat_objs table.<br>
   * @param oConn Database Connection
   * @param sIdObject Object GUID
   * @param iIdClass Object Numeric Class Identifier (variable ClassId)
   * @param iAttribs Object attributes mask (user defined)
   * @param iOdPosition Object Position. An arbitrary position for the object inside the
   * category. Position is not unique for an object. Two or more objects may have the same
   * position.
   * @throws SQLException If object is alredy contanied in Category then a primary key violation exception is raised.
   */
  public int addObject(Connection oConn, String sIdObject, int iIdClass, int iAttribs, int iOdPosition) throws SQLException {
     PreparedStatement oStmt;
     int iRetVal;

     if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.addObject([Connection], " + sIdObject + ", ...)" );
       DebugFile.incIdent();
     }

     oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_x_cat_objs + " (" + DB.gu_category + "," + DB.gu_object + "," + DB.id_class + "," + DB.bi_attribs + "," + DB.od_position + ") VALUES (?,?,?,?,?)");
     oStmt.setString(1, getString(DB.gu_category));
     oStmt.setString(2, sIdObject);
     oStmt.setInt (3, iIdClass);
     oStmt.setInt (4, iAttribs);
     oStmt.setInt (5, iOdPosition);
     iRetVal = oStmt.executeUpdate();
     oStmt.close();

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Category.addObject() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // addProduct

  // ----------------------------------------------------------

  /**
   * <p>Remove object from Category</p>
   * Removing an object from a Category does not delete it.
   * @param oConn Database Connection
   * @param sIdObject Object GUID
   * @return 1 if object was present at category, 0 if object was not present at category.
   * @throws SQLException
   */
  public int removeObject(Connection oConn, String sIdObject) throws SQLException {
     int iRetVal;
     PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_category + "=? AND " + DB.gu_object + "=?");
     oStmt.setString(1, getString(DB.gu_category));
     oStmt.setString(2, sIdObject);
     iRetVal = oStmt.executeUpdate();
     oStmt.close();
     return iRetVal;
  } // removeObject

  // ----------------------------------------------------------

  /**
   * <p>Remove object from Category</p>
   * Removing an object from a Category does not delete it.
   * @param oConn Database Connection
   * @param sIdObject Object GUID
   * @param iClassId Object Class Numeric Identifier
   * @return 1 if object was present at category, 0 if object was not present at category.
   * @throws SQLException
   * @since 4.0
   */
  public int removeObject(Connection oConn, String sIdObject, int iClassId) throws SQLException {
     int iRetVal;
     PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_category + "=? AND " + DB.gu_object + "=? AND " + DB.id_class + "=?");
     oStmt.setString(1, getString(DB.gu_category));
     oStmt.setString(2, sIdObject);
     oStmt.setInt(3, iClassId);
     iRetVal = oStmt.executeUpdate();
     oStmt.close();
     return iRetVal;
  } // removeObject

  // ----------------------------------------------------------

  /**
   * <p>Set group permissions.</p>
   * Calls  k_sp_cat_del_grp stored procedure.
   * @param oConn Database Connection
   * @param sIdGroups String of comma separated GUIDs of ACLGroups with permissions to remove.
   * @param iRecurse Remove permissions also from childs Categories all levels down.
   * @param iObjects Not Used, must be zero.
   * @throws SQLException
   */
  public void removeGroupPermissions (Connection oConn, String sIdGroups, short iRecurse, short iObjects) throws SQLException {
    CallableStatement oStmt;
    StringTokenizer oUsrTok;
    int iTokCount;
    String sIdCategory;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.removeGroupPermissions([Connection], " + sIdGroups + "," + iRecurse + "," + iObjects + ")" );
       DebugFile.incIdent();
       DebugFile.writeln("Connection.prepareCall({ call k_sp_cat_del_grp ('" + getStringNull(DB.gu_category, "null") + "',?," + String.valueOf(iRecurse) + "," + String.valueOf(iObjects) + ") }");
     }

    if (oConn.getMetaData().getDatabaseProductName().equals("PostgreSQL"))
      oStmt = oConn.prepareCall("{ call k_sp_cat_del_grp ('" + getString(DB.gu_category) + "',?,CAST(" + String.valueOf(iRecurse) + " AS SMALLINT), CAST(" + String.valueOf(iObjects) + " AS SMALLINT)) }");
    else
      oStmt = oConn.prepareCall("{ call k_sp_cat_del_grp ('" + getString(DB.gu_category) + "',?," + String.valueOf(iRecurse) + "," + String.valueOf(iObjects) + ") }");

    if (sIdGroups.indexOf(',')>=0) {
      oUsrTok = new StringTokenizer(sIdGroups, ",");
      iTokCount = oUsrTok.countTokens();
      sIdCategory = getString(DB.gu_category);

      for (int t=0; t<iTokCount; t++) {
        oStmt.setString(1, oUsrTok.nextToken());
        oStmt.execute();
      } // end for ()

      oStmt.close();
    }
    else {
      oStmt.setString(1, sIdGroups);
      oStmt.execute();
      oStmt.close();
    }

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Category.Category.removeGroupPermissions()");
     }
  } // removeGroupPermissions

  // ----------------------------------------------------------

  /**
   * <p>Set group permissions for Category</p>
   * Calls k_sp_cat_set_grp stored procedure.
   * @param oConn Database Connection
   * @param sIdGroups String of comma separated GUIDs of ACLGroups with permissions to set.
   * @param iACLMask Permissions mask, any combination of { ACL.PERMISSION_LIST,
   * ACL.PERMISSION_READ,ACL.PERMISSION_ADD,ACL.PERMISSION_DELETE,ACL.PERMISSION_MODIFY,
   * ACL.PERMISSION_MODERATE,ACL.PERMISSION_SEND,ACL.PERMISSION_GRANT,
   * ACL.PERMISSION_FULL_CONTROL }
   * @param iRecurse Remove permissions also from childs Categories all levels down.
   * @param iObjects Not Used, must be zero.
   * @throws SQLException
   * @see com.knowgate.acl.ACL
   */
  public void setGroupPermissions(Connection oConn, String sIdGroups, int iACLMask, short iRecurse, short iObjects) throws SQLException {
    PreparedStatement oStmt;
    CallableStatement oCall;
    StringTokenizer oUsrTok;
    String sToken;
    int iTokCount;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.setGroupPermissions([Connection], " + sIdGroups + "," + iACLMask + "," + iRecurse + "," + iObjects + ")" );
       DebugFile.incIdent();

       DebugFile.writeln("database product name " + oConn.getMetaData().getDatabaseProductName());

       if (oConn.getMetaData().getDatabaseProductName().equals("PostgreSQL"))
         DebugFile.writeln("Connection.prepareStatement(SELECT k_sp_cat_set_grp ('" + getString(DB.gu_category) + "',?," + String.valueOf(iACLMask) + ", CAST(" + String.valueOf(iRecurse) + " AS SMALLINT), CAST(" + String.valueOf(iObjects) + " AS SMALLINT))");
       else
         DebugFile.writeln("Connection.prepareCall({ call k_sp_cat_set_grp ('" + getStringNull(DB.gu_category, "null") + "',?," + String.valueOf(iACLMask) + "," + String.valueOf(iRecurse) + "," + String.valueOf(iObjects) + ") }");
     }

    if (oConn.getMetaData().getDatabaseProductName().equals("PostgreSQL")) {
      oStmt = oConn.prepareStatement("SELECT k_sp_cat_set_grp ('" + getString(DB.gu_category) + "',?," + String.valueOf(iACLMask) + ", CAST(" + String.valueOf(iRecurse) + " AS SMALLINT), CAST(" + String.valueOf(iObjects) + " AS SMALLINT))");
      if (sIdGroups.indexOf(',')>0) {
        oUsrTok = new StringTokenizer(sIdGroups, ",");
        iTokCount = oUsrTok.countTokens();
        for (int t=0; t<iTokCount; t++) {
          oStmt.setString(1, oUsrTok.nextToken());
          oStmt.executeQuery().close();
        } // end for ()
      }
      else {
        oStmt.setString(1, sIdGroups);
        oStmt.executeQuery().close();
      }
      oStmt.close();
    } else {
      oCall = oConn.prepareCall("{ call k_sp_cat_set_grp ('" + getString(DB.gu_category) + "',?," + String.valueOf(iACLMask) + "," + String.valueOf(iRecurse) + "," + String.valueOf(iObjects) + ") }");
      if (sIdGroups.indexOf(',')>0) {
        oUsrTok = new StringTokenizer(sIdGroups, ",");
        iTokCount = oUsrTok.countTokens();
        for (int t=0; t<iTokCount; t++) {
          sToken = oUsrTok.nextToken();
          if (DebugFile.trace) DebugFile.writeln("CallableStatement.setString(1,"+sToken+")");
          oCall.setString(1, sToken);
          oCall.execute();
        } // end for ()
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("CallableStatement.setString(1,"+sIdGroups+")");
        oCall.setString(1, sIdGroups);
        oCall.execute();
      }
      oCall.close();
    }

    if (DebugFile.trace) {
       String[] aGrps = com.knowgate.misc.Gadgets.split(sIdGroups,',');
       int iMsk;
       for (int g=0; g<aGrps.length; g++) {
         iMsk = getGroupPermissions(oConn,aGrps[g]);
         if (iMsk!=iACLMask)
           throw new SQLException("Procedure k_sp_cat_grp_perm returned a different permissions mask ("+String.valueOf(iMsk)+") for group "+aGrps[g]+" on category " + getStringNull(DB.gu_category,null)+ " than that set by k_sp_cat_set_grp ("+String.valueOf(iACLMask)+")");
       }
       DebugFile.decIdent();
       DebugFile.writeln("End Category.Category.setGroupPermissions()");
     }
  } // setGroupPermissions

  // ----------------------------------------------------------

  /**
   * <p>Get User permissions for Category</p>
   * Calls k_sp_cat_usr_perm stored procedure.<br>
   * User permissions are those granted directy to user plus those grants
   * indirectly by assigning permisssion to a group witch the user belongs to.<br>
   * Permissions are accumulative; a user gains new permissions by belonging to
   * new groups. All permissions are of grant type, there are no deny permissions.
   * @param oConn Database Connection
   * @param sIdUser User GUID
   * @return User permissions mask. Any combination of:
   * { ACL.PERMISSION_LIST, ACL.PERMISSION_READ,ACL.PERMISSION_ADD,
   * ACL.PERMISSION_DELETE,ACL.PERMISSION_MODIFY, ACL.PERMISSION_MODERATE,
   * ACL.PERMISSION_SEND,ACL.PERMISSION_GRANT,ACL.PERMISSION_FULL_CONTROL }
   * @throws SQLException
   */
  public int getUserPermissions(Connection oConn, String sIdUser) throws SQLException {
    int iACLMask;
    CallableStatement oCall;
    Statement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.getUserPermissions([Connection], " + sIdUser + ")" );
       DebugFile.incIdent();
    }

    if (oConn.getMetaData().getDatabaseProductName().equals("PostgreSQL")) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT k_sp_cat_usr_perm ('" + sIdUser + "','" + getStringNull(DB.gu_category,"null") + "'))");

      oRSet = oStmt.executeQuery("SELECT k_sp_cat_usr_perm ('" + sIdUser + "','" + getString(DB.gu_category) + "')");
      oRSet.next();
      iACLMask = oRSet.getInt(1);
      oRSet.close();
      oStmt.close();
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_cat_usr_perm('" + sIdUser + "','" + getStringNull(DB.gu_category,null) + "',?) })");

      oCall = oConn.prepareCall("{ call k_sp_cat_usr_perm(?,?,?) }");
      oCall.setString(1, sIdUser);
      oCall.setString(2, getString(DB.gu_category));
      oCall.registerOutParameter(3, java.sql.Types.INTEGER);
      oCall.execute();
      iACLMask = oCall.getInt(3);
      oCall.close();
    }

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Category.getUserPermissions() : " + String.valueOf(iACLMask));
     }

    return iACLMask;
  } // getUserPermissions()

  // ----------------------------------------------------------

  /**
   * <p>Get permissions mas of a group over this category</p>
   * If there is no explicit permissions mask set at k_x_cat_group_acl for given
   * group and this category, then the category hierarchy is scanned upwards and
   * the permissions of the closest parent are assumed to be the ones of this category.
   * If no parent has explicit permissions set for given group then return value is zero.
   * @param oConn Database Connection
   * @param sIdGroup ACLGroup GUID
   * @return Group permissions mask. Any combination of:
   * { ACL.PERMISSION_LIST, ACL.PERMISSION_READ,ACL.PERMISSION_ADD,
   * ACL.PERMISSION_DELETE,ACL.PERMISSION_MODIFY, ACL.PERMISSION_MODERATE,
   * ACL.PERMISSION_SEND,ACL.PERMISSION_GRANT,ACL.PERMISSION_FULL_CONTROL }
   * @throws SQLException
   * @since 3.0
   */
  public int getGroupPermissions(Connection oConn, String sIdGroup) throws SQLException {
    int iACLMask;
    CallableStatement oCall;
    Statement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.getGroupPermissions([Connection], " + sIdGroup + ")" );
       DebugFile.incIdent();
    }

    if (oConn.getMetaData().getDatabaseProductName().equals("PostgreSQL")) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT k_sp_cat_grp_perm ('" + sIdGroup + "','" + getStringNull(DB.gu_category,"null") + "'))");

      oRSet = oStmt.executeQuery("SELECT k_sp_cat_grp_perm ('" + sIdGroup + "','" + getString(DB.gu_category) + "')");
      oRSet.next();
      iACLMask = oRSet.getInt(1);
      oRSet.close();
      oStmt.close();
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_cat_grp_perm('" + sIdGroup + "','" + getStringNull(DB.gu_category,null) + "',?) })");

      oCall = oConn.prepareCall("{ call k_sp_cat_grp_perm(?,?,?) }");
      oCall.setString(1, sIdGroup);
      oCall.setString(2, getString(DB.gu_category));
      oCall.registerOutParameter(3, java.sql.Types.INTEGER);
      oCall.execute();
      iACLMask = oCall.getInt(3);
      oCall.close();
    }

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Category.getGroupPermissions() : " + String.valueOf(iACLMask));
     }

    return iACLMask;
  } // getGroupPermissions()

  // ----------------------------------------------------------

  /**
   * <p>Remove permissions for user at a Category.</p>
   * Calls k_sp_cat_del_usr.<br>
   * Only permissions directly granted to user are removed.<br>
   * Permissions obtained by belonging to a Group remain active.<br>
   * @param oConn Database Connection
   * @param sIdUsers String of user GUIDs separated by commas.
   * @param iRecurse Remove permissions from child categories.
   * @param iObjects Not used, must be zero.
   * @throws SQLException
   */
  public void removeUserPermissions(Connection oConn, String sIdUsers, short iRecurse, short iObjects) throws SQLException {
    CallableStatement oStmt;
    StringTokenizer oUsrTok;
    int iTokCount;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.removeUserPermissions([Connection], " + sIdUsers + "," + iRecurse + "," + iObjects + ")" );
       DebugFile.incIdent();
       DebugFile.writeln("Connection.prepareCall({ call k_sp_cat_del_usr ('" + getStringNull(DB.gu_category, "null") + "',?," + String.valueOf(iRecurse) + "," + String.valueOf(iObjects) + ") }");
     }

    if (oConn.getMetaData().getDatabaseProductName().equals("PostgreSQL"))
      oStmt = oConn.prepareCall("{ call k_sp_cat_del_usr ('" + getString(DB.gu_category) + "',?, CAST(" + String.valueOf(iRecurse) + " AS SMALLINT), CAST(" + String.valueOf(iObjects) + " AS SMALLINT)) }");
    else
      oStmt = oConn.prepareCall("{ call k_sp_cat_del_usr ('" + getString(DB.gu_category) + "',?," + String.valueOf(iRecurse) + "," + String.valueOf(iObjects) + ") }");

    if (sIdUsers.indexOf(',')>=0) {
      oUsrTok = new StringTokenizer(sIdUsers, ",");
      iTokCount = oUsrTok.countTokens();

      for (int t=0; t<iTokCount; t++) {
        oStmt.setString(1, oUsrTok.nextToken());
        oStmt.execute();
      } // end for ()

      oStmt.close();
    }
    else {
      oStmt.setString(1, sIdUsers);
      oStmt.execute();
      oStmt.close();
    }

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Category.Category.removeUserPermissions()");
     }
  } // removeUserPermissions

  // ----------------------------------------------------------

  /**
   * <p>Set user permissions for a Category.</p>
   * Calls k_sp_cat_set_usr stored procedure.
   * @param oConn Database Connection
   * @param sIdUsers String of user GUIDs separated by commas.
   * @param iACLMask Permissions mask. Any combination of:
   * { ACL.PERMISSION_LIST, ACL.PERMISSION_READ,ACL.PERMISSION_ADD,
   * ACL.PERMISSION_DELETE,ACL.PERMISSION_MODIFY, ACL.PERMISSION_MODERATE,
   * ACL.PERMISSION_SEND,ACL.PERMISSION_GRANT,ACL.PERMISSION_FULL_CONTROL }
   * @param iRecurse Remove permissions from child categories.
   * @param iObjects Not used, must be zero.
   * @throws SQLException
   */
  public void setUserPermissions(Connection oConn, String sIdUsers, int iACLMask, short iRecurse, short iObjects) throws SQLException {
    PreparedStatement oStmt = null;
    CallableStatement oCall = null;
    StringTokenizer oUsrTok;
    String sSQL;
    String sUserId;
    int iTokCount;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.setUserPermissions([Connection], " + sIdUsers + "," + iACLMask + "," + iRecurse + "," + iObjects + ")" );
       DebugFile.incIdent();
       DebugFile.writeln("  " + DB.gu_category + "=" + getStringNull(DB.gu_category, "null"));
     }

    if (oConn.getMetaData().getDatabaseProductName().equalsIgnoreCase("PostgreSQL")) {
      sSQL = "SELECT k_sp_cat_set_usr (?,?," + String.valueOf(iACLMask) + ", CAST(" + String.valueOf(iRecurse) + " AS SMALLINT), CAST(" + String.valueOf(iObjects) + " AS SMALLINT))";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");
      oStmt = oConn.prepareStatement(sSQL);
    } else {
      sSQL = "{ call k_sp_cat_set_usr (?,?," + String.valueOf(iACLMask) + "," + String.valueOf(iRecurse) + "," + String.valueOf(iObjects) + ") }";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall(" + sSQL + ")");
      oCall = oConn.prepareCall(sSQL);
    }

    if (sIdUsers.indexOf(',')>0) {
      oUsrTok = new StringTokenizer(sIdUsers, ",");
      iTokCount = oUsrTok.countTokens();

      for (int t=0; t<iTokCount; t++) {
        sUserId = oUsrTok.nextToken();

        if (DebugFile.trace) DebugFile.writeln("binding user " + String.valueOf(t+1) + "/" + String.valueOf(iTokCount) + " " + sUserId);

		if (null!=oCall) {
          oCall.setString(1, getString(DB.gu_category));
          oCall.setString(2, sUserId);
          oCall.execute();
		} else {
          oStmt.setObject(1, getString(DB.gu_category), java.sql.Types.CHAR);
          oStmt.setObject(2, sUserId, java.sql.Types.CHAR);
          oStmt.executeQuery().close();
		}
      } // end for ()

    } else {

      if (DebugFile.trace) DebugFile.writeln("binding user " + sIdUsers);

	  if (null!=oCall) {
        oCall.setString(1, getString(DB.gu_category));
        oCall.setString(2, sIdUsers);
        if (DebugFile.trace) DebugFile.writeln("CallableStatement.execute()");
        oCall.execute();
	  } else {
        oStmt.setObject(1, getString(DB.gu_category), java.sql.Types.CHAR);
        oStmt.setObject(2, sIdUsers, java.sql.Types.CHAR);
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");
        oStmt.executeQuery().close();
	  }
    }

    if (DebugFile.trace) DebugFile.writeln("Statement.close()");

    if (null!=oCall) oCall.close();
    if (null!=oStmt) oStmt.close();

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Category.setUserPermissions()");
     }
  } // setUserPermissions

  // ----------------------------------------------------------

  /**
   * <p>Inherits permissions from another Category.</p>
   * All previous permissions on this Category are removed before copying
   * permission from the other Category.
   * @param oConn Database Connection
   * @param sFromCategory GUID of category with permissions to be inherited.
   * @param iRecurse Propagate permissions to child categories.
   * @param iObjects Not used, must be zero.
   * @throws SQLException
   */
  public void inheritPermissions(JDCConnection oConn, String sFromCategory, short iRecurse, short iObjects) throws SQLException {
    int i;
    int iUsrPerms;
    int iGrpPerms;
    String sIdCategory = getString(DB.gu_category);
    DBSubset oUsrPerms = new DBSubset(DB.k_x_cat_user_acl, DB.gu_user + "," + DB.acl_mask, DB.gu_category + "='" + sFromCategory + "'", 100);
    DBSubset oGrpPerms = new DBSubset(DB.k_x_cat_group_acl, DB.gu_acl_group + "," + DB.acl_mask, DB.gu_category + "='" + sFromCategory + "'", 100);
    Statement oDelete = oConn.createStatement();
    PreparedStatement oInsert;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.inheritPermissions([Connection], " + sFromCategory + "," + iRecurse + "," + iObjects + ")" );
       DebugFile.incIdent();
     }

    if (DebugFile.trace) DebugFile.writeln("  loading user permissions from " + DB.k_x_cat_user_acl);

    iUsrPerms = oUsrPerms.load(oConn);

    if (DebugFile.trace) DebugFile.writeln("  loading group permissions from " + DB.k_x_cat_group_acl);

    iGrpPerms = oGrpPerms.load(oConn);

    if (DebugFile.trace) DebugFile.writeln("  Connection.executeUpdate(" + "DELETE FROM " + DB.k_x_cat_user_acl + " WHERE " + DB.gu_category + "='" + sIdCategory + "')");

    oDelete.executeUpdate("DELETE FROM " + DB.k_x_cat_user_acl + " WHERE " + DB.gu_category + "='" + sIdCategory + "'");

    if (DebugFile.trace) DebugFile.writeln("  Connection.executeUpdate(" + "DELETE FROM " + DB.k_x_cat_group_acl + " WHERE " + DB.gu_category + "='" + sIdCategory + "')");

    oDelete.executeUpdate("DELETE FROM " + DB.k_x_cat_group_acl + " WHERE " + DB.gu_category + "='" + sIdCategory + "'");

    oDelete.close();
    oDelete = null;

    if (DebugFile.trace) DebugFile.writeln("  Connection.prepareStatement(" + "INSERT INTO " + DB.k_x_cat_user_acl + "(" + DB.gu_category + "," + DB.gu_user + "," + DB.acl_mask + ") VALUES (?,?,?))");

    oInsert = oConn.prepareStatement("INSERT INTO " + DB.k_x_cat_user_acl + "(" + DB.gu_category + "," + DB.gu_user + "," + DB.acl_mask + ") VALUES (?,?,?)");

    for (i=0; i<iUsrPerms; i++) {
      oInsert.setString(1, sIdCategory );
      oInsert.setString(2, oUsrPerms.getString(0,i) );
      oInsert.setInt(3, oUsrPerms.getInt(1,i) );

      if (DebugFile.trace) DebugFile.writeln("    PreparedStatement.executeUpdate(" + sIdCategory + "," + oUsrPerms.getString(0,i) + "," + oUsrPerms.getInt(1,i) + ")");
      oInsert.executeUpdate();
      oInsert.close();
    }

    if (DebugFile.trace) DebugFile.writeln("  Connection.prepareStatement(" + "INSERT INTO " + DB.k_x_cat_group_acl + "(" + DB.gu_category + "," + DB.gu_acl_group + "," + DB.acl_mask + ") VALUES (?,?,?))");

    oInsert = oConn.prepareStatement("INSERT INTO " + DB.k_x_cat_group_acl + "(" + DB.gu_category + "," + DB.gu_acl_group + "," + DB.acl_mask + ") VALUES (?,?,?)");
    for (i=0; i<iGrpPerms; i++) {
      oInsert.setString(1, sIdCategory );
      oInsert.setString(2, oGrpPerms.getString(0,i) );
      oInsert.setInt(3, oGrpPerms.getInt(1,i) );

      if (DebugFile.trace) DebugFile.writeln("    PreparedStatement.executeUpdate(" + sIdCategory + "," + oGrpPerms.getString(0,i) + "," + oGrpPerms.getInt(1,i) + ")");
      oInsert.executeUpdate();
      oInsert.close();
    }

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Category.inheritPermissions()");
     }
  } // inheritPermissions

  // ----------------------------------------------------------

  /**
   * Get whether or not this category descends at any level from another one.
   * @param oConn Database Connection
   * @param sParentCategory Parent category
   * @return <b>true</b> if this category descends at any level of depth from sParentCategory.
   * @throws SQLException
   */
  public boolean isChildOf(Connection oConn, String sParentCategory) throws SQLException {
    String sSelfId = getString(DB.gu_category);
    String sChild;
    boolean isChild = false;
    boolean bDoNext;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.gu_child_cat + " FROM " + DB.k_cat_tree + " WHERE " + DB.gu_parent_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    ResultSet oRSet;

    do {
      oStmt.setString(1, sParentCategory);
      oRSet = oStmt.executeQuery();
      bDoNext = oRSet.next();
      if (bDoNext)
        sChild = oRSet.getString(1);
      else
        sChild = "-1";
      oRSet.close();

      if (bDoNext) {
        if (sChild.equals(sParentCategory)) {
          bDoNext = false;
        }
        else if (sChild.equals(sSelfId)) {
          isChild = true;
          bDoNext = false;
        }
        else {
          sParentCategory = sChild;
        }
      } // endif (bDoNext)
    } while (bDoNext);

    oStmt.close();

    return isChild;
  } // isChildOf

  // ----------------------------------------------------------

  /**
   * Get whether or not this category is parent at any level of another one.
   * @param oConn Database Connection
   * @param sChildCategory Child Category GUID
   * @return <b>true</b> if this category is parent at any level.
   * @throws SQLException
   */
  public boolean isParentOf(Connection oConn, String sChildCategory) throws SQLException {
    String sSelfId;
    String sParnt;
    boolean isParent = false;
    boolean bDoNext;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.gu_parent_cat + " FROM " + DB.k_cat_tree + " WHERE " + DB.gu_child_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    ResultSet oRSet;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.isParentOf(" + sChildCategory + ")");
       DebugFile.incIdent();
    }

    sSelfId = getString(DB.gu_category);

    if (DebugFile.trace) DebugFile.writeln("  " + DB.gu_category + " = " + sSelfId);

    do {
      oStmt.setString(1, sChildCategory);
      oRSet = oStmt.executeQuery();
      bDoNext = oRSet.next();
      if (bDoNext)
        sParnt = oRSet.getString(1);
      else
        sParnt = "-1";
      oRSet.close();

      if (DebugFile.trace) DebugFile.writeln("  id_parent = " + sParnt);

      if (bDoNext) {
        if (sParnt.equals(sChildCategory)) {
          bDoNext = false;
        }
        else if (sParnt.equals(sSelfId)) {
          isParent = true;
          bDoNext = false;
        }
        else {
          sChildCategory = sParnt;
        }
      } // endif (bDoNext)
    } while (bDoNext);

    oStmt.close();

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Category.isParentOf() : " + isParent);
     }

    return isParent;
  } // isParentOf

  // ----------------------------------------------------------

  /**
   * <p>Get category depth level.</p>
   * Calls k_sp_cat_level stored procedure.<br>
   * Root Categories have level 1.
   * @param oConn Database Connection
   * @return Category depth evel starting at 1.
   * @throws SQLException
   */
  public int level(JDCConnection oConn) throws SQLException {
    int iLevel;
    CallableStatement oCall;
    Statement oStmt;
    ResultSet oRSet;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT k_sp_cat_level('" + getString(DB.gu_category) + "')");
      oRSet.next();
      iLevel = oRSet.getInt(1);
      oRSet.close();
      oStmt.close();
    }
    else {
      oCall = oConn.prepareCall("{ call k_sp_cat_level(?,?)}");
      oCall.setString(1, getString(DB.gu_category));
      oCall.registerOutParameter(2, java.sql.Types.INTEGER);
      oCall.execute();
      iLevel = oCall.getInt(2);
      oCall.close();
    }

    return iLevel;
  } // level

  // ----------------------------------------------------------

  /**
   * @param oConn Database Connection
   * @return <b>true</b> if Category is present at k_cat_root table.
   * @throws SQLException
   */
  public boolean getIsRoot(Connection oConn) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    boolean bRoot = false;

    // Begin SQLException
      oStmt = oConn.createStatement();
      oRSet = oStmt.executeQuery("SELECT " + DB.gu_category + " FROM " + DB.k_cat_root + " WHERE " + DB.gu_category + "='" + getString(DB.gu_category) + "'");

      bRoot = oRSet.next();

      oRSet.close();
      oStmt.close();
    // End SQLException

    return bRoot;
  } // getIsRoot

  // ----------------------------------------------------------

  /**
   * Make or unmake a root category.
   * @param oConn Database Connection
   * @param bIsRoot <b>true</b> if category is to be made root.
   * @throws SQLException If This Category is present as a child of another
   * category at k_cat_tree table.
   */
  public void setIsRoot(Connection oConn, boolean bIsRoot) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    boolean bIsChild;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.setIsRoot([Connection], " + String.valueOf(bIsRoot) + ")" );
      DebugFile.incIdent();
      }

    // Begin SQLException
      if (bIsRoot) {
        oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT NULL FROM " + DB.k_cat_tree + " WHERE " + DB.gu_child_cat + "='" + getStringNull(DB.gu_category,"null") + "')");
        oRSet = oStmt.executeQuery("SELECT NULL FROM " + DB.k_cat_tree + " WHERE " + DB.gu_child_cat + "='" + getString(DB.gu_category) + "'");
        bIsChild = oRSet.next();
        oRSet.close();
        oStmt.close();

        if (bIsChild)
          throw new SQLException("Category cannot be set Root if present as a child at k_cat_tree table");
      }

      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_cat_root + " WHERE " + DB.gu_category + "='" + getStringNull(DB.gu_category, "null") + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_cat_root + " WHERE " + DB.gu_category + "='" + getString(DB.gu_category) + "'");

      if (bIsRoot) {
        if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(INSERT INTO " + DB.k_cat_root + "(" + DB.gu_category + ") VALUES ('" + getStringNull(DB.gu_category, "null") + "')");

        oStmt.executeUpdate("INSERT INTO " + DB.k_cat_root + "(" + DB.gu_category + ") VALUES ('" + getString(DB.gu_category) + "')");
      }

      oStmt.close();
    // End SQLException

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.setIsRoot()");
      }
  } // setIsRoot

  // ----------------------------------------------------------
  /**
   * Get translated label for a category.
   * @param oConn Database Connection
   * @param sLanguage Language code from k_lu_languages table.
   * @return Translated label or <b>null</b> if no translated label for such
   * language was found at k_cat_labels table.
   * @throws SQLException
   */
  public String getLabel(Connection oConn, String sLanguage) throws SQLException {
    String sTr;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.getLabel([Connection], " + sLanguage + ")" );
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.tr_category + " FROM " + DB.k_cat_labels + " WHERE " + DB.gu_category + "='" + get(DB.gu_category) + "' AND " + DB.id_language + "='" + Gadgets.left(sLanguage,2).toLowerCase() + "'");
      }

    PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.tr_category + " FROM " + DB.k_cat_labels + " WHERE " + DB.gu_category + "=? AND " + DB.id_language + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getString(DB.gu_category));
    oStmt.setString(2, Gadgets.left(sLanguage,2).toLowerCase());

    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sTr = oRSet.getString(1);
    else
      sTr = null;
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.getLabel() : " + sTr);
    }

    return sTr;
  } // getLabel()

  // ----------------------------------------------------------

  /**
   * Set category label for all supported languages
   * @param oConn Database connection
   * @param sTr Label
   * @throws SQLException
   * @throws NullPointerException if label is null or empty string
   * @since 5.0
   */
  public void setLabel(Connection oConn, String sTr) throws SQLException {
	
	if (null==sTr) throw new NullPointerException("Category.setLabel() Label string may not be null");
	if (sTr.length()==0) throw new NullPointerException("Category.setLabel() Label string may not be empty");

    sTr = Gadgets.left(sTr,30);
    
    PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_cat_labels+" WHERE "+DB.gu_category+"=?");
    oStmt.setString(1, getString(DB.gu_category));
    oStmt.executeUpdate();
    oStmt.close();

    oStmt = oConn.prepareStatement("INSERT INTO "+DB.k_cat_labels+" ("+DB.gu_category+","+DB.id_language+","+DB.tr_category+") VALUES (?,?,?)");
    final int nLangs = DBLanguages.SupportedLanguages.length;
    for (int l=0; l<nLangs; l++) {
      oStmt.setString(1, getString(DB.gu_category));
      oStmt.setString(2, DBLanguages.SupportedLanguages[l]);
      oStmt.setString(3, sTr);
      oStmt.executeUpdate();
    } // next
    oStmt.close();    
  } // setLabel
  
  // ----------------------------------------------------------

  /**
   * <p>Get Category translated labels as a DBSubset.</p>
   * @param oConn Database Connection
   * @return DBSubset with columns:<br>
   * <table border=1 cellpadding=4>
   * <tr><td><b>id_language</b></td><td><b>tr_category</b></td><td><b>url_category</b></td></tr>
   * <tr><td>2 chras. Lang. Id.</td><td>Translated Category Name</td><td>URL for Category</td></tr>
   * </table>
   * @throws SQLException
   */
  public DBSubset getNames(JDCConnection oConn) throws SQLException {
    Object aCatg[] = { get(DB.gu_category) };

    oNames = new DBSubset(DB.k_cat_labels, DB.id_language + "," + DB.tr_category + "," + DB.url_category, DB.gu_category + "=?", 4);
    oNames.load (oConn, aCatg);

    return oNames;
  } // getNames

  // ----------------------------------------------------------

  /**
   * <p>Get first level childs as a DBSubset.</p>
   * @param oConn Database Connection
   * @return Single column DBSubset with child GUIDs
   * @throws SQLException
   */
  public DBSubset getChilds(JDCConnection oConn) throws SQLException {
    Object aCatg[] = { get(DB.gu_category) };

    oChilds = new DBSubset(DB.k_cat_tree, DB.gu_child_cat, DB.gu_parent_cat + "=?",1);

    oChilds.load (oConn, aCatg);

    return oChilds;
  } // getChilds

  // ----------------------------------------------------------

  /**
   * <p>Get inmediate parents as a DBSubset.</p>
   * @param oConn Database Connection
   * @return Single column DBSubset with parent GUIDs
   * @throws SQLException
   */
  public DBSubset getParents(JDCConnection oConn) throws SQLException {
    Object aCatg[] = { get(DB.gu_category) };

    oParents = new DBSubset(DB.k_cat_tree, DB.gu_parent_cat, DB.gu_child_cat + "=?", 1);
    oParents.load (oConn, aCatg);

    return oParents;
  } // getParents

  // ----------------------------------------------------------

  /**
   * Get objects contained at Category.
   * @param oConn Database Connection
   * @return DBSubset with columns:
   * <table border=1 cellpadding=4>
   * <tr><td><b>gu_object</b></td><td><b>id_class</b></td><td><b>bi_attribs</b></td></tr>
   * </table>
   * @throws SQLException
   */
  public DBSubset getObjects(JDCConnection oConn) throws SQLException {
    DBSubset oObjs = new DBSubset(DB.k_x_cat_objs, DB.gu_object + "," + DB.id_class + "," + DB.bi_attribs,    				
                         DB.gu_category + "=? ORDER BY " + DB.od_position, 64);

    oObjs.load(oConn, new Object[]{getString(DB.gu_category)});

    return oObjs;
  } // getObjects

  // ----------------------------------------------------------

  /**
   * Get objects contained at Category.
   * @param oConn Database Connection
   * @param Numeric identifier of class to get (ClassId member variable value)
   * @return DBSubset with columns:
   * <table border=1 cellpadding=4>
   * <tr><td><b>gu_object</b></td><td><b>id_class</b></td><td><b>bi_attribs</b></td></tr>
   * </table>
   * @throws SQLException
   * @since 4.0
   */
  public DBSubset getObjectsOfClass(JDCConnection oConn, short iClassId) throws SQLException {
    DBSubset oObjs;
    
    if (Product.ClassId==iClassId) {
  	  Product oProd = new Product();
      try {
        oObjs = new DBSubset(DB.k_x_cat_objs+" x, "+DB.k_products+" p",
      					     "x." + DB.gu_object + ",x." + DB.id_class + ",x." + DB.bi_attribs + "," +
     					     "p."+Gadgets.replace(oProd.getTable(oConn).getColumnsStr(),",",",p."),
     					     "x."+DB.gu_object+"=p."+DB.gu_product+" AND "+
    					     "x."+DB.id_class+"=? AND x."+DB.gu_category + "=? ORDER BY " + DB.od_position, 64);
      } catch (Exception neverthrown) { oObjs=null; }
    } else {
      oObjs = new DBSubset(DB.k_x_cat_objs, DB.gu_object + "," + DB.id_class + "," + DB.bi_attribs,
    					   DB.id_class+"=? AND "+DB.gu_category + "=? ORDER BY " + DB.od_position, 64);
    }

    oObjs.load(oConn, new Object[]{new Short(iClassId), getString(DB.gu_category)});

    return oObjs;
  } // getObjectsOfClass

  // ----------------------------------------------------------

  /**
   * </p>Get Products contained at this Category</p>
   * @param oConn Database Connection
   * @param sOrderBy Column to sort the products { od_position, nm_product, pr_list, pr_sale, ... }
   * If <b>null</b> no sorting is performed
   * @return Array of Product instances or <b>null</b> if this Category contains no products
   * @throws SQLException
   * @since 4.0
   */
  public Product[] getProducts (JDCConnection oConn, String sOrderBy) throws SQLException {
  	Product oProd = new Product();
    Product[] aProds = null;
    DBSubset oProds = null;
	String sOrderClause;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.getProducts([Connection], " + sOrderBy + ")" );
      DebugFile.incIdent();
    }
    	
	if (null==sOrderBy)
	  sOrderClause = "";
	else
	  sOrderClause = " ORDER BY " + (sOrderBy.equalsIgnoreCase(DB.od_position) ? "x." : "p.") + sOrderBy;

    try {
      oProds = new DBSubset(DB.k_x_cat_objs+" x, "+DB.k_products+" p",
     					    "p."+Gadgets.replace(oProd.getTable(oConn).getColumnsStr(),",",",p."),
     					    "x."+DB.gu_object+"=p."+DB.gu_product+" AND "+
    					    "x."+DB.id_class+"="+String.valueOf(Product.ClassId)+" AND x."+DB.gu_category + "=? "+sOrderClause, 64);
    } catch (Exception neverthrown) {}

    oProds.load(oConn, new Object[]{getString(DB.gu_category)});
    int nProds = oProds.getRowCount();
    if (0!=nProds) {
	  aProds = new Product[nProds];
	  for (int p=0; p<nProds; p++) {
	    aProds[p] = new Product();
	    aProds[p].putAll(oProds.getRowAsMap(p));
 	  } // next
    } // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==aProds)
        DebugFile.writeln("End Category.getProducts() : null");
	  else
        DebugFile.writeln("End Category.getProducts() : "+String.valueOf(aProds.length));	  	
    }

    return aProds;
  } // getProducts
  // ----------------------------------------------------------

  /**
   * Get Groups with permissions over this Category.
   * @param oConn Database Connection
   * @return A DBSubset with 2 columns: gu_acl_group, acl_mask
   * @throws SQLException
   */
  public DBSubset getACLGroups(JDCConnection oConn) throws SQLException {
    Object aCatg[] = { get(DB.gu_category) };

    oACLGroups = new DBSubset(DB.k_x_cat_group_acl, DB.gu_acl_group + "," + DB.acl_mask, DB.gu_category + "=?", 50);
    oACLGroups.load (oConn, aCatg);

    return oACLGroups;
  } // getACLGroups

  // ----------------------------------------------------------

  /**
   * Get Users with direct permissions over this Category.
   * @param oConn Database Connection
   * @return A DBSubset with 2 columns: gu_user, acl_mask
   * @throws SQLException
   */
  public DBSubset getACLUsers(JDCConnection oConn) throws SQLException {
    Object aCatg[] = { get("id_category") };

    oACLUsers = new DBSubset(DB.k_x_cat_user_acl, DB.gu_user + "," + DB.acl_mask, DB.gu_category + "=?", 100);
    oACLUsers.load (oConn, aCatg);

    return oACLUsers;
  } // getACLUsers

  // ----------------------------------------------------------

  /**
   * Get integer indentifier of the domain to which this category belongs
   * @param JDCConnection
   * @return id_domain
   * @throws SQLException
   * @throws IllegalStateException
   * @since 4.0
   */
  public int getDomainId (JDCConnection oConn) throws SQLException, IllegalStateException {
    
    if (isNull(DB.gu_owner)) throw new IllegalStateException("Category.getDomainId() gu_owner field not found, Category must be loaded before calling getDomainId function");
    
    PreparedStatement oStmt = oConn.prepareStatement("SELECT d."+DB.id_domain+" FROM "+DB.k_domains+" d, "+DB.k_users+" u WHERE u."+DB.gu_user+"=? AND d."+DB.id_domain+"=u."+DB.id_domain,
    						  ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getString(DB.gu_owner));
	ResultSet oRSet = oStmt.executeQuery();
	oRSet.next();
	int iDomainId = oRSet.getInt(1);
	oRSet.close();
	oStmt.close();
	return iDomainId;
  } // getDomainId
  
  // ----------------------------------------------------------

  /**
   * <p>Set New Parent for this category.</p>
   * The old parent (if any) is not changed nor removed.<br>
   * If Category is already a child of selected parent method proceeds silently
   * and no error is raised.
   * @param oConn Database Connection
   * @param sIdParent GUID of parent Category
   * @throws SQLException
   */
  public void setParent(Connection oConn, String sIdParent) throws SQLException {
    Statement oStmt = oConn.createStatement();
    ResultSet oRSet;
    String sSQL;
    boolean bAlreadyExists;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.setParent([Connection], " + sIdParent + ")" );
      DebugFile.incIdent();
      }

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    sSQL = "SELECT NULL FROM " + DB.k_cat_tree + " WHERE " + DB.gu_parent_cat + "='" + sIdParent + "' AND " + DB.gu_child_cat + "='" + getString(DB.gu_category) + "'";
    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" +  sSQL + ")");
    oRSet = oStmt.executeQuery(sSQL);
    bAlreadyExists = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (!bAlreadyExists) {
      oStmt = oConn.createStatement();
      sSQL = "INSERT INTO " + DB.k_cat_tree + " (" + DB.gu_parent_cat + "," + DB.gu_child_cat + ") VALUES ('" + sIdParent + "','" + getString(DB.gu_category) + "')";
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" +  sSQL + ")");
      oStmt.execute(sSQL);
      oStmt.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.setParent()");
      }
  } // setParent

  // ----------------------------------------------------------

  /**
   * <p>Remove Category from parent.</p>
   * Removing a Category from a parent does not delete it.
   * @param oConn Database Connection
   * @param sIdParent Parent Category GUID
   * @throws SQLException
   */
  public void resetParent(Connection oConn, String sIdParent) throws SQLException {
    Statement oStmt = oConn.createStatement();
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.resetParent([Connection], " + sIdParent + ")" );
      DebugFile.incIdent();
      }

    sSQL = "DELETE FROM " + DB.k_cat_tree + " WHERE " + DB.gu_parent_cat + "='" + sIdParent + "' AND " + DB.gu_child_cat + "='" + getString(DB.gu_category) + "'";

    if (DebugFile.trace) DebugFile.writeln("oStmt.executeUpdate(" +  sSQL + ")");

    oStmt.executeUpdate(sSQL);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.resetParent()");
      }
  } // resetParent

  // ----------------------------------------------------------

  /**
   * <p>Store Category.</p>
   * If gu_category is null a new GUID is automatically assigned.<br>
   * dt_modified field is set to current date.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    // Si no se especificó un identificador para la categoria
    // entonces añadirlo autimaticamente
    if (!AllVals.containsKey(DB.gu_category))
      put(DB.gu_category, Gadgets.generateUUID());

    // Forzar la fecha de modificación del registro
    replace(DB.dt_modified, dtNow);

    return super.store(oConn);
  } // store

  // ----------------------------------------------------------

  /**
   * <p>Expand all Category childs.</p>
   * Calls k_sp_cat_expand stored procedure.<br>
   * Expansion tree is stored at k_cat_expand table.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public void expand(Connection oConn) throws SQLException {
    CallableStatement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.expand([Connection])");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareCall({ call k_sp_cat_expand ('" + getStringNull(DB.gu_category,"null") + "')}");
    }

    oStmt = oConn.prepareCall("{ call k_sp_cat_expand ('" + getString(DB.gu_category) + "') }");
    oStmt.execute();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.expand()");
    }
  } // expand()

  // ----------------------------------------------------------

  /**
   * <p>Store a set of labels for this category</p>
   * This method takes a string of the form "en;Root|es;Raíz|fr;Racine|it;Radice|ru;\u041A\u043E\u0440\u0435\u043D\u044C"
   * and store one label for each {language,literal} pair
   * @param oConn JDCConnection
   * @param sNamesTable String Language names and translated names
   * @param sRowDelim String Delimiter for {language,literal} pairs,
   * in the example above it would be "|"
   * @param sColDelim String Delimiter between language and literal,
   * in the example above  it would be ";"
   * @throws SQLException
   * @throws NoSuchElementException
   */
  public void storeLabels(JDCConnection oConn, String sNamesTable,
                          String sRowDelim, String sColDelim)
      throws SQLException, NoSuchElementException {
    String sName;
    String sLanguageId;
    String sTrCategory;
    int iTokCount;
    StringTokenizer oRowTok;
    StringTokenizer oColTok;
    CategoryLabel oName = new CategoryLabel();

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.storeLabels([Connection], \"" + sNamesTable + "\",\"" + sRowDelim + "\",\"" + sColDelim + "\")");
      DebugFile.incIdent();
    }

    if (sNamesTable.length()>0) {
      oName.put (DB.gu_category, getString(DB.gu_category));

      // Sacar el idioma y la lista de etiquetas del String recibido como parametro.

      if (DebugFile.trace) DebugFile.writeln("new StringTokenizer(" + sNamesTable + "\"" + sRowDelim + "\"");

      oRowTok = new StringTokenizer(sNamesTable, sRowDelim);

      iTokCount = oRowTok.countTokens();

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iTokCount) + " tokens found");

      for (int r=0; r<iTokCount; r++) {
        // Separar los registros
        sName = oRowTok.nextToken();

        if (DebugFile.trace) DebugFile.writeln("new StringTokenizer(" + sName + ", \"" + sColDelim + "\"");

        // Para cada registro separar los campos
        String[] aPair = Gadgets.split2(sName,sColDelim);
		
		if (aPair.length<2) throw new NoSuchElementException("Invalid language value pair "+sName);
		
		sLanguageId = aPair[0];
		sTrCategory = aPair[1];

        if (sTrCategory!=null) {
          sTrCategory = sTrCategory.trim();

          if (sTrCategory.length()>0) {
            oName.replace(DB.id_language, sLanguageId);
            oName.replace(DB.tr_category, sTrCategory);

            if (DebugFile.trace) DebugFile.writeln("CategoryLabel.store("+ sLanguageId + "," + sTrCategory + ")");

            oName.store(oConn);
          }
        } // fi (tr_category!=null)
      } // endfor (r)
    } // fi (sNamesTable!="")

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.storeLabels()");
    }
  } // storeLabels()

  // ----------------------------------------------------------

  /**
   * <p>Copy a directory and index all its files as products inside this Category</p>
   * @param oConn JDCConnection Any pending transaction on given connection will be commited.
   * This methods calls Connection.commit() on oConn object,
   * so AutoCommit status for connection must be set to true before calling uploadDirectory()
   * @param sSourcePath String "file:///tmp/upload/myfiles"
   * @param sProtocol String "file://"
   * @param sServer String Server name (for FTP transfers)
   * @param sTargetPath String "file:///opt/hipergate/storege/domains/2050/..."
   * @param sLanguage String
   * @throws Exception
   * @throws IOException
   * @throws SQLException
   */
  public void uploadDirectory (JDCConnection oConn, String sSourcePath, String sProtocol,
                               String sServer, String sTargetPath, String sLanguage)
    throws Exception, IOException, SQLException {
    File oDir, oFile;
    File aFiles[];
    int iFiles;
    String sFileName, sBasePath, sTargetChomp, sNewCategoryId, sNewCategoryNm;
    Properties oURLProps;
    FileInputStream oIOStrm;
    PreparedStatement oStmt, oCatg;
    ResultSet oRSet;

    Category oNewCategory;
    Product oProd;
    ProductLocation oLoca;

    Object aCatValues[];
    Object aLblValues[];
    Short iTrue = new Short((short)1);
    Integer iActive = new Integer(1);

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.uploadDirectory([Connection], " + sSourcePath + ", ..., " + sTargetPath + "," + sLanguage + ")" );
      DebugFile.incIdent();
    }

    if (null==oFS) {
      if (DebugFile.trace) DebugFile.writeln("new com.knowgate.dfs.FileSystem()");
      oFS = new FileSystem();
    }

    // Crea la ruta base quitando el file:// de por delante
    sBasePath = sSourcePath.substring(sSourcePath.indexOf("://")+3);

    if (DebugFile.trace) DebugFile.writeln("sBasePath=" + sBasePath);

    oProd = new Product();
    oProd.put(DB.gu_owner, getString(DB.gu_owner));

    // Obtiene un array con los archivos del directorio base
    oDir = new File(sBasePath);
    aFiles = oDir.listFiles();
    iFiles = aFiles.length;

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iFiles) + " files found");

    // Cursor preparado para leer los archivos de una categoría
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM " + DB.k_products + " p, " + DB.k_x_cat_objs + " o WHERE p." + DB.nm_product + "=? AND o." + DB.gu_category + "=? AND o." + DB.id_class + "=" + String.valueOf(Product.ClassId) + " AND p." + DB.gu_product + "=o." + DB.gu_object);
    oStmt = oConn.prepareStatement("SELECT " + DB.gu_product + " FROM " + DB.k_products + " p, " + DB.k_x_cat_objs + " o WHERE p." + DB.nm_product + "=? AND o." + DB.gu_category + "=? AND o." + DB.id_class + "=" + String.valueOf(Product.ClassId) + " AND p." + DB.gu_product + "=o." + DB.gu_object, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    // Cursor preparado para buscar una categoría hija por nombre traducido
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_category + " FROM " + DB.k_cat_tree + " t," + DB.k_cat_labels + " l WHERE t.gu_parent_cat=? AND l.tr_category=? AND t.gu_child_cat=l.gu_category");
    oCatg = oConn.prepareStatement("SELECT " + DB.gu_category + " FROM " + DB.k_cat_tree + " t," + DB.k_cat_labels + " l WHERE t." + DB.gu_parent_cat + "=? AND l." + DB.tr_category + "=? AND t." + DB.gu_child_cat + "=l." + DB.gu_category, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    for (int f=0; f<iFiles; f++) {
      oFile = aFiles[f];
      if (oFile.isFile()) {
        sFileName = oFile.getName();

        if (DebugFile.trace) DebugFile.writeln("nm_product=" + (sFileName.length()<=128 ? sFileName : sFileName.substring(0,128)));

        if (sFileName.toLowerCase().endsWith(".url"))
          // Si el archivo tiene extensión .url interpretarlo como un enlace
          oProd.put(DB.nm_product, (sFileName.length()<=128 ? sFileName.substring(0,sFileName.length()-4) : sFileName.substring(0,128)));
        else
          // Es un archivo físico
          oProd.put(DB.nm_product, (sFileName.length()<=128 ? sFileName : sFileName.substring(0,128)));

        // Guardar el archivo como un producto en la base de datos
        oStmt.setString(1, oProd.getString(DB.nm_product));
        oStmt.setString(2, getString(DB.gu_category));
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          oProd.put(DB.gu_product, oRSet.getString(1));
        oRSet.close();

        if (DebugFile.trace) DebugFile.writeln("oProd.store([Connection]);");
        oProd.store(oConn);

        // Añadir el producto a la categoría actual
        if (DebugFile.trace) DebugFile.writeln("oProd.addToCategory([Connection], " + getStringNull(DB.gu_category, "null") + ");");
        oProd.addToCategory(oConn, this.getString(DB.gu_category), 0);

        // Crear una nueva ubicación de producto para apuntar al archivo físico o al enlace
        oLoca = new ProductLocation();

        oLoca.put(DB.gu_owner, getString(DB.gu_owner));
        oLoca.put(DB.gu_product, oProd.get(DB.gu_product));

        if (sFileName.toLowerCase().endsWith(".url")) {
          // Si se trata de un archivo .url
          // abrirlo como un fichero de propiedades
          // para sacar los parámetros del enlace.
          oURLProps = new Properties();
          oIOStrm = new FileInputStream(oFile);
          oURLProps.load(oIOStrm);
          oIOStrm.close();

          if (DebugFile.trace) DebugFile.writeln("URL=" + oURLProps.getProperty("URL", "null"));

          oLoca.setURL(oURLProps.getProperty("URL"));
          oLoca.remove(DB.xfile);
          oLoca.remove(DB.xoriginalfile);

          oLoca.put(DB.id_cont_type, oLoca.getContainerType());
          oLoca.setLength(0);
          if (DebugFile.trace) DebugFile.writeln("oLoca.store([Connection])");
          oLoca.store(oConn);

          try { oConn.commit(); } catch (SQLException ignore) { /* Ignore exception if AutoCOmmit was already set to true*/}
        }
        else {
          // Si es una archivo físico moverlo de ubicación y apuntar su ruta en la base de datos
          oLoca.setPath (sProtocol, sServer, sTargetPath, sFileName, sFileName);
          oLoca.put(DB.id_cont_type, oLoca.getContainerType());
          oLoca.setLength(new Long(oFile.length()).intValue());

          if (DebugFile.trace) DebugFile.writeln("oLoca.store([Connection])");
          oLoca.store(oConn);

          try { oConn.commit(); } catch (SQLException ignore) { /* Ignore exception if AutoCOmmit was already set to true*/}

          // Coger el fichero "sSourcePath/sFileName" y moverlo a "sProtocol://sServer/sTargetPath/sFileName"
          // luego grabar en la base de datos su nueva ubicación física
          oLoca.upload(oConn, oFS, sSourcePath, sFileName, sProtocol + sServer + sTargetPath, sFileName);
        }
        oLoca = null;

        oProd.remove(DB.gu_product);
        oProd.remove(DB.nm_product);
      }
      else if (oFile.isDirectory()) {
        sFileName = oFile.getName();

        if (sProtocol.startsWith("file://"))
          sTargetChomp = (sTargetPath.endsWith(System.getProperty("file.separator")) ? sTargetPath : sTargetPath + System.getProperty("file.separator"));
        else
          sTargetChomp = (sTargetPath.endsWith("/") ? sTargetPath : sTargetPath + "/");

        oCatg.setString(1, getString(DB.gu_category));
        oCatg.setString(2, sFileName);
        oRSet = oCatg.executeQuery();
        if (oRSet.next()) {
          sNewCategoryId = oRSet.getString(1);
          oNewCategory = new Category(oConn, sNewCategoryId);
          sNewCategoryNm = oNewCategory.getString(DB.nm_category);

          // Crear el directorio espejo donde se almacenan los archivos (Productos) de la categoría
          oFS.mkdirs(sProtocol + sServer + sTargetChomp + sNewCategoryNm);
        }
        else {

          // Componer un nuevo alias (nombre corto único) para la categoria que representa el directorio
          sNewCategoryNm = Category.makeName(oConn, sFileName);

          if (DebugFile.trace) DebugFile.writeln("sNewCategoryNm=" + sNewCategoryNm);

          // Crear la categoría
          aCatValues = new Object[] { getString(DB.gu_category), getString(DB.gu_owner), sNewCategoryNm, iTrue, iActive, "folderclosed_16x16.gif", "folderopen_16x16.gif"};
          sNewCategoryId = Category.create(oConn, aCatValues);

          // Crear la etiqueta de nombre traducido para la categoría
          aLblValues = new Object[] { sNewCategoryId, sLanguage, sFileName, null };
          CategoryLabel.create(oConn, aLblValues);

          try { oConn.commit(); } catch (SQLException ignore) { /* Ignore exception if AutoCOmmit was already set to true*/}

          // Crear el directorio espejo donde se almacenan los archivos (Productos) de la categoría
          oFS.mkdirs(sProtocol + sServer + sTargetChomp + sNewCategoryNm);

          // Añadir archivos recursivamente
          oNewCategory = new Category(oConn, sNewCategoryId);
          oNewCategory.inheritPermissions(oConn, getString(DB.gu_category), (short)1, (short)1);
        }
        oRSet.close();

        oNewCategory.uploadDirectory(oConn, "file://" + oFile.getAbsolutePath(), sProtocol, sServer, sTargetChomp + sNewCategoryNm, sLanguage);
      }
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.uploadDirectory()");
      }

  } // uploadDirectory()

  // --------------------------------------------------------------------------
  
  /**
   * <p>Get an XML dump for the Category values plus nodes for translated labels</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @param sDelim Line delimiter (usually "\n" or "\r\n")
   * @return XML String
   * @since 4.0
   */
  public String toXMLWithLabels(JDCConnection oConn, String sIdent, String sDelim)
    throws SQLException, IllegalStateException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.toXMLWithLabels([Connection], ...)");
      DebugFile.incIdent();
    }
	  String sXML = toXML(sIdent, sDelim);
	  sXML = sXML.substring(0, sXML.indexOf("</"+sAuditCls+">"));
	  StringBuffer oStrBuff = new StringBuffer();
	  PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.id_language+","+DB.tr_category+","+DB.url_category+" FROM "+DB.k_cat_labels+" WHERE "+DB.gu_category + "=?",
	  												   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  oStmt.setObject(1, get(DB.gu_category), java.sql.Types.CHAR);      
	  ResultSet oRSet = oStmt.executeQuery();
	  oStrBuff.append(sIdent+"<labels>\n");
	  while (oRSet.next()) {
	    oStrBuff.append(sIdent+sIdent+"<label id_language=\"");
	    oStrBuff.append(oRSet.getString(1));
	    oStrBuff.append("\"><![CDATA[");
	    oStrBuff.append(oRSet.getString(2));
	    oStrBuff.append("]]></label>\n");
	  } // wend
	  oRSet.close();
	  oStrBuff.append(sIdent+"</labels>\n");
	  oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.toXMLWithLabels()");
    }
	return sXML+oStrBuff.toString()+"</"+sAuditCls+">";
  } // toXMLWithLabels

  // --------------------------------------------------------------------------
  
  /**
   * <p>Get an XML dump for the Category values plus nodes for translated labels</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @return XML String
   * @since 4.0
   */
  public String toXMLWithLabels(JDCConnection oConn, String sIdent)
    throws SQLException, IllegalStateException {
	return toXMLWithLabels(oConn, sIdent, "\n");
  }  

  // --------------------------------------------------------------------------
  
  /**
   * <p>Get an XML dump for the Category values plus nodes for translated labels</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @return XML String
   * @since 4.0
   */
  public String toXMLWithLabels(JDCConnection oConn)
    throws SQLException, IllegalStateException {
	return toXMLWithLabels(oConn, "  ", "\n");
  }  

  // --------------------------------------------------------------------------

  /**
   * Check-out all documents from this Category and all its subcategories
   * @param JDCConnection
   * @param sUserId GUID of user requesting check-out
   * @throws SecurityException if user does not have modify permission over any category containing this product
   * @throws IllegalStateException if product is already checked out by another user
   * @throws NullPointerException is sUserId is <b>null</b>
   * @throws SQLException
   * @since 4.0
   */
  public void checkOut(JDCConnection oConn, String sUserId)
  	throws SecurityException, SQLException, IllegalStateException, NullPointerException {

	if (null==sUserId)
	  throw new NullPointerException("Category.checkOut() User GUID may not be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Categrory.checkOut([JDCConnection]," + sUserId + ")" );
      DebugFile.incIdent();      
    }

	int iAppMask = getUserPermissions((oConn), sUserId);

    if (DebugFile.trace) {
      DebugFile.writeln("gu_category="+getString(DB.gu_category));
      DebugFile.writeln("appmask="+String.valueOf(iAppMask));
    }
    
	if ((iAppMask&ACL.PERMISSION_MODIFY)==0) {
	  throw new SecurityException("Product.checkOut() User does not have enought permissions to check-out documents from Category ");
	}

	Product[] aProds = getProducts(oConn, null);

	if (null!=aProds) {
	  int nProds = aProds.length;
	  PreparedStatement oUpdt = oConn.prepareStatement("UPDATE "+DB.k_products+" SET "+DB.gu_blockedby+"=? WHERE "+DB.gu_product+"=?");
	  for (int p=0; p<nProds; p++) {
	    if (aProds[p].isNull(DB.gu_blockedby)) {
		  oUpdt.setString(1, sUserId);
		  oUpdt.setString(2, aProds[p].getString(DB.gu_product));
		  oUpdt.executeUpdate();
	    } // fi (gu_blockedby is null)
	  } // next
	  oUpdt.close();
	} // fi (aProds)

	DBSubset oChilds = getChilds(oConn);
	
	if (null!=oChilds) {
	  int nChilds = oChilds.getRowCount();
	  Category oChld = new Category();
	  for (int c=0; c<nChilds; c++) {
	    oChld.replace(DB.gu_category, oChilds.getString(0,c));
	    oChld.checkOut(oConn, sUserId);
	  } // next
	} // fi (oChilds)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Categrory.checkOut()");
    }
  } // checkOut

  // --------------------------------------------------------------------------

  /**
   * Check-in all documents from this Category and all its subcategories
   * @param JDCConnection
   * @param sUserId GUID of user requesting check-out
   * @throws IllegalStateException if product is already checked out by another user
   * @throws NullPointerException is sUserId is <b>null</b>
   * @throws SQLException
   * @since 4.0
   */
  public void checkIn(JDCConnection oConn, String sUserId)
  	throws SQLException, IllegalStateException, NullPointerException {

	if (null==sUserId)
	  throw new NullPointerException("Category.checkIn() User GUID may not be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Categrory.checkIn([JDCConnection]," + sUserId + ")" );
      DebugFile.incIdent();      
    }

    if (DebugFile.trace) {
      DebugFile.writeln("gu_category="+getString(DB.gu_category));
    }

	Product[] aProds = getProducts(oConn, null);

	if (null!=aProds) {
	  int nProds = aProds.length;
	  PreparedStatement oUpdt = oConn.prepareStatement("UPDATE "+DB.k_products+" SET "+DB.gu_blockedby+"=NULL WHERE "+DB.gu_product+"=?");
	  for (int p=0; p<nProds; p++) {
	    if (sUserId.equals(aProds[p].getStringNull(DB.gu_blockedby,null))) {
		  oUpdt.setString(1, aProds[p].getString(DB.gu_product));
		  oUpdt.executeUpdate();
	    } // fi (gu_blockedby is null)
	  } // next
	  oUpdt.close();
	} // fi (aProds)

	DBSubset oChilds = getChilds(oConn);
	
	if (null!=oChilds) {
	  int nChilds = oChilds.getRowCount();
	  Category oChld = new Category();
	  for (int c=0; c<nChilds; c++) {
	    oChld.replace(DB.gu_category, oChilds.getString(0,c));
	    oChld.checkIn(oConn, sUserId);
	  } // next
	} // fi (oChilds)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Categrory.checkIn()");
    }
  } // checkIn

  // **********************************************************
  // Static Methods

  /**
   * <p>Create or Store Category.</p>
   * @param oConn Database Connection
   * @param sCategoryId GUID of Category to store or <b>null</b> if it is a new Category.
   * @param sParentId GUID of Parent Category or <b>null</b> if it is a root category.
   * @param sCategoryName Internal Category Name. It is recommended that makeName()
   * method is applied always on sCategoryName. Because category names are often used for composing
   * physical disk paths, assigning characters such as '*', '/', '?' etc. to category names may
   * lead to errors when creating directories for contained Products. As a general rule use ONLY
   * upper case letters and numbers for category names.
   * @param iIsActive 1 if category is to be marked active, 0 if it is to be marked as unactive.
   * @param iDocStatus Initial Document Status, { 0=Pending, 1=Active, 2=Locked } See k_lu_status table.
   * @param sOwner GUID of User owner of this Category.
   * @param sIcon1 Icon for closed folder.
   * @param sIcon2 Icon for opened folder.
   * @return GUID of new Category or sCategoryId if Category already existed.
   * @throws SQLException
   */
  public static String store(JDCConnection oConn, String sCategoryId, String sParentId, String sCategoryName, short iIsActive, int iDocStatus, String sOwner, String sIcon1, String sIcon2 ) throws SQLException {
    Category oCatg = new Category ();
    boolean isParentOfParent = false;
    Object aCatg[] = { null };
    DBSubset oNames;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.store([Connection], " + sCategoryId + ", " + sParentId + ", sCategoryName" + ", ...)" );
      DebugFile.incIdent();
      }

    oCatg.put (DB.gu_owner, sOwner);
    oCatg.put (DB.nm_category, sCategoryName);
    oCatg.put (DB.bo_active, iIsActive);
    oCatg.put (DB.id_doc_status, iDocStatus);

    if (null!=sIcon1) oCatg.put (DB.nm_icon, sIcon1);
    if (null!=sIcon2) oCatg.put (DB.nm_icon2, sIcon2);

      if (null!=sCategoryId) {
        oCatg.put (DB.gu_category, sCategoryId);

        // Verificar que la categoria no es padre de si misma
        if (null!=sParentId) {
          if (sCategoryId.equalsIgnoreCase(sParentId)) {
            if (DebugFile.trace) DebugFile.writeln("ERROR: Category " + sCategoryName + " is its own parent");
            throw new SQLException("Category tree circular reference");
          } // endif (sCategoryId==sParentId)

          // Si la categoria tiene padre (no es raiz) entonces
          // verificar que el padre no es a su vez un hijo de
          // la categoria para evitar la creacion de bucles.
          isParentOfParent = oCatg.isParentOf(oConn, sParentId);
        } // endif (sParentId)

      } // endif (null!=sCategoryId)

      if (isParentOfParent) {
        if (DebugFile.trace) DebugFile.writeln("ERROR: Category " + sCategoryName + " has a circular parentship relationship");
        throw new SQLException("Category tree circular reference");
      }

      // Si la categoria ya existia, entonces
      // borrar todos los nombres traducidos (etiquetas)
      if (null!=sCategoryId) {
        if (DebugFile.trace) DebugFile.writeln("Clearing labels...");
        aCatg[0] = oCatg.getString(DB.gu_category);
        oNames = new DBSubset (DB.k_cat_labels, DB.id_language+","+DB.tr_category+","+DB.url_category, DB.gu_category+"=?",1);
        oNames.clear (oConn, aCatg);
        if (DebugFile.trace) DebugFile.writeln("Labels cleared.");
      }
      else
        oCatg.remove(DB.gu_category);

      // Grabar la categoria,
      // si el campo id_category no existe (nueva categoria)
      // el metodo store lo rellenara automaticamente al grabar
      oCatg.store(oConn);

      // Establecer si la categoria es raiz
      if (null==sParentId)
        oCatg.setIsRoot(oConn, true);
      else
        oCatg.setParent(oConn, sParentId);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.store() : " + oCatg.getString(DB.gu_category));
    }

    // Recuperar el identificador unico de la categoria recien escrita
    return oCatg.getString(DB.gu_category);
  } // storeCategory()

  // ----------------------------------------------------------

  /**
   * <p>Delete Category and all its childs.</p>
   * First delete all Products and Companies contained in Category, including
   * physical disk files associted with Products and Company attachments.<br>
   * Then call k_sp_del_category_r stored procedure and perform recursive
   * deletion of all childs.
   * @param oConn Database Connection
   * @param sCategoryGUID GUID of Category to delete.
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sCategoryGUID)
    throws SQLException, IOException {

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Category.delete([Connection], " + sCategoryGUID + ")");
       DebugFile.incIdent();
     }

     Category oCat = new Category(sCategoryGUID);

     // Delete any child category first
     // New for v2.1
     DBSubset oChlds = oCat.getChilds(oConn);
     int iChilds = oChlds.getRowCount();
     for (int c=0; c<iChilds; c++)
       Category.delete(oConn, oChlds.getString(0,c));

     Statement oStmt;
     Product oProd;
     DBSubset oObjs = oCat.getObjects(oConn);
     int iObjs = oObjs.getRowCount();
     boolean bRetVal;

    // recorre los objetos de esta categoría y los borra
    for (int o=0; o<iObjs; o++) {
      switch (oObjs.getInt(1, o)) {
        case com.knowgate.training.AcademicCourse.ClassId:
          // los cursos academicos no se borran cuando se borra la categoria
          // pero si se borran sus productos asociados en la tienda
        case com.knowgate.hipergate.Product.ClassId:
          oProd = new Product(oObjs.getString(0, o));
          if (oProd.exists(oConn)) {
            oProd.delete(oConn);          
          }
          break;
        case com.knowgate.crm.DistributionList.ClassId:
          com.knowgate.crm.DistributionList.delete(oConn, oObjs.getString(0, o));
          break;
        case com.knowgate.crm.Company.ClassId:
          com.knowgate.crm.Company.delete(oConn, oObjs.getString(0, o));
          break;
        case com.knowgate.forums.NewsGroup.ClassId:
          com.knowgate.forums.NewsGroup.delete(oConn, oObjs.getString(0, o));
          break;
        case com.knowgate.hipergate.Image.ClassId:
          Image oImg = new com.knowgate.hipergate.Image(oConn, oObjs.getString(0, o));
          oImg.delete(oConn);
          break;
        case com.knowgate.hipermail.DBMimeMessage.ClassId:
          com.knowgate.hipermail.DBMimeMessage.delete(oConn, sCategoryGUID, oObjs.getString(0, o));
          break;
        case com.knowgate.acl.PasswordRecord.ClassId:
          com.knowgate.acl.PasswordRecord.delete(oConn, oObjs.getString(0, o));
          break;
      }
    } // next (o)

    oObjs = null;

    if (DBBind.exists(oConn, DB.k_mime_msgs, "U")) {
      oObjs = new DBSubset(DB.k_mime_msgs, DB.gu_mimemsg, DB.gu_category + "='" + sCategoryGUID + "'", 1000);
      iObjs = oObjs.load(oConn);

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        PreparedStatement oDlte = oConn.prepareStatement("SELECT k_sp_del_mime_msg(?)");
        ResultSet oRSet;
        for (int m=0; m<iObjs; m++) {
          oDlte.setString(1, oObjs.getString(0,m));
          oRSet = oDlte.executeQuery();
          oRSet.close();
        }
        oDlte.close();
      }
      else {
        CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_mime_msg(?) }");
        for (int m=0; m<iObjs; m++) {
          oCall.setString(1, oObjs.getString(0,m));
          oCall.execute();
        }
        oCall.close();
      }
    } // fi (exists(k_mime_msgs))

    oObjs = null;

    if (DBBind.exists(oConn, DB.k_x_company_prods, "U")) {

      oStmt = oConn.createStatement();

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_company_prods + " WHERE " + DB.gu_category + "='" + sCategoryGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_x_company_prods + " WHERE " + DB.gu_category + "='" + sCategoryGUID + "'");

      oStmt.close();
    } // fi (k_x_company_prods)

    if (DBBind.exists(oConn, DB.k_x_contact_prods, "U")) {

      oStmt = oConn.createStatement();

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_contact_prods + " WHERE " + DB.gu_category + "='" + sCategoryGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_x_contact_prods + " WHERE " + DB.gu_category + "='" + sCategoryGUID + "'");

      oStmt.close();
    } // fi (k_x_contact_prods)

    // Saca la lista de categorías hijas de primer nivel y repite el proceso de borrado
    LinkedList oChilds = oCat.browse(oConn, BROWSE_DOWN, BROWSE_BOTTOMUP);
    ListIterator oIter = oChilds.listIterator();

    while (oIter.hasNext()) {
      oCat = (Category) oIter.next();
      oCat.delete(oConn);
    } // wend

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace) DebugFile.writeln("Connection.executeQuery(SELECT k_sp_del_category_r ('" + sCategoryGUID + "'))");
      oStmt = oConn.createStatement();
      oStmt.executeQuery("SELECT k_sp_del_category_r ('" + sCategoryGUID + "')");
      oStmt.close();
      bRetVal = true;
    } else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({call k_sp_del_category_r('" + sCategoryGUID + "')})");
      CallableStatement oCall = oConn.prepareCall("{call k_sp_del_category_r ('" + sCategoryGUID + "')}");
      bRetVal = oCall.execute();
      oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.delete() : " + String.valueOf(bRetVal));
    }
    return bRetVal;
  } // delete

  // ----------------------------------------------------------

  /**
   * Create new Category with translated labels.
   * @param oConn Database Connection
   * @param Values An array with the following elements:<br>
   * { (String) gu_parent, (String) gu_owner, (String) nm_category,
   * (Short) bo_active, (Short) id_doc_status, (String) nm_icon, (String) nm_icon2 }
   * @return GUID of new Category
   * @throws SQLException
   */
  public static String create(JDCConnection oConn, Object[] Values) throws SQLException {
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin Category.create([Connection], Object[])" );
	  DebugFile.incIdent();
	}

	Category oCatg = new Category ();

    oCatg.put (DB.gu_owner, Values[1]);
    oCatg.put (DB.nm_category, Values[2]);
    oCatg.put (DB.bo_active, Values[3]);
    oCatg.put (DB.id_doc_status, Values[4]);
    oCatg.put (DB.nm_icon, Values[5]);
    if (Values[6]!=null)
      oCatg.put (DB.nm_icon2, Values[6]);
    else
      oCatg.put (DB.nm_icon2, Values[5]);

    // Grabar la categoria, el metodo store
    // rellenara automaticamente el campo gu_category
    oCatg.store(oConn);

    // Establecer el padre
    if (null!=Values[0])
      oCatg.setParent(oConn, Values[0].toString());
    else
      oCatg.setIsRoot(oConn, true);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.create() : " + oCatg.getStringNull(DB.gu_category,"null"));
    }
    
    // Recuperar el identificador unico de la categoria recien escrita
    return oCatg.getString(DB.gu_category);
  } // create()

  // ----------------------------------------------------------

  /**
   * <p>Get Category GUID given its internal name.</p>
   * Category name is column nm_category at table k_categories.<br>
   * This Java method calls k_sp_get_cat_id database stored procedure.
   * @param oConn Database Connection
   * @param sCategoryNm Category Internal Name
   * @return Category GUID or <b>null</b> if no Category with such name is found.
   * @throws SQLException
   */
  public static String getIdFromName(JDCConnection oConn, String sCategoryNm) throws SQLException {
    if (DebugFile.trace) {
     DebugFile.writeln("Begin Category.getIdFromName([Connection], " + sCategoryNm + ")" );
     DebugFile.incIdent();
     }

    String sCatId =  DBPersist.getUIdFromName(oConn, null, sCategoryNm, "k_sp_get_cat_id");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.getIdFromName() : " + sCatId);
    }

    return sCatId;
  } // getIdFromName()

  // ----------------------------------------------------------

  /**
   * <p>Make an internal category name from an arbitrary string.</p>
   * Because nm_category is a primary key for table k_categories and because
   * category names are used for composing physical disk paths, some special
   * rules must be followed when assigning category names.<br>
   * <ul>
   * <li><b>First</b> a Category Name MUST NOT containing any character not allowed in a directory name.
   * <li><b>Second</b> a Category Name MUST be unique for all categories at all WorkAreas.
   * </ul>
   * @param oConn Database Connection
   * @param sCategoryNm String to be used as a guide for making category name.
   * @return The input string truncated to 18 characters and transformed to upper case.
   * Method Gadgets.ASCIIEncode() is applies and spaces, commas, asterisks, slashes,
   * backslashes and other characters are removed or substituted.
   * Finally an 8 decimals integer tag is appended to name for making it unique.
   * For example "Barnes & Noble" is transormed to "BARNES_A_NOBLE~00000001"
   * @throws SQLException
   */
  public static synchronized String makeName(JDCConnection oConn, String sCategoryNm) throws SQLException {
    String sCatNm;
    int iChurriguito;
    String sCatIndex;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Category.makeName([Connection], " + sCategoryNm + ")" );
      DebugFile.incIdent();
      }

    String sShortCategoryNm = (sCategoryNm.length()>18 ? sCategoryNm.substring(0, 18) : sCategoryNm);
    sShortCategoryNm = Gadgets.ASCIIEncode(sShortCategoryNm);
    sShortCategoryNm.replace(' ', '_');
    sShortCategoryNm.replace(',', '_');
    sShortCategoryNm.replace(';', '_');
    sShortCategoryNm.replace('"', 'q');
    sShortCategoryNm.replace('|', '_');

    // Obtener el máximo de las categorías cuyo alias es igual al buscado
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DBBind.Functions.ISNULL + "(MAX(" + DB.nm_category + "),'" + sShortCategoryNm + "~00000000') FROM " + DB.k_categories + " WHERE " + DB.nm_category + " LIKE '" + sShortCategoryNm + "%')");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DBBind.Functions.ISNULL + "(MAX(" + DB.nm_category + "),'" + sShortCategoryNm + "~00000000') FROM " + DB.k_categories + " WHERE " + DB.nm_category + " LIKE ?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oStmt.setString(1, sShortCategoryNm + "%");
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      sCatNm = oRSet.getString(1);
    }
    else
      sCatNm = sShortCategoryNm + "~00000000";
    oRSet.close();
    oStmt.close();

    // Buscar el churriguito y sacar los números que quedan a la derecha
    iChurriguito = sCatNm.indexOf("~");
    if (iChurriguito>0)
      sCatIndex = String.valueOf(Integer.parseInt(sCatNm.substring(iChurriguito+1)) + 1);
    else
      sCatIndex = "00000001";

    // Añadir zeros de padding por la izquierda
    for (int z=0; z<8-sCatIndex.length(); z++) sCatIndex = "0" + sCatIndex;

    sShortCategoryNm += "~" + sCatIndex;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Category.makeName() : " + sShortCategoryNm);
    }

    return sShortCategoryNm;
  } // makeName

  // **********************************************************
  // Constantes Publicas

  public static final int BROWSE_UP = 0;
  public static final int BROWSE_DOWN = 1;

  public static final int BROWSE_TOPDOWN = 0;
  public static final int BROWSE_BOTTOMUP = 1;

  public static final short ClassId = 10;

  // **********************************************************
  // Variables Privadas

  private DBSubset oParents;
  private DBSubset oChilds;
  private DBSubset oNames;
  private DBSubset oACLGroups;
  private DBSubset oACLUsers;
  private FileSystem oFS;
}
