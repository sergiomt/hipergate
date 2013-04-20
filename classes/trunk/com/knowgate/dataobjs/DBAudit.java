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

package com.knowgate.dataobjs;

import java.io.FileWriter;
import java.io.IOException;
import java.io.LineNumberReader;
import java.io.FileReader;
import java.io.BufferedReader;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;

import java.util.TreeMap;
import java.util.Iterator;

import com.knowgate.misc.Gadgets;
import com.knowgate.jdc.JDCConnection;

/**
 * Keeps an operations log at a file or database table.
 * @author Sergio Montoro ten
 * @version 7.0
 */

public class DBAudit {

  protected void finalize()  throws IOException {
    if (sAuditFile!="") oLogWriter.close();
  }

  // ----------------------------------------------------------

  /**
   * Write a log entry into k_auditing database table
   * @param oConn Database connection, if null then data if dumped to a flat file.
   * @param iIdEntity - Internal ClassId short name for audited class.
   * @param sCoOp - Operation Code (4 alphanumeric digits)
   * @param sGUUser - GUID of user performing the operation (max. 32 characters)
   * @param sGUEntity1 - GUID of primary entity (or source entity) for the operation (max. 32 characters)
   * @param sGUEntity2 - GUID of secondary entity (or target entity) for the operation (max. 32 characters)
   * @param iIdTransact - Transaction Identifier
   * @param iIPAddr - User IP address
   * @param sTxParams1 - Additional parameters related to entity 1 (max 255 characters)
   * @param sTxParams2 - Additional parameters related to entity 2 (max 255 characters)
   * @throws SQLException
   * @throws SecurityException
   */

  public static void log(Connection oConn, short iIdEntity, String sCoOp, String sGUUser, String sGUEntity1, String sGUEntity2, int iIdTransact, int iIPAddr, String sTxParams1, String sTxParams2)
    throws SQLException {
    PreparedStatement oStmt;

    if (sCoOp==null)            throw new SQLException("DBAudit.log() operation code cannot be null", "23000", 23000);
    if (sCoOp.length()>4)       throw new SQLException("DBAudit.log() operation code " + sCoOp + " cannot be longer than 4 characters", "01004", 1004);
    if (sGUUser==null)          throw new SQLException("DBAudit.log() user GUID cannot be null", "23000", 23000);
    if (sGUUser.length()>32)    throw new SQLException("DBAudit.log() user GUID cannot be longer than 32 characters", "23000", 23000);
    if (sGUEntity1==null)       throw new SQLException("DBAudit.log() user entity GUID cannot be null", "23000", 23000);
    if (sGUEntity1.length()>32) throw new SQLException("DBAudit.log() entity GUID cannot be longer than 32 characters", "23000", 23000);

    if (null==oConn) {
        writeLog (iIdEntity, sCoOp, sGUUser, sGUEntity1, sGUEntity2, iIdTransact, String.valueOf(iIPAddr), sTxParams1, sTxParams2);
    }
    else {
      oStmt = oConn.prepareStatement("INSERT INTO k_auditing VALUES (?,?,?,?,?,?,?,?,?,?)");
      oStmt.setShort    (1, iIdEntity);
      oStmt.setString   (2, sCoOp);
      oStmt.setString   (3, sGUUser);
      oStmt.setTimestamp(4, new Timestamp(new java.util.Date().getTime()));
      oStmt.setString   (5, sGUEntity1);
      if (null==sGUEntity2)
        oStmt.setNull   (6, Types.VARCHAR);
      else
        oStmt.setString (6, sGUEntity2);
      oStmt.setInt      (7, iIdTransact);
      oStmt.setInt      (8, iIPAddr);
      if (null==sTxParams1)
        oStmt.setNull   (9, Types.VARCHAR);
      else
        oStmt.setString (9, Gadgets.left(sTxParams1,100));
      if (null==sTxParams2)
        oStmt.setNull   (10, Types.VARCHAR);
      else
        oStmt.setString (10, Gadgets.left(sTxParams2, 100));

      oStmt.execute();
      oStmt.close();
    } // fi (oConn)
  } // log()

  // ----------------------------------------------------------

  /**
   * Write a log entry into k_auditing database table
   * @param oConn JDCConnection Database connection, if null then data if dumped to a flat file.
   * @param iIdEntity - Internal ClassId short name for audited class.
   * @param sCoOp - Operation Code (4 alphanumeric digits)
   * @param sGUUser - GUID of user performing the operation (max. 32 characters)
   * @param sGUEntity1 - GUID of primary entity (or source entity) for the operation (max. 32 characters)
   * @param sGUEntity2 - GUID of secondary entity (or target entity) for the operation (max. 32 characters)
   * @param iIdTransact - Transaction Identifier
   * @param iIPAddr - User IP address
   * @param sTxParams1 - Additional parameters related to entity 1 (max 255 characters)
   * @param sTxParams2 - Additional parameters related to entity 2 (max 255 characters)
   * @throws SQLException
   * @throws SecurityException
   */
  public static void log(JDCConnection oConn, short iIdEntity, String sCoOp, String sGUUser, String sGUEntity1, String sGUEntity2, int iIdTransact, int iIPAddr, String sTxParams1, String sTxParams2)
	throws SQLException {
	  log((Connection) oConn, iIdEntity, sCoOp, sGUUser, sGUEntity1, sGUEntity2, iIdTransact, iIPAddr, sTxParams1, sTxParams2);
  }
  
  // ----------------------------------------------------------

