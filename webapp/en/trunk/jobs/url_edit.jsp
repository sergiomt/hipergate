<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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

  // 01. Verify user credentials
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // 02. Avoid page caching
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // 03. Get parameters

  final String PAGE_NAME = "url_edit";
  
  final String sLanguage = getNavigatorLanguage(request);
  final String sSkin = getCookie(request, "skin", "xp");
  final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

  final String id_user = getCookie(request, "userid", "");
  final String id_domain = request.getParameter("id_domain");
  final String gu_workarea = request.getParameter("gu_workarea");
  final String gu_url = request.getParameter("gu_url");
  
  DBPersist oObj = new DBPersist(DB.k_urls,"Url");
    
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME,true);  

    if (null!=gu_url) oObj.load(oConn, new Object[]{gu_url,gu_workarea});
    
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&"+e.getClass().getName()+"=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Example Form</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	      if (frm.url_addr.value.length==0) {
	        alert ("The web address is required");
	        frm.url_addr.focus();
	        return false;
	      }

	      if (frm.url_addr.value.length>2000) {
	        alert ("The address may not be longer than 2000 characters");
	        frm.url_addr.focus();
	        return false;
	      }

	      if (! /(http|ftp|https):\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:/~\+#]*[\w\-\@?^=%&amp;/~\+#])?/.test(frm.url_addr.value)) {
	        alert ("The address is not valid");
	        frm.url_addr.focus();
	        return false;
	      }

	      if (frm.tx_title.value.length>2000) {
	        alert ("The title may not be longer than 2000 characters");
	        frm.tx_title.focus();
	        return false;
	      }

	      if (frm.de_url.value.length>2000) {
	        alert ("The description may not be longer than 2000 characters");
	        frm.de_url.focus();
	        return false;
	      }
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit URL</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="url_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_url" VALUE="<%=oObj.getStringNull("gu_url",Gadgets.generateUUID())%>">
    <INPUT TYPE="hidden" NAME="nu_clicks" VALUE="<% if (oObj.isNull("nu_clicks")) out.write("0"); else out.write(String.valueOf(oObj.getInt("nu_clicks"))); %>">
    <INPUT TYPE="hidden" NAME="dt_last_visit" VALUE="<% if (!oObj.isNull("dt_last_visit")) out.write(oObj.getDateTime24("dt_last_visit")); %>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="110" CLASS="formstrong">Address</TD>
            <TD ALIGN="left" WIDTH="570"><INPUT TYPE="text" NAME="url_addr" MAXLENGTH="2000" SIZE="80" VALUE="<%=oObj.getStringHtml("url_addr","")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110" CLASS="formplain">Title</TD>
            <TD ALIGN="left" WIDTH="570"><INPUT TYPE="text" NAME="tx_title" MAXLENGTH="2000" SIZE="80" VALUE="<%=oObj.getStringHtml("tx_title","")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Description</FONT></TD>
            <TD ALIGN="left" WIDTH="570"><TEXTAREA ROWS="3" COLS="60" NAME="de_url"><%=oObj.getStringHtml("de_url","")%></TEXTAREA></TD>
          </TR>
<% if (null!=gu_url) { %>
          <TR>
            <TD ALIGN="right" WIDTH="110" CLASS="formplain">Clicks</TD>
            <TD ALIGN="left" WIDTH="570"><% if (oObj.isNull("nu_clicks")) out.write("0"); else out.write(String.valueOf(oObj.getInt("nu_clicks"))); %></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110" CLASS="formplain">Last Visit</TD>
            <TD ALIGN="left" WIDTH="570"><% if (!oObj.isNull("dt_last_visit")) out.write(oObj.getDateTime24("dt_last_visit")); %></TD>
          </TR>
<% } %>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
