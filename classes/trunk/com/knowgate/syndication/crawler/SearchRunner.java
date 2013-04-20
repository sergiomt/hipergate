/*
  Copyright (C) 2011  Know Gate S.L. All rights reserved.

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

package com.knowgate.syndication.crawler;

import java.io.IOException;
import java.io.InputStream;

import java.net.URL;


import java.util.Date;
import java.util.Map;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Properties;
import java.util.Collections;
import java.util.ListIterator;

import java.text.SimpleDateFormat;

import org.xml.sax.Attributes;
import org.xml.sax.Parser;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.xml.sax.InputSource;
import org.xml.sax.helpers.XMLReaderFactory;
import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.helpers.ParserAdapter;
import org.xml.sax.helpers.ParserFactory;

import com.knowgate.dataobjs.DB;
import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

import com.knowgate.misc.Gadgets;
import com.knowgate.misc.NameValuePair;

import com.knowgate.storage.Table;
import com.knowgate.storage.Record;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.StorageException;
import com.knowgate.storage.RecordColumnValueComparatorAsc;

import com.knowgate.clocial.UserAccountAlias;

import com.knowgate.syndication.FeedEntry;
import com.knowgate.syndication.SyndSearch;
import com.knowgate.syndication.SyndReferer;
import com.knowgate.syndication.SyndSearchRun;

import com.knowgate.syndication.fetcher.BingFetcher;
import com.knowgate.syndication.fetcher.EntriesBatch;
import com.knowgate.syndication.fetcher.MeneameFetcher;
import com.knowgate.syndication.fetcher.YahooBossFetcher;
import com.knowgate.syndication.fetcher.BitacorasFetcher;
import com.knowgate.syndication.fetcher.GenericFeedFetcher;
import com.knowgate.syndication.fetcher.TwitterJsonFetcher;
import com.knowgate.syndication.fetcher.FacebookJsonFetcher;

import org.apache.oro.text.regex.MalformedPatternException;

import com.sun.syndication.io.FeedException;
import com.sun.syndication.feed.synd.SyndContent;
import com.sun.syndication.feed.synd.SyndEntryImpl;
import com.sun.syndication.fetcher.FetcherException;

public class SearchRunner extends DefaultHandler {

  private final static int MAX_RECENT = 100;
  private final static int DEFAULT_SEARCH_REFRESH = 1200; // 20 minutes
  private final static int FASTEST_SEARCH_REFRESH = 60; // 1 minute
  private final static int SLOWEST_SEARCH_REFRESH = 1296000; // 15 days
  private final static int DELAYED_SEARCH_REFRESH = 600; // 10 minutes
  private final static int NEVER_SEARCH_REFRESH = 2147483647;

  private EntriesBatch oBatch;
  private String sQry, sDomain;
  private String sCurrentTag, sFetcherId, sFetcherUri;
  private boolean bFetcherIsEnabled;
  private Properties oEnvProps;
  private ArrayList<NameValuePair> aFetchers;

  public SearchRunner(String sTxSought, Properties oProps) {
	oEnvProps = oProps;
    aFetchers = new ArrayList<NameValuePair>(20);
	oBatch = null;
	init();
	setQueryString(sTxSought);
  }

  private void init() {
  	
    if (DebugFile.trace) DebugFile.writeln("Begin SearchRunner.init()");
    
    try {
    
      XMLReader oParser;
      Parser oSax1Parser;
    
      try {
        oParser = XMLReaderFactory.createXMLReader("org.apache.xerces.parsers.SAXParser");
      } catch (Exception e) {
        oSax1Parser = ParserFactory.makeParser("org.apache.xerces.parsers.SAXParser");
        oParser = new ParserAdapter(oSax1Parser);
      }
    
      oParser.setContentHandler(this);
    
      InputStream oInStm = getClass().getResourceAsStream("SearchRunner.xml");
      InputSource oInSrc = new InputSource(oInStm);
      oParser.parse(oInSrc);
      oInStm.close();
    
    } catch (Exception e) {
      try {
        if (DebugFile.trace) DebugFile.writeln(e.getClass().getName()+" "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
      } catch (IOException ignore) {}
    }

    if (DebugFile.trace) DebugFile.writeln("End SearchRunner.init()");
  } // 

  public void startElement(String uri, String local, String raw, Attributes attrs) throws SAXException {		
    sCurrentTag = local;
    bFetcherIsEnabled = true;
    if (local.equals("fetcher")) {
      sFetcherId = attrs.getValue("id");
      if (attrs.getValue("enabled")!=null)
      	bFetcherIsEnabled = attrs.getValue("enabled").equals("1") || attrs.getValue("enabled").equalsIgnoreCase("true") ||
      		                attrs.getValue("enabled").equalsIgnoreCase("yes") || attrs.getValue("enabled").equalsIgnoreCase("on");      
      else
      	bFetcherIsEnabled = true;
    } else if (local.equals("uri")) {
      sFetcherUri = "";
    }
  } // startElement

  public void characters(char[] ch, int start, int length) throws SAXException {
    if (sCurrentTag.equals("uri")) {
      sFetcherUri += new String(ch,start,length);
    }
  }
                	
  public void endElement(String uri, String local, String name) throws SAXException {
    if (bFetcherIsEnabled) aFetchers.add(new NameValuePair(sFetcherId,sFetcherUri));
  }

  public void setQueryString(String sTxSought) {
    sQry = sTxSought;
    try {
      URL oFind = new URL(sQry.startsWith("http://") || sQry.startsWith("https://") ? sQry : "http://"+sQry);
      if (oFind.getFile().length()==0) {
        sDomain = oFind.getHost();
		String[] aDomain = Gadgets.split(sDomain,'.');
		if (aDomain.length>1) sDomain = aDomain[aDomain.length-2] + "." + aDomain[aDomain.length-1];
      } else {
        sDomain = null;
      }
    } catch (Exception ignore) { sDomain = null; }
  }
  
  private String setURLParam1(String sUrl, String sParamValue) {
  	String sRetVal = sUrl;
  	try {
  	  sRetVal =  Gadgets.replace(sUrl,"\\x241",Gadgets.URLEncode(sParamValue));
  	} catch (MalformedPatternException neverthrown) { }
  	return sRetVal;
  }
  
  public void run(DataSource oDts)
  	throws IOException,StorageException,InstantiationException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin SearchRunner.run("+sQry+")");
      DebugFile.incIdent();
    }

  	Table oTbl = null;
  	int nNew = 0;
  	RecordColumnValueComparatorAsc oRcvc = new RecordColumnValueComparatorAsc("uri_entry");
  	long lStartMilis = new Date().getTime(), lEndMilis;
	
	oBatch = new EntriesBatch(oDts, oEnvProps);
	for (NameValuePair oNvp : aFetchers) {
	  if (oNvp.getName().equals("twittersearch")) {
	    oBatch.registerFetcher(new TwitterJsonFetcher (oDts, setURLParam1(oNvp.getValue(), sQry), sQry));
	  } else if (oNvp.getName().equals("bitacoras")) {
	    oBatch.registerFetcher(new BitacorasFetcher(oDts, setURLParam1(oNvp.getValue(), sDomain==null ? sQry : sDomain), sQry, oBatch.getFeedsCache()));	  
	  } else if (oNvp.getName().equals("facebookgraph")) {
	  	oBatch.registerFetcher(new FacebookJsonFetcher(oDts, setURLParam1(oNvp.getValue(), sQry), sQry));
	  } else if (oNvp.getName().equals("yahooboss")) {
		oBatch.registerFetcher(new YahooBossFetcher(oDts, sQry, oEnvProps));
	  } else if (oNvp.getName().startsWith("meneame")) {
		oBatch.registerFetcher(new MeneameFetcher(oDts, setURLParam1(oNvp.getValue(), sQry), sQry, oBatch.getFeedsCache()));
	  } else if (oNvp.getName().startsWith("bingsearch")) {
		oBatch.registerFetcher(new BingFetcher(oDts, sQry, oEnvProps));
	  } else {
		oBatch.registerFetcher(new GenericFeedFetcher (oDts, setURLParam1(oNvp.getValue(), sQry), oNvp.getName(), sQry, oBatch.getFeedsCache(), oEnvProps));
	  }
	} // next

    oBatch.mapReduce();
    
	ArrayList<SyndReferer> aReferences = new ArrayList<SyndReferer>();

    try {

	  // *********************************************************
	  // Store a singleton for query string at k_syndsearches table

  	  SyndSearch oSs = new SyndSearch(oDts,Gadgets.left(sQry, 254), new Date(), 0, null, 0, 0);
  	  oTbl = oDts.openTable(oSs);
      if (!oTbl.exists(sQry)) oSs.store(oTbl);
  	  oTbl.close();
  	  oTbl=null;

	  // ********************************************************
	  // Get all entries found for current query at previous runs
	  FeedEntry oFe = new FeedEntry(oDts);
  	  oTbl = oDts.openTable(oFe);
	  RecordSet oRst = oTbl.fetch("tx_sought", sQry);
	  oTbl.close();
	  oTbl=null;

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(oRst.size())+" previous entries exists");
	
	  oRst.sort("uri_entry");

	  Map<String,FeedEntry> oCache = oBatch.entries();
	  
	  // *********************************************************************
	  // For each fetched entry check if it was already at k_syndentries table
	  for (Object oOntr : oCache.values()) {
        FeedEntry oFntr = (FeedEntry) oOntr;
        int iRec = Collections.binarySearch(oRst, oFntr, (Comparator) oRcvc);
      	if (iRec>=0) {
      	   // If this entry was already indexed then get its former primary key
      	  oFntr.put("id_syndentry", oRst.get(iRec).get("id_syndentry"));
      	} else {
      	   // If this is a completely new entry, increment the new entries counter
      	   // and add the reference to the target URL for given query string      	  
      	  nNew++;
      	  if (!oFntr.isNull(DB.url_domain))
      	    aReferences.add(new SyndReferer(oDts, sQry, oFntr.getString(DB.url_domain)));
      	}
      } // next (feed)

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(nNew)+" new entries found");
          
	  Date dtNow = new Date();

	  // **************************************
	  // Add new entries to k_syndentries table

  	  oTbl = oDts.openTable(oFe);
	  for (Object oOntr : oCache.values()) {
        FeedEntry oFntr = (FeedEntry) oOntr;
        // Always try to associate a user account to each feed entry
        if (oFntr.isEmpty("nm_service") || oFntr.isEmpty("nm_alias") ||
        	Gadgets.search (new String[] {"admin","anonymous","anonimo","editorial"}, oFntr.getString("nm_alias","").toLowerCase())>=0) {
          oFntr.remove("id_acalias");
          oFntr.remove("nm_alias");
        }
        if (oFntr.isEmpty(DB.gu_account) && !oFntr.isEmpty("nm_service") && !oFntr.isEmpty("nm_alias")) {
          String sAccId = UserAccountAlias.getUserAccountId(oDts, oFntr.getString("nm_service"), oFntr.getString("nm_alias"));
          oFntr.put(DB.gu_account, sAccId);
        }
        oFntr.store(oTbl);
	  } // next
      oRst = oTbl.fetch("tx_sought_by_date", sQry+"%");
      oTbl.close();
      oTbl=null;

	  oBatch.close();
	  oBatch=null;

	  final int nResults = oRst.size();
	  
      if (DebugFile.trace) DebugFile.writeln(String.valueOf(nResults)+" total entries after update");

	  // ************************************
	  // Add referers to k_syndreferers table

	  oTbl = oDts.openTable(new SyndReferer(oDts,null,null));
	  for (SyndReferer r : aReferences) {
		Record s = oTbl.load(r.getString(DB.id_syndref));
		if (null!=s)
		  r.put(DB.nu_entries, s.getInt(DB.nu_entries)+1);
		r.store(oTbl);
	  } // next
      oTbl.close();
      oTbl=null;

	  // *****************************************************
	  // Update total results and times run for query string &
	  // kept latests result formatted into an cached XML CLOB
	  SyndSearch oSyS = new SyndSearch(oDts, sQry, dtNow, 1, null, 0, nResults);	
  	  oTbl = oDts.openTable(oSyS);
	  Record oRyS = oTbl.load(sQry);
	  int nReRunAfter;
	  if (oRyS==null) {
	  	nReRunAfter = DEFAULT_SEARCH_REFRESH;
	  } else {
	    oSyS.put("nu_runs", oRyS.getInt("nu_runs")+1);
	    if (oRyS.isNull("nu_rerun_after_secs"))
		  nReRunAfter = DEFAULT_SEARCH_REFRESH;
		else
	      nReRunAfter = oRyS.getInt("nu_rerun_after_secs");
	  } // fi
	  if (nReRunAfter==NEVER_SEARCH_REFRESH) {
	    oSyS.remove("dt_next_run");
	  } else {
	    if (nNew==0) {
	  	  if (nReRunAfter<SLOWEST_SEARCH_REFRESH) nReRunAfter += DELAYED_SEARCH_REFRESH;
	    } else {
	  	  if (nReRunAfter>FASTEST_SEARCH_REFRESH) nReRunAfter /= 2;
	  	  if (nReRunAfter>FASTEST_SEARCH_REFRESH) nReRunAfter = FASTEST_SEARCH_REFRESH;	  	
	    } // fi
	    oSyS.put("dt_next_run", new Date(dtNow.getTime()+(long) nReRunAfter));
	  } // fi
	  oSyS.put("dt_last_run", dtNow);
	  oSyS.put("nu_rerun_after_secs", nReRunAfter);
	  oSyS.put("nu_results", nResults);
	  oSyS.put("xml_recent", recordSetToXML(oRst, oEnvProps.getProperty("shortdate", "yyyy-MM-dd"), MAX_RECENT, 0));
	  oSyS.store(oTbl);
	  oTbl.close();
	  oTbl=null;
	  
	  lEndMilis = new Date().getTime();

      if (DebugFile.trace) DebugFile.writeln("Batch took "+String.valueOf(lEndMilis-lStartMilis)+" to execute");

	  // ******************************
	  // Write an audit log of this run
	  SyndSearchRun oRun = new SyndSearchRun(oDts, sQry, dtNow,
										    (int) (lEndMilis-lStartMilis),nNew);
  	  oTbl = oDts.openTable(oRun);
  	  oRun.store(oTbl);
  	  oTbl.close();

  	} catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt));
      }  		
  	  
  	  if (oTbl!=null) {
  	  	try { oTbl.close(); } catch (Exception ignore) { }
  	    throw new StorageException(xcpt.getMessage(), xcpt);
  	  }
  	}

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SearchRunner.run()");
    }
  } // run
  	
  private static String hlink(final String sIn) {
    String sHIn = sIn;
    try {
      String sUrl = Gadgets.getFirstMatchSubStr(sIn, "(http|https)://[\\w\\-_]+(\\.[\\w\\-_]+)+([\\w\\-\\.,@?^=%&amp;:/~\\+#]*[\\w\\-\\@?^=%&amp;/~\\+#])?");
      String sHref = Gadgets.getFirstMatchSubStr(sIn, "(href|HREF)\\s*=\\s*(\"|')(http|https)://[\\w\\-_]+(\\.[\\w\\-_]+)+([\\w\\-\\.,@?^=%&amp;:/~\\+#]*[\\w\\-\\@?^=%&amp;/~\\+#])?(\"|')");
      if (sUrl!=null && sHref==null) {
        sHIn = Gadgets.replace(sIn, Gadgets.escapeChars(sUrl, "*?()[]-+\\",'\\'), "<a href=\""+sUrl+"\"></a>");
      }
      String sTwit = Gadgets.getFirstMatchSubStr(sHIn, "( |RT)@\\w+( |:)");
      if (sTwit!=null) {
        sHIn = Gadgets.replace(sHIn, sTwit, "<a href=\"http://twitter.com/"+sTwit.trim()+"\"></a>");    
      }
    } catch (Exception xcpt) {
      if (DebugFile.trace) DebugFile.writeln(xcpt.getClass().getName()+" at hlink("+sIn+")"+xcpt.getMessage());
    }
    return sHIn;
  }

  public static String recordToXML(Record r, SimpleDateFormat oFmt) {
    StringBuffer oBuffer = new StringBuffer(8000);
    try {
	  oBuffer.append("<syndentry id=\""+r.get("id_syndentry")+"\">");
	  oBuffer.append("<uri_entry>");
	  oBuffer.append(Gadgets.replace(Gadgets.XMLEncode(r.getString("uri_entry")),"\"","%22").replace('\n',' '));
	  oBuffer.append("</uri_entry>");
	  oBuffer.append("<id_type>");
	  oBuffer.append(r.getString("id_type",""));
	  oBuffer.append("</id_type>");
	  oBuffer.append("<id_country>");
	  String sCountryId = r.getString("id_country","");
	  oBuffer.append(sCountryId.equals("xx") ? "" : sCountryId);
	  oBuffer.append("</id_country>");
	  oBuffer.append("<dt_run>");
	  if (!r.isNull("dt_run")) oBuffer.append(oFmt.format(r.getDate("dt_run")).replace(' ','T'));
	  oBuffer.append("</dt_run>");
	  oBuffer.append("<dt_published>");
	  if (!r.isNull("dt_published"))
	  	oBuffer.append(oFmt.format(r.getDate("dt_published")).replace(' ','T'));
	  oBuffer.append("</dt_published>");	  
	  oBuffer.append("<dt_modified>");
	  if (!r.isNull("dt_modified"))
	  	oBuffer.append(oFmt.format(r.getDate("dt_modified")).replace(' ','T'));
	  oBuffer.append("</dt_modified>");
	  oBuffer.append("<gu_contact>");
	  oBuffer.append(r.getString("gu_contact",""));
	  oBuffer.append("</gu_contact>");
	  oBuffer.append("<nm_author><![CDATA[");
	  if (Gadgets.hasXssSignature(r.getString("nm_author","")))
	    oBuffer.append(Gadgets.XMLEncode(Gadgets.HTMLDencode(r.getString("nm_author",""))).replace('\n',' '));
	  else
	    oBuffer.append(Gadgets.HTMLDencode(r.getString("nm_author","")).replace('\n',' '));
	  oBuffer.append("]]></nm_author>");
	  oBuffer.append("<url_author>");
	  oBuffer.append(Gadgets.replace(Gadgets.XMLEncode(r.getString("url_author","")),"\"","%22").replace('\n',' '));
	  oBuffer.append("</url_author>");
	  oBuffer.append("<nu_influence>");
	  if (!r.isNull("nu_influence")) oBuffer.append(r.getInteger("nu_influence").toString());
	  oBuffer.append("</nu_influence>");
	  oBuffer.append("<nu_relevance>");
	  if (!r.isNull("nu_relevance")) oBuffer.append(r.get("nu_relevance").toString());
	  oBuffer.append("</nu_relevance>");
	  oBuffer.append("<tl_entry><![CDATA[");
	  if (Gadgets.hasXssSignature(r.getString("tl_entry","")))
	    oBuffer.append(Gadgets.XMLEncode(Gadgets.HTMLDencode(r.getString("tl_entry",""))).replace('\n',' '));
	  else
	    oBuffer.append(Gadgets.HTMLDencode(hlink(r.getString("tl_entry","")).replace('\n',' ')));
	  oBuffer.append("]]></tl_entry>");
	  oBuffer.append("<de_entry><![CDATA[");
	  if (Gadgets.hasXssSignature(r.getString("de_entry","")))
	    oBuffer.append(Gadgets.XMLEncode(Gadgets.HTMLDencode(r.getString("de_entry",""))).replace('\n',' '));
	  else
	    oBuffer.append(Gadgets.HTMLDencode(hlink(r.getString("de_entry","")).replace('\n',' ')));
	  oBuffer.append("]]></de_entry>");
	  oBuffer.append("<url_addr>");
	  oBuffer.append(Gadgets.replace(Gadgets.XMLEncode(r.getString("url_addr","")),"\"","%22").replace('\n',' '));
	  oBuffer.append("</url_addr>");
	  oBuffer.append("<url_domain>");
	  oBuffer.append(Gadgets.replace(Gadgets.XMLEncode(r.getString("url_domain","")),"\"","%22").replace('\n',' '));
	  oBuffer.append("</url_domain>");
	  oBuffer.append("<tx_content><![CDATA[");
	  try {
	    SyndEntryImpl oEntry = (SyndEntryImpl) r.get(DB.bin_entry);
	    if (oEntry.getContents().size()>0) oBuffer.append(((SyndContent)oEntry.getContents().get(0)).getValue());
	  } catch (Exception xcpt) {	  
	    if (DebugFile.trace) DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage()+" at entry "+r.get("id_syndentry"));
	  }	  
	  oBuffer.append("]]></tx_content>");
	  oBuffer.append("</syndentry>");
	} catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) { }
	return oBuffer.toString();
  } // recordToXML

  public static String recordSetToXML(RecordSet oRst, String sDateFormat, int iMaxResults, int iOffset)
  	throws StorageException,InstantiationException,FeedException,FetcherException,IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin SearchRunner.recordSetToXML([RecordSet], "+sDateFormat+", "+String.valueOf(iMaxResults)+", "+String.valueOf(iOffset)+")");
      DebugFile.incIdent();
    }

	int iWritten,iSkipped;
    StringBuffer oBuffer = new StringBuffer(64000);
    SimpleDateFormat oFmt = new SimpleDateFormat(sDateFormat==null ? "yyyy-MM-dd" : sDateFormat);
	oBuffer.append("<syndentries count=\""+String.valueOf(oRst.size()<iMaxResults ? oRst.size() : iMaxResults)+"\">");
    ListIterator<Record> oIter = oRst.listIterator(oRst.size());
    for (iSkipped=0; oIter.hasPrevious() && iSkipped<iOffset; iSkipped++) oIter.previous();
	for (iWritten=0; oIter.hasPrevious() && iWritten<iMaxResults; iWritten++) {
	  oBuffer.append(SearchRunner.recordToXML(oIter.previous(), oFmt));
	} // next
	oBuffer.append("</syndentries>");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SearchRunner.recordSetToXML() : "+String.valueOf(iWritten));
    }

    return oBuffer.toString();
  }
	
}
