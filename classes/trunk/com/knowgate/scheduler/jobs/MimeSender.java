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

package com.knowgate.scheduler.jobs;

import java.io.File;
import java.io.IOException;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Timestamp;

import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Properties;

import javax.mail.Message;
import javax.mail.URLName;
import javax.mail.Folder;
import javax.mail.MessagingException;
import javax.mail.StoreClosedException;
import javax.mail.internet.InternetAddress;

import org.htmlparser.util.ParserException;

/*
import org.htmlparser.Parser;
import org.htmlparser.Node;
import org.htmlparser.util.NodeIterator;

import org.htmlparser.tags.ImageTag;
*/

import org.apache.oro.text.regex.*;

import com.sun.mail.smtp.SMTPMessage;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

import com.knowgate.acl.ACLUser;
import com.knowgate.acl.ACLDomain;
import com.knowgate.dfs.FileSystem;
import com.knowgate.crm.DistributionList;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataxslt.FastStreamReplacer;
import com.knowgate.hipermail.DBStore;
import com.knowgate.hipermail.DBFolder;
import com.knowgate.hipermail.DBInetAddr;
import com.knowgate.hipermail.DBMimeMessage;
import com.knowgate.hipermail.DraftsHelper;
import com.knowgate.hipermail.MailAccount;
import com.knowgate.hipermail.HtmlMimeBodyPart;
import com.knowgate.hipermail.SessionHandler;
import com.knowgate.scheduler.Job;
import com.knowgate.scheduler.Atom;
import com.knowgate.scheduler.AtomFeeder;
import com.knowgate.scheduler.Event;
import com.oreilly.servlet.MailMessage;

