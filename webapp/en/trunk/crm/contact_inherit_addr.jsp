<%@ page import="java.net.URLDecoder,java.util.HashMap,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.RecentlyUsed" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/nullif.jspf" %>
<%@ include file="../methods/cookies.jspf" %>
<%
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
 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String gu_company = request.getParameter("gu_company");
  
  String sErrMsg = "";
  int iAddressCount = 0;
  DBSubset oAddresses = null;        
    
  // Obtener una conexiónd el pool a bb.dd. (el nombre de la conexión es arbitrario)
  JDCConnection oConn = GlobalDBBind.getConnection("contactinheritaddr");  
    
  try {
    // Si el filtro no existe devolver todos los registros
    oAddresses = new DBSubset (DB.k_addresses + " a," + DB.k_x_company_addr + " x",
      			       "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.tp_street + ",a." + DB.nm_street + ",a." + DB.nu_street + ",a." + DB.zipcode + ",a." + DB.mn_city + ",a." + DB.tx_email + ",a." + DB.work_phone + ",a." + DB.direct_phone + ",a." + DB.home_phone + ",a." + DB.mov_phone + ",a." + DB.fax_phone + ",a." + DB.nm_company + ",a." + DB.tx_addr1 + ",a." + DB.tx_addr2 + ",a." + DB.id_country + ",a." + DB.id_state + ",a." + DB.nm_state,
      			       "x." + DB.gu_company + "='" + gu_company + "' AND a." + DB.gu_address + "=x." + DB.gu_address, 1);
    oAddresses.setMaxRows(1);
    iAddressCount = oAddresses.load (oConn);

    oConn.close("addresspopup"); 
  }
  catch (SQLException e) {  
    oAddresses = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("addresspopup");
    sErrMsg = "../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_close";
  }
  oConn = null;  
%>
<HTML>
<HEAD>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    function inherit() {
      var frm = window.parent.contacttext.document.forms[2];
    
<%  if (sErrMsg.length()==0 && iAddressCount>0) { %>

      setCombo(frm.sel_location, "<%=oAddresses.getStringNull(1,0,"")%>");
      frm.tp_location.value = "<%=oAddresses.getStringNull(1,0,"")%>";
      setCombo(frm.sel_street, "<%=oAddresses.getStringNull(2,0,"")%>");
      frm.tp_street.value = "<%=oAddresses.getStringNull(2,0,"")%>";
      frm.nm_street.value = "<%=oAddresses.getStringNull(3,0,"")%>";
      frm.nu_street.value = "<%=oAddresses.getStringNull(4,0,"")%>";      
      frm.zipcode.value = "<%=oAddresses.getStringNull(5,0,"")%>";
      frm.mn_city.value = "<%=oAddresses.getStringNull(6,0,"")%>";
      frm.work_phone.value = "<%=oAddresses.getStringNull(8,0,"")%>";
      frm.nm_company.value = "<%=oAddresses.getStringNull(13,0,"")%>";
      frm.tx_addr1.value = "<%=oAddresses.getStringNull(14,0,"")%>";
      frm.tx_addr2.value = "<%=oAddresses.getStringNull(15,0,"")%>";
      setCombo(frm.sel_country, "<%=oAddresses.getStringNull(16,0,"").trim()%>");
      clearCombo(frm.sel_state);
      comboPush (frm.sel_state, "<%=oAddresses.getStringNull(18,0,"")%>", "<%=oAddresses.getStringNull(17,0,"")%>", true, true);
      frm.id_state.value = "<%=oAddresses.getStringNull(17,0,"")%>";
      frm.nm_state.value = "<%=oAddresses.getStringNull(18,0,"")%>";
      
<%  } // fi(sErrMsg) %>
    }
  //-->
  </SCRIPT>
</HEAD>
<BODY onload="inherit()">
<% out.write(sErrMsg); %>
</BODY>
</HTML>