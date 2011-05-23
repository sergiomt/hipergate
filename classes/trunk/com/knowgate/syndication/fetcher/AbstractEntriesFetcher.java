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

package com.knowgate.syndication.fetcher;

import java.io.File;
import java.io.InputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.ObjectInputStream;
import java.io.ByteArrayInputStream;

import java.net.URL;
import java.net.HttpURLConnection;
import java.net.URISyntaxException;

import java.util.Date;
import java.util.ArrayList;
import java.util.Properties;

import javax.jms.JMSException;
import javax.naming.NamingException;

import org.knallgrau.utils.textcat.TextCategorizer;

import com.knowgate.clocial.IPInfo;
import com.knowgate.clocial.StorageManager;
import com.knowgate.clocial.UserAccountAlias;

import com.knowgate.dataobjs.DB;
import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.FileSystem;
import com.knowgate.dfs.HttpRequest;
import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

import com.knowgate.dfs.HttpRequest;
import com.knowgate.storage.Engine;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.StorageException;
import com.knowgate.syndication.FeedEntry;
import com.knowgate.twitter.Show;

import com.sun.syndication.io.FeedException;

import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.feed.synd.SyndEntry;
import com.sun.syndication.feed.synd.SyndEntryImpl;

import com.sun.syndication.fetcher.FetcherException;
import com.sun.syndication.fetcher.impl.FeedFetcherCache;

/**
 * <p>Abstract base class for threads that search for URLs
 * or RSS feed entries given a query string.</p>
 * Derived classes must override run() method inherited from the Thread parent class.
 * 
 */
 
public abstract class AbstractEntriesFetcher extends Thread {

  	private String sUrl;
  	private String sSrc;
  	private String sQry;
  	// private EntriesBatch oBtc;
	private Properties oPrp;
	private ArrayList<FeedEntry> aEnt;
	private FeedFetcherCache oFfc;

    private static StorageManager oStm = null;	

  	public AbstractEntriesFetcher(String sFeedUrl, String sFeedSourceType, String sQueryString,
  								  FeedFetcherCache oFeedsCache, Properties oEnvProps) {
  	  if (sFeedUrl==null)
  	    sUrl = null;
  	  else
  	  	sUrl = sFeedUrl.trim();
  	  sSrc = sFeedSourceType;
  	  sQry = sQueryString;
  	  oFfc = oFeedsCache;
  	  oPrp = oEnvProps;
  	  aEnt = new ArrayList<FeedEntry>();
  	  init();
  	}

	/**
	 * Initialize the storage manager
	 */
    private void init() {
      if (oStm==null) {
      	try {
      	  oStm = new StorageManager();
      	} catch (InstantiationException oIE) {
          if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.init() InstantiationException "+oIE.getMessage());
          throw new NullPointerException("InstantiationException Could not instantiate StorageManager "+oIE.getMessage());      	  
      	} catch (NamingException oNE) {
          if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.init() NamingException "+oNE.getMessage());
          throw new NullPointerException("NamingException Could not instantiate StorageManager "+oNE.getMessage());      	  
      	} catch (JMSException oJE) {
          if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.init() JMSException "+oJE.getMessage());
          throw new NullPointerException("JMSException Could not instantiate StorageManager "+oJE.getMessage());      	  
      	} catch (StorageException oSE) {
          if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.init() StorageException "+oSE.getMessage());
          throw new NullPointerException("StorageException Could not instantiate StorageManager "+oSE.getMessage());      	  
      	}
      }
    } // init
    
    protected String getAuthor(SyndEntry oEntr) {
  	  String sAuthor = oEntr.getAuthor();
  	  if (null==sAuthor) sAuthor = "";
  	  String sAuthorMatch = null;

      if (DebugFile.trace) {
      	DebugFile.writeln("Begin AbstractEntriesFetcher.getAuthor()");
        DebugFile.incIdent();
      	DebugFile.writeln("SyndEntry.getAuthor() = \""+sAuthor+"\"");
      }
            
	  if (sAuthor.length()==0) {
  	    if (oEntr.getLink()!=null) {
  	      if (oEntr.getLink().length()>0)
  	        sAuthorMatch = AuthorGuessing.extractAuthorFromURL(oEntr.getLink());
  	    }	  	
	  } else {
	    sAuthorMatch = oEntr.getAuthor();
	  }
  	
  	  if (sAuthorMatch==null) {
	    try { sAuthorMatch = new URL(oEntr.getLink()).getHost();
	    } catch (Exception ignore) { sAuthorMatch = "permalink"; }
  	  }

      if (DebugFile.trace) {
        DebugFile.decIdent();
      	DebugFile.writeln("End AbstractEntriesFetcher.getAuthor() : "+sAuthorMatch);
      }

      return sAuthorMatch;
    } // getAuthor

	protected String getTitleOf(String sPageUrl)
	  throws IOException,URISyntaxException {
	  return new HttpRequest(sPageUrl).getTitle();
	}

	protected String getURL() {
	  return sUrl;
	}

	protected String getQueryString() {
	  return sQry;
	}

    public SyndFeed retrieveFeed()
      throws IOException,FeedException,FetcherException {
  	  FeedReader oFrdr = new FeedReader(oFfc); 
  	  return oFrdr.retrieveFeed(sUrl);
    }

    public String getProperty(String sProp) {
  	  return oPrp.getProperty(sProp);
    }

