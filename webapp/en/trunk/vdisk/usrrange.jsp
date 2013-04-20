<%@ page import="java.net.URLDecoder,java.sql.Connection,java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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
  String gu_user = request.getParameter("gu_user")!=null ? request.getParameter("gu_user") : "";
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  
  DBSubset oWrks = null;  
  DBSubset oGrps = null;
  DBSubset oGrpx = null;
  String   sGrpx = null;
  
  int iMaxUsers = 1073741823;
  int iActualUsers;
  
  ACLDomain oDom = new ACLDomain();
  boolean bDomAdm = false;
  Object  aUser[] = { gu_user } ;
  Object  aDom[] = { id_domain } ;
  Object  aDomU[] = { id_domain, gu_user } ;
  JDCConnection oConn = null;
  Statement oStmt;
  ResultSet oRSet;
  
  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

    sHeadStrip = "New User Range";
    oConn = GlobalDBBind.getConnection("usredit2");

    oWrks = new DBSubset(DB.k_workareas, DB.gu_workarea + "," + DB.nm_workarea, DB.id_domain + "=" + id_domain + " AND " + DB.bo_active + "<>0", 10);
    oWrks.load(oConn);

    try {
    
      if (DBBind.exists(oConn, DB.k_accounts, "U")) {
        oStmt = oConn.createStatement();
        oRSet = oStmt.executeQuery("SELECT " + DB.max_users + " FROM " + DB.k_accounts + " WHERE " + DB.id_domain + "=" + id_domain);
   	if (oRSet.next())
   	  iMaxUsers = oRSet.getInt(1);
   	oRSet.close();
   	oStmt.close();
      }
            
      oStmt = oConn.createStatement();
      oRSet = oStmt.executeQuery("SELECT COUNT(" + DB.gu_user + ") FROM " + DB.k_users + " WHERE " + DB.id_domain + "=" + id_domain);
      oRSet.next();
      iActualUsers = oRSet.getInt(1);
      oRSet.close();
      oStmt.close();

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL) {
        oGrps = new DBSubset(DB.k_acl_groups,"'<OPTION VALUE=\"'+" + DB.gu_acl_group + "+'\">' + " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "'<OPTION VALUE=\"'+g." + DB.gu_acl_group + "+'\">' + g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oGrps = new DBSubset(DB.k_acl_groups, "'<OPTION VALUE=\"' || CAST(" + DB.gu_acl_group + " AS VARCHAR) || '\">' || " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "'<OPTION VALUE=\"' || CAST(g." + DB.gu_acl_group + " AS VARCHAR) || '\">' || g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
        oGrps = new DBSubset(DB.k_acl_groups,"CONCAT('<OPTION VALUE=\"'," + DB.gu_acl_group + ",'\">'," + DB.nm_acl_group + ")", DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "CONCAT('<OPTION VALUE=\"',g." + DB.gu_acl_group + ",'\">',g." + DB.nm_acl_group + ")",
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }
      else {
        oGrps = new DBSubset(DB.k_acl_groups,"'<OPTION VALUE=\"' || " + DB.gu_acl_group + " || '\">' || " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "'<OPTION VALUE=\"' || g." + DB.gu_acl_group + " || '\">' || g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }

      oGrps.setRowDelimiter("</OPTION>");
      oGrpx.setRowDelimiter("</OPTION>");
      
      oGrps.load(oConn, aDom);
      sGrpx = "";
      
      oConn.close("usredit2");
      oConn = null;

      if (iActualUsers>=iMaxUsers) {
        response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Maximum number of concurrent users reached&desc=The maximum number of concurrent users for your licese contract has been reached. For creating more users please extend your license first.&resume=_back"));
        return;
      }
    }
    catch (SQLException e) {
      if (oConn!=null) oConn.close("usredit2");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() +  "&resume=_back"));
      return;
    }
    catch (IllegalStateException e) {
      if (oConn!=null) oConn.close("usredit2");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() +  "&resume=_back"));
      return;
    }
    catch (NullPointerException e) {
      if (oConn!=null) oConn.close("usredit2");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() +  "&resume=_back"));
      return;
    }

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");    
%>
  <!-- +---------------------------------+ -->
  <!-- | Creación de Rango de Usuarios   | -->
  <!-- | © KnowGate 2005                 | -->
  <!-- +---------------------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=sHeadStrip%></TITLE>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      var frm = document.forms[0];
      var txt;
      var opt;

      if (!isIntValue(frm.nu_from.value)) {
        alert ("Range start must be between 0 and 999");
        return false;
      }

      if (!isIntValue(frm.nu_to.value)) {
        alert ("Range end must be between 0 and 999");
        return false;
      }
      
      if (parseFloat(frm.nu_from.value)>parseFloat(frm.nu_to.value)) {
        alert ("Range start must be less than range end");
        return false;      
      }

      var txt = frm.tx_nickname.value       
      if (txt.length<4) {
        alert ("Alias must be at least 4 characters long");
        return false;
      }

      if (txt.indexOf(" ")>=0 || txt.indexOf(";")>=0 || txt.indexOf(",")>=0 || txt.indexOf("?")>=0 || txt.indexOf("$")>=0 || txt.indexOf("%")>=0 || txt.indexOf("/")>=0 || txt.indexOf("¨")>=0 || txt.indexOf("`")>=0) {
        alert ("Alias contains forbidden characters");
        return false;        
      }

      if (frm.tx_pwd.value.length<4) {
        alert ("Password must contain at least 4 characters");
        return false;
      }

      if (frm.tx_pwd.value!=frm.tx_pwd2.value) {
        alert ("Original and verified password do not coincide");
        return false;
      }

      txt = rtrim(ltrim(frm.tx_domain.value));
      if (txt.length==0) {
        alert ("e-mail address is mandatory");
        return false;      
      }
      
      if (txt.length>0) {
        if (txt.indexOf("@")>=0 || txt.indexOf(".")<=0) {
          alert ("Domain is not valid");
          return false;
        }
      }

      frm.tx_domain.value = txt.toLowerCase();

      if (frm.sel_workarea.options.selectedIndex>=0)
        frm.gu_workarea.value = getCombo(frm.sel_workarea);
        
      frm.memberof.value = "";     
      opt = frm.group2.options;
      for (var g=0; g<opt.length; g++) {
        frm.memberof.value += opt[g].value + ",";
      }
      txt = frm.memberof.value; 
      if (txt.charAt(txt.length-1)==',') frm.memberof.value = txt.substr(0,txt.length-1);      
                        
      return true;
    }        

    // --------------------------------------------------------
    
    function findValue(opt,val) {
      var fnd = -1;
      
      for (var g=0; g<opt.length; g++) {
        if (opt[g].value==val) {
          fnd = g;
          break;
        }      
      }
      return fnd;
    }

    // --------------------------------------------------------
    
    function addGrps() {
      var opt1 = document.forms[0].groups.options;
      var opt2 = document.forms[0].group2.options;
      var sel2 = document.forms[0].group2;
      var opt;
      
      for (var g=0; g<opt1.length; g++) {
        if (opt1[g].selected && (-1==findValue(opt2,opt1[g].value))) {          
          opt = new Option(opt1[g].text, opt1[g].value);
          opt2[sel2.length] = opt;
        }
      }
    }

    // --------------------------------------------------------

    function remGrps() {
      var opt2 = document.forms[0].group2.options;
      
      for (var g=0; g<opt2.length; g++) {
        if (opt2[g].selected)
          opt2[g--] = null;
      }
    }    
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4">
  <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>
  <TABLE WIDTH="100%"><TR><TD CLASS="strip1"><FONT CLASS="title1"><%=sHeadStrip%> for domain &nbsp;<I><%=n_domain%></I></FONT></TD></TR></TABLE>
  <FORM NAME="usredit" METHOD="post" ACTION="userrange_store.jsp" onSubmit="return validate();">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=gu_user%>">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="bo_searchable" VALUE="1">
    <INPUT TYPE="hidden" NAME="bo_change_pwd" VALUE="1">
    <INPUT TYPE="hidden" NAME="len_quota" VALUE="0">
    <INPUT TYPE="hidden" NAME="max_quota" VALUE="104857600">
    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
	  <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="checkbox" NAME="chk_active" VALUE="1" CHECKED></TD>          
            <TD ALIGN="left" WIDTH="90"><FONT CLASS="formstrong">Active</FONT></TD>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Alias:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="tx_nickname" MAXLENGTH="28" SIZE="7" VALUE="user">
              &nbsp;&nbsp;
              <FONT CLASS="formstrong">From</FONT>
              <INPUT TYPE="text" NAME="nu_from" MAXLENGTH="4" SIZE="3" VALUE="001" onkeypress="acceptOnlyNumbers(this)">
              &nbsp;&nbsp;<FONT CLASS="formstrong">To</FONT>
              <INPUT TYPE="text" NAME="nu_to" MAXLENGTH="4" SIZE="3" VALUE="010" onkeypress="acceptOnlyNumbers(this)">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Password:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="password" NAME="tx_pwd" MAXLENGTH="50" SIZE="19" VALUE="" TITLE="Original key">&nbsp;<INPUT TYPE="password" NAME="tx_pwd2" MAXLENGTH="50" SIZE="19" VALUE="" TITLE="Repeat Password"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Domain:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tx_domain" MAXLENGTH="100" SIZE="40" VALUE="hipergate.org" STYLE="text-transform:lowercase"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Area:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="">
              <SELECT NAME="sel_workarea"><%
              for (int w=0; w<oWrks.getRowCount(); w++)
                out.write ("<OPTION VALUE=\"" + oWrks.getString(0,w) + "\">" + oWrks.getString(1,w) + "</OPTION>");
