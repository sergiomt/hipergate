<%@ page import="java.util.HashMap,java.net.URLDecoder,java.io.File,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.debug.DebugFile,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.QueryByForm" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
/*
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm","");
  String gu_workarea = getCookie(request,"workarea","");
  String gu_user = getCookie(request,"userid","");

  String screen_width = request.getParameter("screen_width");

  int iScreenWidth;
  float fScreenRatio;

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);

  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;

  String sField = nullif(request.getParameter("field"));
  String sFind = nullif(request.getParameter("find"));
  String sType = nullif(request.getParameter("type"),"all");
  String sMine = nullif(request.getParameter("mine"),"no");

  String sGuAbsentism, sGuAlumni, sNmAlumni, sTxDate, sGuACourse, sNmACourse, sGuSubject, sNmSubject, sTpAbsentism, sStrip;

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  // **********************************************

  int iAbsentismCount = 0;
  DBSubset oAbsentisms = null;
  String sOrderBy;
  int iOrderBy;
  int iMaxRows;
  int iSkip;

  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "10"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }

  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));
  else
    iSkip = 0;

  if (iSkip<0) iSkip = 0;

  // **********************************************

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "4";

  if (sOrderBy.length()>0) {
    iOrderBy = Integer.parseInt(sOrderBy);
    if (4==iOrderBy) sOrderBy += " DESC";
  } else {
    iOrderBy = 0;
  }

  // **********************************************

  HashMap oAlumni  = new HashMap();
  HashMap oCourse  = new HashMap();
  HashMap oSubject = new HashMap();
  String sSQL;
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;
  QueryByForm oQBF;
  boolean bIsGuest = true;

  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("absentismlisting", true);

    if (sFind.length()==0 || sField.length()==0) {

      // If filter does not exist then show the last ones written by me

      oAbsentisms = new DBSubset (DB.k_absentisms,
			          "gu_absentism,gu_alumni,gu_writer,dt_from,gu_acourse,gu_subject,tp_absentism",
				  DB.gu_writer + "='" + gu_user + "' " + 
				  (sType.equals("all") ? "" : " AND tp_absentism='" + sType + "'") +
				  (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

      oAbsentisms.setMaxRows(iMaxRows);
      iAbsentismCount = oAbsentisms.load (oConn, iSkip);
    }
    else {

      if (sField.equals("nm_absentism")) {
        oAbsentisms = new DBSubset (DB.k_absentisms,
			            "gu_absentism,gu_alumni,gu_writer,dt_from,gu_acourse,gu_subject,tp_absentism",
			            "gu_alumni IN (SELECT "+DB.gu_contact+" FROM "+DB.k_contacts+" WHERE "+DB.gu_workarea+"=? AND ("+DB.tx_name+" " + DBBind.Functions.ILIKE + " ? OR "+DB.tx_surname+" " + DBBind.Functions.ILIKE + " ?)) " +
				    (sMine.equals("yes") ? " AND gu_writer='" + gu_user + "' " : "") + 
				    (sType.equals("all") ? "" : " AND tp_absentism='" + sType + "'") +
				    (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

        oAbsentisms.setMaxRows(iMaxRows);

        Object[] aFind = { gu_workarea,"%"+sFind+"%","%"+sFind+"%" };
        iAbsentismCount = oAbsentisms.load (oConn, aFind, iSkip);
      }
      else if (sField.equals("nm_acourse")) {
        oAbsentisms = new DBSubset (DB.k_absentisms,
			            "gu_absentism,gu_alumni,gu_writer,dt_from,gu_acourse,gu_subject,tp_absentism",
			            "gu_acourse IN (SELECT a."+DB.gu_acourse+" FROM "+DB.k_academic_courses+" a,"+DB.k_courses+" c WHERE a."+DB.gu_course+"=c."+DB.gu_course+" AND c."+DB.gu_workarea+"=? AND (a."+DB.nm_course+" " + DBBind.Functions.ILIKE + " ? OR a."+DB.id_course+" LIKE ? OR c."+DB.nm_course+" " + DBBind.Functions.ILIKE + " ? OR c."+DB.id_course+" LIKE ?)) " +
				    (sMine.equals("yes") ? " AND gu_writer='" + gu_user + "' " : "") + 
				    (sType.equals("all") ? "" : " AND tp_absentism='" + sType + "'") +
				    (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

        oAbsentisms.setMaxRows(iMaxRows);

        Object[] aFind = { gu_workarea,"%"+sFind+"%","%"+sFind+"%","%"+sFind+"%","%"+sFind+"%" };
        iAbsentismCount = oAbsentisms.load (oConn, aFind, iSkip);
      }
    }

    sSQL = "SELECT "+DB.id_course+","+DB.nm_course+","+DB.tx_start+","+DB.tx_end+" FROM "+DB.k_academic_courses+" WHERE "+DB.gu_acourse+"=?";
    if (DebugFile.trace) {
      DebugFile.writeln("<JSP:absents_listing.jsp Connection.prepareStatement("+sSQL+")");
    }
    oStmt = oConn.prepareStatement(sSQL);
    for (int a=0; a<iAbsentismCount; a++) {
      if (!oAbsentisms.isNull(4,a)) {
        sGuACourse = oAbsentisms.getString(4,a);
        
        if (!oCourse.containsKey(sGuACourse)) {
        
    	  if (DebugFile.trace) {
            DebugFile.writeln("<JSP:absents_listing.jsp PreparedStatement.setString(1,"+sGuACourse+")");
            DebugFile.writeln("<JSP:absents_listing.jsp PreparedStatement.executeQuery()");
          }
          oStmt.setString(1, sGuACourse);
          oRSet = oStmt.executeQuery();
          if (oRSet.next()) {
            sNmACourse = nullif(oRSet.getString(1),nullif(oRSet.getString(2),oRSet.getString(3)+"-"+oRSet.getString(4)));
            if (DebugFile.trace) DebugFile.writeln("<JSP:absents_listing.jsp caching course " + sNmACourse);
            oCourse.put(sGuACourse, sNmACourse);
          }
          oRSet.close();
          oRSet=null;
        }
      }
    } // next
    oStmt.close();
    oStmt=null;

    sSQL = "SELECT "+DB.nm_short+","+DB.nm_subject+" FROM "+DB.k_subjects+" WHERE "+DB.gu_subject+"=?";
    if (DebugFile.trace) {
      DebugFile.writeln("<JSP:absents_listing.jsp Connection.prepareStatement("+sSQL+")");
    }
    oStmt = oConn.prepareStatement(sSQL);
    for (int a=0; a<iAbsentismCount; a++) {
      if (!oAbsentisms.isNull(5,a)) {
        sGuSubject = oAbsentisms.getString(5,a);
        
        if (!oSubject.containsKey(sGuSubject)) {
        
    	  if (DebugFile.trace) {
            DebugFile.writeln("<JSP:absents_listing.jsp PreparedStatement.setString(1,"+sGuSubject+")");
            DebugFile.writeln("<JSP:absents_listing.jsp PreparedStatement.executeQuery()");
          }
          oStmt.setString(1, sGuSubject);
          oRSet = oStmt.executeQuery();
          if (oRSet.next()) {
            sNmSubject = nullif(oRSet.getString(1),nullif(oRSet.getString(2)));
            if (DebugFile.trace) DebugFile.writeln("<JSP:absents_listing.jsp caching subject " + sNmSubject);
            oSubject.put(sGuSubject, sNmSubject);
          }
          oRSet.close();
          oRSet=null;
        }
      }
    } // next
    oStmt.close();
    oStmt=null;

    sSQL = "SELECT "+DB.tx_name+","+DB.tx_surname+" FROM "+DB.k_contacts+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_contact+"=?";
    if (DebugFile.trace) {
      DebugFile.writeln("<JSP:absents_listing.jsp Connection.prepareStatement("+sSQL+")");
    }
    oStmt = oConn.prepareStatement(sSQL);
    for (int a=0; a<iAbsentismCount; a++) {
      if (!oAbsentisms.isNull(1,a)) {
        sGuAlumni = oAbsentisms.getString(1,a);
        
        if (!oAlumni.containsKey(sGuAlumni)) {
        
    	  if (DebugFile.trace) {
            DebugFile.writeln("<JSP:absents_listing.jsp PreparedStatement.setString(1,"+sGuAlumni+")");
            DebugFile.writeln("<JSP:absents_listing.jsp PreparedStatement.executeQuery()");
          }
          oStmt.setString(1, sGuAlumni);
          oRSet = oStmt.executeQuery();
          if (oRSet.next()) {
            sNmAlumni = nullif(oRSet.getString(1))+" "+nullif(oRSet.getString(2));
            if (DebugFile.trace) DebugFile.writeln("<JSP:absents_listing.jsp caching student " + sNmAlumni);
            oAlumni.put(sGuAlumni, sNmAlumni);
          }
          oRSet.close();
          oRSet=null;
        }
      }
    } // next
    oStmt.close();
    oStmt=null;

    oConn.close("absentismlisting");
  }
  catch (SQLException e) {
    oAbsentisms = null;
    if (oConn!=null) {
      if (oRSet!=null) {
        try { oRSet.close(); } catch (Exception ignore) {} 
      }
      if (oStmt!=null) {
        try { oStmt.close(); } catch (Exception ignore) {} 
      }
      if (!oConn.isClosed())
        oConn.close("absentismlisting");
    }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }

  if (null==oConn) return;
  oConn = null;
  
  sendUsageStats(request, "absents_listing"); 

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>

  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
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
  </SCRIPT>
  <SCRIPT SRC="../javascript/dynapi3/rightmenu.js" TYPE="text/javascript"></SCRIPT>
  <SCRIPT SRC="../javascript/dynapi3/floatdiv.js" TYPE="text/javascript"></SCRIPT>

  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // Global variables for moving the clicked row to the context menu

        var jsAbsentismId;

        <%
          // Write instance primary keys in a JavaScript Array
          // This Array is used when posting multiple elements
          // for deletion.

          out.write("var jsAbsentisms = new Array(");

            for (int i=0; i<iAbsentismCount; i++) {
              if (i>0) out.write(",");
              out.write("\"" + oAbsentisms.getString(0,i) + "\"");
            }

          out.write(");\n        ");
        %>

        // ----------------------------------------------------

        function showCalendar(ctrl) {       
          var dtnw = new Date();

          window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
        } // showCalendar()

        // ----------------------------------------------------
      
<% if (!bIsGuest) { %>

        // 12. Create new instance

	function createAbsentism() {

	  self.open ("absent_new_f.jsp", "newabsentism", "directories=no,toolbar=no,menubar=no,width=720,height=500");
	} // createAbsentism()

        // ----------------------------------------------------

        // 13. Delete checked absentisms

	function deleteAbsentisms() {

	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;

	  if (window.confirm("Are you sure that you want to delete selected absentisms?")) {

	    chi.value = "";
	    frm.action = "absentism_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");

	    for (var i=0;i<jsAbsentisms.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsAbsentisms[i] + ",";
              offset++;
	    } // next()

	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteAbsentisms()
<% } %>
        // ----------------------------------------------------

        // 14. Modify Absentism

	function modifyAbsentism(id) {

	  self.open ("absentism_edit.jsp?gu_workarea=<%=gu_workarea%>" + "&gu_absentism=" + id, "editabsentism", "directories=no,toolbar=no,menubar=no,width=500,height=400");
	} // modifyAbsentism

        // ----------------------------------------------------

        // 15. Reload Page sorting by a field

	function sortBy(fld) {

	  var frm = document.forms[0];

	  window.location = "absents_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // sortBy

        // ----------------------------------------------------

	      function showOnlyJustified(yn) {

	        var frm = document.forms[0];

	        window.location = "absents_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0<%=iOrderBy==0 ? "" : "&orderby="+String.valueOf(iOrderBy) %>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&type=" + yn + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	      } // showOnlyJustified

        // ----------------------------------------------------

        // 16. Select All Absentisms

        function selectAll() {

          var frm = document.forms[0];

          for (var c=0; c<jsAbsentisms.length; c++)
            eval ("frm.elements['" + jsAbsentisms[c] + "'].click()");
        } // selectAll()

        // ----------------------------------------------------

        // 17. Reload Page finding instances by a single field

	function findAbsentism() {

	  var frm = document.forms[0];

	  if (frm.find.value.length>0)
	    window.location = "absents_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0<%=iOrderBy==0 ? "" : "&orderby="+String.valueOf(iOrderBy) %>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  else
	    window.location = "absents_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0<%=iOrderBy==0 ? "" : "&orderby="+String.valueOf(iOrderBy) %>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);

	} // findAbsentism()

      // ----------------------------------------------------

      var intervalId;
      var winclone;

      // This function is called every 100 miliseconds for testing
      // whether or not clone call has finished.

      function findCloned() {

        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "nm_absentism");
          document.forms[0].find.value = jsAbsentismNm;
          findAbsentism();
        }
      } // findCloned()

      // 18. Clone an instance using an XML data structure definition

      function clone() {
        // Open a clone window and wait for it to be closed

        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=aabsentism_clon&gu_instance=" + jsAbsentismId +"&opcode=CACR&classid=61", null, "directories=no,toolbar=no,menubar=no,width=320,height=200");
        intervalId = setInterval ("findCloned()", 100);
      }	// clone()

    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	  document.forms[0].justified[<%=sType.equals("yes") ? "0" : sType.equals("no") ? "1" : "2"%>].checked=true;
	} // setCombos()
    //-->
  </SCRIPT>
  <TITLE>hipergate :: Absentisms List</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Absentisms</FONT></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <!-- 19. Top Menu -->
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="9" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
<% if (bIsGuest) { %>
	<TD COLSPAN="4"></TD>
<% } else { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Ansentism"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createAbsentism()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Absentism"></TD>
        <TD><A HREF="#" onclick="deleteAbsentisms()" CLASS="linkplain">Delete</A></TD>
<% } %>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="nm_acourse">Course</OPTION><OPTION VALUE="nm_absentism">Student</OPTION><OPTION VALUE="id_absentism">Id.</OPTION><OPTION VALUE="tx_tutor">Tutor</OPTION></SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	</TD>
	<TD>
	  &nbsp;<A HREF="javascript:findAbsentism();" CLASS="linkplain" TITLE="Search">Search</A>
        </TD>
        <TD VALIGN="bottom" ALIGN="right">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Search"></TD>
        <TD VALIGN="bottom" ALIGN="left">
          <A HREF="javascript:document.forms[0].find.value='';findAbsentism();" CLASS="linkplain" TITLE="Discard Search">Discard</A>
        </TD>
      </TR>
      <TR>
        <TD COLSPAN="6">
          <FONT CLASS="textplain">Justified&nbsp;&nbsp;<INPUT TYPE="radio" NAME="justified" onclick="showOnlyJustified('yes')">&nbsp;Yes&nbsp;&nbsp;<INPUT TYPE="radio" NAME="justified" onclick="showOnlyJustified('no')">&nbsp;No&nbsp;&nbsp;<INPUT TYPE="radio" NAME="justified" onclick="showOnlyJustified('all')">&nbsp;Does not matter</FONT>
        </TD>
        <TD COLSPAN="3" ALIGN="right">
          <FONT CLASS="textplain">Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR>
        <TD COLSPAN="6">
          <FONT CLASS="textplain">Since:&nbsp;&nbsp;
	    <INPUT TYPE="text" MAXLENGTH="10" SIZE="10" NAME="tx_start" CLASS="combomini">
	    &nbsp;
	    <A HREF="javascript:showCalendar('tx_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
	    &nbsp;until&nbsp;
	    <INPUT TYPE="text" MAXLENGTH="10" SIZE="10" NAME="tx_end" CLASS="combomini">
	    &nbsp;
	    <A HREF="javascript:showCalendar('tx_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
        </TD>
        <TD COLSPAN="3" ALIGN="right">
        </TD>
      </TR>
      <TR><TD COLSPAN="9" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top Menu -->
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="6" ALIGN="left">
<%

    	  if (iAbsentismCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"absents_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + (iOrderBy==0 ? "" : "&orderby="+String.valueOf(iOrderBy)) + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");

            if (!oAbsentisms.eof())
              out.write("            <A HREF=\"absents_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + (iOrderBy==0 ? "" : "&orderby="+String.valueOf(iOrderBy)) + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iAbsentismCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Student</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Course</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(6);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==6 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Subject</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(7);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==7 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Justified</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select all"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%

	  for (int i=0; i<iAbsentismCount; i++) {
	   
	    sGuAbsentism = oAbsentisms.getString(0,i);
	    if (!oAbsentisms.isNull(1,i)) {
	      if (oAlumni.containsKey(oAbsentisms.getString(1,i)))
	        sNmAlumni = (String) oAlumni.get(oAbsentisms.getString(1,i));
	      else
	        sNmAlumni = "";
	    }
	    else {
	      sNmAlumni = "";
	    }
	    sTxDate = oAbsentisms.getString(3,i);
	    if (!oAbsentisms.isNull(4,i)) {
	      if (oCourse.containsKey(oAbsentisms.getString(4,i)))
	        sNmACourse = (String) oCourse.get(oAbsentisms.getString(4,i));
	      else
	        sNmACourse = "";
	    }
	    else {
	      sNmACourse = "";
	    }
	    if (!oAbsentisms.isNull(5,i)) {
	      if (oSubject.containsKey(oAbsentisms.getString(5,i)))
	        sNmSubject = (String) oSubject.get(oAbsentisms.getString(5,i));
	      else
	        sNmSubject = "";
	    }
	    else {
	      sNmSubject = "";
	    }
	    sTpAbsentism = oAbsentisms.getStringNull(6,i,"UNJUSTIFIED");
	    
            sStrip = String.valueOf((i%2)+1);
%>
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" oncontextmenu="jsAbsentismId='<%=sGuAbsentism%>'; return showRightMenu(event);" onclick="modifyAbsentism('<%=sGuAbsentism%>')" TITLE="Click right mouse button to open context menu"><%=sTxDate%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sNmAlumni%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sNmACourse%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sNmSubject%></TD>
	      <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=(sTpAbsentism.equalsIgnoreCase("UNJUSTIFIED") ? "No" : "Yes")%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<% out.write (sGuAbsentism); %>">
            </TR>
<%        } // next(i) %>
      </TABLE>
    </FORM>
    <!-- 22. DynFloat Right-click context menu -->
    <SCRIPT language="JavaScript" type="text/javascript">
      <!--
      addMenuOption("Open","modifyAbsentism(jsAbsentismId)",1);
      addMenuOption("Duplicate","clone()",0);
      //-->
    </SCRIPT>
    <!-- /RightMenuBody -->
</BODY>
</HTML>