<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %>
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

  final int Sales=16;

  // Inicio de sesion anónimo permitido
  // if (autenticateSession(GlobalDBBind, request, response)<0) return;
 
  String gu_project = request.getParameter("gu_project");
  
  String sLanguage = getNavigatorLanguage(request);
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  String sWorkArea = getCookie(request,"workarea","");
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
    
  JDCConnection oCon1 = null;
  Object aProj[] = { gu_project }; 
  Project oPrj = new Project();
  Project oChl = null;  
  String sDeptsLookUp = null;
  String sStatusLookUp = null;
  
  int iPrjRoot = 0;
  DBSubset oPrjRoots = new DBSubset (DB.k_projects, DB.gu_project + "," + DB.nm_project + "," + DB.id_parent,
  				     DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_parent + " IS NULL ORDER BY 2", 10);
  int iPrjChlds = 0;
  DBSubset oPrjChlds = null;
  float fCost = 0;
  
  Boolean oTrue = new Boolean(true);

  HashMap oPrjChilds = new HashMap(31);  
  oPrjChilds.put(gu_project, oTrue);
  
  boolean bIsGuest = true;
  
  try {
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oCon1 = GlobalDBBind.getConnection("prj_edit");
    
    if ((iAppMask & (1<<Sales))!=0)        
      sDeptsLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_projects_lookup, sWorkArea, DB.id_dept, sLanguage);
      
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_projects_lookup, sWorkArea, DB.id_status, sLanguage);
    
    oPrj.load(oCon1, aProj);
    
    fCost = oPrj.cost(oCon1);
    
    iPrjRoot = oPrjRoots.load(oCon1);
    
    oCon1.close("prj_edit");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("prj_edit");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  
  if (null==oCon1) return;
  oCon1=null;
  
