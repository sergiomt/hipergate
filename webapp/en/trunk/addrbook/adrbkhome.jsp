<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Timestamp,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
  String sFace = nullif(request.getParameter("face"),getCookie(request,"face","crm"));

  String id_domain = getCookie(request, "domainid", "0");
  String n_domain = getCookie(request, "domainnm", "");
  String gu_user = getCookie(request, "userid", "");
  String gu_workarea = getCookie(request, "workarea", "");

  String sStart, sToday = DBBind.escape(new Date(), "shortDate");
  Date dtStart;

  boolean bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);

  JDCConnection oConn = null;
  DBSubset oCalls = new DBSubset (DB.k_phone_calls, DB.gu_phonecall + "," + DB.tp_phonecall + "," + DB.dt_start + "," + DB.dt_end + "," + DB.gu_contact + "," + DB.contact_person + "," + DB.tx_phone + "," + DB.tx_comments,
    				    DB.gu_workarea + "=? AND " + DB.gu_user + "=? AND " + DB.id_status + "=0 ORDER BY 3 DESC", 10);
  int iCalls = 0;

  DBSubset oToDo = new DBSubset (DB.k_to_do, DB.gu_to_do + "," + DB.od_priority + "," + DB.tl_to_do,
    				    DB.gu_user + "=? AND (" + DB.tx_status + "='PENDING' OR " + DB.tx_status + " IS NULL) ORDER BY 2 DESC", 10);
  int iToDo = 0;

  try {
      oConn = GlobalDBBind.getConnection("addrbkhome");

      iCalls = oCalls.load (oConn, new Object[]{gu_workarea,gu_user});

      oToDo.setMaxRows(10);
      iToDo = oToDo.load (oConn, new Object[]{gu_user});

      oConn.close("addrbkhome");
  }
  catch (SQLException e) {
      if (oConn!=null)
        if (!oConn.isClosed()) oConn.close("addrbkhome");
      oConn = null;

      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn = null;
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Collaborative Tools</TITLE>
  <SCRIPT SRC="../javascript/cookies.js" TYPE="text/javascript"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js" TYPE="text/javascript"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--

    var activity_edition_page = "<% out.write(sFace.equalsIgnoreCase("healthcare") ? "appointment_edit_f.htm" : "meeting_edit_f.htm"); %>";

    // ------------------------------------------------------

    function createMeeting() {
        window.open(activity_edition_page+"?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid") + "&date=<%=sToday%>", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
    }

    // ------------------------------------------------------

    function modifyMeeting(gu) {
        window.open(activity_edition_page+"?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid") + "&gu_meeting=" + gu, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
    }

    // ------------------------------------------------------

    function createVisit() {
        window.open("visit_edit_f.htm?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid") + "&date=<%=sToday%>", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
    }

    // ----------------------------------------------------

    function searchfellow() {
      var frm = document.forms[0];
      var nmc = frm.full_name.value;

      if (nmc.length==0) {
        alert ("Type name and surname of person to find");
        window.location = window.location.href;
        return false;
      }

      if (nmc.indexOf("'")>0 || nmc.indexOf('"')>0 || nmc.indexOf("?")>0 || nmc.indexOf("%")>0 || nmc.indexOf("*")>0 || nmc.indexOf("&")>0 || nmc.indexOf("/")>0) {
	      alert ("The name contains invalid characters");
	      return false;
      }
      else
        window.location = "fellow_listing.jsp?selected=1&subselected=3&queryspec=fellows&where=" + escape(" AND (<%=DB.tx_name%> <%=DBBind.Functions.ILIKE%> '" + nmc + "%' OR <%=DB.tx_surname%> LIKE '%" + nmc + "%') ");
    }

    // ------------------------------------------------------

    function viewContact(id) {
      self.open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));
    }

  //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0">
