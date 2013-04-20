<%@ page import="java.net.URLDecoder,java.util.Date,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.hipergate.QueryByForm,com.knowgate.misc.Gadgets,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/reqload.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
  String sFace = nullif(request.getParameter("face"),getCookie(request,"face","crm"));
  String sToday = DBBind.escape(new Date(), "shortDate");

  int iScreenWidth;
  float fScreenRatio;
    
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm","");
  String id_user = getCookie (request, "userid", null);
  String face = nullif(request.getParameter("face"),getCookie(request,"face","crm"));  
  String gu_workarea = getCookie(request,"workarea",null); 
  String screen_width = request.getParameter("screen_width");

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;

  String sField = safeSqlGetParameter(request,"field","").trim();
  String sFind = safeSqlGetParameter(request,"find","").trim();
  String sWhere = nullif(request.getParameter("where")).trim();
  String sQuery = nullif(request.getParameter("query")).trim();
  String sPrivate = safeSqlGetParameter(request,"private","0").trim();
  String sSalesMan = safeSqlGetParameter(request,"salesman","").trim();
  String sSecurityFilter;
  boolean bPrivate = sPrivate.equals("1");

  int iContactCount = 0;
  DBSubset oContacts = null;
  DBSubset oQueries = null;
  DBSubset oACourses = null;
  DBSubset oSalesMen = null;
  Object[] aFind = new Object[1];
  int iQueries = 0;
  QueryByForm oQBF;
  String sOrderBy;
  int iACourses = 0;
  int iSalesMen = 0;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;
  
  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "100"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }

  try {  
    if (request.getParameter("skip")!=null)
      iSkip = Integer.parseInt(request.getParameter("skip"));      
    else
      iSkip = 0;
  }
  catch (NumberFormatException nfe) { iSkip = 0; }

  if (iSkip<0) iSkip = 0;

  if (nullif(request.getParameter("orderby")).length()>0)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "0";   

  iOrderBy = Integer.parseInt(sOrderBy.endsWith(" DESC") ? sOrderBy.substring(0,sOrderBy.length()-5) : sOrderBy);
  
  if (8==iOrderBy && !sOrderBy.endsWith(" DESC")) sOrderBy += " DESC";
  
  JDCConnection oConn = null;  
  
  boolean bIsGuest = true;
  boolean bIsAdmin = false;
      
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

    oConn = GlobalDBBind.getConnection("contact_listing");
		
    if (bIsAdmin) {
      sSecurityFilter = sSalesMan.length()==0 ? "" : " AND ("+DB.gu_writer+"='"+sSalesMan+"' OR "+DB.gu_sales_man+"='"+sSalesMan+"') ";

      oSalesMen = GlobalCacheClient.getDBSubset(DB.k_sales_men + ".DBSubset.[" + gu_workarea + "]");
    
      if (null==oSalesMen) {
        oSalesMen = new DBSubset (DB.k_sales_men+" s,"+DB.k_users+" u",
                                  "s."+DB.gu_sales_man+",u."+DB.nm_user+",u."+DB.tx_surname1+",u."+DB.tx_surname2+","+
                                  "s."+DB.gu_workarea+",s."+DB.gu_geozone+",s."+DB.id_country+",s."+DB.id_state+","+
                                  "s."+DB.id_sales_group,
                                  "s."+DB.gu_sales_man+"=u."+DB.gu_user+" AND u."+DB.bo_active+"<>0 AND s."+DB.gu_workarea+"=?",10);    
        iSalesMen = oSalesMen.load(oConn, new Object[]{gu_workarea});
        GlobalCacheClient.putDBSubset(DB.k_sales_men, DB.k_sales_men + ".DBSubset.[" + gu_workarea + "]", oSalesMen);
      } else {
        iSalesMen = oSalesMen.getRowCount();
      } // fi
    } else {
    	String sUserGroups = GlobalCacheClient.getString("["+id_user+",groups]");
	    if (null==sUserGroups) {
	      ACLUser oUser = new ACLUser(id_user);
	      DBSubset oUserGroups = oUser.getGroups(oConn);
	      oUserGroups.setRowDelimiter("','");
	      sUserGroups = "'" + Gadgets.dechomp(oUserGroups.toString(),"','") + "'";
	      GlobalCacheClient.put("["+id_user+",groups]", sUserGroups);
	    }
    	sSecurityFilter = " AND (b.bo_restricted=0 OR b.bo_restricted IS NULL OR EXISTS (SELECT x."+DB.gu_acl_group+" FROM "+DB.k_x_group_contact+" x WHERE x."+DB.gu_contact+"=b."+DB.gu_contact+" AND x."+DB.gu_acl_group+" IN ("+sUserGroups+"))) AND " + (bPrivate ? "(b." + DB.bo_private + "=1 AND b." + DB.gu_writer + "='" + id_user + "') " : "(b." + DB.bo_private + "=0 OR "+DB.bo_private+" IS NULL OR b." + DB.gu_writer + "='" + id_user + "') ") + " ";
    }

    if (face.equals("edu")) {
      if (WorkArea.isAdmin(oConn, gu_workarea, id_user)) {
        oACourses = new DBSubset(DB.k_academic_courses+" a",
      			         DB.gu_acourse+","+DB.nm_course+","+DB.id_course,
      			         DB.bo_active+"=1 AND EXISTS (SELECT "+DB.gu_course+" FROM "+DB.k_courses+" c WHERE a."+DB.gu_course+"=c."+DB.gu_course+" AND c."+DB.gu_workarea+"=?) ORDER BY 2", 50);
        iACourses = oACourses.load(oConn, new Object[]{gu_workarea});
      } else {
        oACourses = new DBSubset(DB.k_academic_courses+" a",
      			         DB.gu_acourse+","+DB.nm_course+","+DB.id_course,
      							 " (  EXISTS (SELECT u."+DB.gu_acourse+" FROM "+DB.k_x_user_acourse+" u WHERE u."+DB.gu_acourse+"=a."+DB.gu_acourse+" AND u."+DB.gu_user+"=? AND u."+DB.bo_user+"<>0) OR "+
                     "NOT EXISTS (SELECT u."+DB.gu_acourse+" FROM "+DB.k_x_user_acourse+" u WHERE u."+DB.gu_acourse+"=a."+DB.gu_acourse+" AND u."+DB.gu_user+"=?)) AND "+
      			         DB.bo_active+"=1 AND EXISTS (SELECT "+DB.gu_course+" FROM "+DB.k_courses+" c WHERE a."+DB.gu_course+"=c."+DB.gu_course+" AND c."+DB.gu_workarea+"=?) ORDER BY 2", 50);
        iACourses = oACourses.load(oConn, new Object[]{id_user,id_user,gu_workarea});      
      }
    }
    
    oQueries = GlobalCacheClient.getDBSubset("k_queries.contacts[" + gu_workarea + "]");
    
    if (null==oQueries) {
      oQueries = new DBSubset(DB.k_queries, DB.gu_query + "," + DB.tl_query, DB.gu_workarea + "='" + gu_workarea + "' AND " + DB.nm_queryspec + "='contacts'", 10);
      oQueries.load (oConn);
      
      GlobalCacheClient.putDBSubset("k_queries" , "k_queries.contacts[" + gu_workarea + "]", oQueries);
    }
    iQueries = oQueries.getRowCount();
    
    if (sQuery.length()>0 && sWhere.length()==0) {
      oQBF = new QueryByForm (oConn, DB.v_contact_address_title, "b", sQuery);
      
      sWhere = " AND (" + oQBF.composeSQL() + ")";
      
      oQBF = null;
    }
    
    if (sWhere.length()>0) {
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
        oContacts = new DBSubset (DB.v_contact_address_title + " b", 
	      		          "b." + DB.gu_contact + ",CONCAT(COALESCE(b." + DB.tx_surname + ",''),', ',COALESCE(b." + DB.tx_name + ",''))," + DBBind.Functions.ISNULL + "(b." + DB.tr_ + sLanguage + ",''),b." + DB.gu_company + ",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			        "((b." + DB.gu_owner + "='" + gu_workarea + "' OR b." + DB.gu_owner + " IS NULL) AND (b." + DB.id_section + "='de_title' OR b." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' ) " +
	      			        sWhere + sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows); 		 
      else
        oContacts = new DBSubset (DB.v_contact_address_title + " b", 
	      		          "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",'')," + DBBind.Functions.ISNULL + "(b." + DB.tr_ + sLanguage + ",''),b." + DB.gu_company + ",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			        "((b." + DB.gu_owner + "='" + gu_workarea + "' OR b." + DB.gu_owner + " IS NULL) AND (b." + DB.id_section + "='de_title' OR b." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' ) " +
	      			        sWhere + sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows); 		 
        oContacts.setMaxRows(iMaxRows);
        iContactCount = oContacts.load (oConn, iSkip);
    }
    else if (sFind.length()==0) {
      oContacts = new DBSubset (DB.v_contact_list + " b, "+DB.k_contacts_recent+" r",      
	      		        "b."+DB.gu_contact + ",b." + DB.full_name + ",b." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + "," + DBBind.Functions.ISNULL + "(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b."+DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			      "(b." + DB.gu_owner + "=? OR b." + DB.gu_owner + " IS NULL) AND b." + DB.gu_workarea + "=? AND " +
	      			      "b."+DB.gu_contact+"=r."+DB.gu_contact+" AND r."+DB.gu_user+"=? "+
	      			      sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      oContacts.setMaxRows(iMaxRows);
      iContactCount = oContacts.load (oConn, new Object[]{gu_workarea,gu_workarea,id_user}, iSkip);
    }
    else {

      if (sField.equalsIgnoreCase(DB.nm_course)) {
        aFind[0] = sFind + "%";

        if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
          oContacts = new DBSubset (DB.k_contacts + " c," + DB.k_x_course_alumni + " x," + DB.k_academic_courses + " a",
	      		            "c." + DB.gu_contact + ",CONCAT(COALESCE(c." + DB.tx_surname + ",''),', ',COALESCE(c." + DB.tx_name + ",'')),c." + DB.de_title + ",a." + DB.gu_acourse +",a." + DB.nm_course + ","+DBBind.Functions.ISNULL+"(c." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(c." + DB.nu_attachs + ",0),c." + DB.dt_modified,
	      			          "c." + DB.gu_contact + "=x." + DB.gu_alumni + " AND x." + DB.gu_acourse + "=a." + DB.gu_acourse + " AND c." + DB.gu_workarea + "='" + gu_workarea + "' AND a." + sField + " " + DBBind.Functions.ILIKE + " ? AND " +
	      			          (bPrivate ? "(c." + DB.bo_private + "=1 AND c." + DB.gu_writer + "='" + id_user + "') " : "(c." + DB.bo_private + "=0 OR c." + DB.gu_writer + "='" + id_user + "') ") +
	      			          (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);                
        else
          oContacts = new DBSubset (DB.k_contacts + " c," + DB.k_x_course_alumni + " x," + DB.k_academic_courses + " a",
	      		            "c." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(c." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(c." + DB.tx_name + ",''),c." + DB.de_title + ",a." + DB.gu_acourse +",a." + DB.nm_course + ","+DBBind.Functions.ISNULL+"(c." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(c." + DB.nu_attachs + ",0),c." + DB.dt_modified,
	      			          "c." + DB.gu_contact + "=x." + DB.gu_alumni + " AND x." + DB.gu_acourse + "=a." + DB.gu_acourse + " AND c." + DB.gu_workarea + "='" + gu_workarea + "' AND a." + sField + " " + DBBind.Functions.ILIKE + " ? AND " + (bPrivate ? "(c." + DB.bo_private + "=1 AND c." + DB.gu_writer + "='" + id_user + "') " : "(c." + DB.bo_private + "=0 OR c." + DB.gu_writer + "='" + id_user + "') ") +
	      			          (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);                
      }     
      else if (sField.equalsIgnoreCase(DB.work_phone)) {
        aFind = new Object[] {sFind,sFind,sFind,sFind};
        if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
          oContacts = new DBSubset (DB.v_contact_address_title + " b", 
	      		      "b." + DB.gu_contact + ",CONCAT(COALESCE(b." + DB.tx_surname + ",''),', ',COALESCE(b." + DB.tx_name + ",''))," + DBBind.Functions.ISNULL + "(b." + DB.tr_ + sLanguage + ",''),b." + DB.gu_company + ",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			    "((b." + DB.gu_owner + "='" + gu_workarea + "' OR b." + DB.gu_owner + " IS NULL) AND (b." + DB.id_section + "='de_title' OR b." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND " +
	      			    "(b." + DB.work_phone + "=? OR b." + DB.direct_phone + "=? OR b." + DB.home_phone + "=? OR b." + DB.mov_phone + "=?) " + sSecurityFilter + 
	      			    (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
	      else
          oContacts = new DBSubset (DB.v_contact_address_title + " b", 
	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",'')," + DBBind.Functions.ISNULL + "(b." + DB.tr_ + sLanguage + ",''),b." + DB.gu_company + ",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			    "((b." + DB.gu_owner + "='" + gu_workarea + "' OR b." + DB.gu_owner + " IS NULL) AND (b." + DB.id_section + "='de_title' OR b." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND " +
	      			    "(b." + DB.work_phone + "=? OR b." + DB.direct_phone + "=? OR b." + DB.home_phone + "=? OR b." + DB.mov_phone + "=?) " + sSecurityFilter + 
	      			    (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      }
      else if (sField.equalsIgnoreCase(DB.tx_email)) {
        aFind = new Object[] {gu_workarea,gu_workarea,sFind};
        oContacts = new DBSubset (DB.v_contact_address_title + " b", 
	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",'')," + DBBind.Functions.ISNULL + "(b." + DB.tr_ + sLanguage + ",''),b." + DB.gu_company + ",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			    "(b." + DB.gu_owner + "=? OR b." + DB.gu_owner + " IS NULL) AND (b." + DB.id_section + "='de_title' OR b." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "=? AND " +
	      			    "b." + DB.tx_email + "=? " + sSecurityFilter + 
	      			    (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      }
      else if (sField.equalsIgnoreCase(DB.nm_legal)) {
        
	      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
          aFind[0] = "%" + sFind + "%";
          oContacts = new DBSubset (DB.v_contact_company_all + " b, " + DB.k_contacts_lookup + " l",
	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''),l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			    "b." + DB.de_title + "=l." + DB.vl_lookup + "(+) AND (l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " " + DBBind.Functions.ILIKE + " ? " +
	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
	      } else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
          aFind[0] = "%" + sFind + "%";
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
        			    " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
	      		      "b." + DB.gu_contact + ",CONCAT(COALESCE(b." + DB.tx_surname + ",''),', ',COALESCE(b." + DB.tx_name + ",'')),l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			    "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " " + DBBind.Functions.ILIKE + " ? " +
	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
	      } else {
          aFind[0] = "%" + sFind + "%";
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
        			    " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''),l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			    "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " " + DBBind.Functions.ILIKE + " ? " +
	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
        }                
      }
      else if (sField.equalsIgnoreCase(DB.tp_company)) {
        aFind[0] = sFind.toUpperCase();

	      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE)
          oContacts = new DBSubset (DB.v_contact_company_all + " b, " + DB.k_contacts_lookup + " l",
	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company + ", b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			    "b." + DB.de_title + "=l." + DB.vl_lookup + "(+) AND (l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " = ? " +
	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
	      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
        			    " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,	      		          
	      		      "b." + DB.gu_contact + ",CONCAT(COALESCE(b." + DB.tx_surname + ",''),', ',COALESCE(b." + DB.tx_name + ",'')), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company + ", b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			    "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " = ? " +
	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
	      else
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
        			    " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,	      		          
	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company + ", b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
	      			    "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " = ? " +
	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      }
      else if (sField.equalsIgnoreCase(DB.tx_term)) {
      	if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
          aFind[0] = "%" + sFind + "%";
          oContacts = new DBSubset (DB.v_contact_company_all + " b, " + DB.k_contacts_lookup + " l",
      	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
      	      			    "b." + DB.de_title + "=l." + DB.vl_lookup + "(+) AND (l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND " +
      	      			    "EXISTS (SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " t WHERE t." + DB.gu_term + "=b." + DB.gu_geozone + " AND t. " + DB.tx_term + " " + DBBind.Functions.ILIKE + " ?) " +
      	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      	} else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
          aFind[0] = "%" + sFind + "%";
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
                			  " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
      	      		      "b." + DB.gu_contact + ",CONCAT(COALESCE(b." + DB.tx_surname + ",''),', ',COALESCE(b." + DB.tx_name + ",'')), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
      	      			    "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND " +
      	      			    "EXISTS (SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " t WHERE t." + DB.gu_term + "=b." + DB.gu_geozone + " AND t. " + DB.tx_term + " " + DBBind.Functions.ILIKE + " ?) " +
      	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      	} else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
          aFind[0] = ".*" + Gadgets.accentsToPosixRegEx(sFind) + ".*";
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
                			  " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
      	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
      	      			    "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND " +
      	      			    "EXISTS (SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " t WHERE t." + DB.gu_term + "=b." + DB.gu_geozone + " AND t. " + DB.tx_term + " ~* ?) " +
      	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
        } else {
          aFind[0] = "%" + sFind + "%";
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
                			  " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
      	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
      	      			    "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND " +
      	      			    "EXISTS (SELECT " + DB.gu_term + " FROM " + DB.k_thesauri + " t WHERE t." + DB.gu_term + "=b." + DB.gu_geozone + " AND t. " + DB.tx_term + " " + DBBind.Functions.ILIKE + " ?) " +
      	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
				}
      }
      else {
      	if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
          aFind[0] = "%" + sFind + "%";
          oContacts = new DBSubset (DB.v_contact_company_all + " b, " + DB.k_contacts_lookup + " l",
      	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
      	      			    "b." + DB.de_title + "=l." + DB.vl_lookup + "(+) AND (l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " " + DBBind.Functions.ILIKE + " ? " +
      	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      	} else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
          aFind[0] = "%" + sFind + "%";
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
                			  " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
      	      		      "b." + DB.gu_contact + ",CONCAT(COALESCE(b." + DB.tx_surname + ",''),', ',COALESCE(b." + DB.tx_name + ",'')), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
      	      			    "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " " + DBBind.Functions.ILIKE + " ? " +
      	      			    sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      	} else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
          aFind[0] = ".*" + Gadgets.accentsToPosixRegEx(sFind) + ".*";
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
                			    " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
      	      		        "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
      	      			      "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " ~* ? " +
      	      			      sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
        } else {
          aFind[0] = "%" + sFind + "%";
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
                			    " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
      	      		        "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal + ","+DBBind.Functions.ISNULL+"(b." + DB.nu_notes + ",0),"+DBBind.Functions.ISNULL+"(b." + DB.nu_attachs + ",0),b." + DB.dt_modified,
      	      			      "(l." + DB.gu_owner + "='" + gu_workarea + "' OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "='" + gu_workarea + "' AND b." + sField + " " + DBBind.Functions.ILIKE + " ? " +
      	      			      sSecurityFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
        }
      }
      oContacts.setMaxRows(iMaxRows);
      iContactCount = oContacts.load(oConn,aFind,iSkip);
    }
    oConn.close("contact_listing");
    oConn = null;

    sendUsageStats(request, "contact_listing");      
  }
  catch (SQLException e) {  
    oContacts = null;
    iContactCount = 0;
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("contact_listing");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=face.equals("edu") ? "Students Listing" : "Contact Listing"%></TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" >
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" >
    var menuLayer,addrLayer;

    dynapi.onLoad(init);

		function init() { 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setHTML(rightMenuHTML);
      
      addrLayer = new DynLayer();
      addrLayer.setWidth(300);
      addrLayer.setHeight(160);
      addrLayer.setZIndex(200);
    }
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>

  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        var jsContactId;
        var jsCompanyId;
        var jsCompanyNm;
        var jsContactNm;
        var jsNotesCount;
        var jsFilesCount;        
    
        <%
          
          out.write("var jsContacts = new Array(");
            for (int i=0; i<iContactCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oContacts.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createOportunity (contact_id,company_id) {	  
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
	  self.open ("oportunity_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_contact=" + contact_id + "&gu_company=" + company_id, "createoportunity", "directories=no,toolbar=no,menubar=no,width=640,height=600");	  
<% } %>
	} // createOportunity()

      // ----------------------------------------------------
	
      function viewOportunities (contact_id, contact_nm) {
        var frm = window.document.forms["fixedAttrs"];
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
	      window.location = "oportunity_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + contact_id + "&where=" + escape(" AND gu_contact='" + contact_id + "'") + "&field=" + escape("<%=DB.tx_contact%>") + "&find=" + escape(contact_nm) + "&show=oportunities&skip=0&selected=2&subselected=2";
<% } %>
      } // viewOportunities

        // ----------------------------------------------------
        	
	function createContact() {	  
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
	  self.open ("contact_new_f.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "createcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=660");	  
<% } %>
	} // createContact()

        // ----------------------------------------------------
	
	function deleteContacts() {
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to delete selected individuals?")) {
	    chi.value = "";

	    frm.action = "contact_edit_delete.jsp?face=<%=sFace%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
         
            while (frm.elements[offset].type!="checkbox") offset++;
                 
	    for (var i=0; i<jsContacts.length; i++)
              if (frm.elements[i+offset].checked)
                chi.value += jsContacts[i] + ",";	      
                      
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
	    
              frm.submit();
            } // fi(checkeditems)
          } // fi(confirm)
	} // deleteContacts()
	
        // ----------------------------------------------------

	function modifyContact(id) {
	  self.open ("contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id + "&face=<%=sFace%>", "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=760,height=660");
	}	

	

        // ----------------------------------------------------
	
	function showOportunities() {
	  window.location = "oportunity_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&show=oportunities&maxrows=<%=String.valueOf(iMaxRows)%>&skip=0";
	}
	
        // ----------------------------------------------------

	function sortBy(fld) {
	  var frm = document.forms[0];
<% if (bIsAdmin) { %>
	  document.location = "contact_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>&query=<%=sQuery%>&where=<%=Gadgets.URLEncode(sWhere)%>" + "&salesman=" + getCombo(frm.salesman) + "&private=" + (frm.private[0].checked ? "1" : "0") + "&face=<%=sFace%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
<% } else { %>
	  document.location = "contact_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>&query=<%=sQuery%>&where=<%=Gadgets.URLEncode(sWhere)%>" + "&private=" + (frm.private[0].checked ? "0" : "1") + "&face=<%=sFace%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
<% } %>
	}
				
        // ----------------------------------------------------

        function selectAll() {
          var frm = document.forms[0];
          
          for (var c=0; c<jsContacts.length; c++)                        
           
           eval ("frm.elements['" + jsContacts[c] + "'].click()");
    
        }
       
       // ----------------------------------------------------

	function findContact() {
	  var frm = document.forms[0];
		if (hasForbiddenChars(frm.find.value)) {
		  alert ("Searched text contains invalid characters");
		  frm.find.focus();
		  return false;
		}
<% if (bIsAdmin) { %>
	  window.location="contact_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&salesman=" + getCombo(frm.salesman) + "&face=<%=sFace%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");	
<% } else { %>
	  window.location="contact_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&private=" + (frm.private[0].checked ? "0" : "1") + "&face=<%=sFace%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");	
<% } %>
    return true;
	} // findContact()

      // ------------------------------------------------------

      function listAddresses() {
        var frm = window.document.forms[0];
      
        self.open ("../common/addr_list.jsp?linktable=k_x_contact_addr&linkfield=gu_contact&linkvalue=" + jsContactId, "editcontact", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=520");
      }

      // ----------------------------------------------------

      function viewAddrs(ev,gu,nm) {
        showDiv(ev,"../common/addr_layer.jsp?nm_company=" + escape(nm) + "&linktable=k_x_contact_addr&linkfield=gu_contact&linkvalue=" + gu);
        //open("../common/addr_layer.jsp?nm_company=" + escape(nm) + "&linktable=k_x_contact_addr&linkfield=gu_contact&linkvalue=" + gu);
      }

      // ------------------------------------------------------

      function viewNotes(gu,cm) {
        if (isRightMenuOptionEnabled(5))
          self.open ("note_listing.jsp?gu_contact=" + gu + "&nm_company=" + escape(cm), "viewnotes", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=520");
      }

      // ------------------------------------------------------

      function addNote(gu) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        self.open ("note_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + gu, "addnote", "directories=no,toolbar=no,menubar=no,width=610,height=400");
<% } %>
      } // addNote

      // ------------------------------------------------------

      function viewAttachments(gu) {
        if (isRightMenuOptionEnabled(7))
          self.open ("attach_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + gu, "listattachments", "directories=no,toolbar=no,menubar=no,width=610,height=440");
      }

      // ------------------------------------------------------

      function addAttachment(gu) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        window.open("attach_edit.jsp?gu_contact=" + gu, "addattachment", "directories=no,toolbar=no,menubar=no,width=480,height=360");          
<% } %>        
      } // addAttachment

      // ------------------------------------------------------

      function addPhoneCall(gu) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        window.open("../addrbook/phonecall_edit_f.jsp?gu_workarea=<%=gu_workarea%>&gu_contact=" + gu, "addphonecall", "directories=no,toolbar=no,menubar=no,width=500,height=400");       
<% } %>        
      } // addPhoneCall

      // ------------------------------------------------------

      function addActivity(gu) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        var activity_edition_page = "<% out.write(sFace.equalsIgnoreCase("healthcare") ? "appointment_edit_f.htm" : "meeting_edit_f.htm"); %>";
        window.open("../addrbook/"+activity_edition_page+"?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid") + "&gu_contact=" + gu + "&date=<%=sToday%>", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
<% } %>        
      } // addActivity

      // ------------------------------------------------------

      function addProject(gu,cm) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        window.open("prj_create.jsp?gu_workarea=<%=gu_workarea%>&gu_contact=" + gu + "&gu_company=" + cm, "addproject", "directories=no,toolbar=no,menubar=no,width=540,height=280");       
