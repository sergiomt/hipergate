<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/tab-separated-values;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%
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

  response.setHeader("Content-Disposition", "inline; filename=\"salesforecast.xls\"");

  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = getCookie (request, "workarea", null);
  String id_user = getCookie (request, "userid", null);
  String id_language = getNavigatorLanguage(request);
  
  JDCConnection oConn = null;

  DBSubset oSales = null;
   
  try {
    oConn = GlobalDBBind.getConnection("rp_salesforecast");

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
      oSales = new DBSubset(DB.k_oportunities + " o," + DB.k_users + " u",
  		            "o." + DB.tl_oportunity + ",o." + DB.id_objetive + ",o." + DB.id_status + ",o." + DB.im_revenue + ",o." + DB.dt_modified + ",o." + DB.dt_next_action + ",CONCAT(COALESCE(u." + DB.nm_user + ",''),' ',COALESCE(u." + DB.tx_surname1 + ",''),' ',COALESCE(u." + DB.tx_surname2 + ",''))",
  			    "o." + DB.gu_workarea + "='" + gu_workarea + "' AND o." + DB.gu_writer + "=u." + DB.gu_user + " AND o." + DB.id_status + " IN ('NUEVA','ABIERTA','APLAZADA')", 100);
    else
      oSales = new DBSubset(DB.k_oportunities + " o," + DB.k_users + " u",
  		            "o." + DB.tl_oportunity + ",o." + DB.id_objetive + ",o." + DB.id_status + ",o." + DB.im_revenue + ",o." + DB.dt_modified + ",o." + DB.dt_next_action + "," + DBBind.Functions.ISNULL + "(u." + DB.nm_user + ",'') " + DBBind.Functions.CONCAT + " ' ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(u." + DB.tx_surname1 + ",'') " + DBBind.Functions.CONCAT + " ' ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(u." + DB.tx_surname2 + ",'')",
  			    "o." + DB.gu_workarea + "='" + gu_workarea + "' AND o." + DB.gu_writer + "=u." + DB.gu_user + " AND o." + DB.id_status + " IN ('NUEVA','ABIERTA','APLAZADA')", 100);

    oSales.setRowDelimiter("\n");
    oSales.setColumnDelimiter("\t");
    oSales.setTextQualifier("");

    oSales.print (oConn, response.getOutputStream());
        
    oConn.close("rp_salesforecast");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("rp_salesforecast");
      }
    oConn = null;
    throw new SQLException(e.getMessage(), e.getSQLState(), e.getErrorCode());
  }
  
  if (null==oConn) return;
    
  oConn = null;

  if (true) return;
%>