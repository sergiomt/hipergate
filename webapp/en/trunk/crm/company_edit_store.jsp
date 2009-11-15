<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.util.*,java.math.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.crm.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.hipergate.RecentlyUsed" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/customattrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
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
  final int Shop = 20;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
      
  if (autenticateSession(GlobalDBBind, request, response)<0) return;  
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_company = request.getParameter("gu_company");
  String id_category = request.getParameter("id_category");  
  String id_user = getCookie (request, "userid", null);  
  String combobox = request.getParameter("combobox");
  String noreload = nullif(request.getParameter("noreload"),"0");
  String tx_prods = nullif(request.getParameter("tx_prods"));
  
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String sOpCode = gu_company.length()>0 ? "NCOM" : "MCOM";  
  Company oCompany = new Company();
  JDCConnection oConn = GlobalDBBind.getConnection("company_edit_store");  
  PreparedStatement oStmt;

  try {
    loadRequest(oConn, request, oCompany);
    
    oConn.setAutoCommit (false);
    
    oCompany.store(oConn);
    
    storeAttributes (request, GlobalCacheClient, oConn, DB.k_companies_attrs, gu_workarea, oCompany.getString(DB.gu_company));
    
    if (null!=id_category)
      if (id_category.length()>0) {
        oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + "=? AND " + DB.id_class + "=" + String.valueOf(Company.ClassId));
        oStmt.setString(1, oCompany.getString(DB.gu_company));
        oStmt.executeUpdate();
        oStmt.close();
      
        oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_x_cat_objs + " (" + DB.gu_category + "," + DB.gu_object + "," + DB.id_class + ") VALUES (?,?," + String.valueOf(Company.ClassId) + ")");
        oStmt.setString(1, id_category);
        oStmt.setString(2, oCompany.getString(DB.gu_company));
        oStmt.executeUpdate();
        oStmt.close();                  
      } // fi
    // fi
    
    if (gu_company.length()>0) {
      oStmt = oConn.prepareStatement("DELETE FROM k_x_company_prods WHERE " + DB.gu_company + "=?");
      oStmt.setString(1, gu_company);
      oStmt.executeUpdate();
      oStmt.close();      
    }

    if (tx_prods.length()>0 && ((iAppMask & (1<<Shop))!=0)) {
      String[] aProds = Gadgets.split(tx_prods, ',');
      
      oStmt = oConn.prepareStatement("INSERT INTO k_x_company_prods (" + DB.gu_company + "," + DB.gu_category + ") VALUES ('" + oCompany.getString(DB.gu_company) + "',?)");

      for (int c=0;c<aProds.length; c++) {
        oStmt.setString(1, aProds[c]);
        oStmt.executeUpdate();
      }
      
      oStmt.close();
    } // fi (prods)
    
    RecentlyUsed oRecent = new RecentlyUsed (DB.k_companies_recent, 10, DB.gu_company, DB.gu_user);
	  DBPersist oItem = new DBPersist (DB.k_companies_recent, "RecentCompany");
	  oItem.put (DB.gu_company, oCompany.getString(DB.gu_company));
	  oItem.put (DB.gu_user, id_user);
	  oItem.put (DB.gu_workarea, gu_workarea);
	  oItem.put (DB.nm_company, oCompany.getStringNull(DB.nm_commercial, oCompany.getString(DB.nm_legal)));
	  oRecent.add(oConn, oItem);
        
    DBAudit.log(oConn, Company.ClassId, sOpCode, id_user, oCompany.getString(DB.gu_company), null, 0, 0, request.getParameter("nm_legal"), null);
    
    oConn.commit();
    
    oConn.close("company_edit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"company_edit_store");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  oConn = null;
%>
<HTML>
<HEAD>
  <TITLE>Wait...</TITLE>
  <SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>
    <!--    
    if ("<%=noreload%>"=="0")
      window.opener.top.location.reload(true);
    //-->
  </SCRIPT>
  <META http-equiv="refresh" content="0; url=company_edit.jsp?id_domain=<%=id_domain%>&n_domain=<%=Gadgets.URLEncode(n_domain)%>&gu_workarea=<%=gu_workarea%>&gu_company=<%=oCompany.getString(DB.gu_company)%>&n_company=<%=Gadgets.URLEncode(oCompany.getString(DB.nm_legal))%>&noreload=<%=noreload%>">  
</HEAD>
<BODY>
</BODY>
</HTML>
