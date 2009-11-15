<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.projtrack.Project,com.knowgate.projtrack.ProjectCost" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
<%
/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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
  
  Project oProj = new Project(request.getParameter("gu_project"));  
  ProjectCost oCost = new ProjectCost();
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  
  try {
    oConn = GlobalDBBind.getConnection("cost_edit_store"); 
    loadRequest(oConn, request, oCost);
    oConn.setAutoCommit (false);    
    oCost.store(oConn);

    oStmt = oConn.prepareStatement("UPDATE "+DB.k_projects+" SET "+DB.pr_cost+"=? WHERE "+DB.gu_project+"=?");
    oStmt.setFloat (1, oProj.cost(oConn));
    oStmt.setString(2, oProj.getString(DB.gu_project));
    oStmt.executeUpdate();
    oStmt.close();
    oStmt=null;

    oConn.commit();
    oConn.close("cost_edit_store");
  }
  catch (SQLException e) {  
    if (oConn!=null) {
      if (null!=oStmt) { try { oStmt.close(); } catch (Exception ignore) {} }
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("cost_edit_store");      
      }
      oConn = null;
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null) {
      if (null!=oStmt) { try { oStmt.close(); } catch (Exception ignore) {} }
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("cost_edit_store");      
      }
      oConn = null;
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }  
  if (null==oConn) return;
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>