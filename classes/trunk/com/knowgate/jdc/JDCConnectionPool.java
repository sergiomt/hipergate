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

import java.io.PrintWriter;

import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.ListIterator;
import java.util.Vector;
import java.util.Enumeration;
import java.util.Date;
import java.util.ConcurrentModificationException;
import java.util.logging.Logger;

import java.text.SimpleDateFormat;

import java.sql.CallableStatement;
import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.sql.ConnectionPoolDataSource;
import javax.sql.PooledConnection;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

import com.knowgate.storage.Table;
import com.knowgate.storage.Engine;
import com.knowgate.storage.Record;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.SchemaMetaData;
import com.knowgate.storage.StorageException;

/**
 * <p>Connection pool daemon thread</p>
 * This thread scans a ConnectionPool every given interval calling
 * ConnectionPool.reapConnections() for closing unused connections.
 */

final class ConnectionReaper extends Thread {

   /**
    * Reference to reaped connection pool
    */
    private JDCConnectionPool pool;

    /**
     * Used to stop the Connection reaper thread
     */
    private boolean keepruning;

   /**
    * Connection Reaper call interval (default = 10 mins)
    */
    private long delay=600000l;

    /**
     * <p>Constructor</p>
     * @param forpool JDCConnectionPool
     */
    ConnectionReaper(JDCConnectionPool forpool) {
        pool = forpool;
        keepruning = true;
        try {
          checkAccess();
          setDaemon(true);
          setPriority(MIN_PRIORITY);
        } catch (SecurityException ignore) { }
    }

    /**
     * Get connection reaper call interval
     * @return long Number of miliseconds between reaper calls
     * @since 3.0
     */
    public long getDelay() {
      return delay;
    }

    /**
     * <p>Set connection reaper call interval</p>
     * The default value is 10 minutes
     * @param lDelay long Number of miliseconds between reaper calls
     * @throws IllegalArgumentException if lDelay is less than 1000
     * @since 3.0
     */
    public void setDelay(long lDelay) throws IllegalArgumentException {
      if (lDelay<1000l && lDelay>0l)
        throw new IllegalArgumentException("ConnectionReaper delay cannot be smaller than 1000 miliseconds");
      delay=lDelay;
    }

    public void halt() {
      keepruning=false;
    }

    /**
     * Reap connections every n-minutes
     */
    public void run() {
        while (keepruning) {
           try {
             sleep(delay);
           } catch( InterruptedException e) { }
           if (keepruning) pool.reapConnections();
        } // wend
    } // run
} // ConnectionReaper

// ---------------------------------------------------------

  /**
   * <p>JDBC Connection Pool</p>
   * <p>Implementation of a standard JDBC connection pool.</p>
   * @version 7.0
   */

public final class JDCConnectionPool implements ConnectionPoolDataSource,DataSource {

   private javax.sql.DataSource binding;
   private Vector<JDCConnection> connections;
   private int openconns;
   private HashMap callers;
   private String url, user, password;
   private ConnectionReaper reaper;
   private LinkedList errorlog;

   /**
    * Staled connection threshold (10 minutes)
    * The maximum time that any SQL single statement may last.
    */
   private long timeout = 600000l;

   /**
    * Soft limit for maximum open connections
    */
   private int poolsize = 32;

   /**
    * Hard absolute limit for maximum open connections
    */
   private int hardlimit = 100;

   // ---------------------------------------------------------

   public JDCConnectionPool() {
     binding = null;
     url = null;
     user = null;
     password = null;
     openconns = 0;
     connections = null;
     reaper = null;
   }

   /**
    * Constructor
    * By default, maximum pool size is set to 32,
    * maximum opened connections is 100,
    * login timeout is 20 seconds,
    * connection timeout is 5 minutes.
    * @param url JDBC URL string
    * @param user Database user
    * @param password Password for user
    */

   public JDCConnectionPool(String url, String user, String password)
   	 throws StorageException {
     open(url, user, password, false);
    }

   // ---------------------------------------------------------

   /**
    * <p>Constructor</p>
    * This method sets a default login timeout of 20 seconds
    * @param bind DBBind owner of the connection pool (may be <b>null</b>)
    * @param url JDBC URL string
    * @param user Database user
    * @param password Password for user
    * @param maxpoolsize Maximum pool size
    * @param maxconnections Maximum opened connections
    * @param connectiontimeout Maximum time that a
    * @param logintimeout Maximum time, in seconds, to wait for connection
    * @since v2.2
    */

