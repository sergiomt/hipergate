<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Category,com.knowgate.hipergate.Categories" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><jsp:useBean id="GlobalCategories" scope="application" class="com.knowgate.hipergate.Categories"/><%!

/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.

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

  static void addChilds (Categories oCatBean, JDCConnection oConn, String sLang, StringBuffer oBuffer,
                         String sParentCat, int iParentNode, String sChildCatId) throws SQLException {
    DBSubset oChlds;
    int iChlds;
    int iChld;
    String sSubCat;
    String sJs = "";
    
    oChlds = oCatBean.getChildsNamed(oConn, sChildCatId, sLang, oCatBean.ORDER_BY_NONE);
    iChlds = oChlds.getRowCount();
    			  
    if (iChlds>0) {
      if (iParentNode>=0) {
        sSubCat = "C_" + sChildCatId;
        sJs = "    var " + sSubCat + " = new TreeMenu();\n";
        oBuffer.append (sJs);
      }
      else {
        sSubCat = "treeMenu";
      }

      if (iParentNode>=0) {
        if (sParentCat.equals("treeMenu")) {
          sJs = "    " + sParentCat + ".items["+ String.valueOf(iParentNode)+"].makeSubmenu(" + sSubCat + ");\n";
			  } else {
          sJs = "    " + sParentCat + ".items[" + String.valueOf(iParentNode) + "].makeSubmenu(" + sSubCat + ");\n";
        }
        oBuffer.append (sJs);
      } // fi
      
      for (int c=0; c<iChlds; c++) {
        if (oChlds.isNull(3,c))
          sJs = "    " + sSubCat + ".addItem(new TreeMenuItem('" + oChlds.getString(2,c) + "', '', 'selectNode(\"" + oChlds.getString(0,c) + "\",\"" + Gadgets.HTMLEncode(oChlds.getStringNull(2,c,oChlds.getString(1,c))) + "\")'));\n";
	      else
          sJs = "    " + sSubCat + ".addItem(new TreeMenuItem('" + oChlds.getString(2,c) + "', '', 'selectNode(\"" + oChlds.getString(0,c) + "\",\"" + Gadgets.HTMLEncode(oChlds.getStringNull(2,c,oChlds.getString(1,c))) + "\")','" + oChlds.getString(3,c) + "'));\n";
		    oBuffer.append (sJs);
      } // next
      	      
      for (int c=0; c<iChlds; c++) {
        addChilds (oCatBean, oConn, sLang, oBuffer, sSubCat, c, oChlds.getString(0,c));
      }
      oChlds = null;
    }
  } // addChilds()
  
%><%
 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);

  String sSkin = getCookie(request, "skin", "default");

  String id_user = getCookie(request,"userid","");
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String gu_list = request.getParameter("gu_list");
  String gu_pageset = request.getParameter("gu_pageset");

  DBSubset oSelec = new DBSubset(DB.k_x_adhoc_mailing_list+" x,"+DB.k_lists+" l",
  															 "l."+DB.gu_list+",l."+DB.tx_subject+",l."+DB.de_list,
  															 "x."+DB.gu_mailing+"=? AND x."+DB.gu_list+"=l."+DB.gu_list, 20);
  int iSelec = 0;
  JDCConnection oConn = null;  
  StringBuffer oBuffer = new StringBuffer();

  try {
    oConn = GlobalDBBind.getConnection("listlisting");

    iSelec = oSelec.load (oConn, new Object[]{gu_pageset});

    String sTopParent = Category.getIdFromName(oConn, n_domain+"_apps_sales_lists_"+gu_workarea);
    if (null==sTopParent) {
			oConn.setAutoCommit(false);
		  String sGuSalesCategory = Category.getIdFromName(oConn, n_domain+"_apps_sales");
    	Category oRootCat = new Category();
    	oRootCat.put(DB.gu_owner, DBCommand.queryStr(oConn, "SELECT "+DB.gu_owner+" FROM "+DB.k_domains+" WHERE "+DB.id_domain+"="+id_domain));
    	oRootCat.put(DB.nm_category, n_domain+"_apps_sales_lists_"+gu_workarea);
      oRootCat.put(DB.bo_active, (short) 1);
      oRootCat.put(DB.id_doc_status, (short) 1);
      oRootCat.put(DB.len_size, 0);
      oRootCat.store(oConn);
      sTopParent = oRootCat.getString(DB.gu_category);
      if (sGuSalesCategory!=null) {
        DBCommand.executeUpdate(oConn, "INSERT INTO "+DB.k_cat_tree+" ("+DB.gu_parent_cat+","+DB.gu_child_cat+") VALUES ('"+sGuSalesCategory+"','"+sTopParent+"')");
      }
      oConn.commit();
    } // fi

	  addChilds(GlobalCategories, oConn, sLanguage, oBuffer, "treeMenu", -1, sTopParent);

    oConn.close("listlisting"); 
  }
  catch (SQLException e) {  
    if (null!=oConn) oConn.close("listlisting");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    return;
  }
  oConn = null;  

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
    
    var jsList;
    var jsSelectedLists = new Array();
