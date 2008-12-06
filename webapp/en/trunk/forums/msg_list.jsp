<%@ page import="java.util.ArrayList,java.util.Date,java.net.URLDecoder,java.sql.SQLException,java.sql.Timestamp,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.*,com.knowgate.hipergate.Category,com.knowgate.hipergate.QueryByForm,com.knowgate.forums.Forums,com.knowgate.forums.NewsGroup" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
  String dt_date = request.getParameter("dt_date");
  String dt_month = request.getParameter("dt_month");
  String dt_year = request.getParameter("dt_year");
  
  if (dt_month==null || dt_year==null) {
    Date dtNow = new Date();
    dt_month = String.valueOf(dtNow.getMonth());
    dt_year = String.valueOf(dtNow.getYear()+1900);    
  }
  
  final int iLastDayOfMonth = Calendar.LastDay(Integer.parseInt(dt_month), Integer.parseInt(dt_year));
  final String aStatusIcons[] = { "validated.gif", "pending.gif", "discarded.gif", "expired.gif" };
  final String aStatusAlt[] = { "Validado", "Pendiente de Validar", "Rechazado", "Caducado" };
  
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
    sOrderBy = "5";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 5;

  ArrayList aDaysWithPosts = null;
  Category oNewsGrp;
  QueryByForm oQBF;
  Object[] aFind = { null };
  
  JDCConnection oConn = GlobalDBBind.getConnection("messagelisting");  
    
  try {
    bIsAdmin = isDomainAdmin(GlobalCacheClient, GlobalDBBind, request, response);
    bIsGuest = isDomainGuest(GlobalCacheClient, GlobalDBBind, request, response);
    
    oNewsGrp = new Category(oConn, gu_newsgroup);
    bIsModerator = ((oNewsGrp.getUserPermissions(oConn,gu_user) & ACL.PERMISSION_MODERATE)!=0);
    bIsModerated = (oNewsGrp.getShort(DB.id_doc_status)==NewsGroup.MODERATED);
    
    aDaysWithPosts = Forums.getDaysWithPosts(oConn, gu_newsgroup,
    																		     new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), 1),
    																				 new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), iLastDayOfMonth));

    if (sWhere.length()>0) {
      oQBF = new QueryByForm("file://" + sStorage + "/qbf/" + request.getParameter("queryspec") + ".xml");
    
      oMessages = new DBSubset (oQBF.getBaseObject(), 
      				 "b." + DB.gu_company + "," + "b." + DB.nm_legal + "," + DBBind.Functions.ISNULL + "(" + "b." + DB.de_company + ",'')," + "b." + DB.id_sector + "," + "b." + DB.id_legal + "," + "b." + DB.id_status,
      				 "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oMessages.setMaxRows(iMaxRows);
      iMessageCount = oMessages.load (oConn, iSkip);
    }
    
    else if (sFind.length()==0 || sField.length()==0) {

	    if (null==dt_date) {
        oMessages = new DBSubset (DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x", 
      				  "m." + DB.gu_msg + ",m." + DB.gu_product + ",m." + DB.nm_author + ",m." + DB.tx_subject + ",m." + DB.dt_published + ",m." + DB.id_status + ",m." + DB.tx_email,
      				  ((bIsAdmin || bIsModerator) ? "" : "(m.dt_expire>" + DBBind.Functions.GETDATE + " OR m.dt_expire IS NULL) AND (m." + DB.id_status + "=0 OR " + DB.gu_writer + "='" + gu_user + "') AND ") + (sStatus.length()>0 ? "m."+DB.id_status+"="+sStatus+" AND " : "") + "m." + DB.gu_msg + "=x." + DB.gu_object + " AND x." + DB.gu_category + "='" + gu_newsgroup + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy + " DESC": ""), iMaxRows);      				 
        oMessages.setMaxRows(iMaxRows);
        iMessageCount = oMessages.load (oConn, iSkip);
      } else {
        oMessages = new DBSubset (DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x", 
      				  "m." + DB.gu_msg + ",m." + DB.gu_product + ",m." + DB.nm_author + ",m." + DB.tx_subject + ",m." + DB.dt_published + ",m." + DB.id_status + ",m." + DB.tx_email,
      				  DBBind.Functions.ISNULL+"(m."+DB.dt_start+",m."+DB.dt_published+") BETWEEN ? AND ? AND (m." + DB.id_status + "=0 OR " + DB.gu_writer + "='" + gu_user + "') AND " + (sStatus.length()>0 ? "m."+DB.id_status+"="+sStatus+" AND " : "") + "m." + DB.gu_msg + "=x." + DB.gu_object + " AND x." + DB.gu_category + "='" + gu_newsgroup + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy + " DESC": ""), iMaxRows);      				 
        oMessages.setMaxRows(iMaxRows);
        Timestamp ts00Day = new Timestamp(new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), Integer.parseInt(dt_date), 0, 0, 0).getTime());
        Timestamp ts23Day = new Timestamp(new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), Integer.parseInt(dt_date), 23, 59, 59).getTime());
        iMessageCount = oMessages.load (oConn, new Object[]{ts00Day,ts23Day}, iSkip);      
      }
    }
    else {
      
	    if (null==dt_date) {
        aFind[0] = "%" + sFind + "%";
        oMessages = new DBSubset (DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x", 
      	  			"m." + DB.gu_msg + ",m." + DB.gu_product + ",m." + DB.nm_author + ",m." + DB.tx_subject + ",m." + DB.dt_published + ",m." + DB.id_status + ",m." + DB.tx_email,
      		  		"m." + sField + " " + DBBind.Functions.ILIKE + " ? AND " + (sStatus.length()>0 ? "m."+DB.id_status+"="+sStatus+" AND " : "") + "m." + DB.gu_msg + "=x." + DB.gu_object + " AND x." + DB.gu_category + "='" + gu_newsgroup + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy + " DESC": ""), iMaxRows);      				 
        oMessages.setMaxRows(iMaxRows);
        iMessageCount = oMessages.load (oConn, aFind, iSkip);
      } else {
        Timestamp ts00Day = new Timestamp(new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), Integer.parseInt(dt_date), 0, 0, 0).getTime());
        Timestamp ts23Day = new Timestamp(new Date(Integer.parseInt(dt_year)-1900, Integer.parseInt(dt_month), Integer.parseInt(dt_date), 23, 59, 59).getTime());
        aFind = new Object[]{"%"+sFind+"%", ts00Day, ts23Day};
        oMessages = new DBSubset (DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x", 
      	  			"m." + DB.gu_msg + ",m." + DB.gu_product + ",m." + DB.nm_author + ",m." + DB.tx_subject + ",m." + DB.dt_published + ",m." + DB.id_status + ",m." + DB.tx_email,
      		  		"m." + sField + " " + DBBind.Functions.ILIKE + " ? AND " +
      		  		DBBind.Functions.ISNULL+"(m."+DB.dt_start+",m."+DB.dt_published+") BETWEEN ? AND ? AND " +
      		  		(sStatus.length()>0 ? "m."+DB.id_status+"="+sStatus+" AND " : "") + "m." + DB.gu_msg + "=x." + DB.gu_object + " AND x." + DB.gu_category + "='" + gu_newsgroup + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy + " DESC": ""), iMaxRows);      				 
        oMessages.setMaxRows(iMaxRows);
        iMessageCount = oMessages.load (oConn, aFind, iSkip);      
      }
    }
    
    oConn.close("messagelisting"); 
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
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/dynapi/dynapi.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript">
    DynAPI.setLibraryPath('../javascript/dynapi/lib/');
    DynAPI.include('dynapi.api.*');
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript">
    var menuLayer;
    DynAPI.onLoad = function() { 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setHTML(rightMenuHTML);
    }
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/dynapi/rightmenu.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" DEFER="defer">
    <!--
        
        // [~//Variables globales para traspasar la instancia clickada al menu contextual~]
        var jsMessageId;
        var jsPrevMsgId = "";
                    
        <%
          // [~//Escribir los nombres de instancias en Arrays JavaScript~]
          // [~//Estos arrays se usan en las llamadas de borrado múltiple.~]
          
          out.write("var jsMessages = new Array(");
            for (int i=0; i<iMessageCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oMessages.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createMessage() {	  
	  // [~//Crear una nueva instancia del tipo de objeto listado~]
	  
	  window.open ("msg_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_newsgrp="+ getURLParam("gu_newsgrp") + "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&screen_width=" + String(screen.width), "editmessage", "directories=no,toolbar=no,menubar=no,width=<% out.write(String.valueOf(floor(760f*fScreenRatio))); %>,height=<% out.write(String.valueOf(floor(520f*fScreenRatio))); %>; %>");	  
	} // createMessage()

        // ----------------------------------------------------
        	
	function replyMessage(id) {	  
	  // [~//Crear una nueva instancia del tipo de objeto listado~]

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
	
	function moderateMessages() {
	  // [~//Cambiar el estado de los mensajes marcados con checkboxes~]
	  
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
	  window.open ("msg_read.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_newsgrp=<%=gu_newsgroup%>&nm_newsgrp=<%=nm_newsgrp%>&gu_msg=" + id, "readmessage" + id);
	}	

        // ----------------------------------------------------

	function readThread(id) {		  
	  window.open ("msg_thread.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_newsgrp=<%=gu_newsgroup%>&nm_newsgrp=<%=nm_newsgrp%>&gu_msg=" + id, "readthread" + id);
	}	

        // ----------------------------------------------------

	function sortBy(fld) {
	  // Ordenar por un campo
	  
	  window.location = "msg_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_newsgrp=" + getURLParam("gu_newsgrp") + "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>&status=<%=sStatus%>&screen_width=" + String(screen.width);
	}			

        // ----------------------------------------------------

	function filterBy() {
	  // Mostrar sólo los mensajes que estén en un estado determinado
	  var status = getCombo(document.forms[0].sel_status);
	  
	  window.location = "msg_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_newsgrp=" + getURLParam("gu_newsgrp") + "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&skip=0&orderby=<%=sOrderBy%>&field=<%=sField%>&find=<%=sFind%>&status=" + status + "&screen_width=" + String(screen.width);
	}			

        // ----------------------------------------------------

        function selectAll() {
          // [~//Seleccionar/Deseleccionar todas las instancias~]
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsMessages.length; c++)                        
            eval ("frm.elements['" + jsMessages[c] + "'].click()");
        } // selectAll()
       
       // ----------------------------------------------------
	
	     function findMessage(day) {
	  	  
	       var frm = document.forms[0];
	  
	       if (frm.sel_searched.options.selectedIndex<0 && day==0)
	         alert("Debe seleccionar un campo sobre el que realizar la búsqueda");	  
	       else if (getCombo(frm.sel_searched)=="" && day==0)
	         alert("Debe seleccionar un campo sobre el que realizar la búsqueda");
	       else
	         window.location = "msg_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_newsgrp=" + getURLParam("gu_newsgrp") + "&nm_newsgrp=" + getURLParam("nm_newsgrp") + "&skip=0&orderby=<%=sOrderBy%>" + (frm.find.value.length>0 ? "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) : "") + "&status=" + status + "&screen_width=" + String(screen.width) + (day==0 ? "" : "&dt_date=" + String(day)) + "&dt_month=<%=dt_month%>&dt_year=<%=dt_year%>";
	    } // findMessage()

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
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	  if (getURLParam("status")!=null)
	    setCombo(document.forms[0].sel_status, "<%=sStatus%>");	  
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	} // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Message Listing</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <FORM METHOD="post" TARGET="msgsexec" onSubmit="findMessage(0);return false">
      <TABLE><TR><TD WIDTH="100%" CLASS="striptitle"><FONT CLASS="title1"><% out.write(nm_newsgrp); %></FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="id_status">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="7" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD ALIGN="center"><IMG SRC="../images/images/refresh.gif" BORDER="0" ALT="Update"></TD>
        <TD VALIGN="middle" ALIGN="left"><A HREF="#" onClick="parent.frames['msgsexec'].document.location='../common/blank.htm';document.location.reload();"  CLASS="linkplain">Update</A></TD>
        <TD ALIGN="right" VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Write"></TD>
        <TD VALIGN="middle" ALIGN="left">
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Write</A>
<% } else { %>
          <A HREF="#" onclick="createMessage()" CLASS="linkplain">Write</A>
<% } %>
        </TD>
