<%@ page import="java.util.Date,com.oreilly.servlet.MultipartRequest,java.util.Enumeration,java.io.IOException,java.net.URLDecoder,java.sql.Timestamp,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dfs.FileSystem,com.knowgate.hipermail.SendMail,com.knowgate.hipermail.MailAccount,com.knowgate.misc.*,com.knowgate.hipergate.*,com.knowgate.forums.*,com.knowgate.lucene.NewsMessageIndexer" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/multipartreqload.jspf" %><%
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
  final String sSep = System.getProperty("file.separator");

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sTempDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTempDir = Gadgets.chomp(sTempDir,sSep);

  String sWrkAPut = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasput", sDefWrkArPut);
  String sFileProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  String sFileServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  
  MultipartRequest oReq = new MultipartRequest(request, sTempDir, Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "10485760")), "UTF-8");
      
  String id_domain = oReq.getParameter("id_domain");
  String n_domain = oReq.getParameter("n_domain");
  String gu_workarea = oReq.getParameter("gu_workarea");
  String id_user = oReq.getParameter("gu_user");
  String id_language = oReq.getParameter("id_language");
  String gu_newsgrp = oReq.getParameter("gu_newsgrp");
  String tx_subject = oReq.getParameter("tx_subject");
  short  id_status = Short.parseShort(nullif(oReq.getParameter("id_status"),"0"));
  String gu_product = null;
  int pg_prod_locat = 1;
      
  FileSystem oFileSys;
  Product oProd;  
  ProductLocation oLoca;  
  Enumeration oFileNames;
  NewsGroup oGrp;
  NewsMessage oMsg = new NewsMessage();
  String sMsgId = Gadgets.generateUUID();
  String aDtEnd[];
  String aSubscribers[] = null;
  String aAttachments[] = null;
  DBSubset oAttachments;
  MailAccount oMacc = null;
  
	String sFile;
  String sPath = sWrkAPut + sSep + gu_workarea + sSep + "apps" + sSep + "Forums" + sSep;

  Date dtPub = null;
  if (nullif(oReq.getParameter("dt_published")).length()>0) {
    aDtEnd = Gadgets.split(oReq.getParameter("dt_published"),"-");
    dtPub = new Date(Integer.parseInt(aDtEnd[0])-1900,Integer.parseInt(aDtEnd[1])-1,Integer.parseInt(aDtEnd[2]), Integer.parseInt(oReq.getParameter("dt_hour")), Integer.parseInt(oReq.getParameter("dt_min")), Integer.parseInt(oReq.getParameter("dt_sec")));
  }
  
  JDCConnection oConn = null;

  try {
    oConn = GlobalDBBind.getConnection("msg_edit_store");
    
    oGrp = new NewsGroup(oConn, gu_newsgrp);

    if (oReq.getFileCount()>0) {
      oProd = new Product();
      oProd.put(DB.nm_product, sMsgId);
      oProd.put(DB.gu_owner, id_user);
      oProd.put(DB.id_language, id_language);
      oProd.put(DB.dt_uploaded, new Timestamp(System.currentTimeMillis()));
      oProd.put(DB.id_status, id_status);
      oProd.put(DB.is_compound, (short)1);
      oProd.put(DB.de_product, tx_subject);
    
      if (oGrp.getShort(DB.id_doc_status)==NewsGroup.MODERATED) {
        oProd.put(DB.dt_start, new Timestamp(System.currentTimeMillis()));
      }
    
      if (nullif(oReq.getParameter("dt_expire")).length()>0) {
        aDtEnd = Gadgets.split(oReq.getParameter("dt_expire"),"-");
        oProd.put(DB.dt_expire, new Timestamp(new java.util.Date(Integer.parseInt(aDtEnd[0]),Integer.parseInt(aDtEnd[1]),Integer.parseInt(aDtEnd[2])).getTime()));
      }       

      if (dtPub!=null) {
        aDtEnd = Gadgets.split(oReq.getParameter("dt_published"),"-");
        oProd.put(DB.dt_published, new Timestamp(dtPub.getTime()));
      }       
    
      oProd.store(oConn);
      gu_product = oProd.getString(DB.gu_product);
      
      sPath += oGrp.getString(DB.nm_category);
      
      oFileSys = new FileSystem(Environment.getProfile(GlobalDBBind.getProfileName()));
      
      if (sFileProtocol.equalsIgnoreCase("file://"))
        oFileSys.mkdirs(sFileProtocol + sPath);
      else
        oFileSys.mkdirs(sFileProtocol + sFileServer + sPath);
      
      oLoca = new ProductLocation();      
      oLoca.put(DB.gu_owner, id_user);  
      oLoca.put(DB.gu_product, oProd.get(DB.gu_product));
      oLoca.put(DB.pg_prod_locat, pg_prod_locat);
      
      oFileNames = oReq.getFileNames();
    
      while (oFileNames.hasMoreElements()) {
        // Get original file name as uploaded from client and store it in sFile
        
        sFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
        
	      if (sFile!=null) {      
          if (sFileProtocol.equalsIgnoreCase("file://")) {
            oLoca.setPath  (sFileServer, Gadgets.chomp(sPath,sSep) + sFile);
            oLoca.replace(DB.id_cont_type, ProductLocation.CONTAINER_FILE);
            oLoca.replace(DB.id_prod_type, oLoca.getProductType());
          }
          else {
            oLoca.setPath(sFileProtocol, sFileServer, sPath, sFile, sFile);
            oLoca.replace(DB.id_cont_type, oLoca.getContainerType());
          }
          oLoca.setLength(oFileSys.filelen(Gadgets.chomp(sTempDir,sSep) + sFile));
            
          // Actually store product location
          oLoca.store(oConn);
          if (sFileProtocol.equalsIgnoreCase("file://"))
            oLoca.upload(oConn, oFileSys, "file://" + sTempDir, sFile, sFileProtocol + sPath, sFile);
          else
            oLoca.upload(oConn, oFileSys, "file://" + sTempDir, sFile, sFileProtocol + sFileServer + sPath, sFile);
          oLoca.remove(DB.gu_location);
          oLoca.replace(DB.pg_prod_locat, ++pg_prod_locat);
        } // fi (sFile)  
      } // wend(oFileNames.hasMoreElements())
      
      oFileNames = null;
      oLoca = null;
      oFileSys = null;
      oProd = null;      
    }

    loadRequest(oConn, oReq, oMsg);
    
    oMsg.put(DB.gu_newsgrp, gu_newsgrp);    
		if (dtPub!=null) oMsg.replace(DB.dt_published, new Timestamp(dtPub.getTime()));
		
    if (oReq.getParameter("tx_tags").length()>0)
      oMsg.put(DB.tx_tags, oReq.getParameter("tx_tags"));    
     
    if (nullif(oReq.getParameter("id_status")).length()==0) {
      if (oGrp.getShort(DB.id_doc_status)==NewsGroup.MODERATED)    
        oMsg.put(DB.id_status, NewsMessage.STATUS_PENDING);
      else
        oMsg.put(DB.id_status, NewsMessage.STATUS_VALIDATED);
    }

    if (gu_product!=null) oMsg.put(DB.gu_product, gu_product);
    
    oConn.setAutoCommit (false);
    
    oMsg.store(oConn);

    DBAudit.log(oConn, NewsMessage.ClassId, "NMSG", id_user, oMsg.getString(DB.gu_msg), null, 0, 0, oReq.getParameter("tx_subject"), null);

    oConn.commit();

    aSubscribers = oMsg.subscribers(oConn);

    oAttachments = oMsg.getAttachments(oConn);
	  if (null==oAttachments) {
	    aAttachments = null;
	  } else {
	    aAttachments = new String[oAttachments.getRowCount()];
	    for (int a=0; a<aAttachments.length; a++) {
	      aAttachments[a] = oAttachments.getString(DB.xfile,a);
	    } // next
	  } // fi 

	  if (aSubscribers!=null) {
	    oMacc = MailAccount.forUser(oConn, id_user, GlobalDBBind.getProperties());
	  }

    oConn.setAutoCommit (true);

    com.knowgate.http.portlets.HipergatePortletConfig.touch(oConn, id_user, "com.knowgate.http.portlets.RecentPostsTab", gu_workarea);

		NewsGroupJournal oJour = oGrp.getJournal();
		if (null!=oJour) {
		  oJour.rebuild(oConn, false);
		}

    oConn.close("msg_edit_store");
    
		if (null!=GlobalDBBind.getProperty("luceneindex")) {
			NewsMessageIndexer oIdxr = new NewsMessageIndexer();
			oIdxr.addOrReplaceNewsMessage(GlobalDBBind.getProperties(), oMsg.getString(DB.gu_msg), gu_workarea, gu_newsgrp, tx_subject, oMsg.getStringNull(DB.nm_author,""), oMsg.getDate(DB.dt_start), oMsg.getStringNull(DB.tx_msg,""));
		}    
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"msg_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (IOException e) {  
    disposeConnection(oConn,"msg_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (oConn==null) return;

  try {
    String sXHtml = oMsg.getStringNull(DB.tx_msg,"");    

    if (null!=aSubscribers && oMacc!=null && oMsg.getShort(DB.id_status)==NewsMessage.STATUS_VALIDATED) {
			SendMail.send (GlobalDBBind.getProperties(), sPath, sXHtml, sXHtml, "ISO-8859-1", aAttachments,
										 "[hipergate forum] "+oMsg.getStringNull(DB.tx_subject,""), oMsg.getStringNull(DB.tx_email,""),
										 oMsg.getStringNull(DB.nm_author,""), oMsg.getStringNull(DB.tx_email,""), aSubscribers, "to",
										 oMsg.getString(DB.gu_msg),GlobalDBBind.getProfileName(),
										 Gadgets.left(oMsg.getStringNull(DB.tx_subject,"")+" ("+String.valueOf(oMsg.getInt(DB.nu_thread_msgs))+")",100),
										 GlobalDBBind);			      
    }
  } catch (Exception xcpt) {
    if (DebugFile.trace) DebugFile.writeln("<JSP:msg_edit_store.jsp "+xcpt.getClass().getName()+" "+xcpt.getMessage());
  }

  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>if (window.opener) window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>
