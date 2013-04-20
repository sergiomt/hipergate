<%@ page import="java.net.URLDecoder,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %><%@ include file="../methods/cookies.jspf" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
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

  String sLanguage = getNavigatorLanguage(request);
  String id_product = request.getParameter("id_product");
  String id_location = request.getParameter("id_location");
  
  String id_user = getCookie (request, "userid", null);
  String nm_product;
  String de_product;
  String id_language;
  String vs_stamp;
  String gu_blockedby;
  
  String xfile;

  DBSubset oVersions = null;
  Product oProd;  
  ProductLocation oLoca;

  JDCConnection oConn = GlobalDBBind.getConnection("docheckin");
  
    String sSelLang = GlobalDBLang.toHTMLSelect(oConn, sLanguage);
  
    oProd = new Product(oConn, id_product);

    oVersions = oProd.getLocations(oConn);
    
    nm_product = oProd.getString(DB.nm_product);
    de_product = oProd.getStringNull(DB.de_product,"");
    id_language = oProd.getStringNull(DB.id_language,"");
    gu_blockedby = oProd.getStringNull(DB.gu_blockedby,"");
    
    if (null==id_location)
      oLoca = oProd.getFirstLocation(oConn);
    else
      oLoca = new ProductLocation(oConn, id_location);
      
    if (null!=oLoca)
      xfile = oLoca.getStringNull("xfile","");
    else
      xfile = "";
    
    vs_stamp = oLoca.getStringNull(DB.vs_stamp, "");
    
    oLoca = null;
    oProd = null;
  
  oConn.close("docheckin");  
%>
  <!-- +-----------------------+ -->
  <!-- | Proteger de documento | -->
  <!-- | © KnowGate 2008       | -->
  <!-- +-----------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>  
  <TITLE>hipergate :: Check-in Document</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>   
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      var frm = document.forms[0];

      if (frm.localfile.value.length==0) {
        alert ("A local file is required");
        return false;      
      }
      
      if (frm.nm_product.value.length==0) {
        alert ("A name for the document is required");
        return false;
      }
      
      frm.id_language.value = getCombo(frm.sel_language);
      
      if (frm.vs_stamp.value.length==0) {
        var dtNow = new Date();
        
        frm.vs_stamp.value = String(dtNow.getFullYear()) + "-" + String(dtNow.getMonth()+1) + "-" + String(dtNow.getDate()) + " " + String(dtNow.getHours()) + ":" + String(dtNow.getMinutes());
      }      
      return true;
    } // validate

    // --------------------------------------------------------
    
    function setDocTitle() {
      var frm = document.forms[0];
      var pth;
      var fnm;
      var dot;
      
      if (frm.localfile.value.length>0 && frm.nm_product.value.length==0) {
        pth = frm.localfile.value.split('\\');
        fnm = pth[pth.length-1];
        dot = fnm.lastIndexOf('.');
                
        frm.nm_product.value = fnm.substring(0,dot);        
      } // fi()
    } // setDocTitle()
    
  //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    function setCombos() {
      var frm = document.forms[0];      
      setCombo(frm.sel_language, "<%=id_language%>");
    }
  //-->
  </SCRIPT>
</HEAD>

<BODY SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4" onLoad="setCombos()">
  <TABLE WIDTH="460"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Check-in Document</FONT></TD></TR></TABLE>
  <FORM NAME="linkedit" ENCTYPE="multipart/form-data" METHOD="post" ACTION="docedit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_user" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="gu_owner" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="id_product" VALUE="<% out.write(id_product); %>">
    <INPUT TYPE="hidden" NAME="gu_blockedby" VALUE="<% out.write(gu_blockedby); %>">
    <INPUT TYPE="hidden" NAME="id_category" VALUE="<% out.write(request.getParameter("id_category")); %>">
    <INPUT TYPE="hidden" NAME="id_previous_cat" VALUE="<% out.write(request.getParameter("id_category")); %>">
    <INPUT TYPE="hidden" NAME="chk_keepcheckedout" VALUE="0">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">Dcoument Name:</FONT></TD>
            <TD WIDTH="310">
              <INPUT TYPE="text" NAME="nm_product" MAXLENGTH="50" SIZE="34" VALUE="<% out.write(nm_product); %>" TABINDEX="-1" onfocus="document.forms[0].localfile.focus()">
            </TD>
          </TR>  
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="130"><FONT CLASS="formstrong">File:</FONT></TD>
            <TD WIDTH="310">
              <INPUT TYPE="FILE" NAME="localfile" MAXLENGTH="254" SIZE="24" onchange="setDocTitle()">
            </TD>
          </TR>  
	        <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">Language:</FONT></TD>            
            <TD WIDTH="310">
	            <INPUT TYPE="hidden" NAME="id_language">
              <SELECT NAME="sel_language"><OPTION VALUE="" SELECTED><% out.write (sSelLang); %></SELECT></TD>
          </TR>
	        <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">Version:</FONT></TD>            
            <TD WIDTH="310">
              <INPUT TYPE="hidden" NAME="gu_location" VALUD="<% if (null!=id_location) out.write(id_location);%>">
	            <INPUT TYPE="text" NAME="vs_stamp" MAXLENGTH="16" SIZE="16" VALUE="<% out.write(vs_stamp); %>">
	          </TD>
          </TR>           
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">Description</FONT></TD>
            <TD WIDTH="310"><TEXTAREA NAME="de_product" COLS="32" ROWS="3"><% out.write(de_product); %></TEXTAREA></TD>
          </TR>
          <TR>
    	      <TD COLSPAN="2"><HR></TD>
  	      </TR>
          <TR>
    	    <TD WIDTH="130">&nbsp;</TD>
    	    <TD WIDTH="310">
              <% if (gu_blockedby.equals(id_user)) { %>
                <INPUT TYPE="submit" ACCESSKEY="m" VALUE="Check-in" CLASS="pushbutton" TITLE="ALT+p">&nbsp;&nbsp;
      	      <% } %>
	            <INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	        <BR><BR>
    	    </TD>	    
          </TR>           
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>
