<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.ResultSet,java.sql.PreparedStatement,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Term,com.knowgate.hipergate.Thesauri,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/reqload.jspf" %>
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
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_term = request.getParameter("gu_term");
  String gu_parent = request.getParameter("gu_parent");
  String tx_term = request.getParameter("tx_term");
  String tx_term2 = request.getParameter("tx_term2").length()==0 ? null : request.getParameter("tx_term2");
  String de_term = request.getParameter("de_term").length()==0 ? null : request.getParameter("de_term");
  String id_language = request.getParameter("id_language");
  String id_scope = request.getParameter("id_scope");
  String gu_synonym = request.getParameter("gu_synonym");
    
  Term oTerm;
  Term oPrnt;
  Thesauri oThes;

  JDCConnection oConn = null;
  PreparedStatement oStmt;
  ResultSet oRSet;
  
  boolean bAlreadyExists;
  
  try {
    oConn = GlobalDBBind.getConnection("term_edit_store");
    
    if (gu_term.length()>0) {

      oTerm = new Term();

      loadRequest(oConn, request, oTerm);

      oConn.setAutoCommit (false);

      oTerm.store(oConn);

    }
    else {

      oThes = new Thesauri();

      if (gu_parent.length()==0) {

	oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_thesauri + " WHERE " + DB.id_domain + "=? AND " + DB.tx_term + "=? AND " + DB.id_term + "1 IS NULL");

	oStmt.setInt   (1, Integer.parseInt(id_domain));
	oStmt.setString(2, tx_term);

	oRSet = oStmt.executeQuery();

	bAlreadyExists = oRSet.next();

	oRSet.close();
	oStmt.close();

        oConn.setAutoCommit (false);

	if (bAlreadyExists)
	  throw new SQLException ("Term already exists");

	if (gu_synonym.length()==0)
	  gu_term = oThes.createRootTerm (oConn, tx_term, tx_term2, de_term, id_language, id_scope, Integer.parseInt(id_domain), gu_workarea);
	else
	  gu_term = oThes.createSynonym (oConn, gu_parent, tx_term, tx_term2, de_term);
      }
      else {

	oPrnt = new Term();
	oPrnt.load (oConn, new Object[]{gu_parent});

	if (DebugFile.trace)
	  DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM " + DB.k_thesauri + " WHERE " + DB.id_domain + "=" + id_domain + " AND " + DB.tx_term + "='" + tx_term + "' AND " + DB.id_term + String.valueOf(oPrnt.level()) + " IS NOT NULL AND " + DB.id_term + String.valueOf(oPrnt.level()+1) + " IS NULL)");
	  
	oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_thesauri + " WHERE " + DB.id_domain + "=? AND " + DB.tx_term + "=? AND " + DB.id_term + String.valueOf(oPrnt.level()) + " IS NOT NULL AND " + DB.id_term + String.valueOf(oPrnt.level()+1) + " IS NULL");

	oStmt.setInt   (1, Integer.parseInt(id_domain));
	oStmt.setString(2, tx_term);

	oRSet = oStmt.executeQuery();

	bAlreadyExists = oRSet.next();

	oRSet.close();
	oStmt.close();

        oConn.setAutoCommit (false);

	if (bAlreadyExists)
	  throw new SQLException ("Term already exists");

	if (gu_synonym.length()==0)
  	  gu_term = oThes.createTerm (oConn, gu_parent, tx_term, tx_term2, de_term, id_language, id_scope, Integer.parseInt(id_domain));
	else
	  gu_term = oThes.createSynonym (oConn, gu_parent, tx_term, tx_term2, de_term);

      }
    }

    oConn.commit();
    oConn.close("term_edit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"term_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  GlobalCacheClient.expire("[" + id_domain + "," + gu_workarea + "," + id_scope + ",thesauri]");
  GlobalCacheClient.expire("[" + id_domain + "," + gu_workarea + ",all,thesauri]");
  GlobalCacheClient.expire("[" + id_domain + "," + gu_workarea + ",geozone,thesauri]");
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.parent.frames[0].document.location.reload(true); window.parent.frames[1].document.location.href ='term_edit.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_term=" + gu_term + "';<" + "/SCRIPT" +"></HEAD></HTML>");

%>