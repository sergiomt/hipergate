/*
 * @(#)DOMAttrImpl.java   1.11 2000/08/16
 *
 */

package org.w3c.tidy;

import org.w3c.dom.DOMException;

/**
 *
 * DOMAttrImpl
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

public class DOMAttrImpl extends DOMNodeImpl implements org.w3c.dom.Attr {

    protected AttVal avAdaptee;

    protected DOMAttrImpl(AttVal adaptee)
    {
        super(null); // must override all methods of DOMNodeImpl
        this.avAdaptee = adaptee;
    }


    /* --------------------- DOM ---------------------------- */

    public String getNodeValue() throws DOMException
    {
        return getValue();
    }

    public void setNodeValue(String nodeValue) throws DOMException
    {
        setValue(nodeValue);
    }

    public String getNodeName()
    {
        return getName();
    }

    public short getNodeType()
    {
        return org.w3c.dom.Node.ATTRIBUTE_NODE;
    }

    public org.w3c.dom.Node getParentNode()
    {
        return null;
    }

    public org.w3c.dom.NodeList getChildNodes()
    {
        // NOT SUPPORTED
        return null;
    }

    public org.w3c.dom.Node getFirstChild()
    {
        // NOT SUPPORTED
        return null;
    }

    public org.w3c.dom.Node getLastChild()
    {
        // NOT SUPPORTED
        return null;
    }

    public org.w3c.dom.Node getPreviousSibling()
    {
        return null;
    }

    public org.w3c.dom.Node getNextSibling()
    {
        return null;
    }

    public org.w3c.dom.NamedNodeMap getAttributes()
    {
        return null;
    }

    public org.w3c.dom.Document getOwnerDocument()
    {
        return null;
    }

    public org.w3c.dom.Node insertBefore(org.w3c.dom.Node newChild,
                                         org.w3c.dom.Node refChild)
                                             throws DOMException
    {
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    public org.w3c.dom.Node replaceChild(org.w3c.dom.Node newChild,
                                         org.w3c.dom.Node oldChild)
                                             throws DOMException
    {
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    public org.w3c.dom.Node removeChild(org.w3c.dom.Node oldChild)
                                            throws DOMException
    {
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    public org.w3c.dom.Node appendChild(org.w3c.dom.Node newChild)
                                            throws DOMException
    {
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    public boolean hasChildNodes()
    {
        return false;
    }

    public org.w3c.dom.Node cloneNode(boolean deep)
    {
        return null;
    }

    /**
     * @see org.w3c.dom.Attr#getName
     */
    public String getName()
    {
        return avAdaptee.attribute;
    }

    /**
     * @see org.w3c.dom.Attr#getSpecified
     */
    public boolean getSpecified()
    {
        return true;
    }

    /**
     * Returns value of this attribute.  If this attribute has a null value,
     * then the attribute name is returned instead.
     * Thanks to Brett Knights <brett@knightsofthenet.com> for this fix.
     * @see org.w3c.dom.Attr#getValue
     *
     */
    public String getValue()
    {
        return (avAdaptee.value == null) ? avAdaptee.attribute : avAdaptee.value ;
    }

    /**
     * @see org.w3c.dom.Attr#setValue
     */
    public void setValue(String value)
    {
        avAdaptee.value = value;
    }

    /**
     * DOM2 - not implemented.
     */
    public org.w3c.dom.Element getOwnerElement() {
	return null;
    }

    public boolean isId() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl isId() Not implemented");
    }

    public org.w3c.dom.TypeInfo getSchemaTypeInfo() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getSchemaTypeInfo() Not implemented");
    }

    public org.w3c.dom.Node adoptNode (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl adoptNode() Not implemented");
    }

    public short compareDocumentPosition (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl compareDocumentPosition() Not implemented");
    }

    public boolean isDefaultNamespace(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl isDefaultNamespace() Not implemented");
    }

    public boolean isEqualNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl isEqualNode() Not implemented");
    }

    public boolean isSameNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl isSameNode() Not implemented");
    }

    public String lookupPrefix(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl lookupPreffix() Not implemented");
    }

    public String lookupNamespaceURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl lookupNamespaceURI() Not implemented");
    }

    public String getDocumentURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getDocumentURI() Not implemented");
    }

    public void setDocumentURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl setDocumentURI() Not implemented");
    }

    public boolean getStrictErrorChecking() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getStrictErrorChecking() Not implemented");
    }

    public void setStrictErrorChecking(boolean bStrictCheck) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl setStrictErrorChecking() Not implemented");
    }

    public boolean getXmlStandalone() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getXmlStandalone() Not implemented");
    }

    public void setXmlStandalone(boolean bXmlStandalone) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl setXmlStandalone() Not implemented");
    }

    public Object getFeature(String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getFeature() Not implemented");
    }

    public String getInputEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getInputEncoding() Not implemented");
    }

    public String getXmlEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getXmlEncoding() Not implemented");
    }

    public String getXmlVersion() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getXmlVersion() Not implemented");
    }

    public void setXmlVersion(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl setXmlVersion() Not implemented");
    }

    public Object getUserData(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getUserData() Not implemented");
    }

    public Object setUserData(String sStr1, Object oObj2, org.w3c.dom.UserDataHandler oHndlr) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl setUserData() Not implemented");
    }

    public org.w3c.dom.DOMConfiguration getDomConfig () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getDomConfig() Not implemented");
    }

    public void normalizeDocument () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl normalizeDocument() Not implemented");
    }

    public org.w3c.dom.Node renameNode (org.w3c.dom.Node oNode, String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl renameNode() Not implemented");
    }

    public String getBaseURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getBaseURI() Not implemented");
    }

    public String getTextContent() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl getTextContent() Not implemented");
    }

    public void setTextContent(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMAttrImpl setTextContent() Not implemented");
    }

}
