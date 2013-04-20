<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<% 
/*
  Copyright (C) 2004-2010  Know Gate S.L. All rights reserved.

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
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY >
<FORM ACTION="setup2.jsp">
<BR/>
<TABLE SUMMARY="Setup Welcome Box" WIDTH="480" HEIGHT="320" ALIGN="center" BORDER="0" CELLSPACING="0" CELLPADDING="0" BACKGROUND="../images/images/setup/setup.gif">
	<TR HEIGHT="80">
		<TD WIDTH="40" ROWSPAN="7"></TD>
		<TD WIDTH="180" ROWSPAN="2"></TD>
		<TD></TD>
  </TR>
	<TR><TD CLASS="title1">Setup Wizard</TD></TR>
	<TR><TD COLSPAN="2" HEIGHT="20"></TD></TR>
	<TR><TD COLSPAN="2" CLASS="textplain">Welcome to hipergate Setup Wizard</TD></TR>
	<TR><TD COLSPAN="2" CLASS="textplain">The setup wizard will guide you over the following steps:</TD></TR>
	<TR>
		<TD COLSPAN="2" CLASS="textplain"><B>1.</B>&nbsp;Base libraries verification
      <BR/>
      <B>2.</B>&nbsp;hipergate.cnf file configuration
      <BR/>
      <B>3.</B>&nbsp;Database connection test
      <BR/>
      <B>4.</B>&nbsp;Datamodel creation</TD>
  </TR>
	<TR><TD WIDTH="180"></TD><TD VALIGN="top"><INPUT TYPE="submit" CLASS="pushbutton" VALUE="Start" onclick="window.parent.frames[1].document.location='setup1_do.jsp'"></TD></TR>
</TABLE>
<CENTER><FONT CLASS="textsmall">&copy; Know Gate S.L. 2003-2011</FONT></CENTER> 
</FORM>
</BODY>
</HTML>