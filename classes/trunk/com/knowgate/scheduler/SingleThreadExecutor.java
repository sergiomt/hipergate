package com.knowgate.scheduler;

import java.sql.SQLException ;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.FileNotFoundException;

import java.util.Properties;
import java.util.LinkedList;
import java.util.ListIterator;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

import com.knowgate.misc.Gadgets;

/**
 * <p>Single Thread Scheduler Executor</p>
 * <p>SingleThreadExecutor is a class that processes jobs and atoms in a simple way,
 * unlike SchedulerDaemon witch is based on an AtomQueue and a WorkerThreadPool,
 * SingleThreadExecutor uses directly the database for tracking execution progress
 * for a single thread.</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class SingleThreadExecutor extends Thread {

  private DBBind oGlobalDbb;
  
  private String sEnvProps;

  private Properties oEnvProps;

  private boolean bContinue;

  private String sLastError;

  private String sJob;

  private Job  oJob;

  private Atom oAtm;

  private LinkedList oCallbacks;

  private int iCallbacks;

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
   * <p>Create new SingleThreadExecutor</p>
   * @param sPropertiesFilePath Absolute path to hipergate.cnf properties file
   * @throws FileNotFoundException
   * @throws IOException
   */
  public SingleThreadExecutor (String sPropertiesFilePath)
    throws FileNotFoundException, IOException {

    if (DebugFile.trace) DebugFile.writeln("new SingleThreadExecutor("+sPropertiesFilePath+")");

	oGlobalDbb = null;
	
    sJob = null;

    bContinue = true;

    if (sPropertiesFilePath.lastIndexOf(System.getProperty("file.separator"))==-1)
      sEnvProps = sPropertiesFilePath;
    else
      sEnvProps = sPropertiesFilePath.substring(sPropertiesFilePath.lastIndexOf(System.getProperty("file.separator"))+1);

    FileInputStream oInProps = new FileInputStream (sPropertiesFilePath);
    oEnvProps = new Properties();
    oEnvProps.load (oInProps);
    oInProps.close ();

    oCallbacks = new LinkedList();
  }

  /**
   * <p>Create new SingleThreadExecutor for a single Job</p>
   * @param sPropertiesFilePath Absolute path to hipergate.cnf properties file
   * @param sJobId GUID of Job for which to process atoms,
   * if <b>null</b> the executor will process atoms for all pending jobs
   * @throws FileNotFoundException
   * @throws IOException
   */
  public SingleThreadExecutor (String sPropertiesFilePath, String sJobId)
    throws FileNotFoundException, IOException {

    if (DebugFile.trace) DebugFile.writeln("new SingleThreadExecutor("+sPropertiesFilePath+","+sJobId+")");

	oGlobalDbb = null;

    sJob = sJobId;

    bContinue = true;

    if (sPropertiesFilePath.lastIndexOf(System.getProperty("file.separator"))==-1)
      sEnvProps = sPropertiesFilePath;
    else
      sEnvProps = sPropertiesFilePath.substring(sPropertiesFilePath.lastIndexOf(System.getProperty("file.separator"))+1);

    FileInputStream oInProps = new FileInputStream (sPropertiesFilePath);
    oEnvProps = new Properties();
    oEnvProps.load (oInProps);
    oInProps.close ();

    oCallbacks = new LinkedList();
  } // SingleThreadExecutor

  // ---------------------------------------------------------------------------

  /**
   * <p>Create new SingleThreadExecutor for a single Job</p>
   * @param oProps Environment properties (usually taken from hipergate.cnf)
   * @param sJobId GUID of Job for which to process atoms,
   * if <b>null</b> the executor will process atoms for all pending jobs
   */
  public SingleThreadExecutor (Properties oProps, String sJobId) {

    if (DebugFile.trace) DebugFile.writeln("new SingleThreadExecutor([Properties],"+sJobId+")");

	oGlobalDbb = null;

    sJob = sJobId;

    bContinue = true;

    oEnvProps = oProps;
    
    oGlobalDbb = new DBBind(oProps);

	sEnvProps = oGlobalDbb.getProfileName();

    oCallbacks = new LinkedList();
  } // SingleThreadExecutor

  // ---------------------------------------------------------------------------

  /**
   * <p>Create new SingleThreadExecutor for a single Job</p>
   * @param oDbb DBBind used for accesing the satabase
   * @param sJobId GUID of Job for which to process atoms,
   * if <b>null</b> the executor will process atoms for all pending jobs
   */
  public SingleThreadExecutor (DBBind oDbb, String sJobId) {

	oGlobalDbb = oDbb;

    sJob = sJobId;

    bContinue = true;

	sEnvProps = oDbb.getProfileName();

    oEnvProps = oDbb.getProperties();

    oCallbacks = new LinkedList();
  } // SingleThreadExecutor

  // ---------------------------------------------------------------------------

  public Atom activeAtom() {
    return oAtm;
  }

  // ---------------------------------------------------------------------------

  public Job activeJob() {
    return oJob;
  }

  // ---------------------------------------------------------------------------

  public String lastError() {
    return sLastError;
  }

  // ---------------------------------------------------------------------------

  /**
   * Register a thread callback object
   * @param oNewCallback WorkerThreadCallback subclass instance
   * @throws IllegalArgumentException If a callback with same name has oNewCallback was already registered
   */
  public void registerCallback(WorkerThreadCallback oNewCallback)
    throws IllegalArgumentException {

    WorkerThreadCallback oCallback;
    ListIterator oIter = oCallbacks.listIterator();

    while (oIter.hasNext()) {
      oCallback = (WorkerThreadCallback) oIter.next();

      if (oCallback.name().equals(oNewCallback.name())) {
        throw new IllegalArgumentException("Callback " + oNewCallback.name() + " is already registered");
      } // fi
    } // wend

    oCallbacks.addLast(oNewCallback);
    iCallbacks++;
  } // registerCallback

  // ---------------------------------------------------------------------------

  /**
   * Unregister a thread callback object
   * @param sCallbackName Name of callback to be unregistered
   * @return <b>true</b> if a callback with such name was found and unregistered,
   * <b>false</b> otherwise
   */
  public boolean unregisterCallback(String sCallbackName) {
    WorkerThreadCallback oCallback;
    ListIterator oIter = oCallbacks.listIterator();

    while (oIter.hasNext()) {
      oCallback = (WorkerThreadCallback) oIter.next();

      if (oCallback.name().equals(sCallbackName)) {
        oIter.remove();
        iCallbacks--;
        return true;
      } // fi
    } // wend

    return false;
  } // unregisterCallback

  // ---------------------------------------------------------------------------

  private void callBack (int iOpCode, String sMessage, Exception oXcpt, Object oParam) {

    WorkerThreadCallback oCallback;
    ListIterator oIter = oCallbacks.listIterator();

    while (oIter.hasNext()) {
      oCallback = (WorkerThreadCallback) oIter.next();
      oCallback.call(getName(), iOpCode, sMessage, oXcpt, oParam);
    } // wend

  } // callBack

  // ---------------------------------------------------------------------------

  public void run() {
    Statement oStm;
    AtomFeeder oFdr;
    DBSubset oDBS;
    String sSQL;
    String sJId;
    ResultSet oRst;
    ResultSetMetaData oMDt;

    DBBind oDBB = null;
    JDCConnection oCon = null;

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin SingleThreadExecutor.run("+String.valueOf(currentThread().getId())+")");
	  DebugFile.writeln("environment is "+sEnvProps);
	}

    try {
      if (oGlobalDbb==null) {
        // Disable connection reaper to avoid connections being closed in the middle of job execution
        oDBB = new DBBind(sEnvProps);
        oDBB.connectionPool().setReaperDaemonDelay(0l);
      }
      else {
      	oDBB = oGlobalDbb;
      }

      oCon = oDBB.getConnection("SingleThreadExecutor_"+String.valueOf(currentThread().getId()));
	  oCon.setAutoCommit(true);

      bContinue = true;

      sLastError = "";

      oFdr = new AtomFeeder();

      while (bContinue) {

        if (oCon.isClosed()) {
          oCon = oDBB.getConnection("SingleThreadExecutor_"+String.valueOf(currentThread().getId()));
          oCon.setAutoCommit(true);
        }

        if (sJob==null)
          oDBS = oFdr.loadAtoms(oCon,1);
        else
          oDBS = oFdr.loadAtoms(oCon, sJob);

        if (oDBS.getRowCount()>0) {

          sJId = oDBS.getString(0,0);

          oJob = Job.instantiate(oCon, sJId, oEnvProps);

          oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

          sSQL = "SELECT a.*, j." + DB.tx_parameters + " FROM " + DB.k_job_atoms + " a, " + DB.k_jobs + " j WHERE a." + DB.id_status + "=" + String.valueOf(Atom.STATUS_PENDING) + " AND j." + DB.gu_job + "=a." + DB.gu_job + " AND j." + DB.gu_job + "='" + sJId + "'";

	      if (DebugFile.trace) {
	        DebugFile.writeln("Statement.executeQuery("+sSQL+")");
	      }

          oRst = oStm.executeQuery(sSQL);
          oMDt = oRst.getMetaData();

          while (oRst.next()) {

            oAtm = new Atom(oRst, oMDt);

		    try {
              oJob.process(oAtm);
              oAtm.archive(oCon);          	
              if (DebugFile.trace)
                DebugFile.writeln("Thread " + String.valueOf(currentThread().getId()) + " consumed Atom " + String.valueOf(oAtm.getInt(DB.pg_atom)));
      		  if (iCallbacks>0) callBack(WorkerThreadCallback.WT_ATOM_CONSUME, oJob.getString(DB.gu_job), null, oAtm.getString(DB.tx_email));
		    }
            catch (Exception e) {
              if (DebugFile.trace) {
                DebugFile.writeln(getName() + " " + e.getClass().getName() + " job " + oJob.getString(DB.gu_job) + " atom " + String.valueOf(oAtm.getInt(DB.pg_atom)) + e.getMessage());
                DebugFile.writeln(StackTraceUtil.getStackTrace(e));
              }

              sLastError = e.getClass().getName() + ", job " + oJob.getString(DB.gu_job) + " ";
              sLastError = "atom " + String.valueOf(oAtm.getInt(DB.pg_atom)) + " ";
              sLastError += e.getMessage() + "\n" + StackTraceUtil.getStackTrace(e) + "\n";
              try {
                oAtm.setStatus(oCon, Atom.STATUS_INTERRUPTED, e.getClass().getName() + " " + e.getMessage());
              } catch (SQLException sqle) {
                if (DebugFile.trace) DebugFile.writeln("Atom.setStatus() SQLException " + sqle.getMessage());
              }
              oJob.log(sLastError);

              if (iCallbacks>0) callBack(WorkerThreadCallback.WT_EXCEPTION, "Thread " + getName() + " " + sLastError, e, oJob);
            }

            if (oJob.pending()==0) {
              oJob.setStatus(oCon, Job.STATUS_FINISHED);
              if (iCallbacks>0) callBack(WorkerThreadCallback.WT_JOB_FINISH, "finish", null, oJob);
              if (sJob!=null) bContinue = false;
            }
          } // wend
          oRst.close();
          oStm.close();
        }
        else
          bContinue = false;
      } // wend

      if (!oCon.isClosed())
        oCon.close("SingleThreadExecutor_"+String.valueOf(currentThread().getId()));

      if (oGlobalDbb==null && oDBB!=null) oDBB.close();
    }
    catch (SQLException e) {

	  try { if (oCon!=null) if (!oCon.isClosed()) oCon.close(); } catch (Exception ignore) {}

      if (oGlobalDbb==null && oDBB!=null) oDBB.close();

      sLastError = "SQLException " + e.getMessage();

      if (iCallbacks>0) callBack(-1, sLastError, new SQLException(e.getMessage(), e.getSQLState(), e.getErrorCode()), null);

      if (oJob!=null) oJob.log(sLastError + "\n");

    }
    catch (FileNotFoundException e) {

	  try { if (oCon!=null) if (!oCon.isClosed()) oCon.close(); } catch (Exception ignore) {}

      if (oGlobalDbb==null && oDBB!=null) oDBB.close();

      sLastError = "FileNotFoundException " + e.getMessage();

      if (iCallbacks>0) callBack(-1, sLastError, new FileNotFoundException(e.getMessage()), null);

      if (oJob!=null) oJob.log(sLastError + "\n");
    }
    catch (IOException e) {

	  try { if (oCon!=null) if (!oCon.isClosed()) oCon.close(); } catch (Exception ignore) {}

      if (oGlobalDbb==null && oDBB!=null) oDBB.close();

      sLastError = "IOException " + e.getMessage();

      if (iCallbacks>0) callBack(-1, sLastError, new IOException(e.getMessage()), null);

      if (oJob!=null) oJob.log(sLastError + "\n");
    }
    catch (ClassNotFoundException e) {

	  try { if (oCon!=null) if (!oCon.isClosed()) oCon.close(); } catch (Exception ignore) {}

      if (oGlobalDbb==null && oDBB!=null) oDBB.close();

      sLastError = "ClassNotFoundException " + e.getMessage();

      if (iCallbacks>0) callBack(-1, sLastError, new ClassNotFoundException(e.getMessage()), null);

      if (oJob!=null) oJob.log(sLastError + "\n");
    }
    catch (InstantiationException e) {

	  try { if (oCon!=null) if (!oCon.isClosed()) oCon.close(); } catch (Exception ignore) {}

      if (oGlobalDbb==null && oDBB!=null) oDBB.close();

      sLastError = "InstantiationException " + e.getMessage();

      if (iCallbacks>0) callBack(-1, sLastError, new InstantiationException(e.getMessage()), null);

      if (oJob!=null) oJob.log(sLastError + "\n");
    }
    catch (IllegalAccessException e) {

	  try { if (oCon!=null) if (!oCon.isClosed()) oCon.close(); } catch (Exception ignore) {}

      if (oGlobalDbb==null && oDBB!=null) oDBB.close();

      sLastError = "IllegalAccessException " + e.getMessage();

      if (iCallbacks>0) callBack(-1, sLastError, new IllegalAccessException(e.getMessage()), null);

      if (oJob!=null) oJob.log(sLastError + "\n");
    }
    catch (NullPointerException e) {

	  try { if (oCon!=null) if (!oCon.isClosed()) oCon.close(); } catch (Exception ignore) {}

      if (oGlobalDbb==null && oDBB!=null) oDBB.close();

      sLastError = "NullPointerException " + e.getMessage();

      if (iCallbacks>0) callBack(-1, sLastError, new NullPointerException(e.getMessage()), null);

      if (oJob!=null) oJob.log(sLastError + "\n");
    }

	if (DebugFile.trace) {
	  DebugFile.writeln("End SingleThreadExecutor.run() : "+String.valueOf(currentThread().getId()));
	}

  } // run

  // ---------------------------------------------------------------------------

  /**
   * <p>Halt thread execution commiting all operations in course before stopping</p>
   * If a thread is dead-locked by any reason halting it will not cause any effect.<br>
   * halt() method only sends a signals to the each WokerThread telling it that must
   * finish pending operations and stop.
   */
  public void halt() {
    bContinue = false;
  }

  // ***************************************************************************
  // Static Methods

   private static void printUsage() {
     System.out.println("");
     System.out.println("Usage:");
     System.out.println("SingleThreadExecutor {run | lrun} job_type cnf_file_path {gu_job | xml_file_path} [verbose]");
     System.out.println("job_type is one of {MAIL | FAX | SAVE | FTP}");
   }

  public static void main(String[] argv)
    throws java.io.FileNotFoundException, java.io.IOException, SQLException,
    ClassNotFoundException, IllegalAccessException, InstantiationException,
    org.xml.sax.SAXException {

    SingleThreadExecutor oExec;

    if (argv.length!=4 && argv.length!=5)
      printUsage();

    else if (argv.length==5 && !argv[4].equals("verbose"))
      printUsage();

    else if (!argv[0].equals("run") && !argv[0].equals("lrun"))
      printUsage();

    else if (!argv[1].equalsIgnoreCase("MAIL") && !argv[1].equalsIgnoreCase("FAX") &&
             !argv[1].equalsIgnoreCase("SAVE") && !argv[1].equalsIgnoreCase("FTP") )
      printUsage();

    else {

      if (argv[0].equals("run"))
        oExec = new SingleThreadExecutor(argv[2], argv[3]);

      else {
        String sJobGUID = Gadgets.generateUUID();

        Job.main(new String[]{"create", argv[1], argv[2], argv[3], sJobGUID });

        oExec = new SingleThreadExecutor(argv[2], sJobGUID);
      }

      if (argv.length==5)
        oExec.registerCallback(new SystemOutNotify());

      oExec.start();
    } // fi
  } // main

} // SingleThreadExecutor