    /**
     * Create FeedEntry and set several attributes of it from a single method call
     * @param eEng Engine to be used for storage
     * @param iIdDomain int Domain unique Id. to which the SyndEntry will be associated
     * @param sGuWorkArea String Work Area GUID to which the SyndEntry will be associated, may be <b>null</b>
     * @param sIdType String Entry type or source "backtype" "twingly" etc.
     * @param sTxQuery String Optional query string passed when generating the feed
     * @param oInfluence Integer Optional user influence
     * @param oEntry SyndEntryImpl SyndEntry object to be stored
     * @throws StorageException
     */
    protected FeedEntry createEntry(int iIdDomain, String sGuWorkArea, String sIdType,
  				   			String sGuFeed, String sTxQuery, Integer oInfluence, String sCountryId, String sLangId,
  				   			String sAuthor, SyndEntryImpl oEntry) throws StorageException {

  	  DataSource oDts = null;
  	  FeedEntry oFey = null;

  	  try {
  	    oDts = oStm.getDataSource();
  	    oFey = new FeedEntry(oDts);
  	  } catch (InstantiationException ie) {
  	  	throw new StorageException(ie.getMessage(),ie);
  	  } finally {
  	  	oStm.free(oDts);
  	  }

      oFey.put(DB.id_domain, iIdDomain);
      oFey.put(DB.gu_workarea, sGuWorkArea);
      oFey.put(DB.dt_run, new Date());
      if (null!=sIdType ) oFey.put(DB.id_type, sIdType);
      if (null!=sGuFeed ) oFey.put(DB.gu_feed, sGuFeed);
      if (null!=sCountryId) oFey.put(DB.id_country, sCountryId);
      if (null!=sLangId) oFey.put(DB.id_language, sLangId);
      if (null!=sAuthor) oFey.put(DB.nm_author, Gadgets.left(sAuthor,100));
	  if (null!=sIdType && null!=sAuthor) {
	    oFey.put(DB.nm_service, sIdType);
	    oFey.put(DB.nm_alias, Gadgets.left(sAuthor,100));
	    oFey.put(DB.id_acalias, sIdType.toLowerCase()+":"+Gadgets.left(sAuthor,100).toLowerCase());
	  }
      if (null!=sTxQuery) {
        oFey.put(DB.tx_sought, sTxQuery);
	    oFey.put(DB.tx_query , sTxQuery);
      }
      if (null!=oInfluence) oFey.put(DB.nu_influence, oInfluence);
      oFey.putEntry(oEntry);
      
      return oFey;
    } // createEntry

	public String getSourceType() {
	  return sSrc;
	}
		
	public boolean isOfType(String sSrcType) {
	  return sSrc.equals(sSrcType);
	}
	
  	public void addEntry(FeedEntry oEnt) {
	  aEnt.add(oEnt);
  	}

  	public ArrayList<FeedEntry> entries() {
	  return aEnt;
  	}

    protected String getCountry(String sUrl) {
      String sCountryId = null;
      DataSource oDts = null;
      try {
      	oDts = oStm.getDataSource();
        IPInfo oIPInf = IPInfo.forUrl(oDts, sUrl);
		oStm.free(oDts);
		oDts = null;
        sCountryId = oIPInf.getString("id_country");
      } catch (Exception xcpt) {
      	try { if (oDts!=null) oStm.free(oDts); } catch (Exception ignore) {}
      }
      if (DebugFile.trace) DebugFile.writeln("origin country of "+sUrl+" is "+sCountryId);
	  return sCountryId;
    }

    protected String getLanguage(String sUrl) {
      String sLanguage = "";      
      try {
        if (sUrl.startsWith("http://") || sUrl.startsWith("https://")) {
          if (sUrl.startsWith("http://twitter.com/") &&
          	  (sUrl.indexOf("/status/")>0 || sUrl.indexOf("/statuses/")>0)) {
		    sLanguage = new TextCategorizer().categorize(new Show(sUrl.substring(sUrl.lastIndexOf('/')+1)).getTweet().getString("text"));
          } else {
      	    sLanguage = new HttpRequest(sUrl).getLanguage();
          }
        } else {
		  sLanguage = new TextCategorizer().categorize(sUrl);
		}
      } catch (Exception xcpt) {
        if (DebugFile.trace) {
          DebugFile.writeln(xcpt.getClass().getName()+" getting language for "+sUrl+" "+xcpt.getMessage());
          // try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (Exception ignore) { }
        }
      }      
      return sLanguage;
    }

    protected boolean preFetch(SyndEntry oEntr) {
	  boolean bOK;
      boolean bIsAutoReference;
      try {
        bIsAutoReference =  new URL(oEntr.getLink()).getHost().equalsIgnoreCase(new URL(getQueryString().startsWith("http://") ? getQueryString() : "http://"+getQueryString()).getHost());
      } catch (Exception ignore) { bIsAutoReference = false; }
	  if (bIsAutoReference) {
	    bOK = false;
	  } else {
        try {
		  HttpRequest oReq = new HttpRequest(oEntr.getLink());
		  int iRespCode = oReq.head();
	      bOK = (iRespCode!=HttpURLConnection.HTTP_BAD_GATEWAY &&
	      	     iRespCode!=HttpURLConnection.HTTP_BAD_METHOD &&
	    	     iRespCode!=HttpURLConnection.HTTP_BAD_REQUEST &&
	    	     iRespCode!=HttpURLConnection.HTTP_FORBIDDEN &&
	    	     iRespCode!=HttpURLConnection.HTTP_INTERNAL_ERROR &&
	    	     iRespCode!=HttpURLConnection.HTTP_NOT_FOUND &&
	    	     iRespCode!=HttpURLConnection.HTTP_SERVER_ERROR &&
	    	     iRespCode!=HttpURLConnection.HTTP_UNAUTHORIZED &&
	    	     iRespCode!=HttpURLConnection.HTTP_UNAVAILABLE);
        } catch (Exception ignore) { bOK = true; }
	  }
	  return bOK;
    } // preFetch

    protected Integer getInfluence(SyndEntry oEntr) {
      return null;
    } // getInfluence  	

}
