
<%@ page import="java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/nullif.jspf" %><%
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
<SCRIPT SRC="../javascript/combobox.js"></SCRIPT> 
<SCRIPT TYPE="text/javascript">
<!--
<% 
  String gu_workarea = request.getParameter("gu_workarea");
  String id_language = request.getParameter("id_language");
  String id_section = request.getParameter("id_section");
  String nm_control = request.getParameter("control");
  String onload = request.getParameter("onload");
  String id_form = nullif(request.getParameter("id_form"), "0");
  if (id_form.length()==0) id_form="0";
  String set_value = request.getParameter("set_value");
%>
  var doc = parent.frames[0].document;
  var frm = doc.forms[<%=id_form%>];
  var opt;
<%  
  JDCConnection oConn = GlobalDBBind.getConnection("addr_load");  
  Statement oStmt;
  ResultSet oRSet;
  String sErrMsg = "";
  String sSQL = "SELECT " + DB.vl_lookup + "," + DBBind.Functions.ISNULL + "(" + DB.tr_ + id_language + ",'') FROM " +  DB.k_addresses_lookup + " WHERE " + DB.gu_owner + "='" + gu_workarea + "' AND " + DB.id_section + "='" + id_section + "'";    
  String sVal;
  String sTr;

  out.write("  opt = doc.createElement(\"OPTION\");\n");
  out.write("  opt.value = \"\";\n");
  out.write("  opt.text = \"\";\n");
  out.write("  frm." + nm_control  + ".options.add(opt);\n");
  
  try {
    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oRSet = oStmt.executeQuery(sSQL);
    
    while (oRSet.next()) {
      sVal = oRSet.getString(1);
      sTr = oRSet.getString(2);
      if (sTr.length()>0) {
        out.write("  opt = doc.createElement(\"OPTION\");\n");
        out.write("  opt.value = \"" + sVal + "\";\n");
        out.write("  opt.text = \"" + sTr + "\";\n");
        out.write("  frm." + nm_control  + ".options.add(opt);\n");
      } // fi(sTr)      
    } // wend()
    
    oRSet.close();
    oStmt.close();
    
    if (set_value!=null)
      out.write("  setCombo(frm." + nm_control + ",\"" + set_value + "\");\n");

    oConn.close("addr_load");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("addr_load");      
    sErrMsg = e.getMessage();    
  }
  oConn = null;
  
  if (onload!=null) out.write("  window.parent.frames[0]."+onload+"();\n");
%>
//-->
</SCRIPT>
<TITLE>hipergate :: Load addresses</TITLE>
</HEAD>
<BODY><%="<!--" + sSQL + "-->\n" + sErrMsg%></BODY>
</HTML>
