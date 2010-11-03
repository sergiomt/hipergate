<%@ page import="java.io.File,java.io.FileNotFoundException,java.io.IOException,java.net.URL,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  JDCConnection oConn = null;  
    
  try {

    oConn = GlobalDBBind.getConnection("adhoc_mailing_preview");
		Integer iPgMailing = DBCommand.queryInt(oConn, "SELECT "+DB.pg_mailing+" FROM "+DB.k_adhoc_mailings+" WHERE "+DB.gu_mailing+"='"+request.getParameter("gu_mailing")+"'");
    if (null==iPgMailing) throw new SQLException("Ad-hoc mailing "+request.getParameter("gu_mailing")+" not found at k_adhoc_mailings table");
    oConn.close("adhoc_mailing_preview");
    oConn=null;

    String sDefWrkArPut = request.getRealPath(request.getServletPath());
    sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
    sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
    sDefWrkArPut = sDefWrkArPut + File.separator + "workareas/";
    String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	  if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;
	  sWrkAPut += request.getParameter("gu_workarea") + File.separator;

		File oHtmlDir = new File(sWrkAPut+"apps"+File.separator+"Hipermail"+File.separator+"html"+File.separator+Gadgets.leftPad(String.valueOf(iPgMailing),'0',5));
		if (!oHtmlDir.exists()) {
		  throw new FileNotFoundException(sWrkAPut+"apps"+File.separator+"Hipermail"+File.separator+"html"+File.separator+Gadgets.leftPad(String.valueOf(iPgMailing),'0',5));
	  } else {
	  	String sHtmlFile = null;
      String[] aFiles = oHtmlDir.list();
      if (null==aFiles) {
        throw new FileNotFoundException("No files found at "+sWrkAPut+"apps"+File.separator+"Hipermail"+File.separator+"html"+File.separator+Gadgets.leftPad(String.valueOf(iPgMailing),'0',5));
			} else {
        for (int f=0; f<aFiles.length && sHtmlFile==null; f++) {
          if (aFiles[f].endsWith(".htm") || aFiles[f].endsWith(".html") || aFiles[f].endsWith(".HTM") || aFiles[f].endsWith(".HTML")) {
            sHtmlFile = aFiles[f];
          }
        } // next
        if (null==sHtmlFile) {
          throw new FileNotFoundException("No valid HTML file found at "+sWrkAPut+"apps"+File.separator+"Hipermail"+File.separator+"html"+File.separator+Gadgets.leftPad(String.valueOf(iPgMailing),'0',5));        
        } else {
          URL oWebSrv = new URL(GlobalDBBind.getProperty("webserver"));
					response.sendRedirect (response.encodeRedirectUrl (oWebSrv.getProtocol()+"://"+oWebSrv.getHost()+(oWebSrv.getPort()==-1 ? "" : ":"+String.valueOf(oWebSrv.getPort()))+Gadgets.chomp(GlobalDBBind.getProperty("workareasget"),"/")+request.getParameter("gu_workarea")+"/apps/Hipermail/html/"+Gadgets.leftPad(String.valueOf(iPgMailing),'0',5)+"/"+sHtmlFile));
        }
			}
    }    
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("adhoc_mailing_preview");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_topclose"));
  }
%>