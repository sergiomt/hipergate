<%@ page import="java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%
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

  String gu_workarea = request.getParameter("gu_workarea");
  String id_language = request.getParameter("id_language");
  String id_section = request.getParameter("id_section");

  out.write("<lookupslist>\n");

  JDCConnection oConn = GlobalDBBind.getConnection("addr_xmlfeed");  
  Statement oStmt;
  ResultSet oRSet;
  String sSQL = "SELECT " + DB.vl_lookup + "," + DBBind.Functions.ISNULL + "(" + DB.tr_ + id_language + ",'') FROM " +  DB.k_addresses_lookup + " WHERE " + DB.gu_owner + "='" + gu_workarea + "' AND " + DB.id_section + "='" + id_section + "'";    
  String sVal;
  String sTr;
  
  try {
    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oRSet = oStmt.executeQuery(sSQL);
    
    while (oRSet.next()) {
      sVal = oRSet.getString(1);
      sTr = oRSet.getString(2);
      if (sTr.length()>0) {
        out.write("<lookup><value><![CDATA["+sVal+"]]></value><label><![CDATA["+sTr+"]]></label></lookup>\n");
      } // fi(sTr)      
    } // wend()

    oRSet.close();
    oStmt.close();

    oConn.close("addr_xmlfeed");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("addr_xmlfeed");      
  }
  oConn = null;  

  out.write("</lookupslist>");
%>