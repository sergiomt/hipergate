<%@ page import="com.knowgate.dataxslt.db.PageSetDB,com.knowgate.dataxslt.db.PageDB,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/reqload.jspf" %><%
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
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_page = request.getParameter("gu_page");
  String path_publish = request.getParameter("path_publish");
  String id_user = getCookie (request, "userid", null);
  
  String gu_pageset = request.getParameter("gu_pageset");

  String sOpCode = "MPGS";
    
  JDCConnection oConn = GlobalDBBind.getConnection("pageset_change_store");  
  
  PageSetDB oPgDb = new PageSetDB();
  PageDB oPage;
  
  try {
    loadRequest(oConn, request, oPgDb);

    oConn.setAutoCommit (false);
    
    oPgDb.store(oConn);

    DBAudit.log(oConn, PageSetDB.ClassId, sOpCode, id_user, oPgDb.getString(DB.gu_pageset), null, 0, 0, oPgDb.getString(DB.nm_pageset), null);

		if (path_publish!=null && gu_page.length()>0) {
		  oPage = new PageDB();
		  if (oPage.load(oConn, new Object[]{gu_page})) {
		    oPage.replace(DB.path_publish, path_publish);
		    oPage.store(oConn);
        DBAudit.log(oConn, PageDB.ClassId, "MSPG", id_user, DB.gu_page, null, 0, 0, path_publish, null);
		  } // fi
		} else {
			PageDB[] aPages = oPgDb.getPages(oConn);
      if (null!=aPages) {
        for (int p=0; p<aPages.length; p++) {
          oPage = aPages[p];
		      oPage.replace(DB.path_publish, request.getParameter("path_publish_"+String.valueOf(oPage.getInt(DB.pg_page))));
		      oPage.store(oConn);
          DBAudit.log(oConn, PageDB.ClassId, "MSPG", id_user, DB.gu_page, null, 0, 0, oPage.getStringNull(DB.path_publish,""), null);
        } // next		  
		  } // fi (aPages)
		} // fi (path_publish!=null && gu_page!="")
    
    oConn.commit();
    oConn.close("pageset_change_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"pageset_change_store");

    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); ");
  if (nullif(request.getParameter("bo_edit")).equals("1")) {
	  out.write ("window.moveTo(8,8); ");
	  out.write ("window.resizeTo(screen.width-24,screen.height-80); ");
    out.write ("document.documentElement.style.overflow = \"auto\"; ");
	  out.write ("document.location = \"wb_document.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_pageset="+gu_pageset+"&doctype=newsletter\"; ");
  } else if (nullif(request.getParameter("bo_send")).equals("1")) {
    out.write ("document.location = \"list_choose.jsp?gu_pageset="+gu_pageset+"&id_command=MAIL\"; ");
  } else {
    out.write ("self.close();");
  }
  out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");

%>
<%@ include file="../methods/page_epilog.jspf" %>