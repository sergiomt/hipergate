<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dfs.FileSystem,com.knowgate.hipergate.Category,com.knowgate.hipergate.ProductLocation" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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
      
  String id_user = getCookie (request, "userid", null);
  String gu_product = request.getParameter("gu_product");
  String id_location = request.getParameter("id_location");
  String gu_category = request.getParameter("gu_category");
  String xfile = request.getParameter("xfile");
  String name;
  
  ProductLocation oLoca = new ProductLocation();

  boolean bRenamed = false;
  PreparedStatement oStmt = null;
  JDCConnection oConn = null;
  FileSystem oFSys;
    
  try {
    oFSys = new FileSystem();
    
    oConn = GlobalDBBind.getConnection("docrename_store"); 
  
    Category oCatg = new Category(gu_category);
    int iACLMask = oCatg.getUserPermissions(oConn,id_user);
    
    if ((iACLMask&ACL.PERMISSION_MODIFY)==0) {
      throw new SecurityException("The Current User does not have rights to change the File Name");
    }

    oConn.setAutoCommit (false);
    
    if (oLoca.load(oConn, new Object[]{id_location})) {
      bRenamed = oLoca.rename(oConn, oFSys, xfile);
    }
    else {
      throw new SQLException("File not found", "02000", 2000);    
    }
          
    if (bRenamed) {
      int iDot = xfile.lastIndexOf(46);
      if (iDot>0)
        name = xfile.substring(0,iDot);
      else 
        name = xfile;
      
      oStmt = oConn.prepareStatement("UPDATE "+DB.k_products+" SET "+DB.nm_product+"=?"+" WHERE "+DB.gu_product+"=?");
      oStmt.setString(1, name);
      oStmt.setString(2, oLoca.getString(DB.gu_product));
      oStmt.executeUpdate();
      oStmt.close();
      oStmt=null;
      
      oConn.commit();
    }
    else
      if (!oConn.getAutoCommit()) oConn.rollback();
    
    oConn.close("docrename_store");
  }
  catch (Exception e) {
    if (oStmt!=null) { try {oStmt.close();} catch (Exception ignore) {} }   
    disposeConnection(oConn,"docrename_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Espere...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>