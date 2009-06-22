<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.misc.Gadgets,com.knowgate.acl.*,com.knowgate.training.AcademicCourseBooking" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String[] aDiscardList = Gadgets.split(request.getParameter("gu_discard"),',');
  String[] aInsertList = Gadgets.split(request.getParameter("chekeditems"),',');
  
  AcademicCourseBooking oACBk = new AcademicCourseBooking();
  oACBk.put(DB.gu_acourse, request.getParameter("gu_acourse"));
  oACBk.put(DB.id_classroom, request.getParameter("id_classroom"));
  oACBk.put(DB.bo_confirmed, Short.parseShort(nullif(request.getParameter("bo_confirmed"),"0")));
  oACBk.put(DB.bo_paid, Short.parseShort(nullif(request.getParameter("bo_paid"),"0")));
  oACBk.put(DB.bo_waiting, Short.parseShort(nullif(request.getParameter("bo_waiting"),"0")));
  
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("acourse_book_store"); 
    oConn.setAutoCommit (false);

    if (null!=aInsertList) {
      for (int c=0; c<aInsertList.length; c++) {
        boolean bDiscard = false;
        oACBk.replace(DB.gu_contact, aInsertList[c]);
        if (null!=aDiscardList) {
          for (int d=0; d<aDiscardList.length; d++) {
            bDiscard = bDiscard || aDiscardList[d].equals(aInsertList[c]);
          } // next
        } // fi (aDiscardList)
        if (!bDiscard) oACBk.store(oConn);     
      } // next (c)
    } // fi (aInsertList)
    
    oConn.commit();
    oConn.close("acourse_book_store");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (oConn.getAutoCommit()) oConn.rollback();
        oConn.close("acourse_book_store");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>