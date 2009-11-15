<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/reqload.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
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
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  String gu_member = request.getParameter("gu_member");
  String chk_bloqued = nullif(request.getParameter("chk_bloqued"));
  String was_bloqued = request.getParameter("was_bloqued");
  String gu_list = request.getParameter("gu_list");
  String gu_blacklist = request.getParameter("gu_blacklist");
  short tp_member = Short.parseShort(request.getParameter("tp_member"));
  
  String sOpCode = gu_member.length()>0 ? "NMBR" : "MMBR";
    
  DistributionList oLst;
    
  ListMember oMbr = new ListMember();

  oMbr.put(DB.bo_active, Short.parseShort(request.getParameter("bo_active")));
  oMbr.put(DB.tp_member, tp_member);
  oMbr.put(DB.gu_member, request.getParameter("gu_member"));
  oMbr.put(DB.id_format, request.getParameter("id_format"));
  
  if (tp_member==Company.ClassId)
    oMbr.put(DB.gu_company, request.getParameter("gu_member"));
  else if (tp_member==Contact.ClassId)
    oMbr.put(DB.gu_contact, request.getParameter("gu_member"));


  JDCConnection oConn = GlobalDBBind.getConnection("member_edit_store");  

  loadRequest(oConn, request, oMbr.member());
  
  try {
    
    oConn.setAutoCommit (false);
    
    oMbr.store(oConn, gu_list);

    if (!chk_bloqued.equals(was_bloqued)) {
      
      if (was_bloqued.length()==0) {
        
        oLst = new DistributionList();
        
        if (gu_blacklist.length()>0)
          oLst.put(DB.gu_list, gu_blacklist);
        else {  
          oLst.put(DB.gu_workarea, gu_workarea);
          oLst.put(DB.tp_list, DistributionList.TYPE_BLACK);
          oLst.put(DB.gu_query, request.getParameter("gu_list"));
          oLst.put(DB.de_list, request.getParameter("de_list"));

	  oLst.store(oConn);
	}
	
        oMbr.replace(DB.tp_list, DistributionList.TYPE_BLACK);
	oMbr.replace(DB.gu_list, oLst.getString(DB.gu_list));
	oMbr.replace(DB.tp_member, ListMember.ClassId);
	
        oMbr.store(oConn, oLst.getString(DB.gu_list));
        
      }
      
      if (chk_bloqued.length()==0) {
        oMbr.remove (DB.tp_list);
        oMbr.delete (oConn, gu_blacklist);        
      }
    }
    
    DBAudit.log(oConn, ListMember.ClassId, sOpCode, id_user, oMbr.getString(DB.gu_member), null, 0, 0, oMbr.getString(DB.tx_email), null);
    
    oConn.commit();
    oConn.close("member_edit_store");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("...");      
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  oConn = null;
  
  // [~//Refrescar el padre y cerrar la ventana~]
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>