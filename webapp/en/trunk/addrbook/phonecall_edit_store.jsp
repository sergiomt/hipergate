<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.crm.PhoneCall,com.knowgate.projtrack.Bug" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/reqload.jspf" %><%
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = request.getParameter("gu_workarea");
  String bo_newbug = nullif(request.getParameter("chk_bug"),"0");
  
  String gu_phonecall = request.getParameter("gu_phonecall");

  String sOpCode = nullif(gu_phonecall).length()>0 ? "NPHN" : "MPHN";
    
  PhoneCall oPhn = new PhoneCall();

  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("phonecall_edit_store");

    loadRequest(oConn, request, oPhn);
    oPhn.put(DB.gu_writer, id_user);

    oConn.setAutoCommit (false);

    if (bo_newbug.equals("1")) {
      ACLUser oRep = new ACLUser(oConn, id_user);
      String sNmReporter = oRep.getStringNull(DB.nm_user,"")+" "+oRep.getStringNull(DB.tx_surname1,"")+" "+oRep.getStringNull(DB.tx_surname2,"");
      Bug oBug = new Bug();
      oBug.put(DB.tl_bug,Gadgets.left(request.getParameter("tx_comments"),250).toUpperCase());
      oBug.put(DB.gu_writer,id_user);
      oBug.put(DB.gu_project,request.getParameter("gu_project"));      
      oBug.put(DB.od_priority,(short)4);
      oBug.put(DB.od_severity,(short)4);
      oBug.put(DB.nm_assigned,request.getParameter("gu_user"));      
      oBug.put(DB.tx_rep_mail,oRep.getString(DB.tx_main_email));
      oBug.put(DB.nm_reporter,Gadgets.left(sNmReporter.trim(),50));
      oBug.put(DB.id_client,request.getParameter("gu_contact"));
      oBug.put(DB.tx_bug_brief, request.getParameter("tx_comments"));
      oBug.store(oConn);
      oPhn.replace(DB.gu_bug, oBug.getString(DB.gu_bug));
    }

    oPhn.store(oConn);

    DBAudit.log(oConn, oPhn.ClassId, sOpCode, id_user, oPhn.getString(DB.gu_phonecall), request.getParameter("gu_contact"), 0, 0, null, null);
    
    oConn.commit();

    oConn.setAutoCommit (true);

    com.knowgate.http.portlets.HipergatePortletConfig.touch(oConn, id_user, "com.knowgate.http.portlets.CallsTab", gu_workarea);

    oConn.close("phonecall_edit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"phonecall_edit_store");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,"phonecall_edit_store");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NumberFormatException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript' SRC='../javascript/cookies.js'></SCRIPT> <" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>setCookie('lastcallfor','" + request.getParameter("gu_user") + "'); if (typeof(window.parent.opener)!='undefined') window.parent.opener.location.reload(true); window.parent.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>
<%@ include file="../methods/page_epilog.jspf" %>