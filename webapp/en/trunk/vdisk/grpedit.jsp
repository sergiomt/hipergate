<%@ page import="java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %><%
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

  String sSkin = getCookie(request, "skin", "xp");  
  String sLanguage = getNavigatorLanguage(request);
  String sHeadStrip= "";
  String gu_acl_group = request.getParameter("gu_acl_group")!=null ? request.getParameter("gu_acl_group") : "";
  String n_acl_group = request.getParameter("n_acl_group");
  Integer id_domain = new Integer(request.getParameter("id_domain"));
  String n_domain = request.getParameter("n_domain");
  
  DBSubset oUsrs = null;
  DBSubset oGrpx = null;
  
  String   sUsrs = null;
  String   sGrpx = null;
  
  ACLGroup oGroup = new ACLGroup();
  ACLDomain oDomn = new ACLDomain();
  Object  aGrp[] = { gu_acl_group } ;
  Object  aDom[] = { id_domain } ;
  Object  aGrpU[] = { id_domain } ;
  JDCConnection oConn = null;
  boolean bIsAdmin = false;
  
  if (0!=gu_acl_group.length()) {
    sHeadStrip = "Edit Group";    
    
    oConn = GlobalDBBind.getConnection("grpedit1");
  
    try {
      ACLUser oUser = new ACLUser(oConn, getCookie(request, "userid", ""));
      
      bIsAdmin = oUser.isDomainAdmin(oConn);

      if (!bIsAdmin) {
        throw new SQLException("Administrator role is required for editing groups", "28000", 28000);
      }
 
 		  oDomn.load(oConn, new Object[]{id_domain});

      oGroup.load(oConn, aGrp);

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL) {
        oUsrs = new DBSubset(DB.k_users + " u","'<OPTION VALUE=' + u." + DB.gu_user + " + '>' + u." + DB.tx_nickname, "u." + DB.id_domain + "=? AND NOT EXISTS (SELECT NULL FROM " + DB.k_x_group_user + " WHERE gu_acl_group='" + gu_acl_group + "' AND gu_user=u.gu_user)", 1000 );
        oGrpx = new DBSubset(DB.k_x_group_user + " x," + DB.k_users + " u","'<OPTION VALUE=' + u." + DB.gu_user + " + '>' + u." + DB.tx_nickname, "u." + DB.id_domain + "=? AND u.gu_user=x.gu_user AND x.gu_acl_group='" + gu_acl_group + "'", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oUsrs = new DBSubset(DB.k_users + " u","'<OPTION VALUE=' || CAST(u." + DB.gu_user + " AS VARCHAR) || '>' || u." + DB.tx_nickname, "u." + DB.id_domain + "=? AND NOT EXISTS (SELECT NULL FROM " + DB.k_x_group_user + " WHERE gu_acl_group='" + gu_acl_group + "' AND gu_user=u.gu_user)", 1000 );
        oGrpx = new DBSubset(DB.k_x_group_user + " x," + DB.k_users + " u","'<OPTION VALUE=' || CAST(u." + DB.gu_user + " AS VARCHAR) || '>' || u." + DB.tx_nickname, "u." + DB.id_domain + "=? AND u.gu_user=x.gu_user AND x.gu_acl_group='" + gu_acl_group + "'", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
        oUsrs = new DBSubset(DB.k_users + " u","CONCAT('<OPTION VALUE=',u." + DB.gu_user + ",'>',u." + DB.tx_nickname + ")", "u." + DB.id_domain + "=? AND NOT EXISTS (SELECT NULL FROM " + DB.k_x_group_user + " WHERE gu_acl_group='" + gu_acl_group + "' AND gu_user=u.gu_user)", 1000 );
        oGrpx = new DBSubset(DB.k_x_group_user + " x," + DB.k_users + " u","CONCAT('<OPTION VALUE=',u." + DB.gu_user + ",'>',u." + DB.tx_nickname + ")", "u." + DB.id_domain + "=? AND u.gu_user=x.gu_user AND x.gu_acl_group='" + gu_acl_group + "'", 50 );
      }  
      else {
        oUsrs = new DBSubset(DB.k_users + " u","'<OPTION VALUE=' || u." + DB.gu_user + " || '>' || u." + DB.tx_nickname, "u." + DB.id_domain + "=? AND NOT EXISTS (SELECT NULL FROM " + DB.k_x_group_user + " WHERE gu_acl_group='" + gu_acl_group + "' AND gu_user=u.gu_user)", 1000 );
        oGrpx = new DBSubset(DB.k_x_group_user + " x," + DB.k_users + " u","'<OPTION VALUE=' || u." + DB.gu_user + " || '>' || u." + DB.tx_nickname, "u." + DB.id_domain + "=? AND u.gu_user=x.gu_user AND x.gu_acl_group='" + gu_acl_group + "'", 50 );
      }  
  
      oUsrs.setRowDelimiter("</OPTION>");
      oGrpx.setRowDelimiter("</OPTION>");
    
      oUsrs.load(oConn, aDom);
      sUsrs = oUsrs.toString();
      oUsrs = null;
      
      oGrpx.load(oConn, aGrpU);
      sGrpx = oGrpx.toString();
      oGrpx = null;
      
      oConn.close("grpedit1");
      oConn = null;
    }
    catch (SQLException e) {
      if (null!=oConn) oConn.close("grpedit1");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" +
    			   e.getLocalizedMessage() + 
    			   "&resume=../vdisk/domusrs.jsp%38id_domain=" + request.getParameter("id_domain")));
      return;
    }
  }
  else {  
    sHeadStrip = "New Group";
    oConn = GlobalDBBind.getConnection("grpedit2");

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL) {
        oUsrs = new DBSubset(DB.k_users + " u", "'<OPTION VALUE=' + u." + DB.gu_user + " + '>' + u." + DB.tx_nickname, "u." + DB.id_domain + "=? AND NOT EXISTS (SELECT NULL FROM " + DB.k_x_group_user + " WHERE gu_acl_group='" + gu_acl_group + "' AND gu_user=u.gu_user)", 1000 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oUsrs = new DBSubset(DB.k_users + " u", "'<OPTION VALUE=' || CAST(u." + DB.gu_user + " AS VARCHAR) || '>' || u." + DB.tx_nickname, "u." + DB.id_domain + "=? AND NOT EXISTS (SELECT NULL FROM " + DB.k_x_group_user + " WHERE gu_acl_group='" + gu_acl_group + "' AND gu_user=u.gu_user)", 1000 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
        oUsrs = new DBSubset(DB.k_users + " u", "CONCAT('<OPTION VALUE=',u." + DB.gu_user + ",'>',u." + DB.tx_nickname + ")", "u." + DB.id_domain + "=? AND NOT EXISTS (SELECT NULL FROM " + DB.k_x_group_user + " WHERE gu_acl_group='" + gu_acl_group + "' AND gu_user=u.gu_user)", 1000 );
      }  
      else {
        oUsrs = new DBSubset(DB.k_users + " u", "'<OPTION VALUE=' || u." + DB.gu_user + " || '>' || u." + DB.tx_nickname, "u." + DB.id_domain + "=? AND NOT EXISTS (SELECT NULL FROM " + DB.k_x_group_user + " WHERE gu_acl_group='" + gu_acl_group + "' AND gu_user=u.gu_user)", 1000 );
      }  
  
      oUsrs.setRowDelimiter("</OPTION>");

    try {
      oUsrs.load(oConn, aDom);
      sUsrs = oUsrs.toString();
      sGrpx = "";
      
      oConn.close("grpedit2");
      oConn = null;
    }
    catch (SQLException e) {
      if (null!=oConn) oConn.close("grpedit2");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" +
    			   e.getLocalizedMessage() + 
    			   "&resume=../vdisk/domusrs.jsp%38id_domain=" + request.getParameter("id_domain")));
      return;
    }
  }
  oConn = null;   
