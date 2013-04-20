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

package com.knowgate.hipergate;

import java.util.LinkedList;
import java.util.ListIterator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.ArrayList;
import java.util.WeakHashMap;

import java.rmi.RemoteException;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Gadgets;

import com.knowgate.cache.DistributedCachePeer;

/**
 * <p>Display static tables as HTML elements like &lt;SELECT&gt;.</p>
 * This class is a singleton memory cache for frequently accessed static tables.
 * @version 7.0
 */

public class DBLanguages {

  private static String CNul(String sTr) {
    return DBBind.Functions.ISNULL+"("+sTr+","+DB.tr_country_en+")";
  }

  private static String LNul(String sTr) {
    return DBBind.Functions.ISNULL+"("+sTr+","+DB.tr_lang_en+")";
  }

  /**
   * Array of language identifiers supported by the database
   * @since 4.0
   */
  public static final String[] SupportedLanguages = new String[] {"en","es","fr","de","it","pt","ca","ja","cn","tw","fi","ru","pl","nl","th","ko","sk","cs","uk","no"};
  
  public DBLanguages() {
    oTranslations = null;
    oCountries = null;
    oHTMLCache = new HashMap(83);
    oCountryCacheHtml = new HashMap(387);
	oStateCacheHtml = new WeakHashMap(387);
	oStateCacheText = new WeakHashMap(387);
    bLoaded = false;
    bCountries = false;
  }

  // ----------------------------------------------------------

  /**
   * <p>A comma separated list of column names for translated labels of lookup tables</p>
   * @return String like "tr_es,tr_en,tr_de,tr_it,tr_fr,tr_pt,tr_ca,tr_eu,tr_ja,tr_cn,tr_tw,tr_fi,tr_ru,tr_nl,tr_th,tr_cs,tr_uk,tr_no,tr_sk"
   * @since 4.0
   */
  public static String getLookupTranslationsColumnList() {
  	StringBuffer oColumnList = new StringBuffer(255);
  	final int nCols = SupportedLanguages.length;
  	  oColumnList.append(DB.tr_+SupportedLanguages[0]);
  	for (int c=1; c<nCols; c++) {
  	  oColumnList.append(",");
  	  oColumnList.append(DB.tr_);
  	  oColumnList.append(SupportedLanguages[c]);  	
  	} // next
	return oColumnList.toString();
  } // getLookupTranslationsColumnList
  
  // ----------------------------------------------------------

  /**
   * <p>Get an HTML ComboBox with a list of all languages available at table k_lu_languages.</p>
   * Language names are written in the language passed as parameter.<br>
   * Languages names are sorted.
   * @param oConn Database Connection
   * @param sIdLanguage 2 chraracters code of language for displaying &lt;OPTION&gt; texts.
   * @return <OPTION VALUE="xx">Language 1<OPTION VALUE="yy">Language 2<OPTION ...
   * @throws SQLException
   */
  public String toHTMLSelect(JDCConnection oConn, String sIdLanguage) throws SQLException {
    String sLang = sIdLanguage.toLowerCase();
    String sHTML = null;
    int iTRCol;

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBLanguages.toHTMLSelect([Connection]," + sIdLanguage + ")");
      DebugFile.incIdent();
      }

    if (!bLoaded) {
      if (DebugFile.trace) DebugFile.writeln("  Loading language table");

      Statement oStmt = oConn.createStatement();
      ResultSet oRSet = oStmt.executeQuery("SELECT * FROM "+DB.k_lu_languages+" WHERE 1=0");
      ResultSetMetaData oMDat = oRSet.getMetaData();
      final int nCols = oMDat.getColumnCount();
      StringBuffer oCols = new StringBuffer(1000);
      oCols.append(DB.id_language);
      final String sLCaseTr = DB.tr_.toLowerCase();
      for (int c=1; c<=nCols; c++) {
        String sColNameLCase = oMDat.getColumnName(c).toLowerCase();
        if (sColNameLCase.startsWith(sLCaseTr)) {
          if (sColNameLCase.equalsIgnoreCase(DB.tr_lang_en) || sColNameLCase.equalsIgnoreCase(DB.tr_lang_es))
            oCols.append(","+oMDat.getColumnName(c));
          else
            oCols.append(","+LNul(oMDat.getColumnName(c))+" AS "+oMDat.getColumnName(c));
        } // fi (sColNameLCase startsWith sLCaseTr)
      } // next
      oRSet.close();
      oStmt.close();

      oTranslations = new DBSubset(DB.k_lu_languages, oCols.toString(), null, 60);
      oTranslations.load(oConn);
      bLoaded = true;

      if (DebugFile.trace) DebugFile.writeln("  Languages loaded " + oTranslations.getRowCount());
    } // endif (bLoaded)

    try {
      sHTML = (String) oHTMLCache.get(sLang);
    } catch (NullPointerException e) {
      // Ignore Null Pointer Exception on assigning sHTML
    }

