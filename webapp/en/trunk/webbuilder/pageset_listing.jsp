<%@ page import="java.util.Date,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  final int MailwireApp=13;
  final int WebBuilderApp=14;
  final int HipermailApp=21;
  final int SurveysApp=23;

  String sLanguage = getNavigatorLanguage(request);

  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String sDocType = nullif(request.getParameter("doctype"),"newsletter");
  
  String sDocTypeFilter;
  if (sDocType.equals("newsletter"))
     sDocTypeFilter = "(p." + DB.id_app + "=" + String.valueOf(MailwireApp) + " OR " + DB.id_app + "=" + String.valueOf(HipermailApp) + ") AND ";
  else if (sDocType.equals("survey"))
     sDocTypeFilter = "p." + DB.id_app + "=" + String.valueOf(SurveysApp) + " AND ";
  else
     sDocTypeFilter = "p." + DB.id_app + "=" + String.valueOf(WebBuilderApp) + " AND ";

  String sLangFilter = nullif(request.getParameter("id_language")).length()==0 ? "" : "(p."+DB.id_language+"='"+request.getParameter("id_language")+"' OR p.id_app="+String.valueOf(HipermailApp)+") AND ";
    
  String sFind = "";
    
  if (nullif(request.getParameter("find")).length()>0)
    sFind += " AND (p." + DB.nm_pageset + " " + DBBind.Functions.ILIKE + " '%" + request.getParameter("find") + "%' OR p." + DB.tx_comments + " " + DBBind.Functions.ILIKE + " '%" + request.getParameter("find") + "%')";

  if (nullif(request.getParameter("dt_start")).length()>0)
    sFind += " AND p." + DB.dt_created + "<={ d '" + request.getParameter("dt_start") + "'} ";
  
  if (nullif(request.getParameter("dt_end")).length()>0)
    sFind += " AND p." + DB.dt_created + ">={ d '" + request.getParameter("dt_end") + "'} ";

  String sStorageRoot = Environment.getProfilePath(GlobalDBBind.getProfileName(),"storage");
  
  int iPageSetCount = 0;
  DBSubset oPageSets = null;
  int nReminders = 0;
  DBSubset oReminders = new DBSubset(DB.k_adhoc_mailings+" m,"+DB.k_activities+" a",
                                     "a."+DB.gu_activity+",a."+DB.dt_start+",a."+DB.tl_activity+",m."+DB.gu_mailing+",m."+DB.pg_mailing+",m."+DB.nm_mailing,
                                     "a."+DB.gu_mailing+"=m."+DB.gu_mailing+" AND a."+DB.gu_workarea+"=? AND m.bo_reminder=1 AND "+
                                     "a."+DB.dt_start+" BETWEEN CURRENT_TIMESTAMP-interval '2 days' AND CURRENT_TIMESTAMP", 10);
  DBSubset oLanguages = new DBSubset(DB.k_lu_languages+" l",
  											"l."+DB.id_language+","+(GlobalDBBind.getDBTable(DB.k_lu_languages).getColumnByName(DB.tr_lang_+sLanguage)==null ? "l."+DB.tr_lang_en : DBBind.Functions.ISNULL+"(l."+DB.tr_lang_+sLanguage+",l."+DB.tr_lang_en+")"),
                        "EXISTS (SELECT NULL FROM "+DB.k_pagesets+" p WHERE p."+DB.gu_workarea+"=? AND p."+DB.id_language+"=l."+DB.id_language+") ORDER BY 2", 50);
  int iLangsCount = 0;
  Object[] aFind = { '%' + sFind + '%' };
  int iMaxRows;
  int iSkip;
  String sOrderBy;
  int iOrderBy;
  boolean bShowSendColumn = false;

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "5 DESC";
  
  if ((sOrderBy.length()>0) && (sOrderBy.length()<3))
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 5;
    
  if (request.getParameter("maxrows")!=null)
    iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
  else
    iMaxRows = 100;

  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (iSkip<0) iSkip = 0;

  JDCConnection oConn = GlobalDBBind.getConnection("pageset_listing");  
  String aStatus[];
   
  try {
  
    iLangsCount = oLanguages.load(oConn, new Object[]{gu_workarea});
    
    if (sFind.length()==0) {
      oPageSets = new DBSubset ("v_pagesets_mailings p ", 
      				"p." + DB.gu_pageset + ",p." + DB.nm_pageset + ",p." + DB.tx_comments + ",p." + DB.path_data + ",p." + DB.dt_created + ",p." + DB.nm_microsite + ",p." + DB.id_status + ",p." + DB.id_app + ",p." + DB.bo_urgent + ",p." + DB.dt_execution,
      				sDocTypeFilter + sLangFilter + "p.gu_workarea='" + gu_workarea + "' ORDER BY " + sOrderBy, iMaxRows);
      oPageSets.setMaxRows(iMaxRows);
      iPageSetCount = oPageSets.load (oConn, iSkip);
    }
    else {
      oPageSets = new DBSubset ("v_pagesets_mailings p", 
      				"p." + DB.gu_pageset + ",p." + DB.nm_pageset + ",p." + DB.tx_comments + ",p." + DB.path_data + ",p." + DB.dt_created + ",p." + DB.nm_microsite + ",p." + DB.id_status + ",p." + DB.id_app + ",p." + DB.bo_urgent + ",p." + DB.dt_execution,
      				sDocTypeFilter + sLangFilter + "p.gu_workarea='" + gu_workarea + "' " + sFind + " ORDER BY " + sOrderBy, iMaxRows);
      oPageSets.setMaxRows(iMaxRows);
      iPageSetCount = oPageSets.load (oConn, iSkip);    
    }
    
    aStatus = new String[iPageSetCount];
    
    for (int ps=0; ps<iPageSetCount; ps++) {
      if (oPageSets.isNull(6,ps))
        aStatus[ps] = "";
      else if (oPageSets.getInt(7,ps)==HipermailApp)
        aStatus[ps] = DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_adhoc_mailings_lookup, gu_workarea , "id_status", sLanguage, oPageSets.getString(6,ps));
      else
        aStatus[ps] = DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_pagesets_lookup, gu_workarea , "id_status", sLanguage, oPageSets.getString(6,ps));
      if (!oPageSets.isNull(9,ps)) bShowSendColumn = true;
    } // next
    
    // nReminders = oReminders.load(oConn, new Object[]{gu_workarea});
    
    oConn.close("pageset_listing"); 
  }
  catch (SQLException e) {  
    oPageSets = null;
    if (null!=oConn)
      if (!oConn.isClosed())
        oConn.close("pageset_listing");

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));
    return;
  }
  oConn = null;

  sendUsageStats(request, "pageset_listing");  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>

  <SCRIPT TYPE="text/javascript">
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');

    var menuLayer;
    
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
    	var jsPageSetId;
    	var jsPageSetName;
    	var jsType;
    	
        <%
          // Escribir los nombres de PageSets en Arrays JavaScript
          // Estos arrays se usan en las llamadas de borrado multiple.
          
          out.write("var jsPageSets = new Array(");
            for (int i=0; i<iPageSetCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oPageSets.getString(0,i) + "\"");
            }
          out.write(");\n        ");

          out.write("var jsTypes = new Array(");
            for (int i=0; i<iPageSetCount; i++) {
              if (i>0) out.write(","); 
              out.write(String.valueOf(oPageSets.getInt(7,i)));
            }
          out.write(");\n        ");

        %>
	// ----------------------------------------------------

        function showCalendar(ctrl) {       
          var dtnw = new Date();

          window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
        } // showCalendar()
      
	// ----------------------------------------------------
	
	function findRecords() {
	  var frm = document.forms[0];
	  var qry = "";
	  var txt;
	  
	  txt = rtrim(frm.find.value);
	  if (txt.indexOf("'")>=0 || txt.indexOf("%")>=0  || txt.indexOf(",")>=0  || txt.indexOf("&")>=0  || txt.indexOf("?")>=0 ) {
	    alert ("Search string contains invalid characters");
	    document.location = "pageset_listing.jsp?doctype="+ getURLParam("doctype") + "&id_language=" + getCombo(frm.id_language) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	    return false;
	  }
	  
	  if (txt.length>0)
	    qry += "&find=" + escape(txt);
	    
	  if (txt.length==0 && frm.dt_start.value.length==0 && frm.dt_end.value.length==0 && frm.id_language.selectedIndex<=0) {
	    alert ("Must specify a search criteria");
	    document.location = "pageset_listing.jsp?doctype="+ getURLParam("doctype") + "&id_language=" + getCombo(frm.id_language) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	    return false;
	  }
	  	  
	  txt = frm.dt_start.value;
	  if (txt.length>0)
	    if (isDate(txt,"d"))
	      qry += "&dt_start=" + txt;
	    else {
	      alert ("Invalid Start Date");
	      document.location = "pageset_listing.jsp?doctype="+ getURLParam("doctype") + "&id_language=" + getCombo(frm.id_language) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	      return false;
	    }
	    
	  txt = frm.dt_end.value;
	  if (txt.length>0)
	    if (isDate(txt,"d"))
	      qry += "&dt_end=" + txt;
	    else {
	      alert ("Invalid End Date");
	      document.location = "pageset_listing.jsp?doctype="+ getURLParam("doctype") + "&id_language=" + getCombo(frm.id_language) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	      return false;
	    }
		    	  
	  document.location = "pageset_listing.jsp?doctype=<%=sDocType%>&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + (getURLParam("orderby")!=null ? "&orderby="+request.getParameter("orderby") : "") + qry + "&id_language=" + getCombo(frm.id_language) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&maxrows=<%=iMaxRows%>&skip=<%=iSkip%>";
	} // findRecords

	// ----------------------------------------------------
	
	function clonePageSet(id,tp) {
	  document.location = "pageset_clone.jsp?id_app=" + tp + "&gu_pageset=" + id + "&doctype=<%=sDocType%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	}
	
	// ----------------------------------------------------
	
	function sortBy(fld) {
	  document.location = "pageset_listing.jsp?doctype=<%=sDocType%>&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&orderby=" + String(fld) + (fld==5 ? " DESC" : "") + "&find=<%=sFind%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&maxrows=<%=iMaxRows%>&skip=<%=iSkip%>";
	}

        // ----------------------------------------------------
        	
	function createPageSet() {
	    self.open("microsite_lookup_f.jsp?doctype=<%=sDocType%>&gu_workarea=<%=gu_workarea%>&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&nm_table=k_microsites&doctype=<%=sDocType%>&id_language=<%=sLanguage%>&id_section=id_sector&tp_control=1&nm_control=gu_microsite&nm_coding=id_sector", "createpageset", "toolbar=no,directories=no,menubar=no,resizable=no,top=" + (screen.height-520)/2 + ",left=" + (screen.width-540)/2 + ",width=600,height=520");	  
	} // createPageSet()

        // ----------------------------------------------------
        	
	function changePageSet(jsPageSetId,jsPageSetType) {
		if (jsPageSetType==<% out.write(String.valueOf(HipermailApp)); %>)
	    self.open ("adhoc_mailing_edit.jsp?gu_mailing=" + jsPageSetId + "&gu_workarea=<%=gu_workarea%>&id_domain=<%=id_domain%>", "editpagesetproperties", "scrollbars=yes,directories=no,toolbar=no,menubar=no,top=" + (screen.height-500)/2 + ",left=" + (screen.width-720)/2 + ",width=720,height=500");	  
	  else
	    self.open("pageset_change.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&doctype=<%=sDocType%>&gu_pageset=" + jsPageSetId, "changepageset", "toolbar=no,directories=no,menubar=no,scrollbars=yes,resizable=yes,top=" + (screen.height-520)/2 + ",left=" + (screen.width-540)/2 + ",width=600,height=520");	  
	} // createPageSet()

        // ----------------------------------------------------

	function editProperties(jsPageSetId,jsPageSetType) {
	    self.open ("pageset_edit.jsp?gu_pageset=" + jsPageSetId + "&gu_workarea=<%=gu_workarea%>&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>"), "editpagesetproperties", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-320)/2 + ",left=" + (screen.width-400)/2 + ",width=400,height=320");	  
	} // editProperties()

        // ----------------------------------------------------

	function modifyPageSet(id,nm,tp) {
	  var w,h;
	  
	  switch (screen.width) {
	    case 640:
	      w="620";
	      h="460";
	      break;
	    case 800:
	      w="740";
	      h="560";
	      break;
	    case 1024:
	      w="960";
	      h="700";
	      break;
	    case 1152:
	      w="1024";
	      h="768";
	      break;
	    case 1280:
	      w="1152";
	      h="960";
	      break;
	    default:
	      w="740";
	      h="560";
	  }
    	  
		if (tp==<% out.write(String.valueOf(HipermailApp)); %>)
	    window.open ("wb_file_upload.jsp?gu_microsite=adhoc&gu_pageset="+id+"&doctype=<%=sDocType%>", "editPageSet", "directories=no,toolbar=no,menubar=no,status=yes,resizable=yes,width=500,height=400");
	  else
	    window.open ("wb_document.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=" + id + "&doctype=<%=sDocType%>", "editPageSet", "top=" + (screen.height-parseInt(h))/2 + ",left=" + (screen.width-parseInt(w))/2 + ",scrollbars=yes,directories=no,toolbar=no,menubar=no,status=yes,resizable=yes,width=" + w + ",height=" + h);
	} // modifyPageSet

        // ----------------------------------------------------

	function previewPageSet(id,nm,tp) {
	  var w,h;
	  
	  switch (screen.width) {
	    case 640:
	      w="620";
	      h="460";
	      break;
	    case 800:
	      w="740";
	      h="560";
	      break;
	    case 1024:
	      w="960";
	      h="700";
	      break;
	    case 1152:
	      w="1024";
	      h="768";
	      break;
	    case 1280:
	      w="1152";
	      h="960";
	      break;
	    default:
	      w="740";
	      h="560";
	  }
	  	    	      	    	  
		if (tp==<% out.write(String.valueOf(HipermailApp)); %>)
	    window.open ("adhoc_mailing_preview.jsp?gu_mailing="+id+"&gu_workarea=<%=gu_workarea%>", "previewPageSet", "top=" + (screen.height-parseInt(h))/2 + ",left=" + (screen.width-parseInt(w))/2 + ",scrollbars=yes,directories=no,toolbar=no,menubar=yes,width=" + w + ",height=" + h);
	  else
	    window.open ("wb_preview.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=" + id + "&doctype=<%=sDocType%>", "previewPageSet", "top=" + (screen.height-parseInt(h))/2 + ",left=" + (screen.width-parseInt(w))/2 + ",scrollbars=yes,directories=no,toolbar=no,menubar=yes,width=" + w + ",height=" + h);
	} // modifyPageSet

  // ----------------------------------------------------

  function listJobs(gu_pageset,nm_pageset,tp_doc) {
	  document.location = "../jobs/job_list.jsp?id_domain=<%=id_domain%>&viewonly=2&selected=5&subselected=2&id_command="+(tp_doc==<%=String.valueOf(HipermailApp)%> ? "SEND" : "MAIL")+"&list_title="+escape(nm_pageset)+"&filter="+escape(" AND gu_job_group='"+gu_pageset+"'");
	} // listJobs

  // ----------------------------------------------------

  function listStats(gu_pageset) {
	  document.location = "../jobs/job_followup_stats_xls.jsp?gu_job_group="+gu_pageset;
	} // listStats

  // ----------------------------------------------------

	function selectList(gu_pageset,tp_doc) {
	  var wEnvio = window.open("list_choose.jsp?gu_pageset=" +gu_pageset+"&id_command="+(tp_doc==<%=String.valueOf(HipermailApp)%> ? "SEND" : "MAIL"),"wEnvio","top=" + (screen.height-500)/2 + ",left=" + (screen.width-640)/2 + ",height=500,width=640,scrollbars=yes");
	} // selectList

  // ----------------------------------------------------
	
	function schedule()
	{
	  var i;
	  var counter=0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  var tp;
	  
	  var offset = 0;
          while (frm.elements[offset].type!="checkbox") offset++;
	  
	        for (i=0;i<jsPageSets.length; i++){
            if (frm.elements[offset].checked) {              
              counter++;
              chi.value = frm.elements[offset].name;
              tp = jsTypes[i];
            }
            offset++;
          } // next (i)
                    
          if (counter==0){
           alert("You must select at least one document");
           return (false);
          }
          
          if (counter>1){
           alert("You must select only one document");
           return (false);
          }
	  	  
	  var wEnvio = window.open("list_choose.jsp?gu_pageset="+chi.value+"&id_command="+(tp==<%=String.valueOf(HipermailApp)%> ? "SEND" : "MAIL"),"wEnvio","top=" + (screen.height-500)/2 + ",left=" + (screen.width-640)/2 + ",height=500,width=640,scrollbars=yes");
	} // schedule
	
        // ----------------------------------------------------

	function deletePageSets() {
	  var i;
	  var c;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  var offset = 0;
	  
	  c = 0;
	  
	  chi.value = "";
	  
	  while (frm.elements[offset].type!="checkbox") offset++;
	  	  
	  for (i=0; i<jsPageSets.length; i++){	    
            if (frm.elements[offset].checked) {
              c++;
              chi.value += jsPageSets[i] + ",";
            } // fi ()
            offset++;
          } // next
	  
	  if (chi.value.length>0) {
	    if (window.confirm("You are about to delete " + String(c) + "  documents. Are you sure you wish to continue?")) {	    
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.action = "pageset_edit_delete.jsp";
              frm.submit();
              return true;
            }
          } 
          else {
            alert('You must select at least one document');
          } // fi()
	} // deletePageSets()

        // ----------------------------------------------------

	function publish() {
	  var i;
	  var c;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  var offset = 0;
	  
	  c = 0;
	  
	  chi.value = "";
	  
	  while (frm.elements[offset].type!="checkbox") offset++;
	  	  
	  for (i=0; i<jsPageSets.length; i++){	    
            if (frm.elements[offset].checked) {
              c++;
              chi.value += jsPageSets[i] + ",";
            } // fi ()
            offset++;
          } // next
	  
	  if (chi.value.length>0) {
	    if (window.confirm("You are about to publish " + String(c) + "  documents. Are you sure you wish to continue?")) {	    
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.action = "pageset_edit_publish.jsp";
              frm.submit();
              return true;
            }
          } 
          else {
            alert('You must select at least one document');
          } // fi()
	} // publish()
	
        // ----------------------------------------------------

    //-->    
  </SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
	function setCombos() {
	  var frm = document.forms[0];

	  if (getURLParam("find")!=null)
	    frm.find.value = getURLParam("find");

	  if (getURLParam("dt_start")!=null)
	    frm.dt_start.value = getURLParam("dt_start");

	  if (getURLParam("dt_end")!=null)
	    frm.dt_end.value = getURLParam("dt_end");

	  if (getURLParam("id_language")!=null)
	    setCombo(frm.id_language,getURLParam("id_language"));
	}
	
    //-->    
  </SCRIPT>  
