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

import java.util.Arrays;
import java.util.Date;
import java.util.Comparator;

import java.io.File;
import java.io.IOException;

import org.apache.lucene.index.Term;
import org.apache.lucene.search.TermQuery;
import org.apache.lucene.search.TermRangeQuery;
import org.apache.lucene.search.BooleanQuery;
import org.apache.lucene.search.BooleanClause;
import org.apache.lucene.search.IndexSearcher;
import org.apache.lucene.search.TopDocs;
import org.apache.lucene.search.ScoreDoc;
import org.apache.lucene.store.Directory;
import org.apache.lucene.document.DateTools;
import org.apache.lucene.document.Document;
import org.apache.lucene.queryParser.ParseException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * Search into a Lucene full text index for bugs
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class BugSearcher {

  public BugSearcher() {
  }

  /**
   * Compose a Lucene query based on given parameters
   * @param sLuceneIndexPath String Base path for Lucene indexes excluding WorkArea and table name
   * @param sWorkArea String GUID of WorkArea to be searched, cannot be null
   * @param sProject String GUID f project to which bug belongs
   * @param sReportedBy String
   * @param sWrittenBy String
   * @param sTitle String
   * @param sFromDate String
   * @param sToDate String
   * @param sType String
   * @param sPriority String
   * @param sSeverity String
   * @param sStatus String
   * @param sText String
   * @param sComments String
   * @param iLimit int
   * @param oSortBy Comparator
   * @return BugRecord[]
   * @throws ParseException
   * @throws IOException
   * @throws NullPointerException
   */
  public static BugRecord[] search (String sLuceneIndexPath,
                                     String sWorkArea, String sProjectGUID,
                                     String sReportedBy, String sWrittenBy,
                                     String sTitle,
                                     Date dtFromDate, Date dtToDate,
                                     String sType, String sPriority, String sSeverity,
                                     String sStatus, String sText,
                                     String sComments,
                                     int iLimit, Comparator oSortBy)
    throws ParseException, IOException, NullPointerException {

  if (null==sLuceneIndexPath)
    throw new NullPointerException("BugSearcher.search() luceindex parameter cannot be null");

    if (null==sWorkArea)
      throw new NullPointerException("BugSearcher.search() workarea parameter cannot be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin BugSearcher.search("+sLuceneIndexPath+","+
                        sWorkArea+","+sProjectGUID+","+sReportedBy+","+sWrittenBy+","+
                        sTitle+","+dtFromDate+","+dtToDate+","+sType+","+sPriority+","+
                        sSeverity+","+","+sStatus+","+sText+String.valueOf(iLimit)+")");
      DebugFile.incIdent();
    }

    BugRecord[] aRetArr;

	BooleanQuery oQry = new BooleanQuery();

	oQry.add(new TermQuery(new Term("workarea",sWorkArea)),BooleanClause.Occur.MUST);

    if (null!=sProjectGUID)
	  if (sProjectGUID.length()>0)
	  	oQry.add(new TermQuery(new Term("container",sProjectGUID)),BooleanClause.Occur.MUST);

    if (null!=sWrittenBy)
      if (sWrittenBy.length()>0)
	  	oQry.add(new TermQuery(new Term("writer",sWrittenBy)),BooleanClause.Occur.MUST);

    if (null!=sReportedBy)
      if (sReportedBy.length()>0)
	  	oQry.add(new TermQuery(new Term("author",sReportedBy)),BooleanClause.Occur.MUST);

    if (null!=sTitle)
      if (sTitle.length()>0)
	  	oQry.add(new TermQuery(new Term("title",sTitle)),BooleanClause.Occur.MUST);

    if (null!=sType)
      if (sType.length()>0)
	  	oQry.add(new TermQuery(new Term("type",sType)),BooleanClause.Occur.MUST);

    if (null!=sStatus)
      if (sStatus.length()>0)
	  	oQry.add(new TermQuery(new Term("status",sStatus)),BooleanClause.Occur.MUST);

    if (null!=sPriority)
      if (sPriority.length()>0)
	  	oQry.add(new TermQuery(new Term("priority",sPriority)),BooleanClause.Occur.MUST);

    if (null!=sSeverity)
      if (sSeverity.length()>0)
	  	oQry.add(new TermQuery(new Term("severity",sSeverity)),BooleanClause.Occur.MUST);

    if (dtFromDate!=null && dtToDate!=null)
	  oQry.add(new TermRangeQuery("created",DateTools.dateToString(dtFromDate, DateTools.Resolution.DAY),
	  						                DateTools.dateToString(dtToDate, DateTools.Resolution.DAY), true, true), BooleanClause.Occur.MUST);    
    else if (dtFromDate!=null)
	  oQry.add(new TermRangeQuery("created",DateTools.dateToString(dtFromDate, DateTools.Resolution.DAY), null, true, false), BooleanClause.Occur.MUST);    
    else if (dtToDate!=null)
	  oQry.add(new TermRangeQuery("created",null,DateTools.dateToString(dtToDate, DateTools.Resolution.DAY), false, true), BooleanClause.Occur.MUST);
    if (null!=sText)
      if (sText.length()>0)
	  	oQry.add(new TermQuery(new Term("text",sText)),BooleanClause.Occur.SHOULD);

    if (null!=sComments)
      if (sComments.length()>0)
	  	oQry.add(new TermQuery(new Term("comments",sComments)),BooleanClause.Occur.SHOULD);

	String sSegments = Gadgets.chomp(sLuceneIndexPath,File.separator)+"k_bugs"+File.separator+sWorkArea;	
    if (DebugFile.trace) DebugFile.writeln("new IndexSearcher("+sSegments+")");
	Directory oFsDir = Indexer.openDirectory(sSegments);
    IndexSearcher oSearch = new IndexSearcher(oFsDir);
    
    Document oDoc;

      TopDocs oTopSet = oSearch.search(oQry, null, iLimit>0 ? iLimit : 2147483647);
      if (oTopSet.scoreDocs!=null) {
        ScoreDoc[] oTopDoc = oTopSet.scoreDocs;
        int iDocCount = oTopDoc.length;
        aRetArr = new BugRecord[iDocCount];
        for (int d=0; d<iDocCount; d++) {
          oDoc = oSearch.doc(oTopDoc[d].doc);
          aRetArr[d] = new BugRecord(oTopDoc[d].score,
          			   Integer.parseInt(oDoc.get("number")),
                       oDoc.get("guid"), oDoc.get("container"), oDoc.get("title"),
                       oDoc.get("author"), oDoc.get("created"), oDoc.get("type"),
                       oDoc.get("status"), oDoc.get("priority"),
                       oDoc.get("severity"), oDoc.get("abstract"));
        } // next
      } else {
        aRetArr = null;
      }

    oSearch.close();
    oFsDir.close();

    if (oSortBy!=null) {
      Arrays.sort(aRetArr, oSortBy);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==aRetArr)
        DebugFile.writeln("End BugSearcher.search() : no records found");
      else
        DebugFile.writeln("End BugSearcher.search() : "+String.valueOf(aRetArr.length));
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
