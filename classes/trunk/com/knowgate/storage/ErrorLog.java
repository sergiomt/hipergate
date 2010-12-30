package com.knowgate.storage;

import javax.jms.Message;

public interface ErrorLog {

  public void log (DataSource oDts, ErrorCode eCode, String sUid, Message oObjMsg,
  				   Exception oStorXcpt, Throwable oCauseXcpt);

  public RecordSet forUserAccount(DataSource oDts, String sUid) throws StorageException;

}