<%
  String sTitle = "";
  
  if (sDocType.equals("newsletter"))
    sTitle="Newsletters";
  else if (sDocType.equals("survey"))
    sTitle="Questionnaires";  
  else
   sTitle = "WebSites";
  
%>
  <TITLE>hipergate :: Edit &nbsp;<%=sTitle%></TITLE>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post" NAME="frmPageset" ID="frmPageset">
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
    <TABLE SUMMARY="Title" CELLSPACING="0" CELLPADDING="0" BORDER="0" WIDTH="99%"><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Edit &nbsp;<%=sTitle%></FONT></TD></TR></TABLE>
    <TABLE SUMMARY="New & Delete" CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="<% if (sDocType.equals("newsletter")) out.write("8"); else out.write("6");%>" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
        <TD ALIGN="right" HEIGHT="16">&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD ALIGN="left" VALIGN="middle"><A HREF="javascript:void(0)" onclick="createPageSet()" CLASS="linkplain">New</A></TD>
        <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD ALIGN="left" HEIGHT="16"><A HREF="javascript:deletePageSets()" CLASS="linkplain">Delete</A></TD>
        <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/copyfiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Publish"></TD>
        <TD ALIGN="left" HEIGHT="16"><A HREF="javascript:void(0)" onclick="publish();return false;" CLASS="linkplain">Publish</A></TD>
