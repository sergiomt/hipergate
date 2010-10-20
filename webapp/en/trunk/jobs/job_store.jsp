<%@ page import="java.util.ArrayList,java.util.Date,java.util.Properties,java.text.SimpleDateFormat,java.io.File,java.io.FileNotFoundException,java.io.IOException,java.net.URL,java.net.URLDecoder,java.sql.Statement,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dfs.FileSystem,com.knowgate.dfs.chardet.CharacterSetDetector,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Job,com.knowgate.crm.DistributionList,com.knowgate.hipermail.AdHocMailing,com.knowgate.hipermail.HtmlMimeBodyPart,com.knowgate.hipermail.MailAccount,com.knowgate.hipermail.SendMail,com.knowgate.crm.GlobalBlackList,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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
  
  final String WEBMAILS_REGEXP = "[\\w\\x2E_-]+@((?:yahoo)|(?:wanadoo)|(?:terra)|(?:hotmail)|(?:gmail))(?:\\x2E\\D{2,4}){1,2}";

  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  String gu_pageset = request.getParameter("gu_pageset");
  String gu_job = request.getParameter("gu_job");
  String tl_job = request.getParameter("tl_job");  
  String gu_job_group = request.getParameter("gu_job_group");
  String id_command = request.getParameter("id_command");
  String tx_parameters = request.getParameter("tx_parameters");
  String id_status = request.getParameter("id_status");
  String hour = request.getParameter("sel_hour");
  String min = request.getParameter("sel_minute");
  String sSQL = "";
  String sGuJob;
  final int iAttachImages = Integer.parseInt(request.getParameter("attachimages"));
  DistributionList oRecipients = null;
  String[] aRecipients = null;
  int nBatch;
  
  final boolean bAsap = request.getParameter("dt_execution").equals("ASAP");
  Date dtExecution;
  if (bAsap) 
    dtExecution = null;
  else
  	dtExecution = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse(request.getParameter("dt_execution")+" "+hour+":"+min+":00");

  String[] aLists = null;
  int iGuList = tx_parameters.indexOf("gu_list:");
  if (iGuList>0) {
    int iComma = tx_parameters.indexOf(",", iGuList+8);
    if (iComma>0)
      aLists = Gadgets.split(tx_parameters.substring(iGuList+8,iComma),';');
    else
  	  aLists = Gadgets.split(tx_parameters.substring(iGuList+8),';');
  }

  URL oWebSrv = new URL(GlobalDBBind.getProperty("webserver"));

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut + File.separator + "workareas/";
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;

  JDCConnection oConn = null;  
  
  try {
    oConn = (JDCConnection) GlobalDBBind.getConnection(GlobalDBBind.getProperty("dbuser"), GlobalDBBind.getProperty("dbpassword"));
    
    if (id_command.equals("MAIL")) {
      sSQL = "INSERT INTO k_jobs ";
      sSQL += "(gu_workarea,gu_writer,gu_job,tl_job,gu_job_group,id_command,tx_parameters,id_status,dt_execution) VALUES (";
      sSQL += "'"+gu_workarea+"',";
      sSQL += "'"+id_user+"',";
      sSQL += "'"+gu_job+"',";
      sSQL += "'"+tl_job+"',";    
      sSQL += "'"+gu_job_group+"',";
      sSQL += "'"+id_command+"',";
      sSQL += "'"+tx_parameters+"',";
      sSQL += id_status+",";
      if (bAsap)
        sSQL += "NULL";
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL)
        sSQL += "timestamp '" + request.getParameter("dt_execution") + " "+hour+":"+min+":00' ";
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
        sSQL += "TIMESTAMP ('" + request.getParameter("dt_execution") + " "+hour+":"+min+":00') ";
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE)
        sSQL += "TO_DATE('" + request.getParameter("dt_execution") + " "+hour+":"+min+"','YYYY-MM-DD HH24:MI') ";
      else
        sSQL += "{ ts '" + request.getParameter("dt_execution") + " "+hour+":"+min+":00'} ";
      sSQL += ")";
    
      oConn.setAutoCommit (false);

      Statement oStmt = oConn.createStatement();
    
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      
      oStmt.executeUpdate(sSQL);
      oStmt.close();
    
      if (iGuList>0) {
        Job oEmailSender = Job.instantiate(oConn, gu_job, GlobalDBBind.getProperties());
        for (int l=0; l<aLists.length; l++) {
          oRecipients = new DistributionList (oConn, aLists[l]);
          aRecipients = Gadgets.split(oRecipients.activeMembers(oConn),',');
          oEmailSender.insertRecipients(oConn, aRecipients, "to", "html", Job.STATUS_PENDING);
        }
      } // fi

    } else if (id_command.equals("SEND")) {

      AdHocMailing oAdhm = new AdHocMailing();

      if (!oAdhm.load(oConn, gu_pageset)) {
        throw new SQLException("Could not find AdHocMailing "+gu_pageset);
      } else {

        if (oAdhm.isNull(DB.tx_email_from)) {
          throw new SQLException("Sender address was not set");
        }

				oAdhm.addBlackList(GlobalBlackList.forDomain(oConn, Integer.parseInt(id_domain)));
				
        String sTargetDir = sWrkAPut + gu_workarea + File.separator + "apps" + File.separator + "Hipermail" + File.separator + "html" + File.separator + Gadgets.leftPad(String.valueOf(oAdhm.getInt(DB.pg_mailing)), '0', 5);
        String sWrkGetDir = oWebSrv.getProtocol()+"://"+oWebSrv.getHost()+(oWebSrv.getPort()==-1 ? "" : ":"+String.valueOf(oWebSrv.getPort()))+Gadgets.chomp(GlobalDBBind.getProperty("workareasget"),"/")+gu_workarea+"/apps/Hipermail/html/"+Gadgets.leftPad(String.valueOf(oAdhm.getInt(DB.pg_mailing)),'0',5)+"/";
      	ArrayList<String> oAttachments = new ArrayList<String>();
      	String[] aFiles = new File(sTargetDir).list();
        String sHtmlFile = null, sPlainFile = null;
        if (aFiles!=null) {
          for (int f=0; f<aFiles.length; f++) {
            String sFileName = aFiles[f].toLowerCase();
            if (sFileName.endsWith(".htm") || sFileName.endsWith(".html")) {
              if (sHtmlFile!=null) throw new FileNotFoundException("More than one HTML partw as uploaded for the email "+sHtmlFile+", "+sFileName);
              sHtmlFile = aFiles[f];
            }
            if (sFileName.endsWith(".txt")) {
              if (sPlainFile!=null) throw new FileNotFoundException("More than one plain part was uploaded for the email "+sPlainFile+", "+sFileName);
              sPlainFile = aFiles[f];
            }
            if (sFileName.endsWith(".pdf") || sFileName.endsWith(".doc") || sFileName.endsWith(".xls") || sFileName.endsWith(".ppt") ||
                sFileName.endsWith(".odf") || sFileName.endsWith(".odg") || sFileName.endsWith(".zip") || sFileName.endsWith(".arj") ||
                sFileName.endsWith(".rar") || sFileName.endsWith(".avi") || sFileName.endsWith(".mpg") || sFileName.endsWith(".mpeg") ||
                sFileName.endsWith(".wmv") || sFileName.endsWith(".docx") || sFileName.endsWith(".xlsx"))
              oAttachments.add(aFiles[f]);
               
          } // next
        } // fi
        String[] aAttachments;
        if (oAttachments.size()==0)
          aAttachments = null;
        else
          aAttachments = oAttachments.toArray(new String[oAttachments.size()]);

        if (null==sHtmlFile && null==sPlainFile) {
          throw new SQLException("Could not find any valid file for e-mail body");
        } else {

          MailAccount oMacc = MailAccount.forUser(oConn, id_user);

          if (oMacc==null) {

            throw new SQLException("Could not find default mail account for current user");

          } else {

				    Properties oProps = oMacc.getProperties();
				    oProps.put("webbeacon", nullif(request.getParameter("webbeacon"),"0").equals("1") ? "1" : "0");
				    oProps.put("clickthrough", nullif(request.getParameter("clickthrough"),"0").equals("1") ? "1" : "0");
				    oProps.put("webserver", GlobalDBBind.getProperty("webserver"));		    	

						FileSystem oFs = new FileSystem();

            String sHtmlText = null, sPlainText = null, sEncoding = "ISO8859_1";
            CharacterSetDetector oCDet = new CharacterSetDetector();

            if (null!=sPlainFile) {
              sEncoding = oCDet.detect(sTargetDir+File.separator+sPlainFile, sEncoding);
              sPlainText = oFs.readfilestr(sTargetDir+File.separator+sPlainFile, sEncoding);
            }

            if (null!=sHtmlFile) {
              sEncoding = oCDet.detect(sTargetDir+File.separator+sHtmlFile, sEncoding);
              sHtmlText = oFs.readfilestr(sTargetDir+File.separator+sHtmlFile, sEncoding);
              int iBodyStart = Gadgets.indexOfIgnoreCase(sHtmlText,"<body>", 0);
              if (iBodyStart>=0) {
                int iBodyEnd = Gadgets.indexOfIgnoreCase(sHtmlText,"</body>", iBodyStart+6);
                if (iBodyEnd!=-1) {
                  sHtmlText = sHtmlText.substring(0, iBodyStart+6) + Gadgets.XHTMLEncode(sHtmlText.substring(iBodyStart+6, iBodyEnd)) + sHtmlText.substring(iBodyEnd);
                } // fi
              } // fi
            } // fi

            nBatch = DBCommand.queryCount(oConn, "*", DB.k_jobs, DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.tl_job+" LIKE '"+oAdhm.getString(DB.nm_mailing)+"%'");

      			oConn.setAutoCommit (false);

						switch (iAttachImages) {

						  case 0:
						  	oProps.put("attachimages", "0");
            	  if (iGuList>0) {
                  for (int l=0; l<aLists.length; l++)
						        oAdhm.addRecipients(Gadgets.split(new DistributionList (oConn, aLists[l]).activeMembers(oConn),','));
						    }
				        sGuJob = Gadgets.generateUUID();
				        SendMail.send(oMacc, oProps, sTargetDir, sHtmlText, sPlainText, sEncoding, aAttachments,
				                      oAdhm.getStringNull(DB.tx_subject,""), oAdhm.getString(DB.tx_email_from),
				                      oAdhm.getStringNull(DB.nm_from, oAdhm.getString(DB.tx_email_from)),
				                      oAdhm.getStringNull(DB.tx_email_reply, oAdhm.getString(DB.tx_email_from)),
				                      oAdhm.getRecipients(), "to", sGuJob, 
				                      GlobalDBBind.getProfileName(), oAdhm.getString(DB.nm_mailing)+" ("+String.valueOf(++nBatch)+")",
				                      false, GlobalDBBind);
						  	DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_jobs+" SET "+DB.gu_job_group+"='"+gu_pageset+"' WHERE "+DB.gu_job+"='"+sGuJob+"'");
						  	break;
						  
						  case 1:
						  	oProps.put("attachimages", "1");
            	  if (iGuList>0) {
                  for (int l=0; l<aLists.length; l++)
						      oAdhm.addRecipients(Gadgets.split(new DistributionList (oConn, aLists[l]).activeMembers(oConn),','));
						    }
				        sGuJob = Gadgets.generateUUID();
				        if (sHtmlText!=null)
									sHtmlText = new HtmlMimeBodyPart(sHtmlText, sEncoding).replacePreffixFromImgSrcs(sWrkGetDir, sTargetDir+File.separator);
				        SendMail.send(oMacc, oProps, sTargetDir,
				        							sHtmlText, sPlainText, sEncoding, aAttachments,
				                      oAdhm.getStringNull(DB.tx_subject,""), oAdhm.getString(DB.tx_email_from),
				                      oAdhm.getStringNull(DB.nm_from, oAdhm.getString(DB.tx_email_from)),
				                      oAdhm.getStringNull(DB.tx_email_reply, oAdhm.getString(DB.tx_email_from)),
				                      oAdhm.getRecipients(), "to", sGuJob,  
				                      GlobalDBBind.getProfileName(), oAdhm.getString(DB.nm_mailing)+" ("+String.valueOf(++nBatch)+")",
				                      false, dtExecution, GlobalDBBind);
						  	DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_jobs+" SET "+DB.gu_job_group+"='"+gu_pageset+"' WHERE "+DB.gu_job+"='"+sGuJob+"'");
						  	break;

              case 2:

						  	oProps.put("attachimages", "0");
                oAdhm.setAllowPattern(WEBMAILS_REGEXP);
                oAdhm.setDenyPattern("");
            	  if (iGuList>0) {
                  for (int l=0; l<aLists.length; l++)
						        oAdhm.addRecipients(Gadgets.split(new DistributionList (oConn, aLists[l]).activeMembers(oConn),','));
						    }
				        sGuJob = Gadgets.generateUUID();
				        SendMail.send(oMacc, oProps, sTargetDir, sHtmlText, sPlainText, sEncoding, aAttachments,
				                      oAdhm.getStringNull(DB.tx_subject,""), oAdhm.getString(DB.tx_email_from),
				                      oAdhm.getStringNull(DB.nm_from, oAdhm.getString(DB.tx_email_from)),
				                      oAdhm.getStringNull(DB.tx_email_reply, oAdhm.getString(DB.tx_email_from)),
				                      oAdhm.getRecipients(), "to", sGuJob,
				                      GlobalDBBind.getProfileName(), oAdhm.getString(DB.nm_mailing)+" ("+String.valueOf(++nBatch)+")",
				                      false, dtExecution, GlobalDBBind);
						  	DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_jobs+" SET "+DB.gu_job_group+"='"+gu_pageset+"' WHERE "+DB.gu_job+"='"+sGuJob+"'");

								oAdhm.clearRecipients();

						  	oProps.put("attachimages", "1");
                oAdhm.setAllowPattern("");
                oAdhm.setDenyPattern(WEBMAILS_REGEXP);
            	  if (iGuList>0) {
                  for (int l=0; l<aLists.length; l++)
						        oAdhm.addRecipients(Gadgets.split(new DistributionList (oConn, aLists[l]).activeMembers(oConn),','));
						    }
				        sGuJob = Gadgets.generateUUID();
				        if (sHtmlText!=null)
									sHtmlText = new HtmlMimeBodyPart(sHtmlText, sEncoding).replacePreffixFromImgSrcs(sWrkGetDir, sTargetDir+File.separator);
				        SendMail.send(oMacc, oProps, sTargetDir,
				        							sHtmlText, sPlainText, sEncoding, aAttachments,
				                      oAdhm.getStringNull(DB.tx_subject,""), oAdhm.getString(DB.tx_email_from),
				                      oAdhm.getStringNull(DB.nm_from, oAdhm.getString(DB.tx_email_from)),
				                      oAdhm.getStringNull(DB.tx_email_reply, oAdhm.getString(DB.tx_email_from)),
				                      oAdhm.getRecipients(), "to", sGuJob,
				                      GlobalDBBind.getProfileName(), oAdhm.getString(DB.nm_mailing)+" ("+String.valueOf(++nBatch)+")",
				                      false, dtExecution, GlobalDBBind);
						  	DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_jobs+" SET "+DB.gu_job_group+"='"+gu_pageset+"' WHERE "+DB.gu_job+"='"+sGuJob+"'");
						  	break;
              
            } // end switch
          } // fi (oMacc!=null)        
        } // fi (sHtmlFile=!null || sPlainFile!=null)
      } // fi (AdHocMailing.exists)
    
    } // fi (id_command==SEND)
    
    oConn.commit();
    oConn.close();
  } catch (FileNotFoundException f) {
    disposeConnection(oConn,"jobstore");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFoundException&desc=" + f.getMessage() + "&resume=_back"));
  
  } catch (SQLException e) {  
    disposeConnection(oConn,"jobstore");
    oConn = null;
    if (e.getLocalizedMessage().equals("Could not find default mail account for current user"))
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume="+Gadgets.URLEncode("../hipermail/account_edit.jsp?bo_popup=true")));
	  else if (e.getLocalizedMessage().equals("Sender address was not set"))
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume="+Gadgets.URLEncode("../webbuilder/adhoc_mailing_edit.jsp?gu_mailing="+gu_pageset+"&gu_workarea="+gu_workarea+"&id_domain="+id_domain)));
	  else
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;  
  oConn = null;

  sendUsageStats(request, "job_store");  
  
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><"+"SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript' SRC='../javascript/xmlhttprequest.js'><"+"/SCRIPT"+">");
  out.write ("<" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
  if (bAsap) {
    out.write ("var sched_info = httpRequestXML('../servlet/HttpSchedulerServlet?action=info'); var sched_stat = getElementText(sched_info.getElementsByTagName('scheduler')[0],'status'); ");
    out.write ("if (sched_stat=='stop' || sched_stat=='stopped') httpRequestXML('../servlet/HttpSchedulerServlet?action=start'); ");
  }
  out.write ("if (window.opener) { window.opener.location='../jobs/job_list.jsp?orderby=5&selected=5&subselected=2&id_command=" + id_command + "&list_title=:%20Batches'; self.close(); } ");
  out.write ("else { document.location = \"../newsletters/newsletter_job_list.jsp?id_command=MAIL\"; }");
  
  out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");

%><%@ include file="../methods/page_epilog.jspf" %>