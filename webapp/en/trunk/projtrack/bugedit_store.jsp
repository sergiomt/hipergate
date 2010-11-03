<%@ page import="java.io.IOException,java.io.File,java.io.FileInputStream,java.net.URLDecoder,java.util.Enumeration,java.sql.SQLException,java.sql.Timestamp,java.sql.PreparedStatement,java.sql.ResultSet,java.text.SimpleDateFormat,com.oreilly.servlet.MailMessage,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
  sTmpDir = Gadgets.chomp(sTmpDir,java.io.File.separator);

  String sUserIdCookiePrologValue = null, sWorkAreaIdCookie = null;
  
  if (com.knowgate.debug.DebugFile.trace) {

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
      
    com.knowgate.dataobjs.DBAudit.log ((short)0, "OJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, "", "", "");
  }

  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "10485760")), "UTF-8");
  
  int iPgBug = 0;
  String sOpCode = Integer.parseInt(oReq.getParameter("is_new"))==1 ? "NBUG" : "MBUG";

  String gu_bug = oReq.getParameter("gu_bug");
  String tl_bug = oReq.getParameter("tl_bug").trim();
  String tp_bug = nullif(oReq.getParameter("tp_bug"));  
  String sz_times = oReq.getParameter("nu_times");  
  String gu_project = oReq.getParameter("gu_project");
  String gu_writer = oReq.getParameter("gu_writer");
  String vs_found = oReq.getParameter("vs_found")==null ? "" : oReq.getParameter("vs_found");
  String vs_closed = oReq.getParameter("vs_closed")==null ? "" : oReq.getParameter("vs_closed");
  String sz_closed = oReq.getParameter("dt_closed")==null ? "" : oReq.getParameter("dt_closed");
  String sz_since = oReq.getParameter("dt_since")==null ? "" : oReq.getParameter("dt_since");
  short od_severity = Short.parseShort(nullif(oReq.getParameter("od_severity"),"0"));
  short od_priority = Short.parseShort(nullif(oReq.getParameter("od_priority"),"0"));
  String tx_status = oReq.getParameter("tx_status").length()==0 ? null : oReq.getParameter("tx_status");
  String nm_reporter = oReq.getParameter("nm_reporter");
  String tx_rep_mail = oReq.getParameter("tx_rep_mail");
  String nm_assigned = oReq.getParameter("nm_assigned");
  String tx_bug_brief = oReq.getParameter("tx_bug_brief");
  String tx_comments = oReq.getParameter("tx_comments");
  String checked_files = nullif(oReq.getParameter("checkedfiles"));
  Timestamp dt_closed, dt_since;
  Integer nu_times = null;
  String[] aCheckedFiles = null;
  
  if (checked_files.length()>0) aCheckedFiles = Gadgets.split(checked_files, '`');
  
  SimpleDateFormat oDateFormat;
  MailMessage msg;
  PreparedStatement oStmt;
  PreparedStatement oDlte;
  ResultSet oRSet;
  String sFileName;
  int iFileLen;
  File oFile;
  FileInputStream oFileStream;
  Enumeration oFileNames;
  JDCConnection oCon1 = null;
  boolean bAlreadyExists=false;
  Bug oBug = new Bug();
  
  if (sz_times!=null) {
    nu_times = new Integer(sz_times);
  }
  
  if (tx_comments!=null)
    if (tx_comments.length()==0) tx_comments=null;
    
  if (sz_closed.length()>0) {
    oDateFormat = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
    dt_closed =  new Timestamp(oDateFormat.parse(sz_closed + " 23:59:59").getTime());
  }
  else
    dt_closed = null;

  if (sz_since.length()>0) {
    oDateFormat = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
    dt_since =  new Timestamp(oDateFormat.parse(sz_since + " 00:00:00").getTime());
  }
  else
    dt_since = null;
                
  try {
    oCon1 = GlobalDBBind.getConnection("bugedit_store");  
    
    if (null==gu_bug) {      
      oStmt = oCon1.prepareStatement("SELECT b." + DB.pg_bug + " FROM  " +  DB.k_bugs + " b," + DB.k_projects + " p WHERE b." + DB.tl_bug + "=? AND p." + DB.gu_project + "=? AND b." + DB.gu_project + "=p." + DB.gu_project, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, tl_bug);
      oStmt.setString(2, gu_project);
      oRSet = oStmt.executeQuery();
    
      if (oRSet.next()) {
        out.write ("<HTML><HEAD><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
        out.write ("alert('Ya existe otra incidencia [" + oRSet.getObject(1).toString() + "] con el mismo Asunto');"); 
        out.write ("window.opener.location.reload();");
        out.write ("window.history.back();");  
        out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");
        oRSet.close();
        oStmt.close();
        bAlreadyExists=true;
      } // fi (oRSet.next())
      oRSet.close();
      oStmt.close();
    }
    else {
      oBug.put(DB.gu_bug, gu_bug);
    }
    
    Project oPrj = new Project (oCon1, gu_project);    
    
    if (!oPrj.isNull(DB.gu_contact))
      oBug.put(DB.id_client, oPrj.getString(DB.gu_contact));
    else if (!oPrj.isNull(DB.gu_company))
      oBug.put(DB.id_client, oPrj.getString(DB.gu_company));

    if (tp_bug.length()>0)
      oBug.put(DB.tp_bug, tp_bug);

    if (vs_found.length()>0)
      oBug.put(DB.vs_found, vs_found);

    if (vs_closed.length()>0)
      oBug.put(DB.vs_closed, vs_closed);
    
    if (sz_times!=null)
      oBug.put(DB.nu_times, nu_times);
    
    oBug.put(DB.tl_bug, tl_bug);
    oBug.put(DB.gu_project, gu_project);
    oBug.put(DB.gu_writer, gu_writer);
    oBug.put(DB.od_severity, od_severity);
    oBug.put(DB.od_priority, od_priority);
    oBug.put(DB.nm_reporter, nm_reporter);
    oBug.put(DB.tx_rep_mail, tx_rep_mail);
    oBug.put(DB.tx_bug_brief, tx_bug_brief);
    oBug.put(DB.dt_closed, dt_closed);
    oBug.put(DB.dt_since, dt_since);
    oBug.put(DB.tx_status, tx_status);
    oBug.put(DB.nm_assigned, nm_assigned);
    oBug.put(DB.tx_comments, tx_comments);
        
    oCon1.setAutoCommit (false);
    
    if (false) { // remove false to enable bug indexing with Lucene
      oBug.storeAndIndex(oCon1, Environment.getProfile(GlobalDBBind.getProfileName()));
    } else {
      oBug.store(oCon1);    
    }

    if (null!=aCheckedFiles) {
      oDlte = oCon1.prepareStatement("DELETE FROM " + DB.k_bugs_attach + " WHERE " + DB.gu_bug + "=? AND " + DB.tx_file + "=?");
      for (int f=0; f<aCheckedFiles.length; f++) {
        oDlte.setString(1, oBug.getString(DB.gu_bug));
        oDlte.setString(2, aCheckedFiles[f]);
        oDlte.executeUpdate();
      }
      oDlte.close();
    } // fi (aCheckedFiles)
      
    oDlte = oCon1.prepareStatement("DELETE FROM " + DB.k_bugs_attach + " WHERE " + DB.gu_bug + "=? AND " + DB.tx_file + "=?");
    
    oStmt = oCon1.prepareStatement("INSERT INTO " + DB.k_bugs_attach + "(" + DB.gu_bug + "," + DB.tx_file + "," + DB.len_file + "," + DB.bin_file + ") VALUES (?,?,?,?)");

    oFileNames = oReq.getFileNames();

    while (oFileNames.hasMoreElements()) {
      sFileName = oReq.getOriginalFileName(oFileNames.nextElement().toString());

      if (sFileName!=null) {
        // Delete previous instances of uploaded files
        oDlte.setString(1, oBug.getString(DB.gu_bug));
        oDlte.setString(2, sFileName);
        oDlte.execute();      
      
        // Get file length
        oFile = new File(sTmpDir + sFileName);

        if (oFile==null) throw new IOException("Null file pointer");

        iFileLen = new Long(oFile.length()).intValue();
      
        if (iFileLen>0) {
          // Move file into database blob field
          oFileStream = new FileInputStream (oFile);
          oStmt.setString(1, oBug.getString(DB.gu_bug));
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
      
    DBAudit.log(oCon1, Bug.ClassId, sOpCode, nm_reporter, oBug.getString(DB.gu_bug), null, 0, 0, tl_bug, null);
        
    oCon1.commit();
    
    if (sOpCode.equals("NBUG"))
      iPgBug = Bug.getPgFromId(oCon1, oBug.getString(DB.gu_bug));

    oCon1.setAutoCommit (true);

    com.knowgate.http.portlets.HipergatePortletConfig.touch(oCon1, sUserIdCookiePrologValue, "com.knowgate.http.portlets.MyIncidencesTab", sWorkAreaIdCookie);

    oCon1.close("bugedit_store");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("bugedit_store");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, oReq.getServletPath(), "", 0, "", "SQLException", e.getMessage());
    }
          
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Database access error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  catch (IOException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("bugedit_store");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, oReq.getServletPath(), "", 0, "", "IOException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=File access error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  
  if (null==oCon1) return;
  
  oCon1 = null;
  
  if (!bAlreadyExists) {    
    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\"><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
  
    if (sOpCode.equals("NBUG"))
      out.write ("alert('Thanks for using the incident reporting system. Your report has been assigned number&nbsp;" + String.valueOf(iPgBug) + ". From now on, you may consult the status of your incident from find and listing pages');");
  
    out.write ("window.opener.location.reload();");
  
    out.write ("self.close();");
  
    out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");

    if (null==gu_bug && null!=oReq.getParameter("chk_send_mail")) {
      msg = new MailMessage(Environment.getProfileVar(GlobalDBBind.getProfileName(),"mail.outgoing"));
      msg.from("hipergate incidents support");
      msg.to(tx_rep_mail);
      msg.setHeader("Return-Path", "noreply@hipergate.com");
      msg.setHeader("MIME-Version","1.0");
      msg.setHeader("Content-Type","text/plain;charset=\"utf-8\"");
      msg.setHeader("Content-Transfer-Encoding","8bit");
      
      msg.setSubject("Confirmacion " + String.valueOf(iPgBug) + ": " + tl_bug);
      msg.getPrintStream().println("Thanks for using the incident reporting system. Your report has been acknowledged and the support team will review it in brief.");
      msg.sendAndClose();
      
      msg = null;
    } // fi (null==gu_bug)
  } // fi(!bAlreadyExists)
%>
<%
  if (com.knowgate.debug.DebugFile.trace) {      
    com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, oReq.getServletPath(), "", 0, "", "", "");
  }
%>