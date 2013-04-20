<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.*,com.knowgate.workareas.WorkArea,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCategories" scope="application" class="com.knowgate.hipergate.Categories"/><%!

  static void addChilds (Categories oCatBean, JDCConnection oConn, String sLang, StringBuffer oBuffer,
                         String sParentCat, int iParentNode, String sChildCatId, String sQryStr) throws SQLException {
    DBSubset oChlds;
    int iChlds;
    int iChld;
    String sSubCat;
    String sJs = "";

	  /*
	  if (DebugFile.trace) {
	    if (sParentCat.startsWith("C_"))
	      DebugFile.write("<JSP:    addChilds("+DBCommand.queryStr(oConn, "SELECT nm_category FROM k_categories WHERE gu_category='"+sParentCat.substring(2)+"'")+","+String.valueOf(iParentNode)+","+DBCommand.queryStr(oConn, "SELECT nm_category FROM k_categories WHERE gu_category='"+sChildCatId+"'")+")\n");
	    else
	      DebugFile.write("<JSP:    addChilds("+sParentCat+","+String.valueOf(iParentNode)+","+DBCommand.queryStr(oConn, "SELECT nm_category FROM k_categories WHERE gu_category='"+sChildCatId+"'")+")\n");
    }
    */
    
    oChlds = oCatBean.getChildsNamed(oConn, sChildCatId, sLang, oCatBean.ORDER_BY_NONE);
    iChlds = oChlds.getRowCount();
    			  
    if (iChlds>0) {
      if (iParentNode>=0) {
        sSubCat = "C_" + sChildCatId;
        sJs = "    var " + sSubCat + " = new TreeMenu();\n";
        oBuffer.append (sJs);
			  // if (DebugFile.trace) DebugFile.write("<JSP:    var " + DBCommand.queryStr(oConn, "SELECT nm_category FROM k_categories WHERE gu_category='"+sChildCatId+"'") + " = new TreeMenu();\n");
      }
      else {
        sSubCat = "treeMenu";
      }

      if (iParentNode>=0) {
        if (sParentCat.equals("treeMenu")) {
          sJs = "    " + sParentCat + ".items["+ String.valueOf(iParentNode+1)+"].makeSubmenu(" + sSubCat + ");\n";
			    // if (DebugFile.trace) { try { DebugFile.write("<JSP:"+Gadgets.replace(sJs,sSubCat,DBCommand.queryStr(oConn, "SELECT nm_category FROM k_categories WHERE gu_category='"+sChildCatId+"'"))); } catch (org.apache.oro.text.regex.MalformedPatternException ignore) {} };
			  } else {
          sJs = "    " + sParentCat + ".items[" + String.valueOf(iParentNode) + "].makeSubmenu(" + sSubCat + ");\n";
			    // if (DebugFile.trace) { try { DebugFile.write("<JSP:"+Gadgets.replace(Gadgets.replace(sJs,sSubCat,DBCommand.queryStr(oConn, "SELECT nm_category FROM k_categories WHERE gu_category='"+sChildCatId+"'")),sParentCat,DBCommand.queryStr(oConn, "SELECT nm_category FROM k_categories WHERE gu_category='"+sParentCat.substring(2)+"'"))); } catch (org.apache.oro.text.regex.MalformedPatternException ignore) {} };
        }
        oBuffer.append (sJs);
      } // fi
      
      for (int c=0; c<iChlds; c++) {
        if (oChlds.isNull(3,c))
          sJs = "    " + sSubCat + ".addItem(new TreeMenuItem('" + oChlds.getString(2,c) + "', 'item_list_f.htm?" + sQryStr + "&gu_category=" + oChlds.getString(0,c) + "&tr_category=" + Gadgets.URLEncode(Gadgets.HTMLEncode(oChlds.getStringNull(2,c,oChlds.getString(1,c)))) + "', 'parent.selectNode(\"" + oChlds.getString(0,c) + "\",\"" + Gadgets.HTMLEncode(oChlds.getStringNull(2,c,oChlds.getString(1,c))) + "\")'));\n";
	      else
          sJs = "    " + sSubCat + ".addItem(new TreeMenuItem('" + oChlds.getString(2,c) + "', 'item_list_f.htm?" + sQryStr + "&gu_category=" + oChlds.getString(0,c) + "&tr_category=" + Gadgets.URLEncode(Gadgets.HTMLEncode(oChlds.getStringNull(2,c,oChlds.getString(1,c)))) + "','parent.selectNode(\"" + oChlds.getString(0,c) + "\",\"" + Gadgets.HTMLEncode(oChlds.getStringNull(2,c,oChlds.getString(1,c))) + "\")','" + oChlds.getString(3,c) + "'));\n";
		    oBuffer.append (sJs);
			  // if (DebugFile.trace) { try { DebugFile.write("<JSP:"+Gadgets.replace(sJs,sSubCat,DBCommand.queryStr(oConn, "SELECT nm_category FROM k_categories WHERE gu_category='"+sChildCatId+"'"))); } catch (org.apache.oro.text.regex.MalformedPatternException ignore) {} };
      } // next
      	      
      for (int c=0; c<iChlds; c++) {
        addChilds (oCatBean, oConn, sLang, oBuffer, sSubCat, c, oChlds.getString(0,c), sQryStr);
      }
      oChlds = null;
    }
  } // addChilds()
  
