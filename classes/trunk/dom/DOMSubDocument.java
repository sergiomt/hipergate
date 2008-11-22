package dom;

import org.w3c.dom.Node;
import java.util.Vector;

public class DOMSubDocument {

  protected Node oNode;

  // ----------------------------------------------------------

  private DOMSubDocument() { }

  // ----------------------------------------------------------

  public DOMSubDocument(Node oRefNode) {
    oNode = oRefNode;
  }

  // ----------------------------------------------------------

  public Node getNode() {
    return oNode;
  }

  // ----------------------------------------------------------

  public Node getNode(String sNodeName) {
    Node oCurrentNode = null;

    for (oCurrentNode=oNode.getFirstChild(); oCurrentNode!=null; oCurrentNode=oCurrentNode.getNextSibling())
      if (Node.ELEMENT_NODE==oCurrentNode.getNodeType())
        if (sNodeName.equals(oCurrentNode.getNodeName())) break;

    if (oCurrentNode!=null)
      return oCurrentNode;
    else
      return null;
  }

  // ----------------------------------------------------------

  public String getElement(String sElementName) {
    Node oCurrentNode = null;
    Node oFirstChild;

    for (oCurrentNode=oNode.getFirstChild(); oCurrentNode!=null; oCurrentNode=oCurrentNode.getNextSibling())
      if (Node.ELEMENT_NODE==oCurrentNode.getNodeType())
        if (sElementName.equals(oCurrentNode.getNodeName())) break;

    if (oCurrentNode!=null) {
      oFirstChild = oCurrentNode.getFirstChild();

      if (oFirstChild!=null)
        return oFirstChild.getNodeValue();
      else
        return null;
    }
    else
      return null;
  } // getElement()

  // ----------------------------------------------------------

  public Vector getElements(String sElementName) {
    Node oCurrentNode = null;
    Vector oVector = new Vector();

    for (oCurrentNode=oNode.getFirstChild(); oCurrentNode!=null; oCurrentNode=oCurrentNode.getNextSibling())
      if (Node.ELEMENT_NODE==oCurrentNode.getNodeType())
        if (sElementName.equals(oCurrentNode.getNodeName()))
          oVector.addElement(oCurrentNode);
    if (oVector.size()>0)
      return oVector;
    else
      return null;
  } // getElement()

}