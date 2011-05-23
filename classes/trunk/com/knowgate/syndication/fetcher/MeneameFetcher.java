package com.knowgate.syndication.fetcher;

import java.util.List;

import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import com.sun.syndication.io.FeedException;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.feed.synd.SyndEntry;
import com.sun.syndication.fetcher.FetcherException;
import com.sun.syndication.fetcher.impl.FeedFetcherCache;

import com.knowgate.debug.DebugFile;
import com.knowgate.syndication.fetcher.AbstractEntriesFetcher;

public class MeneameFetcher extends AbstractEntriesFetcher {
	
  	public MeneameFetcher(String sFeedUrl, String sQueryString, FeedFetcherCache oFeedsCache) {
  	  super(sFeedUrl, "meneame", sQueryString, oFeedsCache, null);
  	}

    protected Integer getInfluence(SyndEntry oEntr) {
	  List<Element> foreignMarkups = (List<Element>) oEntr.getForeignMarkup();
      for (Element foreignMarkup : foreignMarkups) {      	
        if (foreignMarkup.getNamespaceURI().equals("meneame")) {
          if (foreignMarkup.getTagName().equals("karma")) {
            if (foreignMarkup.getChildNodes().item(0).getNodeValue().length()>0)
              return new Integer(foreignMarkup.getChildNodes().item(0).getNodeValue());
          } // fi
        } // fi
      } // next
      return null;
    } // getInfluence  	

    protected String getCountry(String sUrl) {
	  return "es";
    }

    protected String getLanguage(String sUrl) {
      return "es";
    }

}
