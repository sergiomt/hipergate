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

import java.util.Properties;
import java.io.File;
import java.io.IOException;

import org.apache.lucene.index.Term;
import org.apache.lucene.store.Directory;
import org.apache.lucene.search.TermQuery;
import org.apache.lucene.search.BooleanQuery;
import org.apache.lucene.search.BooleanClause;
import org.apache.lucene.search.IndexSearcher;
import org.apache.lucene.search.TopDocs;
import org.apache.lucene.search.ScoreDoc;
import org.apache.lucene.document.Document;
import org.apache.lucene.queryParser.ParseException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * Search into a Lucene full text index for contacts
 * @author Alfonso Marín López
 * @version 7.0
 */
public class ContactSearcher {

  public ContactSearcher() {
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
  public static ContactRecord[] search (Properties oProps,
                                     String sWorkArea, 
                                     String values[],
                                     boolean obligatorio[])
    throws ParseException, IOException, NullPointerException {

  if (null==oProps.getProperty("luceneindex"))
    throw new NullPointerException("ContactSearcher.search() luceindex parameter cannot be null");

    if (null==sWorkArea)
      throw new NullPointerException("ContactSearcher.search() workarea parameter cannot be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ContactSearcher.search("+oProps.getProperty("luceneindex")+","+
                        sWorkArea+","+String.valueOf(20)+")");
      DebugFile.incIdent();
    }

	BooleanQuery oQry = new BooleanQuery();

	oQry.add(new TermQuery(new Term("workarea",sWorkArea)),BooleanClause.Occur.MUST);
	
	for(int i=0; i<values.length;i++){
		if(obligatorio[i]){
			oQry.add(new TermQuery(new Term("value",values[i])),BooleanClause.Occur.MUST);
		}else{
			oQry.add(new TermQuery(new Term("value",values[i])),BooleanClause.Occur.SHOULD);
		}
	}

	String sSegments = Gadgets.chomp(oProps.getProperty("luceneindex"),File.separator)+"k_contacts"+File.separator+sWorkArea;	
    if (DebugFile.trace) DebugFile.writeln("new IndexSearcher("+sSegments+")");
	
    File oDir = new File(sSegments);
	if(!oDir.exists()){
		try {
			Indexer.rebuild(oProps, "k_contacts", sWorkArea);
		} catch (Exception e) {
			if(DebugFile.trace)
				DebugFile.writeln(e.getMessage());
		} 
	}
	Directory oFsDir = Indexer.openDirectory(sSegments);
    IndexSearcher oSearch = new IndexSearcher(oFsDir);
    
    Document oDoc;

    ContactRecord aRetArr[] = null;
    
      TopDocs oTopSet = oSearch.search(oQry, null, 20);
      if (oTopSet.scoreDocs!=null) {
        ScoreDoc[] oTopDoc = oTopSet.scoreDocs;
        int iDocCount = oTopDoc.length;
        aRetArr = new ContactRecord[iDocCount];
        for (int d=0; d<iDocCount; d++) {
          oDoc = oSearch.doc(oTopDoc[d].doc);
         // String[] aAbstract = Gadgets.split(oSearch.doc(oTopDoc[d].doc).get("abstract"), '¨');
          aRetArr[d] = new ContactRecord(oTopDoc[d].score,oDoc.get("author"),
        			  oDoc.get("workarea"),oDoc.get("guid"),oDoc.get("value"));
        } // next
      } else {
    	  aRetArr = null;
      }
   
    oSearch.close();
    oFsDir.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==aRetArr)
        DebugFile.writeln("End ContactSearcher.search() : no records found");
      else
        DebugFile.writeln("End ContactSearcher.search() : "+String.valueOf(aRetArr.length));
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
