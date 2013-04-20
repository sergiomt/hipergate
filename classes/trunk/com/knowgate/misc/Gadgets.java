/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

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

import java.lang.StringBuffer;
import java.lang.System;

import java.util.Random;
import java.util.Date;
import java.util.StringTokenizer;
import java.util.Collection;
import java.util.LinkedList;
import java.util.Iterator;
import java.util.ArrayList;
import java.util.Currency;
import java.util.Locale;
import java.util.TreeMap;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.regex.PatternSyntaxException;

import java.math.BigDecimal;

import java.text.DecimalFormat;
import java.text.NumberFormat;

import java.net.InetAddress;
import java.net.UnknownHostException;

import org.apache.oro.text.regex.Util;
import org.apache.oro.text.regex.MatchResult;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Pattern;
import org.apache.oro.text.regex.Perl5Substitution;
import org.apache.oro.text.regex.PatternMatcherInput;
import org.apache.oro.text.regex.MalformedPatternException;

import com.knowgate.debug.DebugFile;

/**
 * Miscellaneous functions and utilities.
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public final class Gadgets {

  private static int iSequence = 1048576;

  private static DecimalFormat oFmt2 = null;
  private static Currency oCurr = null;
  private static String sCurr = null;

  private static Perl5Matcher oMatcher = null;
  private static Perl5Compiler oCompiler = null;  
  private static Perl5Pattern oXss1 = null, oXss2 = null;

  public Gadgets() { }

  private static String[] byteToStr = {
                                 "00","01","02","03","04","05","06","07","08","09","0a","0b","0c","0d","0e","0f",
                                 "10","11","12","13","14","15","16","17","18","19","1a","1b","1c","1d","1e","1f",
                                 "20","21","22","23","24","25","26","27","28","29","2a","2b","2c","2d","2e","2f",
                                 "30","31","32","33","34","35","36","37","38","39","3a","3b","3c","3d","3e","3f",
                                 "40","41","42","43","44","45","46","47","48","49","4a","4b","4c","4d","4e","4f",
                                 "50","51","52","53","54","55","56","57","58","59","5a","5b","5c","5d","5e","5f",
                                 "60","61","62","63","64","65","66","67","68","69","6a","6b","6c","6d","6e","6f",
                                 "70","71","72","73","74","75","76","77","78","79","7a","7b","7c","7d","7e","7f",
                                 "80","81","82","83","84","85","86","87","88","89","8a","8b","8c","8d","8e","8f",
                                 "90","91","92","93","94","95","96","97","98","99","9a","9b","9c","9d","9e","9f",
                                 "a0","a1","a2","a3","a4","a5","a6","a7","a8","a9","aa","ab","ac","ad","ae","af",
                                 "b0","b1","b2","b3","b4","b5","b6","b7","b8","b9","ba","bb","bc","bd","be","bf",
                                 "c0","c1","c2","c3","c4","c5","c6","c7","c8","c9","ca","cb","cc","cd","ce","cf",
                                 "d0","d1","d2","d3","d4","d5","d6","d7","d8","d9","da","db","dc","dd","de","df",
                                 "e0","e1","e2","e3","e4","e5","e6","e7","e8","e9","ea","eb","ec","ed","ee","ef",
                                 "f0","f1","f2","f3","f4","f5","f6","f7","f8","f9","fa","fb","fc","fd","fe","ff" };

  //-----------------------------------------------------------

  /**
   * Generate an universal unique identifier
   * @return An hexadecimal string of 32 characters,
   * created using the machine IP address, current system date, a randon number
   * and a sequence.
   */
  public static String generateUUID() {

    int iRnd;
    long lSeed = new Date().getTime();
    Random oRnd = new Random(lSeed);
    String sHex;
    StringBuffer sUUID = new StringBuffer(32);
    byte[] localIPAddr = new byte[4];

    try {

      // 8 characters Code IP address of this machine
      localIPAddr = InetAddress.getLocalHost().getAddress();

      sUUID.append(byteToStr[((int) localIPAddr[0]) & 255]);
      sUUID.append(byteToStr[((int) localIPAddr[1]) & 255]);
      sUUID.append(byteToStr[((int) localIPAddr[2]) & 255]);
      sUUID.append(byteToStr[((int) localIPAddr[3]) & 255]);
    }
    catch (UnknownHostException e) {
      // Use localhost by default
      sUUID.append("7F000000");
    }

    // Append a seed value based on current system date
    sUUID.append(Long.toHexString(lSeed));

    // 6 characters - an incremental sequence
    sUUID.append(Integer.toHexString(iSequence++));

    if (iSequence>16777000) iSequence=1048576;

    do {
      iRnd = oRnd.nextInt();
      if (iRnd>0) iRnd = -iRnd;
      sHex = Integer.toHexString(iRnd);
    } while (0==iRnd);

    // Finally append a random number
    sUUID.append(sHex);

    return sUUID.substring(0, 32);
  } // generateUUID()

  //-----------------------------------------------------------

  /**
   * Generate a random identifier of a given length
   * @param iLength int Length of identifier to be generated /between 1 and 4096 characters)
   * @param sCharset String Character set to be used for generating the identifier
   * @param byCategory byte Character category, must be one of Character.UNASSIGNED, Character.UPPERCASE_LETTER or Character.LOWERCASE_LETTER
   * If sCharset is <b>null</b> then it is "abcdefghjkmnpqrstuvwxyz23456789" by default
   * @return Identifier of given length composed using the designated character set
   * created using the machine IP address, current system date, a randon number
   * and a sequence.
   */
  public static String generateRandomId(int iLength, String sCharset, byte byCategory )
  	throws StringIndexOutOfBoundsException {
    
    if (iLength<=0) 
      throw new StringIndexOutOfBoundsException("Gadgets.generateRandomId() identifier length must be greater than zero");

    if (iLength>4096) 
      throw new StringIndexOutOfBoundsException("Gadgets.generateRandomId() identifier length must be less than or equal to 4096");

    if (sCharset!=null) {
      if (sCharset.length()==0) throw new StringIndexOutOfBoundsException("Gadgets.generateRandomId() character set length must be greater than zero");
    } else {
      sCharset = "abcdefghjkmnpqrstuvwxyz23456789";
    }
    
	if (byCategory!=Character.UNASSIGNED && byCategory!=Character.UPPERCASE_LETTER && byCategory!=Character.LOWERCASE_LETTER)
	  throw new IllegalArgumentException("Gadgets.generateRandomId() Character category must be one of {UNASSIGNED, UPPERCASE_LETTER, LOWERCASE_LETTER}");

	int iCsLen = sCharset.length();
    StringBuffer oId = new StringBuffer(iLength);
    Random oRnd = new Random(new Date().getTime());
    for (int i=0; i<iLength; i++){
	  char c = sCharset.charAt(oRnd.nextInt(iCsLen));
	  if (byCategory==Character.UPPERCASE_LETTER)
	  	c = Character.toUpperCase(c);
	  else if (byCategory==Character.LOWERCASE_LETTER)
	  	c = Character.toLowerCase(c);
	  oId.append(c);
	} // next
	return oId.toString();
  } // generateRandomId

  //-----------------------------------------------------------

  /**
   * <p>Return text enconded as XHTML.</p>
   * ASCII-7 characters [0..127] are returned as they are,
   * any other character is returned as &#<i>code</i>;
   * @param text String
   * @return String
   */
  public static String XHTMLEncode(String text) {
    char c;
    int len = text.length();
    StringBuffer results = new StringBuffer(len*2);

    for (int i = 0; i < len; ++i) {
      c = text.charAt(i);
      if (c<=127) {
		results.append(c);
      } else {
        results.append("&#"+String.valueOf((int)c)+";");
      }
    }
    return results.toString();
  }

  /**
   * <p>Escape XML entities &amp; &lt; and &gt;</p>
   * @param text String
   * @return String
   * @since 7.0
   */
  public static String XMLEncode(String text) {
    char c;
    int len = text.length();
    StringBuffer results = new StringBuffer(len*2);

    for (int i = 0; i < len; ++i) {
      c = text.charAt(i);
      switch (c) {
      	case '&':
      	  if (i>len-5)
      	    results.append("&amp;");
          else if (text.charAt(i+1)=='a' && text.charAt(i+2)=='m' && text.charAt(i+3)=='p' && text.charAt(i+4)==';')
      	    results.append(c);
      	  else if (text.charAt(i+1)=='#' &&
      	  	      ((text.charAt(i+2)>='0' && text.charAt(i+2)<='9') || text.charAt(i+2)=='x' || text.charAt(i+2)=='X'))
      	    results.append(c);
      	  else
      	    results.append("&amp;");      	  	
          break;
      	case '<':
      	  if (i>len-4)
      	    results.append("&lt;");
          else if (text.charAt(i+1)!='l' || text.charAt(i+2)!='t' || text.charAt(i+3)!=';')
      	    results.append("&lt;");
      	  else
      	    results.append(c);
          break;
      	case '>':
      	  if (i>len-4)
      	    results.append("&gt;");
          else if (text.charAt(i+1)!='t' || text.charAt(i+2)!='t' || text.charAt(i+3)!=';')
      	    results.append("&gt;");
      	  else
      	    results.append(c);
          break;
        default:
      	  results.append(c);        	
      }
    }
    return results.toString();
  }

  //-----------------------------------------------------------

  /**
   * <p>Return text enconded as HTML.</p>
   * For example "Tom & Jerry" is encoded as "Tom &amp; Jerry"
   * @param text Text to encode
   * @return HTML-encoded text
   */
  public static String HTMLEncode(String text) {
    if (text == null) return "";

    char c;
    int len = text.length();
    StringBuffer results = new StringBuffer(len);

    for (int i = 0; i < len; ++i) {
      c = text.charAt(i);
      switch (c) {
            case '&':
              results.append("&amp;");
              break;
            case '<':
              results.append("&lt;");
              break;
            case '>':
              results.append("&gt;");
              break;
            case 39:
              results.append("&#39;");
              break;
            case '"':
              results.append("&quot;");
              break;
            case '¡':
              results.append("&iexcl;");
              break;
            case '¤':
              results.append("&curren;");
              break;
            case '¥':
              results.append("&yen;");
              break;
            case '|':
              results.append("&brvbar;");
              break;
            case '§':
              results.append("&sect;");
              break;
            case '¨':
              results.append("&uml;");
              break;
            case '©':
              results.append("&copy;");
              break;
            case 'ª':
              results.append("&ordf;");
              break;
            case '«':
              results.append("&laquo;");
              break;
            case '»':
              results.append("&raquo;");
              break;
            case '€':
              results.append("&euro;");
              break;
            case '£':
              results.append("&pound;");
              break;
            case '­':
              results.append("&shy;");
              break;
            case '®':
              results.append("&reg;");
              break;
            case '¯':
              results.append("&macr;");
              break;
            case '°':
              results.append("&deg;");
              break;
            case '±':
              results.append("&plusmn;");
              break;
            case '¹':
              results.append("&sup1;");
              break;
            case '²':
              results.append("&sup2;");
              break;
            case '³':
              results.append("&sup3;");
              break;
            case '´':
              results.append("&acute;");
              break;
            case 'µ':
              results.append("&micro;");
              break;
            case '¶':
              results.append("&para;");
              break;
            case '·':
              results.append("&middot;");
              break;
            case '¸':
              results.append("&cedil;");
              break;
            case 'º':
              results.append("&ordm;");
              break;
            case '¿':
              results.append("&iquest;");
              break;
            case 'ñ':
              results.append("&ntilde;");
              break;
            case 'Ñ':
              results.append("&Ntilde;");
              break;
            case 'á':
              results.append("&aacute;");
              break;
            case 'é':
              results.append("&eacute;");
              break;
            case 'í':
              results.append("&iacute;");
              break;
            case 'ó':
              results.append("&oacute;");
              break;
            case 'ú':
              results.append("&uacute;");
              break;
            case 'ü':
              results.append("&uuml;");
              break;
            case 'Á':
              results.append("&Aacute;");
              break;
            case 'À':
              results.append("&Agrave;");
              break;
            case 'Ä':
              results.append("&Auml;");
              break;
            case 'Â':
              results.append("&Acirc;");
              break;
            case 'Å':
              results.append("&Aring;");
              break;
            case 'É':
              results.append("&Eacute;");
              break;
            case 'È':
              results.append("&Egrave;");
              break;
            case 'Ë':
              results.append("&Euml;");
              break;
            case 'Ê':
              results.append("&Ecirc;");
              break;
            case 'Í':
              results.append("&Iacute;");
              break;
            case 'Ì':
              results.append("&Igrave;");
              break;
            case 'Ï':
              results.append("&Iuml;");
              break;
            case 'Î':
              results.append("&Icirc;");
              break;
            case 'Ó':
              results.append("&Oacute;");
              break;
            case 'Ò':
              results.append("&Ograve;");
              break;
            case 'Ö':
              results.append("&Ouml;");
              break;
            case 'Ô':
              results.append("&Ocirc;");
              break;
            case 'Ú':
              results.append("&Uacute;");
              break;
            case 'Ù':
              results.append("&Ugrave;");
              break;
            case 'Ü':
              results.append("&Uuml;");
              break;
            case 'Û':
              results.append("&Ucirc;");
              break;
            case '½':
              results.append("&frac12;");
              break;
            case '¾':
              results.append("&frac34;");
              break;
            case '¼':
              results.append("&frac14;");
              break;
            case 'Ç':
              results.append("&Ccedil;");
              break;
            case 'ç':
              results.append("&ccedil;");
              break;
            case 'ð':
              results.append("&eth;");
              break;
            case '¢':
              results.append("&cent;");
              break;
            case 'Þ':
              results.append("&THORN;");
              break;
            case 'þ':
              results.append("&thorn;");
              break;
            case 'Ð':
              results.append("&ETH;");
              break;
            case '×':
              results.append("&times;");
              break;
            case '÷':
              results.append("&divide;");
              break;
            case 'Æ':
              results.append("&AElig;");
              break;

              /*
                           uml    => chr 168, #umlaut (dieresis)
                           laquo  => chr 171, #angle quotation mark, left
                           not    => chr 172, #not sign
                           shy    => chr 173, #soft hyphen
                           reg    => chr 174, #registered sign
                           macr   => chr 175, #macron
                           deg    => chr 176, #degree sign
                           sup2   => chr 178, #superscript two
                           sup3   => chr 179, #superscript three
                           acute  => chr 180, #acute accent
                           micro  => chr 181, #micro sign
                           para   => chr 182, #pilcrow (paragraph sign)
                           cedil  => chr 184, #cedilla
                           sup1   => chr 185, #superscript one
                           raquo  => chr 187, #angle quotation mark, right
                           iquest => chr 191, #inverted question mark
                           Auml   => chr 196, #capital A, dieresis or umlaut mark
                           Aring  => chr 197, #capital A, ring
                           Ccedil => chr 199, #capital C, cedilla
                           Egrave => chr 200, #capital E, grave accent
                           Eacute => chr 201, #capital E, acute accent
                           Ecirc  => chr 202, #capital E, circumflex accent
                           Euml   => chr 203, #capital E, dieresis or umlaut mark
                           Igrave => chr 204, #capital I, grave accent
                           Iacute => chr 205, #capital I, acute accent
                           Icirc  => chr 206, #capital I, circumflex accent
                           Iuml   => chr 207, #capital I, dieresis or umlaut mark
                           Ouml   => chr 214, #capital O, dieresis or umlaut mark
                           Oslash => chr 216, #capital O, slash
                           Ugrave => chr 217, #capital U, grave accent
                           Uacute => chr 218, #capital U, acute accent
                           Ucirc  => chr 219, #capital U, circumflex accent
                           Uuml   => chr 220, #capital U, dieresis or umlaut mark
                           Yacute => chr 221, #capital Y, acute accent
                           szlig  => chr 223, #small sharp s, German (sz ligature)
                           agrave => chr 224, #small a, grave accent
                           aacute => chr 225, #small a, acute accent
                           acirc  => chr 226, #small a, circumflex accent
                           atilde => chr 227, #small a, tilde
                           auml   => chr 228, #small a, dieresis or umlaut mark
                           aring  => chr 229, #small a, ring
                           aelig  => chr 230, #small ae diphthong (ligature)
                           ccedil => chr 231, #small c, cedilla
                           egrave => chr 232, #small e, grave accent
                           eacute => chr 233, #small e, acute accent
                           ecirc  => chr 234, #small e, circumflex accent
                           euml   => chr 235, #small e, dieresis or umlaut mark
                           igrave => chr 236, #small i, grave accent
                           iacute => chr 237, #small i, acute accent
                           icirc  => chr 238, #small i, circumflex accent
                           iuml   => chr 239, #small i, dieresis or umlaut mark
                           eth    => chr 240, #small eth, Icelandic
                           ntilde => chr 241, #small n, tilde
                           ograve => chr 242, #small o, grave accent
                           oacute => chr 243, #small o, acute accent
                           ocirc  => chr 244, #small o, circumflex accent
                           otilde => chr 245, #small o, tilde
                           ouml   => chr 246, #small o, dieresis or umlaut mark
                           divide => chr 247, #divide sign
                           oslash => chr 248, #small o, slash
                           ugrave => chr 249, #small u, grave accent
                           uacute => chr 250, #small u, acute accent
                           ucirc  => chr 251, #small u, circumflex accent
                           uuml   => chr 252, #small u, dieresis or umlaut mark
                           yacute => chr 253, #small y, acute accent
                           thorn  => chr 254, #small thorn, Icelandic
                           yuml   => chr 255, #small y, dieresis or umlaut mark

                             <!ENTITY Atilde CDATA "&#195;" -- latin capital letter A with tilde,
                                                               U+00C3 ISOlat1 -->
                             <!ENTITY Aring  CDATA "&#197;" -- latin capital letter A with ring above
                                                               = latin capital letter A ring,
                                                               U+00C5 ISOlat1 -->
                             <!ENTITY AElig  CDATA "&#198;" -- latin capital letter AE
                                                               = latin capital ligature AE,
                                                               U+00C6 ISOlat1 -->
                             <!ENTITY Egrave CDATA "&#200;" -- latin capital letter E with grave,
                                                               U+00C8 ISOlat1 -->
                             <!ENTITY Eacute CDATA "&#201;" -- latin capital letter E with acute,
                                                               U+00C9 ISOlat1 -->
                             <!ENTITY Ecirc  CDATA "&#202;" -- latin capital letter E with circumflex,
                                                               U+00CA ISOlat1 -->
                             <!ENTITY Euml   CDATA "&#203;" -- latin capital letter E with diaeresis,
                                                               U+00CB ISOlat1 -->
                             <!ENTITY Igrave CDATA "&#204;" -- latin capital letter I with grave,
                                                               U+00CC ISOlat1 -->
                             <!ENTITY Iacute CDATA "&#205;" -- latin capital letter I with acute,
                                                               U+00CD ISOlat1 -->
                             <!ENTITY Icirc  CDATA "&#206;" -- latin capital letter I with circumflex,
                                                               U+00CE ISOlat1 -->
                             <!ENTITY Iuml   CDATA "&#207;" -- latin capital letter I with diaeresis,
                                                               U+00CF ISOlat1 -->
                             <!ENTITY ETH    CDATA "&#208;" -- latin capital letter ETH, U+00D0 ISOlat1 -->
                             <!ENTITY Ograve CDATA "&#210;" -- latin capital letter O with grave,
                                                               U+00D2 ISOlat1 -->
                             <!ENTITY Oacute CDATA "&#211;" -- latin capital letter O with acute,
                                                               U+00D3 ISOlat1 -->
                             <!ENTITY Ocirc  CDATA "&#212;" -- latin capital letter O with circumflex,
                                                               U+00D4 ISOlat1 -->
                             <!ENTITY Otilde CDATA "&#213;" -- latin capital letter O with tilde,
                                                               U+00D5 ISOlat1 -->
                             <!ENTITY Ouml   CDATA "&#214;" -- latin capital letter O with diaeresis,
                                                               U+00D6 ISOlat1 -->
                             <!ENTITY times  CDATA "&#215;" -- multiplication sign, U+00D7 ISOnum -->
                             <!ENTITY Oslash CDATA "&#216;" -- latin capital letter O with stroke
                                                               = latin capital letter O slash,
                                                               U+00D8 ISOlat1 -->
                             <!ENTITY Ugrave CDATA "&#217;" -- latin capital letter U with grave,
                                                               U+00D9 ISOlat1 -->
                             <!ENTITY Uacute CDATA "&#218;" -- latin capital letter U with acute,
                                                               U+00DA ISOlat1 -->
                             <!ENTITY Ucirc  CDATA "&#219;" -- latin capital letter U with circumflex,
                                                               U+00DB ISOlat1 -->
                             <!ENTITY Uuml   CDATA "&#220;" -- latin capital letter U with diaeresis,
                                                               U+00DC ISOlat1 -->
                             <!ENTITY Yacute CDATA "&#221;" -- latin capital letter Y with acute,
                                                               U+00DD ISOlat1 -->
                             <!ENTITY THORN  CDATA "&#222;" -- latin capital letter THORN,
                                                               U+00DE ISOlat1 -->
                             <!ENTITY szlig  CDATA "&#223;" -- latin small letter sharp s = ess-zed,
                                                               U+00DF ISOlat1 -->
                             <!ENTITY agrave CDATA "&#224;" -- latin small letter a with grave
                                                               = latin small letter a grave,
                                                               U+00E0 ISOlat1 -->
                             <!ENTITY aacute CDATA "&#225;" -- latin small letter a with acute,
                                                               U+00E1 ISOlat1 -->
                             <!ENTITY acirc  CDATA "&#226;" -- latin small letter a with circumflex,
                                                               U+00E2 ISOlat1 -->
                             <!ENTITY atilde CDATA "&#227;" -- latin small letter a with tilde,
                                                               U+00E3 ISOlat1 -->
                             <!ENTITY auml   CDATA "&#228;" -- latin small letter a with diaeresis,
                                                               U+00E4 ISOlat1 -->
                             <!ENTITY aring  CDATA "&#229;" -- latin small letter a with ring above
                                                               = latin small letter a ring,
                                                               U+00E5 ISOlat1 -->
                             <!ENTITY aelig  CDATA "&#230;" -- latin small letter ae
                                                               = latin small ligature ae, U+00E6 ISOlat1 -->
                             <!ENTITY egrave CDATA "&#232;" -- latin small letter e with grave,
                                                               U+00E8 ISOlat1 -->
                             <!ENTITY ecirc  CDATA "&#234;" -- latin small letter e with circumflex,
                                                               U+00EA ISOlat1 -->
                             <!ENTITY euml   CDATA "&#235;" -- latin small letter e with diaeresis,
                                                               U+00EB ISOlat1 -->
                             <!ENTITY igrave CDATA "&#236;" -- latin small letter i with grave,
                                                               U+00EC ISOlat1 -->
                             <!ENTITY iacute CDATA "&#237;" -- latin small letter i with acute,
                                                               U+00ED ISOlat1 -->
                             <!ENTITY icirc  CDATA "&#238;" -- latin small letter i with circumflex,
                                                               U+00EE ISOlat1 -->
                             <!ENTITY iuml   CDATA "&#239;" -- latin small letter i with diaeresis,
                                                               U+00EF ISOlat1 -->
                             <!ENTITY ograve CDATA "&#242;" -- latin small letter o with grave,
                                                               U+00F2 ISOlat1 -->
                             <!ENTITY oacute CDATA "&#243;" -- latin small letter o with acute,
                                                               U+00F3 ISOlat1 -->
                             <!ENTITY ocirc  CDATA "&#244;" -- latin small letter o with circumflex,
                                                               U+00F4 ISOlat1 -->
                             <!ENTITY otilde CDATA "&#245;" -- latin small letter o with tilde,
                                                               U+00F5 ISOlat1 -->
                             <!ENTITY ouml   CDATA "&#246;" -- latin small letter o with diaeresis,
                                                               U+00F6 ISOlat1 -->
                             <!ENTITY divide CDATA "&#247;" -- division sign, U+00F7 ISOnum -->
                             <!ENTITY oslash CDATA "&#248;" -- latin small letter o with stroke,
                                                               = latin small letter o slash,
                                                               U+00F8 ISOlat1 -->
                             <!ENTITY ugrave CDATA "&#249;" -- latin small letter u with grave,
                                                               U+00F9 ISOlat1 -->
                             <!ENTITY uacute CDATA "&#250;" -- latin small letter u with acute,
                                                               U+00FA ISOlat1 -->
                             <!ENTITY ucirc  CDATA "&#251;" -- latin small letter u with circumflex,
                                                               U+00FB ISOlat1 -->
                             <!ENTITY uuml   CDATA "&#252;" -- latin small letter u with diaeresis,
                                                               U+00FC ISOlat1 -->
                             <!ENTITY yacute CDATA "&#253;" -- latin small letter y with acute,
                                                               U+00FD ISOlat1 -->
                             <!ENTITY thorn  CDATA "&#254;" -- latin small letter thorn,
                                                               U+00FE ISOlat1 -->
                             <!ENTITY yuml   CDATA "&#255;" -- latin small letter y with diaeresis,
                                                               U+00FF ISOlat1 -->

              */
            default:
              if (c<256)
                results.append(c);
              else
                results.append("&#"+String.valueOf(c)+";");
          } // end switch (c)
    } // end for (i)

    return results.toString();
  } // HTMLEncode

  //-----------------------------------------------------------

  public static String HTMLDencode(String text) {
    if (text == null) return "";

    char c;
    int len = text.length();
    StringBuffer results = new StringBuffer(len);
    
    final String[] aEnts = {"amp;", "lt;", "gt;", "quot;", "iexcl;", "curren;", "yen;", "brvbar;", "sect;",
                           "uml;", "copy;", "ordf;", "laquo;", "raquo;", "euro;", "pound;", "shy;", "reg;",
                           "macr;", "deg;", "plusmn;", "sup1;", "sup2;", "sup3;", "acute;", "micro;", "para;",
                           "middot;", "cedil;", "ordm;", "iquest;", "ntilde;", "Ntilde;", "aacute;", "eacute;", "iacute;",
                           "oacute;", "uacute;", "uuml;", "Aacute;", "Agrave;", "Auml;", "Acirc;", "Aring;", "Eacute;",
                           "Egrave;", "Euml;", "Ecirc;", "Iacute;", "Igrave;", "Iuml;", "Icirc;", "Oacute;", "Ograve;",
                           "Ouml;", "Ocirc;", "Uacute;", "Ugrave;", "Uuml;", "Ucirc;", "frac12;", "frac34;", "frac14;",
                           "Ccedil;", "ccedil;", "eth;", "cent;", "THORN;",  "thorn;", "ETH;", "times;", "divide;",
                           "AElig;", "ordf;", "hellip;", "bull;", "ldquo;", "rdquo;", "ndash;", "mdash;", "oline;",
                           "Alpha;", "Beta;", "Gamma;", "Delta;", "Epsilon;", "Lambda;", "Sigma;", "Pi;", "Psi;", "Omega;",
                           "alpha;", "beta;", "gamma;", "delta;", "epsilon;", "lambda;", "sigma;", "pi;", "zeta;", "omega;",
                           "forall;", "part;", "exist;", "empty;", "isin;", "notin;", "sum;", "infin;", "minus;",
                           "loz;", "spades;", "clubs;", "hearts;", "diams;", "nbsp;"
                           };

    final String[] aChars= {"&", "<", ">", "\"", "¡", "¤", "¥", "|", "§",
                            "¨", "©", "ª", "«" , "»", "€", "£", "­", "®",
                            "¯", "°", "±", "¹" , "²", "³", "´", "µ", "¶",
                            "·", "¸", "º", "¿" , "ñ", "Ñ", "á", "é", "í",
                            "ó", "ú", "ü", "Á" , "À", "Ä", "Â", "Å", "É",
                            "È", "Ë", "Ê", "Í" , "Ì", "Ï", "Î", "Ó", "Ò",
                            "Ö", "Ô", "Ú", "Ù" , "Ü", "Û", "½", "¾", "¼",
                            "Ç", "ç", "ð", "¢" , "Þ", "þ", "Ð", "×", "÷",
                            "Æ", "ª", "…", "•" , "“", "”", "–", "—", "‾",
                            "Α", "Β", "Γ", "Δ" , "Ε", "Λ", "Σ", "Π", "Ψ", "Ω",
                            "α", "β", "γ", "δ" , "ε", "λ", "σ", "σ", "ζ", "ω",
                            "∀", "∂", "∃", "∅" , "∈", "∈", "∑", "∞", "−",
                            "◊", "♠", "♣", "♥" , "♦", " "
                           };

    final int iEnts = aEnts.length;
    
    for (int i = 0; i < len; ) {
      c = text.charAt(i);
      if (c=='&' && i<len-3) {
        try {
          int semicolon = text.indexOf(59, i+1)+1;
          if (semicolon>0) {
            if (text.charAt(i+1)=='#') {
            	if (text.charAt(i+2)=='x')
                results.append( (char) Integer.parseInt(text.substring(i + 3, semicolon-1), 16));
              else
                results.append( (char) Integer.parseInt(text.substring(i + 2, semicolon-1)));
              i = semicolon;
            } else {
              int e = -1;
              for (int f=0; f<iEnts && e<0; f++)
              	if (aEnts[f].equals(text.substring(i+1, semicolon)))
              	  e = f;
              if (e>=0) {
                results.append(aChars[e]);
                i = semicolon;
              } else {
                results.append(c);
                i++;
              }
            }          
          } else {
            results.append(c);
            i++;        
          }
        } catch (StringIndexOutOfBoundsException siob) {
          return results.toString();
        }
      } else {
        results.append(c);
        i++;
      }
    } // next (i)

    return results.toString();
  } // HTMLDencode

  // ----------------------------------------------------------

  /**
   * Return text enconded as an URL.
   * For example, "Tom's Bookmarks" is encodes as "Tom%27s%20Bookmarks"
   * @param sStr Text to encode
   * @return URL-encoded text
   */
  public static String URLEncode (String sStr) {
    if (sStr==null) return null;

    int iLen = sStr.length();
    StringBuffer sEscaped = new StringBuffer(iLen+100);
    char c;
    for (int p=0; p<iLen; p++) {
      c = sStr.charAt(p);
      switch (c) {
        case ' ':
          sEscaped.append("%20");
          break;
        case '/':
          sEscaped.append("%2F");
          break;
        case '"':
          sEscaped.append("%22");
          break;
        case '#':
          sEscaped.append("%23");
          break;
        case '%':
          sEscaped.append("%25");
          break;
        case '&':
          sEscaped.append("%26");
          break;
        case (char)39:
          sEscaped.append("%27");
          break;
        case '+':
          sEscaped.append("%2B");
          break;
        case ',':
          sEscaped.append("%2C");
          break;
        case '=':
          sEscaped.append("%3D");
          break;
        case '?':
          sEscaped.append("%3F");
          break;
        case 'á':
          sEscaped.append("%E1");
          break;
        case 'é':
          sEscaped.append("%E9");
          break;
        case 'í':
          sEscaped.append("%ED");
          break;
        case 'ó':
          sEscaped.append("%F3");
          break;
        case 'ú':
          sEscaped.append("%FA");
          break;
        case 'Á':
          sEscaped.append("%C1");
          break;
        case 'É':
          sEscaped.append("%C9");
          break;
        case 'Í':
          sEscaped.append("%CD");
          break;
        case 'Ó':
          sEscaped.append("%D3");
          break;
        case 'Ú':
          sEscaped.append("%DA");
          break;
        case 'à':
          sEscaped.append("%E0");
          break;
        case 'è':
          sEscaped.append("%E8");
          break;
        case 'ì':
          sEscaped.append("%EC");
          break;
        case 'ò':
          sEscaped.append("%F2");
          break;
        case 'ù':
          sEscaped.append("%F9");
          break;
        case 'À':
          sEscaped.append("%C0");
          break;
        case 'È':
          sEscaped.append("%C8");
          break;
        case 'Ì':
          sEscaped.append("%CC");
          break;
        case 'Ò':
          sEscaped.append("%D2");
          break;
        case 'Ù':
          sEscaped.append("%D9");
          break;
        case 'ñ':
          sEscaped.append("%F1");
          break;
        case 'Ñ':
          sEscaped.append("%D1");
          break;
        case 'ç':
          sEscaped.append("%E7");
          break;
        case 'Ç':
          sEscaped.append("%C7");
          break;
        case 'ô':
          sEscaped.append("%F4");
          break;
        case 'Ô':
          sEscaped.append("%D4");
          break;
        case 'ö':
          sEscaped.append("%F6");
          break;
        case 'Ö':
          sEscaped.append("%D6");
          break;
        case '`':
          sEscaped.append("%60");
          break;
        case '¨':
          sEscaped.append("%A8");
          break;
        default:
          sEscaped.append(c);
          break;
      }
    } // next

    return sEscaped.toString();
  } // URLEncode

  // ----------------------------------------------------------

  /**
   * Convert an ASCII-8 String to an ASCII-7 String
   */
  public static String ASCIIEncode (String sStrIn) {
    if (sStrIn==null) return null;

    int iLen = sStrIn.length();

    if (iLen==0) return sStrIn;

    StringBuffer sStrBuff = new StringBuffer(iLen);
    String sStr = sStrIn.toUpperCase();

    for (int c=0; c<iLen; c++) {
      switch (sStr.charAt(c)) {
        case 'Á':
        case 'À':
        case 'Ä':
        case 'Â':
        case 'Å':
          sStrBuff.append('A');
          break;
        case 'É':
        case 'È':
        case 'Ë':
        case 'Ê':
          sStrBuff.append('E');
          break;
        case 'Í':
        case 'Ì':
        case 'Ï':
        case 'Î':
          sStrBuff.append('I');
          break;
        case 'Ó':
        case 'Ò':
        case 'Ö':
        case 'Ô':
        case 'Ø':
          sStrBuff.append('O');
          break;
        case 'Ú':
        case 'Ù':
        case 'Ü':
        case 'Û':
          sStrBuff.append('U');
          break;
        case 'Æ':
          sStrBuff.append('E');
          break;
        case 'Ñ':
          sStrBuff.append('N');
          break;
        case 'Ç':
          sStrBuff.append('C');
          break;
        case '°':
          sStrBuff.append('o');
          break;
        case 'ª':
          sStrBuff.append('a');
          break;
        case '\\':
        case '.':
        case '/':
          sStrBuff.append('_');
          break;
        case '&':
          sStrBuff.append('A');
          break;
        case ':':
          sStrBuff.append(';');
          break;
        case '<':
          sStrBuff.append('L');
          break;
        case '>':
          sStrBuff.append('G');
          break;
        case '"':
          sStrBuff.append((char)39);
          break;
        case '|':
          sStrBuff.append('P');
          break;
        case '¡':
          sStrBuff.append('E');
          break;
        case '¿':
        case '?':
          sStrBuff.append('Q');
          break;
        case '*':
          sStrBuff.append('W');
          break;
        case '%':
          sStrBuff.append('P');
          break;
        case 'ß':
          sStrBuff.append('B');
          break;
        case '¥':
          sStrBuff.append('Y');
          break;
        case (char)255:
          sStrBuff.append('_');
          break;
        default:
          sStrBuff.append(sStr.charAt(c));
      } // end switch
    } // next ()
    return sStrBuff.toString();
  } // ASCIIEncode

  // ----------------------------------------------------------

  /**
   * Replace any vowel by a POSIX Regular Expression representing all its accentuated variants
   * @return If Input String is Andrés Lozäno
   * the returned value will be something like [AÁÀÄÂAÅAAAÃ]ndr[eéàëêeeeee]s L[oóòöôoooøõo]z[aáàäâaåaaaã]n[oóòöôoooøõo]
   */
  public static String accentsToPosixRegEx(String sText) {
    String[] aSets = new String[]{"aáàäâaåaaaã",
    							                "eéèëêeeeee",
    							                "iíìïîiiiiii",
    							                "oóòöôoooøõō",
    							                "uúùüûuuuuuuuuu",
    							                "yýyÿy"};
    if (null==sText) return null;
    final int nSets = aSets.length;
    final int lText = sText.length();
    final String sLext = sText.toLowerCase();
    StringBuffer oText = new StringBuffer();
    for (int n=0; n<lText; n++) {
      char c = sLext.charAt(n);
      int iMatch = -1;
      for (int s=0; s<nSets && -1==iMatch; s++) {
        if (aSets[s].indexOf(c)>=0) iMatch=s;
      } // next(s)
      
      if (iMatch!=-1)
      	oText.append("["+(sText.charAt(n)==c ? aSets[iMatch] : aSets[iMatch].toUpperCase())+"]");
      else
      	oText.append(sText.charAt(n));
    } // next (n)
    return oText.toString();
  } // AccentsToPosixRegEx
  	
  /**
   * Split a String in two parts
   * This method is a special case optimization of split() to be used when
   * the input string is to be splitted by a single character delimiter and
   * there at most one occurrence of that delimiter.
   * @param sInputStr String to split
   * @param cDelimiter Single character to be used as delimiter,
   * the String will be splited on the first occurence of character.
   * @return If cDelimiter is not found, or cDelimiter if found as the first
   * character of sInputStr or cDelimiter if found as the last character of
   * sInputStr then an array with a single String element is returned. If
   * cDelimiter is found somewhere in the middle of sInputStr then an array
   * with 2 elements is returned.
   * @throws NullPointerException If sInputStr is <b>null</b>
   */
  public static String[] split2(String sInputStr, char cDelimiter)
    throws NullPointerException {

    int iDelim = sInputStr.indexOf(cDelimiter);

    if (iDelim<0)
      return new String[]{sInputStr};
    else if (iDelim==0)
      return new String[]{"", sInputStr.substring(iDelim+1)};
    else if (iDelim==sInputStr.length()-1)
      return new String[]{sInputStr.substring(0, iDelim), ""};
    else
      return new String[]{sInputStr.substring(0, iDelim), sInputStr.substring(iDelim+1)};
  } // split2

  // ----------------------------------------------------------

  /**
   * Split a String in two parts
   * This method is a special case optimization of split() to be used when
   * the input string is to be splitted by a variable length delimiter and
   * there at most one occurrence of that delimiter.
   * @param sInputStr String to split
   * @param sDelimiter String to be used as delimiter,
   * the String will be splited on the first occurence of sDelimiter.
   * @return If sDelimiter is not found, or sInputStr starts with sDelimiter or
   * sInputStr ends with sDelimiter then an array with a single String element
   * is returned. If sDelimiter is found somewhere in the middle of sInputStr
   * then an array with 2 elements is returned.
   * @throws NullPointerException If sInputStr is <b>null</b>
   */
  public static String[] split2(String sInputStr, String sDelimiter)
    throws NullPointerException  {

    int iDelim = sInputStr.indexOf(sDelimiter);

    if (iDelim<0)
      return new String[]{sInputStr};
    else if (iDelim==0)
      return new String[]{"", sInputStr.substring(iDelim+sDelimiter.length())};
    else if (iDelim==sInputStr.length()-sDelimiter.length())
      return new String[]{sInputStr.substring(0, iDelim), ""};
    else
      return new String[]{sInputStr.substring(0, iDelim), sInputStr.substring(iDelim+sDelimiter.length())};
  } // split2

  // ----------------------------------------------------------

  /**
   * <p>Split a String using a character delimiter</p>
   * Contiguous delimiters with nothing in the middle will delimit empty substrings.<br>
   * This is an important behaviour difference between Gadgets.split(String,String) and Gadgets.split(String,char).<br>
   * Gadgets.split("1;;3;;5;6,";") will return String[4] but Gadgets.split("1;;3;;5;6,';') will return String[6]
   * @param sInputStr String to split
   * @param cDelimiter Character Delimiter
   * @return An array with the splitted substrings
   * @throws NullPointerException If sInputStr is <b>null</b>
   */
  public static String[] split(String sInputStr, char cDelimiter)
    throws NullPointerException {
    int iStrLen = sInputStr.length();
    int iTokCount = 0;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Gadgets.split(\"" + sInputStr + "\",'" + cDelimiter+ "')");
      DebugFile.incIdent();
    }

    if (0==iStrLen) {
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Gadgets.split() : 0");
      }
      return null;
    }

    for (int p=0; p<iStrLen; p++)
      if (sInputStr.charAt(p)==cDelimiter) iTokCount++;

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iTokCount+1) + " tokens found");

    String Tokens[] = new String[iTokCount+1];

    int iToken = 0;
    int iLast = 0;
    for (int iNext=0; iNext<iStrLen; iNext++) {
      if (sInputStr.charAt(iNext)==cDelimiter) {
        if (iLast==iNext)
          Tokens[iToken] = "";
        else
          Tokens[iToken] = sInputStr.substring(iLast, iNext);
      iLast = iNext + 1;
      iToken++;
      } // fi (sInputStr[iNext]==cDelimiter)
    } // next

    if (iLast>=iStrLen)
      Tokens[iToken] = "";
    else
      Tokens[iToken] = sInputStr.substring(iLast, iStrLen);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Gadgets.split()");
    }
    return Tokens;
  } // split

  // ----------------------------------------------------------

  /**
   * <p>Split a String using any of the given characters as delimiter</p>
   * @param aDelimiter Character Delimiter Array
   * @return An array with the splitted substrings
   * @throws NullPointerException If sInputStr is <b>null</b> or aDelimiter is <b>null</b>
   */
  public static String[] split(String sInputStr, char[] aDelimiter)
    throws NullPointerException {
    int iStrLen = sInputStr.length();
    int iTokCount = 0;
    int iDelimCount = aDelimiter.length;
    int d;
    boolean b;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Gadgets.split(\"" + sInputStr + "\",char[])");
      DebugFile.incIdent();
    }

    if (0==iStrLen) {
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Gadgets.split() : 0");
      }
      return null;
    }

    for (int p=0; p<iStrLen; p++) {
      for (d=0,b=false; d<iDelimCount && !b; d++) b=(sInputStr.charAt(p)==aDelimiter[d]);
      if (b) iTokCount++;
    }

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iTokCount+1) + " tokens found");

    String Tokens[] = new String[iTokCount+1];

    int iToken = 0;
    int iLast = 0;
    for (int iNext=0; iNext<iStrLen; iNext++) {
      for (d=0,b=false; d<iDelimCount && !b; d++) b=(sInputStr.charAt(iNext)==aDelimiter[d]);
      if (b) {
        if (iLast==iNext)
          Tokens[iToken] = "";
        else
          Tokens[iToken] = sInputStr.substring(iLast, iNext);
      iLast = iNext + 1;
      iToken++;
      } // fi (sInputStr[iNext]==cDelimiter)
    } // next

    if (iLast>=iStrLen)
      Tokens[iToken] = "";
    else
      Tokens[iToken] = sInputStr.substring(iLast, iStrLen);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Gadgets.split()");
    }
    return Tokens;
  } // split

  // ----------------------------------------------------------

  /**
   * <p>Split a String using a substring delimiter</p>
   * Contiguous delimiters with nothing in the middle will be considered has a single delimiter.<br>
   * This is an important behaviour difference between Gadgets.split(String,String) and Gadgets.split(String,char).<br>
   * Gadgets.split("1;;3;;5;6,";") will return String[4] but Gadgets.split("1;;3;;5;6,';') will return String[6]
   * @param sInputStr String to split
   * @param sDelimiter Substring Delimiter (no regular expressions allowed)
   * @return An array with the splitted substrings
   * @throws NullPointerException If sInputStr is <b>null</b>
   */
  public static String[] split(String sInputStr, String sDelimiter)
    throws NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Gadgets.split(\"" + sInputStr + "\",\"" + sDelimiter+ "\")");
      DebugFile.incIdent();
    }

    // Split an input String by a given delimiter and return an array
    StringTokenizer oTokenizer = new StringTokenizer(sInputStr, sDelimiter);
    int iTokCount = oTokenizer.countTokens();
    int iTok = 0;
    String Tokens[] = null;

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iTokCount) + " tokens found");

    if(iTokCount>0) {
      Tokens = new String[iTokCount];
      while (oTokenizer.hasMoreTokens()) {
        Tokens[iTok] = oTokenizer.nextToken();
        if (DebugFile.trace) DebugFile.writeln("Token " + String.valueOf(iTok) + "=" + Tokens[iTok]);
        iTok++;
      } // wend
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Gadgets.split()");
    }

    return Tokens;
  } // split

  // ----------------------------------------------------------

  /**
   * Join a Collection into a String
   * @param oList Collection to join
   * @param sDelimiter Delimiter for elements in resulting String
   * @return List joined as a String
   */
  public static String join (Collection oList, String sDelimiter) {
    // Join a Collection into a single String
    StringBuffer oBuff = new StringBuffer(oList.size()*(32+sDelimiter.length())+1);
    Iterator oIter = oList.iterator();
    boolean bFirst = true;
    
    while (oIter.hasNext()) {
      if (bFirst) {
      	bFirst = false;
      } else {
        oBuff.append(sDelimiter);
      }
      oBuff.append(oIter.next());
    } // wend()

    oIter = null;

    return oBuff.toString();
  } // join

  // ----------------------------------------------------------

  /**
   * Join an Array into a String
   * @param aList Array to join
   * @param sDelimiter Delimiter for elements in resulting String
   * @return List joined as a String
   * @since v3.0
   */

  public static String join (String[] aList, String sDelimiter) {
    if (null==aList) return null;
    final int iCount = aList.length;
    if (iCount==0) return "";
    if (null==sDelimiter) sDelimiter="";

    // Join an array into a single String
    StringBuffer oBuff = new StringBuffer(iCount*(32+sDelimiter.length())+1);
    oBuff.append(aList[0]);
    for (int s=1; s<iCount; s++) {
      oBuff.append(sDelimiter);
      oBuff.append(aList[s]);
    }
    return oBuff.toString();
  } // join

  // ----------------------------------------------------------

   /**
    * <p>Split a String into a Collection using a character delimiter</p>
    * Contiguous delimiters with nothing in the middle will delimit empty substrings.
    * @param sInputStr String to split
    * @param cDelimiter Character Delimiter
    * @return A LinkedList splitted substrings
    * @throws NullPointerException If sInputStr is <b>null</b>
    */

   public static Collection splitAsCollection(String sInputStr, char cDelimiter)
     throws NullPointerException {
     int iStrLen = sInputStr.length();

     if (DebugFile.trace) {
       DebugFile.writeln("Begin Gadgets.splitAsCollection(\"" + sInputStr + "\",'" + cDelimiter+ "')");
       DebugFile.incIdent();
     }

     LinkedList oTokens = new LinkedList();

     int iLast = 0;
     for (int iNext=0; iNext<iStrLen; iNext++) {
       if (sInputStr.charAt(iNext)==cDelimiter) {
         if (iLast==iNext)
           oTokens.add("");
         else
           oTokens.add(sInputStr.substring(iLast, iNext));
       iLast = iNext + 1;
       } // fi (sInputStr[iNext]==cDelimiter)
     } // next

     if (iLast>=iStrLen)
       oTokens.add("");
     else
       oTokens.add(sInputStr.substring(iLast, iStrLen));

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Gadgets.splitAsCollection() : " + String.valueOf(oTokens.size()));
     }
     return oTokens;
   } // splitAsCollection

  // ----------------------------------------------------------

  /**
   * Perform case sensitive brute force search of a String into an Array
   * @param aList Array of Strings
   * @param sSought String sought
   * @return String index into Array or -1 if not found or sSought is null
   * @since v5.0
   */

  public static int search (String[] aList, String sSought) {
    if (null==sSought) return -1;
    int iRetVal = -1;
    final int nList = aList.length;
    for (int a=0; a<nList && iRetVal==-1; a++) {
      if (sSought.equals(aList[a])) {
      	iRetVal = a;
      }
    } //next
    return iRetVal;
  } // search

  // ----------------------------------------------------------

  /**
   * Perform brute force search of an int into an Array
   * @param aList Array of int
   * @param iSought Value sought
   * @return Index into Array or -1 if not found
   * @since v5.5
   */

  public static int search (int[] aList, int iSought) {
    int iRetVal = -1;
    final int nList = aList.length;
    for (int a=0; a<nList && iRetVal==-1; a++) {
      if (iSought==aList[a]) {
      	iRetVal = a;
      }
    } //next
    return iRetVal;
  } // search

  // ----------------------------------------------------------

  /**
   * Get index of a substring inside another string
   * @param sSource String String to be scanned
   * @param sSought Substring to be sought
   * @param iStartAt int Index to start searching from
   * @return int Start index of substring or -1 if not found
   */

  public static int indexOfIgnoreCase(String sSource, String sSought, int iStartAt) {
    if ((sSource==null) || (sSought==null)) return -1;

    final int iSrcLen = sSource.length();
    final int iSghLen = sSought.length();

    if (iSrcLen<iSghLen) return -1;

    if (iSrcLen==iSghLen) return (sSource.equalsIgnoreCase(sSought) ? 0 : -1);

    final int iReducedLen = iSrcLen-iSghLen;

    if (iStartAt+iSghLen>iSrcLen) return -1;

    for (int p=iStartAt; p<iReducedLen; p++) {
      if (sSource.substring(p, p+iSghLen).equalsIgnoreCase(sSought))
        return p;
    }
    return -1;
  }

  // ----------------------------------------------------------

  /**
   * Get index of a substring inside another string
   * @param sSource String String to be scanned
   * @param sSought Substring to be sought
   * @return int Start index of substring or -1 if not found
   */
  public static int indexOfIgnoreCase(String sSource, String sSought) {
    if ((sSource==null) || (sSought==null)) return -1;

    final int iSrcLen = sSource.length();
    final int iSghLen = sSought.length();

    if (iSrcLen<iSghLen) return -1;

    if (iSrcLen==iSghLen) return (sSource.equalsIgnoreCase(sSought) ? 0 : -1);

    final int iReducedLen = iSrcLen-iSghLen;

    for (int p=0; p<iReducedLen; p++) {
      if (sSource.substring(p, p+iSghLen).equalsIgnoreCase(sSought))
        return p;
    }
    return -1;
  } // indexOfIgnoreCase

  // ----------------------------------------------------------

  /**
   * Fill String with a given character
   * @param c Character for filling
   * @param len Number of characters
   * @return A String with given numbers of characters
   * @throws IndexOutOfBoundsException if len<0
   */
  public static String fill(char c, int len) throws IndexOutOfBoundsException {
    // Return a String filled with a given character
    if (len<0)
      throw new IndexOutOfBoundsException("Gadgets.fill() numbers of characters must be greater than or equal to zero");
    else if (len==0)
      return "";
    else {
      StringBuffer oStrBuff = new StringBuffer(len);
      for (int i=0; i<len; i++) oStrBuff.append(c);
      return oStrBuff.toString();
    }
  } // fill

  // ----------------------------------------------------------
  /**
   * Repeat a substring n times
   * @param sSubStr Substring to be repeated
   * @param nTimes Number of times to repeat
   * @return String with n repetitions of sSubStr,
   * if nTimes is zero the empty string "" is returned,
   * if sSubStr is null the null is returned
   * @throws IndexOutOfBoundsException if nTimes<0
   * @since 4.0
   */
  public static String repeat (String sSubStr, int nTimes)
  	throws IndexOutOfBoundsException {
    if (null==sSubStr) return null;
    if (sSubStr.length()==0) return "";
    StringBuffer oStrBuff = new StringBuffer(sSubStr.length()*nTimes);
    for (int t=0; t<nTimes; t++) oStrBuff.append(sSubStr);
    return oStrBuff.toString();
  } // repeat

  // ----------------------------------------------------------

  /**
   * Check whether or not a String matches a regular expression
   * @param sSource String Source
   * @param sRegExp String Regular Expression
   * @return boolean <b>false</b> if either sSource or sRegExp are <b>null</b>
   * @throws MalformedPatternException
   * @since v3.0
   * @see http://www.savarese.org/oro/docs/OROMatcher/Syntax.html
   */
  public static boolean matches (String sSource, String sRegExp) throws MalformedPatternException {
    
    if (sSource==null || sRegExp==null) {
      return false;
    } else {
      try {
        Pattern oPatt = Pattern.compile(sRegExp);
        return oPatt.matcher(sSource).matches();
      } catch (PatternSyntaxException pse) {
    	throw new MalformedPatternException(sRegExp);
      }
    }
  } // matches

  // ----------------------------------------------------------

  /**
   * Check whether or not a String contains a regular expression
   * @param sSource String Source
   * @param sRegExp String Regular Expression
   * @return boolean <b>false</b> if either sSource or sRegExp are <b>null</b>
   * @throws MalformedPatternException
   * @since v3.0
   * @see http://www.savarese.org/oro/docs/OROMatcher/Syntax.html
   */
  public static boolean contains (String sSource, String sRegExp) throws MalformedPatternException {
    if (sSource==null || sRegExp==null) {
      return false;
    } else {
      try {
        Pattern oPatt = Pattern.compile(sRegExp);
        return oPatt.matcher(sSource).find();
      } catch (PatternSyntaxException pse) {
        throw new MalformedPatternException(sRegExp);
      }    	
    }
  } // contains

  // ----------------------------------------------------------

  /**
   * Get the first substring that matches the given regular expression
   * @param sSource String Source
   * @param sRegExp String Regular Expression
   * @return String if no substring matches the regular expression then <b>null</b> is returned
   * @throws MalformedPatternException
   * @since v3.0
   * @see http://jakarta.apache.org/oro/api/org/apache/oro/text/regex/Perl5Matcher.html
   */
  public static String getFirstMatchSubStr (String sSource, String sRegExp) throws MalformedPatternException {
    String sRetStr;
    if (sSource==null || sRegExp==null)
      sRetStr=null;
    else {
      try {
        Matcher oMatchr = Pattern.compile(sRegExp).matcher(sSource);
        if (oMatchr.find())
          return oMatchr.group();
        else
          return null;
      } catch (PatternSyntaxException pse) {
        throw new MalformedPatternException(sRegExp);
      }    	
    }
    return sRetStr;
  } // getFirstMatchSubStr

  // ----------------------------------------------------------

  /**
   * Get all substrings that match the given regular expression
   * @param sSource String Source
   * @param sRegExp String Regular Expression
   * @return ArrayList<MatchResult>
   * @throws MalformedPatternException
   * @since v7.0
   */
  public static ArrayList<MatchResult> getAllMatches (String sSource, String sRegExp) throws MalformedPatternException {
    ArrayList<MatchResult> aRetVal = new ArrayList<MatchResult>();
    if (sSource!=null && sRegExp!=null) {
      if (null==oMatcher) oMatcher = new Perl5Matcher();
      if (null==oCompiler) oCompiler = new Perl5Compiler();
      Perl5Pattern oPatt = (Perl5Pattern) oCompiler.compile(sRegExp);
      PatternMatcherInput oPmin = new PatternMatcherInput(sSource);
      while (oMatcher.contains(oPmin, oPatt)) {
        aRetVal.add(oMatcher.getMatch());
      } // wend
    } // fi
    return aRetVal;
  } // getAllMatches

  // --------------------------------------------------------------------------

  /**
   * Check if a String seems to has a cross site scripting attack signature
   * @param sSource String to be checked
   * @return <b>true</b>if the input string appears to be an XSS attack attempt
   * @since 6.0
   */

  public static boolean hasXssSignature(String sSource) {
    boolean bIsXss;
    if (sSource==null)
      bIsXss = false;
    else {
      if (null==oXss1) {
        oMatcher = new Perl5Matcher();
        oCompiler = new Perl5Compiler();
        try {
	      oXss1 = (Perl5Pattern) oCompiler.compile("((\\%3C)|<)((\\%2F)|\\/)*[a-z0-9A-Z\\%]+((\\%3E)|>)");
	      oXss2 = (Perl5Pattern) oCompiler.compile("((\\%3C)|<)((\\%69)|(i|I)|(\\%49))((\\%6D)|(m|M)|(\\%4D))((\\%67)|(g|G)|(\\%47))[^\\n]+((\\%3E)|>)");
        } catch (MalformedPatternException neverthrown) { }
      } // fi
      bIsXss = oMatcher.matches(sSource, oXss1) || oMatcher.matches(sSource, oXss2);
    }
    return bIsXss;
  } // hasXssSignature

  // ----------------------------------------------------------

  /**
   * Convert each letter after space to Upper Case and all others to Lower Case
   * @param sSource Source String
   * @return Replaced string or <b>null</b> if sSource if <b>null</b>
   * @since 7.0
   */
  
  public static String capitalizeFirst(String sSource) {
    if (null==sSource) {
      return null;
    } else {
      char[] aChars = sSource.toLowerCase().toCharArray();
      int nChars = aChars.length;
	  boolean bFound = false;
	  for (int i = 0; i < nChars; i++) {
	    if (!bFound && Character.isLetter(aChars[i])) {
	      aChars[i] = Character.toUpperCase(aChars[i]);
	      bFound = true;
	    } else if (Character.isWhitespace(aChars[i])) {
	      bFound = false;
	    }
	  } // next
	  return String.valueOf(aChars);
    }
  } // capitalizeFirst

  // ----------------------------------------------------------
  
  /**
   * Replace a single character with one or more other characters
   * @param sSource Source String
   * @param cSought Character to be sought
   * @param sNewVal New value for character,
   * if it is an empty string "" then the sought character
   * is just removed from the source string
   * @return Replaced string or <b>null</b> if sSource if <b>null</b>
   * @throws NullPointerException if sNewVal is <b>null</b>
   * @since 4.0
   */
  public static String replace(String sSource, char cSought, String sNewVal) throws NullPointerException {
    if (null==sSource) return null;
    int nLen = sSource.length();
	if (0==nLen) return "";
    StringBuffer oOut = new StringBuffer(nLen+100);
    if (sNewVal.length()==0) {
      for (int c=0; c<nLen; c++) {
        char cAt = sSource.charAt(c);
        if (cAt!=cSought) oOut.append(cAt);
      } // next
    } else {
      for (int c=0; c<nLen; c++) {
        char cAt = sSource.charAt(c);
        if (cAt==cSought)
      	  oOut.append(sNewVal);
        else
          oOut.append(cAt);
      } // next
    }
    return oOut.toString();
  } // replace

  // ----------------------------------------------------------

  /**
   * Replace a given pattern on a string with a fixed value
   * @param sSource Source String
   * @param sRegExp Regular Expression to be matched
   * @param sNewVal New value for replacement
   * @throws MalformedPatternException
   * @throws NullPointerException if either sRegExp or NewVal is null
   * @see http://www.savarese.org/oro/docs/OROMatcher/Syntax.html
   */
  public static String replace(String sSource, String sRegExp, String sNewVal) throws MalformedPatternException {

    if (null==oMatcher) oMatcher = new Perl5Matcher();
    if (null==oCompiler) oCompiler = new Perl5Compiler();

	if (null==sSource) return null;

	if (null==sRegExp) throw new NullPointerException("Gadgets.replace() pattern may not be null");
	if (null==sNewVal) throw new NullPointerException("Gadgets.replace() new value may not be null");

    return Util.substitute(oMatcher, oCompiler.compile(sRegExp),
			   new Perl5Substitution(sNewVal, Perl5Substitution.INTERPOLATE_ALL),
                           sSource, Util.SUBSTITUTE_ALL);
  } // replace

  /**
   * Replace a given pattern on a string with a fixed value
   * @param sSource Source String
   * @param sRegExp Regular Expression to be matched
   * @param sNewVal New value for replacement
   * @param iOptions A set of flags giving the compiler instructions on how to
   * treat the regular expression. The flags are a logical OR of any number of
   * the five <a href="http://jakarta.apache.org/oro/api/org/apache/oro/text/regex/Perl5Compiler.html">
   * org.apache.oro.text.regex.Perl5Compiler</A> MASK constants.<br>
   * <table>
   * <tr><td>CASE_INSENSITIVE_MASK</td><td>Compiled regular expression should be case insensitive</td></tr>
   * <tr><td>DEFAULT_MASK</td><td>Use default mask for compile method</td></tr>
   * <tr><td>EXTENDED_MASK</td><td>compiled regular expression should be treated as a Perl5 extended pattern (i.e., a pattern using the /x modifier)</td></tr>
   * <tr><td>MULTILINE_MASK</td><td>Compiled regular expression should treat input as having multiple lines</td></tr>
   * <tr><td>READ_ONLY_MASK</td><td>Resulting Perl5Pattern should be treated as a read only data structure by Perl5Matcher, making it safe to share a single Perl5Pattern instance among multiple threads without needing synchronization</td></tr>
   * <tr><td>SINGLELINE_MASK</td><td>Compiled regular expression should treat input as being a single line</td></tr>
   * @throws MalformedPatternException
   * @see http://www.savarese.org/oro/docs/OROMatcher/Syntax.html
   */
  public static String replace(String sSource, String sRegExp, String sNewVal, int iOptions) throws MalformedPatternException {

	if (null==oMatcher) oMatcher = new Perl5Matcher();
    if (null==oCompiler) oCompiler = new Perl5Compiler();

    return Util.substitute(oMatcher, oCompiler.compile(sRegExp, iOptions),
                           new Perl5Substitution(sNewVal, Perl5Substitution.INTERPOLATE_ALL),
                           sSource, Util.SUBSTITUTE_ALL);
  } // replace

  // ----------------------------------------------------------

  /**
   * Count occurrences of a given substring
   * @param sSource String Source
   * @param sSubStr Substring to be searched (no wildcards)
   * @param iOptions int org.apache.oro.text.regex.Perl5Compiler.CASE_INSENSITIVE_MASK for case insensitive search
   * @return int Number of occurrences of sSubStr at sSource.
   * If sSource is null or sSubStr is null then the number of occurrences is zero.
   * If sSource is empty or sSubStr is empty then the number of occurrences is zero.
   */
  public static int countOccurrences(String sSource, String sSubStr, int iOptions) throws MalformedPatternException {
    if (null==sSource || null==sSubStr) return 0;
    if (sSource.length()==0 || sSubStr.length()==0) return 0;

    int lSource = sSource.length();
    int lSubStr = sSubStr.length();
    int iOccurrences = 0;
    int iCurPos;
    if ((org.apache.oro.text.regex.Perl5Compiler.CASE_INSENSITIVE_MASK&iOptions)==0) {
      iCurPos = sSource.indexOf(sSubStr);
      while (iCurPos!=-1 && iCurPos+lSubStr<=lSource) {
        iOccurrences++;
        iCurPos = sSource.indexOf(sSubStr, iCurPos+1);
      }
    } else {
      iCurPos = Gadgets.indexOfIgnoreCase(sSource, sSubStr);
      while (iCurPos!=-1 && iCurPos+lSubStr<=lSource) {
        iOccurrences++;
        iCurPos = Gadgets.indexOfIgnoreCase(sSource, sSubStr, iCurPos+1);
      }
    }
    return iOccurrences;
  } // countOccurrences

  // ----------------------------------------------------------

  /**
   * Return left portion of a string.
   * This function is similar to substring(sSource, nChars) but it does not raise
   * any exception if sSource.length()>nChars but just return the full sSource
   * input String.
   * @param sSource Source String
   * @param nChars Number of characters to the left of String to get.
   * @return Left characters of sSource String or <b>null</b> if sSource is <b>null</b>.
   */
  public static String left(String sSource, int nChars) {
    int iLen;

    if (null==sSource) return null;

    iLen = sSource.length();

    if (iLen>nChars)
      return sSource.substring(0, nChars);
    else
      return sSource;
  } // left

  // ----------------------------------------------------------

  /**
   * Add padding characters to the left.
   * @param sSource Input String
   * @param cPad Padding character
   * @param nChars Final length of the padded string
   * @return Padded String
   */
  public static String leftPad(String sSource, char cPad, int nChars) {
      if (null==sSource) return null;

      int iPadLen = nChars - sSource.length();

      if (iPadLen<=0) return sSource;

      char aPad[] = new char[iPadLen];

      java.util.Arrays.fill(aPad, cPad);

      return new String(aPad) + sSource;
  } // leftPad

  // ----------------------------------------------------------

  /**
   * Add padding characters to the right.
   * @param sSource Input String
   * @param cPad Padding character
   * @param nChars Final length of the padded string
   * @return Padded String
   * @since 4.0
   */
  public static String rightPad(String sSource, char cPad, int nChars) {
      if (null==sSource) return null;

      int iPadLen = nChars - sSource.length();

      if (iPadLen<=0) return sSource;

      char aPad[] = new char[iPadLen];

      for (int c=0; c<iPadLen; c++) aPad[c] = cPad;

      return sSource+new String(aPad);
  } // rightPad
  
  // ----------------------------------------------------------

  /**
   * Ensure that a String ends with a given character
   * @param sSource Input String
   * @param cEndsWith Character that the String must end with.
   * @return If sSource ends with cEndsWith then sSource is returned,
   * else sSource+cEndsWith is returned.
   */
  public static String chomp(String sSource, char cEndsWith) {

    if (null==sSource)
      return null;
    else if (sSource.length()==0)
      return "";
    else if (sSource.charAt(sSource.length()-1)==cEndsWith)
      return sSource;
    else
      return sSource + String.valueOf(cEndsWith);
  } // chomp

  // ----------------------------------------------------------

  /**
   * Ensure that a String ends with a given substring
   * @param sSource Input String
   * @param sEndsWith Substring that the String must end with.
   * @return If sSource ends with sEndsWith then sSource is returned,
   * else sSource+sEndsWith is returned.
   */
  public static String chomp(String sSource, String sEndsWith) {

    if (null==sSource)
      return null;
    else if (sSource.length()==0)
      return "";
    else if (sSource.endsWith(sEndsWith))
      return sSource;
    else
      return sSource + sEndsWith;
  } // chomp

  // ----------------------------------------------------------

  /**
   * Ensure that a String does not end with a given substring
   * @param sSource Input String
   * @param sEndsWith Substring that the String must not end with.
   * @return If sSource does not end with sEndsWith then sSource is returned,
   * else sSource-sEndsWith is returned.
   */
  public static String dechomp(String sSource, String sEndsWith) {

    if (null==sSource)
      return null;
    else if (sEndsWith==null)
      return sSource;
    else if (sSource.length()<sEndsWith.length())
      return sSource;
    else if (sSource.endsWith(sEndsWith))
      return sSource.substring(0, sSource.length()-sEndsWith.length());
    else
      return sSource;
  } // dechomp

  // ----------------------------------------------------------

  /**
   * Ensure that a String does not end with a given character
   * @param sSource Input String
   * @param cEndsWith Character that the String must not end with.
   * @return If sSource does not end with sEndsWith then sSource is returned,
   * else sSource-cEndsWith is returned.
   */
  public static String dechomp(String sSource, char cEndsWith) {

    if (null==sSource)
      return null;
    else if (sSource.length()<1)
      return sSource;
    else if (sSource.charAt(sSource.length()-1)==cEndsWith)
      return sSource.substring(0, sSource.length()-1);
    else
      return sSource;
  } // dechomp

  // ----------------------------------------------------------

  /**
   * Get substring between two given character sequence
   * @param sSource Source String
   * @param sLowerBound Lower bound character sequence
   * @param sUpperBound Upper bound character sequence
   * @return Subtring between sLowerBound and sUpperBound or <b>null</b> if
   * either sLowerBound or sUpperBound are not found at sSource
   * @since 4.0
   */
  public static String substrBetween(String sSource, String sLowerBound, String sUpperBound)
    throws StringIndexOutOfBoundsException,NullPointerException {
    String sRetVal = substrAfter(sSource, 0, sLowerBound);
    if (null!=sRetVal) {
      if (sRetVal.indexOf(sUpperBound)>=0) {
        sRetVal = substrUpTo(sRetVal,0,sUpperBound);
      } else {
      	sRetVal = null;
      } // fi
    } // fi
    return sRetVal;
  } // substrBetween

  // ----------------------------------------------------------

  /**
   * Get substring after a given character sequence
   * @param sSource Source String
   * @param iFromIndex Index top start searching character sequence from
   * @param sSought Character sequence sought
   * @return Substring after sSought character sequence.
   * If source string is empty then return value is always an empty string.
   * If sought substring is empty then return value is the whole source string.
   * If sought substring is not found then return value is <b>null</b>
   * @throws StringIndexOutOfBoundsException
   * @throws NullPointerException is source or sought string is null
   * @since 4.0
   */
  public static String substrAfter(String sSource, int iFromIndex, String sSought)
  	throws StringIndexOutOfBoundsException,NullPointerException {
    String sRetVal;
    
    if (sSource.length()==0) {
      sRetVal = "";
    } else {
      if (sSought.length()==0) {
      	sRetVal =  sSource;
      } else {
        iFromIndex = sSource.indexOf(sSought, iFromIndex);
        if (iFromIndex<0) {
          sRetVal = null;
        } else {
  	      if (iFromIndex==sSource.length()-1) {
  	  	   sRetVal = "";
  	      } else {
  	  	    sRetVal = sSource.substring(iFromIndex+sSought.length());
  	      }
        }
      }
    }
    return sRetVal;    
  } // substrAfter

  // ----------------------------------------------------------
  	
  /**
   * Get substring from an index up to next given character
   * @param sSource Source String
   * @param iFromIndex Index top start searching character from
   * @param cSought Character sought
   * @return Substring between iFromIndex and cSought character
   * @throws StringIndexOutOfBoundsException if cSought character is not found at sSource
   * @since 4.0
   */
  public static String substrUpTo(String sSource, int iFromIndex, char cSought)
  	throws StringIndexOutOfBoundsException {
  	String sRetVal;
  	if (null==sSource) {
  		sRetVal=null;  	
  	} else {
      int iToIndex = sSource.indexOf(cSought, iFromIndex);
	  if (iToIndex<0) throw new StringIndexOutOfBoundsException ("Gadgets.substrUpTo() character "+cSought+" not found");
	  if (iFromIndex==iToIndex)
	    sRetVal = "";
	  else
	    sRetVal = sSource.substring(iFromIndex, iToIndex);
  	}
  	return sRetVal;
  } // substrUpTo

  // ----------------------------------------------------------

  /**
   * Get substring from an index up to next given character sequence
   * @param sSource Source String
   * @param iFromIndex Index top start searching character from
   * @param sSought Character sequence sought
   * @return Substring between iFromIndex and sSought
   * @throws StringIndexOutOfBoundsException if sSought sequence is not found at sSource
   * @since 4.0
   */
  public static String substrUpTo(String sSource, int iFromIndex, String sSought)
  	throws StringIndexOutOfBoundsException {
  	String sRetVal;
  	if (null==sSource) {
  		sRetVal=null;  	
  	} else {
      int iToIndex = sSource.indexOf(sSought, iFromIndex);
	  if (iToIndex<0) throw new StringIndexOutOfBoundsException ("Gadgets.substrUpTo() character "+sSought+" not found");
	  if (iFromIndex==iToIndex)
	    sRetVal = "";
	  else
	    sRetVal = sSource.substring(iFromIndex, iToIndex);
  	}
  	return sRetVal;
  } // substrUpTo

  // ----------------------------------------------------------

  /**
   * <p>Take an input string and tokenize each command on it<p>
   * @param sSource String to be parsed.<br>
   * Tokens are separated by spaces. Single or double quotes are allowed for qualifying string literals.
   * @return String[] Array of tokens. If sSource is <b>null</b> then the return value is <b>null</b>,
   * if sSource is empty then the return value is an array with a single element being it <b>null</b>.
   * @throws StringIndexOutOfBoundsException
   */
  public static String[] tokenizeCmdLine(String sSource)
    throws StringIndexOutOfBoundsException {
    String[] aTokens;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Gadgets.tokenizeCmdLine("+sSource+")");
       DebugFile.incIdent();
    }

    if (null==sSource) {
      aTokens=null;
    } else if (sSource.length()==0) {
      aTokens=new String[]{null};
    } else {
      final int iLen = sSource.length();
      ArrayList oTokens = new ArrayList();
      char cTextQualifier = (char) 0;
      char cCurrentChar;
      StringBuffer oCurrentToken = new StringBuffer(256);
      for (int p=0; p<iLen; p++) {
        cCurrentChar = sSource.charAt(p);
        switch (cCurrentChar) {
          case ' ':
            if (0!=cTextQualifier) {
              oCurrentToken.append(cCurrentChar);
            } else if (oCurrentToken.length()>0) {
              oTokens.add(oCurrentToken.toString());
              oCurrentToken.setLength(0);
            }
            break;
          case '\\':
            if (p==iLen-1) throw new StringIndexOutOfBoundsException("Input string terminated with a single backslash character");
            switch (sSource.charAt(++p)) {
              case 'n':
                oCurrentToken.append('\n');
                break;
              case 't':
                oCurrentToken.append('\t');
                break;
              case '\\':
                oCurrentToken.append('\\');
                break;
              case '"':
                oCurrentToken.append('"');
                break;
              default:
                throw new StringIndexOutOfBoundsException("Unrecognized escape sequence \\"+sSource.charAt(p)+" at "+sSource.substring(p-5>=0 ? p-5 : 0, p+5<=sSource.length()-1 ? p+5 : sSource.length()-1));
            } // end switch (charAt(++p))
            break;
          case '"':
            if (0==cTextQualifier) {
              cTextQualifier='"';
            } else if ('"'==cTextQualifier) {
              cTextQualifier=(char)0;
            }
            break;
          case '\'':
            if (0==cTextQualifier) {
              cTextQualifier='\'';
            } else if ('\''==cTextQualifier) {
              cTextQualifier=(char)0;
            }
            break;
          case ',':
          case ';':
          case '(':
          case ')':
          case '[':
          case ']':
          case '{':
          case '}':
          case '-':
          case '+':
          case '/':
          case '*':
          case '=':
          case '&':
          case '!':
          case '?':
            if (0!=cTextQualifier) {
              oCurrentToken.append(cCurrentChar);
            }
            else  {
              if (oCurrentToken.length()>0) {
                oTokens.add(oCurrentToken.toString());
                oCurrentToken.setLength(0);
              }
              oTokens.add(new String(new char[]{cCurrentChar}));
            }
            break;
          default:
            oCurrentToken.append(cCurrentChar);
        }
      } // next
      if (oCurrentToken.length()>0) {
        oTokens.add(oCurrentToken.toString());
      }
      aTokens=new String[oTokens.size()];
      System.arraycopy(oTokens.toArray(),0,aTokens,0,aTokens.length);
    }

    if (DebugFile.trace) {
      StringBuffer oOutput = new StringBuffer();
      if (aTokens!=null)
        for (int t=0; t<aTokens.length; t++)
          oOutput.append(aTokens[t]+(t<aTokens.length-1 ? "¶" :""));
      DebugFile.decIdent();
      DebugFile.writeln("End Gadgets.tokenizeCmdLine() : " + oOutput.toString());
    }

    return aTokens;
  } // tokenizeCmdLine

  // ----------------------------------------------------------

  /**
   * <p>Take an input string and return a map of commands<p>
   * @param sSource String to be parsed.<br>
   * The String must be of the form parameter1="value1" parameter2="value2" parameter3="value3"<br>
   * Map keys will be parameter1,parameter2,parameter3 and map values value1,value2,value3
   * @return TreeMap A case insensitive map
   * @throws StringIndexOutOfBoundsException
   * @since 4.0
   */

  public static TreeMap mapCmdLine(String sSource)
    throws StringIndexOutOfBoundsException {
	TreeMap oCommands = new TreeMap(String.CASE_INSENSITIVE_ORDER);
	String[] aTokens = tokenizeCmdLine(sSource);
	if (null!=aTokens) {
	  for (int t=0; t<aTokens.length; t++) {
	    String sToken = aTokens[t];
	    int iEq = sToken.indexOf('=');
	    if (0==iEq) {
		  throw new StringIndexOutOfBoundsException("Parameter "+String.valueOf(t+1)+" begins with equal sign but expected a parameter name");	      
	    } else if (iEq==sToken.length()-1) {
		  throw new StringIndexOutOfBoundsException("Parameter "+String.valueOf(t+1)+" ends with equal sign but expected a value for it");
	    } else if (iEq>0) {
	      String[] aPair = Gadgets.split2(sToken,'=');
	      oCommands.put(aPair[0],aPair[1]);
	    }
	  } // next
	} // fi
	return oCommands;
  } // mapCmdLine

  // ----------------------------------------------------------

  /**
   * Check that an e-mail address is syntactically valid.
   * @param sEMailAddr e-mail address to check
   * @return <b>true</b> if e-mail address is syntactically valid.
   */
  public static boolean checkEMail(String sEMailAddr) {
	boolean b = false;
	try {
      b = matches (sEMailAddr, "[\\w\\x2B\\x2E_-]+@[\\w\\x2E_-]+\\x2E\\D{2,4}");
    } catch (MalformedPatternException neverthrown) { }	
    return b;
  } // checkEMail

  // ----------------------------------------------------------

  public static final char[] HEX_DIGITS = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };

  public static void toHexChars( int val, char dst[], int dstIndex, int size ) {
      while( size > 0 ) {
          dst[dstIndex + size - 1] = HEX_DIGITS[val & 0x000F];
          if( val != 0 ) {
              val >>>= 4;
          }
          size--;
      }
  }

  // ----------------------------------------------------------

  public static String toHexString( int val, int size ) {
      char[] c = new char[size];
      toHexChars( val, c, 0, size );
      return new String( c );
  }

  // ----------------------------------------------------------

  /**
   * Convert a byte array into its corresponding Hexadecimal String representation
   * @param src Input array
   * @param srcIndex Begin Index
   * @param size Number of bytes to be readed
   * @return A String with two hexadecimal upper case digits per byte on the input array
   */
  public static String toHexString( byte[] src, int srcIndex, int size ) {
      if (null==src) return null;

      char[] c = new char[size];
      size = ( size % 2 == 0 ) ? size / 2 : size / 2 + 1;
      for( int i = 0, j = 0; i < size; i++ ) {
          c[j++] = HEX_DIGITS[(src[i] >> 4 ) & 0x0F];
          if( j == c.length ) {
              break;
          }
          c[j++] = HEX_DIGITS[src[i] & 0x0F];
      }
      return new String( c );
  }

  // ----------------------------------------------------------

  /**
   * Convert a byte array into its corresponding Hexadecimal String representation
   * @param src Input array
   * @return A String with two hexadecimal upper case digits per byte on the input array
   */
  public static String toHexString( byte[] src) {
    if (null==src) return null;

    return toHexString(src, 0, src.length);
  }

  // ----------------------------------------------------------

  /**
   * Remove a character from a String
   * @param sInput Input String
   * @param cRemove Character to be removed
   * @return The input String without all the occurences of the given character
   */
  public static String removeChar(String sInput, char cRemove) {
    if (null==sInput) return null;
    if (sInput.length()==0) return sInput;

    final int iLen = sInput.length();
    StringBuffer oOutput = new StringBuffer(iLen);

    for (int i=0; i<iLen; i++) {
      char c = sInput.charAt(i);
      if (cRemove!=c)
        oOutput.append(c);
    } // next

    return oOutput.toString();
  } // removeChar

  // ----------------------------------------------------------

  /**
   * Remove a character set from a String
   * @param sInput Input String
   * @param sRemove A String containing all the characters to be removed from input String
   * @return The input String without all the characters of sRemove
   */
  public static String removeChars(String sInput, String sRemove) {
    if (null==sInput) return null;
    if (null==sRemove) return sInput;
    if (sInput.length()==0) return sInput;
    if (sRemove.length()==0) return sInput;

    final int iLen = sInput.length();
    StringBuffer oOutput = new StringBuffer(iLen);

    for (int i=0; i<iLen; i++) {
      char c = sInput.charAt(i);
      if (sRemove.indexOf(c)<0)
        oOutput.append(c);
    } // next

    return oOutput.toString();
  } // removeChars

  // ----------------------------------------------------------

  /**
   * Preffixes a set of special characters with an escape character
   * @param sInput String
   * @param sSpecialSet Set of special characters
   * @param cEsc Escape character to be used
   * @return The input String without all special characters preceded by the escape character
   * for example: if input is "Chicken & ~Egg",the special set is "&~" and escape is '¬' then
   * returned value is "Chicken ¬& ¬~Egg"
   * @throws NullPointerException if sSpecialSet is null
   * @since 4.0
   */
  public static String escapeChars(String sInput, String sSpecialSet, char cEsc)
  	throws NullPointerException {

	if (null==sSpecialSet) throw new NullPointerException("Gadgets.escapeChars() especial character set cannot be null");

    if (null==sInput) return null;
    
    final int nLen = sInput.length();
    if (nLen==0) return "";
    
    StringBuffer oOutput = new StringBuffer(nLen+100);
	char cAt;
	for (int c=0; c<nLen; c++) {
	  cAt = sInput.charAt(c);
	  if (sSpecialSet.indexOf(cAt)>=0)
	    oOutput.append(cEsc);
	  oOutput.append(cAt);
	} // next
	return oOutput.toString();
  } // escapeChars
  
  // ----------------------------------------------------------

  /**
   * Rounds a BigDecimal value to two decimals
   * @param oDec BigDecimal to be rounded
   * @return BigDecimal If oDec is <b>null</b> then round2 returns <b>null</b>
   */
  public static BigDecimal round2 (BigDecimal oDec) {
    if (null==oDec) return null;
    if (null==oFmt2) {
      // oFmt2 = new DecimalFormat("#0.00");
	  oFmt2 = new DecimalFormat();
	  oFmt2.setMaximumFractionDigits(2);
    }
    
    return new BigDecimal (oFmt2.format(oDec.doubleValue()).replace(',', '.'));
  }

  // ----------------------------------------------------------

  /**
   * Format a BigDecimal as a String following the rules for an specific locale
   * @param oDec BigDecimal to be formatted
   * @param sCurrency String ISO 4217 currency code (EUR, USD, GBP, BRL, CNY, etc.)
   * @param sLanguage String lowercase two-letter ISO-639 code
   * @param sLocale2 String uppercase two-letter ISO-3166 code
   * @return String
   * @see <a href="http://www.bsi-global.com/British_Standards/currency/index.xalter">BSI Currency Code Service (ISO 4217 Maintenance Agency)</a>
   * @see <a href="http://www.xe.com/iso4217.htm">ISO 4217 currency code list</a>
   * @see <a href="http://www.ics.uci.edu/pub/ietf/http/related/iso639.txt">ISO 639 language codes</a>
   * @see <a href="http://www.iso.org/iso/en/prods-services/iso3166ma/02iso-3166-code-lists/list-en1.html">ISO 3166 country codes</a>
   */
  public static String formatCurrency (BigDecimal oDec, String sCurrency,
                                       String sLanguage, String sCountry) {
    if (null==oDec) return null;

    Locale oLoc;
    if (null!=sLanguage && null!=sCountry)
      oLoc = new Locale(sLanguage,sCountry);
    else if (null!=sLanguage)
      oLoc = new Locale(sLanguage);
    else
      oLoc = Locale.getDefault();
    if (null==sCurrency) {
      oCurr = Currency.getInstance(oLoc);
    }
    else if (!sCurrency.equals(sCurr)) {
      oCurr = Currency.getInstance(sCurrency);
    }
    NumberFormat oFmtC = NumberFormat.getCurrencyInstance(oLoc);
    oFmtC.setCurrency(oCurr);
    return oFmtC.format(oDec.doubleValue());
  }

  // ----------------------------------------------------------

  /**
   * Format a BigDecimal as a String following the rules for an specific locale
   * @param oDec BigDecimal to be formatted
   * @param sCurrency String ISO 4217 currency code (EUR, USD, GBP, BRL, CNY, etc.)
   * @param sLanguage String lowercase two-letter ISO-639 code
   * @return String
   * @see <a href="http://www.xe.com/iso4217.htm">ISO 4217 currency code list</a>
   * @see <a href="http://www.ics.uci.edu/pub/ietf/http/related/iso639.txt">ISO 639 language codes</a>
   */
  public static String formatCurrency (BigDecimal oDec, String sCurrency,
                                       String sLanguage) {
    if (null==oDec) return null;

    Locale oLoc = (sLanguage==null ? Locale.getDefault() : new Locale(sLanguage));
    if (null==sCurrency) {
      oCurr = Currency.getInstance(oLoc);
    }
    else if (!sCurrency.equals(sCurr)) {
      oCurr = Currency.getInstance(sCurrency);
    }
    NumberFormat oFmtC = NumberFormat.getCurrencyInstance(oLoc);
    oFmtC.setCurrency(oCurr);
    return oFmtC.format(oDec.doubleValue());
  }

  // ----------------------------------------------------------
  /**
   * Format a BigDecimal as a String following the rules for an specific locale
   * @param oDec BigDecimal to be formatted
   * @param sCurrency String ISO 4217 currency code (EUR, USD, GBP, BRL, CNY, etc.)
   * @param oLocale Locale used for formatting
   * @return String
   * @see <a href="http://java.sun.com/j2se/1.4.2/docs/api/java/util/Locale.html">java.util.Locale</a>
   */
  public static String formatCurrency (BigDecimal oDec, String sCurrency, Locale oLocale) {
    NumberFormat oFmtC;
    if (null==oDec) return null;

    if (null==sCurrency) {
      oCurr = Currency.getInstance(oLocale==null ? Locale.getDefault() : oLocale);
    }
    else if (!sCurrency.equals(sCurr)) {
      oCurr = Currency.getInstance(sCurrency);
    }
    if (null==oLocale)
      oFmtC = NumberFormat.getCurrencyInstance(Locale.getDefault());
    else
      oFmtC = NumberFormat.getCurrencyInstance(oLocale);
    oFmtC.setCurrency(oCurr);
    return oFmtC.format(oDec.doubleValue());
  } // formatCurrency

  // ----------------------------------------------------------

  /**
   * <p>Calculate Levenshtein distance between two strings</p>
   * The Levenshtein distance is defined as the minimal number of characters
   * you have to replace, insert or delete to transform str1 into str2.
   * The complexity of the algorithm is O(m*n),
   * where n and m are the length of str1 and str2.
   * @return Levenshtein distance between str1 and str2
   * @throws IllegalArgumentException if either str1 or str2 is <b>null</b>
   * @author Michael Gilleland & Chas Emerick
   * @see <a href="http://www.merriampark.com/ldjava.htm">http://www.merriampark.com/ldjava.htm</a>
   * @since 4.0
   */

  public static int getLevenshteinDistance (String s, String t) {
    if (s == null || t == null) {
      throw new IllegalArgumentException("Strings must not be null");
    }
  		
    int n = s.length(); // length of s
    int m = t.length(); // length of t
  		
    if (n == 0) {
      return m;
    } else if (m == 0) {
      return n;
    }
  
    int p[] = new int[n+1]; //'previous' cost array, horizontally
    int d[] = new int[n+1]; // cost array, horizontally
    int _d[]; //placeholder to assist in swapping p and d
  
    // indexes into strings s and t
    int i; // iterates through s
    int j; // iterates through t
  
    char t_j; // jth character of t
  
    int cost; // cost
  
    for (i = 0; i<=n; i++) {
       p[i] = i;
    }
  		
    for (j = 1; j<=m; j++) {
       t_j = t.charAt(j-1);
       d[0] = j;
  		
       for (i=1; i<=n; i++) {
          cost = s.charAt(i-1)==t_j ? 0 : 1;
          // minimum of cell to the left+1, to the top+1, diagonally left and up +cost				
          d[i] = Math.min(Math.min(d[i-1]+1, p[i]+1),  p[i-1]+cost);  
       }
  
       // copy current distance counts to 'previous row' distance counts
       _d = p;
       p = d;
       d = _d;
    } 
  		
    // our last action in the above loop was to switch d and p, so p now 
    // actually has the most recent cost counts
    return p[n];
  } // getLevenshteinDistance

  // ----------------------------------------------------------

  public static void main(String[] argv) {
    if (argv.length>0) {
      if (argv[0].equalsIgnoreCase("uuidgen")) {
        System.out.println(Gadgets.generateUUID());
      } // fi (argv[0]=="uuidgen")
    }
  }

} // Gadgets
