/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipergate;

import java.util.Date;

import java.sql.SQLException;
import java.sql.PreparedStatement;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;

public class InvoicePayment extends DBPersist {

  public InvoicePayment() {
  	super(DB.k_invoice_payments,"InvoicePayment");
  }

  public boolean store(JDCConnection oConn) throws SQLException,NullPointerException {

	if (isNull(DB.gu_invoice) || !AllVals.containsKey(DB.gu_invoice))
	  throw new NullPointerException("InvoicePayment.store() gu_invoice not set");
		
  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin InvoicePayment.store([JDCConnection])");
  	  DebugFile.incIdent();
  	}
  	
    if (isNull(DB.pg_payment)) {
      Integer oNextPayId = DBCommand.queryInt(oConn, "SELECT MAX("+DB.pg_payment+") FROM "+
      	                                      DB.k_invoice_payments+" WHERE "+
      	                                      DB.gu_invoice+"='"+getString(DB.gu_invoice)+"'");
      if (null==oNextPayId) oNextPayId = new Integer(0);
      put(DB.pg_payment, oNextPayId.intValue()+1);
    }
    if (isNull(DB.dt_payment)) {
      if (isNull(DB.dt_paid))
        put(DB.dt_payment, new Date());
      else
        put(DB.dt_payment, get(DB.dt_paid));
    }
    if (isNull(DB.id_currency)) {
	  put(DB.id_currency, DBCommand.queryStr(oConn, "SELECT "+DB.id_currency+" FROM "+DB.k_invoices+" WHERE "+DB.gu_invoice+"='"+getString(DB.gu_invoice)+"'"));
    }

	boolean bRetVal = super.store(oConn);    

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End InvoicePayment.store([JDCConnection]) : "+String.valueOf(bRetVal));
  	}

	return bRetVal;
  } // store

  public boolean delete(JDCConnection oConn) throws SQLException {
    if (!isNull(DB.dt_paid) && !isNull(DB.im_paid)) {    	
      PreparedStatement oUpdt = oConn.prepareStatement("UPDATE "+DB.k_invoices+" SET "+DB.im_paid+"="+DB.im_paid+"-? WHERE "+DB.gu_invoice+"=?");
	  oUpdt.setBigDecimal(1, getDecimal(DB.im_paid));
	  oUpdt.setString(2, getString(DB.gu_invoice));
	  oUpdt.executeUpdate();
	  oUpdt.close();
    }
	return super.delete(oConn);
  }
  
  // **********************************************************
  // Constantes Publicas

  public static final short ClassId = 46;

}
