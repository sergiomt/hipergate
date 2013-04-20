<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/projtrack.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%

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

  int iQryMode;
  String sSkin = getCookie(request, "skin", "xp");
  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");

  String sLanguage = getNavigatorLanguage(request);

  String sWhere = nullif(request.getParameter("where"));
  String sResource = nullif(request.getParameter("nm_resource"));
  
  String sStatusLookUp   = null;
  String sPriorityLookUp = null;
  String sResourceLookUp = null;
  
  HashMap oResourceMap = null;
  
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  JDCConnection oCon1 = null;  
  String sLastProj = "";
  Object oPriority;
  int iRowCount = 0;
  String sTables;
  String sFields;
  String sJoin = "";   
  DBSubset oDuties = null;

  Project oPrj = new Project();
  DBSubset oTopLevel = new DBSubset(DB.k_projects, DB.gu_project + "," + DB.nm_project, DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_parent + " IS NULL ORDER BY " + DB.nm_project, 10);
  DBSubset oPrjChlds = null;
  int iPrjChlds = 0;
  String sProjCombo = null;
  
  if (nullif(request.getParameter("qrymode")).length()==0)
    iQryMode = 1;
  else
    iQryMode = Integer.parseInt(request.getParameter("qrymode"));

  boolean bIsAdmin = true;
  boolean bIsGuest = true;

  try {

    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
       
    oCon1 = GlobalDBBind.getConnection("duty_list");
  
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.tx_status, sLanguage);
    sPriorityLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.od_priority, sLanguage);
    sResourceLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.nm_resource, sLanguage);

    oResourceMap = new HashMap();

    String C = DBBind.Functions.CONCAT;
    String N = DBBind.Functions.ISNULL;
    String sSQL;
    
    if (oCon1.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
      sSQL = "(SELECT " + DB.vl_lookup + "," + DB.tr_ + sLanguage + " FROM " + DB.k_duties_lookup +
                     " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=?) " +
    		     " UNION (SELECT " + DB.tx_nickname + " AS " + DB.vl_lookup + ",CONCAT(COALESCE(" + DB.nm_user + ",''),' ',COALESCE(" + DB.tx_surname1 + ",''),' ',COALESCE(" + DB.tx_surname2 + ",'')) AS " + DB.tr_ + sLanguage + " FROM " + DB.k_users +
    		     " WHERE " + DB.gu_user + " IN (SELECT " + DB.vl_lookup + " FROM " + DB.k_duties_lookup + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=?))";
    else
      sSQL = "(SELECT " + DB.vl_lookup + "," + DB.tr_ + sLanguage + " FROM " + DB.k_duties_lookup +
                     " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=?) " +
    		     " UNION (SELECT " + DB.tx_nickname + " AS " + DB.vl_lookup + "," + N + "(" + DB.nm_user + ",'')" + C + "' '" + C + N + "(" + DB.tx_surname1 + ",'')" + C + "' '" + C + N + "(" + DB.tx_surname2 + ",'') AS " + DB.tr_ + sLanguage + " FROM " + DB.k_users +
    		     " WHERE " + DB.gu_user + " IN (SELECT " + DB.vl_lookup + " FROM " + DB.k_duties_lookup + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=?))";

    PreparedStatement oStmt = oCon1.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sWorkArea);
    oStmt.setString(2, DB.nm_resource);
    oStmt.setString(3, sWorkArea);
    oStmt.setString(4, DB.nm_resource);
    ResultSet oRSet = oStmt.executeQuery();
    while (oRSet.next()) {
      oResourceMap.put(oRSet.getObject(1), oRSet.getObject(2));
    } // wend    
    oRSet.close();
    oStmt.close();
    oRSet = null;
    oStmt = null;

    sProjCombo =  getHTMLSelectProject(oCon1, sWorkArea);
          
    // Si la clausula Where contiene el campo nm_resource
    // cambiar las queries para que hagan búsquedas por persona
    
    if ((sWhere.indexOf("nm_resource")>0 && iQryMode!=4) || iQryMode==3) {
      sTables = DB.v_duty_resource + " b";
      sFields = "b.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.tx_status,b.nm_resource,b.pr_cost,b.dt_end,b.dt_scheduled,b.pct_complete,b.de_duty";
      sJoin = "(b.gu_owner='" + sWorkArea + "') ";
    }
    else if (iQryMode==2) {
      sTables = DB.v_duty_project + " b, " + DB.k_duties_lookup + " l";
      sFields = "b.nm_project,l.tr_" + sLanguage + ",b.gu_duty,b.nm_duty,b.dt_start,b.tx_status,NULL,b.pr_cost,b.dt_end,b.dt_scheduled,b.pct_complete,b.de_duty";
      sJoin = "(b.gu_owner='" + sWorkArea + "' AND l.vl_lookup=" + DBBind.Functions.toChar ("b." + DB.od_priority, 255) + " AND l.gu_owner='" + sWorkArea + "' AND l.id_section='od_priority') ";
    }
    else if (iQryMode==4) {
      sTables = DB.v_duty_resource + " b, " + DB.k_duties_lookup + " l";
      sFields = "b.nm_project,l.tr_" + sLanguage + ",b.gu_duty,b.nm_duty,b.dt_start,b.tx_status,NULL,b.pr_cost,b.dt_end,b.dt_scheduled,b.pct_complete,b.de_duty";
      sJoin = "(b.gu_owner='" + sWorkArea + "' AND l.vl_lookup=" + DBBind.Functions.toChar ("b." + DB.od_priority, 255) + " AND l.gu_owner='" + sWorkArea + "' AND l.id_section='od_priority') ";
    }
    else {
      sTables = DB.v_duty_project + " b";
      sFields = "b.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.tx_status,NULL,b.pr_cost,b.dt_end,b.dt_scheduled,b.pct_complete,b.de_duty";
      sJoin = "(b.gu_owner='" + sWorkArea + "') ";
    }
        
    switch (iQryMode) {
      case 1:
        oDuties = new DBSubset(sTables, sFields, sJoin + sWhere + " ORDER BY 1", 100);
        break;
      case 3:
        oDuties = new DBSubset(sTables, sFields, sJoin + sWhere + " ORDER BY 7,1", 100);
        break;
      case 2:
      case 4:      
        oDuties = new DBSubset(sTables, sFields, sJoin + sWhere + " ORDER BY 2", 100);
        break;
    } // end switch()

    iRowCount = oDuties.load(oCon1);    
              
    oCon1.close("duty_list");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("duty_list");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
          
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  if (null==oCon1) return;
  oCon1=null;
