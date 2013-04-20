<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.workareas.WorkArea,com.knowgate.dataobjs.*,com.knowgate.projtrack.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
  
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  JDCConnection oCon1 = null;  
  String sLastProj = "";
  String sLastWrkA = "";  
  int iRowCount = 0;
  String sTlBug = request.getParameter("tl_bug")==null ? "" : request.getParameter("tl_bug");
  String sPgBug = request.getParameter("pg_bug")==null ? "" : request.getParameter("pg_bug");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
  String sAssigned = request.getParameter("nm_assigned")==null ? "" : request.getParameter("nm_assigned");
  String sTxClient = request.getParameter("tx_client")==null ? "" : request.getParameter("tx_client");
  String sOrderBy = request.getParameter("orderby")==null ? "" : request.getParameter("orderby");
  String sLanguage = getNavigatorLanguage(request);
  String sDomainId = getCookie(request,"domainid","0");  
  String sUserId = getCookie(request,"userid","");
  String sWorkAreaNm = getCookie(request,"workareanm","");  
  String sUserMail = null;
  String sWorkArea = null;
  
  Project oPrj = new Project();
  DBSubset oPrjChlds = null;
  int iPrjChlds = 0;
  StringBuffer oProjCombo = new StringBuffer();
  
  String sSeverityLookUp = null;
  String sPriorityLookUp = null;
  String sAssignedLookUp = null;
  String sStatusLookUp   = null;
  
  if (sWhere.length()==0) {
    if (sPgBug.length()>0)
      sWhere = " AND b.pg_bug=" + sPgBug;
    else if (sTlBug.length()>0)
      sWhere = " AND b.tl_bug " + DBBind.Functions.ILIKE + " '%" + sTlBug.toUpperCase() + "%'";
  } // fi (sWhere=="")
  
  if (sOrderBy.length()==0)
    sOrderBy = ((iApplicationMask & (1<<ProjectMngr))!=0) ? "1" : "11 DESC, 7 DESC";

  DBSubset oBugs = null, oWorkAreas = null;
    
  boolean bIsGuest = true, bIsUser = false, bIsPowUser = false, bIsAdmin = false;

  try {
    Integer oDomainId = new Integer(sDomainId);
    
    oCon1 = GlobalDBBind.getConnection("bug_list");

    oCon1.setAutoCommit(true);

    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
    
    if (bIsAdmin) {
      sWorkArea = decode(nullif(request.getParameter("gu_workarea"), getCookie(request,"workarea","")),"",getCookie(request,"workarea",""));

      oWorkAreas = new DBSubset (DB.k_workareas, DB.gu_workarea+","+DB.nm_workarea, DB.id_domain+"=? ORDER BY 2", 10);
      oWorkAreas.load(oCon1, new Object[]{oDomainId});

      if (sTxClient.length()==0) {
        oBugs = new DBSubset(DB.k_bugs + " b," + DB.k_projects + " p," + DB.k_workareas + " w",
  			     "p.nm_project,b.pg_bug,b.od_priority,b.gu_bug,b.od_severity,b.tl_bug,b.dt_created,b.tx_status,w.nm_workarea,w.gu_workarea,b.dt_modified",
  			     "(p.gu_project=b.gu_project AND p.gu_owner=w.gu_workarea AND w.id_domain=? AND w.bo_active<>0) " +
  			     sWhere + " ORDER BY " + sOrderBy, 100);
      oBugs.setMaxRows(iMaxRows);
      iRowCount = oBugs.load(oCon1, new Object[]{oDomainId});

      }
      else {
        oBugs = new DBSubset(DB.k_bugs + " b," + DB.k_projects + " p," + DB.k_workareas + " w",
  			     "p.nm_project,b.pg_bug,b.od_priority,b.gu_bug,b.od_severity,b.tl_bug,b.dt_created,b.tx_status,w.nm_workarea,w.gu_workarea,b.dt_modified",
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
      sWorkArea = getCookie(request,"workarea","");
      
      if (sTxClient.length()==0) {
        oBugs = new DBSubset(DB.k_bugs + " b," + DB.k_projects + " p",
  			     "p.nm_project,b.pg_bug,b.od_priority,b.gu_bug,b.od_severity,b.tl_bug,b.dt_created,b.tx_status,NULL,p.gu_owner,b.dt_modified",
  			     "(p.gu_project=b.gu_project AND p.gu_owner=?) "+ sWhere + " ORDER BY " + sOrderBy, 100);
      oBugs.setMaxRows(iMaxRows);
      iRowCount = oBugs.load(oCon1, new Object[]{sWorkArea});
      }
      else {
        oBugs = new DBSubset(DB.k_bugs + " b," + DB.k_projects + " p",
  			     "p.nm_project,b.pg_bug,b.od_priority,b.gu_bug,b.od_severity,b.tl_bug,b.dt_created,b.tx_status,NULL,p.gu_owner,b.dt_modified",
  			     "(p.gu_project=b.gu_project AND p.gu_owner=?) " +
  			     "AND (b."+DB.id_client+" IS NOT NULL " + 
  			     "AND (b."+DB.id_client+" IN (SELECT gu_company FROM k_companies WHERE "+DB.gu_workarea+"=? AND ("+DB.nm_legal+" " + DBBind.Functions.ILIKE + " ? OR "+DB.nm_commercial+" " + DBBind.Functions.ILIKE + " ?)) OR " +
  			     "     b."+DB.id_client+" IN (SELECT gu_contact FROM k_contacts  WHERE "+DB.gu_workarea+"='"+sWorkArea+"' AND ("+DB.tx_name+" " + DBBind.Functions.ILIKE + " ? OR "+DB.tx_surname+" " + DBBind.Functions.ILIKE + " ?))) " +   			     
  			     sWhere + " ORDER BY " + sOrderBy, 100);
      oBugs.setMaxRows(iMaxRows);
      iRowCount = oBugs.load(oCon1, new Object[]{sWorkArea,sWorkArea,"%"+sTxClient+"%","%"+sTxClient+"%",sWorkArea,"%"+sTxClient+"%","%"+sTxClient+"%"});
      }
    }

    bIsGuest = WorkArea.isGuest (oCon1,sWorkArea,sUserId);
    bIsUser = WorkArea.isUser (oCon1,sWorkArea,sUserId);
    bIsPowUser = WorkArea.isPowerUser (oCon1,sWorkArea,sUserId);
    
    sSeverityLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.od_severity, sLanguage);
    sPriorityLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.od_priority, sLanguage);
    sAssignedLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.nm_assigned, sLanguage);
    sStatusLookUp   = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.tx_status  , sLanguage);

    if (((iApplicationMask & (1<<ProjectMngr))!=0)) {
      DBSubset oTopLevel;
      
      if (bIsAdmin) {
        oTopLevel = new DBSubset(DB.k_projects,
      			         DB.gu_project + "," + DB.nm_project,
      			         DB.gu_owner + " IN (SELECT " + DB.gu_workarea + " FROM "+DB.k_workareas+" WHERE " + DB.id_domain + "=? AND "+DB.bo_active+"<>0) AND " + DB.id_parent + " IS NULL ORDER BY " + DB.nm_project, 10);
        oTopLevel.load(oCon1, new Object[]{oDomainId});
      }
      else {
        oTopLevel = new DBSubset(DB.k_projects,
      			         DB.gu_project + "," + DB.nm_project,
      	  	                 DB.gu_owner + "=? AND " + DB.id_parent + " IS NULL ORDER BY " + DB.nm_project, 10);
        oTopLevel.load(oCon1, new Object[]{sWorkArea});
      }
    
      for (int t=0; t<oTopLevel.getRowCount(); t++) {
        oPrj.replace(DB.gu_project, oTopLevel.getString(0,t));
        oPrjChlds = oPrj.getAllChilds(oCon1);
        iPrjChlds = oPrjChlds.getRowCount();
        oProjCombo.append ("                      ");
        oProjCombo.append ("<OPTION VALUE=\"" + oTopLevel.getString(0,t) + "\">" + oTopLevel.getString(1,t) + "</OPTION>");
        for (int p=0;p<iPrjChlds; p++) {
          if (oPrjChlds.getInt(2,p)>1) {
            // Project GUIDs as values
            oProjCombo.append ("<OPTION VALUE=\"" + oPrjChlds.getString(0,p) + "\">");
            // Indent project names
            for (int s=1;s<oPrjChlds.getInt(2,p); s++) oProjCombo.append("&nbsp;&nbsp;&nbsp;&nbsp;");
              // Project names
              oProjCombo.append (oPrjChlds.getString(1,p));

              oProjCombo.append ("</OPTION>");
          } // fi (od_level>1)
        } // next (p)
        oProjCombo.append ("\n");
      } // next (t)
      oTopLevel = null;
    } // fi (ProjectManager)
    
    PreparedStatement oStmt = oCon1.prepareStatement("SELECT " + DB.tx_main_email + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?");
    oStmt.setString(1, sUserId);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sUserMail = oRSet.getString(1);
    oRSet.close();
    oStmt.close();
    
    oCon1.close("bug_list");
  }
  catch (NumberFormatException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("bug_list");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NumberFormatException", e.getMessage());
    }      

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("bug_list");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }      

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  catch (IllegalStateException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("bug_list");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IllegalStateException", e.getMessage());
    }      

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  catch (NullPointerException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("bug_list");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NullPointerException", e.getMessage());
    }      

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  
  if (null==oCon1) return;
  oCon1 = null;
  
	sendUsageStats(request, "bug_list");

