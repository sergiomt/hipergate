<%@ page import="javax.mail.*,javax.mail.internet.*,java.io.IOException,java.io.UnsupportedEncodingException,java.io.ByteArrayOutputStream,java.util.Properties,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.debug.DebugFile,com.knowgate.dataobjs.DB,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipermail.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %><%
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

  // --------------------------------------------------------------------------
  
  response.addHeader ("cache-control", "private");

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_mimemsg = request.getParameter("gu_mimemsg");
  String gu_folder = request.getParameter("gu_folder");

  JDCConnection oCon = null;

  SessionHandler oHndl = null;
  DBStore oRDBMS = null;
  DBFolder oFldr = null;
  ByteArrayOutputStream oOutStrm;
  
  try {
    oHndl = new SessionHandler(oMacc);
    oRDBMS = new DBStore(oHndl.getSession(), new URLName("jdbc://", GlobalDBBind.getProfileName(), -1, sMBoxDir, id_user, tx_pwd));
    oRDBMS.connect();    
    oFldr = oRDBMS.openDBFolder(gu_folder,Folder.READ_ONLY);
    MimeMessage oMimeMsg = oFldr.getMessageByGuid(gu_mimemsg);
    if (oMimeMsg.getSize()>0)    
      oOutStrm = new ByteArrayOutputStream(oMimeMsg.getSize());
    else
      oOutStrm = new ByteArrayOutputStream();    
    oMimeMsg.writeTo(oOutStrm);
    oFldr.close(false);
    oFldr=null;
    oRDBMS.close();
    oRDBMS=null;
    out.write(oOutStrm.toString("UTF-8"));
  }
  catch (MessagingException me) {
    try { if (oFldr!=null) oFldr.close(false); } catch (Exception ignore) {}
    try { if (oRDBMS!=null) oRDBMS.close(); } catch (Exception ignore) {}
    try { if (oHndl!=null) oHndl.close(); } catch (Exception ignore) {}
    out.write("MessagingException " + me.getMessage());
  }
%><%@ include file="../methods/page_epilog.jspf" %>
