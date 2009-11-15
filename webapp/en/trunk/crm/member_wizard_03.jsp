<%@ page import="java.util.HashMap,java.net.URLDecoder,java.sql.*,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);
  
  JDCConnection oConn = GlobalDBBind.getConnection("memberinsert");
  PreparedStatement statement = null;

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 
  String gu_list = request.getParameter("gu_list");
  String sList = request.getParameter("members");

  String aContacts[];
  
  try
  { aContacts = Gadgets.split(sList,","); }
  catch (Exception e)
  { aContacts = new String[]{sList}; }
    
  for (int i=0; i<aContacts.length; i++)
  {  
    String aMember[] = Gadgets.split(aContacts[i], '-');
    String sQuery = new String("INSERT INTO k_x_list_members (gu_list,tx_email,mov_phone,tx_name,tx_surname,dt_created,");
    
    if (aMember[0].length()<32) // Company does not exist
    {
	    sQuery = sQuery + "gu_company,gu_contact) SELECT '" + request.getParameter("gu_list") + "',tx_email,mov_phone,tx_name,tx_surname,dt_created,gu_company,gu_contact FROM "+DB.k_member_address+" WHERE gu_contact='" + aMember[1] + " AND gu_company IS NULL ";
    }
    else
      if (aMember[1].length()<32) // Contact does not exist
      {
       	sQuery = sQuery + "gu_company,gu_contact) SELECT '" + request.getParameter("gu_list") + "',tx_email,nm_commercial,tx_surname,dt_created,gu_company,gu_contact FROM "+DB.k_member_address+" WHERE gu_contact IS NULL AND gu_company =" + aMember[0] + "'";
      }
      else // Both exist
      {
        sQuery = sQuery + "gu_company,gu_contact) SELECT '" + request.getParameter("gu_list") + "',tx_email,tx_name,tx_surname,dt_created,gu_company,gu_contact FROM "+DB.k_member_address+" WHERE gu_contact='" + aMember[1] + " AND gu_company =" + aMember[0] + "'";
      }
    
    oConn.setAutoCommit (true);

    try {
      statement = oConn.prepareStatement(sQuery);    
      statement.executeUpdate();
      oConn.close("memberinsert"); 
    } catch (SQLException xcpt) {
      try { if (null!=statement) statement.close(); } catch (Exception ignore) { }
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=(gu_list="+request.getParameter("gu_list")+") " + e.getLocalizedMessage() + "&resume=_close"));
      if (!oConn.isClosed()) oConn.close("memberinsert"); 
      oConn = null;
    }
  }

  if (null==oConn) return;
  oConn = null;

%><HTML>
  <HEAD>
    <TITLE>Wait...</TITLE>
  </HEAD>
  <BODY>
    <script>
     window.opener.location.reload();
     self.close();
    </script>
  </BODY>
</HTML>