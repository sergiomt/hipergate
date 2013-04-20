<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1Âº2 28050 Madrid (Spain)

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

  String nm_table = request.getParameter("nm_table");
  String id_language = request.getParameter("id_language");
  String id_section = request.getParameter("id_section");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");  
  String sDocType = request.getParameter("doctype");
  String sTitle = "Web Site";
  if (sDocType.compareTo("newsletter")==0) sTitle = "NewsLetter";
  String sQryStr = "?nm_table="+ nm_table + "&id_language=" + id_language + "&id_section=" + id_section + "&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding;
%>
<HTML>
  <HEAD>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
    <TITLE>hipergate :: New<%=sTitle%> Step 1 of 2</TITLE>
  </HEAD>
  <!-- -->
  <BODY  LEFTMARGIN="4" TOPMARGIN="4" SCROLL="no">
    <TABLE width="100%"BORDER="0" CELLSPACING="0" CELLPADDING="2">
      <TR width="100%" VALIGN="middle"><TD align="left" CLASS="striptitle"><FONT CLASS="title1">New&nbsp;<%=sTitle%></FONT></TD><TD ALIGN="right" CLASS="striptitle"><FONT CLASS="title1">Step 1 of 2</font></TD></TR>
      <TR><TD ALIGN="left" colspan="2" class="formplain">Choose the document type and language and enter your comments&nbsp;To proceed to the next step, click on the Next button</TD></TR>
    </TABLE>
  </BODY>
</HTML>