package com.knowgate.syndication.fetcher;

import com.knowgate.dfs.FileSystem;

import java.text.SimpleDateFormat;

import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import org.knallgrau.utils.textcat.TextCategorizer;

import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.storage.DataSource;

import com.sun.syndication.feed.synd.SyndContentImpl;
import com.sun.syndication.feed.synd.SyndEntryImpl;

public class FacebookJsonFetcher extends AbstractEntriesFetcher {

  	public FacebookJsonFetcher(DataSource oDts, String sFeedUrl, String sQueryString) {
  	  super(oDts, sFeedUrl, "facebookgraph", sQueryString, null, null);
  	}

  	public void run() {
      String sFB = "";
      try {
        sFB = new FileSystem().readfilestr(getURL(),"UTF-8");
        SimpleDateFormat oyyyyMMddT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
      
	    JSONArray oData = new JSONObject(sFB).getJSONArray("data");
	    final int nLen = oData.length();
	    for (int j=0;j<nLen; j++) {
	  	    JSONObject oJobj = oData.getJSONObject(j);
	  	  
      	    SyndEntryImpl oEntr = new SyndEntryImpl();
	  	    JSONObject oFrom = oJobj.getJSONObject("from");
	  	    oEntr.setAuthor(oFrom.getString("name"));
      	    try {
      	      oEntr.setUri("http://www.facebook.com/"+oJobj.getString("id"));
      	      oEntr.setLink("http://www.facebook.com/"+oJobj.getString("id"));
      	    } catch (JSONException idnotfound) {
      		  if (DebugFile.trace) DebugFile.writeln("JSONException id object not found");      	    	
      	    }
            oEntr.setTitle(Gadgets.left(oJobj.getString("message"),27)+"...");
      	    SyndContentImpl oScnt = new SyndContentImpl();
      	    oScnt.setType("text/plain");
      	    oScnt.setValue(oJobj.getString("message"));
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
			if (oJobj.getString("message")!=null) {
			  if (oJobj.getString("message").length()>10) {
				try {
				  sLanguage = new TextCategorizer().categorize(oJobj.getString("message"));
				} catch (Exception xcpt) {
        		  if (DebugFile.trace)
          			DebugFile.writeln(xcpt.getClass().getName()+" categorizing language "+xcpt.getMessage());
      			}
			  } // fi
			} // fi
			if (sLanguage.length()>0 && sLanguage.length()!=2) {
			  String sLangId = getLanguageCodeFromName(sLanguage, "en");
			  if (sLangId!=null) sLanguage = sLangId;
			}
      	    addEntry(createEntry(0, "", "facebook",
      	    		 null, getQueryString(), null, "", sLanguage, getAuthor(oEntr), oEntr));
	    } // next
	  }	catch (Exception xcpt) {
		if (DebugFile.trace)
		  DebugFile.writeln("FacebookJsonFetcher.run() "+xcpt.getClass().getName()+" "+xcpt.getMessage());
      }
  	} // run
}