%><%
       JDCConnection oConn = null;
       Shop oShp = new Shop();

       String sDomainId = getCookie(request, "domainid", "default");
       String sUserId = getCookie(request, "userid", "default");
       String sLanguage = getNavigatorLanguage(request);
       String sSkin = getCookie(request, "skin", "default");

       String sQryStr = null;
       
       oConn = GlobalDBBind.getConnection("shop_tree_f");
       
       StringBuffer oBuffer = new StringBuffer();
       
       try {
         oShp.load(oConn, new Object[]{request.getParameter("gu_shop")});

         sQryStr = "?id_domain=" + sDomainId + "&id_user=" + sUserId + "&id_language=" + sLanguage + "&gu_shop=" + oShp.getString(DB.gu_shop) + "&top_parent_cat=" + oShp.getString(DB.gu_root_cat) + "&gu_bundles_cat=" + oShp.getStringNull(DB.gu_bundles_cat,"") + "&void";

	       addChilds(GlobalCategories, oConn, sLanguage, oBuffer, "treeMenu", -1, oShp.getString(DB.gu_root_cat), sQryStr);
	   	 
	       oConn.close("shop_tree_f");	 
	       oConn = null;
       }
       catch (SQLException e) {
         if (null!=oConn)
           if (!oConn.isClosed()) {
             oConn.close("shop_tree_f");
             oConn = null;
           }        
         response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
       }
       
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Category Tree</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript">
    <!--
    // User-defined tree menu data.

    var treeMenuName       = "ShopCategories";  // Make this unique for each tree menu.
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
    var treeMenuRoot       = "CATEGORIES"; // Text for the menu root.
    var treeMenuFolders    = 1;                 // Sets display of '+' and '-' icons.
    var treeMenuAltText    = false;             // Use menu item text for icon image ALT text.

    
    function selectNode(guid,name) {
      window.frames[2].document.forms[0].code.value = guid;
      window.frames[2].document.forms[0].ctrl.value = name;
      parent.parent.msgsadmin.location = "item_list_f.htm?gu_shop=" + getURLParam("gu_shop") + "&gu_category=" + guid + "&tr_category=" + escape(name) + "&top_parent_cat=<%=oShp.getString(DB.gu_root_cat)%>&gu_bundles_cat=<%=oShp.getStringNull(DB.gu_bundles_cat,"")%>";
      return false;
    }

  //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="shopmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    var treeMenu = new TreeMenu();   // This is the main menu.  

<%  if (!oShp.isNull(DB.gu_bundles_cat))
      out.write ("    treeMenu.addItem(new TreeMenuItem('Packages', 'item_list_f.htm?" + sQryStr + "&gu_category=" + oShp.getString(DB.gu_bundles_cat) + "&tr_category=" + Gadgets.URLEncode(Gadgets.HTMLEncode("Packages")) + "', 'parent.selectNode(\"" + oShp.getString(DB.gu_bundles_cat) + "\",\"Packages\")','package16.gif'));\n");	

    out.write(oBuffer.toString());
    %>
  //-->
  </SCRIPT>
</HEAD>
<FRAMESET ROWS="70,*,0" BORDER=0 FRAMEBORDER="0">
  <FRAME NAME="scroll" FRAMEBORDER=0 MARGINWIDTH=8 MARGINHEIGHT=0 SRC="tree_scroll.htm<% out.write(sQryStr); %>" SCROLLING="no">
  <FRAME NAME="tree" FRAMEBORDER=0 MARGINWIDTH=8 SRC="tree_nodes.htm" SCROLLING="yes">
  <FRAME NAME="cmds" FRAMEBORDER=0 MARGINWIDTH=8 SRC="tree_cmds.htm<% out.write(sQryStr); %>" SCROLLING="no">
</FRAMESET>
<NOFRAMES>
  <BODY>
    <P>This page use frames, but your web browser does not handle them</P>
  </BODY>
</NOFRAMES>
<HTML>