<%@ include file="../common/tabmenu.jspf" %>
<BR>
<TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Collaborative Tools</FONT></TD></TR></TABLE>
<FORM NAME="loginForm" METHOD="POST" ACTION="../servlet/WebMail/login" TARGET="_blank">
  <INPUT TYPE="hidden" NAME="login">
  <INPUT TYPE="hidden" NAME="password">
  <INPUT TYPE="hidden" NAME="vdom">
  <TABLE>
  <TR>
  <TD>
  <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
    <!-- Pestaña superior -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD BACKGROUND="../images/images/graylinebottom.gif">
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_24x24.gif" style="display:block" WIDTH="24" HEIGHT="24" BORDER="0"></TD>
	  </TR>
          <TR>
            <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" COLSPAN="2" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">Tasks</TD>
          </TR>
        </TABLE>
      </TD>
      <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG style="display:block" SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea gris y roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Cuerpo de Correo-->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="menu1">
        <TABLE CELLSPACING="8" BORDER="0">
          <TR>
            <TD ROWSPAN="2" ALIGN="center">
              <IMG SRC="../images/images/projtrack/duties.gif" BORDER="0" ALT="Tasks">
            </TD>
            <TD>
              <TABLE><TR><TD><IMG SRC="../images/images/new16x16.gif" BORDER="0" ALT=""></TD><TD VALIGN="middle"><A HREF="#" onclick="window.open('todo_edit.jsp?gu_workarea=' + getCookie('workarea'),null,'directories=no,toolbar=no,menubar=no,width=500,height=400')" CLASS="linkplain">New Task</A></TD></TR></TABLE>
            </TD>
          </TR>
    	  <TR>
      	    <TD COLSPAN="2">
              <TABLE>
<%
  String sTitle, sPriority;


  for (int d=0; d<iToDo; d++) {

    sTitle = Gadgets.left(oToDo.getString(2,d),60);

    if (oToDo.isNull(1,d))
      sPriority = "";
    else
      sPriority = String.valueOf(oToDo.getInt(1,d));

    out.write("                <TR><TD><FONT CLASS=\"textplain\">" + sPriority + "</FONT></TD><TD><A CLASS=\"linkplain\" HREF=\"#\" onclick=\"window.open('todo_edit.jsp?gu_workarea=' + getCookie('workarea') + '&gu_to_do=" + oToDo.getString(0,d) + "',null,'directories=no,toolbar=no,menubar=no,width=500,height=400')\">" + sTitle + (sTitle.length()==60 ? "..." : "") + "</A></TD><TD><A HREF=\"#\" onclick=\"window.open('todo_finish.jsp?gu_workarea=' + getCookie('workarea') + '&gu_to_do=" + oToDo.getString(0,d) + "',null,'directories=no,toolbar=no,menubar=no,width=500,height=400')\" TITLE=\"End Task\"><IMG SRC=\"../images/images/checkmark16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\"></A></TD></TR>\n");
  }


  out.write("<TR><TD></TD><TD><A CLASS=\"linkplain\" HREF=\"to_do_listing.jsp\"><B>more...</B></A></TD></TR>");
%>
	      </TABLE>
            </TD>
          </TR>
        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
      <TD ><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
    </TR>
    <!-- Pestaña media -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD>
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG  style="display:block"SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
	  </TR>
          <TR>
      	    <TD COLSPAN="2" BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/3x3puntos.gif" BORDER="0">Calendar</TD>
          </TR>
        </TABLE>
      </TD>
      <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Cuerpo de Calendario -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="menu1">
        <TABLE CELLSPACING="8" BORDER="0">
          <TR>
            <TD ROWSPAN="2" ALIGN="center">
              <A HREF="schedule.jsp?selected=1&subselected=1" TITLE="Calendar"><IMG SRC="../images/images/addrbook/calendarxp32.gif" BORDER="0" ALT="Calendar"></A>
            </TD>
            <TD VALIGN="top">
