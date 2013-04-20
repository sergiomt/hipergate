<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
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
  
  final int iApplicationMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  final int ProjectMngr=12;
  
  final int iMaxRows = 1000;
   
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
  String sTxClient = request.getParameter("tx_client")==null ? "" : request.getParameter("tx_client");
  String sPgBug = request.getParameter("pg_bug")==null ? "" : request.getParameter("pg_bug");
  String sTlBug = request.getParameter("tl_bug")==null ? "" : request.getParameter("tl_bug");

  String sOrderBy = ((iApplicationMask & (1<<ProjectMngr))!=0) ? "1" : "7 DESC";
  
  String sDomainId = getCookie(request,"domainid","0");  
  
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  JDCConnection oCon1 = null;  
  String sLastProj = "";
  int iRowCount = 0;
  boolean bIsAdmin = false;
  DBSubset oBugs = null;

  if (sWhere.length()==0) {
    if (sPgBug.length()>0)
      sWhere = " AND b.pg_bug=" + sPgBug;
    else if (sTlBug.length()>0)
      sWhere = " AND b.tl_bug " + DBBind.Functions.ILIKE + " '%" + sTlBug.toUpperCase() + "%'";
  } // fi (sWhere=="")
  
  try {
    Integer oDomainId = new Integer(sDomainId);

    oCon1 = GlobalDBBind.getConnection("bug_report");

    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

    if (bIsAdmin) {
      if (sTxClient.length()==0) {
        oBugs = new DBSubset(DB.k_bugs + " b," + DB.k_projects + " p," + DB.k_workareas + " w",
  			   "p.nm_project,b.pg_bug,b.od_priority,b.gu_bug,b.od_severity,b.tl_bug,b.dt_created,b.tx_status,b.nm_reporter,b.tx_bug_brief,b.tx_comments",
  			     "(p.gu_project=b.gu_project AND p.gu_owner=w.gu_workarea AND w.id_domain=? AND w.bo_active<>0) " +
  			     sWhere + " ORDER BY " + sOrderBy, 100);
        oBugs.setMaxRows(iMaxRows);
        iRowCount = oBugs.load(oCon1, new Object[]{oDomainId});
      }
      else {
        oBugs = new DBSubset(DB.k_bugs + " b," + DB.k_projects + " p," + DB.k_workareas + " w",
  			     "p.nm_project,b.pg_bug,b.od_priority,b.gu_bug,b.od_severity,b.tl_bug,b.dt_created,b.tx_status,w.nm_workarea,w.gu_workarea,b.tx_bug_brief,b.tx_comments",
  			     "(p.gu_project=b.gu_project AND p.gu_owner=w.gu_workarea AND w.id_domain=? AND w.bo_active<>0) " +
  			     "AND (b."+DB.id_client+" IS NOT NULL " + 
  			     "AND (b."+DB.id_client+" IN (SELECT gu_company FROM k_companies WHERE "+DB.gu_workarea+" IN (SELECT "+DB.gu_workarea+" FROM "+DB.k_workareas+" WHERE "+DB.id_domain+"=?) AND ("+DB.nm_legal+" " + DBBind.Functions.ILIKE + " ? OR "+DB.nm_commercial+" " + DBBind.Functions.ILIKE + " ?)) OR " +
  			     "     b."+DB.id_client+" IN (SELECT gu_contact FROM k_contacts  WHERE "+DB.gu_workarea+" IN (SELECT "+DB.gu_workarea+" FROM "+DB.k_workareas+" WHERE "+DB.id_domain+"=?) AND ("+DB.tx_name+" " + DBBind.Functions.ILIKE + " ? OR "+DB.tx_surname+" " + DBBind.Functions.ILIKE + " ?))) " + 
  			     sWhere + " ORDER BY " + sOrderBy, 100);
        oBugs.setMaxRows(iMaxRows);
        iRowCount = oBugs.load(oCon1, new Object[]{oDomainId,oDomainId,"%"+sTxClient+"%","%"+sTxClient+"%",oDomainId,"%"+sTxClient+"%","%"+sTxClient+"%"});
      }
    }
    else {
      String sWorkArea = getCookie(request,"workarea","");
      
      if (sTxClient.length()==0) {
        oBugs = new DBSubset(DB.k_bugs + " b," + DB.k_projects + " p",
  			     "p.nm_project,b.pg_bug,b.od_priority,b.gu_bug,b.od_severity,b.tl_bug,b.dt_created,b.tx_status,NULL,p.gu_owner,b.tx_bug_brief,b.tx_comments",
  			     "(p.gu_project=b.gu_project AND p.gu_owner=?) "+ sWhere + " ORDER BY " + sOrderBy, 100);
      oBugs.setMaxRows(iMaxRows);
      iRowCount = oBugs.load(oCon1, new Object[]{sWorkArea});
      }
      else {
        oBugs = new DBSubset(DB.k_bugs + " b," + DB.k_projects + " p",
  			     "p.nm_project,b.pg_bug,b.od_priority,b.gu_bug,b.od_severity,b.tl_bug,b.dt_created,b.tx_status,NULL,p.gu_owner,b.tx_bug_brief,b.tx_comments",
  			     "(p.gu_project=b.gu_project AND p.gu_owner=?) " +
  			     "AND (b."+DB.id_client+" IS NOT NULL " + 
  			     "AND (b."+DB.id_client+" IN (SELECT gu_company FROM k_companies WHERE "+DB.gu_workarea+"=? AND ("+DB.nm_legal+" " + DBBind.Functions.ILIKE + " ? OR "+DB.nm_commercial+" " + DBBind.Functions.ILIKE + " ?)) OR " +
  			     "     b."+DB.id_client+" IN (SELECT gu_contact FROM k_contacts  WHERE "+DB.gu_workarea+"='"+sWorkArea+"' AND ("+DB.tx_name+" " + DBBind.Functions.ILIKE + " ? OR "+DB.tx_surname+" " + DBBind.Functions.ILIKE + " ?))) " +   			     
  			     sWhere + " ORDER BY " + sOrderBy, 100);
      oBugs.setMaxRows(iMaxRows);
      iRowCount = oBugs.load(oCon1, new Object[]{sWorkArea,sWorkArea,"%"+sTxClient+"%","%"+sTxClient+"%",sWorkArea,"%"+sTxClient+"%","%"+sTxClient+"%"});
      }    
    }
        
    oCon1.close("bug_report");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("bug_report");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
      
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  catch (NumberFormatException e) {
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
      
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  if (null==oCon1) return;
  oCon1=null;
  
%>

<HTML>
  <HEAD>
    <TITLE>hipergate :: Incident Listing</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  </HEAD>
  
  <!-- Black and white page (printer friendly styles) -->
  
  <BODY BGCOLOR="white">
    <FONT FACE="Arial" SIZE="4" COLOR="black"><B>Incident Listing</B></FONT>
    <BR><BR>
    <TABLE CELLSPACING="0" CELLPADDING="2">      
      <%
      for (int r=0; r<iRowCount; r++) {
        if (!sLastProj.equals(oBugs.getString(0,r))) {
          sLastProj = oBugs.getString(0,r);        
          out.write("      <TR>\n");
          out.write("        <TD COLSPAN=\"7\" BGCOLOR=\"black\"><FONT FACE=\"Arial\" SIZE=\"2\" COLOR=\"white\"><B>" + sLastProj + "</B></FONT></TD>\n");
          out.write("      </TR>\n");
        }                 
      %>
      <TR>
        <TD><FONT CLASS="textsmall"><%=oBugs.get(1,r)%></FONT></TD>
        <%
           switch (oBugs.getInt(2,r)) {
             case 1 : out.write("        <TD><IMG SRC=\"../images/images/highimp.gif\" WIDTH=\"12\" HEIGHT=\"16\" BORDER=\"0\"></TD>\n");
		      break;
             case 5 : out.write("        <TD><IMG SRC=\"../images/images/lowimp.gif\" WIDTH=\"12\" HEIGHT=\"16\" BORDER=\"0\"></TD>\n");
		      break;
	     default: out.write("        <TD><IMG SRC=\"../images/images/spacer.gif\" WIDTH=\"12\" HEIGHT=\"16\" BORDER=\"0\"></TD>\n");		     
           }
        %>
        <TD><FONT CLASS="textplain"><%=oBugs.getString(5,r)%></FONT></TD>
        <TD><FONT CLASS="textsmall"><%=oSimpleDate.format((Date) oBugs.get(6,r))%></FONT></TD>
        <TD><FONT CLASS="textsmall"><%=(oBugs.get(7,r)==null ? "PENDING" : "CORREGIDO")%></FONT></TD>
        <TD><FONT CLASS="textsmall">PRIORITY <%=oBugs.getInt(2,r)%></FONT></TD>
        <TD><% if (bIsAdmin) out.write("<FONT CLASS=\"textsmall\">"+oBugs.getString(8,r)+"</FONT>"); %></TD>
      </TR>
      <TR>
        <TD COLSPAN="7">
          <FONT CLASS="textsmall"><%=oBugs.getString(DB.tx_bug_brief,r)%></FONT>
        </TD>
      </TR>
      <% 
      if (!oBugs.isNull(DB.tx_comments,r)) {
        out.write("      <TR>\n");
        out.write("        <TD COLSPAN=\"7\">\n");
        out.write("          <IMG SRC=\"../images/images/caveat.gif\" BORDER=\"0\">&nbsp;<FONT CLASS=\"textsmall\"><I>" + oBugs.getString(DB.tx_comments,r) + "</I></FONT>\n");
        out.write("        </TD>\n");
        out.write("      </TR>\n");        
      }
      %>
      <TR>
        <TD COLSPAN="7">
	  <HR>
        </TD>
      </TR>
      <% } // next (r) %>
    </TABLE>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>