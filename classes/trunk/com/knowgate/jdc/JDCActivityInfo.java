package com.knowgate.jdc;

import java.util.ArrayList;
import java.util.Date;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;

/**
 * @author Sergio Montoro Ten
 * @version 5.5
 */
public class JDCActivityInfo {

  private JDCProcessInfo[] aProcessInfo = null;
  private JDCLockConflict[] aLocksInfo = null;

  private void pgSqlActivity(Connection oConn) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    ArrayList aStats;
    String sSlct;	
    aStats = new ArrayList();
    oStmt = oConn.createStatement();
    sSlct = "SELECT datid,datname,procpid,usesysid,usename,current_query,query_start FROM pg_stat_activity";
    oRSet = oStmt.executeQuery(sSlct+" WHERE current_query NOT LIKE '"+sSlct+"%'");
    while (oRSet.next()) {
      aStats.add (new JDCProcessInfo(oRSet.getString(1),oRSet.getString(2),
                                     oRSet.getString(3),oRSet.getString(4),
                                     oRSet.getString(5),oRSet.getString(6),
                                     new Date(oRSet.getTimestamp(7).getTime())));
    } // wend
    oRSet.close();
    oStmt.close();
    final int nProcs = aStats.size();
    if (nProcs>0) {
      aProcessInfo = new JDCProcessInfo[nProcs];
      for (int p=0; p<nProcs; p++) {
        aProcessInfo[p] = (JDCProcessInfo) aStats.get(p);
      } // next
    } // fi

    aStats = new ArrayList();
    oStmt = oConn.createStatement();
    oRSet = oStmt.executeQuery("SELECT pid,waitingonpid,query,waitingonquery FROM v_querylockwait");
    while (oRSet.next()) {
      aStats.add (new JDCLockConflict(oRSet.getInt(1),oRSet.getInt(2),
                                     oRSet.getString(3),oRSet.getString(4)));
    } // wend
    oRSet.close();
    oStmt.close();
    final int nLocks = aStats.size();
    if (nLocks>0) {
      aLocksInfo = new JDCLockConflict[nLocks];
      for (int l=0; l<nLocks; l++) {
        aLocksInfo[l] = (JDCLockConflict) aStats.get(l);
      } // next
    } // fi
  } // pgSqlActivity

  public JDCActivityInfo(JDCConnection oConn) throws SQLException {
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      pgSqlActivity(oConn);
    } // fi
  }

  public JDCActivityInfo(JDCConnectionPool oPool)
    throws SQLException,ClassNotFoundException {
    JDCConnection oConn = oPool.getConnection("activity_info");
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      pgSqlActivity(oConn);
    } // fi
    oConn.close("activity_info");
  }

  public JDCProcessInfo[] processesInfo() {
    return aProcessInfo;
  }

  public JDCLockConflict[] lockConflictsInfo() {
    return aLocksInfo;
  }

}
