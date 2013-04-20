<%@ page import="java.util.Iterator,java.util.Vector,java.math.BigDecimal,java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/customattrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%!
/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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
  
  public static void listChilds(StringBuffer oOptions, PreparedStatement oStmt, String sThisCategory, String sParent, int iLevel) throws SQLException {
    ResultSet oChls;
    Vector vIds = new Vector(10);
    Vector vNms = new Vector(10);
        
    oStmt.setString(1, sParent);
    oChls = oStmt.executeQuery();
    
    int iOps = 0;
    while (oChls.next()) {
      vIds.add(oChls.getObject(1));
      vNms.add(oChls.getObject(2));      
      iOps++;
    } // wend
    oChls.close();
    
    for (int o=0; o<iOps; o++) {
      oOptions.append("<OPTION VALUE=\"");
      oOptions.append(vIds.get(o) + "\">");
      for (int l=0;l<iLevel;l++) oOptions.append("&nbsp;");      
      oOptions.append(vNms.get(o) + "</OPTION>");
      listChilds (oOptions,oStmt,sThisCategory,(String)vIds.get(o),iLevel+3);
    } // next
  } // listChilds
%>
<%
  String sFace = getCookie(request,"face","crm");
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  String sPath = null;
 
  String id_domain = request.getParameter("id_domain");
  String id_user = getCookie(request, "userid", "default");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_product = request.getParameter("gu_product");
  String gu_category = request.getParameter("gu_category");
  String gu_shop = request.getParameter("gu_shop");
  String top_parent = request.getParameter("top_parent_cat");
  Integer od_position = null;
  
  Shop oShp = null;
  Product oItm = null;
  ProductAttribute oAtr = null;
  
  String sStreetLookUp = null, sCountriesLookUp = null;
  String sUserAttribs,sHiddenAttribs,sAttachmentId,sAttachmentRf,sAttachmentF1,sAttachmentF2;
  StringBuffer oSelCategories = new StringBuffer();
  PreparedStatement oBrowseChilds;
  PreparedStatement oFareCount;
  DBSubset oLocs = null,oImgs = null;
  int iLocIndex=-1,iPgLocColPos=-1,iImgIndex=-1,iTpImgColPos=-1, nFares=0;
  
  JDCConnection oConn = null;

  boolean bIsGuest = true;
  boolean bIsBundle = false;

  Object ONE=null, TWO=null, THREE=null, FOUR=null, FIVE=null, SIX=null, SEVEN=null;
      
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("item_edit");

    sStreetLookUp = DBLanguages.getHTMLSelectLookUp (oConn, DB.k_addresses_lookup, gu_workarea, "tp_street", sLanguage);
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);
    
    oBrowseChilds = oConn.prepareStatement("SELECT c." + DB.gu_category + "," + DBBind.Functions.ISNULL + "(l." + DB.tr_category + ",c." + DB.nm_category + ") FROM " + DB.k_categories + " c," + DB.k_cat_tree + " t," + DB.k_cat_labels + " l WHERE c." + DB.gu_category + "=t." + DB.gu_child_cat + " AND l." + DB.gu_category + "=c." + DB.gu_category + " AND l." + DB.id_language + "='" + sLanguage + "' AND t." + DB.gu_parent_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    listChilds (oSelCategories, oBrowseChilds, top_parent, top_parent, 3);
    oBrowseChilds.close();
    
    sUserAttribs = paintAttributes (oConn, GlobalCacheClient, id_domain, id_user, iAppMask, DB.k_prod_attrs, "Products", gu_workarea, sLanguage, gu_product);
    sHiddenAttribs = paintAttributesHidden (oConn, GlobalCacheClient, id_domain, id_user, iAppMask, DB.k_prod_attrs, "Productos", gu_workarea, sLanguage, gu_product);
    
    if (gu_product!=null) {
      oItm  = new Product();

		  if (!oItm.load(oConn, new Object[]{gu_product})) {
		    throw new SQLException("Product not found "+gu_product);
		  }
	    
	    if (gu_category==null) {
	      gu_category = oItm.getCategories(oConn).getString(0,0);
	    } else if (gu_category.length()==0) {
	      gu_category = oItm.getCategories(oConn).getString(0,0);
	    }

      oAtr  = new ProductAttribute(oConn, gu_product);
      oLocs = oItm.getLocations(oConn);
      iPgLocColPos = oLocs.getColumnPosition(DB.pg_prod_locat);      
      oImgs = oItm.getImages(oConn);
      iTpImgColPos = oImgs.getColumnPosition(DB.tp_image);
      od_position = oItm.getPosition(oConn, gu_category); 

      oFareCount = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_prod_fares+" WHERE "+DB.gu_product+"=?");
      oFareCount.setString(1, gu_product);
      ResultSet rFareCount = oFareCount.executeQuery();
      rFareCount.next();
	    nFares = rFareCount.getInt(1);
	    rFareCount.close();
	    oFareCount.close();
	    
    }
    else {
      oItm  = new Product();
      oAtr  = new ProductAttribute();
      oLocs = new DBSubset (DB.k_prod_locats, "NULL", DB.gu_product + "=NULL", 1);
      oImgs = new DBSubset (DB.k_images, "NULL", DB.gu_product + "=NULL", 1);
    }

    oShp = new Shop(oConn, gu_shop);

    bIsBundle = gu_category.equals(oShp.getStringNull(DB.gu_bundles_cat,""));
    
    String sDefWrkArGet = request.getRequestURI();
    sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
    sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
    sDefWrkArGet = sDefWrkArGet + "/workareas";

    sPath = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasget", sDefWrkArGet) + "/" + oShp.getString(DB.gu_workarea) + "/apps/Shop/" + oShp.getString(DB.nm_shop) + "/";
  
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
      ONE = new BigDecimal(1); TWO=new BigDecimal(2); THREE=new BigDecimal(3); FOUR= new BigDecimal(4); FIVE=new BigDecimal(5); SIX=new BigDecimal(6); SEVEN=new BigDecimal(7);    
    }
    else {
      ONE = new Integer(1); TWO=new Integer(2); THREE=new Integer(3); FOUR= new Integer(4); FIVE=new Integer(5); SIX=new Integer(6); SEVEN=new Integer(7);    
    }
  
    oConn.close("item_edit");
  }
  catch (SQLException e) {  
    sPath = sHiddenAttribs = sUserAttribs = null;
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("item_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;  
  oConn = null;
  
  sendUsageStats(request, "item_edit"); 
%>
<HTML LANG="<% out.write(sLanguage); %>">
<!--<%=sFace%>--><HEAD>
  <TITLE>hipergate :: <% if (bIsBundle) out.write("Edit Package"); else out.write(request.getParameter("gu_category").length()>0 ? "Edit Product" : "View product"); %></TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
<% if (bIsBundle) { %>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/autosuggest20.js"></SCRIPT>
<% } %>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      // ----------------------------------------------------

	    function modifyProduct(n) {
	    	var pid = document.forms[2].elements["gu_location"+n].value;
	    	
	    	if (pid.length==0)	    	
	      	alert ("The product name does not match anyone already present at current catalog");
	      else
	        window.open ("item_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_shop=<%=gu_shop%>&gu_category=&top_parent_cat=<%=top_parent%>&gu_product=" + pid, "editProductFromPackage", "directories=no,toolbar=no,menubar=no,width=760,height=520");	  
	    }	

      // ------------------------------------------------------

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      // ------------------------------------------------------

      function showFares() {       
        var dtnw = new Date();

        window.open("fare_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_product=<%=gu_product%>", "fareedit", "toolbar=no,directories=no,menubar=no,resizable=no,width=400,height=320");
      } // showCalendar()
      
      // ------------------------------------------------------

      function presetAttrib() {
        var dot;
        var idx;
        var txt;
        var frm = document.forms[1];
        var desc = getCombo(frm.sel_attr).split(";");

	      if (frm.vl_attr.value.length==0) {
          idx = comboIndexOf(frm.list_attrs,desc[0]);
	
      	  if (-1!=idx) {
      	    txt = frm.list_attrs.options[idx].text;
      	    dot = txt.indexOf(":");
      	    frm.vl_attr.value = txt.substr(dot+1);
      	  } // fi
	      } // fi
      }
      
      // ------------------------------------------------------
      
      function setAttribs() {

        var opt;
        var idx;
        var frm = document.forms[1];
        var desc = getCombo(frm.sel_attr).split(";");
        
        if (frm.vl_attr.value.indexOf("'")>=0) {
          alert ("Attribute name may not contain quotes");
          return false;
        }
        
        if (frm.vl_attr.value.length>parseInt(desc[2])){
          alert ("Atribute length is too long, it must not exceed&nbsp;" + String(desc[2]) + " characters");
          return false;
        }

        if ((desc[1]=="SMALLINT" || desc[1]=="INTEGER") && !isIntValue(frm.vl_attr.value)) {
	        alert ("Modified attribute must be an integer numeric value");
	        return false;
        }

        if (desc[1]=="FLOAT" && !isFloatValue(frm.vl_attr.value)) {
	        alert ("Modified attribute must be a numeric value");
	        return false;
        }

	      if (desc[1]=="DATE" && !isDate(frm.vl_attr.value, "d") && frm.vl_attr.value.length>0) {
	        alert ("Modified attribute must be a date in format yyyy-mm-dd");
	        return false;	
	      }
        
        idx = comboIndexOf(frm.list_attrs,desc[0]);
                
        if (-1==idx && frm.vl_attr.value.length>0) {
          comboPush (frm.list_attrs, getComboText(frm.sel_attr)+":"+frm.vl_attr.value, desc[0], false, false);
        }
        else if (frm.vl_attr.value.length>0) {
          opt = new Option(getComboText(frm.sel_attr)+":"+frm.vl_attr.value, desc[0], false, false);
  	      frm.list_attrs.options[idx] = opt;
        }
        else {
  	      frm.list_attrs.options[idx] = null;
        }
      } // setAttribs

      // ------------------------------------------------------


      function validate() {
        var frm,atr,txt,opt,ops,dot,typ,idx,fld,wrh,usr;
	      var desc;
	
      	frm = window.document.forms[0];
      	atr = window.document.forms[1];
      
      	// ********************************************************************
      	// verify nm_product
      	
      	txt = rtrim(frm.nm_product.value);
      	if (txt.length==0) {
      	  alert ("Product name is mandatory");
      	  return false;
      	}
      
      	if (hasForbiddenChars(txt)) {
      	  alert ("Product name contains invalid characters");
      	  return false;
      	}
      
      	// ********************************************************************
      	// Verify pricing
      
      	if (frm.pr_list.value.length==0) {
      	  alert ("Standard price is required");
      	  return false;
      	}
      
      	if (frm.pr_list.value.length>0 && !isFloatValue(frm.pr_list.value)) {
      	  alert ("Standard price is not valid");
      	  return false;
      	}
      
      	if (frm.pr_sale.value.length>0 && !isFloatValue(frm.pr_sale.value)) {
      	  alert ("Bargain price is not valid");
      	  return false;
      	}
      
      	if (frm.pr_sale.value.length>0 && ltrim(frm.pr_list.value).length==0) {
      	  alert ("If a bargain price is set, a normal price must also exist");
      	  return false;
      	}
      
      	if (frm.pct_tax_rate.value.length>0) {
      	  if (!isFloatValue(frm.pct_tax_rate.value)) {
      	    alert ("Tax percentage is not valid");
      	    return false;
      	  }
      	  if (parseFloat(frm.pct_tax_rate.value.replace(new RegExp(","), "."))>100) {
      	    alert ("Tax percentage is not valid");
      	    return false;
      	  }
      	}
      	
      	// ********************************************************************
      	// Verify dates
      	
      	if (frm.dt_start.value.length>0 && !isDate(frm.dt_start.value, "d")) {
      	  alert ("Bargain start date is not valid");
      	  return false;	  
      	}
      
      	if (frm.dt_end.value.length>0 && !isDate(frm.dt_end.value, "d")) {
      	  alert ("Bargain end date is not valid");
      	  return false;	  
      	}
      
      	if (frm.dt_start.value.length>0 && frm.dt_end.value.length>0 && parseDate(frm.dt_end.value,"d")<parseDate(frm.dt_start.value,"d")) {
      	  alert ("Bargain start date must be previous to bargain end date");
      	  return false;	  
      	}
      	
      	if ((frm.dt_start.value.length>0 || frm.dt_end.value.length>0) && ltrim(frm.pr_sale.value).length==0) {
      	  alert ("If a bargain start date or end date is set than a bargain price must also exist");
      	  return false;	  
      	}
      
      	// ********************************************************************
      	// Verify remaining fields
      	
      	if (frm.de_product.value.length>254) {
      	  alert ("product description may not be longer than 254 characters");
      	  return false;
      	}
      	
      	if (frm.od_position.value.length>0 && !isIntValue(frm.od_position.value)) {
      	  alert ("Position of Product inside Category is not a valid integer.");
      	  return false;
      	}
      	
      	// ********************************************************************
      	// Assign product to category
      
        if (frm.sel_category.options.selectedIndex<0) {
      	  alert ("The category for the new product is required");
      	  return false;
        } else if (getCombo(frm.sel_category)=="") {
      	  alert ("The category for the new product is required");
      	  return false;        
        }

      	frm.gu_category.value = getCombo(frm.sel_category);
      
      	// ********************************************************************
        // Set tax rate

        frm.pct_tax_rate.value = getCombo(frm.sel_tax_rate);
        
      	// ********************************************************************
      	// Convert currency to ISO-4217 value
      	
      	frm.id_currency.value = getCombo(frm.sel_currency);
      
      	// ********************************************************************
      	// Assign product status
      	
      	frm.id_status.value = getCombo(frm.sel_status);
      
      	// ********************************************************************
      	// Validate files' extension
      
      	var filext = new RegExp( "(.gif$)|(.jpg$)|(.jpeg$)", "i" );
      	
      	if (frm.thumbview.value.length>0 && !frm.thumbview.value.match(filext)) {
      	  alert ("Graphics file extension must be .gif, .jpg or .jpeg");
      	  return false;	
      	}
      
      	// ********************************************************************
      	// Checking for autothumbs generation
      
      	if (frm.autothumb.checked && frm.normalview.value.length==0) {
      	  alert ("A thumbnail can only be automatically generated is a Normal Image exists.");
      	  return false;
      	}
      
      	if (!frm.autothumb.checked && (getCombo(frm.sel_thumbsize).length>0)) {
      	  if (!window.confirm("You have selected a size for thumion. Do you want to automatically generate thumbnail?bnail, but you did not check it for generat"))
      	    return false;
      	  else
      	    frm.autothumb.checked = true;
      	}
      	
      	if (frm.autothumb.checked && frm.gu_thumbview.value.length>0 && !frm.del_thumbview.checked) {
      	  if (!window.confirm("You have selected to overwrite current thumbnail with another one automatically generated. Are you sure that you want to replace the previous one?"))
      	    return false;
      	  else
      	    frm.del_thumbview.checked = true;
      	}
      
      	if (frm.autothumb.checked && (getCombo(frm.sel_thumbsize).length==0)) {
      	  alert ("Must specify size of thumbnail");
      	  return false;
      	}
      	
      	frm.dm_thumbsize.value = getCombo(frm.sel_thumbsize);
      
      	// ********************************************************************
      	// Move attributes from one form to another
      	        
      	ops = atr.sel_attr.options.length;
      	
      	frm.lst_attribs.value = "";
      	
      	for (var o=0; o<ops; o++){
      	  opt = atr.sel_attr.options[o];	  
      	  desc = opt.value.split(";");	  	  
      	  
      	  idx = comboIndexOf(atr.list_attrs, desc[0]);
      	  if (-1!=idx) {
      	  
      	    dot = atr.list_attrs.options[idx].text.indexOf(":")+1;
      
      	    if (atr.list_attrs.options[idx].text.indexOf("'")>=0) {
      	      alert ("The attribute&nbsp;" + atr.list_attrs.options[idx].text.substr(0,dot-1) + "contains invalid characters");
      	      return false;
      	    }
      	  	  
      	    if (frm.lst_attribs.value.length!=0) frm.lst_attribs.value = frm.lst_attribs.value + ",";
      	 
      	    typ = ltrim(rtrim(desc[1]));
      	  
      	    if (typ=="VARCHAR")
      	      frm.lst_attribs.value = frm.lst_attribs.value + desc[0] + "='" + atr.list_attrs.options[idx].text.substr(dot) + "'";
      	    else if (typ=="SMALLINT" || typ=="INTEGER" || typ=="FLOAT")
      	      frm.lst_attribs.value = frm.lst_attribs.value + desc[0] + "=" + atr.list_attrs.options[idx].text.text.substr(dot);
      	    else if (typ=="DATE" || typ=="INTEGER" || typ=="DATE")	    
      	      frm.lst_attribs.value = frm.lst_attribs.value + desc[0] + "={ d '" + atr.list_attrs.options[idx].text.substr(dot) + "' }";
      	    else {
      	      alert ("Unrecognized Type" + typ + " for attribute&nbsp;" + desc[0]);
      	      return false;	  
      	    }
      	  } // fi (idx)
      	} // next
      	
      	// Add upload_by attribute
      	if (frm.lst_attribs.value.length!=0) frm.lst_attribs.value = frm.lst_attribs.value + ",";
      	frm.lst_attribs.value = frm.lst_attribs.value + "upload_by='" + getCookie("userid") + "'";
      	
      	// ********************************************************************
      	// Verify and move warehouse fields
      	
      	wrh = document.forms[2];

<% if (bIsBundle) { %>

      	if (getCookie("face")!="realstate") {        	
        
        	for (var l=1; l<=5; l++) {

        	  if (wrh.elements["de_prod_locat"+String(l)].value>0 && wrh.elements["gu_location"+String(l)].value.length==0) {
        	    alert ("The product was not found at current catalog");
        	    wrh.elements["gu_location"+String(l)].focus();
        	    return false;
        	  }
        	
        	  if (hasForbiddenChars(wrh.elements["de_prod_locat"+String(l)].value)) {
        	    alert ("Product name contains invalid characters");
        	    wrh.elements["de_prod_locat"+String(l)].focus();
        	    return false;
        	  }
        
        	  if (hasForbiddenChars(wrh.elements["tag_prod_locat"+String(l)].value)) {
        	    alert ("Product comments contain invalid characters");
        	    wrh.elements["tag_prod_locat"+String(l)].focus();
        	    return false;
        	  }

        	  eval ("frm.gu_location" + String(l) + ".value=wrh.gu_location" + String(l) + ".value");
        	  eval ("frm.de_prod_locat" + String(l) + ".value=wrh.de_prod_locat" + String(l) + ".value");
        	  eval ("frm.tag_prod_locat" +  String(l) + ".value=wrh.tag_prod_locat" + String(l) + ".value");
        	}
      	} // fi (face!="realstate")

<% } else { %>
      	if (getCookie("face")!="realstate") {

        	if (hasForbiddenChars(wrh.de_prod_locat1.value)) {
        	  alert ("Warehouse 1 name contains forbidden characters");
        	  return false;
        	}
        
        	if (hasForbiddenChars(wrh.tag_prod_locat1.value)) {
        	  alert ("Comments for warehouse 1 contain forbidden characters");
        	  return false;
        	}
        	
        	if ((wrh.nu_current_stock1.value.length>0 || wrh.nu_min_stock1.value.length>0 || wrh.tag_prod_locat1.value.length>0) && ltrim(wrh.de_prod_locat1.value)=="") {
        	  alert ("Warehouse location 1 name is mandatory");
        	  return false;	
        	}
        	
        	if (wrh.nu_current_stock1.value.length>0 && !isIntValue(wrh.nu_current_stock1.value)) {
        	  alert ("Current stock for location 1" + wrh.de_prod_locat2.value + "must be an integer quantity");
        	  return false;
        	}
        
        	if (wrh.nu_min_stock1.value.length>0 && !isIntValue(wrh.nu_min_stock1.value)) {
        	  alert ("Minimum stock for location 1" + wrh.de_prod_locat2.value + "must be an integer quantity");
        	  return false;
        	}
        
        	if ((wrh.nu_current_stock2.value.length>0 || wrh.nu_min_stock2.value.length>0 || wrh.tag_prod_locat2.value.length>0) && ltrim(wrh.de_prod_locat2.value)=="") {
        	  alert ("Warehouse location 2 name is mandatory");
        	  return false;	
        	}
        	
        	if (wrh.nu_current_stock2.value.length>0 && !isIntValue(wrh.nu_current_stock2.value)) {
        	  alert ("Current stock for location 2" + wrh.de_prod_locat2.value + "must be an integer quantity");
        	  return false;        	}
        
        	if (wrh.nu_min_stock2.value.length>0 && !isIntValue(wrh.nu_min_stock2.value)) {
        	  alert ("Minimum stock for location 2" + wrh.de_prod_locat2.value + "must be an integer quantity");
        	  return false;
        	}
        
        	if (hasForbiddenChars(wrh.de_prod_locat2.value)) {
        	  alert ("Warehouse 2 name contains forbidden characters");
        	  return false;
        	}
        
        	if (hasForbiddenChars(wrh.tag_prod_locat2.value)) {
        	  alert ("Comments for warehouse 2 contain forbidden characters");
        	  return false;
        	}
        
        	if ((wrh.nu_current_stock3.value.length>0 || wrh.nu_min_stock3.value.length>0 || wrh.tag_prod_locat3.value.length>0) && ltrim(wrh.de_prod_locat3.value)=="") {
        	  alert ("Warehouse location 3 name is mandatory");
        	  return false;	
        	}
        	
        	if (wrh.nu_current_stock3.value.length>0 && !isIntValue(wrh.nu_current_stock3.value)) {
        	  alert ("Current stock for location 3" + wrh.de_prod_locat3.value + "must be an integer quantity");
        	  return false;
        	}
        
        	if (wrh.nu_min_stock3.value.length>0 && !isIntValue(wrh.nu_min_stock3.value)) {
        	  alert ("Minimum stock for location 3" + wrh.de_prod_locat3.value + "must be an integer quantity");
        	  return false;
        	}
        
        	if (hasForbiddenChars(wrh.de_prod_locat3.value)) {
        	  alert ("Warehouse 3 name contains forbidden characters");
        	  return false;
        	}
        
        	if (hasForbiddenChars(wrh.tag_prod_locat3.value)) {
        	  alert ("Comments for warehouse 3 contain forbidden characters");
        	  return false;
        	}
        
        	if ((wrh.nu_current_stock4.value.length>0 || wrh.nu_min_stock4.value.length>0 || wrh.tag_prod_locat4.value.length>0) && ltrim(wrh.de_prod_locat4.value)=="") {
        	  alert ("Warehouse location 4 name is mandatory");
        	  return false;	
        	}
        	
        	if (wrh.nu_current_stock4.value.length>0 && !isIntValue(wrh.nu_current_stock4.value)) {
        	  alert ("Current stock for location 4" + wrh.de_prod_locat4.value + "must be an integer quantity");
        	  return false;
        	}
        
        	if (wrh.nu_min_stock4.value.length>0 && !isIntValue(wrh.nu_min_stock4.value)) {
        	  alert ("Minimum stock for location 4" + wrh.de_prod_locat4.value + "must be an integer quantity");
        	  return false;
        	}
        
        	if (hasForbiddenChars(wrh.de_prod_locat4.value)) {
        	  alert ("Warehouse 4 name contains forbidden characters");
        	  return false;
        	}
        
        	if (hasForbiddenChars(wrh.tag_prod_locat4.value)) {
        	  alert ("Comments for warehouse 4 contain forbidden characters");
        	  return false;
        	}
        
        	if ((wrh.nu_current_stock5.value.length>0 || wrh.nu_min_stock5.value.length>0 || wrh.tag_prod_locat5.value.length>0) && ltrim(wrh.de_prod_locat5.value)=="") {
        	  alert ("Warehouse location 5 name is mandatory");
        	  return false;	
        	}
        	
        	if (wrh.nu_current_stock5.value.length>0 && !isIntValue(wrh.nu_current_stock5.value)) {
        	  alert ("Current stock for location 5" + wrh.de_prod_locat5.value + "must be an integer quantity");
        	  return false;
        	}
        
        	if (wrh.nu_min_stock5.value.length>0 && !isIntValue(wrh.nu_min_stock5.value)) {
        	  alert ("Minimum stock for location 5" + wrh.de_prod_locat5.value + "must be an integer quantity");
        	  return false;
        	}
        
        	if (hasForbiddenChars(wrh.de_prod_locat5.value)) {
        	  alert ("Warehouse 5 name contains forbidden characters");
        	  return false;
        	}
        
        	if (hasForbiddenChars(wrh.tag_prod_locat5.value)) {
        	  alert ("Comments for warehouse 5 contain forbidden characters");
        	  return false;
        	}
        
        	for (var l=1; l<=5; l++) {
        	  eval ("frm.gu_location" + String(l) + ".value=wrh.gu_location" + String(l) + ".value");
        	  eval ("frm.de_prod_locat" + String(l) + ".value=wrh.de_prod_locat" + String(l) + ".value");
        	  eval ("frm.tag_prod_locat" +  String(l) + ".value=wrh.tag_prod_locat" + String(l) + ".value");
        	  eval ("frm.nu_min_stock" + String(l) + ".value=wrh.nu_min_stock" + String(l) + ".value");
        	  eval ("frm.nu_current_stock" + String(l) + ".value=wrh.nu_current_stock" + String(l) + ".value");  
        	}
      	} // fi (face!="realstate")

<% } %>
      
      	// ********************************************************************
      	// Move user defined fields
      	
      	if (document.forms[0].custom_attributes.value.length>0) {
      	  usr = document.forms[0].custom_attributes.value.split(",");
      	  for (idx=0;idx<usr.length; idx++)
      	    eval("document.forms[0]." + usr[idx] + ".value = " + "document.forms[3]." + usr[idx] + ".value;");
      	} // fi (custom_attributes!="")
	
        return true;
      } // validate;

      // ------------------------------------------------------
              
      function lookup(odctrl) {        
        switch(parseInt(odctrl)) {
          case 5:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=tp_location&tp_control=2&nm_control=sel_location&nm_coding=tp_location&id_form=2", "lookupaddrlocation", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 6:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=tp_street&tp_control=2&nm_control=sel_street&nm_coding=tp_street&id_form=2", "lookupaddrstreet", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 7:
            if (document.forms[2].sel_country.options.selectedIndex>0)
              window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=" + getCombo(document.forms[2].sel_country) + "&tp_control=2&nm_control=sel_state&nm_coding=id_state&id_form=2", "lookupaddrstate", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            else
              alert ("Must select a country before choosing the state");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------
      
      var httpreq = null;

      function processStatesList() {
          if (httpreq.readyState == 4) {
            if (httpreq.status == 200) {
	      var vl,lb;
	      var scmb = document.forms[2].sel_state;
    	      var lkup = httpreq.responseXML.getElementsByTagName("lookup");
	      if (lkup) {
    	        for (var l = 0; l < lkup.length; l++) {
    	          vl = getElementText(lkup[l], "value");
    	          lb = getElementText(lkup[l], "label");
		  comboPush (scmb, lb, vl, false, false);
	      } // next (l)
	      httpreq = false;
	      sortCombo(scmb);
	      } // fi (lkup)
            } // fi (status == 200)
	  } // fi (readyState == 4)
      } // processStatesList

      function loadstates() {
	      var frm = window.document.forms[2];

        clearCombo(frm.sel_state);
        
        if (frm.sel_country.options.selectedIndex>0) {
          httpreq = createXMLHttpRequest();
          if (httpreq) {
	          httpreq.onreadystatechange = processStatesList;            
            httpreq.open("GET", "../common/addr_xmlfeed.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.sel_country), true);
            httpreq.send(null);
          }
        }  
      }

    //-->
  </SCRIPT>
  <SCRIPT language="JavaScript" TYPE="text/javascript">
  <!--
  var panelID = "p1";
  var numDiv = 4;
  var numRows = 1;
  var tabsPerRow = 4;
  var numLocations = numRows * tabsPerRow;
  var tabWidth = 150;
  var tabHeight = 30;
  var vOffset = 8;
  var hOffset = 10;
  
  var divLocation = new Array(numLocations);
  var newLocation = new Array(numLocations);
  
  for(var i=0; i<numLocations; ++i) {
  	divLocation[i] = i
  	newLocation[i] = i
  }
  
  function getDiv(s,i) {
  	var div
  	if (document.layers) {
  		div = document.layers[panelID].layers[panelID+s+i]
  	} else if (document.all && !document.getElementById) {
  		div = document.all[panelID+s+i]
  	} else {
  		div = document.getElementById(panelID+s+i)
  	}
  	return div
  }
  
  function setZIndex(div, zIndex) {
  	if (document.layers) div.style = div;
  	div.style.zIndex = zIndex
  }
  
  function updatePosition(div, newPos) {
  	newClip=tabHeight*(Math.floor(newPos/tabsPerRow)+1)
  	if (document.layers) {
  		div.style=div;
  		div.clip.bottom=newClip; // clip off bottom
  		} else {
  		div.style.clip="rect(0 auto "+newClip+" 0)"
  		}
  	div.style.top = (numRows-(Math.floor(newPos/tabsPerRow) + 1)) * (tabHeight-vOffset)
  	div.style.left = (newPos % tabsPerRow) * tabWidth +	(hOffset * (Math.floor(newPos / tabsPerRow)))
  }

  //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function selectTab(n) {
      	// n is the ID of the division that was clicked
      	// firstTab is the location of the first tab in the selected row
      	var firstTab = Math.floor(divLocation[n] / tabsPerRow) * tabsPerRow
      	// newLoc is its new location
      	
      	switch (n) {
      	  case 0:
      	    document.forms[0].sel_category.style.visibility = "visible";
      	    document.forms[0].sel_thumbsize.style.visibility = "visible";
      	    document.forms[0].sel_status.style.visibility = "visible";
      	    document.forms[0].sel_currency.style.visibility = "visible";
      	    document.forms[0].sel_tax_rate.style.visibility = "visible";
      	    document.forms[1].sel_attr.style.visibility = "hidden";
      	    document.forms[1].list_attrs.style.visibility = "hidden";
      	    break;
    	  case 1:
      	    document.forms[0].sel_category.style.visibility = "hidden";
      	    document.forms[0].sel_thumbsize.style.visibility = "hidden";
      	    document.forms[0].sel_status.style.visibility = "hidden";
      	    document.forms[0].sel_currency.style.visibility = "hidden";
      	    document.forms[0].sel_tax_rate.style.visibility = "hidden";
      	    document.forms[1].sel_attr.style.visibility = "visible";
      	    document.forms[1].list_attrs.style.visibility = "visible";
    	    break;
    	  case 2:
      	    document.forms[0].sel_category.style.visibility = "hidden";
      	    document.forms[0].sel_thumbsize.style.visibility = "hidden";
      	    document.forms[0].sel_status.style.visibility = "hidden";
      	    document.forms[0].sel_currency.style.visibility = "hidden";
      	    document.forms[0].sel_tax_rate.style.visibility = "hidden";
      	    document.forms[1].sel_attr.style.visibility = "hidden";
      	    document.forms[1].list_attrs.style.visibility = "hidden";
    	    break;
    	  case 3:
      	    document.forms[0].sel_category.style.visibility = "hidden";
      	    document.forms[0].sel_thumbsize.style.visibility = "hidden";
      	    document.forms[0].sel_status.style.visibility = "hidden";
      	    document.forms[0].sel_currency.style.visibility = "hidden";
      	    document.forms[0].sel_tax_rate.style.visibility = "hidden";
      	    document.forms[1].sel_attr.style.visibility = "hidden";
      	    document.forms[1].list_attrs.style.visibility = "hidden";
    	    break;
      	}
      	
      	for(var i=0; i<numDiv; ++i) {
      		// loc is the current location of the tab
      		var loc = divLocation[i]
      		// If in the selected row
      		if(loc >= firstTab && loc < (firstTab + tabsPerRow)) newLocation[i] = (loc - firstTab)
      		else if(loc < tabsPerRow) newLocation[i] = firstTab+(loc % tabsPerRow)
      		else newLocation[i] = loc
      	}
      	// Set tab positions & zIndex
      	// Update location
      	for(var i=0; i<numDiv; ++i) {
      		var loc = newLocation[i]
      		var div = getDiv("panel",i)
      		if(i == n) setZIndex(div, numLocations +1)
      		else setZIndex(div, numLocations - loc)
      		divLocation[i] = loc
      		div = getDiv("tab",i)
      		updatePosition(div, loc)
      		if(i == n) setZIndex(div, numLocations +1)
      		else setZIndex(div,numLocations - loc)
      	}
      }
      
      // Nav4: position component into a table
      function positionPanel() {
      	document.p1.top=document.panelLocator.pageY;
      	document.p1.left=document.panelLocator.pageX;
      }

      if (document.layers) window.onload=positionPanel;
  
      function getLabelForField(fld) {
  	var opt = document.forms[1].sel_attr.options;
  	var len = opt.length;
  	var idx = -1;
  	var dsc;
  	
  	for (var i=0;i<len;i++) {
  	  dsc = opt[i].value.split(";");
  	  if (dsc[0]==fld)
  	    return opt[i].text;
        } // next                
      } // getLabelForField
      
      // ----------------------------------------------------------------------
      
      function setCombos() {
        var frm = document.forms[0];
        var atr = document.forms[1];
                
        setCombo(frm.sel_category, getURLParam("gu_category"));
        setCombo(frm.sel_status, "<% if (oItm.isNull(DB.id_status)) out.write("1"); else out.write(String.valueOf(oItm.getShort(DB.id_status))); %>");
        setCombo(frm.sel_currency, "<%=oItm.getStringNull(DB.id_currency,"999")%>");
<%      
        Iterator oFlds;
	      String sAtrFld;
	      Object oAtrVal;
	
        if (gu_product!=null) {
	        oFlds = oAtr.getItems().iterator();      
	        while (oFlds.hasNext()) {
	          sAtrFld = (String) oFlds.next();
	          if (!DB.gu_product.equals(sAtrFld) && !sAtrFld.equals("upload_by")) {
	            oAtrVal = oAtr.get(sAtrFld);
	            if (null!=oAtrVal)
	              out.write("        comboPush (atr.list_attrs, getLabelForField(\"" + sAtrFld + "\") + \":\" + \"" + oAtrVal.toString() + "\", \"" + sAtrFld + "\", false, false);\n");
	          } // fi
	        } // wend
	      } // fi (gu_product)
	
        if (!oItm.isNull(DB.pct_tax_rate))
          out.write("        setCombo(frm.sel_tax_rate, \""+String.valueOf(oItm.getFloat(DB.pct_tax_rate))+"\");\n" );
%>        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <STYLE type="text/css">
      <!--
      .tab {
      font-family: sans-serif; font-size: 14px; line-height:150%; font-weight: bold; position:absolute; text-align: center; border: 2px; border-color:#999999; border-style: outset; border-bottom-style: none; width:150px; margin:0px;
      }

      .panel {
      font-family: sans-serif; font-size: 12px; position:absolute; border: 2px; border-color:#999999; border-style:outset; width:700px; height:420px; left:0px; top:22px; margin:0px; padding:6px;
      }
      -->
  </STYLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1"><% if (bIsBundle) out.write("Edit Package"); else out.write(request.getParameter("gu_category").length()>0 ? "Edit Product" : "View product"); %></FONT></TD></TR>
  </TABLE>

  <ILAYER id="panelLocator" width="700" height="510"></ILAYER>
  <NOLAYER>
  <CENTER>
    <DIV id="p1" style="background-color: transparent; position: relative; width: 700px; height: 510px">
    <DIV id="p1panel0" class="panel" style="background-color: #eeeeee;  z-index:4">
      <FORM ENCTYPE="multipart/form-data" METHOD="post" ACTION="item_edit_store.jsp" onSubmit="return validate()">
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="id_language" VALUE="<%=sLanguage%>">   
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="id_domain" VALUE="<%=id_domain%>">
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="n_domain" VALUE="<%=n_domain%>">
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="id_user" VALUE="<%=id_user%>">      
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="gu_owner" VALUE="<%=id_user%>">      
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="gu_previous_category" VALUE="<%=gu_category%>">        
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="gu_category" VALUE="<%=gu_category%>">
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="gu_product" VALUE="<%=(gu_product==null ? "" : gu_product)%>">        
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="gu_shop" VALUE="<%=gu_shop%>">        
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="nm_shop" VALUE="<%=oShp.getString(DB.nm_shop)%>">        
  	    <INPUT TYPE="hidden" TABINDEX="-1" NAME="lst_attribs">
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="id_status">
        <INPUT TYPE="hidden" TABINDEX="-1" NAME="id_currency">
  	
        <TABLE WIDTH="100%">
<% if (bIsBundle) { %> 
          <TR>
            <TD ALIGN="right" WIDTH="140"></TD>
            <TD ALIGN="left">            	
              <SELECT STYLE="display:none" NAME="sel_category"><OPTION VALUE="<%=gu_category%>" SELECTED></OPTION></SELECT>
              <FONT CLASS="formplain">Position at category&nbsp;</FONT><INPUT TYPE="text" NAME="od_position" MAXLENGTH="5" SIZE="4" CLASS="combomini" VALUE="<% if (od_position!=null) out.write (od_position.toString()); %>" onkeypress="return acceptOnlyNumbers();">
            </TD>
          </TR>
<% } else { %> 
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formstrong">Category</FONT></TD>
            <TD ALIGN="left">
              <SELECT STYLE="width:320px" NAME="sel_category" CLASS="combomini"><% out.write(oSelCategories.toString()); %></SELECT>
              &nbsp;&nbsp;<FONT CLASS="formplain">Position&nbsp;</FONT><INPUT TYPE="text" NAME="od_position" MAXLENGTH="5" SIZE="4" CLASS="combomini" VALUE="<% if (od_position!=null) out.write (od_position.toString()); %>" onkeypress="return acceptOnlyNumbers();">
            </TD>
          </TR>
<% } %> 
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="nm_product" MAXLENGTH="128" SIZE="70" CLASS="combomini" VALUE="<%=oItm.getStringNull(DB.nm_product,"")%>"></TD>
          </TR>
          <TR>
            <TD VALIGN="top" ALIGN="right"><FONT CLASS="formplain">Description:</FONT></TD>
            <TD>
	      <TEXTAREA NAME="de_product" ROWS="3" COLS="80" CLASS="combomini"><% out.write(oItm.getStringNull(DB.de_product,"")); %></TEXTAREA>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Reference:</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="16" CLASS="combomini" VALUE="<%=oItm.getStringNull(DB.id_ref,"")%>">
              &nbsp;&nbsp;&nbsp;&nbsp;
              <FONT CLASS="formplain">Status:</FONT>
              <SELECT NAME="sel_status" CLASS="combomini"><OPTION VALUE="0">Not available</OPTION><OPTION VALUE="1" SELECTED>In Stock</OPTION><OPTION VALUE="2">On demand</OPTION></SELECT>                           
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formstrong">Standard Price:</FONT></TD>
            <TD ALIGN="left">                            
              <INPUT TYPE="text" NAME="pr_list" MAXLENGTH="12" SIZE="9" CLASS="combomini" VALUE="<% if (!oItm.isNull(DB.pr_list)) out.write(String.valueOf(oItm.getFloat(DB.pr_list))); %>">
              <SELECT NAME="sel_currency" CLASS="combomini"><OPTION VALUE="999"></OPTION><OPTION VALUE="978" SELECTED>€</OPTION><OPTION VALUE="840">$</OPTION><OPTION VALUE="826">£</OPTION><OPTION VALUE="392">¥</OPTION></SELECT>              
<%     if (gu_product!=null) { %>
              &nbsp;&nbsp;&nbsp;
              <A HREF="#" CLASS="linkplain" onclick="showFares()">Tarifas</A>&nbsp;<FONT CLASS="formplain">(<%=String.valueOf(nFares)%>)</FONT>
<% } %>
            </TD>            
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Bargain Price:</FONT></TD>
            <TD ALIGN="left">                            
              <INPUT TYPE="text" NAME="pr_sale" MAXLENGTH="12" SIZE="9" CLASS="combomini" VALUE="<% if (!oItm.isNull(DB.pr_sale)) out.write(String.valueOf(oItm.getFloat(DB.pr_sale))); %>">
              &nbsp;&nbsp;<FONT CLASS="formplain">Bargain Start:</FONT>
              <INPUT TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="12" CLASS="combomini" VALUE="<% out.write(oItm.isNull(DB.dt_start) ? "" : oItm.getDateFormated(DB.dt_start,"yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
	      &nbsp;&nbsp;&nbsp;<FONT CLASS="formplain">Bargain End:</FONT>
              <INPUT TYPE="text" NAME="dt_end" MAXLENGTH="10" SIZE="12" CLASS="combomini" VALUE="<% out.write(oItm.isNull(DB.dt_end) ? "" : oItm.getDateFormated(DB.dt_end,"yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>	      
            </TD>            
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140" CLASS="formplain">Taxes:</TD>
            <TD ALIGN="left" CLASS="formplain">
              <INPUT TYPE="hidden" NAME="pct_tax_rate" MAXLENGTH="5" SIZE="4" CLASS="combomini" VALUE="<% if (!oItm.isNull(DB.pct_tax_rate)) out.write(String.valueOf(oItm.getFloat(DB.pct_tax_rate))); %>"> 
              <SELECT NAME="sel_tax_rate" CLASS="combomini"><OPTION VALUE=""></OPTION><% for (int t=0; t<=99; t++) { String s = String.valueOf(t); out.write("<OPTION VALUE=\"0."+Gadgets.leftPad(s,'0',2)+"\">"+s+"</OPTION><OPTION VALUE=\"0."+Gadgets.leftPad(s,'0',2)+"5\">"+s+".5</OPTION>"); } %></SELECT>&nbsp;%
              &nbsp;&nbsp;&nbsp;
              <INPUT TYPE="checkbox" NAME="is_tax_included" VALUE="1" <% if (!oItm.isNull(DB.is_tax_included)) out.write(oItm.getShort(DB.is_tax_included)==0 ? "" : " CHECKED"); %>>
              &nbsp;
              Taxes included in standard price
            </TD>                            
          </TR>
          <TR>
            <TD WIDTH="140" ALIGN="right"><FONT CLASS="formplain">Thumbnail:</FONT></TD>
            <TD>
	      <INPUT TYPE="file" NAME="thumbview" SIZE="15" CLASS="combomini" >
<%          iImgIndex = oImgs.find(iTpImgColPos, "thumbview");
	    if (-1!=iImgIndex) { %>
              <A HREF="<% out.write(sPath+gu_product+"_thumbview."+oImgs.getString(DB.id_img_type,iImgIndex)); %>" TARGET="_blank" TABINDEX="-1"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View Thumbnail" BORDER="0"></A>
              <A HREF="<% out.write(sPath+gu_product+"_thumbview."+oImgs.getString(DB.id_img_type,iImgIndex)); %>" TARGET="_blank" CLASS="linkplain" TITLE="View Thumbnail">View</A>
	      <IMG SRC="../images/images/spacer.gif" WIDTH="10" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" ALT="Delete Thumbnail"><INPUT TYPE="hidden" NAME="gu_thumbview" VALUE="<% out.write(oImgs.getString(0, iImgIndex)); %>"><INPUT TYPE="checkbox" NAME="del_thumbview" VALUE="1"><FONT CLASS="formplain">Delete</A>
<%          } else { %>
              <INPUT TYPE="hidden" NAME="del_thumbview" VALUE="0"><INPUT TYPE="hidden" NAME="gu_thumbview" VALUE=""><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="16" BORDER="0">
<%          } %>
	      <IMG SRC="../images/images/spacer.gif" WIDTH="10" HEIGHT="1" BORDER="0"><INPUT TYPE="checkbox" NAME="autothumb" VALUE="1"><FONT CLASS="formplain">Automatic</FONT>&nbsp;<INPUT TYPE="hidden" NAME="dm_thumbsize"><SELECT CLASS="combomini" NAME="sel_thumbsize" onchange="document.forms[0].autothumb.checked=(this.selectedIndex>0);"><OPTION VALUE=""></OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="60">60</OPTION><OPTION VALUE="80">80</OPTION><OPTION VALUE="100">100</OPTION><OPTION VALUE="120">120</OPTION><OPTION VALUE="150">150</OPTION><OPTION VALUE="175">175</OPTION><OPTION VALUE="200">200</OPTION><OPTION VALUE="240">240</OPTION></SELECT>&nbsp;<FONT CLASS="formplain">pixels</FONT>
            </TD>
	  </TR>
          <TR>
            <TD WIDTH="140" ALIGN="right"><FONT CLASS="formplain">Normal View:</FONT></TD>
            <TD>
	      <INPUT TYPE="file" NAME="normalview" SIZE=15" CLASS="combomini">
<%          iImgIndex = oImgs.find(iTpImgColPos, "normalview");
	    if (-1!=iImgIndex) { %>
              <A HREF="<% out.write(sPath+gu_product+"_normalview."+oImgs.getString(DB.id_img_type,iImgIndex)); %>" TARGET="_blank" TABINDEX="-1"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="Normal view Image" BORDER="0"></A>
              <A HREF="<% out.write(sPath+gu_product+"_normalview."+oImgs.getString(DB.id_img_type,iImgIndex)); %>" TARGET="_blank" CLASS="linkplain" TITLE="Normal view Image">View</A>
	      <IMG SRC="../images/images/spacer.gif" WIDTH="10" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" ALT="Remove Normal View Image"><INPUT TYPE="hidden" NAME="gu_normalview" VALUE="<% out.write(oImgs.getString(0, iImgIndex)); %>"><INPUT TYPE="checkbox" NAME="del_normalview" VALUE="1"><FONT CLASS="formplain">Delete</A>
<%          } else { %>
              <INPUT TYPE="hidden" NAME="del_normalview" VALUE="0"><INPUT TYPE="hidden" NAME="gu_normalview" VALUE="">
<%          } %>
            </TD>
	  </TR>
          <TR>
            <TD WIDTH="140" ALIGN="right"><FONT CLASS="formplain">Front View:</FONT></TD>
            <TD>
	      <INPUT TYPE="file" NAME="frontview" SIZE=15" CLASS="combomini">
<%          iImgIndex = oImgs.find(iTpImgColPos, "frontview");
	    if (-1!=iImgIndex) { %>
              <A HREF="<% out.write(sPath+gu_product+"_frontview."+oImgs.getString(DB.id_img_type,iImgIndex)); %>" TARGET="_blank" TABINDEX="-1"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="Front view Image" BORDER="0"></A>
              <A HREF="<% out.write(sPath+gu_product+"_frontview."+oImgs.getString(DB.id_img_type,iImgIndex)); %>" TARGET="_blank" CLASS="linkplain" TITLE="Front view Image">View</A>
	      <IMG SRC="../images/images/spacer.gif" WIDTH="10" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" ALT="Remove Front View Image"><INPUT TYPE="hidden" NAME="gu_frontview" VALUE="<% out.write(oImgs.getString(0, iImgIndex)); %>"><INPUT TYPE="checkbox" NAME="del_frontview" VALUE="1"><FONT CLASS="formplain">Delete</A>
<%          } else { %>
              <INPUT TYPE="hidden" NAME="del_frontview" VALUE="0"><INPUT TYPE="hidden" NAME="gu_frontview" VALUE="">
<%          } %>
            </TD>
	  </TR>
          <TR>
            <TD WIDTH="140" ALIGN="right"><FONT CLASS="formplain">Rear View:</FONT></TD>
            <TD>
	      <INPUT TYPE="file" NAME="rearview" SIZE=15" CLASS="combomini">
<%          iImgIndex = oImgs.find(iTpImgColPos, "rearview");
	    if (-1!=iImgIndex) { %>
              <A HREF="<% out.write(sPath+gu_product+"_rearview."+oImgs.getString(DB.id_img_type,iImgIndex)); %>" TARGET="_blank" TABINDEX="-1"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="Rear view Image" BORDER="0"></A>
              <A HREF="<% out.write(sPath+gu_product+"_rearview."+oImgs.getString(DB.id_img_type,iImgIndex)); %>" TARGET="_blank" CLASS="linkplain" TITLE="Front view Image">View</A>
	      <IMG SRC="../images/images/spacer.gif" WIDTH="10" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" ALT="Remove Rear View Image"><INPUT TYPE="hidden" NAME="gu_rearview" VALUE="<% out.write(oImgs.getString(0, iImgIndex)); %>"><INPUT TYPE="checkbox" NAME="del_rearview" VALUE="1"><FONT CLASS="formplain">Delete</A>
<%          } else { %>
              <INPUT TYPE="hidden" NAME="del_rearview" VALUE="0"><INPUT TYPE="hidden" NAME="gu_rearview" VALUE="">
<%          } %>
            </TD>
	  </TR>
          <TR>
          <TD WIDTH="140" ALIGN="right"><FONT CLASS="formplain">Associated files:</FONT></TD>
          <TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos, SIX);
	  if (-1==iLocIndex) {
	    sAttachmentId = "";
	    sAttachmentF1 = "";
	    sAttachmentRf = "<INPUT TYPE=\"hidden\" NAME=\"del_attachment1\" VALUE=\"0\">";
	  }
	  else {
	    sAttachmentId = oLocs.getString(0, iLocIndex);
	    sAttachmentF1 = Gadgets.HTMLEncode(oLocs.getStringNull(DB.xoriginalfile, iLocIndex,""));
	    sAttachmentRf = "<A HREF=\"../servlet/HttpBinaryServlet?id_product=" + oItm.getString(DB.gu_product) + "&id_location=" + sAttachmentId + "&id_user=" + id_user + "\" TARGET=\"_blank\" TITLE=\"Download File " + sAttachmentF1 + "\"><IMG SRC=\"../images/images/viewtxt.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Download File" + sAttachmentF1 + "\"></A>&nbsp;&nbsp;<IMG SRC=\"../images/images/delete.gif\" WIDTH=\"13\" HEIGHT=\"13\" ALT=\"Delete File " + sAttachmentF1 + "\"><INPUT TYPE=\"checkbox\" NAME=\"del_attachment1\" VALUE=\"1\">&nbsp;";
          }
          out.write(sAttachmentRf);
%>
            <INPUT TYPE="hidden" NAME="gu_attachment1" VALUE="<% out.write(sAttachmentId); %>"><INPUT TYPE="file" NAME="attachment1" SIZE="15" CLASS="combomini">
            &nbsp;&nbsp;
<%	  iLocIndex = oLocs.find(iPgLocColPos, SEVEN);
	  if (-1==iLocIndex) {
	    sAttachmentId = "";
	    sAttachmentF2 = "";
	    sAttachmentRf = "";
	  }
	  else {
	    sAttachmentId = oLocs.getString(0, iLocIndex);
	    sAttachmentF2 = Gadgets.HTMLEncode(oLocs.getStringNull(DB.xoriginalfile, iLocIndex,""));
	    sAttachmentRf = "<A HREF=\"../servlet/HttpBinaryServlet?id_product=" + oItm.getString(DB.gu_product) + "&id_location=" + sAttachmentId + "&id_user=" + id_user + "\" TARGET=\"_blank\" TITLE=\"Download File " + sAttachmentF2 + "\"><IMG SRC=\"../images/images/viewtxt.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Download File " + sAttachmentF2 + "\"></A>&nbsp;&nbsp;<IMG SRC=\"../images/images/delete.gif\" WIDTH=\"13\" HEIGHT=\"13\" ALT=\"Delete File " + sAttachmentF2 + "\"><INPUT TYPE=\"checkbox\" NAME=\"del_attachment2\" VALUE=\"1\">&nbsp;";
	  }	  
          out.write(sAttachmentRf);
%>
            <INPUT TYPE="hidden" NAME="gu_attachment2" VALUE="<% out.write(sAttachmentId); %>"><INPUT TYPE="file" NAME="attachment2" SIZE="15" CLASS="combomini">
          </TD>
          </TR>
<% if (request.getParameter("gu_category").length()>0) { %>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your credential level as Guest does not allow you to perform this action')">
<% } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">
<% } %>
              &nbsp;&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	    </TD>
	  </TR>
<% } %>
        </TABLE>
<%
	for (int l=1; l<=5; l++) {
	  String sl = String.valueOf(l);
	  out.write ("        <INPUT TYPE=\"hidden\" NAME=\"gu_location" + sl + "\">\n");
	  out.write ("        <INPUT TYPE=\"hidden\" NAME=\"de_prod_locat" + sl + "\">\n");
	  out.write ("        <INPUT TYPE=\"hidden\" NAME=\"tag_prod_locat" + sl + "\">\n");
	  out.write ("        <INPUT TYPE=\"hidden\" NAME=\"nu_min_stock" + sl +"\">\n");
	  out.write ("        <INPUT TYPE=\"hidden\" NAME=\"nu_current_stock" + sl +"\">\n");
	}	
	out.write (sHiddenAttribs);
%>
      </FORM>
    </DIV>
    <DIV onclick="selectTab(0)" id="p1tab0" class="tab" style="background-color:#eeeeee; left:0px; top:0px; z-index:4; clip:rect(0 auto 30 0)"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';"><%=bIsBundle ? "Package" : "Product" %></SPAN></DIV>
    <DIV id="p1panel1" class="panel" style="background-color: #dddddd;  z-index:3"> 
      <FORM>
        <TABLE WIDTH="100%">
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formstrong">Subject:</FONT></TD>
            <TD ALIGN="left">
	              <SELECT NAME="sel_attr" STYLE="visibility:hidden" onChange="presetAttrib()">
                <OPTION VALUE="scope;VARCHAR;100">Scope</OPTION>
                <OPTION VALUE="subject;VARCHAR;100">Subject</OPTION>
                <OPTION VALUE="author;VARCHAR;50">Author</OPTION>
                <OPTION VALUE="color;VARCHAR;50">Color</OPTION>
                <OPTION VALUE="size_z;VARCHAR;50">Height</OPTION>
                <OPTION VALUE="size_x;VARCHAR;50">Width</OPTION>
                <OPTION VALUE="size_y;VARCHAR;50">Length</OPTION>
                <OPTION VALUE="department;VARCHAR;50">Department</OPTION>
                <OPTION VALUE="days_to_deliver;SMALLINT;2">Days to deliver</OPTION>
                <OPTION VALUE="availability;VARCHAR;50">Availability</OPTION>
                <OPTION VALUE="disk_space;VARCHAR;50">Disk space</OPTION>
                <OPTION VALUE="dt_expire;DATE;10">Date Expires</OPTION>
                <OPTION VALUE="dt_out;DATE;10">Out Date</OPTION>
                <OPTION VALUE="product_group;VARCHAR;32">Product Group</OPTION>
                <OPTION VALUE="isbn;VARCHAR;16">ISBN</OPTION>
                <OPTION VALUE="brand;VARCHAR;50">Brand</OPTION>
                <OPTION VALUE="doc_no;VARCHAR;50">Doc. Number</OPTION>
                <OPTION VALUE="organization;VARCHAR;50">Organization</OPTION>
                <OPTION VALUE="pages;INTEGER;10">Pages</OPTION>
                <OPTION VALUE="country;VARCHAR;50">Country</OPTION>
                <OPTION VALUE="power;VARCHAR;32">Power</OPTION>
                <OPTION VALUE="rank;FLOAT">Ranking</OPTION>
                <OPTION VALUE="reference_id;VARCHAR;100">Reference</OPTION>
                <OPTION VALUE="revised_by;VARCHAR;50">Reviewed by</OPTION>
                <OPTION VALUE="rooms;SMALLINT;4">Rooms</OPTION>
                <OPTION VALUE="target;VARCHAR;50">Objective</OPTION>
                <OPTION VALUE="weight;VARCHAR;16">Weight</OPTION>
                <OPTION VALUE="adult_rated;SMALLINT;2">Adults only</OPTION>
                <OPTION VALUE="typeof;VARCHAR;50">Type</OPTION>
                <OPTION VALUE="alturl;VARCHAR;254">URL</OPTION>
                <OPTION VALUE="speed;VARCHAR;32">Speed</OPTION>	
      	      </SELECT>
      	      <INPUT TYPE="text" NAME="vl_attr" SIZE="37" onFocus="selectTab(1)">
      	      <INPUT TYPE="button" VALUE="Modify" onClick="setAttribs();" onFocus="selectTab(1)">
	    </TD>
          </TR>
          <TR>
            <TD></TD>
            <TD ALIGN="left">
              <SELECT NAME="list_attrs" STYLE="width:500;visibility:hidden" SIZE="17"></SELECT>
            </TD>
          </TR>
<% if (request.getParameter("gu_category").length()>0) { %>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onClick="alert('Your credential level as Guest does not allow you to perform this action')">
<% } else { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onClick="if (validate()) document.forms[0].submit();">
<% } %>
              &nbsp;&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	    </TD>
	  </TR>
<% } %>
        </TABLE>      	      
      </FORM> 
    </DIV>
    <DIV onclick="selectTab(1)" id="p1tab1" class="tab" style="background-color:#dddddd; left:150px; top:0px; z-index:3; clip:rect(0 auto 30 0)"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Attributes</SPAN></DIV>
    <DIV id="p1panel2" class="panel" style="background-color: #cccccc;  z-index:2">
      <FORM>
<% if (bIsBundle) { %>
        <TABLE SUMMARY="Package Products">

          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>1. Product Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,ONE);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location1" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat1" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>" onfocus="selectTab(2)" onchange="document.forms[2].gu_location1.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('1')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat1" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>" onfocus="selectTab(2)">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location1"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat1" onfocus="selectTab(2)" onchange="document.forms[2].gu_location1.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('1')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat1" onfocus="selectTab(2)">
<% } %>
	  </TR>
          <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>2. Product Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,TWO);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location2" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat2" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>" onfocus="selectTab(2)" onchange="document.forms[2].gu_location2.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('2')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat2" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location2"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat2" onfocus="selectTab(2)" onchange="document.forms[2].gu_location2.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('2')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat2">
