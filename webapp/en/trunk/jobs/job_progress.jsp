<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.acl.*,com.knowgate.scheduler.Job,com.knowgate.scheduler.Atom" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%
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
      
  String gu_job = request.getParameter("gu_job");
  int id_status = Integer.parseInt(nullif(request.getParameter("id_status"), "-100"));
  
  int iStatus = -100;
  int iProcessed=0, iPending=0, iPct=0;
  boolean bStmt = false;
  boolean bRSet = false;
  Statement oStmt = null;
  ResultSet oRSet = null;
    
  JDCConnection oConn = GlobalDBBind.getConnection("jobprogress");  
    
  try {

    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    bStmt = true;
    
    try { oStmt.setQueryTimeout(4); } catch (SQLException sqle) { }

    oRSet = oStmt.executeQuery("SELECT " + DB.id_status + " FROM " + DB.k_jobs + " WHERE " + DB.gu_job + "='" + gu_job + "'");
    bRSet = true;
    oRSet.next();
    iStatus = oRSet.getInt(1);
    oRSet.close();
    bRSet = false;

    oRSet = oStmt.executeQuery("SELECT COUNT(*) FROM " + DB.k_job_atoms + " WHERE " + DB.gu_job + "='" + gu_job + "' AND (" + DB.id_status + "=" + String.valueOf(Atom.STATUS_PENDING) + " OR " + DB.id_status + "=" + String.valueOf(Atom.STATUS_SUSPENDED) + " OR " + DB.id_status + "=" + String.valueOf(Atom.STATUS_RUNNING) + ")");
    bRSet = true;
    oRSet.next();
    iPending = oRSet.getInt(1);
    oRSet.close();
    bRSet = false;

    oRSet = oStmt.executeQuery("SELECT COUNT(*) FROM " + DB.k_job_atoms_archived + " WHERE " + DB.gu_job + "='" + gu_job + "'");
    bRSet = true;
    oRSet.next();
    iProcessed = oRSet.getInt(1);
    oRSet.close();
    bRSet = false;
    
    oStmt.close();
    bStmt = false;
    
    oConn.close("jobprogress");
    
    if (iPending+iProcessed>0)
      iPct = (iProcessed*100) / (iPending+iProcessed);
  }
  catch (SQLException e) {  
    if (bRSet) oRSet.close();
    if (bStmt) oStmt.close();
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("jobprogress");
    oConn = null;
  }
  
  if (null==oConn) return;
    
  oConn = null;
%>
<HTML>
  <HEAD>
    <TITLE>hipergate :: Progress</TITLE>
    <META HTTP-EQUIV="Refresh" CONTENT="8; URL=job_progress.jsp?gu_job=<% out.write(gu_job); %>&id_status=<% out.write(String.valueOf(iStatus)); %>">
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
<% if (iStatus!=id_status) { %>
    <SCRIPT TYPE="text/javascript">
      <!--
        window.parent.jobmodify.document.location.reload();
      //-->
    </SCRIPT>
<% } %>    
  </HEAD>
  <BODY >
    <CENTER>
    <HR>
<% if (Job.STATUS_RUNNING==iStatus) { %>
    <TABLE WIDTH="100%">
      <TR>
        <TD ALIGN="left" WIDTH="160"><FONT CLASS="textplain"><B>Processed</B>&nbsp;<% out.write(String.valueOf(iProcessed) + " / " + String.valueOf(iProcessed+iPending)); %></FONT></TD>
        <TD>
          <TABLE WIDTH="304px" CELLSPACING="0" CELLPADDING="0" BORDER="0">
            <TR>
              <TD COLSPAN="5" HEIGHT="1px" BGCOLOR="gray"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            </TR>
            
            <TR>
              <TD HEIGHT="1px" BGCOLOR="gray"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
              <TD HEIGHT="1px" BGCOLOR="white" COLSPAN="3" ><IMG SRC="../images/images/spacer.gif" WIDTH="200" HEIGHT="1" BORDER="0"></TD>
              <TD HEIGHT="1px" BGCOLOR="gray"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            </TR>

	    <TR>
	      <TD WIDTH="1px" BGCOLOR="gray"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="16" BORDER="0"></TD>
	      <TD WIDTH="1px" BGCOLOR="white"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="16" BORDER="0"></TD>
	      <TD ALIGN="left">
	        <TABLE WIDTH="300px" CELLSPACING="0" CELLPADDING="0" BORDER="0">
	          <TR>
	            <TD WIDTH="<% out.write(String.valueOf(iPct)+"%"); %>" HEIGHT="16" BGCOLOR="darkblue"></TD>
	            <TD WIDTH="<% out.write(String.valueOf(100-iPct)+"%"); %>" HEIGHT="16" BGCOLOR="white"></TD>
		  </TR>
		</TABLE>
	      </TD>
	      <TD WIDTH="1px" BGCOLOR="white"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="16" BORDER="0"></TD>
	      <TD WIDTH="1px" BGCOLOR="gray"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="16" BORDER="0"></TD>
	    </TR>

            <TR>
              <TD HEIGHT="1px" BGCOLOR="gray"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
              <TD HEIGHT="1px" BGCOLOR="white" COLSPAN="3" ><IMG SRC="../images/images/spacer.gif" WIDTH="200" HEIGHT="1" BORDER="0"></TD>
              <TD HEIGHT="1px" BGCOLOR="gray"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            </TR>
	    	    
            <TR>
              <TD COLSPAN="5" HEIGHT="1px" BGCOLOR="gray"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            </TR>            
          </TABLE>
        </TD>        
      </TR>
    </TABLE>
<% } %>
    <FORM><INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" TITLE="ALT+c" onclick="window.parent.close()"></FORM>    
    </CENTER>
  </BODY>  
</HTML>