   public JDCConnectionPool(Object bind, String url, String user, String password,
                            int maxpoolsize, int maxconnections,
                            int logintimeout, long connectiontimeout) {

      binding = (javax.sql.DataSource) bind;

      if (null==url)
        throw new IllegalArgumentException("JDCConnectionPool : url cannot be null");

      if (url.length()==0)
        throw new IllegalArgumentException("JDCConnectionPool : url value not set");

      if (maxpoolsize<1)
        throw new IllegalArgumentException("maxpoolsize must be greater than or equal to 1");

      if (maxconnections<1)
        throw new IllegalArgumentException("maxpoolsize must be greater than or equal to 1");

      if (maxpoolsize>maxconnections)
        throw new IllegalArgumentException("maxpoolsize must be less than or equal to maxconnections");

      this.url = url;
      this.user = user;
      this.password = password;
      this.openconns = 0;
      this.poolsize = maxpoolsize;
      this.hardlimit = maxconnections;
      this.timeout = connectiontimeout;

      DriverManager.setLoginTimeout(logintimeout);

      connections = new Vector<JDCConnection>(poolsize<=hardlimit ? poolsize : hardlimit);
      reaper = new ConnectionReaper(this);
      reaper.start();

      if (DebugFile.trace) callers = new HashMap(1023);

      errorlog = new LinkedList();
   }

   /**
    * <p>Constructor</p>
    * This method sets a default login timeout of 20 seconds
    * @param bind DBBind owner of the connection pool (may be <b>null</b>)
    * @param url JDBC URL string
    * @param user Database user
    * @param password Password for user
    * @param maxpoolsize Maximum pool size
    * @param maxconnections Maximum opened connections
    * @param logintimeout Maximum time, in seconds, to wait for connection
    * @since v2.2
    */

   public JDCConnectionPool(Object bind, String url, String user, String password,
                            int maxpoolsize, int maxconnections,
                            int logintimeout) {
     this(bind,url,user,password,maxpoolsize,maxconnections,logintimeout,60000l);
   }

   // ---------------------------------------------------------

   /**
    * <p>Constructor</p>
    * This method sets a default login timeout of 20 seconds
    * @param bind DBBind owner of the connection pool (may be <b>null</b>)
    * @param url JDBC URL string
    * @param user Database user
    * @param password Password for user
    * @param maxpoolsize Maximum pool size (Default 32)
    * @param maxconnections Maximum opened connections (Default 100)
    */
   public JDCConnectionPool(Object bind, String url, String user, String password,
                            int maxpoolsize, int maxconnections) {
     this(bind,url,user,password,maxpoolsize,maxconnections,20);
   }

   // ---------------------------------------------------------

   /**
    * <p>Constructor</p>
    * @param url JDBC URL string
    * @param user Database user
    * @param password Password for user
    * @param maxpoolsize Maximum pool size (Default 32)
    * @param maxconnections Maximum opened connections (Default 100)
    * @param logintimeout Maximum time, in seconds, to wait for connection
    * @since v2.2
    */

   public JDCConnectionPool(String url, String user, String password,
                            int maxpoolsize, int maxconnections,
                            int logintimeout) {

     binding = null;

     if (null==url)
       throw new IllegalArgumentException("JDCConnectionPool : url cannot be null");

     if (url.length()==0)
       throw new IllegalArgumentException("JDCConnectionPool : url value not set");

     if (maxpoolsize<1)
       throw new IllegalArgumentException("maxpoolsize must be greater than or equal to 1");

     if (maxconnections<1)
       throw new IllegalArgumentException("maxpoolsize must be greater than or equal to 1");

     if (maxpoolsize>maxconnections)
       throw new IllegalArgumentException("maxpoolsize must be less than or equal to maxconnections");

     this.url = url;
     this.user = user;
     this.password = password;
     this.openconns = 0;
     this.poolsize = maxpoolsize;
     this.hardlimit = maxconnections;

     DriverManager.setLoginTimeout(logintimeout);

     connections = new Vector<JDCConnection>(poolsize);
     reaper = new ConnectionReaper(this);
     reaper.start();

     if (DebugFile.trace) callers = new HashMap(1023);

     errorlog = new LinkedList();
   }

   // ---------------------------------------------------------

   /**
    * <p>Constructor</p>
    * This method sets a default login timeout of 20 seconds
    * @param url JDBC URL string
    * @param user Database user
    * @param password Password for user
    * @param maxpoolsize Maximum pool size
    * @param maxconnections Maximum opened connections
    */

