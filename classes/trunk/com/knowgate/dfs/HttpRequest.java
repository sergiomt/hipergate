/*
  Copyright (C) 2003-2012  Know Gate S.L. All rights reserved.

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

package com.knowgate.dfs;

import java.io.Reader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;

import java.net.URL;
import java.net.URLEncoder;
import java.net.HttpURLConnection;
import java.net.URISyntaxException;
import java.net.MalformedURLException;

import java.text.SimpleDateFormat;

import java.util.Map;
import java.util.Date;
import java.util.ArrayList;
import java.util.List;
import java.util.Iterator;

import org.apache.oro.text.regex.*;
import org.knallgrau.utils.textcat.TextCategorizer;

import org.htmlparser.Parser;
import org.htmlparser.util.ParserException;
import org.htmlparser.beans.StringBean;

import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Base64Encoder;
import com.knowgate.misc.NameValuePair;

/**
 * Wrapper for an HTTP request
 * @author Sergio Montoro Ten
 *
 */
public class HttpRequest extends Thread {

  private String sUrl;
  private URL oReferUrl;
  private String sMethod;
  private NameValuePair[] aParams;
  private Object oRetVal;
  private String sPageSrc, sEncoding, sUsr, sPwd;
  private int responseCode; 
  private ArrayList<NameValuePair> aCookies;

  private static final SimpleDateFormat oDtFmt = new SimpleDateFormat("EEE, dd-MMM-yyyy hh:mm:ss z");
  
  // ------------------------------------------------------------------------

  /**
   * Create new request for the given URL
   * @param sUrl String
   */
  public HttpRequest(String sUrl) {
    this.sUrl = sUrl;
    oReferUrl = null;
    sMethod = "GET";
    aParams = null;
    responseCode=0;
    oRetVal = null;
    sPageSrc = null;
    sEncoding = null;
    sUsr = null;
    sPwd = null;
    aCookies = new ArrayList<NameValuePair>();
  }	

  // ------------------------------------------------------------------------

  /**
   * Create new request for the given URL
   * @param sUrl String requested URL
   * @param oReferUrl String Referer URL
   * @param sMethod String Must be "get" or "post"
   * @param aParams Array of NameValuePair with parameters to be sent along with get or post
   */
  public HttpRequest(String sUrl, URL oReferUrl, String sMethod, NameValuePair[] aParams) {
    this.sUrl = sUrl;
    this.oReferUrl = oReferUrl;
    this.sMethod = sMethod;
    this.aParams = aParams;
    responseCode=0;
    oRetVal = null;
    sPageSrc = null;    
    sEncoding = null;  
    sUrl = null;
    sPwd = null;
    aCookies = new ArrayList<NameValuePair>();
  }	

  // ------------------------------------------------------------------------

  /**
   * Create new request for the given URL with basic authentication
   * @param sUrl String requested URL
   * @param oReferUrl String Referer URL
   * @param sMethod String Must be "get" or "post"
   * @param aParams Array of NameValuePair with parameters to be sent along with get or post
   */
  public HttpRequest(String sUrl, URL oReferUrl, String sMethod, NameValuePair[] aParams, String sUsr, String sPwd) {
    this.sUrl = sUrl;
    this.oReferUrl = oReferUrl;
    this.sMethod = sMethod;
    this.aParams = aParams;
    this.responseCode=0;
    this.oRetVal = null;
    this.sPageSrc = null;    
    this.sEncoding = null;  
    this.sUsr = sUsr;
    this.sPwd = sPwd;
    this.aCookies = new ArrayList<NameValuePair>();
  }	
  
  // ------------------------------------------------------------------------

  /**
   * Get cookies readed from the last get or post call
   * @return ArrayList<NameValuePair>
   */
  public ArrayList<NameValuePair> getCookies() {
    return aCookies;
  }

  // ------------------------------------------------------------------------

  /**
   * Set cookies foor next call to get or post method
   * @param aCookies ArrayList<NameValuePair>
   */
  public void setCookies(ArrayList<NameValuePair> aCookies) {
    this.aCookies = aCookies;
  }
  