%><HTML>
  <HEAD>
    <TITLE>hipergate :: Incident Listing</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript">
      <!--
      
      // ------------------------------------------------------      
<%
      // Write bug guids in a JavaScript Array
      // This Array is used when posting multiple elements for deletion.
          
      out.write("      var jsBugs = new Array(");
            
      for (int i=0; i<iRowCount; i++) {
        if (i>0) out.write(","); 
        out.write("\"" + oBugs.getString(3,i) + "\"");
      }
            
      out.write(");\n");
%>
      // ------------------------------------------------------

      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_bugs_lookup&id_language=" + getUserLanguage() + "&id_section=nm_assigned&tp_control=2&nm_control=sel_new_assigned&nm_coding=nm_assigned", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      // ------------------------------------------------------
      
      function editBug(guBug) {
        window.open("bug_edit.jsp?gu_bug=" + guBug, guBug, "width=790,height=580");
      }

      // ------------------------------------------------------

      function deleteBugs() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure that you want to delete the selected incidents?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "bugedit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsBugs.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsBugs[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
      } // deleteBugs()

      // ------------------------------------------------------

      function updateBugs() {
	  
	      var offset = 0;
    	  var frm = document.forms[0];
    	  var chi = frm.checkeditems;
    	  	  
    	  if (frm.sel_new_status.selectedIndex<=0 && frm.sel_new_priority.selectedIndex<=0 && frm.sel_new_severity.selectedIndex<=0 && frm.sel_new_assigned.selectedIndex<=0) {
    	    alert ("An attribute to be updated must be selected");
    	    return false;
    	  }
    
    	  if (window.confirm("Are you sure that you want to update selected incidents?")) {
	  	  
	        chi.value = "";	  	  
	        frm.action = "bugedit_update.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	        for (var i=0;i<jsBugs.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsBugs[i] + ",";
              offset++;
	        } // next()
	    
	        if (chi.value.length>0) {
	          chi.value = chi.value.substr(0,chi.value.length-1);
            frm.nm_assigned.value = (getCombo(frm.sel_new_assigned)==null ? "" : getCombo(frm.sel_new_assigned));
            frm.submit();
          } // fi(chi!="")
        } // fi (confirm)
      } // updateBugs()
	
      // ----------------------------------------------------

      function printerVersion() {
	      var offset = 0;
	      var frm = window.document.forms[0];
			  var chi = frm.checkeditems;
	  	  	  	  
	      chi.value = "";	  	  
	  	  
	      for (var i=0;i<jsBugs.length; i++) {
          while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
              chi.value += "'" + jsBugs[i] + "',";
            offset++;
	      } // next()
	    
	      if (chi.value.length>0) {
	        frm.action = "bug_report.jsp?where=%20AND%20b.gu_bug%20IN%20(" + chi.value.substr(0,chi.value.length-1) + ")%20";
        } else {
	        frm.action = "bug_report.jsp";
        }
	      frm.submit();
      } // printerVersion

      // ----------------------------------------------------
      
      function queryByCombos() {
	var frm = document.forms[0];
	var whr = "";
	
<% if (bIsAdmin) { %>
        if (frm.sel_area.selectedIndex>0) {
	  frm.gu_workarea.value = getCombo(frm.sel_area);
	  whr += " AND w.gu_workarea='" + frm.gu_workarea.value + "' ";
	}
	else {
	  frm.gu_workarea.value = "";
	}
<% } %>
	
	if (frm.sel_status.selectedIndex>0) {
	  if (getCombo(frm.sel_status).length==0)
	    whr += " AND (b.tx_status IS NULL ";
	  else
	    whr += " AND (b.tx_status='" + getCombo(frm.sel_status) + "'";
	}
<% if (((iApplicationMask & (1<<ProjectMngr))!=0)) { %>
	if (frm.sel_project.selectedIndex>0)
	  whr += (whr.length==0 ? " AND (" : " AND ") + " b.gu_project='" + getCombo(frm.sel_project) + "'";
<% } %>

	if (frm.dt_start.value.length>0 && frm.dt_end.value.length>0) {
	  if (isDate(frm.dt_start.value, "d") && isDate(frm.dt_end.value, "d")) {
	    whr += (whr.length==0 ? " AND (" : " AND ") + " b.dt_created BETWEEN { ts '" + frm.dt_start.value + " 00:00:00'} AND { ts '" + frm.dt_end.value + " 23:59:59'} ";	  
	  }
	  else {
	    if (!isDate(frm.dt_start.value, "d")) alert ("Invalid Start Date");
	    if (!isDate(frm.dt_end.value, "d")) alert ("Invalid End date");	     
	    return;
	  }
	}
	else if (frm.dt_start.value.length>0) {
	  if (isDate(frm.dt_start.value, "d"))
	    whr += (whr.length==0 ? " AND (" : " AND ") + " b.dt_created>={ ts '" + frm.dt_start.value + " 00:00:00'} ";  
	  else {
	    alert ("Invalid Start Date");
	    return;
	  }
	} 
	else if (frm.dt_end.value.length>0) {
	  if (isDate(frm.dt_end.value, "d"))
	    whr += (whr.length==0 ? " AND (" : " AND ") + " b.dt_created<={ ts '" + frm.dt_end.value + " 23:59:59'} ";	  
	  else {
	    alert ("Invalid End date");
	    return;
	  }
	} 
	
	if (frm.id_ref.value.length>0) {
	  if (isIntValue(frm.id_ref.value))
	    whr += (whr.length==0 ? " AND (" : " AND ") + " (b.pg_bug =" + frm.id_ref.value + " OR b.id_ref='"+frm.id_ref.value+"') ";
          else
	    whr += (whr.length==0 ? " AND (" : " AND ") + " b.id_ref='" + frm.id_ref.value + "'";	  
	}
 
	if (frm.sel_priority.selectedIndex>0)
	  whr += (whr.length==0 ? " AND (" : " AND ") + " b.od_priority=" + getCombo(frm.sel_priority);

	if (frm.sel_severity.selectedIndex>0)
	  whr += (whr.length==0 ? " AND (" : " AND ") + " b.od_severity=" + getCombo(frm.sel_severity);

<% if (bIsAdmin || bIsPowUser) { %>
	if (frm.nm_reporter.length>0)
	  whr += (whr.length==0 ? " AND (" : " AND ") + " b.nm_reporter <%=DBBind.Functions.ILIKE%> '%" + frm.nm_reporter.value + "%' ";
	if (frm.sel_assigned.selectedIndex>0) {
	  frm.nm_assigned.value = getCombo(frm.sel_assigned);
	  whr += (whr.length==0 ? " AND (" : " AND ") + " b.nm_assigned='" + getCombo(frm.sel_assigned) + "' ";
	}
<% } %>		
<% if (!bIsAdmin) { %>	
	else if (frm.mybugs[1].checked) {
	  frm.nm_assigned.value = getCookie("userid");
	  whr += (whr.length==0 ? " AND (" : " AND ") + " (b.nm_assigned='" + frm.nm_assigned.value + "' OR b.tx_rep_mail='<%=sUserMail%>')";
	}
	else
	  frm.nm_assigned.value = "";
<% } %>
	
	if (frm.tl_bug.value.length>0)
	  whr += (whr.length==0 ? " AND (" : " AND ") + " b.tl_bug <%=DBBind.Functions.ILIKE%> '%" + frm.tl_bug.value.toUpperCase() + "%'";
		
	if (whr.length>0) {	  
	  whr += ")";
          frm.where.value = whr;
	  frm.submit();
	}
	else {
          frm.where.value = "";
	  frm.submit();
	}	
      }

      // ----------------------------------------------------

      function skipChar (str, idx, c) {
        while (idx<str.length) {        
          if (str.charCodeAt(idx)==c)
            idx++;
          else
            break;
        } // wend
        
        return idx;
      } // skipChar

      // ----------------------------------------------------

      function parseColumn (colname, type) {
	var whr = document.forms[0].where.value;
	var idx = whr.indexOf(colname);
	var idz;
	
	if (idx<0)
	  return null;
	else {
	  idx += colname.length;
	  idx = skipChar(whr, idx, 32);
	  idx = skipChar(whr, idx, 61);
	  idx = skipChar(whr, idx, 32);
	  
	  if (type=="varchar") {
	    idx = whr.indexOf("'", idx);
	    idx++;
	    if (whr.charAt(idx)=='%') idx++;
	    idz = whr.indexOf("'", idx);
	    if (whr.charAt(idz-1)=='%') --idz;
	  }
	  else {
	    idz = idx;
	    
	    while (whr.charCodeAt(idz)>=48 && whr.charCodeAt(idz)<=57) {

	      idz++;
	      if (idz==whr.length) break;
	    }
	  }	
	  return whr.substring(idx, idz);	  
	}
      } // parseColumn

      // ----------------------------------------------------
      
      function setCombos() {
        var frm = document.forms[0];        
	      var col;

<% if (((iApplicationMask & (1<<ProjectMngr))!=0)) { %>
	col = parseColumn("gu_project", "varchar");
	if (null!=col) setCombo(frm.sel_project, col);
<% } %>
	col = parseColumn("tx_status", "varchar");
	if (null!=col) setCombo(frm.sel_status, col);


	col = parseColumn("od_severity", "smallint");
	if (null!=col) setCombo(frm.sel_severity, col);

<% if (bIsAdmin || bIsPowUser) { %>

	col = parseColumn("nm_reporter", "varchar");
	if (null!=col) frm.nm_reporter.value =  col;

	col = parseColumn("nm_assigned", "varchar");
	if (null!=col) {
	  frm.nm_assigned.value =  col;
          setCombo(frm.sel_assigned, col);
        }
<% } %>
	      col = parseColumn("tl_bug", "varchar");
	      if (null!=col) frm.tl_bug.value =  col;

        var opt = frm.sel_new_priority.options;
        var pln = opt.length;
				var cpy = new Array();
				
        for (var i=0; i<pln; i++)   
          cpy[i] = new Array(opt[i].value, opt[i].text);
				
				cpy.sort(function(a,b) { if (isNaN(a[0]) || isNaN(b[0])) return (a[0]>b[0] ? 1 : (a[0]<b[0] ? -1 : 0)); else return (a[0]-b[0]); });
  
        for (var i=opt.length-1; i>=0; i--)  
          opt[i] = null;
      	
        for (var i=0; i<cpy.length; i++)
          comboPush (frm.sel_new_priority, cpy[i][1], cpy[i][0], false, false);

        for (var p=0; p<pln; p++) {
        	if (opt[p].value.length>0)
            opt[p].text = opt[p].value + " - " + opt[p].text
        } // next

	      col = parseColumn("od_priority", "smallint");
	      if (null!=col) setCombo(frm.sel_priority, col);
      }

      // ----------------------------------------------------
      
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  onload="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM NAME="frmPrinterFriendly" ACTION="bug_list.jsp?selected=4&subselected=4" METHOD="POST">
    <INPUT TYPE="hidden" NAME="checkeditems">
    <INPUT TYPE="hidden" NAME="pg_bug" VALUE="<%=sPgBug%>">
    <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Incident Listing</FONT></TD></TR></TABLE>
    <BR>    
    <TABLE CLASS="formfront">
      <TR>
        <TD><FONT CLASS="textplain">Reference:</FONT></TD>
        <TD>
          <TABLE WIDTH="100%">
            <TR>
              <TD><INPUT CLASS="combomini" NAME="id_ref" VALUE="<%=nullif(request.getParameter("id_ref"))%>"></TD>
              <TD ALIGN="right"><FONT CLASS="textplain">Between:</FONT></TD>
            </TR>
          </TABLE>
        </TD>
        <TD>
          <INPUT CLASS="combomini" TYPE="text" MAXLENGTH="10" SIZE="12" NAME="dt_start" VALUE="<%=nullif(request.getParameter("dt_start"))%>">&nbsp;
          <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Start date"></A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;and&nbsp;&nbsp;&nbsp;</FONT>
          <INPUT CLASS="combomini" TYPE="text" MAXLENGTH="10" SIZE="12" NAME="dt_end" VALUE="<%=nullif(request.getParameter("dt_end"))%>">&nbsp;
          <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="End date"></A>
        </TD>
      </TR>
      <TR>
