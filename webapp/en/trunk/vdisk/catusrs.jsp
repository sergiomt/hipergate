<%@ page import="java.net.URLDecoder,java.sql.Connection,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/dbbind.jsp" %>
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

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);
  String sDomain = request.getParameter("id_domain");
  int    iDomain = Integer.parseInt(sDomain);

  int    id_domain = Integer.parseInt(getCookie(request,"domainid",""));
  String id_category = request.getParameter("id_category");
  String n_category = request.getParameter("n_category");
  String id_parent = request.getParameter("id_parent_cat")!=null ? request.getParameter("id_parent_cat") : "";
  
  Category   oCatg;
  ACLDomain  oDom  = null;
  ACL        oACL  = new ACL();
  DBSubset   oUsrs = null;
  DBSubset   oPerm = new DBSubset(DB.k_users + " u, " + DB.k_x_cat_user_acl + " a", "u." + DB.gu_user + ",u." + DB.tx_nickname + ",a." + DB.acl_mask, "u." + DB.id_domain + "=" + sDomain + " AND u." + DB.gu_user + "=a." + DB.gu_user + " AND a." + DB.gu_category + "='" + id_category + "'", 128);
  DBSubset   oDoms = new DBSubset(DB.k_domains, DB.id_domain + "," + DB.nm_domain, "1=1 ORDER BY 2", 100);
  int        iDoms = 0;
  int        iRows = 0;

  JDCConnection oConn = null; // DB Connection
    
    try {
      oConn = GlobalDBBind.getConnection("catusrs");

      switch (oConn.getDataBaseProduct()) {
        case JDCConnection.DBMS_MSSQL:      
          oUsrs = new DBSubset(DB.k_users, "'<OPTION VALUE=\"' + " + DB.gu_user + " + '\">' + " + DB.tx_nickname + " + '  -  ' + ISNULL(" + DB.nm_user + ",'') + ISNULL(' ' + " + DB.tx_surname1 + ",'') + ISNULL(' ' + " + DB.tx_surname2 + ",'')", DB.bo_active + "<>0 AND " + DB.id_domain + "=" + sDomain + " ORDER BY " + DB.tx_nickname, 256);
          break;
        case JDCConnection.DBMS_POSTGRESQL:      
          oUsrs = new DBSubset(DB.k_users, "'<OPTION VALUE=\"' || CAST(" + DB.gu_user + " AS VARCHAR(32)) || '\">' || " + DB.tx_nickname + " || '  -  ' || COALESCE(" + DB.nm_user + ",'') || COALESCE(' ' || " + DB.tx_surname1 + ",'') || COALESCE(' ' || " + DB.tx_surname2 + ",'')", DB.bo_active + "<>0 AND " + DB.id_domain + "=" + sDomain + " ORDER BY " + DB.tx_nickname, 256);
          break;
        case JDCConnection.DBMS_ORACLE:      
          oUsrs = new DBSubset(DB.k_users, "'<OPTION VALUE=\"' || " + DB.gu_user + " || '\">' || " + DB.tx_nickname + " || '  -  ' || NVL(" + DB.nm_user + ",'') || NVL(' ' || " + DB.tx_surname1 + ",'') || NVL(' ' || " + DB.tx_surname2 + ",'')", DB.bo_active + "<>0 AND " + DB.id_domain + "=" + sDomain + " ORDER BY " + DB.tx_nickname, 256);
          break;
        case JDCConnection.DBMS_MYSQL:      
          oUsrs = new DBSubset(DB.k_users, "CONCAT('<OPTION VALUE=\"'," + DB.gu_user + ",'\">'," + DB.tx_nickname + ",'  -  ',COALESCE(" + DB.nm_user + ",''),COALESCE(CONCAT(' '," + DB.tx_surname1 + "),''),COALESCE(CONCAT(' '," + DB.tx_surname2 + "),''))", DB.bo_active + "<>0 AND " + DB.id_domain + "=" + sDomain + " ORDER BY " + DB.tx_nickname, 256);
          break;
      }
      
      oDom  = new ACLDomain(oConn, Integer.parseInt(sDomain,10));
    
      oUsrs.load(oConn);
      oUsrs.setColumnDelimiter("");
      oUsrs.setRowDelimiter("");

      iRows = oPerm.load(oConn);
            
      // Si no es una nueva categoria, entonces cargar sus datos
      oCatg = new Category(oConn, id_category);
    
      if (id_domain==1024) iDoms = oDoms.load(oConn);
      
      oConn.close("catusrs");
    }
  catch(SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("catusrs");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Acess Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));  
  }
  if (null==oConn) return;
  oConn = null;
