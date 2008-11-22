package com.knowgate.hipergate;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;

/**
 * Generic list of recently used items held at a database table
 * @author Sergio Montoro Ten
 * @version 2.0
 */

public class RecentlyUsed {

  private String sTable;
  private String sPK;
  private String sFilter;
  private String sDate;
  private int iSize;

  /**
   * <p>Open access to a recently used list.</p>
   * <p>Example: new RecentlyUsed ("k_companies_recent", 10, "gu_company", "gu_user")</p>
   * @param sBaseTable Name of database table that holds all instances of list class
   * @param iListSize Maximum items per distinct list
   * @param sPrimaryKey Primary key of the items at each list
   * @param sFilterField Field used for filtering items from an specific list
   */
  public RecentlyUsed (String sBaseTable, int iListSize, String sPrimaryKey, String sFilterField) {
    sTable = sBaseTable;
    sPK = sPrimaryKey;
    sFilter = sFilterField;
    iSize = iListSize;
    sDate = DB.dt_last_visit;
  }

  // ---------------------------------------------------------------------------

  /**
   * Clear recently used list
   * @param oConn JDBC Database Connection
   * @param oFilterValue Value for field used for filtering items from this list
   * @throws SQLException
   */
  public void clear (JDCConnection oConn, Object oFilterValue)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin RecentlyUsed.clear ([Connection]," + oFilterValue + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + sTable + " WHERE " + sFilter + "=" + oFilterValue + ")");
    }

    PreparedStatement oDlte = oConn.prepareStatement("DELETE FROM " + sTable + " WHERE " + sFilter + "=?");
    oDlte.setObject (1, oFilterValue);
    int iDeleted = oDlte.executeUpdate();
    oDlte.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RecentlyUsed.clear () : " + String.valueOf(iDeleted));
    }
  } // clear

  // ---------------------------------------------------------------------------

  /**
   * Current list size
   * @param oConn JDBC Database connection
   * @param oFilterValue Value for field used for filtering items from this list
   * @return Number of items in list
   * @throws SQLException
   */
  public int listSize (JDCConnection oConn, Object oFilterValue)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin RecentlyUsed.listSize ([Connection]," + oFilterValue + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT COUNT(" + sPK + ") FROM " + sTable + " WHERE " + sFilter + "=" +oFilterValue + ")");
    }

    PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(" + sPK + ") FROM " + sTable + " WHERE " + sFilter + "=?" , ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setObject (1, oFilterValue);
    ResultSet oRSet = oStmt.executeQuery();
    oRSet.next();
    Object oCount = oRSet.getObject(1);
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RecentlyUsed.listSize () : " + oCount);
    }

    return Integer.parseInt(oCount.toString());
  } // listSize

  // ---------------------------------------------------------------------------

  /**
   * <P>Get list items</p>
   * Items are returned ordered by last use. First the most recently used one.
   * @param oConn JDBC Database Connection
   * @param oFilterValue Value for field used for filtering items from this list
   * @return List items as a DBSubset
   * @throws SQLException
   */
  public DBSubset list (JDCConnection oConn, Object oFilterValue)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin RecentlyUsed.list ([Connection]," + oFilterValue + ")");
      DebugFile.incIdent();
    }

    DBSubset oList = new DBSubset (sTable, "*", sFilter + "=? ORDER BY " + sDate + " DESC", iSize);

    oList.load (oConn, new Object[]{oFilterValue});

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RecentlyUsed.list () : " + String.valueOf(oList.getRowCount()));
    }

    return oList;
  } // list

  // ---------------------------------------------------------------------------

  private void deleteOldest (JDCConnection oConn, Object oFilterValue)
    throws SQLException {

    Object oPK = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin RecentlyUsed.deleteOldest ([Connection]," + oFilterValue + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT " + sPK + " FROM " + sTable + " WHERE " + sFilter + "=" + oFilterValue + " ORDER BY " + sDate + ")");
    }

    PreparedStatement oStmt = oConn.prepareStatement("SELECT " + sPK + " FROM " + sTable + " WHERE " + sFilter + "=? ORDER BY " + sDate, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setObject (1, oFilterValue);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      oPK = oRSet.getObject(1);
    oRSet.close();
    oStmt.close();

    if (null!=oPK) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + sTable + " WHERE " + sPK + "=" + oPK + ")");

      PreparedStatement oDlte = oConn.prepareStatement("DELETE FROM " + sTable + " WHERE " + sPK + "=?");
      oDlte.setObject (1, oPK);
      oDlte.executeUpdate();
      oDlte.close();
    } // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RecentlyUsed.deleteOldest () : " + oPK);
    }
  } // deleteOldest

  // ---------------------------------------------------------------------------

  /**
   * <p>Add item to the list</p>
   * If list has reached its maximum allowed size then the oldest item is removed before inserting the new one
   * @param oConn JDBC Database Connection
   * @param oItem DBPersist instance containing all neccessary values for the inserted item except the access date.
   * @throws SQLException
   */
  public void add (JDCConnection oConn, DBPersist oItem)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin RecentlyUsed.add ([Connection],[DBPersist])");
      DebugFile.incIdent();
      DebugFile.writeln("filter value=" + oItem.get(sFilter));
    }

    Object oFilterValue = oItem.get(sFilter);

    if (listSize(oConn, oFilterValue) >= iSize) deleteOldest (oConn, oFilterValue);

    oItem.replace(sDate, new Timestamp (new java.util.Date().getTime()));

    oItem.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RecentlyUsed.add()");
    }
  } // add
}