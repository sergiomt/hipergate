<%@ page import="java.util.Date,java.util.Properties,java.io.IOException,java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,java.sql.Statement,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.addrbook.Fellow,com.knowgate.misc.Gadgets,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
  
  String sTxNick = request.getParameter("tx_nickname");

  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

  String sLanguage = getNavigatorLanguage(request);
  
  final Short iTrue = new Short((short)1);
  final Short iFalse = new Short((short)0);
  final Integer iOne = new Integer(1);
  String sDomainName;
  String sDomainNick;
  String sFlwId = null;
  	        
  JDCConnection oCon1 = null;
  JDCConnection oCon2 = null;
  PreparedStatement oPrep;
  Statement oStmt;
  ResultSet oRSet;
  String sSQL;
  
  ACLUser oUser = null;
  ACLDomain oDomain = null;
  String sUserId = null;
  Category oCatg;
  String sParentId;
  String sHomeId;
  String sCatgId;
  Date dtExpires;
  int iAlreadyExists;

  Object oMaxPg;
  PreparedStatement oStmMax;
  ResultSet oRstMax;
  DBPersist oRes;
  
  if (request.getParameter("dt_pwd_expires").length()==0) {
    dtExpires = null;
  } else {
	  String[] aDt = Gadgets.split(request.getParameter("dt_pwd_expires"),'-');	  
	  dtExpires = new java.util.Date(Integer.parseInt(aDt[0])-1900,Integer.parseInt(aDt[1])-1,Integer.parseInt(aDt[2]));  
  }

  try {
    
    oCon1 = GlobalDBBind.getConnection("usernew_store", true);

    // Verificar que no exista otro usuario con el mismo nick o e-mail
    sSQL = "SELECT " + DB.tx_nickname + "," + DB.tx_main_email + " FROM " + DB.k_users + " WHERE (" + DB.tx_nickname + "=? AND " + DB.id_domain + "=?) OR " + DB.tx_main_email + "=?";

    if (DebugFile.trace) DebugFile.writeln("<JSP:JDCConnection.prepareStatement("+sSQL+")");

    oPrep = oCon1.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    
    oPrep.setString(1, request.getParameter("tx_nickname"));
    oPrep.setInt   (2, id_domain);
    oPrep.setString(3, request.getParameter("tx_main_email"));

    if (DebugFile.trace) DebugFile.writeln("<JSP:JDCConnection.executeQuery("+request.getParameter("tx_nickname")+","+String.valueOf(id_domain)+","+request.getParameter("tx_main_email")+")");

    oRSet = oPrep.executeQuery();

    // Si existe otro usuario asignar iAlreadyExists = 1 ó iAlreadyExists = 2
    if (oRSet.next()) {
      if (oRSet.getString(1).equals(request.getParameter("tx_nickname")))
        iAlreadyExists = 1;
      else if (oRSet.getString(2).equals(request.getParameter("tx_main_email")))
        iAlreadyExists = 2;
      else
      iAlreadyExists = 0;      
    }
    else
      iAlreadyExists = 0;
    
    oRSet.close();
    oPrep.close();
    
    // Si no existe otro usuario con el mismo nick o e-mail...    
    if (0==iAlreadyExists) {

      if (null!=gu_workarea) {
        if ((iAppMask & (1<<CollaborativeTools))!=0) {

          // *******************************************************************************
          // Si existe un empleado con el mismo e-mail en el mismo dominio y área de trabajo
          // asignar al usuario el mismo guid que al empleado.

					sSQL = "SELECT " + DB.gu_fellow + " FROM " + DB.k_fellows + " WHERE " + DB.id_domain + "=? AND " + DB.gu_workarea + "=? AND " + DB.tx_email + "=?";

          if (DebugFile.trace) DebugFile.writeln("<JSP:JDCConnection.prepareStatement("+sSQL+")");

  	      PreparedStatement oFlw = oCon1.prepareStatement(sSQL);

	        oFlw.setInt(1, id_domain);
	        oFlw.setString(2, gu_workarea);
	        oFlw.setString(3, request.getParameter("tx_main_email"));	  

          if (DebugFile.trace) DebugFile.writeln("<JSP:JDCConnection.executeQuery("+String.valueOf(id_domain)+","+gu_workarea+","+request.getParameter("tx_main_email")+")");

  	      ResultSet rFlw = oFlw.executeQuery();

	        if (rFlw.next())
	          sFlwId = rFlw.getString(1);
	        else
	          sFlwId = null;
	    
	        rFlw.close();
	        oFlw.close();
	      } // fi (CollaborativeTools)
	    } // fi (gu_workarea)
      
      // Close read-only connection and re-open in read-write mode
      oCon1.close("usernew_store");
      oCon1 = GlobalDBBind.getConnection("usernew_store");
      oCon1.setAutoCommit (false);

      // ******************************************
      // Crear el nuevo usuario
    
      sUserId = ACLUser.create(oCon1, sFlwId, new Object[] {
        new Integer(id_domain),
        request.getParameter("tx_nickname"),
        request.getParameter("tx_pwd"),
        nullif(request.getParameter("chk_active")).equals("1") ? iTrue : iFalse,
        iTrue, // bo_searchable
        iTrue, // bo_change_pwd
        request.getParameter("tx_main_email"),
        request.getParameter("tx_alt_email"),
        request.getParameter("nm_user"),
        request.getParameter("tx_surname1"),
        request.getParameter("tx_surname2"),
        request.getParameter("tx_challenge"),
        request.getParameter("tx_reply"),
        request.getParameter("nm_company"),
        request.getParameter("de_title"),
        request.getParameter("gu_workarea"),
        request.getParameter("tx_comments"),        
        dtExpires
        } );

      // ***********************************
      // Asociar el usuario con su WorkArea
      
      if (null!=gu_workarea) {

        if ((iAppMask & (1<<CollaborativeTools))!=0) {
  	  
  	      if (null!=sFlwId) {

  	        DBCommand.executeUpdate(oCon1,"UPDATE " + DB.k_users + " SET " + DB.gu_user + "='" + sFlwId + "' WHERE " + DB.gu_user + "='" + sUserId + "'");
	          sUserId = sFlwId;

  	      } else if (nullif(request.getParameter("chk_fellow")).equals("1")) {  	      	

    			  oCon2 = GlobalDBBind.getConnection("usernew_store_exists_fellow", true);
					  boolean bExistsFellow = DBCommand.queryExists(oCon2, DB.k_fellows, DB.gu_fellow+"='"+sUserId+"'");
					  oCon2.close("usernew_store_exists_fellow");

    			  if (!bExistsFellow) {
    			    Fellow oFllw = new Fellow(sUserId);
      				oFllw.put(DB.id_domain, id_domain);      
      				oFllw.put(DB.gu_workarea, gu_workarea);
      				oFllw.put(DB.tx_company, request.getParameter("nm_company"));
      				oFllw.put(DB.tx_name, request.getParameter("nm_user"));
      				oFllw.put(DB.tx_surname, Gadgets.left((request.getParameter("tx_surname1")+" "+request.getParameter("tx_surname2")).trim(),100) );
      				oFllw.put(DB.de_title, request.getParameter("de_title"));
      				oFllw.put(DB.tx_email, request.getParameter("tx_main_email"));
      				oFllw.put(DB.tx_comments, request.getParameter("tx_comments"));
      				oFllw.store(oCon1);
      
      				GlobalCacheClient.expire("k_fellows.id_domain[" + id_domain + "]");
      				GlobalCacheClient.expire("k_fellows.gu_workarea[" + request.getParameter("gu_workarea") + "]");
    			  } // fi (!oFlw.exists())												
  	      } // fi
        } // fi (iAppMask & CollaborativeTools)

        // *************************************************************************************
        // New for v2.1
        // If the Duties Management module is active then add the new user to the resources list

	      String sFullName = nullif(request.getParameter("nm_user"));
	      if (nullif(request.getParameter("tx_surname1")).length()>0) sFullName += " " + request.getParameter("tx_surname1");
	      if (nullif(request.getParameter("tx_surname2")).length()>0) sFullName += " " + request.getParameter("tx_surname2");
	      if (sFullName.trim().length()==0) sFullName = sTxNick;
	
        if ((iAppMask & (1<<BugTracker))!=0) {

    			oCon2 = GlobalDBBind.getConnection("usernew_store_max_bug_assigned", true);

					sSQL = "SELECT MAX(" + DB.pg_lookup + ")+1 FROM " + DB.k_bugs_lookup + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "='nm_assigned'";

          if (DebugFile.trace) DebugFile.writeln("<JSP:JDCConnection.prepareStatement("+sSQL+")");

          oStmMax = oCon2.prepareStatement(sSQL);
          oStmMax.setString(1, gu_workarea);

          if (DebugFile.trace) DebugFile.writeln("<JSP:JDCConnection.executeQuery("+gu_workarea+")");

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

					oCon2.close("usernew_store_max_bug_assigned");

          oRes = new DBPersist (DB.k_bugs_lookup, "BugAssigned");
          
          oRes.put (DB.gu_owner, gu_workarea);
          oRes.put (DB.id_section, "nm_assigned");
          oRes.put (DB.pg_lookup, oMaxPg);
          oRes.put (DB.vl_lookup, sUserId);
					for (int l=0; l<DBLanguages.SupportedLanguages.length; l++) {
            oRes.put (DB.tr_ + DBLanguages.SupportedLanguages[l], sFullName);
					}
	  
	        oRes.store(oCon1);  

          GlobalCacheClient.expire(DB.k_duties_lookup + ".nm_resource#" + sLanguage + "[" + gu_workarea + "]"); 
          GlobalCacheClient.expire(DB.k_bugs_lookup + ".nm_assigned#" + sLanguage + "[" + gu_workarea + "]"); 

        } // fi (iAppMask & BugTracker)
      
        if ((iAppMask & (1<<DutyManager))!=0) {
        	            
    			oCon2 = GlobalDBBind.getConnection("usernew_store_max_duty_assigned", true);

					sSQL = "SELECT MAX(" + DB.pg_lookup + ")+1 FROM " + DB.k_duties_lookup + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "='nm_resource'";

          if (DebugFile.trace) DebugFile.writeln("<JSP:JDCConnection.prepareStatement("+sSQL+")");

          oStmMax = oCon2.prepareStatement(sSQL);
          oStmMax.setString(1, gu_workarea);

          if (DebugFile.trace) DebugFile.writeln("<JSP:JDCConnection.executeQuery("+gu_workarea+")");

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

					oCon2.close("usernew_store_max_duty_assigned");

          oRes = new DBPersist (DB.k_duties_lookup, "DutyResources");
          
          oRes.put (DB.gu_owner, gu_workarea);
          oRes.put (DB.id_section, "nm_resource");
          oRes.put (DB.pg_lookup, oMaxPg);
          oRes.put (DB.vl_lookup, sUserId);
					for (int l=0; l<DBLanguages.SupportedLanguages.length; l++) {
            oRes.put (DB.tr_ + DBLanguages.SupportedLanguages[l], sFullName);
					}
	  
	        oRes.store(oCon1);  

          GlobalCacheClient.expire(DB.k_duties_lookup + ".nm_resource#" + sLanguage + "[" + gu_workarea + "]"); 

        } // fi (iAppMask & DutyManager)
  	
  	    GlobalCacheClient.expire ("["+gu_workarea+",users]");
  	
      } // fi (gu_workarea)
      
      // *******************************************
      // Asociar el usuario a los grupos pertinentes
      
      if (nullif(request.getParameter("memberof")).length()>0) {
		    new ACLUser(sUserId).addToACLGroups(oCon1, request.getParameter("memberof"));
      }

      GlobalCacheClient.put("["+sUserId+",authstr]", request.getParameter("tx_pwd"));
      
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
      
      // ***************************************************************************
      // Check whether or not there is an active LDAP server and synchronize with it
    
      String sLdapConnect = Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapconnect", "");

      if (sLdapConnect.length()>0) {

        Class oLdapCls = Class.forName(Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapclass", "com.knowgate.ldap.LDAPNovell"));

        com.knowgate.ldap.LDAPModel oLdapImpl = (com.knowgate.ldap.LDAPModel) oLdapCls.newInstance();

        oLdapImpl.connectAndBind(Environment.getProfile(GlobalDBBind.getProfileName()));
        
        if (request.getParameter("tx_main_email")!=null)      
          oLdapImpl.addUser (oCon1, sUserId);
          
        oLdapImpl.disconnect();
      }
      
      // End LDAP synchronization
      // ***************************************************************************
        
      oCon1.commit();
      oCon1.close("usernew_store");

    } // fi (iAlreadyExists)
    else {
      oCon1.close("usernew_store");

      switch (iAlreadyExists) {
        case 1: response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Imposible crear nuevo usuario&desc=Ya existe otro usuario con dicho nick en la base de datos&resume=_back"));
 	        break;
        case 2: response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Imposible crear nuevo usuario&desc=Ya existe otro usuario con dicho e-mail en la base de datos&resume=_back"));
 	        break;
      }
    }
  }
  /*
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("usernew_store");
        oCon1 = null;
      } // fi (oCon1.isClosed)
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));    
  }
  */
  catch (com.knowgate.ldap.LDAPException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("usernew_store");
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
    <SCRIPT TYPE='text/javascript'>
      function redirect() {
      	if (window.opener) {
          if (!window.opener.closed)
          window.opener.location.reload(true);
      	}

<% if (nullif(request.getParameter("chk_fellow")).equals("1")) { %>
	  	  window.resizeTo(680, 640);
	  	  window.location = "../addrbook/fellow_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_fellow=<%=sUserId%>&gu_workarea=<%=request.getParameter("gu_workarea")%>&chk_webmail=<%=nullif(request.getParameter("chk_webmail"),"0")%>";
<% } else if (nullif(request.getParameter("chk_webmail")).equals("1")) { %>
	  	  window.resizeTo(680, 640);
	  	  window.location = "../hipermail/account_edit.jsp?id_user=<%=sUserId%>&bo_popup=true";
<% } else { %>
        self.close();
<% } %>
      }
    </SCRIPT>
  </HEAD>
  <BODY onLoad="redirect()"></BODY>
</HTML>