<% } %>
      } // addProject

      function addToCourse() {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
	var offset = 0;
	var frm = document.forms[0];
	var chi = frm.checkeditems;
	chi.value = "";

	if (frm.sel_acourse.selectedIndex<=0) {
	  alert ("Select course to which students must be assigned");
	  frm.sel_acourse.focus();
	  return false;
	}
         
        while (frm.elements[offset].type!="checkbox") offset++;
                 
	for (var i=0; i<jsContacts.length; i++)
          if (frm.elements[i+offset].checked)
            chi.value += jsContacts[i] + ",";	      
                      
	if (chi.value.length>0) {
	  chi.value = chi.value.substr(0,chi.value.length-1);

	  self.open ("../training/acourse_book.jsp?gu_acourse="+getCombo(frm.sel_acourse)+"&checkeditems="+chi.value, null, "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=600,height=520");

        } else {
	        alert ("At least one student must be selected");
	        return false;        
        }
<% } %>      
      } // addToCourse

      // ------------------------------------------------------

      function configureMenu() {
        if (jsNotesCount>0)
          enableRightMenuOption(9);
        else
          disableRightMenuOption(9);
          
        if (jsFilesCount>0)
          enableRightMenuOption(12);
        else
          disableRightMenuOption(12);

	      var iProjOption = (parseInt(getCookie("appmask")) & 131072)!=0 ? 16 : 14;
	 
        if ((parseInt(getCookie("appmask")) & 4096)!=0)
          if (jsCompanyId.length>0)
            enableRightMenuOption(iProjOption);
          else
            disableRightMenuOption(iProjOption);        
      }
      
      // ------------------------------------------------------

      function runQuery() {
	      var frm = document.forms[0];
        var qry = getCombo(document.forms[0].sel_query);
        
        if (qry.length>0) {
<% if (bIsAdmin) { %>
          window.top.location.href = "contact_listing_f.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&salesman=" + getCombo(frm.salesman) + "&orderby=<%=sOrderBy%>&gu_query=" + qry + "&face=<%=sFace%>&selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>";
<% } else { %>
          window.top.location.href = "contact_listing_f.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&private=" + (frm.private[0].checked ? "0" : "1") + "&orderby=<%=sOrderBy%>&gu_query=" + qry + "&face=<%=sFace%>&selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>";
<% } %>
        }
      }
      
      // ------------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {
        if (winclone.closed) {
          clearInterval(intervalId);
          
          setCombo(document.forms[0].sel_searched, "<%=DB.tx_surname%>");
          
          var comma = jsContactNm.indexOf(",");

          if (comma>0)
            document.forms[0].find.value = jsContactNm.substring(0, comma);
          else
            document.forms[0].find.value = jsContactNm;

          findContact();
        }
      } // findCloned()
      
      function clone() {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=contact_clon&gu_instance=" + jsContactId +"&opcode=CCON&classid=92", null, "directories=no,toolbar=no,menubar=no,width=320,height=200");                
        intervalId = setInterval ("findCloned()", 100);
<% } %>
      }	// clone()
	
      //--------------------------------------------------
    //-- Inicio I2E 2009-01-20
	function searchCandidate() {
	  window.open("candidate_search.jsp?gu_workarea=<%=gu_workarea%>","", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=760,height=660");
	}		

	//-- Fin I2E
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
<% if (((Integer.parseInt(getCookie(request, "appmask", "0")) & (1<<22))==0) || !face.equals("edu") || bIsGuest) { %>
	  setCombo(document.forms[0].sel_query, "<%=sQuery%>");	    
<% }
   if (bIsAdmin) { %>
	  setCombo(document.forms[0].salesman, "<%=sSalesMan%>");	    
<% } %>
   if (getURLParam("find")!=null) document.forms[0].find.value=decodeURIComponent(getURLParam("find"));
	} // setCombos()
    //-->    
  </SCRIPT>
  <!-- WHERE <%=sWhere%> -->       
