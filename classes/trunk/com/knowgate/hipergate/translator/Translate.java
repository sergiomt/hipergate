/*
  Copyright (C) 2003-2007  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipergate.translator;

import java.net.URL;
import java.util.ArrayList;
import java.util.Properties;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import java.util.TreeMap;

import java.io.IOException;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileInputStream;

import java.net.MalformedURLException;
import java.sql.DriverManager;
import java.sql.DatabaseMetaData;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import com.knowgate.dfs.FileSystem;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.CSVParser;

import com.enterprisedt.net.ftp.FTPException;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpConnection;
import org.apache.commons.httpclient.HttpState;
import org.apache.commons.httpclient.NameValuePair;
import org.apache.commons.httpclient.UsernamePasswordCredentials;

import org.apache.commons.httpclient.auth.AuthPolicy;
import org.apache.commons.httpclient.auth.AuthScope;

import org.apache.commons.httpclient.methods.PostMethod;

/**
 * <p>Robot for translating text files using k_translations table</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Translate {

  private ArrayList aTags;
  private ArrayList aWords;
  private FileSystem oHttpFs;
  /**
   * A sorted array with the extensions of files that will be parsed
   */
  private String[] aExtensions = new String[]{".htm",".html",".inc",".jsp",".jspf",".xml",".xsl"};
  private HashMap oEncodings;
  private HttpClient oHttpCli;

  // ---------------------------------------------------------------------------

  public Translate() {
    aTags=aWords=null;
    oHttpFs = new FileSystem();
    oHttpCli = new HttpClient();
    oEncodings = new HashMap(4093);
    Arrays.sort(aExtensions, String.CASE_INSENSITIVE_ORDER);
  }

  // ---------------------------------------------------------------------------

  public Translate(String sAuthUsr, String sAuthStr, String sRealm, String sHost) {
    aTags=aWords=null;
    oHttpFs = new FileSystem(sAuthUsr, sAuthStr, sRealm);
    oHttpCli = new HttpClient();
	oHttpCli.getState().setCredentials(sRealm, sHost,
                					   new UsernamePasswordCredentials(sAuthUsr, sAuthStr));
    oEncodings = new HashMap(4093);
    Arrays.sort(aExtensions, String.CASE_INSENSITIVE_ORDER);
  }

  // ---------------------------------------------------------------------------

  /**
   * @return List of translatable file extensions
   */
  public List extensions() {
    return Arrays.asList(aExtensions);
  }

  // ---------------------------------------------------------------------------

  /**
   * Find out whether the given file is in the list of translatable files
   * @return <b>true</b> if the file extension is in the list of translatable file extensions
   */
  private boolean isTranslatable(String sFileName) {
    if (sFileName==null) return false;
    int iExt = sFileName.lastIndexOf('.');
    if (iExt!=-1)
      return Arrays.binarySearch(aExtensions, sFileName.substring(iExt).toLowerCase())>=0;
    else
      return false;
  } // isTranslatable

  // ---------------------------------------------------------------------------

  /**
   * This routine is currently unstable and must not be used
   */
  private void autoFill(String sDrv, String sUrl, String sUsr, String sPwd, String sCnf)
    throws MalformedURLException,FileNotFoundException,IOException {

    boolean bAutocompleted;
    ArrayList oTagList;
    String sFullTranslationsTable;

    // Columns from k_translations table
    final String sCols = "tx_directory,tx_filename,tx_tag,dt_created,dt_modified,tr_en,tr_es,tr_de,tr_it,tr_fr,tr_pt,tr_ca,tr_eu,tr_ja,tr_cn,tr_tw_old,tr_ru,tr_fi,tr_pl,tr_es_edu,tr_tw,tr_nl,tr_th,tr_cs,tr_uk,tr_no,tr_sk,tr_en_np,tr_ko";
    final String[] aCols = Gadgets.split(sCols,',');
    final int nCols = aCols.length;

    // Get the full k_translations table as a text string
    try {
      sFullTranslationsTable = oHttpFs.readfilestr(sUrl+"?profile="+sCnf+"&user="+sUsr+"&password="+sPwd+"&command=query&coldelim=%A8&rowdelim=%60&maxrows=10000&table=k_translations&fields="+sCols+"&where=1%3D1","UTF-8");
    } catch (com.enterprisedt.net.ftp.FTPException neverthrown) { sFullTranslationsTable=null; }

    // Split lines from k_translations table
    String[] aTranslationLines = Gadgets.split(sFullTranslationsTable, '`');
    final int nLines = aTranslationLines.length;

    // This map will a have an entry for each distinct tx_tag value
    // Each entry will be the list of lines from k_translations table
    // which contain the given tx_tag
    HashMap oTagsMap = new HashMap(nLines*3);

    // Iterate throught all lines and fill oTagsMap
    for (int l=0; l<nLines; l++) {
      if (aTranslationLines[l].indexOf('¨')>0) {
        String[] aLine = Gadgets.split(aTranslationLines[l],'¨');
        if (oTagsMap.containsKey(aLine[2])) {
          oTagList = (ArrayList) oTagsMap.get(aLine[2]);
          oTagList.add(aLine);
        } else {
          oTagList = new ArrayList();
          oTagList.add(aLine);
          oTagsMap.put(aLine[2], oTagList);
        } // fi
      }
    } // next (l)

    // Now iterate throught the map of tags
    // For each tag look at all of its lines
    // if one line does not have translations
    // for a given language but another line does
    // then fill the translation in the empty line
    // with the value present at the second one.
    Iterator oIter = oTagsMap.values().iterator();
    while (oIter.hasNext()) {
      // This is a list of k_translations lines
      oTagList = (ArrayList) oIter.next();
      // Autofill is only possible if there is more than one line with the same tx_tag
      if (oTagList.size()>1) {
        // Loop throught all lines of the same tag
        for (int i=0; i<oTagList.size(); i++) {
          // This is an array of the lines with the same tx_tag
          String[] aTagLine = (String[]) oTagList.get(i);
          // This variable will be set to true if autocomplete is possible
          bAutocompleted = false;
          // Read one by one all columns for translations
          for (int c=5; c<nCols; c++) {
            // This is a single translation for a particular language
            String sTr1 = aTagLine[c];
            if (sTr1==null) sTr1 = "null";
            if (sTr1.length()==0) sTr1 = "null";
            if (sTr1.equals("null")) {
              // If the translation at current line is null then
              // look at the values of the same column at all other lines
              // and if there is one which is not null then
              // put the value of the second line into the first one
              for (int j=0; j<oTagList.size(); j++) {
                if (i!=j) {
                  String sTr2 = ((String[]) oTagList.get(j))[c];
                  if (sTr2==null) sTr1 = "null";
                  if (sTr2.length()==0) sTr1 = "null";
                  if (!sTr2.equals("null")) {
                    aTagLine[c] = sTr2;
                    bAutocompleted = true;
                    break;
                  } // fi
                } // fi
              } // next
            } // fi
          } // next
          // If the line was autocompleted then re-write it at the database
          if (bAutocompleted) {
            PostMethod oPost = new PostMethod(sUrl);
            oPost.addParameter(new NameValuePair("profile", sCnf));
            oPost.addParameter(new NameValuePair("user", sUsr));
            oPost.addParameter(new NameValuePair("password", sPwd));
            oPost.addParameter(new NameValuePair("command", "update"));
            oPost.addParameter(new NameValuePair("table", "k_translations"));
            for (int n=0; n<nCols; n++) {
              if (aTagLine[n]!=null) {
                if (!aTagLine[n].equalsIgnoreCase("null")) {
                  oPost.addParameter(new NameValuePair(aCols[n], aTagLine[n]));
                } // fi
              } // fi
            } // next (n)
            //HttpConnection oHonn = new HttpConnection("www.hipergate.org", 80);
            //oHonn.open();
            try {
			  oHttpCli.executeMethod(oPost);
              //oPost.execute(new HttpState(), oHonn);
              String sResponse = oPost.getResponseBodyAsString();
              if (null!=sResponse) {
                if (sResponse.equals("SUCCESS")) {
                  System.out.println(aTagLine[0]+"/"+aTagLine[1]+"/"+aTagLine[2]+" sucessfully filled");
                } else {
                  System.out.println(sResponse);
                }
              }
              else {
                System.out.println(String.valueOf(oPost.getStatusText()));
                System.out.println(oPost.getStatusText());
                System.out.println(oPost.getStatusLine());
              }
            } finally {
              oPost.releaseConnection();
            }
            //oHonn.close();
          } // fi (bAutocompleted)
        } // next (i)
      } // fi
    } // wend
  } // autoFill

  // ---------------------------------------------------------------------------

  public void loadTranslationsForFile(String sDrv, String sUrl,
                                      String sUsr, String sPwd,
                                      String sLng, String sDir,
                                      String sFle, String sCnf)
    throws SQLException,ClassNotFoundException,IOException,FileNotFoundException {

    // If the driver is the name of HttpDataObjsServlet then
    // connect to the database throught a servlet bridge
    if (sDrv.equals("com.knowgate.http.HttpDataObjsServlet")) {
      if (!sUrl.startsWith("http://") && !sUrl.startsWith("https://")) sUrl = "http://"+sUrl;
      if (null==sCnf) sCnf = "hipergate";
      if (sCnf.length()==0) sCnf = "hipergate";
      char[] aTagWords;
      System.out.println(sDir+"/"+sFle);
      try {
        aTagWords = oHttpFs.readfilestr(sUrl+"?profile="+sCnf+"&user="+sUsr+"&password="+sPwd+"&command=query&coldelim=%A8&rowdelim=%0A&table=k_translations&fields=tx_tag,tr_"+sLng+"&where=tx_directory"+Gadgets.URLEncode("='"+sDir+"' AND tx_filename='"+sFle+"' AND tr_"+sLng+" IS NOT NULL"),"UTF-8").toCharArray();
      } catch (com.enterprisedt.net.ftp.FTPException neverthrown) { aTagWords=null; }
      CSVParser oPrs = new CSVParser("UTF-8");
      oPrs.parseData(aTagWords, "tag¨tr");
      final int nLin = oPrs.getLineCount();
      aTags = new ArrayList(nLin);
      aWords = new ArrayList(nLin);
      for (int l=0; l<nLin; l++) {
        aTags.add (oPrs.getField(0,l));
        aWords.add(oPrs.getField(1,l));
      } // next
    } else {
      Class.forName(sDrv);
      Connection oCon = DriverManager.getConnection(sUrl,sUsr,sPwd);
      DatabaseMetaData oMdt = oCon.getMetaData();
      if (oMdt.getDatabaseProductName().equals("PostgreSQL")) {
        Statement oSet = oCon.createStatement();
        oSet.execute("SET client_encoding = 'UNICODE'");
        oSet.close();
        oSet=null;
      } // fi
      aTags = new ArrayList();
      aWords = new ArrayList();
      PreparedStatement oStm = oCon.prepareStatement("SELECT tx_tag, tr_" + sLng + " FROM k_translations WHERE tx_directory=? AND tx_filename=? AND tr_" + sLng + " IS NOT NULL",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStm.setString(1, sDir);
      oStm.setString(2, sFle);
      ResultSet oRst = oStm.executeQuery();
      while (oRst.next()) {
        String sTag = oRst.getString(1);
        String sTr = oRst.getString(2);
        aTags.add(sTag);
        aWords.add(sTr);
      } //wend
      oRst.close();
      oStm.close();
    }
  } // loadTranslationsForFile

  // ---------------------------------------------------------------------------

  /**
   * Create a Map with all the translatable literals found at a given file
   * @param sSourceBase Source base directory
   * @param sSourceDir Source subdirectory
   * @param sSourceFile Source file name with extension
   * @throws MalformedURLException
   * @throws FTPException
   * @throws FileNotFoundException
   * @throws IOException
   */
   
  public HashMap extractTagsFromFile(String sSourceBase, String sSourceDir, String sSourceFile)
    throws MalformedURLException, FTPException, FileNotFoundException, IOException {
    HashMap oTagMap = new HashMap(123);
    
    // Concatenate sSourceBase + sSourceDir + sSourceFile to form the full path to the file to be scanned
    String sSourcePath = sSourceBase + (sSourceDir.length()>0 ? File.separator + sSourceDir : "")  + File.separator + sSourceFile;
    String sSource;

	// If the file has already been assigned a character encoding then use it
	// else try to automatically detect character encoding
    if (oEncodings.containsKey(sSourcePath)) {
      sSource = oHttpFs.readfilestr(sSourcePath, (String) oEncodings.get(sSourcePath));
    } else {
      sSource = oHttpFs.readfilestr(sSourcePath, null);
      oEncodings.put(sSourcePath, oHttpFs.detectEncoding(sSourcePath,"ISO-8859-1"));
    }

    final int iLen = sSource.length();
    int iLeftBracket, iRightBracket, iLeftHyppen, iRightHyppen;
    int iFrom = 0;
    if (iLen>5) {
      // Search for literals enclosed between [~ ~]
      do {
        // Search for a left bracket '['
        iLeftBracket = sSource.indexOf('[', iFrom);
        // If left bracket is found before 4 characters from end of file
        if (iLeftBracket>=0) {
          if (iLeftBracket<iLen-4) {
            // Check if character next to left bracket is '~'
            if (sSource.charAt(iLeftBracket+1)=='~' &&
               (sSource.charAt(iLeftBracket+2)!='/' || sSource.charAt(iLeftBracket+3)!='/')) {
              // Now we have found a marker for a tag start "[~"
              iLeftHyppen = iLeftBracket+1;
              // Search for a matching '~]'
              iRightHyppen = sSource.indexOf("~]", iLeftHyppen+1);
              if (iRightHyppen!=-1) {
                iRightBracket = iRightHyppen+1;
                // Now we have the start and end positions of tag [~ ... ~]
                String sTag = sSource.substring(iLeftBracket, iRightBracket+1);
                // Add the tag just found to the tags map
                // the FALSE status is a flag that indicated whether or not the tag
                // is already stored at the database. Because at this point the db
                // has not already been accessed, all the tags are marked as non-stored
                // until writeTagsToDatabase() method is called
                if (!oTagMap.containsKey(sTag)) oTagMap.put(sTag, Boolean.FALSE);
                iFrom = iRightBracket;
              } else {
                // A tag start marker was reached but no corresponding
                // end tag "[~" was found
                System.err.println(sSourceDir+File.separator+sSourceFile+" unclosed tag marker [~ at character position "+String.valueOf(iLeftBracket));
                iFrom=iLeftBracket+1;
              }
            } else {
              // The character next to '[' is not a '~'
              // or the tag is commented with a double slash '//'
              // so this was a bracket but not a tag start marker.
              // Just continue tag search from here.
              iFrom=iLeftBracket+1;
            }
            iFrom=iLeftBracket+1;
          } // fi (iLeftBracket<iLen-4)
        } // fi (iLeftBracket>=0)
      } while (iLeftBracket>=0 && iFrom<iLen-4);
    }
    return oTagMap;
  } // extractTagsFromFile

  // ---------------------------------------------------------------------------

  /**
   * <p>Write a tag map extracted from a file to the database</p>
   * @param oTagMap The Map to be written.
   * @param sDrv Name of class for database drive,
   * for example oracle.jdbc.driver.OracleDriver
   * or com.knowgate.http.HttpDataObjsServlet if the database will
   * be accessed throught an HttpDataObjsServlet HTTP bridge
   * @param sUrl Database connection string (like jdbc:oracle:thin:@localhost:1521:XE)
   * or full HTTP URL to HttpDataObjsServlet servlet.
   * @param sUsr Database user name.
   * @param sPwd Database user password.
   * @param sDir Directory where file which tags are to be written is located.
   * @param sFle File name.
   * @param sCnf Profile name. If <b>null</b> or "" then "hipergate" is the default.
   * @throws MalformedURLException
   * @throws SQLException
   * @throws ClassNotFoundException
   * @throws FileNotFoundException
   * @throws IOException
   */
  public void writeTagsToDatabase(HashMap oTagMap,
                                  String sDrv, String sUrl,
                                  String sUsr, String sPwd,
                                  String sDir, String sFle, String sCnf)
    throws MalformedURLException,SQLException,ClassNotFoundException,FileNotFoundException,IOException {
    Iterator oTags;

    if (sDrv.equals("com.knowgate.http.HttpDataObjsServlet")) {
      String sResponse;
      
      // If using an HTTP servelt bridge then ensure that the URL starts with http:// or https://
      if (!sUrl.startsWith("http://") && !sUrl.startsWith("https://")) sUrl = "http://"+sUrl;
	  URL oUrl = new URL(sUrl);

      // Use hipergate profile by default
      if (null==sCnf) sCnf = "hipergate";
      if (sCnf.length()==0) sCnf = "hipergate";
      
      String sTags;
      try {
       // Get all tags currently stored at the database for the desired file
       sTags = oHttpFs.readfilestr(sUrl+"?profile="+sCnf+"&user="+sUsr+"&password="+sPwd+"&command=query&table=k_translations&fields=tx_tag&where="+Gadgets.URLEncode("tx_directory='"+sDir+"' AND tx_filename='"+sFle+"'"),"UTF-8");
      }
      catch (com.enterprisedt.net.ftp.FTPException neverthrown) { sTags = null; }

      if (sTags!=null) {
        if (sTags.trim().length()>0) {
          // Tags are delimited by '¨'
          String[] aExistingTagList = Gadgets.split(sTags, '¨');
          final int nTags = aExistingTagList.length;
          for (int t=0; t<nTags; t++) {
            // For those tags of this file already stored at the database
            // change its store flag status to TRUE
            if (oTagMap.containsKey(aExistingTagList[t])) {
              oTagMap.remove(aExistingTagList[t]);
              oTagMap.put(aExistingTagList[t], Boolean.TRUE);
            } // fi
          } // next
        } // fi
      } // fi

      oTags = oTagMap.keySet().iterator();
      while (oTags.hasNext()) {
        String sTag = (String) oTags.next();
        try {
          // If the tag was not already present at the database then add it
          if (oTagMap.get(sTag).equals(Boolean.FALSE)) {
            String sEscapedTag = Gadgets.replace(sTag, "'", "''");
            PostMethod oPost = new PostMethod(sUrl);
            oPost.setRequestBody(new NameValuePair[] {
              new NameValuePair("profile", sCnf),
              new NameValuePair("user", sUsr),
              new NameValuePair("password", sPwd),
              new NameValuePair("command", "update"),
              new NameValuePair("table", "k_translations"),
              new NameValuePair("tx_directory", sDir),
              new NameValuePair("tx_filename", sFle),
              new NameValuePair("tx_tag", sEscapedTag),
              new NameValuePair("tr_es", sEscapedTag.substring(2, sEscapedTag.length()-2))});
              
            // Open HTTP connection
            //HttpConnection oHonn = new HttpConnection(oUrl.getHost(), oUrl.getPort());

            //oHonn.setHttpConnectionManager(oHttpConMan);
            //oHonn.open();

            try {			  
			  oPost.setDoAuthentication(true);
			  oHttpCli.executeMethod(oPost);
              //oPost.execute(oHttpCli.getState(), oHonn);
              sResponse = oPost.getResponseBodyAsString();

              if (null!=sResponse) {
                System.out.println(sResponse);
              } else {
                System.out.println(String.valueOf(oPost.getStatusText()));
                System.out.println(oPost.getStatusText());
                System.out.println(oPost.getStatusLine());
              }
            } finally {
              oPost.releaseConnection();
            }
            //oHonn.close();
          } // fi
        }
        catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) { }
      } // wend
    } else {
      // Use LAN JDBC connection to the database
      Class.forName(sDrv);
      Connection oCon = DriverManager.getConnection(sUrl,sUsr,sPwd);
      oCon.setAutoCommit(true);
      PreparedStatement oSel = oCon.prepareStatement("SELECT NULL FROM k_translations WHERE tx_directory=? AND tx_filename=? AND tx_tag=?");
      PreparedStatement oIns = oCon.prepareStatement("INSERT INTO k_translations(tx_directory,tx_filename,tx_tag,tr_es) VALUES(?,?,?,?)");
      oTags = oTagMap.keySet().iterator();
      while (oTags.hasNext()) {
        Object oTag = oTags.next();
        oSel.setString(1, sDir);
        oSel.setString(2, sFle);
        oSel.setObject(3, oTag, Types.VARCHAR);
        ResultSet oRst = oSel.executeQuery();
        boolean bExists = oRst.next();
        oRst.close();
        if (!bExists) {
          oIns.setString(1, sDir);
          oIns.setString(2, sFle);
          oIns.setObject(3, oTag, Types.VARCHAR);
          oIns.setObject(4, oTag, Types.VARCHAR);
          oIns.executeUpdate();
        }
      } // wend
      oIns.close();
      oSel.close();
    }
  } // writeTagsToDatabase

  // ---------------------------------------------------------------------------

  public void writeTagsFromDirectory(String sSourceBase, String sSourceDir,
                                     String sDrv, String sUrl,
                                     String sUsr, String sPwd,
                                     String sCnf)
    throws IOException,SQLException,ClassNotFoundException,FTPException {
    File oDir = new File(sSourceBase+File.separator+sSourceDir);
    File[] aFiles = oDir.listFiles();
    if (aFiles!=null) {
      final int nFiles = aFiles.length;
      for (int f=0; f<nFiles; f++) {
        File oCurrentOf = aFiles[f];
        String sFileName = oCurrentOf.getName();
        if (oCurrentOf.isFile()) {
          String sFileNameLCase = sFileName.toLowerCase();
          if (isTranslatable(sFileName)) {
            writeTagsToDatabase(extractTagsFromFile(sSourceBase, sSourceDir, sFileName),
                                sDrv, sUrl, sUsr, sPwd,
                                sSourceDir.replace('\\','/'),
                                sFileName, sCnf);
          } // fi
        } else if (oCurrentOf.isDirectory()) {
          writeTagsFromDirectory(sSourceBase, sSourceDir+File.separator+sFileName,
                                 sDrv, sUrl, sUsr, sPwd, sCnf);
        }
      } // next
    } // fi
  } // writeTagsFromDirectory

  // ---------------------------------------------------------------------------

  /**
   * Read a source file and write a translated version for it
   * @param sDrv Name of class for database drive,
   * for example oracle.jdbc.driver.OracleDriver
   * or com.knowgate.http.HttpDataObjsServlet if the database will
   * be accessed throught an HttpDataObjsServlet HTTP bridge
   * @param sUrl Database connection string (like jdbc:oracle:thin:@localhost:1521:XE)
   * or full HTTP URL to HttpDataObjsServlet servlet.
   * @param sUsr Database user name.
   * @param sPwd Database user password.
   * @param sLng Two letter lowercase ISO code of target language.
   * @param sDir
   * @param sFle
   * @param sSourceBase
   * @param sSourceDir
   * @param sSourceFile
   * @param sTargetBase
   * @param sTargetDir
   * @param sTargetFile
   */
  public void translateFile(String sDrv, String sUrl,
                            String sUsr, String sPwd,
                            String sLng, String sDir,
                            String sFle, String sCnf,
                            String sSourceBase, String sSourceDir, String sSourceFile,
                            String sTargetBase, String sTargetDir, String sTargetFile)
    throws SQLException,IOException,FileNotFoundException,
           ClassNotFoundException,FTPException {
    String sSourcePath = sSourceBase + (sSourceDir.length()>0 ? File.separator + sSourceDir : "") + File.separator + sSourceFile;
    String sSource;
    if (oEncodings.containsKey(sSourcePath)) {
      sSource = oHttpFs.readfilestr(sSourcePath, (String) oEncodings.get(sSourcePath));
    } else {
      sSource = oHttpFs.readfilestr(sSourcePath, null);
      oEncodings.put(sSourcePath, oHttpFs.detectEncoding(sSourcePath,"ISO-8859-1"));
    }
    loadTranslationsForFile(sDrv, sUrl, sUsr, sPwd, sLng, sDir, sFle, sCnf);
    final int nTags = aTags.size();
    for (int t=0; t<nTags; t++) {
      sSource = replaceTagWithWord(sSource, (String) aTags.get(t), (String) aWords.get(t));
    }
    if (oHttpFs.exists(sTargetBase+File.separator+sTargetDir+File.separator+sTargetFile)) oHttpFs.delete(sTargetBase+File.separator+sTargetDir+File.separator+sTargetFile);
    oHttpFs.writefilestr(sTargetBase+File.separator+sTargetDir+File.separator+sTargetFile, sSource, (String) oEncodings.get(sSourcePath));
  } // translateFile

  // ---------------------------------------------------------------------------

  /**
   * Read files from a source directory and all its subdirectories
   * and write translated versions for them
   */
  public void translateDirectory(String sDrv, String sUrl,
                                 String sUsr, String sPwd,
                                 String sLng, String sCnf,
                                 String sSourceBase, String sSourceDir,
                                 String sTargetBase, String sTargetDir)
    throws SQLException, IOException, FileNotFoundException,
           ClassNotFoundException, FTPException {
    File oDir = new File(sSourceBase+File.separator+sSourceDir);
    File[] aFiles = oDir.listFiles();
    if (aFiles!=null) {
      try {
        oHttpFs.mkdirs("file://"+sTargetBase+File.separator+sTargetDir);
      } catch (Exception xcpt) { throw new IOException(xcpt.getMessage()); }
      final int nFiles = aFiles.length;
      for (int f=0; f<nFiles; f++) {
        File oCurrentOf = aFiles[f];
        String sFileName = oCurrentOf.getName();
        if (oCurrentOf.isFile()) {
          if (isTranslatable(sFileName)) {
            translateFile(sDrv, sUrl, sUsr, sPwd, sLng, sSourceDir, sFileName, sCnf, sSourceBase, sSourceDir, sFileName, sTargetBase, sTargetDir, sFileName);
          } // fi
        } else if (oCurrentOf.isDirectory() && !oCurrentOf.getName().equalsIgnoreCase(".svn")) {
          translateDirectory(sDrv, sUrl, sUsr, sPwd, sLng, sCnf,
                             sSourceBase, sSourceDir+File.separator+sFileName,
                             sTargetBase, sTargetDir+File.separator+sFileName);
        }
      } // next
    } // fi
  } // translateDirectory

  // ---------------------------------------------------------------------------

  private static String replaceTagWithWord(String sSource, String sFind, String sReplace) {
    final int iSlen = sSource.length()-1;
    final int iFlen = sFind.length();
    int iStartText = 0; // Start of text previous to searched word
    int iStartWord = 0; // Index where searched word is found or -1 if not found
    StringBuffer sTarget = new StringBuffer(sSource.length()+1024);

    // Do while searched word is found and search point is before end of source string
    while (iStartWord!=-1 && iStartWord<iSlen) {
      // Search for word
      iStartWord = sSource.indexOf(sFind, iStartWord);
      if (iStartWord != -1) {
        // If word if found append text before it to target string buffer
        sTarget.append(sSource.substring(iStartText,iStartWord));
        // Append the new word
        sTarget.append(sReplace);
        // Move search point past the end of searched string that was found
        iStartWord += iFlen;
        // Move prior text pointer past the end of searched string that was found
        iStartText = iStartWord;
      } else {
        // If searched string is not found then append the remaining source text
        // from the last prior text pointer
        sTarget.append(sSource.substring(iStartText));
      } // fi
    } // wend
    return sTarget.toString();
  } // replaceTagWithWord

  // ---------------------------------------------------------------------------
  
  /**
   * <p>Command line interface</p>
   * @param args The first parameter must be either extract or translate.
   * The second parameter is the full path to a properties file containing
   * Database connections parameters and source and target directories.
   * @throws FileNotFoundException
   * @throws IOException
   * @throws SQLException
   * @throws FTPException
   * @throws ClassNotFoundException
   * @thorws StringIndexOutOfBoundsException
   */
  public static void main(String args[])
    throws FileNotFoundException, IOException, SQLException,
           ClassNotFoundException, FTPException,StringIndexOutOfBoundsException {

	if (args==null) {	  
	  System.out.println("Usage: com.knowgate.hipergate.translator.Translate [extract|translate] path_to_properties_file");	  
	} else if (args.length<2) {
	  System.out.println("Usage: com.knowgate.hipergate.translator.Translate [extract|translate] path_to_properties_file");	  
	} else if (!args[0].equalsIgnoreCase("extract") && !args[0].equalsIgnoreCase("translate") && !args[0].equalsIgnoreCase("autofill")) {
	  System.out.println("Usage: com.knowgate.hipergate.translator.Translate [extract|translate] path_to_properties_file");	  
	} else {
	  TreeMap oArgsMap = Gadgets.mapCmdLine(Gadgets.join(args," "));
	  
      Properties oProps = new Properties();
      if (oArgsMap.containsKey("cnf")) {
        oProps.load(new FileInputStream((String)oArgsMap.get("cnf")));      
      } else if (args[1].indexOf('=')<0) {
        oProps.load(new FileInputStream(args[1]));            
      }

      String sSourceBase = Gadgets.dechomp((String) (oArgsMap.containsKey("src_dir") ? oArgsMap.get("src_dir") : oProps.getProperty("src_dir")),File.separatorChar);
      String sTargetBase = Gadgets.dechomp((String) (oArgsMap.containsKey("dest_dir") ? oArgsMap.get("dest_dir") : oProps.getProperty("dest_dir")),File.separatorChar);
      String sDrv = (String) (oArgsMap.containsKey("driver") ? oArgsMap.get("driver") : oProps.getProperty("driver"));
      String sUrl = (String) (oArgsMap.containsKey("dburl") ? oArgsMap.get("dburl") : oProps.getProperty("dburl"));
      String sUsr = (String) (oArgsMap.containsKey("dbuser") ? oArgsMap.get("dbuser") : oProps.getProperty("dbuser"));
      String sPwd = (String) (oArgsMap.containsKey("dbpassword") ? oArgsMap.get("dbpassword") : oProps.getProperty("dbpassword"));
      String sCnf = (String) (oArgsMap.containsKey("profile") ? oArgsMap.get("profile") : oProps.getProperty("profile"));
      String sLang = (String) (oArgsMap.containsKey("language") ? oArgsMap.get("language") : oProps.getProperty("language"));
      String sFsr = (String) (oArgsMap.containsKey("fileuser") ? oArgsMap.get("fileuser") : oProps.getProperty("fileuser"));
      String sFwd = (String) (oArgsMap.containsKey("filepassword") ? oArgsMap.get("filepassword") : oProps.getProperty("filepassword"));
      String sFea = (String) (oArgsMap.containsKey("fileserver") ? oArgsMap.get("fileserver") : oProps.getProperty("fileserver"));

      System.out.println("Language is "+sLang);
      System.out.println("Driver is "+sDrv);
      System.out.println("Profile is "+sCnf);
      System.out.println("Source base is "+sSourceBase);
      System.out.println("Target base is "+sTargetBase);
      System.out.println("Database connection string is "+sUrl);
      System.out.println("Database user is "+sUsr);
      if (null!=sFea) System.out.println("Realm is "+sFea);
      if (null!=sFsr) System.out.println("Realm user is "+sFsr);

	  Translate oTrn;
	  if (null==sFsr) {
        oTrn = new Translate();
	  } else if (sFsr.length()==0 || sFsr.equals("anonymous") || !sDrv.equals("com.knowgate.http.HttpDataObjsServlet")) {
        oTrn = new Translate();
      } else {
      	URL oUrl = new URL(sUrl);
        oTrn = new Translate(sFsr, sFwd, sFea, oUrl.getHost());
      }

      File oFile = new File(sSourceBase);
      
      // Verify that source directory is actually a directory
      if (!oFile.isDirectory()) {
        throw new FileNotFoundException(sSourceBase+" is not a directory");
      } else {

        // Get a list of all filles and inmediate subdirectories of source directory
        File[] aFiles = oFile.listFiles();

        if (aFiles!=null) {          
          final int nFiles = aFiles.length;

		  // This portion of code reads a language neutral version from the source
		  // directory structure and writes a translated version to the target directory
          if (args[0].equalsIgnoreCase("translate")) {
            for (int f=0; f<nFiles; f++) {
              // If current File object is a directory then call translateDirectory
              if (aFiles[f].isDirectory() && !aFiles[f].getName().equalsIgnoreCase(".svn")) {
                System.out.println("Processing "+sSourceBase+File.separator+aFiles[f].getName());
                oTrn.translateDirectory(sDrv, sUrl, sUsr, sPwd, sLang,
                                        sCnf, sSourceBase, aFiles[f].getName(),
                                        sTargetBase, aFiles[f].getName());
              }
              // If current File object is a file then check whether or nor its extension
              // is in the list of translatable files
              else if (oTrn.isTranslatable(aFiles[f].getName())) {
                oTrn.translateFile(sDrv, sUrl, sUsr, sPwd, sLang, "",
                                   aFiles[f].getName(), sCnf, sSourceBase,
                                   "", aFiles[f].getName(), sTargetBase, "",
                                   aFiles[f].getName());
              } // fi
            } // next

          }
		  // This portion of code extracts literals from a language neutral directory structure          
          else if (args[0].equalsIgnoreCase("extract")) {

            for (int f=0; f<nFiles; f++) {
              if (aFiles[f].isDirectory()) {
                System.out.println("Processing "+sSourceBase+File.separator+aFiles[f].getName());
                oTrn.writeTagsFromDirectory(sSourceBase, aFiles[f].getName(),
                                            sDrv, sUrl, sUsr, sPwd, sCnf);
              } else if (oTrn.isTranslatable(aFiles[f].getName())) {
                oTrn.writeTagsToDatabase(oTrn.extractTagsFromFile(sSourceBase, "", aFiles[f].getName()),
                                         sDrv, sUrl, sUsr, sPwd, "", aFiles[f].getName(), sCnf);
              } // fi
            } // next
          } else if (args[0].equalsIgnoreCase("autofill")) {
            oTrn.autoFill (sDrv, sUrl, sUsr, sPwd, sCnf);
          } // fi
        } // fi
      } // fi
    } // 
  } // main
}
