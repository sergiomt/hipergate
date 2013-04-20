<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
 
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
  String sSkin = getCookie(request, "skin", "xp");
  
  String id_domain = getCookie(request, "domainid", "0");
  String n_domain = getCookie(request, "domainnm", "");
  String gu_user = getCookie(request, "userid", "");
  String gu_workarea = getCookie(request, "workarea", "");

  boolean bIsGuest = true;
  
  try {
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
  }
  catch (IllegalStateException e) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=_back"));
    return;
  }
  catch (NullPointerException e) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=_back"));
    return;
  }
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD> 
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function createNewsletter() {	  
      self.open("microsite_lookup_f.jsp?doctype=newsletter&gu_workarea=<%=gu_workarea%>&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&nm_table=k_microsites&id_language=<%=sLanguage%>&id_section=id_sector&tp_control=1&nm_control=gu_microsite&nm_coding=id_sector", "editgroup", "toolbar=no,directories=no,menubar=no,resizable=no,top=" + (screen.height-520)/2 + ",left=" + (screen.width-540)/2 + ",width=600,height=520");
      document.location="pageset_listing.jsp?selected=5&subselected=0&doctype=newsletter";
    }

    function createWebsite() {	  
      self.open("microsite_lookup_f.jsp?doctype=website&gu_workarea=<%=gu_workarea%>&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&nm_table=k_microsites&id_language=<%=sLanguage%>&id_section=id_sector&tp_control=1&nm_control=gu_microsite&nm_coding=id_sector", "editgroup", "toolbar=no,directories=no,menubar=no,resizable=no,top=" + (screen.height-520)/2 + ",left=" + (screen.width-540)/2 + ",width=600,height=520");
      document.location="pageset_listing.jsp?selected=5&subselected=0&doctype=website";
    }

    function uploadImage() {	  
      self.open("wb_file_upload.jsp?gu_workarea=<%=gu_workarea%>&id_domain=<%=id_domain%>&n_domain=" + escape('<%=n_domain%>'), "uploadimages", "directories=no,scrollbars=yes,toolbar=no,menubar=no,top=" + (screen.height-400)/2 + ",left=" + (screen.width-480)/2 + ",width=480,height=400");	  
      document.location="image_listing.jsp?selected=5&subselected=1";
    }
  //-->
  </SCRIPT>
  <TITLE>hipergate :: Content Management</TITLE>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0">
<%@ include file="../common/tabmenu.jspf" %>
<FORM>
<TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Content Management</FONT></TD></TR></TABLE>
  <TABLE WIDTH="<%=iTabWidth*iActive%>" CELLSPACING="0" CELLPADDING="0" BORDER="0">
    <!-- Espacio entre la barra de título y la tabla -->
    <TR>
      <TD COLSPAN="3"><IMG SRC="../images/images/spacer.gif" HEIGHT="8" WIDTH="1" BORDER="0"></TD>
    </TR>
    <!-- Pestaña superior -->
    <TR>  
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD BACKGROUND="../images/images/graylinebottom.gif">
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_24x24.gif" WIDTH="24" HEIGHT="24" BORDER="0"></TD>
	  </TR>
          <TR>
      	    <TD CLASS="subtitle"></TD>
      	    <TD CLASS="subtitle" ALIGN="left" VALIGN="middle" BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif"><IMG SRC="../images/images/3x3puntos.gif" BORDER="0">HTML Documents</TD>
          </TR>
        </TABLE>
      </TD>
      <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea gris y roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Cuerpo de Documentos HTML-->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="menu1">
        <TABLE CELLSPACING="8" BORDER="0">
          <TR>
            <TD VALIGN="top">
              <IMG SRC="../images/images/webbuilder/newnewsletter.gif" BORDER="0" ALT="HTML Documents">
            </TD>
            <TD>
              <A CLASS="linkplain" HREF="pageset_listing.jsp?selected=5&subselected=0&doctype=newsletter">View Documents</A>
              <BR>
              <A CLASS="linkplain" HREF="javascript:createNewsletter()">New Document</A>
              <BR>
              <FONT CLASS="textsmall">From this link you may create and compose a new document for being sent to a list of Individuals.<BR>Documents are composed by inserting texts and images on a template that is later sent to a distribution list.<BR><BR></FONT>
            </TD>
          </TR>
	  <TR>
            <TD>
              <IMG SRC="../images/images/webbuilder/newwebsite.gif" BORDER="0" ALT="WebSites">
            </TD>
            <TD>
              <A CLASS="linkplain" HREF="pageset_listing.jsp?selected=5&subselected=0&doctype=website">View Websites</A>
              <BR>
              <A CLASS="linkplain" HREF="javascript:createWebsite()">New Website</A>
              <BR>
              <FONT CLASS="textsmall">Click here for creating a new website.<BR></FONT>
            </TD>
	  </TR>	  
        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <TR> 
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <TR> 
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
      <TD ><IMG SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
    </TR>
    <!-- Pestaña media -->
    <TR>  
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD>
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
	  </TR>
          <TR>
      	    <TD CLASS="subtitle"></TD>
      	    <TD CLASS="subtitle" ALIGN="left" VALIGN="middle" BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif"><IMG SRC="../images/images/3x3puntos.gif" BORDER="0">Images and Files</TD>
          </TR>
        </TABLE>
      </TD>
      <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Cuerpo de Imágenes y Archivos -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="menu1">
        <TABLE CELLSPACING="8" BORDER="0">
          <TR>
            <TD VALIGN="top">
              <IMG SRC="../images/images/webbuilder/uploadimages.gif" BORDER="0" ALT="Images and Files">
            </TD>
            <TD>
<% if (bIsGuest) { %>
              <A CLASS="linkplain" HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')">Pre-load images</A>
<% } else { %>
              <A CLASS="linkplain" HREF="javascript:uploadImage()">Pre-load images</A>
<% } %>
              <BR>
              <FONT CLASS="textsmall">From this option you may pre-load images that will be more easily available when coposing a Document.<BR></FONT>
            </TD>
          </TR>
<!-- No hay aun precarga de archivos
          <TR>
            <TD VALIGN="top">
              <IMG SRC="../images/images/webbuilder/uploadfiles.gif" BORDER="0" ALT="Load Files">
            </TD>
            <TD>
              <A CLASS="linkplain" HREF="javascript:void(0)">Pre-load attached files</A>
              <BR>
              <FONT CLASS="textsmall">From this option you may load files that wil be shown as links in the Newsletter or Website.<BR></FONT>
            </TD>
          </TR>
-->
        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Línea gris -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle"><IMG SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0"></TD>
      <TD  BACKGROUND="../images/images/graylinefloor.gif"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0"></TD>
    </TR>
  </TABLE>
</FORM>


</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>