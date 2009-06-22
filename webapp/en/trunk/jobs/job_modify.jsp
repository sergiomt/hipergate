<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.scheduler.Job,com.knowgate.dataxslt.db.PageSetDB,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%
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
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);
  
  String gu_job = request.getParameter("gu_job");
    
  boolean bStmt = false;
  boolean bRSet = false;
  DBSubset oJobCmd = null;
  Job oJob = null;
  String sJobStatus = null;
  ACLUser oUsr = null;
  PageSetDB oPag = null;
  DistributionList oLst = null;
  String s1StPage = null;
  String sTxCmmd = null;

  JDCConnection oConn = GlobalDBBind.getConnection("jobmodify");  
      
  try {
    oJob = Job.instantiate(oConn, gu_job, Environment.getProfile(GlobalDBBind.getProfileName()));
    
    oJobCmd = new DBSubset (DB.k_lu_job_commands, DB.tx_command, DB.id_command + "='" + oJob.getString(DB.id_command) + "'", 10);      				 
    oJobCmd.load (oConn);
    sTxCmmd = oJobCmd.getString(0,0);
    sJobStatus = DBCommand.queryStr(oConn, "SELECT " + DB.tr_ + sLanguage + " FROM " + DB.k_lu_job_status + " WHERE " + DB.id_status + "=" + String.valueOf(oJob.getShort(DB.id_status)));

    oUsr = new ACLUser(oConn, oJob.getString(DB.gu_writer));

    if (oJob.getString(DB.id_command).equals("MAIL")) {      
      oPag = new PageSetDB (oConn, oJob.getParameter("gu_pageset"));
      oLst = new DistributionList(oConn, oJob.getParameter("gu_list"));
            
      s1StPage = DBCommand.queryStr(oConn, "SELECT " + DB.path_page + "," + DB.pg_page + " FROM " + DB.k_pageset_pages + " WHERE " + DB.gu_pageset + "='" + oJob.getParameter("gu_pageset") + "' ORDER BY 2");
    }
    
    oConn.close("jobmodify");
    
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("jobmodify");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  catch (ClassNotFoundException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("jobmodify");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "ClassNotFoundException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ClassNotFoundException&desc=" + e.getMessage() + "&resume=_close"));
  }
  catch (IllegalAccessException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("jobmodify");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IllegalAccessException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalAccessException&desc=" + e.getMessage() + "&resume=_close"));
  }
  catch (InstantiationException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("jobmodify");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "InstantiationException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=InstantiationException&desc=" + e.getMessage() + "&resume=_close"));
  }
  catch (NullPointerException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("jobmodify");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NullPointerException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=_close"));
  }

  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Task</TITLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()            
      
    //-->
  </SCRIPT>
</HEAD>
<BODY >

  <TABLE CELLSPACING="0" CELLPADDING="0" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="4" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Task</FONT></TD></TR>
  </TABLE>  
  <CENTER>
  <FORM METHOD="post">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formstrong">Task:</FONT></TD>
            <TD ALIGN="left" WIDTH="390"><FONT CLASS="textplain">(<% out.write(sTxCmmd); %></FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formstrong">Owner:</FONT></TD>
            <TD ALIGN="left" WIDTH="390"><FONT CLASS="textplain"><B><%=oUsr.getString(DB.tx_nickname)%>&nbsp;</B><I>(<%=oUsr.getStringNull(DB.nm_user,"")+"&nbsp;"+oUsr.getStringNull(DB.tx_surname1,"")%>)</I><FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formstrong">Status:</FONT></TD>
            <TD ALIGN="left" WIDTH="390"><FONT CLASS="textplain"><% out.write(sJobStatus); %></FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Execution Date</FONT></TD>
            <TD ALIGN="left" WIDTH="390">
<%	    if (oJob.isNull(DB.dt_execution))
	      out.write("              <FONT CLASS=\"textplain\">As soon as possible</FONT>");
	    else
	      out.write("              <FONT CLASS=\"textplain\">" + oJob.getDateFormated(DB.dt_execution, "yyyy-MM-dd") + "</FONT>");
%>
              <!--<A HREF="javascript:showCalendar('dt_execution')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>-->
            </TD>
          </TR>
<%	  if (oJob.getStringNull(DB.id_command,"").equals("MAIL")) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Document to be processed:</FONT></TD>
            <TD ALIGN="left" WIDTH="390"><FONT CLASS="textplain">
<%          if (s1StPage==null)
  	      out.write("              " + oPag.getStringNull(DB.nm_pageset,""));
  	    else
  	      out.write("              <A HREF=\"../common/servepage.jsp?filepath=" + Gadgets.URLEncode(s1StPage) + "\" TARGET=\"_blank\" CLASS=\"linkplain\" TITLE=\"View document to be sended\">" + oPag.getStringNull(DB.nm_pageset,"Untitled document") + "</A>");
%>
	      </FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Recipients List:</FONT></TD>
            <TD ALIGN="left" WIDTH="390"><FONT CLASS="textplain"><%=oLst.getStringNull(DB.de_list,"")%></FONT></TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><IMG SRC="../images/images/jobs/atoms16.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Atoms"></TD>
            <TD ALIGN="left" WIDTH="390"><A HREF="job_viewatoms.jsp?gu_job=<%=gu_job%>" TARGET="_top" CLASS="linkplain">[~Ver átomos~]</A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><IMG SRC="../images/images/jobs/logfile16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Log File"></TD>
            <TD ALIGN="left" WIDTH="390"><A HREF="job_viewlog.jsp?gu_job=<%=gu_job%>" TARGET="_blank" CLASS="linkplain">View log file</A></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"></TD>
          </TR>
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
  </CENTER>

</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>