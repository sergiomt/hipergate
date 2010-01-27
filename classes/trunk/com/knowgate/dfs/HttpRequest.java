package com.knowgate.dfs;

import java.io.Reader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.ByteArrayOutputStream;

import java.net.URL;
import java.net.URLEncoder;
import java.net.HttpURLConnection;
import java.net.URISyntaxException;
import java.net.MalformedURLException;

import com.knowgate.misc.NameValuePair;

public class HttpRequest extends Thread {

  private String sUrl;
  private URL oReferUrl;
  private String sMethod;
  private NameValuePair[] aParams;
  private Object oRetVal;

  // ------------------------------------------------------------------------

  public HttpRequest(String sUrl) {
    this.sUrl = sUrl;
    this.oReferUrl = null;
    this.sMethod = "GET";
    this.aParams = null;
  }	

  // ------------------------------------------------------------------------

  public HttpRequest(String sUrl, URL oReferUrl, String sMethod, NameValuePair[] aParams) {
    this.sUrl = sUrl;
    this.oReferUrl = oReferUrl;
    this.sMethod = sMethod;
    this.aParams = aParams;
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

	int responseCode = oCon.getResponseCode();

	if (responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
		responseCode == HttpURLConnection.HTTP_MOVED_TEMP) {

      HttpRequest oMoved = new HttpRequest(oCon.getHeaderField("Location"), oUrl, "POST", aParams);	  
	  oRetVal = oMoved.post();
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

	int responseCode = oCon.getResponseCode();

	if (responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
		responseCode == HttpURLConnection.HTTP_MOVED_TEMP) {
      HttpRequest oMoved = new HttpRequest(oCon.getHeaderField("Location"), oUrl, "GET", null);
	  oRetVal = oMoved.get();	  
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

}

