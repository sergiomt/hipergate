/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

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

import java.math.BigDecimal;

import java.util.Date;
import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.ListIterator;

import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.Properties;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.File;

import org.apache.lucene.index.Term;
import org.apache.lucene.index.IndexReader;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.store.Directory;
import org.apache.lucene.store.NIOFSDirectory;
import org.apache.lucene.store.db.DbDirectory;
import org.apache.lucene.document.DateTools;
import org.apache.lucene.document.Field;
import org.apache.lucene.document.Field.Index;
import org.apache.lucene.document.Document;
import org.apache.lucene.analysis.Analyzer;
import org.apache.lucene.analysis.StopAnalyzer;
import org.apache.lucene.util.Version;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.FileSystem;


/**
 * <p>Data Feeder from hipergate tables for Lucene</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 * @see http://lucene.apache.org/java/3_0_1/api/all/overview-summary.html
 */

public class Indexer {

  public final static String DEFAULT_ANALYZER = "org.apache.lucene.analysis.StopAnalyzer";

  // ---------------------------------------------------------------------------

  /**
   * Open Lucene Directory
   * @param sDirectoryPath String Full path to Directory location.
   * Use a disk path for opening a NIOFSDirectory o preffix the
   * path with bdb:// for opening a Berkely DB DbDirectory like "bdb:///opt/storage/db/"
   * @throws IOException
   * @since 7.0
   */
  public static Directory openDirectory(String sDirectoryPath)
    throws IOException {
	Directory oDir;
    if (sDirectoryPath.startsWith("bdb://")) {
      oDir = DBDirectory.open(sDirectoryPath.substring(6));
    } else if (sDirectoryPath.startsWith("file://"))  {
      oDir = new NIOFSDirectory(new File(sDirectoryPath.substring(7)));
    } else {
      oDir = new NIOFSDirectory(new File(sDirectoryPath));    
    }
    return oDir;
  }

  // ---------------------------------------------------------------------------

  /**
   * Instantiate a subclass of org.apache.lucene.analysis.Analyzer
   * @param oProps Properties Must contain a property named "analyzer" which is
   * the full class name of the desired Analyzer subclass. If no analyzer property
   * is set then org.apache.lucene.analysis.StopAnalyzer is instantiated by default.
   * @throws ClassNotFoundException
   * @throws InstantiationException
   * @throws IllegalAccessException
   * @since 7.0
   */
  public static Analyzer instantiateAnalyzer(Properties oProps)
    throws ClassNotFoundException,InstantiationException,IllegalAccessException {	
    Analyzer oAnal;
	String sClassName = oProps.getProperty("analyzer", DEFAULT_ANALYZER);
    if (DebugFile.trace) DebugFile.writeln("Class.forName(" + sClassName + ")");
	if (sClassName.equals("org.apache.lucene.analysis.StopAnalyzer"))
	  oAnal = new StopAnalyzer(Version.LUCENE_33);
	else
	  oAnal = ((Analyzer) Class.forName(sClassName).newInstance());
    return oAnal;
  }

  // ---------------------------------------------------------------------------

  private static String IfNull(Connection oConn) throws SQLException {
    String sDBMS = oConn.getMetaData().getDatabaseProductName();

    if (sDBMS.equals("PostgreSQL"))
      return "COALESCE";
    else if (sDBMS.equals("Microsoft SQL Server"))
      return "ISNULL";
    else if (sDBMS.equals("Oracle"))
      return "NVL";
    else if (sDBMS.equals("MySQL"))
      return "COALESCE";
    else
      return null;
  }

  // ---------------------------------------------------------------------------

  private static boolean allowedTable(String sTableName) {
    return sTableName.equalsIgnoreCase("k_bugs") || sTableName.equalsIgnoreCase("k_newsmsgs") || sTableName.equalsIgnoreCase("k_mime_msgs")||sTableName.equalsIgnoreCase("k_contacts");
  }

  // ---------------------------------------------------------------------------

