<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%
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

  final int CollaborativeTools=17;
  final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  final boolean bCollabToolsEnabled = ((iAppMask & (1<<CollaborativeTools))!=0);
  
  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");  
  String sLanguage = getNavigatorLanguage(request);
  int iDomainId = Integer.parseInt(getCookie(request,"domainid","0"));
  
  Project oPrj = null;
  JDCConnection oCon1 = null;
  int iRowCount = 0;
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  DBSubset oBug = new DBSubset(DB.k_bugs + " b," + DB.k_projects + " p",
                               "b.tl_bug,p.gu_project,b.od_severity,b.od_priority,b.nm_reporter,b.tx_rep_mail,b.tx_bug_brief,b.dt_created,b.dt_closed," + DBBind.Functions.ISNULL + "(b.tx_status,''),b.nm_assigned,b.tx_comments,b.pg_bug,b.gu_writer,b.tp_bug,b.vs_found,b.vs_closed",
  			                       "p.gu_project=b.gu_project AND b.gu_bug=?", 1);
  DBSubset oTrk = new DBSubset(DB.k_bugs_track,
                               DB.gu_bug+","+DB.pg_bug_track+","+DB.dt_created+","+DB.nm_reporter+","+DB.tx_rep_mail+","+DB.gu_writer+","+DB.tx_bug_track,
                               DB.gu_bug+"=? ORDER BY 2 DESC", 20);
  DBSubset oAttachs = new DBSubset(DB.k_bugs_attach, DB.tx_file, DB.gu_bug + "=? AND " + DB.pg_bug_track + " IS NULL", 1);
  DBSubset oPrjRoots = null;
  DBSubset oPrjChlds = null;
  BugTrack[] aTrack = null;
  int iAttachs = 0;
  int iPrjChlds = 0;
  int iPrjRoot = 0;
  int iTrack = 0;
      
  String sSeverityLookUp = null;
  String sPriorityLookUp = null;
  String sAssignedLookUp = null;
  String sStatusLookUp = null;
  String sVsFoundLookUp = null;
  String sVsClosedLookUp = null;
   
  boolean bIsGuest = true;
  boolean bIsAdmin = false;
  boolean bIsUser = false;
  boolean bIsPower = false;
  
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
    
    if (bIsAdmin)
      oPrjRoots = new DBSubset(DB.k_projects,DB.gu_project + "," + DB.nm_project,DB.gu_owner + " IN (SELECT " + DB.gu_workarea + " FROM " + DB.k_workareas + " WHERE " + DB.id_domain + "=" + String.valueOf(iDomainId) + " AND " + DB.bo_active + "<>0) AND " + DB.id_parent + " IS NULL ORDER BY 2", 10);
    else
      oPrjRoots = new DBSubset(DB.k_projects,DB.gu_project + "," + DB.nm_project,DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_parent + " IS NULL ORDER BY 2", 10);

    oCon1 = GlobalDBBind.getConnection("bug_edit");
    
    iRowCount = oBug.load(oCon1, new Object[]{request.getParameter("gu_bug")});
    iAttachs = oAttachs.load(oCon1, new Object[]{request.getParameter("gu_bug")});
    iTrack = oTrk.load(oCon1, new Object[]{request.getParameter("gu_bug")});

    sSeverityLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.od_severity, sLanguage);
    sPriorityLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.od_priority, sLanguage);
    sAssignedLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.nm_assigned, sLanguage);
    sStatusLookUp   = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.tx_status  , sLanguage);
    sVsFoundLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.vs_found, sLanguage);
    sVsClosedLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.vs_closed, sLanguage);
  
    iPrjRoot = oPrjRoots.load(oCon1);

	  sendUsageStats(request, "bug_edit");
%>    
<HTML LANG="<%=sLanguage%>">
  <HEAD>
    <TITLE>hipergate :: Incident Maintenance</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>       
    <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');

      // ------------------------------------------------------

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

