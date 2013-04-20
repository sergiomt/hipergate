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

import java.util.Vector;
import java.util.HashMap;
import java.util.Iterator;

import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.FileInputStream;

import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import dom.DOMDocument;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * Microsite DOMDocument.
 * Metadata for a PageSet.
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Microsite extends DOMDocument {
  private Node oMicrositeNode;

  public Microsite() {
    oMicrositeNode = null;
  }

  // ----------------------------------------------------------

  public Microsite (String sURI)
    throws ClassNotFoundException, Exception, IllegalAccessException {
    // Crea un árbol DOM en memoria a partir de un archivo XML de definición
    // Parámetros:
    //             sURI -> Ruta absoluta al documento XML de definición
    //                     este documento debe validar con el schema
    //                     microsite.xsd

    if (DebugFile.trace) DebugFile.writeln("new Microsite(" + sURI + ")");

    // Cargar el documento DOM desde una ruta en disco
    super.parseURI(sURI);

    // Asignar una referencia interna permanente al nodo de nivel superior
    Node oTopNode = getRootNode().getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet"))
      oTopNode = oTopNode.getNextSibling();

    oMicrositeNode = seekChildByName(oTopNode, "microsite");

    if (DebugFile.trace) DebugFile.writeln("oMicrositeNode=" + (oMicrositeNode==null ? "null" : "[Element]"));
  }

  // ----------------------------------------------------------

  public Microsite (String sURI, boolean bValidateXML)
    throws ClassNotFoundException, Exception, IllegalAccessException {
    // Crea un árbol DOM en memoria a partir de un archivo XML de definición
    // Parámetros:
    //             sURI -> Ruta absoluta al documento XML de definición
    //                     este documento debe validar con el schema
    //                     microsite.xsd

    super("UTF-8", bValidateXML, false);

    if (DebugFile.trace)
      DebugFile.writeln("new Microsite(" + sURI + "," + String.valueOf(bValidateXML) + ")");

    // Cargar el documento DOM desde una ruta en disco
    super.setValidation(bValidateXML);
    super.parseURI(sURI);

    // Asignar una referencia interna permanente al nodo de nivel superior
    Node oRootNode = getRootNode();
    if (null==oRootNode) {
      throw new NullPointerException ("Cannot find root node for XML document " + sURI);
    }
    Node oTopNode = oRootNode.getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet"))
      oTopNode = oTopNode.getNextSibling();

    oMicrositeNode = seekChildByName(oTopNode, "microsite");

    if (DebugFile.trace) DebugFile.writeln("oMicrositeNode=" + (oMicrositeNode==null ? "null" : "[Element]"));
  }

  // ----------------------------------------------------------

  public String guid() {
    Node oTopNode;

    if (null==oMicrositeNode) {
      oTopNode = getRootNode().getFirstChild();
      if (oTopNode.getNodeName().equals("xml-stylesheet"))
        oTopNode = oTopNode.getNextSibling();
      if (oTopNode.getNodeName().equals("microsite"))
        oMicrositeNode = oTopNode;
      else
        oMicrositeNode = seekChildByName(oTopNode, "microsite");
    } // (oMicrositeNode)

    // Valor del atributo guid del nodo <microsite>
    return getAttribute(oMicrositeNode, "guid");
  }  // guid()

  // ----------------------------------------------------------

  public String name() {
    Node oTopNode;
    Element oName;
    String sName;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Microsite.name()");
      DebugFile.incIdent();
    }

    if (null==oMicrositeNode) {
      oTopNode = getRootNode().getFirstChild();

      if (oTopNode.getNodeName().equals("xml-stylesheet"))
        oTopNode = oTopNode.getNextSibling();
      if (oTopNode.getNodeName().equals("microsite"))
        oMicrositeNode = oTopNode;
      else
        oMicrositeNode = seekChildByName(oTopNode, "microsite");
    } // (oMicrositeNode)

    if (oMicrositeNode!=null) {

      // Buscar el nodo <name>
      oName = (Element) seekChildByName(oMicrositeNode, "name");

      if (oName != null) {
        sName = oName.getFirstChild().getNodeValue();
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("ERROR: <name> node not found");
        sName = null;
      }
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("ERROR: <microsite> node not found");
      sName = null;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Microsite.name() : " + sName );
    }

    return sName;
  }  // name()

  // ----------------------------------------------------------

  public Container container(int iIndex) {

    Node oTopNode;
    Element oContainers;
    NodeList oNodeList;
    Container oRetObj;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Microsite.container(" + String.valueOf(iIndex) + ")");
      DebugFile.incIdent();
    }

    // Obtener una referencia al nodo de nivel superior en el documento
    if (null==oMicrositeNode) {
      oTopNode = getRootNode().getFirstChild();
      if (oTopNode.getNodeName().equals("xml-stylesheet"))
        oTopNode = oTopNode.getNextSibling();
    if (oTopNode.getNodeName().equals("microsite"))
      oMicrositeNode = oTopNode;
    else
      oMicrositeNode = seekChildByName(oTopNode, "microsite");
    } // (oMicrositeNode)

    if (oMicrositeNode!=null) {

      // Buscar el nodo <containers>
      oContainers = (Element) seekChildByName(oMicrositeNode, "containers");

      if (oContainers!=null) {

        // Obtener una lista de nodos cuyo nombre sea <container>
        oNodeList = oContainers.getElementsByTagName("container");

        oRetObj = new Container(oNodeList.item(iIndex));

      }
      else {
        if (DebugFile.trace) DebugFile.writeln("<containers> node not found");
        oRetObj = null;
      }
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("<microsite> node not found");
      oRetObj = null;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Microsite.container() : " + (null==oRetObj ? "null" : "[Container]") );
    }

    return oRetObj;
  } // container


  // ----------------------------------------------------------

  public Container container(String sGUID) {

    Node oTopNode;
    Element oContainers, oContainer;
    NodeList oNodeList;
    Container oRetObj;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Microsite.container(" + sGUID + ")");
      DebugFile.incIdent();
    }

    // Obtener una referencia al nodo de nivel superior en el documento
    if (null==oMicrositeNode) {
      oTopNode = getRootNode().getFirstChild();
      if (oTopNode.getNodeName().equals("xml-stylesheet"))
        oTopNode = oTopNode.getNextSibling();
    if (oTopNode.getNodeName().equals("microsite"))
      oMicrositeNode = oTopNode;
    else
      oMicrositeNode = seekChildByName(oTopNode, "microsite");
    } // (oMicrositeNode)

    if (oMicrositeNode!=null) {

      oContainers = seekChildByName(oMicrositeNode, "containers");

      if (oContainers!=null) {

        // Buscar el nodo <container> con el guid especificado
        oContainer = seekChildByAttr(oContainers, "guid", sGUID);

        if (oContainer!=null) {
          oRetObj = new Container(oContainer);
        }
        else {
          if (DebugFile.trace) DebugFile.writeln("<container guid=\"" + sGUID + "\"> node not found");
          oRetObj = null;
        }
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("<containers> node not found");
        oRetObj = null;
      }
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("<microsite> node not found");
      oRetObj = null;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Microsite.container() : " + (null==oRetObj ? "null" : "[Container]") );
    }

    return oRetObj;
  } // container

  // ----------------------------------------------------------

  public Vector<Container> containers() {
    // Devuelve un vector con los contenedores de este Microsite
    Node oTopNode;
    Element oContainers;
    NodeList oNodeList;
    Vector oLinkVctr;
    int iContainers;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Microsite.containers()");
      DebugFile.incIdent();
    }

    // Obtener una referencia al nodo de nivel superior en el documento
    if (null==oMicrositeNode) {
      oTopNode = getRootNode().getFirstChild();
      if (oTopNode.getNodeName().equals("xml-stylesheet"))
        oTopNode = oTopNode.getNextSibling();
    if (oTopNode.getNodeName().equals("microsite"))
      oMicrositeNode = oTopNode;
    else
      oMicrositeNode = seekChildByName(oTopNode, "microsite");
    } // (oMicrositeNode)

    if (oMicrositeNode!=null) {

      // Buscar el nodo <containers>
      oContainers = (Element) seekChildByName(oMicrositeNode, "containers");

      if (oContainers!=null) {

        // Obtener una lista de nodos cuyo nombre sea <container>
        oNodeList = oContainers.getElementsByTagName("container");

        // Crear el vector
        iContainers = oNodeList.getLength();
        oLinkVctr = new Vector<Container>(iContainers);

        // Convertir los nodos DOM en objetos de tipo Container
        for (int i = 0; i < iContainers; i++)
          oLinkVctr.add(new Container(oNodeList.item(i)));
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("<containers> node not found");
        iContainers = 0;
        oLinkVctr = null;
      }
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("<microsite> node not found");
      iContainers = 0;
      oLinkVctr = null;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Microsite.containers() : " + String.valueOf(iContainers));
    }

    return oLinkVctr;
  } // containers()

  // ----------------------------------------------------------

  public Element seekChildByAttr(Node oParent, String sAttrName, String sAttrValue) {
    // Busca un nodo hijo del nivel inmediatamente inferior cuyo atributo tenga un valor determinado
    // Parametros:
    //             oParent    -> Nodo Padre
    //             sAttrName  -> Nombre del atributo a examinar
    //             sAttrValue -> Valor del atributo buscado
    Node oCurrentNode = null;
    String sCurrentAttr;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Microsite.seekChildByAttr(" + (oParent!=null ? "[Node]" : "null") + "," + sAttrName + "," + sAttrValue + ")");
      DebugFile.incIdent();
    }

    for (oCurrentNode=getFirstElement(oParent);
         oCurrentNode!=null;
         oCurrentNode=getNextElement(oCurrentNode)) {
      sCurrentAttr = getAttribute(oCurrentNode, sAttrName);

      if (sAttrValue.equals(sCurrentAttr))
        break;
    } // next(iNode)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (oCurrentNode==null)
        DebugFile.writeln("End Microsite.seekChildByAttr() : null");
      else
        DebugFile.writeln("End Microsite.seekChildByAttr() : " + oCurrentNode.toString());
    }

    if (oCurrentNode!=null)
      return (Element) oCurrentNode;
    else
      return null;
  } // seekChildByAttr()

  // ----------------------------------------------------------

  public void createPageSet(String sPath, HashMap oParameters) throws IOException {
    // Crear un nuevo documento PageSet en un archivo
    // a partir de la definición estructural de este Microsite
    // Parámetros:
    //             sPath       -> Ruta al archivo de salida
    //             oParameters -> Parámetros adicionales de creación
    //             (típicamente: font, color, etc)

    FileWriter oWriter = new FileWriter(sPath);
    Iterator oKeyIterator;
    Object oKey;
    Vector oContainers;
    int iContainers;

    // Escribir a capón los nodos del PageSet
    oWriter.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    oWriter.write("<?xml-stylesheet type=\"text/xsl\"?>\n");
    oWriter.write("<?xml-stylesheet type=\"text/xsl\"?>\n");
    oWriter.write("<pageset xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"pageset.xsd\" guid=\"" + Gadgets.generateUUID() + "\">\n");
    oWriter.write("  <microsite>" + this.guid() + "</microsite>\n");

    oKeyIterator = oParameters.keySet().iterator();
    while (oKeyIterator.hasNext()) {
      oKey = oKeyIterator.next();
      oWriter.write("  <" + oKey.toString() + ">" + oParameters.get(oKey).toString() + "</" + oKey.toString() + ">\n");
    } // wend()
    oKeyIterator = null;

    oWriter.write("  <pages>\n");

    oContainers = this.containers();
    iContainers = oContainers.size();

    for (int p=0; p<iContainers; p++) {
      oWriter.write("    <page guid=\">" + Gadgets.generateUUID() + "\">\n");
      oWriter.write("      <title>Pagina " + String.valueOf(p) + "</title>\n");
      oWriter.write("      <container>" + ((Container) oContainers.get(p)).guid() + "</container>\n");
      oWriter.write("      <blocks>\n");
      oWriter.write("      </blocks>\n");
      oWriter.write("    </page>\n");
    } // next(p)

    oWriter.write("  </pages>\n");
    oWriter.write("</pageset>\n");

    oWriter.close();
    oWriter = null;
  } // createPageSet()

  // ***************************************************************************
  // Static methods

  public static String getMicrositeGUID(String sMicrositeURI) throws FileNotFoundException, IOException {
    String sXML;
    int iMSiteOpenQuote, iMSiteCloseQuote;
    byte byXML[] = new byte[1024];;
    FileInputStream oXMLStream = new FileInputStream(sMicrositeURI);
    int iReaded = oXMLStream.read(byXML, 0, 1024);
    oXMLStream.close();

    sXML = new String(byXML, 0, iReaded);
    iMSiteOpenQuote = sXML.indexOf("guid")+4;

    for (char b=sXML.charAt(iMSiteOpenQuote);
         b==' ' || b=='\r' || b=='\n' || b=='\t' || b=='"' || b=='=';
         b=sXML.charAt(++iMSiteOpenQuote)) ;

    iMSiteCloseQuote = sXML.indexOf("\"", iMSiteOpenQuote);

    return sXML.substring(iMSiteOpenQuote, iMSiteCloseQuote);
  } // getMicrositeGUID();

  // ----------------------------------------------------------

  private static void printUsage() {

    System.out.println("");
    System.out.println("Usage:");
    System.out.println("com.knowgate.dataxslt.Microsite parse file_path");
  }

  // ---------------------------------------------------------

  public static void main(String[] argv)
    throws IllegalAccessException, ClassNotFoundException, Exception {
    if (argv.length!=2)
      printUsage();
    else if (!argv[0].equalsIgnoreCase("parse"))
      printUsage();
    else {
      Microsite oMSite = new Microsite(argv[1], true);
    }
  } // main

  // ***************************************************************************
  // Static variables

  public static final short ClassId = 70;

} // Microsite