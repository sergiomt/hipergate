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

import javax.portlet.PortletURL;
import javax.portlet.RenderResponse;

import javax.servlet.http.HttpServletResponse;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class HipergateRenderResponse implements RenderResponse {

  private Properties oProps;
  private HttpServletResponse oSrvltRes;

  public HipergateRenderResponse (HttpServletResponse oServletRes) {
    oProps = new Properties();
    oSrvltRes = oServletRes;
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
    return oSrvltRes.encodeURL(path);
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
    oSrvltRes.setContentType(type);
  }

   public String getCharacterEncoding() {
     return oSrvltRes.getCharacterEncoding();
   }

   public PrintWriter getWriter() throws IOException {
     return oSrvltRes.getWriter();
   }

   public Locale getLocale() {
     return oSrvltRes.getLocale();
   }

   public void setBufferSize(int size) {
    oSrvltRes.setBufferSize(size);
   }

   public int getBufferSize() {
     return oSrvltRes.getBufferSize();
   }

   public void flushBuffer() throws IOException {
     oSrvltRes.flushBuffer();
   }

   public void resetBuffer() {
     oSrvltRes.resetBuffer();
   }

   public boolean isCommitted() {
     return oSrvltRes.isCommitted();
   }

   public void reset() {
     oSrvltRes.reset();
   }

   public OutputStream getPortletOutputStream() throws IOException {
     return oSrvltRes.getOutputStream();
   }

}
