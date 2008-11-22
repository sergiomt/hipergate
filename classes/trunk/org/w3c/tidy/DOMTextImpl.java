/*
 * @(#)DOMTextImpl.java   1.11 2000/08/16
 *
 */

package org.w3c.tidy;

import org.w3c.dom.DOMException;

/**
 *
 * DOMTextImpl
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

public class DOMTextImpl extends DOMCharacterDataImpl
                            implements org.w3c.dom.Text {

    protected DOMTextImpl(Node adaptee)
    {
        super(adaptee);
    }


    /* --------------------- DOM ---------------------------- */

    /**
     * @see org.w3c.dom.Node#getNodeName
     */
    public String getNodeName()
    {
        return "#text";
    }

    /**
     * @see org.w3c.dom.Node#getNodeType
     */
    public short getNodeType()
    {
        return org.w3c.dom.Node.TEXT_NODE;
    }

    /**
     * @see org.w3c.dom.Text#splitText
     */
    public org.w3c.dom.Text splitText(int offset) throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    public boolean isElementContentWhitespace() throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NOT_SUPPORTED_ERR,
                                   "Not supported");
    }

    public String getWholeText() throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NOT_SUPPORTED_ERR,
                                   "Not supported");
    }

    public org.w3c.dom.Text replaceWholeText(String sTxt) throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    public org.w3c.dom.Node adoptNode (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl adoptNode() Not implemented");
    }

    public short compareDocumentPosition (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl compareDocumentPosition() Not implemented");
    }

    public boolean isDefaultNamespace(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl isDefaultNamespace() Not implemented");
    }

    public boolean isEqualNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl isEqualNode() Not implemented");
    }

    public boolean isSameNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl isSameNode() Not implemented");
    }

    public String lookupPrefix(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl lookupPreffix() Not implemented");
    }

    public String lookupNamespaceURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl lookupNamespaceURI() Not implemented");
    }

    public String getDocumentURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getDocumentURI() Not implemented");
    }

    public void setDocumentURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl setDocumentURI() Not implemented");
    }

    public boolean getStrictErrorChecking() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getStrictErrorChecking() Not implemented");
    }

    public void setStrictErrorChecking(boolean bStrictCheck) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl setStrictErrorChecking() Not implemented");
    }

    public boolean getXmlStandalone() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getXmlStandalone() Not implemented");
    }

    public void setXmlStandalone(boolean bXmlStandalone) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl setXmlStandalone() Not implemented");
    }

    public Object getFeature(String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getFeature() Not implemented");
    }

    public String getInputEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getInputEncoding() Not implemented");
    }

    public String getXmlEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getXmlEncoding() Not implemented");
    }

    public String getXmlVersion() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getXmlVersion() Not implemented");
    }

    public void setXmlVersion(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl setXmlVersion() Not implemented");
    }

    public Object getUserData(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getUserData() Not implemented");
    }

    public Object setUserData(String sStr1, Object oObj2, org.w3c.dom.UserDataHandler oHndlr) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl setUserData() Not implemented");
    }

    public org.w3c.dom.DOMConfiguration getDomConfig () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getDomConfig() Not implemented");
    }

    public void normalizeDocument () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl normalizeDocument() Not implemented");
    }

    public org.w3c.dom.Node renameNode (org.w3c.dom.Node oNode, String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl renameNode() Not implemented");
    }

    public String getBaseURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getBaseURI() Not implemented");
    }

    public String getTextContent() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl getTextContent() Not implemented");
    }

    public void setTextContent(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMTextImpl setTextContent() Not implemented");
    }

}
