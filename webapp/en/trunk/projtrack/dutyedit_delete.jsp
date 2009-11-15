<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  String sDutyId;
  String sProjGu;
  int iDutyCount  = Integer.parseInt(request.getParameter("nu_duties"));
  JDCConnection oConn = null;;  
  PreparedStatement oStmt = null;
  PreparedStatement oDuty = null;
  ResultSet oRSet = null;  
  Project oProj = new Project();
  
  try {
    oConn = GlobalDBBind.getConnection("dutyedit_delete");
    oStmt = oConn.prepareStatement("UPDATE "+DB.k_projects+" SET "+DB.pr_cost+"=? WHERE "+DB.gu_project+"=?");
    oDuty = oConn.prepareStatement("SELECT "+DB.gu_project+" FROM "+DB.k_duties+" WHERE "+DB.gu_duty+"=?");
    
    oConn.setAutoCommit (false);
    
    for (int d=0; d<iDutyCount; d++) {
      sDutyId = request.getParameter("chkbox" + String.valueOf(d));
      if (null!=sDutyId) {
	oDuty.setString(1, sDutyId);
        oRSet = oDuty.executeQuery();
        if (oRSet.next())
          sProjGu = oRSet.getString(1);
        else
          sProjGu = null;
        oRSet.close();        
        if (null!=sProjGu) {
          Duty.delete(oConn, sDutyId);
          oProj.replace(DB.gu_project, sProjGu);
    	  oStmt.setFloat (1, oProj.cost(oConn));
    	  oStmt.setString(2, sProjGu);
    	  oStmt.executeUpdate();
        }  
        DBAudit.log(oConn, Duty.ClassId, "DDTY", "unknown", sDutyId, null, 0, getClientIP(request), null, null);
      }
    }  // next (d)
    oDuty.close();
    oDuty=null;
    oStmt.close();
    oStmt=null;
    
    oConn.commit();
    oConn.close("dutyedit_delete");

    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript1.2' TYPE='text/javascript'>\n");
    out.write ("if (window.name==\"editduty\") self.close();\nelse\nwindow.history.back();\n");
    out.write ("</SCRIPT></HEAD><BODY></BODY></HTML>");
    
  }
  catch (SQLException e) {
    disposeConnection(oConn,"dutyedit_delete");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (oConn==null) return;
  
  oConn = null;  

%>
<%@ include file="../methods/page_epilog.jspf" %>