<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %><%!
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

  static void addSubordinates (JDCConnection oConn, StringBuffer oBuffer, String sBoss, int iBoss, String sSubDe, String sWorkArea) throws SQLException {
    DBSubset oSbrdts;
    int      iSbrdts;
    int      iSbrdt;
    String sSubordinate;
    
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.debug.DebugFile.writeln("addSubordinates([Connection],[StringBuffer]," + sBoss + "," + String.valueOf(iBoss) + "," + sSubDe + "," + sWorkArea + ")");

    oSbrdts = new DBSubset(DB.k_lu_fellow_titles + " t",
    			  "t." + DB.de_title,
    			  "t." + DB.id_boss + "=? AND " + DB.gu_workarea + "=?", 10);
    			  
    iSbrdts = oSbrdts.load(oConn, new Object[]{sSubDe,sWorkArea});

    if (iSbrdts>0) {
      sSubordinate = "C_" + Gadgets.ASCIIEncode(sSubDe).replace(' ','_').replace('-','_');
      oBuffer.append ("    var " + sSubordinate + " = new TreeMenu();\n");
    
      for (int c=0; c<iSbrdts; c++)
        oBuffer.append ("    " + sSubordinate + ".addItem(new TreeMenuItem('" + oSbrdts.getString(0,c) + "', 'editfellowtitle.jsp?gu_workarea=" + sWorkArea + "&de_title=" + Gadgets.URLEncode(oSbrdts.getString(0,c)) + "', 'edittitle', 'person13.gif'));\n");

      oBuffer.append ("    " + sBoss + ".items[" + String.valueOf(iBoss) + "].makeSubmenu(" + sSubordinate + ");\n");
	      
      for (int c=0; c<iSbrdts; c++)
        addSubordinates (oConn, oBuffer, sSubordinate, c, oSbrdts.getString(0,c), sWorkArea);

      oSbrdts = null;
    } // fi (iSbrdts)
    
  } // addSubordinates()
  
%>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%
  // [~//Inicio de sesion anónimo permitido~]
  // if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sWorkArea = getCookie(request,"workarea", "");

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Corporate Chart Tree</TITLE>
    <SCRIPT TYPE="text/javascript">
    <!--
          
    document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/xp/styles.css">');
                    
    // User-defined tree menu data.

    var treeMenuName       = "OrgTree"; // Make this unique for each tree menu.
    var treeMenuDays       = 1;                // Number of days to keep the cookie.
    var treeMenuFrame      = "tree";           // Name of the menu frame.
    var treeMenuImgDir     = "../images/images/tree/"        // Path to graphics directory.
    var treeMenuBackground = "../images/images/tree/menu_background.gif";               // Background image for menu frame.   
    var treeMenuBgColor    = "#FFFFFF";        // Color for menu frame background.   
    var treeMenuFgColor    = "#000000";        // Color for menu item text.
    var treeMenuHiBg       = "#034E7A";        // Color for selected item background.
    var treeMenuHiFg       = "#FFFF00";        // Color for selected item text.
    var treeMenuFont       = "Arial,Helvetica"; // Text font face.
    var treeMenuFontSize   = 2;                    // Text font size.
    var treeMenuRoot       = "Organizative Tree"; // Text for the menu root.
    var treeMenuFolders    = 1;                    // Sets display of '+' and '-' icons.
    var treeMenuAltText    = false;                 // Use menu item text for icon image ALT text.
    
    var SelectedNode;
    var SelectedName;
    
    function selectNode(name) {      
      window.frames[2].document.forms[0].code.value = guid;
      window.frames[2].document.forms[0].ctrl.value = name;
    }

  //-->
  </SCRIPT>

  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/treemenu.js"></SCRIPT>

  <SCRIPT TYPE="text/javascript">
  <!--
    
    var treeMenu = new TreeMenu();   // This is the main menu.  

    treeMenuOlderOpen = "person13.gif";
    treeMenuOlderClosed = "person13.gif";
        
    <%
       JDCConnection oConn = null;
       PreparedStatement oStmt;
       ResultSet oRSet;
       String sTitleDe;
       int iNode;

       String sUserId = request.getParameter("id_user");
       String sQryStr = "?id_user=" + sUserId + "&nm_control=" + request.getParameter("nm_control") + "&nm_coding=" + request.getParameter("nm_coding");
       
       oConn = GlobalDBBind.getConnection("org_tree_f");
       
       StringBuffer oBuffer = new StringBuffer();
       
       try {
         oStmt = oConn.prepareStatement("SELECT " + DB.de_title + " FROM " + DB.k_lu_fellow_titles + " WHERE " + DB.id_boss + " IS NULL AND " + DB.gu_workarea + "='" + sWorkArea + "'", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	 oRSet = oStmt.executeQuery();
	 iNode = 0;
	 while (oRSet.next()) {
	   sTitleDe = oRSet.getString(1);
	   
	   out.write ("treeMenu.addItem(new TreeMenuItem('" + sTitleDe + "', 'editfellowtitle.jsp?gu_workarea=" + sWorkArea + "&de_title=" + Gadgets.URLEncode(sTitleDe) + "', 'edittitle', 'person13.gif'));\n");

	   addSubordinates(oConn, oBuffer, "treeMenu", iNode, sTitleDe, sWorkArea);
	   
	   iNode++;
	 } // wend (oRSet.next())
	 oRSet.close();
	 oStmt.close();
	 
	 oConn.close("org_tree_f");	 
       }
       catch (SQLException e) {
         if (null!=oConn)
           if (!oConn.isClosed()) {
             oConn.close("org_tree_f");
           }        
         oConn = null;

         if (com.knowgate.debug.DebugFile.trace) {      
           com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
         }
         
         response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
       }
    
    if (null==oConn) return;
    
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.debug.DebugFile.writeln("<SCRIPT>\n" + oBuffer.toString() + "\n</SCRIPT>");
      
    out.write (oBuffer.toString());
    
    %>	 
  //-->
  </SCRIPT>

  <SCRIPT SRC="../javascript/scroller.js"></SCRIPT>
    
</HEAD>
  <FRAMESET NAME="orgtop" COLS="270,*" >
  <FRAMESET ROWS="30,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="scroll" FRAMEBORDER=0 MARGINWIDTH=4 MARGINHEIGHT=4 SRC="tree_scroll.htm" SCROLLING="no">
    <FRAME NAME="tree" FRAMEBORDER=0 MARGINWIDTH=8 SRC="tree_nodes.htm" SCROLLING="yes">
  </FRAMESET>
  <FRAME NAME="edittitle" SRC="../common/blank.htm">
  </FRAMESET>  
<NOFRAMES>
  <BODY>
    <P>This page use frames, but your web browser does not handle them</P>
  </BODY>
</NOFRAMES>
<HTML>
<%@ include file="../methods/page_epilog.jspf" %>
