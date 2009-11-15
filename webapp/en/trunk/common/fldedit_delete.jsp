<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.MetaAttribute" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%
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
  String nm_table = request.getParameter("nm_table");
  String id_section = request.getParameter("field");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_language = request.getParameter("lang");
  
  String sKey = nm_table + "#" + id_language + "[" + gu_workarea + "]";
    
  JDCConnection oCon = null;
  MetaAttribute oAtr = null;
        
  try {
    oCon = GlobalDBBind.getConnection("customfield_delete");

    oCon.setAutoCommit (false);
    
    oAtr = new MetaAttribute(oCon, gu_workarea, nm_table, id_section);
    
    oAtr.delete(oCon);
    
    GlobalCacheClient.expire(sKey);
    //DBAudit.log(oCon, MetaAttribute.ClassId, "DATR", id_user, gu_workarea, null, 0, 0, nm_table+"."+id_section, null);

    oCon.commit();
    oCon.close("customfield_delete");
  } 
  catch (SQLException e) {
      disposeConnection(oCon,"customfield_delete");
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
      return;
  }
  /*
  catch (NullPointerException e) {
      disposeConnection(oCon,"customfield_delete");
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + id_section + "&resume=_back"));
      return;
  }
  */
  if (null==oCon) return;    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='" + request.getParameter("urlback") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>