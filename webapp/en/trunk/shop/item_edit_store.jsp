<%@ page import="com.oreilly.servlet.MultipartRequest,java.io.IOException,java.io.File,java.net.URLDecoder,java.sql.Statement,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dfs.FileSystem,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/multipartreqload.jspf" %><%@ include file="../methods/multipartcustomattrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 

  final int ATTACHMENT_OFFSET = 6;

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sTempDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTempDir = Gadgets.chomp(sTempDir,java.io.File.separator);

  String sWrkAPut = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasput", sDefWrkArPut);
  String sFileProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  String sFileServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  // String sWebServer = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver");
  
  MultipartRequest oReq = null;
  
  int iMaxUpload = Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "10485760"));
  
  try {
    oReq = new MultipartRequest(request, sTempDir, iMaxUpload, "UTF-8");
  }
  catch (IOException e) {
    oReq = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Archivos demasiado grandes&desc=La longuitud total de los archivos subidos excede el maximo permitido de " + String.valueOf(iMaxUpload/1024) + "Kb&resume=_back"));
  }
  
  if (null==oReq) return;
      
  String id_domain = oReq.getParameter("id_domain");
  String n_domain = oReq.getParameter("n_domain");
  String gu_workarea = oReq.getParameter("gu_workarea");
  String id_user = oReq.getParameter("id_user");
  String gu_product = nullif(oReq.getParameter("gu_product"));
  Integer od_position = new Integer(oReq.getParameter("od_position").length()>0 ? oReq.getParameter("od_position") : "0");  
  String lst_attribs = nullif(oReq.getParameter("lst_attribs"));
  String pg_location;
  
  String sDefWrkArGet = request.getRequestURI();
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet + "/workareas";

  String sOpCode = gu_product.length()>0 ? "NITM" : "MITM";
  String sPath, sDeLocation;
  String sWebPath = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasget", sDefWrkArGet) + "/" + oReq.getParameter("gu_workarea") + "/apps/Shop/" + oReq.getParameter("nm_shop") + "/";
  boolean bAutoThumb = nullif(oReq.getParameter("autothumb")).equals("1");
  
  FileSystem oFileSys;
  Shop oShp;
  Product oItm = new Product();
  ProductLocation oLoc;
  Image oImg;
  File oUploadedFile;
  Statement oStmt=null;
  JDCConnection oConn = GlobalDBBind.getConnection("item_edit_store");  
  
  try {
  
    oShp = new Shop(oConn, oReq.getParameter("gu_shop"));

    sPath = sWrkAPut + File.separator + gu_workarea + File.separator + "apps" + File.separator + "Shop" + File.separator + oShp.getString(DB.nm_shop) + File.separator;
    
    oStmt = oConn.createStatement();

    // *********************************************************************
    // Load common fields of the product and store on DB
    
    loadRequest(oConn, oReq, oItm);
    
    oItm.replace(DB.gu_owner, id_user);
    
    if (null==request.getParameter("is_tax_included")) oItm.replace(DB.is_tax_included, (short)0);
    
    oConn.setAutoCommit (false);
    
    oItm.store(oConn);

    // *********************************************************************
    // Add product to selected category and create a blank row in k_prod_attr
    
    if (gu_product.length()!=0) {
      if (!oReq.getParameter("gu_previous_category").equals(oReq.getParameter("gu_category")) ||
          od_position.compareTo(oItm.getPosition(oConn, oReq.getParameter("gu_previous_category")))!=0) {
        oItm.removeFromCategory(oConn, oReq.getParameter("gu_previous_category"));
        oItm.addToCategory(oConn, oReq.getParameter("gu_category"), od_position.intValue());
      }
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_prod_attr + " WHERE " + DB.gu_product + "='" + gu_product + "')");
      oStmt.executeUpdate("DELETE FROM " + DB.k_prod_attr + " WHERE " + DB.gu_product + "='" + gu_product + "'");
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(INSERT INTO " + DB.k_prod_attr + " (" + DB.gu_product + ") VALUES ('" + gu_product + "'))");
      oStmt.executeUpdate("INSERT INTO " + DB.k_prod_attr + " (" + DB.gu_product + ") VALUES ('" + gu_product + "')");
    }
    else {
      oItm.addToCategory(oConn, oReq.getParameter("gu_category"), od_position.intValue());
    }

    // *********************************************************************
    // Update fixed attributes values
        
    if (lst_attribs.length()>0) {
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_prod_attr + " SET " + lst_attribs + " WHERE " + DB.gu_product + "='" + oItm.getString(DB.gu_product) + "')");
      oStmt.executeUpdate("UPDATE " + DB.k_prod_attr + " SET " + lst_attribs + " WHERE " + DB.gu_product + "='" + oItm.getString(DB.gu_product) + "'");
    }
    
    // *********************************************************************
    // Store user defined fields
          
    storeAttributes (oReq, GlobalCacheClient, oConn, DB.k_prod_attrs, gu_workarea, oItm.getString(DB.gu_product));

    // *********************************************************************
    // Update values for each warehouse location
    
    for (int l=1; l<=5; l++) {
      pg_location = String.valueOf(l);
      
      if (oReq.getParameter("de_prod_locat" + pg_location).length()==0 && oReq.getParameter("gu_location" + pg_location).length()!=0) {
	if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_prod_locats + " WHERE " + DB.gu_location + "='" + oReq.getParameter("gu_location" + pg_location) + "')");
        oStmt.execute("DELETE FROM " + DB.k_prod_locats + " WHERE " + DB.gu_location + "='" + oReq.getParameter("gu_location" + pg_location) + "'");
      }      
      else if (oReq.getParameter("de_prod_locat" + pg_location).length()>0) {
      
        oLoc = new ProductLocation();
        if (oReq.getParameter("gu_location" + pg_location).length()>0)
          oLoc.put(DB.gu_location, oReq.getParameter("gu_location" + pg_location));
        oLoc.put(DB.gu_product, oItm.getString(DB.gu_product));
        oLoc.put(DB.gu_owner, gu_workarea);
        oLoc.put(DB.pg_prod_locat, l);
        oLoc.put(DB.id_cont_type, 100);
        oLoc.put(DB.id_prod_type, "LNK");
        oLoc.put(DB.len_file, 0);
        oLoc.put(DB.xprotocol, "ware://");
        oLoc.put(DB.xhost, "warehouse");
        oLoc.put(DB.de_prod_locat, oReq.getParameter("de_prod_locat" + pg_location));
        if (oReq.getParameter("nu_current_stock" + pg_location).length()>0)
          oLoc.put(DB.nu_current_stock, new Float(oReq.getParameter("nu_current_stock" + pg_location)));
        if (oReq.getParameter("nu_min_stock" + pg_location).length()>0)
          oLoc.put(DB.nu_min_stock, new Float(oReq.getParameter("nu_min_stock" + pg_location)));        
        if (oReq.getParameter("tag_prod_locat" + pg_location).length()>0)
          oLoc.put(DB.tag_prod_locat, oReq.getParameter("tag_prod_locat" + pg_location));
        oLoc.store(oConn);
      }              
    } // next

    oStmt.close();
    oStmt = null;

    oFileSys = new FileSystem(Environment.getProfile(GlobalDBBind.getProfileName()));

    // *****************************************
    // Copy files related to the product
    
    oUploadedFile = oReq.getFile("attachment1");
    
    if ((nullif(oReq.getParameter("del_attachment1")).equals("1") || oUploadedFile!=null) && oReq.getParameter("gu_attachment1").length()>0)
      new ProductLocation(oConn, oReq.getParameter("gu_attachment1")).delete(oConn);

    if (oUploadedFile!=null) {
      if (oItm.getString(DB.nm_product).length()>80)
        sDeLocation = oItm.getString(DB.nm_product).substring(0,80) +  " attached file 1";
      else
        sDeLocation = oItm.getString(DB.nm_product) +  " attached file 1";
        
      oLoc = new ProductLocation();

      oLoc.put(DB.gu_product, oItm.getString(DB.gu_product));
      oLoc.put(DB.gu_owner, id_user);
      oLoc.put(DB.pg_prod_locat, ATTACHMENT_OFFSET);
      oLoc.put(DB.de_prod_locat, sDeLocation);
      oLoc.setPath  (sFileProtocol, sFileServer, sPath, oUploadedFile.getName(), oUploadedFile.getName());
      oLoc.setLength(new Long(oUploadedFile.length()).intValue());
      oLoc.store(oConn);
      
      if (sFileProtocol.startsWith("file:")) {
        oFileSys.mkdirs(sFileProtocol + sPath);
        oLoc.upload(oConn, oFileSys, "file://" + sTempDir, oUploadedFile.getName(), sFileProtocol + sPath, oUploadedFile.getName());
      }
      else {
        oFileSys.mkdirs(sFileProtocol + sFileServer + sPath);
        oLoc.upload(oConn, oFileSys, "file://" + sTempDir, oUploadedFile.getName(), sFileProtocol + sFileServer + sPath, oUploadedFile.getName());
      }
    } // fi (getFile("attachment1"))

    // -----------------------------------------
    
    oUploadedFile = oReq.getFile("attachment2");
    
    if ((nullif(oReq.getParameter("del_attachment2")).equals("1") || oUploadedFile!=null) && oReq.getParameter("gu_attachment2").length()>0)
      new ProductLocation(oConn, oReq.getParameter("gu_attachment2")).delete(oConn);

    if (oUploadedFile!=null) {
      if (oItm.getString(DB.nm_product).length()>80)
        sDeLocation = oItm.getString(DB.nm_product).substring(0,80) +  " attached file 2";
      else
        sDeLocation = oItm.getString(DB.nm_product) +  " attached file 2";
        
      oLoc = new ProductLocation();

      oLoc.put(DB.gu_product, oItm.getString(DB.gu_product));
      oLoc.put(DB.gu_owner, id_user);
      oLoc.put(DB.pg_prod_locat, ATTACHMENT_OFFSET+1);
      oLoc.put(DB.de_prod_locat, sDeLocation);
      oLoc.setPath  (sFileProtocol, sFileServer, sPath, oUploadedFile.getName(), oUploadedFile.getName());
      oLoc.setLength(new Long(oUploadedFile.length()).intValue());
      oLoc.store(oConn);

      if (sFileProtocol.startsWith("file:")) {
        oFileSys.mkdirs(sFileProtocol + sPath);
        oLoc.upload(oConn, oFileSys, "file://" + sTempDir, oUploadedFile.getName(), sFileProtocol + sPath, oUploadedFile.getName());
      }
      else {
        oFileSys.mkdirs(sFileProtocol + sFileServer + sPath);
        oLoc.upload(oConn, oFileSys, "file://" + sTempDir, oUploadedFile.getName(), sFileProtocol + sFileServer + sPath, oUploadedFile.getName());
      }
    } // fi (getFile("attachment2"))
    	
    // ***************************************************************************
    // Copiar las imágenes a su ubicación final y apuntar la entradas en la bb.dd.
    
    // Primero borrar las imágenes anteriores que tengan su checkbox de eliminación marcada
    
    if ((nullif(oReq.getParameter("del_thumbview")).equals("1") || oReq.getFile("thumbview")!=null) && oReq.getParameter("gu_thumbview").length()>0)
      new Image(oConn, oReq.getParameter("gu_thumbview")).delete(oConn);

    if ((nullif(oReq.getParameter("del_normalview")).equals("1") || oReq.getFile("normalview")!=null) && oReq.getParameter("gu_normalview").length()>0)
      new Image(oConn, oReq.getParameter("gu_normalview")).delete(oConn);

    if ((nullif(oReq.getParameter("del_frontview")).equals("1") || oReq.getFile("frontview")!=null) && oReq.getParameter("gu_frontview").length()>0)
      new Image(oConn, oReq.getParameter("gu_frontview")).delete(oConn);

    if ((nullif(oReq.getParameter("del_rearview")).equals("1") || oReq.getFile("rearview")!=null) && oReq.getParameter("gu_rearview").length()>0)
      new Image(oConn, oReq.getParameter("gu_rearview")).delete(oConn);
        
    if ((oReq.getFileCount()>0) || nullif(oReq.getParameter("autothumb")).equals("1")) {

      if (sFileProtocol.startsWith("file:"))
        oFileSys.mkdirs(sFileProtocol + sPath);
      else
        oFileSys.mkdirs(sFileProtocol + sFileServer + sPath);
      
      oImg = new Image(Image.USE_JAI);
      oImg.put(DB.gu_writer, id_user);
      oImg.put(DB.gu_workarea, gu_workarea);
      oImg.put(DB.gu_product, oItm.getString(DB.gu_product));

      String aImageTypes[] = { "normalview", "thumbview", "frontview", "rearview" };
      
      DebugFile.writeln("autothumb=" + String.valueOf(bAutoThumb));
      
      for (int i=0; i<aImageTypes.length; i++) {
        
        if (aImageTypes[i].equals("thumbview") && bAutoThumb)
          oUploadedFile = new File(sTempDir + oItm.getString(DB.gu_product) + "_thumbview.jpg");
        else
          oUploadedFile = oReq.getFile(aImageTypes[i]);
          
        if (oUploadedFile!=null) {
	
	  if (oReq.getParameter("gu_" + aImageTypes[i]).length()>0)
      	    oImg.replace(DB.gu_image, oReq.getParameter("gu_" + aImageTypes[i]));
	  else
      	    oImg.remove(DB.gu_image);
      	  
      	  String sImgName, sImgExt;
      	  
      	  if (bAutoThumb && aImageTypes[i].equals("thumbview")) {
      	    sImgName = "tn_" + oReq.getOriginalFileName("normalview");
      	  } else {
      	  	sImgName = oReq.getOriginalFileName(aImageTypes[i]);
					}

					if (sImgName.length()>30) {
					  sImgExt = sImgName.substring(sImgName.lastIndexOf("."));
					  sImgName = sImgName.substring(0, 29-sImgExt.length()) + sImgExt;
					}

	        oImg.replace(DB.nm_image, sImgName);					
          oImg.replace(DB.path_image, sPath + oItm.getString(DB.gu_product) + "_" + aImageTypes[i] + "." + oUploadedFile.getName().substring(oUploadedFile.getName().lastIndexOf(".")+1).toLowerCase());
          oImg.replace(DB.tp_image, aImageTypes[i]);

	  oFileSys.copy("file://" + sTempDir + oUploadedFile.getName(), "file://" + sPath + oItm.getString(DB.gu_product) + "_" + aImageTypes[i] + "." + oImg.getImageType());

	  oImg.store(oConn);

          oImg.remove(DB.id_img_type);
          oImg.remove(DB.len_file);
          oImg.remove(DB.dm_width);
          oImg.remove(DB.dm_height);
          oImg.remove(DB.nm_image);          

    	  // Generar automáticamente el thumbnail llamando al bean en el servidor de aplicaciones
    	  if ( bAutoThumb && aImageTypes[i].equals("normalview") ) {

      	    int iThumbDimensions = Integer.parseInt(oReq.getParameter("dm_thumbsize"));
	    
      	    oImg.createThumbFile(sTempDir + oItm.getString(DB.gu_product) + "_thumbview.jpg", iThumbDimensions, iThumbDimensions, 30f);
                            
          } // fi (autothumb==1 && normalview)
        } // fi (oUploadedFile)  
      } // next
    } // fi (getFileCount()>0)
    
    oFileSys = null;

    // *****************************
    // Store an Audit row in DB
        
    DBAudit.log(oConn, Product.ClassId, sOpCode, id_user, oItm.getString(DB.gu_product), oReq.getParameter("gu_category"), 0, 0, oItm.getString(DB.nm_product), null);
        
    oConn.commit();
    oConn.close("item_edit_store");
  }
  catch (SQLException e) {  
    if (oStmt!=null)
      oStmt.close();
      
    disposeConnection(oConn,"item_edit_store");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (IOException e) {  
    if (oStmt!=null)
      oStmt.close();
      
    disposeConnection(oConn,"item_edit_store");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + e.getMessage() + "&resume=_back"));
  }

  catch (InstantiationException e) {  
    if (oStmt!=null)
      oStmt.close();
      
    disposeConnection(oConn,"item_edit_store");
      oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=InstantiationException&desc=" + e.getMessage() + "&resume=_back"));
  }

  catch (NoClassDefFoundError e) {  
    if (oStmt!=null)
      oStmt.close();
      
    disposeConnection(oConn,"item_edit_store");
      oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NoClassDefFoundError&desc=" + e.getMessage() + "&resume=_back"));
  }

  catch (UnsatisfiedLinkError e) {  
    if (oStmt!=null)
      oStmt.close();
      
    disposeConnection(oConn,"item_edit_store");
      oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=UnsatisfiedLinkError&desc=" + e.getMessage() + "&resume=_back"));
  }

  /* Java 1.4 only
  catch (java.awt.HeadlessException e) {  
    if (oStmt!=null)
      oStmt.close();
      
    disposeConnection(oConn,"item_edit_store");
      oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=HeadlessException&desc=" + e.getMessage() + "&resume=_back"));
  }
  */

  catch (ArrayIndexOutOfBoundsException e) {  
    if (oStmt!=null)
      oStmt.close();
      
    disposeConnection(oConn,"item_edit_store");
      oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=" + e.getMessage() + "&resume=_back"));
  }
    
  catch (NullPointerException e) {  
    if (oStmt!=null)
      oStmt.close();
      
    disposeConnection(oConn,"item_edit_store");
      oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (Exception e) {  
    if (oStmt!=null)
      oStmt.close();
      
    disposeConnection(oConn,"item_edit_store");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
      
  finally {
     if (bAutoThumb)
       oUploadedFile = new File(sTempDir + oItm.getString(DB.gu_product) + "_thumbview.jpg");
     else
       oUploadedFile = oReq.getFile("thumbview");
    
    if (oUploadedFile!=null) try { if (oUploadedFile.exists()) oUploadedFile.delete(); } catch (Exception e) { }

    oUploadedFile = oReq.getFile("normalview");
    if (oUploadedFile!=null) try { oUploadedFile.delete(); } catch (Exception e) { }

    oUploadedFile = oReq.getFile("frontview");
    if (oUploadedFile!=null) try { oUploadedFile.delete(); } catch (Exception e) { }

    oUploadedFile = oReq.getFile("rearview");
    if (oUploadedFile!=null) try { oUploadedFile.delete(); } catch (Exception e) { }    
  }
  
  if (null==oConn) return;
  
  oShp  = null;
  oItm  = null;
  oConn = null;
    
  // Refresh parent and close this window
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>