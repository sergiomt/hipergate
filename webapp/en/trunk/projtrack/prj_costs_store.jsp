<%@ page import="java.util.Iterator,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.projtrack.Project" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  /* Autenticate user cookie */
  // if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_user = getCookie (request, "userid", null);

  String gu_project = request.getParameter("gu_project");
  String dt_from = request.getParameter("dt_from");
  String dt_to = request.getParameter("dt_to");
  
  Project oPrj = new Project(gu_project);
  JDCConnection oConn = null;
  PreparedStatement oDuty = null;
  PreparedStatement oCost = null;
  Iterator oIter = request.getParameterMap().keySet().iterator();
  String sParamName;
   
  try {
    oConn = GlobalDBBind.getConnection("prj_cost_store"); 
  
    oDuty = oConn.prepareStatement("UPDATE "+DB.k_duties+" SET "+DB.pr_cost+"=? WHERE "+DB.gu_duty+"=?");
    oCost = oConn.prepareStatement("UPDATE "+DB.k_project_costs+" SET "+DB.pr_cost+"=? WHERE "+DB.gu_cost+"=?");
    
    oConn.setAutoCommit (false);

    while (oIter.hasNext()) {
      sParamName = (String) oIter.next();
      if (sParamName.startsWith("duty_cost_")) {
        oDuty.setFloat (1, Float.parseFloat(request.getParameter(sParamName)));
        oDuty.setString(2, sParamName.substring(10));
        oDuty.executeUpdate();
      }
      if (sParamName.startsWith("cost_cost_")) {
        oCost.setFloat (1, Float.parseFloat(request.getParameter(sParamName)));
        oCost.setString(2, sParamName.substring(10));
        oCost.executeUpdate();
      }      
    } // wend
    oCost.close();
    oCost=null;
    oDuty.close();
    oDuty=null;
    
    oCost = oConn.prepareStatement("UPDATE "+DB.k_projects+" SET "+DB.pr_cost+"=? WHERE "+DB.gu_project+"=?");
    oCost.setFloat (1, oPrj.cost(oConn));
    oCost.setString(2, request.getParameter("gu_project"));
    oCost.executeUpdate();
    oCost.close();
    oCost=null;

    oConn.commit();
    oConn.close("prj_cost_store");
  }
  catch (SQLException e) {
    if (oConn!=null) {
      if (null!=oCost) { try { oCost.close(); } catch (Exception ignore) {} }
      if (null!=oDuty) { try { oDuty.close(); } catch (Exception ignore) {} }
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("prj_cost_store");      
      }
      oConn = null;
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null) {
      if (null!=oCost) { try { oCost.close(); } catch (Exception ignore) {} }
      if (null!=oDuty) { try { oDuty.close(); } catch (Exception ignore) {} }
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("prj_cost_store");      
      }
      oConn = null;
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("prj_costs.jsp?gu_project="+gu_project+(dt_from.length()>0 ? "&dt_from="+dt_from : "")+(dt_to.length()>0 ? "&dt_to="+dt_to : "")));
%>