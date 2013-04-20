<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.sql.ResultSet,java.sql.PreparedStatement,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
  
  String sSkin = getCookie(request, "skin", "xp");
  String sUserId = getCookie(request, "userid", "");   
  String sDomainId = getCookie(request, "domainid", "");
  String sDomainNm = getCookie(request, "domainnm", "");
  String sLanguage = getNavigatorLanguage(request);
  String sParentId;
  String sError = null;
  String sDomainShared;
  
  if (sUserId.length()==0 || sDomainId.length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=[~Domain or User Cookies not set~]&resume=_back"));
  }
  boolean bIsGuest = isDomainGuest (GlobalDBBind, request, response);

  String sUri = null; 
  if (sDomainId.equals("1024")) { sParentId = "";
	    sUri = "pickchilds.jsp?Skin="+sSkin+"&Lang="+sLanguage+"&Uid="+sUserId;
  } else if (sDomainId.equals("1025")) { sParentId = "";
	    sUri = "pickchilds.jsp?Skin="+sSkin+"&Lang="+sLanguage+"&Parent=ecd80abbb4b24668aa75d45a58c830a6&Label=root&Uid="+sUserId;
  } else {	
	  JDCConnection oConn = null;
	  PreparedStatement oStmt;
	  ResultSet oRSet;
	  String sSQL;
	
	  try {

	    oConn = GlobalDBBind.getConnection("catdipu3x");		
	    sSQL = "SELECT " +  DB.gu_category + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?";
	    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");
	    oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	    oStmt.setString(1,sUserId);	  	  
	    oRSet = oStmt.executeQuery();
	    if (oRSet.next())
	      sParentId = oRSet.getString(1);
	    else
	      sParentId = "000000000000000000000000000000000";
	    oRSet.close();
	    oRSet = null;
	    oStmt.close();
	    oStmt = null;
            
	    oConn.close("catdipu3x");
	    oConn = null;
	  }
  	catch (NumberFormatException e) {
    	  sError = "NumberFormatException " + sDomainId;
	  sParentId = "000000000000000000000000000000000";
  	}
	  catch (SQLException sqle) {
    	  if (oConn!=null)
      	    if (!oConn.isClosed()) oConn.close("catdipu3x");
    	  oConn = null;
    	  sError = "SQLException " + sqle.getMessage();
	  sParentId = "000000000000000000000000000000000";
	  }
	  sUri = "pickchilds.jsp?Skin="+sSkin+"&Lang="+sLanguage+"&Parent="+sParentId+"&Label=root&Uid="+sUserId;
	}
