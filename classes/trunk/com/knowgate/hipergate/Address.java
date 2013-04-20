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

import java.util.HashMap;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.PreparedStatement;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Gadgets;

/**
 * <p>Address</p>
 * A generic postal address object for being associated to any other objects
 * that may require address information.
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class Address extends DBPersist {

  /**
   * Create empty Address
   */
  public Address() {
    super(DB.k_addresses, "Address");
  }

  /**
   * Load Address from database
   * @param oConn Database Connection
   * @param guAddr GUID of address to be loaded
   */

  public Address(JDCConnection oConn, String guAddr) throws SQLException {
    super(DB.k_addresses, "Address");

    Object aAddr[] = { guAddr };

    load(oConn, aAddr);
  }

  // ---------------------------------------------------------

  /**
   * <p>Load values set at table k_addresses</p>
   * This method trims the value of id_country column and loads the translated value for street type
   * @param oConn Database Connection
   * @param PKVals An Array with a single String containing the GUID of the Address to be loaded
   * @return <b>true</b> if Address was found, <b>false</b> otherwise.
   * @throws SQLException
   * @since 3.0
   */

  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    String sIdCountry = null;
    boolean bRetVal = super.load(oConn, PKVals);
    if (bRetVal) {
      if (!isNull(DB.id_country)) {
        sIdCountry = getString(DB.id_country).trim();
        AllVals.remove(DB.id_country);
        AllVals.put(DB.id_country, sIdCountry);

        String sTpStreetTr = null;
        try {
      	  if (!isNull(DB.tp_street)) {
            sTpStreetTr = DBCommand.queryStr(oConn, "SELECT "+DB.tr_+sIdCountry+" FROM "+DB.k_addresses_lookup+" WHERE "+DB.gu_owner+"='"+getString(DB.gu_workarea)+"' AND "+DB.id_section+"='tp_street' AND "+DB.vl_lookup+"='"+getString(DB.tp_street)+"'");
      	  }
        } catch (Exception ignore) { }
        if (sTpStreetTr!=null) put(DB.tp_street+"_"+sIdCountry.toLowerCase(), sTpStreetTr);
      } // id_country
    }
    return bRetVal;
  } // load

  // ---------------------------------------------------------

  /**
   * <p>Load values set at table k_addresses</p>
   * This method trims the value of id_country column
   * @param oConn JDCConnection
   * @param sGuAddress String GUID of the Address to be loaded
   * @return <b>true</b> if Address was found, <b>false</b> otherwise.
   * @throws SQLException
   * @since 3.0
   */
  public boolean load(JDCConnection oConn, String sGuAddress) throws SQLException {
    return this.load(oConn, new Object[]{sGuAddress});
  }

  // ---------------------------------------------------------

  /**
   * <p>Delete Address</p>
   * Registers at k_welcome_packs, k_x_company_addr, k_x_contact_addr, k_meetings, k_sms_audit, k_activities, k_x_activity_audience are deleted on cascade
   * @param oConn Database Connection
   * @return <b>true<b> if Address existed at k_addresses table.
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    Statement oDlte = oConn.createStatement();
    int iAffected;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Address.delete(" + getStringNull(DB.gu_address, "null") + ")");
      DebugFile.incIdent();
    }

	// ************
    // New for v6.0

	  if (isNull(DB.gu_workarea)) put(DB.gu_workarea, DBCommand.queryStr(oConn, "SELECT "+DB.gu_workarea+" FROM "+DB.k_addresses+" WHERE "+DB.gu_address+"='"+ getString(DB.gu_address)+"'"));
      oDlte.executeUpdate("DELETE FROM "+DB.k_meetings_lookup+" WHERE "+DB.id_section+"='"+DB.gu_address+"' AND "+DB.gu_owner+"='"+getString(DB.gu_workarea)+"' AND "+DB.vl_lookup+"='"+getString(DB.gu_address)+"'");

	// ************
    // New for v5.0

    if (DBBind.exists(oConn, DB.k_activities, "U")) {
      oDlte.executeUpdate("UPDATE "+DB.k_activities+" SET "+DB.gu_address+"=NULL WHERE "+DB.gu_address+"='"+getString(DB.gu_address)+"'");
    }

    if (DBBind.exists(oConn, DB.k_x_activity_audience, "U")) {
      oDlte.executeUpdate("UPDATE "+DB.k_x_activity_audience+" SET "+DB.gu_address+"=NULL WHERE "+DB.gu_address+"='"+getString(DB.gu_address)+"'");
    }

    if (DBBind.exists(oConn, DB.k_sms_audit, "U")) {
      oDlte.executeUpdate("UPDATE "+DB.k_sms_audit+" SET "+DB.gu_address+"=NULL WHERE "+DB.gu_address+"='"+getString(DB.gu_address)+"'");
    }

	// ************

	// ************
    // New for v4.0

    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_meetings + " SET " + DB.gu_address + "=NULL WHERE " + DB.gu_address + "='" + getStringNull(DB.gu_address,"null") + "')");
    oDlte.executeUpdate("UPDATE " + DB.k_meetings + " SET " + DB.gu_address + "=NULL WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "'");

	// ************
	
    if (DBBind.exists(oConn, DB.k_welcome_packs, "U")) {
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_welcome_packs_changelog + " WHERE " + DB.gu_pack + " IN (SELECT " + DB.gu_pack +  " FROM " + DB.k_welcome_packs + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "'))");

      oDlte.executeUpdate("DELETE FROM " + DB.k_welcome_packs_changelog + " WHERE " + DB.gu_pack + " IN (SELECT " + DB.gu_pack +  " FROM " + DB.k_welcome_packs + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "')");

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_welcome_packs + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "')");

      oDlte.executeUpdate("DELETE FROM " + DB.k_welcome_packs + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "'");
    }

    if (DBBind.exists(oConn, DB.k_x_company_addr, "U")) {
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_company_addr + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "')");

      oDlte.executeUpdate("DELETE FROM " + DB.k_x_company_addr + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "'");
    }

    if (DBBind.exists(oConn, DB.k_x_contact_addr, "U")) {
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_contact_addr + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "')");

      oDlte.executeUpdate("DELETE FROM " + DB.k_x_contact_addr + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "'");
    }

    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_addresses + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "')");

    iAffected = oDlte.executeUpdate("DELETE FROM " + DB.k_addresses + " WHERE " + DB.gu_address + "='" + getString(DB.gu_address) + "'");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Address.delete() : " + String.valueOf((iAffected>0 ? true : false)));
    }

    return (iAffected>0 ? true : false);
  } // delete

  // ---------------------------------------------------------

  /**
   * <p>Store Address</p>
   * If gu_address is null a new GUID is automatically assigned.<br>
   * dt_modified field is set to current date.<br>
   * For generating a new address index call nextLocalIndex() and set property ix_address.<br>
   * For example:<br>
   * this.put (DB.ix_address, Address.nextLocalIndex(Connection, "k_x_company_addr", "gu_company"))
   * @param oConn Database Connection
   * @return boolean <b>true</b> if Address was stored for the first time,
   * <b>false</b> if register already existed.
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (isNull(DB.gu_address)) put(DB.gu_address, Gadgets.generateUUID());
	if (isNull(DB.bo_active)) put(DB.bo_active, (short)1);

    replace(DB.dt_modified, dtNow);

    return super.store (oConn);
  } // store()

  // ---------------------------------------------------------

  /**
   * <p>Get Address as a single plain text line using the given locale</p>
   * @param sCountryId 2 letters identifier for country locale.
   * Currently format are supported for us, gb, uk, es, fr, and it
   * @return String
   * @since 4.0
   */

  public String toLocaleString(String sCountryId) {
	StringBuffer oAddrLine = new StringBuffer(255);
	if (null==sCountryId) sCountryId = "";
	sCountryId = sCountryId.trim().toLowerCase();
	if (sCountryId.equals("es") || sCountryId.equals("it")) {
	  if (!isNull(DB.tp_street+"_"+sCountryId)) 
	    oAddrLine.append(getString(DB.tp_street+"_"+sCountryId)+" ");
	  if (!isNull(DB.nm_street)) 
	    oAddrLine.append(getString(DB.nm_street)+" ");
	  if (!isNull(DB.nu_street)) 
	    oAddrLine.append(getString(DB.nu_street));
	} else if (sCountryId.equals("en") || sCountryId.equals("us") || sCountryId.equals("gb")  || sCountryId.equals("uk")) {
	  if (!isNull(DB.nu_street)) 
	    oAddrLine.append(getString(DB.nu_street)+" ");
	  if (!isNull(DB.nm_street)) 
	    oAddrLine.append(getString(DB.nm_street)+" ");
	  if (!isNull(DB.tp_street+"_"+sCountryId)) 
	    oAddrLine.append(getString(DB.tp_street+"_"+sCountryId));
	} else if (sCountryId.equals("fr")) {
	  if (!isNull(DB.nu_street)) 
	    oAddrLine.append(getString(DB.nu_street)+" ");
	  if (!isNull(DB.tp_street+"_"+sCountryId)) 
	    oAddrLine.append(getString(DB.tp_street+"_"+sCountryId)+" ");
	  if (!isNull(DB.nm_street)) 
	    oAddrLine.append(getString(DB.nm_street));
	} else {
	  if (!isNull(DB.nm_street)) 
	    oAddrLine.append(getString(DB.nm_street)+" ");
	  if (!isNull(DB.nu_street)) 
	    oAddrLine.append(getString(DB.nu_street));
	}// id_country

	if (!isNull(DB.zipcode))
	  oAddrLine.append(","+getString(DB.zipcode));

	if (!isNull(DB.mn_city))
	  oAddrLine.append(","+getString(DB.mn_city));

	if (!isNull(DB.nm_state)) 
	  oAddrLine.append(","+getString(DB.nm_state));

	if (!isNull(DB.nm_country)) 
	  oAddrLine.append(","+getString(DB.nm_country));

	return oAddrLine.toString();
  } // toLocaleString

  // ---------------------------------------------------------

  /**
   * <p>Get Address as a single plain text line using country as locale</p>
   * @return String
   * @since 4.0
   */

  public String toLocaleString() {
    return toLocaleString(getStringNull(DB.id_country,""));
  } // toLocaleString

  // ---------------------------------------------------------

  /**
   * <p>Get an XML dump for the DBPersist values</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @param sDelim Line delimiter (usually "\n" or "\r\n")
   * @return XML String
   @ @throws IllegalStateException If XML method is invoked before DBPersist object is loaded
   */

  public String toXML(String sIdent, String sDelim)
    throws IllegalStateException {
    HashMap oAttrs = new HashMap(7);
    oAttrs.put(DB.tp_location, getStringNull(DB.tp_location,""));
    if (!isNull(DB.ix_address))
      oAttrs.put(DB.ix_address, new Integer(getInt(DB.ix_address)));
    return toXML(sIdent, sDelim, oAttrs);
  }

  /**
   * <p>Get an XML dump for the DBPersist values.</p>
   * <p>Lines are delimited by a single Line Feed CHR(10) '\n' character.</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @return XML String
   */

  public String toXML(String sIdent) {
    return toXML(sIdent, "\n", null);
  }

  /**
   * <p>Get an XML dump for the DBPersist values.</p>
   * <p>No left padding is placed to the left of each line.</p>
   * <p>Lines are delimited by a single Line Feed CHR(10) '\n' character.</p>
   * @return XML String
   */

  public String toXML() {
    return toXML("", "\n", null);
  }

  // **********************************************************
  // Static Methods

  /**
   * <p>Get next free address index for a given object.</p>
   * Address indexes are integers assigned on a per object basis.<br>
   * @param oConn Database Connection
   * @param sLinkTable Table used for linking addresses to instances of objects
   * of a given class (for example "k_x_company_addr" or "k_x_contact_addr").
   * @param sLinkField Foreign object column name at link table (for example "gu_company" or "gu_contact")
   * @param sLinkValue Value for foreign object GUID
   * @return SELECT COUNT(*)+1 FROM sLinkTable WHERE sLinkField = sLinkValue
   * @throws SQLException
   */
  public static int nextLocalIndex(Connection oConn, String sLinkTable, String sLinkField, String sLinkValue) throws SQLException {
    // Obtiene el siguiente valor del índice correlativo de direcciones
    // asociadas a una determinada instancia de otro objeto.
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Address.nextLocalIndex([Connection],"+sLinkTable+","+sLinkField+","+sLinkValue+")");
      DebugFile.incIdent();
    }
    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    ResultSet oRSet = oStmt.executeQuery("SELECT COUNT(*) FROM " + sLinkTable + " WHERE " + sLinkField + "='" + sLinkValue + "'");
    oRSet.next();
    Object oCount = oRSet.getObject(1);
    oRSet.close();
    oStmt.close();
    int iRetVal = Integer.parseInt(oCount.toString())+1;
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Address.nextLocalIndex() : "+String.valueOf(iRetVal));
    }
    return iRetVal;
  } // nextLocalIndex

  /**
   * <p>Get Address Unique Id. from its e-mail.</p>
   * @param oConn Database Connection
   * @param sEMail Address e-mail (tx_email from k_addresses table)
   * @param sWorkArea WorkArea filter. If <b>null</b> all WorkAreas are seached
   * @return User Unique Id. or <b>null</b> if no Address was found with such e-mail.
   * @throws SQLException
   * @since 2.2
   */
  public static String getIdFromEmail(JDCConnection oConn, String sEMail, String sWorkArea) throws SQLException {
    String sRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      if (null==sWorkArea)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_address + " FROM " + DB.k_addresses + " WHERE " + DB.tx_email + "='" + sEMail + "')");
      else
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_address + " FROM " + DB.k_addresses + " WHERE " + DB.tx_email + "='" + sEMail + "' AND " + DB.gu_workarea+ "='" + sWorkArea + "')");
    }

    if (null==sWorkArea) {
      oStmt = oConn.prepareStatement("SELECT " + DB.gu_address + " FROM " + DB.k_addresses + " WHERE " + DB.tx_email + "=?", ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sEMail);
    } else {
      oStmt = oConn.prepareStatement("SELECT " + DB.gu_address + " FROM " + DB.k_addresses + " WHERE " + DB.tx_email + "=? AND " + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sEMail);
      oStmt.setString(2, sWorkArea);
    }

    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();

    return sRetVal;
  } // getIdFromEmail

  /**
    * <p>Add a State for a given country at k_addresses_lookup table</p>
    * This methods checks whether the given State Name exists at k_addresses_lookup
    * for a given country and, if not, then inserts it.<br>
    * Example of how to call this method:<br>
    * Connection oConn = <i>// Code to get connection</i> ;<br>
    * HashMap oTr = new HashMap();<br>
    * oTr.put("en", "New York");<br>
    * oTr.put("fr", "Nouveau York");<br>
    * oTr.put("es", "Nueva York");<br>
    * Address.addState(oConn, "0123456789ABCDEFGHIJKLMNOPQRST", "us", "NY", oTr);
    * @param oConn Connection
    * @param sGuWorkArea String GUID of WorkArea
    * @param sIdCountry String Two letters country identifier from k_lu_countries table
    * @param sNmState String Language Neutral State Name or Code
    * @param oTranslations HashMap with one entry for each language
    * Language codes must be those from id_language column of k_lu_languages table.
    * @return boolean <b>true</b> if state was added, <b>false</b> if it already existed
    * @throws SQLException
    * @since 3.0
    */
   public static boolean addLookupState (Connection oConn, String sGuWorkArea, String sIdCountry, String sNmState, HashMap<String,String> oTranslations)
    throws SQLException {
      return DBLanguages.addLookup(oConn,DB.k_addresses_lookup, sGuWorkArea, sIdCountry, sNmState, oTranslations);
    }

    /**
     * <p>Add a Street Type lookup value</a>
     * @param oConn Connection
     * @param sGuWorkArea String GUID of WorkArea
     * @param sTpStreet String Street Type Internal Value
     * @param oTranslations HashMap with one entry for each language
     * @return boolean <b>true</b> if new street type was added, <b>false</b> if it already existed
     * @throws SQLException
     * @since 3.0
     */
    public static boolean addLookupStreetType (Connection oConn, String sGuWorkArea, String sTpStreet, HashMap<String,String> oTranslations)
     throws SQLException {
     return DBLanguages.addLookup(oConn,DB.k_addresses_lookup, sGuWorkArea, DB.tp_street, sTpStreet, oTranslations);
   }

  /**
   * <p>Get addresses given their company name</p>
   * This method difers from Company.getAddresses()
   * in that getAddresses() takes the Company GUID
   * and makes a query into k_x_company_addr table.
   * getAddressesForCompany() instead tests the
   * value of nm_company column at k_addresses table.
   * @param oConn Connection
   * @param sCompanyNm String Exact Company Name (case sensitive)
   * @param sWorkArea String GUID of WorkArea where to search
   * @return String Address GUID or <b>null</b> if no company with such legal number was found at given work area
   * @throws SQLException
   * @since 4.0
   */
  public static DBSubset getAddressesByCompanyName(JDCConnection oConn, String sCompanyNm, String sWorkArea)
    throws SQLException {
    String sRetVal;
    DBSubset oDbs = new DBSubset(DB.k_addresses,new Address().getTable(oConn).getColumnsStr(),
    							 DB.nm_company+"=? AND "+DB.gu_workarea+"=?",
                                 10);
	oDbs.load(oConn, new Object[]{sCompanyNm,sWorkArea});
	
	return oDbs;
  } // getAddressesByCompanyName

  // **********************************************************
  // Public Constants

  public static final short ClassId = 7;
}
