<%@ page import="java.io.IOException,java.io.File,java.io.FileInputStream,java.net.URLDecoder,java.util.Enumeration,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.addrbook.jical.ICalendarFactory,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.oreilly.servlet.MultipartRequest,com.knowgate.debug.DebugFile,com.knowgate.dataobjs.DBAudit" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = Gadgets.chomp(sTmpDir,File.separator);

  String sUserIdCookiePrologValue = null, sWorkAreaIdCookie = null;
  
  if (DebugFile.trace) {

    Cookie aCookies[] = request.getCookies();
    
    if (null != aCookies) {
      for (int c=0; c<aCookies.length; c++) {
      	if (aCookies[c].getName().equals("userid")) {
          sUserIdCookiePrologValue = java.net.URLDecoder.decode(aCookies[c].getValue());
        } else if (aCookies[c].getName().equals("workarea")) {
          sWorkAreaIdCookie = java.net.URLDecoder.decode(aCookies[c].getValue());
        }  
      } // for
      
    } // fi
      
    DBAudit.log ((short)0, "OJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, "", "", "");
  }

  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, "UTF-8");
  
  File oFile = null;
  FileInputStream oFileStream;
  String sFileName;
  JDCConnection oCon1 = null;
  
  try {
    Enumeration oFileNames = oReq.getFileNames();
    
    while (oFileNames.hasMoreElements()) {
      sFileName = oReq.getOriginalFileName(oFileNames.nextElement().toString());

      if (sFileName!=null) {
        oFile = new File(sTmpDir + sFileName);
        if (oFile==null) throw new IOException("Null file pointer");
      } else {
        throw new IOException("Invalid iCalendar file");
      }
    } // wend
    
    oCon1 = GlobalDBBind.getConnection("ical_store");      

    oCon1.setAutoCommit(false);

    ICalendarFactory.loadCalendar(oCon1, sUserIdCookiePrologValue, oFile, "UTF-8");

    oCon1.commit();
    
    oCon1.close("ical_store");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("ical_store");
        oCon1 = null;
      }
          
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Data Base Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  catch (IOException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("ical_store");
        oCon1 = null;
      }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=File Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  if (null==oCon1) return;  
  oCon1 = null;
  
  if (com.knowgate.debug.DebugFile.trace) {      
    com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, oReq.getServletPath(), "", 0, "", "", "");
  }
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");
%>
