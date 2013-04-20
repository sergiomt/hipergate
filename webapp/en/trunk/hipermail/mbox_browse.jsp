<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Category,com.knowgate.hipergate.Categories" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<jsp:useBean id="GlobalCategories" scope="application" class="com.knowgate.hipergate.Categories"/><% 
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

  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sSkin = getCookie(request, "skin", "xp");
      
  String id_user = getCookie (request, "userid", null);
  String id_language = getNavigatorLanguage(request);
  String gu_target = request.getParameter("gu_target");
  String gu_category = request.getParameter("gu_category");
  String gu_parent = null;
  
  boolean bCanBrowseUp = false;
  HashMap oIcons = null;
  JDCConnection oConn = null;  
  PreparedStatement oStmt = null;
  DBSubset oSubCats = null;

  DBSubset oProds = new DBSubset (DB.k_products + " p, " + DB.k_prod_locats + " l, " + DB.k_x_cat_objs + " x",
  			  	  "p." + DB.gu_product +",p." + DB.nm_product + ",p." + DB.de_product + ",p." + DB.dt_modified +
  			  	  ",l." + DB.xprotocol + DBBind.Functions.CONCAT + "l." + DB.xhost + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(l." + DB.xpath + ",'')" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(l." + DB.xanchor + ",'') AS full_path, l." +
  			  	  DB.id_cont_type + "," + DB.len_file + ",l." + DB.gu_location + ",l." + DB.id_prod_type + ",l." + DB.xfile,
  			  	  "p." + DB.gu_product + "=x." + DB.gu_object + " AND l." + DB.gu_product + "=x." + DB.gu_object + " AND x." + DB.gu_category + " = ? AND x." + DB.id_class + "=15 AND (l." + DB.status + "<>3 OR l." + DB.status + " IS NULL)", 100);

  try {
    oConn = GlobalDBBind.getConnection("browseusercategories");

    oIcons = (HashMap) GlobalCacheClient.get("k_lu_prod_types");

    if (oIcons==null) {
      oIcons = new HashMap(200);
      
      DBSubset oProdTypes = new DBSubset (DB.k_lu_prod_types, DB.id_prod_type + "," + DB.nm_icon, DB.nm_icon + " IS NOT NULL", 200);
      oProdTypes.load(oConn);
      int iTypeCount = oProdTypes.getRowCount();
      
      for (int t=0; t<iTypeCount; t++)
        oIcons.put (oProdTypes.getString(0,t), oProdTypes.getString(1,t));
      
      GlobalCacheClient.put("k_lu_prod_types", oIcons);
    } // fi (oIcons)

    ACLUser oMe = new ACLUser();
    oMe.load(oConn, new Object[]{id_user});
    
    if (null==gu_category) {
      oSubCats = GlobalCategories.getChildsNamed(oConn, oMe.getString(DB.gu_category), id_language, Categories.ORDER_BY_LOCALE_NAME);
    }
    else {
      oStmt = oConn.prepareStatement("SELECT "+DB.gu_parent_cat+" FROM " +DB.k_cat_tree+" WHERE "+DB.gu_child_cat+"=?");
      oStmt.setString(1,gu_category);
      ResultSet oRSet = oStmt.executeQuery();
      if (oRSet.next())
        gu_parent = oRSet.getString(1);
      oRSet.close();
      oStmt.close();
      oStmt = null ;
      
      oSubCats = GlobalCategories.getChildsNamed(oConn, gu_category, id_language, Categories.ORDER_BY_LOCALE_NAME);    
    }
    
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
      oProds = new DBSubset (DB.k_products + " p, " + DB.k_prod_locats + " l, " + DB.k_x_cat_objs + " x",
  			     "p." + DB.gu_product +",p." + DB.nm_product + ",p." + DB.de_product + ",p." + DB.dt_modified +
  			     ",CONCAT(l." + DB.xprotocol + ",l." + DB.xhost + ",COALESCE(l." + DB.xpath + ",''),COALESCE(l." + DB.xanchor + ",'')) AS full_path, l." +
  			     DB.id_cont_type + "," + DB.len_file + ",l." + DB.gu_location + ",l." + DB.id_prod_type + ",l." + DB.xfile,
  			     "p." + DB.gu_product + "=x." + DB.gu_object + " AND l." + DB.gu_product + "=x." + DB.gu_object + " AND x." + DB.gu_category + " = ? AND x." + DB.id_class + "=15 AND (l." + DB.status + "<>3 OR l." + DB.status + " IS NULL)", 100);
    else
      oProds = new DBSubset (DB.k_products + " p, " + DB.k_prod_locats + " l, " + DB.k_x_cat_objs + " x",
  			     "p." + DB.gu_product +",p." + DB.nm_product + ",p." + DB.de_product + ",p." + DB.dt_modified +
  			     ",l." + DB.xprotocol + DBBind.Functions.CONCAT + "l." + DB.xhost + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(l." + DB.xpath + ",'')" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(l." + DB.xanchor + ",'') AS full_path, l." +
  			     DB.id_cont_type + "," + DB.len_file + ",l." + DB.gu_location + ",l." + DB.id_prod_type + ",l." + DB.xfile,
  			     "p." + DB.gu_product + "=x." + DB.gu_object + " AND l." + DB.gu_product + "=x." + DB.gu_object + " AND x." + DB.gu_category + " = ? AND x." + DB.id_class + "=15 AND (l." + DB.status + "<>3 OR l." + DB.status + " IS NULL)", 100);

    oProds.load(oConn, new Object[]{gu_category==null ? oMe.getString(DB.gu_category) : gu_category});
    
    if (null!=gu_parent && !oMe.getStringNull(DB.gu_category, "null").equals(gu_category)) {
      int iPerms =  new Category(gu_parent).getUserPermissions(oConn, id_user);
      bCanBrowseUp = ((iPerms&ACL.PERMISSION_LIST)!=0);
    }
    
    oConn.close("browseusercategories");
  }
  catch (SQLException e) {  
    if (null!=oStmt) { try { oStmt.close(); } catch (Exception ignore) {} }
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("browseusercategories");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NullPointerException e) {  
    if (null!=oStmt) { try { oStmt.close(); } catch (Exception ignore) {} }
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("browseusercategories");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

%>  
<HTML LANG="<% out.write(id_language); %>">
  <HEAD>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    </SCRIPT>
    <TITLE>Categor&iacute;as Personales</TITLE>
  </HEAD>
  
  <BODY  TOPMARGIN="4" MARGINHEIGHT="4">
    <TABLE WIDTH="100%">
      <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
      <TR><TD CLASS="striptitle"><FONT CLASS="title1">Select file to be imported</FONT></TD></TR>
    </TABLE>  
    <FONT CLASS="formplain">filtro de archivos (*.mbox)</FONT><BR>
    <TABLE CELLPADDING="2">    
<% if (bCanBrowseUp) { %>
      <TR>
        <TD CLASS="tabletd" WIDTH="20px"><IMG SRC="../skins/<%=sSkin%>/nav/folderclosed_16x16.gif" BORDER="0"></TD>
        <TD CLASS="tabletd" ><A CLASS="linkplain" HREF="mbox_browse.jsp?gu_category=<%=gu_parent%>&gu_target=<%=gu_target%>">..</A></TD>
      </TR>
<% }
   for (int c=0; c<oSubCats.getRowCount(); c++) { %>
      <TR>
        <TD CLASS="tabletd" WIDTH="20px"><IMG SRC="../skins/<%=sSkin%>/nav/folderclosed_16x16.gif" BORDER="0"></TD>
        <TD CLASS="tabletd" ><A CLASS="linkplain" HREF="mbox_browse.jsp?gu_category=<%=oSubCats.getString(0,c)%>&gu_target=<%=gu_target%>"><%=oSubCats.getStringNull(2,c,oSubCats.getString(1,c))%></A></TD>
      </TR>
<% }
   for (int p=0; p<oProds.getRowCount(); p++) {   
     if (oProds.getStringNull(9,p,"").toLowerCase().endsWith(".mbox")) { %>
      <TR>
        <TD CLASS="tabletd" WIDTH="20px"><IMG SRC="..<%=oIcons.get(oProds.getString(8,p))%>" BORDER="0"></TD>
        <TD CLASS="tabletd" ><A CLASS="linkplain" HREF="mbox_import.jsp?gu_location=<%=oProds.getString(7,p)%>&gu_target=<%=gu_target%>"><%=oProds.getString(1,p)%></A></TD>
      </TR>   
<% } } %>
    </TABLE>
    <FORM>    
    <TABLE WIDTH="100%">
      <TR><TD ALIGN="center"><INPUT TYPE="button" CLASS="closebutton" ACCESSKEY="c" TITLE="ALT+c" onclick="window.close()" VALUE="Cancel"></TD></TR>
    </TABLE>  
    </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>