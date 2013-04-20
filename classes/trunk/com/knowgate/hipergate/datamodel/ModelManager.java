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

package com.knowgate.hipergate.datamodel;

import java.io.UnsupportedEncodingException;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.SQLException;
import java.sql.DriverManager;
import java.sql.CallableStatement;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Types;

import java.text.ParseException;

import java.util.Properties;
import java.util.LinkedList;
import java.util.ListIterator;

import bsh.Interpreter;
import bsh.EvalError;

import com.knowgate.dataobjs.DBBind;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.CSVParser;
import com.knowgate.misc.Gadgets;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DBColumn;
import com.knowgate.datacopy.DataStruct;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.workareas.FileSystemWorkArea;

/**
 * <p>hipergate Data Model Manager</p>
 * <p>This class is used for programatically creating the full underlying
 * data model for hipergate Java packages.</p>
 * <p>It may be used as an alternative method to database dumps for initial data loading,
 * or, also, as a tool for porting the data model to a new DBMS in a structured way.</p>
 * @author Sergio Montoro ten
 * @version 7.0
 */

public class ModelManager {

  private static final String VERSION = "7.0.0";

  private static final int BULK_PROCEDURES = 1;
  private static final int BULK_STATEMENTS = 2;
  private static final int BULK_BATCH = 3;
  private static final int BULK_PLSQL = 4;
  private static final int FILE_STATEMENTS = 5;

  private static final int DBMS_MYSQL = 1;
  private static final int DBMS_POSTGRESQL = 2;
  private static final int DBMS_MSSQL = 3;
  private static final int DBMS_ORACLE = 5;
  private static final int DBMS_DB2 = 6;

  private static final String CURRENT_TIMESTAMP = "CURRENT_TIMESTAMP";
  private static final int CURRENT_TIMESTAMP_LEN = 17;

  private static final String DATETIME = "DATETIME";
  private static final int DATETIME_LEN = 8;

  private static final String LONGVARBINARY = "LONGVARBINARY";
  private static final int LONGVARBINARY_LEN = 13;

  private static final String LONGVARCHAR = "LONGVARCHAR";
  private static final int LONGVARCHAR_LEN = 11;

  private static final String FLOAT_NUMBER = "FLOAT";
  private static final int FLOAT_NUMBER_LEN = 5;

  private static final String NUMBER_6 = "SMALLINT";
  private static final int NUMBER_6_LEN = 8;

  private static final String NUMBER_11 = "INTEGER";
  private static final int NUMBER_11_LEN = 7;

  private static final String CHARACTER_VARYING = "VARCHAR";
  private static final int CHARACTER_VARYING_LEN = 7;

  private static final String SERIAL = "SERIAL";
  private static final int SERIAL_LEN = 6;

  private static final String CHAR_LENGTH = "LENGTH(";
  private static final int CHAR_LENGTH_LEN = 7;

  private static final String BLOB = "BLOB";
  private static final int BLOB_LEN = 4;

  private static final String CLOB = "CLOB";
  private static final int CLOB_LEN = 4;

  private static final String CurrentTimeStamp[] = { null, "CURRENT_TIMESTAMP", "CURRENT_TIMESTAMP", "GETDATE()", null, "SYSDATE" };
  private static final String DateTime[] = { null, "TIMESTAMP", "TIMESTAMP", "DATETIME", null, "DATE" };
  private static final String LongVarChar[] = { null, "MEDIUMTEXT", "TEXT", "NTEXT", null, "LONG" };
  private static final String LongVarBinary[] = { null, "MEDIUMBLOB", "BYTEA", "IMAGE", null, "LONG RAW" };
  private static final String CharLength[] = { null, "CHAR_LENGTH(", "char_length(", "LEN(", null, "LENGTH(" };
  private static final String Serial[] = { null, "INTEGER NOT NULL AUTO_INCREMENT", "SERIAL", "INTEGER IDENTITY", null, "NUMBER(11)" };
  private static final String VarChar[] = { null, "VARCHAR", "VARCHAR", "NVARCHAR", null, "VARCHAR2" };
  private static final String Blob[] = { null, "MEDIUMBLOB", "BYTEA", "IMAGE", null, "BLOB" };
  private static final String Clob[] = { null, "MEDIUMTEXT", "TEXT", "NTEXT", null, "CLOB" };

  private boolean bStopOnError;
  private Connection oConn;
  private String sDbms;
  private String sSchema;
  private int iDbms;
  private int iErrors;
  private StringBuffer oStrLog;
  private String sEncoding;
  private boolean bASCII;

  // ---------------------------------------------------------------------------

  private class Constraint {
    public String constraintname;
    public String tablename;

    public Constraint(String sConstraintName, String sTableName) {
      constraintname = sConstraintName;
      tablename = sTableName;
    }
  }

  // ---------------------------------------------------------------------------

  public ModelManager() {

    if (DebugFile.trace) {
      DebugFile.writeln("hipergate ModelManager build " + VERSION);
      DebugFile.envinfo();
    }

    iDbms = 0;
    sDbms = null;
    oConn = null;
    oStrLog = null;
    bStopOnError = false;
    sEncoding = "UTF-8";
    bASCII = false;
  }

  // ---------------------------------------------------------------------------

  public void activateLog(boolean bActivate) {
    oStrLog = (bActivate ? new StringBuffer() : null);      
  }

  // ---------------------------------------------------------------------------

  public String getEncoding () {
    return sEncoding;
  }

  public void setEncoding (String sCharset) {
    sEncoding = sCharset;
  }

  /**
   * <p>Set whether or not create() and drop() methods should stop on error</p>
   * @param bStop <b>true</b>=stop on error, <b>false</b>=don not stop
   */
  public void stopOnError(boolean bStop) {
    bStopOnError = bStop;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get whether or not create() and drop() methods will stop on error</p>
   * @return bStop <b>true</b>=stop on error, <b>false</b>=don not stop
   */
  public boolean stopOnError() {
    return bStopOnError;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Connect to database</p>
   * Connection autocommit is set to ON.
   * @param sDriver JDBC driver class name
   * @param sUrl Database URL
   * @param sUsr Database User
   * @param sPwd Database Password
   * @throws SQLException
   * @throws ClassNotFoundException If class for JDBC driver is not found
   * @throws IllegalStateException If already connected to database
   * @throws UnsupportedOperationException If DBMS is not recognized,
   * currently only Oracle, Microsoft SQL Server and PostgreSQL are recognized.
   */
  public void connect(String sDriver, String sUrl, String sSch, String sUsr, String sPwd)
    throws SQLException, ClassNotFoundException, IllegalStateException,
           UnsupportedOperationException {

    if (DebugFile.trace) {
     DebugFile.writeln("Begin ModelManager.connect(" + sDriver + "," + sUrl + ", ...)");
     DebugFile.incIdent();
    }

    if (null!=oConn)
      throw new IllegalStateException("already connected to database");

    Connection oNewConn;
    Class oDriver = Class.forName(sDriver);

    oNewConn = DriverManager.getConnection(sUrl, sUsr, sPwd);
    oNewConn.setAutoCommit(true);

    setConnection(oNewConn);

    sSchema = sSch;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.connect()");
    }

  } // connect

  // ---------------------------------------------------------------------------

  /**
   * <p>Disconnect from database</p>
   * @throws SQLException
   */
  public void disconnect() throws SQLException {

    if (DebugFile.trace) {
     DebugFile.writeln("Begin ModelManager.disconnect()");
     DebugFile.incIdent();
    }

    if (null!=oConn) {
      if (!oConn.isClosed()) {
        oConn.close();
        sDbms = null;
      } // fi (!isClosed())
    } // fi (oConn)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.disconnect()");
    }
  } // disconnect

  // ---------------------------------------------------------------------------

