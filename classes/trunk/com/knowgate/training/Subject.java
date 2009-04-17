package com.knowgate.training;

/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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
import java.util.HashMap;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.misc.Gadgets;

/**
 * @author Sergio Montoro Ten
 * @version 2.2
 */

public class Subject extends DBPersist {

  // ---------------------------------------------------------------------------

  private class SubjectCourse extends DBPersist {
    public SubjectCourse() {
       super(DB.k_x_course_subject, "SubjectCourse");
    }

    public boolean store(JDCConnection oConn, HashMap oValues) throws SQLException {
      boolean bRetVal;
      if (DebugFile.trace) {
        DebugFile.writeln("Begin SubjectCourse.store([JDCConnection],[HashMap])");
        DebugFile.incIdent();
      }
      AllVals.putAll(oValues);
      bRetVal = super.store(oConn);
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End SubjectCourse.store()");
      }
      return bRetVal;
    }
  } // SubjectCourse

  // ---------------------------------------------------------------------------

  public Subject() {
     super(DB.k_subjects, "Subject");
  }

  // ---------------------------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException {
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Subject.store([JDCConnection])");
      DebugFile.incIdent();
    }

    if (!AllVals.containsKey(DB.dt_modified))
      AllVals.put(DB.dt_modified, new Date());
    if (!AllVals.containsKey(DB.gu_subject))
      AllVals.put(DB.gu_subject, Gadgets.generateUUID());
    bRetVal = super.store(oConn);

    if (AllVals.containsKey(DB.gu_course)) {
      bRetVal = new SubjectCourse().store(oConn, AllVals);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Subject.store() : " + AllVals.get(DB.gu_subject));
    }

    return bRetVal;
  } // store

  // ---------------------------------------------------------------------------

  public boolean delete (JDCConnection oConn) throws SQLException {
    return Subject.delete(oConn, getString(DB.gu_acourse));
  }

  // ---------------------------------------------------------------------------

  public static boolean delete (JDCConnection oConn, String sGuACourse) throws SQLException {
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      PreparedStatement oStmt = oConn.prepareStatement("SELECT k_sp_del_subject(?)");
      oStmt.setString(1, sGuACourse);
      oStmt.executeQuery();
      oStmt.close();
    }
    else {
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_subject(?) }");
      oCall.setString(1, sGuACourse);
      oCall.execute();
      oCall.close();
    }
    return true;
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 62;

}
