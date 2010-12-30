package com.knowgate.storage;

public interface Transaction {

	public void begin   (Connection oConn) throws StorageException;

	public void commit  () throws StorageException;

	public void rollback() throws StorageException;
	
}
