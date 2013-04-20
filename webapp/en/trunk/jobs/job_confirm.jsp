<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "job_confirm";
  
  final String sLanguage = getNavigatorLanguage(request);
  final String sSkin = getCookie(request, "skin", "xp");
  final boolean bMail = request.getParameter("id_command").equals("MAIL");

  final String sDtExecution = request.getParameter("dt_execution").equals("ASAP") ? "A soon as possible" : request.getParameter("dt_execution");

  String[] aLists = null;
  int iGuList = request.getParameter("tx_parameters").indexOf("gu_list:");
  if (iGuList>0) {
    int iComma = request.getParameter("tx_parameters").indexOf(",", iGuList+8);
    if (iComma>0)
      aLists = Gadgets.split(request.getParameter("tx_parameters").substring(iGuList+8,iComma),';');
    else
  	  aLists = Gadgets.split(request.getParameter("tx_parameters").substring(iGuList+8),';');
  }
  
  DBPersist oObj = new DBPersist(bMail ? DB.k_pagesets : DB.k_adhoc_mailings, "Newsletter");
  DBSubset oLst = new DBSubset(DB.k_lists, DB.tx_subject+","+DB.de_list, DB.gu_workarea+"=? AND "+DB.gu_list+" IN ('"+Gadgets.join(aLists,"','")+"')", 10);
  int nLst = 0;
      
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME,true);  

    oObj.load(oConn, new Object[]{request.getParameter("gu_pageset")});
    
    nLst = oLst.load(oConn, new Object[]{request.getParameter("gu_workarea")});
    
    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Sending Confirmation</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Sending Confirmation</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="job_store.jsp">
    <INPUT TYPE="hidden" NAME="target_dir" VALUE="<%=request.getParameter("target_dir")%>">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=request.getParameter("id_domain")%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=request.getParameter("gu_workarea")%>">
    <INPUT TYPE="hidden" NAME="gu_pageset" VALUE="<%=request.getParameter("gu_pageset")%>">    
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=request.getParameter("id_user")%>">    
    <INPUT TYPE="hidden" NAME="gu_job" VALUE="<%=request.getParameter("gu_job")%>">
    <INPUT TYPE="hidden" NAME="gu_job_group" VALUE="<%=request.getParameter("gu_job_group")%>">
    <INPUT TYPE="hidden" NAME="id_command" VALUE="<%=request.getParameter("id_command")%>">
    <INPUT TYPE="hidden" NAME="tx_parameters" VALUE="<%=request.getParameter("tx_parameters")%>">
    <INPUT TYPE="hidden" NAME="id_status" VALUE="<%=request.getParameter("id_status")%>">
    <INPUT TYPE="hidden" NAME="tx_job" VALUE="<%=request.getParameter("tx_job")%>">
    <INPUT TYPE="hidden" NAME="tl_job" VALUE="<%=request.getParameter("tl_job")%>">
    <INPUT TYPE="hidden" NAME="attachimages" VALUE="<%=request.getParameter("attachimages")%>">
    <INPUT TYPE="hidden" NAME="dt_execution" VALUE="<%=request.getParameter("dt_execution")%>">
    <INPUT TYPE="hidden" NAME="webbeacon" VALUE="<%=nullif(request.getParameter("webbeacon"),"0")%>">
    <INPUT TYPE="hidden" NAME="clickthrough" VALUE="<%=nullif(request.getParameter("clickthrough"),"0")%>">
    <BR/>
    <TABLE CLASS="formback" ALIGN="center">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD CLASS="formplain">You are you about to sent the newsletter&nbsp;<%=oObj.getStringNull(bMail ? DB.nm_pageset : DB.nm_mailing,"")%></TD>
          </TR>
          <TR>
            <TD CLASS="formplain">to lists:&nbsp;<% for (int l=0; l<nLst; l++) { out.write(oLst.getStringNull(0,l,oLst.getStringNull(1,l,""))+"&nbsp;"); }%></TD>
          </TR>
          <TR>
            <TD CLASS="formplain">with subject&nbsp;<%=oObj.getStringNull(DB.tx_subject,"no subject")%></TD>
          </TR>
          <TR>
            <TD CLASS="formplain">sender's address&nbsp;<%=oObj.getStringNull(DB.nm_from,"")%>&nbsp;&lt;<%=oObj.getStringNull(DB.tx_email_from,"")%>&gt;</TD>
          </TR>
          <TR>
            <TD CLASS="formplain">reply-to&nbsp;&lt;<%=oObj.getStringNull(DB.tx_email_reply,oObj.getStringNull(DB.tx_email_from,""))%>&gt;</TD>
          </TR>
          <TR>
            <TD CLASS="formplain">send at date&nbsp;<%=sDtExecution%></TD>
          </TR>
          <TR>
            <TD><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Confirm" CLASS="pushbutton" TITLE="ALT+s">&nbsp;
    	        &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
