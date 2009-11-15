<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
%>

<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY >
<TABLE WIDTH="98%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Setup Wizard</FONT></TD></TR></TABLE> 
<BR>
<TABLE>
  <TR>
    <TD><IMG SRC="../images/images/setup/setup.gif" WIDTH="134" HEIGHT="134" ALT="" BORDER="0"></TD>
    <TD>
      <FONT CLASS="textplain">
      Welcome to hipergate Setup Wizard
      <BR>
      The setup wizard will guide you over the following steps:
      <BR><BR>
      <B>1.</B>&nbsp;Base libraries verification
      <BR>
      <B>2.</B>&nbsp;hipergate.cnf file configuration
      <BR>
      <B>3.</B>&nbsp;Database connection test
      <BR>
      <B>4.</B>&nbsp;Datamodel creation
      <BR>
      </FONT>
    </TD>
  </TR>
  <TR>
    <TD></TD>
    <TD><FORM ACTION="setup1.jsp"><INPUT TYPE="submit" CLASS="pushbutton" VALUE="Start"></FORM></TD>
  </TR>
</TABLE>
</BODY>
</HTML>