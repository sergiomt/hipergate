<%@ page import="java.net.URLDecoder,java.io.File,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
/*
  
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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

  final String BASE_TABLE = "k_urls b";
  final String COLUMNS_LIST = "b.gu_url,b.url_addr,b.tx_title,b.nu_clicks,b.dt_last_visit,b.de_url";

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm","");
  String gu_workarea = getCookie(request,"workarea","");

  String sFind = nullif(request.getParameter("find"));

  // **********************************************

  int iUrlCount = 0;
  DBSubset oUrls;        
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

  sOrderBy = nullif(request.getParameter("orderby"));
    
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  // **********************************************

  JDCConnection oConn = null;
  PreparedStatement oStmt;
  ResultSet oRSet;  
  boolean bIsGuest = true;
  
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("urllisting");  
    
    // Limpieza adhoc de URLs txungas
    if (request.getParameter("cleanup")!=null) {

      DBCommand.executeUpdate(oConn, "DELETE FROM k_job_atoms_clicks WHERE gu_url in (SELECT gu_url FROM k_urls WHERE url_addr LIKE '%&pg_atom=%')");
      DBCommand.executeUpdate(oConn, "DELETE FROM k_urls WHERE url_addr like '%&pg_atom=%'");
      DBCommand.executeUpdate(oConn, "DELETE FROM k_job_atoms_clicks WHERE gu_url IN (SELECT gu_url FROM k_urls WHERE length(url_addr)<16 OR url_addr IS NULL)");
      DBCommand.executeUpdate(oConn, "DELETE FROM k_urls WHERE length(url_addr)<16 OR url_addr IS NULL");
      
		  DBSubset oDist = new DBSubset ("k_urls", "DISTINCT(url_addr),gu_workarea", null, 500);
		  int iDist = oDist.load(oConn);
		  String sGuid;
		  
      for (int u=0; u<iDist; u++) {
		    oStmt = oConn.prepareStatement("SELECT gu_url FROM k_urls WHERE gu_workarea=? AND url_addr=?");
		    oStmt.setString(1, oDist.getString(1,u));
		    oStmt.setString(2, oDist.getString(0,u));
		    oRSet = oStmt.executeQuery();
		    if (oRSet.next())
		      sGuid = oRSet.getString(1);
		    else
		    	sGuid = null;
		    oRSet.close();
		    oStmt.close();
      
        int jSesId = oDist.getString(0,u).indexOf(";jsessionid="); 
        if (jSesId>0) {
		    	oStmt = oConn.prepareStatement("UPDATE k_job_atoms_clicks SET gu_url=? WHERE gu_job IN (SELECT gu_job FROM k_jobs WHERE gu_workarea=?) AND gu_url IN (SELECT gu_url FROM k_urls WHERE gu_workarea=? AND url_addr=? OR url_addr LIKE ?)");
		    	oStmt.setString(1, sGuid);
		    	oStmt.setString(2, oDist.getString(1,u));
		    	oStmt.setString(3, oDist.getString(1,u));
		    	oStmt.setString(4, oDist.getString(0,u));
		    	oStmt.setString(5, oDist.getString(0,u).substring(0,jSesId)+"%");	
		    	oStmt.executeUpdate();
		    	oStmt.close();
		    	oStmt = oConn.prepareStatement("DELETE FROM k_urls WHERE gu_workarea=? AND gu_url<>? AND url_addr=? OR url_addr LIKE ?");
		    	oStmt.setString(1, oDist.getString(1,u));
		    	oStmt.setString(2, sGuid);
		    	oStmt.setString(3, oDist.getString(0,u));
		    	oStmt.setString(4, oDist.getString(0,u).substring(0,jSesId)+"%");
		    	oStmt.executeUpdate();
		    	oStmt.close();
		    } else {
		    	oStmt = oConn.prepareStatement("UPDATE k_job_atoms_clicks SET gu_url=? WHERE gu_job IN (SELECT gu_job FROM k_jobs WHERE gu_workarea=?) AND gu_url IN (SELECT gu_url FROM k_urls WHERE url_addr=?)");
		    	oStmt.setString(1, sGuid);
		    	oStmt.setString(2, oDist.getString(1,u));
		    	oStmt.setString(3, oDist.getString(0,u));
		    	oStmt.executeUpdate();
		    	oStmt.close();
		    	oStmt = oConn.prepareStatement("DELETE FROM k_urls WHERE gu_workarea=? AND gu_url<>? AND url_addr=?");
		    	oStmt.setString(1, oDist.getString(1,u));
		    	oStmt.setString(2, sGuid);
		    	oStmt.setString(3, oDist.getString(0,u));
		    	oStmt.executeUpdate();
		    	oStmt.close();
		  	}
      }     // next
    } // fi

    if (sFind.length()==0) {

      oUrls = new DBSubset (BASE_TABLE, COLUMNS_LIST,
      				              "b." + DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy + (iOrderBy==4 || iOrderBy==5 ? " DESC" : "") : ""), iMaxRows);      				 

      oUrls.setMaxRows(iMaxRows);
      iUrlCount = oUrls.load (oConn, iSkip);
    }
    else {

      oUrls = new DBSubset (BASE_TABLE, COLUMNS_LIST,
      				              "b." + DB.gu_workarea+ "='" + gu_workarea + "' AND (" + DB.url_addr + " " + DBBind.Functions.ILIKE + " ? OR "+ DB.tx_title + " " + DBBind.Functions.ILIKE + " ?)" +
      				              (iOrderBy>0 ? " ORDER BY " + sOrderBy + (iOrderBy==4 || iOrderBy==5 ? " DESC" : "") : ""), iMaxRows);

      oUrls.setMaxRows(iMaxRows);

      Object[] aFind = { "%" + sFind + "%", "%" + sFind + "%" };      
      iUrlCount = oUrls.load (oConn, aFind, iSkip);
    }
    
    oConn.close("urllisting"); 
  }
  catch (SQLException e) {  
    oUrls = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("urllisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // Global variables for moving the clicked row to the context menu
        
        var jsInstanceId;
        var jsInstanceNm;
            
        <%          
          out.write("var jsInstances = new Array(");
            
            for (int i=0; i<iUrlCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oUrls.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

<% if (!bIsGuest) { %>
        
	      function createUrl() {	  
	        open ("url_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "editurl", "directories=no,toolbar=no,menubar=no,width=700,height=300");
	      } // createUrl()

        // ----------------------------------------------------
	
	      function deleteUrls() {
	  
	        var offset = 0;
	        var frm = document.forms[0];
	        var chi = frm.checkeditems;
	  	  
	        if (window.confirm("Are you sure that you want to delete the selected URLs?")) {
	  	  
	          chi.value = "";	  	  
	  	  
	          for (var i=0;i<jsInstances.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	        if (frm.elements[offset].checked)
                chi.value += jsInstances[i] + ",";
                offset++;
	          } // next()
	    
	          if (chi.value.length>0) {
	            chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	      } // deleteUrls()
<% } %>	
        // ----------------------------------------------------

	      function modifyUrl(id,nm) {
	        open ("url_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" + "&gu_url=" + id + "&tx_title=" + escape(nm), "editurl", "directories=no,toolbar=no,menubar=no,width=700,height=300");
	      } // modifyInstance

        // ----------------------------------------------------

        // 15. Reload Page sorting by a field

	      function sortBy(fld) {
	  
	        var frm = document.forms[0];
	  
	          window.location = "urls_followup_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	      } // sortBy		

        // ----------------------------------------------------

        // 16. Select All Instances

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsInstances.length; c++)                        
            eval ("frm.elements['" + jsInstances[c] + "'].click()");
        } // selectAll()
       
        // ----------------------------------------------------

	
	      function findUrl() {
	  	  
	        var frm = document.forms[0];

			    if (hasForbiddenChars(frm.find.value)) {
			      alert ("The string sought contains invalid characters");
				    frm.find.focus();
				    return false;
			    }
	  
	        if (frm.find.value.length>0)
	          window.location = "urls_followup_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	        else
	          window.location = "urls_followup_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  
	      } // findUrl()
      
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
  <TITLE>hipergate :: URLs listing</TITLE>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post" ACTION="url_delete.jsp">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">URLs listing</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">      
      <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE SUMMARY="Top controls and filters" CELLSPACING="2" CELLPADDING="2">
        <TR>
        	<TD>&nbsp;&nbsp;<IMG SRC="../images/images/forums/emoticons/opentopic.gif" WIDTH="18" HEIGHT="12" BORDER="0" ALT="Newsletter"></TD>
          <TD COLSPAN="7"><A HREF="jobs_followup_stats.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>" CLASS="linkplain">Listing target URL</A></TD>
        </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
<% if (bIsGuest) { %>      
        <TD COLSPAN="4"></TD>
<% } else { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createUrl()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="#" onclick="deleteUrls()" CLASS="linkplain">Delete</A></TD>
<% } %>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	        &nbsp;<A HREF="javascript:findUrl();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:document.forms[0].find.value='';findInstance();" CLASS="linkplain" TITLE="Discard">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top controls and filters -->
      <TABLE SUMMARY="Data" CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  // 20. Paint Next and Previous Links
    
    	  if (iUrlCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"urls_followup_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oUrls.eof())
              out.write("            <A HREF=\"urls_followup_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iUrlCount)
%>
          </TD>
        </TR>
        <TR>        	
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>Title</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>Clicks</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>Last visit</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Detail</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select All"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD></TR>
<%

	        String sUrlGu, sUrlAd, sUrlTl, sUrlNu, sUrlDt, sStrip;
					int nTotal = 0;	    
	        for (int i=0; i<iUrlCount; i++) {
            sStrip = String.valueOf((i%2)+1);

            sUrlGu = oUrls.getString(0,i);
            sUrlAd = oUrls.getStringHtml(1,i,"");
            sUrlTl = Gadgets.left(oUrls.getStringHtml(2,i,sUrlAd),80);

            if (oUrls.isNull(3,i)) {
              sUrlNu = "";
            } else {
              sUrlNu = String.valueOf(oUrls.getInt(3,i));
              nTotal += oUrls.getInt(3,i);
            }
            
            if (oUrls.isNull(4,i))
              sUrlDt = "";
            else
            	sUrlDt = oUrls.getDateShort(4,i);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right"><A HREF="<%=sUrlAd%>" TARGET="<%=sUrlGu%>"><IMG SRC="../images/images/viewlink.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Open target URL"></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" onclick="modifyUrl('<%=sUrlGu%>','<%=oUrls.getStringNull(2,i,"").replace((char)39,'´').replace((char)34,'´')%>')" ><%=sUrlTl.length()==0 ? sUrlAd : sUrlTl%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right">&nbsp;<%=sUrlNu%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">&nbsp;<%=sUrlDt%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">&nbsp;<A HREF="url_followup_list.jsp?gu_url=<%=sUrlGu%>&gu_workarea=<%=gu_workarea%>&selected=<%=request.getParameter("selected")%>&selected=<%=request.getParameter("subselected")%>">Detail</TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<% out.write (sUrlGu); %>"></TD>
            </TR>
<%        } // next(i) %>
            <TR>
              <TD CLASS="strip<% out.write (String.valueOf((iUrlCount%2)+1)); %>"></TD>
              <TD CLASS="strip<% out.write (String.valueOf((iUrlCount%2)+1)); %>" ALIGN="right"><B>Total</B></TD>
              <TD CLASS="strip<% out.write (String.valueOf((iUrlCount%2)+1)); %>" ALIGN="right"><B><%=String.valueOf(nTotal)%></B></TD>
              <TD CLASS="strip<% out.write (String.valueOf((iUrlCount%2)+1)); %>" COLSPAN="3"></TD>
            </TR>
      </TABLE>
    </FORM>
</BODY>
</HTML>