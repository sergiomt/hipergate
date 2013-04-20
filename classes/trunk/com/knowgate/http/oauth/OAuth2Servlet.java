/*
  Copyright (C) 2011  Know Gate S.L. All rights reserved.

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

package com.knowgate.http.oauth;

import java.io.IOException;
import java.io.FileInputStream;

import java.sql.ResultSet;
import java.sql.PreparedStatement;

import java.util.Properties;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.UnavailableException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.knowgate.acl.ACL;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.jdc.JDCConnectionPool;
import com.knowgate.storage.StorageException;
import com.knowgate.training.Curriculum;

public class OAuth2Servlet extends HttpServlet {

  private static long serialVersionUID = 700l;
  
  private String jdbcDriverClassName;
  private String jdbcURL;
  private String dbUserName;
  private String dbUserPassword;

  private static OAuthAccessCache oAccCache = null;
  private static JDCConnectionPool oConnPool;

 // -----------------------------------------------------------

  private String nil(String s) {
    return s==null ? "" : s;
  }

 // -----------------------------------------------------------

 private boolean isVoid(String sParam) {
   if (null==sParam)
     return true;
   else
     return (sParam.length()==0);
 }

 /**
  * <p>Initialize Servlet Parameters</p>
  * Take Database Driver, Conenction URL and User from /WEB-INF/web.xml.<br>
  * If any parameter is not found then look it up at hipergate.cnf Properties
  * file using Environment singleton.
  * @throws ServletException
  * @throws UnavailableException If jdbcDriverClassName parameter is not found
  * and driver property at hipergate.cnf is not found or if jdbcURL parameter
  * is not found and dburl property at hipergate.cnf is not found.
  * @see com.knowgate.misc.Environment
  */
 public void init() throws ServletException {

   ServletConfig config = getServletConfig();

   jdbcDriverClassName = config.getInitParameter("jdbcDriverClassName");

   jdbcURL = config.getInitParameter("jdbcURL");
   dbUserName = config.getInitParameter("dbUserName");
   dbUserPassword = config.getInitParameter("dbUserPassword");

   if (isVoid(jdbcDriverClassName) || isVoid(jdbcURL) || isVoid(dbUserName) || isVoid(dbUserPassword)) {
     Properties env = new Properties();
     try {
       FileInputStream fin = new FileInputStream("/etc/hipergate.cnf");
       env.load(fin);
       fin.close();
     } catch (IOException ioe) {}

     if (isVoid(jdbcDriverClassName))
       jdbcDriverClassName = env.getProperty("driver");

     if (isVoid(jdbcURL))
       jdbcURL = env.getProperty("dburl");

     if (isVoid(dbUserName))
       dbUserName = env.getProperty("dbuser");

     if (isVoid(dbUserPassword))
       dbUserPassword = env.getProperty("dbpassword");
   }

   if (jdbcDriverClassName == null || jdbcURL == null)
     throw new UnavailableException("Init params missing");
     
   try {
   	if (null==oAccCache) oAccCache = new OAuthAccessCache (jdbcURL,dbUserName,dbUserPassword);
   	if (null==oConnPool) oConnPool = new JDCConnectionPool(jdbcURL,dbUserName,dbUserPassword);
   } catch (StorageException e) {
   	 throw new ServletException(e.getMessage(), e);
   }
 } // init()

  // -----------------------------------------------------------

  public void destroy() {
    if (null==oAccCache) { oAccCache.close(); oAccCache=null; }
    if (null==oConnPool) { oConnPool.close(); oConnPool=null; }
  }
  
  // -----------------------------------------------------------

  private void redirect(HttpServletResponse oResponse, int iResponseCode, String sRedirectUri, String sData)
  	throws IOException {
	oResponse.sendRedirect(sRedirectUri+(sRedirectUri.indexOf('?')>0 ? "&" : "?")+sData);
  }  

 // -----------------------------------------------------------

  private void reply(HttpServletResponse oResponse, String sContentType, String sData)
  	throws IOException  {
	oResponse.setStatus(HttpServletResponse.SC_OK);
    oResponse.setCharacterEncoding("UTF-8");
    oResponse.setContentType(sContentType);
    oResponse.getOutputStream().write(sData.getBytes("UTF-8"));
  }  

 // -----------------------------------------------------------

  public void doGet(HttpServletRequest request, HttpServletResponse response)
    throws IOException, ServletException {

	OAuthAccess oAa;
	
    String grant_type = nil(request.getParameter("grant_type"));
    String response_type = nil(request.getParameter("response_type"));
    String access_token = nil(request.getParameter("access_token"));
    String refresh_token = nil(request.getParameter("refresh_token"));    
    String client_id = nil(request.getParameter("client_id"));
    String resource_type = nil(request.getParameter("resource_type"));
    String resource_id = nil(request.getParameter("resource_id"));
    String resource_data = nil(request.getParameter("resource_data"));
    String redirect_uri = nil(request.getParameter("redirect_uri"));
    String client_secret = nil(request.getParameter("client_secret"));
    String scope = nil(request.getParameter("scope"));
    String state = nil(request.getParameter("state"));
    String username = nil(request.getParameter("username"));
    String password = nil(request.getParameter("password"));
    String code = nil(request.getParameter("code"));

	if (response_type.length()==0 && grant_type.length()==0) {
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Parameter+response_type+or+grant_type+is+required&state="+response.encodeURL(state));	  
	  return;
	}
	if (response_type.length()>0 && grant_type.length()>0) {
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Either+response_type+or+grant_type+is+required+but+not+both&state="+response.encodeURL(state));
	  return;
	}
	if (response_type.length()>0 && !response_type.equals("code") && !response_type.equals("token") && !response_type.equals("code_and_token") && !response_type.equals("resource")) {
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Parameter+response_type+is+must+be+code+token+or+code_and_token&state="+response.encodeURL(state));
	  return;
	}
	if (response_type.length()>0 && access_token.length()==0 && (response_type.equals("token") || response_type.equals("code_and_token"))) {
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Parameter+access_token+is+required&state="+response.encodeURL(state));
	  return;
	}
	if (client_id.length()==0) {
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Parameter+client_id+is+required&state="+response.encodeURL(state));
	  return;
	}
	if (redirect_uri.length()==0) {
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Parameter+redirect_uri+is+required&state="+response.encodeURL(state));
	  return;
	}

	if (response_type.equals("token") || response_type.equals("code_and_token")) {
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=unsupported_response_type&error_description=Unsupported+response+type"+response_type+"&state="+response.encodeURL(state));
	  return;
	}
	
	if (response_type.equals("code")) {
	  oAa = new OAuthAccess(OAuthAccess.TYPE_CODE, client_id, redirect_uri);
	  oAccCache.put(oAa);
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "token_type=code&code="+oAa.getValue()+"&state="+response.encodeURL(state)+"&expires_in="+String.valueOf(oAa.expiresInSecs()));
	  return;
	}

	if (response_type.equals("resource")) {
	  if (resource_type.length()==0) {
	    redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Resource+type+is+required&state="+response.encodeURL(state));
	    return;
	  }
	  oAa = oAccCache.get(access_token);
	  if (null==oAa) {
	    redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=access_denied&error_description=Invalid+or+expired+session+for+access_token+"+access_token+"&state="+response.encodeURL(state));
	    return;
	  }
	  oAa.refresh();
	  JDCConnection oConn = null;
	  String sXML;
	  try {

	    if (resource_type.equalsIgnoreCase("Curriculum")) {
	      String gu_contact = null;
	  	  oConn = oConnPool.getConnection("OAuth2Servlet");

	      PreparedStatement oStmt = oConn.prepareStatement("SELECT gu_contact FROM k_contacts WHERE gu_contact=? OR (tx_nickname=? AND gu_workarea=?)");
	      oStmt.setString(1, resource_id);
	      oStmt.setString(2, resource_id);
	      oStmt.setString(3, scope);
	      ResultSet oRSet = oStmt.executeQuery();
	      if (oRSet.next()) {
	      	gu_contact = oRSet.getString(1);
	      }
	      oRSet.close();
	      oStmt.close();

		  if (gu_contact==null) {
	        redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Contact+"+resource_id+"+not+found+at+scope+"+scope+"&state="+response.encodeURL(state));
		  } else {
	        sXML = Curriculum.forContact(oConn, gu_contact);
	        reply(response, "text/xml", "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"+sXML);
		  }
	      oConn.close("OAuth2Servlet");
	      oConn=null;
		  return;	  
	    } else {	    
	      redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Invalid+resource+type&state="+response.encodeURL(state));
	      return;
	    } 
	  } catch (Exception xcpt) {
	  	if (oConn!=null) { try { if (!oConn.isClosed()) oConn.close("OAuth2Servlet"); } catch (Exception ignore) {} }
	  	throw new ServletException(xcpt.getMessage(), xcpt);
	  }
	} // fi (response_type=="resource") {
	
	if (grant_type.equals("authorization_code") || grant_type.equals("password")) {
	  if (code.length()==0) {
	    redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Parameter+code+is+required&state="+response.encodeURL(state));
	    return;
	  }
	  oAa = oAccCache.get(code);
	  if (null==oAa) {
	    redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=access_denied&error_description=Invalid+or+expired+code+"+code+"&state="+response.encodeURL(state));
	    return;
	  }
	  if (!client_id.equals(oAa.getClient())) {
	    redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_client&error_description=Invalid+client_id+for+code&state="+response.encodeURL(state));
	    return;
	  }
	} else if (grant_type.length()>0) {
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Unsupported+grant_type&state="+response.encodeURL(state));
	  return;
	}

	if (grant_type.equals("password")) {
	  short iAuth = oAccCache.authenticate(username, password, scope);
	  
	  if (iAuth<0) {
	    redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=access_denied&error_description="+ACL.getErrorMessage(iAuth).replace(' ','+')+"&state="+response.encodeURL(state));
	    return;
	  }
	  
	  oAa = new OAuthAccess(OAuthAccess.TYPE_TOKEN, client_id, redirect_uri);
	  oAccCache.put(oAa);
	  	  
	  reply(response, "application/json", "{\"access_token\":\""+oAa.getValue()+"\",\"token_type\":\"token\",\"expires_in\":\""+String.valueOf(oAa.expiresInSecs())+"\",\"refresh_token\":\""+oAa.getRefresh()+"\",\"scope\":\"\",\"state\":\""+response.encodeURL(state)+"\"}");
	  return;
	}

	if (grant_type.equals("refresh_token")) {
	  oAa = oAccCache.refresh(refresh_token);
	  if (null==oAa) {
	    redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=access_denied&error_description=Invalid+refresh+token&state="+response.encodeURL(state));
	    return;
	  } else {
	    reply(response, "application/json", "{\"access_token\":\""+oAa.getValue()+"\",\"token_type\":\"token\",\"expires_in\":\""+String.valueOf(oAa.expiresInSecs())+"\",\"refresh_token\":\""+oAa.getRefresh()+"\",\"scope\":\"\",\"state\":\""+response.encodeURL(state)+"\"}");
	  	return;
	  }	  
	}

	redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Bad+parameters&state="+response.encodeURL(state));	
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response)
    throws IOException, ServletException {
	
	String response_type = nil(request.getParameter("response_type"));
	String access_token = nil(request.getParameter("access_token"));
	String refresh_token = nil(request.getParameter("refresh_token"));    
	String client_id = nil(request.getParameter("client_id"));
	String resource_type = nil(request.getParameter("resource_type"));
	String resource_id = nil(request.getParameter("resource_id"));
	String resource_data = nil(request.getParameter("resource_data"));
	String redirect_uri = nil(request.getParameter("redirect_uri"));
	String scope = nil(request.getParameter("scope"));
	String state = nil(request.getParameter("state"));
	String code = nil(request.getParameter("code"));

	OAuthAccess oAa;
	
	if (response_type.equals("status")) {
	  if (!resource_type.equalsIgnoreCase("Curriculum")) {
	    redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Invalid+Resource+type&state="+response.encodeURL(state));
		return;
	  }
      oAa = oAccCache.get(access_token);
	  if (null==oAa) {
		redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=access_denied&error_description=Invalid+or+expired+session+for+access_token+"+access_token+"&state="+response.encodeURL(state));
		return;
	  }
	  oAa.refresh();
	  JDCConnection oConn = null;
	  try {
	    if (resource_type.equalsIgnoreCase("Curriculum")) {
	    }
	  } catch (Exception xcpt) {
		if (oConn!=null) { try { if (!oConn.isClosed()) oConn.close("OAuth2Servlet"); } catch (Exception ignore) {} }
		throw new ServletException(xcpt.getMessage(), xcpt);
	  }
	} else {
	  redirect(response, HttpServletResponse.SC_FOUND, redirect_uri, "error=invalid_request&error_description=Parameter+response_type+must+be+status&state="+response.encodeURL(state));
	  return;
	}
  }
      
  public static OAuthAccessCache getCache() {
  	return oAccCache;
  }
}
