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

package com.knowgate.projtrack;

import java.text.SimpleDateFormat;

import java.util.Date;
import java.util.Stack;
import java.util.HashMap;

import com.knowgate.debug.DebugFile;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;

import com.knowgate.acl.ACLUser;
import com.knowgate.misc.Gadgets;
import com.knowgate.jdc.JDCConnection;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * <p>Project</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public class Project extends DBPersist {

  /**
   * Create empty an Project
   */
  public Project() {
    super(DB.k_projects, "Project");
  }

  /**
   * Create empty an Project and set gu_project.
   * No data is loaded from database.
   * @param sPrjId Project Unique Identifier.
   */
  public Project(String sPrjId) {
    super(DB.k_projects, "Project");

    put(DB.gu_project, sPrjId);
  }

  public Project(JDCConnection oConn, String sPrjId) throws SQLException {
    super(DB.k_projects, "Project");

    put (DB.gu_project, sPrjId);

    load (oConn, new Object[]{sPrjId});
  }

  // ----------------------------------------------------------

  /**
   * Get Project Top Parent.
   * Browse recursively k_projects table until finding the top most parent for Project.
   * @param oConn Database Connection
   * @return GUID of top most parent Project or <b>null</b> if this is a top Project.
   * @throws SQLException
   */
  public String topParent(JDCConnection oConn) throws SQLException {
    String sCurrent;
    String sParent;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.topParent([Connection])");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.id_parent + " FROM " + DB.k_projects + " WHERE " + DB.gu_project + "='" + getStringNull(DB.gu_project, "null") + "')");
    }

    oStmt = oConn.prepareStatement("SELECT " + DB.id_parent + " FROM " + DB.k_projects + " WHERE " + DB.gu_project + "=?");

    sParent = getString(DB.gu_project);
    do {
      sCurrent = sParent;

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(1, " + sCurrent + ")");

      oStmt.setString(1, sCurrent);
      oRSet = oStmt.executeQuery();
      if (oRSet.next())
        sParent = oRSet.getString(1);
      else
        sParent = null;
      oRSet.close();
    } while (sParent!=null);

    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Project.topParent() : " + sCurrent);
    }

    return sCurrent;
  } // topParent();

  // ----------------------------------------------------------

  /**
   * <P>Clone Project</P>
   * When a project is cloned all its subprojects, duites and bugs are also cloned.
   * @param oConn Database Connection
   * @return GUID of new cloned Project
   * @throws SQLException
   * @throws IllegalAccessException
   */
  public String clone (JDCConnection oConn)
    throws SQLException, IllegalAccessException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.clone([Connection])");
      DebugFile.incIdent();
    }

    Project oProj;
    Duty oDuty = new Duty();
    Bug oBug = new Bug();
    HashMap oSubProjMap = new HashMap();
    Object[] aChild = new Object[]{getString(DB.gu_project)};

    oProj = new Project(oConn, getString(DB.gu_project));
    oProj.replace(DB.gu_project, Gadgets.generateUUID());
    oProj.store(oConn);

    oSubProjMap.put(aChild[0], oProj.get(DB.gu_project));

    DBSubset oChilds = new DBSubset(DB.k_projects, DB.gu_project, DB.id_parent + "=?", 10);
    DBSubset oDuties = new DBSubset (DB.k_duties, oDuty.getTable(oConn).getColumnsStr(), DB.gu_project + "=?", 10);
    DBSubset oBugs = new DBSubset (DB.k_bugs, oBug.getTable(oConn).getColumnsStr(), DB.gu_project + "=?", 10);

    int iDuties = oDuties.load (oConn, new Object[]{get(DB.gu_project)});

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iDuties) + " duties loaded for " + getString(DB.gu_project));

    for (int d=0; d<iDuties; d++) {
      oDuties.setElementAt(Gadgets.generateUUID(), 0, d);
      oDuties.setElementAt(oProj.get(DB.gu_project), 2, d);
    }

    try { oDuties.store(oConn, oDuty.getClass(), true); }
    catch (java.lang.InstantiationException ignore) { /* never thrown*/ }

    int iBugs = oBugs.load (oConn, new Object[]{get(DB.gu_project)});

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iBugs) + " bugs loaded for " + getString(DB.gu_project));

    for (int b=0; b<iBugs; b++) {
      oBugs.setElementAt(Gadgets.generateUUID(), 0, b);
      oBugs.setElementAt(oProj.get(DB.gu_project), 3, b);
    }

    try { oBugs.store(oConn, oBug.getClass(), true); }
    catch (java.lang.InstantiationException ignore) { /* never thrown*/ }

    Stack oPending = new Stack();

    int iChilds = oChilds.load(oConn, aChild);

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iChilds) + " childs loaded for " + getString(DB.gu_project));

    for (int c=0; c<iChilds;c++) oPending.push(oChilds.get(0,c));

    while (!oPending.empty()) {
      aChild[0] = oPending.pop();

      iChilds = oChilds.load(oConn, aChild);

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iChilds) + " childs loaded for " + aChild[0]);

      oProj = new Project(oConn, (String) aChild[0]);
      oProj.replace(DB.gu_project, Gadgets.generateUUID());
      if (oSubProjMap.containsKey(oProj.get(DB.id_parent)))
        oProj.replace(DB.id_parent, oSubProjMap.get(oProj.get(DB.id_parent)));
      oProj.store(oConn);

      iDuties = oDuties.load (oConn, new Object[]{oProj.get(DB.gu_project)});

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iDuties) + " duties loaded for " + oProj.getString(DB.gu_project));

      for (int d=0; d<iDuties; d++) {
        oDuties.setElementAt(Gadgets.generateUUID(), 0, d);
        oDuties.setElementAt(oProj.get(DB.gu_project), 2, d);
      }

      try {
        oDuties.store(oConn, oDuty.getClass(), true);
      }
      catch (java.lang.InstantiationException ignore) { /* never thrown*/ }

      iBugs = oBugs.load (oConn, new Object[]{oProj.get(DB.gu_project)});

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iBugs) + " bugs loaded for " + oProj.getString(DB.gu_project));

      for (int b=0; b<iBugs; b++) {
        oBugs.setElementAt(Gadgets.generateUUID(), 0, b);
        oBugs.setElementAt(oProj.get(DB.gu_project), 3, b);
      }

      try {
        oBugs.store(oConn, oBug.getClass(), true);
      }
      catch (java.lang.InstantiationException ignore) { /* never thrown*/ }

      oSubProjMap.put (aChild[0], oProj.getString(DB.gu_project));

      for (int c=0; c<iChilds;c++)
        oPending.push(oChilds.get(0,c));
    } // wend

    // Re-expandir todos los hijos del padre absoluto del clon
    oProj = new Project((String) oSubProjMap.get(get(DB.gu_project)));
    String sTopParent = oProj.topParent(oConn);

    if (DebugFile.trace) DebugFile.writeln("topparent=" + (null!=sTopParent ? sTopParent : "null"));

    if (null!=sTopParent)
      oProj = new Project(sTopParent);

    oProj.expand(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Project.topParent() : " + (String) oSubProjMap.get(get(DB.gu_project)));
    }

    return (String) oSubProjMap.get(get(DB.gu_project));
  } // clone

  // ----------------------------------------------------------

  /**
   * Load Project.
   * If Project is assigned to a Company then Company Legal Name
   * (k_companies.nm_legal) is loaded into property DB.tx_company.
   * If Project is assigned to a Contact then Contact Full Name
   * (tx_name+tx_surname) is loaded into property DB.tx_contact.
   * @param oConn JDCConnection
   * @param PKVals Array of one String containing the GUID of the Project to be loaded
   * @return
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    boolean bRetVal = super.load(oConn, PKVals);
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.load([Connection], Object[])");
      DebugFile.incIdent();
    }

    if (bRetVal) {
      if (!isNull(DB.gu_company) && DBBind.exists(oConn, DB.k_companies, "U")) {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "='" + getStringNull(DB.gu_company, "null") + "'");

        oStmt = oConn.prepareStatement("SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, getString(DB.gu_company));
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          replace(DB.tx_company, oRSet.getString(1));
        else if (AllVals.containsKey(DB.tx_company))
          remove(DB.tx_company);
        oRSet.close();
        oStmt.close();
      } // fi (exists(k_companies))
      else if (AllVals.containsKey(DB.tx_company))
        remove(DB.tx_company);

      if (!isNull(DB.gu_contact) && DBBind.exists(oConn, DB.k_contacts, "U")) {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DBBind.Functions.ISNULL + "(" + DB.tx_name + ",'')" + DBBind.Functions.CONCAT + "' '" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(" + DB.tx_surname + ",'') FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "='" + getStringNull(DB.gu_contact,"null") + "'");

		if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
          oStmt = oConn.prepareStatement("SELECT CONCAT(" + DBBind.Functions.ISNULL + "(" + DB.tx_name + ",''), ' ', " + DBBind.Functions.ISNULL + "(" + DB.tx_surname + ",'')) FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
		else
          oStmt = oConn.prepareStatement("SELECT " + DBBind.Functions.ISNULL + "(" + DB.tx_name + ",'')" + DBBind.Functions.CONCAT + "' '" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(" + DB.tx_surname + ",'') FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

        oStmt.setString(1, getString(DB.gu_contact));
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          replace(DB.tx_contact, oRSet.getString(1));
        else if (AllVals.containsKey(DB.tx_contact))
          remove(DB.tx_contact);
        oRSet.close();
        oStmt.close();
      } // fi (exists(k_contacts))
      else if (AllVals.containsKey(DB.tx_contact))
        remove(DB.tx_contact);

      if (!isNull(DB.gu_user) && DBBind.exists(oConn, DB.k_users, "U")) {
		
		if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
          if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT CONCAT(" + DBBind.Functions.ISNULL + "(" + DB.nm_user + ",''), ' ', " + DBBind.Functions.ISNULL + "(" + DB.tx_surname1 + ",'')," + DBBind.Functions.ISNULL + "(" + DB.tx_surname2 + ",'')) FROM " + DB.k_users + " WHERE " + DB.gu_user + "='"+getStringNull(DB.gu_user,"null")+"')");
          oStmt = oConn.prepareStatement("SELECT CONCAT(" + DBBind.Functions.ISNULL + "(" + DB.nm_user + ",''), ' ', " + DBBind.Functions.ISNULL + "(" + DB.tx_surname1 + ",'')," + DBBind.Functions.ISNULL + "(" + DB.tx_surname2 + ",'')) FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?",
        							     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
		}
        else {
          if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DBBind.Functions.ISNULL + "(" + DB.tx_name + ",'')" + DBBind.Functions.CONCAT + "' '" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(" + DB.tx_surname + ",'') FROM " + DB.k_users + " WHERE " + DB.gu_user + "='" + getStringNull(DB.gu_user,"null") + "'");
          oStmt = oConn.prepareStatement("SELECT " + DBBind.Functions.ISNULL + "(" + DB.nm_user + ",'')" + DBBind.Functions.CONCAT + "' '" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(" + DB.tx_surname1 + ",'') " + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(" + DB.tx_surname2 + ",'') FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?",
        							     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        }
        oStmt.setString(1, getString(DB.gu_contact));
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          replace(DB.tx_user, oRSet.getString(1));
        else if (AllVals.containsKey(DB.tx_user))
          remove(DB.tx_user);
        oRSet.close();
        oStmt.close();
      } // fi (exists(k_contacts))
      else if (AllVals.containsKey(DB.tx_user))
        remove(DB.tx_user);

    } // fi (super.load)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Project.load() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // load

  // ----------------------------------------------------------

  /**
   * Load Project.
   * If Project is assigned to a Company then Company Legal Name
   * (k_companies.nm_legal) is loaded into property DB.tx_company.
   * If Project is assigned to a Contact then Contact Full Name
   * (tx_name+tx_surname) is loaded into property DB.tx_contact.
   * @param oConn JDCConnection
   * @param sGuProject Project GUID
   * @return
   * @throws SQLException
   * @since 4.0
   */

  public boolean load(JDCConnection oConn, String sGuProject) throws SQLException {
    return load(oConn, new Object[]{sGuProject});
  }
  
  // ----------------------------------------------------------

  /**
   * <p>Delete Project.</p>
   * Calls k_sp_del_project stored procedure.<br>
   * Deletion includes Project Childs, Duties and Bugs.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    return Project.delete(oConn, getString(DB.gu_project));
  }

  // ----------------------------------------------------------

  /**
   * Store Project
   * If gu_project is null a new GUID is automatically assigned.<br>
   * Calls internally to expand() method for re-expanding k_project_expand table.<br>
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    boolean bRetVal;
    String sTopParent;
    Project oTopParent;
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.store([Connection])");
      DebugFile.incIdent();
    }

    if (!AllVals.containsKey(DB.gu_project))
      put(DB.gu_project, Gadgets.generateUUID());

    bRetVal = super.store(oConn);

    // Re-expandir todos los hijos del padre absoluto de este proyecto
    sTopParent = topParent(oConn);

    if (DebugFile.trace) DebugFile.writeln("topparent=" + (null!=sTopParent ? sTopParent : "null"));

    if (null!=sTopParent) {
      oTopParent = new Project(sTopParent);
      oTopParent.expand(oConn);
      oTopParent = null;
    } // fi (sTopParent)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Project.store() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store()

  // ----------------------------------------------------------

  /**
   * <p>Compute total project cost</p>
   * Total project cost is the sum of costs of all duties from the project<br>
   * This method call stored procedure k_sp_prj_cost
   * @param oConn Database Connection
   * @return Sum of all duty costs for project
   * @throws SQLException
   * @throws NumberFormatException
   */
  public float cost (JDCConnection oConn) throws SQLException, NumberFormatException {
    float fCost = 0;
    Object oCost;
    Statement oStmt;
    ResultSet oRSet;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.cost([Connection])");
      DebugFile.incIdent();
      DebugFile.writeln("Connection schema name is "+oConn.getSchemaName());
	  if (oConn.getPool()!=null) {
	    if (oConn.getPool().getDatabaseBinding()!=null) {
          DebugFile.writeln("Environment schema name is "+((DBBind) oConn.getPool().getDatabaseBinding()).getProperty("schema"));
	    }
	  }
    }

    switch (oConn.getDataBaseProduct()) {
      case JDCConnection.DBMS_ORACLE:
        sSQL = "SELECT k_sp_prj_cost ('" + getString(DB.gu_project) + "') FROM DUAL";
        break;
      case JDCConnection.DBMS_MSSQL:
        String sSchema = oConn.getSchemaName();
        if (null!=sSchema) {
          if (sSchema.indexOf('\\')>0)
            sSQL = "SELECT k_sp_prj_cost ('" + getString(DB.gu_project) + "')";
          else
            sSQL = "SELECT " + sSchema + ".k_sp_prj_cost ('" + getString(DB.gu_project) + "')";
        } else {
          sSQL = "SELECT k_sp_prj_cost ('" + getString(DB.gu_project) + "')";
        }
        break;
      default:
        sSQL = "SELECT k_sp_prj_cost ('" + getString(DB.gu_project) + "')";
    }

    oStmt = oConn.createStatement();

    if (DebugFile.trace)
      DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

    oRSet = oStmt.executeQuery (sSQL);

    oRSet.next();

    oCost = oRSet.getObject(1);

    oRSet.close();

    oStmt.close();

    fCost = Float.parseFloat(oCost.toString());

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Project.store() : " + String.valueOf(fCost));
    }

    return fCost;
  } // cost

  // ----------------------------------------------------------

  /**
   * <p>Get all Project Childs as a DBSubset.</p>
   * @param oConn Database Connection
   * @return DBSubset with the following structure:<br>
   * <table border=1 cellpadding=4>
   * <tr><td><b>gu_project</b></td><td><b>nm_project</b></td><td><b>od_level</b></td><td><b>od_walk</b></td><td><b>id_parent</b></td></tr>
   * <tr><td>Project GUID</td><td>Project Name</td><td>Depth Level</td><td>Walk order within level</td><td>Inmediate Parent</td></tr>
   * </table>
   * @throws SQLException
   */
  public DBSubset getAllChilds(JDCConnection oConn) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.getAllChilds([Connection])");
      DebugFile.incIdent();
    }

    DBSubset oTree = new DBSubset(DB.k_project_expand + " e," + DB.k_projects + " p",
                                  "e."+DB.gu_project + ",e." + DB.nm_project + ",e." + DB.od_level + ",e." + DB.od_walk + ",e." + DB.gu_parent + ",p." +DB.id_status + ",p." +DB.gu_company + ",p." +DB.gu_contact + ",p." +DB.gu_user,
                                  "e."+DB.gu_project + "=p." + DB.gu_project + " AND " +
                                  DB.gu_rootprj + "='" + getString(DB.gu_project) + "' ORDER BY " + DB.od_walk, 50);

    int iChildCount = oTree.load(oConn);

    if (DebugFile.trace) {
      for (int c=0; c<iChildCount; c++)
        DebugFile.writeln(String.valueOf(oTree.getInt(3,c))+" lv="+String.valueOf(oTree.getInt(2,c))+",gu="+oTree.getString(0,c)+",nm="+oTree.getString(1,c));
      DebugFile.decIdent();
      DebugFile.writeln("End Project.getAllChilds() : "+String.valueOf(iChildCount));
    }

    return oTree;
  }

  // ----------------------------------------------------------

  /**
   * <p>Expand Project childs.</p>
   * Calls k_sp_prj_expand stored procedure.<br>
   * Expansion is stored at k_project_expand table.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public void expand(JDCConnection oConn) throws SQLException {
    CallableStatement oCall;
    Statement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.expand([Connection])");
      DebugFile.incIdent();
    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace) DebugFile.writeln("Connection.executeQuery(SELECT  k_sp_prj_expand ('" + getStringNull(DB.gu_project,"null") + "')");
      oStmt = oConn.createStatement();
      oStmt.executeQuery("SELECT k_sp_prj_expand ('" + getString(DB.gu_project) + "')");
      oStmt.close();
    } else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_prj_expand ('" + getStringNull(DB.gu_project,"null") + "')}");
      oCall = oConn.prepareCall("{ call k_sp_prj_expand ('" + getString(DB.gu_project) + "') }");
      oCall.execute();
      oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Project.expand()");
    }
  } // expand()

  // ----------------------------------------------------------

  private String snapshotBuilder(JDCConnection oConn, String sIdent) throws SQLException {
	final String s2 = sIdent+sIdent;
	final String s3 = sIdent+sIdent+sIdent;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.snapshotBuilder([Connection])");
      DebugFile.incIdent();
    }
	
	String sXml = toXML(sIdent);

	DBSubset oDuties = new DBSubset (DB.k_duties, "*", DB.gu_project+"=? ORDER BY "+DB.dt_modified+" DESC", 50);
	int nDuties = oDuties.load(oConn, new Object[]{getString(DB.gu_project)});

    if (DebugFile.trace) DebugFile.writeln("duties count is "+String.valueOf(nDuties));

	DBSubset oBugs = new DBSubset (DB.k_bugs, "*", DB.gu_project+"=? ORDER BY "+DB.dt_modified+" DESC", 50);
	int nBugs = oBugs.load(oConn, new Object[]{getString(DB.gu_project)});

    if (DebugFile.trace) DebugFile.writeln("bugs count is "+String.valueOf(nBugs));

	DBSubset oSubp = new DBSubset (DB.k_projects, "*", DB.	id_parent+"=? ORDER BY "+DB.nm_project, 20);
	int nSubp = oSubp.load(oConn, new Object[]{getString(DB.gu_project)});

    if (DebugFile.trace) DebugFile.writeln("subprojects count is "+String.valueOf(nSubp));

    StringBuffer oSS = new StringBuffer(sXml.length()+256*nDuties+256*nBugs+4000*nSubp);

	oSS.append(sXml.substring(0,sXml.length()-(sIdent+"</Project>").length()));

	Duty oDut = new Duty();
	oDut.getTable(oConn);
	oSS.append(s2+"<Duties count=\""+String.valueOf(nDuties)+"\">\n");
	for (int d=0; d<nDuties; d++) {
	  oDut.clear();
	  oDut.putAll(oDuties.getRowAsMap(d));
	  oSS.append(oDut.toXML(s3));
	  oSS.append("\n");
	} // next
	oDuties = null;
	oDut = null;
	oSS.append(s2+"</Duties>\n");
	
	Bug oBug = new Bug();
	oBug.getTable(oConn);
	oSS.append(s2+"<Bugs count=\""+String.valueOf(nBugs)+"\">\n");
	for (int b=0; b<nBugs; b++) {
	  oBug.clear();
	  oBug.putAll(oBugs.getRowAsMap(b));
	  oSS.append(oBug.toXML(s3));	  
	  oSS.append("\n");
	} // next
	oBugs = null;
	oBug = null;
	oSS.append(s2+"</Bugs>\n");

	Project oSub = new Project();
	oSub.getTable(oConn);
	oSS.append(s2+"<Subprojects count=\""+String.valueOf(nSubp)+"\">\n");
	for (int p=0; p<nSubp; p++) {
	  oSub.clear();
	  oSub.putAll(oSubp.getRowAsMap(p));
	  oSS.append(oSub.snapshotBuilder(oConn,s3));
	} // next
	oSubp = null;
	oSub = null;
	oSS.append(s2+"</Subprojects>\n");
	oSS.append(sIdent+"</Project>\n");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Project.snapshotBuilder()");
    }

	return oSS.toString(); 
  } // snapshotBuilder

  // ----------------------------------------------------------

  /**
   * <p>Get snapshot view of the whole project</p>
   * @param oConn Database Connection
   * @return ProjectSnapshot object instance
   * @throws SQLException
   */
  public ProjectSnapshot snapshot(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.snapshot([Connection])");
      DebugFile.incIdent();
    }

    SimpleDateFormat oXMLDate = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");

	ProjectSnapshot oPrjSnpSht = new ProjectSnapshot();

	oPrjSnpSht.setProject(getString(DB.gu_project));
	oPrjSnpSht.setTitle(getStringNull(DB.nm_project,"")+" "+new Date().toString());
    if (sAuditUsr!=null) oPrjSnpSht.setWriter(sAuditUsr);
    String sSnapshot = snapshotBuilder(oConn,"  ");
    StringBuffer oData = new StringBuffer(sSnapshot.length()+1000);
    oData.append("<ProjectSnapshot>\n");
    oData.append("  <gu_project>"+getString(DB.gu_project)+"</gu_project>\n");
    oData.append("  <nm_project><![CDATA["+getStringNull(DB.nm_project,"")+"]]></nm_project>\n");
    oData.append("  <dt_created>"+oXMLDate.format(new Date())+"</dt_created>\n");
    if (sAuditUsr==null) {
      oData.append("  <tx_full_name/>\n");
    } else {
      ACLUser oWrt = new ACLUser(oConn, sAuditUsr);
      oData.append("  <tx_full_name><![CDATA["+oWrt.getStringNull(DB.nm_user,"")+" "+oWrt.getStringNull(DB.tx_surname1,"")+" "+oWrt.getStringNull(DB.tx_surname2,"")+"]]></tx_full_name>\n");      
    }
    oData.append(sSnapshot);
    oData.append("</ProjectSnapshot>");
	oPrjSnpSht.setData(oData.toString());

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Project.snapshot()");
    }

	return oPrjSnpSht;
  } // ProjectSnapshot

  // **********************************************************
  // Static Methods

  /**
   * <p>Delete Project.</p>
   * Calls k_sp_del_project stored procedure.<br>
   * Deletion includes Project Childs, Duties and Bugs.
   * @param oConn Database Connection
   * @param sProjectGUID GUID of project to be deleted.
   * @throws NullPointerException if sProjectGUID is null
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sProjectGUID)
    throws SQLException,NullPointerException {
    boolean bRetVal;

    if (null==sProjectGUID)
      throw new NullPointerException("Project.delete() GUID of project to be deleted may not be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Project.delete([Connection], " + sProjectGUID + ")");
      DebugFile.incIdent();
    }

    String sTopParent = new Project(sProjectGUID).topParent(oConn);

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace) DebugFile.writeln("Connection.executeQuery(SELECT k_sp_del_project ('" + sProjectGUID + "'))");
      Statement oStmt = oConn.createStatement();
      ResultSet oRSet = oStmt.executeQuery("SELECT k_sp_del_project ('" + sProjectGUID + "')");
      oRSet.close();
      oStmt.close();
      bRetVal = true;
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_project ('" + sProjectGUID + "')})");
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_project ('" + sProjectGUID + "')}");
      bRetVal = oCall.execute();
      oCall.close();
    }

    if (DebugFile.trace) DebugFile.writeln("sTopParent="+sTopParent);

    if (!sProjectGUID.equals(sTopParent)) new Project(sTopParent).expand(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Project.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete()
  
  // **********************************************************
  // Public Constants

  public static final short ClassId = 80;

}
