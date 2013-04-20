<%@ page import="java.math.BigDecimal,java.net.URLDecoder,java.util.Date,java.util.HashMap,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.*,com.knowgate.hipergate.QueryByForm,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");
  
  int iScreenWidth;
  float fScreenRatio;

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String screen_width = request.getParameter("screen_width");
  String output = nullif(request.getParameter("output"),"html");

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
        
  int iDespatchAdvicesCount = 0;
  DBSubset oDespatchAdvices;        
  String sSortBy;
  int iSortBy;  
  int iMaxRows;
  int iSkip;

  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "100"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (request.getParameter("sortby")!=null)
    sSortBy = request.getParameter("sortby");
  else
    sSortBy = "";
  
  if (sSortBy.length()>0) {
    if (sSortBy.indexOf("DESC")>0)
      iSortBy = Integer.parseInt(sSortBy.substring(0,sSortBy.indexOf("DESC")).trim());
    else
      iSortBy = Integer.parseInt(sSortBy.trim());
  } else {
    iSortBy = 0;
  }
      
  String sStatusVl = "";
  String sStatusTr = "";
  String sSelSearch = "", sSearch = "", sSelLookup = "", sLooked = "", sSelBetween = "", sStart = "", sEnd = "";
  String sDespatchAdviceId,sDespatchAdvicePg,sDespatchAdviceDt,slegalNm,sContNm,sClient,sStatus,sTotalIm,sStrip,sLegalId,sShopNm;
  BigDecimal dGrandTotal = new BigDecimal("0");
  Object oClient;
  boolean bFirst;

  HashMap oStatusMap = null;
  HashMap oClientMap = null;
  QueryByForm oQBF;
  String sStatusLookUp="";

  ResultSet oRSet;
  PreparedStatement oName  = null;
  PreparedStatement oComps = null;
  PreparedStatement oConts = null;
  PreparedStatement oLooks = null;

  JDCConnection oConn = null;  
  
  try {
    oConn = GlobalDBBind.getConnection("despatchlisting"); 
    
    sStatusLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_despatch_advices_lookup, gu_workarea, DB.id_status, sLanguage);

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
    
    oLooks = oConn.prepareStatement("SELECT " + DB.vl_lookup + "," + DB.tr_ + sLanguage + " FROM " + DB.k_despatch_advices_lookup + " WHERE " + DB.gu_owner + "='" + gu_workarea + "' AND " + DB.id_section  + "=? ORDER BY 2", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    
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
    
    oLooks.close();
    
    oComps = oConn.prepareStatement("SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
      oConts = oConn.prepareStatement("SELECT CONCAT(COALESCE(" + DB.tx_name + ",''),' ',COALESCE(" + DB.tx_surname + ",'')) FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    else
      oConts = oConn.prepareStatement("SELECT " + DBBind.Functions.ISNULL + "(" + DB.tx_name + ",'')" + DBBind.Functions.CONCAT + "' '" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(" + DB.tx_surname + ",'') FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    
    if (sWhere.length()>0) {

      oQBF = new QueryByForm("file://" + sStorage + "/qbf/" + request.getParameter("queryspec") + ".xml");
    
      oDespatchAdvices = new DBSubset (oQBF.getBaseObject(), 
      			             "b.gu_despatch,b.pg_despatch,b.gu_despatch," + DBBind.Functions.ISNULL + "(b.dt_modified,b.dt_created),NULL AS dt_payment,b.gu_company,b.gu_contact,b.id_status,b.im_total,b.id_legal",
      			             "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iSortBy>0 ? " ORDER BY " + sSortBy : ""), iMaxRows);      				 

      oDespatchAdvices.setMaxRows(iMaxRows);
      iDespatchAdvicesCount = oDespatchAdvices.load (oConn, iSkip);
    }
    
    else if (sFindClause.length()==0) {

      if (sContact.length()>0)
        oDespatchAdvices = new DBSubset (DB.k_despatch_advices +" i," + DB.k_shops + " s", 
      			          "i.gu_despatch,i.pg_despatch,i.gu_despatch," + DBBind.Functions.ISNULL + "(i.dt_modified,i.dt_created),NULL AS dt_payment,i.gu_company,i.gu_contact,i.id_status,i.im_total,i.id_legal,s.nm_shop",
      			          "i.gu_shop=s.gu_shop AND i." + DB.gu_contact + "='" + sContact + "' " + (iSortBy>0 ? " ORDER BY " + sSortBy : ""), iMaxRows);      				 

      else if (sCompany.length()>0)
        oDespatchAdvices = new DBSubset (DB.k_despatch_advices +" i," + DB.k_shops + " s", 
      			          "i.gu_despatch,i.pg_despatch,i.gu_despatch," + DBBind.Functions.ISNULL + "(i.dt_modified,i.dt_created),NULL AS dt_payment,i.gu_company,i.gu_contact,i.id_status,i.im_total,i.id_legal,s.nm_shop",
      			          "i.gu_shop=s.gu_shop AND i." + DB.gu_company + "='" + sCompany + "' " + (iSortBy>0 ? " ORDER BY " + sSortBy : ""), iMaxRows);      				 

      else if (sSalesMan.length()>0)
        oDespatchAdvices = new DBSubset (DB.k_despatch_advices +" i," + DB.k_shops + " s", 
      			          "i.gu_despatch,i.pg_despatch,i.gu_despatch," + DBBind.Functions.ISNULL + "(i.dt_modified,i.dt_created),NULL AS dt_payment,i.gu_company,i.gu_contact,i.id_status,i.im_total,i.id_legal,s.nm_shop",
      			          "i.gu_shop=s.gu_shop AND i." + DB.gu_sales_man + "='" + sSalesMan + "' " + (iSortBy>0 ? " ORDER BY " + sSortBy : ""), iMaxRows);      				 
      
      else
        oDespatchAdvices = new DBSubset (DB.k_despatch_advices +" i," + DB.k_shops + " s", 
      			          "i.gu_despatch,i.pg_despatch,i.gu_despatch," + DBBind.Functions.ISNULL + "(i.dt_modified,i.dt_created),NULL AS dt_payment,i.gu_company,i.gu_contact,i.id_status,i.im_total,i.id_legal,s.nm_shop",
      			          "i.gu_shop=s.gu_shop AND i." + DB.gu_workarea + "='" + gu_workarea + "'" + (iSortBy>0 ? " ORDER BY " + sSortBy : ""), iMaxRows);      				 
      
      oDespatchAdvices.setMaxRows(iMaxRows);
      iDespatchAdvicesCount = oDespatchAdvices.load (oConn, iSkip);
    }
    else {
      String sWhereClause = "";
      String[] aFindClause = Gadgets.split(sFindClause, ';');
      String[] aFindField;
      
      for (int c=0; c<aFindClause.length; c++) {
        if (aFindClause[c].length()>0) {

          aFindField = Gadgets.split(aFindClause[c], ',');


          if (sWhereClause.length()>0) sWhereClause += " AND ";
  
          if (aFindField[0].equalsIgnoreCase(DB.pg_despatch)) {
            sWhereClause += "i."+DB.pg_despatch + "=" + aFindField[1];
            sSelSearch = DB.pg_despatch;
            sSearch = aFindField[1];
          }        
          else if (aFindField[0].equalsIgnoreCase(DB.nm_client)
                || aFindField[0].equalsIgnoreCase(DB.gu_despatch)
                || aFindField[0].equalsIgnoreCase(DB.tx_comments)) {
            sWhereClause += "i."+aFindField[0] + " " + DBBind.Functions.ILIKE + " '%" + aFindField[1] + "%'";
  
            sSelSearch = aFindField[0];
            sSearch = aFindField[1];
          }
          else if (aFindField[0].equalsIgnoreCase(DB.id_legal)) {
            sWhereClause += "i."+aFindField[0] + " ='" + aFindField[1] + "'";
  
            sSelSearch = DB.id_legal;
            sSearch = aFindField[1];
          }
          else if (aFindField[0].equalsIgnoreCase(DB.id_status)) {
            sWhereClause += "i."+aFindField[0] + " = '" + aFindField[1] + "'";
            sSelLookup = aFindField[0];
            sLooked = aFindField[1];
          }        
          else if (aFindField[0].equalsIgnoreCase(DB.im_total)) {
            if (aFindField[1].length()>0 && aFindField[2].length()>0)
              sWhereClause += "i."+DB.im_total + " BETWEEN " + aFindField[1] + " AND " + aFindField[2];
            else if (aFindField[1].length()==0)
              sWhereClause += "i."+DB.im_total + "<=" + aFindField[2];
            else if (aFindField[2].length()==0)
              sWhereClause += "i."+DB.im_total + ">=" + aFindField[1];
  
  	  sSelBetween = DB.im_total;
  	  sStart = aFindField[1];
  	  sEnd = aFindField[2];
          }
          else if (aFindField[0].equalsIgnoreCase(DB.dt_modified)
                || aFindField[0].equalsIgnoreCase(DB.dt_created)) {
  	  
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
              sWhereClause += "i."+aFindField[0] + " BETWEEN " + DBBind.escape(dtStart, "ts") + " AND " + DBBind.escape(dtEnd, "ts");
  	    else if (aFindField[1].length()==0)
              sWhereClause += "i."+aFindField[0] + "<=" + DBBind.escape(dtEnd, "ts");
  	    else if (aFindField[2].length()==0)
              sWhereClause += "i."+aFindField[0] + ">=" + DBBind.escape(dtStart, "ts");		            
          } // fi (aFindField[0]=="dt_modified" || aFindField[0]=="dt_created")

        } // fi (aFindClause[c]!="")
      } // next

      if (sContact.length()>0)
        oDespatchAdvices = new DBSubset (DB.k_despatch_advices +" i," + DB.k_shops + " s",
      			          "i.gu_despatch,i.pg_despatch,i.gu_despatch," + DBBind.Functions.ISNULL + "(i.dt_modified,i.dt_created),NULL AS dt_payment,i.gu_company,i.gu_contact,i.id_status,i.im_total,i.id_legal,s.nm_shop",
      			          "i.gu_shop=s.gu_shop AND " + sWhereClause + " AND i." + DB.gu_workarea+ "='" + gu_workarea + "' AND i." + DB.gu_contact + "='" + sContact + "' " + (iSortBy>0 ? " ORDER BY " + sSortBy : ""), iMaxRows);

      else if (sCompany.length()>0)
        oDespatchAdvices = new DBSubset (DB.k_despatch_advices +" i," + DB.k_shops + " s",
      			          "i.gu_despatch,i.pg_despatch,i.gu_despatch," + DBBind.Functions.ISNULL + "(i.dt_modified,i.dt_created),NULL AS dt_payment,i.gu_company,i.gu_contact,i.id_status,i.im_total,i.id_legal,s.nm_shop",
      			          "i.gu_shop=s.gu_shop AND " + sWhereClause + " AND i." + DB.gu_workarea+ "='" + gu_workarea + "' AND i." + DB.gu_company + "='" + sCompany + "' " + (iSortBy>0 ? " ORDER BY " + sSortBy : ""), iMaxRows);

      else if (sSalesMan.length()>0)
        oDespatchAdvices = new DBSubset (DB.k_despatch_advices +" i," + DB.k_shops + " s",
      			          "i.gu_despatch,i.pg_despatch,i.gu_despatch," + DBBind.Functions.ISNULL + "(i.dt_modified,i.dt_created),NULL AS dt_payment,i.gu_company,i.gu_contact,i.id_status,i.im_total,i.id_legal,s.nm_shop",
      			          "i.gu_shop=s.gu_shop AND " + sWhereClause + " AND i." + DB.gu_workarea+ "='" + gu_workarea + "' AND i." + DB.gu_sales_man + "='" + sSalesMan + "' " + (iSortBy>0 ? " ORDER BY " + sSortBy : ""), iMaxRows);

      else
        oDespatchAdvices = new DBSubset (DB.k_despatch_advices +" i," + DB.k_shops + " s",
      			          "i.gu_despatch,i.pg_despatch,i.gu_despatch," + DBBind.Functions.ISNULL + "(i.dt_modified,i.dt_created),NULL AS dt_payment,i.gu_company,i.gu_contact,i.id_status,i.im_total,i.id_legal,s.nm_shop",
      			          "i.gu_shop=s.gu_shop AND " + sWhereClause + " AND i." + DB.gu_workarea+ "='" + gu_workarea + "'" + (iSortBy>0 ? " ORDER BY " + sSortBy : ""), iMaxRows);

      oDespatchAdvices.setMaxRows(iMaxRows);
      iDespatchAdvicesCount = oDespatchAdvices.load (oConn, iSkip);
    }
    
    oStatusMap = GlobalDBLang.getLookUpMap((java.sql.Connection) oConn, DB.k_despatch_advices_lookup, gu_workarea, "id_status", sLanguage);

    oClientMap = new HashMap(iDespatchAdvicesCount+13);
    
    for (int o=0; o<iDespatchAdvicesCount; o++) {
      oClient = oDespatchAdvices.get(6,o);
      if (null!=oClient) {
        oConts.setString(1, (String) oClient);
        oRSet = oConts.executeQuery();
        if (oRSet.next())
          if (!oClientMap.containsKey(oClient)) {
            if (output.equals("csv"))
              oClientMap.put(oClient, oRSet.getString(1));
            else 
              oClientMap.put(oClient, "<A HREF=\"#\" onclick=\"editContact('" + (String) oClient + "','" + oRSet.getString(1) + "')\">" + Gadgets.HTMLEncode(oRSet.getString(1)) + "</A>");
          }        	
        oRSet.close();
      }
      else {
        oClient = oDespatchAdvices.get(5,o);
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
    
    oConn.close("despatchlisting"); 
  }
  catch (SQLException e) {  
    oDespatchAdvices = null;
    
    if (oComps!=null) { oComps.close(); oComps = null; }

    if (oConts!=null) { oConts.close(); oConts = null; }

    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("despatchlisting");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  if (output.equals("html")) {
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

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
  <SCRIPT TYPE="text/javascript" DEFER="true">
    <!--
        var jsStatusVl = Array(<% out.write(sStatusVl); %>);
        var jsStatusTr = Array(<% out.write(sStatusTr); %>);
        
        var jsDespatchAdviceId;
            
        <%
          out.write("var jsDespatchAdvices = new Array(");
            for (int i=0; i<iDespatchAdvicesCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oDespatchAdvices.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

	function editContact(id) {
	  self.open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));
	}

        // ----------------------------------------------------

	function editCompany(id,nm) {
	  self.open ("../crm/company_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_company=" + id + "&n_company=" + escape(nm) + "&gu_workarea=<%=gu_workarea%>", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=" + String(screen.height-80));
	}	

        // ----------------------------------------------------
        	
	function createDespatchAdvice() {	  	  	  
	  window.open ("despatch_edit_f.jsp?id_domain=<%=id_domain%>" + "&gu_workarea=<%=gu_workarea%>", "editdespatch", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
	} // createDespatchAdvice()

        // ----------------------------------------------------
	
	function deleteDespatchAdvices() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure that you want to delete selected despatch advices?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "despatch_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsDespatchAdvices.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsDespatchAdvices[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteDespatchAdvices()

        // ----------------------------------------------------
	
	function updateStatus() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  
	  if (frm.sel_status.selectedIndex<=0) {
	    alert ("A status must be specified for Despatch Advices");
	    return false;
	  }
	  
	  if (window.confirm("Are you sure that you want to change the status of selected addespatch vices?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "despatch_status_updt.jsp?id_status="+getCombo(frm.sel_status)+"&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsDespatchAdvices.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsDespatchAdvices[i] + ",";
              offset++;
	    } // next()
	    
	    	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } else {
	      alert ("At least one Despacth Advice to be modified must be selected");
            }
          } // fi (confirm)
	} // updateStatus()
	
        // ----------------------------------------------------

	function modifyDespatchAdvice(id) {
	  
	  self.open ("despatch_edit_f.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>" + "&gu_despatch=" + id, "editdespatch", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
	}	
        
        // ----------------------------------------------------
        
	function sortBy(fld) {
	  // Ordenar por un campo
	  
	  var frm = document.forms[0];
	  
	  window.location = "despatch_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&sortby=" + fld + "&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&findclause=" + escape(frm.findclause.value) + "&company=<%=sCompany%>&contact=<%=sContact%>&salesman=<%=sSalesMan%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	}			

        // ----------------------------------------------------
        
	function excelView() {
	  
	  var frm = document.forms[0];
	  
	  if ("<%=sSortBy%>"!="")
	    window.location = "despatch_list.jsp?output=csv&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&sortby=" + fld + "&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&findclause=" + escape(frm.findclause.value) + "&company=<%=sCompany%>&contact=<%=sContact%>&salesman=<%=sSalesMan%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  else
	    window.location = "despatch_list.jsp?output=csv&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&findclause=" + escape(frm.findclause.value) + "&company=<%=sCompany%>&contact=<%=sContact%>&salesman=<%=sSalesMan%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);	  
	}			

        // ----------------------------------------------------

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsDespatchAdvices.length; c++)                        
            eval ("frm.elements['" + jsDespatchAdvices[c] + "'].click()");
        } // selectAll()

        // ------------------------------------------------------	

        function fillLooked() {
	  var frm = document.forms[0];
          var fld = getCombo(frm.sel_lookup);
          	  
	  clearCombo(frm.sel_looked);
	  
	  if (fld=="id_status")
	    for (var i=0; i<jsStatusVl.length; i++)
	      comboPush (frm.sel_looked, jsStatusTr[i], jsStatusVl[i],  false, false);
        }

        // ----------------------------------------------------

        function findClause() {
	  var frm = document.forms[0];
          var fnd = "";
          
          if (frm.tx_search.value.indexOf("'")>=0 || frm.tx_search.value.indexOf(",")>=0 || frm.tx_search.value.indexOf(";")>=0) {
	    alert ("Invalid characters at field "+getComboText(frm.sel_searched));
	    return null;
          }

          if (frm.tx_start.value.indexOf("'")>=0 || frm.tx_start.value.indexOf(",")>=0 || frm.tx_start.value.indexOf(";")>=0) {
	    alert ("Start date contains invalid characters");
	    return null;
          }

          if (frm.tx_end.value.indexOf("'")>=0 || frm.tx_end.value.indexOf(",")>=0  || frm.tx_end.value.indexOf(";")>=0) {
	    alert ("End date contains invalid characters");
	    return null;
          }

          if ((frm.tx_start.value.length>0 || frm.tx_end.value.length>0) && frm.sel_between.selectedIndex<=0) {
	    alert ("A field for restricting date or amount is required");
	    return null;
          }

          if (getCombo(frm.sel_searched)=="pg_despatch" && !isIntValue(frm.tx_search.value)) {
	    alert ("Despacth Advice Number is not valid");
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
	  else if (getCombo(frm.sel_between)=="dt_modified") {
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
	
	function findDespatchAdvice() {
	  var frm = document.forms[0];
	  var fnd = findClause();
	  
	  if (null==fnd) return;
          
	  window.location = "despatch_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&sortby=<%=sSortBy%>" + "&findclause=" + escape(fnd) + "&company=<%=sCompany%>&contact=<%=sContact%>&salesman=<%=sSalesMan%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // findDespatchAdvice()

       // ----------------------------------------------------
	
	function discardFind() {
	  var frm = document.forms[0];
          	  
	  window.location = "despatch_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&sortby=<%=sSortBy%>" + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // discardFind()

      // ----------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_between, "<%=DB.dt_created%>");
          document.forms[0].tx_start.value = dateToString(new Date(), "d");
          findDespatchAdvice();
        }
      } // findCloned()
      
      function clone() {        
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&datastruct=despatch_clon&gu_instance=" + jsDespatchAdviceId +"&opcode=CDNT&classid=42", "clonedespatch", "directories=no,toolbar=no,menubar=no,width=320,height=200");                
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
  <TITLE>hipergate :: Despatch Advices</TITLE>
</HEAD>
<BODY CLASS="htmlbody" TOPMARGIN="8" MARGINHEIGHT="8" onclick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Despatch Advices&nbsp;<% if (sName!=null) out.write(sName); %></FONT></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">
      <INPUT TYPE="hidden" NAME="findclause" VALUE="<%=sFindClause%>">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE SUMMARY="Filter Buttons" CELLSPACING="2" CELLPADDING="2" BORDER="0" WIDTH="98%">
        <TR>
          <TD NOWRAP>
            <TABLE SUMMARY="Top Options Line" BORDER="0">
              <TR>
                <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Despatch Advice"></TD>
                <TD ALIGN="left" VALIGN="center"><A HREF="#" onclick="createDespatchAdvice()" CLASS="linkplain">New</A></TD>
                <TD>&nbsp;&nbsp;</TD>
                <TD ALIGN="right">&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Despatch Advice"></TD>
                <TD ALIGN="left"><A HREF="javascript:deleteDespatchAdvices()" CLASS="linkplain">Delete</A></TD>
                <TD>&nbsp;&nbsp;</TD>
	        <TD>
	          <IMG SRC="../images/images/excel16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View as Excel">&nbsp;
	          <A HREF="javascript:excelView()" CLASS="linkplain">Excel</A>
	        </TD>
                <TD>&nbsp;&nbsp;</TD>
	        <TD>
	          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
	        </TD>
              </TR>
            </TABLE>
          </TD>
        </TR>
        <TR>
          <TD NOWRAP>
            <TABLE SUMMARY="Bottom Options Line" BORDER="0" WIDTH="100%">
              <TR>
		<TD>
                  <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="pg_despatch">Despatch Advice Num</OPTION><OPTION VALUE="nm_client">Client</OPTION><OPTION VALUE="id_legal">Legal Id</OPTION><OPTION VALUE="tx_comments">Comments</OPTION></SELECT>
                  <INPUT CLASS="textmini" TYPE="text" NAME="tx_search" MAXLENGTH="30" SIZE="10" VALUE="">
                  &nbsp;<FONT CLASS="textsmall">and</FONT>&nbsp;
                  <SELECT NAME="sel_lookup" CLASS="combomini" onchange="fillLooked()"><OPTION VALUE=""></OPTION><OPTION VALUE="id_status">Status</OPTION></SELECT>
                  <SELECT NAME="sel_looked" CLASS="combomini"></SELECT>
                  &nbsp;<FONT CLASS="textsmall">and</FONT>&nbsp;
                  <SELECT NAME="sel_between" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="dt_created">Creation Date</OPTION><OPTION VALUE="dt_modified">Date Upd.</OPTION><OPTION VALUE="im_total">Amount</OPTION></SELECT>
                  &nbsp;<FONT CLASS="textsmall">between</FONT>&nbsp;
                  <INPUT CLASS="textmini" TYPE="text" NAME="tx_start" MAXLENGTH="10" SIZE="10" VALUE="">
                  &nbsp;<FONT CLASS="textsmall">and</FONT>&nbsp;
                  <INPUT CLASS="textmini" TYPE="text" NAME="tx_end" MAXLENGTH="10" SIZE="10" VALUE="">
	          &nbsp;<A HREF="javascript:findDespatchAdvice();" TITLE="Buscar"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search Despacth Advice"></A>
	          &nbsp;&nbsp;&nbsp;<A HREF="javascript:discardFind();" TITLE="Discard Find Filter"><IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></A>
                </TD>
              </TR>
            <TABLE>
          </TD>
        </TR>      
      </TABLE><!-- Filter Buttons -->
      <BR>
      <TABLE SUMMARY="Dispatch Notes Rows" CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="7" ALIGN="left">
<%    
    	  if (iDespatchAdvicesCount>0) {
            if (iSkip>0) 
              out.write("            <A HREF=\"despatch_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&sortby=" + sSortBy + "&findclause=" + sFindClause + "&selected=" + request.getParameter("selected") + "&contact=" + sContact + "&company=" + sCompany + "&salesman=" + sSalesMan + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");    
            if (!oDespatchAdvices.eof())
              out.write("            <A HREF=\"despatch_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&sortby=" + sSortBy + "&findclause=" + sFindClause + "&selected=" + request.getParameter("selected") + "&contact=" + sContact + "&company=" + sCompany + "&salesman=" + sSalesMan + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iDespatchAdvicesCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="80">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iSortBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Number</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="128">&nbsp;<A HREF="javascript:sortBy(9);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iSortBy==9 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Status</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="100">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iSortBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Date Upd.</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="200">&nbsp;<B>Cliente</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="100">&nbsp;<A HREF="javascript:sortBy(10);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iSortBy==10 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Amount</B></TD>          
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="18"><A HREF="#" onclick="selectAll()" TITLE="Select all"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD>
        </TR>
<%	  
	  for (int i=0; i<iDespatchAdvicesCount; i++) {
	  
            sDespatchAdviceId = oDespatchAdvices.getString(0,i);
            sDespatchAdvicePg = Gadgets.leftPad(String.valueOf(oDespatchAdvices.getInt(1,i)),'0',10);
              
            sDespatchAdviceDt = oDespatchAdvices.getDateShort(3,i);
            
            oClient = oDespatchAdvices.get(6,i);
            if (null!=oClient)
              sClient = (String) oClientMap.get(oClient);
            else {
              oClient = oDespatchAdvices.get(5,i);
              if (null!=oClient)
                sClient = (String) oClientMap.get(oClient);
              else
                sClient = "";
            }            
            
            sStatus = oDespatchAdvices.getStringNull(7,i,"");
            if (!oDespatchAdvices.isNull(8,i)) {
              sTotalIm = String.valueOf(oDespatchAdvices.getFloat(8,i,2)).trim();
              dGrandTotal = dGrandTotal.add(oDespatchAdvices.getDecimal(8,i));              
            }
            else
              sTotalIm = "";

	    sStrip = String.valueOf((i%2)+1);   
%>            
            <TR>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<A HREF="#" oncontextmenu="jsDespatchAdviceId='<%=sDespatchAdviceId%>';return showRightMenu(event);" onclick="modifyDespatchAdvice('<%=sDespatchAdviceId%>')"><% out.write(sDespatchAdvicePg); %></A></TD>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<%=sStatus%></TD>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<%=sDespatchAdviceDt%></TD>
              <TD CLASS="strip<%=sStrip%>">&nbsp;<%=sClient%></TD>
              <TD CLASS="strip<%=sStrip%>" ALIGN="right">&nbsp;<%=sTotalIm%></TD>
              <TD CLASS="strip<%=sStrip%>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<%=sDespatchAdviceId%>"></TD>
            </TR>
<%        } // next(i) %>          	  
        <TR>
          <TD COLSPAN="4"></TD>
          <TD ALIGN="right"><FONT CLASS="formstrong">Total&nbsp;</FONT></TD>
          <TD ALIGN="right"><FONT CLASS="formstrong"><%=dGrandTotal.setScale(2, BigDecimal.ROUND_HALF_UP)%></FONT></TD>
	  <TD></TD>
        </TR>
        <TR>
          <TD COLSPAN="7" ALIGN="left">
<%
    	  // //Pintar los enlaces de siguiente y anterior
    
    	  if (iDespatchAdvicesCount>0) {
            if (iSkip>0) // //Si iSkip>0 entonces hay registros anteriores
              out.write("            <A HREF=\"despatch_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&sortby=" + sSortBy + "&findclause=" + sFindClause + "&selected=" + request.getParameter("selected") + "&contact=" + sContact + "&company=" + sCompany + "&salesman=" + sSalesMan + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oDespatchAdvices.eof())
              out.write("            <A HREF=\"despatch_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&sortby=" + sSortBy + "&findclause=" + sFindClause + "&selected=" + request.getParameter("selected") + "&contact=" + sContact + "&company=" + sCompany + "&salesman=" + sSalesMan + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iDespatchAdvicesCount)
%>
          </TD>
        </TR>
        <TR>
          <TD COLSPAN="7" ALIGN="left" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3">
        </TR>
        <TR>
          <TD COLSPAN="3">
            <FONT CLASS="formplain">Change selected Despatch Advces status to</FONT>
          </TD>
          <TD COLSPAN="4">
            <SELECT NAME="sel_status" CLASS="combomini" STYLE="width:180px"><OPTION VALUE="" SELECTED><%=sStatusLookUp%></SELECT>
          </TD>
          <TD></TD>
        </TR>
        <TR>
          <TD COLSPAN="7" ALIGN="left" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3">
        </TR>
      </TABLE>
    </FORM>
    <SCRIPT TYPE="text/javascript">
      addMenuOption("Open","modifyDespatchAdvice(jsDespatchAdviceId)",1);
      addMenuSeparator();
      addMenuOption("Duplicate","clone()",0);
      addMenuSeparator();
    </SCRIPT>
</BODY>
</HTML><% } else { // output=="csv"
   response.setContentType("text/tab-separated-values");
   response.setHeader("Content-Disposition", "attachment; filename=\"despatchadvices.txt\"");

   out.write("Number\tStatus\tInvoicing Date\tDue date\tLegal Name\tLegal Id.\tTotal\tCatalog\n");
   
   for (int i=0; i<iDespatchAdvicesCount; i++) {
	  
     sDespatchAdviceId = oDespatchAdvices.getString(0,i);
     sDespatchAdvicePg = Gadgets.leftPad(String.valueOf(oDespatchAdvices.getInt(1,i)),'0',10);              
     sDespatchAdviceDt = oDespatchAdvices.getDateShort(3,i);
     oClient = oDespatchAdvices.get(6,i);
     if (null!=oClient)
       sClient = (String) oClientMap.get(oClient);
     else {
       oClient = oDespatchAdvices.get(5,i);
     if (null!=oClient)
       sClient = (String) oClientMap.get(oClient);
     else
       sClient = "";
     }                        
     sStatus = oDespatchAdvices.getStringNull(7,i,"");
     if (!oDespatchAdvices.isNull(8,i)) {
       sTotalIm = String.valueOf(oDespatchAdvices.getFloat(8,i,2));
       dGrandTotal = dGrandTotal.add(oDespatchAdvices.getDecimal(8,i));              
     }
     else
       sTotalIm = "";
     sLegalId = oDespatchAdvices.getString(9,i);
     sShopNm = oDespatchAdvices.getString(10,i);
     
     out.write(sDespatchAdvicePg+"\t"+sStatus+"\t"+sDespatchAdviceDt+"\t"+"\t"+sClient+"\t"+sLegalId+"\t"+sTotalIm+"\t"+sShopNm+"\n");
   } // next
} %> 