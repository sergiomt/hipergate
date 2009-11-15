<%@ page import="java.io.IOException,java.net.URLDecoder,java.util.HashMap,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_language = getNavigatorLanguage(request);        
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  String nm_table = request.getParameter("sel_table");
  String nm_base = nm_table.substring(0, nm_table.length()-7);
  String id_section = request.getParameter("sel_section");
  String nu_rows = request.getParameter("nu_rows");
  String[] aCols = Gadgets.split(request.getParameter("collist"), ',');
  String pg_lookup, vl_lookup;
  String s;
  
  int iRows = Integer.parseInt(nu_rows);  
  int iCols = aCols.length;
  HashMap oTr = new HashMap(43);
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("lookups_store"); 
  
    oConn.setAutoCommit (false);

    for (int r=0; r<iRows; r++) {
      s = String.valueOf(r);
      pg_lookup = request.getParameter("pg_lookup"+s);
      vl_lookup = request.getParameter("vl_lookup"+s).toUpperCase();
      oTr.clear();
      for (int c=2; c<iCols; c++)
        if (request.getParameter(aCols[c]+s)!=null)
          oTr.put(aCols[c].substring(3), request.getParameter(aCols[c]+s));
      com.knowgate.debug.DebugFile.writeln("<JPS:looukps_store.jsp pg_lookup="+pg_lookup+"|vl_lookup="+vl_lookup+"|id_section="+id_section);
      if (pg_lookup!=null) {
        if (pg_lookup.length()>0 && vl_lookup.length()==0)
          if (id_section.length()>3)
            DBLanguages.deleteLookup (oConn, nm_table, nm_base, gu_workarea, id_section, Integer.parseInt(pg_lookup));
          else 
            DBLanguages.deleteLookup (oConn, nm_table, null, gu_workarea, id_section, Integer.parseInt(pg_lookup));
        else if (vl_lookup.length()>0)
          DBLanguages.storeLookup (oConn, nm_table, gu_workarea, id_section, vl_lookup, oTr);
      } else {
        if (vl_lookup.length()>0)
          DBLanguages.storeLookup (oConn, nm_table, gu_workarea, id_section, vl_lookup, oTr);
        else
          DBLanguages.deleteLookup (oConn, nm_table, null, gu_workarea, id_section, "");
      }
    } // next

    oConn.commit();
    oConn.close("lookups_store");
    
    GlobalCacheClient.expire(nm_table + "." + id_section + "[" + gu_workarea + "]");
    GlobalCacheClient.expire(nm_table + "." + id_section + "#" + id_language + "[" + gu_workarea + "]");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"lookups_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,"lookups_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn = null;
  
  response.sendRedirect (response.encodeRedirectUrl ("lookups.jsp?nm_table="+nm_table+"&id_section="+id_section));
%>