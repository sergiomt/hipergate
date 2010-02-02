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

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import org.apache.lucene.index.IndexReader;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.Term;
import org.apache.lucene.analysis.Analyzer;
import org.apache.lucene.document.Document;
import org.apache.lucene.document.Field;

import com.knowgate.dataobjs.DB;
import com.knowgate.debug.DebugFile;
import com.knowgate.dfs.FileSystem;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

/**
 * Indexer subclass for hipergate contact
 * @author Alfonso Marin Lopez
 * @version 1.0
 */
public class ContactIndexer extends Indexer {

  public ContactIndexer() { }


  /**
   * Add contact to index
   * @param oIWrt
   * @param sGuid
   * @param sWorkArea
   * @param sName
   * @param sSurname
   * @param sKey
   * @param sValue
   * @param sLevel
   * @param sLanguage
   * @throws ClassNotFoundException
   * @throws IOException
   * @throws IllegalArgumentException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws NullPointerException
   */
  public static void addDocument(IndexWriter oIWrt,ContactRecord contact)
    throws ClassNotFoundException, IOException, IllegalArgumentException,
             NoSuchFieldException, IllegalAccessException, InstantiationException,
             NullPointerException {

    Document oDoc = new Document();
    oDoc.add (new Field("workarea" , contact.getWorkarea(), Field.Store.YES, Field.Index.UN_TOKENIZED));
    oDoc.add (new Field("guid"     , contact.getGui() , Field.Store.YES, Field.Index.UN_TOKENIZED));
    oDoc.add (new Field("author"   , contact.getAuthor() , Field.Store.YES, Field.Index.UN_TOKENIZED));
    oDoc.add (new Field("value"    , contact.getValue(), Field.Store.YES, Field.Index.TOKENIZED));
    oIWrt.addDocument(oDoc);
  } // addBug



  /**
   * Se añade un contacto por su identificador unico
   * @param oIWrt
   * @param contact
   * @throws ClassNotFoundException
   * @throws IOException
   * @throws IllegalArgumentException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws NullPointerException
   * @throws SQLException 
   */
  public static void addDocument(IndexWriter oIWrt,String sContact, String sWorkArea,JDCConnection oConn)
  throws ClassNotFoundException, IOException, IllegalArgumentException,
           NoSuchFieldException, IllegalAccessException, InstantiationException,
           NullPointerException, SQLException {
  	
  	String consultas[] = new String[6];
  	consultas[0] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, csc.nm_scourse, csc.lv_scourse FROM k_contacts c, k_contact_short_courses csc WHERE c.gu_workarea='" + sWorkArea + "' AND csc.gu_contact = c.gu_contact AND c.gu_contact='" +sContact+"'";
  	consultas[1] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ccsl.tr_es,ccsl2.tr_es FROM k_contacts c, k_contact_computer_science ccc, k_contact_computer_science_lookup ccsl, k_contact_computer_science_lookup ccsl2 WHERE c.gu_workarea='"+ sWorkArea +"' AND ccc.gu_contact = c.gu_contact AND ccc.nm_skill = ccsl.vl_lookup AND ccc.lv_skill = ccsl2.vl_lookup AND c.gu_contact='" +sContact+"'";
  	consultas[2] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ccsl.tr_en,ccsl2.tr_en FROM k_contacts c, k_contact_computer_science ccc, k_contact_computer_science_lookup ccsl, k_contact_computer_science_lookup ccsl2 WHERE c.gu_workarea='"+ sWorkArea +"' AND ccc.gu_contact = c.gu_contact AND ccc.nm_skill = ccsl.vl_lookup AND ccc.lv_skill = ccsl2.vl_lookup AND c.gu_contact='" +sContact+"'";
  	consultas[3] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ed.nm_degree,'' as level FROM k_contacts c,k_contact_education ce,k_education_degree ed WHERE c.gu_workarea='"+ sWorkArea +"' AND ce.gu_contact = c.gu_contact AND ce.gu_degree= ed.gu_degree AND c.gu_contact='" +sContact+"'";
  	consultas[4] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ll.tr_lang_es,cll.tr_es FROM k_contacts c, k_contact_languages cl, k_lu_languages ll,k_contact_languages_lookup cll WHERE c.gu_workarea='"+ sWorkArea +"' AND c.gu_contact = cl.gu_contact AND cl.id_language = ll.id_language AND cl.lv_language_degree = cll.vl_lookup AND c.gu_contact='" +sContact+"'";
  	consultas[5] = "SELECT c.gu_contact, c.gu_workarea, c.tx_name, c.tx_surname, ll.tr_lang_en,cll.tr_en FROM k_contacts c, k_contact_languages cl, k_lu_languages ll,k_contact_languages_lookup cll WHERE c.gu_workarea='"+ sWorkArea +"' AND c.gu_contact = cl.gu_contact AND cl.id_language = ll.id_language AND cl.lv_language_degree = cll.vl_lookup AND c.gu_contact='" +sContact+"'";
  	
  	Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
  	ResultSet oRSet;
  	ContactRecord contact = null;
  	for(int i=0;i<consultas.length;i++){
          if (DebugFile.trace)
              DebugFile.writeln("Statement.executeQuery(" + consultas[i] + ")");

  		oRSet = oStmt.executeQuery(consultas[i]);

  	    while (oRSet.next()) {
          	String sGuid = oRSet.getString(1);
          	sWorkArea = oRSet.getString(2);
          	String sName = oRSet.getString(3);
          	String sSurname = oRSet.getString(4);
          	String sValue = oRSet.getString(5);
          	String sLevel = oRSet.getString(6);
          	if(sLevel==null) sLevel="";
          	if(contact==null) contact = new ContactRecord(null,sName+" "+ sSurname,sWorkArea,sGuid);
          	contact.addValue(sValue, sLevel);
         	
          }
  	    oRSet.close();
  	}
	ContactIndexer.addDocument(oIWrt,contact);

  }
  
