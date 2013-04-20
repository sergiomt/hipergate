/*
  Copyright (C) 2007  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipermail;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

import java.sql.SQLException;
import java.sql.PreparedStatement;

import java.util.Date;
import java.util.Properties;
import java.util.ArrayList;
import java.util.Arrays;

import javax.mail.MessagingException;
import javax.mail.Message.RecipientType;

import org.apache.oro.text.regex.MalformedPatternException;

import com.oreilly.servlet.MailMessage;

import com.knowgate.acl.ACLUser;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dfs.FileSystem;
import com.knowgate.hipermail.DBMimePart;
import com.knowgate.misc.Gadgets;
import com.knowgate.scheduler.Job;
import com.knowgate.scheduler.SingleThreadExecutor;
import com.knowgate.scheduler.WorkerThreadCallback;

import com.enterprisedt.net.ftp.FTPException;

/**
 * Send a given mail to a recipients list
 * @author Sergio Montoro Ten
 * @version 5.0
 */
public final class SendMail {

    // ------------------------------------------------------------------------

    private static class SystemOutPrintln extends WorkerThreadCallback {

      public SystemOutPrintln() {
        super("SystemOutPrintln");
      }

      public void call(String sThreadId, int iOpCode, String sMessage, Exception oXcpt, Object oParam) {        
        if (iOpCode==WorkerThreadCallback.WT_EXCEPTION) {
          String sStackTrace = "";
          try { sStackTrace = StackTraceUtil.getStackTrace(oXcpt); } catch (Exception ignore) {}
          System.out.println("ERROR "+sMessage+"\n"+sStackTrace);
        } else {
          System.out.println("OK "+oParam);
        }
      } // call
    } // SystemOutPrintln

    private static class DebugOutPrintln extends WorkerThreadCallback {

      public DebugOutPrintln() {
        super("DebugOutPrintln");
      }

      public void call(String sThreadId, int iOpCode, String sMessage, Exception oXcpt, Object oParam) {
        if (-1==iOpCode) {
          String sStackTrace = "";        	
          try { sStackTrace = StackTraceUtil.getStackTrace(oXcpt); } catch (Exception ignore) {}
          DebugFile.writeln("ERROR "+sMessage+"\n"+sStackTrace);
        } else {
          DebugFile.writeln("OK "+oParam);
        }
      } // call
    } // SystemOutPrintln

	private static SystemOutPrintln PRINTLN = new SendMail.SystemOutPrintln();

	private static DebugOutPrintln DEBUGLN = new SendMail.DebugOutPrintln();

    // ------------------------------------------------------------------------