<% } %>
	  </TR>
          <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>3. Product Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,THREE);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location3" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat3" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>" onfocus="selectTab(2)" onchange="document.forms[2].gu_location3.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('3')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat3" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location3"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat3" onfocus="selectTab(2)" onchange="document.forms[2].gu_location2.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('2')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat3">
<% } %>
          </TR> 
          <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>4. Product Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,FOUR);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location4" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat4" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>" onfocus="selectTab(2)" onchange="document.forms[2].gu_location4.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('4')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat4" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location4"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat4" onfocus="selectTab(2)" onchange="document.forms[2].gu_location2.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('2')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat4">
<% } %>
          </TR>
          <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>5. Product Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,FIVE);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location5" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat5" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>" onfocus="selectTab(2)" onchange="document.forms[2].gu_location5.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('5')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat5" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location5"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat5" onfocus="selectTab(2)" onchange="document.forms[2].gu_location2.value=''">&nbsp;<A HREF="#" TITLE="View product" onclick="modifyProduct('2')"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" ALT="View product" BORDER="0"></A></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD CLASS="formplain">Comments</TD>
            <TD CLASS="formplain"><INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat5">
<% }
   if (request.getParameter("gu_category").length()>0) { %>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	      <TD COLSPAN="2" ALIGN="center">
<%   if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onClick="alert('Your credential level as Guest does not allow you to perform this action')">
<%   } else { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onClick="if (validate()) document.forms[0].submit();">
<%   } %>
              &nbsp;&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      </TD>
	        </TR>
