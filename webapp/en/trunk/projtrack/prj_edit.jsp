<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
 
  String gu_project = request.getParameter("gu_project");
  
  String sLanguage = getNavigatorLanguage(request);
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  String sWorkArea = getCookie(request,"workarea","");
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
    
  JDCConnection oCon1 = null;
  Object aProj[] = { gu_project }; 
  Project oPrj = new Project();
  Project oChl = null;  
  String sDeptsLookUp = null;
  String sStatusLookUp = null;
  String sUserFullName = "";
  DBSubset oBugs = new DBSubset (DB.k_bugs, DB.gu_bug+","+DB.pg_bug+","+DB.tl_bug+","+DB.dt_created+","+DB.tx_status,
  															 DB.gu_project+"=? ORDER BY 4 DESC", 20);
  DBSubset oDuts = new DBSubset (DB.k_duties, DB.gu_duty+","+DB.nm_duty+","+DB.dt_created+","+DB.tx_status,
                                 DB.gu_project+"=? ORDER BY 4 DESC", 20);
  int nBugs = 0;
  int nDuts = 0;
  
  int iPrjRoot = 0;
  DBSubset oPrjRoots = new DBSubset (DB.k_projects, DB.gu_project + "," + DB.nm_project + "," + DB.id_parent,
  				     DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_parent + " IS NULL ORDER BY 2", 10);
  int iPrjChlds = 0;
  DBSubset oPrjChlds = null;
  float fCost = 0;
  
  final Boolean oTrue = new Boolean(true);
  
  HashMap oBugStatus = null;
  HashMap oDutyStatus = null;
  
  HashMap oPrjChilds = new HashMap(31);
  oPrjChilds.put(gu_project, oTrue);
  
  boolean bIsGuest = true;
  
  try {
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oCon1 = GlobalDBBind.getConnection("prj_edit");

		nBugs = oBugs.load(oCon1, aProj);

		nDuts = oDuts.load(oCon1, aProj);

    oBugStatus = DBLanguages.getLookUpMap(oCon1, DB.k_bugs_lookup, sWorkArea, DB.tx_status, sLanguage);

    oDutyStatus = DBLanguages.getLookUpMap(oCon1, DB.k_duties_lookup, sWorkArea, DB.tx_status, sLanguage);

    if ((iAppMask & (1<<Sales))!=0)        
      sDeptsLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_projects_lookup, sWorkArea, DB.id_dept, sLanguage);
      
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_projects_lookup, sWorkArea, DB.id_status, sLanguage);
    
    oPrj.load(oCon1, aProj);

    if (!oPrj.isNull(DB.gu_user)) {
      PreparedStatement oStm = oCon1.prepareStatement("SELECT "+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"=?");
      oStm.setString(1, oPrj.getString(DB.gu_user));
      ResultSet oRst = oStm.executeQuery();
      if (oRst.next())
        sUserFullName = (nullif(oRst.getString(1))+" "+nullif(oRst.getString(2))+" "+nullif(oRst.getString(3))).trim();
      oRst.close();
      oStm.close();
    } // fi
    
    fCost = oPrj.cost(oCon1);
    
    if (oPrj.isNull(DB.pr_cost)) oPrj.put(DB.pr_cost, 0f);
    
    if (fCost!=oPrj.getFloat(DB.pr_cost)) {
      oCon1.setAutoCommit(true);
      oPrj.replace(DB.pr_cost, fCost);
      oPrj.store(oCon1);
    }
    
    iPrjRoot = oPrjRoots.load(oCon1);

  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("prj_edit");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
          
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  
  if (null==oCon1) return;

	sendUsageStats(request, "prj_edit");

%><HTML>
  <HEAD>
    <TITLE>hipergate :: Edit Project<%=oPrj.getString(DB.nm_project)%></TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript">
      <!--

      // ------------------------------------------------------

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_status, "<%=oPrj.getStringNull(DB.id_status,"")%>");

        setCombo(frm.sel_parent, "<%=oPrj.getStringNull(DB.id_parent,"")%>");

