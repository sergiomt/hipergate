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

package com.knowgate.addrbook;

import java.io.InputStream;
import java.io.ByteArrayOutputStream;

import java.util.Date;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Timestamp;

import com.knowgate.debug.DebugFile;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Base64Encoder;

import java.util.Iterator;

/**
 * <p>Enterprise Fellow</p>
 * @author Sergio Montoro ten
 * @version 3.0
 */

public class Fellow extends DBPersist {
  public Fellow() {
    super(DB.k_fellows, "Fellow");
  }

  //-------------------------------------------------------------------

  /**
   * Construct object and set gu_fellow field.
   * Object is not fully loaded from database.
   * @param sFellowId Fellow Unique Identifier
   */

  public Fellow(String sFellowId) {
    super(DB.k_fellows, "Fellow");
    put(DB.gu_fellow, sFellowId);
  }

  //-------------------------------------------------------------------

  /**
   * <p>Construct object and load fields from database.</p>
   * @param oConn database Connection
   * @param sFellowId Fellow Unique Identifier
   * @throws SQLException
   */
  public Fellow(JDCConnection oConn, String sFellowId) throws SQLException {
    super(DB.k_fellows, "Fellow");
    load ((Connection) oConn, new Object[] { sFellowId });
  }

  //-------------------------------------------------------------------

  /**
   * <p>Create a fellow from a {@link ACLUser} or from another fellow
   * <p>The fellow is internally stored at this object but NOT persisted to database.</p>
   * @param oUsr ACLUser Identifier or Fellow identifier.
   */
  public void clone(DBPersist oUsr) {
    String sField;
    String sSurName;
    String sSurName1 = "";
    String sSurName2 = "";

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Fellow.clone(" + oUsr.getStringNull(DB.gu_user,"null") + ")");
      DebugFile.incIdent();
    }

    Iterator oFields = oUsr.getItems().iterator();

    while (oFields.hasNext()) {
      sField = (String) oFields.next();

      if (sField.equals(DB.tx_main_email))
        put(DB.tx_email, oUsr.get(DB.tx_main_email));
      else if (sField.equals(DB.nm_user))
        put(DB.tx_name, oUsr.get(DB.nm_user));
      else if (sField.equals(DB.tx_surname1))
        sSurName1 = oUsr.getStringNull(DB.tx_surname1, "");
      else if (sField.equals(DB.tx_surname2))
        sSurName2 = " " + oUsr.getStringNull(DB.tx_surname2, "");
      else
        put(sField, oUsr.get(sField));
    } // wend

    sSurName = sSurName1 + sSurName2;

