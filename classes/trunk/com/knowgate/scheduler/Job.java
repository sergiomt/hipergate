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

import java.util.Arrays;
import java.util.Date;
import java.util.Properties;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.File;
import java.io.FileWriter;

import javax.mail.MessagingException;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Environment;
import com.knowgate.misc.Gadgets;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataxslt.db.PageSetDB;
import com.knowgate.crm.GlobalBlackList;

import com.oreilly.servlet.MailMessage;

/**
 * <p>Abstract base class for Job Commands Implementations</p>
 * @author Sergio Montoro Ten
 * @version 5.0
 */
public abstract class Job extends DBPersist {

  private static final long serialVersionUID = 500l;

  private Properties oParams;
  private Properties oEnvProps;
  private File oLogFile;
  private DBBind oDataBind;

  protected int iPendingAtoms;

  public Job() {
    super(DB.k_jobs, "Job");
    oParams = null;
    oEnvProps = null;
    iPendingAtoms = 0;
    oLogFile = null;
    oDataBind = null;
  }

  // ----------------------------------------------------------

  /**
   * <p>Process an atom</p>
   * Concrete atom processing implementation must be provided by each derived subclass.
   * @param oAtm Atom to be processed
   * @return Custom subclass defined Object
   * @throws SQLException
   * @throws FileNotFoundException
   * @throws IOException
   * @throws MessagingException
   * @throws NullPointerException
   */
  public abstract Object process (Atom oAtm)
      throws SQLException,FileNotFoundException,IOException,MessagingException,
      NullPointerException,ClassNotFoundException,InstantiationException,IllegalAccessException;

  // ----------------------------------------------------------

  /**
   * <p>This method must free all the resource allocated by a Job</p>
   */
  public abstract void free ();

  // ----------------------------------------------------------

  /**
   * <p>Count of atoms pending of processing for this Job</p>
   * This count is decremented upon each successfull call to process() method
   */
  public int pending() {
    return iPendingAtoms;
  }

  // ----------------------------------------------------------

