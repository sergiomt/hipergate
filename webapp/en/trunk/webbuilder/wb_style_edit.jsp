<%@ page import="com.knowgate.misc.*,java.io.File,java.lang.*,java.util.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.dataxslt.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.db.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<% response.addHeader ("Pragma", "no-cache"); response.addHeader ("cache-control", "no-store"); response.setIntHeader("Expires", 0); %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
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
 
  
  String id_domain = getCookie(request, "domainid", "0");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = nullif(request.getParameter("gu_pageset"));
  
  String file_template = request.getParameter("file_template");
  String file_pageset = request.getParameter("file_pageset");
  
  XMLDocument oXMLDocument = new XMLDocument(file_pageset);
  XMLDocument oXMLTemplate = new XMLDocument(file_template);
  
  String xml = oXMLDocument.toString();
  String xmlTemplate = oXMLTemplate.toString();
  
  // Montar selects de color y fuente a partir de xml de metadatos
  
  // Obtener combos
  int iBeginComboColor = xmlTemplate.indexOf("<colors>");
  int iEndComboColor = xmlTemplate.indexOf("</colors>") + 9;
  int iBeginComboFont = xmlTemplate.indexOf("<fonts>");
  int iEndComboFont = xmlTemplate.indexOf("</fonts>") + 8;
  
  String comboColor = xmlTemplate.substring(iBeginComboColor,iEndComboColor);
  comboColor = Gadgets.replace(comboColor,"<colors>","<select class=\"textsmall\" name=\"color\">");
  comboColor = Gadgets.replace(comboColor,"</colors>","</select>");
  comboColor = Gadgets.replace(comboColor,"<color>","<option>");
  comboColor = Gadgets.replace(comboColor,"</color>","</option>");
  
  String comboFont = xmlTemplate.substring(iBeginComboFont,iEndComboFont);
  comboFont = Gadgets.replace(comboFont,"<fonts>","<select class=\"textsmall\" name=\"font\">");
  comboFont = Gadgets.replace(comboFont,"</fonts>","</select>");
  comboFont = Gadgets.replace(comboFont,"<family>","<option>");
  comboFont = Gadgets.replace(comboFont,"</family>","</option>");
  
  // Obtener color y fuente actuales
  int iBeginColor = xml.indexOf("<color>") + 7;
  int iEndColor = xml.indexOf("</color>");
  int iBeginFont = xml.indexOf("<font>") + 6;
  int iEndFont = xml.indexOf("</font>");
  
  String color = xml.substring(iBeginColor,iEndColor);
  String font = xml.substring(iBeginFont,iEndFont);
%>
<html>
<head>
<TITLE>hipergate :: Select styles</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>      
  <SCRIPT LANGUAGE="JavaScript">
  <!--
    function loadOptions(selectedColor, selectedFont) {
     for (i=0; i<document.all.color.options.length; i++){
      document.all.color.options[i].value=document.all.color.options[i].text;
      if (document.all.color.options[i].text==selectedColor) document.all.color.options[i].selected=true;
     }
     for (i=0; i<document.all.font.options.length; i++){
      document.all.font.options[i].value=document.all.font.options[i].text;
      if (document.all.font.options[i].text==selectedFont) document.all.font.options[i].selected=true;
     }
    }
   -->
  </SCRIPT>
</head>
<BODY  TOPMARGIN="4" MARGINHEIGHT="0" onload="loadOptions('<%=color%>','<%=font%>')">  
  <CENTER>
  <TABLE BORDER="0" CELLSPACINGH="0" CELLPADDING="0"><TR><TD WIDTH="560" CLASS="striptitle"><FONT CLASS="title1">Select styles</FONT></TD></TR></TABLE>
<br>
<span class="textsmall">Select color and font for texts.</span><br><br>
<form name="frmSelStyle" action="wb_style_persist.jsp" method="get">
<input type="hidden" name="file_template" value="<%=file_template%>">
<input type="hidden" name="file_pageset" value="<%=file_pageset%>">
<input type="hidden" name="gu_pageset" value="<%=gu_pageset%>">
<input type="hidden" name="gu_workarea" value="<%=gu_workarea%>">
<input type="hidden" name="doctype" value="<%=request.getParameter("doctype")%>">
<table border="0" cellspacing="0" cellpadding="0">
<tr><td class="textplain">Color</td><td>&nbsp;&nbsp;&nbsp;</td><td class="textplain">Font</td></tr>
<tr><td><%=comboColor%></td>
<td>&nbsp;&nbsp;&nbsp;</td>
<td><%=comboFont%></td>
</tr>
<tr><td colspan="3" align="center"><br><br><input class="pushbutton" type="submit" name="btnSubmit" value="Save"></td></tr>
</table>
</select>
</form>
</CENTER>
</body>
</html>
