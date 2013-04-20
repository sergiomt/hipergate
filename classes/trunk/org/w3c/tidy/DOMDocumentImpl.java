/*
 * @(#)DOMDocumentImpl.java   1.11 2000/08/16
 *
 */

package org.w3c.tidy;

import org.w3c.dom.DOMException;

/**
 *
 * DOMDocumentImpl
 *
 * (c) 1998-2000 (W3C) MIT, INRIA, Keio University
 * See Tidy.java for the copyright notice.
 * Derived from <a href="http://www.w3.org/People/Raggett/tidy">
 * HTML Tidy Release 4 Aug 2000</a>
 *
 * @author  Dave Raggett <dsr@w3.org>
 * @author  Andy Quick <ac.quick@sympatico.ca> (translation to Java)
 * @version 1.4, 1999/09/04 DOM Support
 * @version 1.5, 1999/10/23 Tidy Release 27 Sep 1999
 * @version 1.6, 1999/11/01 Tidy Release 22 Oct 1999
 * @version 1.7, 1999/12/06 Tidy Release 30 Nov 1999
 * @version 1.8, 2000/01/22 Tidy Release 13 Jan 2000
 * @version 1.9, 2000/06/03 Tidy Release 30 Apr 2000
 * @version 1.10, 2000/07/22 Tidy Release 8 Jul 2000
 * @version 1.11, 2000/08/16 Tidy Release 4 Aug 2000
 */

public class DOMDocumentImpl extends DOMNodeImpl implements org.w3c.dom.Document {

    private TagTable tt;      // a DOM Document has its own TagTable.

    protected DOMDocumentImpl(Node adaptee)
    {
        super(adaptee);
        tt = new TagTable();
    }

    public void setTagTable(TagTable tt)
    {
        this.tt = tt;
    }

    /* --------------------- DOM ---------------------------- */

    /**
     * @see org.w3c.dom.Node#getNodeName
     */
    public String getNodeName()
    {
        return "#document";
    }

    /**
     * @see org.w3c.dom.Node#getNodeType
     */
    public short getNodeType()
    {
        return org.w3c.dom.Node.DOCUMENT_NODE;
    }

    /**
     * @see org.w3c.dom.Document#getDoctype
     */
    public org.w3c.dom.DocumentType       getDoctype()
    {
        Node node = adaptee.content;
        while (node != null) {
            if (node.type == Node.DocTypeTag) break;
            node = node.next;
        }
        if (node != null)
            return (org.w3c.dom.DocumentType)node.getAdapter();
        else
            return null;
    }

    /**
     * @see org.w3c.dom.Document#getImplementation
     */
    public org.w3c.dom.DOMImplementation  getImplementation()
    {
        // NOT SUPPORTED
        return null;
    }

    /**
     * @see org.w3c.dom.Document#getDocumentElement
     */
    public org.w3c.dom.Element            getDocumentElement()
    {
        Node node = adaptee.content;
        while (node != null) {
            if (node.type == Node.StartTag ||
                node.type == Node.StartEndTag) break;
            node = node.next;
        }
        if (node != null)
            return (org.w3c.dom.Element)node.getAdapter();
        else
            return null;
    }

    /**
     * @see org.w3c.dom.Document#createElement
     */
    public org.w3c.dom.Element            createElement(String tagName)
                                            throws DOMException
    {
        Node node = new Node(Node.StartEndTag, null, 0, 0, tagName, tt);
        if (node.tag == null)           // Fix Bug 121206
          node.tag = tt.xmlTags;
        return (org.w3c.dom.Element) node.getAdapter();
    }

    /**
     * @see org.w3c.dom.Document#createDocumentFragment
     */
    public org.w3c.dom.DocumentFragment   createDocumentFragment()
    {
        // NOT SUPPORTED
        return null;
    }

    /**
     * @see org.w3c.dom.Document#createTextNode
     */
    public org.w3c.dom.Text               createTextNode(String data)
    {
        byte[] textarray = Lexer.getBytes(data);
        Node node = new Node(Node.TextNode, textarray, 0, textarray.length);
        return (org.w3c.dom.Text)node.getAdapter();
    }

    /**
     * @see org.w3c.dom.Document#createComment
     */
    public org.w3c.dom.Comment            createComment(String data)
    {
        byte[] textarray = Lexer.getBytes(data);
        Node node = new Node(Node.CommentTag, textarray, 0, textarray.length);
        if (node != null)
            return (org.w3c.dom.Comment)node.getAdapter();
        else
            return null;
    }

    /**
     * @see org.w3c.dom.Document#createCDATASection
     */
    public org.w3c.dom.CDATASection       createCDATASection(String data)
                                                 throws DOMException
    {
        // NOT SUPPORTED
        return null;
    }