<% if (sDocType.equals("newsletter")) { %>
        <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/jobs/sandclock.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Schedule"></TD>
        <TD ALIGN="left" HEIGHT="16"><A HREF="javascript:void(0)" onclick="schedule();return false;" CLASS="linkplain">Schedule</A></TD>
<% } %>
      </TR>
      <TR><TD COLSPAN="<% if (sDocType.equals("newsletter")) out.write("8"); else out.write("6");%>" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>      
      <TR>
        <TD COLSPAN="<% if (sDocType.equals("newsletter")) out.write("8"); else out.write("6");%>">
	        <IMG SRC="../images/images/find16.gif" BORDER="0" ALT="Search">&nbsp;<FONT CLASS="textplain"><INPUT CLASS="combomini" TYPE="text" MAXLENGTH="30" NAME="find">&nbsp;&nbsp;between&nbsp;<INPUT TYPE="text" CLASS="combomini" MAXLENGTH="10" SIZE="10" NAME="dt_start">&nbsp;<A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>&nbsp;&nbsp;and&nbsp;&nbsp;<INPUT CLASS="combomini" TYPE="text" MAXLENGTH="10" SIZE="10" NAME="dt_end">&nbsp;<A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>&nbsp;</FONT>
	        &nbsp;&nbsp;<FONT CLASS="textplain">Language</FONT>&nbsp;<SELECT NAME="id_language" CLASS="combomini"><OPTION VALUE=""></OPTION><% for (int l=0; l<iLangsCount; l++) out.write("<OPTION VALUE=\""+oLanguages.getString(0,l)+"\">"+oLanguages.getString(1,l)+"</OPTION>"); %></SELECT>
	        &nbsp;&nbsp;<A HREF="javascript:findRecords()" CLASS="linkplain">Search</A>
        </TD>
      <TR>
        <TD COLSPAN="<% if (sDocType.equals("newsletter")) out.write("8"); else out.write("6");%>">
          <FONT CLASS="textplain"><B>View</B>&nbsp;<INPUT TYPE="radio" NAME="chk_doctype" <% if (sDocType.equals("newsletter")) out.write("CHECKED"); else out.write("onClick=\"window.document.location.href='pageset_listing.jsp?selected=' + getURLParam('selected') + '&subselected=' + getURLParam('subselected') + '&doctype=newsletter'\""); %>>Newsletters&nbsp;&nbsp;<INPUT TYPE="radio" NAME="chk_doctype" <% if (sDocType.equals("website")) out.write("CHECKED"); else out.write("onClick=\"window.document.location.href='pageset_listing.jsp?selected=' + getURLParam('selected') + '&subselected=' + getURLParam('subselected') + '&doctype=website'\""); %>>WebSites&nbsp;&nbsp;<INPUT TYPE="radio" NAME="chk_doctype" <% if (sDocType.equals("survey")) out.write("CHECKED"); else out.write("onClick=\"window.document.location.href='pageset_listing.jsp?selected=' + getURLParam('selected') + '&subselected=' + getURLParam('subselected') + '&doctype=survey'\""); %>>Questionnaires</FONT>
        </TD>
      <TR>
    </TABLE>
    <%

	  if (nReminders>0) {
      out.write("<FONT CLASS=\"textstrong\">Reminders</FONT><BR/>");
      for (int r=0; r<nReminders; r++) {      
        out.write("<FONT CLASS=\"textplain\">"+String.valueOf(oReminders.getInt(4,r))+"&nbsp;("+oReminders.getStringNull(5,r,"")+")&nbsp;"+oReminders.getDateTime24(1,r)+"&nbsp;"+oReminders.getStringNull(2,r,"n/a")+"</FONT><BR/>");
      }
    }

    // Pintar los enlaces de siguiente y anterior
    
    String sTabIndicators = "selected=5&subselected=0&";

    if (iSkip>0) // Si iSkip>0 entonces hay registros anteriores
      out.write("<A HREF=\"pageset_listing.jsp?" + sTabIndicators + "doctype=" + sDocType + "&id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip-iMaxRows)+ "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;" + String.valueOf(iMaxRows) + "&nbsp;Previous " + "</A>&nbsp;&nbsp;&nbsp;");
    
    if (!oPageSets.eof())
      out.write("<A HREF=\"pageset_listing.jsp?" + sTabIndicators + "doctype=" + sDocType + "&id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip+iMaxRows)+ "\" CLASS=\"linkplain\">Next " + String.valueOf(iMaxRows) + "&nbsp;&gt;&gt;</A>");
    %>

    <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR>
         <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="200px"><A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;&nbsp;<B>Name</B></TD>
         <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="300px"><A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>&nbsp;Description</B></TD>
         <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="96px"><A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>&nbsp;Create</B></TD>
<% if (bShowSendColumn) { %>
         <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="96px"><A HREF="javascript:sortBy(10);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==10 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>&nbsp;Sent</B></TD>
<% } %>
         <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="100px">&nbsp;<B>&nbsp;Status</B></TD>
         <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
        </TR>
<%
	  String sCompId;
	  String sTdClass;
    boolean bUrgent;

	  for (int i=0; i<iPageSetCount; i++) {

            // Recupero la ruta al archivo
            String sPathData = sStorageRoot + oPageSets.getStringNull(3,i,"");
            int matchdoctype = -1;
            // Si estoy listando monopagina
            if (sDocType.equals("newsletter"))
              // Si en la ruta aparece Mailwire es Newsletter
              matchdoctype = (sPathData.indexOf("Mailwire")>=0 || sPathData.indexOf("Hipermail")>=0 ? 0 : -1);
            else // Si estoy listando multipagina
              // Si en la ruta aparece WebBuilder es multipagina
              matchdoctype = sPathData.indexOf("WebBuilder");
            
						if (oPageSets.isNull(8,i)) {
						  bUrgent = false;
						} else {
						  bUrgent = (oPageSets.getShort(8,i)!=0);
						}
						
						if (!bUrgent) {
						  if (!oPageSets.isNull(9,i)) {
						    Date dtToday = new Date();
						    dtToday.setHours(23);
						    dtToday.setMinutes(59);
						    dtToday.setSeconds(59);
						    bUrgent = (oPageSets.getDate(9,i).compareTo(dtToday)<=0);
						  }
						}
            
            if (oPageSets.getStringNull(6,i,"").equals("ENVIADO")) bUrgent = false;
            
            // Si el registro corresponde a un documento que estoy listando
            if (matchdoctype!=-1)
            {
             int counter = (i%2)+1;
             sCompId = oPageSets.getString(0,i);
             sTdClass = bUrgent ? "CLASS=\"stripr\"" : "CLASS=\"strip" + counter + "\"";
             out.write ("<TR HEIGHT=\"14\">");
             out.write ("<TD "+sTdClass+">");
             out.write ("&nbsp;<A HREF=\"#\" oncontextmenu=\"jsPageSetId='" + sCompId + "'; jsPageSetName = '" + oPageSets.getString(1,i) + "'; jsType = " + String.valueOf(oPageSets.getInt(7,i)) + "; return showRightMenu(event);\" onclick=\""+ (oPageSets.getInt(7,i)==HipermailApp ? "changePageSet('"+sCompId+"','"+String.valueOf(HipermailApp)+"')" : "modifyPageSet('"+sCompId+"','"+oPageSets.getString(1,i)+"', "+String.valueOf(oPageSets.getInt(7,i))+")") + "\" TITLE=\"Right click to see context menu\">");
             out.write (oPageSets.getString(1,i));
             out.write ("</A>");
             out.write ("</TD>");
             out.write ("<TD "+sTdClass+">");
             out.write ("&nbsp;" + Gadgets.left(oPageSets.getStringNull(2,i,""), 60));
             out.write ("</TD>");
             out.write ("<TD ALIGN=\"middle\" "+sTdClass+">");
             out.write ("&nbsp;" + oPageSets.getDateShort(4,i));
             out.write ("</TD>");
             if (bShowSendColumn) {
               out.write ("<TD ALIGN=\"middle\" "+sTdClass+">");
               if (!oPageSets.isNull(9,i))
                 out.write ("&nbsp;" + oPageSets.getDateShort(9,i));
               out.write ("</TD>");
             }
             out.write ("<TD "+sTdClass+">");
             out.write ("&nbsp;" + nullif(aStatus[i]));
             out.write ("</TD>");
             out.write ("<TD "+sTdClass+" ALIGN=\"center\">");
             out.write ("<INPUT VALUE=\"1\" TYPE=\"checkbox\" NAME=\"" + sCompId + "\">");
             out.write ("</TD>");
             out.write ("</TR>\n");
            }
          }
	%>          	  
      </TABLE>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="checkeditems" VALUE="">
      <INPUT TYPE="hidden" NAME="doctype" VALUE="<%=sDocType%>">
    </FORM>

    <SCRIPT language="JavaScript" type="text/javascript">
      addMenuOption("Edit","modifyPageSet(jsPageSetId,jsPageSetName,jsType)",1);
      addMenuOption("Preview","previewPageSet(jsPageSetId,jsPageSetName,jsType)",0);
      addMenuOption("Properties","changePageSet(jsPageSetId,jsType)",0);
      addMenuOption("Clone","clonePageSet(jsPageSetId,jsType)",0);
      <% if (sDocType.equals("newsletter")) { %>
      addMenuSeparator();
      addMenuOption("Schedule","selectList(jsPageSetId,jsType)",0);
      addMenuOption("Show Sent Messages","listJobs(jsPageSetId,jsPageSetName,jsType)",0);
      addMenuOption("Show Statistics","listStats(jsPageSetId)",0);
      
      <% } %>
    </SCRIPT>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>