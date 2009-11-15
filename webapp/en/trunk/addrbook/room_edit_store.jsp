<%@ page import="java.math.BigDecimal,com.knowgate.addrbook.Room,java.io.IOException,java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Product" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/reqload.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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
  
  final String CATALOG_CATEGORY = "c0a8019111669bc55cf100003a86da41"; // "c0a801fa116696f044a100000dd4511b";

  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  String nm_room = request.getParameter("nm_room");

  String sOpCode = nm_room.length()>0 ? "NROO" : "MROO";
    
  JDCConnection oConn = GlobalDBBind.getConnection("storeroom");  
  
  Room oRoom = new Room();
  Product oProd;
  
  try {
    loadRequest(oConn, request, oRoom);

    oConn.setAutoCommit (false);
    
    if (nullif(request.getParameter("chk_available")).length()==0)
      oRoom.replace(DB.bo_available, (short)0);
      
    oRoom.store(oConn);
    
    GlobalCacheClient.expire("k_rooms.nm_room[" + gu_workarea + "]"); 

    DBAudit.log (oConn, Room.ClassId, sOpCode, id_user, oRoom.getString(DB.nm_room), null, 0, 0, null, null);
    
    oConn.commit();
    oConn.close("storeroom");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"storeroom");

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  oConn = null;
  
  // [~//Refrescar el padre y cerrar la ventana~]
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>
<%@ include file="../methods/page_epilog.jspf" %>