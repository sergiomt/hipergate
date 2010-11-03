<%@ page import="java.net.MalformedURLException,java.util.HashMap,org.xml.sax.SAXParseException,org.w3c.dom.DOMException,com.knowgate.debug.DebugFile,com.knowgate.debug.StackTraceUtil,java.util.Vector,java.io.BufferedOutputStream,java.io.OutputStreamWriter,java.io.FileOutputStream,java.io.FileNotFoundException,java.io.IOException,java.io.File,java.util.Properties,java.net.URLDecoder,java.sql.Statement,java.sql.ResultSet,java.sql.ResultSetMetaData,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBAudit,com.knowgate.dfs.FileSystem,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.acl.*,com.knowgate.dataxslt.*,com.knowgate.dataxslt.db.*,javax.xml.transform.Transformer,javax.xml.transform.OutputKeys,javax.xml.transform.TransformerException,javax.xml.transform.TransformerConfigurationException" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%!

  static String back (String sPath) {
    String sRetVal;

    if (System.getProperty("file.separator").equals("/")) {
      sRetVal = "";
      for (int p=0; p<sPath.length(); p++)
        if (sPath.charAt(p)=='\\')
          sRetVal += "/";
        else
          sRetVal += sPath.charAt(p);
    }
    else {
      sRetVal = "";
      for (int p=0; p<sPath.length(); p++)
        if (sPath.charAt(p)=='/')
          sRetVal += "\\";
        else
          sRetVal += sPath.charAt(p);
    }      
    return sRetVal;
  }
