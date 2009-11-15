<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_user = getCookie (request, "userid", null);
      
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_alumni = request.getParameter("gu_alumni");
  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  String a_class[] = Gadgets.split(request.getParameter("classrooms"), ',');

  String gu_object = request.getParameter("gu_alumni");

  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  
  try {
    oConn = GlobalDBBind.getConnection("acourses_assign_store"); 
  
    oConn.setAutoCommit (false);

    oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_x_course_alumni + " WHERE " + DB.gu_alumni + "=? AND " + DB.gu_acourse + " IN (SELECT " + DB.gu_course + " FROM " + DB.k_academic_courses + " WHERE " + DB.bo_active + "<>0)");
    oStmt.setString(1, gu_alumni);
    oStmt.executeUpdate();
    oStmt.close();
    oStmt=null;
    oStmt = oConn.prepareStatement("INSERT INTO "+DB.k_x_course_alumni+"("+DB.gu_acourse+","+DB.gu_alumni+","+DB.id_classroom+") VALUES (?,'"+gu_alumni+"',?)");
    for (int c=0; c<a_items.length; c++) {
        oStmt.setString(1, a_items[c]);
        oStmt.setString(2, a_class[c]);
        oStmt.executeUpdate();
    } // next
    oStmt.close();
    oStmt=null;    
    oConn.commit();
    oConn.close("acourses_assign_store");
  }
  catch (SQLException e) {  
    try { if (oStmt!=null) oStmt.close(); } catch (SQLException ignore) { }
    disposeConnection(oConn,"acourses_assign_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>