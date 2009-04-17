/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.
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

package com.knowgate.http.portlets;

import java.util.Properties;
import java.util.Locale;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.OutputStream;
import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;

import javax.portlet.PortletURL;
import javax.portlet.RenderResponse;

import com.knowgate.misc.Gadgets;

/**
 * RenderResponse implementation with output to a StringBuffer
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class StringBufferRenderResponse implements RenderResponse {

  private Properties oProps;
  private ByteArrayOutputStream oBuf;
  private PrintWriter oWrt;
  private int iBufSize;
  private String sEncoding;

  public StringBufferRenderResponse (String encoding) {
    sEncoding = encoding;
    iBufSize = 4000;
    oProps = new Properties();
    oBuf = new ByteArrayOutputStream(iBufSize);
    oWrt = new PrintWriter(oBuf);
  }

  public void setProperty(String key, String value) {
    oProps.setProperty (key, value);
  }

  public void addProperty(String key, String value) {
    String sProp = oProps.getProperty(key);

    if (sProp==null)
      oProps.setProperty (key, value);
    else {
      oProps.remove(key);
      oProps.setProperty(key, sProp + ";" + value);
    }
  }

  public String encodeURL (String path) {
    return Gadgets.URLEncode(path);
  }

  public String getContentType () {
    throw new UnsupportedOperationException ("getContentType() not implemented HipergateRenderRequest");
  }

  public PortletURL createRenderURL () {
    throw new UnsupportedOperationException ("createRenderURL() not implemented HipergateRenderRequest");
  }

  public PortletURL createActionURL () {
    throw new UnsupportedOperationException ("createActionURL() not implemented HipergateRenderRequest");
  }

  public String getNamespace () {
    throw new UnsupportedOperationException ("getNamespace() not implemented HipergateRenderRequest");
  }

  public void setTitle(String title) {
    throw new UnsupportedOperationException ("setTitle() not implemented HipergateRenderRequest");
  }

  public void setContentType(String type) {
    throw new UnsupportedOperationException ("setContentType() not implemented HipergateRenderRequest");
  }

   public String getCharacterEncoding() {
     return sEncoding;
   }

   public PrintWriter getWriter() throws IOException {
     return oWrt;
   }

   public Locale getLocale() {
     throw new UnsupportedOperationException ("getLocale() not implemented HipergateRenderRequest");
   }

   public void setBufferSize(int size) {
     throw new UnsupportedOperationException ("setBufferSize() not implemented HipergateRenderRequest");
   }

   public int getBufferSize() {
     return iBufSize;
   }

   public void setCharacterEncoding(String encoding) {
     sEncoding = encoding;
   }

   public void flushBuffer() throws IOException {
     oWrt.flush();
   }

   public void resetBuffer() {
     oBuf.reset();
   }

   public boolean isCommitted() {
     throw new UnsupportedOperationException ("isCommitted() not implemented HipergateRenderRequest");
   }

   public void reset() {
     oBuf.reset();
   }

   public OutputStream getPortletOutputStream() throws IOException {
     return oBuf;
   }

   public String toString() {
     String sRetVal;

     try {
       sRetVal = new String(oBuf.toByteArray(), sEncoding);
     }
     catch (UnsupportedEncodingException uee) {
       sRetVal = new String(oBuf.toByteArray());
     }

     return sRetVal;
   } // toString()
}
