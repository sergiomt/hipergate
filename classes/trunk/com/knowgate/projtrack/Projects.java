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

package com.knowgate.projtrack;

import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;

public class Projects {

  // --------------------------------------------------------------------------

  public static DBSubset getBugs(JDCConnection oConn, String[] aStatus,
  								 String sWorkAreaId, String sUserId, String sOrderBy)
  	throws SQLException {

	String sAllowedStatusList;
	
	if (aStatus==null) {
	  sAllowedStatusList = "";
	} else {
	  if (aStatus.length==1) {
	  	if (aStatus[0]==null)
	  	  sAllowedStatusList = "b."+DB.tx_status+" IS NULL AND ";
	  	else
	  	  sAllowedStatusList = "b."+DB.tx_status+"='"+aStatus[0]+"' AND ";
	  } else {
	  	sAllowedStatusList = "(";
	  	for (int s=0; s<aStatus.length; s++) {
	  	  if (aStatus[s]==null)
	  	    sAllowedStatusList += (s==0 ? "" : " OR ")+"b."+DB.tx_status+" IS NULL";
	  	  else
	  	    sAllowedStatusList += (s==0 ? "" : " OR ")+"b."+DB.tx_status+"='"+aStatus[s]+"'";
	  	} // next
	  	sAllowedStatusList += ") AND ";
	  } // fi
	} // fi (aStatus!=null)

	DBSubset oDbss = new DBSubset(DB.k_bugs+" b,"+DB.k_projects+" p",
								  "b."+DB.gu_bug+",b."+DB.pg_bug+",b."+DB.tl_bug+",b."+DB.gu_project+",b."+DB.dt_created+",b."+DB.gu_bug_ref+",b."+DB.dt_modified+",b."+DB.dt_since+",b."+DB.dt_closed+",b."+DB.dt_verified+",b."+DB.vs_found+",b."+DB.vs_closed+",b."+DB.od_severity+",b."+DB.od_priority+",b."+DB.tx_status+",b."+DB.nu_times+",b."+DB.tp_bug+",b."+DB.nm_reporter+",b."+DB.tx_rep_mail+",b."+DB.nm_assigned+",b."+DB.nm_inspector+",b."+DB.id_ref+",b."+DB.id_client+",b."+DB.gu_writer+",b."+DB.tx_bug_brief+",b."+DB.tx_bug_info+",b."+DB.tx_comments+",p."+DB.nm_project,
								  "b."+DB.gu_project+"=p."+DB.gu_project+" AND p."+DB.gu_owner+"=? AND "+ sAllowedStatusList +
								  "(b.gu_writer=? OR p.gu_user=? OR p.gu_contact=? OR EXISTS (SELECT c.gu_contact FROM k_contacts c WHERE c.gu_contact=? AND c.gu_company=p.gu_company)) "+
								  "ORDER BY "+(sOrderBy==null ? "5 DESC" : sOrderBy), 100);
    oDbss.load(oConn, new Object[]{sWorkAreaId, sUserId, sUserId, sUserId, sUserId});
    return oDbss;
  } // getBugs

  // --------------------------------------------------------------------------

  public static DBSubset getDuties(JDCConnection oConn, String[] aStatus,
  								   String sWorkAreaId, String sUserId, String sOrderBy)
  	throws SQLException {

	String sAllowedStatusList;

	if (aStatus==null) {
	  sAllowedStatusList = "";
	} else {
	  if (aStatus.length==1) {
	  	if (aStatus[0]==null)
	  	  sAllowedStatusList = "d."+DB.tx_status+" IS NULL AND ";
	  	else
	  	  sAllowedStatusList = "d."+DB.tx_status+"='"+aStatus[0]+"' AND ";
	  } else {
	  	sAllowedStatusList = "(";
	  	for (int s=0; s<aStatus.length; s++) {
	  	  if (aStatus[s]==null)
	  	    sAllowedStatusList += (s==0 ? "" : " OR ")+"d."+DB.tx_status+" IS NULL";
	  	  else
	  	    sAllowedStatusList += (s==0 ? "" : " OR ")+"d."+DB.tx_status+"='"+aStatus[s]+"'";
	  	} // next
	  	sAllowedStatusList += ") AND ";
	  } // fi
	} // fi (aStatus!=null)

	DBSubset oDbss = new DBSubset(DB.k_duties+" d,"+DB.k_projects+" p",
								  "d."+DB.gu_duty+",d."+DB.nm_duty+",d."+DB.gu_project+",d."+DB.gu_writer+",d."+DB.dt_created+",d."+DB.dt_modified+",d."+DB.dt_start+",d."+DB.dt_scheduled+",d."+DB.dt_end+",d."+DB.ti_duration+",d."+DB.od_priority+",d."+DB.gu_contact+",d."+DB.tx_status+",d."+DB.pct_complete+",d."+DB.pr_cost+",d."+DB.tp_duty+",d."+DB.de_duty+",d."+DB.tx_comments,
								  "d."+DB.gu_project+"=p."+DB.gu_project+" AND p."+DB.gu_owner+"=? AND "+ sAllowedStatusList +
								  "(d."+DB.gu_writer+"=? OR EXISTS (SELECT r."+DB.nm_resource+" FROM "+DB.k_x_duty_resource+" r WHERE r."+DB.gu_duty+"=d."+DB.gu_duty+" AND r."+DB.nm_resource+"=?)) "+
								  "ORDER BY "+(sOrderBy==null ? "5 DESC" : sOrderBy), 100);
    oDbss.load(oConn, new Object[]{sWorkAreaId, sUserId, sUserId});
    return oDbss;
  } // getDuties

  // --------------------------------------------------------------------------

  public static String XMLListBugs(JDCConnection oConn, String[] aStatus,
  								   String sWorkAreaId, String sUserId,
  								   String sDateTimeFormat, String sOrderBy)
    throws SQLException,IllegalArgumentException {
	DBSubset oDbss = Projects.getBugs(oConn, aStatus, sWorkAreaId, sUserId, sOrderBy);
    return "<Bugs count=\""+String.valueOf(oDbss.getRowCount())+"\">\n"+oDbss.toXML("","Bug",sDateTimeFormat, null)+"</Bugs>";
  } // XMLListOpenBugs

  // --------------------------------------------------------------------------

  public static String XMLListDuties(JDCConnection oConn, String[] aStatus,
  									 String sWorkAreaId, String sUserId, String sDateTimeFormat, String sOrderBy)
    throws SQLException,IllegalArgumentException {
	DBSubset oDbss = Projects.getDuties(oConn, aStatus, sWorkAreaId, sUserId, sOrderBy);
    return "<Duties count=\""+String.valueOf(oDbss.getRowCount())+"\">\n"+oDbss.toXML("","Duty",sDateTimeFormat, null)+"</Duties>";
  } // XMLListPendingDuties

  // --------------------------------------------------------------------------
	
}
