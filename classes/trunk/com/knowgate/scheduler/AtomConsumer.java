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
import java.util.HashMap;
import java.util.Iterator;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Timestamp;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.debug.DebugFile;

/**
 * Atom queue consumer
 * @author Sergio Montoro Ten
 * @version 5.0
 */
public class AtomConsumer {

  private AtomQueue oQueue;
  private DBBind oDbb;

  // ----------------------------------------------------------

  /**
   * <p>Create Atom Queue Consumer</p>
   * @param oConnection
   * @param oAtomQueue
   * @throws SQLException
   */
  public AtomConsumer(DBBind oDbBnd, AtomQueue oAtomQueue) throws SQLException {
    oQueue = oAtomQueue;
    oDbb = oDbBnd;
  }

  // ----------------------------------------------------------

  public DBBind getDatabaseBind() {
    return oDbb;
  }

  public void close() throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin AtomConsumer.close()");
      DebugFile.incIdent();
    }

	HashMap<String,String> oJobs = new HashMap<String,String>();

    for (Atom oAtm=oQueue.pop(); oAtm!=null; oAtm=oQueue.pop()) {
      if (!oJobs.containsKey(oAtm.getString(DB.gu_job))) {
      	oJobs.put(oAtm.getString(DB.gu_job), oAtm.getString(DB.gu_job));
      }
    } // next    

	if (oJobs.size()>0) {
      JDCConnection oConn = oDbb.getConnection("AtomConsumer.close");
      oConn.setAutoCommit(true);
      Iterator<String> oIter = oJobs.keySet().iterator();
      while (oIter.hasNext()) {
      	String sGuJob = oIter.next();
        DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_job_atoms+" SET "+DB.id_status+"="+String.valueOf(Job.STATUS_PENDING)+" WHERE "+DB.gu_job+"='"+sGuJob+"' AND "+DB.id_status+"="+String.valueOf(Atom.STATUS_RUNNING));
        DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_jobs+" SET "+DB.id_status+"="+String.valueOf(Job.STATUS_PENDING)+","+DB.dt_execution+"=NULL WHERE "+DB.gu_job+"='"+sGuJob+"'");
      } // wend
      oConn.close("AtomConsumer.close");
	} // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End AtomConsumer.close()");
    }
  } // close
  	
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

    JDCConnection oConn = null;
	PreparedStatement oStmt = null;
	
    Atom oAtm = (Atom) oQueue.pop();

    if (oAtm!=null) {
	  
	  try {
        oConn = oDbb.getConnection("AtomConsumer");
        oConn.setAutoCommit(true);

        if (DebugFile.trace) {
      	  DebugFile.writeln("Connection process id is "+oConn.pid());
          DebugFile.writeln("Connection.prepareStatement (UPDATE " + DB.k_job_atoms + " SET " + DB.id_status + "=" + String.valueOf(Atom.STATUS_RUNNING) + ", " + DB.dt_execution + "=? WHERE " + DB.gu_job + "=? AND " + DB.pg_atom + "=?)");
        }

        oStmt = oConn.prepareStatement("UPDATE " + DB.k_job_atoms + " SET " + DB.id_status + "=" + String.valueOf(Atom.STATUS_RUNNING) + ", " + DB.dt_execution + "=? WHERE " + DB.gu_job + "=? AND " + DB.pg_atom + "=?");

        try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(20); } catch (SQLException sqle) { }

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setTimestamp(1, new Timestamp(new Date().getTime()))");

        oStmt.setTimestamp(1, new Timestamp(new Date().getTime()));

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setString(2, " + oAtm.getStringNull(DB.gu_job,"null") + ")");

        // Actualizar el estado en la base de datos a Finished
        oStmt.setString(2, oAtm.getString(DB.gu_job));

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setInt(3, " + String.valueOf(oAtm.getInt(DB.pg_atom)) + ")");

        oStmt.setInt(3, oAtm.getInt(DB.pg_atom));

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

        oStmt.executeUpdate();

        if (null!=oStmt)
          try { oStmt.close(); } catch (SQLException sqle) { }
        oStmt = null;

        if (oConn!=null) oConn.close("AtomConsumer");
		oConn = null;
      } catch (SQLException sqle) {
        if (null!=oStmt)
          try { oStmt.close(); } catch (SQLException ignore) { }
        if (oConn!=null) oConn.close("AtomConsumer");
          try { oConn.close(); } catch (SQLException ignore) { }
      }
      	
	} // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End AtomConsumer.next()");
    }

    return oAtm;
  } // next()

} // AtomConsumer