%>            </SELECT>
              </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tx_comments" MAXLENGTH="254" SIZE="40" VALUE=""></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" VALIGN="top"><FONT CLASS="formstrong">Groups</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <TABLE CELLSPACING="0" CELLPADDING="0" BACKGROUND="../skins/<%=sSkin%>/fondoc.gif">
                <TR HEIGHT="20"><TD WIDTH="8">&nbsp;</TD><TD><FONT CLASS="textsmallfront">All Groups</FONT></TD><TD WIDTH="50"></TD><TD><FONT CLASS="textsmallfront">Belongs to</FONT></TD><TD WIDTH="8">&nbsp;</TD></TR>
                <TR><TD WIDTH="8">&nbsp;</TD><TD><SELECT NAME="groups" CLASS="textsmall" STYLE="width:148" SIZE="9" MULTIPLE><%=oGrps.toString()%></SELECT></TD><TD ALIGN="center" VALIGN="middle"><INPUT TYPE="button" NAME="AddGrps" VALUE="++ >>" TITLE="Add" STYLE="width:40" onclick="addGrps()"><BR><BR><INPUT TYPE="button" NAME="RemGrps" VALUE="<< - -" TITLE="Remove" STYLE="width:40" onclick="remGrps()"></TD><TD><SELECT NAME="group2" CLASS="textsmall" STYLE="width:148" SIZE="9" MULTIPLE><%=sGrpx%></SELECT><INPUT TYPE="hidden" NAME="memberof" VALUE=""></TD><TD WIDTH="8">&nbsp;</TD></TR>
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