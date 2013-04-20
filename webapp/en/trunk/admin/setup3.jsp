<%@ page import="java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.hipergate.datamodel.ModelManager" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/cookies.jspf" %><% 

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

  String sCnf = request.getParameter("cnf");

  DBBind oDBB = new DBBind(sCnf);  
  JDCConnection oConn = null;

  String sInstalledVersion = null;
  int iInstalledVersion = 0;
  boolean bKVersion = false;
  
  try {
    oConn = oDBB.getConnection("setup3");
    
    sInstalledVersion = DBBind.getDataModelVersion(oConn);
    iInstalledVersion = DBBind.getDataModelVersionNumber(oConn);
    
    bKVersion = oDBB.exists(oConn, DB.k_version, "U");

    oConn.close("setup3");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("setup3");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (NullPointerException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("setup3");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  oConn = null;
%>
<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/registration.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--      

    function skipRegistration() {
    	if (window.confirm("Are you sure that you want to skip product registration?"))
    	  hideLayer("registration");
    }

    function confirmDrop() {
			var frm = document.forms[0];
      var dropall = window.confirm("Are you sure that you want to completely wip all the information on the database?");      
      if (dropall) {
			  frm.bdrop.disabled = frm.bback.disabled = true;
        window.parent.frames[1].document.location.href = "setup3_do.jsp?cnf=<%=sCnf%>&dropall=true&version=0";
        showLayer("processing");
      }
    }

    function createDataModel() {
			var frm = document.forms[0];
			frm.bcreate.disabled = frm.bback.disabled = true;
    	var pag = document.getElementById("wholepage");
      showLayer("processing");
      document.getElementById("registration").style.display="block";
      return true;
    }
    
    function setCombos() {
      var frm = document.forms[1];
      hideLayer("processing");
      setCombo(frm.id_country, "<%=getNavigatorLanguage(request).equals("en") ? "us" : getNavigatorLanguage(request)%>");
    }
  //-->
  </SCRIPT>
</HEAD>
<BODY onload="setCombos()">
<!-- Installed version : <%=String.valueOf(iInstalledVersion) %> -->
<TABLE WIDTH="98%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Setup Wizard</FONT></TD></TR></TABLE> 
<BR>
<DIV ID="wholepage" STYLE="z-index:1">
<FONT CLASS="textplain">
<BIG>Datamodel creation</BIG>
<BR><BR>
<% if (0!=iInstalledVersion) out.write ("Previous installed version&nbsp;" + sInstalledVersion + " (" + String.valueOf(iInstalledVersion) + ")"); %>
</FONT>
<FORM ACTION="setup3_do.jsp" TARGET="setupoutput" onsubmit="return createDataModel()">
<INPUT TYPE="hidden" NAME="cnf" VALUE="<%=sCnf%>">
<INPUT TYPE="hidden" NAME="version" VALUE="<%=iInstalledVersion%>">
<INPUT TYPE="button" NAME="bback" VALUE="Previous" onclick="window.document.location.href='setup2.jsp';"> 
&nbsp;&nbsp;
<% if (iInstalledVersion==21000 || iInstalledVersion==30000 || iInstalledVersion==40000 || iInstalledVersion==50000 || iInstalledVersion==55000 || iInstalledVersion==60000) { %>
  <INPUT TYPE="submit" VALUE="Update from version <%=sInstalledVersion%>" onclick="showLayer('processing')">
  &nbsp;&nbsp;
  <INPUT TYPE="button" NAME="bdrop" VALUE="Erase datamodel" onclick="confirmDrop()">
<% } else if (iInstalledVersion==70000) { %>
  &nbsp;&nbsp;
  <INPUT TYPE="button" NAME="bdrop" VALUE="Erase datamodel" onclick="confirmDrop()">
  <BR><BR>
  <FONT FACE="Arial,Helvetica,sans-serif" COLOR="red" SIZE="2">It is not possible to create the datamodel because there is already another one</FONT>
<% } else if (iInstalledVersion==0 && bKVersion) { %>
  <BR/><BR/>
  <FONT FACE="Arial,Helvetica,sans-serif" COLOR="red" SIZE="2">It was not possible to get the version of the former datamodel, please check k_version table</FONT>
  <BR/><BR/>
  <A TARGET="_top" HREF="sql.htm"><FONT FACE="Arial,Helvetica,sans-serif">Go to SQL Query Tool</FONT></A>
<% } else { %>
  <INPUT TYPE="submit" NAME="bcreate" VALUE="Create datamodel" onclick="createDataModel()">
<% } %>
</FORM>
<DIV ID="processing" NAME="processing" STYLE="z-index:0">
<FONT FACE="Arial,Helvetica,sans-serif" COLOR="red" SIZE="2">
  <B>
  PROCESSING DATAMODEL
  <BR>
  PLEASE WAIT  
  <BR>
  DO NOT CLOSE BROWSER NOR PRESS BACK BUTTON
  </B>
</FONT>
</DIV>
<%@ include file="../common/registration.jspf" %>
</DIV>
<DIV ID="reglink"></DIV>
</BODY>
</HTML>