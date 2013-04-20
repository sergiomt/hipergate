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

import java.security.AccessControlException;

import java.io.PrintWriter;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Properties;
import java.util.LinkedList;
import java.util.ListIterator;
import java.util.logging.Logger;

import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.DatabaseMetaData;
import java.sql.CallableStatement;
import java.sql.Statement;
import java.sql.SQLException;
import java.sql.Timestamp;

import javax.sql.DataSource;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.misc.Environment;
import com.knowgate.misc.Gadgets;
import com.knowgate.storage.Column;
import com.knowgate.storage.StorageException;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.jdc.JDCConnectionPool;

import java.beans.Beans;

/**
 * <p>Singleton object for database binding.</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class DBBind extends Beans implements DataSource {

  // *****************
  // Private Variables

  private JDCConnectionPool oConnPool;
  private String sProfileName;
  private String sDatabaseProductName;
  private int iDatabaseProductId;
  private Exception oConnectXcpt;
  private Properties oCustomEnvProps;

  private static HashMap oGlobalTableMap;

  private HashMap<String,DBTable> oTableMap;

  private static final String VERSION = "7.0.0";

  // ***********
  // Constructor

  /**
   * <p>Create DBBind.</p>
   * Read database connection properties from hipergate.cnf.<br>
   * This file must be placed at the directory pointed by KNOWGATE_PROFILES
   * environment variable.<br>
   * By defualt hipergate.cnf is placed on C:\WINNT\ for Windows Systems and
   * /etc/ for UNIX Systems.
   *
   */
  public DBBind() {

    // This is a special variable only set after DriverManager.getConnection() from initialize()
    // If DriverManager.getConnection() fails the the exception will be stored and
    // re-thrown each time DBBind.getConnection() is called.
    oConnectXcpt = null;
	
	oCustomEnvProps = null;
	
    try {
      initialize("hipergate");
    } catch (Exception e) {
       oConnectXcpt=e;
	   System.err.println("DBBind.initialize() "+e.getClass().getName() + " "  + e.getMessage());
       if (DebugFile.trace) DebugFile.writeln(e.getClass().getName() + " "  + e.getMessage());
    }
  }

  /**
   * <p>Create DBBind.</p>
   * Read database connection properties from specified properties file.
   * @param Properties<br>
   */
  public DBBind(Properties oProps) {

    oConnectXcpt = null;

	oCustomEnvProps = oProps;

    try {
      initialize(oCustomEnvProps, "custom");
    }
    catch (AccessControlException e) {
      oConnectXcpt=e;
      if (DebugFile.trace) DebugFile.writeln("AccessControlException " + e.getMessage());
    }
    catch (ClassNotFoundException e) {
      oConnectXcpt=e;
      if (DebugFile.trace) DebugFile.writeln("ClassNotFoundException " + e.getMessage());
    }
    catch (SQLException e) {
      oConnectXcpt=e;
      if (DebugFile.trace) DebugFile.writeln("SQLException " + e.getMessage());
    }
    catch (NullPointerException e) {
      oConnectXcpt=e;
      if (DebugFile.trace) DebugFile.writeln("NullPointerException " + e.getMessage());
    }
    catch (UnsatisfiedLinkError e) {
      oConnectXcpt = new Exception("UnsatisfiedLinkError " + e.getMessage(), e);
      if (DebugFile.trace) DebugFile.writeln("UnsatisfiedLinkError " + e.getMessage());
    }
    catch (NumberFormatException e) {
      oConnectXcpt = new Exception("NumberFormatException " + e.getMessage(), e);
      if (DebugFile.trace) DebugFile.writeln("NumberFormatException " + e.getMessage());
    }
  }

  /**
   * <p>Create DBBind.</p>
   * Read database connection properties from specified properties file.
   * @param sProfile Name of properties file without extension.<br>
   * For example "hipergate" or "portal".<br>
   * The properties file must be placed at the directory pointed by
   * KNOWGATE_PROFILES environment variables.
   */
  public DBBind(String sProfile) {

    oConnectXcpt = null;

	oCustomEnvProps = null;

    try {
      initialize(sProfile);
    }
    catch (AccessControlException e) {
      oConnectXcpt=e;
      if (DebugFile.trace) DebugFile.writeln("AccessControlException " + e.getMessage());
    }
    catch (ClassNotFoundException e) {
      oConnectXcpt=e;
      if (DebugFile.trace) DebugFile.writeln("ClassNotFoundException " + e.getMessage());
    }
    catch (SQLException e) {
      oConnectXcpt=e;
      if (DebugFile.trace) DebugFile.writeln("SQLException " + e.getMessage());
    }
    catch (NullPointerException e) {
      oConnectXcpt=e;
      if (DebugFile.trace) DebugFile.writeln("NullPointerException " + e.getMessage());
    }
    catch (UnsatisfiedLinkError e) {
      oConnectXcpt = new Exception("UnsatisfiedLinkError " + e.getMessage(), e);
      if (DebugFile.trace) DebugFile.writeln("UnsatisfiedLinkError " + e.getMessage());
    }
    catch (NumberFormatException e) {
      oConnectXcpt = new Exception("NumberFormatException " + e.getMessage(), e);
      if (DebugFile.trace) DebugFile.writeln("NumberFormatException " + e.getMessage());
    }
  }

  /**
   * <P>Close DBBind</P>
   * Close connections from pool.<BR>
   * Stop connection reaper.<BR>
   */
  public void close() {

   if (DebugFile.trace)  {
     DebugFile.writeln("Begin DBBind.close()");
     DebugFile.incIdent();
   }

   oConnectXcpt = null;

   oGlobalTableMap = null;

   oTableMap.clear();
   oTableMap = null;

   if (null!=oConnPool) oConnPool.close();

   oConnPool = null;

   if (DebugFile.trace)  {
     DebugFile.decIdent();
     DebugFile.writeln("End DBBind.close()");
   }
  }

  // ----------------------------------------------------------

  /**
   * Close and reopen the connection pool and reload the table map cache
   * @throws SQLException
   * @throws ClassNotFoundException
   */
  public void restart()
    throws SQLException, ClassNotFoundException {

    if (DebugFile.trace)  {
      DebugFile.writeln("Begin DBBind.restart()");
      DebugFile.incIdent();
    }

    oConnectXcpt = null;

    oGlobalTableMap = null;

    oTableMap.clear();
    oTableMap = null;

    try {
      oConnPool.close();
    }
    catch (Exception e) {
      if (DebugFile.trace)  DebugFile.writeln(e.getClass().getName() + " " + e.getMessage());
    }

    oConnPool = null;

    initialize (sProfileName);

    if (DebugFile.trace)  {
      DebugFile.incIdent();
      DebugFile.writeln("End DBBind.restart()");
    }
  } // restart

  // ----------------------------------------------------------

  /**
   * Get connection pool used by this database binding
   * @return Reference to JDCConnectionPool
   */
  public JDCConnectionPool connectionPool() {
    return oConnPool;
  }

  // ----------------------------------------------------------

  private void loadDriver(Properties oProps)
    throws ClassNotFoundException, NullPointerException  {

	if (DebugFile.trace) DebugFile.writeln("Begin DBBind.loadDriver()" );
	  
    final String sDriver = oProps.getProperty("driver");

    if (DebugFile.trace) DebugFile.writeln("  driver=" +  sDriver);

    if (null==sDriver)
      throw new NullPointerException("Could not find property driver");

    Class.forName(sDriver);

    if (DebugFile.trace) DebugFile.writeln("End DBBind.loadDriver()" );
  } // loadDriver()

  // ----------------------------------------------------------

  private static  boolean in (String sStr, String[] aSet) {

    boolean bRetVal = false;

    if (aSet!=null) {
      final int iLen = aSet.length;

      for (int i=0; i<iLen && !bRetVal; i++)
        bRetVal = sStr.equalsIgnoreCase(aSet[i]);
    } // fi

    return bRetVal;
  }

  // ----------------------------------------------------------

  protected void initialize(String sProfile)
    throws ClassNotFoundException, SQLException, NullPointerException,
           AccessControlException,UnsatisfiedLinkError,NumberFormatException {

    Properties oProfEnvProps = Environment.getProfile(sProfile);

    initialize (oProfEnvProps, sProfile);
  }

  // ----------------------------------------------------------

  protected void initialize(Properties oProfEnvProps, String sProfile)
    throws ClassNotFoundException, SQLException, NullPointerException,
           AccessControlException,UnsatisfiedLinkError,NumberFormatException {

    int i;
    Connection oConn;
    DatabaseMetaData oMData;
    Statement oAcct = null;
    ResultSet oRSet;
    String TableTypes[] = new String[1];
    DBTable oTable;
    String sCatalog;
    String sSchema;
    String sTableSchema;
    String sTableName;
    Iterator oTableIterator;
    String[] aExclude;

    oTableMap = new HashMap<String,DBTable>(255);
    oGlobalTableMap = oTableMap ;

    if (DebugFile.trace)
      {
      DebugFile.writeln("hipergate package build " + DBBind.VERSION);
      DebugFile.envinfo();

      DebugFile.writeln("Begin DBBind.initialize("+sProfile+")");
      DebugFile.incIdent();
      }

      sProfileName = sProfile;

      // ****************
      // Load JDBC driver
      loadDriver(oProfEnvProps);

      if (DebugFile.trace) DebugFile.writeln("Load Driver " + oProfEnvProps.getProperty("driver") + " : OK\n" );

      if (DebugFile.trace) DebugFile.writeln("Trying to connect to " + oProfEnvProps.getProperty("dburl") + " with user " + oProfEnvProps.getProperty("dbuser"));

      // **********************************************************
      // Get database connection parameters from file hipergate.cnf

      // New for v2.2 *
      try {
        DriverManager.setLoginTimeout(Integer.parseInt(oProfEnvProps.getProperty("logintimeout", "20")));
      } catch (Exception x) {
        if (DebugFile.trace) DebugFile.writeln("DriverManager.setLoginTimeout() "+x.getClass().getName()+" "+x.getMessage());
      }
      // **************

      try {
    	if (oProfEnvProps.getProperty("dbuser")==null && oProfEnvProps.getProperty("dbpassword")==null)
            oConn = DriverManager.getConnection(oProfEnvProps.getProperty("dburl"));
    	else
          oConn = DriverManager.getConnection(oProfEnvProps.getProperty("dburl"),
                                              oProfEnvProps.getProperty("dbuser"),
                                              oProfEnvProps.getProperty("dbpassword"));
      }
      catch (SQLException e) {
        if (DebugFile.trace) DebugFile.writeln("DriverManager.getConnection("+oProfEnvProps.getProperty("dburl")+","+oProfEnvProps.getProperty("dbuser")+", ...) SQLException [" + e.getSQLState() + "]:" + String.valueOf(e.getErrorCode()) + " " + e.getMessage());
        oConnectXcpt = new SQLException("DriverManager.getConnection("+oProfEnvProps.getProperty("dburl")+","+oProfEnvProps.getProperty("dbuser")+", ...) "+e.getMessage(), e.getSQLState(), e.getErrorCode());
        throw (SQLException) oConnectXcpt;
      }

      if (DebugFile.trace) {
        DebugFile.writeln("Database Connection to " + oProfEnvProps.getProperty("dburl") + " : OK\n" );
        DebugFile.writeln("Calling Connection.getMetaData()");
      }

      oMData = oConn.getMetaData();

      if (DebugFile.trace) DebugFile.writeln("Calling DatabaseMetaData.getDatabaseProductName()");

      sDatabaseProductName = oMData.getDatabaseProductName();

      if (DebugFile.trace) {
        DebugFile.writeln("Database is \"" + sDatabaseProductName + "\"");
        DebugFile.writeln("Product version " + oMData.getDatabaseProductVersion());
        DebugFile.writeln(oMData.getDriverName() + " " + oMData.getDriverVersion());
        DebugFile.writeln("Max connections " + String.valueOf(oMData.getMaxConnections()));
        DebugFile.writeln("Max statements " + String.valueOf(oMData.getMaxStatements()));
      }

      if (sDatabaseProductName.equals(DBMSNAME_POSTGRESQL))
        iDatabaseProductId = DBMS_POSTGRESQL;
      else if (sDatabaseProductName.equals(DBMSNAME_MSSQL))
        iDatabaseProductId = DBMS_MSSQL;
      else if (sDatabaseProductName.equals(DBMSNAME_ORACLE))
        iDatabaseProductId = DBMS_ORACLE;
      else if (sDatabaseProductName.equals(DBMSNAME_MYSQL))
        iDatabaseProductId = DBMS_MYSQL;
      else if (sDatabaseProductName.equals(DBMSNAME_ACCESS))
        iDatabaseProductId = DBMS_ACCESS;
      else if (sDatabaseProductName.equals(DBMSNAME_SQLITE))
        iDatabaseProductId = DBMS_SQLITE;
      else if (sDatabaseProductName.equals("StelsDBF JDBC driver") ||
      	       sDatabaseProductName.equals("HXTT DBF"))
        iDatabaseProductId = DBMS_XBASE;
      else
        iDatabaseProductId = DBMS_GENERIC;

      Functions.setForDBMS(sDatabaseProductName);

      // **********************
      // Cache database catalog

      sCatalog = oConn.getCatalog();

      if (DebugFile.trace) DebugFile.writeln("Catalog is \"" + sCatalog + "\"");

      if (DebugFile.trace) DebugFile.writeln("Gather metadata : OK" );

      sSchema = oProfEnvProps.getProperty("schema", "");

      if (DebugFile.trace) DebugFile.writeln("Schema is \"" + sSchema + "\"");

      i = 0;

      TableTypes[0] = "TABLE";

      if (DBMS_ORACLE==iDatabaseProductId) {
        aExclude = new String[]{ "AUDIT_ACTIONS", "STMT_AUDIT_OPTION_MAP", "DUAL",
        "PSTUBTBL", "USER_CS_SRS", "USER_TRANSFORM_MAP", "CS_SRS", "HELP",
        "SDO_ANGLE_UNITS", "SDO_AREA_UNITS", "SDO_DIST_UNITS", "SDO_DATUMS",
        "SDO_CMT_CBK_DML_TABLE", "SDO_CMT_CBK_FN_TABLE", "SDO_CMT_CBK_DML_TABLE",
        "SDO_PROJECTIONS", "SDO_ELLIPSOIDS", "SDO_GEOR_XMLSCHEMA_TABLE",
        "SDO_GR_MOSAIC_0", "SDO_GR_MOSAIC_1", "SDO_GR_MOSAIC_2", "SDO_GR_MOSAIC_3",
        "SDO_TOPO_RELATION_DATA", "SDO_TOPO_TRANSACT_DATA", "SDO_TXN_IDX_DELETES",
        "DO_TXN_IDX_EXP_UPD_RGN", "SDO_TXN_IDX_INSERTS", "SDO_CS_SRS", "IMPDP_STATS",
        "OLAP_SESSION_CUBES", "OLAP_SESSION_DIMS", "OLAPI_HISTORY",
        "OLAPI_IFACE_OBJECT_HISTORY", "OLAPI_IFACE_OP_HISTORY", "OLAPI_MEMORY_HEAP_HISTORY",
        "OLAPI_MEMORY_OP_HISTORY", "OLAPI_SESSION_HISTORY", "OLAPTABLEVELS","OLAPTABLEVELTUPLES",
        "OLAP_OLEDB_FUNCTIONS_PVT", "OLAP_OLEDB_KEYWORDS", "OLAP_OLEDB_MDPROPS","OLAP_OLEDB_MDPROPVALS",
        "OGIS_SPATIAL_REFERENCE_SYSTEMS", "SYSTEM_PRIVILEGE_MAP", "TABLE_PRIVILEGE_MAP" };

        if (DebugFile.trace) {
          ResultSet oSchemas = null;
          try {
            int iSchemaCount = 0;
            oSchemas = oMData.getSchemas();
            while (oSchemas.next()) {
              DebugFile.writeln("schema name = " + oSchemas.getString(1));
              iSchemaCount++;
            }
            oSchemas.close();
            oSchemas = null;
            if (0==iSchemaCount) DebugFile.writeln("no schemas found");
          }
          catch (Exception sqle) {
            try { if (null!=oSchemas) oSchemas.close();} catch (Exception ignore) {}
            DebugFile.writeln("SQLException at DatabaseMetaData.getSchemas() " + sqle.getMessage());
          }
          DebugFile.writeln("DatabaseMetaData.getTables(" + sCatalog + ", null, %, {TABLE})");
        }

        oRSet = oMData.getTables(sCatalog, null, "%", TableTypes);

        while (oRSet.next()) {

          if (oRSet.getString(3).indexOf('$')<0 && !in(oRSet.getString(3).toUpperCase(), aExclude)) {
          	sTableSchema = oRSet.getString(2);
          	if (oRSet.wasNull()) sTableSchema = sSchema;
            oTable = new DBTable(sCatalog, sTableSchema, oRSet.getString(3), ++i);

            sTableName = oTable.getName().toLowerCase();

            if (oTableMap.containsKey(sTableName))
              oTableMap.remove(sTableName);

            oTableMap.put(sTableName, oTable);

            if (DebugFile.trace)
              DebugFile.writeln("Reading table " + oTable.getName());
          }
          else if (DebugFile.trace)
            DebugFile.writeln("Skipping table " + oRSet.getString(3));
       } // wend

      }
      else  {
        if (DBMS_POSTGRESQL==iDatabaseProductId)
          aExclude = new String[]{ "sql_languages", "sql_features",
                                   "sql_implementation_info", "sql_packages",
                                   "sql_sizing", "sql_sizing_profiles",
                                   "pg_ts_cfg", "pg_logdir_ls",
                                   "pg_ts_cfgmap", "pg_ts_dict", "pg_ts_parses",
                                   "pg_ts_parser", "pg_reload_conf" };
        else if (DBMS_MSSQL==iDatabaseProductId)
          aExclude = new String[]{ "syscolumns", "syscomments", "sysdepends",
                                   "sysfilegroups", "sysfiles" , "sysfiles1",
                                   "sysforeignkeys", "sysfulltextcatalogs",
                                   "sysfulltextnotify", "sysindexes",
                                   "sysindexkeys", "sysmembers", "sysobjects",
                                   "syspermissions", "sysproperties",
                                   "sysprotects", "sysreferences", "systypes",
                                   "sysusers" };
        else
          aExclude = null;

        if (DebugFile.trace)
          DebugFile.writeln("DatabaseMetaData.getTables(" + sCatalog + ", " + sSchema + ", %, {TABLE})");

		if ((DBMS_ACCESS==iDatabaseProductId)) {
		  oAcct = oConn.createStatement();
		  oRSet = oAcct.executeQuery("SELECT NULL,NULL,Name FROM MSysObjects WHERE Type=1 AND Flags<>-2147483648");
		} else {
          oRSet = oMData.getTables(sCatalog, sSchema, "%", TableTypes);
		}

        // For each table, keep its name in a memory map

        if (sSchema.length()>0) {

          while (oRSet.next()) {

            sTableName = oRSet.getString(3);
            
            if (!oRSet.wasNull()) {
              if (DebugFile.trace) DebugFile.writeln("Processing table " + sTableName);
          	  sTableSchema = oRSet.getString(2);
          	  if (oRSet.wasNull()) sTableSchema = oProfEnvProps.getProperty("schema", "dbo");
              oTable = new DBTable (sCatalog, sTableSchema, sTableName, ++i);

              sTableName = oTable.getName().toLowerCase();

              if (!in(sTableName, aExclude)) {
                if (oTableMap.containsKey(sTableName))
                  oTableMap.remove(sTableName);

                oTableMap.put(sTableName, oTable);

                if (DebugFile.trace) DebugFile.writeln("Readed table " + sSchema + "." + oTable.getName());
              } // fi (!in(sTableName, aExclude))
            } // fi (!oRSet.wasNull())
          } // wend
        }
        else { // sSchema == ""
          while (oRSet.next()) {

          	sTableSchema = oRSet.getString(2);
          	if (oRSet.wasNull()) sTableSchema = "";

            sTableName = oRSet.getString(3);

            if (!oRSet.wasNull()) {
              if (DebugFile.trace) DebugFile.writeln("Processing table " + sTableName);

              oTable = new DBTable (sCatalog, sTableSchema, sTableName, ++i);

              sTableName = oTable.getName().toLowerCase();

              if (!in(sTableName, aExclude)) {
                if (oTableMap.containsKey(sTableName))
                  oTableMap.remove(sTableName);

                oTableMap.put(sTableName, oTable);

                if (DebugFile.trace) DebugFile.writeln("Readed table " + oTable.getName());
              } // fi (!in(sTableName, aExclude))
            } // fi (!oRSet.wasNull())
         } // wend
        } // fi (sSchema == "")
      } // fi (DBMS_ORACLE!=iDatabaseProductId)

      oRSet.close();

	  if ((DBMS_ACCESS==iDatabaseProductId)) oAcct.close();

      if (DebugFile.trace && oTableMap.size()==0) DebugFile.writeln("No tables found");

      oTableIterator = oTableMap.values().iterator();

      // For each table, read its column structure and keep it in memory
      int nWarnings = 0;
  	  LinkedList<String> oUnreadableTables = new LinkedList<String>();
      
      while (oTableIterator.hasNext()) {
        oTable = (DBTable) oTableIterator.next();
        try {
          oTable.readColumns(oConn,oMData);
        } catch (SQLException sqle) {
          if (DebugFile.trace) {
        	DebugFile.writeln("Could not read columns of table "+oTable.getName());
        	try { DebugFile.writeln(StackTraceUtil.getStackTrace(sqle)); } catch (Exception ignore) {}
          }
          nWarnings++;
          oUnreadableTables.add(oTable.getName());
        }
      } // wend
      for (String t : oUnreadableTables) oTableMap.remove(t);

      if (DebugFile.trace) {
    	if (nWarnings==0)
      	  DebugFile.writeln("Table scan finished with "+String.valueOf(nWarnings)+" warnings");
    	else
    	  DebugFile.writeln("Table scan succesfully completed" );
      }

      oConn.close();
      oConn=null;

      // Create database connection pool

      if (DebugFile.trace) DebugFile.writeln("new JDCConnectionPool("+oProfEnvProps.getProperty("dburl")+","+oProfEnvProps.getProperty("dbuser")+",...,"+oProfEnvProps.getProperty("poolsize", "32")+","+oProfEnvProps.getProperty("maxconnections", "100")+")");

      // ***************************************************************
      // New for v2.2
      // Perform aditional checkings of hipergate.cnf integer values and
      // add logintimeout and connectiontimeout property handling

      int iPoolSize, iMaxConns, iLoginTimeout;
      long iConnectionTimeout;

      try {
        iPoolSize=Integer.parseInt(oProfEnvProps.getProperty("poolsize", "32"));
        if (iPoolSize<0) throw new NumberFormatException();
      }
      catch (NumberFormatException nfe) {
        if (DebugFile.trace) {
          DebugFile.writeln("poolsize property at "+sProfile+".cnf must be a positive integer value");
          DebugFile.decIdent();
        }
        throw new NumberFormatException("poolsize property at "+sProfile+".cnf must be a positive integer value");
      }

      try {
        iMaxConns=Integer.parseInt(oProfEnvProps.getProperty("maxconnections", "100"));
        if (iMaxConns<0) throw new NumberFormatException();
      }
      catch (NumberFormatException nfe) {
        if (DebugFile.trace) {
          DebugFile.writeln("maxconnections property at "+sProfile+".cnf must be a positive integer value");
          DebugFile.decIdent();
        }
        throw new NumberFormatException("maxconnections property at "+sProfile+".cnf must be a positive integer value");
      }

      try {
        iLoginTimeout=Integer.parseInt(oProfEnvProps.getProperty("logintimeout", "20"));
      }
      catch (NumberFormatException nfe) {
        if (DebugFile.trace) {
          DebugFile.writeln("logintimeout property at "+sProfile+".cnf must be an integer value");
          DebugFile.decIdent();
        }
        throw new NumberFormatException("logintimeout property at "+sProfile+".cnf must be an integer value");
      }
      if (iLoginTimeout<=0) {
        if (DebugFile.trace) {
          DebugFile.writeln("logintimeout property at "+sProfile+".cnf must be greater than zero");
          DebugFile.decIdent();
        }
        throw new NumberFormatException("logintimeout property at "+sProfile+".cnf must be greater than zero");
      }

      try {
        iConnectionTimeout=Long.parseLong(oProfEnvProps.getProperty("connectiontimeout", "60000"));
      }
      catch (NumberFormatException nfe) {
        if (DebugFile.trace) {
          DebugFile.writeln("connectiontimeout property at "+sProfile+".cnf must be an integer value");
          DebugFile.decIdent();
        }
        throw new NumberFormatException("connectiontimeout property at "+sProfile+".cnf must be an integer value");
      }
      if (iConnectionTimeout<1000l) {
        if (DebugFile.trace) {
          DebugFile.writeln("connectiontimeout property at "+sProfile+".cnf must be greater than 1000 miliseconds");
          DebugFile.decIdent();
        }
        throw new NumberFormatException("connectiontimeout property at "+sProfile+".cnf must be greater than 1000 miliseconds");
      }

      // ***************************************************************

      oConnPool = new JDCConnectionPool(this,
                                        oProfEnvProps.getProperty("dburl"),
                                        oProfEnvProps.getProperty("dbuser"),
                                        oProfEnvProps.getProperty("dbpassword"),
                                        iPoolSize,iMaxConns,iLoginTimeout,iConnectionTimeout);

      if (null!=oConnPool) {
        if (DebugFile.trace) DebugFile.writeln("Connection pool creation : OK" );

        try {
          oConnPool.setReaperDaemonDelay(Long.parseLong(oProfEnvProps.getProperty("connectionreaperdelay", "600000")));
        }
        catch (NumberFormatException nfe) {
          if (DebugFile.trace) {
            DebugFile.writeln("connectionreaperdelay property at "+sProfile+".cnf must be an integer value");
            DebugFile.decIdent();
          }
          throw new NumberFormatException("connectionreaperdelay property at "+sProfile+".cnf must be an integer value");
        }
        catch (IllegalArgumentException iae) {
          if (DebugFile.trace) {
            DebugFile.writeln("connectionreaperdelay property at " + sProfile + ".cnf must be greater than 1000");
            DebugFile.decIdent();
          }
          throw new NumberFormatException("connectionreaperdelay property at "+sProfile+".cnf must must be greater than 1000");
        }
      } else {
        if (DebugFile.trace) DebugFile.writeln("Connection pool creation failed!" );
      }

      if (DebugFile.trace)
        {
        DebugFile.decIdent();
        DebugFile.writeln("End DBBind.initialize()");
      }
  } // initialize

  // ----------------------------------------------------------

  /**
   * Get the name of Database Management System Connected
   * @return one of { "Microsoft SQL Server", "Oracle", "PostgreSQL", "MySQL" }
   * @throws SQLException
   */

  public String getDatabaseProductName()
    throws SQLException {

    if (null!=oConnectXcpt) throw (SQLException) oConnectXcpt;

    return sDatabaseProductName;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get Name of profile used for initializing DBBind</p>
   * Profile Name is the properties file name ("hipergate.cnf") without extension.<br>
   * For example "hipergate", "real", "demo", "test", "portal"
   * @return Profile name
   */
  public String getProfileName() {
    return sProfileName;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get properties from the .CNF file for this DBBind.</p>
   * @since 4.0
   */
  public Properties getProperties() {
    return oCustomEnvProps==null ? Environment.getProfile(getProfileName()) : oCustomEnvProps;
  }

  // ----------------------------------------------------------
  
  /**
   * <p>Get a single property from the .CNF file for this DBBind.</p>
   * @param sVarName Property Name
   * @return Value of property or <b>null</b> if no property with such name was found.
   * @since 4.0
   */
  public String getProperty(String sVarName) {
    return oCustomEnvProps==null ? Environment.getProfileVar(getProfileName(),sVarName) : oCustomEnvProps.getProperty(sVarName);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get a single property from the .CNF file for this DBBind.</p>
   * @param sVarName Property Name
   * @param sDefault Default Value
   * @return Value of property or sDefault if no property with such name was found.
   * @since 4.0
   */
  public String getProperty(String sVarName, String sDefault) {
    return oCustomEnvProps==null ? Environment.getProfileVar(getProfileName(),sVarName,sDefault) : oCustomEnvProps.getProperty(sVarName, sDefault);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get a boolean property from the .CNF file for this DBBind.</p>
   * @param sVarName Property Name
   * @param bDefault Default Value
   * @return If no property named sVarName is found then bDefault value is returned.
   * If sVarName is one of {true , yes, on, 1} then return value is <b>true</b>.
   * If sVarName is one of {false, no, off, 0} then return value is <b>false</b>.
   * If sVarName is any other value then then return value is bDefault
   * @since 4.0
   */
  public boolean getPropertyBool(String sVarName, boolean bDefault) {
    return oCustomEnvProps==null ? Environment.getProfileBool(getProfileName(),sVarName,bDefault) : Boolean.valueOf(oCustomEnvProps.getProperty(sVarName));
  }

  // ----------------------------------------------------------
  
  /**
   * <p>Get a property representing a file path from the .CNF file for this DBBind.</p>
   * @param sVarName Property Name
   * @return Value of property or <b>null</b> if no property with such name was found.
   * @since 4.0
   */
  public String getPropertyPath(String sVarName) {
    return oCustomEnvProps==null ? Environment.getProfilePath(getProfileName(),sVarName) : oCustomEnvProps.getProperty(sVarName);
  }

  // ----------------------------------------------------------

  /**
   * Checks if an object exists at database
   * Checking is done directly against database catalog tables,
   * if current user does not have enought priviledges for reading
   * database catalog tables methos may fail or return a wrong result.
   * @param oConn Database connection
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

  public static boolean exists(JDCConnection oConn, String sObjectName, String sObjectType)
      throws SQLException, UnsupportedOperationException {

      return oConn.exists(sObjectName, sObjectType);

  } // exists()

  // ----------------------------------------------------------

  /**
   * Get datamodel version
   * @param oConn JDCConnection object
   * @return vs_stamp field from k_version table
   * @throws SQLException
   */
  public static String getDataModelVersion(JDCConnection oConn) throws SQLException {
    String sVersion = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBBind.getDataModelVersion([Connection])");
      DebugFile.incIdent();
    }

    if (DBBind.exists(oConn, DB.k_version, "U")) {
      Statement oStmt = oConn.createStatement();
      ResultSet oRSet = oStmt.executeQuery("SELECT vs_stamp FROM " + DB.k_version);
      if (oRSet.next())
        sVersion = oRSet.getString(1);
      oRSet.close();
      oStmt.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBBind.getDataModelVersion() : " + sVersion);
    }

    return sVersion;
  } // getDataModelVersion

  // ----------------------------------------------------------

  /**
   * Get datamodel version number
   * @param oConn JDCConnection object
   * @return for 2.0.8-> 20008 , 2.1.0 -> 20100, etc.
   * @throws SQLException
   */
  public static int getDataModelVersionNumber(JDCConnection oConn)
    throws SQLException {

    String sVersion = getDataModelVersion(oConn);

    if (null==sVersion) return 0;

    final int iLen = sVersion.length();
    String sMajor = "", sMinor = "", sRevision = "";
    int iDots = 0;

    for (int i=0; i<iLen; i++) {
      if (sVersion.charAt(i)>='0' && sVersion.charAt(i)<='9') {
        switch (iDots) {
          case 0:
            sMajor += sVersion.charAt(i);
            break;
          case 1:
            sMinor += sVersion.charAt(i);
            break;
          case 2:
            sRevision += sVersion.charAt(i);
        }
      }
      else if (sVersion.charAt(i)=='.')
        iDots++;
    } // next (i)

    return Integer.parseInt(sMajor+Gadgets.leftPad(sMinor, '0', 2)+Gadgets.leftPad(sRevision, '0', 2));
  } // getDataModelVersionNumber

  // ----------------------------------------------------------

  /**
   * <p>Get current value for a sequence</p>
   * @param oConn JDCConnection
   * @param sSequenceName Sequence name.
   * In MySQL and SQL Server sequences are implemented using row locks at k_sequences table.
   * @return Current sequence value
   * @throws SQLException
   * @throws UnsupportedOperationException Not all databases support sequences.
   * On Oracle and PostgreSQL, native SEQUENCE objects are used,
   * on MySQL and Microsoft SQL Server the stored procedure k_sp_currval simulates sequences,
   * this function is not supported on other DataBase Management Systems.
   * @since 3.0
   */

  public static int currVal(JDCConnection oConn, String sSequenceName)
      throws SQLException, UnsupportedOperationException {

    Statement oStmt;
    ResultSet oRSet;
    CallableStatement oCall;
    int iCurrVal;

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin hipergate DBBind.currVal([JDCConnection], " + sSequenceName + ")" );
      DebugFile.incIdent();
      }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_MYSQL:
      case JDCConnection.DBMS_MSSQL:

        if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({call k_sp_currval ('" + sSequenceName + "',?)})" );

        oCall = oConn.prepareCall("{call k_sp_currval (?,?)}");
        oCall.setString(1, sSequenceName);
        oCall.registerOutParameter(2, java.sql.Types.INTEGER);
        oCall.execute();
        iCurrVal = oCall.getInt(2);
        oCall.close();
        oCall = null;
        break;

      case JDCConnection.DBMS_POSTGRESQL:
        oStmt = oConn.createStatement();

        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT nextval('" + sSequenceName + "'))" );

        oRSet = oStmt.executeQuery("SELECT nextval('" + sSequenceName + "')");
        oRSet.next();
        iCurrVal = oRSet.getInt(1)-1;
        oRSet.close();

        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT setval('" + sSequenceName + "',"+String.valueOf(iCurrVal)+"))" );

        oRSet = oStmt.executeQuery("SELECT setval('" + sSequenceName + "',"+String.valueOf(iCurrVal)+")");
        oRSet.close();

        oStmt.close();
        break;

      case JDCConnection.DBMS_ORACLE:
        oStmt = oConn.createStatement();

        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT " + sSequenceName + ".CURRVAL))" );

        oRSet = oStmt.executeQuery("SELECT " + sSequenceName + ".CURRVAL FROM dual");
        oRSet.next();
        iCurrVal = oRSet.getInt(1);
        oRSet.close();
        oStmt.close();
        break;

      default:
        throw new UnsupportedOperationException("function currVal() not supported on current DBMS");
    }

    oConn = null;

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBBind.currVal() : " + String.valueOf(iCurrVal));
      }

    return iCurrVal;
  } // currVal

  // ----------------------------------------------------------

  /**
   * <p>Get current value for a sequence</p>
   * @param oSQLConn Database connection
   * @param sSequenceName Sequence name.
   * In MySQL and SQL Server sequences are implemented using row locks at k_sequences table.
   * @return Current sequence value
   * @throws SQLException
   * @throws UnsupportedOperationException Not all databases support sequences.
   * On Oracle and PostgreSQL, native SEQUENCE objects are used,
   * on MySQL and Microsoft SQL Server the stored procedure k_sp_nextval simulates sequences,
   * this function is not supported on other DataBase Management Systems.
   * @since 3.0
   */

  public static int currVal(Connection oSQLConn, String sSequenceName)
      throws SQLException, UnsupportedOperationException {
    return currVal(new JDCConnection(oSQLConn, null), sSequenceName);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get next value for a sequence</p>
   * @param oConn JDCConnection
   * @param sSequenceName Sequence name.
   * In MySQL and SQL Server sequences are implemented using row locks at k_sequences table.
   * @return int Next sequence value
   * @throws SQLException
   * @throws UnsupportedOperationException Not all databases support sequences.
   * On Oracle and PostgreSQL, native SEQUENCE objects are used,
   * on Microsoft SQL Server the stored procedure k_sp_nextval simulates sequences,
   * this function is not supported on other DataBase Management Systems.
   * @since 3.0
   */
  public static int nextVal(JDCConnection oConn, String sSequenceName)
      throws SQLException, UnsupportedOperationException {

    Statement oStmt;
    ResultSet oRSet;
    CallableStatement oCall;
    int iNextVal;

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin hipergate DBBind.nextVal([JDCConnection], " + sSequenceName + ")" );
      DebugFile.incIdent();
      }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_MYSQL:
      case JDCConnection.DBMS_MSSQL:

        if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({call k_sp_nextval ('" + sSequenceName + "',?)})" );

        oCall = oConn.prepareCall("{call k_sp_nextval (?,?)}");
        oCall.setString(1, sSequenceName);
        oCall.registerOutParameter(2, java.sql.Types.INTEGER);
        oCall.execute();
        iNextVal = oCall.getInt(2);
        oCall.close();
        oCall = null;
        break;

      case JDCConnection.DBMS_POSTGRESQL:
        oStmt = oConn.createStatement();

        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT nextval('" + sSequenceName + "'))" );

        oRSet = oStmt.executeQuery("SELECT nextval('" + sSequenceName + "')");
        oRSet.next();
        iNextVal = oRSet.getInt(1);
        oRSet.close();
        oStmt.close();
        break;

      case JDCConnection.DBMS_ORACLE:
        oStmt = oConn.createStatement();

        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT nextval('" + sSequenceName + "'))" );

        oRSet = oStmt.executeQuery("SELECT " + sSequenceName + ".NEXTVAL FROM dual");
        oRSet.next();
        iNextVal = oRSet.getInt(1);
        oRSet.close();
        oStmt.close();
        break;

      default:
        throw new UnsupportedOperationException("function nextVal() not supported on current DBMS");
    }

    oConn = null;

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBBind.nextVal() : " + String.valueOf(iNextVal));
      }

    return iNextVal;
  } // nextVal

  // ----------------------------------------------------------

  /**
   * <p>Get next value for a sequence</p>
   * @param oSQLConn Database connection
   * @param sSequenceName Sequence name.
   * In MySQL and SQL Server sequences are implemented using row locks at k_sequences table.
   * @return int Next sequence value
   * @throws SQLException
   * @throws UnsupportedOperationException Not all databases support sequences.
   * On Oracle and PostgreSQL, native SEQUENCE objects are used,
   * on Microsoft SQL Server the stored procedure k_sp_nextval simulates sequences,
   * this function is not supported on other DataBase Management Systems.
   */

  public static int nextVal(Connection oSQLConn, String sSequenceName)
      throws SQLException, UnsupportedOperationException {

    return nextVal(new JDCConnection(oSQLConn, null), sSequenceName);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get next value for a sequence</p>
   * @param sSequenceName Sequence name.
   * In MySQL and SQL Server sequences are implemented using row locks at k_sequences table.
   * @return long Next sequence value
   * @throws SQLException
   * @throws UnsupportedOperationException Not all databases support sequences.
   * On Oracle and PostgreSQL, native SEQUENCE objects are used,
   * on Microsoft SQL Server the stored procedure k_sp_nextval simulates sequences,
   * this function is not supported on other DataBase Management Systems.
   * @since 7.0
   */
  public long nextVal(String sSequenceName) throws StorageException {
	  long lNextVal;
	  JDCConnection oConn = null;
	  try {
		  oConn = getConnection("nextVal."+sSequenceName);
		  lNextVal = nextVal(oConn, sSequenceName);
	  } catch (Exception xcpt) {
		  throw new StorageException(xcpt.getClass().getName()+" "+xcpt.getMessage(), xcpt);
	  } finally {
		  try {
			  if (oConn!=null)
				  if (!oConn.isClosed())
					  oConn.close("nextVal."+sSequenceName);
		  } catch (SQLException sqle) { }
	  }
	  return lNextVal;
  }
  
  // ----------------------------------------------------------

  /**
   * Format Date in ODBC escape sequence style
   * @param dt Date to be formated
   * @param sFormat Format Type "d" or "ts" or "shortTime".
   * Use d for { d 'yyyy-mm-dd' }, use ts for { ts 'ts=yyyy-mm-dd hh:nn:ss' }<br>
   * use shortTime for hh:mm<br>
   * use shortDate for yyyy-mm-dd<br>
   * use dateTime for yyyy-mm-dd hh:mm:ss<br>
   * @return Formated date
   * @throws IllegalArgumentException if dt is of type java.sql.Date
   */

  public static String escape(java.util.Date dt, String sFormat)
    throws IllegalArgumentException {
    String str = "";
    String sMonth, sDay, sHour, sMin, sSec;

    if (sFormat.equalsIgnoreCase("ts") || sFormat.equalsIgnoreCase("d")) {
      str = DBBind.Functions.escape(dt, sFormat);
    }
    else if (sFormat.equalsIgnoreCase("shortTime")) {
      sHour = (dt.getHours()<10 ? "0" + String.valueOf(dt.getHours()) : String.valueOf(dt.getHours()));
      sMin = (dt.getMinutes()<10 ? "0" + String.valueOf(dt.getMinutes()) : String.valueOf(dt.getMinutes()));
      str += sHour + ":" + sMin;
    }
    else if (sFormat.equalsIgnoreCase("shortDate")) {
      sMonth = (dt.getMonth()+1<10 ? "0" + String.valueOf((dt.getMonth()+1)) : String.valueOf(dt.getMonth()+1));
      sDay = (dt.getDate()<10 ? "0" + String.valueOf(dt.getDate()) : String.valueOf(dt.getDate()));

      str += String.valueOf(dt.getYear()+1900) + "-" + sMonth + "-" + sDay;
    } else {
      sMonth = (dt.getMonth()+1<10 ? "0" + String.valueOf((dt.getMonth()+1)) : String.valueOf(dt.getMonth()+1));
      sDay = (dt.getDate()<10 ? "0" + String.valueOf(dt.getDate()) : String.valueOf(dt.getDate()));
      sHour = (dt.getHours()<10 ? "0" + String.valueOf(dt.getHours()) : String.valueOf(dt.getHours()));
      sMin = (dt.getMinutes()<10 ? "0" + String.valueOf(dt.getMinutes()) : String.valueOf(dt.getMinutes()));
      sSec = (dt.getSeconds()<10 ? "0" + String.valueOf(dt.getSeconds()) : String.valueOf(dt.getSeconds()));

      str += String.valueOf(dt.getYear()+1900)+"-"+sMonth+"-"+sDay+" "+sHour+":"+sMin+":"+sSec;
    }

    return str;
  } // escape()

  // ----------------------------------------------------------

  /**
   * Format Timestamp in ODBC escape sequence style
   * @param ts Timestamp to be formated
   * @param sFormat Format Type "d" or "ts" or "shortTime".
   * Use d for { d 'yyyy-mm-dd' }, use ts for { ts 'ts=yyyy-mm-dd hh:nn:ss' }<br>
   * use shortTime for hh:mm<br>
   * use shortDate for yyyy-mm-dd<br>
   * use dateTime for yyyy-mm-dd hh:mm:ss<br>
   * @return Formated date
   * @since 3.0
   */

  public static String escape(Timestamp ts, String sFormat) {
    return DBBind.escape(new java.util.Date(ts.getTime()), sFormat);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get {@link DBTable} object by name</p>
   * @param sTable Table name
   * @return DBTable object or <b>null</b> if no table was found with given name.
   * @throws IllegalStateException DBTable objects are cached in a static HasMap,
   * the HashMap is loaded upon first call to a DBBind constructor. If getTable()
   * is called before creating any instance of DBBind an IllegalStateException
   * will be raised.
   * @deprecated Use {@link #getDBTable(String) getDBTable} instead
   */

  public static DBTable getTable(String sTable) throws IllegalStateException {

    if (null==oGlobalTableMap)
      throw new IllegalStateException("DBBind global table map not initialized, call DBBind constructor first");

    return (DBTable) oGlobalTableMap.get(sTable.toLowerCase());
  } // getTable

  // ----------------------------------------------------------

  /**
   * <p>Get {@link DBTable} object by name</p>
   * @param sTable Table name
   * @return DBTable object or <b>null</b> if no table was found with given name.
   * @throws IllegalStateException DBTable objects are cached in a static HasMap,
   * the HashMap is loaded upon first call to a DBBind constructor.
   * If getDBTable() is called before creating any instance of DBBind then an
   * IllegalStateException will be thrown.
   * @since 2.0
   */

  public DBTable getDBTable(String sTable) throws IllegalStateException {

    if (null==oTableMap)
      throw new IllegalStateException("DBBind internal table map not initialized, call DBBind constructor first");

    return (DBTable) oTableMap.get(sTable.toLowerCase());
  } // getDBTable

  /**
   * <p>Get map of {@link DBTable} objects</p>
   * @return HashMap
   * @throws IllegalStateException DBTable objects are cached in a static HasMap,
   * the HashMap is loaded upon first call to a DBBind constructor.
   * If getDBTablesMap() is called before creating any instance of DBBind
   * then an IllegalStateException will be thrown.
   * @since 3.0
   */
  public HashMap getDBTablesMap() throws IllegalStateException {

    if (null==oTableMap)
      throw new IllegalStateException("DBBind internal table map not initialized, call DBBind constructor first");

    return oTableMap;
  } // getDBTablesMap

  // ----------------------------------------------------------

  /**
   * <p>Get a {@link JDCConnection} instance from connection pool</p>
   * @param sCaller Symbolic name identifying the caller program or subroutine,
   * this field is used for statistical control of database accesses,
   * performance tunning and debugging open/close mismatch.
   * @return An open connection to the database.
   * @throws SQLException
   */

  public synchronized JDCConnection getConnection(String sCaller) throws SQLException {
    JDCConnection oConn;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBBind.getConnection(" + sCaller + ")");
      DebugFile.incIdent();
    }

    if (null!=oConnectXcpt) {

        if (DebugFile.trace) {
          DebugFile.writeln(oConnectXcpt.getClass().getName()+" "+oConnectXcpt.getMessage());
          if (oConnectXcpt.getCause()!=null) {
          	DebugFile.writeln(oConnectXcpt.getCause().getClass().getName()+" "+oConnectXcpt.getCause().getMessage());
          } // fi
          DebugFile.decIdent();
        } // fi

      if (oConnectXcpt instanceof SQLException) {
        throw (SQLException) oConnectXcpt;

      } else {
        throw new SQLException(oConnectXcpt.getClass().getName()+" "+oConnectXcpt.getMessage(), oConnectXcpt.getCause());
      }
    }

    if (null!=oConnPool) {
      oConn = oConnPool.getConnection(sCaller);
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("ERROR: connection pool not set");
      oConn = null;
    }

    if (DebugFile.trace) {
      if (oConn!=null) DebugFile.writeln("Connection process id. is " + oConn.pid());
      DebugFile.decIdent();
      DebugFile.writeln("End DBBind.getConnection(" + sCaller + ") : " + (null==oConn ? "null" : "[Connection]") );
    }

    return oConn;
  } // getConnection()

  // ----------------------------------------------------------

  /**
   * <p>Get a {@link JDCConnection} instance from connection pool</p>
   * @param sCaller Symbolic name identifying the caller program or subroutine,
   * this field is used for statistical control of database accesses,
   * performance tunning and debugging open/close mismatch.
   * @param bReadOnly <b>true</b> if connection must be put into read-only mode,
   * <b>false</b> otherwise
   * @return An open connection to the database.
   * @throws SQLException
   * @since 5.0
   */

  public synchronized JDCConnection getConnection(String sCaller, boolean bReadOnly)
  	throws SQLException {
    JDCConnection oConn = getConnection(sCaller);
	if (null!=oConn) oConn.setReadOnly(bReadOnly);
    return oConn;
  } // getConnection()

  // ----------------------------------------------------------

  /**
   * <p>Get a Connection instance from connection pool</p>
   * @param sCaller Symbolic name identifying the caller program or subroutine,
   * this field is used for statistical control of database accesses,
   * performance tunning and debugging open/close mismatch.
   * @return An open connection to the database.
   * @throws SQLException
   * @since 4.0
   */

  public synchronized Connection getConnection() throws SQLException {
    return getConnection(null);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get a Connection instance directly from the database bypassing the pool</p>
   * @param sUser User name
   * @param sPasswd Password
   * @return An open connection to the database.
   * Returned type is actually an unpooled com.knowgate.jdc.JDCConnection instance.
   * @throws SQLException
   */

  public synchronized Connection getConnection(String sUser, String sPasswd) throws SQLException {
    Connection oConn;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBBind.getConnection(" + sUser + ", ...)");
      DebugFile.incIdent();

      if (null!=oConnectXcpt) {
        DebugFile.writeln("Previous exception " + oConnectXcpt.getMessage());
        DebugFile.decIdent();
      }
    }

    if (null!=oConnectXcpt) {
      if (oConnectXcpt instanceof SQLException)
        throw (SQLException) oConnectXcpt;
      else
        throw new SQLException(oConnectXcpt.getClass().getName()+" "+oConnectXcpt.getMessage());
    }

    if (sUser==null && sPasswd==null)
      oConn = DriverManager.getConnection(getProperty("dburl"));
    else
      oConn = DriverManager.getConnection(getProperty("dburl"), sUser, sPasswd);   

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBBind.getConnection() : " + (null==oConn ? "null" : "[Connection]") );
    }

	return (Connection) new JDCConnection(oConn, null);
  } // getConnection()

   // ---------------------------------------------------------

   /**
	* Get LogWriter from java.sql.DriverManager
	* @since 4.0
    */
   public PrintWriter getLogWriter() throws SQLException {
     return DriverManager.getLogWriter();
   }

   // ---------------------------------------------------------

   /**
	* Set LogWriter for java.sql.DriverManager
	* @since 4.0
    */
   public void setLogWriter(PrintWriter printwrt) throws SQLException {
     DriverManager.setLogWriter(printwrt);
   }

   // ---------------------------------------------------------

   /**
	* Get login timeout from java.sql.DriverManager
	* @since 4.0
    */
   public int getLoginTimeout() throws SQLException {
     return DriverManager.getLoginTimeout();
   }

   // ---------------------------------------------------------

   /**
	* Set login timeout for java.sql.DriverManager
	* @since 4.0
    */
   public void setLoginTimeout(int seconds) throws SQLException {
     DriverManager.setLoginTimeout(seconds);
   }

   // ----------------------------------------------------------

   public boolean isWrapperFor(Class c) {
     return false;
   }

   // ----------------------------------------------------------

   public Object unwrap(Class c) {
     return null;
   }
    
   // ----------------------------------------------------------
   /**
    *
    * @return Get Current System Time
    */

   public static long getTime() {

    return System.currentTimeMillis();
   }

   // ----------------------------------------------------------
   
   /**
    * This method is added for compatibility with Java 7 and it is not iplemented
    * @return null
    * @since 7.0
    */
   public Logger getParentLogger() {
	   return null;
   }
   
  // ----------------------------------------------------------

  /**
   * Dump table definitions as a database independent XML file
   * @since 6.0
   */
  public String toXml() {
  	StringBuffer oXml = new StringBuffer(32000);
  	oXml.append("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<MetaData>\n");
  	oXml.append("  <Schema name=\""+getProfileName()+"\">");
	Iterator<String> oTbls = getDBTablesMap().keySet().iterator();
	while (oTbls.hasNext()) {
	  DBTable oTbl = getDBTable(oTbls.next());
	  if (!oTbl.getName().endsWith("_lookup") && !(oTbl.getName().indexOf("_lu_")>0) ) {
	  LinkedList<String> oPk = oTbl.getPrimaryKey();
	  LinkedList<DBIndex> oIx = oTbl.getIndexes();
  	  oXml.append("  <Table name=\""+oTbl.getName()+"\">\n");
  	  ListIterator<Column> oCols = oTbl.getColumns().listIterator();
  	  while (oCols.hasNext()) {
  	    Column oCol = oCols.next();
  	    oXml.append("    <Column name=\""+oCol.getName()+"\" type=\""+Column.typeName(oCol.getType())+"\" ");
  	    oXml.append("maxlength=\""+oCol.getPrecision()+"\" nullable=\""+oCol.isNullable()+"\"");
  	    if (oPk!=null) {
  	      for (String p : oPk) {
  	      	if (p.equalsIgnoreCase(oCol.getName()))
  	    	  oXml.append(" constraint=\"primary key\"");
  	      } // next
  	    } // fi
  	    if (oIx!=null) {
  	      for (DBIndex i : oIx) {
			for (String c : i.getColumns()) {
  	      	  if (c.equalsIgnoreCase(oCol.getName())) {
  	    	    oXml.append(" indexed=\"true\"");			  
			  } // fi
  	        } // next
  	      } // next
  	    } // fi
  	    oXml.append("></Column>\n");
   	  }
  	  oXml.append("  </Table>\n");
	  }	  
	} // wend
  	oXml.append("  </Schema>");
  	return oXml.toString();
  } // toXml

  // ===========================================================================

  /**
   * <p>Aliases for common SQL functions in different database dialects.</p>
   * @author Sergio Montoro Ten
   * @version 6.0
   */

  public static class Functions {

    /**
     * <p>ISNULL(value, default)</p>
     * Get value or default if value is null
     */
    public static String ISNULL;

    /**
     * <p>String concatenation</p>
     * Str1 CONCAT Str2
     */
    public static String CONCAT;

    /**
     * Get System Date
     */
    public static String GETDATE;

    /**
     * <p>Transform String to lowercase</p>
     * LOWER(str)
     */
    public static String LOWER;


    /**
     * <p>Transform String to uppercase</p>
     * UPPER(str)
     */
    public static String UPPER;

    /**
     * <p>Get string length</p>
     * LENGTH(str)
     */
    public static String LENGTH;


    /**
     * <p>Get character from ASCII code</p>
     * CHAR([0..255])
     */
    public static String CHR;

    /**
     * <p>Case-insensitve LIKE operator (PostgreSQL only)</p>
     */
    public static String ILIKE;

    public static int iDBMS;

    // -------------------------------------------------------------------------

    private static void setForDBMS(String sDBMSName) throws UnsupportedOperationException {

      if (sDBMSName.equals("Microsoft SQL Server")) {
        iDBMS = JDCConnection.DBMS_MSSQL;
        ISNULL = "ISNULL";
        CONCAT = "+";
        GETDATE = "GETDATE()";
        LOWER = "LOWER";
        UPPER = "UPPER";
        LENGTH = "LEN";
        CHR = "CHAR";
        ILIKE = "LIKE";

      } else if (sDBMSName.equals("Oracle")) {
        iDBMS = JDCConnection.DBMS_ORACLE;
        ISNULL = "NVL";
        CONCAT = "||";
        GETDATE = "SYSDATE";
        LOWER = "LOWER";
        UPPER = "UPPER";
        LENGTH = "LENGTH";
        CHR = "CHR";
        ILIKE = "LIKE";

      } else if (sDBMSName.equals("PostgreSQL")) {
        iDBMS = JDCConnection.DBMS_POSTGRESQL;
        ISNULL = "COALESCE";
        CONCAT = "||";
        GETDATE = "current_timestamp";
        LOWER = "lower";
        UPPER = "upper";
        LENGTH = "char_length";
        CHR = "chr";
        ILIKE = "ILIKE";

      } else if (sDBMSName.equals("MySQL")) {
        iDBMS = JDCConnection.DBMS_MYSQL;
        ISNULL = "COALESCE";
        CONCAT = null; // MySQL uses CONCAT() function instead of an operator
        GETDATE = "NOW()";
        LENGTH = "CHAR_LENGTH";
        CHR = "CHAR";
        LOWER = "LCASE";
        UPPER = "UCASE";
        ILIKE = "LIKE";

      } else if (sDBMSName.equals("ACCESS")) {
        iDBMS = JDCConnection.DBMS_ACCESS;
        ISNULL = "NZ";
        CONCAT = "&";
        GETDATE = "NOW()";
        LENGTH = "LEN";
        CHR = "CHR";
        LOWER = "LCASE";
        UPPER = "UCASE";
        ILIKE = "LIKE";

      } else if (sDBMSName.equals("SQLite")) {
        iDBMS = JDCConnection.DBMS_SQLITE;
        ISNULL = "coalesce";
        CONCAT = "||";
        GETDATE = "date('now')";
        LENGTH = "length";
        CHR = null; // SQLite does not have a CHR function
        LOWER = "lower";
        UPPER = "upper";
        ILIKE = "LIKE";

      } else if (sDBMSName.equals("StelsDBF JDBC driver") ||
      	         sDBMSName.equals("HXTT DBF")) {
        iDBMS = JDCConnection.DBMS_XBASE;
        ISNULL = "ISNULL";
        CONCAT = "+"; 
        GETDATE = "CURDATE()";
        LENGTH = "CHAR_LENGTH";
        CHR = "CHAR";
        LOWER = "LOWER";
        UPPER = "UPPER";
        ILIKE = "LIKE";
      } else
        throw new UnsupportedOperationException("unsupported DBMS");

    } // setForDBMS

    // -------------------------------------------------------------------------

    private static String escape(java.util.Date dt, String sFormat) throws UnsupportedOperationException {
      String str;
      String sMonth, sDay, sHour, sMin, sSec;

      sMonth = (dt.getMonth()+1<10 ? "0" + String.valueOf((dt.getMonth()+1)) : String.valueOf(dt.getMonth()+1));
      sDay = (dt.getDate()<10 ? "0" + String.valueOf(dt.getDate()) : String.valueOf(dt.getDate()));
      sHour = (dt.getHours()<10 ? "0" + String.valueOf(dt.getHours()) : String.valueOf(dt.getHours()));
      sMin = (dt.getMinutes()<10 ? "0" + String.valueOf(dt.getMinutes()) : String.valueOf(dt.getMinutes()));
      sSec = (dt.getSeconds()<10 ? "0" + String.valueOf(dt.getSeconds()) : String.valueOf(dt.getSeconds()));

      switch (iDBMS) {

        case JDCConnection.DBMS_MSSQL:
          str = "{ " + sFormat.toLowerCase() + " '";

          str += String.valueOf(dt.getYear()+1900) + "-" + sMonth + "-" + sDay + " ";

          if (sFormat.equalsIgnoreCase("ts")) {
            str += sHour + ":" + sMin +  ":" + sSec;
          }

          str = str.trim() + "'}";
          break;

        case JDCConnection.DBMS_ORACLE:
          if (sFormat.equalsIgnoreCase("ts"))
            str = "TO_DATE('" + String.valueOf(dt.getYear()+1900) + "-" + sMonth + "-" + sDay + " " + sHour + ":" + sMin +  ":" + sSec + "','YYYY-MM-DD HH24-MI-SS')";
          else
            str = "TO_DATE('" + String.valueOf(dt.getYear()+1900) + "-" + sMonth + "-" + sDay + "','YYYY-MM-DD')";
          break;

        case JDCConnection.DBMS_POSTGRESQL:
          if (sFormat.equalsIgnoreCase("ts"))
            str = "TIMESTAMP '" + String.valueOf(dt.getYear()+1900) + "-" + sMonth + "-" + sDay + " " + sHour + ":" + sMin +  ":" + sSec + "'";
          else
            str = "DATE '" + String.valueOf(dt.getYear()+1900) + "-" + sMonth + "-" + sDay + "'";
          break;

        case JDCConnection.DBMS_MYSQL:
          if (sFormat.equalsIgnoreCase("ts"))
            str = "CAST('" + String.valueOf(dt.getYear()+1900) + "-" + sMonth + "-" + sDay + " " + sHour + ":" + sMin +  ":" + sSec + "' AS DATETIME)";
          else
            str = "CAST('" + String.valueOf(dt.getYear()+1900) + "-" + sMonth + "-" + sDay + "' AS DATE)";
          break;

        case JDCConnection.DBMS_ACCESS:
          if (sFormat.equalsIgnoreCase("ts"))
            str = "CDate('" + sMonth + "/" + sDay + "/" + String.valueOf(dt.getYear()+1900) + " " + sHour + ":" + sMin +  ":" + sSec + "')";
          else
            str = "CDate('" + sMonth + "/" + sDay + "/" + String.valueOf(dt.getYear()+1900) + "')";
          break;

        case JDCConnection.DBMS_XBASE:
          if (sFormat.equalsIgnoreCase("ts"))
            throw new UnsupportedOperationException("DBBind.Functions.escape(Date,String) unsupported casting to TIMESTAMP");
          else
            str = "'"+sMonth+"/"+sDay+"/"+String.valueOf(dt.getYear()+1900)+"'";
          break;
        default:
          throw new UnsupportedOperationException("DBBind.Functions.escape(Date,String) unsupported DBMS");
      } // end switch()

      return str;
    } // escape()

    // -------------------------------------------------------------------------

	/**
	 * Cast into CHARACTER VARYING SQL TYPE
	 * @param oData Object of any type
	 * @param iLength Maximum length of character data
	 * return <br/>
	 * For Oracle: TO_CHAR(oData)<br/>
	 * For MySQL: CAST(oData AS CHAR)<br/>
	 * For PostgreSQL and SQL Server: CAST(oData AS VARCHAR(iLength))<br/>
	 * For Access: CStr(oData)
	 */
    public static String toChar(Object oData, int iLength) throws UnsupportedOperationException {
      String sRetVal;

      switch (iDBMS) {
        case JDCConnection.DBMS_ORACLE:
          if (null==oData)
            sRetVal = "NULL";
          else	
            sRetVal = "TO_CHAR(" + oData.toString() + ")";
          break;
        case JDCConnection.DBMS_MYSQL:
          if (null==oData)
            sRetVal = "NULL";
          else	
            sRetVal = "CAST(" + oData.toString() + " AS CHAR)";
          break;
        case JDCConnection.DBMS_POSTGRESQL:
        case JDCConnection.DBMS_MSSQL:
          if (null==oData)
            sRetVal = "NULL";
          else	
            sRetVal = "CAST(" + oData.toString() + " AS VARCHAR(" + String.valueOf(iLength) + "))";
          break;
        case JDCConnection.DBMS_ACCESS:
          if (null==oData)
            sRetVal = "NULL";
          else	
            sRetVal = "CStr(" + oData.toString() + ")";
          break;
        case JDCConnection.DBMS_XBASE:
          if (null==oData)
            sRetVal = "NULL";
          else	
            sRetVal = oData.toString();
          break;
        default:
          throw new UnsupportedOperationException("DBBind.Functions.toChar(Date,String) unsupported DBMS");
      }

      return sRetVal;
    } // toChar()

    /**
     * Create a SQL expressions which concatenates the given ones
     */
    public static String strCat(String[] aExpressions, char cPlaceBetween) {
      String sRetExpr;
      if (null==aExpressions) {
        sRetExpr = null;
      } else if (aExpressions.length==0) {
        sRetExpr = "''";
      } else {
        switch (iDBMS) {
          case JDCConnection.DBMS_MYSQL:
            sRetExpr = "CONCAT(";
            for (int e=0; e<aExpressions.length; e++) {
              sRetExpr += (0==e ? "" : ",") + ISNULL + "(" + aExpressions[e] + ",'')";
              if (cPlaceBetween!=0 && e<aExpressions.length-1)
                sRetExpr += ",'"+cPlaceBetween+"'";
            } // next
            sRetExpr += ")";
            break;
          default:
            sRetExpr = "";
            for (int e=0; e<aExpressions.length; e++) {
              sRetExpr += (0==e ? "" : CONCAT) + ISNULL +"(" + aExpressions[e] + ",'')";
              if (cPlaceBetween!=0 && e<aExpressions.length-1)
                sRetExpr += CONCAT+"'"+cPlaceBetween+"'";
            } // next
        }
      } // fi
      return sRetExpr;
    } // strCat
    
  } // Functions

  // ===========================================================================

  public static final int DBMS_GENERIC = 0;
  public static final int DBMS_MYSQL = 1;
  public static final int DBMS_POSTGRESQL = 2;
  public static final int DBMS_MSSQL = 3;
  public static final int DBMS_ORACLE = 5;

  private static final int DBMS_UNKNOWN = -1;
  private static final int DBMS_SYBASE = 4;
  private static final int DBMS_B2 = 6;
  private static final int DBMS_INFORMIX = 7;
  private static final int DBMS_DERBY = 8;
  private static final int DBMS_XBASE = 9;
  public static final int DBMS_ACCESS = 10;
  public static final int DBMS_SQLITE = 11;

  private static final String DBMSNAME_MSSQL = "Microsoft SQL Server";
  private static final String DBMSNAME_POSTGRESQL = "PostgreSQL";
  private static final String DBMSNAME_ORACLE = "Oracle";
  private static final String DBMSNAME_MYSQL = "MySQL";
  private static final String DBMSNAME_XBASE = "XBase";
  private static final String DBMSNAME_ACCESS = "ACCESS";
  private static final String DBMSNAME_SQLITE = "SQLite";

} // DBBind
