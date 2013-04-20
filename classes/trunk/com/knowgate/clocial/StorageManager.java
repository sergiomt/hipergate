package com.knowgate.clocial;

import java.sql.SQLException;

import java.util.Properties;

import javax.jms.JMSException;
import javax.naming.NamingException;

import com.knowgate.storage.Table;
import com.knowgate.storage.Engine;
import com.knowgate.storage.Record;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.DataSourcePool;
import com.knowgate.storage.StorageException;

import com.knowgate.jmsqueue.JMSQueueProducer;
import com.knowgate.misc.Environment;

public class StorageManager {
  
  private final String PROFILE = "extranet";
  
  private JMSQueueProducer oRqp;
  private Properties oSyn = new Properties();
  
  public StorageManager()
  	throws StorageException,JMSException,NamingException,InstantiationException {
  	MetaData oMDat = MetaData.getDefaultSchema();
    DataSource oDts = DataSourcePool.get(Engine.DEFAULT, PROFILE, true);
	oRqp = new JMSQueueProducer(Environment.getProfile(PROFILE));
	if (null!=oDts) DataSourcePool.free(oDts);
	oSyn = new Properties();
    oSyn.put("synchronous","true");
  }

  public Properties getProperties()  {
    return Environment.getProfile(PROFILE);
  }

  public DataSource getDataSource() throws StorageException,InstantiationException {
    return DataSourcePool.get(Engine.DEFAULT, PROFILE, false);
  }

  public void free(DataSource oDts) throws StorageException {
  	if (null!=oDts) DataSourcePool.free(oDts);    	
  }

  public boolean exists(String sTableName, String sKey)
  	throws StorageException,InstantiationException {
    Table oTbl = null;
    boolean bRetVal = false;
    DataSource oDts = null;
    try {
      oDts = DataSourcePool.get(Engine.DEFAULT, PROFILE, true);
      oTbl = oDts.openTable(sTableName);
      bRetVal = oTbl.exists(sKey);
	  try { oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    } finally {
	  try { if (null!=oTbl) oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
	  if (null!=oDts) DataSourcePool.free(oDts);    	
    }
    return bRetVal;
  }

  public Record load(String sTableName, String sKey)
  	throws StorageException,InstantiationException {
    Table oTbl = null;
    Record oRec= null;
    DataSource oDts = null;
    try {
      oDts = DataSourcePool.get(Engine.DEFAULT, PROFILE, true);
      oTbl = oDts.openTable(sTableName);
      oRec = oTbl.load(sKey);
	  try { oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    } finally {
	  try { if (null!=oTbl) oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
	  if (null!=oDts) DataSourcePool.free(oDts);    	
    }
    return oRec;
  }
  
  public void store(Record oRec, boolean bSynchronous)
  	throws StorageException,JMSException,InstantiationException {
  	if (bSynchronous)
	  oRqp.store(oRec, oSyn);
	else
	  oRqp.store(oRec);		
  }

  public RecordSet fetch(String sTableName)
  	throws StorageException,JMSException,InstantiationException {
    Table oTbl = null;
    RecordSet oRst= null;
    DataSource oDts = null;
    try {
      oDts = DataSourcePool.get(Engine.DEFAULT, PROFILE, true);
      oTbl = oDts.openTable(sTableName);
      oRst = oTbl.fetch();
	  try { oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    } finally {
	  try { if (null!=oTbl) oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
	  if (null!=oDts) DataSourcePool.free(oDts);    	
    }
    return oRst;	
  }
  
  public RecordSet fetch(String sTableName, String sIndexColumn, String sIndexValue)
  	throws StorageException,JMSException,InstantiationException {
    Table oTbl = null;
    RecordSet oRst= null;
    DataSource oDts = null;
    try {
      oDts = DataSourcePool.get(Engine.DEFAULT, PROFILE, true);
      oTbl = oDts.openTable(sTableName, new String[] {sIndexColumn});
      oRst = oTbl.fetch(sIndexColumn, sIndexValue);
	  try { oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    } finally {
	  try { if (null!=oTbl) oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
	  if (null!=oDts) DataSourcePool.free(oDts);    	
    }
    return oRst;	
  }
  
}
