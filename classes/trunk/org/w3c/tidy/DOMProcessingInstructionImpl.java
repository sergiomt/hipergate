/*
 * @(#)DOMProcessingInstructionImpl.java   1.11 2000/08/16
 *
 */

package org.w3c.tidy;

import org.w3c.dom.DOMException;

/**
 *
 * DOMProcessingInstructionImpl
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

public class DOMProcessingInstructionImpl extends DOMNodeImpl
                            implements org.w3c.dom.ProcessingInstruction {

    protected DOMProcessingInstructionImpl(Node adaptee)
    {
        super(adaptee);
    }


    /* --------------------- DOM ---------------------------- */

    /**
     * @see org.w3c.dom.Node#getNodeType
     */
    public short getNodeType()
    {
        return org.w3c.dom.Node.PROCESSING_INSTRUCTION_NODE;
    }

    /**
     * @see org.w3c.dom.ProcessingInstruction#getTarget
     */
    public String getTarget()
    {
        // TODO
        return null;
    }

    /**
     * @see org.w3c.dom.ProcessingInstruction#getData
     */
    public String getData()
    {
        return getNodeValue();
    }

    /**
     * @see org.w3c.dom.ProcessingInstruction#setData
     */
    public void setData(String data) throws DOMException
    {
        // NOT SUPPORTED
        throw new DOMExceptionImpl(DOMException.NO_MODIFICATION_ALLOWED_ERR,
                                   "Not supported");
    }

    public org.w3c.dom.Node adoptNode (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl adoptNode() Not implemented");
    }

    public short compareDocumentPosition (org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl compareDocumentPosition() Not implemented");
    }

    public boolean isDefaultNamespace(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl isDefaultNamespace() Not implemented");
    }

    public boolean isEqualNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl isEqualNode() Not implemented");
    }

    public boolean isSameNode(org.w3c.dom.Node oNode) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl isSameNode() Not implemented");
    }

    public String lookupPrefix(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl lookupPreffix() Not implemented");
    }

    public String lookupNamespaceURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl lookupNamespaceURI() Not implemented");
    }

    public String getDocumentURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getDocumentURI() Not implemented");
    }

    public void setDocumentURI(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl setDocumentURI() Not implemented");
    }

    public boolean getStrictErrorChecking() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getStrictErrorChecking() Not implemented");
    }

    public void setStrictErrorChecking(boolean bStrictCheck) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl setStrictErrorChecking() Not implemented");
    }

    public boolean getXmlStandalone() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getXmlStandalone() Not implemented");
    }

    public void setXmlStandalone(boolean bXmlStandalone) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl setXmlStandalone() Not implemented");
    }

    public Object getFeature(String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getFeature() Not implemented");
    }

    public String getInputEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getInputEncoding() Not implemented");
    }

    public String getXmlEncoding() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getXmlEncoding() Not implemented");
    }

    public String getXmlVersion() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getXmlVersion() Not implemented");
    }

    public void setXmlVersion(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl setXmlVersion() Not implemented");
    }

    public Object getUserData(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getUserData() Not implemented");
    }

    public Object setUserData(String sStr1, Object oObj2, org.w3c.dom.UserDataHandler oHndlr) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl setUserData() Not implemented");
    }

    public org.w3c.dom.DOMConfiguration getDomConfig () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getDomConfig() Not implemented");
    }

    public void normalizeDocument () {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl normalizeDocument() Not implemented");
    }

    public org.w3c.dom.Node renameNode (org.w3c.dom.Node oNode, String sStr1, String sStr2) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl renameNode() Not implemented");
    }

    public String getBaseURI() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getBaseURI() Not implemented");
    }

    public String getTextContent() {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl getTextContent() Not implemented");
    }

    public void setTextContent(String sStr1) {
      throw new UnsupportedOperationException("org.w3c.tidy.DOMProcessingInstructionImpl setTextContent() Not implemented");
    }
}