<% } %>
        </TABLE>
<% } else { %>
        <TABLE SUMMARY="Product Locations">
          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>1. Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,ONE);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location1" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat1" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>" onfocus="selectTab(2)">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock1" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oLocs.isNull(DB.nu_current_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_current_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();" onfocus="selectTab(2)">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock1" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oLocs.isNull(DB.nu_min_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_min_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();" onfocus="selectTab(2)"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat1" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>" onfocus="selectTab(2)">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location1"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat1" onfocus="selectTab(2)">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock1" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();" onfocus="selectTab(2)">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock1" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();" onfocus="selectTab(2)"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat1" onfocus="selectTab(2)">
<% } %>
	  </TR>
          <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>2. Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,TWO);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location2" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat2" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock2" MAXLENGTH="10" SIZE="6" VALUE="<% if (!oLocs.isNull(DB.nu_current_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_current_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock2" MAXLENGTH="10" SIZE="6" VALUE="<% if (!oLocs.isNull(DB.nu_min_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_min_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat2" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location2"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat2">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock2" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock2" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat2">
<% } %>
	  </TR>
          <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>3. Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,THREE);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location3" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat3" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock3" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oLocs.isNull(DB.nu_current_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_current_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock3" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oLocs.isNull(DB.nu_min_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_min_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat3" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location3"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat3">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock3" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock3" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat3">
<% } %>
          </TR> 
          <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>4. Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,FOUR);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location4" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat4" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock4" MAXLENGTH="10" SIZE="6" VALUE="<% if (!oLocs.isNull(DB.nu_current_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_current_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock4" MAXLENGTH="10" SIZE="6" VALUE="<% if (!oLocs.isNull(DB.nu_min_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_min_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat4" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location4"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat4">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock4" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock4" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat4">
<% } %>
          </TR>
          <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
          <TR CLASS="strip2">
            <TD CLASS="formplain" NOWRAP>5. Name&nbsp;</TD>
<%	  iLocIndex = oLocs.find(iPgLocColPos,FIVE);
	  if (null!=gu_product && -1!=iLocIndex) { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location5" VALUE="<% out.write(oLocs.getString(0,iLocIndex)); %>"><INPUT TYPE="text" MAXLENGTH="100" SIZE="20" NAME="de_prod_locat5" VALUE="<% if (!oLocs.isNull(DB.de_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.de_prod_locat,iLocIndex)); %>">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock5" MAXLENGTH="10" SIZE="6" VALUE="<% if (!oLocs.isNull(DB.nu_current_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_current_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock5" MAXLENGTH="10" SIZE="6" VALUE="<% if (!oLocs.isNull(DB.nu_min_stock,iLocIndex)) out.write(String.valueOf((int)oLocs.getFloat(DB.nu_min_stock,iLocIndex))); %>" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat5" VALUE="<% if (!oLocs.isNull(DB.tag_prod_locat,iLocIndex)) out.write(oLocs.getString(DB.tag_prod_locat,iLocIndex)); %>">
<% } else { %>
            <TD CLASS="formplain"><INPUT TYPE="hidden" NAME="gu_location5"><INPUT TYPE="text" MAXLENGTH="100" SIZE="30" NAME="de_prod_locat5">&nbsp;&nbsp;&nbsp;Current Stock&nbsp;<INPUT TYPE="text" NAME="nu_current_stock5" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();">&nbsp;&nbsp;Minimum Stock&nbsp;<INPUT TYPE="text" NAME="nu_min_stock5" MAXLENGTH="10" SIZE="6" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR> 
          <TR CLASS="strip2">
            <TD></TD>
            <TD CLASS="formplain">Comments&nbsp;<INPUT TYPE="text" MAXLENGTH="254" SIZE="74" NAME="tag_prod_locat5">
<% } %>
          </TR>
<% if (request.getParameter("gu_category").length()>0) { %>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<%   if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onClick="alert('Your credential level as Guest does not allow you to perform this action')">
<%   } else { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onClick="if (validate()) document.forms[0].submit();">
<%   } %>
              &nbsp;&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	    </TD>
	  </TR>
<% } %>
	</TABLE>
<% } %>
      </FORM>
    </DIV>
    <DIV onclick="selectTab(2)" id="p1tab2" class="tab" style="background-color:#cccccc; left:300px; top:0px; z-index:2; clip:rect(0 auto 30 0)"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';"><%= bIsBundle ? "Products" : "Warehouse" %></SPAN></DIV>
    <DIV id="p1panel3" class="panel" style="background-color: #bbbbbb;  z-index:1">
      <FORM>
      <TABLE WIDTH="100%">
        <TR><TD>
          <TABLE ALIGN="center">  
  	   <% out.write(sUserAttribs); %>
          </TABLE>
        </TD></TR>
<% if (request.getParameter("gu_category").length()>0) { %>
        <TR>
          <TD COLSPAN="2"><HR></TD>
        </TR>
        <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<%   if (bIsGuest) { %>
            <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onClick="alert('Your credential level as Guest does not allow you to perform this action')">
<%   } else { %>
            <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onClick="if (validate()) document.forms[0].submit();">
<%   } %>
            &nbsp;&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	    </TD>
	      </TR>
<% } %>
      </TABLE>
      </FORM>
    </DIV>
    <DIV onclick="selectTab(3)" id="p1tab3" class="tab" style="background-color:#bbbbbb; left:450px; top:0px; z-index:1; clip:rect(0 auto 30 0); width:200px"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Defined by User</SPAN></DIV>
    </DIV>
  </CENTER>
  </NOLAYER>
  <LAYER id="p1" width="700" height="510" src="nav4.html"></LAYER>
</BODY>
<% if (bIsBundle) { %>
<SCRIPT TYPE="text/javascript">
    <!--  
      
      var AutoSuggestOptions1 = { script:"String('../common/autocomplete.jsp?gu_shop=<%=gu_shop%>&')", varname:"tx_like",minchars:2,form:2, callback: function (obj) { document.forms[2].gu_location1.value = obj.id; } };
      var AutoSuggestOptions2 = { script:"String('../common/autocomplete.jsp?gu_shop=<%=gu_shop%>&')", varname:"tx_like",minchars:2,form:2, callback: function (obj) { document.forms[2].gu_location2.value = obj.id; } };
      var AutoSuggestOptions3 = { script:"String('../common/autocomplete.jsp?gu_shop=<%=gu_shop%>&')", varname:"tx_like",minchars:2,form:2, callback: function (obj) { document.forms[2].gu_location3.value = obj.id; } };
      var AutoSuggestOptions4 = { script:"String('../common/autocomplete.jsp?gu_shop=<%=gu_shop%>&')", varname:"tx_like",minchars:2,form:2, callback: function (obj) { document.forms[2].gu_location4.value = obj.id; } };
      var AutoSuggestOptions5 = { script:"String('../common/autocomplete.jsp?gu_shop=<%=gu_shop%>&')", varname:"tx_like",minchars:2,form:2, callback: function (obj) { document.forms[2].gu_location5.value = obj.id; } };
      
      var AutoSuggestProductName1 = new AutoSuggest("de_prod_locat1", AutoSuggestOptions1);
      var AutoSuggestProductName2 = new AutoSuggest("de_prod_locat2", AutoSuggestOptions2);
      var AutoSuggestProductName3 = new AutoSuggest("de_prod_locat3", AutoSuggestOptions3);
      var AutoSuggestProductName4 = new AutoSuggest("de_prod_locat4", AutoSuggestOptions4);
      var AutoSuggestProductName5 = new AutoSuggest("de_prod_locat5", AutoSuggestOptions5);
    //-->
</SCRIPT>
<% } %>
</HTML>
