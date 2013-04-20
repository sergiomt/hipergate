<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.math.CurrencyCode" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "payment_edit";
  
  final String sLanguage = getNavigatorLanguage(request);
  final String sSkin = getCookie(request, "skin", "xp");
  final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

  final String id_user = getCookie(request, "userid", "");
  final String id_domain = request.getParameter("id_domain");
  final String gu_workarea = request.getParameter("gu_workarea");
  final String gu_invoice = request.getParameter("gu_invoice");
  Integer pg_payment = new Integer (nullif(request.getParameter("pg_payment"),"1"));
  
  String gu_shop = "";
  String gu_category = "";
  String gu_root_cat = "";
  String tr_category = "";
  
  InvoicePayment oPay = new InvoicePayment();
  Invoice oInv = new Invoice();
  InvoiceLine oLin = null;
  Product oPrd = new Product();
  HashMap oBillingLookUp;
  String sBillingLookUp = "";
    
  JDCConnection oConn = null;
  DBSubset oShops = new DBSubset(DB.k_shops, DB.gu_root_cat+","+DB.nm_shop,DB.gu_workarea+"=? ORDER BY 2",10);
  int nShops = 0;
  
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

		oConn.setReadOnly(true);

    if (null!=gu_invoice) {
      oInv.load(oConn, new Object[]{gu_invoice});
      oLin = oInv.getLine(oConn, 1);
      if (!oLin.isNull(DB.gu_product)) {
        oPrd = new Product(oConn, oLin.getString(DB.gu_product));
				Shop oShp = oPrd.getShop(oConn);
				gu_shop = oShp.getString(DB.gu_shop);
				gu_root_cat = oShp.getString(DB.gu_root_cat);
				gu_category = oPrd.getCategoryId(oConn);
				tr_category = DBCommand.queryStr(oConn, "SELECT " + DB.tr_category + " FROM " + DB.k_cat_labels + " WHERE " + DB.gu_category + "='"+gu_category+"' AND " + DB.id_language + "='"+sLanguage+"'");
      }
      oPay.load(oConn, new Object[]{gu_invoice,pg_payment});
    }
    
		DBCurrencies.currencyCodes(oConn);

    sBillingLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_invoices_lookup, gu_workarea, DB.tp_billing, sLanguage);

    oBillingLookUp = DBLanguages.getLookUpMap(oConn, DB.k_invoices_lookup, gu_workarea, DB.tp_billing, sLanguage);
    
    nShops = oShops.load(oConn, new Object[]{gu_workarea});

    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&"+e.getClass().getName()+"=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Payment</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/autosuggest20.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      // ------------------------------------------------------
              
      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_invoices_lookup&id_language=" + getUserLanguage() + "&id_section=tp_billing&tp_control=2&nm_control=sel_type&nm_coding=tp_billing", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
	          // window.open("...
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      // ------------------------------------------------------

			function openTPV() {
        var frm = document.forms[0];
				if (isFloatValue(removeThousandsDelimiter(frm.im_paid.value))) {
			    parent.document.location = "invoice_payment_payonline.jsp?gu_invoice=<%=gu_invoice%>&pg_payment=<%=pg_payment.toString()%>&im_paid="+removeThousandsDelimiter(frm.im_paid.value);
				} else {
					alert ("The amount is not valid");
				  frm.im_paid.focus();
				  return false;				
			  }
			} // openTPV
      
      // ------------------------------------------------------

      function loadCategories(root) {
      	clearCombo (document.forms[0].sel_target); 
      	document.forms[0].sel_target.options[0] = new Option('Loading...', '');
      	parent.msgsexec.document.location='cat_select.jsp?top_parent=' + root;
      }

      // ------------------------------------------------------

			var req = false;

      function processProductsList() {
        if (req.readyState == 4) {
          if (req.status == 200) {
    	      var frm = window.document.forms[0];
      	    clearCombo (frm.sel_product);
    	      var prods = req.responseXML.getElementsByTagName("option");
    	      for (var p = 0; p < prods.length; p++) {
              comboPush (frm.sel_product, getElementValue(prods[p]), prods[p].getAttribute("value"), false, false);
            } // next
	          req = false;
            if (frm.sel_product.selectedIndex>=0) getPrice(getCombo(frm.sel_product));
	        } // fi
	      } // fi
      } // processProductsList

      function loadProducts(catg) {
        if (!req) {
	        req = createXMLHttpRequest();
	        if (req) {
      	    clearCombo (document.forms[0].sel_product);
      	    document.forms[0].sel_product.options[0] = new Option('Loading...', '');
	          req.onreadystatechange = processProductsList;
	          req.open("GET", "../common/select_xml.jsp?id_domain=<%=id_domain%>&gu_workarea="+catg+"&nu_limit=1000&nu_skip=0&nm_select=Products&id_form=0&nm_table=v_prod_cat_on_sale&nm_value=gu_product&nm_text=nm_product", true);
	          req.send(null);
	        }
	      } // fi
      }

      // ------------------------------------------------------

			function fillClientData(gu) {
      	parent.msgsexec.document.location = "client_fill.jsp?gu_workarea=<%=gu_workarea%>&gu_client=" + gu;
			}

      // ------------------------------------------------------

			var prd = false;

      function processProductPrice() {
        if (prd.readyState == 4) {
          if (prd.status == 200) {
    	      var frm = window.document.forms[0];
    	      var imp = getElementValue(prd.responseXML.getElementsByTagName("option")[0]);
    	      if (imp.length>5) if (imp.substr(imp.length-5,5)==".0000") imp = imp.substr(0, imp.length-5);
    	      frm.im_paid.value = imp;
	          prd = false;
	        } // fi
	      } // fi
      } // processProductPrice

      function getPrice(prod) {
        if (!prd) {
	        prd = createXMLHttpRequest();
	        if (prd) {
	          prd.onreadystatechange = processProductPrice;
	          prd.open("GET", "../common/select_xml.jsp?nu_limit=1000&nu_skip=0&nm_select=ProductPrice&id_form=0&nm_table=k_products&nm_value=gu_product&nm_text=pr_list&tx_where=gu_product%3d%27"+prod+"%27", true);
	          prd.send(null);
	        }
	      } // fi      
      }

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        
        if (null==getCheckedValue(frm.tp_client)) {
          alert ("You must select the customer type, either person or company");
          return false;
        }

	      if (frm.im_paid.value.length==0) {
	        alert ("The amount is requi red");
	        frm.im_paid.focus();
	        return false;
	      }

	      if (frm.id_legal.value.length==0) {
	        alert ("Legal Id. is required");
	        frm.id_legal.focus();
	        return false;
	      }

	      if (!isFloatValue(frm.im_paid.value)) {
	        alert ("The amount is not valid");
	        frm.im_paid.focus();
	        return false;
	      }

	      if (!check_email(frm.tx_email_to.value, "d") && frm.tx_email_to.value.length>0) {
	        alert ("E-mail is not valid");
	        frm.tx_email_to.focus();
	        return false;
	      }

	      if (!isDate(frm.dt_payment.value, "d") && frm.dt_payment.value.length>0) {
	        alert ("Due date is not valid");
	        frm.dt_payment.focus();
	        return false;
	      }

	      if (!isDate(frm.dt_paid.value, "d") && frm.dt_paid.value.length>0) {
	        alert ("Payment date is not valid");
	        frm.dt_paid.focus();
	        return false;
	      }

	      if (frm.tx_comments.value.length>254) {
	        alert ("Comments may not exceed 254 characters");
	        frm.tx_comments.focus();
	        return false;
	      }
        
        return true;
      } // validate;

      // ------------------------------------------------------

      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_type,"<% out.write(oPay.getStringNull(DB.tp_billing,"C"));%>");
        
        if (frm.gu_shop.options.length>0) {
        	
          if ("<%=gu_root_cat%>"=="") {
            frm.gu_shop.selectedIndex = 0;
            loadCategories(frm.gu_shop.options[frm.gu_shop.selectedIndex].value);
          } else {
          	setCombo(frm.gu_shop, "<%=gu_root_cat%>");
						comboPush (frm.sel_target, "<%=tr_category%>", "<%=gu_category%>", true, true);
						comboPush (frm.sel_product, "<%=oPrd.getStringNull(DB.nm_product,"")%>", "<%=oPrd.getStringNull(DB.gu_product,"")%>", true, true);
          }
        }

		    frm.tp_client[1].checked = ("<%=oInv.getStringNull(DB.gu_company,"")%>"!="");
		    frm.tp_client[0].checked = ("<%=oInv.getStringNull(DB.gu_contact,"")%>"!="");

        return true;
      } // validate;
    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1"><%= gu_invoice==null ? "Create Payment" : "Edit Payment"%></FONT></TD></TR>
  </TABLE>  
  <FORM TARGET="_top" METHOD="post" ACTION="payment_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_invoice" VALUE="<%=oInv.getStringNull(DB.gu_invoice,"")%>">
    <INPUT TYPE="hidden" NAME="pg_payment" VALUE="<%=pg_payment.toString()%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=oInv.getStringNull(DB.gu_company,"")%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=oInv.getStringNull(DB.gu_contact,"")%>">
    <INPUT TYPE="hidden" NAME="id_ref" VALUE="<%=oPay.getStringNull(DB.id_ref,"")%>">
    <INPUT TYPE="hidden" NAME="id_transact" VALUE="<%=oPay.getStringNull(DB.id_transact,"")%>">
    <INPUT TYPE="hidden" NAME="id_country" VALUE="<%=oPay.getStringNull(DB.id_country,"").trim()%>">
    <INPUT TYPE="hidden" NAME="id_authcode" VALUE="<%=oPay.getStringNull("id_authcode","")%>">
    <INPUT TYPE="hidden" NAME="id_currency" VALUE="<%=oPay.getStringNull(DB.id_currency,"978")%>">
    <INPUT TYPE="hidden" NAME="dt_expire" VALUE="<% out.write(oPay.isNull("dt_expire") ? "" : oPay.getDateFormated("dt_expire","yyyy-MM-dd")); %>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
