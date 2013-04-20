<%@ page import="java.net.URLDecoder,java.io.IOException,java.io.FileNotFoundException,java.io.File,com.knowgate.acl.*,com.knowgate.misc.*,com.knowgate.crm.DirectList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  // obtener el idioma del navegador cliente
  String sLanguage = getNavigatorLanguage(request);

  // Obtener el skin actual
  String sSkin = getCookie(request, "skin", "default");

  // Obtener el directorio /tmp
  String sTempDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTempDir = com.knowgate.misc.Gadgets.chomp(sTempDir,java.io.File.separator);
    
  // Resolucion de pantalla en el cliente
  int iScreenWidth;
  float fScreenRatio;

  // Obtener el dominio y la workarea
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain"); 
  String gu_workarea = request.getParameter("gu_workarea"); 
  String tp_list = request.getParameter("tp_list");
  String gu_query = request.getParameter("gu_query");
  String desc_file = request.getParameter("desc_file");
  String id_encoding = request.getParameter("sel_encoding");
  
  // URL para volver al paso 2 si se produce un error
  String sRedirect2URL = Gadgets.URLEncode("../crm/list_wizard_d2.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&gu_workarea=" + gu_workarea + "&tp_list=" + tp_list + "&gu_query=" + gu_query);
  
  File oTmpFile;
  int Checks[] = null;
  DirectList oList = new DirectList(id_encoding);

  try {
    Checks = oList.parseFile(sTempDir + request.getParameter("gu_query") + ".tmp", request.getParameter("desc_file"));
  }
  catch (FileNotFoundException e) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=File not found&desc=" + e.getMessage() + "&resume=" + sRedirect2URL));
    oList = null;  
  }
  catch (IOException e) {  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Internal input-output error&desc=" + e.getMessage() + "&resume=" + sRedirect2URL));
    oList = null;  
  }
  catch (ArrayIndexOutOfBoundsException e) {
    oTmpFile = new File(sTempDir + request.getParameter("gu_query") + ".tmp"); 
    oTmpFile.delete();
    oTmpFile = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Index out of range&desc=El número de columnas del fichero en la línea " + String.valueOf(oList.errorLine()) + " no coincide con las especificadas en el paso 2&resume=" + sRedirect2URL));
    oList = null;  
  }
  catch (IllegalStateException e) {  
    oTmpFile = new File(sTempDir + request.getParameter("gu_query") + ".tmp"); 
    oTmpFile.delete();
    oTmpFile = null;
    oList = null;  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=File is empty&desc=El fichero que especifico para cargar la lista esta vacio&resume=" + sRedirect2URL));
  }
  catch (RuntimeException e) {  
    oTmpFile = new File(sTempDir + request.getParameter("gu_query") + ".tmp"); 
    oTmpFile.delete();
    oTmpFile = null;
    oList = null;  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error processing input file&desc=" + e.getMessage() + "&resume=" + sRedirect2URL));
  }

  if (null==oList) return;
  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Direct loading of e-mails</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/findit.js"></SCRIPT>  
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
    <FORM METHOD="get" ACTION="list_wizard_store.jsp">
      <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Direct loading of e-mails</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="caller" VALUE="wizard">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="tp_list" VALUE="<%=tp_list%>">
      <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=Gadgets.generateUUID()%>">
<%    if (desc_file.indexOf("\"")>=0) { %>
      <INPUT TYPE="hidden" NAME="desc_file" VALUE='<%=desc_file%>'>
<%    } else { %>
      <INPUT TYPE="hidden" NAME="desc_file" VALUE="<%=desc_file%>">
<%    } %>
      <INPUT TYPE="hidden" NAME="gu_query" VALUE="<%=gu_query%>">
      <INPUT TYPE="hidden" NAME="tx_sender" VALUE="<%=request.getParameter("tx_sender")%>">
      <INPUT TYPE="hidden" NAME="tx_from" VALUE="<%=request.getParameter("tx_from")%>">
      <INPUT TYPE="hidden" NAME="tx_reply" VALUE="<%=request.getParameter("tx_reply")%>">
      <INPUT TYPE="hidden" NAME="tx_sender" VALUE="<%=request.getParameter("tx_sender")%>">
      <INPUT TYPE="hidden" NAME="tx_subject" VALUE="<%=request.getParameter("tx_subject")%>">
      <INPUT TYPE="hidden" NAME="de_list" VALUE="<%=request.getParameter("de_list")%>">
      
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <INPUT NAME="findstr" CLASS="combomini">
	  &nbsp;<A HREF="javascript:if (document.forms[0].findstr.value.length>0) findit(document.forms[0].findstr.value);" CLASS="linkplain" TITLE="Buscar">Search</A>	  
        </TD>
      </TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
