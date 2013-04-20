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

import java.io.*;

import org.xml.sax.ContentHandler;
import org.xml.sax.ErrorHandler;
import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.helpers.XMLReaderFactory;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;

/**
 * SAXValidate Class.
 * XML Document Parser Validator.
 * @author Carlos Enrique Navarro Candil
 * @version 1.0
 */

public class SAXValidate extends DefaultHandler
                        implements ErrorHandler {

   private static final String
           DEFAULT_PARSER = "org.apache.xerces.parsers.SAXParser";
   private boolean schemavalidate = false;
   @SuppressWarnings("unused")
   private boolean valid;

   /**
    * Construye una instancia de la clase handler
    */
   public SAXValidate(boolean validateschema) {
     this.schemavalidate = validateschema;
     this.valid = true;
   }

   public void error (SAXParseException exception) throws SAXException {
     this.valid = false;
     System.out.println("ERROR: " + exception.getMessage());
   }

  /**
   * Rutina principal para probar la utilidad SAXValidate.
   */
  static public void main(String[] args) {

    if (args.length < 1 || args.length > 2) {
      System.err.println("USO: java SAXValidate [-s] <xmlfile>");
    } else {
      boolean svalidate = false;
      String filename = "";

      if (args.length > 1) {
        if (args[0].equals("-s")) {
          svalidate = true;
        }
        filename = args[1];
      } else {
        filename = args[0];
      }

      SAXValidate test = new SAXValidate(svalidate);

      try {
        test.runTest(new FileReader(new File(filename).toString()),
                   DEFAULT_PARSER);
      } catch (Exception e) {
        System.err.println("Error running test.");
        System.err.println(e.getMessage());
        e.printStackTrace(System.err);
      }
    }
  }

  /**
   * Ejecuta el test
   *
   * @param xml stream xml que se quiere parsear
   * @param parserName nombre de una clase parser "SAX2 compliant"
   */

  public void runTest(Reader xml, String parserName)
                  throws IOException, ClassNotFoundException {

    try {

      // Obtiene una instancia del parser
      XMLReader parser = XMLReaderFactory.createXMLReader(parserName);

      // Configura los manejadores en el parser
      parser.setContentHandler((ContentHandler)this);
      parser.setErrorHandler((ErrorHandler)this);

      parser.setFeature("http://xml.org/sax/features/validation", true);
      if (schemavalidate) {
        parser.setFeature("http://apache.org/xml/features/validation/schema", true);
      }

      // Parsea el documento
      parser.parse(new InputSource(xml));

    } catch (SAXParseException e) {
      System.err.println(e.getMessage());
    } catch (SAXException e) {
      System.err.println(e.getMessage());
    } catch (Exception e) {
      System.err.println(e.toString());
    }
  }
}
