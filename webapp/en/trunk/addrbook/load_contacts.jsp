<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%
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
%>
<HTML>
<HEAD>
<SCRIPT TYPE="text/javascript">
  <!--
  function setList() {
    var doc = parent.frames[0].document;
        
    var frm = doc.forms[0];
    var opt;    

<%
  String sFind = request.getParameter("find");
  String sGuid = request.getParameter("guid");
  String sCtrl = request.getParameter("control");
  String sMaxr = request.getParameter("max_rows");
  if (sCtrl==null) sCtrl = "sel_users";
  if (sMaxr==null) sMaxr = "100";

  DBSubset oContacts = null;
  
  if (null==sFind && null==sGuid)
    oContacts = new DBSubset(DB.k_contacts, DB.gu_contact + "," + DB.tx_name + "," + DB.tx_surname, DB.gu_workarea + "='" + request.getParameter("gu_workarea") + "' ORDER BY 2,3", 100);
  else if (null==sFind)
    oContacts = new DBSubset(DB.k_contacts,
    			     DB.gu_contact + "," + DB.tx_name + "," + DB.tx_surname,
    			     DB.gu_workarea + "=? AND " + DB.gu_contact + "=? ORDER BY 2,3", 100);  
  else
    oContacts = new DBSubset(DB.k_contacts,
    			     DB.gu_contact + "," + DB.tx_name + "," + DB.tx_surname,
    			     DB.gu_workarea + "=? AND (" + DB.tx_name + " LIKE ? OR " + DB.tx_surname + " LIKE ?) ORDER BY 2,3", 100);  
  	
  oContacts.setMaxRows(Integer.parseInt(sMaxr));
  
  JDCConnection oConn = null;  
  int iContacts = 0; 
  try {
    oConn = GlobalDBBind.getConnection("loadcontacts");
    
    if (null==sFind && null==sGuid)
      iContacts = oContacts.load(oConn);
    else if (null==sFind)
      iContacts = oContacts.load(oConn, new Object[]{request.getParameter("gu_workarea"),sGuid});
    else
      iContacts = oContacts.load(oConn, new Object[]{request.getParameter("gu_workarea"),"%"+sFind+"%","%"+sFind+"%"});
          
    oConn.close("loadcontacts");

    oConn = null;

    for (int c=0; c<iContacts; c++) {
      out.write("    opt = doc.createElement(\"OPTION\");\n");
      out.write("    opt.value = \"" + oContacts.getString(0,c) + "\";\n");
      out.write("    opt.text = \"" + oContacts.getStringNull(1,c,"") + " " + oContacts.getStringNull(2,c,"") + "\";\n");
      out.write("    frm."+sCtrl+".options.add(opt);\n");    
    } // next c
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("loadcontacts");

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));  
  }  
%>

  if (frm.<%=sCtrl%>.options.length>0)
    if ("COMBOLOADING"==frm.<%=sCtrl%>.options[0].value)
      frm.<%=sCtrl%>.options[0] = null;

  self.document.location.href = "../blank.htm";
  } //-->
</SCRIPT>
</HEAD>
<BODY onLoad="setList()">
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>