<%
      int iValid = 0;
      int iRows = oList.getLineCount();
      
      for (int v=0; v<iRows; v++)
        if (DirectList.CHECK_OK==Checks[v]) iValid++;      
%>    
      <BR>
      <FONT CLASS="textplain"><B>You are about to load&nbsp;<% out.write(String.valueOf(iValid)); %> addresses from a total of&nbsp;<% out.write(String.valueOf(iRows)); %></B>
      &nbsp;&nbsp;&nbsp;&nbsp;
      <INPUT CLASS="pushbutton" TYPE="submit" VALUE="Load">&nbsp;&nbsp;&nbsp;&nbsp;<INPUT CLASS="closebutton" TYPE="button" VALUE="Cancel" onclick="window.document.location='list_wizard_cancel.jsp?tp_list=<%=tp_list%>&gu_query=<%=gu_query%>';">
      <BR><BR>
      <TABLE CELLSPACING="1" CELLPADDING="0" WIDTH="100%">

        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>e-mail</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Surname</B></TD>
          <TD CLASS="tableheader" WIDTH="120px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Status</B></TD>

<%
	  int iMail = oList.getColumnPosition("tx_email");
	  int iName = oList.getColumnPosition("tx_name");
	  int iSurN = oList.getColumnPosition("tx_surname");
	  int iSalt = oList.getColumnPosition("tx_salutation");
	  String sStrip;
  	  	  
	  for (int i=0; i<iRows; i++) {
	    sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write((i%2)+1); %>">&nbsp;<FONT CLASS="textsmall"><% out.write(oList.getField(iMail,i)); %></FONT></TD>
              <TD CLASS="strip<% out.write((i%2)+1); %>">&nbsp;<FONT CLASS="textsmall"><% if (-1!=iName) out.write(oList.getField(iName,i)); %></FONT></TD>
              <TD CLASS="strip<% out.write((i%2)+1); %>">&nbsp;<FONT CLASS="textsmall"><% if (-1!=iSurN) out.write(oList.getField(iSurN,i)); %></FONT></TD>
	      <TD CLASS="strip<% out.write((i%2)+1); %>">
<%
	      switch (Checks[i]) {
	        case DirectList.CHECK_OK:
	          out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=green>OK</FONT></FONT>");
		  break;
	        case DirectList.CHECK_INVALID_EMAIL:
		  out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=red>invalid e-mail</FONT></FONT>");
		  break;
	        case DirectList.CHECK_NAME_TOO_LONG:
		  out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=red>Name is too long</FONT></FONT>");
		  break;
	        case DirectList.CHECK_SURNAME_TOO_LONG:
		  out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=red>Surname is too long</FONT></FONT>");
		  break;
	        case DirectList.CHECK_INVALID_FORMAT:
		  out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=red>Format must be either TXT or HTML</FONT></FONT>");
		  break;
	        case DirectList.CHECK_SALUTATION_TOO_LONG:
		  out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=red>Salutation is too long</FONT></FONT>");
		  break;	        	        
	        case DirectList.CHECK_INVALID_NAME:
		  out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=red>The name contains invalid characters</FONT></FONT>");
		  break;
	        case DirectList.CHECK_INVALID_SURNAME:
		  out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=red>Surname contains invalid characters</FONT></FONT>");
		  break;
	        case DirectList.CHECK_INVALID_SALUTATION:
		  out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=red>Salutation contains invaid characters</FONT></FONT>");
		  break;
		default:
		  out.write("&nbsp;<FONT CLASS=\"textsmall\"><FONT COLOR=red>Unknown format error</FONT></FONT>");
		  break;		
	      }
%>
	      </TD>
            </TR>
<%        } // next(i) %>
      </TABLE>
    </FORM>
</BODY>
</HTML>
