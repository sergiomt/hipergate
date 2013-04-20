<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.example.Example" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "sms_from_list";
  
  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");  
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm","");
  String gu_workarea = getCookie(request,"workarea","");
    
  JDCConnection oConn = null;

	DBSubset oFrom = new DBSubset(DB.k_sms_msisdn, DB.nu_msisdn+","+DB.bo_validated, DB.gu_workarea+"=?", 10);
  int nFrom = 0;

  final String aStatusIcons[] = { "pending.gif", "validated.gif", "discarded.gif", "expired.gif" };

  boolean bIsGuest = true;
    
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

    nFrom = oFrom.load(oConn, new Object[]{gu_workarea});
    
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Senders</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
            
        <%          
          out.write("var jsMsisdns = new Array(");
            
            for (int i=0; i<nFrom; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oFrom.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

        function selectAll() {          
          var frm = document.forms[0];
				  for (var e=0;e<frm.elements.length; e++)
            if (frm.elements[e].type=="checkbox") frm.elements[e].click();          
        } // selectAll()

        // ----------------------------------------------------

<% if (!bIsGuest) { %>
	
	      function deleteMsisdns() {
	  
	        var offset = 0;
	        var frm = document.forms[0];
	        var chi = frm.checkeditems;
	  	  
	        if (window.confirm("Are you sure that you want to delete the selected numbers?")) {
	  	  
	          chi.value = "";	  	  
	          frm.action = "sms_from_delete.jsp";
	  	  
	          for (var i=0;i<jsMsisdns.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	        if (frm.elements[offset].checked)
                chi.value += jsMsisdns[i] + ",";
                offset++;
	          } // next()
	    
	          if (chi.value.length>0) {
	            chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteInstances()
<% } %>	

    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <DIV class="cxMnu1" style="width:100px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Senders List</FONT></TD></TR>
  </TABLE>
  <FORM METHOD="post" ACTION="sms_from_delete.jsp">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="checkeditems" VALUE="">
<% if (!bIsGuest) { %>
    <IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New">&nbsp;<A HREF="sms_from_new.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>" CLASS="linkplain">New</A>
    &nbsp;&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete">&nbsp;<A HREF="#" onclick="deleteMsisdns()" CLASS="linkplain">Delete</A>
    <BR/>
<% } %>
    <TABLE SUMMARY="MSISDN List" CELLSPACING="1" CELLPADDING="0">
      <TR>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>MSISDN</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Validated</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" ALIGN="center"><A HREF="#" onclick="selectAll()" TITLE="Select All"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD></TR>
    	</TR>
<% for (int f=0; f<nFrom; f++) {
     String sStrip = String.valueOf((f%2)+1); %>
      <TR>
        <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oFrom.getString(0,f)%></TD>
        <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><IMG SRC="../images/images/forums/<%=aStatusIcons[oFrom.getShort(1,f)]%>" BORDER="0" ALT="" /></TD>
        <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<%=oFrom.getString(0,f)%>"></TD></TR>
    	</TR>
<% } %>
    </TABLE>
	</FORM>
</BODY>
</HTML>
