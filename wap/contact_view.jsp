<%@ page import="com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.dataobjs.DBPersist,com.knowgate.dataobjs.RecentlyUsed,com.knowgate.crm.Contact,com.knowgate.crm.MemberAddress,com.knowgate.hipergate.Address,com.knowgate.hipergate.DBLanguages" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><%@ include file="inc/dbbind.jsp" %><%
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

  final String PAGE_NAME = "contact_view";

  final String gu_contact = request.getParameter("gu_contact");

  Contact oCont = new Contact();
  MemberAddress oMadr = new MemberAddress();
  Address oAddr = new Address();
  String sTitle = null;

  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);

    if (oCont.load(oConn, gu_contact)) {
		  String sGuAddr = DBCommand.queryStr(oConn, "SELECT "+DB.gu_address+" FROM "+DB.k_addresses+" WHERE "+
                                          DB.gu_address + " IN (SELECT " + DB.gu_address +  " FROM " + DB.k_x_contact_addr + " WHERE " +
                                          DB.gu_contact + "='" + gu_contact + "')");
      if (null!=sGuAddr) {
        oMadr.load(oConn, sGuAddr);
        oAddr.load(oConn, sGuAddr);
      }
      
      if (!oCont.isNull(DB.gu_company) && !oCont.isNull(DB.de_title))
        sTitle = DBLanguages.getLookUpTranslation(oConn, DB.k_contacts_lookup, oUser.getString(DB.gu_workarea), DB.de_title, sLanguage, oCont.getString(DB.de_title));
    }

    RecentlyUsed oRecent = new RecentlyUsed (DB.k_contacts_recent, 10, DB.gu_contact, DB.gu_user);
	  DBPersist oItem = new DBPersist (DB.k_contacts_recent, "RecentContact");		
	  oItem.put (DB.gu_contact, oCont.getString(DB.gu_contact));
	  oItem.put (DB.full_name, oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""));
	  oItem.put (DB.gu_user, oUser.getString(DB.gu_user));
	  oItem.put (DB.gu_workarea, oUser.getString(DB.gu_workarea));	
	  if (!oAddr.isNull(DB.nm_company)) oItem.put (DB.nm_company, oAddr.getString(DB.nm_company));	  
	  oRecent.add (oConn, oItem);

		oConn.close(PAGE_NAME);

  } catch (Exception xcpt) {
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+xcpt.getClass().getName()+"&desc=" + xcpt.getMessage() + "&resume=home.jsp"));    
    return;
  }
  
%><?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
"http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <card id="contact_view" title="<%=oCont.getStringNull(DB.tx_name,"")+" "+oCont.getStringNull(DB.tx_surname,"")%>">
    <%=oCont.getStringNull(DB.tx_name,"")+" "+oCont.getStringNull(DB.tx_surname,"")%>
<% if (!oMadr.isNull(DB.nm_commercial) || !oMadr.isNull(DB.nm_legal)) {
     if (sTitle!=null) out.write("<br/>"+sTitle+"\n");
     out.write("<br/><a href=\"company_view.jsp?gu_company="+oCont.getString(DB.gu_company)+"\">"+oMadr.getStringNull(DB.nm_commercial, oMadr.getStringNull(DB.nm_legal,""))+"</a>\n");   
   }
   if (!oMadr.isNull(DB.tx_email))
     out.write("<br/><a href=\"mailto:"+oMadr.getString(DB.tx_email)+"\">"+oMadr.getString(DB.tx_email)+"</a>\n");   
   if (!oMadr.isNull(DB.direct_phone) || !oMadr.isNull(DB.mov_phone) || !oMadr.isNull(DB.work_phone) || !oMadr.isNull(DB.home_phone)) {
     out.write("<br/><table columns=\"2\" align=\"RL\">\n");
     if (!oMadr.isNull(DB.direct_phone))
       out.write("<tr><td><img src=\"img/phoned16.gif\" width=\"16\" height=\"16\" alt=\"Direct Phone\" /></td><td wml:mode=\"nowrap\"><a href=\"callto:"+oMadr.getString(DB.direct_phone)+"\">"+oMadr.getString(DB.direct_phone)+"</a></td></tr>\n");   
     if (!oMadr.isNull(DB.mov_phone))
       out.write("<tr><td><img src=\"img/phonem16.gif\" width=\"16\" height=\"16\" alt=\"Mobile Phone\" /></td><td wml:mode=\"nowrap\"><a href=\"callto:"+oMadr.getString(DB.mov_phone)+"\">"+oMadr.getString(DB.mov_phone)+"</a></td></tr>\n");   
     if (!oMadr.isNull(DB.work_phone))
       out.write("<tr><td><img src=\"img/phonew16.gif\" width=\"16\" height=\"16\" alt=\"Work Phone\" /></td><td wml:mode=\"nowrap\"><a href=\"callto:"+oMadr.getString(DB.work_phone)+"\">"+oMadr.getString(DB.work_phone)+"</a></td></tr>\n");   
     if (!oMadr.isNull(DB.home_phone))
       out.write("<tr><td><img src=\"img/phoneh16.gif\" width=\"16\" height=\"16\" alt=\"Home Phone\" /></td><td wml:mode=\"nowrap\"><a href=\"callto:"+oMadr.getString(DB.home_phone)+"\">"+oMadr.getString(DB.home_phone)+"</a></td></tr>\n");
     out.write("</table>\n");
   }
   if (!oMadr.isNull(DB.nm_street))
     out.write("<br/>"+oAddr.toLocaleString());
%>
    <p><a href="contact_edit.jsp?gu_contact=<%=gu_contact%>">Editar</a></p>
    <p><do type="accept" label="<%=Labels.getString("a_back")%>"><prev/></do> <a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>
  </card>
</wml>
