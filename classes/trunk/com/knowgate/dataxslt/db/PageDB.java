/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

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

package com.knowgate.dataxslt.db;

import java.io.IOException;
import java.io.FileNotFoundException;

import java.net.MalformedURLException;

import java.sql.SQLException;

import com.knowgate.dataxslt.Page;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dfs.FileSystem;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

public class PageDB extends DBPersist {

  public PageDB() {
    super(DB.k_pageset_pages, "PageDB");
  }

  // ----------------------------------------------------------

  public PageSetDB getPageSetDB(JDCConnection oConn) throws SQLException {
  	return new PageSetDB(oConn, getString(DB.gu_pageset));
  }

  // ----------------------------------------------------------

  public Page getPage(JDCConnection oConn, String sBasePath) throws SQLException,ClassNotFoundException,Exception {
  	return new PageSetDB(oConn, getString(DB.gu_pageset)).getPageSet(oConn,sBasePath).page(getString(DB.gu_page));
  }

  // ----------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_page))
      put(DB.gu_page, Gadgets.generateUUID());

    replace(DB.dt_modified, dtNow);

    return super.store(oConn);
  } // store

  // ----------------------------------------------------------

  public boolean publish() throws NullPointerException,MalformedURLException,
  							      IOException,FileNotFoundException,Exception {
  	if (isNull(DB.path_page))
  	  throw new NullPointerException("PageDB.publish() value for column path_page is null");
  	if (isNull(DB.path_publish))
  	  throw new NullPointerException("PageDB.publish() value for column path_publish is null");

	String sSourceUri = getString(DB.path_page);
	if (!sSourceUri.startsWith("file://") &&
		!sSourceUri.startsWith("ftp://" ) && !sSourceUri.startsWith("ftps://" ) &&
		!sSourceUri.startsWith("http://") && !sSourceUri.startsWith("https://")) {
	  sSourceUri = "file://" + sSourceUri;
	}
	String sTargetUri = getString(DB.path_publish);
	if (!sTargetUri.startsWith("file://") &&
		!sTargetUri.startsWith("ftp://" ) && !sTargetUri.startsWith("ftps://" ) &&
		!sTargetUri.startsWith("http://") && !sTargetUri.startsWith("https://")) {
	  sTargetUri = "file://" + sTargetUri;
	}
	
  	FileSystem oFs = new FileSystem();
	if (!oFs.exists(sSourceUri)) {
	  throw new FileNotFoundException("PageDB.publish() file not found "+getString(DB.path_page));
	}
	return oFs.copy(sSourceUri, sTargetUri);
  } // publish
  	
  // **********************************************************
  // * Variables estáticas

  public static final short ClassId = 72;
	
}
