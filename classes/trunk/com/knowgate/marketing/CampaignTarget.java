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

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.util.Date;
import java.util.LinkedList;
import java.util.ListIterator;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.debug.DebugFile;

import com.knowgate.misc.Gadgets;

import com.knowgate.hipergate.Term;

public class CampaignTarget extends DBPersist {

  public CampaignTarget() {
    super(DB.k_campaign_targets, "CampaignTarget");    
  }

  public boolean store (JDCConnection oConn) throws SQLException {
  	Date dtNow = new Date();
  	
  	if (!AllVals.containsKey(DB.gu_campaign_target)) {
  	  put (DB.gu_campaign_target, Gadgets.generateUUID());
  	}

	replace (DB.dt_modified, new Date(dtNow.getTime()+60000l));

	return super.store(oConn);
  }

  /**
   * Lookup non cancelled orders at k_orders table and refresh achieved sales for this campaign target
   * @param oConn JDCConnection
   * @return float Total number of products actually sold for this campaign target
   */

  public float refreshTargetAchievement (JDCConnection oConn)
  	throws SQLException {

	if (DebugFile.trace) {
      DebugFile.writeln("Begin CampaignTarget.refreshTargetAchievement([JDCConnection])");
      DebugFile.incIdent();
	}  	

  	float fSum = 0f;

	String sSQL = "SELECT SUM(l."+DB.nu_quantity+") FROM "+
		          DB.k_orders+" o,"+DB.k_order_lines+" l WHERE "+
		          "o."+DB.gu_order+"=l."+DB.gu_order+" AND "+
		          "o."+DB.dt_cancel+" IS NOT NULL AND "+
		          "o."+DB.dt_created+" BETWEEN ? AND ? AND "+
		          "o."+DB.gu_workarea+"=? AND "+
		          "l."+DB.gu_product +"=? AND ("+
		          "EXISTS (SELECT c."+DB.gu_company+" FROM "+DB.k_companies+" c WHERE c."+DB.gu_workarea+"=? AND c."+DB.gu_geozone+"=? AND c."+DB.gu_company+"=o."+DB.gu_company+") OR "+
		          "EXISTS (SELECT d."+DB.gu_contact+" FROM "+DB.k_contacts+" d WHERE d."+DB.gu_workarea+"=? AND d."+DB.gu_geozone+"=? AND d."+DB.gu_contact+"=o."+DB.gu_contact+"))";
		          	
	PreparedStatement oSum = oConn.prepareStatement(sSQL);
    ResultSet oRst;

	oSum.setTimestamp(1, getTimestamp(DB.dt_start));
	oSum.setTimestamp(2, getTimestamp(DB.dt_end));
	oSum.setString(3, getString(DB.gu_workarea));
	oSum.setString(4, getString(DB.gu_product));
	oSum.setString(5, getString(DB.gu_workarea));
	oSum.setString(7, getString(DB.gu_workarea));
  	
  	Term oZone = new Term();
  	oZone.load(oConn, getString(DB.gu_geozone));
  	LinkedList oChlds = oZone.getChilds(oConn, Term.SCOPE_ALL);
  	ListIterator oIter = oChlds.listIterator();
  	while (oIter.hasNext()) {
  	  oZone = (Term) oIter.next();
	  oSum.setString(6, oZone.getString(DB.gu_term));
	  oSum.setString(8, oZone.getString(DB.gu_term));
	  oRst = oSum.executeQuery();
      oRst.next();
	  if (DebugFile.trace)
        DebugFile.writeln("  sales for "+oZone.getString(DB.tx_term)+" = "+String.valueOf(oRst.getFloat(1)));
      fSum += oRst.getFloat(1);
      oRst.close();
  	} // wend

	if (DebugFile.trace)
      DebugFile.writeln("  subtotal sales for all child zones = "+String.valueOf(fSum));
  	
	oSum.setString(6, getString(DB.gu_geozone));
	oSum.setString(8, getString(DB.gu_geozone));
	oRst = oSum.executeQuery();
    oRst.next();
	if (DebugFile.trace) {
  	  oZone.load(oConn, getString(DB.gu_geozone));
      DebugFile.writeln("  sales for zone "+oZone.getString(DB.tx_term)+" = "+String.valueOf(oRst.getFloat(1)));
	}
    fSum += oRst.getFloat(1);
    oRst.close();

    oSum.close();

    replace(DB.nu_achieved, fSum);

	if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CampaignTarget.refreshTargetAchievement() : "+String.valueOf(fSum));
	}

    return fSum;
  } // refreshTargetAchievement

  /**
   * Increase achieved sales of a given product for all active campaigns
   * @param oConn JDCConnection
   * @param sGuWorkArea String WorkArea GUID
   * @param sGuZone String GUID of thesauri Term representing the Geographic Zone
   * @param sGuProduct String product GUID
   * @param fQuantity float Count of new products sold (if negative sales are decreased)
   * @return int Number of campaign targets updated
   */
  public static int increaseTargetAchievement(JDCConnection oConn,
  								              String sGuWorkArea,
  								              String sGuZone,
  								              String sGuProduct,
  								              float fQuantity)
  	throws SQLException {

	int iAffected = 0;
	
	String sSQL = "UPDATE "+DB.k_campaign_targets+" SET "+
				  DB.nu_achieved+"="+DB.nu_achieved+(fQuantity>=0f ? "+" : "-")+String.valueOf(fQuantity>=0f ? fQuantity : -fQuantity)+" WHERE "+
				  DB.gu_campaign_target+" IN (SELECT t."+DB.gu_campaign_target+" FROM "+
  				  DB.k_campaigns+" c,"+DB.k_campaign_targets+" t WHERE "+
  				  "c."+DB.gu_campaign+"=t."+DB.gu_campaign+" AND "+
  				  "c."+DB.gu_workarea+"=? AND c."+DB.bo_active+"<>0 AND "+
  				  "t."+DB.gu_geozone+"=? AND t."+DB.gu_product+"=? AND "+  								   
  				  DBBind.Functions.GETDATE+" BETWEEN "+DB.dt_start+" AND "+DB.dt_end+")";

	PreparedStatement oUpdt = oConn.prepareStatement(sSQL);
	
	oUpdt.setString(1,sGuWorkArea);
	oUpdt.setString(2,sGuZone);
	oUpdt.setString(3,sGuProduct);
	iAffected += oUpdt.executeUpdate();

	Term oZone = new Term();
	oZone.load(oConn, sGuZone);
	String sGuParent = oZone.getParent(oConn);
	
	while (sGuParent!=null) {	  
	  oUpdt.setString(1,sGuWorkArea);
	  oUpdt.setString(2,sGuParent);
	  oUpdt.setString(3,sGuProduct);
	  iAffected += oUpdt.executeUpdate();
	  oZone.load(oConn, sGuParent);
	  sGuParent = oZone.getParent(oConn);	  
	} // wend
	
	oUpdt.close();
	return iAffected;				   	  							  	

  } // increaseProductSales

  public static final short ClassId = (short) 301;
	
}
