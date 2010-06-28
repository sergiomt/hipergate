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
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.Iterator;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.DOMException;

import dom.DOMSubDocument;

/**
 * <p>PageSet Page</p>
 * <p>This class represents a &lt;page&gt;&lt;/page&gt; section of a PageSet XML definition file.
 * @author Sergio Montoro Ten
 * @version 1.1
 */

public class Page extends DOMSubDocument {
  private String sPhysicalFile;
  private PageSet oOwnerPageSet;

  // ----------------------------------------------------------

  /**
   * @param oRefNode DOMDocument Node holding &lt;page&gt; element.
   * @param oPagSet Reference to PageSet object that contains this page
   */
  public Page (Node oRefNode, PageSet oPagSet) {
    super(oRefNode);

    sPhysicalFile = null;
    oOwnerPageSet = oPagSet;
  }

  // ----------------------------------------------------------

  /**
   * Reference to PageSet object that contains this Page
   */
  public PageSet getPaseSet() {
    return oOwnerPageSet;
  }

  // ----------------------------------------------------------

  /**
   * Reference to Container object that describes this Page structure
   */
  public Container getContainer() {
    return oOwnerPageSet.microsite().container(container());
  }

  // ----------------------------------------------------------

  /**
   * Get XSL transformer stylesheet name for this Page
   * @return &lt;template&gt; value for Container of this Page
   * @throws DOMException
   */
  public String template() throws DOMException {

	if (DebugFile.trace) {
      DebugFile.writeln("Begin Page.template()");
      DebugFile.incIdent();
	}
        	
    Microsite oMSite = oOwnerPageSet.microsite();

    Node oTopNode = oMSite.getRootNode().getFirstChild();

    if (oTopNode.getNodeName().equalsIgnoreCase("xml-stylesheet"))
      oTopNode = oTopNode.getNextSibling();

    Node oContainers = oMSite.seekChildByName(oTopNode, "containers");

    if (oContainers==null) {
      if (DebugFile.trace) {
        DebugFile.writeln("ERROR: <containers> node not found.");
        DebugFile.decIdent();
      }
      throw new DOMException(DOMException.NOT_FOUND_ERR, "<containers> node not found");
    }

    Node oContainer = (Node) oMSite.seekChildByAttr(oContainers, "guid", this.container());

    if (oContainer==null) {
      if (DebugFile.trace) {
        DebugFile.writeln("ERROR: guid attribute for container " + this.container() + " not found.");
        DebugFile.decIdent();
      }

      throw new DOMException(DOMException.NOT_FOUND_ERR, "guid attribute for container " + this.container() + " not found");
    } // fi

    Element oTemplate = oMSite.seekChildByName(oContainer, "template");

    if (oTemplate==null) {
      if (DebugFile.trace) {
        DebugFile.writeln("ERROR: <template> node for page " + this.getTitle() + " not found.");
        DebugFile.decIdent();
      }

      throw new DOMException(DOMException.NOT_FOUND_ERR, "<template> node for page " + this.getTitle() + " not found");
    }

	if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Page.template() : " + oMSite.getTextValue(oTemplate));
	}

