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
 * <p>Microsite Container</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class Container extends DOMSubDocument {

  // ----------------------------------------------------------

  public Container(Node oRefNode) {
    super(oRefNode);
  }

  // ----------------------------------------------------------

  public String guid() {
    Node oItem = oNode.getAttributes().getNamedItem("guid");

    if (null==oItem)
      return null;
    else
      return oItem.getNodeValue();
  } // guid()

  // ----------------------------------------------------------

  public String name() {
    return getElement("name");
  } // name

  // ----------------------------------------------------------

  public String template() {
    return getElement("template");
  } // name

  // ----------------------------------------------------------

  public String thumbnail() {
    return getElement("thumbnail");
  } // thumbnail

  // ----------------------------------------------------------

  public String parameters() {
    return getElement("parameters");
  } // parameters

  // ----------------------------------------------------------

  public Vector<MetaBlock> metablocks() {
    Node oMetaBlksNode = null;
    NodeList oNodeList;
    Vector oLinkVctr;

    for (oMetaBlksNode=oNode.getFirstChild(); oMetaBlksNode!=null; oMetaBlksNode=oMetaBlksNode.getNextSibling())
      if (Node.ELEMENT_NODE==oMetaBlksNode.getNodeType())
        if (oMetaBlksNode.getNodeName().equals("metablocks")) break;

    oNodeList = ((Element) oMetaBlksNode).getElementsByTagName("metablock");

    oLinkVctr = new Vector(oNodeList.getLength());

    for (int i=0; i<oNodeList.getLength(); i++)
      oLinkVctr.add(new MetaBlock (oNodeList.item(i)));

    return oLinkVctr;
  } // metablocks()

  // ----------------------------------------------------------

  public MetaBlock metablock(String sId) {
    for (MetaBlock mb : metablocks()) {
      if (mb.id().equals(sId)) return mb;
    }
    return null;
  }

  // ----------------------------------------------------------

}