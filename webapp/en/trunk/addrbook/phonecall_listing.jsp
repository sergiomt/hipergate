<%@ page import="java.util.Date,java.net.URLDecoder,java.text.SimpleDateFormat,java.text.ParseException,java.sql.SQLException,java.sql.Timestamp,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.projtrack.Bug" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  SimpleDateFormat oFtm = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "default");
  
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea","");
  String gu_user = getCookie(request, "userid", "");
  
  // **********************************************

  // Variables for client screen resolution

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
    
  // Filter clauses (SQL WHERE)
        
  String sField = nullif(request.getParameter("field"));
  String sFind = nullif(request.getParameter("find"));
  String sContactName = nullif(request.getParameter("contact_person"));  
  String sTpPhoneCall = nullif(request.getParameter("tp_phonecall"));
  String sIdStatus = nullif(request.getParameter("id_status"));
  String sDtStart = nullif(request.getParameter("dt_start"));
  String sDtEnd = nullif(request.getParameter("dt_end"));
  String sTypeStatus = "";
  String sDatesFilter = "";
	String sGuBug = "";

  // **********************************************

  int nDates = (sDtStart.length()>0 ? 1 : 0) + (sDtEnd.length()>0 ? 1 : 0);
  Date dtToday = new Date();
  Date dtOneMonthAgo = new Date(dtToday.getTime()-2592000000l);
  int iPhoneCallCount = 0;
  DBSubset oPhoneCalls;        
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  // *******************************************************
  // Maximum number of rows to display and row to start with
  
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
  // Type and status filter
  
  if (sIdStatus.length()>0)
    sTypeStatus = "p." + DB.id_status + "=" + sIdStatus + " AND ";
  
  if (sTpPhoneCall.length()>0)
    sTypeStatus += "p." + DB.tp_phonecall + "='" + sTpPhoneCall + "' AND ";

  if (sDtStart.length()>0 || sDtEnd.length()>0) {
    if (sDtStart.length()>0 && sDtEnd.length()==0)
      sDatesFilter = " p."+DB.dt_start+">=? AND ";
    else if (sDtStart.length()==0 && sDtEnd.length()>0)
      sDatesFilter = " p."+DB.dt_start+"<=? AND ";
    else
      sDatesFilter = " p."+DB.dt_start+" BETWEEN ? AND ? AND ";
  }
  
  // **********************************************
  // Order by column
  
  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  if (3==iOrderBy)
    sOrderBy += " DESC";
    
  // **********************************************

  JDCConnection oConn = null;  
  
  try {
    // Get a connection from pool

    oConn = GlobalDBBind.getConnection("phonecalllisting");  
    
    if (sFind.length()==0 || sField.length()==0) {

      oPhoneCalls = new DBSubset (DB.k_phone_calls + " p", 
      				 DB.gu_phonecall + "," + DB.tp_phonecall + "," + DB.dt_start + "," + DB.dt_end + "," + DB.gu_contact + "," + DB.contact_person + "," + DB.tx_phone + "," + DB.tx_comments + "," + DB.id_status,
      				 sTypeStatus + sDatesFilter + DB.gu_workarea + "='" + gu_workarea + "' AND (" + DB.gu_user + "='" + gu_user + "' OR " + DB.gu_writer + "='" + gu_user + "') " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      oPhoneCalls.setMaxRows(iMaxRows);

      if (sDtStart.length()>0 && sDtEnd.length()>0)
        iPhoneCallCount = oPhoneCalls.load (oConn, new Object[]{new Timestamp(oFtm.parse(sDtStart+" 00:00:00").getTime()),new Timestamp(oFtm.parse(sDtEnd+" 23:59:59").getTime())}, iSkip);
      else if (sDtStart.length()>0)
        iPhoneCallCount = oPhoneCalls.load (oConn, new Object[]{new Timestamp(oFtm.parse(sDtStart+" 00:00:00").getTime())}, iSkip);
      else if (sDtEnd.length()>0)
        iPhoneCallCount = oPhoneCalls.load (oConn, new Object[]{new Timestamp(oFtm.parse(sDtEnd+" 23:59:59").getTime())}, iSkip);
      else
        iPhoneCallCount = oPhoneCalls.load (oConn, iSkip);
    }
    else {

      Object[] aFind = new Object[1+nDates];
      if (sDtStart.length()>0 && sDtEnd.length()>0) {
        aFind[0] = new Timestamp(oFtm.parse(sDtStart+" 00:00:00").getTime());
        aFind[1] = new Timestamp(oFtm.parse(sDtEnd+" 23:59:59").getTime());
      } else if (sDtStart.length()>0) {
        aFind[0] = new Timestamp(oFtm.parse(sDtStart+" 00:00:00").getTime());
      } else if (sDtEnd.length()>0) {
        aFind[0] = new Timestamp(oFtm.parse(sDtEnd+" 23:59:59").getTime());
      }

      if (sField.equals(DB.pg_bug)) {
	try {
	  sGuBug = Bug.getIdFromPg(oConn, Integer.parseInt(sFind), gu_workarea);	  
        } catch (NumberFormatException invalidbugpg) { sGuBug = null; }

	if (sGuBug!=null) {
          oPhoneCalls = new DBSubset (DB.k_phone_calls + " p", 
      				      DB.gu_phonecall + "," + DB.tp_phonecall + "," + DB.dt_start + "," + DB.dt_end + "," + DB.gu_contact + "," + DB.contact_person + "," + DB.tx_phone + "," + DB.tx_comments + "," + DB.id_status,
      				      sTypeStatus + sDatesFilter + DB.gu_workarea+ "='" + gu_workarea + "' AND " + DB.gu_bug + "=? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

          oPhoneCalls.setMaxRows(iMaxRows);

          aFind[nDates] = sGuBug;
        } else {
          oPhoneCalls = new DBSubset (DB.k_phone_calls + " p", 
      				      DB.gu_phonecall + "," + DB.tp_phonecall + "," + DB.dt_start + "," + DB.dt_end + "," + DB.gu_contact + "," + DB.contact_person + "," + DB.tx_phone + "," + DB.tx_comments + "," + DB.id_status,
      				      "1=0 AND " + sDatesFilter + DB.gu_phonecall + "=? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
          oPhoneCalls.setMaxRows(1);
          aFind[nDates] = sFind;
        }
      } else if (sField.equals(DB.gu_contact)) {
        oPhoneCalls = new DBSubset (DB.k_phone_calls + " p", 
      				    DB.gu_phonecall + "," + DB.tp_phonecall + "," + DB.dt_start + "," + DB.dt_end + "," + DB.gu_contact + "," + DB.contact_person + "," + DB.tx_phone + "," + DB.tx_comments + "," + DB.id_status,
      				    sTypeStatus + sDatesFilter + DB.gu_workarea+ "='" + gu_workarea + "' AND (" + DB.gu_user + "='" + gu_user + "' OR " + DB.gu_writer + "='" + gu_user + "') AND " + DB.gu_contact + " = ? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

        oPhoneCalls.setMaxRows(iMaxRows);

        aFind[nDates] = sFind;
      }
      else if (sField.equals(DB.nm_legal)) {
        oPhoneCalls = new DBSubset (DB.k_phone_calls + " p",
      				    "p."+DB.gu_phonecall + ",p." + DB.tp_phonecall + ",p." + DB.dt_start + ",p." + DB.dt_end + ",p." + DB.gu_contact + ",p." + DB.contact_person + ",p." + DB.tx_phone + ",p." + DB.tx_comments + ",p." + DB.id_status,
      				    sTypeStatus + sDatesFilter + " p." + DB.gu_workarea+ "=? AND (p." + DB.gu_user + "=? OR p." + DB.gu_writer + "=?) AND p." + DB.gu_contact + " IN (SELECT " + DB.gu_contact + " FROM " + DB.k_companies + " c WHERE c." + DB.gu_workarea + "=? AND (c." + DB.nm_legal + " " + DBBind.Functions.ILIKE + " ? OR c." + DB.nm_commercial + " " + DBBind.Functions.ILIKE + " ?)) " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

        oPhoneCalls.setMaxRows(iMaxRows);

        if (sDtStart.length()>0 && sDtEnd.length()>0)
	  aFind = new Object[]{new Timestamp(oFtm.parse(sDtStart+" 00:00:00").getTime()), new Timestamp(oFtm.parse(sDtEnd+" 23:59:59").getTime()), gu_workarea,gu_user,gu_user,gu_workarea,"%"+sFind+"%","%"+sFind+"%"};	
        else if (sDtStart.length()>0)
	  aFind = new Object[]{new Timestamp(oFtm.parse(sDtStart+" 00:00:00").getTime()), gu_workarea,gu_user,gu_user,gu_workarea,"%"+sFind+"%","%"+sFind+"%"};	
        else if (sDtEnd.length()>0)
	  aFind = new Object[]{new Timestamp(oFtm.parse(sDtEnd+" 23:59:59").getTime()), gu_workarea,gu_user,gu_user,gu_workarea,"%"+sFind+"%","%"+sFind+"%"};
        else
	  aFind = new Object[]{gu_workarea,gu_user,gu_user,gu_workarea,"%"+sFind+"%","%"+sFind+"%"};
      }
      else {
        oPhoneCalls = new DBSubset (DB.k_phone_calls + " p", 
      				    DB.gu_phonecall + "," + DB.tp_phonecall + "," + DB.dt_start + "," + DB.dt_end + "," + DB.gu_contact + "," + DB.contact_person + "," + DB.tx_phone + "," + DB.tx_comments + "," + DB.id_status,
      				    sTypeStatus + sDatesFilter + DB.gu_workarea+ "='" + gu_workarea + "' AND (" + DB.gu_user + "='" + gu_user + "' OR " + DB.gu_writer + "='" + gu_user + "') AND " + sField + " " + DBBind.Functions.ILIKE + " ? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

        oPhoneCalls.setMaxRows(iMaxRows);

        aFind[nDates] = "%" + sFind + "%";
      }
      
      iPhoneCallCount = oPhoneCalls.load (oConn, aFind, iSkip);
      
      if (sField.equals(DB.gu_contact)) {
        sField = DB.contact_person;
        sFind = sContactName;
      }
    }
    
    oConn.close("phonecalllisting"); 
  }
  catch (SQLException e) {  
    oPhoneCalls = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("phonecalllisting");
    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (ParseException e) {  
    oPhoneCalls = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("phonecalllisting");
    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "ParseException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getMessage() + "&resume=_back"));
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
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // Global variables for moving the clicked row to the context menu
        
        var jsPhoneCallId;
        var jsPhoneCallNm;
            
        <%
          // Write instance primary keys in a JavaScript Array
          // This Array is used when posting multiple elements
          // for deletion.
          
          out.write("var jsPhoneCalls = new Array(");
          
          boolean bFirst = true;  
          for (int i=0; i<iPhoneCallCount; i++) {
              if (bFirst) {
                out.write("\"" + oPhoneCalls.getString(0,i) + "\""); 
                bFirst = false;
              }
              else {
                out.write(",\"" + oPhoneCalls.getString(0,i) + "\"");
              }
          } // next
            
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

        function getPhoneCallStatus() {
          var frm = document.forms[0];
          
          if (frm.id_status[0].checked)
            return "0";
          if (frm.id_status[1].checked)
            return "1";
	  else
            return "";	              
        }
        
        // ----------------------------------------------------

        function getPhoneCallType() {
          var frm = document.forms[0];
          
          if (frm.tp_phonecall[0].checked)
            return "R";
          if (frm.tp_phonecall[1].checked)
            return "S";
	  else
            return "";	              
        }
        
        // ----------------------------------------------------
        
        // 12. Create new phone call
        	
	function createPhoneCall() {	  
	  
	  self.open ("phonecall_edit_f.jsp?gu_workarea=<%=gu_workarea%>&gu_fellow=<%=gu_user%>&gu_bug=<%=nullif(sGuBug)%>", null, "directories=no,toolbar=no,menubar=no,width=500,height=400");	  
	} // createPhoneCall()

        // ----------------------------------------------------
	
	function archivePhoneCalls() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure that you want to archive selected calls?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "phonecall_acknowledge.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsPhoneCalls.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsPhoneCalls[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // archivePhoneCalls()

        // ----------------------------------------------------
	
	function deletePhoneCalls() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to delete the selected calls?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "phonecall_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsPhoneCalls.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsPhoneCalls[i] + ",";
              offset++;
	    } // next()

	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deletePhoneCalls()
	
        // ----------------------------------------------------

        // 14. Modify PhoneCall

	function modifyPhoneCall(id,nm) {
	  
	  self.open ("phonecall_edit_f.jsp?gu_workarea=<%=gu_workarea%>&gu_fellow=<%=gu_user%>&gu_bug=<%=nullif(sGuBug)%>" + "&gu_phonecall=" + id, null, "directories=no,toolbar=no,menubar=no,width=500,height=400");
	} // modifyPhoneCall

        // ----------------------------------------------------

        // 15. Reload Page sorting by a field

	function sortBy(fld) {
	  
	  var frm = document.forms[0];
	  
	  window.location = "phonecall_listing.jsp?id_domain=<%=id_domain%>&tp_phonecall="  + getPhoneCallType() + "&id_status=" + getPhoneCallStatus() + "&skip=0&orderby=" + fld + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // sortBy		

        // ----------------------------------------------------

        // 16. Select All PhoneCalls

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsPhoneCalls.length; c++)                        
            eval ("frm.elements['" + jsPhoneCalls[c] + "'].click()");
        } // selectAll()
       
        // ----------------------------------------------------
	
	function findPhoneCall() {
	  	  
	  var frm = document.forms[0];
	  
	  if (!validate()) return;

	  if (frm.find.value.length>0) {
	    if (getCombo(frm.sel_searched)=="pg_bug" && !isIntValue(frm.find.value)) {
	      alert ("Incident number must be an integer");
	    window.location = "phonecall_listing.jsp?id_domain=<%=id_domain%>&tp_phonecall="  + getPhoneCallType() + "&id_status=" + getPhoneCallStatus() + "&dt_start=" + frm.dt_start.value + "&dt_end="+frm.dt_end.value + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	    }
	    else {
	      window.location = "phonecall_listing.jsp?id_domain=<%=id_domain%>&tp_phonecall="  + getPhoneCallType() + "&id_status=" + getPhoneCallStatus() + "&dt_start=" + frm.dt_start.value + "&dt_end="+frm.dt_end.value + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	    }
	  } else {
	    window.location = "phonecall_listing.jsp?id_domain=<%=id_domain%>&tp_phonecall="  + getPhoneCallType() + "&id_status=" + getPhoneCallStatus() + "&dt_start=" + frm.dt_start.value + "&dt_end="+frm.dt_end.value + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  }
	} // findPhoneCall()
      
      // ------------------------------------------------------	

      function validate() {
        var frm = document.forms[0];
        
        if (frm.dt_start.value.length>0 && !isDate(frm.dt_start.value, "d")) {
          alert ("Invalid Start Date");
          return false;
        }
        if (frm.dt_end.value.length>0 && !isDate(frm.dt_end.value, "d")) {
          alert ("Invalid Start Date");
          return false;
        }
        
        return true;
      }

      // ------------------------------------------------------	

    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  var frm = document.forms[0];
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(frm.maxresults, "<%=iMaxRows%>");
	  setCombo(frm.sel_searched, "<%=sField%>");
	  if (getURLParam("dt_start")==null)
	    frm.dt_start.value = "<%=DBBind.escape(dtOneMonthAgo,"shortDate")%>";
	  else
	    frm.dt_start.value = getURLParam("dt_start");
	  if (getURLParam("dt_end")==null)
	    frm.dt_end.value = "<%=DBBind.escape(dtToday,"shortDate")%>";
	  else
	    frm.dt_end.value = getURLParam("dt_end");
	  
	} // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Phone Call List</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post" onsubmit="return validate()">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Phone Calls</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <!-- 19. Top Menu -->
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createPhoneCall()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/checkmark16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Archive"></TD>
        <TD><A HREF="#" onclick="archivePhoneCalls()" CLASS="linkplain" TITLE="Archive selected calls">Archive</A></TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini">
            <OPTION VALUE="contact_person">Call from</OPTION>
            <OPTION VALUE="nm_legal">Company</OPTION>
            <OPTION VALUE="tx_phone">Phone</OPTION>
            <OPTION VALUE="pg_bug">Incident Num</OPTION>
          </SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="javascript:findPhoneCall();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Search"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:document.forms[0].find.value='';document.forms[0].dt_start.value='';document.forms[0].dt_end.value='';findPhoneCall();" CLASS="linkplain" TITLE="Discard Search">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR>
        <TD COLSPAN="2"></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="#" onclick="deletePhoneCalls()" CLASS="linkplain" TITLE="Delete selected calls">Delete</A></TD>
        <TD></TD>
        <TD VALIGN="middle">
          <FONT CLASS="textplain">between&nbsp;</FONT><INPUT TYPE="text" NAME="dt_start" CLASS="combomini" SIZE="12" MAXLENGTH="10"><FONT CLASS="textplain">&nbsp;and&nbsp;</FONT><INPUT TYPE="text" NAME="dt_end" CLASS="combomini" SIZE="12" MAXLENGTH="10">	                    
        </TD>
        <TD COLSPAN="2"></TD>
      </TR>
      <TR>
        <TD COLSPAN="8">
          <TABLE>
            <TR>
              <TD><FONT CLASS="formstrong">Show</FONT></TD>
              <TD><INPUT TYPE="radio" NAME="tp_phonecall" VALUE="R" onclick="findPhoneCall()" <% if (sTpPhoneCall.equals("R")) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">Received</FONT></TD>
              <TD><INPUT TYPE="radio" NAME="tp_phonecall" VALUE="S" onclick="findPhoneCall()" <% if (sTpPhoneCall.equals("S")) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">Sent</FONT></TD>
              <TD><INPUT TYPE="radio" NAME="tp_phonecall" VALUE="" onclick="findPhoneCall()" <% if (sTpPhoneCall.length()==0) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">Received and Sent</FONT></TD>
	    </TR>
	    <TR>
              <TD></TD>	    
              <TD><INPUT TYPE="radio" NAME="id_status" VALUE="0" onclick="findPhoneCall()" <% if (sIdStatus.equals("0")) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">Pending</FONT></TD>
              <TD><INPUT TYPE="radio" NAME="id_status" VALUE="1" onclick="findPhoneCall()" <% if (sIdStatus.equals("1")) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">Archived</FONT></TD>
              <TD><INPUT TYPE="radio" NAME="id_status" VALUE="" onclick="findPhoneCall()" <% if (sIdStatus.length()==0) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="formplain">Pending and Archived</FONT></TD>
	    </TR>
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
    
    	  if (iPhoneCallCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"phonecall_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oPhoneCalls.eof())
              out.write("            <A HREF=\"phonecall_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iPhoneCallCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" WIDTH="20" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by Sent/Received"></A></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by Date"></A>&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(6);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==6 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by Origin"></A>&nbsp;<B>From</B></TD>
          <TD CLASS="tableheader" WIDTH="100" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(7);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==7 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by Origin"></A>&nbsp;<B>Number</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD></TR>
<%
    	  // 21. List rows

	  String sInstId, sStrip, sCallIcon;
	  for (int i=0; i<iPhoneCallCount; i++) {
            sInstId = oPhoneCalls.getString(0,i);
            
            sStrip = String.valueOf((i%2)+1);
            
            if (oPhoneCalls.getShort(8,i)==(short)1)
              sCallIcon = "callarchived.gif";
            else
              sCallIcon = oPhoneCalls.getString(1,i).equals("R") ? "callin.gif" : "callout.gif";
%>            
            <TR HEIGHT="16">
              <TD CLASS="strip<% out.write (sStrip); %>" WIDTH="20" ALIGN="center"><IMG SRC="../images/images/addrbook/<% out.write(sCallIcon); %>" BORDER="0" ALT="<% out.write(oPhoneCalls.getString(1,i).equals("R") ? "Received Call" : "Sent Call"); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><%=oPhoneCalls.getDate(2,i)%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" onclick="modifyPhoneCall('<%=sInstId%>')"><%=oPhoneCalls.getStringNull(5,i,"unknown")%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right"><%=oPhoneCalls.getStringNull(6,i,"")%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">
	        <INPUT VALUE="1" TYPE="checkbox" NAME="<%=sInstId%>">
	      </TD>
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>
