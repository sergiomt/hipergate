<%@ page import="java.util.LinkedList,java.util.HashMap,java.util.ListIterator,java.net.URLDecoder,java.lang.StringBuffer,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalCategories" scope="application" class="com.knowgate.hipergate.Categories"/><%
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
  
  final int Hipermail=21;
  
  String sSkin = getCookie(request, "skin", "xp");
  int iDomain = Integer.parseInt(getCookie(request,"domainid",""));

  String sLanguage = getNavigatorLanguage(request);
  int iACLMask = 0;
  int iUsrMask = 0;
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
    
  String id_category = nullif(request.getParameter("id_category"));
  String tr_category = nullif(request.getParameter("tr_category"));
  String id_user = getCookie (request, "userid", null);
  String nm_domain = getCookie(request, "domainnm", "");

  if (id_category.length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/blank.htm"));
    return;
  }  
  
  int iProdCount = 0;
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "10"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;
  
  String sCats = null;
  String sParentId = null;
  String sParentTr = null;
  String sLbl = null;
  String sSharedLbl = null;
  LinkedList oCats;
  ListIterator oIter;
  Category oCatg = null;
  Category oShared = null;
  DBSubset oProd = null;
  
  DBSubset oChld = new DBSubset (DB.v_cat_tree_labels,
  				 DB.gu_category + "," + DB.tr_category + "," + DB.dt_modified,
  				 DB.nm_category+" NOT LIKE '"+nm_domain+"_%_pwds' AND "+
  				 DB.gu_parent_cat + "=? AND " + DB.id_language + "=? ORDER BY 2", 10);
  int iChld = 0;
  boolean bLoaded;
  boolean bUserRoot = false;
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;
  
  boolean bIsGuest = true;
  HashMap oIcons = null;
  HashMap oUsers = null;

  try {
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("catprods");
    
    ACLUser oUsr = new ACLUser(oConn, id_user);

    // ***********************************************
    // Load icons for known mime extensions into cache

    oIcons = (HashMap) GlobalCacheClient.get("k_lu_prod_types");

    if (oIcons==null) {
      oIcons = new HashMap(200);
      
      DBSubset oProdTypes = new DBSubset (DB.k_lu_prod_types, DB.id_prod_type + "," + DB.nm_icon, DB.nm_icon + " IS NOT NULL", 200);
      oProdTypes.load(oConn);
      int iTypeCount = oProdTypes.getRowCount();
      
      for (int t=0; t<iTypeCount; t++)
        oIcons.put (oProdTypes.getString(0,t), oProdTypes.getString(1,t));
      
      
      GlobalCacheClient.put("k_lu_prod_types", oIcons);
    } // fi (oIcons)
    
    // ***********************************************

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
      oProd = new DBSubset (DB.k_products + " p, " + DB.k_prod_locats + " l, " + DB.k_x_cat_objs + " x",
  			    "p." + DB.gu_product +",p." + DB.nm_product + ",p." + DB.de_product + ",p." + DB.dt_modified +
  			    ",CONCAT(l." + DB.xprotocol + ",l." + DB.xhost + ",COALESCE(l." + DB.xpath + ",''),COALESCE(l." + DB.xanchor + ",'')), l." +
  			    DB.id_cont_type + "," + DB.len_file + ",l." + DB.gu_location + ",l." + DB.id_prod_type + ",l." + DB.xfile + ",p." + DB.gu_blockedby,
  			    "p." + DB.gu_product + "=x." + DB.gu_object + " AND l." + DB.gu_product + "=x." + DB.gu_object + " AND x." + DB.gu_category + " = '" + id_category + "' AND x." + DB.id_class + "=15 AND (l." + DB.status + "<>3 OR l." + DB.status + " IS NULL) " + (iOrderBy==0 ? "" : " ORDER BY " + sOrderBy + (iOrderBy==4 ? " DESC" : "")), 100);
    else
      oProd = new DBSubset (DB.k_products + " p, " + DB.k_prod_locats + " l, " + DB.k_x_cat_objs + " x",
  			    "p." + DB.gu_product +",p." + DB.nm_product + ",p." + DB.de_product + ",p." + DB.dt_modified +
  			    ",l." + DB.xprotocol + DBBind.Functions.CONCAT + "l." + DB.xhost + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(l." + DB.xpath + ",'')" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(l." + DB.xanchor + ",''), l." +
  			    DB.id_cont_type + "," + DB.len_file + ",l." + DB.gu_location + ",l." + DB.id_prod_type + ",l." + DB.xfile + ",p." + DB.gu_blockedby,
  			    "p." + DB.gu_product + "=x." + DB.gu_object + " AND l." + DB.gu_product + "=x." + DB.gu_object + " AND x." + DB.gu_category + " = '" + id_category + "' AND x." + DB.id_class + "=15 AND (l." + DB.status + "<>3 OR l." + DB.status + " IS NULL) " + (iOrderBy==0 ? "" : " ORDER BY " + sOrderBy + (iOrderBy==4 ? " DESC" : "")), 100);

    oCatg = new Category();
    bLoaded = oCatg.load(oConn, new Object[]{id_category});
    
    if (bLoaded) {
      
      if (0==tr_category.length())
        tr_category = oCatg.getLabel(oConn, sLanguage);    
      
      if (null==tr_category) tr_category = oCatg.getString(DB.nm_category);
      
      iACLMask = oCatg.getUserPermissions(oConn,id_user);
      
      if ((iACLMask&ACL.PERMISSION_LIST)!=0) {
        oCats = oCatg.browse(oConn, Category.BROWSE_UP, Category.BROWSE_TOPDOWN);

        sCats = "";
        oIter = oCats.listIterator();    
        bUserRoot = false;
        while (oIter.hasNext()) {
          oCatg = (Category) oIter.next();
          if (!bUserRoot)
            bUserRoot = oCatg.getStringNull(DB.gu_owner,"").equals(id_user);
      
          if (bUserRoot) {
            sLbl = oCatg.getLabel(oConn, sLanguage);
            iUsrMask = oCatg.getUserPermissions(oConn,id_user);
            if (((iUsrMask&ACL.PERMISSION_LIST)!=0) || ((iUsrMask&ACL.PERMISSION_READ)!=0) || ((iUsrMask&ACL.PERMISSION_MODIFY)!=0)) {
              sCats += "<FONT CLASS=\"linknodecor\">&nbsp;/&nbsp;</FONT>" + "<A CLASS=\"linkplain\" HREF=\"catprods.jsp?id_category=" + oCatg.getString(DB.gu_category) + "&tr_category=" + Gadgets.URLEncode(sLbl) + "\">" + Gadgets.HTMLEncode(sLbl) + "</A>";
              sParentId = oCatg.getString(DB.gu_category);
              sParentTr = sLbl;              
            }
            else {
              sCats += "<FONT CLASS=\"linknodecor\">&nbsp;/&nbsp;</FONT>" + "<FONT CLASS=\"textplain\">...</FONT>";
            }
          } // fi (bUserRoot)
        } // wend
        oIter = null;
        oCats = null;
    
        iProdCount = oProd.load (oConn);

        iChld = oChld.load(oConn, new Object[] {id_category, sLanguage});
        
        if (oUsr.getStringNull(DB.gu_category,"").equals(id_category)) {
          oShared = GlobalCategories.getSharedFilesCategoryForDomain(oConn, iDomain);
          if (sCats.length()==0 || (oShared.getUserPermissions(oConn,id_user)&ACL.PERMISSION_LIST)==0) oShared = null;
          if (null!=oShared) sSharedLbl = oShared.getLabel(oConn, sLanguage);
        }

				int nUsers = 0;
				for (int p=0; p<iProdCount; p++) {
				  if (!oProd.isNull(10,p))
				    nUsers++;
				} // next
				if (nUsers>0) {
          oUsers = new HashMap(nUsers*3);
				  oStmt = oConn.prepareStatement("SELECT "+DB.tx_nickname+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"=?");
				  for (int p=0; p<iProdCount; p++) {
				    if (!oProd.isNull(10,p)) {
				      oStmt.setString(1, oProd.getString(10,p));
				      oRSet = oStmt.executeQuery();
				      if (oRSet.next()) {
				        String sTxNickName = oRSet.getString(1);
				        if (!oUsers.containsKey(oProd.getString(10,p))) {
				          oUsers.put(oProd.getString(10,p), sTxNickName);
				        }
				      } // fi	(exists nickname)
				      oRSet.close();
				    } // fi	(blocked by is not null)
				  } // next
				  oStmt.close();
				} // fi (nUsers)
				
        oConn.close("catprods"); 
      }
      else
      {
        oConn.close("catprods");
        oConn = null;
        response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Access Denied&desc=You do not have sufficient permissions for listing contents of this category&resume=_back"));
      }
    }
    else {
      oConn.close("catprods");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Invalid Argument&desc=Category not found&resume=_back"));           
    }
  }
  catch (SQLException e) {
    if (null!=oConn)
      if (!oConn.isClosed())
        oConn.close("catprods"); 
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error connecting to database&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;  
  oConn = null;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

	sendUsageStats(request, "catprods"); 

%><!-- +---------------------------------------+ -->
  <!-- | Listado de productos de una categoria | -->
  <!-- | © KnowGate 2001-2007                  | -->
  <!-- +---------------------------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
  <HEAD>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" >
      dynapi.library.setPath('../javascript/dynapi3/');
      dynapi.library.include('dynapi.api.DynLayer');

      var menuLayer;

      dynapi.onLoad(init);
    function init() {
 
        menuLayer = new DynLayer();
        menuLayer.setWidth(160);
        menuLayer.setHTML(rightMenuHTML);      
      }
    </SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" DEFER="defer">
      <!--
        var id_category = "<%=id_category%>";
        var tr_category = escape("<%=tr_category%>");
        var acl_mask = <% out.write(String.valueOf(iACLMask)); %>;
	
	      var jsItemTp;
	      var jsItemId;
	      var jsItemTr;
	      var jsItemLc;
	      var jsBlockedBy;
	
        <%
          
          out.write("var jsInstances = new Array(");
            for (int i=0; i<iProdCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oProd.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

	// ----------------------------------------------------
	
        function createLink() {
          <% if (((iACLMask&ACL.PERMISSION_ADD)==0) || bIsGuest) { %>
	           alert ("You are not authorized to add links to this category");
          <% } else { %>
            window.open("linkedit.jsp?id_category=" + id_category + "&tr_category=" + tr_category, "editlink", "directories=no,toolbar=no,menubar=no,width=480,height=420");
          <% } %>
        }

	// ----------------------------------------------------

        function createDocument() {
          <% if (((iACLMask&ACL.PERMISSION_ADD)==0) || bIsGuest) { %>
	           alert ("You are not authorized to add documents to this category");
          <% } else { %>
            window.open("docedit.jsp?id_category=" + id_category + "&tr_category=" + tr_category, "editdocument", "directories=no,toolbar=no,menubar=no,width=480,height=420");          
          <% } %>
        }

	// ----------------------------------------------------

        function modifyLink(idProduct) {
          <% if (((iACLMask&ACL.PERMISSION_MODIFY)==0) || bIsGuest) { %>
	           alert ("You are not authorized for modifying links from this category");
          <% } else { %>
            window.open("linkedit.jsp?id_category=" + id_category + "&tr_category=" + tr_category + "&id_product=" + idProduct, idProduct, "directories=no,toolbar=no,menubar=no,width=480,height=380");
          <% } %>
        }          

	// ----------------------------------------------------

        function modifyDoc(idProduct,idLocation) {
          <% if (((iACLMask&ACL.PERMISSION_MODIFY)==0) || bIsGuest) { %>
	           alert ("You are not authorized for modifying documents from this category");
          <% } else { %>
            window.open("docedit.jsp?id_category=" + id_category + "&tr_category=" + tr_category + "&id_product=" + idProduct + "&id_location=" + idLocation, idProduct, "directories=no,toolbar=no,menubar=no,width=480,height=380");
          <% } %>
        }          

	// ----------------------------------------------------

        function updateList() {
          var dipuwnd = window.parent.frames[1];

	        if (dipuwnd.id_category.length==0)
	          alert ("Must first select a category");
	  		  else	                                          
            window.document.location.href = "catprods.jsp?id_category=" + dipuwnd.id_category + "&tr_category=" + escape(dipuwnd.tr_category);
        }

	// ----------------------------------------------------
        
        function deleteProducts() {
          <% if (((iACLMask&ACL.PERMISSION_DELETE)==0) || bIsGuest) { %>
	           alert ("You are not authorized to delete elements from this category");
          <% } else { %>
            if (confirm("Are you sure you want to delete selected elements?"))
              window.document.forms[0].submit();
          <% } %>
        }

        // ----------------------------------------------------

	      function sortBy(fld) {	  
	        document.location.href = "catprods.jsp?id_category=<%=id_category%>&tr_category=<%=Gadgets.URLEncode(tr_category)%>&orderby=" + String(fld);
	      }			

        // ----------------------------------------------------

        function selectAll() {
          // [~//Seleccionar/Deseleccionar todas los archivos~]
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsInstances.length; c++)                        
            eval ("frm.chkbox" + String(c) + ".click()");
        } // selectAll()

        // ----------------------------------------------------
        
        var intervalChoose;
        var winchoose; 

        function findChoosed() {
          var frm = document.forms[0];         
          
          if (winchoose.closed) {
            clearInterval(intervalChoose);
            if (frm.id_target_cat.value.length>0) {
<% if (bIsGuest) { %>
              alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
              if (window.confirm ("Are you sure you want to " + (parseInt(frm.tp_operation.value)==1 ? "copy" : "move") + " selected files to category " + frm.tr_target_cat.value + "?")) {
                frm.action = "catprods_copy.jsp";
                frm.submit();
              } // fi (confirm)
<% } %>
            } // fi (id_target_cat!="")
          } // fi (winchoose.closed)
        } // findChoosed()

        // ----------------------------------------------------
                   
        function selectCategory(tpOperation) {
          document.forms[0].tp_operation.value = String(tpOperation);
          
          // Abrir un arbol de seleccion de categoria
          winchoose = window.open("pickdipu.jsp?inputid=id_target_cat&inputtr=tr_target_cat", "picktarget", "status=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=330,height=460");
	        intervalChoose = setInterval ("findChoosed()", 100);
        }

        // ----------------------------------------------------

        function createCategory() {
          window.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_parent_cat=" + id_category, "newcategory", "directories=no,toolbar=no,menubar=no,width=480,height=420");
	}
	
        // ----------------------------------------------------

        function viewItem(item_type, id_item, tr_item) {
          if (item_type=="category")       
            window.document.location.href = "catprods.jsp?id_category=" + id_item + "&tr_category=" + tr_item; 
          else
            window.open ("../servlet/HttpBinaryServlet?id_product=" + id_item + "&id_category=<%=id_category%>&id_user=<%=id_user%>");
        }

        // ----------------------------------------------------

        function editItem(item_type,id_item,id_location) {
          if (item_type=="category")
            window.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_category=" + id_item + "&id_parent_cat=" + id_category, "editcategory", "directories=no,toolbar=no,menubar=no,width=480,height=460");
	        else
	          modifyDoc(id_item,id_location);
        }

        // ----------------------------------------------------

        function renameItem(item_type, id_item, id_location, tr_item) {
          if (item_type=="category")
            window.open ("catrename.jsp?id_category=" + id_item + "&tr_category=" + tr_item, null, "directories=no,toolbar=no,menubar=no,width=460,height=240");
          else
            window.open ("docrename.jsp?gu_category=<%=id_category%>&gu_product=" + id_item + "&id_location=" + id_location + "&xfile=" + tr_item, null, "directories=no,toolbar=no,menubar=no,width=460,height=240");
        }

        // ----------------------------------------------------

        function deleteItem(item_type,id_item) {                
          if (item_type=="category") {
            window.open ("catedit_del.jsp?checkeditems=" + id_item + "&id_parent_cat=" + id_category + "&tr_parent=" + tr_category, "deletecategory", "directories=no,toolbar=no,menubar=no,width=400,height=300");
      	  }
      	  else {
      	    var frm = document.forms[0];
      	     for (var i=0;i<frm.elements.length; i++) {
      	       if (frm.elements[i].type=="checkbox")
      	         frm.elements[i].checked = (frm.elements[i].value==id_item);
      	     }
      	    deleteProducts();
      	  } // fi
      	} // deleteItem

        // ----------------------------------------------------

        function checkOutItem(item_type,id_item,id_location) {
          var result;

          <% if (((iACLMask&ACL.PERMISSION_MODIFY)==0) || bIsGuest) { %>
	           alert ("You don't have enought access rights to check-out documents at this category");
          <% } else { %>
          result = httpRequestText("doccheckout.jsp?tp_item="+item_type+"&gu_item="+id_item+"&gu_category="+id_category).split("\n");
          if (result[0]=="SUCCESS") {
          	if (item_type=="product")
              window.open("../servlet/HttpBinaryServlet?id_product="+id_item+"&id_category="+id_category+"&id_user=<%=id_user%>");
            document.location.reload();
          } else {
          	alert (result);
          }
          <% } %>
        } // checkOutItem

        // ----------------------------------------------------

        function undoCheckOutItem(item_type,id_item,id_location) {
				  var result;
				  
          <% if (((iACLMask&ACL.PERMISSION_MODIFY)==0) || bIsGuest) { %>
	           alert ("You don't have enought access rights to check-in documents at this category");
          <% } else { %>
          result = httpRequestText("docundocheckout.jsp?tp_item="+item_type+"&gu_item="+id_item+"&gu_category="+id_category).split("\n");
          if (result[0]=="SUCCESS")
            document.location.reload();
          else
          	alert (result);
          <% } %>
        } // checkOutItem

	      // ----------------------------------------------------

        function checkInItem(item_type,id_item,id_location) {
          <% if (((iACLMask&ACL.PERMISSION_MODIFY)==0) || bIsGuest) { %>
	           alert ("You don't have enought access rights to check-in documents at this category");
          <% } else { %>
            window.open("doccheckin.jsp?id_category=" + id_category + "&id_location=" + id_location + "&id_product=" + id_item, "ci"+id_item, "directories=no,toolbar=no,menubar=no,width=480,height=350");
            document.location.reload();
          <% } %>
        }          
			
			  function sendByMail(id,lc) {
			    window.open("../hipermail/msg_new_f.jsp?folder=drafts&gu_location="+lc);
			  }
        // ------------------------------------------------------

        function configureMenu() {
<% if (((iACLMask&ACL.PERMISSION_MODIFY)!=0)) { %>
          if (jsItemTp=="product") {
            if (null==jsBlockedBy) {
              enableRightMenuOption (2);
              disableRightMenuOption(3);
              disableRightMenuOption(4);
            } else {
              disableRightMenuOption(2); 
              if (jsBlockedBy=="<%=id_user%>") {
                enableRightMenuOption(3);
                enableRightMenuOption(4);
						  } else {
                disableRightMenuOption(3);
                disableRightMenuOption(4);
              }							
            }
            enableRightMenuOption (6);
          } else {
              disableRightMenuOption(2);
              disableRightMenuOption(3);          
              disableRightMenuOption(4);
              disableRightMenuOption(6);
          }
<% } %>
				}

        // ----------------------------------------------------
	                
      //-->
    </SCRIPT>
    <TITLE>hipergate :: Category</TITLE>
  </HEAD>  
  <BODY  TOPMARGIN="4" MARGINHEIGHT="4" onClick="hideRightMenu()">
  <DIV class="cxMnu1" style="width:300px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
    <TABLE CELLSPACING="0" BORDER="0" SUMMARY="Spacer"><TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" BORDER="0"></TD></TR></TABLE>        
    <TABLE WIDTH="98%" CELLSPACING="4" BORDER="0" SUMMARY="Parent Category Listing">
      <TR>
        <TD CLASS="striptitle">
          <FONT CLASS="title1"><% out.write(tr_category); %></FONT>
        </TD>      
      </TR>
      <TR>
        <TD>
	        <%=sCats%>
        </TD>
      </TR>  
      <TR>
        <TD>
          <FONT CLASS="textplain">click&nbsp;<A HREF="javascript:updateList()">here</A>&nbsp;For switching to selected Category</FONT>
        </TD>
      </TR>  
    </TABLE>
<% if ( ((iACLMask&ACL.PERMISSION_ADD)!=0) || ((iACLMask&ACL.PERMISSION_MODIFY)!=0)) { %>
    <TABLE CELLSPACING="2" CELLPADDING="2" SUMMARY="Commands">
      <TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/newfolder16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Category"></TD>
        <TD VALIGN="middle"><A HREF="javascript:;" onclick="createCategory()" CLASS="linkplain">New Category</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/newlink.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Link"></TD>
        <TD VALIGN="middle"><A HREF="javascript:;" onclick="createLink()" CLASS="linkplain">New Link</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/newdoc.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New File"></TD>
        <TD VALIGN="middle"><A HREF="javascript:;" onclick="createDocument()" CLASS="linkplain">New File</A></TD>
      </TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/copyfiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Copy Links and Files"></TD>
        <TD><A HREF="javascript:selectCategory(1)" CLASS="linkplain" TITLE="Copy Links and Files">Copy</A></TD>
<% if ( ((iACLMask&ACL.PERMISSION_DELETE)!=0) || ((iACLMask&ACL.PERMISSION_MODIFY)!=0)) { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/movefiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Move Links & Files"></TD>
        <TD><A HREF="javascript:selectCategory(2)" onclick="" CLASS="linkplain" TITLE="Move Links & Files">Move</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="javascript:;" onclick="deleteProducts()" CLASS="linkplain">Delete Links & Files</A></TD>
<% } else { %>
	<TD COLSPAN="4"></TD>
<% } %>    
      </TR>
      <TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    </TABLE>
<% } %>    
    <FORM ACTION="catprods_delete.jsp" METHOD="post" TARGET="catexec">              
      <INPUT TYPE="hidden" NAME="id_target_cat">
      <INPUT TYPE="hidden" NAME="tr_target_cat">
      <INPUT TYPE="hidden" NAME="tp_operation">
      <INPUT TYPE="hidden" NAME="chkcount" VALUE="<%=iProdCount%>">
      <INPUT TYPE="hidden" NAME="id_category" VALUE="<%=id_category%>">      
      <TABLE CELLPADDING="2" SUMMARY="File listing">
        <TR>
          <TD CLASS="tableheader" WIDTH="20px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ?  "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" TITLE="Order by Name" ALT="Order by Name"></A>&nbsp;Name</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ?  "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" TITLE="Order by Date Modified" ALT="Order by Date Modified"></A>&nbsp;Modified</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="javascript:;" onclick="selectAll()" TITLE="Select all"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD>
        </TR>
<%
	  if (null!=sParentId) {
	    out.write("        <TR>\n");
            out.write("          <TD CLASS='tabletd'><IMG SRC=\"../skins/"+sSkin+"/nav/folderclosed_16x16.gif\" ALT=\"Closed Folder\" BORDER=0></TD>\n");
            out.write("          <TD CLASS='tabletd'><A HREF=\"catprods.jsp?id_category=" + sParentId + "&tr_category=" + Gadgets.URLEncode(sParentTr) + "\" oncontextmenu=\"return false;\">..</A></TD>\n");
	  }

          for (int iChl=0; iChl<iChld; iChl++) {
	          out.write("        <TR>\n");
            out.write("          <TD CLASS='tabletd'><IMG SRC=\"../skins/"+sSkin+"/nav/folderclosed_16x16.gif\" BORDER=0></TD>\n");
            out.write("          <TD CLASS='tabletd'><A HREF=\"catprods.jsp?id_category=" + oChld.getString(0,iChl) + "&tr_category=" + Gadgets.URLEncode(oChld.getString(1,iChl)) + "\" TITLE=\"Click Right Mouse Button for Context Menu\" oncontextmenu=\"jsBlockedBy=null; jsItemTp='category';jsItemId='" + oChld.getString(0,iChl) + "'; jsItemTr='" + Gadgets.URLEncode(oChld.getString(1,iChl)) + "'; configureMenu(); return showRightMenu(event);\" onmouseover=\"window.status='Edit Category'; return true;\" onmouseout=\"window.status=''; return true;\">" + oChld.getString(1,iChl) + "</A></TD>\n");
            if (oChld.isNull(2,iChl))
              out.write("          <TD CLASS='tabletd'></TD>\n"); 
            else
              out.write("          <TD CLASS='tabletd'>" + oChld.getDateTime(2, iChl) + "</TD>\n");
	          out.write("          <TD CLASS='tabletd'></TD>\n");
	          out.write("        </TR>\n");
          } // next()
          
          String sFileLen; 
          StringBuffer sBuffer = new StringBuffer(640*iProdCount);
          
          if ((iACLMask&ACL.PERMISSION_LIST)!=0) {
            for (int iRow=0; iRow<iProdCount; iRow++) {            
              if (oProd.get(6,iRow)!=null) 
                sFileLen = " " + String.valueOf(oProd.getInt(6,iRow) + " bytes");
              else
                sFileLen = "";
              
              sBuffer.append("        <TR><TD ALIGN='middle' CLASS='tabletd' WIDTH='20px'>");
              
              if ((iACLMask&ACL.PERMISSION_READ)!=0) {              
                sBuffer.append("<A HREF='");
                switch (oProd.getInt(5,iRow)) {
	              case 1:
	              case 4:	        
                  sBuffer.append("../servlet/HttpBinaryServlet?id_product=" + oProd.getString(0,iRow) + "&id_category=" + id_category + "&id_user=" + id_user);
            	    if (oIcons.containsKey(oProd.getString(8,iRow)))
            	      sBuffer.append("' TARGET='_blank'><IMG SRC='.." + oIcons.get(oProd.getString(8,iRow)) + "' BORDER='0' ALT='Download/Open" + sFileLen + "'></A></TD><TD CLASS='tabletd'><A HREF=\"#\" oncontextmenu=\"jsBlockedBy="+(oProd.isNull(10,iRow) ? "null" : "'"+oProd.getString(10,iRow)+"'")+"; jsItemTp='product';jsItemId='"+oProd.getString(0,iRow)+"';jsItemLc='"+oProd.getString(7,iRow)+"';jsItemTr='"+Gadgets.URLEncode(oProd.getStringNull(9,iRow,""))+"'; " + (((iACLMask&ACL.PERMISSION_MODIFY)!=0) ? "configureMenu();" : "") + " return showRightMenu(event);\" onClick='modifyDoc(\"");
            	    else
            	      sBuffer.append("' TARGET='_blank'><IMG SRC='../images/images/download.gif' BORDER='0' ALT='Download/Open" + sFileLen + "'></A></TD><TD CLASS='tabletd'><A HREF=\"#\" oncontextmenu=\"jsBlockedBy="+(oProd.isNull(10,iRow) ? "null" : "'"+oProd.getString(10,iRow)+"'")+"; jsItemTp='product';jsItemId='"+oProd.getString(0,iRow)+"';jsItemLc='"+oProd.getString(7,iRow)+"'; jsItemTr='"+Gadgets.URLEncode(oProd.getStringNull(9,iRow,""))+"'; " + (((iACLMask&ACL.PERMISSION_MODIFY)!=0) ? "configureMenu();" : "") + " return showRightMenu(event);\" onClick='modifyDoc(\"");
                    sBuffer.append(oProd.getString(0,iRow) + "\",\"" + oProd.getString(7,iRow));
                    break;
                case 2: 
                case 3: 
                  sBuffer.append(oProd.getString(4,iRow));
            	    sBuffer.append("' TARGET='_blank'><IMG SRC='../images/images/wlink.gif' WIDTH='16' HEIGHT='16' BORDER='0' ALT='Open in new window'></A></TD><TD CLASS='tabletd'><A HREF=\"#\" onClick='modifyLink(\"");
                    sBuffer.append(oProd.getString(0,iRow));
                    break;
              }
              sBuffer.append("\")' TITLE='Edit'>");
              sBuffer.append(oProd.getString(1,iRow));
              sBuffer.append("</A>");
              if (!oProd.isNull(10,iRow))
                sBuffer.append(" ["+oUsers.get(oProd.getString(10,iRow))+"]");
            }
              
            sBuffer.append("</TD>");
              
            sBuffer.append("<TD CLASS='tabletd'>");
            sBuffer.append(nullif(oProd.getDateTime(3,iRow)));
            sBuffer.append("</TD><TD CLASS='tabletd'><INPUT TYPE='checkbox' VALUE='");
            sBuffer.append(oProd.getString(0,iRow));
            sBuffer.append("' NAME='chkbox" + String.valueOf(iRow) + "'");
            sBuffer.append("></TD></TR>\n");
          } // next (iRow)
          
	    out.write(sBuffer.toString());
	  } // fi (ACL.PERMISSION_LIST)
	  
	  if (oShared!=null) {
        %>

        <TR>
          <TD CLASS='tabletd'><IMG SRC="../skins/<%=sSkin%>/nav/folderclosed_16x16.gif" BORDER=0></TD>
          <TD CLASS='tabletd'><A HREF="catprods.jsp?id_category=<% out.write(oShared.getString(DB.gu_category)); %>&tr_category=<%=Gadgets.URLEncode(sSharedLbl)%>" TITLE="Bot&oacute;n Derecho para Ver el Men&uacute; Contextual" oncontextmenu="jsBlockedBy=null; jsItemTp='category';jsItemId='<% out.write(oShared.getString(DB.gu_category)); %>'; jsItemTr='<%=sSharedLbl%>'; return showRightMenu(event);" onmouseover="window.status='Edit Category'; return true;" onmouseout="window.status=''; return true;"><% out.write(sSharedLbl); %></A></TD>
          <TD CLASS='tabletd'><%=nullif(oShared.getDateTime(DB.dt_modified))%></TD>
          <TD CLASS='tabletd'></TD>
        </TR>
      <% } // fi (oShared) %>
      </TABLE>
      <%
      if ((iACLMask&ACL.PERMISSION_LIST)==0)
        out.write("<FONT CLASS=\"textplain\">You are not authorized to see products from this category</FONT>");
      %>
    </FORM>
    
    <DIV id="divHolder" style="width:100px;height:20px;z-index:200;visibility:hidden;position:absolute;top:31px;left:0px"></DIV>
    <FORM name="divForm"><input type="hidden" name="divField" value=""></FORM>

    <SCRIPT type="text/javascript">
      <!--

      addMenuOption("View","viewItem(jsItemTp,jsItemId,jsItemTr)",0);
<% if (((iACLMask&ACL.PERMISSION_MODIFY)!=0)) { %>
      addMenuOption("Edit","editItem(jsItemTp,jsItemId,jsItemLc)",0);
      addMenuOption("Check-out","checkOutItem(jsItemTp,jsItemId,jsItemLc)",0);
      addMenuOption("Check-in","checkInItem(jsItemTp,jsItemId,jsItemLc)",0);
      addMenuOption("Undo check-out","undoCheckOutItem(jsItemTp,jsItemId,jsItemLc)",0);
<% }
   if ((iAppMask & (1<<Hipermail))!=0) { %>
      addMenuSeparator();
      addMenuOption("Send by e-mail","sendByMail(jsItemId,jsItemLc)",0);
<% } 
   if (((iACLMask&ACL.PERMISSION_DELETE)!=0) || ((iACLMask&ACL.PERMISSION_MODIFY)!=0)) { %>
      addMenuSeparator();
      addMenuOption("Delete","deleteItem(jsItemTp,jsItemId)",0);
<% } %>

      //-->
    </SCRIPT>

  </BODY>
</HTML>
            
