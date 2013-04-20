<%@ page import="com.knowgate.debug.StackTraceUtil,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.Timestamp,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/xml;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
/*
  Get a query resultset in a format suitable for filling a combobox using XMLHttpRequest
  
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
  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  int iLimit=1000, iSkip=0;    
  String id_user = getCookie (request, "userid", null);
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String nu_limit = request.getParameter("nu_limit");
  String nu_skip = request.getParameter("nu_skip");

  if (null!=nu_limit) iLimit = Integer.parseInt(nu_limit); 
  if (null!=nu_skip) iSkip = Integer.parseInt(nu_skip); 
  
  String nm_select = request.getParameter("nm_select");
  String id_form = request.getParameter("id_form");
  String nm_table = request.getParameter("nm_table");
  String nm_value = request.getParameter("nm_value");
  String nm_text = request.getParameter("nm_text");
  String tx_order = request.getParameter("tx_order");
  String tx_where = request.getParameter("tx_where");

  if (nm_table==null)
    throw new NullPointerException("select_xml.jsp parameter nm_table is required "+request.getHeader("referer"));
    
  String sWhere = "";
  if (nm_table.equals("v_prod_cat"))
    sWhere = DB.gu_category+"=? "; 
  else if (nm_table.equals("v_prod_cat_on_sale"))
    sWhere = DB.gu_category+"=? AND "+DB.dt_start+">? ORDER BY "+DB.dt_start; 
  else if (id_domain!=null && gu_workarea!=null)
    sWhere = "("+DB.id_domain+"=? AND "+DB.gu_workarea+"=?) ";
  else if (id_domain!=null)
    sWhere = DB.id_domain+"=? ";
  else if (gu_workarea!=null)
    sWhere = DB.gu_workarea+"=? ";
  else if (!nm_table.equals(DB.k_products))
    throw new SQLException("Either id_domain or gu_workarea parameters are required");
  if (tx_where!=null) if (tx_where.length()>0) sWhere += (sWhere.length()==0 ? "" : " AND ") + " ("+tx_where+") ";
  if (tx_order!=null) if (tx_order.length()>0) sWhere += " ORDER BY "+tx_order;

  JDCConnection oConn = null;  
  DBSubset oSel = new DBSubset (nm_table.equals("v_prod_cat_on_sale") ? "v_prod_cat" : nm_table, nm_value+","+nm_text, sWhere, iLimit);
  int iSel = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("select_xml");
        
    if (null!=nu_limit) oSel.setMaxRows(iLimit);

    if (nm_table.equals("v_prod_cat_on_sale"))
      iSel = oSel.load(oConn, new Object[]{gu_workarea, new Timestamp(new Date().getTime())}, iSkip);
    else if (id_domain!=null && gu_workarea!=null)
      iSel = oSel.load(oConn, new Object[]{new Integer(id_domain),gu_workarea}, iSkip);
    else if (id_domain!=null)
      iSel = oSel.load(oConn, new Object[]{new Integer(id_domain)}, iSkip);    
    else if (gu_workarea!=null)
      iSel = oSel.load(oConn, new Object[]{gu_workarea}, iSkip);
    else
      iSel = oSel.load(oConn, iSkip);

    oConn.close("select_xml");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("select_xml");      
    oConn = null;
    out.write("<selectxml><error>"+e.getClass().getName()+" "+e.getMessage()+" "+StackTraceUtil.getStackTrace(e)+"</error><name>"+nm_select+"</name><form>"+id_form+"</form><options></options></selectxml>");
  }  
  if (null==oConn) return;    
  oConn = null;

  out.write("<selectxml><error></error><name>"+nm_select+"</name><form>"+id_form+"</form><options count=\""+String.valueOf(iSel)+"\">");
  for (int s=0; s<iSel; s++) out.write("<option value=\""+oSel.getString(0,s)+"\"><![CDATA["+oSel.getString(1,s)+"]]></option>");
  out.write("</options></selectxml>");
%>