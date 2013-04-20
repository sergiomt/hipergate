<%@ page import="com.knowgate.debug.DebugFile,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.*,com.knowgate.forums.*,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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
       response.addHeader ("cache-control", "private");

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
       String    sAppsCat;
       String    sMailRoot;
       Category  oRootFolder;
       ACLUser oMe;
       StringBuffer oBuffer = new StringBuffer();
	
       String gu_workarea = getCookie(request,"workarea",null);
       String id_user = getCookie(request,"userid","");
       String nm_domain = getCookie(request,"domainnm","");
       int id_domain = Integer.parseInt(getCookie(request,"domainid",""));

       String sSkin = getCookie(request, "skin", "xp");
       String sLanguage = getNavigatorLanguage(request);
       String sQryStr;

       try {
         oConn = GlobalDBBind.getConnection("folders_tree_f");
        
         oMe = new ACLUser(oConn, id_user);
         
         bIsAdmin = WorkArea.isAdmin(oConn, gu_workarea, id_user);

	       oConn.setAutoCommit(true);
	 
         sMailRoot = oMe.getMailRoot (oConn);
         
         oRootFolder = new Category(sMailRoot);
         
         String sInBox = oMe.getMailFolder(oConn, "inbox");
         String sOutBox = oMe.getMailFolder(oConn, "outbox");
         String sDrafts = oMe.getMailFolder(oConn, "drafts");
         String sDeleted = oMe.getMailFolder(oConn, "deleted");
         String sSent = oMe.getMailFolder(oConn, "sent");
         String sSpam = oMe.getMailFolder(oConn, "spam");
         String sReceived = oMe.getMailFolder(oConn, "received");
         String sReceipts = oMe.getMailFolder(oConn, "receipts");
         
	       oConn.setAutoCommit(false);

	       oBuffer.append ("treeMenu.addItem(new TreeMenuItem('Inbox', 'parent.parent.frames[3].location.href =\"folder_listing.jsp?screen_width=\"+String(screen.width);return false;','myemailc_16x16.gif'));\n");
	       oBuffer.append ("treeMenu.addItem(new TreeMenuItem('Outbox', 'parent.parent.frames[3].location.href = \"folder_listing_local.jsp?gu_folder="+sOutBox+"&screen_width=\" + String(screen.width);return false;','folderoutgoing_16x16.gif'));\n");
	       oBuffer.append ("treeMenu.addItem(new TreeMenuItem('Received messages', 'parent.parent.frames[3].location.href = \"folder_listing_local.jsp?gu_folder="+sReceived+"&screen_width=\" + String(screen.width);return false;','folderclosed_16x16.gif'));\n");
	       oBuffer.append ("treeMenu.addItem(new TreeMenuItem('Draft', 'parent.parent.frames[3].location.href = \"folder_listing_local.jsp?gu_folder="+sDrafts+"&screen_width=\" + String(screen.width);return false;','foldertempo_16x16.gif'));\n");
	       oBuffer.append ("treeMenu.addItem(new TreeMenuItem('Deleted Messages', 'parent.parent.frames[3].location.href = \"folder_listing_local.jsp?gu_folder="+sDeleted+"&screen_width=\" + String(screen.width);return false;','recycledempty_16x16.gif'));\n");
	       oBuffer.append ("treeMenu.addItem(new TreeMenuItem('Sent Messsages', 'parent.parent.frames[3].location.href = \"folder_listing_local.jsp?gu_folder="+sSent+"&screen_width=\" + String(screen.width);return false;','folderclosed_16x16.gif'));\n");
	       oBuffer.append ("treeMenu.addItem(new TreeMenuItem('Bulk Mail', 'parent.parent.frames[3].location.href = \"folder_listing_local.jsp?gu_folder="+sSpam+"&screen_width=\" + String(screen.width);return false;','folderred_16x16.gif'));\n");
	       oBuffer.append ("treeMenu.addItem(new TreeMenuItem('Read receipts', 'parent.parent.frames[3].location.href = \"folder_listing_local.jsp?gu_folder="+sReceipts+"&screen_width=\" + String(screen.width);return false;','folder_receipts16.gif'));\n");
         
         String sSQL;
                                            	 
	 if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
	   
	   sSQL = "SELECT c." + DB.gu_category + ",NVL(l." + DB.tr_category + ",c." + DB.nm_category + "),c." + DB.nm_icon +
	          " FROM " + DB.k_cat_tree + " t, " + DB.k_categories + " c, " + DB.k_cat_labels +
	   	  " l WHERE c." + DB.gu_category + "=l." + DB.gu_category + "(+) AND l." + DB.id_language + "=? AND t." +
	   	  DB.gu_child_cat + "=c." + DB.gu_category + " AND t." + DB.gu_parent_cat +
	   	  "=? AND c." + DB.gu_category + " NOT IN ('"+sInBox+"','"+sOutBox+"','"+sDrafts+"','"+sDeleted+"','"+sSent+"','"+sSpam+"','"+sReceived+"','"+sReceipts+"') " +
	   	  " UNION SELECT c.gu_category,c.nm_category,c.nm_icon FROM k_cat_tree t, k_categories c WHERE NOT EXISTS (SELECT l.gu_category FROM k_cat_labels l WHERE l.gu_category=c.gu_category AND l.id_language=?) AND t.gu_child_cat=c.gu_category AND t.gu_parent_cat=?" +
	   	  " AND c." + DB.gu_category + " NOT IN ('"+sInBox+"','"+sOutBox+"','"+sDrafts+"','"+sDeleted+"','"+sSent+"','"+sSpam+"','"+sReceived+"','"+sReceipts+"') ";

	   if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
	     
	   oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	 }
	 else {
	   sSQL = "(SELECT c." + DB.gu_category+ "," + DBBind.Functions.ISNULL + "(l."+DB.tr_category+",c."+DB.nm_category+"),c."+DB.nm_icon+
                  " FROM " + DB.k_cat_tree+" t, "+DB.k_categories+" c LEFT OUTER JOIN "+DB.k_cat_labels+" l ON c."+DB.gu_category+"=l."+DB.gu_category+
	   	  " WHERE l."+DB.id_language+"=? AND t."+DB.gu_child_cat+"=c."+DB.gu_category+" AND t."+DB.gu_parent_cat+"=? "+
	   	  " AND c." + DB.gu_category + " NOT IN ('"+sInBox+"','"+sOutBox+"','"+sDrafts+"','"+sDeleted+"','"+sSent+"','"+sSpam+"','"+sReceived+"','"+sReceipts+"')) " +
	   	  " UNION (SELECT c.gu_category,c.nm_category,c.nm_icon FROM k_cat_tree t, k_categories c WHERE NOT EXISTS (SELECT l.gu_category FROM k_cat_labels l WHERE l.gu_category=c.gu_category AND l.id_language=?) AND t.gu_child_cat=c.gu_category AND t.gu_parent_cat=?" +
	   	  " AND c." + DB.gu_category + " NOT IN ('"+sInBox+"','"+sOutBox+"','"+sDrafts+"','"+sDeleted+"','"+sSent+"','"+sSpam+"','"+sReceived+"','"+sReceipts+"')) ";

	   if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
	   
	   oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
         }
         
	 oStmt.setString(1, sLanguage);
	 oStmt.setString(2, sMailRoot);
	 oStmt.setString(3, sLanguage);
	 oStmt.setString(4, sMailRoot);

	 if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");
	     
	 oRSet = oStmt.executeQuery();
	 
	 while (oRSet.next()) {
	   sCatId = oRSet.getString(1);
	   sCatTr = Gadgets.HTMLEncode(oRSet.getString(2));
	   sCatTl = Gadgets.URLEncode(oRSet.getString(2));
	   
	   if (DebugFile.trace) DebugFile.writeln("javascript:treeMenu.addItem(" + sCatTr + "," + sCatId + "," + sCatTl + ")");
	     	   
	   sCatIc = oRSet.getString(3);
	   
	   if (sCatIc!=null)
	     oBuffer.append ("treeMenu.addItem(new TreeMenuItem('" + sCatTr + "', 'parent.selectNode(\"" + sCatId + "\",\"" + sCatTl + "\")','" + sCatIc + "'));\n");
	   else
	     oBuffer.append ("treeMenu.addItem(new TreeMenuItem('" + sCatTr + "', 'parent.selectNode(\"" + sCatId + "\",\"" + sCatTl + "\")'));\n");

	 } // wend
	 
	 oRSet.close();
	 oStmt.close();
	 
	 oConn.close("folders_tree_f");	 
       }
       catch (SQLException e) {
         bIsAdmin = false;
         sMailRoot = sQryStr = null;
         if (null!=oConn)
           if (!oConn.isClosed()) {
             try { if (!oConn.getAutoCommit()) oConn.rollback(); } catch (Exception ignore) {}
             oConn.close("folders_tree_f");
             oConn = null;
           }        
         response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));           
       }
       if (null==oConn) return;
       
       oConn = null;
       
       sQryStr = "?id_domain=" + String.valueOf(id_domain) + "&id_user=" + id_user + "&id_language=" + sLanguage + "&id_parent_cat=" + sMailRoot +"&void";
