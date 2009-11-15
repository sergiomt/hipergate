<%@ page contentType="image/jpeg" import="java.net.URLDecoder,java.io.IOException,java.io.OutputStream,java.io.File,java.io.FileInputStream,java.io.FileOutputStream,com.sun.image.codec.jpeg.ImageFormatException,com.knowgate.misc.Environment,com.knowgate.hipergate.Image,com.knowgate.debug.DebugFile,com.knowgate.misc.Gadgets,com.knowgate.dataobjs.DB,com.knowgate.dfs.FileSystem" language="java" session="false" contentType="image/jpeg" %><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

  final String sSep = System.getProperty("file.separator");
  final String sApp = nullif(request.getParameter("nm_app"),"Mailwire");
  
  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = request.getParameter("gu_workarea");
  String nm_image = request.getParameter("nm_image");
  String gu_writer = request.getParameter("gu_writer");
  
  String sDefWrkArGet = request.getRequestURI();
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet + "/workareas";

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";
  
  String sSiteRootUrl = request.getRequestURL().substring(0,request.getRequestURL().length()-27);
  String sDocIconsUrl = sSiteRootUrl + "images/images/docicons/";
  
  String sEnvWorkGet	= Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasget", sDefWrkArGet);
  String sEnvWorkPut	= Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasput", sDefWrkArPut);
  
  String sImagesDir, sImagesUrl;
  
  if (null==gu_writer) {
    sImagesDir	= Gadgets.chomp (sEnvWorkPut,sSep) + gu_workarea + sSep + "apps" + sSep + sApp + (sApp.equals("Forum") ? "" : sSep + "data" + sSep + "images");
    sImagesUrl	= Gadgets.chomp (sEnvWorkGet,'/') + gu_workarea + "/apps/"+sApp+"/data/images";
  }
  else {
    sImagesDir	= Gadgets.chomp (sEnvWorkPut,sSep) + gu_workarea + sSep + "apps" + sSep + sApp + (sApp.equals("Forum") ? "" : sSep + gu_writer + sSep + "images");
    sImagesUrl	= Gadgets.chomp (sEnvWorkGet,'/') + gu_workarea + "/apps/"+sApp+"/"+gu_writer+"/images";  
  }
  
  Image oImg;
  byte aThumbBinary[] = null;
  
  if (DebugFile.trace) DebugFile.writeln("<wb_thumbnail: new File(" +  sImagesDir + sSep + "thumbs" + sSep + nm_image + ")");

  FileSystem oFs = new FileSystem();

  String sExt;
  int iDot = nm_image.lastIndexOf('.');
  if (iDot>0 && iDot<nm_image.length()-1)
    sExt = nm_image.substring(iDot+1).toUpperCase();
  else
  	sExt = "";

  if (sExt.equals("BMP") || sExt.equals("GIF") || sExt.equals("JPG") || sExt.equals("JPEG") || sExt.equals("PNG")) {
    
    File oThumbFile = new File(sImagesDir + sSep + "thumbs" + sSep + nm_image.substring(0,nm_image.lastIndexOf('.'))+".jpg");

    if (oThumbFile.exists()) {
      // Si existe el thumbnail pregenerado leerlo del disco y no llamar al bean de generacion
    
      Long lFile = new Long (oThumbFile.length());
      aThumbBinary = new byte[lFile.intValue()];
    
      FileInputStream oInStrm = new FileInputStream(oThumbFile);
      oInStrm.read(aThumbBinary);
      oInStrm.close();
    }
    else {
    
      try {
      
        oImg = new Image(Image.USE_JAI);  
        oImg.put(DB.path_image, sImagesDir + File.separator + nm_image);
        aThumbBinary = oImg.createThumbBitmap(80, 80, 30f);
        oImg = null;
            
        // Grabar a disco la imagen generada
        FileOutputStream oOutStrm = new FileOutputStream(oThumbFile);
        oOutStrm.write(aThumbBinary);
        oOutStrm.close();
      }
      catch (IOException ioe) {
        if (com.knowgate.debug.DebugFile.trace) {
          DebugFile.writeln("<wb_thumbnail: IOException at wb_thumbnail.jsp: " + ioe.getMessage());
          com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", ioe.getMessage());
        }    
        oThumbFile = null;
      }
      catch (IllegalArgumentException iarg) {
        if (com.knowgate.debug.DebugFile.trace) {
          DebugFile.writeln("<wb_thumbnail: IllegalArgumentException at wb_thumbnail.jsp: " + iarg.getMessage());
          com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IllegalArgumentException", iarg.getMessage());
        }    
        oThumbFile = null;
      }
      catch (InterruptedException inte) {
        if (com.knowgate.debug.DebugFile.trace) {
          DebugFile.writeln("<wb_thumbnail: InterruptedException at wb_thumbnail.jsp: " + inte.getMessage());
          com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "InterruptedException", inte.getMessage());
        }    
        oThumbFile = null;
      }
      catch (InstantiationException inse) {
        if (com.knowgate.debug.DebugFile.trace) {
          DebugFile.writeln("<wb_thumbnail: InstantiationException at wb_thumbnail.jsp: " + inse.getMessage());
          com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "InstantiationException", inse.getMessage());
        }
        oThumbFile = null;
      }
      catch (NullPointerException npe) {
        if (com.knowgate.debug.DebugFile.trace) {
          DebugFile.writeln("NullPointerException at wb_thumbnail.jsp: " + npe.getMessage());
          com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NullPointerException", npe.getMessage());
        }
        oThumbFile = null;
      }
      catch (ImageFormatException ife) {
        if (com.knowgate.debug.DebugFile.trace) {
          DebugFile.writeln("ImageFormatException at wb_thumbnail.jsp: " + ife.getMessage());
          com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "ImageFormatException", ife.getMessage());
        }
        oThumbFile = null;
      }
    } // fi (oThumbFile.exists)
    if (null==oThumbFile) return;
    oThumbFile = null;
  } else if (oFs.exists(sDocIconsUrl+sExt+".png")) {
	  aThumbBinary = oFs.readfilebin(sDocIconsUrl+sExt+".png");
  } else {
    aThumbBinary = oFs.readfilebin(sSiteRootUrl+"images/images/webbuilder/nothumb.jpg");
  }

  // Write jpeg bytes throught ServletOutputStream
  out.clear();
  
  if (null!=aThumbBinary) {
    OutputStream oOut = response.getOutputStream();
    oOut.write(aThumbBinary);
    oOut.flush();
  }
  
  if (com.knowgate.debug.DebugFile.trace) {
    com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "", "");
  }
    
  if (true) return; // Do not remove this line or you will get an error "getOutputStream() has already been called for this response"
%>