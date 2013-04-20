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

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.util.Date;
import java.util.Properties;

import org.apache.lucene.index.IndexReader;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.Term;
import org.apache.lucene.store.Directory;
import org.apache.lucene.document.DateTools;
import org.apache.lucene.document.Field;
import org.apache.lucene.document.Document;


import com.knowgate.dfs.FileSystem;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * Indexer subclass for hipergate forum messages
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class NewsMessageIndexer extends Indexer {

  public NewsMessageIndexer() {
  }

  public static void addNewsMessage(IndexWriter oIWrt,
                                    String sGuid, String sThread,
                                    String sWorkArea, String sContainer,
                                    String sTitle, String sAuthor,
                                    Date dtCreated, String sText)
    throws ClassNotFoundException, IOException, IllegalArgumentException,
             NoSuchFieldException, IllegalAccessException, InstantiationException,
             NullPointerException {

	if (null==sGuid) throw new NullPointerException("NewsMessageIndexer.addNewsMessage() Message GUID may not be null");
	if (null==sWorkArea) throw new NullPointerException("NewsMessageIndexer.addNewsMessage() Message WorkArea may not be null");
	if (null==sContainer) throw new NullPointerException("NewsMessageIndexer.addNewsMessage() Message Container may not be null");
	if (null==dtCreated) throw new NullPointerException("NewsMessageIndexer.addNewsMessage() Message Creation Date may not be null");
	
    Document oDoc = new Document();
    oDoc.add (new Field ("workarea" , sWorkArea, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("container", sContainer, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("guid"     , sGuid, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("thread"   , sThread, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("created"  , DateTools.dateToString(dtCreated, DateTools.Resolution.SECOND), Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field ("title"    , null==sTitle ? "" : sTitle, Field.Store.YES, Field.Index.ANALYZED));    
    oDoc.add (new Field ("author"   , null==sAuthor ? "" : sAuthor, Field.Store.YES, Field.Index.ANALYZED));
    if (null==sText) {
      oDoc.add (new Field ("text"   , "", Field.Store.NO, Field.Index.ANALYZED));
      oDoc.add (new Field("abstract", "", Field.Store.YES, Field.Index.ANALYZED));
    } else {
      oDoc.add (new Field ("text"   , Gadgets.ASCIIEncode(sText).toLowerCase(), Field.Store.NO, Field.Index.ANALYZED));
      if (sText.length()>80)
        oDoc.add (new Field("abstract", sText.substring(0,80), Field.Store.YES, Field.Index.ANALYZED));
      else
        oDoc.add (new Field("abstract", sText, Field.Store.YES, Field.Index.ANALYZED));
    }
    oIWrt.addDocument(oDoc);
  } // addNewsMessage

  public static void addNewsMessage(Properties oProps, String sGuid, String sThread, String sWorkArea, String sContainer, String sTitle, String sAuthor, Date dtCreated, String sText)
    throws ClassNotFoundException, IOException, IllegalArgumentException, NoSuchFieldException, IllegalAccessException, InstantiationException, NullPointerException {

    String sDirectory = oProps.getProperty("luceneindex");

	if (null==sDirectory) {
	  if (DebugFile.trace) DebugFile.decIdent();
	    throw new NoSuchFieldException ("Cannot find luceneindex property");
    }

	sDirectory = Gadgets.chomp(sDirectory, File.separator) + "k_newsmsgs" + File.separator + sWorkArea;

	if (DebugFile.trace) DebugFile.writeln("index directory is " + sDirectory);

    Directory oFsDir = Indexer.openDirectory(sDirectory);
		
    IndexWriter oIWrt = new IndexWriter(oFsDir, Indexer.instantiateAnalyzer(oProps), IndexWriter.MaxFieldLength.LIMITED);
			
    addNewsMessage(oIWrt, sGuid, sThread, sWorkArea, sContainer, sTitle, sAuthor, dtCreated, sText);
			
	oIWrt.close();
	oFsDir.close();			
  } // addNewsMessage

  public static void addOrReplaceNewsMessage(Properties oProps, String sGuid, String sThread, String sWorkArea, String sContainer, String sTitle, String sAuthor, Date dtCreated, String sText)
    throws ClassNotFoundException, IOException, IllegalArgumentException, 
             NoSuchFieldException, IllegalAccessException, InstantiationException, NullPointerException {

    String sDirectory = oProps.getProperty("luceneindex");

    if (null==sDirectory) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NoSuchFieldException ("Cannot find luceneindex property");
    }

    sDirectory = Gadgets.chomp(sDirectory, File.separator) + "k_newsmsgs" + File.separator + sWorkArea;

    if (DebugFile.trace) DebugFile.writeln("index directory is " + sDirectory);

    File oDir = new File(sDirectory);
	boolean bNewIndex = !oDir.exists();
    if (bNewIndex) {
	  FileSystem oFs = new FileSystem();
	  try {
	    oFs.mkdirs("file://"+sDirectory);
	  } catch (Exception xcpt) {
        if (DebugFile.trace) DebugFile.writeln(xcpt.getClass()+" "+xcpt.getMessage());
        throw new FileNotFoundException ("Could not create directory "+sDirectory+" "+xcpt.getMessage());
	  }
    } else {
	  File[] aFiles = oDir.listFiles();
	  if (aFiles==null) {
	    bNewIndex = true;
	  } else if (aFiles.length==0) {
		bNewIndex = true;
	  }	
    }

    Directory oFsDir = Indexer.openDirectory(sDirectory);
    
	if (!bNewIndex) {
	  if (DebugFile.trace) DebugFile.writeln("new IndexReader(...)");
      IndexReader oIRdr = IndexReader.open(oFsDir,false);
	  if (DebugFile.trace) DebugFile.writeln("IndexReader.deleteDocuments("+sGuid+")");
      oIRdr.deleteDocuments(new Term("guid",sGuid));
      oIRdr.close();
	}

    if (DebugFile.trace)
        DebugFile.writeln("new IndexWriter(...)");
	
    IndexWriter oIWrt = new IndexWriter(oFsDir, Indexer.instantiateAnalyzer(oProps), IndexWriter.MaxFieldLength.LIMITED);
	
	addNewsMessage(oIWrt, sGuid, sThread, sWorkArea, sContainer, sTitle, sAuthor, dtCreated, sText);
	
	oIWrt.close();
	oFsDir.close();
	
  } // addOrReplaceNewsMessage
}
