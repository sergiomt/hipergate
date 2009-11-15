<%@ page import="java.util.Properties,java.math.BigDecimal,java.io.File,java.io.IOException,java.io.ByteArrayInputStream,java.io.ByteArrayOutputStream,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.projtrack.DutiesWorkReport,com.knowgate.misc.Environment,com.knowgate.dfs.FileSystem,com.knowgate.dataxslt.StylesheetCache" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="templates.jspf" %><%
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String sSep = File.separator;
  
  String sSkin = getCookie(request, "skin","xp");
  String sIdDomain = getCookie(request,"domainid","");
  String sGuWorkArea = getCookie(request,"workarea","");
  String sPathLogo = getCookie (request, "path_logo", "hglogopeq.jpg");
  if (sPathLogo.length()==0) sPathLogo = "hglogopeq.jpg";
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  String gu_workreport = request.getParameter("gu_workreport");

  JDCConnection oConn = null;  
  DutiesWorkReport oWrkR = null;

  try {
    oConn = GlobalDBBind.getConnection("workreport_print");    
    oWrkR = new DutiesWorkReport(oConn, gu_workreport);
    oWrkR.load(oConn, new Object[]{gu_workreport});
    oConn.close("workreport_print");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("workreport_print");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,"workreport_print");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;

  oConn = null;
  
  Properties oProps = new Properties();
  oProps.put("logo", "../skins/"+sSkin+"/"+sPathLogo);
  
  ByteArrayInputStream oByInStrm = null;
  
  try {
    oByInStrm = new ByteArrayInputStream(oWrkR.toXML().getBytes("UTF-8"));
  
    String sXslPath = getXSLTemplatePath(sStorage,sIdDomain,sGuWorkArea,oWrkR.getString(DB.gu_project),"workreport.xsl");
  
    if (sXslPath==null)
      throw new java.io.FileNotFoundException("Cannot find workreport.xsl template file at storage " + sStorage + " for WorkArea " + sGuWorkArea + " of Domain " + sIdDomain + " nor at " + sStorage+"xslt"+sSep+"templates"+sSep+"Projtrack"+sSep+"workreport.xsl");

    StylesheetCache.transform(sXslPath, oByInStrm, response.getOutputStream(), oProps);

    oByInStrm.close();
    
    //out.write(oWrkR.toXML());  
  }  catch (IllegalStateException ise) {
     out.write("IllegalStateException " + ise.getMessage());
  }
  if (true) return;
%>