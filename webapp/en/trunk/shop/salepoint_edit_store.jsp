<%@ page import="java.math.BigDecimal,java.sql.Types.*,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.debug.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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
    
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_sale_point = request.getParameter("gu_sale_point");
  String gu_address = request.getParameter("gu_address");
  String ix_address = request.getParameter("ix_address");
  String id_class = request.getParameter("id_class");
  String id_user = getCookie (request, "userid", null);
  String tx_previous_email = "";
  String gu_geozone = null;
  
  String sLanguage = getNavigatorLanguage(request);
  
  String sOpCode = gu_sale_point.length()>0 ? "NSLP" : "MSLP";
    
  JDCConnection oConn = null;  
  
  SalePoint oAddr = new SalePoint();
 
  try {
    oConn = GlobalDBBind.getConnection("salepoint_edit_store");  

    loadRequest(oConn, request, oAddr);
    
    if (gu_sale_point.length()>0)
      oAddr.put(DB.gu_sale_point, gu_sale_point);

	  oAddr.put(DB.gu_workarea, gu_workarea);

	  oAddr.put(DB.nm_sale_point, request.getParameter("nm_sale_point"));

    oConn.setAutoCommit (false);
          
    oAddr.store(oConn);
    
    DBAudit.log(oConn, Short.parseShort(id_class), sOpCode, id_user, oAddr.getString(DB.gu_sale_point), null, 0, 0, null, null);

    oConn.commit();

    oConn.close("salepoint_edit_store");    
  }
  catch (NullPointerException e) {  
    disposeConnection(oConn,"salepoint_edit_store"); // fi (isClosed)
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  } // catch()
  
  if (null==oConn) return;
  
  oAddr = null;
  oConn = null;  
%>
<HTML>
<HEAD>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--      
      if (window.parent.opener)
        window.parent.opener.location.reload(true);
      window.parent.close();      
    //-->
  </SCRIPT>
</HEAD>
</HTML>