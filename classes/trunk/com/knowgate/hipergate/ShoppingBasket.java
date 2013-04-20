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

package com.knowgate.hipergate;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.Serializable;
import java.io.StringBufferInputStream;

import java.util.ArrayList;
import java.util.Date;
import java.util.Map;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.TreeMap;
import java.util.Iterator;
import java.math.BigDecimal;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBColumn;
import com.knowgate.dfs.FileSystem;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipergate.Address;

import org.xml.sax.Attributes;
import org.xml.sax.ContentHandler;
import org.xml.sax.InputSource;
import org.xml.sax.Parser;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;

import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.helpers.ParserFactory;
import org.xml.sax.helpers.ParserAdapter;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 * <p>Shopping basket</p>
 * This class is specially designed for usage as a shopping basket for a website<br>
 * Shopping baskets have 3 main elements:<br>
 * <ul><li>Customer identification</li><li>Global properties</li><li>Lines</li></ul>
 * @author Sergio Montoro Ten
 * @version 4.0
 */
public class ShoppingBasket extends DefaultHandler implements ContentHandler,Serializable {

  private String sGuCustomer;
  private ArrayList oLines;
  private HashMap   oProps;
  private HashMap   oLastLine;
  private int       iLastLine;
  private LinkedHashMap oAddressesByName;
  private TreeMap oAddressesByIndex;
  private StringBuffer oBuffer;
  private Address oTemporaryAddr;
  private OrderLine oTemporaryLine;

  // ---------------------------------------------------------------------------