<% if (!oPay.isNull(DB.id_ref)) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Reference</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><FONT CLASS="formplain"><%=oPay.getString(DB.id_ref)%></FONT></TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Active</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="checkbox" NAME="bo_active" VALUE="1" <% if (oPay.isNull("bo_active")) out.write("CHECKED"); else out.write(oPay.getShort("bo_active")!=0 ? "CHECKED" : ""); %>></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Customer</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_client" MAXLENGTH="50" SIZE="50" VALUE="<%=oPay.getStringHtml(DB.nm_client,oInv.getStringHtml(DB.nm_client,""))%>" onchange="document.forms[0].gu_contact.value=document.forms[0].gu_company.value"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="370"><FONT CLASS="formplain"><INPUT TYPE="radio" NAME="tp_client" VALUE="Contact">&nbsp;Person&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="tp_client" VALUE="Company">&nbsp;Company</FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Legal Id.</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="id_legal" MAXLENGTH="16" SIZE="20" VALUE="<%=oInv.getStringNull(DB.id_legal,"")%>" onchange="document.forms[0].gu_contact.value=document.forms[0].gu_company.value"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">e-mail</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tx_email_to" MAXLENGTH="100" SIZE="50" VALUE="<%=oInv.getStringNull(DB.tx_email_to,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Catalog</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><SELECT NAME="gu_shop" CLASS="combomini" onchange="loadCategories(this.options[this.selectedIndex].value)"><% for (int s=0; s<nShops; s++) out.write("<OPTION VALUE=\""+oShops.getString(0,s)+"\">"+oShops.getString(1,s)+"</OPTION>"); %></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Category</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><SELECT NAME="sel_target" CLASS="combomini" onchange="loadProducts(this.options[this.selectedIndex].value)"></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Product</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><SELECT NAME="sel_product" CLASS="combomini" onchange="getPrice(this.options[this.selectedIndex].value)"></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Amount</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="im_paid" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oPay.isNull("im_paid")) out.write(oPay.getDecimal(DB.im_paid).toString().endsWith(".0000") ? String.valueOf(oPay.getDecimal(DB.im_paid).intValue()) : oPay.getDecimal(DB.im_paid).toString()); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;<SELECT NAME="id_currency"><OPTION VALUE="678" SELECTED="selected">&euro;</OPTION></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Payment mean</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tp_example">
              <SELECT NAME="sel_type"><OPTION VALUE=""></OPTION><%=sBillingLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Types List"></A>
            </TD>
          </TR>