<% if (((iApplicationMask & (1<<ProjectMngr))!=0)) { %>
        <TD><FONT CLASS="textplain">Project:</FONT></TD>
        <TD>
          <TABLE WIDTH="100%">
            <TR>
              <TD><SELECT CLASS="combomini" NAME="sel_project"><OPTION VALUE=""></OPTION><%=oProjCombo.toString()%></SELECT></TD>
              <TD ALIGN="right"><FONT CLASS="textplain">Title:</FONT></TD>
            </TR>
          </TABLE>
        </TD>
<% } else { %>
        <TD><FONT CLASS="textplain">Customer:</FONT></TD>
        <TD>
          <TABLE WIDTH="100%">
            <TR>
              <TD><INPUT TYPE="text" CLASS="combomini" NAME="tx_client"></TD>
              <TD ALIGN="right"><FONT CLASS="textplain">Title:</FONT></TD>
            </TR>
          </TABLE>
        </TD>
<% } %>    
        <TD>
          <INPUT CLASS="combomini" TYPE="text" MAXLENGTH="250" SIZE="50" NAME="tl_bug" STYLE="text-transform:uppercase" VALUE="<%=nullif(request.getParameter("tl_bug"))%>">
        </TD>
      </TR>
      <TR>
        <TD>
          <FONT CLASS="textplain">Status:</FONT>
        </TD>
        <TD>
          <TABLE WIDTH="100%">
            <TR>
              <TD><SELECT CLASS="combomini" NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT></TD>
              <TD ALIGN="right"><FONT CLASS="textplain">Priority:</FONT></TD>
            </TR>
          </TABLE>
        </TD>
        <TD>
          <TABLE WIDTH="100%">
            <TR>
              <TD><SELECT CLASS="combomini" NAME="sel_priority"><OPTION VALUE=""></OPTION><%=sPriorityLookUp%></SELECT></TD>
              <TD ALIGN="right"><FONT CLASS="textsmall">Severity:</FONT>&nbsp;<SELECT CLASS="combomini" NAME="sel_severity"><OPTION VALUE=""></OPTION><%=sSeverityLookUp%></SELECT></TD>
            </TR>
          </TABLE>
        </TD>
      </TR>
      <TR>
