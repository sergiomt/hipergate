/*
 * @(#)DOMCharacterDataImpl.java   1.11 2000/08/16
 *
 */

package org.w3c.tidy;

import org.w3c.dom.DOMException;

/**
 *
 * DOMCharacterDataImpl
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

public class DOMCharacterDataImpl extends DOMNodeImpl
                            implements org.w3c.dom.CharacterData {

    protected DOMCharacterDataImpl(Node adaptee)
    {
        super(adaptee);
    }


    /* --------------------- DOM ---------------------------- */

    /**
     * @see org.w3c.dom.CharacterData#getData
     */
    public String getData() throws DOMException
    {
        return getNodeValue();
    }

    /**
     * @see org.w3c.dom.CharacterData#setData
     */
    public void setData(String data) throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    /**
     * @see org.w3c.dom.CharacterData#getLength
     */
    public int getLength()
    {
        int len = 0;
        if (adaptee.textarray != null && adaptee.start < adaptee.end)
            len = adaptee.end - adaptee.start;
        return len;
    }

    /**
     * @see org.w3c.dom.CharacterData#substringData
     */
    public String substringData(int offset,
                                int count) throws DOMException
    {
        int len;
        String value = null;
        if (count < 0)
        {
            throw new DOMExceptionImpl(DOMException.INDEX_SIZE_ERR,
                                       "Invalid length");
        }
        if (adaptee.textarray != null && adaptee.start < adaptee.end)
        {
            if (adaptee.start + offset >= adaptee.end)
            {
                throw new DOMExceptionImpl(DOMException.INDEX_SIZE_ERR,
                                           "Invalid offset");
            }
            len = count;
            if (adaptee.start + offset + len - 1 >= adaptee.end)
                len = adaptee.end - adaptee.start - offset;

            value = Lexer.getString(adaptee.textarray,
                                    adaptee.start + offset,
                                    len);
        }
        return value;
    }

    /**
     * @see org.w3c.dom.CharacterData#appendData
     */
    public void appendData(String arg) throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    /**
     * @see org.w3c.dom.CharacterData#insertData
     */
    public void insertData(int offset,
                           String arg) throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    /**
     * @see org.w3c.dom.CharacterData#deleteData
     */
    public void deleteData(int offset,
                           int count) throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    /**
     * @see org.w3c.dom.CharacterData#replaceData
     */
    public void replaceData(int offset,
                            int count,
                            String arg) throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    public org.w3c.dom.Node adoptNode (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl adoptNode() Not implemented");
    }

    public short compareDocumentPosition (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl compareDocumentPosition() Not implemented");
    }

    public boolean isDefaultNamespace(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl isDefaultNamespace() Not implemented");
    }

    public boolean isEqualNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl isEqualNode() Not implemented");
    }

    public boolean isSameNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl isSameNode() Not implemented");
    }

    public String lookupPrefix(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl lookupPreffix() Not implemented");
    }

    public String lookupNamespaceURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl lookupNamespaceURI() Not implemented");
    }

    public String getDocumentURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getDocumentURI() Not implemented");
    }

    public void setDocumentURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl setDocumentURI() Not implemented");
    }

    public boolean getStrictErrorChecking() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getStrictErrorChecking() Not implemented");
    }

    public void setStrictErrorChecking(boolean bStrictCheck) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl setStrictErrorChecking() Not implemented");
    }

    public boolean getXmlStandalone() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getXmlStandalone() Not implemented");
    }

    public void setXmlStandalone(boolean bXmlStandalone) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl setXmlStandalone() Not implemented");
    }

    public Object getFeature(String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getFeature() Not implemented");
    }

    public String getInputEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getInputEncoding() Not implemented");
    }

    public String getXmlEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getXmlEncoding() Not implemented");
    }

    public String getXmlVersion() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getXmlVersion() Not implemented");
    }

    public void setXmlVersion(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl setXmlVersion() Not implemented");
    }

    public Object getUserData(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getUserData() Not implemented");
    }

    public Object setUserData(String sStr1, Object oObj2, org.w3c.dom.UserDataHandler oHndlr) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl setUserData() Not implemented");
    }

    public org.w3c.dom.DOMConfiguration getDomConfig () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getDomConfig() Not implemented");
    }

    public void normalizeDocument () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl normalizeDocument() Not implemented");
    }

    public org.w3c.dom.Node renameNode (org.w3c.dom.Node oNode, String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl renameNode() Not implemented");
    }

    public String getBaseURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getBaseURI() Not implemented");
    }

    public String getTextContent() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl getTextContent() Not implemented");
    }

    public void setTextContent(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMCharacterDataImpl setTextContent() Not implemented");
    }

}
