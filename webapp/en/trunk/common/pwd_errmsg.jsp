<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><%

request.setCharacterEncoding("UTF-8");
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

  String sTitle = request.getParameter("title")!=null ? request.getParameter("title") : "";
  String sDesc = request.getParameter("desc")!=null ? request.getParameter("desc") : "";
  String sResume = request.getParameter("resume")!=null ? request.getParameter("resume") : "";
%>
<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <TITLE>hipergate :: <% out.write(sTitle); %></TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    var action = "<%=sResume%>";
    
    function resume() {
      if (action=="_back")
        window.history.back();
      else if (action=="_close")
        window.close();
      else if (action=="_topclose")
        top.close();
      else
        window.document.location = action;
    }
  //-->
  </SCRIPT>
</HEAD>
<BODY  SCROLL="no" TOPMARGIN="16" MARGINHEIGHT="16">
  <TABLE ALIGN="CENTER" WIDTH="90%" BGCOLOR="#000080">
    <TR><TD>
      <FONT FACE="Arial,Helvetica,sans-serif" COLOR="white" SIZE="2"><B><%=sTitle%></B></FONT>
    </TD></TR>
    <TR><TD>
      <TABLE WIDTH="100%" BGCOLOR="#FFFFFF">
        <TR><TD>
          <TABLE BGCOLOR="#FFFFFF" BORDER="0" CELLSPACING="8" CELLPADDING="8">
            <TR VALIGN="middle">
              <TD><IMG SRC="../images/images/yield.gif" BORDER="0"></TD>
              <TD><FONT CLASS="textplain"><%=sDesc%></FONT></TD>
	    </TR>
	  </TABLE>
        </TD></TR>
<% if (!sResume.equals("_none")) { %>
        <TR><TD ALIGN="center">
          <FORM>
            <INPUT TYPE="button" CLASS="pushbutton" VALUE="OK" onclick="resume()">
          </FORM>
        </TD></TR>
<% } %>
      </TABLE>
    </TD></TR>    
  </TABLE>
</BODY>
</HTML>