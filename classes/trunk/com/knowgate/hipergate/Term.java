/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.SQLException;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;

import java.util.LinkedList;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;

/**
 * <p>Thesauri Term</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */

public class Term extends DBPersist {

  // ---------------------------------------------------------------------------

  public Term() {
    super(DB.k_thesauri, "Term");
  }

  // ---------------------------------------------------------------------------

  /**
   * Load a Term given its Domain and Text
   * @param oConn Database Connection
   * @param iIdDomain Domain to which term belongs
   * @param sTxTerm Term Text
   * @return <b>true</b> if a term was found with given text
   * @throws SQLException
   */
  public boolean load (JDCConnection oConn, int iIdDomain, String sTxTerm) throws SQLException {
    boolean bRetVal;
    PreparedStatement oStmt = oConn.prepareStatement(
    	"SELECT "+DB.gu_term+" FROM "+DB.k_thesauri+" WHERE "+DB.id_domain+"=? AND "+DB.tx_term+"=?",
    	ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt(1, iIdDomain);
    oStmt.setString(2, sTxTerm);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      String sGuTerm = oRSet.getString(1);
      oRSet.close();
      oStmt.close();
      bRetVal = super.load(oConn, new Object[]{sGuTerm});
    } else {
      bRetVal = false;
      oRSet.close();
      oStmt.close();
    }
    return bRetVal;
  } // load

  // ---------------------------------------------------------------------------

  /**
   * Delete a Term and all its synonyms
   * @param oConn Database Connection
   * @param sTermGUID Term GUID
   * @throws SQLException
   */

  public boolean delete (JDCConnection oConn) throws SQLException {
    return Term.delete(oConn, getString(DB.gu_term));
  }

  // ---------------------------------------------------------------------------

