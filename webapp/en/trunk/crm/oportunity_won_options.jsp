<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.crm.Oportunity" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

  final int ProjectManager=12,Shop=20, Hipermail=21;

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "oportunity_won_options";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_oportunity = request.getParameter("gu_oportunity");

  String id_user = getCookie(request, "userid", "");
        
  JDCConnection oConn = null;
  
  Oportunity oOprt = new Oportunity();

  DBSubset oTemplateProjs = new DBSubset(DB.k_projects, DB.gu_project+","+DB.nm_project,
  																			 DB.gu_owner+"=? AND "+DB.id_parent+" IS NULL AND "+DB.dt_start+" IS NULL AND "+
  																			 DB.gu_company+" IS NULL AND "+DB.gu_contact+" IS NULL ORDER BY 2", 100);
  int nTemplateProjs = 0;
  
  DBSubset oShops = new DBSubset(DB.k_shops, DB.gu_shop+","+DB.nm_shop,
  															 DB.gu_workarea+"=? AND "+DB.bo_active+"<>0 ORDER BY 2", 10);
  															 
  int nShops = 0;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

    oOprt.load(oConn, new Object[]{gu_oportunity});
    
    nTemplateProjs = oTemplateProjs.load(oConn, new Object[]{gu_workarea});
		
		nShops = oShops.load(oConn, new Object[]{gu_workarea});
		
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Additional Options for Oportunity</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
            
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        var rcp;
        
<% if ((iAppMask & (1<<ProjectManager))!=0 && nTemplateProjs>0) { %>
        if (frm.bo_project.checked) {
          if (frm.sel_template.selectedIndex<=0) {
            alert ("A project template must be chosen");
            return false;
          }
          if (frm.dt_start.value.length>0 && !isDate(frm.dt_start.value,"d")) {
            alert ("Start date is not valid");
            return false;          
          }
        } // fi (bo_project.checked)
<% }
   if ((iAppMask & (1<<Hipermail))!=0) { %>
				
        if (frm.bo_email.checked) {
          if (frm.tx_subject.value.length==0) {
            alert ("The e-mail subject is required");
            return false;
          }
          if (frm.tx_recipients.value.length==0) {
            alert ("At least one e-mail recipient is required");
            return false;
          }
          rcp = frm.tx_recipients.value.replace(/;/g,",");
					rcp = rcp.split(",");
					for (var r=0; r<=rcp.length; r++) {
					  if (!check_email(rcp[r])) {
					    alert (rcp[r]+" "+"The e-mail address is not valid");
							return false;
					  } // fi
					} // next
          frm.tx_recipients.value = frm.tx_recipients.value.replace(/;/g,",").toLowerCase();
        } // fi (frm.bo_email.checked)
<% }
   if ((iAppMask & (1<<Shop))!=0) { %>

<% } %>

        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Additional Options for Oportunity</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="oportunity_won_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_oportunity" VALUE="<%=gu_oportunity%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=oOprt.getStringNull(DB.gu_company,"")%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=oOprt.getStringNull(DB.gu_contact,"")%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
<% if ((iAppMask & (1<<ProjectManager))!=0 && nTemplateProjs>0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="checkbox" NAME="bo_project" VALUE="1" onclick="if (this.checked) showLayer('div_template'); else hideLayer('div_template');"></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formstrong">Create project from template</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="370">
              <DIV ID="div_template" STYLE="visibility:hidden">
                <TABLE SUMMARY="Project Data" CLASS="formfront">
                  <TR>
                    <TD CLASS="formplain">Template</TD>
                    <TD><SELECT NAME="sel_template" CLASS="combomini"><OPTION VALUE=""></OPTION><% for (int p=0; p<nTemplateProjs; p++) out.write("<OPTION VALUE=\""+oTemplateProjs.getString(0,p)+"\">"+oTemplateProjs.getString(1,p)+"</OPTION>"); %></SELECT></TD>
                  </TR>
                  <TR>
                    <TD CLASS="formplain">Start</TD>
                    <TD><INPUT TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="12">&nbsp;<A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A></TD>
                  </TR>
                </TABLE>
              </DIV>
            </TD>
          </TR>
<% }
   if ((iAppMask & (1<<Hipermail))!=0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="checkbox" NAME="bo_email" VALUE="1" onclick="if (this.checked) showLayer('div_email'); else hideLayer('div_email');"></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formstrong">Send a notification e-mail</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="370">
              <DIV ID="div_email" STYLE="visibility:hidden">
                <TABLE SUMMARY="e-mail Data" CLASS="formfront">
                  <TR>
                    <TD CLASS="formplain">Subject</TD>
                    <TD><INPUT TYPE="text" NAME="tx_subject" MAXLENGTH="100" SIZE="50" VALUE="New Sale Alert <%=oOprt.getStringNull(DB.tl_oportunity,"")%>"></TD>
                  </TR>
                  <TR>
                    <TD CLASS="formplain">Recipients</TD>
                    <TD><INPUT TYPE="text" NAME="tx_recipients" MAXLENGTH="255" SIZE="50"></TD>
                  </TR>
                  <TR>
                    <TD CLASS="formplain">Text</TD>
                    <TD><TEXTAREA NAME="tx_body" ROWS="4" COLS="40"></TEXTAREA></TD>
                  </TR>
                </TABLE>
              </DIV>
            </TD>
          </TR>
<% }
   if ((iAppMask & (1<<Shop))!=0 && nShops>0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="checkbox" NAME="bo_order" VALUE="1" onclick="if (this.checked) showLayer('div_shops'); else hideLayer('div_shops');"></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formstrong">Open order edition form</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="370">
              <DIV ID="div_shops" STYLE="visibility:hidden">
                <TABLE SUMMARY="Shops Data" CLASS="formfront">
                  <TR>
                    <TD CLASS="formplain">Catalog</TD>
                    <TD><SELECT NAME="sel_shop"><% out.write("<OPTION VALUE=\""+oShops.getString(0,0)+"\" SELECTED=\"selected\">"+oShops.getString(1,0)+"</OPTION>"); for (int s=1; s<nShops; s++) out.write("<OPTION VALUE=\""+oShops.getString(0,s)+"\">"+oShops.getString(1,s)+"</OPTION>"); %></SELECT></TD>
                  </TR>
                </TABLE>
              </DIV>
            </TD>
          </TR>
<% } %>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
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
