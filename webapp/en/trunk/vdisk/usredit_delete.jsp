<%@ page import="java.io.IOException,java.net.URLDecoder,java.util.StringTokenizer,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.addrbook.Fellow" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/dbbind.jsp" %>
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

  String sUsrId;
  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String id_user = getCookie (request, "userid", null);
  String n_domain  = request.getParameter("n_domain");
  
  String sMaxRows = request.getParameter("maxrows");
  String sFind = request.getParameter("find");

  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

  GlobalCacheClient.expireAll();

  StringTokenizer oUsrs = new StringTokenizer(request.getParameter("checkeditems"),",");
  JDCConnection oConn = GlobalDBBind.getConnection("usredit_delete");  
  String sLdapConnect = Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapconnect", "");
  Class oLdapCls = null;
  com.knowgate.ldap.LDAPModel oLdapImpl = null;
  
  try {
    if (!bIsAdmin) {
        throw new SQLException("Administrator role is required for deleteing groups", "28000", 28000);
    }    
    
    oConn.setAutoCommit (false);

    if (sLdapConnect.length()>0) {

      oLdapCls = Class.forName(Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapclass", "com.knowgate.ldap.LDAPNovell"));

      oLdapImpl = (com.knowgate.ldap.LDAPModel) oLdapCls.newInstance();
      
      oLdapImpl.connectAndBind(Environment.getProfile(GlobalDBBind.getProfileName()));
    }
    
    while (oUsrs.hasMoreTokens()) {
      sUsrId = oUsrs.nextToken();

			Fellow.delete(oConn, sUsrId);

      ACLUser.delete(oConn, sUsrId);

      if (sLdapConnect.length()>0) {
        try {
          oLdapImpl.deleteUser (oConn, sUsrId);
        } catch (com.knowgate.ldap.LDAPException ignore) { }
      }
      
      DBAudit.log(oConn, ACLUser.ClassId, "DUSR", id_user, sUsrId, null, 0, getClientIP(request), null, null);
    }

    if (sLdapConnect.length()>0) {
      oLdapImpl.disconnect();
    }
    
    oConn.commit();
    oConn.close("usredit_delete"); 
    oConn = null;  

    response.sendRedirect (response.encodeRedirectUrl ("domusrs.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&show=users&maxrows=" + sMaxRows + "&skip=0" + (sFind.length()>0 ? "&find=" + sFind : "")));
  }
  catch (SQLException e) {
    if (null!=oConn) {
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("usredit_delete");
      }
      oConn = null;
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
%>