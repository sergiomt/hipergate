<%@ page import="java.util.Date,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/dbbind.jsp" %>
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
  final int BugTracker=10,DutyManager=11;
  
  String id_user = getCookie (request, "userid", "anonymous");
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");    
  String gu_user = request.getParameter("gu_user");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_previous_workarea = gu_workarea;

  String sLanguage = getNavigatorLanguage(request);
  
  String sRetCode;

  ACLUser oUsr = new ACLUser(gu_user);
  int iAppMask = 0;
  Object oPgUser;
  PreparedStatement oStmMax;
  ResultSet oRstMax;
  DBPersist oRes;
  JDCConnection oConn = null;
  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
  
  try {
      if (!bIsAdmin) {
        throw new SQLException("Administrator role is required for modifying groups", "28000", 28000);
      }

      oConn = GlobalDBBind.getConnection("useredit_modify");

      oConn.setAutoCommit (false);
      
      // Get the previous WorkArea for this user, it will be needed for resource synchronization
      if (oUsr.load(oConn, new Object[]{gu_user})) {
        gu_previous_workarea = oUsr.getString(DB.gu_workarea);
      }

      oUsr = new ACLUser(gu_user);
      loadRequest(oConn, request, oUsr);
      oUsr.put(DB.bo_active, nullif(request.getParameter("chk_active")).equals("1") ? (short)1 : (short)0);

      oUsr.store(oConn);
      
      // *******************************************
      // Asociar el usuario a los grupos pertinentes
      
      oUsr.clearACLGroups(oConn);
       
      String sGroupList = request.getParameter("memberof");
      
      if (nullif(sGroupList).length()>0) {
        
        String[] aGroupList = Gadgets.split(sGroupList,',');
        
        for (int g=0; g<aGroupList.length; g++)      
	        oUsr.addToACLGroups(oConn, aGroupList[g]);
	  
      } // fi (request.getParameter("memberof")!=null)
     
      if (!oUsr.isNull(DB.gu_workarea)) {

        String sFullName = nullif(oUsr.getStringNull(DB.nm_user, ""));
        if (oUsr.getStringNull(DB.tx_surname1,"").length()>0) sFullName += " " + oUsr.getString(DB.tx_surname1);
        if (oUsr.getStringNull(DB.tx_surname2,"").length()>0) sFullName += " " + oUsr.getString(DB.tx_surname2);
	      if (sFullName.trim().length()==0) sFullName = request.getParameter("tx_nickname");

        if ((iAppMask & (1<<BugTracker))!=0) {
                	            
          oStmMax = oConn.prepareStatement("SELECT " + DB.pg_lookup + " FROM " + DB.k_bugs_lookup + " WHERE " + DB.gu_owner + "=? AND " + DB.vl_lookup + "=? AND " + DB.id_section + "='nm_assigned'");
          oStmMax.setString(1, gu_workarea);
          oStmMax.setString(2, gu_user);
          oRstMax = oStmMax.executeQuery();
          if (oRstMax.next()) {
            oPgUser = oRstMax.getObject(1);
            if (oRstMax.wasNull())
              oPgUser = null;            
          }
          else
            oPgUser = null;

          oRstMax.close();
          oStmMax.close();

	        if (null!=oPgUser) {
            oRes = new DBPersist (DB.k_bugs_lookup, "BugAssigned");
          
            oRes.put (DB.id_section, "nm_assigned");
            oRes.put (DB.pg_lookup, oPgUser);
            oRes.put (DB.vl_lookup, gu_user);
            for (int l=0; l<DBLanguages.SupportedLanguages.length; l++)
              oRes.put (DB.tr_ + DBLanguages.SupportedLanguages[l], sFullName);

	          if (!oUsr.getString(DB.gu_workarea).equals(gu_previous_workarea)) {
              oRes.replace (DB.gu_owner, gu_previous_workarea);
	            oRes.store(oConn);  
	          }

            oRes.replace (DB.gu_owner, gu_workarea);
	          oRes.store(oConn);  

            GlobalCacheClient.expire(DB.k_duties_lookup + ".nm_resource#" + sLanguage + "[" + gu_workarea + "]");
            GlobalCacheClient.expire(DB.k_bugs_lookup + ".nm_assigned#" + sLanguage + "[" + gu_workarea + "]"); 

          } // fi (null!=oPgUser)
        } // fi (iAppMask&BugTracker)
      
        if ((iAppMask & (1<<DutyManager))!=0) {
                	            
          oStmMax = oConn.prepareStatement("SELECT " + DB.pg_lookup + " FROM " + DB.k_duties_lookup + " WHERE " + DB.gu_owner + "=? AND " + DB.vl_lookup + "=? AND " + DB.id_section + "='nm_resource'");
          oStmMax.setString(1, gu_workarea);
          oStmMax.setString(2, gu_user);
          oRstMax = oStmMax.executeQuery();
          if (oRstMax.next()) {
            oPgUser = oRstMax.getObject(1);
            if (oRstMax.wasNull())
              oPgUser = null;            
          }
          else
            oPgUser = null;

          oRstMax.close();
          oStmMax.close();

	  if (null!=oPgUser) {
            oRes = new DBPersist (DB.k_duties_lookup, "DutyResources");
          
            oRes.put (DB.gu_owner, gu_workarea);
            oRes.put (DB.id_section, "nm_resource");
            oRes.put (DB.pg_lookup, oPgUser);
            oRes.put (DB.vl_lookup, gu_user);
            for (int l=0; l<DBLanguages.SupportedLanguages.length; l++)
              oRes.put (DB.tr_ + DBLanguages.SupportedLanguages[l], sFullName);
	  
	          if (!oUsr.getString(DB.gu_workarea).equals(gu_previous_workarea)) {
              oRes.replace (DB.gu_owner, gu_previous_workarea);
	            oRes.store(oConn);  
	          }

            oRes.replace (DB.gu_owner, gu_workarea);
	          oRes.store(oConn);  

            GlobalCacheClient.expire(DB.k_duties_lookup + ".nm_resource#" + sLanguage + "[" + gu_workarea + "]"); 
          } // fi (null!=oPgUser)
        } // fi (iAppMask&DutyManager)
        
      } // fi (gu_workarea!=null)

      // ***************************************************************************
      // Check whether or not there is an active LDAP server and synchronize with it
    
      String sLdapConnect = Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapconnect", "");

      if (sLdapConnect.length()>0) {

        Class oLdapCls = Class.forName(Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapclass", "com.knowgate.ldap.LDAPNovell"));

        com.knowgate.ldap.LDAPModel oLdapImpl = (com.knowgate.ldap.LDAPModel) oLdapCls.newInstance();

        oLdapImpl.connectAndBind(Environment.getProfile(GlobalDBBind.getProfileName()));

        try {
          oLdapImpl.deleteUser (oConn, gu_user);
        } catch (com.knowgate.ldap.LDAPException ignore) { }

	if (!oUsr.isNull(DB.tx_main_email))
          oLdapImpl.addUser (oConn, gu_user);

        oLdapImpl.disconnect();
      } // fi (sLdapConnect!="")
      
      // End LDAP synchronization
      // ***************************************************************************

      // ******************************************************
      // Limpiar el cache de passwords, hacer commit y terminar
  
      GlobalCacheClient.expire ("["+gu_workarea+",users]");
      GlobalCacheClient.expire ("["+gu_user+",authstr]");
      GlobalCacheClient.expire ("["+gu_user+",groups]");
      GlobalCacheClient.expire ("["+gu_user+",admin]");
      GlobalCacheClient.expire ("["+gu_user+",user]");
      GlobalCacheClient.expire ("["+gu_user+",poweruser]");
      GlobalCacheClient.expire ("["+gu_user+",guest]");
      GlobalCacheClient.expire ("["+gu_user+",mailbox]");
      GlobalCacheClient.expire ("["+gu_user+",left]");
      GlobalCacheClient.expire ("["+gu_user+",right]");
      for (int a=1; a<=31; a++)
        GlobalCacheClient.expire ("["+gu_user+","+gu_workarea+","+String.valueOf(a)+"]");

      oConn.commit();
  
      if (id_user.equals(gu_user)) {
        iAppMask = com.knowgate.workareas.WorkArea.getUserAppMask(oConn, gu_workarea, gu_user);

        for (int opt=0; opt<10; opt++) {
          GlobalCacheClient.expire ("[" + gu_user + ",options," + String.valueOf(opt) + "]");
          for (int sub=0; sub<10; sub++)
            GlobalCacheClient.expire ("[" + gu_user + ",suboptions," + String.valueOf(sub) + "]");
        } // next
      } // fi (id_user==gu_user)
      
      oConn.close("useredit_modify");
  }
  catch (SQLException e) {
    disposeConnection(oConn,"useredit_modify");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (com.knowgate.ldap.LDAPException e) {
    disposeConnection(oConn,"useredit_modify");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=LDAPException&desc=" + e.getMessage() + "&resume=_back"));
  }  

  if (null==oConn) return;
  
  oConn = null;
%>
<HTML>
  <HEAD>
    <TITLE>Wait...</TITLE>
    <META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
    <META HTTP-EQUIV="Pragma" CONTENT="no-cache"> 
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE='text/javascript'>
      function redirect() {
        window.opener.location = 'domusrs.jsp?id_domain=<%=id_domain%>&n_domain=' + escape('<%=n_domain%>') + '&show=users&maxrows=10&skip=0';
        self.close();
      }
      
<%    if (0!=iAppMask) {
        out.write ("      setCookie(\"appmask\",\"" + String.valueOf(iAppMask) + "\");\n");
        out.write ("      setCookie(\"workarea\",\"" + gu_workarea + "\");\n");
      }

      if (id_user.equals(oUsr.getString(DB.gu_user))) {
        out.write ("      setCookie (\"userid\",\"" + oUsr.getString(DB.gu_user) + "\");");
        out.write ("      setCookie (\"authstr\",\"" + ACL.encript(oUsr.getString(DB.tx_pwd),ENCRYPT_ALGORITHM) + "\");");
      }      
%>
    </SCRIPT>
  </HEAD>
  <BODY onLoad="redirect()"></BODY>
</HTML>
