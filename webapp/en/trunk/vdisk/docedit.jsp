<%@ page import="java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %><%@ include file="../methods/cookies.jspf" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
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
  String id_product = request.getParameter("id_product")!=null ? request.getParameter("id_product") : "";
  String id_location = request.getParameter("id_location");
  
  String id_user = getCookie (request, "userid", null);
  String nm_product;
  String de_product;
  String id_language;
  String vs_stamp;
  String gu_blockedby = "";
  String nm_blockedby = "";
  
  String xfile;

  DBSubset oVersions = null;
  Product oProd;  
  ProductLocation oLoca;
  JDCConnection oConn = GlobalDBBind.getConnection("docedit");
  
  String sSelLang = GlobalDBLang.toHTMLSelect(oConn, sLanguage);
  
  if (id_product.length()>0) {
    oProd = new Product(oConn, id_product);

    oVersions = oProd.getLocations(oConn);
    
    nm_product = oProd.getString(DB.nm_product);
    de_product = oProd.getStringNull(DB.de_product,"");
    id_language = oProd.getStringNull(DB.id_language,"");
    gu_blockedby = oProd.getStringNull(DB.gu_blockedby,"");
    
    if (gu_blockedby.length()>0) {
      String sColVal;
      PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"=?",
      																								 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, gu_blockedby);
      ResultSet oRSet = oStmt.executeQuery();
      oRSet.next();
      sColVal = oRSet.getString(1);
      if (!oRSet.wasNull()) nm_blockedby += sColVal;
      sColVal = oRSet.getString(2);
      if (!oRSet.wasNull()) nm_blockedby += " " + sColVal;
      sColVal = oRSet.getString(3);
      if (!oRSet.wasNull()) nm_blockedby += " " + sColVal;
    } // fi gu_blockedby

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
  }
  else {
    nm_product = "";
    de_product = "";
    xfile = "";
    id_language = sLanguage;
    vs_stamp = ""; 
    gu_blockedby = "";
  }
  
  oConn.close("docedit");  
%>
  <!-- +-----------------------+ -->
  <!-- | Edición de documentos | -->
  <!-- | © KnowGate 2001       | -->
  <!-- +-----------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
   
  <TITLE>hipergate :: Document Edition</TITLE>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      var frm = document.forms[0];

      if (frm.localfile.value.length==0) {
        alert ("Must specify a local file");
        return false;      
      }
      
      if (frm.nm_product.value.length==0) {
        alert ("Must specify a name for document");
        return false;
      }
      
      frm.id_language.value = getCombo(frm.sel_language);
      
      if (frm.vs_stamp.value.length==0) {
        var dtNow = new Date();
        
        frm.vs_stamp.value = String(dtNow.getFullYear()) + "-" + String(dtNow.getMonth()+1) + "-" + String(dtNow.getDate()) + " " + String(dtNow.getHours()) + ":" + String(dtNow.getMinutes());
      }
      
      return true;
    }    
    
    // --------------------------------------------------------
    
    function selectCategory() {
      window.open("pickdipu.jsp?inputid=id_category&inputtr=tr_category", "pickcategory", "toolbar=no,directories=no,menubar=no,resizable=no,width=320,height=460");
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

    // --------------------------------------------------------
    
    function editVersion() {
      var frm = document.forms[0];

      if (frm.sel_stamp.options.selectedIndex>0) {
	      if (getCombo(frm.sel_stamp)!=frm.gu_location.value)
	      window.document.location.href = "docedit.jsp?id_category=" + getURLParam("id_category") + "&tr_category=" + getURLParam("tr_category") + "&id_product=" + getURLParam("id_product") + "&id_location=" + getCombo(frm.sel_stamp);
      } // fi ()
    } // editVersion
    
  //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    function setCombos() {
      var frm = document.forms[0];
      
      setCombo(frm.sel_language, "<%=id_language%>");
      
<%    if (id_product.length()>0) { %>
        setCombo(frm.sel_stamp, "<%=vs_stamp%>");
<% } %>

    }
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4" onLoad="setCombos()">
  <TABLE WIDTH="460"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Document Edition</FONT></TD></TR></TABLE>
  <FORM NAME="linkedit" ENCTYPE="multipart/form-data" METHOD="post" ACTION="docedit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_user" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="gu_owner" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="id_product" VALUE="<% out.write(id_product); %>">
    <INPUT TYPE="hidden" NAME="gu_blockedby" VALUE="<% out.write(gu_blockedby); %>">
    <INPUT TYPE="hidden" NAME="id_category" VALUE="<% out.write(request.getParameter("id_category")); %>">
    <INPUT TYPE="hidden" NAME="id_previous_cat" VALUE="<% out.write(request.getParameter("id_category")); %>">
