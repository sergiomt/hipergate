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

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ByteArrayInputStream;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.misc.Gadgets;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

import com.sun.syndication.feed.synd.SyndEntry;
import com.sun.syndication.feed.synd.SyndEntryImpl;

public class FeedEntry extends DBPersist {
      
  public FeedEntry() {
	super(DB.k_syndentries, "FeedEntry");
  }
  
  public SyndEntryImpl getEntry() throws IOException,ClassNotFoundException {
  	SyndEntryImpl oRetVal;
  	if (!containsKey(DB.bin_entry))
      put(DB.bin_entry, new SyndEntryImpl());
    return (SyndEntryImpl) new ObjectInputStream(new ByteArrayInputStream((byte[])get(DB.bin_entry))).readObject();
  }

  public void putEntry(SyndEntryImpl oEntry) {
  	if (oEntry.getUri()!=null) put(DB.uri_entry, oEntry.getUri());
  	if (oEntry.getAuthor()!=null) put(DB.nm_author, Gadgets.left(oEntry.getAuthor(),100));
  	if (oEntry.getTitle()!=null) put(DB.tl_entry, Gadgets.left(oEntry.getTitle(),254));
  	if (oEntry.getLink()!=null) put(DB.url_addr, Gadgets.left(oEntry.getLink(),254));
  	if (oEntry.getDescription()!=null) put(DB.de_entry, Gadgets.left(oEntry.getDescription().getValue(),1000));
  	if (oEntry.getPublishedDate()!=null) put(DB.dt_published, oEntry.getPublishedDate());
  	if (oEntry.getUpdatedDate()!=null) put(DB.dt_modified, oEntry.getUpdatedDate());
  	put(DB.bin_entry, oEntry);
  }

  public static FeedEntry store(JDCConnection oConn, int iIdDomain, String sGuWorkArea,
  							  String sIdType, String sGuFeed, String sTxQuery, Integer oInfluence,
  							  SyndEntryImpl oEntry) throws SQLException {    
    FeedEntry oFE = new FeedEntry();
    oFE.put(DB.id_domain, iIdDomain);
    oFE.put(DB.gu_workarea, sGuWorkArea);
    if (null!=sIdType ) oFE.put(DB.id_type, sIdType);
    if (null!=sGuFeed ) oFE.put(DB.gu_feed, sGuFeed);
    if (null!=sTxQuery) oFE.put(DB.tx_query, sTxQuery);
    if (null!=oInfluence) oFE.put(DB.nu_influence, oInfluence);
    oFE.putEntry(oEntry);    
    if (oFE.store(oConn))
      return oFE;
    else
      return null;
  }
  
  public static final short ClassId = 151;
}
