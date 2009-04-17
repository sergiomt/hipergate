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
import java.sql.PreparedStatement;
import java.sql.Timestamp;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.debug.DebugFile;

/**
 * Atom queue consumer
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class AtomConsumer {

  private AtomQueue oQueue;
  private JDCConnection oConn;
  private PreparedStatement oStmt;

  // ----------------------------------------------------------

  /**
   * <p>Create Atom Queue Consumer</p>
   * @param oConnection
   * @param oAtomQueue
   * @throws SQLException
   */
  public AtomConsumer(JDCConnection oConnection, AtomQueue oAtomQueue) throws SQLException {
    oQueue = oAtomQueue;
    oConn = oConnection;

    if (DebugFile.trace) {
      DebugFile.writeln("Connection.prepareStatement (UPDATE " + DB.k_job_atoms + " SET " + DB.id_status + "=" + String.valueOf(Atom.STATUS_RUNNING) + ", " + DB.dt_execution + "=? WHERE " + DB.gu_job + "=? AND " + DB.pg_atom + "=?)");
    }

    // deja preparada la sentencia de actulización de estado del átomo para mejor velocidad
    oStmt = oConn.prepareStatement("UPDATE " + DB.k_job_atoms + " SET " + DB.id_status + "=" + String.valueOf(Atom.STATUS_RUNNING) + ", " + DB.dt_execution + "=? WHERE " + DB.gu_job + "=? AND " + DB.pg_atom + "=?");

    try { if (oConnection.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(20); } catch (SQLException sqle) { }
  }

  // ----------------------------------------------------------

  public void close() {
    if (null!=oStmt)
      try { oStmt.close(); } catch (SQLException sqle) { }
    oStmt = null;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get next Atom and remove it from queue</p>
   * @return Atom object instance
   * @throws SQLException
   */

  public synchronized Atom next() throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin AtomConsumer.next()");
      DebugFile.incIdent();
    }

    Atom oAtm = (Atom) oQueue.pop();

    if (oAtm!=null) {

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setTimestamp(1, new Timestamp(new Date().getTime()))");

      oStmt.setTimestamp(1, new Timestamp(new Date().getTime()));

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(2, " + oAtm.getStringNull(DB.gu_job,"null") + ")");

      // Actualizar el estado en la base de datos a Finished
      oStmt.setString(2, oAtm.getString(DB.gu_job));

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setInt(3, " + String.valueOf(oAtm.getInt(DB.pg_atom)) + ")");

      oStmt.setInt(3, oAtm.getInt(DB.pg_atom));

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

      oStmt.executeUpdate();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End AtomConsumer.next()");
    }

    return oAtm;
  } // next()

  // ----------------------------------------------------------

  public JDCConnection getConnection() {
    return oConn;
  }

} // AtomConsumer