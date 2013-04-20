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

import java.lang.ClassNotFoundException;
import java.lang.IllegalAccessException;
import java.lang.StringBuffer;

import java.util.Vector;
import java.util.Properties;

import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;

import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.StringWriter;
import java.io.ByteArrayOutputStream;
import java.io.UTFDataFormatException;

import java.net.MalformedURLException;

import javax.xml.transform.Transformer;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.SourceLocator;
import javax.xml.transform.OutputKeys;

import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.DOMException;

import dom.DOMDocument;

import org.apache.oro.text.regex.*;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dfs.FileSystem;

import com.knowgate.debug.DebugFile;

import com.knowgate.misc.Gadgets;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;

/**
 * PageSet DOMDocument
 * @author Sergio Montoro Ten
 * @version 5.5
 */
public class PageSet extends DOMDocument {

  //-----------------------------------------------------------

  private Microsite oMSite; // Microsite metadata definition
  private String sURI;      // Path to XML data file.
  private TransformerException oLastXcpt; // Last TransformerException raised by
                                          // buildSite() or buildSiteForEdit()

  //***************************************************************
  // Constructors

  private void initMicrosite(String sMsiteURI, boolean bValidateXML)
    throws ClassNotFoundException, Exception, IllegalAccessException,FileNotFoundException {

    if (DebugFile.trace) DebugFile.writeln("PageSet.initMicrosite(" + sMsiteURI + ",schema-validation=" + String.valueOf(bValidateXML) + ")");

    // Load Microsite

    if (sMsiteURI.startsWith("/") || sMsiteURI.startsWith("\\")) {

      File oMFile = new File(sMsiteURI);

      if (!oMFile.exists()) {
        if (DebugFile.trace) DebugFile.writeln("FileNotFoundException "+sMsiteURI);
        throw new FileNotFoundException (sMsiteURI + " not found");
      }

      oMFile = null;

      oMSite = MicrositeFactory.getInstance("file://" + sMsiteURI, bValidateXML);
    }
    else {
      oMSite = MicrositeFactory.getInstance(sMsiteURI, bValidateXML);
    }
  }

 /**
  * Create empty PageSet from a Microsite.
  * XML validation is disabled.
  * @param sMsiteURI Microsite XML file URI
  * @throws ClassNotFoundException
  * @throws IllegalAccessException
  * @throws FileNotFoundException
  */
  public PageSet(String sMsiteURI)
    throws ClassNotFoundException, IllegalAccessException, FileNotFoundException, Exception {

    initMicrosite(sMsiteURI, this.getValidation());

    sURI = null;
  } // PageSet()

  /**
   * Create empty PageSet from a Microsite
   * @param sMsiteURI Microsite XML file URI
   * (for example file:///opt/knowgate/storage/xslt/templates/Comtemporary.xml)
   * @param bValidateXML <b>true</b> if XML validation with W3C schemas is to be done,
   * <b>false</b> is no validation is to be done.
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   * @throws FileNotFoundException
   */
  public PageSet(String sMsiteURI, boolean bValidateXML)
    throws ClassNotFoundException, Exception, IllegalAccessException, FileNotFoundException {
    super("UTF-8", bValidateXML, false);

    if (DebugFile.trace) DebugFile.writeln("new PageSet(" + sMsiteURI + ",schema-validation=" + String.valueOf(bValidateXML) + ")");

    initMicrosite(sMsiteURI, bValidateXML);
    sURI = null;
  } // PageSet()

  /**
   * Create PageSet from a Microsite and load data from an XML file.
   * @param sMsiteURI Microsite XML file URI
   * @param sPageSetURI PageSet XML file URI
   * (for example file:///opt/knowgate/storage/domains/1026/workareas/f7f055ca39854673b17518ec5f87de3b/apps/Mailwire/data/Newsletter01.xml)
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   */
  public PageSet(String sMsiteURI, String sPageSetURI)
    throws ClassNotFoundException, Exception, IllegalAccessException, FileNotFoundException {

    if (DebugFile.trace) DebugFile.writeln("new PageSet(" + sMsiteURI + "," + sPageSetURI + ")");

    File oPFile;

    if (sMsiteURI.startsWith("file://"))
      initMicrosite(sMsiteURI, this.getValidation());
    else
      initMicrosite("file://" + sMsiteURI, this.getValidation());

    sURI = sPageSetURI;

    if (sPageSetURI.startsWith("file://")) {
      oPFile = new File(sPageSetURI.substring(7));

      if (!oPFile.exists()) {
        if (DebugFile.trace) DebugFile.writeln("FileNotFoundException "+sPageSetURI.substring(7));
        throw new FileNotFoundException (sPageSetURI.substring(7) + " not found");
      }

      if (DebugFile.trace) DebugFile.writeln("parseURI (" + sPageSetURI  + ");");

      parseURI(sPageSetURI, "UTF-8");
    }
    else {
      oPFile = new File(sPageSetURI);

      if (!oPFile.exists()) {
        if (DebugFile.trace) DebugFile.writeln("FileNotFoundException "+sPageSetURI);
        throw new FileNotFoundException (sPageSetURI + " not found");
      }

      if (DebugFile.trace) DebugFile.writeln("parseURI (file://" + sPageSetURI  + ");");

      parseURI("file://" + sPageSetURI, "UTF-8");
    }
    // fi (sPageSetURI.startsWith("file://"))

    oPFile = null;

  } // PageSet()

  /**
   * Create PageSet from a Microsite and load data from an XML file.
   * @param sMsiteURI Microsite XML file URI
   * @param sPageSetURI PageSet XML file URI
   * @param bValidateXML <b>true</b> if XML validation with W3C schemas is to be done,
   * <b>false</b> is no validation is to be done.
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   */

  public PageSet(String sMsiteURI, String sPageSetURI, boolean bValidateXML)
    throws ClassNotFoundException, Exception, IllegalAccessException, FileNotFoundException {

    super("UTF-8", bValidateXML, false);

    if (DebugFile.trace) DebugFile.writeln("new PageSet(" + sMsiteURI + "," + sPageSetURI + ",schema-validation=" + String.valueOf(bValidateXML) + ")");

    File oPFile;

    if (sMsiteURI.startsWith("file://"))
      initMicrosite(sMsiteURI, bValidateXML);
    else
      initMicrosite("file://" + sMsiteURI, bValidateXML);

    sURI = sPageSetURI;

    if (sPageSetURI.startsWith("file://")) {
      oPFile = new File(sPageSetURI.substring(7));

      if (!oPFile.exists()) {
        if (DebugFile.trace) DebugFile.writeln("FileNotFoundException "+sPageSetURI.substring(7));
        throw new FileNotFoundException (sPageSetURI.substring(7) + " not found");
      }

      parseURI(sPageSetURI, "UTF-8");
    }
    else {
      oPFile = new File(sPageSetURI);

      if (!oPFile.exists()) {
        if (DebugFile.trace) DebugFile.writeln("FileNotFoundException "+sPageSetURI);
        throw new FileNotFoundException (sPageSetURI + " not found");
      }

      parseURI("file://" + sPageSetURI, "UTF-8");
    }
  } // PageSet()

