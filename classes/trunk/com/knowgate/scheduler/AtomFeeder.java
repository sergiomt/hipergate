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

import java.util.Date;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Timestamp;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipergate.QueryByForm;

import com.knowgate.crm.DistributionList;

import java.util.Properties;

/**
 * <p>Feeds atoms to RAM based AtomQueue</p>
 * @author Sergio Montoro Ten
 * @version 5.5
 */
public class AtomFeeder {
  private int iMaxBatchSize;

  /**
   * Create an Atom Feeder with a default batch size of 10000 atoms
   */
  public AtomFeeder() {
    iMaxBatchSize = 10000;
  }

  // ----------------------------------------------------------

  public void setMaxBatchSize(int iMaxBatch) {
    iMaxBatchSize = iMaxBatch;
  }

  // ----------------------------------------------------------

  public int getMaxBatchSize() {
    return iMaxBatchSize;
  }

  // ----------------------------------------------------------

  /**
   * <p>Load a dynamic list of members from k_member_address to k_job_atoms</p>
   * <p>Registers will be filtered according to the query stored at k_queries table
   * witch corresponds to the list at k_lists used by Job being loaded.</p>
   * @param oConn Database Connection
   * @param sJobGUID Job to be loaded
   * @param dtExec Scheduled Execution DateTime
   * @param sListGUID Base List GUID
   * @param sQueryGUID GUID of Query to be used for member filtering upon retrieval
   * @param sWorkAreaGUID GUID of WorArea
   * @throws SQLException
   */

  private int loadDynamicList(JDCConnection oConn, String sJobGUID, Date dtExec, String sListGUID,
                              String sQueryGUID, String sWorkAreaGUID, short iInitialStatus) throws SQLException {
    Statement oStmt;
    QueryByForm oQBF;
    String sSQL;
    int iInserted;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin AtomFeeder.loadDynamicList([Connection] , " + sJobGUID + "," + dtExec.toString() + "," + sQueryGUID + "," + sWorkAreaGUID + " )");
       DebugFile.incIdent();
     }

    // Lista de columnas de la table k_member_address
    String sColumns = "gu_company,gu_contact,tx_email,tx_name,tx_surname,tx_salutation,nm_commercial,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,nm_country,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box";

    // Componer la sentencia SQL de filtrado de datos a partir de la definición de la consulta almacenada en la tabla k_queries
    oQBF = new QueryByForm(oConn, DB.k_member_address, "ma", sQueryGUID);

    // Insertar los registros a capón haciendo un snapshot de k_member_address a k_job_atoms
    // y evitando los atomos cuyo e-mail ya este en k_job_atoms o k_job_atoms_archived
    oStmt = oConn.createStatement();

    sSQL = "INSERT INTO " + DB.k_job_atoms +
           " (gu_job,id_status," + sColumns + ") " +
           " (SELECT '" + sJobGUID + "'," + String.valueOf(iInitialStatus) +
           "," + sColumns + " FROM " + DB.k_member_address + " ma WHERE ma.gu_workarea='" + sWorkAreaGUID +
           "' AND (" + oQBF.composeSQL() + ") AND NOT EXISTS (SELECT x." + DB.tx_email +
           " FROM " + DB.k_lists + " b, " + DB.k_x_list_members + " x WHERE b." +
           DB.gu_list + "=x." + DB.gu_list + " AND b." + DB.gu_query + "='" + sListGUID +
           "' AND b." + DB.tp_list + "=" + String.valueOf(DistributionList.TYPE_BLACK) +
           " AND x." + DB.tx_email + "=ma." + DB.tx_email + ") AND NOT EXISTS (SELECT j." + DB.tx_email +
           " FROM " + DB.k_job_atoms + " j WHERE j." + DB.gu_job + "='" + sJobGUID + "' AND " +
           " j." +DB.tx_email + "=ma." + DB.tx_email+") AND NOT EXISTS (SELECT a." + DB.tx_email +
           " FROM " + DB.k_job_atoms_archived + " a WHERE a." + DB.gu_job + "='" + sJobGUID + "' AND " +
           " a." +DB.tx_email + "=ma." + DB.tx_email+"))"; 

