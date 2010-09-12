<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,java.sql.ResultSet,java.util.Enumeration,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.workareas.FileSystemWorkArea,com.knowgate.crm.Attachment,com.knowgate.hipergate.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.oreilly.servlet.MultipartRequest" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/multipartreqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
  sTempDir = Gadgets.chomp(sTempDir,java.io.File.separator);

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sFileProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  String sFileServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  MultipartRequest oReq = null;
    
  try {
    oReq = new MultipartRequest(request, sTempDir, Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "10485760")), "UTF-8");
  }
  catch (IOException ioe) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + ioe.getMessage() + "&resume=_back"));
  }
  if (null==oReq) return;
  
  String id_domain = getCookie(request,"domainid","");
  String id_workarea = getCookie(request,"workarea","");
    
  String id_language = oReq.getParameter("id_language");
  String id_user = oReq.getParameter("id_user");
  String id_product = oReq.getParameter("id_product");
  String pg_product = oReq.getParameter("pg_product");
  String nm_product = oReq.getParameter("nm_product");  
  String de_product = oReq.getParameter("de_product");  
  String gu_contact = oReq.getParameter("gu_contact");
  String gu_location = oReq.getParameter("gu_location");
  String tp_product = oReq.getParameter("type_of");
  String id_format = oReq.getParameter("format");
  
  String nm_legal;
  
  String sSep = System.getProperty("file.separator");
  
  String sWrkAHome = sStorage + "domains" + sSep + id_domain + sSep + "workareas" + sSep + id_workarea + sSep;
  String sCatPath = "apps/Sales/";
  
  Enumeration oFileNames;
  JDCConnection oCon1;
  ResultSet oRSet;
  PreparedStatement oStmt;
  String sFile = null;
  Product oProd;  
  Attachment oAttach;  
  DBSubset oLocs;
  File oTmpFile;
  FileSystemWorkArea oFileSys;
  ProductLocation oLoca;
  ProductAttribute oAttr;
  
  Object aProd[] = { id_product };

  oCon1 = GlobalDBBind.getConnection("attachedit_store");
    
  oCon1.setAutoCommit (false);
  try {
    // Mirar si el contacto está adscrito a alguna compañía y usar el nombre para componer la ruta del archivo

    switch (oCon1.getDataBaseProduct()) {
      case JDCConnection.DBMS_ORACLE:
        oStmt = oCon1.prepareStatement("SELECT k." + DB.nm_legal + " FROM " + DB.k_contacts + " c, " + DB.k_companies + " k WHERE c." + DB.gu_company + "=k." + DB.gu_company + "(+) AND c." + DB.gu_contact + "=? AND c." + DB.gu_company + " IS NOT NULL", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	      break;
      default:
        oStmt = oCon1.prepareStatement("SELECT k." + DB.nm_legal + " FROM " + DB.k_contacts + " c LEFT OUTER JOIN " + DB.k_companies + " k ON c." + DB.gu_company + "=k." + DB.gu_company + " WHERE c." + DB.gu_contact + "=? AND c." + DB.gu_company + " IS NOT NULL", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    }
    
    oStmt.setString(1, gu_contact);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      nm_legal = Gadgets.ASCIIEncode(oRSet.getString(1));
    else
      nm_legal = "_NOCOMPANY";
    oRSet.close();
    oStmt.close();
    
    //Concatenar el nombre de la compañía con el guid del contacto en la ruta del archivo
    sCatPath += nm_legal + "/" + gu_contact + "/";
      
    if (id_product.length()==0) {
      oProd = new Product();
      oAttr = new ProductAttribute();
      if (tp_product.length()>0) oAttr.put("typeof", tp_product);
      if (id_format.length()>0) oAttr.put("format", id_format);
      loadRequest(oCon1, oReq, oProd);
    }
    else
      {
      oProd = new Product(oCon1, id_product);
      oProd.replace(DB.nm_product, nm_product);
      oProd.replace(DB.de_product, de_product);

      oAttr = new ProductAttribute(oCon1, id_product);
      if (tp_product.length()>0) oAttr.replace("typeof", tp_product);
      if (id_format.length()>0) oAttr.replace("format", id_format);

      // Erase previous locations
      oProd.eraseLocations(oCon1);
         
      if (id_language.length()>0)
        oProd.replace(DB.id_language, id_language);  
      else
        oProd.remove(DB.id_language);         
      }
    // fi (id_product=="")
  
    oProd.store(oCon1);
    oAttr.replace(DB.gu_product, oProd.getString(DB.gu_product));
    oAttr.store(oCon1);

    oFileSys = new FileSystemWorkArea(Environment.getProfile(GlobalDBBind.getProfileName()));
    oFileSys.mkstorpath(Integer.parseInt(id_domain), id_workarea, sCatPath);
    
    oLoca = new ProductLocation();
    oLoca.put(DB.gu_owner, id_user);  
    oLoca.put(DB.gu_product, oProd.get(DB.gu_product));   
    
    if (pg_product.length()>0)
      oLoca.put(DB.pg_prod_locat, Integer.parseInt(pg_product));
    
    oFileNames = oReq.getFileNames();
  
    while (oFileNames.hasMoreElements()) {
      // Get original file name as uploaded from client and store it in sFile
      sFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
      
        oLoca.setPath  (sFileProtocol, sFileServer, sWrkAHome + sCatPath, sFile, sFile);
        oLoca.setLength(oFileSys.filelen(sTempDir+"/"+sFile));
      
        // Actually store product location
        oLoca.replace(DB.id_cont_type, oLoca.getContainerType());
        oLoca.store(oCon1);
        
        if (sFileProtocol.equalsIgnoreCase("ftp://"))
          oLoca.upload(oCon1, oFileSys, "file://" + sTempDir, sFile, "ftp://" + sFileServer + sWrkAHome + sCatPath, sFile);
        else
          oLoca.upload(oCon1, oFileSys, "file://" + sTempDir, sFile, sFileProtocol + sWrkAHome + sCatPath, sFile);

        // Store attachment data
        oAttach = new Attachment();
        oAttach.put(DB.gu_contact , gu_contact);
        oAttach.put(DB.gu_product , oProd.getString(DB.gu_product) );
        oAttach.put(DB.gu_location, oLoca.getString(DB.gu_location));        
        oAttach.put(DB.gu_writer, id_user);
        oAttach.store(oCon1);

        oLoca.remove(DB.gu_location);
        oLoca.remove(DB.pg_prod_locat);
    } // wend(oFileNames.hasMoreElements())
            
    oCon1.commit();  
    oCon1.close("attachedit_store");
    oCon1 = null;
  }
  catch (SQLException sqle) {
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("attachedit_store");      
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + sqle.getLocalizedMessage() + "&resume=_back"));
  }
  catch (IOException ioe) {
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("attachedit_store");      
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + ioe.getLocalizedMessage() + "&resume=_back"));
  }
  /*
  catch (NullPointerException npe) {
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("attachedit_store");      
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=NullPointerException&resume=_back"));
  }
  catch (Exception xcpt) {
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("attachedit_store");      
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + xcpt.getMessage() + "&resume=_back"));
  }
  */
  finally {
    oTmpFile = new File (sTempDir + "/" + sFile);
    oTmpFile.delete();
    oTmpFile = null;
  }

  
  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.opener.location.reload();window.close();</SCRIPT></HEAD></HTML>");
%>
