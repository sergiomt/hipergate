package dom;

import java.lang.ClassNotFoundException;
import java.lang.IllegalAccessException;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.io.UTFDataFormatException;
import java.io.Writer;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.Reader;
import java.io.FileReader;
import java.io.InputStreamReader;

import java.util.Vector;

import org.w3c.dom.*;
import org.xml.sax.InputSource;
import org.xml.sax.SAXNotRecognizedException;
import org.xml.sax.SAXNotSupportedException;

import com.knowgate.debug.DebugFile;

public class DOMDocument {

    //---------------------------------------------------------
    // Private Member Variables

    private String sEncoding;
    private boolean bCanonical;
    private boolean bValidation;
    private boolean bNamespaces;
    private Writer oPrtWritter;
    private Document oDocument;

    //---------------------------------------------------------
    // Constructors

    /**
     * <p>Create new DOMDocument</p>
     * Default properties:<br>
     * canonical = <b>false</b>
     * validation = <b>false</b>
     * namespaces = <b>true</b>
     * enconding = ISO-8859-1
     */
    public DOMDocument() {
      if (DebugFile.trace) DebugFile.writeln("new DOMDocument()");

      bCanonical = false;
      bValidation = false;
      bNamespaces = true;
      sEncoding = "UTF-8";
    } // DOMDocument()

    /**
     * <p>Create new DOMDocument</p>
     * @param sEncodingType Encoding {ISO-8859-1, UTF-8, UTF-16, ASCII-7, ...}
     * @param bValidateXML Activate/Deactivate schema-validation
     * @param bCanonicalXML Activate/Deactivate Canonical XML
     */
    public DOMDocument(String sEncodingType, boolean bValidateXML, boolean bCanonicalXML) {
      if (DebugFile.trace) DebugFile.writeln("new DOMDocument(" + sEncodingType + "," + String.valueOf(bValidateXML) + "," + String.valueOf(bCanonicalXML) + ")");

      bCanonical = bCanonicalXML;
      bValidation = bValidateXML;
      bNamespaces = true;
      sEncoding = sEncodingType;
    } // DOMDocument()

    /**
     * <p>Create a DOMDocument from an XML Document</p>
     * @param oW3CDoc org.w3c.dom.Document
     */
    public DOMDocument(Document oW3CDoc) {
      if (DebugFile.trace) DebugFile.writeln("new DOMDocument([Document])");

      bCanonical = false;
      bValidation = false;
      bNamespaces = true;
      sEncoding = "UTF-8";
      oDocument = oW3CDoc;
    } // DOMDocument()

    //---------------------------------------------------------
    // Methods

    public Document getDocument() {
      return oDocument;
    } // getDocument()

    //---------------------------------------------------------

    public Node getRootNode() {
      return oDocument;
    } // getRootNode()

    //---------------------------------------------------------

    public Element getRootElement() {
      return oDocument.getDocumentElement();
    } // getRootElement()

    //---------------------------------------------------------

    public String getAttribute(Node oNode, String sAttrName) {
      NamedNodeMap oMap = oNode.getAttributes();
      Node oItem = oMap.getNamedItem(sAttrName);

      if (null==oItem)
        return null;
      else
        return oItem.getNodeValue();
    } // getAttribute()

    //---------------------------------------------------------

    public void setAttribute(Node oNode, String sAttrName, String sAttrValue) {
      Attr oAttr = oDocument.createAttribute(sAttrName);
      oAttr.setNodeValue(sAttrValue);
      ((Element) oNode).setAttributeNode(oAttr);
    } // setAttribute()


    //---------------------------------------------------------

    public boolean getValidation()  {
      return bValidation;
    }

    //---------------------------------------------------------

    public void setValidation(boolean bValidate)  {
      bValidation = bValidate;
    }

    //---------------------------------------------------------

    public boolean getNamesSpaces()  {
      return bNamespaces;
    }

    //---------------------------------------------------------

    public void setNamesSpaces(boolean bNames)  {
      bNamespaces = bNames;
    }

    //---------------------------------------------------------

    public String getWriterEncoding() {
      return sEncoding;
    } // getWriterEncoding()

