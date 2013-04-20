<%@ page import="java.net.URLDecoder" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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

  String nm_table = request.getParameter("nm_table");
  String id_language = request.getParameter("id_language");
  String id_section = request.getParameter("id_section");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");  
  String id_form = nullif(request.getParameter("id_form"), "0");
    
  String sQryStr = "?nm_table="+ nm_table + "&id_language=" + id_language + "&id_section=" + id_section + "&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding + "&id_form=" + id_form;
  
  boolean bIsGuest = true;
  boolean bIsAdmin = false;

  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
  }
  catch (java.sql.SQLException e) {
  }
  
%>
<HTML>
  <HEAD>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--

      // ------------------------------------------------------
      
      function selectAll() {      
        var elems = window.parent.lookupmid.document.forms[0].elements;
        var allon = true;
        
        for (var i=0; i<elems.length && allon; i++)
          if (!elems[i].checked) allon = false;
                
        for (var i=0; i<elems.length; i++)
          elems[i].checked = !allon;        
      } // selectAll()

      // ------------------------------------------------------
      
      function deleteSelected() {
        if (confirm("Are you sure you want to delete selected elements?"))
          window.parent.lookupmid.document.forms[0].submit();
      } // deleteSelected()
            
      //-->
    </SCRIPT>  
  </HEAD>
  
  <BODY  LEFTMARGIN="4" TOPMARGIN="4" SCROLL="no">
<% if (!bIsGuest) { %>
    <TABLE BORDER="0" CELLSPACING="0" CELLPADDING="2">
      <FORM>
      <TR>
        <TD>
          <IMG SRC="../images/images/booknew16.gif" WIDTH="16" HEIGHT="16" BORDER="0">
        </TD>
        <TD>        
          <A HREF="lookup_new.jsp<%=sQryStr%>" onClick="javascript:window.location.href='../blank.htm';" TARGET="lookupmid" CLASS="linkplain">Add</A>
        </TD>
        <TD>
          <IMG SRC="../images/images/spacer.gif" WIDTH="16" HEIGHT="16" BORDER="0">
        </TD>
        <TD>
          <IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0">
        </TD>
        <TD>
          <A HREF="javascript:deleteSelected();" CLASS="linkplain">Delete</A>
        </TD>
        <TD>
          <IMG SRC="../images/images/spacer.gif" WIDTH="16" HEIGHT="16" BORDER="0">
        </TD>
        <TD>
          <IMG SRC="../images/images/selall16.gif" WIDTH="16" HEIGHT="16" BORDER="0">        
        </TD>
        <TD>
          <A HREF="javascript:selectAll();" CLASS="linkplain">Select All</A>        
        </TD>
      </TR>
<% if (bIsAdmin) { %>      
      <TR valign="middle">
        <TD valign="middle">
          <IMG SRC="../images/images/table16.gif" WIDTH="15" HEIGHT="13" BORDER="0">
        </TD>
        <TD valign="middle" colspan="7">
          <A HREF="../admin/lookups.jsp?nm_table=<%=nm_table%>&id_section=<%=id_section%>" TARGET="_blank" CLASS="linkplain">Fast Edit</A>
	</TD>
      </TR>
<% } %>      
      <TR valign="middle">
        <TD valign="middle">
          <IMG SRC="../images/images/find16.gif" WIDTH="22" HEIGHT="16" BORDER="0">
        </TD>
        <TD valign="middle" colspan="7">        
	  <INPUT CLASS="combomini" TYPE="text" NAME="search">&nbsp;
          <A HREF="#" onClick="top.frames['lookupmid'].findit(document.forms[0].search.value);" CLASS="linkplain">Search</A>
	</TD>
      </TR>
      </FORM>
    </TABLE>
<% } %>
  </BODY>
</HTML>