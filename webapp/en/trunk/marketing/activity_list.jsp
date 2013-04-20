<%@ page import="java.text.SimpleDateFormat,java.net.URLDecoder,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.QueryByForm" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%

/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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

  final String BASE_TABLE = "k_activities b";
  final String COLUMNS_LIST = "b."+DB.gu_activity+",b."+DB.gu_workarea+",b."+DB.dt_created+",b."+DB.tl_activity+",b."+DB.dt_modified+",b."+DB.gu_address+",b."+DB.gu_campaign+",b."+DB.gu_list+",b."+DB.gu_writer+",b."+DB.dt_start+",b."+DB.dt_end+",b."+DB.nu_capacity+",b."+DB.pr_sale+",b."+DB.pr_discount+",b."+DB.id_ref+",b."+DB.tx_dept+",b."+DB.de_activity+",b."+DB.tx_comments;

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm","");
  String gu_workarea = getCookie(request,"workarea","");

  String screen_width = nullif(request.getParameter("screen_width"), "1024");

  int iScreenWidth;

  if (screen_width.length()==0)
    iScreenWidth = 1024;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  float fScreenRatio = ((float) iScreenWidth) / 1024f;
  if (fScreenRatio<1) fScreenRatio=1;

  String sField = nullif(request.getParameter("field"), DB.tl_activity);
  String sFind = nullif(request.getParameter("find"));
  String sWhere = nullif(request.getParameter("where"));
  String sQuery = nullif(request.getParameter("query"));

  SimpleDateFormat oDtFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm");

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  // **********************************************

  int iActivitiesCount = 0;
  DBSubset oActivities;        
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  // 06. Maximum number of rows to display and row to start with

  try {  
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "10"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 100; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;
    
  if (iSkip<0) iSkip = 0;

  // **********************************************

  // 07. Order by column

  sOrderBy = nullif(request.getParameter("orderby"),"10");
  iOrderBy = Integer.parseInt(sOrderBy.indexOf(' ')>0 ? sOrderBy.substring(0,sOrderBy.indexOf(' ')) : sOrderBy);
   if (3==iOrderBy || 10==iOrderBy) sOrderBy = String.valueOf(iOrderBy)+" DESC";

  // **********************************************

  JDCConnection oConn = null;  
  QueryByForm oQBF;
  boolean bIsGuest = true;
  
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("activity_list");  
        
    if (sWhere.length()>0) {
      
      oQBF = new QueryByForm("file://" + sStorage + "qbf" + File.separator + request.getParameter("queryspec") + ".xml");
    
      oActivities = new DBSubset (oQBF.getBaseObject(), COLUMNS_LIST,
      				 "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      
      oActivities.setMaxRows(iMaxRows);
      iActivitiesCount = oActivities.load (oConn, iSkip);
    }
    
    else if (sFind.length()==0 || sField.length()==0) {
      
      // 10. If filter does not exist then return all rows up to maxrows limit

      oActivities = new DBSubset (BASE_TABLE, COLUMNS_LIST,
      				                   "b." + DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oActivities.setMaxRows(iMaxRows);
      iActivitiesCount = oActivities.load (oConn, iSkip);
    }
    else {

      // 11. Single field Filtered Listing

      oQBF = new QueryByForm("file://" + sStorage + "/qbf/" + request.getParameter("queryspec") + ".xml");
      oActivities = new DBSubset (BASE_TABLE, COLUMNS_LIST,
      				                   "(" + oQBF.getBaseFilter(request) + ") AND (" + sField + " " + DBBind.Functions.ILIKE + " ?)" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oActivities.setMaxRows(iMaxRows);

      Object[] aFind = { "%" + sFind + "%" };      
      iActivitiesCount = oActivities.load (oConn, aFind, iSkip);
    }
    
    oConn.close("activity_list"); 
  }
  catch (SQLException e) {  
    oActivities = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("activity_list");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');

    var menuLayer,addrLayer;
    dynapi.onLoad(init);
    function init() {
 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setHTML(rightMenuHTML);      
    }
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // Global variables for moving the clicked row to the context menu
        
        var jsActivityId;
        var jsActivityNm;
            
        <%          
          out.write("var jsActivities = new Array(");
            
            for (int i=0; i<iActivitiesCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oActivities.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

<% if (!bIsGuest) { %>
        
	      function createActivity() {	  
	        open ("activity_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "editactivity", "scrollbars=yes,directories=no,toolbar=no,menubar=no,width=700,height=670");	  
	      } // createActivity()

        // ----------------------------------------------------
	
	      function deleteActivities() {
	  
	        var offset = 0;
	        var frm = document.forms[0];
	        var chi = frm.checkeditems;
	  	  
	        if (window.confirm("Are you sure that you want to delete the selected activities?")) {
	  	  
	          chi.value = "";	  	  
	          frm.action = "activity_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	          for (var i=0;i<jsActivities.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	        if (frm.elements[offset].checked)
                chi.value += jsActivities[i] + ",";
                offset++;
	          } // next()
	    
	          if (chi.value.length>0) {
	            chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteActivities()
<% } %>	
        // ----------------------------------------------------

	      function modifyActivity(id) {
	        open ("activity_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" + "&gu_activity=" + id, "editactivity", "scrollbars=yes,directories=no,toolbar=no,menubar=no,width=700,height=670");
	      } // modifyActivity

        // ----------------------------------------------------

	      function showAttendants(id) {
	        open ("activity_audience.jsp?gu_activity=" + id, "editactivity", "scrollbars=yes,directories=no,toolbar=no,menubar=no,width=1000,height=700");
	      } // modifyActivity

        // ----------------------------------------------------

        // 15. Reload Page sorting by a field

	      function sortBy(fld) {
	  
	        var frm = document.forms[0];
	  
	          window.location = "activity_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&where=" + escape("<%=sWhere%>") + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	      } // sortBy		

        // ----------------------------------------------------

        // 16. Select All Activities

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsActivities.length; c++)                        
            eval ("frm.elements['" + jsActivities[c] + "'].click()");
        } // selectAll()
       
        // ----------------------------------------------------

        // 17. Reload Page finding instances by a single field
	
	      function findActivity() {
	  	  
	        var frm = document.forms[0];

			    if (hasForbiddenChars(frm.find.value)) {
			      alert ("String sought contains invalid characters");
				    frm.find.focus();
				    return false;
			    }
	  
	        if (frm.find.value.length>0)
	          window.location = "activity_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&queryspec=activities&skip=0&orderby=<%=sOrderBy%>&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	        else
	          window.location = "activity_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&queryspec=activities&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  
	  			return true;
	      } // findActivity()

        // ----------------------------------------------------

        var intervalId;
        var winclone;

        // This function is called every 100 miliseconds for testing
        // whether or not clone call has finished.
      
        function findCloned() {
        
          if (winclone.closed) {
            clearInterval(intervalId);
            document.forms[0].find.value = jsActivityNm;
            findActivity();
          }
        } // findCloned()
      
        function clone() {        
          // Open a clone window and wait for it to be closed
        
          winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=activity_clon&gu_instance=" + jsActivityId +"&opcode=CACY&classid=310",
                                  null, "directories=no,toolbar=no,menubar=no,width=320,height=200");                
          intervalId = setInterval ("findCloned()", 100);
        }	// clone()
      
        // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	    function setCombos() {
	      setCookie ("maxrows", "<%=iMaxRows%>");
	      setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	    } // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Activity List</TITLE>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Activity List</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <!-- 19. Top controls and filters -->
      <TABLE SUMMARY="Top controls and filters" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
<% if (bIsGuest) { %>      
        <TD COLSPAN="4"></TD>
<% } else { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createActivity()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="#" onclick="deleteActivities()" CLASS="linkplain">Delete</A></TD>
<% } %>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	        &nbsp;<A HREF="javascript:findActivity();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard search"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:document.forms[0].find.value='';findActivity();" CLASS="linkplain" TITLE="Discard search">Discard search</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top controls and filters -->
      <TABLE SUMMARY="Data" CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%    
    	  if (iActivitiesCount>0) {
            if (iSkip>0)
              out.write("            <A HREF=\"activity_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&queryspec=activities&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oActivities.eof())
              out.write("            <A HREF=\"activity_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&queryspec=activities&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iActivitiesCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>Title</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Creation</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(10);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==10 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>Start date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select All"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD></TR>
<%
	        String sActivityId, sActivityTl, sActivityDtCreated, sActivityDtStart, sStrip;

	        for (int i=0; i<iActivitiesCount; i++) {
            sActivityId = oActivities.getString(0,i);
            sActivityTl = oActivities.getStringNull(3,i,"");
            sActivityDtCreated = oActivities.getDateShort(2,i);
            if (oActivities.isNull(9,i))
              sActivityDtStart = "";
            else
              sActivityDtStart = oActivities.getDateFormated(9,i,oDtFmt);
            
            sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" oncontextmenu="jsActivityId='<%=sActivityId%>'; jsActivityNm='<%=sActivityTl.replace((char)39,'´')%>'; return showRightMenu(event);" onclick="modifyActivity('<%=sActivityId%>')" TITLE="Click right mouse button to show context menu"><%=sActivityTl%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sActivityDtCreated%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sActivityDtStart%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<% out.write (sActivityId); %>"></TD>
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
    <SCRIPT TYPE="text/javascript">
      <!--
      addMenuOption("Open","modifyActivity(jsActivityId)",1);
      addMenuOption("Clone","clone()",0);
      addMenuSeparator();
      addMenuOption("Show audience","showAttendants(jsActivityId)",1);	      
      //-->
    </SCRIPT>
    <!-- /RightMenuBody -->    
</BODY>
</HTML>