<% if (!bIsGuest) { %>

      // ------------------------------------------------------

      function addTrackRecord() {
      	var frm = document.forms[0];
      	if (frm.tx_bug_track.value.length==0) {
      	  alert ("Follow-up message may not be empty");
      	  frm.tx_bug_track.focus();
      	  return false;
      	}
      	if (frm.tx_bug_track.value.length>2000) {
      	  alert ("Follow-up message may not be longer the 2,000 characters");
      	  frm.tx_bug_track.focus();
      	  return false;
      	}
	      httpPostForm("bug_track_store.jsp",frm);	      
        document.location.reload();
      } // addTrackRecord()

<% } %>
      
      // ------------------------------------------------------

      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.gu_project, "<%=oBug.getString(1,0)%>");
        setCombo(frm.od_severity, "<%=String.valueOf(oBug.getInt(2,0))%>");
        setCombo(frm.od_priority, "<%=String.valueOf(oBug.getInt(3,0))%>");
        setCombo(frm.tx_status, "<% if (!oBug.isNull(9,0)) out.write(oBug.get(9,0).toString()); %>");
        setCombo(frm.sel_assigned, "<%=oBug.getStringNull(10,0,"").toString()%>");
        setCombo(frm.sel_found, "<%=oBug.getStringNull(15,0,"")%>");
        setCombo(frm.sel_closed, "<%=oBug.getStringNull(16,0,"")%>");
      }

      // ------------------------------------------------------

      function lookup(odctrl) {
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_bugs_lookup&id_language=" + getUserLanguage() + "&id_section=nm_assigned&tp_control=2&nm_control=sel_assigned&nm_coding=nm_assigned", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_bugs_lookup&id_language=" + getUserLanguage() + "&id_section=vs_found&tp_control=2&nm_control=sel_found&nm_coding=vs_found", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_bugs_lookup&id_language=" + getUserLanguage() + "&id_section=vs_closed&tp_control=2&nm_control=sel_closed&nm_coding=vs_closed", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;            
        }
      } // lookup()

      // ------------------------------------------------------
      
      function validate() {
	var frm = window.document.forms[0];
	var str;
	
	str = rtrim(frm.tl_bug.value);
	if (str.length==0) {
	  alert ("Subject is mandatory");
	  return false;
	}
	else
	  frm.tl_bug.value = str.toUpperCase();

	str = rtrim(frm.nm_reporter.value);
	if (str.length==0) {
	  alert ("Field Reported by is mandatory");
	  return false;
	}
	else
	  frm.nm_reporter.value = str.toUpperCase();
        
	str = rtrim(frm.tx_rep_mail.value);
	if (str.length==0) {
	  alert ("Contact e-mail is mandatory");
	  return false;
	}
	else
	  frm.tx_rep_mail.value = str.toLowerCase();

	str = frm.tx_bug_brief.value;
	if (str.length==0) {
	  alert ("Incident description is mandatory");
	  return false;
	}

	if (str.length>2000) {
	  alert ("Incident description may not be longer than 2000 characters");
	  return false;
	}

	str = frm.dt_closed.value;
	if (str.length>0 && getCombo(frm.tx_status)=="") {
	  alert ("Status cannot be PENDING if a close date is not set");
	  return false;
	}
	
	if (str.length==0 && getCombo(frm.tx_status)=="CORREGIDO") {
	  alert ("It is mandatory to set a close date for Closed Status");
	  return false;
	}
	
	if (!isDate(frm.dt_closed.value, "d") && frm.dt_closed.value.length>0) {
	  alert ("Close date is not valid");
	  return false;	  
	}
	
	frm.nm_assigned.value = getCombo(frm.sel_assigned);
	
	if (frm.tx_comments.value.length>1000) {
	  alert ("Comments may not be longer than 1000 characters");
	  return false;
	}
	
	frm.checkedfiles.value = "";
	for (var f=0; f<frm.elements.length; f++) {
	  if (frm.elements[f].type=="checkbox") {
	    if (frm.elements[f].checked) {
	      frm.checkedfiles.value += (frm.checkedfiles.value.length==0 ? "" : "`") + frm.elements[f].value;
	    }
	  }
	} // next

	frm.vs_found.value = getCombo(frm.sel_found);
	frm.vs_closed.value = getCombo(frm.sel_closed);

	return true;	
      }      
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  onLoad="setCombos()">
    <TABLE WIDTH="90%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Incident Maintenance</FONT></TD></TR></TABLE>  
    <IMG SRC="../images/images/crm/history16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="History">&nbsp;
    <A HREF="bug_changelog.jsp?gu_bug=<%=request.getParameter("gu_bug")%>&tl_bug=<%=Gadgets.URLEncode(oBug.getStringNull(0,0,""))%>" CLASS="linkplain">History</A>