<% if (oPay.isNull(DB.dt_paid) && oInv.getStringNull(DB.gu_invoice,"").length()>0) { %>          
          <TR>
            <TD ALIGN="right" WIDTH="180"><IMG SRC="../images/images/shop/credicards16.gif" WIDTH="16" HEIGHT="16" ALT="Credit Cards" BORDER="0"></TD>
            <TD ALIGN="left" WIDTH="370">
              <A CLASS="linkplain" HREF="#" onclick="openTPV()">Pay with credit card</A>
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Due date</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_payment" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oPay.isNull("dt_payment") ? "" : oPay.getDateFormated("dt_payment","yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_payment')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Payment Date</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_paid" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oPay.isNull("dt_paid") ? "" : oPay.getDateFormated("dt_paid","yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_paid')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Comments</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><TEXTAREA NAME="tx_comments" COLS="40"><%=oPay.getStringHtml("tx_comments","")%></TEXTAREA></TD>
          </TR>
<!--
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="checkbox" NAME="chk_invite" VALUE="1" <%=gu_invoice==null ? "CHECKED" : ""%>></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain">Send payment link to customer
            </TD>
          </TR>
-->
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
<SCRIPT TYPE="text/javascript">
    <!--  
      
      var AutoSuggestClientOptions = { script:"'../common/autocomplete.jsp?nm_table=k_contact_company&gu_workarea=<%=gu_workarea%>&'", varname:"tx_like",minchars:2,form:0, callback: function (obj) { fillClientData(obj.id); } };

      var AutoSuggestDocIdOptions = { script:"'../common/autocomplete.jsp?nm_table=k_contact_doc_id&gu_workarea=<%=gu_workarea%>&'", varname:"tx_like",minchars:2,form:0, callback: function (obj) { fillClientData(obj.id); } };

      var AutoSuggestEmailOptions = { script:"'../common/autocomplete.jsp?nm_table=k_member_address&gu_workarea=<%=gu_workarea%>&nm_valuecolumn=gu_contact&nm_textcolumn=tx_email&tx_where=gu_contact%20IS%20NOT%20NULL%20AND%20tx_email&'", varname:"tx_like",minchars:2,form:0, callback: function (obj) { fillClientData(obj.id); } };

      var AutoSuggestClient = new AutoSuggest("nm_client", AutoSuggestClientOptions);

      var AutoSuggestDocId = new AutoSuggest("id_legal", AutoSuggestDocIdOptions);

      var AutoSuggestDocId = new AutoSuggest("tx_email_to", AutoSuggestEmailOptions);

    //-->
</SCRIPT>
</HTML>