  //-----------------------------------------------------------

  /**
   * Get PageSet &lt;guid&gt; value
   */
  public String guid() {
    Node oPageSetNode = getRootNode().getFirstChild();

    if (oPageSetNode.getNodeName().equals("xml-stylesheet")) oPageSetNode = oPageSetNode.getNextSibling();

    // Devuelve el valor del atributo guid del nodo <pageset>
    return getAttribute(oPageSetNode, "guid");
  }  // guid()

  //-----------------------------------------------------------

  /**
   * Last TransformerException raised by buildSite() or buildSiteForEdit()
   */
  public TransformerException lastException() {
    return oLastXcpt;
  }

  //-----------------------------------------------------------

  public Microsite microsite() {
    return oMSite;
  }

  //-----------------------------------------------------------

  /**
   * GUID of Catalog associated to this PageSet
   * @return Catalog GUID or <b>null</b> if &lt;catalog&gt; node does not exist.
   * @throws DOMException
   */

  public String catalog() throws DOMException {

    Node oCatalogNode;
    String sRetVal;

    if (DebugFile.trace)
      DebugFile.writeln("Begin PageSet.catalog()");

    if (DebugFile.trace) DebugFile.incIdent();

    // Get a reference to top Node
    Node oPageSetNode = getRootNode().getFirstChild();
    if (oPageSetNode.getNodeName().equals("xml-stylesheet")) oPageSetNode = oPageSetNode.getNextSibling();

    // Find <pages> node
    oCatalogNode = seekChildByName(oPageSetNode, "catalog");

    if (oCatalogNode==null)
      sRetVal = null;
    else
      sRetVal = oCatalogNode.getFirstChild().getNodeValue();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSet.catalog() : " + sRetVal);
    }

