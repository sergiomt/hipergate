<%@ page import="java.math.BigDecimal,java.net.URLDecoder,java.util.Date,java.util.HashMap,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.*,com.knowgate.hipergate.QueryByForm,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);

  String sSkin = getCookie(request, "skin", "xp");

  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");
  
  int iScreenWidth;
  float fScreenRatio;

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String screen_width = request.getParameter("screen_width");

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;
            
  String sFindClause = request.getParameter("findclause")==null ? "" : request.getParameter("findclause");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");

  String sCompany  = request.getParameter("company")==null ? "" : request.getParameter("company");
  String sContact  = request.getParameter("contact")==null ? "" : request.getParameter("contact");
  String sSalesMan = request.getParameter("salesman")==null ? "" : request.getParameter("salesman");
  
  String sName = null;
        
  int iOrderCount = 0;
  DBSubset oOrders;        
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "10"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  String sLocationsVl = "", sStatusVl = "", sPayStatusVl = "";
  String sLocationsTr = "", sStatusTr = "", sPayStatusTr = "";
  String sSelSearch = "", sSearch = "", sSelLookup = "", sLooked = "", sSelBetween = "", sStart = "", sEnd = "";
  String sOrderId,sOrderPg,sOrderDe,sOrderDt,sPayDt,slegalNm,sContNm,sClient,sStatus,sTotalIm,sStrip;
  boolean bHasLegalId;
  BigDecimal dGrandTotal = new BigDecimal("0");
  Object oClient;
  boolean bActive;
  boolean bFirst;

  HashMap oStatusMap = null;
  HashMap oClientMap = null;
  QueryByForm oQBF;

  ResultSet oRSet;
  PreparedStatement oName  = null;
  PreparedStatement oComps = null;
  PreparedStatement oConts = null;
  PreparedStatement oLooks = null;

  JDCConnection oConn = null;  
  
  try {
    oConn = GlobalDBBind.getConnection("orderlisting"); 
    
    if (sContact.length()>0) {

      oName = oConn.prepareStatement("SELECT " + DB.tx_name + "," + DB.tx_surname + " FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?");
      oName.setString(1, sContact);
      oRSet = oName.executeQuery();
      if (oRSet.next())
        sName = oRSet.getString(1) + " " + nullif(oRSet.getString(2),""); 
      oRSet.close();
      oName.close();

    } else if (sCompany.length()>0) {

      oName = oConn.prepareStatement("SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "=?");
      oName.setString(1, sCompany);
      oRSet = oName.executeQuery();
      if (oRSet.next())
        sName = oRSet.getString(1);
      oRSet.close();
      oName.close();

    } else if (sSalesMan.length()>0) {

      oName = oConn.prepareStatement("SELECT " + DB.nm_user + "," + DB.tx_surname1 + "," + DB.tx_surname2 + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?");
      oName.setString(1, sSalesMan);
      oRSet = oName.executeQuery();
      if (oRSet.next())
        sName = oRSet.getString(1) + " " + nullif(oRSet.getString(2),"") + nullif(oRSet.getString(3),"");
      oRSet.close();
      oName.close();
    }
    
    oLooks = oConn.prepareStatement("SELECT " + DB.vl_lookup + "," + DB.tr_ + sLanguage + " FROM " + DB.k_orders_lookup + " WHERE " + DB.gu_owner + "='" + gu_workarea + "' AND " + DB.id_section  + "=? ORDER BY 2", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oLooks.setString(1, "tx_location");    
    oRSet = oLooks.executeQuery();
    bFirst = true;
    while (oRSet.next()){
      if (!bFirst) {
        sLocationsVl += ",";
        sLocationsTr += ",";
      }
      bFirst = false;
      sLocationsVl += "\"" + oRSet.getString(1) + "\"";
      sLocationsTr += "\"" + oRSet.getString(2) + "\"";      
    } // wend
    oRSet.close();
    
    oLooks.setString(1, "id_status");    
    oRSet = oLooks.executeQuery();
    bFirst = true;
    while (oRSet.next()){
      if (!bFirst) {
        sStatusVl += ",";
        sStatusTr += ",";
      }
      bFirst = false;
      sStatusVl += "\"" + oRSet.getString(1) + "\"";
      sStatusTr += "\"" + oRSet.getString(2) + "\"";      
    } // wend
    oRSet.close();

    oLooks.setString(1, "id_pay_status");    
    oRSet = oLooks.executeQuery();
    bFirst = true;
    while (oRSet.next()){
      if (!bFirst) {
        sPayStatusVl += ",";
        sPayStatusTr += ",";
      }
      bFirst = false;
      sPayStatusVl += "\"" + oRSet.getString(1) + "\"";
      sPayStatusTr += "\"" + oRSet.getString(2) + "\"";      
    } // wend
    oRSet.close();
    
    oLooks.close();
    
    oComps = oConn.prepareStatement("SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
      oConts = oConn.prepareStatement("SELECT CONCAT(COALESCE(" + DB.tx_name + ",''),' ',COALESCE(" + DB.tx_surname + ",'')) FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    else
      oConts = oConn.prepareStatement("SELECT " + DBBind.Functions.ISNULL + "(" + DB.tx_name + ",'')" + DBBind.Functions.CONCAT + "' '" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(" + DB.tx_surname + ",'') FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    
    if (sWhere.length()>0) {

      // Listados con filtro
      
      oQBF = new QueryByForm("file://" + sStorage + "/qbf/" + request.getParameter("queryspec") + ".xml");
    
      oOrders = new DBSubset (oQBF.getBaseObject(),
      			      "b.gu_order,b.pg_order,b.de_order,b.bo_active," + DBBind.Functions.ISNULL + "(b.dt_modified,b.dt_created),b.dt_payment,b.gu_company,b.gu_contact,b.id_status,b.im_total,b.id_legal",
      			      "(" + oQBF.getBaseFilter(request) + ") AND (" + sWhere + ") " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oOrders.setMaxRows(iMaxRows);
      iOrderCount = oOrders.load (oConn, iSkip);
    }
    
    else if (sFindClause.length()==0) {
      if (sContact.length()>0)
        oOrders = new DBSubset (DB.k_orders, 
      			        "gu_order,pg_order,de_order,bo_active," + DBBind.Functions.ISNULL + "(dt_modified,dt_created),dt_payment,gu_company,gu_contact,id_status,im_total,id_legal",
      			        DB.gu_contact + "='" + sContact + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      else if (sCompany.length()>0)
        oOrders = new DBSubset (DB.k_orders, 
      			        "gu_order,pg_order,de_order,bo_active," + DBBind.Functions.ISNULL + "(dt_modified,dt_created),dt_payment,gu_company,gu_contact,id_status,im_total,id_legal",
      			        DB.gu_company + "='" + sCompany + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      else if (sSalesMan.length()>0)
        oOrders = new DBSubset (DB.k_orders, 
      			        "gu_order,pg_order,de_order,bo_active," + DBBind.Functions.ISNULL + "(dt_modified,dt_created),dt_payment,gu_company,gu_contact,id_status,im_total,id_legal",
      			        DB.gu_sales_man + "='" + sSalesMan + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      
      else
        oOrders = new DBSubset (DB.k_orders, 
      			        "gu_order,pg_order,de_order,bo_active," + DBBind.Functions.ISNULL + "(dt_modified,dt_created),dt_payment,gu_company,gu_contact,id_status,im_total,id_legal",
      			        DB.gu_workarea + "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      
      oOrders.setMaxRows(iMaxRows);
      iOrderCount = oOrders.load (oConn, iSkip);
    }
    else {
      String sWhereClause = "";
      String[] aFindClause = Gadgets.split(sFindClause, ';');
      String[] aFindField;
      

      for (int c=0; c<aFindClause.length; c++) {
        if (aFindClause[c].length()>0) {

          aFindField = Gadgets.split(aFindClause[c], ',');


          if (sWhereClause.length()>0) sWhereClause += " AND ";
  
          if (aFindField[0].equalsIgnoreCase(DB.pg_order)) {
            sWhereClause += DB.pg_order + "=" + aFindField[1];
            sSelSearch = DB.pg_order;
            sSearch = aFindField[1];
          }        
          else if (aFindField[0].equalsIgnoreCase(DB.nm_client)
                || aFindField[0].equalsIgnoreCase(DB.de_order)
                || aFindField[0].equalsIgnoreCase(DB.tx_comments)) {
            sWhereClause += aFindField[0] + " " + DBBind.Functions.ILIKE + " '%" + aFindField[1] + "%'";
  
            sSelSearch = aFindField[0];
            sSearch = aFindField[1];
          }
          else if (aFindField[0].equalsIgnoreCase(DB.id_legal)) {
            sWhereClause += aFindField[0] + " ='" + aFindField[1] + "'";
  
            sSelSearch = DB.id_legal;
            sSearch = aFindField[1];
          }
          else if (aFindField[0].equalsIgnoreCase(DB.tx_location)
                || aFindField[0].equalsIgnoreCase(DB.id_status)
                || aFindField[0].equalsIgnoreCase(DB.id_pay_status)) {
            sWhereClause += aFindField[0] + " = '" + aFindField[1] + "'";
            sSelLookup = aFindField[0];
            sLooked = aFindField[1];
          }        
          else if (aFindField[0].equalsIgnoreCase(DB.im_total)) {
            if (aFindField[1].length()>0 && aFindField[2].length()>0)
              sWhereClause += DB.im_total + " BETWEEN " + aFindField[1] + " AND " + aFindField[2];
            else if (aFindField[1].length()==0)
              sWhereClause += DB.im_total + "<=" + aFindField[2];
            else if (aFindField[2].length()==0)
              sWhereClause += DB.im_total + ">=" + aFindField[1];
  
  	  sSelBetween = DB.im_total;
  	  sStart = aFindField[1];
  	  sEnd = aFindField[2];
          }
          else if (aFindField[0].equalsIgnoreCase(DB.dt_modified)
                || aFindField[0].equalsIgnoreCase(DB.dt_payment)) {
  	  
  	  sSelBetween = aFindField[0];
  	  sStart = aFindField[1];
  	  sEnd = aFindField[2];
            
            Date dtStart = null, dtEnd = null;
            String[] aStart;
            String[] aEnd;
            
            if (sStart.length()>0) {
              aStart = Gadgets.split(sStart, '-');
              dtStart = new Date(Integer.parseInt(aStart[0])-1900, Integer.parseInt(aStart[1])-1, Integer.parseInt(aStart[2]), 0, 0, 0);
            }
  
            if (sEnd.length()>0) {
              aEnd = Gadgets.split(sEnd, '-');
              dtEnd = new Date(Integer.parseInt(aEnd[0])-1900, Integer.parseInt(aEnd[1])-1, Integer.parseInt(aEnd[2]), 23, 59, 59);
            }
            
            if (aFindField[1].length()>0 && aFindField[2].length()>0)
              sWhereClause += aFindField[0] + " BETWEEN " + DBBind.escape(dtStart, "ts") + " AND " + DBBind.escape(dtEnd, "ts");
  	    else if (aFindField[1].length()==0)
              sWhereClause += aFindField[0] + "<=" + DBBind.escape(dtEnd, "ts");
  	    else if (aFindField[2].length()==0)
              sWhereClause += aFindField[0] + ">=" + DBBind.escape(dtStart, "ts");		            
          } // fi (aFindField[0]=="dt_modified" || aFindField[0]=="dt_payment")

        } // fi (aFindClause[c]!="")
      } // next

      if (sContact.length()>0)
        oOrders = new DBSubset (DB.k_orders, 
      			        "gu_order,pg_order,de_order,bo_active," + DBBind.Functions.ISNULL + "(dt_modified,dt_created),dt_payment,gu_company,gu_contact,id_status,im_total,id_legal",
      			        sWhereClause + " AND " + DB.gu_workarea+ "='" + gu_workarea + "' AND " + DB.gu_contact + "='" + sContact + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

      else if (sCompany.length()>0)
        oOrders = new DBSubset (DB.k_orders, 
      			        "gu_order,pg_order,de_order,bo_active," + DBBind.Functions.ISNULL + "(dt_modified,dt_created),dt_payment,gu_company,gu_contact,id_status,im_total,id_legal",
      			        sWhereClause + " AND " + DB.gu_workarea+ "='" + gu_workarea + "' AND " + DB.gu_company + "='" + sCompany + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

      else if (sSalesMan.length()>0)
        oOrders = new DBSubset (DB.k_orders, 
      			        "gu_order,pg_order,de_order,bo_active," + DBBind.Functions.ISNULL + "(dt_modified,dt_created),dt_payment,gu_company,gu_contact,id_status,im_total,id_legal",
      			        sWhereClause + " AND " + DB.gu_workarea+ "='" + gu_workarea + "' AND " + DB.gu_sales_man + "='" + sSalesMan + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

      else
        oOrders = new DBSubset (DB.k_orders, 
      			        "gu_order,pg_order,de_order,bo_active," + DBBind.Functions.ISNULL + "(dt_modified,dt_created),dt_payment,gu_company,gu_contact,id_status,im_total,id_legal",
      			        sWhereClause + " AND " + DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);

      oOrders.setMaxRows(iMaxRows);
      iOrderCount = oOrders.load (oConn, iSkip);
    }
    
    oStatusMap = GlobalDBLang.getLookUpMap((java.sql.Connection) oConn, DB.k_orders_lookup, gu_workarea, "id_status", sLanguage);

    oClientMap = new HashMap(iOrderCount+13);
    
    for (int o=0; o<iOrderCount; o++) {
      oClient = oOrders.get(7,o);
      if (null!=oClient) {
        oConts.setString(1, (String) oClient);
        oRSet = oConts.executeQuery();
        if (oRSet.next())
          if (!oClientMap.containsKey(oClient))
            oClientMap.put(oClient, "<A HREF=\"#\" onclick=\"editContact('" + (String) oClient + "','" + oRSet.getString(1) + "')\">" + Gadgets.HTMLEncode(oRSet.getString(1)) + "</A>");
        oRSet.close();
      }
      else {
        oClient = oOrders.get(6,o);
        if (null!=oClient) {
          oComps.setString(1, (String) oClient);
          oRSet = oComps.executeQuery();
          if (oRSet.next())
            if (!oClientMap.containsKey(oClient))
              oClientMap.put(oClient, "<A HREF=\"#\" onclick=\"editCompany('" + (String) oClient + "','" + oRSet.getString(1) + "')\">" + Gadgets.HTMLEncode(oRSet.getString(1)) + "</A>");
          oRSet.close();
        }
      }
    } // next
    
    oComps.close();
    oComps = null;
    
    oConts.close();
    oConts = null;
    
    oConn.close("orderlisting"); 
  }
  catch (SQLException e) {  
    oOrders = null;
    
    if (oComps!=null) { oComps.close(); oComps = null; }

    if (oConts!=null) { oConts.close(); oConts = null; }

    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("orderlisting");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');
    var menuLayer;
    dynapi.onLoad(init);
    function init() {
 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setVisible(true);
      menuLayer.setHTML(rightMenuHTML);      
    }
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // [~//Variables globales para rellenar los combos de búsqueda~]
        var jsLocationsVl = Array(<% out.write(sLocationsVl); %>);
        var jsLocationsTr = Array(<% out.write(sLocationsTr); %>);
        var jsStatusVl = Array(<% out.write(sStatusVl); %>);
        var jsStatusTr = Array(<% out.write(sStatusTr); %>);
        var jsPayStatusVl = Array(<% out.write(sPayStatusVl); %>);
        var jsPayStatusTr = Array(<% out.write(sPayStatusTr); %>);
        
        // Variables globales para traspasar la instancia clickada al menu contextual
        var jsOrderId;
        var jsOrderNm;
            
        <%
          // [~//Escribir los nombres de instancias en Arrays JavaScript~]
          // [~//Estos arrays se usan en las llamadas de borrado múltiple.~]
          
          out.write("var jsOrders = new Array(");
            for (int i=0; i<iOrderCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oOrders.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	      function createOrder() {	  	  	  
	        window.open ("order_edit_f.jsp?id_domain=<%=id_domain%>" + "&gu_workarea=<%=gu_workarea%>", "editorder", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
	      } // createOrder()

        // ----------------------------------------------------
        	
	      function createOrderForNewClient() {	  	  	  
	        window.open ("order_for_new_client_edit_f.jsp?id_domain=<%=id_domain%>" + "&gu_workarea=<%=gu_workarea%>", "editneworder", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
	      } // createOrder()

        // ----------------------------------------------------
	
	      function deleteOrders() {
	  
      	  var offset = 0;
      	  var frm = document.forms[0];
      	  var chi = frm.checkeditems;
      	  	  
      	  if (window.confirm("Are you sure that you want to delete the selected orders?")) {
      	  	  
      	    chi.value = "";	  	  
      	    frm.action = "order_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
      	  	  
      	    for (var i=0;i<jsOrders.length; i++) {
                    while (frm.elements[offset].type!="checkbox") offset++;
          	      if (frm.elements[offset].checked)
                      chi.value += jsOrders[i] + ",";
                    offset++;
      	    } // next()
      	    
      	    if (chi.value.length>0) {
      	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	      } // deleteOrders()
	
        // ----------------------------------------------------

	      function modifyOrder(id,nm) {	  
	        window.open ("order_edit_f.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" + "&gu_order=" + id + "&n_order=" + escape(nm), "editorder", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
	      }	

        // ----------------------------------------------------

	      function createDespatchAdvice(id) {
	        window.open ("create_from_order.jsp?gu_order=" + id + "&doctype=42", "createdespatchfromorder", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
	      }

        // ----------------------------------------------------

	     function createInvoice(id) {	  
	       window.open ("create_from_order.jsp?gu_order=" + id + "&doctype=47", "createinvoicefromorder", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
	     }	

        // ----------------------------------------------------

	      function editCompany(id,nm) {
	        window.open ("../crm/company_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_company=" + id + "&n_company=" + escape(nm) + "&gu_workarea=<%=gu_workarea%>", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=" + String(screen.height-80));
	      }	

        // ----------------------------------------------------

	      function editContact(id) {
	        window.open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));
	      }
        
        // ----------------------------------------------------
        
	     function sortBy(fld) {  
	       var frm = document.forms[0];
	       window.location = "order_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&findclause=" + escape(findclause) + "&company=<%=sCompany%>&contact=<%=sContact%>&salesman=<%=sSalesMan%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	      }

        // ----------------------------------------------------

        function selectAll() {          
          var frm = document.forms[0];
          for (var c=0; c<jsOrders.length; c++)                        
            eval ("frm.elements['" + jsOrders[c] + "'].click()");
        } // selectAll()

        // ------------------------------------------------------	

        function fillLooked() {
	        var frm = document.forms[0];
          var fld = getCombo(frm.sel_lookup);
          	  
	        clearCombo(frm.sel_looked);
	  
      	  if (fld=="id_status")
      	    for (var i=0; i<jsLocationsVl.length; i++)
      	      comboPush (frm.sel_looked, jsStatusTr[i], jsStatusVl[i],  false, false);
      	  else if (fld=="id_pay_status")
      	    for (var i=0; i<jsPayStatusVl.length; i++)
      	      comboPush (frm.sel_looked, jsPayStatusTr[i], jsPayStatusVl[i], false, false);
      	  else if (fld=="tx_location")
      	    for (var i=0; i<jsLocationsVl.length; i++)
      	      comboPush (frm.sel_looked, jsLocationsTr[i], jsLocationsVl[i], false, false);
        }

        // ----------------------------------------------------

        function findClause() {
	        var frm = document.forms[0];
          var fnd = "";
          
          if (frm.tx_search.value.indexOf("'")>=0 || frm.tx_search.value.indexOf(",")>=0 || frm.tx_search.value.indexOf(";")>=0) {
	          alert ("The&nbsp;" + getComboText(frm.sel_searched) + "contains invalid characters");
	          return null;
          }

          if (frm.tx_start.value.indexOf("'")>=0 || frm.tx_start.value.indexOf(",")>=0 || frm.tx_start.value.indexOf(";")>=0) {
	          alert ("Amount or initial date contain invalid characters");
	          return null;
          }

          if (frm.tx_end.value.indexOf("'")>=0 || frm.tx_end.value.indexOf(",")>=0  || frm.tx_end.value.indexOf(";")>=0) {
	          alert ("Amount or end date contain invalid characters");
	          return null;
          }

          if (getCombo(frm.sel_searched)=="pg_order" && !isIntValue(frm.tx_search.value)) {
	    alert ("Order number is not valid");
	    return null;
          }
          
	  if (getCombo(frm.sel_between)=="im_total") {
	    if (frm.tx_start.value.length>0 && isNaN(frm.tx_start.value)) {
	      alert ("Initial amount is not a valid quantity");
	      return null;
	    }
	    if (frm.tx_end.value.length>0 && isNaN(frm.tx_end.value)) {
	      alert ("Final amount is not a valid quantity");
	      return null;
	    }
	  }
	  else if (getCombo(frm.sel_between)=="dt_modified" || getCombo(frm.sel_between)=="dt_payment") {
	    if (frm.tx_start.value.length>0 && !isDate(frm.tx_start.value, "d")) {
	      alert ("Start date is not valid");
	      return null;
	    }
	    if (frm.tx_end.value.length>0 && !isDate(frm.tx_end.value, "d")) {
	      alert ("End date is not valid");
	      return null;
	    }
	  }

	  if (frm.sel_searched.selectedIndex>0 && rtrim(frm.tx_search.value)!="")
	    fnd = getCombo(frm.sel_searched) + "," + frm.tx_search.value + ";";	    
          
	  if (frm.sel_lookup.selectedIndex>=0 && frm.sel_looked.selectedIndex>=0)
	    fnd += getCombo(frm.sel_lookup) + "," + getCombo(frm.sel_looked) + ";";

	  if (frm.sel_between.selectedIndex>=0 && (frm.tx_start.value.length>0 || frm.tx_end.value.length>0)) {
	    fnd += getCombo(frm.sel_between) + ",";

	    if (frm.tx_start.value.length>0)
	      fnd += frm.tx_start.value;
	    fnd += ",";
	    
	    if (frm.tx_end.value.length>0)
	      fnd += frm.tx_end.value;
	    fnd += ";";
          }
          
          return fnd;
        } // findClause
       
       // ----------------------------------------------------
	
	function findOrder() {
	  var frm = document.forms[0];
	  var fnd = findClause();
	  
	  if (null==fnd) return;
          
          //alert (fnd);
          	  
	  window.location = "order_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>" + "&findclause=" + escape(fnd) + "&company=<%=sCompany%>&contact=<%=sContact%>&salesman=<%=sSalesMan%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // findOrder()

       // ----------------------------------------------------
	
	function discardFind() {
	  var frm = document.forms[0];
          	  
	  window.location = "order_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>" + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // discardFind()

      // ----------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {
        // [~//Funcion temporizada que se llama cada 100 milisegundos para ver si ha terminado el clonado~]
        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.de_order%>");
          document.forms[0].tx_search.value = jsOrderNm;
          findOrder();
        }
      } // findCloned()
      
      function clone() {        
        // [~//Abrir una ventana de clonado y poner un temporizador para recargar la página cuando se termine el clonado~]
        
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=order_clon&gu_instance=" + jsOrderId +"&opcode=CORD&classid=41", "cloneorder", "directories=no,toolbar=no,menubar=no,width=320,height=200");                
        intervalId = setInterval ("findCloned()", 100);
      }	// clone()
      
      
      // ------------------------------------------------------	

    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  var frm = document.forms[0];
	  
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(frm.maxresults, "<%=iMaxRows%>");

          if (frm.findclause.value.length>0) {

	    setCombo(frm.sel_searched, "<%=sSelSearch%>");
	    frm.tx_search.value = "<%=sSearch%>";
	    
	    if ("<%=sLooked%>"!="") {	    
	      setCombo(frm.sel_lookup, "<%=sSelLookup%>");
	      fillLooked();
	      setCombo(frm.sel_looked, "<%=sLooked%>");
            }
            
	    setCombo(frm.sel_between, "<%=sSelBetween%>");
	    frm.tx_start.value = "<%=sStart%>";
	    frm.tx_end.value = "<%=sEnd%>";
          }          
	} // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Orders</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onclick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Orders&nbsp;<% if (sName!=null) out.write(sName); %></FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">
      <INPUT TYPE="hidden" NAME="findclause" VALUE="<%=sFindClause%>">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="5" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Order"></TD>
        <TD ALIGN="left" VALIGN="middle"><A HREF="#" onclick="createOrder()" CLASS="linkplain">Create Order for an already existing Customer</A></TD>
        <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Orders"></TD>
        <TD ALIGN="left">
          <A HREF="javascript:deleteOrders()" CLASS="linkplain">Delete selected orders</A>
        </TD>
	      <TD ALIGN="right"><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT></TD>
      </TR>
      <TR>
        <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/shop/neworder17.gif" WIDTH="18" HEIGHT="18" BORDER="0" ALT="New Customer and Order"></TD>
        <TD ALIGN="left" VALIGN="middle"><A HREF="#" onclick="createOrderForNewClient()" CLASS="linkplain">Create order for a new customer</A></TD>
        <TD COLSPAN="3"></TD>
      </TR>
      <TR>
        <TD COLSPAN="5">
          <SELECT NAME="sel_searched" CLASS="combomini">
            <OPTION VALUE=""></OPTION>
            <OPTION VALUE="pg_order">Order number</OPTION>
            <OPTION VALUE="id_ref">Reference</OPTION>
            <OPTION VALUE="de_order">Description</OPTION>
            <OPTION VALUE="nm_client">Client</OPTION>
            <OPTION VALUE="id_legal">Legal Id</OPTION>
            <OPTION VALUE="tx_comments">Comments</OPTION>
          </SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="tx_search" MAXLENGTH="30" SIZE="10" VALUE="">
          &nbsp;<FONT CLASS="textsmall">and</FONT>&nbsp;
          <SELECT NAME="sel_lookup" CLASS="combomini" onchange="fillLooked()"><OPTION VALUE=""></OPTION><OPTION VALUE="id_status">Status</OPTION><OPTION VALUE="id_pay_status">Paydate</OPTION><OPTION VALUE="tx_location">Subsidiary</OPTION></SELECT>
          <SELECT NAME="sel_looked" CLASS="combomini"></SELECT>
          &nbsp;<FONT CLASS="textsmall">and</FONT>&nbsp;
          <SELECT NAME="sel_between" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="dt_modified">Date Upd.</OPTION><OPTION VALUE="dt_payment">Payment date</OPTION><OPTION VALUE="im_total">Amount</OPTION></SELECT>
          &nbsp;<FONT CLASS="textsmall">between</FONT>&nbsp;
          <INPUT CLASS="textmini" TYPE="text" NAME="tx_start" MAXLENGTH="10" SIZE="10" VALUE="">
          &nbsp;<FONT CLASS="textsmall">and</FONT>&nbsp;
          <INPUT CLASS="textmini" TYPE="text" NAME="tx_end" MAXLENGTH="10" SIZE="10" VALUE="">
	  &nbsp;<A HREF="javascript:findOrder();" TITLE="Search"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Find Orders"></A>
	  &nbsp;&nbsp;&nbsp;<A HREF="javascript:discardFind();" TITLE="Discard Find Filter"><IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></A>
        </TD>
      </TR>      
      <TR><TD COLSPAN="5" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="9" ALIGN="left">
<%
    	  // [~//Pintar los enlaces de siguiente y anterior~]
    
    	  if (iOrderCount>0) {
            if (iSkip>0) // [~//Si iSkip>0 entonces hay registros anteriores~]
              out.write("            <A HREF=\"order_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&findclause=" + sFindClause + "&selected=" + request.getParameter("selected") + "&contact=" + sContact + "&company=" + sCompany + "&salesman=" + sSalesMan + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oOrders.eof())
              out.write("            <A HREF=\"order_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&findclause=" + sFindClause + "&selected=" + request.getParameter("selected") + "&contact=" + sContact + "&company=" + sCompany + "&salesman=" + sSalesMan + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iOrderCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Number</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(9);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Status</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(320f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Description</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Date Upd.</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(6);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Payment Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Client</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(10);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Amount</B></TD>          
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD>
        </TR>
<%	  
	  for (int i=0; i<iOrderCount; i++) {
            sOrderId = oOrders.getString(0,i);
            sOrderPg = Gadgets.leftPad(String.valueOf(oOrders.getInt(1,i)),'0',10);
            sOrderDe = oOrders.getStringNull(2,i,"");
	               
            if (sOrderDe.length()>50) sOrderDe = sOrderDe.substring(0,50)+"...";
              
            if (oOrders.isNull(3,i))
  	      bActive  = false;
            else
  	      bActive  = (oOrders.getShort(3,i)==(short)1);

            if (oOrders.isNull(4,i)) sOrderDt = ""; else sOrderDt = oOrders.getDateShort(4,i);
            if (oOrders.isNull(5,i)) sPayDt = ""; else sPayDt = oOrders.getDateShort(5,i);
            
            oClient = oOrders.get(7,i);
            if (null!=oClient)
              sClient = (String) oClientMap.get(oClient);
            else {
              oClient = oOrders.get(6,i);
              if (null!=oClient)
                sClient = (String) oClientMap.get(oClient);
              else
                sClient = "";
            }            
            
            if (!oOrders.isNull(8,i)) sStatus = (String) oStatusMap.get(oOrders.getString(8,i)); else sStatus = "";
            if (!oOrders.isNull(9,i)) {
              sTotalIm = String.valueOf(oOrders.getFloat(9,i,2));
              dGrandTotal = dGrandTotal.add(oOrders.getDecimal(9,i));              
            }
            else
              sTotalIm = "";

	    bHasLegalId = !oOrders.isNull(10,i);

	    sStrip = String.valueOf((i%2)+1);   
%>
            <TR HEIGHT="14">
              <TD CLASS="strip<%=sStrip%>"><INPUT TYPE="radio" NAME="active" <% if (bActive) out.write("CHECKED");%>></TD>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<A HREF="#" oncontextmenu="jsOrderId='<%=sOrderId%>'; jsOrderNm='<%=sOrderDe.replace((char)39,(char)32)%>'; <% if (bHasLegalId) out.write("enableRightMenuOption(5);"); else out.write("disableRightMenuOption(5);"); %> return showRightMenu(event);" onclick="modifyOrder('<%=sOrderId%>')" TITLE="Click Right Mouse Button for Context Menu"><% out.write(sOrderPg); %></A></TD>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<% out.write(sStatus); %></TD>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<% out.write(sOrderDe); %></TD>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<% out.write(sOrderDt); %></TD>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<% out.write(sPayDt==null ? "" : sPayDt); %></TD>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<% out.write(sClient); %></TD>
              <TD CLASS="strip<%=sStrip%>" ALIGN="right">&nbsp;<% out.write(sTotalIm); %></TD>
              <TD CLASS="strip<%=sStrip%>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<%=sOrderId%>"></TD>
            </TR>
<%        } // next(i) %>          	  
        <TR HEIGHT="14">
          <TD COLSPAN="6"></TD>
          <TD><FONT CLASS="formstrong">Total</FONT></TD>
          <TD ALIGN="right"><FONT CLASS="formstrong"><% out.write(dGrandTotal.toString()); %></FONT></TD>
          <TD></TD>
        </TR>
        <TR>
          <TD COLSPAN="9" ALIGN="left">
<%
    	  // [~//Pintar los enlaces de siguiente y anterior~]
    
    	  if (iOrderCount>0) {
            if (iSkip>0) // [~//Si iSkip>0 entonces hay registros anteriores~]
              out.write("            <A HREF=\"order_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&findclause=" + sFindClause + "&selected=" + request.getParameter("selected") + "&contact=" + sContact + "&company=" + sCompany + "&salesman=" + sSalesMan + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oOrders.eof())
              out.write("            <A HREF=\"order_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&findclause=" + sFindClause + "&selected=" + request.getParameter("selected") + "&contact=" + sContact + "&company=" + sCompany + "&salesman=" + sSalesMan + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iOrderCount)
%>
          </TD>
        </TR>
      </TABLE>
    </FORM>
    <SCRIPT TYPE="text/javascript">
      addMenuOption("Open","modifyOrder(jsOrderId)",1);
      addMenuSeparator();
      addMenuOption("Duplicate","clone()",0);
      addMenuSeparator();
      addMenuOption("New Despatch Advice","createDespatchAdvice(jsOrderId)",0);
      addMenuOption("New Invoice","createInvoice(jsOrderId)",0);
    </SCRIPT>
</BODY>
</HTML>

