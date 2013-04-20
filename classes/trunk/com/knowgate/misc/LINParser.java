/*
  Copyright (C) 2007  Know Gate S.L. All rights reserved.
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

package com.knowgate.misc;

import java.io.File;
import java.io.FileReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.Reader;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.FileInputStream;

import java.util.ArrayList;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

public class LINParser {

  // ----------------------------------------------------------

  private ArrayList<String> oLines;   // Array de lineas del fichero
  private int  iRows;      // Número de filas encontradas en el fichero leído
  private String sCharSet; // Juego de caracteres

  // ----------------------------------------------------------

  public LINParser() {
	iRows = 0;
    sCharSet = null;
    oLines = new ArrayList<String>();
  }

  public LINParser(String sCharsetName) {
	iRows = 0;
    sCharSet = sCharsetName;
    oLines = new ArrayList<String>();
  }
    
  // ----------------------------------------------------------

  public String charSet() {
    return sCharSet;
  }

  // ----------------------------------------------------------

  public void charSet(String sCharSetName) {
    sCharSet = sCharSetName;
  }

  // ----------------------------------------------------------

  /**
   * Get line count
   * @return int
   */
  public int getLineCount() {
    return iRows;
  }

  // ----------------------------------------------------------

  public void parseString(String sStr) throws NullPointerException {
  	String[] aLines = Gadgets.split(sStr, '\n');
  	
	if (aLines!=null) {
	  iRows = aLines.length;
	  for (int r=0; r<iRows; r++) {
	    oLines.add(Gadgets.removeChar(aLines[r],'\r'));
	  } // next
	} // fi 	
  } // parseString

  // ----------------------------------------------------------

  public void parseStream(InputStream oInStrm)
    throws IOException, NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LINParser.parseStream([InputStream])");
      DebugFile.incIdent();
    }

	String sLine;
	Reader oRder = new InputStreamReader(oInStrm,sCharSet);		
    BufferedReader oBuff = new BufferedReader(oRder);

    iRows = 0;
    while (null!=(sLine=oBuff.readLine())) {
      oLines.add(sLine);
      iRows++;
    } // wend
    oBuff.close();
    if (null!=oInStrm) oInStrm.close();
    oRder.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LINParser.parseStream()");
    }
  } // parseStream
  
  // ----------------------------------------------------------
  
  public void parseFile(File oInFile)
    throws FileNotFoundException, IOException,NumberFormatException,
           ArrayIndexOutOfBoundsException,RuntimeException,
           NullPointerException,IllegalArgumentException {

    String sLine;
    Reader oRder;
    BufferedReader oBuff;
    FileInputStream oInStrm;
  
    if (DebugFile.trace) {
      DebugFile.writeln("Begin LINParser.parseFile(" + oInFile.getName() + ")");
      DebugFile.incIdent();
    }

    if (null==sCharSet) {
	  oInStrm = null;
      oRder = new FileReader(oInFile);
    } else {
	  oInStrm = new FileInputStream(oInFile);
	  oRder = new InputStreamReader(oInStrm,sCharSet);		
    }
    oBuff = new BufferedReader(oRder);
    iRows = 0;
    while (null!=(sLine=oBuff.readLine())) {
      oLines.add(sLine);
      iRows++;
    } // wend
    oBuff.close();
    if (null!=oInStrm) oInStrm.close();
    oRder.close();
 
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LINParser.parseFile()");
    }
  } // parseFile

  // ----------------------------------------------------------

  public void parseFile(String sInFile)
    throws FileNotFoundException, IOException,NumberFormatException,
           ArrayIndexOutOfBoundsException,RuntimeException,
           NullPointerException,IllegalArgumentException {
    parseFile(new File(sInFile));
  }         	

  // ----------------------------------------------------------
  
  public String getLine(int iRow)
    throws IllegalStateException, ArrayIndexOutOfBoundsException {
    return (String) oLines.get(iRow);
  }

  // ----------------------------------------------------------
  
  public String[] splitLine(int iRow, char cDelimiter)
    throws IllegalStateException, ArrayIndexOutOfBoundsException {    
    return Gadgets.split((String) oLines.get(iRow),cDelimiter);
  }
    
}