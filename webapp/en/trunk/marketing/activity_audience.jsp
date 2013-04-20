<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.

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

  final String PAGE_NAME = "activity_audience";

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm","");
  String gu_workarea = getCookie(request,"workarea","");

  String sSkin = getCookie(request, "skin", "xp");
  String gu_activity = request.getParameter("gu_activity");


  JDCConnection oConn = null;

  String sOrderBy = nullif(request.getParameter("orderby"),"2,3");
  String sFind = nullif(request.getParameter("find"));
  String sConfirmed = nullif(request.getParameter("confirmed"));
  
  int iMaxRows = 100;

  int iSkip = Integer.parseInt(nullif(request.getParameter("skip"),"0"));

	DBSubset oAcA1 = null, oAcA2 = null;
  int iAcA1 = 0, iAcA2 = 0;
  
  boolean bIsGuest = true;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME);

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);

		String LIKEI = oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL ? "~*" : DBBind.Functions.ILIKE;

	  oAcA1 = new DBSubset (DB.k_x_activity_audience+" x, "+DB.k_contacts+" c, "+DB.k_addresses+" a",
																 "c."+DB.gu_contact+",c."+DB.tx_name+",c."+DB.tx_surname+",a."+DB.tx_email+
																 ",a."+DB.work_phone+",a."+DB.direct_phone+",a."+DB.home_phone+",a."+DB.mov_phone+
																 ",x."+DB.bo_confirmed+",x."+DB.bo_went+",x."+DB.bo_paid+",a."+DB.gu_address,
																 "x."+DB.gu_contact+"=c."+DB.gu_contact+" AND x."+DB.gu_address+"=a."+DB.gu_address+" AND "+
																(sFind.length()>0 ? " (c."+DB.tx_name+" "+LIKEI+" ? OR c."+DB.tx_surname+" "+LIKEI+" ?) AND " : "")+
																(sConfirmed.length()>0 ? "x."+DB.bo_confirmed+"="+sConfirmed+" AND " : "")+
																 "x."+DB.gu_activity+"=? ORDER BY "+sOrderBy, 1000);
	  oAcA2 = new DBSubset (DB.k_x_activity_audience+" x, "+DB.k_contacts+" c",
																 "c."+DB.gu_contact+",c."+DB.tx_name+",c."+DB.tx_surname+",NULL AS "+DB.tx_email+
																 ",NULL AS "+DB.work_phone+",NULL AS "+DB.direct_phone+",NULL AS "+DB.home_phone+",NULL AS "+DB.mov_phone+
																 ",x."+DB.bo_confirmed+",x."+DB.bo_went+",x."+DB.bo_paid+",'' AS "+DB.gu_address,
																 "x."+DB.gu_contact+"=c."+DB.gu_contact+" AND x."+DB.gu_address+" IS NULL AND "+
																(sFind.length()>0 ? " (c."+DB.tx_name+" "+LIKEI+" ? OR c."+DB.tx_surname+" "+LIKEI+" ?) AND " : "")+
																(sConfirmed.length()>0 ? "x."+DB.bo_confirmed+"="+sConfirmed+" AND " : "")+
																 "x."+DB.gu_activity+"=? ORDER BY "+sOrderBy, 1000);

		if (sFind.length()==0) {
      iAcA1 = oAcA1.load(oConn, new Object[]{gu_activity});
      iAcA2 = oAcA2.load(oConn, new Object[]{gu_activity});
    } else {
    	String sSought = oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL ? Gadgets.accentsToPosixRegEx(sFind) + ".*" : sFind + "%";
      iAcA1 = oAcA1.load(oConn, new Object[]{sSought, sSought, gu_activity});
      iAcA2 = oAcA2.load(oConn, new Object[]{sSought, sSought, gu_activity});
    }
    if (iAcA1>0 && iAcA2>0) {
      oAcA1.union(oAcA2);
      oAcA1.sortBy(1);
      iAcA1 = oAcA1.getRowCount();
    } else if (iAcA1==0 && iAcA2>0) {
			iAcA1 = iAcA2;
			oAcA1 = oAcA2;
    }
   
    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close(PAGE_NAME);
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  final int iUpperbound = iAcA1<iSkip+iMaxRows ? iAcA1 : iSkip+iMaxRows;
  
%>
<HTML>
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <TITLE>hipergate :: Audience</TITLE>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
<%          
          out.write("var jsContacts = new Array(");
            
          for (int i=iSkip; i<iUpperbound; i++) {
            if (i>0) out.write(","); 
              out.write("\"" + oAcA1.getString(0,i) + "\"");
            }
          out.write(");\n        ");
