<%@ page import="java.net.URLDecoder,java.util.Vector,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/listchilds.jspf" %><%

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

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  final int Config=30;
    
  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String sHeadStrip;
  
  if (null==request.getParameter("id_domain")) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Dominio no encontrado&desc=Imposible encontrar el dominio de seguridad para la categoria&resume=_close"));
    return;
  }
  
  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String gu_user = getCookie(request, "userid", "");
  String id_category = nullif(request.getParameter("id_category"));
  String id_parent = nullif(request.getParameter("id_parent_cat"));
  String top_parent = nullif(request.getParameter("top_parent_cat"));
  String n_category,tr_category="";
  Short  is_active;
  Short  id_doc_status;
  String nm_icon1,nm_icon2;
  int iRowCount; // Nº de filas en la matriz de nombres traducidos
  int iColCount; // Nº de columnas en la matriz de nombres traducidos
  boolean bAdmin;
    
  Category   oCatg; // Categoria  
  ACLUser    oUser; // Usuario logado
  DBSubset   oPrnt; // Lista de nodos padre de esta categoria
  Object     oFld;  // Variable intermedia

  JDCConnection oConn; // Conexion con la BB.DD.
  PreparedStatement oBrowseChilds;
  StringBuffer oSelParents;
    
  // Conectar con la BB.DD.  
  oConn = GlobalDBBind.getConnection("listcatedit");
  
  if ((iAppMask & (1<<Config))==0)
    bAdmin = false;
  else {
    oUser = new ACLUser();
    oUser.put(DB.gu_user, gu_user);
    oUser.put(DB.id_domain, id_domain);
    bAdmin = oUser.isDomainAdmin(oConn);
    oUser = null;
  }
  
  // Get categories list in a <SELECT> tag
  oSelParents = new StringBuffer();
  oBrowseChilds = oConn.prepareStatement("SELECT c." + DB.gu_category + "," + DBBind.Functions.ISNULL + "(l." + DB.tr_category + ",c." + DB.nm_category + ") FROM " + DB.k_categories + " c," + DB.k_cat_tree + " t," + DB.k_cat_labels + " l WHERE c." + DB.gu_category + "=t." + DB.gu_child_cat + " AND l." + DB.gu_category + "=c." + DB.gu_category + " AND l." + DB.id_language + "='" + sLanguage + "' AND t." + DB.gu_parent_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
  listChilds (oSelParents, oBrowseChilds, id_category, top_parent, 3);
  oBrowseChilds.close();
  
  if (0!=id_category.length()) {
    
    oCatg = new Category(oConn, id_category);
    n_category = oCatg.getString(DB.nm_category);
    tr_category = oCatg.getLabel(oConn, sLanguage);
    
    is_active = new Short(String.valueOf(oCatg.get(DB.bo_active)));
    
    if (oCatg.isNull(DB.id_doc_status))
      id_doc_status = new Short((short)0);
    else
      id_doc_status = new Short((short)0);
    
    nm_icon1 = oCatg.getStringNull(DB.nm_icon, "folderclosed_16x16.gif");
    nm_icon2 = oCatg.getStringNull(DB.nm_icon2, "folderopen_16x16.gif");
    
    // Get parent
    oPrnt = oCatg.getParents(oConn);
    id_parent = oPrnt.getString(0,0);

    sHeadStrip = "Edit Category "+oCatg.getLabel(oConn, sLanguage);
    
    oCatg = null;
  }
  else {
    sHeadStrip = "New Category";

    n_category = new String("");
    is_active = new Short((short)1);
    id_doc_status = new Short((short)0);
    nm_icon1 = "folderclosed_16x16.gif";
    nm_icon2 = "folderopen_16x16.gif";
    
  
    iRowCount = iColCount = 0;
  }

  oConn.close("listcatedit");
  oConn = null;
%>
<!-- +-----------------------+ -->
<!-- | Edición de categorias | -->
<!-- | © KnowGate 2010       | -->
<!-- +-----------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=sHeadStrip%></TITLE>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>    
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      var frm = document.forms[0];

			if (frm.tr_category.length==0) {
        alert ("The category name is required");
        frm.tr_category.focus();
        return false;        
			}   

      frm.id_parent_cat.value = getCombo(frm.sel_parent_cat);

      if (frm.id_parent_cat.value=="<%=id_category%>") {
          alert ("The category cannot be parent of itself");
          return false;        
      }
   
      return true;
    } // validate
    
    function setCombos() {
      var frm = document.forms[0];
  		setCombo(frm.sel_parent_cat, "<%=id_parent%>");
    }
  //-->
  </SCRIPT>
</HEAD>

<BODY TOPMARGIN="4" MARGINHEIGHT="4" onLoad="setCombos()">
  <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1"><%=sHeadStrip%></FONT></TD></TR></TABLE>

  <FORM NAME="linkedit" METHOD="post" ACTION="catedit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_category" VALUE="<% out.write(id_category); %>">
    <INPUT TYPE="hidden" NAME="n_category" MAXLENGTH="30" SIZE="34" VALUE="<% out.write(n_category); %>">
    <INPUT TYPE="hidden" NAME="nm_icon1" VALUE="<% out.write(nm_icon1); %>">
    <INPUT TYPE="hidden" NAME="nm_icon2" VALUE="<% out.write(nm_icon2); %>">

    <INPUT TYPE="hidden" NAME="id_parent_cat" VALUE="<% out.write(id_parent); %>">
    <INPUT TYPE="hidden" NAME="id_parent_old" VALUE="<% out.write(id_parent); %>">
    <INPUT TYPE="hidden" NAME="top_parent" VALUE="<% out.write(top_parent); %>"> 
    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">	      
          <TR>
            <TD ALIGN="right" CLASS="formstrong">Parent</TD>
            <TD ALIGN="left"><SELECT NAME="sel_parent_cat"><OPTION VALUE="<% out.write (top_parent);%>">ROOT</OPTION><% out.write(oSelParents.toString()); %></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formstrong">Visible:</TD>
            <TD ALIGN="left" WIDTH="290">
              <INPUT TYPE="checkbox" NAME="is_active" VALUE="1" <% if (is_active.intValue()!=0) out.write(" CHECKED=\"true\" "); %>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
              <INPUT TYPE="hidden" NAME="id_doc_status" VALUE="1">
            </TD>
          </TR>
          <TR>
          	<TD CLASS="formstrong">Name:</TD>
          	<TD><INPUT TYPE="text" NAME="tr_category" MAXLENGTH="30" SIZE="34" VALUE="<%=tr_category%>"></TD>
          </TR>
          <TR>
    	      <TD COLSPAN="2"><HR></TD>
  	  		</TR>
          <TR>
    	    <TD>&nbsp;</TD>
    	    <TD>
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
