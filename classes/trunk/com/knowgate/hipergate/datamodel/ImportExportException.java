package com.knowgate.hipergate.datamodel;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class ImportExportException extends Exception {
  
  private static final long serialVersionUID = 1l;

  public ImportExportException(String sMessage) {
    super(sMessage);
  }
  public ImportExportException(String sMessage,Throwable oCause) {
    super(sMessage,oCause);
  }
}
