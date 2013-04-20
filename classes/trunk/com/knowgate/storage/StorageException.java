package com.knowgate.storage;

public class StorageException extends Exception {

  private static final long serialVersionUID = 70000l;

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
