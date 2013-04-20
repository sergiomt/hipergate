<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.debug.DebugFile,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%!
  static void addChilds (JDCConnection oConn, String sLang, StringBuffer oBuffer, String sParentCat, int iParentNode, String sChildCatId) throws SQLException {
    DBSubset oChlds;
    int iChlds;
    int iChld;
    String sSubCat;
        
    oChlds = new DBSubset(DB.k_categories + " c," + DB.k_cat_tree + " t," + DB.k_cat_labels + " l",
    			  "c." + DB.gu_category	+ ",c." + DB.nm_category + ",l." + DB.tr_category + ",c." + DB.nm_icon, 
    			  "t." + DB.gu_parent_cat + "=? AND t." + DB.gu_child_cat + "=c." + DB.gu_category + " AND l." + DB.gu_category + "=c." + DB.gu_category + " AND l." + DB.id_language + "='" + sLang + "'", 10);
    iChlds = oChlds.load(oConn, new Object[]{sChildCatId});

    if (iChlds>0) {
      sSubCat = "C_" + sChildCatId;
      oBuffer.append ("    var " + sSubCat + " = new TreeMenu();\n");
    
      for (int c=0; c<iChlds; c++) {
        if (oChlds.isNull(3,c))
          oBuffer.append ("    " + sSubCat + ".addItem(new TreeMenuItem('" + oChlds.getString(2,c) + "', 'parent.selectNode(\"" + oChlds.getString(0,c) + "\",\"" + Gadgets.HTMLEncode(oChlds.getStringNull(2,c,oChlds.getString(1,c))) + "\")'));\n");
	      else
          oBuffer.append ("    " + sSubCat + ".addItem(new TreeMenuItem('" + oChlds.getString(2,c) + "', 'parent.selectNode(\"" + oChlds.getString(0,c) + "\",\"" + Gadgets.HTMLEncode(oChlds.getStringNull(2,c,oChlds.getString(1,c))) + "\")','" + oChlds.getString(3,c) + "'));\n");	
      } // next
      
      oBuffer.append ("    " + sParentCat + ".items[" + String.valueOf(iParentNode) + "].makeSubmenu(" + sSubCat + ");\n");
	      
      for (int c=0; c<iChlds; c++) {
        addChilds (oConn, sLang, oBuffer, sSubCat, c, oChlds.getString(0,c));
      } // next
      
      oChlds = null;
      
    } // fi (iChlds)
    
  } // addChilds()
  
