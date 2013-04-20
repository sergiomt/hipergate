<%@ page import="java.util.ArrayList,java.util.Date,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,java.sql.Timestamp,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBCommand,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.*,com.knowgate.hipergate.Category,com.knowgate.hipergate.QueryByForm,com.knowgate.forums.Forums,com.knowgate.forums.NewsGroup,com.knowgate.forums.NewsMessage,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");
  
  int iScreenWidth;
  float fScreenRatio;

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String gu_user = getCookie(request,"userid",""); 
  
  String screen_width = request.getParameter("screen_width");
  String gu_newsgroup = request.getParameter("gu_newsgrp");
  String nm_newsgrp = request.getParameter("nm_newsgrp");
  String gu_tag = request.getParameter("gu_tag");
  String dt_date = request.getParameter("dt_date");
  String dt_month = request.getParameter("dt_month");
  boolean bHasMonthParam = (dt_month!=null);
  String dt_year = request.getParameter("dt_year");
  boolean bHasYearParam = (dt_year!=null);
  boolean bo_parent = nullif(request.getParameter("bo_parent"),"0").equals("1");
  
  if (!bHasMonthParam || !bHasYearParam) {
    Date dtNow = new Date();
    dt_month = String.valueOf(dtNow.getMonth());
    dt_year = String.valueOf(dtNow.getYear()+1900);    
  }
  
  final int iLastDayOfMonth = Calendar.LastDay(Integer.parseInt(dt_month), Integer.parseInt(dt_year));
  Timestamp ts00Day, ts23Day;
  Date dtFirstMsg=null;
  Date dtLastMsg=null;
  if (null==request.getParameter("dt_date")) {
    ts00Day = new Timestamp(new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), 1, 0, 0, 0).getTime());
    ts23Day = new Timestamp(new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), iLastDayOfMonth, 23, 59, 59).getTime());
  } else {
    ts00Day = new Timestamp(new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), Integer.parseInt(dt_date), 0, 0, 0).getTime());
    ts23Day = new Timestamp(new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), Integer.parseInt(dt_date), 23, 59, 59).getTime());
  }

  final String aStatusIcons[] = { "validated.gif", "pending.gif", "discarded.gif", "expired.gif" };
  final String aStatusAlt[] = { "Validated", "Pending", "Not approved", "Outdated" };
  
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
  String sStatus = request.getParameter("status")==null ? "" : request.getParameter("status");
          
  boolean bIsAdmin = false;
  boolean bIsGuest = true;
  
  boolean bIsModerator = false;
  boolean bIsModerated = false;  
  int iMessageCount = 0;
  DBSubset oMessages;        
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "50"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 50; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (iSkip<0) iSkip = 0;

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "5";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 5;

  ArrayList aDaysWithPosts = null;
  Category oNewsGrp;
  QueryByForm oQBF;
  ArrayList aFind = new ArrayList();
  StringBuffer oBuffer = new StringBuffer();
  DBSubset oTags = null;
  int nTags = 0;

  JDCConnection oConn = GlobalDBBind.getConnection("messagelisting");  
    
  try {
    bIsAdmin = isDomainAdmin(GlobalCacheClient, GlobalDBBind, request, response);
    bIsGuest = isDomainGuest(GlobalCacheClient, GlobalDBBind, request, response);
    
    oNewsGrp = new Category(oConn, gu_newsgroup);
    bIsModerator = ((oNewsGrp.getUserPermissions(oConn,gu_user) & ACL.PERMISSION_MODERATE)!=0);
    bIsModerated = (oNewsGrp.getShort(DB.id_doc_status)==NewsGroup.MODERATED);

    oTags = GlobalCacheClient.getDBSubset("NewsGroupTags["+gu_newsgroup+"]");
    if (null==oTags) {
      oTags = new DBSubset(DB.k_newsgroup_tags, DB.gu_tag+","+DB.tl_tag, DB.gu_newsgrp+"=? ORDER BY 2", 30);
      nTags = oTags.load(oConn, new Object[]{gu_newsgroup});
    } else {
      nTags = oTags.getRowCount();
    }
    
    aDaysWithPosts = Forums.getDaysWithPosts(oConn, gu_newsgroup,
    																		     new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), 1),
    																				 new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), iLastDayOfMonth));

		String sQuery = "m." + DB.gu_msg + "=x." + DB.gu_object + " AND x." + DB.gu_category + "=";

    dtFirstMsg = DBCommand.queryMinDate(oConn, "m."+DB.dt_published, DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x", sQuery+"'"+gu_newsgroup+"'");
    dtLastMsg  = DBCommand.queryMaxDate(oConn, "m."+DB.dt_published, DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x", sQuery+"'"+gu_newsgroup+"'");
    
    sQuery += "?";
		aFind.add(gu_newsgroup);
		
		if (!bIsAdmin && !bIsModerator) {
		  sQuery += " AND (m." + DB.id_status + "="+String.valueOf(NewsMessage.STATUS_VALIDATED)+" OR " + DB.gu_writer + "=?) ";
		  aFind.add(gu_user);
		}
	  if (sStatus.length()>0) {
	    sQuery += " AND m."+DB.id_status+"=? ";
		  aFind.add(new Short(sStatus));	    
	  }
	  if (bo_parent) {
	    sQuery += " AND m."+DB.gu_parent_msg+" IS NULL ";
	  }
    if (bHasYearParam) {
      sQuery += " AND "+DBBind.Functions.ISNULL+"(m."+DB.dt_start+",m."+DB.dt_published+") BETWEEN ? AND ? ";
		  aFind.add(ts00Day);
		  aFind.add(ts23Day);      
    }
    if (gu_tag!=null) {
	    sQuery += " AND m."+DB.gu_msg+" IN (SELECT "+DB.gu_msg+" FROM "+DB.k_newsmsg_tags+" WHERE "+DB.gu_tag+"=?) ";
		  aFind.add(gu_tag);          
    }
    if (sFind.length()>0) {
      if (sField.length()>0) {
        if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
          sQuery += " AND m."+sField+" ~* ? ";
          aFind.add(".*"+Gadgets.accentsToPosixRegEx(sFind)+".*");
        } else {
          sQuery += " AND m."+sField+" "+DBBind.Functions.ILIKE+" ? ";
          aFind.add("%"+sField+"%");
        } // fi
      } else {
        if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
          sQuery += " AND (m."+DB.tx_subject+" ~* ? OR m."+DB.nm_author+" ~* ? OR m."+DB.tx_msg+" ~* ?) ";
          aFind.add(".*"+Gadgets.accentsToPosixRegEx(sFind)+".*");
          aFind.add(".*"+Gadgets.accentsToPosixRegEx(sFind)+".*");
          aFind.add(".*"+Gadgets.accentsToPosixRegEx(sFind)+".*");
        } else {
          sQuery += " AND (m."+DB.tx_subject+" "+DBBind.Functions.ILIKE+" ? OR m."+DB.nm_author+" "+DBBind.Functions.ILIKE+" ? OR m."+DB.tx_msg+" "+DBBind.Functions.ILIKE+" ?) ";
          aFind.add("%"+sField+"%");
          aFind.add("%"+sField+"%");
          aFind.add("%"+sField+"%");
        } // fi      	
      }
    } // fi

    oMessages = new DBSubset (DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x", 
      				                "m." + DB.gu_msg + ",m." + DB.gu_product + ",m." + DB.nm_author + ",m." + DB.tx_subject + ",m." + DB.dt_published + ",m." + DB.id_status + ",m." + DB.tx_email + ",m." + DB.nu_thread_msgs + ",m." + DB.gu_parent_msg,
								              sQuery + (iOrderBy>0 ? " ORDER BY " + sOrderBy + " DESC" : ""), iMaxRows);
    oMessages.setMaxRows(iMaxRows);
    iMessageCount = oMessages.load (oConn, aFind.toArray(), iSkip);

    if (bIsAdmin  || bIsModerator) {
	   PreparedStatement oStmt;
	   ResultSet oRSet;
	   String sForumsCat = Category.getIdFromName(oConn, n_domain + "_apps_forums");


	   if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {	     
	     oStmt = oConn.prepareStatement("(SELECT c." + DB.gu_category + ",NVL(l." + DB.tr_category + ",c." + DB.nm_category + ") FROM " + DB.k_cat_tree + " t, " + DB.k_categories + " c, " + DB.k_cat_labels + " l WHERE c." + DB.gu_category + "=l." + DB.gu_category + "(+) AND l." + DB.id_language + "=? AND t." + DB.gu_child_cat + "=c." + DB.gu_category + " AND t." + DB.gu_parent_cat + "=?) UNION (SELECT c.gu_category,c.nm_category,c.nm_icon FROM k_cat_tree t, k_categories c WHERE NOT EXISTS (SELECT l.gu_category FROM k_cat_labels l WHERE l.gu_category=c.gu_category AND l.id_language=?) AND t.gu_child_cat=c.gu_category AND t.gu_parent_cat=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	   }
	   else {
	     oStmt = oConn.prepareStatement("(SELECT c.gu_category," + DBBind.Functions.ISNULL + "(l.tr_category,c.nm_category) FROM k_cat_tree t, k_categories c LEFT OUTER JOIN k_cat_labels l ON c.gu_category=l.gu_category WHERE l.id_language=? AND t.gu_child_cat=c.gu_category AND t.gu_parent_cat=?) UNION (SELECT c.gu_category,c.nm_category FROM k_cat_tree t, k_categories c WHERE NOT EXISTS (SELECT l.gu_category FROM k_cat_labels l WHERE l.gu_category=c.gu_category AND l.id_language=?) AND t.gu_child_cat=c.gu_category AND t.gu_parent_cat=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
     }
         
	   oStmt.setString(1, sLanguage);
	   oStmt.setString(2, sForumsCat);
	   oStmt.setString(3, sLanguage);
	   oStmt.setString(4, sForumsCat);
	     
	   oRSet = oStmt.executeQuery();
	 
	   while (oRSet.next()) {
	     if (!gu_newsgroup.equals(oRSet.getString(1))) oBuffer.append ("<OPTION VALUE=\""+oRSet.getString(1)+"\">"+oRSet.getString(2)+"</OPTION>");
	   } // wend

	   oRSet.close();
	   oStmt.close();
	  }  
  }
  catch (SQLException e) {  
    oMessages = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("messagelisting");
    oConn = null;  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=../common/blank.htm"));
  }
  catch (IllegalStateException e) {  
    oMessages = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("messagelisting");
    oConn = null;  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=../common/blank.htm"));
  }
  catch (NullPointerException e) {  
    oMessages = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("messagelisting");
    oConn = null;  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=../common/blank.htm"));
  }

  if (null==oConn) return;  
  oConn = null;  

	sendUsageStats(request, "msg_list");

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript">
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    var menuLayer;
    dynapi.onLoad(init);
    function init() {
 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setHTML(rightMenuHTML);
    }
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        
        var jsMessageId;
        var jsPrevMsgId = "";
                    
        <%

          out.write("var jsMessages = new Array(");
            for (int i=0; i<iMessageCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oMessages.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	      function createMessage() {
	  
	        window.open ("msg_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_newsgrp="+ getURLParam("gu_newsgrp") + "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&screen_width=" + String(screen.width), "editmessage", "directories=no,toolbar=no,menubar=no,width=<% out.write(String.valueOf(floor(760f*fScreenRatio))); %>,height=<% out.write(String.valueOf(floor(520f*fScreenRatio))); %>; %>");	  
	      } // createMessage()

        // ----------------------------------------------------
        	
	      function editMessage(gu) {
	  
	        window.open ("msg_edit.jsp?gu_msg="+gu+"&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_newsgrp="+ getURLParam("gu_newsgrp") + "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&screen_width=" + String(screen.width), "editmessage", "directories=no,toolbar=no,menubar=no,width=<% out.write(String.valueOf(floor(760f*fScreenRatio))); %>,height=<% out.write(String.valueOf(floor(520f*fScreenRatio))); %>; %>");	  
	      } // createMessage()

        // ----------------------------------------------------
        	
	      function replyMessage(id) {	  

<% if (bIsGuest) { %>	  
	  alert ("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
	  window.open ("msg_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_newsgrp="+ getURLParam("gu_newsgrp") + "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&gu_parent_msg=" + id + "&screen_width=" + String(screen.width), "editmessage", "directories=no,toolbar=no,menubar=no,width=<% out.write(String.valueOf(floor(760f*fScreenRatio))); %>,height=<% out.write(String.valueOf(floor(520f*fScreenRatio))); %>; %>");	  
<% } %>
	} // createMessage()
	
        // ----------------------------------------------------
	
	function deleteMessages() {
	  // Borrar los mensajes marcados con checkboxes
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to delete selected messages?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "msg_edit_delete.jsp";
	  	  
	    for (var i=0;i<jsMessages.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsMessages[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteMessages()

        // ----------------------------------------------------
	
	function moveMessages() {
	  // Mover los mensajes marcados con checkboxes
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  
	  if (frm.sel_move.selectedIndex<=0) {
	    alert ("A target forum must be selected first");
	    frm.sel_move.focus();
	    return false;
	  }	  

	  if (window.confirm("Arre you sure that you want to move the selected threads?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "msg_edit_move.jsp";
	  	  
	    for (var i=0;i<jsMessages.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsMessages[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteMessages()

        // ----------------------------------------------------
	
	function moderateMessages() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  	  
	    chi.value = "";	  	  
	    frm.action = "msg_aproval.jsp";
	  	  
	    for (var i=0;i<jsMessages.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsMessages[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {

	      if (frm.aproval[0].checked)
	        frm.id_status.value = "0"; // STATUS_VALIDATED
	      else if (frm.aproval[1].checked)
	        frm.id_status.value = "2"; // STATUS_DISCARDED
	      else if (frm.aproval[2].checked)
	        frm.id_status.value = "1"; // STATUS_PENDING
	      else {
	        alert ("Debe seleccionar un estado al que cambiar");
	        return false;
	      }
	      
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")

	} // moderateMessages
	
        // ----------------------------------------------------

	      function readMessage(id) {	  
	        window.open ("msg_read.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_newsgrp=<%=gu_newsgroup%>&nm_newsgrp="+getURLParam("nm_newsgrp")+"&gu_msg=" + id, "readmessage" + id);
	      }	

        // ----------------------------------------------------

	      function readThread(id) {		  
	        window.open ("msg_thread.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_newsgrp=<%=gu_newsgroup%>&nm_newsgrp="+getURLParam("nm_newsgrp")+"&gu_msg=" + id, "readthread" + id);
	      }	

        // ----------------------------------------------------

	      function sortBy(fld) {
          var frm = document.forms[0];
	      	
	        window.location = "msg_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_newsgrp=" + getURLParam("gu_newsgrp") +
	                          "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&skip=0&orderby=" + fld +
	                          "&field=<%=sField%>&find=<%=sFind%>&status=<%=sStatus%>&bo_parent=" + getCheckedValue(frm.bo_parent) +
	                          (frm.sel_month.selectedIndex>0 ? "&dt_year="+getCombo(frm.sel_month).split("-")[0]+"&dt_month="+getCombo(frm.sel_month).split("-")[1] : "") +
														(frm.sel_tag.selectedIndex>0 ? "&gu_tag="+getCombo(frm.sel_tag) : "")+
	                          "&screen_width=" + String(screen.width);
	      }			

        // ----------------------------------------------------

	     function filterBy() {
	       // Mostrar sólo los mensajes que estén en un estado determinado
	       var status = getCombo(document.forms[0].sel_status);
	  
	       window.location = "msg_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_newsgrp=" + getURLParam("gu_newsgrp") + "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&skip=0&orderby=<%=sOrderBy%>&field=<%=sField%>&find=<%=sFind%>&status=" + status + "&screen_width=" + String(screen.width);
	     }			

        // ----------------------------------------------------

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsMessages.length; c++)                        
            eval ("frm.elements['" + jsMessages[c] + "'].click()");
        } // selectAll()
       
       // ----------------------------------------------------
	
	     function findMessage(day,month,year) {
	  	  
	       var frm = document.forms[0];
	  
	       window.location = "msg_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_newsgrp=" + getURLParam("gu_newsgrp") +
	                         "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&skip=0&orderby=<%=sOrderBy%>&bo_parent=" + getCheckedValue(frm.bo_parent) +
	                         (frm.find.value.length>0 ? (getCombo(frm.sel_searched)=="" ? "" : "&field="+getCombo(frm.sel_searched)) + "&find=" + escape(frm.find.value) : "") +
	                         "&status=" + status + "&screen_width=" + String(screen.width) + (day<=0 ? "" : "&dt_date=" + String(day)) +
	                         (month>=0 ? "&dt_month="+String(month) : "")+(year>0 ? "&dt_year="+String(year) : "");
	    } // findMessage()

       // ----------------------------------------------------
	
	     function findMessages(tag) {
	  	  
	       var frm = document.forms[0];
	  
	       window.location = "msg_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_newsgrp=" + getURLParam("gu_newsgrp") +
	                         "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&skip=0&orderby=<%=sOrderBy%>&bo_parent=0" + "&gu_tag=" + tag;
	    } // findMessages()

      // ----------------------------------------------------

      var intervalId;
      
      function preview() {
        clearInterval(intervalId);
        if (jsPrevMsgId != jsMessageId) {
          jsPrevMsgId = jsMessageId;
          window.parent.msgsexec.document.location = "msg_preview.jsp?gu_msg=" + jsMessageId;
        }
      }

      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
<% if ((bIsAdmin || bIsModerator) && bIsModerated) { %>
	  if (getURLParam("status")!=null)
	    setCombo(document.forms[0].sel_status, "<%=sStatus%>");	  
<% } %>
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	} // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Message Listing</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <FORM METHOD="post" TARGET="msgsexec" onSubmit="findMessage(0,-1,0);return false">
      <TABLE SUMMARY="Listing Title"><TR><TD WIDTH="100%" CLASS="striptitle"><FONT CLASS="title1"><% out.write(nm_newsgrp); %></FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="id_status">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE SUMMARY="Management Options" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD ALIGN="center"><IMG SRC="../images/images/refresh.gif" BORDER="0" ALT="Update"></TD>
        <TD VALIGN="middle" ALIGN="left"><A HREF="#" onClick="parent.frames['msgsexec'].document.location='../common/blank.htm';document.location.reload();"  CLASS="linkplain">Update</A></TD>
        <TD ALIGN="right" VALIGN="middle">&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Write"></TD>
        <TD VALIGN="middle" ALIGN="left">        	
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Write</A>
<% } else { %>
          <A HREF="#" onclick="createMessage()" CLASS="linkplain">Write</A>
<% } %>
        </TD>
<% if (bIsAdmin || bIsModerator) { %>
        <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD ALIGN="left">        
          <A HREF="#" onclick="deleteMessages()" CLASS="linkplain">Delete</A>
        </TD>
<% if (bo_parent) { %>
        <TD ALIGN="right" VALIGN="middle"><IMG SRC="../images/images/movefiles.gif" WIDTH="24" HEIGHT="16" HEIGHT="16" BORDER="0" ALT="Move"></TD>
        <TD VALIGN="middle" CLASS="textplain"><SELECT CLASS="combomini" NAME="sel_move"><OPTION VALUE="" SELECTED></OPTION><%=oBuffer.toString()%></SELECT>&nbsp;<A HREF="#" onclick="moveMessages()" CLASS="linkplain" TITLE="Mover">Move</A></TD>
<% } else { %>
        <TD COLSPAN="2"></TD>
<% } } else { %>
        <TD COLSPAN="4"></TD>
<% } %>
      </TR>
                
      </TR>
      </TR>
	    <TR>
<% if ((bIsAdmin || bIsModerator) && bIsModerated) { %>
        <TD ALIGN="right"><IMG SRC="../images/images/megaphone22x16.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Filter"></TD>
        <TD><SELECT NAME="sel_status" onChange="filterBy()" CLASS="combomini"><OPTION VALUE="" SELECTED>All<OPTION VALUE="0">Validated<OPTION VALUE="1">Pending<OPTION VALUE="2">Refused<OPTION VALUE="3">Outdated</SELECT></TD>
        <TD COLSPAN="3"><FONT CLASS="textplain"><INPUT TYPE="radio" NAME="aproval">&nbsp;Validate&nbsp;&nbsp;<INPUT TYPE="radio" NAME="aproval">&nbsp;Refuse&nbsp;&nbsp;<INPUT TYPE="radio" NAME="aproval">&nbsp;Pending</FONT></TD>
        <TD COLSPAN="3"><A CLASS="linkplain" HREF="#" onClick="moderateMessages()">Change status</A></TD>
<% } else out.write("<TD COLSPAN=\"8\"></TD>"); %>
      </TR>
      <TR>
        <TD ALIGN="center" VALIGN="middle"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle" CLASS="textplain"><SELECT CLASS="combomini" NAME="sel_searched"><OPTION VALUE="" SELECTED></OPTION><OPTION VALUE="<%=DB.nm_author%>">Author</OPTION><OPTION VALUE="<%=DB.tx_subject%>">Subject</OPTION><OPTION VALUE="<%=DB.tx_msg%>">Body</OPTION></SELECT></TD>
        <TD COLSPAN="3"><INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="100" SIZE="50" VALUE="<%=sFind%>"></TD>
	      <TD><A HREF="javascript:findMessage(0,-1,0);" CLASS="linkplain" TITLE="Buscar">Search</A></TD>
        <TD ALIGN="right" VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></TD>
        <TD ALIGN="left" VALIGN="bottom"><A HREF="javascript:window.parent.document.location.reload(true);" CLASS="linkplain" TITLE="Discard Find Filter">Discard</A></TD>
	    </TR>
      <TR>
      	<TD COLSPAN="2" CLASS="textplain">Tags</TD>
      	<TD COLSPAN="6" CLASS="textplain">
      	  <SELECT NAME="sel_tag" CLASS="combomini" onchange="if (this.selectedIndex>0) findMessages(this.options[this.selectedIndex].value); else window.parent.document.location.reload(true);"><OPTION VALUE=""></OPTION><%
            for (int t=0; t<nTags; t++) {
              out.write("<OPTION VALUE=\""+oTags.getString(0,t)+"\"");
              if (oTags.getString(0,t).equals(gu_tag)) out.write(" SELECTED=\"selected\"");
              out.write(">"+oTags.getString(1,t)+"</OPTION>");
            }
      	  %></SELECT>
      	</TD>
     </TR>
<% if (dtFirstMsg!=null) { %>
      <TR>
      	<TD COLSPAN="2" CLASS="textplain">Monthly archive</TD>
      	<TD COLSPAN="6" CLASS="textplain">
      	  <SELECT NAME="sel_month" CLASS="combomini" onchange="findMessage(0,Number(this.options[this.selectedIndex].value.split('-')[1]),Number(this.options[this.selectedIndex].value.split('-')[0]))"><OPTION VALUE="0-0"></OPTION><%
      	    Date dtMonth = new Date(dtFirstMsg.getYear(),dtFirstMsg.getMonth(),dtFirstMsg.getDate());
      	    while (dtMonth.getYear()*100+dtMonth.getMonth()<=dtLastMsg.getYear()*100+dtLastMsg.getMonth()) {
      	      out.write("<OPTION VALUE=\""+String.valueOf(dtMonth.getYear()+1900)+"-"+String.valueOf(dtMonth.getMonth())+"\"");
      	      if (bHasYearParam && bHasMonthParam) {
      	        if (Integer.parseInt(dt_year)==dtMonth.getYear()+1900 && Integer.parseInt(dt_month)==dtMonth.getMonth())
      	          out.write(" SELECTED=\"selected\"");
      	      }
      	      out.write(">"+Calendar.MonthName(dtMonth.getMonth(), sLanguage)+" "+String.valueOf(dtMonth.getYear()+1900)+"</OPTION>");
      	      dtMonth = new Date(dtMonth.getTime()+86400000l*((long)Calendar.LastDay(dtMonth.getMonth(), dtMonth.getYear()+1900)));
      	    } // wend
      	  %></SELECT>
      	</TD>
     </TR>
<% } %>
      <TR>
      	<TD COLSPAN="2" CLASS="textplain">Daily archive</TD>
      	<TD COLSPAN="6" CLASS="textplain">
<%		    try {
				    out.write(Calendar.MonthName(Integer.parseInt(dt_month), sLanguage));
				  } catch (IllegalArgumentException ignore) { }
				  for (int d=1; d<=iLastDayOfMonth; d++) {
				    out.write("&nbsp;&nbsp;");
				    if ( ((Boolean)aDaysWithPosts.get(d-1)).booleanValue() )
				      out.write("<A HREF='javascript:findMessage("+String.valueOf(d)+","+String.valueOf(dt_month)+","+String.valueOf(dt_year)+");' CLASS=linkplain>"+String.valueOf(d)+"</A>");
				    else
				    	out.write(String.valueOf(d));
				  } // next
%>      	
      	</TD></TR>
      <TR>
        <TD ALIGN="center" VALIGN="middle"></TD>
        <TD COLSPAN="5" VALIGN="middle" CLASS="textplain">
          <INPUT TYPE="radio" NAME="bo_parent" VALUE="0" onclick="findMessage(-1,<%=dt_month%>,<%=dt_year%>)" <%=(bo_parent ? "" : "CHECKED")%>>&nbsp;Show all messages&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="bo_parent" onclick="findMessage(-1,<%=dt_month%>,<%=dt_year%>)" VALUE="1" <%=(bo_parent ? "CHECKED" : "")%>>&nbsp;Show only the first message of each thread
        </TD>
        <TD COLSPAN="2"><FONT CLASS="textplain">Show</FONT>&nbsp;<SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;<FONT CLASS="textplain">Messages</FONT></TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE SUMMARY="Messages List" CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  if (iMessageCount>0) {
            if (iSkip>0)
              out.write("            <A HREF=\"msg_list.jsp?gu_newsgrp=" + gu_newsgroup + "&nm_newsgrp=" + Gadgets.URLEncode(nm_newsgrp) + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&screen_width=" + String.valueOf(iScreenWidth) + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oMessages.eof())
              out.write("            <A HREF=\"msg_list.jsp?gu_newsgrp=" + gu_newsgroup + "&nm_newsgrp=" + Gadgets.URLEncode(nm_newsgrp) + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&screen_width=" + String.valueOf(iScreenWidth) + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iMessageCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" WIDTH="<%=floor(160f*fScreenRatio)%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by Author"></A>&nbsp;<B>Author</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=floor(220f*fScreenRatio)%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by Subject"></A>&nbsp;<B>Subject</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Answers</B></TD>
          <TD CLASS="tableheader" WIDTH="128px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by publishing date"></A>&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%
	  String sStripN;
	  String sMsgId,sAuthor,sSubject,sDtPub,sMail;	  
	  int nAnswers,iStatus;
	  boolean bAttachs;
	  for (int i=0; i<iMessageCount; i++) {
            sMsgId   = oMessages.getString(0,i);
            bAttachs = !oMessages.isNull(1,i);
            sAuthor  = oMessages.getStringNull(2,i,"");
            sSubject = oMessages.getStringNull(3,i,"");
            sDtPub = oMessages.getDateTime(4,i);
	    iStatus = (int) oMessages.getShort(5,i);
	    sMail = oMessages.getStringNull(6,i,"");
	    nAnswers = oMessages.getInt(7,i)-1;
	    
            sStripN = "strip" + String.valueOf((i%2)+1);
	    
	    out.write("            <TR HEIGHT=\"14\">\n");
	    out.write("            <TD CLASS=\"" + sStripN + "\"><IMG SRC =\"../images/images/forums/" + aStatusIcons[iStatus] + "\" BORDER=\"0\" ALT=\"" + aStatusAlt[iStatus] + "\" TITLE=\"" + aStatusAlt[iStatus] + "\"></TD>\n");
	    out.write("              <TD CLASS=\"" + sStripN + "\">&nbsp;" + sAuthor + "</TD>\n");
	    out.write("              <TD CLASS=\"" + sStripN + "\">&nbsp;<A HREF=\"#\" onClick=\"readMessage('"+sMsgId+"');return false\" TARGET=\"_blank\" oncontextmenu=\"jsMessageId='" + sMsgId+ "'; jsAuthorEMail='" + sMail + "'; return showRightMenu(event);\" onmouseover=\"top.status='Loading Message&nbsp;" +  sSubject + "'; jsMessageId='" + sMsgId + "'; intervalId=setInterval ('preview()', 1500); return true;\" onmouseout=\"top.status=''; clearInterval(intervalId); return true;\">" + sSubject + "</A></TD>\n");
	    out.write("              <TD CLASS=\"" + sStripN + "\" ALIGN=\"center\">&nbsp;" + (oMessages.isNull(8,i) ? String.valueOf(nAnswers) : "") + "</TD>\n");
	    out.write("              <TD CLASS=\"" + sStripN + "\">&nbsp;" + sDtPub + "</TD>\n");
	    out.write("              <TD CLASS=\"" + sStripN + "\" ALIGN=\"center\"><INPUT VALUE=\"1\" TYPE=\"checkbox\" NAME=\"" + sMsgId + "\">\n");
	    out.write("            </TR>\n");
         } // next(i)
%>
      </TABLE>
    </FORM>
    <SCRIPT language="JavaScript" type="text/javascript">
      addMenuOption("Read Message","readMessage(jsMessageId)",1);
      addMenuOption("Read Thread","readThread(jsMessageId)",0);
      addMenuSeparator();
<% if (bIsAdmin) { %>
      addMenuOption("Edit Message","editMessage(jsMessageId)",0);
      addMenuSeparator();
<% } %>
      addMenuOption("Reply to All","replyMessage(jsMessageId)",0);
    </SCRIPT>
</BODY>
</HTML>