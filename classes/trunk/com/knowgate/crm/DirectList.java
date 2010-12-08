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

package com.knowgate.crm;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.UnsupportedEncodingException;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.CSVParser;
import com.knowgate.dataobjs.DB;

/**
 * <p>DirectList</p>
 * <p>A subclass of DistributionList with methods for loading List Members from
 * text files.</p>
 * <p>Copyright: Copyright (c) KnowGate 2003-2010</p>
 * @author Sergio Montoro Ten
 * @version 6.0
 */

public class DirectList extends DistributionList {

  private CSVParser oCSV;

  // ----------------------------------------------------------

  /**
   * Default constructor
   */
  public DirectList() {
    oCSV = new CSVParser();
  }

  // ----------------------------------------------------------

  /**
   * Constructor
   * @param String Name of character set to be used when parsing files (ISO-8859-1, UTF-8, etc.)
   * @since 3.0
   */
  public DirectList(String sCharSetName) {
    oCSV = new CSVParser(sCharSetName);
  }

  // ----------------------------------------------------------

  /**
   * Get last error line
   * @return int
   */
  public int errorLine() {
    return oCSV.errorLine();
  }

  // ----------------------------------------------------------

  /**
   * Get line count after parsing a text file
   * @return int
   */
  public int getLineCount() {
    return oCSV.getLineCount();
  }

  // ----------------------------------------------------------

  private int[] checkValues() throws IllegalStateException {

    String sMail, sName, sSurN, sSalt, sFrmt, sPhne, sInfo;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DirectList.checkValues()");
      DebugFile.incIdent();
    }

    if (0 == oCSV.getLineCount())
      throw new IllegalStateException("Trying to parse an empty file");

    int iMail = getColumnPosition(DB.tx_email);
    int iName = getColumnPosition(DB.tx_name);
    int iSurN = getColumnPosition(DB.tx_surname);
    int iSalt = getColumnPosition(DB.tx_salutation);
    int iFrmt = getColumnPosition(DB.id_format);
    int iPhne = getColumnPosition(DB.mov_phone);
    int iInfo = getColumnPosition(DB.tx_info);

    int CheckCodes[]  = new int[oCSV.getLineCount()];

    int iLines = oCSV.getLineCount();

