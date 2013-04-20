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

package com.knowgate.misc;

import java.io.File;
import java.io.FileReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.io.BufferedOutputStream;
import java.io.Reader;
import java.io.InputStreamReader;
import java.io.FileInputStream;

import java.text.SimpleDateFormat;

import java.util.Arrays;
import java.util.HashMap;

import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFCell;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * <p>Delimited Text Parser</p>
 * <p>Parses a delimited text file into a memory array</p>
 * @author Sergio Montoro Ten
 * @version 6.0
 */
public class CSVParser  {

  private char cBuffer[];      // Buffer interno que contiene los caracteres del fichero a parsear
  private int  iBuffer;        // Longuitud del buffer interno
  private String ColNames[];   // Nombres de columnas leidos del descriptor de fichero
  private int RowPointers[];   // Punteros al inicio de cada línea en el buffer interno
  private int ColPointers[][]; // Punteros al inicio de cada columna en el buffer interno
  private int iCols;           // Número de columnas contadas en el descriptor
  private int iRows;           // Número de filas encontradas en el fichero leído
  private int iErrLine;        // Línea del fichero donde se produjo el último error de parseo
  private char cDelimiter;
  private boolean bQuoted;
  private String sCharSet;

  // ----------------------------------------------------------

  public CSVParser() {
	iRows = iBuffer = 0;
    sCharSet = null;
  }

  // ----------------------------------------------------------

