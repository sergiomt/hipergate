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

package com.knowgate.scheduler;

import java.io.File;
import java.io.IOException;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Types;

import java.util.Date;
import java.util.Properties;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.ListIterator;

import java.io.FileInputStream;
import java.io.FileNotFoundException;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;

/**
 * <p>Scheduler daemon</p>
 * <p>Keeps a thread pool and an atom queue for feeding the pool.</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */

public class SchedulerDaemon extends Thread {

  private boolean bContinue;

  private String sProfile;

  // Worker threads pool
  private WorkerThreadPool oThreadPool;

  private DBBind oDbb;

  // This queue will be an in-memory list
  // of pending atoms (messages) to send
  private AtomQueue oQue = new AtomQueue();

  // Environment properties (typically readed from hipergate.cnf)
  private Properties oEnvProps;

  private LinkedList oCallbacks;

  private Date dtCreationDate;
  private Date dtStartDate;
  private Date dtStopDate;

  // ---------------------------------------------------------------------------

  private static class SystemOutNotify extends WorkerThreadCallback {

    public SystemOutNotify() {
      super("SystemOutNotify");
    }

    public void call (String sThreadId, int iOpCode, String sMessage, Exception oXcpt, Object oParam) {

      if (WorkerThreadCallback.WT_EXCEPTION==iOpCode)
        System.out.println("Thread " + sThreadId + ": ERROR " + sMessage);
      else
        System.out.println("Thread " + sThreadId + ": " + sMessage);
    }
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Create new SchedulerDaemon</p>
   * @param sPropertiesFilePath Full path to hipergate.cnf file.<br>
   * Constructor will read the following properties from hipergate.cnf:<br>
   * <b>driver</b> JDBC driver class<br>
   * <b>dburl</b> URL for database connection<br>
   * <b>dbuser</b> Database User<br>
   * <b>dbpassword</b> Database User Password<br>
   * @throws ClassNotFoundException
   * @throws FileNotFoundException
   * @throws IOException
   * @throws SQLException
   */
  public SchedulerDaemon (String sPropertiesFilePath)
    throws ClassNotFoundException, FileNotFoundException, IOException, SQLException {

    dtStartDate = dtStopDate = null;

    dtCreationDate = new Date();

    oThreadPool = null;

    oDbb = null;

    bContinue = true;

    if (DebugFile.trace) {
      DebugFile.writeln("new FileInputStream("+sPropertiesFilePath+")");
    }

    FileInputStream oInProps = new FileInputStream (sPropertiesFilePath);
    oEnvProps = new Properties();
    oEnvProps.load (oInProps);
    oInProps.close ();

    oCallbacks = new LinkedList();

    sProfile = sPropertiesFilePath.substring(sPropertiesFilePath.lastIndexOf(File.separator)+1,sPropertiesFilePath.lastIndexOf('.'));

  } // SchedulerDaemon

  // ---------------------------------------------------------------------------

