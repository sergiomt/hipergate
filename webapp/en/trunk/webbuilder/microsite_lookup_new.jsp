<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  String nm_table = request.getParameter("nm_table");
  String id_language = request.getParameter("id_language");
  String id_section = request.getParameter("id_section");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");  
  
  String sQryStr = "?nm_table="+ nm_table + "&id_language=" + id_language + "&id_section=" + id_section + "&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding;

%>
<HTML>
  <HEAD>
    <TITLE>hipergate ::</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');                  
      
      // ------------------------------------------------------
      
      function validate() {
        var frm = document.forms[0];
        var str;
        
        if (frm.tr_<%=id_language%>.value.length==0) {
          alert ("Description is mandatory");
          return false;
        }

	str = frm.vl_lookup.value;

        if (str.length==0) {
          alert ("Value is mandatory");
          return false;
        }
	
        if (str.indexOf("'")>0 || str.indexOf('"')>0 || str.indexOf("*")>0 || str.indexOf("?")>0 || str.indexOf("&")>0 || str.indexOf("^")>0 || str.indexOf("¨")>0 || str.indexOf(";")>0) {
          alert ("Value contains invalid characters");
          return false;
        }
        
        window.parent.lookupup.location.href = "lookup_up.jsp<%=sQryStr%>";
        
        return true;
      } // validate()
      
      //-->
    </SCRIPT>  
  </HEAD>
  
  <BODY  LEFTMARGIN="4" TOPMARGIN="4" SCROLL="no">
    <CENTER><FONT CLASS="title1">A&ntilde;adir Valor</FONT></CENTER>
    <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>
    <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>
    <BR>
    <FORM METHOD="POST" ACTION="lookup_store.jsp<%=sQryStr%>&xxx=1" onsubmit="return validate()">
      <CENTER>
      <TABLE CLASS="formback">
        <TR><TD>
          <TABLE CLASS="formfront">
            <TR>
              <TD ALIGN="right"><SPAN onmouseover="popover('Descriptive text shown<BR>when value is chosen')" onmouseout="popout()"><FONT CLASS="formstrong">Description:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" MAXLENGTH="50" NAME="tr_<%=id_language%>"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><SPAN onmouseover="popover('Actual value stored internally at database')" onmouseout="popout()"><FONT CLASS="formstrong">Value:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" MAXLENGTH="250" NAME="vl_lookup"></TD>          
            </TR>
          </TABLE>
        </TD></TR>
      </TABLE>
      <BR>
      <INPUT TYPE="submit" VALUE="Guardar" CLASS="pushbutton" STYLE="width:80">&nbsp;&nbsp;<INPUT TYPE="button" VALUE="Cancel" CLASS="closebutton" onClick="window.parent.lookupup.location.href='lookup_up.jsp<%=sQryStr%>';window.history.back();">
      </CENTER>
    </FORM>
  </BODY>
</HTML>