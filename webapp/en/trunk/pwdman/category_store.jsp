<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Category" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  int id_domain = Integer.parseInt(getCookie (request, "domainid", "0"), 10);  
  short id_doc_status = (short) 0;
  short is_active = (short) 1;

  String id_category = null;
  String n_category  = null;
  
  String id_parent_cat = request.getParameter("id_parent_cat");
  String nm_icon1 = nullif(request.getParameter("nm_icon1"),"folderclosed_16x16.gif");
  String nm_icon2 = nullif(request.getParameter("nm_icon2"),"folderopen_16x16.gif");
  String id_user = getCookie (request, "userid", null);
      
  String sCatg = "";
  ACLDomain oDom;
  JDCConnection oCon1 = null;
  Category oCatg;
  
  try {
    oCon1 = GlobalDBBind.getConnection("catedit_store");
    
    n_category = Category.makeName(oCon1, request.getParameter("tr1st"));
      
    oCon1.setAutoCommit (false);
    
    sCatg = Category.create (oCon1, new Object[]{ id_parent_cat, id_user, n_category, new Short(is_active), new Short(id_doc_status), nm_icon1, nm_icon2 });

    oCatg = new Category(sCatg);

    // Asignar permisos al usuario actual, los del administrador del dominio se asignan
    // automáticamente dentro del método newCategory()
    oDom = new ACLDomain(oCon1, id_domain);
                  
    oCatg.setUserPermissions (oCon1, oDom.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);

    if (!id_user.equals(oDom.getString(DB.gu_owner)))
      oCatg.setUserPermissions ( oCon1, id_user, ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_DELETE|ACL.PERMISSION_MODIFY|ACL.PERMISSION_GRANT, (short) 1, (short) 0);
        
    oCatg.setLabel(oCon1, request.getParameter("tr1st"));
    
    oCon1.commit();
    oCon1.close("catedit_store");
    oCon1 = null;        
  }
  catch (Exception d) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        if (!oCon1.getAutoCommit()) oCon1.rollback();
        oCon1.close("catedit_store");
        oCon1 = null;
      }
    out.write ("ERROR "+d.getClass().getName()+" "+d.getMessage());    
    return;
  }
  out.write (sCatg+" "+request.getParameter("tr1st"));
%>