%>
  <!-- +---------------------------------------------+ -->
  <!-- | Page for showing a JavaScript TreeMenu      | -->
  <!-- | © KnowGate 2009                             | -->
  <!-- +---------------------------------------------+ -->  

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/defined.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>

  <SCRIPT TYPE="text/javascript">
    <!--
    // User-defined tree menu data.

    var treeMenuName       = "VDiskCategories";  // Make this unique for each tree menu.
    var treeMenuDays       = 1;                 // Number of days to keep the cookie.
    var treeMenuFrame      = window.parent.response;    // Menu frame window.
    var treeMenuImgDir     = "../skins/<%=sSkin%>/nav/" // Path to graphics directory.
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

    var currentCategoryGuid = "000000000000000000000000000000000";

    function selectNode(guid,name) {
      currentCategoryGuid = guid;
    }

		function getChildsCollection(uri) {
		  var doc = httpRequestXML(uri);
		  var has = doc.getElementsByTagName("has");
		  return has[0].getElementsByTagName("b");
	  }

		function loadChilds(mnu,bs) {
			for (var n=0; n<bs.length; n++) {
			  var b = bs[n];
				var id = getElementText(b.getElementsByTagName("target")[0],"s");
				var lt = getElementText(b, "lt");
				var sb = new TreeMenuItem(lt,
									                "catprods.jsp?id_category=" + id + "&tr_category=" + escape(lt),
				                          "window.parent.frames[1].selectNode(\""+id+"\",\""+lt+"\")", getElementText(b.getElementsByTagName("uri")[0],"s"));
			  mnu.addItem(sb);

			  var ch = getChildsCollection("pickchilds.jsp?Skin=<%=sSkin%>&Lang=<%=sLanguage%>&Parent="+id+"&Label="+escape(lt)+"&Uid=<%=sUserId%>");
			  if (ch.length>0) {
			  	var sm = new TreeMenu();
			    mnu.items[n].makeSubmenu(sm);
			    loadChilds(sm, ch);			    
			  }
			} // next
		}

    // ----------------------------------------------------------------
        
    function createCategory() {
      var diputree = window.document.diputree;
                    
      if (currentCategoryGuid=="000000000000000000000000000000000") {
	      alert ("[~Debe seleccionar primero una categoria padre para poder crear otra nueva categoria.~]");        
      } else {
        if (currentCategoryGuid=="<%=sParentId%>") {
          alert ("It is not allowed to create root categories");
      	  return false;
      	}

          self.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_parent_cat=" + currentCategoryGuid, "newcategory", "directories=no,toolbar=no,menubar=no,width=480,height=420");
      	
      	/*
      	if (id_parent_category.length==0) {
      	} else {
          if (id_category.charCodeAt(0)==35)
            self.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_parent_cat=" + id_category.substr(1), "newcategory", "directories=no,toolbar=no,menubar=no,width=480,height=420");
          else
            self.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_parent_cat=" + id_category, "newcategory", "directories=no,toolbar=no,menubar=no,width=480,height=420");
        }
        */
      }
    } // createCategory()

    // ----------------------------------------------------------------

    function modifyCategory() {
      var diputree = window.document.diputree;
            	
      if (currentCategoryGuid=="000000000000000000000000000000000") {
        alert ("[~Debe seleccionar una categoría en el árbol antes de poder editarla~]");
      } else {
        self.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_category=" + currentCategoryGuid + "&id_parent_cat=" + currentCategoryGuid, "", "directories=no,toolbar=no,menubar=no,width=480,height=460");
      }
    } // modifyCategory()

    // ----------------------------------------------------------------

    function deleteCategory() {
      var diputree = window.document.diputree;

      if (currentCategoryGuid=="000000000000000000000000000000000") {
        alert ("[~Para eliminar una Categoria debe seleccionarla primero en el arbol de navegacion~]");
      } else {                   
        if (currentCategoryGuid=="<%=sParentId%>") {
	        alert ("[~No esta permitido eliminar categorias raiz~]");	  
        } else if (window.confirm("[~Esta seguro de que desea eliminar la categoria seleccionada?~]")) {
          self.open ("catedit_del.jsp?checkeditems=" + currentCategoryGuid, "", "directories=no,toolbar=no,menubar=no,width=400,height=300");
        }
      }
    } // deleteCategory()
      
    // ----------------------------------------------------------------
    
    function showFiles () {
      var frm = document.forms[0];
      var cad = window.parent.parent.catadmin;
      
      if (frm.catname.value.length>0)     
        cad.location = "catprods.jsp?id_category=" + id_category + "&tr_category=" + escape(frm.catname.value);
      } // showFiles()

    // --------------------------------------------------------
    
    function searchFile () {
      var cad = window.parent.parent.catadmin;
      var sought = window.prompt("Enter the name of file, link of category to be found","");
      
      if (null!=sought)
        if (sought.length>0)
          cad.location = "catfind.jsp?tx_sought=" + escape(sought);
    }

  //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/catdipu3x.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  	<!--
      var treeMenu = new TreeMenu();
    //-->
  </SCRIPT>
  
</HEAD>
<BODY ID="pagebody"  LEFTMARGIN="4" RIGHTMARGIN="0" TOPMARGIN="0" MARGINWIDTH="4" MARGINHEIGHT="0" SCROLL="no" onload="loadChilds(treeMenu,getChildsCollection('<%=sUri%>'));treeMenuDisplay();">
  <TABLE CELLSPACING="2" CELLPADDING="0" BORDER="0">
    <TR VALIGN="middle">
      <TD ALIGN="center" VALIGN="middle"><IMG SRC="../images/images/newfolder16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Nueva Categor&iacute;a~]"><BR><A HREF="#" onclick="createCategory()" CLASS="linkplain">New</A></TD>
      <TD WIDTH="8"></TD>
      <TD ALIGN="center" VALIGN="middle">
        <IMG SRC="../images/images/deletefolder.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Category"><BR>
<% if (bIsGuest) { %>
        <A HREF="#" onclick="alert('Your priviledge level as guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
        <A HREF="#" onclick="deleteCategory()" CLASS="linkplain">Delete</A>
<% } %>
      </TD>
      <TD WIDTH="8"></TD>
      <TD ALIGN="center" VALIGN="middle"><IMG SRC="../images/images/folderoptions.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Edit Category"><BR><A HREF="#" onclick="modifyCategory()" CLASS="linkplain">Edit</A></TD>
      <TD WIDTH="8"></TD>
      <TD ALIGN="center" VALIGN="middle"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search Category"><BR><A HREF="#" onclick="searchFile()" CLASS="linkplain">Search</A></TD>
    </TR>
  </TABLE>  
</BODY>
</HTML>
