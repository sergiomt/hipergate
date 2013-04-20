<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String sShow = request.getParameter("show");  
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sGroup = request.getParameter("group")==null ? "" : request.getParameter("group");
  int iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
  int iSkip = Integer.parseInt(request.getParameter("skip"));
  int iUsrCount = 0;
  int iGrpCount = 0;
  DBSubset oUsrs, oGrps=null;
  
  boolean bIsAdmin = false;
  
  ACLUser oUser;
    
  JDCConnection oConn = null;

  Object[] aFind = { '%' + sFind + '%', '%' + sFind + '%', '%' + sFind + '%', '%' + sFind + '%', '%' + sFind + '%' };
  
  if (null==sShow) sShow = "users";
  
  try {

    oConn = GlobalDBBind.getConnection("domusrs");  

    oUser = new ACLUser (oConn, getCookie(request, "userid", ""));

    bIsAdmin = oUser.isDomainAdmin(oConn);
    
    if (!bIsAdmin) {
      throw new SQLException("Administrator role is required for listing users", "28000", 28000);
    }

    oGrps = new DBSubset (DB.k_acl_groups + " g, " + DB.k_domains + " d",
                            "g." + DB.gu_acl_group + ",g." + DB.nm_acl_group + ",g." + DB.de_acl_group + ",d." + DB.gu_admins,
                            "g." + DB.id_domain + "=d." + DB.id_domain + " AND d." + DB.id_domain + "=" + id_domain, 100);
    iGrpCount = oGrps.load (oConn, iSkip);

    if (sFind.length()==0) {
      if (sGroup.length()==0)
        oUsrs = new DBSubset (DB.k_users + " u, " + DB.k_domains + " d",
      			                  "u." + DB.gu_user + ",u." + DB.tx_nickname + ",u." + DB.nm_user + ",u." + DB.tx_surname1 + ",u." + DB.tx_surname2 + ",d." + DB.gu_owner,
                              "u." + DB.id_domain + "=d." + DB.id_domain + " AND d." + DB.id_domain + "=" + id_domain, iMaxRows);
      else
        oUsrs = new DBSubset (DB.k_users + " u, " + DB.k_domains + " d," + DB.k_x_group_user + " g",
      			                  "u." + DB.gu_user + ",u." + DB.tx_nickname + ",u." + DB.nm_user + ",u." + DB.tx_surname1 + ",u." + DB.tx_surname2 + ",d." + DB.gu_owner,
                              "u." + DB.gu_user + "=g." + DB.gu_user + " AND g." + DB.gu_acl_group + "='" + sGroup + "' AND " +
                              "u." + DB.id_domain + "=d." + DB.id_domain + " AND d." + DB.id_domain + "=" + id_domain, iMaxRows);
      	
      oUsrs.setMaxRows(iMaxRows);
      oUsrs.load (oConn, iSkip);
    }
    else {
      if (sGroup.length()==0)
        oUsrs = new DBSubset (DB.k_users + " u, " + DB.k_domains + " d",
      			                  "u." + DB.gu_user + ",u." + DB.tx_nickname + ",u." + DB.nm_user + ",u." + DB.tx_surname1 + ",u." + DB.tx_surname2 + ",d." + DB.gu_owner,
                              "u." + DB.id_domain + "=d." + DB.id_domain + " AND d." + DB.id_domain + "=" + id_domain + " AND (" + DB.nm_user + " LIKE ? OR " + DB.tx_surname1 + " LIKE ? OR " + DB.tx_surname2 + " LIKE ? OR " + DB.tx_nickname + " LIKE ? OR " + DB.tx_main_email + " LIKE ?)", iMaxRows);    
      else
        oUsrs = new DBSubset (DB.k_users + " u, " + DB.k_domains + " d," + DB.k_x_group_user + " g",
      			                  "u." + DB.gu_user + ",u." + DB.tx_nickname + ",u." + DB.nm_user + ",u." + DB.tx_surname1 + ",u." + DB.tx_surname2 + ",d." + DB.gu_owner,
                              "u." + DB.gu_user + "=g." + DB.gu_user + " AND g." + DB.gu_acl_group + "='" + sGroup + "' AND " +
                              "u." + DB.id_domain + "=d." + DB.id_domain + " AND d." + DB.id_domain + "=" + id_domain + " AND (" + DB.nm_user + " LIKE ? OR " + DB.tx_surname1 + " LIKE ? OR " + DB.tx_surname2 + " LIKE ? OR " + DB.tx_nickname + " LIKE ? OR " + DB.tx_main_email + " LIKE ?)", iMaxRows);    
      	
      oUsrs.setMaxRows(iMaxRows);
      oUsrs.load (oConn, aFind, iSkip);
    }
        
    iUsrCount = oUsrs.getRowCount();

    oConn.close("domusrs"); 
  }
  catch (SQLException e) {
    oUsrs = null; 
    if (null!=oConn) oConn.close("domusrs");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));      
  }
  catch (IllegalStateException e) {
    oUsrs = null; 
    if (oConn!=null) oConn.close("domwrks");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=../blank.htm"));         
  }
  catch (NullPointerException e) {
    oUsrs = null; 
    if (oConn!=null) oConn.close("domwrks");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=../blank.htm"));         
  }

  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        <%
          
          boolean bFirst = true;
          out.write("var jsUsrs = new Array(");
            for (int i=0; i<iUsrCount; i++) {
              if (!oUsrs.getString(0,i).equals(oUsrs.get(5,i))) {
                if (!bFirst) out.write(","); else bFirst=false;
                out.write("\"" + oUsrs.getString(0,i) + "\"");
              }
            }
          out.write(");\n");
        %>

        // ----------------------------------------------------
        	
	function createUsr() {
	  if (<%=id_domain%>==1024 || <%=id_domain%>==1025)
	    alert ("It is not allowed to create new usersSYSTEM and MODEL domains");
	  else
	    window.open ("usredit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>"), "edituser", "directories=no,toolbar=no,menubar=no,width=640,height=600");
	}

        // ----------------------------------------------------
        	
	function createUsrRange() {
	  if (<%=id_domain%>==1024 || <%=id_domain%>==1025)
	    alert ("It is not allowed to create new usersSYSTEM and MODEL domains");
	  else	
	    window.open ("usrrange.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>"), "createusrrange", "directories=no,toolbar=no,menubar=no,width=600,height=600");
	}

        // ----------------------------------------------------
	
	function deleteUsr() {
	  var i;
	  var offset = 0;	  
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;

	  if (confirm("Are you sure you want to delete selected users?")) {
	  	  	  
	    chi.value = "";

	    frm.action = "usredit_delete.jsp";
	  
	    while (frm.elements[offset].type!="checkbox") offset++;
	  	  	  	  
	    for (i=0;i<jsUsrs.length; i++)
              if (frm.elements[i+offset].checked)
                chi.value += jsUsrs[i] + ",";
	   
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(checkeditems)
          } // fi (confirm)
	} // deleteUsr()

        // ----------------------------------------------------
	
	function modifyUsr(id) {
	  self.open ("usredit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_user=" + id, "edituser", "directories=no,toolbar=no,menubar=no,width=600,height=600");
	}

        // ----------------------------------------------------

	function findUsr() {
	  var fnd = document.forms[0].find.value;
	  var grp = document.forms[0].group.value;
	  
	  if (hasForbiddenChars(fnd))
	    alert ("User name contains invalid characters");
	  else	
            window.location = "domusrs.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&maxrows=10&show=users&skip=0&find=" + escape(fnd) + "&group=" + grp;
	}

        // ----------------------------------------------------
	
	function showGrps() {
	  window.location = "domgrps.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=groups&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
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
    
    	function importTXT() {          
      	  var w = window.open("userloader1.jsp?id_domain=<%=id_domain%>","userloader","menubar=no,toolbar=no,resizable=yes,scrollbars=yes,status=yes,height=460,width=490");
      	  w.focus();
    	}

    //-->    

  </SCRIPT>  
  <SCRIPT TYPE="text/javascript">
  	<!--
  	  function setCombos() {
	      document.forms[0].find.value = "<%=sFind%>";
	      setCombo(document.forms[0].group, "<%=sGroup%>");  	    
  	  }
  	//-->
  </SCRIPT>  
  <STYLE TYPE="text/css">
    <!--
      .tab { font-family: sans-serif; font-size: 12px; line-height:150%; font-weight: bold; position:absolute; text-align:center; border:2px; border-color:#999999; border-style:outset; border-bottom-style:none; width:90px; margin:0px; height: 30px; cursor: hand }
  
      .panel { font-family: sans-serif; font-size: 12px; position:absolute; border: 2px; border-color:#999999; border-style:outset; width: 520px; height: 296px; left:0px; top:28px; margin:0px; padding:6px; }
    -->
  </STYLE>
  <TITLE>hipergate :: Domain <%=n_domain%> - Users</TITLE>
</HEAD>

<BODY TOPMARGIN="0" MARGINHEIGHT="0" onload="setCombos()">  
    <TABLE><TR><TD WIDTH="520px" CLASS="striptitle"><FONT CLASS="title1">Domain <I><%=n_domain%></I> - Users</FONT></TD></TR></TABLE>  
    <FORM NAME="frmusrs" METHOD="post">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=request.getParameter("maxrows")%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=request.getParameter("skip")%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD VALIGN="middle">&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
          <TD VALIGN="middle"><A HREF="#" onclick="createUsr()" CLASS="linkplain">New</A></TD>
          <TD VALIGN="middle">&nbsp;&nbsp;&nbsp;<A HREF="#" onclick="createUsrRange();" CLASS="linkplain" TITLE="New User Range">New Range</A></TD>
          <TD VALIGN="middle">&nbsp;&nbsp;&nbsp;<A HREF="#" onclick="importTXT();" CLASS="linkplain" TITLE="Import from a text file">Import from a text file</A></TD>
          <TD VALIGN="middle">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
          <TD VALIGN="middle"><A HREF="javascript:deleteUsr()" CLASS="linkplain">Delete</A></TD>
        </TR>
        <TR>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0"></TD>
          <TD COLSPAN="2">
            <INPUT TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=nullif(request.getParameter("find"))%>">          
          </TD>
          <TD>
				    &nbsp;&nbsp;&nbsp;<SELECT NAME="group"><OPTION VALUE=""></OPTION><OPTGROUP LABEL="Group"><% for (int g=0; g<iGrpCount; g++) out.write("<OPTION VALUE="+oGrps.getString(DB.gu_acl_group,g)+">"+oGrps.getString(DB.nm_acl_group,g)+"</OPTION>"); %></OPTGROUP></SELECT>
				  </TD>
          <TD ALIGN="left" VALIGN="middle" COLSPAN="2"><A HREF="javascript:findUsr()" CLASS="linkplain">Search</A></TD>
        </TR>

        <TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR></TABLE>
      <FONT CLASS="textplain">&nbsp;<B>Ver</B>&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="groups" onClick="showGrps()">Groups&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="users" CHECKED>Users&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="workareas" onClick="showWrks()">WorkAreas
<% if (id_domain.equals("1024") && bIsAdmin) { %>
      &nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" VALUE="domains" onClick="showDoms()">Domains
<% } %>
      </FONT>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" WIDTH="250" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Alias</B></TD>
          <TD CLASS="tableheader" WIDTH="400" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Full Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
        </TR>
<%
	  String sUserId;
	  for (int i=0; i<iUsrCount; i++) {
	    sUserId = oUsrs.getString(0,i);
            out.write ("<TR HEIGHT=\"14\">");
            out.write ("<TD CLASS=\"tabletd\">&nbsp;<A HREF=\"#\" onclick=\"modifyUsr('" + sUserId + "')\" TITLE=\"Edit this user\">" + oUsrs.getString(1,i) + "</A></TD><TD CLASS=\"tabletd\">&nbsp;" + oUsrs.getStringNull(2,i,"") + "&nbsp;" + oUsrs.getStringNull(3,i,"") + "&nbsp;" + oUsrs.getStringNull(4,i,"") + "</TD>");
            if (sUserId.equals(oUsrs.get(5,i)))
              out.write ("<TD CLASS=\"tabletd\"></TD>");
            else
              out.write ("<TD CLASS=\"tabletd\" ALIGN=\"middle\"><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"" + sUserId + "\">");
            out.write ("</TR>");
          }
	%>          	  
      </TABLE>
    </FORM>
    <%
    if (iSkip>0)
      out.write("<A HREF=\"domusrs.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip-iMaxRows)+ "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;" + String.valueOf(iMaxRows) + "&nbsp;Previous " + "</A>&nbsp;&nbsp;&nbsp;");
        
    if (!oUsrs.eof())
      out.write("<A HREF=\"domusrs.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&maxrows=" + String.valueOf(iMaxRows) + "&skip=" + String.valueOf(iSkip+iMaxRows)+ "\" CLASS=\"linkplain\">Next " + String.valueOf(iMaxRows) + "&nbsp;&gt;&gt;</A>");
    %>
    
</BODY>
</HTML>
