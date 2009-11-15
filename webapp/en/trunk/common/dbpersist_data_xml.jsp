<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.crm.Contact,com.knowgate.crm.Company" language="java" session="false" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
/*
  
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String gu_instance = request.getParameter("gu_instance");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_class = nullif(request.getParameter("id_class"));
  short iClassId = 0;
  
  if (id_class.length()>0) iClassId = Short.parseShort(id_class);
  
  JDCConnection oConn = null;  
      
  try {
    oConn = GlobalDBBind.getConnection("instance_data_xml");

	  if (0==iClassId) {
	    if (DBCommand.queryExists(oConn, DB.k_contacts, DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_contact+"='"+gu_instance+"'"))
	      iClassId = Contact.ClassId;
	    else if (DBCommand.queryExists(oConn, DB.k_companies, DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_company+"='"+gu_instance+"'"))
	      iClassId = Contact.ClassId;	    	
	  }

    out.write("<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<DBPersist id_class=\""+String.valueOf(iClassId)+"\">\n");

    switch (iClassId) {
      case Contact.ClassId:
        Contact oCont = new Contact(oConn, gu_instance);
        out.write(oCont.toXML(oConn, "", "\n"));
        break;
      case Company.ClassId:
        Company oComp = new Company(oConn, gu_instance);
        out.write(oComp.toXML(oConn, "", "\n"));
        break;
    } 
      
    oConn.close("instance_data_xml");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("instance_data_xml");
      }
    oConn = null;
    out.write("<error>"+e.getClass().getName() + " " + e.getMessage() + "</error>");
  }
    out.write("</DBPersist>");
  
  if (null==oConn) return;    
  oConn = null;
%>