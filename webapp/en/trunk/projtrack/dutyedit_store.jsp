<%@ page import="java.io.IOException,java.io.File,java.io.FileInputStream,java.net.URLDecoder,java.util.StringTokenizer,java.util.Enumeration,java.sql.SQLException,java.sql.Timestamp,java.sql.PreparedStatement,java.sql.ResultSet,java.text.SimpleDateFormat,javax.mail.Message,javax.mail.internet.InternetAddress,javax.mail.SendFailedException,javax.mail.MessagingException,javax.mail.internet.ParseException,javax.mail.internet.MimeUtility,com.sun.mail.smtp.SMTPMessage,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.hipermail.MailAccount,com.knowgate.hipermail.SessionHandler,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
  sTmpDir = com.knowgate.misc.Gadgets.chomp(sTmpDir,java.io.File.separator);
  
  MultipartRequest oReq = null;
  
  try {
    oReq = new MultipartRequest(request, sTmpDir, "UTF-8");
  }
  catch (IOException ioe) {
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", ioe.getMessage());
    }              
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + ioe.getMessage() + "&resume=_back"));    
    return;
  }

  String sOpCode = Integer.parseInt(oReq.getParameter("is_new"))==1 ? "NDTY" : "MDTY";

  String id_user = getCookie (oReq, "userid", null);
  String gu_duty = oReq.getParameter("gu_duty");
  String gu_writer = oReq.getParameter("gu_writer");
  String nm_duty = oReq.getParameter("nm_duty").trim();
  String gu_project = oReq.getParameter("gu_project");
  String sz_start = oReq.getParameter("dt_start")==null ? "" : oReq.getParameter("dt_start");
  String sz_scheduled = oReq.getParameter("dt_scheduled")==null ? "" : oReq.getParameter("dt_scheduled");
  String sz_end = oReq.getParameter("dt_end")==null ? "" : oReq.getParameter("dt_end");
  String nm_resource = oReq.getParameter("nm_resource");
  Short od_priority = null;
  String de_duty = oReq.getParameter("de_duty");
  String tx_comments = oReq.getParameter("tx_comments");
  String tx_status = oReq.getParameter("tx_status").length()==0 ? null : oReq.getParameter("tx_status");
  String pct_complete = oReq.getParameter("pct_complete").length()==0 ? "0" : oReq.getParameter("pct_complete");
  String pr_cost = oReq.getParameter("pr_cost").length()==0 ? null : oReq.getParameter("pr_cost");
  String chk_notify = oReq.getParameter("chk_notify");
  if (chk_notify==null) chk_notify="0";

  Timestamp dt_scheduled;
  Timestamp dt_start;
  Timestamp dt_end;
  
  StringTokenizer oStrTok;
  SimpleDateFormat oDateFormat;
  PreparedStatement oStmt = null;
  PreparedStatement oDlte = null;
  ResultSet oRSet;
  int iTokCount;
  String sFileName;
  int iFileLen;
  File oFile;
  FileInputStream oFileStream;
  Enumeration oFileNames;
  JDCConnection oCon1 = null;
  MailAccount oMacc = null;
  Duty oDuty = new Duty();
  ACLUser oMe = new ACLUser();
  ACLUser oHumanResource = new ACLUser();
  String[] aResourcesMails = null;
  int iHumanCount = 0;

  if (gu_writer!=null)
    if (gu_writer.length()==0) gu_writer=null;
  
  if (null!=oReq.getParameter("od_priority"))
    od_priority = new Short(oReq.getParameter("od_priority"));
    
  if (de_duty!=null)
    if (de_duty.length()==0) de_duty=null;
  
  if (tx_comments!=null)
    if (tx_comments.length()==0) tx_comments=null;

  if (sz_scheduled.length()>0) {
    oDateFormat = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
    dt_scheduled =  new Timestamp(oDateFormat.parse(sz_scheduled + " 00:00:00").getTime());
  }
  else
    dt_scheduled = null;
    
  if (sz_start.length()>0) {
    oDateFormat = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
    dt_start =  new Timestamp(oDateFormat.parse(sz_start + " 00:00:00").getTime());
  }
  else
    dt_start = null;

  if (sz_end.length()>0) {
    oDateFormat = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
    dt_end =  new Timestamp(oDateFormat.parse(sz_end + " 00:00:00").getTime());
  }
  else
    dt_end = null;
                
  try {
    oCon1 = GlobalDBBind.getConnection("dutyedit_store"); 
    
    oMe.load(oCon1, new Object[]{id_user});

    oMacc = MailAccount.forUser(oCon1,id_user,Environment.getProfile(GlobalDBBind.getProfileName()));

    if (nm_resource.length()>0) {
      oStrTok = new StringTokenizer(nm_resource,",");
      iTokCount = oStrTok.countTokens();
      aResourcesMails = new String[iTokCount];
      for (int t=0; t<iTokCount; t++) {      
        if (oHumanResource.load(oCon1, new Object[]{oStrTok.nextToken()})) {
          iHumanCount++;
          aResourcesMails[t]=oHumanResource.getString(DB.tx_main_email); 
        } else {
          aResourcesMails[t]=null;
        }
      } // next
    } // fi

    if (null!=gu_duty) {      
      oDuty.put(DB.gu_duty, gu_duty);
    }
    
    oDuty.put(DB.nm_duty, nm_duty);
    oDuty.put(DB.gu_project, gu_project);

    if (null!=gu_writer)    oDuty.put(DB.gu_writer, gu_writer);
    if (null!=od_priority)  oDuty.put(DB.od_priority, od_priority);
    if (null!=pct_complete) oDuty.put(DB.pct_complete, pct_complete);
    if (null!=dt_scheduled) oDuty.put(DB.dt_scheduled, dt_scheduled);
    if (null!=dt_start) oDuty.put(DB.dt_start, dt_start);
    if (null!=dt_end) oDuty.put(DB.dt_end, dt_end);
    if (null!=pct_complete) oDuty.put(DB.pct_complete, Short.parseShort(pct_complete));
    if (null!=pr_cost) oDuty.put(DB.pr_cost, Double.parseDouble(pr_cost));
    if (null!=tx_status) oDuty.put(DB.tx_status, tx_status);
    if (null!=de_duty) oDuty.put(DB.de_duty, de_duty);
    if (null!=tx_comments) oDuty.put(DB.tx_comments, tx_comments);
        
    oCon1.setAutoCommit (false);
    
    oDuty.store(oCon1);

    // Delete previous assigned resources    
    oDlte = oCon1.prepareStatement("DELETE FROM " + DB.k_x_duty_resource + " WHERE " + DB.gu_duty + "=?");
    oDlte.setString(1, oDuty.getString(DB.gu_duty));
    oDlte.execute();      
    oDlte.close();
    
    // Insert assigned resources
    oStmt = oCon1.prepareStatement("INSERT INTO " + DB.k_x_duty_resource + "(" + DB.gu_duty + "," + DB.nm_resource + ") VALUES ('" + oDuty.getString(DB.gu_duty) + "',?)");
    oStrTok = new StringTokenizer(nm_resource,",");
    iTokCount = oStrTok.countTokens();

    for (int t=0; t<iTokCount; t++) {
      oStmt.setString(1,oStrTok.nextToken());
      oStmt.execute();             
    }
    oStmt.close();
    oStrTok = null;
    
    oDlte = oCon1.prepareStatement("DELETE FROM " + DB.k_duties_attach + " WHERE " + DB.gu_duty + "=? AND " + DB.tx_file + "=?");
    
    oStmt = oCon1.prepareStatement("INSERT INTO " + DB.k_duties_attach + "(" + DB.gu_duty + "," + DB.tx_file + "," + DB.len_file + "," + DB.bin_file + ") VALUES (?,?,?,?)");

    oFileNames = oReq.getFileNames();

    while (oFileNames.hasMoreElements()) {
      sFileName = oReq.getOriginalFileName(oFileNames.nextElement().toString());
      
      if (null!=sFileName) {
        // Delete previous instances of uploaded files
        oDlte.setString(1, oDuty.getString(DB.gu_duty));
        oDlte.setString(2, sFileName);
        oDlte.execute();      
      
        // Get file length
        oFile = new File(sTmpDir + sFileName);

        if (oFile==null) throw new IOException("Null file pointer");

        iFileLen = new Long(oFile.length()).intValue();
      
        if (iFileLen>0) {
          // Move file into database blob field
          oFileStream = new FileInputStream (oFile);
          oStmt.setString(1, oDuty.getString(DB.gu_duty));
          oStmt.setString(2, sFileName);
          oStmt.setInt(3, iFileLen);
          oStmt.setBinaryStream(4, oFileStream, iFileLen);
          oStmt.execute();
          oFileStream.close();
          oFileStream = null;
        } // fi(iFileLen>0)
      
        // Delete temporary upload file      
        oFile.delete();
        oFile = null;
      } // fi (sFileName)
    } // wend(oFileNames.hasMoreElements())

    oStmt.close();
    oDlte.close();

    Project oProj = new Project(gu_project);
    oStmt = oCon1.prepareStatement("UPDATE "+DB.k_projects+" SET "+DB.pr_cost+"=? WHERE "+DB.gu_project+"=?");
    oStmt.setFloat (1, oProj.cost(oCon1));
    oStmt.setString(2, gu_project);
    oStmt.executeUpdate();
    oStmt.close();
    oStmt=null;

    DBAudit.log(oCon1, Duty.ClassId, sOpCode, "unknown", oDuty.getString(DB.gu_duty), null, 0, 0, nm_duty, null);
        
    oCon1.commit();
    
    oCon1.close("dutyedit_store");
  }
  catch (SQLException e) {
    if (null!=oCon1) {
      if (null!=oStmt) { try { oStmt.close(); } catch (Exception ignore) {} }
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("dutyedit_store");
        oCon1 = null;
      }
    }
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
              
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  catch (IOException e) {
    if (null!=oCon1) {
      if (null!=oStmt) { try { oStmt.close(); } catch (Exception ignore) {} }
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("dutyedit_store");
        oCon1 = null;
      }
    }  
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", e.getMessage());
    }
          
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));    
  }  
  if (null==oCon1) return;  
  oCon1 = null;
  
  if (chk_notify.equals("1") && iHumanCount>0) {
    SessionHandler oHndlr = null;
  
    try {
      oHndlr = new SessionHandler(oMacc);
      SMTPMessage oMsg = new SMTPMessage(oHndlr.getSession());
      oMsg.setHeader("Content-Transfert-Encoding", "8Bit");
      oMsg.setFrom(new InternetAddress(oMacc.getString(DB.tx_main_email),oMacc.getString(DB.tl_account)));
      oMsg.setSubject(MimeUtility.encodeText("New Duty "+nm_duty));
      oMsg.setText(nullif(de_duty)+"\n\n"+nullif(tx_comments), "utf-8");
      if (null!=od_priority) {
        switch ((int) od_priority.shortValue()) {
          case 1:
          case 2:
          case 3:
            oMsg.setHeader("X-Priority","1");
            break;
          case 5:
          case 6:
            oMsg.setHeader("X-Priority","5");
            break;
	}            
      } // fi      
      for (int r=0;r<aResourcesMails.length; r++) {
        if (aResourcesMails[r]!=null)
          oMsg.addRecipient(Message.RecipientType.TO, new InternetAddress(aResourcesMails[r].trim()));
      }

      oHndlr.sendMessage(oMsg, oMsg.getRecipients(Message.RecipientType.TO));

      oHndlr.close();
      oHndlr=null;
    }
    catch (SendFailedException e) {
      if (null!=oHndlr) { try { oHndlr.close(); } catch (Exception ignore) {} }
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SendFailedException&desc=" + e.getMessage() + "&resume=_close"));
      return;
    }
    catch (ParseException e) {  
      if (null!=oHndlr) { try { oHndlr.close(); } catch (Exception ignore) {} }
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ParseException&desc=" + e.getMessage() + "&resume=_close"));
      return;
    }
    catch (MessagingException e) {  
      if (null!=oHndlr) { try { oHndlr.close(); } catch (Exception ignore) {} }
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MessagingException&desc=" + e.getMessage() + "&resume=_close"));
      return;
    }
  } // fi (chk_notify=="1" && iHumanCount>0)
  
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\"><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
  out.write ("window.opener.location.reload();");  
  out.write ("self.close();");  
  out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");
%>
<%@ include file="../methods/page_epilog.jspf" %>)e