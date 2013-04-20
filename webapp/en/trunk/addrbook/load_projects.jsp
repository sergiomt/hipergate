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
  String sGuUser = request.getParameter("gu_user");
  String sGuFellow = request.getParameter("gu_fellow");
  String sGuContact = request.getParameter("gu_contact");
  String sGuWorkArea = request.getParameter("gu_workarea");
    
  DBSubset oProjects = new DBSubset(DB.k_projects,
    			             DB.gu_project + "," + DB.nm_project,
    			   	         DB.gu_owner+"=? AND (" + DB.gu_contact + "=? OR " + DB.gu_company + " IN (SELECT "+DB.gu_company+" FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?))",
    			   	         50);

  DBSubset oBugs = new DBSubset(DB.k_bugs,
    			            DB.gu_bug + "," + DB.pg_bug + "," + DB.tl_bug,
    			   	    "(" + DB.tx_status + " IS NULL OR " + DB.tx_status + " IN ('EN ESPERA','PENDIENTE')) AND (" + DB.gu_writer + "=? OR " + DB.nm_assigned + "=? OR " + DB.gu_writer + "=? OR " + DB.nm_assigned + "=? OR " + DB.gu_project + " IN (SELECT " + DB.gu_project + " FROM " + DB.k_projects + " WHERE " + DB.gu_owner + "=? AND (" + DB.gu_contact + "=? OR " + DB.gu_company + " IN (SELECT " + DB.gu_company + " FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?))))",
    			   	    50);
    			   	      
  JDCConnection oConn = null;
  int iProjects = 0, iBugs = 0; 
  try {
    oConn = GlobalDBBind.getConnection("loadcontacts");

    oProjects.setMaxRows(100);

    iProjects = oProjects.load(oConn, new Object[]{sGuWorkArea,sGuContact,sGuContact});

    iBugs = oBugs.load(oConn, new Object[]{sGuFellow,sGuFellow,sGuUser,sGuUser,sGuWorkArea,sGuContact,sGuContact});
          
    oConn.close("loadprojects");

    oConn = null;

    for (int c=0; c<iProjects; c++) {
      out.write("    opt = doc.createElement(\"OPTION\");\n");
      out.write("    opt.value = \"" + oProjects.getString(0,c) + "\";\n");
      out.write("    opt.text = \"" + oProjects.getStringNull(1,c,"") + "\";\n");
      out.write("    frm.sel_project.options.add(opt);\n");
    } // next c

    for (int b=0; b<iBugs; b++) {
      out.write("    opt = doc.createElement(\"OPTION\");\n");
      out.write("    opt.value = \"" + oBugs.getString(0,b) + "\";\n");
      out.write("    opt.text = \"" + String.valueOf(oBugs.getInt(1,b)) + " - " + oBugs.getString(2,b) + "\";\n");
      out.write("    frm.sel_bugs.options.add(opt);\n");    
    }
    
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("loadprojects");

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));  
  }  
%>

  if (frm.sel_project.options.length>0)
    if ("COMBOLOADING"==frm.sel_project.options[0].value)
      frm.sel_project.options[0] = null;

  if (frm.sel_bugs.options.length>0)
    if ("COMBOLOADING"==frm.sel_bugs.options[0].value)
      frm.sel_bugs.options[0] = null;

  //self.document.location.href = "../blank.htm";
  } //-->
</SCRIPT>
</HEAD>
<BODY onLoad="setList()">
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>