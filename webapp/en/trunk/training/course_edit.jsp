<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.training.Course" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
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
  
  // 01. Authenticate user session by checking cookies
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // 02. Add no-cache headers
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // 03. Get parameters

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_course = nullif(request.getParameter("gu_course"));
    
  Course oCur = new Course();
  
  String sDeptsLookUp = "", sAreasLookUp = "";
    
  JDCConnection oConn = null;
    
  try {
    
    oConn = GlobalDBBind.getConnection("course_edit", true);  
    
    sDeptsLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_courses_lookup, gu_workarea, DB.tx_dept, sLanguage);
    sAreasLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_courses_lookup, gu_workarea, DB.tx_area, sLanguage);
    
    if (gu_course.length()>0) {
      oCur.load(oConn, new Object[]{gu_course});
    }

    oConn.close("course_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("course_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }

  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Course</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_courses_lookup&id_language=" + getUserLanguage() + "&id_section=tx_dept&tp_control=2&nm_control=sel_dept&nm_coding=tx_dept", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_courses_lookup&id_language=" + getUserLanguage() + "&id_section=tx_area&tp_control=2&nm_control=sel_area&nm_coding=tx_area", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	if (frm.nm_course.value.length==0) {
	  alert ("Course name is required");
	  return false;
	}
	
	if ((frm.nm_course.value.indexOf("'")>=0) || (frm.nm_course.value.indexOf('"')>=0)) {
	  alert ("Course name contains forbidden characters");
	  return false;
	}

	if (frm.de_course.value.length>2000) {
	  alert ("Course description cannot exceed 2000 characters");
	  return false;
	}
	
	if (frm.nu_credits.value.length>0) {
	  if (!isFloatValue(frm.nu_credits.value)) {
	    alert ("Credit number is not valid");
	    return false;	  
	  }
	}
	
	frm.nm_course.value = frm.nm_course.value.toUpperCase();
	frm.id_course.value = frm.id_course.value.toUpperCase();
	
	frm.tx_dept.value = getCombo(frm.sel_dept);
	frm.tx_area.value = getCombo(frm.sel_area);

	if (frm.chk_active.checked) frm.bo_active.value = "1"; else frm.bo_active.value = "0";

        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];

        setCombo(frm.sel_dept,"<%out.write(oCur.getStringNull(DB.tx_dept,""));%>");
        setCombo(frm.sel_area,"<%out.write(oCur.getStringNull(DB.tx_area,""));%>");

        return true;
      } // validate;
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Course</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="course_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_course" VALUE="<%=gu_course%>">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="<% if (!oCur.isNull(DB.bo_active)) out.write(String.valueOf(oCur.getShort(DB.bo_active))); else out.write("1"); %>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Active:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="checkbox" NAME="chk_active" <% if (!oCur.isNull(DB.bo_active)) out.write(oCur.getShort(DB.bo_active)!=0 ? "CHECKED" : ""); else out.write("CHECKED"); %>></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_course" MAXLENGTH="100" SIZE="48" STYLE="text-transform:uppercase" VALUE="<%=oCur.getStringNull(DB.nm_course,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Identifier:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="id_course" MAXLENGTH="50" SIZE="10" STYLE="text-transform:uppercase" VALUE="<%=oCur.getStringNull(DB.id_course,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Department:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tx_dept">
              <SELECT NAME="sel_dept"><OPTION VALUE=""></OPTION><%=sDeptsLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Departments List"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Area:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tx_area">
              <SELECT NAME="sel_area"><OPTION VALUE=""></OPTION><%=sAreasLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Areas List"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Creditts:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nu_credits" MAXLENGTH="5" SIZE="6" VALUE="<% if (!oCur.isNull(DB.nu_credits)) out.write(String.valueOf(oCur.getFloat(DB.nu_credits))); %>" onkeypress="acceptOnlyNumbers(this)"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Description:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><TEXTAREA ROWS="4" COLS="32" NAME="de_course"<%=oCur.getStringNull(DB.de_course,"")%>></TEXTAREA></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