<%
    for (int s=0; s<iSelec; s++) {
      out.write("    jsList = new Object();\n");
      out.write("    jsList = new Array(\""+oSelec.getString(0,s)+"\",\""+oSelec.getStringNull(1,s,"").replace('"',' ').replace('\n',' ')+"\",\""+oSelec.getStringNull(2,s,"").replace('"',' ').replace('\n',' ')+"\");\n");
      out.write("    jsSelectedLists.push(jsList);\n");
    }
%>

    // User-defined tree menu data.

    var treeMenuName       = "ListsTree";       // Make this unique for each tree menu.
    var treeMenuDays       = 1;                 // Number of days to keep the cookie.
    var treeMenuFrame      = "treeMenuLayer";   // Name of the menu layer.
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
      document.getElementById("listingLayer").innerHTML = "";
    	var html= "";
    	var lists = httpRequestText("lists_x_category.jsp?gu_category="+guid);
      if (lists.indexOf("¨")>0) {
        lists = lists.split("`");
        for (var l=0; l<lists.length; l++) {
          list = lists[l].split("¨");
          html += "<DIV STYLE=\"text-align:left;clear:right\" ID=\"div_"+list[0]+"\"><INPUT TYPE=\"checkbox\" ID=\"chk_"+list[0]+"\" NAME=\"chk_"+list[0]+"\" VALUE=\""+list[0]+"\""+(isSelected(list[0]) ? " CHECKED" : "")+" onclick=\"if (this.checked) { if (listIndex('"+list[0]+"')==-1) jsSelectedLists.push(new Array('"+list[0]+"','"+list[1]+"','"+list[2]+"')); paintSelectedLists(); } else { if (listIndex('"+list[0]+"')!=-1) jsSelectedLists.splice(listIndex('"+list[0]+"'),1); paintSelectedLists(); } \">&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"modifyList('"+list[0]+"',escape('"+list[1]+"'))\" TITLE=\"Edit List\">"+list[1]+"</A>"+(list[1]==list[2] ? "" : "<FONT CLASS=\"textplain\">: " + list[2] + "</FONT>")+"</DIV>";
        }
        document.getElementById("listingLayer").innerHTML = html;
      } else {
        document.getElementById("listingLayer").innerHTML = "<FONT CLASS=\"textplain\">There is no list at category "+name+"</FONT>";      
      }
    }

  //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="listtreemenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        function programJob() {
          var frm = document.forms[0];
          var ele = jsSelectedLists.length;
          var chk = 0;
	        var par;
	        var lst = "";

          if (0==ele) {
            alert ("Must select a List to witch send documents");
            return false;
          }
	            
          for (var idx=0; idx<ele; idx++) {
	          lst += (lst.length==0 ? "" : ";") + jsSelectedLists[idx][0];
          } // next
          
          
          par = "gu_pageset:" + getURLParam("gu_pageset") + ",gu_list:" + lst;
          
          document.location = "../jobs/job_edit.jsp?gu_pageset=" + getURLParam("gu_pageset") + "&id_command=" + getURLParam("id_command") + "&parameters=" + par;

        } // programJob

        // ----------------------------------------------------
        	
      	function deselectAll() {
          var ele = jsSelectedLists.length;
					for (var l=0; l<ele; l++) {
					  if (document.getElementById("chk_"+jsSelectedLists[l][0]))
					    document.getElementById("chk_"+jsSelectedLists[l][0]).checked=false;
					}
					jsSelectedLists = new Array();
				  document.getElementById("selectedLists").innerHTML = "";
        } // deselectAll

        // ----------------------------------------------------
        	
      	function createList() {
      		  	  
      	  self.open ("../crm/list_wizard_01.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" , "listwizard", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-320)/2 + ",left=" + (screen.width-340)/2 + ",width=340,height=320");	  
      	} // createList()
        
        //---------------------------------------------------------------------
        
        function modifyList(id,nm) {
	  
	        self.open ("../crm/list_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_list=" + id + "&n_list=" + nm, "editlist", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-420)/2 + ",left=" + (screen.width-600)/2 + ",width=600,height=420");	      
	      }

        //---------------------------------------------------------------------

				function isSelected(guid) {
				  for (var l=0; l<jsSelectedLists.length; l++) {
				    if (jsSelectedLists[l][0]==guid) return true;
				  }
				  return false;
				}

        //---------------------------------------------------------------------

				function listIndex(guid) {
				  for (var l=0; l<jsSelectedLists.length; l++) {
				    if (jsSelectedLists[l][0]==guid) return l;
				  }
				  return -1;
				}

        //---------------------------------------------------------------------

				function paintSelectedLists() {
				  var html = "";
				  var llen = jsSelectedLists.length;
				  for (var l=0; l<llen; l++) {
				    html += "<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"modifyList('"+jsSelectedLists[l][0]+"',escape('"+jsSelectedLists[l][1]+"'))\" TITLE=\"Edit List\">"+jsSelectedLists[l][1]+"</A><A HREF=\"#\" onclick=\"if (document.getElementById('chk_"+jsSelectedLists[l][0]+"')) document.getElementById('chk_"+jsSelectedLists[l][0]+"').checked=false; jsSelectedLists.splice("+String(l)+",1); paintSelectedLists();\" TITLE=\"Delete list\"><IMG SRC=\"../images/images/webbuilder/x_11x11.gif\" WIDTH=\"13\" HEIGHT=\"13\" ALT=\"X\" BORDER=\"0\" onmouseover=\"this.src='../images/images/webbuilder/x2_11x11.gif'\" onmouseout=\"this.src='../images/images/webbuilder/x_11x11.gif'\"></A>";
				    if (l<llen-1) html += ",&nbsp;";
				  } // next
				  document.getElementById("selectedLists").innerHTML = html;
				}
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Schedule Task (1/2)</TITLE>
</HEAD>
<BODY onload="paintSelectedLists()">
  <TABLE CELLSPACING="0" CELLPADDING="0" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Schedule Task: Select Distribution List</FONT></TD><TD CLASS="striptitle" align="right"><FONT CLASS="title1">(1 of 2)</FONT></TD></TR>
  </TABLE>  
  <BR>
  <FONT CLASS="textplain">Select a Distribution List as a target for e-mailing.</FONT>
  <FORM>  
      <TABLE WIDTH="100%" CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD WIDTH="18px"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New List"></TD>
          <TD ALIGN="left" VALIGN="middle"><A HREF="#" onclick="createList();" CLASS="linkplain" TITLE="New List">New Distribution List</A>
          &nbsp;&nbsp;&nbsp;&nbsp;<A HREF="#" CLASS="linkplain" onclick="deselectAll()">Deshacer Selecci&oacute;n</A>
          </TD>
        </TR>
        <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
        	<TD COLSPAN="2" CLASS="textplain">Seledted lists
        		<DIV ID="selectedLists" STYLE="text-align:left"></DIV>
          </TD>
        </TR>
        <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
			<DIV ID="treeMenuLayer" STYLE="float:left;overflow:auto;width:240px"></DIV>
		  <DIV ID="listingLayer" STYLE="float:left;clear:right;text-align:left;width:350px"></DIV>
      <DIV ID="button" STYLE="clear:left;text-align:center">
        <BR><TABLE WIDTH="100%"><TR><TD BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR></TABLE><BR>
        <INPUT TYPE="button" CLASS="closebutton" ACCESSKEY="c" TITLE="ALT+c" VALUE="Cancel" onClick="if (window.opener) window.close(); else window.history.back()">
        <INPUT TYPE="button" CLASS="pushbutton" ACCESSKEY="n" TITLE="ALT+n" VALUE="Next >>" onClick="programJob()">
      </DIV>
  </FORM>
</BODY>
<SCRIPT TYPE="text/javascript">
  <!--
    var treeMenu = new TreeMenu();  
<%  out.write(oBuffer.toString()); %>
    treeMenuDisplay();
  //-->
</SCRIPT>
</HTML>
