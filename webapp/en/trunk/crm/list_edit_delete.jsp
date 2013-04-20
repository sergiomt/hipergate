<%@ page import="com.knowgate.crm.DistributionList,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Job" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%
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

  final int Mailwire=13,WebBuilder=14;
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = getCookie(request,"workarea",null); 
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  boolean bReferenced = false;
  
  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  
  PreparedStatement oStmt;
  ResultSet oRSet;  
  JDCConnection oCon = GlobalDBBind.getConnection("list_delete");
  DistributionList oList;
  
  try {
    oCon.setAutoCommit (false);
    
    for (int i=0;i<a_items.length;i++) {
      
      if (((iAppMask & (1<<WebBuilder))!=0) || ((iAppMask & (1<<Mailwire))!=0)) {
        oStmt = oCon.prepareStatement("SELECT NULL FROM " + DB.k_jobs + " WHERE " + DB.gu_workarea + "=? AND " + DB.id_status + " IN (?,?,?) AND " + DB.tx_parameters + " LIKE ?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	oStmt.setString(1, gu_workarea);
	oStmt.setShort(2, Job.STATUS_PENDING);
	oStmt.setShort(3, Job.STATUS_SUSPENDED);
	oStmt.setShort(4, Job.STATUS_RUNNING);
	oStmt.setString(5, "%gu_list:" + a_items[i] + "%");
	oRSet = oStmt.executeQuery();
	bReferenced = oRSet.next();
	oRSet.close();
	oStmt.close();

        if (bReferenced) {
    	  oList = new DistributionList(oCon, a_items[i]);
    	  
    	  oCon.commit();
    	  oCon.close("list_delete");
      	  response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=No es posible borrar la lista " + oList.getStringNull(DB.de_list,"") + " porque esta en uso por una tarea programada&resume=_back"));
          return;
        }
      }
      
      DistributionList.delete(oCon, a_items[i]);
      
      DBAudit.log(oCon, DistributionList.ClassId, "DLST", id_user, a_items[i], null, 0, 0, null, null);
    } // next ()
    oCon.commit();
    oCon.close("list_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"list_delete");
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
    
  oCon = null; 
%>
<HTML>
<HEAD>
<TITLE>Wait...</TITLE>
<SCRIPT TYPE='text/javascript'>
window.document.location='list_listing.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>';
</SCRIPT>
</HEAD>
</HTML>

