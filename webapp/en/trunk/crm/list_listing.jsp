<%@ page import="java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.crm.DistributionList,com.knowgate.hipergate.Category,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String id_user = getCookie(request,"userid",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String screen_width = request.getParameter("screen_width");
  String gu_list = request.getParameter("gu_list");

  int iScreenWidth;
  float fScreenRatio;

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;
        
  String sField = request.getParameter("field")==null ? "" : request.getParameter("field");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
  String sCateg = request.getParameter("categ")==null ? "" : request.getParameter("categ");
  boolean bHasAccounts = false;
  String sGuRootCategory = null;    
  int iListCount = 0;
  DBSubset oLists = null;
  DBSubset oCatgs = new DBSubset (DB.k_cat_expand + " e," + DB.k_categories + " c",
                                  "e." + DB.gu_category + ",c." + DB.nm_category + ",e." + DB.od_level + ",e." + DB.od_walk + ",e." + DB.gu_parent_cat + ",'' AS "+DB.tr_+sLanguage,
    				                      "e." + DB.gu_category + "=c." + DB.gu_category + " AND "+
    				                      "e." + DB.od_level + ">1 AND e." + DB.gu_rootcat + "=? AND e." + DB.gu_parent_cat + " IS NOT NULL ORDER BY e." + DB.od_walk, 50);
  int iCatgs = 0;
  Object[] aFind = { '%' + sFind + '%' };
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

  if (iSkip<0) iSkip = 0;

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";   
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  JDCConnection oConn = null;  
  boolean bIsGuest = true;
    
  try {
    
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("listlisting");
		
    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM "+DB.k_user_mail+" WHERE "+DB.gu_user+"=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, id_user);
    ResultSet oRSet = oStmt.executeQuery();
    bHasAccounts = oRSet.next();
    oRSet.close();
    oStmt.close();

		sGuRootCategory = Category.getIdFromName(oConn, n_domain+"_apps_sales_lists_"+gu_workarea);
    if (null==sGuRootCategory) {
			oConn.setAutoCommit(false);
		  String sGuSalesCategory = Category.getIdFromName(oConn, n_domain+"_apps_sales");
    	Category oRootCat = new Category();
    	oRootCat.put(DB.gu_owner, DBCommand.queryStr(oConn, "SELECT "+DB.gu_owner+" FROM "+DB.k_domains+" WHERE "+DB.id_domain+"="+id_domain));
    	oRootCat.put(DB.nm_category, n_domain+"_apps_sales_lists_"+gu_workarea);
      oRootCat.put(DB.bo_active, (short) 1);
      oRootCat.put(DB.id_doc_status, (short) 1);
      oRootCat.put(DB.len_size, 0);
      oRootCat.store(oConn);
      if (sGuSalesCategory!=null) {
        DBCommand.executeUpdate(oConn, "INSERT INTO "+DB.k_cat_tree+" ("+DB.gu_parent_cat+","+DB.gu_child_cat+") VALUES ('"+sGuSalesCategory+"','"+oRootCat.getString(DB.gu_category)+"')");
      }
      oConn.commit();
    } else {
      iCatgs = oCatgs.load(oConn, new Object[]{sGuRootCategory});
      Category oCatg = new Category();
      for (int l=0; l<iCatgs; l++) {
        oCatg.replace (DB.gu_category, oCatgs.getString(0,l));
        oCatgs.setElementAt(nullif(oCatg.getLabel(oConn, sLanguage), oCatgs.getString(1,l)), 5, l); 
      } // next
    } // fi

    if (sCateg.length()>0) {

      DBSubset oChlds = new DBSubset (DB.k_cat_expand, DB.gu_category, DB.gu_rootcat+"=?", 20);
      int iChlds = oChlds.load(oConn, new Object[]{sCateg});
      sCateg = "'"+sCateg+"'";
      for (int c=0; c<iChlds; c++) {
        sCateg += ",'"+oChlds.getString(0,c)+"'";
      }

      if (sFind.length()==0) {
        oLists = new DBSubset (DB.k_lists+" l,"+DB.k_x_cat_objs+" c", 
      			                   "l.gu_list,l.tp_list,l.gu_query,l.tx_subject,l.de_list",
      			                   "l."+DB.gu_list+"=c."+DB.gu_object+" AND c."+DB.id_class+"="+String.valueOf(DistributionList.ClassId)+" AND "+
      			                   "c."+DB.gu_category+" IN ("+sCateg+") AND "+
      		                     "l."+DB.tp_list + "<>" + String.valueOf(DistributionList.TYPE_BLACK) + " AND l." + DB.gu_workarea + "='" + gu_workarea + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
        oLists.setMaxRows(iMaxRows);
        iListCount = oLists.load (oConn, iSkip);
      }
      else {
        oLists = new DBSubset (DB.k_lists+" l,"+DB.k_x_cat_objs+" c",
      			                   "l.gu_list,l.tp_list,l.gu_query,l.tx_subject,l.de_list",
      			                   "l."+DB.gu_list+"=c."+DB.gu_object+" AND c."+DB.id_class+"="+String.valueOf(DistributionList.ClassId)+" AND "+
      			                   "c."+DB.gu_category+" IN ("+sCateg+") AND "+
      		                     "l."+DB.tp_list + "<>" + String.valueOf(DistributionList.TYPE_BLACK) + " AND l." + DB.gu_workarea + "='" + gu_workarea + "' AND " + sField + " " + DBBind.Functions.ILIKE + " ? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
        oLists.setMaxRows(iMaxRows);
        iListCount = oLists.load (oConn, new Object[] { "%" + sFind +"%" }, iSkip);
      }
    } else {
      if (sFind.length()==0) {
        oLists = new DBSubset (DB.k_lists, 
      			                   "gu_list,tp_list,gu_query,tx_subject,de_list",
      		                     DB.tp_list + "<>" + String.valueOf(DistributionList.TYPE_BLACK) + " AND " + DB.gu_workarea + "='" + gu_workarea + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
        oLists.setMaxRows(iMaxRows);
        iListCount = oLists.load (oConn, iSkip);
      }
      else {
        oLists = new DBSubset (DB.k_lists, 
      			                   "gu_list,tp_list,gu_query,tx_subject,de_list",
      		                     DB.tp_list + "<>" + String.valueOf(DistributionList.TYPE_BLACK) + " AND " + DB.gu_workarea + "='" + gu_workarea + "' AND " + sField + " " + DBBind.Functions.ILIKE + " ? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
        oLists.setMaxRows(iMaxRows);
        iListCount = oLists.load (oConn, new Object[] { "%" + sFind +"%" }, iSkip);
      }
    }

    oConn.close("listlisting"); 
  }
  catch (SQLException e) {  
    oLists = null;
    oConn.close("listlisting");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    return;
  }
  oConn = null;
  sendUsageStats(request, "list_listing");   

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>  

  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" >
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    var menuLayer,addrLayer;
    dynapi.onLoad(init);
    function init() {
 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setVisible(true);
      menuLayer.setHTML(rightMenuHTML);
    }
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>

  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // Variables globales para traspasar la instancia clickada al menu contextual
        var jsListId;
        var jsListTp;
        var jsListNm;
        var jsListDe;
        var jsListQr;
                    
        <%
          
          out.write("var jsLists = new Array(");
            for (int i=0; i<iListCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oLists.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	      function createList() {	  	  
	        self.open ("list_wizard_01.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" , "listwizard", "directories=no,scrollbars=yes,toolbar=no,menubar=no,top=" + (screen.height-420)/2 + ",left=" + (screen.width-420)/2 + ",width=420,height=420");	  
	      } // createList()

        // ----------------------------------------------------
	
	      function deleteLists() {	  
	        var offset = 0;
	        var frm = document.forms[0];
	        var chi = frm.checkeditems;
	        	  
	        if (window.confirm("Are you sure you want to delete selected lists?á certo de")) {
	        	  
	          chi.value = "";	  	  
	          
	          frm.action = "list_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	        	  
	          for (var i=0;i<jsLists.length; i++) {
                    while (frm.elements[offset].type!="checkbox") offset++;
          	      if (frm.elements[offset].checked)
                      chi.value += jsLists[i] + ",";
                    offset++;
	          } // next()
        
	          if (chi.value.length>0) {
	            chi.value = chi.value.substr(0,chi.value.length-1);
                    frm.submit();
                  } // fi(chi!="")
                } // fi (confirm)
	      } // deleteLists()

        // ----------------------------------------------------
	
	      function moveLists() {	  
	        var offset = 0;
	        var frm = document.forms[0];
	        var chi = frm.checkeditems;
	       
	        if (frm.sel_category_move.selectedIndex<=0) {
	          alert ("You must select a target category");
	          frm.sel_category_move.focus();
	          return false;
	        }

	        if (window.confirm("Are you sure that you want to move the selected lists?")) {
	        	  
	          chi.value = "";	  	  
	          
	          frm.action = "list_edit_move.jsp?gu_category=&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	        	  
	          for (var i=0;i<jsLists.length; i++) {
                    while (frm.elements[offset].type!="checkbox") offset++;
          	      if (frm.elements[offset].checked)
                      chi.value += jsLists[i] + ",";
                    offset++;
	          } // next()
        
	          if (chi.value.length>0) {
	            chi.value = chi.value.substr(0,chi.value.length-1);
                    frm.submit();
                  } // fi(chi!="")
                } // fi (confirm)
	      } // moveLists()
	      
        // ----------------------------------------------------

	      function modifyList(id,nm) {	  
	        self.open ("list_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_list=" + id + "&n_list=" + escape(nm), "editlist", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-420)/2 + ",left=" + (screen.width-600)/2 + ",width=600,height=480");
	      }	

        // ----------------------------------------------------

	      function sortBy(fld) {
	        // Ordenar por un campo
	        
	        window.location = "list_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>" + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&categ=" + (frm.sel_category.selectedIndex<=0 ? "" : frm.sel_category.options[frm.sel_category.selectedIndex].value) + "&maxrows=" + document.forms[0].maxrows.value;
	      }

        // ----------------------------------------------------

        function selectAll() {
          // Seleccionar/Deseleccionar todas las instancias
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsLists.length; c++)                        
            eval ("frm.elements['" + jsLists[c] + "'].click()");
        } // selectAll()
       
       // ----------------------------------------------------
	
	     function findList() {	  	  
	       var frm = document.forms[0];
       
	       if (frm.find.value!="")
	         window.location = "list_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=tx_subject&find=" + escape(frm.find.value) + "&categ=" + (frm.sel_category.selectedIndex<=0 ? "" : frm.sel_category.options[frm.sel_category.selectedIndex].value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&maxrows=" + document.forms[0].maxrows.value;
         else
	         window.location = "list_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&categ=" + (frm.sel_category.selectedIndex<=0 ? "" : frm.sel_category.options[frm.sel_category.selectedIndex].value) + "&maxrows=" + document.forms[0].maxrows.value;
	     } // findList()

       // ----------------------------------------------------
	
	     function editMembers(id,de) {
         if (jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_STATIC)); %> || jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_DIRECT)); %>)
           window.open('member_listing.jsp?gu_list=' + id + '&de_list=' + escape(de),'wMembers','height=' + (screen.height>600 ? '600' : '520') + ',width= ' + (screen.width>800 ? '800' : '760') + ',scrollbars=yes,toolbar=no,menubar=no');
         else if (jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_DYNAMIC)); %>)
           window.open('../common/qbf.jsp?caller=list_listing.jsp&queryspec=listmember&caller=list_listing.jsp?gu_list=' + id + '&de_title=' + escape('Consulta de Miembros: ' + de) + '&queryspec=listmember&queryid=' + jsListQr,'wMemberList','height=' + (screen.height>600 ? '600' : '520') + ',width= ' + (screen.width>800 ? '800' : '760') + ',scrollbars=yes,toolbar=no,menubar=no');
       }

       // ----------------------------------------------------
	
	     function exportMembers(id) {
         window.open('list_members_csv.jsp?gu_list=' + id);
       }

       // ----------------------------------------------------
	
	     function editQuery(id,de) {
         if (jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_DYNAMIC)); %>)
           window.open('../common/qbf.jsp?caller=list_listing.jsp&queryspec=listmember&caller=list_listing.jsp?gu_list=' + id + '&de_title=' + escape('Consulta de Miembros: ' + de) + '&queryspec=listmember&queryid=' + jsListQr,'wMemberQuery','height=' + (screen.height>600 ? '600' : '520') + ',width= ' + (screen.width>800 ? '800' : '760') + ',scrollbars=yes,toolbar=no,menubar=no');
       }

       // ----------------------------------------------------
	
	     function mergeMembers(id,de) {
          if (isRightMenuOptionEnabled(3)) {
            window.open('list_merge.jsp?id_domain=' + getCookie('domainid') + '&gu_workarea=' + getCookie('workarea') + '&gu_list=' + id + '&de_list=' + escape(de),'wListMerge','height=460,width=600,scrollbars=yes,toolbar=no,menubar=no');
          }
       }

      // ----------------------------------------------------
        	
	    function createOportunity (id,de) {	  
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
	      self.open ("oportunity_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_list=" + id + "&de_list=" + escape(de), "createoportunity", "directories=no,toolbar=no,menubar=no,width=640,height=560");	  
<% } %>
	    } // createOportunity()

      // ------------------------------------------------------

      function createProject(gu,de) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        window.open("prj_create.jsp?gu_workarea=<%=gu_workarea%>&gu_list=" + gu + "&de_list=" + escape(de), "addproject", "directories=no,toolbar=no,menubar=no,width=540,height=280");       