</HEAD>

<BODY  TOPMARGIN="4" MARGINHEIGHT="4" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post" onSubmit="findContact();return false;">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1"><%=face.equals("edu") ? "Students Listing" : "Contact Listing"%></FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle">
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New</A>
<% } else { %>
          <A HREF="#" onclick="createContact()" CLASS="linkplain">New</A>
<% } %>
        </TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD>
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
          <A HREF="#" onclick="deleteContacts();return false;" CLASS="linkplain">Delete</A>
<% } %>
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Find Individual"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE="<%=DB.tx_name%>">Name<OPTION VALUE="<%=DB.tx_surname%>">Surname<OPTION VALUE="<%=DB.de_title%>">Position<OPTION VALUE="<%=DB.nm_legal%>">Company<OPTION VALUE="<%=DB.tx_email%>">e-mail<OPTION VALUE="<%=DB.tp_company%>">Company Type<OPTION VALUE="<%=DB.work_phone%>">Telephone<OPTION VALUE="<%=DB.tx_term%>">Zone<OPTION VALUE="<%=DB.nm_course%>">Course</SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50">
	  &nbsp;<A HREF="#" onclick="findContact();return false;" CLASS="linkplain" TITLE="Find Individual">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></TD>
        <TD VALIGN="bottom">
          <A HREF="#" onclick="<% if (bIsAdmin) { %>document.forms[0].salesman.selectedIndex=0;<% } %>document.forms[0].find.value='';findContact();return false;" CLASS="linkplain" TITLE="Discard Find Filter">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
        </TR>
	<TR>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/fastedit.gif" WIDTH="20" HEIGHT="16" BORDER="0" ALT="Fast Edit"></TD>
          <TD COLSPAN="4"><A HREF="<%= face.equals("edu") ? "../training/alumni_fastedit_f.jsp" : "contact_fastedit_f.jsp" %>" TARGET="_top" CLASS="linkplain">Fast Edit</A></TD>
	        <TD COLSPAN="3" ALIGN="left" CLASS="textplain">
