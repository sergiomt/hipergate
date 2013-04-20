<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Address,com.knowgate.crm.Contact,com.knowgate.addrbook.Fellow,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
 
 response.addHeader ("Pragma", "no-cache");
 response.addHeader ("cache-control", "no-store");
 response.setIntHeader("Expires", 0);

 // [~//Obtener el idioma del navegador cliente~]
 String sLanguage = getNavigatorLanguage(request);

 // [~//Obtener el skin actual~]
 String sSkin = getCookie(request, "skin", "default");

 // [~//Obtener el dominio y la workarea~]
 String id_domain = getCookie(request,"domainid","");
 String n_domain = getCookie(request,"domainnm",""); 
 String gu_workarea = getCookie(request,"workarea",""); 
 String gu_user = getCookie(request, "userid", "");

 String tx_name = request.getParameter("tx_name");
 String tx_surname = request.getParameter("tx_surname");
 String de_title = request.getParameter("de_title");
 String tx_dept = request.getParameter("tx_dept");
 String tx_location = request.getParameter("tx_location");
 String work_phone = request.getParameter("work_phone");
 String home_phone = request.getParameter("home_phone");
 String tx_email = request.getParameter("tx_email");

 String nm_company = request.getParameter("nm_company");
 String tx_addr1 = request.getParameter("tx_addr1");
 String nm_country = request.getParameter("nm_country");
 String nm_state = request.getParameter("nm_state");
 String nm_city = request.getParameter("nm_city");

 String mov_phone = request.getParameter("mov_phone");
 String fax_phone = request.getParameter("fax_phone");

 String url_addr = request.getParameter("url_addr");
 String contact_person = request.getParameter("contact_person");

  Contact oContact = new Contact();
  Address oAddress = new Address();
  
  String gu_contact = Gadgets.generateUUID();
  String gu_address = Gadgets.generateUUID();

  JDCConnection oConn = GlobalDBBind.getConnection("wabprocess");  
  Statement oStmt = null;
  PreparedStatement oPrep = null;
  ResultSet oRSet;
  boolean bAlreadyExists;
    
  try {
  
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM k_addresses WHERE gu_workarea='" + gu_workarea + "' AND tx_email='" + tx_email + "')");

    oPrep = oConn.prepareStatement("SELECT NULL FROM k_addresses WHERE gu_workarea=? AND tx_email=?");
    oPrep.setString(1, gu_workarea);
    oPrep.setString(2, tx_email);    
    oRSet = oPrep.executeQuery();
    bAlreadyExists = oRSet.next();
    oRSet.close();
    oRSet=null;
    oPrep.close();
    oPrep=null;
    
    if (!bAlreadyExists) {
      if (DebugFile.trace) DebugFile.writeln(tx_email + " does not exist");
      
      oConn.setAutoCommit (false);
  
      oAddress.put("gu_address",gu_address);
      oAddress.put("gu_workarea",gu_workarea);
      oAddress.put("bo_active",1);
      oAddress.put("ix_address",1);
      oAddress.put("tx_email",tx_email);
      if (nm_company.length()>0) oAddress.put("nm_company",nm_company);
      if (tx_addr1.length()>0) oAddress.put("tx_addr1",tx_addr1);
      if (nm_country.length()>0) oAddress.put("nm_country",nm_country);
      if (nm_state.length()>0) oAddress.put("nm_state",nm_state);
      if (nm_city.length()>0) oAddress.put("mn_city",nm_city);
      if (work_phone.length()>0) oAddress.put("work_phone",work_phone);
      if (home_phone.length()>0) oAddress.put("home_phone",home_phone);
      if (mov_phone.length()>0) oAddress.put("mov_phone",mov_phone);
      if (fax_phone.length()>0) oAddress.put("fax_phone",fax_phone);
      if (url_addr.length()>0) oAddress.put("url_addr",url_addr);
      if (contact_person.length()>0) oAddress.put("contact_person",contact_person);
      oAddress.store(oConn);
    
      oContact.put("gu_contact",gu_contact);
      oContact.put("id_ref","wab");
      oContact.put("gu_workarea",gu_workarea);
      oContact.put("bo_private",(short)1);
      oContact.put("gu_writer",gu_user);
      oContact.put("nu_attachs",0);
      oContact.put("nu_notes",0);
      if (tx_name.length()>0) oContact.put("tx_name",tx_name);
      if (tx_surname.length()>0) oContact.put("tx_surname",tx_surname);
      if (de_title.length()>0) oContact.put("de_title",de_title);
      if (tx_dept.length()>0) oContact.put("tx_dept",tx_dept);
      if (tx_location.length()>0) oContact.put("tx_location",tx_location);
      if (work_phone.length()>0) oContact.put("work_phone",work_phone);
      if (home_phone.length()>0) oContact.put("home_phone",home_phone);
      oContact.put("tx_email",tx_email);
      oContact.store(oConn);
    
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Connection.executeUpdate(INSERT INTO k_x_contact_addr (" + DB.gu_contact + ", " + DB.gu_address + ") VALUES ('" + gu_contact + "','" + gu_address + "'))");

      oStmt.executeUpdate("INSERT INTO k_x_contact_addr (" + DB.gu_contact + ", " + DB.gu_address + ") VALUES ('" + gu_contact + "','" + gu_address + "')");

      oStmt.close();
      oStmt = null;
      
      oConn.commit();
    } // fi (!bAlreadyExists)
    else if (DebugFile.trace)
      DebugFile.writeln(tx_email + " already exists");

  oConn.close("wabprocess");
  }
  catch (SQLException e) {  
    try {if (oStmt!=null) oStmt.close(); } catch (SQLException ignore) {}
    disposeConnection(oConn,"wabprocess");
    oConn = null;
    
    if (DebugFile.trace) DebugFile.writeln("SQLException " + e.getMessage());
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=../_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
%>
<HTML>
<HEAD>
<TITLE>Wait...</TITLE>
<SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
<SCRIPT DEFER>
<!--
  WAB_Frame = top.frames[0];
  entrydata = unescape(getURLParam("entrydata"));
    
  WAB_Frame.WAB_Select(WAB_Frame.WAB_SelectedEntry()+1);
  document.location.href = "./wabload.html?getentry=1";
//-->
</SCRIPT>
</HEAD>
<BODY>
</BODY>
</HTML>
