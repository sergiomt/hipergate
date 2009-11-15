<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<%
/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

  // if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String[] aDuties = Gadgets.split(request.getParameter("duties"),',');
  String[] aCosts = Gadgets.split(request.getParameter("costs"),',');
  String sProjGu = request.getParameter("gu_project");
  String sDtFrom = request.getParameter("dt_from");
  String sDtTo = request.getParameter("dt_to");  
  JDCConnection oConn = null;;  
  PreparedStatement oDlte = null;
  PreparedStatement oUpdt = null;
  Project oProj = new Project(sProjGu);
  
  try {
    oConn = GlobalDBBind.getConnection("prj_costs_delete");
    oConn.setAutoCommit (false);
    if (aDuties!=null) {
      for (int d=aDuties.length-1; d>=0; d--)
      Duty.delete(oConn, aDuties[d]);
    }
    if (aCosts!=null) {
      oDlte = oConn.prepareStatement("DELETE FROM "+DB.k_project_costs+" WHERE "+DB.gu_cost+"=?");
      for (int c=aCosts.length-1; c>=0; c--) {
        oDlte.setString(1, aCosts[c]);
        oDlte.executeUpdate();
      }
      oDlte.close();
      oDlte=null;
    }
    oUpdt = oConn.prepareStatement("UPDATE "+DB.k_projects+" SET "+DB.pr_cost+"=? WHERE "+DB.gu_project+"=?");
    oUpdt.setFloat (1, oProj.cost(oConn));
    oUpdt.setString(2, sProjGu);
    oUpdt.executeUpdate();
    oUpdt.close();
    oUpdt=null;    
    oConn.commit();
    oConn.close("prj_costs_delete");
    
  }
  catch (SQLException e) {
    if (oConn!=null) {
      if (!oConn.isClosed()) {
        if (null!=oDlte) { try { oDlte.close(); } catch (Exception ignore) {} }
        if (null!=oUpdt) { try { oUpdt.close(); } catch (Exception ignore) {} }
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("prj_costs_delete");
      }
      oConn = null;
    }
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (oConn==null) return;
  oConn = null;  

  response.sendRedirect (response.encodeRedirectUrl ("prj_costs.jsp?gu_project="+sProjGu+(sDtFrom.length()>0 ? "&dt_from="+sDtFrom : "")+(sDtTo.length()>0 ? "&dt_to="+sDtTo : "")));
%>
<%@ include file="../methods/page_epilog.jspf" %>