    return sRetVal;
  } // company()

  //-----------------------------------------------------------

  /**
   * GUID of Company associated to this PageSet
   * @return Company GUID or <b>null</b> if &lt;company&gt; node does not exist.
   * @throws DOMException
   */

  public String company() throws DOMException {

    Node oCompanyNode;
    String sRetVal;

    if (DebugFile.trace)
      DebugFile.writeln("Begin PageSet.company()");

    if (DebugFile.trace) DebugFile.incIdent();

    // Get a reference to top Node
    Node oPageSetNode = getRootNode().getFirstChild();
    if (oPageSetNode.getNodeName().equals("xml-stylesheet")) oPageSetNode = oPageSetNode.getNextSibling();

    // Find <pages> node
    oCompanyNode = seekChildByName(oPageSetNode, "company");

    if (oCompanyNode==null)
      sRetVal = null;
    else
      sRetVal = oCompanyNode.getFirstChild().getNodeValue();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSet.company() : " + sRetVal);
    }

    return sRetVal;
  } // catalog()

  // ---------------------------------------------------------------------------

  /**
   * Get a Page from this PageSet
   * @param sPageId GUID of page to be retrieved
   * @return Page object or <b>null</b> if no page with such GUID was found at XML file
   * @throws DOMException If <pages> node is not found
   * @throws NullPointerException If sPageId is <b>null</b>
   */

  public Page page(String sPageId) throws DOMException,NullPointerException {

    Node oPagesNode;
    NodeList oNodeList;
    Page oCurrent;
    Page oRetVal = null;

    if (DebugFile.trace)
      DebugFile.writeln("Begin PageSet.page(" + sPageId + ")");

    if (null==sPageId)
      throw new NullPointerException("PageSet.page(), parameter sPageId may not be null");

    if (DebugFile.trace) DebugFile.incIdent();

    // Get a reference to top Node
    Node oPageSetNode = getRootNode().getFirstChild();
    if (oPageSetNode.getNodeName().equals("xml-stylesheet")) oPageSetNode = oPageSetNode.getNextSibling();

    // Find <pages> node
    oPagesNode = seekChildByName(oPageSetNode, "pages");

    if (oPagesNode==null) {
      if (DebugFile.trace) {
        DebugFile.writeln("DOMException <pages> node not found");
        ByteArrayOutputStream baOut = new ByteArrayOutputStream();
        try { print(baOut); } catch (IOException ignore) {}
        DebugFile.write("\n"+baOut.toString()+"\n");
      }
      throw new DOMException(DOMException.NOT_FOUND_ERR, "<pages> node not found");
    }

    oNodeList = ((Element)oPagesNode).getElementsByTagName("page");

    if (oNodeList.getLength()>0) {

      // Cast DOM nodes to Page objects inside Vector
      for (int i=0; i<oNodeList.getLength() && (null==oRetVal); i++) {
        oCurrent = new Page(oNodeList.item(i), this);
        if (sPageId.equals(oCurrent.guid()))
          oRetVal = oCurrent;
      } // next
    } // fi (oNodeList.getLength()>0)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSet.page() : " + oRetVal);
    }

    return oRetVal;
  } // page()

  //-----------------------------------------------------------

  /**
   * Get pages for this PageSet
   * @return vector of Page objects
   * @throws DOMException If <pages> node is not found
   */
  public Vector<Page> pages() throws DOMException {
    Node oPagesNode;
    NodeList oNodeList;
    Vector<Page> oLinkVctr;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin PageSet.pages()");
      DebugFile.incIdent();
    }

    // get a reference to top Node
    Node oPageSetNode = getRootNode().getFirstChild();
    if (oPageSetNode.getNodeName().equals("xml-stylesheet")) oPageSetNode = oPageSetNode.getNextSibling();

    // Buscar el nodo <pages>
    oPagesNode = seekChildByName(oPageSetNode, "pages");

    if (oPagesNode==null)
      throw new DOMException(DOMException.NOT_FOUND_ERR, "<pages> node not found");

    oNodeList = ((Element)oPagesNode).getElementsByTagName("page");

    if (oNodeList.getLength()>0) {
      // Create Vector
      oLinkVctr = new Vector(oNodeList.getLength());

      // Cast DOM nodes to Page objects inside Vector
      for (int i=0; i<oNodeList.getLength(); i++)
        oLinkVctr.add(new Page (oNodeList.item(i), this));
    }
    else
      oLinkVctr = new Vector();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSet.pages()");
    }

    return oLinkVctr;
  } // pages()

  //-----------------------------------------------------------

  /**
   * Get Addresses for this PageSet
   * @return vector of Page objects
   * @throws DOMException If <addresses> node is not found
   */
  public Vector<Page> addresses() throws DOMException {
    Node oPagesNode;
    NodeList oNodeList;
    Vector oLinkVctr;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin PageSet.pages()");
      DebugFile.incIdent();
    }

    // get a reference to top Node
    Node oPageSetNode = getRootNode().getFirstChild();
    if (oPageSetNode.getNodeName().equals("xml-stylesheet")) oPageSetNode = oPageSetNode.getNextSibling();

    // Buscar el nodo <pages>
    oPagesNode = seekChildByName(oPageSetNode, "addresses");

    if (oPagesNode==null)
      throw new DOMException(DOMException.NOT_FOUND_ERR, "<addresses> node not found");

    oNodeList = ((Element)oPagesNode).getElementsByTagName("address");

    if (oNodeList.getLength()>0) {
      // Create Vector
      oLinkVctr = new Vector(oNodeList.getLength());

      // Cast DOM nodes to Page objects inside Vector
      for (int i=0; i<oNodeList.getLength(); i++)
        oLinkVctr.add(new Page (oNodeList.item(i), this));
    }
    else
      oLinkVctr = new Vector();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSet.addresses()");
    }

    return oLinkVctr;
  } // addresses()

  //-----------------------------------------------------------

  /*
  private LinkedList matchChildsByTag(Node oParent, String sPattern) {
    // Get a list of pointers to nodes with child <tag>
    // matches a regular expression pattern.
    // Parameters:
    //     oParent  -> Parent Node
    //     sPattern -> Pattern to match

    Node oCurrentNode = null; // Iterador de nodos hijo
    Node oTag = null; // Nodo nieto <tag>
    NodeList oChilds = oParent.getChildNodes(); // Lista total de nodos hijo
    int iMaxNodes = oChilds.getLength(); // Cuenta de nodos hijo
    LinkedList oList = new LinkedList(); // Lista resultado

    Pattern oPattern = null;
    PatternMatcher oMatcher = new Perl5Matcher();
    PatternCompiler oCompiler = new Perl5Compiler();

    try {
      // Compile regular expression at Pattern Matcher
      oPattern = oCompiler.compile(sPattern);
    } catch(MalformedPatternException e) {}

    // Iterate throught child nodes
    for (int iNode=0; iNode<iMaxNodes; iNode++) {
      // Assign oCurrentNode as an alias for the current node.
      oCurrentNode = oChilds.item(iNode);
      if(Node.ELEMENT_NODE==oCurrentNode.getNodeType()) {

        // Seek grandchild by name
        oTag = seekChildByName(oCurrentNode, "tag");
        if (null!=oTag)
          // If pattern matches add child to list
          if (oMatcher.matches(getTextValue((Element)oTag), oPattern))
            oList.addLast(oCurrentNode);
      } // fi(ELEMENT_NODE)
    } // next(iNode)

    return oList;
  }  // matchChildsByTag
  */

  //-----------------------------------------------------------

  /**
   * <p>Generate XSL Transformation output for PageSet.</p>
   * @param sBasePath Path to directory containing XSL stylesheets
   * @param sOutputPath Path to output directory where generated files shall be saved.
   * @param oEnvironmentProps Environment Properties
   * @param oUserProps User Properties
   * @return
   * @throws IOException
   * @throws TransformerException
   * @throws TransformerConfigurationException
   */
  public Vector buildSite(String sBasePath, String sOutputPath, Properties oEnvironmentProps, Properties oUserProps)
      throws FileNotFoundException,IOException, DOMException, TransformerException, TransformerConfigurationException {

    Transformer oTransformer;
    StreamResult oStreamResult;
    StreamSource oStreamSrcXML;
    InputStream oXMLStream = null;
    String sMedia;
    Page oCurrentPage;
    long lElapsed = 0;

    final String sSep = System.getProperty("file.separator");

    if (DebugFile.trace) {
      lElapsed = System.currentTimeMillis();

      DebugFile.writeln("Begin PageSet.buildSite(" + sBasePath + "," + sOutputPath + "...)");
      DebugFile.incIdent();
    }

    oLastXcpt = null;

    if (!sBasePath.endsWith(sSep)) sBasePath += sSep;

    Vector vPages = pages();

    // Move to containers node
    if (DebugFile.trace)
      DebugFile.writeln("seekChildByName(,[Node], \"containers\")");

    Node oContainers = oMSite.seekChildByName(oMSite.getRootNode().getFirstChild(), "containers");

    if (oContainers==null) {
      if (DebugFile.trace)
        DebugFile.writeln("ERROR: <containers> node not found.");

      throw new DOMException(DOMException.NOT_FOUND_ERR, "<containers> node not found");
    }

    // Load XML data stream only once for all containers
    if (DebugFile.trace)
      DebugFile.writeln("oXMLStream = new FileInputStream(" + sURI + ")");

    // For each Page do XSL Transformation
    for (int c=0; c<vPages.size(); c++) {
      oCurrentPage = (Page) vPages.get(c);

      oXMLStream = new FileInputStream(sURI);
      oStreamSrcXML = new StreamSource(oXMLStream);

      // XSL Transformation
      try {
        if (DebugFile.trace)
          DebugFile.writeln("oTransformer = StylesheetCache.newTransformer(" + sBasePath + "xslt" + sSep + "templates" + sSep + oMSite.name() + sSep + oCurrentPage.template() + ")");

        // Get a copy of Stylesheet from cache
        oTransformer = StylesheetCache.newTransformer(sBasePath + "xslt" + sSep + "templates" + sSep + oMSite.name() + sSep + oCurrentPage.template());

        sMedia = oTransformer.getOutputProperty(OutputKeys.MEDIA_TYPE);
        if (null==sMedia)
          sMedia = "html";
        else
          sMedia = sMedia.substring(sMedia.indexOf('/')+1);

        if (DebugFile.trace)
          DebugFile.writeln("Pages[" + String.valueOf(c) + "].filePath(" + sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "." + sMedia + ")");

        oCurrentPage.filePath(sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "." + sMedia);

        if (DebugFile.trace)
          DebugFile.writeln("oStreamResult = new StreamResult(" + oCurrentPage.filePath() + ")");

        oStreamResult = new StreamResult(oCurrentPage.filePath());

        // Set environment parameters for stylesheet
        StylesheetCache.setParameters(oTransformer, oEnvironmentProps);

        // Set user defined parameters for stylesheet
        StylesheetCache.setParameters(oTransformer, oUserProps);

        // Realizar la transformación
        if (DebugFile.trace)
          DebugFile.writeln("oTransformer.transform(oStreamSrcXML, oStreamResult)");

        oTransformer.setParameter("param_page", ((Page)(vPages.get(c))).getTitle());
        oTransformer.transform(oStreamSrcXML, oStreamResult);

		if (!new File(oCurrentPage.filePath()).exists()) {
          if (DebugFile.trace) {
            DebugFile.writeln("FileNotFoundException: PageSet.buildSite() could not create file "+oCurrentPage.filePath());
            DebugFile.decIdent();
          }
		  throw new FileNotFoundException("PageSet.buildSite() could not create file "+oCurrentPage.filePath());
		} // fi (exists())
      }
      catch (TransformerConfigurationException e) {
        oLastXcpt = e;
        if (DebugFile.trace) DebugFile.writeln("ERROR TransformerConfigurationException " + e.getMessageAndLocation());
      }
      catch (TransformerException e) {
        oLastXcpt = e;
        if (DebugFile.trace) DebugFile.writeln("ERROR TransformerException " + e.getMessageAndLocation());
      }

      oTransformer = null;
      oStreamResult = null;
    } // next (c)

    oXMLStream.close();

    if (DebugFile.trace) {
      DebugFile.writeln("done in " + String.valueOf(System.currentTimeMillis()-lElapsed) + " miliseconds");

      DebugFile.decIdent();
      DebugFile.writeln("End PageSet.buildSite()");
    }

    return vPages;
  } // buildSite()


  // ---------------------------------------------------------------------------

  public Page buildPageForEdit(String sPageGUID, String sBasePath,
                               String sOutputPath, String sCtrlPath,
                               String sMenuPath, String sIntegradorPath,
                               String sSelPageOptions,
                               Properties oEnvironmentProps, Properties oUserProps)

    throws FileNotFoundException, IOException, DOMException, TransformerException,
           TransformerConfigurationException, MalformedURLException {

    Transformer oTransformer;
    StreamResult oStreamResult;
    StreamSource oStreamSrcXML;
    StringWriter oStrWritter;
    File oXMLFile,oXSLFile;
    InputStream oXMLStream = null;
    String sTransformed;
    StringBuffer oPostTransform;
    String sMedia;
    String sXSLFile;
    Page oCurrentPage;

    int iCloseHead, iOpenBody, iCloseBody;
    String sCharBuffer;
    long lElapsed = 0;

    final String sSep = System.getProperty("file.separator");

    if (DebugFile.trace) {
      lElapsed = System.currentTimeMillis();

      DebugFile.writeln("Begin Pageset.buildPageForEdit(" + sBasePath + "," + sOutputPath + "," + sCtrlPath + "," + sMenuPath + ")");
      DebugFile.incIdent();
    }

    FileSystem oFS = new FileSystem();

    if (!sBasePath.endsWith(sSep)) sBasePath += sSep;

    String sWebServer = oEnvironmentProps.getProperty("webserver", "");

    if (DebugFile.trace && sWebServer.length()==0) DebugFile.writeln("WARNING: webserver property not set at EnvironmentProperties");

    if (!sWebServer.endsWith("/")) sWebServer+="/";


    // Posicionarse en el nodo de contenedores
    Node oContainers = oMSite.seekChildByName(oMSite.getRootNode().getFirstChild(), "containers");

    if (oContainers==null) {
      if (DebugFile.trace)
        DebugFile.writeln("ERROR: <containers> node not found.");

      throw new DOMException(DOMException.NOT_FOUND_ERR, "<containers> node not found");
    }

    // Cagar el stream de datos XML una sola vez
    if (DebugFile.trace)
      DebugFile.writeln("new FileInputStream(" + (sURI.startsWith("file://") ? sURI.substring(7) : sURI) + ")");

    // Para cada contenedor (página) realizar la transformación XSLT

      oCurrentPage = this.page(sPageGUID);

	  oXMLFile = new File (sURI.startsWith("file://") ? sURI.substring(7) : sURI);
	  if (!oXMLFile.exists()) {
        if (DebugFile.trace) DebugFile.decIdent(); 
	  	throw new FileNotFoundException("PageSet.buildPageForEdit() File not found "+sURI);
	  }

      oXMLStream = new FileInputStream(oXMLFile);
      oStreamSrcXML = new StreamSource(oXMLStream);

      // Asignar cada stream de salida a su stream temporal
      oStrWritter = new StringWriter();
      oStreamResult = new StreamResult(oStrWritter);

      // Transformacion XSLT
      try {

        // Obtener la hoja de estilo desde el cache
        sXSLFile = sBasePath + "xslt" + sSep + "templates" + sSep + oMSite.name() + sSep + oCurrentPage.template();
	    oXSLFile = new File (sXSLFile);
	    if (!oXSLFile.exists()) {
          if (DebugFile.trace) DebugFile.decIdent(); 
	  	  throw new FileNotFoundException("PageSet.buildPageForEdit() File not found "+sXSLFile+" maybe there is a mismatch between the microsite name and the directory name where it is placed, or between the template name and the actual .xsl file name");
	    }

        oTransformer = StylesheetCache.newTransformer(sXSLFile);

        sMedia = oTransformer.getOutputProperty(OutputKeys.MEDIA_TYPE);

        if (DebugFile.trace) DebugFile.writeln(OutputKeys.MEDIA_TYPE + "=" + sMedia);

        if (null==sMedia)
          sMedia = "html";
        else
          sMedia = sMedia.substring(sMedia.indexOf('/')+1);

        if (null==oCurrentPage.getTitle())
          throw new NullPointerException("Page title is null");

        if (DebugFile.trace)
          DebugFile.writeln("Page.filePath(" + sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "." + sMedia + ")");

        oCurrentPage.filePath(sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "." + sMedia);

        // Set environment parameters for stylesheet
        StylesheetCache.setParameters (oTransformer, oEnvironmentProps);

        // Set user defined parameters for stylesheet
        StylesheetCache.setParameters (oTransformer, oUserProps);

        // Paso el title de la pagina como parametro
        oTransformer.setParameter ("param_page", oCurrentPage.getTitle());

        // Realizar la transformación
        oTransformer.transform (oStreamSrcXML, oStreamResult);

      }
      catch (TransformerConfigurationException e) {
         oLastXcpt = e;
         sMedia = null;

         SourceLocator sl = e.getLocator();

         if (DebugFile.trace) {
           if (sl == null) {
             DebugFile.writeln("ERROR TransformerConfigurationException " + e.getMessage());
           }
           else {
             DebugFile.writeln("ERROR TransformerConfigurationException " + e.getMessage() + " line=" + String.valueOf(sl.getLineNumber()) + " column=" + String.valueOf(sl.getColumnNumber()));
           }
         }
      }
      catch (TransformerException e) {
        oLastXcpt = e;
        sMedia = null;

        if (DebugFile.trace) DebugFile.writeln("ERROR TransformerException " + e.getMessageAndLocation());
      }

      oTransformer = null;
      oStreamResult = null;

      // Asignar un String con el fuente XML transformado
      sTransformed = oStrWritter.toString();

      if (DebugFile.trace) DebugFile.writeln("transformation length=" + String.valueOf(sTransformed.length()));

      // Buscar el fin de tag </head>
      if (sTransformed.length()>0) {
        iCloseHead = sTransformed.indexOf("</head");
        if (iCloseHead<0) iCloseHead = sTransformed.indexOf("</HEAD");

		if (iCloseHead<0) {
          if (DebugFile.trace) {
            DebugFile.writeln("Stylesheet lacks </head> tag");
            DebugFile.decIdent();
          }		  
		  throw new TransformerException("Stylesheet lacks </head> tag");
		} // fi

        // Buscar el inicio de tag <body>
        iOpenBody = sTransformed.indexOf("<body", iCloseHead);
        if (iOpenBody<0) iOpenBody = sTransformed.indexOf("<BODY", iCloseHead);

		if (iOpenBody<0) {
          if (DebugFile.trace) {
            DebugFile.writeln("Stylesheet lacks <body> tag");
            DebugFile.decIdent();
          }		  
		  throw new TransformerException("Stylesheet lacks <body> tag");
		} // fi
		
        iCloseBody = sTransformed.indexOf(">", iOpenBody+5);
        for (char s = sTransformed.charAt(iCloseBody+1); s=='\r' || s=='\n' || s==' ' || s=='\t'; s = sTransformed.charAt(++iCloseBody)) ;

        // Crear un buffer intermedio para mayor velocidad de concatenado
        oPostTransform = new StringBuffer(sTransformed.length()+4096);

        // Incrustar las llamadas al Integrador en el lugar apropiado del fuente
        oPostTransform.append(sTransformed.substring(0, iCloseHead));
        oPostTransform.append("\n<script language=\"JavaScript\" type=\"text/javascript\" src=\"" + sMenuPath + "\"></script>");
        oPostTransform.append("\n<script language=\"JavaScript\" type=\"text/javascript\" src=\"" + sIntegradorPath + "\"></script>\n");
        oPostTransform.append(sTransformed.substring(iCloseHead, iCloseHead+7));
        oPostTransform.append(sTransformed.substring(iOpenBody, iCloseBody));

        // Cargar el código fuente del control de visulización del Integrador
        try {
          sCharBuffer = oFS.readfilestr(sCtrlPath, "UTF-8");

          if (DebugFile.trace) DebugFile.writeln(String.valueOf(sCharBuffer.length()) + " characters readed");
        }
        catch (com.enterprisedt.net.ftp.FTPException ftpe) {
          throw new IOException (ftpe.getMessage());
        }

        try {
          if (DebugFile.trace) DebugFile.writeln("Gadgets.replace(" + sCtrlPath + ",http://demo.hipergate.com/," + sWebServer + ")");

          Gadgets.replace(sCharBuffer, "http://demo.hipergate.com/", sWebServer);

        } catch (org.apache.oro.text.regex.MalformedPatternException e) { }

        oPostTransform.append("<!--Begin " + sCtrlPath + "-->\n");

        oPostTransform.append(sCharBuffer);
        sCharBuffer = null;

        oPostTransform.append("\n<!--End " + sCtrlPath + "-->\n");

        oPostTransform.append(sTransformed.substring(iCloseBody));
      }
      else {
        oPostTransform = new StringBuffer("Page " + oCurrentPage.getTitle() + " could not be rendered.");
        if (oLastXcpt!=null) oPostTransform.append("<BR>" + oLastXcpt.getMessageAndLocation());
      }

      // Escribir el resultado con las llamadas incrustadas en el archivo de salida

      if (sSelPageOptions.length()==0)
        oFS.writefilestr(sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "_." + sMedia, oPostTransform.toString(), "UTF-8");
      else
        try {

          oFS.writefilestr(sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "_." + sMedia, Gadgets.replace(oPostTransform.toString(), ":selPageOptions", sSelPageOptions), "UTF-8");

        } catch (Exception e) {/* Ignore MalformedPatternException, is never thrown */ }

      // Desreferenciar los buffers intermedios para liberar memoria lo antes posible
      oPostTransform = null;
      sTransformed = null;

    oXMLStream.close();

    if (DebugFile.trace) {
      DebugFile.writeln("done in " + String.valueOf(System.currentTimeMillis()-lElapsed) + " miliseconds");

      DebugFile.decIdent();
      DebugFile.writeln("End Pageset.buildPageForEdit() : " + oCurrentPage.getTitle());
    }

    return oCurrentPage;
  } // buildPageForEdit()

  //-----------------------------------------------------------

  /**
   * <p>Generate XSL Transformation output with editing layers for PageSet.</p>
   * @param sBasePath Path to directory containing XSL stylesheets
   * @param sOutputPath Path to output directory where generated files shall be saved.
   * @param sCtrlPath Path to source code of the edition layer (tipically /includes/integrador_ctrl.inc file)
   * @param sMenuPath Path to dynamic page that generates the block list (tipically  /webbuilder/wb_mnuintegrador.jsp)
   * @param sIntegradorPath Path to JavaScript functions of edition layer (tipically integrador.js)
   * @param sSelPageOptions If this is a single Page PageSet this parameter must be "",
   *        else it is a list of available pages in HTML <OPTION>...</OPTION> format.
   * @param oEnvironmentProps Environment properties to be replaced at templated
   * @param oUserProps User Properties to be replaced at templated
   * @throws IOException
   * @throws DOMException
   * @throws TransformerException
   * @throws TransformerConfigurationException
   * @throws NullPointerException
   */
  public void buildSiteForEdit(String sBasePath, String sOutputPath,
                               String sCtrlPath, String sMenuPath,
                               String sIntegradorPath, String sSelPageOptions,
                               Properties oEnvironmentProps, Properties oUserProps)

    throws IOException, DOMException, TransformerException,
           TransformerConfigurationException, MalformedURLException {

    Transformer oTransformer;
    StreamResult oStreamResult;
    StreamSource oStreamSrcXML;
    StringWriter oStrWritter;
    InputStream oXMLStream = null;
    String sTransformed;
    StringBuffer oPostTransform;
    String sMedia;
    Page oCurrentPage;

    int iCloseHead, iOpenBody, iCloseBody;
    String sCharBuffer;
    long lElapsed = 0;

    final String sSep = System.getProperty("file.separator");

    if (DebugFile.trace) {
      lElapsed = System.currentTimeMillis();

      DebugFile.writeln("Begin Pageset.buildSiteForEdit(" + sBasePath + "," + sOutputPath + "," + sCtrlPath + "," + sMenuPath + ")");
      DebugFile.incIdent();
    }

    FileSystem oFS = new FileSystem();

    Vector vPages = pages();

    if (!sBasePath.endsWith(sSep)) sBasePath += sSep;

    String sWebServer = oEnvironmentProps.getProperty("webserver", "");

    if (DebugFile.trace && sWebServer.length()==0) DebugFile.writeln("WARNING: webserver property not set at EnvironmentProperties");

    if (!sWebServer.endsWith("/")) sWebServer+="/";


    // Posicionarse en el nodo de contenedores
    Node oContainers = oMSite.seekChildByName(oMSite.getRootNode().getFirstChild(), "containers");

    if (oContainers==null) {
      if (DebugFile.trace)
        DebugFile.writeln("ERROR: <containers> node not found.");

      throw new DOMException(DOMException.NOT_FOUND_ERR, "<containers> node not found");
    }

    // Cagar el stream de datos XML una sola vez
    if (DebugFile.trace)
      DebugFile.writeln("new FileInputStream(" + (sURI.startsWith("file://") ? sURI.substring(7) : sURI) + ")");


    // Para cada contenedor (página) realizar la transformación XSLT
    for (int c=0; c<vPages.size(); c++) {

      oCurrentPage = (Page) vPages.get(c);

      oXMLStream = new FileInputStream(sURI.startsWith("file://") ? sURI.substring(7) : sURI);
      oStreamSrcXML = new StreamSource(oXMLStream);

      // Asignar cada stream de salida a su stream temporal
      oStrWritter = new StringWriter();
      oStreamResult = new StreamResult(oStrWritter);

      // Transformacion XSLT
      try {

        // Obtener la hoja de estilo desde el cache
        oTransformer = StylesheetCache.newTransformer(sBasePath + "xslt" + sSep + "templates" + sSep + oMSite.name() + sSep + oCurrentPage.template());

        sMedia = oTransformer.getOutputProperty(OutputKeys.MEDIA_TYPE);

        if (DebugFile.trace) DebugFile.writeln(OutputKeys.MEDIA_TYPE + "=" + sMedia);

        if (null==sMedia)
          sMedia = "html";
        else
          sMedia = sMedia.substring(sMedia.indexOf('/')+1);

        if (null==oCurrentPage.getTitle())
          throw new NullPointerException("Page " + String.valueOf(c) + " title is null");

        if (DebugFile.trace)
          DebugFile.writeln("Page.filePath(" + sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "." + sMedia + ")");

        oCurrentPage.filePath(sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "." + sMedia);

        // Set environment parameters for stylesheet
        StylesheetCache.setParameters (oTransformer, oEnvironmentProps);

        // Set user defined parameters for stylesheet
        StylesheetCache.setParameters (oTransformer, oUserProps);

        // Paso el title de la pagina como parametro
        oTransformer.setParameter ("param_page", ((Page)(vPages.get(c))).getTitle());

        // Realizar la transformación
        oTransformer.transform (oStreamSrcXML, oStreamResult);

      }
      catch (TransformerConfigurationException e) {
         oLastXcpt = e;
         sMedia = null;

         SourceLocator sl = e.getLocator();

         if (DebugFile.trace) {
           if (sl == null) {
             DebugFile.writeln("ERROR TransformerConfigurationException " + e.getMessage());
           }
           else {
             DebugFile.writeln("ERROR TransformerConfigurationException " + e.getMessage() + " line=" + String.valueOf(sl.getLineNumber()) + " column=" + String.valueOf(sl.getColumnNumber()));
           }
         }
      }
      catch (TransformerException e) {
        oLastXcpt = e;
        sMedia = null;

        if (DebugFile.trace) DebugFile.writeln("ERROR TransformerException " + e.getMessageAndLocation());
      }

      oTransformer = null;
      oStreamResult = null;

      // Asignar un String con el fuente XML transformado
      sTransformed = oStrWritter.toString();

      if (DebugFile.trace) DebugFile.writeln("transformation length=" + String.valueOf(sTransformed.length()));

      // Buscar el fin de tag </head>
      if (sTransformed.length()>0) {
        iCloseHead = sTransformed.indexOf("</head");
        if (iCloseHead<0) iCloseHead = sTransformed.indexOf("</HEAD");

        // Buscar el inicio de tag <body>
        iOpenBody = sTransformed.indexOf("<body", iCloseHead);
        if (iOpenBody<0) iOpenBody = sTransformed.indexOf("<BODY", iCloseHead);

        iCloseBody = sTransformed.indexOf(">", iOpenBody+5);
        for (char s = sTransformed.charAt(iCloseBody+1); s=='\r' || s=='\n' || s==' ' || s=='\t'; s = sTransformed.charAt(++iCloseBody)) ;

        // Crear un buffer intermedio para mayor velocidad de concatenado
        oPostTransform = new StringBuffer(sTransformed.length()+4096);

        // Incrustar las llamadas al Integrador en el lugar apropiado del fuente
        oPostTransform.append(sTransformed.substring(0, iCloseHead));
        oPostTransform.append("\n<script language=\"JavaScript\" src=\"" + sMenuPath + "\"></script>");
        oPostTransform.append("\n<script language=\"JavaScript\" src=\"" + sIntegradorPath + "\"></script>\n");
        oPostTransform.append(sTransformed.substring(iCloseHead, iCloseHead+7));
        oPostTransform.append(sTransformed.substring(iOpenBody, iCloseBody));

        // Cargar el código fuente del control de visulización del Integrador
        try {
          sCharBuffer = oFS.readfilestr(sCtrlPath, "UTF-8");

          if (DebugFile.trace) DebugFile.writeln(String.valueOf(sCharBuffer.length()) + " characters readed");
        }
        catch (com.enterprisedt.net.ftp.FTPException ftpe) {
          throw new IOException (ftpe.getMessage());
        }

        try {
          if (DebugFile.trace) DebugFile.writeln("Gadgets.replace(" + sCtrlPath + ",http://demo.hipergate.com/," + sWebServer + ")");

          Gadgets.replace(sCharBuffer, "http://demo.hipergate.com/", sWebServer);
        } catch (org.apache.oro.text.regex.MalformedPatternException e) { }

        oPostTransform.append("<!--Begin " + sCtrlPath + "-->\n");

        oPostTransform.append(sCharBuffer);
        sCharBuffer = null;

        oPostTransform.append("\n<!--End " + sCtrlPath + "-->\n");

        oPostTransform.append(sTransformed.substring(iCloseBody+1));
      }
      else {
        oPostTransform = new StringBuffer("Page " + ((Page)vPages.get(c)).getTitle() + " could not be rendered.");
        if (oLastXcpt!=null) oPostTransform.append("<BR>" + oLastXcpt.getMessageAndLocation());
      }

      // Escribir el resultado con las llamadas incrustadas en el archivo de salida
      if (DebugFile.trace) DebugFile.writeln("new FileWriter(" + sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "_." + sMedia + ")");


      if (sSelPageOptions.length()==0)
        oFS.writefilestr(sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "_." + sMedia, oPostTransform.toString(), "UTF-8");
      else
        try {
          oFS.writefilestr(sOutputPath + oCurrentPage.getTitle().replace(' ','_') + "_." + sMedia, Gadgets.replace(oPostTransform.toString(), ":selPageOptions", sSelPageOptions), "UTF-8");

        } catch (Exception e) {/* Ignore MalformedPatternException, is never thrown */ }

      // Desreferenciar los buffers intermedios para liberar memoria lo antes posible
      oPostTransform = null;
      sTransformed = null;
    } // next (c)

    oXMLStream.close();

    if (DebugFile.trace) {
      DebugFile.writeln("done in " + String.valueOf(System.currentTimeMillis()-lElapsed) + " miliseconds");

      DebugFile.decIdent();
      DebugFile.writeln("End Pageset.buildSiteForEdit()");
    }
  } // buildSiteForEdit()

  //-----------------------------------------------------------

  private Page findPage(String sPageGUID) {
    Vector oPages = this.pages();
    int iPages = oPages.size();
    Page oPage = null;

    for (int p=0; p<iPages && oPage==null; p++)
      if (sPageGUID.equals(((Page)oPages.get(p)).guid()))
        oPage = (Page)oPages.get(p);

    return oPage;
  } // findPage

  //-----------------------------------------------------------

  /**
   * <p>Add block at the end of a Page</p>
   * @param sFilePath Path to PageSet XML file
   * @param sPageGUID &lt;Page&gt; GUID attribute
   * @param sBlockXML XML of Block to be added
   * @return New Block Id
   * @throws IllegalAccessException
   * @throws IOException
   * @throws ClassNotFoundException
   * @throws NumberFormatException If Identifier attribute <block id="..."> is not an integer number.
   */
  public String addBlock(String sFilePath, String sPageGUID, String sBlockXML)
    throws IllegalAccessException, IOException, ClassNotFoundException,
           NumberFormatException, UTFDataFormatException, Exception {

    String sBlockId;
    Page oPage = null;
    long lElapsed = 0;

    if (DebugFile.trace) {
      lElapsed = System.currentTimeMillis();

      DebugFile.writeln("Begin Pageset.addBlock(" + sFilePath + "," + sPageGUID + ",\n" + sBlockXML + "\n)");
      DebugFile.incIdent();
    }

    sURI = sFilePath;

    parseURI(sFilePath, "UTF-8");

    oPage = findPage(sPageGUID);

    sBlockId = oPage.nextBlockId();

    try {
      sBlockXML = com.knowgate.misc.Gadgets.replace(sBlockXML, "<block>", "<block id=\"" + sBlockId + "\">");
    }
    catch (MalformedPatternException mpe) { }

    new XMLDocument(sFilePath).addNodeAndSave("pageset/pages/page[@guid='" + oPage.guid() + "']/blocks/block/", sBlockXML);

    if (DebugFile.trace) {
      DebugFile.writeln("done in " + String.valueOf(System.currentTimeMillis()-lElapsed) + " miliseconds");

      DebugFile.decIdent();
      DebugFile.writeln("End Pageset.addBlock()");
    }

  return sBlockId;
  } // addBlock

  //-----------------------------------------------------------

  public void save(String sFilePath) throws IOException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Pageset.save("+sFilePath+")");
    }
	
    FileOutputStream oOutFile = new FileOutputStream(sFilePath,false);

    print(oOutFile);

    oOutFile.close();

    if (DebugFile.trace) {
      DebugFile.writeln("End Pageset.save()");
    }
  } // save

  // **********************************************************
  // * Static Methods

  //-----------------------------------------------------------

  /**
   * <p>Merge Company addresses, catalog and other information into a PageSet XML file<p>
   * Addresses are readed from k_addresses table and appended to the XML file after the &lt;pages&gt; node.
   * @param oConn JDBC database connection
   * @param sFilePath Complete path to the PageSet XML data file
   * @param sCompanyGUID GUID of Company which addresses are to be merged into the PageSet XML file
   * @throws SQLException
   * @throws IOException
   */
  public static void mergeCompanyInfo (JDCConnection oConn, String sFilePath, String sCompanyGUID)
    throws SQLException, IOException {

    Statement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("PageSet.mergeCompanyAddresses(JDCConnection," + sFilePath + "," + sCompanyGUID + ")");
      DebugFile.incIdent();
    }

    XMLDocument oXMLDoc = new XMLDocument(sFilePath);

    String sCategoryGUID = "";

    if (DebugFile.trace) {
      DebugFile.writeln("Connection.executeQuery(SELECT " + DB.gu_category + " FROM " + DB.k_x_company_prods + " WHERE " + DB.gu_company + "='" + sCompanyGUID + "')");
    }

    oStmt = oConn.createStatement();
    oRSet = oStmt.executeQuery("SELECT " + DB.gu_category + " FROM " + DB.k_x_company_prods + " WHERE " + DB.gu_company + "='" + sCompanyGUID + "'");
    if (oRSet.next()) {
      sCategoryGUID = oRSet.getString(1);
    }
    oRSet.close();
    oStmt.close();

    oStmt = oConn.createStatement();
    oRSet = oStmt.executeQuery("SELECT * FROM " + DB.k_addresses + " WHERE 1=0");
    ResultSetMetaData oMDat = oRSet.getMetaData();
    StringBuffer oColumnList = new StringBuffer(512);
    int iColumnCount = oMDat.getColumnCount();

    for (int c=1; c<=iColumnCount; c++) {
      if (c>1) oColumnList.append(',');
      oColumnList.append("a." + oMDat.getColumnName(c).toLowerCase());
    } // next (c)

    oRSet.close();
    oStmt.close();

    DBSubset oAddrs = new DBSubset(DB.k_addresses + " a," + DB.k_x_company_addr + " x",
                                   oColumnList.toString(), "a." + DB.gu_address + "=x." + DB.gu_address + " AND x." + DB.gu_company + "=? ORDER BY a." + DB.ix_address, 10);

    oAddrs.load(oConn, new Object[]{sCompanyGUID});

    String sAddresses = "\n  <company>" + sCompanyGUID + "</company>\n  <catalog>" + sCategoryGUID + "</catalog>\n  <addresses>\n" + oAddrs.toXML("    ", "address") + "\n  </addresses>";

    try { oXMLDoc.removeNode("pageset/company"); }
    catch (DOMException dome) {
      if (dome.code!=DOMException.NOT_FOUND_ERR) throw new DOMException(dome.code, dome.getMessage());
    }
    try { oXMLDoc.removeNode("pageset/catalog"); }
    catch (DOMException dome) {
      if (dome.code!=DOMException.NOT_FOUND_ERR) throw new DOMException(dome.code, dome.getMessage());
    }
    try { oXMLDoc.removeNode("pageset/addresses"); }
    catch (DOMException dome) {
      if (dome.code!=DOMException.NOT_FOUND_ERR) throw new DOMException(dome.code, dome.getMessage());
    }

    oXMLDoc.addNodeAndSave("pageset/pages", sAddresses);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("PageSet.mergeCompanyAddresses()");
    }
  } // mergeCompanyAddresses

    //-----------------------------------------------------------

  /**
   * <p>Remove Page from PageSet</p>
   * Page is searched by an internal XPath expression:<br>
   * pageset/pages/page[@guid='<i>sPageGUID</i>']
   * @param sFilePath Path to PageSet XML file
   * @param sPageGUID &lt;Page&gt; GUID attribute
   * @throws IOException
   */
  public static void removePage(String sFilePath, String sPageGUID) throws IOException {
    XMLDocument oXThis = new XMLDocument(sFilePath);

    oXThis.removeNodeAndSave("pageset/pages/page[@guid='" + sPageGUID + "']");
  } // removePage

  //-----------------------------------------------------------

  /**
   * <p>Remove a Page searching it by title</p>
   * Page is searched by an internal XPath expression:<br>
   * pageset/pages/page[guid = '<i>sPageTitle</i>']
   * @param sFilePath Path to PageSet XML file
   * @param sPageGUIDAttr Page GUID
   * @throws IOException
   */
  public static void removePageByTitle(String sFilePath, String sPageGUIDAttr) throws IOException {
    XMLDocument oXThis = new XMLDocument(sFilePath);

    oXThis.removeNodeAndSave("pageset/pages/page[guid = '" + sPageGUIDAttr + "']");
  } // removePageByTitle

  //-----------------------------------------------------------

  /**
   * <p>Remove Block</p>
   * Block is searched by an internal XPath expression:<br>
   * pageset/pages/page[@guid='<i>sPageGUID</i>']/blocks/block[@id='<i>sBlockId</i>']
   * @param sFilePath Path to PageSet XML file
   * @param sPageGUID &lt;Page&gt; GUID attribute
   * @param sBlockId id attribute of Block to be removed
   * @throws IOException
   */
  public static void removeBlock(String sFilePath, String sPageGUID, String sBlockId) throws IOException {
    XMLDocument oXThis = new XMLDocument(sFilePath);

    oXThis.removeNodeAndSave("pageset/pages/page[@guid='" + sPageGUID + "']/blocks/block[@id='" + sBlockId + "']");
  } // removeBlock

  //-----------------------------------------------------------

  /**
   * <p>Get base Microsite GUID from a PageSet XML file.<p>
   * GUID is obtained directly from raw text reading without parsing the input file.
   * @param sPageSetURI Path to PageSet XML file
   * @return Microsite GUID
   * @throws FileNotFoundException
   * @throws IOException
   */
  public static String getMicrositeGUID(String sPageSetURI)
    throws FileNotFoundException, IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("PageSet.getMicrositeGUID(" + sPageSetURI + ")");
      DebugFile.incIdent();
    }

    String sXML;
    int iMSiteOpenTag, iMSiteCloseTag;
    byte byXML[] = new byte[1024];
    FileInputStream oXMLStream = new FileInputStream(sPageSetURI);
    int iReaded = oXMLStream.read(byXML, 0, 1024);
    oXMLStream.close();

    sXML = new String(byXML, 0, iReaded);
    iMSiteOpenTag = sXML.indexOf("<microsite>")+11;
    iMSiteCloseTag = sXML.indexOf("</microsite>", iMSiteOpenTag);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("PageSet.getMicrositeGUID() : " + sXML.substring(iMSiteOpenTag, iMSiteCloseTag));
    }

    return sXML.substring(iMSiteOpenTag, iMSiteCloseTag);
  } // getMicrositeGUID();

  // ----------------------------------------------------------

  private static void printUsage() {

    System.out.println("");
    System.out.println("Usage:");
    System.out.println("com.knowgate.dataxslt.PageSet parse file_path");
  }

  // ---------------------------------------------------------

  public static void main(String[] argv)
    throws IllegalAccessException, ClassNotFoundException, Exception {
    if (argv.length!=2)
      printUsage();
    else if (!argv[0].equalsIgnoreCase("parse"))
      printUsage();
    else {
      PageSet oMSite = new PageSet(argv[1], true);
    }
  } // main

  // **********************************************************
  // * Variables estáticas

  public static final short ClassId = 71;

} // PageSet
