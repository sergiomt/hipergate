<%@ page import="java.io.IOException,java.rmi.RemoteException,java.net.URLDecoder,java.util.HashMap,java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.cache.*,com.knowgate.acl.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  String nm_table = request.getParameter("nm_table");
  String id_language = request.getParameter("id_language");
  String id_section = request.getParameter("id_section");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");
  String id_form = nullif(request.getParameter("id_form"), "0");

  String sWorkArea = nullif(request.getParameter("gu_workarea"), getCookie(request,"workarea", request.getParameter("gu_workarea")));
  
  String sQryStr = "?gu_workarea="+sWorkArea+"&nm_table="+ nm_table + "&id_language=" + id_language + "&id_section=" + id_section + "&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding + "&id_form=" + id_form;

  String tr_desc = request.getParameter("tr_" + id_language);
  String vl_lookup = request.getParameter("vl_lookup");

  JDCConnection oConn = null;
  PreparedStatement oStmt;
  ResultSet oRSet;
  int iErrorLevel = 0;
  Object oNextPg;
  int iNextPg;

  try {  
    oConn = GlobalDBBind.getConnection("lookup_store1");  
  
    // Verificar que no existe ningun otro registro con el mismo valor o descripción
    
    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.vl_lookup + "," + DB.tr_ + id_language + " FROM " + nm_table + " WHERE " + DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_section + "='" + id_section + "' AND (" + DB.tr_ + id_language + "='" + tr_desc + "' OR " + DB.vl_lookup + "='" + vl_lookup + "'))");
      
    oStmt = oConn.prepareStatement("SELECT " + DB.vl_lookup + "," + DB.tr_ + id_language + " FROM " + nm_table + " WHERE " + DB.gu_owner + "=? AND " + DB.id_section + "=? AND (" + DB.tr_ + id_language + "=? OR " + DB.vl_lookup + "=?)");
    oStmt.setString(1, sWorkArea);
    oStmt.setString(2, id_section);
    oStmt.setString(3, tr_desc);
    oStmt.setString(4, vl_lookup);
    oRSet = oStmt.executeQuery();

    if (oRSet.next())
      if (oRSet.getString(1).equals(vl_lookup))
        iErrorLevel = 1;
      else
        iErrorLevel = 2;

    oRSet.close();
    oStmt.close();
    
    oConn.close("lookup_store1");
    oConn = null;
    
    if (1==iErrorLevel)
      response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?resume=_back&title=Duplicated Entry&desc=Another entry with the same value already exists"));
    else if (2==iErrorLevel)
      response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?resume=_back&title=Duplicated Entry&desc=Another entry with the same description already exists"));    
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("lookup_store1");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?resume=_back&title=Database Access Error&desc=" + e.getLocalizedMessage()));
    return;
  }
  
  try {
    
    // Continuar sólo si no había registros duplicados
    
    if (0==iErrorLevel) {
      HashMap oTr = new HashMap(53);
      String aLangs[] = DBLanguages.SupportedLanguages;
      for (int l=aLangs.length-1; l>=0; l--) {
        String sTr = request.getParameter("tr_"+aLangs[l]);
        if (sTr!=null)
          if (sTr.length()>0)
            oTr.put(aLangs[l], sTr); 
      } // next

      oConn = GlobalDBBind.getConnection("lookup_store2");  

      oConn.setAutoCommit(false);

      DBLanguages.addLookup((Connection) oConn, nm_table, sWorkArea, id_section, vl_lookup, oTr);
      
      oConn.commit();
      
      oConn.close("lookup_store2");
      oConn = null;
            
      GlobalCacheClient.expire(nm_table + "." + id_section + "[" + sWorkArea + "]");
      GlobalCacheClient.expire(nm_table + "." + id_section + "#" + id_language + "[" + sWorkArea + "]");
      
      response.sendRedirect (response.encodeRedirectUrl ((nm_table.equals("k_duties_lookup") ? "../projtrack/resource_" : "")+"lookup_mid.jsp" + sQryStr));   
      return;
    } // fi (iErrorLevel)
  }
  catch (SQLException e) {
    disposeConnection(oConn,"lookup_store2");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    return;
  }
  catch (RemoteException r) {
    if (null!=oConn)
      if (!oConn.isClosed()) {
        oConn.close("lookup_store2");
        oConn = null;
      }        
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=AppServer Access Error&desc=" + r.getMessage() + "&resume=_back"));
    return;
  }
%>