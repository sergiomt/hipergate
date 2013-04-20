<%@ page import="java.net.URLDecoder,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

  String gu_workarea = getCookie(request,"workarea","");
  
  JDCConnection oConn = null;
  boolean bIsGuest = true;
  int iDegrees = 0;
  DBSubset oDegrees = GlobalCacheClient.getDBSubset("k_education_degree["+gu_workarea+","+sLanguage+"]");
  
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("degree_lookup", true);
    
	  if (null==oDegrees) {
      oDegrees = new DBSubset(DB.k_education_degree,
                              DB.gu_degree+","+DB.id_degree+","+DB.tp_degree+","+DB.nm_degree,
  													  DB.gu_workarea+"=? ORDER BY 4", 200);
	    iDegrees = oDegrees.load(oConn, new Object[]{gu_workarea});

      for (int d=0; d<iDegrees; d++) {
        if (!oDegrees.isNull(2,d)) {
          oDegrees.setElementAt(DBLanguages.getLookUpTranslation(oConn, DB.k_education_degree_lookup, gu_workarea,
          																											 DB.tp_degree, sLanguage, oDegrees.getString(2,d)),2,d);
        }
      } // next
			
			GlobalCacheClient.put("k_education_degree["+gu_workarea+","+sLanguage+"]", oDegrees);
			
	  } else {
      iDegrees = oDegrees.getRowCount();
    }

    oConn.close("degree_lookup");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("degree_lookup");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }

  if (null==oConn) return;

  oConn = null;
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
<%          
          out.write("      var jsInstances = new Array(");
            
            for (int i=0; i<iDegrees; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oDegrees.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
%>

      function selectAll() {    
          var frm = document.forms[0];          
          for (var c=0; c<jsInstances.length; c++)                        
            eval ("frm.elements['" + jsInstances[c] + "'].click()");
      } // selectAll()

<% if (!bIsGuest) { %>

      // ----------------------------------------------------------------------

	    function deleteDegrees() {
	        var offset = 0;
	        var frm = document.forms[0];
	        var chi = frm.checkeditems;
	  	  
	        if (window.confirm("Are you sure that you want to delete the selected qualifications?")) {
	  	  
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
	    } // deleteDegrees()

<% } %>

    //-->
  </SCRIPT>
  <TITLE>hipergate :: Qualifications List</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <DIV class="cxMnu1" style="width:320px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
    <FORM METHOD="post" ACTION="degree_delete.jsp" onsubmit="return validate()">
      <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1">Qualifications List</FONT></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="checkeditems" VALUE="">
<% if (!bIsGuest) { %>      
      <TABLE SUMMARY="Top controls and filters" CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
          <TD VALIGN="middle"><A HREF="degree_edit.jsp?gu_workarea=<%=gu_workarea%>" CLASS="linkplain">New</A></TD>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
          <TD><A HREF="#" onclick="deleteDegrees()" CLASS="linkplain">Delete</A></TD>
        </TR>
        <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>   
<% } %>
      <TABLE SUMMARY="Degrees" CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Id.</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Type</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Title</B></TD>
<% if (!bIsGuest) { %>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select All"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD>
<% } %>
        </TR>
<%

    for (int d=0; d<iDegrees; d++) {
            
      String sStrip = String.valueOf((d%2)+1);
%>
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oDegrees.getStringNull(1,d,"")%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oDegrees.getStringNull(2,d,"")%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="degree_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_degree=<%=oDegrees.getStringNull(0,d,"")%>"><%=oDegrees.getStringNull(3,d,"")%></TD>
<% if (!bIsGuest) { %>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT TYPE="checkbox" VALUE="<% out.write (oDegrees.getString(0,d)); %>"></TD>
<% } %>
            </TR>
<%        } // next %>
      </TABLE>
      <HR>
      <% /* Inicio i2e 2009-01-18 */ %>
      <CENTER><INPUT TYPE="button" VALUE="Close" ACCESSKEY="c" CLASS="closebutton" onclick="window.close()"></CENTER>
      <% /* fin i2e 2009-01-18 */ %>
    </FORM>
</BODY>
</HTML>