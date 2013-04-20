/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.

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

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.FileInputStream;

import java.util.HashMap;

import java.util.Date;

import com.knowgate.debug.DebugFile;

/**
 * Search and Replace a set of substrings with another substrings.
 * <p>This class is a single-pass fast no wildcards replacer for a given set of substrings.</p>
 * <p>It is primarily designed for mail merge document personalization routines, where a small
 * number of substrings have to be replaced at a master document with data retrieved from a list
 * or database.</p>
 * @author Sergio Montoro Ten
 * @version 2.1
 */

public class FastStreamReplacer {
  int BufferSize;
  int iReplacements;
  StringBuffer oOutStream;

  // ----------------------------------------------------------

  public FastStreamReplacer() {
    BufferSize = 32767;
    oOutStream = new StringBuffer(BufferSize);
  }

  // ----------------------------------------------------------

  public FastStreamReplacer(int iBufferSize) {
    BufferSize = iBufferSize;
    oOutStream = new StringBuffer(BufferSize);
  }

  // ----------------------------------------------------------
  /**
   * Replace subtrings from a Stream.
   * @param oInStream Input Stream containing substrings to be replaced.
   * @param oMap Map with values to be replaced.<br>
   * Each map key will be replaced by its value.<br>
   * Map keys must appear in stream text as {#<i>key</i>}<br>
   * For example: InputStream "Today is {#System.Date}" will be replaced with "Today is 2002-02-21 11:32:44"<br>
   * No wildcards are accepted.<br>
   * Map keys must not contain {#&nbsp;} key markers.
   * @return String Replacements Result
   * @throws IOException
   */

