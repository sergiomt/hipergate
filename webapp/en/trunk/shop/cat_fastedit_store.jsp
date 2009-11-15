<%@ page import="java.io.IOException,java.io.File,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.oreilly.servlet.MultipartRequest,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.workareas.FileSystemWorkArea,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%@ include file="../methods/multipartreqload.jspf" %>
<%
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

  /* Autenticate user cookie */
  //if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = com.knowgate.misc.Gadgets.chomp(sTmpDir,java.io.File.separator);

  String sProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  
  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, "UTF-8");

  String id_domain = oReq.getParameter("id_domain");
  String n_domain = oReq.getParameter("n_domain");
  String gu_workarea = oReq.getParameter("gu_workarea");
  String gu_user = oReq.getParameter("gu_user");
  String gu_category;

  int nu_images = Integer.parseInt(oReq.getParameter("nu_images"));

  FileSystemWorkArea oFS = new FileSystemWorkArea (Environment.getProfile(GlobalDBBind.getProfileName()));

  JDCConnection oConn = null;
  PreparedStatement oUpdt = null, oDlte = null;

  Category oCatg;
  Image oCatImg;

  try {
    oConn = GlobalDBBind.getConnection("cat_fastedit_store");

    oConn.setAutoCommit (false);

    oUpdt = oConn.prepareStatement("UPDATE " + DB.k_cat_labels + " SET " + DB.tr_category + "=?," + DB.de_category + "=? WHERE " + DB.gu_category + "=? AND " + DB.id_language + "=?");
    oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_cat_tree + " WHERE " + DB.gu_child_cat + "=?");

    for (int i=0; i<nu_images; i++) {

      String si = String.valueOf(i);

      gu_category = oReq.getParameter("gu_category" + si);

      if (nullif(oReq.getParameter("delete" + si)).equals("1")) {
	Category.delete (oConn, gu_category);
      }
      else {
        if (gu_category.length()>0) {

	  oCatg = new Category(gu_category);

          oUpdt.setString (1, oReq.getParameter("tr_es" + si).length()==0 ? null : oReq.getParameter("tr_es" + si));
          oUpdt.setString (2, oReq.getParameter("de_es" + si).length()==0 ? null : oReq.getParameter("de_es" + si));
          oUpdt.setString (3, gu_category);
          oUpdt.setString (4, "es");
	  oUpdt.executeUpdate();

          oUpdt.setString (1, oReq.getParameter("tr_en" + si).length()==0 ? null : oReq.getParameter("tr_en" + si));
          oUpdt.setString (2, oReq.getParameter("de_en" + si).length()==0 ? null : oReq.getParameter("de_en" + si));
          oUpdt.setString (3, gu_category);
          oUpdt.setString (4, "en");
	  oUpdt.executeUpdate();

	  oDlte.setString (1, gu_category);
    	  oDlte.executeUpdate();

	  oCatg.setParent (oConn, oReq.getParameter("parent" + si));
	}
	else {
	  String sTr = oReq.getParameter("tr_es" + si);

	  if (sTr.length()==0)
	    sTr = oReq.getParameter("tr_en" + si);

	  if (sTr.length()>0) {
	    oCatg = new Category();
	    oCatg.put (DB.gu_owner, gu_user);
	    oCatg.put (DB.bo_active, (short)1);
	    oCatg.put (DB.nm_category, Category.makeName(oConn, sTr));
	    oCatg.store(oConn);

	    gu_category = oCatg.getString(DB.gu_category);

	    if (oReq.getParameter("tr_es" + String.valueOf(i)).length()>0)
	      CategoryLabel.create (oConn, new Object[]{gu_category, "es", oReq.getParameter("tr_es" + si), null, oReq.getParameter("de_es" + si)});

	    if (oReq.getParameter("tr_en" + String.valueOf(i)).length()>0)
	      CategoryLabel.create (oConn, new Object[]{gu_category, "en", oReq.getParameter("tr_en" + si), null, oReq.getParameter("de_en" + si)});

	    oCatg.setParent (oConn, oReq.getParameter("parent" + si));
	  }
	  else {
	    gu_category = null;
	    oCatg = null;
	  }
	}

	if (null!=gu_category) {

  	  File oTmpFile = oReq.getFile("image" + si);
  	    	  
  	  if (nullif(oReq.getParameter("removeimage" + si)).equals("1") || (oTmpFile!=null)) {

  	    DBSubset oImgSet = new DBSubset (DB.k_x_cat_objs, DB.gu_object, DB.gu_category + "=? AND " + DB.id_class + "=13", 2);
  	    int iImgSet = oImgSet.load(oConn, new Object[]{gu_category});

  	    for (int n=0; n<iImgSet; n++) {
  	      oCatImg = new Image(oConn, oImgSet.getString(0,n));
  	      oCatImg.delete(oConn);
  	    } // next (n)
  	  } // fi (removeimage==1 || image!=null)

  	  if (oTmpFile!=null) {

  	    String sWrkAPath = Environment.getProfilePath(GlobalDBBind.getProfileName(), "workareasput");
  	    String sSubPath = "apps" + File.separator + "Shop" + File.separator + Gadgets.replace(oCatg.getPath(oConn),"/", File.separator);

  	    oFS.mkworkpath (gu_workarea, sSubPath);

  	    oCatImg = new Image(Image.USE_JAI);
  	    oCatImg.put(DB.gu_writer, gu_user);
  	    oCatImg.put(DB.gu_workarea, gu_workarea);
  	    oCatImg.put(DB.nm_image, oTmpFile.getName());
  	    oCatImg.put(DB.tp_image, "category");
  	    oCatImg.put(DB.len_file, new Long(oTmpFile.length()).intValue());
  	    oCatImg.put(DB.path_image, sWrkAPath+gu_workarea+File.separator+sSubPath+File.separator+oTmpFile.getName());
  	    oCatImg.dimensions();
  	    oCatImg.store(oConn);

  	    oFS.move("file://" + sTmpDir+oTmpFile.getName(), sProtocol + sWrkAPath+gu_workarea+File.separator+sSubPath+File.separator+oTmpFile.getName());

	    oCatg.addObject (oConn, oCatImg.getString(DB.gu_image), Image.ClassId, 0, 0);
  	  } // fi (removeimage || oTmpFile)
        } // fi (null!=gu_category)
      } // fi (getParameter("delete")==1)
    } // next

    oDlte.close();
    oUpdt.close();

    oCatg = new Category(oReq.getParameter("top_parent_cat"));
    oCatg.expand(oConn);
    
    oConn.commit();
    oConn.close("cat_fastedit_store");
  }
  catch (SQLException e) {
    if (oDlte!=null) oDlte.close();
    if (oUpdt!=null) oUpdt.close();

    disposeConnection(oConn,"cat_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (IOException e) {
    if (oDlte!=null) oDlte.close();
    if (oUpdt!=null) oUpdt.close();

    disposeConnection(oConn,"cat_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + e.getMessage() + "&resume=_back"));
  }

  if (null==oConn) return;

  oConn = null;

  // Refresh window
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>top.frames[1].document.location.href='shopjtree_f.jsp?gu_shop=" + oReq.getParameter("gu_shop") + "&top_parent_cat=" + oReq.getParameter("top_parent_cat") + "'; window.document.location.href='cat_fastedit.jsp?gu_shop=" + oReq.getParameter("gu_shop") + "&top_parent_cat=" + oReq.getParameter("top_parent_cat") + "';<" + "/SCRIPT" +"></HEAD></HTML>");

%>