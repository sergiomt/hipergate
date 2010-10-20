<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  HashMap oMap = new HashMap();
  oMap.put("com.knowgate.http.portlets.CalendarTab","home_calendar.xsl");
  oMap.put("com.knowgate.http.portlets.CallsTab","home_calls.xsl");
  oMap.put("com.knowgate.http.portlets.MyIncidencesTab","home_incidences.xsl");
  oMap.put("com.knowgate.http.portlets.OportunitiesTab","home_oportunities.xsl");                                                                                                                                                                                                                               
  oMap.put("com.knowgate.http.portlets.RecentContactsTab","home_contacts.xsl");
  oMap.put("com.knowgate.http.portlets.RecentPostsTab","home_posts.xsl");
  oMap.put("com.knowgate.http.portlets.NewMail","home_email.xsl");
  oMap.put("com.knowgate.http.portlets.Favorites","home_favorites.xsl");
  oMap.put("com.knowgate.http.portlets.Invoicing","home_invoicing.xsl");
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  int id_domain = Integer.parseInt(getCookie(request, "domainid", "0"));
  String gu_workarea = getCookie(request, "workarea", "");
  String gu_user = getCookie(request, "userid", "");
  
  JDCConnection oConn = null;
  PreparedStatement oStmt;
  
  try {
    oConn = GlobalDBBind.getConnection("desktop_store"); 
  
    oConn.setAutoCommit (false);
  
    oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_x_portlet_user + " WHERE " + DB.nm_page + "='desktop.jsp' AND " + DB.gu_user + "=? AND " + DB.gu_workarea + "=?");
    oStmt.setString(1, gu_user);
    oStmt.setString(2, gu_workarea);
    oStmt.executeUpdate();
    oStmt.close();

    oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_x_portlet_user + " ("+DB.id_domain+","+DB.gu_user+","+DB.gu_workarea+","+DB.nm_portlet+","+DB.nm_page+","+DB.nm_zone+","+DB.od_position+","+DB.id_state+","+DB.dt_modified+",nm_template) VALUES(?,?,?,?,'desktop.jsp',?,?,'NORMAL',?,?)");

    String aLeft[] = Gadgets.split(request.getParameter("left"),",");
    
    if (null!=aLeft) {
      for (int l=0; l<aLeft.length; l++) {
        oStmt.setInt(1, id_domain);
        oStmt.setString(2, gu_user);
        oStmt.setString(3, gu_workarea);
        oStmt.setString(4, aLeft[l]);
        oStmt.setString(5, "left");
        oStmt.setInt(6, l);
        oStmt.setTimestamp(7, new java.sql.Timestamp(new java.util.Date().getTime()));
        oStmt.setString(8, (String)oMap.get(aLeft[l]));
        oStmt.executeUpdate();
      }
    }
    
    String aRight[] = Gadgets.split(request.getParameter("right"),",");

    if (null!=aRight) {
      for (int r=0; r<aRight.length; r++) {
        oStmt.setInt(1, id_domain);
        oStmt.setString(2, gu_user);
        oStmt.setString(3, gu_workarea);
        oStmt.setString(4, aRight[r]);
        oStmt.setString(5, "right");
        oStmt.setInt(6, r);
        oStmt.setTimestamp(7, new java.sql.Timestamp(new java.util.Date().getTime()));
        oStmt.setString(8, (String)oMap.get(aRight[r]));
        oStmt.executeUpdate();
      }
    }
    
    oStmt.close();
    
    oConn.commit();
    oConn.close("desktop_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"desktop_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  GlobalCacheClient.expire("["+gu_user+",left]");
  GlobalCacheClient.expire("["+gu_user+",right]");

  response.sendRedirect (response.encodeRedirectUrl ("desktop.jsp"));

%>