<% if (bCollabToolsEnabled) { %>
    &nbsp;&nbsp;&nbsp;&nbsp;
    <IMG SRC="../images/images/addrbook/telephone16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Calls">&nbsp;
    <A HREF="../addrbook/phonecall_listing.jsp?field=pg_bug&find=<%=String.valueOf(oBug.getInt(12,0))%>" TARGET="_blank" CLASS="linkplain">Calls</A>
<% } %>
    &nbsp;&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/printer16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0">&nbsp;<A HREF="bug_report.jsp?pg_bug=<% out.write(String.valueOf(oBug.getInt(DB.pg_bug,0))); %>" CLASS="linkplain">Print</A>
    <FORM NAME="frmReportBug" ENCTYPE="multipart/form-data" METHOD="post" ACTION="bugedit_store.jsp" onSubmit="return validate()">
      <INPUT TYPE="hidden" NAME="is_new" VALUE="0">
      <INPUT TYPE="hidden" NAME="pg_bug" VALUE="<%=String.valueOf(oBug.getInt(DB.pg_bug,0))%>">      
      <INPUT TYPE="hidden" NAME="gu_bug" VALUE="<%=request.getParameter("gu_bug")%>">
      <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<% out.write(oBug.getStringNull(13,0,"")); %>">
      <INPUT TYPE="hidden" NAME="tp_bug" VALUE="<% out.write(oBug.getStringNull(14,0,""));%>" >
      <INPUT TYPE="hidden" NAME="checkedfiles"> 
      
      <TABLE SUMMARY="Tabla Principal" CLASS="formback">
        <TR>
          <!-- Columna Izquierda -->
          <TD CLASS="formfront">
            <!-- Datos de Alta -->
            <TABLE SUMMARY="Datos de Alta" CLASS="formfront">
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Subject</FONT></TD>
                <TD><INPUT TYPE="text" MAXLENGTH="250" SIZE="36" NAME="tl_bug" STYLE="text-transform:uppercase" VALUE="<%=oBug.getString(0,0)%>"></TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Applies to&nbsp;</FONT></TD>
                <TD><SELECT NAME="gu_project">
                    <%                    
		      for (int r=0; r<iPrjRoot; r++) {
    		        
    		        oPrj = new Project(oPrjRoots.getString(0,r));
                      
    		        oPrjChlds = oPrj.getAllChilds(oCon1);
    		        iPrjChlds = oPrjChlds.getRowCount();

                        out.write("                      ");
                        out.write("<OPTION VALUE=\"" + oPrjRoots.getString(0,r) + "\">" + oPrjRoots.getString(1,r) + "</OPTION>");
                        for (int p=0;p<iPrjChlds; p++) {
                          if (oPrjChlds.getInt(2,p)>1) {
                            // Project GUIDs as values
                            out.write("<OPTION VALUE=\"" + oPrjChlds.getString(0,p) + "\">");
                            // Indent project names
                            for (int s=1;s<oPrjChlds.getInt(2,p); s++) out.write("&nbsp;&nbsp;&nbsp;&nbsp;");
                            // Project names
                            out.write(oPrjChlds.getString(1,p));

                            out.write("</OPTION>");
                          } // fi (od_level>1)
                        } // next (p)

                      } // next (r)
                    out.write("\n");
                    %>
                    </SELECT>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="TOP"><FONT CLASS="formstrong">Versions</FONT></TD>
                <TD VALIGN="top">
                  <INPUT TYPE="hidden" NAME="vs_found">
		  <INPUT TYPE="hidden" NAME="vs_closed">
		  <TABLE BORDER="0">
		    <TR>
		      <TD><FONT CLASS="formplain">Detected</FONT></TD>
		      <TD><FONT CLASS="formplain">Solved</FONT></TD>
		    </TR>
		    <TR>
		      <TD>
                        <SELECT NAME="sel_found"><OPTION VALUE=""></OPTION><%=sVsFoundLookUp%></SELECT>
