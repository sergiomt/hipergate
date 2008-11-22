/*
 * @(#)DOMCommentImpl.java   1.11 2000/08/16
 *
 */

package org.w3c.tidy;

/**
 *
 * DOMCommentImpl
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

public class DOMCommentImpl extends DOMCharacterDataImpl
                            implements org.w3c.dom.Comment {

    protected DOMCommentImpl(Node adaptee)
    {
        super(adaptee);
    }


    /* --------------------- DOM ---------------------------- */

    /**
     * @see org.w3c.dom.Node#getNodeName
     */
    public String getNodeName()
    {
        return "#comment";
    }

    /**
     * @see org.w3c.dom.Node#getNodeType
     */
    public short getNodeType()
    {
        return org.w3c.dom.Node.COMMENT_NODE;
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
