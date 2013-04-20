package com.knowgate.syndication.crawler;

import java.util.Date;
import java.util.Properties;
import java.util.ListIterator;
import java.util.concurrent.ConcurrentLinkedQueue;

import com.knowgate.storage.Table;
import com.knowgate.storage.Record;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.DataSource;

import com.knowgate.clocial.StorageManager;
import com.knowgate.syndication.SyndSearch;
import com.knowgate.syndication.crawler.SearchRunner;

public class SearchDaemon {

  private static ConcurrentLinkedQueue<String> oQueuedSearches = new ConcurrentLinkedQueue<String>();

  public static void main (String[] aForceResearch) throws Exception {
  	StorageManager oStMan = new StorageManager();

	Date dtNow = new Date();
  	DataSource oDts = null;
  	Table oTbl = null;
  	RecordSet oQue;
  	ListIterator<Record> oIter;

    Properties oProps = oStMan.getProperties();
    oProps.put("shortdate","dd/MM/yyyy");  
	if (aForceResearch!=null) {
      oDts = oStMan.getDataSource();
      for (int s=0; s<aForceResearch.length; s++) {
	    new SearchRunner(aForceResearch[s], oProps).run(oDts);
	  }
      oStMan.free(oDts);
	} // fi
	
	try {
	  if (aForceResearch==null) {
	    oDts = oStMan.getDataSource();
	    oTbl = oDts.openTable(new SyndSearch(oDts));
	    oQue = oTbl.fetch("dt_next_run", "IS NULL");
	    oIter = oQue.listIterator();
	    while (oIter.hasNext()) {
		  Record oRec = oIter.next();
		  oRec.put("dt_next_run", dtNow);
		  oRec.store(oTbl);
	    } // wend
	    oTbl.close();
	    oTbl = oDts.openTable(new SyndSearch(oDts));
	    oQue = oTbl.fetch("dt_next_run", null, dtNow);
	    oIter = oQue.listIterator();
	    while (oIter.hasNext()) {
	      oQueuedSearches.add(oIter.next().getString("tx_sought"));
	    } // wend
	    oTbl.close();
	    oTbl = null;
	    SearchRunner oRunner = new SearchRunner("",oStMan.getProperties());
	    while (!oQueuedSearches.isEmpty()) {
	      oRunner.setQueryString(oQueuedSearches.poll());
	      oRunner.run(oDts);
	    } // wend
	    oStMan.free(oDts);
	    oDts = null;
	  } // fi
	} finally {
	  if (oTbl!=null) oTbl.close();
	  if (oDts!=null) oStMan.free(oDts);
	}
  }
}