<% } %>
      } // createProject

      // ------------------------------------------------------

<% if (bHasAccounts) { %>
      function sendEmail(gu,de) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        window.open("../hipermail/msg_new_f.jsp?folder=drafts&to={"+escape(de)+"}", "sendmailtolist");       
<% } %>
      } // sendEmail
<% } %>

      // ------------------------------------------------------

<% if (!bHasAccounts) { %>
      function configEmail() {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
	alert ("Mail server is not properly configured to send e-mails");
	top.document.location.href="../hipermail/mail_config_f.htm?selected=1&subselected=0"
<% } %>
      } // configEmail
<% } %>
	
      // ------------------------------------------------------

      function configureMenu() {
        if (jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_STATIC)); %> || jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_DIRECT)); %>) {
          enableRightMenuOption(4);
          disableRightMenuOption(5);
        }
        else {
          disableRightMenuOption(4);
          enableRightMenuOption(5);
        }          
      }
      
      // ----------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {
        
        if (winclone.closed) {
          clearInterval(intervalId);
          document.forms[0].find.value = jsListNm;
          findList();
        }
      } // findCloned()
      
      function clone() {        
        // [~//Abrir una ventana de clonado y poner un temporizador para recargar la página cuando se termine el clonado~]
<% if (bIsGuest) { %>
        alert ("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        winclone = window.open ("list_clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_instance=" + jsListId + "&opcode=CLST&classid=96", "clonelist", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-200)/2 + ",left=" + (screen.width-320)/2 + ",width=320,height=200");                
        intervalId = setInterval ("findCloned()", 100);
<% } %>
      }	// clone()
      
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	  function setCombos() {
	    setCookie ("maxrows", "<%=iMaxRows%>");
	    setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	    setCombo(document.forms[0].sel_category, "<%=nullif(request.getParameter("categ"))%>");
	  } // setCombos()  
    //-->    
  </SCRIPT>  
  <TITLE>hipergate :: Distribution Lists</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post" onSubmit="findList();return false;">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Distribution Lists</FONT></TD></TR></TABLE>      
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      
      <TABLE CELLSPACING="2" CELLPADDING="2" BORDER="0">
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle">
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert ('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New</A>
<% } else { %>
          <A HREF="#" onclick="createList();return false;" CLASS="linkplain">New</A>
<% } %>
        </TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD>
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert ('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
          <A HREF="#" onclick="deleteLists();return false;" CLASS="linkplain">Delete</A>
<% } %>
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Find List"></TD>
        <TD VALIGN="middle">
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">&nbsp;<A HREF="javascript:findList()" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:document.forms[0].find.value='';findList();" CLASS="linkplain" TITLE="Discard Find Filter">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
        </TR>
        <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/tree/menu_root.gif" WIDTH="18" HEIGHT="18" BORDER="0"></TD>
        <TD><A HREF="list_tree_f.htm?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>&top_parent_cat=<%=sGuRootCategory%>" TARGET="_top" CLASS="linkplain">Tree</A></TD>
				<TD COLSPAN="4"><SELECT name="sel_category" class="combomini" onchange="document.location='list_listing.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>&find=<%=Gadgets.URLEncode(sFind)%>&field=<%=sField%>&screen_width='+String(screen.width)+'&categ='+(this.selectedIndex<=0 ? '' : this.options[this.selectedIndex].value)"><%

    		  out.write ("<OPTION VALUE=\"" + sGuRootCategory + "\"></OPTION>");
    			for (int c=0; c<iCatgs; c++) {		    
        	  out.write ("<OPTION VALUE=\"" + oCatgs.getString(0,c) + "\">");
        		for (int s=1; s<oCatgs.getInt(2,c); s++) out.write("&nbsp;&nbsp;&nbsp;");
        		out.write (oCatgs.getString(5,c));
            out.write ("</OPTION>");
        	}                            
					
		 	  %></SELECT></TD>
            <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/movefiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Move to another category"></TD>
			<TD><SELECT name="sel_category_move" class="combomini"><%

    		  out.write ("<OPTION VALUE=\"" + sGuRootCategory + "\"></OPTION>");
    			for (int c=0; c<iCatgs; c++) {		    
        	  out.write ("<OPTION VALUE=\"" + oCatgs.getString(0,c) + "\">");
        		for (int s=1; s<oCatgs.getInt(2,c); s++) out.write("&nbsp;&nbsp;&nbsp;");
        		out.write (oCatgs.getString(5,c));
            out.write ("</OPTION>");
        	}                            
					
		 	  %></SELECT>&nbsp;<A HREF="#" CLASS="linkplain" onclick="moveLists()">Move</A></TD>
			  </TR>
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%    
          if (iSkip>0)
            out.write("            <A HREF=\"list_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
          if (!oLists.eof())
            out.write("            <A HREF=\"list_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(300f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4)" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Subject</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(400f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5)" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Description</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%
	  String sInstId, sInstQr, sInstTp, sInstNm, sInstDe;
	  for (int i=0; i<iListCount; i++) {
            sInstId = oLists.getString(0,i);
            sInstTp = String.valueOf(oLists.getShort(1,i));
            sInstQr = oLists.getStringNull(2,i,"");
            sInstNm = oLists.getStringNull(3,i,"");
            sInstDe = oLists.getStringNull(4,i,"");            
%>
            <TR HEIGHT="14">
              <TD CLASS="strip<%=(i%2)+1%>" VALIGN="middle">&nbsp;<A HREF="#" oncontextmenu="jsListId='<%=sInstId%>'; jsListTp=<%=sInstTp%>; jsListQr='<%=sInstQr%>'; jsListNm='<%=sInstNm%>'; jsListDe='<%=sInstDe%>'; configureMenu(); return showRightMenu(event);" onmouseover="window.status='Edit List'; return true;" onmouseout="window.status='';" onclick="modifyList('<%=sInstId%>','<%=sInstNm%>')" TITLE="Click Right Mouse Button for Context Menu"><%=oLists.getStringNull(3,i,"(no subject)")%></A></TD>
              <TD CLASS="strip<%=(i%2)+1%>">&nbsp;<%=oLists.getStringNull(4,i,"")%></TD>
              <TD CLASS="strip<%=(i%2)+1%>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<%=sInstId%>">
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>

    <SCRIPT language="JavaScript" type="text/javascript">
      addMenuOption("Open","modifyList(jsListId,jsListNm)",1);
      addMenuOption("Duplicate","clone()",0);
      addMenuOption("Combine","mergeMembers(jsListId,jsListDe)",0);
      addMenuSeparator();
      addMenuOption("Edit Members","editMembers(jsListId,jsListDe)",0);
      addMenuOption("Edit Query","editQuery(jsListId,jsListDe)",2);
      addMenuOption("Export members","exportMembers(jsListId)",0);
      addMenuSeparator();
      addMenuOption("New Oportunity","createOportunity(jsListId,jsListDe)",0);
<% if (((iAppMask & (1<<ProjectManager))!=0)) { %>
      addMenuOption("New Project","createProject(jsListId,jsListDe)",0);
<% } %>
<% if (((iAppMask & (1<<Hipermail))!=0)) {
      if (bHasAccounts) { %>
      addMenuOption("Send e-mail","sendEmail(jsListId,jsListDe)",0);
<%    } else { %>
      addMenuOption("Send e-mail","configEmail()",0);
<% }  } %>
    </SCRIPT>
</BODY>
</HTML>
