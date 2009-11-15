<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.Contact,com.knowgate.crm.Company,com.knowgate.hipergate.Address,com.knowgate.hipergate.Order,com.knowgate.hipergate.RecentlyUsed,com.knowgate.hipergate.Product" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sLanguage = getNavigatorLanguage(request);
      
  String id_domain = request.getParameter("gu_workarea");
  String gu_workarea = request.getParameter("gu_workarea");
  short tp_client = Short.parseShort(request.getParameter("tp_client"));
  boolean bo_same_addr = request.getParameter("chk_same_addr").equals("chk_same_addr");
  String id_user = getCookie (request, "userid", null);
        
  Contact oCnt = new Contact();
  Company oCmp = new Company();
  Address oAd1 = new Address();
  Address oAd2 = null;
  Address oAdf;
  Order oOrd = new Order();
  DBPersist oItm;
  
  JDCConnection oConn = null;
  PreparedStatement oSelt;
  ResultSet = oRSet;

  try {
    oConn = GlobalDBBind.getConnection("order_for_new_client_store"); 
  
    oConn.setAutoCommit (false);

		oAd1.put(DB.gu_workarea, gu_workarea);
		oAd1.put(DB.ix_address, 1);
		oAd1.put(DB.gu_user, id_user);
		oAd1.put(DB.tp_location, "ENVIO");
		oAd1.put(DB.nm_company, request.getParameter("nm_company"));
		oAd1.put(DB.tp_street, request.getParameter("a1_tp_street"));
		oAd1.put(DB.nm_street, request.getParameter("a1_nm_street"));
		oAd1.put(DB.nu_street, request.getParameter("a1_nu_street"));
		oAd1.put(DB.tx_addr1, request.getParameter("a1_tx_addr1"));
		oAd1.put(DB.tx_addr2, request.getParameter("a1_tx_addr2"));
		oAd1.put(DB.id_country, request.getParameter("a1_id_country"));
		oAd1.put(DB.nm_country, request.getParameter("a1_nm_country"));
		oAd1.put(DB.id_state, request.getParameter("a1_id_state"));
		oAd1.put(DB.nm_state, request.getParameter("a1_nm_state"));
		oAd1.put(DB.mn_city, request.getParameter("a1_mn_city"));
		oAd1.put(DB.work_phone, request.getParameter("a1_fixed_phone"));
		oAd1.put(DB.mov_phone, request.getParameter("a1_mobile_phone"));
		oAd1.put(DB.fax_phone, request.getParameter("a1_fax_phone"));
		oAd1.put(DB.tx_email, request.getParameter("a1_tx_email"));
		oAd1.put(DB.contact_person, request.getParameter("contact_person"));
	  oAd1.store(oConn);

	  if (!bo_same_addr) {
	    oAd2 = new Address();
		  oAd2.put(DB.gu_workarea, gu_workarea);
		  oAd2.put(DB.ix_address, 2);
		  oAd2.put(DB.gu_user, id_user);
		  oAd2.put(DB.tp_location, "FACTURACION");
		  oAd2.put(DB.nm_company, request.getParameter("nm_company"));
		  oAd2.put(DB.tp_street, request.getParameter("a2_tp_street"));
		  oAd2.put(DB.nm_street, request.getParameter("a2_nm_street"));
		  oAd2.put(DB.nu_street, request.getParameter("a2_nu_street"));
		  oAd2.put(DB.tx_addr1, request.getParameter("a2_tx_addr1"));
		  oAd2.put(DB.tx_addr2, request.getParameter("a2_tx_addr2"));
		  oAd2.put(DB.id_country, request.getParameter("a2_id_country"));
		  oAd2.put(DB.nm_country, request.getParameter("a2_nm_country"));
		  oAd2.put(DB.id_state, request.getParameter("a2_id_state"));
		  oAd2.put(DB.nm_state, request.getParameter("a2_nm_state"));
		  oAd2.put(DB.mn_city, request.getParameter("a2_mn_city"));
		  oAd2.put(DB.work_phone, request.getParameter("a2_fixed_phone"));
		  oAd2.put(DB.mov_phone, request.getParameter("a2_mobile_phone"));
		  oAd2.put(DB.fax_phone, request.getParameter("a2_fax_phone"));
		  oAd2.put(DB.tx_email, request.getParameter("a2_tx_email"));
		  oAd2.put(DB.contact_person, request.getParameter("contact_person"));
	    oAd2.store(oConn);
	  }
		
    switch (tp_client) {
		  case Contact.ClassId:
		    oCnt.put(DB.gu_writer, id_user);
		    oCnt.put(DB.gu_workarea, request.getParameter("gu_workarea"));
		    oCnt.put(DB.bo_restricted, (short) 0);
		    oCnt.put(DB.bo_private, (short) 0);
		    oCnt.put(DB.nu_notes, 0);
		    oCnt.put(DB.nu_attachs, 0);

		    oCnt.put(DB.gu_workarea, request.getParameter("gu_workarea"));
		    oCnt.put(DB.tx_name, request.getParameter("tx_name"));
		    oCnt.put(DB.tx_surname, request.getParameter("tx_surname"));
		    oCnt.put(DB.sn_passport, request.getParameter("sn_passport"));
		    if (request.getParameter("gu_company").length()>0) {

          if (request.getParameter("gu_company").equals("newguid")) {
            oCmp.put(DB.nm_legal, request.getParameter("nm_company"));
            oCmp.put(DB.gu_workarea, gu_workarea);      
            oCmp.store(oConn);
		        oCnt.put(DB.gu_company, oCmp.getString(DB.gu_company));
		      } else {
		        oCnt.put(DB.gu_company, request.getParameter("gu_company"));
		      }
		    } else if (bEveryContactBelongsToACompany) {
          oCnt.replace(DB.gu_company, "00000000000000000000000000000000");
          oCmp.put(DB.nm_legal, "N/A");
          oCmp.put(DB.gu_workarea, gu_workarea);
          oCmp.store(oConn);		    
		    }
		    oCnt.store(oConn);
		    DBAudit.log(oConn, oCnt.ClassId, "NCON", id_user, oCnt.getString(DB.gu_contact), null, 0, 0, request.getParameter("nm_company"), null);

				oCnt.addAddress(oConn, oAd1.getString(DB.gu_address));
				if (oAd2!=null) oCnt.addAddress(oConn, oAd2.getString(DB.gu_address));
				oAdf = (oAd2==null ? oAd1 : oAd2);
				
				if (!oAdf.isNull(DB.nm_state)) {
          if (null==DBCommand.queryStr(oConn, "SELECT "+DB.gu_geozone+" FROM "+DB.k_contacts+" WHERE "+DB.gu_contact+"='"+oCnt.getString(DB.gu_contact)+"'")) {
            oSelt = oConn.prepareStatement("SELECT "+DB.gu_term+" FROM "+DB.k_thesauri+" WHERE "+DB.id_domain+"=? AND "+DB.id_language+"=? AND "+DB.tx_term+"=?");
            oSelt.setInt   (1, Integer.parseInt(id_domain));
            oSelt.setString(2, sLanguage);
            oSelt.setString(3, oAdf.getString(DB.nm_state));
            oRSet = oSelt.executeQuery();
            if (oRSet.next())
              DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_contacts+" SET "+DB.gu_geozone+"='"+gu_geozone+"' WHERE "+DB.gu_contact+"='"+oCnt.getString(DB.gu_contact)+"'");
            oRSet.close();
            oSelt.close();
          } // fi (gu_geozone IS NULL)
        } // fi (nm_state IS NOT NULL)

		    oOrd.put(DB.id_legal, request.getParameter("sn_passport"));
		    oOrd.put(DB.gu_contact, oCnt.getString(DB.gu_contact));
		    oOrd.put(DB.nm_client, oCnt.getStringNull(DB.tx_name,"") + " " + oCnt.getStringNull(DB.tx_surname,""));

        // *********************************
        // Add Contact to Recently Used list

        RecentlyUsed oRecent = new RecentlyUsed (DB.k_contacts_recent, 10, DB.gu_contact, DB.gu_user);

        oItm = new DBPersist (DB.k_contacts_recent, "RecentContact");

        oItm.put (DB.gu_contact, oCnt.getString(DB.gu_contact));
        oItm.put (DB.full_name, oCnt.getStringNull(DB.tx_name,"") + " " + oCnt.getStringNull(DB.tx_surname,""));
        oItm.put (DB.gu_user, id_user);
        oItm.put (DB.gu_workarea, gu_workarea);    
        oItm.put (DB.nm_company, request.getParameter("nm_company"));
        oRecent.add (oConn, oItm);

		    break;
		  case Company.ClassId:
		    oCmp.put(DB.gu_writer, id_user);
		    oCnt.put(DB.bo_restricted, (short) 0);
		    oCmp.put(DB.gu_workarea, request.getParameter("gu_workarea"));
		    oCmp.put(DB.nm_legal, request.getParameter("nm_company"));
		    oCmp.put(DB.nm_commercial, request.getParameter("nm_company"));
		    oCmp.put(DB.id_legal, request.getParameter("id_legal"));
		    oCmp.store(oConn);
		    DBAudit.log(oConn, oCmp.ClassId, "NCOM", id_user, oCmp.getString(DB.gu_company), null, 0, 0, request.getParameter("nm_company"), null);

				oCmp.addAddress(oConn, oAd1.getString(DB.gu_address));
				if (oAd2!=null) oCmp.addAddress(oConn, oAd2.getString(DB.gu_address));
				oAdf = (oAd2==null ? oAd1 : oAd2);

				if (!oAdf.isNull(DB.nm_state)) {
          if (null==DBCommand.queryStr(oConn, "SELECT "+DB.gu_geozone+" FROM "+DB.k_companies+" WHERE "+DB.gu_company+"='"+oCmp.getString(DB.gu_company)+"'")) {
            oSelt = oConn.prepareStatement("SELECT "+DB.gu_term+" FROM "+DB.k_thesauri+" WHERE "+DB.id_domain+"=? AND "+DB.id_language+"=? AND "+DB.tx_term+"=?");
            oSelt.setInt   (1, Integer.parseInt(id_domain));
            oSelt.setString(2, sLanguage);
            oSelt.setString(3, oAdf.getString(DB.nm_state));
            oRSet = oSelt.executeQuery();
            if (oRSet.next())
              DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_companies+" SET "+DB.gu_geozone+"='"+gu_geozone+"' WHERE "+DB.gu_company+"='"+oCmp.getString(DB.gu_company)+"'");
            oRSet.close();
            oSelt.close();
          } // fi (gu_geozone IS NULL)
        } // fi (nm_state IS NOT NULL)
		    
		    oOrd.put(DB.id_legal, request.getParameter("id_legal"));
		    oOrd.put(DB.gu_company, oCnt.getString(DB.gu_company));
		    oOrd.put(DB.nm_client, request.getParameter("nm_company"));

		    break;
    }

	  Product oPrd = new Product(oConn, request.getParameter("gu_product"));
	  
    oOrd.put(DB.gu_workarea, gu_workarea);
    oOrd.put(DB.gu_shop, request.getParameter("gu_shop"));
    oOrd.put(DB.id_currency, oPrd.getStringNull(DB.id_currency, "999"));
    oOrd.put(DB.de_order, request.getParameter("de_order"));
    oOrd.put(DB.bo_active, (short) 0);
    oOrd.put(DB.gu_ship_addr, oAd1.getString(DB.gu_address));
    if (null==oAd2)
      oOrd.put(DB.gu_bill_addr, oAd1.getString(DB.gu_address));
    else
      oOrd.put(DB.gu_bill_addr, oAd2.getString(DB.gu_address));
    oOrd.store(oConn);
    
    oOrd.addProduct(oConn, request.getParameter("gu_product"), 1f);

    oConn.commit();
    oConn.close("order_for_new_client_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"order_for_new_client_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("...");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
    response.sendRedirect (response.encodeRedirectUrl ("order_edit_f.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_order="+oOrd.getString(DB.gu_order)));

%>