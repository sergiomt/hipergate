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

import java.util.Date;

import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.document.DateTools;
import org.apache.lucene.document.DateTools.Resolution;
import org.apache.lucene.document.Field;
import org.apache.lucene.document.Field.Index;
import org.apache.lucene.document.Field.Store;
import org.apache.lucene.document.Document;

import com.knowgate.misc.Gadgets;

/**
 * Indexer subclass for hipergate forum messages
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public class NewsMessageIndexer extends Indexer {

  public NewsMessageIndexer() {
  }

  public static void addNewsMessage(IndexWriter oIWrt,
                                    String sGuid, String sWorkArea,
                                    String sContainer, String sTitle,
                                    String sAuthor, Date dtCreated,
                                    String sText)
    throws ClassNotFoundException, IOException, IllegalArgumentException,
             NoSuchFieldException, IllegalAccessException, InstantiationException,
             NullPointerException {

    Document oDoc = new Document();
    oDoc.add (new Field ("workarea" , sWorkArea, Field.Store.YES, Field.Index.UN_TOKENIZED));
    oDoc.add (new Field ("container", sContainer, Field.Store.YES, Field.Index.UN_TOKENIZED));
    oDoc.add (new Field ("guid"     , sGuid, Field.Store.YES, Field.Index.UN_TOKENIZED));
    oDoc.add (new Field ("created"  , DateTools.dateToString(dtCreated, DateTools.Resolution.SECOND), Field.Store.YES, Field.Index.UN_TOKENIZED));
    oDoc.add (new Field ("title"    , sTitle, Field.Store.YES, Field.Index.TOKENIZED));
    oDoc.add (new Field ("author"   , sAuthor, Field.Store.YES, Field.Index.TOKENIZED));
    oDoc.add (new Field ("text"     , sText, Field.Store.NO, Field.Index.TOKENIZED));
    if (sText.length()>80)
      oDoc.add (new Field("abstract", sText.substring(0,80), Field.Store.YES, Field.Index.TOKENIZED));
    else
      oDoc.add (new Field("abstract", sText, Field.Store.YES, Field.Index.TOKENIZED));
    oIWrt.addDocument(oDoc);
  } // addNewsMessage
}
