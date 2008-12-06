<%@ page import="java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DBBind,com.knowgate.hipergate.datamodel.ModelManager" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  String sCnf = request.getParameter("cnf");

  DBBind oDBB = new DBBind(sCnf);  
  JDCConnection oConn = null;

  String sInstalledVersion = null;
  int iInstalledVersion = 0;
  
  try {
    oConn = oDBB.getConnection("setup3");
    
    sInstalledVersion = DBBind.getDataModelVersion(oConn);
    iInstalledVersion = DBBind.getDataModelVersionNumber(oConn);
    
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
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
  <!--
    function confirmDrop() {
      var dropall = window.confirm("Are you sure that you want to completely wip all the information on the database?");
      
      if (dropall)
        window.parent.frames[1].document.location.href = "setup3_do.jsp?cnf=<%=sCnf%>&dropall=true&version=0";
        
      showLayer("processing");
    }
  //-->
  </SCRIPT>    
</HEAD>
<BODY  onload="hideLayer('processing')" METHOD="GET">
<TABLE WIDTH="98%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Setup Wizard : Step 3</FONT></TD></TR></TABLE> 
<BR><BR>
<FONT CLASS="textplain">
<BIG>Datamodel creation</BIG>
<BR>
<% if (0!=iInstalledVersion) out.write ("Previous installed version&nbsp;" + sInstalledVersion + " (" + String.valueOf(iInstalledVersion) + ")"); %>
</FONT>
<FORM ACTION="setup3_do.jsp" TARGET="setupoutput">
<INPUT TYPE="hidden" NAME="cnf" VALUE="<%=sCnf%>">
<INPUT TYPE="hidden" NAME="version" VALUE="<%=iInstalledVersion%>">
<INPUT TYPE="button" CLASS="pushbutton" VALUE="Previous" onclick="window.document.location.href='setup2.jsp';"> 
&nbsp;&nbsp;
<% if (iInstalledVersion==21000 || iInstalledVersion==30000) { %>
  <INPUT TYPE="submit" STYLE="background-color:steelblue;color:white;font-family:Arial,Helvetica,sans-serif;font-size:9pt;" VALUE="Update from version <%=sInstalledVersion%>" onclick="showLayer('processing')">
  &nbsp;&nbsp;
  <INPUT TYPE="button" STYLE="background-color:indianred;color:white;font-family:Arial,Helvetica,sans-serif;font-size:9pt;" VALUE="Erase datamodel" onclick="confirmDrop()">
<% } else if (iInstalledVersion==40000) { %>
  &nbsp;&nbsp;
  <INPUT TYPE="button" STYLE="background-color:indianred;color:white;font-family:Arial,Helvetica,sans-serif;font-size:9pt;" VALUE="Erase datamodel" onclick="confirmDrop()">
  <BR><BR>
  <FONT FACE="Arial,Helvetica,sans-serif" COLOR="red">It is not possible to create the datamodel because there is already another one</FONT>
<% } else { %>
  <INPUT TYPE="submit" STYLE="background-color:steelblue;color:white;font-family:Arial,Helvetica,sans-serif;font-size:9pt;" VALUE="Create datamodel" onclick="showLayer('processing')">
<% } %>
</FORM>
<DIV ID="processing" NAME="processing">
<FONT FACE="Arial,Helvetica,sans-serif" COLOR="red" SIZE="3">
  <B>
  PROCESSING DATAMODEL
  <BR>
  PLEASE WAIT  
  <BR>
  DO NOT CLOSE BROWSER NOR PRESS BACK BUTTON
  </B>
</FONT>
</DIV>
</BODY>
</HTML>