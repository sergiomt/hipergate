<%@ page import="java.util.Date,java.sql.PreparedStatement,java.sql.SQLException,java.sql.Timestamp,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.NameValuePair,com.knowgate.dfs.HttpRequest,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2010  Know Gate S.L. All rights reserved.

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

  final String PAGE_NAME = "registration";

  String tx_email	= request.getParameter("tx_email");
  String tx_name = request.getParameter("tx_name");
  String tx_surname	= request.getParameter("tx_surname");
  String nm_company	= request.getParameter("nm_company");
  String work_phone	= request.getParameter("work_phone");
  String id_country	= request.getParameter("id_country");
  String nm_state	= request.getParameter("nm_state");
  String zipcode	= request.getParameter("zipcode");
  int nu_employees = Integer.parseInt(request.getParameter("nu_employees"));
  short bo_stats_allowed = Short.parseShort(nullif(request.getParameter("chk_stats_allowed"),"0"));

  NameValuePair[] aParams = new NameValuePair[8];
  aParams[0] = new NameValuePair("tx_email", tx_email);
  aParams[1] = new NameValuePair("tx_name", tx_name);
  aParams[2] = new NameValuePair("tx_surname", tx_surname);
  aParams[3] = new NameValuePair("nm_company", nm_company);
  aParams[4] = new NameValuePair("work_phone", work_phone);
  aParams[5] = new NameValuePair("id_country", id_country);
  aParams[6] = new NameValuePair("nm_state", nm_state);
  aParams[7] = new NameValuePair("zipcode", zipcode);

  JDCConnection oConn = null;
  PreparedStatement oStmt = null;  

  try {    
    oConn = GlobalDBBind.getConnection(PAGE_NAME);
    
    oConn.setAutoCommit(false);
    
    oStmt = oConn.prepareStatement("UPDATE k_version SET dt_modified=?, bo_register=2, bo_allow_stats=?, gu_support=NULL, tx_name=?, tx_surname=?, nu_employees=?, nm_company=?, id_sector=?, id_country=?, nm_state=?, mn_city=NULL, zipcode=?, work_phone=?, tx_email=?");
    oStmt.setTimestamp(1, new Timestamp(new Date().getTime()));
    oStmt.setShort(2, bo_stats_allowed);
    oStmt.setString(3, tx_name);
    oStmt.setString(4, tx_surname);
    oStmt.setInt(5, nu_employees);
    oStmt.setString(6, nm_company);
    oStmt.setString(7, "");
    oStmt.setString(8, id_country);
    oStmt.setString(9, nm_state);
    oStmt.setString(10, zipcode);
    oStmt.setString(11, work_phone);
    oStmt.setString(12, tx_email);
    oStmt.executeUpdate();
    oStmt.close();

    oConn.commit();
  
    HttpRequest oPost = new HttpRequest("http://www.hipergate.org/login/registration_store.jsp", null, "POST", aParams);  
    Object oResponse = oPost.post();
		String sResponse;
		
		if (oResponse.getClass().getName().equals("java.lang.String"))
		  sResponse = ((String) oResponse).trim();
		else
			sResponse = new String((byte[]) oResponse, "UTF-8").trim();

		if (sResponse.startsWith("OK")) {
		  out.write("OK");
      oConn.setAutoCommit(false);
		  oStmt = oConn.prepareStatement("UPDATE k_version SET bo_register=1, gu_support=?");
      oStmt.setString(1, Gadgets.split2(sResponse,'\n')[1]);
      oStmt.executeUpdate();
      oStmt.close();
      oConn.commit();
		  
    } else {
		  out.write(sResponse);
    }    	
    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
		out.write("ERROR\n"+e.getClass().getName()+" "+e.getMessage());
  }
%>