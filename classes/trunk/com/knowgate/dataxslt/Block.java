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

import java.util.Vector;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import dom.DOMSubDocument;

/**
 * <p>Page Block</p>
 * <p>This class represents a &lt;block&gt;&lt;/block&gt; section of a PageSet
 * XML definition file. The XML file is first parsed into a DOMDocument and
 * then DOMDocument nodes are wrapped with classes that add specific PageSet
 * behavior.</p>
 * @author Sergio Montoro Ten
 * @version 1.1
 */
public class Block extends DOMSubDocument {

  private Node oBlockNode;
  /**
   * @param oRefNode DOMDocument Node holding &lt;block&gt; element.
   */
  public Block(Node oRefNode) {
    super(oRefNode);

    oBlockNode = oRefNode;
  }

  // ----------------------------------------------------------

  public Node getNode() {
    return oBlockNode;
  }

  // ----------------------------------------------------------

  /**
   * @return Block id attribute
   */
  public String id() {
    Node oItem = oNode.getAttributes().getNamedItem("id");

    if (null==oItem)
      return null;
    else
      return oItem.getNodeValue();
  } // id()

  // ----------------------------------------------------------

  public void id(String sNewId) {
    Node oItem = oNode.getAttributes().getNamedItem("id");

    oItem.setNodeValue(sNewId);
  }

  // ----------------------------------------------------------

  /**
   * @return metablock element value
   */
  public String metablock() {
    return getElement("metablock");
  } // metablock()

  // ----------------------------------------------------------

  /**
   * @return tag element value
   */
  public String tag() {
    return getElement("tag");
  } // tag()

  // ----------------------------------------------------------

  /**
   * @return tag element value
   */
  public void tag(String sNewTag) {
    Node oItem = oNode.getAttributes().getNamedItem("tag");

    oItem.setNodeValue(sNewTag);
  } // tag()

  // ----------------------------------------------------------

  /**
   * @return zone element value
   */
  public String zone() {
    return getElement("zone");
  } // zone()

  // ----------------------------------------------------------

  /**
   * @return Vector with Image objects for this Block.
   */
  public Vector images() {
    Node oImagesNode = null;
    NodeList oNodeList;
    Vector oLinkVctr;

    for (oImagesNode=oNode.getFirstChild(); oImagesNode!=null; oImagesNode=oImagesNode.getNextSibling())
      if (Node.ELEMENT_NODE==oImagesNode.getNodeType())
        if (oImagesNode.getNodeName().equals("images")) break;

    oNodeList = ((Element) oImagesNode).getElementsByTagName("image");

    oLinkVctr = new Vector(oNodeList.getLength());

    for (int i=0; i<oNodeList.getLength(); i++)
      oLinkVctr.add(new Image(oNodeList.item(i)));

    return oLinkVctr;
  } // images()

  // ----------------------------------------------------------

  /**
   * @return Vector with Paragraph objects for this Block.
   */
  public Vector<Paragraph> paragraphs() {
    Node oParagraphsNode = null;
    NodeList oNodeList;
    Vector oLinkVctr;

    for (oParagraphsNode=oNode.getFirstChild(); oParagraphsNode!=null; oParagraphsNode=oParagraphsNode.getNextSibling())
      if (Node.ELEMENT_NODE==oParagraphsNode.getNodeType())
        if (oParagraphsNode.getNodeName().equals("paragraphs")) break;

    oNodeList = ((Element) oParagraphsNode).getElementsByTagName("paragraph");

    oLinkVctr = new Vector<Paragraph>(oNodeList.getLength());

    for (int i=0; i<oNodeList.getLength(); i++)
      oLinkVctr.add(new Paragraph(oNodeList.item(i)));

    return oLinkVctr;
  } // paragraphs()

  // ----------------------------------------------------------
}