/*
  Copyright (C) 2010  Know Gate S.L. All rights reserved.

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

package com.knowgate.syndication;

import java.net.URL;

import java.io.IOException;

import java.util.Date;

import com.knowgate.dataobjs.DB;
import com.knowgate.misc.Gadgets;

import com.knowgate.debug.DebugFile;
import com.sun.syndication.feed.synd.SyndEntryImpl;

import com.knowgate.clocial.Serials;

import com.knowgate.storage.DataSource;
import com.knowgate.storage.Engine;
import com.knowgate.storage.RecordDelegator;
import com.knowgate.storage.StorageException;
import com.knowgate.storage.Table;

/**
 * Store a SyndEntry object at either a RDBMS or a NoSQL engine
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class FeedEntry extends RecordDelegator {

  public static final short ClassId = 151;

  private static final long serialVersionUID = Serials.SyndEntry;
  
  private static final String tableName = DB.k_syndentries;
  
  private static final int MAX_URL_LENGTH = 254;

  public FeedEntry(DataSource oDts) throws InstantiationException {
  	super(oDts, tableName);
  }
  
  public SyndEntryImpl getEntry() throws IOException,ClassNotFoundException {
  	if (!containsKey(DB.bin_entry))
      put(DB.bin_entry, new SyndEntryImpl());
    return (SyndEntryImpl) get(DB.bin_entry);
  }

  public String getURL() {
    return getString(DB.url_addr,"");
  }

  public void putEntry(SyndEntryImpl oEntry) throws IllegalArgumentException {

	if (DebugFile.trace) DebugFile.writeln("FeedEntry.putEntry([SyndEntryImpl])");

  	if (oEntry.getTitle()!=null) put(DB.tl_entry, Gadgets.left(oEntry.getTitle(),254));
	  	
  	if (oEntry.getUri()!=null) put(DB.uri_entry, oEntry.getUri());
  	      	
  	if (oEntry.getLink()!=null) {

  	  put(DB.url_addr, Gadgets.left(oEntry.getLink(), MAX_URL_LENGTH));

  	  try {
  	  	String[] aHost = Gadgets.split(new URL(oEntry.getLink()).getHost(),'.');
		if (aHost.length==1)
  	      put(DB.url_domain, Gadgets.left(aHost[0],100));						
		else
  	      put(DB.url_domain, Gadgets.left(aHost[aHost.length-2]+"."+aHost[aHost.length-1],100));
  	    if (getString(DB.url_domain,"").endsWith(".es")) put(DB.id_country, "es");						
  	  } catch (Exception ignore) { }

  	  if (oEntry.getLink().startsWith("http://twitter.com/")) {
  	  	String sUrlAuthor = null;
  	  	if (oEntry.getLink().indexOf("/statuses/")>0)
  	  	  sUrlAuthor = Gadgets.substrUpTo(oEntry.getLink(),0,"/statuses/");
  	  	else if (oEntry.getLink().indexOf("/status/")>0)
  	  	  sUrlAuthor = Gadgets.substrUpTo(oEntry.getLink(),0,"/status/");
		if (sUrlAuthor==null) sUrlAuthor = oEntry.getLink();
		else if (sUrlAuthor.length()==0) sUrlAuthor = oEntry.getLink();
  	      put(DB.url_author, sUrlAuthor);		
  	  } // Twitter

  	} // getLink()
  	
  	if (oEntry.getDescription()!=null) put(DB.de_entry, Gadgets.left(oEntry.getDescription().getValue(),1000));
  	if (oEntry.getPublishedDate()==null)
  	  if (oEntry.getUpdatedDate()!=null)
  	  	put(DB.dt_published, oEntry.getUpdatedDate());
  	  else
  	    put(DB.dt_published, new Date());
  	else
  	  put(DB.dt_published, oEntry.getPublishedDate());
  	if (oEntry.getUpdatedDate()!=null) put(DB.dt_modified, oEntry.getUpdatedDate());
  	put(DB.bin_entry, oEntry);
  } // putEntry
  
  public String store(Table oTbl) throws StorageException {
	DataSource oDts = oTbl.getDataSource();
	if (oDts.getEngine().equals(Engine.JDBCRDBMS)) {
	  if (isNull("id_syndentry"))
		put ("id_syndentry", oDts.nextVal("seq_"+DB.k_syndentries));
	}
	return super.store(oTbl);
  }    
}
