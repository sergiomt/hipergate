<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
 
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
  
  String id_domain = getCookie(request, "domainid", "0");
  String n_domain = getCookie(request, "domainnm", "");
  String gu_user = getCookie(request, "userid", "");
  String gu_workarea = getCookie(request, "workarea", "");
  
  DBSubset oLists = null;
  int iListCount = 0, iOprtCount = 0;

  String sSQL;
  
  final int iMaxRecent = 8;

  String[][] aRecent = new String [6][iMaxRecent];
  String[][] aOprtns = new String [6][iMaxRecent];
  int iRecentCount = 0, iOprtnCount = 0;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;

  JDCConnection oConn = null;  
  
  boolean bIsGuest = true;
  
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("crmhome");
    
    oLists = new DBSubset (DB.k_lists, 
    			   DB.gu_list + "," + DBBind.Functions.ISNULL + "(" + DB.de_list + "," + DB.tx_subject + ")",
      		           DB.gu_workarea + "=?", 100);      				 
    oLists.setMaxRows(100);
    iListCount = oLists.load (oConn, new Object[]{gu_workarea});

    sSQL = "(SELECT dt_last_visit,gu_company,NULL AS gu_contact,nm_company,nm_company AS full_name,work_phone,tx_email FROM k_companies_recent WHERE gu_user=?) UNION (SELECT dt_last_visit,NULL AS gu_company,gu_contact,nm_company,full_name,work_phone,tx_email FROM k_contacts_recent WHERE gu_user=?) ORDER BY 1 DESC";

    if (com.knowgate.debug.DebugFile.trace) com.knowgate.debug.DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");
    
    oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString (1,gu_user);
    oStmt.setString (2,gu_user);
    oRSet = oStmt.executeQuery();
    
    while (oRSet.next() && iRecentCount<iMaxRecent) {
      
      aRecent[0][iRecentCount] = oRSet.getString(2);         // gu_company
      if (oRSet.wasNull()) aRecent[0][iRecentCount] = null;
      
      aRecent[1][iRecentCount] = nullif(oRSet.getString(3)); // gu_contact
      aRecent[2][iRecentCount] = oRSet.getString(4);         // nm_company
      aRecent[3][iRecentCount] = nullif(oRSet.getString(5)); // full_name
      aRecent[4][iRecentCount] = nullif(oRSet.getString(6)); // work_phone
      aRecent[5][iRecentCount] = oRSet.getString(7);         // tx_email

      iRecentCount++;      
    } // wend
    
    oRSet.close();
    oStmt.close();

    String sInterval;
    
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL)
      sInterval = "interval '10 years'";
    else
      sInterval = "3600";
      
    sSQL = "(SELECT "+
            DB.gu_oportunity+","+DB.tl_oportunity+","+DB.gu_company+","+DB.gu_contact+","+DB.tx_company+","+DB.tx_contact+","+DB.dt_modified+","+DB.dt_next_action+","+
    	    DBBind.Functions.GETDATE+"-"+DB.dt_modified+ " AS nu_elapsed FROM "+DB.k_oportunities+" WHERE "+DB.id_status+" NOT IN ('PERDIDA','GANADA','ABANDONADA') AND "+
    	    DB.dt_modified+" IS NOT NULL AND " + DB.gu_workarea+"=? AND "+DB.gu_writer+"=?) UNION (SELECT "+    				   
    	    DB.gu_oportunity+","+DB.tl_oportunity+","+DB.gu_company+","+DB.gu_contact+","+DB.tx_company+","+DB.tx_contact+","+DB.dt_modified+","+DB.dt_next_action+","+    				   
	    DBBind.Functions.ISNULL+"("+DB.dt_next_action+","+DBBind.Functions.GETDATE+"+" + sInterval + ")-"+DBBind.Functions.GETDATE+" AS nu_elapsed "+
	    "FROM "+DB.k_oportunities+" WHERE "+DB.id_status+" NOT IN ('PERDIDA','GANADA','ABANDONADA') AND "+
    	    DB.gu_workarea+"=? AND "+DB.gu_writer+"=?) ORDER BY nu_elapsed";

    if (com.knowgate.debug.DebugFile.trace) com.knowgate.debug.DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");
    
    oStmt = oConn.prepareStatement(sSQL,ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oStmt.setString (1,gu_workarea);
    oStmt.setString (2,gu_user);
    oStmt.setString (3,gu_workarea);
    oStmt.setString (4,gu_user);
    oRSet = oStmt.executeQuery();    
        
    while (oRSet.next() && iOprtnCount<iMaxRecent) {
    
      boolean bListed = false;
      for (int n=0; n<iOprtnCount && !bListed; n++)
	bListed = oRSet.getString(1).equals(aOprtns[0][n]);
	
      if (!bListed) {
        aOprtns[0][iOprtnCount] = oRSet.getString(1);
        aOprtns[1][iOprtnCount] = oRSet.getString(2);
        aOprtns[2][iOprtnCount] = oRSet.getString(3);
        aOprtns[3][iOprtnCount] = oRSet.getString(4);
        aOprtns[4][iOprtnCount] = oRSet.getString(5);
        aOprtns[5][iOprtnCount] = oRSet.getString(6);

        iOprtnCount++;
      }
    } // wend
    
    oRSet.close();
    oStmt.close();
    
    oConn.close("crmhome");
  }
  catch (SQLException e) {  
    iListCount=0;
    oLists=null;
    
    if (oRSet!=null) oRSet.close();

    if (oStmt!=null) oStmt.close();
    
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("crmhome");

    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;  
  oConn = null;
  
  sendUsageStats(request, "crmhome");
  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Contact Management</TITLE> 
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--

    // ----------------------------------------------------
        	
    function createCompany() {	  
      window.open ("company_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", null, "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=" + (screen.height<=600 ? "520" : "650"));	  
    } // createCompany()

    // ----------------------------------------------------
        	
    function createContact() {
      self.open ("contact_new_f.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>", null, "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=" + (screen.height<=600 ? "520" : "600"));
    } // createContact()

    // ----------------------------------------------------

    function createOportunity() {
<%    if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<%    } else { %>
	  self.open ("oportunity_new.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "newoportunity", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));	  
<%    } %>
    } // createOportunity()

    // ----------------------------------------------------

    function searchCompany() {
    
      var frm = document.forms[0];
      var nmc = frm.nm_company.value.toUpperCase();      

      if (nmc.length==0) {
        alert ("Type legal name of Company to find");
        return false;
      }  
     
      if (hasForbiddenChars(nmc)) {
	      alert ("Company name contains invalid characters");
	      return false;
      } else {
        document.location = "company_listing_f.jsp?selected=2&subselected=0&field=nm_legal&find=" + escape(nmc);        
        return true;
      }
    }

    // ----------------------------------------------------

    function searchContact() {
      var frm = document.forms[0];
      var nmc = frm.full_name.value;

      if (nmc.length==0) {
        alert ("Type name or surname for individual to find");
        return false;
      }  
      
      if (hasForbiddenChars(nmc)) {
	      alert ("Contact name contains invalid characters");
	      return false;
      }
      window.location = "contact_listing_f.jsp?selected=2&subselected=1&field=tx_name&find=" + encodeURIComponent(nmc);
    }

    // ----------------------------------------------------

    function searchOportunity() {
      var frm = document.forms[0];
      var nmc = frm.tl_oportunity.value;

      if (nmc.length==0) {
        alert ("Enter the title of the opportunity to be found");
        return false;
      }  
      
      if (nmc.indexOf("'")>0 || nmc.indexOf('"')>0 || nmc.indexOf("?")>0 || nmc.indexOf("%")>0 || nmc.indexOf("*")>0 || nmc.indexOf("&")>0 || nmc.indexOf("/")>0) {
		    alert ("The string contains invalid characters");
				return false;
      }
      window.location = "oportunity_listing_f.jsp?id_domain=<%=id_domain%>&n_domain=<%=n_domain%>&skip=0&orderby=0&field=tl_oportunity&id_status=&id_objetive=&private=0&selected=2&subselected=2&find=" + escape(nmc);
    }

    // ----------------------------------------------------
    
    function importWAB() {
    
      if (navigator.appName!="Microsoft Internet Explorer") {
        alert ("Windows Address Book import only works from Internet Explorer");
        return false;
      }
      
      var w = window.open("../wab/wabframe.html","wabimport","top=" + (screen.height-300)/2 + ",left=" + (screen.width-320)/2 + ",height=300,width=320,theatermode,menubar=no");
      w.focus();
    }

    // ----------------------------------------------------
    
    function importTXT() {
          
      var w = window.open("textloader1.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>","textloader","menubar=no,toolbar=no,resizable=yes,scrollbars=yes,status=yes,height=500,width=500");
      w.focus();
    }

    // ----------------------------------------------------
    
    function importVCard() {
          
      var w = window.open("vcardloader1.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>","vcardloader","menubar=no,toolbar=no,resizable=yes,scrollbars=yes,status=yes,height=460,width=490");
      w.focus();
    }

    // ----------------------------------------------------
        	
    function createList() {	  
       // [~//Crear una nueva lista de distribución~]
	  
       window.open ("list_wizard_01.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" , "listwizard", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-320)/2 + ",left=" + (screen.width-340)/2 + ",width=340,height=340");	  
    } // createList()

    // ----------------------------------------------------

    function modifyContact(id) {
      window.open ("contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));
    }	

    // ----------------------------------------------------

    function modifyCompany(id,nm) {
      window.open ("company_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_company=" + id + "&n_company=" + escape(nm) + "&gu_workarea=<%=gu_workarea%>", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=" + String(screen.height-80));
    }	
        
  //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0">
<%@ include file="../common/tabmenu.jspf" %>
<BR>
<TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Contact Management</FONT></TD></TR></TABLE>
<FORM>
  <TABLE  BORDER="0">
    <TR>
      <TD VALIGN="top" ALIGN="left">
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <!-- Pestaña superior -->
          <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD BACKGROUND="../images/images/graylinebottom.gif">
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
                  <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
      	          <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_24x24.gif" style="display:block" WIDTH="24" HEIGHT="24" BORDER="0"></TD>
      	        </TR>
                <TR>
            	  <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" COLSPAN="2" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">Companies</TD>
                </TR>
              </TABLE>
            </TD>
            <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG style="display:block" SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea gris y roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Compañías -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">
              <TABLE CELLSPACING="8" BORDER="0">
                <TR>
                  <TD ROWSPAN="2">
                    <A HREF="company_listing_f.jsp?selected=2&subselected=0"><IMG style="display:block" SRC="../images/images/crm/companies.gif" BORDER="0" ALT="Companies"></A>
                  </TD>
                  <TD>
                    <INPUT TYPE="text" NAME="nm_company" MAXLENGTH="50" STYLE="width:180px;text-transform:uppercase">
                  </TD>
                  <TD>
                    <A HREF="#" onClick="searchCompany();return false" CLASS="linkplain">Find Company</A>
                  </TD>
                </TR>
      	        <TR>
                  <TD>
      <% if (bIsGuest) { %>
                    <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New Company</A>
      <% } else { %>
                    <A HREF="#" onclick="createCompany();return false" CLASS="linkplain">New Company</A>
      <% } %>
                  </TD>
                  <TD></TD>
      	        </TR>
              </TABLE>
            </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
            <TD ><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
          </TR>
          <!-- Pestaña media individuos -->
           <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD>
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
            	  <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">Individuals</TD>
      	          <TD ALIGN="right"><IMG  SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
      	        </TR>
              </TABLE>
            </TD>
            <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
        <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Individuos -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">
              <TABLE CELLSPACING="8" BORDER="0">
                <TR>
                  <TD ROWSPAN="3">
                    <A HREF="contact_listing_f.jsp?selected=2&subselected=1"><IMG style="display:block" SRC="../images/images/crm/contacts.gif" BORDER="0" ALT="Individuals"></A>
                  </TD>
                  <TD>
                    <INPUT TYPE="text" NAME="full_name" MAXLENGTH="50" STYLE="width:180px">
                  </TD>
                  <TD>
                    <A HREF="#" onClick="searchContact();return false;" CLASS="linkplain">Find Individual</A>
                  </TD>
                </TR>
      	        <TR>
                  <TD COLSPAN="2">
      <% if (bIsGuest) { %>
                    <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New Individual</A>
      <% } else { %>
                    <A HREF="#" onclick="createContact()" CLASS="linkplain">New Individual</A>
                    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                    <A HREF="contact_fastedit_f.jsp" CLASS="linkplain">Fast Edit</A>
      <% } %>
                  </TD>
      	        </TR>	  
      	        <TR>
                  <TD COLSPAN="2">
                    <TABLE BORDER="0">
                      <TR VALIGN="middle">
                        <TD><IMG style="display:block" SRC="../images/images/crm/outlookexpress2.gif" WIDTH="20" HEIGHT="20" BORDER="0"></TD>
                        <TD>
      <% if (bIsGuest) { %>
                          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Import Address Book Entries from outllok Express</A>
      <% } else { %>
                          <A HREF="#" onclick="importWAB()" CLASS="linkplain">Import Address Book Entries from outllok Express</A>
      <% } %>
                        </TD>
                      </TR>
                      <TR VALIGN="middle">
                        <TD><IMG style="display:block" SRC="../images/images/crm/textload.gif" WIDTH="19" HEIGHT="18" BORDER="0"></TD>
                        <TD>
      <% if (bIsGuest) { %>
                          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Import contacts from text file</A>
      <% } else { %>
                          <A HREF="#" onclick="importTXT()" CLASS="linkplain">Import contacts from text file</A>
      <% } %>
                        </TD>
                      </TR>
                      <TR VALIGN="middle">
                        <TD><IMG style="display:block" SRC="../images/images/crm/vcard.gif" WIDTH="23" HEIGHT="19" BORDER="0"></TD>
                        <TD>
      <% if (bIsGuest) { %>
                          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Import contacts from VCard</A>
      <% } else { %>
                          <A HREF="#" onclick="importVCard()" CLASS="linkplain">Import contacts from VCard</A>
      <% } %>
                        </TD>
                      </TR>
                    </TABLE>
                  </TD>
      	        </TR>	  
              </TABLE>
            </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
      
          <!-- espacio en blanco -->
      
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
            <TD ><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
          </TR>
      
          <!-- Pestaña media oportunidades -->
           <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD>
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
            	  <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">Oportunidades</TD>
      	          <TD ALIGN="right"><IMG  SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
      	        </TR>
              </TABLE>
            </TD>
            <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
        <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Oportunidades -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">
              <TABLE CELLSPACING="8" BORDER="0">
                <TR>
                  <TD ROWSPAN="3">
                    <A HREF="oportunity_listing_f.jsp?selected=2&subselected=2"><IMG style="display:block" SRC="../images/images/crm/oportunities.png" BORDER="0" ALT="Opportunities"></A>
                  </TD>
                  <TD>
                    <INPUT TYPE="text" NAME="tl_oportunity" MAXLENGTH="50" STYLE="width:180px">
                  </TD>
                  <TD>
                    <A HREF="#" onClick="searchOportunity();return false;" CLASS="linkplain">Find Opportunity</A>
                  </TD>
                </TR>
      	        <TR>
                  <TD COLSPAN="2">
      <% if (bIsGuest) { %>
                    <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New Opportunity</A>
      <% } else { %>
                    <A HREF="#" onclick="createOportunity()" CLASS="linkplain">New Opportunity</A>
                    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                    <A HREF="oportunity_fastedit_f.jsp" CLASS="linkplain">Fast Edit</A>
      <% } %>
                  </TD>
      	        </TR>
              </TABLE>
            </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
      
          <!-- espacio en blanco -->
      
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
            <TD ><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
          </TR>
      
          <!-- Pestaña media listas -->
           <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD>
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
            	  <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">Distribution Lists</TD>
      	          <TD ALIGN="right"><IMG  SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
      	        </TR>
              </TABLE>
            </TD>
            <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Lista de Distribución -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">
              <TABLE CELLSPACING="8" BORDER="0">
                <TR>
                  <TD ROWSPAN="2">
                    <A HREF="list_listing_f.jsp?selected=2&subselected=3"><IMG style="display:block" SRC="../images/images/crm/mailserved.gif" BORDER="0" ALT="Lists"></A>
                  </TD>
                  <TD>
                    <SELECT NAME="sel_list" CLASS="textplain" STYLE="width:180px">
      <% 	        for (int l=0; l<iListCount; l++)
      		  out.write("<OPTION VALUE=\"" + oLists.getString(0,l) + "\">" + oLists.getStringNull(1,l,"Lista " + String.valueOf(l)));
      %>              
                    </SELECT>
                  </TD>
                  <TD>
                    <A HREF="#" onclick="alert('Direct Send is disabled at demostrative version')" CLASS="linkplain">Send Mailing</A>
                  </TD>
      	        </TR>	  
      	        <TR>
                  <TD>
      <% if (bIsGuest) { %>            
                    <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New List</A>
      <% } else { %>
                    <A HREF="#" onclick="createList();return false" CLASS="linkplain">New List</A>
      <% } %>
                  </TD>
                  <TD></TD>
      	        </TR>
              </TABLE>
            </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
      
          <!-- Línea gris -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle"><IMG style="display:block" SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0"></TD>
            <TD  BACKGROUND="../images/images/graylinefloor.gif"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0"></TD>
          </TR>
        </TABLE>
      </TD>



      <TD VALIGN="top" ALIGN="left">
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <!-- Pestaña superior -->
          <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD BACKGROUND="../images/images/graylinebottom.gif">
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
                  <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
      	          <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_24x24.gif" style="display:block" WIDTH="24" HEIGHT="24" BORDER="0"></TD>
      	        </TR>
                <TR>
            	  <TD COLSPAN="2" BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">Recent</TD>
                </TR>
              </TABLE>
            </TD>
            <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG style="display:block" SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea gris y roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Compañías -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">

              <!-- INICIO LISTA DE ELEMENTOS -->
              <TABLE CELLSPACING="0" CELLPADDING="2" BORDER="0">
<% for (int r=0; r<iRecentCount; r++) {
     if (aRecent[0][r]==null) {
       out.write ("                <TR>");
       out.write ("<TD><A CLASS=\"linksmall\" HREF=\"#\" onclick=\"modifyContact('" + aRecent[1][r] + "')\">" + aRecent[3][r] + "</A></TD><TD><FONT CLASS=\"textsmall\">" + aRecent[4][r] + "</FONT></TD>");
       if (aRecent[5][r]!=null)
         out.write ("<TD><A CLASS=\"linksmall\" HREF=\"mailto:" + aRecent[5][r] + "\">" + aRecent[5][r] + "</A></TD>");
       else
         out.write ("<TD></TD>");
       out.write ("</TR>\n");
       if (aRecent[2][r]!=null)
         out.write ("                <TR><TD COLSPAN=3><FONT CLASS=\"textsmall\"><I>(" + aRecent[2][r] + ")</I></FONT></TD></TR>\n");    
     }
     else {
       out.write ("                <TR>");
       out.write ("<TD><A CLASS=\"linksmall\" HREF=\"#\" onclick=\"modifyCompany('" + aRecent[0][r] + "')\">" + aRecent[2][r] + "</A></TD><TD><FONT CLASS=\"textsmall\">" + aRecent[4][r] + "</FONT></TD>");
       if (aRecent[5][r]!=null)
         out.write ("<TD><A CLASS=\"linksmall\" HREF=\"mailto:" + aRecent[5][r] + "\">" + aRecent[5][r] + "</A></TD>");
       else
         out.write ("<TD></TD>");
       out.write ("</TR>\n");
     }
     out.write ("                <TR><TD COLSPAN=3><IMG SRC=\"../images/images/spacer.gif\" BORDER=0 HEIGHT=4></TD></TR>\n");
   } // next (r)
   
   if (iOprtnCount>0) {
     out.write ("                <TR><TD COLSPAN=3><HR></TD></TR>\n");

     for (int o=0; o<iOprtnCount; o++) {
       out.write ("                <TR><TD COLSPAN=3><A CLASS=\"linkplain\" HREF=\"oportunity_listing_f.jsp?id_domain="+id_domain+"&n_domain="+n_domain+"&gu_contact="+aOprtns[3][o]+"&where=%20AND%20gu_contact%3D%%27"+aOprtns[3][o]+"%27&field=tx_contact&find="+Gadgets.URLEncode(aOprtns[5][o])+"&show=oportunities&skip=0&selected=2&subselected=2\">" + aOprtns[1][o] + "</A></TD></TR>\n");	
       out.write ("                <TR><TD COLSPAN=3><FONT CLASS=\"textsmall\"><I>(" + nullif(aOprtns[5][o],aOprtns[4][o]) + ")</I></FONT></TD></TR>\n");	
     }
   } // fi (iOprtnCount)
%>     
              </TABLE>              
            </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
      
          <!-- Línea gris -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle"><IMG style="display:block" SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0"></TD>
            <TD  BACKGROUND="../images/images/graylinefloor.gif"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0"></TD>
          </TR>
        </TABLE>      
      </TD>




    </TR>
  </TABLE>
</FORM>
</BODY>
</HTML>
