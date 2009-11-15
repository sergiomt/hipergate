<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Connection,java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
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

  // Inicio de sesion anónimo permitido
  //if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String nm_table = request.getParameter("nm_table");
  String id_language = request.getParameter("id_language");
  String id_section = request.getParameter("id_section");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");  
  int iChkCount = Integer.parseInt(request.getParameter("chkcount"));
  
  String sWorkArea = getCookie(request,"workarea", "");
  
  String sQryStr = "?nm_table="+ nm_table + "&id_language=" + id_language + "&id_section=" + id_section + "&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding;

  JDCConnection oConn = null;
  Statement oStmt;
  String sSQL;
  String sPg;

  // Componer la sentencia SQL de borrado
  
  sSQL = "DELETE FROM " + nm_table + " WHERE " + DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_section + "='" + id_section + "' AND " + DB.pg_lookup + " IN (";
  for (int c=0; c<iChkCount; c++) {
    sPg = request.getParameter("chkbox" + String.valueOf(c));
      
    if (null!=sPg) sSQL += (c==0 ? sPg : "," + sPg);
        
  } // next (c)
  sSQL += ")";  
    
  try {    

    oConn = GlobalDBBind.getConnection("lookup_delete");  

    oConn.setAutoCommit (false);
    
    oStmt = oConn.createStatement();
    oStmt.execute(sSQL);
  
    oConn.commit();
    
    oConn.close("lookup_delete");
    oConn = null;
  }
  catch (SQLException e) {
    disposeConnection(oConn,"lookup_delete");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  response.sendRedirect (response.encodeRedirectUrl ("lookup_mid.jsp" + sQryStr));        
%>