    if (DebugFile.trace) DebugFile.writeln("Connection.executeUpdate(" + sSQL + ")");

    iInserted = oStmt.executeUpdate(sSQL);

    oStmt.close();

    if (DebugFile.trace) {
       DebugFile.decIdent();

       DebugFile.writeln("End AtomFeeder.loadDynamicList() : " + String.valueOf(iInserted));
     }
     return iInserted;
  } // loadDynamicList()

  // ----------------------------------------------------------

  /**
   * <p>Load a static member list from k_x_list_members to k_job_atoms</p>
   * @param oConn Database Connection
   * @param sJobGUID GUID of Job to be loaded
   * @param dtExec Execution date to be assigned to Atoms (inherited from job)
   * @param sListGUID GUID of list to be loaded
   * @throws SQLException
   */
  private int loadStaticList(JDCConnection oConn, String sJobGUID,
  							 Date dtExec, String sListGUID, short iInitialStatus)
  	throws SQLException {
    int iInserted;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin AtomFeeder.loadStaticList([Connection] , " + sJobGUID + "," + dtExec.toString() + "," + sListGUID + ")");
       DebugFile.incIdent();
     }

    // Lista de columnas de la table k_x_list_members
    // * TO DO: Añadir el resto de columnas que faltan para reemplazar direcciones
    String sColumns = "id_format,gu_company,gu_contact,tx_email,tx_name,tx_surname,tx_salutation";

    // Insertar los registros a capón haciendo un snapshot de k_member_address a k_job_atoms
	iInserted =  DBCommand.executeUpdate(oConn, "INSERT INTO " + DB.k_job_atoms +
           " (gu_job,id_status," + sColumns + ") " +
           " (SELECT '" + sJobGUID + "'," + String.valueOf(iInitialStatus) +
           "," + sColumns + " FROM " + DB.k_x_list_members + " m WHERE " +
           DB.gu_list + "='" + sListGUID + "' AND m." + DB.bo_active + "<>0 " +
           " AND NOT EXISTS (SELECT x." + DB.tx_email + " FROM " + DB.k_lists + " b, " +
           DB.k_x_list_members + " x WHERE b." + DB.gu_list + "=x." + DB.gu_list +
           " AND b." + DB.gu_query + "='" + sListGUID + "' AND b." + DB.tp_list +
           "=" + String.valueOf(DistributionList.TYPE_BLACK) + " AND x." + DB.tx_email + "=m." + DB.tx_email + ") "+
		   " AND NOT EXISTS (SELECT j." + DB.tx_email +
           " FROM " + DB.k_job_atoms + " j WHERE j." + DB.gu_job + "='" + sJobGUID + "' AND " +
           " j." +DB.tx_email + "=m." + DB.tx_email+") AND NOT EXISTS (SELECT a." + DB.tx_email +
           " FROM " + DB.k_job_atoms_archived + " a WHERE a." + DB.gu_job + "='" + sJobGUID + "' AND " +
           " a." +DB.tx_email + "=m." + DB.tx_email+"))");

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End AtomFeeder.loadStaticList() : " + String.valueOf(iInserted));
     }

     return iInserted;
  } // loadStaticList()

  // ----------------------------------------------------------

  /**
   * <p>Load direct list into k_job_atoms table</p>
   * @param oConn Database Connection
   * @param sJobGUID GUID of Job to be loaded
   * @param dtExec Execution date to be assigned to Atoms (inherited from job)
   * @param sListGUID GUID of list to be loaded
   * @throws SQLException
   */

  private int loadDirectList(JDCConnection oConn, String sJobGUID, Date dtExec,
                             String sListGUID, short iInitialStatus)
    throws SQLException {

    // Alimentar una lista directa se hace igual que una estática
    return loadStaticList(oConn, sJobGUID, dtExec, sListGUID, iInitialStatus);
  } // loadDirectList()

  // ----------------------------------------------------------

  private Properties parseParameters(String sTxParams) {
    String aVariable[];
    String aParams[];
    Properties oParams = new Properties();

    if (DebugFile.trace) {
       DebugFile.writeln("Begin AtomFeeder.parseParameters(" + sTxParams + ")");
       DebugFile.incIdent();
     }

    if (sTxParams!=null) {
      if (sTxParams.length()>0) {
        aParams = Gadgets.split(sTxParams, ",");

        for (int p = 0; p < aParams.length; p++) {
          aVariable = Gadgets.split(aParams[p], ":");
          oParams.put(aVariable[0], aVariable[1]);
        } // next (p)
      } // fi (sTxParams!="")
    } // fi (sTxParams!=null)

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End AtomFeeder.parseParameters() : " + String.valueOf(oParams.size()));
     }

    return oParams;
  } // parseParameters

  // ----------------------------------------------------------

  /**
   * <p>Load an Atom batch into k_job_atoms table</p>
   * <p>Atoms will be taken by looking up pending Jobs by its execution date and extracting Atoms
   * for nearest Jobs in time.<br>
   * On each loadAtoms() no more than iWorkerThreads Jobs will be loaded at a time.
   * @param oConn Database Connection
   * @param iWorkerThreads Number of worker thread. This parameter will limit the number of loaded Jobs
   * as the program will try to use a one to one ratio between Jobs and WorkerThreads.
   * @return DBSubset with loaded Jobs
   * @throws SQLException
   */

  public DBSubset loadAtoms(JDCConnection oConn, int iWorkerThreads) throws SQLException {

    PreparedStatement oJobStmt;
    DBSubset  oJobsSet;
    int iJobCount;
    Properties oParams;
    DistributionList oDistribList;
    Date dtNow = new Date();
    Date dtExec;
    String sSQL;
    int iLoaded = 0;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin AtomFeeder.loadAtoms([Connection], " + String.valueOf(iWorkerThreads) + ")");
       DebugFile.incIdent();
     }

    // Crea un DBSubset para recorrer los jobs pendientes de ejecución

    oJobsSet = new DBSubset(DB.k_jobs,
                            "gu_job,gu_job_group,gu_workarea,id_command,tx_parameters,id_status,dt_execution,dt_finished,dt_created,dt_modified",
                            DB.id_status + "=" + String.valueOf(Job.STATUS_PENDING) + " ORDER BY " +
                            DB.id_status + " DESC," + DB.dt_execution + " DESC", iWorkerThreads);

    oJobsSet.setMaxRows(iWorkerThreads);

    iJobCount = oJobsSet.load(oConn); // Devuelve la cuenta de jobs pendientes

    // Prepara la sentencia para actualizar el estado de los jobs a Running
    sSQL = "UPDATE " + DB.k_jobs + " SET " + DB.id_status + "=" + String.valueOf(Job.STATUS_RUNNING) + "," + DB.dt_execution + "=" + DBBind.Functions.GETDATE + " WHERE " + DB.gu_job + "=?";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

    oJobStmt = oConn.prepareStatement(sSQL);

    // Para cada job, cargar su lista de miembros del tipo que corresponda y
    // cambiar el estado a Running
    for (int j=0; j<iJobCount; j++) {
      // leer los parámetros adicionales del job del campo tx_parameters
      oParams = parseParameters(oJobsSet.getString(4, j));

      // Generar un objeto temporal de tipo lista de distribución
      // para leer los valores de la lista de miembros
      if (oParams.getProperty("gu_list")!=null) {
        oDistribList = new DistributionList(oConn, oParams.getProperty("gu_list"));

        // Si la fecha de ejecución del job es null,
        // tomar la fecha actual como fecha de ejecución inmediata
        if (oJobsSet.isNull(DB.dt_execution,j))
          dtExec = dtNow;
        else
          dtExec = oJobsSet.getDate(DB.dt_execution,j);

        // Para cada tipo de lista usar el método de carga de miembros que corresponda
        switch (oDistribList.getShort(DB.tp_list)) {
          case DistributionList.TYPE_DYNAMIC:
            iLoaded += loadDynamicList(oConn, oJobsSet.getString(0, j), dtExec, oParams.getProperty("gu_list"), oDistribList.getString(DB.gu_query), oDistribList.getString(DB.gu_workarea), Atom.STATUS_PENDING);
            break;
          case DistributionList.TYPE_STATIC:
            iLoaded += loadStaticList(oConn, oJobsSet.getString(0, j), dtExec, oParams.getProperty("gu_list"), Atom.STATUS_PENDING);
            break;
          case DistributionList.TYPE_DIRECT:
            iLoaded += loadDirectList(oConn, oJobsSet.getString(0, j), dtExec, oParams.getProperty("gu_list"), Atom.STATUS_PENDING);
            break;
        } // end switch()
      }
      else
        iLoaded = 0;

      // Cambiar el estado del job cargado de Pending a Running

      if (DebugFile.trace) DebugFile.writeln("PrepareStatement.setString(1, '" + oJobsSet.getStringNull(0, j, "") + "')");

      oJobStmt.setString (1, oJobsSet.getString(0, j));

      if (DebugFile.trace) DebugFile.writeln("PrepareStatement.executeUpdate()");

      oJobStmt.executeUpdate();
    } // next (j)

    if (DebugFile.trace) DebugFile.writeln("PrepareStatement.close()");

    oJobStmt.close();

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End AtomFeeder.loadAtoms() : " + String.valueOf(iLoaded));
     }

     return oJobsSet;
  } // loadAtoms()

  // ----------------------------------------------------------

  /**
   * <p>Load Atoms for a given Job into k_job_atoms table</p>
   * On each loadAtoms() no more than iWorkerThreads Jobs will be loaded at a time.
   * @param oConn Database Connection
   * @param sJodId GUID of Job for witch atoms are to be loaded.
   * @param iInitialStatus Initial status for new Atoms
   * @return DBSubset with loaded Job
   * @throws SQLException
   */

  public DBSubset loadAtoms(JDCConnection oConn, String sJobId, short iInitialStatus) throws SQLException {
    PreparedStatement oJobStmt;
    DBSubset  oJobsSet;
    int iJobCount;
    Properties oParams;
    DistributionList oDistribList;
    Date dtNow = new Date();
    Date dtExec;
    String sSQL;
    int iLoaded = 0;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin AtomFeeder.loadAtoms([Connection:"+oConn.pid()+"], " + sJobId + ")");
       DebugFile.incIdent();
     }

    // Crea un DBSubset para recorrer los jobs pendientes de ejecución

    oJobsSet = new DBSubset(DB.k_jobs,
                            "gu_job,gu_job_group,gu_workarea,id_command,tx_parameters,id_status,dt_execution,dt_finished,dt_created,dt_modified",
                            DB.gu_job + "='" + sJobId + "'", 1);


    iJobCount = oJobsSet.load(oConn); // Devuelve la cuenta de jobs pendientes

    // Prepara la sentencia para actualizar el estado de los jobs a Running
    sSQL = "UPDATE " + DB.k_jobs + " SET " + DB.id_status + "=" + String.valueOf(Job.STATUS_RUNNING) + "," + DB.dt_execution + "=" + DBBind.Functions.GETDATE + " WHERE " + DB.gu_job + "=?";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ") on connection with process id. "+oConn.pid());

    oJobStmt = oConn.prepareStatement(sSQL);

    // Para cada job, cargar su lista de miembros del tipo que corresponda y
    // cambiar el estado a Running
    if (1==iJobCount) {
      // leer los parámetros adicionales del job del campo tx_parameters
      oParams = parseParameters(oJobsSet.getString(4, 0));

      // Generar un objeto temporal de tipo lista de distribución
      // para leer los valores de la lista de miembros
      if (oParams.getProperty("gu_list")!=null) {
        oDistribList = new DistributionList(oConn, oParams.getProperty("gu_list"));

        // Si la fecha de ejecución del job es null,
        // tomar la fecha actual como fecha de ejecución inmediata
        if (oJobsSet.isNull(DB.dt_execution,0))
          dtExec = dtNow;
        else
          dtExec = oJobsSet.getDate(DB.dt_execution,0);

        // Para cada tipo de lista usar el método de carga de miembros que corresponda
        switch (oDistribList.getShort(DB.tp_list)) {
          case DistributionList.TYPE_DYNAMIC:
            iLoaded += loadDynamicList(oConn, oJobsSet.getString(0, 0), dtExec, oParams.getProperty("gu_list"), oDistribList.getString(DB.gu_query), oDistribList.getString(DB.gu_workarea), iInitialStatus);
            break;
          case DistributionList.TYPE_STATIC:
            iLoaded += loadStaticList(oConn, oJobsSet.getString(0, 0), dtExec, oParams.getProperty("gu_list"), iInitialStatus);
            break;
          case DistributionList.TYPE_DIRECT:
            iLoaded += loadDirectList(oConn, oJobsSet.getString(0, 0), dtExec, oParams.getProperty("gu_list"), iInitialStatus);
            break;
        } // end switch()
      }
      else
        iLoaded = 0;

      // Cambiar el estado del job cargado de Pending a Running

      if (DebugFile.trace) DebugFile.writeln("PrepareStatement.setString(1, '" + oJobsSet.getStringNull(0, 0, "") + "')");

      oJobStmt.setString (1, oJobsSet.getString(0, 0));

      if (DebugFile.trace) DebugFile.writeln("PrepareStatement.executeUpdate()");

      oJobStmt.executeUpdate();
    } // fi

    if (DebugFile.trace) DebugFile.writeln("PrepareStatement.close()");

    oJobStmt.close();

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End AtomFeeder.loadAtoms(sJobId) : " + String.valueOf(iLoaded));
     }

     return oJobsSet;
  } // loadAtoms()

  // ----------------------------------------------------------

  /**
   * <p>Load Atoms with PENDING status for a given Job into k_job_atoms table</p>
   * On each loadAtoms() no more than iWorkerThreads Jobs will be loaded at a time.
   * @param oConn Database Connection
   * @param sJodId GUID of Job for witch atoms are to be loaded.
   * @return DBSubset with loaded Job
   * @throws SQLException
   */

  public DBSubset loadAtoms(JDCConnection oConn, String sJobId) throws SQLException {
    return loadAtoms(oConn, sJobId, Atom.STATUS_PENDING);
  }
  
  // ----------------------------------------------------------

  /**
   * <p>Feed RAM queue with pending Atoms from k_job_atoms table</p>
   * @param oConn Database Connection
   * @param oQueue AtomQueue
   * @throws SQLException
   */

  public void feedQueue(JDCConnection oConn, AtomQueue oQueue) throws SQLException {
    PreparedStatement oStmt;
    PreparedStatement oUpdt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    String sJobId;
    int iAtomId;
    int iJobCol;
    int iAtmCol;
    int iProcessed;
    String sSQL;
    Atom oAtm;
    boolean bNext;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin AtomFeeder.feedQueue([Connection:"+oConn.pid()+"], [AtomQueue])");
       DebugFile.incIdent();
     }

    // Crear un cursor actualizable para recorrer los átomos y cargarlos en la cola
    // al mismo tiempo que se cambia en la base de datos su estado de Pending a Running

    sSQL = "SELECT a.*, j." + DB.tx_parameters + " FROM " + DB.k_job_atoms + " a, " + DB.k_jobs + " j WHERE " +
    	   "a." + DB.id_status + "=" + String.valueOf(Atom.STATUS_PENDING) + " AND j." + DB.gu_job + "=a." + DB.gu_job +
    	   " AND (j." + DB.dt_execution + " IS NULL OR j." + DB.dt_execution + "<=?) " +
    	   " ORDER BY j." + DB.dt_execution;

    if (DebugFile.trace) DebugFile.writeln("JDCConnection.prepareStatement(" + sSQL + ") on connection with process id. "+oConn.pid());

    oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oStmt.setTimestamp(1, new Timestamp(new Date().getTime()));

    oRSet = oStmt.executeQuery();

    oMDat = oRSet.getMetaData();
    iJobCol = oRSet.findColumn(DB.gu_job);
    iAtmCol = oRSet.findColumn(DB.pg_atom);

    // Bucle de carga y actualización de estado de job_atoms

    sSQL = "UPDATE " + DB.k_job_atoms + " SET " + DB.id_status + "=" + Atom.STATUS_RUNNING + " WHERE " + DB.gu_job + "=? AND " + DB.pg_atom + "=?";
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ") on connection with process id. "+oConn.pid());
    oUpdt = oConn.prepareStatement(sSQL);

    iProcessed = 0;

    bNext = oRSet.next();

    while (bNext && iProcessed<iMaxBatchSize) {
      oAtm = new Atom(oRSet, oMDat);

      oQueue.push (oAtm);

      sJobId = oRSet.getString(iJobCol);
      iAtomId = oRSet.getInt(iAtmCol);

      bNext = oRSet.next();

      oUpdt.setString(1, sJobId);
      oUpdt.setInt   (2, iAtomId);

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate(UPDATE " + DB.k_job_atoms + " SET " + DB.id_status + "=" + Atom.STATUS_RUNNING + " WHERE " + DB.gu_job + "='" + sJobId + "' AND " + DB.pg_atom + "=" + String.valueOf(iAtomId) +")");
      oUpdt.executeUpdate();

      iProcessed++;
    } // wend

    oUpdt.close();
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End AtomFeeder.feedQueue() : " + String.valueOf(iProcessed));
     }
  } // feedQueue

  /*
   * Formatea una fecha en formato escape ODBC
   * @param dt Fecha a formatear
   * @param sFormat tipo de formato {d=yyyy-mm-dd, ts=yyyy-mm-dd hh:nn:ss}
   * @return Fecha formateada como una cadena

  private static String escape(java.util.Date dt) {
      String str;
      String sMonth, sDay, sHour, sMin, sSec;

      str = "{ ts '";

      sMonth = (dt.getMonth()+1<10 ? "0" + String.valueOf((dt.getMonth()+1)) : String.valueOf(dt.getMonth()+1));
      sDay = (dt.getDate()<10 ? "0" + String.valueOf(dt.getDate()) : String.valueOf(dt.getDate()));

      str += String.valueOf(dt.getYear()+1900) + "-" + sMonth + "-" + sDay + " ";

      sHour = (dt.getHours()<10 ? "0" + String.valueOf(dt.getHours()) : String.valueOf(dt.getHours()));
      sMin = (dt.getMinutes()<10 ? "0" + String.valueOf(dt.getMinutes()) : String.valueOf(dt.getMinutes()));
      sSec = (dt.getSeconds()<10 ? "0" + String.valueOf(dt.getSeconds()) : String.valueOf(dt.getSeconds()));

      str += " " + sHour + ":" + sMin +  ":" + sSec;

      str = str.trim() + "'}";

      return str;
  } // escape()

   */

  // ----------------------------------------------------------

} // AtomFeeder
