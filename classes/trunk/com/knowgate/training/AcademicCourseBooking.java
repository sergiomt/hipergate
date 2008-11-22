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
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.crm.Contact;

/**
 * Booking for an academic course
 * @author Sergio Montoro Ten
 * @version 1.0
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
