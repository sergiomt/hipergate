<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.Category" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/dbbind.jsp" %><%
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
  
  String sCatg = request.getParameter("id_category");
  String nCatg = request.getParameter("n_category");
  String sPrnt = request.getParameter("id_parent_cat");
  
  int iDomainId = Integer.parseInt(request.getParameter("id_domain"));
  String sUserId = getCookie (request, "userid", null);  
  int iACLMask = Integer.parseInt(request.getParameter("acl_mask"));
  short iRecurse = Short.parseShort(nullif(request.getParameter("recurse"),"0"));
  String TpAction = request.getParameter("tp_action");
  String sGroups = request.getParameter("grp_list");
    
  Category oCatg = new Category(sCatg);

  JDCConnection oConn = GlobalDBBind.getConnection("catgrps_store");
    
  try {
    oConn.setAutoCommit (false);

    oCatg.removeGroupPermissions (oConn, sGroups, iRecurse, iRecurse);
    
    if (TpAction.compareTo("modify")==0)
      oCatg.setGroupPermissions (oConn, sGroups, iACLMask, iRecurse, iRecurse);
    
    oConn.commit();
    oConn.close("catgrps_store");
    oConn = null;
  }
  catch (SQLException e) {
    if(null!=oConn)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("catgrps_store");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error connecting to database&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    return;
  }
  response.sendRedirect ( response.encodeRedirectUrl ("catgrps.jsp?id_domain=" + String.valueOf(iDomainId) + "&id_category=" + sCatg + "&n_category=" + nCatg + "&id_parent_cat=" + sPrnt));
%>