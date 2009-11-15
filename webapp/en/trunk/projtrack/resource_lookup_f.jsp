<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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

  String id_language = request.getParameter("id_language").trim();
  String tp_control = request.getParameter("tp_control").trim();
  String nm_control = request.getParameter("nm_control").trim();
  String nm_coding = request.getParameter("nm_coding").trim();
  String id_form = nullif(request.getParameter("id_form"), "0");

  String sQryStr = "?id_language=" + id_language + "&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding + "&id_form=" + id_form;
  
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Select resource</TITLE>
  </HEAD>
  <FRAMESET NAME="lookuptop" ROWS="80,*,48" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="lookupup" FRAMEBORDER="no" MARGINWIDTH="0 MARGINHEIGHT="0" NORESIZE SRC="resource_lookup_up.jsp<%=sQryStr%>">
    <FRAME NAME="lookupmid" FRAMEBORDER="no" MARGINWIDTH="0 MARGINHEIGHT="0" NORESIZE SRC="resource_lookup_mid.jsp<%=sQryStr%>">
    <FRAME NAME="lookupdown" FRAMEBORDER="no" MARGINWIDTH="0 MARGINHEIGHT="0" NORESIZE SRC="../common/lookup_down.jsp">
    <NOFRAMES>
      <BODY>
        <P>This page uses frames but your browser does not support them</P>
      </BODY>
    </NOFRAMES>
  </FRAMESET>
</HTML>
