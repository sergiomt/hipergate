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

import java.util.ArrayList;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DB;

import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;

import com.knowgate.debug.DebugFile;

import com.knowgate.misc.Gadgets;

public class Campaign extends DBPersist {
  
  public Campaign() {
    super(DB.k_campaigns,"Campaign");    
  }

  public boolean store (JDCConnection oConn) throws SQLException {
  	if (!AllVals.containsKey(DB.gu_campaign))
  	  put(DB.gu_campaign, Gadgets.generateUUID());
    return super.store(oConn);
  }

  public DBSubset getTargets(JDCConnection oConn) throws SQLException {
  	DBSubset oTargets = null;
  	
	try {
	  oTargets = new DBSubset(DB.k_campaign_targets+" t,"+DB.k_products+" p,"+DB.k_thesauri+" z",
							  "t."+Gadgets.replace(new CampaignTarget().getTable(oConn).getColumnsStr(),",",",t.")+","+
							  "p."+DB.nm_product+",z."+DB.tx_term,
							  "p."+DB.gu_product+"=t."+DB.gu_product+" AND "+
							  "z."+DB.gu_term+"=t."+DB.gu_geozone+" AND "+									 
							  DB.gu_campaign+"=? ORDER BY t."+DB.dt_start, 10);
	} catch (Exception neverthrown) { }

	oTargets.load(oConn, new Object[]{getString(DB.gu_campaign)});
	return oTargets;
  }

  public boolean delete(JDCConnection oConn) throws SQLException {
    
    PreparedStatement oStmt;

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin Campaign.delete([JDCConnection])");
	  DebugFile.incIdent();
	}    

	ArrayList<String> aActivities = new ArrayList<String>();
	PreparedStatement oDlte = oConn.prepareStatement("SELECT "+DB.gu_activity+" FROM "+DB.k_activities+" WHERE "+DB.gu_campaign+"=?");
    oDlte.setString(1, getString(DB.gu_campaign));
    ResultSet oRSet = oDlte.executeQuery();
    while (oRSet.next()) {
      aActivities.add(oRSet.getString(1));
    }
    oRSet.close();
	oDlte.close();
	
	Activity oActy = new Activity();
	for (String a : aActivities) {
	  oActy.replace(DB.gu_activity, a);
      oActy.delete(oConn);
	}

    oStmt = oConn.prepareStatement("UPDATE "+DB.k_oportunities+" SET "+DB.gu_campaign+"=NULL WHERE "+DB.gu_campaign+"=?");
    oStmt.setString(1, getString(DB.gu_campaign));
    oStmt.executeUpdate();
    oStmt.close();
    
    oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_campaign_targets+" WHERE "+DB.gu_campaign+"=?");
    oStmt.setString(1, getString(DB.gu_campaign));
    oStmt.executeUpdate();
    oStmt.close();

    oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_campaigns+" WHERE "+DB.gu_campaign+"=?");
    oStmt.setString(1, getString(DB.gu_campaign));
    oStmt.executeUpdate();
    oStmt.close();    

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End Campaign.delete()");
	}
	return true;
  } // delete

  public static final short ClassId = (short) 300;
}
