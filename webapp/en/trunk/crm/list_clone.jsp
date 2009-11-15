<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Connection,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
   
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_instance = request.getParameter("gu_instance");
  
  String sOpCode = request.getParameter("opcode");
  
  short iClassId = Short.parseShort(request.getParameter("classid"));
  String id_user = getCookie (request, "userid", null);
    
  JDCConnection oConOr = null;  
    
  try {
    oConOr = GlobalDBBind.getConnection("list_clone");  
    
    oConOr.setAutoCommit (false);
    
    DistributionList oList = new DistributionList(oConOr, gu_instance);
    
    oList.clone(oConOr);
    
    DBAudit.log(oConOr, iClassId, sOpCode, id_user, gu_instance, oList.getString(DB.gu_list), 0, 0, oList.getStringNull(DB.tx_subject,null), null);
    
    oConOr.commit();
    oConOr.close("list_clone");
  }
  catch (SQLException e) {  
    if (oConOr!=null)
      if (!oConOr.isClosed()) {
        oConOr.rollback();
        oConOr.close("list_clone");
      }
    oConOr = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  
  if (null==oConOr) return;
  
  oConOr = null;
  
  // [~//Refrescar el padre y cerrar la ventana~]
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript1.2' TYPE='text/javascript'>self.close();<" + "/SCRIPT" +"></HEAD></HTML>");
%>