<%  if (bIsAdmin) { %>     
                        &nbsp;<A HREF="#" onclick="lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A>
<%  } %>
		      </TD>
		      <TD>
                        <SELECT NAME="sel_closed"><OPTION VALUE=""></OPTION><%=sVsClosedLookUp%></SELECT>
<%  if (bIsAdmin) { %>     
                        &nbsp;<A HREF="#" onclick="lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A>
<%  } %>
		      </TD>
		    </TR>
		  </TABLE>
    	        </TD>
    	      </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Severity</FONT></TD>
                <TD><SELECT NAME="od_severity"><%=sSeverityLookUp%></SELECT>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Priority</FONT></TD>
                <TD><SELECT NAME="od_priority"><%=sPriorityLookUp%></SELECT>
                    <INPUT TYPE="hidden" VALUE="R">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Reported by:</FONT></TD>
                <TD><INPUT TYPE="text" MAXLENGTH="50" SIZE="34" NAME="nm_reporter" VALUE="<%=oBug.getString(4,0)%>"></TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">e-mail:</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="100" SIZE="32" NAME="tx_rep_mail" VALUE="<%=oBug.getString(5,0)%>">
                  <A HREF="mailto:<%=oBug.getString(5,0)%>" TITLE="Send e-mail"><IMG SRC="../images/images/mailto16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Send e-mail"></A>

                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Description:</FONT></TD>
                <TD><TEXTAREA NAME="tx_bug_brief" ROWS="6" COLS="40" CLASS="textsmall"><%=oBug.getString(6,0)%></TEXTAREA></TD>
              </TR>
            </TABLE> <!-- Fin Datos de Alta -->            
          </TD> <!-- Fin Columna Izquierda -->
          <!-- Columna Derecha -->
          <TD VALIGN="top" CLASS="formfront">
	    <TABLE SUMMARY="Datos de Mantenimiento">
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Identifier</FONT><BR></TD>
                <TD><FONT CLASS="formplain"><%=String.valueOf(oBug.getInt(12,0))%></FONT><BR></TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formstrong">Dates</FONT></TD>
                <TD VALIGN="top">
                  <TABLE BORDER="0">
                    <TR>
                      <TD><FONT CLASS="formplain">Open</FONT></TD>
                      <TD><FONT CLASS="formplain">Closed</FONT></TD>
                    </TR>
                    <TR>
                      <TD><INPUT TYPE="text" MAXLENGTH="10" SIZE="10" NAME="dt_created" VALUE="<% if (oBug.get(7,0)!=null) out.write(oSimpleDate.format((Date)oBug.get(7,0))); %>" TABINDEX="-1" onfocus="document.forms[0].dt_closed.focus()"></TD>
                      <TD><INPUT TYPE="text" MAXLENGTH="10" SIZE="10" NAME="dt_closed" VALUE="<% if (oBug.get(8,0)!=null) out.write(oSimpleDate.format((Date)oBug.get(8,0))); %>">&nbsp;&nbsp;<A HREF="javascript:showCalendar('dt_closed')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A></TD>
                    </TR>
                  </TABLE>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Status</FONT></TD>
                <TD>
                  <SELECT NAME="tx_status"><%=sStatusLookUp%></SELECT>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Assigned to&nbsp;</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" MAXLENGTH="255" SIZE="33" NAME="nm_assigned" VALUE="<% if (oBug.get(10,0)!=null) out.write(oBug.getString(10,0)); %>">
                  <SELECT NAME="sel_assigned" STYLE="width:210"><OPTION VALUE=""></OPTION><%=sAssignedLookUp%></SELECT>
                  &nbsp;&nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Comments</FONT></TD>
                <TD><TEXTAREA NAME="tx_comments" ROWS="6" COLS="38" CLASS="textsmall"><% if (oBug.get(11,0)!=null) out.write(oBug.getString(11,0)); %></TEXTAREA></TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">File 1</FONT></TD>
                <TD><INPUT TYPE="file" SIZE="16" NAME="bugfile1_<%=sUserId%>"></TD>
              </TR>
	      <%
	        for (int a=0; a<iAttachs; a++) {
	          out.write ("              <TR>\n");
	          out.write ("                <TD VALIGN=\"middle\" ALIGN=\"right\"><FONT CLASS=\"formplain\">Delete</FONT>&nbsp;<INPUT TYPE=\"checkbox\" VALUE=\"" + oAttachs.getString(0,a) + "\"></TD>\n");
	          out.write ("                <TD VALIGN=\"middle\">\n");
	          out.write ("                  <A HREF=\"../servlet/HttpBLOBServlet?nm_table=" + DB.k_bugs_attach + "&nm_field=" +  DB.tx_file + "&bin_field=" + DB.bin_file + "&pk_field=" + DB.gu_bug + "," + DB.tx_file + "&pk_value=" + request.getParameter("gu_bug") + "," + Gadgets.URLEncode(oAttachs.getString(0,a)) + "\" TARGET=\"_blank\" CLASS=\"linknodecor\" TITLE=\"Ver Archivo\"><IMG SRC=\"../images/images/viewtxt.gif\" BORDER=\"0\">&nbsp;<I>" + oAttachs.getString(0,a) + "</I></A>");
	          out.write ("                </TD>\n");
	          out.write ("              </TR>\n");
	        }
	      %>
              <TR>
                <TD ALIGN="right"></TD>
                <TD>
                  <BR>
