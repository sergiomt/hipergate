<%@ page import="java.util.Properties,java.io.IOException,java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,java.sql.Statement,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  final int BugTracker=10,DutyManager=11,CollaborativeTools=17;

  int id_domain = Integer.parseInt(request.getParameter("id_domain"), 10);
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  int iFrom = Integer.parseInt(request.getParameter("nu_from"), 10);
  int iTo = Integer.parseInt(request.getParameter("nu_to"), 10);
  int iPad = request.getParameter("nu_to").length();

  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

  String sLanguage = getNavigatorLanguage(request);
  
  final Short iTrue = new Short((short)1);
  final Short iFalse = new Short((short)0);
  final Integer iOne = new Integer(1);
  String sDomainName;
  String sDomainNick;
  String sTxMail, sTxNick;
  
  JDCConnection oCon1 = null;
  PreparedStatement oPrep;
  Statement oStmt;
  ResultSet oRSet = null;
  
  ACLUser oUser = null;
  ACLDomain oDomain = null;
  Category oCatg;
  String sParentId;
  String sHomeId;
  String sCatgId;
  String sUserId;
  int iAlreadyExists = 0;

  Object oMaxPg;
  PreparedStatement oStmMax;
  ResultSet oRstMax;
  DBPersist oRes;
  
  try {

    oCon1 = GlobalDBBind.getConnection("userrange_store");
    
    // Verificar que no exista otro usuario con el mismo nick o e-mail
    oPrep = oCon1.prepareStatement("SELECT " + DB.tx_nickname + "," + DB.tx_main_email + " FROM " + DB.k_users + " WHERE (" + DB.tx_nickname + "=? AND " + DB.id_domain + "=?) OR " + DB.tx_main_email + "=?",
    				   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    
    for (int u=iFrom; u<=iTo && 0==iAlreadyExists; u++) {
      sTxNick = request.getParameter("tx_nickname")+Gadgets.leftPad(String.valueOf(u),'0',iPad);
      sTxMail = sTxNick+"@"+request.getParameter("tx_domain");
      
      oPrep.setString(1, sTxNick);
      oPrep.setInt   (2, id_domain);
      oPrep.setString(3, sTxMail);

    oRSet = oPrep.executeQuery();

    // Si existe otro usuario asignar iAlreadyExists = 1 ó iAlreadyExists = 2
    if (oRSet.next()) {
      if (oRSet.getString(1).equals(request.getParameter("tx_nickname")))
        iAlreadyExists = 1;
      else if (oRSet.getString(2).equals(sTxMail))
        iAlreadyExists = 2;
      else
      iAlreadyExists = 0;      
    }
    else
      iAlreadyExists = 0;
    oRSet.close();
    } // next
        
    oPrep.close();
    
    // Si no existe otro usuario con el mismo nick o e-mail...    
    if (0==iAlreadyExists) {
    
      oCon1.setAutoCommit (false);

      // ******************************************
      // Crear el nuevo usuario

      for (int u=iFrom; u<=iTo; u++) {

        sTxNick = request.getParameter("tx_nickname")+Gadgets.leftPad(String.valueOf(u),'0',iPad);
        sTxMail = sTxNick+"@"+request.getParameter("tx_domain");
    
        sUserId = ACLUser.create(oCon1, new Object[] {
          new Integer(id_domain),
          sTxNick,
          request.getParameter("tx_pwd"),
          nullif(request.getParameter("chk_active")).equals("1") ? iTrue : iFalse,
          iTrue, // bo_searchable
          iTrue, // bo_change_pwd
          sTxMail,
          null,
          request.getParameter("nm_user"),
          request.getParameter("tx_surname1"),
          request.getParameter("tx_surname2"),
          request.getParameter("tx_challenge"),
          request.getParameter("tx_reply"),
          request.getParameter("nm_company"),
          request.getParameter("de_title"),
          request.getParameter("tx_comments")        
        } );

        // ***********************************
        // Asociar el usuario con su WorkArea
      
        if (null!=gu_workarea) {

        // *************************************************************************************
        // If the Duties Management module is active then add the new user to the resources list
	
        if ((iAppMask & (1<<BugTracker))!=0) {
        	            
          oStmMax = oCon1.prepareStatement("SELECT MAX(" + DB.pg_lookup + ")+1 FROM " + DB.k_bugs_lookup + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "='nm_assigned'");
          oStmMax.setString(1, gu_workarea);
          oRstMax = oStmMax.executeQuery();
          if (oRstMax.next()) {
            oMaxPg = oRstMax.getObject(1);
            if (oRstMax.wasNull())
              oMaxPg = new Integer(1);            
          }
          else
            oMaxPg = new Integer(1);

          oRstMax.close();
          oStmMax.close();

          oRes = new DBPersist (DB.k_bugs_lookup, "BugAssigned");
          
          oRes.put (DB.gu_owner, gu_workarea);
          oRes.put (DB.id_section, "nm_assigned");
          oRes.put (DB.pg_lookup, oMaxPg);
          oRes.put (DB.vl_lookup, sUserId);
          oRes.put (DB.tr_ + "es", sTxNick);
          oRes.put (DB.tr_ + "en", sTxNick);
          oRes.put (DB.tr_ + "de", sTxNick);
          oRes.put (DB.tr_ + "it", sTxNick);
          oRes.put (DB.tr_ + "fr", sTxNick);
          oRes.put (DB.tr_ + "pt", sTxNick);
          oRes.put (DB.tr_ + "ca", sTxNick);
          oRes.put (DB.tr_ + "eu", sTxNick);
          oRes.put (DB.tr_ + "ja", sTxNick);
          oRes.put (DB.tr_ + "cn", sTxNick);
          oRes.put (DB.tr_ + "tw", sTxNick);
          oRes.put (DB.tr_ + "fi", sTxNick);
          oRes.put (DB.tr_ + "ru", sTxNick);
          oRes.put (DB.tr_ + "pl", sTxNick);
          oRes.put (DB.tr_ + "sk", sTxNick);
	  
	  oRes.store(oCon1);  

          GlobalCacheClient.expire(DB.k_duties_lookup + ".nm_resource#" + sLanguage + "[" + gu_workarea + "]"); 
          GlobalCacheClient.expire(DB.k_bugs_lookup + ".nm_assigned#" + sLanguage + "[" + gu_workarea + "]"); 

        } // fi (iAppMask & BugTracker)
      
        if ((iAppMask & (1<<DutyManager))!=0) {
        	            
          oStmMax = oCon1.prepareStatement("SELECT MAX(" + DB.pg_lookup + ")+1 FROM " + DB.k_duties_lookup + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "='nm_resource'");
          oStmMax.setString(1, gu_workarea);
          oRstMax = oStmMax.executeQuery();
          if (oRstMax.next()) {
            oMaxPg = oRstMax.getObject(1);
            if (oRstMax.wasNull())
              oMaxPg = new Integer(1);            
          }
          else
            oMaxPg = new Integer(1);

          oRstMax.close();
          oStmMax.close();

          oRes = new DBPersist (DB.k_duties_lookup, "DutyResources");
          
          oRes.put (DB.gu_owner, gu_workarea);
          oRes.put (DB.id_section, "nm_resource");
          oRes.put (DB.pg_lookup, oMaxPg);
          oRes.put (DB.vl_lookup, sUserId);
          oRes.put (DB.tr_ + "es", sTxNick);
          oRes.put (DB.tr_ + "en", sTxNick);
          oRes.put (DB.tr_ + "de", sTxNick);
          oRes.put (DB.tr_ + "it", sTxNick);
          oRes.put (DB.tr_ + "fr", sTxNick);
          oRes.put (DB.tr_ + "pt", sTxNick);
          oRes.put (DB.tr_ + "ca", sTxNick);
          oRes.put (DB.tr_ + "eu", sTxNick);
          oRes.put (DB.tr_ + "ja", sTxNick);
          oRes.put (DB.tr_ + "cn", sTxNick);
          oRes.put (DB.tr_ + "tw", sTxNick);
          oRes.put (DB.tr_ + "fi", sTxNick);
          oRes.put (DB.tr_ + "ru", sTxNick);
          oRes.put (DB.tr_ + "pl", sTxNick);
          oRes.put (DB.tr_ + "sk", sTxNick);
	  
	  oRes.store(oCon1);  

          GlobalCacheClient.expire(DB.k_duties_lookup + ".nm_resource#" + sLanguage + "[" + gu_workarea + "]"); 

        } // fi (iAppMask & DutyManager)

        // *************************************************************************************

  	Statement oUpdt = oCon1.createStatement();
  	oUpdt.executeUpdate("UPDATE " + DB.k_users + " SET " + DB.gu_workarea + "='" + gu_workarea + "' WHERE " + DB.gu_user + "='" + sUserId + "'");
  	oUpdt.close();
  	oUpdt = null;
  	
  	GlobalCacheClient.expire ("["+gu_workarea+",users]");
  	
      } // fi (gu_workarea)
      
      // *******************************************
      // Asociar el usuario a los grupos pertinentes
      
      if (nullif(request.getParameter("memberof")).length()>0) {
	new ACLUser(sUserId).addToACLGroups(oCon1, request.getParameter("memberof"));
      }
      
      // Grabar un registro de auditoría
      // Parámetros:
      //   Conexión
      //   Id. numérico de la clase (mirar dentro del .java)
      //   Código de operación
      //   GUID del Usuario que realiza la operacion (traza del usuario logado)
      //   GUID del objeto 1 (típicamente origen)
      //   GUID del objeto 2 (típicamente destino)
      //   Id. de la transacción (arbitrario)
      //   IP del browser cliente
      //   Parámetros 255
      //   Parámetros 255

      DBAudit.log(oCon1, ACLUser.ClassId, "NUSR", sUserId, sUserId, null, 0, getClientIP(request), request.getParameter("nm_user"), request.getParameter("tx_main_email"));
               
      // ****************************************************************************************
      // Obtener el nombre del dominio y el identificador unico de la categoria padre de usuarios
     
      oDomain = new ACLDomain(oCon1, id_domain);
    
      sDomainName = oDomain.getString(DB.nm_domain);
    
      sParentId = Category.getIdFromName(oCon1, sDomainName + "_" + "USERS");
    
      // ***********************************************
      // Crear las categorias personales para el usuario
    
      sDomainNick = sDomainName + "_" + sTxNick;
    
      sHomeId = Category.create(oCon1, new Object[] { sParentId, sUserId, sDomainNick, iTrue, iOne, "mydesktopc_16x16.gif", "mydesktopc_16x16.gif" });

      DBAudit.log(oCon1, Category.ClassId, "NCAT", sUserId, sHomeId, sParentId, 0, getClientIP(request), sDomainNick, null);

      CategoryLabel.create (oCon1, new Object[] { sHomeId, "es", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "en", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "de", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "it", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "fr", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "pt", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "ru", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "fi", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "cn", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "tw", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "ca", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "eu", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "ja", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "pl", sTxNick, null });
      CategoryLabel.create (oCon1, new Object[] { sHomeId, "sk", sTxNick, null });

      sCatgId = Category.create(oCon1, new Object[] { sHomeId, sUserId, sDomainNick + "_docs", iTrue, iOne, "folderclosed_16x16.gif", "folderopen_16x16.gif" });

      DBAudit.log(oCon1, Category.ClassId, "NCAT", sUserId, sCatgId, sHomeId, 0, getClientIP(request), sDomainNick + "_docs", null);

      CategoryLabel.create (oCon1, new Object[] { sCatgId, "es", "documentos", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "en", "documents", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "fr", "documents", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "de", "dokumente", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "it", "dokumenti", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "ru", "Документы", null });

      sCatgId = Category.create(oCon1, new Object[] { sHomeId, sUserId, sDomainNick + "_favs", iTrue, iOne, "folderfavsc_16x16.gif", "folderfavso_16x16.gif" });

      DBAudit.log(oCon1, Category.ClassId, "NCAT", sUserId, sCatgId, sHomeId, 0, getClientIP(request), sDomainNick + "_favs", null);

      CategoryLabel.create (oCon1, new Object[] { sCatgId, "es", "favoritos", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "en", "favourites", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "fr", "favoris", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "de", "favoriten", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "it", "preferiti", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "ru", "Избранное", null });

      sCatgId = Category.create(oCon1, new Object[] { sHomeId, sUserId, sDomainNick + "_temp", iTrue, iOne, "foldertempc_16x16.gif", "foldertempo_16x16.gif" });

      DBAudit.log(oCon1, Category.ClassId, "NCAT", sUserId, sCatgId, sHomeId, 0, getClientIP(request), sDomainNick + "_temp", null);

      CategoryLabel.create (oCon1, new Object[] { sCatgId, "es", "temp", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "en", "temp", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "fr", "temp", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "de", "temp", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "it", "temp", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "ru", "Временный", null });
      
      sCatgId = Category.create(oCon1, new Object[] { sHomeId, sUserId, sDomainNick + "_email", iTrue, iOne, "myemailc_16x16.gif", "myemailo_16x16.gif" });

      DBAudit.log(oCon1, Category.ClassId, "NCAT", sUserId, sCatgId, sHomeId, 0, getClientIP(request), sDomainNick + "_email", null);

      CategoryLabel.create (oCon1, new Object[] { sCatgId, "es", "correos", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "en", "emails", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "fr", "emails", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "de", "emails", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "it", "emails", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "ru", "emails", null });

      sCatgId = Category.create(oCon1, new Object[] { sHomeId, sUserId, sDomainNick + "_recycled", iTrue, iOne, "recycledfull_16x16.gif", "recycledfull_16x16.gif" });

      DBAudit.log(oCon1, Category.ClassId, "NCAT", sUserId, sCatgId, sHomeId, 0, getClientIP(request), sDomainNick + "_recycled", null);

      CategoryLabel.create (oCon1, new Object[] { sCatgId, "es", "eliminados", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "en", "deleted", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "fr", "efface", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "de", "geloescht", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "it", "cancellati", null });
      CategoryLabel.create (oCon1, new Object[] { sCatgId, "ru", "Удалённый", null });

      // *****************************************************************************
      // Establecer la referencia a la categoria home del usuario
      oStmt = oCon1.createStatement();
      oStmt.executeUpdate("UPDATE " + DB.k_users + " SET " + DB.gu_category + "='" + sHomeId + "' WHERE " + DB.gu_user + "='" + sUserId + "'");
      oStmt.close();

      // *****************************************************************************
      // Asignar y propagar permisos desde la categoria home del usuario recien creado

      oCatg = new Category(sHomeId);

      // Asignar permisos al usuario actual    
      oCatg.setUserPermissions(oCon1, sUserId, ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_DELETE|ACL.PERMISSION_MODIFY|ACL.PERMISSION_GRANT, iTrue.shortValue(), (short) 0);

      // Asignar permisos al usuario administrador del dominio
      oCatg.setUserPermissions(oCon1, oDomain.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, iTrue.shortValue(), (short) 0);

      // Asignar permisos al grupo de administradores del dominio
      oCatg.setGroupPermissions(oCon1, oDomain.getString(DB.gu_admins), ACL.PERMISSION_FULL_CONTROL, iTrue.shortValue(), (short) 0);
    
      oCatg = null;

      // *****************************************************
      // Crear las carpetas de correo por defecto (si procede)

      if (DBBind.exists(oCon1, DB.k_mime_msgs, "U")) {
        ACLUser oMe = new ACLUser(sUserId);
        oMe.getMailRoot (oCon1);                  
        oMe.getMailFolder(oCon1, "inbox");
        oMe.getMailFolder(oCon1, "outbox");
        oMe.getMailFolder(oCon1, "drafts");
        oMe.getMailFolder(oCon1, "deleted");
        oMe.getMailFolder(oCon1, "sent");
        oMe.getMailFolder(oCon1, "spam");
        oMe.getMailFolder(oCon1, "received");        
      }
      
      // ***************************************************************************
      // Check whether or not there is an active LDAP server and synchronize with it
    
      String sLdapConnect = Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapconnect", "");
      if (sLdapConnect.length()>0) {
        Class oLdapCls = Class.forName(Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapclass", "com.knowgate.ldap.LDAPNovell"));
        com.knowgate.ldap.LDAPModel oLdapImpl = (com.knowgate.ldap.LDAPModel) oLdapCls.newInstance();
        oLdapImpl.connectAndBind(Environment.getProfile(GlobalDBBind.getProfileName()));
        oLdapImpl.addUser (oCon1, sUserId);
        oLdapImpl.disconnect();
      }
      
      // End LDAP synchronization
      // ***************************************************************************
        
      oCon1.commit();
      } // next (u)
    oCon1.close("userrange_store");

    } // fi (iAlreadyExists)
    else {
      oCon1.close("userrange_store");

      switch (iAlreadyExists) {
        case 1: response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Impossible to create new user&desc=Another user with same nickname already exists&resume=_back"));
 	        break;
        case 2: response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Impossible to create new user&desc=Another user with same e-mail already exists&resume=_back"));
 	        break;
      }
    }
  }    
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("userrange_store");
        oCon1 = null;
      } // fi (oCon1.isClosed)
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  catch (com.knowgate.ldap.LDAPException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("userrange_store");
        oCon1 = null;
      } // fi (oCon1.isClosed)
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=LDAPException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  if (null==oCon1) return;
  oCon1 = null;
%>
<HTML>
  <HEAD>
    <TITLE>Wait...</TITLE>
    <META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
    <META HTTP-EQUIV="Pragma" CONTENT="no-cache"> 
    <SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>
    <!--
      function redirect() {
        window.opener.location.reload(true);
        self.close();
      }
    -->
    </SCRIPT>
  </HEAD>
  <BODY onLoad="redirect()"></BODY>
</HTML>