package com.knowgate.training;

/*
 Copyright (C) 2003-2012  Know Gate S.L. All rights reserved.

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

import java.sql.SQLException;
import java.sql.ResultSet;
import java.sql.PreparedStatement;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

public class Admission extends DBPersist {

	public static final short ClassId = 105;

	public Admission() {
		super(DB.k_admission, "Admission");
	}

	public boolean store(JDCConnection oConn) throws SQLException {
	  if (!AllVals.containsKey(DB.gu_admission))
	    put(DB.gu_admission, Gadgets.generateUUID());

	  if (!AllVals.containsKey(DB.gu_oportunity) && AllVals.containsKey(DB.gu_acourse)) {
		PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_object+" FROM "+DB.k_oportunities_attrs+" WHERE "+DB.nm_attr+"='gu_acourse' AND "+DB.vl_attr+"=?");
		oStmt.setString(1, getString(DB.gu_acourse));
		ResultSet oRSet = oStmt.executeQuery();
		if (oRSet.next()) put(DB.gu_oportunity, oRSet.getString(1));
		oRSet.close();
		oStmt.close();
	  }

	  if (!AllVals.containsKey(DB.gu_oportunity) && AllVals.containsKey(DB.gu_contact) && AllVals.containsKey(DB.gu_acourse)) {
		PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_oportunity+" FROM "+DB.k_oportunities+" WHERE "+DB.gu_contact+"=? AND "+DB.tl_oportunity+"=?");
		oStmt.setString(1, getString(DB.gu_contact));
		oStmt.setString(2, DBCommand.queryStr(oConn, "SELECT "+DB.nm_course+" FROM "+DB.k_academic_courses+" WHERE "+DB.gu_acourse+"='"+getString(DB.gu_acourse)+"'"));
		ResultSet oRSet = oStmt.executeQuery();
		if (oRSet.next()) put(DB.gu_oportunity, oRSet.getString(1));
		oRSet.close();
		oStmt.close();
	  }
	  
	  return super.store(oConn);
	} // store
}