  /**
   * Get date when this SchedulerDaemon was created
   * @return Date
   */
  public Date creationDate() {
    return dtCreationDate;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get date when this SchedulerDaemon was started for the last time
   * @return Date
   */
  public Date startDate() {
    return dtStartDate;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get date when this SchedulerDaemon was stopped for the last time
   * @return Date
   */
  public Date stopDate() {
    return dtStopDate;
  }

  // ---------------------------------------------------------------------------

  public AtomQueue atomQueue() {
    return oQue;
  }

  // ---------------------------------------------------------------------------

  public WorkerThreadPool threadPool() {
    return oThreadPool;
  }

  // ---------------------------------------------------------------------------

  public DBBind databaseBind() {
    return oDbb;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Create AtomQueue and start WorkerThreadPool</p>
   */

  public void run() {
    Statement oStmt;
    ResultSet oRSet;
    int iJobCount;
    int nThreads;
    String sSQL;
    AtomConsumer oCsr = null;
    JDCConnection oJcn = null;
    
    if (DebugFile.trace) DebugFile.writeln("Begin SchedulerDaemon.run()");

	try  {
	  nThreads = Integer.parseInt(oEnvProps.getProperty("maxschedulerthreads","1"));
	} catch (Exception xcpt) { nThreads = 1; }
	
    try {

    if (null==oDbb) oDbb = new DBBind(sProfile);

    oJcn = oDbb.getConnection("SchedulerDaemon",true);
	Event.trigger(oJcn, 1024, "startschedulerdaemon", new HashMap(), oEnvProps);
	oJcn.close("SchedulerDaemon");
	
	oDbb.connectionPool().setPoolSize(4*nThreads);
	// No more that ten times the number of threads allowed for connections
	oDbb.connectionPool().setMaxPoolSize(10*nThreads);

    // Create Atom queue.
    if (DebugFile.trace) DebugFile.writeln("new AtomQueue()");

    oQue = new AtomQueue();

    // This object feeds the queue with new atoms
    // extracted from the database.
    if (DebugFile.trace) DebugFile.writeln("new AtomFeeder()");

    AtomFeeder oFdr = new AtomFeeder();

    // This is the queue consumer object
    // it grants that only one atom is
    // popped from the queue at a time.
    if (DebugFile.trace) DebugFile.writeln("new AtomConsumer([JDCconnection], [AtomQueue])");

    oCsr = new AtomConsumer(oDbb, oQue);

    // Create WorkerThreadPool

    if (DebugFile.trace) DebugFile.writeln("new WorkerThreadPool([AtomConsumer], [Properties])");

    oThreadPool = new WorkerThreadPool(oCsr, oEnvProps);

    // Register callbacks on each worker thread

    ListIterator oIter = oCallbacks.listIterator();
    while (oIter.hasNext())
      oThreadPool.registerCallback((WorkerThreadCallback) oIter.next());

    dtStartDate = new Date();

    do {
      try {

        while (bContinue) {

          oJcn = oDbb.getConnection("SchedulerDaemon");
          oJcn.setAutoCommit(true);
          
          // Count how many atoms are pending of processing at the database
          oStmt = oJcn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

          // ***************************************************
          // Finish all the jobs that have no more pending atoms
          sSQL = "SELECT j.gu_job FROM k_jobs j WHERE ("+
                 "j.id_status="+String.valueOf(Job.STATUS_PENDING)+" OR "+
                 "j.id_status="+String.valueOf(Job.STATUS_RUNNING)+") AND "+
                 "NOT EXISTS (SELECT a.pg_atom FROM k_job_atoms a WHERE "+
                 "j.gu_job=a.gu_job AND a.id_status IN ("+
                 String.valueOf(Atom.STATUS_PENDING)+","+
                 String.valueOf(Atom.STATUS_RUNNING)+","+
                 String.valueOf(Atom.STATUS_SUSPENDED)+"))";

          if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery("+sSQL+") on connection with process id. "+oJcn.pid());

          oRSet = oStmt.executeQuery(sSQL);
          LinkedList<String> oFinished = new LinkedList<String>();
          while (oRSet.next()) {
            oFinished.add(oRSet.getString(1));
          } // wend
          oRSet.close();
		  oStmt.close();

          if (DebugFile.trace) DebugFile.writeln("Already finished jobs "+String.valueOf(oFinished.size()));

          if (oFinished.size()>0) {
            sSQL = "UPDATE k_jobs SET id_status="+String.valueOf(Job.STATUS_FINISHED)+",dt_finished="+DBBind.Functions.GETDATE+" WHERE gu_job=?";
            if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+") on connection with process id. "+oJcn.pid());
            PreparedStatement oUpdt = oJcn.prepareStatement(sSQL);
            oIter = oFinished.listIterator();
            while (oIter.hasNext()) {
              oUpdt.setObject(1, oIter.next(), java.sql.Types.CHAR);
              oUpdt.executeUpdate();
            } // wend
            oUpdt.close();
          } // fi

          // ****************************************************
          // Count jobs running or pending of beginning execution

          if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT COUNT(*) FROM k_jobs WHERE id_status=" + String.valueOf(Job.STATUS_PENDING) + " AND ("+DB.dt_execution+" IS NULL OR "+DB.dt_execution+"<="+DBBind.Functions.GETDATE+")) on connection with process id. "+oJcn.pid());

		  iJobCount = DBCommand.queryCount(oJcn, "*", DB.k_jobs, DB.id_status + "=" + String.valueOf(Job.STATUS_RUNNING) + " OR (" + DB.id_status + "=" + String.valueOf(Job.STATUS_PENDING)+" AND ("+DB.dt_execution+" IS NULL OR "+DB.dt_execution+"<="+DBBind.Functions.GETDATE+"))");

		  oJcn.close("SchedulerDaemon");

          if (DebugFile.trace) DebugFile.writeln(String.valueOf(iJobCount) + " pending jobs");

          if (0==iJobCount) {
            if (DebugFile.trace) DebugFile.writeln("sleep (10000)");
            sleep (10000);
          }
          else {
            break;
          }
        } // wend

        if (bContinue) {

		  try {

			oJcn = oDbb.getConnection("SchedulerDaemon.AtomFeeder");
            oJcn.setAutoCommit(true);
            oFdr.loadAtoms(oJcn, oThreadPool.size());
            oJcn.close("SchedulerDaemon.AtomFeeder");

            oJcn = oDbb.getConnection("SchedulerDaemon.AtomFeeder");
            oJcn.setAutoCommit(true);            
            oFdr.feedQueue(oJcn, oQue);
		    oJcn.close("SchedulerDaemon.AtomFeeder");

		    oJcn=null;
		  } finally {
		  	try { if (null!=oJcn) oJcn.close("SchedulerDaemon.AtomFeeder"); } catch (Exception ignore) { }
		  }

		  if (DebugFile.trace) {
		    DebugFile.writeln("Queue has "+String.valueOf(oQue.size())+" atoms");
		  }

          if (oQue.size()>0) {
            oThreadPool.launchAll();
          }

          do {

            if (DebugFile.trace) DebugFile.writeln("sleep (10000)");

            sleep(10000);

            if (DebugFile.trace) DebugFile.writeln(String.valueOf(oThreadPool.livethreads()) + " live threads");

          } while(oThreadPool.livethreads()==oThreadPool.size());
        } // fi (bContinue)
      }
      catch (InterruptedException e) {
        if (DebugFile.trace)
          DebugFile.writeln("SchedulerDaemon InterruptedException " + e.getMessage());
      }
    } while (bContinue) ;

    if (DebugFile.trace) DebugFile.writeln(" exiting SchedulerDaemon");

    oThreadPool.haltAll();
    oThreadPool = null;

	oCsr.close();
    oCsr = null;

    oFdr = null;
    oQue = null;

    if (DebugFile.trace) DebugFile.writeln("JDConnection.close()");

	if (oJcn!=null) { if (!oJcn.isClosed()) { oJcn.close("SchedulerDaemon"); } oJcn = null; }

    oJcn = oDbb.getConnection("SchedulerDaemon",true);
	Event.trigger(oJcn, 1024, "stopschedulerdaemon", new HashMap(), oEnvProps);
	oJcn.close("SchedulerDaemon");

    oDbb.close();
    oDbb=null;
    }
    catch (Exception e) {
      
      if (DebugFile.trace) {
        DebugFile.writeln("SchedulerDaemon " + e.getClass().getName() + " " + e.getMessage());
        try {
          DebugFile.writeln(StackTraceUtil.getStackTrace(e));
        } catch (IOException ignore) {}
        
        DebugFile.writeln("SchedulerDaemon.run() abnormal termination");
      }
      
      try {
        System.err.println("Hipergate SchedulerDaemon fatal error " + e.getClass().getName() + " " + e.getMessage());
        System.err.println(StackTraceUtil.getStackTrace(e));
      } catch (IOException ignore) {}

      try { oThreadPool.haltAll(); oThreadPool=null; } catch (Exception ignore) {}
      try {
        if (oJcn!=null) if (!oJcn.isClosed()) oJcn.close("SchedulerDaemon");
      } catch (SQLException sqle) {
        if (DebugFile.trace) DebugFile.writeln("SchedulerDaemon SQLException on close() " + sqle.getMessage());
      }
      if (null!=oDbb) { try { oDbb.close(); } catch (Exception ignore) {} }
      oJcn = null;

      dtStartDate = null;
      dtStopDate = new Date();

    } // catch
    if (DebugFile.trace) DebugFile.writeln("End SchedulerDaemon.run()");
  } // run

  // ---------------------------------------------------------------------------

  public void registerCallback(WorkerThreadCallback oNewCallback)
    throws IllegalArgumentException {

    if (oThreadPool==null)
      oCallbacks.addLast(oNewCallback);
    else
      oThreadPool.registerCallback(oNewCallback);
  }

  // ---------------------------------------------------------------------------

  public void unregisterCallback(String sCallbackName) {
    if (oThreadPool!=null)
      oThreadPool.unregisterCallback(sCallbackName);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Abort a given Job</p>
   * @param sGuJob GUID of Job to be aborted
   * @throws SQLException, ClassNotFoundException
   * @since 5.0
   */
  public void abortJob(String sGuJob)
  	throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, FileNotFoundException {
    DBBind oDb2;

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin SchedulerDaemon.abortJob("+sGuJob+")");
	  DebugFile.incIdent();
	}
	
    if (null==oDbb)
      oDb2 = new DBBind(sProfile);
    else
      oDb2 = oDbb;
      
    JDCConnection oCon = oDb2.getConnection("SchedulerDaemon.abortJob");
	oCon.setAutoCommit(true);

	atomQueue().remove(sGuJob);

	Job.instantiate(oCon, sGuJob, oEnvProps).abort(oCon);

	oCon.close("SchedulerDaemon.abortJob");

	if (oDb2!=oDbb) oDb2.close();

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End SchedulerDaemon.abortJob()");
	}
  } // abortJob

