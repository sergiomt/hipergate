<%@ page import="java.util.HashMap,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBAudit,com.knowgate.crm.Contact,com.knowgate.crm.Company,com.knowgate.hipergate.Address,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets,com.knowgate.debug.StackTraceUtil" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><%@ include file="inc/dbbind.jsp" %><%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "contact_store";
  final int nLangs = DBLanguages.SupportedLanguages.length;

  final String gu_workarea = oUser.getString(DB.gu_workarea);
  final String gu_contact = request.getParameter("gu_contact");
  
  String gu_company = request.getParameter("gu_company");
  String gu_address = request.getParameter("gu_address");
  String nm_company = request.getParameter("nm_company");
  String de_title = request.getParameter("de_title");
  String id_country = request.getParameter("id_country");
  String nm_state = request.getParameter("nm_state");
  String id_state = null;

  final String sOpCode = gu_contact.length()>0 ? "NCON" : "MCON";
      
  Contact oCont = new Contact();
  Company oComp = new Company();
  Address oAddr = new Address();

  oCont.allcaps(oUser.allcaps());
  oComp.allcaps(oUser.allcaps());
  oAddr.allcaps(oUser.allcaps());

  PreparedStatement oStmt = null;
  ResultSet oRset = null;
  boolean bNewCompany = false;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

    // ****************************
	  // Lookup State Id. by its name
	  
		if (id_country.length()>0 && nm_state.length()>0) {
      oStmt = oConn.prepareStatement("SELECT "+DB.vl_lookup+" FROM "+DB.k_addresses_lookup+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"=? AND ("+DB.tr_+"en=? OR "+DB.tr_+sLanguage+"=?)",
                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, gu_workarea);
      oStmt.setString(2, id_country);
      oStmt.setString(3, nm_state);
      oStmt.setString(4, nm_state);
      oRset = oStmt.executeQuery();
      if (oRset.next()) id_state = oRset.getString(1);
		  oRset.close();
			oRset=null;
			oStmt.close();
			oStmt=null;
		} // fi (id_country!="" && nm_state!="")

	  // End lookup State Id. by its name
    // ********************************

    // *******************************
	  // Lookup Company GUID by its name

    if (gu_company.length()==0 && nm_company.length()>0) {
    	oStmt = oConn.prepareStatement("SELECT "+DB.gu_company+" FROM "+DB.k_companies+" WHERE "+DB.gu_workarea+"=? AND ("+DB.nm_legal+"=? OR "+DB.nm_commercial+"=?)",
    																 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    	oStmt.setString(1, gu_workarea);
    	oStmt.setString(2, nm_company);
    	oStmt.setString(3, nm_company);
			oRset = oStmt.executeQuery();
		  if (oRset.next()) gu_company = oRset.getString(1);
      oRset.close();
      oStmt.close();
    } // fi

	  // End lookup Company GUID by its name
    // ***********************************

    if (gu_company.length()>0) {
      oComp.load(oConn, gu_company);
    }

    if (nm_company.length()>0 && !nm_company.equalsIgnoreCase(oComp.getString(DB.nm_legal)) && !nm_company.equalsIgnoreCase(oComp.getStringNull(DB.nm_commercial,""))) {
      bNewCompany = true;
      oComp = new Company();
      oComp.put(DB.gu_workarea, gu_workarea);
      oComp.put(DB.nm_legal, nm_company);
      oComp.put(DB.nm_commercial, nm_company);
      oComp.put(DB.bo_restricted, (short)0);
    }

		// ******************************
	  // Load and update contact record

    if (gu_contact.length()>0) {
      if (!oCont.load(oConn, gu_contact)) throw new Exception("Contact not found "+gu_contact); 
    } else {
      oCont.put(DB.gu_workarea, gu_workarea);
      oCont.put(DB.bo_restricted, (short)0);
      oCont.put(DB.bo_private, (short)0);
      oCont.put(DB.bo_change_pwd, (short)1);
      oCont.put(DB.nu_notes, 0);
      oCont.put(DB.nu_attachs, 0);
    }
		if (nm_company.length()==0)
		  oCont.remove(DB.gu_company);
		else
      oAddr.replace(DB.nm_company, nm_company);
    oCont.replace(DB.gu_writer, oUser.getString(DB.gu_user));
    if (request.getParameter("tx_name").length()>0)
      oCont.replace(DB.tx_name, request.getParameter("tx_name"));
    else
      oCont.remove(DB.tx_name);
    if (request.getParameter("tx_surname").length()>0)
      oCont.replace(DB.tx_surname, request.getParameter("tx_surname"));
    else
      oCont.remove(DB.tx_surname);
    if (de_title.length()>0) {      
      oCont.replace(DB.de_title, de_title);
    } else {
      oCont.remove(DB.de_title);
    }

	  // End load and update contact record
		// **********************************

		// ******************************
	  // Load and update address record

    if (gu_address.length()>0) {
      oAddr.load(oConn, gu_address);
    } else {
      oAddr.put(DB.gu_workarea, gu_workarea);
      oAddr.put(DB.gu_user, oUser.getString(DB.gu_user));
		  if (nm_company.length()==0) oAddr.replace(DB.nm_company, nm_company);
    }
    if (request.getParameter("tx_email").length()>0)    
      oAddr.replace(DB.tx_email, request.getParameter("tx_email"));
    else
    	oAddr.remove(DB.tx_email);
    if (request.getParameter("tp_street").length()>0)
      oAddr.replace(DB.tp_street, request.getParameter("tp_street"));
    else
      oAddr.remove(DB.tp_street);
    oAddr.replace(DB.nm_street, request.getParameter("nm_street"));
    oAddr.replace(DB.nu_street, request.getParameter("nu_street"));
    oAddr.replace(DB.tx_addr1, request.getParameter("tx_addr1"));
    oAddr.replace(DB.tx_addr2, request.getParameter("tx_addr2"));
    oAddr.replace(DB.zipcode, request.getParameter("zipcode"));
    oAddr.replace(DB.mn_city, request.getParameter("mn_city"));
    if (id_state==null) {
      oAddr.remove(DB.id_state);
    } else {
      oAddr.replace(DB.id_state, id_state);
    }
    if (nm_state.length()>0) {
      oAddr.replace(DB.nm_state, nm_state);
    } else {      
      oAddr.remove(DB.nm_state);
    }
    if (id_country.length()>0) {
      oAddr.replace(DB.id_country, id_country);      
    } else {    	
      oAddr.remove(DB.id_country);
      oAddr.remove(DB.nm_country);
    }

    if (gu_contact.length()==0) {
      if (request.getParameter("nu_phone").length()>0)
        oAddr.put(request.getParameter("tp_phone"), request.getParameter("nu_phone"));
    } else {
    	if (request.getParameter("mov_phone").length()>0)
        oAddr.replace(DB.mov_phone, request.getParameter("mov_phone"));
      else
      	oAddr.remove(DB.mov_phone);
    	if (request.getParameter("work_phone").length()>0)
        oAddr.replace(DB.work_phone, request.getParameter("work_phone"));
      else
      	oAddr.remove(DB.work_phone);
    	if (request.getParameter("direct_phone").length()>0)
        oAddr.replace(DB.direct_phone, request.getParameter("direct_phone"));
      else
      	oAddr.remove(DB.direct_phone);
    	if (request.getParameter("home_phone").length()>0)
        oAddr.replace(DB.home_phone, request.getParameter("home_phone"));
      else
      	oAddr.remove(DB.home_phone);
    }

	  // End load and update address record
		// **********************************

	  // ***********************
	  // Begin write transaction
	  	  
    oConn.setAutoCommit (false);

	  if (bNewCompany) oComp.store(oConn);

		if (!oComp.isNull(DB.gu_company))
		  oCont.replace(DB.gu_company, oComp.getString(DB.gu_company));

	  oCont.store(oConn);

    if (gu_address.length()==0) {
    	oAddr.put(DB.ix_address, Address.nextLocalIndex(oConn, DB.k_x_contact_addr, DB.gu_contact, oCont.getString(DB.gu_contact)));
		}

    oAddr.store(oConn);

		if (gu_address.length()==0) oCont.addAddress(oConn, oAddr.getString(DB.gu_address));

    // Add contact title lookup value if necessary
    
    if (de_title.length()>0) {      
      HashMap<String,String> oTitles = new HashMap<String,String>(nLangs*3);
      for (int l=0; l<nLangs; l++) oTitles.put(DBLanguages.SupportedLanguages[l], de_title); 
      Contact.addLookupJobTitle (oConn, gu_workarea, de_title, oTitles);
    }
			
    // Add state name lookup value if necessary
			
    if (id_country.length()>0 && nm_state.length()>0) {
      HashMap<String,String> oState = new HashMap<String,String>(nLangs*3);
      for (int l=0; l<nLangs; l++) oState.put(DBLanguages.SupportedLanguages[l], nm_state);       
      Address.addLookupState (oConn, gu_workarea, id_country, nm_state, oState);
    }
 
    DBAudit.log(oConn, Contact.ClassId, sOpCode, oUser.getString(DB.gu_user), oCont.getString(DB.gu_contact), oCont.getStringNull(DB.gu_company,""), 0, 0, oCont.getStringNull(DB.tx_name,"")+" "+oCont.getStringNull(DB.tx_surname,""), oComp.getStringNull(DB.nm_legal,""));
    
    oConn.commit();
    oConn.close(PAGE_NAME);
  }
  catch (Exception xcpt) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close(PAGE_NAME);
      }
    oConn = null;
    
		out.write("<?xml version=\"1.0\"?><wml><card>"+xcpt.getClass().getName()+"<br/>"+xcpt.getMessage()+"<br/>"+Gadgets.replace(StackTraceUtil.getStackTrace(xcpt),"\n","<br/>")+"</card></wml>");
  }

  if (null==oConn) return;
  oConn = null;
  
  response.sendRedirect ("home.jsp");
%>