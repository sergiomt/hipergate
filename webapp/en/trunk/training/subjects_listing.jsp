<%@ page import="java.net.URLDecoder,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.QueryByForm" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
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

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm","");
  String gu_workarea = getCookie(request,"workarea","");

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
  String sWhere = nullif(request.getParameter("where"));
  String sQuery = nullif(request.getParameter("query"));
  String sStatus = nullif(request.getParameter("status"),"all");

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  // **********************************************

  int iSubjectCount = 0;
  DBSubset oSubjects;
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
    sOrderBy = "";

  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  // **********************************************

  JDCConnection oConn = null;
  QueryByForm oQBF;
  boolean bIsGuest = true;

  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);

    oConn = GlobalDBBind.getConnection("subjectlisting", true);

    if (sWhere.length()>0) {

      // 09. QBF Filtered Listing

      oQBF = new QueryByForm("file://" + sStorage + "qbf" + File.separator + request.getParameter("queryspec") + ".xml");

      oSubjects = new DBSubset (oQBF.getBaseObject(),
      			       "gu_subject,id_subject,nm_subject,bo_active,tx_area",
      				 "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

      oSubjects.setMaxRows(iMaxRows);
      iSubjectCount = oSubjects.load (oConn, iSkip);
    }

    else if (sFind.length()==0 || sField.length()==0) {

      oSubjects = new DBSubset (DB.k_subjects,
      			       "gu_subject,id_subject,nm_subject,bo_active,tx_area",
      			       DB.gu_workarea+ "='" + gu_workarea + "' " + (sStatus.equals("active") ? " AND bo_active=1 " : "") + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

      oSubjects.setMaxRows(iMaxRows);
      iSubjectCount = oSubjects.load (oConn, iSkip);
    }
    else {
      Object[] aFind = { null };
      
      if (sField.equalsIgnoreCase(DB.nm_course)) {
        oSubjects = new DBSubset (DB.k_subjects + " s," + DB.k_courses + " c",
      			          "s.gu_subject,s.id_subject,s.nm_subject,s.bo_active,s.tx_area",
      			          "s." + DB.gu_workarea+ "='" + gu_workarea + "' AND s." + DB.gu_course + "=c." + DB.gu_course + " AND c." + DB.nm_course + " " + DBBind.Functions.ILIKE + " ? " + (sStatus.equals("active") ? " AND s.bo_active=1 " : "") + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
        aFind[0] = "%" + sFind + "%";
      } else if (sField.equalsIgnoreCase(DB.gu_course)) {
        oSubjects = new DBSubset (DB.k_subjects + " s," + DB.k_courses + " c",
      			          "s.gu_subject,s.id_subject,s.nm_subject,s.bo_active,s.tx_area,c.nm_course",
      			          "s." + DB.gu_workarea+ "='" + gu_workarea + "' AND s." + DB.gu_course + "=c." + DB.gu_course + " AND c." + DB.nm_course + " " + DBBind.Functions.ILIKE + " ? " + (sStatus.equals("active") ? " AND s.bo_active=1 " : "") + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
        aFind[0] = sFind;
      }      
      else {
        oSubjects = new DBSubset (DB.k_subjects,
      			          "gu_subject,id_subject,nm_subject,bo_active,tx_area",
      			          DB.gu_workarea+ "='" + gu_workarea + "' AND " + sField + " " + DBBind.Functions.ILIKE + " ? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
        aFind[0] = "%" + sFind + "%";
      }
      
      oSubjects.setMaxRows(iMaxRows);

      iSubjectCount = oSubjects.load (oConn, aFind, iSkip);
    }

    oConn.close("subjectlisting");
  }
  catch (SQLException e) {
    oSubjects = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("subjectlisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
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

        var jsSubjectId;
        var jsSubjectNm;

        <%
          // Write instance primary keys in a JavaScript Array
          // This Array is used when posting multiple elements
          // for deletion.

          out.write("var jsSubjects = new Array(");

            for (int i=0; i<iSubjectCount; i++) {
              if (i>0) out.write(",");
              out.write("\"" + oSubjects.getString(0,i) + "\"");
            }

          out.write(");\n        ");
        %>

        // ----------------------------------------------------

<% if (!bIsGuest) { %>

        // 12. Create new instance

	function createSubject() {

	  self.open ("subject_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "editsubject", "directories=no,toolbar=no,menubar=no,width=500,height=420");
	} // createSubject()

        // ----------------------------------------------------

        // 13. Delete checked subjects

	function deleteSubjects() {

	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;

	  if (window.confirm("Are you sure that you want to delete selected courses?")) {

	    chi.value = "";
	    frm.action = "subject_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");

	    for (var i=0;i<jsSubjects.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsSubjects[i] + ",";
              offset++;
	    } // next()

	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteSubjects()
<% } %>
        // ----------------------------------------------------

        // 14. Modify Subject

	function modifySubject(id) {

	  self.open ("subject_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>" + "&gu_subject=" + id, "editsubject", "directories=no,toolbar=no,menubar=no,width=500,height=420");
	} // modifySubject

        // ----------------------------------------------------

	function sortBy(fld) {

	  var frm = document.forms[0];

	  window.location = "subjects_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&status=" + (frm.status[0].checked ? "all" : "active") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // sortBy

        // ----------------------------------------------------

	function showOnlyActive(yn) {

	  var frm = document.forms[0];

	  window.location = "subjects_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&status=" + (yn ? "active" : "all") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // showOnlyActive

        // ----------------------------------------------------

        // 16. Select All Subjects

        function selectAll() {

          var frm = document.forms[0];

          for (var c=0; c<jsSubjects.length; c++)
            eval ("frm.elements['" + jsSubjects[c] + "'].click()");
        } // selectAll()

        // ----------------------------------------------------

        // 17. Reload Page finding instances by a single field

	function findSubject() {

	  var frm = document.forms[0];

	  if (frm.find.value.length>0)
	    window.location = "subjects_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&status=" + (frm.status[0].checked ? "all" : "active") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  else
	    window.location = "subjects_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&status=" + (frm.status[0].checked ? "all" : "active") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);

	} // findSubject()


      // ------------------------------------------------------
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
<% if (sField.equalsIgnoreCase(DB.gu_course)) { %>
	  setCombo(document.forms[0].sel_searched, "nm_course");
<%   if (iSubjectCount>0) { %>
	  document.forms[0].find.value="<%=oSubjects.getString(5,0)%>";
<%   }
   } else { %>
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	  document.forms[0].find.value="<%=sFind%>";
<% } %>   
	  document.forms[0].status[0].checked = (getURLParam("status")=="all");
	} // setCombos()
    //-->
  </SCRIPT>
  <TITLE>hipergate :: Subjects Listing</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Subjects</FONT></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <!-- 19. Top Menu -->
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
<% if (bIsGuest) { %>
	<TD COLSPAN="4"></TD>
<% } else { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Subject"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createSubject()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Subject"></TD>
        <TD><A HREF="#" onclick="deleteSubjects()" CLASS="linkplain">Delete</A></TD>
<% } %>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="nm_subject">Name</OPTION><OPTION VALUE="nm_course">Course</OPTION><OPTION VALUE="id_subject">Id.</OPTION><OPTION VALUE="tx_area">Area</OPTION></SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50">
	  &nbsp;<A HREF="javascript:findSubject();" CLASS="linkplain" TITLE="Search">Search</A>
        </TD>
        <TD VALIGN="bottom" ALIGN="right">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Search"></TD>
        <TD VALIGN="bottom" ALIGN="left">
          <A HREF="javascript:document.forms[0].find.value='';findSubject();" CLASS="linkplain" TITLE="Discard Search">Discard</A>
        </TD>
      </TR>
      <TR>
        <TD></TD>
        <TD COLSPAN="4">
          <FONT CLASS="textplain">Status:&nbsp;&nbsp;<INPUT TYPE="radio" NAME="status" onclick="showOnlyActive(false)">&nbsp;All&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="status" CHECKED onclick="showOnlyActive(true)">&nbsp;Active Only</FONT>
        </TD>
        <TD ALIGN="right">
          <FONT CLASS="textplain">Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
        <TD COLSPAN="2"></TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top Menu -->
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="5" ALIGN="left">
<%
    	  // 20. Paint Next and Previous Links

    	  if (iSubjectCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"subjects_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");

            if (!oSubjects.eof())
              out.write("            <A HREF=\"subjects_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iSubjectCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Id.</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Status</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Area</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select all"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%

	  String sGuSubject, sIdSubject, sNmSubject, sTxArea, sStrip;
	  for (int i=0; i<iSubjectCount; i++) {
            sGuSubject = oSubjects.getString(0,i);
            sIdSubject = oSubjects.getStringNull(1,i,"");
            sNmSubject = oSubjects.getString(2,i);
            if (oSubjects.isNull(3,i))
              sStatus = "Active";
            else if (oSubjects.getShort(3,i)!=(short)0)
              sStatus = "Active";
            else
              sStatus = "Inactive";
            sTxArea = oSubjects.getStringNull(4,i,"");

            sStrip = String.valueOf((i%2)+1);
%>
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sIdSubject%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" onclick="modifySubject('<%=sGuSubject%>')"><%=sNmSubject%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sStatus%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sTxArea%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<% out.write (sGuSubject); %>">
            </TR>
<%        } // next(i) %>
      </TABLE>
    </FORM>
    <!-- 22. DynFloat Right-click context menu -->
    <SCRIPT language="JavaScript" type="text/javascript">
      <!--
      addMenuOption("Open","modifySubject(jsSubjectId)",1);
      addMenuOption("Duplicate","clone()",0);
      addMenuSeparator();
      //-->
    </SCRIPT>
    <!-- /RightMenuBody -->
</BODY>
</HTML>