<% if (bIsAdmin) {
     String sWrkParam = nullif(request.getParameter("gu_workarea")); %>
        <TD><FONT CLASS="textplain">Area:</FONT></TD>
        <TD><INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=sWrkParam%>"><SELECT NAME="sel_area"><OPTION VALUE=""></OPTION><% for (int w=0;w<oWorkAreas.getRowCount(); w++) out.write("<OPTION VALUE=\""+oWorkAreas.getString(0,w)+"\""+(oWorkAreas.getString(0,w).equals(sWrkParam) ? " SELECTED" : "")+">"+oWorkAreas.getString(1,w)+"</OPTION>"); %></SELECT></TD>
<% } else if (bIsPowUser) { %>
        <TD COLSPAN="2">
	        <INPUT TYPE="radio" NAME="mybugs" <% if (sAssigned.length()==0) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="textplain">View all incidents</FONT>&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="mybugs" <% if (sAssigned.equals(sUserId)) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="textplain">View my incidents</FONT>
        </TD>
<% } else { %>
        <TD COLSPAN="2">
	        <DIV STYLE="display:none"><INPUT TYPE="radio" NAME="mybugs"></DIV><INPUT TYPE="radio" NAME="mybugs" CHECKED>&nbsp;<FONT CLASS="textplain">View my incidents</FONT>
        </TD>
<% }%>
<% if (bIsAdmin || bIsPowUser) { %>
        <TD ALIGN="right">
          <FONT CLASS="textplain">View assigned to:</FONT>&nbsp;<INPUT TYPE="hidden" NAME="nm_assigned" VALUE="<%=sAssigned%>"><SELECT CLASS="combomini" NAME="sel_assigned"><OPTION VALUE=""></OPTION><%=sAssignedLookUp%></SELECT>
	</TD>
<% } else { %>
        <TD ALIGN="right"><INPUT TYPE="hidden" NAME="nm_assigned" VALUE=""></TD>
<% } %>	
      </TR>
      <TR>