    /**
     * <p>Send an e-mail to a recipients list</p>
     * The message may be sent inmediately by the current thread or asynchronously at the designated date.
     * If parameter sJobTl is <b>null</b> then the message will be send by the current thread.
     * If sJobTl is not <b>null</b> then a new job will be inserted at k_jobs table.
     * A new SingleThreadExecutor will be created if bAutoRunJob parameter is <b>true</b>
     * or if bAutoRunJob is <b>false</b> then the new Job will remain in Pending status until
     * the main Job Scheduler starts running it.
     * 
     * @param oMacc MailAccount used for sending the message
     * @param oSessionProps Properties
     * <table><tr><th>Property</th><th>Description></th><th>Default value</th></tr>
     *        <tr><td>mail.user</td><td>Store and transport user</td><td></td></tr>
     *        <tr><td>mail.password</td><td></td>Store and transport password<td></td></tr>
     *        <tr><td>mail.store.protocol</td><td></td><td>pop3</td></tr>
     *        <tr><td>mail.transport.protocol</td><td></td><td>smtp</td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.host</td><td>For example: pop.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.host</td><td>For example: smtp.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     * </table>
     * @param sUserDir Full path of base directory for mail inline and attached files
     * @param sTextHtml HTML message part, if <b>null</b> then mail body is just plain text
     * @param sTextPlain Plain text message part, if <b>null</b> then mail body is HTML only
     * @param sEncoding Character encoding, see http://java.sun.com/j2se/1.3/docs/guide/intl/encoding.doc.html
     * @param aAttachments Array of attachments file names, without path, they must be under sUserDir base directory
     * @param sSubject Message subject
     * @param sFromAddr Recipient From address
     * @param sFromPersonal Recipient From Display Name
     * @param sReplyAddr Reply-To address
     * @param aRecipients List of recipient addresses
     * @param sRecipientType Recipients Type. Must be of one {to, cc, bcc}
     * @param sId Job or Message GUID If <b>null</b> then an automatically generated 32 characters GUID is assigned
     * @param sEnvCnfFileName Name without extension of properties file to be used for conenction to the database.
     * This parameter is optional and only required when the message must be send by the job scheduler
     * @param sJobTl Job Title. This parameter is optional and only required when the message must be send by the job scheduler
     * @param bAutoRunJob boolean, whether or not a thread must be automatically started for running the Job inmediately.
     * @param dtExecution Date when job must be executed or <b>null</b> if job is in auto run mode or must be executed as soon as possible.
     * @param oGlobalDbb DBBind instance used for accesing the database, if <b>null</b> a new one is created if it is required
     * @return ArrayList of Strings with warnings and errors detected for each recipient.
     * If anything went wrong whilst trying to send message to a recipient, the array list entry starts with
     * the word "ERROR" followed by the recipient e-mail address, a space, and then the error message that describes what happened.
     * If the e-mail was sent sucessfully the the array list entry starts with "OK"
     * @throws FileNotFoundException
     * @throws IOException
     * @throws IllegalArgumentException
     * @throws IllegalAccessException
     * @throws NullPointerException
     * @throws MessagingException
     * @throws FTPException
     * @throws SQLException
     * @throws ClassNotFoundException
     * @throws InstantiationException
     * @since 5.5
     */
	public static ArrayList send(MailAccount oMacc,
								 Properties oSessionProps,
								 final String sUserDir, // Base directory for mail inline and attached files
								 final String sTextHtml, // Mail HTML body
								 final String sTextPlain, // Mail Plain Text body
								 String sEncoding, // Character encoding for body
								 final String aAttachments[],
							     final String sSubject, // Subject,
							     final String sFromAddr,
							     final String sFromPersonal, // Mail From display name
							     String sReplyAddr,
							     final String aRecipients[],
							     String sRecipientType,
							     String sId,
							     String sEnvCnfFileName,
							     String sJobTl,
							     boolean bAutoRunJob,
							     Date dtExecution,
							     DBBind oGlobalDbb
							    )
	 throws FileNotFoundException,IOException,IllegalArgumentException,
	 	    IllegalAccessException,NullPointerException,
	        MessagingException,FTPException,SQLException,
	        ClassNotFoundException,InstantiationException {
	  	
	  if (null==aRecipients) throw new IllegalArgumentException("No recipients list was supplied");
	  if (0==aRecipients.length) throw new IllegalArgumentException("Recipients list is empty");

	  if (DebugFile.trace) {
	    DebugFile.writeln("Begin SendMail.send("+oMacc.getString(DB.gu_account)+","+
	    				  "{mail.smtp.host="+oSessionProps.getProperty("mail.smtp.host","")+","+
	    	              "mail.user="+oSessionProps.getProperty("mail.user","")+","+
	    	              "mail.account="+oSessionProps.getProperty("mail.account","")+","+
	    	              "mail.outgoing="+oSessionProps.getProperty("mail.outgoing","")+","+
	    	              "mail.transport.protocol="+oSessionProps.getProperty("mail.transport.protocol","")+"}, "+
	    				  sUserDir+",text/html, text/plain"+","+
	    	              sEncoding+",String[],\""+sSubject+"\",<"+sFromAddr+">,"+sFromPersonal+",<"+
	    	              sReplyAddr+">,{"+Gadgets.join(aRecipients,";")+"},"+
	    	              sRecipientType+","+sId+","+sEnvCnfFileName+","+sJobTl+",[DBbind])");
	    DebugFile.incIdent();
	  } // fi (trace)

	  if (dtExecution!=null) {
	    if (bAutoRunJob) {
	      if (DebugFile.trace) {
	    	DebugFile.writeln("SendMail.send() execution date must be null if auto run job is true");
	    	DebugFile.decIdent();
	      }
	      throw new IllegalArgumentException("SendMail.send() execution date must be null if auto run job is true");
	    }
	    if (dtExecution.compareTo(new Date())<0) {
	      if (DebugFile.trace) {
		    DebugFile.writeln("SendMail.send() execution date must be after current date");
	    	DebugFile.decIdent();
	      }
	      throw new IllegalArgumentException("SendMail.send() execution date must be after current date");
	    }
	  } // fi (dtExecution)

	  boolean bTestMode = oSessionProps.getProperty("testmode","no").equalsIgnoreCase("yes") || oSessionProps.getProperty("testmode","false").equalsIgnoreCase("true") || oSessionProps.getProperty("testmode","0").equalsIgnoreCase("1");
	  if (bTestMode) {
	    if (DebugFile.trace) DebugFile.writeln("test mode activated no e-mail will be actually sent");
	  }

	  boolean bAttachImages = oSessionProps.getProperty("attachimages","yes").equalsIgnoreCase("yes") || oSessionProps.getProperty("attachimages","true").equalsIgnoreCase("true") || oSessionProps.getProperty("attachimages","1").equalsIgnoreCase("1");
	  boolean bWebBeacon = oSessionProps.getProperty("webbeacon","no").equalsIgnoreCase("yes") || oSessionProps.getProperty("webbeacon","false").equalsIgnoreCase("true") || oSessionProps.getProperty("webbeacon","0").equalsIgnoreCase("1");
	  boolean bClickThrough = oSessionProps.getProperty("clickthrough","no").equalsIgnoreCase("yes") || oSessionProps.getProperty("clickthrough","false").equalsIgnoreCase("true") || oSessionProps.getProperty("clickthrough","0").equalsIgnoreCase("1");

	  if (bWebBeacon && oSessionProps.getProperty("webserver")==null) {
	    if (DebugFile.trace) {
		  DebugFile.writeln("SendMail.send() If webbeacon property is true then webserver property is required");
	      DebugFile.decIdent();
	    }
	    throw new NullPointerException("SendMail.send() If webbeacon property is true then webserver property is required");
	  }

	  if (bClickThrough && oSessionProps.getProperty("webserver")==null) {
	    if (DebugFile.trace) {
		  DebugFile.writeln("SendMail.send() If webbeacon property is true then webserver property is required");
	      DebugFile.decIdent();
	    }
	    throw new NullPointerException("SendMail.send() If clickthrough property is true then webserver property is required");
	  }

	  DBBind oDbb;
	  ArrayList<String> aWarnings = new ArrayList<String>();

	  // *******************************************
	  // Setup default values for missing parameters
	   	  
	  if (null==oSessionProps) oSessionProps=oMacc.getProperties();
 	  if (null==sEncoding) sEncoding = "UTF-8";
	  if (null==sReplyAddr) sReplyAddr = sFromAddr;
	  if (null==sRecipientType) sRecipientType = "to";
	  if (null==sId) sId = Gadgets.generateUUID();
	  if (null==sEnvCnfFileName) sEnvCnfFileName = "hipergate";
	  if (null==sJobTl) sJobTl = "";

	  final int nRecipients = aRecipients.length;

	  if (DebugFile.trace) DebugFile.writeln("recipient count is "+String.valueOf(nRecipients));
	  
	  // Remove blank spaces, tabs and carriage return characters from e-mail address
	  // end make a limited attempt to extract a sanitized email address
	  // prefer text in <brackets>, ignore anything in (parentheses)
	  for (int r=0; r<nRecipients; r++) {
		aRecipients[r] = MailMessage.sanitizeAddress(Gadgets.removeChars(aRecipients[r], " \t\r"));
		if (!Gadgets.checkEMail(aRecipients[r])) {
		  if (DebugFile.trace) DebugFile.writeln("ERROR "+aRecipients[r]+" at line "+String.valueOf(r+1)+" is not a valid e-mail address");
		  aWarnings.add(aRecipients[r]+" at line "+String.valueOf(r+1)+" is not a valid e-mail address");
		}
	  }
	  		  	
	  // Get mail from address
	  if (!Gadgets.checkEMail(sFromAddr)) {
		aWarnings.add(sFromAddr+" is not a valid from e-mail address");
	  }
	  
	  // Get mail reply-to address
	  if (!Gadgets.checkEMail(sReplyAddr)) {
	    aWarnings.add(sReplyAddr+" is not a valid reply-to e-mail address");
	  }
	  
	  RecipientType oRecType;
	  if (sRecipientType.equalsIgnoreCase("cc"))
	    oRecType = RecipientType.CC;
	  else if (sRecipientType.equalsIgnoreCase("bcc"))
	    oRecType = RecipientType.BCC;
	  else if (sRecipientType.equalsIgnoreCase("to"))
		oRecType = RecipientType.TO;
	  else
	  	throw new MessagingException(sRecipientType+" is not a valid recipient type");

	  if (sJobTl.length()>0) {
		if (DebugFile.trace) DebugFile.writeln("Processing job "+sJobTl);

		if (null==oGlobalDbb)
		  oDbb = new DBBind(sEnvCnfFileName);
		else
		  oDbb = oGlobalDbb;
		  
		JDCConnection oCon = null;
		try {

	      if (DebugFile.trace) DebugFile.writeln("getting JDCConnection from pool");

	      Job oSnd;
		  DBPersist oJob = new DBPersist(DB.k_jobs,"Job");
		  oCon = oDbb.getConnection("SendMail",false);
		  oCon.setAutoCommit(false);

		  ACLUser oUsr = new ACLUser(oCon, oMacc.getString(DB.gu_user));

		  String sJobId = Job.getIdFromTitle(oCon, sJobTl, oUsr.getString(DB.gu_workarea));

		  if (null==sJobId) {
		    if (DebugFile.trace) DebugFile.writeln("Job "+sJobTl+" not found, creating a new one...");
			
			if (oMacc.isNull(DB.gu_account)) {
			  if (DebugFile.trace) DebugFile.decIdent();
		      throw new SQLException("No MailAccount found for user "+oUsr.getString(DB.gu_user),"01S06");			  
			}

		  	String sMBoxDir = DBStore.MBoxDirectory(oDbb.getProfileName(),oUsr.getInt(DB.id_domain),oUsr.getString(DB.gu_workarea));

		    if (DebugFile.trace) DebugFile.writeln("mbox directory is "+sMBoxDir);

    		SessionHandler oHndl = new SessionHandler(oMacc,sMBoxDir);
    		DBStore oRDBMS = DBStore.open(oHndl.getSession(), oDbb.getProfileName(), sMBoxDir, oUsr.getString(DB.gu_user), oUsr.getString(DB.tx_pwd));
			DBFolder oOutbox = oRDBMS.openDBFolder("outbox",DBFolder.READ_WRITE);

			if (DebugFile.trace) DebugFile.writeln("creating draft");
			
			DBMimeMessage oMsg = DraftsHelper.draftMessage(oOutbox, oMacc.getString(DB.outgoing_server),
														   oUsr.getString(DB.gu_workarea),
														   oUsr.getString(DB.gu_user),
														   sTextHtml==null ? "plain" : "html");

			String sMsgId = oMsg.getContentID();

    		if (null==sMsgId) throw new NullPointerException("MIME message identifier could not be set for message with GUID "+oMsg.getMessageGuid());

    		DraftsHelper.draftUpdate(oCon, oUsr.getInt(DB.id_domain),
    								 oUsr.getString(DB.gu_workarea),
    								 oMsg.getMessageGuid(), sMsgId,
                             	     sFromAddr,sReplyAddr,sFromPersonal,
                             	     sSubject,
                             	     "text/"+(sTextHtml==null ? "plain" : "html")+";charset="+sEncoding,
                             	     sTextHtml==null ? sTextPlain : sTextHtml,
                             	     null, null, null);

			if (aAttachments!=null) {
			  if (DebugFile.trace) DebugFile.writeln("adding attachments");
    		  Integer oPart = DBCommand.queryMaxInt(oCon, DB.id_part, DB.k_mime_parts, DB.gu_mimemsg+"='"+oMsg.getMessageGuid()+"'");
    		  if (oPart==null) oPart = new Integer(1);
    		  PreparedStatement oStm = oCon.prepareStatement("INSERT INTO " + DB.k_mime_parts + "("+DB.gu_mimemsg+","+DB.id_message+","+DB.id_part+","+DB.id_disposition+","+DB.id_content+","+DB.id_type+","+DB.len_part+","+DB.de_part+","+DB.file_name+") VALUES ('"+oMsg.getMessageGuid()+"',?,?,'reference',?,?,?,?,?)");
			  for (int p=0; p<aAttachments.length; p++) {
	      	    String sFilePath = Gadgets.chomp(sUserDir,File.separator)+aAttachments[p];
	      	    File oAttach = new File(sFilePath);
	      	    if (oAttach.exists()) {
	      	      oStm.setString(1, sMsgId);
                  oStm.setInt(2, oPart.intValue()+p);
	      		  oStm.setString(3, DBMimePart.getMimeType(oCon,aAttachments[p]));        
	      		  oStm.setString(4, DBMimePart.getMimeType(oCon,aAttachments[p]));        
        		  oStm.setInt(5, (int) oAttach.length());
	      		  oStm.setString(6, aAttachments[p]);
	      		  oStm.setString(7, sFilePath);	
	  			  if (DebugFile.trace) DebugFile.writeln("INSERT INTO " + DB.k_mime_parts + "("+DB.gu_mimemsg+","+DB.id_message+","+DB.id_part+","+DB.id_disposition+","+DB.id_content+","+DB.id_type+","+DB.len_part+","+DB.de_part+","+DB.file_name+") VALUES ('"+oMsg.getMessageGuid()+"','"+sMsgId+"',"+String.valueOf(oPart.intValue()+p)+",'reference',?,?,?,?,'"+sFilePath+"')");
	      		  oStm.executeUpdate();
	      	    } // fi
			  } // next
			  oStm.close();	
			} // fi

			sJobId = (sId.length()==32 ? sId : Gadgets.generateUUID());
		  	oJob.put(DB.gu_job, sJobId);
		    oJob.put(DB.gu_workarea, oUsr.getString(DB.gu_workarea));
		    oJob.put(DB.gu_writer, oUsr.getString(DB.gu_user));
		    oJob.put(DB.id_command, Job.COMMAND_SEND);
		    oJob.put(DB.id_status, bAutoRunJob ? Job.STATUS_SUSPENDED : Job.STATUS_PENDING);
		    oJob.put(DB.tl_job, sJobTl);
		    oJob.put(DB.tx_parameters, (bTestMode ? "testmode:true," : "")+
		    	                       "message:"+oMsg.getMessageGuid()+","+
		    	                       "id:"+sMsgId+","+
		    	                       "profile:"+oDbb.getProfileName()+","+
		    	                       "account:"+oMacc.getString(DB.gu_account)+","+
		    	                       "personalized:true"+","+
		    	                       "attachimages:"+(bAttachImages ? "true" : "false")+","+
		    	                       "clickthrough:"+(bClickThrough ? "true" : "false")+","+
		    	                       "webbeacon:"+(bWebBeacon ? "true" : "false")+","+
		    	                       "webserver:"+oSessionProps.getProperty("webserver")+","+
		    	                       "encoding:"+sEncoding);
		    if (dtExecution!=null) oJob.put(DB.dt_execution, dtExecution);
			if (DebugFile.trace) DebugFile.writeln("storing job "+sJobId+" "+oJob.getString(DB.tx_parameters));
		    oJob.store(oCon);

			DBCommand.executeUpdate(oCon, "UPDATE "+DB.k_mime_msgs+" SET "+DB.gu_job+"='"+sJobId+"' WHERE "+DB.gu_mimemsg+"='"+oMsg.getMessageGuid()+"'");

			if (DebugFile.trace) DebugFile.writeln("instantiating job "+sJobId);

			oSnd = Job.instantiate(oCon, sJobId, oDbb.getProperties());
		    
			if (DebugFile.trace)
			  if (null==aRecipients)
				DebugFile.writeln("ERROR recipients list is null");
			  else
			    DebugFile.writeln("inserting "+String.valueOf(aRecipients)+" recipients ");

			oSnd.insertRecipients(oCon, aRecipients, sRecipientType,
		                          sTextHtml==null ? "text" : "html",
		                          Job.STATUS_PENDING);
			
		  } else {

		    if (DebugFile.trace) DebugFile.writeln("Job "+sJobTl+" found with GUID "+sJobId);

			if (DebugFile.trace) DebugFile.writeln("instantiating job "+sJobId);

			oSnd = Job.instantiate(oCon, sJobId, oDbb.getProperties());		    		  	

			if (DebugFile.trace)
				  if (null==aRecipients)
					DebugFile.writeln("ERROR recipients list is null");
				  else
				    DebugFile.writeln("inserting "+String.valueOf(aRecipients)+" recipients ");

			oSnd.insertRecipients(oCon, aRecipients, sRecipientType,
		                          sTextHtml==null ? "text" : "html",
		                          Job.STATUS_PENDING);
		  }
		  oCon.commit();
		  oCon.close("SendMail");
		  oCon = null;
		  
		  if (bAutoRunJob) {
		    SingleThreadExecutor oSte = new SingleThreadExecutor(oDbb, sJobId);
		    oSte.registerCallback(SendMail.DEBUGLN);
		    oSte.registerCallback(SendMail.PRINTLN);
		    oSte.run();		  
		  } // bAutoRunJob
		  
		} catch (SQLException sqle) {
		  if (DebugFile.trace) DebugFile.writeln("SQLException "+sqle.getMessage());
	      aWarnings.add("SQLException "+sqle.getMessage());
		  if (null!=oCon) {
		    if (!oCon.isClosed()) {
		      if (!oCon.getAutoCommit()) oCon.rollback();
		      oCon.close("SendMail");
		    }
		    oCon = null;
		  }
		  if (null==oGlobalDbb && null!=oDbb) oDbb.close();
		  oDbb = null;
	    }
	  } else {
	    SessionHandler oSssnHndlr = new SessionHandler(oSessionProps);
		ByteArrayOutputStream oByteOutStrm = new ByteArrayOutputStream();
		PrintStream oPrntStrm = new PrintStream(oByteOutStrm);
		for (int r=0; r<nRecipients; r++) {
	      oSssnHndlr.sendMessage(sSubject, sFromPersonal, sFromAddr, sReplyAddr,
	                             new String[]{aRecipients[r]}, oRecType,
	                             sTextPlain, sTextHtml, sEncoding,
	                             sId, aAttachments, sUserDir, oPrntStrm);
		  if (oByteOutStrm.size()>0) {
		    aWarnings.add(aRecipients[r]+" "+oByteOutStrm.toString());
		    oByteOutStrm.reset();
		  }
		} // next
		oPrntStrm.close();
	    oSssnHndlr.close();	  	
	  }// fi (sJobTl)

	  if (DebugFile.trace) {
	  	for (String w : aWarnings) {
	  	  DebugFile.writeln(w);
	  	}
	    DebugFile.decIdent();
	    DebugFile.writeln("End SendMail.send()");
	  }
	  return aWarnings;
	} // send

