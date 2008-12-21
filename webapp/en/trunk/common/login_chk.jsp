<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.CallableStatement,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.workareas.WorkArea,com.knowgate.billing.Account,com.knowgate.cache.DistributedCachePeer,com.knowgate.misc.Environment,com.knowgate.misc.MD5" language="java" session="false" buffer="8kb" autoFlush="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  if (DebugFile.trace) DebugFile.writeln("Begin <JSP:login_chk.jsp"); 

%><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/authusrs.jspf" %><%!
  public static void logLoginAttempt(DBBind oDbb, JDCConnection oConn, String sSuccess, short iErrorCode, String sGuUser, String sTxMail, String sTxPwd, String sGuWorkArea, String sIpAddr)
    throws SQLException {
    PreparedStatement oStmt;
    
    if (oDbb.exists(oConn,"k_login_audit","U")) {
      oStmt = oConn.prepareStatement("INSERT INTO k_login_audit (bo_success,nu_error,gu_user,tx_email,tx_pwd,gu_workarea,ip_addr) VALUES(?,?,?,?,?,?,?)");
      oStmt.setString(1, sSuccess);
      oStmt.setShort (2, iErrorCode);      
      oStmt.setString(3, sGuUser);
      oStmt.setString(4, sTxMail);
      oStmt.setString(5, sTxPwd);
      oStmt.setString(6, sGuWorkArea);
      oStmt.setString(7, sIpAddr);
      oStmt.executeUpdate();
      oStmt.close();      
    } // fi
  } // logLoginAttempt
