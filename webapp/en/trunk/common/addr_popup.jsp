<%@ page import="java.net.URLDecoder,java.util.HashMap,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
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

  String sAddrId;
  String sAddrTp;
  String sAddrTv;
  String sAddrSt;
  String sAddrNu;
  String sAddrZp;    
  String sAddrCt;
  String sAddrEm;
  Object oAddrPh;
  String sResult = "";

  String sErrMsg = "";
  // Obtener el idioma del navegador cliente
  String sLanguage = getNavigatorLanguage(request);

  // Obtener el dominio y la workarea
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 

  // Obtener el nombre de la tabla para cruzar direcciones con su objeto padre que las contiene
  String sLinkTable = request.getParameter("linktable")==null ? "" : request.getParameter("linktable");
  // Obtener el nombre del campo de cruce y su valor
  String sLinkField = request.getParameter("linkfield")==null ? "" : request.getParameter("linkfield");
  String sLinkValue = request.getParameter("linkvalue")==null ? "" : request.getParameter("linkvalue");
  
  // Mapa para recuperar las etiquetas de tipos de ubicación a partir de sus códigos
  HashMap oLocationTypes = null;
  
  // Cadena de de filtrado (claúsula WHERE)
        
  int iAddressCount = 0;
  DBSubset oAddresses = null;        
  int iMaxRows = 4;
    
  // Obtener una conexiónd el pool a bb.dd. (el nombre de la conexión es arbitrario)
  JDCConnection oConn = GlobalDBBind.getConnection("addresspopup");  
    
  try {
    // Si el filtro no existe devolver todos los registros
    oAddresses = new DBSubset (DB.k_addresses + " a," + sLinkTable + " x",
      			       "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.tp_street + ",a." + DB.nm_street + ",a." + DB.nu_street + ",a." + DB.zipcode + ",a." + DB.mn_city + ",a." + DB.tx_email + ",a." + DB.work_phone + ",a." + DB.direct_phone + ",a." + DB.home_phone + ",a." + DB.mov_phone + ",a." + DB.fax_phone,
      			       "x." + sLinkField + "='" + sLinkValue + "' AND a." + DB.gu_address + "=x." + DB.gu_address, iMaxRows);
    oAddresses.setMaxRows(iMaxRows);
    iAddressCount = oAddresses.load (oConn);
    
    // Cargar un mapa de códigos y etiquetas traducidas de tipos de ubicacion
    oLocationTypes = GlobalDBLang.getLookUpMap((java.sql.Connection) oConn, DB.k_addresses_lookup, gu_workarea, "tp_location", sLanguage);
    
    oConn.close("addresspopup"); 
  }
  catch (SQLException e) {  
    oAddresses = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("addresspopup");
    sErrMsg = "../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close";
  }
  oConn = null;  

  if (sErrMsg.length()==0) {    
    for (int i=0; i<iAddressCount; i++) {
      
      sAddrId = oAddresses.getString(0,i);
      sAddrTp = (String) oAddresses.get(1,i);
      sAddrTv = (String) oAddresses.get(2,i);    

      if (null!=sAddrTp) sAddrTp = (String) oLocationTypes.get(sAddrTp);              
      sAddrSt = oAddresses.getStringNull(3,i,"* N/A *");
      sAddrNu = oAddresses.getStringNull(4,i,"");
      sAddrZp = oAddresses.getStringNull(5,i,"");
      sAddrCt = oAddresses.getStringNull(6,i,"");
      sAddrEm = oAddresses.getStringNull(7,i,"");
      if (sAddrEm.length()>0) sAddrEm = "<A HREF=\"mailto:" + sAddrEm + "\" TITLE=\"Send message\">" + sAddrEm + "</A>";

      if (null!=sAddrTp) sResult += "Address Type" + sAddrTp + "<BR>";
      if (null!=sAddrTv) sResult += sAddrTv + " ";
      sResult += Gadgets.HTMLEncode(sAddrSt) + " " + sAddrNu + "<BR>";
      sResult += (sAddrZp.length()>0 ? sAddrZp+" " : "") + sAddrCt + "<BR>";
      sResult += sAddrEm+"<BR>";
      
      oAddrPh = oAddresses.get(8,i);
      sResult += (oAddrPh==null ? "" : "Main" + oAddrPh + "<BR>");
      oAddrPh = oAddresses.get(9,i);
      sResult += (oAddrPh==null ? "" : "Direct" + oAddrPh + "<BR>");
      oAddrPh = oAddresses.get(10,i);
      sResult += (oAddrPh==null ? "" : "Personal" + oAddrPh + "<BR>");
      oAddrPh = oAddresses.get(11,i);
      sResult += (oAddrPh==null ? "" : "Mobile" + oAddrPh + "<BR>");
      oAddrPh = oAddresses.get(12,i);
      sResult += (oAddrPh==null ? "" : "Fax" + oAddrPh + "<BR>");
    } // next(i)
  } // fi(sErrMsg)
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Address</TITLE>
  <SCRIPT TYPE="text/javascript">
  <!--
    top.frames['<%=request.getParameter("visible_frame")%>'].document.forms['<%=request.getParameter("visible_form")%>'].divField.value = '<%=sResult%><br><a href="javascript:hideDiv()">Close</a>';
<%  if (sErrMsg.length()>0) out.write(    "open('" + sErrMsg + "');\n"); %>
  //-->
  </SCRIPT>
  <META HTTP-EQUIV="refresh" CONTENT="0; URL=../common/blank.htm">
</HEAD>
</HTML>