%>
  <!-- +-----------------------+ -->
  <!-- | Edición de Grupos     | -->
  <!-- | © KnowGate 2001       | -->
  <!-- +-----------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=sHeadStrip%></TITLE>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
   
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      var frm = document.forms[0];
      var txt;
      
      if (frm.nm_acl_group.value.length==0) {
        alert ("Group name is mandatory");
        return false;
      }

      txt = frm.nm_acl_group.value;
      if (txt.indexOf(";")>=0 || txt.indexOf(",")>=0 || txt.indexOf("?")>=0 || txt.indexOf("$")>=0 || txt.indexOf("%")>=0 || txt.indexOf("¨")>=0 || txt.indexOf("`")>=0 || txt.indexOf("|")>=0) {
        alert ("Group name contains invalid characters");
        return false;        
      }
           
      frm.memberof.value = "";     
      opt = frm.user2.options;
      for (var g=0; g<opt.length; g++) {
        frm.memberof.value += opt[g].value + "`";
      }
      txt = frm.memberof.value; 
      if (txt.charAt(txt.length-1)=='`') frm.memberof.value = txt.substr(0,txt.length-1);      
            
      return true;
    }        
    
    function addUsrs() {
      var opt1 = document.forms[0].users.options;
      var opt2 = document.forms[0].user2.options;
      var sel2 = document.forms[0].user2;
      var opt;
      
      for (var g=0; g<opt1.length; g++) {
        if (opt1[g].selected && (-1==comboIndexOf(sel2,opt1[g].value))) {
<%  if (0!=gu_acl_group.length()) { %>
				  if ("<%=gu_acl_group%>"!="<%=oDomn.getString(DB.gu_admins)%>" && opt1[g].value=="<%=oDomn.getString(DB.gu_owner)%>") {
            alert ("It is not allowed to add administrator user to any other group which is not the one of administrators for the domain");
          } else {
            opt = new Option(opt1[g].text, opt1[g].value);
            opt2[sel2.length] = opt;
          }
<% } else { %>
          opt = new Option(opt1[g].text, opt1[g].value);
          opt2[sel2.length] = opt;
<% } %>
        }
      }
    }

    function remUsrs() {
      var sel1 = document.forms[0].users;
      var opt2 = document.forms[0].user2.options;
      
      for (var g=0; g<opt2.length; g++) {
        if (opt2[g].selected) {
<%  if (0!=gu_acl_group.length()) { %>
				  if ("<%=gu_acl_group%>"=="<%=oDomn.getString(DB.gu_admins)%>" && opt2[g].value=="<%=oDomn.getString(DB.gu_owner)%>") {
            alert ("Is is not allowed to delete the administrator user");
          } else {
            if (-1==comboIndexOf(sel1, opt2[g].value)) {
              comboPush (sel1, opt2[g].text, opt2[g].value, false, false);
            } // fi
            opt2[g--] = null;
          } // fi (group==admins AND user==admin)
<% } else { %>
          opt2[g--] = null;
<% } %>
        } // fi (selected)
      } // next
    } // remUsrs
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4">
  <!--<SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>-->
  <TABLE WIDTH="100%"><TR><TD CLASS="strip1"><FONT CLASS="title1"><%=sHeadStrip + (null!=n_acl_group ? " " + n_acl_group : "")%> for domain &nbsp;<I><%=n_domain%></I></FONT></TD></TR></TABLE>
  <FORM NAME="usredit" METHOD="post" ACTION="grpedit_store.jsp" onsubmit="return validate();">
    <INPUT TYPE="hidden" NAME="gu_acl_group" VALUE="<%=gu_acl_group%>">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain.toString()%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="activated" VALUE="1">    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_acl_group" MAXLENGTH="32" SIZE="32" VALUE="<%=(null!=n_acl_group ? n_acl_group : "")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" VALIGN="top"><FONT CLASS="formplain">Description:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><TEXTAREA NAME="de_acl_group" ROWS="3" COLS="42"><% out.write(oGroup.getStringNull("de_acl_group","")); %></TEXTAREA></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" VALIGN="top"><FONT CLASS="formstrong">Members</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <TABLE CELLSPACING="0" CELLPADDING="0" BACKGROUND="../skins/<%=sSkin%>/fondoc.gif">
                <TR HEIGHT="20">
                  <TD WIDTH="8">&nbsp;</TD>
                  <TD><FONT CLASS="textsmallfront">All Users</FONT></TD>
                  <TD WIDTH="50"></TD>
                  <TD><FONT CLASS="textsmallfront">Members of this group</FONT></TD>
                  <TD WIDTH="8">&nbsp;</TD>
                </TR>
                <TR><TD WIDTH="8">&nbsp;</TD><TD><SELECT NAME="users" CLASS="textsmall" STYLE="width:148" SIZE="14" MULTIPLE><%=sUsrs%></SELECT></TD><TD ALIGN="center" VALIGN="middle"><INPUT TYPE="button" NAME="AddUsrs" VALUE="++ >>" TITLE="Add" STYLE="width:40" onclick="addUsrs()"><BR><BR><INPUT TYPE="button" NAME="RemUsrs" VALUE="<< - -" TITLE="Remove" STYLE="width:40" onclick="remUsrs()"></TD><TD><SELECT NAME="user2" CLASS="textsmall" STYLE="width:148" SIZE="14" MULTIPLE><%=sGrpx%></SELECT><INPUT TYPE="hidden" NAME="memberof" VALUE=""></TD><TD WIDTH="8">&nbsp;</TD></TR>
                <TR HEIGHT="8"><TD COLSPAN="5"></TD></TR>
              </TABLE>
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
          </TR>           
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>