  /**
   * Optimize a given index
   * @param oProps Properties Collection (typically loaded from hipergate.cnf)
   * containing luceneindex property and (optionally) analyzer
   * @param sTableName String Name of table to be indexed (currently only k_bugs, k_newsmsgs or k_mime_msgs are permitted)
   * @param sWorkArea GUID of WorkArea to be optimized
   * @throws NoSuchFieldException
   * @throws IllegalArgumentException
   * @throws ClassNotFoundException
   * @throws IOException
   * @throws InstantiationException
   * @throws IllegalAccessException
   */
  public static void optimize(Properties oProps, String sTableName, String sWorkArea)
    throws NoSuchFieldException,IllegalArgumentException, ClassNotFoundException,
           FileNotFoundException,IOException,InstantiationException,IllegalAccessException {

    if (!allowedTable(sTableName))
      throw new IllegalArgumentException("Table name must be k_bugs or k_newsmsgs or k_mime_msgs");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Indexer.rebuild([Properties]" + sTableName);
      DebugFile.incIdent();
    }

    String sDirectory = oProps.getProperty("luceneindex");

    if (null==sDirectory) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NoSuchFieldException ("Cannot find luceneindex property");
    }

    sDirectory = Gadgets.chomp(sDirectory, File.separator) + sTableName.toLowerCase();
    if (null!=sWorkArea) sDirectory += File.separator + sWorkArea;

    if (DebugFile.trace) DebugFile.writeln("index directory is " + sDirectory);

