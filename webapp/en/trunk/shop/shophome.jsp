<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 

/*  
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
  
  String id_domain = getCookie(request, "domainid", "0");
  String n_domain = getCookie(request, "domainnm", "");
  String gu_user = getCookie(request, "userid", "");
  String gu_workarea = getCookie(request, "workarea", "");
  
  boolean bIsAdmin = false;
  DBSubset oShops;
  int iShopCount;

  JDCConnection oConn = null;  
  
  try {
    oConn = GlobalDBBind.getConnection("shophome");  

    bIsAdmin = WorkArea.isAdmin(oConn, gu_workarea, gu_user);
    
    oShops = new DBSubset (DB.k_shops, 
    			   DB.gu_shop + "," + DB.nm_shop,
      		           DB.bo_active + "<>0 AND " + DB.gu_workarea + "=?", 10);
    iShopCount = oShops.load (oConn, new Object[]{gu_workarea});

    oConn.close("shophome");
  }
  catch (SQLException e) {  
    iShopCount=0;
    oShops=null;
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("shophome");
    oConn=null;    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  if (null==oConn) return;  
  oConn = null;
  
  sendUsageStats(request, "shophome");  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Shop Management</TITLE>  
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--

    // ----------------------------------------------------

<% if (bIsAdmin) { %>
    function createShop() {	  
      self.open ("shop_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "editshop", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=600,height=400");	  
    } // createShop()

    function modifyShop() {	  
      if (document.forms[0].sel_shop.selectedIndex>=0)
        self.open ("shop_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" + "&gu_shop=" + getCombo(document.forms[0].sel_shop), "editshop", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=600,height=400");	  
      else
        alert("A catalog to be edited must be selected");
    } // modifyShop()

    function deleteShop() {	  
      if (document.forms[0].sel_shop.options.selectedIndex<0) {
        alert ("You must first choose a catalog to be deleted");
      }
      else {
        if (confirm("Are you sure that you want to delete catalog " + getComboText(document.forms[0].sel_shop)))
          window.document.location = "shop_delete.jsp?gu_shop=" + getCombo(document.forms[0].sel_shop) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
      }
    } // deleteShop()

<% } %>

    function openShop() {
      if (document.forms[0].sel_shop.selectedIndex==-1) {
        alert ("You must select a catalog to be displayed");
        window.document.location.href.href = window.document.location.href;
      }
      else {
        window.document.location = "shop_top_f.htm?gu_shop=" + getCombo(document.forms[0].sel_shop) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
      }
    }

    // ----------------------------------------------------

    function searchOrder() {
    
      var frm = document.forms[0];
      var whr = frm.tx_order.value;      

      if (whr.length==0) {
        alert ("Enter number or text of order to be searched");
        return false;
      }  
     
      if (whr.indexOf("'")>0 || whr.indexOf('"')>0 || whr.indexOf("?")>0 || whr.indexOf("%")>0 || whr.indexOf("*")>0 || whr.indexOf("&")>0 || whr.indexOf("/")>0) {
	alert ("Order text contains forbidden characters");
	return false;
      } else {
        if (isIntValue(whr))
          document.location = "order_list.jsp?id_domain=<%=id_domain%>&n_domain=<%=n_domain%>&selected=7&subselected=1&screen_width="+String(screen.width)+"&findclause=pg_order%2C"+whr+"%3B";    
        else {
          whr = escape(whr);
          document.location = "order_list.jsp?id_domain=<%=id_domain%>&n_domain=<%=n_domain%>&selected=7&subselected=1&screen_width="+String(screen.width)+"&queryspec=orders&where=id_ref%3D%27"+whr+"%27 OR id_legal%3D%27"+whr+"%27 OR de_order LIKE %27%25"+whr+"%25%27 OR nm_client LIKE %27"+whr+"%25%27 OR tx_comments LIKE %27%25"+whr+"%25%27";
        }return true;
      }
    }

    // ----------------------------------------------------

    function searchInvoice() {
    
      var frm = document.forms[0];
      var whr = frm.tx_invoice.value;      

      if (whr.length==0) {
        alert ("Enter number or text of invoice to be searched");
        return false;
      }  
     
      if (whr.indexOf("'")>0 || whr.indexOf('"')>0 || whr.indexOf("?")>0 || whr.indexOf("%")>0 || whr.indexOf("*")>0 || whr.indexOf("&")>0 || whr.indexOf("/")>0) {
	alert ("Invoice text contains forbidden characters");
	return false;
      } else {
        if (isIntValue(whr))
          document.location = "invoice_list.jsp?id_domain=<%=id_domain%>&n_domain=<%=n_domain%>&selected=7&subselected=3&screen_width="+String(screen.width)+"&findclause=pg_invoice%2C"+whr+"%3B";    
        else {
          whr = escape(whr);
          document.location = "invoice_list.jsp?id_domain=<%=id_domain%>&n_domain=<%=n_domain%>&selected=7&subselected=3&screen_width="+String(screen.width)+"&queryspec=invoices&where=id_ref%3D%27"+whr+"%27 OR id_legal%3D%27"+whr+"%27 OR nm_client LIKE %27"+whr+"%25%27 OR tx_comments LIKE %27%25"+whr+"%25%27";
        }return true;
      }
    }

    // ----------------------------------------------------
        	
    function newOrder() {	  
      self.open ("order_edit_f.jsp?id_domain=<%=id_domain%>" + "&gu_workarea=<%=gu_workarea%>", "editorder", "directories=no,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
    } // newOrder()

    // ----------------------------------------------------
        	
    function newInvoice() {
      window.open ("invoice_edit_f.jsp?id_domain=<%=id_domain%>" + "&gu_workarea=<%=gu_workarea%>", "editinvoice", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
    } // createInvoice()


    function exportFacturaPlus() {
      window.open ("sagesp/facturaplus_export1.jsp?gu_workarea=<%=gu_workarea%>", "exportfacturaplus", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=400,height=400");
    }

  //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0">
<%@ include file="../common/tabmenu.jspf" %>
<BR>
<TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Shop Management</FONT></TD></TR></TABLE>
<FORM>
  <TABLE WIDTH="<%=iTabWidth*iActive%>" CELLSPACING="0" CELLPADDING="0" BORDER="0">
    <!-- Pestaña superior -->
    <TR>  
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD BACKGROUND="../images/images/graylinebottom.gif">
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_24x24.gif" WIDTH="24" HEIGHT="24" BORDER="0"></TD>
	  </TR>
          <TR>
      	    <TD COLSPAN="2" BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" BORDER="0">Catalogs</TD>
          </TR>
        </TABLE>
      </TD>
      <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea gris y roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Cuerpo de Catálogos -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="menu1">
        <TABLE CELLSPACING="8" BORDER="0">
          <TR>
            <TD ROWSPAN="2">
              <A HREF="javascript:openShop()"><IMG SRC="../images/images/shop/shop32.gif" BORDER="0" ALT="Catalog"></A>
            </TD>
            <TD>
              <SELECT NAME="sel_shop"><% for (int n=0; n<iShopCount; n++) out.write("<OPTION VALUE=\"" + oShops.getString(0,n) + "\">" + oShops.getString(1,n) + "</OPTION>"); %></SELECT>
            </TD>
            <TD NOWRAP>
<% if (bIsAdmin) { %>
              <A HREF="#" onclick="createShop()" CLASS="linkplain">New Catalog</A>
              &nbsp;&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/delete.gif" BORDER="0">&nbsp;<A HREF="javascript:deleteShop()" CLASS="linkplain">Delete Catalog</A>
<% } %>
            </TD>
          </TR>
	  <TR>
            <TD></TD>
            <TD NOWRAP>
<% if (iShopCount>0) { %>
              <A HREF="javascript:openShop()" CLASS="linkplain"><B>View Catalog</B></A>
<% if (bIsAdmin) { %>
              &nbsp;&nbsp;&nbsp;&nbsp;<A HREF="#" onclick="modifyShop()" CLASS="linkplain">Edit Catalog</A>
<% } %>
<% } %>
            </TD>
	  </TR>
        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <TR> 
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <TR> 
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
      <TD ><IMG SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
    </TR>
<% if (iShopCount>0) { %>
    <!-- Pestaña media Pedidos -->
    <TR>  
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD>
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
	  </TR>
          <TR>
      	    <TD COLSPAN="2" BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" BORDER="0">Orders</TD>
          </TR>
        </TABLE>
      </TD>
      <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Cuerpo de Pedidos -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="menu1">
        <TABLE CELLSPACING="8" BORDER="0">
	  <TR>
            <TD ROWSPAN="3">
              <A HREF="order_list.jsp?selected=7&subselected=1"><IMG SRC="../images/images/shop/order32.gif" BORDER="0" ALT="Orders"></A>
            </TD>
            <TD></TD>
            <TD NOWRAP>
              <A HREF="#" onclick="newOrder()" CLASS="linkplain">New Order</A>
            </TD>
	  </TR>	  
          <TR>
            <TD>
              <INPUT TYPE="text" NAME="tx_order" MAXLENGTH="50" STYLE="width:180px">
            </TD>
            <TD NOWRAP>
              <A HREF="javascript:searchOrder()" CLASS="linkplain">Find Order</A>
            </TD>
          </TR>

        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>

    <!-- espacio en blanco -->

    <TR> 
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
      <TD ><IMG SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
    </TR>

    <!-- Pestaña media Facturas -->
    <TR>  
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD>
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
	  </TR>
          <TR>
      	    <TD COLSPAN="2" BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" BORDER="0">Invoices</TD>
          </TR>
        </TABLE>
      </TD>
      <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>
    <!-- Cuerpo de Facturas -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="menu1">
        <TABLE CELLSPACING="8" BORDER="0">
	        <TR>
            <TD ROWSPAN="2">
              <A HREF="invoice_list.jsp?selected=7&subselected=2"><IMG SRC="../images/images/shop/invoice32.gif" BORDER="0" ALT="Orders"></A>
            </TD>
            <TD></TD>
            <TD NOWRAP>
              <A HREF="#" onclick="newInvoice()" CLASS="linkplain">New Invoice</A>
            </TD>
	        </TR>	  
          <TR>
            <TD>
              <INPUT TYPE="text" NAME="tx_invoice" MAXLENGTH="50" STYLE="width:180px">
            </TD>
            <TD NOWRAP>
              <A HREF="javascript:searchInvoice()" CLASS="linkplain">Search Invoice</A>
            </TD>
          </TR>
<!--
<% if (bIsAdmin) { %>          
          <TR>
            <TD ALIGN="right"><IMG SRC="../images/images/shop/facturaplus.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="FacturaPlus"></TD>
            <TD COLSPAN="2"><A HREF="#" onclick="exportFacturaPlus()" CLASS="linkplain">Exportar Albaranes a FacturaPlus</A></TD>
          </TR>
<% } %>
-->
        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
    </TR>
    <!-- Línea roja -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
    </TR>

    <!-- espacio en blanco -->

    <TR> 
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
      <TD ><IMG SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
    </TR>


<% } %>

    <!-- Línea gris -->
    <TR>
      <TD WIDTH="2px" CLASS="subtitle"><IMG SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0"></TD>
      <TD  BACKGROUND="../images/images/graylinefloor.gif"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0"></TD>
    </TR>
  </TABLE>
</FORM>
</BODY>
</HTML>
