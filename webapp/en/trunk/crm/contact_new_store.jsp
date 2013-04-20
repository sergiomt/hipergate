<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_user = getCookie (request, "userid", null);

  String sLanguage = getNavigatorLanguage(request);
      
  String id_domain = nullif(request.getParameter("id_domain"),getCookie(request,"domainid",""));
  String gu_workarea = nullif(request.getParameter("gu_workarea"),getCookie(request,"workarea",""));
  String gu_oportunity = nullif(request.getParameter("gu_oportunity"));
  String courses = nullif(request.getParameter("courses"),"");
  
  String gu_company, gu_contact, gu_address;
      
  Company oComp = new Company();
  Contact oCont = new Contact();
  Address oAddr = new Address();
    
  JDCConnection oConn = null;
  PreparedStatement oPtmt = null;
  Statement oStmt = null;
  
  try {
    oConn = GlobalDBBind.getConnection("contact_new_store"); 

    oConn.setAutoCommit (false);

    // *************************
    // Store Company Information
    
    if (request.getParameter("nm_legal").length()>0) {
    
      if (request.getParameter("gu_company").length()>0)
        oComp.load(oConn, new Object[]{request.getParameter("gu_company")});
  
      loadRequest(oConn, request, oComp);
      
      oComp.store(oConn);

      gu_company = oComp.getString(DB.gu_company);
    }
    else
      gu_company = null;
      
    // *************************
    // Store Contact Information

    loadRequest(oConn, request, oCont);
    if (null!=gu_company) oCont.replace(DB.gu_company, gu_company);

    oCont.store(oConn);

    gu_contact = oCont.getString(DB.gu_contact);

    // *************************
    // Store Contact Information

    loadRequest(oConn, request, oAddr);
    
    if (gu_company != null)
      oAddr.replace(DB.nm_company, oComp.getStringNull(DB.nm_commercial, oComp.getString(DB.nm_legal)));
      
    oAddr.store(oConn);

    // ******************************
    // Store Link Contact and Address

    gu_address = oAddr.getString(DB.gu_address);

    if (!DBCommand.queryExists(oConn,DB.k_x_contact_addr,DB.gu_contact+"='"+gu_contact+"' AND "+DB.gu_address+"='"+gu_address+"'"))
    	oCont.addAddress(oConn, gu_address);
	
	  if (!oAddr.isNull(DB.nm_state)) {
      if (null==DBCommand.queryStr(oConn, "SELECT "+DB.gu_geozone+" FROM "+DB.k_contacts+" WHERE "+DB.gu_contact+"='"+gu_contact+"'")) {
        oPtmt = oConn.prepareStatement("SELECT "+DB.gu_term+" FROM "+DB.k_thesauri+" WHERE "+DB.id_domain+"=? AND "+DB.id_language+"=? AND "+DB.tx_term+"=?");
        oPtmt.setInt   (1, Integer.parseInt(id_domain));
        oPtmt.setString(2, sLanguage);
        oPtmt.setString(3, oAddr.getString(DB.nm_state));
        ResultSet oRSet = oPtmt.executeQuery();
        if (oRSet.next())
          DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_contacts+" SET "+DB.gu_geozone+"='"+oRSet.getString(1)+"' WHERE "+DB.gu_contact+"='"+gu_contact+"'");
        oRSet.close();
        oPtmt.close();
      } // fi (gu_geozone IS NULL)
    } // fi (nm_state IS NOT NULL)

    // *********************************
    // Assign contact to courses

    if (courses.length()>0) {
      String[] aCourses = Gadgets.split(courses,',');
      oPtmt = oConn.prepareStatement("DELETE FROM " + DB.k_x_course_alumni + " WHERE " + DB.gu_alumni + "=? AND " + DB.gu_acourse + " IN (SELECT " + DB.gu_course + " FROM " + DB.k_academic_courses + " WHERE " + DB.bo_active + "<>0)");
      oPtmt.setString(1, gu_contact);
      oPtmt.executeUpdate();
      oPtmt.close();
      oPtmt = oConn.prepareStatement("INSERT INTO "+DB.k_x_course_alumni+"("+DB.gu_acourse+","+DB.gu_alumni+") VALUES (?,'"+gu_contact+"')");
      for (int c=0; c<aCourses.length; c++) {
        oPtmt.setString(1, aCourses[c]);
        oPtmt.executeUpdate();
      }
      oPtmt.close();
    } // fi (courses!="")

    // *********************************
    // Assign contact to opportunity

    if (gu_oportunity.length()>0) {
    	DBPersist oXoc = new DBPersist(DB.k_x_oportunity_contacts, "OportunityContacts");
    	oXoc.put(DB.gu_oportunity, gu_oportunity);
    	oXoc.put(DB.gu_contact, gu_contact);
    	if (nullif(request.getParameter("tp_relation")).length()>0) oXoc.put(DB.tp_relation, request.getParameter("tp_relation"));
      oXoc.store(oConn);
    }

    // *********************************
    // Add Contact to Recently Used list

    RecentlyUsed oRecent = new RecentlyUsed (DB.k_contacts_recent, 10, DB.gu_contact, DB.gu_user);

    DBPersist oItem = new DBPersist (DB.k_contacts_recent, "RecentContact");

    oItem.put (DB.gu_contact, gu_contact);
    oItem.put (DB.full_name, oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""));
    oItem.put (DB.gu_user, id_user);
    oItem.put (DB.gu_workarea, gu_workarea);
    
    String nm_company = oComp.getStringNull(DB.nm_commercial, oComp.getStringNull(DB.nm_legal, null));
    if (null!=nm_company) oItem.put (DB.nm_company, nm_company);

    if (oAddr.getItemMap().containsKey(DB.work_phone))
      oItem.put (DB.work_phone, oAddr.get(DB.work_phone));
    if (oAddr.getItemMap().containsKey(DB.tx_email))
      oItem.put (DB.tx_email, oAddr.get(DB.tx_email));
	  
    oRecent.add (oConn, oItem);

    // ***************************************************************************
    // Check whether or not there is an active LDAP server and synchronize with it
    
    String sLdapConnect = Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapconnect", "");

    if (sLdapConnect.length()>0 && !oAddr.isNull(DB.tx_email)) {
    
      Class oLdapCls = Class.forName(Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapclass", "com.knowgate.ldap.LDAPNovell"));

      com.knowgate.ldap.LDAPModel oLdapImpl = (com.knowgate.ldap.LDAPModel) oLdapCls.newInstance();

      oLdapImpl.connectAndBind(Environment.getProfile(GlobalDBBind.getProfileName()));
         
      oLdapImpl.addAddress (oConn, gu_address);

      oLdapImpl.disconnect();
    } // fi (ldapconnect!="")

    // End LDAP synchronization
    // ***************************************************************************
    
    oConn.commit();

    oConn.setAutoCommit (true);
    
    com.knowgate.http.portlets.HipergatePortletConfig.touch(oConn, id_user, "com.knowgate.http.portlets.RecentContactsTab", gu_workarea);
    
    oConn.close("contact_new_store");
  }
  catch (NullPointerException e) {
    if (oConn!=null) {
      if (oStmt!=null) { try {oStmt.close(); } catch (Exception ignore) {} }
      if (oPtmt!=null) { try {oPtmt.close(); } catch (Exception ignore) {} }      
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("contact_new_store");
      }
    }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (com.knowgate.ldap.LDAPException e) {
    disposeConnection(oConn,"contact_new_store");
    oConn = null;
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=LDAPException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (ClassNotFoundException e) {
    disposeConnection(oConn,"contact_new_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ClassNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }  
  catch (NumberFormatException e) {
    disposeConnection(oConn,"contact_new_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>if (window.parent) { window.parent.opener.location.reload(true); window.parent.close(); } else if (\""+gu_oportunity+"\"!=\"\") { document.location = \"oportunity_edit.jsp?gu_oportunity="+gu_oportunity+"&gu_workarea="+gu_workarea+"&id_domain="+id_domain+"\" }<" + "/SCRIPT" +"></HEAD></HTML>");

%>