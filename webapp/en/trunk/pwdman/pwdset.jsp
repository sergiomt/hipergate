<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,java.sql.Timestamp,java.sql.Types,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Category" language="java" session="true" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "pwdset";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  boolean bSession = (session.getAttribute("validated")!=null);
      
  String id_user = getCookie (request, "userid", null);
  int id_domain = new Integer(getCookie(request,"domainid","")).intValue();
      
	PreparedStatement oStmt = null;
  JDCConnection oConn = null;
  String sPwd1 = request.getParameter("pwd1");
  String sPwdSign;
  String sCatName = "";
  
  try {
		if (sPwd1.length()<8) throw new SQLException("The length of the password must be of at least 8 characters");

    oConn = GlobalDBBind.getConnection(PAGE_NAME); 
  
    sPwdSign = DBCommand.queryStr(oConn, "SELECT "+DB.tx_pwd_sign+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+id_user+"'");
		
    oConn.setAutoCommit (false);

	  if (bSession) {
	    ACLUser.resetSignature(oConn, id_user, sPwd1);

			oStmt = oConn.prepareStatement("UPDATE "+DB.k_users+" SET "+DB.tx_challenge+"=? WHERE "+DB.gu_user+"=?");
			if (request.getParameter("tx_challenge").length()>0)
			  oStmt.setString(1, request.getParameter("tx_challenge"));
			else
			  oStmt.setNull(1, Types.VARCHAR);
			oStmt.setString(2, id_user);
			oStmt.executeUpdate();
			oStmt.close();
			
      DBAudit.log(oConn, ACLUser.ClassId, "USPW", id_user, id_user, null, 0, 0, null, null);	  
	  }
	  else {
	  	if (sPwdSign==null || sPwd1.equals(sPwdSign)) {
	      ACLUser.resetSignature(oConn, id_user, sPwd1);

			  oStmt = oConn.prepareStatement("UPDATE "+DB.k_users+" SET "+DB.tx_challenge+"=? WHERE "+DB.gu_user+"=?");
			  if (request.getParameter("tx_challenge").length()>0)
			    oStmt.setString(1, request.getParameter("tx_challenge"));
			  else
			    oStmt.setNull(1, Types.VARCHAR);
			  oStmt.setString(2, id_user);
			  oStmt.executeUpdate();
			  oStmt.close();

        DBAudit.log(oConn, ACLUser.ClassId, sPwdSign==null ? "NSPW" : "USPW", id_user, id_user, null, 0, 0, null, null);

			  sCatName = DBCommand.queryStr(oConn, "SELECT d."+DB.nm_domain+",'_'"+",u."+DB.tx_nickname+",'_pwds' FROM "+DB.k_domains+" d,"+DB.k_users+" u WHERE d."+DB.id_domain+"=u."+DB.id_domain+" AND u."+DB.gu_user+"='"+id_user+"'");

				String sPwdsCat = DBCommand.queryStr(oConn, "SELECT "+DB.gu_category+" FROM "+DB.k_categories+" c, " + DB.k_cat_tree+ " t WHERE c."+DB.gu_category+"=t."+DB.gu_child_cat+" AND t."+DB.gu_parent_cat+" IN (SELECT "+DB.gu_category+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+id_user+"') AND c."+DB.nm_category+"='"+sCatName+"'");
				
				if (null==sPwdsCat) {
    			ACLDomain oDom = new ACLDomain(oConn, id_domain);
					
      	  Category oPwdsCat = new Category(Category.create(oConn, new Object[] { DBCommand.queryStr(oConn, "SELECT "+DB.gu_category+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+id_user+"'"),
      	  																		             id_user, sCatName, new Short((short)1), new Integer(1), "folderpwds_16x16.gif", "folderpwds_16x16.gif" }));

    			oPwdsCat.setUserPermissions (oConn, oDom.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
      		oPwdsCat.setUserPermissions ( oConn, id_user, ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_DELETE|ACL.PERMISSION_MODIFY|ACL.PERMISSION_GRANT, (short) 1, (short) 0);

      	  Category oMySites = new Category(Category.create(oConn, new Object[] { oPwdsCat.getString(DB.gu_category), id_user, sCatName + "_mywebs", new Short((short)1), new Integer(1), "folderpwds_16x16.gif", "folderpwds_16x16.gif" }));
    			oMySites.setUserPermissions (oConn, oDom.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
      		oMySites.setUserPermissions ( oConn, id_user, ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_DELETE|ACL.PERMISSION_MODIFY|ACL.PERMISSION_GRANT, (short) 1, (short) 0);
					oMySites.setLabel(oConn, "My WebSites");
				} // fi

		    session.setAttribute("validated", new Boolean(true));

	    } else {
	      throw new SQLException("The previous password is not correct");
	    }
	  } // fi

    oConn.commit();
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + " "+sCatName+"&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  response.sendRedirect (response.encodeRedirectUrl ("pwdmanhome.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));

%><%@ include file="../methods/page_epilog.jspf" %>