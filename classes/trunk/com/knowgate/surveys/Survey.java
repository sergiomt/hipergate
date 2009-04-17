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

import java.io.File;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.UnsupportedEncodingException;

import java.util.LinkedList;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataxslt.db.MicrositeDB;
import com.knowgate.dataxslt.db.PageSetDB;
import com.knowgate.misc.Gadgets;

import org.jibx.runtime.JiBXException;

/**
 * <p>Survey Definition Handler</p>
 * There is one instance of this class and one row at k_pagesets table for each
 * different survey definition.
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Survey extends PageSetDB {

  private static final String MICROSITEGUID = "SURVEYMICROSITEJIXBXMLDEFINITION";

  /**
     * This reference always point to the Microsite which GUID is MICROSITEGUID
    */
  private static MicrositeDB oMSite = null;

  private int nPages;

  //----------------------------------------------------------------------------

  /**
   * Default Constructor
   */
  public Survey() {
    oMSite = new MicrositeDB();
    oMSite.put(DB.gu_microsite, MICROSITEGUID);
    nPages=0;
  }

  //----------------------------------------------------------------------------

  /**
   * Create Survey and load Microsite definition
   * @param oConn Open JDCConnection
   * @throws SQLException
   */
  public Survey(JDCConnection oConn) throws SQLException {
    if (null==oMSite)
      oMSite = new MicrositeDB(oConn, MICROSITEGUID);
    nPages=countPages(oConn);
  }

  //----------------------------------------------------------------------------

  /**
   * Create Survey, load Microsite definition and PageSet definition
   * @param oConn Open JDCConnection
   * @param sPageSetGUID GUID of PageSet for this Survey
   * @throws SQLException
   */
  public Survey(JDCConnection oConn, String sPageSetGUID)
    throws SQLException {
    super(oConn, sPageSetGUID);
    if (null==oMSite)
      oMSite = new MicrositeDB(oConn, MICROSITEGUID);
    nPages=countPages(oConn);
  }

  //----------------------------------------------------------------------------

  /**
   * List GUIDs for pages of this Survey
   * @param oConn Open JDBC database connecyion
   * @return LinkedList with page GUIDs. Pages are ordered by pg_page column.
   * @throws SQLException
   */
  public LinkedList listPages(JDCConnection oConn)
    throws SQLException {
    LinkedList lPages = new LinkedList();
    DBSubset oPages = new DBSubset(DB.k_pageset_pages, DB.gu_page, DB.gu_pageset+"=? ORDER BY "+DB.pg_page,10);
    int iPages = oPages.load(oConn, new Object[]{getStringNull(DB.gu_pageset,null)});
    for (int p=0; p<iPages; p++)
      lPages.add(oPages.get(0,p));
    return lPages;
  } // listPages

  //----------------------------------------------------------------------------

  /**
   * Retrive the GUID for a Page given its number
   * @param oConn JDCConnection Open JDBC database connection
   * @param iPgPage Page number
   * @return GUID of Page or <b>null</b> if no page with that number is found
   * for the PageSet of this Survey.
   * @throws SQLException
   */
  public String getGuidForPage(JDCConnection oConn, int iPgPage)
    throws SQLException {
    String sRetVal;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_page+" FROM "+DB.k_pageset_pages+" WHERE "+DB.gu_pageset+"=? AND "+DB.pg_page+"=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getString(DB.gu_pageset));
    oStmt.setInt(2, iPgPage);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();
    return sRetVal;
  } // getGuidForPage

  //----------------------------------------------------------------------------

  /**
   * Get Survey Page definition by guid
   * @param oConn JDCConnection
   * @param sGuPage Page GUID as at k_pageset_pages.gu_page
   * @param sStorage Location of /storage directory (typically from hipergate.cnf storage property)
   * @param sEnc Character Set Encoding. If <b>null</b> the parser will try to determine it.
   * @return SurveyPage object instance or <b>null</b> if no page with such pg_page was found
   * @throws SQLException
   * @throws FileNotFoundException If file sStorage+k_pageset.path_data+k_pageset.nm_pageset+{dot}xml was not found
   * @throws UnsupportedEncodingException
   * @throws IOException
   * @throws JiBXException
   * @throws NullPointerException
   */
  public SurveyPage getPage(JDCConnection oConn, String sGuPage, String sStorage, String sEnc)
    throws SQLException,FileNotFoundException,UnsupportedEncodingException,
           IOException,JiBXException,NullPointerException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin SurveyPage.getPage([JDCConnection],"+sGuPage+","+sStorage+","+sEnc+")");
      DebugFile.incIdent();
    }
    SurveyPage oJiXBPage=null, oDbmsPage=new SurveyPage(this);
    if (oDbmsPage.load(oConn, new Object[]{sGuPage})) {
      String sJiXBFilePath = sStorage+Gadgets.chomp(getString(DB.path_data), File.separator)+getString(DB.nm_pageset)+String.valueOf(oDbmsPage.getInt(DB.pg_page))+".xml";
      oJiXBPage = SurveyPage.parse(sJiXBFilePath,sEnc);
      oJiXBPage.setSurvey(this);
      oJiXBPage.getItemMap().putAll(oDbmsPage.getItemMap());
      oDbmsPage=null;
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SurveyPage.getPage() : "+ ((oJiXBPage==null) ? "null" : "[Page]"));
    }
    return oJiXBPage;
  } // getPage

  //----------------------------------------------------------------------------

  /**
   * Get Survey Page definition by number
   * @param oConn JDCConnection
   * @param iPgPage Page number [1..n] as at k_pageset_pages.pg_page
   * @param sStorage Location of /storage directory (typically from hipergate.cnf storage property)
   * @param sEnc Character Set Encoding. If <b>null</b> the parser will try to determine it.
   * @return SurveyPage object instance or <b>null</b> if no page with such pg_page was found
   * @throws SQLException
   * @throws FileNotFoundException If file sStorage+k_pageset.path_data+k_pageset.nm_pageset+{dot}xml was not found
   * @throws UnsupportedEncodingException
   * @throws IOException
   * @throws JiBXException
   * @throws NullPointerException
   */
  public SurveyPage getPage(JDCConnection oConn, int iPgPage, String sStorage, String sEnc)
    throws SQLException,FileNotFoundException,UnsupportedEncodingException,
           IOException,JiBXException,NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin SurveyPage.getPage([JDCConnection],"+String.valueOf(iPgPage)+","+sStorage+","+sEnc+")");
      DebugFile.incIdent();
    }

    SurveyPage oPage = null;
    String sJiXBFilePath = sStorage+Gadgets.chomp(getString(DB.path_data), File.separator)+getString(DB.nm_pageset)+String.valueOf(iPgPage)+".xml";

    DBSubset oPages = new DBSubset(DB.k_pageset_pages, DB.gu_page+","+DB.pg_page, DB.gu_pageset+"=?", 10);
    int iPages = oPages.load(oConn, new Object[]{getString(DB.gu_pageset)});

    for (int p=0; p<iPages; p++) {
      if (oPages.getInt(1,p)==iPgPage) {
        oPage = SurveyPage.parse(sJiXBFilePath,sEnc);
        oPage.load(oConn, new Object[]{oPages.getString(0,p)});
        oPage.setSurvey(this);
        break;
      } // fi
    } // next

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SurveyPage.getPage() : "+ ((oPage==null) ? "null" : "[Page]"));
    }
    return oPage;
  } // getPage

  //----------------------------------------------------------------------------

  /**
   * Count number of pages on this Survey
   * @return Page Count
   * @throws SQLException
   */
  public int countPages() {
    return nPages;
  }

  //----------------------------------------------------------------------------

  /**
   * Count number of pages on this Survey
   * @param oConn Open JDBC database connection
   * @return Page Count
   * @throws SQLException
   */
  public int countPages(JDCConnection oConn) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin SurveyPage.countPages([JDCConnection])");
      DebugFile.incIdent();
    }
    if (nPages<=0) {
      PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_pageset_pages+" WHERE "+DB.gu_pageset+"=?",
                                                       ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, getStringNull(DB.gu_pageset,null));
      ResultSet oRSet = oStmt.executeQuery();
      oRSet.next();
      nPages = oRSet.getInt(1);
      oRSet.close();
      oStmt.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SurveyPage.countPages([JDCConnection]) : "+String.valueOf(nPages));
    }
    return nPages;
  } // countPages

  //----------------------------------------------------------------------------
}
