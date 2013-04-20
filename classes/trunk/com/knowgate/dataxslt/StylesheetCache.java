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

package com.knowgate.dataxslt;

import java.io.File;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;

import java.util.Date;
import java.util.WeakHashMap;
import java.util.Iterator;
import java.util.Properties;

import javax.xml.transform.TransformerFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.Templates;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.stream.StreamResult;

import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * XSL File Cache
 * This class keeps a master copy in memory of each XSL Stylesheet file.<br>
 * When a Transformer object is requested a copy of the master Stylesheet is
 * done. This is faster than re-loading de XSL file from disk.<br>
 * StylesheetCache is a WeakHashMap so cached stylesheets can be automatically
 * garbage collected is memory runs low.
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class StylesheetCache {

  private StylesheetCache() { }

  // ---------------------------------------------------------------------------

  /**
   * Get Transformer object for XSL file.
   * StylesheetCache automatically checks file last modification date and compares
   * it with loading date for cached objects. If file is more recent than its cached
   * object then the disk copy is reloaded.
   * @param sFilePath File Path
   * @throws IOException
   * @throws TransformerException
   * @throws TransformerConfigurationException
   */
  public static synchronized Transformer newTransformer(String sFilePath)
    throws FileNotFoundException, IOException, TransformerException, TransformerConfigurationException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin StylesheetCache.newTransformer(" + sFilePath + ")");
      DebugFile.incIdent();
    }

    File oFile = new File(sFilePath);

    if (!oFile.exists()) {
      if (DebugFile.trace) {
        DebugFile.writeln("File not found " + sFilePath);
        DebugFile.decIdent();
      }
      throw new FileNotFoundException(sFilePath);
    }
    long lastMod = oFile.lastModified();

    TransformerFactory oFactory;
    Templates oTemplates;
    StreamSource oStreamSrc;
    SheetEntry oSheet = oCache.get(sFilePath);

    if (null!=oSheet) {
      if (DebugFile.trace) {
        DebugFile.writeln("Cache hit: Cached stylesheet date "+new Date(oSheet.lastModified).toString() + " Disk file date "+new Date(lastMod).toString());
      }
      if (lastMod>oSheet.lastModified) {
        oSheet = null;
        oCache.remove(sFilePath);
      }
    } // fi (oSheet)

    if (null==oSheet) {
      if (DebugFile.trace) DebugFile.writeln("TransformerFactory.newInstance()");
      oFactory = TransformerFactory.newInstance();
      if (DebugFile.trace) DebugFile.writeln("new StreamSource("+sFilePath+")");
      File oFlSrc = new File(sFilePath);
      oStreamSrc = new StreamSource(oFlSrc);
      oStreamSrc.setSystemId(oFlSrc);
      if (DebugFile.trace) DebugFile.writeln("TransformerFactory.newTemplates("+oFlSrc.toURL().toExternalForm()+")");
      oTemplates = oFactory.newTemplates(oStreamSrc);
      oSheet = new SheetEntry(lastMod, oTemplates);
      if (DebugFile.trace) DebugFile.writeln("WeakHashMap.put("+sFilePath+", SheetEntry)");
      oCache.put(sFilePath, oSheet);
    } // fi

    if (DebugFile.trace) DebugFile.writeln("javax.xml.transform.Templates.newTransformer()");
    Transformer oTransformer = oSheet.templates.newTransformer();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oTransformer)
        DebugFile.writeln("End StylesheetCache.newTransformer() : null");
	  else
        DebugFile.writeln("End StylesheetCache.newTransformer() : " + oTransformer.toString());
    }

    return oTransformer;
  } // newTransformer()

  // ---------------------------------------------------------------------------

  /**
   * Set parameters for a StyleSheet taken from a properties collection.
   * This method is primarily designed for setting environment parameters.
   * @param oXSL Transformer object.
   * @param oProps Properties to be set as parameters. The substring "param_"
   * will be added as a preffix to each property name passed as parameter.
   * So if you pass a property named "workarea" it must be retrieved from XSL
   * as &lt;xsl:param name="param_workarea"/&gt;
   * @throws NullPointerException if oXSL is <b>null</b> or oProps is <b>null</b>
   */
  public static void setParameters(Transformer oXSL, Properties oProps)
    throws NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin StylesheetCache.setParameters(Transformer, Properties)");
      if (null==oXSL) throw new NullPointerException("StylesheetCache.setParameters() Transformer may not be null");
      if (null==oProps) throw new NullPointerException("StylesheetCache.setParameters() Properties may not be null");
      DebugFile.writeln(oProps.toString());
      DebugFile.incIdent();
    }

    String sKey, sVal;
    Iterator myIterator = oProps.keySet().iterator();

    while (myIterator.hasNext())
    {
      sKey = (String) myIterator.next();
      sVal = oProps.getProperty(sKey);

      try {
       	oXSL.setParameter("param_" + sKey, sVal);
      } catch (Exception xcpt) {
      	if (DebugFile.trace)
      	  DebugFile.writeln("Transformer.setParameter(param_"+sKey+","+sVal+") "+xcpt.getClass().getName()+" "+xcpt.getMessage());
      }
    } // wend()

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End StylesheetCache.setParameters()");
    }
  } // setParameters

  // ---------------------------------------------------------------------------

  /**
   * Perform XSLT transformation
   * @param sStyleSheetPath File Path to XSL style sheet file
   * @param oXMLInputStream Input Stream for XML source data
   * @param oOutputStream Stream where output is to be written
   * @param oProps Parameters for Transformer. The substring "param_"
   * will be added as a preffix to each property name passed as parameter.
   * So if you pass a property named "workarea" it must be retrieved from XSL
   * as &lt;xsl:param name="param_workarea"/&gt;
   * @throws NullPointerException if oProps is <b>null</b>
   * @throws FileNotFoundException if sStyleSheetPath does not exist
   * @throws IOException
   * @throws TransformerException
   * @throws TransformerConfigurationException
   */
  public static void transform (String sStyleSheetPath,
                                InputStream oXMLInputStream,
                                OutputStream oOutputStream, Properties oProps)
    throws IOException, FileNotFoundException,
           NullPointerException, TransformerException, TransformerConfigurationException {

    long lElapsed = 0;

    if (null==sStyleSheetPath)
      	throw new NullPointerException ("StylesheetCache.transform() style sheet path may not be null");

    if (null==oXMLInputStream)
      	throw new NullPointerException ("StylesheetCache.transform() InputStream may not be null");

    if (null==oOutputStream)
      	throw new NullPointerException ("StylesheetCache.transform() OutputStream may not be null");

    if (DebugFile.trace) {
      if (!new File(sStyleSheetPath).exists())
      	throw new FileNotFoundException ("StylesheetCache.transform() "+sStyleSheetPath);

      lElapsed = System.currentTimeMillis();

      DebugFile.writeln("Begin StylesheetCache.transform(" + sStyleSheetPath + ", InputStream, Properties)");
      DebugFile.incIdent();
    }

    Transformer oTransformer = StylesheetCache.newTransformer(sStyleSheetPath);

    if (null!=oProps) setParameters(oTransformer, oProps);

    StreamSource oStreamSrcXML = new StreamSource(oXMLInputStream);

    StreamResult oStreamResult = new StreamResult(oOutputStream);

    if (DebugFile.trace) DebugFile.writeln("Transformer.transform(StreamSource,StreamResult)");

    oTransformer.transform(oStreamSrcXML, oStreamResult);

    if (DebugFile.trace) {
      DebugFile.writeln("done in " + String.valueOf(System.currentTimeMillis()-lElapsed) + " miliseconds");
      DebugFile.decIdent();
      DebugFile.writeln("End StylesheetCache.transform()");
    }
  } // transform

  // ---------------------------------------------------------------------------

  /**
   * Perform XSLT transformation
   * @param sStyleSheetPath File Path to XSL style sheet file
   * @param sXMLInput Input String with XML source data
   * @param oProps Parameters for Transformer. The substring "param_"
   * will be added as a preffix to each property name passed as parameter.
   * So if you pass a property named "workarea" it must be retrieved from XSL
   * as &lt;xsl:param name="param_workarea"/&gt;
   * @return String Transformed document
   * @throws NullPointerException if sXMLInput or oProps are <b>null</b>
   * @throws FileNotFoundException if sStyleSheetPath does not exist
   * @throws IOException
   * @throws UnsupportedEncodingException
   * @throws TransformerException
   * @throws TransformerConfigurationException
   * @since 3.0
   */
  public static String transform (String sStyleSheetPath, String sXMLInput, Properties oProps)
    throws IOException, FileNotFoundException, UnsupportedEncodingException,
           NullPointerException, TransformerException, TransformerConfigurationException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin StylesheetCache.transform(" + sStyleSheetPath + ", String, Properties)");
      DebugFile.incIdent();
    }

    if (null==sXMLInput) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("StylesheetCache.transform() XML input String may not be null");
    }

    // ****************************************
    // Get character encoding of input XML data
    String sEncoding;
    int iEnc = Gadgets.indexOfIgnoreCase(sXMLInput, "encoding");
    if (iEnc<0) {
      sEncoding = "ISO8859_1";
    } else {
      int iBeg = iEnc+8;
      int iEnd;
      while (sXMLInput.charAt(iBeg)==' ' || sXMLInput.charAt(iBeg)=='=') iBeg++;
      while (sXMLInput.charAt(iBeg)==' ') iBeg++;
      if (sXMLInput.charAt(iBeg)=='"') {
        iEnd = ++iBeg;
        while (sXMLInput.charAt(iEnd)!='"') iEnd++;
      } else {
        iEnd = iBeg;
        while (sXMLInput.charAt(iEnd)!=' ' && sXMLInput.charAt(iEnd)!='?') iEnd++;
      } // fi
      sEncoding = sXMLInput.substring(iBeg, iEnd);
    } // fi
    // ****************************************

    if (DebugFile.trace) {
      DebugFile.writeln("XML input file encoding is "+sEncoding);
    }

    ByteArrayOutputStream oOutputStream = new ByteArrayOutputStream();
    ByteArrayInputStream oXMLInputStream = new ByteArrayInputStream(sXMLInput.getBytes(sEncoding));
    Transformer oTransformer = StylesheetCache.newTransformer(sStyleSheetPath);
    if (null!=oProps) setParameters(oTransformer, oProps);
    StreamSource oStreamSrcXML = new StreamSource(oXMLInputStream);
    StreamResult oStreamResult = new StreamResult(oOutputStream);
    if (DebugFile.trace) DebugFile.writeln("Transformer.transform(StreamSource,StreamResult)");
    oTransformer.transform(oStreamSrcXML, oStreamResult);
    oStreamSrcXML = null;
    oXMLInputStream.close();
    String sRetVal = oOutputStream.toString(sEncoding);
    if (DebugFile.trace) {
      if (null==sRetVal)
        DebugFile.writeln("Transformer.transform() returned null");
      else
        DebugFile.writeln("Transformer.transform() returned "+String.valueOf(sRetVal.length())+" characters");
    }
    oStreamResult = null;
    oOutputStream.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End StylesheetCache.transform()");
    }
    return sRetVal;
  } // transform

  // ---------------------------------------------------------------------------

  /**
   * Perform XSLT transformation
   * @param oStyleSheetStream Stream to XSL style sheet
   * @param oXMLInput Input Stream with XML source data
   * @param oEncoding Input Stream data encoding
   * @param oProps Parameters for Transformer. The substring "param_"
   * will be added as a preffix to each property name passed as parameter.
   * So if you pass a property named "workarea" it must be retrieved from XSL
   * as &lt;xsl:param name="param_workarea"/&gt;
   * @return String Transformed document
   * @throws NullPointerException if sXMLInput or oProps are <b>null</b>
   * @throws FileNotFoundException if sStyleSheetPath does not exist
   * @throws IOException
   * @throws UnsupportedEncodingException
   * @throws TransformerException
   * @throws TransformerConfigurationException
   * @since 6.0
   */
  public static String transform (InputStream oStyleSheetStream, InputStream oXMLInputStream,
  								  String sEncoding, Properties oProps)
    throws IOException, FileNotFoundException, UnsupportedEncodingException,
           NullPointerException, TransformerException, TransformerConfigurationException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin StylesheetCache.transform([InputStream], [InputStream], "+sEncoding+", [Properties])");
      DebugFile.incIdent();
    }

    if (null==oStyleSheetStream) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("StylesheetCache.transform() XSL input stream may not be null");
    }

    if (null==oXMLInputStream) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("StylesheetCache.transform() XML input stream may not be null");
    }

    ByteArrayOutputStream oOutputStream = new ByteArrayOutputStream();

    Transformer oTransformer;
    final String sXSLSystemId = oProps.getProperty("XSLSystemId");

    if (sXSLSystemId==null) {
      TransformerFactory oFactory = TransformerFactory.newInstance();
      StreamSource oStreamSrc = new StreamSource(oStyleSheetStream);
      Templates oTemplates = oFactory.newTemplates(oStreamSrc);
      oTransformer = oTemplates.newTransformer();
    } else {
      if (oCache.containsKey(sXSLSystemId)) {
    	oTransformer = StylesheetCache.newTransformer(sXSLSystemId);
      } else {
        TransformerFactory oFactory = TransformerFactory.newInstance();
        StreamSource oStreamSrc = new StreamSource(oStyleSheetStream);
        oStreamSrc.setSystemId(oProps.getProperty("XSLSystemId"));
        Templates oTemplates = oFactory.newTemplates(oStreamSrc);
        oTransformer = oTemplates.newTransformer();    	  
      }
    }

    if (null!=oProps) setParameters(oTransformer, oProps);
    StreamSource oStreamSrcXML = new StreamSource(oXMLInputStream);
    if (oProps.getProperty("XMLSystemId")!=null) oStreamSrcXML.setSystemId(oProps.getProperty("XMLSystemId"));
    StreamResult oStreamResult = new StreamResult(oOutputStream);
    if (DebugFile.trace) DebugFile.writeln("Transformer.transform(StreamSource,StreamResult)");
    oTransformer.transform(oStreamSrcXML, oStreamResult);
    oStreamSrcXML = null;
    oXMLInputStream.close();
    String sRetVal = oOutputStream.toString(sEncoding);
    if (DebugFile.trace) {
      if (null==sRetVal)
        DebugFile.writeln("Transformer.transform() returned null");
      else
        DebugFile.writeln("Transformer.transform() returned "+String.valueOf(sRetVal.length())+" characters");
    }
    oStreamResult = null;
    oOutputStream.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End StylesheetCache.transform()");
    }
    return sRetVal;
  } // transform

  // ---------------------------------------------------------------------------

  /**
   * Perform XSLT transformation
   * @param oStyleSheetStream Stream to XSL style sheet
   * @param sXMLInput Input String with XML source data
   * @param oProps Parameters for Transformer. The substring "param_"
   * will be added as a preffix to each property name passed as parameter.
   * So if you pass a property named "workarea" it must be retrieved from XSL
   * as &lt;xsl:param name="param_workarea"/&gt;
   * @return String Transformed document
   * @throws NullPointerException if sXMLInput or oProps are <b>null</b>
   * @throws FileNotFoundException if sStyleSheetPath does not exist
   * @throws IOException
   * @throws UnsupportedEncodingException
   * @throws TransformerException
   * @throws TransformerConfigurationException
   * @since 5.0
   */
  public static String transform (InputStream oStyleSheetStream, String sXMLInput, Properties oProps)
    throws IOException, FileNotFoundException, UnsupportedEncodingException,
           NullPointerException, TransformerException, TransformerConfigurationException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin StylesheetCache.transform([InputStream], String, Properties)");
      DebugFile.incIdent();
    }

    if (null==oStyleSheetStream) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("StylesheetCache.transform() XSL input stream may not be null");
    }

    if (null==sXMLInput) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("StylesheetCache.transform() XML input String may not be null");
    }

    // ****************************************
    // Get character encoding of input XML data
    String sEncoding;
    int iEnc = Gadgets.indexOfIgnoreCase(sXMLInput, "encoding");
    if (iEnc<0) {
      if (DebugFile.trace) DebugFile.writeln("No explicit encoding found, setting default to ISO8859_1");
      sEncoding = "ISO8859_1";
    } else {
      int iBeg = iEnc+8;
      int iEnd;
      while (sXMLInput.charAt(iBeg)==' ' || sXMLInput.charAt(iBeg)=='=') iBeg++;
      while (sXMLInput.charAt(iBeg)==' ') iBeg++;
      if (sXMLInput.charAt(iBeg)=='"') {
        iEnd = ++iBeg;
        while (sXMLInput.charAt(iEnd)!='"') iEnd++;
      } else {
        iEnd = iBeg;
        while (sXMLInput.charAt(iEnd)!=' ' && sXMLInput.charAt(iEnd)!='?') iEnd++;
      } // fi
      sEncoding = sXMLInput.substring(iBeg, iEnd);
    } // fi
    // ****************************************

    if (DebugFile.trace) {
      DebugFile.writeln("XML input file encoding is "+sEncoding);
    }

    ByteArrayInputStream oXMLInputStream = new ByteArrayInputStream(sXMLInput.getBytes(sEncoding));
    String sRetVal = transform(oStyleSheetStream, oXMLInputStream, sEncoding, oProps);    
	oXMLInputStream.close();
	
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End StylesheetCache.transform()");
    }

    return sRetVal;
  } // transform

  // ---------------------------------------------------------------------------

  /**
   * Validate an XML document using an XSD schema
   * @param oXsd InputStream to XSD schema
   * @param oXml InputStream to XML document
   * @return String An empty string if validation was successful or text describing the error found
   * @since 7.0
   */
  
  public String validate(InputStream oXsd, InputStream oXml) {
    String sRetVal;
	try {
	  SchemaFactory factory = SchemaFactory.newInstance("http://www.w3.org/2001/XMLSchema");
	  Schema schema = factory.newSchema(new StreamSource(oXsd));
	  Validator validator = schema.newValidator();
	  validator.validate(new StreamSource(oXml));
	  sRetVal = "";
	} catch (Exception xcpt) {
      sRetVal = xcpt.getMessage();
	}	
	return sRetVal;
  }
  
  // ---------------------------------------------------------------------------
  
  /**
   * Clear XLS Stylesheets cache
   * @since 7.0
   */
  public static void clearCache () {
    oCache.clear();
  }
  
  // ---------------------------------------------------------------------------

  static class SheetEntry {
    long lastModified;
    Templates templates;

    SheetEntry (long lLastModified, Templates oTemplats) {
      lastModified = lLastModified;
      templates = oTemplats;
    }
  } // SheetEntry

  private static WeakHashMap<String,SheetEntry> oCache = new WeakHashMap<String,SheetEntry>();
} // StylesheetCache