%><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
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

    var treeMenuName       = "SubCategories";   // Make this unique for each tree menu.
    var treeMenuDays       = 1;                 // Number of days to keep the cookie.
    var treeMenuFrame      = "tree";            // Name of the menu frame.
    var treeMenuImgDir     = "../images/images/tree/"        // Path to graphics directory.
    var treeMenuBackground = "../images/images/tree/menu_background.gif";               // Background image for menu frame.   
    var treeMenuBgColor    = "#FFFFFF";         // Color for menu frame background.   
    var treeMenuFgColor    = "#000000";         // Color for menu item text.
    var treeMenuHiBg       = "#034E7A";         // Color for selected item background.
    var treeMenuHiFg       = "#FFFF00";         // Color for selected item text.
    var treeMenuFont       = "Arial,Helvetica"; // Text font face.
    var treeMenuFontSize   = 1;                 // Text font size.
    var treeMenuRoot       = "CATEGORIES";      // Text for the menu root.
    var treeMenuFolders    = 1;                 // Sets display of '+' and '-' icons.
    var treeMenuAltText    = false;             // Use menu item text for icon image ALT text.

    
    function selectNode(guid,name) {      
      window.frames[2].document.forms[0].code.value = guid;
      window.frames[2].document.forms[0].ctrl.value = name;      
    }

  //-->
  </SCRIPT>

  <SCRIPT SRC="catmenu.js"></SCRIPT>
  <SCRIPT SRC="../javascript/scroller.js" DEFER=true></SCRIPT>  

  <SCRIPT TYPE="text/javascript">
  <!--
    
    var treeMenu = new TreeMenu();   // This is the main menu.  
        
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
       String sCatIc;       
       int iNode;

       String sUserId = request.getParameter("id_user");
       String sLanguage = getNavigatorLanguage(request);
       String sQryStr = "?id_user=" + sUserId + "&id_language=" + sLanguage + "&nm_control=" + request.getParameter("nm_control") + "&nm_coding=" + request.getParameter("nm_coding");
       
       oConn = GlobalDBBind.getConnection("cat_tree_f");
       
       StringBuffer oBuffer = new StringBuffer();
       
       try {
	 if (DebugFile.trace)
	   DebugFile.writeln("SELECT DISTINCT(a.gu_category),a.nm_category,l.tr_category,a.nm_icon FROM v_cat_acl a, k_cat_tree t, k_cat_labels l WHERE a.gu_user='" + sUserId + "' AND a.gu_category=t.gu_child_cat AND a.gu_category=l.gu_category AND l.id_language='" + sLanguage + "' AND t.gu_parent_cat NOT IN (SELECT p.gu_category FROM v_cat_acl p WHERE p.gu_user='" + sUserId + "'))");
	   
         oStmt = oConn.prepareStatement("SELECT DISTINCT(a.gu_category),a.nm_category,l.tr_category,a.nm_icon FROM v_cat_acl a, k_cat_tree t, k_cat_labels l WHERE a.gu_user=? AND a.gu_category=t.gu_child_cat AND a.gu_category=l.gu_category AND l.id_language=? AND t.gu_parent_cat NOT IN (SELECT p.gu_category FROM v_cat_acl p WHERE p.gu_user=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	 oStmt.setString(1, sUserId);
	 oStmt.setString(2, sLanguage);
	 oStmt.setString(3, sUserId);
	 oRSet = oStmt.executeQuery();

	 iNode = 0;
	 while (oRSet.next()) {
	   sCatId = oRSet.getString(1);
	   sCatNm = oRSet.getString(2);
	   sCatTr = oRSet.getString(3);
	   sCatIc = oRSet.getString(4);
	   
	   if (sCatIc!=null)
	     out.write ("treeMenu.addItem(new TreeMenuItem('" + sCatTr + "', 'parent.selectNode(\"" + sCatId + "\",\"" + Gadgets.HTMLEncode(sCatTr==null ? sCatNm : sCatTr) + "\")','" + sCatIc + "'));\n");
	   else
	     out.write ("treeMenu.addItem(new TreeMenuItem('" + sCatTr + "', 'parent.selectNode(\"" + sCatId + "\",\"" + Gadgets.HTMLEncode(sCatTr==null ? sCatNm : sCatTr) + "\")'));\n");

	   addChilds(oConn, sLanguage, oBuffer, "treeMenu", iNode, sCatId);
	   
	   iNode++;
	 } // wend (oRSet.next())

	 oRSet.close();
	 oStmt.close();
	 
	 oConn.close("cat_tree_f");	 
	 oConn = null;
       }
       catch (SQLException e) {
         if (null!=oConn)
           if (!oConn.isClosed()) {
             oConn.close("cat_tree_f");
             oConn = null;
           }        
         response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
       }
    out.write (oBuffer.toString());

    %>	 
  //-->
  </SCRIPT>
</HEAD>

<FRAMESET ROWS="16,*,60" BORDER=0 FRAMEBORDER="0">
  <FRAME NAME="scroll" FRAMEBORDER=0 MARGINWIDTH=0 MARGINHEIGHT=0 SRC="tree_scroll.htm" SCROLLING="no">
  <FRAME NAME="tree" FRAMEBORDER=0 MARGINWIDTH=8 SRC="tree_nodes.htm" SCROLLING="yes">
  <FRAME NAME="cmds" FRAMEBORDER=0 MARGINWIDTH=8 SRC="tree_cmds.htm<% out.write(sQryStr); %>" SCROLLING="no">
  
</FRAMESET>
<NOFRAMES>
  <BODY>
    <P>Resultados da Busca</P>
  </BODY>
</NOFRAMES>


<HTML>
