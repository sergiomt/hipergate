<%@ page import="java.util.Date,java.text.SimpleDateFormat,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBAudit,com.knowgate.dataobjs.DBPersist,com.knowgate.addrbook.ToDo,com.knowgate.misc.Gadgets,com.knowgate.debug.StackTraceUtil" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><%@ include file="inc/dbbind.jsp" %><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "todo_store";
  final String gu_to_do = request.getParameter("gu_to_do");
    
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  Date oDtEnd = null;

  if (request.getParameter("yend").length()>0 && request.getParameter("mend").length()>0 && request.getParameter("dend").length()>0) {
    try {
      oDtEnd = oFmt.parse(request.getParameter("yend")+"-"+request.getParameter("mend")+"-"+request.getParameter("dend")+" 23:59:59");
    } catch (Exception xcpt) { }
  }

  if (request.getParameter("tl_to_do").length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=To Do title is required&desc=A title for the To Do is required&resume=todo_edit.jsp"+(gu_to_do==null ? "" : "?gu_to_do="+gu_to_do)));
  }

  ToDo oTodo = new ToDo();
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

		if (gu_to_do.length()>0) {
		  oTodo.load(oConn, new Object[]{gu_to_do});
		} else {
		  oTodo.put(DB.gu_workarea, oUser.getString(DB.gu_workarea));
		}

		oTodo.replace(DB.gu_user, oUser.getString(DB.gu_user));
	  if (oDtEnd!=null) oTodo.replace(DB.dt_end, oDtEnd);
	  oTodo.replace(DB.tl_to_do, request.getParameter("tl_to_do"));
	  oTodo.replace(DB.tp_to_do, request.getParameter("tp_to_do"));
	  oTodo.replace(DB.tx_status, request.getParameter("tx_status"));
	  oTodo.replace(DB.od_priority, Short.parseShort(request.getParameter("od_priority")));

		oTodo.store(oConn);
    
    oConn.commit();
    oConn.close(PAGE_NAME);
  }
  catch (Exception xcpt) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close(PAGE_NAME);
      }
    oConn = null;
    
		out.write("<?xml version=\"1.0\"?><wml><card>"+xcpt.getClass().getName()+"<br/>"+xcpt.getMessage()+"<br/>"+Gadgets.replace(StackTraceUtil.getStackTrace(xcpt),"\n","<br/>")+"</card></wml>");
  }

  if (null==oConn) return;
  oConn = null;
  
  response.sendRedirect ("home.jsp");
%>