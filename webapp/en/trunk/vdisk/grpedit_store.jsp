<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/dbbind.jsp" %>
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

  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String id_user = getCookie (request, "userid", null);
  String n_domain  = request.getParameter("n_domain");
  String id_acl_group = nullif(request.getParameter("gu_acl_group"));
  short activated = Short.parseShort(request.getParameter("activated"));
  String n_acl_group = request.getParameter("nm_acl_group");
  String de_acl_group = request.getParameter("de_acl_group");

  String sGrp = null;
  ACLGroup oGroup;
  JDCConnection oCon1 = null;
  boolean bIsAdmin = false;
  
  try {   
    oCon1 = GlobalDBBind.getConnection("grpedit_store");

    ACLUser oUser = new ACLUser(oCon1, getCookie(request, "userid", ""));
      
    bIsAdmin = oUser.isDomainAdmin(oCon1);

    if (!bIsAdmin) {
        throw new SQLException("Administrator role is required for modifying groups", "28000", 28000);
    }        

    oCon1.setAutoCommit (false);

    if (id_acl_group.length()>0) {
      oGroup = new ACLGroup(id_acl_group);
      
      DBSubset oUsers = oGroup.getACLUsers(oCon1); 
			int nUsers = oUsers.getRowCount();
			for (int u=0; u<nUsers; u++) {
			  GlobalCacheClient.expire ("["+oUsers.getString(0,u)+",groups]");
			}
			oUsers = null;

      oGroup.clearACLUsers(oCon1);
    }
    else
      oGroup = new ACLGroup();
    
    if (id_acl_group.length()>0) oGroup.put(DB.gu_acl_group, id_acl_group);
    oGroup.put(DB.id_domain, id_domain);
    oGroup.put(DB.bo_active, activated);
    oGroup.put(DB.nm_acl_group, n_acl_group);
    if (null!=de_acl_group) oGroup.put(DB.de_acl_group, de_acl_group);

    oGroup.store(oCon1);

    String[] aUsers = Gadgets.split(request.getParameter("memberof"), '`');

    if (null!=aUsers) {
      for (int u=0; u<aUsers.length; u++) {
        oGroup.addACLUser(oCon1, aUsers[u]);        
      }
    }
    
    oCon1.commit();
    oCon1.close();
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        try { oCon1.rollback(); } catch (Exception ignore) {}
        try { oCon1.close(); } catch (Exception ignore) {}
      }
    oCon1 = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }    
  
  if (null==oCon1) return;
  
  oCon1 = null;
  
  GlobalCacheClient.expireAll();
  
  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();</" + "SCRIPT></HEAD><BODY></BODY></HTML>");
%>
