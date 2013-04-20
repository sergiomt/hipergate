<%@ page import="java.net.URLDecoder,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String BASE_TABLE = "k_jobs j, k_job_atoms_clicks c";
  final String COLUMNS_LIST = "c.gu_company,c.gu_contact,c.tx_email,c.dt_action,c.pg_atom,j.tl_job";

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");

  final String id_domain = getCookie(request,"domainid","");
  final String n_domain = getCookie(request,"domainnm","");

  final String gu_workarea = request.getParameter("gu_workarea");
  final String gu_url = request.getParameter("gu_url");
  String[] aInfo = null; 

  // **********************************************

  int iUrlCount = 0;
  DBSubset oUrls;

  // **********************************************

  JDCConnection oConn = null;  
  boolean bIsGuest = true;
  
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("clicksdetail");

		aInfo = DBCommand.queryStrs(oConn, "SELECT tx_title,url_addr FROM k_urls WHERE gu_url='"+gu_url+"' AND gu_workarea='"+gu_workarea+"'");
		if (null==aInfo) throw new SQLException("URL "+gu_url+" not found at workarea "+gu_workarea);
		if (aInfo[0]==null) aInfo[0]=aInfo[1];
	  else if (aInfo[0].length()==0) aInfo[0]=aInfo[1];

    oUrls = new DBSubset (BASE_TABLE, COLUMNS_LIST,
      				            "j." + DB.gu_workarea+ "=? AND "+
      				            "j." +  DB.gu_job +"=c."+DB.gu_job+" AND "+
      				            "c." + DB.gu_url+"=?", 1000);

      iUrlCount = oUrls.load (oConn, new Object[]{gu_workarea,gu_url});
    
    oConn.close("clicksdetail"); 
  }
  catch (SQLException e) {  
    oUrls = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("clicksdetail");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	  function modifyContact(id) {
	    open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=760,height=660");
	  }

	  function modifyCompany(id) {
	    open ("../crm/company_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_company=" + id + "&n_company=" + "&gu_workarea=<%=gu_workarea%>", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=660,height=660");
	  }	
	  //-->
  </SCRIPT>
  <TITLE>hipergate :: Clicks detail</TITLE>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post" ACTION="url_delete.jsp">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Clicks detail</FONT></TD></TR></TABLE>  
      <A HREF="<%=aInfo[1]%>" TARGET="_blank" CLASS="linkplain"><BIG><%=aInfo[0]%></BIG></A><BR>
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">      
      <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">      
      <TABLE SUMMARY="Data" CELLSPACING="1" CELLPADDING="0">
        <TR>        	
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Message Num.</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>e-mail</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Origin</B></TD>
<%

	        String sClkPg, sClkEm, sClkDt, sClkJb, sStrip;
	    
	        for (int i=0; i<iUrlCount; i++) {
            sStrip = String.valueOf((i%2)+1);

            sClkEm = oUrls.getString(2,i);
            sClkDt = oUrls.getDateTime24(3,i);
            sClkPg = String.valueOf(oUrls.getInt(4,i));
            sClkJb = oUrls.getString(5,i);
            
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right">&nbsp;<%=sClkPg%></TD>
<% if (!oUrls.isNull(1,i)) { %>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="left">&nbsp;<A HREF="#" CLASS="linkplain" onclick="modifyContact('<%=oUrls.getString(1,i)%>')"><%=sClkEm%></A></TD>
<% } else if (!oUrls.isNull(0,i)) { %>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="left">&nbsp;<A HREF="#" CLASS="linkplain" onclick="modifyCompany('<%=oUrls.getString(1,i)%>')"><%=sClkEm%></A></TD>
<% } else { %>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="left">&nbsp;<%=sClkEm%></TD>
<% } %>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="left">&nbsp;<%=sClkDt%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="left">&nbsp;<%=sClkJb%></TD>
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>