<% if (bIsAdmin) { %>
        <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD ALIGN="left">        
          <A HREF="#" onclick="deleteMessages()" CLASS="linkplain">Delete</A>
        </TD>
	<TD>
	  <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Messages&nbsp;</FONT>
	</TD>
<% } else { %>
	<TD COLSPAN="3">
	  <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Messages&nbsp;</FONT>
	</TD>
<% } %>
      </TR>
      <TR>
        <TD ALIGN="center" VALIGN="middle"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD COLSPAN="3" VALIGN="middle" CLASS="textplain">
          <SELECT CLASS="combomini" NAME="sel_searched"><OPTION VALUE="" SELECTED></OPTION><OPTION VALUE="<%=DB.nm_author%>">Author</OPTION><OPTION VALUE="<%=DB.tx_subject%>">Subject</OPTION></SELECT>
          &nbsp;<INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="100" SIZE="20" VALUE="<%=sFind%>">
	        &nbsp;<A HREF="javascript:findMessage(0);" CLASS="linkplain" TITLE="Buscar">Search</A>	  
        </TD>
        <TD ALIGN="right" VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></TD>
        <TD ALIGN="left" VALIGN="bottom">
          <A HREF="javascript:window.parent.document.location.reload(true);" CLASS="linkplain" TITLE="Discard Find Filter">Discard</A>
        </TD>
