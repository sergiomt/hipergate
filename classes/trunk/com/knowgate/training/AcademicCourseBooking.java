/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.
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

package com.knowgate.training;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.math.BigDecimal;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.crm.Company;
import com.knowgate.crm.Contact;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipergate.Invoice;
import com.knowgate.hipergate.Product;

/**
 * Booking for an academic course
 * @author Sergio Montoro Ten
 * @version 5.0
 */
public class AcademicCourseBooking extends DBPersist {

  public AcademicCourseBooking() {
    super(DB.k_x_course_bookings, "AcademicCourseBooking");
  }

  // ---------------------------------------------------------------------------

  public AcademicCourseBooking(String sAcademicCourseId, String sContactId) {
    super(DB.k_x_course_bookings, "AcademicCourseBooking");
    put (DB.gu_acourse, sAcademicCourseId);
    put (DB.gu_contact, sContactId);
  }

  // ---------------------------------------------------------------------------

  public AcademicCourseBooking(JDCConnection oConn,
                               String sAcademicCourseId, String sContactId)
    throws SQLException {
    super(DB.k_x_course_bookings, "AcademicCourseBooking");
    load(oConn, new Object[]{sAcademicCourseId, sContactId});
  }

  // ---------------------------------------------------------------------------

  public boolean confirmed() {
    boolean bRetVal;
    if (isNull(DB.bo_confirmed))
      bRetVal = false;
    else
      bRetVal = (getShort(DB.bo_confirmed)==(short) 1);
    return bRetVal;
  }

  // ---------------------------------------------------------------------------

  public boolean paid() {
    boolean bRetVal;
    if (isNull(DB.bo_paid))
      bRetVal = false;
    else
      bRetVal = (getShort(DB.bo_paid)==(short) 1);
    return bRetVal;
  }

  // ---------------------------------------------------------------------------

  public BigDecimal amount() {
    return getDecimal(DB.im_paid);
  }

  // ---------------------------------------------------------------------------

  public boolean waiting() {
    boolean bRetVal;
    if (isNull(DB.bo_waiting))
      bRetVal = false;
    else
      bRetVal = (getShort(DB.bo_waiting)==(short) 1);
    return bRetVal;
  }

  // ---------------------------------------------------------------------------

  public boolean canceled() {
    boolean bRetVal;
    if (isNull(DB.bo_canceled))
      bRetVal = false;
    else
      bRetVal = (getShort(DB.bo_canceled)==(short) 1);
    return bRetVal;
  }

  // ---------------------------------------------------------------------------

  public AcademicCourseAlumni createAlumni(JDCConnection oConn)
    throws SQLException {
    AcademicCourseAlumni oAlmn = new AcademicCourseAlumni();
    oAlmn.put(DB.gu_acourse, get(DB.gu_acourse));
    oAlmn.put(DB.gu_alumni, get(DB.gu_contact));
    if (!isNull(DB.tp_register))
      oAlmn.put(DB.tp_register, get(DB.tp_register));
    if (!isNull(DB.id_classroom))
      oAlmn.put(DB.id_classroom, get(DB.id_classroom));
    oAlmn.store(oConn);
    return oAlmn;
  } // createAlumni

  // ---------------------------------------------------------------------------

