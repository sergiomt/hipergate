<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.debug.DebugFile,com.knowgate.projtrack.Project" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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
      
  String gu_workarea = getCookie (request, "workarea", null);
  
  Project oProj = new Project();
  
  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("tree_refresh");

    DBSubset oRoots = new DBSubset (DB.k_projects, DB.gu_project, DB.gu_owner + "='" + gu_workarea + "' AND " + DB.id_parent + " IS NULL", 10);
    int iRoots = oRoots.load(oConn);
    
    oConn.setAutoCommit (true);
    
    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_project_expand + " WHERE EXISTS (SELECT p." + DB.gu_project + " FROM " + DB.k_projects + " p WHERE " + DB.gu_rootprj + "=p." + DB.gu_project + " AND p." + DB.gu_owner + "='" + gu_workarea + "')");
      
    PreparedStatement oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_project_expand + " WHERE EXISTS (SELECT p." + DB.gu_project + " FROM " + DB.k_projects + " p WHERE " + DB.gu_rootprj + "=p." + DB.gu_project + " AND p." + DB.gu_owner + "=?)");
    oDlte.setString(1, gu_workarea);
    oDlte.executeUpdate();
    oDlte.close();
        
    for (int r=0; r<iRoots; r++) {
      oProj.replace (DB.gu_project, oRoots.getString(0,r));
      oProj.expand(oConn);
    }
      
    oConn.close("tree_refresh");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("tree_refresh");      
      }
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;
%>
<HTML><BODY onload="window.parent.document.location.reload(true)"></BODY></HTML>
<%@ include file="../methods/page_epilog.jspf" %>