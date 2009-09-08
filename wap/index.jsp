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

final java.util.ResourceBundle Labels =  java.util.ResourceBundle.getBundle("Labels", request.getLocale());

%><?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
"http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <card id="login" newcontext="true" title="<%=Labels.getString("title_login")%>">
    <%=Labels.getString("lbl_welcome")%>
    <fieldset>
      <%=Labels.getString("lbl_email")%><br/>
      <input type="text" name="email" value="admisiones1@eoi.es" />
      <br/>
      <%=Labels.getString("lbl_passw")%><br/>
      <input type="password" name="passw" value="mides13" />
    </fieldset>
    
    <anchor><%=Labels.getString("a_enter")%>
      <go href="login.jsp" accept-charset="UTF-8" method="post">
        <postfield name="nickname" value="$(email)"/>
        <postfield name="pwd_text" value="$(passw)"/>
      </go>
    </anchor>
  </card>
</wml>
