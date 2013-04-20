<%@ page import="java.util.Properties,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.hipermail.*,com.knowgate.lucene.MailIndexer" language="java" session="false" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %><%
/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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
  
  String gu_folder = request.getParameter("gu_folder");
  String nm_folder = request.getParameter("nm_folder");

  String sBackUrl = "fldr_opts.jsp?gu_folder="+gu_folder+"&nm_folder="+Gadgets.URLEncode(nm_folder);
  
  SessionHandler oHndl = new SessionHandler(oMacc, sMBoxDir);
  DBStore oRdbms = null;
  DBFolder oFldr = null;

  // **************************************************
  // Re-create database entries from MBOX physical file
  
  try {
    oRdbms = DBStore.open(oHndl.getSession(), sProfile, sMBoxDir, id_user, tx_pwd);
    oFldr = oRdbms.openDBFolder(gu_folder, DBFolder.READ_WRITE);
    oFldr.reindexMbox();
    oFldr.close(false);    
    oFldr=null;
    oRdbms.close();
    oRdbms=null;
    oHndl.close();
    oHndl=null;
  } 
  catch (Exception e) {
    try { if (oFldr!=null) oFldr.close(false); } catch (Exception ignore) { }
    try { if (oRdbms!=null) oRdbms.close(); } catch (Exception ignore) { }
    try { if (oHndl!=null) oHndl.close(); } catch (Exception ignore) { }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume="+Gadgets.URLEncode(sBackUrl)));
    return;
  }

  // ******************************************
  // Re-build Lucene full text index for Folder
  
  Properties oProps = Environment.getProfile(GlobalDBBind.getProfileName());
  if (nullif(oProps.getProperty("luceneindex")).length()>0) {
    try {
      MailIndexer.rebuildFolder(oProps, gu_workarea, nm_folder);
    }
    catch (Exception e) {
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume="+Gadgets.URLEncode(sBackUrl)));
      return;
    }
  } // fi

  // ******************************************

  response.sendRedirect (response.encodeRedirectUrl (sBackUrl));
%>