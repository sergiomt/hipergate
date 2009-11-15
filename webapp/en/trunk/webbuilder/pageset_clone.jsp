<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.dataxslt.db.PageSetDB,com.knowgate.hipermail.AdHocMailing" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  final int MailwireApp=13;
  final int WebBuilderApp=14;
  final int HipermailApp=21;
  final int SurveysApp=23;
  
  JDCConnection oConn = null;  
  PageSetDB oClon = new PageSetDB ();
  AdHocMailing oAdhm = new AdHocMailing();

  String sProtocol = GlobalDBBind.getProperty("fileprotocol", "file://");
  String sStorageRoot = GlobalDBBind.getPropertyPath("storage");
  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut + File.separator + "workareas/";
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;

  String gu_pageset = request.getParameter("gu_pageset");
  int id_app = Integer.parseInt(request.getParameter("id_app"));
  
  try {
    oConn = GlobalDBBind.getConnection("pageset_clone");
    
    oConn.setAutoCommit(false);
    
    if (id_app==HipermailApp) {
      oAdhm.clone(oConn, sProtocol, sWrkAPut, new AdHocMailing (oConn,gu_pageset));
    }
    else {
      oClon.clone(oConn, sProtocol, sStorageRoot, new PageSetDB (oConn,gu_pageset));
    }
    
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

  if (id_app==HipermailApp)
    response.sendRedirect (response.encodeRedirectUrl ("pageset_listing.jsp?doctype="+request.getParameter("doctype")+"&find="+Gadgets.URLEncode(oAdhm.getString(DB.nm_mailing))+"&selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
  else
    response.sendRedirect (response.encodeRedirectUrl ("pageset_listing.jsp?doctype="+request.getParameter("doctype")+"&find="+Gadgets.URLEncode(oClon.getString(DB.nm_pageset))+"&selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
%>