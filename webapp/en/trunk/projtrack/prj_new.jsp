<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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

  final int Sales=16;

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  String sStatus = nullif(request.getParameter("id_status"));
  String sFilter;
  
  if (sStatus.length()==0)
    sFilter = "";
  else if (sStatus.equals("ABIERTO"))
    sFilter = "(" + DB.id_status + "='ABIERTO' OR " + DB.id_status + " IS NULL) AND ";
  else
    sFilter = DB.id_status + "='" + sStatus + "' AND ";
  
  String gu_company = nullif(request.getParameter("gu_company"));
  String gu_contact = nullif(request.getParameter("gu_contact"));
  String gu_user = nullif(request.getParameter("gu_user"));
  String nm_legal = nullif(request.getParameter("nm_legal"));
  String tx_contact = nullif(request.getParameter("tx_contact"));
  String tx_user = nullif(request.getParameter("tx_user"));
  
  Project oPrj = new Project();
  JDCConnection oCon1 = null;
  int iRowCount = 0;
  String sWorkArea = getCookie(request,"workarea","");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  DBSubset oTopLevel = new DBSubset(DB.k_projects,
  				    DB.gu_project + "," + DB.nm_project,
  				    sFilter + DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_parent + " IS NULL ORDER BY " + DB.nm_project, 10);
  DBSubset oPrjChlds = null;
  int iPrjChlds = 0;
  String sDeptsLookUp;
  String sStatusLookUp = null;
    
  try {
    oCon1 = GlobalDBBind.getConnection("prj_new");

    sDeptsLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_projects_lookup, sWorkArea, DB.id_dept, sLanguage);
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_projects_lookup, sWorkArea, DB.id_status, sLanguage);
            
    oTopLevel.load(oCon1);

	  sendUsageStats(request, "prj_new");    
