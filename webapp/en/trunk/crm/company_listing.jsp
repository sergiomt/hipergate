<%@ page import="java.util.HashMap,java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.QueryByForm,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
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

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  
  int iScreenWidth;
  float fScreenRatio;
    
  String gu_user = getCookie (request, "userid", null);
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 
  String screen_width = request.getParameter("screen_width");

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;
  
        
  String sField = nullif(request.getParameter("field"));
  String sFind = nullif(request.getParameter("find"));
  String sWhere = nullif(request.getParameter("where"));
  String sQuery = nullif(request.getParameter("query"));
  String sSecurityFilter;
      
  int iCompanyCount = 0;
  DBSubset oCompanies = null;
  HashMap oStatusMap = null;
  DBSubset oQueries = null;
  int iQueries = 0;
  QueryByForm oQBF;
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  try {    
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "100"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }
   
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (iSkip<0) iSkip = 0;
  
  if (nullif(request.getParameter("orderby")).length()>0)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "0";   
  
  iOrderBy = Integer.parseInt(sOrderBy);
     
  JDCConnection oConn = null;  
  
  boolean bIsGuest = true;
  boolean bIsAdmin = false;
    
  try {
    
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
        
    oConn = GlobalDBBind.getConnection("companylisting");

    if (bIsAdmin) {
      sSecurityFilter = "";
    } else {
    	String sUserGroups = GlobalCacheClient.getString("["+gu_user+",groups]");
	    if (null==sUserGroups) {
	      ACLUser oUser = new ACLUser(gu_user);
	      DBSubset oUserGroups = oUser.getGroups(oConn);
	      oUserGroups.setRowDelimiter("','");
	      sUserGroups = "'" + Gadgets.dechomp(oUserGroups.toString(),"','") + "'";
	      GlobalCacheClient.put("["+gu_user+",groups]", sUserGroups);
	    }
    	sSecurityFilter = " AND (b.bo_restricted=0 OR EXISTS (SELECT x."+DB.gu_acl_group+" FROM "+DB.k_x_group_company+" x WHERE x."+DB.gu_company+"=b."+DB.gu_company+" AND x."+DB.gu_acl_group+" IN ("+sUserGroups+"))) ";
    }

    oQueries = GlobalCacheClient.getDBSubset("k_queries.companies[" + gu_workarea + "]");
    
    if (null==oQueries) {
      oQueries = new DBSubset(DB.k_queries, DB.gu_query + "," + DB.tl_query, DB.gu_workarea + "='" + gu_workarea + "' AND " + DB.nm_queryspec + "='companies'", 10);
      oQueries.load (oConn);
      
      GlobalCacheClient.putDBSubset("k_queries" , "k_queries.companies[" + gu_workarea + "]", oQueries);
    }
    iQueries = oQueries.getRowCount();
    
    if (sQuery.length()>0 && sWhere.length()==0) {
      oQBF = new QueryByForm (oConn, DB.v_company_address, "b", sQuery);
      
      sWhere = " AND (" + oQBF.composeSQL() + ")";
      
      oQBF = null;
    }
        
    if (sWhere.length()>0) {
      
      	oCompanies = new DBSubset (DB.v_company_address + " b", 
      				 "b." + DB.gu_company + "," + "b." + DB.nm_legal + "," + DBBind.Functions.ISNULL + "(" + "b." + DB.de_company + ",'')," + "b." + DB.id_sector + "," + "b." + DB.id_legal + "," + "b." + DB.id_status,
      				 "b." + DB.gu_workarea + "='" + gu_workarea + "' " + sWhere + sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oCompanies.setMaxRows(iMaxRows);
      iCompanyCount = oCompanies.load (oConn, iSkip);
    }
    else if (sFind.length()==0 || sField.length()==0) {
     
    	oCompanies = new DBSubset (DB.k_companies + " b, "+DB.k_companies_recent+" r",
      				 "b."+DB.gu_company + ",b." + DB.nm_legal + "," + DBBind.Functions.ISNULL + "(b." + DB.de_company + ",''),b." + DB.id_sector + ",b." + DB.id_legal + ",b." + DB.id_status,
      				 "b."+DB.gu_workarea + "=? AND " +
	      			 "b."+DB.gu_company+"=r."+DB.gu_company+" AND r."+DB.gu_user+"=? "+
      				 sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oCompanies.setMaxRows(iMaxRows);
      iCompanyCount = oCompanies.load (oConn, new Object[]{gu_workarea,gu_user}, iSkip);
    }
    else {
      
      oCompanies = new DBSubset (DB.k_companies + " b", 
      				 DB.gu_company + "," + DB.nm_legal + "," + DBBind.Functions.ISNULL + "(" + DB.de_company + ",'')," + DB.id_sector + "," + DB.id_legal + "," + DB.id_status,
      				 DB.gu_workarea + "='" + gu_workarea + "' AND " + sField + " " + DBBind.Functions.ILIKE + " ? " + sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      oCompanies.setMaxRows(iMaxRows);
      Object[] aFind = { "%" + sFind + "%" };
      iCompanyCount = oCompanies.load(oConn,aFind,iSkip);
    }
    
    oStatusMap = GlobalDBLang.getLookUpMap((Connection) oConn, DB.k_companies_lookup, gu_workarea, "id_status", sLanguage);

    oConn.close("companylisting");
    
    sendUsageStats(request, "company_listing");
  }
  catch (SQLException e) {  
    oCompanies = null;
    oConn.close("companylisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML>
<HEAD>
  <TITLE>hipergate :: Company Listing</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');

    var menuLayer,addrLayer;
    dynapi.onLoad(init);
    function init() {
 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setVisible(true);
      menuLayer.setHTML(rightMenuHTML);
      
      addrLayer = new DynLayer();
      addrLayer.setWidth(200);
      addrLayer.setHeight(150);
      addrLayer.setZIndex(200);
    }
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        var jsCompanyId;
        var jsCompanyNm;
        
        <%
          
          out.write("var jsCompanies = new Array(");
            for (int i=0; i<iCompanyCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oCompanies.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createCompany() {	  
	  self.open ("company_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "createcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=660,height=660");	  
	} // createCompany()

        // ----------------------------------------------------

	function deleteCompanies() {
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;	 

	  if (window.confirm("Are you sure you want to delete selected companies?")) {
	  
	    chi.value = "";
            frm.action = "company_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  
	    while (frm.elements[offset].type!="checkbox") offset++;
	  
	    for (var i=0; i<jsCompanies.length; i++) {
              if (frm.elements[i+offset].checked)
                chi.value += jsCompanies[i] + ",";
            } // next(i)
          
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
          
              frm.submit();
            } // fi(checkeditems)
          } // fi(confirm)            
	} // deleteCompanies()

        // ----------------------------------------------------

	function modifyCompany(id,nm) {
	  self.open ("company_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_company=" + id + "&n_company=" + escape(nm) + "&gu_workarea=<%=gu_workarea%>", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=660,height=660");
	}	

        // ----------------------------------------------------

	function sortBy(fld) {
	  
	  document.location = "company_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>" + "&query=<%=sQuery%>&where=<%=Gadgets.URLEncode(sWhere)%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	}			

        // ----------------------------------------------------

        function selectAll() {
          var frm = document.forms[0];
          
          for (var c=0; c<jsCompanies.length; c++)                        
            eval ("frm.elements['" + jsCompanies[c] + "'].click()");
        }
       
       // ----------------------------------------------------

	function findCompany() {	  
	  var frm = document.forms[0];
	  
	  window.location = "company_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	
	} // findCompany()

      // ------------------------------------------------------

      function viewAddrs(ev,gu,nm) {
        showDiv(ev,"../common/addr_layer.jsp?nm_company=" + escape(nm) + "&linktable=k_x_company_addr&linkfield=gu_company&linkvalue=" + gu);
      }

      // ----------------------------------------------------
      
      function listContacts() {
        window.location = "contact_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=0&field=nm_legal&find=" + escape(jsCompanyNm) + "&selected=" + getURLParam("selected") + "&subselected=1";
      }

      // ----------------------------------------------------
      
      function listBugs() {
        top.location = "../projtrack/bug_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=0&where=%20AND%20p.gu_company='" + jsCompanyId + "'&selected=4&subselected=2";
      }

      // ----------------------------------------------------
      
      function listProjects() {      
        window.location = "../projtrack/project_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&field=nm_legal&find=" + escape(jsCompanyNm) + "&selected=4&subselected=0";
      }

      // ----------------------------------------------------

      function listAddresses() {
        var frm = window.document.forms[0];
      
        self.open ("../common/addr_list.jsp?nm_company=" + escape(jsCompanyNm) + "&linktable=k_x_company_addr&linkfield=gu_company&linkvalue=" + jsCompanyId, "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=520");

      }

      // ----------------------------------------------------
      
      function createProject(id,nm) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        window.open("prj_create.jsp?gu_workarea=<%=gu_workarea%>&gu_company=" + id, "addproject", "directories=no,toolbar=no,menubar=no,width=540,height=280");       
<% } %>
      }

      // ------------------------------------------------------

      function runQuery() {
        var qry = getCombo(document.forms[0].sel_query);
        
        if (qry.length>0) {
          window.top.location.href = "company_listing_f.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&orderby=<%=sOrderBy%>&gu_query=" + qry + "&selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>";
        }
      }
        
      // ----------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {
        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.nm_legal%>");
          document.forms[0].find.value = jsCompanyNm;
          findCompany();
        }
      } // findCloned()
      
      function clone() {
<% if (bIsGuest) { %>
        alert ("Your credential level as Guest does not allow you to perform this action");
<% } else { %>              
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=company_clon&gu_instance=" + jsCompanyId +"&opcode=CCOM&classid=91", null, "directories=no,toolbar=no,menubar=no,width=320,height=200");                
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
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	  setCombo(document.forms[0].sel_query, "<%=sQuery%>");
	} // setCombos()
    //-->    
  </SCRIPT>
</HEAD>

<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post" onSubmit="findCompany();return false;">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Company Listing</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>      
        <TR VALIGN="middle">
        <TD>&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Company"></TD>
        <TD VALIGN="middle">
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain" TITLE="New Company">New</A>
<% } else { %>
          <A HREF="#" onclick="createCompany()" CLASS="linkplain" TITLE="New Company">New</A>
<% } %>
        </TD>
        <TD VALIGN="middle">&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Company"></TD>
        <TD VALIGN="middle">
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain" TITLE="Delete Company">Delete</A>
<% } else { %>
          <A HREF="javascript:deleteCompanies()" CLASS="linkplain" TITLE="Delete Company">Delete</A>
<% } %>
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Find Company"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE="<%=DB.nm_legal%>">Legal Name<OPTION VALUE="<%=DB.nm_commercial%>">Commercial Name<OPTION VALUE="<%=DB.id_sector%>">Sector<OPTION VALUE="<%=DB.id_legal%>">Legal Id<OPTION VALUE="<%=DB.id_status%>">Status<OPTION VALUE="<%=DB.id_ref%>">Reference</SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="#" onclick="findCompany();return false;" CLASS="linkplain" TITLE="Find Company">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard find filter"></TD>
        <TD VALIGN="bottom">
          <A HREF="#" onclick="document.forms[0].find.value='';findCompany();return false;" CLASS="linkplain" TITLE="Discard find filter">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR></TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="2" ALIGN="left">
<%
    	  // [~//Pintar los enlaces de siguiente y anterior~]
    
          if (iSkip>0)
            out.write("            <A HREF=\"company_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&query=" + sQuery + "&orderby=" + sOrderBy + "&where=" + Gadgets.URLEncode(sWhere) + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
          if (!oCompanies.eof())
            out.write("            <A HREF=\"company_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&query=" + sQuery + "&orderby=" + sOrderBy + "&where=" + Gadgets.URLEncode(sWhere) + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
%>
          </TD>
          <TD COLSPAN="3" ALIGN="right">
	    <FONT CLASS="textplain">Predefined queries</FONT>&nbsp;<SELECT NAME="sel_query" CLASS="combomini"><OPTION VALUE=""></OPTION><% for (int q=0; q<iQueries; q++) out.write("<OPTION VALUE=\"" + oQueries.getString(0,q) + "\">" + oQueries.getString(1,q) + "</OPTION>"); %></SELECT>&nbsp;<A HREF="#" onClick="runQuery()" CLASS="linkplain">Query</A>
          </TD>
          <TD>
<% if (bIsGuest) { %>
            <IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="22" BORDER="0">
<% } else { %>
            <A HREF="../common/qbf.jsp?queryspec=companies" TARGET="_top" TITLE="New Query"><IMG SRC="../images/images/newqry16.gif" WIDTH="22" HEIGHT="18" VSPACE="2" BORDER="0" ALT="New Query"></A>&nbsp;
<% } %>
          </TD>          
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="<%=String.valueOf(floor(340f*fScreenRatio))%>">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" TITLE="Order by this field" ALT="Order by this field"></A>&nbsp;<B>Legal Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="<%=String.valueOf(floor(160f*fScreenRatio))%>">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" TITLE="Order by this field" ALT="Order by this field"></A><B>&nbsp;Sector</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="80">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ?  "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" TITLE="Order by this field" ALT="Order by this field"></A><B>&nbsp;Legal Id</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="120">&nbsp;<A HREF="javascript:sortBy(6);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==6 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" TITLE="Order by this field" ALT="Order by this field"></A><B>&nbsp;Status</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD>
        </TR>
<%
	  String sCompId, sCompNm, sCompDe, sCompSc, sCompLg;
	  Object sCompSt;
	  	  	  
	  for (int i=0; i<iCompanyCount; i++) {
            
            sCompId = oCompanies.getString(0,i);
	    sCompNm = oCompanies.getString(1,i).replace((char)39,(char)32);
	    sCompDe = oCompanies.getStringNull(2,i,"").replace((char)39,(char)32);
            sCompSc = oCompanies.getStringNull(3,i,"");
            sCompLg = oCompanies.getStringNull(4,i,"");
            if (null==oCompanies.get(5,i))
              sCompSt = "";
            else
              sCompSt = oStatusMap.get(oCompanies.getString(5,i));
            if (sCompDe.length()>40) sCompDe = sCompDe.substring(0,37) + "...";
            
            // The GUID which is 32 zeros is a special code that it is never shown on screen
            if (!sCompId.equals("00000000000000000000000000000000")) {
%>                        
            <TR HEIGHT="14">
              <TD CLASS="strip<%=(i%2)+1%>"><A HREF="#" onContextMenu="return false;" onClick='hideDiv();viewAddrs(event,"<%=sCompId%>","<%=sCompDe%>");return false'><IMG SRC="../images/images/theworld16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Click for viewing addresses"></A></TD>
              <TD CLASS="strip<%=(i%2)+1%>">&nbsp;<A HREF="javascript:;" oncontextmenu="jsCompanyId='<%=sCompId%>'; jsCompanyNm='<%=oCompanies.getString(1,i)%>'; return showRightMenu(event)" onmouseover="window.status='Edit Company'; return true;" onmouseout="window.status=''; return true;" onclick="modifyCompany('<%=sCompId%>','<%=sCompNm%>')" TITLE="Click Right Mouse Button for Context Menu"><%=sCompNm%></A></TD>
              <TD CLASS="strip<%=(i%2)+1%>">&nbsp;<%=sCompSc%></TD>
              <TD CLASS="strip<%=(i%2)+1%>">&nbsp;<%=sCompLg%></TD>
              <TD CLASS="strip<%=(i%2)+1%>">&nbsp;<%=sCompSt%></TD>
              <TD CLASS="strip<%=(i%2)+1%>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<%=sCompId%>"></TD>
            </TR>
<%        } } // next(i) %>          	  
        <TR>
          <TD COLSPAN="6" ALIGN="left">
<%
    	  // [~//Pintar los enlaces de siguiente y anterior~]
    
          if (iSkip>0)
            out.write("            <A HREF=\"company_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&query=" + sQuery + "&orderby=" + sOrderBy + "&where=" + Gadgets.URLEncode(sWhere) + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
          if (!oCompanies.eof())
            out.write("            <A HREF=\"company_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&query=" + sQuery + "&orderby=" + sOrderBy + "&where=" + Gadgets.URLEncode(sWhere) + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
%>
          </TD>
        </TR>
      </TABLE>
    </FORM>
    
    <IFRAME name="addrIFrame" src="../common/blank.htm" width="0" height="0" border="0" frameborder="0"></IFRAME>
    <SCRIPT language="JavaScript" type="text/javascript">
      addMenuOption("Open","modifyCompany(jsCompanyId, jsCompanyNm)",1);
      addMenuOption("Duplicate","clone()",0);
      addMenuSeparator();
      addMenuOption("View Individuals","listContacts()",0);
      addMenuOption("View Addresses","listAddresses()",0);
      <% if ((iAppMask & (1<<ProjectManager))!=0) { %>
        addMenuSeparator();
        addMenuOption("Show Incident","listBugs()",0);
        addMenuOption("New project","createProject(jsCompanyId, jsCompanyNm)",0);
        addMenuOption("View Projects","listProjects()",0);
      <% } %>
    </SCRIPT>
  </BODY>
</HTML>