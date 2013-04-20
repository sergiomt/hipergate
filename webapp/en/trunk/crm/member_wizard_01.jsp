<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
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
  String gu_list = request.getParameter("gu_list");

  response.sendRedirect("../common/qbf.jsp?memberselection=1&tp_memberselection=table&requesttype=members&queryspec=listmember&gu_workarea=" + gu_workarea + "&gu_list=" + gu_list);
  
%>

<HTML>
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      setCookie(response,"workarea",gu_workarea);
      
      function setInputs() {
	var frm = document.forms[0];
	frm.id_domain.value = getURLParam("id_domain");
	frm.n_domain.value = getURLParam("n_domain");
	frm.gu_workarea.value = getURLParam("gu_workarea");
	frm.memberselection.value = getURLParam("memberselection");
	
	if (frm.memberselection.value=="1") frm.listtype[0].checked = true;
	if (frm.memberselection.value=="2") frm.listtype[1].checked = true;
	
	if (frm.memberselection.value=="" || frm.memberselection.value==null) {
		frm.listtype[0].checked = true;
		frm.memberselection.value=="1";
	}
      }
    //-->
  </SCRIPT>
  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function validate() {
        var frm = document.forms[0];
                
        if (frm.memberselection.value=="" || frm.memberselection.value=="null") {
          alert ("Must choose a type of list to be generated");
          return false;
        }
        
        return true;
      }
    //-->
  </SCRIPT>
  <TITLE>hipergate :: Add members to a Distribution List - Step 1/3</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setInputs()">
  <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>  
  <FORM NAME="" METHOD="post" ACTION="../common/qbf.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="memberselection" VALUE="1">
    <INPUT TYPE="hidden" NAME="request_type" VALUE="members">
    <INPUT TYPE="hidden" NAME="queryspec" VALUE="listmember">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=request.getParameter("gu_list")%>">
    <TABLE BORDER="0"><TR><TD><IMG SRC="../skins/<%=sSkin%>/hglogopeq.jpg" BORDER="0" ALIGN="MIDDLE"></TD></TR></TABLE>  
    <TABLE WIDTH="100%"><TR><TD WIDTH="310px" CLASS="striptitle"><FONT CLASS="title1">Insert Members - Step 1 of 3</FONT></TD></TR></TABLE>
    <BR>
    <CENTER>
    <TABLE WIDTH="310px" CLASS="formback">
      <TR><TD ALIGN="left" CLASS="formstrong">Insert Members</TD></TR>
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="left">
              <INPUT TYPE="radio" NAME="tp_memberselection" VALUE="table" onClick="document.forms[0].memberselection.value='1';" checked>&nbsp;<FONT CLASS="formstrong">Select from contact list</FONT>
              <BR>
              <FONT CLASS="textsmall">Allows to insert members in lists.</FONT>
              <BR>
              <INPUT TYPE="radio" NAME="tp_memberselection" VALUE="query" onClick="document.forms[0].memberselection.value='2';">&nbsp;<FONT CLASS="formstrong">Select from Query</FONT>              
              <BR>
              <FONT CLASS="textsmall">Allows to insert members proceeding from results of a query.</FONT>
            </TD>
          </TR>
        </TABLE>
      </TD></TR>
    </TABLE>
    </CENTER>
    <BR>
    <TABLE WIDTH="310px">
      <TR><TD ALIGN="right"><INPUT TYPE="button" CLASS="closebutton" VALUE="Cancel" STYLE="width:100px" onClick="self.close()">&nbsp;<INPUT TYPE="submit" CLASS="pushbutton" VALUE="Next >>" STYLE="width:100px"></TD></TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>