  /**
   * Create CSV Parser and set encoding to be used
   * @param sCharSetName Name of charset encoding
   */
  public CSVParser(String sCharSetName) {
	iRows = iBuffer = 0;
    sCharSet = sCharSetName;
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
   * @since 3.0
   */
  public int getLineCount() {
    return iRows;
  }

  // ----------------------------------------------------------

  /**
   * Get column count
   * @return int
   * @since 3.0
   */
  public int getColumnCount() {
    return iCols;
  }

  // ----------------------------------------------------------

  public int errorLine() {
    return iErrLine;
  }

  // ----------------------------------------------------------

  public char getDelimiter() {
    return cDelimiter;
  }

  // ----------------------------------------------------------

  private char extractDelimiter(String sFileDescriptor) {
    boolean bIgnore = false;
    final int iFileDescLen = sFileDescriptor.length();
    // Inferir el delimitador

    for (int p=0; p<iFileDescLen && cDelimiter==(char)0; p++) {

      char cAt = sFileDescriptor.charAt(p);

      if (cAt=='"') bIgnore = !bIgnore;
      if (!bIgnore) {
        switch (cAt) {
          case ',':
            cDelimiter = ',';
            break;
          case ';':
            cDelimiter = ';';
            break;
          case '|':
            cDelimiter = '|';
            break;
          case '`':
            cDelimiter = '`';
            break;
          case '¨':
            cDelimiter = '¨';
            break;
          case '\t':
            cDelimiter = '\t';
            break;
        } // end switch()
      } // fi ()
    } // next

    // If no delimiter is found, then assume that file has just one column and use Tab as default
    if (cDelimiter==(char)0) cDelimiter = '\t';  	
  
    return cDelimiter;
  }

  // ----------------------------------------------------------

  private boolean isVoid(String sStr) {
    if (sStr==null)
      return true;
    else
      return sStr.trim().length()==0;
  }

  // ----------------------------------------------------------

  private boolean isEmptyRow(HSSFRow oRow, int nCols) {
  	if (null==oRow) return true;
  	for (int c=0; c<nCols; c++) {
  	  if (oRow.getCell(c)!=null) {
  	  	if (!isVoid(oRow.getCell(c).getStringCellValue()))
  	  	  return false;
  	  }
  	}
  	return true;
  }
  
  // ----------------------------------------------------------

  public void parseSheet(HSSFSheet oSheet, String sFileDescriptor) {
  	HSSFCell oCel;
  	HSSFRow oRow = oSheet.getRow(0);
    int iRow;
    char cDelim;
    SimpleDateFormat oFmt4 = new SimpleDateFormat("yyyy-MM-dd");
  	String[] aFileDescriptor;
  	int iFileDescLen;
  	  
  	if (isVoid(sFileDescriptor)) {
  	  iRow = 1;
  	  cDelim = '\t';
  	  sFileDescriptor = "";
  	  short iCel = (short) 0;
	  oCel = oRow.getCell(iCel);
	  while (oCel!=null) {
	  	if (isVoid(oCel.getStringCellValue())) break;
	  	sFileDescriptor += (sFileDescriptor.length()==0 ? "" : "\t") + oCel.getStringCellValue();
	    oCel = oRow.getCell(++iCel);
	  } // wend
  	  aFileDescriptor = Gadgets.split(sFileDescriptor, cDelim);
      iFileDescLen = aFileDescriptor.length;
  	} else {
  	  iRow = 1;
  	  cDelim = extractDelimiter(sFileDescriptor);
  	  aFileDescriptor = Gadgets.split(sFileDescriptor, cDelim);
      iFileDescLen = aFileDescriptor.length;
  	  for (int c=0; c<iFileDescLen; c++) {
  	  	oCel = oRow.getCell(c);
  	  	if (null==oCel) {
  	  	  iRow = 0;
  	  	  break;
  	  	} else if (!aFileDescriptor[c].equalsIgnoreCase(oCel.getStringCellValue())) {
  	  	  iRow = 0;
  	  	  break;  	  	  
  	  	}
  	  } //next
  	} // fi
  	
    StringBuffer oData = new StringBuffer(1024*1024);
	while (!isEmptyRow(oSheet.getRow(iRow),iFileDescLen) && iRow<=65535) {
	  oRow = oSheet.getRow(iRow);
	  if (oRow.getCell(0)!=null) 
	    oData.append(oRow.getCell(0).getStringCellValue());
	  for (int c=1; c<iFileDescLen; c++) {
	    oData.append(cDelim);
	    if (oRow.getCell(c)!=null) {
	      int iCelType = oRow.getCell(c).getCellType();
		  switch (iCelType) {
		    case HSSFCell.CELL_TYPE_BLANK:
			  break;
		    case HSSFCell.CELL_TYPE_STRING:
	          oData.append(oRow.getCell(c).getStringCellValue().replace(cDelim,' ').replace('\n',' '));
		      break;
			case HSSFCell.CELL_TYPE_NUMERIC:
			  switch (oRow.getCell(c).getCellStyle().getDataFormat()) {
				case (short) 15: // m/d/yy
				case (short) 16: // d-mmm-yy
				oData.append(oFmt4.format(oRow.getCell(c).getDateCellValue()));
			    break;
			  default:
				oData.append(String.valueOf(oRow.getCell(c).getNumericCellValue()));
		      }
			  break;				            
		  } // end switch	      	      
	    } // fi 
	  } // next
	  oData.append('\n');
	  iRow++;
	} // wend
	parseData(oData.toString().toCharArray(), sFileDescriptor);
  } // parseSheet

  // ----------------------------------------------------------

  /**
   * <p>Parse data from a character array</p>
   * Parsed values are stored at an internal array in this CSVParser.
   * @param sFileDescriptor A list of column names separated by ',' ';' '|' '`' or '\t'.
   * Column names may be quoted. Lines are delimiter by '\n' characters<br>
   * Example 1) tx_mail,tx_name,tx_surname<br>
   * Example 2) "tx_name","tx_surname","tx_salutation"<br>
   * @throws ArrayIndexOutOfBoundsException Delimited values for a file is greater
   * than columns specified at descriptor.
   * @throws RuntimeException If delimiter is not one of { ',' ';' '|' '`' or '\t' }
   * @throws NullPointerException if sFileDescriptor is <b>null</b>
   * @throws IllegalArgumentException if sFileDescriptor is ""
   */

  public void parseData(char[] aCharData, String sFileDescriptor)
    throws ArrayIndexOutOfBoundsException, RuntimeException,
           NullPointerException,IllegalArgumentException {

    boolean bIgnore;
    char cAt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CSVParser.parseData(char[" + String.valueOf(aCharData.length) + "], \"" + sFileDescriptor + "\")");
      DebugFile.incIdent();
    }

    bQuoted = false;
    cDelimiter = (char)0;
    bIgnore = false;

    if (aCharData!=cBuffer) {
      iBuffer = aCharData.length;
      cBuffer = new char[iBuffer];
      System.arraycopy(aCharData, 0, cBuffer, 0, iBuffer);
    }

    iErrLine = 0;

    if (DebugFile.trace) DebugFile.writeln("trimming leading whitespaces");

    // Ignorar los espacios en blanco al final del fichero
    for (int p=iBuffer-1; p>=0; p--) {
      cAt = cBuffer[p];
      if (cAt==' ' || cAt=='\n' || cAt=='\r' || cAt=='\t')
        iBuffer--;
      else
        break;
    }

    if (iBuffer==0) {
      iRows = 0;
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End CSVParser.parseData() : zero length array");
      }
      return;
    }

