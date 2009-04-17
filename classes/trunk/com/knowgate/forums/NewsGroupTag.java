/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

package com.knowgate.forums;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

public class NewsGroupTag extends DBPersist {
  public NewsGroupTag() {
    super(DB.k_newsgroup_tags, "NewsGroupTag");
  }
  
  public boolean store(JDCConnection oConn) throws SQLException {
  	
  	if (isNull(DB.gu_newsgrp)) throw new SQLException("NewsGroupTag.store() gu_newsgrp may not be null"); 
  	if (isNull(DB.tl_tag)) throw new SQLException("NewsGroupTag.store() tl_tag may not be null"); 
  		
  	if (isNull(DB.gu_tag)) {
	  PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_tag+" FROM "+DB.k_newsgroup_tags+" WHERE "+DB.gu_newsgrp+"=? AND "+DBBind.Functions.UPPER+"("+DB.tl_tag+")=?");
	  oStmt.setString(1, getString(DB.gu_newsgrp));
	  oStmt.setString(2, getString(DB.tl_tag).toUpperCase());
	  ResultSet oRSet = oStmt.executeQuery();
	  if (oRSet.next())
	  	replace(DB.gu_tag, oRSet.getString(1));
	  oRSet.close();
	  oStmt.close();
  	} // fi

  	if (isNull(DB.gu_tag)) put(DB.gu_tag, Gadgets.generateUUID());
  	
  	return super.store(oConn);
  }
}
