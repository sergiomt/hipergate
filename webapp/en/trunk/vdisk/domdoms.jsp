<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
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
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String sShow = request.getParameter("show");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  int iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
  int iSkip = Integer.parseInt(request.getParameter("skip"));
  int iDomCount = 0;
  DBSubset oDoms = new DBSubset (DB.k_domains, DB.id_domain + "," + DB.nm_domain, DB.nm_domain + " LIKE ?", iMaxRows);
  
  boolean bIsAdmin = false;
  
  ACLUser oUser;

  JDCConnection oConn = null;  

  Object[] aFind = { '%' + sFind + '%' };
  
  if (null==sShow) sShow = "groups";
    
  try {
    oConn = GlobalDBBind.getConnection("domdoms");
    
    oUser = new ACLUser (oConn, getCookie(request, "userid", ""));
     
    bIsAdmin = oUser.isDomainAdmin(oConn);
        
    if (sFind.length()==0) {
      oDoms = new DBSubset (DB.k_domains, DB.id_domain + "," + DB.nm_domain, "1=1", iMaxRows);
      oDoms.setMaxRows(iMaxRows);
      oDoms.load (oConn, iSkip);
    }
    else {
      oDoms.setMaxRows(iMaxRows);
      oDoms.load (oConn, aFind, iSkip);
    }
    
    iDomCount = oDoms.getRowCount();

    oConn.close("domdoms"); 
  }
  catch (SQLException e) {  
    oDoms = null;
    if (null!=oConn) oConn.close("domdoms");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));  
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
  
  if (!bIsAdmin) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Insufficient Priviledges&desc=You are not authorized to see this page&resume=../blank.htm"));  
    return;
  }  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        <%
          boolean bFirst = true;          
          out.write("var jsDoms = new Array(");
            for (int i=0; i<iDomCount; i++) {
                if (!bFirst) out.write(","); else bFirst=false;
                out.write("\"" + String.valueOf(oDoms.getInt(0,i)) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createDom() {	  
	  self.open ("domedit.jsp", "editdomain", "directories=no,toolbar=no,menubar=no,width=500,height=350");	  
	} // createDom()

        // ----------------------------------------------------
	
	function deleteDom() {
	  var i;
	  var offset = 0;	  
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;

	  if (confirm("Are you sure you want to delete selected domains?")) {
	  	  
	    chi.value = "";
	  	  
	    frm.action = "domedit_delete.jsp";

	    while (frm.elements[offset].type!="checkbox") offset++;
	  
	    for (i=0;i<jsDoms.length; i++) {
              if (frm.elements[i+offset].checked) {
                if (jsDoms[i]=="1024" || jsDoms[i]=="1025") {
                  alert ("SYSTEM and MODEL domains may not e deleted");
                  chi.value = "";
                  break;
                }
                chi.value += jsDoms[i] + ",";
	      }
	    }
	      
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(checkeditems)
          } // fi (confirm)
	} // deleteDom()

        // ----------------------------------------------------

	function findDom() {
	  var fnd = document.forms[0].find.value;
	  
	  if (hasForbiddenChars(fnd))
	    alert ("Domain name contains invalid characters");
	  else	
            window.location = "domdoms.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&maxrows=10&show=domains&skip=0&find=" + escape(fnd);
	}
	
        // ----------------------------------------------------

	function modifyDom(id,nm) {
	  self.open ("domedit.jsp?id_domain=" + id + "&n_domain=" + escape(nm), "editdomain", "directories=no,toolbar=no,menubar=no,width=500,height=350");
	}	

        // ----------------------------------------------------
	
	function showWrks() {
	  window.location = "domwrks.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=workareas&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
	}

        // ----------------------------------------------------
	
	function showGrps() {
	  window.location = "domgrps.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=groups&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
	}

        // ----------------------------------------------------
	
	function showUsrs() {
	  window.location = "domusrs.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=users&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
	}	
	
    //-->    
  </SCRIPT>  
  <STYLE TYPE="text/css">
    <!--
      .tab { font-family: sans-serif; font-size: 12px; line-height:150%; font-weight: bold; position:absolute; text-align:center; border:2px; border-color:#999999; border-style:outset; border-bottom-style:none; width:90px; margin:0px; height: 30px; cursor: hand }
      .panel { font-family: sans-serif; font-size: 12px; position:absolute; border: 2px; border-color:#999999; border-style:outset; width: 520px; height: 296px; left:0px; top:28px; margin:0px; padding:6px; }
    -->
  </STYLE>
  <TITLE>hipergate :: Domains</TITLE>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0">
    <TABLE><TR><TD WIDTH="520px" CLASS="striptitle"><FONT CLASS="title1">Domains</FONT></TD></TR></TABLE>  
    <FORM NAME="frmdoms" METHOD="post">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=request.getParameter("maxrows")%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=request.getParameter("skip")%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR><TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD><TD VALIGN="middle"><A HREF="#" onclick="createDom()" CLASS="linkplain">New</A></TD><TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" HEIGHT="16" BORDER="0" ALT="Delete"></TD><TD><A HREF="javascript:deleteDom()" CLASS="linkplain">Delete</A></TD><TD>&nbsp;&nbsp;<TD><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD><TD><INPUT TYPE="text" NAME="find" VALUE="<%=sFind%>" MAXLENGTH="50"></TD><TD VALIGN="middle"><A HREF="javascript:findDom()" CLASS="linkplain">Search</A></TD></TR>
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <FONT CLASS="textplain">&nbsp;<B>View</B>&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="groups">Groups&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="users" onClick="showUsrs()">Users&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="workareas" onClick="showWrks()">WorkAreas&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="domains" CHECKED>Domains</FONT>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" WIDTH="100px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Domain</B></TD>
          <TD CLASS="tableheader" WIDTH="300px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
        </TR>
	<%
	  String sDomId;
	  int iDomId;
	  
	  for (int i=0; i<iDomCount; i++) {
            
            iDomId = oDoms.getInt(0,i);
            sDomId = String.valueOf (iDomId);
            
            out.write ("<TR HEIGHT=\"14\">");
            out.write ("<TD CLASS=\"tabletd\" WIDTH=\"100px\">&nbsp;<A HREF=\"#\" onclick=\"modifyDom('" + sDomId + "','" + oDoms.getString(1,i) + "')\" TITLE=\"Edit this domain\">" + sDomId + "</A></TD><TD CLASS=\"tabletd\">&nbsp;" + oDoms.getString(1,i) + "</TD>");
            
            out.write ("<TD CLASS=\"tabletd\" ALIGN=\"center\"><INPUT VALUE=\"1\" TYPE=\"checkbox\" NAME=\"D" + sDomId + "\"></TD>");
            
            out.write ("</TR>");
          }
	%>          	  
      </TABLE>
    </FORM>
    <%
    if (iSkip>0)
      out.write("<A HREF=\"domdoms.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip-iMaxRows)+ "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;" + String.valueOf(iMaxRows) + "&nbsp;Previous " + "</A>&nbsp;&nbsp;&nbsp;");
    
    if (!oDoms.eof())
      out.write("<A HREF=\"domdoms.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip+iMaxRows)+ "\" CLASS=\"linkplain\">Next " + String.valueOf(iMaxRows) + "&nbsp;&gt;&gt;</A>");
    %>
</BODY>
</HTML>
