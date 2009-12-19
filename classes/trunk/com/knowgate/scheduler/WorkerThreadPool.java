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

import java.sql.SQLException;

import java.util.Properties;
import java.util.LinkedList;
import java.util.ListIterator;

import com.knowgate.dataobjs.DB;
import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;

/**
 * WorkerThread Pool
 * @author Sergio Montoro Ten
 * @version 5.5
 */

public class WorkerThreadPool {

  private WorkerThread aThreads[];
  private long aStartTime[];
  private Properties oEnvProps;

  // ---------------------------------------------------------------------------

  /**
   * <p>Create WorkerThreadPool</p>
   * thread Pool size is readed from maxschedulerthreads property of oEnvironmentProps,
   * the default value is 1.
   * Each thread is given the name WorkerThread_<i>n</i>
   * @param oAtomConsumer Atom Consumer Object to be used
   * @param oEnvironmentProps Environment Properties collection
   * (usually readed from hipergate.cnf)
   */
  public WorkerThreadPool(AtomConsumer oAtomConsumer, Properties oEnvironmentProps) {
    int nThreads = Integer.parseInt(oEnvironmentProps.getProperty("maxschedulerthreads", "1"));

    if (DebugFile.trace) DebugFile.writeln("maxschedulerthreads=" + String.valueOf(nThreads));

    oEnvProps = oEnvironmentProps;
    aThreads = new WorkerThread[nThreads];
    aStartTime = new long[nThreads];

    for (int t=0; t<nThreads; t++) {
      if (DebugFile.trace) DebugFile.writeln("new WorkerThread(" + String.valueOf(t) + ")");

      aThreads[t] = new WorkerThread(this, oAtomConsumer);

      aThreads[t].setName("WorkerThread_" + String.valueOf(t));
    } // next(t)
  }

  // ---------------------------------------------------------------------------

