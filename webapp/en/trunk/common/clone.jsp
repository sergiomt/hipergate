<%@ page import="java.util.Properties,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Connection,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.datacopy.*,com.knowgate.acl.*,com.knowgate.misc.*,com.knowgate.crm.Company,com.knowgate.crm.Contact,com.knowgate.hipergate.Invoice,com.knowgate.hipergate.DespatchAdvice,com.knowgate.hipergate.Order" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
   
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  String gu_oldinstance = request.getParameter("gu_instance");
  Object oPKOr[] = Gadgets.split(gu_oldinstance,',');
  
  String gu_newinstance = Gadgets.generateUUID();
  
  Object oPKTr[] = new String[oPKOr.length];
  for (int pk=0; pk<oPKOr.length; pk++)
    oPKTr[pk] = gu_newinstance;
  
  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");
  String sOpCode = request.getParameter("opcode");
  short iClassId = Short.parseShort(request.getParameter("classid"));
  
  Properties oProps = new Properties();
  DataStruct oDS; 
  JDCConnection oConOr = null;  
  JDCConnection oConTr = null;  
  
  String sSep = System.getProperty("file.separator");
  String sDBMS;

  try {
    oConOr = GlobalDBBind.getConnection("clone_origin");  
    oConTr = GlobalDBBind.getConnection("clone_target");  

    switch (oConOr.getDataBaseProduct()) {
      case JDCConnection.DBMS_POSTGRESQL:
        sDBMS = "postgresql";
        break;
      case JDCConnection.DBMS_MYSQL:
        sDBMS = "mysql";
        break;
      case JDCConnection.DBMS_MSSQL:
        sDBMS = "mssql";
        break;
      case JDCConnection.DBMS_ORACLE:
        sDBMS = "oracle";
        break;
      default:
        sDBMS = "";
        throw new UnsupportedOperationException("Unrecognized DBMS");
      }
      
    switch (iClassId) {
      case Company.ClassId:
      case Contact.ClassId:
        oProps.put("IdWorkArea", gu_workarea);
        oProps.put("IdOwner", id_user);    		
        break;
      case Invoice.ClassId:
        // Set number for new Invoice
        oProps.put("PgInvoice", String.valueOf(Invoice.nextVal(oConTr, gu_workarea)));
        break;
      case DespatchAdvice.ClassId:
        // Set number for new Despatch Advice
        oProps.put("PgDispatchNote", String.valueOf(DespatchAdvice.nextVal(oConTr, gu_workarea)));
        break;
      case Order.ClassId:
        // Set number for new order
        oProps.put("PgOrder", String.valueOf(DBBind.nextVal(oConTr, "seq_" + DB.k_orders)));
        break;
    } // end switch

    oDS = new DataStruct(sStorage + sSep + "datacopy" + sSep + sDBMS + sSep + request.getParameter("datastruct") + ".xml", oProps);
        
    if (oConOr.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL
     && oConOr.getDataBaseProduct()!=JDCConnection.DBMS_MYSQL
     && oConOr.getDataBaseProduct()!=JDCConnection.DBMS_ORACLE)
      oConOr.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);

    oDS.setOriginConnection(oConOr);
    oDS.setTargetConnection(oConTr);

    oConTr.setAutoCommit (false);
    
    oDS.insert(oPKOr, oPKTr, oPKTr.length);
    oDS.clear ();
    
    DBAudit.log(oConTr, iClassId, sOpCode, id_user, gu_oldinstance, gu_newinstance, 0, 0, null, null);
    
    oConTr.commit();
    oConTr.close("clone_target");
    oConOr.close("clone_origin");
  }
  catch (SQLException e) {  
    if (oConOr!=null)
      if (!oConOr.isClosed()) {
        oConOr.close("clone_origin");      
      }
    if (oConTr!=null)
      if (!oConTr.isClosed()) {
        oConTr.rollback();
        oConTr.close("clone_target");      
      }
    oConOr = null;
    oConTr = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  catch (NullPointerException e) {  
    if (oConOr!=null)
      if (!oConOr.isClosed()) {
        oConOr.close("clone_origin");      
      }
    if (oConTr!=null)
      if (!oConTr.isClosed()) {
        oConTr.rollback();
        oConTr.close("clone_target");      
      }
    oConOr = null;
    oConTr = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }

  if (null==oConOr && null==oConTr) return;
  
  oConOr = null;
  oConTr = null;
  
  // Refrescar el padre y cerrar la ventana
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript1.2' TYPE='text/javascript'>self.close();<" + "/SCRIPT" +"></HEAD></HTML>");
%>