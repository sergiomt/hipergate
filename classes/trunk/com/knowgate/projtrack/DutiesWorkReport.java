/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

import java.math.BigDecimal;

import java.text.SimpleDateFormat;
import java.text.NumberFormat;
import java.text.DecimalFormat;

import java.util.HashMap;
import java.util.Locale;
import java.util.Date;
import java.util.ArrayList;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import com.knowgate.acl.ACLUser;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.crm.Contact;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.misc.Gadgets;

public class DutiesWorkReport extends DBPersist {
  
  private ArrayList<Duty> oDuties;
  
  public DutiesWorkReport() {
    super(DB.k_duties_workreports, "DutiesWorkReport");
    oDuties = new ArrayList<Duty>();
  }

  public void addDuty(Duty oDut) throws IllegalStateException {
    oDuties.add(oDut);
  }

  public boolean store(JDCConnection oConn) throws SQLException,IllegalStateException,NullPointerException {
    return store(oConn, "en");
  }
  
  public boolean store(JDCConnection oConn, String sLanguage) throws SQLException,IllegalStateException,NullPointerException {  	
	Date dtNow = new Date();
    Locale oLoc = new Locale(sLanguage);
    SimpleDateFormat oXMLDate = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
	DecimalFormat oNumFmt = (DecimalFormat) NumberFormat.getNumberInstance(oLoc);
	oNumFmt.setMaximumFractionDigits(2);

  	if (!containsKey(DB.gu_project)) throw new NullPointerException("DutiesWorkReport duties report, project is required");
  	if (!containsKey(DB.gu_writer)) throw new NullPointerException("DutiesWorkReport duties report, writer user is required");
  	 
    if (containsKey(DB.gu_workreport)) {
      if (DBCommand.queryExists(oConn, DB.k_duties_workreports, DB.gu_workreport+"='"+getString(DB.gu_workreport)+"'"))
  	    throw new IllegalStateException("DutiesWorkReport, it is not allowed to update an already existing report");  	
    } else {
      put(DB.gu_workreport, Gadgets.generateUUID());
    }
    
	if (!containsKey(DB.tl_workreport)) {
	  String sNmProject = DBCommand.queryStr(oConn, "SELECT "+DB.nm_project+" FROM "+DB.k_projects+" WHERE "+DB.gu_project+"='"+getStringNull(DB.gu_project,"")+"'");
	  put(DB.tl_workreport, sNmProject+" "+dtNow.toString());
	}

	ACLUser oWriter = new ACLUser(oConn, getString(DB.gu_writer));
	Project oProj = new Project(oConn, getString(DB.gu_project));

 	HashMap oPrioritiesMap = DBLanguages.getLookUpMap(oConn, DB.k_duties_lookup, oProj.getString(DB.gu_owner), DB.od_priority, sLanguage);
 	HashMap oDutyTypesMap = DBLanguages.getLookUpMap(oConn, DB.k_duties_lookup, oProj.getString(DB.gu_owner), DB.tp_duty, sLanguage);
 	HashMap oStatusMap = DBLanguages.getLookUpMap(oConn, DB.k_duties_lookup, oProj.getString(DB.gu_owner), DB.tx_status, sLanguage);
 	HashMap oResourcesMap = DBLanguages.getLookUpMap(oConn, DB.k_duties_lookup, oProj.getString(DB.gu_owner), DB.nm_resource, sLanguage);

    int nDuties = oDuties.size();
    StringBuffer oStrBuf = new StringBuffer(1000+500*nDuties);

    oStrBuf.append("<DutiesWorkReport>\n");

    oStrBuf.append("<tl_workreport><![CDATA["+getString(DB.tl_workreport)+"]]></tl_workreport>\n");
    oStrBuf.append("<dt_created>"+oXMLDate.format(dtNow)+"</dt_created>\n");
    oStrBuf.append("<de_workreport><![CDATA["+getStringNull(DB.de_workreport,"")+"]]></de_workreport>\n");

    oStrBuf.append("<Writer>\n");
    oStrBuf.append("  <tx_nickname>"+oWriter.getStringNull(DB.tx_nickname,"")+"</tx_nickname>\n");
    oStrBuf.append("  <tx_full_name><![CDATA["+(oWriter.getStringNull(DB.nm_user,"")+" "+oWriter.getStringNull(DB.tx_surname1,"")+" "+oWriter.getStringNull(DB.tx_surname2,"")).trim()+"]]></tx_full_name>\n");
    oStrBuf.append("  <nm_company><![CDATA["+oWriter.getStringNull(DB.nm_company,"")+"]]></nm_company>\n");
    oStrBuf.append("  <tx_main_email><![CDATA["+oWriter.getStringNull(DB.tx_main_email,"")+"]]></tx_main_email>\n");
    oStrBuf.append("</Writer>\n");

    oStrBuf.append(oProj.toXML());
    oStrBuf.append('\n');

	PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.nm_resource+","+DB.pct_time+" FROM "+DB.k_x_duty_resource+" WHERE "+DB.gu_duty+"=?",
													 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStrBuf.append("<Duties count=\""+String.valueOf(nDuties)+"\">\n");
    for (int d=0; d<nDuties; d++) {
      Duty oDut = oDuties.get(d);
      oStrBuf.append("<Duty>\n");
      oStrBuf.append("  <gu_duty>"+oDut.getString(DB.gu_duty)+"</gu_duty>\n");
      oStrBuf.append("  <nm_duty>"+oDut.getString(DB.nm_duty)+"</nm_duty>\n");
      if (oDut.isNull(DB.dt_modified)) oStrBuf.append("  <dt_modified/>\n"); else oStrBuf.append("  <dt_modified>"+oXMLDate.format(oDut.getDate(DB.dt_modified))+"</dt_modified>\n");
      if (oDut.isNull(DB.dt_start)) oStrBuf.append("  <dt_start/>\n"); else oStrBuf.append("  <dt_start>"+oDut.getDateShort(DB.dt_start)+"</dt_start>\n");
      if (oDut.isNull(DB.dt_end)) oStrBuf.append("  <dt_end/>\n"); else oStrBuf.append("  <dt_end>"+oDut.getDateShort(DB.dt_end)+"</dt_end>\n");
	  if (oDut.isNull(DB.ti_duration)) oStrBuf.append("  <ti_duration/>\n"); else oStrBuf.append("  <ti_duration>"+oDut.getDecimalFormated(DB.ti_duration,oLoc,2)+"</ti_duration>\n");
	  if (oDut.isNull(DB.pr_cost)) oStrBuf.append("  <pr_cost/>\n"); else oStrBuf.append("  <pr_cost>"+oNumFmt.format(new BigDecimal(oDut.getFloat(DB.pr_cost)))+"</pr_cost>\n");
	  if (oDut.isNull(DB.pct_complete)) oStrBuf.append("  <pct_complete/>\n"); else oStrBuf.append("  <pct_complete>"+String.valueOf(oDut.getFloat(DB.pct_complete)+"</pct_complete>\n"));
	  if (oDut.isNull(DB.od_priority)) {
	  	oStrBuf.append("  <od_priority/>\n");
	  } else {
		Object oPriority = oPrioritiesMap.get(oDut.get(DB.od_priority));
		if (null==oPriority)
		  oStrBuf.append("  <od_priority>"+oDut.get(DB.od_priority)+"</od_priority>\n");
	    else
		  oStrBuf.append("  <od_priority>"+oPriority+"</od_priority>\n");
	  }
	  if (oDut.isNull(DB.tp_duty)) {
	  	oStrBuf.append("  <tp_duty/>\n");
	  } else {
		Object oTpDuty = oDutyTypesMap.get(oDut.get(DB.tp_duty));
		if (null==oTpDuty)
		  oStrBuf.append("  <tp_duty>"+oDut.get(DB.tp_duty)+"</tp_duty>\n");
	    else
		  oStrBuf.append("  <tp_duty>"+oTpDuty+"</tp_duty>\n");
	  }
	  if (oDut.isNull(DB.tx_status)) {
	  	oStrBuf.append("  <tx_status/>\n");
	  } else {
		Object oTxStatus = oStatusMap.get(oDut.get(DB.tx_status));
		if (null==oTxStatus)
		  oStrBuf.append("  <tx_status>"+oDut.get(DB.tx_status)+"</tx_status>\n");
	    else
		  oStrBuf.append("  <tx_status>"+oTxStatus+"</tx_status>\n");
	  }
      oStrBuf.append("  <de_duty><![CDATA["+oDut.getStringNull(DB.de_duty,"")+"]]></de_duty>\n");
      oStrBuf.append("  <tx_comments><![CDATA["+oDut.getStringNull(DB.tx_comments,"")+"]]></tx_comments>\n");
	  if (oDut.isNull(DB.gu_contact)) {
	    oStrBuf.append("  <Contact><gu_contact/></Contact>\n");
	  } else {
	  	Contact oCont = new Contact(oConn, oDut.getString(DB.gu_contact));
	  	oStrBuf.append(oCont.toXML("  "));
	  }
	  oStrBuf.append("  <Resources>\n");
	  oStmt.setString(1, oDut.getString(DB.gu_duty));
	  ResultSet oRSet = oStmt.executeQuery();
	  while (oRSet.next()) {
	  	String sResNm = oRSet.getString(1);
	    oStrBuf.append("    <Resource name=\""+sResNm+"\" ");
	    short iPct = oRSet.getShort(2);
	    if (oRSet.wasNull())
	      oStrBuf.append("pct=\"100\"");
	    else
	      oStrBuf.append("pct=\""+String.valueOf(iPct)+"\"");	    	
	    oStrBuf.append("><![CDATA[");
	    Object oResTr = oResourcesMap.get(sResNm);
	    if (null==oResTr)
	      oStrBuf.append(sResNm);
	    else
	      oStrBuf.append(oResTr);
	    oStrBuf.append("]]></Resource>\n");
	  } // wend
	  oRSet.close();
	  oStrBuf.append("  </Resources>\n");
      oStrBuf.append("</Duty>\n");      
    } // next

    oStmt.close();

    oStrBuf.append("</Duties>\n");
    oStrBuf.append("</DutiesWorkReport>");
    put(DB.tx_workreport, oStrBuf.toString());

	return super.store(oConn);
  }

  public String toXML() {
  	return getStringNull(DB.tx_workreport,"<DutiesWorkReport><Duties count=\"0\"/></DutiesWorkReport>");
  }
  
  // **********************************************************
  // Public Constants

  public static final short ClassId = 87;
  
}
