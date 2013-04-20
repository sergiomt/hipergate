<%@ page import="java.net.URLDecoder,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.QueryByForm" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = getCookie(request,"workarea",""); 

  String screen_width = request.getParameter("screen_width");

  int iScreenWidth;
  float fScreenRatio;

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;

  // **********************************************

  int iMicrositeCount = 0;
  DBSubset oMicrosites;        
  String sOrderBy;
  int iOrderBy;  

  // **********************************************

  // 07. Order by column
  
  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  // **********************************************

  JDCConnection oConn = null;  
  boolean bIsAdmin = true;
  
  try {
    
    bIsAdmin = isDomainAdmin(GlobalCacheClient, GlobalDBBind, request, response);
 
    oConn = GlobalDBBind.getConnection("micrositelisting");  
    
    if (id_domain.equals("1024") || id_domain.equals("1025")) {
      oMicrosites = new DBSubset ("k_microsites", 
      				  "gu_microsite,dt_created,tp_microsite,nm_microsite,id_app",
      				  DB.gu_workarea+ " IS NULL " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), 50);      				 
    }
    else {
      oMicrosites = new DBSubset ("k_microsites", 
      				  "gu_microsite,dt_created,tp_microsite,nm_microsite,id_app",
      				  DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), 50);      				 
    }
    iMicrositeCount = oMicrosites.load (oConn);    
    oConn.close("micrositelisting"); 
  }
  catch (SQLException e) {  
    oMicrosites = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("micrositelisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  

  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

        // ----------------------------------------------------

<% if (bIsAdmin) { %>

	function createMicrosite() {	  
	  
	  self.open ("microsite_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>", "editmicrosite", "directories=no,toolbar=no,menubar=no,width=500,height=400");	  
	} // createMicrosite()

        // ----------------------------------------------------

	function deleteMicrosite(id) {	  
	  var frm = document.forms[0];
	  	  
	  if (window.confirm("Are you sure that you want to delete ")) {	  	  
	    frm.gu_microsite.value = id;
            frm.submit();
          } // fi (confirm)
	} // deleteMicrosites()
<% } %>	
        // ----------------------------------------------------

	function modifyMicrosite(id) {
	  
	  self.open ("microsite_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>" + "&gu_microsite=" + id, "editmicrosite", "directories=no,toolbar=no,menubar=no,width=500,height=400");
	} // modifyMicrosite

        // ----------------------------------------------------

	function sortBy(fld) {	  
	  var frm = document.forms[0];
	  
	  window.location = "microsite_listing.jsp?id_domain=<%=id_domain%>&orderby=" + fld + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // sortBy
       
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Microsites List</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Microsites List</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="gu_microsite">
<% if (bIsAdmin) { %>      
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createMicrosite()" CLASS="linkplain">New</A></TD>
      </TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
<% } %>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Type</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Creation Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD></TR>
<%
    	  // 21. List rows

	  String sGuMSite, sTpMSite, sDtMSite, sNmMSite, sStrip;
	  short iTpMSite;
	  for (int i=0; i<iMicrositeCount; i++) {
            sGuMSite = oMicrosites.getString(0,i);
            sDtMSite = oMicrosites.getDateShort(1,i);
            iTpMSite = oMicrosites.getShort(2,i);
            sNmMSite = oMicrosites.getString(3,i);
            
            switch (iTpMSite) {
              case (short)1:
                sTpMSite = "Newsletter";
                break;
              case (short)2:
                sTpMSite = "WebSite";
                break;
              case (short)4:
                sTpMSite = "Questionnaire";
                break;
              default:
                sTpMSite = "";              
            }
            
            sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" onclick="modifyMicrosite('<%=sGuMSite%>')"><%=sNmMSite%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right">&nbsp;<%=sTpMSite%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right"><%=sDtMSite%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><A HREF="microsite_delete.jsp?gu_microsite=<%=sGuMSite%>&selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>" TITLE="Delete"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" HSPACE="4" BORDER="0" ALT="Delete"></A></TD>              
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
