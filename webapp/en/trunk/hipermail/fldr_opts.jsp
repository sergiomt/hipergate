<%@ page import="java.io.IOException,java.io.File,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %><%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_folder = request.getParameter("gu_folder");
  String gu_product = null;
  
  JDCConnection oConn = null;  
  PreparedStatement oStmt = null;
  ResultSet oRSet;
  long lVisible=0, lDeleted=0;
  int iVisibleMsgCount=0, iDeletedMsgCount=0, iFileMsgCount=0;
  try {
    oConn = GlobalDBBind.getConnection("fldropts");    

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_object + " FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_category + "=? AND " + DB.id_class + "=15");
    oStmt.setString(1,gu_folder);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      gu_product = oRSet.getString(1);
    oRSet.close();
    oStmt.close();
    oStmt = null;
    
    oStmt = oConn.prepareStatement("SELECT " + DB.len_mimemsg + " FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_category + "=? AND " + DB.bo_deleted + "=?");
    oStmt.setString(1,gu_folder);
    oStmt.setShort(2,(short)0);
    oRSet = oStmt.executeQuery();    
    try { oRSet.setFetchSize (4000); } catch (SQLException ignore) {}
    while (oRSet.next()) {
      lVisible += oRSet.getInt(1);
      iVisibleMsgCount++; 
    }
    oRSet.close();
    oStmt.setString(1,gu_folder);
    oStmt.setShort(2,(short)1);
    oRSet = oStmt.executeQuery();    
    try { oRSet.setFetchSize (4000); } catch (SQLException ignore) {}
    while (oRSet.next()) {
      lDeleted += oRSet.getInt(1);
      iDeletedMsgCount++; 
    }
    oRSet.close();

    oStmt.close();    
    
    oConn.close("fldropts");
  }
  catch (SQLException e) {  
    if (oConn!=null) {
      if (oStmt!=null) oStmt.close();
      if (!oConn.isClosed()) oConn.close("fldropts");
    }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

  long lTotal = lDeleted+lVisible;
  
  String sTotal, sUnused;
  if (lTotal<1024l)
    sTotal = String.valueOf(lTotal) + " bytes";
  else if (lTotal<1048576l)
    sTotal = String.valueOf(lTotal/1024l) + " Kb";
  else
    sTotal = String.valueOf(lTotal/1048576l) + " Mb";
  
  if (lTotal>0)
    sUnused = String.valueOf((lDeleted*100l)/lTotal)+"%";
  else
    sUnused = "0 %";

  SessionHandler oHndl = new SessionHandler(oMacc,sMBoxDir);
  
  DBStore oRDBMS = DBStore.open(oHndl.getSession(), sProfile, sMBoxDir, id_user, tx_pwd);

  DBFolder oFolder = oRDBMS.openDBFolder(gu_folder, DBFolder.READ_ONLY);  
  
  File oFl = oFolder.getFile();
  long lFlen = oFl.length();
  
  oFolder.close(false);
  oRDBMS.close();
  oHndl.close();

  if (oFl.exists()) {
    MboxFile oMBox = new MboxFile(oFl, MboxFile.READ_ONLY);
    iFileMsgCount = oMBox.getMessageCount();
    oMBox.close();
  } else {
    iFileMsgCount = 0;
  }
%>
<HTML>
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // ----------------------------------------------------

	function importMessages() {
	  
	  open ("mbox_browse.jsp?gu_target=<%=gu_folder%>", "mboxbrowse", "scrollbars=yes,resizable=no,directories=no,toolbar=no,menubar=no,width=600,height=460");
	
	  return false;
	} // importMessages

    
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">  
  <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1"><%=request.getParameter("nm_folder")%></FONT></TD></TR></TABLE>
  <BR>
  <FONT CLASS="textstrong">Indexes</FONT>
  <BR>
  <FONT CLASS="textplain">total indexed messages&nbsp;<%=String.valueOf(iVisibleMsgCount+iDeletedMsgCount)%>&nbsp;&nbsp;deleted&nbsp;<%=String.valueOf(iDeletedMsgCount)%></FONT>
  <BR>
  <FONT CLASS="textplain">messages space&nbsp;<%=String.valueOf(lVisible/1024l)%>Kb&nbsp;&nbsp;deleted&nbsp;<%=String.valueOf(lDeleted/1024l)%>Kb</FONT>
  <BR>
  <FONT CLASS="textstrong">Physical File</FONT>
  <BR>
  <FONT CLASS="textplain">total stored messages&nbsp;<%=String.valueOf(iFileMsgCount)%></FONT>
  <BR>
  <FONT CLASS="textplain">total space&nbsp;<%=String.valueOf(lFlen/1024l)%>Kb</FONT>
  <UL>
    <LI><A CLASS="linkplain" HREF="#" onclick="importMessages()">Import messages</A></LI>
<% if (null!=gu_product) { %>
    <LI><A CLASS="linkplain" HREF="../servlet/HttpBinaryServlet?id_product=<%=gu_product%>">Download MBOX file</A></LI>
<% } %>
    <LI><A CLASS="linkplain" HREF="mbox_wait.jsp?gu_folder=<%=gu_folder%>&nm_folder=<%=Gadgets.URLEncode(request.getParameter("nm_folder"))%>&nm_action=mbox_compact.jsp">Compact MBOX file</A></LI>
    <LI><A CLASS="linkplain" HREF="mbox_wait.jsp?gu_folder=<%=gu_folder%>&nm_folder=<%=Gadgets.URLEncode(request.getParameter("nm_folder"))%>&nm_action=mbox_reindex.jsp">Re-index MBOX file</A></LI>
    <LI><A CLASS="linkplain" HREF="mbox_wait.jsp?gu_folder=<%=gu_folder%>&nm_folder=<%=Gadgets.URLEncode(request.getParameter("nm_folder"))%>&nm_action=mbox_wipe.jsp">Empty MBOX file</A></LI>
  </UL>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>