<% if (bIsAdmin || bIsPowUser) { %>
        <TD><FONT CLASS="textplain">Reported by:</FONT></TD>
        <TD><INPUT CLASS="combomini" TYPE="text" MAXLENGTH="50" NAME="nm_reporter" SIZE="30" STYLE="text-transform:uppercase"></TD>
<% } else { %>
        <TD COLSPAN="2"><INPUT TYPE="hidden" NAME="nm_reporter" VALUE=""></TD>
<% } %>
        <TD></TD>
      </TR>
      <TR>
        <TD COLSPAN="3">
          <FONT CLASS="textplain">Sort by&nbsp;&nbsp;&nbsp;</FONT>
          <INPUT TYPE="radio" NAME="orderby" VALUE="2" <%=(sOrderBy.equals("2") ? "CHECKED" : "")%>>&nbsp;<FONT CLASS="textplain">Incident Num</FONT>
          &nbsp;&nbsp;&nbsp;
          <INPUT TYPE="radio" NAME="orderby" VALUE="3" <%=(sOrderBy.equals("3") ? "CHECKED" : "")%>>&nbsp;<FONT CLASS="textplain">Priority</FONT>
          &nbsp;&nbsp;&nbsp;
          <INPUT TYPE="radio" NAME="orderby" VALUE="7 DESC" <%=(sOrderBy.equals("7 DESC") ? "CHECKED" : "")%>>&nbsp;<FONT CLASS="textplain">Date</FONT>
          &nbsp;&nbsp;&nbsp;
          <INPUT TYPE="radio" NAME="orderby" VALUE="8 DESC" <%=(sOrderBy.equals("8 DESC") ? "CHECKED" : "")%>>&nbsp;<FONT CLASS="textplain">Status</FONT>
          &nbsp;&nbsp;&nbsp;
          <INPUT TYPE="radio" NAME="orderby" VALUE="1" <%=(sOrderBy.equals("1") ? "CHECKED" : "")%>>&nbsp;<FONT CLASS="textplain">Project</FONT>
        </TD>
      </TR>
      <TR>
        <TD COLSPAN="2"></TD>
        <TD ALIGN="right">
	  <IMG SRC="../images/images/search16x16.gif" BORDER="0">&nbsp;<A HREF="javascript:queryByCombos()" CLASS="linkplain">Search</A>&nbsp;&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/undosearch16x16.gif" BORDER="0">&nbsp;<A HREF="bug_list.jsp?selected=4&subselected=4" CLASS="linkplain">Undo Search</A>
        </TD>
      </TR>
    </TABLE>
    <TABLE CELLSPACING="0" CELLPADDING="2">      
