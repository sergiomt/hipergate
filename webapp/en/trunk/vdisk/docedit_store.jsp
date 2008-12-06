<%@ page import="java.io.File,java.io.IOException,java.io.FileNotFoundException,java.net.URLDecoder,java.sql.Statement,java.sql.SQLException,java.util.Enumeration,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.workareas.FileSystemWorkArea,com.knowgate.misc.*,com.knowgate.hipergate.*,com.knowgate.ole.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/multipartreqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="summaryinfo.jspf" %><%
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sTempDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTempDir = com.knowgate.misc.Gadgets.chomp(sTempDir,java.io.File.separator);
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sFileProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  String sFileServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");

  int iMaxUpload = Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "134217728"));
  
  MultipartRequest oReq;
    
  try {
    oReq = new MultipartRequest(request, sTempDir, iMaxUpload, "UTF-8");
  }
  catch (IOException e) {
    oReq = null;
    if (request.getContentLength()>=iMaxUpload)
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=File too big&desc=File size exceeds the limit of " + String.valueOf(iMaxUpload/1024) + "Kb&resume=_back"));
    else
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MultipartRequest IOException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  
  if (null==oReq) return;

  int id_domain = Integer.parseInt(getCookie(request, "domainid", ""));
  String id_workarea = getCookie(request,"workarea","");  
  String id_product = oReq.getParameter("id_product");
  String de_product = oReq.getParameter("de_product");
  String nm_product = oReq.getParameter("nm_product");
  String id_language = oReq.getParameter("id_language");
  String id_user = oReq.getParameter("id_user");
  String id_category = oReq.getParameter("id_category");
  String id_previous_cat = oReq.getParameter("id_previous_cat");
  String gu_location = oReq.getParameter("gu_location");  
  String vs_stamp = oReq.getParameter("vs_stamp").trim();
  boolean bKeepCheckedOut = nullif(oReq.getParameter("chk_keepcheckedout")).equals("1");

  Enumeration oFileNames;
  JDCConnection oCon1 = null;
  String sFile = null;
  Product oProd;
  DBSubset oLocs;
  File oTmpFile = null;
  
  String sSep = System.getProperty("file.separator");
  
  String sSubPath = "domains" + sSep + String.valueOf(id_domain) + sSep + "workareas" + sSep + id_workarea + sSep;
    
  ProductLocation oLoca;
  ProductAttribute oAttr = new ProductAttribute();
  ProductKeyword oKeyw = new ProductKeyword();
  
  Category oCatg = new Category(oReq.getParameter("id_category"));

  String sCatPath = null;
  
  Object aProd[] = { id_product };
 
  try { 

    oCon1 = GlobalDBBind.getConnection("docedit_store");

    // *********************
    // Compose Category Path

    sCatPath = oCatg.getPath(oCon1);

    oCon1.setAutoCommit (false);

    if (id_product.length()==0) {
      oProd = new Product();
      loadRequest(oCon1, oReq, oProd);          
		  if (bKeepCheckedOut) oProd.replace(DB.gu_blockedby, id_user);
    }
    else
      {
      oProd = new Product(oCon1, id_product);
      oProd.replace(DB.nm_product, nm_product);
      oProd.replace(DB.de_product, de_product);

      // ****************************************************
      // If it is not a version then erase previous locations
      
      if (vs_stamp.length()==0)
        oProd.eraseLocations(oCon1);
    
      // ******************************************************************
      // Remove product from previous category iff the new one is different 

      if (!id_category.equals(id_previous_cat))
        oProd.removeFromCategory(oCon1, id_previous_cat);

      // ************
      // Set language
     
      if (id_language.length()>0)
        oProd.replace(DB.id_language, id_language);  
      else
        oProd.remove(DB.id_language);         
      }
      // fi (id_product=="")

		  // *******************************
		  // Set check-in / check-out status
		  
		  if (id_user.equals(oProd.getStringNull(DB.gu_blockedby,id_user))) {
		    if (bKeepCheckedOut)
		      oProd.replace(DB.gu_blockedby, id_user);
		    else
		  	  oProd.remove(DB.gu_blockedby);
      }

      // ******************
      // Store Base  Product
  
      oProd.store(oCon1);
    
      // **************************************************
      // Add to Category if different from the previous one
        
    if (!id_category.equals(id_previous_cat) || id_product.length()==0)
      oProd.addToCategory(oCon1, id_category, 0);

    // **************************************************************************
    // Make Category Path under /storage/domains/id_domain/workareas/id_workarea/

    FileSystemWorkArea oFileSys = new FileSystemWorkArea (Environment.getProfile(GlobalDBBind.getProfileName()));

    oFileSys.mkstorpath (id_domain, id_workarea, sCatPath);
      
    if (gu_location.length()==0)
      oLoca = new ProductLocation();
    else
      oLoca = new ProductLocation(oCon1, gu_location);
    
    oLoca.replace (DB.gu_owner, id_user);  
    oLoca.replace (DB.gu_product, oProd.get(DB.gu_product));
    
    if (vs_stamp.length()>0)
      oLoca.replace (DB.vs_stamp, vs_stamp);
        
    oFileNames = oReq.getFileNames();

    // **********************
    // Inspect uploaded files
  
    while (oFileNames.hasMoreElements()) {

      // Get original file name as uploaded from client and store it in sFile
      sFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
      
      if (sFile!=null) {
        oTmpFile = new File (sTempDir + sFile);

        oLoca.setPath  (sFileProtocol, sFileServer, sStorage + sSubPath + sCatPath, sFile, sFile);
        oLoca.setLength(oTmpFile.length());
        oLoca.replace  (DB.id_cont_type, oLoca.getContainerType());

    	// ***************************
        // Get OLE Document Properties
        
        SummaryInfo(oCon1, oProd.getString(DB.gu_product), oLoca, oAttr, oKeyw, sTempDir+sFile);

    	// *******************************
        // Actually store product location
        
        oLoca.store(oCon1);

    	// ******************************************************
        // If this is a new version then set it as the active one

    	if (vs_stamp.length()>0 && gu_location.length()==0) {
    	
          Statement oStmt = oCon1.createStatement();
          oStmt.executeUpdate("UPDATE " + DB.k_prod_locats +
                              " SET " + DB.status + "=3 WHERE " +
                              DB.gu_product + "='" + id_product +
                              "' AND " + DB.gu_location + "<>'" + oLoca.getString(DB.gu_location) + "'");
          oStmt.close();

        } // fi (vs_stamp && !gu_location)

    	  // *****************************************
        // Copy file from temp directory to storage
        
        if (sFileProtocol.equalsIgnoreCase("ftp://"))          
          oLoca.upload(oCon1, oFileSys, "file://" + sTempDir, sFile, sFileProtocol + sFileServer + sStorage + sSubPath + sCatPath, sFile);
	      else          
          oLoca.upload(oCon1, oFileSys, "file://" + sTempDir, sFile, sFileProtocol + sStorage + sSubPath + sCatPath, sFile);

        // Clear properties for next file
	
        gu_location = oLoca.getString(DB.gu_location);
        oLoca.remove(DB.gu_location);
        oLoca.remove(DB.pg_prod_locat);

        oTmpFile.delete();
    	  oTmpFile = null;
      } // fi (sFile)    

    } // wend(oFileNames.hasMoreElements())
  
    DBAudit.log (oCon1, Product.ClassId, "NPRO", id_user, oProd.getString(DB.gu_product), gu_location, 0, 0, nm_product, null);
    
    oCon1.commit();  
    oCon1.close("docedit_store");
    oFileSys = null;
  }  
  catch (NumberFormatException nfe) {
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("docedit_store");      
  	oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + nfe.getMessage() + "&resume=_back"));
  }
  catch (SQLException sqle) {
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("docedit_store");      
  	oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + sqle.getMessage() + "&resume=_back"));
  }
  catch (FileNotFoundException fnf) {
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("docedit_store");      
  	oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFoundException&desc=" + fnf.getMessage() + "&resume=_back"));
  }
  catch (IOException ioe) {
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("docedit_store");      
  	oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + ioe.getMessage() + "&resume=_back"));
  }
  /*
  catch (Exception xcpt) {
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("docedit_store");      
  	oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + xcpt.getMessage() + "&resume=_back"));
  }
  */
  finally {
    if (null!=oTmpFile)
      oTmpFile.delete();
    oTmpFile = null;
  }

  if (null==oCon1) return;
    
  oCon1 = null;
  
  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.opener.location.reload();window.close();</SCRIPT></HEAD></HTML>");
%>
