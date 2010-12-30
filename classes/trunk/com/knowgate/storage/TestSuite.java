package com.knowgate.storage;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Properties;

import javax.jms.JMSException;
import javax.naming.NamingException;

import com.knowgate.berkeleydb.DBEntity;
import com.knowgate.berkeleydb.DBEnvironment;

import com.knowgate.clocial.*;

import com.knowgate.berkeleydb.DBErrorLog;

import com.knowgate.storage.RecordQueueProducer;
import com.knowgate.storage.RecordQueueConsumer;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

public final class TestSuite {

  public static final Engine NOSQL = Engine.BERKELYDB;
  public static final String PROFILE = "extranet";
  
  public static boolean test01_WriteErrorLog() throws StorageException,InstantiationException {
  	DataSource oDs = DataSourcePool.get(NOSQL,PROFILE,false);

    Record oELog = new DBErrorLog();

	Table oCn = oDs.openTable("k_errors_log", new String[]{"gu_error"});

	oCn.truncate();

	String sGuError = ((DBErrorLog)oELog).log(oDs, ErrorCode.SUCCESS, "UUIDGUID", "Prueba ELog");
	
	oELog = oCn.load(sGuError);
	
	oCn.close();
	oDs.close();  

	System.out.println("Write/Read ErrorLog test returned "+String.valueOf(oELog!=null));

	return oELog!=null;
  }

  public static boolean test02_WriteDomain() throws StorageException,InstantiationException {
  	DataSource oDs = DataSourcePool.get(NOSQL,PROFILE,false);

	Domain oDom = new Domain(NOSQL);

  	Table oCn = oDs.openTable(oDom);
	oCn.truncate();

    oDom.put("nm_domain","DirectWriteTest02");
	oDom.store(oCn);

	RecordSet oCl = oCn.fetch("nm_domain", "QueuedTest01", 1);
	Record oRec = oCl.get(0);

	System.out.println("Fetch domain by name returned "+String.valueOf(oRec!=null));

	oCl = oCn.fetch("id_domain", oDom.getString("id_domain"), 1);
	oRec = oCl.get(0);

	System.out.println("Fetch domain by id returned "+String.valueOf(oRec!=null));

	oRec = oCn.load(oDom.getString("id_domain"));
	
	System.out.println("Write/Read Domain test returned "+String.valueOf(oDom!=null));

	oCn.close();
	oDs.close();  

	return oDom!=null;
  }

  public static boolean test03_WriteDomainAsync()
  	throws StorageException,JMSException,NamingException,InstantiationException {
	Domain oDom = new Domain(NOSQL);
	StorageManager oStMan = new StorageManager();
    oDom.put("nm_domain","QueuedWriteTest03");
	oStMan.store(oDom, true);
	return true;
  }
  
  public static void main (String[] args) throws Exception {

    // test01_WriteErrorLog();
    // test02_WriteDomain();
    test03_WriteDomainAsync();

    if (true) return;
    
  	DataSource oDs = DataSourcePool.get(NOSQL,"extranet",true);
	RecordSet oCl;
	Table oCn;

    Properties oStorProps = new Properties();
    oStorProps.put("synchronous","true");
    oStorProps.put("useraccount","sysadmin");


    RecordQueueProducer oRqp = new RecordQueueProducer("ClocialQueueConnectionFactory",
   												       "ClocialQueue", "C:/Temp", "admin", "admin");
    
	Record oDom = new Domain(NOSQL);

  	oCn = oDs.openTable(oDom);
	oCn.truncate();
	oCn.close();

    oDom.put("nm_domain","QueuedTest01");
    
	oRqp.store(oDom,oStorProps);
	
	oCn = oDs.openTable(oDom);
	oCl = oCn.fetch("nm_domain", "QueuedTest01", 1);
	oDom = oCl.get(0);
	oCn.close();
	
	System.out.println("Domain "+oDom.get("id_domain")+" readed");

	oCn = oDs.openTable(oDom);
	oDom = oCn.load(oDom.getString("id_domain"));
	oCn.close();

	System.out.println("Domain "+oDom.get("id_domain")+" readed twice");
	
    HashMap<String,Record> oRecs = MetaData.getDefaultSchema().getRecords();
    
	UserAccount u = new UserAccount(NOSQL);
  	oCn = oDs.openTable(u);
  	oCl = oCn.fetch();
    for (Record r : oCl) {
      System.out.println(r.toString());
    }
    oCn.close();
    DataSourcePool.free(oDs);
    oDs.close();

	Company k = new Company(NOSQL);

  	oDs = DataSourcePool.get(NOSQL,"extranet",false);
  	oCn = oDs.openTable(k);
	oCn.truncate();
  	oCl = oCn.fetch();
    System.out.println("Reset found "+oCl.size());
	oCn.close();
    DataSourcePool.free(oDs);
	
    Properties oPrps = new Properties();
    oPrps.setProperty("synchronous","true");

	
	k = new Company(NOSQL);
	k.put("id_domain", oDom.getInteger("id_domain")); 
	k.put("id_country", "es");
	k.put("nm_legal", "AAA Corp.");
	k.put("nm_commercial", "AAA");
  	oRqp.store(k,oPrps);

	k = new Company(NOSQL);
	k.put("id_domain", oDom.getInteger("id_domain")); 
	k.put("id_country", "es");
	k.put("nm_legal", "ACME Corp.");
	k.put("nm_commercial", "ACME");
  	oRqp.store(k,oPrps);
  	
	k = new Company(NOSQL);
	k.put("id_domain", oDom.getInteger("id_domain")); 
	k.put("id_country", "es");
	k.put("nm_legal", "ACID Corp.");
	k.put("nm_commercial", "ACID");
  	oRqp.store(k,oPrps);

	k = new Company(NOSQL);
	k.put("id_domain", oDom.getInteger("id_domain")); 
	k.put("id_country", "es");
	k.put("nm_legal", "ACID Corp.");
	k.put("nm_commercial", "ACID 2");
  	oRqp.store(k,oPrps);
  	
	k = new Company(NOSQL);
	k.put("id_domain", oDom.getInteger("id_domain")); 
	k.put("id_country", "es");
	k.put("nm_legal", "ACCUA Corp.");
	k.put("nm_commercial", "ACCUA");
  	oRqp.store(k,oPrps);

	k = new Company(NOSQL);
	k.put("id_domain", oDom.getInteger("id_domain")); 
	k.put("id_country", "es");
	k.put("nm_legal", "3M Corp.");
	k.put("nm_commercial", "3M");
  	oRqp.store(k,oPrps);

	oRqp.stop(false,10000);

  	oDs = DataSourcePool.get(NOSQL,"extranet",false);
  	oCn = oDs.openTable(k);
    
  	oCl = oCn.fetch();
    System.out.println("All found "+oCl.size());

  	oCl = oCn.fetch();
    for (Record r : oCl) {
      System.out.println(r.toString());
    }

  	oCl = oCn.fetch("nm_ascii", Gadgets.ASCIIEncode("ACID Corp."));
    System.out.println("ACID Corp. found "+oCl.size());
    for (Record r : oCl) {
      System.out.println(r.toString());
    }

  	oCn.close();

    oCl = Company.fetchLike(oDs, "AC", "es", 20);
    System.out.println("AC Companies found "+oCl.size());
    for (Record r : oCl) {
      System.out.println(r.toString());
    }
    
    DataSourcePool.free(oDs);

  }
}
