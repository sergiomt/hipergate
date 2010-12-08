<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Category" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/reqload.jspf" %><%
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

  int id_domain = Integer.parseInt(getCookie (request, "domainid", "0"), 10);  
  short id_doc_status;

  if (nullif(request.getParameter("id_doc_status")).length()>0)
    id_doc_status = Short.parseShort(request.getParameter("id_doc_status"));
  else
    id_doc_status = 0;      
  String id_category = request.getParameter("id_category").length()==0 ? null : request.getParameter("id_category");
  String n_category = nullif(request.getParameter("n_category")).trim().toUpperCase();
  
  short is_active;
  if (nullif(request.getParameter("is_active")).length()>0)
    is_active = Short.parseShort(request.getParameter("is_active"));
  else
    is_active = (short) 0;    
  String id_parent_cat = request.getParameter("id_parent_cat");
  String id_parent_old = request.getParameter("id_parent_old");
  String nm_icon1 = request.getParameter("nm_icon1");
  String nm_icon2 = request.getParameter("nm_icon2");
  String id_user = getCookie (request, "userid", null);
  String names_subset = nullif(request.getParameter("names_subset"));
  
  if (names_subset.length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Missing Parameter&desc=Parameter names_subset for Category labels is empty or missing&resume=_back"));
    return;
  }
    
  String sCatg = "";
  ACLDomain oDom;
  JDCConnection oCon1 = null;
  Category oCatg;
  
  try {
    oCon1 = GlobalDBBind.getConnection("catedit_store");
    
    if (n_category.length()==0)
      n_category = Category.makeName(oCon1, request.getParameter("tr1st"));
      
    oCon1.setAutoCommit (false);
    
    if (id_category==null) {
      sCatg = Category.create (oCon1, new Object[]{ id_parent_cat, id_user, n_category, new Short(is_active), new Short(id_doc_status), nm_icon1, nm_icon2 });

      oCatg = new Category(sCatg);

      // Asignar permisos al usuario actual, los del administrador del dominio se asignan
      // automáticamente dentro del método newCategory()
      oDom = new ACLDomain(oCon1, id_domain);
                  
      oCatg.setGroupPermissions (oCon1, oDom.getString(DB.gu_admins), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
      oCatg.setUserPermissions (oCon1, oDom.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);

      if (!id_user.equals(oDom.getString(DB.gu_owner)))
        oCatg.setUserPermissions ( oCon1, id_user, ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_DELETE|ACL.PERMISSION_MODIFY|ACL.PERMISSION_GRANT, (short) 1, (short) 0);
    }
    else {

      oCatg = new Category(id_category);
      
      loadRequest(oCon1, request, oCatg);

      oCatg.replace(DB.nm_category, n_category);
	
      // Cambiar el padre (si procede)
      oCatg.resetParent(oCon1, id_parent_old);
      oCatg.setParent(oCon1, id_parent_cat);
    }
        
    oCatg.storeLabels(oCon1, names_subset, "¨", "`");
    
    oCon1.commit();
    oCon1.close("catedit_store");
    oCon1 = null;        
  }
  catch (SQLException d) {
	  disposeConnection(oCon1,"catedit_store");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + d.getMessage() + "&resume=_back"));    
    return;
  }
  catch (NullPointerException d) {
	  disposeConnection(oCon1,"catedit_store");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + d.getMessage() + "&resume=_back"));    
    return;
  }
  catch (java.util.NoSuchElementException d) {
	  disposeConnection(oCon1,"catedit_store");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NoSuchElementException&desc=" + names_subset + "&resume=_back"));    
    return;
  }
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>if (window.opener.document.location.href.indexOf('catdipu3x.jsp')>=0) window.opener.document.location='catdipu3x.jsp'; else window.opener.document.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");
%>