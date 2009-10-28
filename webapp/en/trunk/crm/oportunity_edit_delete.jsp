<%@ page import="java.util.*,com.knowgate.crm.*,java.math.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.dataxslt.db.*,com.knowgate.misc.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%

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

  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  
  // [~//Inicializaciones~]
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  String id_user = getCookie (request, "userid", null);
  JDCConnection oCon = null;

  // [~//Recuperar datos de formulario~]
  String chkItems = request.getParameter("checkeditems");  
  String a_items[] = Gadgets.split(chkItems, ',');

  try{
  
    oCon = GlobalDBBind.getConnection("oportunity_delete");
    oCon.setAutoCommit (false);
    
    for (int i=0;i<a_items.length;i++)  
      com.knowgate.crm.Oportunity.delete(oCon, a_items[i]);
  
    oCon.commit();
    oCon.close("oportunity_delete");
  }
  catch (SQLException e) {  
    disposeConnection(oCon,"oportunity_delete"); // fi (isClosed)
    oCon = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  } // catch()
    
  oCon = null;

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='oportunity_listing.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")+"'<" + "/SCRIPT" +"></HEAD></HTML>");
 
 %>
 