/**
 * <p>Send mime mail message from the outbox of an account to a recipients list</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class MimeSender extends Job {

  private SessionHandler oHndlr;
  private int iDomainId;
  private String sBody;
  private boolean bPersonalized;
  private Boolean bHasCSSStyles;
  private Boolean oBeforeSend;
  private DBMimeMessage oDraft;
  private Properties oHeaders;
  private InternetAddress[] aFrom;
  private InternetAddress[] aReply;
  private String[] aBlackList;
  private String sTargetLists;
  private String sProfile;
  private String sMBoxDir;
  private ACLUser oUser;
  private Perl5Matcher oMatcher;
  private Perl5Compiler oCompiler;
  private Pattern oLinkCSS;
  private HashMap<String,String> oLinksSrc;

  // ---------------------------------------------------------------------------

  public MimeSender() {
    sBody = null;
    oHndlr = null;
    sMBoxDir = null;
    sProfile = null;
    aBlackList = null;
    oUser = new ACLUser();
    oBeforeSend = null;
    bHasCSSStyles = null;
    oMatcher = null;
    oCompiler= null;
    oLinkCSS=null;
    oLinksSrc=new HashMap<String,String>(13);
  }

  // ---------------------------------------------------------------------------

  protected void finalize() throws Throwable {
    free();
  }

  // ---------------------------------------------------------------------------

  public static String redirectExternalLinks(String sLBody, MimeSender oJob, Atom oAtm) throws ParserException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MimeSender.redirectExternalLinks([Atom])");
      DebugFile.incIdent();
    }
    
    String sRedirectorDir = oJob.getProperty("webbeacon");
    if (sRedirectorDir==null) {
	  sRedirectorDir = Gadgets.chomp(oJob.getParameter("webserver"),'/')+"hipermail/";
	} else if (sRedirectorDir.trim().length()==0) {
	  sRedirectorDir = Gadgets.chomp(oJob.getParameter("webserver"),'/')+"hipermail/";
	}
	
	String sRedirectorUrl = Gadgets.chomp(sRedirectorDir,'/')+"contenido.jsp?";

    HtmlMimeBodyPart oPart = new HtmlMimeBodyPart(sLBody, null);
    String sRBody = oPart.addClickThroughRedirector(sRedirectorUrl+"gu_job="+oJob.getString(DB.gu_job)+"&pg_atom="+String.valueOf(oAtm.getInt(DB.pg_atom))+"&tx_email="+oAtm.getStringNull(DB.tx_email,"")+(oAtm.isNull(DB.gu_company) ? "" : "&gu_company="+oAtm.getString(DB.gu_company))+(oAtm.isNull(DB.gu_contact) ? "" : "&gu_contact="+oAtm.getString(DB.gu_contact))+"&url=");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MimeSender.redirectExternalLinks()");
    }

	return sRBody;
  } // redirectExternalLinks

  // ---------------------------------------------------------------------------

  private String inlineStyles(String sSBody) {
    String sInlinedBody;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MimeSender.inlineStyles()");
      DebugFile.incIdent();
    }
    
    if (null==oMatcher) oMatcher = new Perl5Matcher();
    if (null==oCompiler) oCompiler = new Perl5Compiler();
	try {
      if (DebugFile.trace) DebugFile.writeln("Matching <LINK> Regular Expression <LINK\\s+(?:rel\\s*=\\s*\"stylesheet\"\\s+)?(?:type\\s*=\\s*\"text/css\"\\s+)?(?:rel\\s*=\\s*\"stylesheet\"\\s+)?href\\s*=\\s*[\"']{1}((?:[\\x20!#$%&]|[\\x28-~])+)[\"']{1}\\s*(?:rel\\s*=\\s*\"stylesheet\"\\s+)?(?:type\\s*=\\s*\"text/css\"\\s+)?(?:rel\\s*=\\s*\"stylesheet\"\\s+)?\\s*/?>(?:</LINK>)?");
	  if (null==oLinkCSS) oLinkCSS = oCompiler.compile("<LINK\\s+(?:rel\\s*=\\s*\"stylesheet\"\\s+)?(?:type\\s*=\\s*\"text/css\"\\s+)?(?:rel\\s*=\\s*\"stylesheet\"\\s+)?href\\s*=\\s*[\"']{1}((?:[\\x20!#$%&]|[\\x28-~])+)[\"']{1}\\s*(?:rel\\s*=\\s*\"stylesheet\"\\s+)?(?:type\\s*=\\s*\"text/css\"\\s+)?(?:rel\\s*=\\s*\"stylesheet\"\\s+)?\\s*/?>(?:</LINK>)?",Perl5Compiler.CASE_INSENSITIVE_MASK);
	} catch (MalformedPatternException mpe) {
	  if (DebugFile.trace) DebugFile.writeln("MalformedPatternException "+mpe.getMessage());
	}

    if (oMatcher.contains(sSBody, oLinkCSS)) {
      String sLinkCSS = oMatcher.getMatch().group(0);
	  if (DebugFile.trace) DebugFile.writeln("Matched a CSS <link> regular expression "+sLinkCSS);
      String sLinkHref = oMatcher.getMatch().group(1);
      if (!oLinksSrc.containsKey(sLinkHref)) {
        try {
          FileSystem oFls = new FileSystem();
          String sLinkSrc = oFls.readfilestr(sLinkHref,"ISO8859_1");
          if (null!=sLinkSrc) {
            oLinksSrc.put(sLinkHref,"<style type=\"text/css\">\n"+sLinkSrc+"\n</style>\n");
            if (sLinkSrc.length()>0) {
              sInlinedBody = Util.substitute(oMatcher, oLinkCSS, new Perl5Substitution(oLinksSrc.get(sLinkHref), Perl5Substitution.INTERPOLATE_ALL), sSBody, Util.SUBSTITUTE_ALL);
            } else {
          	  sInlinedBody = sSBody;
            }
          } else {
            oLinksSrc.put(sLinkHref,"");
            sInlinedBody = sSBody;
          }
        } catch (Exception xcpt) {
    	  if (DebugFile.trace) DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
          sInlinedBody = sSBody;
        }
      } else if (oLinksSrc.get(sLinkHref).length()>0) {
        sInlinedBody = Util.substitute(oMatcher, oLinkCSS, new Perl5Substitution(oLinksSrc.get(sLinkHref), Perl5Substitution.INTERPOLATE_ALL), sSBody, Util.SUBSTITUTE_ALL);
      } else {
      	sInlinedBody = sSBody;
      }
    } else {
	  if (DebugFile.trace) DebugFile.writeln("Did not find any CSS <link>");
      sInlinedBody = sSBody;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MimeSender.inlineStyles()");
    }

    return sInlinedBody;
  } // inlineStyles
    
  // ---------------------------------------------------------------------------

  private String personalizeBody(String sFBody, MimeSender oJob, Atom oAtm) throws NullPointerException {
    JDCConnection oConn = null;
    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    String sPersonalizedBody;
    String sNm="", sSn="", sSl="", sCo="", sEm="", sCp="", sCn="", sIn="", sPw="";
    boolean bDirectListDataFound = false;
    
    if (DebugFile.trace) {
      DebugFile.writeln("Begin MimeSender.personalizeBody([Atom])");
      DebugFile.incIdent();
      DebugFile.writeln("gu_job="+oAtm.getStringNull(DB.gu_job,"null"));
      if (oAtm.isNull(DB.pg_atom)) {
        DebugFile.decIdent();
        throw new NullPointerException("MimeSender.personalizeBody() no Atom set");
      } else {
        DebugFile.writeln("pg_atom="+String.valueOf(oAtm.getInt(DB.pg_atom)));
      }
    }

    sEm = oAtm.getString(DB.tx_email);

    try {
      oConn = oJob.getDataBaseBind().getConnection("MimeSender", true);

      if (sTargetLists.length()>0) {
    	oStmt = oConn.prepareStatement("SELECT m."+DB.tx_name+",m."+DB.tx_surname+",m."+DB.tx_salutation+",c."+DB.nm_commercial+",c."+DB.gu_company+","+DB.gu_contact+" FROM "+
    								   DB.k_x_list_members+" m LEFT OUTER JOIN "+DB.k_companies+" c ON m."+DB.gu_company+"=c."+DB.gu_company+
    			                       " WHERE m."+DB.gu_list+" IN "+sTargetLists+" AND m."+DB.tx_email+"=?");
        oStmt.setString(1, sEm);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          bDirectListDataFound = true;
          sNm = oRSet.getString(1); if (oRSet.wasNull()) sNm = "";
          sSn = oRSet.getString(2); if (oRSet.wasNull()) sSn = "";
          sSl = oRSet.getString(3); if (oRSet.wasNull()) sSl = "";
          sCo = oRSet.getString(4); if (oRSet.wasNull()) sCo = "";
          sCp = oRSet.getString(5); if (oRSet.wasNull()) sCp = "";
          sCn = oRSet.getString(6); if (oRSet.wasNull()) sCn = "";
        }
        oRSet.close();
        oRSet=null;
        oStmt.close();
        oStmt=null;
      }

      if (!bDirectListDataFound) {
        if (DebugFile.trace) {
          DebugFile.writeln("Connection.prepareStatement(SELECT "+DB.tx_name+","+DB.tx_surname+","+DB.tx_salutation+","+DB.nm_commercial+","+DB.gu_company+","+DB.gu_contact+","+DB.url_addr+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+oJob.getStringNull(DB.gu_workarea,"null")+"' AND "+DB.tx_email+"='"+sEm+"')");
        }
        oStmt = oConn.prepareStatement("SELECT "+DB.tx_name+","+DB.tx_surname+","+DB.tx_salutation+","+DB.nm_commercial+","+DB.gu_company+","+DB.gu_contact+","+DB.url_addr+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+oJob.getString(DB.gu_workarea)+"' AND "+DB.tx_email+"=?",
                                     ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sEm);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          sNm = oRSet.getString(1); if (oRSet.wasNull()) sNm = "";
          sSn = oRSet.getString(2); if (oRSet.wasNull()) sSn = "";
          sSl = oRSet.getString(3); if (oRSet.wasNull()) sSl = "";
          sCo = oRSet.getString(4); if (oRSet.wasNull()) sCo = "";
          sCp = oRSet.getString(5); if (oRSet.wasNull()) sCp = "";
          sCn = oRSet.getString(6); if (oRSet.wasNull()) sCn = "";
          sIn = oRSet.getString(7); if (oRSet.wasNull()) sIn = "";
        } else {
          sIn=sCn=sCp=sNm=sSn=sSl=sCo="";
        }
        oRSet.close();
        oRSet=null;
        oStmt.close();
        oStmt=null;
      } // fi (!bDirectListDataFound)
      
      if (sFBody.indexOf("{#Data.Password}")>0 || sFBody.indexOf("{#Datos.Password}")>0) {
        oStmt = oConn.prepareStatement("SELECT "+DB.tx_pwd+" FROM "+DB.k_contacts+" c,"+DB.k_x_contact_addr+" x, "+DB.k_addresses+" a WHERE a."+DB.gu_workarea+"='"+oJob.getString(DB.gu_workarea)+"' AND a."+DB.tx_email+"=? AND a."+DB.gu_address+"=x."+DB.gu_address+" AND x."+DB.gu_contact+"=c."+DB.gu_contact,
                  					   ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    	oStmt.setString(1, sEm);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
    	  sPw = oRSet.getString(1);
    	  if (oRSet.wasNull()) sPw = "";
    	} else {
          sPw="";
        }
      }

      oConn.close("MimeSender");
      oConn=null;
      
      FastStreamReplacer oRplcr = new FastStreamReplacer(sFBody.length()+256);
      try {
        sPersonalizedBody = oRplcr.replace(new StringBuffer(sFBody), FastStreamReplacer.createMap(
                             new String[]{"Data.Name","Data.Surname","Data.Salutation","Data.Legal_Name","Data.Password","Address.EMail","Job.Guid","Job.Atom","Data.Company_Guid","Data.Contact_Guid","Address.URL",
                                          "Datos.Nombre","Datos.Apellidos","Datos.Saludo","Datos.Razon_Social","Datos.Password","Direccion.EMail","Lote.Guid","Lote.Atomo","Datos.Guid_Empresa","Datos.Guid_Contacto","Direccion.URL"},

                             new String[]{sNm,sSn,sSl,sCo,sPw,sEm,oJob.getString(DB.gu_job),String.valueOf(oAtm.getInt(DB.pg_atom)),sCp,sCn,sIn,
                                          sNm,sSn,sSl,sCo,sPw,sEm,oJob.getString(DB.gu_job),String.valueOf(oAtm.getInt(DB.pg_atom)),sCp,sCn,sIn}));
      } catch (IOException ioe) {
        if (DebugFile.trace) DebugFile.writeln("IOException " + ioe.getMessage() + " sending message "+oJob.getParameter("message") + " to " + sEm);
        oJob.log("IOException " + ioe.getMessage() + " sending message "+oJob.getParameter("message") + " to " + sEm);
        sPersonalizedBody = sFBody;
      }
    } catch (SQLException sqle) {
      if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) {} }
      if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) {} }
      if (oConn!=null) { try { oConn.close(); } catch (Exception ignore) {} }
      if (DebugFile.trace) DebugFile.writeln("SQLException " + sqle.getMessage() + " sending message "+oJob.getParameter("message") + " to " + sEm);
      oJob.log("SQLException " + sqle.getMessage() + " sending message "+oJob.getParameter("message") + " to " + sEm);
      sPersonalizedBody = sFBody;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MimeSender.personalizeBody()");
    }
    return sPersonalizedBody;
  } // personalizeBody

  // ---------------------------------------------------------------------------

  public void init(Atom oAtm)
    throws SQLException,MessagingException,NullPointerException {

      if (DebugFile.trace) {
        DebugFile.writeln("Begin MimeSender.init()");
        DebugFile.incIdent();
      }

      // If mail is personalized (contains {#...} tags) a special parameter must has been previously set
      if (getParameter("personalized")==null)
        bPersonalized = false;
      else
      	bPersonalized = getParameter("personalized").equals("true") ? true : false;
      if (DebugFile.trace) DebugFile.writeln("personalized="+getParameter("personalized"));

      DBStore oStor = null;
      DBFolder oOutBox = null;
      JDCConnection oConn = null;
      PreparedStatement oUpdt = null;
      MailAccount oMacc = new MailAccount();

      if (DebugFile.trace) DebugFile.writeln("workarea="+getStringNull(DB.gu_workarea,"null"));
      String sWrkA = getString(DB.gu_workarea);
      try {

    	if (DebugFile.trace) DebugFile.writeln("DBBind="+getDataBaseBind());

        oConn = getDataBaseBind().getConnection("MimeSender.init.1");
    	
        // Get User, Account and Domain objects
        iDomainId = ACLDomain.forWorkArea(oConn, sWrkA);
        if (!oUser.load(oConn, new Object[]{getStringNull(DB.gu_writer,null)})) oUser=null;
        if (!oMacc.load(oConn, new Object[]{getParameter("account")})) oMacc=null;

        oConn.setAutoCommit(true);

        // If message is personalized then fill data for each mail address
        if (bPersonalized) resolveAtomsEMails(oConn);

        
        // Find target lists of this job group
        if (isNull(DB.gu_job_group)) {
          sTargetLists = "";
        } else {
          DBSubset oLsts = new DBSubset (DB.k_x_adhoc_mailing_list,DB.gu_list,DB.gu_mailing+"=?",10);
          DBSubset oLst2 = new DBSubset (DB.k_x_pageset_list,DB.gu_list,DB.gu_pageset+"=?",10);
          oLsts.load(oConn, new Object[]{getString(DB.gu_job_group)});
          oLst2.load(oConn, new Object[]{getString(DB.gu_job_group)});
          oLsts.union(oLst2);
          oLsts.setRowDelimiter("',");
          if (oLsts.getRowCount()==0)
            sTargetLists = "";        	  
          else
        	sTargetLists = "('"+Gadgets.chomp(Gadgets.dechomp(oLsts.toString(),","),"'")+")";
        }
        
        oConn.close("MimeSender.init.1");
        oConn=null;
      } catch (SQLException sqle) {
        if (DebugFile.trace) DebugFile.writeln("MimeSender.init("+getStringNull(DB.gu_job,"null")+") " + sqle.getClass().getName() + " " + sqle.getMessage());
        if (oConn!=null) { try { if (!oConn.isClosed()) oConn.close("MimeSender.init.1"); } catch (Exception ignore) {} }
        throw sqle;
      }
        catch (NullPointerException npe) {
        if (DebugFile.trace) DebugFile.writeln("MimeSender.init("+getStringNull(DB.gu_job,"null")+") " + npe.getClass().getName());
        if (oConn!=null) { try { if (!oConn.isClosed()) oConn.close("MimeSender.init.1"); } catch (Exception ignore) {} }
        throw npe;
      }
      if (null==oUser) {
        if (DebugFile.trace) {
          DebugFile.decIdent();
          DebugFile.writeln("End MimeSender.init("+oAtm.getString(DB.gu_job)+") : abnormal process termination");
        }
        throw new NullPointerException("User "+getStringNull(DB.gu_writer,"null")+" not found");
      }
      if (null==oMacc) {
        if (DebugFile.trace) {
          DebugFile.decIdent();
          DebugFile.writeln("End MimeSender.init("+oAtm.getString(DB.gu_job)+") : abnormal process termination");
        }
        throw new NullPointerException("Mail Account "+getParameter("account")+" not found");
      }
      try {

        // Create mail session
        if (DebugFile.trace) DebugFile.writeln("new SessionHandler("+oMacc.getStringNull(DB.gu_account,"null")+")");
        oHndlr = new SessionHandler(oMacc);

        // Retrieve profile name to be used from a Job parameter
        // Profile is needed because it contains the path to /storage directory
        // which is used for composing the path to outbox mbox file containing
        // source of message to be sent
        sProfile = getParameter("profile");
        sMBoxDir = DBStore.MBoxDirectory(sProfile,iDomainId,sWrkA);

        oStor = new DBStore(oHndlr.getSession(), new URLName("jdbc://", sProfile, -1, sMBoxDir, oUser.getString(DB.gu_user), oUser.getStringNull(DB.tx_pwd,"")));
        oStor.connect(sProfile, oUser.getString(DB.gu_user), oUser.getStringNull(DB.tx_pwd,""));
        oOutBox = (DBFolder) oStor.getFolder("outbox");
        oOutBox.open(Folder.READ_WRITE);
        String sMsgId = getParameter("message");

        oDraft = oOutBox.getMessageByGuid(sMsgId);
        if (null==oDraft) throw new MessagingException("DBFolder.getMessageByGuid() Message "+sMsgId+" not found");

        oHeaders = oOutBox.getMessageHeaders(sMsgId);
        if (null==oHeaders) throw new MessagingException("DBFolder.getMessageHeaders() Message "+sMsgId+" not found");
        if (null==oHeaders.get(DB.nm_from))
          aFrom = new InternetAddress[]{new InternetAddress(oHeaders.getProperty(DB.tx_email_from))};
        else
          aFrom = new InternetAddress[]{new InternetAddress(oHeaders.getProperty(DB.tx_email_from),
                                                            oHeaders.getProperty(DB.nm_from))};

        if (DebugFile.trace) DebugFile.writeln("tx_email_reply="+oHeaders.getProperty(DB.tx_email_reply));

        aReply = new InternetAddress[]{new InternetAddress(oHeaders.getProperty(DB.tx_email_reply, oHeaders.getProperty(DB.tx_email_from)))};

        sBody = oDraft.getText();
        
        if (DebugFile.trace) {
          if (null==sBody)
            DebugFile.writeln("Message body: null");
          else
            DebugFile.writeln("Message body: " + Gadgets.left(sBody.replace('\n',' '), 100));
        }

		oOutBox.close(false);
		oOutBox=null;
		oStor.close();
		oStor=null;

        oConn = getDataBaseBind().getConnection("MimeSender.init.2");
        oConn.setAutoCommit(true);

        oUpdt = oConn.prepareStatement("UPDATE "+DB.k_mime_msgs+" SET "+DB.dt_sent+"=? WHERE "+DB.gu_mimemsg+"=?");
        oUpdt.setTimestamp(1, new Timestamp(new Date().getTime()));
    	oUpdt.setString(2, sMsgId);
        oUpdt.executeUpdate();
        oUpdt.close();

		DBSubset oBlck = new DBSubset(DB.k_global_black_list, DB.tx_email,
		                              DB.id_domain+"=? AND "+DB.gu_workarea+" IN (?,'00000000000000000000000000000000')", 1000);
		int nBlacklisted = oBlck.load(oConn, new Object[]{new Integer(iDomainId), getString(DB.gu_workarea)});
        for (int m=0; m<nBlacklisted; m++)
          oBlck.setElementAt(oBlck.getString(0, m).toLowerCase(), 0, m);

		if (nBlacklisted==0) {
		  if (getDataBaseBind().exists(oConn, DB.k_grey_list, "U")) {
		  	DBSubset oGrey = new DBSubset(DB.k_grey_list+" g", DB.tx_email, null, 1000);		    
		  	int nGreylisted = oGrey.load(oConn);
			if (nGreylisted>0) {
		      for (int m=0; m<nGreylisted; m++)
		        oGrey.setElementAt(oGrey.getString(0, m).toLowerCase(), 0, m);
		  	  aBlackList = new String[nGreylisted];
		      for (int g=0; g<nGreylisted; g++)
		  	    aBlackList[g] = oGrey.getString(0,g);
			} else {
		      aBlackList = null;
			}
		  } else {
		    aBlackList = null;
		  } 		  
		} else {
		  aBlackList = new String[nBlacklisted];
		  for (int b=0; b<nBlacklisted; b++)
		  	aBlackList[b] = oBlck.getString(0,b);
		  if (getDataBaseBind().exists(oConn, DB.k_grey_list, "U")) {
		  	DBSubset oGrey = new DBSubset(DB.k_grey_list+" g", DB.tx_email,
		  	                              "NOT EXISTS (SELECT "+DB.tx_email+" FROM "+DB.k_global_black_list+" b WHERE b."+DB.tx_email+"=g."+DB.tx_email+" AND b."+DB.id_domain+"=? AND b."+DB.gu_workarea+" IN (?,'00000000000000000000000000000000'))", 1000);
		    
		    int nGreylisted = oGrey.load(oConn, new Object[]{new Integer(iDomainId), getString(DB.gu_workarea)});
			if (nGreylisted>0) {
			  for (int m=0; m<nGreylisted; m++)
			    oGrey.setElementAt(oGrey.getString(0, m).toLowerCase(), 0, m);
		  	  String[] aBlackGrey = new String[nBlacklisted+nGreylisted];
		  	  for (int b=0; b<nBlacklisted; b++)
		  	    aBlackGrey[b] = oBlck.getString(0,b);
		  	  for (int g=0; g<nGreylisted; g++)
		  	    aBlackGrey[g+nBlacklisted] = oGrey.getString(0,g);
		  	  aBlackList = aBlackGrey;
			}
		  }
		  Arrays.sort(aBlackList);
		} // fi

        Event.trigger(oConn, iDomainId, "initjob", this, getProperties());
                             	
        oConn.close("MimeSender.init.2");
        oConn=null;

      } catch (Exception e) {
        if (DebugFile.trace) {
          DebugFile.writeStackTrace(e);
          DebugFile.write("\n");
          DebugFile.decIdent();
          DebugFile.writeln("End MimeSender.init(" + oAtm.getString(DB.gu_job) + ":" + String.valueOf(oAtm.getInt(DB.pg_atom)) + ") : abnormal process termination");
        }
        try { if (oUpdt!=null) oUpdt.close(); } catch (Exception ignore) {}
        try { if (oConn!=null) if (!oConn.isClosed()) oConn.close("MimeSender.init.2"); } catch (Exception ignore) {}
        if (null!=oOutBox) { try { oOutBox.close(false); oOutBox=null; } catch (Exception ignore) {} }
        if (null!=oStor) { try { oStor.close(); oStor=null; } catch (Exception ignore) {} }
        if (null!=oHndlr) { try { oHndlr.close(); oHndlr=null; } catch (Exception ignore) {} }
        throw new MessagingException(e.getMessage(),e);
      }
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End MimeSender.init()");
      }
  } // init

  // ---------------------------------------------------------------------------

  /**
   * Move message from outbox to sent items folder
   */
  public void free() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin MimeSender.free()");
      DebugFile.incIdent();
      DebugFile.writeln("gu_job="+getStringNull(DB.gu_job,"null"));
    }

	DBStore oStor = null;
	DBFolder oSent = null;
	int iStillExecutable = 0;
	
    if (0==iPendingAtoms) {

      try {
      	if (getDataBaseBind()!=null) {
          JDCConnection oConn = getDataBaseBind().getConnection("MimeSender.free", true);
          if (oConn!=null) {
            iStillExecutable = DBCommand.queryCount(oConn, "*", DB.k_job_atoms, DB.id_status+" IN ("+
      					       String.valueOf(Atom.STATUS_INTERRUPTED)+","+String.valueOf(Atom.STATUS_SUSPENDED)+
      					       String.valueOf(Atom.STATUS_RUNNING)+","+String.valueOf(Atom.STATUS_PENDING)+")");
            if (0==iStillExecutable) {
              try {
          	    Event.trigger(oConn, iDomainId, "freejob", this, getProperties());
              } catch (Exception ignore) { }
            }
            oConn.close("MimeSender.free");
          } // fi (oConn!=null)
      	} // fi getDataBaseBind()
      } catch (SQLException sqle) {
        if (DebugFile.trace) {
          DebugFile.writeln("SQLException "+sqle.getMessage());
        }
      }

      if (0==iStillExecutable) {
        try {
          if (oHndlr==null) {
            throw new MessagingException("Session lost. SessionHandler is null");
          } else if (oHndlr.getSession()==null) {
            throw new MessagingException("Session lost. SessionHandler.getSession() is null");
          } else {
            oStor = new DBStore(oHndlr.getSession(), new URLName("jdbc://", sProfile, -1, sMBoxDir, oUser.getString(DB.gu_user), oUser.getStringNull(DB.tx_pwd,"")));
            oStor.connect(sProfile, oUser.getString(DB.gu_user), oUser.getStringNull(DB.tx_pwd,""));
            oSent = (DBFolder) oStor.getFolder("sent");
            oSent.open(Folder.READ_WRITE);
            oSent.moveMessage(oDraft);
	        oSent.close(false);
	        oStor.close();
          }
        } catch (StoreClosedException sce) {
          if (DebugFile.trace) {
            DebugFile.writeln("MimeSender.free() StoreClosedException "+sce.getMessage());
            try  {
              DebugFile.writeln(StackTraceUtil.getStackTrace(sce));
            } catch (IOException ignore) {}
          }      	
        } catch (MessagingException mse) {
          if (DebugFile.trace) {
            DebugFile.writeln("MimeSender.free() MessagingException "+mse.getMessage());
            try  {
              DebugFile.writeln(StackTraceUtil.getStackTrace(mse));
            } catch (IOException ignore) {}
          }
        } catch (NullPointerException npe) {
          if (DebugFile.trace) {
            DebugFile.writeln("MimeSender.free() NullPointerException "+npe.getMessage());
            try  {
              DebugFile.writeln(StackTraceUtil.getStackTrace(npe));
            } catch (IOException ignore) {}
          }
        }
      } // fi (0==iStillExecutable)	
    } // fi

    oDraft=null;
    if (null!=oSent)   { try { oSent.close(false); oSent=null; } catch (Exception ignore) {} }
    if (null!=oStor)   { try { oStor.close(); oStor=null; } catch (Exception ignore) {} }
    if (null!=oHndlr)  { try { oHndlr.close(); oHndlr=null; } catch (Exception ignore) {} }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MimeSender.free()");
    }
  } // free

  // ---------------------------------------------------------------------------

  public Object process(Atom oAtm) throws SQLException, MessagingException, NullPointerException {
    final String Activated = "true";
    final String Yes = "1";
    final String No = "0";
    boolean bBlackListed = false;
    
    if (DebugFile.trace) {
      DebugFile.writeln("Begin MimeSender.process("+oAtm.getString(DB.gu_job)+":"+String.valueOf(oAtm.getInt(DB.pg_atom))+")");
      DebugFile.incIdent();
    }

	if (null==oAtm) {
	  if (DebugFile.trace) {
	  	DebugFile.writeln("NullPointerException MimeSender.process() Atom may not be null");
	  	DebugFile.decIdent();
	  }
	  throw new NullPointerException("MimeSender.process() Atom may not be null");
	}

    // ***************************************************
    // Create mail session if it does not previously exist

    if (oHndlr==null && iPendingAtoms>0) {
      init(oAtm);
    }

	if (null==aFrom) {
	  if (DebugFile.trace) {
	  	DebugFile.writeln("NullPointerException MimeSender.process() From address may not be null");
	  	DebugFile.decIdent();
	  }
	  throw new NullPointerException("MimeSender.process() From address may not be null");
	}

    if (null==oDraft) {
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End MimeSender.process(" + oAtm.getString(DB.gu_job) + ":" + String.valueOf(oAtm.getInt(DB.pg_atom)) + ") : abnormal process termination");
      }
      throw new NullPointerException("Draft message "+getParameter("message")+" not found");
    }

    // ***********************************
    // Once session is created set message

    SMTPMessage oSentMsg;

    try {
	  
      // Personalize mail if needed by replacing {#...} tags by values taken from Atom fields
      String sFormat = oAtm.getStringNull(DB.id_format,"plain").toLowerCase();
      if (sFormat.equals("text") || sFormat.equals("txt")) sFormat = "plain";
      if (sFormat.equals("htm")) sFormat = "html";
      
	  String sAttachInlineImages = getParameter("attachimages");
	  if (sAttachInlineImages==null) sAttachInlineImages = Yes;
	  boolean bAttachInlineImages = Yes.equals(sAttachInlineImages) || Activated.equals(sAttachInlineImages);

	  String sEncoding = getParameter("encoding");
	  if (sEncoding==null) sEncoding = "UTF-8";
	  
	  String sPBody;

	  if (bHasCSSStyles==null) {
	    bHasCSSStyles = new Boolean (!inlineStyles(sBody).equals(sBody));	    	
	  }
	  
	  if (bHasCSSStyles.booleanValue()) {
        if (DebugFile.trace)
          DebugFile.writeln("Message body has linked CSS styles that have been inlined inside the HTML");
        if (bPersonalized)
          sPBody = personalizeBody(inlineStyles(sBody), this, oAtm);
        else
      	  sPBody = inlineStyles(sBody);
	  } else {
        if (DebugFile.trace)
          DebugFile.writeln("Message body does not have linked CSS styles");
        if (bPersonalized)
          sPBody = personalizeBody(sBody, this, oAtm);
        else
      	  sPBody = sBody;
	  }

	  String sClickThrough = getParameter("clickthrough");
	  if (sClickThrough==null) sClickThrough = No;
	  if (Yes.equals(sClickThrough) || Activated.equals(sClickThrough)) {
	    sPBody = redirectExternalLinks(sPBody,this,oAtm);
	  }

	  // Insert Web Beacon just before </BODY> tag
	  String sWebBeacon = getParameter("webbeacon");
	  if (sWebBeacon==null) sWebBeacon= No;
	  if (Yes.equals(sWebBeacon) || Activated.equals(sWebBeacon)) {
	    int iEndBody = Gadgets.indexOfIgnoreCase(sPBody, "</body>", 0);
	  	if (iEndBody>0) {
	  	  String sWebBeaconDir = getProperty("webbeacon");	  	  
	  	  if (sWebBeaconDir==null) {
	  	  	sWebBeaconDir = Gadgets.chomp(getParameter("webserver"),'/')+"hipermail/";
	  	  } else if (sWebBeaconDir.trim().length()==0) {
	  	  	sWebBeaconDir = Gadgets.chomp(getParameter("webserver"),'/')+"hipermail/";
	  	  }
	  	  sPBody = sPBody.substring(0, iEndBody)+"<!--WEBBEACON SRC=\""+Gadgets.chomp(sWebBeaconDir,'/')+"web_beacon.jsp?gu_job="+getString(DB.gu_job)+"&pg_atom="+String.valueOf(oAtm.getInt(DB.pg_atom))+"&gu_company="+oAtm.getStringNull(DB.gu_company,"")+"&gu_contact="+oAtm.getStringNull(DB.gu_contact,"")+"&tx_email="+oAtm.getStringNull(DB.tx_email,"")+"\"-->"+sPBody.substring(iEndBody);
	  	} // fi </body>
	  } // fi (bo_webbeacon)
	  
      oSentMsg = oDraft.composeFinalMessage(oHndlr.getSession(), oDraft.getSubject(),
                                            sPBody, getParameter("id"),
                                            sFormat, sEncoding, bAttachInlineImages);

      // If there is no mail address at the atom then send message to recipients
      // that are already set into message object itself.
      // If there is a mail address at the atom then send message to that recipient
      if (!oAtm.isNull(DB.tx_email)) {
        if (DebugFile.trace) DebugFile.writeln("tx_email="+oAtm.getString(DB.tx_email));
        String sSanitizedEmail = MailMessage.sanitizeAddress(oAtm.getString(DB.tx_email));
        if (DebugFile.trace) DebugFile.writeln("sanitized tx_email="+sSanitizedEmail);
        // An AddressException can be thrown here even after sanitizing the e-mail address
        InternetAddress oRec = DBInetAddr.parseAddress(sSanitizedEmail);

		// No blacklisted e-mails allowed to pass through
	    if (aBlackList==null) {
	      bBlackListed = false;
	    } else {
	      bBlackListed = (Arrays.binarySearch(aBlackList,oAtm.getString(DB.tx_email).toLowerCase())>=0 ||
	      	              Arrays.binarySearch(aBlackList,sSanitizedEmail.toLowerCase())>=0);
	    }
		if (bBlackListed)
		  throw new SQLException("Could not sent message to "+sSanitizedEmail+" because it is blacklisted");
        
        String sRecType = oAtm.getStringNull(DB.tp_recipient,"to");
        if (sRecType.equalsIgnoreCase("to"))
          oSentMsg.setRecipient(Message.RecipientType.TO, oRec);
        else if (sRecType.equalsIgnoreCase("cc"))
          oSentMsg.setRecipient(Message.RecipientType.CC, oRec);
        else
          oSentMsg.setRecipient(Message.RecipientType.BCC, oRec);
      } else {
        if (DebugFile.trace) DebugFile.writeln("tx_email is null");
      }

      // Set From and Reply-To addresses
	  if (DebugFile.trace) {
	  	DebugFile.writeln("from "+aFrom[0].getAddress());
	  	DebugFile.writeln("reply-to "+aReply[0].getAddress());
	  }
      oSentMsg.addFrom(aFrom);
      oSentMsg.setReplyTo(aReply);

	  // Request read notification
	  String sNotification = getParameter("notification");
      if (Activated.equals(sNotification) || Yes.equals(sNotification)) {
        if (DebugFile.trace) DebugFile.writeln("Disposition-Notification-To "+aFrom[0].getAddress());
	    oSentMsg.addHeader("Disposition-Notification-To", aFrom[0].getAddress());
      }
	  
      // Send message here
      String sTestMode = getParameter("testmode");
      if (Activated.equals(sTestMode) || Yes.equals(sTestMode)) {

		if (DebugFile.trace) DebugFile.writeln("Test mode activated, skiping recipient "+oAtm.getStringNull(DB.tx_email,""));

      } else {

      	JDCConnection oConn = null;
      	if (oBeforeSend==null) {
      	  oConn = getDataBaseBind().getConnection("MimeSender.process");
      	  oBeforeSend = new Boolean (Event.getEvent(oConn, iDomainId, "beforesmtpmime")!=null);
      	  oConn.close("MimeSender.process");
      	}
		if (DebugFile.trace) DebugFile.writeln("beforesmtpmime event hook is "+(oBeforeSend.booleanValue() ? "activated" : "deactivated"));
      	if (oBeforeSend.booleanValue()) {
		  HashMap oJobParams = new HashMap(size()*2);
		  oJobParams.putAll(this);
		  oJobParams.putAll(oAtm.getItemMap());
		  oJobParams.put("bin_smtpmessage", oSentMsg);
		  oConn = getDataBaseBind().getConnection("MimeSender.process");
		  if (DebugFile.trace) DebugFile.writeln("triggering beforesmtpmime event handler");
		  Event.trigger(oConn, iDomainId, "beforesmtpmime", oJobParams, getProperties());
      	  oConn.close("MimeSender.process");
      	}

        oHndlr.sendMessage(oSentMsg);

      } // fi testmode

    } catch (Exception e) {
      if (DebugFile.trace) {
        DebugFile.writeStackTrace(e);
        DebugFile.write("\n");
        DebugFile.decIdent();
        DebugFile.writeln("End MimeSender.process("+oAtm.getString(DB.gu_job)+":"+String.valueOf(oAtm.getInt(DB.pg_atom))+") : abnormal process termination");
      }
      throw new MessagingException(e.getMessage(),e);
    } finally {
      // Decrement de count of atoms pending of processing at this job
      if (DebugFile.trace) DebugFile.writeln("decrementing pending atoms to "+String.valueOf(iPendingAtoms-1));
      if (0==--iPendingAtoms) {
        free();
      } // fi (iPendingAtoms==0)
    }

    if (DebugFile.trace) {
      DebugFile.writeln("End MimeSender.process("+oAtm.getString(DB.gu_job)+":"+String.valueOf(oAtm.getInt(DB.pg_atom))+")");
      DebugFile.decIdent();
    }

    return oSentMsg;
 } // process

 // ----------------------------------------------------------------------------

 public void setPending(int nPending) {
 	iPendingAtoms = nPending;
 }

 // ----------------------------------------------------------------------------

 public static MimeSender newInstance(JDCConnection oConn, String sJobGroup,
 									  String sIdWrkA, String sGuUser,
 									  Date dtExecution, short iInitialStatus,
                                      String sTxTitle, String sTxParameters)
    throws SQLException {
    MimeSender oJob = new MimeSender();
    oJob.put(DB.gu_workarea, sIdWrkA);
    oJob.put(DB.gu_writer, sGuUser);
    oJob.put(DB.id_command, Job.COMMAND_SEND);
    oJob.put(DB.tl_job, Gadgets.left(sTxTitle,100));   
    oJob.put(DB.tx_parameters, sTxParameters);
	oJob.put(DB.id_status, iInitialStatus);
    if (null!=sJobGroup) oJob.put(DB.gu_job_group, sJobGroup);
    if (null!=dtExecution) oJob.put(DB.dt_execution, dtExecution);
    oJob.store(oConn);

    PreparedStatement oUpdt = oConn.prepareStatement("UPDATE "+DB.k_mime_msgs+" SET "+DB.gu_job+"=? WHERE "+DB.gu_mimemsg+"=?");
    oUpdt.setString(1, oJob.getString(DB.gu_job));
    oUpdt.setString(2, oJob.getParameter("message"));
    oUpdt.executeUpdate();
    oUpdt.close();

    return oJob;
 } // newInstance

 // ----------------------------------------------------------------------------

 public static MimeSender newInstance(JDCConnection oConn, String sProfile, String sIdWrkA,
                                      String sGuMsg, String sIdMsg,
                                      String sGuUser, String sGuAccount,
                                      boolean bIsPersonalizedMail,
                                      String sTxTitle)
   throws SQLException {


   if (DebugFile.trace) {
     DebugFile.writeln("Begin MimeSender.newInstance(JDCConnection, "+sProfile+", "+sIdWrkA+", "+sGuMsg+", "+sIdMsg+", "+sGuUser+", "+sGuAccount+", "+String.valueOf(bIsPersonalizedMail)+", "+sTxTitle+")");
     DebugFile.incIdent();
   }

   MimeSender oJob = MimeSender.newInstance(oConn, null, sIdWrkA, sGuUser, null, Job.STATUS_PENDING, sTxTitle,
											"profile:"+sProfile+
                              				",id:"+sIdMsg+
                              				",message:"+sGuMsg+
                              				",account:"+sGuAccount+
                              				",personalized:"+String.valueOf(bIsPersonalizedMail)+
                              				",notification:false");

   if (DebugFile.trace) {
     DebugFile.writeln("End MimeSender.newInstance() " + oJob.getStringNull(DB.gu_job,"null"));
     DebugFile.decIdent();
   }

   return oJob;
 } // newInstance

 // ----------------------------------------------------------------------------

 public static MimeSender newInstance(JDCConnection oConn, String sProfile, String sIdWrkA,
                                      String sGuMsg, String sIdMsg,
                                      String sGuUser, String sGuAccount,
                                      boolean bIsPersonalizedMail,
                                      String sTxTitle,
                                      boolean bNotification)
   throws SQLException {


   if (DebugFile.trace) {
     DebugFile.writeln("Begin MimeSender.newInstance([JDCConnection:"+oConn.pid()+"], "+sProfile+", "+sIdWrkA+", "+sGuMsg+", "+sIdMsg+", "+sGuUser+", "+sGuAccount+", "+String.valueOf(bIsPersonalizedMail)+", "+sTxTitle+")");
     DebugFile.incIdent();
   }

   MimeSender oJob = MimeSender.newInstance(oConn, null, sIdWrkA, sGuUser, null, Job.STATUS_PENDING, sTxTitle,
											"profile:"+sProfile+
                              				",id:"+sIdMsg+
                              				",message:"+sGuMsg+
                              				",account:"+sGuAccount+
                              				",personalized:"+String.valueOf(bIsPersonalizedMail)+
                              				",notification:"+String.valueOf(bNotification));

   if (DebugFile.trace) {
     DebugFile.writeln("End MimeSender.newInstance() " + oJob.getStringNull(DB.gu_job,"null"));
     DebugFile.decIdent();
   }

   return oJob;
 } // newInstance

 // ----------------------------------------------------------------------------

 /**
  * <P>MimeSender.main() is used for sending bulk mailing from the command line</P>
  * This methods creates a new Job for sending the e-mails or reloads a previously
  * existing one that was interrupted, resuming the Job execution at the point that
  * it was left.
  *
  * For sending e-mails you must have previously configured a mail account at
  * hipermail module and have a List of recipients created at the Contacts Manager.
  *
  * Provide as argument the name without extension of a .cnf file located at your
  * profiles directory /by default /etc on Linux or C:\Windows on Windows).
  * This file must contain the following properties:
  * # hipergate MimeSender bulk mailer sample configuration file
  * # Database
  * driver=org.postgresql.Driver
  * dburl=jdbc\:postgresql\://127.0.0.1\:5432/postgres
  * schema=
  * dbpassword=postgres
  * dbuser=postgres
  * poolsize=5
  * maxconnections=10
  * connectiontimeout=20000
  * connectionreaperdelay=31536000000
  * 
  * # File System
  * fileserver=localhost
  * fileprotocol=file\://
  * fileuser=
  * storage=C\:\\ARCHIV~1\\Tomcat\\storage
  * temp=C\:\\Windows\\Temp
  * 
  * # Mail System
  * mail.account=name_of_hipermail_account
  * mail.list=List description
  * mail.job.title=Unique name for mail batch
  *
  * The message body must be placed at a file under storage/mailing/List description
  * (in the previous example it would be C:\ARCHIV~1\Tomcat\storage\mailing\List description)
  * The message body file must be named body.htm if message is in HTML format
  * or body.txt if it is in plain text format.
  * @throws IOException
  * @throws SQLException
  **/
 public static void main(String[] args) throws IOException,SQLException {
   int nSent = 0;
   int nErrs = 0;
   FileSystem oFs = new FileSystem();
   DBBind oDbb = null;
   JDCConnection oCon = null;
   PreparedStatement oStm = null;
   ResultSet oRst = null;
   MimeSender oSnd = null;
   SessionHandler oHnl = null;
   DBStore  oSto = null;
   DBFolder oFld = null;
   DBSubset oLists = new DBSubset(DB.k_lists,DB.gu_list,DB.gu_list+"=? OR "+DB.de_list+"=?",1);
   DBSubset oMaccs = new DBSubset(DB.k_user_mail,DB.gu_account,DB.gu_account+"=? OR "+DB.tl_account+"=?",1);
      
   if (args==null) {
     System.out.println("Mail batch descriptor is required");
   } else if (args.length==0) {
     System.out.println("Mail batch descriptor is required");  
   } else {
   	 try {
   	   System.out.println("Connecting to database...");
   	   oDbb = new DBBind(args[0]);
   	   System.out.println("Database connection was successfull");
   	   if (oDbb.getProperty("storage")==null) {
         System.out.println("storage property is required but not found at "+args[0]+".cnf file");
         nErrs++; 	     
   	   } else {

   	   if (oDbb.getProperty("mail.list")==null) {
         System.out.println("mail.list property is required but not found at "+args[0]+".cnf file");   
         nErrs++; 	     
   	   } else {
   	   	 String sMailingDir = Gadgets.chomp(oDbb.getProperty("storage"), File.separator)+"mailing"+File.separator+oDbb.getProperty("mail.list");
		 String sBody = null;
		 String sType = null;
		 String sBodyFile = sMailingDir+File.separator+"body.htm";
		 
		 if (new File(sMailingDir+File.separator+"body.htm").exists()) {
           System.out.println("Trying to read file "+sMailingDir+File.separator+"body.htm");
		   sBody = oFs.readfilestr("file://"+sMailingDir+File.separator+"body.htm","UTF-8");
		   sType = "html";		   
		 } else if (new File("file://"+sMailingDir+File.separator+"body.txt").exists()) {
           System.out.println("Trying to read file "+sMailingDir+File.separator+"body.txt");
		   sBody = oFs.readfilestr("file://"+sMailingDir+File.separator+"body.txt","UTF-8");
		   sType = "plain";		   
		 }
		 if (null==sBody) {
           System.out.println("Could not find body.htm nor body.txt files at directory "+sMailingDir);
           nErrs++;
		 } else {

           oCon = oDbb.getConnection("MimeSender.main()");
           oCon.setAutoCommit(false);
           int nLists = oLists.load(oCon, new Object[]{oDbb.getProperty("mail.list").trim(),oDbb.getProperty("mail.list").trim()});
           if (nLists==0) {
             System.out.println("Mailing list "+oDbb.getProperty("mail.list")+" not found at k_lists table");
             nErrs++;
           } else if (nLists>1) {       
             System.out.println("Ambiguous name for mailing list "+oDbb.getProperty("mail.list"));
             nErrs++;
           } else {
             Date dtNow = new Date();

             if (oDbb.getProperty("mail.account")==null) {
               System.out.println("mail.account property is required but not found at "+args[0]+".cnf file");   
               nErrs++;
             } else {           
               int nMaccs = oMaccs.load(oCon, new Object[]{oDbb.getProperty("mail.account").trim(),oDbb.getProperty("mail.account").trim()});
               if (nMaccs==0) {
                 System.out.println("Mailing account "+oDbb.getProperty("mail.account")+" not found at k_user_mail table");
                 nErrs++;
               } else if (nMaccs>1) {       
                 System.out.println("Ambiguous name for mailing account "+oDbb.getProperty("mail.account"));
                 nErrs++;
               } else {
                 System.out.println("Composing message...");
                 DistributionList oLst = new DistributionList(oCon, oLists.getString(0,0));
                 oLists = null;
                 System.out.println("Getting mail account...");
                 MailAccount oAcc = new MailAccount(oCon, oMaccs.getString(0,0));
                 ACLUser oUsr = new ACLUser(oCon, oAcc.getString(DB.gu_user));
                 System.out.println("Got mail");
                 String sMBoxDir = DBStore.MBoxDirectory(oDbb.getProfileName(),
                                                       oUsr.getInt(DB.id_domain),
                                                       oUsr.getString(DB.gu_workarea));
                 System.out.println("mbox directory is "+sMBoxDir);
                 System.out.println("Opening mail session... ");
                 oHnl = new SessionHandler(oAcc);
         
                 oSto = DBStore.open (oHnl.getSession(), oDbb.getProfileName(), sMBoxDir,
                                      oUsr.getString(DB.gu_user), oUsr.getString(DB.tx_pwd));
                 oFld = oSto.openDBFolder("outbox", DBFolder.READ_WRITE);
                 System.out.println("Creating message template...");
         
                 DBMimeMessage oMsg = DraftsHelper.draftMessage(oFld, oDbb.getProperty("mail.host","127.0.0.1"),
                                                                oUsr.getString(DB.gu_workarea),
                                                                oUsr.getString(DB.gu_user), sType);
                 DraftsHelper.draftUpdate (oCon, oUsr.getInt(DB.id_domain),
                                           oUsr.getString(DB.gu_workarea),
                                           oMsg.getMessageGuid(),
                                           DBCommand.queryStr(oCon, "SELECT "+DB.id_message+" FROM "+DB.k_mime_msgs+
    								 	                      " WHERE "+DB.gu_mimemsg+"='"+oMsg.getMessageGuid()+"'"),
                                           oLst.getString(DB.tx_from),
                                           oLst.getStringNull(DB.tx_reply,oLst.getString(DB.tx_from)),
                                           oLst.getStringNull(DB.tx_sender,oLst.getString(DB.tx_from)),
                                           oLst.getStringNull(DB.tx_subject,""),
                                           "text/"+sType+"; charset=utf-8",
                                           sBody, null, null, null);

                 System.out.println("Message template successfully composed");
                 String sGuJob = null;
                 if (null!=oDbb.getProperty("mail.job.title")) {
                   oStm = oCon.prepareStatement("SELECT "+DB.gu_job+" FROM "+DB.k_jobs+" WHERE "+
                                                DB.tl_job+"=? AND "+DB.gu_workarea+"=?");
                   oStm.setString(1, oDbb.getProperty("mail.job.title"));
                   oStm.setString(2, oLst.getString(DB.gu_workarea));
                   oRst = oStm.executeQuery();
                   if (oRst.next()) sGuJob = oRst.getString(1);
                   oRst.close();
                   oRst=null;
                   oStm.close();
                   oStm=null;
                 } // fi
         
                 if (null==sGuJob) {
                   oSnd = newInstance(oCon, oLst.getString(DB.gu_list),
                                      oLst.getString(DB.gu_workarea),
                                      oUsr.getString(DB.gu_user), dtNow,
                                      Job.STATUS_RUNNING,
                                      oDbb.getProperty("mail.job.title",oLst.getStringNull(DB.de_list,"")+" "+dtNow.toString()),
                                      "profile:"+oDbb.getProfileName()+
                                      ",id:"+oMsg.getMessageID()+
                                      ",message:"+oMsg.getMessageGuid()+
                                      ",account:"+oAcc.getString(DB.gu_account)+
                                      ",gu_list:"+oLst.getString(DB.gu_list)+
                                      ",personalized:"+String.valueOf(true)+
                                      ",bo_attachimages:1");
                 } else {
                   oSnd = new MimeSender();
                   oSnd.load(oCon, sGuJob);
                   oSnd.setStatus(oCon, Job.STATUS_RUNNING);
                 }
                 oSnd.setDataBaseBind(oDbb);

                 oFld.close(false);
                 oFld=null;
                 oSto.close();
                 oSto=null;
                 oHnl.close();
                 oHnl=null;

                 System.out.println("Loading queue...");

                 if (null==sGuJob) {
                   AtomFeeder oAfd = new AtomFeeder();
                   oAfd.loadAtoms (oCon, oSnd.getString(DB.gu_job), Atom.STATUS_RUNNING);         
                 }

                 oCon.commit();
         
                 oSnd.setPending(DBCommand.queryInt(oCon,"SELECT COUNT(*) FROM "+DB.k_job_atoms+" WHERE "+DB.gu_job+"='"+oSnd.getString(DB.gu_job)+"' AND "+DB.id_status+"="+String.valueOf(Atom.STATUS_RUNNING)));

                 System.out.println("Queue loaded with "+String.valueOf(oSnd.pending())+" mails to be sent");

                 oStm = oCon.prepareStatement("SELECT a.*, j." + DB.tx_parameters + " FROM " + DB.k_job_atoms + " a, " + DB.k_jobs + " j WHERE a." + DB.id_status + "=" + String.valueOf(Atom.STATUS_RUNNING) + " AND j." + DB.gu_job + "=a." + DB.gu_job + " AND j." + DB.gu_job + "=? ORDER BY "+DB.pg_atom,
                                              ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

                 oStm.setString(1, oSnd.getString(DB.gu_job));
                 oRst = oStm.executeQuery();
                 ResultSetMetaData oMdt = oRst.getMetaData();
                 boolean bHasNext = oRst.next();
                 while (bHasNext) {
                   Atom oAtm = new Atom(oRst, oMdt);
                   oAtm.replace(DB.id_format,sType);
                   try {                   	
                     oSnd.process(oAtm);
                     oAtm.archive(oCon);                     
                     oCon.commit();
                     nSent++;
                     System.out.println("Mail number "+String.valueOf(oAtm.getInt(DB.pg_atom))+" "+oAtm.getString(DB.tx_email)+" sent OK");
                   } catch (SQLException sqle) {
                     nErrs++;
                     System.out.println("Mail number "+String.valueOf(oAtm.getInt(DB.pg_atom))+" "+oAtm.getString(DB.tx_email)+" failed with SQLException "+sqle.getMessage());
                     if (DebugFile.trace) DebugFile.writeln("SQLException at atom "+String.valueOf(oAtm.getInt(DB.pg_atom))+" "+sqle.getMessage()+" "+StackTraceUtil.getStackTrace(sqle));
                     try { oCon.rollback(); oAtm.setStatus(oCon, Atom.STATUS_INTERRUPTED, "SQLException "+sqle.getMessage()); oCon.commit(); } catch (SQLException ignore) { }
                     oRst.close(); oRst=null;
                 	 oStm.close(); oStm=null;
                     break;
                   } catch (NullPointerException npe) {
                     nErrs++;
                     System.out.println("Mail number "+String.valueOf(oAtm.getInt(DB.pg_atom))+" "+oAtm.getString(DB.tx_email)+" failed with NullPointerException "+npe.getMessage());
                     if (DebugFile.trace) DebugFile.writeln("NullPointerException at atom "+String.valueOf(oAtm.getInt(DB.pg_atom))+" "+npe.getMessage()+" "+StackTraceUtil.getStackTrace(npe));
                     try { oCon.rollback(); oAtm.setStatus(oCon, Atom.STATUS_INTERRUPTED, "NullPointerException "+npe.getMessage()); oCon.commit(); } catch (SQLException ignore) { }
                     oRst.close(); oRst=null;
                 	 oStm.close(); oStm=null;
                     break;
                   } catch (MessagingException msge) {
                     nErrs++;
                     System.out.println("Mail number "+String.valueOf(oAtm.getInt(DB.pg_atom))+" "+oAtm.getString(DB.tx_email)+" failed with MessagingException "+msge.getMessage());
                     if (DebugFile.trace) DebugFile.writeln(msge.getClass().getName()+" at atom "+String.valueOf(oAtm.getInt(DB.pg_atom))+" "+msge.getMessage()+" "+StackTraceUtil.getStackTrace(msge));
                     try { oCon.rollback(); oAtm.setStatus(oCon, Atom.STATUS_INTERRUPTED, "MessagingException "+msge.getMessage()); oCon.commit(); } catch (SQLException ignore) { }
                   } finally {
                     bHasNext = oRst.next();
                   }
                 } //wend
                 if (null!=oRst) oRst.close();
                 oRst=null;
                 if (null!=oStm) oStm.close();
                 oStm=null;
                 if (oSnd.getStatus()==Job.STATUS_RUNNING) {
                   System.out.println("Finishing job...");
                   oSnd.setStatus(oCon, Job.STATUS_FINISHED);
                 } else {
                   System.out.println("Job finished abnormaly.");
                 }
                 oSnd=null;     
               } // fi
             } 
           } // fi
           oCon.close("MimeSender.main()");
           oCon=null;
	     }
       } // fi   	   	 
     }

   	 System.out.println("Disconnecting from database...");

   	 oDbb.close();
   	 oDbb=null;
   	 if (nErrs==0)
   	   System.out.println("Bulk mailing sucessfully finished, "+String.valueOf(nSent)+" messages sent");
   	 else
   	   System.out.println("Bulk mailing finished with errors, "+String.valueOf(nSent)+" message"+(nSent==1 ? "s" : "")+" sent and "+String.valueOf(nErrs)+" error"+(nErrs==1 ? "s" : ""));
   	 } catch (Exception xcpt) {
   	   System.out.println(xcpt.getClass().getName()+" "+xcpt.getMessage());
   	   System.out.println(StackTraceUtil.getStackTrace(xcpt));
   	   if (oFld!=null) try { oFld.close(false); } catch (MessagingException ignore) { }
   	   if (oSto!=null) try { oSto.close(); } catch (MessagingException ignore) { }
   	   if (oHnl!=null) try { oHnl.close(); } catch (MessagingException ignore) { }
   	   if (oSnd!=null) {
   	   	 try {
   	   	   if (null!=oCon) if (!oCon.isClosed()) oSnd.setStatus(oCon, Job.STATUS_INTERRUPTED);
   	   	   oSnd.free();
   	     } catch (Exception ignore) { }
   	   }
   	   if (oRst!=null) oRst.close();
   	   if (oStm!=null) oStm.close();   	   
   	   if (null!=oCon) {
   	   	if (!oCon.getAutoCommit()) oCon.rollback();
   	   	if (!oCon.isClosed()) oCon.close("MimeSender.main()");
   	   }
   	   if (null!=oDbb) { oDbb.close(); }
   	 }
   } // fi
 }

} // MimeSender