	public static void addOrReplaceContact(Properties oProps, String sGuid,
			String sWorkArea,JDCConnection oConn) throws ClassNotFoundException,
			IOException, IllegalArgumentException, NoSuchFieldException,
			IllegalAccessException, InstantiationException,
			NullPointerException, SQLException {

		String sDirectory = oProps.getProperty("luceneindex");

		if (null == sDirectory) {
			if (DebugFile.trace)
				DebugFile.decIdent();
			throw new NoSuchFieldException("Cannot find luceneindex property");
		}

		sDirectory = Gadgets.chomp(sDirectory, File.separator) + "k_contacts"
				+ File.separator + sWorkArea;

		if (DebugFile.trace)
			DebugFile.writeln("index directory is " + sDirectory);

		File oDir = new File(sDirectory);
		boolean bNewIndex = !oDir.exists();
		if (bNewIndex) {
			FileSystem oFs = new FileSystem();
			try {
				oFs.mkdirs("file://" + sDirectory);
			} catch (Exception xcpt) {
				if (DebugFile.trace)
					DebugFile
							.writeln(xcpt.getClass() + " " + xcpt.getMessage());
				throw new FileNotFoundException("Could not create directory "
						+ sDirectory + " " + xcpt.getMessage());
			}
		}

		if (DebugFile.trace)
			DebugFile.writeln("Class.forName("
					+ oProps.getProperty("analyzer", DEFAULT_ANALYZER) + ")");

		Class oAnalyzer = Class.forName(oProps.getProperty("analyzer",
				DEFAULT_ANALYZER));

		if (DebugFile.trace)
			DebugFile.writeln("new IndexWriter(...)");

		IndexReader oIRdr = IndexReader.open(sDirectory);
		oIRdr.deleteDocuments(new Term("guid", sGuid));
		oIRdr.close();

		IndexWriter oIWrt = new IndexWriter(sDirectory, (Analyzer) oAnalyzer
				.newInstance(), bNewIndex);

		addDocument(oIWrt, sGuid, sWorkArea, oConn);

		oIWrt.close();

	} // addOrReplaceNewsMessage
	