<% if (!bIsGuest) { %>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD COLSPAN="8">
          <IMG SRC="../images/images/new16x16.gif" BORDER="0">&nbsp;
          <A HREF="#" onClick="window.open('bug_new.jsp','reportbug','menubar=no,toolbar=no,width=700,height=520')" CLASS="linkplain">New Incident</A>
<% if (bIsAdmin) { %>
			    &nbsp;&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0">&nbsp;<A HREF="javascript:deleteBugs()" CLASS="linkplain">Delete Incidents</A>
<% } %>
          <!--
          <IMG SRC="../images/images/refresh.gif" BORDER="0">&nbsp;<A HREF="#" onClick="document.forms[0].submit()" CLASS="linkplain">Update</A>
          -->
          &nbsp;&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/printer16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0">&nbsp;<A HREF="#" onClick="printerVersion()" CLASS="linkplain">Printer Friendly Version</A>
        </TD>
      </TR>
<% } %>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <%
        for (int r=0; r<iRowCount; r++) {
          if (bIsAdmin) {
	    if (!sLastWrkA.equals(oBugs.getString(8,r))) {          
              sLastWrkA = oBugs.getString(8,r);
              out.write("      <TR CLASS=\"stripheader\">\n");
              out.write("        <TD COLSPAN=\"3\"><FONT CLASS=\"forminvstrong\">" + sLastWrkA + "</FONT></TD>\n");
              out.write("        <TD><FONT CLASS=\"forminvstrong\">Fecha</FONT></TD>\n");
              out.write("        <TD COLSPAN=\"2\"></TD>\n");
              out.write("        <TD><FONT CLASS=\"forminvstrong\">Proyecto</FONT></TD>\n");
              out.write("        <TD></TD>\n");
              out.write("      </TR>\n");
            } // fi
          }
      	  else if (!sLastProj.equals(oBugs.getString(0,r))) {

            sLastProj = oBugs.getString(0,r);
      	    if (((iApplicationMask & (1<<ProjectMngr))!=0)) {   
              out.write("      <TR CLASS=\"stripheader\">\n");
              out.write("        <TD COLSPAN=\"3\"><FONT CLASS=\"forminvstrong\">" + sLastProj + "</FONT></TD>\n");
              out.write("        <TD><FONT CLASS=\"forminvstrong\">Fecha</FONT></TD>\n");
              out.write("        <TD COLSPAN=\"2\"></TD>\n");
              out.write("        <TD><FONT CLASS=\"forminvstrong\">Proyecto</FONT></TD>\n");
              out.write("        <TD></TD>\n");
              out.write("      </TR>\n");
            } // fi (ProjectMngr)
      	  } // fi (sLastProj==current.gu_project)
      %>
      <TR CLASS="strip<%= (r%2==0 ? "1" : "2") %>">
        <TD><SPAN TITLE="Incident number"><FONT CLASS="textsmall"><%=oBugs.get(1,r)%></FONT></SPAN></TD>
        <%
           switch (oBugs.getInt(2,r)) {
             case 1 : out.write("        <TD><IMG SRC=\"../images/images/highimp.gif\" WIDTH=\"12\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Priority\"></TD>\n");
		           break;
             case 5 : out.write("        <TD><IMG SRC=\"../images/images/lowimp.gif\" WIDTH=\"12\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Priority\"></TD>\n");
		           break;
	           default: out.write("        <TD><IMG SRC=\"../images/images/spacer.gif\" WIDTH=\"12\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Priority\"></TD>\n");		     
           }
        %>
        <TD><A HREF="#" onClick="javascript:editBug('<%=oBugs.getString(3,r)%>')" CLASS="linkplain"><%=oBugs.getString(5,r)%></A></TD>
        <TD><FONT CLASS="textsmall"><%=oSimpleDate.format((Date) oBugs.get(6,r))%></FONT></TD>	
        <TD><FONT CLASS="textsmall">&nbsp;<%=oBugs.getInt(2,r)%></FONT></TD>
        <TD><IMG SRC="../images/images/<%=(oBugs.get(7,r)==null ? "pending.gif" : "corrected.gif")%>" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Status"></TD>
<%
   if (bIsAdmin)
      out.write ("       <TD><FONT CLASS=\"textsmall\">"+(oBugs.getString(8,r).equals(sWorkAreaNm) ? "" : oBugs.getString(8,r)+" ")+oBugs.getString(0,r)+"</FONT></TD>\n");
   else
     out.write ("        <TD>"+oBugs.getString(0,r)+"</TD>\n");   
   
   if (bIsGuest)
     out.write ("        <TD></TD>\n");   
   else
      out.write ("       <TD><INPUT TYPE=\"checkbox\" NAME=\"c_" + oBugs.getString(3,r) + "\" VALUE=\"" + oBugs.getString(3,r) +  "\"></TD>\n");
%>        
      </TR>
      <% } // next (r) %>
