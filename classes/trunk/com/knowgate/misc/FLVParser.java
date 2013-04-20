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
import java.io.FileNotFoundException;
import java.io.IOException;

import java.util.HashMap;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * <p>Fixed Length Columns Text Parser</p>
 * <p>Parses a text file with fixed length columns into a memory array</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */

public class FLVParser extends LINParser {
  private int  iCols;              // Número de columnas contadas en el descriptor
  private int  iErrLine;           // Línea del fichero donde se produjo el último error de parseo
  private int[] aColFrom;          // Array con las posiciones de inicio de cada columna
  private int[] aColTo;            // Array con las posiciones de fin de cada columna
  private HashMap oColPosMap;      // Mapa que recupera el índice de cada columna dado su nombre

  // ----------------------------------------------------------

  public FLVParser() {
    aColTo = aColFrom = null;
    oColPosMap = null;
  }

  // ----------------------------------------------------------

  /**
   * Create Fixed Length Value Parser and set encoding to be used
   * @param sCharSetName Name of charset encoding
   */
  public FLVParser(String sCharSetName) {
    super(sCharSetName);
    aColTo = aColFrom = null;
    oColPosMap = null;
  }

  // ----------------------------------------------------------

  /**
   * Get column count
   * @return int
   */
  public int getColumnCount() {
    return iCols;
  }

  // ----------------------------------------------------------

  /**
   * @param sColumnName Column Name
   * @return Zero based index for column position or -1 if column was not found.
   */
  public int getColumnPosition(String sColumnName) {
	Integer oCol = (Integer) oColPosMap.get(sColumnName);
	if (null==oCol) oCol = new Integer(-1);
	return oCol.intValue();
  }
  
  // ----------------------------------------------------------

  public int errorLine() {
    return iErrLine;
  }

  // ----------------------------------------------------------

  private static int getFromPosition(String sColumnDescriptor)
    throws IllegalArgumentException,NumberFormatException {
    int iLeftBracket = sColumnDescriptor.indexOf('[');
    int iRightBracket = sColumnDescriptor.indexOf(']');
    int iComma = sColumnDescriptor.indexOf(',',iLeftBracket);
    if (-1==iLeftBracket) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new IllegalArgumentException("Column "+sColumnDescriptor+" missing left bracket");
    }
    if (-1==iRightBracket) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new IllegalArgumentException("Column "+sColumnDescriptor+" missing right bracket");
    }
    if (-1==iComma) iComma = iRightBracket;
    return Integer.parseInt(sColumnDescriptor.substring(iLeftBracket+1, iComma));
  } // getFromPosition

  // ----------------------------------------------------------

  private static int getToPosition(String sColumnDescriptor)
    throws IllegalArgumentException,NumberFormatException {
    int iLeftBracket = sColumnDescriptor.indexOf('[');
    int iRightBracket = sColumnDescriptor.indexOf(']');
    int iComma = sColumnDescriptor.indexOf(',',iLeftBracket);
    if (-1==iLeftBracket) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new IllegalArgumentException("Column "+sColumnDescriptor+" missing left bracket");
    }
    if (-1==iRightBracket) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new IllegalArgumentException("Column "+sColumnDescriptor+" missing right bracket");
    }
    if (-1==iComma) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new IllegalArgumentException("Column "+sColumnDescriptor+" missing comma delimiter between 'from' and 'to' indexes");
    }
    return Integer.parseInt(sColumnDescriptor.substring(iComma+1, iRightBracket));
  } // getToPosition
  
  // ----------------------------------------------------------
  
  public void parseFile(File oInFile, String sFileDescriptor)
    throws FileNotFoundException, IOException,NumberFormatException,
           ArrayIndexOutOfBoundsException,RuntimeException,
           NullPointerException,IllegalArgumentException {
  
    if (DebugFile.trace) {
      DebugFile.writeln("Begin FLVParser.parseFile(" + oInFile.getName() + "], [TreeSet])");
      DebugFile.incIdent();
    }

    // Each column of the file descriptor is delimited by a semi-colon
    String[] aCols = Gadgets.split(sFileDescriptor, ';');
    iCols = aCols.length;
    
    // Initialize column names map and column 'from' and 'to' positions arrays
    oColPosMap = new HashMap(11+iCols*2);
    aColFrom = new int[iCols];
    aColTo = new int[iCols];
    
    for (int c=0; c<iCols; c++) {
      // Get full column descriptor for current column
      String sColDesc = aCols[c].trim();
      // Ignore empty column descriptions
      if (sColDesc.length()>0) {
    	// Find position of the first left bracket
    	int iLeftBracket = sColDesc.indexOf('[');
        if (-1==iLeftBracket) {
        	if (DebugFile.trace) DebugFile.decIdent();
        	throw new IllegalArgumentException("Column "+aCols[c]+" missing left bracket");
        }
        // Get column 'from' position
        aColFrom[c] = getFromPosition(sColDesc);
        int iComma = sColDesc.indexOf(',',iLeftBracket);
        if (-1==iComma) {
          // If there is no comma then 
          // get 'to' position as one less than next column 'from'
          if (c<iCols-1) {
            aColTo[c] = getFromPosition(aCols[c+1])-1;
          } else {
        	// If there is no 'to' position and this is the last column then
        	// set flag to read characters until the end of the line
        	aColTo[c] = -1;
          }
        } else {
          aColTo[c] = getToPosition(sColDesc);        	
        } // fi (-1==iComma)
        // Get column name and store it at internal map
        String sColName = sColDesc.substring(0,iLeftBracket).trim();
        if (sColName.length()>0) oColPosMap.put(sColName, new Integer(c));
      } else {
    	aColFrom[c] = aColTo[c] = 0;
      } // fi (sColDesc!="")
    } // next

	super.parseFile(oInFile);
	 
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FLVParser.parseFile()");
    }
  } // parseFile
    
  // ----------------------------------------------------------
  
  public String getField(int iCol, int iRow)
    throws IllegalStateException, ArrayIndexOutOfBoundsException, StringIndexOutOfBoundsException {
	String sLine = super.getLine(iRow);
	int iFrom = aColFrom[iCol];
	int iTo = aColTo[iCol];
	if (iTo==-1 || iTo>=sLine.length())
      return sLine.substring(iFrom).trim();
	else
	  return sLine.substring(iFrom,iTo+1).trim();
  } // getField

  // ----------------------------------------------------------
  
  public String getField(String sCol, int iRow)
    throws IllegalStateException, ArrayIndexOutOfBoundsException, StringIndexOutOfBoundsException {
	Integer oCol = (Integer) oColPosMap.get(sCol);
	if (null==oCol) throw new ArrayIndexOutOfBoundsException("Column " + sCol + " not found");
	return getField(oCol.intValue(),iRow);
  } // getField
  
}
