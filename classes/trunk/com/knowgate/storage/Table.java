/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

package com.knowgate.storage;

import java.sql.SQLException;

import java.util.Date;
import java.util.LinkedList;

import com.knowgate.storage.Column;
import com.knowgate.storage.Record;
import com.knowgate.storage.AbstractRecord;
import com.knowgate.storage.RecordSet;

import com.knowgate.misc.NameValuePair;

public interface Table {

  public String getName();

  public LinkedList<Column> columns();

  public DataSource getDataSource();
  
  public void close() throws SQLException,StorageException;

  public boolean exists(String sKey) throws StorageException;

  public Record load(String sKey) throws StorageException;

  public Record load(Object[] aKey) throws StorageException;

  public Record newRecord() throws StorageException;
  
  public void store(AbstractRecord oRec) throws StorageException;

  public void delete(AbstractRecord oRec) throws StorageException;

  public void delete(final String sIndexColumn, final String sIndexValue) throws StorageException;

  public void dropIndex(final String sIndexColumn) throws StorageException;

  public RecordSet fetch() throws StorageException;

  public RecordSet fetch(final int iMaxRows, final int iOffset) throws StorageException;

  public RecordSet fetch(final String sIndexColumn, String sIndexValue) throws StorageException;

  public RecordSet fetch(final String sIndexColumn, String sIndexValueMin, String sIndexValueMax) throws StorageException;

  public RecordSet fetch(final String sIndexColumn, Date dtIndexValueMin, Date dtIndexValueMax) throws StorageException;

  public RecordSet fetch(final String sIndexColumn, String sIndexValue, final int iMaxRows) throws StorageException;

  public RecordSet fetch(NameValuePair[] aPairs, final int iMaxRows) throws StorageException;

  public RecordSet last(final String sOrderByColumn, final int iMaxRows, final int iOffset) throws StorageException;

  public void truncate() throws StorageException;

}
