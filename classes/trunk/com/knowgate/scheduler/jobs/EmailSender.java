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

package com.knowgate.scheduler.jobs;

import java.lang.ref.SoftReference;

import java.util.HashMap;
import java.util.Iterator;

import java.sql.SQLException;

import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.io.StringBufferInputStream;

import java.net.URL;
import java.net.MalformedURLException;

import javax.activation.DataHandler;
import javax.activation.FileDataSource;

import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.MessagingException;
import javax.mail.NoSuchProviderException;
import javax.mail.BodyPart;

import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMultipart;

import org.htmlparser.Parser;
import org.htmlparser.Node;
import org.htmlparser.util.NodeIterator;
import org.htmlparser.util.ParserException;
import org.htmlparser.tags.ImageTag;

import org.apache.oro.text.regex.*;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataxslt.FastStreamReplacer;
import com.knowgate.dfs.FileSystem;

import com.knowgate.scheduler.Atom;
import com.knowgate.scheduler.Job;


/**
 * <p>Add database fields to a document template and send it to a mail recipient</p>
 * <p>Mails are send using Sun JavaMail</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class EmailSender extends Job {

  // This flag is set if the first Job execution finds replacements of the form
  // {#Section.Field} witch is data retrived from the database and inserted
  // dynamically into the document final template.
  // If the execution of this job for the first Atom find no tags of the form
  // {#Section.Field} then the replacement subroutine can be skipped in next
  // execution saving CPU cycles.
  private boolean bHasReplacements;

  // This is a soft reference to a String holding the base document template
  // if virtual memory runs low the garbage collector can discard the soft
  // reference that would be reloaded from disk later upon the next atom processing
  private SoftReference oFileStr;

  // A reference to the replacer class witch maps tags of the form {#Section.Field}
  // to their corresponding database fields.
  private FastStreamReplacer oReplacer;

  // javax.mail objects
  Session oMailSession;
  Transport oMailTransport;

  // Images repeated at HTML document are only attached once and referenced multiple times
  // This hashmap keeps a record of the file names of images that have been already attached.
  HashMap oDocumentImages;

  // Because the HTML may be loaded once and then passed throught FastStreamReplacer
  // and be send multiple times, a Soft Reference to a String holding the HTML is kept.
  private SoftReference oHTMLStr;

  // ---------------------------------------------------------------------------

  public EmailSender() {
    bHasReplacements = true;
    oFileStr = null;
    oHTMLStr = null;
    oReplacer = new FastStreamReplacer();
    oDocumentImages = new HashMap();
    oMailSession = null;
    oMailTransport = null;
  }

  // ---------------------------------------------------------------------------

  public void free() {}

  // ---------------------------------------------------------------------------

  /**
   * <p>Set Job Status</p>
   * <p>If Status if set to Job.STATUS_FINISHED then dt_finished is set to current
   * system date.</p>
   * <p>If Status if set to any value other than Job.STATUS_RUNNING then the MailTransport is closed.
   * @param oConn Database Connection
   * @param iStatus Job Status
   * @throws SQLException
   */
  public void setStatus(JDCConnection oConn, int iStatus) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin EmailSender.setStatus([Connection], " + String.valueOf(iStatus) + ")");
      DebugFile.incIdent();
    }

    super.setStatus(oConn, iStatus);

    if (Job.STATUS_RUNNING!=iStatus) {

      if (oMailTransport!=null) {
        try {
          if (oMailTransport.isConnected())
            oMailTransport.close();
        }
        catch (MessagingException msge) {
          if ( DebugFile.trace)
            DebugFile.writeln("Transport.close() MessagingException " + msge.getMessage());
        }

        oMailTransport = null;
      } // fi (oMailTransport)

      if (null!=oMailSession) oMailSession = null;

    } // fi (STATUS_RUNNING)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End EMailSender.setStatus()");
    }
  } // setStatus

  // ---------------------------------------------------------------------------

  private String attachFiles(String sHTMLPath) throws FileNotFoundException,IOException {
    String sHtml = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin EmailSender.attachFiles(" + sHTMLPath + ")");
      DebugFile.incIdent();
      DebugFile.writeln("new File(" + sHTMLPath + ")");
    }

    try {
      FileSystem oFS = new FileSystem();
      sHtml = oFS.readfilestr(sHTMLPath, null);
      oFS = null;
    }
    catch (com.enterprisedt.net.ftp.FTPException ftpe) {}

    PatternMatcher oMatcher = new Perl5Matcher();
    PatternCompiler oCompiler = new Perl5Compiler();

    Parser parser = Parser.createParser(sHtml, null);

    StringBuffer oRetVal = new StringBuffer(sHtml.length());

    try {
      for (NodeIterator i = parser.elements(); i.hasMoreNodes(); ) {
        Node node = i.nextNode();

        if (node instanceof ImageTag) {
          ImageTag oImgNode = (ImageTag) node;
          String sSrc = oImgNode.extractImageLocn();
          String sTag = oImgNode.getText();

          Pattern oPattern;

          try {
            oPattern = oCompiler.compile(sSrc);
          } catch (MalformedPatternException neverthrown) { oPattern=null; }

          if (!oDocumentImages.containsKey(sSrc)) {
            int iSlash = sSrc.lastIndexOf('/');
            String sCid;

            if (iSlash>=0) {
              while (sSrc.charAt(iSlash)=='/') { if (++iSlash==sSrc.length()) break; }
              sCid = sSrc.substring(iSlash);
            }
            else
              sCid = sSrc;

            oDocumentImages.put(sSrc, sCid);
          }

          oRetVal.append(Util.substitute(oMatcher, oPattern,
                         new Perl5Substitution("cid:"+oDocumentImages.get(sSrc),
                                               Perl5Substitution.INTERPOLATE_ALL),
                         sTag, Util.SUBSTITUTE_ALL));

        }
        else {
          oRetVal.append(node.getText());
        }
      }
    }
    catch (ParserException pe) {
      if (DebugFile.trace) {
        DebugFile.writeln("ParserException " + pe.getMessage());
      }

      oRetVal = new StringBuffer(sHtml.length());
      oRetVal.append(sHtml);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End EmailSender.attachFiles()");
    }

    return oRetVal.toString();
  } // attachFiles

  // ---------------------------------------------------------------------------

  /**
   * <p>Send PageSet document instance by e-mail.</p>
   * <p>Transforming and sending aPageSet is a two stages task. First the PageSet
   * stylesheet is combined via XSLT with user defined XML data and an XHTML
   * document is pre-generated. This document still contains fixed database reference
   * tags. At second stage the database reference tags are replaced for each document
   * using FastStreamReplacer. Thus PageSet templates must have been previously
   * transformed via XSLT before sending the PageSet instance by e-mail.</p>
   * <p>This method uses javax.mail package for e-mail sending</p>
   * <p>Parameters for locating e-mail server are stored at properties
   * mail.transport.protocol, mail.host, mail.user from hipergate.cnf</p>
   * <p>If parameter bo_attachimages is set to "1" then any &lt;IMG SRC=""&gt; tag
   * will be replaced by a cid: reference to an attached file.</p>
   * @param oAtm Atom containing reference to PageSet.<br>
   * Atom must have the following parameters set:<br>
   * <table border=1 cellpadding=4>
   * <tr><td>gu_workarea</td><td>GUID of WorkArea owner of document to be sent</td></tr>
   * <tr><td>gu_pageset</td><td>GUID of PageSet to be sent</td></tr>
   * <tr><td>nm_pageset</td><td>Name of PageSet to be sent</td></tr>
   * <tr><td>bo_attachimages</td><td>"1" if must attach images on document,<br>"0" if images must be absolute references</td></tr>
   * <tr><td>tx_sender</td><td>Full Name of sender to be displayed</td></tr>
   * <tr><td>tx_from</td><td>Sender e-mail address</td></tr>
   * <tr><td>tx_subject</td><td>e-mail subject</td></tr>
   * </table>
   * @return String with document template after replacing database tags
   * @throws FileNotFoundException
   * @throws IOException
   * @throws MessagingException
   * @see com.knowgate.dataxslt.FastStreamReplacer
   */
  public Object process (Atom oAtm) throws FileNotFoundException,IOException,MessagingException {

    File oFile;                      // Document Template File
    FileReader oFileRead;            // Document Template Reader
    String sPathHTML;                // Full Path to Document Template File
    char cBuffer[];                  // Internal Buffer for Document Template File Data
    StringBufferInputStream oInStrm; // Document Template File Data after replacing images src http: with cid:
    Object oReplaced;                // Document Template File Data after FastStreamReplacer processing
    final String Yes = "1";

    final String sSep = System.getProperty("file.separator"); // Alias for file.separator

    if (DebugFile.trace) {
      DebugFile.writeln("Begin EMailSender.process([Job:" + getStringNull(DB.gu_job, "") + ", Atom:" + String.valueOf(oAtm.getInt(DB.pg_atom)) + "])");
      DebugFile.incIdent();
    }

    if (bHasReplacements) { // Initially the document is assumed to have tags to replace

      // *************************************************
      // Compose the full path to document template file

      // First get the storage base path from hipergate.cnf
      sPathHTML = getProperty("workareasput");
      if (!sPathHTML.endsWith(sSep)) sPathHTML += sSep;

        // Concatenate PageSet workarea guid and subpath to Mailwire application directory
      sPathHTML += getParameter("gu_workarea") + sSep + "apps" + sSep + "Mailwire" + sSep + "html" + sSep + getParameter("gu_pageset") + sSep;

      // Concatenate PageSet Name
      sPathHTML += getParameter("nm_pageset").replace(' ', '_') + ".html";

      if (DebugFile.trace) DebugFile.writeln("PathHTML = " + sPathHTML);

      // ***********************************************************************
      // Change <IMG SRC=""> tags for embeding document images into mime message

      if (Yes.equals(getParameter("bo_attachimages"))) {

        if (DebugFile.trace) DebugFile.writeln("bo_attachimages=true");

        // Check first the SoftReference to the tag-replaced in-memory String cache
        oInStrm = null;

        if (null!=oHTMLStr) {
          if (null!=oHTMLStr.get())
            // Get substituted html source as a StringBufferInputStream suitable
            // for FastStreamReplacer replace() method.
            oInStrm = new StringBufferInputStream((String) oHTMLStr.get());
        }
        if (null==oInStrm)
          // If SoftReference was not found then
          // call html processor for <IMG> tag substitution
          oInStrm = new StringBufferInputStream(attachFiles(sPathHTML));

        oHTMLStr = new SoftReference(oInStrm);

        // Call FastStreamReplacer for {#Section.Field} tags
        oReplaced = oReplacer.replace(oInStrm, oAtm.getItemMap());
      }

      else { // do not attach images with message body

        if (DebugFile.trace) DebugFile.writeln("bo_attachimages=false");

        // Call FastStreamReplacer for {#Section.Field} tags
        oReplaced = oReplacer.replace(sPathHTML, oAtm.getItemMap());
      }

      // Count number of replacements done and update bHasReplacements flag accordingly
      bHasReplacements = (oReplacer.lastReplacements() > 0);
    }

    else {

      oReplaced = null;

      if (null != oFileStr)
        oReplaced = oFileStr.get();

      if (null == oReplaced) {

        // If document template has no database replacement tags
        // then just cache the document template into a SoftReference String

        // Compose the full path to document template file
        sPathHTML = getProperty("workareasput");
        if (!sPathHTML.endsWith(sSep)) sPathHTML += sSep;

        sPathHTML += getParameter("gu_workarea") + sSep + "apps" + sSep + "Mailwire" + sSep + "html" + sSep + getParameter("gu_pageset") + sSep + getParameter("nm_pageset").replace(' ', '_') + ".html";

        if (DebugFile.trace) DebugFile.writeln("PathHTML = " + sPathHTML);

        // ***************************
        // Read document template file

        if (DebugFile.trace) DebugFile.writeln("new File(" + sPathHTML + ")");

        oFile = new File(sPathHTML);

        cBuffer = new char[new Long(oFile.length()).intValue()];

        oFileRead = new FileReader(oFile);
        oFileRead.read(cBuffer);
        oFileRead.close();

        if (DebugFile.trace) DebugFile.writeln(String.valueOf(cBuffer.length) + " characters readed");

        if (Yes.equals(getParameter("bo_attachimages")))
          oReplaced = attachFiles(new String(cBuffer));
        else
          oReplaced = new String(cBuffer);

        // *********************************************************
        // Assign SoftReference to File cached in-memory as a String

        oFileStr = new SoftReference(oReplaced);

      } // fi (oReplaced)

    } // fi (bHasReplacements)

    // ***********************************************
    // Send replaced file data by e-mail

    if (null==oMailSession) {
      if (DebugFile.trace) DebugFile.writeln("Session.getInstance(Job.getProperties(), null)");

      java.util.Properties oMailProps = getProperties();

      if (oMailProps.getProperty("mail.transport.protocol")==null)
        oMailProps.put("mail.transport.protocol","smtp");

      if (oMailProps.getProperty("mail.host")==null)
        oMailProps.put("mail.host","localhost");

      oMailSession = Session.getInstance(getProperties(), null);

      if (null!=oMailSession) {
        oMailTransport = oMailSession.getTransport();

        try {
          oMailTransport.connect();
        }
        catch (NoSuchProviderException nspe) {
          if (DebugFile.trace) DebugFile.writeln("MailTransport.connect() NoSuchProviderException " + nspe.getMessage());
          throw new MessagingException(nspe.getMessage(), nspe);
        }
      } // fi (Session.getInstance())
    } // fi (oMailSession)

    MimeMessage oMsg;
    InternetAddress oFrom, oTo;

    try {
      if (null==getParameter("tx_sender"))
        oFrom = new InternetAddress(getParameter("tx_from"));
      else
        oFrom = new InternetAddress(getParameter("tx_from"), getParameter("tx_sender"));

      if (DebugFile.trace) DebugFile.writeln("to: " + oAtm.getStringNull(DB.tx_email, "ERROR Atom[" + String.valueOf(oAtm.getInt(DB.pg_atom)) + "].tx_email is null!"));

      oTo = new InternetAddress(oAtm.getString(DB.tx_email), oAtm.getStringNull(DB.tx_name,"") + " " + oAtm.getStringNull(DB.tx_surname,""));
    }
    catch (AddressException adre) {
      if (DebugFile.trace) DebugFile.writeln("AddressException " + adre.getMessage() + " job " + getString(DB.gu_job) + " atom " + String.valueOf(oAtm.getInt(DB.pg_atom)));

      oFrom = null;
      oTo = null;

      throw new MessagingException ("AddressException " + adre.getMessage() + " job " + getString(DB.gu_job) + " atom " + String.valueOf(oAtm.getInt(DB.pg_atom)));
    }

    if (DebugFile.trace) DebugFile.writeln("new MimeMessage([Session])");

    oMsg = new MimeMessage(oMailSession);

    oMsg.setSubject(getParameter("tx_subject"));

    oMsg.setFrom(oFrom);

    if (DebugFile.trace) DebugFile.writeln("MimeMessage.addRecipient(MimeMessage.RecipientType.TO, " + oTo.getAddress());

    oMsg.addRecipient(MimeMessage.RecipientType.TO, oTo);

    String sSrc = null, sCid = null;

    try {

      // Images may be attached into message or be absolute http source references
      if (Yes.equals(getParameter("bo_attachimages"))) {

        BodyPart oMsgBodyPart = new MimeBodyPart();
        oMsgBodyPart.setContent(oReplaced, "text/html");

        // Create a related multi-part to combine the parts
        MimeMultipart oMultiPart = new MimeMultipart("related");
        oMultiPart.addBodyPart(oMsgBodyPart);

        Iterator oImgs = oDocumentImages.keySet().iterator();

        while (oImgs.hasNext()) {
          BodyPart oImgBodyPart = new MimeBodyPart();

          sSrc = (String) oImgs.next();
          sCid = (String) oDocumentImages.get(sSrc);

          if (sSrc.startsWith("www."))
            sSrc = "http://" + sSrc;

          if (sSrc.startsWith("http://") || sSrc.startsWith("https://")) {
            oImgBodyPart.setDataHandler(new DataHandler(new URL(sSrc)));
          }
          else {
            oImgBodyPart.setDataHandler(new DataHandler(new FileDataSource(sSrc)));
          }

          oImgBodyPart.setHeader("Content-ID", sCid);

          // Add part to multi-part
          oMultiPart.addBodyPart(oImgBodyPart);
        } // wend

        if (DebugFile.trace) DebugFile.writeln("MimeMessage.setContent([MultiPart])");

        oMsg.setContent(oMultiPart);
      }

      else {

        if (DebugFile.trace) DebugFile.writeln("MimeMessage.setContent([String], \"text/html\")");

        oMsg.setContent(oReplaced, "text/html");

      }

      oMsg.saveChanges();

      if (DebugFile.trace) DebugFile.writeln("Transport.sendMessage([MimeMessage], MimeMessage.getAllRecipients())");

      oMailTransport.sendMessage(oMsg, oMsg.getAllRecipients());

      // ************************************************************
      // Decrement de count of atoms peding of processing at this job
      iPendingAtoms--;
    }
    catch (MalformedURLException urle) {

      if (DebugFile.trace) DebugFile.writeln("MalformedURLException " + sSrc);
      throw new MessagingException("MalformedURLException " + sSrc);
    }

    if (DebugFile.trace) {
      DebugFile.writeln("End EMailSender.process([Job:" + getStringNull(DB.gu_job, "") + ", Atom:" + String.valueOf(oAtm.getInt(DB.pg_atom)) + "])");
      DebugFile.decIdent();
    }

    return oReplaced;

  } //process

} // EmailSender
