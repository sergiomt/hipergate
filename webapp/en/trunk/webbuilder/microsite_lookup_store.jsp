<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
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

  String sWorkArea = getCookie(request,"workarea", "");
  
  String sQryStr = "?nm_table="+ nm_table + "&id_language=" + id_language + "&id_section=" + id_section + "&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding;

  String tr_desc = request.getParameter("tr_" + id_language);
  String vl_lookup = request.getParameter("vl_lookup");

  JDCConnection oConn = null;
  PreparedStatement oStmt;
  ResultSet oRSet;
  int iErrorLevel = 0;
  Object oNextPg;
  int iNextPg;

  try {  
    oConn = GlobalDBBind.getConnection("lookup_store");  
  
    // Verificar que no existe ningun otro registro con el mismo valor o descripción
    
    oStmt = oConn.prepareStatement("SELECT " + DB.vl_lookup + "," + DB.tr_ + id_language + " FROM " + nm_table + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=? AND (" + DB.tr_ + id_language + "=? OR " + DB.vl_lookup + "=?)");
    oStmt.setString(1, sWorkArea);
    oStmt.setString(2, id_section);
    oStmt.setString(3, tr_desc);
    oStmt.setString(4, vl_lookup);
    oRSet = oStmt.executeQuery();
    
    if (oRSet.next())
      iErrorLevel = (oRSet.getString(1).equals(vl_lookup) ? 1 : 2);

    oRSet.close();
    oStmt.close();
    
    oConn.close("lookup_store");
    
    if (1==iErrorLevel) {
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Duplicated data&desc=Another register with same value already exists&resume=_back"));
      return;
    }
    else if (2==iErrorLevel) {
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Duplicated data&desc=Another register with same description already exists&resume=_back"));
      return;
    }
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("lookup_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    return;
  }
  
  try {
    
    // Continuar sólo si no había registros duplicados
    
    if (0==iErrorLevel) {

      oConn = GlobalDBBind.getConnection("lookup_store");  

      // Hallar el siguiente progresivo dentro de esta sección

      oStmt = oConn.prepareStatement("SELECT MAX(" + DB.pg_lookup + ")+1 FROM " + nm_table + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=?");
      oStmt.setString(1, sWorkArea);
      oStmt.setString(2, id_section);
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        oNextPg = oRSet.getObject(1);
        if (oRSet.wasNull())
          iNextPg = 1;
        else
          iNextPg = Integer.parseInt(oNextPg.toString());
      }
      else
        iNextPg = 1;
      oRSet.close();
      oStmt.close();
      
      // Insertar el nuevo valor
      oConn.setAutoCommit (false);
            
      oStmt = oConn.prepareStatement("INSERT INTO " + nm_table + "(" + DB.gu_owner + "," + DB.id_section + "," + DB.pg_lookup + "," + DB.vl_lookup + "," + DB.tr_ + id_language + ") VALUES (?,?,?,?,?)");
      oStmt.setString(1, sWorkArea);
      oStmt.setString(2, id_section);
      oStmt.setInt(3, iNextPg);
      oStmt.setString(4, vl_lookup);
      oStmt.setString(5, tr_desc);      
      oStmt.execute();
      oStmt.close();
      
      oConn.commit();
      
      oConn.close("lookup_store");

      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
      }
            
      response.sendRedirect (response.encodeRedirectUrl ("lookup_mid.jsp" + sQryStr));            
    } // fi (iErrorLevel)
  }
  catch (SQLException e) {
    disposeConnection(oConn,"lookup_store");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (oConn==null) return;
  
  oConn=null;
  
%>
<%@ include file="../methods/page_epilog.jspf" %>
