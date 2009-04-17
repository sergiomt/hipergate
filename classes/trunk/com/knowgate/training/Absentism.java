package com.knowgate.training;

/*
  Copyright (C) 2003-2006cx  Know Gate S.L. All rights reserved.
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

import java.util.Date;
import java.sql.SQLException;
import java.sql.PreparedStatement;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.acl.ACLUser;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.crm.Contact;
import com.knowgate.misc.Gadgets;

/**
 * Academic Course Absentism
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class Absentism extends DBPersist {

  public Absentism() {
    super(DB.k_absentisms, "Absentism");
  }

  public Absentism(String sGuAbsentism) {
    super(DB.k_absentisms, "Absentism");
    put(DB.gu_absentism, sGuAbsentism);
  }

  public Absentism(JDCConnection oConn, String sGuAbsentism)
    throws SQLException {
    super(DB.k_absentisms, "Absentism");
    load(oConn, new Object[]{sGuAbsentism});
  }

  // ---------------------------------------------------------------------------

  public AcademicCourseAlumni getAlumni(JDCConnection oConn) throws SQLException {
    AcademicCourseAlumni oAlmn;
    if (isNull(DB.gu_alumni) || isNull(DB.gu_acourse)) {
      oAlmn = null;
    } else {
      oAlmn = new AcademicCourseAlumni();
      if (!oAlmn.load(oConn, new Object[]{get(DB.gu_acourse),get(DB.gu_alumni)}))
        oAlmn = null;
    } // fi
    return oAlmn;
  } // getAlumni

  // ---------------------------------------------------------------------------

  public Contact getContact(JDCConnection oConn) throws SQLException {
    AcademicCourseAlumni oAlmn = getAlumni(oConn);
    if (null==oAlmn)
      return null;
    else
      return oAlmn.getContact(oConn);
  } // getContact

  // ---------------------------------------------------------------------------

  public AcademicCourse getAcademicCourse(JDCConnection oConn) throws SQLException {
    AcademicCourse oAcrs;
    if (isNull(DB.gu_acourse)) {
      oAcrs = null;
    } else {
      oAcrs = new AcademicCourse();
      if (!oAcrs.load(oConn, new Object[]{get(DB.gu_acourse)}))
        oAcrs = null;
    } // fi
    return oAcrs;
  } // getAcademicCourse

  // ---------------------------------------------------------------------------

  public Subject getSubject(JDCConnection oConn) throws SQLException {
    Subject oSbjct;
    if (isNull(DB.gu_subject)) {
      oSbjct = null;
    } else {
      oSbjct = new Subject();
      if (!oSbjct.load(oConn, new Object[]{get(DB.gu_subject)}))
        oSbjct = null;
    } // fi
    return oSbjct;
  } // getSubject

  // ---------------------------------------------------------------------------

  public ACLUser getWriter(JDCConnection oConn) throws SQLException {
    ACLUser oUsr = new ACLUser();
    if (!oUsr.load(oConn, new Object[]{get(DB.gu_writer)}))
      oUsr = null;
    return oUsr;
  } // getWriter

  // ---------------------------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException{
    if (!AllVals.containsKey(DB.dt_modified))
      AllVals.put(DB.dt_modified, new Date());
    if (!AllVals.containsKey(DB.gu_absentism))
      AllVals.put(DB.gu_absentism, Gadgets.generateUUID());
    return super.store(oConn);
  }

  // ---------------------------------------------------------------------------

  public boolean delete(JDCConnection oConn) throws SQLException{
    return Absentism.delete(oConn, getString(DB.gu_absentism));
  }

  // ---------------------------------------------------------------------------

  public static boolean delete (JDCConnection oConn, String sGuAbsentism)
    throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_absentisms+" WHERE "+DB.gu_absentism+"=?");
    oStmt.setString(1, sGuAbsentism);
    int iAffected = oStmt.executeUpdate();
    oStmt.close();
    return (iAffected!=0);
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 64;

}