%>
<HTML>
  <HEAD>
    <TITLE>hipergate :: Edit Project<%=oPrj.getString(DB.nm_project)%></TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
    <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');

      // ------------------------------------------------------

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

      function setCombos() {
        var frm = document.forms[0];
        
<% if ((iAppMask & (1<<Sales))!=0) { %>
        setCombo(frm.sel_dept, "<%=oPrj.getStringNull(DB.id_dept,"")%>");
<% } %>
      }

      // ------------------------------------------------------

      function lookup(odctrl) {
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_projects_lookup&id_language=" + getUserLanguage() + "&id_section=id_dept&tp_control=2&nm_control=sel_dept&nm_coding=id_dept", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()

      // ------------------------------------------------------

      function reference(odctrl) {
        var frm = document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 2:
            window.open("../common/reference.jsp?nm_table=k_companies&tp_control=1&nm_control=nm_legal&nm_coding=gu_company", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            if (frm.gu_company.value=="")
              alert ("Para asignar un contacto primero debe seleccionar una compañía");
            else
              window.open("../common/reference.jsp?nm_table=k_contacts&tp_control=1&nm_control=" + "tx_name%2B%27%20%27%2Btx_surname%20AS%20tx_contact" + "&nm_coding=gu_contact&where=" + escape("gu_company='" + frm.gu_company.value + "'"), "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // reference()
            
      // ------------------------------------------------------
      
      function validate() {
	var frm = window.document.forms[0];
	var str;
	var aStart;
	var aEnd;
	var dtStart;
	var dtEnd;
	
	if (rtrim(frm.nm_project.value)=="") {
	  alert ("Project Name is mandatory");
	  return false;
	}
	
	if (frm.de_project.value.length>1000) {
	  alert ("Description must not be longer than 1000 characters");
	  return false;
	}

<% if ((iAppMask & (1<<Sales))!=0) { %>

	frm.id_dept.value = getCombo(frm.sel_dept);

	if (ltrim(frm.nm_legal.value)=="")
	  frm.gu_company.value = "";
	
	if (ltrim(frm.tx_contact.value)=="")
	  frm.gu_contact.value = "";

<% } %>
	
	return true;	
      } // validate()

      //-->
    </SCRIPT>
  </HEAD>
  <BODY  onLoad="setCombos()">
    <TABLE WIDTH="90%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Clone Project</FONT></TD></TR></TABLE>       
    <BR>
    <FORM NAME="frmCloneProject" METHOD="post" ACTION="prj_clone_store.jsp" onSubmit="return validate();">
      <INPUT TYPE="hidden" NAME="gu_project" VALUE="<%=request.getParameter("gu_project")%>">
      <INPUT TYPE="hidden" NAME="gu_company" VALUE="<% if (oPrj.get(DB.gu_company)!=null) out.write(oPrj.getString(DB.gu_company)); %>">
      <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<% if (oPrj.get(DB.gu_contact)!=null) out.write(oPrj.getString(DB.gu_contact)); %>">
      <CENTER>
      <TABLE SUMMARY="Edición de Proyecto" CLASS="formback">
        <TR>          
          <TD VALIGN="top" CLASS="formfront">
	    <TABLE SUMMARY="Project Data">
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Name</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="50" SIZE="30" NAME="nm_project" VALUE="<%=oPrj.getString(DB.nm_project)%>" TABINDEX="-1" onfocus="//document.forms[0].dt_closed.focus()">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Reference</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="50" SIZE="20" NAME="id_ref">
                </TD>
              </TR>
<% if ((iAppMask & (1<<Sales))!=0) { %>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Company</FONT></TD>
                <TD>
                  <INPUT TYPE="text" SIZE="34" NAME="nm_legal" VALUE="<% if (oPrj.get(DB.tx_company)!=null) out.write(oPrj.getString(DB.tx_company)); %>" onkeypress="return false;">
                  &nbsp;&nbsp;<A HREF="javascript:reference(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Company List"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Department</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" MAXLENGTH="255" NAME="id_dept" VALUE="<% if (oPrj.get(DB.id_dept)!=null) out.write(oPrj.getString(DB.id_dept)); %>">
                  <SELECT NAME="sel_dept" STYLE="width:230"><OPTION VALUE=""></OPTION><%=sDeptsLookUp%></SELECT>
                  &nbsp;&nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Departments List"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Contact</FONT></TD>
                <TD>
                  <INPUT TYPE="text" SIZE="34" NAME="tx_contact" VALUE="<% if (oPrj.get(DB.tx_contact)!=null) out.write(oPrj.getString(DB.tx_contact)); %>" onkeypress="return false;">
                  &nbsp;&nbsp;<A HREF="javascript:reference(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Contacts List"></A>
                </TD>
              </TR>
<% } %>             
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">Description</FONT></TD>
                <TD><TEXTAREA NAME="de_project" ROWS="5" COLS="40" STYLE="font-family:Arial;font-size:9pt"><% if (oPrj.get(DB.de_project)!=null) out.write(oPrj.getString(DB.de_project)); %></TEXTAREA></TD>
              </TR>
              <TR>
                <TD COLSPAN="2"><HR></TD>
              </TR>
              <TR>
                <TD ALIGN="right"></TD>
                <TD>
                  <BR>
<% if (bIsGuest) { %>
                  <INPUT TYPE="button" CLASS="pushbutton" STYLE="WIDTH:80" ACCESSKEY="s" TITLE="ALT+s" VALUE="Clone" onclick="alert ('Your privilege level as guest does not allow you to perform this action')">
<% } else { %>                  
                  <INPUT TYPE="submit" CLASS="pushbutton" STYLE="WIDTH:80" ACCESSKEY="s" TITLE="ALT+s" VALUE="Clone">
<% } %>
                  &nbsp;&nbsp;&nbsp;
                  <INPUT TYPE="button" CLASS="closebutton" STYLE="WIDTH:80" ACCESSKEY="c" TITLE="ALT+c" VALUE="Close" onClick="javascript:window.parent.close()">
                </TD>
              </TR>              
            </TABLE>
          </TD>
        </TR>
      </TABLE> 
      </CENTER>
    </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>