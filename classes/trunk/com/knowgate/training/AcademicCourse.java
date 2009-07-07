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
import java.sql.ResultSet;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.crm.Contact;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipergate.Product;

/**
 * Academic Course Instance
 * @author Sergio Montoro Ten
 * @version 5.0
 */

public class AcademicCourse extends DBPersist {

  public AcademicCourse() {
    super(DB.k_academic_courses, "AcademicCourse");
  }

  public AcademicCourse(JDCConnection oConn, String sGuACourse)
    throws SQLException {
    super(DB.k_academic_courses, "AcademicCourse");
    load(oConn, new Object[]{sGuACourse});
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

  public int countAlumni(JDCConnection oConn)
    throws SQLException,IllegalStateException {

    if (isNull(DB.gu_acourse))
      throw new IllegalStateException("AcademicCourse.countBookings() gu_acourse not set");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_x_course_alumni+" WHERE "+DB.gu_acourse+"=?");
    oStmt.setString(1, getString(DB.gu_acourse));
    ResultSet oRSet = oStmt.executeQuery();
    oRSet.next();
    int nAlumni = oRSet.getInt(1);
    oRSet.close();
    oStmt.close();
    return nAlumni;
  } // countAlumni

  // ---------------------------------------------------------------------------

  public int countBookings(JDCConnection oConn)
    throws SQLException,IllegalStateException {

    if (isNull(DB.gu_acourse))
      throw new IllegalStateException("AcademicCourse.countBookings() gu_acourse not set");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_x_course_bookings+" WHERE "+DB.gu_acourse+"=? AND "+DB.bo_canceled+"<>1");
    oStmt.setString(1, getString(DB.gu_acourse));
    ResultSet oRSet = oStmt.executeQuery();
    oRSet.next();
    int nBooks = oRSet.getInt(1);
    oRSet.close();
    oStmt.close();
    return nBooks;
  } // countBookings

  // ---------------------------------------------------------------------------

  public int countConfirmedBookings(JDCConnection oConn)
    throws SQLException,IllegalStateException {

    if (isNull(DB.gu_acourse))
      throw new IllegalStateException("AcademicCourse.countBookings() gu_acourse not set");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_x_course_bookings+" WHERE "+DB.gu_acourse+"=? AND "+DB.bo_canceled+"<>1 AND "+DB.bo_confirmed+"=1");
    oStmt.setString(1, getString(DB.gu_acourse));
    ResultSet oRSet = oStmt.executeQuery();
    oRSet.next();
    int nBooks = oRSet.getInt(1);
    oRSet.close();
    oStmt.close();
    return nBooks;
  } // countConfirmedBookings

  // ---------------------------------------------------------------------------

  public int countPaidBookings(JDCConnection oConn)
    throws SQLException,IllegalStateException {

    if (isNull(DB.gu_acourse))
      throw new IllegalStateException("AcademicCourse.countBookings() gu_acourse not set");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_x_course_bookings+" WHERE "+DB.gu_acourse+"=? AND "+DB.bo_canceled+"<>1 AND "+DB.bo_paid+"=1");
    oStmt.setString(1, getString(DB.gu_acourse));
    ResultSet oRSet = oStmt.executeQuery();
    oRSet.next();
    int nBooks = oRSet.getInt(1);
    oRSet.close();
    oStmt.close();
    return nBooks;
  } // countPaidBookings

  // ---------------------------------------------------------------------------

  public int countWaitingBookings(JDCConnection oConn)
    throws SQLException,IllegalStateException {

    if (isNull(DB.gu_acourse))
      throw new IllegalStateException("AcademicCourse.countBookings() gu_acourse not set");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_x_course_bookings+" WHERE "+DB.gu_acourse+"=? AND "+DB.bo_canceled+"<>1 AND "+DB.bo_waiting+"=1");
    oStmt.setString(1, getString(DB.gu_acourse));
    ResultSet oRSet = oStmt.executeQuery();
    oRSet.next();
    int nBooks = oRSet.getInt(1);
    oRSet.close();
    oStmt.close();
    return nBooks;
  } // countWaitingBookings

  // ---------------------------------------------------------------------------

  public int maxAlumni() {
    if (isNull(DB.nu_max_alumni))
      return 2147483647;
    else
      return getInt(DB.nu_max_alumni);
  }

  // ---------------------------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException{
    if (!AllVals.containsKey(DB.dt_modified))
      AllVals.put(DB.dt_modified, new Date());
    if (!AllVals.containsKey(DB.gu_acourse))
      AllVals.put(DB.gu_acourse, Gadgets.generateUUID());
    return super.store(oConn);
  }

  // ---------------------------------------------------------------------------

  public boolean delete (JDCConnection oConn) throws SQLException {
    return AcademicCourse.delete(oConn, getString(DB.gu_acourse));
  }

  // ---------------------------------------------------------------------------

  public Contact[] getContacts(JDCConnection oConn)
    throws SQLException {
    Contact[] aContacts = null;
    DBSubset oBooks = new DBSubset(DB.k_x_course_bookings+" b,"+DB.k_contacts+" c",    							
                                   new Contact().getTable(oConn).getColumnsStr(),
                                   "b."+DB.gu_contact+"=c."+DB.gu_contact+" AND "+
                                   "b."+DB.gu_acourse+"=?",50);
    int nBooks = oBooks.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aContacts = new Contact[nBooks];
      for (int b=0; b<nBooks; b++) {
        aContacts[b] = new Contact();
        aContacts[b].putAll(oBooks.getRowAsMap(b));
      } // next
    } // fi

    return aContacts;
  } // getContacts
  
  // ---------------------------------------------------------------------------

  public AcademicCourseAlumni[] getAlumni(JDCConnection oConn)
    throws SQLException {
    AcademicCourseAlumni[] aAlmni = null;
    DBSubset oAlmni = new DBSubset(DB.k_x_course_alumni,
                                   new AcademicCourseAlumni().getTable(oConn).getColumnsStr(),
                                   DB.gu_acourse+"=? ORDER BY "+DB.gu_alumni,50);
    int nBooks = oAlmni.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aAlmni = new AcademicCourseAlumni[nBooks];
      for (int b=0; b<nBooks; b++) {
        aAlmni[b] = new AcademicCourseAlumni();
        aAlmni[b].putAll(oAlmni.getRowAsMap(b));
      } // next
    } // fi

    return aAlmni;
  } // getAlumni

  // ---------------------------------------------------------------------------

  public AcademicCourseBooking[] getAllBookings(JDCConnection oConn)
    throws SQLException {
    AcademicCourseBooking[] aBooks = null;
    DBSubset oBooks = new DBSubset(DB.k_x_course_bookings,
                                   new AcademicCourseBooking().getTable(oConn).getColumnsStr(),
                                   DB.gu_acourse+"=? ORDER BY "+DB.dt_created,50);
    int nBooks = oBooks.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aBooks = new AcademicCourseBooking[nBooks];
      for (int b=0; b<nBooks; b++) {
        aBooks[b] = new AcademicCourseBooking();
        aBooks[b].putAll(oBooks.getRowAsMap(b));
      } // next
    } // fi
    return aBooks;
  } // getAllBookings

  // ---------------------------------------------------------------------------

  public AcademicCourseBooking[] getActiveBookings(JDCConnection oConn)
    throws SQLException {
    AcademicCourseBooking[] aBooks = null;
    DBSubset oBooks = new DBSubset(DB.k_x_course_bookings,
                                   new AcademicCourseBooking().getTable(oConn).getColumnsStr(),
                                   DB.gu_acourse+"=? AND "+DB.bo_canceled+"<>1 "+
                                   "ORDER BY "+DB.dt_created,50);
    int nBooks = oBooks.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aBooks = new AcademicCourseBooking[nBooks];
      for (int b=0; b<nBooks; b++) {
        aBooks[b] = new AcademicCourseBooking();
        aBooks[b].putAll(oBooks.getRowAsMap(b));
      } // next
    } // fi
    return aBooks;
  } // getActiveBookings

  // ---------------------------------------------------------------------------

  public AcademicCourseBooking[] getCancelledBookings(JDCConnection oConn)
    throws SQLException {
    AcademicCourseBooking[] aBooks = null;
    DBSubset oBooks = new DBSubset(DB.k_x_course_bookings,
                                   new AcademicCourseBooking().getTable(oConn).getColumnsStr(),
                                   DB.gu_acourse+"=? AND "+DB.bo_canceled+"<>1 "+
                                   "ORDER BY "+DB.dt_created,50);
    int nBooks = oBooks.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aBooks = new AcademicCourseBooking[nBooks];
      for (int b=0; b<nBooks; b++) {
        aBooks[b] = new AcademicCourseBooking();
        aBooks[b].putAll(oBooks.getRowAsMap(b));
      } // next
    } // fi
    return aBooks;
  } // getCancelledBookings

  // ---------------------------------------------------------------------------

  public AcademicCourseBooking[] getConfirmedBookings(JDCConnection oConn)
    throws SQLException {
    AcademicCourseBooking[] aBooks = null;
    DBSubset oBooks = new DBSubset(DB.k_x_course_bookings,
                                   new AcademicCourseBooking().getTable(oConn).getColumnsStr(),
                                   DB.gu_acourse+"=? AND "+DB.bo_confirmed+"<>0 "+
                                   "ORDER BY "+DB.dt_created,50);
    int nBooks = oBooks.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aBooks = new AcademicCourseBooking[nBooks];
      for (int b=0; b<nBooks; b++) {
        aBooks[b] = new AcademicCourseBooking();
        aBooks[b].putAll(oBooks.getRowAsMap(b));
      } // next
    } // fi
    return aBooks;
  } // getConfirmedBookings


  // ---------------------------------------------------------------------------

  public AcademicCourseBooking[] getUnconfirmedBookings(JDCConnection oConn)
    throws SQLException {
    AcademicCourseBooking[] aBooks = null;
    DBSubset oBooks = new DBSubset(DB.k_x_course_bookings,
                                   new AcademicCourseBooking().getTable(oConn).getColumnsStr(),
                                   DB.gu_acourse+"=? AND "+DB.bo_confirmed+"<>1 "+
                                   "ORDER BY "+DB.dt_created,50);
    int nBooks = oBooks.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aBooks = new AcademicCourseBooking[nBooks];
      for (int b=0; b<nBooks; b++) {
        aBooks[b] = new AcademicCourseBooking();
        aBooks[b].putAll(oBooks.getRowAsMap(b));
      } // next
    } // fi
    return aBooks;
  } // getConfirmedBookings

  // ---------------------------------------------------------------------------

  public AcademicCourseBooking[] getWaitingBookings(JDCConnection oConn)
    throws SQLException {
    AcademicCourseBooking[] aBooks = null;
    DBSubset oBooks = new DBSubset(DB.k_x_course_bookings,
                                   new AcademicCourseBooking().getTable(oConn).getColumnsStr(),
                                   DB.gu_acourse+"=? AND "+DB.bo_waiting+"<>0 "+
                                   "ORDER BY "+DB.dt_created,50);
    int nBooks = oBooks.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aBooks = new AcademicCourseBooking[nBooks];
      for (int b=0; b<nBooks; b++) {
        aBooks[b] = new AcademicCourseBooking();
        aBooks[b].putAll(oBooks.getRowAsMap(b));
      } // next
    } // fi
    return aBooks;
  } // getWaitingBookings

  // ---------------------------------------------------------------------------

  public AcademicCourseBooking[] getPaidBookings(JDCConnection oConn)
    throws SQLException {
    AcademicCourseBooking[] aBooks = null;
    DBSubset oBooks = new DBSubset(DB.k_x_course_bookings,
                                   new AcademicCourseBooking().getTable(oConn).getColumnsStr(),
                                   DB.gu_acourse+"=? AND "+DB.bo_paid+"<>0 "+
                                   "ORDER BY "+DB.dt_created,50);
    int nBooks = oBooks.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aBooks = new AcademicCourseBooking[nBooks];
      for (int b=0; b<nBooks; b++) {
        aBooks[b] = new AcademicCourseBooking();
        aBooks[b].putAll(oBooks.getRowAsMap(b));
      } // next
    } // fi
    return aBooks;
  } // getPaidBookings


  // ---------------------------------------------------------------------------

  public AcademicCourseBooking[] getUnpaidBookings(JDCConnection oConn)
    throws SQLException {
    AcademicCourseBooking[] aBooks = null;
    DBSubset oBooks = new DBSubset(DB.k_x_course_bookings,
                                   new AcademicCourseBooking().getTable(oConn).getColumnsStr(),
                                   DB.gu_acourse+"=? AND "+DB.bo_paid+"<>1 "+
                                   "ORDER BY "+DB.dt_created,50);
    int nBooks = oBooks.load(oConn, new Object[]{get(DB.gu_acourse)});
    if (nBooks>0) {
      aBooks = new AcademicCourseBooking[nBooks];
      for (int b=0; b<nBooks; b++) {
        aBooks[b] = new AcademicCourseBooking();
        aBooks[b].putAll(oBooks.getRowAsMap(b));
      } // next
    } // fi
    return aBooks;
  } // getUnpaidBookings

  // ---------------------------------------------------------------------------

  public Course getCourse(JDCConnection oConn)
    throws SQLException,NullPointerException {
    if (isNull(DB.gu_course)) throw new NullPointerException("AcademicCourse.getCourse() gu_course is null");
    return new Course(oConn, getString(DB.gu_course));
  } // getCourse

  // ---------------------------------------------------------------------------

  public Subject[] getSubjects(JDCConnection oConn)
    throws SQLException,NullPointerException {
    return getCourse(oConn).getSubjects(oConn);
  }

  // ---------------------------------------------------------------------------

  public void convertConfirmedBookingsToAlumni(JDCConnection oConn)
    throws SQLException {
    AcademicCourseBooking[] aBooks = getActiveBookings(oConn);
    if (null!=aBooks) {
      for (int b=0; b<aBooks.length; b++) {
        if (aBooks[b].confirmed()) {
          aBooks[b].createAlumni(oConn);
        }
      } // next
    } // fi
  } // convertBookingsToAlumni

  // ---------------------------------------------------------------------------

  /**
   * <p>Get complete dump in XML</p>
   * This method gets a full XML dump of an academic course,
   * including its base course, subjects and bookings
   */
   
  public String toXML(JDCConnection oConn, String sIdent, String sDelim)
  	throws SQLException {
  	
  	final String sIdent2 = sIdent+sIdent;
  	final String sIdent3 = sIdent2+sIdent;
  	
  	Course oCour = new Course(oConn, getString(DB.gu_course));
  	Subject[] aSubj = oCour.getSubjects(oConn);
  	AcademicCourseBooking[] aBook = getAllBookings(oConn);
  	Contact[] aCont = getContacts(oConn);
    final int nCont = aCont.length;

  	String sXml = toXML(sIdent, sDelim);
  	int iLastTag = sXml.indexOf("</"+getAuditClassName()+">");
  	StringBuffer oXml = new StringBuffer(8000);
  	oXml.append(sXml.substring(0, iLastTag));
  	oXml.append(sDelim);
  	oXml.append(oCour.toXML(sIdent2, sDelim));
	if (null!=aSubj) {
	  oXml.append(sIdent2);
  	  oXml.append("<Subjects count=\""+String.valueOf(aSubj.length)+"\">");  
	  oXml.append(sDelim);
	  for (int s=0; s<aSubj.length; s++) {
	    oXml.append(aSubj[s].toXML(sIdent3,""));
	  }
	  oXml.append(sIdent2);
	  oXml.append("</Subjects>");
	  oXml.append(sDelim);
	}
	if (null!=aBook) {
	  oXml.append(sIdent2);
  	  oXml.append("<Bookings count=\""+String.valueOf(aBook.length)+"\">");
	  oXml.append(sDelim);
	  for (int b=0; b<aBook.length; b++) {
	  	String sBok = aBook[b].toXML(sIdent3,"");
	  	int iBok = sBok.indexOf("</AcademicCourseBooking>");
	    oXml.append(sBok.substring(0,iBok));
	    String sGuBook = aBook[b].getString(DB.gu_contact);
	    for (int c=0; c<nCont; c++) {
	      if (aCont[c].getString(DB.gu_contact).equals(sGuBook)) {
	      	oXml.append(aCont[c].toXML("",""));
	      	break;
	      } // fi
	    } // next
	    oXml.append("</AcademicCourseBooking>");
	    oXml.append(sDelim);
	  } // next
	  oXml.append(sIdent2);
	  oXml.append("</Bookings>");
	  oXml.append(sDelim);
	}
	return oXml.toString();
  } // toXML

  // ---------------------------------------------------------------------------

  public static boolean delete (JDCConnection oConn, String sGuACourse) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin AcademicCourse.delete([JDCConnection],"+sGuACourse+")");
      DebugFile.incIdent();
    }
    
    String sGuProduct = DBCommand.queryStr(oConn, "SELECT "+DB.gu_product+" FROM "+DB.k_academic_courses+" WHERE "+DB.gu_acourse+"='"+sGuACourse+"'");
    if (null!=sGuProduct) new Product(sGuProduct).delete(oConn);
    
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace) {
        DebugFile.writeln("Connection.prepareStatement(SELECT k_sp_del_acourse('"+sGuACourse+"'))");
      }
      PreparedStatement oStmt = oConn.prepareStatement("SELECT k_sp_del_acourse(?)");
      oStmt.setString(1, sGuACourse);
      oStmt.executeQuery();
      oStmt.close();
    }
    else {
      if (DebugFile.trace) {
        DebugFile.writeln("Connection.prepareCall({call k_sp_del_acourse('"+sGuACourse+"')})");
      }
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_acourse(?) }");
      oCall.setString(1, sGuACourse);
      oCall.execute();
      oCall.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End AcademicCourse.delete()");
    }
    return true;
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 61;

}
