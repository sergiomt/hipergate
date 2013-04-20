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

import java.util.Properties;
import java.util.ListIterator;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.storage.DataSource;

import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.feed.synd.SyndEntryImpl;

import com.sun.syndication.fetcher.impl.FeedFetcherCache;

public class GenericFeedFetcher extends AbstractEntriesFetcher {

  	public GenericFeedFetcher(DataSource oDts, String sFeedUrl, String sFeedSourceType, String sQueryString,
  							  FeedFetcherCache oFeedsCache, Properties oEnvProps) {
  	  super(oDts, sFeedUrl, sFeedSourceType, sQueryString, oFeedsCache, oEnvProps);
  	}

	private String getUriDesc(String sUri, SyndEntryImpl oEntr) {
	  if (sUri==null)
	  	if (oEntr.getDescription()==null)
	  	  return "";
	  	else
	  	  return oEntr.getDescription().getValue();
	  else
	  	if (sUri.startsWith("http://") || sUri.startsWith("https://"))
	  	  return sUri;
	  	else
	  	  if (oEntr.getDescription()==null)
	  	    return "";
	  	  else
	  	    return oEntr.getDescription().getValue();	  	
	}
	
  	public void run() {

      if (DebugFile.trace) {
        DebugFile.writeln("Begin GenericFeedFetcher.run("+getSourceType()+")");
	    DebugFile.incIdent();
	  }

  	  int nFetched = 0;

	  try {
		if (DebugFile.trace) DebugFile.writeln("retrieveFeed("+getURL()+")");
  	    SyndFeed oFeed = retrieveFeed();
	    ListIterator oIter = oFeed.getEntries().listIterator();
        while (oIter.hasNext()) {
          SyndEntryImpl oEntr = (SyndEntryImpl) oIter.next();
          String sUri = oEntr.getUri();

       	  if (DebugFile.trace) DebugFile.writeln("fetching "+sUri);

	      if (DebugFile.trace) {
		    DebugFile.writeln("Fetched "+oEntr.getLink()+" from "+getSourceType()+" for query string "+getQueryString());
		  }

      	  if (preFetch(oEntr)) {
      	      nFetched++;
      	      addEntry(createEntry(0, "", getSourceType(), null,
      	        	   getQueryString(), getInfluence(oEntr),
					   getCountry(oEntr.getLink()),
					   getLanguage(getUriDesc(oEntr.getLink(),oEntr)),
					   getAuthor(oEntr), oEntr) );
      	  } // fi
        } // wend
  	    
	  } catch (Exception xcpt) {
        if (DebugFile.trace)          
          DebugFile.writeln("GenericFeedFetcher.run("+getSourceType()+") "+xcpt.getClass().getName()+" "+xcpt.getMessage()+" "+getQueryString());
	      try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (Exception ignore) {}
	  }	  

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End GenericFeedFetcher.run("+getSourceType()+") : "+String.valueOf(nFetched));
	  }
  	} // run
} // GenericFeedFetcher
