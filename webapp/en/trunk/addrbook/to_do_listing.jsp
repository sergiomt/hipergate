<%@ page import="java.util.HashMap,java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.workareas.WorkArea,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  // 01. Get browser language
  
  String sLanguage = getNavigatorLanguage(request);
  
  // **********************************************
  
  // 02. Get current skin

  String sSkin = getCookie(request, "skin", "default");
  
  // **********************************************

  // 03. Get WorkArea

  String gu_workarea = getCookie(request,"workarea","");
  String gu_user = getCookie(request, "userid", "");
  
  // **********************************************

  // Variables for client screen resolution

  String screen_width = request.getParameter("screen_width");

  int iScreenWidth;
  float fScreenRatio;

  // Screen resolution must be passed as a parameter
  // if it does not exist then 800x600 is assumed.

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;

  // **********************************************
    
  // Filter clauses (SQL WHERE)
        
  String sField = nullif(request.getParameter("field"));
  String sFind = nullif(request.getParameter("find"));
  String sTxStatus = nullif(request.getParameter("tx_status"), "PENDING");
  String sTpToDo = nullif(request.getParameter("tp_to_do"));  
  boolean bAllUsers = Boolean.valueOf(nullif(request.getParameter("all_users"), "false")).booleanValue();
  String sTypeStatus = "", sTypeLookUp = "";
 
  // **********************************************

  int iToDoCount = 0;
  DBSubset oToDos;        
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  // *******************************************************
  // Maximum number of rows to display and row to start with

  try {  
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "100"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;
    
  if (iSkip<0) iSkip = 0;

  // **********************************************
  // Type and status filter
  
  if (sTxStatus.length()>0)
    sTypeStatus = DB.tx_status + "='" + sTxStatus + "' AND ";
    
  // **********************************************
  // Order by column
  
  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  if (3==iOrderBy)
    sOrderBy += " DESC";
    
  // **********************************************

  JDCConnection oConn = null;  
  
  boolean bIsWrkAdmin = false;
  
  HashMap oPriorities = null, oTypes = null, oStatus = null;
  
  try {
    // Get a connection from pool

    oConn = GlobalDBBind.getConnection("todolisting");  

    sTypeLookUp = GlobalDBLang.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_to_do_lookup, gu_workarea, DB.tp_to_do, sLanguage);
    
    bIsWrkAdmin = WorkArea.isAdmin(oConn, gu_workarea, gu_user);

    oPriorities = GlobalDBLang.getLookUpMap((java.sql.Connection) oConn, DB.k_to_do_lookup, gu_workarea, "od_priority", sLanguage);

    oTypes = GlobalDBLang.getLookUpMap((java.sql.Connection) oConn, DB.k_to_do_lookup, gu_workarea, "tp_to_do", sLanguage);

    oStatus = GlobalDBLang.getLookUpMap((java.sql.Connection) oConn, DB.k_to_do_lookup, gu_workarea, "tx_status", sLanguage);
    
    if (sFind.length()==0 || sField.length()==0) {
      
      // If filter does not exist then return all rows up to maxrows limit

      oToDos = new DBSubset (DB.k_to_do + " t," + DB.k_users + " u", 
      			     "t." + DB.gu_to_do + ",t." + DB.tp_to_do + ",t." + DB.dt_created + ",t." + DB.dt_end + ",t." + DB.gu_user + ",t." + DB.od_priority + ",t." + DB.tl_to_do + ",t." + DB.tx_status + ",u." + DB.nm_user + ",u." + DB.tx_surname1 + ",u." + DB.tx_surname2,
      			     "t." + DB.gu_user + "=u." + DB.gu_user + " AND " + sTypeStatus + (sTpToDo.length()>0 ? "t." + DB.tp_to_do + "='" + sTpToDo + "' AND " : "") + "t." + DB.gu_workarea + "='" + gu_workarea + "' AND u." + (bIsWrkAdmin & bAllUsers ? DB.gu_workarea + "='" + gu_workarea + "'" : DB.gu_user + "='" + gu_user + "'") + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oToDos.setMaxRows(iMaxRows);

      iToDoCount = oToDos.load (oConn, iSkip);
    }
    else {

      oToDos = new DBSubset (DB.k_to_do + " t," + DB.k_users + " u",
      			     "t." + DB.gu_to_do + ",t." + DB.tp_to_do + ",t." + DB.dt_created + ",t." + DB.dt_end + ",t." + DB.gu_user + ",t." + DB.od_priority + ",t." + DB.tl_to_do + ",t." + DB.tx_status + ",u." + DB.nm_user + ",u." + DB.tx_surname1 + ",u." + DB.tx_surname2,
      			     "t." + DB.gu_user + "=u." + DB.gu_user + " AND " + sTypeStatus + (sTpToDo.length()>0 ? "t." + DB.tp_to_do + "='" + sTpToDo + "' AND " : "") + "t." + DB.gu_workarea+ "='" + gu_workarea + "' AND u." + (bIsWrkAdmin & bAllUsers ? DB.gu_workarea + "='" + gu_workarea : DB.gu_user + "='" + gu_user) + "' AND " + sField + " " + DBBind.Functions.ILIKE + " ? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oToDos.setMaxRows(iMaxRows);

      Object[] aFind = { "%" + sFind + "%" };      
      iToDoCount = oToDos.load (oConn, aFind, iSkip);
    }
    
    oConn.close("todolisting"); 
  }
  catch (SQLException e) {  
    oToDos = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("todolisting");
    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getMessage(), "");
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // Global variables for moving the clicked row to the context menu
        
        var jsToDoId;
        var jsToDoNm;
            
        <%
          // Write instance primary keys in a JavaScript Array
          // This Array is used when posting multiple elements
          // for deletion.
          
          out.write("var jsToDos = new Array(");
            
            for (int i=0; i<iToDoCount; i++) {
              if (i>0) out.write(","); 
                out.write("\"" + oToDos.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

        function getToDoStatus() {
          var frm = document.forms[0];
          
          if (frm.tx_status[0].checked)
            return "PENDING";
	  else
            return "";	              
        }
        
        // ----------------------------------------------------
        
        // 12. Create new todo
        	
	function createToDo() {	  
	  
	  self.open ("todo_edit.jsp?gu_workarea=<%=gu_workarea%>", null, "directories=no,toolbar=no,menubar=no,width=500,height=400");	  
	} // createToDo()

        // ----------------------------------------------------

	
	function deleteToDos() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure that you want to delete the selected tasks?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "to_do_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsToDos.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsToDos[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteToDos()

        // ----------------------------------------------------
	
	function finishToDos() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to finish the selected tasks?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "todo_done.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsToDos.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsToDos[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // finishToDos()
		
        // ----------------------------------------------------

        // 14. Modify ToDo

	function modifyToDo(id,nm) {
	  
	  self.open ("todo_edit.jsp?gu_workarea=<%=gu_workarea%>" + "&gu_to_do=" + id, null, "directories=no,toolbar=no,menubar=no,width=500,height=400");
	} // modifyToDo

        // ----------------------------------------------------

        // 15. Reload Page sorting by a field

	function sortBy(fld) {
	  
	  var frm = document.forms[0];

	  var all = <%=(bIsWrkAdmin ? "frm.all_users[0].checked ? 'true' : 'false'" : "false")%>;
	  
	  window.location = "to_do_listing.jsp?tp_to_do="  + getCombo(frm.sel_to_do) + "&all_users=" + all + "&tx_status=" + getToDoStatus() + "&skip=0&orderby=" + fld + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // sortBy		

        // ----------------------------------------------------

        // 16. Select All ToDos

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsToDos.length; c++)                        
            eval ("frm.elements['" + jsToDos[c] + "'].click()");
        } // selectAll()
       
        // ----------------------------------------------------

        // 17. Reload Page finding instances by a single field
	
	function findToDo() {
	  	  
	  var frm = document.forms[0];
	  var all = <%=(bIsWrkAdmin ? "frm.all_users[0].checked ? 'true' : 'false'" : "false")%>;

	  if (frm.find.value.length>0)
	    window.location = "to_do_listing.jsp?tp_to_do="  + getCombo(frm.sel_to_do) + "&all_users=" + all + "&tx_status=" + getToDoStatus() + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&screen_width=" + String(screen.width);
	  else
	    window.location = "to_do_listing.jsp?tp_to_do="  + getCombo(frm.sel_to_do) + "&all_users=" + all + "&tx_status=" + getToDoStatus() + "&skip=0&orderby=<%=sOrderBy%>" + "&screen_width=" + String(screen.width);
	  
	} // findToDo()
      
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	
	  setCookie ("maxrows", "<%=iMaxRows%>");

	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	  setCombo(document.forms[0].sel_to_do, "<%=sTpToDo%>");
	  
	} // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Task List</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Tasks</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <!-- 19. Top Menu -->
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD ALIGN="left">
          <TABLE BORDER="0" CELLSPACING="0">
            <TR>             
              <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ACCESSKEY="N" ALT="New"></TD>
              <TD><A HREF="#" onclick="createToDo()" CLASS="linkplain">New</A></TD>
              <TD>&nbsp;&nbsp;<IMG SRC="../images/images/checkmark16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Finish"></TD>
              <TD><A HREF="#" onclick="finishToDos()" CLASS="linkplain">Finish</A></TD>
              <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" BORDER="0" ALT="Delete"></TD>
              <TD><A HREF="#" onclick="deleteToDos()" CLASS="linkplain">Delete</A></TD>
            </TR>
          </TABLE>
        </TD>
      <TR>
      <TR>
        <TD VALIGN="middle">
          <IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search">
          <SELECT NAME="sel_searched" CLASS="combomini">
            <OPTION VALUE="tl_to_do">Title</OPTION>
            <OPTION VALUE="tx_to_do">Text</OPTION>
          </SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="javascript:findToDo();" CLASS="linkplain" TITLE="Search">Search</A>	  
        &nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Search">
          <A HREF="javascript:document.forms[0].find.value=''; setCombo(document.forms[0].sel_to_do,''); findToDo();" CLASS="linkplain" TITLE="Discard Search">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
      </TR>
      <TR>
        <TD>
          <FONT CLASS="formplain">&nbsp;Show only</FONT>&nbsp;<SELECT CLASS="combomini" NAME="sel_to_do" onchange="findToDo()"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT>
	  &nbsp;&nbsp;&nbsp;&nbsp;
          <INPUT TYPE="radio" NAME="tx_status" VALUE="PENDING" onclick="findToDo()" <% if (sTxStatus.equals("PENDING")) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">Pending</FONT>
          <INPUT TYPE="radio" NAME="tx_status" VALUE="" onclick="findToDo()" <% if (!sTxStatus.equals("PENDING")) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">All</FONT>
	  &nbsp;&nbsp;&nbsp;
<% if (bIsWrkAdmin) { %>
          <INPUT TYPE="radio" NAME="all_users" VALUE="true" onclick="findToDo()" <% if (bAllUsers==true) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">All Users</FONT>
	  &nbsp;
          <INPUT TYPE="radio" NAME="all_users" VALUE="false" onclick="findToDo()" <% if (bAllUsers!=true) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">Only my Tasks</FONT>
<% } %>
        </TD>
      </TR>
      
      <TR><TD BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top Menu -->
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  // 20. Paint Next and Previous Links
    	  // tp_to_do=&all_users=false&tx_status=&skip=0&orderby=&screen_width=1024
    	  // sTpToDo,bAllUsers,sTxStatus
    
    	  if (iToDoCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"to_do_listing.jsp?tp-to_do=" + sTpToDo + "&all_users=" + bAllUsers + "&tx_status=" + sTxStatus + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oToDos.eof())
              out.write("            <A HREF=\"to_do_listing.jsp?tp-to_do=" + sTpToDo + "&all_users=" + bAllUsers + "&tx_status=" + sTxStatus + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iToDoCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(6);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==6 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by Priority"></A><B>Priority</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(8);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==8 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by Status"></A>&nbsp;<B>Status</B></TD>          
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by Start Date"></A>&nbsp;<B>Start</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by End Date"></A>&nbsp;<B>End</B></TD>          
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by Type"></A>&nbsp;<B>Type</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(7);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==7 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by Title"></A>&nbsp;<B>Title</B></TD>
<%	  if (bIsWrkAdmin && bAllUsers)
	    out.write("          <TD CLASS=\"tableheader\" BACKGROUND=\"../skins/" + sSkin + "/tablehead.gif\"><B>User</B></TD>\n");
%>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD></TR>
<%
	  String sStrip, sInstId, sType="", sDtStart="", sDtEnd="", sFullName="", sTitle="", sStatus="";
	  Object oPriority = null;

	  for (int i=0; i<iToDoCount; i++) {
            
            sInstId = oToDos.getString(0,i);
	    sType = oToDos.getStringNull(1,i,null);
            sDtStart= nullif(oToDos.getDateFormated(2,i,"yyyy-MM-dd"));
            sDtEnd  = nullif(oToDos.getDateFormated(3,i,"yyyy-MM-dd"));
            sTitle  = oToDos.getString(6,i);
            sStatus  = oToDos.getStringNull(7,i,null);
	    oPriority = oToDos.get(5,i);
	    	                 
	    sFullName = oToDos.getStringNull(8,i,"") + " " + oToDos.getStringNull(9,i,"") + " " + oToDos.getStringNull(10,i,"");

            sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="16">
              <TD CLASS="strip<% out.write (sStrip); %>"><% if (null!=oPriority) out.write((String) oPriorities.get(String.valueOf(oPriority))); %></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><% if (null!=sStatus) out.write((String) oStatus.get(sStatus)); %></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><% out.write(sDtStart); %></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><% out.write(sDtEnd); %></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><% if (null!=sType) out.write((String) oTypes.get(sType)); %></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" onclick="modifyToDo('<%=sInstId%>')"><%=sTitle%></A></TD>
<%          if (bIsWrkAdmin && bAllUsers)
	      out.write("              <TD CLASS=\"strip" + sStrip + "\">&nbsp;" + sFullName + "</TD>\n");
%>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<%=sInstId%>"></TD>
            </TR>
<%        } // next(i)
%>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>