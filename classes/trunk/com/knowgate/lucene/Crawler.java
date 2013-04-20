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

import java.util.Properties;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.File;
import java.io.FilenameFilter;
import java.io.FileReader;
import java.io.FileInputStream;

import org.apache.lucene.analysis.*;
import org.apache.lucene.index.*;
import org.apache.lucene.store.Directory;
import org.apache.lucene.document.Document;
import org.apache.lucene.document.Field;
import org.apache.lucene.document.Field.Index;
import org.apache.lucene.document.Field.Store;
import org.apache.lucene.util.Version;

import org.apache.oro.text.regex.*;

import com.knowgate.debug.DebugFile;

/**
 * <p>Simple HTML crawler for Lucene</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 * @see http://lucene.apache.org/java/2_3_0/api/core/index.html
 */

public class Crawler {

  class RegExpFilter implements FilenameFilter {

    private Pattern oPattern;
    private PatternMatcher oMatcher;
    private PatternCompiler oCompiler;

    RegExpFilter (String sPattern) throws MalformedPatternException {
      oMatcher = new Perl5Matcher();
      oCompiler = new Perl5Compiler();
      oPattern = oCompiler.compile(sPattern);
    }

    public boolean accept(File oFile, String sName) {
      return oFile.isDirectory() || oMatcher.matches(sName, oPattern);
    }
  } // RegExpFilter

  // ---------------------------------------------------------------------------
  // Private Variables

  private String sSeparator;
  private PatternMatcher oMatcher;
  private PatternCompiler oCompiler;
  private Pattern oTagPattern;

  // ---------------------------------------------------------------------------

  public Crawler() {
    oMatcher = new Perl5Matcher();
    oCompiler = new Perl5Compiler();

    try {
      oTagPattern = oCompiler.compile("<[^>]*>");
    }
    catch (MalformedPatternException mpe) { }

    sSeparator = System.getProperty("file.separator");
  }
  // ---------------------------------------------------------------------------

  private Document makeHTMLDocument (String sRelativePath, String sName, String sHTMLText) {
    int iTitleStart, iTitleEnd;

    if (DebugFile.trace) DebugFile.writeln("Crawler.addHTMLDocument(" + sRelativePath + "," + sName + ")");

    iTitleStart = sHTMLText.indexOf("<TITLE>");
    if (iTitleStart<0) iTitleStart = sHTMLText.indexOf("<title>");

    if (iTitleStart>=0) {
      iTitleEnd = sHTMLText.indexOf("</TITLE>");
      if (iTitleEnd<0) iTitleEnd = sHTMLText.indexOf("</title>");
    }
    else
      iTitleEnd = -1;

    String sTitle;

    if (iTitleStart>=0 && iTitleEnd>0)

      sTitle = sHTMLText.substring (iTitleStart+7, iTitleEnd).trim();

    else {

      sTitle = null;

      // ***************************************************************
      // Código ñapa para indexar las listas de correo waltrappa de Iván

      iTitleStart = sHTMLText.indexOf("<H1>");
      if (iTitleStart<0) iTitleStart = sHTMLText.indexOf("<h1>");

      if (iTitleStart>=0) {
        iTitleEnd = sHTMLText.indexOf("</H1>");
        if (iTitleEnd<0) iTitleEnd = sHTMLText.indexOf("</h1>");
      }

      if (iTitleStart>=0 && iTitleEnd>0)
        sTitle = sHTMLText.substring (iTitleStart+4, iTitleEnd).trim();

      iTitleStart = sHTMLText.indexOf("<H2>");
      if (iTitleStart<0) iTitleStart = sHTMLText.indexOf("<h2>");

      if (iTitleStart>=0) {
        iTitleEnd = sHTMLText.indexOf("</H2>");
        if (iTitleEnd<0) iTitleEnd = sHTMLText.indexOf("</h2>");
      }

      if (iTitleStart>=0 && iTitleEnd>0)
        if (null==sTitle)
          sTitle = sHTMLText.substring (iTitleStart+4, iTitleEnd).trim();
        else
          sTitle += " " + sHTMLText.substring (iTitleStart+4, iTitleEnd).trim();

      // Fin de ñapa
      // ***************************************************************

      if (sTitle==null) sTitle = "untitled";
    }

    Document oDoc = new Document();

    oDoc.add (new Field("subpath", sRelativePath, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("name", sName, Field.Store.YES, Field.Index.NOT_ANALYZED));
    oDoc.add (new Field("title", sTitle, Field.Store.YES, Field.Index.ANALYZED));
    oDoc.add (new Field("text" , Util.substitute(oMatcher, oTagPattern, new StringSubstitution(""), sHTMLText, Util.SUBSTITUTE_ALL), Field.Store.NO, Field.Index.ANALYZED));

    return oDoc;
  } // makeHTMLDocument

  // ---------------------------------------------------------------------------

  private void crawlDir (IndexWriter oIWrt, String sBasePath, int iBasePathlen, RegExpFilter oFileFilter)
    throws IOException, FileNotFoundException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Crawler.crawlDir(" + sBasePath + ")");
      DebugFile.incIdent();
    }

