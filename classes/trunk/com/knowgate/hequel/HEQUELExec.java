package com.knowgate.hequel;

import java.io.FileWriter;
import java.io.IOException;

import java.sql.SQLException;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.util.StringTokenizer;
import java.util.NoSuchElementException;
import java.util.Vector;
import java.util.HashMap;
import java.lang.NullPointerException;
import java.lang.Exception;
import java.lang.ClassNotFoundException;
import java.lang.IllegalAccessException;
import java.lang.InstantiationException;

import com.knowgate.debug.*;
import com.knowgate.jdc.*;
import com.knowgate.dataobjs.*;
import com.knowgate.acl.*;
import com.knowgate.hipergate.*;
import com.knowgate.misc.*;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 * @deprecated
 */
public class HEQUELExec {

  public static final String sAdminsGUID = "ce75c69a786f49cfa3beead8a961942c";
  public static final String sAdminGUID = "bab84ab397564299b068693187464b4f";

  private String sCurrentUser;
  private int iCurrentDomain;
  private int iIPAddr;
  private int iTransactId;
  private HashMap oBindings;
  private String sActiveBinding;
  private DBBind oActiveBinding;
  private JDCConnection oActiveConnection;
  private Vector oExceptions;
  private String sColDelim;
  private String sRowDelim;

  /*
  public void methodTemplate(JDCConnection oConn )  throws DBException {
    DBException oDBEx;

    oExceptions.clear();

    try {

    }

    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  }
  */

  // ----------------------------------------------------------