<% if (bIsGuest) {
     out.write("	      <TABLE BORDER=0 CELLSPACING=2 CELLPADDING=0>");
     out.write("<TR><TD><IMG SRC=\"../images/images/new16x16.gif\" BORDER=\"0\"></TD><TD>&nbsp;</TD><TD><A CLASS=\"linkplain\" HREF=\"#\" onClick=\"alert('Your credential level as Guest does not allow you to perform this action')\">" + (sFace.equalsIgnoreCase("healthcare") ? "New Appointment" : "New Activity") + "</A></TD></TR>");
     out.write("<TR><TD COLSPAN=\"2\"></TD><TD><A CLASS=\"linkplain\" HREF=\"#\" onClick=\"alert('Your credential level as Guest does not allow you to perform this action')\">Arrange meeting for another person</A></TD></TR>");
     out.write("</TABLE>");
   } else {
     out.write("	      <TABLE BORDER=0 CELLSPACING=2 CELLPADDING=0>");
     out.write("<TR><TD><IMG SRC=\"../images/images/new16x16.gif\" BORDER=\"0\"></TD><TD>&nbsp;</TD><TD><A CLASS=\"linkplain\" HREF=\"#\" onClick=\"createMeeting()\">" + (sFace.equalsIgnoreCase("healthcare") ? "New Appointment" : "New Activity") + "</A></TD></TR>");
     if (!sFace.equalsIgnoreCase("healthcare")) {
       out.write("<TR><TD COLSPAN=\"2\"></TD><TD><A CLASS=\"linkplain\" HREF=\"#\" onClick=\"createVisit()\">Arrange meeting for another person</A></TD></TR>");
     }
     out.write("</TABLE>");
   }
   out.flush();
%>
	      <A CLASS="linkplain" HREF="schedule.jsp?selected=1&subselected=1" TITLE="Calendar for today">Today</A><BR>
<%
	      Date dt00 = new Date();
	      Date dt23 = new Date();

	      dt00.setHours(0);
     	      dt00.setMinutes(0);
     	      dt00.setSeconds(0);

	      dt23.setHours(23);
     	      dt23.setMinutes(59);
     	      dt23.setSeconds(59);
%>
	      <A CLASS="linkplain" HREF="javascript:window.location='month_schedule.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_fellow=<%=gu_user%>&selected=1&subselected=1&year=<%=dt00.getYear()%>&month=<%=dt00.getMonth()%>&screen_width='+String(screen.width)" TITLE="Calendar for this month">Calendar for this month</A><BR>