  /**
   * <p>Assign an external conenction to ModelManager</p>
   * Use this method when ModelManager must not connect itself to database but
   * reuse an already existing connection.
   * @param oJDBCConn Database Connection
   * @throws SQLException
   * @throws UnsupportedOperationException If DBMS is not recognized
   * @throws NullPointerException if oJDBCConn is <b>null</b>
   */
  public void setConnection(Connection oJDBCConn)
      throws SQLException,UnsupportedOperationException,NullPointerException {

    if (DebugFile.trace) {
     DebugFile.writeln("Begin ModelManager.setConnection([Connection])");
     DebugFile.incIdent();
    }

    if (null==oJDBCConn) throw new NullPointerException("Connection parameter may not be null");

    oConn = oJDBCConn;

    DatabaseMetaData oMDat = oConn.getMetaData();
    String sDatabaseProductName = oMDat.getDatabaseProductName();

    if (sDatabaseProductName.equals("Microsoft SQL Server")) {
      sDbms = "mssql";
      iDbms = DBMS_MSSQL;
    }
    else if (sDatabaseProductName.equals("PostgreSQL")) {
      sDbms = "postgresql";
      iDbms = DBMS_POSTGRESQL;
    }
    else if (sDatabaseProductName.equals("Oracle")) {
      sDbms = "oracle";
      iDbms = DBMS_ORACLE;
    }
    else if (sDatabaseProductName.startsWith("DB2")) {
      sDbms = "db2";
      iDbms = DBMS_DB2;
    }
    else if (sDatabaseProductName.startsWith("MySQL")) {
      sDbms = "mysql";
      iDbms = DBMS_MYSQL;
    }
    else {
      sDbms = oMDat.getDatabaseProductName().toLowerCase();
      iDbms = 0;
    }
    oMDat = null;

    if (0==iDbms) {
      oConn.close();
      oConn = null;
      throw new UnsupportedOperationException("DataBase Management System not supported");
    }

    oStrLog = new StringBuffer();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.setConnection()");
    }
  } // setConnection()

  // ---------------------------------------------------------------------------

  /**
   * Clear internal operation log
   */
  public void clear() {
    if (null!=oStrLog) oStrLog.setLength(0);
  }

  // ---------------------------------------------------------------------------

  /**
   * Get reference to opened database connection
   */
  public Connection getConnection() {
    return oConn;
  }

  // ---------------------------------------------------------------------------

  /**
   * Print internal operation log to a String
   */
  public String report() {
    String sRep;

    if (null!=oStrLog)
      sRep = oStrLog.toString();
    else
      sRep = "";

    return sRep;
  } // report

  // ---------------------------------------------------------------------------

  /**
   * <p>Translate SQL statement for a particular DBMS</p>
   * @param sSQL SQL to be translated
   * @throws NullPointerException if sSQL is <b>null</b>
   * @return SQL statement translated for the active DBMS
   */
  public String translate(String sSQL)
    throws NullPointerException {

	String sRetSql;
	
    if (DebugFile.trace) {
     DebugFile.writeln("Begin ModelManager.translate(" + sSQL + ")");
     DebugFile.incIdent();
    }

    if (null==sSQL) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("Sentence to translate may not be null");
    }

    final int iLen = sSQL.length();

    if (iLen<=0) {
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ModelManager.translate()");
      }
      sRetSql = "";
    }
    else {
      int iPos, iOff;
      boolean bMatch;

      StringBuffer oTrn = new StringBuffer(iLen);

      for (int p=0; p<iLen; p++) {

        bMatch = true;
        for (iPos=0, iOff=p; iPos<CURRENT_TIMESTAMP_LEN && iOff<iLen && bMatch; iOff++, iPos++)
          bMatch = (sSQL.charAt(iOff) == CURRENT_TIMESTAMP.charAt(iPos));

        if (bMatch) {

          oTrn.append(CurrentTimeStamp[iDbms]);
          p += CURRENT_TIMESTAMP_LEN-1;
        }
        else {

          bMatch = true;
          for (iPos=0, iOff=p; iPos<DATETIME_LEN && iOff<iLen && bMatch; iOff++, iPos++)
            bMatch = (sSQL.charAt(iOff) == DATETIME.charAt(iPos));

          if (bMatch) {

            oTrn.append(DateTime[iDbms]);
            p += DATETIME_LEN-1;
          }
          else {

            if (p>0)
              bMatch = sSQL.charAt(p-1)!='N';
            else
              bMatch = true;

            for (iPos=0, iOff=p; iPos<CHARACTER_VARYING_LEN && iOff<iLen && bMatch; iOff++, iPos++)
              bMatch &= (sSQL.charAt(iOff) == CHARACTER_VARYING.charAt(iPos));

            if (bMatch) {

              oTrn.append(VarChar[iDbms]);
              p += CHARACTER_VARYING_LEN-1;
            }
            else {

              bMatch = true;
              for (iPos=0, iOff=p; iPos<LONGVARCHAR_LEN && iOff<iLen && bMatch; iOff++, iPos++)
                bMatch = (sSQL.charAt(iOff) == LONGVARCHAR.charAt(iPos));

              if (bMatch) {

                oTrn.append(LongVarChar[iDbms]);
                p += LONGVARCHAR_LEN-1;
              }
              else {

                bMatch = true;
                for (iPos=0, iOff=p; iPos<LONGVARBINARY_LEN && iOff<iLen && bMatch; iOff++, iPos++)
                  bMatch = sSQL.charAt(iOff) == LONGVARBINARY.charAt(iPos);

                if (bMatch) {

                  oTrn.append(LongVarBinary[iDbms]);
                  p += LONGVARBINARY_LEN-1;
                }
                else {

                  bMatch = true;
                  for (iPos=0, iOff=p; iPos<CHAR_LENGTH_LEN && iOff<iLen && bMatch; iOff++, iPos++)
                    bMatch = sSQL.charAt(iOff) == CHAR_LENGTH.charAt(iPos);

                  if (bMatch) {

                    oTrn.append(CharLength[iDbms]);
                    p += CHAR_LENGTH_LEN-1;
                  }

                  else {
                    bMatch = true;
                    for (iPos = 0, iOff = p;
                         iPos < SERIAL_LEN && iOff < iLen && bMatch; iOff++, iPos++)
                      bMatch = sSQL.charAt(iOff) == SERIAL.charAt(iPos);

                    if (bMatch) {

                      oTrn.append(Serial[iDbms]);
                      p += SERIAL_LEN - 1;
                    }

                    else {

                      if (DBMS_ORACLE == iDbms) {

                        bMatch = true;
                        for (iPos = 0, iOff = p;
                             iPos < NUMBER_6_LEN && iOff < iLen && bMatch; iOff++,
                             iPos++)
                          bMatch = sSQL.charAt(iOff) == NUMBER_6.charAt(iPos);

                        if (bMatch) {

                          oTrn.append("NUMBER(6,0)");
                          p += NUMBER_6_LEN - 1;
                        }
                        else {

                          bMatch = true;
                          for (iPos = 0, iOff = p;
                               iPos < NUMBER_11_LEN && iOff < iLen && bMatch;
                               iOff++, iPos++)
                            bMatch = sSQL.charAt(iOff) == NUMBER_11.charAt(iPos);

                          if (bMatch) {

                            oTrn.append("NUMBER(11,0)");
                            p += NUMBER_11_LEN - 1;
                          }
                          else {

                            bMatch = true;
                            for (iPos = 0, iOff = p;
                                 iPos < FLOAT_NUMBER_LEN && iOff < iLen && bMatch;
                                 iOff++, iPos++)
                              bMatch = sSQL.charAt(iOff) ==
                                  FLOAT_NUMBER.charAt(iPos);

                            if (bMatch) {

                              oTrn.append("NUMBER");
                              p += FLOAT_NUMBER_LEN - 1;
                            }
                            else {
                              oTrn.append(sSQL.charAt(p));
                            }
                          } // // fi (NUMBER(11))

                        } // fi (NUMBER(6))

                      } // fi (DBMS_ORACLE)

                      else {

                        bMatch = true;
                        for (iPos = 0, iOff = p;
                             iPos < BLOB_LEN && iOff < iLen && bMatch; iOff++,
                             iPos++)
                          bMatch = sSQL.charAt(iOff) == BLOB.charAt(iPos);

                        if (bMatch) {
                          oTrn.append(Blob[iDbms]);
                          p += BLOB_LEN - 1;
                        }
                        else {
                          bMatch = true;
                          for (iPos = 0, iOff = p;
                               iPos < CLOB_LEN && iOff < iLen && bMatch; iOff++,
                               iPos++)
                            bMatch = sSQL.charAt(iOff) == CLOB.charAt(iPos);

                          if (bMatch) {
                            oTrn.append(Clob[iDbms]);
                            p += CLOB_LEN - 1;
                          }
                          else
                            oTrn.append(sSQL.charAt(p));
                        }
                      }
                    }
                  }
                } // fi (no matching translation found)
              }
            }
          }
        }
      } // next

      if (bASCII) {
        int iTrn = oTrn.length();
        StringBuffer oAsc = new StringBuffer(iTrn);
        char[] cTrn = new char[1];
        for (int i=0; i<iTrn; i++) {
          oTrn.getChars(i, i + 1, cTrn, 0);
          if ((int)cTrn[0] <= 255)
            oAsc.append(cTrn[0]);
          else
            oAsc.append('?');
        } // next
        sRetSql = oAsc.toString().replace((char)13, (char)32);
      }
      else {
        sRetSql = oTrn.toString().replace((char)13, (char)32);
      } // fi (iLen)
    }

	if (iDbms==DBMS_MYSQL) {

	  try {
	    sRetSql = Gadgets.replace(sRetSql, " DROP CONSTRAINT ", " DROP FOREIGN KEY ",
	                              org.apache.oro.text.regex.Perl5Compiler.CASE_INSENSITIVE_MASK);
	  } catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) { }

	  if (sRetSql.toUpperCase().startsWith("DROP INDEX ")) {
	  	int iDot = sRetSql.indexOf('.');
	  	if (iDot>0) {
	  	  sRetSql = "DROP INDEX "+sRetSql.substring(iDot+1)+" ON "+sRetSql.substring(11,iDot);
	  	}
	  }
	} // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.translate() :\n" + sRetSql + "\n");
    }
	return sRetSql;
  } // translate

  // ---------------------------------------------------------------------------

  private boolean isDoubleQuote(StringBuffer oBuffer, int iLen, int iPos) {
    if (iPos>=iLen-2)
      return false;
    else
      return (oBuffer.charAt(++iPos)==(char)39);    
  } // isDoubleQuote

  // ---------------------------------------------------------------------------

  private boolean switchQuoteActiveStatus (StringBuffer oBuffer, int iLen, char cAt, int iPos, boolean bActive) {
    boolean bRetVal;
    // If a single quote sign ' is found then switch ON or OFF the value of bActive
    if (cAt==39) {
      if (isDoubleQuote(oBuffer, iLen, iPos))
      	bRetVal = bActive;
      else
      	bRetVal = !bActive;
    } else {
      bRetVal = bActive;
    }// fi (cAt==')
    if (DebugFile.trace && bRetVal!=bActive) {
      String sLine = "";
      for (int l=iPos; l<iLen && oBuffer.charAt(l)>=32; l++) sLine += oBuffer.charAt(l);
	  DebugFile.writeln("switching quote status to "+String.valueOf(bRetVal)+" at character position " + String.valueOf(iPos)+ " near "+sLine);
    }
    return bRetVal;
  } // switchQuoteActiveStatus

  // ---------------------------------------------------------------------------
  
  private String[] split(StringBuffer oBuffer, char cDelimiter, String sGo) {

    // Fast String spliter routine specially tuned for SQL sentence batches
    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.split([StringBuffer], "+cDelimiter+", "+sGo+")");
      DebugFile.incIdent();
    }

    final int iLen = oBuffer.length();
    int iGo;

    if (null!=sGo)
      iGo = sGo.length();
    else
      iGo = 0;

    char cAt;

    // Initially bActive is set to true
    // bActive signals that the current status is sensitive
    // to statement delimiters.
    // When a single quote is found, bActive is set to false
    // and then found delimiters are ignored until another
    // matching closing quote is reached.
    boolean bActive = true;
    int iStatementsCount = 0;
    int iMark = 0, iTail = 0, iIndex = 0;

    // Scan de input buffer
    for (int c=0; c<iLen; c++) {
      cAt = oBuffer.charAt(c);
      
      if (iGo>0 && JDCConnection.DBMS_POSTGRESQL==iDbms) {
        bActive = switchQuoteActiveStatus(oBuffer, iLen, cAt, c, bActive);
        if (c<iLen-1) if ((cAt==(char)39) && (oBuffer.charAt(c+1)==(char)39)) c+=2;
      }

      // If the statement delimiter is found outside a quoted text then count a new line
      if (cAt==cDelimiter && bActive) {
        if (null==sGo) {
          iStatementsCount++;
        } else if (c>=iGo) {
          if (oBuffer.substring(c-iGo,c).equalsIgnoreCase(sGo)) {
            iStatementsCount++;
            if (DebugFile.trace) DebugFile.writeln("statement delimiter " + String.valueOf(iStatementsCount) + " found at character position "+c);
          }
        }
      } // fi (cAt==cDelimiter && bActive)
      // Skip any blank or non-printable characters after the end-of-statement marker
      for (iMark=c+1; iMark<iLen; iMark++)
        if (oBuffer.charAt(iMark)>32) break;
    } // next (c)

    String aArray[] = new String[iStatementsCount];
    iMark  = iTail = iIndex = 0;
    bActive = true;
    for (int c=0; c<iLen; c++) {
      cAt = oBuffer.charAt(c);

      if (iGo>0 && JDCConnection.DBMS_POSTGRESQL==iDbms) {
        bActive = switchQuoteActiveStatus(oBuffer, iLen, cAt, c, bActive);
        if (c<iLen-1) if ((cAt==(char)39) && (oBuffer.charAt(c+1)==(char)39)) c+=2;
      }

      // If reached and end-of-statement marker outside a quoted text
      // and either there is no "GO" marker
      // or the "GO" marker is just prior to the delimiter
      if ((cAt==cDelimiter && bActive) &&
    	  (null==sGo || (c>=iGo && oBuffer.substring(c-iGo,c).equalsIgnoreCase(sGo)))) {

    	// Scan backwards from the end-of-statement
        for ( iTail=c-1; iTail>0; iTail--) {
          // If there is no "GO" then just skip blank spaces between the end-of-statement marker
          // and the last printable character of the statement
          if (oBuffer.charAt(iTail)>32 && null==sGo)
            break;
          else
        	// Just step back the length of the "GO" marker and break
        	if (null!=sGo) {
              iTail -= iGo;
              break;
            }
        } // next

        try {
          // Assign the statement to an array line
          aArray[iIndex] = oBuffer.substring(iMark,iTail+1);
          iIndex++;
        } catch (ArrayIndexOutOfBoundsException aioobe) {
          String sXcptInfo = aioobe.getMessage()+" c="+String.valueOf(c)+" at="+cAt+" active="+String.valueOf(bActive)+" aArray.length="+String.valueOf(iStatementsCount)+" oBuffer.length="+String.valueOf(oBuffer.length())+" iIndex="+String.valueOf(iIndex)+" iMark="+String.valueOf(iMark)+" iTail="+String.valueOf(iTail);
          if (iIndex>0) sXcptInfo += " next to " + aArray[iIndex-1];
          throw new ArrayIndexOutOfBoundsException(sXcptInfo);
        }

        // Skip any blank or non-printable characters after the end-of-statement marker
        for (iMark=c+1; iMark<iLen; iMark++)
          if (oBuffer.charAt(iMark)>32) break;

      } // fi (found delimiter)
    } // next (c)

    if (iIndex<iStatementsCount-1 && iMark<iLen-1)
      aArray[iIndex] = oBuffer.substring(iMark);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.split() : "+String.valueOf(iStatementsCount));
    }

    return aArray;
  } // split

  // ---------------------------------------------------------------------------

  /**
   * Load a delimited text file into a database table
   * @param sTableName String Fully qualified table name
   * @param sFilePath String File Path
   * @param sEncoding String File Character encoding
   * @throws SQLException
   * @throws ParseException
   * @throws NumberFormatException
   * @throws IOException
   * @throws FileNotFoundException
   * @throws UnsupportedEncodingException
   * @since 6.0
   */
  public void bulkLoad (String sTableName, String sFilePath, String sEncoding)
  	throws SQLException,IOException,FileNotFoundException,UnsupportedEncodingException,
  	       NumberFormatException,ArrayIndexOutOfBoundsException,ParseException {

	int c;
	String f = "";
	ColumnList oColList = new ColumnList();
	
    PreparedStatement oStmt = getConnection().prepareStatement("SELECT * FROM "+sTableName);
    ResultSet oRSet = oStmt.executeQuery();
    int iFlags = oRSet.next() ? ImportLoader.MODE_APPENDUPDATE : ImportLoader.MODE_APPEND;
    ResultSetMetaData oMDat = oRSet.getMetaData();
    for (c=1; c<=oMDat.getColumnCount(); c++) {
      oColList.add(new DBColumn(sTableName, oMDat.getColumnName(c), (short) oMDat.getColumnType(c), oMDat.getColumnTypeName(c), oMDat.getPrecision(c), oMDat.getScale(c), oMDat.isNullable(c), c));    
    }
    oRSet.close();
    oStmt.close();

  	TableLoader oTblLdr = new TableLoader(sTableName);
  	oTblLdr.prepare(getConnection(),oColList);
  	String[] aColumns = oTblLdr.columnNames();

  	CSVParser oCsvPrsr = new CSVParser(sEncoding);
  	oCsvPrsr.parseFile(sFilePath, Gadgets.join(aColumns,"\t"));
  	final int nLines = oCsvPrsr.getLineCount();
  	final int nCols = oCsvPrsr.getColumnCount();

    getConnection().setAutoCommit(false);

    for (int l=0; l<nLines; l++) {
      c = -1;
      try {
        while (++c<nCols) {
          f = oCsvPrsr.getField(c,l);
          oTblLdr.put(c, f);
        } // wend   
        oTblLdr.store(getConnection(), "", iFlags);
        oTblLdr.setAllColumnsToNull();
    	getConnection().commit();
      } catch (Exception xcpt) {
        iErrors++;
        String sTrc = "";
        try { sTrc = com.knowgate.debug.StackTraceUtil.getStackTrace(xcpt); } catch (IOException ignore) {}
        if (null!=oStrLog) oStrLog.append(xcpt.getClass().getName()+" for value "+f+" at line " + String.valueOf(l+1) + " column "+String.valueOf(c+1)+" of type "+oColList.getColumn(c).getSqlTypeName()+": " + xcpt.getMessage() + "\t" + oCsvPrsr.getLine(l) + "\n" + sTrc);
    	getConnection().rollback();
        oTblLdr.setAllColumnsToNull();
        break;
      }
    } // next
    oTblLdr.close();
  } // bulkLoad

  // ---------------------------------------------------------------------------

  /**
   * Truncate table
   * @param sTableName String Table name
   * @throws SQLException
   * @since 6.0
   */

  public void truncate (String sTableName) throws SQLException {
    Statement oStmt = getConnection().createStatement();
    oStmt.execute("TRUNCATE TABLE "+sTableName);
    oStmt.close();
    if (!getConnection().getAutoCommit()) getConnection().commit();
  }

  // ---------------------------------------------------------------------------

  public void executeSQLScript (String sScriptSource, String sDelimiter)
    throws SQLException,InterruptedException,IllegalArgumentException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.executeSQLScript(String, "+sDelimiter+")");
      DebugFile.incIdent();
    }

    String sSQL;
    String aStatements[];

    if (sDelimiter.equals("GO;"))
      aStatements = split (new StringBuffer(sScriptSource), ';', "GO");
    else
      aStatements = split (new StringBuffer(sScriptSource), sDelimiter.charAt(0), null);

    int iStatements = aStatements.length;

    Statement oStmt = oConn.createStatement();

    for (int s = 0; s < iStatements; s++) {
      sSQL = aStatements[s];
      if (sSQL.length() > 0) {
        if (null!=oStrLog) oStrLog.append(sSQL + "\n\\\n");

        try {
          oStmt.execute (sSQL);
        }
        catch (SQLException sqle) {
          iErrors++;
          if (null!=oStrLog) oStrLog.append("SQLException: " + sqle.getMessage() + "\n");

          if (bStopOnError) {
            try { if (null!=oStmt) oStmt.close(); } catch (SQLException ignore) { }
            throw new InterruptedException(sqle.getMessage() + " " + sSQL);
          }
        }
      } // fi (sSQL)
      aStatements[s] = null;
    } // next
    oStmt.close();
    oStmt = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.executeSQLScript()");
    }
  }

  // ---------------------------------------------------------------------------

  private StringBuffer getSQLBuffer(String sResourcePath, int iBatchType)
    throws FileNotFoundException, IOException,SQLException,InterruptedException {

      if (DebugFile.trace) {
        DebugFile.writeln("Begin ModelManager.getSQLBuffer(" + sResourcePath + ")");
        DebugFile.incIdent();
      }

      int iReaded, iSkip;
      final int iBufferSize = 16384;
      char Buffer[] = new char[iBufferSize];
      InputStream oInStrm;
      InputStreamReader oStrm;
      StringBuffer oBuffer = new StringBuffer();

      iErrors = 0;

      if (FILE_STATEMENTS == iBatchType) {
        if (DebugFile.trace) DebugFile.writeln("new FileInputStream("+sResourcePath+")");
        if (null!=oStrLog) oStrLog.append("Open file " + sResourcePath + " as " + sEncoding + "\n");
        oInStrm = new FileInputStream(sResourcePath);
      }
      else {
        if (DebugFile.trace) DebugFile.writeln(getClass().getName()+".getResourceAsStream("+sResourcePath+")");
        if (null!=oStrLog) oStrLog.append("Get resource " + sResourcePath + " as " + sEncoding + "\n");
        oInStrm = getClass().getResourceAsStream(sResourcePath);
      }

      if (null == oInStrm) {
        iErrors = 1;
        if (null!=oStrLog) oStrLog.append("FileNotFoundException "+sResourcePath);
        if (DebugFile.trace) {
          DebugFile.writeln("FileNotFoundException "+sResourcePath);
          DebugFile.decIdent();
        }
        throw new FileNotFoundException("executeBulk() " + sResourcePath);
      } // fi

      if (DebugFile.trace) DebugFile.writeln("new InputStreamReader([InputStream], "+sEncoding+")");

      oStrm = new InputStreamReader(oInStrm, sEncoding);

      try {
        while (true) {
          iReaded = oStrm.read(Buffer,0,iBufferSize);

          if (-1==iReaded) break;

          // Skip FF FE character mark for Unidode files
          iSkip = ((int)Buffer[0]==65279 || (int)Buffer[0]==65534 ? 1 : 0);

          oBuffer.append(Buffer, iSkip, iReaded-iSkip);

        }
        oStrm.close();
        oInStrm.close();
      }
      catch (IOException ioe) {
        iErrors = 1;
        if (null!=oStrLog) oStrLog.append("IOException "+ioe.getMessage());
        if (DebugFile.trace) DebugFile.decIdent();
        throw new IOException(ioe.getMessage());
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ModelManager.getSQLBuffer() : " + String.valueOf(oBuffer.length()));
      }

      return oBuffer;
  }

  // ---------------------------------------------------------------------------

  private int executeBulk(StringBuffer oBuffer, String sResourcePath, int iBatchType)
    throws FileNotFoundException, IOException, SQLException,InterruptedException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.executeBulk(" + sResourcePath + "," +
                        String.valueOf(iBatchType) + ")");
      DebugFile.incIdent();
    }

    int iStatements;
    CallableStatement oCall = null;
    Statement oStmt = null;
    String sSQL = null;
    String aStatements[];

    iErrors = 0;

    if (sResourcePath.endsWith(".ddl") || sResourcePath.endsWith(".DDL")) {
      aStatements = split(oBuffer, ';', "GO");
    }
    else {
      aStatements = split(oBuffer, ';', null);
    }

    iStatements = aStatements.length;

      switch (iBatchType) {
        case BULK_PROCEDURES:
          for (int s = 0; s < iStatements; s++) {
            sSQL = aStatements[s];
            if (sSQL.length() > 0) {
              if (null!=oStrLog) oStrLog.append(sSQL + "\n");
              try {
                oCall = oConn.prepareCall(sSQL);
                oCall.execute();
                oCall.close();
                oCall = null;
              }
              catch (SQLException sqle) {
                iErrors++;
                if (null!=oStrLog) oStrLog.append("SQLException: " + sqle.getMessage() + "\n");
                try { if (null!=oCall) oCall.close(); } catch (SQLException ignore) { }
                if (bStopOnError) throw new java.lang.InterruptedException();
              }
            } // fi (sSQL)
          } // next
          break;

        case BULK_STATEMENTS:
        case FILE_STATEMENTS:
        case BULK_BATCH:

          oStmt = oConn.createStatement();
          for (int s = 0; s < iStatements; s++) {

            try {
              sSQL = translate(aStatements[s]);
            }
            catch (NullPointerException npe) {
              if (null!=oStrLog) oStrLog.append (" NullPointerException: at " + sResourcePath + " statement " + String.valueOf(s) + "\n");
              sSQL = "";
            }

            if (sSQL.length() > 0) {
              if (null!=oStrLog) oStrLog.append(sSQL + "\n\\\n");
              try {
            	if (!sSQL.startsWith("--")) {
                  oStmt.executeUpdate(sSQL);
                }
              }
              catch (SQLException sqle) {
                iErrors++;
                if (null!=oStrLog) oStrLog.append ("SQLException: " + sqle.getMessage() + "\n");

                if (bStopOnError) {
                  try { if (null!=oStmt) oStmt.close(); } catch (SQLException ignore) { }
                  throw new java.lang.InterruptedException();
                }
              }
            } // fi (sSQL)
          } // next
          oStmt.close();
          oStmt = null;
          break;

        case BULK_PLSQL:
          oStmt = oConn.createStatement();
          for (int s = 0; s < iStatements; s++) {
            sSQL = aStatements[s];
            if (sSQL.length() > 0) {
              if (null!=oStrLog) oStrLog.append(sSQL + "\n\\\n");
              try {
                oStmt.execute(sSQL);
              }
              catch (SQLException sqle) {
                iErrors++;
                if (null!=oStrLog) oStrLog.append("SQLException: " + sqle.getMessage() + "\n");

                if (bStopOnError) {
                  try { if (null!=oStmt) oStmt.close(); } catch (SQLException ignore) { }
                  throw new java.lang.InterruptedException();
                }
              }
            } // fi (sSQL)
          } // next
          oStmt.close();
          oStmt = null;
          break;
/*
        case BULK_BATCH:
          oStmt = oConn.createStatement();
          for (int s = 0; s < iStatements; s++) {
            sSQL = aStatements[s];
            if (sSQL.length() > 0) {
                oStmt.addBatch(sSQL);
            } // fi (sSQL)
            int[] results = oStmt.executeBatch();
            for (int r=0; r<results.length; r++) {
              if (results[r]==1)
                if (null!=oStrLog) oStrLog.append(aStatements[r] + "\n\\\n");
              else {
                iErrors++;
                if (null!=oStrLog) oStrLog.append("ERROR: " + aStatements[r] + "\n\\\n");
                if (bStopOnError) {
                  try { if (null!=oStmt) oStmt.close(); } catch (SQLException ignore) { }
                  throw new java.lang.InterruptedException();
                }
              }
            }
          } // next
          oStmt.close();
          oStmt = null;
          break;
 */
      } // end switch()

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.executeBulk()");
    }

    return iErrors;
  } // executeBulk

  // ---------------------------------------------------------------------------

  private int executeBulk(String sResourcePath, int iBatchType)
    throws FileNotFoundException, IOException, SQLException,InterruptedException {
    StringBuffer oBuffer = getSQLBuffer(sResourcePath, iBatchType);
    return executeBulk(oBuffer, sResourcePath, iBatchType);
  }

  // ---------------------------------------------------------------------------

  private StringBuffer changeSchema(String sResourcePath, int iType, String sOriginalSchema, String sNewSchema)
    throws InterruptedException, SQLException, IOException, FileNotFoundException {

    StringBuffer oBuffer = getSQLBuffer(sResourcePath, iType);
    String sBuffer = "";

    try {
      sBuffer = Gadgets.replace(oBuffer.toString(), sOriginalSchema+".", sNewSchema+".");
      oBuffer = new StringBuffer(sBuffer);
    } catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) {}

    return oBuffer;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Create a functional module</p>
   * @param sModuleName Name of module to create { kernel | lookups | security |
   * jobs | thesauri | categories | products | addrbook | webbuilder | crm |
   * lists | shops | projtrack | billing | hipermail | marketing }
   * @return <b>true</b> if module was successfully created, <b>false</b> if errors
   * occured during module creation. Even if error occur module may still be partially
   * created at database after calling create()
   * @throws IllegalStateException If not connected to database
   * @throws FileNotFoundException If any of the internal files for module is not found
   * @throws SQLException
   * @throws IOException
   */
  public boolean create(String sModuleName)
    throws IllegalStateException, SQLException, FileNotFoundException, IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.create(" + sModuleName + ")");
      DebugFile.incIdent();
    }

    boolean bRetVal = true;

    if (null==oConn)
      throw new IllegalStateException("Not connected to database");

    try {
    if (sModuleName.equals("kernel")) {

      executeBulk("tables/kernel.ddl", BULK_STATEMENTS);
      executeBulk("data/k_sequences.sql", BULK_STATEMENTS);
      executeBulk("data/k_version.sql", BULK_STATEMENTS);
      executeBulk("indexes/kernel.sql", BULK_STATEMENTS);

      switch (iDbms) {
        case DBMS_MSSQL:
          executeBulk("procedures/mssql/kernel.ddl", BULK_PLSQL);
          break;
        case DBMS_MYSQL:
          executeBulk("procedures/mysql/kernel.ddl", BULK_PLSQL);
          break;
        case DBMS_POSTGRESQL:
          executeBulk("procedures/postgresql/kernel.sql", BULK_STATEMENTS);
          executeBulk("procedures/postgresql/kernel.ddl", BULK_PLSQL);
          executeBulk("views/postgresql/kernel.sql", BULK_STATEMENTS);
          break;
        default:
          executeBulk("procedures/" + sDbms + "/kernel.sql", BULK_PLSQL);
          break;
      } // end switch

    } else if (sModuleName.equals("lookups")) {

      executeBulk("tables/lookups.ddl", BULK_STATEMENTS);

      executeBulk("data/k_lu_languages.sql"  , BULK_STATEMENTS);
      executeBulk("data/k_lu_countries.sql"  , BULK_STATEMENTS);
      executeBulk("data/k_lu_currencies.sql" , BULK_STATEMENTS);
      executeBulk("data/k_lu_status.sql"     , BULK_BATCH);
      executeBulk("data/k_lu_cont_types.sql" , BULK_BATCH);
      executeBulk("data/k_lu_prod_types.sql" , BULK_BATCH);
      executeBulk("data/k_classes.sql"       , BULK_BATCH);

    } else if (sModuleName.equals("security")) {

      executeBulk("tables/security.ddl", BULK_STATEMENTS);

      executeBulk("data/k_lu_permissions.sql", BULK_STATEMENTS);

      executeBulk("data/k_apps.sql", BULK_STATEMENTS);

      executeBulk("data/k_domains.sql", BULK_STATEMENTS);

      executeBulk("data/k_acl_groups.sql", BULK_STATEMENTS);

      executeBulk("data/k_users.sql", BULK_STATEMENTS);

      executeBulk("data/k_x_group_user.sql", BULK_STATEMENTS);

      executeBulk("data/k_workareas.sql", BULK_STATEMENTS);

      executeBulk("data/k_x_app_workarea.sql", BULK_STATEMENTS);

      executeBulk("data/k_x_portlet_user.sql", BULK_STATEMENTS);

      executeBulk("constraints/security.sql", BULK_STATEMENTS);

      executeBulk("views/security.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/security.ddl", BULK_PLSQL);

      switch (iDbms) {
        case DBMS_MSSQL:
          executeBulk("triggers/mssql/security.ddl", BULK_PLSQL);
          break;
      }

    } else if (sModuleName.equals("example")) {
      executeBulk("tables/example.ddl", BULK_STATEMENTS);

    } else if (sModuleName.equals("jobs")) {

      executeBulk("tables/jobs.ddl", BULK_STATEMENTS);

      executeBulk("views/jobs.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/jobs.ddl", BULK_PLSQL);

      executeBulk("data/k_lu_job_status.sql" , BULK_BATCH);

      executeBulk("data/k_lu_job_commands.sql" , BULK_BATCH);

      executeBulk("constraints/jobs.sql", BULK_STATEMENTS);

      executeBulk("indexes/jobs.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("categories")) {

      executeBulk("tables/categories.ddl", BULK_STATEMENTS);

      executeBulk("constraints/categories.sql", BULK_STATEMENTS);

      executeBulk("data/all_categories.sql", BULK_BATCH);

      executeBulk("procedures/" + sDbms + "/categories.ddl", BULK_PLSQL);

      executeBulk("indexes/categories.sql", BULK_STATEMENTS);

      if (iDbms==DBMS_MSSQL) {
        executeBulk(changeSchema("views/" + sDbms + "/categories.sql", BULK_STATEMENTS, "dbo", sSchema),
                                 "views/" + sDbms + "/categories.sql", BULK_STATEMENTS);
        executeBulk("triggers/" + sDbms + "/categories.ddl", BULK_STATEMENTS);
      }
      else {
        executeBulk("views/" + sDbms + "/categories.sql", BULK_STATEMENTS);
      }

      if (iDbms==DBMS_ORACLE)
        executeBulk("triggers/" + sDbms + "/categories.ddl", BULK_STATEMENTS);

    } else if (sModuleName.equals("thesauri")) {

      executeBulk("tables/thesauri.ddl", BULK_STATEMENTS);

      executeBulk("indexes/thesauri.sql", BULK_STATEMENTS);

      executeBulk("constraints/thesauri.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/thesauri.ddl", BULK_PLSQL);

    } else if (sModuleName.equals("products")) {

      executeBulk("tables/products.ddl", BULK_STATEMENTS);

      executeBulk("constraints/products.sql", BULK_STATEMENTS);

      executeBulk("views/" + sDbms + "/products.sql", BULK_STATEMENTS);

      executeBulk("indexes/products.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/products.ddl", BULK_PLSQL);

    } else if (sModuleName.equals("addrbook")) {

      executeBulk("tables/addrbook.ddl", BULK_STATEMENTS);

      executeBulk("constraints/addrbook.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/addrbook.ddl", BULK_PLSQL);

      executeBulk("data/k_to_do_lookup.sql" , BULK_STATEMENTS);

      executeBulk("data/k_addresses_lookup.sql" , BULK_STATEMENTS);

      executeBulk("indexes/addrbook.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("forums")) {

      executeBulk("tables/forums.ddl", BULK_STATEMENTS);

      executeBulk("constraints/forums.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/forums.ddl", BULK_PLSQL);

      executeBulk("data/k_newsgroups.sql", BULK_STATEMENTS);

      executeBulk("indexes/forums.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("crm")) {

      executeBulk("tables/crm.ddl", BULK_STATEMENTS);

	  // Do not change order between constraints and procedures.
	  // For Micorosft SQL Server, constraints/crm.sql must be
	  // executed before procedures/mssql/crm.ddl
	  
      executeBulk("constraints/crm.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/crm.ddl", BULK_PLSQL);

      executeBulk("data/k_companies_lookup.sql" , BULK_STATEMENTS);

      executeBulk("data/k_contacts_lookup.sql" , BULK_STATEMENTS);

      executeBulk("data/k_oportunities_lookup.sql" , BULK_STATEMENTS);

      executeBulk("indexes/crm.sql", BULK_STATEMENTS);

      if (iDbms==DBMS_MSSQL) {
        executeBulk(changeSchema("views/" + sDbms + "/crm.sql", BULK_STATEMENTS, "dbo", sSchema),
                    "views/" + sDbms + "/crm.sql", BULK_STATEMENTS);

      }
      else {
        executeBulk("views/" + sDbms + "/crm.sql", BULK_STATEMENTS);
      }
    } else if (sModuleName.equals("lists")) {

      executeBulk("tables/lists.ddl", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/lists.ddl", BULK_PLSQL);

      executeBulk("views/" + sDbms + "/lists.sql", BULK_STATEMENTS);

      executeBulk("indexes/lists.sql", BULK_STATEMENTS);

      executeBulk("constraints/lists.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("projtrack")) {

      executeBulk("tables/projtrack.ddl", BULK_STATEMENTS);

      executeBulk("views/" + sDbms + "/projtrack.sql", BULK_STATEMENTS);

      executeBulk("data/k_projects_lookup.sql" , BULK_STATEMENTS);

      executeBulk("data/k_duties_lookup.sql" , BULK_STATEMENTS);

      executeBulk("data/k_bugs_lookup.sql" , BULK_STATEMENTS);

      executeBulk("indexes/projtrack.sql", BULK_STATEMENTS);

      executeBulk("constraints/projtrack.sql", BULK_STATEMENTS);

      if (iDbms==DBMS_MSSQL) {
        // Microsoft SQL Server functions and views must be created specifying
        // explicitly the schema, so change the default "dbo" to the current one
        executeBulk(changeSchema("procedures/" + sDbms + "/projtrack.ddl", BULK_PLSQL, "dbo", sSchema),
                    "procedures/" + sDbms + "/projtrack.ddl", BULK_PLSQL);
      }
      else {
        executeBulk("procedures/" + sDbms + "/projtrack.ddl", BULK_PLSQL);
      }
    } else if (sModuleName.equals("webbuilder")) {

      executeBulk("tables/webbuilder.ddl", BULK_STATEMENTS);

      executeBulk("constraints/webbuilder.sql", BULK_STATEMENTS);

      executeBulk("data/k_microsites.sql" , BULK_STATEMENTS);

      executeBulk("indexes/webbuilder.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/webbuilder.ddl", BULK_PLSQL);

    } else if (sModuleName.equals("shops")) {

      executeBulk("tables/shops.ddl", BULK_STATEMENTS);

      executeBulk("data/k_invoices_lookup.sql", BULK_STATEMENTS);

      executeBulk("constraints/shops.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/shops.ddl", BULK_PLSQL);

      if (iDbms==DBMS_MSSQL) {
        executeBulk(changeSchema("views/" + sDbms + "/shops.sql", BULK_STATEMENTS, "dbo", sSchema),
                    "views/" + sDbms + "/shops.sql", BULK_STATEMENTS);
      }
      else {
        executeBulk("views/" + sDbms + "/shops.sql", BULK_STATEMENTS);
      }
    } else if (sModuleName.equals("billing")) {

      executeBulk("tables/billing.ddl", BULK_STATEMENTS);

      executeBulk("constraints/billing.sql", BULK_STATEMENTS);

      executeBulk("procedures/" + sDbms + "/billing.ddl", BULK_PLSQL);

  } else if (sModuleName.equals("hipermail")) {

    executeBulk("tables/hipermail.ddl", BULK_STATEMENTS);

    executeBulk("constraints/hipermail.sql", BULK_STATEMENTS);

    executeBulk("indexes/hipermail.sql", BULK_STATEMENTS);

    executeBulk("procedures/" + sDbms + "/hipermail.ddl", BULK_PLSQL);

    executeBulk("views/hipermail.sql", BULK_STATEMENTS);

  } else if (sModuleName.equals("training")) {

    executeBulk("tables/training.ddl", BULK_STATEMENTS);

    executeBulk("views/training.sql", BULK_STATEMENTS);

    executeBulk("constraints/training.sql", BULK_STATEMENTS);

    executeBulk("procedures/" + sDbms + "/training.ddl", BULK_PLSQL);

  } else if (sModuleName.equals("marketing")) {
    executeBulk("tables/marketing.ddl", BULK_STATEMENTS);
    executeBulk("procedures/" + sDbms + "/marketing.ddl", BULK_PLSQL);
    executeBulk("views/marketing.sql", BULK_STATEMENTS);
    executeBulk("constraints/marketing.sql", BULK_STATEMENTS);
    executeBulk("indexes/marketing.sql", BULK_STATEMENTS);
  }
  } catch (InterruptedException ie) {
    if (null!=oStrLog) oStrLog.append("STOP ON ERROR SET TO ON: SCRIPT INTERRUPTED\n");
    bRetVal = false;
  }

  if (DebugFile.trace) {
    DebugFile.decIdent();
    DebugFile.writeln("End ModelManager.create() : " + String.valueOf(bRetVal));
  }

  return bRetVal;
 } // create

  // ---------------------------------------------------------------------------

  /**
   * <p>Drop a functional module</p>
   * @param sModuleName Name of module to drop { kernel | lookups | security |
   * jobs | thesauri | categories | products | addrbook | webbuilder | crm |
   * lists | shops | projtrack | billing | hipermail }
   * @return <b>true</b> if module was successfully droped, <b>false</b> if errors
   * occured during droping module.
   * Even if error occur module may still be partially droped at database after calling drop()
   * @throws IllegalStateException
   * @throws SQLException
   * @throws FileNotFoundException
   * @throws IOException
   */
  public boolean drop(String sModuleName)
    throws IllegalStateException, SQLException, FileNotFoundException,IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.drop(" + sModuleName + ")");
      DebugFile.incIdent();
    }

    boolean bRetVal = true;

    if (null==oConn)
      throw new IllegalStateException("Not connected to database");

    try {
    if (sModuleName.equals("kernel")) {

      executeBulk("drop/" + sDbms + "/kernel.sql", BULK_STATEMENTS);
      executeBulk("drop/kernel.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("lookups")) {

      executeBulk("drop/lookups.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("security")) {

      executeBulk("drop/" + sDbms + "/security.sql", BULK_STATEMENTS);

      executeBulk("drop/security.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("jobs")) {

      executeBulk("drop/" + sDbms + "/jobs.sql", BULK_STATEMENTS);

      executeBulk("drop/jobs.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("categories")) {

      executeBulk("drop/" + sDbms + "/categories.sql", BULK_STATEMENTS);

      executeBulk("drop/categories.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("thesauri")) {

      executeBulk("drop/thesauri.sql", BULK_STATEMENTS);

      executeBulk("drop/" + sDbms + "/thesauri.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("addrbook")) {

      executeBulk("drop/" + sDbms + "/addrbook.sql", BULK_STATEMENTS);

      executeBulk("drop/addrbook.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("forums")) {

      executeBulk("drop/" + sDbms + "/forums.sql", BULK_STATEMENTS);

      executeBulk("drop/forums.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("products")) {

      executeBulk("drop/" + sDbms + "/products.sql", BULK_STATEMENTS);

      executeBulk("drop/products.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("crm")) {

      executeBulk("drop/" + sDbms + "/crm.sql", BULK_STATEMENTS);

      executeBulk("drop/crm.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("lists")) {

      executeBulk("drop/" + sDbms + "/lists.sql", BULK_STATEMENTS);

      executeBulk("drop/lists.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("projtrack")) {

      if (iDbms==DBMS_MSSQL) {
        executeBulk(changeSchema("drop/" + sDbms + "/projtrack.sql", BULK_STATEMENTS, "dbo", sSchema),
                    "drop/" + sDbms + "/projtrack.sql", BULK_STATEMENTS);
      }
      else {
        executeBulk("drop/" + sDbms + "/projtrack.sql", BULK_STATEMENTS);
      }

      executeBulk("drop/projtrack.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("webbuilder")) {

      executeBulk("drop/" + sDbms + "/webbuilder.sql", BULK_STATEMENTS);

      executeBulk("drop/webbuilder.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("shops")) {

      executeBulk("drop/" + sDbms + "/shops.sql", BULK_STATEMENTS);

      executeBulk("drop/shops.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("billing")) {

      executeBulk("drop/" + sDbms + "/billing.sql", BULK_STATEMENTS);

      executeBulk("drop/billing.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("hipermail")) {

      executeBulk("drop/" + sDbms + "/hipermail.sql", BULK_STATEMENTS);

      executeBulk("drop/hipermail.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("training")) {

      executeBulk("drop/training.sql", BULK_STATEMENTS);

      executeBulk("drop/" + sDbms + "/training.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("marketing")) {

      executeBulk("drop/" + sDbms + "/marketing.sql", BULK_STATEMENTS);

      executeBulk("drop/marketing.sql", BULK_STATEMENTS);

    } else if (sModuleName.equals("example")) {

      executeBulk("drop/example.sql", BULK_STATEMENTS);

    }
    } catch (InterruptedException ie) {
      if (null!=oStrLog) oStrLog.append("STOP ON ERROR SET TO ON: SCRIPT INTERRUPTED\n");
      bRetVal = false;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.drop() : " + String.valueOf(bRetVal));
    }

  return bRetVal;
  } // drop

  // ---------------------------------------------------------------------------

  /**
   * <p>Create all modules</p>
   * The created modules will be (in order):
   * kernel, lookups, security, jobs, categories, thesauri, products, addrbook,
   * forums, crm, projtrack, lists, webbuilder, shops, billing, hipermail, training
   * @throws FileNotFoundException If any of the internal files for modules are not found
   * @throws IllegalStateException
   * @throws SQLException
   * @throws IOException
   */
  public boolean createAll()
    throws IllegalStateException, SQLException, FileNotFoundException, IOException {

    if (!create ("kernel") && bStopOnError) return false;
    if (!create ("lookups") && bStopOnError) return false;
    if (!create ("security") && bStopOnError) return false;
    if (!create ("jobs") && bStopOnError) return false;
    if (!create ("categories") && bStopOnError) return false;
    if (!create ("thesauri") && bStopOnError) return false;
    if (!create ("products") && bStopOnError) return false;
    if (!create ("addrbook") && bStopOnError) return false;
    if (!create ("forums") && bStopOnError) return false;
    if (!create ("crm") && bStopOnError) return false;
    if (!create ("projtrack") && bStopOnError) return false;
    if (!create ("lists") && bStopOnError) return false;
    if (!create ("webbuilder") && bStopOnError) return false;
    if (!create ("shops") && bStopOnError) return false;
    if (!create ("billing") && bStopOnError) return false;
    if (!create ("hipermail") && bStopOnError) return false;
    if (!create ("training") && bStopOnError) return false;
    if (!create ("marketing") && bStopOnError) return false;
    if (!create ("example") && bStopOnError) return false;

    if (DBMS_ORACLE==iDbms) {
      try {
        recompileOrcl();
      }
        catch (SQLException sqle) {
          if (bStopOnError) throw new SQLException ("SQLException: " + sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
      }

      Statement oStmt = null;
      ResultSet oRSet = null;

      try {

        oStmt = oConn.createStatement();
        oRSet = oStmt.executeQuery("SELECT OBJECT_TYPE,OBJECT_NAME FROM USER_OBJECTS WHERE STATUS='INVALID' AND OBJECT_TYPE IN ('PROCEDURE','VIEW','TRIGGER')");

        while (oRSet.next()) {
          iErrors++;
          if (null!=oStrLog) oStrLog.append(oRSet.getString(1) + " " + oRSet.getString(2) + " is invalid after recompile\n");
        } // wend

      } catch (SQLException sqle) {
        iErrors++;
        if (null!=oStrLog) oStrLog.append(sqle + "\n");

        if (bStopOnError)
          throw new SQLException("SQLException: " + sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
      }
      finally {
        if (null!=oRSet) oRSet.close();
        oRSet = null;
        if (null!=oStmt) oStmt.close();
        oStmt = null;
      }
    }
    return true;
  } // createAll

  // ---------------------------------------------------------------------------

  /**
   * <p>Drop all modules</p>
   * The created modules will be (in order):
   * example, marketing, training, hipermail, billing, shops, webbuilder,
   * lists, projtrack, crm, forums, addrbook, products, thesauri, categories,
   * jobs, security, lookups, kernel
   * @throws IllegalStateException
   * @throws SQLException
   * @throws FileNotFoundException
   * @throws IOException
   */
  public boolean dropAll()
    throws IllegalStateException, SQLException, FileNotFoundException, IOException {

    if (!drop ("example") && bStopOnError) return false;
    if (!drop ("marketing") && bStopOnError) return false;
    if (!drop ("training") && bStopOnError) return false;
    if (!drop ("hipermail") && bStopOnError) return false;
    if (!drop ("billing") && bStopOnError) return false;
    if (!drop ("shops") && bStopOnError) return false;
    if (!drop ("webbuilder") && bStopOnError) return false;
    if (!drop ("lists") && bStopOnError) return false;
    if (!drop ("projtrack") && bStopOnError) return false;
    if (!drop ("crm") && bStopOnError) return false;
    if (!drop ("forums") && bStopOnError) return false;
    if (!drop ("addrbook") && bStopOnError) return false;
    if (!drop ("products") && bStopOnError) return false;
    if (!drop ("thesauri") && bStopOnError) return false;
    if (!drop ("categories") && bStopOnError) return false;
    if (!drop ("jobs") && bStopOnError) return false;
    if (!drop ("security") && bStopOnError) return false;
    if (!drop ("lookups") && bStopOnError) return false;
    if (!drop ("kernel") && bStopOnError) return false;

    return true;
  } // createAll

  // ---------------------------------------------------------------------------

  /**
   * <p>Create a default database ready for use</p>
   * All modules for the full suite will be created at the new database.<br>
   * The new database will contain 5 domains and 5 workareas:<br>
   * SYSTEM, MODEL, TEST, DEMO and REAL<br>
   * SYSTEM and MODEL domains are for administrative purposed only and should
   * not be used by programmers.<br>
   * Domains TEST, DEMO and REAL are intended for development/testing,
   * aceptance/demostration and real/production usage.<br>
   * Error messages are written to internal ModelManager log and can be inspected by
   * calling report() method after createDefaultDatabase()
   * @throws FileNotFoundException If any of the internal files for modules are not found
   * @throws EvalError Java BeanShell script domain_create.js as a syntax error
   * @throws org.xml.sax.SAXException Parsing error at file workarea_clon.xml
   * @throws InstantiationException SAX parser is not properly installed
   * @throws IllegalAccessException SAX parser is not properly installed
   * @throws ClassNotFoundException SAX parser is not properly installed
   * @throws IOException
   * @throws SQLException
   */
  public boolean createDefaultDatabase()
    throws FileNotFoundException, IOException, SQLException, EvalError,
    InstantiationException, IllegalAccessException, ClassNotFoundException,
    org.xml.sax.SAXException {

    Statement oStmt = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("Begin ModelManager.createDefaultDatabase()");
    }

    // Ensure that SAXParser can be instantiated before initiating the database creation process
    if (DebugFile.trace)
      DebugFile.writeln("Class.forName(org.apache.xerces.parsers.SAXParser)");
    Class SAXParserClass = Class.forName("org.apache.xerces.parsers.SAXParser");

    if (DBMS_MSSQL==iDbms) {
      try {
        oStmt = oConn.createStatement();

        if (DebugFile.trace)
          DebugFile.writeln("Statement.execute(ALTER DATABASE " + oConn.getCatalog() + " SET ARITHABORT ON)");

        oStmt.execute("ALTER DATABASE " + oConn.getCatalog() + " SET ARITHABORT ON");
        oStmt.close();
        oStmt=null;

        if (null!=oStrLog) oStrLog.append("ALTER DATABASE " + oConn.getCatalog() + " SET ARITHABORT ON\n");
      }
      catch (SQLException sqle) {
         if (DebugFile.trace)
           DebugFile.writeln("SQLException " + sqle.getMessage());
         iErrors++;
         if (null!=oStrLog) oStrLog.append("SQLException: " + sqle.getMessage() + "\n");
      }
    }

    boolean bRetVal = createAll();

    createDomain("TEST");
    createDomain("DEMO");
    createDomain("REAL");

    cloneWorkArea("MODEL.model_default", "TEST.test_default");
    cloneWorkArea("MODEL.model_default", "DEMO.demo_default");
    cloneWorkArea("MODEL.model_default", "REAL.real_default");

    // After installing on Windows replace slashes with backslashes

    if (System.getProperty("os.name").startsWith("Windows")) {
      oStmt = oConn.createStatement();
      try {
        switch (iDbms) {
          case DBMS_MSSQL:
          case DBMS_ORACLE:
          case DBMS_MYSQL:
          case DBMS_DB2:
            oStmt.executeUpdate(
                "UPDATE k_microsites SET path_metadata=REPLACE(path_metadata,'/','\\\\')");
            oStmt.executeUpdate(
                "UPDATE k_pagesets SET path_data=REPLACE(path_data,'/','\\\\')");
            break;
          case DBMS_POSTGRESQL:
            oStmt.executeUpdate(
                "UPDATE k_microsites SET path_metadata=translate(path_metadata,'/','\\\\')");
            oStmt.executeUpdate(
                "UPDATE k_pagesets SET path_data=translate(path_data,'/','\\\\')");
            break;
        } // end switch(iDbms)
        oStmt.close();
        oStmt=null;
      } catch (SQLException sqle) {
        if (DebugFile.trace) DebugFile.writeln("SQLException " + sqle.getMessage());
        iErrors++;
        if (null!=oStrLog) oStrLog.append("SQLException: " + sqle.getMessage() + "\n");
        try { oStmt.close(); } catch (Exception ignore) {}
      }
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.createDefaultDatabase() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // createDefaultDatabase

  // ---------------------------------------------------------------------------

  /**
   * Create INSERT SQL statements for the data of a table
   * @param sTableName Table Name
   * @param sWhere SQL filter clause
   * @param sFilePath Path for file where INSERT statements are to be written
   * @throws SQLException
   * @throws IOException
   */
  public void scriptData (String sTableName, String sWhere, String sFilePath)
    throws SQLException, IOException {

    Statement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    FileOutputStream oWriter;
    String sColumns;
    Object oValue;
    String sValue;
    String sValueEscaped;
    int iCols;
    byte[] byComma = new String(",").getBytes(sEncoding);
    byte[] byNull = new String("NULL").getBytes(sEncoding);
    byte[] byCRLF = new String(");\n").getBytes(sEncoding);

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    if (sWhere==null)
      oRSet = oStmt.executeQuery("SELECT * FROM " + sTableName + " ORDER BY 1");
    else
      oRSet = oStmt.executeQuery("SELECT * FROM " + sTableName + " WHERE " + sWhere + " ORDER BY 1");

    oMDat = oRSet.getMetaData();
    iCols = oMDat.getColumnCount();

    sColumns = "";

    for (int c=1; c<=iCols; c++) {
      if (!oMDat.getColumnName(c).equalsIgnoreCase("dt_created")) {
        if (c!=1) sColumns += ",";
        sColumns += oMDat.getColumnName(c);
      }
    } // next

    oWriter = new FileOutputStream(sFilePath);

    while (oRSet.next()) {
      sValue = "INSERT INTO " + sTableName + " (" + sColumns + ") VALUES (";

      oWriter.write(sValue.getBytes(sEncoding));

      for (int c=1; c<=iCols; c++) {

        if (!oMDat.getColumnName(c).equalsIgnoreCase("dt_created")) {

          if (c!=1) oWriter.write(byComma);

          switch (oMDat.getColumnType(c)) {

            case Types.CHAR:
            case Types.VARCHAR:
              sValue = oRSet.getString(c);
              if (oRSet.wasNull())
                sValueEscaped = "NULL";
              else if (sValue.indexOf(39)>=0) {
                sValueEscaped = "'";
                for (int n=0; n<sValue.length(); n++)
                  sValueEscaped += (sValue.charAt(n)!=39 ? sValue.substring(n,n+1) : "''");
                sValueEscaped += "'";
              }
              else
                sValueEscaped = "'" + sValue + "'";
              oWriter.write(sValueEscaped.getBytes(sEncoding));
              break;

            case Types.SMALLINT:
              oValue = oRSet.getObject(c);
              if (oRSet.wasNull())
                oWriter.write(byNull);
              else
                oWriter.write(String.valueOf(oRSet.getShort(c)).getBytes(sEncoding));
              break;

            case Types.INTEGER:

              oValue = oRSet.getObject(c);
              if (oRSet.wasNull())
                oWriter.write(byNull);
              else
                oWriter.write(String.valueOf(oRSet.getInt(c)).getBytes(sEncoding));
              break;

            case Types.DATE:
            case Types.TIMESTAMP:
              oWriter.write(byNull);
              break;

          } // end switch
        } // fi (dt_created)
      } // next
      oWriter.write(byCRLF);
    } // wend

    oWriter.close();
  } // scriptData

  // ----------------------------------------------------------

  /**
   * <p>Get an embedded resource file as a String</p>
   * @param sResourcePath Relative path at JAR file from com/knowgate/hipergate/datamodel/ModelManager
   * @param sEncoding Character encoding for resource if it is a text file.<br>
   * If sEncoding is <b>null</b> then UTF-8 is assumed.
   * @return Readed file
   * @throws FileNotFoundException
   * @throws IOException
   */
  public String getResourceAsString (String sResourcePath, String sEncoding)
      throws FileNotFoundException, IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.getResourceAsString(" + sResourcePath + "," + sEncoding + ")");
      DebugFile.incIdent();
    }

    StringBuffer oXMLSource = new StringBuffer(12000);
    char[] Buffer = new char[4000];
    InputStreamReader oReader = null;
    int iReaded, iSkip;

    if (null==sEncoding) sEncoding = "UTF-8";

    InputStream oIoStrm = this.getClass().getResourceAsStream(sResourcePath);

	if (null==oIoStrm) throw new FileNotFoundException("Resource "+sResourcePath+" not found for class "+this.getClass().getName());

    oReader = new InputStreamReader(oIoStrm, sEncoding);
	
    while (true) {
      iReaded = oReader.read(Buffer, 0, 4000);

      if (-1==iReaded) break;

      // Skip FF FE character mark for Unidode files
      iSkip = ((int)Buffer[0]==65279 || (int)Buffer[0]==65534 ? 1 : 0);

      oXMLSource.append(Buffer, iSkip, iReaded-iSkip);
    } // wend

    oReader.close();
	oIoStrm.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.getResourceAsString()");
    }

    return oXMLSource.toString();

  } // getResourceAsString

  // ---------------------------------------------------------------------------

  /**
  * <p>Re-compile invalid objects for an Oracle database</p>
  * @throws SQLException
  * @throws FileNotFoundException
  * @throws IOException
  */
  public void recompileOrcl () throws SQLException {

    String sqlgencmd;
    Statement oStmt;
    CallableStatement oCall;
    ResultSet oRSet;
    String sAlterSql = "";

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.recompileOrcl()");
      DebugFile.incIdent();
    }

    // This SQL query produces the alter statements for recompile the objects which status is 'INVALID'
    sqlgencmd = " SELECT 'ALTER ' || DECODE(object_type, 'PACKAGE BODY', 'PACKAGE', object_type) || ' ' || ";
    sqlgencmd += "object_name || ' COMPILE' || DECODE(object_type, 'PACKAGE BODY', ' BODY', '') ";
    sqlgencmd += " cmd ";
    sqlgencmd += "FROM USER_OBJECTS ";
    sqlgencmd += "WHERE status = 'INVALID' AND ";
    sqlgencmd += "object_type IN ('TRIGGER','PACKAGE','PACKAGEBODY','VIEW','PROCEDURE','FUNCTION') AND ";
    sqlgencmd += "(object_type <> 'PACKAGE BODY' OR ";
    sqlgencmd += " (object_name) NOT IN ";
    sqlgencmd += "               (SELECT object_name ";
    sqlgencmd += "                FROM USER_OBJECTS ";
    sqlgencmd += "                WHERE object_type = 'PACKAGE' AND status = 'INVALID'))";

    if (null!=oStrLog) oStrLog.append(sqlgencmd+"\n");

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oRSet = oStmt.executeQuery(sqlgencmd);

    while (oRSet.next()) {

      try {
           sAlterSql = oRSet.getString(1);
           oCall = oConn.prepareCall(sAlterSql);
           oCall.execute();
           oCall.close();

           if (null!=oStrLog) oStrLog.append(sAlterSql+"\n");
      }
      catch (SQLException sqle) {

           iErrors++;
           if (null!=oStrLog) oStrLog.append("SQLException: " + sqle.getMessage() + "\n");
           if (null!=oStrLog) oStrLog.append(sAlterSql + "\n");

           if (bStopOnError) {
             oRSet.close();
             oRSet = null ;
             oStmt.close();
             oStmt = null ;

             throw new SQLException("SQLException: " + sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
           }
      }

    } // wend
    if (null!=oRSet) oRSet.close();
    if (null!=oStmt) oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.recompileOrcl()");
    }
  } // recompileOrcl

  // ----------------------------------------------------------

  /**
   * <p>Clone a set of Contacts</p>
   * Contacts are cloned by following instructions contained in contact_clon.xml file.
   * @param sContactsFilter WHERE clause of contacts to be cloned, for cloning just one contact use "gu_contact='<i>GUID_OF_CONTACT</i>'"
   * @param sTargetWorkArea GUID of WorkArea where new contact is to be written
   * @param sNewOwner GUID of user (from k_users table) that will be the new owner of the contact or <b>null</b>
   * @return Error messages are written to internal ModelManager log and can be inspected by
   * calling report() method after cloneContacts()
   * @throws SQLException
   * @throws IOException XML definition file for cloning not found
   * @throws InstantiationException SAX parser is not properly installed
   * @throws IllegalAccessException SAX parser is not properly installed
   * @throws ClassNotFoundException SAX parser is not properly installed
   * @throws org.xml.sax.SAXException Parsing error at file workarea_clon.xml
   * @throws IOException
   * @since 6.0
   */
  public void cloneContacts(String sContactsFilter, String sTargetWorkArea, String sNewOwnerId)
    throws SQLException,IOException,InstantiationException,IllegalAccessException,
           IOException, ClassNotFoundException, org.xml.sax.SAXException {

	ListIterator oIter;
    Statement oStmt= null;
    ResultSet oRSet= null;
    Object[] oPKOr = new Object[1];
	Object[] oPKTr = new Object[1];

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.cloneContacts(" + sContactsFilter + "," + sTargetWorkArea + "," + sNewOwnerId + ")");
      DebugFile.incIdent();
    }

    if (null==oConn)
      throw new IllegalStateException("Not connected to database");

	JDCConnection oJDC;
    // Get a JDC Connection Wrapper
    if (oConn instanceof JDCConnection)
      oJDC = (JDCConnection) oConn;
    else
      oJDC = new JDCConnection(oConn, null);

	String sContactXml = null;
	String sCompanyXml = null;
	
	if (oJDC.getPool()==null) {
      switch (oJDC.getDataBaseProduct()) {
        case JDCConnection.DBMS_MSSQL:
          sContactXml = getResourceAsString("scripts/mssql/contact_clon.xml", sEncoding);
          sCompanyXml = getResourceAsString("scripts/mssql/company_clon.xml", sEncoding);
          break;
        case JDCConnection.DBMS_MYSQL:
          sContactXml = getResourceAsString("scripts/mysql/contact_clon.xml", sEncoding);
          sCompanyXml = getResourceAsString("scripts/mysql/company_clon.xml", sEncoding);
          break;
      case JDCConnection.DBMS_ORACLE:
        sContactXml = getResourceAsString("scripts/oracle/contact_clon.xml", sEncoding);
        sCompanyXml = getResourceAsString("scripts/oracle/company_clon.xml", sEncoding);
        break;
      case JDCConnection.DBMS_POSTGRESQL:
        sContactXml = getResourceAsString("scripts/postgresql/contact_clon.xml", sEncoding);
        sCompanyXml = getResourceAsString("scripts/postgresql/company_clon.xml", sEncoding);
        break;
      default:
        if (DebugFile.trace) {
          DebugFile.writeln("Unsupported database");
          DebugFile.decIdent();
        }
      	throw new SQLException ("Unsupported database");
      }
	}
	else {
	  FileSystemWorkArea oFsw = new FileSystemWorkArea(((DBBind)oJDC.getPool().getDatabaseBinding()).getProperties());
      try {
        switch (oJDC.getDataBaseProduct()) {
          case JDCConnection.DBMS_MSSQL:
            sContactXml = oFsw.readstorfilestr("datacopy/mssql/contact_clon.xml", sEncoding);
            sCompanyXml = oFsw.readstorfilestr("datacopy/mssql/company_clon.xml", sEncoding);
            break;
          case JDCConnection.DBMS_MYSQL:
            sContactXml = oFsw.readstorfilestr("datacopy/mysql/contact_clon.xml", sEncoding);
            sCompanyXml = oFsw.readstorfilestr("datacopy/mysql/company_clon.xml", sEncoding);
            break;
          case JDCConnection.DBMS_ORACLE:
            sContactXml = oFsw.readstorfilestr("datacopy/oracle/contact_clon.xml", sEncoding);
            sCompanyXml = oFsw.readstorfilestr("datacopy/oracle/company_clon.xml", sEncoding);
            break;
          case JDCConnection.DBMS_POSTGRESQL:
            sContactXml = oFsw.readstorfilestr("datacopy/postgresql/contact_clon.xml", sEncoding);
            sCompanyXml = oFsw.readstorfilestr("datacopy/postgresql/company_clon.xml", sEncoding);
            break;
          default:
            if (DebugFile.trace) {
              DebugFile.writeln("Unsupported database "+oJDC.getMetaData().getDatabaseProductName());
              DebugFile.decIdent();
            }
      	    throw new SQLException ("Unsupported database "+oJDC.getMetaData().getDatabaseProductName());
        }
      } catch (com.enterprisedt.net.ftp.FTPException neverthrown) { }
	} // fi
	
    Properties oParams = new Properties();
    oParams.put("IdWorkArea", sTargetWorkArea);
    oParams.put("IdOwner", sNewOwnerId==null ? "null" : sNewOwnerId);

    DataStruct oCS = new DataStruct();
    DataStruct oDS = new DataStruct();

    oCS.setOriginConnection(oConn);
    oCS.setTargetConnection(oConn);
    oCS.setAutoCommit(false);

    oDS.setOriginConnection(oConn);
    oDS.setTargetConnection(oConn);
    oDS.setAutoCommit(false);

    oCS.parse (sCompanyXml, oParams);
    oDS.parse (sContactXml, oParams);

	try {

	  LinkedList<String> oContacts = new LinkedList<String>();
	  LinkedList<String> oCompanies = new LinkedList<String>();

	  oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  oRSet = oStmt.executeQuery("SELECT gu_contact,gu_company,gu_workarea FROM k_contacts WHERE "+sContactsFilter);
	  while (oRSet.next()) {
	  	oContacts.add(oRSet.getString(1));
	  	String sCompany = oRSet.getString(2);
	  	if (!oRSet.wasNull()) {
	  	  if (!sTargetWorkArea.equals(oRSet.getString(3))) {
	  	    oCompanies.add(sCompany);
	  	  }
	  	}
	  } // wend
	  oRSet.close();
	  oRSet=null;
	  oStmt.close();
	  oStmt=null;

	  if (oCompanies.size()>0) {
	    oIter = oCompanies.listIterator();
	    while (oIter.hasNext()) {
	      oPKOr[0] = oIter.next();
	      oPKTr[0] = Gadgets.generateUUID();
          oCS.insert(oPKOr, oPKTr, 1);
	      oCS.commit();
          if (null!=oStrLog) oStrLog.append("New Company "+oPKTr[0]+" created successfully\n");
	    } // wend
	  } // fi

	  oIter = oContacts.listIterator();
	  while (oIter.hasNext()) {
	    oPKOr[0] = oIter.next();
	    oPKTr[0] = Gadgets.generateUUID();
        oDS.insert(oPKOr, oPKTr, 1);
	    oDS.commit();
        if (null!=oStrLog) oStrLog.append("New Contact "+oPKTr[0]+" created successfully\n");
	  } // wend

	} catch (SQLException sqle) {
      if (null!=oStrLog) oStrLog.append("SQLException at ModelManager.cloneContacts() "+sqle.getMessage()+"\n");
	  try { System.out.println(com.knowgate.debug.StackTraceUtil.getStackTrace(sqle));}
	  catch (Exception ignore){}
	} finally {
	  if (null!=oRSet) oRSet.close();
	  if (null!=oStmt) oStmt.close();
      oDS.clear();
      oCS.clear();
	}

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.cloneContacts()");
    }

  } // cloneContacts()

  // ----------------------------------------------------------

  /**
   * <p>Create a clone of a WorkArea</p>
   * WorkAreas are cloned by following instructions contained in
   * com/knowgate/hipergate/datamodel/scripts/<i>dbms</i>/workarea_clon.xml file.
   * @param sOriginWorkArea String of the form domain_name.workarea_name,
   * for example "MODEL.default_workarea"
   * @param sTargetWorkArea String of the form domain_name.workarea_name,
   * for example "TEST1.devel_workarea"
   * @return GUID of new WorkArea or <b>null</b> if clone could not be created.<br>
   * Error messages are written to internal ModelManager log and can be inspected by
   * calling report() method after cloneWorkArea()
   * @throws SQLException Most probably raised because data at model_default workarea is corrupted
   * @throws InstantiationException SAX parser is not properly installed
   * @throws IllegalAccessException SAX parser is not properly installed
   * @throws ClassNotFoundException SAX parser is not properly installed
   * @throws org.xml.sax.SAXException Parsing error at file workarea_clon.xml
   * @throws IOException
   * @see com.knowgate.workareas.WorkArea#delete(JDCConnection,String)
   */
  public String cloneWorkArea(String sOriginWorkArea, String sTargetWorkArea)
      throws SQLException,IOException,InstantiationException,IllegalAccessException,
             ClassNotFoundException, org.xml.sax.SAXException {

    PreparedStatement oPrep;
    Statement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.cloneWorkArea(" + sOriginWorkArea + "," + sTargetWorkArea + ")");
      DebugFile.incIdent();
    }

    if (null==oConn)
      throw new IllegalStateException("Not connected to database");

	com.knowgate.jdc.JDCConnection oJDC;
    // Get a JDC Connection Wrapper
    if (oConn instanceof com.knowgate.jdc.JDCConnection)
      oJDC = (com.knowgate.jdc.JDCConnection) oConn;
    else
      oJDC = new com.knowgate.jdc.JDCConnection(oConn, null);

    // Split Domain and WorkArea names
    String[] aOriginWrkA = com.knowgate.misc.Gadgets.split2 (sOriginWorkArea, '.');
    String[] aTargetWrkA = com.knowgate.misc.Gadgets.split2 (sTargetWorkArea, '.');

    int iSourceDomainId = com.knowgate.acl.ACLDomain.getIdFromName(oJDC, aOriginWrkA[0]);

    if (0==iSourceDomainId) {
      iErrors++;
      if (null!=oStrLog) oStrLog.append("Domain " + aOriginWrkA[0] + " not found\n");
      return null;
    }

    int iTargetDomainId = com.knowgate.acl.ACLDomain.getIdFromName(oJDC, aTargetWrkA[0]);

    if (0==iTargetDomainId) {
      iErrors++;
      if (null!=oStrLog) oStrLog.append("Domain " + aTargetWrkA[0] + " not found\n");
      return null;
    }

    String sSourceWorkAreaId = com.knowgate.workareas.WorkArea.getIdFromName(oJDC, iSourceDomainId, aOriginWrkA[1]);

    if (null==sSourceWorkAreaId) {
      iErrors++;
      if (null!=oStrLog) oStrLog.append("WorkArea " + aOriginWrkA[1] + " not found at Domain " + aOriginWrkA[0] + "\n");
      return null;
    }

    String sTargetWorkAreaId = com.knowgate.workareas.WorkArea.getIdFromName(oJDC, iTargetDomainId, aTargetWrkA[1]);

    if (null==sTargetWorkAreaId)
      sTargetWorkAreaId = Gadgets.generateUUID();

    if (null!=oStrLog) oStrLog.append("SELECT gu_owner,gu_admins FROM k_domains WHERE id_domain=" + String.valueOf(iTargetDomainId));

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    if (DebugFile.trace)
      DebugFile.writeln("Statement.executeQuery(SELECT gu_owner,gu_admins FROM k_domains WHERE id_domain=" + String.valueOf(iTargetDomainId) + ")");

    oRSet = oStmt.executeQuery("SELECT gu_owner,gu_admins FROM k_domains WHERE id_domain=" + String.valueOf(iTargetDomainId));
    oRSet.next();
    String sOwnerId = oRSet.getString(1);
    String sAdminId = oRSet.getString(2);
    oRSet.close();
    oStmt.close();

    Properties oParams = new Properties();
    oParams.put("SourceWorkAreaId", sSourceWorkAreaId);
    oParams.put("TargetDomainId", String.valueOf(iTargetDomainId));
    oParams.put("TargetWorkAreaId", sTargetWorkAreaId);
    oParams.put("TargetWorkAreaNm", String.valueOf(aTargetWrkA[1]));
    oParams.put("OwnerId", sOwnerId);

    com.knowgate.datacopy.DataStruct oDS = new com.knowgate.datacopy.DataStruct();

    oDS.setOriginConnection(oConn);
    oDS.setTargetConnection(oConn);

    switch (oJDC.getDataBaseProduct()) {

      case com.knowgate.jdc.JDCConnection.DBMS_MSSQL:
        oDS.parse (getResourceAsString("scripts/mssql/workarea_clon.xml", sEncoding), oParams);
        break;

      case com.knowgate.jdc.JDCConnection.DBMS_MYSQL:
        oDS.parse (getResourceAsString("scripts/mysql/workarea_clon.xml", sEncoding), oParams);
        break;

      case com.knowgate.jdc.JDCConnection.DBMS_ORACLE:
        oDS.parse (getResourceAsString("scripts/oracle/workarea_clon.xml", sEncoding), oParams);
        break;

      case com.knowgate.jdc.JDCConnection.DBMS_POSTGRESQL:
        oDS.parse (getResourceAsString("scripts/postgresql/workarea_clon.xml", sEncoding), oParams);
        break;
    }

    Object[] oPKOr = { };
    Object[] oPKTr = { };

    oDS.update(oPKOr, oPKTr, 0);
    oDS.clear();

    if (null!=oStrLog) oStrLog.append("New WorkArea " + sTargetWorkAreaId + " created successfully\n");

    // ***********************************************************
    // Give permissions to domain administrators over applications
    String sSQL;

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    LinkedList oApps = new LinkedList();
    sSQL = "SELECT id_app FROM k_x_app_workarea WHERE gu_workarea='" + sSourceWorkAreaId + "'";
    oRSet = oStmt.executeQuery(sSQL);
    while (oRSet.next()) oApps.add(oRSet.getObject(1));
    oRSet.close();
    oStmt.close();

    ListIterator oIter = oApps.listIterator();
    oPrep = oConn.prepareStatement("DELETE FROM k_x_app_workarea WHERE gu_workarea='" + sTargetWorkAreaId + "' AND id_app=?");
    while (oIter.hasNext()) {
      oPrep.setObject(1, oIter.next());
      oPrep.executeUpdate();
    }
    oPrep.close();
    oIter = null;
    oApps = null;

    oStmt = oConn.createStatement();
    sSQL = "INSERT INTO k_x_app_workarea (id_app,gu_workarea,gu_admins,path_files) SELECT id_app,'" + sTargetWorkAreaId + "','" + sAdminId + "','" + aTargetWrkA[1].toLowerCase() + "' FROM k_x_app_workarea  WHERE gu_workarea='" + sSourceWorkAreaId + "'";

    if (null!=oStrLog) oStrLog.append("Statement.executeUpdate(" + sSQL + ")\n");
    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");

    oStmt.executeUpdate(sSQL);

    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.cloneWorkArea() : " + sTargetWorkAreaId);
    }

    return sTargetWorkAreaId;
  } // cloneWorkArea()

  // ----------------------------------------------------------

  /**
   * <p>Drop WorkArea</p>
   * THIS METHOD DROPS ALL WORKAREA DATA. USE IT WITH CARE.
   * @param sDomainDotWorkAreaNm Domain Name and WorkArea Name with a middle dot. <i>Domain_Name.WorkArea_Name</i>
   * @param oProps Environment properties (as readed from hipergate.cnf)
   * @return GUID of droped WorkArea or <b>null</b> if WorkArea is not found.
   * @throws SQLException
   * @throws IOException
   * @see com.knowgate.workareas.WorkArea#delete (JDCConnection,String,java.util.Properties)
   */
  public String dropWorkArea(String sDomainDotWorkAreaNm, Properties oProps)
      throws SQLException,IOException,Exception {
    com.knowgate.jdc.JDCConnection oJDC = new com.knowgate.jdc.JDCConnection(oConn, null);

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.dropWorkArea(" + sDomainDotWorkAreaNm + ", ...)");
      DebugFile.incIdent();
    }

    String[] aDomWrkA = com.knowgate.misc.Gadgets.split2 (sDomainDotWorkAreaNm, '.');

    int iDomainId = com.knowgate.acl.ACLDomain.getIdFromName(oJDC, aDomWrkA[0]);

    String sWorkAreaId = com.knowgate.workareas.WorkArea.getIdFromName(oJDC, iDomainId, aDomWrkA[1]);

    if (null!=sWorkAreaId)
      if (oProps==null)
        com.knowgate.workareas.WorkArea.delete (oJDC, sWorkAreaId);
      else
        com.knowgate.workareas.WorkArea.delete (oJDC, sWorkAreaId, oProps);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.dropWorkArea() : " + sWorkAreaId);
    }

    return sWorkAreaId;
  } // dropWorkArea

  // ----------------------------------------------------------

  /**
   * <p>Drop Domain</p>
   * Drop a Domain, all its WorkAreas and associated data.<br>
   * Internally executes scripts/domain_drop.js Java BeanShell Script contained
   * inside JAR file under com/knowgate/hipergate/datamodel.<br>
   * THIS METHOD DROPS ALL DOMAIN DATA. USE IT WITH CARE.<br>
   * @param sDomainNm Name of domain to be droped.
   * @return Numeric identifier for droped domain.
   * @throws EvalError
   * @throws SQLException
   * @throws IOException
   * @see com.knowgate.acl.ACLDomain#delete(JDCConnection,int);
   */
  public int dropDomain(String sDomainNm) throws EvalError,SQLException,IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.dropDomain(" + sDomainNm + ")");
      DebugFile.incIdent();
    }

    Interpreter oInterpreter = new Interpreter();

    oInterpreter.set ("DomainNm", sDomainNm);
    oInterpreter.set ("DefaultConnection", oConn);

    oInterpreter.eval(getResourceAsString("scripts/domain_drop.js", sEncoding));

    Object obj = oInterpreter.get("ErrorCode");

    Integer oCodError = (Integer) oInterpreter.get("ErrorCode");

    if (oCodError.compareTo(new Integer (0))!=0) {
      iErrors++;
      if (null!=oStrLog) oStrLog.append("EvalError: " + oInterpreter.get("ErrorMessage") + "\n");

      throw new SQLException((String) oInterpreter.get("ErrorMessage"));
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.dropDomain()");
    }

    if  (oInterpreter.get("ReturnValue")!=null)
      return ( (Integer) oInterpreter.get("ReturnValue")).intValue();
    else
      return 0;
  } // dropDomain

  // ----------------------------------------------------------

  /**
   * <p>Create New Domain</p>
   * Internally executes scripts/domain_create.js Java BeanShell Script contained
   * inside JAR file under com/knowgate/hipergate/datamodel.<br>
   * @param sDomainNm New Domain Name
   * @return Autogenerated unique numeric identifier for new domain
   * @throws EvalError Java BeanShell script domain_create.js as a syntax error
   * @throws IOException
   * @throws FileNotFoundException
   * @throws SQLException
   */
  public int createDomain(String sDomainNm)
    throws EvalError, IOException, FileNotFoundException, SQLException {
    String sErrMsg;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.createDomain(" + sDomainNm + ")");
      DebugFile.incIdent();
    }

    int iDominId = 0;
    int iRetVal;

    Interpreter oInterpreter = new Interpreter();

    oInterpreter.set ("DomainNm", sDomainNm);
    oInterpreter.set ("DefaultConnection", oConn);
    oInterpreter.set ("AlternativeConnection", oConn);

    if (DebugFile.trace) DebugFile.writeln("Interpreter.eval(getResourceAsString(scripts/domain_create.js,"+sEncoding);

    oInterpreter.eval(getResourceAsString("scripts/domain_create.js", sEncoding));

    Object obj = oInterpreter.get("ErrorCode");

    Integer oCodError = (Integer) oInterpreter.get("ErrorCode");

    if (oCodError.intValue()!=0) {
      sErrMsg = (String) oInterpreter.get("ErrorMessage");
      iErrors++;
      if (null!=oStrLog) oStrLog.append("EvalError: " + sErrMsg + "\n");
      if (DebugFile.trace) {
        DebugFile.writeln("SQLException "+sErrMsg);
        DebugFile.decIdent();
      }
      throw new SQLException(sErrMsg);
    } // fi ()

    obj = oInterpreter.get("ReturnValue");

    if ( null != obj ) {
      iDominId = ( (Integer) obj).intValue();

      Statement oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE k_workareas SET nm_workarea='" + sDomainNm.toLowerCase() + "_default' WHERE id_domain=" + String.valueOf(iDominId) + " AND nm_workarea='model_default')");
      oStmt.executeUpdate("UPDATE k_workareas SET nm_workarea='" + sDomainNm.toLowerCase() + "_default' WHERE id_domain=" + String.valueOf(iDominId) + " AND nm_workarea='model_default'");
      oStmt.close();

      if (null!=oStrLog) oStrLog.append("New Domain " + oInterpreter.get("ReturnValue") + " created successfully\n");
      iRetVal = iDominId;
    }
    else {
      if (null!=oStrLog) oStrLog.append( oInterpreter.get("ErrorMessage") + ": Domain not created.");
      iRetVal = 0;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.createDomain() : " + String.valueOf(iRetVal));
    }

    return iRetVal;
  } // createDomain

  // ----------------------------------------------------------

  /**
   * <p>Create default categories for a user</p>
   * Internally executes scripts/user_categories_create.js Java BeanShell Script contained
   * inside JAR file under com/knowgate/hipergate/datamodel.<br>
   * @param sUserId User GUID
   * @return GUID of home category for given user
   * @throws EvalError Java BeanShell script user_categories_create.js as a syntax error
   * @throws IOException
   * @throws FileNotFoundException
   * @throws SQLException
   * @since 4.0
   */

  public String createCategoriesForUser(String sUserId)
    throws IOException, FileNotFoundException, SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.createCategoriesForUser(" + sUserId + ")");
      DebugFile.incIdent();
    }

    String sErrMsg = null;
    String sRetVal = null;
	Integer oCodError = new Integer(0);
	
    Interpreter oInterpreter = new Interpreter();
    try {
      oInterpreter.set ("UserId", sUserId);
      oInterpreter.set ("DefaultConnection", new JDCConnection(oConn,null));
      if (DebugFile.trace) DebugFile.writeln("Interpreter.eval(getResourceAsString(scripts/user_categories_create.js,"+sEncoding);
      oInterpreter.eval(getResourceAsString("scripts/user_categories_create.js", sEncoding));
      oCodError = (Integer) oInterpreter.get("ErrorCode");
      if (oCodError.intValue()==0) {
        sErrMsg = (String) oInterpreter.get("ErrorMessage");
        sRetVal = (String) oInterpreter.get("ReturnValue");
      }
    } catch (EvalError ee) {
      if (DebugFile.trace) {
        DebugFile.writeln("EvalError at user_categories_create.js "+ee.getMessage());
        DebugFile.decIdent();
      }
      throw new SQLException("EvalError at user_categories_create.js "+ee.getMessage());
    }

    if (oCodError.intValue()!=0) {
      iErrors++;
      if (null!=oStrLog) oStrLog.append("EvalError: " + sErrMsg + "\n");
      if (DebugFile.trace) {
        DebugFile.writeln("SQLException "+sErrMsg);
        DebugFile.decIdent();
      }
      throw new SQLException(sErrMsg);
    } // fi ()

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==sRetVal)
        DebugFile.writeln("End ModelManager.createCategoriesForUser() : null");
      else
        DebugFile.writeln("End ModelManager.createCategoriesForUser() : " + sRetVal);
    }

    return sRetVal;
  } // createCategoriesForUser

  // ----------------------------------------------------------

  private LinkedList listConstraints (Connection oJCon)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.listConstraints()");
      DebugFile.incIdent();
    }

    LinkedList oConstraintList = new LinkedList();
    Statement oStmt = oJCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    ResultSet oRSet = null;
    int iCount = 0;
    String sSQL = null;

    switch (iDbms) {
      case DBMS_MSSQL:
        sSQL = "SELECT foreignkey.name AS constraintname,foreigntable.name AS tablename FROM sysforeignkeys sysfks, sysobjects foreignkey, sysobjects foreigntable WHERE sysfks.constid=foreignkey.id AND sysfks.fkeyid=foreigntable.id";
        break;
      case DBMS_POSTGRESQL:
        sSQL = "SELECT c.conname,t.relname FROM pg_constraint c, pg_class t WHERE c.conrelid=t.oid AND c.contype='f'";
        break;
      case DBMS_ORACLE:
        sSQL = "SELECT CONSTRAINT_NAME,TABLE_NAME FROM USER_CONSTRAINTS WHERE R_CONSTRAINT_NAME IS NOT NULL";
        break;
    }

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

    oRSet = oStmt.executeQuery (sSQL);

    while (oRSet.next()) {
      oConstraintList.add (new Constraint(oRSet.getString(1),oRSet.getString(2)));
      iCount++;
    }

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ModelManager.listConstraints() : " + String.valueOf(iCount));
    }

    return oConstraintList;
  } // listConstraints

  // ----------------------------------------------------------

  private void upgrade1x2x (Connection jCon1, Connection jCon2, Properties oProps)
    throws IllegalStateException, SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ModelManager.upgrade1x2x()");
      DebugFile.incIdent();
    }

     String[] sTables = new String[]{
         // Kernel
         "k_classes","k_sequences",
         // Lookups
         "k_lu_meta_attrs",
         // Security
         "k_lu_permissions","k_domains","k_users","k_acl_groups","k_x_group_user","k_apps","k_workareas","k_x_app_workarea",
         // Jobs
         "k_lu_job_commands","k_lu_job_status","k_jobs","k_job_atoms","k_job_atoms_archived","k_queries",
         // Categories
         "k_categories","k_cat_labels","k_cat_root","k_cat_tree","k_x_cat_group_acl","k_x_cat_objs","k_x_cat_user_acl",
         // Thesauri
         "k_thesauri","k_thesauri_root","k_images","k_addresses_lookup","k_addresses","k_bank_accounts",
         // Products
         "k_products","k_prod_attr","k_prod_attrs","k_prod_keywords","k_prod_locats",
         // Addrbook
         "k_lu_fellow_titles","k_fellows_lookup","k_fellows", "k_fellows_attach",
         "k_rooms_lookup","k_rooms",
         "k_meetings","k_x_meeting_contact","k_x_meeting_fellow","k_x_meeting_room",
         // Forums
         "k_newsgroups","k_newsmsgs",
         // CRM
         "k_companies_lookup","k_companies","k_companies_attrs","k_x_company_addr","k_x_company_bank",
         "k_contacts_lookup","k_contacts","k_contact_attachs","k_contact_notes","k_contacts_attrs","k_x_contact_addr","k_x_contact_bank",
         "k_oportunities_lookup","k_oportunities","k_oportunities_attrs",
         "k_sales_men","k_sales_objectives",
         // Lists
         "k_lists","k_list_members",
         // Webbuilder
         "k_microsites","k_pagesets_lookup","k_pagesets","k_pageset_pages",
         // Projects
         "k_projects_lookup","k_projects",
         "k_duties_lookup","k_duties","k_duties_attach","k_x_duty_resource",
         "k_bugs_lookup","k_bugs","k_bugs_attach",
         // Shop
         "k_shops","k_warehouses","k_sale_points",
         "k_orders_lookup","k_orders","k_order_lines",
         "k_invoices_lookup","k_invoices","k_invoice_schedules","k_invoice_lines",
         "k_x_orders_invoices" };

     final int iTables = sTables.length;

     Statement oStmt;

     // ********************************************************
     // Drop f1_domains foreign key constraint before proceeding

     if (DebugFile.trace) {
       DebugFile.writeln("Statement.execute(ALTER TABLE k_domains DROP CONSTRAINT f1_domains)");
     }

     oStmt = jCon2.createStatement();
     oStmt.execute("ALTER TABLE k_domains DROP CONSTRAINT f1_domains");
     oStmt.close();

     // ****************************************************
     // Disable all foreign key constraint before proceeding

     LinkedList oConstraints = listConstraints(jCon2);

     ListIterator oIter;
     Constraint oCons;
     String sSQL = null;

     try {

       oStmt = oConn.createStatement();

       oIter = oConstraints.listIterator();

       while (oIter.hasNext()) {
         oCons = (Constraint) oIter.next();

         switch (iDbms) {
           case DBMS_MSSQL:
             sSQL = "ALTER TABLE " + oCons.tablename + " NOCHECK CONSTRAINT " + oCons.constraintname;
             break;
           case DBMS_POSTGRESQL:
             sSQL = "UPDATE pg_class SET reltriggers=0 WHERE relname = '" + oCons.tablename + "'";
             break;
           case DBMS_ORACLE:
             sSQL = "ALTER TABLE " + oCons.tablename + " DISABLE CONSTRAINT " + oCons.constraintname;
             break;
         }

         if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");

         oStmt.execute(sSQL);
       } // wend
       oStmt.close();
       sSQL = null;
     }
     catch (SQLException sqle) {
       DebugFile.writeln("SQLException: " + sqle.getMessage() + " " + sSQL + "\n");
       iErrors++;
       if (null!=oStrLog) oStrLog.append("SQLException: " + sqle.getMessage() + " " + sSQL + "\n");
     }

     // ********************************************
     // Copy data from 1.x version datamodel to v2.0

     com.knowgate.datacopy.CopyRegisters oCopy = new com.knowgate.datacopy.CopyRegisters(oProps.getProperty("schema1"), jCon1.getCatalog());

     for (int t=0; t<iTables; t++) {
       try {
         if (DBMS_ORACLE==iDbms) sTables[t] = sTables[t].toUpperCase();

         int iAppended = oCopy.append (jCon1, jCon2, sTables[t], sTables[t], null);

         if (null!=oStrLog) oStrLog.append(String.valueOf(iAppended) + " registers appended or updated at table " + sTables[t] + "\n");
       }
       catch (SQLException sqle) {
         DebugFile.writeln("SQLException: CopyRegisters.append(" + sTables[t] + ") " + sqle.getMessage() + "\n");
         DebugFile.decIdent();
         iErrors++;
         if (null!=oStrLog) oStrLog.append("SQLException: CopyRegisters.append(" + sTables[t] + ") " + sqle.getMessage() + " " + "\n");
       }
     } // next (t)

     // ************************************
     // Additional tables witout primary key

     PreparedStatement oWrtStm;
     Statement oReadStm;
     ResultSet oReadSet;

     oWrtStm = jCon2.prepareStatement("INSERT INTO k_cat_expand (gu_rootcat,gu_category,od_level,od_walk,gu_parent_cat) VALUES (?,?,?,?,?)");

     oReadStm = jCon1.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
     oReadSet = oReadStm.executeQuery("SELECT gu_rootcat,gu_category,od_level,od_walk,gu_parent_cat FROM k_cat_expand");

     while (oReadSet.next()) {
       oWrtStm.setObject(1, oReadSet.getObject(1));
       oWrtStm.setObject(2, oReadSet.getObject(2));
       oWrtStm.setObject(3, oReadSet.getObject(3));
       oWrtStm.setObject(4, oReadSet.getObject(4));
       oWrtStm.setObject(5, oReadSet.getObject(5));
       oWrtStm.executeUpdate();
     } // wend

     oReadSet.close();
     oReadStm.close();
     oWrtStm.close();

     oWrtStm = jCon2.prepareStatement("INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES (?,?,?,?,?,?)");

     oReadStm = jCon1.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
     oReadSet = oReadStm.executeQuery("SELECT gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent FROM k_project_expand");

     while (oReadSet.next()) {
       oWrtStm.setObject(1, oReadSet.getObject(1));
       oWrtStm.setObject(2, oReadSet.getObject(2));
       oWrtStm.setObject(3, oReadSet.getObject(3));
       oWrtStm.setObject(4, oReadSet.getObject(4));
       oWrtStm.setObject(5, oReadSet.getObject(5));
       oWrtStm.setObject(6, oReadSet.getObject(6));
       oWrtStm.executeUpdate();
     } // wend

     oReadSet.close();
     oReadStm.close();
     oWrtStm.close();

     oWrtStm = jCon2.prepareStatement("INSERT INTO k_x_list_members (gu_list,tx_email,tx_name,tx_surname,tx_salutation,bo_active,dt_created,tp_member,gu_company,gu_contact,id_format,dt_modified) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");

     oReadStm = jCon1.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
     oReadSet = oReadStm.executeQuery("SELECT gu_list,tx_email,tx_name,tx_surname,tx_salutation,bo_active,dt_created,tp_member,gu_company,gu_contact,id_format,dt_modified FROM k_x_list_members");

     while (oReadSet.next()) {
       oWrtStm.setObject(1, oReadSet.getObject(1));
       oWrtStm.setObject(2, oReadSet.getObject(2));
       oWrtStm.setObject(3, oReadSet.getObject(3));
       oWrtStm.setObject(4, oReadSet.getObject(4));
       oWrtStm.setObject(5, oReadSet.getObject(5));
       oWrtStm.setObject(6, oReadSet.getObject(6));
       oWrtStm.setObject(7, oReadSet.getObject(7));
       oWrtStm.setObject(8, oReadSet.getObject(8));
       oWrtStm.setObject(9, oReadSet.getObject(9));
       oWrtStm.setObject(10, oReadSet.getObject(10));
       oWrtStm.setObject(11, oReadSet.getObject(11));
       oWrtStm.setObject(12, oReadSet.getObject(12));
       oWrtStm.executeUpdate();
     } // wend

     oReadSet.close();
     oReadStm.close();
     oWrtStm.close();

     // **************************************************
     // Enable all foreign key constraint after processing

     try {

       oStmt = oConn.createStatement();

       oIter = oConstraints.listIterator();

       while (oIter.hasNext()) {
         oCons = (Constraint) oIter.next();

         switch (iDbms) {
           case DBMS_MSSQL:
             sSQL = "ALTER TABLE " + oCons.tablename + " CHECK CONSTRAINT " + oCons.constraintname;
             break;
           case DBMS_POSTGRESQL:
             sSQL = "UPDATE pg_class SET reltriggers = COUNT(*) FROM pg_trigger WHERE pg_class.oid=tgrelid AND relname='" + oCons.tablename + "'";
             break;
           case DBMS_ORACLE:
             sSQL = "ALTER TABLE " + oCons.tablename + " ENABLE CONSTRAINT " + oCons.constraintname;
             break;
         }

         if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");

         oStmt.execute(sSQL);
       } // wend
       oStmt.close();
       sSQL = null;
     }
     catch (SQLException sqle) {
       DebugFile.writeln("SQLException: " + sqle.getMessage() + " " + sSQL + "\n");
       iErrors++;
       if (null!=oStrLog) oStrLog.append("SQLException: " + sqle.getMessage() + " " + sSQL + "\n");
     }

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End ModelManager.upgrade1x2x()");
     }
  } // upgrade1x2x

  // ----------------------------------------------------------

  public void upgrade(String sOldVersion, String sNewVersion, Properties oProps)
    throws IllegalStateException, SQLException, FileNotFoundException, IOException {

    Statement oStmt;
    ResultSet oRSet;
    String sDetectedVersion;

    try {
      com.knowgate.jdc.JDCConnection jCon = new com.knowgate.jdc.JDCConnection(getConnection(), null);

      if (sOldVersion.equals("105") && sNewVersion.equals("110")) {
        executeBulk("upgrade/" + sDbms + "/" + sOldVersion + "-" + sNewVersion + ".ddl", BULK_STATEMENTS);
      }
      else if ((sOldVersion.equals("200") || sOldVersion.equals("201")) && sNewVersion.equals("202")) {
        executeBulk("upgrade/" + sDbms + "/200-202.ddl", BULK_PLSQL);
      }
      else if ((sOldVersion.equals("105") || sOldVersion.equals("110")) &&
               (sNewVersion.equals("200") || sNewVersion.equals("201") || sNewVersion.equals("202"))) {

        Connection jCon2 = getConnection();

        oStmt = jCon2.createStatement();

        try {
          oRSet = oStmt.executeQuery("SELECT vs_stamp FROM k_version");
          if (oRSet.next())
            sDetectedVersion = oRSet.getString(1);
          else
            sDetectedVersion = "unknown";
          oRSet.close();
        }
        catch (SQLException sqle) {
          sDetectedVersion = "1.0.5";
        }
        oStmt.close();

        if (DebugFile.trace) {
          DebugFile.writeln("Target model current version is " + sDetectedVersion);
        }

        if (!sDetectedVersion.startsWith("2.")) {
          throw new SQLException("Target database cannot be recognized as hipergate 2.x version");
        }

        if (DebugFile.trace) {
          DebugFile.writeln("DriverManager.getConnection(" + oProps.getProperty("dburl1") + "," + oProps.getProperty("dbuser1") + ")");
        }

        Connection jCon1 = DriverManager.getConnection(oProps.getProperty("dburl1"), oProps.getProperty("dbuser1"), oProps.getProperty("dbpassword1"));

        oStmt = jCon1.createStatement();

        try {
          oRSet = oStmt.executeQuery("SELECT vs_stamp FROM k_version");
          if (oRSet.next())
            sDetectedVersion = oRSet.getString(1);
          else
            sDetectedVersion = "unknown";
          oRSet.close();
        }
        catch (SQLException sqle) {
          sDetectedVersion = "1.0.5";
        }
        oStmt.close();

        if (DebugFile.trace) {
          DebugFile.writeln("Source model current version is " + sDetectedVersion);
        }

        if (!sDetectedVersion.startsWith("1.")) {
          jCon1.close();
          throw new SQLException("Source database cannot be recognized as hipergate 1.x version");
        }

        jCon1.setAutoCommit(true);

        upgrade1x2x (jCon1, jCon2, oProps);

        jCon1.close();
      }
      else if ((sOldVersion.equals("200") || sOldVersion.equals("201") ||
                sOldVersion.equals("202") || sOldVersion.equals("203") ||
                sOldVersion.equals("204"))&& sNewVersion.equals("208") ) {

         if (sOldVersion.equals("200") || sOldVersion.equals("201"))
           executeBulk("upgrade/" + sDbms + "/200-202.ddl", BULK_PLSQL);

         if (iDbms==DBMS_MSSQL) {
           executeBulk("drop/mssql/lists.sql", BULK_STATEMENTS);
           executeBulk("procedures/mssql/lists.ddl", BULK_PLSQL);
         }
      }
      else if ((sOldVersion.equals("200") || sOldVersion.equals("201") ||
                sOldVersion.equals("202") || sOldVersion.equals("203") ||
                sOldVersion.equals("204") || sNewVersion.equals("208"))&&
                sNewVersion.equals("210")) {
         executeBulk("upgrade/" + sDbms + "/208-210.ddl", BULK_PLSQL);
         create("hipermail");
         if (iDbms==DBMS_ORACLE) recompileOrcl();
      }
      else if (sOldVersion.equals("210") &&
               sNewVersion.equals("300")) {
         executeBulk("upgrade/" + sDbms + "/210-300.ddl", BULK_PLSQL);
         if (iDbms==DBMS_ORACLE) recompileOrcl();
      }
      else if (sOldVersion.equals("300") &&
               sNewVersion.equals("400")) {
        executeBulk("upgrade/" + sDbms + "/300-400.ddl", BULK_PLSQL);
        if (iDbms==DBMS_ORACLE) recompileOrcl();
      }
      else if (sOldVersion.equals("400") &&
               sNewVersion.equals("500")) {
        executeBulk("upgrade/" + sDbms + "/400-500.ddl", BULK_PLSQL);
        if (iDbms==DBMS_ORACLE) recompileOrcl();
      }
      else if (sOldVersion.equals("500") &&
               sNewVersion.equals("550")) {
        executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
        if (iDbms==DBMS_ORACLE) recompileOrcl();
      }
      else if (sOldVersion.equals("400") &&
               sNewVersion.equals("600")) {
        executeBulk("upgrade/" + sDbms + "/400-500.ddl", BULK_PLSQL);
        executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
        executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
        executeBulk("upgrade/" + sDbms + "/550-600.ddl", BULK_PLSQL);
        if (iDbms==DBMS_ORACLE) recompileOrcl();
      }
      else if (sOldVersion.equals("500") &&
               sNewVersion.equals("600")) {
        executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
        executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
        executeBulk("upgrade/" + sDbms + "/550-600.ddl", BULK_PLSQL);
        if (iDbms==DBMS_ORACLE) recompileOrcl();
      }
      else if (sOldVersion.equals("550") &&
               sNewVersion.equals("600")) {
        executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
        executeBulk("upgrade/" + sDbms + "/550-600.ddl", BULK_PLSQL);
        if (iDbms==DBMS_ORACLE) recompileOrcl();
      }
      else if (sNewVersion.equals("700")) {
        if (sOldVersion.equals("400")) {
          executeBulk("upgrade/" + sDbms + "/400-500.ddl", BULK_PLSQL);
          executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
          executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
          executeBulk("upgrade/" + sDbms + "/550-600.ddl", BULK_PLSQL);
          executeBulk("upgrade/" + sDbms + "/600-700.ddl", BULK_PLSQL);
        } else if (sOldVersion.equals("500")) {
          executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
          executeBulk("upgrade/" + sDbms + "/500-550.ddl", BULK_PLSQL);
          executeBulk("upgrade/" + sDbms + "/550-600.ddl", BULK_PLSQL);
          executeBulk("upgrade/" + sDbms + "/600-700.ddl", BULK_PLSQL);
        } else if (sOldVersion.equals("550")) {
          executeBulk("upgrade/" + sDbms + "/550-600.ddl", BULK_PLSQL);
          executeBulk("upgrade/" + sDbms + "/600-700.ddl", BULK_PLSQL);
        } else if (sOldVersion.equals("600"))
          executeBulk("upgrade/" + sDbms + "/600-700.ddl", BULK_PLSQL);
        if (iDbms==DBMS_ORACLE) recompileOrcl();
      }
      else
        throw new SQLException ("ERROR: ModelManager.upgrade() Source or Target version not recognized.");

    } catch (InterruptedException ie) {
      if (null!=oStrLog) oStrLog.append("STOP ON ERROR SET TO ON: SCRIPT INTERRUPTED\n");
    }
  } // upgrade
  
  // ----------------------------------------------------------

  public int fixTranslationColumns() throws SQLException {
     String[] aTableLookUps = new String[]{"k_addresses_lookup","k_bank_accounts_lookup","k_bugs_lookup","k_companies_lookup","k_contacts_lookup","k_courses_lookup","k_datasheets_lookup","k_despatch_advices_lookup","k_duties_lookup","k_examples_lookup","k_fellows_lookup","k_invoices_lookup","k_meetings_lookup","k_oportunities_lookup","k_orders_lookup","k_pagesets_lookup","k_prod_fares_lookup","k_projects_lookup","k_rooms_lookup","k_sales_men_lookup","k_subjects_lookup","k_suppliers_lookup","k_thesauri_lookup","k_to_do_lookup","k_welcome_packs_lookup"};
	 String[] aTrColLookUps = Gadgets.split(DBLanguages.getLookupTranslationsColumnList(),',');
	 final int nTrColCount  = aTrColLookUps.length;
	 int nFixes = 0;
	 Statement oAltr = oConn.createStatement();
	 Statement oStmt = oConn.createStatement();
	 ResultSet oRSet;
	 ResultSetMetaData oMDat;
	 for (int t=0; t<aTableLookUps.length; t++) {
	   try {
	     oRSet = oStmt.executeQuery("SELECT * FROM " + aTableLookUps[t]+" WHERE 1=0");
	   } catch (SQLException sqle) {
	     oRSet = null;
	   }
	   if (null!=oRSet) {
	     oMDat = oRSet.getMetaData();
	     int nTbColCount = oMDat.getColumnCount();
	     for (int tc=0; tc<nTrColCount; tc++) {
	       boolean bFound = false;
	       for (int tb=1; tb<=nTbColCount && !bFound; tb++) {
	         bFound = oMDat.getColumnName(tb).equalsIgnoreCase(aTrColLookUps[tc]);
	       } //next
	       if (!bFound) {
	         oAltr.execute("ALTER TABLE "+aTableLookUps[t]+" ADD "+aTrColLookUps[tc]+" "+VarChar[iDbms]+"(50) NULL");
		     if (null!=oStrLog) oStrLog.append("Added column " + aTrColLookUps[tc] + "to table " + aTableLookUps[t] + "\n");
		     nFixes++;
	       } // fi
	     } // next
	     oRSet.close();
	   } // fi (oRSet)
	 } // next
	 oStmt.close();
	 oAltr.close();
	 return nFixes; 
  } // fixTranslationColumns

  // ----------------------------------------------------------

  private static void printUsage() {
    System.out.println("");
    System.out.println("Usage:\n");
    System.out.println("Creating and dropping the database");
    System.out.println("ModelManager cnf_path command {database|all|module_name|domain|workarea} [domain_name|domain_name.workarea_name] [verbose]\n");
    System.out.println("Cloning workareas");
    System.out.println("ModelManager cnf_path clone workarea domain_name.workarea_name domain_name.workarea_name [verbose]\n");
    System.out.println("Executing a SQL script");
    System.out.println("ModelManager cnf_path execute sql_script_path\n");
    System.out.println("Generating SQL scripts for a table data");
    System.out.println("ModelManager cnf_path script table_name output_path\n");
    System.out.println("Parameters");
    System.out.println("cnf_path: path to hipergate.cnf file ej. /opt/knowgate/hipergate.cnf");
    System.out.println("output_path: path where SQL statements for inserting data on a table will be generated ej. /tmp/x_companies.sql");
    System.out.println("command: { create | drop | clone | execute }");
    System.out.println("module: { all | kernel | lookups | security | jobs | categories | addrbook | webbuilder | crm | shops | projtrack }");
    System.out.println("domain_name: name of domain to create or drop");
    System.out.println("workarea_name: name of workarea to drop");
    System.out.println("verbose: show executed SQL");
    System.out.println("Fixing missing translation columns");
    System.out.println("ModelManager cnf_path fixtr\n");
  }

  // ----------------------------------------------------------

  /**
   * <p>Method for calling ModelManager from the command line</p>
   * Usage:<br>
   * java com.knowgate.hipergate.datamodel.ModelManager /etc/hipergate.cnf <i>command</i> <i>module</i> [domain_name|domain_name.workarea_name] [verbose]<br>
   * Path "/etc/hipergate.cnf" must point to where hipergate.cnf file is located.<br>
   * @param argv Array of Strings with 3 to 6 elements<br>
   * <b>argv[0]</b>: (Command) May be { bulkload | create | drop | clone | execute | script | truncate | upgrade }<br>
   * <b>argv[1]</b>: (Object) May be { database | <i>a module_name</i> | all | domain | workarea }<br>
   * Valid module names are: { { all | kernel | lookups | security | jobs | categories | addrbook | webbuilder | crm | shops | projtrack }<br>
   * "all" will create or drop all modules.<br>
   * Example for initial database creation :<br>
   * java com.knowgate.hipergate.datamodel.ModelManager /etc/hipergate.cnf create database<br>
   * Example for version upgrade script:<br>
   * java com.knowgate.hipergate.datamodel.ModelManager /etc/hipergate.cnf upgrade 105 110 verbose<br>
   * java com.knowgate.hipergate.datamodel.ModelManager /etc/hipergate.cnf execute /tmp/statements.sql verbose<br>
   * Example for generating a SQL script for a table :<br>
   * java com.knowgate.hipergate.datamodel.ModelManager /etc/hipergate.cnf script k_lu_languages /tmp/langs.sql<br>
   * Example for loading a text file delimited by tabs and line feeds into a table :<br>
   * java com.knowgate.hipergate.datamodel.ModelManager /etc/hipergate.cnf bulkload k_tablename /tmp/data.txt UTF-8 verbose<br>
   * Example for truncating a table :<br>
   * java com.knowgate.hipergate.datamodel.ModelManager /etc/hipergate.cnf truncate k_tablename<br>
   * Example for fixing missing translation columns :<br>
   * java com.knowgate.hipergate.datamodel.ModelManager /etc/hipergate.cnf fixtr<br>
   */
  public static void main(String[] argv) {
    ModelManager oMan = new ModelManager();
    FileInputStream oInStrm;
    Properties oProps;

    if (argv.length<2 || argv.length>6)
      printUsage();
    else if (!argv[1].equals("bulkload") && !argv[1].equals("create") && !argv[1].equals("drop") && !argv[1].equals("clone") && !argv[1].equals("execute") && !argv[1].equals("script") && !argv[1].equals("upgrade") && !argv[1].equals("fixtr") && !argv[1].equals("truncate"))
      printUsage();
    else if ((argv[1].equals("create") || argv[1].equals("drop")) && argv.length>5)
      printUsage();
    else if (argv[1].equals("bulkload") && argv.length>6)
      printUsage();
    else if (argv[1].equals("execute") && argv.length>4)
      printUsage();
    else if ((argv[1].equals("script") || argv[1].equals("truncate")) && argv.length>4)
      printUsage();
    else if (argv[1].equals("clone") && argv.length<5)
      printUsage();
    else if (argv[1].equals("upgrade") && argv.length<4)
      printUsage();
    else {
      oProps = new Properties();
      oInStrm = null;

      try {
        oInStrm = new FileInputStream(argv[0]);
        oProps.load(oInStrm);
        oInStrm.close();

        oMan.connect (oProps.getProperty("driver"), oProps.getProperty("dburl"), oProps.getProperty("schema",""), oProps.getProperty("dbuser"), oProps.getProperty("dbpassword"));

        if (argv[1].equals("bulkload")) {
          if (argv.length>4) {
            if (argv[4].equalsIgnoreCase("verbose"))
              oMan.bulkLoad(argv[2],argv[3],"UTF-8");
            else
              oMan.bulkLoad(argv[2],argv[3],argv[4]);            	
          }
          else {
            oMan.bulkLoad(argv[2],argv[3],"UTF-8");
          }
        }
        else if (argv[1].equals("create")) {

          if (argv[2].equals("domain"))
            if (argv.length<4)
              printUsage();
            else if (argv[3].equals("verbose"))
              printUsage();
            else
              oMan.createDomain(argv[3]);

          else if (argv[2].equals("all"))

            oMan.createAll();

          else if (argv[2].equals("database")) {

            if (oProps.getProperty("dburl1")==null) {
              oMan.createDefaultDatabase();
            }
            else {
              oMan.createAll();
              oMan.upgrade("110", "200", oProps);
            }
          }
          else
            oMan.create (argv[2]);

        } else if (argv[1].equals("clone")) {

          if (argv[2].equals("workarea")) {
            oMan.cloneWorkArea(argv[3], argv[4]);
          }
          else
            printUsage();

        } else if (argv[1].equals("drop")) {

          if (argv[2].equals("domain"))
            if (argv.length<4)
              printUsage();
            else if (argv[3].equals("verbose"))
              printUsage();
            else
              oMan.dropDomain(argv[3]);

          if (argv[2].equals("workarea"))
            if (argv.length<4)
              printUsage();
            else if (argv[3].equals("verbose"))
              printUsage();
            else if (argv[3].indexOf('.')<0)
              printUsage();
            else
              oMan.dropWorkArea(argv[3], oProps);

          else if (argv[2].equals("all") || argv[2].equals("database"))
            oMan.dropAll();
          else
            oMan.drop (argv[2]);

        } else if (argv[1].equals("execute")) {
          oMan.executeBulk(argv[2], FILE_STATEMENTS);
        }
         else if (argv[1].equals("script")) {
          oMan.scriptData(argv[2], null, argv[3]);
        }
        else if (argv[1].equals("upgrade")) {
          oMan.upgrade(argv[2],argv[3], oProps);
        }
        else if (argv[1].equals("fixtr")) {
          int nFixes = oMan.fixTranslationColumns();
          System.out.println(String.valueOf(nFixes)+" columns fixed");
        }
         else if (argv[1].equals("truncate")) {
          oMan.truncate(argv[2]);
        }

        switch (argv.length) {
          case 3:
            if (argv[2].equals("verbose"))
              if (null!=oMan.oStrLog) System.out.println(oMan.oStrLog.toString());
            break;
          case 4:
            if (argv[3].equals("verbose"))
              if (null!=oMan.oStrLog) System.out.println(oMan.oStrLog.toString());
            break;
          case 5:
            if (argv[4].equals("verbose"))
              if (null!=oMan.oStrLog) System.out.println(oMan.oStrLog.toString());
            break;
          case 6:
            if (argv[5].equals("verbose"))
              if (null!=oMan.oStrLog) System.out.println(oMan.oStrLog.toString());
            break;
        }

        oMan.disconnect();
      }
      catch (org.xml.sax.SAXException saxe) {
        System.out.print(argv[0] + " SAXException " + saxe.getMessage());
      }
      catch (InstantiationException inste) {
        System.out.print(argv[0] + " InstantiationException " + inste.getMessage());
      }
      catch (IllegalAccessException ille) {
        System.out.print(argv[0] + " IllegalAccessException " + ille.getMessage());
      }
      catch (FileNotFoundException fnfe) {
        System.out.print(argv[0] + " FileNotFoundException " + fnfe.getMessage());
      }
      catch (IOException ioe) {
        System.out.print("IOException " + ioe.getMessage() + " not found");
      }
      catch (ClassNotFoundException cnfe) {
        System.out.print(cnfe.getMessage() + " Check class for JDBC driver " + oProps.getProperty("driver"));
      }
      catch (SQLException sqle) {
        System.out.println(sqle.getMessage());
      }
      catch (EvalError eval) {
        System.out.print("EvalError: " + eval.getErrorText() + "\n at line " + String.valueOf(eval.getErrorLineNumber()) + "\n" + eval.getScriptStackTrace() + "\n");
      }
      catch (ArrayIndexOutOfBoundsException aiob) {
        System.out.print("ArrayIndexOutOfBoundsException " + aiob.getMessage());
      }
      catch (NullPointerException npe) {
        System.out.print("NullPointerException " + npe.getMessage());
      }
      catch (Exception xcpt) {
        System.out.print("Exception " + xcpt.getMessage());
      }
    }
  }

} // ModelManager
