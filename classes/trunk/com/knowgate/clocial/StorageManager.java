package com.knowgate.clocial;

import java.util.Properties;

import javax.jms.JMSException;
import javax.naming.NamingException;

import com.knowgate.storage.Table;
import com.knowgate.storage.Engine;
import com.knowgate.storage.Record;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.DataSourcePool;
import com.knowgate.storage.StorageException;
import com.knowgate.storage.RecordQueueProducer;

public class StorageManager {
  
  private final String PROFILE = "extranet";
  
  private RecordQueueProducer oRqp;
  private Properties oSyn = new Properties();
  
  public StorageManager()
  	throws StorageException,JMSException,NamingException,InstantiationException {
    DataSource oDts = DataSourcePool.get(Engine.DEFAULT, PROFILE, true);
	oRqp = new RecordQueueProducer(oDts.getProperties());
	if (null!=oDts) DataSourcePool.free(oDts);
	oSyn = new Properties();
    oSyn.put("synchronous","true");
  }

  public Record load(String sTableName, String sKey)
  	throws StorageException,JMSException,InstantiationException {
    Table oTbl = null;
    Record oRec= null;
    DataSource oDts = null;
    try {
      oDts = DataSourcePool.get(Engine.DEFAULT, PROFILE, true);
      oTbl = oDts.openTable(sTableName);
      oRec = oTbl.load(sKey);
      oTbl.close();
    } finally {
	  if (null!=oTbl) oTbl.close();    	
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
  
  
}
