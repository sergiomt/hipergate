<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.marketing.Campaign" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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
  
  String gu_campaign = request.getParameter("gu_campaign");
  String gu_workarea = request.getParameter("gu_workarea");
  
  Campaign oCamp = new Campaign();
  DBSubset oTrgt = null;
  
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection("campaign_edit");
    
    if (null!=gu_campaign) {
      if (oCamp.load(oConn, gu_campaign));
        oTrgt = oCamp.getTargets(oConn);
    }

    oConn.close("campaign_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("campaign_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Campaign</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
            
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

			  if (frm.nm_campaign.value.length==0) {
			    alert ("Campaign name is required");
				  frm.nm_campaign.focus();
				  return false;
			  }

			  if (hasForbiddenChars(frm.nm_campaign.value)) {
			    alert ("Campaign name contains invalid characters");
				  frm.nm_campaign.focus();
				  return false;
			  }
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE SUMMARY="Form Title" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1"><%=(null==gu_campaign ? "New Campaign" : "Edit Campaign")%></FONT></TD></TR>
  </TABLE>
  
  <FORM NAME="" METHOD="post" ACTION="campaign_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_campaign" VALUE="<%=nullif(gu_campaign)%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Name:</TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_campaign" MAXLENGTH="70" SIZE="40" VALUE="<%=oCamp.getStringHtml(DB.nm_campaign,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Active</TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="checkbox" VALUE="1" NAME="bo_active" <% if (oCamp.isNull(DB.bo_active)) out.write("CHECKED"); else if (oCamp.getShort(DB.bo_active)!=(short)0) out.write("CHECKED"); %>></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
<% if (null!=gu_campaign) { %>
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="90" CLASS="formstrong">Targets:</TD>
            <TD ALIGN="left" WIDTH="370">
				      <TABLE SUMMARY="Targets">
				        <TR>
				        	<TD WIDTH="20"><IMG SRC="../images/images/marketing/newtarget.gif" HEIGHT="18" WIDTH="17" BORDER="0" ALT="New Campaign Target"></TD>
				        	<TD ALIGN="left"><A CLASS="linkplain" HREF="campaigntarget_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_campaign=<%=gu_campaign%>">New Target</A></TD>
				          <TD WIDTH="90"></TD>
				        </TR>
<%   for (int o=0; o<oTrgt.getRowCount(); o++) { %>
				        <TR>
				        	<TD WIDTH="280" COLSPAN="2" NOWRAP><A CLASS="linksmall" HREF="campaigntarget_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_campaign=<%=gu_campaign%>&gu_campaign_target=<%=oTrgt.getString(DB.gu_campaign_target,o)%>"><%=oTrgt.getStringNull(DB.nm_product,o,"")+" "+oTrgt.getStringNull(DB.tx_term,o,"")+" ["+oTrgt.getDateShort(oTrgt.getColumnPosition(DB.dt_start),o)+".."+oTrgt.getDateShort(oTrgt.getColumnPosition(DB.dt_end),o)+"]"%></A></TD>
				        	<TD WIDTH="90" CLASS="textsmall"><%=String.valueOf(oTrgt.getFloat(DB.nu_planned,o))%>&nbsp;(<%=String.valueOf(oTrgt.getFloat(DB.nu_achieved,o))%>)</TD>
				        </TR>
<%   } %>	
            </TABLE>
            </TD>
          </TR>
<% } %>
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