    File oDir = new File(sDirectory);
    if (!oDir.exists()) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new FileNotFoundException("Directory " + sDirectory + " does not exist");
    }

    if (DebugFile.trace)
      DebugFile.writeln("new IndexWriter(...)");

    Directory oFsDir = openDirectory(sDirectory);
    IndexWriter oIWrt = new IndexWriter(oFsDir, instantiateAnalyzer(oProps), IndexWriter.MaxFieldLength.LIMITED);

    if (DebugFile.trace) DebugFile.writeln("IndexWriter.optimize()");

    oIWrt.optimize();

    if (DebugFile.trace) DebugFile.writeln("IndexWriter.close()");

    oIWrt.close();
    oFsDir.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Indexer.optimize()");
    }
  } // optimize

  // ---------------------------------------------------------------------------

  /**
   * <p>Rebuild Full Text Index for a table restricting to a given WorkArea</p>
   * Indexed documents have the following fields:<br>
   * <table border=1 cellpadding=4>
   * <tr><td><b>Field Name</b></td><td><b>Description</b></td><td><b>Indexed</b></td><td><b>Stored</b></td></tr>
   * <tr><td>workarea</td><td>GUID of WorkArea</td><td align=middle>Yes</td><td align=middle>Yes</td></tr>
   * <tr><td>container</td><td>Name of Container (NewsGroup, Project, etc)</td><td align=middle>Yes</td><td align=middle>Yes</td></tr>
   * <tr><td>guid</td><td>GUID for Retrieved Object</td><td align=middle>Yes</td><td align=middle>Yes</td></tr>
   * <tr><td>number</td><td>Object Ordinal Identifier</td><td align=middle>Yes</td><td align=middle>Yes</td></tr>
   * <tr><td>title</td><td>Title or Subject</td><td align=middle>Yes</td><td align=middle>Yes</td></tr>
   * <tr><td>author</td><td>Author</td><td align=middle>Yes</td><td align=middle>Yes</td></tr>
   * <tr><td>text</td><td>Document Text</td><td align=middle>Yes</td><td align=middle>No</td></tr>
   * <tr><td>abstract</td><td>First 80 characters of text</td><td align=middle>No</td><td align=middle>Yes</td></tr>
   * </table>
   * @param oProps Properties Collection (typically loaded from hipergate.cnf) containing:<br>
   * <b>driver</b> : Class name for JDBC driver<br>
   * <b>dburl</b> : Database Connection URL<br>
   * <b>dbuser</b> : Database User<br>
   * <b>dbpassword</b> : Database User Password<br>
   * <b>luceneindex</b> : Base path for Lucene index directories,
   * the rebuilded index will be stored at a subdirectory called as the table name.<br>
   * @param sTableName Name of table to be indexed (currently only k_bugs, k_newsmsgs or k_mime_msgs are permitted)
   * <b>analyzer</b> : org.apache.lucene.analysis.Analyzer subclass name
   * @param sWorkArea GUID of WorkArea to be rebuilt
   * @throws NoSuchFieldException If any of the requiered properties of oProps is not found
   * @throws ClassNotFoundException If JDBC driver or analyzer classes are not found
   * @throws SQLException
   * @throws IOException
   * @throws IllegalArgumentException
   * @throws IllegalAccessException
   * @throws InstantiationException
   */
  public static void rebuild(Properties oProps, String sTableName, String sWorkArea)
    throws SQLException, IOException, ClassNotFoundException,
           IllegalArgumentException, NoSuchFieldException,
           IllegalAccessException, InstantiationException {

    String sGuid, sThread, sContainer, sTitle, sAuthor, sComments, sText;
    Date dtCreated;
    BigDecimal dNumber;
    int iNumber, iSize;

    final BigDecimal dZero = new BigDecimal(0);

    // Check whether table name is any of the allowed ones
    if (!allowedTable(sTableName))
      throw new IllegalArgumentException("Table name must be k_bugs or k_newsmsgs or k_mime_msgs");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Indexer.rebuild([Properties]," + sTableName + "," + sWorkArea + ")");
      DebugFile.incIdent();
    }

    // Get physical base path to index files from luceneindex property
    String sDirectory = oProps.getProperty("luceneindex");

    if (null==sDirectory) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NoSuchFieldException ("Cannot find luceneindex property");
    }

    // Append WorkArea and table name to luceneindex base path
    sDirectory = Gadgets.chomp(sDirectory, File.separator) + sTableName.toLowerCase();
    if (null!=sWorkArea) sDirectory += File.separator + sWorkArea;

    if (DebugFile.trace) DebugFile.writeln("index directory is " + sDirectory);

    if (null==oProps.getProperty("driver")) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NoSuchFieldException ("Cannot find driver property");
    }

    if (null==oProps.getProperty("dburl")) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NoSuchFieldException ("Cannot find dburl property");
    }

    if (DebugFile.trace) DebugFile.writeln("Class.forName(" + oProps.getProperty("driver") + ")");

    Class oDriver = Class.forName(oProps.getProperty("driver"));

    if (DebugFile.trace) DebugFile.writeln("IndexReader.open("+sDirectory+")");

    // *********************************************************************
    // Delete every document from this table and WorkArea before re-indexing
    File oDir = new File(sDirectory);
    if (oDir.exists()) {
      File[] aFiles = oDir.listFiles();
      if (null!=aFiles) {
        if (aFiles.length>0) {
          Directory oFsDir = openDirectory(sDirectory);
          IndexReader oReader = IndexReader.open(oFsDir);      
          int iDeleted = oReader.deleteDocuments(new Term("workarea", sWorkArea));
          oReader.close();
          oFsDir.close();
        }
      }
    } else {
      FileSystem oFS = new FileSystem();
      try { oFS.mkdirs(sDirectory); } catch (Exception e) { throw new IOException(e.getClass().getName()+" "+e.getMessage()); }
    }
    // *********************************************************************

    if (DebugFile.trace) DebugFile.writeln("new IndexWriter("+sDirectory+",[Analyzer], true)");

    Directory oFsDir = openDirectory(sDirectory);
    IndexWriter oIWrt = new IndexWriter(oFsDir, instantiateAnalyzer(oProps), IndexWriter.MaxFieldLength.LIMITED);

    if (DebugFile.trace)
      DebugFile.writeln("DriverManager.getConnection(" + oProps.getProperty("dburl") + ", ...)");

    Connection oConn = DriverManager.getConnection(oProps.getProperty("dburl"), oProps.getProperty("dbuser"),oProps.getProperty("dbpassword"));
    oConn.setAutoCommit(true);

    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    ResultSet oRSet;

    if (sTableName.equalsIgnoreCase("k_bugs")) {

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeQuery(SELECT p.gu_workarea,p.nm_project,b.gu_bug,b.tl_bug,b.dt_modified," + IfNull(oConn) + "(b.nm_reporter,'')," + IfNull(oConn) + "(b.tx_bug_brief,'')," + IfNull(oConn) + "(b.tx_comments,'') FROM k_bugs b, k_projects p WHERE b.gu_project=p.gu_project AND p.gu_owner='"+sWorkArea+"')");

      oRSet = oStmt.executeQuery("SELECT p.gu_owner,p.nm_project,b.gu_bug,b.pg_bug,b.tl_bug,b.dt_modified," + IfNull(oConn) + "(b.nm_reporter,'')," + IfNull(oConn) + "(b.tx_comments,'')," + IfNull(oConn) + "(b.tx_bug_brief,'') FROM k_bugs b, k_projects p WHERE b.gu_project=p.gu_project AND p.gu_owner='"+sWorkArea+"'");

      while (oRSet.next()) {
        sWorkArea = oRSet.getString(1);
        sContainer = oRSet.getString(2);
        sGuid = oRSet.getString(3);
        iNumber = oRSet.getInt(4);
        sTitle = oRSet.getString(5);
        dtCreated = oRSet.getDate(6);
        sAuthor = oRSet.getString(7);
        sComments = oRSet.getString(8);
        if (null==sComments) sComments = "";
        sText = oRSet.getString(9);
        if (null==sText) sText = "";
        BugIndexer.addBug(oIWrt, sGuid, iNumber, sWorkArea, sContainer, sTitle, sAuthor, dtCreated, sComments, sText);
      } // wend
      oRSet.close();
    }

    else if (sTableName.equalsIgnoreCase("k_newsmsgs")) {

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeQuery(SELECT g.gu_workarea,c.nm_category,m.gu_msg,m.tx_subject,m.dt_published," + IfNull(oConn) + "(b.nm_author,'')," + IfNull(oConn) + "(b.tx_msg,'') FROM k_newsmsgs m, k_categories c, k_newsgroups g, k_x_cat_objs x WHERE m.id_status=0 AND m.gu_msg=x.gu_object AND x.gu_category=g.gu_newsgrp AND c.gu_category=g.gu_newsgrp AND g.gu_workarea='"+sWorkArea+"')");

      oRSet = oStmt.executeQuery("SELECT g.gu_workarea,c.nm_category,m.gu_msg,m.gu_thread_msg,m.tx_subject,m.dt_published," + IfNull(oConn) + "(m.nm_author,'')," + IfNull(oConn) + "(m.tx_msg,'') FROM k_newsmsgs m, k_categories c, k_newsgroups g, k_x_cat_objs x WHERE m.id_status=0 AND m.gu_msg=x.gu_object AND x.gu_category=g.gu_newsgrp AND c.gu_category=g.gu_newsgrp AND g.gu_workarea='"+sWorkArea+"'");

      while (oRSet.next()) {
        sWorkArea = oRSet.getString(1);
        sContainer = oRSet.getString(2);
        sGuid = oRSet.getString(3);
        sThread = oRSet.getString(4);        
        sTitle = oRSet.getString(5);
        dtCreated = oRSet.getDate(6);
        sAuthor = oRSet.getString(7);
        sText = oRSet.getString(8);
        NewsMessageIndexer.addNewsMessage(oIWrt, sGuid, sThread, sWorkArea, sContainer, sTitle, sAuthor, dtCreated, sText);
      } // wend
      oRSet.close();
    }
    // Inicio I2E 2009-12-23
    else if (sTableName.equalsIgnoreCase("k_contacts")) {
    	
    	Map<String,ContactRecord> contacts = new HashMap<String,ContactRecord>();
    	String consultas[] = new String[6];
    	consultas[0] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, csc.nm_scourse, csc.lv_scourse FROM k_contacts c, k_contact_short_courses csc WHERE c.gu_workarea='" + sWorkArea + "' AND csc.gu_contact = c.gu_contact";
    	consultas[1] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ccsl.tr_es,ccsl2.tr_es FROM k_contacts c, k_contact_computer_science ccc, k_contact_computer_science_lookup ccsl, k_contact_computer_science_lookup ccsl2 WHERE c.gu_workarea='"+ sWorkArea +"' AND ccc.gu_contact = c.gu_contact AND ccc.nm_skill = ccsl.vl_lookup AND ccc.lv_skill = ccsl2.vl_lookup";
    	consultas[2] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ccsl.tr_en,ccsl2.tr_en FROM k_contacts c, k_contact_computer_science ccc, k_contact_computer_science_lookup ccsl, k_contact_computer_science_lookup ccsl2 WHERE c.gu_workarea='"+ sWorkArea +"' AND ccc.gu_contact = c.gu_contact AND ccc.nm_skill = ccsl.vl_lookup AND ccc.lv_skill = ccsl2.vl_lookup";
    	consultas[3] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ed.nm_degree,'' as level FROM k_contacts c,k_contact_education ce,k_education_degree ed WHERE c.gu_workarea='"+ sWorkArea +"' AND ce.gu_contact = c.gu_contact AND ce.gu_degree= ed.gu_degree";
    	consultas[4] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ll.tr_lang_es,cll.tr_es FROM k_contacts c, k_contact_languages cl, k_lu_languages ll,k_contact_languages_lookup cll WHERE c.gu_workarea='"+ sWorkArea +"' AND c.gu_contact = cl.gu_contact AND cl.id_language = ll.id_language AND cl.lv_language_degree = cll.vl_lookup";
    	consultas[5] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ll.tr_lang_en,cll.tr_en FROM k_contacts c, k_contact_languages cl, k_lu_languages ll,k_contact_languages_lookup cll WHERE c.gu_workarea='"+ sWorkArea +"' AND c.gu_contact = cl.gu_contact AND cl.id_language = ll.id_language AND cl.lv_language_degree = cll.vl_lookup";
    	
    	for(int i=0;i<consultas.length;i++){
            if (DebugFile.trace)
                DebugFile.writeln("Statement.executeQuery(" + consultas[i] + ")");

    		oRSet = oStmt.executeQuery(consultas[i]);

    	    while (oRSet.next()) {
            	sGuid = oRSet.getString(1);
            	sWorkArea = oRSet.getString(2);
            	String sName = oRSet.getString(3);
            	String sSurname = oRSet.getString(4);
            	String sValue = oRSet.getString(5);
            	String sLevel = oRSet.getString(6);
            	if(sLevel==null) sLevel="";
            	ContactRecord contact = contacts.get(sGuid);
            	if(contact==null){
            		contact = new ContactRecord(null,sName+" "+ sSurname,sWorkArea,sGuid);
            		contacts.put(sGuid, contact);
            	}
            	contact.addValue(sValue, sLevel);

            	//ContactIndexer.addDocument(oIWrt, sGuid, sWorkArea, sName, sSurname, ContactRecord.COURSE, sValue, sLevel,null);
            	
            }
    	    oRSet.close();
    	}
    	ContactRecord arrayContactos[] = contacts.values().toArray(new ContactRecord[contacts.size()]);
    	for(int i=0;i<arrayContactos.length;i++){
    		ContactIndexer.addDocument(oIWrt,arrayContactos[i]);
    	}    	    	
      }

    //Fin i2E
      else if (sTableName.equalsIgnoreCase("k_mime_msgs")) {

      LinkedList oIndexedGuids = new LinkedList();

      PreparedStatement oRecp = oConn.prepareStatement("SELECT tx_personal,tx_email FROM k_inet_addrs WHERE tp_recipient<>'to' AND gu_mimemsg=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeQuery(SELECT g.gu_workarea,c.nm_category,m.gu_mimemsg,m.tx_subject,m.nm_from,m.tx_mail_from,m.pg_mimemsg,m.de_mimemsg,m.dt_sent,m.len_mimemsg,m.by_content FROM k_mime_msgs m, k_categories c WHERE m.bo_deleted<>0 AND m.bo_draft<>0 AND m.gu_category=c.gu_category AND m.gu_workarea='"+sWorkArea+"')");

      oRSet = oStmt.executeQuery("SELECT g.gu_workarea,c.nm_category,m.gu_mimemsg,m.tx_subject,m.nm_from,m.tx_mail_from,m.pg_mimemsg,m.de_mimemsg,m.dt_sent,m.len_mimemsg,m.by_content FROM k_mime_msgs m, k_categories c WHERE m.bo_deleted<>0 AND m.bo_draft<>0 AND m.gu_category=c.gu_category AND m.gu_workarea='"+sWorkArea+"'");

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
        dtCreated = oRSet.getDate(9);
        iSize = oRSet.getInt(10);

        if (DebugFile.trace) DebugFile.writeln("Indexing message "+sGuid+" - "+sTitle);

        InputStream oStrm = oRSet.getBinaryStream(11);

        String sRecipients = "";
        oRecp.setString(1, sGuid);
        ResultSet oRecs = oRecp.executeQuery();
        while (oRecs.next()) {
          sRecipients += oRecs.getString(1)+" "+oRecs.getString(2)+" ";
        } // wend
        oRecs.close();

        MailIndexer.addMail(oIWrt, sGuid, dNumber, sWorkArea, sContainer, sTitle,
                            sAuthor, sRecipients, dtCreated, sComments, oStrm, iSize);

        oIndexedGuids.add(sGuid);
      } // wend
      oRSet.close();
      oRecp.close();

      PreparedStatement oUpdt = oConn.prepareStatement("UPDATE k_mime_msgs SET bo_indexed=1 WHERE gu_mimemsg=?");
      ListIterator oIter = oIndexedGuids.listIterator();
      while (oIter.hasNext()) {
        oUpdt.setObject(1, oIter.next(), java.sql.Types.CHAR);
        oUpdt.executeUpdate();
      } // wend
      oUpdt.close();
    } // fi

    oStmt.close();
    oConn.close();

    if (DebugFile.trace) DebugFile.writeln("IndexWriter.optimize()");

    oIWrt.optimize();

    if (DebugFile.trace) DebugFile.writeln("IndexWriter.close()");

    oIWrt.close();
    oFsDir.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Indexer.rebuild()");
    }
  } // rebuild

  // ---------------------------------------------------------------------------

  /**
   * <p>Rebuild Full Text Index for a table for all WorkAreas</p>
   * @param oProps
   * @param sTableName
   * @throws SQLException
   * @throws IOException
   * @throws ClassNotFoundException
   * @throws IllegalArgumentException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   */
  public static void rebuild(Properties oProps, String sTableName)
    throws SQLException, IOException, ClassNotFoundException,
           IllegalArgumentException, NoSuchFieldException,
           IllegalAccessException, InstantiationException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Indexer.rebuild([Properties]," + sTableName + ")");
      DebugFile.incIdent();
    }

	LinkedList oWrkA = new LinkedList();
	Class oDriver = Class.forName(oProps.getProperty("driver"));
    Connection oConn = DriverManager.getConnection(oProps.getProperty("dburl"), oProps.getProperty("dbuser"),oProps.getProperty("dbpassword"));
    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	ResultSet oRSet = oStmt.executeQuery("SELECT gu_workarea FROM k_workareas WHERE bo_active<>0");
	while (oRSet.next()) {
	  oWrkA.add(oRSet.getString(1));
	} // wend
    oRSet.close();
    oStmt.close();
    oConn.close();

	ListIterator oIter = oWrkA.listIterator();
	while (oIter.hasNext()) {
	  rebuild(oProps, sTableName, (String) oIter.next());
	} // wend

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Indexer.rebuild()");
    }    
  } // rebuild

  public static void add(IndexWriter oIWrt,
                         Map oKeywords, Map oTexts, Map oUnStored)
    throws ClassNotFoundException, IOException,
           IllegalArgumentException, NoSuchFieldException,
           IllegalAccessException, InstantiationException,
           NullPointerException {

    String sFieldName;
    Object oFieldValue;
    Document oDoc = new Document();

	// *******************************************
	// Index keywords as stored untokenized fields
	
    Iterator oKeys = oKeywords.keySet().iterator();
    while (oKeys.hasNext()) {
      sFieldName = (String) oKeys.next();
      oFieldValue = oKeywords.get(sFieldName);
      if (null==oFieldValue) oFieldValue = "";
      
      if (oFieldValue.getClass().getName().equals("java.util.Date"))
      	oDoc.add(new Field(sFieldName, DateTools.dateToString((Date) oFieldValue,  DateTools.Resolution.SECOND), Field.Store.YES, Field.Index.NOT_ANALYZED));
      else
      	oDoc.add(new Field(sFieldName, (String) oFieldValue, Field.Store.YES, Field.Index.NOT_ANALYZED));
    } // wend

	// ******************************************************
	// Index titles, authors, etc. as stored tokenized fields

    Iterator oTxts = oTexts.keySet().iterator();
    while (oTxts.hasNext()) {
      sFieldName = (String) oTxts.next();
      oFieldValue = oTexts.get(sFieldName);
      if (null==oFieldValue) oFieldValue = "";
      oDoc.add(new Field(sFieldName, (String) oFieldValue, Field.Store.YES, Field.Index.ANALYZED));
    } // wend

	// *********************************************
	// Index full texts as unstored tokenized fields
	
    Iterator oUnStor = oUnStored.keySet().iterator();
    while (oUnStor.hasNext()) {
      sFieldName = (String) oUnStor.next();
      oFieldValue = oUnStored.get(sFieldName);
      if (null==oFieldValue) oFieldValue = "";
      oDoc.add(new Field(sFieldName, (String) oFieldValue, Field.Store.NO, Field.Index.ANALYZED));
    } // wend
    oIWrt.addDocument(oDoc);
  } // add

  // ---------------------------------------------------------------------------

  public static void add(String sTableName, String sDirectory, String sAnalyzer,
                         Map oKeywords, Map oTexts, Map oUnStored)
      throws ClassNotFoundException, IOException,
             IllegalArgumentException, NoSuchFieldException,
             IllegalAccessException, InstantiationException,
             NullPointerException {

    if (!allowedTable(sTableName))
      throw new IllegalArgumentException("Table name must be k_bugs or k_newsmsgs or k_mime_msgs");

    if (null==sDirectory)
      throw new NoSuchFieldException ("Cannot find luceneindex property");

    File oDir = new File(sDirectory);
    if (!oDir.exists()) {
      FileSystem oFS = new FileSystem();
      try { oFS.mkdirs(sDirectory); } catch (Exception e) { throw new IOException(e.getClass().getName()+" "+e.getMessage()); }
    }

    Class oAnalyzer = Class.forName((sAnalyzer==null) ? DEFAULT_ANALYZER : sAnalyzer);

    NIOFSDirectory oFsDir = new NIOFSDirectory(new File(sDirectory));
    IndexWriter oIWrt = new IndexWriter(oFsDir, (Analyzer) oAnalyzer.newInstance(), IndexWriter.MaxFieldLength.LIMITED);

    add (oIWrt, oKeywords, oTexts, oUnStored);

    oIWrt.close();
    oFsDir.close();
  } // add

  // ---------------------------------------------------------------------------

  /**
   * Add a document to the index
   * @param sTableName k_bugs, k_newsmsgs or k_mime_msgs
   * @param oProps Properties Collection containing luceneindex directory
   * @param sWorkArea WorkArea for document
   * @param sContainer GUID of Category or NewsGroup to which documento belongs
   * @param sGUID Document GUID
   * @param iNumber Document number (optional, may be zero)
   * @param sTitle Document Title (optional, may be <b>null</b>)
   * @param sText Document text (optional, may be <b>null</b>)
   * @param sAuthor Document author (optional, may be <b>null</b>)
   * @param sAbstract Document abstract (optional, may be <b>null</b>)
   * @param sComments Document comments (optional, may be <b>null</b>)
   * @throws ClassNotFoundException
   * @throws IOException
   * @throws IllegalArgumentException If sTableName is not one of { k_bugs, k_newsmsgs, k_mime_msgs }
   * @throws NoSuchFieldException If luceneindex property is not found at oProps
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws NullPointerException
   * @deprecated Use add method from Indexer subclasses instead
   */

  public static void add(String sTableName, Properties oProps,
                         String sGUID, int iNumber, String sWorkArea,
                         String sContainer, String sTitle,
                         String sText, String sAuthor,
                         String sAbstract, String sComments)
      throws ClassNotFoundException, IOException,
             IllegalArgumentException, NoSuchFieldException,
             IllegalAccessException, InstantiationException,
             NullPointerException {

    if (null==sGUID)
      throw new NullPointerException ("Document GUID may not be null");

    if (!sTableName.equalsIgnoreCase("k_bugs") && !sTableName.equalsIgnoreCase("k_newsmsgs") && !sTableName.equalsIgnoreCase("k_mime_msgs"))
      throw new IllegalArgumentException("Table name must be k_bugs or k_newsmsgs or k_mime_msgs");

    String sDirectory = oProps.getProperty("luceneindex");

    if (null==sDirectory)
      throw new NoSuchFieldException ("Cannot find luceneindex property");

    sDirectory = Gadgets.chomp(sDirectory, File.separator) + sTableName.toLowerCase() + File.separator + sWorkArea;
    File oDir = new File(sDirectory);
    if (!oDir.exists()) {
      FileSystem oFS = new FileSystem();
      try { oFS.mkdirs(sDirectory); } catch (Exception e) { throw new IOException(e.getClass().getName()+" "+e.getMessage()); }
    }

    HashMap oKeys = new HashMap(11);
    oKeys.put("workarea" , sWorkArea==null ? "" : sWorkArea);
    oKeys.put("container", sContainer==null ? "" : sContainer);
    oKeys.put("guid", sGUID);
    oKeys.put("number", String.valueOf(iNumber));
    HashMap oTexts = new HashMap(11);
    oTexts.put("title", sTitle==null ? "" : sTitle);
    oTexts.put("author", sAuthor==null ? "" : sAuthor);
    oTexts.put("abstract", sAbstract==null ? "" : Gadgets.left(sAbstract, 80));
    HashMap oUnstor = new HashMap(11);
    oUnstor.put("comments", sComments==null ? "" : sComments);
    oUnstor.put("text", sText==null ? "" : sText);
        
    Directory oFsDir = openDirectory(sDirectory);
    IndexWriter oIWrt = new IndexWriter(oFsDir, instantiateAnalyzer(oProps), IndexWriter.MaxFieldLength.LIMITED);

    add(oIWrt, oKeys, oTexts, oUnstor);
    oIWrt.close();
    oFsDir.close();
  } // add

  // ---------------------------------------------------------------------------

  /**
   * Delete a document with a given GUID
   * @param sTableName k_bugs, k_newsmsgs or k_mime_msgs
   * @param oProps Properties Collection containing luceneindex directory
   * @param sGuid Document GUID
   * @return Number of documents deleted
   * @throws IllegalArgumentException If sTableName is not one of { k_bugs, k_newsmsgs, k_mime_msgs }
   * @throws NoSuchFieldException If luceneindex property is not found at oProps
   * @throws IllegalAccessException
   * @throws IOException
   * @throws NullPointerException If sGuid is <b>null</b>
   */
  public static int delete(String sTableName, String sWorkArea, Properties oProps, String sGuid)
      throws IllegalArgumentException, NoSuchFieldException,
             IllegalAccessException, IOException, NullPointerException {

    if (null==sGuid)
      throw new NullPointerException ("Document GUID may not be null");

    if (!allowedTable(sTableName))
      throw new IllegalArgumentException("Table name must be k_bugs or k_newsmsgs or k_mime_msgs");

    String sDirectory = oProps.getProperty("luceneindex");

    if (null==sDirectory)
      throw new NoSuchFieldException ("Cannot find luceneindex property");

    sDirectory = Gadgets.chomp(sDirectory, File.separator) + sTableName.toLowerCase() + File.separator + sWorkArea;
    File oDir = new File(sDirectory);
    if (!oDir.exists()) {
      FileSystem oFS = new FileSystem();
      try { oFS.mkdirs(sDirectory); } catch (Exception e) { throw new IOException(e.getClass().getName()+" "+e.getMessage()); }
    } // fi

    NIOFSDirectory oFsDir = new NIOFSDirectory(new File(sDirectory));
    IndexReader oReader = IndexReader.open(oFsDir);

    int iDeleted = oReader.deleteDocuments(new Term("guid", sGuid));

    oReader.close();
    oFsDir.close();

    return iDeleted;
  } // delete


  private static void printUsage() {
    System.out.println("");
    System.out.println("Usage:");
    System.out.println("Indexer cnf_path rebuild {k_bugs|k_newsmsgs|k_mime_msgs|k_contacts}");
    System.out.println("cnf_path  : Full path to hipergate.cnf file");
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Static method for calling indexer from the command line</p>
   * @param argv String[] Must have two arguments, the first one is the full path
   * to hipergate.cnf or other properties file containing database connection parameters.<br>
   * The second argument must be "rebuild".<br>
   * The third argument is one of {k_bugs|k_newsmsgs|k_mime_msgs} indicating which table index is to be rebuilt.<br>
   * Command line example: java -cp ... com.knowgate.lucene.Indexer /etc/hipergate.cnf rebuild k_mime_msgs
   * @throws SQLException
   * @throws IOException
   * @throws ClassNotFoundException
   * @throws IllegalArgumentException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   */
  public static void main(String[] argv)
    throws SQLException, IOException, ClassNotFoundException,
    IllegalArgumentException, NoSuchFieldException,
    IllegalAccessException, InstantiationException {

    if (argv.length!=3)
      printUsage();
    else if (!argv[1].equals("rebuild")) {
      printUsage();
    } else if (!allowedTable(argv[2])) {
      printUsage();
    }
    else {
      Properties oProps = new Properties();
      FileInputStream oCNF = new FileInputStream(argv[0]);
      oProps.load(oCNF);
      oCNF.close();
      rebuild (oProps, argv[2]);
    }
  } // main
}
