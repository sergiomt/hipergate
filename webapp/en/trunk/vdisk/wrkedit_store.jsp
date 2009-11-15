<%@ page import="java.io.IOException,java.io.File,java.io.FileInputStream,java.net.URLDecoder,java.util.Enumeration,java.sql.SQLException,java.sql.Date,java.sql.PreparedStatement,java.sql.ResultSet,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.workareas.FileSystemWorkArea,com.knowgate.misc.Environment,com.knowgate.workareas.WorkArea,com.knowgate.hipergate.datamodel.ModelManager" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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
  
  autenticateSession(GlobalDBBind, (HttpServletRequest)request, response);

  String sUserId = getCookie (request, "userid", "");
  String sWrkAId = getCookie (request, "workarea", "");
  
  String sDefWrkArGet = request.getRequestURI();
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet + "/workareas";

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = com.knowgate.misc.Gadgets.chomp(sTmpDir,java.io.File.separator);

  String sWrkPut = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasput", sDefWrkArPut);

  boolean bIsAdmin = false;

  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, "UTF-8");

  String sOpCode = Integer.parseInt(oReq.getParameter("is_new"))==1 ? "NWRK" : "MWRK";
  
  String gu_workarea = oReq.getParameter("gu_workarea");
  String nm_workarea = oReq.getParameter("nm_workarea");
  Integer id_domain = new Integer(oReq.getParameter("id_domain"));
  String n_domain = oReq.getParameter("n_domain");
  String id_app;
  String bo_associated;
  String gu_admins;
  String gu_powusers;
  String gu_users;
  String gu_guests;
  
  PreparedStatement oStmt;
  PreparedStatement oDlte;
  ResultSet oRSet;
  int iFileLen;
  File oFile;
  FileInputStream oFileStream;
  Enumeration oFileNames;
  String sCheckApp;
  String sFileName = null;
  JDCConnection oCon1 = null;
  boolean bAlreadyExists=false;
  WorkArea oWrkA = new WorkArea();
  ACLDomain oDom;
  String sDomainOwner;
  DBSubset oApps = null;
  int iApps = 0;
  int iAppMask = Integer.parseInt(getCookie(request,"appmask","0"));
  final String sYes = "1";
  
  final String sSep = System.getProperty("file.separator");
  
  FileSystemWorkArea oFS = null;
  
  try {
    oFS = new FileSystemWorkArea (Environment.getProfile(GlobalDBBind.getProfileName()));
  }
  catch (Exception e) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getClass().getName() + " whilst parsing " + GlobalDBBind.getProfileName() + " file&resume=_back"));
    return;
  }
   
  try {
    oCon1 = GlobalDBBind.getConnection("wrkedit_store");  

    ACLUser oUser = new ACLUser(oCon1, getCookie(request, "userid", ""));
      
    bIsAdmin = oUser.isDomainAdmin(oCon1);

    if (!bIsAdmin) {
        throw new SQLException("Administrator role is required for modifying workareas", "28000", 28000);
    }
            
    if (gu_workarea.length()==0)    
      oWrkA = new WorkArea();
    else 
      oWrkA = new WorkArea(oCon1, gu_workarea);    
    
    oApps = new DBSubset(DB.k_apps, DB.id_app, "1=1", 20);
    iApps = oApps.load(oCon1);
    
    oDom = new ACLDomain(oCon1, id_domain.intValue());
    sDomainOwner = oDom.getString(DB.gu_owner);
    oDom = null;
    
    if (gu_workarea.length()==0) {
      // Verify that no other previous workarea exists with the same name
      oStmt = oCon1.prepareStatement("SELECT b." + DB.gu_workarea + " FROM  " + DB.k_workareas + " b," + DB.k_domains + " p WHERE b." + DB.nm_workarea + "=? AND p." + DB.id_domain + "=? AND b." + DB.id_domain + "=p." + DB.id_domain, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, nm_workarea);
      oStmt.setInt(2, id_domain.intValue());
      oRSet = oStmt.executeQuery();
    
      if (oRSet.next()) {
        if (!oRSet.getString(1).equals(gu_workarea!=null ? gu_workarea : "")) {
          out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
          out.write ("alert('Ya existe otra Area de Trabajo con el mismo nombre');"); 
          out.write ("window.history.back();");  
          out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");
          oRSet.close();
          oStmt.close();
          bAlreadyExists=true;
        } // fi ()
      } // fi()
      oRSet.close();
      oStmt.close();
    } // fi()
            
    if (!bAlreadyExists) {
    
      // If new file is uploaded then delete previous file
      if (oWrkA.get(DB.path_logo)!=null && (nullif(oReq.getParameter("erase")).length()>0 || nullif(oReq.getParameter("path_logo")).length()>0))
        oFS.delete("file://" + sWrkPut + File.separator + gu_workarea + sSep + oWrkA.getString(DB.path_logo));
                      
      oFileNames = oReq.getFileNames();

      while (oFileNames.hasMoreElements()) {

        sFileName = oReq.getOriginalFileName(oFileNames.nextElement().toString());

	      if (null!=sFileName) {
          // oFS.mkworkpath (gu_workarea);
          oFS.mkdirs("file://" + sWrkPut + File.separator + gu_workarea);

          oFS.mkstorpath (id_domain.intValue(), gu_workarea, null);
          
          oFS.copy("file://" + sTmpDir + sFileName, "file://" + sWrkPut + File.separator + gu_workarea + sSep + sFileName);
	            
          // Delete temporary upload file      
          oFile = new File (sTmpDir + sFileName);
          oFile.delete();
          oFile = null;
        } // fi (sFileName)
        
      } // wend(oFileNames.hasMoreElements())

      oCon1.setAutoCommit (false);

      if (sYes.equals(oReq.getParameter("load_lookups"))) {
        
        ModelManager oModMan = new ModelManager();
        oModMan.setConnection(oCon1);
        gu_workarea = oModMan.cloneWorkArea("MODEL.model_default", n_domain + "." + nm_workarea);
        
        if (null==gu_workarea)
          throw new SQLException(oModMan.report());
        else
          oWrkA = new WorkArea(oCon1, gu_workarea);
          
        oModMan = null;
      }        
      
      oWrkA.replace(DB.nm_workarea, nm_workarea);
      oWrkA.replace(DB.id_domain, id_domain);
      oWrkA.replace(DB.gu_owner, sDomainOwner);
      oWrkA.replace(DB.bo_active, 1);    
      if (nullif(oReq.getParameter("erase")).length()>0)
        oWrkA.remove(DB.path_logo);
      else if (null!=sFileName)
        oWrkA.replace(DB.path_logo, sFileName);
      
      oWrkA.store(oCon1);
      
      // Delete previous associations between WorkArea and Applications
      oDlte = oCon1.prepareStatement("DELETE FROM " + DB.k_x_app_workarea + " WHERE " + DB.gu_workarea + "=?");
      oDlte.setString(1, oWrkA.getString(DB.gu_workarea));
      oDlte.execute();
      oDlte.close();
      
      // Write associations between WorkArea and Applications    
      oStmt = oCon1.prepareStatement("INSERT INTO " + DB.k_x_app_workarea + " (" + DB.id_app + "," + DB.gu_workarea + "," + DB.gu_admins + "," + DB.gu_powusers + "," + DB.gu_users + "," + DB.gu_guests + "," + DB.path_files + ") VALUES (?,?,?,?,?,?,?)");
  
      for (int a=0; a<iApps; a++) {
        id_app = String.valueOf(oApps.getInt(0,a));
	      sCheckApp = nullif(oReq.getParameter("c" + id_app));
        
        if (sCheckApp.length()>0) {
          gu_admins = oReq.getParameter("a" + id_app + "admins");
          gu_powusers = oReq.getParameter("a" + id_app + "powusers");
  	      gu_users = oReq.getParameter("a" + id_app + "users");
          gu_guests = oReq.getParameter("a" + id_app + "guests");
          
          oStmt.setInt(1, oApps.getInt(0,a));
          oStmt.setString(2, oWrkA.getString(DB.gu_workarea));
          if (nullif(gu_admins).equals("")) oStmt.setString(3, null); else oStmt.setString(3, gu_admins);
          if (nullif(gu_powusers).equals("")) oStmt.setString(4, null); else oStmt.setString(4, gu_powusers);
          if (nullif(gu_users).equals("")) oStmt.setString(5, null); else oStmt.setString(5, gu_users);
          if (nullif(gu_guests).equals("")) oStmt.setString(6, null); else oStmt.setString(6, gu_guests);
          oStmt.setString(7, nm_workarea);
          
          oStmt.execute();
        } // fi()
      } // next (a)
      oStmt.close();
                
      DBAudit.log(oCon1, WorkArea.ClassId, sOpCode, sUserId, oWrkA.getString(DB.gu_workarea), null, 0, 0, nm_workarea, null);
    
      oCon1.commit();

      iAppMask = WorkArea.getUserAppMask(oCon1, gu_workarea, sUserId);

      oUser = new ACLUser(oCon1, sUserId);	  
      if (oUser.isDomainAdmin(oCon1)) iAppMask = iAppMask | (1<<30);
      oUser = null;
    
    } // fi (bAlreadyExists)  

    GlobalCacheClient.expireAll();
    
    oCon1.close("wrkedit_store");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        try { oCon1.rollback(); } catch (Exception ignore) {}
        oCon1.close("wrkedit_store");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  catch (IllegalStateException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("wrkedit_store");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  catch (IOException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("wrkedit_store");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileSystem Error&desc=" + e.getMessage() + "&resume=_back"));    
  }
  catch (org.xml.sax.SAXException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("wrkedit_store");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SAXException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  catch (UnsupportedOperationException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("wrkedit_store");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=UnsupportedOperationException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  
  oCon1 = null;
  
  if (!bAlreadyExists) {    
    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\"><SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript' SRC='../javascript/cookies.js'></SCRIPT><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>\n");

    if (gu_workarea.equals(sWrkAId))
      out.write ("document.cookie = \"appmask=" + String.valueOf(iAppMask) + "; path=/\";");

    out.write ("        setCookie (\"path_logo\",\"" + nullif(sFileName) + "\");\n");

    out.write ("opener.location.reload();\n");    

    out.write ("self.close();\n");
  
    out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");
  } // fi(!bAlreadyExists)
%>
