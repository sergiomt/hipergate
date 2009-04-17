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
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

/**
 * @author Sergio Montoro Ten
 * @version 1.1
 */

public class Thesauri {

  public Thesauri() {
  }

  /**
   * <p>Create Root Term</p>
   * @param oConn Database Connection
   * @param sTxTerm Term Text Singular
   * @param sTxTerm Term Text Plural
   * @param sDeTerm Term Contextual Description
   * @param sIdLanguage Language
   * @param sIdScope Scope
   * @param iIdDomain Domain Numeric Identifier (from k_domains)
   * @param sGuWorkArea WorkArea GUID
   * @return GUID for new term
   * @throws SQLException
   */
  public static String createRootTerm(JDCConnection oConn, String sTxTerm, String sTxTermPlural, String sDeTerm, String sIdLanguage, String sIdScope, int iIdDomain, String sGuWorkArea) throws SQLException {
    PreparedStatement oStmt;
    String sGuRootTerm = Gadgets.generateUUID();
    int iNextVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Thesauri.createRootTerm([Connection]," + sTxTerm + "," + sTxTermPlural + "," + sDeTerm + "," + sIdLanguage + "," + sIdScope + String.valueOf(iIdDomain) + "," + sGuWorkArea + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(INSERT INTO " + DB.k_thesauri_root + " (" + DB.gu_rootterm + "," + DB.tx_term + "," + DB.tx_term + "2," + DB.id_domain + "," + DB.gu_workarea + "," + DB.id_scope + ") VALUES ('" + sGuRootTerm + "','" + sTxTerm + "'," + String.valueOf(iIdDomain) + ",'" + sGuWorkArea + "','" + sIdScope + "'))");
    }

    oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_thesauri_root + " (" + DB.gu_rootterm + "," + DB.tx_term + "," + DB.id_domain + "," + DB.gu_workarea + "," + DB.id_scope + ") VALUES (?,?,?,?,?)");
    oStmt.setString(1, sGuRootTerm);
    oStmt.setString(2, sTxTerm);
    oStmt.setInt(3, iIdDomain);
    oStmt.setString(4, sGuWorkArea);
    oStmt.setString(5, sIdScope);
    oStmt.executeUpdate();
    oStmt.close();

    iNextVal = DBBind.nextVal(oConn, "seq_thesauri");

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(INSERT INTO " + DB.k_thesauri + " (" + DB.gu_rootterm + "," + DB.gu_term + "," + DB.tx_term + "," + DB.tx_term + "2," + DB.id_language + "," + DB.de_term + "," + DB.id_scope + "," + DB.id_domain + "," + DB.id_term + "0) VALUES ('" + sGuRootTerm + "','" + sGuRootTerm + "','" + sTxTerm + "','" + sIdLanguage + "','" + sDeTerm + "','" + sIdScope + "'," + String.valueOf(iIdDomain) + "," + String.valueOf(iNextVal) + "))");

    oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_thesauri + " (" + DB.gu_rootterm + "," + DB.gu_term + "," + DB.tx_term + "," + DB.tx_term + "2," + DB.id_language + "," + DB.de_term + "," + DB.id_scope + "," + DB.id_domain + "," + DB.id_term + "0) VALUES (?,?,?,?,?,?,?,?,?)");
    oStmt.setString(1, sGuRootTerm);
    oStmt.setString(2, sGuRootTerm);
    oStmt.setString(3, sTxTerm);
    oStmt.setString(4, sTxTermPlural);
    oStmt.setString(5, sIdLanguage);
    if (sDeTerm==null)
      oStmt.setNull(6, Types.VARCHAR);
    else
      oStmt.setString(6, sDeTerm);
    oStmt.setString(7, sIdScope);
    oStmt.setInt(8, iIdDomain);
    oStmt.setInt(9, iNextVal);
    oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Thesauri.createRootTerm() : " + sGuRootTerm);
    }

    return sGuRootTerm;
  } // createRootTerm


  /**
   * <p>Create Term</p>
   * @param oConn Database Connection
   * @param sGuParent Parent Term
   * @param sTxTerm Term Text Singular
   * @param sTxTermPlural Term Text Plural
   * @param sDeTerm Term Contextual Description
   * @param sIdLanguage Language
   * @param sIdScope Scope
   * @param iIdDomain Domain Numeric Identifier (from k_domains)
   * @return GUID for new term
   * @throws SQLException
   */
  public static String createTerm(JDCConnection oConn, String sGuParent, String sTxTerm, String sTxTermPlural, String sDeTerm, String sIdLanguage, String sIdScope, int iIdDomain) throws SQLException {
    ResultSet oRSet;
    PreparedStatement oStmt;
    String sGuTerm = Gadgets.generateUUID();
    String sGuRootTerm;
    Object [] oTerm = new Object[10];
    int iTerm;
    int iNext;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Thesauri.createTerm([Connection]," + sGuParent + "," + sTxTerm + "," + sTxTermPlural + "," + sDeTerm + "," + sIdLanguage + "," + sIdScope + String.valueOf(iIdDomain) + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_rootterm + "," + DB.id_term + "0," + DB.id_term + "1," + DB.id_term + "2," + DB.id_term + "3," + DB.id_term + "4," + DB.id_term + "5," + DB.id_term + "6," + DB.id_term + "7," + DB.id_term + "8," + DB.id_term + "9 FROM " + DB.k_thesauri + " WHERE " + DB.gu_term + "='" + sGuParent + "'");
    }

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_rootterm + "," + DB.id_term + "0," + DB.id_term + "1," + DB.id_term + "2," + DB.id_term + "3," + DB.id_term + "4," + DB.id_term + "5," + DB.id_term + "6," + DB.id_term + "7," + DB.id_term + "8," + DB.id_term + "9 FROM " + DB.k_thesauri + " WHERE " + DB.gu_term + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sGuParent);
    oRSet = oStmt.executeQuery();
    boolean bParentExists = oRSet.next();
    if (bParentExists) {
      sGuRootTerm = oRSet.getString(1);
      oTerm[0] = oRSet.getObject(2);
      oTerm[1] = oRSet.getObject(3);
      oTerm[2] = oRSet.getObject(4);
      oTerm[3] = oRSet.getObject(5);
      oTerm[4] = oRSet.getObject(6);
      oTerm[5] = oRSet.getObject(7);
      oTerm[6] = oRSet.getObject(8);
      oTerm[7] = oRSet.getObject(9);
      oTerm[8] = oRSet.getObject(10);
      oTerm[9] = oRSet.getObject(11);
    } else {
      sGuRootTerm = null;
    }
    oRSet.close();
    oStmt.close();

	if (!bParentExists) {
	  if (DebugFile.trace) { DebugFile.writeln("Parent term \""+sGuParent+"\" not found"); DebugFile.decIdent(); }
	  throw new SQLException ("Thesauri.createTerm() Parent term \""+sGuParent+"\" not found");
	}
	
    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(INSERT INTO " + DB.k_thesauri + " (" + DB.gu_rootterm + "," + DB.gu_term + "," + DB.tx_term + "," + DB.tx_term + "2," + DB.id_language + "," + DB.de_term + "," + DB.id_scope + "," + DB.id_domain + "," + DB.id_term + "0," + DB.id_term + "1," + DB.id_term + "2," + DB.id_term + "3," + DB.id_term + "4," + DB.id_term + "5," + DB.id_term + "6," + DB.id_term + "7," + DB.id_term + "8," + DB.id_term + "9) VALUES ('" + sGuRootTerm + "','" + sGuTerm + "','" + sTxTerm + "','" + sTxTermPlural + "','" + sIdLanguage + "','" + sDeTerm + "','" + sIdScope + "'," + String.valueOf(iIdDomain) + ",?,?,?,?,?,?,?,?,?,?))");

    oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_thesauri + " (" + DB.gu_rootterm + "," + DB.gu_term + "," + DB.tx_term + "," + DB.tx_term + "2," + DB.id_language + "," + DB.de_term + "," + DB.id_scope + "," + DB.id_domain + "," + DB.id_term + "0," + DB.id_term + "1," + DB.id_term + "2," + DB.id_term + "3," + DB.id_term + "4," + DB.id_term + "5," + DB.id_term + "6," + DB.id_term + "7," + DB.id_term + "8," + DB.id_term + "9) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    oStmt.setString(1, sGuRootTerm);
    oStmt.setString(2, sGuTerm);
    oStmt.setString(3, sTxTerm);
    oStmt.setString(4, sTxTermPlural);
    oStmt.setString(5, sIdLanguage);
    if (sDeTerm==null)
      oStmt.setNull(6, Types.VARCHAR);
    else
      oStmt.setString(6, sDeTerm);
    oStmt.setString(7, sIdScope);
    oStmt.setInt(8, iIdDomain);

    iTerm = 0;
    do  {
      if (null==oTerm[iTerm]) break;

      if (DebugFile.trace)
        DebugFile.writeln("PreparedStatement.setObject(" + String.valueOf(iTerm+9) + ", " + oTerm[iTerm] + ", java.sql.Types.INTEGER)");

      oStmt.setObject(iTerm+9, oTerm[iTerm], java.sql.Types.INTEGER);
    } while (++iTerm<=9);

    if (10==iTerm)
      throw new SQLException ("Thesauri maximum number of hierarchical levels exceeded");

    iNext = DBBind.nextVal(oConn, "seq_thesauri");

    if (DebugFile.trace)
      DebugFile.writeln("PreparedStatement.setInt (" + String.valueOf(iTerm+9) + "," + String.valueOf(iNext) + ")");

    oStmt.setInt (iTerm+9, iNext);

    while (++iTerm<=9) {
      if (DebugFile.trace)
        DebugFile.writeln("PreparedStatement.setObject(" + String.valueOf(iTerm+9) + ", null, java.sql.Types.INTEGER)");

      oStmt.setObject(iTerm+9, null, java.sql.Types.INTEGER);

    } // wend

    if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate();");

    oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Thesauri.createTerm() : " + sGuTerm);
    }

    return sGuTerm;
  } // createTerm

  /**
   * Delete a Term and all its childs
   * @param sGuTerm Term GUID
   * @throws SQLException
   */
  public static void delete(JDCConnection oConn, String sGuTerm)
    throws SQLException {

    PreparedStatement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Thesauri.delete([Connection]," + sGuTerm);
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_thesauri + " WHERE " + DB.gu_term + "=? OR " + DB.id_term + "0=? OR " + DB.id_term + "1=? OR " + DB.id_term + "2=? OR " + DB.id_term + "3=? OR " + DB.id_term + "4=? OR " + DB.id_term + "5=? OR " + DB.id_term + "6=? OR " + DB.id_term + "7=? OR " + DB.id_term + "8=? OR " + DB.id_term + "9=?)");
    }

    oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_thesauri + " WHERE " + DB.gu_term + "=? OR " + DB.id_term + "0=? OR " + DB.id_term + "1=? OR " + DB.id_term + "2=? OR " + DB.id_term + "3=? OR " + DB.id_term + "4=? OR " + DB.id_term + "5=? OR " + DB.id_term + "6=? OR " + DB.id_term + "7=? OR " + DB.id_term + "8=? OR " + DB.id_term + "9=?");

    oStmt.setString(1, sGuTerm);
    oStmt.setString(2, sGuTerm);
    oStmt.setString(3, sGuTerm);
    oStmt.setString(4, sGuTerm);
    oStmt.setString(5, sGuTerm);
    oStmt.setString(6, sGuTerm);
    oStmt.setString(7, sGuTerm);
    oStmt.setString(8, sGuTerm);
    oStmt.setString(9, sGuTerm);
    oStmt.setString(10, sGuTerm);
    oStmt.setString(11, sGuTerm);

    oStmt.executeUpdate();

    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Thesauri.delete()");
    }
  } // delete

  public static String createSynonym (JDCConnection oConn, String sGuMainTerm, String sTxTerm, String sTxTermPlural, String sDeTerm)
      throws SQLException {
    Term oMain = new Term();

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Thesauri.createSynonym([Connection]," + sGuMainTerm + "," + sTxTerm + "," + sTxTermPlural + "," + sDeTerm);
      DebugFile.incIdent();
    }

    oMain.load(oConn, new Object[]{sGuMainTerm});

    int iLevel = oMain.level();

    oMain.replace(DB.gu_term, Gadgets.generateUUID());
    oMain.replace(DB.gu_synonym, sGuMainTerm);
    oMain.replace(DB.id_term + String.valueOf(iLevel-1), DBBind.nextVal(oConn, "seq_thesauri"));
    oMain.replace(DB.tx_term, sTxTerm);
    oMain.replace(DB.tx_term + "2", sTxTermPlural);
    oMain.replace(DB.de_term, sDeTerm);

    oMain.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Thesauri.createSynonym() : " + oMain.getString(DB.gu_term));
    }

    return oMain.getString(DB.gu_term);
  }

  /**
   * Get Term GUID given its numeric identifier and level
   * @param oConn Database Connection
   * @param iDomainId Term Domain identifier
   * @param iTermId Term numeric identifier
   * @param iLevel Term level [0..9]
   * @return Term GUID or <b>null</b> if no term with such numeric identifier and level was found
   * @throws SQLException
   */
  public static String getTerm (JDCConnection oConn, int iDomainId, int iTermId, int iLevel)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Thesauri.getTerm (Connection], " + String.valueOf(iTermId) + "," + String.valueOf(iLevel));
      DebugFile.incIdent();
    }

    String sTermGUID;
    PreparedStatement oStmt;

    if (iLevel<9) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " WHERE " + DB.id_domain + "=" + String.valueOf(iDomainId) + " AND " + DB.id_term + String.valueOf(iLevel) + "=" + String.valueOf(iTermId) + " AND " + DB.id_term + String.valueOf(iLevel+1) + " IS NULL)");

      oStmt = oConn.prepareStatement("SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " WHERE " + DB.id_domain + "=? AND " + DB.id_term + String.valueOf(iLevel) + "=? AND " + DB.id_term + String.valueOf(iLevel+1) + " IS NULL", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    }
    else {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " WHERE " + DB.id_domain + "=" + String.valueOf(iDomainId) + " AND " + DB.id_term + String.valueOf(iLevel) + "=" + String.valueOf(iTermId) + ")");

      oStmt = oConn.prepareStatement("SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " WHERE " + DB.id_domain + "=? AND " + DB.id_term + String.valueOf(iLevel) + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    }

    oStmt.setInt(1, iDomainId);
    oStmt.setInt(2, iTermId);

    ResultSet oRSet = oStmt.executeQuery();

    if (oRSet.next())
      sTermGUID = oRSet.getString(1);
    else
      sTermGUID = null;

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Thesauri.getTerm() : " + sTermGUID);
    }

    return sTermGUID;
  }
}