%><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String sSep = System.getProperty("file.separator");
  
  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = nullif(request.getParameter("gu_pageset"));
  String sDocType = request.getParameter("doctype");
  String sPage = nullif(request.getParameter("page"));
  String sPageId = request.getParameter("gu_page");
  String sMedia;
  String sTitle_;
  Page oPage = null;
  Transformer oTransformer;
  FileSystem oFS = new FileSystem();
  
  String sAppDir, sIntegrador;
  
  if (sDocType.equals("newsletter")) {
    sAppDir = "Mailwire";
    sIntegrador = "/includes/integrador_ctrl.inc";
  }
  else {
    sAppDir = "WebBuilder";
    sIntegrador = "/includes/integrador_ctrl_web.inc";
  } 
  
  Properties UserProperties = new Properties();      
  UserProperties.put("domain",   id_domain);
  UserProperties.put("workarea", gu_workarea);
  UserProperties.put("pageset",  gu_pageset);
    
  // Rutas y parámetros
  
  String sDefWrkArGet = request.getRequestURI();
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet + "/workareas";

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sWebRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver");
  
  if (null==sWebRoot) {
    sWebRoot = request.getRequestURI();
    sWebRoot = sWebRoot.substring(0,sWebRoot.lastIndexOf("/"));
    sWebRoot = sWebRoot.substring(0,sWebRoot.lastIndexOf("/"));
  }
  
  sWebRoot = com.knowgate.misc.Gadgets.dechomp (sWebRoot, "/");
  
  String sURLRoot = request.getRealPath(request.getServletPath());
         sURLRoot = sURLRoot.substring(0,sURLRoot.lastIndexOf(sSep)) + "/../";

  String sStorageRoot = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sEnvWorkGet	= Environment.getProfileVar(GlobalDBBind.getProfileName() , "workareasget", sDefWrkArGet);
  String sEnvWorkPut	= Environment.getProfileVar(GlobalDBBind.getProfileName() , "workareasput", sDefWrkArPut);
 
  String sMenuPath = sWebRoot + "/webbuilder/wb_mnuintegrador.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_pageset=" + gu_pageset + "&doctype=" + sDocType + "&page=" + sPage;
  String sOutputPathEdit = sEnvWorkPut + sSep + gu_workarea + sSep + "apps" + sSep + sAppDir + sSep + "html" + sSep + gu_pageset + sSep;
  String sURLEdit = sEnvWorkGet + "/" + gu_workarea + "/apps/" + sAppDir + "/html/" + gu_pageset + "/";
  String sIntegradorPath = sWebRoot + "/javascript/integrador.js";

  String sFilePageSet=null, sFileTemplate=null, sCompanyGUID=null, sParamName=null, sParamsQry=null, sSQL=null, sQueryString="?offset=0&limit=1000";

  JDCConnection oConn = null;
  PageSetDB oPageSetDB = null;
  
  try {

    oConn = GlobalDBBind.getConnection("wb_document");
    
    oPageSetDB = new PageSetDB(oConn, gu_pageset);

    sFilePageSet = sStorageRoot + back(oPageSetDB.getString(DB.path_data));
    sFileTemplate = sStorageRoot + back(oPageSetDB.getString(DB.path_metadata));

    sCompanyGUID = oPageSetDB.getStringNull(DB.gu_company, null);

    if (sCompanyGUID!=null)
      PageSet.mergeCompanyInfo (oConn, sFilePageSet, sCompanyGUID);
  
    oConn.close("wb_document");

  }
  catch (SQLException sqle) {
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("wb_document");
    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: SQLException " + sqle.getMessage());
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", sqle.getMessage());
    }
        
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_close"));       
  }

  if (null==oConn) return;  
  oConn = null;  
  
  File oFileDir;
  
  if (DebugFile.trace) DebugFile.writeln("<JSP: new File (" + sOutputPathEdit + ");>");
  
  oFileDir = new File (sOutputPathEdit);
  if (!oFileDir.exists()) oFileDir.mkdirs();

  oFileDir = null;
  
  PageSet oPageSet = null;
  
  try {
    if (DebugFile.trace)
      DebugFile.writeln("<JSP: new PageSet (" + sFileTemplate + "," + sFilePageSet + ",...);>");
    
    oPageSet = new PageSet (sFileTemplate, sFilePageSet, true);
  }
  catch (FileNotFoundException fnfe) {
    oPageSet = null;

    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: FileNotFoundException " + fnfe.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "FileNotFoundException", fnfe.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=PageSet FileNotFoundException&desc=" + fnfe.getMessage() + "<BR>" + sFileTemplate + "<BR>" + sFilePageSet + "&resume=_close")); 
  }
  catch (ClassNotFoundException cnfe) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: ClassNotFoundException " + cnfe.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "ClassNotFoundException" , cnfe.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=PageSet ClassNotFoundException&desc=" + cnfe.getMessage() + "<BR>" + sFileTemplate + "<BR>" + sFilePageSet + "&resume=_close")); 
  }
  catch (IllegalAccessException iae) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: IllegalAccessException " + iae.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IllegalAccessException", iae.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=PageSet IllegalAccessException&desc=" + iae.getMessage() + "<BR>" + sFileTemplate + "<BR>" + sFilePageSet + "&resume=_close")); 
  }
  catch (SAXParseException spe) {
    oPageSet = null;
    String sTrace = StackTraceUtil.getStackTrace(spe);
    if (null==sTrace)
      sTrace = "";
    else
      sTrace = Gadgets.split(sTrace,'\n')[0];
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: SAXParseException " + spe.getMessage() + " " + sTrace);
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SAXParseException", spe.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SAXParseException&desc=" + spe.getClass().getName() + "<BR>" + sFileTemplate + "<BR>" + sFilePageSet +"<BR>" + sTrace + "&resume=_close")); 
  }  
  /*
  catch (Exception xcpt) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: Exception " + xcpt.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "Exception", xcpt.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=PageSet Exception&desc=" + xcpt.getClass().getName() + "<BR>" + sFileTemplate + "<BR>" + sFilePageSet + "&resume=_close")); 
  }
  */
  if (null==oPageSet) return;

  if (DebugFile.trace) DebugFile.writeln("<JSP: Vector vPages = oPageSet.pages();>");

  Vector vPages = oPageSet.pages();
  oPage = (Page) vPages.elementAt(0);
  
  if (null==sPageId) sPageId = oPage.guid();
      
  String sPageTitle, sPageGUID, sSelPageOptions = "";
  
  try {

    Properties EnvironmentProperties = Environment.getProfile(GlobalDBBind.getProfileName());
    
    if (null==EnvironmentProperties.getProperty("imageserver")) {
      String sDefImgSrv = request.getRequestURI();
      sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
      sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/")) + "/images";
      
      EnvironmentProperties.setProperty("imageserver", sDefImgSrv);
    }
       
    if (DebugFile.trace) {
      DebugFile.writeln("imageserver=" + EnvironmentProperties.getProperty("imageserver"));
      DebugFile.writeln("<JSP: PageSet.buildPageForEdit(" + sPageId + "," + sStorageRoot + "," + sOutputPathEdit + "," + sURLRoot + sIntegrador + "," + sMenuPath + "," + sIntegradorPath + "," + sSelPageOptions + ", ...);>" );
    }
        
    if (sDocType.equals("newsletter")) {

      oPage = oPageSet.buildPageForEdit(sPageId, sStorageRoot, sOutputPathEdit,
    			                              sURLRoot + sIntegrador, sMenuPath,
    			                              sIntegradorPath, sSelPageOptions, EnvironmentProperties, UserProperties);
      
      oConn = GlobalDBBind.getConnection("wb_document_newsletter");
      oPageSetDB.setPage(oConn, sPageId, 1, oPage.getTitle(), oPage.filePath());
      oConn.close("wb_document_newsletter");
      
    } else {
      int iSize = vPages.size();

      oConn = GlobalDBBind.getConnection("wb_document_page");

      for (int p=0; p<iSize; p++) {        
        oPage = (Page) vPages.elementAt(p);        
        sPageGUID  = oPage.guid();
        sPageTitle = oPage.getTitle();
        sSelPageOptions += "<option value=\"" + sPageGUID + "\"" + (sPageId.equals(sPageGUID) ? " selected" : "") + ">" + sPageTitle;             
      } // next    
      for (int p=0; p<iSize; p++) {        
        oPage = (Page) vPages.elementAt(p);        
        sPageGUID  = oPage.guid();
        sPageTitle = oPage.getTitle();
        oPage = oPageSet.buildPageForEdit(sPageGUID, sStorageRoot, sOutputPathEdit,
    			                                sURLRoot + sIntegrador, sMenuPath,
    			                                sIntegradorPath, sSelPageOptions, EnvironmentProperties, UserProperties);
        oPageSetDB.setPage(oConn, sPageGUID, p+1, sPageTitle, oPage.filePath());
      } // next    

      oConn.close("wb_document_page");
    } // fi (sDocType=="newsletter")  
  }
  catch (MalformedURLException badurl) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: MalformedURLException " + badurl.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "MalformedURLException", badurl.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MalformedURLException&desc=" + badurl.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathEdit + "&resume=_close"));
  }
  catch (DOMException dome) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: DOMException " + dome.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "DOMException", dome.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DOMException&desc=" + dome.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathEdit + "&resume=_close"));
  }
  catch (FileNotFoundException fnf) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: FileNotFoundException " + fnf.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "FileNotFoundException", fnf.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + fnf.getMessage() + "<BR><B>storage</B>:" + sStorageRoot + "<BR><B>outputpath</B>:" + sOutputPathEdit + "&resume=_close")); 
  }
  catch (IOException ioe) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: IOException " + ioe.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", ioe.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + ioe.getMessage() + "<BR><B>storage</B>:" + sStorageRoot + "<BR><B>outputpath</B>:" + sOutputPathEdit + "&resume=_close")); 
  }
  catch (TransformerConfigurationException tcxc) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: TransformerConfigurationException " + tcxc.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "TransformerConfigurationException", tcxc.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=TransformerConfigurationException&desc=" + tcxc.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathEdit + "&resume=_close")); 
  }
  catch (TransformerException texc) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: TransformerException " + texc.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "TransformerException", texc.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=TransformerException&desc=" + texc.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathEdit + "&resume=_close")); 
  }
  catch (NullPointerException npex) {
    oPageSet = null;
    if (DebugFile.trace) {
      DebugFile.writeln("<wb_document.jsp: NullPointerException " + npex.getMessage());
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NullPointerException", npex.getMessage());
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + npex.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathEdit + "&resume=_close"));
  }

  if (null==oPageSet) return;
      
  // Redirección a la página renderizada
  if (sPage.length()==0) {

    oTransformer = StylesheetCache.newTransformer(sStorageRoot + "xslt" + File.separator + "templates" + File.separator + oPageSet.microsite().name() + File.separator + oPage.template());

    sMedia = oTransformer.getOutputProperty(OutputKeys.MEDIA_TYPE);    
    if (null==sMedia)
      sMedia = "html";
    else
      sMedia = sMedia.substring(sMedia.indexOf('/')+1);

		sTitle_ = ((Page) vPages.elementAt(0)).getTitle().replace(' ', '_');
		
    if (DebugFile.trace) {
      DebugFile.writeln("<JSP: response.encodeRedirectUrl (" + sURLEdit + sTitle_ + "_." + sMedia + ");>");
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "", "");
    }

    if (!oFS.exists(request.getScheme()+"://"+request.getServerName()+":"+String.valueOf(request.getServerPort()) + sURLEdit + sTitle_ + "_." + sMedia)) {
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=UrlNotFoundException&desc="+Gadgets.URLEncode(request.getScheme()+"://"+request.getServerName()+":"+String.valueOf(request.getServerPort()) + sURLEdit + sTitle_ + "_." + sMedia)+"<BR/>Template could not be opened please check the value of workareasget at hipergate.cnf&resume=_close"));
    } else {
      response.sendRedirect (response.encodeRedirectUrl (sURLEdit + sTitle_ + "_." + sMedia));  
    }
  }
  else {

    oTransformer = StylesheetCache.newTransformer(sStorageRoot + "xslt" + File.separator + "templates" + File.separator + oPageSet.microsite().name() + File.separator + oPage.template());

    sMedia = oTransformer.getOutputProperty(OutputKeys.MEDIA_TYPE);    
    if (null==sMedia)
      sMedia = "html";
    else
      sMedia = sMedia.substring(sMedia.indexOf('/')+1);

    sTitle_ = sPage.replace(' ', '_');

    sParamsQry = oPage.getContainer().parameters();

    if (DebugFile.trace) DebugFile.writeln("parameters query = " + sParamsQry);
        
    if (sParamsQry!=null) {

      sSQL = Gadgets.replace(sParamsQry, "{#catalog}", oPageSet.catalog());

      StringBuffer oParamBuffer = new StringBuffer(2048);
      Statement oStmt = null;
      ResultSet oRSet = null;
      ResultSetMetaData oMDat;
      
      try {

        oConn = GlobalDBBind.getConnection("wb_document_ctrl");

    	  oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    	  oRSet = oStmt.executeQuery(sSQL);
    	  oMDat = oRSet.getMetaData();
    	
    	  sParamName = oMDat.getColumnName(1);
    	
    	  int p = 0;
    	
    	  while (oRSet.next()) {
    	    if (0==p) oParamBuffer.append("<SELECT NAME=\"" + sParamName + "\" onchange=\"goPageN('" + sParamName + "',this.options[this.selectedIndex].value)\">");

    	    oParamBuffer.append("<OPTION VALUE=\"" + oRSet.getString(1) + "\"");
    	  
    	    if (oRSet.getString(1).equals(request.getParameter(sParamName))) oParamBuffer.append(" SELECTED");
    	  
    	    oParamBuffer.append(">Page " + String.valueOf(++p) + "</OPTION>");
    	  } // wend

	      if (0!=p) {
	        oParamBuffer.append("</SELECT>");
	      }
	
	      oRSet.close();
	      oStmt.close();
	
        oConn.close("wb_document_ctrl");
      }
      catch (SQLException sqle) {
        if (oRSet!=null) oRSet.close();
        if (oStmt!=null) oStmt.close();
        if (oConn!=null)
          if (!oConn.isClosed()) oConn.close("wb_document_ctrl");
        if (DebugFile.trace) {
          DebugFile.writeln("<wb_document.jsp: SQLException " + sqle.getMessage());
        } // fi
      } // catch

      if (oParamBuffer.length()>0) {
        String sHTML = oFS.readfilestr (sOutputPathEdit + sTitle_ + "_." + sMedia, "UTF-8");
        int iNav = sHTML.indexOf("<!--navigation-->");
        
        FileOutputStream oOutStrm = new FileOutputStream (sOutputPathEdit + sTitle_ + "_." + sMedia);
        BufferedOutputStream oBFStrm = new BufferedOutputStream(oOutStrm, sHTML.length()+2048);
        OutputStreamWriter oWriter = new OutputStreamWriter(oBFStrm, "UTF-8");
        oWriter.write(sHTML.substring(0,iNav));
        oWriter.write(oParamBuffer.toString());
        oWriter.write(sHTML.substring(iNav+17));
        oWriter.close();
        oBFStrm.close();
        oOutStrm.close();       
      }
    } // fi (oPageSet.parameters())
    
    if (com.knowgate.debug.DebugFile.trace) {
      DebugFile.writeln("<JSP: response.encodeRedirectUrl (" + sURLEdit + sTitle_ + "_." + sMedia + sQueryString + ");>");
      DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "", "");
    }

    if (!oFS.exists(request.getScheme()+"://"+request.getServerName()+":"+String.valueOf(request.getServerPort()) + sURLEdit + sTitle_ + "_." + sMedia + sQueryString)) {
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=UrlNotFoundException&desc="+Gadgets.URLEncode(request.getScheme()+"://"+request.getServerName()+":"+String.valueOf(request.getServerPort()) + sURLEdit + sPage + "_." + sMedia + sQueryString)+"<BR/>Template could not be opened please check the value of workareasget at hipergate.cnf&resume=_close"));
    } else {
      response.sendRedirect (response.encodeRedirectUrl (sURLEdit + sTitle_ + "_." + sMedia + sQueryString));
    }
  }
%>
