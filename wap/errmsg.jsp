<%@ page language="java" session="false" contentType="text/vnd.wap.wml;charset=UTF-8" %><%

/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

  request.setCharacterEncoding("UTF-8");

  String sTitle = request.getParameter("title")!=null ? request.getParameter("title") : "";
  String sDesc = request.getParameter("desc")!=null ? request.getParameter("desc") : "";
  String sResume = request.getParameter("resume")!=null ? request.getParameter("resume") : "_back";

%><?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
"http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <card id="errmsg" title="<%=sTitle%>">
    <%=sDesc%>
    <br/><br/>
<% if (sResume.equals("_back")) { %>
	  <do type="accept" label="Back">
      <prev />
    </do><%
} else { %>
      <anchor>[~Atrás~] <go href="<%=sResume%>" /></anchor>
<% } %>
  </card>
</wml>
