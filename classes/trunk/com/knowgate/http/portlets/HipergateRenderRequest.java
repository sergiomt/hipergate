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

import java.util.Hashtable;
import java.util.Enumeration;
import java.util.Properties;
import java.util.Map;
import java.util.Locale;

import java.security.Principal;

import javax.portlet.*;

import javax.servlet.http.HttpServletRequest;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class HipergateRenderRequest implements RenderRequest {

  private HttpServletRequest oSrvltReq;
  private Properties oProps;
  private Hashtable oAttrs;
  private WindowState oWinState;

  public HipergateRenderRequest(HttpServletRequest oServletReq) {
    oAttrs = new Hashtable();
    oProps = new Properties();
    oSrvltReq = oServletReq;
    oWinState = WindowState.NORMAL;
  }

  public boolean isWindowStateAllowed(WindowState state) {
    return state == WindowState.NORMAL;
  }

  public boolean isPortletModeAllowed(PortletMode mode) {
    return mode == PortletMode.VIEW;
  }

  public PortletMode getPortletMode () {
    return PortletMode.VIEW;
  }

  public WindowState getWindowState () {
    return oWinState;
  }

  public void setWindowState (String state) {
    if (state.equalsIgnoreCase("NORMAL"))
      oWinState = WindowState.NORMAL;
    else if (state.equalsIgnoreCase("MINIMIZED"))
      oWinState = WindowState.MINIMIZED;
    else if (state.equalsIgnoreCase("MAXIMIZED"))
      oWinState = WindowState.MAXIMIZED;
  }

  public void setWindowState (WindowState state) {
    oWinState = state;
  }

  public PortletPreferences getPreferences () {
    return null;
  }

  public PortletSession getPortletSession () {
    return null;
  }

  public PortletSession getPortletSession (boolean create) {
    return null;
  }

  public String getProperty(String name) {
    return oProps.getProperty(name);
  }

  public void setProperty(String name, String value) {
    oProps.put(name, value);
  }

  public void setProperties(Properties props) {
    oProps = props;
  }

  public Enumeration getProperties(String name) {
    return (Enumeration) oProps;
  }

  public Enumeration getPropertyNames() {
    return oProps.keys();
  }

  public PortalContext getPortalContext() {
    return null;

  }

  public String getAuthType() {
    return null;
  }

  public String getContextPath() {
    return oSrvltReq.getContextPath();
  }

  public String getRemoteUser() {
    return oSrvltReq.getRemoteUser();
  }

  public Principal getUserPrincipal() {
    return oSrvltReq.getUserPrincipal();
  }

  public boolean isUserInRole(String role) {
    return false;
  }

  public Object getAttribute(String name) {
    return oAttrs.get(name);
  }

  public Enumeration getAttributeNames() {
    return oAttrs.keys();
  }

  public String getParameter(String name) {
    return oSrvltReq.getParameter(name);
  }

  public Enumeration getParameterNames() {
    return oSrvltReq.getParameterNames();
  }

  public String[] getParameterValues(String name) {
    return oSrvltReq.getParameterValues(name);
  }

  public Map getParameterMap() {
    return oSrvltReq.getParameterMap();
  }

  public boolean isSecure() {
    return false;
  }

  public void setAttribute(String name, Object o) {
    if (oAttrs.containsKey(name)) oAttrs.remove(name);
    oAttrs.put(name, o);
  }

  public void removeAttribute(String name) {
    oAttrs.remove(name);
  }

  public String getRequestedSessionId() {
    return oSrvltReq.getRequestedSessionId();
  }

  public boolean isRequestedSessionIdValid() {
    return oSrvltReq.isRequestedSessionIdValid();
  }

  public String getResponseContentType() {
    throw new UnsupportedOperationException ("getResponseContentType() not implemented at HipergateRenderRequest");
  }

  public Enumeration getResponseContentTypes() {
    throw new UnsupportedOperationException ("getResponseContentTypes() not implemented HipergateRenderRequest");
  }

  public Locale getLocale() {
    return oSrvltReq.getLocale();
  }

  public Enumeration getLocales() {
    return oSrvltReq.getLocales();
  }

  public String getScheme() {
    return oSrvltReq.getScheme();
  }

  public String getServerName() {
    return oSrvltReq.getServerName();
  }

  public int getServerPort() {
    return oSrvltReq.getServerPort();
  }
}