    /**
     * @see org.w3c.dom.Document#createProcessingInstruction
     */
    public org.w3c.dom.ProcessingInstruction createProcessingInstruction(String target,
                                                          String data)
                                                          throws DOMException
    {
        throw new DOMExceptionImpl(DOMException.NOT_SUPPORTED_ERR,
                                   "HTML document");
    }

    /**
     * @see org.w3c.dom.Document#createAttribute
     */
    public org.w3c.dom.Attr               createAttribute(String name)
                                              throws DOMException
    {
        AttVal av = new AttVal(null, null, (int)'"', name, null);
        if (av != null) {
            av.dict =
                AttributeTable.getDefaultAttributeTable().findAttribute(av);
            return (org.w3c.dom.Attr)av.getAdapter();
        } else {
            return null;
        }
    }

    /**
     * @see org.w3c.dom.Document#createEntityReference
     */
    public org.w3c.dom.EntityReference    createEntityReference(String name)
                                                    throws DOMException
    {
        // NOT SUPPORTED
        return null;
    }

    /**
     * @see org.w3c.dom.Document#getElementsByTagName
     */
    public org.w3c.dom.NodeList           getElementsByTagName(String tagname)
    {
        return new DOMNodeListByTagNameImpl(this.adaptee, tagname);
    }

    /**
     * DOM2 - not implemented.
     * @exception   org.w3c.dom.DOMException
     */
    public org.w3c.dom.Node importNode(org.w3c.dom.Node importedNode, boolean deep)
        throws org.w3c.dom.DOMException
    {
	return null;
    }

    /**
     * DOM2 - not implemented.
     * @exception   org.w3c.dom.DOMException
     */
    public org.w3c.dom.Attr createAttributeNS(String namespaceURI,
                                              String qualifiedName)
        throws org.w3c.dom.DOMException
    {
	return null;
    }

    /**
     * DOM2 - not implemented.
     * @exception   org.w3c.dom.DOMException
     */
    public org.w3c.dom.Element createElementNS(String namespaceURI,
                                               String qualifiedName)
        throws org.w3c.dom.DOMException
    {
	return null;
    }

    /**
     * DOM2 - not implemented.
     */
    public org.w3c.dom.NodeList getElementsByTagNameNS(String namespaceURI,
                                                       String localName)
    {
	return null;
    }

    /**
     * DOM2 - not implemented.
     */
    public org.w3c.dom.Element getElementById(String elementId)
    {
	return null;
    }

    public org.w3c.dom.Node adoptNode (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl adoptNode() Not implemented");
    }

    public short compareDocumentPosition (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl compareDocumentPosition() Not implemented");
    }

    public boolean isDefaultNamespace(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl isDefaultNamespace() Not implemented");
    }

    public boolean isEqualNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl isEqualNode() Not implemented");
    }

    public boolean isSameNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl isSameNode() Not implemented");
    }

    public String lookupPrefix(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl lookupPreffix() Not implemented");
    }

    public String lookupNamespaceURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl lookupNamespaceURI() Not implemented");
    }

    public String getDocumentURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getDocumentURI() Not implemented");
    }

    public void setDocumentURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl setDocumentURI() Not implemented");
    }

    public boolean getStrictErrorChecking() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getStrictErrorChecking() Not implemented");
    }

    public void setStrictErrorChecking(boolean bStrictCheck) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl setStrictErrorChecking() Not implemented");
    }

    public boolean getXmlStandalone() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getXmlStandalone() Not implemented");
    }

    public void setXmlStandalone(boolean bXmlStandalone) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl setXmlStandalone() Not implemented");
    }

    public Object getFeature(String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getFeature() Not implemented");
    }

    public String getInputEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getInputEncoding() Not implemented");
    }

    public String getXmlEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getXmlEncoding() Not implemented");
    }

    public String getXmlVersion() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getXmlVersion() Not implemented");
    }

    public void setXmlVersion(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl setXmlVersion() Not implemented");
    }

    public Object getUserData(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getUserData() Not implemented");
    }

    public Object setUserData(String sStr1, Object oObj2, org.w3c.dom.UserDataHandler oHndlr) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl setUserData() Not implemented");
    }

    public org.w3c.dom.DOMConfiguration getDomConfig () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getDomConfig() Not implemented");
    }

    public void normalizeDocument () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl normalizeDocument() Not implemented");
    }

    public org.w3c.dom.Node renameNode (org.w3c.dom.Node oNode, String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl renameNode() Not implemented");
    }

    public String getBaseURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getBaseURI() Not implemented");
    }

    public String getTextContent() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl getTextContent() Not implemented");
    }

    public void setTextContent(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentImpl setTextContent() Not implemented");
    }

}
