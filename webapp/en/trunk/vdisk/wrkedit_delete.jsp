<%@ page import="java.io.IOException,java.net.URLDecoder,java.util.StringTokenizer,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.workareas.*,com.knowgate.misc.Environment" language="java" session="false" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/dbbind.jsp" %>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sWrkId;
  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String id_user = getCookie (request, "userid", null);
  String n_domain  = request.getParameter("n_domain");

  String sMaxRows = request.getParameter("maxrows");
  String sFind = request.getParameter("find");
  
  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  // String sWrkPut = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasput", sDefWrkArPut);
  StringTokenizer oWrks = new StringTokenizer(request.getParameter("checkeditems"),",");

  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
  
  JDCConnection oConn = null;  
  WorkArea oWrkA;
   
  try {
    oConn = GlobalDBBind.getConnection("wrkedit_delete");

    if (!bIsAdmin) {
      throw new SQLException("Administrator role is required for deleteing workareas", "28000", 28000);
    }    

    oConn.setAutoCommit(false);

    while (oWrks.hasMoreTokens()) {
      sWrkId = oWrks.nextToken();
            
      WorkArea.delete(oConn, sWrkId, Environment.getProfile(GlobalDBBind.getProfileName()));
            
      oConn.commit();
    } // wend()

    oConn.close("wrkedit_delete"); 
    oConn = null;  
    
    response.sendRedirect (response.encodeRedirectUrl ("domwrks.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&show=workareas&maxrows=" + sMaxRows + "&skip=0" + (sFind.length()>0 ? "&find=" + sFind : "")));
  }
  catch (SQLException e) {
    if (!oConn.isClosed()) {
      if (!oConn.getAutoCommit()) oConn.rollback();
      oConn.close("wrkedit_delete");
    }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (IOException e) {
    if (!oConn.isClosed()) {
      if (!oConn.getAutoCommit()) oConn.rollback();
      oConn.close("wrkedit_delete");
    }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileSystem Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }  
%>