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

import java.io.IOException;
import java.io.File;
import java.io.InputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.StringBufferInputStream;
import java.io.ObjectOutputStream;
import java.io.ObjectInputStream;
import java.io.FileInputStream;

import java.sql.SQLException;
import java.sql.DatabaseMetaData;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.sql.Types;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.ListIterator;

import com.knowgate.debug.*;
import com.knowgate.jdc.*;
import com.knowgate.misc.Gadgets;

import com.knowgate.storage.Column;
import com.knowgate.storage.RDBMS;

/**
 * <p>A database table as a Java Object</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class DBTable {

  /**
   * <p>Constructor</p>
   * Catalog and schema names are set to <b>null</b>.<br>
   * Table index is set to 1.
   * @param sSchemaName Database schema name
  */

  public DBTable(String sTableName) {
    sCatalog = null;
    sSchema = null;
    sName = sTableName;
    iHashCode = 1;
  }

  /**
   * Constructor
   * @param sCatalogName Database catalog name
   * @param sSchemaName Database schema name
   * @param sTableName Database table name (not qualified)
   * @param iIndex Ordinal number identifier for table
   */

  public DBTable(String sCatalogName, String sSchemaName, String sTableName, int iIndex) {
    sName = sTableName;
    sCatalog = sCatalogName;
    sSchema = sSchemaName;
    iHashCode = iIndex;
  }

  // ---------------------------------------------------------------------------

  /**
   * @return Column Count for this table
   * @throws IllegalStateException if columns list has not been initialized
   */

  public int columnCount() throws IllegalStateException {
    if (null==oColumns)
      throw new IllegalStateException("Table columns list not initialized");
    return oColumns.size();
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Load a single table register into a Java HashMap</p>
   * @param oConn Database Connection
   * @param PKValues Primary key values of register to be readed, in the same order as they appear in table source.
   * @param AllValues Output parameter. Readed values.
   * @return <b>true</b> if register was found <b>false</b> otherwise.
   * @throws NullPointerException If all objects in PKValues array are null (only debug version)
   * @throws IllegalStateException if columns list has not been initialized
   * @throws SQLException
   */
  public boolean loadRegister(JDCConnection oConn, Object[] PKValues, HashMap AllValues)
    throws SQLException, NullPointerException, IllegalStateException {
    int c;
    boolean bFound;
    Object oVal;
    DBColumn oDBCol;
    ListIterator<DBColumn> oColIterator;
    PreparedStatement oStmt = null;
    ResultSet oRSet = null;

    if (null==oColumns)
      throw new IllegalStateException("DBTable.loadRegister() Table columns list not initialized");

    if (null==oConn)
      throw new NullPointerException("DBTable.loadRegister() Connection is null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBTable.loadRegister([Connection:"+oConn.pid()+"], Object[], [HashMap])" );
      DebugFile.incIdent();

      boolean bAllNull = true;
      for (int n=0; n<PKValues.length; n++)
        bAllNull &= (PKValues[n]==null);

      if (bAllNull)
        throw new NullPointerException(sName + " cannot retrieve register, value supplied for primary key is NULL.");
    }

    if (sSelect==null) {
      throw new SQLException("Primary key not found", "42S12");
    }

    AllValues.clear();

    bFound = false;

    try {

      if (DebugFile.trace) DebugFile.writeln("  Connection.prepareStatement(" + sSelect + ")");

      // Prepare SELECT sentence for reading
      oStmt = oConn.prepareStatement(sSelect);

      try {
        if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL)
          oStmt.setQueryTimeout(10);
      }
      catch (SQLException sqle) {
        if (DebugFile.trace) DebugFile.writeln("Error at PreparedStatement.setQueryTimeout(10)" + sqle.getMessage());
      }


      // Bind primary key values
      for (int p=0; p<oPrimaryKeys.size(); p++) {
        if (DebugFile.trace) DebugFile.writeln("  binding primary key " + PKValues[p] + ".");

        oConn.bindParameter(oStmt, p+1, PKValues[p]);

      } // next

      if (DebugFile.trace) DebugFile.writeln("  Connection.executeQuery()");

      oRSet = oStmt.executeQuery();

      if (oRSet.next()) {
        if (DebugFile.trace) DebugFile.writeln("  ResultSet.next()");

        bFound = true;

        // Iterate throught readed columns
        // and store readed values at AllValues
        oColIterator = oColumns.listIterator();

        c = 1;
        while (oColIterator.hasNext()) {
          oVal = oRSet.getObject(c++);
          oDBCol = oColIterator.next();
          if (oRSet.wasNull()) {
          	if (DebugFile.trace) DebugFile.writeln("Value of column "+oDBCol.getName()+" is NULL");
          } else {
            AllValues.put(oDBCol.getName(), oVal);
          	if (DebugFile.trace) DebugFile.writeln("Value of column "+oDBCol.getName()+" is "+oVal);
          }// fi
        }
      }

      if (DebugFile.trace) DebugFile.writeln("  ResultSet.close()");

      oRSet.close();
      oRSet = null;

      oStmt.close();
      oStmt = null;
    }
    catch (SQLException sqle) {
      try {
        if (null!=oRSet) oRSet.close();
        if (null!=oStmt) oStmt.close();
      }
      catch (Exception ignore) { }

      throw new SQLException(sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBTable.loadRegister() : " + (bFound ? "true" : "false"));
    }

    return bFound;

  } // loadRegister

  // ---------------------------------------------------------------------------

  /**
   * <p>Store a single register at the database representing a Java Object</p>
   * for register containing LONGVARBINARY, IMAGE, BYTEA or BLOB fields use
   * storeRegisterLong() method.
   * Columns named "dt_created" are invisible for storeRegister() method so that
   * register creation timestamp is not altered by afterwards updates.
   * @param oConn Database Connection
   * @param AllValues Values to assign to fields.
   * @return <b>true</b> if register was inserted for first time, <false> if it was updated.
   * @throws SQLException
   */

  public boolean storeRegister(JDCConnection oConn, HashMap AllValues) throws SQLException {
    int c;
    boolean bNewRow = false;
    DBColumn oCol;
    String sCol;
    String sSQL = "";
    ListIterator<DBColumn> oColIterator;
    ListIterator<String> oKeyIterator;
    int iAffected = 0;
    PreparedStatement oStmt = null;

    if (null==oConn)
      throw new NullPointerException("DBTable.storeRegister() Connection is null");

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBTable.storeRegister([Connection:"+oConn.pid()+"], {" + AllValues.toString() + "})" );
      DebugFile.incIdent();
      }

    try {
      if (null!=sUpdate) {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sUpdate + ")");

        sSQL = sUpdate;

        oStmt = oConn.prepareStatement(sSQL);

        try {
          if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL)
        	oStmt.setQueryTimeout(10);
        } catch (SQLException sqle) {
          if (DebugFile.trace) DebugFile.writeln("Error at PreparedStatement.setQueryTimeout(10)" + sqle.getMessage());
        }

        c = 1;
        oColIterator = oColumns.listIterator();

        while (oColIterator.hasNext()) {
          oCol = oColIterator.next();
          sCol = oCol.getName().toLowerCase();

          if (!oPrimaryKeys.contains(sCol) &&
              (sCol.compareTo(DB.dt_created)!=0)) {

            if (DebugFile.trace) {
              if (oCol.getSqlType()==java.sql.Types.CHAR  || oCol.getSqlType()==java.sql.Types.VARCHAR ||
                  oCol.getSqlType()==java.sql.Types.NCHAR || oCol.getSqlType()==java.sql.Types.NVARCHAR ) {

                if (AllValues.get(sCol)!=null) {
                  DebugFile.writeln("Binding " + sCol + "=" + AllValues.get(sCol).toString());

                  if (AllValues.get(sCol).toString().length() > oCol.getPrecision())
                    DebugFile.writeln("ERROR: value for " + oCol.getName() + " exceeds columns precision of " + String.valueOf(oCol.getPrecision()));
                } // fi (AllValues.get(sCol)!=null)
                else
                  DebugFile.writeln("Binding " + sCol + "=NULL");
              }
            } // fi (DebugFile.trace)

            try {
              oConn.bindParameter (oStmt, c, AllValues.get(sCol), oCol.getSqlType());
              c++;
            } catch (ClassCastException e) {
                if (AllValues.get(sCol)!=null)
                  throw new SQLException("ClassCastException at column " + sCol + " Cannot cast Java " + AllValues.get(sCol).getClass().getName() + " to SQL type " + oCol.getSqlTypeName(), "07006");
                else
                  throw new SQLException("ClassCastException at column " + sCol + " Cannot cast NULL to SQL type " + oCol.getSqlTypeName(), "07006");
            }

            } // endif (!oPrimaryKeys.contains(sCol))
          } // wend

        oKeyIterator = oPrimaryKeys.listIterator();
        while (oKeyIterator.hasNext()) {
          sCol = oKeyIterator.next();
          oCol = getColumnByName(sCol);

          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject (" + String.valueOf(c) + "," + AllValues.get(sCol) + "," + oCol.getSqlTypeName() + ")");

          oConn.bindParameter (oStmt, c, AllValues.get(sCol), oCol.getSqlType());
          c++;
        } // wend

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

		try {
          iAffected = oStmt.executeUpdate();
		} catch (SQLException sqle) {
          if (DebugFile.trace) {
          	DebugFile.writeln("SQLException "+sqle.getMessage());
            DebugFile.decIdent();
          }
		  oStmt.close();
		  throw new SQLException(sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
		}

        if (DebugFile.trace) DebugFile.writeln(String.valueOf(iAffected) +  " affected rows");

        oStmt.close();
        oStmt = null;
      } // fi (sUpdate!=null)
      else
        iAffected = 0;

      if (0==iAffected)
          {
          bNewRow = true;

          if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sInsert + ")");

          sSQL = sInsert;

          oStmt = oConn.prepareStatement(sInsert);

          try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(10); } catch (SQLException sqle) { if (DebugFile.trace) DebugFile.writeln("Error at PreparedStatement.setQueryTimeout(10)" + sqle.getMessage()); }

          c = 1;
          oColIterator = oColumns.listIterator();

          while (oColIterator.hasNext()) {

            oCol  = (DBColumn)oColIterator.next();
            sCol = oCol.getName();

            if (DebugFile.trace) {
              if (null!=AllValues.get(sCol))
                DebugFile.writeln("Binding " + sCol + "=" + AllValues.get(sCol).toString());
              else
                DebugFile.writeln("Binding " + sCol + "=NULL");
            } // fi

            oConn.bindParameter (oStmt, c, AllValues.get(sCol), oCol.getSqlType());
            c++;
          } // wend

          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

          try {
            iAffected = oStmt.executeUpdate();
		  } catch (SQLException sqle) {
            if (DebugFile.trace) {
          	  DebugFile.writeln("SQLException "+sqle.getMessage());
              DebugFile.decIdent();
            }
		    oStmt.close();
		    throw new SQLException(sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
		  }

          if (DebugFile.trace) DebugFile.writeln(String.valueOf(iAffected) +  " affected rows");

          oStmt.close();
          oStmt =null;
          }
        else
          bNewRow = false;
    }
    catch (SQLException sqle) {
      try { if (null!=oStmt) oStmt.close(); } catch (Exception ignore) { }

      throw new SQLException (sqle.getMessage() + " " + sSQL, sqle.getSQLState(), sqle.getErrorCode());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBTable.storeRegister() : " + String.valueOf(bNewRow && (iAffected>0)));
    }

    return bNewRow && (iAffected>0);
  } // storeRegister

  // ---------------------------------------------------------------------------

  /**
   * <p>Store a single register at the database representing a Java Object</p>
   * for register NOT containing LONGVARBINARY, IMAGE, BYTEA or BLOB fields use
   * storeRegister() method witch is faster than storeRegisterLong().
   * Columns named "dt_created" are invisible for storeRegisterLong() method so that
   * register creation timestamp is not altered by afterwards updates.
   * @param oConn Database Connection
   * @param AllValues Values to assign to fields.
   * @param BinaryLengths map of lengths for long fields.
   * @return <b>true</b> if register was inserted for first time, <false> if it was updated.
   * @throws SQLException
   */

  public boolean storeRegisterLong(JDCConnection oConn, HashMap AllValues, HashMap BinaryLengths) throws IOException, SQLException {
    int c;
    boolean bNewRow = false;
    DBColumn oCol;
    String sCol;
    ListIterator oColIterator;
    PreparedStatement oStmt;
    int iAffected;

    LinkedList oStreams;
    InputStream oStream;
    String sClassName;

    if (null==oConn)
      throw new NullPointerException("DBTable.storeRegisterLong() Connection is null");

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBTable.storeRegisterLong([Connection:"+oConn.pid()+"], {" + AllValues.toString() + "})" );
      DebugFile.incIdent();
      }

    oStreams  = new LinkedList();

    if (null!=sUpdate) {

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sUpdate + ")");

      oStmt = oConn.prepareStatement(sUpdate);

      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(10); } catch (SQLException sqle) { if (DebugFile.trace) DebugFile.writeln("Error at PreparedStatement.setQueryTimeout(10)" + sqle.getMessage()); }

      c = 1;
      oColIterator = oColumns.listIterator();
      while (oColIterator.hasNext()) {
        oCol = (DBColumn) oColIterator.next();
        sCol = oCol.getName().toLowerCase();

        if (!oPrimaryKeys.contains(sCol) &&
            (!sCol.equalsIgnoreCase(DB.dt_created))) {

          if (DebugFile.trace) {
            if (oCol.getSqlType()==java.sql.Types.CHAR || oCol.getSqlType()==java.sql.Types.VARCHAR) {
              if (AllValues.get(sCol) != null) {
                DebugFile.writeln("Binding " + sCol + "=" +
                                  AllValues.get(sCol).toString());
                if (AllValues.get(sCol).toString().length() > oCol.getPrecision())
                  DebugFile.writeln("ERROR: value for " + oCol.getName() +
                                    " exceeds columns precision of " +
                                    String.valueOf(oCol.getPrecision()));
              } // fi (AllValues.get(sCol)!=null)
              else
                DebugFile.writeln("Binding " + sCol + "=NULL");
            }
          } // fi (DebugFile.trace)

          if (oCol.getSqlType()==java.sql.Types.LONGVARCHAR || oCol.getSqlType()==java.sql.Types.CLOB || oCol.getSqlType()==java.sql.Types.LONGVARBINARY || oCol.getSqlType()==java.sql.Types.BLOB) {
            if (BinaryLengths.containsKey(sCol)) {
              if (((Long)BinaryLengths.get(sCol)).intValue()>0) {
                sClassName = AllValues.get(sCol).getClass().getName();
                if (sClassName.equals("java.io.File"))
                  oStream = new FileInputStream((File) AllValues.get(sCol));
                else if (sClassName.equals("[B"))
                  oStream = new ByteArrayInputStream((byte[]) AllValues.get(sCol));
                else if (sClassName.equals("[C"))
                  oStream = new StringBufferInputStream(new String((char[]) AllValues.get(sCol)));
                else {
                  Class[] aInts = AllValues.get(sCol).getClass().getInterfaces();
                  if (aInts==null) {
                    throw new SQLException ("Invalid object binding for column " + sCol);
                  } else {
                  	boolean bSerializable = false;
                  	for (int i=0; i<aInts.length &!bSerializable; i++)
                  	  bSerializable |= aInts[i].getName().equals("java.io.Serializable");
                    if (bSerializable) {
                      ByteArrayOutputStream oBOut = new ByteArrayOutputStream();
                      ObjectOutputStream oOOut = new ObjectOutputStream(oBOut);
                      oOOut.writeObject(AllValues.get(sCol));
                      oOOut.close();
                      ByteArrayInputStream oBin = new ByteArrayInputStream(oBOut.toByteArray());
                      oStream = new ObjectInputStream(oBin);	                  
                    } else {
                      throw new SQLException ("Invalid object binding for column " + sCol);                      
                    }
                  } // fi
                }
                oStreams.addLast(oStream);
                oStmt.setBinaryStream(c++, oStream, ((Long)BinaryLengths.get(sCol)).intValue());
              }
              else
                oStmt.setObject (c++, null, oCol.getSqlType());
            }
            else
             oStmt.setObject (c++, null, oCol.getSqlType());
          }
          else
            oConn.bindParameter (oStmt, c++, AllValues.get(sCol), oCol.getSqlType());
          } // fi (!oPrimaryKeys.contains(sCol))
        } // wend

      oColIterator = oPrimaryKeys.listIterator();
      while (oColIterator.hasNext()) {
        sCol = (String) oColIterator.next();
        oCol = getColumnByName(sCol);

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject (" + String.valueOf(c) + "," + AllValues.get(sCol) + "," + oCol.getSqlTypeName() + ")");

        oConn.bindParameter (oStmt, c, AllValues.get(sCol), oCol.getSqlType());
        c++;
      } // wend

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

      iAffected = oStmt.executeUpdate();

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iAffected) +  " affected rows");

      oStmt.close();

      oColIterator = oStreams.listIterator();

      while (oColIterator.hasNext())
        ((InputStream) oColIterator.next()).close();

      oStreams.clear();

    }
    else
      iAffected = 0;

    if (0==iAffected)
        {
        bNewRow = true;

        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sInsert + ")");

        oStmt = oConn.prepareStatement(sInsert);

        c = 1;
        oColIterator = oColumns.listIterator();

        while (oColIterator.hasNext()) {

          oCol  = (DBColumn)oColIterator.next();
          sCol = oCol.getName();

          if (DebugFile.trace) {
            if (null!=AllValues.get(sCol))
              DebugFile.writeln("Binding " + sCol + "=" + AllValues.get(sCol).toString());
            else
              DebugFile.writeln("Binding " + sCol + "=NULL");
          }

          if (oCol.getSqlType()==java.sql.Types.LONGVARCHAR || oCol.getSqlType()==java.sql.Types.CLOB || oCol.getSqlType()==java.sql.Types.LONGVARBINARY || oCol.getSqlType()==java.sql.Types.BLOB) {
            if (BinaryLengths.containsKey(sCol)) {
              if ( ( (Long) BinaryLengths.get(sCol)).intValue() > 0) {
                sClassName = AllValues.get(sCol).getClass().getName();
                if (sClassName.equals("java.io.File"))
                  oStream = new FileInputStream((File) AllValues.get(sCol));
                else if (sClassName.equals("[B"))
                  oStream = new ByteArrayInputStream((byte[]) AllValues.get(sCol));
                else if (sClassName.equals("[C"))
                  oStream = new StringBufferInputStream(new String((char[]) AllValues.get(sCol)));
                else {
                  Class[] aInts = AllValues.get(sCol).getClass().getInterfaces();
                  if (aInts==null) {
                    throw new SQLException ("Invalid object binding for column " + sCol);
                  } else {
                  	boolean bSerializable = false;
                  	for (int i=0; i<aInts.length &!bSerializable; i++)
                  	  bSerializable |= aInts[i].getName().equals("java.io.Serializable");
                    if (bSerializable) {
                      ByteArrayOutputStream oBOut = new ByteArrayOutputStream();
                      ObjectOutputStream oOOut = new ObjectOutputStream(oBOut);
                      oOOut.writeObject(AllValues.get(sCol));
                      oOOut.close();
                      ByteArrayInputStream oBin = new ByteArrayInputStream(oBOut.toByteArray());
                      oStream = new ObjectInputStream(oBin);	                  
                    } else {
                      throw new SQLException ("Invalid object binding for column " + sCol);                      
                    }
                  } // fi
                }
                oStreams.addLast(oStream);
                oStmt.setBinaryStream(c++, oStream, ((Long) BinaryLengths.get(sCol)).intValue());
              }
              else
                oStmt.setObject(c++, null, oCol.getSqlType());
            }
            else
              oStmt.setObject(c++, null, oCol.getSqlType());
          }
          else
            oConn.bindParameter (oStmt, c++, AllValues.get(sCol), oCol.getSqlType());
        } // wend

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

        iAffected = oStmt.executeUpdate();

        if (DebugFile.trace) DebugFile.writeln(String.valueOf(iAffected) +  " affected rows");

        oStmt.close();

        oColIterator = oStreams.listIterator();

        while (oColIterator.hasNext())
          ((InputStream) oColIterator.next()).close();

        oStreams.clear();
    }

    else
        bNewRow = false;

    // End SQLException

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBTable.storeRegisterLong() : " + String.valueOf(bNewRow));
      }

    return bNewRow;
  } // storeRegisterLong

  // ---------------------------------------------------------------------------

  /**
   * <p>Delete a single register from this table at the database</p>
   * @param oConn Database connection
   * @param AllValues A Map with, at least, the primary key values for the register. Other Map values are ignored.
   * @return <b>true</b> if register was delete, <b>false</b> if register to be deleted was not found.
   * @throws SQLException
   */

  public boolean deleteRegister(JDCConnection oConn, HashMap AllValues) throws SQLException {
    int c;
    boolean bDeleted;
    ListIterator oColIterator;
    PreparedStatement oStmt;
    Object oPK;
    DBColumn oCol;

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBTable.deleteRegister([Connection], {" + AllValues.toString() + "})" );
      DebugFile.incIdent();
      }

      if (sDelete==null) {
        throw new SQLException("Primary key not found", "42S12");
      }

    // Begin SQLException

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sDelete + ")");

      oStmt = oConn.prepareStatement(sDelete);

      c = 1;
      oColIterator = oPrimaryKeys.listIterator();

      while (oColIterator.hasNext()) {
        oPK = oColIterator.next();
        oCol = getColumnByName((String) oPK);

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject(" + String.valueOf(c) + "," + AllValues.get(oPK) + "," + oCol.getSqlTypeName() + ")");

        oStmt.setObject (c++, AllValues.get(oPK), oCol.getSqlType());
      } // wend

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

      bDeleted = (oStmt.executeUpdate()>0);

    // End SQLException

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBTable.deleteRegister() : " + (bDeleted ? "true" : "false"));
      }

    return bDeleted;
  } // deleteRegister

  // ---------------------------------------------------------------------------

  /**
   * <p>Checks if register exists at this table</p>
   * @param oConn Database Connection
   * @param sQueryString Register Query String, as a SQL WHERE clause syntax
   * @return <b>true</b> if register exists, <b>false</b> otherwise.
   * @throws SQLException
   */

  public boolean existsRegister(JDCConnection oConn, String sQueryString) throws SQLException {
    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    ResultSet oRSet = oStmt.executeQuery("SELECT NULL FROM " + getName() + " WHERE " + sQueryString);
    boolean bExists = oRSet.next();
    oRSet.close();
    oStmt.close();

    return bExists;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Checks if register exists at this table</p>
   * @param oConn Database Connection
   * @param sQueryString Register Query String, as a SQL WHERE clause syntax
   * @return <b>true</b> if register exists, <b>false</b> otherwise.
   * @throws SQLException
   */

  public boolean existsRegister(JDCConnection oConn, String sQueryString, Object[] oQueryParams) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM " + getName() + " WHERE " + sQueryString, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    if (oQueryParams!=null) {
      for (int p=0; p<oQueryParams.length; p++)
        oStmt.setObject(p+1, oQueryParams[p]);
    }

    ResultSet oRSet = oStmt.executeQuery();
    boolean bExists = oRSet.next();
    oRSet.close();
    oStmt.close();

    return bExists;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Checks if register exists at this table</p>
   * @param oConn Database Connection
   * @return <b>true</b> if register exists, <b>false</b> otherwise.
   * @throws SQLException
   */

  public boolean existsRegister(JDCConnection oConn, HashMap AllValues) throws SQLException {
    int c;
    boolean bExists;
    PreparedStatement oStmt;
    ResultSet oRSet;
    ListIterator oColIterator;
    Object oPK;
    DBColumn oCol;

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBTable.existsRegister([Connection], {" + AllValues.toString() + "})" );
      DebugFile.incIdent();
      }

    oStmt = oConn.prepareStatement(sExists, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    c = 1;
    oColIterator = oPrimaryKeys.listIterator();

    while (oColIterator.hasNext()) {
      oPK = oColIterator.next();
      oCol = getColumnByName((String) oPK);

      oStmt.setObject (c++, AllValues.get(oPK), oCol.getSqlType());
    } // wend

    oRSet = oStmt.executeQuery();
    bExists = oRSet.next();

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBTable.existsRegister() : " + String.valueOf(bExists));
      }

    return bExists;
  } // existsRegister

  // ---------------------------------------------------------------------------

  /**
   * @return List of {@link DBColumn} objects composing this table.
   */

  public LinkedList<Column> getColumns() {
	LinkedList<Column> oCols = new LinkedList<Column>();
	oCols.addAll(oColumns);
	return oCols;
  }

  // ---------------------------------------------------------------------------

  /**
   * @return List of {@link DBIndex} objects of this table.
   * @since 6.0
   */

  public LinkedList<DBIndex> getIndexes() {
    return oIndexes;
  }

  // ---------------------------------------------------------------------------

  /**
   * @return Columns names separated by commas
   * @throws IllegalStateException
   */

  public String getColumnsStr() throws IllegalStateException {

    if (null==oColumns)
      throw new IllegalStateException("Table columns list has not been initialized");

    ListIterator oColIterator = oColumns.listIterator();
    String sGetAllCols = new String("");

    while (oColIterator.hasNext())
      sGetAllCols += ((DBColumn) oColIterator.next()).getName() + ",";

    return sGetAllCols.substring(0, sGetAllCols.length()-1);

  } // getColumnsStr

  // ---------------------------------------------------------------------------

  /**
   * <p>Get DBColumn by name</p>
   * @param sColumnName Column Name
   * @return Reference to DBColumn ot <b>null</b> if no column with such name was found.
   * @throws IllegalStateException If column list for table has not been initialized
   */

  public DBColumn getColumnByName (String sColumnName) throws IllegalStateException {

    if (null==oColumns)
      throw new IllegalStateException("Table columns list not initialized");

    ListIterator oColIterator = oColumns.listIterator();
    DBColumn oCol = null;

    while (oColIterator.hasNext()) {
      oCol = (DBColumn) oColIterator.next();
      if (oCol.getName().equalsIgnoreCase(sColumnName)) {
        break;
      }
      oCol = null;
    } // wend

    return oCol;

  } // getColumnByName

  // ---------------------------------------------------------------------------

  /**
   * <p>Get DBColumn index given its by name</p>
   * @param sColumnName Column Name
   * @return Column Index[1..columnsCount()] or -1 if no column with such name was found.
   */

  public int getColumnIndex (String sColumnName) {
    ListIterator oColIterator = oColumns.listIterator();
    DBColumn oCol = null;

    while (oColIterator.hasNext()) {
      oCol = (DBColumn) oColIterator.next();
      if (oCol.getName().equalsIgnoreCase(sColumnName)) {
        return oCol.getPosition();
      }
      oCol = null;
    } // wend

    return -1;

  } // getColumnIndex

  // ---------------------------------------------------------------------------

  /**
   * @return List of primary key column names
   */

  public LinkedList<String> getPrimaryKey() {
    return oPrimaryKeys;

  }

  // ---------------------------------------------------------------------------

  /**
   * @return Unqualified table name
   */

  public String getName() { return sName; }

  // ---------------------------------------------------------------------------

  /**
   * @return Catalog name
   */

  public String getCatalog() { return sCatalog; }

  // ---------------------------------------------------------------------------

  public void setCatalog(String sCatalogName) { sCatalog=sCatalogName; }

  // ---------------------------------------------------------------------------

  /**
   * @return Schema name
   */

  public String getSchema() { return sSchema; }

  // ---------------------------------------------------------------------------

  /**
   * Set schema name
   * @param sSchemaName String
   */
  public void setSchema(String sSchemaName) { sSchema=sSchemaName; }

  // ---------------------------------------------------------------------------

  public int hashCode() { return iHashCode; }

  // ---------------------------------------------------------------------------

  /**
   * <p>Read DBColumn List from DatabaseMetaData</p>
   * This is primarily an internal initialization method for DBTable object.
   * Usually there is no need to call it from any other class.
   * @param oConn Database Connection
   * @param oMData DatabaseMetaData
   * @throws SQLException
   */
  public void readColumns(Connection oConn, DatabaseMetaData oMData) throws SQLException {
      int iErrCode;
      Statement oStmt;
      ResultSet oRSet;
      ResultSetMetaData oRData;
      DBColumn oCol;
      String sCol;
      int iCols;
      ListIterator oColIterator;

      String sColName;
      short iSQLType;
      String sTypeName;
      int iPrecision;
      int iDigits;
      int iNullable;
      int iColPos;

      int iDBMS;

      String sGetAllCols = "";
      String sSetPKCols = "";
      String sSetAllCols = "";
      String sSetNoPKCols = "";

      oColumns = new LinkedList<DBColumn>();
	  oIndexes = new LinkedList<DBIndex>();
      oPrimaryKeys = new LinkedList<String>();

      if (DebugFile.trace)
        {
        DebugFile.writeln("Begin DBTable.readColumns([DatabaseMetaData])" );
        DebugFile.incIdent();

        DebugFile.writeln("DatabaseMetaData.getColumns(" + sCatalog + "," + sSchema + "," + sName + ",%)");
        }

      if (oConn.getMetaData().getDatabaseProductName().equals("PostgreSQL"))
        iDBMS = JDCConnection.DBMS_POSTGRESQL;
      else if (oConn.getMetaData().getDatabaseProductName().equals("Oracle"))
        iDBMS = JDCConnection.DBMS_ORACLE;
      else if (oConn.getMetaData().getDatabaseProductName().equals("MySQL"))
        iDBMS = JDCConnection.DBMS_MYSQL;
      else if (oConn.getMetaData().getDatabaseProductName().equals("ACCESS"))
        iDBMS = JDCConnection.DBMS_ACCESS;
      else if (oConn.getMetaData().getDatabaseProductName().equals("Microsoft SQL Server"))
        iDBMS = JDCConnection.DBMS_MSSQL;
      else if (oConn.getMetaData().getDatabaseProductName().equals("SQLite"))
        iDBMS = JDCConnection.DBMS_SQLITE;
      else
        iDBMS = 0;

      oStmt = oConn.createStatement();

      try {
        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT * FROM " + sName + " WHERE 1=0)");

        if (iDBMS==JDCConnection.DBMS_POSTGRESQL) {
          if (sSchema==null)
            oRSet = oStmt.executeQuery("SELECT * FROM " + sName + " WHERE 1=0");
          else if (sSchema.length()==0)
            oRSet = oStmt.executeQuery("SELECT * FROM " + sName + " WHERE 1=0");
          else
            oRSet = oStmt.executeQuery("SELECT * FROM \""+sSchema+"\"." + sName + " WHERE 1=0");
        } else {
          oRSet = oStmt.executeQuery("SELECT * FROM " + sName + " WHERE 1=0");
        }
        
        iErrCode = 0;
      }
      catch (SQLException sqle) {
        // Patch for Oracle. DatabaseMetadata.getTables() returns table names
        // that later cannot be SELECTed, so this catch ignore these system tables

        oStmt.close();
        oRSet = null;

        if (DebugFile.trace) DebugFile.writeln("SQLException " + sSchema + "." + sName + " " + sqle.getMessage());

        iErrCode = sqle.getErrorCode();
        if (iErrCode==0) iErrCode=-1;
        if (!sqle.getSQLState().equals("42000"))
          throw new SQLException(sSchema + "." + sName + " " + sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
      }

      if (0==iErrCode) {
        if (DebugFile.trace) DebugFile.writeln("ResultSet.getMetaData()");

        oRData= oRSet.getMetaData();

        iCols = oRData.getColumnCount();

        if (DebugFile.trace) DebugFile.writeln("table has " + String.valueOf(iCols) + " columns");

        for (int c=1; c<=iCols; c++) {
          sColName = oRData.getColumnName(c).toLowerCase();
          sTypeName = oRData.getColumnTypeName(c);
          iSQLType = (short) oRData.getColumnType(c);

          if (iDBMS==JDCConnection.DBMS_POSTGRESQL)
            switch (iSQLType) {
              case Types.CHAR:
              case Types.VARCHAR:
                iPrecision = oRData.getColumnDisplaySize(c);
                break;
              default:
                iPrecision = oRData.getPrecision(c);
            }
          else {
            // New for v2.0, solves bug SF887614
            if (iSQLType==Types.BLOB || iSQLType==Types.CLOB)
              iPrecision = 2147483647;
            // end v2.0
            else
              iPrecision = oRData.getPrecision(c);
          }

          iDigits = oRData.getScale(c);
          iNullable = oRData.isNullable(c);
          iColPos = c;

          if (5==iDBMS && iSQLType==Types.NUMERIC && iPrecision<=6 && iDigits==0) {
            // Workaround for an Oracle 9i bug witch is unable to convert from Short to NUMERIC but does understand SMALLINT
            oCol = new DBColumn (sName,sColName,(short) Types.SMALLINT, sTypeName, iPrecision, iDigits, iNullable,iColPos);
          }
          else {
            oCol = new DBColumn (sName,sColName,iSQLType,sTypeName,iPrecision,iDigits,iNullable,iColPos);
          }

          // Establecer el comportamiento de no tocar en ningún caso los campos dt_created
          // quitar este if si se desea asignarlos manualmente al insertar cada registro
          if (!sColName.equals(DB.dt_created))
            oColumns.add(oCol);
        } // next

        if (DebugFile.trace) DebugFile.writeln("ResultSet.close()");

        oRSet.close();
        oRSet = null;
        oStmt.close();
        oStmt = null;

        if (5==iDBMS) /* Oracle */ {

          /* getPrimaryKeys() not working properly on some Oracle versions,
             use non portable implementation instead. Sergio 12-01-2004.

          Code until v1.1.4:

          if (DebugFile.trace)
            DebugFile.writeln("DatabaseMetaData.getPrimaryKeys(null, " + sSchema.toUpperCase() + ", " + sName.toUpperCase() + ")");

          oRSet = oMData.getPrimaryKeys(sCatalog, sSchema.toUpperCase(), sName.toUpperCase());
          */

          oStmt = oConn.createStatement();

          if (DebugFile.trace) {
            if (null==sSchema)
              DebugFile.writeln("Statement.executeQuery(SELECT NULL AS TABLE_CAT, COLS.OWNER AS TABLE_SCHEM, COLS.TABLE_NAME, COLS.COLUMN_NAME, COLS.POSITION AS KEY_SEQ, COLS.CONSTRAINT_NAME AS PK_NAME FROM USER_CONS_COLUMNS COLS, USER_CONSTRAINTS CONS WHERE CONS.OWNER=COLS.OWNER AND CONS.CONSTRAINT_NAME=COLS.CONSTRAINT_NAME AND CONS.CONSTRAINT_TYPE='P' AND CONS.TABLE_NAME='" + sName.toUpperCase()+ "')");
            else
              DebugFile.writeln("Statement.executeQuery(SELECT NULL AS TABLE_CAT, COLS.OWNER AS TABLE_SCHEM, COLS.TABLE_NAME, COLS.COLUMN_NAME, COLS.POSITION AS KEY_SEQ, COLS.CONSTRAINT_NAME AS PK_NAME FROM USER_CONS_COLUMNS COLS, USER_CONSTRAINTS CONS WHERE CONS.OWNER=COLS.OWNER AND CONS.CONSTRAINT_NAME=COLS.CONSTRAINT_NAME AND CONS.CONSTRAINT_TYPE='P' AND CONS.OWNER='" + sSchema.toUpperCase() + "' AND CONS.TABLE_NAME='" + sName.toUpperCase()+ "')");
          }

          if (null==sSchema)
            oRSet = oStmt.executeQuery("SELECT NULL AS TABLE_CAT, COLS.OWNER AS TABLE_SCHEM, COLS.TABLE_NAME, COLS.COLUMN_NAME, COLS.POSITION AS KEY_SEQ, COLS.CONSTRAINT_NAME AS PK_NAME FROM USER_CONS_COLUMNS COLS, USER_CONSTRAINTS CONS WHERE CONS.OWNER=COLS.OWNER AND CONS.CONSTRAINT_NAME=COLS.CONSTRAINT_NAME AND CONS.CONSTRAINT_TYPE='P' AND CONS.TABLE_NAME='" + sName.toUpperCase()+ "'");
          else
            oRSet = oStmt.executeQuery("SELECT NULL AS TABLE_CAT, COLS.OWNER AS TABLE_SCHEM, COLS.TABLE_NAME, COLS.COLUMN_NAME, COLS.POSITION AS KEY_SEQ, COLS.CONSTRAINT_NAME AS PK_NAME FROM USER_CONS_COLUMNS COLS, USER_CONSTRAINTS CONS WHERE CONS.OWNER=COLS.OWNER AND CONS.CONSTRAINT_NAME=COLS.CONSTRAINT_NAME AND CONS.CONSTRAINT_TYPE='P' AND CONS.OWNER='" + sSchema.toUpperCase() + "' AND CONS.TABLE_NAME='" + sName.toUpperCase()+ "'");

          // End new code v1.2.0
          }
          else if (10==iDBMS) { // Microsoft Access
            oRSet=null;
          }
          else {
            if (DebugFile.trace)
              DebugFile.writeln("DatabaseMetaData.getPrimaryKeys(" + sCatalog + "," + sSchema + "," + sName + ")");

            oRSet = oMData.getPrimaryKeys(sCatalog, sSchema, sName);
          } // fi (iDBMS)

        if (oRSet!=null) {
          while (oRSet.next()) {
            oPrimaryKeys.add(oRSet.getString(4).toLowerCase());
            sSetPKCols += oRSet.getString(4) + "=? AND ";
          } // wend

          if (DebugFile.trace) DebugFile.writeln("pk cols " + sSetPKCols);

          if (sSetPKCols.length()>7)
            sSetPKCols = sSetPKCols.substring(0, sSetPKCols.length()-5);

          if (DebugFile.trace) DebugFile.writeln("ResultSet.close()");

          oRSet.close();
          oRSet = null;
        } // fi (oRSet)

      if (null!=oStmt) { oStmt.close(); oStmt = null; }

      oColIterator = oColumns.listIterator();

      while (oColIterator.hasNext()) {
        sCol = ((DBColumn) oColIterator.next()).getName();

        sGetAllCols += sCol + ",";
        sSetAllCols += "?,";

        if (!oPrimaryKeys.contains(sCol) && !sCol.equalsIgnoreCase(DB.dt_created))
          sSetNoPKCols += sCol + "=?,";
      } // wend

      if (DebugFile.trace) DebugFile.writeln("get all cols " + sGetAllCols );

      if (sGetAllCols.length()>0)
        sGetAllCols = sGetAllCols.substring(0, sGetAllCols.length()-1);
      else
        sGetAllCols = "*";

      if (DebugFile.trace) DebugFile.writeln("set all cols " + sSetAllCols );

      if (sSetAllCols.length()>0)
        sSetAllCols = sSetAllCols.substring(0, sSetAllCols.length()-1);

      if (DebugFile.trace) DebugFile.writeln("set no pk cols " + sSetNoPKCols );

      if (sSetNoPKCols.length()>0)
        sSetNoPKCols = sSetNoPKCols.substring(0, sSetNoPKCols.length()-1);

      if (DebugFile.trace) DebugFile.writeln("set pk cols " + sSetPKCols );

      if (sSetPKCols.length()>0) {
        sSelect = "SELECT " + sGetAllCols + " FROM " + sName + " WHERE " + sSetPKCols;
        sInsert = "INSERT INTO " + sName + "(" + sGetAllCols + ") VALUES (" + sSetAllCols + ")";
        if (sSetNoPKCols.length()>0)
          sUpdate = "UPDATE " + sName + " SET " + sSetNoPKCols + " WHERE " + sSetPKCols;
        else
          sUpdate = null;
        sDelete = "DELETE FROM " + sName + " WHERE " + sSetPKCols;
        sExists = "SELECT NULL FROM " + sName + " WHERE " + sSetPKCols;
      }
      else {
        sSelect = null;
        sInsert = "INSERT INTO " + sName + "(" + sGetAllCols + ") VALUES (" + sSetAllCols + ")";
        sUpdate = null;
        sDelete = null;
        sExists = null;
      }
      
      // New for v6.0
      try {
        switch (iDBMS) {
      	case JDCConnection.DBMS_POSTGRESQL:
      	  oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      	  if (DebugFile.trace)
            DebugFile.writeln("Statement.executeQuery(SELECT indexname,indexdef FROM pg_indexes WHERE tablename='"+sName+"')");
      	  oRSet = oStmt.executeQuery("SELECT indexname,indexdef FROM pg_indexes WHERE tablename='"+sName+"'");
      	  while (oRSet.next()) {
      	  	String sIndexName = oRSet.getString(1);
      	  	String sIndexDef = oRSet.getString(2);
        	if (DebugFile.trace)
              DebugFile.writeln("index name "+sIndexName+", index definition "+sIndexDef);
      	  	int lPar = sIndexDef.indexOf('(');
      	  	int rPar = sIndexDef.indexOf(')');
      	  	if (lPar>0 && rPar>0) {      	  	  
      	  	  oIndexes.add(new DBIndex(sIndexName, sIndexDef.substring(++lPar,rPar).split(","), sIndexDef.toUpperCase().indexOf("UNIQUE")>0));
      	  	}
      	  } //wend
      	  oRSet.close();
      	  oRSet=null;
      	  oStmt.close();
      	  oStmt=null;
      	  break;
      	case JDCConnection.DBMS_MYSQL:
      	  oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      	  if (DebugFile.trace)
              DebugFile.writeln("Statement.executeQuery(SELECT COLUMN_NAME,COLUMN_KEY FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME ='"+sName+"' AND COLUMN_KEY!='')");
      	  oRSet = oStmt.executeQuery("SELECT COLUMN_NAME,COLUMN_KEY FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME ='"+sName+"' AND COLUMN_KEY!=''");
      	  while (oRSet.next()) {
      	  	String sIndexName = oRSet.getString(1);
      	  	String sIndexType = oRSet.getString(2);
        	if (DebugFile.trace)
                DebugFile.writeln("index name "+sIndexName+", index type "+sIndexType);
      	  	oIndexes.add(new DBIndex(sIndexName, new String[]{sIndexName},
      	  	             sIndexType.equalsIgnoreCase("PRI") || sIndexType.equalsIgnoreCase("UNI")));
      	  } //wend
      	  oRSet.close();
      	  oRSet=null;
      	  oStmt.close();
      	  oStmt=null;
      	  break;
        }
      } catch (SQLException sqle) {
      	if (DebugFile.trace) DebugFile.writeln("Cannot get indexes for " + sName );
		if (oRSet!=null) oRSet.close();
		if (oStmt!=null) oStmt.close();
      } 
    } // fi (0==iErrCode)

    if (DebugFile.trace)
      {
      DebugFile.writeln(sSelect!=null ? sSelect : "NO SELECT STATEMENT");
      DebugFile.writeln(sInsert!=null ? sInsert : "NO INSERT STATEMENT");
      DebugFile.writeln(sUpdate!=null ? sUpdate : "NO UPDATE STATEMENT");
      DebugFile.writeln(sDelete!=null ? sDelete : "NO DELETE STATEMENT");
      DebugFile.writeln(sExists!=null ? sExists : "NO EXISTS STATEMENT");

      DebugFile.decIdent();
      DebugFile.writeln("End DBTable.readColumns()");
      }

  } // readColumns
  
  // ----------------------------------------------------------

  /**
   * Get SQL DDL creation script for this table
   * @param eRDBMS
   * @return String like "CREATE TABLE table_name ( ... ) "
   * @since 7.0
   */
  public String sqlScriptDef(RDBMS eRDBMS)  {
    String sDDL = "CREATE TABLE "+getName()+"(";
    for (DBColumn c : oColumns)
      sDDL += c.sqlScriptDef(eRDBMS)+",";
    if (getPrimaryKey().size()>0)
      sDDL += "CONSTRAINT pk_"+getName()+" PRIMARY KEY ("+Gadgets.join(getPrimaryKey(), ",")+"),";
    for (int c=0; c<oColumns.size(); c++) {
      if (oColumns.get(c).getForeignKey()!=null)
        sDDL += "CONSTRAINT f"+String.valueOf(c+1)+"_"+getName()+" "+oColumns.get(c).getForeignKey()+",";
      else if (oColumns.get(c).getConstraint()!=null)
        sDDL += "CONSTRAINT c"+String.valueOf(c+1)+"_"+getName()+" CHECK ("+oColumns.get(c).getForeignKey()+"),";
    }    
    sDDL = Gadgets.dechomp(sDDL, ',');
    sDDL += ")";
    return sDDL;
  } // sqlScriptDef

  // ----------------------------------------------------------
  
  private String sCatalog;
  private String sSchema;
  private String sName;
  private int iHashCode;
  private LinkedList<DBColumn> oColumns;
  private LinkedList<DBIndex> oIndexes;
  private LinkedList<String> oPrimaryKeys;

  private String sSelect;
  private String sInsert;
  private String sUpdate;
  private String sDelete;
  private String sExists;

} // DBTable
