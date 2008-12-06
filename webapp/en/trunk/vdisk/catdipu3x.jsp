<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.sql.ResultSet,java.sql.PreparedStatement,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
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
  
  String sSkin = getCookie(request, "skin", "xp");
  String sUserId = getCookie(request, "userid", "");   
  String sDomainId = getCookie(request, "domainid", "");
  String sDomainNm = getCookie(request, "domainnm", "");
  String sLanguage = getNavigatorLanguage(request);
  String sParentId;
  String sError = null;
  String sDomainShared;
  
  if (sUserId.length()==0 || sDomainId.length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=Domain or User Cookies not set&resume=_back"));
  }
  boolean bIsGuest = isDomainGuest (GlobalDBBind, request, response);
%>
  <!-- +---------------------------------------------+ -->
  <!-- | Página HTML para mostrar el applet DipuTree | -->
  <!-- | JavaScript compatible con DipuTree v3.x     | -->  
  <!-- | © KnowGate 2001                             | -->
  <!-- +---------------------------------------------+ -->  

<HTML LANG="<% out.write(sLanguage); %>">

<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/defined.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/catdipu3x.js"></SCRIPT>
</HEAD>

<BODY ID="pagebody"  LEFTMARGIN="4" RIGHTMARGIN="0" TOPMARGIN="0" MARGINWIDTH="4" MARGINHEIGHT="0" SCROLL="no">

  <TABLE CELLSPACING="2" CELLPADDING="0" BORDER="0">
    <TR VALIGN="middle">
      <TD ALIGN="center" VALIGN="middle"><IMG SRC="../images/images/newfolder16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Category"><BR><A HREF="#" onclick="createCategory()" CLASS="linkplain">New</A></TD>
      <TD WIDTH="8"></TD>
      <TD ALIGN="center" VALIGN="middle">
        <IMG SRC="../images/images/deletefolder.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Category"><BR>
<% if (bIsGuest) { %>
        <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
        <A HREF="#" onclick="deleteCategory()" CLASS="linkplain">Delete</A>
<% } %>
      </TD>
      <TD WIDTH="8"></TD>
      <TD ALIGN="center" VALIGN="middle"><IMG SRC="../images/images/folderoptions.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Edit Category"><BR><A HREF="#" onclick="modifyCategory()" CLASS="linkplain">Edit</A></TD>
      <TD WIDTH="8"></TD>
      <TD ALIGN="center" VALIGN="middle"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Find Category"><BR><A HREF="#" onclick="searchFile()" CLASS="linkplain">Search</A></TD>
    </TR>
  </TABLE>  
  <!-- <DIV STYLE="position:relative;top:-12px"> -->
  <FORM style="margin:0;padding:0">
    <TABLE BORDER="2" CELLSPACING="0" CELLPADDING="0">
      <TR>
        <TD>
          <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
            <TR VALIGN="middle">            
              <TD><INPUT CLASS="textmini" TYPE="text" MAXLENGTH="50" STYLE="width:250px" NAME="catname"></TD>
              <TD><A HREF="javascript:showFiles()"><IMG SRC="../images/images/refresh.gif" HSPACE="2" WIDTH="13" HEIGHT="16" BORDER="0" ALT="View Files & Links"></A></TD>
            </TR>
          </TABLE>
        </TD>
      </TR>
      <TR><TD WIDTH="280">
        <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">        
          <!--
            var appletheight;
            switch (screen.height) {
              case 600:
                appletheight = "256"; break;
              case 768:
                appletheight = "400"; break;
              case 864:
                appletheight = "460"; break;
              case 960:
                appletheight = "540"; break;
              default:
                appletheight = String(Math.floor(286*1.15*(screen.height/600))-80);
            }            
            document.write ('        <APPLET NAME="diputree" CODE="diputree.class" ARCHIVE="diputree3.jar" CODEBASE="../applets" WIDTH="260" HEIGHT="' + appletheight + '" MAYSCRIPT>');
	  //-->
	</SCRIPT>
<%    if (sDomainId.equals("1024")) { sParentId = ""; %>
	<PARAM NAME="xmlsource" VALUE="pickchilds.jsp?Skin=<%=sSkin%>&Lang=<%=sLanguage%>&Uid=<%=sUserId%>">
<%    } else if (sDomainId.equals("1025")) { sParentId = ""; %>
	<PARAM NAME="xmlsource" VALUE="pickchilds.jsp?Skin=<%=sSkin%>&Lang=<%=sLanguage%>&Parent=ecd80abbb4b24668aa75d45a58c830a6&Label=root&Uid=<%=sUserId%>">
<%    } else {
	JDCConnection oConn = null;
	PreparedStatement oStmt;
	ResultSet oRSet;
	int iDomainId;
	String sSQL;
	
	try {
	  iDomainId = Integer.parseInt(sDomainId);

	  oConn = GlobalDBBind.getConnection("catdipu3x");
		
	  sSQL = "SELECT " +  DB.gu_category + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?";
	  
	  if (DebugFile.trace)
	    DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

	  oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  
	  oStmt.setString(1,sUserId);
	  	  
	  oRSet = oStmt.executeQuery();

	  if (oRSet.next())
	    sParentId = oRSet.getString(1);
	  else
	    sParentId = "000000000000000000000000000000000";

	  oRSet.close();
	  oRSet = null;
	  oStmt.close();
	  oStmt = null;
          
	  oConn.close("catdipu3x");
	  oConn = null;
	}
  	catch (NumberFormatException e) {
    	  sError = "NumberFormatException " + sDomainId;
	  sParentId = "000000000000000000000000000000000";
  	}
	catch (SQLException sqle) {
    	  if (oConn!=null)
      	    if (!oConn.isClosed()) oConn.close("catdipu3x");
    	  oConn = null;
    	  sError = "SQLException " + sqle.getMessage();
	  sParentId = "000000000000000000000000000000000";
	}
%>
	<PARAM NAME="xmlsource" VALUE="pickchilds.jsp?Skin=<%=sSkin%>&Lang=<%=sLanguage%>&Parent=<%=sParentId%>&Label=root&Uid=<%=sUserId%>">
<%    } %>	
        </APPLET></TD></TR>
    </TABLE>
  </FORM>      
  <!-- </DIV> -->
</BODY>
<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">        
  <!--
    g_defaultparent = "<%=sParentId%>";
<% if (null!=sError)
     out.write("    window.parent.parent.cadmframe.catadmin.location.href = \"../common/errmsg.jsp?title=SQLException&desc=" + Gadgets.URLEncode(sError) + "&resume=_close\";\n");
%>
  //-->
</SCRIPT>
</HTML>
