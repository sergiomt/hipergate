<%@ page import="java.util.HashMap,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
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
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // [~//Obtener el skin actual~]
  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
    
  // [~//Obtener el dominio y la workarea~]
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 
  String screen_width = request.getParameter("screen_width");
  String gu_list = request.getParameter("gu_list");

    
  // [~//Cadena de de filtrado (claúsula WHERE)~]
        
  String sField = request.getParameter("field")==null ? "" : request.getParameter("field");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
    
  int iCompanyCount = 0;
  DBSubset oCompanies = null;        
  HashMap oStatusMap = null;
  String sOrderBy;
  int iOrderBy;  
  int iSkip;
    
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (nullif(request.getParameter("orderby")).length()!=0)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "5,4,3";   
  
  iOrderBy = 1;
     
  // [~//Obtener una conexiónd el pool a bb.dd. (el nombre de la conexión es arbitrario)~]
  JDCConnection oConn = GlobalDBBind.getConnection("memberlisting");
    
  try {
    if (sWhere.length()>0) {
      
      	oCompanies = new DBSubset (DB.k_member_address+" b", 
      				   DB.gu_company + "," + DB.gu_contact + "," + DB.nm_legal + "," + DB.tx_name + "," + DB.tx_surname + ", " + DB.tx_email,
      				   DB.gu_workarea + "='" + gu_workarea + "' " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), 0);      				 
    }
    else if (sFind.length()==0 || sField.length()==0) {
     
    	oCompanies = new DBSubset (DB.k_member_address+" b", 
      				 DB.gu_company + "," + DB.gu_contact + "," + DB.nm_legal + "," + DB.tx_name + "," + DB.tx_surname + ", " + DB.tx_email,
      				 DB.gu_workarea + "='" + gu_workarea + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), 0);      				 
    }
      //oCompanies.setMaxRows(iMaxRows);
      iCompanyCount = oCompanies.load (oConn, iSkip);
    
    oConn.close("memberlisting"); 
  }
  catch (SQLException e) {  
    oCompanies = null;
    oConn.close("memberlisting");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  oConn = null;  
%>

<HTML>
<HEAD>
  <TITLE>hipergate :: Member Listing</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript">
<%
          // [~//Escribir los nombres de instancias en Arrays JavaScript~]
          // [~//Estos arrays se usan en las llamadas de borrado múltiple.~]
          
          out.write("var jsInstances = new Array(");
            for (int i=0; i<iCompanyCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"check-" + i + "\"");
            }
          out.write(");\n        ");
%>
	  function insertSelected() {
	   var frm = document.forms[0];
	   var lst =new String("");
	   for (var c=0; c<jsInstances.length; c++)
	     if (frm.elements[jsInstances[c]].checked) lst += frm.elements['guid-'+c].value+ ",";
	   if (lst=="") {
	   	alert("Debe seleccionar algun contacto");
	   	return(false);
	   }
	   else {
	        
	   	lst = lst.substr(0,lst.length-1);
	   	url = "member_wizard_03.jsp?gu_list=<%=gu_list%>&members="+lst;
	   	self.document.location = url;
	   	return(true);
	   }
	   
	  } //insertSelected

          function selectAll() {
          // [~//eleccionar/Deseleccionar todas las instancias~]
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsInstances.length; c++)                        
            eval ("frm.elements['" + jsInstances[c] + "'].click()");
          } // selectAll()
  </SCRIPT>
</HEAD>

<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="//setCombos()">
    <FORM METHOD="post">
      <TABLE><TR><TD><IMG SRC="../skins/<%=sSkin%>/hglogopeq.jpg" BORDER="0" ALIGN="MIDDLE"></TD></TR></TABLE>
      <TABLE WIDTH="90%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Contact Listing</FONT></TD></TR></TABLE>  
      <TABLE><TR><TD><IMG SRC="../images/images/crm/person_add.jpg" BORDER="0" ALIGN="MIDDLE">&nbsp;<A HREF="javascript:insertSelected()" CLASS="linkplain">Insert selected</A></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=request.getParameter("maxrows")%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=request.getParameter("skip")%>">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=request.getParameter("gu_list")%>">
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Contacts</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Address</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select all"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
        </TR>
