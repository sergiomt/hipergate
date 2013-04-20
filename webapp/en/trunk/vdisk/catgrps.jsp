<%@ page import="java.net.URLDecoder,java.sql.Connection,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/dbbind.jsp" %><%
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
  
  Category   oCatg; // Category
  ACLDomain  oDom  = null;
  ACL        oACL  = new ACL();
  DBSubset   oGrps = null;
  DBSubset   oPerm = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_cat_group_acl + " a", "g." + DB.gu_acl_group + ",g." + DB.nm_acl_group + ",a." + DB.acl_mask, "g." + DB.id_domain + "=" + sDomain + " AND g." + DB.gu_acl_group + "=a." + DB.gu_acl_group + " AND a." + DB.gu_category + "='" + id_category + "'", 128);
  DBSubset   oDoms = new DBSubset(DB.k_domains, DB.id_domain + "," + DB.nm_domain, "1=1 ORDER BY 2", 100);
  int        iDoms = 0;
  int        iRows = 0;

  JDCConnection oConn = null;
    
  // Connect to DB 

    try {
      oConn = GlobalDBBind.getConnection("catgrps");

      switch (oConn.getDataBaseProduct()) {
        case JDCConnection.DBMS_MSSQL:      
          oGrps = new DBSubset(DB.k_acl_groups, "'<OPTION VALUE=' + " + DB.gu_acl_group + " + '>' + " + DB.nm_acl_group, DB.bo_active + "<>0 AND " + DB.id_domain + "=" + sDomain + " ORDER BY " + DB.nm_acl_group, 256);
          break;
        case JDCConnection.DBMS_POSTGRESQL:      
          oGrps = new DBSubset(DB.k_acl_groups, "'<OPTION VALUE=' || CAST(" + DB.gu_acl_group + " AS VARCHAR(32)) || '>' || " + DB.nm_acl_group, DB.bo_active + "<>0 AND " + DB.id_domain + "=" + sDomain + " ORDER BY " + DB.nm_acl_group, 256);
          break;
        case JDCConnection.DBMS_ORACLE:      
          oGrps = new DBSubset(DB.k_acl_groups, "'<OPTION VALUE=' || " + DB.gu_acl_group + " || '>' || " + DB.nm_acl_group, DB.bo_active + "<>0 AND " + DB.id_domain + "=" + sDomain + " ORDER BY " + DB.nm_acl_group, 256);
          break;
        case JDCConnection.DBMS_MYSQL:
          oGrps = new DBSubset(DB.k_acl_groups, "CONCAT('<OPTION VALUE='," + DB.gu_acl_group + ",'>'," + DB.nm_acl_group + ")", DB.bo_active + "<>0 AND " + DB.id_domain + "=" + sDomain + " ORDER BY " + DB.nm_acl_group, 256);
          break;
      }

      oDom  = new ACLDomain(oConn, Integer.parseInt(sDomain,10));

      oGrps.load(oConn);
      oGrps.setColumnDelimiter("");
      oGrps.setRowDelimiter("");

      iRows = oPerm.load(oConn);
            
      // Si no es una nueva categoria, entonces cargar sus datos
      oCatg = new Category(oConn, id_category);

      if (id_domain==1024) iDoms = oDoms.load(oConn);
    
      oConn.close("catgrps");
    }
  catch(SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("catgrps");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));  
  }

  if (null==oConn) return;
  oConn = null;
%>

  <!-- +-----------------------------------------------+ -->
  <!-- | Edición de permisos de Usuarios por Grupo     | -->
  <!-- | © KnowGate 2001                               | -->
  <!-- +-----------------------------------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit permissions of Category per Group</TITLE>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
    
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      var frm = window.document.forms[0];
      var grp = frm.sel_all_grps.options;
      var lst = "";
      
      frm.acl_mask.value = getCombo(frm.sel_mask);
                  
      frm.grp_list.value = "";
      
      for (var n=0; n<grp.length; n++)
        if (grp[n].selected) lst += grp[n].value + ",";      
                  
      if (lst.length>0)
        frm.grp_list.value = lst.substr(0, lst.length-1);
      else
        return false;
        
      return true;        
    }

    function editCategory() {
      window.document.location = "catedit.jsp?id_domain=<%=sDomain%>&id_category=<%=id_category%>&n_category=" + escape("<%=n_category%>") + "&id_parent_cat=" + document.forms[0].id_parent_cat.value;
    }

    function editUserPerms() {
      window.document.location = "catusrs.jsp?id_domain=<%=sDomain%>&id_category=<%=id_category%>&n_category=" + escape("<%=n_category%>") + "&id_parent_cat=" + document.forms[0].id_parent_cat.value;
    }

    function switchDomain() {
      window.document.location="catgrps.jsp?id_domain=" + getCombo(document.forms[0].sel_domains) + "&id_category=" + getURLParam("id_category") + "&n_category=" + getURLParam("n_category") + (getURLParam("id_parent_cat")!=null ? "&id_parent_cat="+getURLParam("id_parent_cat") : "");
    }
               
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4">
  <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Permissions per Group <%=n_category%></FONT></TD></TR></TABLE>
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>
  <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>
  <FORM METHOD="post" ACTION="catgrps_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=sDomain%>">  
    <INPUT TYPE="hidden" NAME="id_category" VALUE="<%=request.getParameter("id_category")%>">
    <INPUT TYPE="hidden" NAME="n_category" VALUE="<%=request.getParameter("n_category")%>">    
    <INPUT TYPE="hidden" NAME="id_parent_cat" VALUE="<% out.write(id_parent); %>">
    <INPUT TYPE="hidden" NAME="grp_list">
    <INPUT TYPE="hidden" NAME="acl_mask">
    <INPUT TYPE="hidden" NAME="tp_action">
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
            <TD ALIGN="right" VALIGN="top" WIDTH="90"><FONT CLASS="formstrong">Groups:</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_all_grps" STYLE="width:330" SIZE="6" MULTIPLE><%=oGrps.toString()%></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90">&nbsp;</TD>
            <TD ALIGN="left"><SELECT NAME="sel_mask"><OPTION VALUE="1">List<OPTION VALUE="3">Read<OPTION VALUE="7">Add and Read<OPTION VALUE="15">Moderate<OPTION VALUE="31">Modify<OPTION VALUE="255">Full Control</SELECT>&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="Modify" CLASS="pushbutton" TITLE="Modify permissions of selected groups" STYLE="width:90" onClick="document.forms[0].tp_action.value='modify'">&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="Delete" CLASS="pushbutton" TITLE="Remove permissions of selected groups" STYLE="width:90" onClick="document.forms[0].tp_action.value='remove'"></TD>
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
              <SELECT NAME="sel_cat_grps" STYLE="width:330" SIZE="6">
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
