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

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import java.io.File;
import java.io.IOException;

import org.apache.lucene.store.Directory;
import org.apache.lucene.index.IndexReader;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.Term;
import org.apache.lucene.document.Document;
import org.apache.lucene.document.Field;

import com.knowgate.dataobjs.DB;
import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

/**
 * Indexer subclass for hipergate contact
 * @author Alfonso Marin Lopez
 * @version 7.0
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
    oDoc.add (new Field("workarea" , contact.getWorkarea(), Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("guid"     , contact.getGui() , Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("author"   , contact.getAuthor() , Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("value"    , contact.getValue(), Field.Store.YES, Field.Index.ANALYZED));
    oIWrt.addDocument(oDoc);
  } // addDocument



  /**
   * Add contact by his GUID
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
			String sWorkArea, JDCConnection oConn) throws ClassNotFoundException,
			IOException, IllegalArgumentException, NoSuchFieldException,
			IllegalAccessException, InstantiationException,
			NullPointerException, SQLException {
		String sDirectory = oProps.getProperty("luceneindex");

    	if (DebugFile.trace) {
          DebugFile.writeln("Begin ContactIndexer.addOrReplaceContact([Properties]," + sGuid + "," + sWorkArea + ", [JDCConnection])");
          DebugFile.incIdent();
    	}

		if (null == sDirectory) {
			if (DebugFile.trace) DebugFile.decIdent();
			throw new NoSuchFieldException("Cannot find luceneindex property");
		}

		sDirectory = Gadgets.chomp(sDirectory, File.separator) + "k_contacts" + File.separator + sWorkArea;

		if (DebugFile.trace)
			DebugFile.writeln("index directory is " + sDirectory);

		File oDir = new File(sDirectory);
		boolean bNewIndex = !oDir.exists();
		
		if (oDir.exists()) {
		  File[] aFiles = oDir.listFiles();
		  if (aFiles==null) {
		  	bNewIndex = true;
		  } else if (aFiles.length==0) {
		  	bNewIndex = true;
		  }
		}

		if (bNewIndex) {
			Indexer.rebuild(oProps, "k_contacts", sWorkArea);
		}
		
		if (DebugFile.trace) DebugFile.writeln("IndexReader.open("+sDirectory+")");

		Directory oFsDir = Indexer.openDirectory(sDirectory);
		
		IndexReader oIRdr = IndexReader.open(oFsDir);
		oIRdr.deleteDocuments(new Term("guid", sGuid));
		oIRdr.close();
		
		IndexWriter oIWrt = new IndexWriter(oFsDir, instantiateAnalyzer(oProps), IndexWriter.MaxFieldLength.LIMITED);

		addDocument(oIWrt, sGuid, sWorkArea, oConn);

		oIWrt.close();
		oFsDir.close();

    	if (DebugFile.trace) {
          DebugFile.decIdent();
          DebugFile.writeln("End ContactIndexer.addOrReplaceContact()");
    	}

	} // addOrReplaceContact
	

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
