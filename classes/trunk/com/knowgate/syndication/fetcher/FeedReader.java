package com.knowgate.syndication.fetcher;

import java.io.IOException;

import java.net.URL;

import com.sun.syndication.io.FeedException;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.fetcher.FetcherException;
import com.sun.syndication.fetcher.impl.DiskFeedInfoCache;
import com.sun.syndication.fetcher.impl.HttpURLFeedFetcher;

public class FeedReader {
  
  private DiskFeedInfoCache oDche;
  
  public FeedReader(String sDiskCachePath) {
  	oDche = new DiskFeedInfoCache(sDiskCachePath);
  }
  
  public SyndFeed retrieveFeed(String sUrl)
  	throws FeedException,FetcherException,IOException {
  	HttpURLFeedFetcher oFtchr = new HttpURLFeedFetcher(oDche);
  	return oFtchr.retrieveFeed(new URL(sUrl));
  }
  
  
}
