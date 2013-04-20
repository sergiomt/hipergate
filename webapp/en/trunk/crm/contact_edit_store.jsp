<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.util.*,java.math.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.crm.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.RecentlyUsed" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/customattrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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

  final boolean bEveryContactBelongsToACompany = false;

  if (autenticateSession(GlobalDBBind, request, response)<0) return;  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_company = request.getParameter("gu_company");  
  String nm_company = request.getParameter("nm_company");  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_contact = request.getParameter("gu_contact");
  String id_user = getCookie (request, "userid", null);
  String noreload = nullif(request.getParameter("noreload"),"0");
  String courses = nullif(request.getParameter("courses"),"");

  JDCConnection oConn = GlobalDBBind.getConnection("contact_edit_store");  
  PreparedStatement oStmt = null;
  
  String sOpCode = gu_contact.length()>0 ? "NCON" : "MCON";

  Contact oContact = new Contact();
 
  try {
    loadRequest(oConn, request, oContact);

    if (!oContact.isNull(DB.gu_geozone))
      if (oContact.getString(DB.gu_geozone).length()==0 || oContact.getString(DB.gu_geozone).equals("null"))
        oContact.remove(DB.gu_geozone);

    oConn.setAutoCommit (false);

    Company oCompany = new Company();
    
    if (gu_company.equals("newguid")) {

      oCompany.put(DB.nm_legal, nm_company);
      oCompany.put(DB.gu_workarea, gu_workarea);      
      oCompany.store(oConn);
      
      oContact.replace(DB.gu_company, oCompany.getString(DB.gu_company));
    } else if (bEveryContactBelongsToACompany && gu_company.length()==0) {
      oContact.replace(DB.gu_company, "00000000000000000000000000000000");
      oCompany.put(DB.nm_legal, "N/A");
      oCompany.put(DB.gu_workarea, gu_workarea);
      oCompany.store(oConn);    
    } // fi
    
    oContact.store(oConn);
    
    storeAttributes (request, GlobalCacheClient, oConn, DB.k_contacts_attrs, gu_workarea, oContact.getString(DB.gu_contact));
    /* Inicio I2E 2009-12-09 */
    storeInterest(request, oConn, DB.k_contacts_attrs, oContact.getString(DB.gu_contact));
    /*Fin I2E*/
    
    
    if (courses.length()>0) {
      String[] aCourses = Gadgets.split(courses,',');
      oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_x_course_alumni + " WHERE " + DB.gu_alumni + "=? AND " + DB.gu_acourse + " IN (SELECT " + DB.gu_course + " FROM " + DB.k_academic_courses + " WHERE " + DB.bo_active + "<>0)");
      oStmt.setString(1, oContact.getString(DB.gu_contact));
      oStmt.executeUpdate();
      oStmt.close();
      oStmt = oConn.prepareStatement("INSERT INTO "+DB.k_x_course_alumni+"("+DB.gu_acourse+","+DB.gu_alumni+") VALUES (?,'"+oContact.getString(DB.gu_contact)+"')");
      for (int c=0; c<aCourses.length; c++) {
        oStmt.setString(1, aCourses[c]);
        oStmt.executeUpdate();
      }
      oStmt.close();
    } // fi (courses!="")

    RecentlyUsed oRecent = new RecentlyUsed (DB.k_contacts_recent, 10, DB.gu_contact, DB.gu_user);
	  DBPersist oItem = new DBPersist (DB.k_contacts_recent, "RecentContact");		
	  oItem.put (DB.gu_contact, oContact.getString(DB.gu_contact));
	  oItem.put (DB.full_name, oContact.getStringNull(DB.tx_name,"") + " " + oContact.getStringNull(DB.tx_surname,""));
	  oItem.put (DB.gu_user, id_user);
	  oItem.put (DB.gu_workarea, gu_workarea);	
	  oItem.put (DB.nm_company, nm_company);	  
	  oRecent.add (oConn, oItem);
    
    DBAudit.log(oConn, oContact.ClassId, sOpCode, id_user, oContact.getString(DB.gu_contact), oContact.getStringNull(DB.gu_company,""), 0, 0, oContact.getStringNull(DB.tx_name,"")+" "+oContact.getStringNull(DB.tx_surname,""), request.getParameter("nm_legal"));

    oConn.commit();
        
    oConn.close("contact_edit_store");
  }
  catch (SQLException e) {  
    if (oStmt!=null) { try {oStmt.close(); } catch (Exception ignore) {} }
    disposeConnection(oConn,"contact_edit_store");		
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + oContact.getStringNull(DB.gu_geozone,"NULL") + " " + e.getLocalizedMessage() + "&resume=_back"));
  }  
  
  if (null==oConn) return;  

  oConn = null;

%>
<HTML>
<HEAD>
  <TITLE>Wait...</TITLE>
  <SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>
    <!--    
    if ("<%=noreload%>"=="0")
      window.opener.location.reload(true);
    //-->
  </SCRIPT>  
  <META http-equiv="refresh" content="0; url=contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=<%=n_domain%>&nm_company=<%=Gadgets.URLEncode(nullif(nm_company))%>&gu_contact=<%=oContact.getString(DB.gu_contact)%>&noreload=<%=noreload%>">
</HEAD>
</HTML>