%>

    function filterAttendants(findstr, skiprows, sortby, confirmation) {
      document.location = "activity_audience.jsp?gu_activity=<%=gu_activity%>&skip="+String(skiprows)+"&sortby="+sortby+"&confirmed="+confirmation+"&find="+escape(encodeURI(findstr));
      return true;
    }

    // ----------------------------------------------------

    function selectAll() {
          
      var frm = document.forms[0];
          
        for (var c=0; c<jsContacts.length; c++)                        
          eval ("frm.elements['" + jsContacts[c] + "'].click()");
    } // selectAll()

    // ----------------------------------------------------

	  function deleteAttendants() {
	  
	    var offset = 0;
	    var frm = document.forms[0];
	    var chi = frm.checkeditems;
	  	  
	    if (window.confirm("Are you sure that you want to delete the selected people?")) {	  	  
	      chi.value = "";	  	  
	      frm.action = "activity_audience_delete.jsp";
	  	  
	      for (var i=0;i<jsContacts.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	        if (frm.elements[offset].checked)
                chi.value += jsContacts[i] + ",";
                offset++;
	          } // next()
	    
	          if (chi.value.length>0) {
	            chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
      } // fi (confirm)
	  } // deleteAttendants()

    // ----------------------------------------------------

	  function updateAttendantsStatus() {
	  
	    var offset = 0;
	    var frm = document.forms[0];
	    var chi = frm.checkeditems;
	  	
	  	if (frm.sel_new_status.selectedIndex<=0) {
	  	  alert ("Please select the new status for the selected people");
			  frm.sel_new_status.focus();
			  return false;
	  	}

	    if (window.confirm("Are you sure that you want to change the status of the selected people?")) {	  	  
	      chi.value = "";	  	  
	      frm.action = "activity_audience_update.jsp";
	  	  
	      for (var i=0;i<jsContacts.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	        if (frm.elements[offset].checked)
                chi.value += jsContacts[i] + ",";
                offset++;
	          } // next()
	    
	          if (chi.value.length>0) {
	            chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
      } // fi (confirm)
	  } // updateAttendantsStatus()

    // ----------------------------------------------------

	  function modifyContact(id) {
	    document.location = "../crm/contact_edit.jsp?noreload=1&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id;
	  }	

    // ----------------------------------------------------

	  function modifyAddress(ad,id) {
      open("../common/addr_edit_f.jsp?gu_address=" + ad + "&nm_company=&linktable=k_x_contact_addr&linkfield=gu_contact&linkvalue=" + id, "editcompaddr", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
	  }

  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onload="window.resizeTo(1000,700)">
  <TABLE WIDTH="100%" SUMMARY="Title">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Audience</FONT></TD></TR>
  </TABLE>  
	<FORM METHOD="post">
    <INPUT TYPE="hidden" NAME="gu_activity" VALUE="<%=gu_activity%>" />
    <INPUT TYPE="hidden" NAME="checkeditems" />
    <TABLE SUMMARY="Top controls and filters" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
<% if (bIsGuest) { %>      
        <TD COLSPAN="4"></TD>
<% } else { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="audience_new_f.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_activity=<%=gu_activity%>" CLASS="linkplain">New</A></TD>
        <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD ALIGN="left"><A HREF="#" onclick="deleteAttendants()" CLASS="linkplain">Delete</A></TD>
<% } %>
        <TD VALIGN="bottom" ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle" ALIGN="left">
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	        &nbsp;<A HREF="javascript:filterAttendants(document.forms[0].find.value, 0, '<%=sOrderBy%>', getCheckedValue(document.forms[0].confirmed))" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard search"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:filterAttendants('', 0, '<%=sOrderBy%>', getCheckedValue(document.forms[0].confirmed))" CLASS="linkplain" TITLE="Discard search">Discard search</A>
        </TD>
      </TR>
<% if (!bIsGuest) { %>      
      <TR>
        <TD></TD>
        <TD VALIGN="middle" ALIGN="right" COLSPAN="4" CLASS="textplain">Update status of selected attendants to</TD>
        <TD COLSPAN="3" ALIGN="left"><SELECT NAME="sel_new_status"><OPTION VALUE=""></OPTION><OPTION VALUE="confirmed">Confirmed people</OPTION><OPTION VALUE="went">Went to the event</OPTION><OPTION VALUE="paid">Paid the event</OPTION><OPTION VALUE="unconfirmed">Not confirmed people</OPTION><OPTION VALUE="nowent">Not went to the event</OPTION><OPTION VALUE="nopaid">Not paid the event</OPTION></SELECT>&nbsp;<A HREF="#" CLASS="linkplain" onclick="updateAttendantsStatus()">Update</TD>
      </TR>
<% } %>
      <TR>
        <TD></TD>
        <TD VALIGN="middle" ALIGN="right" CLASS="textplain">Show</TD>
        <TD COLSPAN="6" ALIGN="left" CLASS="textplain"><INPUT TYPE="radio" NAME="confirmed" VALUE="" onclick="filterAttendants(document.forms[0].find.value, 0, '<%=sOrderBy%>', this.value)" <%=sConfirmed.length()==0 ? "CHECKED" : ""%>>&nbsp;All&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="confirmed" VALUE="1" onclick="filterAttendants(document.forms[0].find.value, 0, '<%=sOrderBy%>', this.value)" <%=sConfirmed.equals("1") ? "CHECKED" : ""%>>&nbsp;Only confirmed&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="confirmed" VALUE="0" onclick="filterAttendants(document.forms[0].find.value, 0, '<%=sOrderBy%>', this.value)" <%=sConfirmed.equals("0") ? "CHECKED" : ""%>>&nbsp;Only unconfirmed</TD>
      </TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/excel16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Excel"></TD>
        <TD COLSPAN="7" VALIGN="middle"><A HREF="activity_audience_xls.jsp?gu_activity=<%=gu_activity%>" TARGET="blank" CLASS="linkplain">Show in Excel format</A></TD>
      </TR>	
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    </TABLE>
<%    
    if (iAcA1>0) {
      if (iSkip>0)
        out.write("            <A HREF=\"#\" CLASS=\"linkplain\" onclick=\"filterAttendants(document.forms[0].find.value, "+String.valueOf(iSkip-iMaxRows)+", '"+sOrderBy+"', getCheckedValue(document.forms[0].confirmed))\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
      if (iSkip+iMaxRows<iAcA1)
        out.write("            <A HREF=\"#\" CLASS=\"linkplain\" onclick=\"filterAttendants(document.forms[0].find.value, "+String.valueOf(iSkip+iMaxRows)+", '"+sOrderBy+"', getCheckedValue(document.forms[0].confirmed))\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iActivitiesCount)
%>
    <TABLE SUMMARY="Audience List" CELLSPACING="1" CELLPADDING="0">
      <TR>
      	<TD CLASS="tableheader" WIDTH="110" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy('2,3');" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (sOrderBy.equals("2,3") ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by name"></A>&nbsp;<B>Name</B></TD>
        <TD CLASS="tableheader" WIDTH="220" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy('3,2');" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (sOrderBy.equals("3,2") ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by surname"></A>&nbsp;<B>Surname</B></TD>
        <TD CLASS="tableheader" WIDTH="180" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>e-mail</B></TD>
        <TD CLASS="tableheader" WIDTH="180" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Telephones</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Confirmed</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Went</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Paid</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Delete"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Delete"></A>&nbsp;</TD>
      </TR>
<% 
   for (int a=iSkip; a<iUpperbound; a++) {
     String sStrip = String.valueOf((a%2)+1);
%>  
       <TR>
         <TD CLASS="strip<% out.write (sStrip); %>" WIDTH="110">&nbsp;<A HREF="#" onclick="modifyContact('<%=oAcA1.getStringNull(0,a,"")%>')"><FONT CLASS="textsmall"><% out.write (oAcA1.getStringNull(1,a,"")); %></FONT></A></TD>
         <TD CLASS="strip<% out.write (sStrip); %>" WIDTH="220">&nbsp;<A HREF="#" onclick="modifyContact('<%=oAcA1.getStringNull(0,a,"")%>')"><FONT CLASS="textsmall"><% out.write (oAcA1.getStringNull(2,a,"")); %></FONT></A></TD>
         <TD CLASS="strip<% out.write (sStrip); %>" WIDTH="180">&nbsp;<A HREF="#" onclick="modifyAddress('<%=oAcA1.getStringNull(11,a,"")%>','<%=oAcA1.getStringNull(0,a,"")%>')"><FONT CLASS="textsmall"><% out.write (oAcA1.getStringNull(3,a,"")); %></FONT></A></TD>
         <TD CLASS="strip<% out.write (sStrip); %>" WIDTH="180">&nbsp;<FONT CLASS="textsmall"><% if (!oAcA1.isNull(4,a)) out.write (oAcA1.getString(4,a)); if (!oAcA1.isNull(5,a)) out.write ("&nbsp;"+oAcA1.getString(5,a)); if (!oAcA1.isNull(6,a)) out.write ("&nbsp;"+oAcA1.getString(6,a)); if (!oAcA1.isNull(7,a)) out.write ("&nbsp;"+oAcA1.getString(7,a)); %></FONT></TD>
         <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><IMG SRC="../images/images/<% if (!oAcA1.isNull(8,a)) if (oAcA1.getShort(8,a)!=0) out.write ("validated.gif"); else out.write ("pending.gif"); else out.write ("pending.gif"); %>" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Status"></TD>
         <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><IMG SRC="../images/images/<% if (!oAcA1.isNull(9,a)) if (oAcA1.getShort(9,a)!=0) out.write ("validated.gif"); else out.write ("pending.gif"); else out.write ("pending.gif"); %>" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Status"></TD>
         <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><IMG SRC="../images/images/<% if (!oAcA1.isNull(10,a)) if (oAcA1.getShort(10,a)!=0) out.write ("validated.gif"); else out.write ("pending.gif"); else out.write ("pending.gif"); %>" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Status"></TD>
				 <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT TYPE="checkbox" NAME="<%=oAcA1.getString(0,a)%>"></TD>
			</TR>
<% } %>
	  </TABLE>
	</BODY>
</HTML>