   // ---------------------------------------------------------

   public JDCConnectionPool(String url, String user, String password, int maxpoolsize, int maxconnections) {
     this(url,user,password,maxpoolsize,maxconnections,20);
   }

   // ---------------------------------------------------------

   private synchronized void modifyMap (String sCaller, int iAction)
     throws NullPointerException {

     if (null==callers) callers = new HashMap(1023);

     if (callers.containsKey(sCaller)) {
       Integer iRefCount = new Integer(((Integer) callers.get(sCaller)).intValue()+iAction);
       callers.remove(sCaller);
       callers.put(sCaller, iRefCount);
       DebugFile.writeln("  " + sCaller + " reference count is " + iRefCount.toString());
     }
     else {
       if (1==iAction) {
         callers.put(sCaller, new Integer(1));
         DebugFile.writeln("  " + sCaller + " reference count is 1");
       }
       else {
         DebugFile.writeln("  ERROR: JDCConnectionPool get/close connection mismatch for " + sCaller);
       }
     }
   } // modifyMap

   // ---------------------------------------------------------

   /**
    * @return Engine.JDBCRDBMS
    * @since 6.0
    */
   public Engine getEngine() {
   	 return Engine.JDBCRDBMS;
   }

   // ---------------------------------------------------------

   /**
    * <p>Open ConnectionPool</p>
    * By default, maximum pool size is set to 32,
    * maximum opened connections is 100,
    * login timeout is 20 seconds,
    * connection timeout is 5 minutes.
    * @param url JDBC URL string
    * @param user Database user
    * @param password Password for user
    */

   public void open(String url, String user, String password, boolean readonly)
   	 throws StorageException {

     binding = null;

      if (null==url)
        throw new StorageException("JDCConnectionPool : url cannot be null");

      if (url.length()==0)
        throw new StorageException("JDCConnectionPool : url value not set");

      this.url = url;
      this.user = user;
      this.password = password;
      this.openconns = 0;

      DriverManager.setLoginTimeout(20); // default login timeout = 20 seconds

      connections = new Vector<JDCConnection>(poolsize<=hardlimit ? poolsize : hardlimit);
      reaper = new ConnectionReaper(this);
      reaper.start();

      if (DebugFile.trace) callers = new HashMap(1023);

      errorlog = new LinkedList();
    }

   // ---------------------------------------------------------