    // ------------------------------------------------------------------------

    /**
     * <p>Send an e-mail to a recipients list</p>
     * The message may be sent inmediately by the current thread or asynchronously as soon as possible.
     * If parameter sJobTl is <b>null</b> then the message will be send by the current thread.
     * If sJobTl is not <b>null</b> then a new job will be inserted at k_jobs table.
     * A new SingleThreadExecutor will be created if bAutoRunJob parameter is <b>true</b>
     * or if bAutoRunJob is <b>false</b> then the new Job will remain in Pending status until
     * the main Job Scheduler starts running it.
     * 
     * @param oMacc MailAccount used for sending the message
     * @param oSessionProps Properties
     * <table><tr><th>Property</th><th>Description></th><th>Default value</th></tr>
     *        <tr><td>mail.user</td><td>Store and transport user</td><td></td></tr>
     *        <tr><td>mail.password</td><td></td>Store and transport password<td></td></tr>
     *        <tr><td>mail.store.protocol</td><td></td><td>pop3</td></tr>
     *        <tr><td>mail.transport.protocol</td><td></td><td>smtp</td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.host</td><td>For example: pop.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.host</td><td>For example: smtp.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     * </table>
     * @param sUserDir Full path of base directory for mail inline and attached files
     * @param sTextHtml HTML message part, if <b>null</b> then mail body is just plain text
     * @param sTextPlain Plain text message part, if <b>null</b> then mail body is HTML only
     * @param sEncoding Character encoding, see http://java.sun.com/j2se/1.3/docs/guide/intl/encoding.doc.html
     * @param aAttachments Array of attachments file names, without path, they must be under sUserDir base directory
     * @param sSubject Message subject
     * @param sFromAddr Recipient From address
     * @param sFromPersonal Recipient From Display Name
     * @param sReplyAddr Reply-To address
     * @param aRecipients List of recipient addresses
     * @param sRecipientType Recipients Type. Must be of one {to, cc, bcc}
     * @param sId Job or Message GUID If <b>null</b> then an automatically generated 32 characters GUID is assigned
     * @param sEnvCnfFileName Name without extension of properties file to be used for conenction to the database.
     * This parameter is optional and only required when the message must be send by the job scheduler
     * @param sJobTl Job Title. This parameter is optional and only required when the message must be send by the job scheduler
     * @param bAutoRunJob boolean, whether or not a thread must be automatically started for running the Job inmediately.
     * @param oGlobalDbb DBBind instance used for accesing the database, if <b>null</b> a new one is created if it is required
     * @return ArrayList of Strings with warnings and errors detected for each recipient.
     * If anything went wrong whilst trying to send message to a recipient, the array list entry starts with
     * the word "ERROR" followed by the recipient e-mail address, a space, and then the error message that describes what happened.
     * If the e-mail was sent sucessfully the the array list entry starts with "OK"
     * @throws FileNotFoundException
     * @throws IOException
     * @throws IllegalAccessException
     * @throws NullPointerException
     * @throws MessagingException
     * @throws FTPException
     * @throws SQLException
     * @throws ClassNotFoundException
     * @throws InstantiationException
     */
	public static ArrayList send(MailAccount oMacc,
								 Properties oSessionProps,
								 String sUserDir, // Base directory for mail inline and attached files
					   	         final String sTextHtml, // Mail HTML body
					   	         final String sTextPlain, // Mail Plain Text body
							     String sEncoding, // Character encoding for body
							     String aAttachments[],
							     String sSubject, // Subject,
							     String sFromAddr,
							     String sFromPersonal, // Mail From display name
							     String sReplyAddr,
							     String aRecipients[],
							     String sRecipientType,
						         String sId,
							     String sEnvCnfFileName,
							     String sJobTl,
							     boolean bAutoRunJob,
							     DBBind oGlobalDbb)

