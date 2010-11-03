<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.marketing.ActivityAttachment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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
  String gu_activity = request.getParameter("gu_activity");

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  String a_locat[];
    
  JDCConnection oCon = GlobalDBBind.getConnection("activity_attach_edit_delete");
  oCon.setAutoCommit (false);
  ActivityAttachment oAttach = new ActivityAttachment();
  oAttach.put(DB.gu_activity, gu_activity);
    
  try {
    for (int i=0;i<a_items.length;i++) {
      a_locat = Gadgets.split(a_items[i], "_");
      oAttach.replace(DB.gu_product, a_locat[0]);      
      oAttach.replace(DB.pg_product, Integer.parseInt(a_locat[1]));
    
      oAttach.delete(oCon);
    } // next ()
    oCon.commit();
    oCon.close("activity_attach_edit_delete");
  } 
  catch(Exception e) {
      disposeConnection(oCon,"activity_attach_edit_delete");
      out.write("../common/errmsg.jsp?title=Error&desc=" + e.getMessage());
    }
    
  oCon = null; 
 %>