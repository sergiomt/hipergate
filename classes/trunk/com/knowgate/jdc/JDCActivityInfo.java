package com.knowgate.jdc;

import java.util.ArrayList;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;

/**
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public class JDCActivityInfo {

  private JDCProcessInfo[] aProcessInfo = null;

  private void pgSqlActivity(Connection oConn) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    ArrayList aStats = new ArrayList();
    oStmt = oConn.createStatement();
    oRSet = oStmt.executeQuery("SELECT datid,datname,procpid,usesysid,usename,current_query,query_start FROM pg_stat_activity");
    while (oRSet.next()) {
      aStats.add (new JDCProcessInfo(oRSet.getString(1),oRSet.getString(2),
                                     oRSet.getString(3),oRSet.getString(4),
                                     oRSet.getString(5),oRSet.getString(6),
                                     oRSet.getDate(7)));
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
  }

  public JDCActivityInfo(JDCConnection oConn) throws SQLException {
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      pgSqlActivity(oConn);
    } // fi
  }

  public JDCActivityInfo(JDCConnectionPool oPool)
    throws SQLException,ClassNotFoundException {
    //Class.forName("org.postgresql.Driver");
    //Connection oConn = DriverManager.getConnection("jdbc:postgresql://127.0.0.1:5432/econtainers2r","sa","laifee3B");
    JDCConnection oConn = oPool.getConnection("activity_info");
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      pgSqlActivity(oConn);
    } // fi
    oConn.close();
  }

  public JDCProcessInfo[] processesInfo() {
    return aProcessInfo;
  }

}
