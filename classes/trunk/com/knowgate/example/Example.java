package com.knowgate.example;

import java.sql.SQLException;
import java.sql.Timestamp;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

/**
 * <p>Example</p>
 * An example of how to create a DBPersist subclass for managing
 * load and store of single registers from a table
 * @author Sergio Montoro Ten
 * @version 4.0
 */

public class Example extends DBPersist {

  /**
   * Create empty Example instance
   */
  public Example() {
    super("k_examples", // table name
          "Example"     // class name
         );
  }

  /**
   * Create Example instance and load its data from database
   * @param oConn Database Connection
   * @param sGuExmpl GUID of Example to be loaded
   * @throws SQLException
   */

  public Example(JDCConnection oConn, String sGuExmpl) throws SQLException {
    this();
    load(oConn, new Object[]{sGuExmpl});
  }

  /**
   * <p>Store Example data at database</p>
   * Values for gu_example and dt_modified columns are automatically assigned if not present
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {

	// *** Debug Traces
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin Example.store(JDCConnection)");
	  DebugFile.incIdent();
	} // ***
    
    if (isNull("gu_example")) // If object has no GUID then assign one automatically

      put ("gu_example", Gadgets.generateUUID());

    else // Update last modified date stamp

      replace ("dt_modified", new Timestamp(DBBind.getTime()));

	boolean bRetVal = super.store (oConn);

	// *** Debug Traces
	if (DebugFile.trace) {
	  DebugFile.writeln("End Example.store() : " + String.valueOf(bRetVal));
	  DebugFile.decIdent();
	} // ***

    return bRetVal;
  } // store()

  // **********************************************************
  // Public Constants

  public static final short ClassId = 666; // Value at k_classes table

} // Example

