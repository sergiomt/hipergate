<%@ page import="java.io.File,java.util.Enumeration,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.dfs.FileSystem,com.knowgate.dataxslt.db.MicrositeDB" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<% 
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  final String sSep = java.io.File.separator;
  final String sProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  final String sFileSrvr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  final String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  final String sTemplates = sStorage + "xslt" + sSep + "templates" + sSep;
  final String sThumbPath = Gadgets.chomp(request.getRealPath("/images"), sSep)+"styles"+sSep+"thumbnails"+sSep;
    
  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = Gadgets.chomp(sTmpDir,java.io.File.separator);  
  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, "UTF-8");

  String gu_workarea  = oReq.getParameter("gu_workarea");
  String gu_microsite = oReq.getParameter("gu_microsite");
  String nm_microsite = oReq.getParameter("nm_microsite");
  
  FileSystem oFS = new FileSystem(Environment.getProfile(GlobalDBBind.getProfileName()));
 
  if (sProtocol.equals("file://"))
    oFS.mkdirs(sTemplates+sSep+nm_microsite);
  else
    oFS.mkdirs(sProtocol+sSep+sFileSrvr+sTemplates+sSep+nm_microsite);
 
  File oFl;
  Enumeration oFileNames = oReq.getFileNames();  

  String sDefFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
  if (null!=sDefFile) {
    if (sProtocol.equals("file://")) {
      oFl = new File(sTemplates+nm_microsite+sSep+nm_microsite+".xml");
      if (oFl.exists()) oFl.delete();
      oFS.move("file://"+sTmpDir+sDefFile, "file://"+sTemplates+nm_microsite+sSep+nm_microsite+".xml");
    } else {
      oFS.delete(sProtocol+sFileSrvr+sSep+sTemplates+nm_microsite+sSep+nm_microsite+".xml");
      oFS.move("file://"+sTmpDir+sDefFile, sProtocol+sFileSrvr+sSep+sTemplates+nm_microsite+sSep+nm_microsite+".xml");    
    }
  } // fi

  String sDataFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
  if (null!=sDataFile) {
    if (sProtocol.equals("file://")) {
      oFl = new File(sTemplates+nm_microsite+sSep+nm_microsite+".datatemplate.xml");
      if (oFl.exists()) oFl.delete();
      oFS.move("file://"+sTmpDir+sDataFile, "file://"+sTemplates+nm_microsite+sSep+nm_microsite+".datatemplate.xml");
    } else {
      oFS.delete(sProtocol+sFileSrvr+sSep+sTemplates+nm_microsite+sSep+nm_microsite+".datatemplate.xml");
      oFS.move("file://"+sTmpDir+sDataFile, sProtocol+sFileSrvr+sSep+sTemplates+nm_microsite+sSep+nm_microsite+".datatemplate.xml");    
    }
  } // fi

  String sXSLFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
  if (null!=sXSLFile) {
    if (sProtocol.equals("file://")) {
      oFl = new File(sTemplates+nm_microsite+sSep+nm_microsite+".xsl");
      if (oFl.exists()) oFl.delete();
      oFS.move("file://"+sTmpDir+sXSLFile, "file://"+sTemplates+nm_microsite+sSep+nm_microsite+".xsl");
    } else {
      oFS.delete(sProtocol+sFileSrvr+sSep+sTemplates+nm_microsite+sSep+nm_microsite+".xsl");
      oFS.move("file://"+sTmpDir+sXSLFile, sProtocol+sFileSrvr+sSep+sTemplates+nm_microsite+sSep+nm_microsite+".xsl");    
    }
  } // fi  

  String sThumbFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
  if (null!=sThumbFile) {
    oFl = new File(sThumbPath+nm_microsite+".gif");
    if (oFl.exists()) oFl.delete();
    oFS.move("file://"+sTmpDir+sThumbFile, "file://"+sThumbPath+nm_microsite+".gif");
  } // fi  

  JDCConnection oConn = null;
  MicrositeDB oMSite = new MicrositeDB();
    
  try {
    
    oConn = GlobalDBBind.getConnection("microsite_edit_store");  

    oConn.setAutoCommit (false);

    if (gu_microsite.length()>0) {
      oMSite.load(oConn, new Object[]{gu_microsite});
    }
    
    oMSite.replace(DB.id_app, Integer.parseInt(oReq.getParameter("id_app")));
    oMSite.replace(DB.tp_microsite, Short.parseShort(oReq.getParameter("tp_microsite")));
    oMSite.replace(DB.nm_microsite, nm_microsite);
    oMSite.replace(DB.gu_workarea, gu_workarea);
    
    if (sDefFile!=null)
      oMSite.replace(DB.path_metadata, sTemplates+sDefFile);
    
    oMSite.store(oConn);
    
    oConn.commit();    
    oConn.close("microsite_edit_store");
  }
  catch (SQLException e) {  
    if (oConn!=null) {
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("microsite_edit_store");
      }
    }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  catch (NumberFormatException e) {
    if (oConn!=null) {
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("microsite_edit_store");
      }
    }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_close"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.close()<" + "/SCRIPT" +"></HEAD></HTML>"); 

%>