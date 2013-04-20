<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<% 
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

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_contact = request.getParameter("gu_contact");
  String gu_company = nullif(request.getParameter("gu_company"));
  String gu_list = nullif(request.getParameter("gu_list"));
  String de_list = nullif(request.getParameter("de_list"));

  String full_name = null;
  String nm_company = null;

  JDCConnection oConn = null;
  PreparedStatement oStmt;
  ResultSet oRSet;
  DBSubset oTemplateProjs = new DBSubset (DB.k_projects, DB.gu_project + "," + DB.nm_project, DB.gu_owner + "='" + gu_workarea + "' AND " + DB.id_parent + " IS NULL AND " + DB.gu_company + " IS NULL", 10);
  int iTemplateProjs = 0;

  try {    
    oConn = GlobalDBBind.getConnection("create_project_for");
    
    iTemplateProjs = oTemplateProjs.load (oConn);
    
    if (null!=gu_contact) {
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
        oStmt = oConn.prepareStatement("SELECT CONCAT(COALESCE(tx_name,''),' ',COALESCE(tx_surname,'')) FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?");
      else
        oStmt = oConn.prepareStatement("SELECT " + DBBind.Functions.ISNULL + "(tx_name,'')" + DBBind.Functions.CONCAT + "' '" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(tx_surname,'') FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?");
      oStmt.setString(1, gu_contact);
      oRSet = oStmt.executeQuery();   
      oRSet.next();
      full_name = oRSet.getString(1);
      oRSet.close();
      oStmt.close();
    }
    
    if (gu_company.length()>0) {
      oStmt = oConn.prepareStatement("SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "=?");
      oStmt.setString(1, gu_company);
      oRSet = oStmt.executeQuery();   
      oRSet.next();
      nm_company = oRSet.getString(1);
      oRSet.close();
      oStmt.close();
    }
    

    oConn.close("create_project_for");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("create_project_for");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>Create Project for&nbsp;<%=nullif(full_name,nm_company)%></TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      function suggestNewName() {
        var frm = window.document.forms[0];
	var prj;

	if (frm.nm_project.value.length==0) {
	  if (frm.sel_project.options.selectedIndex<=0)
	    frm.nm_project.value = "";
	  else {
	    prj = getComboText(frm.sel_project);
	    if (prj.length>50) prj = prj.substring(0,49);
<%          if (null!=gu_contact) { %>
	      frm.nm_project.value = prj + " (<%=full_name%>)";
<%	    } else { %>
	      frm.nm_project.value = prj + " (<%=nullif(nm_company,de_list)%>)";
<%	    } %>
	  }
	}
      }
      
      function validate() {
        var frm = window.document.forms[0];

	if (frm.de_project.value.length>1000) {
	  alert ("Project description cannot exceed 1000 characters");
	  return false;
	}

	if (frm.sel_project.options.selectedIndex<0) {
	  alert ("YYou must choose a template for the Project");
	  return false;
	}
		  
	if (frm.sel_project.options.selectedIndex>0 && frm.nm_project.value==getCombo(frm.sel_project)) {
	  alert ("Name of the new project cannot be the same as its template");
	  return false;
	}

	if (frm.sel_project.options.selectedIndex>0 && frm.nm_project.value.length==0) {
	  alert ("Project Name is mandatory");
	  return false;
	}

	frm.gu_project.value = getCombo(frm.sel_project);
	
	if (frm.sel_project.options.selectedIndex==0) {
	  frm.action = "../projtrack/prj_new.jsp";
          resizeTo(740,520);
        }
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY >
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Create Project for&nbsp;<%=nullif(full_name,nullif(nm_company,de_list))%></FONT></TD></TR>
  </TABLE>
  <FORM METHOD="post" ACTION="prj_create_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=nullif(gu_contact)%>">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=gu_company%>">
    <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=gu_list%>">
    <INPUT TYPE="hidden" NAME="nm_legal" VALUE="<%=nullif(nm_company)%>">
    <INPUT TYPE="hidden" NAME="tx_contact" VALUE="<%=nullif(full_name)%>">
    <INPUT TYPE="hidden" NAME="gu_project">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">Project Template</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_project" STYLE="width:370px" onchange="suggestNewName()"><OPTION VALUE="">(none)</OPTION><% for (int p=0; p<iTemplateProjs; p++) out.write("<OPTION VALUE=\"" + oTemplateProjs.getString(0,p) + "\">" + oTemplateProjs.getString(1,p) + "</OPTION>"); %></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">New name</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="nm_project" MAXLENGTH="50" STYLE="width:360px"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">Description</FONT></TD>
            <TD><TEXTAREA NAME="de_project" ROWS="5" STYLE="font-family:Arial;font-size:9pt;width:360px"></TEXTAREA></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Create" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
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