  /**
   * Default constructor
   */
  public ShoppingBasket() {
    sGuCustomer = null;
    oLines = new ArrayList();
    oProps = new HashMap();
    oAddressesByName = new LinkedHashMap(13);
    oAddressesByIndex = new TreeMap();
    oLastLine = null;
    iLastLine = -1;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get Address by index</p>
   * The Address index is the value of ix_address column of k_addresses table
   * @return Address object or <b>null</b> if no Address with such index was found
   * @since 4.0
   */
  public Address getAddress(int nIndex) {
    return (Address) oAddressesByIndex.get(new Integer(nIndex));
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get Address by type</p>
   * The Address type is the value of tp_location column of k_addresses table
   * @return Address object or <b>null</b> if no Address with such type was found
   * @since 4.0
   */
  public Address getAddress(String sType) {
    return (Address) oAddressesByName.get(sType);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get Addresses </p>
   * The Address type is the value of tp_location column of k_addresses table
   * @return Array of addresses loaded at ShoppingBasket or <b>null</b> if ShoppingBasket contains no addresses
   * @since 4.0
   */
  public Address[] getAddresses() {
    Address[] aRetArr;
    int nAddrs = oAddressesByIndex.size();
    if (nAddrs==0) {
   	 aRetArr = null;
    } else {
      aRetArr = new Address[nAddrs];
      int a = 0;
      Iterator oIter = oAddressesByIndex.entrySet().iterator();
	  while (oIter.hasNext()) {
	    aRetArr[a++] = (Address) oIter.next();
	  } // wend
    } // fi
    return aRetArr;
  } // getAddresses

  // ---------------------------------------------------------------------------

  public int countAddresses() {
    return oAddressesByIndex.size();
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Put an Address into the Shopping basket</p>
   * If a previous Address of same type or index is already present then it is silently replaced.
   * @since 4.0
   */
  public void putAddress(Address oAddr)
  	throws NullPointerException {
  	if (null==oAddr) throw new NullPointerException("ShoppingBasket.putAddress() Address may noy be null");
  	if (!oAddr.isNull(DB.tp_location)) {
  	  if (oAddressesByName.containsKey(oAddr.get(DB.tp_location)))
  	  	oAddressesByName.remove(oAddr.get(DB.tp_location));
  	  oAddressesByName.put(oAddr.get(DB.tp_location), oAddr);
  	} // fi
  	if (!oAddr.isNull(DB.ix_address)) {
  	  if (oAddressesByIndex.containsKey(oAddr.get(DB.ix_address)))
  	  	oAddressesByIndex.remove(oAddr.get(DB.ix_address));
  	  oAddressesByIndex.put(oAddr.get(DB.ix_address), oAddr);
  	} else {
  	  oAddressesByIndex.put(new Integer(Integer.parseInt(oAddressesByIndex.lastKey().toString())+1), oAddr);
  	} // fi
  } // putAddress

  // ---------------------------------------------------------------------------

  /**
   * Get customer identification
   * @return String uniquely identifying the customer owner of this shopping basket
   */
  public String getCustomer() {
    return sGuCustomer;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Set customer identification</p>
   * Customer Id. can be any arbitrary string that uniquely identifies current customer
   * @param sIdCustomer String uniquely identifying the customer owner of this shopping basket
   */
  public void setCustomer(String sIdCustomer) {
    sGuCustomer = sIdCustomer;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get a global property of this basket
   * @param sKey String property name
   * @return Object or <b>null</b> if there is no property with such name
   */
  public Object getProperty(String sKey) {
    return oProps.get(sKey);
  }

  // ---------------------------------------------------------------------------

  /**
   * Whether or not this shopping basket contains a given global property
   * @param sKey String property name
   * @return boolean
   */
  public boolean containsProperty(String sKey) {
    return oProps.containsKey(sKey);
  }

  // ---------------------------------------------------------------------------

  /**
   * Set global property for this basket
   * @param sKey String property name
   * @param oProperty Object
   */
  public void setProperty(String sKey, Object oProperty) {
    if (oProps.containsKey(sKey)) oProps.remove(sKey);
    oProps.put(sKey, oProperty);
  }

  // ---------------------------------------------------------------------------

  /**
   * Set global properties for this basket
   * @param oPropertiesMap Map containing property names as map keys and property values as map values
   */
  public void setProperties (Map oPropertiesMap) {
    Iterator oKeys = oPropertiesMap.keySet().iterator();
    String sKey;
    while (oKeys.hasNext()) {
      sKey = (String) oKeys.next();
      setProperty(sKey, oPropertiesMap.get(sKey));
    } // wend
  } // setProperties

  // ---------------------------------------------------------------------------

  /**
   * Clear all global properties
   */
  public void clearProperties () {
    oProps.clear();
  }

  // ---------------------------------------------------------------------------

  /**
   * Remove a single global property
   * @param sKey String property name
   */
  public void removeProperty(String sKey) {
    oProps.remove(sKey);
  }

  // ---------------------------------------------------------------------------

  /**
   * Add empty order line to this basket
   */
  public void addLine() {
    oLines.add(new HashMap());
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Add order line to this basket</p>
   * Each line has an arbitrary number of named attributes given in the Map passed as parameter
   * @param oLine Map with line attributes
   */
  public void addLine(Map oLine) {
    oLines.add(oLine);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Add order line to this basket</p>
   * This method adds a line from a string of the form: "attribute1=value1,attribute2=value2,attribute3=value3"
   * @param sInputStr String
   * @param sDelimiter String Delimiter to be used between attribute, in the examle above, a comma
   */
  public void addLine(String sInputStr, String sDelimiter) {
    oLines.add(new HashMap());
    setLineAttributes(oLines.size()-1, sInputStr, sDelimiter);
  }

  // ---------------------------------------------------------------------------

  /**
   * Count of lines on this basket
   * @return int
   */
  public int getLineCount() {
    return oLines.size();
  }

  // ---------------------------------------------------------------------------

  /**
   * Remove order line from this basket
   * @param nLine int Line number [0..getLineCount()-1)]
   */
  public void removeLine(int nLine) {
    oLines.remove(nLine);
    oLastLine=null;
    iLastLine=-1;
  }

  // ---------------------------------------------------------------------------

  /**
   * Clear all attributes for a line
   * @param nLine int Line number [0..getLineCount()-1)]
   * @throws ArrayIndexOutOfBoundsException
   */
  public void clearLine(int nLine) throws ArrayIndexOutOfBoundsException {
    ((HashMap) oLines.get(nLine)).clear();
  }

  // ---------------------------------------------------------------------------

  /**
   * Get order line
   * @param nLine int Line number [0..getLineCount()-1)]
   * @return HashMap Line attributes
   * @throws ArrayIndexOutOfBoundsException
   */
  public HashMap getLine(int nLine) throws ArrayIndexOutOfBoundsException {
    return (HashMap) oLines.get(nLine);
  }

  // ---------------------------------------------------------------------------

  /**
   * Get attribute of a given line
   * @param nLine int Line number [0..getLineCount()-1)]
   * @param sKey String attribute name
   * @return Object
   * @throws ArrayIndexOutOfBoundsException
   */
  public Object getLineAttribute(int nLine, String sKey)
    throws ArrayIndexOutOfBoundsException {
    if (nLine!=iLastLine) {
      iLastLine = nLine;
      oLastLine = (HashMap) oLines.get(nLine);
    }
    return oLastLine.get(sKey);
  } // getLineAttribute

  // ---------------------------------------------------------------------------

  /**
   * Get attribute of a given line casted to String
   * @param nLine int Line number [0..getLineCount()-1)]
   * @param sKey String attribute name
   * @return String
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   */
  public String getLineString(int nLine, String sKey)
    throws ArrayIndexOutOfBoundsException, ClassCastException {
    if (nLine!=iLastLine) {
      iLastLine = nLine;
      oLastLine = (HashMap) oLines.get(nLine);
    }
    return (String) oLastLine.get(sKey);
  } // getLineString

  // ---------------------------------------------------------------------------

  /**
   * Get attribute of a given line casted to java.math.BigDecimal
   * @param nLine int Line number [0..getLineCount()-1)]
   * @param sKey String attribute name
   * @return BigDecimal
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   */
  public BigDecimal getLineBigDecimal(int nLine, String sKey)
    throws ArrayIndexOutOfBoundsException, ClassCastException {
    if (nLine!=iLastLine) {
      iLastLine = nLine;
      oLastLine = (HashMap) oLines.get(nLine);
    }
    return (BigDecimal) oLastLine.get(sKey);
  } // getLineBigDecimal

  // ---------------------------------------------------------------------------

  /**
   * Get attribute of a given line casted to java.util.Date
   * @param nLine int Line number [0..getLineCount()-1)]
   * @param sKey String attribute name
   * @return Date
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   */
  public Date getLineDate(int nLine, String sKey)
    throws ArrayIndexOutOfBoundsException, ClassCastException {
    if (nLine!=iLastLine) {
      iLastLine = nLine;
      oLastLine = (HashMap) oLines.get(nLine);
    }
    return (Date) oLastLine.get(sKey);
  } // getLineDate

  // ---------------------------------------------------------------------------

  /**
   * Get attribute of a given line casted to java.lang.Integer
   * @param nLine int Line number [0..getLineCount()-1)]
   * @param sKey String attribute name
   * @return Date
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   */
  public Integer getLineInteger(int nLine, String sKey)
    throws ArrayIndexOutOfBoundsException, ClassCastException {
    if (nLine!=iLastLine) {
      iLastLine = nLine;
      oLastLine = (HashMap) oLines.get(nLine);
    }
    return (Integer) oLastLine.get(sKey);
  } // getLineInteger

  // ---------------------------------------------------------------------------

  /**
   * Set attribute for a given line
   * @param nLine int Line number [0..getLineCount()-1)]
   * @param sKey String attribute name
   * @param oAttr Object attribute value
   * @throws ArrayIndexOutOfBoundsException
   */
  public void setLineAttribute(int nLine, String sKey, Object oAttr)
    throws ArrayIndexOutOfBoundsException {
    if (nLine!=iLastLine) {
      iLastLine = nLine;
      oLastLine = (HashMap) oLines.get(nLine);
    }
    if (oLastLine.containsKey(sKey)) oLastLine.remove(sKey);
    oLastLine.put(sKey, oAttr);
  } // setLineAttribute

  // ---------------------------------------------------------------------------

  /**
   * Set attributes for a given line
   * @param nLine int Line number [0..getLineCount()-1)]
   * @param sInputStr String of the form "attr1=value1,attr2=value2,attr3=value3"
   * @param sDelimiter String Delimiter between pairs of attribute=value (comma in the previous example)
   * @throws ArrayIndexOutOfBoundsException
   */

  public void setLineAttributes(int nLine, String sInputStr, String sDelimiter)
    throws ArrayIndexOutOfBoundsException {
    String[] aAttrs;
    String[] aAtrVl;
    String sKey;
    String sVal;
    if (nLine!=iLastLine) {
      iLastLine = nLine;
      oLastLine = (HashMap) oLines.get(nLine);
    }
    if (sInputStr!=null) {
      if (sInputStr.length()>0) {
        aAttrs = Gadgets.split(sInputStr, sDelimiter);
        for (int a=aAttrs.length-1; a>=0; a--) {
          if (aAttrs[a].length()>0) {
            aAtrVl = Gadgets.split(aAttrs[a], '=');
            sKey = aAtrVl[0].trim();
            sVal = aAtrVl[1].trim();
            if (oLastLine.containsKey(sKey)) oLastLine.remove(sKey);
            oLastLine.put(sKey, sVal);
          } // fi (aAttrs[a].length()>0)
        } // next
      } // fi
    } // fi
  } // setLineAttributes

  // ---------------------------------------------------------------------------

  /**
   * Get the first line that contains an attribute with a given value
   * @param sKey String Attribute key
   * @param oAttr Object Attribute value
   * @return int Number [0..getLineCount()-1)] of the first line that contains
   * an attribute with the given name and value or -1 if no line attribute matches
   * the given one.
   */
  public int findLine (String sAttrKey, Object oAttrValue) {
    final int nLines = oLines.size();
    HashMap oCurrentLine;
    int l;
    int iRetVal = -1;
    if (null==oAttrValue) {
      for (l=0; l<nLines && -1==iRetVal; l++) {
        oCurrentLine = (HashMap) oLines.get(l);
        if (oCurrentLine.containsKey(sAttrKey))
          if (oCurrentLine.get(sAttrKey)==null)
            iRetVal = l;
      } // next
    } else {
      for (l=0; l<nLines && -1==iRetVal; l++) {
        oCurrentLine = (HashMap) oLines.get(l);
        if (oAttrValue.equals(oCurrentLine.get(sAttrKey)))
          iRetVal = l;
      } // next
    } // fi (oAttr==null)
    return iRetVal;
  } // findLine

  // ---------------------------------------------------------------------------

  /**
   * <p>Get sum of all line attributes of a given name</p>
   * @param sAttrKey String Atrributes common name
   * @return BigDecimal Sum of values or zero if no attributes where found
   * @throws ClassCastException Attribute values must be of type BigDecimal
   * or else a ClassCastException is raised
   */
  public BigDecimal sum(String sAttrKey)
    throws ClassCastException {
    final int nLines = oLines.size();
    BigDecimal oSum = new BigDecimal(0d);
    HashMap oCurrentLine;
    Object oVal;
    for (int l=0; l<nLines; l++) {
      oCurrentLine = (HashMap) oLines.get(l);
      oVal = oCurrentLine.get(sAttrKey);
      if (null!=oVal)
        oSum = oSum.add((BigDecimal) oVal);
    } // next
    return oSum;
  }

  // ==========================================================

  //
  // SAX ContentHandler methods
  //

  /** Start document. */
  public void startDocument() throws SAXException {

    if (DebugFile.trace) {
      DebugFile.writeln ("Begin ShoppingBasket.startDocument()");
      DebugFile.incIdent();
    }

	oBuffer = new StringBuffer(8000);
	
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln ("End ShoppingBasket.startDocument()");
    }
  } // startDocument()


  // ---------------------------------------------------------------------------

  /** Characters. */
  public void characters(char ch[], int start, int length) throws SAXException {
    oBuffer.append(ch,start,length);
  } // characters(char[],int,int);

  // ----------------------------------------------------------

  public void startElement(String uri, String local, String raw,
                           Attributes attrs) throws SAXException {
    
     if (local.equalsIgnoreCase("Address")) {
       oTemporaryAddr = new Address();
     } else if (local.equalsIgnoreCase("Line")) {
       oTemporaryLine = new OrderLine();
     }
    
  } // startElement(String,String,StringAttributes)

  // ----------------------------------------------------------

  public void endElement(String uri, String local, String qname) throws SAXException {

    DBColumn oCol = null;

    if (local.equalsIgnoreCase("Customer")) {
      setCustomer(oBuffer.toString());
    } else if (local.equalsIgnoreCase("Address")) {
      putAddress(oTemporaryAddr);
      oTemporaryAddr = null;
    } else if (local.equalsIgnoreCase("Line")) {
	  addLine(oTemporaryLine.getItemMap());
	  oTemporaryLine = null;
    } else if (oTemporaryAddr!=null) {
      if (oTemporaryAddr.getTable()!=null)
	    oCol = oTemporaryAddr.getTable().getColumnByName(local.toLowerCase());
      if (null!=oCol) {
        try { oTemporaryAddr.put(local, oBuffer.toString(), oCol.getSqlType()); }
        catch (FileNotFoundException fnf) { throw new SAXException(fnf.getMessage(), fnf); }
      }
      else
        oTemporaryAddr.put(local, oBuffer.toString());     	  
    } else if (oTemporaryLine!=null) {
      if (oTemporaryLine.getTable()!=null)
	    oCol = oTemporaryLine.getTable().getColumnByName(local.toLowerCase());
      if (null!=oCol) {
        try { oTemporaryLine.put(local, oBuffer.toString(), oCol.getSqlType()); }
        catch (FileNotFoundException fnf) { throw new SAXException(fnf.getMessage(), fnf); }
      }
      else
        oTemporaryLine.put(local, oBuffer.toString());     	  
    } else if (local.equalsIgnoreCase("Properties")) {
      // Do nothing here	
    } else {
      setProperty(local, oBuffer.toString());
    }
    oBuffer.setLength(0);    
  } // endElement(String, String, String)

  // ----------------------------------------------------------

    //
    // ErrorHandler methods
    //

    /** Warning. */
    public void warning(SAXParseException ex) throws SAXException {
        if (DebugFile.trace) DebugFile.write(composeError("Warning", ex));
    } // warning(SAXParseException)

    /** Error. */
    public void error(SAXParseException ex) throws SAXException {
        if (DebugFile.trace) DebugFile.write(composeError("Error", ex));
        throw ex;
    } // error(SAXParseException)

    /** Fatal error. */
    public void fatalError(SAXParseException ex) throws SAXException {
      if (DebugFile.trace) DebugFile.write(composeError("Fatal Error", ex));
      throw ex;
    } // fatalError(SAXParseException)

  // ----------------------------------------------------------

    //
    // Protected methods
    //

    /** Compose the error message. */
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

    public void parse(File oXMLData, String sEncoding)
    	throws InstantiationException,IllegalAccessException,ClassNotFoundException,IOException,SAXException {        
	    try {
	      parse(new String(FileSystem.readfile("file://"+oXMLData.getAbsolutePath(), sEncoding)));
	    } catch (com.enterprisedt.net.ftp.FTPException neverthrown) { }
    }
    	
    // ----------------------------------------------------------

    public void parse(String sXMLData)
    	throws InstantiationException,IllegalAccessException,ClassNotFoundException,IOException,SAXException {
        // This method parses an XML document into a ShoppingBasket instace

        // local variables
        XMLReader parser;
        Parser sax1Parser;
        StringBufferInputStream oStrBuff;
        InputSource ioSrc;

        if (DebugFile.trace) {
          DebugFile.writeln ("Begin ShoppingBasket.parse(String)");
          DebugFile.incIdent();
        }

        try {
          if (DebugFile.trace) DebugFile.writeln ("XMLReaderFactory.createXMLReader(" + DEFAULT_PARSER_NAME + ")");

          parser = XMLReaderFactory.createXMLReader(DEFAULT_PARSER_NAME);
        }
        catch (Exception e) {
            if (DebugFile.trace) DebugFile.writeln ("ParserFactory.makeParser(" + DEFAULT_PARSER_NAME + ")");

            sax1Parser = ParserFactory.makeParser(DEFAULT_PARSER_NAME);

            parser = new ParserAdapter(sax1Parser);
            if (DebugFile.trace)
              DebugFile.writeln("warning: Features and properties not supported on SAX1 parsers.");
        }
        try {
          parser.setFeature(NAMESPACES_FEATURE_ID, DEFAULT_NAMESPACES);
          parser.setFeature(VALIDATION_FEATURE_ID, DEFAULT_VALIDATION);
        }
        catch (SAXException e) {
        }

      // parse file
      parser.setContentHandler(this);
      parser.setErrorHandler(this);

      oStrBuff = new StringBufferInputStream(sXMLData);
      ioSrc = new InputSource(oStrBuff);
      parser.parse(ioSrc);
      oStrBuff.close();

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln ("End ShoppingBasket.parse()");
      }
  } // parse()

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
