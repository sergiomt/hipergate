/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.
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
import java.util.Arrays;
import java.util.Comparator;

import java.io.File;
import java.io.IOException;

import org.apache.lucene.index.Term;
import org.apache.lucene.store.Directory;
import org.apache.lucene.search.TermQuery;
import org.apache.lucene.search.TermRangeQuery;
import org.apache.lucene.search.BooleanQuery;
import org.apache.lucene.search.BooleanClause;
import org.apache.lucene.search.IndexSearcher;
import org.apache.lucene.search.TopDocs;
import org.apache.lucene.search.ScoreDoc;
import org.apache.lucene.document.DateTools;
import org.apache.lucene.document.Document;
import org.apache.lucene.queryParser.ParseException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * Search into a Lucene full text index for news messages
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class NewsMessageSearcher {

  public NewsMessageSearcher() {
  }

  /**
   * Find out if a given NewsMessage is already indexed
   * @param sLuceneIndexPath String Base path for Lucene indexes excluding WorkArea and table name
   * @param sWorkArea String GUID of WorkArea to be searched (optional, may be null)
   * @param sNewsGroupCategoryName String GUID or Category Name of NewsGroup to which message belongs (optional, may be null)
   * @param sAuthor String
   * @param sTitle String
   * @param sText String
   * @param iLimit int
   * @param oSortBy Comparator
   * @return NewsMessageRecord[] An Array of NewsMessageRecord objects or <b>null</b> if no messages where found matching the given criteria
   * @throws ParseException
   * @throws IOException
   * @throws NullPointerException
   */  
  public static boolean isIndexed(String sLuceneIndexPath, String sWorkArea, String sNewsGroupCategoryName, String sMsgId)
    throws ParseException, IOException, NullPointerException {

	boolean bIsIndexed = false;
	
	if (null==sLuceneIndexPath)
	  throw new NullPointerException("NewsMessageSearcher.search() luceneindex parameter cannot be null");

    if (DebugFile.trace) {
	  DebugFile.writeln("Begin NewsMessageSearcher.isIndexed("+sLuceneIndexPath+","+
		                sWorkArea+","+sNewsGroupCategoryName+","+sMsgId+")");
      DebugFile.incIdent();
	}
			
	BooleanQuery oQrx = new BooleanQuery();
	oQrx.add(new TermQuery(new Term("guid",sMsgId)),BooleanClause.Occur.MUST);
	
    if (null!=sWorkArea)
	  oQrx.add(new TermQuery(new Term("workarea",sWorkArea)),BooleanClause.Occur.MUST);

    if (null!=sNewsGroupCategoryName)
	  oQrx.add(new TermQuery(new Term("container",sNewsGroupCategoryName)),BooleanClause.Occur.MUST);
    
	String sSegments = Gadgets.chomp(sLuceneIndexPath,File.separator)+"k_newsmsgs"+File.separator+sWorkArea;	
    if (DebugFile.trace) DebugFile.writeln("new IndexSearcher("+sSegments+")");
	Directory oDir = Indexer.openDirectory(sSegments);
	IndexSearcher oSearch = new IndexSearcher(oDir);

    if (DebugFile.trace) DebugFile.writeln("IndexSearcher.search("+oQrx.toString()+")");
	  TopDocs oTopSet = oSearch.search(oQrx, null, 1);
	  if (oTopSet.scoreDocs!=null) {
		ScoreDoc[] oTopDoc = oTopSet.scoreDocs;
		bIsIndexed = (oTopDoc.length>0);
	}
    oSearch.close();
	oDir.close();

	if (DebugFile.trace) {
      DebugFile.decIdent();
	  DebugFile.writeln("End NewsMessageSearcher.isIndexed() : "+String.valueOf(bIsIndexed));
    }
	return bIsIndexed;
  } // isIndexed
  
  /**
   * Compose a Lucene query based on given parameters
   * @param sLuceneIndexPath String Base path for Lucene indexes excluding WorkArea and table name
   * @param sWorkArea String GUID of WorkArea to be searched, cannot be null
   * @param sGroup sNewsGroupCategoryName String GUID or Category Name of NewsGroup to which message belongs (optional, may be null)
   * @param sAuthor String
   * @param sTitle String
   * @param sText String
   * @param iLimit int
   * @param oSortBy Comparator
   * @return NewsMessageRecord[] An Array of NewsMessageRecord objects or <b>null</b> if no messages where found matching the given criteria
   * @throws ParseException
   * @throws IOException
   * @throws NullPointerException
   */
  public static NewsMessageRecord[] search (String sLuceneIndexPath,
                                            String sWorkArea, String sNewsGroupCategoryName,
                                            String sAuthor, String sTitle,
                                            Date dtFromDate, Date dtToDate,
                                            String sText, int iLimit,
                                            Comparator oSortBy)
    throws ParseException, IOException, NullPointerException {

  if (null==sLuceneIndexPath)
    throw new NullPointerException("NewsMessageSearcher.search() luceneindex parameter cannot be null");

    if (null==sWorkArea)
      throw new NullPointerException("NewsMessageSearcher.search() workarea parameter cannot be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsMessageSearcher.search("+sLuceneIndexPath+","+
                        sWorkArea+","+sNewsGroupCategoryName+","+sAuthor+","+sTitle+","+
                        dtFromDate+","+dtToDate+","+sText+","+String.valueOf(iLimit)+")");
      DebugFile.incIdent();
    }

    NewsMessageRecord[] aRetArr;
	
	BooleanQuery oQrx = new BooleanQuery();

	oQrx.add(new TermQuery(new Term("workarea",sWorkArea)),BooleanClause.Occur.MUST);

    if (null!=sNewsGroupCategoryName)
	  oQrx.add(new TermQuery(new Term("container",sNewsGroupCategoryName)),BooleanClause.Occur.MUST);    

    if (dtFromDate!=null && dtToDate!=null)
	  oQrx.add(new TermRangeQuery("created", DateTools.dateToString(dtFromDate, DateTools.Resolution.DAY),
	  						                 DateTools.dateToString(dtToDate, DateTools.Resolution.DAY), true, true), BooleanClause.Occur.MUST);    
    else if (dtFromDate!=null)
	  oQrx.add(new TermRangeQuery("created",DateTools.dateToString(dtFromDate, DateTools.Resolution.DAY), null, true, false), BooleanClause.Occur.MUST);    

    else if (dtToDate!=null)
	  oQrx.add(new TermRangeQuery("created",null, DateTools.dateToString(dtToDate, DateTools.Resolution.DAY), false, true), BooleanClause.Occur.MUST);    

	BooleanQuery oQry = new BooleanQuery();

	if (null!=sAuthor)
	  oQry.add(new TermQuery(new Term("author",sAuthor)),BooleanClause.Occur.SHOULD);

	if (null!=sTitle)
	  oQry.add(new TermQuery(new Term("title",sTitle)),BooleanClause.Occur.SHOULD);

	if (null!=sText)
	  oQry.add(new TermQuery(new Term("text",escape(Gadgets.ASCIIEncode(sText).toLowerCase()))),BooleanClause.Occur.SHOULD);

	oQrx.add(oQry, BooleanClause.Occur.MUST);

	String sSegments = Gadgets.chomp(sLuceneIndexPath,File.separator)+"k_newsmsgs"+File.separator+sWorkArea;	
    if (DebugFile.trace) DebugFile.writeln("new IndexSearcher("+sSegments+")");
	Directory oDir = Indexer.openDirectory(sSegments);
    IndexSearcher oSearch = new IndexSearcher(oDir);

    Document oDoc;

      if (DebugFile.trace) DebugFile.writeln("IndexSearcher.search("+oQrx.toString()+")");
      TopDocs oTopSet = oSearch.search(oQrx, null, iLimit>0 ? iLimit : 2147483647);
      if (oTopSet.scoreDocs!=null) {
        ScoreDoc[] oTopDoc = oTopSet.scoreDocs;
        final int iDocCount = oTopDoc.length<=iLimit ? oTopDoc.length : iLimit;
        aRetArr = new NewsMessageRecord[iDocCount];
        for (int d=0; d<iDocCount; d++) {
          oDoc = oSearch.doc(oTopDoc[d].doc);
          try {
            aRetArr[d] = new NewsMessageRecord(oTopDoc[d].score, oDoc.get("workarea"),
                         oDoc.get("guid"), oDoc.get("thread"), oDoc.get("container"), oDoc.get("title"),                       
                         oDoc.get("author"), DateTools.stringToDate(oDoc.get("created")), oDoc.get("abstract"));
          } catch (java.text.ParseException neverthrown) {
            throw new ParseException("NewsMessageSearcher.search() Error parsing date "+oDoc.get("created")+" of document "+oDoc.get("guid"));
          }
        } // next
      } else {
        aRetArr = null;
      }

    oSearch.close();
    oDir.close();

    if (oSortBy!=null) {
      Arrays.sort(aRetArr, oSortBy);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==aRetArr)
        DebugFile.writeln("End NewsMessageSearcher.search() : no records found");
      else
        DebugFile.writeln("End NewsMessageSearcher.search() : "+String.valueOf(aRetArr.length));
    }
    return aRetArr;
  } // search

  // ---------------------------------------------------------------------------

  /**
   * Escape special characters from a Lucene query
   * @return The input string with any character of set +-&|!(){}[]^"~*?:\ be preceded by a backslash
   */
  public static String escape(String sInput) {
	return Gadgets.escapeChars(sInput,"+-&|!(){}[]^\"~*?:\\",'\\');
  }

}
