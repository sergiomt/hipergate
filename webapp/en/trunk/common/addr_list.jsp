<%@ page import="java.net.URLDecoder,java.util.HashMap,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
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

  if (sLinkTable.equals("k_x_contact_addr") || sLinkTable.equals("k_meetings_lookup"))
    nm_company = "";
  else
    nm_company = request.getParameter("nm_company");
  
  // Mapa para recuperar las etiquetas de tipos de ubicación a partir de sus códigos
  HashMap oLocationTypes = null;
  
  // Cadena de de filtrado (claúsula WHERE)
        
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  int iAddressCount = 0;
  DBSubset oAddresses = null;        
  Object[] aFind = { '%' + sFind + '%' };
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
    
    oConn = GlobalDBBind.getConnection("addresslisting");  

    // Si el filtro no existe devolver todos los registros
    if (sFind.length()==0) {
      if (sLinkTable.equals("k_meetings_lookup"))
        oAddresses = new DBSubset (DB.k_addresses + " a," + DB.k_meetings_lookup+ " x",
      				                     "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.nm_street + ",a." + DB.mn_city + ",a." + DB.tx_email + ",a." + DB.work_phone + ",a." + DB.direct_phone + ",a." + DB.direct_phone + ",a." + DB.home_phone + ",a." + DB.mov_phone + ",a." + DB.nm_company,
      				                     "x." + sLinkField + "='" + sLinkValue + "' AND a." + DB.gu_address + "=x." + DB.vl_lookup + " AND a." + DB.gu_workarea + "='" + gu_workarea + "' ORDER BY " + sOrderBy, iMaxRows);      				 
      else
        oAddresses = new DBSubset (DB.k_addresses + " a," + sLinkTable + " x",
      				                     "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.nm_street + ",a." + DB.mn_city + ",a." + DB.tx_email + ",a." + DB.work_phone + ",a." + DB.direct_phone + ",a." + DB.direct_phone + ",a." + DB.home_phone + ",a." + DB.mov_phone + ",a." + DB.nm_company,
      				                     "x." + sLinkField + "='" + sLinkValue + "' AND a." + DB.gu_address + "=x." + DB.gu_address + " AND a." + DB.gu_workarea + "='" + gu_workarea + "' ORDER BY " + sOrderBy, iMaxRows);      				 
      oAddresses.setMaxRows(iMaxRows);
      iAddressCount = oAddresses.load (oConn, iSkip);
    }
    else {
      // De momento no hay listados con filtro
    }    
        
    // Cargar un mapa de códigos y etiquetas traducidas de tipos de ubicacion
    oLocationTypes = GlobalDBLang.getLookUpMap((java.sql.Connection) oConn, DB.k_addresses_lookup, gu_workarea, "tp_location", sLanguage);
    
    oConn.close("addresslisting"); 
  }
  catch (SQLException e) {  
    oAddresses = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("addresslisting");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Address Listing</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/findit.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        <%
          // Escribir los guids de las direcciones en Arrays JavaScript
          // Estos arrays se usan en las llamadas de borrado múltiple.
          
          out.write("var jsAddresses = new Array(");
            for (int i=0; i<iAddressCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oAddresses.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createAddress() {
          self.open("../common/addr_edit_f.jsp?nm_company=" + escape("<%=nm_company%>") + "&linktable=" + getURLParam("linktable") + "&linkfield=" + getURLParam("linkfield") + "&linkvalue=" + getURLParam("linkvalue"), "editcompaddr", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
		  
	} // createAddress()

        // ----------------------------------------------------

	function deleteAddresses() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to delete selected addresses?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "addr_edit_delete.jsp";
	  	  
	    for (var i=0;i<jsAddresses.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsAddresses[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
	      
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteAddresses()
	
	
        // ----------------------------------------------------

	function modifyAddress(id,nm) {
          self.open("../common/addr_edit_f.jsp?gu_address=" + id + "&nm_company=" + nm + "&linktable=" + getURLParam("linktable") + "&linkfield=" + getURLParam("linkfield") + "&linkvalue=" + getURLParam("linkvalue"), "editcompaddr", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
	}	
	
    //-->    
  </SCRIPT>  
</HEAD>

<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <FORM METHOD="post">
  <DIV class="cxMnu1" style="width:300px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
      <TABLE WIDTH="95%">
        <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4"></TD></TR>
        <TR><TD CLASS="striptitle"><FONT CLASS="title1">Address Listing&nbsp;<%=(null!=request.getParameter("nm_company") ? " of&nbsp;" + request.getParameter("nm_company") : "")%></FONT></TD></TR>
      </TABLE>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="7" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
          <TD VALIGN="middle">
<% if (bIsGuest) { %>
            <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New</A>
<% } else { %>
            <A HREF="#" onclick="createAddress()" CLASS="linkplain">New</A>
<% } %>
          </TD>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
          <TD>
<% if (bIsGuest) { %>
            <A HREF="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
            <A HREF="javascript:deleteAddresses()" CLASS="linkplain">Delete</A>
<% } %>
          </TD>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
          <TD><INPUT TYPE="text" NAME="find" MAXLENGTH="50"></TD>
          <TD><A HREF="#" onclick="findit(document.forms[0].find.value)" CLASS="linkplain">Search</A></TD>
         </TR>
        <TR><TD COLSPAN="7" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>      
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Type</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>&nbsp;Location</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>&nbsp;City</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>&nbsp;e-mail</B></TD>                    
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>&nbsp;Telephone</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp</TD>
        </TR>
	<%
	  String sAddrId;
	  String sAddrTp;
	  String sAddrSt;
	  String sAddrCt;
	  String sAddrEm;
	  String sAddrCm;
	  Object oAddrPh;

	  for (int i=0; i<iAddressCount; i++) {
            sAddrId = oAddresses.getString(0,i);
            sAddrTp = oAddresses.getStringNull(1,i,"");
            if (sAddrTp.length()>0 && oLocationTypes!=null) {
              if (oLocationTypes.containsKey(sAddrTp))
                sAddrTp = oLocationTypes.get(sAddrTp).toString();              
            }
            sAddrSt = oAddresses.getStringNull(2,i,"* N/A *");
            if (sAddrSt.length()==0) sAddrSt = "* N/A *";
            sAddrCt = oAddresses.getStringNull(3,i,"");
            sAddrEm = oAddresses.getStringNull(4,i,"");
            if (sAddrEm.length()>0) sAddrEm = "<A HREF=\"mailto:" + sAddrEm + "\" TITLE=\"Send Message\">" + sAddrEm + "</A>";
            oAddrPh = null;
            for (int c=5; c<=9 && null==oAddrPh; c++)
              oAddrPh = oAddresses.get(c,i);
            sAddrCm = oAddresses.getStringNull(10,i,"");
             
            out.write ("<TR HEIGHT=\"14\">");
            out.write ("<TD CLASS=\"tabletd\">&nbsp;" + sAddrTp + "</TD>");
            out.write ("<TD CLASS=\"tabletd\">&nbsp;<A HREF=\"#\" onclick=\"modifyAddress('" + sAddrId + "','"+Gadgets.URLEncode(sAddrCm)+"')\" TITLE=\"Edit this address\">" + sAddrSt + "</A></TD>");
            out.write ("<TD CLASS=\"tabletd\">&nbsp;" + sAddrCt + "</TD>");
            out.write ("<TD CLASS=\"tabletd\">&nbsp;" + sAddrEm + "</TD>");
            out.write ("<TD CLASS=\"tabletd\">&nbsp;" + (oAddrPh==null ? "" : oAddrPh) + "</TD>");
            out.write ("<TD CLASS=\"tabletd\" ALIGN=\"center\"><INPUT VALUE=\"" + sAddrId + "\" TYPE=\"checkbox\" NAME=\"checkbox-" + i + "\">");
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
      out.write("<A HREF=\"addr_list.jsp?linktable=" + sLinkTable + "&linkfield=" + sLinkField + "&linkvalue=" + sLinkValue + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip-iMaxRows)+ "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;" + String.valueOf(iMaxRows) + "&nbsp;Previous " + "</A>&nbsp;&nbsp;&nbsp;");
    
    if (!oAddresses.eof())
      out.write("<A HREF=\"addr_list.jsp?linktable=" + sLinkTable + "&linkfield=" + sLinkField + "&linkvalue=" + sLinkValue + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip+iMaxRows)+ "\" CLASS=\"linkplain\">Next " + String.valueOf(iMaxRows) + "&nbsp;&gt;&gt;</A>");
    %>
</BODY>
</HTML>
