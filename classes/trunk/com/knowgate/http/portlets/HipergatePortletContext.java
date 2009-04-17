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

import java.io.InputStream;

import java.net.URL;

import java.util.Set;
import java.util.Hashtable;
import java.util.Properties;
import java.util.Enumeration;

import javax.portlet.PortletContext;
import javax.portlet.PortletRequestDispatcher;

import com.knowgate.debug.*;

/**
 * @author Sergio Montoro Ten
 * @version 0.1
 */

public class HipergatePortletContext implements PortletContext {

  private Hashtable oAttribs;
  private Properties oParams;

  public HipergatePortletContext() {
    oAttribs = new Hashtable();
    oParams = new Properties();
  }

  public Object getAttribute (String sAttributeName) {
    return oAttribs.get(sAttributeName);
  }

  public Enumeration getAttributeNames () {
    return oAttribs.keys();
  }

  public String getInitParameter(String sParameterName) {
    return oParams.getProperty(sParameterName);
  }

  public Enumeration getInitParameterNames() {
    return oParams.keys();
  }

  public int getMajorVersion() {
    return 1;
  }

  public int getMinorVersion() {
    return 0;
  }

  public String getMimeType(String sFile) {
    throw new UnsupportedOperationException("Method getMimeType() not implemented by HipergatePortletContext");
  }

  public PortletRequestDispatcher getNamedDispatcher(String sName) {
    throw new UnsupportedOperationException("Method getNamedDispatcher() not implemented by HipergatePortletContext");
  }

  public PortletRequestDispatcher getRequestDispatcher(String sPath) {
    throw new UnsupportedOperationException("Method getRequestDispatcher() not implemented by HipergatePortletContext");
  }

  public String getPortletContextName() {
    throw new UnsupportedOperationException("Method getPortletContextName() not implemented by HipergatePortletContext");
  }

  public String getRealPath(String sPath) {
    throw new UnsupportedOperationException("Method getRealPath() not implemented by HipergatePortletContext");
  }

  public URL getResource(String sPath) {
    throw new UnsupportedOperationException("Method getResource() not implemented by HipergatePortletContext");
  }

  public Set getResourcePaths (String sPath) {
    throw new UnsupportedOperationException("Method getResourcePaths() not implemented by HipergatePortletContext");
  }

  public InputStream getResourceAsStream(String sPath) {
    throw new UnsupportedOperationException("Method getResourceAsStream() not implemented by HipergatePortletContext");
  }

  public String getServerInfo() {
    return "hipergate Portlet Container Emulator";
  }

  public void log (String sMsg) {
    DebugFile.writeln(sMsg);
  }

  public void log (String sMsg, Throwable oXcpt) {
    DebugFile.writeln(sMsg);
    new ErrorHandler(oXcpt);
  }

  public void removeAttribute (String sName) {
    oAttribs.remove(sName);
  }

  public void setAttribute (String sName, Object oAttr) {
    oAttribs.put(sName, oAttr);
  }
}
