/*
 * @(#)DOMDocumentTypeImpl.java   1.11 2000/08/16
 *
 */

package org.w3c.tidy;

/**
 *
 * DOMDocumentTypeImpl
 *
 * (c) 1998-2000 (W3C) MIT, INRIA, Keio University
 * See Tidy.java for the copyright notice.
 * Derived from <a href="http://www.w3.org/People/Raggett/tidy">
 * HTML Tidy Release 4 Aug 2000</a>
 *
 * @author  Dave Raggett <dsr@w3.org>
 * @author  Andy Quick <ac.quick@sympatico.ca> (translation to Java)
 * @version 1.7, 1999/12/06 Tidy Release 30 Nov 1999
 * @version 1.8, 2000/01/22 Tidy Release 13 Jan 2000
 * @version 1.9, 2000/06/03 Tidy Release 30 Apr 2000
 * @version 1.10, 2000/07/22 Tidy Release 8 Jul 2000
 * @version 1.11, 2000/08/16 Tidy Release 4 Aug 2000
 */

public class DOMDocumentTypeImpl extends DOMNodeImpl
                            implements org.w3c.dom.DocumentType {

    protected DOMDocumentTypeImpl(Node adaptee)
    {
        super(adaptee);
    }


    /* --------------------- DOM ---------------------------- */

    /**
     * @see org.w3c.dom.Node#getNodeType
     */
    public short getNodeType()
    {
        return org.w3c.dom.Node.DOCUMENT_TYPE_NODE;
    }

    /**
     * @see org.w3c.dom.Node#getNodeName
     */
    public String getNodeName()
    {
        return getName();
    }

    /**
     * @see org.w3c.dom.DocumentType#getName
     */
    public String             getName()
    {
        String value = null;
        if (adaptee.type == Node.DocTypeTag)
        {

            if (adaptee.textarray != null && adaptee.start < adaptee.end)
            {
                value = Lexer.getString(adaptee.textarray,
                                        adaptee.start,
                                        adaptee.end - adaptee.start);
            }
        }
        return value;
    }

    public org.w3c.dom.NamedNodeMap       getEntities()
    {
        // NOT SUPPORTED
        return null;
    }

    public org.w3c.dom.NamedNodeMap       getNotations()
    {
        // NOT SUPPORTED
        return null;
    }

    /**
     * DOM2 - not implemented.
     */
    public String getPublicId() {
	return null;
    }

    /**
     * DOM2 - not implemented.
     */
    public String getSystemId() {
	return null;
    }

    /**
     * DOM2 - not implemented.
     */
    public String getInternalSubset() {
	return null;
    }

    public org.w3c.dom.Node adoptNode (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl adoptNode() Not implemented");
    }

    public short compareDocumentPosition (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl compareDocumentPosition() Not implemented");
    }

    public boolean isDefaultNamespace(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl isDefaultNamespace() Not implemented");
    }

    public boolean isEqualNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl isEqualNode() Not implemented");
    }

    public boolean isSameNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl isSameNode() Not implemented");
    }

    public String lookupPrefix(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl lookupPreffix() Not implemented");
    }

    public String lookupNamespaceURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl lookupNamespaceURI() Not implemented");
    }

    public String getDocumentURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getDocumentURI() Not implemented");
    }

    public void setDocumentURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl setDocumentURI() Not implemented");
    }

    public boolean getStrictErrorChecking() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getStrictErrorChecking() Not implemented");
    }

    public void setStrictErrorChecking(boolean bStrictCheck) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl setStrictErrorChecking() Not implemented");
    }

    public boolean getXmlStandalone() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getXmlStandalone() Not implemented");
    }

    public void setXmlStandalone(boolean bXmlStandalone) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl setXmlStandalone() Not implemented");
    }

    public Object getFeature(String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getFeature() Not implemented");
    }

    public String getInputEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getInputEncoding() Not implemented");
    }

    public String getXmlEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getXmlEncoding() Not implemented");
    }

    public String getXmlVersion() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getXmlVersion() Not implemented");
    }

    public void setXmlVersion(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl setXmlVersion() Not implemented");
    }

    public Object getUserData(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getUserData() Not implemented");
    }

    public Object setUserData(String sStr1, Object oObj2, org.w3c.dom.UserDataHandler oHndlr) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl setUserData() Not implemented");
    }

    public org.w3c.dom.DOMConfiguration getDomConfig () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getDomConfig() Not implemented");
    }

    public void normalizeDocument () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl normalizeDocument() Not implemented");
    }

    public org.w3c.dom.Node renameNode (org.w3c.dom.Node oNode, String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl renameNode() Not implemented");
    }

    public String getBaseURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getBaseURI() Not implemented");
    }

    public String getTextContent() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl getTextContent() Not implemented");
    }

    public void setTextContent(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMDocumentTypeImpl setTextContent() Not implemented");
    }
}
