<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
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
    
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  boolean bLatinLanguage = (sLanguage.startsWith("es") || sLanguage.startsWith("en") || sLanguage.startsWith("fr") || sLanguage.startsWith("de") || sLanguage.startsWith("pt") || sLanguage.startsWith("nl") || sLanguage.startsWith("pl"));
  boolean bChineseTraditional = sLanguage.startsWith("tw");
  boolean bChineseSimplified = sLanguage.startsWith("cn");
  boolean bRussianLanguage = sLanguage.startsWith("ru");
  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Contatcs Loader</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function validate() {
        var frm = window.document.forms[0];

	      if (frm.textfile.value.length==0) {
	        alert ("Select a file to be loaded");
	        return false;
	      }

        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Contatcs Loader</FONT></TD></TR>
  </TABLE>  
  <FORM ENCTYPE="multipart/form-data" METHOD="post" ACTION="vcardloader2.jsp" onSubmit="return validate()">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Action</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_action"><OPTION VALUE="APPEND">Insert Only</OPTION><OPTION VALUE="UPDATE">Update</OPTION><OPTION VALUE="APPENDUPDATE" SELECTED="selected">Insert and Update</OPTION></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Character Set</FONT></TD>
            <TD ALIGN="left">
              <SELECT NAME="sel_encoding">
                <OPTION VALUE="UTF8">UTF-8</OPTION>
                <OPTION VALUE="UTF-16">UTF-16</OPTION>
                <OPTION VALUE="UnicodeBig">Sixteen-bit Unicode big endian with byte-order mark</OPTION>
                <OPTION VALUE="UnicodeBigUnmarked">Sixteen-bit Unicode big endian</OPTION>
                <OPTION VALUE="UnicodeLittle">Sixteen-bit Unicode little endian with byte-order mark</OPTION>
                <OPTION VALUE="UnicodeLittleUnmarked">Sixteen-bit Unicode little endian</OPTION>
                <OPTION VALUE="Cp1252">Windows Latin 1</OPTION>
                <OPTION VALUE="ISO8859_1" <%=bLatinLanguage ? "SELECTED" : ""%>>ISO 8859-1 Latin 1</OPTION>
                <OPTION VALUE="ISO8859_2">ISO 8859-1 Latin 2</OPTION>
                <OPTION VALUE="ISO8859_3">ISO 8859-1 Latin 3</OPTION>
                <OPTION VALUE="ISO8859_4">ISO 8859-1 Latin 4</OPTION>
                <OPTION VALUE="ISO8859_5" <%=bRussianLanguage ? "SELECTED" : ""%>>ISO 8859-5, Latin/Cyrillic</OPTION>
                <OPTION VALUE="ISO8859_6">ISO 8859-6, Latin/Arabic</OPTION>
                <OPTION VALUE="ISO8859_7">ISO 8859-7, Latin/Greek</OPTION>
                <OPTION VALUE="ISO8859_8">ISO 8859-8, Latin/Hebrew</OPTION>
                <OPTION VALUE="JIS0201">JIS X 0201, Japanese</OPTION>
                <OPTION VALUE="KOI8_R">KOI8-R, Russian</OPTION>
                <OPTION VALUE="ASCII">ASCII</OPTION>
                <OPTION VALUE="Cp437">MS-DOS</OPTION>
                <OPTION VALUE="Cp500">EBCDIC 500V1</OPTION>
                <OPTION VALUE="Big5" <%=bChineseTraditional ? "SELECTED" : ""%>>Big5 Traditional Chinese</OPTION>
                <OPTION VALUE="MS936" <%=bChineseSimplified ? "SELECTED" : ""%>>MS936 Windows Simplified Chinese</OPTION>
                <OPTION VALUE="MS950">MS950 Windows Traditional Chinese</OPTION>
                <OPTION VALUE="MS932">MS932 Windows Japanese</OPTION>
                <OPTION VALUE="MS874">MS874 Windows Thai</OPTION>
              </SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">File</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="FILE" NAME="textfile" SIZE="30"></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><A HREF="#" CLASS="linkplain" onclick="document.getElementById('advanced').style.display='block'">Opciones Avanzadas</A></TD>
	    <TD></TD>
          </TR>
          <TR>
            <TD></TD>
            <TD>
              <DIV ID="advanced" STYLE="display:none">
                <INPUT TYPE="TEXT" NAME="maxerrors" SIZE="4" VALUE="100" onkeypress="acceptOnlyNumbers(this)">&nbsp;<FONT CLASS="formplain">Max. Errors</FONT>
                <BR>
                <INPUT TYPE="CHECKBOX" NAME="loadlookups" VALUE="INSERTLOOKUPS" CHECKED>&nbsp;<FONT CLASS="formplain">Auto-load lookup tables</FONT>
                <BR>
                <INPUT TYPE="CHECKBOX" NAME="recoverable" VALUE="RECOVERABLE">&nbsp;<FONT CLASS="formplain">Execute in a single transaction</FONT>
              </DIV>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Next" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
