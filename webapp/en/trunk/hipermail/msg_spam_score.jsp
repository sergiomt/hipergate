<%@ page import="java.io.FileInputStream,java.net.URLDecoder,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.misc.Environment,javax.mail.*,javax.mail.internet.MimeMessage,com.knowgate.hipermail.*,com.knowgate.misc.Gadgets,com.knowgate.debug.DebugFile,org.jasen.core.engine.Jasen,org.jasen.interfaces.JasenScanResult,com.knowgate.debug.StackTraceUtil" language="java" session="false" contentType="text/plain;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %><% 
/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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

  response.addHeader ("cache-control", "no-cache");

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  int iMsgNum = Integer.parseInt(request.getParameter("nu_msg"));
  float fThreshold = Float.parseFloat(nullif(request.getParameter("pct_threshold"),"1"));
  String sMsgId = request.getParameter("id_msg");

  // **************************************************************************
  // Initialize variables
    
  if (DebugFile.trace) DebugFile.writeln("<JSP:msg_spam_score.jsp Begin");

  
	Jasen oScanner = new Jasen();
	  
  JasenScanResult oResult = null;

  SessionHandler oHndl = new SessionHandler(oMacc, sMBoxDir);

  Folder oFldr = null;
  String sSubject = "";
  String sId = "";
  
  try {

    oFldr = oHndl.getFolder("inbox");

	  oFldr.open (Folder.READ_ONLY);

    MimeMessage oMsg = (MimeMessage) oFldr.getMessage(iMsgNum);
    
    sSubject = oMsg.getSubject();
	  sId = oMsg.getMessageID();

	  if (sMsgId.equals(sId)) {
	    oScanner.init();
	    oResult = oScanner.scan(oMsg, fThreshold, null);
	    oScanner.destroy();
    } else {
      throw new MessagingException("Message id mismatch, shold be "+sMsgId+" and it is "+sId);
    }

    oFldr.close(false);
    oFldr=null;
    
  } catch (Exception e) {  
    try { if (null!=oFldr) oFldr.close(false); } catch (Exception ignore) {}
    try { if (null!=oHndl) oHndl.close(); } catch (Exception ignore) {}
    if (DebugFile.trace) DebugFile.writeln(e.getClass().getName()+" "+nullif(e.getMessage())+"\n"+StackTraceUtil.getStackTrace(e));
    out.write("error\n"+e.getClass().getName()+" "+nullif(e.getMessage())+"\n"+StackTraceUtil.getStackTrace(e));
    return;
  }
  
  oHndl.close();

  if (DebugFile.trace) DebugFile.writeln("<JSP:msg_spam_score.jsp End");

  out.write((oResult.completed() ? "completed" : "error")+"\n"+String.valueOf(oResult.getProbability())+"\n"+sSubject+"\n");

  String[][] aResults = oResult.getTestResults();
  if (DebugFile.trace) DebugFile.writeln((oResult.completed() ? "completed" : "error")+" "+String.valueOf(oResult.getProbability())+" "+sSubject);
  
  if (null!=aResults) {
    for (int r=0; r<aResults.length; r++) {
      for (int t=0; t<aResults[r].length; t++) {
        if (DebugFile.trace) DebugFile.write(aResults[r][t]+"\t");
        out.write (aResults[r][t]+"\t");
      }
      if (DebugFile.trace) DebugFile.write("\n");
      out.write ("\n");      
    }
  }
%>