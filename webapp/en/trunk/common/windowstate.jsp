<%@ page import="java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.jdc.JDCConnection" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%
  JDCConnection oCon = null;
  PreparedStatement oStm = null;
  
  try {
    oCon = GlobalDBBind.getConnection("windowstate");

    oCon.setAutoCommit (true);
    
    oStm = oCon.prepareStatement ("UPDATE k_x_portlet_user SET id_state=? WHERE gu_user=? AND nm_page=? AND nm_portlet=? AND gu_workarea=? AND nm_zone=?");
    oStm.setString (1, request.getParameter("id_state"));
    oStm.setString (2, request.getParameter("gu_user"));
    oStm.setString (3, request.getParameter("nm_page"));
    oStm.setString (4, request.getParameter("nm_portlet"));
    oStm.setString (5, request.getParameter("gu_workarea"));
    oStm.setString (6, request.getParameter("nm_zone"));
    oStm.executeUpdate();
    oStm.close();

    com.knowgate.http.portlets.HipergatePortletConfig.touch(oCon, request.getParameter("gu_user"), request.getParameter("nm_portlet"), request.getParameter("gu_workarea"));
    
    oCon.close("windowstate");
    
  }
  catch (SQLException e) {

    if (null!=oStm) {
      try {
          oStm.close();
      } catch (SQLException ignore) { }
    }
  
    if (null!=oCon) {
      try {
        if (!oCon.isClosed())
          oCon.close("windowstate");
      } catch (SQLException ignore) { }
    }
  }
  
  GlobalCacheClient.expire ("["+request.getParameter("gu_user")+","+request.getParameter("nm_zone")+"]");
 
%>
<jsp:forward page="desktop.jsp?selected=0&subselected=0"></jsp:forward>