%>
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: New Project</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--

      // ------------------------------------------------------

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

      function lookup(odctrl) {
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_projects_lookup&id_language=<%=sLanguage%>&id_section=id_dept&tp_control=2&nm_control=sel_dept&nm_coding=id_dept", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_projects_lookup&id_language=<%=sLanguage%>&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()

      // ------------------------------------------------------

      function reference(odctrl) {
        var frm = document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 2:
            window.open("../common/reference.jsp?nm_table=k_companies&tp_control=1&nm_control=nm_legal&nm_coding=gu_company", "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            if (frm.gu_company.value=="")
              alert ("To assign a Contact select a Company First");
            else
              window.open("../common/reference.jsp?nm_table=k_contacts&tp_control=1&nm_control=" + "tx_name%2B%27%20%27%2Btx_surname%20AS%20tx_contact" + "&nm_coding=gu_contact&where=" + escape("gu_company='" + frm.gu_company.value + "'"), "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
              window.open("../common/reference.jsp?nm_table=k_users&tp_control=1&nm_control=" + "nm_user%2B%27%20%27%2Btx_surname1%20AS%20tx_user" + "&nm_coding=gu_user", "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
        }
      } // reference()

      // ------------------------------------------------------

      function filter(st) {
        window.document.location.href = "prj_new.jsp?id_status=" + st;
      }
                              
      // ------------------------------------------------------
      
      function validate() {
	var frm = window.document.forms[0];
        var prj = frm.sel_project.options;
	var str;
	var npj;
	var aStart;
	var aEnd;
	var dtStart;
	var dtEnd;
	
	if (rtrim(frm.nm_project.value)=="") {
	  alert ("Project name is mandatory");
	  return false;
	}

	if (frm.nm_project.value.indexOf("'")>=0 || frm.nm_project.value.indexOf('"')>=0 || frm.nm_project.value.indexOf(";")>=0 || frm.nm_project.value.indexOf(",")>=0 || frm.nm_project.value.indexOf("|")>=0) {
	  alert ("The project name contains invalid characters");
	  return false;	
	}

	npj = 0;
        for (var n=0; n<prj.length; n++)
          if (prj[n].selected) npj++;
	
	if (npj>1) {
	  alert ("Must select a unique parent Project");
	  return false;
	}
	else if (npj==1)
	  frm.id_parent.value = getCombo(frm.sel_project);
	  
	frm.id_dept.value = getCombo(frm.sel_dept);
	
	str = frm.dt_start.value;
	
	if (str.length>0 && !isDate(str, "d")) {
	  alert ("Start date is not valid");
	  return false;
	}
	
	str = frm.dt_end.value;

	if (str.length>0 && !isDate(str, "d")) {
	  alert ("End date is not valid");
	  return false;
	}

	if (frm.dt_start.value.length>0 && frm.dt_end.value.length>0) {
	  aStart = frm.dt_start.value.split("-");
	  aEnd = frm.dt_end.value.split("-");	  
	  dtStart = new Date(parseInt(aStart[0]), parseInt(parseFloat(aStart[1]))-1, parseInt(parseFloat(aStart[2])));
	  dtEnd = new Date(parseInt(aEnd[0]), parseInt(parseFloat(aEnd[1]))-1, parseInt(parseFloat(aEnd[2])));
	  if (dtStart>dtEnd) {
	    alert ("Start date must be previous to end date");
	    return false;
	  }
	}
	
	if (frm.de_project.value.length>1000) {
	  alert ("Description must not be longer than 1000 characters");
	  return false;
	}

<% if ((iAppMask & (1<<Sales))!=0) { %>

	frm.id_dept.value = getCombo(frm.sel_dept);

	if (ltrim(frm.nm_legal.value)=="")
	  frm.gu_company.value = "";
	
	if (ltrim(frm.tx_contact.value)=="")
	  frm.gu_contact.value = "";

	if (ltrim(frm.tx_user.value)=="")
	  frm.gu_user.value = "";

<% } %>
	frm.id_status.value=getCombo(frm.sel_status);
	  	
	return true;	
      }      
      //-->
    </SCRIPT>
  </HEAD>
  <BODY >
    <TABLE WIDTH="98%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">New Project</FONT></TD></TR></TABLE>       
    <BR>
    <FORM NAME="frmNewProject" METHOD="post" ACTION="prjedit_store.jsp" onSubmit="return validate()">
      <INPUT TYPE="hidden" NAME="is_new" VALUE="1">
      <INPUT TYPE="hidden" NAME="is_standalone" VALUE="<%=(request.getParameter("standalone")!=null ? "1" : "0")%>">      
      <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=gu_company%>">
      <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
      <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=gu_user%>">
      
      <TABLE SUMMARY="Main table" CLASS="formback">
        <TR>
          <TD CLASS="formfront">
            <TABLE SUMMARY="Parent Project" CLASS="formfront">
              <TR>
                <TD>
                  <TABLE>
                    <TR>
                      <TD COLSPAN="2"><FONT CLASS="formstrong">View</FONT></TD>                      
                      <TD><INPUT TYPE="radio" NAME="status" onclick="filter('')" <%=(sStatus.length()==0 ? "CHECKED" : "")%>></TD>
                      <TD><FONT CLASS="formplain">All</FONT></TD>
                    </TR>
                    <TR>
                      <TD><INPUT TYPE="radio" NAME="status" onclick="filter('ABIERTO')" <%=(sStatus.equals("ABIERTO") ? "CHECKED" : "")%>></TD>
                      <TD><FONT CLASS="formplain">Open</FONT></TD>
                      <TD><INPUT TYPE="radio" NAME="status" onclick="filter('CERRADO')" <%=(sStatus.equals("CERRADO") ? "CHECKED" : "")%>></TD>
                      <TD><FONT CLASS="formplain">Closed</FONT></TD>
                    </TR>
                    <TR>
                      <TD><INPUT TYPE="radio" NAME="status" onclick="filter('SUSPENDIDO')" <%=(sStatus.equals("SUSPENDIDO") ? "CHECKED" : "")%>></TD>
                      <TD><FONT CLASS="formplain">Suspended</FONT></TD>
                      <TD><INPUT TYPE="radio" NAME="status" onclick="filter('CANCELADO')" <%=(sStatus.equals("CANCELADO") ? "CHECKED" : "")%>></TD>
                      <TD><FONT CLASS="formplain">Cancelled</FONT></TD>
                    </TR>
                  </TABLE>
                </TD>
              </TR>
              <TR>
                <TD>
                  <FONT CLASS="formstrong">Parent Project</FONT><BR>
                  <INPUT TYPE="hidden" NAME="id_parent">
                  <SELECT NAME="sel_project" SIZE="18" STYLE="width:256" MULTIPLE>
                    <%
                      for (int t=0; t<oTopLevel.getRowCount(); t++) {
                      
    		        oPrj.replace(DB.gu_project, oTopLevel.getString(0,t));
    		        
    		        oPrjChlds = oPrj.getAllChilds(oCon1);    			
    			iPrjChlds = oPrjChlds.getRowCount();
    			
                        out.write("                      ");
                        out.write("<OPTION VALUE=\"" + oTopLevel.getString(0,t) + "\">" + oTopLevel.getString(1,t) + "</OPTION>");
                        for (int p=0;p<iPrjChlds; p++) {
                          if (oPrjChlds.getInt(2,p)>1) {
                            // Project GUIDs as values
                            out.write("<OPTION VALUE=\"" + oPrjChlds.getString(0,p) + "\">");
                            // Indent project name
                            for (int s=1;s<oPrjChlds.getInt(2,p); s++) out.write("&nbsp;&nbsp;&nbsp;&nbsp;");
                            // Project name
                            out.write(oPrjChlds.getString(1,p));

                            out.write("</OPTION>");
                          } // fi (od_level>1)
                        } // next (p)
                    } // next (t)
                    out.write("\n");
                    %>
                  </SELECT>
                </TD>
              </TR>
            </TABLE>
          </TD>          
          <TD VALIGN="top" CLASS="formfront">
	    <TABLE SUMMARY="Maintenance Data">
              <TR>
                <TD ALIGN="right"></TD>
                <TD>
                  <IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Name</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="50" SIZE="30" NAME="nm_project" VALUE="<% out.write(nullif(request.getParameter("nm_project"))); %>">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Start</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="10" NAME="dt_start" VALUE="<% out.write(oSimpleDate.format(new Date())); %>">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
                  <IMG SRC="../images/images/spacer.gif" WIDTH="8" HEIGHT="1" BORDER="0">
                  <FONT CLASS="formplain">End</FONT>
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="10" NAME="dt_end">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Reference</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="50" SIZE="20" NAME="id_ref">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Status</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" MAXLENGTH="16" NAME="id_status">
                  <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>
                  &nbsp;&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Status List"></A>
                </TD>
              </TR>              
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Department</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" NAME="id_dept" VALUE="">
                  <SELECT NAME="sel_dept"><OPTION VALUE=""></OPTION><%=sDeptsLookUp%></SELECT>
                  <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A>
                </TD>
              </TR>
<% if ((iAppMask & (1<<Sales))!=0) { %>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Company</FONT></TD>
                <TD>
                  <INPUT TYPE="text" SIZE="34" NAME="nm_legal" TABINDEX="-1" onkeypress="return false;" VALUE="<%=nm_legal%>">
                  &nbsp;&nbsp;<A HREF="javascript:reference(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Companies List"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Contact</FONT></TD>
                <TD>
                  <INPUT TYPE="text" SIZE="34" NAME="tx_contact" VALUE="<%=tx_contact%>" onkeypress="return false;">
                  &nbsp;&nbsp;<A HREF="javascript:reference(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Contacts List"></A>
                </TD>
              </TR>
<% } %>              
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Owner</FONT></TD>
                <TD>
                  <INPUT TYPE="text" SIZE="34" NAME="tx_user" VALUE="<%=tx_user%>" onkeypress="return false;">
                  &nbsp;&nbsp;<A HREF="javascript:reference(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View list of users"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">Description</FONT></TD>
                <TD>
                  <TEXTAREA NAME="de_project" ROWS="6" COLS="34"><% out.write(nullif(request.getParameter("de_project"))); %></TEXTAREA>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"></TD>
                <TD>
                  <BR><INPUT TYPE="submit" CLASS="pushbutton" STYLE="WIDTH:80" VALUE="Save">
                  &nbsp;&nbsp;&nbsp;
                  <INPUT TYPE="button" CLASS="closebutton" STYLE="WIDTH:80" VALUE="Close" onClick="javascript:window.close()">
                </TD>
              </TR>              
            </TABLE>
          </TD>
        </TR>
      </TABLE> 
    </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>
<%
    oCon1.close("prj_new");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("prj_new");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
          
    response.sendRedirect (response.encodeRedirectUrl ("../srvrpags/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
%>