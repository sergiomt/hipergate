<%@ page import="com.knowgate.addrbook.Fellow,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.*" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
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
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ",");
    
  JDCConnection oCon = GlobalDBBind.getConnection("fellow_delete");
  String sLdapConnect = Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapconnect", "");
  Class oLdapCls = null;
  com.knowgate.ldap.LDAPModel oLdapImpl = null;
    
  try {

    if (sLdapConnect.length()>0) {

      oLdapCls = Class.forName(Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapclass", "com.knowgate.ldap.LDAPNovell"));

      oLdapImpl = (com.knowgate.ldap.LDAPModel) oLdapCls.newInstance();

      oLdapImpl.connectAndBind(Environment.getProfile(GlobalDBBind.getProfileName()));
    }
        
    oCon.setAutoCommit (false);

    for (int i=0;i<a_items.length;i++) {
      Fellow.delete(oCon, a_items[i]);

      if (sLdapConnect.length()>0) {
	        
        try {
          oLdapImpl.deleteUser (oCon, a_items[i]);
        } catch (com.knowgate.ldap.LDAPException ignore) { }
      }
       
      DBAudit.log(oCon, Fellow.ClassId, "DFLW", id_user, a_items[i], null, 0, 0, null, null);
    } // next ()

    if (sLdapConnect.length()>0) {
      oLdapImpl.disconnect();
    }
    
    GlobalCacheClient.expire("k_fellows.id_domain[" + request.getParameter("id_domain") + "]");
    GlobalCacheClient.expire("k_fellows.gu_workarea[" + request.getParameter("gu_workarea") + "]");
    GlobalCacheClient.expire("["+request.getParameter("gu_workarea")+",users]");

    oCon.commit();
    oCon.close("fellow_delete");
  } 
  catch (SQLException e) {
      disposeConnection(oCon,"fellow_delete");

      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
      }
        
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
    }
  catch (com.knowgate.ldap.LDAPException e) {
      disposeConnection(oCon,"fellow_delete");

      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "LDAPException", e.getMessage());
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=LDAPException&desc=" + e.getMessage() + "&resume=_back"));
    }
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='fellow_listing.jsp?selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>
<%@ include file="../methods/page_epilog.jspf" %>