%>	 
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
    <!--
    // User-defined tree menu data.

    var treeMenuName       = "MailFolders";     // Make this unique for each tree menu.
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
    var treeMenuRoot       = "<a href=mailhome.jsp target=listshow>Local Folders</a>";           // Text for the menu root.
    var treeMenuFolders    = 1;                 // Sets display of '+' and '-' icons.
    var treeMenuAltText    = false;             // Use menu item text for icon image ALT text.


/*    
    function selectNode(guid,name) {      
      window.frames[2].document.forms[0].code.value = guid;
      window.frames[2].document.forms[0].ctrl.value = name;
      parent.parent.msgsadmin.location = "msg_list_f.htm?gu_newsgrp=" + guid + "&nm_newsgrp=" + name;
    }
*/

  //-->
  </SCRIPT>
  <SCRIPT SRC="mailfolders.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    var treeMenu = new TreeMenu();   // This is the main menu.  
<%  out.write(oBuffer.toString()); %>        
  //-->
  </SCRIPT>
</HEAD>

<FRAMESET ROWS="40,*,0" BORDER=0 FRAMEBORDER="0">
<% if (bIsAdmin) { %>
  <FRAME NAME="scroll" FRAMEBORDER=0 MARGINWIDTH=8 MARGINHEIGHT=0 SRC="tree_scroll.htm<% out.write(sQryStr); %>" SCROLLING="no">
<% } else { %>
  <FRAME NAME="scroll" FRAMEBORDER=0 MARGINWIDTH=8 MARGINHEIGHT=0 SRC="../blank.htm" SCROLLING="no">
<% } %>
  <FRAME NAME="tree" FRAMEBORDER=0 MARGINWIDTH=8 SRC="tree_nodes.htm" SCROLLING="no">
  <FRAME NAME="cmds" FRAMEBORDER=0 MARGINWIDTH=8 SRC="tree_cmds.htm<% out.write(sQryStr); %>" SCROLLING="no">
  
</FRAMESET>
<NOFRAMES>
  <BODY>
    <P>This page uses frames but your browser does not support them</P>
  </BODY>
</NOFRAMES>

<HTML>