package com.knowgate.syndication.fetcher;

import com.knowgate.dfs.FileSystem;

import java.util.Map;
import java.util.Properties;

import java.text.SimpleDateFormat;

import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import org.knallgrau.utils.textcat.TextCategorizer;

import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.storage.DataSource;

import com.knowgate.syndication.FeedEntry;

import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.feed.synd.SyndContent;
import com.sun.syndication.feed.synd.SyndContentImpl;
import com.sun.syndication.feed.synd.SyndEntry;
import com.sun.syndication.feed.synd.SyndEntryImpl;

public class FacebookJsonFetcher extends AbstractEntriesFetcher {

  	public FacebookJsonFetcher(String sFeedUrl, String sQueryString) {
  	  super(sFeedUrl, "facebookgraph", sQueryString, null, null);
  	}

  	public void run() {
      String sFB = "";
      try {
        sFB = new FileSystem().readfilestr("https://graph.facebook.com/search?limit=100&q="+Gadgets.URLEncode(getQueryString()),"UTF-8");
        SimpleDateFormat oyyyyMMddT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
      
	    JSONArray oData = new JSONObject(sFB).getJSONArray("data");
	    final int nLen = oData.length();
	    for (int j=0;j<nLen; j++) {
	  	    JSONObject oJobj = oData.getJSONObject(j);
	  	  
      	    SyndEntryImpl oEntr = new SyndEntryImpl();
	  	    JSONObject oFrom = oJobj.getJSONObject("from");
	  	    oEntr.setAuthor(oFrom.getString("name"));
      	    oEntr.setUri(oJobj.getString("link"));
      	    oEntr.setLink(oJobj.getString("link"));
            oEntr.setTitle(oJobj.getString("caption"));
      	    SyndContentImpl oScnt = new SyndContentImpl();
      	    oScnt.setType("text/plain");
      	    oScnt.setValue(oJobj.getString("description"));
      	    oEntr.setDescription(oScnt);
      	    try {
      	      oEntr.setPublishedDate(oyyyyMMddT.parse(Gadgets.substrUpTo(oJobj.getString("created_time").replace('T',' '),0,'+')));
      	      oEntr.setUpdatedDate(oyyyyMMddT.parse(Gadgets.substrUpTo(oJobj.getString("updated_time").replace('T',' '),0,'+')));
      	    } catch (Exception xcpt) {
      	    }
		    Integer iLikes = null;
      	    try {
      	  	  JSONObject oLikes = oJobj.getJSONObject("likes");
      	  	  if (null!=oLikes)
      	  	    iLikes = new Integer(oLikes.getString("count"));      	  	
      	    } catch (JSONException jxcpt) { }
			String sLanguage = "";
			if (oJobj.getString("description")!=null) {
			  if (oJobj.getString("description").length()>10) {
				try {
				  sLanguage = new TextCategorizer().categorize(oJobj.getString("description"));
				} catch (Exception xcpt) {
        		  if (DebugFile.trace)
          			DebugFile.writeln(xcpt.getClass().getName()+" categorizing language "+xcpt.getMessage());
      			}
			  } // fi
			} // fi
      	    addEntry(createEntry(0, "", "facebook",
      	    		 null, getQueryString(), null, "", sLanguage, getAuthor(oEntr), oEntr));
	    } // next
	  }	catch (Exception xcpt) {
      }
  	} // run
}
