<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%
/*  
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = null;
  PreparedStatement oStm;
    
  try {
    oCon = GlobalDBBind.getConnection("phonecall_delete");

    oCon.setAutoCommit (false);
  
    oStm = oCon.prepareStatement("UPDATE " + DB.k_phone_calls + " SET " + DB.id_status + "=1 WHERE " + DB.gu_phonecall + "=?");
    
    for (int i=0;i<a_items.length;i++) {
      
      oStm.setString(1, a_items[i]);

      oStm.executeUpdate();

    } // next ()
  
    oStm.close();
    
    oCon.commit();

    oCon.setAutoCommit (true);

    com.knowgate.http.portlets.HipergatePortletConfig.touch(oCon, id_user, "com.knowgate.http.portlets.CallsTab", getCookie(request,"workarea",""));

    oCon.close("phonecall_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"phonecall_delete");
      oCon = null;

      if (com.knowgate.debug.DebugFile.trace) {      
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
      }
           
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>history.back()<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>
<%@ include file="../methods/page_epilog.jspf" %>