    File oBaseDir = new File(sBasePath);
    String sName;

    if (!oBaseDir.exists())
      throw new FileNotFoundException (sBasePath + " directory does not exist");

    if (!oBaseDir.isDirectory())
      throw new IOException (sBasePath + " is not a directory");

    File[] aFiles = oBaseDir.listFiles();
    int iFiles = aFiles.length;

    int iBuffer;
    char[] aBuffer;
    String sBuffer;

    sBasePath += sSeparator;

    for (int f=0; f<iFiles; f++) {

      if (aFiles[f].isDirectory()) {

        crawlDir ( oIWrt, sBasePath + aFiles[f].getName(), iBasePathlen, oFileFilter);
      }

      else {

        sName = aFiles[f].getName().toLowerCase();

        if (sName.endsWith(".htm") || sName.endsWith(".html") || sName.endsWith(".shtml") || sName.endsWith(".shtm")) {
          iBuffer = new Long(aFiles[f].length()).intValue();

          if (iBuffer>0) {
            FileReader oReader = new FileReader(aFiles[f]);
            aBuffer = new char[iBuffer];
            oReader.read(aBuffer);
            sBuffer = new String(aBuffer);

            oIWrt.addDocument ( makeHTMLDocument(sBasePath.substring(iBasePathlen), aFiles[f].getName(), sBuffer) );
          } // fi (iBuffer>0)
        } // fi (sName.endsWith(".htm") || sName.endsWith(".html"))
      }
    } // next

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Crawler.crawlDir()");
    }
  } // crawlDir

  // ---------------------------------------------------------------------------

  /**
   * <p>Add contents to a Lucene Index
   * @param sBasePath Base Path for crawling
   * @param sFileFilter Perl5 Regular Expression filter for file names
   * @param sIndexDirectory Lucene index target directory
   * @param bRebuild <b>true</b> if index must be deleted and fully rebuild.
   * @throws IOException
   * @throws FileNotFoundException If sBasePath direcory does not exist
   * @throws MalformedPatternException If sFileFilter is not a valid Perl5 regular expression pattern
   */
  public void crawl (String sBasePath, String sFileFilter, String sIndexDirectory, boolean bRebuild)
    throws IOException, MalformedPatternException  {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Crawler.crawl(" + sBasePath + "," + sFileFilter + "," + sIndexDirectory + ")");
      DebugFile.incIdent();
    }

    Directory oFsDir = Indexer.openDirectory(sIndexDirectory);
    IndexWriter oIWrt = new IndexWriter(oFsDir, new StopAnalyzer(Version.LUCENE_33), IndexWriter.MaxFieldLength.UNLIMITED);

    if (sBasePath.endsWith(sSeparator)) sBasePath = sBasePath.substring(0, sBasePath.length()-1);

    crawlDir (oIWrt, sBasePath, sBasePath.length(), new RegExpFilter(sFileFilter));

    oIWrt.optimize();
    oIWrt.close();
    oFsDir.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Crawler.crawl()");
    }
  } // crawl

  // ---------------------------------------------------------------------------

  private static void printUsage() {
    System.out.println("");
    System.out.println("Usage:");
    System.out.println("Crawler cnf_path rebuild index_name base_path");
  }

  // ---------------------------------------------------------------------------

  public static void main(String[] argv)
    throws NoSuchFieldException, IOException, FileNotFoundException, MalformedPatternException {

    if (argv.length!=4)
      printUsage();
    else if (!argv[1].equals("rebuild")) {
      printUsage();
    }
    else {
      Properties oProps = new Properties();
      FileInputStream oCNF = new FileInputStream(argv[0]);
      oProps.load(oCNF);
      oCNF.close();

      String sDirectory = oProps.getProperty("luceneindex");

      if (null==sDirectory)
        throw new NoSuchFieldException ("Cannot find luceneindex property");

      if (!sDirectory.endsWith(System.getProperty("file.separator")))
        sDirectory += System.getProperty("file.separator");

      new Crawler().crawl (argv[3], ".*htm*$", sDirectory + argv[2], true);
    }
  } // main

} // Crawler