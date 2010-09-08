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
import java.util.LinkedList;
import java.util.Iterator;

import java.sql.*;

import javax.sql.PooledConnection;
import javax.sql.ConnectionEventListener;
import javax.sql.StatementEventListener;
import javax.sql.ConnectionEvent;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DBColumn;

/**
 * JDBC Connection Wrapper
 * @author Sergio Montoro Ten
 * @version 6.0
 */
public final class JDCConnection implements Connection,PooledConnection {

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
              if (DebugFile.trace) DebugFile.writeln("binding " + sParamClassName + " as SQL " + DBColumn.typeName(iSQLType));
              oStmt.setObject(iParamIndex, oParamValue, iSQLType);
            }
          }
          else {
            if (oParamValue!=null) {
              if (DebugFile.trace) DebugFile.writeln("binding " + sParamClassName + " as SQL " + DBColumn.typeName(iSQLType));
              oStmt.setObject(iParamIndex, oParamValue, iSQLType);
            } else {
              if (DebugFile.trace) DebugFile.writeln("binding null as SQL " + DBColumn.typeName(iSQLType));
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
}