%>

  <!-- +-----------------------------------------------+ -->
  <!-- | Edición de permisos de Usuarios por Categoria | -->
  <!-- | © KnowGate 2001                               | -->
  <!-- +-----------------------------------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit permissions of Category per User</TITLE>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>    
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      var frm = window.document.forms[0];
      var usr = frm.sel_all_users.options;
      var acl = frm.sel_mask.options;      
      var lst = "";
      
      for (var a=0; a<acl.length; a++)
        if (acl[a].selected) frm.acl_mask.value = acl[a].value;
            
      frm.usr_list.value = "";
      
      for (var n=0; n<usr.length; n++)
        if (usr[n].selected) lst += usr[n].value + ",";      
                  
      if (lst.length>0)
        frm.usr_list.value = lst.substr(0, lst.length-1);
      else
        return false;
        
      return true;        
    }
    
    function editCategory() {
      window.document.location = "catedit.jsp?id_domain=<%=sDomain%>&id_category=<%=id_category%>&n_category=<%=n_category%>&id_parent_cat=" + document.forms[0].id_parent_cat.value;
    }

    function editGroupPerms() {
      window.document.location = "catgrps.jsp?id_domain=<%=sDomain%>&id_category=<%=id_category%>&n_category=<%=n_category%>&id_parent_cat=" + document.forms[0].id_parent_cat.value;
    }
    
    function switchDomain() {
      window.document.location="catusrs.jsp?id_domain=" + getCombo(document.forms[0].sel_domains) + "&id_category=" + getURLParam("id_category") + "&n_category=" + getURLParam("n_category") + (getURLParam("id_parent_cat")!=null ? "&id_parent_cat="+getURLParam("id_parent_cat") : "");
    }
           
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4">
  <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Permissions by User <%=n_category%></FONT></TD></TR></TABLE>
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>
  <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>
  <FORM METHOD="post" ACTION="catusrs_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=sDomain%>">
    <INPUT TYPE="hidden" NAME="id_category" VALUE="<%=request.getParameter("id_category")%>">
    <INPUT TYPE="hidden" NAME="n_category" VALUE="<%=request.getParameter("n_category")%>">
    <INPUT TYPE="hidden" NAME="id_parent_cat" VALUE="<% out.write(id_parent); %>">
    <INPUT TYPE="hidden" NAME="usr_list"><INPUT TYPE="hidden" NAME="acl_mask"><INPUT TYPE="hidden" NAME="tp_action">
    <TABLE WIDTH="100%" CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Domain:</FONT></TD>
            <TD ALIGN="left">
              <SELECT NAME="sel_domains" onChange="switchDomain()">
<% if (1024!=id_domain)
	      out.write("              <OPTION VALUE=\"" + sDomain + "\">" + oDom.getString(DB.nm_domain) + "</OPTION>");
else
	      for (int d=0; d<iDoms; d++) out.write("              <OPTION VALUE=\"" + String.valueOf(oDoms.getInt(0,d)) + "\"" + (oDoms.getInt(0,d)==iDomain ? " SELECTED" : "") + ">" + oDoms.getString(1,d) + "</OPTION>");
%>
              </SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="90"><FONT CLASS="formstrong">Users:</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_all_users" STYLE="width:330" SIZE="6" MULTIPLE><%=oUsrs.toString()%></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90">&nbsp;</TD>
            <TD ALIGN="left"><SELECT NAME="sel_mask"><OPTION VALUE="1">Listar<OPTION VALUE="3">Read<OPTION VALUE="7">Add and Read<OPTION VALUE="15">Moderate<OPTION VALUE="31">Modify<OPTION VALUE="255">Full Control</SELECT>&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="Modify" CLASS="pushbutton" TITLE="Modify permissions for selected users" STYLE="width:90" onClick="document.forms[0].tp_action.value='modify'">&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="Delete" CLASS="pushbutton" TITLE="Delete permissions for selected users" STYLE="width:90" onClick="document.forms[0].tp_action.value='remove'"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90">&nbsp;</TD>
            <TD ALIGN="left"><INPUT TYPE="checkbox" NAME="recurse" VALUE="1"><SPAN><FONT CLASS="textplain">Propagate to child categories</FONT></SPAN></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="90"><FONT CLASS="formstrong">Permissions:</FONT></TD>
            <TD ALIGN="left">
              <SELECT NAME="sel_cat_users" STYLE="width:330" SIZE="6">
                <%                  
                  for (int r=0; r<iRows; r++)
                    out.write("                <OPTION VALUE=\"" + oPerm.getString(0,r) + "\">" + oPerm.getString(1,r) + "  -  " + oACL.getLocalizedMaskName(oPerm.getInt(2,r),sLanguage));
                %>
              </SELECT>
            </TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
    	    <TD WIDTH="90">&nbsp;</TD>
    	    <TD ALIGN="center">
    	      <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	    </TD>	    
          </TR>           
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
</BODY>

</HTML>
