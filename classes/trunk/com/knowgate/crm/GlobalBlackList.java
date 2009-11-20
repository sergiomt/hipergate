/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;

import com.knowgate.jdc.JDCConnection;

public class GlobalBlackList {

  public GlobalBlackList() { }

  /**
   * Array of e-mail addresses which must never receive any message
   * @param oConn JDCConnection
   * @param nDomain int Domain Unique Identifier (from k_domains table)
   * @throws SQLException
   */
  public static String[] forDomain(JDCConnection oConn, int nDomain) throws SQLException {
    ArrayList<String> oEmails = new ArrayList<String>();
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.tx_email+" FROM "+DB.k_global_black_list+" WHERE "+DB.id_domain+"=?",
    												 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	oStmt.setInt(1,nDomain);
	ResultSet oRSet = oStmt.executeQuery();
	while (oRSet.next()) {
	  oEmails.add(oRSet.getString(1));
	} // wend
	oRSet.close();
	oStmt.close();
	if (oEmails.size()==0) {
	  return null;
	} else {
	  return oEmails.toArray(new String[oEmails.size()]);
	}	
  } // forDomain

  /**
   * Array of e-mail addresses which must never receive any message
   * @param oConn JDCConnection
   * @param nDomain int Domain Unique Identifier (from k_domains table)
   * @throws SQLException
   */
  public static String[] forWorkArea(JDCConnection oConn, String sGuWorkArea)
  	throws SQLException {
    ArrayList<String> oEmails = new ArrayList<String>();

    int nDomain = DBCommand.queryInt(oConn, "SELECT "+DB.id_domain+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"='"+sGuWorkArea+"'");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.tx_email+" FROM "+DB.k_global_black_list+" WHERE "+DB.id_domain+"=? AND "+
    												 "("+DB.gu_workarea+"=? OR "+DB.gu_workarea+"='00000000000000000000000000000000')",
    												 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	oStmt.setInt(1,nDomain);
	oStmt.setString(2,sGuWorkArea);
	ResultSet oRSet = oStmt.executeQuery();
	while (oRSet.next()) {
	  oEmails.add(oRSet.getString(1));
	} // wend
	oRSet.close();
	oStmt.close();
	if (oEmails.size()==0) {
	  return null;
	} else {
	  return oEmails.toArray(new String[oEmails.size()]);
	}	
  } // forWorkArea

  /**
   * Add an e-mail addresses to the global black list of a Domain
   * @param oConn JDCConnection
   * @param nDomain int Domain Unique Identifier (from k_domains table)
   * @param sEMail String e-mail address to be added
   * @throws SQLException
   */
  public static void add(JDCConnection oConn, int nDomain, String sEMail) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.tx_email+" FROM "+DB.k_global_black_list+" WHERE "+DB.id_domain+"=? AND "+
    												 DB.tx_email+"=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	oStmt.setInt(1,nDomain);
	oStmt.setString(2,sEMail);
	ResultSet oRSet = oStmt.executeQuery();
	boolean bAlreadyExists = oRSet.next();
	oRSet.close();
	oStmt.close();
	if (!bAlreadyExists) {
	  oStmt = oConn.prepareStatement("INSERT INTO "+DB.k_global_black_list+" ("+DB.id_domain+","+DB.gu_workarea+","+DB.tx_email+") VALUES (?,?,?)");
	  oStmt.setInt(1,nDomain);
	  oStmt.setString(2,"00000000000000000000000000000000");
	  oStmt.setString(3,sEMail.toLowerCase());
	  oStmt.executeUpdate();
	  oStmt.close();
	} // fi
  } // add

  /**
   * Add an e-mail addresses to the global black list of a Work Area
   * @param oConn JDCConnection
   * @param nDomain int Domain Unique Identifier (from k_domains table)
   * @param sEMail String e-mail address to be added
   * @throws SQLException
   */
  public static void add(JDCConnection oConn, int nDomain, String sWrkA, String sEMail) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.tx_email+" FROM "+DB.k_global_black_list+" WHERE "+DB.id_domain+"=? AND "+
    												 DB.tx_email+"=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	oStmt.setInt(1,nDomain);
	oStmt.setString(2,sEMail);
	ResultSet oRSet = oStmt.executeQuery();
	boolean bAlreadyExists = oRSet.next();
	oRSet.close();
	oStmt.close();
	if (!bAlreadyExists) {
	  oStmt = oConn.prepareStatement("INSERT INTO "+DB.k_global_black_list+" ("+DB.id_domain+","+DB.gu_workarea+","+DB.tx_email+") VALUES (?,?,?)");
	  oStmt.setInt(1,nDomain);
	  oStmt.setString(2,sWrkA);
	  oStmt.setString(3,sEMail.toLowerCase());
	  oStmt.executeUpdate();
	  oStmt.close();
	} // fi
  } // add

  /**
   * Remove an e-mail addresses from the global black list of a Domain
   * @param oConn JDCConnection
   * @param nDomain int Domain Unique Identifier (from k_domains table)
   * @param sEMail String e-mail address to be removed
   * @throws SQLException
   */
  public static void remove(JDCConnection oConn, int nDomain, String sEMail) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_global_black_list+" WHERE "+
    												 DB.id_domain+"=? AND "+DB.tx_email+"=?");
	oStmt.setInt(1,nDomain);
	oStmt.setString(2,sEMail);
	oStmt.executeUpdate();
	oStmt.close();
  }	// remove

}
