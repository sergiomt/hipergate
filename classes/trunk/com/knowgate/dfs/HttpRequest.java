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

import org.apache.oro.text.regex.*;

import com.knowgate.misc.Gadgets;
import com.knowgate.misc.NameValuePair;

public class HttpRequest extends Thread {

  private String sUrl;
  private URL oReferUrl;
  private String sMethod;
  private NameValuePair[] aParams;
  private Object oRetVal;
  private int responseCode; 

  // ------------------------------------------------------------------------

  public HttpRequest(String sUrl) {
    this.sUrl = sUrl;
    this.oReferUrl = null;
    this.sMethod = "GET";
    this.aParams = null;
    this.responseCode=0;
  }	

  // ------------------------------------------------------------------------

  public HttpRequest(String sUrl, URL oReferUrl, String sMethod, NameValuePair[] aParams) {
    this.sUrl = sUrl;
    this.oReferUrl = oReferUrl;
    this.sMethod = sMethod;
    this.aParams = aParams;
    this.responseCode=0;
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

  public Object post ()
    throws IOException, URISyntaxException, MalformedURLException {

    oRetVal = null;

	URL oUrl;
    
	if (null==oReferUrl)
	  oUrl = new URL(sUrl);
	else
	  oUrl = new URL(oReferUrl, sUrl);

	String sParams = "";
	if (aParams!=null) {
	  for (int p=0; p<aParams.length; p++) {
	    sParams += aParams[p].getName()+"="+URLEncoder.encode(aParams[p].getValue(), "UTF-8");
	    if (p<aParams.length-1) sParams += "&";
	  } // next
	} // fi

    HttpURLConnection oCon = (HttpURLConnection) oUrl.openConnection();
		
    oCon.setUseCaches(false);
    oCon.setFollowRedirects(false);
    oCon.setInstanceFollowRedirects(false);
    oCon.setDoInput (true);

    oCon.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
	oCon.setRequestProperty("Content-Length", String.valueOf(sParams.getBytes().length));
	oCon.setFixedLengthStreamingMode(sParams.getBytes().length);
    oCon.setDoOutput(true);
	oCon.setRequestMethod("POST");
	OutputStreamWriter oWrt = new OutputStreamWriter(oCon.getOutputStream());
    oWrt.write(sParams);
    oWrt.flush();
    oWrt.close();

	responseCode = oCon.getResponseCode();

	if (responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
		responseCode == HttpURLConnection.HTTP_MOVED_TEMP) {

      HttpRequest oMoved = new HttpRequest(oCon.getHeaderField("Location"), oUrl, "POST", aParams);	  
	  oRetVal = oMoved.post();
	  sUrl = oMoved.url();
	} else if (responseCode == HttpURLConnection.HTTP_OK ||
	    responseCode == HttpURLConnection.HTTP_ACCEPTED) {
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

  public Object get ()
    throws IOException, URISyntaxException, MalformedURLException {

    oRetVal = null;

	URL oUrl;
    
	if (null==oReferUrl)
	  oUrl = new URL(sUrl);
	else
	  oUrl = new URL(oReferUrl, sUrl);

    HttpURLConnection oCon = (HttpURLConnection) oUrl.openConnection();
		
    oCon.setUseCaches(false);
    oCon.setFollowRedirects(false);
    oCon.setInstanceFollowRedirects(false);
    oCon.setDoInput (true);

    oCon.setDoOutput(true);
	oCon.setRequestMethod("GET");
	OutputStreamWriter oWrt = new OutputStreamWriter(oCon.getOutputStream());
    oWrt.flush();
    oWrt.close();

	responseCode = oCon.getResponseCode();

	if (responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
		responseCode == HttpURLConnection.HTTP_MOVED_TEMP) {
      HttpRequest oMoved = new HttpRequest(oCon.getHeaderField("Location"), oUrl, "GET", null);
	  oRetVal = oMoved.get();
	  sUrl = oMoved.url();
	} else if (responseCode == HttpURLConnection.HTTP_OK ||
	    responseCode == HttpURLConnection.HTTP_ACCEPTED) {
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

  public int responseCode() {
    return responseCode;
  }

  // ------------------------------------------------------------------------

  public String getTitle()
  	throws IOException, URISyntaxException, MalformedURLException,
  	UnsupportedEncodingException {

    String sTxTitle = null;
    String sPageSrc = null;
    Object oPageSrc = get();
    
    if (oPageSrc!=null) {
	  String sRcl = oPageSrc.getClass().getName();
      if (sRcl.equals("[B")) {
	      sPageSrc = new String((byte[]) oPageSrc,"ASCII");
	      Perl5Matcher oMatcher = new Perl5Matcher();
          Perl5Compiler oCompiler = new Perl5Compiler();
		  try {
            if (oMatcher.contains(sPageSrc, oCompiler.compile("content=[\"']text/\\w+;\\s*charset=((_|-|\\d|\\w)+)[\"']",Perl5Compiler.CASE_INSENSITIVE_MASK))) {              
              sPageSrc = new String((byte[]) oPageSrc,oMatcher.getMatch().group(1));
            }
		  } catch (MalformedPatternException neverthrown) { }
      } else if (sRcl.equals("java.lang.String")) {
        sPageSrc = (String) oPageSrc;
      }
    } // fi    			
    if (sPageSrc!=null) {
	  int t = Gadgets.indexOfIgnoreCase(sPageSrc,"<title>",0);
	  if (t>0) {
	    int u = Gadgets.indexOfIgnoreCase(sPageSrc,"</title>",t+7);
		if (u>0) {
		  sTxTitle = Gadgets.HTMLDencode(Gadgets.left(Gadgets.removeChars(sPageSrc.substring(t+7,u).trim(),"\t\n\r"),2000)).trim();
		}
	  }         
    }
    return sTxTitle;
  } // getTitle

}