    // Si el primer caracter no en blanco es comillas,
    // entonces se entiende que los campos van entrecomillados

    final int iFileDescLen = sFileDescriptor.length();

    for (int p=0; p<iBuffer; p++) {
      cAt = sFileDescriptor.charAt(p);

      if (cAt!=' ' && cAt!='\t' && cAt!='\n' && cAt!='\r') {
        bQuoted = (cAt == '"');
        break;
      }
    } // next

    if (DebugFile.trace) {
      if (bQuoted) DebugFile.writeln("asume quoted identifiers");
    }

	cDelimiter = extractDelimiter(sFileDescriptor);

    // Almacenar los nombres de campo y contar el número de columnas
    ColNames = Gadgets.split(sFileDescriptor, new String(new char[]{cDelimiter}));
    iCols = ColNames.length;

    if (DebugFile.trace) {
      DebugFile.writeln("chosen delimiter is "+(cDelimiter=='\t' ? 't' : cDelimiter));
      DebugFile.writeln("descriptor has " + String.valueOf(iCols) + " columns");
    }
    
    if (bQuoted)
      for (int c=0; c<iCols; c++)
        ColNames[c] = (ColNames[c].replace('"',' ')).trim();

    // Contar el número de filas a partir de los saltos de línea
    iRows = 1;
    for (int p=0; p<iBuffer; p++) {
      if (cBuffer[p]=='\n') iRows++;
    } // next

    if (DebugFile.trace) DebugFile.writeln("input data has " + String.valueOf(iRows) + " lines");

    RowPointers = new int[iRows];
    ColPointers = new int[iRows][iCols];

    int iRow = 0, iCol = 0;

    if (DebugFile.trace) DebugFile.writeln("parsing line 0");

    RowPointers[iRow] = 0;
    ColPointers[iRow][iCol] = 0;

    bIgnore = false;

    for (int p=0; p<iBuffer; p++) {

      cAt = cBuffer[p];

      if (cAt=='"' && bQuoted) bIgnore = !bIgnore;

      if (!bIgnore) {
        if (cAt==cDelimiter) {
          iCol++;
          if (iCol>=iCols) {
            iErrLine = iRow+1;
            throw new ArrayIndexOutOfBoundsException("Columns count mismatch for line " + String.valueOf(iErrLine) + " expected " + String.valueOf(iCols) + " but found more.");
          }
          else
            ColPointers[iRow][iCol] = p+1;
        }
        else if (cAt=='\n') {
          if (iCol!=iCols-1) {
            iErrLine = iRow+1;
            throw new ArrayIndexOutOfBoundsException("Columns count mismatch for line " + String.valueOf(iErrLine) + " expected " + String.valueOf(iCols) + " and found only " + String.valueOf(iCol+1));
          }
          iRow++;
          iCol = 0;

          if (DebugFile.trace) DebugFile.writeln("parsing line " + String.valueOf(iRow));

          RowPointers[iRow] = p+1;
          ColPointers[iRow][iCol] = p+1;
        }
      } // fi (bIgnore)
    } // next