<% if (bIsGuest) { %>
                  <INPUT TYPE="submit" CLASS="pushbutton" STYLE="WIDTH:80" VALUE="Save" onclick="alert ('Your credential level as Guest does not allow you to perform this action')">
<% } else { %>
                  <INPUT TYPE="submit" CLASS="pushbutton" STYLE="WIDTH:80" VALUE="Save">
<% } %>
                  &nbsp;&nbsp;&nbsp;
                  <INPUT TYPE="button" CLASS="closebutton" STYLE="WIDTH:80" VALUE="Close" onClick="javascript:window.close()">
                </TD>
              </TR>              
            </TABLE>
          </TD> <!-- Fin Columna Derecha -->
        </TR>
        <TR>
        	<!-- Track record -->
          <TD COLSPAN="2" CLASS="formplain" ALIGN="right">
<% if (!bIsGuest) { %>
          	<A HREF="#" onclick="document.getElementById('trackmsg').style.display='block'">New follow-up message</A>
<% } %>
          </TD>
        </TR>
        <TR>
          <TD CLASS="formfront" COLSPAN="2">
          	<DIV id="trackmsg" STYLE="display:none"><TEXTAREA NAME="tx_bug_track" ROWS="4" COLS="80"></TEXTAREA><BR/>
          	<IMG SRC="../images/images/spacer.gif" WIDTH="564" HEIGHT="1" ALT="" BORDER="0"><INPUT TYPE="button" CLASS="pushbutton" onclick="addTrackRecord()" VALUE="Add"></DIV>
<% if (iTrack>0) { %>        	
<%   for (int t=0; t<iTrack; t++) {
       out.write("<FONT CLASS=\"formstrong\">"+oTrk.getDateTime24(2, t)+"&nbsp;"+oTrk.getStringNull(DB.nm_reporter,t,"")+"</FONT><BR/>\n");
       out.write("<FONT CLASS=\"formplain\">"+oTrk.getStringNull(DB.tx_bug_track,t,"")+"</FONT><HR/>\n");
     } %>
          </TD>
        </TR>
<% } %>
      </TABLE> 
    </FORM>
  </BODY>
</HTML>
<%
    oCon1.close("bug_edit");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("bug_edit");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
      
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  
  if (null==oCon1) return;
  oCon1=null;
%>
<%@ include file="../methods/page_epilog.jspf" %>