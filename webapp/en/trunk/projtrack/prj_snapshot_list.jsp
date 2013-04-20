<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/projtrack.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%

/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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
  
  String sSkin = getCookie(request, "skin", "xp");
  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");

  String sLanguage = getNavigatorLanguage(request);

  String gu_project = nullif(request.getParameter("gu_project"));
  String nm_project = "";

  JDCConnection oCon1 = null;
	
  DBSubset oSnapshots = new DBSubset (DB.k_project_snapshots + " w," + DB.k_users + " u",
																			"w."+DB.gu_snapshot+",w."+DB.tl_snapshot+",w."+DB.gu_writer+",u."+DB.nm_user+",u."+DB.tx_surname1+",u."+DB.tx_surname2+",u."+DB.nm_company+",w."+DB.dt_created+",w."+DB.tx_snapshot,
  																		"w."+DB.gu_writer+"=u."+DB.gu_user+" AND "+
  																		"w."+DB.gu_project+"=? "+
  																		"ORDER BY "+DB.dt_created+" DESC", 100);
  int iSnapshots = 0;

  try {
         
    oCon1 = GlobalDBBind.getConnection("prj_snapshot_list");

    iSnapshots = oSnapshots.load(oCon1, new Object[]{gu_project});

		nm_project = DBCommand.queryStr(oCon1, "SELECT "+DB.nm_project+" FROM "+DB.k_projects+" WHERE "+DB.gu_project+"='"+gu_project+"'");
		
    oCon1.close("prj_snapshot_list");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("prj_snapshot_list");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }

  if (null==oCon1) return;
  oCon1=null;
%>
<HTML LANG="<%=sLanguage%>">
  <HEAD>
    <TITLE>hipergate :: Project Snapshots</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  </HEAD>
  <BODY TOPMARGIN="0" MARGINHEIGHT="0">
    <DIV class="cxMnu1" style="width:120px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='prj_edit.jsp?gu_project=<%=gu_project%>&standalone=<%=(request.getParameter("standalone")!=null ? "1" : "0")%>'"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    </DIV></DIV>
    <TABLE><TR><TD WIDTH="400" CLASS="striptitle"><FONT CLASS="title1">Project Snapshots&nbsp;<%=nm_project%></FONT></TD></TR></TABLE>
    <BR>
    <IMG SRC="../images/images/new16x16.gif" BORDER="0">&nbsp;
	  <A HREF="#" onclick="document.forms[0].submit()" CLASS="linkplain">New Snapshot</A>
    <BR><BR>
    <TABLE SUMMARY="Project Snapshots List" CELLSPACING="1" CELLPADDING="0">
      <TR>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Date</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Created by</B></TD>
      </TR>
<%
   for (int i=0; i<iSnapshots; i++) {
     String sStrip = String.valueOf((i%2)+1);
%>
      <TR>      	
        <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="prj_snapshot_preview.jsp?gu_snapshot=<%=oSnapshots.getString(0,i)%>" TARGET="_blank" CLASS="linkplain"><%=oSnapshots.getDateTime24(7,i)%></A></TD>
        <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oSnapshots.getStringNull(3,i,"")+" "+oSnapshots.getStringNull(4,i,"")+" "+oSnapshots.getStringNull(5,i,"")%></TD>
      </TR>  
<% } %>
    </TABLE>
    <FORM METHOD="post" ACTION="prj_snapshot_store.jsp"><INPUT TYPE="hidden" NAME="gu_project" VALUE="<%=gu_project%>"><INPUT TYPE="hidden" NAME="is_standalone" VALUE="<%=(request.getParameter("standalone")!=null ? "1" : "0")%>"></FORM>
</BODY>
</HTML>