%><%
/*
  // This is what include file="../methods/dbbind.jsp" does.
  // This code is unrolled for debugging purposes only,
  // if something bizarre fails whilst instantiating DBBind
  // then remome the include directive and uncomment this code.
  
  DBBind GlobalDBBind = null;

  synchronized (application) {
    GlobalDBBind = (DBBind) pageContext.getAttribute("GlobalDBBind", PageContext.APPLICATION_SCOPE);
    if (GlobalDBBind == null){
      try {
        GlobalDBBind = (DBBind) java.beans.Beans.instantiate(this.getClass().getClassLoader(), "com.knowgate.dataobjs.DBBind");
      } catch (ClassNotFoundException exc) {
        throw new InstantiationException(exc.getMessage());
      } catch (Exception exc) {
        throw new ServletException("Cannot create bean of class com.knowgate.dataobjs.DBBind " + exc.getMessage(), exc);
      }
      pageContext.setAttribute("GlobalDBBind", GlobalDBBind, PageContext.APPLICATION_SCOPE);
    } // fi (GlobalDBBind)
  } // synchronized (application)
*/
  
  // **********************************************
  // Instantiate distributed cache application bean
  
  DistributedCachePeer GlobalCacheClient = null;

  synchronized (application) {
    GlobalCacheClient = (DistributedCachePeer) pageContext.getAttribute("GlobalCacheClient", PageContext.APPLICATION_SCOPE);
    if (GlobalCacheClient == null){
      try {
        GlobalCacheClient = (DistributedCachePeer) java.beans.Beans.instantiate(this.getClass().getClassLoader(), "com.knowgate.cache.DistributedCachePeer");
      } catch (ClassNotFoundException exc) {
        throw new InstantiationException(exc.getMessage());
      } catch (Exception exc) {
        throw new ServletException("Cannot create bean of class com.knowgate.cache.DistributedCachePeer " + exc.getMessage(), exc);
      }
      pageContext.setAttribute("GlobalCacheClient", GlobalCacheClient, PageContext.APPLICATION_SCOPE);
    } // fi (GlobalCacheClient)
  } // synchronized (application)
  
  // **********************************************
      
  JDCConnection oConn;
  String sUserId = null;
  String sSkin = nullif(request.getParameter("skin"),"xp");
  String sCaptchaKey = getCookie (request, "captcha_key", null);
  String sCaptchaTimestamp = getCookie (request, "captcha_timestamp", String.valueOf(new java.util.Date().getTime()));
  String sNickCookie = getCookie (request, "NickCookie", "null");
  String sNickName = nullif(request.getParameter("nickname"));
  String sContext = nullif(request.getParameter("context"));
  String sCaptchaText = nullif(request.getParameter("captcha_text"));
  String sFace = nullif(request.getParameter("face"),"");
  long lCaptchaTimestamp;
  
  try {
    lCaptchaTimestamp = Long.parseLong(sCaptchaTimestamp);
  } catch (NumberFormatException nfe) {
    lCaptchaTimestamp = new java.util.Date().getTime();
  }
  
  if (sFace.length()==0)
    sFace = Environment.getProfileVar(GlobalDBBind.getProfileName(), "face", "crm");
      
  String sAuthStr, sAuthNew, nmDomain, nmWorkArea, sTxMainEMail;
    
  int idDomain = 0;
  short iStatus = ACL.INTERNAL_ERROR;
  String guWorkArea = null;
  String sPathLogo = null;
  String sIdAccount = null;
  boolean bDomainAdmin = false;
  PreparedStatement oStmt = null;
  ResultSet oRSet;
  DBSubset oApps;
  int iApps;
  String sGrp;
  ACLUser oUser = null;
  ACLDomain oDom;
  int iAppMask = 0;
  String sSQL, sMsg;

  // ************************************************************************
  // Get Database Connection pool
  
  if (null==GlobalDBBind) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Error Bean~]&desc=[~GlobalDBBind.getConnection() - Imposible referenciar bean de conexion con base de datos~]&resume=_back"));
    return;
  }

  String sAuthMethod = Environment.getProfileVar(GlobalDBBind.getProfileName(), "authmethod", "native").trim().toLowerCase();

  if (sAuthMethod.equals("ntlm") && sContext.equals("nativelogin")) sAuthMethod = "native";
  
  // ************************************************************************
  // Verify if NickCookie can be readed
  // If it cannot be readed it means that client browser has disabled cookies

  /*
  if (!sNickCookie.equals(request.getParameter("nickname")) && !sContext.equals("newbye") && !sAuthMethod.equals("ntlm")) {    
    
    if (DebugFile.trace) DebugFile.writeln("ERROR: login_chk.jsp -> Error leyendo cookies nickcookie=\""+sNickCookie+"\" nickname="+request.getParameter("nickname")+"\"");
    
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Imposible Iniciar Sesion~]&desc=[~No se puede conectar con el sistema porque su navegador tiene deshabilitadas las cookies de sesión~]<BR>authmethod="+sAuthMethod+"<BR>context="+sContext+"<BR>nickname="+request.getParameter("nickname")+"<BR>nickcookie="+sNickCookie+"&resume=_back"));
    return;
  }
  */
  
  // End Verify Cookies
  // ************************************************************************

  if (sAuthMethod.equals("ntlm")) {
    sNickName = sNickCookie;
    sAuthStr = getCookie (request, "authstr", "null");
    sAuthNew = null;
    nmDomain = getCookie (request, "domainnm", "null");
    nmWorkArea = "";
    sTxMainEMail = null;
  }
  else {
    sNickName = nullif(request.getParameter("nickname"));
    sAuthStr = nullif(request.getParameter("pwd_text"));    
    sAuthNew = nullif(request.getParameter("pwd_new_text1"));
    nmDomain = nullif(request.getParameter("nm_domain"));
    nmWorkArea = nullif(request.getParameter("nm_workarea"));
    sTxMainEMail = null;
  }
  
  if (sNickName.equals("administrator@hipergate-system.com"))
    GlobalDBBind.connectionPool().closeConnections();
  
  try {  
    oConn = GlobalDBBind.getConnection("login");
    
    if (null==oConn) throw new SQLException("Connection pool broken");
  }
  catch (SQLException e) {
    oConn = null;
    sMsg = e.getMessage().replace(':', ' ');
    
    if (DebugFile.trace) DebugFile.writeln("ERROR: login_chk.jsp -> GlobalDBBind.getConnection() returned null " + sMsg);

    try { GlobalDBBind.restart(); } catch (Exception x) { if (DebugFile.trace) DebugFile.writeln("ERROR restarting conenction pool " + x.getMessage()); }
    
    try {  
      oConn = GlobalDBBind.getConnection("login");
    }
    catch (SQLException s) {    
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error JDBC&desc=GlobalDBBind.getConnection() - " + sMsg + "&resume=_back"));
      return;
    }
  }

  // End Database Connection Pool
  // ************************************************************************
  
  if (null==oConn) {
    if (DebugFile.trace) DebugFile.writeln("ERROR: login_chk.jsp -> Impossible to get connection to the database");

    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Error SQL~]&desc=[~GlobalDBBind.getConnection() - Imposible obtener la conexion a la base de datos~]&resume=_back"));
  } else {  
    try {

      // ******************************************
      // Some defensive programming for PostgreSQL:
      // detect that PL/pgSQL is enabled
                              	      
      // *************************************
      // Get Domain Id from Name or from email

      if (nmDomain.length()!=0) {
        
        // ************************************************************************
        // Get Domain Id from Domain Name

        if (DebugFile.trace) DebugFile.writeln("<JSP:ACLDomain.getIdFromName([Connection]," + nmDomain + ")");

      	idDomain = ACLDomain.getIdFromName(oConn,nmDomain);
        
        if (idDomain>0) {

          // If nickname contains @ then asume an e-mail address

          if (sNickName.indexOf("@")>0) {
            sTxMainEMail = sNickName;
            if (DebugFile.trace) DebugFile.writeln("<JSP:ACLUser.getIdFromEmail([Connection]," + sNickName+")");
            sUserId = ACLUser.getIdFromEmail(oConn, sNickName);
            if (DebugFile.trace) DebugFile.writeln("<JSP:userid=" + sUserId);
          }          
          else {
            if (DebugFile.trace) DebugFile.writeln("<JSP:ACLUser.getUserIdFromNick([Connection]," + sNickName + "," + String.valueOf(idDomain)+")");
            sUserId = ACL.getUserIdFromNick(oConn, sNickName, idDomain);

            if (null==sUserId) {
    	      response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~User not found~]&desc=[~Cannot find user~] " + sNickName + " [~at domain~] " + String.valueOf(idDomain) + "&resume=_back"));
              oConn.close("login");
              return;
            }

            sTxMainEMail = ACLUser.getEmailFromId(oConn, sUserId);
            if (DebugFile.trace) DebugFile.writeln("<JSP:userid=" + sUserId);
          }
          // fi (sNickName.indexOf("@"))
          
          if (DebugFile.trace) DebugFile.writeln("<JSP:WorkArea.getIdFromName([Connection]," + String.valueOf(idDomain) +"," + nmWorkArea + ")");

          oUser = new ACLUser(oConn, sUserId);
          
          if (nmWorkArea.length()>0)
            guWorkArea = WorkArea.getIdFromName(oConn, idDomain, nmWorkArea);        
          else {
            guWorkArea = oUser.getStringNull(DB.gu_workarea, null);
	    nmWorkArea = new WorkArea(oConn, guWorkArea).getString(DB.nm_workarea);
          }

          if (DebugFile.trace) DebugFile.writeln("<JSP:workarea=" + guWorkArea);
          
	  sIdAccount = oUser.getStringNull(DB.id_account,"");

	  if (sIdAccount.length()>0) {          
	    if (!Account.checkStatus(oConn, sIdAccount))
	      iStatus = ACL.ACCOUNT_DEACTIVATED;              

	    if (Account.isTrial(oConn, sIdAccount)) {
              try { GlobalCacheClient.put("[" + sUserId + ",trial]", new Boolean(true)); } catch (Exception e) { /* trial already cached */ }
	    }
	    else {
              try { GlobalCacheClient.put("[" + sUserId + ",trial]", new Boolean(false)); } catch (Exception e) { /* trial already cached */ }
	    } 

    } // fi (sIdAccount)

  } // fi (idDomain)
        
  else {
          if (DebugFile.trace) DebugFile.writeln("<JSP:domain " + nmDomain + " not found");

	     iStatus = ACL.DOMAIN_NOT_FOUND;
          sUserId = null;
          guWorkArea = null;
        }            

        // End Get Domain Id from Domain Name
        // ************************************************************************
      }
      else { // nmDomain==""
      
        // ************************************************************************
        // Get Domain Id from User e-mail
      
        if (DebugFile.trace) DebugFile.writeln("<JSP:ACLUser.getIdFromEmail([Connection]," + sNickName + ")");	
	
	      sUserId = ACLUser.getIdFromEmail(oConn, sNickName);
        sTxMainEMail = sNickName;
        
        if (DebugFile.trace) DebugFile.writeln("<JSP:userid=" + sUserId);
	
	if (null!=sUserId) {
	  
	  oUser = new ACLUser(oConn, sUserId);
	  idDomain = oUser.getInt(DB.id_domain);
	  sIdAccount = oUser.getStringNull(DB.id_account,"");
	  
	  oDom = new ACLDomain(oConn, idDomain);
	  nmDomain = oDom.getString(DB.nm_domain);
	  
	  
	  if (oUser.isNull(DB.gu_workarea)) {
	    guWorkArea = null;
	    nmWorkArea = null;
	  }
	  else {
	    guWorkArea = oUser.getString(DB.gu_workarea);
	    nmWorkArea = new WorkArea(oConn, guWorkArea).getString(DB.nm_workarea);
	  }
          
          if (DebugFile.trace) {
            DebugFile.writeln("<JSP:domainid=" + String.valueOf(idDomain));
            DebugFile.writeln("<JSP:workarea=" + (guWorkArea!=null ? guWorkArea + " (" + nmWorkArea + ")": "null"));
            if (null==guWorkArea)
              DebugFile.writeln("ERROR: user " + sUserId + " has no default workarea");
          }
          
          if (null==guWorkArea) {
            iStatus = ACL.WORKAREA_NOT_SET;
            idDomain = 0;
          }
          
          else if (sIdAccount.length()>0) {
          
	    if (!Account.checkStatus(oConn, sIdAccount))
	      iStatus = ACL.ACCOUNT_DEACTIVATED;
	    	      
	    if (Account.isTrial(oConn, sIdAccount)) {
              try { GlobalCacheClient.put("[" + sUserId + ",trial]", new Boolean(true)); } catch (Exception e) { /* trial already cached */ }
	    }
	    else {
              try { GlobalCacheClient.put("[" + sUserId + ",trial]", new Boolean(false)); } catch (Exception e) { /* trial already cached */ }
	    } 
          } // fi (sIdAccount!="")    
	}
	
	else { // null==sUserId
	
	  if (DebugFile.trace) DebugFile.writeln("<JSP:email " + sNickName + " not found");
	  iStatus = ACL.USER_NOT_FOUND;
	  idDomain = 0;
	  guWorkArea = null;
	  
	} // fi (sUserId)

        // End Get Domain Id from User e-mail
        // ************************************************************************

      } // fi (nmDomain!="")
      
      if (idDomain>0) {
        
        // ***********************************************************************
        // Check whether or not this is an existing user and his password is valid
        
        if (null!=sUserId) {

	        if (sAuthMethod.equals("native")) {
            iStatus = ACL.autenticate(oConn, sUserId, sAuthStr, ENCRYPT_ALGORITHM);
            if (ACL.PASSWORD_EXPIRED==iStatus && sAuthNew.length()>0) {
					    ACLUser.resetPassword (oConn, sUserId, sAuthNew, null, GlobalCacheClient);
              iStatus = ACL.autenticate(oConn, sUserId, sAuthNew, ENCRYPT_ALGORITHM);
					    sAuthStr = sAuthNew;
					  }
          }
	        else if (sAuthMethod.equals("captcha")) {
            iStatus = ACL.autenticate(oConn, sUserId, sAuthStr, ENCRYPT_ALGORITHM,
                                      lCaptchaTimestamp, 300000l, sCaptchaText, sCaptchaKey);
            if (ACL.PASSWORD_EXPIRED==iStatus && sAuthNew.length()>0) {
					    ACLUser.resetPassword (oConn, sUserId, sAuthNew, null, GlobalCacheClient);
              iStatus = ACL.autenticate(oConn, sUserId, sAuthNew, ENCRYPT_ALGORITHM,
                                        lCaptchaTimestamp, 300000l, sCaptchaText, sCaptchaKey);
					    sAuthStr = sAuthNew;
					  }
          }
          else if (sAuthMethod.equals("ldap")) {
	          iStatus = autenticateLDAPUser (GlobalDBBind, nmDomain, nmWorkArea, sTxMainEMail, sAuthStr);
          }
          else if (sAuthMethod.equals("ntlm")) {
	          iStatus = 0;
          }
          else {
            if (DebugFile.trace) DebugFile.writeln("<JSP:unrecognized authentication method "+sAuthMethod);
            iStatus = ACL.INTERNAL_ERROR;
          }          
	      }
        else {
          if (DebugFile.trace) DebugFile.writeln("<JSP:user "+sUserId+" not found");
          iStatus = ACL.USER_NOT_FOUND;
		    }

        if (DebugFile.trace) DebugFile.writeln("<JSP:iStatus==" + String.valueOf(iStatus));

        // End check user and password
        // ************************************************************************

        // ************************************************************************************
        // Get WorkArea Information
                
        if (guWorkArea!=null) {
          
          sPathLogo = new WorkArea(oConn, guWorkArea).getStringNull(DB.path_logo, "");

          if (DebugFile.trace) DebugFile.writeln("path logo = " + sPathLogo);

	        iAppMask  = WorkArea.getUserAppMask(oConn, guWorkArea, sUserId);

          if (DebugFile.trace) DebugFile.writeln("app mask = " + String.valueOf(iAppMask));

        }
        else
          iStatus = ACL.WORKAREA_NOT_FOUND;

        // End WorkArea Information
        // ************************************************************************************

        // ************************************************************************************
        // Switch on Configuration tab menu on application mask if User is Domain Administrator

	      if (iStatus>=0) {

	        bDomainAdmin = oUser.isDomainAdmin(oConn);
	        if (bDomainAdmin) iAppMask = iAppMask | (1<<30);
	      }

        // End switch on Configuration tab
        // ************************************************************************************


      } 
      else
        if (iStatus==-255) iStatus = ACL.DOMAIN_NOT_FOUND;
      
      // fi (idDomain)
      
      // *******************************************
      // Clear user permissions cache
      
      GlobalCacheClient.expire ("["+sUserId+",admin]");
      GlobalCacheClient.expire ("["+sUserId+",user]");
      GlobalCacheClient.expire ("["+sUserId+",poweruser]");
      GlobalCacheClient.expire ("["+sUserId+",guest]");
      GlobalCacheClient.expire ("["+sUserId+",authstr]");
      
      // *****************************************************
      // Update User last visit and usucessfull login attempts
      
      if (iStatus>=0) {
        oConn.setAutoCommit (true); 

        if (DebugFile.trace) DebugFile.writeln("Conenction.prepareStatement(UPDATE " + DB.k_users + " SET " +
        																			 DB.dt_last_visit + "=" + DBBind.Functions.GETDATE + "," +
																							 DB.nu_login_attempts + "=" + ((short)0==iStatus ? "0" : DB.nu_login_attempts+"+1") +
        																			 " WHERE " + DB.gu_user + "='" + sUserId + "')");

			  try {        
          oStmt = oConn.prepareStatement("UPDATE " + DB.k_users + " SET " +
        															   DB.dt_last_visit + "=" + DBBind.Functions.GETDATE + "," +
																			   DB.nu_login_attempts + "=" + ((short)0==iStatus ? "0" : DB.nu_login_attempts+"+1") +
        															   " WHERE " + DB.gu_user + "=?");

          oStmt.setQueryTimeout(10);

          oStmt.setString(1, sUserId);
          oStmt.execute();
          
        } catch (SQLException ignore) {
        } finally {
          if (null!=oStmt) oStmt.close();        
        } 
        
			  oStmt = null;
      } // fi ()

      oConn.setAutoCommit (true); 
      
      // *******************************************
      // Deactivate User if its Account is Cancelled
      
      if (ACL.ACCOUNT_CANCELLED==iStatus) {

        if (DebugFile.trace) DebugFile.writeln("Conenction.prepareStatement(UPDATE " + DB.k_users + " SET " + DB.bo_active + "=0 WHERE " + DB.gu_user + "='" + sUserId + "'");

        oStmt = oConn.prepareStatement("UPDATE " + DB.k_users + " SET " + DB.bo_active + "=0 WHERE " + DB.gu_user + "=?");

        oStmt.setQueryTimeout(10);
        oStmt.setString(1, sUserId);
        oStmt.execute();
        oStmt.close();

	      oStmt = null;
	
      } // fi(ACL.ACCOUNT_CANCELLED)

      // End Deactivate User
      // *******************************************
      
      if (iStatus>=0) {
        logLoginAttempt(GlobalDBBind, oConn, "1", (short)0, sUserId, sNickName, null, guWorkArea, request.getRemoteAddr());
      } else {
        logLoginAttempt(GlobalDBBind, oConn, "0", iStatus, sUserId, sNickName, sAuthStr, guWorkArea, request.getRemoteAddr());	
      }

      oConn.close("login");
    }
    catch (SQLException e) {
      if (oConn!=null)
        if (!oConn.isClosed())
          oConn.close("login");
      oConn = null;  
      response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Sistema de Autentificacion de Usuarios Fuera de Servicio~]&desc=" + e.getMessage() + "  [~El sistema de autentificación de usuarios esta temporalmente fuera de servicio por favor vuelva a intentarlo mas tarde.~]" + "&resume=_back"));
    }

    catch (IllegalStateException e) {
      if (oConn!=null)
        if (!oConn.isClosed())
          oConn.close("login");
      oConn = null;  
      response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=_back"));
    }

    catch (NullPointerException e) {
      if (oConn!=null)
        if (!oConn.isClosed())
          oConn.close("login");
      oConn = null;  
      response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=_back"));
    }
    
    if (null==oConn) return;
    
    switch (iStatus) {
      case ACL.USER_NOT_FOUND:      
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Usuario No Valido~]&desc=[~El nombre de usuario especificado no se encuentra en la base de datos~]&resume=_back"));  
        return;
      case ACL.INVALID_PASSWORD:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Contraseña No Válida~]&desc=[~La contraseña especificada para el usuario no es válida~]&resume=_back"));  
        return;
      case ACL.ACCOUNT_DEACTIVATED:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Cuenta Desactivada~]&desc=[~La cuenta de este usuario se halla desactivada~]&resume=_back"));
        return;    
      case ACL.DOMAIN_NOT_FOUND:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Dominio no valido~]&desc=[~No existe ningun dominio llamado~] " + nmDomain + "&resume=_back"));
        return;    
      case ACL.WORKAREA_NOT_FOUND:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Area de trabajo no valida~]&desc=[~No existe ningun area de trabajo llamada~] " + nmWorkArea + "&resume=_back"));
        return;    
      case ACL.WORKAREA_NOT_SET:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Area de trabajo no valida~]&desc=[~El usuario no esta asignado a ningun area de trabajo~]&resume=_back"));
        return;
      case ACL.ACCOUNT_CANCELLED:      
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Cuenta Cancelada~]&desc=[~La cuenta de este usuario ha sido cancelada~]&resume=_back"));
        return;
      case ACL.PASSWORD_EXPIRED:
        if (sAuthMethod.equals("ldap") || sAuthMethod.equals("ntlm"))
          response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Clave caducada~]&desc=[~La validez de la clave de acceso a expirado~]&resume=_back"));
        else
          response.sendRedirect (response.encodeRedirectUrl ("pwd_unexpire.jsp?userid="+sUserId+"&context"+sContext+"&skin="+sSkin+"&face="+sFace));
        return;
      case ACL.CAPTCHA_MISMATCH:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~La clave grafica no coincide~]&desc=[~La clave grafica no coincide con el valor introducido~]&resume=_back"));
        return;
      case ACL.CAPTCHA_TIMEOUT:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=[~Clave grafica caducada~]&desc=[~La clave grafica ha caducado~]&resume=_back"));
        return;      
    } // end switch(iStatus)
  } // fi (oConn)

  if (null==oConn) return;

  oConn = null;

  sSkin = getCookie(request, "skin", "xp");
  if (sSkin.length()==0) sSkin="xp";     
