<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.hipergate.QueryByForm" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
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
 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // 01. Get browser language
  
  String sLanguage = getNavigatorLanguage(request);
  
  // **********************************************
  
  // 02. Get current skin

  String sSkin = getCookie(request, "skin", "default");

  // **********************************************

  // 03. Get directory /storage

  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");

  
  // **********************************************

  // 03. Get Domain and WorkArea

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 

  // **********************************************

  // 04. Variables for client screen resolution

  String screen_width = request.getParameter("screen_width");

  int iScreenWidth;
  float fScreenRatio;

  // Screen resolution must be passed as a parameter
  // if it does not exist then 800x600 is assumed.

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;

  // **********************************************
    
  // 05. Filter clauses (SQL WHERE)
        
  String sFind = nullif(request.getParameter("find"));
  String sWhere = nullif(request.getParameter("where"));
        
  // **********************************************

  int iSalesMenCount = 0;
  DBSubset oSalesMen;        
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  // 06. Maximum number of rows to display and row to start with
  
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

  // **********************************************

  // 07. Order by column
  
  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  // **********************************************

  JDCConnection oConn = null;  
  QueryByForm oQBF;
  
  try {

    oConn = GlobalDBBind.getConnection("salesmenlisting");  
        
    if (sWhere.length()>0) {
      
      oQBF = new QueryByForm("file://" + sStorage + "/qbf/" + request.getParameter("queryspec") + ".xml");
    
      oSalesMen = new DBSubset (oQBF.getBaseObject(), 
      				 "b." + DB.gu_sales_man,
      				 "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      
      oSalesMen.setMaxRows(iMaxRows);
      iSalesMenCount = oSalesMen.load (oConn, iSkip);
    }
    
    else if (sFind.length()==0) {
      
      // 10. If filter does not exist then return all rows up to maxrows limit

      oSalesMen = new DBSubset (DB.k_sales_men + " s," + DB.k_users + " u", 
      				 "s." + DB.gu_sales_man + ",u." + DB.nm_user + ",u." + DB.tx_surname1 + ",u." + DB.tx_surname2,
      				 "s." + DB.gu_sales_man + "=u." + DB.gu_user + " AND s." + DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oSalesMen.setMaxRows(iMaxRows);
      iSalesMenCount = oSalesMen.load (oConn, iSkip);
    }
    else {

      // 11. Single field Filtered Listing

      oSalesMen = new DBSubset (DB.k_sales_men + " s," + DB.k_users + " u", 
      				 "s." + DB.gu_sales_man + ",u." + DB.nm_user + ",u." + DB.tx_surname1 + ",u." + DB.tx_surname2,
      				 "(u." + DB.nm_user + " " + DBBind.Functions.ILIKE + " ? OR u." + DB.tx_surname1 + " " + DBBind.Functions.ILIKE + " ?) AND s." + DB.gu_sales_man + "=u." + DB.gu_user + " AND s." + DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oSalesMen.setMaxRows(iMaxRows);

      Object[] aFind = { "%" + sFind + "%", "%" + sFind + "%" };
      iSalesMenCount = oSalesMen.load (oConn, aFind, iSkip);
    }
    
    oConn.close("salesmenlisting"); 
  }
  catch (SQLException e) {  
    oSalesMen = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("salesmenlisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // Global variables for moving the clicked row to the context menu
        
        var jsSalesMenId;
        var jsSalesMenNm;
            
        <%
          // Write salesmen primary keys in a JavaScript Array
          // This Array is used when posting multiple elements
          // for deletion.
          
          out.write("var jsSalesMen = new Array(");
            
            for (int i=0; i<iSalesMenCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oSalesMen.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        
        // 12. Create new salesmen
        	
	function createSalesMen() {	  
	  
	  self.open ("salesman_new.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "editsalesmen", "directories=no,toolbar=no,menubar=no,width=500,height=460");	  
	} // createSalesMen()

        // ----------------------------------------------------

        // 13. Delete checked salesmens
	
	function deleteSalesMen() {

	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Do you want to remove selected salesmen?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "salesmen_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsSalesMen.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsSalesMen[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteSalesMen()
	
        // ----------------------------------------------------


	function modifySalesObjectives(id,nm) {
	  
	  self.open ("salesman_edit_f.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" + "&gu_sales_man=" + id + "&n_sales_man=" + escape(nm), "editsalesobjectives", "directories=no,toolbar=no,menubar=no,width=600,height=" + String(Math.round(460*(screen.height/600))));
	}

        // ----------------------------------------------------

	function modifySalesMen(id,nm) {
	  
	  self.open ("salesman_f.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" + "&gu_sales_man=" + id + "&n_sales_man=" + escape(nm), "editsalesman", "directories=no,toolbar=no,menubar=no,width=600,height=" + String(Math.round(460*(screen.height/600))));
	}

        // ----------------------------------------------------

        // 15. Reload Page sorting by a field

	function sortBy(fld) {
	  
	  var frm = document.forms[0];
	  
	  window.location = "salesmen_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&where=" + escape("<%=sWhere%>") + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // sortBy		

        // ----------------------------------------------------

        // 16. Select All SalesMen

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsSalesMen.length; c++)                        
            eval ("frm.elements['" + jsSalesMen[c] + "'].click()");
        } // selectAll()
       
        // ----------------------------------------------------

        // 17. Reload Page finding salesmens by a single field
	
	function findSalesMen() {
	  	  
	  var frm = document.forms[0];
	  
	  if (frm.find.value.length>0)
	    window.location = "salesmen_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  else
	    window.location = "salesmen_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  
	} // findSalesMen()

      // ----------------------------------------------------

      var intervalId;
      var winclone;

      // This function is called every 100 miliseconds for testing
      // whether or not clone call has finished.
      
      function findCloned() {
        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.nm_legal%>");
          document.forms[0].find.value = jsSalesMenNm;
          findSalesMen();
        }
      } // findCloned()

      // 18. Clone an salesmen using an XML data structure definition
      
      function clone() {        
        // Open a clone window and wait for it to be closed
        
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=salesmen_clon&gu_salesmen=" + jsSalesMenId +"&opcode=CCOM&classid=91", "clonesalesmen", "directories=no,toolbar=no,menubar=no,width=320,height=200");                
        intervalId = setInterval ("findCloned()", 100);
      }	// clone()
      
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	} // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Sales Men Listing</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Sales Men Listing</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <!-- 19. Top Menu -->
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createSalesMen()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="javascript:deleteSalesMen()" CLASS="linkplain">Delete</A></TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="javascript:findSalesMen();" CLASS="linkplain" TITLE="Find">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Search"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:document.forms[0].find.value='';findSalesMen();" CLASS="linkplain" TITLE="Discard Search">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top Menu -->
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  // 20. Paint Next and Previous Links
    
    	  if (iSalesMenCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"salesmen_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oSalesMen.eof())
              out.write("            <A HREF=\"salesmen_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iSalesMenCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(150f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(320f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Surname</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select All"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD></TR>
<%
    	  // 21. List rows

	  String sInstId, sStrip;
	  for (int i=0; i<iSalesMenCount; i++) {
            sInstId = oSalesMen.getString(0,i);
            
            sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="#" TITLE="Edit Sales Objectives" onclick="modifySalesObjectives('<% out.write(sInstId); %>','<% out.write(oSalesMen.getStringNull(1,i,"no name") + " " + oSalesMen.getStringNull(2,i,"") + " " + oSalesMen.getStringNull(3,i,"")); %>')"><IMG SRC="../images/images/crm/target16.gif" WIDTH="17" HEIGHT="18" BORDER="0" ALT="Edit Sales Objectives"></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" onclick="modifySalesMen('<% out.write(sInstId); %>','<% out.write(oSalesMen.getStringNull(1,i,"no name") + " " + oSalesMen.getStringNull(2,i,"") + " " + oSalesMen.getStringNull(3,i,"")); %>')"><% out.write(oSalesMen.getStringNull(1,i,"no name")); %></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<% out.write(oSalesMen.getStringNull(2,i,"")+" "+oSalesMen.getStringNull(3,i,"")); %></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<% out.write (sInstId); %>">
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
