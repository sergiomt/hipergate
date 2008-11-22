package com.knowgate.addrbook;

import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

/**
 * <p>Personal To Do List</p>
 * @author Sergio Montoro Ten
 * @version 2.0
 */


public class ToDo extends DBPersist {
  public ToDo() {
    super(DB.k_to_do, "ToDo");
  }

  public boolean store(JDCConnection oConn) throws SQLException {
    if (!AllVals.containsKey(DB.gu_to_do))
      put(DB.gu_to_do, Gadgets.generateUUID());

    return super.store(oConn);
  }

  // **********************************************************
  // Public Constants

  public static final String STATUS_PENDING = "PENDING";
  public static final String STATUS_DONE = "DONE";

  public static final short ClassId = 23;
}