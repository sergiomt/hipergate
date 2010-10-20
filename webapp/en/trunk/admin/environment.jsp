<%@ page import="java.io.IOException,java.net.URLDecoder,java.util.Set,java.util.Iterator,com.knowgate.misc.Environment,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
    
  if (request.getParameter("refresh")!=null) {
    Environment.refresh();
  }
  
  String sSkin = "xp";
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Local Cache Inspector</TITLE>
  <LINK REL="stylesheet" TYPE="text/css" HREF="../skins/xp/styles.css">
</HEAD>

<BODY >
<%@ include file="../common/header.jspf" %>
<BR>
<FONT FACE="Arial,Helvetica,sans-serif">
<%

  Iterator oVars, oProfiles = Environment.getProfilesSet().iterator();
  String sProfileName, sVarName;
  
  while (oProfiles.hasNext()) {
    sProfileName = oProfiles.next().toString();
    
    out.write ("<TABLE BORDER=1><TR><TD COLSPAN=2><B><BIG>" + sProfileName + "</BIG></B></TD></TR>");
    
    oVars = Environment.getProfileVarSet(sProfileName).iterator();
    
    while (oVars.hasNext()) {
      sVarName = oVars.next().toString();
			if (!sVarName.equals("dbpassword") && !sVarName.equals("mail.password") && !sVarName.equals("filepassword"))
        out.write ("<TR><TD><B>" + sVarName + "</B></TD><TD>" + Environment.getProfileVar(sProfileName, sVarName) + "</TD></TR>");

    } // wend
    out.write ("</TABLE><BR>");
  } // wend
%></TABLE>
</FONT>
<BR>
<FORM METHOD="get" ACTION="cache.jsp"><INPUT TYPE="hidden" NAME="refresh" VALUE="1"><INPUT TYPE="submit" VALUE="Refresh Environments"></FORM>
</BODY>
</HTML>