    // ----------------------------------------------------------

    public String getTextValue(Element oElement) {
      return oElement.getFirstChild().getNodeValue();
    } // getTextValue()

    // ----------------------------------------------------------

    public Element getFirstElement(Node oParent) {
      Node oCurrentNode = null;

      for (oCurrentNode=oParent.getFirstChild(); oCurrentNode!=null; oCurrentNode=oCurrentNode.getNextSibling())
        if (Node.ELEMENT_NODE==oCurrentNode.getNodeType())
          break;

      return (Element) oCurrentNode;
    } // getFirstElement()

    // ----------------------------------------------------------

    public Element getNextElement(Node oPreviousSibling) {
      Node oCurrentNode = null;

      for (oCurrentNode=oPreviousSibling.getNextSibling(); oCurrentNode!=null; oCurrentNode=oCurrentNode.getNextSibling())
        if (Node.ELEMENT_NODE==oCurrentNode.getNodeType())
          break;

      return (Element) oCurrentNode;
    } // getNextElement()

    // ----------------------------------------------------------

    public Element seekChildByName(Node oParent, String sName) {
      // Busca el nodo hijo que tenga un nombre dado
      Node oCurrentNode = null;
      String sCurrentName;

      for (oCurrentNode=getFirstElement(oParent); oCurrentNode!=null; oCurrentNode=getNextElement(oCurrentNode)) {
        sCurrentName = oCurrentNode.getNodeName();
        if (sName.equals(sCurrentName))
          break;
      } // next(oCurrentNode)

      return (Element) oCurrentNode;
    } // seekChildByName()

    // ----------------------------------------------------------

    public Element seekChildByAttr(Node oParent, String sAttrName, String sAttrValue) {
      // Busca el nodo hijo que tenga un atributo con un valor determinado
      Node oCurrentNode = null;

      for (oCurrentNode=getFirstElement(oParent); oCurrentNode!=null; oCurrentNode=getNextElement(oCurrentNode)) {
        if (getAttribute(oCurrentNode, sAttrName).equals(sAttrValue)) break;
      } // next(iNode)

      return (Element) oCurrentNode;
    } // seekChildByName()

    //---------------------------------------------------------

    public void parseURI(String sURI, String sEncoding)
      throws ClassNotFoundException, UTFDataFormatException,
             IllegalAccessException, InstantiationException,
             FileNotFoundException, UnsupportedEncodingException, IOException,
             SAXNotSupportedException, SAXNotRecognizedException, Exception {

      Class oXerces;
      Reader oReader;
      DOMParserWrapper oParserWrapper;

      if (DebugFile.trace) {
        DebugFile.writeln("Begin DOMDocument.parseURI(" + sURI + "," + sEncoding + ")");
        DebugFile.incIdent();
        DebugFile.writeln("Class.forName(dom.wrappers.Xerces).newInstance()");
      }

      oXerces = Class.forName("dom.wrappers.Xerces");

      if (null==oXerces)
        throw new ClassNotFoundException("dom.wrappers.Xerces");

      oParserWrapper = (DOMParserWrapper) oXerces.newInstance();

      if (DebugFile.trace)  {
        DebugFile.writeln("validation=" + String.valueOf(bValidation));
        DebugFile.writeln("namesapces=" + String.valueOf(bNamespaces));
      }

      oParserWrapper.setFeature("http://xml.org/sax/features/namespaces", bNamespaces);

      oParserWrapper.setFeature("http://xml.org/sax/features/validation", bValidation);
      oParserWrapper.setFeature("http://apache.org/xml/features/validation/schema", bValidation);
      oParserWrapper.setFeature("http://apache.org/xml/features/validation/schema-full-checking", bValidation);

      if (sURI.startsWith("file://")) {
        File oXMLFile = new File(sURI.substring(7));
        if (!oXMLFile.exists()) throw new FileNotFoundException("DOMDocument.parseURI(" + sURI.substring(7) + ") file not found");
        if (null==sEncoding) {
          if (DebugFile.trace) DebugFile.writeln("new FileReader(" + sURI.substring(7) + ")");
          oReader = new FileReader(oXMLFile);
          if (DebugFile.trace) DebugFile.writeln("DOMParserWrapper.parse([InputSource])");
        } else {
          oReader = new InputStreamReader(new FileInputStream(oXMLFile), sEncoding);
        }
        if (DebugFile.trace) DebugFile.writeln("DOMParserWrapper.parse(new InputSource(FileInputStream))");
        oDocument = oParserWrapper.parse(new InputSource(oReader));
        oReader.close();
      }
      else {
        File oXMLFile = new File(sURI);
        if (!oXMLFile.exists()) throw new FileNotFoundException("DOMDocument.parseURI(" + sURI + ") file not found");
        if (null==sEncoding) {
          if (DebugFile.trace) DebugFile.writeln("new FileReader(" + sURI + ")");
          oReader = new FileReader(oXMLFile);
          if (DebugFile.trace) DebugFile.writeln("DOMParserWrapper.parse([InputSource])");
        } else {
          oReader = new InputStreamReader(new FileInputStream(oXMLFile), sEncoding);
        }
        if (DebugFile.trace) DebugFile.writeln("DOMParserWrapper.parse(new InputSource(FileInputStream))");
        oDocument = oParserWrapper.parse(new InputSource(oReader));
        oReader.close();
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DOMDocument.parseURI()");
      }

    } // parseURI()