    for (int r=0; r<iLines; r++) {
      CheckCodes[r] = CHECK_OK;

      if (iMail>=0) {
        sMail = getField(iMail, r);
        if (sMail.length()>100)
          CheckCodes[r] = CHECK_INVALID_EMAIL;
        else if (!Gadgets.checkEMail(sMail))
          CheckCodes[r] = CHECK_INVALID_EMAIL;
      }

      if (iName>=0) {
        sName = getField(iName, r);
        if (sName.length()>100)
          CheckCodes[r] = CHECK_NAME_TOO_LONG;
        else if (sName.indexOf(',')>=0 || sName.indexOf(';')>=0 || sName.indexOf('`')>=0 || sName.indexOf('¨')>=0 || sName.indexOf('?')>=0 || sName.indexOf('"')>=0)
          CheckCodes[r] = CHECK_INVALID_NAME;
      }

      if (iSurN>=0) {
        sSurN = getField(iName, r);
        if (sSurN.length()>100)
          CheckCodes[r] = CHECK_SURNAME_TOO_LONG;
        else if (sSurN.indexOf(',')>=0 || sSurN.indexOf(';')>=0 || sSurN.indexOf('`')>=0 || sSurN.indexOf('¨')>=0 || sSurN.indexOf('?')>=0 || sSurN.indexOf('"')>=0)
          CheckCodes[r] = CHECK_INVALID_SURNAME;
      }

      if (iSalt>=0) {
        sSalt = getField(iSalt, r);
        if (sSalt.length()>16)
          CheckCodes[r] = CHECK_SALUTATION_TOO_LONG;
        else if (sSalt.indexOf(',')>=0 || sSalt.indexOf(';')>=0 || sSalt.indexOf('`')>=0 || sSalt.indexOf('¨')>=0 || sSalt.indexOf('?')>=0 || sSalt.indexOf('"')>=0)
          CheckCodes[r] = CHECK_INVALID_SALUTATION;
      }

      if (iFrmt>=0) {
        sFrmt = getField(iFrmt, r);
        if (sFrmt.length()>4)
          CheckCodes[r] = CHECK_INVALID_FORMAT;
        else if (sFrmt.indexOf(',')>=0 || sFrmt.indexOf(';')>=0 || sFrmt.indexOf('`')>=0 || sFrmt.indexOf('¨')>=0 || sFrmt.indexOf('?')>=0 || sFrmt.indexOf('"')>=0)
          CheckCodes[r] = CHECK_INVALID_SALUTATION;
      }

      if (iPhne>=0) {
        sPhne = getField(iPhne, r);
        if (sPhne.length()>16)
          CheckCodes[r] = CHECK_INVALID_MOBILE;
      }

      if (iInfo>=0) {
        sInfo = getField(iInfo, r);
        if (sInfo.length()>254)
          CheckCodes[r] = CHECK_INVALID_INFO;
      }

    } // next

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DirectList.checkValues()");
    }

    return CheckCodes;
  } // checkValues

  // ----------------------------------------------------------

  /**
   * Parse a delimited text file
   * @param sFilePath File Path
   * @param sFileDescriptor Delimited Column List.<br>
   * The only valid column names are { tx_email, tx_name, tx_surname, id_format, tx_salutation, mov_phone, tx_info }.<br>
   * Column names may be delimited by ',' ';' or '\t'.
   * Columns names may be quoted.
   * @return Array of status for each parsed line.<br>
   * <table><tr><td>CHECK_OK</td><td>Line is OK</td></tr>
   * <tr><td>CHECK_INVALID_EMAIL</td><td>tx_email is longer than 100 characters or it is rejected by method Gadgets.checkEMail()</td></tr>
   * <tr><td>CHECK_NAME_TOO_LONG</td><td>tx_name is longer than 100 characters</td></tr>
   * <tr><td>CHECK_INVALID_NAME</td><td>tx_name contains forbidden characters { ',' ';' '`' '¨' '?' '"' }</td></tr>
   * <tr><td>CHECK_SURNAME_TOO_LONG</td><td>tx_surname is longer than 100 characters</td></tr>
   * <tr><td>CHECK_INVALID_SURNAME</td><td>tx_surname contains forbidden characters { ',' ';' '`' '¨' '?' '"' }</td></tr>
   * <tr><td>CHECK_INVALID_FORMAT</td><td>id_format is longer than 4 characters</td></tr>
   * <tr><td>CHECK_SALUTATION_TOO_LONG</td><td>tx_salutation is longer than 16 characters</td></tr>
   * <tr><td>CHECK_INVALID_SALUTATION</td><td>tx_salutation contains forbidden characters { ',' ';' '`' '¨' '?' '"' }</td></tr>
   * </table>
   * @throws ArrayIndexOutOfBoundsException
   * @throws FileNotFoundException
   * @throws IllegalArgumentException
   * @throws IOException
   * @throws NullPointerException
   * @throws UnsupportedEncodingException
   * @see com.knowgate.misc.CSVParser
   */
  public int[] parseFile(String sFilePath, String sFileDescriptor)
      throws ArrayIndexOutOfBoundsException,NullPointerException,
             IllegalArgumentException,UnsupportedEncodingException,
             IOException,FileNotFoundException {
    int[] aRetVals;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DirectList.parseFile(" + sFilePath + "," + sFileDescriptor + "," + ")");
      DebugFile.incIdent();
    }

    oCSV.parseFile(sFilePath, sFileDescriptor);

    aRetVals = checkValues();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DirectList.parseFile()");
    }

    return aRetVals;
  } // parseFile

  // ----------------------------------------------------------

  /**
   * @param sColumnName Column Name
   * @return Zero based index for column position or -1 if column was not found.
   */
  public int getColumnPosition(String sColumnName) {
    return oCSV.getColumnPosition(sColumnName);
  } // getColumnPosition

  // ----------------------------------------------------------

  /**
   * <p>Get line from a parsed file.</p>
   * Lines are delimited by the Line Feed (LF, CHAR(10), '\n') character
   * @param iLine Line Number [0..getLineCount()-1]
   * @return Full Text for Line. If iLine<0 or iLine>=getLineCount() then <b>null</b>
   * @throws IllegalStateException If parseFile() has not been called prior to getLine()
   */
  public String getLine(int iLine) throws IllegalStateException {
    String sRetVal;

    try {
      sRetVal = oCSV.getLine(iLine);
    } catch (java.io.UnsupportedEncodingException e) { sRetVal = null; }

    return sRetVal;
  } // getLine

  // ----------------------------------------------------------

  /**
   * <p>Get value for a field at a given row and column.</p>
   * Column indexes are zero based.
   * Row indexes range from 0 to getLineCount()-1.
   * @param iCol Column Index
   * @param iRow Row Index
   * @return Field Value
   * @throws IllegalStateException If parseFile() method was not called prior to
   * getField()
   * @throws ArrayIndexOutOfBoundsException If Column or Row Index is out of bounds.
   */

  public String getField(int iCol, int iRow) throws ArrayIndexOutOfBoundsException {
    String sRetVal;

    try {
      sRetVal = oCSV.getField(iCol, iRow);
    } catch (java.io.UnsupportedEncodingException e) { sRetVal = null; }

    return sRetVal;
  } // getField

  // ----------------------------------------------------------

  /**
   * <p>Get value for a field at a given row and column.</p>
   * @param sCol Column Name
   * @param iRow Row Name
   * @throws ArrayIndexOutOfBoundsException
   */
  public String getField(String sCol, int iRow) throws ArrayIndexOutOfBoundsException {

    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    return getField(iCol, iRow);
  }

  // ----------------------------------------------------------

  /**
   * <p>Adds members to a Static, Direct or Black Distribution List.</p>
   * @param oConn Database connection
   * @param sListId DistributionList GUID
   * @param iStatus 1 if loaded members are to be set as active, 0 if loaded member are to be set as unactive.
   * @throws IllegalArgumentException If DistributionList does not exist.
   * @throws ClassCastException If sListId type is DYNAMIC.
   * @throws IllegalStateException If parseFile() has not been called prior to updateList()
   * @throws StringIndexOutOfBoundsException If a row if malformed
   * @throws SQLException
   */
  public void updateList(Connection oConn, String sListId, short iStatus) throws IllegalArgumentException,IllegalStateException,ClassCastException,SQLException {
    Statement oStmt;
    ResultSet oRSet;
    boolean bExists;
    short iTpList;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DirectList.updateList([Connection], "  + sListId + ")");
      DebugFile.incIdent();
    }

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oRSet = oStmt.executeQuery("SELECT " + DB.tp_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_list + "='" + sListId + "'");
    bExists = oRSet.next();
    if (bExists)
      iTpList = oRSet.getShort(1);
    else
      iTpList = -1;
    oRSet.close();
    oStmt.close();

    if (!bExists)
      throw new IllegalArgumentException("List does not exist");

    if (iTpList==com.knowgate.crm.DistributionList.TYPE_DYNAMIC)
      throw new IllegalArgumentException("Dynamic lists cannot be updated by directly loading members");

    if (0 == oCSV.getLineCount())
      throw new IllegalStateException("Must call parseFile() on a valid non-empty delimited file before calling updateList() method");

    int iMail = getColumnPosition(DB.tx_email);
    int iName = getColumnPosition(DB.tx_name);
    int iSurN = getColumnPosition(DB.tx_surname);
    int iSalt = getColumnPosition(DB.tx_salutation);
    int iFrmt = getColumnPosition(DB.id_format);
    int iPhne = getColumnPosition(DB.mov_phone);
    int iInfo = getColumnPosition(DB.tx_info);

    int ChkCods[] = checkValues();

	boolean bHasPhone=false, bHasInfo=false;
	Statement oMdt = oConn.createStatement();
	ResultSet oRdt = oMdt.executeQuery("SELECT * FROM "+DB.k_x_list_members+" WHERE 1=0");
	ResultSetMetaData oRmd = oRdt.getMetaData();
	if (DebugFile.trace) DebugFile.writeln("Checking presence of columns "+DB.mov_phone+" and "+DB.tx_info);
	for (int c=1; c<=oRmd.getColumnCount(); c++) {
	  if (DebugFile.trace) DebugFile.writeln("  checking "+oRmd.getColumnName(c));
	  if (oRmd.getColumnName(c).equalsIgnoreCase(DB.mov_phone)) bHasPhone=true;
	  if (oRmd.getColumnName(c).equalsIgnoreCase(DB.tx_info)) bHasInfo=true;
	}
	oRdt.close();
	oMdt.close();

	PreparedStatement oMbr = oConn.prepareStatement("INSERT INTO "+DB.k_list_members+" (gu_member,tx_email,tx_name,tx_surname,tx_salutation) VALUES (?,?,?,?,?)");

	String sSQL = "INSERT INTO "+DB.k_x_list_members+"("+DB.gu_list+","+DB.tp_member+","+DB.bo_active+","+DB.tx_email+","+DB.tx_name+","+DB.tx_surname+","+DB.tx_salutation+","+DB.id_format+(bHasPhone ? ","+DB.mov_phone : "")+(bHasInfo ? ","+DB.tx_info : "")+") VALUES (?,?,?,?,?,?,?,?"+(bHasPhone ? ",?": "")+(bHasInfo ? ",?" : "")+")";

    if (DebugFile.trace) DebugFile.writeln("JDCConnection.prepareStatement("+sSQL+")");

	PreparedStatement oIns = oConn.prepareStatement(sSQL);
	
    int iLines = oCSV.getLineCount();

    for (int r=0; r<iLines; r++) {
      if (ChkCods[r] == CHECK_OK) {
		oMbr.setString(1, Gadgets.generateUUID());
		oMbr.setString(2, getField(iMail, r));
		oMbr.setString(3, getField(iName, r));
		oMbr.setString(4, getField(iSurN, r));
		oMbr.setString(5, getField(iSalt, r));
        
        try {
		  oMbr.executeUpdate();
        }
        catch (SQLException sqle) {
          if (DebugFile.trace) {
            DebugFile.writeln("SQLException whilst inserting line "+String.valueOf(r+1)+" "+getField(iMail, r)+" at "+DB.k_list_members+" "+sqle.getMessage());
          }
          oMbr.close();
          oMbr = oConn.prepareStatement("INSERT INTO "+DB.k_list_members+" (gu_member,tx_email,tx_name,tx_surname,tx_salutation) VALUES (?,?,?,?,?)");
        }

		
	  	int c = 0;
	    oIns.setString(++c, sListId);
	    oIns.setShort (++c, DirectList.ClassId);
	    oIns.setShort (++c, iStatus);
		oIns.setString(++c, getField(iMail, r));
		oIns.setString(++c, getField(iName, r));
		oIns.setString(++c, getField(iSurN, r));
		oIns.setString(++c, getField(iSalt, r));
	    
        if (iFrmt>=0)
		  oIns.setString(++c, getField(iFrmt, r).toUpperCase());
        else
		  oIns.setString(++c, "TXT");

		if (bHasPhone)
		  oIns.setString(++c, getField(iPhne, r));

		if (bHasInfo)
		  oIns.setString(++c, getField(iInfo, r));
			
        try {
		  oIns.executeUpdate();
        }
        catch (SQLException sqle) {
          if (DebugFile.trace) {
            DebugFile.writeln("SQLException whilst inserting line "+String.valueOf(r+1)+" "+getField(iMail, r)+" at "+DB.k_x_list_members+" "+sqle.getMessage());
          }
          oIns.close();
          oIns = oConn.prepareStatement(sSQL);
        }
      } else {
        if (DebugFile.trace) {
          DebugFile.writeln("Skipped line "+String.valueOf(r+1)+" "+getField(iMail, r)+" error code is "+String.valueOf(ChkCods[r]));
        }
      }
    } // next

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DirectList.updateList()");
    }
  } // updateList


  // ----------------------------------------------------------

  /**
   * <p>Remove members from a Static, Direct or Black Distribution List.</p>
   * Members are matched by their e-mail address (tx_email column)
   * @param oConn Database connection
   * @param sListId DistributionList GUID
   * @throws IllegalArgumentException If DistributionList does not exist.
   * @throws ClassCastException If sListId type is DYNAMIC
   * @throws IllegalStateException If parseFile() has not been called prior to updateList()
   * @throws SQLException
   */
  public void removeFromList(JDCConnection oConn, String sListId) throws IllegalArgumentException,SQLException,ClassCastException {
    Statement oDlte;
    Statement oStmt;
    ResultSet oRSet;
    boolean bExists;
    short iTpList;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DirectList.removeFromList([Connection], "  + sListId + ")");
      DebugFile.incIdent();
    }

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oRSet = oStmt.executeQuery("SELECT " + DB.tp_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_list + "='" + sListId + "'");
    bExists = oRSet.next();
    if (bExists)
      iTpList = oRSet.getShort(1);
    else
      iTpList = -1;
    oRSet.close();
    oStmt.close();

    if (!bExists)
      throw new IllegalArgumentException("List does not exist");

    if (iTpList==com.knowgate.crm.DistributionList.TYPE_DYNAMIC)
      throw new ClassCastException("Dynamic lists cannot be updated by directly removing members");

    if (0 == oCSV.getLineCount())
      throw new IllegalStateException("Must call parseFile() on a valid non-empty delimited file before calling updateList() method");

    int iMail = getColumnPosition(DB.tx_email);

    int ChkCods[] = checkValues();

    int iLines = oCSV.getLineCount();

    sSQL = "DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + sListId + "' AND " + DB.tx_email + "=";

    oDlte = oConn.createStatement();

    for (int r=0; r<iLines; r++) {
      if (ChkCods[r] == CHECK_OK)
        oDlte.addBatch(sSQL + "'" + getField(iMail, r) + "'");
    } // next

    oDlte.executeBatch();
    oDlte.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DirectList.removeFromList()");
    }
  } // removeFromList

  // ----------------------------------------------------------

  // **********************************************************
  // Constantes Publicas

  public static final int CHECK_OK = 0;
  public static final int CHECK_INVALID_EMAIL = 1;
  public static final int CHECK_NAME_TOO_LONG = 2;
  public static final int CHECK_SURNAME_TOO_LONG = 4;
  public static final int CHECK_INVALID_FORMAT = 8;
  public static final int CHECK_SALUTATION_TOO_LONG = 16;
  public static final int CHECK_INVALID_NAME = 32;
  public static final int CHECK_INVALID_SURNAME = 64;
  public static final int CHECK_INVALID_SALUTATION = 128;
  public static final int CHECK_INVALID_MOBILE = 256;
  public static final int CHECK_INVALID_INFO = 512;

  // **********************************************************
  // Public Constants

  public static final short ClassId = 96;

}