    if (null==sHTML) {
      if (DebugFile.trace) DebugFile.writeln("  Composing HTML <OPTION>");

      sHTML = new String("");
      iTRCol = oTranslations.getColumnPosition(DB.tr_lang_ + sLang);
      if (-1==iTRCol) iTRCol = 0;

      if (DebugFile.trace) DebugFile.writeln("  Translated column position is " + iTRCol + " (zero offset)");

      oTranslations.sortBy(iTRCol);

      for (int iRow=0; iRow<oTranslations.getRowCount(); iRow++) {
        sHTML += "<OPTION VALUE='" + oTranslations.getString(0,iRow).trim() + "'>" + oTranslations.getString(iTRCol,iRow);
      }

      oHTMLCache.put(sLang, sHTML);
    } // endif (null==sHTML)
    else
      if (DebugFile.trace) DebugFile.writeln("  HTML cache hit, no composing performed");

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.toHTMLSelect()");
      }

    return sHTML;
  } // toHTMLSelect()

  // ----------------------------------------------------------

  /**
   * <p>Get an HTML ComboBox with a list of all languages at k_lu_countries.</p>
   * Country names are written in the language passed as parameter.<br>
   * Country names are sorted.
   * @param oConn Database Connection
   * @param sIdLanguage 2 chraracters code of language for displaying &lt;OPTION&gt; texts.
   * @return <OPTION VALUE="xx">Country 1<OPTION VALUE="yy">Country 2<OPTION ...
   * @throws SQLException
   */
  public String getHTMLCountrySelect(JDCConnection oConn, String sIdLanguage)
    throws SQLException {

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBLanguages.getHTMLCountrySelect([Connection]," + sIdLanguage + ")");
      DebugFile.incIdent();
      }

    StringBuffer oHTML = new StringBuffer(8000);

    int iRows;
    int iCols;

    if (!bCountries) {
      Statement oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT * FROM "+DB.k_lu_countries+" WHERE 1=0)");
      ResultSet oRSet = oStmt.executeQuery("SELECT * FROM "+DB.k_lu_countries+" WHERE 1=0");
      ResultSetMetaData oMDat = oRSet.getMetaData();
      final int nCols = oMDat.getColumnCount();
      if (DebugFile.trace) DebugFile.writeln("Column count is " + String.valueOf(nCols));
      StringBuffer oCols = new StringBuffer(1000);
      oCols.append(DB.id_country);
      ArrayList aCols = new ArrayList(nCols);
      aCols.add(DB.id_language);
      final String sLCaseTr = DB.tr_.toLowerCase();
      for (int c=1; c<=nCols; c++) {
        String sColNameLCase = oMDat.getColumnName(c).toLowerCase();
        if (sColNameLCase.startsWith(sLCaseTr)) {
          aCols.add(sColNameLCase);
          if (sColNameLCase.equalsIgnoreCase(DB.tr_country_en) || sColNameLCase.equalsIgnoreCase(DB.tr_country_es))
            oCols.append(","+oMDat.getColumnName(c));
          else
            oCols.append(","+CNul(oMDat.getColumnName(c))+" AS "+oMDat.getColumnName(c));
        } // fi (sColNameLCase startsWith sLCaseTr)
      } // next
      oRSet.close();
      oStmt.close();

      oCountries = new DBSubset(DB.k_lu_countries, oCols.toString(), null, 256);
      iRows = oCountries.load(oConn);
      iCols = oCountries.getColumnCount();

      for (int c=1; c<iCols; c++) {
        oCountries.sortBy(c);
        for (int r=0; r<iRows; r++)
          oHTML.append("<OPTION VALUE=\"" + oCountries.getString(0,r).trim() + "\">" + oCountries.getStringNull(c,r,"") + "</OPTION>");
        String sColName = (String) aCols.get(c);
        String sCntryCd = sColName.substring(sColName.lastIndexOf('_')+1);
        if (DebugFile.trace) DebugFile.writeln("caching "+sCntryCd);
        oCountryCacheHtml.put(sCntryCd, oHTML.toString());
        oHTML.setLength(0);
      }

      bCountries = true;
    }

    String sRetVal;
    if (oCountryCacheHtml.containsKey(sIdLanguage.toLowerCase()))
      sRetVal = (String) oCountryCacheHtml.get(sIdLanguage.toLowerCase());
    else
      sRetVal = "";

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.getHTMLCountrySelect() : "+String.valueOf(sRetVal.length()) + " characters");
      }

    return sRetVal;
  } // getHTMLCountrySelect()

  // ----------------------------------------------------------

  /**
   * <p>Get country translated name given its 2 letter ISO code.</p>
   * @param oConn Database Connection
   * @param sCountryId 2 characters code of country as at k_lu_countries table
   * @param sIdLanguage 2 characters code of desired language for displaying
   * @return Country name for the given language or <b>null</b> if no country with such code is found
   * @throws SQLException
   * @since 4.0
   */
  public String getCountryName(JDCConnection oConn, String sCountryId, String sIdLanguage)
    throws SQLException {
    String sRetVal;
    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBLanguages.getCountryName([Connection]," + sCountryId + "," + sIdLanguage + ")");
      DebugFile.incIdent();
      }
    if (!bCountries) getHTMLCountrySelect(oConn, sIdLanguage.toLowerCase());
	int iColPos = oCountries.getColumnPosition(DB.tr_country_+sIdLanguage.toLowerCase());
	if (iColPos<0) throw new SQLException("Column "+DB.tr_country_+sIdLanguage+" not found at "+DB.k_lu_countries+" table");
	int iFound = oCountries.findi(oCountries.getColumnPosition(DB.id_country), sCountryId);
	if (iFound>=0)
	  sRetVal = oCountries.getStringNull(iColPos,iFound,null);
    else
      sRetVal = null;
    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.getCountryName() : " + sRetVal);
      }
    return sRetVal;
  } // getCountryName

  /** INICIO I2E 2009-12-17 **/
  /**
   * <p>Get language translated name given its 2 letter ISO code.</p>
   * @param oConn Database Connection
   * @param sLanguageId 2 characters code of country as at k_lu_languages table
   * @param sIdLanguage 2 characters code of derired language for displaying
   * @return Language name for the given language or <b>null</b> if no language with such code is found
   * @throws SQLException
   * @since 5.0
   */
  public String getLanguageName(JDCConnection oConn, String sLanguageId, String sIdLanguage) throws SQLException {
    String sRetVal;
    
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.getLanguageName([Connection]," + sLanguageId + "," + sIdLanguage + ")");
      DebugFile.incIdent();
    }
    if (!bLoaded) {
    	toHTMLSelect(oConn, sIdLanguage.toLowerCase());
    }
	int iColPos = oTranslations.getColumnPosition(DB.tr_lang_+sIdLanguage.toLowerCase());
	if (iColPos<0) {
		throw new SQLException("Column "+DB.tr_lang_+sIdLanguage+" not found at "+DB.k_lu_languages+" table");
	}
	int iFound = oTranslations.findi(oTranslations.getColumnPosition(DB.id_language), sLanguageId);
	if (iFound>=0) {
	  sRetVal = oTranslations.getStringNull(iColPos,iFound,null);
	} else {
      sRetVal = null;
	}
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.getCountryName() : " + sRetVal);
    }
    return sRetVal;
  } // getLanguageName
  /** FIN I2E **/
  
  // ----------------------------------------------------------

  /**
   * Get list of thesauri terms for a given Domain and WorkArea
   * @param oConn JDCConnection
   * @param iIdDomain int Domain Unique Identifier
   * @param sGuWorkArea String WorkArea GUID
   * @return <OPTION VALUE="guid1">Term 1<OPTION VALUE="guid2">Term 2<OPTION ...
   * throws SQLException
   * @since 4.0
   */
  public String getHTMLTermSelect(JDCConnection oConn,
  								  int iIdDomain, String sGuWorkArea)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.getHTMLTermSelect([DistributedCachePeer], [JDCConnection], "+String.valueOf(iIdDomain)+","+sGuWorkArea+")");
      DebugFile.incIdent();
    }

      DBSubset oRoots = new DBSubset (DB.k_thesauri_root,
      								  DB.gu_rootterm + "," + DB.tx_term,
      								  DB.id_domain + "=? AND " + DB.gu_workarea + "=? AND (" +
      								  DB.id_scope + "='geozone' OR " + 
      								  DB.id_scope + "='all') ORDER BY 2", 10);
      int iRoots = oRoots.load (oConn, new Object[]{new Integer(iIdDomain), sGuWorkArea});
    
      LinkedList<Term> oTerms = new LinkedList<Term>();
      
      for (int r=0; r<iRoots; r++) {
        Term oRoot = new Term();
        if (oRoot.load(oConn, iIdDomain, oRoots.getString(1,r))) {
      
          oTerms.addLast(oRoot);
          oTerms.addAll (oRoot.getChilds(oConn, Term.SCOPE_ALL));
        } // fi
      } // next (r)

      StringBuffer oTermsBuff = new StringBuffer();
    
      ListIterator<Term> oIter = oTerms.listIterator();
      while (oIter.hasNext()) {
        Term oChld = oIter.next();

        oTermsBuff.append("<OPTION VALUE=\"" + oChld.getString(DB.gu_term) + "\">");
        for (int s=1; s<oChld.level(); s++)
          oTermsBuff.append(" ");
        oTermsBuff.append(oChld.getString(DB.tx_term));
        oTermsBuff.append("</OPTION>");
      } // wend

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.getHTMLTermSelect() : " + oTermsBuff.toString());
    }
    
    return oTermsBuff.toString();
  } // getHTMLTermSelect

  // ----------------------------------------------------------

  /**
   * Get list of thesauri terms for a given Domain WorkArea and Scope
   * @param oConn JDCConnection
   * @param iIdDomain int Domain Unique Identifier
   * @param sGuWorkArea String WorkArea GUID
   * @return <OPTION VALUE="guid1">Term 1<OPTION VALUE="guid2">Term 2<OPTION ...
   * throws SQLException
   * @since 7.0
   */
  public String getHTMLTermSelect(JDCConnection oConn,
  								  int iIdDomain, String sGuWorkArea, String sScope)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.getHTMLTermSelect([DistributedCachePeer], [JDCConnection], "+String.valueOf(iIdDomain)+","+sGuWorkArea+", "+sScope+")");
      DebugFile.incIdent();
    }

      DBSubset oRoots = new DBSubset (DB.k_thesauri_root,
      								  DB.gu_rootterm + "," + DB.tx_term,
      								  DB.id_domain + "=? AND " + DB.gu_workarea + "=? AND " +
      								  DB.id_scope + "=? ORDER BY 2", 10);
      int iRoots = oRoots.load (oConn, new Object[]{new Integer(iIdDomain), sGuWorkArea, sScope});
    
      LinkedList<Term> oTerms = new LinkedList<Term>();
      
      for (int r=0; r<iRoots; r++) {
        Term oRoot = new Term();
        if (oRoot.load(oConn, iIdDomain, oRoots.getString(1,r))) {
      
          oTerms.addLast(oRoot);
          oTerms.addAll (oRoot.getChilds(oConn, Term.SCOPE_ALL));
        } // fi
      } // next (r)

      StringBuffer oTermsBuff = new StringBuffer();
    
      ListIterator<Term> oIter = oTerms.listIterator();
      while (oIter.hasNext()) {
        Term oChld = oIter.next();

        oTermsBuff.append("<OPTION VALUE=\"" + oChld.getString(DB.gu_term) + "\">");
        for (int s=1; s<oChld.level(); s++)
          oTermsBuff.append(" ");
        oTermsBuff.append(oChld.getString(DB.tx_term));
        oTermsBuff.append("</OPTION>");
      } // wend

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.getHTMLTermSelect() : " + oTermsBuff.toString());
    }
    
    return oTermsBuff.toString();
  } // getHTMLTermSelect
  
  // ----------------------------------------------------------

  /**
   * Get list of states for a country in HTML SELECT format
   * @param oConn JDCConnection
   * @param sCountryId 2 letters ISO country code (from k_lu_countries table)
   * @param sIdLanguage 2 letters ISO language code (from k_lu_languages table)
   * @return <OPTION VALUE="xxx">State 1<OPTION VALUE="yyy">State 2<OPTION ...
   * throws SQLException
   * @since 4.0
   */
  public String getHTMLStateSelect(JDCConnection oConn, String sCountryId, String sIdLanguage)
    throws SQLException {
  
    String sHTML = (String) oStateCacheHtml.get(sCountryId+"_"+sIdLanguage);
    
    if (null==sHTML) {
      StringBuffer oHTML = new StringBuffer();
      PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.id_state + "," + DB.tr_ + "state_" + sIdLanguage.toLowerCase() + " FROM " + DB.k_lu_states + " WHERE " + DB.id_country + "=? ORDER BY 2",
      												   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  oStmt.setString(1, sCountryId);
	  ResultSet oRSet = oStmt.executeQuery();
	  while (oRSet.next()) {
	  	String sStCode = oRSet.getString(1);
	  	if (oRSet.wasNull())
	  	  sStCode = "";
	  	else
	  	  sStCode = sStCode.trim();
	    oHTML.append("<OPTION VALUE=\""+sStCode+"\">");
	    oHTML.append(Gadgets.HTMLEncode(oRSet.getString(2)));
	    oHTML.append("</OPTION>");
	  } // wend
      oRSet.close();
      oStmt.close();
      sHTML = oHTML.toString();
      try {
      	oStateCacheHtml.put(sCountryId+"_"+sIdLanguage, sHTML);
      } catch (Exception ignore) {}
    } // fi
	return sHTML;    
  } // getHTMLStateSelect

 // ----------------------------------------------------------

  /**
   * Get list of states for a country in plain text format
   * @param oConn JDCConnection
   * @param sCountryId 2 letters ISO country code (from k_lu_countries table)
   * @param sIdLanguage 2 letters ISO language code (from k_lu_languages table)
   * @return 
   * @since 4.0
   */
  public String getPlainTextStateList(JDCConnection oConn, String sCountryId, String sIdLanguage)
    throws SQLException {
  
    String sHTML = (String) oStateCacheText.get(sCountryId+"_"+sIdLanguage);
    
    if (null==sHTML) {
      StringBuffer oHTML = new StringBuffer();
      PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.id_state + "," + DB.tr_ + "state_" + sIdLanguage.toLowerCase() + " FROM " + DB.k_lu_states + " WHERE " + DB.id_country + "=? ORDER BY 2",
      												   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  oStmt.setString(1, sCountryId);
	  ResultSet oRSet = oStmt.executeQuery();
	  while (oRSet.next()) {
	    if (oHTML.length()>0) oHTML.append('\n'); 
	    oHTML.append(oRSet.getString(1).trim());
	    oHTML.append(',');
	    oHTML.append(oRSet.getString(2));
	  } // wend
      oRSet.close();
      oStmt.close();
      sHTML = oHTML.toString();
      try {
      	oStateCacheText.put(sCountryId+"_"+sIdLanguage, sHTML);
      } catch (Exception ignore) {}
    } // fi
	return sHTML;    
  } // getPlainTextStateList

  // ----------------------------------------------------------

  /**
   * <p>Get an HTML ComboBox options with translated labels for a standard hipergate lookup table.</p>
   * This method goes directly to database without any intermediate cache or temporary storage object.
   * @param oConn Database connection
   * @param sTableName Lookup table name
   * @param sOwnerId WorkArea for filtering results
   * @param sSectionId Name of section (field) to retrieve
   * @param sDefaultValue Default selected value, if null then there is no default
   * @param sLanguage 2 chracters language code for ComboBox texts (see k_lu_languages table)
   * @return <OPTION VALUE="...">...</OPTION><OPTION VALUE="...">...</OPTION>...
   * @throws SQLException
   * @since 3.0
   */
  public static String getHTMLSelectLookUp(JDCConnection oConn, String sTableName,
                                           String sOwnerId, String sSectionId,
                                           String sLanguage, String sDefaultValue)
    throws SQLException {

    StringBuffer oBuff = new StringBuffer(2048);
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sValue;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.getHTMLSelectLookUp([Connection], " + sTableName + "," + sOwnerId + "," + sSectionId + "," + sLanguage + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.vl_lookup + "," + DB.tr_ + sLanguage.toLowerCase() + " FROM " + sTableName + " WHERE " + DB.gu_owner + "='" + sOwnerId + "' AND " + DB.id_section + "='" + sSectionId + "' ORDER BY 2)");
    }

    oStmt = oConn.prepareStatement("SELECT " + DB.vl_lookup + "," + DB.tr_ + sLanguage.toLowerCase() + " FROM " + sTableName + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=? ORDER BY 2", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    try {
      if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) {
        oStmt.setFetchSize(100);
      }
    } catch (SQLException sqle) {
      if (DebugFile.trace) DebugFile.writeln(sqle.getMessage());
    }

    oStmt.setString(1, sOwnerId);
    oStmt.setString(2, sSectionId);
    oRSet = oStmt.executeQuery();
    if (null==sDefaultValue) {
      while (oRSet.next()) {
        oBuff.append("<OPTION VALUE=\"");
        sValue = oRSet.getString(1);
        if (!oRSet.wasNull()) oBuff.append(sValue);
        oBuff.append("\">");
        sValue = oRSet.getString(2);
        if (!oRSet.wasNull()) oBuff.append(sValue);
        oBuff.append("</OPTION>");
      } // wend()
    } else {
      while (oRSet.next()) {
        oBuff.append("<OPTION VALUE=\"");
        sValue = oRSet.getString(1);
        if (!oRSet.wasNull()) oBuff.append(sValue);
        oBuff.append("\"");
        if (sDefaultValue.equals(sValue)) oBuff.append(" SELECTED=\"selected\"");
          oBuff.append(">");
        sValue = oRSet.getString(2);
        if (!oRSet.wasNull()) oBuff.append(sValue);
        oBuff.append("</OPTION>");
      } // wend()
    }
    oRSet.close();
    oStmt.close();

    oRSet = null;
    oStmt = null;

    if (DebugFile.trace) {
      DebugFile.writeln("End DBLanguages.getHTMLSelectLookUp() : " + String.valueOf(oBuff.length()));
      DebugFile.decIdent();
    }

    return oBuff.toString();
  } // getHTMLSelectLookUp()

  // ----------------------------------------------------------

  /**
   * <p>Get an HTML ComboBox options with translated labels for a standard hipergate lookup table.</p>
   * This method goes directly to database without any intermediate cache or temporary storage object.
   * @param oConn Database connection
   * @param sTableName Lookup table name
   * @param sOwnerId WorkArea for filtering results
   * @param sSectionId Name of section (field) to retrieve
   * @param sLanguage 2 chracters language code for ComboBox texts (see k_lu_languages table)
   * @return <OPTION VALUE="...">...</OPTION><OPTION VALUE="...">...</OPTION>...
   * @throws SQLException
   */
  public static String getHTMLSelectLookUp(JDCConnection oConn, String sTableName,
                                           String sOwnerId, String sSectionId,
                                           String sLanguage) throws SQLException {
    return getHTMLSelectLookUp(oConn, sTableName, sOwnerId, sSectionId, sLanguage, null);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get an HTML ComboBox options with translated labels for a standard
   * hipergate lookup table.</p>
   * This method first checks the DistributedCachePeer for a matching ResultSet,
   * then goes to database if ResultSet is not cached. Result is placed at cache
   * as a DBSubset object with key sTableName.sSectionId[sOwnerId].
   * @param oCache Local cache peer
   * @param oConn Database connection
   * @param sTableName Lookup table name
   * @param sOwnerId WorkArea for filtering results
   * @param sSectionId Name of section (field) to retrieve
   * @param sLanguage 2 chracters language code for ComboBox texts (see k_lu_languages table)
   * @param iOrderBy Column for ordering results: 0=Internal Lookup Value, 1=Displayed Label, 2=Lookup Ordinal
   * @return <OPTION VALUE="...">...</OPTION><OPTION VALUE="...">...</OPTION>...
   * @throws SQLException
   * @see com.knowgate.cache.DistributedCachePeer
   */

  public static String getHTMLSelectLookUp(DistributedCachePeer oCache, JDCConnection oConn,
                                           String sTableName, String sOwnerId,
                                           String sSectionId, String sLanguage,
                                           int iOrderBy)
    throws RemoteException,SQLException {

    StringBuffer oBuff = new StringBuffer(2048);
    DBSubset oDBSS;
    int iDBSS;
    Object aFilter[] = { sOwnerId, sSectionId };

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.getHTMLSelectLookUp([DistributedCacheClient], [Connection], " + sTableName + "," + sOwnerId + "," + sSectionId + "," + sLanguage + ")");
      DebugFile.incIdent();
    }

    oDBSS = oCache.getDBSubset(sTableName + "." + sSectionId + "[" + sOwnerId + "]");

    if (null==oDBSS) {
      if (oConn!=null) {
        oDBSS = new DBSubset(sTableName,
                             DB.vl_lookup + "," + DB.tr_ + sLanguage.toLowerCase() + "," + DB.pg_lookup,
                             DB.gu_owner + "=? AND " + DB.id_section + "=? ORDER BY "+String.valueOf(iOrderBy),
                             100);
        iDBSS = oDBSS.load(oConn, aFilter);
        oCache.putDBSubset(sTableName, sTableName + "." + sSectionId + "[" + sOwnerId + "]", oDBSS);
      } else {
        iDBSS = 0;
      }
    } // fi(oDBSS)
    else
      iDBSS = oDBSS.getRowCount();

    for (int r=0; r<iDBSS; r++) {

      oBuff.append("<OPTION VALUE=\"");
      oBuff.append(oDBSS.getStringNull(0,r,""));
      oBuff.append("\">");
      oBuff.append(oDBSS.getStringNull(1,r,""));
      oBuff.append("</OPTION>");
    } // next()

    if (DebugFile.trace) {
      DebugFile.writeln("End DBLanguages.getHTMLSelectLookUp() : " + String.valueOf(oBuff.length()));
      DebugFile.decIdent();
    }

    return oBuff.toString();
  } // getHTMLSelectLookUp()

  // ----------------------------------------------------------

  /**
   * <p>Get an HTML ComboBox options with translated labels for a standard
   * hipergate lookup table.</p>
   * This method first checks the DistributedCachePeer for a matching ResultSet,
   * then goes to database if ResultSet is not cached. Result is placed at cache
   * as a DBSubset object with key sTableName.sSectionId[sOwnerId].
   * @param oCache Local cache peer
   * @param oConn Database connection
   * @param sTableName Lookup table name
   * @param sOwnerId WorkArea for filtering results
   * @param sSectionId Name of section (field) to retrieve
   * @param sLanguage 2 chracters language code for ComboBox texts (see k_lu_languages table)
   * @return <OPTION VALUE="...">...</OPTION><OPTION VALUE="...">...</OPTION>...
   * @throws SQLException
   * @see com.knowgate.cache.DistributedCachePeer
   */

  public static String getHTMLSelectLookUp(DistributedCachePeer oCache, JDCConnection oConn,
                                           String sTableName, String sOwnerId,
                                           String sSectionId, String sLanguage)
    throws RemoteException,SQLException {
    return getHTMLSelectLookUp(oCache, oConn, sTableName, sOwnerId, sSectionId, sLanguage, 2);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get a translated label for a lookup value.</p>
   * @param oConn Database Connection
   * @param sTableName Lookup table name
   * @param sOwnerId WorkArea GUID
   * @param sSectionId Section name (field)
   * @param sLanguage Language code for retrieved label
   * @param sLookupId Lookup value to find
   * @return Translated label of lookup value or <b>null</b> if label for such language was not found
   * @throws SQLException
   */
  public static String getLookUpTranslation(Connection oConn, String sTableName, String sOwnerId, String sSectionId, String sLanguage, String sLookupId) throws SQLException {

    PreparedStatement oStmt;
    ResultSet oRSet;
    String sValue;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.getLookUpTranslation([Connection]," + sTableName + "," + sOwnerId + "," + sSectionId + "," + sLanguage + "," + sLookupId);
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.tr_ + sLanguage + " FROM " + sTableName + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=? AND " + DB.vl_lookup + "=?)");
    }

    oStmt = oConn.prepareStatement("SELECT " + DB.tr_ + sLanguage + " FROM " + sTableName + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=? AND " + DB.vl_lookup + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sOwnerId);
    oStmt.setString(2, sSectionId);
    oStmt.setString(3, sLookupId);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sValue = oRSet.getString(1);
    else
      sValue = null;
    oRSet.close();
    oStmt.close();

    oRSet = null;
    oStmt = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.getLookUpTranslation() : " + (sValue!=null ? sValue : "null"));
    }

    return sValue;
  } // getLookUpTranslation

  // ----------------------------------------------------------

  /**
   * <p>Get a Map of lookup values and their corresponding translated labels for a language.</p>
   * This method is to be used when a listing routine has to lookup several values
   * at a base table for their translated lookup labels. Instead of joining the base table and
   * the lookup table, a memory map may be fetched first and then the painting routine translates
   * each value into its labels without any database access.
   * @param oConn Database connection
   * @param sTableName Lookup table name
   * @param sOwnerId WorkArea GUID
   * @param sSectionId Section name (field)
   * @param sLanguage Language code for retrieved labels
   * @return A Map associating looukp values (as keys) with values for translated labels into the given language.
   * @throws SQLException
   */
  public static HashMap getLookUpMap(Connection oConn, String sTableName, String sOwnerId, String sSectionId, String sLanguage) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.getLookUpMap([Connection], " + sTableName + "," + sOwnerId + "," + sSectionId + "," + sLanguage + ")");
      DebugFile.incIdent();
    }

    HashMap oMap = new HashMap();

    String sSQL = "SELECT " + DB.vl_lookup + "," + DB.tr_ + sLanguage + " FROM " + sTableName + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=?";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.vl_lookup + "," + DB.tr_ + sLanguage + " FROM " + sTableName + " WHERE " + DB.gu_owner + "='" + sOwnerId + "' AND " + DB.id_section + "='" + sSectionId + "')");

    PreparedStatement oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sOwnerId);
    oStmt.setString(2, sSectionId);
    ResultSet oRSet = oStmt.executeQuery();

    while (oRSet.next()) {
      oMap.put(oRSet.getObject(1), oRSet.getObject(2));
    } // wend

    oRSet.close();
    oStmt.close();

    oRSet = null;
    oStmt = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.getLookUpMap() : " + String.valueOf(oMap.size()));
    }

    return oMap;
  } // getLookUpMap()
  
  /** INICIO I2E 2009-12-17 **/
  /**
   * <p>Get a Map of language lookup talbe values and their corresponding translated labels for a language.</p>
   * This method is to be used when a listing routine has to lookup several values
   * at language lookup table for their translated lookup labels. Instead of joining the base table and
   * the language lookup table, a memory map may be fetched first and then the painting routine translates
   * each value into its labels without any database access.
   * @param oConn Database connection
   * @param sLanguage Language code for retrieved labels
   * @return A Map associating looukp values (as keys) with values for translated labels into the given language.
   * @throws SQLException
   */
  public static HashMap getLanguageLookUpMap(Connection oConn, String sLanguage) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.getLanguageLookUpMap([Connection], " + sLanguage + ")");
      DebugFile.incIdent();
    }

    HashMap oMap = new HashMap();

    String sSQL = "SELECT " + DB.id_language + "," + DB.tr_lang_ + sLanguage + " FROM " + DB.k_lu_languages;

    if (DebugFile.trace){
    	DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.id_language + "," + DB.tr_lang_ + sLanguage + " FROM " + DB.k_lu_languages);
    }

    PreparedStatement oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    ResultSet oRSet = oStmt.executeQuery();

    while (oRSet.next()) {
      oMap.put(oRSet.getObject(1), oRSet.getObject(2));
    } // wend

    oRSet.close();
    oStmt.close();

    oRSet = null;
    oStmt = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.getLanguageLookUpMap() : " + String.valueOf(oMap.size()));
    }

    return oMap;
  } // getLanguageLookUpMap()
  /** FIN **/

  // ----------------------------------------------------------

  /**
   * Find value of next unused lookup index for a given table section
   * @param oConn Connection Opened JDBC database connection
   * @param sLookupTableName String Look up table name (ex. k_companies_lookup)
   * @param sGuOwner String GUID of WorkArea to which the new lookup value will belong
   * @param sIdSection String Name of section (usually corresponding column name at base table)
   * @return int Next unused lookup index (pg_lookup column at sLookupTableName)
   * @since 3.0
   */
  public static int nextLookuUpProgressive(Connection oConn, String sLookupTableName,
                                           String sGuOwner, String sIdSection)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.nextLookuUpProgressive([Connection], " + sLookupTableName + "," + sGuOwner + "," + sIdSection + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT MAX(" + DB.pg_lookup + ")+1 FROM " + sLookupTableName + " WHERE " + DB.gu_owner + "='"+sGuOwner+"' AND " + DB.id_section + "="+sIdSection+")");
    }

    int iNextPg;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT MAX(" + DB.pg_lookup + ")+1 FROM " + sLookupTableName + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=?",
                                                     ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sGuOwner);
    oStmt.setString(2, sIdSection);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      Object oNextPg = oRSet.getObject(1);
      if (oRSet.wasNull())
        iNextPg = 1;
      else
        iNextPg = Integer.parseInt(oNextPg.toString());
    }
    else
      iNextPg = 1;
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.nextProgressive() : " + String.valueOf(iNextPg));
    }

    return iNextPg;
  } // nextProgressive

  // ----------------------------------------------------------

  /**
   * <p>Add a lookup value for a given section</p>
   * This methods checks whether the lookup value exists and, if not, then inserts it.<br>
   * If lookup value already exists then it is not updated.
   * @param oConn JDCConnection
   * @param sLookupTableName String Name of Lookup Table
   * @param sGuOwner String GUID of Owner WorkArea
   * @param sIdSection String Lookup Section name
   * @param sVlLookUp String Lookup Internal Value
   * @param oTranslatMap HashMap with one entry for each language.
   * Language codes must be those from id_language column of k_lu_languages table.
   * @return boolean <b>true</b> if value was added, <b>false</b> if it already existed
   * @throws SQLException
   * @since 3.0
   */

  public static boolean addLookup (Connection oConn, String sLookupTableName,
                                   String sGuOwner, String sIdSection,
                                   String sVlLookUp, HashMap<String,String> oTranslatMap)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.addLookup([Connection], " + sLookupTableName + "," + sGuOwner + "," + sIdSection + "," + sVlLookUp + ", [HashMap])");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM "+sLookupTableName+" WHERE "+DB.gu_owner+"='"+sGuOwner+"' AND "+DB.id_section+"='"+sIdSection+"' AND "+DB.vl_lookup+"='"+sVlLookUp+"')");
    }
                                               	
    ResultSet oRSet;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM "+sLookupTableName+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"=? AND "+DB.vl_lookup+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sGuOwner);
    oStmt.setString(2, sIdSection);
    oStmt.setString(3, sVlLookUp);
    oRSet = oStmt.executeQuery();
    boolean bAlreadyExists = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (!bAlreadyExists) {
      if (DebugFile.trace) DebugFile.writeln("lookup does not already exists");
      
      HashMap<String,String> oTrColumnMap = new HashMap<String,String>(197);
      oStmt = oConn.prepareStatement("SELECT * FROM "+sLookupTableName+" WHERE 1=0");
      oRSet = oStmt.executeQuery();
      ResultSetMetaData oMDat = oRSet.getMetaData();
      for (int c=1; c<oMDat.getColumnCount(); c++) {
      	oTrColumnMap.put(oMDat.getColumnName(c).toLowerCase(),oMDat.getColumnName(c).toLowerCase());
      }
      oRSet.close();
      oStmt.close();

      int iQuestMarks = 1;
      String sSQL = "INSERT INTO "+sLookupTableName+"("+DB.gu_owner+","+DB.id_section+","+DB.pg_lookup+","+DB.vl_lookup;
      Iterator oKeys = oTranslatMap.keySet().iterator();
      while (oKeys.hasNext()) {
      	String sColName = DB.tr_+oKeys.next();
      	if (oTrColumnMap.containsKey(sColName.toLowerCase())) {
          sSQL += ","+sColName;
          iQuestMarks++;
      	}
      } // wend

      sSQL += ") VALUES (?,?,?,?";
      for (int q=1; q<iQuestMarks; q++) sSQL += ",?";
      sSQL += ")";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
      oStmt = oConn.prepareStatement(sSQL);
      int iParam = 1;
      oStmt.setString(iParam++, sGuOwner);
      oStmt.setString(iParam++, sIdSection);
      oStmt.setInt(iParam++, nextLookuUpProgressive(oConn, sLookupTableName, sGuOwner, sIdSection));
      oStmt.setString(iParam++, sVlLookUp);
      oKeys = oTranslatMap.keySet().iterator();
      while (oKeys.hasNext()) {
      	String sColLang = (String) oKeys.next();
      	if (oTrColumnMap.containsKey((DB.tr_+sColLang).toLowerCase()))
          oStmt.setObject(iParam++, oTranslatMap.get(sColLang), Types.VARCHAR);
      } // wend
      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");
      oStmt.executeUpdate();
      oStmt.close();
    } // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.addLookup() : " + String.valueOf(!bAlreadyExists));
    }

    return !bAlreadyExists;
  } // addLookup

  // ----------------------------------------------------------

  /**
   * <p>Add a lookup value for a given section</p>
   * This methods checks whether the lookup value exists and, if not, then inserts it.<br>
   * If lookup value already exists then it is not updated.
   * @param oConn JDCConnection
   * @param sLookupTableName String Name of Lookup Table
   * @param sGuOwner String GUID of Owner WorkArea
   * @param sIdSection String Lookup Section name
   * @param sVlLookUp String Lookup Internal Value
   * @param oTranslatMap HashMap with one entry for each language.
   * Language codes must be those from id_language column of k_lu_languages table.
   * @return boolean <b>true</b> if value was added, <b>false</b> if it already existed
   * @throws SQLException
   * @since 7.0
   */

  public static boolean addLookup (Connection oConn, String sLookupTableName,
                                   String sGuOwner, String sIdSection, boolean bActive,
                                   String sVlLookUp, String sTpLookUp, String sTxComments,
                                   HashMap<String,String> oTranslatMap)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.addLookup([Connection], " + sLookupTableName + "," + sGuOwner + "," + sIdSection + "," + sVlLookUp + ", [HashMap])");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM "+sLookupTableName+" WHERE "+DB.gu_owner+"='"+sGuOwner+"' AND "+DB.id_section+"='"+sIdSection+"' AND "+DB.vl_lookup+"='"+sVlLookUp+"')");
    }
                                               	
    ResultSet oRSet;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM "+sLookupTableName+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"=? AND "+DB.vl_lookup+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sGuOwner);
    oStmt.setString(2, sIdSection);
    oStmt.setString(3, sVlLookUp);
    oRSet = oStmt.executeQuery();
    boolean bAlreadyExists = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (!bAlreadyExists) {
      if (DebugFile.trace) DebugFile.writeln("lookup does not already exists");
      
      HashMap<String,String> oTrColumnMap = new HashMap<String,String>(197);
      oStmt = oConn.prepareStatement("SELECT * FROM "+sLookupTableName+" WHERE 1=0");
      oRSet = oStmt.executeQuery();
      ResultSetMetaData oMDat = oRSet.getMetaData();
      for (int c=1; c<oMDat.getColumnCount(); c++) {
      	oTrColumnMap.put(oMDat.getColumnName(c).toLowerCase(),oMDat.getColumnName(c).toLowerCase());
      }
      oRSet.close();
      oStmt.close();

      int iQuestMarks = 1;
      String sSQL = "INSERT INTO "+sLookupTableName+"("+DB.gu_owner+","+DB.id_section+","+DB.pg_lookup+","+DB.vl_lookup+","+DB.bo_active+","+DB.tp_lookup+","+DB.tx_comments;
      Iterator oKeys = oTranslatMap.keySet().iterator();
      while (oKeys.hasNext()) {
      	String sColName = DB.tr_+oKeys.next();
      	if (oTrColumnMap.containsKey(sColName.toLowerCase())) {
          sSQL += ","+sColName;
          iQuestMarks++;
      	}
      } // wend

      sSQL += ") VALUES (?,?,?,?,?,?,?";
      for (int q=1; q<iQuestMarks; q++) sSQL += ",?";
      sSQL += ")";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
      oStmt = oConn.prepareStatement(sSQL);
      int iParam = 1;
      oStmt.setString(iParam++, sGuOwner);
      oStmt.setString(iParam++, sIdSection);
      oStmt.setInt(iParam++, nextLookuUpProgressive(oConn, sLookupTableName, sGuOwner, sIdSection));
      oStmt.setString(iParam++, sVlLookUp);
      oStmt.setShort(iParam++, (short) (bActive ? 1 : 0));
      if (null==sTpLookUp)
        oStmt.setNull(iParam++, Types.VARCHAR);
      else
        oStmt.setString(iParam++, sTpLookUp);
      if (null==sTxComments)
        oStmt.setNull(iParam++, Types.VARCHAR);
      else
        oStmt.setString(iParam++, sTxComments);
      oKeys = oTranslatMap.keySet().iterator();
      while (oKeys.hasNext()) {
      	String sColLang = (String) oKeys.next();
      	if (oTrColumnMap.containsKey((DB.tr_+sColLang).toLowerCase()))
          oStmt.setObject(iParam++, oTranslatMap.get(sColLang), Types.VARCHAR);
      } // wend
      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");
      oStmt.executeUpdate();
      oStmt.close();
    } // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.addLookup() : " + String.valueOf(!bAlreadyExists));
    }

    return !bAlreadyExists;
  } // addLookup

  // ----------------------------------------------------------

  /**
   * <p>Add or update a lookup value for a given section</p>
   * This methods checks whether the lookup value exists and, if not, then inserts it.<br>
   * If lookup value already exists then it is updated.
   * @param oConn JDCConnection
   * @param sLookupTableName String Name of Lookup Table
   * @param sGuOwner String GUID of Owner WorkArea
   * @param sIdSection String Lookup Section name
   * @param sVlLookUp String Lookup Internal Value
   * @param oTranslations HashMap with one entry for each language.
   * Language codes must be those from id_language column of k_lu_languages table.
   * @return boolean <b>true</b> if value was added, <b>false</b> if it already existed
   * @throws SQLException
   * @since 3.0
   */

  public static void storeLookup (Connection oConn, String sLookupTableName,
                                  String sGuOwner, String sIdSection,
                                  String sVlLookUp, HashMap oTranslations)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.storeLookup([Connection], " + sLookupTableName + "," + sGuOwner + "," + sIdSection + "," + sVlLookUp + ", [HashMap])");
      DebugFile.incIdent();
    }

    if (!addLookup(oConn, sLookupTableName, sGuOwner, sIdSection, sVlLookUp, oTranslations)) {
      String sSQL = "";
      Iterator oKeys = oTranslations.keySet().iterator();
      while (oKeys.hasNext()) {
        sSQL += (sSQL.length()>0 ? "," : "")+DB.tr_+oKeys.next()+"=?";
      } // wend
      sSQL += " WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"=? AND "+DB.vl_lookup+"=?";
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(UPDATE "+sLookupTableName+" SET "+sSQL+")");
      PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+sLookupTableName+" SET "+sSQL);
      oKeys = oTranslations.keySet().iterator();
      int iParam = 1;
      while (oKeys.hasNext()) {
        oStmt.setObject(iParam++, oTranslations.get(oKeys.next()), Types.VARCHAR);
      } // wend
      oStmt.setString(iParam++, sGuOwner);
      oStmt.setString(iParam++, sIdSection);
      oStmt.setString(iParam++, sVlLookUp);
      oStmt.executeUpdate();
      oStmt.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.storeLookup()");
    }
  } // storeLookup

  // ----------------------------------------------------------

  /**
   * <p>Add or update a lookup value for a given section</p>
   * This methods checks whether the lookup value exists and, if not, then inserts it.<br>
   * If lookup value already exists then it is updated.
   * @param oConn JDCConnection
   * @param sLookupTableName String Name of Lookup Table
   * @param sGuOwner String GUID of Owner WorkArea
   * @param sIdSection String Lookup Section name
   * @param sVlLookUp String Lookup Internal Value
   * @param oTranslations HashMap with one entry for each language.
   * Language codes must be those from id_language column of k_lu_languages table.
   * @return boolean <b>true</b> if value was added, <b>false</b> if it already existed
   * @throws SQLException
   * @since 7.0
   */

  public static void storeLookup (Connection oConn, String sLookupTableName,
                                  String sGuOwner, String sIdSection, boolean bActive,
                                  String sVlLookUp, String sTpLookUp, String sTxComments,
                                  HashMap oTranslations)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.storeLookup([Connection], " + sLookupTableName + "," + sGuOwner + "," + sIdSection + "," + sVlLookUp + ", [HashMap])");
      DebugFile.incIdent();
    }

    if (!addLookup(oConn, sLookupTableName, sGuOwner, sIdSection, bActive, sVlLookUp, sTpLookUp, sTxComments, oTranslations)) {
      String sSQL = DB.bo_active+"=?,"+DB.tp_lookup+"=?,"+DB.tx_comments+"=?";
      Iterator oKeys = oTranslations.keySet().iterator();
      while (oKeys.hasNext()) {
        sSQL += ","+DB.tr_+oKeys.next()+"=?";
      } // wend
      sSQL += " WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"=? AND "+DB.vl_lookup+"=?";
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(UPDATE "+sLookupTableName+" SET "+sSQL+")");
      PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+sLookupTableName+" SET "+sSQL);
      oKeys = oTranslations.keySet().iterator();
      int iParam = 1;
      oStmt.setShort(iParam++, (short) (bActive ? 1 : 0));
      if (null==sTpLookUp)
        oStmt.setNull(iParam++, Types.VARCHAR);
      else if (sTpLookUp.length()==0)
        oStmt.setNull(iParam++, Types.VARCHAR);
      else
        oStmt.setString(iParam++, sTpLookUp);
      if (null==sTxComments)
          oStmt.setNull(iParam++, Types.VARCHAR);
        else if (sTxComments.length()==0)
          oStmt.setNull(iParam++, Types.VARCHAR);
        else
          oStmt.setString(iParam++, sTxComments);
      while (oKeys.hasNext()) {
        oStmt.setObject(iParam++, oTranslations.get(oKeys.next()), Types.VARCHAR);
      } // wend
      oStmt.setString(iParam++, sGuOwner);
      oStmt.setString(iParam++, sIdSection);
      oStmt.setString(iParam++, sVlLookUp);
      oStmt.executeUpdate();
      oStmt.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.storeLookup()");
    }
  } // storeLookup

  // ----------------------------------------------------------

  /**
   * Delete lookup value
   * @param oConn Connection
   * @param sLookupTableName String Name of Lookup Table
   * @param sBaseTable String Base table which column named like sIdSection will be set to null
   * @param sGuOwner String GUID of Owner WorkArea
   * @param sIdSection String Lookup Section name
   * @param sVlLookUp String Lookup Internal Value
   * @throws SQLException
   * @since 3.0
   */
  public static void deleteLookup (Connection oConn, String sLookupTableName,
                                   String sBaseTable, String sGuOwner,
                                   String sIdSection, String sVlLookUp)
    throws SQLException {
    PreparedStatement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.deleteLookup([Connection], " + sLookupTableName + "," + sBaseTable + "," + sGuOwner + "," + sIdSection + "," + sVlLookUp + ")");
      DebugFile.incIdent();
    }

    if (null!=sBaseTable) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(UPDATE "+sBaseTable+" SET "+sIdSection+"=NULL "+"WHERE "+sIdSection+"='"+sIdSection+"' AND "+DB.gu_workarea+"='"+sGuOwner+"')");
      oStmt = oConn.prepareStatement("UPDATE "+sBaseTable+" SET "+sIdSection+"=NULL "+"WHERE "+sIdSection+"=? AND "+DB.gu_workarea+"=?");
      oStmt.setString(1, sIdSection);
      oStmt.setString(2, sGuOwner);
      oStmt.executeUpdate();
      oStmt.close();
    }
    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(DELETE FROM "+sLookupTableName+" WHERE "+DB.gu_owner+"='"+sGuOwner+"' AND "+DB.id_section+"='"+sIdSection+"' AND "+DB.vl_lookup+"='"+sVlLookUp+"')");
    oStmt = oConn.prepareStatement("DELETE FROM "+sLookupTableName+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"=? AND "+DB.vl_lookup+"=?");
    oStmt.setString(1, sGuOwner);
    oStmt.setString(2, sIdSection);
    oStmt.setString(3, sVlLookUp);
    oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.deleteLookup()");
    }
  } // deleteLookup

  // ----------------------------------------------------------

  /**
   * Delete lookup value
   * @param oConn Connection
   * @param sLookupTableName String Name of Lookup Table
   * @param sBaseTable String Base table which column named like sIdSection will be set to null
   * @param sGuOwner String GUID of Owner WorkArea
   * @param sIdSection String Lookup Section name
   * @param iPgLookUp int Lookup Ordinal Value
   * @throws SQLException
   * @since 3.0
   */
  public static void deleteLookup (Connection oConn, String sLookupTableName,
                                   String sBaseTable, String sGuOwner,
                                   String sIdSection, int iPgLookUp)
    throws SQLException {
    PreparedStatement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBLanguages.deleteLookup([Connection], " + sLookupTableName + "," + sBaseTable + "," + sGuOwner + "," + sIdSection + "," + String.valueOf(iPgLookUp) + ")");
      DebugFile.incIdent();
    }

    if (null!=sBaseTable) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(UPDATE "+sBaseTable+" SET "+sIdSection+"=NULL "+"WHERE "+sIdSection+"='"+sIdSection+"' AND "+DB.gu_workarea+"='"+sGuOwner+"'");
      oStmt = oConn.prepareStatement("UPDATE "+sBaseTable+" SET "+sIdSection+"=NULL "+"WHERE "+sIdSection+"=? AND "+DB.gu_workarea+"=?");
      oStmt.setString(1, sIdSection);
      oStmt.setString(2, sGuOwner);
      oStmt.executeUpdate();
      oStmt.close();
    }
    if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM "+sLookupTableName+" WHERE "+DB.gu_owner+"='"+sGuOwner+"' AND "+DB.id_section+"="+sIdSection+" AND "+DB.pg_lookup+"="+iPgLookUp+"");
    oStmt = oConn.prepareStatement("DELETE FROM "+sLookupTableName+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"=? AND "+DB.pg_lookup+"=?");
    oStmt.setString(1, sGuOwner);
    oStmt.setString(2, sIdSection);
    oStmt.setInt(3, iPgLookUp);
    oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBLanguages.deleteLookup()");
    }
  } // deleteLookup

  // ----------------------------------------------------------

  private DBSubset oTranslations;
  private DBSubset oCountries;
  private HashMap oHTMLCache;
  private HashMap oCountryCacheHtml;
  private WeakHashMap oStateCacheHtml;
  private WeakHashMap oStateCacheText;
  private boolean bLoaded;
  private boolean bCountries;

}
