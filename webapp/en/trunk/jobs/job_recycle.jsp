<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.Timestamp,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.scheduler.Job" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "job_recycle";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  Timestamp tsNow = new Timestamp(new Date().getTime());
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 
    oConn.setAutoCommit (false);
    oStmt = oConn.prepareStatement("UPDATE "+DB.k_job_atoms+" SET "+DB.id_status+"="+String.valueOf(Job.STATUS_PENDING)+","+DB.tx_log+"=NULL WHERE "+DB.gu_job+"=? AND "+DB.id_status+"="+String.valueOf(Job.STATUS_INTERRUPTED));
    oStmt.setString(1, request.getParameter("gu_job"));
		oStmt.executeUpdate();
		oStmt.close();
    oStmt = oConn.prepareStatement("UPDATE "+DB.k_jobs+" SET "+DB.id_status+"="+String.valueOf(Job.STATUS_PENDING)+","+DB.dt_modified+"=?,"+DB.dt_execution+"=NULL WHERE "+DB.gu_job+"=? AND "+DB.id_status+"<>"+String.valueOf(Job.STATUS_RUNNING));
    oStmt.setTimestamp(1, tsNow);
    oStmt.setString(2, request.getParameter("gu_job"));
		oStmt.executeUpdate();
		oStmt.close();
    oConn.commit();
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  oConn = null;
  
  response.sendRedirect (response.encodeRedirectUrl ("job_modify.jsp?gu_job="+request.getParameter("gu_job")));

%><%@ include file="../methods/page_epilog.jspf" %>