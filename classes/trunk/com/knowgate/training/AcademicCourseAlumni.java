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

import java.util.Comparator;
import java.util.HashMap;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.crm.Contact;

/**
 * Actual attendant to an academic course
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class AcademicCourseAlumni extends DBPersist implements Comparator {

  public AcademicCourseAlumni() {
    super(DB.k_x_course_alumni, "AcademicCourseAlumni");
  }

  // ---------------------------------------------------------------------------

  public AcademicCourseAlumni(String sAcademicCourseId, String sContactId) {
    super(DB.k_x_course_alumni, "AcademicCourseAlumni");
    put (DB.gu_acourse, sAcademicCourseId);
    put (DB.gu_alumni, sContactId);
  }

  // ---------------------------------------------------------------------------

  public AcademicCourseAlumni(JDCConnection oConn,
                               String sAcademicCourseId, String sContactId)
    throws SQLException {
    super(DB.k_x_course_alumni, "AcademicCourseAlumni");
    load(oConn, new Object[]{sAcademicCourseId, sContactId});
  }

  // ---------------------------------------------------------------------------

  public int compare(Object o1, Object o2) {
    return ((AcademicCourseAlumni)o1).getString(DB.gu_alumni).compareTo(((AcademicCourseAlumni)o2).getString(DB.gu_alumni));
  }

  // ---------------------------------------------------------------------------

  public boolean equals(AcademicCourseAlumni o2) {
    return getString(DB.gu_acourse).equals(o2.getString(DB.gu_acourse)) && getString(DB.gu_alumni).equals(o2.getString(DB.gu_alumni));
  }

  // ---------------------------------------------------------------------------

  public Contact getContact(JDCConnection oConn)
    throws SQLException, IllegalStateException {
    if (isNull(DB.gu_alumni))
      throw new IllegalStateException("AcademicCourseAlumni.getContact() gu_alumni not set");
    return new Contact(oConn, getString(DB.gu_alumni));
  }

  // ---------------------------------------------------------------------------

  public HashMap getEvaluations(JDCConnection oConn)
    throws SQLException, IllegalStateException {

  if (isNull(DB.gu_acourse))
    throw new IllegalStateException("AcademicCourseAlumni.getEvaluations() gu_acourse not set");
    if (isNull(DB.gu_alumni))
      throw new IllegalStateException("AcademicCourseAlumni.getEvaluations() gu_alumni not set");


    DBSubset oEvals = new DBSubset(DB.k_evaluations,
                                   new Evaluation().getTable(oConn).getColumnsStr(),
                                   DB.gu_alumni+"=? AND "+DB.gu_acourse+"=?", 20);
    int nEvals = oEvals.load(oConn, new Object[]{get(DB.gu_alumni),get(DB.gu_acourse)});
    HashMap mEvals = new HashMap();
    for (int e=0; e<nEvals; e++) {
      Evaluation oEval = new Evaluation();
      oEval.putAll(oEvals.getRowAsMap(e));
      mEvals.put(oEvals.getString(DB.gu_subject, e), oEval);
    } // next
    return mEvals;
  } // getEvaluations

  // ---------------------------------------------------------------------------

  public AcademicCourseBooking getBooking(JDCConnection oConn)
    throws SQLException, IllegalStateException {
  if (isNull(DB.gu_acourse))
    throw new IllegalStateException("AcademicCourseAlumni.getBooking() gu_acourse not set");
    if (isNull(DB.gu_alumni))
      throw new IllegalStateException("AcademicCourseAlumni.getBooking() gu_alumni not set");
    return new AcademicCourseBooking(oConn, getString(DB.gu_acourse), getString(DB.gu_contact));
  }

}
