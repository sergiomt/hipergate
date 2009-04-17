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

import java.io.IOException;
import java.io.File;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.FileSystem;

import org.w3c.dom.DOMException;

/**
 * Direct character-level manipulations for XML documents.
 * This class modifies XML document files by directy seeking substrings inside
 * its text. Given a well-knonw XML file structure is easier and faster to seek
 * for &lt;nodes&gt; as substrings instead of parsing the whole documents into a
 * DOM tree.
 * @author Sergio Montoro Ten
 * @version 2.2
 */
public class XMLDocument {

  private String sXMLDoc;
  private String sFilePath;
  private String sEncoding;
  private FileSystem oFS;

  public XMLDocument() {
    oFS = new FileSystem();
    sEncoding = "UTF-8";
  }

  // ----------------------------------------------------------

  /**
   * <p>Create XMLDocument and load an XML file into memory.</p>
   * No node parsing is done, but file is loaded directly into a String.
   * @param sFile File Path
   * @throws IOException
   * @throws OutOfMemoryError
   */
  public XMLDocument(String sFile) throws IOException, OutOfMemoryError {
    oFS = new FileSystem();
    sEncoding = "UTF-8";
    load (sFile);
  }

  // ----------------------------------------------------------

  /**
   * Create XMLDocument and load an XML file into memory.
   * @param sFile File Path
   * @param sEnc Character Encoding
   * @throws IOException
   * @throws OutOfMemoryError
   */
  public XMLDocument(String sFile, String sEnc) throws IOException, OutOfMemoryError {
    oFS = new FileSystem();
    sEncoding = sEnc;
    load (sFile);
  }

  // ----------------------------------------------------------

  public String getCharacterEncoding() {
    return sEncoding;
  }

  // ----------------------------------------------------------

  public void setCharacterEncoding(String sEnc) {
    sEnc = sEncoding;
  }

  // ----------------------------------------------------------

  /**
   * Load an XML file into memory.
   * No node parsing is done, but file is loaded directly into a String.
   * @param sFile File Path
   * @param sEnc Character encoding
   * @throws IOException
   * @throws OutOfMemoryError
   */
  public void load (String sFile, String sEnc) throws IOException,OutOfMemoryError {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin XMLDocument.load(" + sFile + "," + sEnc + ")");
      DebugFile.incIdent();
    }

    sEncoding = sEnc;

    try {
      sXMLDoc = oFS.readfilestr(sFile, sEncoding);
    } catch (com.enterprisedt.net.ftp.FTPException neverthrown) { }

