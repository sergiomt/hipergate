<%@ page import="com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.crm.Contact,com.knowgate.crm.Company,com.knowgate.hipergate.Address,com.knowgate.misc.Gadgets" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%@ include file="inc/dbbind.jsp" %><%
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

  final String PAGE_NAME = "contact_edit";
  final String F = "*M";
  final String gu_contact = request.getParameter("gu_contact");
  Contact oCont = new Contact();
  Company oComp = new Company();
  Address oAddr = new Address();
  String sTitleLookUp = "";
  String sStreetLookUp = "";
  String sCountriesLookUp = "";
  boolean bAlreadyExists = false;
  String N = "";
  
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);

		if (null!=gu_contact) bAlreadyExists = oCont.load(oConn, gu_contact);
	  
    if (bAlreadyExists) {
      N = "_"+gu_contact;
		  if (!oCont.isNull(DB.gu_company)) {
		    oComp.load(oConn, oCont.getString(DB.gu_company));
		  }
		  String sGuAddr = DBCommand.queryStr(oConn, "SELECT "+DB.gu_address+" FROM "+DB.k_addresses+" WHERE "+
                                          DB.gu_address + " IN (SELECT " + DB.gu_address +  " FROM " + DB.k_x_contact_addr + " WHERE " +
                                          DB.gu_contact + "='" + oCont.getString(DB.gu_contact) + "')");
      if (null!=sGuAddr) {
        oAddr.load(oConn, sGuAddr);
      }
    } else {
      N = "_"+Gadgets.generateRandomId(6, "123456789", Character.UNASSIGNED);
    }

    sStreetLookUp = Gadgets.replace(Gadgets.replace(GlobalDBLang.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, oUser.getString(DB.gu_workarea), DB.tp_street, sLanguage),"<OPTION VALUE=", "<option value="),"</OPTION>","</option>");
    sTitleLookUp  = Gadgets.replace(Gadgets.replace(GlobalDBLang.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_contacts_lookup, oUser.getString(DB.gu_workarea), DB.de_title, sLanguage),"<OPTION VALUE=", "<option value="),"</OPTION>","</option>");
    sCountriesLookUp = Gadgets.replace(Gadgets.replace(GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage),"<OPTION VALUE=", "<option value="),"</OPTION>","</option>");

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
  <head><meta http-equiv="cache-control" content="no-cache"/></head>
  <card id="contact_view">
    <%=Labels.getString("lbl_name")%><br/>
    <input type="text" name="name<%=N%>" format="<%=F%>" maxlength="100" value="<%=oCont.getStringNull(DB.tx_name,"")%>" /><br/>
    <%=Labels.getString("lbl_surname")%><br/>
    <input type="text" name="surname<%=N%>"  format="<%=F%>" maxlength="100" emptyok="true" value="<%=oCont.getStringNull(DB.tx_surname,"")%>" /><br/>
    <%=Labels.getString("lbl_company")%><br/>
    <input type="text" name="company<%=N%>" format="<%=F%>" maxlength="70" value="<%=oComp.getStringNull(DB.nm_legal,"")%>" /><br/>
    <select name="title<%=N%>" title="<%=Labels.getString("lbl_title")%>" value="<%=oCont.getStringNull(DB.de_title,"")%>"><%=sTitleLookUp%></select><br/>
    <%=Labels.getString("lbl_email")%><br/>
    <input type="text" name="mail<%=N%>" format="*x" maxlength="100" emptyok="true" value="<%=oAddr.getStringNull(DB.tx_email,"")%>" /><br/>
  <% if (bAlreadyExists) { %>
    <%=Labels.getString("lbl_phone_mobile")%><br/>
    <input type="text" name="phone_mobile<%=N%>" format="1n*N" maxlength="16" emptyok="true" value="<%=oAddr.getStringNull(DB.mov_phone,"")%>" /><br/>
    <%=Labels.getString("lbl_phone_work")%><br/>
    <input type="text" name="phone_work<%=N%>" format="1n*N" maxlength="16" emptyok="true" value="<%=oAddr.getStringNull(DB.work_phone,"")%>" /><br/>
    <%=Labels.getString("lbl_phone_direct")%><br/>
    <input type="text" name="phone_direct<%=N%>" format="1n*N" maxlength="16" emptyok="true" value="<%=oAddr.getStringNull(DB.direct_phone,"")%>" /><br/>
    <%=Labels.getString("lbl_phone_home")%><br/>
    <input type="text" name="phone_home<%=N%>" format="1n*N" maxlength="16" emptyok="true" value="<%=oAddr.getStringNull(DB.home_phone,"")%>" /><br/>
  <% } else { %>
    <select name="ptype" title="<%=Labels.getString("lbl_phone")%>" value="mov">
      <option value="mov"><%=Labels.getString("lbl_phone_mobile")%></option>
      <option value="work"><%=Labels.getString("lbl_phone_work")%></option>
      <option value="direct"><%=Labels.getString("lbl_phone_direct")%></option>
      <option value="home"><%=Labels.getString("lbl_phone_home")%></option>
    </select><br/>
    <input type="text" name="phone" format="1n*N" maxlength="16" emptyok="true" /><br/>
  <% } %>
    <select name="tstreet<%=N%>" value="<%=oAddr.getStringNull(DB.tp_street,"")%>"><option value=""></option><%=sStreetLookUp%></select><br/>
    <%=Labels.getString("lbl_street_nm")%><br/>
    <input type="text" name="nstreet<%=N%>" format="<%=F%>" maxlength="100" emptyok="true" value="<%=oAddr.getStringNull(DB.nm_street,"")%>" /><br/>
    <%=Labels.getString("lbl_street_nu")%> / <%=Labels.getString("lbl_flat_nu")%><br/>
    <input type="text" name="building<%=N%>" format="<%=F%>" size="4" maxlength="16" emptyok="true" value="<%=oAddr.getStringNull(DB.nu_street,"")%>" /> / <input type="text" name="flat<%=N%>" format="<%=F%>" size="8" maxlength="16" emptyok="true" value="<%=oAddr.getStringNull(DB.tx_addr1,"")%>" /><br/>
    <%=Labels.getString("lbl_street_ex")%><br/>
    <input type="text" name="exaddr<%=N%>" format="*M" maxlength="100" emptyok="true" value="<%=oAddr.getStringNull(DB.tx_addr2,"")%>" /><br/>
    <%=Labels.getString("lbl_zipcode")%><br/>
    <input type="text" name="zcode<%=N%>" format="*M" maxlength="30" emptyok="true" value="<%=oAddr.getStringNull(DB.zipcode,"")%>" /><br/>
    <%=Labels.getString("lbl_city")%><br/>
    <input type="text" name="city<%=N%>" format="<%=F%>" maxlength="50" emptyok="true" value="<%=oAddr.getStringNull(DB.mn_city,"")%>" /><br/>
    <%=Labels.getString("lbl_state")%><br/>
    <input type="text" name="state<%=N%>" format="<%=F%>" maxlength="50" emptyok="true" value="<%=oAddr.getStringNull(DB.nm_state,"")%>" /><br/>
    <select name="country<%=N%>" title="<%=Labels.getString("lbl_country")%>" value="<%=oAddr.getStringNull(DB.id_country,sLanguage)%>"><option value=""></option><%=sCountriesLookUp%></select><br/>

	  <table columns="2" align="LR" width="100%">
	    <tr>
	    	<td>
          <anchor><%=Labels.getString("a_save")%>
            <go href="contact_store.jsp" accept-charset="UTF-8" method="post">
              <postfield name="gu_contact" value="<%=oCont.getStringNull(DB.gu_contact,"")%>"/>
              <postfield name="gu_company" value="<%=oCont.getStringNull(DB.gu_company,"")%>"/>
              <postfield name="gu_address" value="<%=oAddr.getStringNull(DB.gu_address,"")%>"/>
              <postfield name="tx_name" value="$(name<%=N%>)"/>
              <postfield name="tx_surname" value="$(surname<%=N%>)"/>
              <postfield name="nm_company" value="$(company<%=N%>)"/>
              <postfield name="de_title" value="$(title<%=N%>)"/>
              <postfield name="tx_email" value="$(mail<%=N%>)"/>
          <% if (bAlreadyExists) { %>
              <postfield name="mov_phone" value="$(phone_mobile<%=N%>)"/>
              <postfield name="work_phone" value="$(phone_work<%=N%>)"/>
              <postfield name="direct_phone" value="$(phone_direct<%=N%>)"/>
              <postfield name="home_phone" value="$(phone_home<%=N%>)"/>
          <% } else { %>
              <postfield name="tp_phone" value="$(ptype)"/>
              <postfield name="nu_phone" value="$(phone)"/>
          <% } %>
              <postfield name="tp_street" value="$(tstreet<%=N%>)"/>
              <postfield name="nm_street" value="$(nstreet<%=N%>)"/>
              <postfield name="nu_street" value="$(building<%=N%>)" />
              <postfield name="tx_addr1" value="$(flat<%=N%>)" />
              <postfield name="tx_addr2" value="$(exaddr<%=N%>)"/>
              <postfield name="zipcode" value="$(zcode<%=N%>)"/>
              <postfield name="mn_city" value="$(city<%=N%>)"/>
              <postfield name="nm_state" value="$(state<%=N%>)"/>
              <postfield name="id_country" value="$(country<%=N%>)"/>
            </go>
          </anchor>
        </td>
        <td>
        	<% if (gu_contact!=null) { %><a href="contact_delete.jsp?gu_contact=<%=gu_contact%>"><%=Labels.getString("a_delete")%></a><% } %>
        </td>
      </tr>
    </table>
    <p><a href="home.jsp"><%=Labels.getString("a_home")%></a> <do type="accept" label="<%=Labels.getString("a_back")%>"><prev/></do> <a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>
  </card>
</wml>