    iErrLine = 0;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CSVParser.parseData()");
    }
  } // parseData

  // ----------------------------------------------------------

  /**
   * <p>Parse a delimited text file</p>
   * Parsed values are stored at an internal array in this CSVParser.<br>
   * File is readed using the character set specifid at constructor
   * @param oFile CSV File
   * @param sFileDescriptor A list of column names separated by ',' ';' '|' '`' or '\t'.
   * Column names may be quoted. Lines are delimiter by '\n' characters<br>
   * Example 1) tx_mail,tx_name,tx_surname<br>
   * Example 2) "tx_name","tx_surname","tx_salutation"<br>
   * @throws IOException
   * @throws FileNotFoundException
   * @throws ArrayIndexOutOfBoundsException Delimited values for a file is greater
   * than columns specified at descriptor.
   * @throws RuntimeException If delimiter is not one of { ',' ';' '|' '`' or '\t' }
   * @throws NullPointerException if oFile or sFileDescriptor are <b>null</b>
   * @throws IllegalArgumentException if sFileDescriptor is ""
   * @throws UnsupportedEncodingException
   * @since 3.0
   */
  public void parseFile(File oFile, String sFileDescriptor)
      throws ArrayIndexOutOfBoundsException,IOException,FileNotFoundException,
             RuntimeException,NullPointerException,IllegalArgumentException,
             UnsupportedEncodingException {

    Reader oReader;

    if (oFile==null)
      throw new NullPointerException("CSVParser.parseFile() File parameter may not be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CSVParser.parseFile(\"" + oFile.getAbsolutePath() + "\",\"" + sFileDescriptor + "\")");
      DebugFile.incIdent();
    }

    if (sFileDescriptor==null && !oFile.getName().endsWith(".xls")) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("CSVParser.parseFile() File Descriptor parameter may not be null");
    }

    if (sFileDescriptor.trim().length()==0 && !oFile.getName().endsWith(".xls")) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new IllegalArgumentException("File Descriptor parameter may not be an empty string");
    }

    iErrLine = 0;

    iBuffer = new Long(oFile.length()).intValue();

    if (iBuffer==0) {
      iRows = 0;
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End CSVParser.parseFile() : zero length file");
      }
      return;
    }

	if (oFile.getName().endsWith(".xls")) {
	  FileInputStream oFistrm = new FileInputStream(oFile);
	  HSSFWorkbook oWrkb = new HSSFWorkbook(oFistrm);
	  HSSFSheet oSheet = oWrkb.getSheetAt(0);
	  oFistrm.close();
	  parseSheet(oSheet, sFileDescriptor);
	} else {

      cBuffer = new char[iBuffer];

      if (null==sCharSet) {
        oReader = new FileReader(oFile);
      } else {
        oReader = new InputStreamReader(new FileInputStream(oFile), sCharSet);
      }
      oReader.read(cBuffer);
      oReader.close();
      oReader = null;
	
	  // Skip Unicode characters prolog
	  if (sCharSet==null) {
        parseData (cBuffer, sFileDescriptor);	  	
	  } else {
	    if (sCharSet.startsWith("UTF") || sCharSet.startsWith("utf") || sCharSet.startsWith("Unicode")) {
	      int iSkip = 0;
	      if  ((int) cBuffer[0] == 65279 || (int) cBuffer[0] == 65533 || (int) cBuffer[0] == 65534) iSkip++;
	      if  ((int) cBuffer[1] == 65279 || (int) cBuffer[1] == 65533 || (int) cBuffer[1] == 65534) iSkip++;

	      if (0==iSkip)
            parseData (cBuffer, sFileDescriptor);
	      else
	  	    parseData (Arrays.copyOfRange(cBuffer, iSkip, iBuffer), sFileDescriptor);
	    } else {
          parseData (cBuffer, sFileDescriptor);	  	
	    }
	  }
	}

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CSVParser.parseFile()");
    }
  } // parseFile

  // ----------------------------------------------------------

  /**
   * <p>Parse a delimited text file</p>
   * Parsed values are stored at an internal array in this CSVParser.
   * @param sFilePath File Path
   * @param sFileDescriptor A list of column names separated by ',' ';' '|' '`' or '\t'.
   * Column names may be quoted. Lines are delimiter by '\n' characters<br>
   * Example 1) tx_mail,tx_name,tx_surname<br>
   * Example 2) "tx_name","tx_surname","tx_salutation"<br>
   * @throws IOException
   * @throws FileNotFoundException
   * @throws ArrayIndexOutOfBoundsException Delimited values for a file is greater
   * than columns specified at descriptor.
   * @throws RuntimeException If delimiter is not one of { ',' ';' '|' '`' or '\t' }
   * @throws NullPointerException if oFile or sFileDescriptor are <b>null</b>
   * @throws IllegalArgumentException if sFileDescriptor is ""
   * @throws UnsupportedEncodingException
   */
  public void parseFile(String sFilePath, String sFileDescriptor)
      throws ArrayIndexOutOfBoundsException,IOException,FileNotFoundException,
             RuntimeException,NullPointerException,IllegalArgumentException,
             UnsupportedEncodingException {
    parseFile (new File(sFilePath), sFileDescriptor);
  }

  // ----------------------------------------------------------

  /**
   * @param sColumnName Column Name
   * @return Zero based index for column position or -1 if column was not found.
   */
  public int getColumnPosition(String sColumnName) {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CSVParser.getColumnPosition(" + sColumnName + ")");
      DebugFile.incIdent();
    }

    int iPos = -1;

    for (int c=0; c<iCols; c++) {
      if (ColNames[c].equalsIgnoreCase(sColumnName)) {
        iPos = c;
        break;
      }
    } // next

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CSVParser.getColumnPosition() : " + String.valueOf(iPos));
    }

    return iPos;
  } // getColumnPosition

  // ----------------------------------------------------------

  /**
   * <p>Get line from a parsed file.</p>
   * Lines are delimited by the Line Feed (LF, CHAR(10), '\n') character
   * @param iLine Line Number [0..getLineCount()-1]
   * @return Full Text for Line. If iLine<0 or iLine>=getLineCount() then <b>null</b>
   * @throws IllegalStateException If parseFile() has not been called prior to getLine()
   * @throws UnsupportedEncodingException
   */
  public String getLine(int iLine) throws IllegalStateException, UnsupportedEncodingException {
    String sRetVal;
    int iStart, iEnd;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CSVParser.getLine(" + String.valueOf(iLine) + ")");
      DebugFile.incIdent();
    }

    if (0 == iBuffer)
      throw new IllegalStateException("Must call parseFile() on a valid non-empty delimited file before calling getField() method");

    if (iLine<0 || iLine>iRows-1)

      sRetVal = null;

    else {

      iStart = ColPointers[iLine][0];
      iEnd = iBuffer;

      // Search for line feed
      for (int p=iStart; p<iBuffer; p++)
        if (cBuffer[p]=='\n') {
          iEnd = p;
          break;
        } // fi ()

      if (iStart==iEnd)
        sRetVal = "";
      else {
        // Remove last Carriage Return (CR, CHAR(13), '\r') character
        if (iEnd-1>iStart) {
          if (cBuffer[iEnd-1]=='\r') --iEnd;
          if (iStart==iEnd)
            sRetVal = "";
          else
            sRetVal = new String(cBuffer, iStart, iEnd - iStart);
        }
        else {
          if (cBuffer[iStart]=='\r')
            sRetVal = "";
          else
            sRetVal = new String(cBuffer, iStart, iEnd - iStart);
        }
      }

    } // fi (iRow<0 || iRow>iRows-1)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CSVParser.getLine() : " + sRetVal);
    }

    return sRetVal;
  } // getLine

  // ----------------------------------------------------------

  /**
   * <p>Get line from a parsed file as a Map of named values.</p>
   * This method is usefull when parsing plain text lines into DBPersist instances
   * @param iLine Line Number [0..getLineCount()-1]
   * @return HashMap
   * @throws IllegalStateException If parseFile() has not been called prior to getLine()
   * @throws UnsupportedEncodingException
   * @throws ArrayIndexOutOfBoundsException
   * @since 4.0
   */
  public HashMap getLineAsMap(int iLine)
  	throws IllegalStateException, UnsupportedEncodingException, ArrayIndexOutOfBoundsException {

    HashMap oMap = new HashMap(iCols*2);
	
	for (int c=0; c<iCols; c++) {
      oMap.put(ColNames[c],getField(c,iLine));
    } // next

    return oMap;
  } // getLineAsMap

  // ----------------------------------------------------------

  /**
   * <p>Get value for a field at a given row and column.</p>
   * Column indexes are zero based.<br>
   * Row indexes range from 0 to getLineCount()-1.
   * @param iCol Column Index
   * @param iRow Row Index
   * @return Field Value
   * @throws IllegalStateException If parseFile() method was not called prior to
   * getField()
   * @throws ArrayIndexOutOfBoundsException If Column or Row Index is out of bounds.
   * @throws StringIndexOutOfBoundsException If Row is malformed.
   * @throws UnsupportedEncodingException If charset encoding name is not recognized.
   */
  public String getField(int iCol, int iRow)
      throws IllegalStateException, ArrayIndexOutOfBoundsException,
             StringIndexOutOfBoundsException, UnsupportedEncodingException {
    int iStart;
    int iEnd;
    String sRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CSVParser.getField(" + String.valueOf(iCol) + "," + String.valueOf(iRow) + ")");
      if (iBuffer>0) DebugFile.incIdent();
    }

    iErrLine = 0;

    if (0 == iBuffer)
      throw new IllegalStateException("Must call parseFile() on a valid non-empty delimited file before calling getField() method");

    if (-1==iCol || -1==iRow) {
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End CSVParser.getField() : null");
      }
      return null;
    }

    iErrLine = iRow;

    iStart = ColPointers[iRow][iCol];

    if (DebugFile.trace) DebugFile.writeln("iStart=" + String.valueOf(iStart));

    if (iCol<iCols-1)
      iEnd = ColPointers[iRow][iCol+1]-1;
    else if (iRow<iRows-1)
      iEnd = ColPointers[iRow+1][0]-1;
    else
      iEnd = iBuffer;

    if (DebugFile.trace) DebugFile.writeln("triming trailing spaces from " + String.valueOf(iEnd));

    if (iEnd>0 && iEnd<iBuffer) {
      if (bQuoted) {
        while (cBuffer[iEnd - 1] == '\r' || cBuffer[iEnd - 1] == ' ' ||
               cBuffer[iEnd - 1] == '\t')
          if (--iEnd == 0)
            break;
      }
      else {
        if (cBuffer[iEnd-1]=='\r') iEnd--;
      }
    }
    else if (iEnd<0)
      iEnd = 0;

    if (DebugFile.trace) DebugFile.writeln("iEnd=" + String.valueOf(iEnd));

    if (iStart==iEnd)
      sRetVal = "";
    else if (bQuoted)
        sRetVal = new String(cBuffer, iStart+1, iEnd-iStart-2);
    else
      sRetVal = new String(cBuffer, iStart, iEnd-iStart);

    iErrLine = 0;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CSVParser.getField() : " + sRetVal);
    }

    return sRetVal;
  } // getField

  // ----------------------------------------------------------

  /**
   * <p>Get value for a field at a given row and column.</p>
   * @param sCol Column name
   * @param iRow Row position [0..getLineCount()-1]
   * @throws IllegalStateException
   * @throws ArrayIndexOutOfBoundsException
   * @throws StringIndexOutOfBoundsException
   * @throws UnsupportedEncodingException
   * @return Field value
   */
  public String getField(String sCol, int iRow)
    throws IllegalStateException, ArrayIndexOutOfBoundsException,
           StringIndexOutOfBoundsException, UnsupportedEncodingException {

    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    return getField (iCol, iRow);
  }

  // ----------------------------------------------------------

  /**
   * <p>Find first occurence of a value at a given column</p>
   * Search is case sensitive
   * @param iCol int Column index [0..getColumnCount()-1]
   * @param sVal String Value sought
   * @return int
   * @throws UnsupportedEncodingException
   * @since 3.0
   */
  public int find (int iCol, String sVal) throws UnsupportedEncodingException {
    int iFound = -1;
    int r = 0;
    while (r<iRows) {
      if (getField(iCol,r).equals(sVal)) {
        iFound = r;
        break;
      }
    } // wend
    return iFound;
  } // find

  // ----------------------------------------------------------

  /**
   * <p>Find first occurence of a value at a given column</p>
   * Search is case insensitive
   * @param iCol int Column index [0..getColumnCount()-1]
   * @param sVal String Value sought
   * @return int
   * @throws UnsupportedEncodingException
   * @since 3.0
   */
  public int findi (int iCol, String sVal) throws UnsupportedEncodingException {
    int iFound = -1;
    int r = 0;
    while (r<iRows) {
      if (getField(iCol,r).equalsIgnoreCase(sVal)) {
        iFound = r;
        break;
      }
    } // wend
    return iFound;
  } // findi

  // ----------------------------------------------------------

  /**
   * Write CSVParser matrix to an output stream
   * @param oStrm OutputStream
   * @throws IOException
   * @since 3.0
   */
  public void writeToStream(OutputStream oStrm) throws IOException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin CSVParser.writeToStream([OutputStream])");
      DebugFile.incIdent();
    }

    if (null!=sCharSet)
      oStrm.write(new String(cBuffer).getBytes(sCharSet));
    else
      oStrm.write(new String(cBuffer).getBytes());

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CSVParser.writeToStream()");
    }
  } // writeToStream

  // ----------------------------------------------------------

  /**
   * Write CSVParser matrix to delimited text file
   * @param oStrm OutputStream
   * @throws IOException
   * @throws SecurityException
   * @since 3.0
   */
  public void writeToFile(String sFilePath) throws IOException, SecurityException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin CSVParser.writeToFile("+sFilePath+")");
      DebugFile.incIdent();
    }
    FileOutputStream oOutStrm = new FileOutputStream(sFilePath);
    BufferedOutputStream oOutBuff = new BufferedOutputStream(oOutStrm);

    writeToStream(oOutBuff);

    oOutBuff.close();
    oOutStrm.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CSVParser.writeToFile()");
    }
  } // writeToFile

}
