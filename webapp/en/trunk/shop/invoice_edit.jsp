<%@ page import="java.text.DecimalFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.crm.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String id_domain = nullif(request.getParameter("id_domain"),getCookie(request,"domainid",""));
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_invoice = nullif(request.getParameter("gu_invoice"));
  
  String sLocationLookUp="", sStatusLookUp="", sPaymentLookUp="", sShipingLookUp="", sBillingLookUp="", sCardsLookUp="";

  DecimalFormat oFmt2 = new DecimalFormat("#0.00");
	oFmt2.setMaximumFractionDigits(2);
  
  Invoice oInvc = new Invoice();
  int iShops = 0;
  DBSubset oShops = new DBSubset(DB.k_shops, DB.gu_shop + "," + DB.nm_shop + "," + DB.gu_root_cat, DB.gu_workarea + "=? AND " + DB.bo_active + "=1", 10);        
  DBSubset oLines = null;
  DBSubset oAddrs = null;
  String   sAddrs = "<OPTION VALUE=\"\"></OPTION>";
  int iLines = 0;
  
  JDCConnection oConn = null;  

  boolean bIsGuest = true;
      
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("invoice_edit");
    
    if (gu_invoice.length()>0) {
      oInvc.load (oConn, new Object[]{gu_invoice});
      oLines = oInvc.getLines(oConn);
      iLines = oLines.getRowCount();
      
      if (!oInvc.isNull(DB.gu_contact))
        oAddrs = new Contact(oInvc.getString(DB.gu_contact)).getAddresses(oConn);
      else if (!oInvc.isNull(DB.gu_company))
        oAddrs = new Company(oInvc.getString(DB.gu_company)).getAddresses(oConn);
      
      if (null!=oAddrs)
        for (int a=0; a<oAddrs.getRowCount(); a++)
          sAddrs += "<OPTION VALUE=\"" + oAddrs.getString(DB.gu_address,a) + "\">" + oAddrs.getStringNull(DB.nm_street,a,"") + " " + oAddrs.getStringNull(DB.nu_street,a,"") + " (" + oAddrs.getStringNull(DB.mn_city,a,"") + ")</OPTION>";

    } // fi (gu_invoice!="")
    
    iShops = oShops.load(oConn, new Object[]{gu_workarea});
      
    sLocationLookUp= DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_invoices_lookup, gu_workarea, DB.tx_location, sLanguage);
    sStatusLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_invoices_lookup, gu_workarea, DB.id_status, sLanguage);
    sPaymentLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_invoices_lookup, gu_workarea, DB.id_pay_status, sLanguage);
    sShipingLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_invoices_lookup, gu_workarea, DB.id_ship_method, sLanguage);
    sBillingLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_invoices_lookup, gu_workarea, DB.tp_billing, sLanguage);
    sCardsLookUp   = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_invoices_lookup, gu_workarea, DB.tp_card, sLanguage);
        
    oConn.close("invoice_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("invoice_edit");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  oConn = null;
  
  sendUsageStats(request, "invoice_edit");
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit invoice</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/grid.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>   
  <SCRIPT TYPE="text/javascript" DEFER="true">
    <!--
      var taxcookiename = "recenttax";
      
      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_invoices_lookup&id_language=" + getUserLanguage() + "&id_section=tx_location&tp_control=2&nm_control=sel_location&nm_coding=tx_location", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_invoices_lookup&id_language=" + getUserLanguage() + "&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_invoices_lookup&id_language=" + getUserLanguage() + "&id_section=id_pay_status&tp_control=2&nm_control=sel_pay_status&nm_coding=id_pay_status", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
            window.open("../common/lookup_f.jsp?nm_table=k_invoices_lookup&id_language=" + getUserLanguage() + "&id_section=id_ship_method&tp_control=2&nm_control=sel_ship_method&nm_coding=id_ship_method", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 5:
            window.open("../common/lookup_f.jsp?nm_table=k_invoices_lookup&id_language=" + getUserLanguage() + "&id_section=tp_billing&tp_control=2&nm_control=sel_billing&nm_coding=tp_billing", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 6:
            window.open("../common/lookup_f.jsp?nm_table=k_invoices_lookup&id_language=" + getUserLanguage() + "&id_section=tp_card&tp_control=2&nm_control=sel_card&nm_coding=tp_card", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------

      function completeClient() {
        if (ltrim(document.forms[0].nm_client.value)!="")
          window.parent.orderexec.document.location = "client_complete.jsp?nm_client=" + escape(document.forms[0].nm_client.value);
      }

      // ------------------------------------------------------
      
      function completeLegalId() {
        
        if (document.forms[0].gu_company.value.length==0 && ltrim(document.forms[0].id_legal.value)!="")
          window.parent.orderexec.document.location = "legal_complete.jsp?id_legal=" + escape(document.forms[0].id_legal.value);
      }
      
      // ------------------------------------------------------

      var intervalId;
      var winreference;
      var previouscompany;
      var previouscontact;
      

      function findReferenceWindow() {
        
        var frm = document.forms[0];;
        
        if (winreference.closed) {
          clearInterval(intervalId);
	              
          if (previouscompany.length>0 && frm.gu_company.value.length==0 && frm.gu_contact.value.length==0)
            frm.gu_company.value = previouscompany;
            
          if (previouscontact.length>0 && frm.gu_company.value.length==0 && frm.gu_contact.value.length==0)
            frm.gu_contact.value = previouscontact;
            
          if (frm.gu_company.value.length==0)
            frm.id_legal.value = "";
 	  else
 	    window.parent.orderexec.document.location = "company_complete.jsp?gu_company=" + frm.gu_company.value;

          if (frm.gu_contact.value.length!=0)
 	    window.parent.orderexec.document.location = "contact_complete.jsp?gu_contact=" + frm.gu_contact.value;          
 	   	  
          showClientWarning();          
        }
      } // findReferenceWindow()

      function reference(odctrl) {
        var frm = document.forms[0];
        
        previouscompany = frm.gu_company.value;
        previouscontact = frm.gu_contact.value;
        
        frm.gu_company.value = "";
        frm.gu_contact.value = "";
        
        switch(parseInt(odctrl)) {
          case 7:
            winreference = window.open("../common/reference.jsp?nm_table=k_companies&tp_control=1&nm_control=" + escape("nm_legal AS nm_client") + "&nm_coding=gu_company", "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 8:
            winreference = window.open("../common/reference.jsp?nm_table=v_contact_list&tp_control=1&nm_control=" + escape("full_name AS nm_client") + "&nm_coding=gu_contact", "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
        intervalId = setInterval ("findReferenceWindow()", 500);
      } // reference()

      // ----------------------------------------------------

      function addProduct() {
                
        var frm = document.forms[0];
        var sPg = String(iProductCount+1);
        var sProdId, sProdPr, sProdPc, sProdCu, sProdNm;
                
        if (frm.sel_product.options.selectedIndex<0) {
          sProdId = "null_"+sPg;
          sProdPr = "0";
          sProdPc = getCookie(taxcookiename)==null ? "0" : getCookie(taxcookiename);
          sProdCu = "978";                
          sProdNm = "";
        } else {

          var aProd = getCombo(frm.sel_product).split(":");        
          sProdId = aProd[0];
          sProdPr = aProd[1];
          sProdPc = aProd[2];
          sProdCu = aProd[3];                
          sProdNm = getComboText(frm.sel_product);        
        }

        var oRow = GridCreateRow(oProductGrid, sProdId);
	
        GridCreateInputCell(oRow, 0, "gu_product"+sPg , "gu_product"+sPg , "hidden", sProdId, null, 32, "");
  	    GridCreateInputCell(oRow, 1, "nm_product"+sPg , "nm_product"+sPg , "text", sProdNm, 30, 128,"onchange='GridSetCellValue(oProductGrid,1," + String(iProductCount) + ",this.value);'");
  	    GridCreateInputCell(oRow, 2, "nu_quantity"+sPg, "nu_quantity"+sPg, "text", "1", 3, 5, "onchange='GridSetCellValue(oProductGrid,2," + String(iProductCount) + ",this.value); computeTotal()'");
  	    GridCreateInputCell(oRow, 3, "pr_product"+sPg , "pr_product"+sPg , "text", sProdPr, 8, 12,"onchange='GridSetCellValue(oProductGrid,3," + String(iProductCount) + ",this.value); computeTotal()'");
  	    GridCreateInputCell(oRow, 4, "pct_tax"+sPg , "pct_tax"+sPg , "text", sProdPc, 4, 12,"onchange='GridSetCellValue(oProductGrid,4," + String(iProductCount) + ",this.value);' onblur='setCookie(taxcookiename,this.value)'");
  	    GridCreateInputCell(oRow, 5, "id_currency"+sPg , "id_currency"+sPg , "hidden", sProdCu, null, 3, "");
  	    GridCreateCell(oRow, 6, "remove"+sPg , "remove"+sPg , "html", "<A HREF='#' onclick='GridRemoveRow(oProductGrid,GridFindRow(oProductGrid," + '"' + sProdId + '"' + ")); GridDraw (oProductGrid, jsTableName, jsTableHeader, jsTableFooter); computeTotal();'><IMG SRC='../images/images/delete.gif' BORDER='0' ALT='Remove Product from Invoice'></A>");        

        iProductCount++;

	      GridDraw (oProductGrid, jsTableName, jsTableHeader, jsTableFooter);

	      computeTotal();

      } // addProduct

      // ----------------------------------------------------

      function addOrderLine(sProdId, sProdNm, sProdQn, sProdPr, sProdPc, sProdCu) {
        
        var frm = document.forms[0];
                        
        var sPg = String(iProductCount+1);
        var oRow = GridCreateRow(oProductGrid, sProdId);
        
        GridCreateInputCell(oRow, 0, "gu_product"+sPg , "gu_product"+sPg , "hidden", sProdId, null, 32, "");
  	GridCreateInputCell(oRow, 1, "nm_product"+sPg , "nm_product"+sPg , "text", sProdNm, 30, 128,"onchange='GridSetCellValue(oProductGrid,1," + String(iProductCount) + ",this.value);'");
  	//GridCreateCell(oRow, 1, "nm_product"+sPg , "nm_product"+sPg , "html", "<FONT CLASS=textsmall>" + sProdNm + "</FONT>");
  	GridCreateInputCell(oRow, 2, "nu_quantity"+sPg, "nu_quantity"+sPg, "text", sProdQn, 3, 5, "onchange='GridSetCellValue(oProductGrid,2," + String(iProductCount) + ",this.value); computeTotal()'");
  	GridCreateCell(oRow, 3, "pr_product"+sPg , "pr_product"+sPg , "html", "<FONT CLASS=textsmall>" + sProdPr  + "</FONT>");
  	GridCreateCell(oRow, 4, "pct_tax"+sPg , "pct_tax"+sPg , "html", "<FONT CLASS=textsmall>" + sProdPc  + "</FONT>");
  	GridCreateInputCell(oRow, 5, "id_currency"+sPg , "id_currency"+sPg , "hidden", sProdCu, null, 3, "");
  	GridCreateCell(oRow, 6, "remove"+sPg , "remove"+sPg , "html", "<A HREF='#' onclick='GridRemoveRow(oProductGrid,GridFindRow(oProductGrid," + '"' + sProdId + '"' + ")); GridDraw (oProductGrid, jsTableName, jsTableHeader, jsTableFooter); computeTotal();'><IMG SRC='../images/images/delete.gif' BORDER='0' ALT='Remove Product from Invoice'></A>");

        iProductCount++;

	GridDraw (oProductGrid, jsTableName, jsTableHeader, jsTableFooter);

      } // addOrderLine

      // ----------------------------------------------------
        	
	function createProduct() {
	  var frm = document.forms[0];
	    	  
	  window.open ("item_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_shop=" + getCombo(frm.sel_shop) + "&gu_category=" + jsRootCats[frm.sel_shop.options.selectedIndex] + "&top_parent_cat=" + jsRootCats[frm.sel_shop.options.selectedIndex], "editProduct", "directories=no,toolbar=no,menubar=no,width=760,height=520");	  
      } // createProduct()

      // ----------------------------------------------------
      
      function seekProducts() {
        var frm = document.forms[0];

	if (ltrim(frm.nm_product.value)!="") {
	  clearCombo(frm.sel_product);
	  comboPush (frm.sel_product, "Searching Products...", "", true, true);
	  window.parent.orderexec.document.location = "item_seek.jsp?nm_product=" + escape(frm.nm_product.value) + "&gu_shop=" + getCombo(frm.sel_shop);
	}
      } // seekProducts

      // ----------------------------------------------------
      
      function listAllProducts() {
        var frm = document.forms[0];

	  clearCombo(frm.sel_product);
	  comboPush (frm.sel_product, "Loading Products...", "", true, true);
	  window.parent.orderexec.document.location = "item_seek.jsp?gu_shop=" + getCombo(frm.sel_shop);
      } // listAllProducts

      // ----------------------------------------------------

      var intervalAd;
      var winaddress;

      function loadAddresses() {
	var frm = document.forms[0];

	clearCombo(frm.sel_ship_addr);
	clearCombo(frm.sel_bill_addr);
	
	comboPush (frm.sel_ship_addr, "Cargando Direcciones...", "", true, true);
	comboPush (frm.sel_bill_addr, "Cargando Direcciones...", "", true, true);

	if (frm.gu_company.value.length>0)
	  window.parent.orderexec.document.location = "addr_load.jsp?gu_company=" + frm.gu_company.value;

	if (frm.gu_contact.value.length>0)
	  window.parent.orderexec.document.location = "addr_load.jsp?gu_contact=" + frm.gu_contact.value;
      
      } // loadAddresses
      
      function findAddressWindow() {        
        if (winaddress.closed) {
          clearInterval(intervalAd);
          loadAddresses();          
        }        
      } // findAddressWindow()
      
      function createAddress() {
        var frm = document.forms[0];

	if (frm.gu_company.value.length==0 && frm.gu_contact.value.length==0) {
	  alert ("A Company or Individual must be selected before adding an address");
	  return false;
	}
	
	if (frm.gu_contact.value.length>=0)
          winaddress = window.open("../common/addr_edit_f.jsp?nm_company=" + frm.nm_client.value + "&linktable=k_x_contact_addr&linkfield=gu_contact&linkvalue=" + frm.gu_contact.value + "&noreload=1", "editcontaddr", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
	else
          winaddress = window.open("../common/addr_edit_f.jsp?nm_company=" + frm.nm_client.value + "&linktable=k_x_company_addr&linkfield=gu_company&linkvalue=" + frm.gu_company.value + "&noreload=1", "editcompaddr", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));

        intervalAd = setInterval ("findAddressWindow()", 500);
      
      } // createAddress

      // ----------------------------------------------------

      function viewAddresses() {
        var frm = document.forms[0];

	      if (frm.gu_company.value.length==0 && frm.gu_contact.value.length==0) {
	        alert ("Please chose a company or individual first");
	        return false;
	      }
	
	      if (frm.gu_company.value.length>=0)
	      
          winaddress = window.open("../common/addr_list.jsp?nm_company=" + frm.nm_client.value + "&linktable=k_x_company_addr&linkfield=gu_company&linkvalue=" + frm.gu_company.value, "editcompaddr", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
	      else
          winaddress = window.open("../common/addr_list.jsp?nm_company=" + frm.nm_client.value + "&linktable=k_x_contact_addr&linkfield=gu_contact&linkvalue=" + frm.gu_contact.value, "editcontaddr", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
      
      } // viewAddresses
            
      // ----------------------------------------------------

      function dotFloat(flt) {
        return flt.replace(new RegExp(","), ".");
      }

      // ----------------------------------------------------
      
      function computeTotal() {
        var qnt;
        var unt;
        var pct;
        var dis;
        var tot = 0;
        var tax = 0;
        var frm = document.forms[0];
	                
        for (var r=0; r<oProductGrid.rowcount; r++) {

	  qnt = GridGetCellValue(oProductGrid, 2, r);

          if (isNaN(qnt)) {
            alert ("Amount "+qnt+" is not a valid number");
            return;
          }
          	  	  
	  if (null!=qnt) {
	    qnt = dotFloat(qnt);
	    	    
	    if (!isFloatValue(qnt)) {
	      alert ("Amount for product " + GridGetCellValue(oProductGrid, 1, r) + " is not valid");
	      return false;
	    }
	    else {	      
	      unt = parseFloat(qnt) * parseFloat(dotFloat(GridGetCellValue(oProductGrid, 3, r)));
	      tot += unt;
	      tax += (unt * parseFloat(dotFloat(GridGetCellValue(oProductGrid, 4, r))));	      
	    }
	  } // fi (qnt)
	} // next

	frm.im_taxes.value = String(Math.round(tax*100)/100);
	
	tot += tax;

	if (frm.im_shipping.value.length>0) {
	  if (isFloatValue(frm.im_shipping.value)) {
	    tot += parseFloat(dotFloat(frm.im_shipping.value));
	  }
	  else {
	    alert ("Shiping costs amount is not valid");
	    return false;
	  }
	} // fi (im_shipping)

	if (frm.im_discount.value.length>0) {
	  pct = frm.im_discount.value.indexOf("%"); 
	  if (pct>0) {
	    dis = frm.im_discount.value.substring(0,pct);
	    if (isFloatValue(dis)) {
	      tot -= (tot*parseFloat(dotFloat(dis)))/100;
	    }
	    else {
	      alert ("Discount percentage is not valid");
	      return false;
	    }	    	    
	  }
	  else if (isFloatValue(frm.im_discount.value)) {
	    tot -= parseFloat(dotFloat(frm.im_discount.value));
	  }
	  else {
	    alert ("Discount is not a valid amount");
	    return false;
	  }
	} // fi (im_discount)
	
	if (frm.im_taxes.value.length>0) {
	  if (!isFloatValue(frm.im_taxes.value)) {
	    alert ("Tax is not a valid amount");
	    return false;
	  }
	} // fi (im_taxes)

	frm.im_total.value = String(Math.round(tot*100)/100);
      } // computeTotal()
      
      // ----------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
	var qnt;
	var pct;
	var dis;
	
	if (frm.sel_bill_addr.selectedIndex<0) {
	  alert ("Invoicing address is required");
	  return false;
	}

	if (ltrim(frm.id_legal.value)=="") {
	  alert ("Legal Id. of customer is required");
	  return false;
	}

	if (ltrim(frm.de_order.value)=="") {
	  alert ("Invoice description is required");
	  return false;
	}

	if (frm.gu_company.value.length==0 && frm.gu_contact.value.length==0 && frm.nm_client.value.length==0) {
	  alert ("Client is mandatory");
	  return false;
	}

	if (frm.gu_company.value.length==0 && frm.gu_contact.value.length==0 && frm.nm_client.value.length==0) {
	  alert ("Client is mandatory");
	  return false;
	}
	
	if (!isDate(frm.dt_payment.value, "d") && frm.dt_payment.value.length>0) {
	  alert ("Due date not valid");
	  return false;	  
	}

	if (frm.nu_card.value.length>0 && getCombo(frm.sel_card)=="") {
	  alert ("Card type is mandatory");
	  return false;	  
	}

	if (frm.nu_card.value.length>0 && frm.nu_bank.value.length>0) {
	  alert ("Type bank account or credit card, but not both.");
	  return false;	  
	}

	if (frm.nu_card.value.length>0 && (getCombo(frm.sel_month)=="" || getCombo(frm.sel_year)=="")) {
	  alert ("Card expire date is mandatory");
	  return false;	  
	}
	
	if (frm.tx_ship_notes.value.length>254) {
	  alert ("Delivery notes may not be longer than 254 characters.");
	  return false;	
	}

	if (frm.tx_comments.value.length>254) {
	  alert ("Comments may not be longer than 254 characters");
	  return false;	
	}

  if (0==oProductGrid.rowcount) {
    alert ("Invoice must contain at least one order line");
    return false;	      	
  }
	
	for (var r=0; r<oProductGrid.rowcount; r++) {
	  qnt = GridGetCellValue(oProductGrid, 2, r);
	  	  
	  if (null!=qnt)
	    if (!isFloatValue(qnt)) {
	      alert ("Amount for product " + GridGetCellValue(oProductGrid, 1, r) + " is not valid");
	      return false;
	    }
	} // next

	if (frm.im_shipping.value.length>0 && !isFloatValue(frm.im_shipping.value)) {
	  alert ("Shiping cost is not a valid amount");
	  return false;
	}

	if (frm.im_discount.value.length>0) {
	  pct = frm.im_discount.value.indexOf("%");

	  if (pct>0) {
	    dis = frm.im_discount.value.substring(0,pct);
	    if (!isFloatValue(dis)) {
	      alert ("Discount percentage is not a valid quantity");
	      return false;
	    }
	  }
	  else {
	    if (!isFloatValue(frm.im_discount.value)) {	  	  
	      alert ("Discount is not a valid quantity");
	      return false;
	    }
	  } // fi (pct)
	} // fi (im_discount)

	if (frm.im_taxes.value.length>0 && !isFloatValue(frm.im_taxes.value)) {
	  alert ("Tax is not a valid amount");
	  return false;
	}

	if (frm.im_total.value.length>0 && !isFloatValue(frm.im_total.value)) {
	  alert ("Total is not a valid amount");
	  return false;
	}

	frm.gu_shop.value = getCombo(frm.sel_shop);
	frm.tx_location.value = getCombo(frm.sel_location);
	frm.id_status.value = getCombo(frm.sel_status);
	frm.id_pay_status.value = getCombo(frm.sel_pay_status);

	if (frm.sel_ship_addr.options.selectedIndex>=0)
	  frm.gu_ship_addr.value = getCombo(frm.sel_ship_addr);
	else
	  frm.gu_ship_addr.value = "";

	if (frm.sel_bill_addr.options.selectedIndex>=0)	  
	  frm.gu_bill_addr.value = getCombo(frm.sel_bill_addr);
	else
	  frm.gu_bill_addr.value = "";

	frm.id_ship_method.value = getCombo(frm.sel_ship_method);
	frm.tp_billing.value = getCombo(frm.sel_billing);
	frm.tp_card.value = getCombo(frm.sel_card);
               
        frm.tx_lines.value = GridToString(oProductGrid,"`","¨");

        if (frm.tx_lines.value.length==0)        
          frm.id_currency.value = "999";
        else
          frm.id_currency.value = GridGetCellValue(oProductGrid,5,0);
		
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      var oProductGrid = GridCreate(0,7);
      var iProductCount = 0;
      var jsTableHeader = "<TABLE WIDTH=100%><TR><TD></TD><TD><FONT CLASS=textsmall><B>Product</B></FONT></TD><TD><FONT CLASS=textsmall><B>Amount</B></FONT></TD><TD><FONT CLASS=textsmall><B>Price</B></FONT></TD><TD><FONT CLASS=textsmall><B>% Tax</B></FONT></TD><TD></TD><TD></TD></TR>";
      var jsTableFooter = "</TABLE>";
      var jsTableName = "orderlines";
      var jsRootCats = new Array(<% for (int c=0; c<iShops; c++) { if (oShops.isNull(2,c)) throw new NullPointerException("Root category for Shop "+oShops.getString(0,c)+" is null"); if (c!=0) out.write(","); out.write("\"" + oShops.getString(2,c) + "\""); }%>);
            
      function viewClient() {
        var frm = document.forms[0];
        
        if (frm.gu_company.value.length!=0)
	  window.open ("../crm/company_edit.jsp?id_domain=<%=id_domain%>&gu_company=" + frm.gu_company.value + "&n_company=" + escape(frm.nm_client.value) + "&gu_workarea=<%=gu_workarea%>&noreload=1", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=" + (screen.height<=800 ? "520" : "640"));
        else if (frm.gu_contact.value.length!=0)
	  window.open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&gu_contact=" + frm.gu_contact.value + "&noreload=1", "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));          
        else
          completeClient();
          
      } // viewClient

      // ----------------------------------------------------------------------
            
      function showClientWarning() {
        var frm = document.forms[0];

        if ((frm.gu_company.value.length==0) && (frm.gu_contact.value.length==0)) {
          document.images["clientwarning"].src = "../images/images/warn16.gif";
        }
        else
          document.images["clientwarning"].src = "../images/images/shop/rolodex20.gif";              
      } // showClientWarning

      // ----------------------------------------------------------------------
      
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_shop,"<% out.write(oInvc.getStringNull(DB.gu_shop,"")); %>");
        setCombo(frm.sel_location,"<% out.write(oInvc.getStringNull(DB.tx_location,"")); %>");
        setCombo(frm.sel_status,"<% out.write(oInvc.getStringNull(DB.id_status,"")); %>");
        setCombo(frm.sel_pay_status,"<% out.write(oInvc.getStringNull(DB.id_pay_status,"")); %>");
        setCombo(frm.sel_ship_method,"<% out.write(oInvc.getStringNull(DB.id_ship_method,"")); %>");
        setCombo(frm.sel_ship_addr,"<% out.write(oInvc.getStringNull(DB.gu_ship_addr,"")); %>");
        setCombo(frm.sel_bill_addr,"<% out.write(oInvc.getStringNull(DB.gu_bill_addr,"")); %>");
        setCombo(frm.sel_billing,"<% out.write(oInvc.getStringNull(DB.tp_billing,"")); %>");
        
        if (getURLParam("gu_invoice")==null) {
          setCombo(frm.sel_status,"NOT SHIPPED");
        }
        
        showClientWarning();

<%      if (gu_invoice.length()>0)
          for (int l=0; l<iLines; l++) {              
            out.write("        addOrderLine(\"" + oLines.getStringNull(DB.gu_product,l,"null_"+String.valueOf(l+1)) + "\",\"" + oLines.getStringNull(DB.nm_product,l,"") + "\",\"" + String.valueOf(oLines.getFloat(3,l)) + "\",\"" + oLines.getDecimal(2,l).toString() + "\",\"" + String.valueOf(oLines.getFloat(6,l)) + "\",\"" + oInvc.getStringNull(DB.id_currency,"999") + "\");\n");
	  }
%>
	
	computeTotal();
	        
        return true;
      } // setCombos
    //-->
  </SCRIPT>    
</HEAD>
<BODY CLASS="htmlbody" TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
<% if (gu_invoice.length()>0) { %>
  <DIV class="cxMnu1" style="width:340px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="if (document.forms[0].gu_company.value.length==0 && document.forms[0].gu_contact.value.length==0) alert('A client is required for invoice preview') ; else top.location='invoice_preview.jsp?gu_invoice='+document.forms[0].gu_invoice.value"><IMG src="../images/images/viewtxt.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Preview"> Preview</SPAN>
  </DIV></DIV>
<% } %>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit invoice <% if (gu_invoice.length()>0) out.write(String.valueOf(oInvc.getInt(DB.pg_invoice))); %></FONT></TD></TR>
  </TABLE>
  <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>
  <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>  
  <FORM METHOD="post" ACTION="invoice_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_invoice" VALUE="<%=gu_invoice%>">
    <INPUT TYPE="hidden" NAME="pg_invoice" VALUE="<% if (gu_invoice.length()>0) out.write(String.valueOf(oInvc.getInt(DB.pg_invoice))); %>">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="<% if(oInvc.isNull(DB.bo_active)) out.write("1"); else out.write(String.valueOf(oInvc.getShort(DB.bo_active))); %>">
    
    <INPUT TYPE="hidden" NAME="id_currency" VALUE="">
    <INPUT TYPE="hidden" NAME="tx_lines" VALUE="">
    <INPUT TYPE="hidden" NAME="gu_shop">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formstrong">Description:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT CLASS="combomini" TYPE="text" NAME="de_order" MAXLENGTH="100" SIZE="70" VALUE="<% out.write(oInvc.getStringNull(DB.de_order,"")); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formstrong">Client:</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <INPUT CLASS="combomini" TYPE="text" NAME="nm_client" MAXLENGTH="200" SIZE="51" VALUE="<% out.write(oInvc.getStringNull("nm_client","")); %>" onchange="completeClient()" onkeypress="document.forms[0].gu_company.value='';document.forms[0].gu_contact.value='';document.images['clientwarning'].src = '../images/images/warn16.gif'"><A HREF="#" onclick="viewClient()"><IMG NAME="clientwarning" ID="clientwarning" HSPACE="2" SRC="../images/images/spacer.gif" WIDTH="16" HEIGHT="16" BORDER="0"></A>&nbsp;&nbsp;<A HREF="#" CLASS="linkplain" onclick="reference(7)" ACCESSKEY="p" TITLE="ALT+p">View Companies</A>&nbsp;&nbsp;<A HREF="#" CLASS="linkplain" onclick="reference(8)" ACCESSKEY="i" TITLE="ALT+i">View Individuals</A>
              <INPUT TYPE="hidden" NAME="gu_company" VALUE="<% out.write(oInvc.getStringNull(DB.gu_company,"")); %>">
              <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<% out.write(oInvc.getStringNull(DB.gu_contact,"")); %>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT CLASS="combomini" TYPE="text" NAME="id_legal" MAXLENGTH="16" SIZE="16" VALUE="<% out.write(oInvc.getStringNull(DB.id_legal,"")); %>" onchange="completeLegalId()">&nbsp;<FONT CLASS="formplain">Legal Id.</FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Reference:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT CLASS="combomini" TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="20" VALUE="<% out.write(oInvc.getStringNull(DB.id_ref,"")); %>">
              &nbsp;&nbsp;&nbsp;&nbsp;<FONT CLASS="formplain">Catalog</FONT><SELECT CLASS="combomini" NAME="sel_shop"><% for (int s=0; s<iShops; s++) if (!oShops.isNull(0,s)) out.write("<OPTION VALUE=\"" + oShops.getString(0,s) + "\">" + oShops.getString(1,s) + "</OPTION>"); %></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Subsidiary</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <INPUT TYPE="hidden" NAME="tx_location">
              <SELECT CLASS="combomini" NAME="sel_location" STYLE="width:300px"><OPTION VALUE=""></OPTION><% out.write(sLocationLookUp); %></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Subsidiaries List"></A>
            </TD>
          </TR>
	  <TR>
	    <TD ALIGN="right" CLASS="strip1"><A HREF="#" CLASS="linkplain" ACCESSKEY="t" TITLE="ALT+t" onclick="listAllProducts()">List All</A></TD>
	    <TD CLASS="strip1"><SELECT CLASS="combomini" NAME="sel_product" STYLE="width:300px" ondblclick="addProduct()"></SELECT><INPUT CLASS="combomini" TYPE="text" NAME="nm_product" MAXLENGTH="100" SIZE="25">&nbsp;<A HREF="#" CLASS="linkplain" ACCESSKEY="l" TITLE="ALT+l" onclick="seekProducts()">Search</A></TD>
	  </TR>
	  <TR>
	    <TD CLASS="strip1" VALIGN="top" ALIGN="right">
	      <A HREF="#" CLASS="linkplain" ACCESSKEY="a" TITLE="ALT+a" onclick="addProduct()">Add Product</A>
	      <BR>
	      <A HREF="#" CLASS="linkplain" ACCESSKEY="n" TITLE="ALT+n" onclick="createProduct()">New Product</A>	      
	    </TD>
	    <TD CLASS="strip1"><DIV ID="orderlines"></DIV></TD>
	  </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Shipping Costs:</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
	      <INPUT CLASS="combomini" TYPE="text" NAME="im_shipping" VALUE="<% if (!oInvc.isNull(DB.im_shipping)) out.write(oInvc.getDecimal(DB.im_shipping).toString()); %>" MAXLENGTH="7" SIZE="5" onchange="computeTotal()">
	      &nbsp;&nbsp;&nbsp;
	      <FONT CLASS="formplain">Discount:</FONT>
	      <INPUT CLASS="combomini" TYPE="text" NAME="im_discount" VALUE="<% if (!oInvc.isNull(DB.im_discount)) out.write(oInvc.getDecimal(DB.im_discount).toString()); %>" MAXLENGTH="7" SIZE="5" onchange="computeTotal()">
	      &nbsp;&nbsp;&nbsp;
	      <FONT CLASS="formplain">Taxes:</FONT>
	      <INPUT CLASS="combomini" TYPE="text" NAME="im_taxes" VALUE="<% if (!oInvc.isNull(DB.im_taxes)) out.write(oInvc.getDecimal(DB.im_taxes).toString()); %>" MAXLENGTH="7" SIZE="5" onchange="computeTotal()">
	      &nbsp;&nbsp;&nbsp;
	      <FONT CLASS="formstrong">Total:</FONT>
	      <INPUT CLASS="combomini" TYPE="text" NAME="im_total" MAXLENGTH="10" SIZE="8">
	      <A HREF="#" onclick="computeTotal()" ACCESSKEY="r" TITLE="Recalc [ALT+r]"><IMG SRC="../images/images/calc16.gif" HSPACE="2" WIDTH="16" HEIGHT="12" BORDER="0" ALT="Recalc [ALT+r]"></A>
	    </TD>
	  </TR>
	  
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Status:</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <INPUT TYPE="hidden" NAME="id_status">
              <TABLE WIDTH="100%">
                <TR>
                  <TD WIDTH="40%">
                    <SELECT CLASS="combomini" NAME="sel_status"><OPTION VALUE=""></OPTION><% out.write(sStatusLookUp); %></SELECT>&nbsp;
                    <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Edit Status List"></A>
                  </TD>
                  <TD WIDTH="60%">
                    <FONT CLASS="formplain">Shipment Method:</FONT>
              	    <INPUT TYPE="hidden" NAME="id_ship_method">
              	    <SELECT CLASS="combomini" NAME="sel_ship_method"><OPTION VALUE=""></OPTION><% out.write(sShipingLookUp); %></SELECT>&nbsp;
              	    <A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Edit Shiping Methods"></A>
                  </TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Send Address</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <INPUT TYPE="hidden" NAME="gu_ship_addr">
              <SELECT CLASS="combomini" NAME="sel_ship_addr"><% out.write (sAddrs); %></SELECT>&nbsp;<A HREF="#" onclick="createAddress()" TITLE="New Address" ACCESSKEY="d"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Address"></A>
	    				&nbsp;&nbsp;<A HREF="#" CLASS="linkplain" onclick="viewAddresses()" TITLE="Show Addresses">Show Addresses</A>
	    </TD>
	  </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Billing Address</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <INPUT TYPE="hidden" NAME="gu_bill_addr">
              <SELECT CLASS="combomini" NAME="sel_bill_addr"><% out.write (sAddrs); %></SELECT>&nbsp;<A HREF="#" onclick="createAddress()" TITLE="New Address"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Address"></A>
	    				&nbsp;&nbsp;<A HREF="#" CLASS="linkplain" onclick="viewAddresses()" TITLE="Show Addresses">Show Addresses</A>
	    </TD>
	  </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Delivery Notes:</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <TEXTAREA CLASS="textplain" NAME="tx_ship_notes" ROWS="2" COLS="80"></TEXTAREA>
	    </TD>
	  </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Due Date:</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <INPUT TYPE="hidden" NAME="tp_billing">
              <INPUT CLASS="combomini" TYPE="text" NAME="dt_payment" MAXLENGTH="10" SIZE="12" VALUE="<% if (!oInvc.isNull(DB.dt_payment)) out.write(oInvc.getDateFormated(DB.dt_payment, "yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_payment')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>              
              &nbsp;&nbsp;&nbsp;&nbsp;
              <FONT CLASS="formplain">Payment Method:</FONT>
              &nbsp;
              <SELECT CLASS="combomini" NAME="sel_billing"><OPTION VALUE=""></OPTION><% out.write(sBillingLookUp); %></SELECT>&nbsp;
              <A HREF="javascript:lookup(5)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Edit payment methods"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Paydate:</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <TABLE WIDTH="100%">
                <TR>
                  <TD>
                    <INPUT TYPE="hidden" NAME="id_pay_status">
                    <SELECT CLASS="combomini" NAME="sel_pay_status"><OPTION VALUE=""></OPTION><% out.write(sPaymentLookUp); %></SELECT>&nbsp;
                    <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Edit Payment Status"></A>
                  </TD>
                  <TD CLASS="formplain"><% if (gu_invoice.length()>0) { %> <A CLASS="linkplain" HREF="invoice_payments.jsp?gu_workarea=<%=gu_workarea%>&gu_invoice=<%=gu_invoice%>">Partial Payments</A> <% if (!oInvc.isNull(DB.im_paid)) out.write("("+oFmt2.format(oInvc.getDecimal(DB.im_paid))+")"); } %></TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Bank Account:</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <INPUT CLASS="combomini" TYPE="text" NAME="nu_bank" MAXLENGTH="20" SIZE="32" VALUE="<% out.write(oInvc.getStringNull(DB.nu_bank,"")); %>" onkeypress="return acceptOnlyNumbers();">
              &nbsp;&nbsp;&nbsp;
              <FONT CLASS="formplain">Heading:</FONT>
              <INPUT CLASS="combomini" TYPE="text" NAME="nm_cardholder" MAXLENGTH="100" SIZE="36" VALUE="<% out.write(oInvc.getStringNull("nm_cardholder","")); %>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Card Type:</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <INPUT TYPE="hidden" NAME="tp_card">
              <SELECT CLASS="combomini" NAME="sel_card"><OPTION VALUE=""></OPTION><% out.write(sCardsLookUp); %></SELECT>&nbsp;
              <A HREF="javascript:lookup(6)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Edit payment methods"></A>
              &nbsp;&nbsp;&nbsp;
              <FONT CLASS="formplain">Num</FONT>&nbsp;<INPUT CLASS="combomini" TYPE="text" NAME="nu_card" MAXLENGTH="16" SIZE="17" onkeypress="return acceptOnlyNumbers();">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Expires:</FONT>
              <INPUT TYPE="hidden" NAME="tx_expire">
              <SELECT CLASS="combomini" NAME="sel_month"><OPTION VALUE=""></OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_year"><OPTION VALUE=""></OPTION><OPTION VALUE="2003">2003</OPTION><OPTION VALUE="2004">2004</OPTION><OPTION VALUE="2005">2005</OPTION><OPTION VALUE="2006">2006</OPTION><OPTION VALUE="2007">2007</OPTION><OPTION VALUE="2008">2008</OPTION><OPTION VALUE="2009">2009</OPTION><OPTION VALUE="2010">2010</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="560">
              <TEXTAREA CLASS="textplain" NAME="tx_comments" ROWS="2" COLS="80"><%=oInvc.getStringNull(DB.tx_comments,"")%></TEXTAREA>
	    </TD>
	  </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Su nivel de privilegio como Invitado no le permite efectuar esta acción')">
<% } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">
<% } %>
              &nbsp;&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.parent.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>                                  