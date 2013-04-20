<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/dbbind.jsp" %>
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
  
  // 01. Authenticate user session by checking cookies
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // 02. Add no-cache headers
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // 03. Get parameters

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_term = request.getParameter("gu_term");
  String gu_parent = request.getParameter("gu_parent");
  String tx_parent = "";
  String bo_mainterm = "1";
  String gu_rootterm = null;
  
  Term oTerm = new Term();
  Term oPrnt = new Term();
  
  String sSelLang = "", sCountriesLookUp = "", sScopeLookUp = "";
    
  JDCConnection oConn = null;
    
  try {
    
    oConn = GlobalDBBind.getConnection("term_edit");
    
    sSelLang = GlobalDBLang.toHTMLSelect(oConn, sLanguage);
    
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);

    sScopeLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_thesauri_lookup", gu_workarea, DB.id_scope, sLanguage);

    if (null!=gu_term) {
      oTerm.load(oConn, new Object[]{gu_term});

      gu_rootterm = oTerm.getString(DB.gu_rootterm);
      
      bo_mainterm = String.valueOf(oTerm.getShort(DB.bo_mainterm));

      if (null==gu_parent) gu_parent = oTerm.getParent(oConn);      
    }

    if (null!=gu_parent) {
      oPrnt = new Term();
      if (!oPrnt.load(oConn, new Object[]{gu_parent}))
        throw new SQLException("Could not find parent "+gu_parent);
      if (oPrnt.isNull(DB.tx_term))
        throw new SQLException(DB.tx_term+" for parent "+gu_parent+" is null");      
      tx_parent = oPrnt.getString(DB.tx_term);
      oPrnt = null;
    }
    
    oConn.close("term_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("term_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Example Form</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      // ------------------------------------------------------
              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_table_lookup&id_language=" + getUserLanguage() + "&id_section=tx_field&tp_control=2&nm_control=sel_field&nm_coding=tx_field", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
	    // window.open("...
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      // 09. Fields values validation.

      function validate() {
        var frm = window.document.forms[0];

	if (rtrim(frm.tx_term.value)=="") {
	  alert ("Singular text for term is mandatory");
	  return false;
	}

<%      if (null==gu_term && null!=gu_parent) { %>
		  
	  if (!frm.relationship[0].checked && !frm.relationship[1].checked) {
	    alert("You must select a relation type: child or synonym");
	    return false;
	  }

	  if (frm.relationship[1].checked) {
	    frm.gu_synonym.value = frm.gu_parent.value;
	  }
<% } %>

	frm.tx_term.value = frm.tx_term.value.toUpperCase();

	frm.tx_term2.value = frm.tx_term2.value.toUpperCase();
	
        frm.id_language.value = getCombo(frm.sel_language);

        frm.id_scope.value = getCombo(frm.sel_scope);
                
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];

        setCombo(frm.sel_language,"<%out.write(oTerm.getStringNull(DB.id_language,sLanguage));%>");

        setCombo(frm.sel_scope,"<%out.write(oTerm.getStringNull(DB.id_scope,""));%>");

        return false;
      } // validate;
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" LEFTMARGIN="8" onLoad="setCombos()">
  <FORM NAME="" METHOD="post" ACTION="term_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_parent" VALUE="<%=(gu_parent==null ? "" : gu_parent)%>">
    <INPUT TYPE="hidden" NAME="gu_rootterm" VALUE="<%=(gu_rootterm==null ? "" : gu_rootterm)%>">
    <INPUT TYPE="hidden" NAME="gu_term" VALUE="<%=(gu_term==null ? "" : gu_term)%>">
    <INPUT TYPE="hidden" NAME="bo_mainterm" VALUE="<%=bo_mainterm%>">
    <INPUT TYPE="hidden" NAME="gu_synonym" VALUE="<%=oTerm.getStringNull(DB.gu_synonym,"")%>">
    <INPUT TYPE="hidden" NAME="id_term0" VALUE="<% if (!oTerm.isNull("id_term0")) out.write(String.valueOf(oTerm.getInt("id_term0"))); %>">
    <INPUT TYPE="hidden" NAME="id_term1" VALUE="<% if (!oTerm.isNull("id_term1")) out.write(String.valueOf(oTerm.getInt("id_term1"))); %>">
    <INPUT TYPE="hidden" NAME="id_term2" VALUE="<% if (!oTerm.isNull("id_term2")) out.write(String.valueOf(oTerm.getInt("id_term2"))); %>">
    <INPUT TYPE="hidden" NAME="id_term3" VALUE="<% if (!oTerm.isNull("id_term3")) out.write(String.valueOf(oTerm.getInt("id_term3"))); %>">
    <INPUT TYPE="hidden" NAME="id_term4" VALUE="<% if (!oTerm.isNull("id_term4")) out.write(String.valueOf(oTerm.getInt("id_term4"))); %>">
    <INPUT TYPE="hidden" NAME="id_term5" VALUE="<% if (!oTerm.isNull("id_term5")) out.write(String.valueOf(oTerm.getInt("id_term5"))); %>">
    <INPUT TYPE="hidden" NAME="id_term6" VALUE="<% if (!oTerm.isNull("id_term6")) out.write(String.valueOf(oTerm.getInt("id_term6"))); %>">
    <INPUT TYPE="hidden" NAME="id_term7" VALUE="<% if (!oTerm.isNull("id_term7")) out.write(String.valueOf(oTerm.getInt("id_term7"))); %>">
    <INPUT TYPE="hidden" NAME="id_term8" VALUE="<% if (!oTerm.isNull("id_term8")) out.write(String.valueOf(oTerm.getInt("id_term8"))); %>">
    <INPUT TYPE="hidden" NAME="id_term9" VALUE="<% if (!oTerm.isNull("id_term9")) out.write(String.valueOf(oTerm.getInt("id_term9"))); %>">

    <CENTER>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
	  <TR>	    
