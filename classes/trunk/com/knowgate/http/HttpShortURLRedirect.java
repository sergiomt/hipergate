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

package com.knowgate.http;

import java.io.IOException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.knowgate.debug.DebugFile;
import com.knowgate.storage.DataSource;

import com.knowgate.clocial.StorageManager;
import com.knowgate.clocial.Redirect;

public class HttpShortURLRedirect extends HttpServlet {

  public static StorageManager oStMan;

  // ---------------------------------------------------------------------------

  public void init() throws ServletException {
    ServletConfig sconfig = getServletConfig();

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HttpShortURLRedirect.init()");
      DebugFile.incIdent();
    }

	 try {
	   oStMan = new StorageManager();
	 } catch (Exception xcpt) {	   
	   throw new ServletException(xcpt.getClass().getName()+" "+xcpt.getMessage(),xcpt);
	 } 

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HttpShortURLRedirect.init()");
    }
  } // init

  // ---------------------------------------------------------------------------

  public void destroy() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin HttpShortURLRedirect.destroy()");
      DebugFile.incIdent();
    }
    
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HttpShortURLRedirect.destroy()");
    }
  } // destroy

  // ---------------------------------------------------------------------------
  
  public void doGet(HttpServletRequest request, HttpServletResponse response)
     throws ServletException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HttpShortURLRedirect.doGet()");
      DebugFile.incIdent();
    }

     String sTargetURL;
     String sShortURL = request.getRequestURL().toString() + (request.getQueryString()==null ? "" : "?"+request.getQueryString());

    if (DebugFile.trace) DebugFile.writeln("short url "+sShortURL);
     
	 DataSource oDts = null;
	 
	 try {
	   oDts = oStMan.getDataSource();
	   sTargetURL = Redirect.resolve(oDts, sShortURL, request.getRemoteAddr());
       if (DebugFile.trace) DebugFile.writeln("target url "+sTargetURL);
	   if (null==sTargetURL)
	     response.sendError(HttpServletResponse.SC_NOT_FOUND, "The requested URL to be redirected "+sShortURL+" was not found");
       else
       	response.sendRedirect(sTargetURL);
	 } catch (Exception xcpt) {	   
	   try {
	     response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, xcpt.getClass().getName()+" "+xcpt.getMessage());
	   } catch (IOException ioe) {
	     throw new ServletException(ioe.getClass().getName()+" "+ioe.getMessage(),ioe);
	   }
	 } finally {
	   if (oDts!=null) { try { oStMan.free(oDts); } catch (Exception ignore) {} }
	 }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HttpShortURLRedirect.doGet()");
    }
  } // doGet

  // ---------------------------------------------------------------------------

}
