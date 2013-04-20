<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
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
  
  // 01. Authenticate user session by checking cookies
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // 02. Add no-cache headers
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  String id_domain = nullif(request.getParameter("id_domain"));
  String n_domain = nullif(request.getParameter("n_domain"));
  String bo_checked = "";
  
  ACLDomain oDom = null;
  ACLUser oUsr = null;        
  JDCConnection oConn = null;
  DBSubset oGrp = null;
  
  try {
    
    oConn = GlobalDBBind.getConnection("domedit");  
    
    if (id_domain.length()>0) {
      oDom = new ACLDomain(oConn, Integer.parseInt(id_domain));
      bo_checked = (oDom.getShort(DB.bo_active)!=(short)0 ? "CHECKED" : "");
      oUsr = new ACLUser(oConn, oDom.getString(DB.gu_owner));
      oGrp = new DBSubset (DB.k_acl_groups, DB.gu_acl_group+","+DB.nm_acl_group, DB.id_domain+"="+id_domain,10);
      oGrp.load(oConn);
    }
    else
      bo_checked = "CHECKED";
      
    oConn.close("domedit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("domedit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Edit Domain</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>
  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
            
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        var chr;
        
        if (hasForbiddenChars(frm.nm_domain.value)) {
          alert ("Domain name contains invalid characters");
          return false;
        }
        
        frm.nm_domain.value = frm.nm_domain.value.toUpperCase();

	for (var c=0; c<frm.nm_domain.value.length; c++) {
	  chr = frm.nm_domain.value.charCodeAt(c); 
	  if (chr>127 || chr<48) {
	    alert ("Domain name contains invalid characters");
	    return false;
	  }
	}

<% if (id_domain.length()>0) { %>
	frm.gu_admins.value = frm.sel_admins.options[frm.sel_admins.selectedIndex].value;
<% } %>
	
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Domain</FONT></TD></TR>
  </TABLE>
  <CENTER> 
  <FORM METHOD="post" ACTION="domedit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Domain Id.</FONT></TD>
            <TD ALIGN="left" WIDTH="350"><FONT CLASS="formplain"><% out.write(id_domain); %></FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="350"><INPUT TYPE="text" NAME="nm_domain" MAXLENGTH="12" SIZE="32" VALUE="<% out.write(n_domain); %>" STYLE="text-transform:uppercase"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Active:</FONT></TD>
            <TD ALIGN="left" WIDTH="350"><INPUT TYPE="checkbox" NAME="bo_active" VALUE="1" <% out.write(bo_checked); %>></TD>
          </TR>
<% if (id_domain.length()>0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Administrator:</FONT></TD>
            <TD ALIGN="left" WIDTH="350"><FONT CLASS="formplain"><%if (oUsr!=null) out.write(oUsr.getStringNull(DB.nm_user,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname2,"")); %></FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Administrators group:</FONT></TD>
            <TD ALIGN="left" WIDTH="350">
              <INPUT TYPE="hidden" NAME="gu_admins" VALUE="<% if (oDom!=null) out.write(oDom.getString(DB.gu_admins)); %>">
              <SELECT NAME="sel_admins"><% for (int g=0; g<oGrp.getRowCount(); g++) out.write("<OPTION VALUE=\""+oGrp.getString(0,g)+"\"" + (oDom.getStringNull(DB.gu_admins,"").equals(oGrp.getString(0,g)) ? " SELECTED" : "") + ">"+oGrp.getString(1,g)+"</OPTION>"); %></SELECT>
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
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
  </CENTER> 
</BODY>
</HTML>
