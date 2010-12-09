<%@ page import="java.io.IOException,java.io.File,java.net.URL,java.net.URLDecoder,java.util.zip.ZipException,java.util.zip.ZipOutputStream,java.util.zip.ZipEntry,com.knowgate.dfs.FileSystem,com.knowgate.dfs.StreamPipe,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.dataxslt.db.PageSetDB,com.knowgate.hipermail.AdHocMailing,com.knowgate.misc.Gadgets" language="java" session="false" contentType="application/zip" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%

  final String gu_pageset = request.getParameter("gu_pageset");

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut + File.separator + "workareas/";
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;
  String sWrkAGet = GlobalDBBind.getProperty("workareasget");
  URL oWebSrvr = new URL(GlobalDBBind.getProperty("webserver"));
	String sWebSrvr = oWebSrvr.getProtocol()+oWebSrvr.getHost()+(oWebSrvr.getPort()==-1 ? "" : ":"+String.valueOf(oWebSrvr.getPort()))+"/";
  String sBasePath;
	  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("wb_zipfile_download");          
	  	  
    if (request.getParameter("gu_microsite").equals("adhoc")) {

      AdHocMailing oAdhm = new AdHocMailing();
			oAdhm.load(oConn, new Object[]{gu_pageset});

      sBasePath = sWrkAPut + oAdhm.getString(DB.gu_workarea) + File.separator + "apps" + File.separator + "Hipermail" + File.separator + "html" + File.separator + Gadgets.leftPad(String.valueOf(oAdhm.getInt(DB.pg_mailing)), '0', 5);    
      oConn.close("wb_zipfile_download");

      response.setHeader("Content-Disposition","attachment; filename=\"" + oAdhm.getString(DB.nm_mailing) + ".zip\"");

		  String[] lst = new File (sBasePath).list();

		  if (lst==null)
		    throw new ZipException("There is no file to be downloaded");
		  else if (lst.length==0)
		    throw new ZipException("There is no file to be downloaded");

      ZipOutputStream zos = new ZipOutputStream(response.getOutputStream());
    
      if (null!=lst) {
        StreamPipe spp = new StreamPipe();
        for (int f=0; f<lst.length; f++) {
          zos.putNextEntry(new ZipEntry(lst[f]));
    		  StreamPipe.between(Gadgets.chomp(sBasePath,File.separator)+lst[f], zos);
          zos.closeEntry();
        } // next
      }
      zos.close();

    } else {

      PageSetDB oPgDb = new PageSetDB(oConn, gu_pageset);
      String sFileName = oPgDb.getFirstPage(oConn).getPage(oConn, GlobalDBBind.getPropertyPath("storage")).getTitle().replace(' ', '_') + ".html";
      Integer iApp = DBCommand.queryInt(oConn, "SELECT "+DB.id_app+" FROM "+DB.k_microsites+" WHERE "+DB.gu_microsite+"='"+oPgDb.getString(DB.gu_microsite)+"'");
      sBasePath = sWrkAPut + oPgDb.getString(DB.gu_workarea) + File.separator + "apps" + File.separator + (iApp.intValue()==13 ? "Mailwire" : "WebBuilder") + File.separator + "html" + File.separator + gu_pageset + File.separator;
      oConn.close("wb_zipfile_download");

      response.setHeader("Content-Disposition","attachment; filename=\"" + sFileName.substring(0,sFileName.lastIndexOf(".")) + ".zip\"");

      FileSystem oFs = new FileSystem();
      oFs.downloadhtmlpage(sBasePath, sFileName, response.getOutputStream());
      //oFs.downloadhtmlpage("http://localhost/", Gadgets.chomp(sWrkAGet,"/") + oPgDb.getString(DB.gu_workarea) + "/apps/" + (iApp.intValue()==13 ? "Mailwire" : "WebBuilder") + "/html/" + gu_pageset + "/" + sFileName, response.getOutputStream());
    }

  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("wb_zipfile_download");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (true) return;
%>