<%@ page import="java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.dataobjs.DB,com.knowgate.jdc.JDCConnection" language="java" session="false" contentType="text/plain;charset=ISO-8859-1" %><%@ include file="../methods/dbbind.jsp" %><%
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

  String gu_workarea = request.getParameter("gu_workarea");
  String sn_passport = request.getParameter("sn_passport");

  if (null==sn_passport) {
    out.write ("error NullPointerException parameter sn_passport is required");
    return;
  }
  if (null==gu_workarea) {
    out.write ("error NullPointerException parameter sn_passport is required");
    return;
  }

  JDCConnection oCon = null;
  PreparedStatement oStm = null;
  ResultSet oRst = null;

  boolean bFound = false;
  String sGuContact = null;
  try {
    oCon = GlobalDBBind.getConnection("passport_lookup");
        
	  oStm = oCon.prepareStatement("SELECT "+DB.gu_contact+" FROM "+DB.k_contacts+" WHERE "+DB.gu_workarea+"=? AND "+DB.sn_passport+"=?",
	  														 ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
	  oStm.setString(1, gu_workarea);
	  oStm.setString(2, sn_passport);	  
	  oRst = oStm.executeQuery();	  
	  bFound = oRst.next();
	  if (bFound) sGuContact = oRst.getString(1);
	  oRst.close();
	  oRst=null;
	  oStm.close();
	  oStm=null;

    oCon.close("passport_lookup");
  }
  catch (Exception e) {
    if (oRst!=null) oRst.close();
    if (oStm!=null) oStm.close();
    if (oCon!=null)
      if (!oCon.isClosed()) {
        oCon.close("passport_lookup");      
      }
    oCon = null;
    out.write ("error "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oCon) return;
  oCon = null;

  out.write (bFound ? "found "+sGuContact : "notfound");
%>