   /**
    * Close all connections and stop connection reaper
    */
   public void close() {
      if (DebugFile.trace) {
        DebugFile.writeln("Begin ConnectionPool.close()");
        DebugFile.incIdent();
      }

     if (null!=reaper) reaper.halt();

     reaper = null;

     closeConnections();

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End ConnectionPool.close()");
     }
   } // close

   // ---------------------------------------------------------

   public boolean isClosed() {
     return (reaper==null);
   }

   // ---------------------------------------------------------

   /**
    * <p>Get prefered open connections limit</p>
    * <p>Additional connections beyond PoolSize may be opened but they
    * will closed inmediately after use and not pooled.<br>The default value is 32.</p>
    * @return open connections soft limit
    */
   public int getPoolSize() {
     return poolsize;
   }

   // ---------------------------------------------------------

   /**
    * <p>Set prefered open connections limit</p>
    * <p>Additional connections beyond PoolSize may be opened but they
    * will closed inmediately after use and not pooled.<br>The default value is 32.<br>
    * Connections not being used can only be in the pool for a maximum of five minutes.<br>
    * After a connection is not used for over 5 minutes it will be closed so the actual
    * pool size will eventually go down to zero after a period of inactivity.</p>
    * @param iPoolSize Maximum pooled connections
    */

   public void setPoolSize(int iPoolSize) {

     if (iPoolSize>hardlimit)
       throw new IllegalArgumentException("prefered pool size must be less than or equal to max pool size ");

     reapConnections();
     poolsize = iPoolSize;
   }

   // ---------------------------------------------------------

   /**
    * <p>Set maximum concurrent open connections limit</p>
    * The default value is 100.<br>
    * If iMaxConnections is set to zero then the connection pool is effectively
    * turned off and no pooling occurs.
    * @param iMaxConnections Absolute maximum for opened connections
    */
   public void setMaxPoolSize(int iMaxConnections) {

     if (iMaxConnections==0) {
       reapConnections();
       poolsize = hardlimit = 0;
     } else {
       if (iMaxConnections<poolsize)
         throw new IllegalArgumentException("max pool size must be greater than or equal to prefered pool size ");

       reapConnections();
       hardlimit = iMaxConnections;
     }
   }

   // ---------------------------------------------------------

   /**
    * <p>Absolute maximum allowed for concurrent opened connections.</p>
    * The default value is 100.
    */
   public int getMaxPoolSize() {
     return hardlimit;
   }

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

   // ---------------------------------------------------------

   /**
    * <p>Get staled connection threshold</p>
    * The default value is 600000ms (10 mins.)<br>
    * This implies that all database operations done using connections
    * obtained from the pool must be completed before 10 minutes or else
    * they can be closed by the connection reaper before their normal finish.
    * @return The maximum amount of time in miliseconds that a JDCConnection
    * can be opened and not used before considering it staled.
    */
   public long getTimeout() {
     return timeout;
   }

   // ---------------------------------------------------------

   /**
    * <p>Set staled connection threshold</p>
    * @param miliseconds The maximum amount of time in miliseconds that a JDCConnection
    * can be opened and not used before considering it staled.<BR>
    * Default value is 600000ms (10 mins.) Minimum value is 1000.
    * @throws IllegalArgumentException If miliseconds<1000
    */

   public void setTimeout(long miliseconds)
     throws IllegalArgumentException {

     if (miliseconds<1000l)
       throw new IllegalArgumentException("Connection timeout must be at least 1000 miliseconds");

     timeout = miliseconds;
   }

   /**
    * Delay betwwen connection reaper executions
    * @return long Number of miliseconds
    * @since 3.0
    */
   public long getReaperDaemonDelay() {
     if (reaper!=null)
       return reaper.getDelay();
     else
       return 0l;
   }

   /**
    * Set delay betwwen connection reaper executions (default value is 5 mins)
    * @param lDelayMs long Miliseconds
    * @throws IllegalArgumentException if lDelayMs is less than 1000
    * @since 3.0
    */
   public void setReaperDaemonDelay(long lDelayMs) throws IllegalArgumentException {
     if (lDelayMs>0l) {
       if (reaper==null) reaper = new ConnectionReaper(this);
       reaper.setDelay(lDelayMs);
     }
     else {
       if (reaper!=null) reaper.halt();
       reaper=null;
     }
   }

   // ---------------------------------------------------------

   /**
    * Close and remove one connection from the pool
    * @param conn Connection to close
    */

   protected synchronized void disposeConnection(JDCConnection conn) {
     boolean bClosed;
     String sCaller = "";

       try {
         if (DebugFile.trace) logConnection (conn, "disposeConnection", "RDBC", null);

         sCaller = conn.getName();
         if (!conn.isClosed()) {         	
         	conn.getConnection().close();
         	conn.notifyClose();
         }
         conn.expireLease();
         if (DebugFile.trace && (null!=sCaller)) modifyMap(sCaller,-1);
         bClosed = true;
       }
       catch (SQLException e) {
         bClosed = false;

         if (errorlog.size()>100) errorlog.removeFirst();
         errorlog.addLast(new Date().toString() + " " + sCaller + " Connection.close() " + e.getMessage());

         if (DebugFile.trace) DebugFile.writeln("SQLException at JDCConnectionPool.disposeConnection() : " + e.getMessage());
       }

       if (bClosed) {
         if (DebugFile.trace) DebugFile.writeln("connections.removeElement(" + String.valueOf(openconns) + ")");
         connections.removeElement(conn);
         openconns--;
       }
   } // disposeConnection()

   // ---------------------------------------------------------

   /**
    * Called from the connection reaper daemon thread every n-minutes for maintaining the pool clean
    */

   synchronized void reapConnections() {

      if (DebugFile.trace) {
        DebugFile.writeln("Begin JDCConnectionPool.reapConnections()");
        DebugFile.incIdent();
      }

      long stale = System.currentTimeMillis() - timeout;
      Enumeration<JDCConnection> connlist = connections.elements();
      JDCConnection conn;

      while((connlist != null) && (connlist.hasMoreElements())) {
          conn = (JDCConnection) connlist.nextElement();

          // Remove each connection that is not in use or
          // is stalled for more than maximun usage timeout (default 10 mins)
          if (!conn.inUse())
            disposeConnection(conn);
          else if (stale>conn.getLastUse()) {
            if (DebugFile.trace) DebugFile.writeln("Connection "+conn.getName()+" was staled since "+new Date(conn.getLastUse()).toString());
            if (errorlog.size()>100) errorlog.removeFirst();
            errorlog.addLast(new Date().toString()+" Connection "+conn.getName()+" was staled since "+new Date(conn.getLastUse()).toString());
            disposeConnection(conn);
          }
      } // wend

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End JDCConnectionPool.reapConnections() : " + new Date().toString());
      }
   } // reapConnections()

   // ---------------------------------------------------------

   /**
    * Close all connections from the pool regardless of their current state
    */

   public void closeConnections() {

     Enumeration connlist;

     if (DebugFile.trace) {
       DebugFile.writeln("Begin JDCConnectionPool.closeConnections()");
       DebugFile.incIdent();
     }

      connlist = connections.elements();

      if (connlist != null) {
        while (connlist.hasMoreElements()) {
          disposeConnection ((JDCConnection) connlist.nextElement());
        } // wend
      } // fi ()

      if (DebugFile.trace) callers.clear();

      connections.clear();

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End JDCConnectionPool.closeConnections() : " + String.valueOf(openconns));
      }

      openconns = 0;
   } // closeConnections()

   // ---------------------------------------------------------

   /**
    * Close connections from the pool not used for a longer time
    * @return Count of staled connections closed
    */

   public int closeStaledConnections() {

     JDCConnection conn;
     Enumeration connlist;

     if (DebugFile.trace) {
       DebugFile.writeln("Begin JDCConnectionPool.closeStaledConnections()");
       DebugFile.incIdent();
     }

     int staled = 0;
     final long stale = System.currentTimeMillis() - timeout;

     connlist = connections.elements();

      if (connlist != null) {
        while (connlist.hasMoreElements()) {
          conn = (JDCConnection) connlist.nextElement();
          if (stale>conn.getLastUse()) {
            staled++;
            disposeConnection (conn);
          }
        } // wend
      } // fi ()

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End JDCConnectionPool.closeStaledConnections() : " + String.valueOf(staled));
      }

      return staled;
   } // closeStaledConnections()

   // ---------------------------------------------------------

   private static void logConnection(JDCConnection conn, String sName, String cOpCode, String sParams) {

     if (DebugFile.trace) {
       com.knowgate.dataobjs.DBAudit.log(JDCConnection.IdClass, cOpCode, "", sName, "", 0, "", sParams, "");
     }

   } // logConnection

   // ---------------------------------------------------------

   /**
    * Get an array with references to all pooled connections
    */
   public synchronized JDCConnection[] getAllConnections() {
     int iConnections = connections.size();
     JDCConnection[] aConnections = new JDCConnection[iConnections];

     for (int c=0; c<iConnections; c++)
       aConnections[c] = (JDCConnection) connections.get(c);

     return aConnections;
   } // getAllConnections

   // ---------------------------------------------------------

   /**
    * Get the DBbind object owner of this conenction pool
    * @return DBBind instance or <b>null</b> if this connection pool has no owner
    */
   public javax.sql.DataSource getDatabaseBinding()  {
     return binding;
   }

   // ---------------------------------------------------------

   /**
    * Get a connection from the pool
    * @param sCaller This is just an information parameter used for open/closed
    * mismatch tracking and other benchmarking and statistical purposes.
    * @return Opened JDCConnection
    * @throws SQLException If getMaxPoolSize() opened connections is reached an
    * SQLException with SQLState="08004" will be raised upon calling getConnection().<br>
    * <b>Microsoft SQL Server</b>: Connection reuse requires that SelectMethod=cursor was
    * specified at connection string.
    */

   public synchronized JDCConnection getConnection(String sCaller) throws SQLException {

       int i, s;
       JDCConnection j;
       Connection c;

       if (DebugFile.trace) {
         DebugFile.writeln("Begin JDCConnectionPool.getConnection(" + (sCaller!=null ? sCaller : "") + ")");
         DebugFile.incIdent();
       }

       if (hardlimit==0) {
         // If hardlimit==0 Then connection pool is turned off so return a connection
         // directly from the DriverManager
    	 if (user==null && password==null)
           c = DriverManager.getConnection(url);
    	 else
           c = DriverManager.getConnection(url, user, password);
         j = new JDCConnection(c,null);
       } else {

         j = null;

         s = connections.size();
         for (i = 0; i < s; i++) {
           j = (JDCConnection) connections.elementAt(i);
           if (j.lease(sCaller)) {
             if (DebugFile.trace) {
               DebugFile.writeln("  JDCConnectionPool hit for (" + url + ", ...) on pooled connection #" + String.valueOf(i));
               if (sCaller!=null) logConnection (j, sCaller, "ODBC", "hit");
             }
             break;
           }
           else
             j = null;
         } // endfor

         if (null==j) {
           if (openconns==hardlimit) {
             if (DebugFile.trace) DebugFile.decIdent();
             throw new SQLException ("Maximum number of " + String.valueOf(hardlimit) + " concurrent connections exceeded","08004");
           }

           if (DebugFile.trace) DebugFile.writeln("  DriverManager.getConnection(" + url + ", ...)");

           if (user==null && password==null)
             c = DriverManager.getConnection(url);
           else
             c = DriverManager.getConnection(url, user, password);

           if (null!=c) {
             j = new JDCConnection(c, this);
             j.lease(sCaller);

             if (DebugFile.trace) {
               DebugFile.writeln("  JDCConnectionPool miss for (" + url + ", ...)");
               if (sCaller!=null) logConnection (j, sCaller, "ODBC", "miss");
             }

             connections.addElement(j);
             c = null;
           }
           else {
             if (DebugFile.trace) DebugFile.writeln("JDCConnectionPool.getConnection() DriverManager.getConnection() returned null value");
             j = null;
           }

           if (null!=j) openconns++;
         } // endif (null==j)

         if (DebugFile.trace ) {
           if (sCaller!=null) modifyMap(sCaller, 1);
         } // DebugFile()
       } // fi (hardlimit==0)

       if (DebugFile.trace ) {
         DebugFile.decIdent();
         DebugFile.writeln("End JDCConnectionPool.getConnection()");
       } // DebugFile()

       return j;
  } // getConnection()

  // ---------------------------------------------------------

   /**
    * Get a connection from the pool
    * @return Opened PooledConnection
    * @throws SQLException If getMaxPoolSize() opened connections is reached an
    * SQLException with SQLState="08004" will be raised upon calling getConnection().<br>
    * <b>Microsoft SQL Server</b>: Connection reuse requires that SelectMethod=cursor was
    * specified at connection string.
    * @since 4.0
    */

  public synchronized PooledConnection getPooledConnection() throws SQLException {
	return (PooledConnection) getConnection(null);
  }

  // ---------------------------------------------------------

   /**
    * Get a connection bypassing the pool and connection directly to the database with the given user and password
    * @param sUser
    * @param sPasswd
    * @return Opened Connection
    * @throws SQLException
    * @since 4.0
    */

  public synchronized PooledConnection getPooledConnection(String sUser, String sPasswd) throws SQLException {
    if (sUser==null && sPasswd==null)
  	  return (PooledConnection) new JDCConnection(DriverManager.getConnection(url),null);
    else
	  return (PooledConnection) new JDCConnection(DriverManager.getConnection(url, sUser, sPasswd),null);
  }

  // ---------------------------------------------------------------------------

  /**
   * This method is added for compatibility with Java 7 and it is not implemented
   * @return null
   * @since 7.0
   */
  public Logger getParentLogger() {
    return null;
  }

  // ---------------------------------------------------------

  /**
   * Get conenction for a server process identifier
   * @param sPId String Operating system process identifier at server side
   * @return JDCConnection or <b>null</b> if no connection for such pid was found
   * @throws SQLException
   * @since 2.2
   */
  public JDCConnection getConnectionForPId(String sPId) throws SQLException {
    String pid;
    JDCConnection conn;
    Enumeration connlist = connections.elements();
    if (connlist != null) {
      while(connlist.hasMoreElements()) {
        conn = (JDCConnection) connlist.nextElement();
        try {
          pid = conn.pid();
        } catch (Exception ignore) { pid=null; }
        if (sPId.equals(pid))
          return conn;
      } // wend
    } // fi ()
    return null;
  } // getConnectionForPId

  // ---------------------------------------------------------

  /**
   * Return a connection to the pool
   * @param conn JDCConnection returned to the pool
   */

   public synchronized void returnConnection(JDCConnection conn) {
     if (DebugFile.trace) DebugFile.writeln("JDCConnectionPool.returnConnection([JDCConnection])");
     conn.expireLease();
   } // returnConnection()

  // ---------------------------------------------------------

  /**
   * Return a connection to the pool
   * @param conn JDCConnection returned to the pool
   * @param sCaller Must be the same String passed as parameter at getConnection()
   */

   public synchronized void returnConnection(JDCConnection conn, String sCaller) {

      if (DebugFile.trace) {
        DebugFile.writeln("JDCConnectionPool.returnConnection([JDCConnection], "+sCaller+")");
        if (sCaller!=null)
          logConnection (conn, sCaller, "CDBC", null);
      }

      if (DebugFile.trace) DebugFile.writeln("JDCConnection.expireLease()");

      conn.expireLease();

      if (DebugFile.trace && (null!=sCaller)) modifyMap(sCaller, -1);
   }

  // ---------------------------------------------------------

  /**
   * @return Actual connection pool size
   */

   public synchronized int size() {
     return openconns;
   }

   /**
    * Get information of current activity at database to which this pool is connected
    * @return JDCActivityInfo
    * @throws SQLException
    * @since 3.0
    */
   public JDCActivityInfo getActivityInfo() throws SQLException {
    JDCActivityInfo oInfo;
    try {
      oInfo = new JDCActivityInfo(this);
    } catch (Exception xcpt) {
      throw new SQLException ("JDCActivityInfo.getActivityInfo() "+xcpt.getClass().getName()+" "+xcpt.getMessage());
    }
    return oInfo;
  } // getActivityInfo()

  // ---------------------------------------------------------

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
	  long iNextVal;
	  JDCConnection oConn = null;
	  try {
		oConn = getConnection("nextVal."+sSequenceName);
	    Statement oStmt;
	    ResultSet oRSet;
	    CallableStatement oCall;

	    switch (oConn.getDataBaseProduct()) {

	      case JDCConnection.DBMS_MYSQL:
	      case JDCConnection.DBMS_MSSQL:
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
	        oRSet = oStmt.executeQuery("SELECT nextval('" + sSequenceName + "')");
	        oRSet.next();
	        iNextVal = oRSet.getInt(1);
	        oRSet.close();
	        oStmt.close();
	        break;

	      case JDCConnection.DBMS_ORACLE:
	        oStmt = oConn.createStatement();
	        oRSet = oStmt.executeQuery("SELECT " + sSequenceName + ".NEXTVAL FROM dual");
	        oRSet.next();
	        iNextVal = oRSet.getInt(1);
	        oRSet.close();
	        oStmt.close();
	        break;

	      default:
	        throw new UnsupportedOperationException("function nextVal() not supported on current DBMS");
	    }
	  } catch (Exception xcpt) {
		  throw new StorageException(xcpt.getClass().getName()+" "+xcpt.getMessage(), xcpt);
	  } finally {
		  try {
			  if (oConn!=null)
				  if (!oConn.isClosed())
					  oConn.close("nextVal."+sSequenceName);
		  } catch (SQLException sqle) { }
	  }
	  return iNextVal;
  }
   
  // ---------------------------------------------------------

  /**
   * Human readable usage statistics
   * @return Connection pool usage statistics string
   * @throws ConcurrentModificationException If pool is modified while iterating
   * throught connection collection
   */
   public String dumpStatistics()
     throws ConcurrentModificationException {
     String sDump;
     String sPId;
     Object sKey;
     Object iVal;
     int iConnOrdinal, iStaled;
     long stale = System.currentTimeMillis() - timeout;
     SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
     
     if (DebugFile.trace) {
       DebugFile.writeln("Begin JDCConnectionPool.dumpStatistics()");
       DebugFile.incIdent();
     }

     Enumeration connlist = connections.elements();
     JDCConnection conn;

     sDump = "Maximum Pool Size=" + String.valueOf(poolsize) + "\n";
     sDump += "Maximum Connections=" + String.valueOf(hardlimit) + "\n";
     sDump += "Connection Timeout=" + String.valueOf(timeout) + " ms\n";
     sDump += "Reaper Daemon Delay=" + String.valueOf(getReaperDaemonDelay()) + " ms\n";
     sDump += "\n";

     iStaled = iConnOrdinal = 0;

     if (connlist != null) {
       while (connlist.hasMoreElements()) {
         conn = (JDCConnection) connlist.nextElement();

         if (stale>conn.getLastUse()) iStaled++;

         try {
           sPId = conn.pid();
         } catch (Exception ignore) { sPId=null; }

         sDump += "#" + String.valueOf(++iConnOrdinal) + (conn.inUse() ? " in use, " : " vacant, ") + (stale>conn.getLastUse() ? " staled," : " ready,") + (conn.validate() ?  "validate=yes" : " validate=no") + ", last use=" + new Date(conn.getLastUse()).toString() + ", " + (conn.inUse() ? "caller=" + conn.getName() : "") + (sPId==null ? "" : " pid="+sPId) + "\n";
       }
     } // fi ()

     sDump += "\n";

     if (DebugFile.trace) {
       Iterator oCallersIterator = callers.keySet().iterator();

       while (oCallersIterator.hasNext()) {
         sKey = oCallersIterator.next();
         iVal = callers.get(sKey);
         if (!iVal.toString().equals("0")) sDump += sKey + " , " + iVal.toString() + " named open connections\n";
       }
       sDump += "\n\n";
     } // fi (DebugFile.trace)

     sDump += String.valueOf(iStaled) + " staled connections\n";

     sDump += "Actual pool size " + String.valueOf(size()) + "\n\n";

     try {
       JDCActivityInfo oAinf = getActivityInfo();
       if (oAinf==null) {
		 sDump += "no activity info available";
       } else {
         JDCProcessInfo[] oPinfo = oAinf.processesInfo();
         if (oPinfo!=null) {
           sDump += "Activity information:\n";
           for (int p=0; p<oPinfo.length; p++) {
             sDump += "user "+oPinfo[p].getUserName()+" running process "+oPinfo[p].getProcessId();
             conn = getConnectionForPId(oPinfo[p].getProcessId());
             if (conn!=null) {
               sDump += " on connection "+conn.getName();
             }
             if (oPinfo[p].getQueryText()!=null) {
               if (oPinfo[p].getQueryText().length()>0) {
           	     if (oPinfo[p].getQueryText().equals("<IDLE>"))
                   sDump += " for idle query";
                 else
                   sDump += " for query "+oPinfo[p].getQueryText();
               } // fi (getQueryText()!="")
             } // fi (getQueryText()!=null)
             if (oPinfo[p].getQueryStart()!=null) {
               sDump += " since "+oFmt.format(oPinfo[p].getQueryStart());
             }
             sDump += "\n";
           } // next
           JDCLockConflict[] oLocks = getActivityInfo().lockConflictsInfo();
           if (oLocks!=null) {
             sDump += "Locks information:\n";
             for (int l=0; l<oLocks.length; l++) {
               sDump += "PID "+String.valueOf(oLocks[l].getPID())+ " query "+oLocks[l].getQuery()+" is waiting on PID "+String.valueOf(oLocks[l].getWaitingOnPID())+" query "+oLocks[l].getWaitingOnQuery()+"\n";
             } // next           
           } // fi
         }
       }
     } catch (Exception xcpt) {
       sDump += xcpt.getClass().getName()+" trying to get activity information "+xcpt.getMessage()+"\n";
       try { sDump += StackTraceUtil.getStackTrace(xcpt); } catch (Exception ignore) { }
     }

     sDump += "\n";

     if (errorlog.size()>0) {
       sDump += "Fatal error log:\n";
       ListIterator oErrIterator = errorlog.listIterator();
       while (oErrIterator.hasNext()) sDump += oErrIterator.next()+"\n";
     } // fi

     DebugFile.writeln(sDump);

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End JDCConnectionPool.dumpStatistics()");
     }

     return sDump;
   } // dumpStatistics

    // ============================================================================
    // com.knowgate.storage.DataSource interface implementation

	public boolean isReadOnly() {
	  return false;
	}

	public Table openTable(Record oRec) throws StorageException {
	  try {
	    return getConnection(oRec.getTableName());
	  } catch (SQLException sqle) {
	  	throw new StorageException(sqle.getMessage(), sqle);
	  }
	}

	public Table openTable(String sName) throws StorageException {
	  try {
        return getConnection(sName);
	  } catch (SQLException sqle) {
	  	throw new StorageException(sqle.getMessage(), sqle);
	  }
	}

	public Table openTable(String sName, String[] sIndexes) throws StorageException {
	  try {
	    return getConnection(sName);
	  } catch (SQLException sqle) {
	  	throw new StorageException(sqle.getMessage(), sqle);
	  }
	}

    public SchemaMetaData getMetaData() {
      throw new UnsupportedOperationException("getMetaData() method not implemented for JDCConnectionPool");
    }

	public Map getDBTablesMap() throws IllegalStateException {
	  return ((com.knowgate.dataobjs.DBBind) binding).getDBTablesMap();
	}
	
    // ============================================================================

} // JDCConnectionPool
