<%@ page import="java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Gadgets,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><% 
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "activity_ref_lookup";

  final String gu_workarea = request.getParameter("gu_workarea");
  final String gu_activity = request.getParameter("gu_activity");
  final String id_ref = Gadgets.removeChar(Gadgets.ASCIIEncode(Gadgets.left(request.getParameter("id_ref"),30)),' ').toLowerCase();

  JDCConnection oConn = null;  
  boolean bExists = false;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME,true);
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.id_ref+" FROM "+DB.k_activities+" WHERE "+
                                                     DB.gu_workarea+"=? AND "+DB.id_ref+"=?"+
                                                    (gu_activity.length()>0 ? " AND "+DB.gu_activity+"<>?" : ""));
    oStmt.setString(1, gu_workarea);
    oStmt.setString(2, id_ref);
    if (gu_activity.length()>0) oStmt.setString(3, gu_activity);
    ResultSet oRSet = oStmt.executeQuery();
    bExists = oRSet.next();
    oRSet.close();
    oStmt.close();
		
    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    out.write("error\n"+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;
  out.write(bExists ? "true" : "false");
  out.write("\n");
  out.write(id_ref);

%>