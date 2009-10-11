<%@ page import="com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBAudit,com.knowgate.addrbook.ToDo" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><%@ include file="inc/dbbind.jsp" %><%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

  final String PAGE_NAME = "todo_delete";

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String gu_to_do = request.getParameter("gu_to_do");
  ToDo oTd = new ToDo();
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME);

    oConn.setAutoCommit (false);
  
    oTd.put(DB.gu_to_do, gu_to_do);
    oTd.delete(oConn);
  
    oConn.commit();
    oConn.close(PAGE_NAME);
  } 
  catch (Exception e) {
      if (oConn!=null)
        if (!oConn.isClosed()) {
          if (!oConn.getAutoCommit()) oConn.rollback();
          oConn.close(PAGE_NAME);      
        }
      oConn = null; 
      response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
    }
  
  if (null==oConn) return;
  oConn = null; 

  response.sendRedirect ("home.jsp");
%>