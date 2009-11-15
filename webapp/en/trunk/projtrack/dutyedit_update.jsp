<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.projtrack.Bug" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

  String[] aDuties = Gadgets.split(request.getParameter("checkeditems"),',');      
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  PreparedStatement oDlte = null;
  PreparedStatement oInsr = null;
  String sSet = " "+DB.dt_modified+"="+DBBind.Functions.GETDATE; 
  String sAttr;
  String sRsrc = request.getParameter("nm_resource");
  
  sAttr = request.getParameter("sel_new_status");
  if (sAttr.length()>0) {
    sSet += ","+DB.tx_status+"='"+sAttr+"'";
    if (sAttr.equals("CORREGIDO"))
      sSet += ","+DB.dt_closed+"="+DBBind.Functions.GETDATE;
  }
  sAttr = request.getParameter("sel_new_priority");
  if (sAttr.length()>0) {
    sSet += ","+DB.od_priority+"="+sAttr;
  }
  sAttr = request.getParameter("sel_new_completed");
  if (sAttr.length()>0) {
    sSet += ","+DB.pct_complete+"="+sAttr;
  }
    
  try {
    oConn = GlobalDBBind.getConnection("dutyedit_update"); 
  
    oStmt = oConn.prepareStatement("UPDATE "+DB.k_duties+" SET "+sSet+" WHERE "+DB.gu_duty+"=?");

    oConn.setAutoCommit (false);

    if (sRsrc.length()==0) {
      for (int b=aDuties.length-1; b>=0; b--) {
        oStmt.setString(1, aDuties[b]);
        oStmt.executeUpdate();
      } // next
    } else {
      oDlte = oConn.prepareStatement("DELETE FROM "+DB.k_x_duty_resource+" WHERE "+DB.gu_duty+"=?");
      oInsr = oConn.prepareStatement("INSERT INTO "+DB.k_x_duty_resource+" ("+DB.gu_duty+","+DB.nm_resource+","+DB.pct_time+") VALUES (?,?,100)");

      for (int b=aDuties.length-1; b>=0; b--) {
        oStmt.setString(1, aDuties[b]);
        oStmt.executeUpdate();
        oDlte.setString(1, aDuties[b]);
        oDlte.executeUpdate();
        oInsr.setString(1, aDuties[b]);
        oInsr.setString(2, sRsrc);
        oInsr.executeUpdate();
      } // next
      oInsr.close();
      oInsr=null;
      oDlte.close();
      oDlte=null;
    } // fi

    oStmt.close();
    oStmt=null;
    
    oConn.commit();

    oConn.close("dutyedit_update");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (oInsr!=null) oInsr.close();
        if (oDlte!=null) oDlte.close();
        if (oStmt!=null) oStmt.close();
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("dutyedit_update");  
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;  
  oConn = null;

  if (request.getParameter("subselected").equals("1"))
    response.sendRedirect (response.encodeRedirectUrl ("duty_list.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
  else
    response.sendRedirect (response.encodeRedirectUrl ("duty_resource.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
  	
%>