  public String replace(InputStream oFileInStream, HashMap oMap) throws IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FastStreamReplacer.replace([InputStream],[HashMap])");
      DebugFile.incIdent();
    }

    int iChr;
    String sKey;
    Object oValue;

    Date dtToday = new Date();
    String sToday = String.valueOf(dtToday.getYear()+1900) + "-" + String.valueOf(dtToday.getMonth()+1) + "-" + String.valueOf(dtToday.getDate());

    oMap.put("Sistema.Fecha",sToday);
    oMap.put("System.Date",sToday);

    iReplacements = 0;

    BufferedInputStream oInStream = new BufferedInputStream(oFileInStream, BufferSize);

    oOutStream.setLength(0);

    do {
      iChr = oInStream.read();

      if (-1==iChr)
        break;

      else {

        if (123 == iChr) {
          // Se encontro el caracter '{'
          iChr = oInStream.read();
          if (35 == iChr) {
            // Se encontro el caracter '#'

            iReplacements++;

            sKey = "";

            do {

              iChr = oInStream.read();
              if (-1==iChr || 125==iChr)
                break;
              sKey += (char) iChr;

            } while (true);

            oValue = oMap.get(sKey);

            if (null!=oValue)
              oOutStream.append(((String)oValue));
          } // fi ('#')

          else {
            oOutStream.append((char)123);
            oOutStream.append((char)iChr);
          }

        } // fi ('{')

        else
          oOutStream.append((char)iChr);
      } // fi (!eof)

    } while (true);

    oInStream.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FastStreamReplacer.replace() : " + String.valueOf(oOutStream.length()));
    }

    return oOutStream.toString();
  } // replace()

  // ----------------------------------------------------------
  /**
   * Replace subtrings from a StringBuffer.
   * @param oStrBuff StringBuffer containing substrings to be replaced.
   * @param oMap Map with values to be replaced.<br>
   * Each map key will be replaced by its value.<br>
   * Map keys must appear in stream text as {#<i>key</i>}<br>
   * For example: InputStream "Today is {#System.Date}" will be replaced with "Today is 2002-02-21 11:32:44"<br>
   * No wildcards are accepted.<br>
   * Map keys must not contain {#&nbsp;} key markers.
   * @return String Replacements Result
   * @throws IOException
   * @throws IndexOutOfBoundsException
   */

  public String replace(StringBuffer oStrBuff, HashMap oMap)
    throws IOException, IndexOutOfBoundsException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FastStreamReplacer.replace([StringBuffer],[HashMap])");
      DebugFile.incIdent();
    }

    int iChr;
    String sKey;
    Object oValue;

    Date dtToday = new Date();
    String sToday = String.valueOf(dtToday.getYear()+1900) + "-" + String.valueOf(dtToday.getMonth()+1) + "-" + String.valueOf(dtToday.getDate());

    oMap.put("Sistema.Fecha",sToday);
    oMap.put("System.Date",sToday);

    iReplacements = 0;

    oOutStream.setLength(0);

    int iAt = 0;
    final int iLen = oStrBuff.length();

    while (iAt<iLen) {
      iChr = oStrBuff.charAt(iAt++);

        if (123 == iChr) {
          // Se encontro el caracter '{'
          iChr = oStrBuff.charAt(iAt++);
          if (35 == iChr) {
            // Se encontro el caracter '#'
            iReplacements++;

            sKey = "";

            while (iAt<iLen) {
              iChr = oStrBuff.charAt(iAt++);
              if (125==iChr) break;
              sKey += (char) iChr;
            } // wend

            oValue = oMap.get(sKey);

            if (null!=oValue)
              oOutStream.append(((String)oValue));
          } // fi ('#')

          else {
            oOutStream.append((char)123);
            oOutStream.append((char)iChr);
          }

        } // fi ('{')

        else
          oOutStream.append((char)iChr);

    } // wend

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FastStreamReplacer.replace() : " + String.valueOf(oOutStream.length()));
    }

    return oOutStream.toString();
  } // replace()

  // ----------------------------------------------------------


  /**
   * Replace substrings from a Text File.
   * @param sFilePath File containing text to be replaced.
   * @param oMap Map with values to be replaced.<br>
   * Each map key will be replaced by its value.<br>
   * Map keys must appear in stream text as {#<i>key</i>}<br>
   * For example: InputStream "Today is {#System.Date}" will be replaced with "Today is 2002-02-21 11:32:44"<br>
   * No wildcards are accepted.<br>
   * Map keys must not contain {#&nbsp;} key markers.
   * @return String Replacements Result.
   * @throws IOException
   */

  public String replace(String sFilePath, HashMap oMap) throws IOException {

    FileInputStream oStrm = new FileInputStream(sFilePath);
    String sRetVal = replace(oStrm, oMap);
    oStrm.close();

    return sRetVal;
  }

  // ----------------------------------------------------------

  /**
   * Number of replacements done in last call to replace() method.
   */
  public int lastReplacements() {
    return iReplacements;
  }

  // ----------------------------------------------------------

  /**
   * <p>Create a HashMap for a couple of String Arrays</p>
   * This method is just a convenient shortcut for creating input HashMap for
   * replace methods from this class
   * @param aKeys An array of Strings to be used as keys
   * @param aValues An array of Strings that will be the actual values for the keys
   * @return A HashMap with the given keys and values
   * @throws ArrayIndexOutOfBoundsException
   */
  public static HashMap createMap(String[] aKeys, String[] aValues) throws ArrayIndexOutOfBoundsException {

    if (aKeys.length!=aValues.length)
    	throw new ArrayIndexOutOfBoundsException("FastStreamReplacer.createMap() ArrayIndexOutOfBoundsException supplied "+String.valueOf(aKeys.length)+" keys but "+String.valueOf(aValues.length)+" values");
    
    HashMap oRetVal  = new HashMap(5+((aKeys.length*100)/60));

    for (int k=0; k<aKeys.length; k++)
      oRetVal.put(aKeys[k], aValues[k]);

    return oRetVal;
  } // createMap

  // ----------------------------------------------------------

} // FastStreamReplacer
