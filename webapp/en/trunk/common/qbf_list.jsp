<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%
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

  final int BugTracker=10,DutyManager=11,ProjectManager=12,Mailwire=13,WebBuilder=14,VirtualDisk=15,Sales=16,CollaborativeTools=17,MarketingTools=18,Shop=20,Config=30;

  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

  JDCConnection oConn = null;
  String sSchema = "";
  String sToday = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new Date());
  
  DBSubset oRootPrjs = new DBSubset(DB.k_projects, DB.gu_project+","+DB.nm_project, DB.gu_owner+"=? AND " + DB.id_parent + " IS NULL ORDER BY 2", 100);
  int iRootPrjs = 0;
  DBSubset oCampaigns = new DBSubset(DB.k_campaigns, DB.gu_campaign+","+DB.nm_campaign, DB.bo_active+"<>0 AND "+DB.gu_workarea+"=? ORDER BY 2", 10);
  int iCampaigns = 0;

  int iDBMS = JDCConnection.DBMS_GENERIC;
  
  try {    
    oConn = GlobalDBBind.getConnection("qbf_list");  
    
    iDBMS = oConn.getDataBaseProduct();
    
    iRootPrjs = oRootPrjs.load(oConn, new Object[]{getCookie(request, "workarea", "")});

    if (iDBMS==JDCConnection.DBMS_MSSQL) sSchema=oConn.getSchemaName()+".";

    if ((iAppMask & (1<<MarketingTools))!=0) {
      iCampaigns = oCampaigns.load(oConn, new Object[]{getCookie(request, "workarea", "")});
    }
    
    oConn.close("qbf_list");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("qbf_list");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;    
%>
<HTML>
  <HEAD>
    <TITLE>hipergate :: Queries</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      // ----------------------------------------------------------------------
          
      function openQueryForm(sQBF) {
        
        if ("bugs"==sQBF)
          window.opener.top.location = "../projtrack/bug_query.jsp";
        else
          window.opener.top.location = "../common/qbf.jsp?queryspec=" + sQBF;
	
	self.close();
      }

      // ----------------------------------------------------------------------
      
      function openExcelSheet(qry) {
        var frm = document.forms[0];
        
        if (qry=="won") {
          if (frm.dt_won.value.length>0 && !isDate(frm.dt_won.value,"d")) {
            alert ("Invalid Date");
	    return false;
          }
          else if (frm.dt_won.value.length==0)
            window.open("../crm/rp_saleswinlost.jsp?qry=won");
          else
            window.open("../crm/rp_saleswinlost.jsp?qry=won&dt_start=" + frm.dt_won.value);
        }
        else if (qry=="lost") {
          if (frm.dt_lost.value.length>0 && !isDate(frm.dt_lost.value,"d")) {
            alert ("Invalid Date");
	    return false;
          }
          else if (frm.dt_lost.value.length==0)
            window.open("../crm/rp_saleswinlost.jsp?qry=lost");
          else
            window.open("../crm/rp_saleswinlost.jsp?qry=lost&dt_start=" + frm.dt_lost.value);
        }        
      } // openExcelSheet()

      // ----------------------------------------------------------------------

      function dutiesByPerson() { 
	var frm = document.forms[0];
	
	
	if (frm.dt_start.value.length==0) {
          alert ("You must specify an start up date");
	  return false;
	}

	if (frm.dt_end.value.length==0) {
          alert ("You must specify an end date");
	  return false;
	}
        
        if (!isDate(frm.dt_start.value,"d")) {
	  alert ("Invalid Date");
	  return false;
	}

        if (!isDate(frm.dt_end.value,"d")) {
	  alert ("Invalid Date");
	  return false;
	}

<% if (iDBMS==JDCConnection.DBMS_POSTGRESQL) { %>
	window.open("../projtrack/duty_list.jsp?selected=4&subselected=1&qrymode=3&where=" + escape(" AND (b.dt_start BETWEEN TIMESTAMP '" + frm.dt_start.value + " 00:00:00' AND TIMESTAMP '" + frm.dt_end.value + " 23:59:59')"));
<% } else { %>
	window.open("../projtrack/duty_list.jsp?selected=4&subselected=1&qrymode=3&where=" + escape(" AND (b.dt_start BETWEEN { ts '" + frm.dt_start.value + " 00:00:00'} AND { ts '" + frm.dt_end.value + " 23:59:59'})"));
<% } %>
      }

      // ----------------------------------------------------------------------

      function callCenterPerformance() { 
	      var frm = document.forms[0];
	
      
      	if (frm.dt_dayn.value.length==0) {
          alert ("You must specify an end date");
      	  return false;
      	}
              
        if (frm.dt_day1.value.length>0 && !isDate(frm.dt_day1.value,"d")) {
      	  alert ("Invalid Date");
      	  frm.dt_day1.focus();
      	  return false;
      	}
      
        if (!isDate(frm.dt_dayn.value,"d")) {
      	  alert ("Invalid Date");
      	  frm.dt_dayn.focus();
      	  return false;
      	}

      	document.location = "../crm/phonecall_report.jsp?gu_workarea=<%=getCookie(request, "workarea", "")%>" + (frm.dt_day1.value.length>0 ? "&dt_from="+frm.dt_day1.value : "") + "&dt_to=" + frm.dt_dayn.value + "&gu_campaign=" + frm.gu_campaign.value;
      } // callCenterPerformance

      // ----------------------------------------------------------------------

      function costsByPerson() { 
	var frm = document.forms[0];
        
        frm.dt_start.value = rtrim(frm.dt_start.value);
        
        if (!isDate(frm.dt_from.value,"d") && frm.dt_from.value.length>0) {
	  alert ("Invalid Date");
	  return false;
	}

	frm.dt_to.value = rtrim(frm.dt_to.value);
	
        if (!isDate(frm.dt_to.value,"d") && frm.dt_to.value.length>0) {
	  alert ("Invalid Date");
	  return false;
	}
	
	var period;

<% if (iDBMS==JDCConnection.DBMS_POSTGRESQL) { %>
	if (frm.dt_from.value.length==0 && frm.dt_to.value.length==0)
	  period = "";
	else if (frm.dt_from.value.length>0 && frm.dt_to.value.length==0)
	  period = "AND b.dt_start >= TIMESTAMP '" + frm.dt_from.value + " 00:00:00' ";
	else if (frm.dt_from.value.length==0 && frm.dt_to.value.length>0)
	  period = "AND b.dt_start <= TIMESTAMP '" + frm.dt_to.value + " 23:59:59' ";
	else
	  period = "AND (b.dt_start BETWEEN TIMESTAMP '" + frm.dt_from.value + " 00:00:00' AND TIMESTAMP '" + frm.dt_to.value + " 23:59:59') ";
<% } else { %>
	if (frm.dt_from.value.length==0 && frm.dt_to.value.length==0)
	  period = "";
	else if (frm.dt_from.value.length>0 && frm.dt_to.value.length==0)
	  period = "AND b.dt_start >= { ts '" + frm.dt_from.value + " 00:00:00'} ";
	else if (frm.dt_from.value.length==0 && frm.dt_to.value.length>0)
	  period = "AND b.dt_start <= { ts '" + frm.dt_to.value + " 23:59:59'} ";
	else
	  period = "AND (b.dt_start BETWEEN { ts '" + frm.dt_from.value + " 00:00:00'} AND { ts '" + frm.dt_to.value + " 23:59:59'}) ";
<% } %>

	var project;

	if (frm.sel_project.options.selectedIndex>0)
	  project = " AND b.gu_project IN (SELECT gu_project FROM k_project_expand WHERE gu_rootprj='" + getCombo(frm.sel_project) + "') ";
	
	window.open("/servlet/HttpQueryServlet?queryspec=duties&where=" + escape(period) + escape(project)+"&orderby=b.nm_resource&showas"+(frm.showas[0].checked ? "XLS" : "CSV")+"&columnlist="+escape("b.nm_resource,b.nm_project,b.nm_duty,b.pr_cost,b.pct_complete,b.dt_start,b.dt_end,b.de_duty"));
      }

      // ----------------------------------------------------------------------

      function costsByProject() { 
	      var frm = document.forms[0];
        
        if (frm.sel_project.options.selectedIndex<=0) {
          alert ("You must select a project");
          return false;
        }
        
	      var project;

	      project = " AND e.gu_rootprj='" + getCombo(frm.sel_project) + "' ";
	
	      window.open("/servlet/HttpQueryServlet?queryspec=projects&where=" + escape(project)+"&orderby=e.od_level&showas"+(frm.showas[0].checked ? "XLS" : "CSV")+"&columnlist="+escape("b.nm_project,<%=sSchema%>k_sp_prj_cost(b.gu_project),b.dt_start,b.dt_end,b.de_project"));
      }

      // ----------------------------------------------------------------------

<%    if ((iAppMask & (1<<WebBuilder))!=0) { %>

      function newsletters() {
	      var frm = document.forms[0];

        if (!isDate(frm.dt_nlfrom.value,"d") && frm.dt_nlfrom.value.length>0) {
	  			alert ("Invalid Date");
	  			frm.dt_nlfrom.setFocus();
	  			return false;
				}

        if (!isDate(frm.dt_nlto.value,"d") && frm.dt_nlto.value.length>0) {
	  			alert ("Invalid Date");
	  			frm.dt_nlto.setFocus();
	  			return false;
				}
      	
      	if (window.opener.closed) {
      		window.open("../jobs/jobs_followup_stats.jsp?selected=5&subselected=4&dt_from="+frm.dt_nlfrom.value+"&dt_to="+frm.dt_nlto.value);
      	} else {
      	  window.opener.document.location = "../jobs/jobs_followup_stats.jsp?selected=5&subselected=4&dt_from="+frm.dt_nlfrom.value+"&dt_to="+frm.dt_nlto.value;
      	}
				self.close();
      }

<% } %>

    //-->
    </SCRIPT>
  </HEAD>
  <BODY >
  <FORM>
  <INPUT TYPE="hidden" NAME="gu_campaign" VALUE="">
  <TABLE WIDTH="100%" SUMMARY="Title"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Queries</FONT></TD></TR></TABLE>  
  <BR>
<% if ((iAppMask & (1<<Sales))!=0) { %>
    <FONT CLASS="textplain"><B>Contact Management</B></FONT>
    <BR>
    <A CLASS="linkplain" HREF="javascript:openQueryForm('contacts')">Individuals</A>
    <BR>
    <A CLASS="linkplain" HREF="javascript:openQueryForm('companies')">Companies</A>
    <BR>
    <A CLASS="linkplain" HREF="javascript:openQueryForm('oportunities')">Oportunities</A>
    <BR>
    <TABLE SUMMARY=Sales Forecast"">
      <TR>
        <TD ROWSPAN="3"><IMG SRC="../images/images/spacer.gif" WIDTH="8" HEIGHT="1"></TD>
        <TD COLSPAN="2"><A CLASS="linksmall" HREF="../crm/rp_salesforecast.jsp" TARGET="_blank">Sales Forecast</A></TD>
      </TR>
      <TR>
        <TD><A CLASS="linksmall" HREF="#" onclick="openExcelSheet('won')">Won</A></TD>
        <TD>
          <FONT CLASS="textsmall">&nbsp;from&nbsp;</FONT><INPUT TYPE="text" NAME="dt_won" CLASS="combomini" SIZE="12" MAXLENGTH="10">
          <FONT CLASS="textsmall">&nbsp;</FONT><A HREF="javascript:showCalendar('dt_won')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
        </TD>
      </TR>
      <TR>
        <TD><A CLASS="linksmall" HREF="#" onclick="openExcelSheet('lost')">Lost</A></TD>
        <TD>
          <FONT CLASS="textsmall">&nbsp;from&nbsp;</FONT><INPUT TYPE="text" NAME="dt_lost" CLASS="combomini" SIZE="12" MAXLENGTH="10">
          <FONT CLASS="textsmall">&nbsp;</FONT><A HREF="javascript:showCalendar('dt_lost')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
        </TD>
      </TR>
    </TABLE>
    <TABLE SUMMARY="Call-Center Performance">
      <TR>
        <TD ROWSPAN="3"><IMG SRC="../images/images/spacer.gif" WIDTH="8" HEIGHT="1"></TD>
        <TD><A CLASS="linksmall" HREF="#" onclick="callCenterPerformance()">Telemarketing effectiveness</A></TD>
      </TR>
      <TR>
        <TD><FONT CLASS="textsmall">from</A>&nbsp;<INPUT TYPE="text" NAME="dt_day1" CLASS="combomini" SIZE="12" MAXLENGTH="10">&nbsp;&nbsp;&nbsp;until&nbsp;<INPUT TYPE="text" NAME="dt_dayn" CLASS="combomini" SIZE="12" MAXLENGTH="10" VALUE="<%=sToday%>">&nbsp;<A HREF="javascript:showCalendar('dt_dayn')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A></TD>
      </TR>
<% if ((iAppMask & (1<<MarketingTools))!=0 && iCampaigns>0) { %>
      <TR>
        <TD><FONT CLASS="textsmall">campaign</A>&nbsp;<SELECT NAME="sel_campaign" CLASS="combomini" onchange="document.forms[0].gu_campaign.value=this.options[this.selectedIndex].value"><OPTION VALUE=""></OPTION><% for (int c=0; c<iCampaigns; c++) { out.write("<OPTION VALUE=\""+oCampaigns.getString(0,c)+"\">"+oCampaigns.getString(1,c)+"</OPTION>"); } %></SELECT></TD>
      </TR>
<% } %>
    </TABLE>
<% }
   if ((iAppMask & (1<<WebBuilder))!=0) { %>
    <HR>
    <FONT CLASS="textplain"><B>Marketing</B></FONT>
    <BR>
    <A CLASS="linkplain" HREF="#" onclick="newsletters()">Newsletters</A>
    <TABLE SUMMARY="Newsletters">
      <TR>
        <TD><FONT CLASS="textsmall">from</A>&nbsp;<INPUT TYPE="text" NAME="dt_nlfrom" CLASS="combomini" SIZE="12" MAXLENGTH="10">&nbsp;&nbsp;&nbsp;until&nbsp;<INPUT TYPE="text" NAME="dt_nlto" CLASS="combomini" SIZE="12" MAXLENGTH="10" VALUE="<%=sToday%>">&nbsp;<A HREF="javascript:showCalendar('dt_dayn')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A></TD>
      </TR>
    </TABLE>
<% } %>
    <HR>
<% if ((iAppMask & (1<<ProjectManager))!=0) { %>
    <FONT CLASS="textplain"><B>Project Management</B></FONT>
    <BR>
    <A CLASS="linkplain" HREF="javascript:openQueryForm('duties')">Duties</A>
    <BR>
    <TABLE SUMMARY="Duties by person">
      <TR>
        <TD ROWSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="8" HEIGHT="1"></TD>
        <TD><A CLASS="linksmall" HREF="#" onclick="dutiesByPerson()">Duties by person</A></TD>
      </TR>
      <TR>
        <TD><FONT CLASS="textsmall">from</A>&nbsp;<INPUT TYPE="text" NAME="dt_start" CLASS="combomini" SIZE="12" MAXLENGTH="10">&nbsp;&nbsp;&nbsp;until&nbsp;<INPUT TYPE="text" NAME="dt_end" CLASS="combomini" SIZE="12" MAXLENGTH="10">&nbsp;<A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A></TD>
      </TR>
    </TABLE>
    <A CLASS="linkplain" HREF="javascript:openQueryForm('bugs')">Incidents</A>
    <BR>
    <A CLASS="linkplain" HREF="javascript:openQueryForm('duties')">Costs</A>
    <BR>
    <TABLE>
      <TR>
        <TD ROWSPAN="4"><IMG SRC="../images/images/spacer.gif" WIDTH="8" HEIGHT="1"></TD>
        <TD><A CLASS="linksmall" HREF="#" onclick="costsByPerson()">Costs by person</A>&nbsp;&nbsp;&nbsp;&nbsp;<A CLASS="linksmall" HREF="#" onclick="costsByProject()">Costs by project</A></TD>
      </TR>
      <TR>
        <TD><FONT CLASS="textsmall">from</A>&nbsp;<INPUT TYPE="text" NAME="dt_from" CLASS="combomini" SIZE="12" MAXLENGTH="10">&nbsp;&nbsp;&nbsp;until&nbsp;<INPUT TYPE="text" NAME="dt_to" CLASS="combomini" SIZE="12" MAXLENGTH="10">&nbsp;<A HREF="javascript:showCalendar('dt_to')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A></TD>
      </TR>
      <TR>
        <TD><FONT CLASS="textsmall">Project&nbsp;<SELECT CLASS="combomini" NAME="sel_project"><OPTION VALUE=""></OPTION><% for (int p=0; p<iRootPrjs; p++) out.write("<OPTION VALUE=\""+oRootPrjs.getString(0,p)+"\">"+oRootPrjs.getString(1,p)+"</OPTION>"); %></SELECT></TD>
      </TR>
      <TR>
        <TD><FONT CLASS="textsmall">Show as&nbsp;<INPUT NAME="showas" TYPE="radio" VALUE="XLS" CHECKED>&nbsp;Excel&nbsp;&nbsp;&nbsp;&nbsp;<INPUT NAME="showas" TYPE="radio" VALUE="CSV">&nbsp;Delimited text</FONT></TD>
      </TR>
    </TABLE>
    <BR>
    <HR>
<% } %>

<% if ((iAppMask & (1<<CollaborativeTools))!=0) { %>
    <FONT CLASS="textplain"><B>Collaborative Tools</B></FONT>
    <BR>
    <A CLASS="linkplain" HREF="javascript:openQueryForm('fellows')">Employees</A>
    <BR>
    <HR>
<% } %>

<% if ((iAppMask & (1<<Shop))!=0) { %>
    <FONT CLASS="textplain"><B>Shop</B></FONT>
    <BR>
    <A CLASS="linkplain" HREF="javascript:openQueryForm('items')">Products</A>
    <BR>
    <A CLASS="linkplain" HREF="javascript:openQueryForm('orders')">Orders</A>
    <BR>    
    <HR>
<% } %>
  </FORM>
  </BODY>
</HTML>
