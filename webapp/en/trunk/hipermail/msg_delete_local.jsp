<%@ page import="javax.mail.*,javax.mail.internet.MimeMessage,java.util.Properties,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.debug.DebugFile,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  // **********************************************

  int iMailCount = 0;
  String sLocalGuids = request.getParameter("guids");
  String sFolder = request.getParameter("folder");
  String sCatId = sFolder;
  
  String[] aLocalGuids = Gadgets.split(sLocalGuids,',');
  
  MimeMessage oMsg;
  PreparedStatement oUpdt = null;
  JDCConnection oConn = null;
   
  SessionHandler oHndl = null;  
  DBStore oRDBMS = null;
  Folder oFolder = null;

  try {
    oHndl = new SessionHandler(oMacc,sMBoxDir);    

    oRDBMS = DBStore.open(oHndl.getSession(), sProfile, sMBoxDir, id_user, tx_pwd);

    oFolder = oRDBMS.getFolder(sFolder);      	      

    oFolder.open(Folder.READ_WRITE);

    sCatId = ((DBFolder)oFolder).getCategory().getString(DB.gu_category);

    String sSQL = "UPDATE " + DB.k_mime_msgs + " SET " + DB.bo_deleted + "=1 WHERE " + DB.gu_mimemsg + "=?";

    oRDBMS.getConnection().setAutoCommit(false);
    
    oUpdt = oRDBMS.getConnection().prepareStatement(sSQL);
    
    for (int i=0; i<aLocalGuids.length; i++) {
        if (null!=aLocalGuids[i]) {
          if (com.knowgate.debug.DebugFile.trace) DebugFile.writeln("Connection.executeUpdate(UPDATE " + DB.k_mime_msgs + " SET " + DB.bo_deleted + "=1 WHERE " + DB.gu_mimemsg + "='"+aLocalGuids[i]+"')");
          oUpdt.setString(1, aLocalGuids[i]);
          oUpdt.executeUpdate();          
        }
    } // next
    oUpdt.close();
    oUpdt = null;

    oRDBMS.getConnection().commit();
    
    oFolder.close(false);
    oFolder = null;
    oRDBMS.close();
    oRDBMS = null;
    oHndl.close();
    oHndl=null;
  }
  catch (MessagingException me) {
    aLocalGuids = null;
    if (null!=oUpdt) { try {oUpdt.close();} catch (Exception ignore) {}}
    if (null!=oRDBMS) {
      if (null!=oRDBMS.getConnection()) {
        try { oRDBMS.getConnection().rollback(); } catch (Exception ignore) {}
        try { oRDBMS.close(); } catch (Exception ignore) {}
      }
    }
    if (null!=oHndl) { try {oHndl.close();} catch (Exception ignore) {} }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MessagingException&desc=" + me.getMessage() + "&resume=_back"));
    return;
  }
%><%@ include file="../methods/page_epilog.jspf" %>
