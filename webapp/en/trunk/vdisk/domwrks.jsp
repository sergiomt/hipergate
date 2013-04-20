<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %>
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

  String sSkin = getCookie(request, "skin", "default");
  String sWorkArea = getCookie(request, "workarea", "");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  
  String sShow = request.getParameter("show");  
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  int iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
  int iSkip = Integer.parseInt(request.getParameter("skip"));
  int iWrkCount = 0;
  DBSubset oWrks = null;

  boolean bIsAdmin = false;
  
  ACLUser oUser;
    
  JDCConnection oConn = null;
  
  Object[] aFind = { '%' + sFind + '%' };
  
  if (null==sShow) sShow = "workareas";
        
  try {

    oConn = GlobalDBBind.getConnection("domwrks");  

    oUser = new ACLUser (oConn, getCookie(request, "userid", ""));

    bIsAdmin = oUser.isDomainAdmin(oConn);

    if (!bIsAdmin) {
      throw new SQLException("Administrator role is required for listing workareas", "28000", 28000);
    }
    
    if (sFind.length()==0) {
      if (getCookie(request, "domainid", "").equals("1024") && bIsAdmin)
        oWrks = new DBSubset (DB.k_workareas + " u, " + DB.k_domains + " d",
                              "u." + DB.gu_workarea + ",u." + DB.nm_workarea + ",d." + DB.id_domain,
                              "u." + DB.id_domain + "=d." + DB.id_domain + " ORDER BY 2", 25);
      else
        oWrks = new DBSubset (DB.k_workareas + " u, " + DB.k_domains + " d",
                              "u." + DB.gu_workarea + ",u." + DB.nm_workarea + ",d." + DB.id_domain,
                              "u." + DB.id_domain + "=d." + DB.id_domain + " AND d." + DB.id_domain + "=" + id_domain + " ORDER BY 2", 25);
      oWrks.setMaxRows(iMaxRows);
      oWrks.load (oConn, iSkip);
    }
    else {
      if (getCookie(request, "domainid", "").equals("1024") && bIsAdmin)
        oWrks = new DBSubset (DB.k_workareas + " u, " + DB.k_domains + " d",
                              "u." + DB.gu_workarea + ",u." + DB.nm_workarea + ",d." + DB.id_domain,
                              "u." + DB.id_domain + "=d." + DB.id_domain + " AND " + DB.nm_workarea + " LIKE ? ORDER BY 2", 25);
      else
        oWrks = new DBSubset (DB.k_workareas + " u, " + DB.k_domains + " d",
                              "u." + DB.gu_workarea + ",u." + DB.nm_workarea + ",d." + DB.id_domain,
                              "u." + DB.id_domain + "=d." + DB.id_domain + " AND d." + DB.id_domain + "=" + id_domain + " AND " + DB.nm_workarea + " LIKE ? ORDER BY 2", 25);
      oWrks.setMaxRows(iMaxRows);
      oWrks.load (oConn, aFind, iSkip);
    }
        
    iWrkCount = oWrks.getRowCount();

    oConn.close("domwrks"); 
  }
  catch (SQLException e) {
    if (oConn!=null) oConn.close("domwrks");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));         
  }
  catch (IllegalStateException e) {
    if (oConn!=null) oConn.close("domwrks");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=../blank.htm"));         
  }
  catch (NullPointerException e) {
    if (oConn!=null) oConn.close("domwrks");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=../blank.htm"));         
  }

  if (null==oConn) return;
  
  oConn = null;
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        <%
          // [~//Escribir los nombres de workareas en un Array JavaScript~]
          // [~//Este arrays se usa en las llamadas de borrado múltiple.~]
          
          out.write("var jsWrks = new Array();\n");
            for (int i=0; i<iWrkCount; i++) {
              if (!sWorkArea.equals(oWrks.getString(0,i))) {
                out.write("jsWrks.push(\"" + oWrks.getString(0,i) + "\");");
              }
            }
        %>

        // ----------------------------------------------------
        	
	function createWrk() {	  
	    window.open ("wrkedit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>"), "newwrkarea", "scrollbars=yes,width=700,height=520");
	}

        // ----------------------------------------------------
	
	function deleteWrk() {
	  var i;
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;

	  if (confirm("Are you sure you want to delete selected WorkAreas?")) {
	    chi.value = "";

	    frm.action = "wrkedit_delete.jsp";
	  
	    while (frm.elements[offset].type!="checkbox") offset++;
	    
	    for (i=0; i<jsWrks.length && i+offset<frm.elements.length; i++) {
                if (frm.elements[i+offset].checked)
                  chi.value += jsWrks[i] + ",";
	    } // next
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(checkeditems)
          } // fi (confirm)
	} // deleteWrk()

        // ----------------------------------------------------
	
	function modifyWrk(id,nm) {
	  window.open ("wrkedit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=" + id + "&n_workarea=" + escape(nm), "editwrkarea", "scrollbars=yes,width=700,height=520");
	}

        // ----------------------------------------------------

	function findWrk() {
	  var fnd = document.forms[0].find.value;
	  
	  if (hasForbiddenChars(fnd))
	    alert ("WorkArea name contains invalid characters");
	  else	
            window.location = "domwrks.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&maxrows=10&show=users&skip=0&find=" + escape(fnd);
	}

        // ----------------------------------------------------
	
	function showGrps() {
	  window.location = "domgrps.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=groups&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
	}

        // ----------------------------------------------------
	
	function showUsrs() {
	  window.location = "domusrs.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=users&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
	}	

        // ----------------------------------------------------
	
	function showDoms() {
	  window.location = "domdoms.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=domains&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
	}

    //-->    
  </SCRIPT>  
  <STYLE TYPE="text/css">
    <!--
      .tab { font-family: sans-serif; font-size: 12px; line-height:150%; font-weight: bold; position:absolute; text-align:center; border:2px; border-color:#999999; border-style:outset; border-bottom-style:none; width:90px; margin:0px; height: 30px; cursor: hand }
  
      .panel { font-family: sans-serif; font-size: 12px; position:absolute; border: 2px; border-color:#999999; border-style:outset; width: 520px; height: 296px; left:0px; top:28px; margin:0px; padding:6px; }
    -->
  </STYLE>
  <TITLE>hipergate :: Domain <%=n_domain%> - WorkAreas</TITLE>
</HEAD>

<BODY  TOPMARGIN="0" MARGINHEIGHT="0">  
    <TABLE><TR><TD WIDTH="520px" CLASS="striptitle"><FONT CLASS="title1">Domain<I><%=n_domain%></I> - WorkAreas</FONT></TD></TR></TABLE>  

    <BR><BR>
    <FORM NAME="frmusrs" METHOD="post">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="find" VALUE="<%=sFind%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=request.getParameter("maxrows")%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=request.getParameter("skip")%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
<%      if (!getCookie(request, "domainid", "").equals("1024")) { %>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR><TR><TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD><TD VALIGN="middle"><A HREF="#" onclick="createWrk()" CLASS="linkplain">New</A></TD><TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD><TD><A HREF="javascript:deleteWrk()" CLASS="linkplain">Delete</A></TD><TD>&nbsp;&nbsp;<TD><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0"></TD><TD><INPUT TYPE="text" NAME="find" MAXLENGTH="50"></TD><TD VALIGN="middle"><A HREF="javascript:findWrk()" CLASS="linkplain">Search</A></TD></TR><TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR></TABLE>
<% } %>
      <FONT CLASS="textplain">&nbsp;<B>View</B>&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="groups" onClick="showGrps()">Groups&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="users" onClick="showUsrs()">Users&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="workareas" CHECKED>WorkAreas
<% if (getCookie(request, "domainid", "").equals("1024") && bIsAdmin) { %>
      &nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="domains" onClick="showDoms()">Domains
<% } %>
      </FONT>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" WIDTH="220px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>&nbsp;Name&nbsp;</B></TD>
<%      if (getCookie(request, "domainid", "").equals("1024")  && bIsAdmin)
          out.write("<TD CLASS=\"tableheader\" BACKGROUND=\"../skins/" + sSkin + "/tablehead.gif\"><B>&nbsp;Domain&nbsp;</B></TD>");
%>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
        </TR>
<%      if (getCookie(request, "domainid", "").equals("1024") && bIsAdmin)
	  for (int i=0; i<iWrkCount; i++) {
            out.write ("<TR HEIGHT=\"14\"><TD CLASS=\"tabletd\">&nbsp;<A HREF=\"#\" onclick=\"modifyWrk('" + oWrks.getString(0,i) + "','" + oWrks.getString(1,i) + "')\" TITLE=\"Edit WorkArea\">" + oWrks.getString(1,i) + "</A></TD><TD CLASS=\"tabletd\">" + oWrks.getString(2,i) + "</TD>");
	    
	    if (sWorkArea.equals(oWrks.getString(0,i)))
              out.write ("<TD CLASS=\"tabletd\"></TD>");
	    else
              out.write ("<TD CLASS=\"tabletd\" ALIGN=\"middle\"><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"" + oWrks.getString(0,i) + "\"></TD>");

	    out.write ("</TR>");
          }
        else
	  for (int i=0; i<iWrkCount; i++) {
            out.write ("<TR HEIGHT=\"14\"><TD CLASS=\"tabletd\">&nbsp;<A HREF=\"#\" onclick=\"modifyWrk('" + oWrks.getString(0,i) + "','" + oWrks.getString(1,i) + "')\" TITLE=\"Edit WorkArea\">" + oWrks.getString(1,i) + "</A></TD>");

	    if (sWorkArea.equals(oWrks.getString(0,i)))
              out.write ("<TD CLASS=\"tabletd\"></TD>");
	    else
              out.write ("<TD CLASS=\"tabletd\" ALIGN=\"middle\"><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"" + oWrks.getString(0,i) + "\"></TD>");

	    out.write ("</TR>");
            
          }
%>          	  
      </TABLE>
    </FORM>
    <%
    if (iSkip>0)
      out.write("<A HREF=\"domwrks.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip-iMaxRows)+ "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;" + String.valueOf(iMaxRows) + "&nbsp;Previous " + "</A>&nbsp;&nbsp;&nbsp;");
        
    if (!oWrks.eof())
      out.write("<A HREF=\"domwrks.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip+iMaxRows)+ "\" CLASS=\"linkplain\">Next " + String.valueOf(iMaxRows) + "&nbsp;&gt;&gt;</A>");
    %>
</BODY>
</HTML>
