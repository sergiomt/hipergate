<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  String id_category = request.getParameter("id_category");
  int iChkCount = Integer.parseInt(request.getParameter("chkcount"));
  String id_user = getCookie (request, "userid", null);
  
  JDCConnection oCon1 = null;
  String sProductId;
  Category oCatg = new Category(id_category);
  Product oProd = new Product();
  int iACLMask;

  oCon1 = GlobalDBBind.getConnection("catprods_delete");
    
  try {
    oCon1.setAutoCommit (false);
    
    iACLMask = oCatg.getUserPermissions(oCon1,id_user);
    
    if ((iACLMask&ACL.PERMISSION_DELETE)==0) {
      out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.parent.catadmin.location.href='../common/errmsg.jsp?title=' + escape('Security restriction') + '&desc=' + escape('No esta autorizado para borrar elementos de esta categoria') + '&resume=_back';</SCRIPT></HEAD></HTML>");
    }
    else {        

      for (int c=0; c<iChkCount; c++) {
        sProductId = nullif(request.getParameter("chkbox" + String.valueOf(c)));
        if (sProductId.length()>0) {
          oProd.replace(DB.gu_product, sProductId);
          oProd.delete(oCon1);
          DBAudit.log (oCon1, Product.ClassId, "DPRO", id_user, oProd.getString(DB.gu_product), null, 0, getClientIP(request), null, null);
          oCon1.commit();
        } // fi (sProductId)
      } // next (c)   
    } // fi (ACL.PERMISSION_DELETE)

    oCon1.close("catprods_delete");
    oCon1 = null;

    oProd = null;
    oCatg = null;
  
    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.parent.catadmin.location.reload();</SCRIPT></HEAD></HTML>");
  }  
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
	oCon1.rollback();
	oCon1.close();
        oCon1 = null;
      }
    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.parent.catadmin.location.href='../common/errmsg.jsp?title=Error&desc=' + escape('" + e.getMessage() + "') + '&resume=_back';</SCRIPT></HEAD></HTML>");
  }         
  catch (IOException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
	oCon1.rollback();
	oCon1.close();
        oCon1 = null;
      }
    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.parent.catadmin.location.href='../common/errmsg.jsp?title=Error&desc=' + escape('" + e.getMessage() + "') + '&resume=_back';</SCRIPT></HEAD></HTML>");
  }         
%>
