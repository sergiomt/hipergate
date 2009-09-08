<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.dataxslt.db.PageSetDB" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  JDCConnection oConn = null;  
  PageSetDB oClon = new PageSetDB ();

  String sProtocol = GlobalDBBind.getProperty("fileprotocol", "file://");
  String sStorageRoot = GlobalDBBind.getPropertyPath("storage");

  String gu_pageset = request.getParameter("gu_pageset");
  
  try {
    oConn = GlobalDBBind.getConnection("pageset_clone");
    
    oConn.setAutoCommit(false);
    
    oClon.clone(oConn, sProtocol, sStorageRoot, new PageSetDB (oConn,gu_pageset));
    
    oConn.commit();
      
    oConn.close("pageset_clone");
  }
  catch (Exception e) {
    disposeConnection(oConn,"pageset_clone");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

    response.sendRedirect (response.encodeRedirectUrl ("pageset_listing.jsp?doctype="+request.getParameter("doctype")+"&find="+Gadgets.URLEncode(oClon.getString(DB.nm_pageset))+"&selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
%>