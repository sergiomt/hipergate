<%@ page import="java.util.HashMap,java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.hipergate.QueryByForm,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");

  String sStatus = nullif(request.getParameter("id_status")); //, getCookie(request, "lastprojstatus", ""));
  String sLevel = nullif(request.getParameter("od_level")); //, getCookie(request, "lastprojlevel", ""));
  String sParent = nullif(request.getParameter("id_parent"));
  String sGrandParent = null;
  String sFilter;
  float fTotalCost = 0f;

  if (sStatus.length()==0)
    sFilter = "";
  else if (sStatus.equals("ABIERTO"))
    sFilter = "(b." + DB.id_status + "='ABIERTO' OR b." + DB.id_status + " IS NULL) AND ";
  else
    sFilter = "b." + DB.id_status + "='" + sStatus + "' AND ";

  if (sLevel.length()>0)
    sFilter += " b." + DB.od_level + "=1 AND ";

  if (sParent.length()>0)
    sFilter += " b." + DB.id_parent + "='" + sParent + "' AND ";

  int iScreenWidth;
  float fScreenRatio;

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String screen_width = request.getParameter("screen_width");

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else {
    try { iScreenWidth = Integer.parseInt(screen_width); } catch (NumberFormatException nfe) {iScreenWidth = 800;}
  }
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio = 1;
        
  String sField = request.getParameter("field")==null ? "" : request.getParameter("field");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
        
  int iProjectCount = 0;
  DBSubset oProjects = null;
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "100"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }

  try {  
    if (request.getParameter("skip")!=null)
      iSkip = Integer.parseInt(request.getParameter("skip"));      
    else
      iSkip = 0;
  }
  catch (NumberFormatException nfe) { iSkip = 0; }
  
  if (iSkip<0) iSkip = 0;

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  if (12==iOrderBy) sOrderBy = "12,13";

  JDCConnection oConn = null;  
  boolean bIsGuest = true;
  String sStatusLookUp = "";
  HashMap oStatusTrMap = null;      
    
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);

    oConn = GlobalDBBind.getConnection("projectlisting");

    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (oConn, DB.k_projects_lookup, gu_workarea, DB.id_status, sLanguage);
    oStatusTrMap = GlobalDBLang.getLookUpMap((Connection) oConn, DB.k_projects_lookup, gu_workarea, DB.id_status, sLanguage);

		
    if (sWhere.length()>0) {
      
      oProjects = new DBSubset ("v_project_company b", 
      				 "b.od_level,b.od_walk,b.gu_project,b.nm_project,b.id_parent,b.dt_created,b.dt_start,b.dt_end,b.pr_cost,b.gu_company,b.gu_contact,b.nm_legal,b.full_name,b.id_status",
      				 "b." + DB.gu_owner + "='" + gu_workarea + "' " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oProjects.setMaxRows(iMaxRows);
      iProjectCount = oProjects.load (oConn, iSkip);
    }
    else if (sFind.length()==0 || sField.length()==0) {
    
      oProjects = new DBSubset ("v_project_company b", 
      				 "b.od_level,b.od_walk,b.gu_project,b.nm_project,b.id_parent,b.dt_created,b.dt_start,b.dt_end,b.pr_cost,b.gu_company,b.gu_contact,b.nm_legal,b.full_name,b.id_status",
      				 sFilter + " b." + DB.gu_owner+ "='" + gu_workarea + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oProjects.setMaxRows(iMaxRows);
      iProjectCount = oProjects.load (oConn, iSkip);
    }
    else {
      
      oProjects = new DBSubset ("v_project_company b",  
      				"b.od_level,b.od_walk,b.gu_project,b.nm_project,b.id_parent,b.dt_created,b.dt_start,b.dt_end,b.pr_cost,b.gu_company,b.gu_contact,b.nm_legal,b.full_name,b.id_status",
      				sFilter + "b." + DB.gu_owner+ "='" + gu_workarea + "' AND b." + sField + " " + DBBind.Functions.ILIKE + " ? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oProjects.setMaxRows(iMaxRows);
      Object[] aFind = { "%" + sFind + "%" };
      iProjectCount = oProjects.load (oConn, aFind, iSkip);
    }
    
    if (sParent.length()>0) {
      sGrandParent = DBCommand.queryStr(oConn, "SELECT "+DB.id_parent+" FROM "+DB.k_projects+" WHERE "+DB.gu_project+"='"+sParent+"'");      
    }

    oConn.close("projectlisting"); 
  }
  catch (SQLException e) {  
    oProjects = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("projectlisting");
    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
        
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;  
  oConn = null;  

	sendUsageStats(request, "project_listing");

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Project Management</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
    var menuLayer;

    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');

    dynapi.onLoad(init);
    function init() {
 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setVisible(true);
      menuLayer.setHTML(rightMenuHTML);      
    }
    // -->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>    
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        var jsProjectId;
        var jsProjectNm;            
<%          
          out.write("        var jsProjects = new Array(");
            for (int i=0; i<iProjectCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oProjects.getString(2,i) + "\"");
            }
          out.write(");\n        ");
%>
        // ------------------------------------------------------

        function navigateProjects() {      
          window.open("proj_nav_f.jsp", "navproject", "menubar=yes,toolbar=no,status=yes,width=780,height=520");
        }

        // ----------------------------------------------------
        	
	function createProject() {	  
          window.open("prj_new.jsp", "newproject", "menubar=no,toolbar=no,width=780,height=520");       
	} // createProject()

        // ----------------------------------------------------
	
	function deleteProjects() {	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to delete selected projects?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "prjedit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsProjects.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsProjects[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
	      	      
              frm.submit();
              return true;
            } // fi(chi!="")
            else
              return false;            
          }
          else
            return false;
          // fi (confirm)
	} // deleteProjects()
	
        // ----------------------------------------------------

	function modifyProject(id,nm) {	  
	  self.open ("prj_edit.jsp?gu_project=" + id + "&n_project=" + escape(nm) + "&standalone=1", "editproject", "directories=no,toolbar=no,menubar=no,width=780,height=520");
	}	

        // ----------------------------------------------------

	function sortBy(fld) {
	  window.location = "project_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>" + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	}			

        // ----------------------------------------------------

        function selectAll() {
          var frm = document.forms[0];
          
          for (var c=0; c<jsProjects.length; c++)                        
            eval ("frm.elements['P" + jsProjects[c] + "'].click()");
        } // selectAll()
       
       // ----------------------------------------------------
	
	     function findProject() {
	       var frm = document.forms[0];
	  
	       if (frm.find.value.length>0)
	         window.document.location = "project_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	       else
	         window.document.location = "project_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  
	       return true;
	     } // findProject()

      // ----------------------------------------------------
	
      function filter(st,lv) {
        var frm = document.forms[0];
				if (st==null) st = "";
				if (lv==null) lv = "";
				
	      if (frm.status[0].checked && frm.level[0].checked)
	        return findProject();
	      else {
	        if (frm.find.value.length>0)
	          window.document.location = "project_listing.jsp?id_status=" + st + "&od_level=" + lv + "&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	        else
	          window.document.location = "project_listing.jsp?id_status=" + st + "&od_level=" + lv + "&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");	  
	      return true;
	      }
      } // filter

       // ----------------------------------------------------
	
	     function listSubprojects(gu) {
	       var frm = document.forms[0];
	       window.document.location = "project_listing.jsp?id_parent=" + gu + "&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	       return true;
			 }
			         
      // ----------------------------------------------------

      function listDuties(id) {
        document.forms[0].where.value = " AND b.gu_project = '" + id + "'";
        document.forms[0].action = "duty_list.jsp?selected="+ getURLParam("selected") + "&subselected=1";
        document.forms[0].submit();
      }

      // ----------------------------------------------------

      function createDuty(prj) {
        window.open('duty_new.jsp?gu_project='+prj, 'newduty', 'menubar=no,toolbar=no,width=780,height=' + (screen.height<=600 ? '520' : '640'));
      }

      // ----------------------------------------------------

      function listBugs(id) {
        document.forms[0].where.value = " AND b.gu_project = '" + id + "'";
        document.forms[0].action = "bug_list.jsp?selected=4&subselected=2";
        document.forms[0].submit();
      }

      // ----------------------------------------------------

      function createSubProject(id,nm) {
        window.open("prjedit_store.jsp?nm_project=" + escape("Sub " + nm) + "&gu_owner=<%=gu_workarea%>&id_parent=" + id + "&is_subproject=1&is_standalone=1&is_new=1", null, "directories=no,toolbar=no,menubar=no,width=600,height=520");
      }

      // ------------------------------------------------------

      function updateProjects() {

	      var offset = 0;
    	  var frm = document.forms[0];
    	  var chi = frm.checkeditems;
    	  	  
    	  if (frm.sel_new_status.selectedIndex<=0) {
    	    alert ("A new status for the projects must be chosen");
    	    return false;
    	  }

    	  if (window.confirm("Are you sure that you want to update the selected projects?")) {

	        chi.value = "";
	        frm.action = "projectedit_update.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");

	        for (var i=0;i<<%=String.valueOf(iProjectCount)%>; i++) {
            while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += frm.elements[offset].value + ",";
              offset++;
	        } // next()

	        if (chi.value.length>0) {
	          chi.value = chi.value.substr(0,chi.value.length-1);
            frm.submit();
          } // fi(chi!="")
        } // fi (confirm)
      } // updateDuties()
      
      // ----------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.nm_legal%>");
          document.forms[0].find.value = jsProjectNm;
        }
      } // findCloned()
      
      function clone(id) {        
        winclone = window.open ("prj_clone.jsp?gu_project=" + id, "cloneproject", "directories=no,toolbar=no,menubar=no,width=500,height=400");                
        intervalId = setInterval ("findCloned()", 100);
      }	// clone()
      
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCookie ("lastprojstatus", "<%=sStatus%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	} // setCombos()
    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE SUMMARY="Strip Title"><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Project Listing</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE SUMMARY="Controls Panel" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="10" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Project"></TD>
        <TD VALIGN="middle">
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert ('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New</A>
<% } else { %>
          <A HREF="#" onclick="createProject()" CLASS="linkplain">New</A>
<% } %>
        </TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Project"></TD>
        <TD>
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert ('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
          <A HREF="javascript:deleteProjects()" CLASS="linkplain">Delete</A>
<% } %>
        </TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/tree/menu_root.gif" BORDER="0" ALT="View Project Tree"></TD>
        <TD><A HREF="#" onclick="navigateProjects()" CLASS="linkplain">Tree</A></TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Find Project"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE="<%=DB.nm_project%>">Name<OPTION VALUE="<%=DB.nm_legal%>">Company<OPTION VALUE="full_name">Contact<OPTION VALUE="od_level">Level<OPTION VALUE="id_ref">Reference</SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" SIZE="16" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="javascript:findProject();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="middle">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></TD>
        <TD VALIGN="middle">
          <A HREF="javascript:document.forms[0].find.value='';document.forms[0].level.checked=document.forms[0].status.checked=true;filter('');" CLASS="linkplain" TITLE="Discard Find Filter">Discard</A>
        </TD>
      </TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/refresh.gif" WIDTH="13" HEIGHT="16" BORDER="0" ALT="Refresh"></TD>
        <TD VALIGN="middle"><A HREF="prj_reexpand.jsp?selected=<%=nullif(request.getParameter("selected"),"4")%>&subselected=<%=nullif(request.getParameter("subselected"),"0")%>" CLASS="linkplain">Refresh</A></TD>
        <TD COLSPAN="5"></TD>
        <TD COLSPAN="3" ALIGN="right">
        <FONT CLASS="textplain">Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR>
        <TD COLSPAN="10">
        	<TABLE SUMMARY="Additional filters">
        	  <TR>
              <TD CLASS="formstrong">Status</TD>            
              <TD CLASS="textplain"><INPUT TYPE="radio" NAME="status" VALUE="" onclick="filter('',getCheckedValue(document.forms[0].level))" <%=(sStatus.length()==0 ? "CHECKED" : "")%>>&nbsp;All</TD>
              <TD CLASS="textplain"><INPUT TYPE="radio" NAME="status" VALUE="ABIERTO" onclick="filter('ABIERTO',getCheckedValue(document.forms[0].level))" <%=(sStatus.equals("ABIERTO") ? "CHECKED" : "")%>>&nbsp;Open</TD>
              <TD CLASS="textplain"><INPUT TYPE="radio" NAME="status" VALUE="CERRADO" onclick="filter('CERRADO',getCheckedValue(document.forms[0].level))" <%=(sStatus.equals("CERRADO") ? "CHECKED" : "")%>>&nbsp;Closed</TD>
              <TD CLASS="textplain"><INPUT TYPE="radio" NAME="status" VALUE="CANCELADO" onclick="filter('CANCELADO',getCheckedValue(document.forms[0].level))" <%=(sStatus.equals("CANCELADO") ? "CHECKED" : "")%>>&nbsp;Cancelled
              <TD CLASS="textplain"><INPUT TYPE="radio" NAME="status" VALUE="SUSPENDIDO" onclick="filter('SUSPENDIDO',getCheckedValue(document.forms[0].level))" <%=(sStatus.equals("SUSPENDIDO") ? "CHECKED" : "")%>>&nbsp;Suspended</TD>
            </TR>
            <TR>
              <TD CLASS="formstrong">Level</TD>
              <TD CLASS="textplain"><INPUT TYPE="radio" NAME="level" VALUE="" onclick="filter(getCheckedValue(document.forms[0].status),'')" <%=(sLevel.length()==0 ? "CHECKED" : "")%>>&nbsp;All</TD>
              <TD CLASS="textplain" COLSPAN="2"><INPUT TYPE="radio" NAME="level" VALUE="1" onclick="filter(getCheckedValue(document.forms[0].status),'1')" <%=(sLevel.equals("1") ? "CHECKED" : "")%>>&nbsp;Only first level</TD>
              <TD COLSPAN="2"></TD>
            </TR>
          </TR>
        </TD>
      </TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0" SUMMARY=""Project Listing>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD COLSPAN="8" ALIGN="left">
<%
          if (iSkip>0)
            out.write("            <A HREF=\"project_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
          if (!oProjects.eof())
            out.write("            <A HREF=\"project_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" WIDTH="18" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" WIDTH="70" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(1);" oncontextmenu="return false;" ><IMG SRC="../skins/<%=sSkin + (iOrderBy==1 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Level</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(320f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" WIDTH="96" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(7);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==7 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by start date"></A>&nbsp;<B>Start</B></TD>
          <TD CLASS="tableheader" WIDTH="80" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(8);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==8 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>End</B></TD>
          <TD CLASS="tableheader" WIDTH="80" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(8);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==9 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by cost"></A>&nbsp;<B>Cost</B></TD>
          <TD CLASS="tableheader" WIDTH="160" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(12);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==12 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Belong to</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%
	  int iProjLv;
	  String sProjId, sProjNm, sProjSt, sProjEn, sProjCt, sProjCo, sProjSs, sSsImg;
	  
	  for (int i=0; i<iProjectCount; i++) {
            iProjLv = oProjects.getInt(0,i);
            sProjId = oProjects.getString(2,i);
            sProjNm = oProjects.getString(3,i);
            sProjSt = oProjects.getDateShort(6,i);
            sProjEn = oProjects.getDateShort(7,i);
            if (oProjects.isNull(8,i)) {
              sProjCt = "";
            } else {
              fTotalCost += oProjects.getFloat(8,i);
              sProjCt = String.valueOf(oProjects.getFloat(8,i));
            }
            if (!oProjects.isNull(10,i))
              sProjCo = oProjects.getStringNull(12,i,"");
            else if (!oProjects.isNull(9,i))
              sProjCo = oProjects.getStringNull(11,i,"");
					  else
					  	sProjCo = "";                        
%>            
            <TR HEIGHT="14">
              <TD ALIGN="center" CLASS="strip<%=((i%2)+1)%>">
<%  if (oProjects.isNull(13,i)) {
  	  sProjSs = "";
  	  sSsImg  = "../images/images/spacer.gif";
    } else {
      sProjSs = oProjects.getString(13,i);
      if (sProjSs.equals("ABIERTO"))
        sSsImg = "../skins/"+sSkin+"/nav/folderopen_16x16.gif";
      else if (sProjSs.equals("CERRADO"))
        sSsImg = "../skins/"+sSkin+"/nav/folderclosed_16x16.gif";
      else if (sProjSs.equals("SUSPENDIDO"))
        sSsImg = "../skins/"+sSkin+"/nav/folderorange_16x16.gif";
      else if (sProjSs.equals("CANCELADO"))
        sSsImg = "../skins/"+sSkin+"/nav/folderred_16x16.gif";
      else
        sSsImg = "../images/images/spacer.gif";
    }
%>              <IMG SRC="<% out.write(sSsImg); %>" WIDTH="16" HEIGHT="16" BORDER="0" ALT="<% out.write(nullif((String)oStatusTrMap.get(sProjSs),sProjSs)); %>">
              </TD>
              <TD ALIGN="center" CLASS="strip<%=((i%2)+1)%>">&nbsp;<%=iProjLv%></TD>
              <TD CLASS="strip<%=((i%2)+1)%>"><A HREF="javascript:listSubprojects('<%=sProjId%>')" CLASS="linksmall">[+]</A>&nbsp;<A HREF="#" onclick="modifyProject('<%=sProjId%>','<%=sProjNm%>')" oncontextmenu="jsProjectId='<%=sProjId%>'; jsProjectNm='<%=sProjNm%>'; return showRightMenu(event)" TITLE="Click Right Mouse Button for Context Menu"><%=sProjNm%></A></TD>
              <TD CLASS="strip<%=((i%2)+1)%>" NOWRAP>&nbsp;<%=sProjSt==null ? "" : sProjSt%></TD>
              <TD CLASS="strip<%=((i%2)+1)%>" NOWRAP>&nbsp;<%=sProjEn==null ? "" : sProjEn%></TD>
              <TD CLASS="strip<%=((i%2)+1)%>">&nbsp;<%=sProjEn==null ? "" : sProjCt%></TD>
              <TD CLASS="strip<%=((i%2)+1)%>">&nbsp;<%=sProjCo%></TD>
              <TD CLASS="strip<%=((i%2)+1)%>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="P<%=sProjId%>"></TD>
            </TR>
<%        } // next(i)
        if (fTotalCost>0f) { %>
            <TR HEIGHT="14">
              <TD COLSPAN="2"></TD>
              <TD COLSPAN="2" ALIGN="right" CLASS="textplain"><B>Total Cost</B>&nbsp;</TD>
              <TD CLASS="textplain"><%=String.valueOf(fTotalCost)%></TD>
              <TD COLSPAN="2"></TD>
            </TR>

<%      }
      if (sParent.length()>0) { %>
            <TR HEIGHT="14">
              <TD COLSPAN="2"></TD>
              <TD><A HREF="javascript:<%=(sGrandParent!=null ? "listSubprojects('"+sGrandParent+"')" : "filter('','1')")%>" CLASS="linksmall">[..]</A></TD>
              <TD COLSPAN="5"></TD>
            </TR>
<%      } %>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
		  <TR>
		    <TD COLSPAN="8">
	        <TABLE BORDER="0" SUMMARY="Massive Update">
	          <TR>
	            <TD CLASS="textsmall">&nbsp;&nbsp;&nbsp;&nbsp;Change to&nbsp;Status&nbsp;</TD>
	            <TD>
	              <SELECT CLASS="combomini" NAME="sel_new_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>
	            </TD>
	            <TD>
	              <A HREF="javascript:updateProjects()" CLASS="linkplain">Change</A>
	            </TD>
		    	  </TR>
		    	</TABLE>
		    </TD>
		  </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <INPUT TYPE="hidden" NAME="is_standalone" VALUE="0">
    </FORM>

    <IFRAME name="addrIFrame" src="../common/blank.htm" width="0" height="0" border="0" frameborder="0"></IFRAME>
    <SCRIPT language="JavaScript" type="text/javascript">
      addMenuOption("Open","modifyProject(jsProjectId, jsProjectNm)",1);
      addMenuOption("Duplicate","clone(jsProjectId)",0);
      addMenuOption("Create subproject","createSubProject(jsProjectId, jsProjectNm)",0);
      addMenuSeparator();
      addMenuOption("New Duty","createDuty(jsProjectId)",0);
      addMenuOption("View Duties","listDuties(jsProjectId)",0);
      addMenuSeparator();
      addMenuOption("View Incident","listBugs(jsProjectId)",0);
    </SCRIPT>

</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>
