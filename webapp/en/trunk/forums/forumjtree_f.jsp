<%@ page import="com.knowgate.debug.DebugFile,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.*,com.knowgate.forums.*,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
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

       JDCConnection oConn = null;
       PreparedStatement oStmt;
       ResultSet oRSet;
       String sCatId;
       String sCatNm;
       String sCatTr;
       String sCatTl;
       String sCatIc;
       boolean   bIsAdmin;       
       ACLDomain oDomain;
       DBSubset  oChilds;
       Category  oDomainCat,oAppsCat;
       String    sAppsCat;
       String    sForumsCat;
       NewsGroup oForumsGrp;
       StringBuffer oBuffer = new StringBuffer();

       int id_domain = 0;
       try {
         id_domain = Integer.parseInt(getCookie(request,"domainid",""));
       } 
       catch (NumberFormatException nfe) {
         response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Invalid session&desc=The system does not recognize your user session&resume=../blank.htm"));
	 return;       
       }
	
       String gu_workarea = getCookie(request,"workarea",null);
       String id_user = getCookie(request,"userid","");
       String nm_domain = getCookie(request,"domainnm","");
              
       String sSkin = getCookie(request, "skin", "xp");
       String sLanguage = getNavigatorLanguage(request);
       String sQryStr;
        
       oConn = GlobalDBBind.getConnection("forums_tree_f");
              
       try {
         bIsAdmin = WorkArea.isAdmin(oConn, gu_workarea, id_user);
         // Buscar por nombre la categoría raiz de los foros
         sForumsCat = Category.getIdFromName(oConn, nm_domain + "_apps_forums");
                             
         // [~//Si no existe la categoría raiz de la aplicación de foros, crearla dinamicamente sobre la marcha~]
         if (null==sForumsCat) {
                    
	   // [~//Crear un objeto de referencia al dominio~]
	   oDomain = new ACLDomain(oConn, id_domain);
	 
           sAppsCat = Category.getIdFromName(oConn, nm_domain + "_APPS");

	   if (sAppsCat==null)
	     throw new SQLException("Category " + nm_domain + "_APPS not found");

	   sForumsCat = NewsGroup.store(oConn, id_domain, gu_workarea, null, sAppsCat, nm_domain + "_apps_forums", (short)1, (short)1, oDomain.getString(DB.gu_owner), "forums_16x16.gif", "forums_16x16.gif");
	   
	   oForumsGrp = new NewsGroup(sForumsCat);
	     	   
	   oForumsGrp.setUserPermissions(oConn, oDomain.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
	   oForumsGrp.setGroupPermissions(oConn, oDomain.getString(DB.gu_admins), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
	 
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "es", "foros", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "en", "forum", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "it", "forum", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "fr", "forum", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "de", "forum", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "br", "fórum", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "cn", "论坛", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "tw", "論壇", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "fi", "foorumi", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "ru", "форум", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "uk", "форум", null});
	   CategoryLabel.create (oConn, new Object[]{oForumsGrp.getString(DB.gu_category), "vn", "diễn đàn", null});	   

	 } // fi (sForumsCat)
	 else
	   oForumsGrp = new NewsGroup(sForumsCat);
	 
	 if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
	   if (DebugFile.trace)
	     DebugFile.writeln("Connection.prepareStatement(SELECT c." + DB.gu_category + ",NVL(l." + DB.tr_category + ",c." + DB.nm_category + "),c." + DB.nm_icon + " FROM " + DB.k_cat_tree + " t, " + DB.k_categories + " c, " + DB.k_cat_labels + " l WHERE c." + DB.gu_category + "=l." + DB.gu_category + "(+) AND l." + DB.id_language + "='" + sLanguage + "' AND t." + DB.gu_child_cat + "=c." + DB.gu_category + " AND t." + DB.gu_parent_cat + "='" + oForumsGrp.getStringNull(DB.gu_category,"null") + "')");
	     
	   oStmt = oConn.prepareStatement("(SELECT c." + DB.gu_category + ",NVL(l." + DB.tr_category + ",c." + DB.nm_category + "),c." + DB.nm_icon + " FROM " + DB.k_cat_tree + " t, " + DB.k_categories + " c, " + DB.k_cat_labels + " l WHERE c." + DB.gu_category + "=l." + DB.gu_category + "(+) AND l." + DB.id_language + "=? AND t." + DB.gu_child_cat + "=c." + DB.gu_category + " AND t." + DB.gu_parent_cat + "=?) UNION (SELECT c.gu_category,c.nm_category,c.nm_icon FROM k_cat_tree t, k_categories c WHERE NOT EXISTS (SELECT l.gu_category FROM k_cat_labels l WHERE l.gu_category=c.gu_category AND l.id_language=?) AND t.gu_child_cat=c.gu_category AND t.gu_parent_cat=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	 }
	 else {
	   if (DebugFile.trace)
	     DebugFile.writeln("Connection.prepareStatement(SELECT c.gu_category," + DBBind.Functions.ISNULL + "(l.tr_category,c.nm_category),c.nm_icon FROM k_cat_tree t, k_categories c LEFT OUTER JOIN k_cat_labels l ON c.gu_category=l.gu_category WHERE l.id_language='" + sLanguage + "' AND t.gu_child_cat=c.gu_category AND t.gu_parent_cat='" + oForumsGrp.getStringNull(DB.gu_category, "") + "')");
	   
	   oStmt = oConn.prepareStatement("(SELECT c.gu_category," + DBBind.Functions.ISNULL + "(l.tr_category,c.nm_category),c.nm_icon FROM k_cat_tree t, k_categories c LEFT OUTER JOIN k_cat_labels l ON c.gu_category=l.gu_category WHERE l.id_language=? AND t.gu_child_cat=c.gu_category AND t.gu_parent_cat=?) UNION (SELECT c.gu_category,c.nm_category,c.nm_icon FROM k_cat_tree t, k_categories c WHERE NOT EXISTS (SELECT l.gu_category FROM k_cat_labels l WHERE l.gu_category=c.gu_category AND l.id_language=?) AND t.gu_child_cat=c.gu_category AND t.gu_parent_cat=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
         }
         
	 oStmt.setString(1, sLanguage);
	 oStmt.setString(2, oForumsGrp.getString(DB.gu_category));
	 oStmt.setString(3, sLanguage);
	 oStmt.setString(4, oForumsGrp.getString(DB.gu_category));

	 if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");
	     
	 oRSet = oStmt.executeQuery();
	 
	 while (oRSet.next()) {
	   sCatId = oRSet.getString(1);
	   sCatTr = Gadgets.HTMLEncode(oRSet.getString(2));
	   sCatTl = Gadgets.URLEncode(oRSet.getString(2));
	   
	   if (DebugFile.trace) DebugFile.writeln("javascript:treeMenu.addItem(" + sCatTr + "," + sCatId + "," + sCatTl + ")");
	     	   
	   sCatIc = oRSet.getString(3);
	   
	   if (sCatIc!=null)
	     oBuffer.append ("treeMenu.addItem(new TreeMenuItem('" + sCatTr + "', 'return parent.selectNode(\"" + sCatId + "\",\"" + sCatTl + "\")','" + sCatIc + "'));\n");
	   else
	     oBuffer.append ("treeMenu.addItem(new TreeMenuItem('" + sCatTr + "', 'return parent.selectNode(\"" + sCatId + "\",\"" + sCatTl + "\")'));\n");

	 } // wend
	 
	 oRSet.close();
	 oStmt.close();
	 
	 oConn.close("forums_tree_f");	 
       }
       catch (SQLException e) {
         bIsAdmin = false;
         sForumsCat = sQryStr = null;
         if (null!=oConn)
           if (!oConn.isClosed()) {
             oConn.close("forums_tree_f");
             oConn = null;
           }        
         response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));           
       }
       if (null==oConn) return;
       
       oConn = null;
       
       sQryStr = "?id_domain=" + String.valueOf(id_domain) + "&id_user=" + id_user + "&id_language=" + sLanguage + "&id_parent_cat=" + sForumsCat +"&void";
