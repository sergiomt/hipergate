<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/dbbind.jsp" %>
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
  String gu_project  = request.getParameter("gu_project");
  JDCConnection oConn = GlobalDBBind.getConnection("prjedit_delete");  
  
  String a_items[];
   
  try {
    
    oConn.setAutoCommit (false);
    
    if (null!=gu_project) {
      Project.delete(oConn, gu_project);
      DBAudit.log(oConn, Project.ClassId, "DPRJ", id_user, gu_project, null, 0, getClientIP(request), null, null);
    }
    
    if (request.getParameter("checkeditems")!=null) {
      a_items = Gadgets.split(request.getParameter("checkeditems"), ',');

      for (int i=0;i<a_items.length;i++) {
        Project.delete(oConn, a_items[i]);
        DBAudit.log(oConn, Project.ClassId, "DPRJ", id_user, a_items[i], null, 0, getClientIP(request), null, null);
      } // next ()      
    } // fi(checkeditems)
        
    oConn.commit();
    oConn.close("prjedit_delete");

    if (request.getParameter("is_standalone").equals("1"))
      out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>self.close();<" + "/SCRIPT" +"></HEAD></HTML>"); 
    else if (request.getParameter("selected")!=null)
      out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='project_listing.jsp?selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
    else
      response.sendRedirect (response.encodeRedirectUrl ("proj_nav_f.jsp"));
  }
  catch (SQLException e) {
    if (!oConn.isClosed()) {
      if (!oConn.getAutoCommit()) oConn.rollback();
      oConn.close("prjedit_delete");
    }
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
        
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oConn) return;

  oConn = null;  
%>
<%@ include file="../methods/page_epilog.jspf" %>