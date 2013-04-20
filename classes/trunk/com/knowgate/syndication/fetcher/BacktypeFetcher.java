package com.knowgate.syndication.fetcher;

import java.io.IOException;
import java.io.StringBufferInputStream;

import java.net.URISyntaxException;

import java.util.ArrayList;
import java.util.Properties;

import org.jibx.runtime.IBindingFactory;
import org.jibx.runtime.BindingDirectory;
import org.jibx.runtime.JiBXException;
import org.jibx.runtime.IUnmarshallingContext;

import com.sun.syndication.io.FeedException;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.feed.synd.SyndEntry;
import com.sun.syndication.feed.synd.SyndFeedImpl;
import com.sun.syndication.feed.synd.SyndImageImpl;
import com.sun.syndication.feed.synd.SyndEntryImpl;
import com.sun.syndication.fetcher.FetcherException;

import com.knowgate.twitter.Show;
import com.knowgate.twitter.User;
import com.knowgate.twitter.Tweet;
import com.knowgate.debug.DebugFile;
import com.knowgate.dfs.HttpRequest;
import com.knowgate.misc.NameValuePair;
import com.knowgate.storage.DataSource;

import com.knowgate.syndication.fetcher.GenericFeedFetcher;


public class BacktypeFetcher extends GenericFeedFetcher {

  private int nTotalResults, iStartIndex, nItemsPerPage;
  private ArrayList<Tweet> aTweets;
  private Integer oInfluence;
  private String sLanguage;

  public BacktypeFetcher(DataSource oDts, Properties oProps) {
    this(oDts, "http://backtweets.com/search.xml", null, oProps);
  }
  	
  public BacktypeFetcher(DataSource oDts, String sFeedUrl, String sQueryString, Properties oProps) {
    super(oDts, sFeedUrl, "backtype", sQueryString, null, oProps);
    aTweets = null;
    sLanguage = null;
    oInfluence = null;
    iStartIndex=1;
    nTotalResults=0;
    nItemsPerPage=25;
  }

  protected Integer getInfluence(SyndEntry oEntr) {
    return oInfluence;
  } // getInfluence

  protected String getLanguage(String sUrl) {
    return sLanguage;
  }

  public SyndFeed retrieveFeed()
    throws IOException,FeedException,FetcherException {
	Show oShw;
	SyndFeedImpl oFeed = new SyndFeedImpl();

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin BacktypeFetcher.retrieveFeed()");
	  DebugFile.incIdent();
	  DebugFile.writeln("url is "+getURL());
	}

	HttpRequest oReq = new HttpRequest(getURL(), null, "GET",
					   new NameValuePair[]{new NameValuePair("key",getProperty("backtypekey")),
										   new NameValuePair("q",getQueryString())});
	StringBufferInputStream oInStrm = null;

	try {
	  oReq.get();
	  oInStrm = new StringBufferInputStream(oReq.src());
	} catch (URISyntaxException use) {
	  if (DebugFile.trace) {
	    DebugFile.writeln("URISyntaxException "+use.getMessage());
	    DebugFile.decIdent();
	  }
	  throw new IOException(use.getMessage(), use);	  
	}
	
	BacktypeFetcher oFtchr = null;
	
	try {
      IBindingFactory oBindFctry = BindingDirectory.getFactory(BacktypeFetcher.class);
      IUnmarshallingContext oUnmCtx = oBindFctry.createUnmarshallingContext();
      oFtchr = (BacktypeFetcher) oUnmCtx.unmarshalDocument (oInStrm, "UTF-8");
      oInStrm.close();
	} catch (JiBXException jbx) {
	  if (DebugFile.trace) {
	    DebugFile.writeln("JiBXException "+jbx.getMessage());
	    DebugFile.decIdent();
	  }
	  throw new IOException(jbx.getMessage(), jbx);	  		
	}

	aTweets = oFtchr.aTweets;
	nTotalResults = oFtchr.nTotalResults;
	iStartIndex = oFtchr.iStartIndex;
	nItemsPerPage = oFtchr.nItemsPerPage;

	if (DebugFile.trace)
	  DebugFile.writeln(String.valueOf(nTotalResults)+" tweets found");

	if (nTotalResults>0) {
	  ArrayList<SyndEntryImpl> oEntries = new ArrayList<SyndEntryImpl>(nTotalResults);
	  boolean b1st = true;
	  for (Tweet oTwt : aTweets) {
	    try {
	      oShw = new Show(oTwt.getId());
          SyndEntryImpl oEntr = new SyndEntryImpl();
	      oEntr.setAuthor(oShw.getUser().get("name"));
	      oEntr.setLink("http://twitter.com/#!/"+oShw.getUser().get("screen_name")+"/status/"+oShw.getTweet().getId());
	      oEntr.setTitle(oShw.getTweet().getString("text"));
          oEntr.setPublishedDate(oShw.getTweet().getDate("created_at"));
          oEntr.setUri("http://twitter.com/#!/"+oShw.getUser().get("screen_name")+"/status/"+oShw.getTweet().getId());	    
	      if (b1st) {
	      	b1st = false;
	      	User oTusr = oShw.getUser();
	        if (oTusr.get("friends_count").length()>0)
	          oInfluence = new Integer(oTusr.get("friends_count"));
	        if (oTusr.get("lang").length()>0)
	      	  sLanguage = oTusr.get("lang");
	        oFeed.setAuthor(oEntr.getAuthor());
	        oFeed.setEncoding("UTF-8");
	        if (null!=sLanguage) oFeed.setLanguage(sLanguage);
	        if (oTusr.get("profile_image_url")!=null) {
	          if (oTusr.get("profile_image_url").length()>0) {
	            SyndImageImpl oUsrImg = new SyndImageImpl();
	            oUsrImg.setUrl(oTusr.get("profile_image_url"));
	            oUsrImg.setLink("http://twitter.com/#!/"+oShw.getUser().get("screen_name"));
	            oUsrImg.setTitle(oTusr.get("name"));
	            oFeed.setImage(oUsrImg);
	          } // fi
	        } // fi
	      } // fi (b1st)
	    } catch (IOException xcpt) {
	      if (DebugFile.trace) {
	        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
	        DebugFile.decIdent();
	  	  }
	    }
	  } // next
	  oFeed.setEntries(oEntries);
	} // fi

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End BacktypeFetcher.retrieveFeed()");
	}
		
	return oFeed;
  } // retrieveFeed()  
}