    return oMSite.getTextValue(oTemplate);
  } // template

  // ----------------------------------------------------------

  /**
   * @return Path to final document generated after XSL transformation of Page.
   * This property is not part of the Page XML file but it is set at runtime and
   * stored appart.
   */
  public String filePath() {
    return sPhysicalFile;
  }

  // ----------------------------------------------------------

  /**
   * Set path to final document generated after XSL transformation of Page.
   * This property is not part of the Page XML file but it is set at runtime and
   * stored appart.
   * @param sPath Path to generated XHTML (or other) final file.
   */
  public void filePath(String sPath) {
    sPhysicalFile = sPath;
  }

  // ----------------------------------------------------------

  /**
   * Value of attribute guid for this Page at PageSet XML file
   * @return GUID of this Page
   */
  public String guid() {
    Node oItem = oNode.getAttributes().getNamedItem("guid");

    if (null==oItem)
      return null;
    else
      return oItem.getNodeValue();
  } // guid()

  // ----------------------------------------------------------

  /**
   * GUID of Container that describes this Page structure
   * @return String representing the Container GUID
   */
  public String container() {
    return getElement("container");
  } // container

  // ----------------------------------------------------------

  /**
   * @return &lt;title&gt;element contents.
   */
  public String getTitle() {
    return getElement("title");
  } // getTitle

  // ----------------------------------------------------------

  /**
   * Set &lt;title&gt;element contents.
   * @param sTitle
   */
  public void setTitle(String sTitle) {
    Node oCurrentNode = null;

    for (oCurrentNode=oNode.getFirstChild(); oCurrentNode!=null; oCurrentNode=oCurrentNode.getNextSibling())
      if (Node.ELEMENT_NODE==oCurrentNode.getNodeType())
        if (oCurrentNode.getNodeName().equals("title")) break;

    oCurrentNode.setNodeValue(sTitle);
  } // setTitle

  // ----------------------------------------------------------

  /**
   * Get Page blocks.
   * @return Vector containing objects of class Block for this Page.<br>
   * Returned blocks are always sorted by their metablock id attribute and their
   * block id attribute. The metablock id and the block id are concatenated
   * @throws DOMException If &lt;blocks&gt; node is not found
   */
  public Vector<Block> blocks()
    throws DOMException {

    if (DebugFile.trace) {
         DebugFile.writeln("Begin Page.blocks()");
         DebugFile.incIdent();
       }

    String sPaddedID;
    Node oBlksNode = null;
    NodeList oNodeList = null;
    int iNodeListLen = 0;
    Vector<Block> oLinkVctr = null;
    SortedMap oSortedMap = new TreeMap();

    if (DebugFile.trace) {
      if (null==oNode.getFirstChild())
        DebugFile.writeln("Node.getFirstChild() returned null");
    }

    for (oBlksNode=oNode.getFirstChild(); oBlksNode!=null; oBlksNode=oBlksNode.getNextSibling())
      if (Node.ELEMENT_NODE==oBlksNode.getNodeType())
        if (oBlksNode.getNodeName().equals("blocks")) break;

    if (DebugFile.trace)
      if (null==oBlksNode)
        DebugFile.writeln("ERROR: blocks node not found");

    if (null==oBlksNode)
      throw new DOMException(DOMException.NOT_FOUND_ERR, "<blocks> node not found");

    oNodeList = ((Element) oBlksNode).getElementsByTagName("block");
    iNodeListLen = oNodeList.getLength();

    if (DebugFile.trace)
      DebugFile.writeln(String.valueOf(iNodeListLen) + " blocks found.");

    oLinkVctr = new Vector<Block>(iNodeListLen);

    for (int i=0; i<iNodeListLen; i++) {

      if (DebugFile.trace) {
        if (null==oNodeList.item(i).getAttributes().getNamedItem("id"))
          DebugFile.writeln("ERROR: Block " + String.valueOf(i) + " does not have the required id attribute.");
        else
          if (null==oNodeList.item(i).getAttributes().getNamedItem("id").getNodeValue())
            DebugFile.writeln("ERROR: Block " + String.valueOf(i) + " id attribute is null.");
          else if (oNodeList.item(i).getAttributes().getNamedItem("id").getNodeValue().length()==0)
            DebugFile.writeln("ERROR: Block " + String.valueOf(i) + " id attribute is empty.");
      }

      sPaddedID = "-" + Gadgets.leftPad(oNodeList.item(i).getAttributes().getNamedItem("id").getNodeValue(), '0', 3);

      if (DebugFile.trace)
        DebugFile.writeln("padded id = " + sPaddedID);

      if (DebugFile.trace) {
        if (((Element)oNodeList.item(i)).getElementsByTagName("metablock").getLength()==0)
          DebugFile.writeln("ERROR: No MetaBlocks found");
        else
          if (null==((Element)oNodeList.item(i)).getElementsByTagName("metablock").item(0).getFirstChild())
            DebugFile.writeln("ERROR: MetaBlock for Block " + String.valueOf(i) + " does not have the requiered id attribute");
          else
            if (((Element)oNodeList.item(i)).getElementsByTagName("metablock").item(0).getFirstChild().getNodeValue().length()==0)
              DebugFile.writeln("ERROR: MetaBlock for Block " + String.valueOf(i) + " id attribute is empty.");
            else
              DebugFile.writeln("SortedMap.put(" + ((Element)oNodeList.item(i)).getElementsByTagName("metablock").item(0).getFirstChild().getNodeValue() + sPaddedID + ", " + oNodeList.item(i).toString()+")");
      }

      oSortedMap.put(((Element)oNodeList.item(i)).getElementsByTagName("metablock").item(0).getFirstChild().getNodeValue() + sPaddedID, oNodeList.item(i));
    } // next (i)

    Iterator oIterator = oSortedMap.keySet().iterator();
    while (oIterator.hasNext()) {
      Node oAux = (Node) oSortedMap.get(oIterator.next());
      oLinkVctr.add(new Block(oAux));
      if (DebugFile.trace)
        DebugFile.writeln("Inserted " + ((Element)oAux).getElementsByTagName("metablock").item(0).getFirstChild().getNodeValue() + (new Integer(oAux.getAttributes().getNamedItem("id").getNodeValue())).intValue());
    } // wend

    oNodeList = null;
    oBlksNode = null;
    oSortedMap = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oLinkVctr)
        DebugFile.writeln("End Page.blocks() : null");
      else
        DebugFile.writeln("End Page.blocks() : "+String.valueOf(oLinkVctr.size()));
    }

    return oLinkVctr;
  } // blocks()

  // ----------------------------------------------------------

  private boolean eqnull (String s1, String s2) {
    if (DebugFile.trace) DebugFile.writeln("eqnull(" + s1 + "," + s2 + ")");

    if (s1==null)
      return true;
    else
      return s1.equals(s2);
  } // eqnull

  // ----------------------------------------------------------

  private Vector<Block> sortById(Vector<Block> vBlocks) {
  	Vector<Block> vSorted = new Vector<Block>(vBlocks.size());
  	TreeMap<String,Block> oSortedMap = new TreeMap<String,Block>();
  	for (Block oBlck : vBlocks) oSortedMap.put(oBlck.id(), oBlck);
    Iterator oIterator = oSortedMap.keySet().iterator();
    while (oIterator.hasNext()) {
      vSorted.add(oSortedMap.get(oIterator.next()));
    } // wend
    return vSorted;
  } // sortById

  // ----------------------------------------------------------

  /**
   * Get Page blocks matching a given criteria.
   * @param sMetaBlockId Identifier of metablock to match
   * @param sTag
   * @param sZone
   * @return Vector containing objects of class Block for this Page.<br>
   * Blocks are returned in source order. Independently of their id attribute value.
   * @throws DOMException If &lt;blocks&gt; node is not found
   */
  public Vector<Block> blocks(String sMetaBlockId, String sTag, String sZone)
    throws DOMException {

    if (DebugFile.trace) {
         DebugFile.writeln("Begin Page.blocks(" + sMetaBlockId + "," + sTag + "," + sZone + ")");
         DebugFile.incIdent();
       }

    Block oBlk;
    Node oAux;
    Node oBlksNode = null;
    NodeList oNodeList = null;
    int iNodeListLen = 0;
    Vector<Block> oLinkVctr = null;

    if (DebugFile.trace) {
      if (null==oNode.getFirstChild())
        DebugFile.writeln("Node.getFirstChild() returned null");
    }

    for (oBlksNode=oNode.getFirstChild(); oBlksNode!=null; oBlksNode=oBlksNode.getNextSibling())
      if (Node.ELEMENT_NODE==oBlksNode.getNodeType())
        if (oBlksNode.getNodeName().equals("blocks")) break;

    if (DebugFile.trace)
      if (null==oBlksNode)
        DebugFile.writeln("ERROR: blocks node not found");

    if (null==oBlksNode)
      throw new DOMException(DOMException.NOT_FOUND_ERR, "<blocks> node not found");

    oNodeList = ((Element) oBlksNode).getElementsByTagName("block");
    iNodeListLen = oNodeList.getLength();

    if (DebugFile.trace)
      DebugFile.writeln(String.valueOf(iNodeListLen) + " total blocks found.");

    oLinkVctr = new Vector<Block>();

    for (int i=0; i<iNodeListLen; i++) {
      oAux = oNodeList.item(i);

      if (DebugFile.trace) {
        DebugFile.writeln("scanning " + oAux);

        if (null==oAux.getAttributes().getNamedItem("id"))
          DebugFile.writeln("ERROR: Block " + String.valueOf(i) + " does not have the required id attribute.");
        else
          if (null==oAux.getAttributes().getNamedItem("id").getNodeValue())
            DebugFile.writeln("ERROR: Block " + String.valueOf(i) + " id attribute is null.");
          else if (oAux.getAttributes().getNamedItem("id").getNodeValue().length()==0)
            DebugFile.writeln("ERROR: Block " + String.valueOf(i) + " id attribute is empty.");

        if (((Element)oAux).getElementsByTagName("metablock").getLength()==0)
          DebugFile.writeln("ERROR: No MetaBlocks found");
        else
          if (null==((Element)oAux).getElementsByTagName("metablock").item(0).getFirstChild())
            DebugFile.writeln("ERROR: MetaBlock for Block " + String.valueOf(i) + " does not have the requiered id attribute");
          else
            if (((Element)oAux).getElementsByTagName("metablock").item(0).getFirstChild().getNodeValue().length()==0)
              DebugFile.writeln("ERROR: MetaBlock for Block " + String.valueOf(i) + " id attribute is empty.");

        DebugFile.writeln("new Block(" + oAux + ")");

      } // fi (DebugFile.trace)

      oBlk = new Block(oAux);

      if (eqnull(sMetaBlockId, oBlk.metablock()) && eqnull(sTag, oBlk.tag()) && eqnull(sZone, oBlk.zone())) {

        if (DebugFile.trace) DebugFile.writeln("Vector.add(" + oBlk.id() + ")");

        oLinkVctr.add(oBlk);
      }
    } // next (i)


    oNodeList = null;
    oBlksNode = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Page.blocks()");
    }

    return oLinkVctr;
  } // blocks(...)

  // ----------------------------------------------------------

  /**
   * <p>Get a list of Block identifiers in source order<p>
   * @return Array of Block Identifiers in the same order as thay appear in source document.
   * @throws NumberFormatException If any Block Id. is not an integer
   */
  public int[] blockIds() throws NumberFormatException {
    Node oBlksNode = null;
    NodeList oNodeList = null;
    int iNodeListLen = 0;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Page.blockIds()");
      DebugFile.incIdent();
    }

    for (oBlksNode=oNode.getFirstChild(); oBlksNode!=null; oBlksNode=oBlksNode.getNextSibling())
      if (Node.ELEMENT_NODE==oBlksNode.getNodeType())
        if (oBlksNode.getNodeName().equals("blocks")) break;

    oNodeList = ((Element) oBlksNode).getElementsByTagName("block");
    iNodeListLen = oNodeList.getLength();

    int[] aIds = new int[iNodeListLen];

    for (int i=0; i<iNodeListLen; i++)
      aIds[i] = Integer.parseInt(oNodeList.item(i).getAttributes().getNamedItem("id").getNodeValue());

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==aIds)
        DebugFile.writeln("End Page.blockIds() : null");
      else
        DebugFile.writeln("End Page.blockIds() : "+String.valueOf(aIds.length));
    }

    return aIds;
  } // blockIds

  // ----------------------------------------------------------

  /**
   * Get next free block integer identifier.
   * @return Left padded next free block identifier (3 characters)
   * @throws NumberFormatException If any of the previous block identifiers is not an integer.
   */
  public String nextBlockId() throws NumberFormatException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Page.nextBlockId()");
      DebugFile.incIdent();
    }

    int iBlk = 0;
    int iMax = 0;
    String sNext;
    Node oBlksNode = null;
    NodeList oNodeList = null;
    int iNodeListLen = 0;

    for (oBlksNode=oNode.getFirstChild(); oBlksNode!=null; oBlksNode=oBlksNode.getNextSibling())
      if (Node.ELEMENT_NODE==oBlksNode.getNodeType())
        if (oBlksNode.getNodeName().equals("blocks")) break;

    if (DebugFile.trace)
      if (null==oBlksNode)
        DebugFile.writeln("ERROR: blocks node not found");

    oNodeList = ((Element) oBlksNode).getElementsByTagName("block");
    iNodeListLen = oNodeList.getLength();

    int[] aBlocks = new int[iNodeListLen];

    for (int i=0; i<iNodeListLen; i++)
      aBlocks[i] = Integer.parseInt(oNodeList.item(i).getAttributes().getNamedItem("id").getNodeValue());

    for (int b=0; b<iNodeListLen; b++) {
      iBlk = aBlocks[b];
      if (iBlk>iMax) iMax=iBlk;
    } // next (b)

    // left pad with zeros
    sNext = String.valueOf(iMax+1);
    if (sNext.length()==1)
      sNext = "00" + sNext;
    else if (sNext.length()==2)
      sNext = "0" + sNext;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Page.nextBlockId() : " + sNext);
    }

  return sNext;
  } // nextBlockId

  // ----------------------------------------------------------

  /**
   * <p>Permute Blocks</p>
   * This method is used for reordering blocks.
   * @param aPermutation New order for blocks.
   * @throws ArrayIndexOutOfBoundsException
   */
  public void permute (String sMetaBlockId, int[] aPermutation)
    throws ArrayIndexOutOfBoundsException {

      if (DebugFile.trace) {
        DebugFile.writeln("Begin Page.permute("+sMetaBlockId+")");
        DebugFile.incIdent();
      }

	  Vector<Block> vFormerOrderBlcks = sortById(blocks(sMetaBlockId, null, null));
	  final int nBlocks = vFormerOrderBlcks.size();

	  if (nBlocks!=aPermutation.length)
	    throw new ArrayIndexOutOfBoundsException("Permutation length "+String.valueOf(aPermutation.length)+" does not match number of blocks of type "+sMetaBlockId+" "+String.valueOf(nBlocks));
	  
	  Vector<Block> vNewPermutedBlcks = new Vector<Block>(nBlocks); 
    		
	  for (int p=0; p<nBlocks; p++) {
	  	Block oBlk = new Block(vFormerOrderBlcks.get(aPermutation[p]).getNode().cloneNode(true));
	  	oBlk.id(vFormerOrderBlcks.get(p).id());
	    vNewPermutedBlcks.add(oBlk);
	  }

      // Search for <blocks> Node
      if (DebugFile.trace) {
        if (null==oNode.getFirstChild())
        DebugFile.writeln("Node.getFirstChild() returned null");
      }

       Node oBlksNode = null;

       for (oBlksNode=oNode.getFirstChild(); oBlksNode!=null; oBlksNode=oBlksNode.getNextSibling())
         if (Node.ELEMENT_NODE==oBlksNode.getNodeType())
           if (oBlksNode.getNodeName().equals("blocks")) break;

       if (DebugFile.trace)
         if (null==oBlksNode)
           DebugFile.writeln("ERROR: blocks node not found");

	   for (int c=0; c<nBlocks; c++) {
	   	 if (DebugFile.trace) DebugFile.writeln("removing child "+vFormerOrderBlcks.get(c).id());
	   	 oBlksNode.removeChild(vFormerOrderBlcks.get(c).getNode());
	   }
	   for (int c=0; c<nBlocks; c++) {
	   	 if (DebugFile.trace) DebugFile.writeln("append child "+vNewPermutedBlcks.get(c).id());
	   	 oBlksNode.appendChild(vNewPermutedBlcks.get(c).getNode());
	   }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Page.permute()");
      }
  } // permute
}