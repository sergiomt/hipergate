<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Statement,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Job,com.knowgate.crm.DistributionList,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
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
 
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  String gu_job = request.getParameter("gu_job");
  String tl_job = request.getParameter("tl_job");  
  String gu_job_group = request.getParameter("gu_job_group");
  String id_command = request.getParameter("id_command");
  String tx_parameters = request.getParameter("tx_parameters");
  String id_status = request.getParameter("id_status");
  String sSQL = "";
  final boolean bAsap = request.getParameter("dt_execution").equals("ASAP");
  
  JDCConnection oConn = null;  
  
  try {
    oConn = GlobalDBBind.getConnection("jobstore");  
    
    sSQL = "INSERT INTO k_jobs ";
    sSQL += "(gu_workarea,gu_writer,gu_job,tl_job,gu_job_group,id_command,tx_parameters,id_status,dt_execution) VALUES (";
    sSQL += "'"+gu_workarea+"',";
    sSQL += "'"+id_user+"',";
    sSQL += "'"+gu_job+"',";
    sSQL += "'"+tl_job+"',";    
    sSQL += "'"+gu_job_group+"',";
    sSQL += "'"+id_command+"',";
    sSQL += "'"+tx_parameters+"',";
    sSQL += id_status+",";
    if (bAsap)
      sSQL += "NULL";
    else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL)
      sSQL += "timestamp '" + request.getParameter("dt_execution") + " 00:00:00' ";
    else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
      sSQL += "TIMESTAMP ('" + request.getParameter("dt_execution") + " 00:00:00') ";
    else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE)
      sSQL += "TO_DATE('" + request.getParameter("dt_execution") + " 00:00','YYYY-MM-DD HH24:MI') ";
    else
      sSQL += "{ d '" + request.getParameter("dt_execution") + "'} ";
    sSQL += ")";
    
    oConn.setAutoCommit (false);

    Statement oStmt = oConn.createStatement();
    
    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      
    oStmt.executeUpdate(sSQL);
    oStmt.close();
    
    int iGuList = tx_parameters.indexOf("gu_list:");
    if (iGuList>0) {
      String sGuList = tx_parameters.substring(iGuList+8,iGuList+40);
      DistributionList oRecipients = new DistributionList (oConn, sGuList);
      String[] aRecipients = Gadgets.split(oRecipients.activeMembers(oConn),',');
      Job oEmailSender = Job.instantiate(oConn, gu_job, GlobalDBBind.getProperties());
      oEmailSender.insertRecipients(oConn, aRecipients, "to", "html", Job.STATUS_PENDING);
    } // fi
    
    oConn.commit();
    oConn.close("jobstore");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (oConn.getAutoCommit()) oConn.rollback();
        oConn.close("jobstore");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><"+"SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript' SRC='../javascript/xmlhttprequest.js'><"+"/SCRIPT"+">");
  out.write ("<" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
  if (bAsap) {
    out.write ("var sched_info = httpRequestXML('../servlet/HttpSchedulerServlet?action=info'); var sched_stat = getElementText(sched_info.getElementsByTagName('scheduler')[0],'status'); ");
    out.write ("if (sched_stat=='stop' || sched_stat=='stopped') httpRequestXML('../servlet/HttpSchedulerServlet?action=start'); ");
  }
  out.write ("window.opener.location='../jobs/job_list.jsp?orderby=5&selected=5&subselected=2&id_command=" + id_command + "&list_title=:%20[~Envios~]'; self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%><%@ include file="../methods/page_epilog.jspf" %>