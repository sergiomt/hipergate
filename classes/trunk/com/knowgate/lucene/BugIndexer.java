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

import java.util.Date;
import java.util.Properties;

import java.io.IOException;
import java.sql.SQLException;

import org.apache.lucene.store.Directory;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.document.DateTools;
import org.apache.lucene.document.Document;
import org.apache.lucene.document.Field;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.projtrack.Bug;
import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.FileSystem;
import java.io.File;

/**
 * Indexer subclass for hipergate bugs
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class BugIndexer extends Indexer {

  public BugIndexer() { }


  /**
   * Add bug to index
   * @param oIWrt IndexWriter
   * @param sGuid String Bug GUID
   * @param iNumber int Bug Number
   * @param sWorkArea String GUID of WorkArea to which bug belongs
   * @param sProject String GUID of project to which bug belongs
   * @param sTitle String Title
   * @param sReportedBy String Author
   * @param dtCreated Date Created
   * @param sComments String Comments
   * @param sText String Bug Description
   * @throws ClassNotFoundException
   * @throws IOException
   * @throws IllegalArgumentException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws NullPointerException
   */
  public static void addBug(IndexWriter oIWrt,
                            String sGuid, int iNumber, String sWorkArea,
                            String sProject, String sTitle, String sWriter,
                            String sReportedBy, Date dtCreated,
                            String sType, Short oPriority, Short oSeverity,
                            String sStatus, String sComments, String sText)
    throws ClassNotFoundException, IOException, IllegalArgumentException,
             NoSuchFieldException, IllegalAccessException, InstantiationException,
             NullPointerException {

    Document oDoc = new Document();
    oDoc.add (new Field("workarea" , sWorkArea, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("container", sProject , Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("guid"     , sGuid    , Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("number"   , String.valueOf(iNumber), Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("title"    , sTitle, Field.Store.YES, Field.Index.ANALYZED));
    oDoc.add (new Field("created"  , DateTools.dateToString(dtCreated, DateTools.Resolution.SECOND), Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("writer"   , sWriter, Field.Store.YES, Field.Index.NOT_ANALYZED));
    if (null!=sStatus)     oDoc.add (new Field("status"   , sStatus, Field.Store.YES, Field.Index.NOT_ANALYZED));
    if (null!=sType)       oDoc.add (new Field("type"     , sType  , Field.Store.YES, Field.Index.NOT_ANALYZED));
    if (null!=oPriority)   oDoc.add (new Field("priority" , oPriority.toString(), Field.Store.YES, Field.Index.NOT_ANALYZED));
    if (null!=oSeverity)   oDoc.add (new Field("severity" , oSeverity.toString(), Field.Store.YES, Field.Index.NOT_ANALYZED));
    if (null!=sReportedBy) oDoc.add (new Field("author"   , sReportedBy, Field.Store.YES, Field.Index.ANALYZED));
    if (null==sComments)
      oDoc.add (new Field("comments", "", Field.Store.NO, Field.Index.ANALYZED));
    else
      oDoc.add (new Field("comments", sComments, Field.Store.NO, Field.Index.ANALYZED));
    if (null==sText) {
      oDoc.add (new Field("text", "", Field.Store.NO, Field.Index.ANALYZED));
      oDoc.add (new Field("abstract", "", Field.Store.YES, Field.Index.ANALYZED));
    } else {
      oDoc.add (new Field("text", sText, Field.Store.NO, Field.Index.ANALYZED));
      if (sText.length()>80)
        oDoc.add (new Field("abstract", sText.substring(0,80).replace('\n',' ').replace('\r',' '), Field.Store.YES, Field.Index.ANALYZED));
      else
        oDoc.add (new Field("abstract", sText.replace('\n',' ').replace('\r',' '), Field.Store.YES, Field.Index.ANALYZED));
    }
    oIWrt.addDocument(oDoc);
  } // addBug

  /**
   * Add bug to index
   * @param oIWrt IndexWriter
   * @param sGuid String Bug GUID
   * @param iNumber int Bug Number
   * @param sWorkArea String GUID of WorkArea to which bug belongs
   * @param sProject String GUID of project to which bug belongs
   * @param sTitle String Title
   * @param sReportedBy String Author
   * @param dtCreated Date Created
   * @param sComments String Comments
   * @param sText String Bug Description
   * @throws ClassNotFoundException
   * @throws IOException
   * @throws IllegalArgumentException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws NullPointerException
   */
  public static void addBug(IndexWriter oIWrt,
                            String sGuid, int iNumber, String sWorkArea,
                            String sProject, String sTitle,
                            String sReportedBy, Date dtCreated,
                            String sComments, String sText)
    throws ClassNotFoundException, IOException, IllegalArgumentException,
             NoSuchFieldException, IllegalAccessException, InstantiationException,
             NullPointerException {
    addBug(oIWrt, sGuid, iNumber, sWorkArea, sProject, sTitle, null, sReportedBy,
           dtCreated, null, null, null, null, sComments, sText);
  } // addBug

  /**
   * Add bug to index
   * @param oIWrt IndexWriter
   * @param oCon JDCConnection
   * @param sWorkArea String GUID of WorkArea where bug must be added
   * @param oBug Bug
   * @throws SQLException
   * @throws IOException
   * @throws ClassNotFoundException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @throws NullPointerException
   */
  public static void addBug(IndexWriter oIWrt, JDCConnection oCon,
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

    addBug(oIWrt, oBug.getString(DB.gu_bug), oBug.getInt(DB.pg_bug),
           sWorkArea, oBug.getString(DB.gu_project),
           oBug.getStringNull(DB.tl_bug,""), oBug.getString(DB.gu_writer),
           oBug.getStringNull(DB.nm_reporter,""), oBug.getCreationDate(oCon),
           oBug.getStringNull(DB.tp_bug,null), oPriority, oSeverity,
           oBug.getStringNull(DB.tx_status, null), oBug.getStringNull(DB.tx_comments,null),
           oBug.getStringNull(DB.tx_bug_brief,null));
  }

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
  public static void addBug(Properties oProps, JDCConnection oCon,
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

    Directory oFsDir = Indexer.openDirectory(sDirectory);
    IndexWriter oIWrt = new IndexWriter(oFsDir, Indexer.instantiateAnalyzer(oProps), IndexWriter.MaxFieldLength.LIMITED);
    addBug(oIWrt, oCon, sWorkArea, oBug);
    oIWrt.close();
    oFsDir.close();
  } // addBug

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
  public static int deleteBug(String sWorkArea, Properties oProps, String sGuid)
    throws IllegalArgumentException, NoSuchFieldException,
           IllegalAccessException, IOException, NullPointerException {
      return Indexer.delete(DB.k_bugs, sWorkArea, oProps, sGuid);
  } // delete
}