    if (sSurName.trim().length()>0) put(DB.tx_surname, sSurName);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Fellow.clone()");
    }
  } // clone

  // ----------------------------------------------------------
  /**
   * @param oConn Database Connection
   * @return <b>true</b> if Fellow has an associated record at k_fellows_attach table</p>
   * @throws SQLException
   */
  public boolean hasPhoto(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Fellow.hasPhoto([Connection])");
      DebugFile.incIdent();

      DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM " + DB.k_fellows_attach + " WHERE " + DB.gu_fellow + "=" + getStringNull(DB.gu_fellow,"null") + ")");
    }

    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_fellows_attach + " WHERE " + DB.gu_fellow + "=?");
    oStmt.setString(1, getString(DB.gu_fellow));
    ResultSet oRSet = oStmt.executeQuery();
    boolean bHasAttach = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Fellow.hasPhoto() : " + String.valueOf(bHasAttach));
    }

    return bHasAttach;
  } // hasPhoto

  // ----------------------------------------------------------

  /**
   * <P>Get Fellow Photo as a byte array</P>
   * @param oConn JDBC Connection
   * @return Byte Array or <b>null</b> if Fellow does not have a photograph.
   * @throws SQLException
   */
  public byte[] getPhoto (Connection oConn)
     throws SQLException {

     if (DebugFile.trace) {
       DebugFile.writeln("Begin Fellow.getPhoto([Connection])");
       DebugFile.incIdent();
     }

     ByteArrayOutputStream oOut = null;
     PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.len_file + "," + DB.bin_file + " FROM " + DB.k_fellows_attach + " WHERE " + DB.gu_fellow + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
     oStmt.setString(1, getString(DB.gu_fellow));
     ResultSet oRSet = oStmt.executeQuery();

     if (oRSet.next()) {
       int iLen = oRSet.getInt(1);

       if (iLen>0)
         oOut = new ByteArrayOutputStream(iLen);
       else
         oOut = new ByteArrayOutputStream();

       byte[] oBuffer = new byte[4000];

       InputStream oBlob = oRSet.getBinaryStream(2);

       int iReaded = 0;
       do {
         try {
           iReaded = oBlob.read(oBuffer, 0, 4000);
           if (iReaded > 0)
             oOut.write(oBuffer, 0, iReaded);
         } catch (java.io.IOException ignore) { }
       } while (4000==iReaded);

       try { oBlob.close(); } catch (java.io.IOException ignore) { }

       oBlob = null;
     }

     oRSet.close();
     oStmt.close();

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Fellow.getPhoto()");
     }

     if (oOut!=null)
       return oOut.toByteArray();
     else
       return null;
  } // getPhoto

  // ----------------------------------------------------------

  /**
   * <p>Load Fellow</p>
   * This method extends the base DBPersist.load() by reading data
   * from k_fellows, k_fellows_attach and k_users and putting all columns
   * into the internal column Map of this instance.
   * @param oConn Database connection
   * @param PKVals A String array with a single element containing GUID of Fellow to be loaded
   * @return <b>true</b> if Fellow was found k_fellows table
   * @throws SQLException
   */
  public boolean load(Connection oConn, Object[] PKVals) throws SQLException {

    Object oCol;
    PreparedStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    int iCols;
    boolean bRetVal = false;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Fellow.load([Connection], " + PKVals[0] + ")");
      DebugFile.incIdent();
    }

    oStmt = oConn.prepareStatement("SELECT * FROM " + DB.k_fellows + " WHERE " + DB.gu_fellow + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, (String) PKVals[0]);
    oRSet = oStmt.executeQuery();
    oMDat = oRSet.getMetaData();
    iCols = oMDat.getColumnCount();

    if (oRSet.next()) {
      bRetVal = true;

      for (int c=1; c<=iCols; c++) {
        if (!oMDat.getColumnName(c).equalsIgnoreCase(DB.dt_created)) {
          oCol = oRSet.getObject(c);
          if (!oRSet.wasNull())
            AllVals.put(oMDat.getColumnName(c).toLowerCase(), oCol);
        }
      } // next
    } // fi (oRSet.next())

    oRSet.close();
    oStmt.close();

    if (bRetVal) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT * FROM " + DB.k_users + " WHERE " + DB.gu_user + "='" + getStringNull(DB.gu_fellow, "null") + "')");

      oStmt = oConn.prepareStatement("SELECT * FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, (String) PKVals[0]);
      oRSet = oStmt.executeQuery();
      oMDat = oRSet.getMetaData();
      iCols = oMDat.getColumnCount();

      if (oRSet.next()) {
        for (int c=1; c<=iCols; c++) {
          if (!oMDat.getColumnName(c).equalsIgnoreCase(DB.dt_created) && !AllVals.containsKey(oMDat.getColumnName(c))) {
            oCol = oRSet.getObject(c);
            if (!oRSet.wasNull())
              AllVals.put (oMDat.getColumnName(c).toLowerCase(), oCol);
          }
        } // next
      } // fi

      oRSet.close();
      oStmt.close();

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.tx_file + "," + DB.len_file + " FROM " + DB.k_fellows_attach + " WHERE " + DB.gu_fellow + "='" + getStringNull(DB.gu_fellow, "null") + "')");

      oStmt = oConn.prepareStatement("SELECT " + DB.tx_file + "," + DB.len_file + " FROM " + DB.k_fellows_attach + " WHERE " + DB.gu_fellow + "=?");
      oStmt.setString(1, (String) PKVals[0]);
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        put(DB.tx_file, oRSet.getString(1));
        put(DB.len_file, oRSet.getInt(2));
      }
      oRSet.close();
      oStmt.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Fellow.load() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // load

  // ----------------------------------------------------------

  /**
   * <p>Load Fellow</p>
   * This method extends the base DBPersist.load() by reading data
   * from k_fellows, k_fellows_attach and k_users and putting all columns
   * into the internal column Map of this instance.
   * @param oConn Database connection
   * @param PKVals A String array with a single element containing GUID of Fellow to be loaded
   * @return <b>true</b> if Fellow was found k_fellows table
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    return load((Connection) oConn, PKVals);
  }

  // ----------------------------------------------------------

  /**
   * <p>Load Fellow</p>
   * This method extends the base DBPersist.load() by reading data
   * from k_fellows, k_fellows_attach and k_users and putting all columns
   * into the internal column Map of this instance.
   * @param oConn Database connection
   * @param sGuFellow GUID of Fellow to be loaded
   * @return <b>true</b> if Fellow was found k_fellows table
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, String sGuFellow) throws SQLException {
    return load(oConn, new Object[]{sGuFellow});
  }

  // ----------------------------------------------------------

  /**
   * <p>Store Fellow</p>
   * This method extends the base DBPersist.load() by automatically creating
   * a value for gu_fellow if none is suplied and updating dt_modified to current date.
   * It does not write any data to k_users nor k_fellows_attach tables.
   * @param oConn Database connection
   * @throws SQLException
   */
   
  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    // Si no se especificó un identificador, entonces añadirlo automáticamente
    if (!AllVals.containsKey(DB.gu_fellow))
      put(DB.gu_fellow, Gadgets.generateUUID());

    // Forzar la fecha de modificación del registro
    replace(DB.dt_modified, dtNow);

    return super.store(oConn);
  } // store

  // ----------------------------------------------------------

  /**
   * <p>Check whether this Fellow is available at the given time</p>
   * This function checks both the Working Calendar for the fellow (if any)
   * and the meetings to which he attends, for determining if he is available.
   * @param oConn Database Connection
   * @param dtAt Date and Time to be checked for availability
   * @return boolean <b>true</b> if given date is within working time of Fellow and he is not attending to any other meeting right then.
   * @throws SQLException
   * @since 4.0
   */
  public boolean isAvailableAt(JDCConnection oConn, Date dtAt) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Fellow.isAvailable([Connection], " + dtAt + ")");
      DebugFile.incIdent();
    }

    boolean bAvailable = true;

    WorkingCalendar oWrkCal = WorkingCalendar.forUser(oConn, getString(DB.gu_fellow), new Date(dtAt.getTime()-86400000l), new Date(dtAt.getTime()+86400000l),null, null);
    if (null!=oWrkCal) {
      bAvailable = oWrkCal.isWorkingTime(dtAt);
    }

    if (bAvailable) {
      bAvailable = (getMeetingAt(oConn, dtAt)==null);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Fellow.isAvailable() : " + String.valueOf(bAvailable));
    }

    return bAvailable;
  } // isAvailableAt

  // ----------------------------------------------------------

  /**
   * <p>Check whether this Fellow is available at the given time interval</p>
   * This function checks both the Working Calendar for the fellow (if any)
   * and the meetings to which he attends, for determining if he is available.
   * @param oConn Database Connection
   * @param dtFrom Start Date and Time to be checked for availability
   * @param dtTo End Date and Time to be checked for availability
   * @return boolean <b>true</b> if given date is within working time of Fellow and he is not attending to any other meeting right then.
   * @throws SQLException
   * @since 4.0
   */
  public boolean isAvailableAt(JDCConnection oConn, Date dtFrom, Date dtTo) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Fellow.isAvailable([Connection], " + dtFrom + "," + dtTo + ")");
      DebugFile.incIdent();
    }

    boolean bAvailable = true;
	WorkingCalendar oWrkCal;
	
    if (null==dtTo)
      oWrkCal = WorkingCalendar.forUser(oConn, getString(DB.gu_fellow), new Date(dtFrom.getTime()-86400000l), new Date(dtFrom.getTime()+86400000l),null, null);
    else
      oWrkCal = WorkingCalendar.forUser(oConn, getString(DB.gu_fellow), new Date(dtFrom.getTime()), new Date(dtTo.getTime()),null, null);
    
    if (null!=oWrkCal) {
      bAvailable = oWrkCal.isWorkingTime(dtFrom);
	  if (dtTo!=null && bAvailable) bAvailable = oWrkCal.isWorkingTime(dtTo);
    }

    if (bAvailable) {
      if (null==dtTo)
        bAvailable = (getMeetingAt(oConn, dtFrom)==null);
      else
        bAvailable = (getMeetingAt(oConn, dtFrom, dtTo)==null);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Fellow.isAvailable() : " + String.valueOf(bAvailable));
    }

    return bAvailable;
  } // isAvailableAt

  // ----------------------------------------------------------

  /**
   * <p>Get meeting for this user at the given date and time (if any)</p>
   * If the fellow is attending to several meetings at the given time, only the first one is returned.
   * @param oConn Database Connection
   * @param dtAt Date and Time to be checked for availability
   * @return String GUID of Meeting or <b>null</b> if Fellow is not attending to any Meeting at that time
   * @throws SQLException
   * @since 4.0
   */
   
  public String getMeetingAt(JDCConnection oConn, Date dtAt) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Fellow.getMeetingAt([Connection], " + dtAt + ")");
      DebugFile.incIdent();
    }

    String sGuMeeting;
    String sSQL = "SELECT m."+DB.gu_meeting+" FROM "+DB.k_meetings+" m,"+DB.k_x_meeting_fellow+" x "+
    			  "WHERE x."+DB.gu_meeting+"=m."+DB.gu_meeting+" AND x."+DB.gu_fellow+"=? AND "+
    			  	     "? BETWEEN m."+DB.dt_start+" AND m."+DB.dt_end;
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
    PreparedStatement oStmt = oConn.prepareStatement(sSQL);
    oStmt.setString(1, getString(DB.gu_fellow));
    oStmt.setTimestamp(2, new Timestamp(dtAt.getTime()));
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sGuMeeting = oRSet.getString(1);
    else
      sGuMeeting = null;
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Fellow.getMeetingAt() : " + sGuMeeting);
    }

    return sGuMeeting;
  } // getMeetingAt

  // ----------------------------------------------------------

  /**
   * <p>Get meeting for this user at the given time interval (if any)</p>
   * If the fellow is attending to several meetings at the given time, only the first one is returned.
   * @param oConn Database Connection
   * @param dtFrom Start Date and Time to be checked for availability
   * @param dtTo End Date and Time to be checked for availability
   * @return String GUID of Meeting or <b>null</b> if Fellow is not attending to any Meeting at that interval
   * @throws SQLException
   * @since 4.0
   */
   
  public String getMeetingAt(JDCConnection oConn, Date dtFrom, Date dtTo) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Fellow.getMeetingAt([Connection], " + dtFrom + "," + dtTo + ")");
      DebugFile.incIdent();
    }

    String sGuMeeting;
    String sSQL = "SELECT m."+DB.gu_meeting+" FROM "+DB.k_meetings+" m,"+DB.k_x_meeting_fellow+" x "+
    	          "WHERE x."+DB.gu_meeting+"=m."+DB.gu_meeting+" AND x."+DB.gu_fellow+"=? AND ("+
    	          "((? BETWEEN m."+DB.dt_start+" AND m."+DB.dt_end+" OR "+
    	          "  ? BETWEEN m."+DB.dt_start+" AND m."+DB.dt_end+")) OR "+
    	          "(m."+DB.dt_start+" BETWEEN ? AND ? AND m."+DB.dt_end+" BETWEEN ? AND ?))";
    if (DebugFile.trace) {
      DebugFile.writeln("Connection.prepareStatement(SELECT m."+DB.gu_meeting+" FROM "+DB.k_meetings+" m,"+DB.k_x_meeting_fellow+" x "+
    	          "WHERE x."+DB.gu_meeting+"=m."+DB.gu_meeting+" AND x."+DB.gu_fellow+"='"+getStringNull(DB.gu_fellow,"")+"' AND ("+
    	          "(("+dtFrom+" BETWEEN m."+DB.dt_start+" AND m."+DB.dt_end+" OR "+
    	          "  "+dtTo+" BETWEEN m."+DB.dt_start+" AND m."+DB.dt_end+")) OR "+
    	          "(m."+DB.dt_start+" BETWEEN "+dtFrom+" AND "+dtTo+" AND m."+DB.dt_end+" BETWEEN "+dtFrom+" AND "+dtTo+")))");
    }
    PreparedStatement oStmt = oConn.prepareStatement(sSQL);
    oStmt.setString(1, getString(DB.gu_fellow));
    oStmt.setTimestamp(2, new Timestamp(dtFrom.getTime()));
    oStmt.setTimestamp(3, new Timestamp(dtTo.getTime()));
    oStmt.setTimestamp(4, new Timestamp(dtFrom.getTime()));
    oStmt.setTimestamp(5, new Timestamp(dtTo.getTime()));
    oStmt.setTimestamp(6, new Timestamp(dtFrom.getTime()));
    oStmt.setTimestamp(7, new Timestamp(dtTo.getTime()));
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sGuMeeting = oRSet.getString(1);
    else
      sGuMeeting = null;
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Fellow.getMeetingAt() : " + sGuMeeting);
    }

    return sGuMeeting;
  } // getMeetingAt
  
  // ----------------------------------------------------------

  public boolean delete(JDCConnection oConn) throws SQLException {

    return Fellow.delete(oConn, getString(DB.gu_fellow));
  }

  // ----------------------------------------------------------

  /**
   *
   * @return
   * @throws SQLException
   * @since 2.1
   * @see <A href="http://www.faqs.org/rfcs/rfc2426.html">RFC 2426 (Plain Text)</A><BR>
   * @see <A href="http://www.imc.org/pdi/vcard-21.doc">vCard 2.1 Spec (MS Word format)</A><BR>
   */
  public String vCard(Connection oConn)
    throws SQLException {

    final String CrLf = new String(new byte[]{13,10});

    StringBuffer oCardBuffer = new StringBuffer();

    oCardBuffer.append("BEGIN:VCARD" + CrLf);
    oCardBuffer.append("VERSION:3.0" + CrLf);
    oCardBuffer.append("PRODID:hipergate" + CrLf);
    oCardBuffer.append("CLASS:PUBLIC" + CrLf);

    oCardBuffer.append("FN:");
    if (!isNull(DB.tx_name)) oCardBuffer.append(getString(DB.tx_name));
    if (!isNull(DB.tx_surname)) oCardBuffer.append(" " + getString(DB.tx_surname));
    oCardBuffer.append(CrLf);

    oCardBuffer.append("N:");
    oCardBuffer.append(getStringNull(DB.tx_surname1, "") + ";");
    oCardBuffer.append(getStringNull(DB.nm_user, "") + ";");
    oCardBuffer.append(getStringNull(DB.tx_surname2, "") + ";");
    oCardBuffer.append(";;" + CrLf);

    if (!isNull(DB.tx_nickname)) {
      oCardBuffer.append("NICKNAME:" + getString(DB.tx_nickname) + CrLf);
    }

    byte[] byPhoto = getPhoto(oConn);

    if (null!=byPhoto) {
      String sType = "";
      int iDot = getStringNull(DB.tx_file, "").lastIndexOf('.');
      if (iDot>0 && iDot<getStringNull(DB.tx_file, "").length()-1)
        sType = getString(DB.tx_file).substring(iDot+1).toUpperCase();
      if (sType.equals("JPG")) sType = "JPEG";

      if (sType.length()>0)
        oCardBuffer.append("PHOTO;ENCODING=BASE64;TYPE=" + sType + ":" + Base64Encoder.encode(byPhoto) + CrLf);
    }

    if (!isNull(DB.dt_birth)) {
      oCardBuffer.append("BDAY:" + getDateFormated(DB.dt_birth, "yyyyMMdd") + CrLf);
    }

    if (!isNull(DB.work_phone)) {
      oCardBuffer.append("TEL;WORK:" + getString(DB.work_phone) + CrLf);
    }

    if (!isNull(DB.home_phone)) {
      oCardBuffer.append("TEL;HOME:" + getString(DB.home_phone) + CrLf);
    }

    if (!isNull(DB.mov_phone)) {
      oCardBuffer.append("TEL;CELL:" + getString(DB.mov_phone) + CrLf);
    }

    if (!isNull(DB.tx_email)) {
      oCardBuffer.append("EMAIL;INTERNET:" + getString(DB.tx_email) + CrLf);
    }

    if (!isNull(DB.tx_timezone)) {
      oCardBuffer.append("TZ:" + getString(DB.tx_timezone) + CrLf);
    }

    if (!isNull(DB.de_title)) {
      oCardBuffer.append("TITLE:" + getString(DB.de_title) + CrLf);
    }

    if (!isNull(DB.nm_company)) {
      oCardBuffer.append("ORG:" + getString(DB.nm_company));
      if (!isNull(DB.tx_division)) oCardBuffer.append(";" + getString(DB.tx_division));
      if (!isNull(DB.tx_dept)) oCardBuffer.append(";" + getString(DB.tx_dept));
      oCardBuffer.append(CrLf);
    }

    if (!isNull(DB.tx_comments)) {
      oCardBuffer.append("NOTE:" + getString(DB.tx_comments) + CrLf);
    }

    if (!isNull(DB.dt_modified)) {
      oCardBuffer.append("REV:" + getDateFormated(DB.dt_modified, "yyyyMMddhhmmss") + CrLf);
    }

    oCardBuffer.append("UID:" + getString(DB.gu_fellow) + CrLf);

    oCardBuffer.append("END:VCARD" + CrLf);

    return oCardBuffer.toString();
  } // vCard

  // **********************************************************
  // Metodos Estáticos

  /**
   * <p>Delete Fellow</p>
   * <p>Calls k_sp_del_fellow stored procedure</p>
   * @param oConn Database Connection
   * @param sFellowGUID Identifier of Fellow to delete
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sFellowGUID) throws SQLException {
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Fellow.delete([Connection]," + sFellowGUID + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareCall({call k_sp_del_fellow ('" + sFellowGUID + "')})");
    }

    CallableStatement oCall = oConn.prepareCall("{call k_sp_del_fellow ('" + sFellowGUID + "')}");
    bRetVal = oCall.execute();
    oCall.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Fellow.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  // **********************************************************
  // Private Variables

  public static final short ClassId = 20;
}
