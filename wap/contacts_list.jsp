<%@ page import="com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %>
<%@ include file="inc/dbbind.jsp" %><%
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

  final String PAGE_NAME = "contacts_list";

  final int iMaxRows = 100;

  String sFind = request.getParameter("find");

  String sSecurityFilter = " AND (b.bo_restricted=0 OR EXISTS (SELECT x."+DB.gu_acl_group+" FROM "+DB.k_x_group_contact+" x WHERE x." +
                           DB.gu_contact+"=b."+DB.gu_contact+" AND x."+DB.gu_acl_group+" IN ("+oUser.getStringNull("groups","")+")))" +
                           " AND (b." + DB.bo_private + "=0 OR b." + DB.gu_writer + "=? ) ";
  DBSubset oContacts = null;
  int iContacts = 0;

  try {

    Object[] aFind = new Object[] { oUser.getString(DB.gu_workarea),
  															    oUser.getString(DB.gu_workarea),
  															    sFind + "%", "%" + sFind + "%",
  															    oUser.getString(DB.gu_user) };

    oConn = GlobalDBBind.getConnection(PAGE_NAME);
    
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
          oContacts = new DBSubset (DB.v_contact_company_all + " b, " + DB.k_contacts_lookup + " l",
      	      		      "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal,
      	      			    "b." + DB.de_title + "=l." + DB.vl_lookup + "(+) AND (l." + DB.gu_owner + "=? OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "=? AND (b.tx_name LIKE ? OR b.tx_surname LIKE ?) " +
      	      			    sSecurityFilter + " ORDER BY 2", iMaxRows);
    } else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
                			  " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
      	      		      "b." + DB.gu_contact + ",CONCAT(COALESCE(b." + DB.tx_surname + ",''),', ',COALESCE(b." + DB.tx_name + ",'')), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal,
      	      			    "(l." + DB.gu_owner + "=? OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) AND b." + DB.gu_workarea + "=? AND (b.tx_name " + DBBind.Functions.ILIKE + " ? OR b.tx_surname " + DBBind.Functions.ILIKE + " ?) " +
      	      			    sSecurityFilter + " ORDER BY 2", iMaxRows);
    } else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
          aFind[2] = Gadgets.accentsToPosixRegEx(sFind) + ".*";
          aFind[3] = ".*" + Gadgets.accentsToPosixRegEx(sFind) + ".*";
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
                			    " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
      	      		        "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal,
      	      			      "(l." + DB.gu_owner + "=? OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) " +
      	      			      "AND b." + DB.gu_workarea + "=? AND (b.tx_name ~* ? OR b.tx_surname ~* ?) " +
      	      			      sSecurityFilter + " ORDER BY 2", iMaxRows);
    } else {
          oContacts = new DBSubset (DB.v_contact_company_all + " b " +
                			    " LEFT OUTER JOIN " + DB.k_contacts_lookup + " l ON l." + DB.vl_lookup + "=b." + DB.de_title,
      	      		        "b." + DB.gu_contact + "," + DBBind.Functions.ISNULL + "(b." + DB.tx_surname + ",'') " + DBBind.Functions.CONCAT + " ', ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(b." + DB.tx_name + ",''), l." + DB.tr_ + sLanguage + ",b." + DB.gu_company +",b." + DB.nm_legal,
      	      			      "(l." + DB.gu_owner + "=? OR l." + DB.gu_owner + " IS NULL) AND (l." + DB.id_section + "='de_title' OR l." + DB.id_section + " IS NULL) " +
      	      			      "AND b." + DB.gu_workarea + "=? AND (b.tx_name " + DBBind.Functions.ILIKE + " ? OR b.tx_surname " + DBBind.Functions.ILIKE + " ?) " +
      	      			      sSecurityFilter + " ORDER BY 2", iMaxRows);
    }
    oContacts.setMaxRows(iMaxRows);
    iContacts = oContacts.load(oConn, aFind);

		oConn.close(PAGE_NAME);
		
  } catch (Exception xcpt) {
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+xcpt.getClass().getName()+"&desc=" + xcpt.getMessage() + "&resume=home.jsp"));    
  }

%><?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
"http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <card id="contacts_list" title="<%=Labels.getString("title_contacts")%>">
<% for (int c=0; c<iContacts; c++) {
     out.write("<a href=\"contact_view.jsp?gu_contact="+oContacts.getString(0,c)+"\">"+oContacts.getString(1,c)+"</a><br/>\n");
   } // next
%>
    <p><a href="contact_edit.jsp"><%=Labels.getString("a_contact_new")%></a></p>
	  <p><do type="accept" label="<%=Labels.getString("a_back")%>"><prev/></do> <a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>

  </card>
</wml>