 /* public static void addContact(IndexWriter oIWrt, JDCConnection oCon,
                            String sWorkArea, Bug oBug)
    throws SQLException,IOException,ClassNotFoundException,NoSuchFieldException,
           IllegalAccessException, InstantiationException, NullPointerException {
    Short oSeverity;
    Short oPriority;

    if (null==oBug) throw new NullPointerException ("BugIndexer.addBug() Bug may not be null");
    if (null==oCon) throw new NullPointerException ("BugIndexer.addBug() JDBC Connection may not be null");
    if (oCon.isClosed()) throw new SQLException("BugIndexer.addBug() JDBC connection is closed");

    if (oBug.isNull(DB.od_priority))
      oPriority = null;
    else
      oPriority = new Short(oBug.getShort(DB.od_priority));

    if (oBug.isNull(DB.od_severity))
      oSeverity = null;
    else
      oSeverity = new Short(oBug.getShort(DB.od_severity));

    addContact(oIWrt, oBug.getString(DB.gu_bug), oBug.getInt(DB.pg_bug),
           sWorkArea, oBug.getString(DB.gu_project),
           oBug.getStringNull(DB.tl_bug,""), oBug.getString(DB.gu_writer),
           oBug.getStringNull(DB.nm_reporter,""), oBug.getCreationDate(oCon),
           oBug.getStringNull(DB.tp_bug,null), oPriority, oSeverity,
           oBug.getStringNull(DB.tx_status, null), oBug.getStringNull(DB.tx_comments,null),
           oBug.getStringNull(DB.tx_bug_brief,null));
  }*/

  /**
   * Add bug to index
   * @param oProps Properties
   * @param oCon JDCConnection
   * @param sWorkArea String
   * @param oBug Bug
   * @throws SQLException
   * @throws IOException
   * @throws ClassNotFoundException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws NullPointerException
   * @throws NoSuchFieldException
   */
  /*public static void addContact(Properties oProps, JDCConnection oCon,
                            String sWorkArea, Bug oBug)
    throws SQLException,IOException,ClassNotFoundException,NoSuchFieldException,
           IllegalAccessException, InstantiationException, NullPointerException,
           NoSuchFieldException {


    String sDirectory = oProps.getProperty("luceneindex");

    if (null==sDirectory)
     throw new NoSuchFieldException ("Cannot find luceneindex property");

     sDirectory = Gadgets.chomp(sDirectory, File.separator) + DB.k_bugs + File.separator + sWorkArea;
     File oDir = new File(sDirectory);
     if (!oDir.exists()) {
       FileSystem oFS = new FileSystem();
       try { oFS.mkdirs(sDirectory); } catch (Exception e) { throw new IOException(e.getClass().getName()+" "+e.getMessage()); }
    }  // fi

    Class oAnalyzer = Class.forName(oProps.getProperty("analyzer" , DEFAULT_ANALYZER));

    IndexWriter oIWrt = new IndexWriter(sDirectory, (Analyzer) oAnalyzer.newInstance(), true);
    addContact(oIWrt, oCon, sWorkArea, oBug);
    oIWrt.close();
  } // addBug*/

  /**
   * Delete a bug with a given GUID
   * @param oProps Properties Collection containing luceneindex directory
   * @param sGuid Bug GUID
   * @return Number of documents deleted
   * @throws IllegalArgumentException If sTableName is not one of { k_bugs, k_newsmsgs, k_mime_msgs }
   * @throws NoSuchFieldException If luceneindex property is not found at oProps
   * @throws IllegalAccessException
   * @throws IOException
   * @throws NullPointerException If sGuid is <b>null</b>
   */
  public static int deleteContact(String sWorkArea, Properties oProps, String sGuid)
    throws IllegalArgumentException, NoSuchFieldException,
           IllegalAccessException, IOException, NullPointerException {
      return Indexer.delete(DB.k_contacts, sWorkArea, oProps, sGuid);
  } // delete
}
