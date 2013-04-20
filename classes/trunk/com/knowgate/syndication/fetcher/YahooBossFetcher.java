package com.knowgate.syndication.fetcher;


import java.util.Properties;

import java.text.SimpleDateFormat;

import com.knowgate.debug.DebugFile;
import com.knowgate.storage.DataSource;

import com.knowgate.yahoo.Boss;
import com.knowgate.yahoo.Result;
import com.knowgate.yahoo.YSearchResponse;

import com.sun.syndication.feed.synd.SyndContentImpl;
import com.sun.syndication.feed.synd.SyndEntryImpl;

public class YahooBossFetcher extends AbstractEntriesFetcher {
	
  	public YahooBossFetcher(DataSource oDts, String sQueryString, Properties oProps) {
  	  super(oDts, "", "yahooboss", sQueryString, null, oProps);
  	}

  	public void run() {
	  try {
        SimpleDateFormat oyyyyMMdd = new SimpleDateFormat("yyyy/MM/dd");
        Boss oYb = new Boss();
        YSearchResponse oYr = oYb.search(getProperty("yahoobosskey"), getQueryString(), null);
        final int ny = oYr.count();
        for (int y=0; y<ny; y++) {
      	  Result oYbr = oYr.results(y);
      	  String sYrl = oYbr.url;
      	  SyndEntryImpl oEntr = new SyndEntryImpl();
      	  oEntr.setUri(sYrl);
      	  oEntr.setLink(sYrl);
      	  oEntr.setTitle(oYbr.title);
      	  SyndContentImpl oScnt = new SyndContentImpl();
      	  oScnt.setType("text/plain");
      	  oScnt.setValue(oYbr.abstrct);
      	  oEntr.setDescription(oScnt);
      	  try {
      	  	  oEntr.setPublishedDate(oyyyyMMdd.parse(oYbr.date));
      	  	  oEntr.setUpdatedDate(oyyyyMMdd.parse(oYbr.date));
      	  } catch (Exception xcpt) { }

	      if (preFetch(oEntr)) {
      	    addEntry(createEntry(0, "", "yahoo", null, getQueryString(), null, getCountry(sYrl), getLanguage(sYrl), getAuthor(oEntr), oEntr));
		  }
        } // next      
	  } catch (Exception xcpt) {
	  	if (DebugFile.trace) {
	  	  DebugFile.writeln("YahooBossFetcher.run() "+xcpt.getClass().getName()+" "+xcpt.getMessage());
	  	}
	  }
  	} // run
}
