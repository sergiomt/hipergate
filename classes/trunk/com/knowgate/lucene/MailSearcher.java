/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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
import org.apache.lucene.search.TermQuery;
import org.apache.lucene.search.TermRangeQuery;
import org.apache.lucene.search.BooleanQuery;
import org.apache.lucene.search.BooleanClause;
import org.apache.lucene.search.BooleanClause.Occur;
import org.apache.lucene.search.IndexSearcher;
import org.apache.lucene.search.TopDocs;
import org.apache.lucene.search.ScoreDoc;
import org.apache.lucene.store.Directory;
import org.apache.lucene.document.DateTools;
import org.apache.lucene.document.DateTools.Resolution;
import org.apache.lucene.document.Document;
import org.apache.lucene.queryParser.ParseException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * Search into a Lucene full text index for e-mails
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class MailSearcher {

  public MailSearcher() {
  }

  /**
   * Compose a Lucene query based on given parameters
   * @param sLuceneIndexPath String Base path for Lucene indexes excluding WorkArea and table name
   * @param sWorkArea String GUID of WorkArea to be searched, cannot be null
   * @param sFolderName String
   * @param sSender String
   * @param sRecipient String
   * @param sSubject String
   * @param sFromDate String
   * @param sToDate String
   * @param sText String
   * @param iLimit int
   * @param oSortBy Comparator
   * @return MailRecord[]
   * @throws ParseException
   * @throws IOException
   * @throws NullPointerException
   */
  public static MailRecord[] search (String sLuceneIndexPath,
                                     String sWorkArea, String[] aFolderName,
                                     String sSender, String sRecipient,
                                     String sSubject,  Date dtFromDate,
                                     Date dtToDate, String sText, int iLimit,
                                     Comparator oSortBy)
    throws ParseException, IOException, NullPointerException {

  if (null==sLuceneIndexPath)
    throw new NullPointerException("MailSearcher.search() luceindex parameter cannot be null");

    if (null==sWorkArea)
      throw new NullPointerException("MailSearcher.search() workarea parameter cannot be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MailSearcher.search("+sLuceneIndexPath+","+
                        sWorkArea+", ...,"+sSender+","+sRecipient+","+
                        sSubject+","+dtFromDate+","+dtToDate+","+sText+","+
                        String.valueOf(iLimit)+")");
      DebugFile.incIdent();
    }

    MailRecord[] aRetArr;

	BooleanQuery oFld = new BooleanQuery();
	for (int f=0; f<aFolderName.length; f++)
	  oFld.add(new TermQuery(new Term("container",aFolderName[f])),BooleanClause.Occur.SHOULD);

	BooleanQuery oQry = new BooleanQuery();

	oQry.add(new TermQuery(new Term("workarea",sWorkArea)),BooleanClause.Occur.MUST);
    oQry.add(oFld, BooleanClause.Occur.MUST);

    if (null!=sSender)
      oQry.add(new TermQuery(new Term("author",Gadgets.ASCIIEncode(sSender))),BooleanClause.Occur.MUST);
     
    if (null!=sRecipient)
      oQry.add(new TermQuery(new Term("recipients",sRecipient)),BooleanClause.Occur.MUST);
    	
    if (null!=sSubject)
      oQry.add(new TermQuery(new Term("title",Gadgets.ASCIIEncode(sSubject))),BooleanClause.Occur.MUST);
   
    if (dtFromDate!=null && dtToDate!=null)
	  oQry.add(new TermRangeQuery("created",DateTools.dateToString(dtFromDate, DateTools.Resolution.DAY),
	  						      DateTools.dateToString(dtToDate, DateTools.Resolution.DAY), true, true), BooleanClause.Occur.MUST);    
    else if (dtFromDate!=null)
	  oQry.add(new TermRangeQuery("created",DateTools.dateToString(dtFromDate, DateTools.Resolution.DAY), null, true, false), BooleanClause.Occur.MUST);    

    else if (dtToDate!=null)
	  oQry.add(new TermRangeQuery("created",null,DateTools.dateToString(dtToDate, DateTools.Resolution.DAY), false, true), BooleanClause.Occur.MUST);

    if (null!=sText)
      oQry.add(new TermQuery(new Term("text",sText)),BooleanClause.Occur.SHOULD);

	String sSegments = Gadgets.chomp(sLuceneIndexPath,File.separator)+"k_mime_msgs"+File.separator+sWorkArea;	
    if (DebugFile.trace) DebugFile.writeln("new IndexSearcher("+sSegments+")");

    Directory oFsDir = Indexer.openDirectory(sSegments);
    IndexSearcher oSearch = new IndexSearcher(oFsDir);

      if (DebugFile.trace) DebugFile.writeln("IndexSearcher.search("+oQry.toString()+", null, "+String.valueOf(iLimit)+")");
      TopDocs oTopSet = oSearch.search(oQry, null, iLimit>0 ? iLimit : 2147483647);
      if (oTopSet.scoreDocs!=null) {
        ScoreDoc[] oTopDoc = oTopSet.scoreDocs;
        int iDocCount = oTopDoc.length;
        if (DebugFile.trace) DebugFile.writeln("doc count is "+String.valueOf(iDocCount));
        aRetArr = new MailRecord[iDocCount];
        for (int d=0; d<iDocCount; d++) {
          Document oDoc = oSearch.doc(oTopDoc[d].doc);
          String[] aAbstract = Gadgets.split(oSearch.doc(oTopDoc[d].doc).get("abstract"), '¨');
          aRetArr[d] = new MailRecord(aAbstract[0], aAbstract[1], aAbstract[2],
                                      aAbstract[3], aAbstract[4], aAbstract[5],
                                      oDoc.get("container"));
        } // next
      } else {
        aRetArr = null;
      }

    oSearch.close();
    oFsDir.close();
    
    if (oSortBy!=null && aRetArr!=null) {
      Arrays.sort(aRetArr, oSortBy);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==aRetArr)
        DebugFile.writeln("End MailSearcer.search() : no records found");
      else
        DebugFile.writeln("End MailSearcer.search() : "+String.valueOf(aRetArr.length));
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