    sFilePath = sFile;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End XMLDocument.load() : " + String.valueOf(sXMLDoc.length()));
    }
  } // load

  // ----------------------------------------------------------

  /**
   * <p>Load an XML file into memory.</p>
   * No node parsing is done, but file is loaded directly into a String.<br>
   * Character encoding is UTF-8 by default unless changed by calling setEncoding()
   * @param sFile File Path
   * @throws IOException
   * @throws OutOfMemoryError
   */
  public void load (String sFile) throws IOException,OutOfMemoryError {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin XMLDocument.load(" + sFile + ")");
      DebugFile.incIdent();
    }

    try {
      sXMLDoc = oFS.readfilestr(sFile, sEncoding);
    } catch (com.enterprisedt.net.ftp.FTPException neverthrown) { }

    sFilePath = sFile;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End XMLDocument.load() : " + String.valueOf(sXMLDoc.length()));
    }
  } // load

  // ----------------------------------------------------------

  /**
   * Save file to disk.
   * If it already exists it is overwritten.
   * @param sFile File Path
   * @throws IOException
   */
  public void save(String sFile) throws IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin XMLDocument.save(" + sFile + ")");
      DebugFile.incIdent();
    }

    oFS.writefilestr (sFile, sXMLDoc, sEncoding);

    if (DebugFile.trace) {

      if (sXMLDoc.length()>0) {
        if (Character.isISOControl(sXMLDoc.charAt(0)))
          DebugFile.writeln("Warning: document " + sFile + " starts with ISO control characters");
        if (Character.isISOControl(sXMLDoc.charAt(sXMLDoc.length()-1)))
          DebugFile.writeln("Warning: document " + sFile + " ends with ISO control characters");
      }

      DebugFile.decIdent();

      File oFileW = new File(sFile);
      long lFileW = oFileW.length();

      DebugFile.writeln("End XMLDocument.save() : " + String.valueOf(lFileW));
    }
  } // save

  // ----------------------------------------------------------

  /**
   * Save file to disk.
   * Save to same path used for loading the file.
   * @throws IOException
   */
  public void save() throws IOException {
    save (sFilePath);
  }

  // ----------------------------------------------------------

  private static  boolean isLastSibling (String sXMLDoc, int iFromIndex,
                                         String sParent, String sSibling) {

    int iEndParent = sXMLDoc.indexOf("</" + sParent, iFromIndex);
    int iNextSibling = sXMLDoc.indexOf("<" + sSibling, iFromIndex);

    if (iNextSibling==-1)
      return true;
    else
      return iNextSibling>iEndParent;
  } // isLastSibling

  // ----------------------------------------------------------

  private int seekNode(String sXPath) {
    int iNodeCount;
    int iNode;
    int iAttr;
    int iLeft;
    int iRight;
    String sCurrent;
    String vNodes[];  // Array de nodos parseados
    String vAttrs[];  // Array de atributos parseados
    boolean bAttrs[]; // Guarda indicadores booleanos según se van encontrando los atributos
                      // para saber cual es el que no se encuentra en caso de fallo

    if (DebugFile.trace) {
      DebugFile.writeln("Begin XMLDocument.seekNode(" + sXPath + ")");
      DebugFile.incIdent();
    }

    // Parsear la cadena de búsqueda XPath y colocar el resultado
    // en dos arrays, uno para los nodos y otro para los atributos.
    vNodes = Gadgets.split(sXPath, "/");
    if (null==vNodes) {
      iNodeCount = 0;
      vAttrs = null;
      bAttrs = null;
    }
    else {
      iNodeCount = vNodes.length;
      vAttrs = new String[iNodeCount];
      bAttrs = new boolean[iNodeCount];
      for (int a=0; a<iNodeCount; a++) bAttrs[a] = false;
    }

    for (int iTok=0; iTok<iNodeCount; iTok++) {

      iLeft = vNodes[iTok].indexOf("[");
      if (iLeft>0) {
        iRight = vNodes[iTok].indexOf("]");

        if (iRight==-1)
          throw new DOMException(DOMException.INVALID_ACCESS_ERR, "missing right bracket");

        // Sacar el contenido dentro de los corchetes
        vAttrs[iTok] = vNodes[iTok].substring(iLeft+1,iRight);
        // Eliminar las arrobas
        vAttrs[iTok] = vAttrs[iTok].replace('@',' ');
        // Cambiar las comillas simples por dobles
        vAttrs[iTok] = vAttrs[iTok].replace((char)39,(char)34);
        // Eliminar los espacios en blanco
        vAttrs[iTok] = vAttrs[iTok].trim();
        // Asignar al nodo el valor quitando el contenido de los corchetes
        vNodes[iTok] = vNodes[iTok].substring(0, iLeft);
      }
      else
        vAttrs[iTok] = "";

      if (DebugFile.trace) DebugFile.writeln("Token " + String.valueOf(iTok) + " : node=" + vNodes[iTok] + ", attr=" + vAttrs[iTok]);
    } // next (iTok)

    // Buscar el nodo
    iLeft = 0;
    iNode = 0;

    while (iNode<iNodeCount) {
      // Primero recorrer el documento XML para buscar nodos coincidentes

      iLeft = sXMLDoc.indexOf("<" + vNodes[iNode], iLeft);
      if (iLeft<0) {
        if (DebugFile.trace) DebugFile.writeln("Node " + vNodes[iNode] + " not found");
        throw new DOMException(DOMException.NOT_FOUND_ERR, "Node " + vNodes[iNode] + " not found");
      } // fi(iLeft<0)

      iRight = sXMLDoc.indexOf(">", iLeft+1);
      if (iRight<0) {
        if (DebugFile.trace) DebugFile.writeln("Unclosed Node " + vNodes[iNode] + " missing >");
        throw new DOMException(DOMException.SYNTAX_ERR, "Unclosed Node " + vNodes[iNode] + " missing >");
      }

      sCurrent = sXMLDoc.substring(iLeft+1, iLeft+vNodes[iNode].length()+1);

      if (vNodes[iNode].equals(sCurrent)) {

        if (vAttrs[iNode].length()==0) {
          // No hay atributos, dar por coincidente el primer nodo que aparezca
          iNode++;
        }

        // Tratar de forma especial la función position() de XPath
        else if (vAttrs[iNode].startsWith("position()")) {

          String[] aAttrValue = Gadgets.split2(vAttrs[iNode], '=');

          if (aAttrValue.length<2)
            throw new DOMException(DOMException.NOT_SUPPORTED_ERR, "position() function can only be declared equal to last() function");
          else {
            if (aAttrValue[1].equals("last()")) {
              if ( isLastSibling (sXMLDoc, iRight, vNodes[iNode-1], sCurrent) ) {
                bAttrs[iNode] = true;
                iNode++;
              } // fi (isLastSibling)
            } // fi (aAttrValue[1])
            else
              throw new DOMException(DOMException.NOT_SUPPORTED_ERR, "position() function can only be declared equal to last() function");
          }
        }
        else {
          // Mirar si el valor del atributo del nodo actual coincide con el especificado en XPath
          iAttr = sXMLDoc.indexOf(vAttrs[iNode], iLeft+1);
          if (iAttr>iLeft && iAttr<iRight) {
            bAttrs[iNode] = true;
            iNode++;
          }
        }
      } // fi(substring(<...)==vNode[])

      if (iNode<iNodeCount) iLeft = iRight;
    } // wend

    if (0==iLeft) {
      for (int b=0; b<iNodeCount; b++) {
        if (false == bAttrs[b]) {
          if (DebugFile.trace) DebugFile.writeln("Attribute " + vAttrs[b] + " of node " + vNodes[b] + " not found");
          throw new DOMException(DOMException.NOT_FOUND_ERR, "Attribute " + vAttrs[b] + " of node " + vNodes[b] + " not found");
        } // fi(bAttrs[b])
      } // next(b)
    } // fi(iLeft<0)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End XMLDocument.seekNode() : " + String.valueOf(iLeft));
    }

    return iLeft;
  } // seekNode

  // ----------------------------------------------------------

  /**
   * Get loaded file as a String
   */
  public String toString() {
    return sXMLDoc;
  }

  // ----------------------------------------------------------

  /**
   * Add a piece of XML text after a given node identifier by an XPath expression.
   * @param sAfterXPath Restricted XPath expression for node after witch the next node is to be placed.
   * For example : <br>
   * "pageset/pages/page[@guid="123456789012345678901234567890AB"]/blocks/block[@id="003"]" will add sNode text after <block id="003">...</block> substring.<br>
   * "pageset/pages/page[position()=last()]" will add sNode text after last <page>...</page> substring.
   * @param sNode XML Text to be added.
   * @throws DOMException
   * DOMException Codes:<br>
   * <table border=1 cellpadding=4>
   * <tr><td>NOT_FOUND_ERR</td><td>A node or attribute from the XPath expression was not found</td></tr>
   * <tr><td>INVALID_ACCESS_ERR</td><td>An attribute expression is invalid</td></tr>
   * <tr><td>NOT_SUPPORTED_ERR</td><td>position() function was used but last() was not specified as value for it</td></tr>
   * </table>
   */
  public void addNode(String sAfterXPath, String sNode) throws DOMException {
    String sCloseParent;
    int iOpenParent;
    int iCloseParent;
    int iTailParent;
    int iAngle;
    int iSpace;
    char b;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin XMLDocument.addNode(" + sAfterXPath + "," + sNode + ")");
      DebugFile.incIdent();
    }

    iOpenParent = seekNode(sAfterXPath);

    if (DebugFile.trace) DebugFile.writeln("iOpenParent=" + String.valueOf(iOpenParent));

    iSpace = sXMLDoc.indexOf(" ", iOpenParent);
    if (-1==iSpace) iSpace = 2147483647;
    iAngle = sXMLDoc.indexOf(">", iOpenParent);
    if (-1==iAngle) iSpace = 2147483647;

    sCloseParent = "</" + sXMLDoc.substring(iOpenParent+1, iSpace<iAngle ? iSpace : iAngle) + ">";

    if (DebugFile.trace) DebugFile.writeln("sCloseParent=" + sCloseParent);

    iCloseParent = sXMLDoc.indexOf(sCloseParent, iOpenParent);

    if (DebugFile.trace) DebugFile.writeln("iCloseParent=" + String.valueOf(iCloseParent));

    if (iCloseParent<=0)
      throw new DOMException(DOMException.NOT_FOUND_ERR, "Node " + sCloseParent + " not found");

    iSpace = 0;
    iAngle = iCloseParent - 1;
    b = sXMLDoc.charAt(iAngle);
    while (b==' ' || b=='\t') {
      iCloseParent--;
      iSpace++;
      b = sXMLDoc.charAt(--iAngle);
    } // wend

    iCloseParent = iCloseParent+sCloseParent.length()+iSpace;
    iTailParent = iCloseParent;

    if (iTailParent<sXMLDoc.length())
      while (sXMLDoc.charAt(iTailParent)==(char)13 || sXMLDoc.charAt(iTailParent)==(char)10) iTailParent++;

    StringBuffer oXMLDoc = new StringBuffer (iCloseParent+sNode.length()+(sXMLDoc.length()-iTailParent)+4);

    oXMLDoc.append(sXMLDoc.substring(0, iCloseParent));
    oXMLDoc.append(sNode);
    oXMLDoc.append('\n');

    if (iTailParent<sXMLDoc.length())
      oXMLDoc.append(sXMLDoc.substring(iTailParent));

    sXMLDoc = oXMLDoc.toString();
    oXMLDoc = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End XMLDocument.addNode()");
    }
  } // addNode

  // ----------------------------------------------------------

  /**
   * Add a piece of XML text after a given node and save document.
   * Document is saved to the same file path where if was loaded.
   * @param sAfterXPath Restricted XPath expression for node after witch the next node is to be placed.
   * @param sNode XML Text to be added.
   * @throws DOMException
   * @throws IOException
   */
  public void addNodeAndSave(String sAfterXPath, String sNode) throws DOMException,IOException {
    String sCloseParent;
    int iOpenParent;
    int iCloseParent;
    int iTailParent;
    int iAngle;
    int iSpace;
    char b;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin XMLDocument.addNodeAndSave(" + sAfterXPath + "," + sNode + ")");
      DebugFile.incIdent();
    }

    iOpenParent = seekNode(sAfterXPath);

    if (DebugFile.trace) DebugFile.writeln("iOpenParent=" + String.valueOf(iOpenParent));

    iSpace = sXMLDoc.indexOf(" ", iOpenParent);
    if (-1==iSpace) iSpace = 2147483647;
    iAngle = sXMLDoc.indexOf(">", iOpenParent);
    if (-1==iAngle) iSpace = 2147483647;

    sCloseParent = "</" + sXMLDoc.substring(iOpenParent+1,iSpace<iAngle ? iSpace : iAngle) + ">";

    if (DebugFile.trace) DebugFile.writeln("sCloseParent=" + sCloseParent);

    iCloseParent = sXMLDoc.indexOf(sCloseParent, iOpenParent);

    if (DebugFile.trace) DebugFile.writeln("iCloseParent=" + String.valueOf(iCloseParent));

    if (iCloseParent<=0)
      throw new DOMException(DOMException.NOT_FOUND_ERR, "Node " + sCloseParent + " not found");

    iSpace = 0;
    iAngle = iCloseParent - 1;
    b = sXMLDoc.charAt(iAngle);
    while (b==' ' || b=='\t') {
      iCloseParent--;
      iSpace++;
      b = sXMLDoc.charAt(--iAngle);
    } // wend

    iCloseParent = iCloseParent+sCloseParent.length()+iSpace;
    iTailParent = iCloseParent;

    if (iTailParent<sXMLDoc.length())
      while (sXMLDoc.charAt(iTailParent)==(char)13 || sXMLDoc.charAt(iTailParent)==(char)10) iTailParent++;

    StringBuffer oXMLDoc = new StringBuffer (iCloseParent+sNode.length()+(sXMLDoc.length()-iTailParent)+4);

    oXMLDoc.append(sXMLDoc.substring(0, iCloseParent));
    oXMLDoc.append(sNode);
    oXMLDoc.append('\n');

    if (iTailParent<sXMLDoc.length())
      oXMLDoc.append(sXMLDoc.substring(iTailParent));

    sXMLDoc = oXMLDoc.toString();
    oXMLDoc = null;

    if (DebugFile.trace) {
      if (sXMLDoc.length()>0) {
        if (Character.isISOControl(sXMLDoc.charAt(0)))
          DebugFile.writeln("Warning: document " + sFilePath + " starts with ISO control characters");
        if (Character.isISOControl(sXMLDoc.charAt(sXMLDoc.length()-1)))
          DebugFile.writeln("Warning: document " + sFilePath + " ends with ISO control characters");
      }
    }

    oFS.writefilestr(sFilePath, sXMLDoc, sEncoding);

    if (DebugFile.trace) {
      DebugFile.decIdent();

      File oFileW = new File(sFilePath);
      long lFileW = oFileW.length();

      DebugFile.writeln("End XMLDocument.addNodeAndSave() : " + String.valueOf(lFileW));
    }
  } // addNodeAndSave

  // ----------------------------------------------------------

  /**
   * Remove a node.
   * @param sXPath Restricted XPath expression for node to remove.
   * For example: "pageset/pages/page[@guid="123456789012345678901234567890AB"]/blocks/block[@id="003"]"
   * will remove <block id="003">...</block> substring.
   * @throws DOMException
   */
  public void removeNode(String sXPath) throws DOMException {
    int iStartParent;
    int iEndParent;
    int iBracket;
    String sNodeName;
    String vNodes[];

    if (DebugFile.trace) {
      DebugFile.writeln("Begin XMLDocument.removeNode(" + sXPath + ")");
      DebugFile.incIdent();
    }

    iStartParent = seekNode(sXPath);

    vNodes = Gadgets.split(sXPath, "/");

    iBracket = vNodes[vNodes.length-1].indexOf("[");

    if (iBracket>0)
      sNodeName = vNodes[vNodes.length-1].substring(0, iBracket);
    else
      sNodeName = vNodes[vNodes.length-1];

    iEndParent = sXMLDoc.indexOf("</" + sNodeName + ">", iStartParent) + sNodeName.length()+3;

    if (iEndParent==0)
      throw new DOMException(DOMException.NOT_FOUND_ERR, "Node " + "</" + sNodeName + ">" + " not found");

    // Quitar los espacios por delante del nodo
    for (char b = sXMLDoc.charAt(iStartParent);
        (b==' ') && iStartParent>0;
         b = sXMLDoc.charAt(--iStartParent)) ;

    // Quitar los saltos de línea y retornos de carro por detrás del nodo
    for (char c = sXMLDoc.charAt(iEndParent);
        (c=='\r' || c=='\n') && iEndParent<sXMLDoc.length();
         c = sXMLDoc.charAt(++iEndParent)) ;

    sXMLDoc =  sXMLDoc.substring(0, iStartParent) + sXMLDoc.substring(iEndParent);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End XMLDocument.removeNode()");
    }
  } // removeNode

  // ----------------------------------------------------------

  /**
   * Remove a node and save document.
   * Document is saved to the same file path where if was loaded.
   * @param sXPath XPath expression for node to remove.
   * @throws DOMException
   * @throws IOException
   */
  public void removeNodeAndSave(String sXPath) throws DOMException,IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin XMLDocument.removeNodeAndSave(" + sXPath + ")");
      DebugFile.incIdent();
    }

    removeNode(sXPath);

    oFS.writefilestr(sFilePath, sXMLDoc, sEncoding);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End XMLDocument.removeNodeAndSave()");
    }
  } // removeNodeAndSave

  // ----------------------------------------------------------
} // XMLDocument
