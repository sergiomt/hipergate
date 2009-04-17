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

package com.knowgate.dataobjs;

import java.io.FileNotFoundException;

import java.util.LinkedList;
import java.util.ListIterator;
import java.io.IOException;

import java.sql.SQLException;

import java.lang.ClassNotFoundException;

import org.xml.sax.Attributes;
import org.xml.sax.Parser;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.XMLReaderFactory;
import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.helpers.ParserAdapter;
import org.xml.sax.helpers.ParserFactory;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;

/**
 * <p>SAX Parser Event Handler for loading XML formated data into a DBPersist object.</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class DBSaxHandler extends DefaultHandler {

  /**
   * Construct and set reference to DBPersist object that will hold the loaded data.
   * @deprecated Use DBSaxHandler(DBPersist oPersist, JDCConnection) instead
   */

    public DBSaxHandler(DBPersist oPersist) {
        oTarget = oPersist;
        oTable = oPersist.getTable();
        oColList = oTable.getColumns();
        oColIter = oColList.listIterator();
    }

    public DBSaxHandler(DBPersist oPersist, JDCConnection oConn)
      throws SQLException {
        oTarget = oPersist;
        oTable = oPersist.getTable(oConn);
        oColList = oTable.getColumns();
        oColIter = oColList.listIterator();
    }

    // Data

    /** Number of elements. */
    protected long fElements;
    /** Number of characters. */
    protected long fCharacters;

    protected LinkedList oColList;
    protected ListIterator oColIter;
    protected DBColumn oColumn;
    protected DBTable oTable;
    protected DBPersist oTarget;

    // -------------------------------------------------------------------------

    // **********************
    // ContentHandler methods
    //

    /**
     * Start document.
     */
    public void startDocument() throws SAXException {

        fElements            = 0;
        fCharacters          = 0;
    } // startDocument()

    // -------------------------------------------------------------------------

    /**
     * Start element.
     */

    public void startElement(String uri, String local, String raw,
                             Attributes attrs) throws SAXException {
        fElements++;

        if (null==oColumn) {
          oColumn = oTable.getColumnByName(local);
        }

    } // startElement(String,String,StringAttributes)

    // -------------------------------------------------------------------------

    /**
     * Characters.
     */

    public void characters(char ch[], int start, int length)
        throws SAXException {

        fCharacters += length;

        if (null!=oColumn) {

          if (DebugFile.trace)
            DebugFile.writeln("DBSaxHendler.characters() parsing " + new String(ch,start,length) +  " into " + oColumn.getName() + " as type " +  oColumn.getSqlTypeName() );

          try {
            oTarget.put(oColumn.getName(), new String(ch,start,length), oColumn.getSqlType());
          }
          catch (FileNotFoundException fnfe) { /* never thrown */ }

        oColumn = null;
        } // fi (oColumn)
    } // characters(char[],int,int);

    // -------------------------------------------------------------------------

    // ********************
    // ErrorHandler methods
    //

    /**
     * Warning.
     */
    public void warning(SAXParseException ex) throws SAXException {
        if (DebugFile.trace) DebugFile.write(composeError("Warning", ex));
    } // warning(SAXParseException)

    /**
     * Error.
     */
    public void error(SAXParseException ex) throws SAXException {
        if (DebugFile.trace) DebugFile.write(composeError("Error", ex));
        throw ex;
    } // error(SAXParseException)

    /**
     * Fatal error.
     * */
    public void fatalError(SAXParseException ex) throws SAXException {
      if (DebugFile.trace) DebugFile.write(composeError("Fatal Error", ex));
      throw ex;
    } // fatalError(SAXParseException)

    // -------------------------------------------------------------------------

    // *****************
    // Protected methods
    //

    /**
     * Compose the error message.
     */
    protected String composeError(String type, SAXParseException ex) {
        String sErrDesc = "";
        String systemId = null;
        int index;

        sErrDesc += "[SAX " + type + "] ";

        if (ex==null)
          sErrDesc += "!!!";
        else
          systemId = ex.getSystemId();

        if (systemId != null) {
            index = systemId.lastIndexOf('/');
            if (index != -1) systemId = systemId.substring(index + 1);
            sErrDesc += systemId;
        }

        sErrDesc += " Line:" + ex.getLineNumber();
        sErrDesc += " Column:" + ex.getColumnNumber();
        sErrDesc += " Cause: " + ex.getMessage();
        sErrDesc += "\n";

        return sErrDesc;
    } // composeError(String,SAXParseException)

    // -------------------------------------------------------------------------

    // **************
    // Public methods
    //

    /**
     * Parses an XML document into a DBPersist instance
     */

    public void parse(String sXMLSource)
        throws InstantiationException,IllegalAccessException,ClassNotFoundException,IOException,SAXException {

        // local variables
        XMLReader parser;
        Parser sax1Parser;
        long time, timeBefore=0, timeAfter=0, memory, memoryBefore=0, memoryAfter=0;

        if (DebugFile.trace) {
          timeBefore = System.currentTimeMillis();
          memoryBefore = Runtime.getRuntime().freeMemory();
        }

        try {
          if (DebugFile.trace)
            DebugFile.writeln("XMLReaderFactory.createXMLReader(DEFAULT_PARSER_NAME)");

          parser = XMLReaderFactory.createXMLReader(DEFAULT_PARSER_NAME);
        }
        catch (Exception e) {
            sax1Parser = ParserFactory.makeParser(DEFAULT_PARSER_NAME);
            parser = new ParserAdapter(sax1Parser);
            if (DebugFile.trace)
              DebugFile.writeln("warning: Features and properties not supported on SAX1 parsers.");
        }

      // parse file
      parser.setContentHandler(this);
      parser.setErrorHandler(this);

      if (DebugFile.trace)
        DebugFile.writeln("XMLReader.parse(" + sXMLSource + ")");

      parser.parse(sXMLSource);

      if (DebugFile.trace) {
        memoryAfter = Runtime.getRuntime().freeMemory();
        timeAfter = System.currentTimeMillis();

        time = timeAfter - timeBefore;
        memory = memoryBefore - memoryAfter;
      }
    } // parse

    // -------------------------------------------------------------------------

    // feature ids

    protected static final String NAMESPACES_FEATURE_ID = "http://xml.org/sax/features/namespaces";
    protected static final String NAMESPACE_PREFIXES_FEATURE_ID = "http://xml.org/sax/features/namespace-prefixes";
    protected static final String VALIDATION_FEATURE_ID = "http://xml.org/sax/features/validation";
    protected static final String SCHEMA_VALIDATION_FEATURE_ID = "http://apache.org/xml/features/validation/schema";
    protected static final String SCHEMA_FULL_CHECKING_FEATURE_ID = "http://apache.org/xml/features/validation/schema-full-checking";
    protected static final String DYNAMIC_VALIDATION_FEATURE_ID = "http://apache.org/xml/features/validation/dynamic";

    // default settings

    protected static final String DEFAULT_PARSER_NAME = "org.apache.xerces.parsers.SAXParser";
    protected static final int DEFAULT_REPETITION = 1;
    protected static final boolean DEFAULT_NAMESPACES = true;
    protected static final boolean DEFAULT_NAMESPACE_PREFIXES = false;
    protected static final boolean DEFAULT_VALIDATION = false;
    protected static final boolean DEFAULT_SCHEMA_VALIDATION = false;
    protected static final boolean DEFAULT_SCHEMA_FULL_CHECKING = false;
    protected static final boolean DEFAULT_DYNAMIC_VALIDATION = false;
    protected static final boolean DEFAULT_MEMORY_USAGE = false;
    protected static final boolean DEFAULT_TAGGINESS = false;
}