%>	 
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Category Tree</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
    <!--
    // User-defined tree menu data.

    var treeMenuName       = "Forums";          // Make this unique for each tree menu.
    var treeMenuDays       = 1;                 // Number of days to keep the cookie.
    var treeMenuFrame      = "tree";            // Name of the menu frame.
    var treeMenuImgDir     = "../skins/<%=sSkin%>/nav/"        // Path to graphics directory.
    var treeMenuBackground = "../images/images/tree/menu_background.gif";               // Background image for menu frame.   
    var treeMenuBgColor    = "#FFFFFF";         // Color for menu frame background.   
    var treeMenuFgColor    = "#000000";         // Color for menu item text.
    var treeMenuHiBg       = "#034E7A";         // Color for selected item background.
    var treeMenuHiFg       = "#FFFF00";         // Color for selected item text.
    var treeMenuFont       = "Arial,Helvetica"; // Text font face.
    var treeMenuFontSize   = 1;                 // Text font size.
    var treeMenuRoot       = "FORUMS";           // Text for the menu root.
    var treeMenuFolders    = 1;                 // Sets display of '+' and '-' icons.
    var treeMenuAltText    = false;             // Use menu item text for icon image ALT text.

    
    function selectNode(guid,name) {      
      window.frames[2].document.forms[0].code.value = guid;
      window.frames[2].document.forms[0].ctrl.value = name;
      parent.parent.msgsadmin.location = "msg_list_f.htm?gu_newsgrp=" + guid + "&nm_newsgrp=" + name;
      return false;
    }

  //-->
  </SCRIPT>
  <SCRIPT SRC="forummenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    var treeMenu = new TreeMenu();   // This is the main menu.  
<%  out.write(oBuffer.toString()); %>        
  //-->
  </SCRIPT>
</HEAD>

<FRAMESET ROWS="70,*,0" BORDER=0 FRAMEBORDER="0">
<% if (bIsAdmin) { %>
  <FRAME NAME="scroll" FRAMEBORDER=0 MARGINWIDTH=8 MARGINHEIGHT=0 SRC="tree_scroll.htm<% out.write(sQryStr); %>" SCROLLING="no">
<% } else { %>
  <FRAME NAME="scroll" FRAMEBORDER=0 MARGINWIDTH=8 MARGINHEIGHT=0 SRC="../blank.htm" SCROLLING="no">
<% } %>
  <FRAME NAME="tree" FRAMEBORDER=0 MARGINWIDTH=8 SRC="tree_nodes.htm" SCROLLING="yes">
  <FRAME NAME="cmds" FRAMEBORDER=0 MARGINWIDTH=8 SRC="tree_cmds.htm<% out.write(sQryStr); %>" SCROLLING="no">
  
</FRAMESET>
<NOFRAMES>
  <BODY>
    <P>This page use frames, but your web browser does not handle them</P>
  </BODY>
</NOFRAMES>

</HTML>