/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.

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

import java.io.IOException;

import java.net.URL;

import com.sun.syndication.io.FeedException;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.fetcher.FetcherException;
import com.sun.syndication.fetcher.impl.FeedFetcherCache;
import com.sun.syndication.fetcher.impl.HttpURLFeedFetcher;
// import com.sun.syndication.fetcher.impl.DiskFeedInfoCache;

import com.knowgate.debug.DebugFile;

/**
 * Read an RSS feed using disk storage for caching feed info
 * @author Sergio Montoro Ten
 * @version 6.0
 */
public class FeedReader {
  
  private FeedFetcherCache oDche;
  
  /**
   * Constructor
   * @param sDiskCachePath String Full path to directory where cached feed info will be stored
   **/
  public FeedReader(FeedFetcherCache oFeedFetchCache) {
  	oDche = oFeedFetchCache;
  }
  
  /**
   * Read feed from a URL
   * @param sUrl String Feed source URL
   * @throws IOException
   * @throws FeedException
   * @throws FetcherException
   */
  public SyndFeed retrieveFeed(String sUrl)
  	throws FeedException,FetcherException,IOException {
  	if (DebugFile.trace) DebugFile.writeln("Begin FeedReader.retrieveFeed("+sUrl+")");
  	HttpURLFeedFetcher oFtchr = new HttpURLFeedFetcher(oDche);
  	SyndFeed oFeed = oFtchr.retrieveFeed(new URL(sUrl));  	
  	if (DebugFile.trace) DebugFile.writeln("End FeedReader.retrieveFeed() : " + (oFeed==null ? "0" : String.valueOf(oFeed.getEntries().size())));
  	return oFeed;
  }
}