%>
<HTML LANG="<%=sLanguage%>">
  <HEAD>
    <TITLE>hipergate :: Duties by project</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript">
      <!--

      // ------------------------------------------------------

      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_duties_lookup&id_language=" + getUserLanguage() + "&id_section=nm_resource&tp_control=2&nm_control=sel_new_resource&nm_coding=nm_resource", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------
            
      function editDuty(guDuty) {
        window.open("duty_edit.jsp?gu_duty=" + guDuty, "editduty", "width=780,height=" + (screen.height<=600 ? "520" : "640"));
      }

      // ------------------------------------------------------
      
      function deleteDuties() {
        var frm = document.forms[0];
        if (confirm("Are you sure you want to delete selected duties?")) {
          frm.action = "dutyedit_delete.jsp";
          frm.submit();
        } // fi(confirm)
      } // deleteDuties()

      // ------------------------------------------------------

      function updateDuties() {

	      var offset = 0;
    	  var frm = document.forms[0];
    	  var chi = frm.checkeditems;
    	  	  
    	  if (frm.sel_new_status.selectedIndex<=0 && frm.sel_new_priority.selectedIndex<=0 && frm.sel_new_completed.selectedIndex<=0 && frm.sel_new_resource.selectedIndex<=0) {
    	    alert ("An attribute to be updated must be selected");
    	    return false;
    	  }

    	  if (window.confirm("Are you sure that you want to update the selected duty?")) {

	        chi.value = "";
	        frm.action = "dutyedit_update.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");

	        for (var i=0;i<<%=String.valueOf(iRowCount)%>; i++) {
            while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += frm.elements[offset].value + ",";
              offset++;
	        } // next()

	        if (chi.value.length>0) {
	          chi.value = chi.value.substr(0,chi.value.length-1);
            frm.nm_resource.value = (getCombo(frm.sel_new_resource)==null ? "" : getCombo(frm.sel_new_resource));
            frm.submit();
          } // fi(chi!="")
        } // fi (confirm)
      } // updateDuties()

      // ------------------------------------------------------

      function queryDuties() {
        var frm = document.forms[0];
        
        if (frm.qrymode[3].checked) {
          frm.where.value = " AND ((b.nm_resource = '" + getCookie ("userid") + "' OR b.nm_resource IN (SELECT tx_nickname FROM k_users where gu_user = '" +  frm.nm_resource.value + "')) ";
          
          if (frm.sel_status.selectedIndex>0)
            frm.where.value += " AND b.tx_status = '" + getCombo(frm.sel_status) + "'";

<%        if (iQryMode!=4) { %>
          if (frm.sel_priority.selectedIndex>0)
            frm.where.value += " AND b.od_priority = " + getCombo(frm.sel_priority);
<% } %>
          if (frm.sel_project.selectedIndex>0)
            frm.where.value += " AND b.gu_project = '" + getCombo(frm.sel_project) + "'";
             
          frm.where.value += ") "; 
        }
	else {
	
          if (frm.sel_resource.selectedIndex>0) {
            frm.qrymode[2].checked = true;
            frm.sel_project.selectedIndex=0;
          }
          
	  frm.where.value = "";

          if (frm.sel_status.selectedIndex>0)	
	    frm.where.value += (frm.where.value.length==0 ? " AND (" : " AND ") + " b.tx_status = '" + getCombo(frm.sel_status) + "'";

<%        if (iQryMode!=4) { %>
          if (frm.sel_priority.selectedIndex>0)	
	    frm.where.value += (frm.where.value.length==0 ? " AND (" : " AND ") + " b.od_priority = " + getCombo(frm.sel_priority);
<% } %>
          if (frm.sel_project.selectedIndex>0)
            frm.where.value +=  (frm.where.value.length==0 ? " AND (" : " AND ") + " b.gu_project = '" + getCombo(frm.sel_project) + "'";

          if (frm.sel_resource.selectedIndex>0)	{
	          frm.nm_resource.value = getCombo(frm.sel_resource);
	          frm.where.value += (frm.where.value.length==0 ? " AND (" : " AND ") + " (b.nm_resource = '" + frm.nm_resource.value + "' OR b.nm_resource IN (SELECT tx_nickname FROM k_users where gu_user = '" +  frm.nm_resource.value + "') ) ";
	        }

	        if (frm.where.value.length>0)
	          frm.where.value += ")";	  
	        }
	          
        frm.submit();
      }

      // ----------------------------------------------------

      function skipChars (str, idx, c) {
        while (idx<str.length) {        
          if (str.charCodeAt(idx)==c)
            idx++;
          else
            break;
        } // wend
        
        return idx;
      } // skipChars

      // ----------------------------------------------------
      
      function parseColumn (colname, type) {
      	var whr = document.forms[0].where.value;
      	var idx = whr.indexOf(colname);
      	var idz;
      	
      	if (idx<0)
      	  return null;
      	else {
      	  idx += colname.length;
      	  idx = skipChars(whr, idx, 32);
      	  idx = skipChars(whr, idx, 61);
      	  idx = skipChars(whr, idx, 32);
      	  
      	  if (type=="varchar") {
      	    idx++;
      	    idz = whr.indexOf("'", idx);
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

      	col = parseColumn("gu_project", "varchar");
      	if (null!=col) setCombo(frm.sel_project, col);
      	
      	col = parseColumn("tx_status", "varchar");
      	if (null!=col) setCombo(frm.sel_status, col);
      
      	col = parseColumn("nm_resource", "varchar");
      	if (null!=col) {
      	  frm.nm_resource.value =  col;
          setCombo(frm.sel_resource, col);
        }
	
        var copyOption = new Array();
        var optCount = <%=(iQryMode!=4 ? "frm.sel_priority.options.length" : "0")%>;

        for (var i=0; i<optCount; i++)
          copyOption[i] = new Array(frm.sel_priority.options[i].value, frm.sel_priority.options[i].text);

   	    copyOption.sort(function(a,b) { return (a[0]>b[0] ? 1 : (a[0]<b[0] ? -1 : 0)); });

<%	if (iQryMode!=4) out.write("clearCombo (frm.sel_priority);\n"); %>
      	
        for (var i=0; i<copyOption.length; i++)
          if (copyOption[i][1].length==0)
            comboPush (frm.sel_priority, "", "", false, false)		
          else
            comboPush (frm.sel_priority, copyOption[i][0] + " - " + copyOption[i][1], copyOption[i][0], false, false)		

	      col = parseColumn("od_priority", "smallint");
	      if (null!=col) setCombo(frm.sel_priority, col);

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

      } // setCombos      

      //-->
    </SCRIPT>
  </HEAD>
  <BODY  TOPMARGIN="0" MARGINHEIGHT="0" onload="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM NAME="frmDuties" METHOD="POST" ACTION="duty_list.jsp?selected=<%=nullif(request.getParameter("selected"),"4")%>&subselected=<%=nullif(request.getParameter("subselected"),"1")%>">
    <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
    <INPUT TYPE="hidden" NAME="nu_duties" VALUE="<%=iRowCount%>">
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=nullif(request.getParameter("selected"),"4")%>">
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=nullif(request.getParameter("subselected"),"1")%>">
    <INPUT TYPE="hidden" NAME="checkeditems" VALUE="">
    
    <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Duties by project</FONT></TD></TR></TABLE>
    <% if (iQryMode!=4) { %>
    <TABLE SUMMARY="Search Options" BORDER="0">
      <TR>
        <TD ALIGN="left"><INPUT TYPE="radio" NAME="qrymode" VALUE="1" <%=(iQryMode==1 ? "CHECKED" : "")%>>&nbsp;<FONT CLASS="textplain">View duties per project</FONT></TD>
        <TD ALIGN="left"><INPUT TYPE="radio" NAME="qrymode" VALUE="2" <%=(iQryMode==2 ? "CHECKED" : "")%>>&nbsp;<FONT CLASS="textplain">View duties per priority</FONT></TD>
	<TD ROWSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="20" HEIGHT="1" BORDER="0"></TD>
      </TR>
      <TR>        
        <TD ALIGN="left"><INPUT TYPE="radio" NAME="qrymode" VALUE="3" <%=((iQryMode==3 && !sResource.equals(sUserId)) ? "CHECKED" : "")%> onclick="document.forms[0].nm_resource=getCombo(sel_resource)">&nbsp;<FONT CLASS="textplain">View duties per person</FONT></TD>
        <TD ALIGN="left"><INPUT TYPE="radio" NAME="qrymode" VALUE="3" <%=((iQryMode==3 &&  sResource.equals(sUserId)) ? "CHECKED" : "")%> onclick="document.forms[0].sel_resource.selectedIndex=0; document.forms[0].nm_resource.value=getCookie('userid');">&nbsp;<FONT CLASS="textplain">View My Duties</FONT></TD>
      </TR>
    </TABLE>
    <TABLE>
      <TR>
        <TD>
          <FONT CLASS="textplain">Status:</FONT>
        </TD>
        <TD ALIGN="right">
          <SELECT CLASS="combomini" NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>
        </TD>
        <TD>
          <FONT CLASS="textplain">Priority:</FONT>
        </TD>
        <TD>
          <SELECT CLASS="combomini" NAME="sel_priority"><OPTION VALUE=""></OPTION><%=sPriorityLookUp%></SELECT>
        </TD>
      </TR>
      <TR>
        <TD>
          <FONT CLASS="textplain">Project:</FONT>
        </TD>
        <TD ALIGN="right">
          <SELECT CLASS="combomini" NAME="sel_project"><OPTION VALUE=""></OPTION><%=sProjCombo%></SELECT>
	</TD>
        <TD>
          <FONT CLASS="textplain">Assigned to:</FONT>
        </TD>
        <TD>
          <INPUT TYPE="hidden" NAME="nm_resource" VALUE="<%=sResource%>"><SELECT CLASS="combomini" NAME="sel_resource"><OPTION VALUE=""></OPTION><%=sResourceLookUp%></SELECT>
        </TD>
      </TR>
      <TR>
        <TD COLSPAN="4" ALIGN="right">
          <IMG SRC="../images/images/search16x16.gif" BORDER="0">&nbsp;<A HREF="javascript:queryDuties()" CLASS="linkplain">Search</A>&nbsp;&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/undosearch16x16.gif" BORDER="0">&nbsp;<A HREF="duty_list.jsp?selected=4&subselected=1" CLASS="linkplain">Undo Search</A>
        </TD>
      </TR>
    </TABLE>
    <%
    }
    else
      out.write("    <INPUT TYPE=\"hidden\" NAME=\"qrymode\" VALUE=\"4\">");
      String nCols = (3==iQryMode ? "9" : "8");
    %>
    <TABLE SUMMARY="Duty List" CELLSPACING="0" CELLPADDING="2">      
      <TR><TD COLSPAN="<%=nCols%>" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD COLSPAN="<%=nCols%>" ALIGN="left">
          <IMG SRC="../images/images/new16x16.gif" BORDER="0">&nbsp;
<% if (bIsGuest) { %>
          <A HREF="#" onClick="alert ('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New Duty</A>
<% } else { %>
          <A HREF="#" onClick="window.open('duty_new.jsp', 'newduty', 'menubar=no,toolbar=no,width=780,height=' + (screen.height<=600 ? '520' : '640'))" CLASS="linkplain">New Duty</A>
<% } %>
          &nbsp;&nbsp;&nbsp;&nbsp;
          <IMG SRC="../images/images/refresh.gif" BORDER="0">&nbsp;<A HREF="#" onClick="document.forms[0].submit()" CLASS="linkplain">Update</A>
	  &nbsp;&nbsp;&nbsp;&nbsp;
          <IMG SRC="../images/images/papelera.gif" BORDER="0">&nbsp;
<% if (bIsGuest) { %>
          <A HREF="#" onClick="alert ('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Delete selected duties</A>
<% } else { %>
          <A HREF="javascript:deleteDuties()" CLASS="linkplain">Delete selected duties</A>
<% } %>
        </TD>
      </TR>
<% if (bIsAdmin) { %>
      <TR>
        <TD COLSPAN="<%=nCols%>" ALIGN="left">
          <IMG SRC="../images/images/excel16.gif" BORDER="0">&nbsp;
          <A HREF="prj_todo_xls.jsp" TARGET="_blank" CLASS="linkplain">List of open duties</A>
        </TD>
      </TR>
<% } %>
      <TR><TD COLSPAN="<%=nCols%>" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <%
      for (int r=0; r<iRowCount; r++) {
        switch (iQryMode) {
          case 1:
            if (!sLastProj.equals(oDuties.getString(0,r))) {
              sLastProj = oDuties.getString(0,r);        
              out.write("      <TR CLASS=\"stripheader\">\n");
              out.write("        <TD COLSPAN=\""+nCols+"\"><FONT CLASS=\"forminvstrong\">" + sLastProj + "</FONT></TD>\n");
              out.write("      </TR>\n");%>
		  <TR>
		    <TD CLASS="textstrong">Subject</TD>
		    <TD CLASS="textstrong">Start</TD>
		    <TD CLASS="textstrong">End</TD>
		    <TD CLASS="textstrong">Status</TD>
		    <TD CLASS="textstrong">Completed</TD>
		    <TD CLASS="textstrong">Priority</TD>
		    <TD CLASS="textstrong">Cost</TD>
		    <TD></TD>
		  </TR>

<%          } // fi (sLastProj!=k_duties.gu_project)
	          break;
	        case 2:
	        case 4:
	          oPriority = oDuties.get(1,r);
	          if (null!=oPriority) {
              if (!sLastProj.equals(oPriority.toString())) {
                sLastProj = oDuties.get(1,r).toString();        
                out.write("      <TR CLASS=\"stripheader\">\n");
                out.write("        <TD COLSPAN=\""+nCols+"\"><FONT CLASS=\"forminvstrong\">Priority&nbsp;" + sLastProj + "</FONT></TD>\n");
                out.write("      </TR>\n");%>
		  <TR>
		    <TD CLASS="textstrong">Subject</TD>
		    <TD CLASS="textstrong">Start</TD>
		    <TD CLASS="textstrong">End</TD>
		    <TD CLASS="textstrong">Status</TD>
		    <TD CLASS="textstrong">Completed</TD>
		    <TD CLASS="textstrong">Priority</TD>
		    <TD CLASS="textstrong">Cost</TD>
		    <TD></TD>
		  </TR>
<%            } // fi (sLastProj!=k_duties.od_priority)
            }
            break;
          case 3:
            if (!sLastProj.equals(oDuties.getStringNull(6,r,"SIN ASIGNAR"))) {
              sLastProj = oDuties.getStringNull(6,r,"SIN ASIGNAR");
              out.write("      <TR CLASS=\"stripheader\">\n");
              out.write("        <TD COLSPAN=\""+nCols+"\"><FONT CLASS=\"forminvstrong\">" + nullif((String)oResourceMap.get(sLastProj), "SIN ASIGNAR") + "</FONT></TD>\n");
              out.write("      </TR>\n");%>
		  <TR>
		    <TD CLASS="textstrong">Project</TD>
		    <TD CLASS="textstrong">Subject</TD>
		    <TD CLASS="textstrong">Start</TD>
		    <TD CLASS="textstrong">End</TD>
		    <TD CLASS="textstrong">Status</TD>
		    <TD CLASS="textstrong">Completed</TD>
		    <TD CLASS="textstrong">Priority</TD>
		    <TD CLASS="textstrong">Cost</TD>
		    <TD></TD>
		  </TR>              
<%          } // fi (sLastProj!=k_x_duty_resource.nm_resource)          
            break;          
        } 
      %>

      <TR CLASS="strip<%= (r%2==0 ? "1" : "2") %>">
<% if (3==iQryMode) { %>
        <TD><FONT CLASS="textsmall"><%=oDuties.getString(0,r)%></FONT></TD>
<% } %>
        <TD><A HREF="#" onClick="javascript:editDuty('<%=oDuties.getString(2,r)%>')" CLASS="linkplain" TITLE="<%=Gadgets.left(oDuties.getStringNull(11,r,"").replace('\n',' ').replace('\r',' ').replace('"',' '),200)%>"><%=oDuties.getString(3,r)%></A></TD>
        <TD><FONT CLASS="textsmall"><% if(null!=oDuties.get(4,r)) out.write(oSimpleDate.format((Date) oDuties.get(4,r))); else if (null!=oDuties.get(9,r)) out.write(oSimpleDate.format((Date) oDuties.get(9,r))+ " *"); %></FONT></TD>	
        <TD><FONT CLASS="textsmall"><% if(null!=oDuties.get(8,r)) out.write(oSimpleDate.format((Date) oDuties.get(8,r))); %></FONT></TD>
        <TD><FONT CLASS="textsmall"><% if (null!=oDuties.get(5,r)) out.write(oDuties.getString(5,r)); %></FONT></TD>
        <TD><FONT CLASS="textsmall"><% if (null!=oDuties.get(10,r)) out.write(String.valueOf(oDuties.getShort(10,r))+"%"); %></FONT></TD>
        <%
          if (iQryMode==1) {
            out.write("        <TD CLASS=\"textsmall\">&nbsp;");
            if (null!=oDuties.get(1,r))
              out.write(String.valueOf(oDuties.getInt(1,r)));
            out.write("        </TD>");
          }
          else if (iQryMode==2 || iQryMode==4) {
            out.write("        <TD CLASS=\"textsmall\">" + oDuties.getString(0,r) + "</TD>");
          } else {
          	out.write("        <TD></TD>");
          }
        %>
        <TD><FONT CLASS="textsmall"><% if (!oDuties.isNull(7,r)) if(oDuties.getFloat(7,r)!=0) out.write(floor(oDuties.getFloat(7,r))); %></FONT></TD>
        <TD><INPUT TYPE="checkbox" NAME="chkbox<%=r%>" VALUE="<%=oDuties.getString(2,r)%>"></TD>        
      </TR>
      <% } // next (r) %>
<% if (!bIsGuest) {
     if (iRowCount>0) { %>
       <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
<%   } %>
      <TR>
        <TD COLSPAN="8">
	        <TABLE BORDER="0" SUMMARY="Massive Update">
	          <TR>
	            <TD CLASS="textsmall" COLSPAN="3">&nbsp;&nbsp;&nbsp;&nbsp;<B>Massive update options:</B></TD>
	          </TR>
	          <TR>
	            <TD CLASS="textsmall">&nbsp;&nbsp;&nbsp;&nbsp;Change to&nbsp;Status&nbsp;</TD>
	            <TD CLASS="textsmall">
	              <SELECT CLASS="combomini" NAME="sel_new_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;&nbsp;Priority<SELECT CLASS="combomini" NAME="sel_new_priority"><OPTION VALUE=""></OPTION><%=sPriorityLookUp%></SELECT>
	            </TD>
              <TD CLASS="textsmall">
                &nbsp;&nbsp;
                <FONT >Completed:&nbsp;<SELECT CLASS="combomini" NAME="sel_new_completed"><OPTION VALUE=""></OPTION><% for (int c=0;c<=100;c+=10) out.write("<OPTION VALUE=\""+String.valueOf(c)+"\">"+String.valueOf(c)+"%</OPTION>"); %></SELECT>
	            </TD>
	          </TR>
	          <TR>
	            <TD CLASS="textsmall">
	              &nbsp;&nbsp;&nbsp;&nbsp;Assign to &nbsp;
	            </TD>
	            <TD>
	              <SELECT CLASS="combomini" NAME="sel_new_resource" onchange="setCombo(document.forms[0].sel_resource,this.options[this.selectedIndex].value);document.forms[0].nm_resource.value=this.options[this.selectedIndex].value;"><OPTION VALUE=""></OPTION><%=sResourceLookUp%></SELECT>
	              &nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Add resources"></A>
	            </TD>
	            <TD COLSPAN="2" ALIGN="right">
                <A HREF="javascript:updateDuties()" CLASS="linkplain">Change</A>
	            </TD>
	          </TR>
	        </TABLE>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
<% }  %>

    </TABLE>
    <BR>    
    <% if (sWhere.length()>0) {
      if (0==iRowCount)
        out.write("    <FONT CLASS=\"textplain\">No Duty was found matching the specified criteria.</FONT>");
      else if (1==iRowCount)
        out.write("    <FONT CLASS=\"textplain\">1 duty was found matching the specified criteria</FONT>");
      else
        out.write("    <FONT CLASS=\"textplain\">&nbsp;" + String.valueOf(iRowCount) + " duties that match the specified criteria</FONT>");
    }
    %>
  </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>