<%@ page import="java.util.ResourceBundle,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.workareas.WorkArea,com.knowgate.cache.DistributedCachePeer,com.knowgate.misc.Gadgets" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><jsp:useBean id="GlobalDBBind" scope="application" class="com.knowgate.dataobjs.DBBind"/><%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

%><%!
  public static void logLoginAttempt(JDCConnection oConn, String sSuccess, short iErrorCode, String sGuUser, String sTxMail, String sTxPwd, String sGuWorkArea, String sIpAddr)
      throws SQLException {    
      PreparedStatement oStmt = oConn.prepareStatement("INSERT INTO k_login_audit (bo_success,nu_error,gu_user,tx_email,tx_pwd,gu_workarea,ip_addr) VALUES(?,?,?,?,?,?,?)");
      oStmt.setString(1, sSuccess);
      oStmt.setShort (2, iErrorCode);      
      oStmt.setString(3, sGuUser);
      oStmt.setString(4, sTxMail);
      oStmt.setString(5, sTxPwd);
      oStmt.setString(6, sGuWorkArea);
      oStmt.setString(7, sIpAddr);
      oStmt.executeUpdate();
      oStmt.close();      
  } // logLoginAttempt
%><%

  // **********************************************

  final java.util.ResourceBundle Labels = java.util.ResourceBundle.getBundle("Labels", request.getLocale());
      
  String sTxMainEMail = request.getParameter("nickname").trim();
  String sAuthStr = request.getParameter("pwd_text");
            
  short iStatus = ACL.INTERNAL_ERROR;
  int idDomain = 0;
  String sUserId = null;
  String guWorkArea = null;
  boolean bDomainAdmin = false;
  ACLUser oUser = null;
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  DBSubset oApps;
  int iAppMask = 0;
  String sSQL, sMsg;

  oConn = GlobalDBBind.getConnection("login");
    
  try {

    // ************************************************************************
    // Get Domain Id from User e-mail
      	
	  sUserId = ACLUser.getIdFromEmail(oConn, sTxMainEMail);
        
	  if (null!=sUserId) {
	  
	    oUser = new ACLUser(oConn, sUserId);
	    idDomain = oUser.getInt(DB.id_domain);
	  
	    ACLDomain oDom = new ACLDomain(oConn, idDomain);
	  	  
	    guWorkArea = oUser.getString(DB.gu_workarea);
                    
      if (null==guWorkArea) {
        iStatus = ACL.WORKAREA_NOT_SET;
        idDomain = 0;
      }          
	  }	
	  else { // null==sUserId
	
	    iStatus = ACL.USER_NOT_FOUND;
	  
	  } // fi (sUserId)
      
    if (idDomain>0) {
        
      // ***********************************************************************
      // Check whether or not this is an existing user and his password is valid
        
      if (null!=sUserId) {
        iStatus = ACL.autenticate(oConn, sUserId, sAuthStr, ACL.PWD_CLEAR_TEXT);
	    } else {
        iStatus = ACL.USER_NOT_FOUND;
		  }
         
      if (guWorkArea!=null) {          
	      iAppMask  = WorkArea.getUserAppMask(oConn, guWorkArea, sUserId);
      } else {
          iStatus = ACL.WORKAREA_NOT_FOUND;
      }
    } else {
      if (iStatus==-255) iStatus = ACL.DOMAIN_NOT_FOUND;
    }  
    // fi (idDomain)
      
    // *****************************************************
    // Update User last visit and usucessfull login attempts
      
    oConn.setAutoCommit (true);
    
    if (iStatus>=0) {

        oStmt = oConn.prepareStatement("UPDATE " + DB.k_users + " SET " +
        															 DB.dt_last_visit + "=" + DBBind.Functions.GETDATE + "," +
																			 DB.nu_login_attempts + "=" + ((short)0==iStatus ? "0" : DB.nu_login_attempts+"+1") +
        															 " WHERE " + DB.gu_user + "=?");
        oStmt.setString(1, sUserId);
        oStmt.executeUpdate();
        oStmt.close();
        oStmt=null;

        logLoginAttempt(oConn, "1", (short)0, sUserId, sTxMainEMail, null, guWorkArea, request.getRemoteAddr());

	      DBSubset oUserGroups = oUser.getGroups(oConn);
	      oUserGroups.setRowDelimiter("','");
	      oUser.put("groups", "'" + Gadgets.dechomp(oUserGroups.toString(),"','") + "'");
	      oUser.put("appmask", iAppMask);
				
				oUser.allcaps(true);

			  session.setAttribute("user", oUser);

    } else {
        logLoginAttempt(oConn, "0", iStatus, sUserId, sTxMainEMail, sAuthStr, guWorkArea, request.getRemoteAddr());	
    }

    oConn.close("login");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("login");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("xcpt_out_of_order")+"&desc=" + e.getMessage() + "&resume=index.jsp"));
  }
  catch (IllegalStateException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("login");
    oConn = null;  
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=index.jsp"));
  }
  catch (NullPointerException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("login");
    oConn = null;  
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=index.jsp"));
  }
  
  if (null==oConn) return;
  
  switch (iStatus) {
      case ACL.USER_NOT_FOUND:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("xcpt_user_not_found")+"&desc="+Labels.getString("xcpt_user_not_found_msg")+"&resume=index.jsp"));
        return;
      case ACL.INVALID_PASSWORD:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("xcpt_invalid_password")+"&desc="+Labels.getString("xcpt_invalid_password_msg")+"&resume=index.jsp"));
        return;
      case ACL.ACCOUNT_DEACTIVATED:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("xcpt_account_deactivated")+"&desc="+Labels.getString("xcpt_account_deactivated_msg")+"&resume=index.jsp"));
        return;    
      case ACL.DOMAIN_NOT_FOUND:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("xcpt_domain_not_found")+"&desc="+Labels.getString("xcpt_domain_not_found_msg")+"&resume=index.jsp"));
        return;    
      case ACL.WORKAREA_NOT_FOUND:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("xcpt_workarea_not_found")+"&desc="+Labels.getString("xcpt_workarea_not_found_msg")+"&resume=index.jsp"));
        return;    
      case ACL.WORKAREA_NOT_SET:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("xcpt_workarea_not_set")+"&desc="+Labels.getString("xcpt_workarea_not_set_msg")+"&resume=index.jsp"));
        return;
      case ACL.ACCOUNT_CANCELLED:      
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("xcpt_account_cancelled")+"&desc="+Labels.getString("xcpt_account_cancelled_msg")+"&resume=index.jsp"));
        return;
      case ACL.PASSWORD_EXPIRED:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("xcpt_password_expired")+"&desc="+Labels.getString("xcpt_password_expired_msg")+"&resume=index.jsp"));
        return;
  } // end switch(iStatus)

  if (null==oConn) return;
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("home.jsp"));
%>