<%
	  for (int i=0; i<iCompanyCount; i++) {
%>
            <TR HEIGHT="14">
              <TD CLASS="strip<%=(i%2)+1%>" VALIGN="MIDDLE">
<%
  String sContact;
  String sCompany;
  String sType;
  String sPicture;
  
  if (oCompanies.getString(4,i)==null)
    if (oCompanies.getString(3,i)==null)
    {
    	sContact = new String("");  
    	sType = new String("Company");
    }
    else
    {
        sContact = oCompanies.getString(3,i);
        sType = new String("Person");
    }
  else
    if (oCompanies.getString(3,i)==null)
    {
        sContact = oCompanies.getString(4,i);
        sType = new String("Person");
    }
    else
    {
    	sContact = oCompanies.getString(4,i) + ", " + oCompanies.getString(3,i);
    	sType = new String("Person");
    }
  
  if (oCompanies.getString(2,i)==null)
  	sCompany = "";
  else
    sCompany = "&nbsp;[" + oCompanies.getString(2,i) + "]";
  if (sType.compareTo("Person")==0)
    sPicture = new String("../images/images/crm/person.jpg");
  else
    sPicture = new String("../images/images/crm/building.jpg");
%>              
                  <IMG SRC="<%=sPicture%>" WIDTH="24" HEIGHT="24" BORDER="0" ALIGN="MIDDLE">&nbsp;<%=sContact%><%=sCompany%>
              </TD>
              <TD CLASS="strip<%=(i%2)+1%>" VALIGN="MIDDLE"><%=nullif(oCompanies.getString(5,i),"")%></TD>
              <TD CLASS="strip<%=((i%2)+1)%>" VALIGN="MIDDLE" ALIGN="center"><INPUT <%=(oCompanies.getString(5,i)==null?"disabled TITLE=\"This entry may not be selected because it does not have an address.\"":"")%> VALUE="1" TYPE="checkbox" NAME="check-<%=i%>">
              <INPUT TYPE="HIDDEN" NAME="guid-<%=i%>" VALUE="'<%=nullif(oCompanies.getString(0,i),"NULL")%>-<%=nullif(oCompanies.getString(1,i),"NULL")%>'">
            </TR>
<%
          } // next(i)
%>
      </TABLE>
    </FORM>
    <!-- DynFloat -->
    <DIV id="divHolder" style="width:100px;height:20px;z-index:200;visibility:hidden;position:absolute;top:31px;left:0px"></DIV>
    <FORM name="divForm"><input type="hidden" name="divField" value=""></FORM>
    <SCRIPT src="../javascript/dynfloat.js"></SCRIPT>    
    <!-- DynFloat -->

    <!-- RightMenuBody -->
    <DIV class="menuDiv" id="rightMenuDiv">
      <TABLE border="0" cellpadding="0" cellspacing="0" width="100">
        <TR height="1">
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR height="1">
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#FFFFFF"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#FFFFFF"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR>
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#FFFFFF"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#D6D3CE">
            <!-- Opciones -->
            <DIV class="menuCP" onMouseOver="menuHighLight(this)" onMouseOut="menuHighLight(this)" onClick="modifyCompany(jsCompanyId, jsCompanyNm)">Open</DIV>
            <DIV id="menuOpt01" class="menuE" onMouseOver="menuHighLight(this)" onMouseOut="menuHighLight(this)" onClick="clone()">Duplicate</DIV>
            <HR size="2" width="98%">
            <DIV id="menuOpt02" class="menuE" onMouseOver="menuHighLight(this)" onMouseOut="menuHighLight(this)" onClick="listContacts()">View Individuals</DIV>
            <DIV id="menuOpt03" class="menuE" onMouseOver="menuHighLight(this)" onMouseOut="menuHighLight(this)" onClick="listAddresses()">View Addresses</DIV>
            <!-- /Opciones -->
          </TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR height="1">
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR height="1">
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
      </TABLE>
    </DIV>
    <!-- /RightMenuBody -->    
</BODY>
</HTML>
