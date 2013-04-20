package com.knowgate.syndication.fetcher;

import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.storage.DataSource;

import com.sun.syndication.feed.synd.SyndEntry;
import com.sun.syndication.feed.synd.SyndContent;

import com.sun.syndication.fetcher.impl.FeedFetcherCache;

public class BitacorasFetcher extends GenericFeedFetcher {

  	public BitacorasFetcher(DataSource oDts, String sFeedUrl, String sQueryString, FeedFetcherCache oFeedCache) {
  	  super(oDts, sFeedUrl, "bitacoras", sQueryString, oFeedCache, null);
  	}

    protected boolean preFetch(SyndEntry oEntr) {
      try {
        if (oEntr.getContents().size()>0) {
      	  SyndContent oCnts = (SyndContent) oEntr.getContents().get(0);
      	  String sOri = Gadgets.getFirstMatchSubStr(oCnts.getValue(), "<p>Ir a <a href=\"(http|https)://[\\w\\-_]+(\\.[\\w\\-_]+)+([\\w\\-\\.,@?^=%&amp;:/~\\+#]*[\\w\\-\\@?^=%&amp;/~\\+#])?\"> anotaci");
      	  if (sOri!=null) {
      	    oEntr.setLink(Gadgets.substrBetween(sOri, "href=\"", "\""));
      	  } // fi
      	} // fi
      } catch (Exception xcpt) {
      	if (DebugFile.trace) DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
      }
      return true;
    } // preFetch

}