  // ---------------------------------------------------------------------------

  private static void interruptJobs(JDCConnection oCon, Object[] aJobs) throws SQLException {
    int nJobs;
    if (null==aJobs) nJobs=0; else nJobs = aJobs.length;
    if (nJobs>0) {
      PreparedStatement oStmt = oCon.prepareStatement("UPDATE " + DB.k_jobs + " SET " + DB.id_status + "=" + String.valueOf(Job.STATUS_INTERRUPTED) + " WHERE " + DB.gu_job + "=?");
      for (int j=0; j<nJobs; j++) {
        if (null!=aJobs[j]) {
          oStmt.setObject(1, aJobs[j], Types.CHAR);
          oStmt.executeUpdate();
        }
      }
      oStmt.close();
    }
  }
  
  // ---------------------------------------------------------------------------

  private static void suspendJobs(JDCConnection oCon, Object[] aJobs) throws SQLException {
    if (DebugFile.trace) {
	  DebugFile.writeln("Begin SchedulerDaemon.suspendJobs([JDCConnection], Object[])");
	  DebugFile.incIdent();
	}
    int nJobs;

    if (null==aJobs) nJobs=0; else nJobs = aJobs.length;
    if (nJobs>0) {
      PreparedStatement oStmt = oCon.prepareStatement("UPDATE " + DB.k_jobs + " SET " + DB.id_status + "=" + String.valueOf(Job.STATUS_SUSPENDED) + " WHERE " + DB.gu_job + "=?");
      for (int j=0; j<nJobs; j++) {
        if (null!=aJobs[j]) {
          oStmt.setObject(1, aJobs[j], Types.CHAR);
          oStmt.executeUpdate();
        } // fi
      } // next
      oStmt.close();
    } // fi
	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End SchedulerDaemon.suspendJobs()");
	}
  } // suspendJobs