<% if (id_product.length()>0) { %>
    <INPUT TYPE="hidden" NAME="chk_keepcheckedout" VALUE="1">
<% } %>    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">Category</FONT></TD>
            <TD ALIGN="left" WIDTH="310">
              <INPUT TYPE="text" NAME="tr_category" MAXLENGTH="30" SIZE="34" DISABLED="true" VALUE="<% out.write(request.getParameter("tr_category")); %>">&nbsp;
      	      <% if (id_product.length()>0 && (gu_blockedby.equals(id_user) || gu_blockedby.length()==0)) { %>
              <A HREF="#" onclick="selectCategory()" CLASS="formplain">Change</A>
              <% } %>
            </TD>
          </TR>  
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">Document Name:</FONT></TD>
            <TD WIDTH="310">
              <INPUT TYPE="text" NAME="nm_product" MAXLENGTH="50" SIZE="34" VALUE="<% out.write(nm_product); %>">
            </TD>
          </TR>  
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="130"><FONT CLASS="formstrong">File:</FONT></TD>
            <TD WIDTH="310">
              <INPUT TYPE="FILE" NAME="localfile" MAXLENGTH="254" SIZE="24" onchange="setDocTitle()">
            </TD>
          </TR>  
<% if (id_product.length()>0) { %> 
          <TR>
            <TD VALIGN="bottom" ALIGN="right" VALIGN="top" WIDTH="130">
              <FONT CLASS="textsmall">Current File:</FONT>
            </TD>
	    <TD ALIGN="left">
	      <FONT CLASS="textsmall"><%=xfile%></FONT>
	      <A HREF="../servlet/HttpBinaryServlet?id_product=<%=id_product%>"><IMG SRC="../images/images/download.gif" WIDTH="20" HEIGHT="16" BORDER="0" ALT="Open/Download Document"></A>
	      <A HREF="../servlet/HttpBinaryServlet?id_product=<%=id_product%>" CLASS="formstrong">Download</FONT></A></TD>
	  </TR>
<% } %>
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
<% if (id_product.length()>0) {
     out.write("	      <SELECT NAME=\"sel_stamp\" onclick=\"editVersion()\"><OPTION VALUE=\"\"></OPTION>");
     for (int v=0; v<oVersions.getRowCount(); v++) {
       out.write("<OPTION VALUE=\"" + oVersions.getString(DB.gu_location,v) + "\">" + oVersions.getStringNull(DB.vs_stamp,v,"") + "</OPTION>");
     } // next
     out.write("</SELECT>");
   } %>
	          </TD>
          </TR>           
<% if (nm_blockedby.length()>0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="130" CLASS="formstrong">Checked-out by</TD>
            <TD WIDTH="310" CLASS="formplain"><%=nm_blockedby%></TD>
   				</TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">Description:</FONT></TD>
            <TD WIDTH="310"><TEXTAREA NAME="de_product" COLS="32" ROWS="3"><% out.write(de_product); %></TEXTAREA></TD>
          </TR>
          <TR>
<% if (id_product.length()==0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="130"></TD>
            <TD WIDTH="310" CLASS="formplain"><INPUT TYPE="checkbox" NAME="chk_keepcheckedout" VALUE="1">&nbsp;Keep checked-out</TD>
          </TR>
          <TR>
<% } %>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
    	    <TD WIDTH="130">&nbsp;</TD>
    	    <TD WIDTH="310">
      	      <% if (id_product.length()==0) { %>
                <INPUT TYPE="submit" ACCESSKEY="a" VALUE="New" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+a">&nbsp;&nbsp;
              <% } else if (gu_blockedby.equals(id_user) || gu_blockedby.length()==0) { %>
                <INPUT TYPE="submit" ACCESSKEY="m" VALUE="Modify" CLASS="pushbutton" TITLE="ALT+m">&nbsp;&nbsp;
      	      <% } %>
	              <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	    
          </TR>           
        </TABLE>
      </TD></TR>
    </TABLE>

  </FORM>
</BODY>
</HTML>