  /**
   * @deprecated
   */
  public HEQUELExec() throws DBException {
    DBException oDBEx;

    oExceptions = new Vector();
    sColDelim = "`";
    sRowDelim = "¨";

    oBindings = new HashMap();
    try {
      oActiveBinding = new DBBind();
      sActiveBinding = "system";
      oBindings.put(sActiveBinding, oActiveBinding);
      oActiveConnection = oActiveBinding.getConnection("HEQUELExec");
      sCurrentUser = sAdminGUID;
      iCurrentDomain = 1;
      iIPAddr = 0;
      iTransactId = 0;
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // HEQUELExec

  // ----------------------------------------------------------

  /**
   * @deprecated
   */
  public HEQUELExec(DBBind oBinding, int iDomainId, String sUserId, int iIPAddr) throws DBException {
    DBException oDBEx;

    oExceptions = new Vector();
    sColDelim = "`";
    sRowDelim = "¨";

    oBindings = new HashMap();
    try {
      oActiveBinding = oBinding;
      sActiveBinding = "system";
      oBindings.put(sActiveBinding, oActiveBinding);
      oActiveConnection = oActiveBinding.getConnection("HEQUELExec");
      sCurrentUser = sUserId;
      iCurrentDomain = iDomainId;
      iTransactId = 0;
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // HEQUELExec

  // ----------------------------------------------------------

  protected void finalize() throws SQLException {
    oActiveConnection.close("HEQUELExec");
    oActiveConnection = null;

    oBindings.clear();
    oBindings = null;
    oActiveBinding = null;
  } // finalize

  // ----------------------------------------------------------

  /**
   * @deprecated
   */
  public Vector Exceptions() {
    return oExceptions;
  } // Exceptions

  /**
   * @deprecated
   */
  public DBException LastException() {
    DBException oRetVal;

    if (oExceptions.isEmpty())
      oRetVal = null;
    else
      oRetVal = (DBException) oExceptions.lastElement();

    return oRetVal;
  } // LastException

  // ----------------------------------------------------------

  /**
   * @deprecated
   */
  public String getColumnDelimiter() {
    return sColDelim;
  }

  /**
   * @deprecated
   */
  public void setColumnDelimiter(String sDelim) {
    oExceptions.clear();
    sColDelim=sDelim;
  } // setColumnDelimiter

  /**
   * @deprecated
   */
  public String getRowDelimiter() {
    return sRowDelim;
  } // getRowDelimiter

  /**
   * @deprecated
   */
  public void setRowDelimiter(String sDelim) {
    oExceptions.clear();
    sRowDelim=sDelim;
  } // setRowDelimiter

  // ----------------------------------------------------------

  /**
   * @deprecated
   */
  public Connection getConnection() {
    return (Connection) oActiveConnection;
  }

  // ----------------------------------------------------------

  /**************************/
  /* Generic Entity Methods */
  /**************************/

  /**
   * @deprecated
   */
  public int modifyEntity(String sEntityName, String sPKValue, int iDomain, String sSetValues ) throws DBException {
    Statement oStmt;
    DBException oDBEx;
    boolean bPrepared;
    String sSQL;
    int iAffected;
    short iEntityId;
    String sEntity1;
    String sCoOp;

    oExceptions.clear();

    try {
      if (sEntityName.compareTo("DOMAIN")==0) {
        sSQL = "UPDATE " + DB.k_domains + " SET " + sSetValues + " WHERE " + DB.nm_domain + "='" + sPKValue + "'";
        iEntityId = ACLDomain.ClassId;
        sEntity1 = String.valueOf(ACLDomain.getIdFromName(oActiveConnection, sPKValue));
        sCoOp = "MDOM";
      }
      else if (sEntityName.compareTo("USER")==0) {
        sSQL = "UPDATE " + DB.k_users + " SET " + sSetValues + " WHERE " + DB.tx_nickname + "='" + sPKValue + "' AND " + DB.id_domain + "=" + String.valueOf(iDomain);
        iEntityId = ACLUser.ClassId;
        sEntity1 = ACLUser.getIdFromNick(oActiveConnection, iDomain, sPKValue);
        sCoOp = "MUSR";
      }
      else if (sEntityName.compareTo("CATEGORY")==0) {
        sSQL = "UPDATE " + DB.k_categories + " SET " + sSetValues + " WHERE " + DB.nm_category + "='" + sPKValue + "'";
        iEntityId = Category.ClassId;
        sEntity1 = Category.getIdFromName(oActiveConnection, sPKValue);
        sCoOp = "MCAT";
      }
      else {
        sEntity1 = sCoOp = sSQL = "";
        iEntityId = (short) 0;
      }

    bPrepared = false;

      oStmt = oActiveConnection.createStatement();

      bPrepared = true;
      iAffected = oStmt.executeUpdate(sSQL);

      DBAudit.log(oActiveConnection, iEntityId, sCoOp, sCurrentUser, sEntity1, null, iTransactId, iIPAddr, sSetValues.substring(0, sSetValues.length()<100 ? sSetValues.length() : 99), null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    try {
      if (bPrepared) oStmt.close();
      oStmt = null;
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      oStmt = null;
      throw oDBEx;
    }

    return iAffected;
  } // modifyEntity

  // ----------------------------------------------------------

  /**
   * @deprecated
   */
  public int detachEntity(String sEntityName, String sPKValue, String sDomain, String sFrom) throws DBException {
    DBException oDBEx;
    ACLGroup oGrp;
    Category oCat;
    int iDomainId;
    String sChldId;
    String sPrntId;
    String sUserId;
    String sGroupId;
    int iDetached;

    oExceptions.clear();

    try {
      if (sEntityName.compareTo("USER")==0) {
        iDomainId = ACLDomain.getIdFromName(oActiveConnection, sDomain);
        sUserId = ACLUser.getIdFromNick(oActiveConnection, iDomainId, sPKValue);
        sGroupId = ACLGroup.getIdFromName(oActiveConnection, iDomainId, sFrom);
        oGrp = new ACLGroup(sGroupId);
        iDetached = oGrp.removeACLUser(oActiveConnection, sUserId);
        oGrp = null;
        DBAudit.log(oActiveConnection, ACLUser.ClassId, "DUSR", sCurrentUser, sUserId, sGroupId, iTransactId, iIPAddr, sPKValue, sFrom);
      }
      else if  (sEntityName.compareTo("CATEGORY")==0) {
        sChldId = Category.getIdFromName(oActiveConnection, sPKValue);
        sPrntId = Category.getIdFromName(oActiveConnection, sFrom);
        oCat = new Category(sChldId);
        oCat.resetParent(oActiveConnection, sPrntId);
        oCat = null;
        iDetached = 1;
        DBAudit.log(oActiveConnection, Category.ClassId, "DCAT", sCurrentUser, sChldId, sPrntId, iTransactId, iIPAddr, sPKValue, sFrom);
      }
      else
        iDetached = 0;
    }
    catch (SQLException oSQLEx) {
      iDetached = 0;
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }

    return iDetached;
  } // detachEntity

  // ----------------------------------------------------------

  /**
   * @deprecated
   */
  public int eraseEntity(String sEntityName, String sPKValue, String sFrom)
      throws DBException,IOException {
    DBException oDBEx;
    Object oEntity;
    boolean bDeleted;
    int iDomain;
    String sUser;
    String sCategory;

    oExceptions.clear();

    try {
      if (sEntityName.compareTo("DOMAIN")==0) {
        iDomain = ACLDomain.getIdFromName(oActiveConnection,sPKValue);
        bDeleted = ACLDomain.delete(oActiveConnection, iDomain);
        DBAudit.log(oActiveConnection, ACLDomain.ClassId, "EDOM", sCurrentUser, String.valueOf(iDomain), null, iTransactId, iIPAddr, sPKValue, null);
      }
      else if (sEntityName.compareTo("USER")==0) {
        iDomain = ACLDomain.getIdFromName(oActiveConnection,sFrom);
        sUser = ACLUser.getIdFromNick(oActiveConnection,iDomain,sPKValue);
        bDeleted = ACLUser.delete(oActiveConnection, sUser);
        DBAudit.log(oActiveConnection, ACLUser.ClassId, "EUSR", sCurrentUser, sUser, String.valueOf(iDomain), iTransactId, iIPAddr, sPKValue, sFrom);
      }
      else if (sEntityName.compareTo("CATEGORY")==0) {
        sCategory = Category.getIdFromName(oActiveConnection,sPKValue);
        bDeleted = deleteCategory(sCategory);
      }
      else
        bDeleted = false;
    }
    catch (SQLException oSQLEx) {
      bDeleted = false;
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }

    return bDeleted ? 1 : 0;
  } // eraseEntity

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void addEntities (String sParentType, String sObjectType, String sParentNm, String sDomainNm, String sObjList) throws DBException {
    DBException oDBEx;
    PreparedStatement oStmt;
    StringTokenizer oGrpTok;
    String sXTable;
    String sParentId;
    String sParentFld;
    String sObjectFld;
    String sCoOp;
    String sToken;
    short iEntityId;
    int iTokCount;
    int iDomainId;

    oExceptions.clear();

    try {

      if (sParentType.compareTo("GROUP")==0 && sObjectType.compareTo("USER")==0) {
        sXTable = DB.k_x_group_user;
        sParentFld = DB.gu_acl_group;
        sObjectFld = DB.gu_user;
        sCoOp = "AUGP";
        iEntityId = ACLUser.ClassId;
        iDomainId = ACLDomain.getIdFromName(oActiveConnection, sDomainNm);
        sParentId = ACLGroup.getIdFromName(oActiveConnection, iDomainId, sParentNm);
      }
      if (sParentType.compareTo("CATEGORY")==0 && sObjectType.compareTo("CATEGORY")==0) {
        sXTable = DB.k_x_cat_tree;
        sParentFld = DB.gu_parent_cat;
        sObjectFld = DB.gu_child_cat;
        sCoOp = "ACCT";
        iDomainId = 0;
        iEntityId = Category.ClassId;
        sParentId = Category.getIdFromName(oActiveConnection, sParentNm);
      }
      else {
        iEntityId = (short) 0;
        iDomainId = 0;
        sCoOp = sParentId = sObjectFld = sParentFld = sXTable = "";
      }

      if (sObjList.length()>0) {
        oStmt = oActiveConnection.prepareStatement("INSERT INTO " + sXTable + "(" + sParentFld + "," + sObjectFld + ") VALUES(?,?)");

        oGrpTok = new StringTokenizer(sObjList, sColDelim);
        iTokCount = oGrpTok.countTokens();

        for (int t=0; t<iTokCount; t++) {
          sToken = oGrpTok.nextToken();
          oStmt.setString (1, sParentId);
          oStmt.setString (2, sToken);
          oStmt.executeUpdate();
          oStmt.close();

          DBAudit.log(oActiveConnection, iEntityId, sCoOp, sCurrentUser, sToken, sParentId, iTransactId, iIPAddr, null, null);
        } // end for (t)
      } // end if (sUsersList!="")
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    catch (NoSuchElementException oNSEx) {
      oDBEx = new DBException(oNSEx.getMessage());
      oExceptions.addElement(oNSEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    catch (NullPointerException oNilEx) {
      oDBEx = new DBException(oNilEx.getMessage());
      oExceptions.addElement(oNilEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // addEntities


  // ----------------------------------------------------------

  /************************/
  /* Begin Domain methods */
  /************************/

  public int newDomain(int iDomainId, String sDomainName, short iIsActive, String sAdminId) throws DBException {
    DBException oDBEx;
    ACLDomain oDom = new ACLDomain();

    if (iDomainId>0) oDom.put(DB.id_domain, iDomainId);
    oDom.put(DB.nm_domain, sDomainName);
    oDom.put(DB.bo_active, iIsActive);
    oDom.put(DB.gu_owner, sAdminId);

    try {
      oDom.store(oActiveConnection);
      DBAudit.log(oActiveConnection, ACLDomain.ClassId, "NDOM", sCurrentUser, String.valueOf(iDomainId), null, iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }

    newUser("admin", "", oDom.getInt(DB.id_domain), (short)1);

    return oDom.getInt(DB.id_domain);
  }

  // ----------------------------------------------------------

  /**********************/
  /* Begin User methods */
  /**********************/

  /**
   * @deprecated
   */

  public String newUser(String sUserNick, String sUserPwd, int iDomainId, short iIsActive) throws DBException {
    DBException oDBEx;
    ACLUser oUsr = new ACLUser();

    try {
      ACLUser.create(oActiveConnection, new Object[] {
        new Integer(iDomainId),
        sUserNick, sUserPwd,
        new Short(iIsActive),
        new Short((short)1), // bo_searchable
        new Short((short)1), // bo_change_pwd
        null, // tx_main_email
        null, // tx_alt_email
        null, // nm_user
        null, // tx_surname1
        null, // tx_surname2
        null, // tx_challenge
        null, // tx_reply
        null, // nm_company
        null // de_title
        } );

      oUsr.store(oActiveConnection);
      DBAudit.log(oActiveConnection, ACLUser.ClassId, "NUSR", sCurrentUser, oUsr.getString(DB.gu_user), String.valueOf(iDomainId), iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    return oUsr.getString(DB.gu_user);
  } // newUser

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void storeUserGroups(String sUserId, String sGroupsTable) throws DBException {
    String sUser;
    PreparedStatement oStmt;
    DBException oDBEx;
    StringTokenizer oColTok;
    String sSQL;
    String sGrp;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin storeUserGroups(" + sUserId + "," + sGroupsTable +")");
      DebugFile.incIdent();
    }

    oExceptions.clear();

    sSQL = "INSERT INTO " + DB.k_x_group_user + "(" + DB.gu_acl_group + "," + DB.gu_user + ") VALUES(?,'" + sUserId + "')";

    try {
      oStmt = oActiveConnection.prepareStatement(sSQL);

      oColTok = new StringTokenizer(sGroupsTable, sColDelim);
      while (oColTok.hasMoreElements()) {
        sGrp = oColTok.nextToken();
        oStmt.setString(1, sGrp);
        try {
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.execute(" + Gadgets.replace(sSQL,"?","'"+sGrp+"'") + ")");
        } catch (Exception e) { }
        oStmt.execute();
      }
      oStmt.close();
      oStmt = null;
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    catch (NoSuchElementException oNSEEx) {
      oDBEx = new DBException(oNSEEx.getMessage());
      oExceptions.addElement(oNSEEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End storeUserGroups()");
    }
  } // storeUserGroups()

  // ----------------------------------------------------------

  /**************************/
  /* Begin Group methods    */
  /**************************/

  /**
   * @deprecated
   */

  public String newGroup (String sGroupName, int iDomainId, short iIsActive, String sGroupDesc) throws DBException {
    DBException oDBEx;
    ACLGroup oGroup = new ACLGroup();

    oExceptions.clear();

    try {
      oGroup.put(DB.id_domain, iDomainId);
      oGroup.put(DB.bo_active, iIsActive);
      oGroup.put(DB.nm_acl_group, sGroupName);
      if (null!=sGroupDesc) oGroup.put(DB.de_acl_group, sGroupDesc);
      oGroup.store(oActiveConnection);

      DBAudit.log(oActiveConnection, ACLGroup.ClassId, "NGRP", sCurrentUser, oGroup.getString(DB.gu_acl_group), String.valueOf(iDomainId), iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  return oGroup.getString(DB.gu_acl_group);
  }

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public String storeGroup (String sGroupId, int iDomainId, short iIsActive, String sGroupNm, String sGroupDesc) throws DBException {
    ACLGroup oGrp = new ACLGroup();

    DBException oDBEx;
    ACLGroup oGroup = new ACLGroup();

    oExceptions.clear();

    try {
      if (sGroupId!=null)
        if (sGroupId.trim().length()>0)
          oGroup.put(DB.gu_acl_group, sGroupId);

      oGroup.put(DB.id_domain, iDomainId);
      oGroup.put(DB.bo_active, iIsActive);
      oGroup.put(DB.nm_acl_group, sGroupNm);
      if (null!=sGroupDesc) oGroup.put(DB.de_acl_group, sGroupDesc);
      oGroup.store(oActiveConnection);

      DBAudit.log(oActiveConnection, ACLGroup.ClassId, "MGRP", sCurrentUser, oGroup.getString(DB.gu_acl_group), String.valueOf(iDomainId), iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    return oGroup.getString(DB.gu_acl_group);
  } // storeGroup()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void storeGroupUsers(String sGroupId, String sUsersTable) throws DBException {
    String sUser;
    PreparedStatement oStmt;
    DBException oDBEx;
    StringTokenizer oColTok;

    oExceptions.clear();

    try {
      oStmt = oActiveConnection.prepareStatement("INSERT INTO " + DB.k_x_group_user + "(" + DB.gu_acl_group + "," + DB.gu_user + ") VALUES('" + sGroupId + "',?)");

      oColTok = new StringTokenizer(sUsersTable, sColDelim);
      while (oColTok.hasMoreElements()) {
        oStmt.setString(1, oColTok.nextToken());
        oStmt.execute();
      }
      oStmt.close();
      oStmt = null;
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    catch (NoSuchElementException oNSEEx) {
      oDBEx = new DBException(oNSEEx.getMessage());
      oExceptions.addElement(oNSEEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // storeGroupUsers()

  // ----------------------------------------------------------

  /**************************/
  /* Begin Category methods */
  /**************************/

  /**
   * @deprecated
   */

  public String newCategory(String sCategoryNm, String sParentId, short iIsActive, int iDocStatus, String sIcon1, String sIcon2 ) throws DBException {
    Category oCat;
    DBException oDBEx;
    String sNewCatId;

    oExceptions.clear();

    sNewCatId = storeCategory(null, sParentId, sCategoryNm, iIsActive, iDocStatus, sIcon1, sIcon2);

    try {

      oCat = new Category(sNewCatId);
      oCat.setParent(oActiveConnection, sParentId);
      oCat.setGroupPermissions (oActiveConnection, sAdminsGUID, 255, (short)0, (short)0);
      oCat.setUserPermissions (oActiveConnection, sAdminGUID, 255, (short)0, (short)0);
      oCat = null;

      DBAudit.log(oActiveConnection, Category.ClassId, "NCAT", sCurrentUser, sNewCatId, sParentId, iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }

    return sNewCatId;
  }

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public String newCategoryByName(String sCategoryNm, String sParentNm, short iIsActive, int iDocStatus, String sIcon1, String sIcon2 ) throws DBException {
    String sParentId;
    DBException oDBEx;

    oExceptions.clear();

    try {
      if (null!=sParentNm)
        sParentId = Category.getIdFromName(oActiveConnection, sParentNm);
      else
        sParentId = null;
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    return newCategory (sCategoryNm, sParentId, iIsActive, iDocStatus, sIcon1, sIcon2);
  } // newCategoryByName()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public String storeCategory(String sCategoryId, String sParentId, String sCategoryName, short iIsActive, int iDocStatus, String sIcon1, String sIcon2 ) throws DBException {
    DBException oDBEx;
    Category oCatg = new Category ();
    boolean isParentOfParent = false;
    Object aCatg[] = new Integer[1];
    DBSubset oNames;

    oExceptions.clear();

    oCatg.put (DB.gu_owner, sCurrentUser);
    oCatg.put (DB.nm_category, sCategoryName);
    oCatg.put (DB.bo_active, iIsActive);
    oCatg.put (DB.id_doc_status, iDocStatus);

    if (null!=sIcon1) oCatg.put (DB.nm_icon, sIcon1);
    if (null!=sIcon2) oCatg.put (DB.nm_icon2, sIcon2);

    try {

      if (null!=sCategoryId) {
        oCatg.put (DB.gu_category, sCategoryId);

        // Verificar que la categoria no es padre de si misma
        if (null!=sParentId) {
          if (sCategoryId.compareToIgnoreCase(sParentId)==0) {
            oDBEx = new DBException("La categoria no puede ser padre de si misma");
            oExceptions.addElement(oDBEx);
            throw oDBEx;
          } // endif (sCategoryId==sParentId && sParentId!="")

          // Si la categoria tiene padre (no es raiz) entonces
          // verificar que el padre no es a su vez un hijo de
          // la categoria para evitar la creacion de bucles.
          isParentOfParent = oCatg.isParentOf(oActiveConnection, sParentId);
        } // endif (null!=sParentId)

        // Asegurar que sólo el administrador puede crear categorías raiz
        //if (sParentId.length()==0) {
        //  if (!oUser.isDomainAdmin(oActiveConnection)) {
        //    oDBEx = new DBException("Solo el administrador puede crear categorias raiz");
        //    oExceptions.addElement(oDBEx);
        //    throw oDBEx;
        //  }

      } // endif (null!=sCategoryId)

      if (isParentOfParent) {
        oDBEx = new DBException("La categoria padre es hija de la categoria que esta intentando guardar");
        oExceptions.addElement(oDBEx);
        throw oDBEx;
      }

      // Si la categoria ya existia, entonces
      // borrar todos los nombres traducidos (etiquetas)
      if (null!=sCategoryId) {
        aCatg[0] = oCatg.getString(DB.gu_category);
        oNames = new DBSubset (DB.k_cat_labels, DB.id_language+","+DB.tr_category+","+DB.url_category, DB.gu_category+"=?",1);
        oNames.clear (oActiveConnection, aCatg);
      }
      else
        oCatg.remove(DB.gu_category);

      // Grabar la categoria,
      // si el campo id_category no existe (nueva categoria)
      // el metodo store lo rellenara automaticamente al grabar
      oCatg.store(oActiveConnection);

      // Establecer si la categoria es raiz
      oCatg.setIsRoot(oActiveConnection, null==sParentId);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }

    // Recuperar el identificador unico de la categoria recien escrita
    return oCatg.getString(DB.gu_category);
  } // storeCategory()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public int eraseCategoryLabelByName(String sCatNm, String sLanguage) throws DBException {
    DBException oDBEx;
    String sCatId;
    CategoryLabel oCatLbl;

    oExceptions.clear();

    try {
      sCatId = Category.getIdFromName(oActiveConnection, sCatNm);
      oCatLbl = new CategoryLabel (sCatId, sLanguage);
      oCatLbl.delete(oActiveConnection);
      oCatLbl = null;

      DBAudit.log(oActiveConnection, CategoryLabel.ClassId, "ELBL", sCurrentUser, sCatId, sLanguage, iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    return 0;
  } // eraseCategoryLabelByName()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public int modifyCategoryLabelByName(String sCatNm, String sLanguage, String sSetValues) throws DBException {
    DBException oDBEx;
    Statement oStmt;
    String sCatId;
    String sSQL;
    int iAffected;

    oExceptions.clear();

    try {
      sCatId = Category.getIdFromName(oActiveConnection, sCatNm);
      sSQL = "UPDATE " + DB.k_categories + " SET " + sSetValues + " WHERE " + DB.gu_category + "='" + sCatId + "' AND "  + DB.id_language + "='" + sLanguage + "'";
      oStmt = oActiveConnection.createStatement();
      iAffected = oStmt.executeUpdate(sSQL);
      oStmt.close();
      oStmt = null;

      DBAudit.log(oActiveConnection, CategoryLabel.ClassId, "MLBL", sCurrentUser, sCatId, sLanguage + "=" + sSetValues, iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    return 0;
  } // modifyCategoryLabelByName()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void moveCategory (String sCatId, String sOldId, String sNewId, boolean bInheritPermissions) throws DBException {
    DBException oDBEx;
    Category oCatg;
    short fNo = (short) 0;

    if (sOldId.equals(sNewId)) return;

    oExceptions.clear();

    try {
      oCatg = new Category (oActiveConnection, sCatId);

      if (sOldId!=null)
        oCatg.resetParent(oActiveConnection, sOldId);
      else
        oCatg.setIsRoot(oActiveConnection, false);

      if (sNewId!=null)
        oCatg.setParent (oActiveConnection, sNewId);
      else
        oCatg.setIsRoot(oActiveConnection, true);

      if (bInheritPermissions)
        oCatg.inheritPermissions(oActiveConnection, sNewId, fNo, fNo);

      DBAudit.log(oActiveConnection, Category.ClassId, "VCAT", sCurrentUser, sCatId, sOldId + "-" + sNewId, iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // moveCategory()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void moveCategoryByName (String sCatNm, String sOldNm, String sNewNm, boolean bInheritPermissions) throws DBException {
    DBException oDBEx;
    Category oCatg;
    String sCatId;
    String sOldId;
    String sNewId;
    short fNo = (short) 0;

    oExceptions.clear();

    try {
      sCatId = Category.getIdFromName(oActiveConnection, sCatNm);
      sOldId = Category.getIdFromName(oActiveConnection, sOldNm);
      sNewId = Category.getIdFromName(oActiveConnection, sNewNm);

      oCatg = new Category (oActiveConnection, sCatId);

      if (sOldNm.length()>0)
        oCatg.resetParent(oActiveConnection, sOldId);
      else
        oCatg.setIsRoot(oActiveConnection, false);

      if (sNewNm.length()>0)
        oCatg.setParent (oActiveConnection, sNewId);
      else
        oCatg.setIsRoot(oActiveConnection, true);

      if (bInheritPermissions)
        oCatg.inheritPermissions(oActiveConnection, sNewId, fNo, fNo);

      DBAudit.log(oActiveConnection, Category.ClassId, "VCAT", sCurrentUser, sCatId, sOldId + "-" + sNewId, iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // moveCategoryByName()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void storeCategoryLabelsByName(String sCatNm, String sNamesTable) throws DBException {
    DBException oDBEx;
    String sCatId;
    oExceptions.clear();

    try {
      sCatId = Category.getIdFromName(oActiveConnection, sCatNm);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }

    storeCategoryLabels(sCatId, sNamesTable);
  }

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void storeCategoryLabels(String sCatId, String sNamesTable) throws DBException {
    String sName;
    String sNoSuch;
    String sLanguageId;
    String sTrCategory;
    DBException oDBEx;
    int iTokCount;
    StringTokenizer oRowTok;
    StringTokenizer oColTok;
    CategoryLabel oName = new CategoryLabel();

    oExceptions.clear();

    oName.put (DB.gu_category, sCatId);

    // Sacar el idioma y la lista de etiquetas del String recibido como parametro.

    oRowTok = new StringTokenizer(sNamesTable, sRowDelim);

    iTokCount = oRowTok.countTokens();

    try {
      for (int r=0; r<iTokCount; r++) {
        // Separar los registros
        sNoSuch = DB.k_cat_labels + " register";
        sName = oRowTok.nextToken();

        // Para cada registro separar los campos
        oColTok = new StringTokenizer(sName, sColDelim);

        sNoSuch = "[" + sName + "] Token 1 : " + DB.id_language;
        sLanguageId = oColTok.nextToken();
        sNoSuch = "[" + sName + "] Token 2 : " + DB.tr_category;
        sTrCategory = oColTok.nextToken();

        if (sTrCategory!=null) {
          sTrCategory = sTrCategory.trim();
          if (sTrCategory.length()>0) {
            oName.replace(DB.id_language, sLanguageId);
            oName.replace(DB.tr_category, sTrCategory);
            oName.store(oActiveConnection);
          }
        } // endif (tr_category!=null)
      } // endfor (r)
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    catch (NoSuchElementException oNSEEx) {
      oDBEx = new DBException(oNSEEx.getMessage());
      oExceptions.addElement(oNSEEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // storeCategoryLabels()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public boolean deleteCategory(String sCatId) throws DBException,IOException {
    boolean bDeleted;
    DBException oDBEx;

    oExceptions.clear();

    try {
      bDeleted = Category.delete(oActiveConnection, sCatId);
      DBAudit.log(oActiveConnection, Category.ClassId, "ECAT", sCurrentUser, sCatId, null, iTransactId, iIPAddr, null, null);
    }
    catch (SQLException oSQLEx) {
      bDeleted = false;
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    return bDeleted;
  }

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void setCategoryGroupPermissions(String sCatNm, String sGroups, int iACLMask, short iRecurseChilds, short iPropagateObjs )  throws DBException {
    DBException oDBEx;
    String sCatId;
    Category oCatg = new Category();

    oExceptions.clear();

    try {
      sCatId = Category.getIdFromName(oActiveConnection, sCatNm);

      oCatg.put(DB.gu_category, sCatId);
      oCatg.setGroupPermissions (oActiveConnection, sGroups, iACLMask, iRecurseChilds, iPropagateObjs);

      DBAudit.log(oActiveConnection, Category.ClassId, "SCGP", sCurrentUser, sCatId, sGroups + "-" + String.valueOf(iACLMask), iTransactId, iIPAddr, null, null);
    }

    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // setCategoryGroupPermissions()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void remCategoryGroupPermissions(String sCatNm, String sGroups, int iACLMask, short iRecurseChilds, short iPropagateObjs )  throws DBException {
    DBException oDBEx;
    String sCatId;
    Category oCatg = new Category();

    oExceptions.clear();

    try {
      sCatId = Category.getIdFromName(oActiveConnection, sCatNm);

      oCatg.put(DB.gu_category, sCatId);
      oCatg.removeGroupPermissions (oActiveConnection, sGroups, iRecurseChilds, iPropagateObjs);

      DBAudit.log(oActiveConnection, Category.ClassId, "RCGP", sCurrentUser, sCatId, sGroups + "-" + String.valueOf(iACLMask), iTransactId, iIPAddr, null, null);
    }

    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // remCategoryGroupPermissions()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void setCategoryUserPermissions(String sCatNm, String sUsers, int iACLMask, short iRecurseChilds, short iPropagateObjs )  throws DBException {
    DBException oDBEx;
    String sCatId;
    Category oCatg = new Category();

    oExceptions.clear();

    try {
      sCatId = Category.getIdFromName(oActiveConnection, sCatNm);

      oCatg.put(DB.gu_category, sCatId);
      oCatg.setUserPermissions (oActiveConnection, sUsers, iACLMask, iRecurseChilds, iPropagateObjs);

      DBAudit.log(oActiveConnection, Category.ClassId, "SCUP", sCurrentUser, sCatId, sUsers + "-" + String.valueOf(iACLMask), iTransactId, iIPAddr, null, null);
    }

    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // setCategoryUserPermissions()

  // ----------------------------------------------------------

  /**
   * @deprecated
   */

  public void remCategoryUserPermissions(String sCatNm, String sUsers, int iACLMask, short iRecurseChilds, short iPropagateObjs )  throws DBException {
    DBException oDBEx;
    String sCatId;
    Category oCatg = new Category();

    oExceptions.clear();

    try {
      sCatId = Category.getIdFromName(oActiveConnection, sCatNm);

      oCatg.put(DB.gu_category, sCatId);
      oCatg.removeUserPermissions (oActiveConnection, sUsers, iRecurseChilds, iPropagateObjs);

      DBAudit.log(oActiveConnection, Category.ClassId, "RCUP", sCurrentUser, sCatId, sUsers + "-" + String.valueOf(iACLMask), iTransactId, iIPAddr, null, null);
    }

    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  } // remCategoryUserPermissions()

  // ----------------------------------------------------------

  /**************************/
  /* End Category methods */
  /**************************/

  // ----------------------------------------------------------

  public void writeXML(String sOutStream, String sClass, String sKey) throws DBException {
    DBException oDBEx;
    FileWriter oFile;
    Class oObjClass;
    DBPersist oInstance;
    String sXML;
    Object[] PK = { sKey };

    oExceptions.clear();

    try {
      oObjClass = Class.forName("hipergate." + sClass);
      oInstance = (DBPersist) oObjClass.newInstance();
    }
    catch (ClassNotFoundException oNotFoundEx) {
      oDBEx = new DBException(oNotFoundEx.getMessage());
      oExceptions.addElement(oNotFoundEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    catch (IllegalAccessException oIllegalAccessEx) {
      oDBEx = new DBException(oIllegalAccessEx.getMessage());
      oExceptions.addElement(oIllegalAccessEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
    catch (InstantiationException oInstanceEx) {
      oDBEx = new DBException(oInstanceEx.getMessage());
      oExceptions.addElement(oInstanceEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }


    try {
      oInstance.load(oActiveConnection, PK);
    }
    catch (SQLException oSQLEx) {
      oDBEx = new DBException(oSQLEx.getMessage());
      oExceptions.addElement(oSQLEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }

    sXML = oInstance.toXML("  ", "\n");

    try {
      oFile = new FileWriter("C:\\" + sOutStream, true);
      oFile.write (sXML);
      oFile.close();
    }
    catch (IOException oIOEx) {
      oDBEx = new DBException(oIOEx.getMessage());
      oExceptions.addElement(oIOEx);
      oExceptions.addElement(oDBEx);
      throw oDBEx;
    }
  }
}