  /**
   * Get Pool Size
   */
  public int size() {
    return aThreads.length;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get Environment properties collection from hipergate.cnf
   */
  public Properties getProperties() {
    return oEnvProps;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get Environment property
   * @return
   */
  public String getProperty(String sKey) {
    return oEnvProps.getProperty(sKey);
  }

  // ---------------------------------------------------------------------------

  public long getRunningTimeMS() {
    long lRunningTime = 0l;
    for (int t=0; t<aThreads.length; t++)
      lRunningTime += aThreads[t].getRunningTimeMS();
    return lRunningTime;
  }

  // ---------------------------------------------------------------------------

  /**
   * Launch all WorkerThreads and start consuming atoms from queue.
   */
  public void launchAll() throws IllegalThreadStateException {
  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin WorkerThreadPool.launchAll()");
  	  DebugFile.incIdent();
  	}
  	
    for (int t=0; t<aThreads.length; t++) {
      if (!aThreads[t].isAlive()) {
  	    if (DebugFile.trace) {
  	      DebugFile.writeln("Re-starting thread "+String.valueOf(t));
  	    }
        aStartTime[t] = new java.util.Date().getTime();
        aThreads[t] = new WorkerThread(this, aThreads[t].getConsumer());
        aThreads[t].start();
      } else {
  	    if (DebugFile.trace) {
  	      DebugFile.writeln("Thread "+String.valueOf(t)+" is alive");
  	    }      	
      }
    } // next

  	if (DebugFile.trace) {
  	  DebugFile.writeln("End WorkerThreadPool.launchAll()");
  	  DebugFile.decIdent();
  	}

  } // launchAll

  // ---------------------------------------------------------------------------

  /**
   * Count of currently active WorkerThreads
   */
  public int livethreads() {
    int iLive = 0;

    for (int t=0; t<aThreads.length; t++) {
      if (aThreads[t].isAlive()) {
        iLive++;
      }
    } // next
    return iLive;
  } // livethreads

  // ---------------------------------------------------------------------------

  public WorkerThread[] threads() {
    return aThreads;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get array of atoms currently running at live WorkerThreads
   * @return Atom[]
   * @since 3.0
   */
  public Atom[] runningAtoms() {
    if (livethreads()==0) return null;
    Atom[] aAtoms = new Atom[livethreads()];
    int a = 0;
    final int iThreads = aThreads.length;
    for (int t=0; t<iThreads; t++) {
      if (aThreads[t].isAlive()) {
        aAtoms[a++]=aThreads[t].activeAtom();
      } // fi
    } // next (t)
    return aAtoms;
  } // runningAtoms

  // ---------------------------------------------------------------------------

  /**
   * Get array with GUIDs of Jobs currently run by live WorkerThreads
   * @return String[] Job GUID array
   * @since 3.0
   */
  public String[] runningJobs() {
    Atom[] aAtoms = runningAtoms();
    if (aAtoms==null) return null;
    LinkedList oJobs = new LinkedList();
    String sJob;
    int nAtoms = aAtoms.length;
    for (int a=0; a<nAtoms; a++) {
      sJob = aAtoms[a].getString(DB.gu_job);
      if (oJobs.contains(sJob)) oJobs.add(sJob);
    }
    if (oJobs.size()==0) return null;
    String[] aJobs = new String[oJobs.size()];
    ListIterator oIter = oJobs.listIterator();
    int j = 0;
    while (oIter.hasNext()) {
      aJobs[j] = (String) oIter.next();
    } // wend
    return aJobs;
  } // runningJobs

  // ---------------------------------------------------------------------------

  /**
   * Register a thread callback object for each thread in this pool
   * @param oNewCallback WorkerThreadCallback subclass instance
   * @throws IllegalArgumentException If a callback with same name has oNewCallback was already registered
   */
  public void registerCallback(WorkerThreadCallback oNewCallback)
    throws IllegalArgumentException {
    final int iThreads = aThreads.length;
    for (int t=0; t<iThreads; t++)
      aThreads[t].registerCallback(oNewCallback);
  } // registerCallback

  // ---------------------------------------------------------------------------

  /**
    * Unregister a thread callback object for each thread in this pool
    * @param sCallbackName Name of callback to be unregistered
    */
   public void unregisterCallback(String sCallbackName) {
     final int iThreads = aThreads.length;

     for (int t=0; t<iThreads; t++)
       aThreads[t].unregisterCallback(sCallbackName);

   } // unregisterCallback

   // --------------------------------------------------------------------------

   /**
    * <p>Halt all pooled threads commiting any pending operations before stoping</p>
    * If a thread is dead-locked by any reason halting it will not cause any effect.<br>
    * halt() method only sends a signals to the each WokerThread telling it that must
    * finish pending operations and stop.
    */
   public void haltAll() {
	 if (DebugFile.trace) {
	   DebugFile.writeln("Begin WorkerThreadPool.haltAll()");
	   DebugFile.incIdent();
	 }

     final int iThreads = aThreads.length;

	 if (DebugFile.trace) {
	   DebugFile.writeln(String.valueOf(iThreads)+" running threads");
	 }

     for (int t=0; t<iThreads; t++) {
       aThreads[t].halt();
     }

	 if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End WorkerThreadPool.haltAll()");
	 }
   } // haltAll

   // --------------------------------------------------------------------------

   /**
    * <p>Call stop() on every thread of the pool which is alive</p>
    * This method should only be used when threads cannot be stopped by calling
    * haltAll()
    * @deprecated Use stopAll(JDCConnection) instead
    */
   public void stopAll() {
	 if (DebugFile.trace) {
	   DebugFile.writeln("Begin WorkerThreadPool.stopAll()");
	   DebugFile.incIdent();
	 }

     final int iThreads = aThreads.length;

	 if (DebugFile.trace) {
	   DebugFile.writeln(String.valueOf(iThreads)+" running threads");
	 }

     for (int t=0; t<iThreads; t++) {
       if (aThreads[t].isAlive()) aThreads[t].stop();
     }

	 if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End WorkerThreadPool.stopAll()");
	 }
   } // stopAll

   // ---------------------------------------------------------------------------

   /**
    * <p>Call stop() on every thread of the pool which is alive</p>
    * All running atoms are set to STATUS_INTERRUPTED
    * @since 3.0
    */
   public void stopAll(JDCConnection oConn) throws SQLException {
	 if (DebugFile.trace) {
	   DebugFile.writeln("Begin WorkerThreadPool.stopAll([JDCConnection])");
	   DebugFile.incIdent();
	 }

     final int iThreads = aThreads.length;

	 if (DebugFile.trace) {
	   DebugFile.writeln(String.valueOf(iThreads)+" running threads");
	 }

     Atom oActiveAtom;

     for (int t=0; t<iThreads; t++) {
       oActiveAtom = aThreads[t].activeAtom();
       if (null!=oActiveAtom)
         oActiveAtom.setStatus(oConn, Atom.STATUS_INTERRUPTED, "Interrupted by user");
       if (aThreads[t].isAlive()) aThreads[t].stop();
     } // next

	 if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End WorkerThreadPool.stopAll()");
	 }
   } // stopAll

   // ---------------------------------------------------------------------------

} // WorkerThreadPool
