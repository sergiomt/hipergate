<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String gu_contact = request.getParameter("gu_contact");

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  String a_locat[];
    
  JDCConnection oCon = GlobalDBBind.getConnection("attachment_delete");
  oCon.setAutoCommit (false);
  Attachment oAttach = new Attachment();
  oAttach.put(DB.gu_contact, gu_contact);
    
  try {
    for (int i=0;i<a_items.length;i++) {
      a_locat = Gadgets.split(a_items[i], "_");
      oAttach.replace(DB.gu_product, a_locat[0]);      
      oAttach.replace(DB.pg_product, Integer.parseInt(a_locat[1]));
    
      oAttach.delete(oCon);
    } // next ()
    oCon.commit();
    oCon.close("attachment_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"attachment_delete");
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='attach_listing.jsp?gu_contact=" + request.getParameter("gu_contact") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>