<% if (null==gu_term && null==gu_parent) {
     out.write ("	    <TD ALIGN=\"right\"><IMG SRC=\"../images/images/new16x16.gif\" BORDER=\"0\"></TD>\n");
     out.write ("	    <TD>\n");
     out.write ("	      <FONT CLASS=\"formplain\">New Root Term</FONT>");
     out.write ("	    </TD>\n");
   } else if (null==gu_term && null!=gu_parent) {
     out.write ("	    <TD></TD>\n");
     out.write ("	    <TD>\n");
     out.write ("	      <INPUT TYPE=\"radio\" NAME=\"relationship\">&nbsp;<FONT CLASS=\"formplain\">Son of&nbsp;" + tx_parent + "</FONT><BR>\n");
     out.write ("	      <INPUT TYPE=\"radio\" NAME=\"relationship\">&nbsp;<FONT CLASS=\"formplain\">Synonym of&nbsp;" + tx_parent + "</FONT>\n");
     out.write ("	    </TD>\n");
   }
%>
	    </TD>
	  </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="textsmall"><B>Singular</B></FONT></TD>
            <TD ALIGN="left" >
              <INPUT CLASS="combomini" TYPE="text" NAME="tx_term" MAXLENGTH="100" SIZE="30" STYLE="text-transform:uppercase" VALUE="<%=oTerm.getStringNull(DB.tx_term,"")%>">
              &nbsp;&nbsp;&nbsp;<FONT CLASS="textsmall">Plural</FONT>&nbsp;
              <INPUT CLASS="combomini" TYPE="text" NAME="tx_term2" MAXLENGTH="100" SIZE="30" STYLE="text-transform:uppercase" VALUE="<%=oTerm.getStringNull("tx_term","")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" ><FONT CLASS="textsmall">Language</FONT></TD>
            <TD ALIGN="left" >
              <SELECT CLASS="combomini" NAME="sel_language"><%=sSelLang%></SELECT>
              <INPUT TYPE="hidden" NAME="id_language" VALUE="<%=oTerm.getStringNull(DB.id_language,"")%>">
              &nbsp;&nbsp;&nbsp;&nbsp;
              <FONT CLASS="textsmall">Scope</FONT>
              &nbsp;
              <SELECT CLASS="combomini" NAME="sel_scope"><OPTION VALUE="all">all</OPTION></SELECT>
              <INPUT TYPE="hidden" NAME="id_scope" VALUE="<%=oTerm.getStringNull(DB.id_scope,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="textsmall"><B>Description</B></FONT></TD>
            <TD ALIGN="left" >
              <INPUT CLASS="combomini" TYPE="text" NAME="de_term" MAXLENGTH="200" SIZE="60" VALUE="<%=oTerm.getStringNull(DB.de_term,"")%>">
            </TD>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
    </CENTER>
  </FORM>
</BODY>
</HTML>
