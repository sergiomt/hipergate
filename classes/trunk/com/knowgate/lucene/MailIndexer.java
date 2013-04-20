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

package com.knowgate.lucene;

import java.io.IOException;
import java.io.InputStream;
import java.io.File;

import java.sql.SQLException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.PreparedStatement;

import java.util.Properties;
import java.util.Date;

import java.math.BigDecimal;

import java.text.SimpleDateFormat;

import javax.mail.MessagingException;
import javax.mail.internet.MimeBodyPart;

import org.htmlparser.beans.StringBean;

import org.apache.lucene.index.Term;
import org.apache.lucene.store.Directory;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.IndexReader;
import org.apache.lucene.document.DateTools;
import org.apache.lucene.document.Document;
import org.apache.lucene.document.Field;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipermail.DBMimePart;
import com.knowgate.dfs.FileSystem;
import org.htmlparser.Parser;
import org.htmlparser.util.ParserException;

/**
 * Indexer subclass for e-mail messages
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class MailIndexer extends Indexer {

  private static SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  public MailIndexer() { }

  /**
   * Add a single mail message to the index
   * @param oIWrt IndexWriter
   * @param sGuid String GUID of mime message to be indexed (from gu_mimemsg field of table k_mime_msgs)
   * @param dNumber BigDecimal mime message number (from pg_message field of table k_mime_msgs)
   * @param sWorkArea String GUID of WorkArea (from gu_workarea field of table k_mime_msgs)
   * @param sContainer String Name of Category (Folder) where message is stored.
   * This is nm_category field at k_categories table record corresponding to gu_category from k_mime_msgs
   * @param sSubject String Subject
   * @param sAuthor String Display name of message sender
   * @param sRecipients String Recipients list (both display name and e-mails)
   * @param dtSent Date
   * @param sComments String
   * @param oStrm InputStream Full mime message body as an InputStream (from by_content field of table k_mime_msgs)
   * @throws ClassNotFoundException
   * @throws IOException
   * @throws IllegalArgumentException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws NullPointerException
   */
  public static void addMail(IndexWriter oIWrt,
                             String sGuid, BigDecimal dNumber, String sWorkArea,
                             String sContainer, String sSubject,
                             String sAuthor, String sRecipients, Date dtSent,
                             String sComments, InputStream oStrm, int iSize)
      throws ClassNotFoundException, IOException, IllegalArgumentException,
             NoSuchFieldException, IllegalAccessException, InstantiationException,
             NullPointerException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin MailIndexer.addMail([IndexWriter], "+sGuid+", "+dNumber+", "+sWorkArea+", "+
	  				    sContainer+", "+sSubject+", "+sAuthor+", "+sRecipients+", "+dtSent+", "+
	  				    sComments+", [InputStream], "+String.valueOf(iSize)+")");
	  DebugFile.incIdent();
	}
    
    String sText;
    String sAbstract = sGuid+"¨"+sSubject+"¨"+sAuthor+"¨"+oFmt.format(dtSent)+"¨"+String.valueOf(iSize)+"¨"+dNumber.toString();
    sSubject = Gadgets.ASCIIEncode(sSubject);
    sAuthor = Gadgets.ASCIIEncode(sAuthor);

    if (null != oStrm) {
      StringBuffer oStrBuff = new StringBuffer();
      try {
        MimeBodyPart oMsgText = new MimeBodyPart(oStrm);
        DBMimePart.parseMimePart(oStrBuff, null, sContainer, "", oMsgText, 0);
      } catch (MessagingException xcpt) {
        if (DebugFile.trace)
          DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage()+" indexing message "+sGuid+" - "+sSubject);
      }
      if (oStrBuff.length()>0) {
        if (Gadgets.indexOfIgnoreCase(oStrBuff.toString(), "<html>")>=0) {
          Parser oPrsr = Parser.createParser(oStrBuff.toString(), null);
          StringBean oStrs = new StringBean();
          try {
            oPrsr.visitAllNodesWith (oStrs);
          } catch (ParserException pe) {
            if (DebugFile.trace) DebugFile.decIdent();
            throw new IOException(pe.getMessage());          
          }

          if (DebugFile.trace) DebugFile.writeln("Gadgets.ASCIIEncode(StringBean.getStrings())");
          sText = Gadgets.ASCIIEncode(oStrs.getStrings());
          if (DebugFile.trace) DebugFile.writeln("StringBean.getStrings() done");
        } // fi (oStrBuff contains <html>)
        else {
          if (DebugFile.trace) DebugFile.writeln("Gadgets.ASCIIEncode(StringBuffer.toString())");
          sText = Gadgets.ASCIIEncode(oStrBuff.toString());
          if (null==sText) sText = "";
          if (DebugFile.trace) DebugFile.writeln("StringBuffer.toString() done");
        }
      } else {
        sText = "";
      }
    } // fi (oStrm)
    else {
      sText = "";
    }

    Document oDoc = new Document();
    oDoc.add (new Field ("workarea" , sWorkArea, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("container", sContainer, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("guid"     , sGuid, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("number"   , dNumber.toString(), Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("created"  , DateTools.dateToString(dtSent, DateTools.Resolution.SECOND), Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("size"     , Gadgets.leftPad(String.valueOf(iSize),'0',10), Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("title"    , Gadgets.ASCIIEncode(sSubject), Field.Store.YES, Field.Index.ANALYZED));
    oDoc.add (new Field ("author"   , Gadgets.ASCIIEncode(sAuthor), Field.Store.YES, Field.Index.ANALYZED));
    oDoc.add (new Field ("abstract" , sAbstract, Field.Store.YES, Field.Index.ANALYZED));
    oDoc.add (new Field ("recipients",sRecipients, Field.Store.YES, Field.Index.ANALYZED));
    oDoc.add (new Field ("comments" , sComments, Field.Store.NO, Field.Index.ANALYZED));
    oDoc.add (new Field ("text"     , sText, Field.Store.NO, Field.Index.ANALYZED));

    if (DebugFile.trace) DebugFile.writeln("IndexWriter.addDocument([Document])");

    oIWrt.addDocument(oDoc);

	if (DebugFile.trace) {
	  DebugFile.writeln("End MailIndexer.addMail()");
	  DebugFile.decIdent();
	}
  } // addMail

  /**
   * <p>Re-build full text index for a given mail folder</p>
   * All previously indexed messages for given folder are removed from index and written back
   * @param oProps Properties containing: luceneindex, driver, dburl, dbuser, dbpassword
   * @param sWorkArea String GUID of WorkArea to which folder belongs
   * @param sFolder String Folder name as in field nm_category of table k_categories
   * @throws SQLException
   * @throws IOException
   * @throws ClassNotFoundException
   * @throws IllegalArgumentException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   */
  public static void rebuildFolder(Properties oProps, String sWorkArea, String sFolder)
    throws SQLException, IOException, ClassNotFoundException,
           IllegalArgumentException, NoSuchFieldException,
           IllegalAccessException, InstantiationException {

    String sGuid, sContainer, sTitle, sAuthor, sComments;
    Date dtCreated;
    BigDecimal dNumber;
    int iSize;

    final BigDecimal dZero = new BigDecimal(0);

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MailIndexer.rebuildFolder([Properties]" + sWorkArea + "," + sFolder + ")");
      DebugFile.incIdent();
    }

    // Get physical base path to index files from luceneindex property
    String sDirectory = oProps.getProperty("luceneindex");

    if (null==sDirectory) throw new NoSuchFieldException ("Cannot find luceneindex property");

    // Append WorkArea and table name to luceneindex base path
    sDirectory = Gadgets.chomp(sDirectory, File.separator) + "k_mime_msgs";
    if (null!=sWorkArea) sDirectory += File.separator + sWorkArea;

    if (DebugFile.trace) DebugFile.writeln("index directory is " + sDirectory);

    if (null==oProps.getProperty("driver"))
      throw new NoSuchFieldException ("Cannot find driver property");

    if (null==oProps.getProperty("dburl"))
      throw new NoSuchFieldException ("Cannot find dburl property");

    if (DebugFile.trace) DebugFile.writeln("Class.forName(" + oProps.getProperty("driver") + ")");

    Class oDriver = Class.forName(oProps.getProperty("driver"));

    if (DebugFile.trace) DebugFile.writeln("IndexReader.open("+sDirectory+")");

    // *********************************************************************
    // Delete every document from this folder before re-indexing
    
    File oDir = new File(sDirectory);
    if (oDir.exists()) {
      File[] aSegments = oDir.listFiles();
      if (null!=aSegments) {
	    if (aSegments.length>0) {
	      Directory oRdDir = Indexer.openDirectory(sDirectory);
          IndexReader oReader = IndexReader.open(oRdDir);
          int iDeleted = oReader.deleteDocuments(new Term("container", sFolder));
          oReader.close();
          oRdDir.close();
	    } // fi 
      } // fi
    } else {
      FileSystem oFS = new FileSystem();
      try { oFS.mkdirs(sDirectory); } catch (Exception e) { throw new IOException(e.getClass().getName()+" "+e.getMessage()); }
    } // fi    
    // *********************************************************************

    if (DebugFile.trace) DebugFile.writeln("new IndexWriter("+sDirectory+",[Analyzer], true)");

    Directory oFsDir = Indexer.openDirectory(sDirectory);
    IndexWriter oIWrt = new IndexWriter(oFsDir, Indexer.instantiateAnalyzer(oProps), IndexWriter.MaxFieldLength.LIMITED);

    if (DebugFile.trace)
      DebugFile.writeln("DriverManager.getConnection(" + oProps.getProperty("dburl") + ", ...)");

    Connection oConn = DriverManager.getConnection(oProps.getProperty("dburl"), oProps.getProperty("dbuser"),oProps.getProperty("dbpassword"));

    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    ResultSet oRSet;

      PreparedStatement oRecp = oConn.prepareStatement("SELECT tx_personal,tx_email FROM k_inet_addrs WHERE tp_recipient<>'to' AND gu_mimemsg=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeQuery(SELECT m.gu_workarea,c.nm_category,m.gu_mimemsg,m.tx_subject,m.nm_from,m.tx_email_from,m.pg_message,m.de_mimemsg,m.dt_sent,m.len_mimemsg,m.by_content FROM k_mime_msgs m, k_categories c WHERE m.bo_deleted=0 AND m.bo_draft=0 AND m.gu_category=c.gu_category AND m.gu_workarea='"+sWorkArea+"' AND c.nm_category='"+sFolder+"')");

      oRSet = oStmt.executeQuery("SELECT m.gu_workarea,c.nm_category,m.gu_mimemsg,m.tx_subject,m.nm_from,m.tx_email_from,m.pg_message,m.de_mimemsg,m.dt_sent,m.len_mimemsg,m.by_content FROM k_mime_msgs m, k_categories c WHERE m.bo_deleted=0 AND m.bo_draft=0 AND m.gu_category=c.gu_category AND m.gu_workarea='"+sWorkArea+"' AND c.nm_category='"+sFolder+"'");

	  int nIndexed = 0;

      while (oRSet.next()) {

        sWorkArea = oRSet.getString(1);
        sContainer = oRSet.getString(2);
        sGuid = oRSet.getString(3);
        sTitle = oRSet.getString(4);
        sAuthor = oRSet.getString(5);
        if (oRSet.wasNull()) sAuthor = "";
        sAuthor += " " + oRSet.getString(6);
        dNumber = oRSet.getBigDecimal(7);
        if (oRSet.wasNull()) dNumber = dZero;
        sComments = oRSet.getString(8);
        if (oRSet.wasNull()) sComments = "";
        dtCreated = oRSet.getDate(9);
        iSize = oRSet.getInt(10);

        if (DebugFile.trace) DebugFile.writeln("Indexing message "+sGuid+" - "+sTitle);

        InputStream oStrm = oRSet.getBinaryStream(11);

        String sRecipients = "";
        oRecp.setString(1, sGuid);
        ResultSet oRecs = oRecp.executeQuery();
        while (oRecs.next()) {
          String sTxPersonal = oRecs.getString(1);
          if (oRecs.wasNull())
            sRecipients += oRecs.getString(2)+" ";
          else
            sRecipients += oRecs.getString(1)+" "+oRecs.getString(2)+" ";
        } // wend
        oRecs.close();

        MailIndexer.addMail(oIWrt, sGuid, dNumber, sWorkArea, sContainer, sTitle,
                            sAuthor, sRecipients, dtCreated, sComments,
                            oStrm, iSize);
        nIndexed++;

      } // wend

      if (DebugFile.trace) {
        DebugFile.writeln(String.valueOf(nIndexed)+" messages indexed");
      }

      oRSet.close();
      oRecp.close();

    if (DebugFile.trace) {
      DebugFile.writeln("Statement.executeUpdate(UPDATE k_mime_msgs SET bo_indexed=1 WHERE gu_workarea='"+sWorkArea+"' AND gu_category IN (SELECT gu_category FROM k_categories WHERE nm_category='"+sFolder+"'))");
    }

    oStmt.executeUpdate("UPDATE k_mime_msgs SET bo_indexed=1 WHERE gu_workarea='"+sWorkArea+"' AND gu_category IN (SELECT gu_category FROM k_categories WHERE nm_category='"+sFolder+"')");

    oStmt.close();
    oConn.close();

    if (DebugFile.trace) DebugFile.writeln("IndexWriter.optimize()");

    oIWrt.optimize();

    if (DebugFile.trace) DebugFile.writeln("IndexWriter.close()");

    oIWrt.close();
    oFsDir.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MailIndexer.rebuildFolder()");
    }
  } // rebuildFolder

}
