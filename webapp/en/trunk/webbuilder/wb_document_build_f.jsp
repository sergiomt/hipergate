<%@ page import="com.knowgate.misc.Gadgets,java.util.Enumeration" session="false" contentType="text/html;charset=UTF-8" %>
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
    
    String sLocation = "wb_document_build.jsp?void=0";

    Enumeration e = request.getParameterNames();
    String p;
    while (e.hasMoreElements()) {
      p = (String) e.nextElement();
      sLocation += "&" + p + "=" + Gadgets.URLEncode(request.getParameter(p));    
    } // wend()
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <TITLE>hipergate :: Regenerate Documents</TITLE>
  </HEAD>
  <FRAMESET NAME="wb_build_top" ROWS="90,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="wb_build_orb" FRAMEBORDER="no" MARGINWIDTH="0" MARGINHEIGHT="0" NORESIZE SRC="wb_document_orb.html">
    <FRAME NAME="wb_build_doc" FRAMEBORDER="no" MARGINWIDTH="0" MARGINHEIGHT="0" NORESIZE SRC="<%=sLocation%>">
  </FRAMESET>
  <NOFRAMES>
      <BODY>
	<P>This page use frames, but your web browser does not handle them</P>
      </BODY>
  </NOFRAMES>
  </FRAMESET>
</HTML>