    //---------------------------------------------------------

    public void parseURI(String sURI)
      throws ClassNotFoundException, UTFDataFormatException,
             FileNotFoundException, IllegalAccessException,
             InstantiationException, IOException, Exception,
             SAXNotSupportedException, SAXNotRecognizedException {
      parseURI(sURI,null);
    }

    //---------------------------------------------------------

    public void parseStream(InputStream oStrm)
      throws ClassNotFoundException, IllegalAccessException, UTFDataFormatException,
      InstantiationException,  SAXNotSupportedException, SAXNotRecognizedException,
      Exception {

      Class oXerces;
      DOMParserWrapper oParserWrapper;

      if (DebugFile.trace) {
        DebugFile.writeln("Begin DOMDocument.parseStream()");
        DebugFile.incIdent();
        DebugFile.writeln("Class.forName(dom.wrappers.Xerces).newInstance()");
      }

      oXerces = Class.forName("dom.wrappers.Xerces");

      if (null==oXerces)
        throw new ClassNotFoundException("dom.wrappers.Xerces");

      oParserWrapper = (DOMParserWrapper) oXerces.newInstance();

      if (DebugFile.trace)  {
        DebugFile.writeln("validation=" + String.valueOf(bValidation));
        DebugFile.writeln("namesapces=" + String.valueOf(bNamespaces));
      }

      oParserWrapper.setFeature("http://xml.org/sax/features/namespaces", bNamespaces);

      oParserWrapper.setFeature("http://xml.org/sax/features/validation", bValidation);
      oParserWrapper.setFeature("http://apache.org/xml/features/validation/schema", bValidation);
      oParserWrapper.setFeature("http://apache.org/xml/features/validation/schema-full-checking", bValidation);

      if (DebugFile.trace) DebugFile.writeln("DOMParserWrapper.parse([InputSource])");

      oDocument = oParserWrapper.parse(new InputSource(oStrm));

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DOMDocument.parseStream()");
      }

    } // parseStream()

    //---------------------------------------------------------

