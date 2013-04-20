<%@ page import="java.text.SimpleDateFormat,java.net.URL,java.net.URLDecoder,java.io.IOException,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.storage.*,com.knowgate.clocial.Domain,com.knowgate.clocial.UserAccount,com.knowgate.syndication.crawler.EntrySearcher,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><jsp:useBean id="GlobalNoSQLStore" scope="application" class="com.knowgate.storage.Manager"/><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%

/*  
  Copyright (C) 2003-2012 Know Gate S.L. All rights reserved.

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

  final String PAGE_NAME = "activity_audience";

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String sLanguage = getNavigatorLanguage(request);  
  final String sSkin = getCookie(request, "skin", "xp");

  final String id_domain = getCookie(request,"domainid","");
  final String gu_workarea = getCookie(request,"workarea","");
  final String id_user = getCookie(request, "userid", "");
  final String sFind = nullif(request.getParameter("find"),"");
  
  // **********************************************

  DebugFile.writeln("Begin conversation track");
  
  SimpleDateFormat oFmt = new SimpleDateFormat("EEE dd MMM HH:mm");
  int iEntryCount = 0;
  int iMaxRows = 100;
  int iSkip = 0;

  try {  
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "100"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 100; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;
    
  if (iSkip<0) iSkip = 0;

  JDCConnection oConn = null;
  DataSource oDts = null;
  RecordSet oRecs = null;
  
  try {
    if (!GlobalNoSQLStore.exists("k_domains",id_domain)) {
			DebugFile.writeln("Begin new Domain "+id_domain);
			oConn = GlobalDBBind.getConnection(PAGE_NAME,true);      
      ACLDomain oAdm = new ACLDomain(oConn, Integer.parseInt(id_domain));
      oConn.close(PAGE_NAME);
      oConn = null;
      oDts = GlobalNoSQLStore.getDataSource();
      Domain oDom = new Domain(oDts);
      oDom.putAll(oAdm);
      GlobalNoSQLStore.store(oDom,true);
      GlobalNoSQLStore.free(oDts);
      oDts = null;
      DebugFile.writeln("End new Domain "+id_domain);
    }
    if (!GlobalNoSQLStore.exists("k_user_accounts",id_user)) {
			oConn = GlobalDBBind.getConnection(PAGE_NAME,true);      
      ACLUser oUsr = new ACLUser(oConn, id_user);
      oConn.close(PAGE_NAME);
      oConn = null;
      oDts = GlobalNoSQLStore.getDataSource();
      UserAccount oAcc = new UserAccount(oDts);
      oAcc.putAll(oUsr);
      oAcc.remove("gu_user");
      oAcc.put("gu_account",oUsr.getString("gu_user"));
      GlobalNoSQLStore.store(oAcc,true);
      GlobalNoSQLStore.free(oDts);
      oDts = null;
    }
    if (sFind.length()>0)
      oRecs = EntrySearcher.search(GlobalNoSQLStore, Gadgets.removeChars(sFind,"'<>?*&(){}[]"), id_user, iMaxRows);
  }
  catch (NullPointerException e) {
    if (oConn!=null) if (!oConn.isClosed()) oConn.close();
    if (null!=oDts) GlobalNoSQLStore.free(oDts);;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
    return;
  }
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript">
    <!--
       
      // ----------------------------------------------------
	
	      function findInstance() {
	  	  
	        var frm = document.forms[0];

			    if (hasForbiddenChars(frm.find.value)) {
			      alert ("The string sought contains invalid characters");
				    frm.find.focus();
				    return false;
			    }
	  
	        if (frm.find.value.length>0)
	          window.location = "conversation_track.jsp?id_domain=<%=id_domain%>&skip=0&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	        else
	          window.location = "conversation_track.jsp?id_domain=<%=id_domain%>&skip=0&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  
	      } // findInstance()
      
      // ------------------------------------------------------	

	      function setCombos() {
	        setCookie ("maxrows", "<%=iMaxRows%>");
	      } // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Conversations tracker</TITLE>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onClick="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Conversations tracker</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <TABLE SUMMARY="Top controls and filters" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD VALIGN="bottom" CLASS="textplain">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search">&nbsp;Search comments about URL&nbsp;</TD>
        <TD VALIGN="middle">
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" SIZE="30" VALUE="<%=sFind%>">
	        <A HREF="javascript:findInstance();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top controls and filters -->
      <TABLE SUMMARY="Data" CELLSPACING="0" CELLPADDING="2">
        <TR>
          <TD ALIGN="left" COLSPAN="4">
<%      /*
				if (sFind.length()>0) {
    
    	  if (iEntryCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"conversation_track.jsp?id_domain=" + id_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oEntries.eof())
              out.write("            <A HREF=\"conversation_track.jsp?id_domain=" + id_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } } */
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Author</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Entry</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Origin</B></TD>
          <!--<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Influence</B></TD>-->
				</TR>
<%    if (oRecs!=null) {
			for (Record oRec : oRecs) { %>
			  <TR><!--<%=oRec.getString("id_type","")%>-->
    	    <TD CLASS="textplain" VALIGN="top" NOWRAP="nowrap"><A HREF="<%=oRec.getString("url_addr","#")%>"><%=oRec.getString("nm_author","").length()>0 ? oRec.getString("nm_author") : oRec.getString("url_domain")%></A></TD>
    	    <TD CLASS="textplain" VALIGN="top"><%=oRec.isNull("dt_modified") ? oRec.getDate("dt_published") : oRec.getDate("dt_modified") %></TD>
    	    <TD CLASS="textplain" VALIGN="top">
    			<% if (oRec.getString("de_entry","").trim().length()>0) {
    					if (oRec.getString("tl_entry","").trim().length()>0) {
						    out.write("<A CLASS=\"linkplain\" HREF=\""+oRec.getString("url_addr","#")+"\">"+oRec.getString("tl_entry","")+"</A><BR/>");
						    if (oRec.getString("de_entry","").startsWith(oRec.getString("tl_entry","")))
						      out.write(oRec.getString("de_entry","").substring(oRec.getString("tl_entry","").length()));
						    else
						      out.write(oRec.getString("de_entry",""));
						  } else {
						    out.write(oRec.getString("de_entry",""));
						  }
						} else {
						  out.write("<A CLASS=\"linkplain\" HREF=\""+oRec.getString("url_addr","#")+"\">"+oRec.getString("tl_entry","")+"</A>");
						}
						if (oRec.getString("tx_content","").length()>0) { %>
        		&#160;<div align="right" id="p{@id}"><img src="images/plusbox13.gif" width="13" height="13" alt="[+]" />&#160;<a href="#" style="text-decoration:none" onmouseover="this.style.textDecoration='underline'" onmouseout="this.style.textDecoration='none'" onclick="dojo.byId('p{@id}').style.display='none';dojo.byId('c{@id}').style.display='block'">read more&#8230;</a></div>
    	  		<div id="c{@id}" style="display:none"><small><%=oRec.getString("tx_content")%></small>
    				&#160;<img src="images/minusbox13.gif" width="13" height="13" alt="[-]" />&#160;<a href="#" style="text-decoration:none" onmouseover="this.style.textDecoration='underline'" onmouseout="this.style.textDecoration='none'" onclick="dojo.byId('c{@id}').style.display='none';dojo.byId('p{@id}').style.display='block'">hide contents</a></div>
<%					} %>
    	    	</TD>
    	    	<TD></TD>
			  </TR>
<%    } } %>
      </TABLE>
    </FORM>
</BODY>
</HTML>