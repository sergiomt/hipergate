<%@ page import="java.net.URLDecoder,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %>
<%@ include file="../methods/cookies.jspf" %>
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

  String sLanguage = getNavigatorLanguage(request);
  String id_language = sLanguage;
  String id_product = request.getParameter("id_product")!=null ? request.getParameter("id_product") : "";
  String n_product;
  String de_product;
  String url;

  Product oProd;  
  ProductLocation oLoca;
  JDCConnection oConn = GlobalDBBind.getConnection("linkedit");

  String sSelLang = GlobalDBLang.toHTMLSelect(oConn, sLanguage);
  
  if (id_product.length()>0) {
    oProd = new Product(oConn, id_product);
    
    n_product = oProd.getString(DB.nm_product);
    de_product = oProd.getStringNull(DB.de_product,"");
    id_language = oProd.getStringNull(DB.id_language,sLanguage);
    
    oLoca = oProd.getFirstLocation(oConn);

    if (null!=oLoca)
      url = oLoca.getURL();
    else
      url = "";
    
    oLoca = null;
    oProd = null;
  }
  else {
    n_product = "";
    de_product = "";
    url = "";
  }
  
  oConn.close("linkedit");  
%>
  <!-- +--------------------+ -->
  <!-- | Edición de enlaces | -->
  <!-- | © KnowGate 2001    | -->
  <!-- +--------------------+ -->


<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Link Edition</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT> 
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      var frm = document.forms[0];

      if (frm.url.value.length==0) {
        alert ("Must specify an URL for link");
        return false;      
      }
      
      if (frm.n_product.value.length==0) {
        alert ("Must specify a name for link");
        return false;
      }
      
      frm.id_language.value = getCombo(frm.sel_language);
      
      return true;
    }    

    function viewLink() {
      var url = document.forms[0].url.value.toLowerCase();
      var wnm = document.forms[0].n_product.value;
      
      if ("ftp://"!=url.substr(0,6) && "http://"!=url.substr(0,7) && "https://"!=url.substr(0,8))
        url = "http://" + url;

      if (url.length>0)
	if (wnm.length>0)
          window.open(url,wnm);
        else
          window.open(url);
    }
    
    function selectCategory() {
      window.open("pickdipu.jsp?inputid=id_category&inputtr=tr_category", "pickcategory", "toolbar=no,directories=no,menubar=no,resizable=no,width=320,height=460");
    }
        
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4" onLoad="setCombo(document.forms[0].sel_language, '<%=id_language%>')">
  <TABLE WIDTH="480"><TR><TD CLASS="strip1"><FONT CLASS="title1">Link Edition</FONT></TD></TR></TABLE>
  <FORM NAME="linkedit" METHOD="post" ACTION="linkedit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_product" VALUE="<% out.write(id_product); %>">

    <INPUT TYPE="hidden" NAME="id_category" VALUE="<% out.write(request.getParameter("id_category")); %>">
    <INPUT TYPE="hidden" NAME="id_previous_cat" VALUE="<% out.write(request.getParameter("id_category")); %>">
    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="150"><FONT CLASS="formstrong">Category</FONT></TD>
            <TD ALIGN="left" WIDTH="290"><INPUT TYPE="text" NAME="tr_category" MAXLENGTH="30" SIZE="28" DISABLED="true" VALUE="<% out.write(request.getParameter("tr_category")); %>">&nbsp;<A HREF="#" onclick="selectCategory()" CLASS="formplain">Change</FONT></A></TD>
          </TR>  
          <TR>
            <TD ALIGN="right" WIDTH="150"><FONT CLASS="formstrong">Link Name:</FONT></TD>
            <TD WIDTH="290"><INPUT TYPE="text" NAME="n_product" MAXLENGTH="50" SIZE="34" VALUE="<% out.write(n_product); %>"></TD>
          </TR>  
          <TR>
            <TD ALIGN="right" WIDTH="150"><FONT CLASS="formstrong">URL:</FONT></TD>
            <TD WIDTH="290">
              <INPUT TYPE="text" NAME="url" MAXLENGTH="384" SIZE="34" VALUE="<% out.write(url); %>">
	      <A HREF="#" onClick="viewLink()"><IMG SRC="../images/images/viewlink.gif" WIDTH="16" HEIGHT="16" ALT="View content in new window" BORDER="0" oncontextmenu="return false;"></A>
            </TD>
          </TR>  
          <TR>
            <TD ALIGN="right" WIDTH="150"><FONT CLASS="formstrong">Language:</FONT></TD>            
            <TD WIDTH="290">
	      <INPUT TYPE="hidden" NAME="id_language">
              <SELECT NAME="sel_language"><OPTION VALUE="" SELECTED><% out.write (sSelLang); %></SELECT></TD>
          </TR>  
          <TR>
            <TD ALIGN="right" WIDTH="150"><FONT CLASS="formstrong">Description:</FONT></TD>
            <TD WIDTH="290"><TEXTAREA NAME="de_product" COLS="32" ROWS="3"><% out.write(de_product); %></TEXTAREA></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
    	    <TD WIDTH="150">&nbsp;</TD>
    	    <TD WIDTH="290">
      	      <% if (id_product.length()==0) { %>
                <INPUT TYPE="submit" ACCESSKEY="a" VALUE="New" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+a">&nbsp;&nbsp;
              <% } else { %>
                <INPUT TYPE="submit" ACCESSKEY="m" VALUE="Modify" CLASS="pushbutton" TITLE="ALT+m">&nbsp;&nbsp;
      	      <% } %>
	      <INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onClick="self.close()">
    	      <BR><BR>
    	    </TD>	    
          </TR>           
        </TABLE>
      </TD></TR>
    </TABLE>

  </FORM>
</BODY>
</HTML>