  /**
   * Delete a Term and all its synonyms
   * @param oConn Database Connection
   * @param sTermGUID Term GUID
   * @throws SQLException
   */
  public static boolean delete (JDCConnection oConn, String sTermGUID) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Term.delete([Connection], " + sTermGUID + ")");
      DebugFile.incIdent();
    }

    Statement oUpdt = oConn.createStatement();

     if (DBBind.exists(oConn, DB.k_companies, "U")) {
       if (DebugFile.trace)
         DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_companies + " SET " + DB.gu_geozone + "=NULL WHERE " + DB.gu_geozone + "='" + sTermGUID + "')");

       oUpdt.executeUpdate("UPDATE " + DB.k_companies + " SET " + DB.gu_geozone + "=NULL WHERE " + DB.gu_geozone + "='" + sTermGUID + "'");
     }

     if (DBBind.exists(oConn, DB.k_contacts, "U")) {
       if (DebugFile.trace)
         DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_contacts + " SET " + DB.gu_geozone + "=NULL WHERE " + DB.gu_geozone + "='" + sTermGUID + "')");

       oUpdt.executeUpdate("UPDATE " + DB.k_contacts + " SET " + DB.gu_geozone + "=NULL WHERE " + DB.gu_geozone + "='" + sTermGUID + "'");
     }

     if (DBBind.exists(oConn, DB.k_member_address, "U")) {
       if (DebugFile.trace)
         DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_member_address + " SET " + DB.gu_geozone + "=NULL WHERE " + DB.gu_geozone + "='" + sTermGUID + "')");

       oUpdt.executeUpdate("UPDATE " + DB.k_member_address + " SET " + DB.gu_geozone + "=NULL WHERE " + DB.gu_geozone + "='" + sTermGUID + "'");
     }

     oUpdt.close();

    // Find root term
    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    if (DebugFile.trace)
      DebugFile.writeln("Statement.executeQuery(SELECT " + DB.gu_rootterm + " FROM " + DB.k_thesauri + " WHERE " + DB.gu_term + "='" + sTermGUID + "')");

    ResultSet oRSet = oStmt.executeQuery("SELECT " + DB.gu_rootterm + " FROM " + DB.k_thesauri + " WHERE " + DB.gu_term + "='" + sTermGUID + "'");

    boolean bExists = oRSet.next();
    String sRootTerm = null;

    if (bExists) sRootTerm = oRSet.getString(1);

    oRSet.close();
    oStmt.close();

    if (!bExists) return false;

    Term oDlte = new Term();
    oDlte.load(oConn, new Object[]{sTermGUID});
    String sTermN = DB.id_term + String.valueOf(oDlte.level()-1);

    oStmt = oConn.createStatement();

    // Delete Synonyms
    if (DebugFile.trace)
      DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_thesauri + " WHERE " + DB.gu_synonym + "='" + sTermGUID + "')");

    oStmt.executeUpdate("DELETE FROM " + DB.k_thesauri + " WHERE " + DB.gu_synonym + "='" + sTermGUID + "'");

    // Delete Term and Childs
    if (DebugFile.trace)
      DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_thesauri + " WHERE " + sTermN + "=" + String.valueOf(oDlte.getInt(sTermN)) + " AND " + DB.id_domain + "=" + oDlte.getInt(DB.id_domain) + ")");

    oStmt.executeUpdate("DELETE FROM " + DB.k_thesauri + " WHERE " + sTermN + "=" + String.valueOf(oDlte.getInt(sTermN)) + " AND " + DB.id_domain + "=" + oDlte.getInt(DB.id_domain));

    // Delete root entry if term is a root one
    if (sRootTerm.equals(sTermGUID))
      oStmt.executeUpdate("DELETE FROM " + DB.k_thesauri_root + " WHERE " + DB.gu_rootterm + "='" + sTermGUID + "'");

    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Term.delete([Connection])");
    }

    return true;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get term level [1..10]
   */
  public int level () {
    int iLevel;

    if (isNull("id_term1"))
      iLevel = 1;
    else if (isNull("id_term2"))
      iLevel = 2;
    else if (isNull("id_term3"))
      iLevel = 3;
    else if (isNull("id_term4"))
      iLevel = 4;
    else if (isNull("id_term5"))
      iLevel = 5;
    else if (isNull("id_term6"))
      iLevel = 6;
    else if (isNull("id_term7"))
      iLevel = 7;
    else if (isNull("id_term8"))
      iLevel = 8;
    else if (isNull("id_term9"))
      iLevel = 9;
    else
      iLevel = 10;

    return iLevel;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get term numeric Id.
   * @return int
   * @since 7.0
   */

  public int id () {
    int iId;

    if (isNull("id_term1"))
    	iId = getInt(DB.id_term+"0");
    else if (isNull("id_term2"))
    	iId = getInt(DB.id_term+"1");
    else if (isNull("id_term3"))
    	iId = getInt(DB.id_term+"2");
    else if (isNull("id_term4"))
    	iId = getInt(DB.id_term+"3");
    else if (isNull("id_term5"))
    	iId = getInt(DB.id_term+"4");
    else if (isNull("id_term6"))
    	iId = getInt(DB.id_term+"5");
    else if (isNull("id_term7"))
    	iId = getInt(DB.id_term+"6");
    else if (isNull("id_term8"))
    	iId = getInt(DB.id_term+"7");
    else if (isNull("id_term9"))
    	iId = getInt(DB.id_term+"8");
    else
    	iId = getInt(DB.id_term+"9");

    return iId;
  }
 
  // ---------------------------------------------------------------------------

  /**
   * Get Term Parent GUID
   * @param oConn Database Connection
   * @return Parent Term GUID or <b>null</b> if this is a root term
   * @throws SQLException
   */
  public String getParent (JDCConnection oConn) throws SQLException {
    int iLevel;
    String sParentId;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Term.getParent([Connection])");
      DebugFile.incIdent();
    }

    iLevel = level();

    Statement oStmt;
    ResultSet oRSet;

    if (1==iLevel) {
      sParentId = null;
    }
    else if (2==iLevel) {
      sParentId = getString(DB.gu_rootterm);
    }
    else {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeQuery(SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " WHERE " + DB.id_term + String.valueOf(iLevel-2) + "=" + String.valueOf(getInt(DB.id_term + String.valueOf(iLevel-2))) + " AND " + DB.id_term + String.valueOf(iLevel-1) + " IS NULL)");

      oRSet = oStmt.executeQuery("SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " WHERE " + DB.id_term + String.valueOf(iLevel-2) + "=" + String.valueOf(getInt(DB.id_term + String.valueOf(iLevel-2))) + " AND " + DB.id_term + String.valueOf(iLevel-1) + " IS NULL");

      if (oRSet.next())
        sParentId = oRSet.getString(1);
      else
        sParentId = null;

      oRSet.close();
      oStmt.close();

      if (null==sParentId)
        throw new SQLException ("Parent key " + String.valueOf(getInt(DB.id_term + String.valueOf(iLevel-2))) + " not found");
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Term.getParent() : " + sParentId);
    }

    return sParentId;
  } // getParent

  // ---------------------------------------------------------------------------

  private void browse (JDCConnection oConn, int iScope, LinkedList oTermsList, String sColList, String[] aColArray)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Term.browse(gu_term=" + getStringNull(DB.gu_term,"null") + ",tx_term=" + getStringNull(DB.tx_term,"null") + ",level=" + String.valueOf(level()) + ",columns=" + String.valueOf(aColArray.length) + ")");
      DebugFile.incIdent();
    }

    int iChilds = 0;
    int iLevel = level();
    int iCols = aColArray.length;

    if (iLevel<10) {
      DBSubset oChilds;

      if (DebugFile.trace && iLevel>0)
        DebugFile.writeln("id_term" + String.valueOf(iLevel-1) + "=" + get(DB.id_term + String.valueOf(iLevel-1)));

      if (9==iLevel)
        oChilds = new DBSubset(DB.k_thesauri, sColList, DB.id_term + "9 IS NOT NULL AND " + DB.id_term + "8=" + String.valueOf(getInt(DB.id_term + "8")), 10);
      else {
        oChilds = new DBSubset(DB.k_thesauri, sColList,
                               DB.id_term + String.valueOf(iLevel) + " IS NOT NULL AND " +
                               DB.id_term + String.valueOf(iLevel+1) + " IS NULL AND " +
                               DB.id_term + String.valueOf(iLevel-1) + "=" + String.valueOf(getInt(DB.id_term + String.valueOf(iLevel-1))), 10);
      }

      iChilds = oChilds.load(oConn);

      Term oChld = new Term();

      for (int t=0; t<iChilds; t++) {
        oChld = new Term();
        oChld.getTable(oConn); // Do not remove this line

        for (int c=0; c<iCols; c++)
          oChld.put(aColArray[c], oChilds.get(c, t));

        oTermsList.addLast(oChld);

        if (SCOPE_ALL==iScope)
          oChld.browse (oConn, iScope, oTermsList, sColList, aColArray);
      } // next t
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Term.browse() : " + String.valueOf(iChilds));
    }
  } // browse

  /**
   * Get child terms for this term.
   * @param oConn Database Connection
   * @param iScope SCOPE_ONE for just first level childs or SCOPE_ALL for childs from all levels down
   * @return LinkedList of Terms with in-depth child walkthrought<BR>
   * for example, if representing a geographic thesauri: WORLD,AMERICA,NORTH AMERICA,USA,CANADA,MEXICO,SOUTH AMERICA,BRAZIL,ARGENTINA,CHILE,EUROPE,SPAIN,FRANCE,GERMANY
   * @throws SQLException
   */
  public LinkedList getChilds (JDCConnection oConn, int iScope)
    throws SQLException {
    LinkedList oTermsList = new LinkedList();

    if (isNull(DB.gu_term)) {
      if (DebugFile.trace)
        DebugFile.writeln("ERROR - Term.getChilds() Attemped to get childs of an unloaded Term.");

      throw new NullPointerException("Term.getChilds() Attemped to get childs of an unloaded Term");
    }

    // ***************************
    // Get k_thesauri columns list

    Statement oStmt = oConn.createStatement();
    ResultSet oRSet = oStmt.executeQuery("SELECT * FROM " + DB.k_thesauri + " WHERE 1=0");
    ResultSetMetaData oMDat = oRSet.getMetaData();

    int iCols = oMDat.getColumnCount();
    String[] aColArray = new String[iCols];
    StringBuffer sColList = new StringBuffer(32*iCols);

    for (int c=0; c<iCols; c++) {
      aColArray[c] = oMDat.getColumnName(c+1).toLowerCase();
      sColList.append(aColArray[c]);
      if (c!=iCols-1) sColList.append(",");
    }

    oRSet.close();
    oStmt.close();

    // End get columns list
    // ********************

    browse (oConn, iScope, oTermsList, sColList.toString(), aColArray);

    return oTermsList;
  } // getChilds

  /**
   * Check whether or not this term is child or grand child of another parent term
   * @param oConn Database Connection
   * @param iDomainId int Domain Numeric Unique Identifier
   * @param sTxParent String Parent Term text
   * @return
   * @throws SQLException
   * @since 7.0
   */
  public boolean isGrandChildOf(JDCConnection oConn, int iIdDomain, String sTxParent)
    throws SQLException {
    String sParentGUID = Term.getIdFromText(oConn, iIdDomain, sTxParent);
    if (null==sParentGUID) throw new SQLException("Term.isGrandChildOf("+sTxParent+") Parent was not found");
    Term oParent = new Term();
    oParent.load(oConn, sParentGUID);
    int iParentId = oParent.id();
    boolean bIsGrandChild=false;
    for (int l=1; l<level() && !bIsGrandChild; l++)
      bIsGrandChild = (getInt(DB.id_term+String.valueOf(l))==iParentId);
    return bIsGrandChild;

  } // isGrandChildOf

  /**
   * Get a term GUID given its exact singular or plural name
   * @param oConn Database Connection
   * @param iDomainId Domain Numeric Unique Identifier
   * @param sTermText Exact term singular or plural text case sensitive
   * @return Term Unique Id. or <b>null</b> if no term was found with such text.
   * @throws SQLException
   * @since 4.0
   */
  public static String getIdFromText(JDCConnection oConn, int iDomainId, String sTermText)
    throws SQLException {
    return DBPersist.getUIdFromName(oConn, new Integer(iDomainId), sTermText, "k_get_term_from_text");
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 9;

  public static final int SCOPE_ONE = 1;
  public static final int SCOPE_ALL = 2;

}