	   throws FileNotFoundException,IOException,
	 	      IllegalAccessException,NullPointerException,
	          MessagingException,FTPException,SQLException,
	          ClassNotFoundException,InstantiationException {

       return send (oMacc, oSessionProps, sUserDir, sTextHtml, sTextPlain, sEncoding,
				    aAttachments, sSubject, sFromAddr, sFromPersonal, sReplyAddr,
				    aRecipients, sRecipientType, sId, sEnvCnfFileName,
				    sJobTl, bAutoRunJob, null, oGlobalDbb);
    }

    // ------------------------------------------------------------------------

    /**
     * <p>Send an e-mail to a recipients list</p>
     * The message may be sent inmediately by the current thread or
     * asynchronously by a new instance of com.knowgate.scheduler.SingleThreadExecutor
     * that will be created on the fly. If parameter sJobTl is <b>null</b> then the message
     * will be send by the current thread. If sJobTl is not <b>null</b> then a new job
     * will be inserted at k_jobs table and a new SingleThreadExecutor will be started to execute it.
     * 
     * @param oSessionProps Properties
     * <table><tr><th>Property</th><th>Description></th><th>Default value</th></tr>
     *        <tr><td>mail.user</td><td>Store and transport user</td><td></td></tr>
     *        <tr><td>mail.password</td><td></td>Store and transport password<td></td></tr>
     *        <tr><td>mail.store.protocol</td><td></td><td>pop3</td></tr>
     *        <tr><td>mail.transport.protocol</td><td></td><td>smtp</td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.host</td><td>For example: pop.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.host</td><td>For example: smtp.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     * </table>
     * @param sUserDir Full path of base directory for mail inline and attached files
     * @param sTextHtml HTML message part, if <b>null</b> then mail body is just plain text
     * @param sTextPlain Plain text message part, if <b>null</b> then mail body is HTML only
     * @param sEncoding Character encoding, see http://java.sun.com/j2se/1.3/docs/guide/intl/encoding.doc.html
     * @param aAttachments Array of attachments file names, without path, they must be under sUserDir base directory
     * @param sSubject Message subject
     * @param sFromAddr Recipient From address
     * @param sFromPersonal Recipient From Display Name
     * @param sReplyAddr Reply-To address
     * @param aRecipients List of recipient addresses
     * @param sRecipientType Recipients Type. Must be of one {to, cc, bcc}
     * @param sId Job or Message GUID If <b>null</b> then an automatically generated 32 characters GUID is assigned
     * @param sEnvCnfFileName Name without extension of properties file to be used for conenction to the database.
     * This parameter is optional and only required when the message must be send by the job scheduler
     * @param sJobTl Job Title. This parameter is optional and only required when the message must be send by the job scheduler
     * @param oGlobalDbb DBBind instance used for accesing the database, if <b>null</b> a new one is created if it is required
     * @return ArrayList of Strings with warnings and errors detected for each recipient.
     * If anything went wrong whilst trying to send message to a recipient, the array list entry starts with
     * the word "ERROR" followed by the recipient e-mail address, a space, and then the error message that describes what happened.
     * If the e-mail was sent sucessfully the the array list entry starts with "OK"
     * @throws FileNotFoundException
     * @throws IOException
     * @throws IllegalAccessException
     * @throws NullPointerException
     * @throws MessagingException
     * @throws FTPException
     * @throws SQLException
     * @throws ClassNotFoundException
     * @throws InstantiationException
     */
	public static ArrayList send(Properties oSessionProps,
								 final String sUserDir, // Base directory for mail inline and attached files
					   	         final String sTextHtml, // Mail HTML body
					   	         final String sTextPlain, // Mail Plain Text body
							     String sEncoding, // Character encoding for body
							     String aAttachments[],
							     String sSubject, // Subject,
							     String sFromAddr,
							     String sFromPersonal, // Mail From display name
							     String sReplyAddr,
							     String aRecipients[],
							     String sRecipientType,
						         String sId,
							     String sEnvCnfFileName,
							     String sJobTl,
							     DBBind oGlobalDbb
							    )
	 throws FileNotFoundException,IOException,
	 	    IllegalAccessException,NullPointerException,
	        MessagingException,FTPException,SQLException,
	        ClassNotFoundException,InstantiationException {
	  	
	  if (DebugFile.trace) {
	    DebugFile.writeln("Begin SendMail.send("+
	    				  "{mail.smtp.host="+oSessionProps.getProperty("mail.smtp.host","")+","+
	    	              "mail.user="+oSessionProps.getProperty("mail.user","")+","+
	    	              "mail.account="+oSessionProps.getProperty("mail.account","")+","+
	    	              "mail.outgoing="+oSessionProps.getProperty("mail.outgoing","")+","+
	    	              "mail.transport.protocol="+oSessionProps.getProperty("mail.transport.protocol","")+"}, "+
	    				  sUserDir+",text/html, text/plain"+","+
	    	              sEncoding+",String[],\""+sSubject+"\",<"+sFromAddr+">,"+sFromPersonal+",<"+
	    	              sReplyAddr+">,"+(aRecipients==null ? null : "{"+Gadgets.join(aRecipients,";")+"}")+","+
	    	              sRecipientType+","+sId+","+sEnvCnfFileName+","+sJobTl+",[DBbind])");
	    DebugFile.incIdent();
	  } // fi (trace)

	  DBBind oDbb;

	  if (null==oGlobalDbb)
	    oDbb = new DBBind(sEnvCnfFileName==null ? "hipergate" : sEnvCnfFileName);
	  else
		oDbb = oGlobalDbb;

	  JDCConnection oCon = oDbb.getConnection("SendMail_RO1", false);
	  
	  String sUserId = ACLUser.getIdFromEmail(oCon,sFromAddr);
	  if (sUserId==null) {
	  	oCon.close("SendMail_RO1");
	    if (DebugFile.trace) DebugFile.decIdent();
		throw new SQLException(sFromAddr+" e-mail address not found at k_users table","01S06");
	  }

	  ACLUser oUsr = new ACLUser(oCon, sUserId);

	  MailAccount oMacc = MailAccount.forUser(oCon, oUsr.getString(DB.gu_user), oDbb.getProperties());
	  if (null==oMacc) {
	  	oCon.close("SendMail_RO1");
	    if (DebugFile.trace) DebugFile.decIdent();
		throw new SQLException("No default e-mail account found for user "+oUsr.getString(DB.gu_user),"01S06");
	  }

	  oCon.close("SendMail_RO1");
	  
	  if (DebugFile.trace) DebugFile.writeln("Ready to send message "+sSubject);
	  
	  ArrayList aWarnings = send(oMacc, oSessionProps,
								 sUserDir, sTextHtml, sTextPlain, sEncoding,
							     aAttachments, sSubject,
							     sFromAddr, sFromPersonal, sReplyAddr,
							     aRecipients, sRecipientType,
						         sId, oDbb.getProfileName(), sJobTl, true, oDbb);

	  if (DebugFile.trace) {
	    DebugFile.decIdent();
	    DebugFile.writeln("End SendMail.send()");
	  }
	  return aWarnings;
	} // send

