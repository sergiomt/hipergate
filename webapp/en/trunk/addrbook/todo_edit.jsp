<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.addrbook.ToDo" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
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
  
  // 01. Authenticate user session by checking cookies
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // 02. Add no-cache headers
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // 03. Get parameters

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_to_do = request.getParameter("gu_to_do");
  String gu_user = getCookie (request, "userid", null);

  ToDo oTodo = new ToDo();
  
  String sPriorityLookUp = "", sStatusLookUp = "", sTypeLookUp = "";
    
  JDCConnection oConn = null;
    
  try {
    
    oConn = GlobalDBBind.getConnection("todo_edit");  
    
    sPriorityLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_to_do_lookup, gu_workarea, DB.od_priority, sLanguage);
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_to_do_lookup, gu_workarea, DB.tx_status, sLanguage);
    sTypeLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_to_do_lookup, gu_workarea, DB.tp_to_do, sLanguage);
    
    if (null!=gu_to_do) oTodo.load (oConn, new Object[]{gu_to_do});
      
    oConn.close("todo_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("todo_edit");
    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getMessage(), "");
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>Edit Task</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_to_do_lookup&id_language=" + getUserLanguage() + "&id_section=tp_to_do&tp_control=2&nm_control=sel_to_do&nm_coding=tp_to_do", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	if (frm.tl_to_do.value.length==0) {
	  alert ("Activity title may not be empty");
	  return false;
	}

	if (frm.dt_end.value.length>0) {
	  if (!isDate(frm.dt_end.value, "d")) {
	    alert ("Date is not valid");
	    return false;	  
	  }
	  else if (parseDate(frm.dt_end.value + " 23:59:59", "ts")<new Date()) {
	    alert ("Date cannot be before today");
	    return false;	  	  
	  }
	}

	if (frm.tx_to_do.value.length>2000) {
	  alert ("Activity description may not be longer than 2000 characters");
	  return false;
	}

        if (frm.sel_status.options.selectedIndex>=0)
          frm.tx_status.value = getCombo(frm.sel_status);

        if (frm.sel_to_do.options.selectedIndex>=0)
          frm.tp_to_do.value = getCombo(frm.sel_to_do);
        
        if (frm.sel_priority.options.selectedIndex>=0)
          frm.od_priority.value = getCombo(frm.sel_priority);

        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];

   	var copyOption = new Array();
   	var opt = frm.sel_priority.options;
   
   	for (var i=0; i<opt.length; i++)   
          copyOption[i] = new Array(opt[i].value, opt[i].text);

   	copyOption.sort(function(a,b) { return parseInt(a[0])-parseInt(b[0]); });

   	clearCombo (frm.sel_priority);

     	comboPush (frm.sel_priority, "", "", false, false)
      	
   	for (var i=0; i<copyOption.length; i++)
     	  comboPush (frm.sel_priority, copyOption[i][1], copyOption[i][0], false, false)
                
        setCombo(frm.sel_to_do,"<% out.write(oTodo.getStringNull(DB.tp_to_do,"")); %>");
        setCombo(frm.sel_status,"<% out.write(oTodo.getStringNull(DB.tx_status,"PENDING")); %>");
        setCombo(frm.sel_priority,"<% if (oTodo.isNull(DB.od_priority)) out.write(""); else out.write(String.valueOf(oTodo.getShort(DB.od_priority))); %>");

        return true;
      } // validate;
    //-->
  </SCRIPT>    
</HEAD>
<BODY  onLoad="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Task</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="todo_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_to_do" VALUE="<%=nullif(gu_to_do)%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=gu_user%>">    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Title</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tl_to_do" MAXLENGTH="100" SIZE="50" VALUE="<%=oTodo.getStringNull(DB.tl_to_do,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Type</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tp_to_do">
              <SELECT NAME="sel_to_do"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Task Types"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Priority</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="od_priority" VALUE="">
              <SELECT NAME="sel_priority"><%=sPriorityLookUp%></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Status</TD>
            <TD>
              <INPUT TYPE="hidden" NAME="tx_status">
              <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Date</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_end" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oTodo.get(DB.dt_end)!=null ? oTodo.getDateFormated(DB.dt_end,"yyyy-MM-dd") : ""); %>">
              <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Description</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><TEXTAREA ROWS="4" COLS="40" NAME="tx_to_do"><%=oTodo.getStringNull(DB.tx_to_do,"")%></TEXTAREA></TD>
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
<%@ include file="../methods/page_epilog.jspf" %>