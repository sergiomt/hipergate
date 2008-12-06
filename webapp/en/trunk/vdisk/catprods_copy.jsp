<%@ page import="java.io.File,java.lang.System,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.dfs.FileSystem,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  final int COPY=1, MOVE=2;

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  int tp_operation = Integer.parseInt(request.getParameter("tp_operation"));  
  String id_category = request.getParameter("id_category");
  String id_target_cat = request.getParameter("id_target_cat");
  String tr_target_cat = request.getParameter("tr_target_cat");
  String id_workarea = getCookie(request,"workarea","");  
  String id_user = getCookie (request, "userid", null);
  int id_domain = Integer.parseInt(getCookie(request, "domainid", ""));

  int iChkCount = Integer.parseInt(request.getParameter("chkcount"));

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sFileProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  String sFileServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  String sCatPath,sOriginPath,sTargetPath;
  String sFile;
  int iContainerType;
    
  JDCConnection oCon1 = null;
  String sProductId;
  Category oCatOrigin = new Category(id_category);
  Category oCatTarget = new Category(id_target_cat);
  
  Product oProd = new Product();
  int iOriginMask, iTargetMask;

  ProductLocation oLoca;
  DBSubset oLocats;
  int iLocats;

  FileSystem oFileSys = new FileSystem(Environment.getProfile(GlobalDBBind.getProfileName()));

  oCon1 = GlobalDBBind.getConnection("catprods_copy");
  
  try {
    oCon1.setAutoCommit (false);
    
    iOriginMask = oCatOrigin.getUserPermissions(oCon1,id_user);
    iTargetMask = oCatTarget.getUserPermissions(oCon1,id_user);
    
    sCatPath = sStorage + "domains" + File.separator + String.valueOf(id_domain) + File.separator + "workareas" + File.separator + id_workarea + File.separator + oCatTarget.getPath(oCon1);
    
    if ((tp_operation==MOVE) && ((iOriginMask&ACL.PERMISSION_DELETE)==0)) {
      out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.parent.catadmin.location.href='../common/errmsg.jsp?title=' + escape('Security restriction') + '&desc=' + escape('You are not authorized to delete elements from this category') + '&resume=_back';</SCRIPT></HEAD></HTML>");
    }
    else if (((iTargetMask&ACL.PERMISSION_ADD)==0)) {
      out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.parent.catadmin.location.href='../common/errmsg.jsp?title=' + escape('Security restriction') + '&desc=' + escape('You are not authorized for copying files into category&nbsp;" + tr_target_cat + "') + '&resume=_back';</SCRIPT></HEAD></HTML>");
    }
    else {              
      oFileSys.mkdirs(sFileProtocol + (sFileProtocol.equals("file://") ? "" : sFileServer) + sCatPath);

      for (int c=0; c<iChkCount; c++) {
        sProductId = nullif(request.getParameter("chkbox" + String.valueOf(c)));

        if (sProductId.length()>0) {                    
	  if (MOVE==tp_operation) {
	    oProd.replace(DB.gu_product, sProductId);
	    if (!id_category.equals(id_target_cat)) {
	      oProd.addToCategory(oCon1, id_target_cat, 1);
	      oProd.removeFromCategory(oCon1, id_category);
	    }

	    oLocats = oProd.getLocations(oCon1);
	    iLocats = oLocats.getRowCount();

      	    sTargetPath = Gadgets.chomp(sFileProtocol+(sFileProtocol.equals("file://") ? "" : sFileServer)+sCatPath, File.separator);

	    for (int l=0;l<iLocats; l++) {
	      oLoca = new ProductLocation(oCon1, oLocats.getString(0, l));
      	      iContainerType = oLoca.getInt(DB.id_cont_type);
      	      
      	      if (iContainerType==ProductLocation.CONTAINER_FILE || iContainerType==ProductLocation.CONTAINER_FTP) {
      	        sFile = oLocats.getString(DB.xfile,l);

      	        sOriginPath = Gadgets.chomp(oLoca.getPath(), File.separator);

      	        oLoca.setPath (sFileProtocol, sFileServer, sCatPath, sFile, oLocats.getString(DB.xoriginalfile,l));
      	        oLoca.store(oCon1);
      	              	              	        
      	        if (!oFileSys.move(sOriginPath+sFile, sTargetPath+sFile)) {
      	          throw new IOException("Unable to move "+sFile+" from "+sOriginPath+" to "+sTargetPath);
      	        }
	      } else {
      	        oLoca.store(oCon1);	      
	      }
	    } // next()
	    
            DBAudit.log (oCon1, Product.ClassId, "MPRO", id_user, oProd.getString(DB.gu_product), id_target_cat, 0, getClientIP(request), id_category, null);
          }
	  else {
	    oProd = new Product(oCon1, sProductId);
	    oLocats = oProd.getLocations(oCon1);
	    iLocats = oLocats.getRowCount();
	    
	    oProd.remove(DB.gu_product);
	    oProd.store(oCon1);
	    
	    oProd.addToCategory(oCon1, id_target_cat, 1);
	    
	    sProductId = oProd.getString(DB.gu_product);

      	    sTargetPath = sFileProtocol+(sFileProtocol.equals("file://") ? "" : sFileServer)+sCatPath;
      	    if (!sTargetPath.endsWith("/")) sTargetPath += "/";
	    	    
	    for (int l=0;l<iLocats; l++) {
      	      
      	      oLoca = new ProductLocation(oCon1, oLocats.getString(0, l));
      	      oLoca.replace(DB.gu_product, sProductId);
      	      oLoca.remove(DB.gu_location);
      	      
      	      iContainerType = oLoca.getInt(DB.id_cont_type);
      	      
      	      if (iContainerType==ProductLocation.CONTAINER_FILE || iContainerType==ProductLocation.CONTAINER_FTP) {
      	        sFile = oLocats.getString(DB.xfile,l);

      	        sOriginPath = oLoca.getPath();
      	        if (!sOriginPath.endsWith("/")) sOriginPath += "/";

      	        oLoca.setPath (sFileProtocol, sFileServer, sCatPath, sFile, oLocats.getString(DB.xoriginalfile,l));
      	        oLoca.store(oCon1);
   	        
      	        if (!oFileSys.copy(sOriginPath+sFile, sTargetPath+sFile)) {
      	          throw new IOException("Unable to copy "+sFile+" from "+sOriginPath+" to "+sTargetPath);
      	        }
	      }
	      else
      	        oLoca.store(oCon1);
	      	                  	    
	      DBAudit.log (oCon1, Product.ClassId, "CPRO", id_user, sProductId, id_target_cat, 0, getClientIP(request), id_category, null);
	    } // next (l)
	  } // fi ()
          oCon1.commit();
        } // fi (sProductId)
      } // next (c)   
    } // fi (ACL.PERMISSION_DELETE)

    oCon1.close("catprods_copy");
    oCon1 = null;
    
    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.parent.catadmin.location.reload();</SCRIPT></HEAD></HTML>");
  }  
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
	oCon1.rollback();
	oCon1.close();
        oCon1 = null;
      }
    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.parent.catadmin.location.href='../common/errmsg.jsp?title=Error&desc=' + escape('" + e.getMessage() + "') + '&resume=_back';</SCRIPT></HEAD></HTML>");
  }      
  catch (IOException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
	oCon1.rollback();
	oCon1.close();
        oCon1 = null;
      }
    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT>window.parent.catadmin.location.href='../common/errmsg.jsp?title=Error&desc=' + escape('" + e.getMessage() + "') + '&resume=_back';</SCRIPT></HEAD></HTML>");
  }        
%>