    // ------------------------------------------------------------------------

	public static ArrayList send(Properties oSessionProps,
								 final String sUserDir,
					   	         final String sTextHtml,
					   	         final String sTextPlain,
							     String sEncoding,
							     String aAttachments[],
							     String sSubject,
							     String sFromAddr,
							     String sFromPersonal, 
							     String sReplyAddr,
							     String aRecipients[],
							     String sRecipientType,
						         String sId,
							     String sEnvCnfFileName,
							     String sJobTl
							    )
	  throws FileNotFoundException,IOException,
	 	    IllegalAccessException,NullPointerException,
	        MessagingException,FTPException,SQLException,
	        ClassNotFoundException,InstantiationException {
	  return send(oSessionProps,sUserDir,sTextHtml,sTextPlain,sEncoding,aAttachments,sSubject,sFromAddr,sFromPersonal,sReplyAddr,aRecipients,sRecipientType,sId,sEnvCnfFileName,sJobTl,null);
	}

    // ------------------------------------------------------------------------

	public static ArrayList send(Properties oSessionProps,
								 final String sUserDir, // Base directory for mail inline and attached files
					   	         final String sTextHtml, // Mail HTML body
					   	         final String sTextPlain, // Mail Plain Text body
							     String sEncoding, // Character encoding for body
							     String aAttachments[],
							     String sSubject, // Subject,
							     String sFromAddr,
							     String sFromPersonal, // // Mail From display name
							     String sReplyAddr,
							     String aRecipientsTo[],
							     String aRecipientsCc[],
							     String aRecipientsBcc[],
						         String sId
							    )
	 throws FileNotFoundException,IOException,
	 	    IllegalAccessException,NullPointerException,
	        MessagingException,FTPException,SQLException,
	        ClassNotFoundException,InstantiationException {
	  	
	  if (DebugFile.trace) {
	    DebugFile.incIdent();
	    DebugFile.writeln("Begin SendMail.send([Properties],"+sUserDir+",text/html,text/plain,"+
	    				  sEncoding+",String[],"+sSubject+","+sFromAddr+","+sFromPersonal+","+
	    				  sReplyAddr+","+
	    				  (aRecipientsTo==null ? "null" : "{"+Gadgets.join(aRecipientsTo,";")+"}")+","+
	    				  (aRecipientsCc==null ? "null" : "{"+Gadgets.join(aRecipientsCc,";")+"}")+","+
	    				  (aRecipientsBcc==null ? "null" : "{"+Gadgets.join(aRecipientsBcc,";")+"}")+","+
	    				  sId+")");
	  } // fi (trace)

	  ArrayList<String> aWarnings = new ArrayList<String>();
	  
	  // *******************************************
	  // Setup default values for missing parameters
	   	  
 	  if (null==sEncoding) sEncoding = "ISO8859_1";
	  if (null==sReplyAddr) sReplyAddr = sFromAddr;
	  if (null==sId) sId = Gadgets.generateUUID();
	  
	  int nRecipients = 0;
	  if (aRecipientsTo!=null) nRecipients+=aRecipientsTo.length;
	  if (aRecipientsCc!=null) nRecipients+=aRecipientsCc.length;
	  if (aRecipientsBcc!=null) nRecipients+=aRecipientsBcc.length;
	  if (DebugFile.trace) DebugFile.writeln("recipient count is "+String.valueOf(nRecipients));
	  String aRecipients[] = new String[nRecipients];
	  RecipientType aRecTypes[] = new RecipientType[nRecipients];
	  int iRecipient=0;
	  	
	  // Remove blank spaces, tabs and carriage return characters from e-mail address
	  // end make a limited attempt to extract a sanitized email address
	  // prefer text in <brackets>, ignore anything in (parentheses)
	  if (aRecipientsTo!=null) {
	    for (int r=0; r<aRecipientsTo.length; r++) {
		  aRecipients[iRecipient] = MailMessage.sanitizeAddress(Gadgets.removeChars(aRecipientsTo[r], " \t\r"));
		  aRecTypes[iRecipient] = RecipientType.TO;
		  if (!Gadgets.checkEMail(aRecipients[iRecipient])) {
		    if (DebugFile.trace) DebugFile.writeln("ERROR "+aRecipientsTo[r]+" at line "+String.valueOf(r+1)+" is not a valid e-mail address");
		    aWarnings.add(aRecipientsTo[r]+" at line "+String.valueOf(r+1)+" is not a valid e-mail address");
		  } // fi
		  iRecipient++;
	    } // next
	  } // fi
	  if (aRecipientsCc!=null) {
	    for (int r=0; r<aRecipientsCc.length; r++) {
		  aRecipients[iRecipient] = MailMessage.sanitizeAddress(Gadgets.removeChars(aRecipientsCc[r], " \t\r"));
		  aRecTypes[iRecipient] = RecipientType.CC;
		  if (!Gadgets.checkEMail(aRecipients[iRecipient])) {
		    if (DebugFile.trace) DebugFile.writeln("ERROR "+aRecipientsTo[r]+" at line "+String.valueOf(r+1)+" is not a valid e-mail address");
		    aWarnings.add(aRecipientsCc[r]+" at line "+String.valueOf(r+1)+" is not a valid cc e-mail address");
		  } // fi
		  iRecipient++;
	    } // next
	  } // fi
	  if (aRecipientsBcc!=null) {
	    for (int r=0; r<aRecipientsBcc.length; r++) {
		  aRecipients[iRecipient] = MailMessage.sanitizeAddress(Gadgets.removeChars(aRecipientsBcc[r], " \t\r"));
		  aRecTypes[iRecipient] = RecipientType.BCC;
		  if (!Gadgets.checkEMail(aRecipients[iRecipient])) {
		    if (DebugFile.trace) DebugFile.writeln("ERROR "+aRecipientsBcc[r]+" at line "+String.valueOf(r+1)+" is not a valid e-mail address");
		    aWarnings.add(aRecipientsBcc[r]+" at line "+String.valueOf(r+1)+" is not a valid bcc e-mail address");
		  } // fi
		  iRecipient++;
	    } // next
	  } // fi	  
	  	
	  // Get mail from address
	  if (!Gadgets.checkEMail(sFromAddr)) {
		aWarnings.add(sFromAddr+" is not a valid from e-mail address");
	  }
	  
	  // Get mail reply-to address
	  if (!Gadgets.checkEMail(sReplyAddr)) {
	    aWarnings.add(sReplyAddr+" is not a valid reply-to e-mail address");
	  }
	  	  
	  
	  SessionHandler oSssnHndlr = new SessionHandler(oSessionProps);
	  ByteArrayOutputStream oByteOutStrm = new ByteArrayOutputStream();
	  PrintStream oPrntStrm = new PrintStream(oByteOutStrm);
	  oSssnHndlr.sendMessage(sSubject, sFromPersonal, sFromAddr, sReplyAddr,
	                         aRecipients, aRecTypes,
	                         sTextPlain, sTextHtml, sEncoding,
	                         sId, aAttachments, sUserDir, oPrntStrm);
	  if (oByteOutStrm.size()>0) {
		  aWarnings.add(oByteOutStrm.toString());
		  oByteOutStrm.reset();
	  }
	  oPrntStrm.close();
	  oSssnHndlr.close();	  	

	  if (DebugFile.trace) {
	  	for (String w : aWarnings) {
	  	  DebugFile.writeln(w);
	  	}
	    DebugFile.decIdent();
	    DebugFile.writeln("End SendMail.send()");
	  }
	  return aWarnings;
	} // send


