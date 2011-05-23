package com.knowgate.training;

/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.

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

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.jdc.JDCConnection;

public class ContactEducation extends DBPersist {

	public static final short ClassId = 103;
	
	public ContactEducation() {
		super (DB.k_contact_education, "ContactEducation");
	}

	public boolean store(JDCConnection oConn) throws SQLException {
		if (DebugFile.trace) {
		  DebugFile.writeln("Begin ContactEducation.store([JDCConnection])");
		  DebugFile.incIdent();
		}
		if (isNull(DB.ix_degree)) {
		  Integer oMaxDg = DBCommand.queryMaxInt(oConn, DB.ix_degree, DB.k_contact_education,
		                   DB.gu_contact+"='"+getString(DB.gu_contact)+"'");
		  if (null==oMaxDg) oMaxDg = new Integer(1);
		  put (DB.ix_degree, oMaxDg);
		}
		
		if (!isNull(DB.gu_degree) &&
		   (isNull(DB.tp_degree) || isNull(DB.id_degree))) {
		   if (DebugFile.trace)
		     DebugFile.writeln("JDCConnection.prepareStatement(SELECT "+DB.tp_degree+","+DB.id_degree+" FROM "+DB.k_education_degree+" WHERE "+DB.gu_degree+"='"+getStringNull(DB.gu_degree,"")+"')");
		  PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.tp_degree+","+DB.id_degree+" FROM "+DB.k_education_degree+" WHERE "+DB.gu_degree+"=?",
		  												   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
		  oStmt.setString(1, getString(DB.gu_degree));
		  ResultSet oRSet = oStmt.executeQuery();
		  if (oRSet.next()) {
		    String d = oRSet.getString(1);
		    if (DebugFile.trace) DebugFile.writeln("tp_degree="+d);
		    if (isNull(DB.tp_degree) && !oRSet.wasNull()) put(DB.tp_degree, d);
		    d = oRSet.getString(2);
		    if (DebugFile.trace) DebugFile.writeln("id_degree="+d);
		    if (isNull(DB.id_degree) && !oRSet.wasNull()) put(DB.id_degree, d);
		  }
		  oRSet.close();
		  oStmt.close();
		} // fi
		
		boolean bRetVal = super.store(oConn);

		if (DebugFile.trace) {
		  DebugFile.decIdent();
		  DebugFile.writeln("End ContactEducation.store() : "+String.valueOf( bRetVal));
		}

		return bRetVal;
  } // store
	
}
