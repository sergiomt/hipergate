<%@ page import="org.w3c.dom.DOMException,java.util.Vector,java.util.HashMap,java.io.FileNotFoundException,java.io.IOException,java.net.URLDecoder,com.knowgate.debug.DebugFile,com.knowgate.dataxslt.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = request.getParameter("gu_pageset");
  String gu_page = request.getParameter("gu_page");
  String doctype = request.getParameter("doctype");
  String id_metablock = request.getParameter("id_metablock");
  String nm_metablock = request.getParameter("nm_metablock");
  String file_pageset = request.getParameter("file_pageset");
  String file_template = request.getParameter("file_template");

  if (DebugFile.trace) {
    DebugFile.writeln("old_order=" + request.getParameter("old_order"));
    DebugFile.writeln("new_order=" + request.getParameter("new_order"));    
  }
                
  String[] aOldOrder = Gadgets.split(request.getParameter("old_order"), ',');
  String[] aNewOrder = Gadgets.split(request.getParameter("new_order"), ',');
  final int iOrder = aNewOrder.length;

  int[] aPermute = new int[iOrder];
    
  for (int b=0; b<iOrder; b++) {
    aPermute[b] = Gadgets.search(aOldOrder,aNewOrder[b]);
  }
      
  PageSet oPageSet = null;
    
  try {
    oPageSet = new PageSet(file_template,file_pageset);
    
    Page oPage = oPageSet.page(gu_page);

    oPage.permute(id_metablock, aPermute);
    
    oPage = null;
    
    oPageSet.save(file_pageset);
  }
  catch (NullPointerException e) {
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NullPointerException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=_back"));
  } 
  catch (DOMException e) {
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "DOMException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DOMException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (ClassNotFoundException e) {
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "ClassNotFoundException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ClassNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (IllegalAccessException e) {  
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IllegalAccessException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalAccessException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (FileNotFoundException e) {  
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "FileNotFoundException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (ArrayIndexOutOfBoundsException e) {  
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "ArrayIndexOutOfBoundsException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=" + e.getMessage() + "&resume=_back"));
  }  
  catch (Exception e) {  
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "Exception", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oPageSet) return;  
%>
<HTML><BODY onload="document.location='wb_document.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=gu_pageset%>&doctype=<%=doctype%>'; window.close();"></BODY></HTML>
<%@ include file="../methods/page_epilog.jspf" %>