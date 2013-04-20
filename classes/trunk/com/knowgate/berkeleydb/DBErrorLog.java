package com.knowgate.berkeleydb;

import java.sql.Types;
import java.util.Arrays;
import java.util.LinkedList;
import javax.jms.Message;

import com.knowgate.storage.Column;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.ErrorCode;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.StorageException;

public class DBErrorLog extends DBEntity {
  
  private static final long serialVersionUID = 600000101201000111l;

  private static Column GU_ERROR = new Column("k_errors_log", "gu_error", Types.CHAR, 32, 0, false, true, null, "GUID", true, 0);
  private static Column GU_ACCOUNT = new Column("k_errors_log", "gu_account", Types.VARCHAR, 32, 0, false, true, null, null, false, 1);
  private static Column DT_CREATED = new Column("k_errors_log", "dt_created", Types.TIMESTAMP, 19, 0, false, false, null, "NOW", false, 2);
  private static Column CO_ERROR   = new Column("k_errors_log", "co_error"  , Types.INTEGER, 11, 0, false, false, null, "666", false, 3);
  private static Column BO_ACKNOWLEDGED = new Column("k_errors_log", "bo_acknowledged", Types.BOOLEAN, 5, 0, false, false, null, "false", false, 4);
  private static Column TX_MESSAGE = new Column("k_errors_log", "tx_message", Types.VARCHAR, 4000, 0, true, false, null, null, false, 5);
  private static Column JV_EXCEPTION = new Column("k_errors_log", "jv_exception", Types.JAVA_OBJECT, 2147483647, 0, true, false, null, null, false, 6);
  private static Column JV_CAUSE = new Column("k_errors_log", "jv_cause", Types.JAVA_OBJECT, 2147483647, 0, true, false, null, null, false, 7);
  private static Column JV_MESSAGE = new Column("k_errors_log", "jv_message", Types.JAVA_OBJECT, 2147483647, 0, true, false, null, null, false, 8);

  public DBErrorLog() {
  	super("k_errors_log", new LinkedList<Column>(Arrays.asList(new Column[]{GU_ERROR,GU_ACCOUNT,DT_CREATED,CO_ERROR,BO_ACKNOWLEDGED,TX_MESSAGE,JV_EXCEPTION,JV_CAUSE,JV_MESSAGE})));
  }

  public String log (DataSource oDts, ErrorCode eCode, String sUid, String sTxMsg) {
	DBTable oTbl = null;
	try {
	  oTbl = (DBTable) oDts.openTable(this);
	  put("gu_error", DBTable.createUniqueKey());
	  put("gu_account", sUid);
	  put("co_error", new Integer(eCode.intValue()));
	  put("tx_message", sTxMsg);
	  oTbl.store(this);
	  oTbl.close();
	} catch (Exception oHardXcpt) {
	  System.err.println("ErrorLog.log() "+oHardXcpt.getClass().getName()+" "+oHardXcpt.getMessage());
	}
	return getString("gu_error");
  }
  
  public String log (DataSource oDts, ErrorCode eCode, String sUid, Message oObjMsg,
  				     Exception oStorXcpt, Throwable oCauseXcpt) {
	DBTable oTbl = null;
	try {
	  oTbl = (DBTable) oDts.openTable(this);
	  put("gu_error", DBTable.createUniqueKey());
	  put("gu_account", sUid);
	  put("co_error", new Integer(eCode.intValue()));
	  if (null!=oStorXcpt) {
	    put("tx_message", oStorXcpt.getMessage());
	    put("jv_exception", oStorXcpt);
	  }
	  if (null!=oCauseXcpt) put("jv_cause", oCauseXcpt);
	  if (null!=oObjMsg) put("jv_message", oObjMsg);
	  oTbl.store(this);
	  oTbl.close();
	} catch (Exception oHardXcpt) {
	  System.err.println("ErrorLog.log() "+oHardXcpt.getClass().getName()+" "+oHardXcpt.getMessage());
	}
	return getString("gu_error");
  }

  public RecordSet forUserAccount(DataSource oDts, String sUid) throws StorageException {
    DBTable oTbl = (DBTable) oDts.openTable(this);
  	RecordSet oRst = oTbl.fetch ("gu_account",sUid);
  	oTbl.close();
  	return oRst;
  }

}
