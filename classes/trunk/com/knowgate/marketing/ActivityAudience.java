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

package com.knowgate.marketing;

import java.util.Date;
import java.util.ListIterator;

import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.storage.Column;
import com.knowgate.crm.Contact;
import com.knowgate.hipergate.Address;
import com.knowgate.misc.Gadgets;

public class ActivityAudience extends DBPersist {

  private Address oAddr;
  private Contact oCont;

  public ActivityAudience() {
    super(DB.k_x_activity_audience, "ActivityAudience");
    oAddr = null;
    oCont = null;
  }

  public Address getAddress() {
    return oAddr;
  }

  public Contact getContact() {
    return oCont;
  }

  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
  	boolean bRetVal = super.load(oConn, PKVals);
  	if (bRetVal) {
  	  if (!isNull(DB.gu_address)) {
  	  	oAddr = new Address(oConn, getString(DB.gu_address));
  	    putAll(oAddr.getItemMap());
  	  }
  	  if (!isNull(DB.gu_contact)) {
  	  	oCont = new Contact(oConn, getString(DB.gu_contact));
  	    putAll(oCont.getItemMap());
  	  }
  	}
	return bRetVal;
  }

  @SuppressWarnings("unused")
public boolean load(JDCConnection oConn, String sGuActivityAudience) throws SQLException {
    if (true) throw new UnsupportedOperationException("Method load() must have two arguments for ActivityAudience");
    return false;
  }

  public boolean store(JDCConnection oConn) throws SQLException {
	boolean bRetVal;

	if (!AllVals.containsKey(DB.gu_activity)) {
	  put(DB.gu_activity, Gadgets.generateUUID());
	} else {
	  replace(DB.dt_modified, new Date());
	}

	bRetVal = super.store(oConn);
	
	if (bRetVal) {
	  String sColunmName;
	  ListIterator<Column> oIter;

	  if (oCont==null) oCont = new Contact();
	  boolean bHasAnyContactValue = false;
	  oIter = oCont.getTable(oConn).getColumns().listIterator();
	  while (oIter.hasNext() && !bHasAnyContactValue) {
	  	sColunmName = oIter.next().getName();
	  	if (!sColunmName.equals(DB.gu_workarea) && !sColunmName.equals(DB.gu_contact) && !sColunmName.equals(DB.gu_writer))
	      bHasAnyContactValue = AllVals.containsKey(sColunmName);
	  } // wend
	  if (bHasAnyContactValue) {
	  	oCont.putAll(getItemMap());
	  	oCont.store(oConn);
	  }
	  
	  if (oAddr==null) oAddr = new Address();
	  boolean bHasAnyAddressValue = false;
	  oIter = oAddr.getTable(oConn).getColumns().listIterator();
	  while (oIter.hasNext() && !bHasAnyAddressValue) {
	  	sColunmName = oIter.next().getName();
	  	if (!sColunmName.equals(DB.gu_workarea) && !sColunmName.equals(DB.gu_address) && !sColunmName.equals(DB.gu_user))
	      bHasAnyAddressValue = AllVals.containsKey(sColunmName);
	  } // wend
	  if (bHasAnyAddressValue) {
	  	oAddr.putAll(getItemMap());
	  	oAddr.replace(DB.ix_address, Address.nextLocalIndex(oConn, DB.k_x_contact_addr, DB.gu_contact, oCont.getString(DB.gu_contact)));
	  	oAddr.replace(DB.bo_active, (short) 1);
	  	oAddr.store(oConn);
	  }

	} // fi 

	return bRetVal;
  } // store

  public static final short CONFIRMED = 1;
  public static final short NOTCONFIRMED = 0;
  public static final short REFUSED = -1;
  
  public static final short ClassId = (short) 311;
}