  // ------------------------------------------------------------------------

  public void run() {
  	try {
    if (sMethod.equalsIgnoreCase("POST"))
	  post();
	else if (sMethod.equalsIgnoreCase("GET"))
      get();
  	} catch (MalformedURLException mue) {
  	} catch (URISyntaxException use) {
  	} catch (IOException ioe) {
  	}
  } // run

  // ------------------------------------------------------------------------

  private void readResponseCookies(HttpURLConnection oCon) {
	Map<String,List<String>> oHdrs = oCon.getHeaderFields();
    Iterator<String> oNames = oHdrs.keySet().iterator();
    while (oNames.hasNext()) {
      String sName = oNames.next();
      if ("Set-Cookie".equals(sName)) {
        Iterator<String> oValues = oHdrs.get(sName).iterator();
        while (oValues.hasNext()) {
          String[] aCookie = oValues.next().split("; ");
          String[] aCookieNameValue=aCookie[0].split("=");
          boolean isExpired=false;
          try {
            String[] aCookieExpired=aCookie[1].split("=");
            Date dtExpires = oDtFmt.parse(aCookieExpired[1]);
            isExpired=(dtExpires.compareTo(new Date())<=0);
          } catch (Exception ignore) { }
          if (!isExpired) {
        	if (aCookieNameValue.length>1)
        	  aCookies.add(new NameValuePair(aCookieNameValue[0],aCookieNameValue[1]));
        	else
          	  aCookies.add(new NameValuePair(aCookieNameValue[0],""));        	  
          }
        } // wend
      } // fi
    } // wend
  }

  // ------------------------------------------------------------------------

  private void writeRequestCookies(HttpURLConnection oCon) {
    StringBuffer oCookies = new StringBuffer();
	for (NameValuePair nvp : aCookies)
      oCookies.append(nvp.getName()+"="+nvp.getValue()+"; ");
	oCon.setRequestProperty("Cookie", oCookies.toString());
  }
  
  // ------------------------------------------------------------------------
  
  /**
   * Perform HTTP POST request
   * @return Object A String or a byte array containing the response to the request
   * @throws IOException if server returned any status different from HTTP_MOVED_PERM (301), HTTP_MOVED_TEMP (302), HTTP_OK (200) or HTTP_ACCEPTED  (202)
   * @throws URISyntaxException
   * @throws MalformedURLException
   */
  public Object post ()
    throws IOException, URISyntaxException, MalformedURLException {

    oRetVal = null;
    sPageSrc = null;
    sEncoding = null;

	URL oUrl;
    
	if (null==oReferUrl)
	  oUrl = new URL(sUrl);
	else
	  oUrl = new URL(oReferUrl, sUrl);

	String sParams = "";
	if (aParams!=null) {
	  for (int p=0; p<aParams.length; p++) {
	    sParams += aParams[p].getName()+"="+URLEncoder.encode(aParams[p].getValue(), "ISO8859_1");
	    if (p<aParams.length-1) sParams += "&";
	  } // next
	} // fi

    HttpURLConnection oCon = (HttpURLConnection) oUrl.openConnection();

    oCon.setUseCaches(false);
    oCon.setInstanceFollowRedirects(false);
    oCon.setDoInput (true);
	oCon.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows; U; Windows NT 6.1; rv:2.2) Gecko/20110201");

    if (sUsr!=null && sPwd!=null)
      oCon.setRequestProperty ("Authorization", "Basic " + Base64Encoder.encode(sUsr + ":" + sPwd));
    oCon.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
	oCon.setRequestProperty("Content-Length", String.valueOf(sParams.getBytes().length));
	oCon.setFixedLengthStreamingMode(sParams.getBytes().length);
    oCon.setDoOutput(true);
	oCon.setRequestMethod("POST"); 
	writeRequestCookies(oCon);
	OutputStreamWriter oWrt = new OutputStreamWriter(oCon.getOutputStream());
    oWrt.write(sParams);
    oWrt.flush();
    oWrt.close();

