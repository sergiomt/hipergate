<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,com.knowgate.hipergate.*" language="java" session="false" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.

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
  
  Integer IdCategory = new Integer(request.getParameter("id_category"));
  Integer ACLMask = new Integer(request.getParameter("acl_mask"));
  String TpAction = request.getParameter("tp_action");
  String sUsers = request.getParameter("usr_list");
  short  iRecurseChilds = (short) 1;
  short  iPropagateObjs = (short) 1;
  
  Category oCatg = new Category();  
  
  JDCConnection oConn = GlobalDBBind.getConnection("catusers_store");
    
  oCatg.put("id_category", IdCategory.intValue()); 

  try {  
    oConn.setAutoCommit (false);
    oCatg.removeUserPermissions (oConn, sUsers, iRecurseChilds, iPropagateObjs);

    if (TpAction.compareTo("modify")==0)
      oCatg.setUserPermissions (oConn, sUsers, ACLMask.intValue(), iRecurseChilds, iPropagateObjs);
    
    oConn.commit();
    oConn.close("catusers_store");    
  }
  catch (SQLException e) {
    if (!oConn.isClosed()) {
      if (!oConn.getAutoCommit()) oConn.rollback();
      oConn.close("catusers_store");
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  oConn = null;
  oCatg = null;
    
  response.sendRedirect ( response.encodeRedirectUrl ("catusers.jsp?id_category=" + request.getParameter("id_category") + "&n_category=" + request.getParameter("id_category")));
%>