<% if ((bIsAdmin || bIsModerator) && bIsModerated) { %>
        <TD ALIGN="right"><IMG SRC="../images/images/megaphone22x16.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Filter">&nbsp;<SELECT NAME="sel_status" onChange="filterBy()" CLASS="combomini"><OPTION VALUE="" SELECTED>All<OPTION VALUE="0">Validated<OPTION VALUE="1">Pending<OPTION VALUE="2">Refused<OPTION VALUE="3">Outdated</SELECT></TD>
<% } else out.write("<TD></TD>"); %>
      </TR>      
<% if ((bIsAdmin || bIsModerator) && bIsModerated) { %>
      <TR><TD></TD><TD COLSPAN="6"><FONT CLASS="textplain"><INPUT TYPE="radio" NAME="aproval">&nbsp;Validate&nbsp;&nbsp;<INPUT TYPE="radio" NAME="aproval">&nbsp;Refuse</FONT>&nbsp;&nbsp;<A CLASS="linkplain" HREF="#" onClick="moderateMessages()">Change status</A></TR>
<% } %>
      <TR>
      	<TD COLSPAN="7" CLASS="textplain">
<%		    try {
				    out.write(Calendar.MonthName(Integer.parseInt(dt_month), sLanguage));
				  } catch (IllegalArgumentException ignore) { }
				  for (int d=1; d<=iLastDayOfMonth; d++) {
				    out.write("&nbsp;&nbsp;");
				    if ( ((Boolean)aDaysWithPosts.get(d-1)).booleanValue() )
				      out.write("<A HREF='javascript:findMessage("+String.valueOf(d)+");' CLASS=linkplain>"+String.valueOf(d)+"</A>");
				    else
				    	out.write(String.valueOf(d));
				  } // next
