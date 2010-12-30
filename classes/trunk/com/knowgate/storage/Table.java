package com.knowgate.storage;

import java.text.NumberFormat;
import java.text.SimpleDateFormat;

import java.util.Date;
import java.util.Collection;

import com.knowgate.storage.Record;
import com.knowgate.storage.AbstractRecord;
import com.knowgate.storage.RecordSet;

public interface Table {

  public String getName();

  public DataSource getDataSource();
  
  public void close() throws StorageException;

  public boolean exists(String sKey) throws StorageException;

  public Record load(String sKey) throws StorageException;

  public void store(AbstractRecord oRec) throws StorageException;

  public void store(AbstractRecord oRec, Transaction oTrans) throws StorageException;

  public void delete(AbstractRecord oRec) throws StorageException;

  public void delete(final String sIndexColumn, final String sIndexValue) throws StorageException;

  public void dropIndex(final String sIndexColumn) throws StorageException;

  public RecordSet fetch() throws StorageException;

  public RecordSet fetch(final String sIndexColumn, String sIndexValue) throws StorageException;

  public RecordSet fetch(final String sIndexColumn, String sIndexValueMin, String sIndexValueMax) throws StorageException;

  public RecordSet fetch(final String sIndexColumn, Date dtIndexValueMin, Date dtIndexValueMax) throws StorageException;

  public RecordSet fetch(final String sIndexColumn, String sIndexValue, final int iMaxRows) throws StorageException;

  public RecordSet last(int iRows) throws StorageException;

  public void truncate() throws StorageException;

}
