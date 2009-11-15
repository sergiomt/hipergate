<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.projtrack.Project" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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

  JDCConnection oConn = null;  
  Project oProj = new Project();
      
  try {
    oConn = GlobalDBBind.getConnection("prj_reexpand");
        
    DBSubset oPrjList = new DBSubset(DB.k_projects, DB.gu_project, DB.gu_owner+"=? AND "+DB.id_parent+" IS NULL", 100);
    int iPrjList = oPrjList.load(oConn, new Object[]{getCookie(request,"workarea","")});

    oConn.setAutoCommit(false);

    for (int p=0; p<iPrjList; p++) {
      oProj.replace(DB.gu_project, oPrjList.getString(0,p));
      oProj.expand(oConn);
      oConn.commit();
    }

    oConn.close("prj_reexpand");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"prj_reexpand");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }

  if (null==oConn) return;
    
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("project_listing.jsp?selected="+nullif(request.getParameter("selected"),"4")+"&subselected="+nullif(request.getParameter("subselected"),"0")));
%>