  public Invoice createInvoiceForCompany(JDCConnection oConn, String sGuShop)
    throws SQLException, IllegalStateException {

	if (!isNull(DB.gu_invoice))
      throw new IllegalStateException("Invoice was already created for academic course booking");

    if (isNull(DB.gu_contact))
      throw new IllegalStateException("AcademicCourseBooking.getContact() gu_contact not set");

	Contact oCntc = new Contact(oConn, getString(DB.gu_contact));

	if (oCntc.isNull(DB.gu_company))
	  throw new SQLException("Company not set for given Contact");
		
	Company oComp = new Company(oConn, getString(DB.gu_contact));
	if (oComp.isNull(DB.id_legal))
	  throw new SQLException("Legal document number not set for given Company");
	  
	Product oProd = new Product();

	if (!oProd.load(oConn, new Object[]{getString(DB.gu_acourse)})) {
	  throw new SQLException("No product found for given academic course");
	} else {
	  if (oProd.isNull(DB.id_currency)) {
	    throw new SQLException("Currency for product is not set");
	  }
	  if (oProd.isNull(DB.pr_list)) {
	    throw new SQLException("List price for product is not set");
	  }
	}

	DBSubset oAddrs = oComp.getAddresses(oConn);
	DBSubset oBanks = oComp.getActiveBankAccounts(oConn);
	
	Invoice oInvc = new Invoice();
	oInvc.put(DB.bo_active, (short) 1);
	oInvc.put(DB.gu_shop, sGuShop);
	oInvc.put(DB.id_currency, oProd.getStringNull(DB.id_currency,"978"));
	oInvc.put(DB.id_legal, oComp.getString(DB.id_legal));
	oInvc.put(DB.de_order, Gadgets.left(getStringNull(DB.nm_course,"")+"/"+oCntc.getStringNull(DB.tx_name,"")+" "+oCntc.getStringNull(DB.tx_surname,""),100));	
	oInvc.put(DB.gu_company, oComp.getString(DB.gu_company));
	oInvc.put(DB.nm_client, oComp.getString(DB.nm_legal));
	if (oAddrs.getRowCount()>0) {
	  oInvc.put(DB.gu_bill_addr, oAddrs.getString(DB.gu_address,0));
	  if (!oAddrs.isNull(DB.tx_email,0)) {
	    oInvc.put(DB.tx_email_to, oAddrs.getString(DB.tx_email,0));	  	
	  }
	} // fi
	if (oBanks.getRowCount()>0) {
	  oInvc.put(DB.nu_bank, oBanks.getString(DB.nu_bank_acc,0));
	} // fi
    oInvc.store(oConn);

	oInvc.addProduct(oConn, oProd.getString(DB.gu_product), 1f);

	oInvc.put(DB.im_subtotal, oInvc.computeSubtotal(oConn));
	oInvc.put(DB.im_taxes, oInvc.computeTaxes(oConn));
	oInvc.put(DB.im_total, oInvc.computeTotal(oConn));
	oInvc.put(DB.im_paid, new BigDecimal(0d));
    oInvc.store(oConn);	
    
    DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_x_course_bookings+" SET "+DB.gu_invoice+"='"+oInvc.getString(DB.gu_invoice)+"' WHERE "+DB.gu_acourse+"='"+getString(DB.gu_acourse)+"' AND "+DB.gu_contact+"='"+getString(DB.gu_contact)+"'");

