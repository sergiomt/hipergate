<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.ResultSet,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
  
  String gu_workarea = getCookie (request, "workarea", null);
  String nm_client = request.getParameter("nm_client");
  String sFoundId = null, sFoundNm = "", sFoundLg = null;
  int iType = 0;
  
  ResultSet oRst;
  PreparedStatement oStm;
  int iAddrs = 0;
  DBSubset oAddrs;
  JDCConnection oCon = GlobalDBBind.getConnection("client_complete");
    
  try {
    oStm = oCon.prepareStatement("SELECT " + DB.gu_company + "," + DB.nm_legal + "," + DB.id_legal + " FROM " +
    														 DB.k_companies + " WHERE " + DB.gu_workarea+ "=? AND (" + DB.nm_legal + " " + DBBind.Functions.ILIKE + " ? OR " +
    														 DB.nm_commercial + " " + DBBind.Functions.ILIKE + " ? OR " + DB.gu_company + "=?)",
    													   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStm.setString(1,gu_workarea);
    oStm.setString(2,nm_client+"%");
    oStm.setString(3,nm_client+"%");
    oStm.setString(4,nm_client);
    oRst = oStm.executeQuery();
    if (oRst.next()) {
      sFoundId = oRst.getString(1);
      sFoundNm = oRst.getString(2);
      sFoundLg = nullif(oRst.getString(3));
      iType = 1;
    }
    oRst.close();
    oStm.close();
    
    if (null==sFoundId) {
      oStm = oCon.prepareStatement("SELECT " + DB.gu_contact + "," + DB.tx_name + "," + DB.tx_surname + " FROM " +
      														 DB.k_contacts + " WHERE " +
      														 DB.gu_workarea+ "=? AND (" + DB.tx_name + " " + DBBind.Functions.ILIKE + " ? OR " + DB.tx_surname + " " + DBBind.Functions.ILIKE + " ? OR " + 
      														 DBBind.Functions.strCat(new String[]{DB.tx_name,DB.tx_surname},' ') + " " + DBBind.Functions.ILIKE + " ? OR " +
      														 DB.gu_contact + "=?)",
                                   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStm.setString(1,gu_workarea);
      oStm.setString(2,nm_client+"%");
      oStm.setString(3,nm_client+"%");
      oStm.setString(4,nm_client+"%");
      oStm.setString(5,nm_client);
      oRst = oStm.executeQuery();
      if (oRst.next()) {
        sFoundId = oRst.getString(1);
        sFoundNm = nullif(oRst.getString(2))+" "+nullif(oRst.getString(3));
        sFoundNm = sFoundNm.trim();
        iType = 2;
      }
      oRst.close();
      oStm.close();
    }
    
    if (1==iType) {
      oAddrs = new DBSubset(DB.k_addresses + " a," + DB.k_x_company_addr + " x",
      			    "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.tp_street + ",a." + DB.nm_street + ",a." + DB.nu_street + ",a." + DB.zipcode + ",a." + DB.mn_city,
      			    "a." + DB.gu_workarea + "=? AND a." + DB.bo_active + "<>0 AND x." + DB.gu_company + "=? AND a." + DB.gu_address + "=x." + DB.gu_address, 2);
      iAddrs = oAddrs.load(oCon, new Object[]{gu_workarea, sFoundId});
    }
    else if (2==iType) {
      oAddrs = new DBSubset(DB.k_addresses + " a," + DB.k_x_contact_addr + " x",
      			    "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.tp_street + ",a." + DB.nm_street + ",a." + DB.nu_street + ",a." + DB.zipcode + ",a." + DB.mn_city,
      			    "a." + DB.gu_workarea + "=? AND a." + DB.bo_active + "<>0 AND x." + DB.gu_contact + "=? AND a." + DB.gu_address + "=x." + DB.gu_address, 2);
      iAddrs = oAddrs.load(oCon, new Object[]{gu_workarea, sFoundId});
    }
    else
      oAddrs = null;
      
    oCon.close("client_complete");
  } 
  catch(NullPointerException e) {
      if (oCon!=null)
        if (!oCon.isClosed()) {
          oCon.close("client_complete");
        }
      oAddrs = null;
      oCon = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE>\n");
  out.write("<SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript' SRC='../javascript/combobox.js'></SCRIPT>\n");
  out.write("<SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>\n");
  out.write("var doc = window.parent.orderdata.document;\n");
  out.write("var frm = doc.forms[0];\n");
  out.write("var opt;\n");
  
  if (0!=iType) {
    if (1==iType) {
      out.write("frm.gu_company.value = '" + sFoundId + "';\n");
      out.write("frm.id_legal.value = '" + sFoundLg + "';\n");
    }
    else {
      out.write("frm.gu_contact.value = '" + sFoundId + "';\n");
      out.write("frm.id_legal.value = '';\n");
    }
    
    out.write("frm.nm_client.value = unescape('" + Gadgets.URLEncode(sFoundNm) + "');\n");
    out.write("window.parent.orderdata.document.images['clientwarning'].src = '../images/images/viewtxt.gif';\n");

    out.write("clearCombo(frm.sel_ship_addr);\n");
    out.write("clearCombo(frm.sel_bill_addr);\n");

    for (int a=0; a<iAddrs; a++) {
      out.write("  opt = doc.createElement(\"OPTION\");\n");
      out.write("  opt.text = \"" + oAddrs.getStringNull(3,a,"") + " " + oAddrs.getStringNull(4,a,"") + " (" + oAddrs.getStringNull(6,a,"") + ")\";\n");
      out.write("  opt.value = \"" + oAddrs.getStringNull(0,a,"") + "\";\n");
      out.write("  frm.sel_ship_addr.options.add(opt);\n");

      out.write("  opt = doc.createElement(\"OPTION\");\n");
      out.write("  opt.text = \"" + oAddrs.getStringNull(3,a,"") + " " + oAddrs.getStringNull(4,a,"") + " (" + oAddrs.getStringNull(6,a,"") + ")\";\n");
      out.write("  opt.value = \"" + oAddrs.getStringNull(0,a,"") + "\";\n");
      out.write("  frm.sel_bill_addr.options.add(opt);\n");
    } // next
    
  } // fi (iType)
  
  out.write("window.document.location='../blank.htm';\n"); 
  out.write("</SCRIPT>\n</HEAD></HTML>"); 
 %>