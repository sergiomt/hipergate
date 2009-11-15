<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" %>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_product = request.getParameter("id_product");
  String de_product = request.getParameter("de_product");
  String n_product = request.getParameter("n_product");
  String id_language = request.getParameter("id_language");
  String id_user = getCookie (request, "userid", null);
  
  JDCConnection oCon1;
  Product oProd;  
  ProductLocation oLoca = new ProductLocation();

  oCon1 = GlobalDBBind.getConnection("linkedit_store");
  oCon1.setAutoCommit (false);
   
  if (id_product.length()==0)
    {
    oProd = new Product();
    oProd.put(DB.gu_owner, id_user);
    oProd.put(DB.nm_product, n_product);
    oProd.put(DB.de_product, de_product);
    oProd.put(DB.id_status, 1); // { 0==Pending, 1=Active }
    
    if (id_language.length()>0) oProd.put(DB.id_language, id_language);  
    }
  else
    {
    oProd = new Product(oCon1, id_product);

    // Erase previous locations
    oProd.eraseLocations(oCon1);
    
    // Remove product from previous category
    oProd.removeFromCategory(oCon1, request.getParameter("id_previous_cat"));

    oProd.replace(DB.nm_product, n_product);
    oProd.replace(DB.de_product, de_product);
     
    if (id_language.length()>0)
      oProd.replace(DB.id_language, id_language);  
    else
      oProd.remove(DB.id_language);         
    }
  
  oProd.store(oCon1);

  oProd.addToCategory(oCon1, request.getParameter("id_category"), 0);

  oLoca.put(DB.gu_owner, id_user);
  oLoca.put(DB.gu_product, oProd.get(DB.gu_product));
  oLoca.put(DB.id_cont_type, 2);
  oLoca.put(DB.id_prod_type, "HTML");
  oLoca.put(DB.len_file, 0);    
  oLoca.setURL(request.getParameter("url"));      
  oLoca.store(oCon1);
  
  DBAudit.log (oCon1, Product.ClassId, "NPRO", id_user, oProd.getString(DB.gu_product), oLoca.getString(DB.gu_location), 0, getClientIP(request), n_product, request.getParameter("url"));

  oCon1.commit();
  
  oCon1.close("linkedit_store");

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">window.opener.location.reload();window.close();</SCRIPT></HEAD></HTML>");
%>
