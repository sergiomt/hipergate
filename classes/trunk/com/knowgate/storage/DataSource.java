package com.knowgate.storage;

import java.util.Properties;

public interface DataSource {

	public void open (String sRepositoryName, boolean bReadOnly) throws StorageException;

	public void close() throws StorageException;

    public boolean isReadOnly();

	public boolean isClosed();

	public Table openTable(Record oRec) throws StorageException;

	public Table openTable(String sName) throws StorageException;

	public Table openTable(String sName, String[] sIndexes) throws StorageException;

	public Table openTable(Properties oConnectionProperties) throws StorageException;

    public String getName();
  
    public String getProperty(String sVariableName);

    public Properties getProperties();

    public Engine getEngine();

}
