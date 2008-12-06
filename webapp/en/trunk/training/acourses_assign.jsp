<%@ page import="java.net.URLDecoder,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

  String gu_workarea = getCookie(request,"workarea","");

  String sField = nullif(request.getParameter("field"));
  String sFind = nullif(request.getParameter("find"));
  String sFullName = request.getParameter("fullname");
  
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  // **********************************************

  String sOrderBy;
  int iOrderBy;

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
  boolean bIsGuest = true;
  DBSubset oCourses = new DBSubset(DB.v_active_courses, DB.gu_acourse+","+DB.id_acourse+","+DB.nm_acourse+","+DB.tx_start+","+DB.tx_end, DB.gu_workarea+"=? ORDER BY 2", 100);
  DBSubset oStuding = new DBSubset(DB.k_x_course_alumni, DB.gu_acourse+","+DB.gu_alumni+","+DB.tp_register+","+DB.id_classroom,
  				   DB.gu_alumni+"=?", 10);  
  int iCourses = 0, iStuding = 0;
  int iFound;
  
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("acourseassign");

    iCourses = oCourses.load(oConn, new Object[]{gu_workarea});

    iStuding = oStuding.load(oConn, new Object[]{sFind});
    
    oConn.close("acourseassign");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("acourseassign");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }

  if (null==oConn) return;

  oConn = null;
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/findit.js"></SCRIPT>    

  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" DEFER="defer">
    <!--
        // ----------------------------------------------------

        // 15. Reload Page sorting by a field

	function sortBy(fld) {

	  var frm = document.forms[0];

	  window.location = "acourses_assign.jsp?field=gu_alumni&find="+getURLParam("find")+"&fullname="+escape(getURLParam("fullname"))+"&orderby=" + fld;
	} // sortBy

        // ----------------------------------------------------

        // 17. Reload Page finding instances by a single field

	function findCourse() {
	  var txt = window.prompt("Name of course to be searched","");

	  if (txt!=null && txt!="" && txt!=undefined) findit(txt);
	} // findCourse()

    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
    <!--
	function validate() {
	  var frm = document.forms[0];
	  var cls;
	  
	  frm.checkeditems.value = "";
	  frm.classrooms.value = "";
	  
	  for (var c=0; c<frm.elements.length; c++) {
	    if (frm.elements[c].type=="checkbox") {
	      if (frm.elements[c].checked) {
	        frm.checkeditems.value += (frm.checkeditems.value.length==0 ? "" : ",") + frm.elements[c].value;
	        
	        var cls = frm.elements[frm.elements[c].value].value;
	        if ((cls.indexOf("'")>=0) || (cls.indexOf(",")>=0)) {
	          alert ("Gruop name contains forbidden characters");
	          return false;
	        }
		frm.classrooms.value += (frm.classrooms.value.length==0 ? "" : ",") + cls;
	      }
	    }
	  } // next
	  return true;
	} // validate()
    //-->
  </SCRIPT>
  <TITLE>hipergate :: Courses by Student</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <DIV class="cxMnu1" style="width:320px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
    <FORM METHOD="post" ACTION="acourses_assign_store.jsp" onsubmit="return validate()">
      <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1">Academic Courses of&nbsp;<%=sFullName%></FONT></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="gu_alumni" VALUE="<%=sFind%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="checkeditems" VALUE="">
      <INPUT TYPE="hidden" NAME="classrooms" VALUE="">
      
      <!-- 19. Top Menu -->
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD VALIGN="bottom"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
	<TD>
	  &nbsp;<A HREF="#" onclick="findCourse();" CLASS="linkplain" TITLE="Search">Search</A>
        </TD>
      </TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top Menu -->
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Id.</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(6);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==6 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Start</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(7);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==7 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>End</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Room/Group</B></TD>
        </TR>
<%

	  String sChecked, sGuCourse, sIdCourse, sNmCourse, sTxStart, sTxEnd, sIdClassroom, sStrip;
	  for (int i=0; i<iCourses; i++) {
            sGuCourse = oCourses.getString(0,i);
            sIdCourse = oCourses.getString(1,i);
            sNmCourse = oCourses.getString(2,i);
            sTxStart = oCourses.getStringNull(3,i,"");
            sTxEnd = oCourses.getStringNull(4,i,"");

	    iFound = oStuding.find(0, sGuCourse);
	    if (iFound>=0) {
	      sChecked = " CHECKED";
	      sIdClassroom = oStuding.getStringNull(3,iFound,"");
	    } else {
	      sChecked = "";
	      sIdClassroom = "";
            }
            
            sStrip = String.valueOf((i%2)+1);
%>
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT TYPE="checkbox" VALUE="<% out.write (sGuCourse); %>"<%=sChecked%>>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sIdCourse%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sNmCourse%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sTxStart%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sTxEnd%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<INPUT TYPE="text" CLASS="combomini" MAXLENGTH="30" NAME="<% out.write (sGuCourse); %>" VALUE="<%=sIdClassroom%>"></TD>
            </TR>
<%        } // next(i) %>
      </TABLE>
      <HR>
      <CENTER><INPUT TYPE="submit" VALUE="Save" ACCESSKEY="s" CLASS="pushbutton">&nbsp;&nbsp;<INPUT TYPE="button" VALUE="Close" ACCESSKEY="c" CLASS="closebutton" onclick="window.close()"></CENTER>
    </FORM>
</BODY>
</HTML>