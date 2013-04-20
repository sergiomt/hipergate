<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.crm.Contact" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/dbbind.jsp" %>
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

  String sSkin = getCookie(request, "skin", "xp");  
  String sLanguage = getNavigatorLanguage(request);
  String gu_contact = request.getParameter("gu_contact")!=null ? request.getParameter("gu_contact") : "";
  String id_domain = request.getParameter("id_domain");
  
  DBSubset oGrps = null;
  DBSubset oGrpx = null;
  String   sGrpx = null;
  
  int iMaxUsers = 1073741823;
  int iActualUsers;
  
  Contact oCont = new Contact();
  Object  aCont[] = { gu_contact } ;
  Object  aDom[] = { new Integer(id_domain) } ;
  Object  aDomC[] = { new Integer(id_domain), gu_contact } ;
  JDCConnection oConn = null;
  
  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

  if (!bIsAdmin) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=Having administrator role is required for editing company access restrictions&resume=_back"));
    return;
  }

  try {

      if (!bIsAdmin) {
        throw new SQLException("Having administrator role is required for editing permissions", "28000", 28000);
      }

      oConn = GlobalDBBind.getConnection("contact_security");
      
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL) {
        oGrps = new DBSubset(DB.k_acl_groups,"'<OPTION VALUE=\"'+" + DB.gu_acl_group + "+'\">' + " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_contact + " x", "'<OPTION VALUE=\"'+g." + DB.gu_acl_group + "+'\">' + g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_contact +"=?", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oGrps = new DBSubset(DB.k_acl_groups, "'<OPTION VALUE=\"' || CAST(" + DB.gu_acl_group + " AS VARCHAR) || '\">' || " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_contact + " x", "'<OPTION VALUE=\"' || CAST(g." + DB.gu_acl_group + " AS VARCHAR) || '\">' || g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_contact +"=?", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
        oGrps = new DBSubset(DB.k_acl_groups,"CONCAT('<OPTION VALUE=\"'," + DB.gu_acl_group + ",'\">'," + DB.nm_acl_group + ")", DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_contact + " x", "CONCAT('<OPTION VALUE=\"',g." + DB.gu_acl_group + ",'\">',g." + DB.nm_acl_group + ")",
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_contact +"=?", 50 );
      }
      else {
        oGrps = new DBSubset(DB.k_acl_groups,"'<OPTION VALUE=\"' || " + DB.gu_acl_group + " || '\">' || " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_contact + " x", "'<OPTION VALUE=\"' || g." + DB.gu_acl_group + " || '\">' || g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_contact +"=?", 50 );
      }

      oGrps.setRowDelimiter("</OPTION>");
      oGrpx.setRowDelimiter("</OPTION>");
            
      oCont.load(oConn, aCont);

      if (oCont.isNull(DB.bo_restricted)) oCont.replace(DB.bo_restricted, (short)0);
      if (oCont.isNull(DB.bo_private)) oCont.replace(DB.bo_private, (short)0);

      oGrps.load(oConn, aDom);
      oGrpx.load(oConn, aDomC);
      sGrpx = oGrpx.toString();
      oGrpx = null;
            
      oConn.close("contact_security");
      oConn = null;
  }
  catch (SQLException e) {
      if (null!=oConn) oConn.close("contact_security");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" +
    			     e.getLocalizedMessage() + 
    			     "&resume=_back"));
      return;    			   
  }

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");    
%>
  <!-- +------------------------------------------+ -->
  <!-- | Restricciones de acceso a un individuo   | -->
  <!-- | © KnowGate 2008                          | -->
  <!-- +------------------------------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit access restrictions</TITLE>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
  <!--

    function validate() {
      var frm = document.forms[0];
      var txt;
      var opt;             
        
      frm.memberof.value = "";     
      
      if (frm.restricted[0].checked) {
        frm.bo_private.value="0";
      } else if (frm.restricted[1].checked) {
        frm.bo_private.value="1";
      } else if (frm.restricted[2].checked) {
        frm.bo_private.value="0";
        opt = frm.group2.options;
        for (var g=0; g<opt.length; g++) {
          frm.memberof.value += opt[g].value + ",";
        }
        txt = frm.memberof.value; 
        if (txt.charAt(txt.length-1)==',') frm.memberof.value = txt.substr(0,txt.length-1);      
      }
    
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
      } // next
    } // addGrps

    // --------------------------------------------------------

    function remGrps() {
      var opt2 = document.forms[0].group2.options;
      
      for (var g=0; g<opt2.length; g++) {
        if (opt2[g].selected){
          opt2[g--] = null;
        } // fi
      } // next
    } // remGrps

  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4" >
  <DIV class="cxMnu1" style="width:200px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
  </DIV></DIV>

  <TABLE WIDTH="100%"><TR><TD CLASS="strip1"><FONT CLASS="title1">Edit access restrictions</FONT></TD></TR></TABLE>
  <FORM NAME="compsecedit" METHOD="post" ACTION="contact_security_store.jsp" onSubmit="return validate();">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    <INPUT TYPE="hidden" NAME="bo_private" VALUE="<% out.write(String.valueOf(oCont.getShort(DB.bo_private))); %>">
    <INPUT TYPE="hidden" NAME="memberof">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
          	<TD></TD>
    	      <TD CLASS="formplain"><%=oCont.getStringNull(DB.tx_name,"")+" "+oCont.getStringNull(DB.tx_surname,"")%></TD>
  	      </TR>
          <TR>
          	<TD ALIGN="right"><INPUT TYPE="radio" NAME="restricted" <%=oCont.getShort(DB.bo_restricted)==(short)0 && oCont.getShort(DB.bo_private)==(short)0 ? "CHECKED" : ""%> onclick="hideLayer('groupselection')"></TD>
    	      <TD CLASS="formplain">This individual is visible by everyboy</TD>
  	      </TR>
          <TR>
          	<TD ALIGN="right"><INPUT TYPE="radio" NAME="restricted" <%=oCont.getShort(DB.bo_private)!=(short)0 ? "CHECKED" : ""%> onclick="hideLayer('groupselection')"></TD>
    	      <TD CLASS="formplain">This individual is visible only by me</TD>
  	      </TR>
          <TR>
          	<TD ALIGN="right"><INPUT TYPE="radio" NAME="restricted" <%=oCont.getShort(DB.bo_restricted)!=(short)0 && oCont.getShort(DB.bo_private)==(short)0 ? "CHECKED" : ""%> onclick="showLayer('groupselection')"></TD>
    	      <TD CLASS="formplain">This individual is visible only by members of groups</TD>
  	      </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" VALIGN="top"></TD>
            <TD ALIGN="left" WIDTH="470">
            	<DIV id="groupselection" style="visibility:<%=oCont.getShort(DB.bo_restricted)==(short)0 ? "hidden" : "visible"%>">
                <TABLE CELLSPACING="0" CELLPADDING="0" BACKGROUND="../skins/<%=sSkin%>/fondoc.gif">
                  <TR HEIGHT="20"><TD WIDTH="8">&nbsp;</TD><TD><FONT CLASS="textsmallfront">All groups</FONT></TD><TD WIDTH="50"></TD><TD><FONT CLASS="textsmallfront">Visible to</FONT></TD><TD WIDTH="8">&nbsp;</TD></TR>
                  <TR><TD WIDTH="8">&nbsp;</TD><TD><SELECT NAME="groups" CLASS="textsmall" STYLE="width:160" SIZE="9" MULTIPLE><%=oGrps.toString()%></SELECT></TD><TD ALIGN="center" VALIGN="middle"><INPUT TYPE="button" NAME="AddGrps" VALUE="++ >>" TITLE="Add" STYLE="width:40" onclick="addGrps()"><BR><BR><INPUT TYPE="button" NAME="RemGrps" VALUE="<< - -" TITLE="Remove" STYLE="width:40" onclick="remGrps()"></TD><TD><SELECT NAME="group2" CLASS="textsmall" STYLE="width:160" SIZE="9" MULTIPLE><%=sGrpx%></SELECT></TD><TD WIDTH="8">&nbsp;</TD></TR>
                  <TR HEIGHT="8"><TD COLSPAN="5"></TD></TR>
                </TABLE>
              </DIV>
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