%>      	
      	</TD></TR>
      <TR><TD COLSPAN="7" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  if (iMessageCount>0) {
            if (iSkip>0) // [~//Si iSkip>0 entonces hay registros anteriores~]
              out.write("            <A HREF=\"msg_list.jsp?gu_newsgrp=" + gu_newsgroup + "&nm_newsgrp=" + Gadgets.URLEncode(nm_newsgrp) + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&screen_width=" + String.valueOf(iScreenWidth) + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oMessages.eof())
              out.write("            <A HREF=\"msg_list.jsp?gu_newsgrp=" + gu_newsgroup + "&nm_newsgrp=" + Gadgets.URLEncode(nm_newsgrp) + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&screen_width=" + String.valueOf(iScreenWidth) + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iMessageCount)
%>
          </TD>
        </TR>
        <TR>
<% if ((bIsAdmin  || bIsModerator) && bIsModerated) { %>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
<% } %>
          <TD CLASS="tableheader" WIDTH="<%=floor(180f*fScreenRatio)%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by Author"></A>&nbsp;<B>Author</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=floor(220f*fScreenRatio)%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by Subject"></A>&nbsp;<B>Subject</B></TD>
          <TD CLASS="tableheader" WIDTH="170px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by publishing date"></A>&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%
	  String sStripN;
	  String sMsgId,sAuthor,sSubject,sDtPub,sMail;
	  int iStatus;
	  boolean bAttachs;
	  for (int i=0; i<iMessageCount; i++) {
            sMsgId   = oMessages.getString(0,i);
            bAttachs = !oMessages.isNull(1,i);
            sAuthor  = oMessages.getStringNull(2,i,"");
            sSubject = oMessages.getStringNull(3,i,"");
            sDtPub = oMessages.getDateTime(4,i);
	    iStatus = (int) oMessages.getShort(5,i);
	    sMail = oMessages.getStringNull(6,i,"");
	    
            sStripN = "strip" + String.valueOf((i%2)+1);
	    
	    out.write("            <TR HEIGHT=\"14\">\n");
	    if ((bIsAdmin || bIsModerator) && bIsModerated)
	      out.write("            <TD CLASS=\"" + sStripN + "\"><IMG SRC =\"../images/images/forums/" + aStatusIcons[iStatus] + "\" BORDER=\"0\" ALT=\"" + aStatusAlt[iStatus] + "\" TITLE=\"" + aStatusAlt[iStatus] + "\"></TD>\n");
	    out.write("              <TD CLASS=\"" + sStripN + "\">&nbsp;" + sAuthor + "</TD>\n");
	    out.write("              <TD CLASS=\"" + sStripN + "\">&nbsp;<A HREF=\"#\" onClick=\"readMessage('"+sMsgId+"');return false\" TARGET=\"_blank\" oncontextmenu=\"jsMessageId='" + sMsgId+ "'; jsAuthorEMail='" + sMail + "'; return showRightMenu(event);\" onmouseover=\"top.status='Loading Message&nbsp;" +  sSubject + "'; jsMessageId='" + sMsgId + "'; intervalId=setInterval ('preview()', 1500); return true;\" onmouseout=\"top.status=''; clearInterval(intervalId); return true;\">" + sSubject + "</A></TD>\n");
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
      addMenuOption("Reply to All","replyMessage(jsMessageId)",0);
    </SCRIPT>
</BODY>
</HTML>