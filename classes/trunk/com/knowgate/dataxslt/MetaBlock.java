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

import org.w3c.dom.Node;

import com.knowgate.misc.Gadgets;

import dom.DOMSubDocument;

/**
 * <p>Microsite MetaBlock.</p>
 * <p>This class represents a &lt;metablock&gt;&lt;/metablock&gt; section of a
 * Microsite XML definition file. The XML file is first parsed into a DOMDocument
 * and then DOMDocument nodes are wrapped with classes that add specific Microsite
 * behavior.</p>
 * @author Sergio Montoro Ten
 * @version 6.0
 */
public class MetaBlock extends DOMSubDocument {

  /**
   * @param oRefNode DOMDocument Node holding &lt;metablock&gt; element.
   */
  public MetaBlock(Node oRefNode) {
    super(oRefNode);
  }

  // ----------------------------------------------------------

  public boolean allowHTML() {
    Node oItem = oNode.getAttributes().getNamedItem("allowHTML");

    if (null==oItem)
      return false;
    else
      return oItem.getNodeValue().equalsIgnoreCase("true") || oItem.getNodeValue().equalsIgnoreCase("yes") || oItem.getNodeValue().equals("1");
  } // allowHTML()

  // ----------------------------------------------------------

  public String id() {
    Node oItem = oNode.getAttributes().getNamedItem("id");

    if (null==oItem)
      return null;
    else
      return oItem.getNodeValue();
  } // id()

  // ----------------------------------------------------------

  /**
   * <p>Get metablock &lt;maxoccurs&gt; node</p>
   * @return If maxoccurs node is not found then function returns -1
   * @throws NumberFormatException If maxoccurs value is not a valid integer
   */
  public int maxoccurs() throws NumberFormatException {

    String sMaxOccurs = getElement("maxoccurs");

    if (null==sMaxOccurs)
      return -1;
    else
      return Integer.parseInt(sMaxOccurs.trim());
  } // maxoccurs

  // ----------------------------------------------------------

  public String name() {
    return getElement("name");
  } // name

  // ----------------------------------------------------------

  public String template() {
    return getElement("template");
  } // template

  // ----------------------------------------------------------

  public String thumbnail() {
    return getElement("thumbnail");
  } // thumbnail

  // ----------------------------------------------------------

  /**
   * <p>Split &lt;objects&gt; node by commas and return resulting array</p>
   */
  public String[] objects() {
    String sObjs = getElement("objects");

    if (null==sObjs)
      return null;
    else
      return Gadgets.split(sObjs,',');
  } // objects

  // ----------------------------------------------------------

}