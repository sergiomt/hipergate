package com.knowgate.storage;

import com.knowgate.storage.Record;
import com.knowgate.storage.RecordSet;

public interface Connection {

  public DataSource getDataSource();
  
  public void close() throws StorageException;

  public Record loadRecord(String sKey) throws StorageException;

  public void storeRecord(Record oRec) throws StorageException;

  public void storeRecord(Record oRec, Transaction oTrans) throws StorageException;

  public RecordSet loadRecordSet(String sIndexName, String sIndexValue) throws StorageException;

}
