<%@ page import="java.io.IOException,java.io.FileNotFoundException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Category,com.knowgate.forums.NewsGroup,com.knowgate.forums.NewsGroupJournal,com.knowgate.lucene.Indexer" language="java" session="false" %>
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
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_owner = request.getParameter("gu_owner");
  String id_user = getCookie (request, "userid", null);
  
  short id_doc_status = Short.parseShort(nullif(request.getParameter("id_doc_status"),"0"));
  short is_active = Short.parseShort(nullif(request.getParameter("is_active"),"0"));
  
  String id_category = request.getParameter("id_category").length()==0 ? null : request.getParameter("id_category");
  String n_category = nullif(request.getParameter("n_category")).trim().toUpperCase();
  
  String id_parent_cat = request.getParameter("id_parent_cat");
  String id_parent_old = request.getParameter("id_parent_old");
  String nm_icon1 = request.getParameter("nm_icon1");
  String nm_icon2 = request.getParameter("nm_icon2");
  String names_subset = request.getParameter("names_subset");
  String de_newsgrp = request.getParameter("de_newsgrp");
  String tx_journal = request.getParameter("tx_journal");
  boolean bo_binaries = (nullif(request.getParameter("bo_binaries"),"0").equals("0") ? false : true);
  boolean bo_rebuild = (nullif(request.getParameter("bo_rebuild"),"0").equals("0") ? false : true);

  String sCatg = "";
  ACLDomain oDom;
  NewsGroup oForumsGrp;
  
  JDCConnection oCon1 = GlobalDBBind.getConnection("forumedit_store");
  Statement oStm1;
           
  try {
    
    if (n_category.length()==0)
      n_category = Category.makeName(oCon1, request.getParameter("tr1st")).replace(' ','_');
    
    oDom = new ACLDomain(oCon1, id_domain);
      
    oCon1.setAutoCommit (false);    
    
    if (id_category==null) {
      sCatg = NewsGroup.store(oCon1, id_domain, gu_workarea, null, id_parent_cat, Category.makeName(oCon1, request.getParameter("tr1st")),
      												is_active, id_doc_status, gu_owner, nm_icon1, nm_icon2, bo_binaries, de_newsgrp, tx_journal);
      
      if (bo_rebuild)
        oForumsGrp = new NewsGroup(oCon1, sCatg);
      else
        oForumsGrp = new NewsGroup(sCatg);

      oForumsGrp.setGroupPermissions(oCon1, oDom.getString(DB.gu_admins), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
      
      oForumsGrp.setUserPermissions (oCon1, oDom.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
	      
      if (!gu_owner.equals(oDom.getString(DB.gu_owner))) oForumsGrp.setUserPermissions (oCon1, gu_owner, ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);

      oForumsGrp.storeLabels(oCon1, names_subset, "¨", "`");
            
    }
    else {        
      sCatg = NewsGroup.store(oCon1, id_domain, gu_workarea, id_category, id_parent_cat,
      												Category.makeName(oCon1, request.getParameter("tr1st")), is_active, id_doc_status, gu_owner, nm_icon1, nm_icon2,
      												bo_binaries, de_newsgrp, tx_journal);

      oStm1 = oCon1.createStatement();
      oStm1.execute("DELETE FROM " + DB.k_cat_labels + " WHERE " + DB.gu_category + "='" + sCatg + "'");
      oStm1.close();
            
      if (bo_rebuild)
        oForumsGrp = new NewsGroup(oCon1, sCatg);
      else
        oForumsGrp = new NewsGroup(sCatg);
	      
      oForumsGrp.storeLabels(oCon1, names_subset, "¨", "`");
    }
        
    oCon1.commit();

    oCon1.setAutoCommit (true);

    com.knowgate.http.portlets.HipergatePortletConfig.touch(oCon1, id_user, "com.knowgate.http.portlets.RecentPostsTab", gu_workarea);

		if (bo_rebuild) {
		  NewsGroupJournal oJour = oForumsGrp.getJournal();
		  if (null!=oJour) {
		    oJour.rebuild(oCon1, true);
		  }
		  if (null!=GlobalDBBind.getProperty("luceneindex")) {
  			try {
  			  Indexer.optimize(GlobalDBBind.getProperties(), "k_newsmsgs", gu_workarea);
  			} catch (FileNotFoundException ignore) { }
  	  } // fi
		} // fi

	  oCon1.close("forumedit_store");

    oCon1 = null;
    
    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.parent.document.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");
  }
  catch (SQLException d) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        if (!oCon1.getAutoCommit()) oCon1.rollback();
        oCon1.close("forumedit_store");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+d.getClass().getName()+"&desc=" + d.getMessage() + "&resume=_back"));    
  }      
%>
