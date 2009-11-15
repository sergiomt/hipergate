<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  String id_user = getCookie (request, "userid", null);

  if (null==request.getParameter("checkeditems")) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalArgumentException&desc=At least one category to be deleted must be specified&resume=_close"));  
    return;
  }

  String id_parent = request.getParameter("id_parent_cat");
  String tr_parent = request.getParameter("tr_parent");
  String[] a_items = Gadgets.split(request.getParameter("checkeditems"), ',');

  int iUserPerms;
  Category oCatg;
  JDCConnection oCon = GlobalDBBind.getConnection("catedit_delete");
  oCon.setAutoCommit (false);
  
  try {
    for (int i=0;i<a_items.length;i++) {
      oCatg = new Category(a_items[i]);
      iUserPerms = oCatg.getUserPermissions(oCon, id_user);
      
      if ((iUserPerms&ACL.PERMISSION_DELETE)==0)
	throw new SQLException("Not enought priviledges to delete this category","01007", 1007);

      oCatg.delete(oCon);
      DBAudit.log(oCon, Category.ClassId, "DCAT", id_user, a_items[i], null, 0, 0, null, null);
    } // next ()
    oCon.commit();
    oCon.close("catedit_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"catedit_delete");
     oCon = null; 
     out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.open('../common/errmsg.jsp?title=Error&desc=" + e.getMessage() + "&resume=_close');</SCRIPT></HEAD><BODY onload=\"window.close()\"></BODY></HTML>");
    }
  
  if (null==oCon) return;
      
  oCon = null; 

  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>" + (id_parent!=null ? "window.opener.document.location.href='catprods.jsp?id_category="+id_parent+"&tr_category="+Gadgets.URLEncode("tr_parent")+"';" : "window.opener.document.location.href='catdipu3x.jsp';") + " window.close();<" + "/SCRIPT" +"></HEAD></HTML>");
%>