<% if ((iAppMask & (1<<Sales))!=0) { %>
        setCombo(frm.sel_dept, "<%=oPrj.getStringNull(DB.id_dept,"")%>");
<% } %>
      }

      // ------------------------------------------------------

      function lookup(odctrl) {
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_projects_lookup&id_language=" + getUserLanguage() + "&id_section=id_dept&tp_control=2&nm_control=sel_dept&nm_coding=id_dept", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_projects_lookup&id_language=" + getUserLanguage() + "&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()

      // ------------------------------------------------------

      function reference(odctrl) {
        var frm = document.forms[0];
        var c1,c2,c12;
        
        switch(parseInt(odctrl)) {
          case 2:
            frm.tx_contact.value="";
            frm.gu_contact.value="";
            if (frm.nm_legal.value.indexOf("'")>=0)
              alert("The company name contains forbidden characters");
            else
              window.open("../common/reference.jsp?nm_table=k_companies&tp_control=1&nm_control=nm_legal&nm_coding=gu_company"+(frm.nm_legal.value.length==0 ? "" : "&where=" + escape(" (<%=DB.nm_legal%> <%=DBBind.Functions.ILIKE%> '"+frm.nm_legal.value+"%' OR <%=DB.nm_commercial%> <%=DBBind.Functions.ILIKE%> '"+frm.nm_legal.value+"%') ")), "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            if (frm.gu_company.value=="")
              alert ("Para asignar un contacto primero debe seleccionar una compañía");
            else {
              c1 = frm.gu_company.value.length==0 ? "" : " <%=DB.gu_company%>='"+frm.gu_company.value+"' ";
	            c2 = frm.tx_contact.value.length==0 ? "" : " (<%=DB.tx_name%> <%=DBBind.Functions.ILIKE%> '"+frm.tx_contact.value+"%' OR <%=DB.tx_surname%> <%=DBBind.Functions.ILIKE%> '"+frm.tx_contact.value+"') ";
	            c12 = (c1.length==0 || c2.length==0 ? c1+c2 : c1+" AND "+c2);
              if (frm.tx_contact.value.indexOf("'")>=0)
                alert("Contact name contains forbidden characters");
              else
                window.open("../common/reference.jsp?nm_table=k_contacts&tp_control=1&nm_control=" + "tx_name%2B%27%20%27%2Btx_surname%20AS%20tx_contact" + "&nm_coding=gu_contact&where=" + escape(c12), "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            }
            break;
          case 4:
            frm.tx_user.value="";
            frm.gu_user.value="";
            c1 = frm.gu_user.value.length==0 ? "" : " <%=DB.gu_user%>='"+frm.gu_user.value+"' ";
	          c2 = frm.tx_user.value.length==0 ? "" : " (<%=DB.nm_user%> <%=DBBind.Functions.ILIKE%> '"+frm.tx_user.value+"%' OR <%=DB.tx_surname1%> <%=DBBind.Functions.ILIKE%> '"+frm.tx_user.value+"') ";
	          c12 = (c1.length==0 || c2.length==0 ? c1+c2 : c1+" AND "+c2);
            if (frm.tx_user.value.indexOf("'")>=0) {
              alert("The owner's name contains invalid characters");
            } else {
              window.open("../common/reference.jsp?nm_table=k_users&tp_control=1&nm_control=" + "nm_user%2B%27%20%27%2Btx_surname1%20AS%20tx_user" + "&nm_coding=gu_user&where=" + escape(c12), "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            }
            break;
        }
      } // reference()
            
      // ------------------------------------------------------
      
      function validate() {
      	var frm = window.document.forms[0];
      	var str;
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
      			  	
      	str = frm.dt_start.value;
      	
      	if (str.length>0 && !isDate(str, "d")) {
      	  alert ("Start date is not valid");
      	  return false;
      	}
      	
      	str = frm.dt_end.value;
      
      	if (str.length>0 && !isDate(str, "d")) {
      	  alert ("End date is not vald");
      	  return false;
      	}
      
      	if (frm.dt_start.value.length>0 && frm.dt_end.value.length>0) {
      	  aStart = frm.dt_start.value.split("-");
      	  aEnd = frm.dt_end.value.split("-");	  
      	  dtStart = new Date(parseInt(aStart[0]), parseInt(parseFloat(aStart[1]))-1, parseInt(parseFloat(aStart[2])));
      	  dtEnd = new Date(parseInt(aEnd[0]), parseFloat(aEnd[1])-1, parseFloat(aEnd[2]));
      	  if (dtStart>dtEnd) {
      	    alert ("Start date must be previous to end date");
      	    return false;
      	  }
      	}
      	
      	if (frm.de_project.value.length>1000) {
      	  alert ("Description must not be longer than 1000 characters");
      	  return false;
      	}
      
      	if (frm.nm_legal.value.length>0 && frm.gu_company.value==0) {
      	  alert ("The selected company is not valid");
      	  reference(2);
      	  return false;
      	}
      
      	if (frm.tx_contact.value.length>0 && frm.gu_contact.value==0) {
      	  alert ("The selected contact is not valid");
      	  reference(3);
      	  return false;
      	}
      
      	if (frm.tx_user.value.length>0 && frm.gu_user.value==0) {
      	  alert ("The selected owner is not valid");
      	  reference(4);
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

	frm.id_parent.value=getCombo(frm.sel_parent);
	
	return true;	
      } // validate()

      // ------------------------------------------------------
      
      function editBug(guBug) {
        window.open("bug_edit.jsp?gu_bug=" + guBug, guBug, "width=780,height=480");
      }

      // ------------------------------------------------------
            
      function editDuty(guDuty) {
        window.open("duty_edit.jsp?gu_duty=" + guDuty, "editduty", "width=780,height=" + (screen.height<=600 ? "520" : "640"));
      }
      
      // ------------------------------------------------------

      function deleteProject() {
	if (confirm("Are you sure you want to delete project&nbsp;"  + document.forms[0].nm_project.value + "On doing so associated duties and incidents will also be deleted"))
	  window.parent.location.href = "prjedit_delete.jsp?gu_project=" + document.forms[0].gu_project.value + "&is_standalone=0";

      } // deleteProject()
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  onLoad="setCombos()">
    <TABLE WIDTH="90%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Project</FONT></TD></TR></TABLE>       
    <FORM NAME="frmReportBug" METHOD="post" ACTION="prjedit_store.jsp" onSubmit="return validate();">
      <INPUT TYPE="hidden" NAME="is_new" VALUE="0">
      <INPUT TYPE="hidden" NAME="is_standalone" VALUE="<%=(request.getParameter("standalone")!=null ? "1" : "0")%>">
      <INPUT TYPE="hidden" NAME="gu_project" VALUE="<%=request.getParameter("gu_project")%>">
      <INPUT TYPE="hidden" NAME="id_parent" VALUE="<%=(null!=request.getParameter("id_parent") ? request.getParameter("id_parent") : "")%>">
      <INPUT TYPE="hidden" NAME="id_previous_parent" VALUE="<%=oPrj.getStringNull(DB.id_parent,"")%>">
      <INPUT TYPE="hidden" NAME="gu_company" VALUE="<% if (oPrj.get(DB.gu_company)!=null) out.write(oPrj.getString(DB.gu_company)); %>">
      <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<% if (oPrj.get(DB.gu_contact)!=null) out.write(oPrj.getString(DB.gu_contact)); %>">
      <INPUT TYPE="hidden" NAME="gu_user" VALUE="<% if (oPrj.get(DB.gu_user)!=null) out.write(oPrj.getString(DB.gu_user)); %>">
      <CENTER>
      <TABLE SUMMARY="Edición de Proyecto" CLASS="formback">
        <TR>          
          <TD VALIGN="top" CLASS="formfront">
	          <TABLE SUMMARY="Project Data">
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Name</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="50" SIZE="30" NAME="nm_project" VALUE="<%=oPrj.getString(DB.nm_project)%>" TABINDEX="-1" onfocus="//document.forms[0].dt_closed.focus()">
                </TD>
                <TD ROWSPAN="11" CLASS="formback" WIDTH="1"></TD>
                <TD><FONT CLASS="formstrong">Summary</FONT></TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Parent</FONT></TD>
                <TD>
                  <SELECT NAME="sel_parent">
                  <OPTION VALUE=""></OPTION>
<%
                      oChl = new Project();
                      
		      for (int r=0; r<iPrjRoot; r++) {
    		        
    		        if (!gu_project.equals(oPrjRoots.getString(0,r))) {
    		        
    		          oChl.replace(DB.gu_project, oPrjRoots.getString(0,r));
    		        
    		          oPrjChlds = oChl.getAllChilds(oCon1);
    		          iPrjChlds = oPrjChlds.getRowCount();
    		        
                          out.write("<OPTION VALUE=\"" + oPrjRoots.getString(0,r) + "\">" + oPrjRoots.getString(1,r) + "</OPTION>");

                          for (int p=0;p<iPrjChlds; p++) {

                            if (oPrjChlds.getInt(2,p)>1) {

			      // No añadir a la lista de padres candidatos los proyectos hijos del actual para evitar que se generen referencias circulares.
			      if (oPrjChilds.containsKey(oPrjChlds.getString(4,p)))
			    
			        oPrjChilds.put(oPrjChlds.getString(0,p), oTrue);
			    
			      else if (!gu_project.equals(oPrjChlds.getString(0,p))) {
			    
                                // Project GUIDs as values
                                out.write("<OPTION VALUE=\"" + oPrjChlds.getString(0,p) + "\">");

                                // Indent project names
                                for (int s=1;s<oPrjChlds.getInt(2,p); s++) out.write("&nbsp;&nbsp;&nbsp;&nbsp;");

                                // Project names
                                out.write(oPrjChlds.getString(1,p));
                            
                                out.write("</OPTION>");
                              } // fi (oPrjChilds.containskey(id_parent))
                            } // fi (od_level>1)
                          } // next (p)
                        } // fi (gu_project!=oPrjRoots[r])
                      } // next (r)

                    out.write("\n");
%>
                  </SELECT>
                </TD>
                <TD ROWSPAN="10" VALIGN="top">                	
                  <FONT CLASS="formplain">Incidents</FONT>
                  <TABLE SUMMARY="Incidents" CLASS="formfront">
<% for (int b=0; b<nBugs; b++) { %>
                  	<TR>
                  		<TD CLASS="textsmall"><%=String.valueOf(oBugs.getInt(1,b))%></TD>
										  <TD><A HREF="#" CLASS="linksmall" onclick="editBug('<%=oBugs.getString(0,b)%>')"><%=oBugs.getStringNull(2,b,"")%></A></TD>
                  		<TD CLASS="textsmall"><%=oBugs.getDateShort(3,b)%></TD>
                  		<TD CLASS="textsmall"><% if (!oBugs.isNull(4,b)) { if (oBugStatus.containsKey(oBugs.get(4,b))) out.write((String) oBugStatus.get(oBugs.get(4,b))); } %></TD>
                    </TR>
<% } %>
                  </TABLE>
<% if (0==nBugs) out.write ("<FONT CLASS=\"textsmall\">none</FONT><BR>"); %>
                  <BR>
                  <FONT CLASS="formplain">Duties</FONT>
                  <TABLE SUMMARY="Duties" CLASS="formfront">
<% for (int d=0; d<nDuts; d++) { %>
                  	<TR>
										  <TD><A HREF="#" CLASS="linksmall" onclick="editDuty('<%=oDuts.getString(0,d)%>')"><%=oDuts.getStringNull(1,d,"")%></A></TD>
                  		<TD CLASS="textsmall"><%=oDuts.getDateShort(2,d)%></TD>
                  		<TD CLASS="textsmall"><% if (!oDuts.isNull(3,d)) { if (oDutyStatus.containsKey(oDuts.get(3,d))) out.write((String) oDutyStatus.get(oDuts.get(3,d))); } %></TD>
                    </TR>
<% } %>
                  </TABLE>
<% if (0==nDuts) out.write ("<FONT CLASS=\"textsmall\">none</FONT>"); %>
									<BR><BR>
									<IMG SRC="../images/images/projtrack/ganttproject16.gif" WIDTH"=16" HEIGHT="16" ALT="Gantt File Export">&nbsp;
    						  <A HREF="#" onclick="window.open('prj_gantt_export.jsp?gu_project=<%=request.getParameter("gu_project")%>')" CLASS="linkplain">Export to Gantt</A>
									<BR><BR>
									<IMG SRC="../images/images/projtrack/projsnapshot.gif" WIDTH"=16" HEIGHT="16" ALT="Project Snapshots">&nbsp;
    						  <A HREF="prj_snapshot_list.jsp?gu_project=<%=request.getParameter("gu_project")%>&standalone=<%=(request.getParameter("standalone")!=null ? "1" : "0")%>" CLASS="linkplain">Project Snapshots</A><BR>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Start</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="10" NAME="dt_start" VALUE="<% if (oPrj.get(DB.dt_start)!=null) out.write(oSimpleDate.format((Date)oPrj.get(DB.dt_start))); %>">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
                  <IMG SRC="../images/images/spacer.gif" WIDTH="8" HEIGHT="1" BORDER="0">
		  <FONT CLASS="formplain">End</FONT>                  
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="10" NAME="dt_end" VALUE="<% if (oPrj.get(DB.dt_end)!=null) out.write(oSimpleDate.format((Date)oPrj.get(DB.dt_end))); %>">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Reference</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="50" SIZE="20" NAME="id_ref" VALUE="<% if (oPrj.get(DB.id_ref)!=null) out.write(oPrj.getString(DB.id_ref)); %>">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Status</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" MAXLENGTH="16" NAME="id_status" VALUE="<% if (oPrj.get(DB.id_status)!=null) out.write(oPrj.getString(DB.id_status)); %>">
                  <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>
                  &nbsp;&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Status List"></A>
                </TD>
              </TR>              
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Cost</FONT></TD>
                <TD>
                  <FONT CLASS="formplain"><% out.write(String.valueOf(fCost)); %></FONT>
<% if (!bIsGuest) { %>
                  &nbsp;
                  <A CLASS="linkplain" HREF="prj_costs.jsp?gu_project=<%=gu_project%>" TARGET="_blank">Edit Costs</A>
<% } %>
                </TD>
              </TR>
<% if ((iAppMask & (1<<Sales))!=0) { %>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Department</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" MAXLENGTH="255" NAME="id_dept" VALUE="<% if (oPrj.get(DB.id_dept)!=null) out.write(oPrj.getString(DB.id_dept)); %>">
                  <SELECT NAME="sel_dept" STYLE="width:230"><OPTION VALUE=""></OPTION><%=sDeptsLookUp%></SELECT>
                  &nbsp;&nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Department Listing"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Company</FONT></TD>
                <TD>
                  <INPUT TYPE="text" SIZE="34" NAME="nm_legal" VALUE="<% if (oPrj.get(DB.tx_company)!=null) out.write(oPrj.getString(DB.tx_company)); %>" onchange="document.forms[0].gu_company.value='';">
                  &nbsp;&nbsp;<A HREF="javascript:reference(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Companies List"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Contact</FONT></TD>
                <TD>
                  <INPUT TYPE="text" SIZE="34" NAME="tx_contact" VALUE="<% if (oPrj.get(DB.tx_contact)!=null) out.write(oPrj.getString(DB.tx_contact)); %>">
                  &nbsp;&nbsp;<A HREF="javascript:reference(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Contacts List"></A>
                </TD>
              </TR>
<% } %>             
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Oowner</FONT></TD>
                <TD>
                  <INPUT TYPE="text" SIZE="34" NAME="tx_user" VALUE="<%=sUserFullName%>">
                  &nbsp;&nbsp;<A HREF="javascript:reference(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View list of users"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">Description</FONT></TD>
                <TD><TEXTAREA NAME="de_project" ROWS="5" COLS="40" STYLE="font-family:Arial;font-size:9pt"><% if (oPrj.get(DB.de_project)!=null) out.write(oPrj.getString(DB.de_project)); %></TEXTAREA></TD>
              </TR>
              <TR>
                <TD COLSPAN="4"><HR></TD>
              </TR>
              <TR>
                <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
                  <INPUT TYPE="button" CLASS="pushbutton" STYLE="WIDTH:80" ACCESSKEY="s" TITLE="ALT+s" VALUE="Save" onclick="alert ('Your credential level as Guest does not allow you to perform this action')">
<% } else { %>                  
                  <INPUT TYPE="submit" CLASS="pushbutton" STYLE="WIDTH:80" ACCESSKEY="s" TITLE="ALT+s" VALUE="Save">
<% } %>
<% if (request.getParameter("standalone")==null && !bIsGuest) { %>
                  &nbsp;&nbsp;&nbsp;
                  <INPUT TYPE="button" CLASS="pushbutton" STYLE="WIDTH:80" ACCESSKEY="d" TITLE="ALT+d" VALUE="Delete" onClick="javascript:deleteProject()">
<% } %>
                  &nbsp;&nbsp;&nbsp;
                  <INPUT TYPE="button" CLASS="closebutton" STYLE="WIDTH:80" ACCESSKEY="c" TITLE="ALT+c" VALUE="Close" onClick="javascript:window.parent.close()">
                </TD>
                <TD COLSPAN="2"></TD>
              </TR>              
            </TABLE>
          </TD>
        </TR>
      </TABLE> 
      </CENTER>
    </FORM>
  </BODY>
</HTML>
<% oCon1.close("prj_edit"); %>
<%@ include file="../methods/page_epilog.jspf" %>