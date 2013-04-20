<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);  
  String sWorkArea = getCookie(request,"workarea","");

  String id_language = request.getParameter("id_language");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");
  String id_form = nullif(request.getParameter("id_form"), "0");

  String sQryStr = "?nm_table=k_duties_lookup&id_language=" + id_language + "&id_section=nm_resource&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding + "&id_form=" + id_form;

  JDCConnection oConn = null;
    
  try {
    oConn = GlobalDBBind.getConnection("resource_lookup_new");      
    oConn.close("resource_lookup_new");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("resource_lookup_new");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Add resource</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/autosuggest20.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      
      function validate() {
        var frm = window.document.forms[0];

			  if (frm.vl_lookup.value.length==0) {
			    alert ("No valid resource has been specified");
			    return false;	
			  }

<%      for (int l=0; l<DBLanguages.SupportedLanguages.length; l++) out.write("        frm.tr_"+DBLanguages.SupportedLanguages[l]+".value=frm.nm_resource.value;\n"); %>
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%" SUMMARY="Form Title">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Add resource</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="../common/lookup_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=sWorkArea%>">
    <INPUT TYPE="hidden" NAME="vl_lookup" VALUE="">
    <INPUT TYPE="hidden" NAME="nm_table" VALUE="k_duties_lookup">
    <INPUT TYPE="hidden" NAME="id_section" VALUE="nm_resource">
    <INPUT TYPE="hidden" NAME="id_language" VALUE="<%=id_language%>">
    <INPUT TYPE="hidden" NAME="tp_control" VALUE="<%=tp_control%>">
    <INPUT TYPE="hidden" NAME="nm_control" VALUE="<%=nm_control%>">
    <INPUT TYPE="hidden" NAME="nm_coding" VALUE="<%=nm_coding%>">
    <INPUT TYPE="hidden" NAME="id_form" VALUE="<%=id_form%>">
    
<%  for (int l=0; l<DBLanguages.SupportedLanguages.length; l++) out.write("    <INPUT TYPE=\"hidden\" NAME=\"tr_"+DBLanguages.SupportedLanguages[l]+"\">\n"); %>

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formstrong">What kind of resource must be added?</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="radio" NAME="tp_resource" VALUE="0" CHECKED></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain">A user</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="radio" NAME="tp_resource" VALUE="1"></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain">An employee</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="radio" NAME="tp_resource" VALUE="2"></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain">An external contact</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="radio" NAME="tp_resource" VALUE="3"></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain">An external company</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="radio" NAME="tp_resource" VALUE="4"></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain">A supplier</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="radio" NAME="tp_other" onclick="document.location='../common/lookup_new.jsp<%=sQryStr%>'"></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain">Other</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Name</TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_resource"></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onClick="window.parent.lookupup.location.href='resource_lookup_up.jsp<%=sQryStr%>';window.history.back();">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>  
</BODY>
<SCRIPT TYPE="text/javascript">
    <!--
	  var qry = new Array ("nm_table=k_users&nm_valuecolumn=gu_user&nm_textcolumn="+"<%=Gadgets.URLEncode(DBBind.Functions.strCat(new String[]{"nm_user","tx_surname1"},' '))%>"+"&tx_where="+"<%=Gadgets.URLEncode(DBBind.Functions.strCat(new String[]{"nm_user","tx_surname1"},' '))%>",
												 "nm_table=k_fellows&nm_valuecolumn=gu_fellow&nm_textcolumn="+"<%=Gadgets.URLEncode(DBBind.Functions.strCat(new String[]{"tx_name","tx_surname"},' '))%>"+"&tx_where="+"<%=Gadgets.URLEncode(DBBind.Functions.strCat(new String[]{"tx_name","tx_surname"},' '))%>",
												 "nm_table=k_contacts&nm_valuecolumn=gu_contact&nm_textcolumn="+"<%=Gadgets.URLEncode(DBBind.Functions.strCat(new String[]{"tx_name","tx_surname"},' '))%>"+"&tx_where="+"<%=Gadgets.URLEncode(DBBind.Functions.strCat(new String[]{"tx_name","tx_surname","sn_passport"},' '))%>",
												 "nm_table=k_companies&nm_valuecolumn=gu_company&nm_textcolumn=nm_legal&tx_where="+"<%=Gadgets.URLEncode(DBBind.Functions.strCat(new String[]{"nm_legal","nm_commercial","id_legal"},' '))%>",
												 "nm_table=k_suppliers&nm_valuecolumn=gu_supplier&nm_textcolumn=nm_legal&tx_where="+"<%=Gadgets.URLEncode(DBBind.Functions.strCat(new String[]{"nm_legal","nm_commercial","id_legal"},' '))%>");
    	  
    var asr = new AutoSuggest("nm_resource", { script:"'../common/autocomplete.jsp?gu_workarea=<%=sWorkArea%>&'+qry[getCheckedValue(document.forms[0].tp_resource)]+'&'", varname:"tx_like", form:0, minchars:2, callback: function (obj) { document.forms[0].vl_lookup.value = obj.id; } });
    
    //-->
</SCRIPT>

</HTML>