    return oInvc;
  } // createInvoiceForCompany

  // ---------------------------------------------------------------------------

  public Invoice createInvoiceForContact(JDCConnection oConn, String sGuShop)
    throws SQLException, IllegalStateException {

	if (!isNull(DB.gu_invoice))
      throw new IllegalStateException("Invoice was already created for academic course booking");
		
    if (isNull(DB.gu_contact))
      throw new IllegalStateException("AcademicCourseBooking.getContact() gu_contact not set");
    
	Contact oCntc = new Contact(oConn, getString(DB.gu_contact));
	if (oCntc.isNull(DB.sn_passport))
	  throw new SQLException("Legal document number not set for Contact "+getString(DB.gu_contact)+" at bookig for academic course "+getString(DB.gu_acourse));
	  
	Product oProd = new Product();

	if (!oProd.load(oConn, new Object[]{getString(DB.gu_acourse)})) {
	  throw new SQLException("No product found for given academic course");
	} else {
	  if (oProd.isNull(DB.id_currency)) {
	    throw new SQLException("Currency for product is not set");
	  }
	  if (oProd.isNull(DB.pr_list)) {
	    throw new SQLException("List price for product is not set");
	  }
	}

	if (oProd.isNull(DB.id_currency))
	  throw new IllegalStateException("Could not generate invoice because currency for product is not set");

    if (oCntc.isNull(DB.sn_passport))
	  throw new IllegalStateException("Could not generate invoice because the identity document of contact is not set");
	
	DBSubset oAddrs = oCntc.getAddresses(oConn);
	DBSubset oBanks = oCntc.getActiveBankAccounts(oConn);
	
	Invoice oInvc = new Invoice();
	oInvc.put(DB.gu_shop, sGuShop);
	oInvc.put(DB.id_currency, oProd.getStringNull(DB.id_currency,"978"));
	oInvc.put(DB.id_legal, oCntc.getString(DB.sn_passport));
	oInvc.put(DB.de_order, Gadgets.left(getStringNull(DB.nm_acourse,"")+"/"+oCntc.getStringNull(DB.tx_name,"")+" "+oCntc.getStringNull(DB.tx_surname,""),100));	
	oInvc.put(DB.gu_contact, oCntc.getString(DB.gu_contact));
	oInvc.put(DB.nm_client, Gadgets.left(oCntc.getStringNull(DB.tx_name,"")+" "+oCntc.getStringNull(DB.tx_surname,""),200));
	if (oAddrs.getRowCount()>0) {
	  oInvc.put(DB.gu_bill_addr, oAddrs.getString(DB.gu_address,0));
	  if (!oAddrs.isNull(DB.tx_email,0)) {
	    oInvc.put(DB.tx_email_to, oAddrs.getString(DB.tx_email,0));	  	
	  }
	} // fi
	if (oBanks.getRowCount()>0) {
	  oInvc.put(DB.nu_bank, oBanks.getString(DB.nu_bank_acc,0));
	} // fi
    oInvc.store(oConn);

	oInvc.addProduct(oConn, oProd.getString(DB.gu_product), 1f);

	oInvc.put(DB.im_subtotal, oInvc.computeSubtotal(oConn));
	oInvc.put(DB.im_taxes, oInvc.computeTaxes(oConn));
	oInvc.put(DB.im_total, oInvc.computeTotal(oConn));
	oInvc.put(DB.im_paid, new BigDecimal(0d));
    oInvc.store(oConn);	
    	
    DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_x_course_bookings+" SET "+DB.gu_invoice+"='"+oInvc.getString(DB.gu_invoice)+"' WHERE "+DB.gu_acourse+"='"+getString(DB.gu_acourse)+"' AND "+DB.gu_contact+"='"+getString(DB.gu_contact)+"'");
	
    return oInvc;
  } // createInvoiceForContact

  // ---------------------------------------------------------------------------

  public Invoice getInvoice(JDCConnection oConn)
    throws SQLException, IllegalStateException {
    if (isNull(DB.gu_invoice))
      return null;
    else
      return new Invoice(oConn, getString(DB.gu_invoice));
  } // getInvoice

  // ---------------------------------------------------------------------------

  public Contact getContact(JDCConnection oConn)
    throws SQLException, IllegalStateException {
    if (isNull(DB.gu_contact))
      throw new IllegalStateException("AcademicCourseBooking.getContact() gu_contact not set");
    return new Contact(oConn, getString(DB.gu_contact));
  }

  // ---------------------------------------------------------------------------

  public AcademicCourseAlumni getAlumni(JDCConnection oConn)
    throws SQLException, IllegalStateException {
    if (isNull(DB.gu_acourse))
      throw new IllegalStateException("AcademicCourseBooking.getAlumni() gu_acourse not set");
    if (isNull(DB.gu_contact))
      throw new IllegalStateException("AcademicCourseBooking.getAlumni() gu_contact not set");
    return new AcademicCourseAlumni(oConn, getString(DB.gu_acourse), getString(DB.gu_contact));
  }

  // ---------------------------------------------------------------------------

  public boolean isAlumni(JDCConnection oConn)
    throws SQLException, IllegalStateException {
    if (isNull(DB.gu_acourse))
      throw new IllegalStateException("AcademicCourseBooking.getAlumni() gu_acourse not set");
    if (isNull(DB.gu_contact))
      throw new IllegalStateException("AcademicCourseBooking.getAlumni() gu_contact not set");
    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM "+DB.k_x_course_alumni+" WHERE "+DB.gu_acourse+"=? AND "+DB.gu_alumni+"=?");
    oStmt.setString(1, getString(DB.gu_acourse));
    oStmt.setString(2, getString(DB.gu_contact));
    ResultSet oRSet = oStmt.executeQuery();
    boolean bIsAlumni = oRSet.next();
    oRSet.close();
    oStmt.close();
    return bIsAlumni;
  } // isAlumni

  // **********************************************************
  // Public Constants

  public static final short ClassId = 65;
}