/*
    public void parseString(String sXML)
      throws ClassNotFoundException, IllegalAccessException, UTFDataFormatException, Exception {

      Class oXerces;
      DOMParserWrapper oParserWrapper;

      if (DebugFile.trace) {
        DebugFile.writeln("Begin DOMDocument.parseString(" + sXML + ")");
        DebugFile.incIdent();
        DebugFile.writeln("Class.forName(dom.wrappers.Xerces).newInstance()");
      }

      oXerces = Class.forName("dom.wrappers.Xerces");

      if (null==oXerces)
        throw new ClassNotFoundException("dom.wrappers.Xerces");

      oParserWrapper = (DOMParserWrapper) oXerces.newInstance();

      if (DebugFile.trace)  {
        DebugFile.writeln("validation=" + String.valueOf(bValidation));
        DebugFile.writeln("namesapces=" + String.valueOf(bNamespaces));
      }

      oParserWrapper.setFeature("http://xml.org/sax/features/namespaces", bNamespaces);

      oParserWrapper.setFeature("http://xml.org/sax/features/validation", bValidation);
      oParserWrapper.setFeature("http://apache.org/xml/features/validation/schema", bValidation);
      oParserWrapper.setFeature("http://apache.org/xml/features/validation/schema-full-checking", bValidation);

      if (DebugFile.trace) DebugFile.writeln("new StringBufferInputStream(\n" + sXML + "\n)");

      StringBufferInputStream oStrStream = new StringBufferInputStream(sXML);
      InputSource oInputSrc = new InputSource(oStrStream);

      if (DebugFile.trace) DebugFile.writeln("DOMParserWrapper.parse([InputSource])");

      oDocument = oParserWrapper.parse(oInputSrc);

      oInputSrc = null;
      oStrStream.close();
      oStrStream = null;

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DOMDocument.parseString()");
      }
    } // parseString()
*/

    //---------------------------------------------------------

    public void print(OutputStream oOutStream) throws IOException,UnsupportedEncodingException {
      if (DebugFile.trace) DebugFile.writeln("DOMDocument.print([OutputStream],"+sEncoding+")");
      oPrtWritter = new PrintWriter(new OutputStreamWriter(oOutStream, sEncoding));
      print(oDocument);
    } // print()

    //---------------------------------------------------------

    public String print() throws IOException,UnsupportedEncodingException {
      oPrtWritter = new StringWriter();
      print(oDocument);
      return oPrtWritter.toString();
    } // print()

    //---------------------------------------------------------

    private void print(Node node) throws IOException {
        // is there anything to do?
        if ( node == null ) {
            return;
        }

        int type = node.getNodeType();
        switch ( type ) {
        // print document
        case Node.DOCUMENT_NODE: {
                if ( !bCanonical ) {
                    String  Encoding = this.getWriterEncoding();
                    if ( Encoding.equalsIgnoreCase( "DEFAULT" ) )
                        Encoding = "ISO-8859-1";
                    else if ( Encoding.equalsIgnoreCase( "Unicode" ) )
                        Encoding = "UTF-16";
					else if ( Encoding.equalsIgnoreCase( "UTF-8" ) )
                        Encoding = "UTF-8";
                    else
                        //Encoding = MIME2Java.reverse( Encoding );
                        Encoding = "ISO-8859-1";

                    oPrtWritter.write("<?xml version=\"1.0\" encoding=\""+
                                Encoding + "\"?>\n");
                }
                //print(((Document)node).getDocumentElement());

                NodeList children = node.getChildNodes();
                for ( int iChild = 0; iChild < children.getLength(); iChild++ ) {
                    print(children.item(iChild));
                }
                oPrtWritter.flush();
                break;
            }

            // print element with attributes
        case Node.ELEMENT_NODE: {
                oPrtWritter.write('<');
                oPrtWritter.write(node.getNodeName());
                Attr attrs[] = sortAttributes(node.getAttributes());
                for ( int i = 0; i < attrs.length; i++ ) {
                    Attr attr = attrs[i];
                    oPrtWritter.write(' ');
                    oPrtWritter.write(attr.getNodeName());
                    oPrtWritter.write("=\"");
                    oPrtWritter.write(normalize(attr.getNodeValue()));
                    oPrtWritter.write('"');
                }
                oPrtWritter.write('>');
                NodeList children = node.getChildNodes();
                if ( children != null ) {
                    int len = children.getLength();
                    for ( int i = 0; i < len; i++ ) {
                        print(children.item(i));
                    }
                }
                break;
            }

            // handle entity reference nodes
        case Node.ENTITY_REFERENCE_NODE: {
                if ( bCanonical ) {
                    NodeList children = node.getChildNodes();
                    if ( children != null ) {
                        int len = children.getLength();
                        for ( int i = 0; i < len; i++ ) {
                            print(children.item(i));
                        }
                    }
                } else {
                    oPrtWritter.write('&');
                    oPrtWritter.write(node.getNodeName());
                    oPrtWritter.write(';');
                }
                break;
            }

            // print cdata sections
        case Node.CDATA_SECTION_NODE: {
                if ( bCanonical ) {
                    oPrtWritter.write(normalize(node.getNodeValue()));
                } else {
                    oPrtWritter.write("<![CDATA[");
                    oPrtWritter.write(node.getNodeValue());
                    oPrtWritter.write("]]>");
                }
                break;
            }

            // print text
        case Node.TEXT_NODE: {
                oPrtWritter.write(normalize(node.getNodeValue()));
                break;
            }

            // print processing instruction
        case Node.PROCESSING_INSTRUCTION_NODE: {
                oPrtWritter.write("<?");
                oPrtWritter.write(node.getNodeName());
                String data = node.getNodeValue();
                if ( data != null && data.length() > 0 ) {
                    oPrtWritter.write(' ');
                    oPrtWritter.write(data);
                }
                oPrtWritter.write("?>\n");
                break;
            }
        }

        if ( type == Node.ELEMENT_NODE ) {
            oPrtWritter.write("</");
            oPrtWritter.write(node.getNodeName());
            oPrtWritter.write('>');
        }

        oPrtWritter.flush();
    } // print(Node)

    //---------------------------------------------------------

    private String normalize(String s) {
        StringBuffer str = new StringBuffer();

        int len = (s != null) ? s.length() : 0;
        for ( int i = 0; i < len; i++ ) {
            char ch = s.charAt(i);
            switch ( ch ) {
            case '<': {
                    str.append("&lt;");
                    break;
                }
            case '>': {
                    str.append("&gt;");
                    break;
                }
            case '&': {
                    str.append("&amp;");
                    break;
                }
            case '"': {
                    str.append("&quot;");
                    break;
                }
            case '\'': {
                    str.append("&apos;");
                    break;
                }
            case '\r':
            case '\n': {
                    if ( bCanonical ) {
                        str.append("&#");
                        str.append(Integer.toString(ch));
                        str.append(';');
                        break;
                    }
                    // else, default append char
                }
            default: {
                    str.append(ch);
                }
            }
        }
        return(str.toString());
    } // normalize(String):String

    //---------------------------------------------------------

   protected Attr[] sortAttributes(NamedNodeMap attrs) {

        int len = (attrs != null) ? attrs.getLength() : 0;
        Attr array[] = new Attr[len];
        for ( int i = 0; i < len; i++ ) {
            array[i] = (Attr)attrs.item(i);
        }
        for ( int i = 0; i < len - 1; i++ ) {
            String name  = array[i].getNodeName();
            int    index = i;
            for ( int j = i + 1; j < len; j++ ) {
                String curName = array[j].getNodeName();
                if ( curName.compareTo(name) < 0 ) {
                    name  = curName;
                    index = j;
                }
            }
            if ( index != i ) {
                Attr temp    = array[i];
                array[i]     = array[index];
                array[index] = temp;
            }
        }
        return(array);
    } // sortAttributes(NamedNodeMap):Attr[]

    //---------------------------------------------------------

  public Vector<DOMSubDocument> filterChildsByName(Element oParent, String sChildsName) {

    NodeList oNodeList;
    Vector<DOMSubDocument> oLinkVctr;

    // Obtener una referencia al nodo de nivel superior en el documento
    Node oPageSetNode = getRootNode().getFirstChild();
    if (oPageSetNode.getNodeName().equals("xml-stylesheet")) oPageSetNode = oPageSetNode.getNextSibling();

    // Obtener una lista de nodos cuyo nombre sea <container>
    oNodeList = oParent.getElementsByTagName(sChildsName);

    // Crear el vector
    oLinkVctr = new Vector<DOMSubDocument>(oNodeList.getLength());

    // Convertir los nodos DOM en objetos de tipo Page
    for (int i=0; i<oNodeList.getLength(); i++)
      oLinkVctr.add(new DOMSubDocument (oNodeList.item(i)));

    return oLinkVctr;
  } // filterChildsByName()

}  // DOMDocument
