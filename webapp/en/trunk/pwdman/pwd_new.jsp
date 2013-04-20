<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.acl.PasswordRecordTemplate,com.knowgate.acl.PasswordRecordLine" language="java" session="true" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="pwdtemplates.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*  
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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
	boolean bSession = (session.getAttribute("validated")!=null) && (session.getAttribute("signature")!=null);

	if (!bSession) {
	  response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Session Expired&desc=Session has expired. Please log in again&resume=_close"));
    return;
  }

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "pwd_new";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  String sStorage = GlobalDBBind.getPropertyPath("storage");
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_category = request.getParameter("gu_category");
  String nm_template = request.getParameter("nm_template");
  String id_user = getCookie(request, "userid", "");
  
  PasswordRecordTemplate oRec = new PasswordRecordTemplate();
  oRec.load(Gadgets.chomp(getTemplatesPath(sStorage, id_domain, gu_workarea, id_user),File.separator)+nm_template);
      
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: New <%=oRec.getName()%></TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/grid.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      var oPwdsGrid = GridCreate(0,3);
      var jsTableHeader = "<TABLE WIDTH=100%><TR><TD></TD><TD></TD><TD></TD></TR>";
      var jsTableFooter = "</TABLE>";
      var jsTableName = "pwdlines";

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        
        if (ltrim(frm.tl_pwd.value).length==0) {
          alert ("The title of the password is required");
          frm.tl_pwd.focus();
          return false;
        }
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function addNewField() {
      	var lbl = window.prompt("Please set the name for the new field");
      	
      	if (lbl!=null) {
      	  if (lbl.length>0) {

					  if (hasForbiddenChars(lbl)) {
					    alert ("The name of the new field contains invalid characters");
					  } else {
				      GridRemoveRow(oPwdsGrid,oGrid.rowcount-1);

				      var rc = String(oGrid.rowcount);

				      oRow = GridCreateRow(oPwdsGrid, "line_"+rc);
              GridCreateCell(oRow, 0, "lbl_line_"+rc, "lbl_line_"+rc, "html", "<FONT CLASS=textsmall>"+lbl+"</FONT>");
              GridCreateInputCell(oRow, 1, "line_"+rc, "line_"+rc, "text", "", 50, 100, "");
              GridCreateCell(oRow, 2, "x_line_"+rc, "x_line_"+rc, "html", "<A HREF=# TITLE='Remove field' onclick='GridRemoveRow(oPwdsGrid,GridFindRow(oPwdsGrid,\"line_" + String(oGrid.rowcount) + "\")); GridDraw (oPwdsGrid, jsTableName, jsTableHeader, jsTableFooter);'><IMG SRC='../images/images/delete.gif' BORDER='0' ALT='Delete'></A>");

				      oRow = GridCreateRow(oPwdsGrid, "newline");
              GridCreateCell(oRow, 0, "void_newline1", "void_newline1", "html", "");
              GridCreateCell(oRow, 1, "void_newline2", "void_newline2", "html", "");
              GridCreateCell(oRow, 2, "void_newline3", "void_newline3", "html", "<A HREF=# onclick='addNewField()' TITLE='Add New Field'><IMG SRC='../images/images/new16x16.gif' BORDER='0' ALT='New'></A>");
		          GridDraw (oPwdsGrid, jsTableName, jsTableHeader, jsTableFooter);
		          
		          var hd = document.createElement("input");
		          hd.type="hidden";
		          hd.name = "lbl_line_"+rc;
		          hd.value = lbl;
		          document.forms[0].appendChild(hd);
		          alert ("lbl_line_"+rc+"="+document.forms[0].elements["lbl_line_"+rc].value);
            }
          }
        }
      } // addNewField
      
      function paintFields() {
        var oRow;
        oRow = GridCreateRow(oPwdsGrid, "tl_pwd");
        GridCreateCell(oRow, 0, "lbl_tl_pwd", "lbl_tl_pwd", "html", "<FONT CLASS=textsmall><B>Title</B></FONT>");
        GridCreateInputCell(oRow, 1, "tl_pwd", "tl_pwd", "text", "", 50, 100, "onchange=''");
        GridCreateCell(oRow, 2, "lbl_void", "lbl_void", "html", "");
        
<%      for (PasswordRecordLine rcl : oRec.lines()) {
				  out.write("        oRow = GridCreateRow(oPwdsGrid, \""+rcl.getId()+"\");\n");
  	      out.write("        GridCreateCell(oRow, 0, \"lbl_"+rcl.getId()+"\", \"lbl_"+rcl.getId()+"\", \"html\", \"<FONT CLASS=textsmall>" + rcl.getLabel() + "</FONT>\");\n");
  	      out.write("        GridCreateInputCell(oRow, 1, \""+rcl.getId()+"\", \""+rcl.getId()+"\", \"text\", \"\", 50, 100, \"onchange=''\");\n");
  	      out.write("        GridCreateCell(oRow, 2, \"x_"+rcl.getId()+"\", \"x_"+rcl.getId()+"\", \"html\", \"<A HREF=# TITLE='Remove field' onclick='GridRemoveRow(oPwdsGrid,GridFindRow(oPwdsGrid,\\\"" + rcl.getId() + "\\\")); GridDraw (oPwdsGrid, jsTableName, jsTableHeader, jsTableFooter);'><IMG SRC='../images/images/delete.gif' BORDER='0' ALT='Delete'></A>\");\n");	
        } // next
%>
				oRow = GridCreateRow(oPwdsGrid, "newline");
        GridCreateCell(oRow, 0, "void_newline1", "void_newline1", "html", "");
        GridCreateCell(oRow, 1, "void_newline2", "void_newline2", "html", "");
        GridCreateCell(oRow, 2, "void_newline3", "void_newline3", "html", "<A HREF=# onclick='addNewField()' TITLE='Add New Field'><IMG SRC='../images/images/new16x16.gif' BORDER='0' ALT='New'></A>");
		    GridDraw (oPwdsGrid, jsTableName, jsTableHeader, jsTableFooter);
      } // paintFields;
    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="paintFields()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">New&nbsp;<%=oRec.getName()%></FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="pwd_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_pwd" VALUE="">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_category" VALUE="<%=gu_category%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="nm_template" VALUE="<%=nm_template%>">
    <INPUT TYPE="hidden" NAME="id_pwd" VALUE="<% if (nm_template.startsWith("brands"+File.separator)) out.write(Gadgets.substrBetween(nm_template, File.separator, ".")); %>">
    <INPUT TYPE="hidden" NAME="id_enc_method" VALUE="<% out.write(nm_template.startsWith("brands"+File.separator) ? "NONE" : "RC4"); %>">   
<% for (PasswordRecordLine rcl : oRec.lines()) { %>
    <INPUT TYPE="hidden" NAME="lbl_<%=rcl.getId()%>" VALUE="<%=rcl.getLabel()%>">   
<% } %>
    <TABLE CLASS="formback" WIDTH="480">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD></TD>
            <TD><DIV ID="pwdlines"></DIV></TD>
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
