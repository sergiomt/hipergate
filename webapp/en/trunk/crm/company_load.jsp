 <%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.Company,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
      
  String gu_workarea = request.getParameter("gu_workarea");

  String nm_sector = "", nu_employees = "", im_revenue = "", de_company = "";

  JDCConnection oConn = null;  
  Company oComp = new Company();
  
  boolean bFound = false;
    
  try {
    oConn = GlobalDBBind.getConnection("company_load");

    bFound = oComp.load (oConn, new Object[]{request.getParameter("gu_company")});

    if (bFound) {
      if (!oComp.isNull(DB.id_sector))
        nm_sector = DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_companies_lookup, gu_workarea, "id_sector", getNavigatorLanguage(request), oComp.getString(DB.id_sector));

      if (!oComp.isNull(DB.nu_employees))
        nu_employees = String.valueOf(oComp.getInt(nu_employees));

      if (!oComp.isNull(DB.im_revenue))
        im_revenue = String.valueOf(oComp.getFloat(im_revenue));
        
      de_company = oComp.getStringNull(DB.de_company, "");
      
      if (de_company.length()!=0) {
        StringBuffer oStrDe = new StringBuffer(de_company.length()+10);
        
        for (int i=0; i<de_company.length(); i++) {
          if (de_company.charAt(i)==10)
            oStrDe.append("\\n");
          else if (de_company.charAt(i)!=13)
            oStrDe.append(de_company.charAt(i));
        }
        de_company = oStrDe.toString();
        
        de_company.replace('"', ' ');
      }
    }
        
    oConn.close("company_load");
    
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"company_load");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

  if (!bFound) return;
%>
<HTML>
  <HEAD>
    <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
    <!--
	var frm = window.parent.contacttext.document.forms[1];
	
	frm.nm_legal.value = "<% out.write(oComp.getString(DB.nm_legal)); %>";

	frm.nm_commercial.value = "<% out.write(oComp.getStringNull(DB.nm_commercial, "")); %>";

	frm.id_sector.value = "<% out.write(oComp.getStringNull(DB.id_sector, "")); %>";

	frm.nm_sector.value = "<% out.write(nullif(nm_sector)); %>";
  
	frm.id_legal.value = "<% out.write(oComp.getStringNull(DB.id_legal, "")); %>";

	frm.nu_employees.value = "<% out.write(nu_employees); %>";

	frm.im_revenue.value = "<% out.write(im_revenue); %>";

	frm.dt_founded.value = "<% out.write(nullif(oComp.getDateFormated(DB.dt_founded,"yyyy-MM-dd"))); %>";

	frm.de_company.value = "<% out.write(de_company); %>";

	setCombo (frm.sel_typecompany, "<% out.write(oComp.getStringNull(DB.tp_company, "")); %>");
    //-->
    </SCRIPT>    
    <!--<META http-equiv="refresh" content="0; url=../blank.htm">-->
  </HEAD>
</HTML>