%>
<HTML>
  <HEAD>
    <TITLE>[~Espere~]...</TITLE>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
      <!--
        // status = <% out.write(String.valueOf(iStatus)); %>

        var dtInf = new Date(2020, 11, 30, 0, 0, 0, 0);
                          
        setCookie ("profilenm","<%=GlobalDBBind.getProfileName()%>",dtInf);
        setCookie ("domainid","<%=String.valueOf(idDomain)%>",dtInf);
        setCookie ("domainnm","<%=nmDomain%>",dtInf);              
        setCookie ("skin","<%=sSkin%>",dtInf);
        setCookie ("face","<%=sFace%>",dtInf);
        setCookie ("userid","<%=sUserId%>");
        setCookie ("authstr","<%=ACL.encript(sAuthStr,ENCRYPT_ALGORITHM)%>");
        setCookie ("appmask","<%=iAppMask%>"); 
        setCookie ("idaccount","<%=sIdAccount%>");
<%
        // Escribir las cookies que indican en qué área de trabajo se está
        if (oUser!=null) {
          out.write ("        setCookie (\"usernm\",\"" + oUser.getStringNull(DB.tx_nickname,"") + "\");\n");
        }
        if (guWorkArea!=null) {
          out.write ("        setCookie (\"workarea\",\"" + guWorkArea + "\");\n");
          out.write ("        setCookie (\"workareanm\",\"" + nmWorkArea + "\");\n");
          out.write ("        setCookie (\"path_logo\",\"" + sPathLogo + "\");\n");
	      }
	      else {
	        out.write ("        deleteCookie (\"workarea\");\n");
	        out.write ("        deleteCookie (\"workareanm\");\n");
	        out.write ("        deleteCookie (\"path_logo\");\n");
        }
%>
        deleteCookie ("NickCookie");
      //-->
    </SCRIPT>
    <META HTTP-EQUIV="Refresh" CONTENT="0; URL=<%=nullif(request.getParameter("redirect"),"desktop.jsp")%>">
  </HEAD>
</HTML>
<% if (DebugFile.trace) DebugFile.writeln("End <JSP:login_chk.jsp"); %>
<%@ include file="../methods/page_epilog.jspf" %>
