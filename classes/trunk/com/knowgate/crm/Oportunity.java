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

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.util.HashMap;
import java.util.LinkedList;

import org.apache.oro.text.regex.MalformedPatternException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBCommand;

/**
 * <p>Sales Oportunity</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class Oportunity extends DBPersist {

  public Oportunity() {
    super(DB.k_oportunities, "Oportunity");
  }

  // ----------------------------------------------------------

  /**
   * <p>Get main contact for this opportunity</p>
   * @param oConn Database Connection
   * @return Contact
   * @throws SQLException
   * @throws IllegalStateException
   * @since 7.0
   */
  public Contact getMainContact(JDCConnection oConn) throws SQLException,IllegalStateException {
    if (isNull(DB.gu_oportunity)) throw new IllegalStateException("Oportunity must be loaded before calling getMainContact() method");
    if (isNull(DB.gu_contact))
      return null;
    else
      return new Contact(oConn, getString(DB.gu_contact));
  }

  // ----------------------------------------------------------

  /**
   * <p>Get secondary contacts for this opportunity</p>
   * @param oConn Database Connection
   * @return Contact
   * @throws SQLException
   * @throws IllegalStateException
   * @since 7.0
   */
  public LinkedList<Contact> getSecondaryContacts(JDCConnection oConn) throws SQLException,IllegalStateException {
    if (isNull(DB.gu_oportunity)) throw new IllegalStateException("Oportunity must be loaded before calling getSecondaryContacts() method");
    Contact oCont = new Contact();
    LinkedList<Contact> oSecConts = new LinkedList<Contact>();
    DBSubset oDbss;
	try {
		oDbss = new DBSubset(DB.k_x_oportunity_contacts+" x INNER JOIN "+DB.k_contacts+" c ON x."+DB.gu_contact+"=c."+DB.gu_contact,
									  "c."+Gadgets.replace(oCont.getTable(oConn).getColumnsStr(),",",",c.")+",x."+DB.tp_relation,
									  "x."+DB.gu_oportunity+"=?",10);
		final int n = oDbss.load(oConn, new Object[]{getString(DB.gu_oportunity)});
		for (int c=0; c<n; c++) {
			oCont = new Contact();
			oCont.putAll(oDbss.getRowAsMap(c));
			oSecConts.add(oCont);
		} // next
	} catch (MalformedPatternException neverthrown) { }
    return oSecConts;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get count of secondary contacts for this opportunity</p>
   * @param oConn Database Connection
   * @return int Number of secondary contactas associated with this opportunity
   * @throws SQLException
   * @throws IllegalStateException
   * @since 7.0
   */  
  public int countSecondaryContacts(JDCConnection oConn) throws SQLException,IllegalStateException {
	int iCount = 0;
	if (isNull(DB.gu_oportunity)) throw new IllegalStateException("Oportunity must be loaded before calling getSecondaryContacts() method");
	PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_x_oportunity_contacts+" WHERE "+DB.gu_oportunity+"=?");
	oStmt.setString(1,getString(DB.gu_oportunity));
	ResultSet oRSet = oStmt.executeQuery();
	if (oRSet.next()) {
	  iCount = oRSet.getInt(1);
	  if (oRSet.wasNull()) iCount = 0;
	}
	oRSet.close();
	oStmt.close();
	return iCount;
  }
  
  // ----------------------------------------------------------

  /**
   * Add a secondary contact to this opportunity. If contact already existed then it is replaced.
   * @param oConn Database Connection
   * @param sGuCont GUID of Contact to be added
   * @param sRelationType String relationship type
   * @throws SQLException
   * @throws IllegalStateException
   * @throws NullPointerException If sGuCont is NULL
   * @since 7.0
   */
  public void addSecondaryContact(JDCConnection oConn, String sGuCont, String sRelationType) throws SQLException,IllegalStateException,NullPointerException {
    if (isNull(DB.gu_oportunity)) throw new IllegalStateException("Oportunity must be loaded before calling addSecondaryContact() method");
    if (sGuCont==null) throw new NullPointerException("Contact GUID may not be null");
    DBPersist oDbp = new DBPersist(DB.k_x_oportunity_contacts, "OportunityContact");
    oDbp.load(oConn, new Object[]{sGuCont, getString(DB.gu_oportunity)});
    oDbp.replace(DB.gu_contact, sGuCont);
    if (sRelationType==null)
      oDbp.remove(DB.tp_relation);
    else
      oDbp.replace(DB.tp_relation,sRelationType);
    oDbp.store(oConn);
  }

  // ----------------------------------------------------------
  
  /**
   * Remove a secondary contact from this opportunity.
   * @param oConn Database Connection
   * @param sGuCont GUID of Contact to be removed
   * @throws SQLException
   * @throws IllegalStateException
   * @throws NullPointerException If sGuCont is NULL
   * @since 7.0
   */
  public void removeSecondaryContact(JDCConnection oConn, String sGuCont) throws SQLException,IllegalStateException,NullPointerException {
    if (isNull(DB.gu_oportunity)) throw new IllegalStateException("Oportunity must be loaded before calling removeSecondaryContact() method");
	if (sGuCont==null) throw new NullPointerException("Contact GUID may not be null");
	PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_x_oportunity_contacts+" WHERE "+DB.gu_oportunity+"=? AND "+DB.gu_contact+"=?");
	oStmt.setString(1, getString(DB.gu_oportunity));
	oStmt.setString(2, sGuCont);
	oStmt.executeUpdate();
	oStmt.close();
  }
  
  // ----------------------------------------------------------

  /**
   * <p>Store Opportunity</p>
   * Fields gu_oportunity, dt_modified, tx_contact and tx_company are automatically filled if not given
   * @param oConn Database Connection
   * @return
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Oportunity.store([Connection])");
      DebugFile.incIdent();
    }

    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_oportunity))
      put(DB.gu_oportunity, Gadgets.generateUUID());

    if (!AllVals.containsKey(DB.nu_oportunities))
        put(DB.nu_oportunities, 1);

    replace(DB.dt_modified, dtNow);

    if (!AllVals.containsKey(DB.tx_contact)) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.tx_surname + "," + DB.tx_name + " FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "='" + getStringNull(DB.gu_contact, "null") + "')");

      oStmt = oConn.prepareStatement("SELECT " + DB.tx_surname + "," + DB.tx_name + " FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setObject (1, get(DB.gu_contact), java.sql.Types.CHAR);
      oRSet = oStmt.executeQuery();
      if (oRSet.next())
        put (DB.tx_contact, oRSet.getString(1) + ", " + oRSet.getString(2));
      oRSet.close();
      oStmt.close();
    }

    if (!AllVals.containsKey(DB.tx_company)) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "='" + getStringNull(DB.gu_company, "null") + "')");

      oStmt = oConn.prepareStatement("SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setObject (1, get(DB.gu_company), java.sql.Types.CHAR);
      oRSet = oStmt.executeQuery();
      if (oRSet.next())
        put (DB.tx_company, oRSet.getString(1));
      oRSet.close();
      oStmt.close();
    }

    bRetVal = super.store(oConn);

    if (!isNull(DB.gu_contact)) {
      int nCount = 0;
      oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_oportunities+" WHERE "+DB.gu_contact+"=?");
      oStmt.setString(1, getString(DB.gu_contact));
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {        
    	nCount = oRSet.getInt(1);
    	if (oRSet.wasNull()) nCount = 0;
      }
      oRSet.close();
      oStmt.close();
      oStmt = oConn.prepareStatement("UPDATE "+DB.k_oportunities+" SET "+DB.nu_oportunities+"=? WHERE "+DB.gu_contact+"=?");
      oStmt.setInt(1, nCount);
      oStmt.setString(2, getString(DB.gu_contact));
      oStmt.executeUpdate();
      oStmt.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Oportunity.store() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store

  /**
   * Map of opportunity attributes at k_oportunities_attrs table
   * @param oConn JDCConnection
   * @return HashMap<String,String> A map with attributes and their values
   * @throws SQLException
   * @since 7.0
   */
  public HashMap<String,String> attributes(JDCConnection oConn) throws SQLException {
	  HashMap<String,String> mAttrs = new HashMap<String,String>();
	  DBSubset oAttrs = new DBSubset(DB.k_oportunities_attrs,DB.nm_attr+","+DB.vl_attr,DB.gu_object+"=?",10);
	  int iAttrs = oAttrs.load(oConn, new Object[]{get(DB.gu_oportunity)});
	  for (int a=0; a<iAttrs; a++)
		  mAttrs.put(oAttrs.getString(0, a), oAttrs.getStringNull(1, a, null));
	  return mAttrs;
  }
  
  // ----------------------------------------------------------

  public boolean delete(JDCConnection oConn) throws SQLException {
    return Oportunity.delete(oConn, getString(DB.gu_oportunity));
  }

  // **********************************************************
  // Static Methods

  /**
   * Delete Oportunity
   * Call k_sp_del_oportunity stored procedure
   * @param oConn Database Connection
   * @param sOportunityGUID GUID of Oportunity to be deleted.
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sOportunityGUID) throws SQLException {
    CallableStatement oCall;
    Statement oStmt;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Oportunity.delete([Connection], " + sOportunityGUID + ")");
      DebugFile.incIdent();

    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.execute(SELECT k_sp_del_oportunity ('" + sOportunityGUID + "'))");

      bRetVal = oStmt.execute("SELECT k_sp_del_oportunity ('" + sOportunityGUID + "')");
      oStmt.close();
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_oportunity('" + sOportunityGUID + "')})");

      oCall = oConn.prepareCall("{ call k_sp_del_oportunity ('" + sOportunityGUID + "')}");
      bRetVal = oCall.execute();
      oCall.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Oportunity.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  }

  // **********************************************************
  // Constantes Publicas

  public static final short ClassId = 92;
}