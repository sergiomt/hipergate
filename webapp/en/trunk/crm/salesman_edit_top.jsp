<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
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
  String gu_sales_man = request.getParameter("gu_sales_man");
  String n_sales_man = request.getParameter("n_sales_man");

  JDCConnection oConn = null;  
  StringBuffer oStrBuff = new StringBuffer();
    
  try {
    oConn = GlobalDBBind.getConnection("salesman_edit_f");
    
    Statement oStmt = oConn.createStatement();
    ResultSet oRSet = oStmt.executeQuery("SELECT tx_year FROM " + DB.k_sales_objectives + " WHERE " + DB.gu_sales_man + "='" + gu_sales_man + "' ORDER BY 1 DESC");
    
    while (oRSet.next()) {
      oStrBuff.append ("<OPTION VALUE=\"" + oRSet.getString(1) + "\">");
      oStrBuff.append (oRSet.getString(1));
      oStrBuff.append ("</OPTION>");      
    }
      
    oStmt.close();
    oRSet.close();
          
    oConn.close("salesman_edit_f");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"salesman_edit_f");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;
%>
<HTML>
  <HEAD>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>    
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

    function deleteYear() {
      var frm = document.forms[0];
    
      if (frm.sel_year.options.selectedIndex != -1) {
        if (window.confirm("Are you sure that you want to delete year " + getCombo(frm.sel_year)))
          // top.frames['yearobjectives'].document.location = "salesman_year_delete.jsp?gu_sales_man=<%=gu_sales_man%>&tx_year=" + getCombo(frm.sel_year) + "&n_sales_man=" + escape("<%=n_sales_man%>");
          var u = "salesman_year_delete.jsp?gu_sales_man=<%=gu_sales_man%>&n_sales_man=<%=(com.knowgate.misc.Gadgets.URLEncode(n_sales_man))%>&tx_year=" + getCombo(frm.sel_year);
          top.frames['yearobjectives'].document.location = u;

      }
    }
        
    function showYear(y) {
      var u = "salesman_year.jsp?gu_sales_man=<%=gu_sales_man%>&n_sales_man=<%=(com.knowgate.misc.Gadgets.URLEncode(n_sales_man))%>&tx_year=" + y;
      top.frames['yearobjectives'].document.location = u;
    }

    function newYear() {
      var frm = document.forms[0];
    
      if (hasForbiddenChars(frm.tx_year.value)) {
        alert ("Year contains invalid characters");
	return;
      }
      
      if (comboIndexOf (frm.sel_year, frm.tx_year.value) != -1) {
        alert ("Year already exists");
      }
      else {
  	frm.sel_year.options[frm.sel_year.options.length] = new Option(frm.tx_year.value, frm.tx_year.value, true, true);
        showYear(frm.tx_year.value);        
      }      
    }
    
    function setCombo() {
      var frm = document.forms[0];
      
      if (frm.sel_year.options.length>0) {
        frm.sel_year.options.selectedIndex = 0;
	showYear(frm.sel_year.options[0].value);
      }            
    }
    
    //-->
    </SCRIPT>    
  </HEAD>  
  <BODY  LEFTMARGIN="8" TOPMARGIN="0" MARGINHEIGHT="0" onload="setCombo()">
    <FORM onSubmit="return false">
    <TABLE WIDTH="100%">
      <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
      <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Sales Objectives&nbsp;<% out.write(n_sales_man); %></FONT></TD></TR>
    </TABLE>
      <TABLE WIDTH="100%">
        <TR>
          <TD>
            <FONT CLASS="formstrong">Year&nbsp;</FONT><SELECT NAME="sel_year" onchange="showYear(getCombo(this))"><% out.write(oStrBuff.toString()); %></SELECT><INPUT TYPE="button" CLASS="closebutton" VALUE="Delete" STYLE="width:80px" onclick="deleteYear()">
          </TD>
          <TD ALIGN="right">
            <FONT CLASS="formstrong">Create New Year&nbsp;</FONT><INPUT TYPE="text" MAXLENGTH="10" SIZE="6" NAME="tx_year">
            <INPUT TYPE="button" CLASS="pushbutton" VALUE="New" STYLE="width:80px" onclick="newYear()">
          </TD>
        </TR>
      </TABLE>
    </FORM>
  </BODY>
</HTML>