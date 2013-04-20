<%@ page import="java.util.Iterator,java.math.BigDecimal,java.sql.Types.*,java.util.Date,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.debug.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
    
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_address = request.getParameter("gu_address");
  String ix_address = request.getParameter("ix_address");
  String linktable = request.getParameter("linktable");
  String linkfield = request.getParameter("linkfield");
  String linkvalue = request.getParameter("linkvalue");
  String id_user = getCookie (request, "userid", null);
  String noreload = nullif(request.getParameter("noreload"),"0");
  String tx_previous_email = "";
  String gu_geozone = null;
  
  String sLanguage = getNavigatorLanguage(request);
  
  String sOpCode = gu_address.length()>0 ? "NADR" : "MADR";
    
  JDCConnection oConn = null;  
  Statement oStmt;
  PreparedStatement oUpdt = null;
  PreparedStatement oSelt = null;
  ResultSet oRSet = null;
  
  Address oAddr = new Address();
 
  try {
    oConn = GlobalDBBind.getConnection("addr_edit_store");  
    
    if (gu_address.length()>0) {
      tx_previous_email = DBCommand.queryStr(oConn, "SELECT "+DB.tx_email+" FROM "+DB.k_addresses+" WHERE "+DB.gu_address+"='"+gu_address+"'");
      if (null==tx_previous_email) tx_previous_email = "";
    }

    loadRequest(oConn, request, oAddr);

    oConn.setAutoCommit (false);

    if (ix_address.length()==0) {
      oAddr.put(DB.ix_address, Address.nextLocalIndex(oConn, linktable, linkfield, linkvalue));
    }
    
    oAddr.store(oConn);
    
    // Borrar la dirección anterior y asociar la nueva    
    if (linktable.length()>0) {
      
      if (linktable.equals("k_meetings_lookup")) {
        DBCommand.executeUpdate(oConn, "DELETE FROM " + linktable + " WHERE " + DB.vl_lookup + "='" + oAddr.getString(DB.gu_address) + "' AND " + linkfield + "='" + linkvalue +"'");
        oUpdt = oConn.prepareStatement("INSERT INTO " + linktable + "(" + DB.pg_lookup + "," + DB.id_section + "," + DB.vl_lookup + "," + linkfield + "," + DB.tr_ + Gadgets.join(DBLanguages.SupportedLanguages,",tr_") + ") VALUES (?,?,?,?"+Gadgets.repeat(",?", DBLanguages.SupportedLanguages.length)+")");
        oUpdt.setInt(1, DBLanguages.nextLookuUpProgressive(oConn, linktable, linkvalue, "gu_address"));
        oUpdt.setString(2, "gu_address");
        oUpdt.setString(3, oAddr.getString(DB.gu_address));
        oUpdt.setString(4, linkvalue);
				for (int l=0; l<DBLanguages.SupportedLanguages.length; l++)
          oUpdt.setString(l+5, Gadgets.left(oAddr.toLocaleString(),50));
        oUpdt.executeUpdate();
        oUpdt.close();
      } else {
        DBCommand.executeUpdate(oConn, "DELETE FROM " + linktable + " WHERE " + DB.gu_address + "='" + oAddr.getString(DB.gu_address) + "' AND " + linkfield + "='" + linkvalue +"'");
        DBCommand.executeUpdate(oConn, "INSERT INTO " + linktable + "(" + DB.gu_address + "," + linkfield + ") VALUES ('" + oAddr.getString(DB.gu_address) + "','" + linkvalue + "')");
      }

      RecentlyUsed oRecent;
      DBPersist oItem;
      
      if (linktable.equals(DB.k_x_company_addr)) {

        oRecent = new RecentlyUsed (DB.k_companies_recent, 10, DB.gu_company, DB.gu_user);

	      oItem = new DBPersist (DB.k_companies_recent, "RecentCompany");
	      oItem.put (DB.gu_company, linkvalue);
	      oItem.put (DB.gu_user, id_user);
	      oItem.put (DB.gu_workarea, gu_workarea);
	      oItem.put (DB.nm_company, nullif(request.getParameter("nm_company")));
	      if (oAddr.getItemMap().containsKey(DB.work_phone))
	        oItem.put (DB.work_phone, oAddr.get(DB.work_phone));
	      if (oAddr.getItemMap().containsKey(DB.tx_email))
	        oItem.put (DB.tx_email, oAddr.get(DB.tx_email));
	  
	      oRecent.add (oConn, oItem);

				if (DebugFile.trace)
				  DebugFile.writeln("<JSP:tx_previous_email="+tx_previous_email);

      	if (!tx_previous_email.equals(nullif(request.getParameter(DB.tx_email)))) {
      	  if (oAddr.getStringNull(DB.tx_email,"").length()==0) {
				    if (DebugFile.trace)
				      DebugFile.writeln("<JSP:Connection.prepareStatement(UPDATE "+DB.k_x_list_members+" SET "+DB.bo_active+"=0 WHERE "+DB.tx_email+"='"+tx_previous_email+"' AND "+DB.gu_company+"='"+linkvalue+"')");
      	    oUpdt = oConn.prepareStatement("UPDATE "+DB.k_x_list_members+" SET "+DB.bo_active+"=0 WHERE "+DB.tx_email+"=? AND "+DB.gu_company+"=?");
      	    oUpdt.setString(1, tx_previous_email);
      	    oUpdt.setString(2, linkvalue);
      	  } else {
      	    if (DebugFile.trace)
				      DebugFile.writeln("<JSP:Connection.prepareStatement(UPDATE "+DB.k_x_list_members+" SET "+DB.tx_email+"='"+oAddr.getStringNull(DB.tx_email,"")+"' WHERE "+DB.tx_email+"='"+tx_previous_email+"' AND "+DB.gu_company+"='"+linkvalue+"'");
      	    oUpdt = oConn.prepareStatement("UPDATE "+DB.k_x_list_members+" SET "+DB.tx_email+"=? WHERE "+DB.tx_email+"=? AND "+DB.gu_company+"=?");
      	    oUpdt.setString(1, oAddr.getStringNull(DB.tx_email,""));
      	    oUpdt.setString(2, tx_previous_email);
      	    oUpdt.setString(3, linkvalue);
      	  }
      	  oUpdt.executeUpdate();
      	  oUpdt.close();
      	} // fi (tx_previous_email!=tx_email)

				if (!oAddr.isNull(DB.nm_state)) {
          if (null==DBCommand.queryStr(oConn, "SELECT "+DB.gu_geozone+" FROM "+DB.k_companies+" WHERE "+DB.gu_company+"='"+linkvalue+"'")) {
            oSelt = oConn.prepareStatement("SELECT "+DB.gu_term+" FROM "+DB.k_thesauri+" WHERE "+DB.id_domain+"=? AND "+DB.id_language+"=? AND "+DB.tx_term+"=?");
            oSelt.setInt   (1, Integer.parseInt(id_domain));
            oSelt.setString(2, sLanguage);
            oSelt.setString(3, oAddr.getString(DB.nm_state));
            oRSet = oSelt.executeQuery();
            if (oRSet.next())
              gu_geozone = oRSet.getString(1);
            else
            	gu_geozone = null;
            oRSet.close();
            oSelt.close();
            if (null!=gu_geozone) {
              DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_companies+" SET "+DB.gu_geozone+"='"+gu_geozone+"' WHERE "+DB.gu_company+"='"+linkvalue+"'");
            } // fi (matching gu_term was found)
          } // fi (gu_geozone IS NULL)
        } // fi (nm_state IS NOT NULL)
      }

      else if (linktable.equals(DB.k_x_contact_addr)) {
        
        oRecent = new RecentlyUsed (DB.k_contacts_recent, 10, DB.gu_contact, DB.gu_user);

	      oItem = new DBPersist (DB.k_contacts_recent, "RecentContact");
	
	      DBPersist oCont = new DBPersist (DB.k_contacts, "Contact");
	      oCont.load (oConn, new Object[]{linkvalue});
	
	      oItem.put (DB.gu_contact, oCont.getString(DB.gu_contact));
	      oItem.put (DB.full_name, oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""));
	      oItem.put (DB.gu_user, id_user);
	      oItem.put (DB.gu_workarea, gu_workarea);
	      oItem.put (DB.nm_company, nullif(request.getParameter("nm_company")));

	      if (oAddr.getItemMap().containsKey(DB.work_phone))
	        oItem.put (DB.work_phone, oAddr.get(DB.work_phone));

	      if (oAddr.getItemMap().containsKey(DB.tx_email))
	        oItem.put (DB.tx_email, oAddr.get(DB.tx_email));
	  
	      oRecent.add (oConn, oItem);
				
				if (DebugFile.trace)
				  DebugFile.writeln("<JSP:tx_previous_email="+tx_previous_email);

      	if (!tx_previous_email.equals(nullif(request.getParameter(DB.tx_email)))) {
      	  if (oAddr.getStringNull(DB.tx_email,"").length()==0) {
				    if (DebugFile.trace)
				      DebugFile.writeln("<JSP:Connection.prepareStatement(UPDATE "+DB.k_x_list_members+" SET "+DB.bo_active+"=0 WHERE "+DB.tx_email+"='"+tx_previous_email+"' AND "+DB.gu_contact+"='"+linkvalue+"')");
      	    oUpdt = oConn.prepareStatement("UPDATE "+DB.k_x_list_members+" SET "+DB.bo_active+"=0 WHERE "+DB.tx_email+"=? AND "+DB.gu_contact+"=?");
      	    oUpdt.setString(1, tx_previous_email);
      	    oUpdt.setString(2, linkvalue);
      	  } else {
      	    if (DebugFile.trace)
				      DebugFile.writeln("<JSP:Connection.prepareStatement(UPDATE "+DB.k_x_list_members+" SET "+DB.tx_email+"='"+oAddr.getStringNull(DB.tx_email,"")+"' WHERE "+DB.tx_email+"='"+tx_previous_email+"' AND "+DB.gu_contact+"='"+linkvalue+"'");
      	    oUpdt = oConn.prepareStatement("UPDATE "+DB.k_x_list_members+" SET "+DB.tx_email+"=? WHERE "+DB.tx_email+"=? AND "+DB.gu_contact+"=?");
      	    oUpdt.setString(1, oAddr.getStringNull(DB.tx_email,""));
      	    oUpdt.setString(2, tx_previous_email);
      	    oUpdt.setString(3, linkvalue);
      	  }
      	  oUpdt.executeUpdate();
      	  oUpdt.close();
      	} // fi (tx_previous_email!=tx_email)

				if (!oAddr.isNull(DB.nm_state)) {
          if (null==DBCommand.queryStr(oConn, "SELECT "+DB.gu_geozone+" FROM "+DB.k_contacts+" WHERE "+DB.gu_contact+"='"+linkvalue+"'")) {
            oSelt = oConn.prepareStatement("SELECT "+DB.gu_term+" FROM "+DB.k_thesauri+" WHERE "+DB.id_domain+"=? AND "+DB.id_language+"=? AND "+DB.tx_term+"=?");
            oSelt.setInt   (1, Integer.parseInt(id_domain));
            oSelt.setString(2, sLanguage);
            oSelt.setString(3, oAddr.getString(DB.nm_state));
            oRSet = oSelt.executeQuery();
            if (oRSet.next())
              gu_geozone = oRSet.getString(1);
            else
            	gu_geozone = null;
            oRSet.close();
            oSelt.close();
            if (null!=gu_geozone) {
              DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_contacts+" SET "+DB.gu_geozone+"='"+gu_geozone+"' WHERE "+DB.gu_contact+"='"+linkvalue+"'");
            } // fi (matching gu_term was found)
          } // fi (gu_geozone IS NULL)
        } // fi (nm_state IS NOT NULL)

      }
     
      DBAudit.log(oConn, Address.ClassId, sOpCode, id_user, oAddr.getString(DB.gu_address), linkvalue, 0, 0, null, null);
    }
    else
      DBAudit.log(oConn, Address.ClassId, sOpCode, id_user, oAddr.getString(DB.gu_address), null, 0, 0, null, null);
                    
    // ***************************************************************************
    // Check whether or not there is an active LDAP server and synchronize with it
    
    String sLdapConnect = Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapconnect", "");

    if (linktable.equals(DB.k_x_contact_addr) && sLdapConnect.length()>0) {
      Class oLdapCls = Class.forName(Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapclass", "com.knowgate.ldap.LDAPNovell"));

      com.knowgate.ldap.LDAPModel oLdapImpl = (com.knowgate.ldap.LDAPModel) oLdapCls.newInstance();

      oLdapImpl.connectAndBind(Environment.getProfile(GlobalDBBind.getProfileName()));
      
      // If address already exists delete it before re-inserting
      if (gu_address.length()>0) {
        try {
          oLdapImpl.deleteAddress (oConn, oAddr.getString(DB.gu_address));
        } catch (com.knowgate.ldap.LDAPException ignore) { }
      }

      if (!oAddr.isNull(DB.tx_email))
        oLdapImpl.addAddress (oConn, oAddr.getString(DB.gu_address));

      oLdapImpl.disconnect();
    } // fi (linktable==k_x_contact_addr && ldapconnect!="")

    // End LDAP synchronization
    // ***************************************************************************

    oConn.commit();

    oConn.close("addr_edit_store");    
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"addr_edit_store"); // fi (isClosed)
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  } // catch()
  catch (com.knowgate.ldap.LDAPException e) {  
    disposeConnection(oConn,"addr_edit_store"); // fi (isClosed)
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=LDAPException&desc=" + e.getMessage() + "&resume=_back"));
  } // catch()
  
  if (null==oConn) return;
  
  oAddr = null;
  oConn = null;  
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Save Address</TITLE>
  <SCRIPT TYPE="text/javascript">
    <!--      
      if ("<%=noreload%>"=="0") {
        if (window.parent.opener)
          window.parent.opener.location.reload(true);
      }
      window.parent.close();      
    //-->
  </SCRIPT>
</HEAD>
</HTML>