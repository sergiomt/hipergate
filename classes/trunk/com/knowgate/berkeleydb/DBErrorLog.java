package com.knowgate.berkeleydb;

import java.sql.Types;
import java.util.Arrays;
import java.util.ArrayList;
import javax.jms.Message;

import com.knowgate.storage.Column;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.ErrorLog;
import com.knowgate.storage.ErrorCode;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.StorageException;

public class DBErrorLog extends DBEntity {
  
  private static final long serialVersionUID = 600000101201000111l;

  private static Column GU_ERROR = new Column(0, "gu_error", Types.CHAR, 32, false, true, null, "GUID", true);
  private static Column GU_ACCOUNT = new Column(1, "gu_account", Types.VARCHAR, 32, false, true, null, null, false);
  private static Column DT_CREATED = new Column(2, "dt_created", Types.TIMESTAMP, 19, false, false, null, "NOW", false);
  private static Column CO_ERROR   = new Column(3, "co_error"  , Types.INTEGER, 11, false, false, null, "666", false);
  private static Column BO_ACKNOWLEDGED = new Column(4, "bo_acknowledged", Types.BOOLEAN, 5, false, false, null, "false", false);
  private static Column TX_MESSAGE = new Column(5, "tx_message", Types.VARCHAR, 4000, true, false, null, null, false);
  private static Column JV_EXCEPTION = new Column(6, "jv_exception", Types.JAVA_OBJECT, 2147483647, true, false, null, null, false);
  private static Column JV_CAUSE = new Column(7, "jv_cause", Types.JAVA_OBJECT, 2147483647, true, false, null, null, false);
  private static Column JV_MESSAGE = new Column(8, "jv_message", Types.JAVA_OBJECT, 2147483647, true, false, null, null, false);

  public DBErrorLog() {
  	super("k_errors_log", new ArrayList<Column>(Arrays.asList(new Column[]{GU_ERROR,GU_ACCOUNT,DT_CREATED,CO_ERROR,BO_ACKNOWLEDGED,TX_MESSAGE,JV_EXCEPTION,JV_CAUSE,JV_MESSAGE})));
  }

  public String log (DataSource oDts, ErrorCode eCode, String sUid, String sTxMsg) {
	DBTable oTbl = null;
	try {
	  oTbl = (DBTable) oDts.openTable(this);
	  put("gu_error", oTbl.createUniqueKey());
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
	  put("gu_error", oTbl.createUniqueKey());
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