<% if (bIsAdmin) { %>
					  <SELECT NAME="salesman" CLASS="combomini"><OPTION VALUE="">All individuals</OPTION><OPTGROUP LABEL="Only individuals assigned to salesman"><% for (int s=0; s<iSalesMen; s++) out.write ("<OPTION VALUE=\""+oSalesMen.getString(0,s)+"\">"+oSalesMen.getStringNull(1,s,"")+" "+oSalesMen.getStringNull(2,s,"")+" "+oSalesMen.getStringNull(3,s,"")+"</OPTION>"); %></SELECT>
<% } else { %>
	          <INPUT TYPE="radio" NAME="private" VALUE="0" onclick="if (document.forms[0].sel_query.selectedIndex>0) runQuery(); else findContact();" <% if (!bPrivate) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="textplain">All Contacts</FONT>
	          &nbsp;&nbsp;
            <INPUT TYPE="radio" NAME="private" VALUE="1" onclick="if (document.forms[0].sel_query.selectedIndex>0) runQuery(); else findContact();" <% if (bPrivate) out.write("CHECKED"); %>>&nbsp;<FONT CLASS="textplain">Private Contacts Only</FONT>
<% } %>
			    <% if (!face.equals("edu")) { %> <A HREF="#" TARGET="_top" CLASS="linkplain" onclick="searchCandidate();return false;">Search Applicants</A><% } %>
	        </TD>
	</TR>
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="2" ALIGN="left">
<%
          if (iSkip>0)
            out.write("            <A HREF=\"contact_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&query=" + sQuery + "&orderby=" + sOrderBy + "&where=" + Gadgets.URLEncode(sWhere) + "&field=" + sField + "&find=" + sFind + "&face="+sFace+"&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
    	  if (oContacts!=null)
            if (!oContacts.eof())
              out.write("            <A HREF=\"contact_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&query=" + sQuery + "&orderby=" + sOrderBy + "&where=" + Gadgets.URLEncode(sWhere) + "&field=" + sField + "&find=" + sFind + "&face="+sFace+"&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
%>
          </TD>
<% if (((iAppMask & (1<<Training))!=0) && face.equals("edu") && !bIsGuest) { %>
          <TD COLSPAN="4" ALIGN="right">
	    <A HREF="#" CLASS="linkplain" onclick="addToCourse();return false;">Book Place at Course</A>&nbsp;
	      <SELECT NAME="sel_acourse" CLASS="combomini"><OPTION VALUE=""></OPTION>
	      <% for (int a=0; a<iACourses; a++) {
	           out.write("<OPTION VALUE=\"" + oACourses.getString(0,a) + "\">" + oACourses.getString(1,a));
	           if (!oACourses.isNull(2,a)) out.write(" ("+oACourses.getString(2,a)+")");
	           out.write("</OPTION>");
	         } %>
	      </SELECT>
          </TD>
<% } else { %>
          <TD COLSPAN="3" ALIGN="right">
	    <FONT CLASS="textplain">Predefined queries</FONT>&nbsp;<SELECT NAME="sel_query" CLASS="combomini"><OPTION VALUE=""></OPTION><% for (int q=0; q<iQueries; q++) out.write("<OPTION VALUE=\"" + oQueries.getString(0,q) + "\">" + oQueries.getString(1,q) + "</OPTION>"); %></SELECT>&nbsp;<A HREF="#" onClick="runQuery()" CLASS="linkplain">Query</A>
          </TD>
          <TD>
<% if (bIsGuest) { %>
            <IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="22" BORDER="0">
<% } else { %>
            <A HREF="../common/qbf.jsp?queryspec=contacts" TARGET="_top" TITLE="New Query"><IMG SRC="../images/images/newqry16.gif" WIDTH="22" HEIGHT="18" VSPACE="2" BORDER="0" ALT="New Query"></A>&nbsp;
<% } %>
          </TD>	
<% } %>          
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by Surname"></A>&nbsp;<B>Surname, Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="<%=String.valueOf(floor(150f*fScreenRatio))%>">&nbsp;&nbsp;<A HREF="javascript:sortBy(3)"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by position"></A>&nbsp;<B><%=(face.equals("edu") ? "Type" : "Position")%></B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5)"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by company name"></A><B>&nbsp;<%=(face.equals("edu") ? "Academic Course" : "Company")%></B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="110">&nbsp;<A HREF="javascript:sortBy(8)"><IMG SRC="../skins/<%=sSkin + (iOrderBy==8 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by last modified"></A><B>&nbsp;Date Modified</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" ALIGN="center"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD>
        </TR>
	<%

  	  String sContactId = "";
	  String sTitle = "";
	  String sName = "";
	  String sCompanyId = "";
	  String sCompany_name = "";
	  String sDtModified = "";

	  for (int i=0; i<iContactCount; i++)
	  {
	  
	    sContactId = oContacts.getStringNull(0,i,"");
            sName = oContacts.getStringHtml(1,i,"");
            if (sName.equals(", ")) sName = "<I>(unnamed)</I>";
            sTitle = oContacts.getStringNull(2,i,"");
            sCompanyId= oContacts.getStringNull(3,i,"");
            sCompany_name= oContacts.getStringHtml(4,i,"");
            sDtModified = oContacts.getDateShort(7,i);
            if (null==sDtModified) sDtModified = "";
            
            out.write ("        <TR HEIGHT=\"5\">\n");
            out.write ("          <TD CLASS=\"strip" + ((i%2)+1) + "\"><A HREF=\"#\" onContextMenu='return false;' onClick='hideDiv();viewAddrs(event,\"" + sContactId + "\",\"" + sName.replace((char)39,(char)32) + "\");return false'><IMG SRC=\"../images/images/theworld16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"View Addresses\"></A></TD>\n");
            out.write ("          <TD CLASS=\"strip" + ((i%2)+1) + "\">&nbsp;<A HREF=\"#\" oncontextmenu=\"jsContactId='" + sContactId + "'; jsContactNm='" + sName.replace((char)39,(char)32) + "'; jsCompanyId='" + sCompanyId + "'; jsCompanyNm='" + sCompany_name.replace((char)39,(char)32) + "'; jsNotesCount='" + oContacts.getInt(5,i) + "'; jsFilesCount='" + oContacts.getInt(6,i) + "'; configureMenu(); return showRightMenu(event);\" onmouseover=\"window.status='Edit Contact'; return true;\" onmouseout=\"window.status='';\" oncontextmenu=\"return false;\" onclick=\"modifyContact('" + sContactId + "'); return false;\" TITLE=\"Click Right Mouse Button for Context Menu\">" + sName  + "</A></TD>\n");
            out.write ("          <TD CLASS=\"strip" + ((i%2)+1) + "\">&nbsp;" + sTitle + "</TD>\n");                        
            out.write ("          <TD CLASS=\"strip" + ((i%2)+1) + "\">&nbsp;" + sCompany_name + "</TD>\n");
            out.write ("          <TD CLASS=\"strip" + ((i%2)+1) + "\">&nbsp;" + sDtModified + "</TD>\n");
            out.write ("          <TD CLASS=\"strip" + ((i%2)+1) + "\" ALIGN=\"middle\"><INPUT VALUE=\"" + sContactId + "\" TYPE=\"checkbox\" NAME=\"" + sContactId + "\">\n");
            out.write ("        </TR>\n");        
            
          }                      
      %>          	  
        <TR>
          <TD COLSPAN="5" ALIGN="left">
<%    
          if (iSkip>0)
            out.write("            <A HREF=\"contact_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&query=" + sQuery + "&orderby=" + sOrderBy + "&where=" + Gadgets.URLEncode(sWhere) + "&field=" + sField + "&find=" + sFind + "&face="+sFace+"&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
    	  if (oContacts!=null)
            if (!oContacts.eof())
              out.write("            <A HREF=\"contact_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&query=" + sQuery + "&orderby=" + sOrderBy + "&where=" + Gadgets.URLEncode(sWhere) + "&field=" + sField + "&find=" + sFind + "&face="+sFace+"&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
%>
          </TD>
        </TR>
      </TABLE>      
    </FORM>

    <IFRAME name="addrIFrame" src="../common/blank.htm" width="0" height="0" border="0" frameborder="0"></IFRAME>
    <SCRIPT language="JavaScript" type="text/javascript">
      <!--
      addMenuOption("Open","modifyContact(jsContactId)",1);
      addMenuOption("Duplicate","clone()",0);
      addMenuSeparator();
      addMenuOption("View Addresses","listAddresses()",0);
      addMenuSeparator();
<% if (!face.equals("edu")) { %>      
      addMenuOption("Create Opportunity","createOportunity(jsContactId,jsCompanyId)",0);
      addMenuOption("View Opportunities","viewOportunities(jsContactId,jsContactNm)",0);
      addMenuSeparator();
<% } else if (((iAppMask & (1<<Training))!=0)) { %>
<% } %>	
      addMenuOption("Add Note","addNote(jsContactId)",0);
      addMenuOption("View Notes","viewNotes(jsContactId,jsCompanyNm)",2);
      addMenuSeparator();
      addMenuOption("Attach File","addAttachment(jsContactId)",0);
      addMenuOption("View Files","viewAttachments(jsContactId)",2);
<% if ((iAppMask & (1<<CollaborativeTools))!=0) { %>
      addMenuSeparator();
      addMenuOption("New Call","addPhoneCall(jsContactId)",0);
      addMenuOption("New Activity:","addActivity(jsContactId)",0);
<% } %>
<% if ((iAppMask & (1<<ProjectManager))!=0) { %>
      addMenuSeparator();
      addMenuOption("Create Project","addProject(jsContactId,jsCompanyId)",0);
<% } %>
      //-->
    </SCRIPT>
  </BODY>
</HTML>