<% if (bIsAdmin || bIsUser || bIsPowUser) { %>  
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD COLSPAN="8">
	  <TABLE BORDER="0" SUMMARY="Massive Update">
	    <TR>
	      <TD>
	  	&nbsp;&nbsp;&nbsp;&nbsp;<FONT CLASS="textsmall">Change to&nbsp;Status</FONT>&nbsp;
	      </TD>
	      <TD>
	        <SELECT CLASS="combomini" NAME="sel_new_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>
	        &nbsp;&nbsp;
                <FONT CLASS="textsmall">Priority</FONT><SELECT CLASS="combomini" NAME="sel_new_priority"><OPTION VALUE=""></OPTION><%=sPriorityLookUp%></SELECT>
	      </TD>
              <TD>
                &nbsp;&nbsp;
                <FONT CLASS="textsmall">Severity:</FONT>&nbsp;<SELECT CLASS="combomini" NAME="sel_new_severity"><OPTION VALUE=""></OPTION><%=sSeverityLookUp%></SELECT>
	      </TD>
	    </TR>
	    <TR>
	      <TD>
	        &nbsp;&nbsp;&nbsp;&nbsp;<FONT CLASS="textsmall">Assign to&nbsp;</FONT>
	      </TD>
	      <TD>
	        <SELECT CLASS="combomini" NAME="sel_new_assigned" onchange="setCombo(document.forms[0].sel_assigned,this.options[this.selectedIndex].value);document.forms[0].nm_assigned.value=this.options[this.selectedIndex].value;"><OPTION VALUE=""></OPTION><%=sAssignedLookUp%></SELECT>
	        &nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Add resources"></A>
	      </TD>
	      <TD COLSPAN="2" ALIGN="right">
                <A HREF="javascript:updateBugs()" CLASS="linkplain">Change</A>
	      </TD>
	    </TR>
	  </TABLE>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
<% } %>
    </TABLE>
    <BR>    
    <% if (sWhere.length()>0) {
      if (0==iRowCount)
        out.write("    <FONT CLASS=\"textplain\">No Incident was found matching the specified criteria.</FONT>");
      else if (1==iRowCount)
        out.write("    <FONT CLASS=\"textplain\">1 incident was found matching the specified criteria</FONT>");
      else
        out.write("    <FONT CLASS=\"textplain\">&nbsp;" + String.valueOf(iRowCount) + " incidents that match the specified criteria</FONT>");
    }
    %>
    <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
  </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>
