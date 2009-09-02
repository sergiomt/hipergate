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

import java.sql.Statement;
import java.sql.CallableStatement;
import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBColumn;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.hipergate.Address;
import com.knowgate.misc.Gadgets;

public class Activity extends DBPersist {

  private Address oAddr;
  
  public Activity(JDCConnection oConn, String sGuActivity) 
    throws SQLException {
    super(DB.k_activities,"Activity");
    load(oConn, sGuActivity);
  }

  public Activity() {
    super(DB.k_activities,"Activity");
    oAddr = null;
  }

  public Address getAddress() {
    return oAddr;
  }

  public int getConfirmedAudienceCount(JDCConnection oConn) throws SQLException {
  	return DBCommand.queryCount(oConn, "*", DB.k_x_activity_audience, DB.gu_activity+"='"+getString(DB.gu_activity)+"' AND "+DB.bo_confirmed+"="+String.valueOf(ActivityAudience.CONFIRMED));
  }

  public int getNotConfirmedAudienceCount(JDCConnection oConn) throws SQLException {
  	return DBCommand.queryCount(oConn, "*", DB.k_x_activity_audience, DB.gu_activity+"='"+getString(DB.gu_activity)+"' AND "+DB.bo_confirmed+"="+String.valueOf(ActivityAudience.NOTCONFIRMED));
  }

  public int getRefusedAudienceCount(JDCConnection oConn) throws SQLException {
  	return DBCommand.queryCount(oConn, "*", DB.k_x_activity_audience, DB.gu_activity+"='"+getString(DB.gu_activity)+"' AND "+DB.bo_confirmed+"="+String.valueOf(ActivityAudience.REFUSED));
  }

  public int getTotalAudienceCount(JDCConnection oConn) throws SQLException {
  	return DBCommand.queryCount(oConn, "*", DB.k_x_activity_audience, DB.gu_activity+"='"+getString(DB.gu_activity)+"'");
  }

  public ActivityAudience[] getAudience(JDCConnection oConn) throws SQLException {
	ActivityAudience[] aAudience = null; 
	DBSubset oAudicence = new DBSubset (DB.k_x_activity_audience, DB.gu_contact, DB.gu_activity+"=?", 100);
	int iAudicence = oAudicence.load(oConn, new Object[]{getString(DB.gu_activity)});
	if (iAudicence>0) {
	  aAudience = new ActivityAudience[iAudicence];
	  for (int a=0; a<iAudicence; a++) {
		aAudience[a].load(oConn, new Object[]{getString(DB.gu_activity), oAudicence.getString(0,a)});
	  } // next
	} // fi
	return aAudience;
  } // getAudience

  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
  	boolean bRetVal = super.load(oConn, PKVals);
  	if (bRetVal) {
  	  if (!isNull(DB.gu_address)) {  	  	
  	  	oAddr = new Address(oConn, getString(DB.gu_address));
  	    putAll(oAddr.getItemMap());
  	  }
  	}
	return bRetVal;
  }

  public boolean load(JDCConnection oConn, String sGuActivity) throws SQLException {
    return load(oConn, new Object[]{sGuActivity});
  }

  public boolean store(JDCConnection oConn) throws SQLException {
	boolean bRetVal;

	if (!AllVals.containsKey(DB.gu_activity)) {
	  put(DB.gu_activity, Gadgets.generateUUID());
	}  else {
	  replace(DB.dt_modified, new Date());
	}

	bRetVal = super.store(oConn);
	
	if (bRetVal) {
	  if (oAddr==null) oAddr = new Address();
	  boolean bHasAnyAddressValue = false;
	  ListIterator<DBColumn> oIter = oAddr.getTable(oConn).getColumns().listIterator();
	  while (oIter.hasNext() && !bHasAnyAddressValue) {
	  	String sColunmName = oIter.next().getName();
	  	if (!sColunmName.equals(DB.gu_workarea))
	      bHasAnyAddressValue = AllVals.containsKey(sColunmName);
	  } // wend
	  if (bHasAnyAddressValue) {
	  	oAddr.putAll(getItemMap());
	  	oAddr.replace(DB.ix_address, 1);
	  	oAddr.replace(DB.bo_active, (short) 1);
	  	oAddr.store(oConn);
	  }
	}

	return bRetVal;
  } // store

  public boolean delete(JDCConnection oConn) throws SQLException {
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      Statement oStmt = oConn.createStatement();
      oStmt.executeQuery("SELECT k_sp_del_activity ('"+getString(DB.gu_activity)+"')");
      oStmt.close();
    } else {
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_activity ('"+getString(DB.gu_activity)+"') }");
	  oCall.execute();
	  oCall.close();
    }
    return true;
  } // delete
  
  public static final short ClassId = (short) 310;

}