  // ---------------------------------------------------------------------------

  /**
   * <p>Halt worker threads and set running jobs status to suspended</p>
   * Wait until all running atoms are finished and then stop all worker threads
   * @throws IllegalStateException If worker threads are not running
   */
  public void haltAll() throws IllegalStateException {
    if (null==oThreadPool)
      throw new IllegalStateException("SchedulerDaemon.haltAll() Thread pool not initialized, call start() method before trying to halt worker threads");

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin SchedulerDaemon.haltAll()");
	  DebugFile.incIdent();
	}
	
    String[] aInitRunningJobs = oThreadPool.runningJobs();
    oThreadPool.haltAll();
    String[] aStillRunningJobs = oThreadPool.runningJobs();

    if (null!=oDbb) {
      try {
        JDCConnection oCon = oDbb.getConnection("SchedulerDaemonHaltAll");
        oCon.setAutoCommit(true);
        if (null!=aInitRunningJobs) {
          if (null!=aStillRunningJobs) {
            int nInitRunningJobs = aInitRunningJobs.length;
            int nStillRunningJobs= aStillRunningJobs.length;
            for (int i=0; i<nInitRunningJobs; i++) {
              boolean bStillRunning = false;
              for (int j=0; j<nStillRunningJobs && !bStillRunning; j++) {
                bStillRunning = aStillRunningJobs[j].equals(aInitRunningJobs[i]);
              } // next
              if (bStillRunning) aInitRunningJobs[i]=null;
            } // next
          } // fi
          suspendJobs(oCon, aInitRunningJobs);
        } // fi
        oCon.close("SchedulerDaemonHaltAll");
      } catch (SQLException sqle) {
        throw new IllegalStateException("SchedulerDaemon.haltAll() SQLException "+sqle.getMessage());
      }
      oDbb.close();
      oDbb=null;
    } // fi

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End SchedulerDaemon.haltAll()");
	}    
  } // haltAll()
  // ---------------------------------------------------------------------------

  /**
   * <p>Stop worker threads and set running jobs status to interrupted</p>
   * Call haltAll() Wait until the specified amount of miliseconds
   * and force all worker threads still alive to stop.
   * This method must only be used when stalled worker threads cannot be stopped
   * by calling haltAll().
   * @param lDelayMilis long Delay (in miliseconds) to wait before executing
   * threads are forced to stop
   * @throws IllegalStateException If worker threads are not running
   */
  public synchronized void stopAll(long lDelayMilis)
    throws IllegalStateException,SQLException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin SchedulerDaemon.stopAll("+String.valueOf(lDelayMilis)+")");
	  DebugFile.incIdent();
	}    

    if (null==oThreadPool)
      throw new IllegalStateException("SchedulerDaemon.stopAll() Thread pool not initialized, call start() method before trying to stop worker threads");

    bContinue = false;

	// After signaling bContinue = false run() method will exit its internal loop,
	// call oThreadPool.haltAll() and clean-up atom consumer

    try { sleep(lDelayMilis); } catch (InterruptedException ignore) { }

    if (null!=oDbb) {
      JDCConnection oCon = oDbb.getConnection("SchedulerDaemonStopAll");
      oCon.setAutoCommit(true);
      oThreadPool.stopAll(oCon);
      interruptJobs(oCon, oThreadPool.runningJobs());
      oCon.close("SchedulerDaemonStopAll");
      oDbb.close();
      oDbb=null;
    } else {
      oThreadPool.stopAll();
    }

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End SchedulerDaemon.stopAll()");
	}    
  } // stopAll

  // ---------------------------------------------------------------------------

  /**
   * <p>Stop worker threads and set running jobs status to interrupted</p>
   * Default delay for forcing threads to stop is 10 seconds
   * @throws IllegalStateException If worker threads are not running
   */
  public void stopAll() throws IllegalStateException,SQLException {
    stopAll(10000l);
  }

  // ---------------------------------------------------------------------------

  private static void printUsage() {
    System.out.println("");
    System.out.println("Usage:");
    System.out.println("SchedulerDaemon cnf_file_path [verbose]");
  }

  public static void main(String[] argv)
    throws ClassNotFoundException, SQLException, IOException {

    SchedulerDaemon TheDaemon;

    if (argv.length<1 || argv.length>2)
      printUsage();

    else if (argv.length==2 && !argv[1].equals("verbose"))
      printUsage();

    else {

      DBBind oGlobalDBBind = new DBBind();
    	
      TheDaemon = new SchedulerDaemon(argv[0]);

      if (argv.length==2)
        TheDaemon.registerCallback(new SystemOutNotify());

      TheDaemon.start();
      
      oGlobalDBBind.close();
    }
  }
} // SchedulerDaemon
