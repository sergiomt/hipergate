<%@ page import="java.sql.Connection,java.sql.ResultSet,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");

  String sLanguage = getNavigatorLanguage(request);
  String sDomain = request.getParameter("id_domain");;
  String id_category = request.getParameter("id_category");
  String n_category = request.getParameter("n_category");
  
  Category   oCatg;
  ACL        oACL  = new ACL();
  DBSubset   oUsrs = new DBSubset(DB.k_users, "'<OPTION VALUE=\"' + " + DB.id_user + " + '\">' + " + DB.nickname + " + '  -  ' + ISNULL(" + DB.n_user + ",'') + ISNULL(' ' + " DB.n_user + ",'') + ISNULL(' ' + " + DB.surname1 + ",'') + ISNULL(' ' + " + DB.surname2 + ",'')", DB.activated + "<>0 AND " + DB.id_domain + "=" + sDomain + " ORDER BY " + DB.nickname, 256);
  DBSubset   oPerm = new DBSubset(DB.k_users + " u, " + DB.k_x_cat_user_acl + " a", "u." + DB.id_user + ",u." + DB.nickname + ",a." + DB.acl_mask, "u." + DB.id_user + "=a." + DB.id_user + " AND a." + DB.id_category + "=" + id_category, 128);

  JDCConnection oConn = null; // DB Connection
    
    try {

      oConn = GlobalDBBind.getConnection("catusers");
    
      oUsrs.load(oConn);
      oUsrs.setColumnDelimiter("");
      oUsrs.setRowDelimiter("");

      oPerm.load(oConn);
            
      // If not a new category, load data
      oCatg = new Category(oConn, new Integer(id_category));
    
      oConn.close("catusers");
    }
  catch(SQLException e) {
    if (!oConn.isClosed()) oConn.close("catusers");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));  
  }
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
           
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4" onLoad="preCache()">
  <TABLE WIDTH="100%"><TR><TD CLASS="strip1"><FONT CLASS="title1">Edit permissions of Category per User</FONT></TD></TR></TABLE>
  <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>
  <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>
  <FORM NAME="linkedit" METHOD="post" ACTION="catusers_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_category" VALUE="<%=request.getParameter("id_category")%>">
    <INPUT TYPE="hidden" NAME="n_category" VALUE="<%=request.getParameter("n_category")%>">
    <INPUT TYPE="hidden" NAME="usr_list"><INPUT TYPE="hidden" NAME="acl_mask"><INPUT TYPE="hidden" NAME="tp_action">
    <TABLE WIDTH="100%" CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Domain:</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_domains"><OPTION VALUE="1">World</SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="90"><FONT CLASS="formstrong">Users:</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_all_users" STYLE="width:330" SIZE="6" MULTIPLE><%=oUsrs.toString()%></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90">&nbsp;</TD>
            <TD ALIGN="left"><SELECT NAME="sel_mask"><OPTION VALUE="1">List<OPTION VALUE="3">Read<OPTION VALUE="7">Add and Read<OPTION VALUE="15">Moderate<OPTION VALUE="31">Modify<OPTION VALUE="255">Full Control</SELECT>&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="Modify" CLASS="pushbutton" TITLE="Modify permissions for selected users" STYLE="width:90" onClick="document.forms[0].tp_action.value='modify'">&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="Delete" CLASS="pushbutton" TITLE="Delete permissions for selected users" STYLE="width:90" onClick="document.forms[0].tp_action.value='remove'"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90">&nbsp;</TD>
            <TD ALIGN="left"><INPUT TYPE="checkbox" NAME="recurse" VALUE="1" CHECKED><SPAN><FONT CLASS="textplain">Propagate to child categories</FONT></SPAN></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="90"><FONT CLASS="formstrong">Permissions:</FONT></TD>
            <TD ALIGN="left">
              <SELECT NAME="sel_cat_users" STYLE="width:330" SIZE="6">
                <%
                  int iRows = oPerm.getRowCount();
                  
                  for (int r=0; r<iRows; r++)
                    out.write("                <OPTION VALUE=\"" + oPerm.getString(0,r) + "\">" + oPerm.getString(1,r) + "  -  " + oACL.getLocalizedMaskName(oPerm.getInt(2,r)));
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
    	      <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	    </TD>	    
          </TR>           
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
</BODY>

</HTML>
