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

package com.knowgate.projtrack;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;

/**
 * <p>Duty Attachment</p>
 * This class represents objects stored as blobs at k_duties_attach table
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public class DutyAttachment {

  private int iSize;
  private String sFileName;
  private String sDutyId;

  // ---------------------------------------------------------------------------

  /**
   * Default constructor
   */
  public DutyAttachment() {
    iSize = 0;
    sFileName = sDutyId = null;
  }

  // ---------------------------------------------------------------------------

  /**
   * Constructor
   * @param sIdDuty String GUID of Duty
   * @param sNameFile String File Name
   * @param iSizeFile int File size in bytes
   */
  public DutyAttachment(String sIdDuty, String sNameFile, int iSizeFile) {
    iSize = iSizeFile;
    sDutyId = sIdDuty;
    sFileName = sNameFile;
  }

  // ---------------------------------------------------------------------------

  /**
   *
   * @return int File size in bytes
   */
  public int size() { return iSize; }

  // ---------------------------------------------------------------------------

  /**
   *
   * @return String File Name
   */
  public String fileName() { return sFileName; }

  // ---------------------------------------------------------------------------

  /**
   *
   * @return String Duty GUID
   */
  public String dutyId() { return sDutyId; }

  // ---------------------------------------------------------------------------

  /**
   * Get stored attachment as byte array
   * @param oConn JDCConnection
   * @return byte[]
   * @throws SQLException
   * @throws IOException
   */
  public byte[] getBytes(JDCConnection oConn)
    throws SQLException, IOException {
    byte[] aBytes;
    PreparedStatement oStmt = oConn.prepareStatement(
      "SELECT "+DB.len_file+","+DB.bin_file+" FROM "+DB.k_duties_attach+ " WHERE "+DB.gu_duty+"=? AND "+DB.tx_file+"=?",
      ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sDutyId);
    oStmt.setString(2, sFileName);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      aBytes = new byte[oRSet.getInt(1)];
      oRSet.getBinaryStream(2).read(aBytes);
    } else {
      aBytes = null;
    }
    oRSet.close();
    oStmt.close();
    return aBytes;
  } // getBytes

  // ---------------------------------------------------------------------------

  /**
   * Remove attachment from k_duties_attach table
   * @param oConn JDCConnection
   * @throws SQLException
   */
  public void delete (JDCConnection oConn) throws SQLException {
    DutyAttachment.delete(oConn, sDutyId, sFileName);
  }

  // ---------------------------------------------------------------------------

  /**
   * Remove attachment from k_dutys_attach table
   * @param oConn JDCConnection
   * @param sDutyId String
   * @param sFileName String
   * @throws SQLException
   */
  public static void delete (JDCConnection oConn, String sDutyId, String sFileName)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Duty.delete([JDCConnection],"+sDutyId+","+sFileName+")");
      DebugFile.incIdent();
    }
    PreparedStatement oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_duties_attach + " WHERE " + DB.gu_duty + "=? AND " + DB.tx_file + "=?");
    oDlte.setString(1, sDutyId);
    oDlte.setString(2, sFileName);
    oDlte.executeUpdate();
    oDlte.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Duty.delete()");
    }
  } // delete

  // ---------------------------------------------------------------------------

  /**
   * Insert attachment into k_duties_attach table
   * @param oConn JDCConnection
   * @param sDutyId String GUID of Duty to which attachment belongs
   * @param sFilePath String Full path to local file
   * @throws SQLException
   * @throws FileNotFoundException
   * @throws IOException
   * @throws NullPointerException
   */
  public static void createFromFile(JDCConnection oConn, String sDutyId, String sFilePath)
    throws SQLException, FileNotFoundException, IOException, NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DutyAttachment.createFromFile([JDCConnection],"+sDutyId+","+sFilePath+")");
      DebugFile.incIdent();
    }

    File oFile = new File(sFilePath);

    if (!oFile.exists()) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new FileNotFoundException(sFilePath);
    }

    PreparedStatement oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_duties_attach + "(" + DB.gu_duty + "," + DB.tx_file + "," + DB.len_file + "," + DB.bin_file + ") VALUES (?,?,?,?)");

    int iFileLen = new Long(oFile.length()).intValue();

    FileInputStream oFileStream = new FileInputStream (oFile);
    oStmt.setString(1, sDutyId);
    oStmt.setString(2, oFile.getName());
    oStmt.setInt(3, iFileLen);
    oStmt.setBinaryStream(4, oFileStream, iFileLen);
    oStmt.executeUpdate();
    oStmt.close();
    oFileStream.close();
    oFileStream = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DutyAttachment.createFromFile()");
    }
  } // createFromFile

  // **********************************************************
  // Constantes Publicas

  public static final short ClassId = 85;

}
