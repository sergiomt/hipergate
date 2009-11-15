<%@ page import="java.net.URLDecoder,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.Contact,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
  String id_product = nullif(request.getParameter("id_product"));
  String pg_product = nullif(request.getParameter("pg_product"));
  String id_user = getCookie (request, "userid", null);
  String gu_contact = request.getParameter("gu_contact");
  
  String nm_product;
  String de_product;
  String id_language;
  String xfile;

  Product oProd;  
  ProductLocation oLoca;
  JDCConnection oConn = GlobalDBBind.getConnection("attachedit");

  String sSelLang = GlobalDBLang.toHTMLSelect(oConn, sLanguage);
  String sContactFullName = "";
  Contact oCont;
  
  if (null!=gu_contact) {
    oCont = new Contact(oConn, gu_contact);
    sContactFullName = " para " + oCont.getStringNull(DB.tx_name, "") + " " + oCont.getStringNull(DB.tx_surname, "");
    oCont = null;
  }
  
  if (id_product.length()>0) {
    oProd = new Product(oConn, id_product);
    
    nm_product = oProd.getString(DB.nm_product);
    de_product = oProd.getStringNull(DB.de_product,"");
    id_language = oProd.getStringNull(DB.id_language,"");
    oLoca = oProd.getFirstLocation(oConn);

    if (null!=oLoca)
      xfile = oLoca.getStringNull("xfile","");
    else
      xfile = "";
    
    oLoca = null;
    oProd = null;
  }
  else {
    nm_product = "";
    de_product = "";
    id_language = sLanguage;
    xfile = "";
  }
  
  oConn.close("attachedit");  
%>
  <!-- +------------------------------------------------+ -->
  <!-- | Edit documents associated with an Individual | -->
  <!-- | © KnowGate 2003                                | -->
  <!-- +------------------------------------------------+ -->


<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/usrlang.js"></SCRIPT>   
  <TITLE>hipergate :: Attach File</TITLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      var frm = document.forms[0];

      if (frm.localfile.value.length==0) {
        alert ("Must specify a local file");
        return false;      
      }
      
      if (frm.nm_product.value.length==0) {
        alert ("Must specify a name for file");
        return false;
      }
      
      frm.id_language.value = getCombo(frm.sel_language);
      
      return true;
    }    
    
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
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
  <!--
    function setCombos() {
      setCombo(document.forms[0].sel_language, "<%=id_language%>");   
    }
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4" onLoad="setCombos()">
  <TABLE WIDTH="460"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Attach File<%=sContactFullName%></FONT></TD></TR></TABLE>
  <FORM NAME="linkedit" ENCTYPE="multipart/form-data" METHOD="post" ACTION="attach_edit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_owner" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="id_user" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="id_product" VALUE="<% out.write(id_product); %>">
    <INPUT TYPE="hidden" NAME="pg_product" VALUE="<% out.write(pg_product); %>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<% out.write(gu_contact); %>">
    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">Document Name:</FONT></TD>
            <TD WIDTH="310"><INPUT TYPE="text" NAME="nm_product" MAXLENGTH="50" SIZE="34" VALUE="<% out.write(nm_product); %>"></TD>
          </TR>  
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="130"><FONT CLASS="formstrong">File:</FONT></TD>
            <TD BGCOLOR="#E5E5E5" WIDTH="310">
              <INPUT TYPE="FILE" NAME="localfile" MAXLENGTH="254" SIZE="24" onchange="setDocTitle()">
            </TD>
          </TR>  
<% if (id_product.length()>0) { %> 
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="130"><FONT CLASS="textsmall">Current File:</FONT></TD>
	    <TD BGCOLOR="#E5E5E5" ALIGN="left">
	      <FONT CLASS="textsmall"><%=xfile%></FONT>
	      <A HREF="../servlet/HttpBinaryServlet?id_product=<%=id_product%>"><IMG SRC="../images/images/download.gif" WIDTH="20" HEIGHT="16" BORDER="0" ALT="Open/Download Document"></A>
	      <A HREF="../servlet/HttpBinaryServlet?id_product=<%=id_product%>" CLASS="formstrong">Download</A></TD>
	  </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formplain">Language:</FONT></TD>            
            <TD WIDTH="310">
	      <INPUT TYPE="hidden" NAME="id_language">
              <SELECT NAME="sel_language"><OPTION VALUE="" SELECTED><% out.write (sSelLang); %></SELECT></TD>
          </TR>  
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formplain">Description:</FONT></TD>
            <TD WIDTH="310"><TEXTAREA NAME="de_product" COLS="32" ROWS="3"><% out.write(de_product); %></TEXTAREA></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
    	    <TD WIDTH="130">&nbsp;</TD>
    	    <TD WIDTH="310">
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
