<%@ page import="java.sql.PreparedStatemnet,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><% 
/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

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

  final String PAGE_NAME = "contact_update_ref";

  final String gu_contact = request.getParameter("gu_contact");
  final String id_ref = Gadgets.removeChars(request.getParameter("id_ref")," \n\t");

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
 
  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME);
    
    oConn.setAutoCommit(false);
    
    Prepared
    
    oConn.commit();
      
    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&"+e.getClass().getName()+"=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;    
  oConn = null;

  /* TO DO: Write HTML or redirect to another page */
%>