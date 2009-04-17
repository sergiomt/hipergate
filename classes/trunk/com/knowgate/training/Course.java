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
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DBSubset;

/**
 * @author Sergio Montoro Ten
 * @version 2.2
 */

public class Course extends DBPersist {

  public Course() {
     super(DB.k_courses, "Course");
  }

  public Course(JDCConnection oConn, String sGuCourse)
    throws SQLException {
    super(DB.k_courses, "Course");
    load(oConn, new Object[]{sGuCourse});
  }

  // ---------------------------------------------------------------------------

  public boolean active() {
    boolean bRetVal;
    if (isNull(DB.bo_active))
      bRetVal = false;
    else
      bRetVal = (getShort(DB.bo_active)==(short) 1);
    return bRetVal;
  } // active

  // ---------------------------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException {
    if (!AllVals.containsKey(DB.dt_modified))
      AllVals.put(DB.dt_modified, new Date());
    if (!AllVals.containsKey(DB.gu_course))
      AllVals.put(DB.gu_course, Gadgets.generateUUID());
    return super.store(oConn);
  }

  // ---------------------------------------------------------------------------

  public boolean delete (JDCConnection oConn) throws SQLException {
    return Course.delete(oConn, getString(DB.gu_course));
  }

  // ---------------------------------------------------------------------------

  public AcademicCourse[] getAcademicCourses(JDCConnection oConn)
    throws SQLException {
    AcademicCourse[] aACrss = null;
    DBSubset oACrss = new DBSubset(DB.k_academic_courses,
                                   new AcademicCourse().getTable(oConn).getColumnsStr(),
                                   DB.gu_course+"=? ORDER BY "+DB.dt_created,10);
    int nACrss = oACrss.load(oConn, new Object[]{get(DB.gu_course)});
    if (nACrss>0) {
      aACrss = new AcademicCourse[nACrss];
      for (int a=0; a<nACrss; a++) {
        aACrss[a] = new AcademicCourse();
        aACrss[a].putAll(oACrss.getRowAsMap(a));
      } // next
    } // fi
    return aACrss;
  } // getAcademicCourses

  // ---------------------------------------------------------------------------

  public Subject[] getSubjects(JDCConnection oConn) throws SQLException {
    Subject[] aSubjs = null;
    DBSubset oSubjs = new DBSubset(DB.k_subjects,
                                   new Subject().getTable(oConn).getColumnsStr(),
                                   DB.gu_workarea+"=? AND "+
                                   DB.gu_course+"=? ORDER BY "+DB.nm_subject,50);
    int nSubjs = oSubjs.load(oConn, new Object[]{get(DB.gu_workarea),get(DB.gu_course)});
    if (nSubjs>0) {
      aSubjs = new Subject[nSubjs];
      for (int s=0; s<nSubjs; s++) {
        aSubjs[s] = new Subject();
        aSubjs[s].putAll(oSubjs.getRowAsMap(s));
      } // next
    } // fi
    return aSubjs;
  } // getSubjects

  // ---------------------------------------------------------------------------

  public static boolean delete (JDCConnection oConn, String sGuCourse) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Course.delete([JDCConnection],"+sGuCourse+")");
      DebugFile.incIdent();
    }
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT k_sp_del_course('"+sGuCourse+"'))");
      PreparedStatement oStmt = oConn.prepareStatement("SELECT k_sp_del_course(?)");
      oStmt.setString(1, sGuCourse);
      oStmt.executeQuery();
      oStmt.close();
    }
    else {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareCall({ call k_sp_del_course('"+sGuCourse+"') })");
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_course(?) }");
      oCall.setString(1, sGuCourse);
      oCall.execute();
      oCall.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Course.delete()");
    }
    return true;
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 60;

}
