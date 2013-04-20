<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");

  Integer id_domain = new Integer(getCookie(request,"domainid",""));
  String gu_workarea = getCookie(request,"workarea","");
  String id_user = getCookie (request, "userid", null);

  ACLUser oUser = new ACLUser(id_user);
  DBPersist oCntr = new DBPersist(DB.k_lu_countries,"Country");
  DBPersist oStte = new DBPersist(DB.k_lu_states,"State");
  ACLGroup oGrop = new ACLGroup();
  
  JDCConnection oConn = null;
  DBSubset oCalendars = null;
  int nCalendars = 0;
  String aScopes[] = null;
  boolean bIsGuest = true;
				      
  try {
    oConn = GlobalDBBind.getConnection("worktime_list");

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);

    if (isDomainAdmin(GlobalCacheClient, GlobalDBBind, request, response)) {
      oCalendars = new DBSubset(DB.k_working_calendar,
  				DB.gu_calendar+","+DB.nm_calendar+","+DB.dt_from+","+DB.dt_to+","+DB.gu_user+","+DB.gu_acl_group+","+DB.id_country+","+DB.id_state,
    				DB.id_domain+"=? ORDER BY 1", 50);
      nCalendars = oCalendars.load(oConn, new Object[]{id_domain});
    } else {
      oCalendars = new DBSubset(DB.k_working_calendar,
  				DB.gu_calendar+","+DB.nm_calendar+","+DB.dt_from+","+DB.dt_to+","+DB.gu_user+","+DB.gu_acl_group+","+DB.id_country+","+DB.id_state,
    				DB.id_domain+"=? AND "+DB.gu_workarea+"=? ORDER BY 2", 50);
      nCalendars = oCalendars.load(oConn, new Object[]{id_domain,gu_workarea});
    } // fi

    if (nCalendars>0) {
      aScopes = new String[nCalendars];
    }
    
    for (int c=0; c<nCalendars; c++) {
      if (!oCalendars.isNull(4,c)) {
        oUser.load(oConn, new Object[]{oCalendars.getString(4,c)});
        aScopes[c] = oUser.getFullName();
      } else if (!oCalendars.isNull(5,c)) {
        oGrop.load(oConn, new Object[]{oCalendars.getString(5,c)});
        aScopes[c] = oGrop.getStringNull(DB.nm_acl_group,"");
      } else if (!oCalendars.isNull(6,c) && !oCalendars.isNull(7,c)) {
        oStte.load(oConn, new Object[]{oCalendars.getString(7,c)});
        aScopes[c] = oStte.getStringNull(DB.nm_state,"");
      } else if (!oCalendars.isNull(6,c)) {
        oCntr.load(oConn, new Object[]{oCalendars.getString(6,c)});
        aScopes[c] = oCntr.getStringNull(DB.tr_+"country_"+sLanguage,"");
      } else {
        aScopes[c] = "";
      }
    } // next

    oConn.close("worktime_list");
  }
  catch (Exception e) {
    // Si algo peta 
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("worktime_list");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');

    var menuLayer,addrLayer;
    dynapi.onLoad(init);
    function init() {
 
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
        
        var jsCalendarId;
            
        <%
          
          out.write("var jsCalendars = new Array(");
            
            for (int i=0; i<nCalendars; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oCalendars.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
        %>

      // ------------------------------------------------------
      
      function createWorkTime() {
        window.open("workcalendar_edit.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea"), "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=500");
      }

      // ------------------------------------------------------
      
      function editWorkCalendar(gu) {
	      var frm = document.forms[0];
        window.open("workcalendar_edit.jsp?gu_calendar="+gu+"&id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&selected=" + frm.selected.value + "&subselected=" + frm.subselected.value, gu, "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=500");
      }


      function addNonWorkingTime(gu) {
        window.open("workcalendar_nonworkingtime_add.jsp?gu_calendar="+gu+"&id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea"), gu, "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=320");
      }

	    function editWorkingTime(gu) {
	      var frm = document.forms[0];
	      document.location = "workcalendar_setdays.jsp?gu_calendar=" + gu + "&id_domain=" + frm.id_domain.value + "&gu_workarea=" + frm.gu_workarea.value + "&selected=" + frm.selected.value + "&subselected=" + frm.subselected.value;
	    }

      // ------------------------------------------------------
      
      function deleteWorkTime() {
      	var frm = document.forms[0];
      	if (window.confirm("Are you sure that you want to delete the selected calendars?")) {
      	  frm.checkeditems.value = "";
      	  for (var c=0; c<jsCalendars.length; c++) {
      	    if (frm.elements[jsCalendars[c]].checked)
      	      frm.checkeditems.value += (frm.checkeditems.value.length==0 ? "" : ",") + jsCalendars[c];
      	  } // next
      	  if (frm.checkeditems.value.length>0)
					  frm.submit();
					  return true;      	  
      	} else {
      	  return false;
      	}
      } // deleteWorkTime

      // ------------------------------------------------------

    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Timetable listing</TITLE>
</HEAD>
  <BODY TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post" ACTION="workcalendar_delete.jsp">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Timetable listing</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
      <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE SUMMARY="Controls" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
<% if (bIsGuest) { %>      
        <TD COLSPAN="4"></TD>
<% } else { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createWorkTime()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="#" onclick="return deleteWorkTime()" CLASS="linkplain">Delete</A></TD>
<% } %>
      </TR>
      <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE SUMMARY="Data" CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Timetable name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>From</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>To</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Scope</B></TD>
	  <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
	</TR>
<% for (int c=0; c<nCalendars; c++) {
     String sStrip = String.valueOf((c%2)+1); %>
	<TR>
          <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="#" CLASS="linkplain" onclick="editWorkCalendar('<%=oCalendars.getString(0,c)%>')" oncontextmenu="jsCalendarId='<%=oCalendars.getString(0,c)%>'; return showRightMenu(event);"><%=oCalendars.getString(1,c)%></A></TD>
          <TD CLASS="strip<% out.write (sStrip); %>"><%=oCalendars.getDateShort(2,c)%></TD>
          <TD CLASS="strip<% out.write (sStrip); %>"><%=oCalendars.getDateShort(3,c)%></TD>
          <TD CLASS="strip<% out.write (sStrip); %>"><%=aScopes[c]%></TD>
	        <TD><INPUT TYPE="checkbox" NAME="<%=oCalendars.getString(0,c)%>" VALUE="1"></TD>
	</TR>
<% } // next %>	
    </FORM>
    <SCRIPT TYPE="text/javascript">
      <!--
      addMenuOption("Open","editWorkCalendar(jsCalendarId)",1);
      addMenuOption("Clone","clone(jsCalendarId)",0);
      addMenuOption("Edit Days","editWorkingTime(jsCalendarId)",0);
      addMenuOption("Add Holidays","addNonWorkingTime(jsCalendarId)",0);
      //-->
    </SCRIPT>
  </BODY>
   
</HTML>