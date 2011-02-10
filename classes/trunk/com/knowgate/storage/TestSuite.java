package com.knowgate.storage;

import java.sql.SQLException;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Properties;

import java.text.SimpleDateFormat;

import javax.jms.JMSException;
import javax.naming.NamingException;

import com.knowgate.berkeleydb.DBEntity;
import com.knowgate.berkeleydb.DBEnvironment;

import com.knowgate.clocial.*;

import com.knowgate.berkeleydb.DBErrorLog;

import com.knowgate.storage.RecordQueueProducer;
import com.knowgate.storage.RecordQueueConsumer;

import com.knowgate.syndication.FeedEntry;
import com.knowgate.syndication.SyndSearch;
import com.knowgate.syndication.crawler.SearchRunner;
import com.knowgate.syndication.crawler.EntrySearcher;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

public final class TestSuite {

  public static final Engine NOSQL = Engine.BERKELYDB;
  public static final String PROFILE = "extranet";
  
  public static boolean test01_WriteErrorLog() throws StorageException,InstantiationException,SQLException {
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

  public static boolean test02_WriteDomain() throws StorageException,InstantiationException,SQLException {
  	DataSource oDs = DataSourcePool.get(NOSQL,PROFILE,false);

	Domain oDom = new Domain(NOSQL);

  	Table oCn = oDs.openTable(oDom);
	oCn.truncate();

    oDom.put("nm_domain","DirectWriteTest02");
	oDom.store(oCn);

	RecordSet oCl = oCn.fetch("nm_domain", "DirectWriteTest02", 1);
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

  public static boolean test04_WriteUserAccount()
  	throws StorageException,JMSException,NamingException,InstantiationException {

	StorageManager oStMan = new StorageManager();
	RecordSet oCl = oStMan.fetch("k_domains");
	Record oRec = oCl.get(0);
	UserAccount oAcc = new 	UserAccount(NOSQL);
	oAcc.put("id_domain", oRec.getInt("id_domain"));
	oAcc.put("tx_nickname", "TestNickName");
	oAcc.put("tx_pwd", "123456");
	oAcc.put("tx_main_email", "testuser@test.com");
	oStMan.store(oAcc,true);
	return true;
  }

  public static boolean test05_WebSearch(String sTxSought)
  	throws Exception {
	StorageManager oStMan = new StorageManager();
	RecordSet oCl = oStMan.fetch("k_user_accounts");
	Record oRec = oCl.get(0);
    EntrySearcher.search(oStMan, sTxSought,oRec.getString("gu_account"), 100);
	SearchRunner oRun = new SearchRunner(sTxSought, oStMan.getProperties());
	DataSource oDts = oStMan.getDataSource();
	oRun.run(oDts);
	oStMan.free(oDts);
    return true;
  }

  public static int test06_FetchIndex(String sTxSought)
  	throws Exception {
	StorageManager oStMan = new StorageManager();
	RecordSet oRst = oStMan.fetch("k_syndentries", "tx_sought", sTxSought);
    return oRst.size();
  }

  public static boolean test07_IPInfo()
  	throws StorageException,JMSException,NamingException,InstantiationException {
	StorageManager oStMan = new StorageManager();
	IPInfo oIp = IPInfo.forHost(oStMan, "84.20.10.80");
	return true;
  }

  public static void test08_deteteSearch(String sTxSought)
  	throws Exception {
	StorageManager oStMan = new StorageManager();
	DataSource oDts = oStMan.getDataSource();
	SyndSearch oSs = new SyndSearch();
	Table oTbl = oDts.openTable(oSs);
	oSs.put("tx_sought", sTxSought);
	oSs.delete(oTbl);
	oTbl.close();
	oStMan.free(oDts);
  }

  public static void test09_rebuildIndexes()
  	throws Exception {
  	SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	StorageManager oStMan = new StorageManager();
	DataSource oDts = oStMan.getDataSource();
	Table oTbl;
	RecordSet oRst;
	SyndSearch oSs = new SyndSearch();
	oTbl = oDts.openTable(oSs);
	SearchRunner oRun = new SearchRunner("", oStMan.getProperties());
	oRst = oTbl.fetch();
	oTbl.close();
	for (Record r : oRst) {
	  oRun.setQueryString(r.getString("tx_sought"));
	  oRun.run(oDts);
	}
	oStMan.free(oDts);
  }
  
  public static void main (String[] args) throws Exception {

    // test01_WriteErrorLog();
    // test02_WriteDomain();
    // test03_WriteDomainAsync();
    // test04_WriteUserAccount();
    // test05_WebSearch("www.eoi.es");
    // test05_WebSearch("www.lapastillaroja.net");
    // test05_WebSearch("inncorpora");	
	// test07_IPInfo();
	// test08_deteteSearch("www.eoi.es");
		
	test09_rebuildIndexes();	

  }
}