  /**
   * Write a log entry into javatrc.txt file
   * @param iIdEntity - Internal ClassId short name for audited class.
   * @param sCoOp - Operation Code (4 alphanumeric digits)
   * @param sGUUser - GUID of user performing the operation (máx. 32 characters)
   * @param sGUEntity1 - GUID of primary entity (or source entity) for the operation (máx. 32 characters)
   * @param sGUEntity2 - GUID of secondary entity (or target entity) for the operation (máx. 32 characters)
   * @param iIdTransact - Transaction Identifier
   * @param iIPAddr - User IP address
   * @param sTxParams1 - Additional parameters related to entity 1 (máx 255 characters)
   * @param sTxParams2 - Additional parameters related to entity 2 (máx 255 characters)
   * @throws SecurityException if there aren't sufficient permissions for writting at javatrc.txt file
   */
  public static void log (short iIdEntity, String sCoOp, String sGUUser, String sGUEntity1, String sGUEntity2, int iIdTransact, String sIPAddr, String sTxParams1, String sTxParams2) {

    writeLog (iIdEntity, sCoOp, sGUUser, sGUEntity1, sGUEntity2, iIdTransact, sIPAddr, sTxParams1, sTxParams2);
  } // log()

  // ----------------------------------------------------------

  /**
   * Set path to log output file
   * @param sFilePath Physical file path
   * @throws IOException
   */
  public static void setAuditFile(String sFilePath) throws IOException {
    if (sAuditFile!="") oLogWriter.close();
    sAuditFile = "";
    oLogWriter = new FileWriter(sFilePath, true);
    sAuditFile = sFilePath;
  } // setAuditFile

  // ----------------------------------------------------------

  /**
   * Write an operation line to the log file
   * @param sTransactId Transaction Identifier
   * @param sUserId GUID of user performing the operation (máx. 32 characters)
   * @param sObject GUID of primary entity for the operation
   * @param sOpCode Operation code (máx. 4 characters)
   * @param sParams Aditional parameters related to entity 1 (máx 255 characters)
   * @throws SecurityException if there aren't sufficient permissions for writting at javatrc.txt file
   */
  private static void writeLog (short iIdEntity, String sCoOp, String sUserId, String sGUEntity1, String sGUEntity2, int iIdTransact, String sIPAddr, String sTxParams1, String sTxParams2)
    throws SecurityException {
    try {
      if (null==oLogWriter)
        if (sOSName.startsWith("Windows"))
          setAuditFile("C:\\javaudit.txt");
        else
          setAuditFile("/tmp/javaudit.txt");

      oLogWriter.write (new java.util.Date().toString() + ";" + String.valueOf(iIdEntity) + ";" + sCoOp + ";" + sUserId + ";" + sGUEntity1 + ";" + sGUEntity2 + ";" + String.valueOf(iIdTransact) + ";" + sIPAddr + ";" + sTxParams1 + ";" + sTxParams2 + "\n");

    }
    catch (IOException ioe) { }
    catch (NullPointerException npe) {}

  } // writeLog()

  // ----------------------------------------------------------

  public static String analyze(String sFile) throws IOException {

    int f, s;
    StringBuffer oReport = new StringBuffer(4096);
    String sLine, sOpCode = null, sEntity = null;

    TreeMap oOpen  = new TreeMap();
    Integer oCount;


    FileReader oReader = new FileReader(sFile);
    BufferedReader oBuffer = new BufferedReader(oReader);
    LineNumberReader oLines = new LineNumberReader(oBuffer);

    while ((sLine = oLines.readLine())!=null) {
      f = 0;
      s = -1;
      while ((s=sLine.indexOf(';',s+1))!=-1) {
        f++;
        switch (f) {
          case 2:
            sOpCode = sLine.substring(s, sLine.indexOf(';', s+1));
            break;
          case 4:
            sEntity = sLine.substring(s, sLine.indexOf(';', s+1));

            if (sOpCode.equals("ODBC") || sOpCode.equals("OJSP")) {
              oCount = (Integer) oOpen.get(sEntity);
              if (oCount==null) {
                oCount = new Integer(1);
                oOpen.put(sEntity, oCount);
              }
              else {
                oCount = new Integer(oCount.intValue()+1);
                oOpen.remove(sEntity);
                oOpen.put(sEntity, oCount);
              }
            } // fi (sOpCode==ODBC)
            else if (sOpCode.equals("CDBC") || sOpCode.equals("CJSP")) {
              oCount = (Integer) oOpen.get(sEntity);
              if (oCount==null) {
                oCount = new Integer(-1);
                oOpen.put(sEntity, oCount);
              }
              else {
                oCount = new Integer(oCount.intValue()-1);
                oOpen.remove(sEntity);
                oOpen.put(sEntity, oCount);
              }
            }
            break;
        } // switch(f)
      } // wend
      if (f%10==0) System.out.print('.');
    } // wend

    System.out.print("\n");

    oReader.close();
    oLines.close();
    oBuffer.close();

    Iterator oKeys = oOpen.keySet().iterator();

    while (oKeys.hasNext()) {
      sEntity = (String) oKeys.next();
      oCount = (Integer) oOpen.get(sEntity);

      if (oCount.intValue()!=0) {
        oReport.append(sEntity + " open/close mismatch " + oCount.toString() + "\n");
      }
    } // wend

    return oReport.toString();
  }

  // ----------------------------------------------------------

  private static void printUsage() {
    System.out.println("");
    System.out.println("Usage:\n");
    System.out.println("DBAudit analyze <file_path>");
  }

  public static void main(String[] argv) throws IOException {

    if (argv.length<2)
      printUsage();
    else if (!argv[0].equals("analyze"))
      printUsage();
    else
      System.out.print(DBAudit.analyze(argv[1]));

  }
  // ----------------------------------------------------------

  private static String sOSName = System.getProperty("os.name");

  private static String sAuditFile = "";

  private static FileWriter oLogWriter = null;

} // DBAudit
