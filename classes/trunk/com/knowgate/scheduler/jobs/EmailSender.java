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

import java.util.Vector;
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

import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMultipart;

import org.htmlparser.Parser;
import org.htmlparser.Node;
import org.htmlparser.Attribute;
import org.htmlparser.util.NodeList;
import org.htmlparser.util.NodeIterator;
import org.htmlparser.util.ParserException;
import org.htmlparser.nodes.TagNode;
import org.htmlparser.tags.ImageTag;
import org.htmlparser.tags.MetaTag;
import org.htmlparser.tags.CompositeTag;


import org.apache.oro.text.regex.*;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataxslt.FastStreamReplacer;
import com.knowgate.dfs.FileSystem;
import com.knowgate.misc.Gadgets;

import com.knowgate.scheduler.Atom;
import com.knowgate.scheduler.Job;


/**
 * <p>Add database fields to a document template and send it to a mail recipient</p>
 * <p>Mails are send using Sun JavaMail</p>
 * @author Sergio Montoro Ten
 * @version 5.0
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
  private SoftReference<String> oFileStr;

  // A reference to the replacer class witch maps tags of the form {#Section.Field}
  // to their corresponding database fields.
  private FastStreamReplacer oReplacer;

  // javax.mail objects
  Session oMailSession;
  Transport oMailTransport;

  // Images repeated at HTML document are only attached once and referenced multiple times
  // This hashmap keeps a record of the file names of images that have been already attached.
  HashMap<String,String> oDocumentImages;

  // Because the HTML may be loaded once and then passed throught FastStreamReplacer
  // and be send multiple times, a Soft Reference to a String holding the HTML is kept.
  private SoftReference<StringBufferInputStream> oHTMLStr;

  // FileSystem object shared among all atoms
  private FileSystem oFS;

  // ---------------------------------------------------------------------------

  public EmailSender() {
    bHasReplacements = true;
    oFileStr = null;
    oHTMLStr = null;
    oFS = new FileSystem();
    oReplacer = new FastStreamReplacer();
    oDocumentImages = new HashMap<String,String>();
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

  private String parseNode(Node oNode, PatternCompiler oCompiler, PatternMatcher oMatcher)
  	throws FileNotFoundException, IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin EmailSender.parseNode(" + oNode.getClass().getName() + ")");
      DebugFile.incIdent();
    }

	StringBuffer oBuffer = new StringBuffer();
    Pattern oPattern;
    String sTag, sCid;
    int iSlash;

    if (oNode instanceof ImageTag) {
      ImageTag oImgNode = (ImageTag) oNode;
      String sSrc = oImgNode.extractImageLocn();

      try {
        oPattern = oCompiler.compile(sSrc);
      } catch (MalformedPatternException neverthrown) {
        if (DebugFile.trace) DebugFile.writeln("MalformedPatternException "+sSrc);
        oPattern=null;
      }

      iSlash = sSrc.lastIndexOf('/');
      if (iSlash>=0) {
        while (sSrc.charAt(iSlash)=='/') { if (++iSlash==sSrc.length()) break; }
        sCid = sSrc.substring(iSlash);
      } else {
        sCid = sSrc;
      } // fi 
	  
      if (!oDocumentImages.containsKey(sCid)) {

 	    if (DebugFile.trace) DebugFile.writeln("HashMap.put(" + sSrc + "," + sCid + ")");

        oDocumentImages.put(sCid, sSrc);
      } // fi (oDocumentImages.containsKey(sCid))

	  sTag = oImgNode.toHtml(true);

	  if (DebugFile.trace) DebugFile.writeln("Util.substitute([Perl5Matcher], "+oPattern.getPattern()+", new Perl5Substitution(cid:"+oDocumentImages.get(sCid)+", Perl5Substitution.INTERPOLATE_ALL)"+", "+sTag+ ", Util.SUBSTITUTE_ALL)");

	  oBuffer.append(Util.substitute(oMatcher, oPattern,
	                                 new Perl5Substitution("cid:"+sCid,
                                                           Perl5Substitution.INTERPOLATE_ALL),
                                     sTag, Util.SUBSTITUTE_ALL));

    } else if (oNode instanceof TagNode && oNode.toHtml().toLowerCase().startsWith("<link")) {

      TagNode oLnkNode = (TagNode) oNode;
      String sSrc = oLnkNode.getAttribute("href");
	  String sType = oLnkNode.getAttribute("type");
	  if (sType==null) sType="text/css";
	  
	  if (sType.equalsIgnoreCase("text/css")) {

	    oBuffer.append("<style type=\"text/css\">\n<!--\n");
	    try {
	      oBuffer.append(oFS.readfile(sSrc));
	    } catch (com.enterprisedt.net.ftp.FTPException ftpe) {
	      throw new IOException(sSrc, ftpe);
	    }
	    oBuffer.append("\n-->\n</style>\n");

	  } else {

        try {
          oPattern = oCompiler.compile(sSrc);
        } catch (MalformedPatternException neverthrown) {
          if (DebugFile.trace) DebugFile.writeln("MalformedPatternException "+sSrc);
          oPattern=null;
        }

        iSlash = sSrc.lastIndexOf('/');
        if (iSlash>=0) {
          while (sSrc.charAt(iSlash)=='/') { if (++iSlash==sSrc.length()) break; }
          sCid = sSrc.substring(iSlash);
        } else {
          sCid = sSrc;
        } // fi 

        if (!oDocumentImages.containsKey(sCid)) {

 	      if (DebugFile.trace) DebugFile.writeln("HashMap.put(" + sSrc + "," + sCid + ")");

          oDocumentImages.put(sCid, sSrc);
        } // fi (oDocumentImages.containsKey(sCid))

	    sTag = oLnkNode.toHtml(true);

	    if (DebugFile.trace) DebugFile.writeln("Util.substitute([Perl5Matcher], "+oPattern.getPattern()+", new Perl5Substitution(cid:"+oDocumentImages.get(sCid)+", Perl5Substitution.INTERPOLATE_ALL)"+", "+sTag+ ", Util.SUBSTITUTE_ALL)");

	    oBuffer.append(Util.substitute(oMatcher, oPattern,
	                                   new Perl5Substitution("cid:"+sCid,
                                                             Perl5Substitution.INTERPOLATE_ALL),
                                       sTag, Util.SUBSTITUTE_ALL));
	  }
    } else if (oNode instanceof CompositeTag) {

      try {
      	CompositeTag oCTag = (CompositeTag) oNode;
        oBuffer.append("<");
        Vector oAttrs = oCTag.getAttributesEx();
        int nAttrs = oAttrs.size();
        for (int a=0; a<nAttrs; a++) {
          Attribute oAttr = (Attribute) oAttrs.get(a);
          oAttr.toString(oBuffer);
        }
        oBuffer.append(">");
        NodeList oChilds = oNode.getChildren();
        if (oChilds!=null) {
          for (NodeIterator i = oNode.getChildren().elements(); i.hasMoreNodes(); ) {
            Node oChildNode = i.nextNode();
            oBuffer.append(parseNode(oChildNode, oCompiler, oMatcher));
          } // next
        } // fi
        oBuffer.append(oCTag.getEndTag().toTagHtml());
        
      } catch (ParserException xcpt) {
        if (DebugFile.trace) DebugFile.writeln("ParserException "+xcpt.getMessage());      
      }

    } else if (oNode instanceof MetaTag) {

	  // Ignore meta tags in e-mails

    } else {

      oBuffer.append(oNode.toHtml(true));

    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End EmailSender.parseNode()");
    }

    return oBuffer.toString();
  } // parseNode

  // ---------------------------------------------------------------------------

  private String attachFiles(String sHTMLPath) throws FileNotFoundException,IOException {
    String sHtml = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin EmailSender.attachFiles(" + sHTMLPath + ")");
      DebugFile.incIdent();
      DebugFile.writeln("new File(" + sHTMLPath + ")");
    }

    try {
      sHtml = oFS.readfilestr(sHTMLPath, null);
    }
    catch (com.enterprisedt.net.ftp.FTPException ftpe) {}

	if (null==sHtml) throw new FileNotFoundException(sHTMLPath);
	if (sHtml.length()==0) throw new FileNotFoundException(sHTMLPath);

    PatternMatcher oMatcher = new Perl5Matcher();
    PatternCompiler oCompiler = new Perl5Compiler();

    Parser parser = Parser.createParser(sHtml, null);

    StringBuffer oRetVal = new StringBuffer(sHtml.length());

    try {
      for (NodeIterator i = parser.elements(); i.hasMoreNodes(); ) {
        Node oNode = i.nextNode();
		oRetVal.append(parseNode(oNode, oCompiler, oMatcher));
      } // next
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
      DebugFile.writeln("End EmailSender.attachFiles() : " + oRetVal.toString().replace('\n',' '));
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
   * <tr><td>nm_page</td><td>File Name of HTML page to be sent</td></tr>
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
    String oReplaced;                // Document Template File Data after FastStreamReplacer processing
    final String Yes = "1";

    final String sSep = System.getProperty("file.separator"); // Alias for file.separator

    if (DebugFile.trace) {
      DebugFile.writeln("Begin EMailSender.process([Job:" + getStringNull(DB.gu_job, "") + ", Atom:" + String.valueOf(oAtm.getInt(DB.pg_atom)) + "])");
      DebugFile.incIdent();
      DebugFile.writeln("document has "+(bHasReplacements ? "" : " no ")+"replacements");
    }

    if (bHasReplacements) { // Initially the document is assumed to have tags to replace

      // *************************************************
      // Compose the full path to document template file

      // First get the storage base path from hipergate.cnf
      sPathHTML = getParameter("workareasput");
      if (null==sPathHTML) sPathHTML = getProperty("workareasput");
      if (!sPathHTML.endsWith(sSep)) sPathHTML += sSep;

        // Concatenate PageSet workarea guid and subpath to Mailwire application directory
      sPathHTML += getParameter("gu_workarea") + sSep + "apps" + sSep + "Mailwire" + sSep + "html" + sSep + getParameter("gu_pageset") + sSep;

      // Concatenate HTML Page Name
      sPathHTML += getParameter("nm_page").replace(' ', '_');

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
            oInStrm = oHTMLStr.get();
        }
        if (null==oInStrm)
          // If SoftReference was not found then
          // call html processor for <IMG> tag substitution
          oInStrm = new StringBufferInputStream(attachFiles(sPathHTML));

        oHTMLStr = new SoftReference<StringBufferInputStream>(oInStrm);

        // Call FastStreamReplacer for {#Section.Field} tags
        oReplaced = oReplacer.replace(oInStrm, oAtm.getItemMap());
      }

      else { // do not attach images with message body

        if (DebugFile.trace) DebugFile.writeln("bo_attachimages=false");

        // Call FastStreamReplacer for {#Section.Field} tags
        oReplaced = oReplacer.replace(sPathHTML, oAtm.getItemMap());
      }

	  if (DebugFile.trace) DebugFile.writeln("document has "+String.valueOf(oReplacer.lastReplacements())+" replacements");

      // Count number of replacements done and update bHasReplacements flag accordingly
      bHasReplacements = (oReplacer.lastReplacements() > 0);
    }

    else { // !bHasReplacements

      oReplaced = null;

      if (null != oFileStr)
        oReplaced = oFileStr.get();

      if (null == oReplaced) {

        // If document template has no database replacement tags
        // then just cache the document template into a SoftReference String

        // Compose the full path to document template file
        sPathHTML = getProperty("workareasput");
        if (!sPathHTML.endsWith(sSep)) sPathHTML += sSep;

        sPathHTML += getParameter("gu_workarea") + sSep + "apps" + sSep + "Mailwire" + sSep + "html" + sSep + getParameter("gu_pageset") + sSep + getParameter("nm_page").replace(' ', '_');

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

        oFileStr = new SoftReference<String>(oReplaced);

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
    MimeMultipart oAltParts = new MimeMultipart("alternative");
    
    // Set alternative plain/text part to avoid spam filters as much as possible
    MimeBodyPart oMsgTextPart = new MimeBodyPart();
	oMsgTextPart.setText("This message is HTML, but your e-mail client is not capable of rendering HTML messages", "UTF-8", "plain");

    MimeBodyPart oMsgBodyPart = new MimeBodyPart();
	
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
	  
	  // Insert Web Beacon just before </BODY> tag
	  if (Yes.equals(getParameter("bo_webbeacon"))) {
	  	int iEndBody = Gadgets.indexOfIgnoreCase(oReplaced, "</body>", 0);
	  	if (iEndBody>0) {
	  	  String sWebBeaconDir = getProperty("webbeacon");	  	  
	  	  if (sWebBeaconDir==null) {
	  	  	sWebBeaconDir = Gadgets.chomp(getParameter("webserver"),'/')+"hipermail/";
	  	  } else if (sWebBeaconDir.trim().length()==0) {
	  	  	sWebBeaconDir = Gadgets.chomp(getParameter("webserver"),'/')+"hipermail/";
	  	  }
	  	  oReplaced = oReplaced.substring(0, iEndBody)+"<img src=\""+Gadgets.chomp(sWebBeaconDir,'/')+"web_beacon.jsp?gu_job="+getString(DB.gu_job)+"&pg_atom="+String.valueOf(oAtm.getInt(DB.pg_atom))+"&gu_company="+oAtm.getStringNull(DB.gu_company,"")+"&gu_contact="+oAtm.getStringNull(DB.gu_contact,"")+"&tx_email="+oAtm.getStringNull(DB.tx_email,"")+"\" width=\"1\" height=\"1\" border=\"0\" alt=\"\" />"+oReplaced.substring(iEndBody);	  	  	
	  	} // fi </body>
	  } // fi (bo_webbeacon)
      
      // Images may be attached into message or be absolute http source references
      if (Yes.equals(getParameter("bo_attachimages"))) {

        if (DebugFile.trace) DebugFile.writeln("BodyPart.setText("+oReplaced.replace('\n',' ')+",UTF-8,html)");

        oMsgBodyPart.setText(oReplaced, "UTF-8", "html");

        // Create a related multi-part to combine the parts
        MimeMultipart oRelatedMultiPart = new MimeMultipart("related");
        oRelatedMultiPart.addBodyPart(oMsgBodyPart);

        Iterator<String> oImgs = oDocumentImages.keySet().iterator();

        while (oImgs.hasNext()) {
          MimeBodyPart oImgBodyPart = new MimeBodyPart();

          sCid = oImgs.next();
          sSrc = oDocumentImages.get(sCid);

          if (sSrc.startsWith("www."))
            sSrc = "http://" + sSrc;

          if (sSrc.startsWith("http://") || sSrc.startsWith("https://")) {
            oImgBodyPart.setDataHandler(new DataHandler(new URL(sSrc)));
          }
          else {
            oImgBodyPart.setDataHandler(new DataHandler(new FileDataSource(sSrc)));
          }

          oImgBodyPart.setContentID(sCid);
          oImgBodyPart.setDisposition(oImgBodyPart.INLINE);
          oImgBodyPart.setFileName(sCid);

          // Add part to multi-part
          oRelatedMultiPart.addBodyPart(oImgBodyPart);
        } // wend

        MimeBodyPart oTextHtmlRelated = new MimeBodyPart();
        oTextHtmlRelated.setContent(oRelatedMultiPart);

		oAltParts.addBodyPart(oMsgTextPart);
		oAltParts.addBodyPart(oTextHtmlRelated);

    	MimeMultipart oSentMsgParts = new MimeMultipart("mixed");
 		MimeBodyPart oMixedPart = new MimeBodyPart();
        
        oMixedPart.setContent(oAltParts);
        oSentMsgParts.addBodyPart(oMixedPart);
        
        oMsg.setContent(oSentMsgParts);
      }

      else {

        if (DebugFile.trace) DebugFile.writeln("BodyPart.setText("+oReplaced.replace('\n',' ')+",UTF-8,html)");

		oMsgBodyPart.setText(oReplaced, "UTF-8", "html");

		oAltParts.addBodyPart(oMsgTextPart);
		oAltParts.addBodyPart(oMsgBodyPart);

        oMsg.setContent(oAltParts);

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
