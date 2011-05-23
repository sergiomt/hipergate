package com.knowgate.storage;

import java.sql.SQLException;

public class StorageException extends Exception {

  private ErrorCode eErrCod;

  public StorageException (String sMessage) {
  	super(sMessage);
  }

  public StorageException (String sMessage, Throwable oCause) {
  	super(sMessage, oCause);
  }

  public StorageException (String sMessage, ErrorCode eCode, Throwable oCause) {
  	super(sMessage, oCause);
  	eErrCod = eCode;
  }

}