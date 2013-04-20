<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
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
 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // Obtener el idioma del navegador cliente
  String sLanguage = getNavigatorLanguage(request);

  // Obtener el skin actual
  String sSkin = getCookie(request, "skin", "default");

  // Obtener el dominio y la workarea
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null);
  
  // Obtener el nombre de la tabla para cruzar direcciones con su objeto padre que las contiene
  String sLinkTable = request.getParameter("linktable")==null ? "" : request.getParameter("linktable");
  // Obtener el nombre del campo de cruce y su valor
  String sLinkField = request.getParameter("linkfield")==null ? "" : request.getParameter("linkfield");
  String sLinkValue = request.getParameter("linkvalue")==null ? "" : request.getParameter("linkvalue");

  String sOrderBy = request.getParameter("orderby")==null ? "3" : request.getParameter("orderby");

  String nm_company;

  if (sLinkTable.equals("k_x_contact_bank"))
    nm_company = "";
  else
    nm_company = request.getParameter("nm_company");
  
  int iBankAccountCount = 0;
  DBSubset oBankAccounts = null;        
  int iMaxRows;
  int iSkip;
    
  if (request.getParameter("maxrows")!=null)
    iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
  else
    iMaxRows = 10;

  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  // Obtener una conexión del pool a bb.dd. (el nombre de la conexión es arbitrario)
  JDCConnection oConn = null;  
  
  boolean bIsGuest = true;
  
  try {

    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("bankaccountlisting");  

    oBankAccounts = new DBSubset (DB.k_bank_accounts + " a," + sLinkTable + " x",
      				 "a.nm_bank, a.tx_addr, a.nu_bank_acc, a.im_credit_limit",      				 
      				 "x." + sLinkField + "='" + sLinkValue + "' AND a.nu_bank_acc=x.nu_bank_acc AND a." + DB.gu_workarea + "='" + gu_workarea + "' ORDER BY " + sOrderBy, iMaxRows);      				 
     
     oBankAccounts.setMaxRows(iMaxRows);
     
     iBankAccountCount = oBankAccounts.load (oConn, iSkip);
  
     oConn.close("bankaccountlisting"); 
  }
  catch (SQLException e) {  
    oBankAccounts = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("bankaccountlisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Bank Account List</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        <%
          // Escribir los guids de las direcciones en Arrays JavaScript
          // Estos arrays se usan en las llamadas de borrado múltiple.
          
          out.write("var jsBankAccounts = new Array(");
            for (int i=0; i<iBankAccountCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oBankAccounts.getString(2,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createBankAccount() {          
          window.open("../common/bank_edit.jsp?nm_company=" + escape("<%=nm_company%>") + "&linktable=" + getURLParam("linktable") + "&linkfield=" + getURLParam("linkfield") + "&linkvalue=" + getURLParam("linkvalue"),
                      "editcompbank", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
	} // createBankAccount()

        // ----------------------------------------------------

	function deleteBankAccounts() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to delete selected accounts?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "bank_edit_delete.jsp";
	  	  
	    for (var i=0;i<jsBankAccounts.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsBankAccounts[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
	      
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteBankAccounts()
	
	
        // ----------------------------------------------------

	function modifyBankAccount(id) {
          self.open("../common/bank_edit.jsp?nu_bank_acc=" + id + "&nm_company=" + escape("<%=nm_company%>") + "&linktable=" + getURLParam("linktable") + "&linkfield=" + getURLParam("linkfield") + "&linkvalue=" + getURLParam("linkvalue"), "editcompbank", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
	}	
	
    //-->    
  </SCRIPT>  
</HEAD>

<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <FORM METHOD="post">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
      <TABLE WIDTH="95%">
        <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4"></TD></TR>
        <TR><TD CLASS="striptitle"><FONT CLASS="title1">Bank Account List&nbsp;<%=(null!=request.getParameter("nm_company") ? "&nbsp;-&nbsp;" + request.getParameter("nm_company") : "")%></FONT></TD></TR>
      </TABLE>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
          <TD VALIGN="middle">
<% if (bIsGuest) { %>
            <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New</A>
<% } else { %>
            <A HREF="#" onclick="createBankAccount()" CLASS="linkplain">New</A>
<% } %>
          </TD>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Remove"></TD>
          <TD>
<% if (bIsGuest) { %>
            <A HREF="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Remove</A>
<% } else { %>
            <A HREF="javascript:deleteBankAccounts()" CLASS="linkplain">Remove</A>
<% } %>
          </TD>
         </TR>
        <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>      
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Bank</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>&nbsp;Address</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>&nbsp;Account</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>&nbsp;Credit</B></TD>                   
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp</TD>
        </TR>
	<%
	  String sBankNm,sTxAddr,sBankNu,sCredit;

	  for (int i=0; i<iBankAccountCount; i++) {  				 

            sBankNm = oBankAccounts.getStringNull(0,i,"* N/A *");
            sTxAddr = oBankAccounts.getStringNull(1,i,"");
            sBankNu = oBankAccounts.getString(2,i);
            if (!oBankAccounts.isNull(3,i))            
              sCredit = String.valueOf(oBankAccounts.getDecimal(3,i).longValue());
            else
              sCredit = "";
              
            out.write ("<TR HEIGHT=\"14\">");
            out.write ("<TD CLASS=\"tabletd\">&nbsp;" + sBankNm + "</TD>");
            out.write ("<TD CLASS=\"tabletd\">&nbsp;" + sTxAddr + "</TD>");
            out.write ("<TD CLASS=\"tabletd\">&nbsp;<A HREF=\"#\" onclick=\"modifyBankAccount('" + sBankNu + "')\" TITLE=\"Edit this Account\">" + sBankNu + "</A></TD>");
            out.write ("<TD CLASS=\"tabletd\" ALIGN=\"right\">&nbsp;" + sCredit + "</TD>");
            out.write ("<TD CLASS=\"tabletd\" ALIGN=\"center\"><INPUT VALUE=\"" + sBankNu + "\" TYPE=\"checkbox\" NAME=\"checkbox-" + i + "\">");
            out.write ("</TR>");
          }
	%>          	  
      </TABLE>
      <BR>
      <CENTER><INPUT TYPE="button" CLASS="closebutton" VALUE="Close Window" onClick="self.close()"></CENTER>      
    </FORM>
    <%
    // Pintar los enlaces de siguiente y anterior
    
    if (iSkip>0) // Si iSkip>0 entonces hay registros anteriores
      out.write("<A HREF=\"bank_list.jsp?linktable=" + sLinkTable + "&linkfield=" + sLinkField + "&linkvalue=" + sLinkValue + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip-iMaxRows)+ "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;" + String.valueOf(iMaxRows) + "&nbsp;Previous " + "</A>&nbsp;&nbsp;&nbsp;");
    
    if (!oBankAccounts.eof())
      out.write("<A HREF=\"bank_list.jsp?linktable=" + sLinkTable + "&linkfield=" + sLinkField + "&linkvalue=" + sLinkValue + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip+iMaxRows)+ "\" CLASS=\"linkplain\">Next " + String.valueOf(iMaxRows) + "&nbsp;&gt;&gt;</A>");
    %>
</BODY>
</HTML>
