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

package com.knowgate.surveys;

import java.lang.ref.SoftReference;

import java.io.IOException;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.UnsupportedEncodingException;
import java.io.InputStream;
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

import java.util.Date;
import java.util.ArrayList;
import java.util.Properties;
import java.util.Collection;
import java.util.Iterator;

import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataxslt.StylesheetCache;
import com.knowgate.dfs.FileSystem;

import org.jibx.runtime.IBindingFactory;
import org.jibx.runtime.IUnmarshallingContext;
import org.jibx.runtime.BindingDirectory;
import org.jibx.runtime.JiBXException;
import org.mozilla.javascript.JavaScriptException;

/**
 * Survey Page Definition
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class SurveyPage extends DBPersist {

  //----------------------------------------------------------------------------

  public String name;
  public String title;
  public String description;
  public String asciifile;
  public String delimiter;
  public String dosbr;
  public String stylesheet;
  public String theme;
  public String bgcolor;
  public String redirect;
  public String submittext;
  public String cleartext;
  public String savetext;
  public String multipage;
  public String lastpage;
  public String progres;
  public boolean showclear;
  public boolean showsave;
  public ArrayList resources;
  public ArrayList questions;
  public Survey mastersurvey;
  public CaseRoute router;

  private SoftReference xsloutput;
  private long xslupdate;

  //----------------------------------------------------------------------------

  public SurveyPage() {
    super(DB.k_pageset_pages, "SurveyPage");
    resources = new ArrayList();
    questions = new ArrayList();
    mastersurvey = null;
    router = null;
    xsloutput = null;
    xslupdate = new Date(80,0,1,0,0).getTime();
  }

  //----------------------------------------------------------------------------

  public SurveyPage(Survey oMaster) {
    super(DB.k_pageset_pages, "SurveyPage");
    questions = new ArrayList();
    mastersurvey = oMaster;
    router = null;
  }

  //----------------------------------------------------------------------------

  public int getPageNumber() {
    int iPgPage;

    if (isNull(DB.pg_page))
      iPgPage = -1;
    else
      iPgPage = getInt(DB.pg_page);

    return iPgPage;
  }

  //----------------------------------------------------------------------------

  public Survey getSurvey() {
    return mastersurvey;
  }

  //----------------------------------------------------------------------------

  public void setSurvey(Survey oMaster) {
    mastersurvey = oMaster;
  }

  //----------------------------------------------------------------------------

  /**
   * Get number of questions on this page
   * @return int Question count
   */
  public int countQuestions()  {
    if (questions==null)
      return 0;
    else
      return questions.size();
  }

  //----------------------------------------------------------------------------

  /**
   * Get Question by its position
   * @param n Position of Question at internal memory array
   * (as appears in order of XML Survey definition file for this page)
   * @return Question
   * @throws IndexOutOfBoundsException If n>countQuestions()
   */
  public Question getQuestion(int n) throws IndexOutOfBoundsException {
    return (Question) questions.get(n);
  }

  //----------------------------------------------------------------------------

  /**
   * Get Question by name
   * @param name Name of Question
   * @return Question object or <b>null</b> if no question with such name was found
   * @throws NullPointerException
   */
  public Question getQuestion(String name)  throws NullPointerException {
    Question oQuest = null;
    final int quests = questions.size();
    for (int q=0; q<quests; q++) {
      if (((Question) questions.get(q)).getName().equals(name)) {
        oQuest = (Question) questions.get(q);
        break;
      } // fi
    } // next
    return oQuest;
  } // getQuestion

  //----------------------------------------------------------------------------

  private String transform(InputStream oInStrm, String sStorage,
                           String sStyleSheet, Properties oParams)
    throws TransformerConfigurationException, TransformerException,
           FileNotFoundException, IOException {

    final int BUFFER_SIZE = 16000;
    FileInputStream oFileStream = null;
    BufferedInputStream oXMLStream = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Survey.transform([InputStream],"+sStorage+","+sStyleSheet+")");
      DebugFile.incIdent();
      DebugFile.writeln("path_page="+getStringNull(DB.path_page, "null"));
    }

    ByteArrayOutputStream oByStream = new ByteArrayOutputStream(BUFFER_SIZE);

    // Begin XSL Transformation

      if ((oParams.getProperty("pageset")==null) && !isNull(DB.gu_pageset))
        oParams.setProperty("pageset", getString(DB.gu_pageset));
      if ((oParams.getProperty("page")==null) && !isNull(DB.gu_page))
        oParams.setProperty("page", getString(DB.gu_page));
      if ((oParams.getProperty("pagenum")==null) && !isNull(DB.pg_page))
        oParams.setProperty("pagenum", String.valueOf(getInt(DB.pg_page)));

      StylesheetCache.transform(sStorage+sStyleSheet, oInStrm, oByStream, oParams);

    // End XSL Transformation

    String sRetVal = null;
    try {
      sRetVal = oByStream.toString("UTF-8");
    } catch (java.io.UnsupportedEncodingException neverthrown) {}

    oByStream.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Survey.transform()");
    }
    return sRetVal;
  } // transform

  //----------------------------------------------------------------------------

  /**
   * Transform a Page XML definition into an HTML document
   * @param sStorage Base path to /storage directory
   * (usually storage property taken from hipergate.cnf)
   * @param sStyleSheet Relative path to stylesheet to be used
   * (for example xslt/templates/Survey/survey.xsl)
   * @param oProps Parameters<br>
   * <table>
   * <tr><td><b>datasheet</b></td><td><i>Required</i> GUID of DataSheet for filling HTML controls</td></tr>
   * <tr><td><b>imageserver</b></td><td><i>Required</i> imageserver property from hipergate.cnf</td></tr>
   * <tr><td><b>workarea</b></td><td><i>Required</i> WorkArea to which the PageSet of this Page belongs </td></tr>
   * <tr><td><b>pageset</b></td><td><i>Optional</i> PageSet GUID. If missing is taken from k_pageset_pages</td></tr>
   * <tr><td><b>page</b></td><td><i>Optional</i> Page GUID. If missing is taken from k_pageset_pages</td></tr>
   * <tr><td><b>pagenum</b></td><td><i>Optional</i> Page Number. If missing is taken from k_pageset_pages</td></tr>
   * </table>
   * @return HTML output string
   * @throws TransformerConfigurationException
   * @throws TransformerException
   * @throws IOException
   * @throws StackOverflowError
   */
  public String transform(String sStorage, String sStyleSheet, Properties oParams)
    throws TransformerConfigurationException, TransformerException,
           FileNotFoundException, IOException, StackOverflowError {

    final int BUFFER_SIZE = 16000;
    FileInputStream oFileStream = null;
    BufferedInputStream oXMLStream = null;
    String sRetVal;
    long lFileDate;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Survey.transform("+sStorage+","+sStyleSheet+",[Properties])");
      DebugFile.incIdent();
    }

    // Begin XSL Transformation
      File oXMLFile = new File(sStorage+getString(DB.path_page));
      lFileDate = oXMLFile.lastModified();

      boolean bLostReference;
      if (xsloutput==null)
        bLostReference = true;
      else
        bLostReference = (xsloutput.get()==null);

      if ((lFileDate>xslupdate) || bLostReference) {
        if (DebugFile.trace) DebugFile.writeln("cache miss for "+sStorage+getString(DB.path_page));
        oFileStream = new FileInputStream(oXMLFile);
        oXMLStream = new BufferedInputStream(oFileStream, BUFFER_SIZE);
        sRetVal = transform(oXMLStream, sStorage, sStyleSheet, oParams);
        oXMLStream.close();
        oXMLStream=null;
        oFileStream.close();
        oFileStream=null;
        xslupdate = lFileDate;
        xsloutput = new SoftReference(sRetVal);
      } else {
        if (DebugFile.trace) DebugFile.writeln("cache hit for "+sStorage+getString(DB.path_page));
        sRetVal = (String) xsloutput.get();
      }

    // End XSL Transformation

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Survey.transform()");
    }
    return sRetVal;
  } // transform

  //----------------------------------------------------------------------------

  /**
   * <p>Transform a Page XML definition and user fullfilment errors into an HTML document</p>
   * @param sStorage Base path to /storage directory
   * @param sStyleSheet sStyleSheet Relative path to stylesheet to be used
   * @param oParams Parameters
   * @param oErrors Collection of error messages produced after checking user's
   * input for this page.
   * @return HTML output string
   * @throws TransformerConfigurationException
   * @throws TransformerException
   * @throws FileNotFoundException
   * @throws StackOverflowError
   * @throws IOException
   */
  public String transform(String sStorage, String sStyleSheet,
                          Properties oParams, Collection oErrors)
    throws TransformerConfigurationException, TransformerException,
           FileNotFoundException, IOException, StackOverflowError {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Survey.transform("+sStorage+","+sStyleSheet+",[Properties],[Collection])");
      DebugFile.incIdent();
    }
    char[] aPageChars = null;

    // Read this Page XML definition file from disk
    try {
      aPageChars = FileSystem.readfile(sStorage+getString(DB.path_page),"UTF-8");
    }  catch (com.enterprisedt.net.ftp.FTPException neverthrow) {}

    if (DebugFile.trace) DebugFile.writeln("looking for </SURVEY> tag...");
    StringBuffer oBuffer = new StringBuffer(aPageChars.length+256);

    // Seek position of </SURVEY> tag for the end of file back to the begining
    int iInsertPoint = -1;
    for (int p=aPageChars.length-9; p>0; p--) {
      if (aPageChars[p]=='<') {
        if (aPageChars[p+1]=='/' && aPageChars[p+2]=='S' && aPageChars[p+3]=='U' &&
            aPageChars[p+4]=='R' && aPageChars[p+5]=='V' && aPageChars[p+6]=='E' &&
            aPageChars[p+7]=='Y' && aPageChars[p+8]=='>') {
          iInsertPoint = p;
          break;
        } // fi ("</SURVEY>")
      } // fi ('<')
    } // next (p)
    if (-1==iInsertPoint) {
      if (DebugFile.trace) {
        DebugFile.writeln("Tag </SURVEY> not found at " + sStorage + getString(DB.path_page));
        DebugFile.decIdent();
      }
      throw new TransformerException("Tag </SURVEY> not found at "+sStorage+getString(DB.path_page));
    } else  if (DebugFile.trace) DebugFile.writeln("</SURVEY> tag found at position "+String.valueOf(iInsertPoint));

    // Insert all Page definition except </SURVEY> tag in a StringBuffer
    oBuffer.append(aPageChars,0,iInsertPoint);

    // Append errors to the StringBuffer
    oBuffer.append("  <ERRORS COUNT=\""+String.valueOf(oErrors.size())+"\">\n");
    Iterator oIter = oErrors.iterator();
    while (oIter.hasNext()) {
      oBuffer.append("    <ERROR><![CDATA["+oIter.next().toString()+"]]></ERROR>\n");
    } // wend
    oBuffer.append("</ERRORS>\n");

    // Append </SURVEY> tag to the StringBuffer
    oBuffer.append(aPageChars,iInsertPoint,aPageChars.length-iInsertPoint);

    // Convert StringBuffer to UTF-8 ByteArrayInputStream
    ByteArrayInputStream oByStrm = new ByteArrayInputStream(oBuffer.toString().getBytes("UTF-8"));
    String sRetVal = transform(oByStrm, sStorage, sStyleSheet, oParams);
    oByStrm.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Survey.transform()");
    }
    return sRetVal;
  } // transform

  //----------------------------------------------------------------------------

  /**
   * Parse an XML file into a SurveyPage
   * @param sXMLDocPath Full path to XML file to be parsed
   * @param sEnc Character Encoding, if null it will be determined by the parser
   * @return SurveyPage object instance
   * @throws JiBXException
   * @throws FileNotFoundException
   * @throws UnsupportedEncodingException
   * @throws IOException
   */
  public static SurveyPage parse(String sXMLDocPath, String sEnc)
    throws JiBXException, FileNotFoundException, UnsupportedEncodingException,
           IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Survey.parse("+sXMLDocPath+","+sEnc+")");
      DebugFile.incIdent();
    }

    IBindingFactory bfact = BindingDirectory.getFactory(SurveyPage.class);
    IUnmarshallingContext uctx = bfact.createUnmarshallingContext();

    final int BUFFER_SIZE = 16000;
    FileInputStream oFileStream = new FileInputStream(sXMLDocPath);
    BufferedInputStream oXMLStream = new BufferedInputStream(oFileStream, BUFFER_SIZE);

    Object obj = uctx.unmarshalDocument (oXMLStream, sEnc);

    oXMLStream.close();
    oFileStream.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Survey.parse()");
    }

    return (SurveyPage) obj;
  } // parse

  //----------------------------------------------------------------------------

  /**
   * <p>Get number of page to route</p>
   * This method evaluates the tag &lt;CASEROUTE&gt;
   * @param datasht DataSheet object with values for CASEROUTE parameters
   * @return Number of page to which flow of control must be routed after current one
   * @throws ClassCastException If JavaScript expression does nor evaluate to a boolean value.
   * @throws JavaScriptException If an error occurs evaluating JavaScript expression of a CASEROUTE
   */
  public int getRouteToPageNumber(DataSheet datasht)
    throws ClassCastException,JavaScriptException {
    int pagnum;
    if (DebugFile.trace) {
      DebugFile.writeln("Begin SurveyPage.getRouteToPageNumber([DataSheet])");
      DebugFile.incIdent();
    }
    if (router==null) {
      pagnum = getPageNumber()+1;
      if (DebugFile.trace) DebugFile.writeln("No CaseRoute set, routing to next page by default");
    }
    else {
      pagnum = router.getPageNumber(datasht);
      if (-1==pagnum) {
        if (DebugFile.trace) DebugFile.writeln("CaseRoute was unable to determine next page, routing to next page by default");
        pagnum = getPageNumber() + 1;
      }
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SurveyPage.getRouteToPageNumber() : " + String.valueOf(pagnum));
    }
    return pagnum;
  } // getRouteToPageNumber

  //----------------------------------------------------------------------------
}