	responseCode = oCon.getResponseCode();
    String sLocation = oCon.getHeaderField("Location");
    if (sLocation!=null)
    	if (sLocation.charAt(0)=='/')
    		sLocation = "http://centros.lectiva.com"+sLocation;
    System.out.println("responseCode=" + String.valueOf(responseCode) + " Location="+sLocation);
    
	if ((responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
		responseCode == HttpURLConnection.HTTP_MOVED_TEMP) &&
		!sUrl.equals(sLocation)) {
      HttpRequest oMoved = new HttpRequest(sLocation, oUrl, "GET", null);
      readResponseCookies(oCon);
      oMoved.setCookies(getCookies());
	  oRetVal = oMoved.post();
	  sUrl = oMoved.url();
	} else if (responseCode == HttpURLConnection.HTTP_OK ||
	           responseCode == HttpURLConnection.HTTP_ACCEPTED) {
	  readResponseCookies(oCon);
	  InputStream oStm = oCon.getInputStream();
	  String sEnc = oCon.getContentEncoding();
	  if (sEnc==null) {
	  	ByteArrayOutputStream oBya = new ByteArrayOutputStream();
	  	new StreamPipe().between(oStm, oBya);
	    oRetVal = oBya.toByteArray();
	  } else {
	  	int c;
	  	StringBuffer oDoc = new StringBuffer();
	    Reader oRdr = new InputStreamReader(oStm, sEnc);
	    while ((c=oRdr.read())!=-1) {
	      oDoc.append((char) c);
	    } // wend
	    oRdr.close();
	    oRetVal = oDoc.toString();
	  }
	  oStm.close();
	} else {
	  throw new IOException(String.valueOf(responseCode));
	}
	oCon.disconnect();
	return oRetVal;
  } // post

  // ------------------------------------------------------------------------

  public String url() {
    return sUrl;
  }

  // ------------------------------------------------------------------------

  /**
   * Perform HTTP GET request
   * @return Object A String or a byte array containing the response to the request
   * @throws IOException if server returned any status different from HTTP_MOVED_PERM (301), HTTP_MOVED_TEMP (302), HTTP_OK (200) or HTTP_ACCEPTED  (202)
   * @throws URISyntaxException
   * @throws MalformedURLException
   */
  public Object get ()
    throws IOException, URISyntaxException, MalformedURLException {
	
    oRetVal = null;
    sPageSrc = null;
	sEncoding = null;

	URL oUrl;

	String sParams = "";
	if (aParams!=null) {
	  if (sUrl.indexOf('?')<0) sParams = "?";
	  for (int p=0; p<aParams.length; p++) {
	    sParams += aParams[p].getName()+"="+URLEncoder.encode(aParams[p].getValue(), "ISO8859_1");
	    if (p<aParams.length-1) sParams += "&";
	  } // next
	} // fi
    
	if (null==oReferUrl)
	  oUrl = new URL(sUrl+sParams);
	else
	  oUrl = new URL(oReferUrl, sUrl+sParams);

    HttpURLConnection oCon = (HttpURLConnection) oUrl.openConnection();
		
    if (sUsr!=null && sPwd!=null)
        oCon.setRequestProperty ("Authorization", "Basic " + Base64Encoder.encode(sUsr + ":" + sPwd));
    oCon.setUseCaches(false);
    oCon.setInstanceFollowRedirects(false);
	oCon.setRequestMethod("GET");
	oCon.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows; U; Windows NT 6.1; rv:2.2) Gecko/20110201");
	writeRequestCookies(oCon);

	responseCode = oCon.getResponseCode();

	if ((responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
		responseCode == HttpURLConnection.HTTP_MOVED_TEMP) &&
		!sUrl.equals(oCon.getHeaderField("Location"))) {
      HttpRequest oMoved = new HttpRequest(oCon.getHeaderField("Location"), oUrl, "GET", null);
      readResponseCookies(oCon);
      oMoved.setCookies(getCookies());	  
	  oRetVal = oMoved.get();
	  sUrl = oMoved.url();
	  oCon.disconnect();
	} else {
      readResponseCookies(oCon);
	  InputStream oStm = oCon.getInputStream();
	  if (oStm!=null) {
	    sEncoding = oCon.getContentEncoding();
	    if (sEncoding==null) {
	  	  ByteArrayOutputStream oBya = new ByteArrayOutputStream();
	  	  new StreamPipe().between(oStm, oBya);
	      oRetVal = oBya.toByteArray();
	    } else {
	  	  int c;
	  	  StringBuffer oDoc = new StringBuffer();
	      Reader oRdr = new InputStreamReader(oStm, sEncoding);
	      while ((c=oRdr.read())!=-1) {
	        oDoc.append((char) c);
	      } // wend
	      oRdr.close();
	      oRetVal = oDoc.toString();
	    }
	    oStm.close();
	  } // fi (oStm!=null)
	  if (responseCode!=HttpURLConnection.HTTP_OK &&
	      responseCode!=HttpURLConnection.HTTP_ACCEPTED) {
	    oCon.disconnect();
	    throw new IOException(String.valueOf(responseCode));
	  } else {
	    oCon.disconnect();
	  } // fi (responseCode)
	} // fi

	return oRetVal;
  } // get

  // ------------------------------------------------------------------------

  /**
   * Perform HTTP HEAD request
   * @return int HTTP response code
   * @throws IOException
   * @throws URISyntaxException
   * @throws MalformedURLException
   */
  public int head ()
    throws IOException, URISyntaxException, MalformedURLException {

    oRetVal = null;
    sPageSrc = null;
	sEncoding = null;

	URL oUrl;

	String sParams = "";
	if (aParams!=null) {
	  if (sUrl.indexOf('?')<0) sParams = "?";
	  for (int p=0; p<aParams.length; p++) {
	    sParams += aParams[p].getName()+"="+URLEncoder.encode(aParams[p].getValue(), "ISO8859_1");
	    if (p<aParams.length-1) sParams += "&";
	  } // next
	} // fi
    
	if (null==oReferUrl)
	  oUrl = new URL(sUrl+sParams);
	else
	  oUrl = new URL(oReferUrl, sUrl+sParams);

    HttpURLConnection oCon = (HttpURLConnection) oUrl.openConnection();
		
    oCon.setUseCaches(false);
    oCon.setInstanceFollowRedirects(false);
	oCon.setRequestMethod("HEAD");

	responseCode = oCon.getResponseCode();

	if (responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
		responseCode == HttpURLConnection.HTTP_MOVED_TEMP) {
      HttpRequest oMoved = new HttpRequest(oCon.getHeaderField("Location"), oUrl, "HEAD", null);
	  oMoved.head();
	  sUrl = oMoved.url();
	} 

	oCon.disconnect();

	return responseCode;
  } // head

  // ------------------------------------------------------------------------

  /**
   * Get response code from last GET, POST or HEAD request
   * @return int
   */
  public int responseCode() {
    return responseCode;
  }

  // ------------------------------------------------------------------------

  /**
   * Get response as String
   * @return String
   * @throws IOException
   * @throws UnsupportedEncodingException
   * @throws URISyntaxException
   */
  public String src() throws IOException,UnsupportedEncodingException,URISyntaxException {


    if (sPageSrc==null) {
	  Perl5Matcher oMatcher = new Perl5Matcher();
      Perl5Compiler oCompiler = new Perl5Compiler();
	  if (oRetVal==null) get();

      sPageSrc = null;
    
      if (oRetVal!=null) {
	    String sRcl = oRetVal.getClass().getName();
        if (sRcl.equals("[B")) {
	      sPageSrc = new String((byte[]) oRetVal, sEncoding==null ? "ASCII" : sEncoding);
		  try {
            if (oMatcher.contains(sPageSrc, oCompiler.compile("content=[\"']text/\\w+;\\s*charset=((_|-|\\d|\\w)+)[\"']",Perl5Compiler.CASE_INSENSITIVE_MASK)) ||
                oMatcher.contains(sPageSrc, oCompiler.compile("<\\?xml version=\"1\\.0\" encoding=\"((_|-|\\d|\\w)+)\"\\?>",Perl5Compiler.CASE_INSENSITIVE_MASK))
               ) {
			  sEncoding = oMatcher.getMatch().group(1);
              sPageSrc = new String((byte[]) oRetVal, sEncoding);
            } else {
              if (null==sEncoding) sEncoding = "ASCII";
            }
		  } catch (MalformedPatternException neverthrown) { }
        } else if (sRcl.equals("java.lang.String")) {
          sPageSrc = (String) oRetVal;
          sEncoding = "UTF8";
        }
      } // fi
    } // fi

    return sPageSrc;
  } // src

  // ------------------------------------------------------------------------

  /**
   * Get response encoding
   * @return String
   * @throws IOException
   * @throws UnsupportedEncodingException
   * @throws URISyntaxException
   */
  public String encoding() throws IOException,UnsupportedEncodingException,URISyntaxException {
    src();
    return sEncoding;
  } // encoding

  // ------------------------------------------------------------------------

  /**
   * Get response HTML document title
   * @return String
   * @throws IOException
   * @throws URISyntaxException
   * @throws MalformedURLException
   * @throws UnsupportedEncodingException
   */
  public String getTitle()
  	throws IOException, URISyntaxException, MalformedURLException, UnsupportedEncodingException {
	
	src();

    String sTxTitle = null;

    if (sPageSrc!=null) {
	  int t = Gadgets.indexOfIgnoreCase(sPageSrc,"<title>",0);
	  if (t>0) {
	    int u = Gadgets.indexOfIgnoreCase(sPageSrc,"</title>",t+7);
		if (u>0) {
		  sTxTitle = Gadgets.HTMLDencode(Gadgets.left(Gadgets.removeChars(sPageSrc.substring(t+7,u).trim(),"\t\n\r"),2000)).trim();
		}
	  }         
    } // fi

    return sTxTitle;
  } // getTitle

  // ------------------------------------------------------------------------

  /**
   * Get response HTML document content language
   * @return String
   * @throws IOException
   * @throws ParserException
   * @throws URISyntaxException
   * @throws MalformedURLException
   * @throws UnsupportedEncodingException
   */
  public String getLanguage()
  	throws IOException, URISyntaxException, MalformedURLException, UnsupportedEncodingException, ParserException {

	src();
	
    String sLanguage = null;

	if (sPageSrc!=null) {
	  Perl5Matcher oMatcher = new Perl5Matcher();
      Perl5Compiler oCompiler = new Perl5Compiler();
      try {
        if (oMatcher.contains(sPageSrc, oCompiler.compile("<html\\s+lang=[\"']?(\\w\\w)[\"']?>",Perl5Compiler.CASE_INSENSITIVE_MASK))) {              
          sLanguage = oMatcher.getMatch().group(1);
        } else if (oMatcher.contains(sPageSrc, oCompiler.compile("<html\\s+xmlns=\"http://www.w3.org/1999/xhtml\"(?:\\s+xml:lang=\"\\w\\w-\\w\\w\")?\\s+lang=\"(\\w\\w)-\\w\\w\">",Perl5Compiler.CASE_INSENSITIVE_MASK))) {
          sLanguage = oMatcher.getMatch().group(1);
        } else if (oMatcher.contains(sPageSrc, oCompiler.compile("<meta\\s+http-equiv=[\"']?Content-Language[\"']?\\s+content=[\"']?(\\w\\w)[\"']?\\s?/?>",Perl5Compiler.CASE_INSENSITIVE_MASK))) {
          sLanguage = oMatcher.getMatch().group(1);      
        }
      } catch (MalformedPatternException neverthrown) { }
    
      if (null==sLanguage) {
	    TextCategorizer oTxtc = new TextCategorizer();
        if (Gadgets.indexOfIgnoreCase(sPageSrc,"<html")>=0) {
          Parser oPrsr = Parser.createParser(sPageSrc, sEncoding);
          StringBean oStrBn = new StringBean();
          oPrsr.visitAllNodesWith (oStrBn);
          sLanguage = oTxtc.categorize(oStrBn.getStrings());	  
        } else {
          sLanguage = oTxtc.categorize(sPageSrc);
        }
      } // fi
	} // fi

    return sLanguage;
  } // getLanguage()

}