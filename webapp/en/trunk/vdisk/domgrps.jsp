<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
  String sLanguage = getNavigatorLanguage(request);
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String sShow = request.getParameter("show");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  int iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
  int iSkip = Integer.parseInt(request.getParameter("skip"));
  int iGrpCount = 0;
  DBSubset oGrps;
  
  boolean bIsAdmin = false;
  
  ACLDomain oDom = new ACLDomain();
  ACLUser oUser;

  JDCConnection oConn = null;  

  Object[] aFind = { '%' + sFind + '%' };
  
  if (null==sShow) sShow = "groups";
    
  try {
    oConn = GlobalDBBind.getConnection("domgrps");
    
    oDom.load(oConn, new Object[]{new Integer(id_domain)}); 

    oUser = new ACLUser (oConn, getCookie(request, "userid", ""));
     
    bIsAdmin = oUser.isDomainAdmin(oConn);
    
    if (!bIsAdmin) {
      throw new SQLException("Administrator role is required for listing groups", "28000", 28000);
    }
    
    if (sFind.length()==0) {
      oGrps = new DBSubset (DB.k_acl_groups + " g, " + DB.k_domains + " d",
                            "g." + DB.gu_acl_group + ",g." + DB.nm_acl_group + ",g." + DB.de_acl_group + ",d." + DB.gu_admins,
                            "g." + DB.id_domain + "=d." + DB.id_domain + " AND d." + DB.id_domain + "=" + id_domain, iMaxRows);
      oGrps.setMaxRows(iMaxRows);
      oGrps.load (oConn, iSkip);
    }
    else {
      oGrps = new DBSubset (DB.k_acl_groups + " g, " + DB.k_domains + " d",
      			    "g." + DB.gu_acl_group + ",g." + DB.nm_acl_group + ",g." + DB.de_acl_group + ",d." + DB.gu_admins,
      			    "g." + DB.id_domain + "=d." + DB.id_domain + " AND d." + DB.id_domain + "=" + id_domain + " AND " + DB.nm_acl_group + " LIKE ?", iMaxRows);
      oGrps.setMaxRows(iMaxRows);
      oGrps.load (oConn, aFind, iSkip);
    }
    
    iGrpCount = oGrps.getRowCount();

    oConn.close("domgrps"); 
  }
  catch (SQLException e) {  
    oGrps = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("domgrps");
    oConn = null;  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=../blank.htm"));  
  }  
  catch (NumberFormatException e) {
    oGrps = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("domgrps");
    oConn = null;  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=../blank.htm"));  
  }  
  catch (IllegalStateException e) {
    oGrps = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("domgrps");
    oConn = null;  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=../blank.htm"));  
  }
  catch (NullPointerException e) {
    oGrps = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("domgrps");
    oConn = null;  
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
          // [~//Escribir los nombres de grupos y usuarios en Arrays JavaScript~]
          // [~//Estos arrays se usan en las llamadas de borrado múltiple.~]

          boolean bFirst = true;          
          out.write("var jsGrps = new Array(");
            for (int i=0; i<iGrpCount; i++) {
              if (!oGrps.getString(0,i).equals(oGrps.get(3,i))) {
                if (!bFirst) out.write(","); else bFirst=false;
                out.write("\"" + oGrps.getString(0,i) + "\"");
              }
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createGrp() {
	  if (<%=id_domain%>==1024 || <%=id_domain%>==1025)
	    alert ("It is not allowed to create new groups for SYSTEM and MODEL domains");
	  else
	    self.open ("grpedit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>"), "editgroup", "directories=no,toolbar=no,menubar=no,width=600,height=520");	  
	} // createGrp()

        // ----------------------------------------------------
	
	function deleteGrp() {
	  var i;
	  var offset = 0;	  
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;

	  if (confirm("Are you sure you want to delete selected groups?")) {
	  	  
	    chi.value = "";
	  	  
	    frm.action = "grpedit_delete.jsp";

	    while (frm.elements[offset].type!="checkbox") offset++;
	  
	    for (i=0;i<jsGrps.length; i++)
              if (frm.elements[i+offset].checked)
                chi.value += jsGrps[i] + ",";
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(checkeditems)
          } // fi (confirm)
	} // deleteGrp()

        // ----------------------------------------------------

	function findGrp() {
	  var fnd = document.forms[0].find.value;
	  
	  if (hasForbiddenChars(fnd))
	    alert ("Group name contains invalid characters");
	  else	
            window.location = "domgrps.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&maxrows=10&show=groups&skip=0&find=" + escape(fnd);
	}
	
        // ----------------------------------------------------

	function modifyGrp(id,nm) {
	  self.open ("grpedit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_acl_group=" + id + "&n_acl_group=" + escape(nm), "editgroup", "directories=no,toolbar=no,menubar=no,width=600,height=520");
	}	

        // ----------------------------------------------------
	
	function showWrks() {
	  window.location = "domwrks.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=workareas&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
	}

        // ----------------------------------------------------
	
	function showDoms() {
	  window.location = "domdoms.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=domains&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
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
  <TITLE>hipergate :: Domain <%=n_domain%> - Groups</TITLE>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0">
    <TABLE><TR><TD WIDTH="520px" CLASS="striptitle"><FONT CLASS="title1">Domain <I><%=n_domain%></I> - Groups</FONT></TD></TR></TABLE>  
    <FORM NAME="frmgrps" METHOD="post">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=request.getParameter("maxrows")%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=request.getParameter("skip")%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR><TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD><TD VALIGN="middle"><A HREF="#" onclick="createGrp()" CLASS="linkplain">New</A></TD><TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" HEIGHT="16" BORDER="0" ALT="Delete"></TD><TD><A HREF="#" onclick="deleteGrp()" CLASS="linkplain">Delete</A></TD><TD>&nbsp;&nbsp;<TD><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD><TD><INPUT TYPE="text" NAME="find" VALUE="<%=sFind%>" MAXLENGTH="50"></TD><TD VALIGN="middle"><A HREF="javascript:findGrp()" CLASS="linkplain">Search</A></TD></TR>
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <FONT CLASS="textplain">&nbsp;<B>Ver</B>&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="groups" CHECKED>Groups&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="users" onClick="showUsrs()">Users&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="workareas" onClick="showWrks()">WorkAreas
<% if (id_domain.equals("1024") && bIsAdmin) { %>
      &nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="domains" onClick="showDoms()">Domains
<% } %>
      </FONT>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" WIDTH="250" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" WIDTH="400" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Description</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
        </TR>
	<%
	  String sAdmin = oDom.getStringNull(DB.gu_admins,"");
	  
	  String sGrpId;
	  
	  for (int i=0; i<iGrpCount; i++) {
            sGrpId = oGrps.getString(0,i);
            out.write ("<TR HEIGHT=\"14\">");

	    if (sGrpId.equals(sAdmin))
              out.write ("<TD CLASS=\"tabletd\">&nbsp;<A HREF=\"#\" onclick=\"modifyGrp('" + sGrpId + "','" + oGrps.getString(1,i) + "')\" TITLE=\"Members of this group are the domain administrators\">" + oGrps.getString(1,i) + "</A><FONT CLASS=\"textplain\">&nbsp;*</FONT></TD><TD CLASS=\"tabletd\">&nbsp;" + Gadgets.left(oGrps.getStringNull(2,i,""),64) + (oGrps.getStringNull(2,i,"").length()>64 ? "..." : "") + "</TD>");
            else
              out.write ("<TD CLASS=\"tabletd\">&nbsp;<A HREF=\"#\" onclick=\"modifyGrp('" + sGrpId + "','" + oGrps.getString(1,i) + "')\" TITLE=\"Edit this group\">" + oGrps.getString(1,i) + "</A></TD><TD CLASS=\"tabletd\">&nbsp;" + Gadgets.left(oGrps.getStringNull(2,i,""),64) + (oGrps.getStringNull(2,i,"").length()>64 ? "..." : "") + "</TD>");

            if (sGrpId.equals(oGrps.get(3,i)))
              out.write ("<TD CLASS=\"tabletd\"></TD>");
            else
              out.write ("<TD CLASS=\"tabletd\" ALIGN=\"center\"><INPUT VALUE=\"1\" TYPE=\"checkbox\" NAME=\"" + sGrpId + "\">");
            out.write ("</TR>");
          }
	%>          	  
      </TABLE>
    </FORM>
    <%
    if (iSkip>0)
      out.write("<A HREF=\"domgrps.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip-iMaxRows)+ "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;" + String.valueOf(iMaxRows) + "&nbsp;Previous " + "</A>&nbsp;&nbsp;&nbsp;");
    
    if (!oGrps.eof())
      out.write("<A HREF=\"domgrps.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip+iMaxRows)+ "\" CLASS=\"linkplain\">Next " + String.valueOf(iMaxRows) + "&nbsp;&gt;&gt;</A>");
    %>
</BODY>
</HTML>