  public void abort(JDCConnection oConn) throws SQLException,IllegalStateException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Job.abort()");
      DebugFile.incIdent();
      DebugFile.writeln("gu_job="+getStringNull(DB.gu_job,"null"));
    }

    short iStatus;
    String sSQL;
    PreparedStatement oUpdt;

	iPendingAtoms = 0;

    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.id_status+" FROM "+DB.k_jobs+" WHERE "+DB.gu_job+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getStringNull(DB.gu_job,null));
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      iStatus = oRSet.getShort(1);
    else
      iStatus = 100;
    oRSet.close();
    oStmt.close();

    if (100==iStatus)
      throw new SQLException("Job "+getStringNull(DB.gu_job,"null")+" not found");
    if (Atom.STATUS_ABORTED==iStatus)
      throw new IllegalStateException("Job "+getStringNull(DB.gu_job,"null")+" was already aborted");
    else if (Atom.STATUS_FINISHED==iStatus)
      throw new IllegalStateException("Job "+getStringNull(DB.gu_job,"null")+" was already finished");

    sSQL = "UPDATE "+DB.k_job_atoms+" SET "+DB.id_status+"="+String.valueOf(Atom.STATUS_ABORTED)+","+DB.dt_execution+"=NULL WHERE "+DB.gu_job+"=? AND "+DB.id_status+"<>"+String.valueOf(Atom.STATUS_FINISHED);
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
    oUpdt = oConn.prepareStatement(sSQL);
    oUpdt.setString(1, getStringNull(DB.gu_job,null));
    oUpdt.executeUpdate();
    oUpdt.close();

    sSQL = "INSERT INTO " + DB.k_job_atoms_archived + " (" + Atom.COLUMNS_LIST + ") " +
           "SELECT " + Atom.COLUMNS_LIST + " FROM " + DB.k_job_atoms +
           " WHERE gu_job='" + getString(DB.gu_job) + "'";
    oUpdt = oConn.prepareStatement(sSQL);
    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
    oUpdt.executeUpdate();
    oUpdt.close();

    sSQL = "DELETE FROM " + DB.k_job_atoms + " WHERE gu_job='" + getString(DB.gu_job) + "'";
    oUpdt = oConn.prepareStatement(sSQL);
    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
    oUpdt.executeUpdate();
    oUpdt.close();

    sSQL = "UPDATE "+DB.k_jobs+" SET "+DB.id_status+"="+String.valueOf(Atom.STATUS_ABORTED)+","+DB.dt_finished+"="+DBBind.Functions.GETDATE+" WHERE "+DB.gu_job+"=?";
    oUpdt = oConn.prepareStatement(sSQL);
    oUpdt.setString(1, getStringNull(DB.gu_job,null));
    oUpdt.executeUpdate();
    oUpdt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Job.abort()");
    }
  } // abort

  // ----------------------------------------------------------

  /**
   * <p>Load Job</p>
   * @param oConn Database Connection
   * @param PKVals An Array with a single element containing the Job GUID
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    boolean bRetVal;
    String sList;
    String sPageSet;
    String sAttachImages;
    Statement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Job.load([Connection], Object[])");
      DebugFile.incIdent();
    }

    oParams = null;

    bRetVal = super.load(oConn, PKVals);

    if (bRetVal) {

      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(60); } catch (SQLException sqle) { }

      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT COUNT(*) FROM " + DB.k_job_atoms + " WHERE " + DB.gu_job + "='" + getStringNull(DB.gu_job,"null") + "' AND (" + DB.id_status + "=" + String.valueOf(Atom.STATUS_PENDING) + " OR " + DB.id_status + "=" + String.valueOf(Atom.STATUS_SUSPENDED) + "))");

      oRSet = oStmt.executeQuery("SELECT COUNT(*) FROM " + DB.k_job_atoms + " WHERE " + DB.gu_job + "='" + getString(DB.gu_job) + "' AND (" + DB.id_status + "=" + String.valueOf(Atom.STATUS_PENDING) + " OR " + DB.id_status + "=" + String.valueOf(Atom.STATUS_SUSPENDED) + " OR " + DB.id_status + "=" + String.valueOf(Atom.STATUS_RUNNING) + ")");
      oRSet.next();
      iPendingAtoms = oRSet.getInt(1);
      oRSet.close();

      oStmt.close();

      if (DebugFile.trace) DebugFile.writeln("pending atoms = " + String.valueOf(iPendingAtoms));

      sPageSet = getParameter("gu_pageset");

      if (null!=sPageSet) {

        oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

        oRSet = oStmt.executeQuery("SELECT " + DB.gu_workarea + "," + DB.nm_pageset + " FROM " + DB.k_pagesets + " WHERE " + DB.gu_pageset + "='" + sPageSet + "'");

        if (oRSet.next()) {
          oParams.put("gu_workarea", oRSet.getString(1));
          oParams.put("nm_pageset", oRSet.getString(2));

          oRSet.close();
          oStmt.close();

          PageSetDB oPageSetDB = new PageSetDB(oConn,sPageSet);
		  try {
		    oParams.put("nm_page", oPageSetDB.getFirstPage(oConn).getPage(oConn, Gadgets.chomp(getProperty("storage"),File.separator)).getTitle().replace(' ', '_') + ".html");
		  } catch (Exception xcpt) {
		  	throw new SQLException(xcpt.getMessage());
		  }
        }
        else {
          bRetVal = false;
          oRSet.close();
          oStmt.close();
        }

		if (!bRetVal) {
          if (DebugFile.trace) {
            DebugFile.writeln("ERROR: PageSet " + sPageSet +
                              " referenced by job " + getString(DB.gu_job) +
                              " was not found");
            DebugFile.decIdent();
          }
          throw new SQLException("PageSet " + sPageSet + " referenced by job " + getString(DB.gu_job) + " was not found at "+DB.k_pagesets);
		}
      } // fi (sPageSet)

      sList = getParameter("gu_list");

      if (null!=sList) {

        oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

        oRSet = oStmt.executeQuery("SELECT " + DB.tx_sender + "," + DB.tx_from + "," + DB.tx_reply + "," + DB.tx_subject + " FROM " + DB.k_lists + " WHERE " + DB.gu_list + "='" + sList + "'");

        if (oRSet.next()) {
          oParams.put("tx_sender", oRSet.getString(1));
          oParams.put("tx_from", oRSet.getString(2));
          oParams.put("tx_reply", oRSet.getString(2));
          oParams.put("tx_subject", oRSet.getString(2));
        }
        else {
          bRetVal = false;
        }
        oRSet.close();
        oStmt.close();

		if (!bRetVal){
          if (DebugFile.trace) {
            DebugFile.writeln("ERROR: List " + sList +
                              " referenced by job " + getString(DB.gu_job) +
                              " was not found");
            DebugFile.decIdent();
          }
          throw new SQLException("ERROR: List " + sList + " referenced by job " + getString(DB.gu_job) + " was not found");
		}
      } // fi (sList)

      sAttachImages = getParameter("bo_attachimages");

      if (null==sAttachImages)
        oParams.put("bo_attachimages", "1");
      else
        oParams.put("bo_attachimages", sAttachImages);

    } // fi (load(oConn, PKVals))

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Job.load() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // load

  // ----------------------------------------------------------

  /**
   * <p>Delete Job</p>
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    return Job.delete(oConn, getString(DB.gu_job));
  }

  // ----------------------------------------------------------

  /**
   * <p>Store Job</p>
   * By default jobs are created with id_status=STATUS_PENDING
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {

    if (!AllVals.containsKey(DB.gu_job))
      put(DB.gu_job, Gadgets.generateUUID());
    else
      put(DB.dt_modified, new Timestamp(new Date().getTime()));

    if (!AllVals.containsKey(DB.id_status))
      put(DB.id_status, STATUS_PENDING);

    return super.store(oConn);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get parameters extracted from tx_parameter field</p>
   * @return Parameters as a java.util.Properties object
   */

  public Properties getParameters() {
    String aParams[];
    int iParams;
    int iDot;

    if (null==oParams) {
      oParams = new Properties();
      if (!isNull(DB.tx_parameters)) {
        aParams = Gadgets.split(getString(DB.tx_parameters), ",");
        iParams = aParams.length;
        for (int p = 0; p < iParams; p++) {
          iDot = aParams[p].indexOf(':');
          if (iDot <= 0)
            oParams.put(aParams[p], "");
          else
            oParams.put(aParams[p].substring(0, iDot),
                        aParams[p].substring(iDot + 1));
        } // next (p)
      } // fi (!isNull(DB.tx_parameters))
    } // fi (oParams)

    return oParams;
  } // getParameters

  // ----------------------------------------------------------

  /**
   * <p>Get parameter extracted from tx_parameter field</p>
   * @param sParamName Parameter Name
   * @return Parameter Value or <b>null</b> if not found
   */
  public String getParameter(String sParamName) {
    return getParameters().getProperty(sParamName);
  }


  /**
   * <p>Get Environment Property</p>
   * Environment properties are readed from hipergate.cnf.
   * @param sPropertyName
   * @return
   */
  public String getProperty(String sPropertyName) {
    return oEnvProps.getProperty(sPropertyName);
  }

  // ----------------------------------------------------------

  /**
   * Get Environment Properties Collection
   */
  public Properties getProperties() {
    return oEnvProps;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get reference to Job log file</p>
   * Job log file is placed at /storage/jobs/gu_workarea/
   * @return Reference to Job Log File Object
   */
  public File logFile() {
    return oLogFile;
  }

  // ----------------------------------------------------------

  /**
   * <p>Write Line to Job Log File</p>
   * @param sStr Line to be written
   */
  public void log (String sStr) {
    FileWriter oWriter;

    if (oLogFile!=null) {
      oWriter = null;
      try {
        oWriter = new FileWriter(oLogFile, true);
        oWriter.write(sStr);
        oWriter.close();
        oWriter = null;
      }
      catch (IOException ioe) {
        if (null!=oWriter) { try {oWriter.close();} catch (IOException e) {} }
      }
    } // fi (oLogFile)
  } // log

  // ----------------------------------------------------------

  /**
   * Get database binding for this Job
   * @return DBBind
   */
  public DBBind getDataBaseBind() {
    return oDataBind;
  }

  // ----------------------------------------------------------

  /**
   * Assign a database binding to the Job
   * @param oDbb DBBind
   */
  public void setDataBaseBind(DBBind oDbb) {
    oDataBind = oDbb;
  }

  // ----------------------------------------------------------

  /**
   * <p>Set Job Status</p>
   * If Status if set to Job.STATUS_FINISHED then dt_finished is set to current
   * system date.
   * @param oConn Database Connection
   * @param iStatus Job Status
   * <table border=1 cellpaddng=4>
   * <tr><td>Status</td></tr>
   * <tr><td align=middle>STATUS_ABORTED (-1)</td></tr>
   * <tr><td align=middle>STATUS_FINISHED (0)</td></tr>
   * <tr><td align=middle>STATUS_PENDING (1)</td></tr>
   * <tr><td align=middle>STATUS_SUSPENDED (2)</td></tr>
   * <tr><td align=middle>STATUS_RUNNING (3)</td></tr>
   * </table>
   * @throws SQLException
   */
  public void setStatus(JDCConnection oConn, int iStatus) throws SQLException {

	if (iStatus!=Job.STATUS_ABORTED && iStatus!=Job.STATUS_FINISHED &&
		iStatus!=Job.STATUS_INTERRUPTED && iStatus!=Job.STATUS_PENDING &&
		iStatus!=Job.STATUS_RUNNING && iStatus!=Job.STATUS_SUSPENDED)
	  throw new IllegalArgumentException("Job.setStatus() illegal status value "+String.valueOf(iStatus));

    PreparedStatement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Job.setStatus([Connection], " + String.valueOf(iStatus) + ")");
      DebugFile.incIdent();
    }

    if (Job.STATUS_FINISHED==iStatus) {

      oStmt = oConn.prepareStatement("UPDATE " + DB.k_jobs + " SET " + DB.id_status + "=" + String.valueOf(iStatus) + "," + DB.dt_finished + "=? WHERE " + DB.gu_job + "='" + getString(DB.gu_job) + "'");

      oStmt.setTimestamp(1, new Timestamp(new java.util.Date().getTime()));
      oStmt.executeUpdate();
      oStmt.close();

    }

    else {

      oStmt = oConn.prepareStatement("UPDATE " + DB.k_jobs + " SET " + DB.id_status + "=" + String.valueOf(iStatus) + " WHERE " + DB.gu_job + "='" + getString(DB.gu_job) + "'");

      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(10);} catch (SQLException sqle) {}

      oStmt.executeUpdate();
      oStmt.close();

    }

	replace(DB.id_status, iStatus);
	
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Job.setStatus()");
    }
  } // setStatus

  /**
   * <p>Get Job status</p>
   * @since 5.0
   */

  public short getStatus() {
    return getShort(DB.id_status);
  }

  /**
   * <p>Fills atoms data from their e-mails</p>
   * This method call k_sp_resolve_atoms stored procedure which takes each atom
   * mail address and looks it up at k_member_address table for completing name
   * surname and other personalization data embedded into each atom's record
   * @param oConn JDCConnection
   * @throws SQLException
   */
  public void resolveAtomsEMails(JDCConnection oConn)
    throws SQLException {
    Statement oStmt;
    CallableStatement oCall;
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Job.resolveAtomsEMails()");
      DebugFile.incIdent();
    }
    switch (oConn.getDataBaseProduct()) {
      case JDCConnection.DBMS_POSTGRESQL:
        oStmt = oConn.createStatement();
        oStmt.executeQuery("SELECT k_sp_resolve_atoms('"+getStringNull(DB.gu_job,null)+"')");
        oStmt.close();
        break;
      default:
        oCall = oConn.prepareCall("{ call k_sp_resolve_atoms('"+getStringNull(DB.gu_job,null)+"') }");
        oCall.execute();
        oCall.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Job.resolveAtomsEMails()");
    }
  } // resolveAtomsEMails

  // **********************************************************
  // Static Methods

  /**
   * <p>Delete Job</p>
   * Call k_sp_del_job stored procedure
   * @param oConn Database Connection
   * @param sJobId GUID of Job to be deleted
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sJobId) throws SQLException {
    Statement oStmt;
    CallableStatement oCall;
    boolean bRetVal;
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Job.delete([Connection]," + sJobId + ")");
      DebugFile.incIdent();
    }

    switch (oConn.getDataBaseProduct()) {
      case JDCConnection.DBMS_POSTGRESQL:
        oStmt = oConn.createStatement();
        if (DebugFile.trace) DebugFile.writeln("Connection.executeQuery(SELECT k_sp_del_job ('" + sJobId + "')");
        oStmt.executeQuery("SELECT k_sp_del_job ('" + sJobId + "')");
        oStmt.close();
        bRetVal = true;
        break;
      default:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_job ('" + sJobId + "') }");
        oCall = oConn.prepareCall("{ call k_sp_del_job ('" + sJobId + "') }");
        bRetVal = oCall.execute();
        oCall.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Job.delete() : " + String.valueOf(bRetVal));
    }
    return bRetVal;
  } // delete

  // ----------------------------------------------------------

  /**
   * <p>Create an instance of a Job subclass</p>
   * <p>The new object class name will be readed form k_jobs.nm_class field.</p>
   * @param oConn Database Connection
   * @param sJobId GUID of Job to be instantiated
   * @param oEnvironmentProps Environment properties taken from hipergate.cnf
   * @return Reference to Instantiated Object
   * @throws FileNotFoundException If any directory for Job log file could not be created
   * @throws ClassNotFoundException If no class with name k_jobs.nm_class was found
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws SQLException
   */
  public static synchronized Job instantiate(JDCConnection oConn, String sJobId, Properties oEnvironmentProps)

    throws ClassNotFoundException, IllegalAccessException, SQLException, InstantiationException, FileNotFoundException {

    Class oJobImplementation;
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sStorage;
    String sCmmdId, sClassNm;
    Job oRetObj;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Job.instantiate([Connection]," + sJobId + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT id_command,tx_command,nm_class FROM k_lu_job_commands WHERE id_command=(SELECT id_command FROM k_jobs WHERE gu_job='" + sJobId + "'))");
    }

    oStmt = oConn.prepareStatement("SELECT id_command,tx_command,nm_class FROM "+DB.k_lu_job_commands+" WHERE "+DB.id_command+"=(SELECT id_command FROM k_jobs WHERE gu_job=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sJobId);

    if (DebugFile.trace) DebugFile.writeln("PreparedStatementStatement.executeQuery()");

    oRSet = oStmt.executeQuery();

    if (oRSet.next()) {

      sCmmdId = oRSet.getString(1);

      if (DebugFile.trace) DebugFile.writeln("Class Id =" + sCmmdId);

      sClassNm = oRSet.getString(3);

      if (DebugFile.trace) DebugFile.writeln("Class Name =" + sClassNm);
    } // fi (next())

    else {
      sCmmdId = null;
      sClassNm = "null";

	  if (DBCommand.queryExists(oConn, DB.k_jobs, DB.gu_job+"='"+sJobId+"'")) {
        if (DebugFile.trace) {
          DebugFile.writeln("SQLException Job "+sJobId+" was not found at "+DB.k_jobs+" table");
          DebugFile.decIdent();
        }
        throw new SQLException("Job "+sJobId+" was not found at "+DB.k_jobs+" table");
	  } // fi

	  if (DBCommand.queryExists(oConn, DB.k_lu_job_commands,
	                            DB.id_command+"=(SELECT id_command FROM k_jobs WHERE gu_job='"+sJobId+"'")) {
        if (DebugFile.trace) {
          DebugFile.writeln("SQLException command was not found at "+DB.k_lu_job_commands+" table for "+DBCommand.queryStr(oConn,"SELECT id_command FROM k_jobs WHERE gu_job='"+sJobId+"'"));
          DebugFile.decIdent();
        }
        throw new SQLException("Job "+sJobId+" was not found at "+DB.k_jobs+" table");
	  } // fi
	  
    } // fi

    oRSet.close();
    oStmt.close();

    if (null==sCmmdId) {

      oRetObj = null;

    } else {
      if (DebugFile.trace) DebugFile.writeln("Class.forName(" + sClassNm + ");");

      oJobImplementation = Class.forName(sClassNm);
      oRetObj = (Job) oJobImplementation.newInstance();
      oRetObj.oEnvProps = oEnvironmentProps;

      if (oRetObj.load(oConn, new Object[] {sJobId})) {
        if (null!=oConn.getPool()) {
          if (null!=oConn.getPool().getDatabaseBinding()) {
            if (DebugFile.trace) DebugFile.writeln("setting Job database binding to "+((DBBind) oConn.getPool().getDatabaseBinding()).getProfileName());
            oRetObj.setDataBaseBind( (DBBind) oConn.getPool().getDatabaseBinding());
          } else {
            if (DebugFile.trace) DebugFile.writeln("Connection Pool has no database binding for Job");
          }
        } else {
          if (DebugFile.trace) DebugFile.writeln("Connection has no pool from which to get database binding for Job");
        }

      } else {

        if (DebugFile.trace) {
          DebugFile.writeln("SQLException "+oRetObj.getClass().getName()+" failed to load "+sJobId);
          DebugFile.decIdent();
        }

        throw new SQLException("SQLException "+oRetObj.getClass().getName()+" failed to load "+sJobId);      	
      }
    } // fi (sCmmdId)

    if (null!=oRetObj) {
      sStorage = oEnvironmentProps.getProperty("storage");

      if (null != sStorage) {
        if (!sStorage.endsWith(System.getProperty("file.separator"))) sStorage += System.getProperty("file.separator");

        sStorage += "jobs";

        // Create directory storage/jobs

        oRetObj.oLogFile = new File(sStorage);
        if (!oRetObj.oLogFile.exists()) oRetObj.oLogFile.mkdir();
        if (!oRetObj.oLogFile.exists()) throw new FileNotFoundException(sStorage);

        // Create directory storage/jobs/gu_workarea

        sStorage += System.getProperty("file.separator") + oRetObj.getString(DB.gu_workarea);
        oRetObj.oLogFile = new File(sStorage);
        if (!oRetObj.oLogFile.exists()) oRetObj.oLogFile.mkdir();
        if (!oRetObj.oLogFile.exists()) throw new FileNotFoundException(sStorage);

        // Create directory storage/jobs/gu_workarea/gu_job
        // oRetObj.oLogFile = new File(sStorage + System.getProperty("file.separator") + sJobId);
        // if (!oRetObj.oLogFile.exists()) oRetObj.oLogFile.mkdir();
        // if (!oRetObj.oLogFile.exists()) throw new FileNotFoundException(sStorage);

        // Set File Object to storage/jobs/gu_workarea/gu_job/gu_job.txt
        oRetObj.oLogFile = new File(sStorage + System.getProperty("file.separator") + sJobId + ".txt");

      } // fi (sStorage)
    } // fi(oRetObj)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Job.instantiate()");
    }

    return oRetObj;
  } // instantiate

  /**
   * <p>Create an instance of a Job subclass</p>
   * <p>The new object class name will be readed form k_jobs.nm_class field.</p>
   * @param oConn Database Connection
   * @param sJobId GUID of Job to be deleted
   * @param sProfileName Name without .cnf extension of the properties file to use
   * @return Reference to Instantiated Object
   * @throws FileNotFoundException If any directory for Job log file could not be created
   * @throws ClassNotFoundException If no class with name k_jobs.nm_class was found
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws SQLException
   */
  public static synchronized Job instantiate(JDCConnection oConn, String sJobId, String sProfileName)
    throws ClassNotFoundException, IllegalAccessException, SQLException, InstantiationException, FileNotFoundException {
    return instantiate(oConn,sJobId,Environment.getProfile(sProfileName));
  }

  // **********************************************************
  // Static Methods

   /**
    * <p>Get a Job GUID given its title</p>
    * @param oConn Database Connection
    * @param sTitle Job Title (search is case sensitive)
    * @param oGuWorkArea GUID of WorkArea to restrict search, if <b>null</b> then all workareas are searched
    * @throws SQLException
    *
   **/
   public static String getIdFromTitle(JDCConnection oConn, String sTitle, String sGuWorkArea)
   	 throws SQLException {
     PreparedStatement oStmt;
     ResultSet oRSet;
     String sJobId;
     if (null==sGuWorkArea) {
       oStmt = oConn.prepareStatement("SELECT "+DB.gu_job+" FROM "+DB.k_jobs+" WHERE "+DB.tl_job+"=?",
                                      ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
       oStmt.setString(1, sTitle);
     } else {
       oStmt = oConn.prepareStatement("SELECT "+DB.gu_job+" FROM "+DB.k_jobs+" WHERE "+DB.tl_job+"=? AND "+DB.gu_workarea+"=?",
                                      ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
       oStmt.setString(1, sTitle);
       oStmt.setString(2, sGuWorkArea);
     }
     oRSet = oStmt.executeQuery();
     if (oRSet.next())
       sJobId = oRSet.getString(1);
     else
       sJobId = null;
     oRSet.close();
	 oStmt.close();
	 return sJobId;     	
   } // getIdFromTitle

  // ----------------------------------------------------------

   /**
    * <p>Insert a recipients list as new atoms of this Job</p>
    * The recipient data is readed from k_member_address by using recipient's e-mail as key.
    * @param oConn Database Connection
    * @param aRecipients Recipients list (e-mail addresses)
    * @param sRecipientTp Recipient Type {to,cc,bcc}
    * @param sFormat Message Format {text,html}
    * @param iStatusId {Job.STATUS_PENDING,STATUS_SUSPENDED}
    * @throws SQLException
    * @since 4.0
   **/
  public void insertRecipients(JDCConnection oConn, String[] aRecipients,
                               String sRecipientTp, String sFormat, short iStatusId)
  	throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Job.insertRecipients([JDCConnection], {"+Gadgets.join(aRecipients,",")+"}, "+sRecipientTp+", "+sFormat+", "+String.valueOf(iStatusId)+")");
      DebugFile.incIdent();      
    }

	final int nRecipients = aRecipients.length;

    ResultSet oRSet;
  	String[] aAddrCols = new String[]{DB.gu_company,DB.gu_contact,DB.tx_email,DB.tx_name,DB.tx_surname,DB.tx_salutation,DB.nm_commercial,DB.tp_street,DB.nm_street,DB.nu_street,DB.tx_addr1,DB.tx_addr2,DB.nm_country,DB.nm_state,DB.mn_city,DB.zipcode,DB.work_phone,DB.direct_phone,DB.home_phone,DB.mov_phone,DB.fax_phone,DB.other_phone,DB.po_box};
  	String[] aUserCols = new String[]{"NULL","NULL",DB.tx_main_email,DB.nm_user,DB.tx_surname1,"NULL",DB.nm_company,"NULL","NULL","NULL","NULL","NULL","NULL","NULL","NULL","NULL","NULL","NULL","NULL","NULL","NULL","NULL","NULL"};

	final int nCols = aAddrCols.length;
	String[] aAddrVals = new String[nCols];
    String sSQL;

	String[] aBlackList = GlobalBlackList.forWorkArea(oConn, getString(DB.gu_workarea));
	if (null!=aBlackList) Arrays.sort(aBlackList, String.CASE_INSENSITIVE_ORDER);
	
	sSQL = "SELECT "+Gadgets.join(aAddrCols,",")+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+getString(DB.gu_workarea)+"' AND "+DB.tx_email+"=?";
	if (DebugFile.trace) DebugFile.writeln("PreparedStatement.prepareStatement("+sSQL+")");
	PreparedStatement oAddr = oConn.prepareStatement(sSQL,ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

	sSQL = "SELECT "+Gadgets.join(aUserCols,",")+" FROM "+DB.k_users+" WHERE "+DB.gu_workarea+"='"+getString(DB.gu_workarea)+"' AND "+DB.tx_main_email+"=?";
	if (DebugFile.trace) DebugFile.writeln("PreparedStatement.prepareStatement("+sSQL+")");
	PreparedStatement oUser = oConn.prepareStatement(sSQL,ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

	sSQL = "INSERT INTO "+DB.k_job_atoms+" ("+DB.gu_job+","+DB.dt_execution+","+DB.id_status+","+DB.id_format+","+DB.tp_recipient+","+Gadgets.join(aAddrCols,",")+","+DB.tx_log+") VALUES ('"+getString(DB.gu_job)+"',NULL,"+String.valueOf(iStatusId)+",'"+sFormat+"','"+sRecipientTp+"',?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NULL)";
	if (DebugFile.trace) DebugFile.writeln("PreparedStatement.prepareStatement("+sSQL+")");
	PreparedStatement oAtom = oConn.prepareStatement(sSQL);

	sSQL = "INSERT INTO "+DB.k_job_atoms_archived+" ("+DB.gu_job+","+DB.dt_execution+","+DB.id_status+","+DB.id_format+","+Gadgets.join(aAddrCols,",")+","+DB.tx_log+","+DB.pg_atom+") VALUES ('"+getString(DB.gu_job)+"',NULL,"+String.valueOf(Job.STATUS_ABORTED)+",'"+sFormat+"',?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'Invalid e-mail address syntax',?)";
	if (DebugFile.trace) DebugFile.writeln("PreparedStatement.prepareStatement("+sSQL+")");
	PreparedStatement oArchived = oConn.prepareStatement(sSQL);

	sSQL = "SELECT NULL FROM "+DB.k_job_atoms+" WHERE "+DB.gu_job+"='"+getString(DB.gu_job)+"' AND "+DB.tx_email+"=?";
	PreparedStatement oExistsPending = oConn.prepareStatement(sSQL);

	sSQL = "SELECT NULL FROM "+DB.k_job_atoms_archived+" WHERE "+DB.gu_job+"='"+getString(DB.gu_job)+"' AND "+DB.tx_email+"=?";
	PreparedStatement oExistsArchived = oConn.prepareStatement(sSQL);
	
	for (int r=0; r<nRecipients; r++) {
		
	  oAddr.setString(1, aRecipients[r]);
	  oRSet = oAddr.executeQuery();
	  if (oRSet.next()) {
	    if (DebugFile.trace) DebugFile.writeln("Found member for recipient "+aRecipients[r]);
	    for (int c=1; c<=nCols; c++)
	      aAddrVals[c-1] = oRSet.getString(c);
	    oRSet.close();
	  } else {
	    oRSet.close();
	    oUser.setString(1, aRecipients[r]);
	    oRSet = oUser.executeQuery();
	    if (oRSet.next()) {
	      if (DebugFile.trace) DebugFile.writeln("Found user for recipient "+aRecipients[r]);
	      Arrays.fill(aAddrVals,null);
	      aAddrVals[2] = MailMessage.sanitizeAddress(oRSet.getString(3));
	      aAddrVals[3] = oRSet.getString(4);
	      aAddrVals[4] = oRSet.getString(5);
	      aAddrVals[6] = oRSet.getString(7);
	      oRSet.close();
	    } else {
	      if (DebugFile.trace) DebugFile.writeln("Neither member nor user found for recipient "+aRecipients[r]);
	      oRSet.close();
	      Arrays.fill(aAddrVals,null);
	      aAddrVals[2] = MailMessage.sanitizeAddress(aRecipients[r]);
	    }
	  }

	  // Avoid any recipient from being inserted twice at the database
	  boolean bAlreadyExists = false;
	  oExistsPending.setString(1, aAddrVals[2]);
	  oRSet = oExistsPending.executeQuery();
	  bAlreadyExists = oRSet.next();
	  oRSet.close();
	  if (!bAlreadyExists) {
	    oExistsArchived.setString(1, aAddrVals[2]);
	    oRSet = oExistsArchived.executeQuery();
	    bAlreadyExists = oRSet.next();
	    oRSet.close();	    
	  } // fi (!bAlreadyExists)
	  
	  // Avoid any blacklisted e-mail from being added to the recipients
	  boolean bBlackListed = false;
	  if (null!=aBlackList) bBlackListed = Arrays.binarySearch(aBlackList, aAddrVals[2].toLowerCase())>=0;

	  if (!bAlreadyExists && !bBlackListed) {
      	if (Gadgets.checkEMail(aAddrVals[2])) {
	      for (int i=1; i<=nCols; i++)
	        oAtom.setString(i,aAddrVals[i-1]);
	    
	      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate("+aAddrVals[2]+")");
      	
	      oAtom.executeUpdate();
      	} else if (!bBlackListed) {
	      for (int i=1; i<=nCols; i++)
	        oArchived.setString(i,aAddrVals[i-1]);
	    
	      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate("+aAddrVals[2]+",Invalid e-mail address syntax)");
      	
      	  oArchived.setInt(nCols+1, DBBind.nextVal(oConn, "seq_k_job_atoms"));
	      oArchived.executeUpdate();      	
      	} else {
	      if (DebugFile.trace) DebugFile.writeln("Skip "+aAddrVals[2]+" because is blacklisted");
      	}
	  } else {
	    if (DebugFile.trace) DebugFile.writeln("Skip "+aAddrVals[2]+" because is already a recipient");
	  }// fi (!bAlreadyExists)

	} // next
	oExistsArchived.close();
	oExistsPending.close();
	oArchived.close();
	oAtom.close();
	oAddr.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Job.insertRecipients()");
    }

  } // insertRecipients

  // ----------------------------------------------------------

   private static void printUsage() {
     System.out.println("");
     System.out.println("Usage:");
     System.out.println("Job create job_type cnf_file_path xml_file_path [gu_job]");
     System.out.println("job_type is one of {MAIL | SEND | FAX | SAVE | FTP}");
   }

  // ----------------------------------------------------------

   public static void main(String[] argv)
     throws SQLException, org.xml.sax.SAXException, java.io.IOException,
     ClassNotFoundException, IllegalAccessException, InstantiationException {

     DBPersist oJob;
     DBBind oDBB;
     JDCConnection oCon;

     if (argv.length!=4 && argv.length!=5)
       printUsage();
     else
       if (!argv[0].equals("create"))
         printUsage();

      else if (!argv[1].equalsIgnoreCase("MAIL") && !argv[1].equalsIgnoreCase("FAX") &&
                !argv[1].equalsIgnoreCase("SAVE") && !argv[1].equalsIgnoreCase("FTP") &&
                !argv[1].equalsIgnoreCase("SEND") )
        printUsage();

      else {
         oDBB = new DBBind(argv[2]);

         oCon = oDBB.getConnection("job_main");
         oCon.setAutoCommit(true);

         oJob = new DBPersist(DB.k_jobs, argv[1]);

         oJob.parseXML(argv[3]);

         if (argv.length==5)
           oJob.replace (DB.gu_job, argv[4]);

         else if (!oJob.getItemMap().containsKey(DB.gu_job))
           oJob.put (DB.gu_job, com.knowgate.misc.Gadgets.generateUUID());

         oJob.store(oCon);

         oCon.close();

         oDBB.close();

         System.out.println("gu_job:"+oJob.getString(DB.gu_job));
      } // fi

   } // main

  // **********************************************************
  // Public Constants

  public static final short STATUS_ABORTED = -1;
  public static final short STATUS_FINISHED = 0;
  public static final short STATUS_PENDING = 1;
  public static final short STATUS_SUSPENDED = 2;
  public static final short STATUS_RUNNING = 3;
  public static final short STATUS_INTERRUPTED = 4;

  public static final String COMMAND_SEND = "SEND";
  public static final String COMMAND_MAIL = "MAIL";
  public static final String COMMAND_SAVE = "SAVE";
  public static final String COMMAND_FAX = "FAX";
  public static final String COMMAND_FTP = "FTP";
  public static final String COMMAND_DUMY = "DUMY";
}
