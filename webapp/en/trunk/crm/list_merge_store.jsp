<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Statement,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.acl.*,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

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

  String gu_base_list = request.getParameter("gu_base_list");
  String gu_added_list = request.getParameter("gu_added_list");
  String tp_action = request.getParameter("tp_action");
  String gu_target = request.getParameter("gu_target");
  String tx_subject = request.getParameter("tx_subject");
  String de_list = request.getParameter("de_list");
  
  Statement oStmt;
  DistributionList oBaseList;
  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("list_merge_store");
    
    oConn.setAutoCommit(false);
    
    oBaseList = new DistributionList(oConn, gu_base_list);
    
    if (gu_target.length()==0) {

      oBaseList.remove(DB.gu_list);
      oBaseList.replace(DB.tx_subject, tx_subject);
      oBaseList.replace(DB.de_list, de_list);
      
      oBaseList.store(oConn);
      
      oStmt = oConn.createStatement();
      oStmt.execute("INSERT INTO " + DB.k_x_list_members + "(gu_list,tx_email,tx_name,tx_surname,mov_phone,tx_salutation,bo_active,tp_member,gu_company,gu_contact,id_format) SELECT '" + oBaseList.getString(DB.gu_list) + "',tx_email,tx_name,tx_surname,mov_phone,tx_salutation,bo_active,tp_member,gu_company,gu_contact,id_format FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + gu_base_list + "'");
      oStmt.close();
      
    }
    
    if (tp_action.equals("append")) {
      oBaseList.append(oConn,gu_added_list);
    }
    else if (tp_action.equals("add")) {
      oBaseList.overwrite(oConn,gu_added_list);
      oBaseList.append(oConn,gu_added_list);
    }
    else if (tp_action.equals("substract")) {
      oBaseList.substract(oConn,gu_added_list);
    }
    
    oConn.commit();
    oConn.close("list_merge_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"list_merge_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  
  if (null==oConn) return;
    
  oConn = null;
%>

<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <TITLE>Wait...</TITLE>
</HEAD>
<BODY onLoad="alert('List combination terminated successfully');window.close();">
</BODY>
</HTML>