    // ------------------------------------------------------------------------

    /**
     * <p>Send a plain text message to a given recipients list</p>
     * The message will be sent inmediately indipendently to each recipient
     * @param oSessionProps Properties
     * <table><tr><th>Property</th><th>Description></th><th>Default value</th></tr>
     *        <tr><td>mail.user</td><td>Store and transport user</td><td></td></tr>
     *        <tr><td>mail.password</td><td></td>Store and transport password<td></td></tr>
     *        <tr><td>mail.store.protocol</td><td></td><td>pop3</td></tr>
     *        <tr><td>mail.transport.protocol</td><td></td><td>smtp</td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.host</td><td>For example: pop.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.host</td><td>For example: smtp.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     * </table>
     * @param sTextPlain Plain text message part
     * @param sSubject Message subject
     * @param sFromAddr Recipient From address
     * @param sFromPersonal Recipient From Display Name
     * @param sReplyAddr Reply-To address
     * @param aRecipients List of recipient addresses
     */
 
	public static ArrayList send(Properties oSessionProps,
								 String sTextPlain,
								 String sSubject,
							     String sFromAddr,
							     String sFromPersonal, 
							     String sReplyAddr,
							     String aRecipients[])
      throws IOException,IllegalAccessException,NullPointerException,
             MessagingException,SQLException,ClassNotFoundException,InstantiationException {

	  if (DebugFile.trace) {
	    DebugFile.writeln("SendMail.send({mail.smtp.host="+oSessionProps.getProperty("mail.smtp.host","")+","+
	    	                             "mail.user="+oSessionProps.getProperty("mail.user","")+","+
	    	                             "mail.account="+oSessionProps.getProperty("mail.account","")+","+
	    	                             "mail.outgoing="+oSessionProps.getProperty("mail.outgoing","")+"},"+
	    	                             "mail.transport.protocol="+oSessionProps.getProperty("mail.transport.protocol","")+","+
	    	                             "\""+Gadgets.left(sTextPlain,80).replace('\n',' ')+"\", \""+sSubject+"\", "+
	    	                             sFromAddr+", \""+sFromPersonal+"\", "+sReplyAddr+", {"+
	    	                             Gadgets.join(aRecipients,",")+"})");
        DebugFile.incIdent();
	  }

	  final String StrNull = null;
	  final String ArrNull[] = null;

	  if (null==sSubject) sSubject = "";
	  if (null==sTextPlain) sTextPlain = "";
	  if (null==sFromPersonal) sFromPersonal = sFromAddr;
	  if (null==sReplyAddr) sReplyAddr = sFromAddr;
	  ArrayList oRetMsgs = null;
	  try {
	    oRetMsgs = send(oSessionProps, StrNull, StrNull, sTextPlain, "UTF-8", ArrNull, sSubject, sFromAddr, sFromPersonal, sReplyAddr, aRecipients, "to", StrNull, StrNull, StrNull);
	  } catch (FileNotFoundException neverthrown) {}
	    catch (FTPException neverthrown) {}

	  if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End SendMail.send()");
	  }

