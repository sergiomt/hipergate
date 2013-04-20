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

package com.knowgate.jdc;

import java.util.Map;
import java.util.Date;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.concurrent.Executor;

import java.text.ParseException;

import java.sql.*;

import javax.sql.PooledConnection;
import javax.sql.ConnectionEventListener;
import javax.sql.StatementEventListener;
import javax.sql.ConnectionEvent;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.NameValuePair;

import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBTable;
import com.knowgate.dataobjs.DBColumn;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBRecordSet;

import com.knowgate.storage.Table;
import com.knowgate.storage.Record;
import com.knowgate.storage.Column;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.Transaction;
import com.knowgate.storage.AbstractRecord;
import com.knowgate.storage.StorageException;

/**
 * JDBC Connection Wrapper
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public final class JDCConnection implements Connection,PooledConnection,Table {

    public static final short IdClass = 100;

    public static final int DBMS_GENERIC = 0;
    public static final int DBMS_MYSQL = 1;
    public static final int DBMS_POSTGRESQL = 2;
    public static final int DBMS_MSSQL = 3;
    public static final int DBMS_ORACLE = 5;
    public static final int DBMS_XBASE = 9;
    public static final int DBMS_ACCESS = 10;
    public static final int DBMS_SQLITE = 11;

    private static final int DBMS_UNKNOWN = -1;
    private static final int DBMS_SYBASE = 4;
    private static final int DBMS_B2 = 6;
    private static final int DBMS_INFORMIX = 7;
    private static final int DBMS_DERBY = 8;

    private JDCConnectionPool pool;
    private Connection conn;
    private LinkedList<ConnectionEventListener> listeners;
    private boolean inuse;
    private long timestamp;
    private int dbms;
    private String name;
    private String schema;

    private static final String DBMSNAME_MSSQL = "Microsoft SQL Server";
    private static final String DBMSNAME_POSTGRESQL = "PostgreSQL";
    private static final String DBMSNAME_ORACLE = "Oracle";
    private static final String DBMSNAME_MYSQL = "MySQL";
    private static final String DBMSNAME_XBASE = "XBase";
    private static final String DBMSNAME_ACCESS = "ACCESS";
    private static final String DBMSNAME_SQLITE = "SQLite";

    public JDCConnection(Connection conn, JDCConnectionPool pool, String schemaname) {
        this.dbms = DBMS_UNKNOWN;
        this.conn=conn;
        this.pool=pool;
        this.inuse=false;
        this.timestamp=0;
        this.name = null;
        this.schema=schemaname;
        listeners = new LinkedList<ConnectionEventListener>();
    }

    public JDCConnection(Connection conn, JDCConnectionPool pool) {
        this.dbms = DBMS_UNKNOWN;
        this.conn=conn;
        this.pool=pool;
        this.inuse=false;
        this.timestamp=0;
        this.name = null;
        this.schema=null;
        listeners = new LinkedList<ConnectionEventListener>();
    }

    public void addConnectionEventListener(ConnectionEventListener listener) {
      listeners.add(listener);
    }

    public void removeConnectionEventListener(ConnectionEventListener listener) {
      listeners.remove(listener);
    } 

	protected void notifyClose() {
      if (listeners.size()>0) {
        Iterator<ConnectionEventListener> oIter = listeners.iterator();
        while (oIter.hasNext()) {
          ConnectionEventListener oCevl = oIter.next();
          oCevl.connectionClosed(new ConnectionEvent(this));
        } // wend
      } // fi        
	} // notifyClose

    public void addStatementEventListener(StatementEventListener listener) {
	  throw new UnsupportedOperationException("JDCConnection.addStatementEventListener() is not implemented");
    }

    public void removeStatementEventListener(StatementEventListener listener) {
	  throw new UnsupportedOperationException("JDCConnection.removeStatementEventListener() is not implemented");
    }

    public boolean lease(String sConnectionName) {
       if (inuse) {
           return false;
       } else {
          inuse=true;
          name = sConnectionName;
          timestamp=System.currentTimeMillis();
          return true;
       }
    }

    public boolean validate() {
      boolean bValid;

      if (DebugFile.trace) {
        DebugFile.writeln("Begin JDCConnection.validate()");
        DebugFile.incIdent();
      }
      try {
        conn.getMetaData();
        bValid = true;
      } catch (Exception e) {
        DebugFile.writeln(new Date().toString() + " " + e.getMessage());
        bValid = false;
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End JDCConnection.validate()");
      }

      return bValid;
    }

    public boolean inUse() {
        return inuse;
    }

    public JDCConnectionPool getPool() {
        return pool;
    }

    public long getLastUse() {
        return timestamp;
    }

    public String getName() {
        return name;
    }

	public LinkedList<Column> columns() {
	  return ((DBTable) pool.getDBTablesMap().get(getName())).getColumns();
	}

    public static int getDataBaseProduct(Connection conn) throws SQLException {
      DatabaseMetaData mdat;
      String prod;

        try {
          mdat = conn.getMetaData();
          prod = mdat.getDatabaseProductName();

          if (prod.equals(DBMSNAME_MSSQL))
            return DBMS_MSSQL;
          else if (prod.equals(DBMSNAME_POSTGRESQL))
            return DBMS_POSTGRESQL;
          else if (prod.equals(DBMSNAME_ORACLE))
            return DBMS_ORACLE;
          else if (prod.equals(DBMSNAME_MYSQL))
            return DBMS_MYSQL;
          else if (prod.equals(DBMSNAME_SQLITE))
            return DBMS_SQLITE;
          else
            return DBMS_GENERIC;
        }
        catch (NullPointerException npe) {
          if (DebugFile.trace) DebugFile.writeln("NullPointerException at JDCConnection.getDataBaseProduct()");
          return DBMS_GENERIC;
        }
    }

    public int getDataBaseProduct() throws SQLException {
      if (DBMS_UNKNOWN==dbms)
        dbms = getDataBaseProduct(conn);
      return dbms;
    }
    
    public String getSchemaName() throws SQLException {
      String sname;

      if (null==schema) {
        DatabaseMetaData mdat = conn.getMetaData();
        ResultSet rset = mdat.getSchemas();

        if (rset.next())
          sname = rset.getString(1);
        else
          sname = null;

        rset.close();
      }
      else
        sname = schema;

      return sname;
    }

   public void setSchemaName(String sname) {
     schema = sname;
   }

   public void close() throws SQLException {
      if (DebugFile.trace) {
        DebugFile.writeln("Begin JDCConnection.close()");
        DebugFile.incIdent();
        DebugFile.writeln("Connection process id. is "+pid());
      }

      if (pool==null) {
        inuse = false;
        name = null;
        conn.close();
		notifyClose();
      }
      else {
      	try { setAutoCommit(true); }
      	catch (SQLException sqle) { DebugFile.writeln("SQLException setAutoCommit(true) "+sqle.getMessage()); } 
      	try { setReadOnly(false); }
      	catch (SQLException sqle) { DebugFile.writeln("SQLException setReadOnly(false) "+sqle.getMessage()); } 
        pool.returnConnection(this);
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End JDCConnection.close()");
      }
    }

    public void close(String sCaller) throws SQLException {
      if (DebugFile.trace) {
        DebugFile.writeln("Begin JDCConnection.close("+sCaller+")");
        DebugFile.incIdent();
      }
      if (pool==null) {
        inuse = false;
        name = null;
        conn.close();
        notifyClose();
      }
      else {
      	try { setAutoCommit(true); }
      	catch (SQLException sqle) { DebugFile.writeln("SQLException setAutoCommit(true) "+sqle.getMessage()); } 
      	try { setReadOnly(false); }
      	catch (SQLException sqle) { DebugFile.writeln("SQLException setReadOnly(false) "+sqle.getMessage()); } 
        pool.returnConnection(this, sCaller);
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End JDCConnection.close("+sCaller+")");
      }
    }

	public void dispose() {
	  try { if (!getAutoCommit()) rollback(); } catch (SQLException ignore) { }
	  pool.returnConnection(this);
	  pool.disposeConnection(this);
	}

	public void dispose(String sCaller) {
	  try { if (!getAutoCommit()) rollback(); } catch (SQLException ignore) { }
	  pool.returnConnection(this, sCaller);
	  pool.disposeConnection(this);
	}

    protected void expireLease() {
        inuse=false;
        name =null ;
    }

    public Connection getConnection() {
        return conn;
    }

    public boolean isWrapperFor(Class c) {
        return c.getClass().getName().equals("java.sql.Connection");
    }

    public Object unwrap(Class c) {
        return c.getClass().getName().equals("java.sql.Connection") ? conn : null;
    }

    public Array createArrayOf(String typeName, Object[] attributes) throws SQLException {
	  return conn.createArrayOf(typeName, attributes);
    }

    public Blob createBlob() throws SQLException {
	  return conn.createBlob();
    }

    public Clob createClob() throws SQLException {
	  return conn.createClob();
    }

    public NClob createNClob() throws SQLException {
	  return conn.createNClob();
    }

    public Struct createStruct(String typeName, Object[] attributes) throws SQLException {
	  return conn.createStruct(typeName, attributes);
    }
    
    public SQLXML createSQLXML() throws SQLException, SQLFeatureNotSupportedException {
    	throw new SQLFeatureNotSupportedException("JDCConnection.createSQLXML() not implemented");
    }

    public Statement createStatement(int i, int j) throws SQLException {
        return conn.createStatement(i,j);
    }

    public Statement createStatement(int i, int j, int k) throws SQLException {
        return conn.createStatement(i,j,k);
    }

    public PreparedStatement prepareStatement(String sql) throws SQLException {
        return conn.prepareStatement(sql);
    }

    public PreparedStatement prepareStatement(String sql, String[] params) throws SQLException {
        return conn.prepareStatement(sql,params);
    }

    public PreparedStatement prepareStatement(String sql, int i) throws SQLException {
        return conn.prepareStatement(sql,i);
    }

    public PreparedStatement prepareStatement(String sql, int i, int j) throws SQLException {
        return conn.prepareStatement(sql,i,j);
    }

    public PreparedStatement prepareStatement(String sql, int i, int j, int k) throws SQLException {
        return conn.prepareStatement(sql,i,j,k);
    }

    public PreparedStatement prepareStatement(String sql, int[] params) throws SQLException {
        return conn.prepareStatement(sql,params);
    }

    public CallableStatement prepareCall(String sql) throws SQLException {
        return conn.prepareCall(sql);
    }

    public CallableStatement prepareCall(String sql, int i, int j) throws SQLException {
        return conn.prepareCall(sql, i , j);
    }

    public CallableStatement prepareCall(String sql, int i, int j, int k) throws SQLException {
        return conn.prepareCall(sql, i , j, k);
    }

    public Statement createStatement() throws SQLException {
        return conn.createStatement();
    }

    public String nativeSQL(String sql) throws SQLException {
        return conn.nativeSQL(sql);
    }

    public java.util.Properties getClientInfo() throws SQLException {
      return null;
    }

    public void setClientInfo(java.util.Properties props) throws SQLClientInfoException {
      throw new UnsupportedOperationException("JDCConnection.setClientInfo() Not implemented");
    }

    public String getClientInfo(String name) throws SQLException {
      return null;
    }

    public void setClientInfo(String name, String value) {
      throw new UnsupportedOperationException("JDCConnection.setClientInfo() Not implemented");
    }
    
    public void setAutoCommit(boolean autoCommit) throws SQLException {
        conn.setAutoCommit(autoCommit);
    }

    public boolean getAutoCommit() throws SQLException {
        return conn.getAutoCommit();
    }

    public int getHoldability() throws SQLException {
        return conn.getHoldability();
    }

    public void setHoldability(int h) throws SQLException {
        conn.setHoldability(h);
    }

    public Savepoint setSavepoint() throws SQLException {
        return conn.setSavepoint();
    }

    public Savepoint setSavepoint(String s) throws SQLException {
        return conn.setSavepoint(s);
    }

    public void commit() throws SQLException {
        conn.commit();
    }

    public void rollback() throws SQLException {
        conn.rollback();
    }

    public void rollback(Savepoint p) throws SQLException {
        conn.rollback(p);
    }

    public boolean isClosed() throws SQLException {
        return conn.isClosed();
    }

    public boolean isValid(int timeout) throws SQLException {
        return conn.isClosed();
    }

    public DatabaseMetaData getMetaData() throws SQLException {
        return conn.getMetaData();
    }

    public void setReadOnly(boolean readOnly) throws SQLException {
        conn.setReadOnly(readOnly);
    }

    public boolean isReadOnly() throws SQLException {
        return conn.isReadOnly();
    }

    public void setCatalog(String catalog) throws SQLException {
        conn.setCatalog(catalog);
    }

    public String getCatalog() throws SQLException {
        return conn.getCatalog();
    }

    public void setTransactionIsolation(int level) throws SQLException {
        conn.setTransactionIsolation(level);
    }

    public int getTransactionIsolation() throws SQLException {
        return conn.getTransactionIsolation();
    }

    public Map getTypeMap() throws SQLException {
      return conn.getTypeMap();
    }

    public void setTypeMap(Map typemap) throws SQLException {
      conn.setTypeMap(typemap);
    }

    public SQLWarning getWarnings() throws SQLException {
        return conn.getWarnings();
    }

    public void clearWarnings() throws SQLException {
        conn.clearWarnings();
    }

    public void releaseSavepoint(Savepoint p) throws SQLException {
        conn.releaseSavepoint(p);
    }

    /**
     * Checks if an object exists at database
     * Checking is done directly against database catalog tables,
     * if current user does not have enought priviledges for reading
     * database catalog tables methos may fail or return a wrong result.
     * @param sObjectName Objeto name
     * @param sObjectType Objeto type
     *        C = CHECK constraint
     *        D = Default or DEFAULT constraint
     *        F = FOREIGN KEY constraint
     *        L = Log
     *        P = Stored procedure
     *        PK = PRIMARY KEY constraint (type is K)
     *        RF = Replication filter stored procedure
     *        S = System table
     *        TR = Trigger
     *        U = User table
     *        UQ = UNIQUE constraint (type is K)
     *        V = View
     *        X = Extended stored procedure
     * @return <b>true</b> if object exists, <b>false</b> otherwise
     * @throws SQLException
     * @throws UnsupportedOperationException If current database management system is not supported for this method
     */

    public boolean exists(String sObjectName, String sObjectType)
      throws SQLException, UnsupportedOperationException {
      boolean bRetVal;
      PreparedStatement oStmt;
      ResultSet oRSet;

      if (DebugFile.trace) {
        DebugFile.writeln("Begin JDCConnection.exists([Connection], " + sObjectName + ", " + sObjectType + ")");
        DebugFile.incIdent();
      }

      switch (this.getDataBaseProduct()) {

        case JDCConnection.DBMS_MSSQL:
          if (DebugFile.trace)
            DebugFile.writeln ("Connection.prepareStatement(SELECT id FROM sysobjects WHERE name='" + sObjectName + "' AND xtype='" + sObjectType + "' OPTION (FAST 1))");

          oStmt = this.prepareStatement("SELECT id FROM sysobjects WHERE name=? AND xtype=? OPTION (FAST 1)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, sObjectName);
          oStmt.setString(2, sObjectType);
          oRSet = oStmt.executeQuery();
          bRetVal = oRSet.next();
          oRSet.close();
          oStmt.close();
          break;

        case JDCConnection.DBMS_POSTGRESQL:
          if (DebugFile.trace)
            DebugFile.writeln ("Conenction.prepareStatement(SELECT relname FROM pg_class WHERE relname='" + sObjectName + "')");

          oStmt = this.prepareStatement("SELECT tablename FROM pg_tables WHERE tablename=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, sObjectName);
          oRSet = oStmt.executeQuery();
          bRetVal = oRSet.next();
          oRSet.close();
          oStmt.close();
          break;

        case JDCConnection.DBMS_ORACLE:
          if (DebugFile.trace)
            DebugFile.writeln ("Conenction.prepareStatement(SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME='" + sObjectName + "')");

          oStmt = this.prepareStatement("SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, sObjectName.toUpperCase());
          oRSet = oStmt.executeQuery();
          bRetVal = oRSet.next();
          oRSet.close();
          oStmt.close();
          break;

        case JDCConnection.DBMS_MYSQL:
          if (DebugFile.trace)
            DebugFile.writeln ("Conenction.prepareStatement(SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE table_name='"+sObjectName+"')");

          oStmt = this.prepareStatement("SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE table_name=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, sObjectName);
          oRSet = oStmt.executeQuery();
          bRetVal = oRSet.next();
          oRSet.close();
          oStmt.close();
          break;

        default:
          throw new UnsupportedOperationException ("Unsupported DBMS");
      } // end switch()

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End JDCConnection.exists() : " + String.valueOf(bRetVal));
      }

      return bRetVal;
    } // exists()

    /**
     * <p>Get operating system process identifier for this connection</p>
     * @return String For PostgreSQL the id of the UNIX process attending this connection.
     * For Oracle a Session Id.
     * @throws SQLException
     * @since 2.2
     */
    public String pid() throws SQLException {
      Statement oStmt;
      ResultSet oRSet;
      String sPId = "unknown";
      switch (getDataBaseProduct()) {
        case DBMS_POSTGRESQL:
          oStmt = createStatement();
          oRSet = oStmt.executeQuery("SELECT pg_backend_pid()");
          if (oRSet.next())
            sPId = String.valueOf(oRSet.getInt(1));
          oRSet.close();
          oStmt.close();
          break;
        case DBMS_ORACLE:
          oStmt = createStatement();
          oRSet = oStmt.executeQuery("SELECT SYS_CONTEXT('USERENV','SESIONID') FROM DUAL");
          if (oRSet.next())
            sPId = oRSet.getString(1);
          oRSet.close();
          oStmt.close();
          break;
      }
      return sPId;
    } // pid


    // ---------------------------------------------------------------------------

    /**
     * <p>Bind parameter into a PreparedStatement</p>
     * @param oStmt PreparedStatement where values is to be binded
     * @param iParamIndex int Starting with 1
     * @param oParamValue Object
     * @param iSQLType int
     * @throws SQLException
     */
    public void bindParameter (PreparedStatement oStmt,
                               int iParamIndex, Object oParamValue, int iSQLType)
      throws SQLException {

      Class oParamClass;

      switch (getDataBaseProduct()) {

        case JDCConnection.DBMS_ORACLE:
          if (oParamValue!=null) {

            oParamClass = oParamValue.getClass();

            if (DebugFile.trace) DebugFile.writeln("binding " + oParamClass.getName() + " as SQL " + DBColumn.typeName(iSQLType));

            if (oParamClass.equals(Short.class) || oParamClass.equals(Integer.class) || oParamClass.equals(Float.class) || oParamClass.equals(Double.class))
              oStmt.setBigDecimal (iParamIndex, new java.math.BigDecimal(oParamValue.toString()));

            // New for hipergate v2.1 support for Oracle 9.2 change of behaviour with regard of DATE and TIMESTAMP columns
            // see http://www.oracle.com/technology/tech/java/sqlj_jdbc/htdocs/jdbc_faq.htm#08_01 for more details
            // If the binded parameter if a java.sql.Timestamp and the underlying database column is a DATE
            // Then create a new java.util.Date object from the Timestamp miliseconds and pass it to the
            // JDBC driver instead of the original Timestamp
            else if ((oParamClass.getName().equals("java.sql.Timestamp") ||
                      oParamClass.getName().equals("java.util.Date"))    &&
                     iSQLType==Types.DATE) {
              try {
                Class[] aTimestamp = new Class[1];
                aTimestamp[0] = Class.forName("java.sql.Timestamp");
                Class cDATE = Class.forName("oracle.sql.DATE");
                java.lang.reflect.Constructor cNewDATE = cDATE.getConstructor(aTimestamp);
                Object oDATE;
                if (oParamClass.getName().equals("java.sql.Timestamp")) {
                  oDATE = cNewDATE.newInstance(new Object[]{oParamValue});
                } else {
                  oDATE = cNewDATE.newInstance(new Object[]{new Timestamp(((java.util.Date)oParamValue).getTime())});
                }
                oStmt.setObject (iParamIndex, oDATE, iSQLType);
              } catch (ClassNotFoundException cnf) {
                throw new SQLException("ClassNotFoundException oracle.sql.DATE " + cnf.getMessage());
              } catch (NoSuchMethodException nsm) {
                throw new SQLException("NoSuchMethodException " + nsm.getMessage());
              } catch (IllegalAccessException iae) {
                throw new SQLException("IllegalAccessException " + iae.getMessage());
              } catch (InstantiationException ine) {
                throw new SQLException("InstantiationException " + ine.getMessage());
              } catch (java.lang.reflect.InvocationTargetException ite) {
                throw new SQLException("InvocationTargetException " + ite.getMessage());
              }
            }
            else if (oParamClass.getName().equals("java.util.Date") && iSQLType==Types.TIMESTAMP) {
              oStmt.setTimestamp(iParamIndex, new Timestamp(((java.util.Date)oParamValue).getTime()));
            }
            else {
              oStmt.setObject (iParamIndex, oParamValue, iSQLType);
            }
          }
          else
          	oStmt.setNull(iParamIndex, iSQLType);
          break;

        default:
          String sParamClassName;
          if (null!=oParamValue)
            sParamClassName = oParamValue.getClass().getName();
          else
            sParamClassName = "null";

          if ((Types.TIMESTAMP==iSQLType) && (oParamValue!=null)) {
            if (sParamClassName.equals("java.util.Date")) {
              if (DebugFile.trace) DebugFile.writeln("binding java.sql.Timestamp as SQL " + DBColumn.typeName(Types.TIMESTAMP));
              oStmt.setTimestamp(iParamIndex, new Timestamp(((java.util.Date)oParamValue).getTime()));
            }
            else {
              if (DebugFile.trace) DebugFile.writeln("binding " + sParamClassName + " as SQL " + DBColumn.typeName(iSQLType));
              oStmt.setObject(iParamIndex, oParamValue, iSQLType);
            }
          }
          else if ((Types.DATE==iSQLType) && (oParamValue!=null)) {
            if (sParamClassName.equals("java.util.Date")) {
              if (DebugFile.trace) DebugFile.writeln("binding java.sql.Date as SQL " + DBColumn.typeName(Types.DATE));
              oStmt.setDate(iParamIndex, new java.sql.Date(((java.util.Date)oParamValue).getTime()));
            }
            else {
              if (DebugFile.trace) DebugFile.writeln("binding " + sParamClassName + " value "+ oParamValue +" as SQL " + DBColumn.typeName(iSQLType));
              oStmt.setObject(iParamIndex, oParamValue, iSQLType);
            }
          }
          else {
            if (oParamValue!=null) {
              if (DebugFile.trace) DebugFile.writeln("binding parameter " + String.valueOf(iParamIndex)+ " " + sParamClassName + " value " + oParamValue + " as SQL " + DBColumn.typeName(iSQLType));
              oStmt.setObject(iParamIndex, oParamValue, iSQLType);
            } else {
              if (DebugFile.trace) DebugFile.writeln("binding parameter " + String.valueOf(iParamIndex) + " value null as SQL " + DBColumn.typeName(iSQLType));
              oStmt.setNull(iParamIndex, iSQLType);
            }
          }
      }
    } // bindParameter

    // ---------------------------------------------------------------------------

    public void bindParameter (PreparedStatement oStmt,
                               int iParamIndex, Object oParamValue)
      throws SQLException {

      if (getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
        if (oParamValue.getClass().equals(Integer.class) ||
            oParamValue.getClass().equals(Short.class) ||
            oParamValue.getClass().equals(Float.class) ||
            oParamValue.getClass().equals(Double.class)) {
          bindParameter(oStmt, iParamIndex, oParamValue, Types.NUMERIC);
        }
        else if (oParamValue.getClass().getName().equals("java.util.Date") ||
                 oParamValue.getClass().getName().equals("java.sql.Timestamp") ) {
          bindParameter(oStmt, iParamIndex, oParamValue, Types.DATE);
        }
        else {
          oStmt.setObject(iParamIndex, oParamValue);
        }
      } else {
        oStmt.setObject(iParamIndex, oParamValue);
      }
    } // bindParameter
    
    // ---------------------------------------------------------------------------

    /**
     * @since 7.0
     */
    public void abort(Executor oExec) throws SQLException {
      conn.abort(oExec);
    }

    // ---------------------------------------------------------------------------
    
    /**
     * @since 7.0
     */
    public int getNetworkTimeout() throws SQLException {
      return conn.getNetworkTimeout();
    }

    // ---------------------------------------------------------------------------
    
    /**
     * @since 7.0
     */
    public void setNetworkTimeout(Executor oExec, int iTimeout) throws SQLException {
      conn.setNetworkTimeout(oExec, iTimeout);
    }
    
    // ---------------------------------------------------------------------------
    
    /**
     * @since 7.0
     */
    public String getSchema() throws SQLException {
      return conn.getSchema();
    }

    // ---------------------------------------------------------------------------
    
    /**
     * @since 7.0
     */
    public void setSchema(String sSchema) throws SQLException {
      conn.setSchema(sSchema);
    }
        
    // ===========================================================================
    // com.knowgate.storage.Table interface implementation
    
	public DataSource getDataSource() {
	  return (DataSource) getPool();
	}

    // ---------------------------------------------------------------------------

	/**
	 * <p>Check whether a register with a given primary key exists at the underlying table</p>
	 * @param sKey Primary Key Value
	 * @throws StorageException
	 * @since 7.0
	 */
	public boolean exists(String sKey) throws StorageException {
	  boolean bRetVal;
	  DBBind oDbb = (com.knowgate.dataobjs.DBBind) getPool().getDatabaseBinding();
	  DBTable oDbt = oDbb.getDBTable(getName());
	  String sColName = oDbt.getPrimaryKey().getFirst();
	  try {
	      switch (oDbt.getColumnByName(sColName).getType()) {
	      	case Types.BIGINT:
	  		  bRetVal = oDbt.existsRegister(this, sColName+"=?", new Object[]{new Long(sKey)});
	  		  break;
	      	case Types.INTEGER:
		  	  bRetVal = oDbt.existsRegister(this, sColName+"=?", new Object[]{new Integer(sKey)});
		  	  break;	      		
	      	case Types.SMALLINT:
		  	  bRetVal = oDbt.existsRegister(this, sColName+"=?", new Object[]{new Short(sKey)});
		  	  break;	      		
	      	default:
		  	  bRetVal = oDbt.existsRegister(this, sColName+"=?", new Object[]{sKey});
	      }
	  } catch (SQLException sqle) {
	  	throw new StorageException(sqle.getMessage(), sqle);
	  }
	  return bRetVal;
	}

    // ---------------------------------------------------------------------------

	/**
	 * <p>Load a register by its primary key</p>
	 * @param sKey Primary Key Value
	 * @throws StorageException
	 * @return DBPersist instance or <b>null</b> if no register with given primary key was found
	 * @since 7.0
	 */
	public Record load(String sKey) throws StorageException {
      DBPersist oDbp = new DBPersist(getName(), getName());
      try {
        if (oDbp.load(this, sKey))
      	  return oDbp;
        else
      	  return null;      
      } catch (SQLException sqle) {
      	throw new StorageException(sqle.getMessage(), sqle);
      }
	}

    // ---------------------------------------------------------------------------

	/**
	 * <p>Load a register by its primary key</p>
	 * @param aKey Object[] Primary Key Values
	 * @throws StorageException
	 * @return DBPersist instance or <b>null</b> if no register with given primary key was found
	 * @since 7.0
	 */
	public Record load(Object[] aKey) throws StorageException {
      DBPersist oDbp = new DBPersist(getName(), getName());
      try {
        if (oDbp.load(this, aKey))
      	  return oDbp;
        else
      	  return null;      
      } catch (SQLException sqle) {
      	throw new StorageException(sqle.getMessage(), sqle);
      }
	}

    // ---------------------------------------------------------------------------

	/**
	 * <p>Create a new empty record</p>
	 * @throws StorageException
	 * @return DBPersist instance
	 * @since 7.0
	 */
	public Record newRecord() throws StorageException {
      return new DBPersist(getName(), getName());
	}
	
    // ---------------------------------------------------------------------------
	
	/**
	 * <p>Store record at database</p>
	 * @param oRec Instance of a DBPersist object to be stored
	 * @throws StorageException
	 * @since 7.0
	 */
	public void store(AbstractRecord oRec) throws StorageException {
      try {
	    ((DBPersist)oRec).store(this);
      } catch (SQLException sqle) {
      	throw new StorageException(sqle.getMessage(), sqle);
      }
	}

    // ---------------------------------------------------------------------------
	
	/**
	 * <p>Store record at database</p>
	 * @param oRec Instance of a DBPersist object
	 * @throws StorageException
	 * @since 7.0
	 */
	public void store(AbstractRecord oRec, Transaction oTrans) throws StorageException {
	  if (oTrans==null)
	  	store(oRec);
	  else
	    throw new StorageException("store(AbstractRecord, Transaction) method is not implemented for JDCConnection class");
	}

    // ---------------------------------------------------------------------------
	
	/**
	 * <p>Delete the given register from the underlying table</p>
	 * @param oRec Instance of a DBPersist object to be deleted
	 * @throws StorageException
	 * @since 7.0
	 */
	public void delete(AbstractRecord oRec) throws StorageException {
      try {
	    ((DBPersist)oRec).delete(this);
      } catch (SQLException sqle) {
      	throw new StorageException(sqle.getMessage(), sqle);
      }		
	}

    // ---------------------------------------------------------------------------
	
	/**
	 * <p>Delete registers from the underlying table</p>
	 * @param sIndexColumn
	 * @param sIndexValue
	 * @throws StorageException
	 * @since 7.0
	 */
	@SuppressWarnings("unused")
	public void delete(String sIndexColumn, String sIndexValue) throws StorageException {
	  PreparedStatement oStmt = null;
	  ResultSet oRSet = null;
	  try {
	    DBPersist oDbp = new DBPersist(getName(), getName());
	    DBTable oDbt = oDbp.getTable(this);
	    DBColumn oDbc = oDbt.getColumnByName(sIndexColumn);
	    String sPk = "";
	    LinkedList<String> oDbk = oDbt.getPrimaryKey();
	    for (String p : oDbk) {
	      sPk += (sPk.length()==0 ? "" : ",") + p;
	    }
	    LinkedList<Object[]> oPkVals = new LinkedList<Object[]>();
	    oStmt = prepareStatement("SELECT "+sPk+" FROM "+getName()+" WHERE "+sIndexColumn+"=?",
	  											 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	    oStmt.setObject(1, oDbc.convert(sIndexValue), oDbc.getSqlType());
	    oRSet = oStmt.executeQuery();
	    while (oRSet.next()) {
	  	  Object[] aPkVals = new Object[oDbk.size()];
	  	  for (int k=0; k<aPkVals.length; k++) {
	  	    aPkVals[k] = oRSet.getObject(k+1);
	  	  }
	  	  oPkVals.add(aPkVals);
	    }
	    oRSet.close();
	    oRSet=null;
	    oStmt.close();
	    oStmt=null;
	    for (Object[] o : oPkVals) {
	  	  int n=0;
	  	  for (String p : oDbk) {
	        oDbp.replace(p, o[n++]);
	      } // next
	      oDbp.delete(this);
	    } // next
	  } catch (SQLException sqle) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(sqle.getMessage(), sqle);
	  } catch (ParseException prse) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(prse.getMessage(), prse);
	  }
	}

	/**
	 * Method dropIndex
	 *
	 *
	 * @param sIndexColumn
	 *
	 @throws StorageException
	 *
	 */
	public void dropIndex(String sIndexColumn) throws StorageException {
	  throw new StorageException("dropIndex(String) method is not implemented for JDCConnection class");
	}

	/**
	 * Method fetch
	 *
	 *
	 @throws StorageException
	 *
	 * @return
	 *
	 */
	public RecordSet fetch(final int n, final int o) throws StorageException {
	  DBRecordSet oRetVal = new DBRecordSet();
	  Statement oStmt = null;
	  ResultSet oRSet = null;
	  ResultSetMetaData oMDat;
	  int nCols;
	  int iFetched = 0;
	  int iAdded = 0;
	  DBPersist oDbp;
	  
	  try {
	    oStmt = createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

        switch (getDataBaseProduct()) {

          case JDCConnection.DBMS_MSSQL:
	        oRSet = oStmt.executeQuery("SELECT * FROM "+getName()+" OPTION FAST ("+String.valueOf(n)+")");
	        oMDat = oRSet.getMetaData();
	        nCols = oMDat.getColumnCount();
	        while (oRSet.next() && iAdded<n) {
	          if (++iFetched>o) {
	            oDbp = new DBPersist(getName(), getName());
	            for (int c=1; c<=nCols; c++)
	              oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	            oRetVal.add(oDbp);
	            ++iAdded;
	          }
	        } // wend
            break;

          case JDCConnection.DBMS_POSTGRESQL:
          case JDCConnection.DBMS_MYSQL:
	        oRSet = oStmt.executeQuery("SELECT * FROM "+getName()+" LIMIT "+String.valueOf(n)+" OFFSET "+String.valueOf(o));
	        oMDat = oRSet.getMetaData();
	        nCols = oMDat.getColumnCount();
	        while (oRSet.next()) {
	          oDbp = new DBPersist(getName(), getName());
	          for (int c=1; c<=nCols; c++)
	            oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	          oRetVal.add(oDbp);
	        } // wend
            break;

		  default:
	        oRSet = oStmt.executeQuery("SELECT * FROM "+getName());
	        oMDat = oRSet.getMetaData();
	        nCols = oMDat.getColumnCount();
	        while (oRSet.next() && iAdded<n) {
	          if (++iFetched>o) {
	            oDbp = new DBPersist(getName(), getName());
	            for (int c=1; c<=nCols; c++)
	              oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	            oRetVal.add(oDbp);
	            ++iAdded;
	          }
	        } // wend
        } // end switch

	    oRSet.close();
	    oStmt.close();
	  } catch (SQLException sqle) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(sqle.getMessage(), sqle);
	  }
	  return oRetVal;
	}

	/**
	 * Method fetch
	 *
	 *
	 @throws StorageException
	 *
	 * @return
	 *
	 */

	public RecordSet fetch() throws StorageException {
	  return fetch(2147483647,0);
	}
	
	/**
	 * Fetch all the rows matching an indexed value
	 * @param sIndexColumn Index column name
	 * @param sIndexValue Value for index column
	 * @throws StorageException
	 * @return RecordSet
	 * @since 7.0
	 */
	public RecordSet fetch(String sIndexColumn, String sIndexValue) throws StorageException {
	  return fetch(sIndexColumn, sIndexValue, 2147483647);
	}

	/**
	 * Fetch all the rows which value for an indexed column is inside a range
	 * @param sIndexColumn Index column name
	 * @param sIndexValueMin Range lower bound
	 * @param sIndexValueMin Range upper bound
	 * @throws StorageException
	 * @return RecordSet
	 * @since 7.0
	 */
	@SuppressWarnings("unused")
	public RecordSet fetch(String sIndexColumn, String sIndexValueMin, 
					       String sIndexValueMax) throws StorageException {
	  DBRecordSet oRetVal = new DBRecordSet();
	  PreparedStatement oStmt = null;
	  ResultSet oRSet = null;
	  try {
	    DBPersist oDbp = new DBPersist(getName(), getName());
	    DBTable oDbt = oDbp.getTable(this); // Do not remove this line
	    DBColumn oDbc = oDbt.getColumnByName(sIndexColumn);
	    oStmt = prepareStatement("SELECT * FROM "+getName()+" WHERE "+sIndexColumn+" BETWEEN ? AND ?",
	  							 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	    oStmt.setObject(1, oDbc.convert(sIndexValueMin), oDbc.getSqlType());
	    oStmt.setObject(2, oDbc.convert(sIndexValueMax), oDbc.getSqlType());
	    oRSet = oStmt.executeQuery();
	    ResultSetMetaData oMDat = oRSet.getMetaData();
	    final int nCols = oMDat.getColumnCount();
	    int iFetched = 0;
	    while (oRSet.next()) {
	      oDbp = new DBPersist(getName(), getName());
	      for (int c=1; c<=nCols; c++)
	        oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	      oRetVal.add(oDbp);
	    } // wend
	    oRSet.close();
	    oStmt.close();
	  } catch (SQLException sqle) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(sqle.getMessage(), sqle);
	  } catch (ParseException prse) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(prse.getMessage(), prse);
	  }
	  return oRetVal;
	}

	/**
	 * Fetch all the rows which value for an indexed column is between two dates
	 * @param sIndexColumn Index column name
	 * @param sIndexValueMin Start Date
	 * @param sIndexValueMin End Date
	 * @throws StorageException
	 * @return RecordSet
	 * @since 7.0
	 */
	@SuppressWarnings("unused")
	public RecordSet fetch(String sIndexColumn, Date dtIndexValueMin, 
					       Date dtIndexValueMax) throws StorageException {
	  DBRecordSet oRetVal = new DBRecordSet();
	  PreparedStatement oStmt = null;
	  ResultSet oRSet = null;
	  try {
	    oStmt = prepareStatement("SELECT * FROM "+getName()+" WHERE "+sIndexColumn+" BETWEEN ? AND ?",
	  											 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	    oStmt.setTimestamp(1, new Timestamp(dtIndexValueMin.getTime()));
	    oStmt.setTimestamp(2, new Timestamp(dtIndexValueMax.getTime()));
	    oRSet = oStmt.executeQuery();
	    ResultSetMetaData oMDat = oRSet.getMetaData();
	    final int nCols = oMDat.getColumnCount();
	    int iFetched = 0;
	    while (oRSet.next()) {
	      DBPersist oDbp = new DBPersist(getName(), getName());
	      for (int c=1; c<=nCols; c++)
	        oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	      oRetVal.add(oDbp);
	    } // wend
	    oRSet.close();
	    oRSet=null;
	    oStmt.close();
	    oStmt=null;
	  } catch (SQLException sqle) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(sqle.getMessage(), sqle);
	  }
	  return oRetVal;
	}

	/**
	 * Fetch the first n rows matching an indexed value
	 * @param sIndexColumn Index column name
	 * @param sIndexValue Value for index column
	 * @param iMaxRows Maximum rows to be readed
	 * @throws StorageException
	 * @return RecordSet
	 * @since 7.0
	 */
	public RecordSet fetch(String sIndexColumn, String sIndexValue, 
					       int iMaxRows) throws StorageException {
	  DBRecordSet oRetVal = new DBRecordSet();
	  PreparedStatement oStmt = null;
	  ResultSet oRSet = null;
	  try {
	    DBPersist oDbp = new DBPersist(getName(), getName());
	    DBTable oDbt = oDbp.getTable(this);
	    if (null==oDbt) throw new StorageException("Table "+getName()+" was not found");
	    DBColumn oDbc = oDbt.getColumnByName(sIndexColumn);
	    oStmt = prepareStatement("SELECT * FROM "+getName()+" WHERE "+sIndexColumn+"=?",
	  				             ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	    oStmt.setObject(1, oDbc.convert(sIndexValue), oDbc.getSqlType());
	    oRSet = oStmt.executeQuery();
	    ResultSetMetaData oMDat = oRSet.getMetaData();
	    final int nCols = oMDat.getColumnCount();
	    int iFetched = 0;
	    while (oRSet.next()) {
	      oDbp = new DBPersist(getName(), getName());
	      for (int c=1; c<=nCols; c++)
	        oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	      oRetVal.add(oDbp);
	      if (++iFetched>=iMaxRows) break;
	    } // wend
	    oRSet.close();
	    oRSet=null;
	    oStmt.close();
	    oStmt=null;
	  } catch (SQLException sqle) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(sqle.getMessage(), sqle);
	  } catch (ParseException prse) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(prse.getMessage(), prse);
	  }
	  return oRetVal;
	}

	/**
	 * Fetch the first n rows matching some indexed values
	 * @param aIndexPairs Array of NameValuePair
	 * @param sIndexValue Value for index column
	 * @param iMaxRows Maximum rows to be readed
	 * @throws StorageException
	 * @return RecordSet
	 * @since 7.0
	 */
	public RecordSet fetch(NameValuePair[] aPairs, int iMaxRows) throws StorageException {
	  DBRecordSet oRetVal = new DBRecordSet();
	  PreparedStatement oStmt = null;
	  ResultSet oRSet = null;
	  try {
	    DBPersist oDbp = new DBPersist(getName(), getName());
	    DBTable oDbt = oDbp.getTable(this); // Do not remove this line
	    String sSQL = "SELECT * FROM "+getName()+" WHERE ";
	    for (int p=0; p<aPairs.length; p++)
	      sSQL += (p==0 ? "" : " AND ") + aPairs[p].getName()+"=?";	      
	    oStmt = prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	    for (int p=0; p<aPairs.length; p++)
	      oStmt.setString(p+1, aPairs[p].getValue());
	    oRSet = oStmt.executeQuery();
	    ResultSetMetaData oMDat = oRSet.getMetaData();
	    final int nCols = oMDat.getColumnCount();
	    int iFetched = 0;
	    while (oRSet.next()) {
	      oDbp = new DBPersist(getName(), getName());
	      for (int c=1; c<=nCols; c++)
	        oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	      oRetVal.add(oDbp);
	      if (++iFetched>=iMaxRows) break;
	    } // wend
	    oRSet.close();
	    oRSet=null;
	    oStmt.close();
	    oStmt=null;
	  } catch (SQLException sqle) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(sqle.getMessage(), sqle);
	  }
	  return oRetVal;
	} // fetch

	/**
	 * <p>Get the last n rows from a table</p>
	 * @param sOrderByColumn Column used for sorting results in descending order
	 * @param n Maximum number of rows to be retrieved
	 * @param o Offset
	 * @throws StorageException
	 * @return RecordSet
	 * @since 7.0
	 */
	public RecordSet last(final String sOrderByColumn, int n, int o) throws StorageException {
	  DBRecordSet oRetVal = new DBRecordSet();
	  PreparedStatement oStmt = null;
	  ResultSet oRSet = null;
	  ResultSetMetaData oMDat;
	  int nCols;
	  
	  try {
	    DBPersist oDbp = new DBPersist(getName(), getName());
	    int iFetched = 0;
	    int iAdded = 0;

        switch (getDataBaseProduct()) {

          case JDCConnection.DBMS_MSSQL:
	        oStmt = prepareStatement("SELECT * FROM "+getName()+" WHERE ORDER BY "+sOrderByColumn+" DESC OPTION FAST ("+String.valueOf(n)+")",
	  				                 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	        oRSet = oStmt.executeQuery();
	        oMDat = oRSet.getMetaData();
	        nCols = oMDat.getColumnCount();
	        while (oRSet.next() && iAdded<n) {
	          if (++iFetched>o) {
	            oDbp = new DBPersist(getName(), getName());
	            for (int c=1; c<=nCols; c++)
	              oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	            oRetVal.add(oDbp);
	            ++iAdded;
	          }
	        } // wend
            break;

          case JDCConnection.DBMS_POSTGRESQL:
          case JDCConnection.DBMS_MYSQL:
	        oStmt = prepareStatement("SELECT * FROM "+getName()+" WHERE ORDER BY "+sOrderByColumn+" DESC LIMIT "+String.valueOf(n)+" OFFSET "+String.valueOf(o),
	  				                 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	        oRSet = oStmt.executeQuery();
	        oMDat = oRSet.getMetaData();
	        nCols = oMDat.getColumnCount();
	        while (oRSet.next()) {
	          oDbp = new DBPersist(getName(), getName());
	          for (int c=1; c<=nCols; c++)
	            oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	          oRetVal.add(oDbp);
	        } // wend
            break;

		  default:
	        oStmt = prepareStatement("SELECT * FROM "+getName()+" WHERE ORDER BY "+sOrderByColumn+" DESC",
	  				                 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	        oRSet = oStmt.executeQuery();
	        oMDat = oRSet.getMetaData();
	        nCols = oMDat.getColumnCount();
	        while (oRSet.next() && iAdded<n) {
	          if (++iFetched>o) {
	            oDbp = new DBPersist(getName(), getName());
	            for (int c=1; c<=nCols; c++)
	              oDbp.put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
	            oRetVal.add(oDbp);
	            ++iAdded;
	          }
	        } // wend
        } // end switch

	    oRSet.close();
	    oRSet=null;
	    oStmt.close();
	    oStmt=null;
	  } catch (SQLException sqle) {
	  	if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) { } }
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(sqle.getMessage(), sqle);
	  }
	  return oRetVal;
	}

	/**
	 * Truncate table
	 * @throws StorageException
	 * @since 7.0
	 */
	public void truncate() throws StorageException {
	  Statement oStmt = null;
	  try {
	  	oStmt = createStatement();
	  	oStmt.execute("TRUNCATE TABLE "+getName());
	  	oStmt.close();
	  	oStmt = null;
	  } catch (SQLException sqle) {
	  	if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) { } }
      	throw new StorageException(sqle.getMessage(), sqle);
	  } 
	} // truncate	

    // ===========================================================================
    
}
