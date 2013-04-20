<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.scheduler.Job,com.knowgate.scheduler.Atom,com.knowgate.dataxslt.db.PageSetDB,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
  String gu_workarea = getCookie(request,"workarea","");

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sJobLog = sStorage + "jobs" + File.separator + gu_workarea + File.separator + gu_job + ".txt";
  File oJobLog = new File(sJobLog);
      
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
  int nAborted=0,nPending=0,nSuspended=0,nInterruptedRecoverable=0,nInterruptedArchived=0,nArchived=0,nNotArchived=0,nSent=0,nBlackListed=0;

  JDCConnection oConn = GlobalDBBind.getConnection("jobmodify");
  DBSubset oCounts = new DBSubset(DB.k_job_atoms, "COUNT(*) AS nu_atoms,"+DB.id_status, DB.gu_job+"=? GROUP BY "+DB.id_status, 10);
  DBSubset oCounta = new DBSubset(DB.k_job_atoms_archived, "COUNT(*) AS nu_atoms,"+DB.id_status, DB.gu_job+"=? GROUP BY "+DB.id_status, 10);
  DBSubset oBlackL = new DBSubset(DB.k_job_atoms+" a", DB.pg_atom,
  																DB.gu_job+"=? AND "+DB.id_status+"="+String.valueOf(Atom.STATUS_INTERRUPTED)+" AND "+
  												 				"EXISTS (SELECT b."+DB.tx_email+" FROM "+DB.k_global_black_list+" b WHERE b."+DB.gu_workarea+"=? AND a."+DB.tx_email+"=b."+DB.tx_email+")", 1000);
  												 				// "EXISTS (SELECT g."+DB.tx_email+" FROM k_grey_list g WHERE g."+DB.tx_email+"=a."+DB.tx_email+") OR "+

  int nCounts = 0;
  
  try {
    oJob = Job.instantiate(oConn, gu_job, Environment.getProfile(GlobalDBBind.getProfileName()));		
		
    if (null==oJob) throw new InstantiationException("Could not instantiate job "+gu_job);

		// Archive all interrumpted atoms because they are black-listed before collecting totals
		int nBlackL = oBlackL.load(oConn, new Object[]{gu_job,oJob.getString(DB.gu_workarea)});
		Atom oAtm = new Atom();
		oAtm.put(DB.gu_job, gu_job);
		oConn.setAutoCommit(false);
		for (int b=0; b<nBlackL; b++) {
		  oAtm.put(DB.pg_atom, oBlackL.getInt(0,b));
		  oAtm.archive(oConn);
		}
		oConn.commit();
		
		nBlackListed = DBCommand.queryCount(oConn, "*", DB.k_job_atoms_archived+" a",
									 DB.gu_job+"='"+gu_job+"' AND "+DB.id_status+"="+String.valueOf(Atom.STATUS_INTERRUPTED)+" AND "+
  								 "EXISTS (SELECT b."+DB.tx_email+" FROM "+DB.k_global_black_list+" b WHERE b."+DB.gu_workarea+"='"+oJob.getString(DB.gu_workarea)+"' AND a."+DB.tx_email+"=b."+DB.tx_email+")");
  							// "EXISTS (SELECT g."+DB.tx_email+" FROM k_grey_list g WHERE g."+DB.tx_email+"=a."+DB.tx_email+") OR "+
		
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

		nCounts = oCounts.load(oConn, new Object[]{gu_job});
    for (int c=0; c<nCounts; c++) {
      switch (oCounts.getShort(1,c)) {
        case Job.STATUS_ABORTED:
          nAborted = oCounts.getInt(0,c);
          break;
        case Job.STATUS_PENDING:
          nPending = oCounts.getInt(0,c);
          break;
        case Job.STATUS_SUSPENDED:
          nSuspended = oCounts.getInt(0,c);
          break;
        case Job.STATUS_INTERRUPTED:
          nInterruptedRecoverable = oCounts.getInt(0,c);
          break;
      }
    } // next
		
		nCounts = oCounta.load(oConn, new Object[]{gu_job});
    for (int c=0; c<nCounts; c++) {
      switch (oCounta.getShort(1,c)) {
        case Job.STATUS_ABORTED:
          nAborted += oCounta.getInt(0,c);
          break;
        case Job.STATUS_PENDING:
          nPending += oCounta.getInt(0,c);
          break;
        case Job.STATUS_SUSPENDED:
          nSuspended += oCounta.getInt(0,c);
          break;
        case Job.STATUS_INTERRUPTED:
          nInterruptedArchived = oCounta.getInt(0,c)-nBlackListed;
          break;
      }
    } // next

    nNotArchived = DBCommand.queryCount(oConn, "*", DB.k_job_atoms, DB.gu_job+"='"+gu_job+"'");
    nArchived = DBCommand.queryCount(oConn, "*", DB.k_job_atoms_archived, DB.gu_job+"='"+gu_job+"'");
    nSent = DBCommand.queryCount(oConn, "*", DB.k_job_atoms_archived, DB.gu_job+"='"+gu_job+"' AND "+DB.id_status+" IN (0,3)");

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

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Task</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      function showCalendar(ctrl) {
        var dtnw = new Date();
        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      function validate() {
        var frm = document.forms[0];
        if (frm.tl_job.value.length==0) {
          alert ("The name of the job may not be empty");
          frm.tl_job.focus();
          return false;
        }
        return true;
      } // validate

    //-->
  </SCRIPT>
</HEAD>
<BODY >

  <TABLE CELLSPACING="0" CELLPADDING="0" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="4" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Task</FONT></TD></TR>
  </TABLE>
  <BR/>
  <CENTER>
  <FORM METHOD="post" ACTION="job_modify_store.jsp" onSubmit="return validate()">
  	<INPUT TYPE="hidden" NAME="gu_job" VALUE="<%=oJob.getString(DB.gu_job)%>">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="390"><INPUT TYPE="text" NAME="tl_job" MAXLENGTH="100" SIZE="30" VALUE="<%=oJob.getStringNull(DB.tl_job,"")%>">&nbsp;<INPUT TYPE="submit" CLASS="pushbutton" VALUE="Modify"></TD>
          </TR>
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
<% }
   if (oJob.getString(DB.id_command).equals("SEND") || oJob.getString(DB.id_command).equals("MAIL")) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><IMG SRC="../images/images/jobs/statistics16.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Statistics"></TD>
            <TD ALIGN="left" WIDTH="390"><A HREF="job_followup_stats.jsp?gu_job=<%=gu_job%>" TARGET="_top" CLASS="linkplain">Show statistics</A></TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><IMG SRC="../images/images/jobs/atoms16.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Atoms"></TD>
            <TD ALIGN="left" WIDTH="390"><A HREF="job_viewatoms.jsp?gu_job=<%=gu_job%>" TARGET="_top" CLASS="linkplain">View atoms</A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"></TD>
            <TD ALIGN="left" WIDTH="390" CLASS="textsmall"><TABLE><%
              out.write("<TR><TD CLASS=\"textsmall\"><B>Batch Total</B></TD><TD CLASS=\"textsmall\"><B>"+String.valueOf(nArchived+nNotArchived)+"</B></TD></TR>");
              out.write("<TR><TD CLASS=\"textsmall\">Sent</TD><TD CLASS=\"textsmall\">"+String.valueOf(nSent)+"</TD></TR>");
              if (nBlackListed>0) out.write("<TR><TD CLASS=\"textsmall\">Blocked</TD><TD CLASS=\"textsmall\">"+String.valueOf(nBlackListed)+"</TD></TR>\n");
              out.write("<TR><TD CLASS=\"textsmall\">Pending</TD><TD CLASS=\"textsmall\">"+String.valueOf(nPending)+"</TD></TR>");
							if (nAborted>0) out.write("<TR><TD CLASS=\"textsmall\">Aborted</TD><TD CLASS=\"textsmall\">"+String.valueOf(nAborted)+"</TD></TR>\n");
              if (nSuspended>0) out.write("<TR><TD CLASS=\"textsmall\">Suspended</TD><TD CLASS=\"textsmall\">"+String.valueOf(nSuspended)+"</TD></TR>\n");
              if (nInterruptedRecoverable==0 && nInterruptedArchived==0) {
                out.write("<TR><TD CLASS=\"textsmall\">Failed</TD><TD CLASS=\"textsmall\">0</TD></TR>\n");
              } else {
                if (nInterruptedRecoverable>0) out.write("<TR><TD CLASS=\"textsmall\">Recoverable</TD><TD CLASS=\"textsmall\">"+String.valueOf(nInterruptedRecoverable)+"</TD></TR>\n");
                if (nInterruptedArchived>0) out.write("<TR><TD CLASS=\"textsmall\">Unrecoverable</TD><TD CLASS=\"textsmall\">"+String.valueOf(nInterruptedArchived)+"</TD></TR>\n");
              }

            %></TABLE></TD>
          </TR>
<% if (nInterruptedRecoverable>0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><IMG SRC="../images/images/jobs/recycleatoms16.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Recycle Atoms"></TD>
            <TD ALIGN="left" WIDTH="390"><A HREF="job_recycle.jsp?gu_job=<%=gu_job%>" CLASS="linkplain">Re-try failed atoms</A></TD>
          </TR>
<% } %>
<% if (oJobLog.exists()) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><IMG SRC="../images/images/jobs/logfile16.gif" WIDTH="16" HEIGHT="16" HSPACE="4" BORDER="0" ALT="Log File"></TD>
            <TD ALIGN="left" WIDTH="390"><A HREF="job_viewlog.jsp?gu_job=<%=gu_job%>" TARGET="_blank" CLASS="linkplain">View log file</A></TD>
          </TR>
<% } %>
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