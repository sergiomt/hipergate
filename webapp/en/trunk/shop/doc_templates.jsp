<%@ page import="java.math.BigDecimal,java.net.URLDecoder,java.util.Date,java.util.HashMap,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.*,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="templates.jspf" %><%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sLanguage = "es";
  String sSkin = getCookie(request, "skin", "xp");
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = getCookie(request,"workarea","");
  String gu_user = getCookie(request, "userid", "");

  DBSubset oShops = null;
  int iShopCount = 0;
  boolean bIsAdmin = false;
  JDCConnection oConn = null;  

  try {
    oConn = GlobalDBBind.getConnection("doc_templates");
    bIsAdmin = WorkArea.isAdmin(oConn, gu_workarea, gu_user);
    oShops = new DBSubset (DB.k_shops, DB.gu_shop + "," + DB.nm_shop,
      		           DB.bo_active + "<>0 AND " + DB.gu_workarea + "='" + gu_workarea + "'", 10);      				 
    iShopCount = oShops.load (oConn);
    oConn.close("doc_templates");
  } catch (SQLException sqle) {
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("shophome");
    oConn=null;    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getLocalizedMessage() + "&resume=_back"));  
  }
  if (null==oConn) return;
  if (!bIsAdmin) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=Insufficient priviledges to open this page&resume=_back"));  
    return;
  }
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      var inv, dis, ord;

      function createShop() {	  
        self.open ("shop_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>", "newshop", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=600,height=400");	  
      } // createShop()

      function invRequestCallback() {
        if (inv.readyState == 4) {
          if (inv.status == 200) {
	    document.forms[0].source.value = inv.responseText;
            document.getElementById("invoice").style.display = "block";
            document.getElementById("invoiceanchor").innerHTML = "Hide";
	  }
	  inv = false;
	}
      }

      function disRequestCallback() {
        if (dis.readyState == 4) {
          if (dis.status == 200) {
	    document.forms[1].source.value = dis.responseText;
            document.getElementById("despatch").style.display = "block";
            document.getElementById("despatchanchor").innerHTML = "Hide";
	  }	    
	  dis = false;
	}
      }

      function ordRequestCallback() {
        if (ord.readyState == 4) {
          if (ord.status == 200) {
	    document.forms[2].source.value = ord.responseText;
            document.getElementById("order").style.display = "block";
            document.getElementById("orderanchor").innerHTML = "Hide";
          }	    
	  ord = false;
	}
      }

      function loadSource() {
        document.forms[0].sel_catalog.selectedIndex = 0;
        inv = createXMLHttpRequest();
	if (inv) {
	  inv.onreadystatechange = invRequestCallback;
	  inv.open("GET", "template_source.jsp?nm_file=invoice.xsl&gu_shop="+getCombo(document.forms[0].sel_catalog), true);
	  inv.send(null);
	}
        dis = createXMLHttpRequest();
	if (dis) {
	  dis.onreadystatechange = disRequestCallback;
	  dis.open("GET", "template_source.jsp?nm_file=despatch.xsl&gu_shop="+getCombo(document.forms[0].sel_catalog), true);
	  dis.send(null);
	}
        ord = createXMLHttpRequest();
	if (ord) {
	  ord.onreadystatechange = ordRequestCallback;
	  ord.open("GET", "template_source.jsp?nm_file=order.xsl&gu_shop="+getCombo(document.forms[0].sel_catalog), true);
	  ord.send(null);
	}
      } // loadSource()

      function toggle(lay) {
        if (document.getElementById(lay).style.display=="block") {
          document.getElementById(lay).style.display = "none";
          document.getElementById(lay+"anchor").innerHTML = "Show";
        } else {
          document.getElementById(lay).style.display = "block";
          document.getElementById(lay+"anchor").innerHTML = "Hide";
        }
      } // toggle()

    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Templates</TITLE>
</HEAD>
<% if (iShopCount>0) { %>
<BODY CLASS="htmlbody" TOPMARGIN="8" MARGINHEIGHT="8" onload="loadSource()">
  <%@ include file="../common/tabmenu.jspf" %>
  <FORM METHOD="post" ACTION="doc_templates_store.jsp" onsubmit="document.forms[0].gu_shop.value=getCombo(document.forms[0].sel_catalog)">
    <TABLE BORDER="0" CELLSPACING="6" CELLPADDING="0"><TR><TD><FONT CLASS="textstrong">Catalog</FONT></TD><TD><SELECT NAME="sel_catalog"><% for (int c=0; c<iShopCount; c++) out.write("<OPTION VALUE=\""+oShops.getString(0,c)+"\">"+oShops.getString(1,c)+"</OPTION>"); %></SELECT></TD></TR></TABLE>
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="nm_file" VALUE="invoice.xsl">
    <INPUT TYPE="hidden" NAME="gu_shop"> 
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=nullif(request.getParameter("selected"),"7")%>"> 
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=nullif(request.getParameter("selected"),"6")%>"> 
    <TABLE WIDTH="<%=iTabWidth*iActive%>" BORDER="0" CELLSPACING="0" CELLPADDING="0">
      <TR>
        <TD CLASS="striptitle"><FONT CLASS="title1">Invoices</FONT></TD>
        <TD CLASS="striptitle" ALIGN="right"><A HREF="#" ID="invoiceanchor" CLASS="linkplain" onclick="toggle('invoice')"></A></TD>
      </TR>
    </TABLE>
    <DIV ID="invoice" NAME="invoice" STYLE="display:none">
      <TABLE BORDER="0" CELLSPACING="4" CELLPADDING="0">
        <TR><TD><TEXTAREA NAME="source" ROWS="25" STYLE="width:<%=iTabWidth*iActive%>px"></TEXTAREA></TR></TD>
        <TR><TD ALIGN="right"><INPUT TYPE="submit" CLASS="minibutton" VALUE="Save"></TD></TR>
      </TABLE>
    </DIV>
  </FORM>
  <BR>
  <FORM METHOD="post" ACTION="doc_templates_store.jsp" onsubmit="document.forms[1].gu_shop.value=getCombo(document.forms[0].sel_catalog)">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="nm_file" VALUE="despatch.xsl">
    <INPUT TYPE="hidden" NAME="gu_shop"> 
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=nullif(request.getParameter("selected"),"7")%>"> 
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=nullif(request.getParameter("selected"),"6")%>"> 
    <TABLE WIDTH="<%=iTabWidth*iActive%>" BORDER="0" CELLSPACING="0" CELLPADDING="0">
      <TR>
        <TD CLASS="striptitle"><FONT CLASS="title1">Despatch Advices</FONT></TD>
        <TD CLASS="striptitle" ALIGN="right"><A HREF="#" ID="despatchanchor" CLASS="linkplain" onclick="toggle('despatch')"></A></TD>
      </TR>
    </TABLE>
    <DIV ID="despatch" NAME="despatch" STYLE="display:none">
      <TABLE BORDER="0" CELLSPACING="4" CELLPADDING="0">
        <TR><TD><TEXTAREA NAME="source" ROWS="25" STYLE="width:<%=iTabWidth*iActive%>px"></TEXTAREA></TR></TD>
        <TR><TD ALIGN="right"><INPUT TYPE="submit" CLASS="minibutton" VALUE="Save"></TD></TR>
      </TABLE>
    </DIV>
  </FORM>
  <BR>
  <FORM METHOD="post" ACTION="doc_templates_store.jsp" onsubmit="document.forms[2].gu_shop.value=getCombo(document.forms[0].sel_catalog)">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="nm_file" VALUE="order.xsl">
    <INPUT TYPE="hidden" NAME="gu_shop"> 
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=nullif(request.getParameter("selected"),"7")%>"> 
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=nullif(request.getParameter("selected"),"6")%>"> 
    <TABLE WIDTH="<%=iTabWidth*iActive%>" BORDER="0" CELLSPACING="0" CELLPADDING="0">
      <TR>
        <TD CLASS="striptitle"><FONT CLASS="title1">Orders</FONT></TD>
        <TD CLASS="striptitle" ALIGN="right"><A HREF="#" ID="orderanchor" CLASS="linkplain" onclick="toggle('order')"></A></TD>
      </TR>
    </TABLE>
    <DIV ID="order" NAME="order" STYLE="display:none">
      <TABLE BORDER="0" CELLSPACING="4" CELLPADDING="0">
        <TR><TD><TEXTAREA NAME="source" ROWS="25" STYLE="width:<%=iTabWidth*iActive%>px"></TEXTAREA></TR></TD>
        <TR><TD ALIGN="right"><INPUT TYPE="submit" CLASS="minibutton" VALUE="Save"></TD></TR>
      </TABLE>
    </DIV>
  </FORM>  
</BODY>
<% } else { %>
<BODY CLASS="htmlbody" TOPMARGIN="8" MARGINHEIGHT="8">
  <%@ include file="../common/tabmenu.jspf" %>
  <BR><BR>
  No catalogs found&nbsp;<A HREF="#" onclick="createShop()" CLASS="linkplain">New Catalog</A>
</BODY>
<% } %>
</HTML>