<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.projtrack.Project" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  String gu_project = request.getParameter("gu_project");

  Project oPrj = new Project(gu_project);

  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("clone_project"); 
  
    oConn.setAutoCommit (false);
    
    String sClon = oPrj.clone(oConn);
    
    oPrj = new Project (oConn, sClon);
    oPrj.replace(DB.nm_project, request.getParameter("nm_project"));
    oPrj.replace(DB.gu_company, request.getParameter("gu_company").length()==0 ? null : request.getParameter("gu_company"));
    oPrj.replace(DB.gu_contact, request.getParameter("gu_contact").length()==0 ? null : request.getParameter("gu_contact"));
    oPrj.replace(DB.id_dept, request.getParameter("id_dept").length()==0 ? null : request.getParameter("id_dept"));
    oPrj.replace(DB.id_ref, request.getParameter("id_ref").length()==0 ? null : request.getParameter("id_ref"));
    oPrj.replace(DB.de_project, request.getParameter("de_project").length()==0 ? null : request.getParameter("de_project"));
    oPrj.store (oConn);
    
    oConn.commit();
    oConn.close("clone_project");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"clone_project");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
        
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>
<%@ include file="../methods/page_epilog.jspf" %>