      return oRetMsgs;
    } // send

    // ------------------------------------------------------------------------

    /**
     * <p>Send a plain text message to a given recipients list</p>
     * The message will be sent inmediately indipendently to each recipient
     * @param oDbb DBBind Session properties will be taken from the .cnf file of this DBBind
     * @param sTextPlain Plain text message part
     * @param sSubject Message subject
     * @param sFromAddr Recipient From address
     * @param sFromPersonal Recipient From Display Name
     * @param sReplyAddr Reply-To address
     * @param aRecipients List of recipient addresses
	 * @return ArrayList of Strings with status messages about each message sent
	 * @throws IOException
	 * @throws IllegalAccessException
	 * @throws NullPointerException
	 * @throws MessagingException
	 * @throws SQLException
	 * @throws ClassNotFoundException
	 * @throws InstantiationException
     * @since 7.0
     */
 
	public static ArrayList send(DBBind oDbb,
								 String sTextPlain,
								 String sSubject,
							     String sFromAddr,
							     String sFromPersonal, 
							     String sReplyAddr,
							     String aRecipients[])
      throws IOException,IllegalAccessException,NullPointerException,
             MessagingException,SQLException,ClassNotFoundException,InstantiationException {

	  if (DebugFile.trace) {
	    DebugFile.writeln("SendMail.send({mail.smtp.host="+oDbb.getProperty("mail.smtp.host","")+","+
	    	                             "mail.user="+oDbb.getProperty("mail.user","")+","+
	    	                             "mail.account="+oDbb.getProperty("mail.account","")+","+
	    	                             "mail.outgoing="+oDbb.getProperty("mail.outgoing","")+"},"+
	    	                             "mail.transport.protocol="+oDbb.getProperty("mail.transport.protocol","")+","+
	    	                             "\""+Gadgets.left(sTextPlain,80).replace('\n',' ')+"\", \""+sSubject+"\", "+
	    	                             sFromAddr+", \""+sFromPersonal+"\", "+sReplyAddr+", {"+
	    	                             Gadgets.join(aRecipients,",")+"})");
        DebugFile.incIdent();
	  }

	  final String StrNull = null;
	  final String ArrNull[] = null;

	  if (null==sSubject) sSubject = "";
	  if (null==sTextPlain) sTextPlain = "";
	  if (null==sFromPersonal) sFromPersonal = sFromAddr;
	  if (null==sReplyAddr) sReplyAddr = sFromAddr;
	  ArrayList oRetMsgs = null;
	  JDCConnection oConn = null;
	  
	  try {

		oConn = oDbb.getConnection("SendMail.send",true);		
		String sUser = ACLUser.getIdFromEmail(oConn, sFromAddr);
	    if (null==sUser) {
	      oConn.close("SendMail.send");
		  oConn=null;
		  throw new SQLException(sFromAddr+" e-mail address was not found at k_users table");
		} else {
		  MailAccount oMacc = MailAccount.forUser(oConn, sUser, oDbb.getProperties());		
	      oConn.close("SendMail.send");
		  oConn=null;
		  oRetMsgs = send(oMacc, oMacc.getProperties(), StrNull, StrNull, sTextPlain, "UTF-8", ArrNull, sSubject, sFromAddr, sFromPersonal, sReplyAddr, aRecipients, "to", StrNull, oDbb.getProfileName(), StrNull, false, oDbb);
		}
	  } catch (FileNotFoundException neverthrown) {}
	    catch (FTPException neverthrown) {	    	
	  } finally {
		if (oConn!=null) { try { if (!oConn.isClosed()) oConn.close(); } catch (SQLException ignore) {} }
	  }
	  if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End SendMail.send()");
	  }

      return oRetMsgs;
    } // send
	
    // ------------------------------------------------------------------------

    /**
     * <p>Send a dual plain text and HTML message to a given recipients list</p>
     * The message will be sent inmediately indipendently to each recipient
     * @param oSessionProps Properties
     * <table><tr><th>Property</th><th>Description></th><th>Default value</th></tr>
     *        <tr><td>mail.user</td><td>Store and transport user</td><td></td></tr>
     *        <tr><td>mail.password</td><td></td>Store and transport password<td></td></tr>
     *        <tr><td>mail.store.protocol</td><td></td><td>pop3</td></tr>
     *        <tr><td>mail.transport.protocol</td><td></td><td>smtp</td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.host</td><td>For example: pop.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.host</td><td>For example: smtp.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     * </table>
     * @param sTextHtml HTML message part
     * @param sTextPlain Plain text message part
     * @param sEncoding Character encoding for message
     * @param sSubject Message subject
     * @param sFromAddr Recipient From address
     * @param sFromPersonal Recipient From Display Name
     * @param sReplyAddr Reply-To address
     * @param aRecipients List of recipient addresses
     * @return ArrayList of Strings with warnings and errors detected for each recipient.
     */
 
	public static ArrayList send(Properties oSessionProps,
								 String sTextHtml,
								 String sTextPlain,
								 String sEncoding,
								 String sSubject,
							     String sFromAddr,
							     String sFromPersonal, 
							     String sReplyAddr,
							     String aRecipients[])
      throws IOException,IllegalAccessException,NullPointerException,
             MessagingException,SQLException,ClassNotFoundException,InstantiationException {

	  final String StrNull = null;
	  final String ArrNull[] = null;

	  if (null==sSubject) sSubject = "";
	  if (null==sFromPersonal) sFromPersonal = sFromAddr;
	  if (null==sReplyAddr) sReplyAddr = sFromAddr;
	  ArrayList oRetMsgs = null;
	  try {
	    oRetMsgs = send(oSessionProps, StrNull, sTextHtml, sTextPlain, sEncoding, ArrNull, sSubject, sFromAddr, sFromPersonal, sReplyAddr, aRecipients, "to", StrNull, StrNull, StrNull);
	  } catch (FileNotFoundException neverthrown) {}
	    catch (FTPException neverthrown) {}
      return oRetMsgs;
    } // send

    // ------------------------------------------------------------------------

    /**
     * <p>Send a dual plain text and HTML message to a given recipients list</p>
     * The message will be sent inmediately independently to each recipient
     * @param oSessionProps Properties
     * <table><tr><th>Property</th><th>Description></th><th>Default value</th></tr>
     *        <tr><td>mail.user</td><td>Store and transport user</td><td></td></tr>
     *        <tr><td>mail.password</td><td></td>Store and transport password<td></td></tr>
     *        <tr><td>mail.store.protocol</td><td></td><td>pop3</td></tr>
     *        <tr><td>mail.transport.protocol</td><td></td><td>smtp</td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.host</td><td>For example: pop.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>storeprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.host</td><td>For example: smtp.mailserver.com</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.class</td><td>Only if using SSL set this value to javax.net.ssl.SSLSocketFactory</td><td></td></tr>
     *        <tr><td>mail.<i>transportprotocol</i>.socketFactory.port</td><td>Only if using SSL</td><td></td></tr>
     * </table>
     * @param sTextHtml HTML message part
     * @param sTextPlain Plain text message part
     * @param sSubject Message subject
     * @param sFromAddr Recipient From address
     * @param sFromPersonal Recipient From Display Name
     * @param sReplyAddr Reply-To address
     * @param aRecipients List of recipient addresses
     * @return ArrayList of Strings with warnings and errors detected for each recipient.
     */
 
	public static ArrayList send(Properties oSessionProps,
								 String sTextHtml,
								 String sTextPlain,
								 String sSubject,
							     String sFromAddr,
							     String sFromPersonal, 
							     String sReplyAddr,
							     String aRecipients[])
      throws IOException,IllegalAccessException,NullPointerException,
             MessagingException,SQLException,ClassNotFoundException,InstantiationException {

	  final String StrNull = null;
	  final String ArrNull[] = null;

	  if (null==sSubject) sSubject = "";
	  if (null==sFromPersonal) sFromPersonal = sFromAddr;
	  if (null==sReplyAddr) sReplyAddr = sFromAddr;
	  ArrayList oRetMsgs = null;
	  try {
	    oRetMsgs = send(oSessionProps, StrNull, sTextHtml, sTextPlain, "UTF-8", ArrNull, sSubject, sFromAddr, sFromPersonal, sReplyAddr, aRecipients, "to", StrNull, StrNull, StrNull);
	  } catch (FileNotFoundException neverthrown) {}
	    catch (FTPException neverthrown) {}
      return oRetMsgs;
    } // send
	
    // ------------------------------------------------------------------------
    	  
	/**
	 * <p>Read properties from a file and send mail according to them</p>
	 * @param args A full path to a properties file
	 */
	public static void main(String[] args)
	 throws FileNotFoundException,IOException,
	 	    IllegalAccessException,NullPointerException,
	        MessagingException,FTPException,SQLException,
	        ClassNotFoundException,InstantiationException,
	        MalformedPatternException {

	  if (null==args)
	  	throw new NullPointerException("SendMail.main() Path of properties file is required");

	  if (0==args.length)
	  	throw new NullPointerException("SendMail.main() Path of properties file is required");

	  File oPropsFile = new File(args[0]);
	  if (!oPropsFile.exists()) {
	  	throw new FileNotFoundException("SendMail.main() file not found "+args[0]);
	  }
	
	  if (DebugFile.trace) {
	    DebugFile.incIdent();
	    DebugFile.write("Begin SendMail.main(");
	    if (null!=args) {
	      for (int a=0; a<args.length; a++) {
	        if (0!=a) DebugFile.write(",");
	        DebugFile.write(args[a]);
	      } // next
	    } // fi (args)
	    DebugFile.writeln(")");
	  } // fi (trace)
 
	  // ***************************************************
	  // Load file with properties about the mail to be sent
	  FileSystem oFS = new FileSystem();
	  FileInputStream oInStrm = new FileInputStream(oPropsFile);
	  Properties oProps = new Properties();
	  oProps.load(oInStrm);
	  
	  System.out.println("Running job "+oProps.getProperty("job"));

	  // *************************************************************************
	  // Recipients list must be an ASCII encoded file with one recipient per line
	  
	  String sRecipientsFile = oProps.getProperty("recipients");

	  if (null==sRecipientsFile) {
	    if (DebugFile.trace) DebugFile.decIdent();
	  	throw new NullPointerException("Recipients file path is required");
	  } else {
	    if (DebugFile.trace) DebugFile.writeln("recipients="+sRecipientsFile);
	  }

	  String sRecipientsList = oFS.readfilestr(sRecipientsFile, "ASCII");
	  if (sRecipientsList.length()==0) {
	    if (DebugFile.trace) DebugFile.decIdent();
	  	throw new NullPointerException("Recipients file is empty");
	  }

	  // ***********************************
	  // Load Black List into a sorted array

	  String[] aBlackList = null;
	  String sBlackListFile = oProps.getProperty("blacklist");
	  if (null!=sRecipientsFile) {
	    if (sRecipientsFile.trim().length()>0) {
	      String sBlackList = oFS.readfilestr(sBlackListFile, "ASCII");
	      if (sBlackList.length()>0) {
	        aBlackList = Gadgets.split(sBlackList, "\n");
	        final int nBlackList = aBlackList.length;
	        for (int b=0; b<nBlackList; b++) {
	          aBlackList[b] = aBlackList[b].toLowerCase();
	        } // next
	        Arrays.sort(aBlackList, String.CASE_INSENSITIVE_ORDER);
	      }
	    } // fi
	  } // fi
	  
	  String aRecipients[] = Gadgets.split(sRecipientsList, "\n");

      System.out.println("total recipients count is "+String.valueOf(aRecipients.length));
	  if (DebugFile.trace) DebugFile.writeln("total recipients count is "+String.valueOf(aRecipients.length));

	  AdHocMailing oAdHoc = new AdHocMailing();
	  if (oProps.getProperty("allow")!=null) oAdHoc.setAllowPattern(oProps.getProperty("allow"));
	  if (oProps.getProperty("deny")!=null) oAdHoc.setDenyPattern(oProps.getProperty("deny"));
	  oAdHoc.addBlackList (aBlackList );
	  oAdHoc.addRecipients(aRecipients);
	  aRecipients = oAdHoc.getRecipients();

	  System.out.println("unique and allowed recipients count is"+String.valueOf(aRecipients.length));
	  if (DebugFile.trace) DebugFile.writeln("unique and allowed recipients count is"+String.valueOf(aRecipients.length));
	  
	  // ******************
	  // Get Mail enconding
	  
	  String sEncoding = oProps.getProperty("encoding","UTF-8");
	  
	  // ******************************************************
	  // Get base directory where mail source files are located
	  
	  String sUserDir = oProps.getProperty("userdir",System.getProperty("user.dir"));
	  
	  // ********************
	  // Get mail source HTML
	  
	  String sTextHtml = null;
	  String sHtmlFilePath = oProps.getProperty("texthtml","");
	  if (sHtmlFilePath.length()>0) {
	    if (!sHtmlFilePath.startsWith(sUserDir)) sHtmlFilePath = sUserDir+sHtmlFilePath;
        sTextHtml = oFS.readfilestr(sHtmlFilePath, sEncoding);
	  }

	  // **************************
	  // Get mail source plain text

	  String sTextPlain = null;
	  String sTextFilePath = oProps.getProperty("textplain","");
	  if (sTextFilePath.length()>0) {
	    if (!sTextFilePath.startsWith(sUserDir)) sTextFilePath = sUserDir+sTextFilePath;
		sTextPlain = oFS.readfilestr(sTextFilePath, sEncoding);
	  }
		  	
	  // Get mail subject
	  String sSubject = oProps.getProperty("subject", "");

	  // Get mail from address
	  String sFromAddr = oProps.getProperty("from");

	  // Get mail from display name
	  String sFromPersonal = oProps.getProperty("displayname",sFromAddr);
	  
	  // Get mail reply-to address
	  String sReplyAddr = oProps.getProperty("replyto",sFromAddr);
	  
	  String sRecipientType = oProps.getProperty("recipienttype","to").toLowerCase().trim();

	  String sAttachments = oProps.getProperty("attachments","").trim();
	  String aAttachments[] = null;
	  if (sAttachments.length()>0) {
		aAttachments = Gadgets.split(sAttachments, new char[]{';',':'});
	  }

	  String sJobTl = oProps.getProperty("job","").trim();	  
	  String sEnvCnf;	  
	  if (args.length<=1) {
	    sEnvCnf = null;
	  } else {
	    sEnvCnf = args[1];
	  }

	  // Generate a unique message Id.
	  String sId = oProps.getProperty("messageid", Gadgets.generateUUID());

	  if (oProps.getProperty("testmode","no").equalsIgnoreCase("yes") || oProps.getProperty("testmode","false").equalsIgnoreCase("true") || oProps.getProperty("testmode","0").equalsIgnoreCase("1"))
	  	System.out.println("test mode activated no e-mail will be actually sent");

	  ArrayList aWarns = send(oProps, sUserDir, sTextHtml, sTextPlain, sEncoding,
		   aAttachments, sSubject,
		   sFromAddr, sFromPersonal, sReplyAddr,
		   aRecipients, sRecipientType,
		   sId, sEnvCnf, sJobTl);
	  
	  for (int a=0; a<aWarns.size(); a++) {
	  	System.out.println(aWarns.get(a).toString());
	  }

	  if (DebugFile.trace) {
	    DebugFile.decIdent();
	    DebugFile.writeln("End SendMail.main()");
	  }
	} // main
}
