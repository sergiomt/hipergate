<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.crm.ListMember,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_list = request.getParameter("gu_list");
  String tp_list = request.getParameter("tp_list");
  String gu_member = request.getParameter("gu_member");
  String tp_member = null;
  String bo_active = null;
  String id_format = null;
  
  String  sBlackList = "";
  boolean bBlocked = false;
  
  PreparedStatement oStmt;
  ResultSet oRSet;
    
  ListMember oMbr;
      
  JDCConnection oConn = GlobalDBBind.getConnection("member_edit");  
    
  try {

    if (gu_member==null) {
      oMbr = new ListMember();
      bo_active = "1";
      tp_member = String.valueOf(ListMember.ClassId);
      id_format = "TXT";
      bBlocked  = false;
    }
    else {
      oMbr = new ListMember(oConn, gu_member, gu_list);
      bo_active = String.valueOf(oMbr.getShort(DB.bo_active));
      tp_member = String.valueOf(oMbr.getShort(DB.tp_member));
      id_format = oMbr.getString(DB.id_format);
    
      // *************************************************************************
      // [~//Buscar si el usuario pertenece a la lista negra de direcciones bloqueadas~]

      // [~//Buscar si existe lista de e-mails bloqueados asociada a la lista del miembro editado~]

      oStmt = oConn.prepareStatement("SELECT " + DB.gu_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_workarea + "=? AND " + DB.tp_list + "=? AND " + DB.gu_query + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, gu_workarea);
      oStmt.setShort (2, DistributionList.TYPE_BLACK);
      oStmt.setString(3, gu_list);
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        sBlackList = oRSet.getString(1);
      }
      else
        sBlackList = "";
      oRSet.close();
      oStmt.close();

      // [~//Si la lista existe, buscar el e-mail del miembro~]
            
      if (sBlackList.length()==0)
        bBlocked = false;
      else {
        oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "=? AND " + DB.tx_email + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sBlackList);
        oStmt.setString(2, oMbr.getString(DB.tx_email));
        oRSet = oStmt.executeQuery();
        bBlocked = oRSet.next();
        oRSet.close();
        oStmt.close();        
      }
    }
            
    oConn.close("member_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("member_edit");
    oMbr = null;
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Member of a List</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
	
	if (!check_email(frm.tx_email.value)) {
	  alert ("e-mail address is not valid");
	  return false;
	}
	
	frm.bo_active.value = (frm.chk_active.checked ? "1" : "0");
	
	frm.id_format.value = getCombo(frm.sel_format);
	
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
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit List Member:<% out.write(request.getParameter("de_list")); %></FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="member_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<% out.write (id_domain); %>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<% out.write (gu_workarea); %>">    
    <INPUT TYPE="hidden" NAME="gu_list" VALUE="<% out.write (gu_list); %>">
    <INPUT TYPE="hidden" NAME="de_list" VALUE="<% out.write (request.getParameter("de_list")); %>">
    <INPUT TYPE="hidden" NAME="tp_member" VALUE="<% out.write (tp_member); %>">
    <INPUT TYPE="hidden" NAME="gu_blacklist" VALUE="<% out.write (sBlackList); %>">
    <INPUT TYPE="hidden" NAME="was_bloqued" VALUE="<% if (bBlocked) out.write ("1"); %>">
    <INPUT TYPE="hidden" NAME="gu_member" VALUE="<% out.write (nullif(gu_member)); %>">
    <INPUT TYPE="hidden" NAME="bo_active">
        
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Active:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="checkbox" NAME="chk_active" VALUE="1" <% if (bo_active.equals("1")) out.write("CHECKED"); %> TITLE="Check here for deactivating a member e-mail address.">
              <FONT CLASS="textsmall"><I>Mail address is valid</I></FONT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Blocked:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="checkbox" NAME="chk_bloqued" VALUE="1" <% if (bBlocked) out.write("CHECKED"); %> TITLE="Check here for stopping this member from receiving any e-mail.">
              <FONT CLASS="textsmall"><I>This member must not receive any e-mail</I></FONT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tx_email" MAXLENGTH="100" SIZE="50" VALUE="<% out.write(oMbr.getStringNull(DB.tx_email,"")); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tx_name" MAXLENGTH="100" SIZE="50" VALUE="<% out.write(oMbr.getStringNull(DB.tx_name,"")); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Surname:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tx_surname" MAXLENGTH="100" SIZE="50" VALUE="<% out.write(oMbr.getStringNull(DB.tx_surname,"")); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Salutation:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <SELECT NAME="sel_salutation"><OPTION SELECTED></OPTION><OPTION>Mr.</OPTION><OPTION>Ms.</OPTION><OPTION>Ms.</OPTION><OPTION>Dr.</OPTION><OPTION>Dr.</OPTION><OPTION>Mr.</OPTION><OPTION>Ms.</OPTION><OPTION>Dear</OPTION><OPTION>Dear</OPTION><OPTION>Dear</OPTION><OPTION>Dear</OPTION><OPTION>Mr.</OPTION><OPTION>Ms.</OPTION><OPTION>Mr.</OPTION><OPTION>Ms.</OPTION></SELECT>
              &nbsp;<INPUT TYPE="button" VALUE=">>" onclick="document.forms[0].tx_salutation.value=getComboText(document.forms[0].sel_salutation);">&nbsp;
              <INPUT TYPE="text" NAME="tx_salutation" MAXLENGTH="16" SIZE="16" VALUE="<% out.write(oMbr.getStringNull(DB.tx_salutation,"")); %>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Format:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="id_format">
              <SELECT NAME="sel_format">
                <OPTION VALUE="TXT" <% if (id_format.equals("TXT")) out.write("SELECTED");%>>Text</OPTION>
                <OPTION VALUE="HTML" <% if (id_format.equals("HTML")) out.write("SELECTED");%>>HTML</OPTION>
              </SELECT>
            </TD>
          </TR>
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
</BODY>
</HTML>