<%
	      JDCConnection oCon2 = GlobalDBBind.getConnection("today");
	      PreparedStatement oStm2;
	      ResultSet oRSe2;

	      try  {
      		if (com.knowgate.debug.DebugFile.trace) {
      		  com.knowgate.debug.DebugFile.writeln("<JSP:adrbkhome.jsp Connection.prepareStatement(SELECT m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ",m." + DB.dt_start + ",m." + DB.dt_end + " FROM " + DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f WHERE m." + DB.gu_meeting + "=f." + DB.gu_meeting + " AND f." + DB.gu_fellow + "='"+gu_user+"' AND m." + DB.dt_start + " BETWEEN " + dt00.toString() + " AND "+ dt23.toString() +" ORDER BY m." + DB.dt_start + ")");
	        }
	        
	        oStm2 = oCon2.prepareStatement("SELECT m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ",m." + DB.dt_start + ",m." + DB.dt_end + " FROM " + DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f WHERE m." + DB.gu_meeting + "=f." + DB.gu_meeting + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + " BETWEEN ? AND ? ORDER BY m." + DB.dt_start, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
		oStm2.setString(1, gu_user);
		oStm2.setTimestamp(2, new Timestamp(dt00.getTime()));
		oStm2.setTimestamp(3, new Timestamp(dt23.getTime()));
      		if (com.knowgate.debug.DebugFile.trace) {
      		  com.knowgate.debug.DebugFile.writeln("PreparedStatement.executeQuery()");
	        }
		oRSe2 = oStm2.executeQuery();
		while (oRSe2.next()) {
		  Timestamp dtFrom = oRSe2.getTimestamp(5);
		  Timestamp dtTo = oRSe2.getTimestamp(6);

		  out.write ("<FONT CLASS=\"formplain\">of " + String.valueOf(dtFrom.getHours())+":"+String.valueOf(dtFrom.getMinutes()) + " to " + String.valueOf(dtTo.getHours())+":"+String.valueOf(dtTo.getMinutes()) + "</FONT>&nbsp;");
		  out.write ("<A CLASS=\"linkplain\" HREF=\"#\" onClick=\"modifyMeeting('" + oRSe2.getString(1) + "');return false\">");
		  
		  /*
		  if (null!=oRSe2.getObject(3)) {
		    out.write (DBLanguages.getLookUpTranslation((java.sql.Connection) oCon2, DB.k_meetings_lookup, gu_workarea, "tp_meeting", sLanguage, oRSe2.getString(3));
		    out.write (" ");
		  }
		  */

		  out.write (nullif(oRSe2.getString(4),"Untitled"));
		  out.write ("</A><BR>");
		} // wend
		oRSe2.close();
		oStm2.close();
    	        oCon2.close("today");
	      }
  	      catch (Exception e) {
    		if (oCon2!=null)
    		  if (!oCon2.isClosed())
    		    oCon2.close("today");
    		oCon2 = null;
    		out.write(e.getClass().getName()+" "+e.getMessage());
		out.flush();
                }
	      if (null==oCon2) return;
	      oCon2 = null;
%>
            </TD>
	  </TR>
        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>

    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
      <TD ><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
    </TR>
    <!-- Pestaña media -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD>
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG style="display:block" SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
	  </TR>
          <TR>
      	    <TD COLSPAN="2" BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/3x3puntos.gif" BORDER="0">Directory</TD>
          </TR>
        </TABLE>
      </TD>
      <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Cuerpo de Personal -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="menu1">
        <TABLE CELLSPACING="8" BORDER="0">
          <TR>
            <TD ROWSPAN="2" ALIGN="center">
              <A HREF="fellow_listing.jsp?selected=1&subselected=3" TITLE="Corporate Directory"><IMG SRC="../images/images/addrbook/employee_card.gif" BORDER="0" ALT="Corporate Directory"></A>
            </TD>
            <TD>
              <INPUT TYPE="text" NAME="full_name" MAXLENGTH="50">
            </TD>
            <TD>
              <A HREF="#" onClick="searchfellow();return false" CLASS="linkplain">Find Person</A>
            </TD>
          </TR>
        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Línea gris -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle"><IMG style="display:block" SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0"></TD>
      <TD  BACKGROUND="../images/images/graylinefloor.gif"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0"></TD>
    </TR>
  </TABLE>
  </TD>
  <TD VALIGN="top">

  <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
    <!-- Pestaña superior -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD BACKGROUND="../images/images/graylinebottom.gif">
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_24x24.gif" style="display:block" WIDTH="24" HEIGHT="24" BORDER="0"></TD>
	  </TR>
          <TR>
      	    <TD COLSPAN="2" BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/3x3puntos.gif" BORDER="0">Calls</TD>
          </TR>
        </TABLE>
      </TD>
      <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG style="display:block" SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea gris y roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Cuerpo de Llamadas-->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="menu1">
        <TABLE CELLSPACING="8" BORDER="0">
          <TR>
            <TD ALIGN="center">
              <IMG SRC="../images/images/addrbook/telephone24.gif" BORDER="0" ALT="">
            </TD>
            <TD ALIGN="left" VALIGN="middle">
              <TABLE><TR><TD><IMG SRC="../images/images/new16x16.gif" BORDER="0"></TD><TD VALIGN="middle"><A HREF="#" onclick="window.open('phonecall_edit_f.jsp?gu_workarea=' + getCookie('workarea'),null,'directories=no,toolbar=no,menubar=no,width=500,height=400')" CLASS="linkplain">New Call</A></TD></TR></TABLE>
	    </TD>
	  </TR>
	  <TR>
	    <TD COLSPAN="2">
	      <FONT CLASS="formstrong">Received</FONT>
	      <BR>
	      <TABLE>
<% for (int r=0; r<iCalls; r++) {

     if (oCalls.getString(1,r).equals("R")) {

       if (oCalls.isNull(2,r))
         sStart = "";
       else {
         dtStart = oCalls.getDate(2,r);

         sStart = Gadgets.leftPad(String.valueOf(dtStart.getHours()), '0', 2) + ":" + Gadgets.leftPad(String.valueOf(dtStart.getMinutes()), '0', 2);
       }

       if (oCalls.isNull(4,r))
         out.write("<TR><TD ALIGN=\"right\"><FONT CLASS=\"textsmall\">" + sStart + "</FONT></TD><TD><A CLASS=\"linksmall\" TITLE=\"" + oCalls.getStringNull(7,r,"") + "\">" + oCalls.getStringNull(5,r,"unknown") + "</A></TD><TD><FONT CLASS=\"textsmall\">" + oCalls.getStringNull(6,r,"") + "</FONT></TD><TD><A HREF=\"phonecall_acknowledge.jsp?checkeditems=" + oCalls.getString(0,r) + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\"><IMG SRC=\"../images/images/checkmark16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Archive\"></A></TD></TR>");
       else
         out.write("<TR><TD ALIGN=\"right\"><FONT CLASS=\"textsmall\">" + sStart + "</FONT></TD><TD><A CLASS=\"linksmall\" HREF=\"#\" onclick=\"viewContact('" + oCalls.getString(4,r) + "')\" TITLE=\"" + oCalls.getStringNull(7,r,"") + "\">" + oCalls.getStringNull(5,r,"unknown") + "</A></TD><TD><FONT CLASS=\"textsmall\">" + oCalls.getStringNull(6,r,"") + "</FONT></TD><TD><A HREF=\"phonecall_acknowledge.jsp?checkeditems=" + oCalls.getString(0,r) + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\"><IMG SRC=\"../images/images/checkmark16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Archive\"></A></TD></TR>");
     }

   } // next (r)
%>
	      </TABLE>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2">
              <FONT CLASS="formstrong">Pending</FONT>
	      <BR>
	      <TABLE>
<%   for (int r=0; r<iCalls; r++) {

     if (oCalls.getString(1,r).equals("S")) {

       if (oCalls.isNull(2,r))
         sStart = "";
       else {
         dtStart = oCalls.getDate(2,r);

         sStart = Gadgets.leftPad(String.valueOf(dtStart.getHours()), '0', 2) + ":" + Gadgets.leftPad(String.valueOf(dtStart.getMinutes()), '0', 2);
       }

       if (oCalls.isNull(4,r))
         out.write("<TR><TD ALIGN=\"right\"><FONT CLASS=\"textsmall\">" + sStart + "</FONT></TD><TD><A CLASS=\"linksmall\" TITLE=\"" + oCalls.getStringNull(7,r,"") + "\">" + oCalls.getStringNull(5,r,"unknown") + "</A></TD><TD><FONT CLASS=\"textsmall\">" + oCalls.getStringNull(6,r,"") + "</FONT></TD><TD><A HREF=\"phonecall_acknowledge.jsp?checkeditems=" + oCalls.getString(0,r) + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\"><IMG SRC=\"../images/images/checkmark16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"All right\"></A></TD></TR>");
       else
         out.write("<TR><TD ALIGN=\"right\"><FONT CLASS=\"textsmall\">" + sStart + "</FONT></TD><TD><A CLASS=\"linksmall\" HREF=\"#\" onclick=\"viewContact('" + oCalls.getString(4,r) + "')\" TITLE=\"" + oCalls.getStringNull(7,r,"") + "\">" + oCalls.getStringNull(5,r,"unknown") + "</A></TD><TD><FONT CLASS=\"textsmall\">" + oCalls.getStringNull(6,r,"") + "</FONT></TD><TD><A HREF=\"phonecall_acknowledge.jsp?checkeditems=" + oCalls.getString(0,r) + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\"><IMG SRC=\"../images/images/checkmark16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"All right\"></A></TD></TR>");
     }

   } // next (r)

%>
	      </TABLE>
            </TD>
          </TR>
        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>

    <!-- Línea gris -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle"><IMG style="display:block" SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0"></TD>
      <TD  BACKGROUND="../images/images/graylinefloor.gif"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0"></TD>
    </TR>
  </TABLE>

  </TD>
  </TR>
  </TABLE>
</FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>
