<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String gu_category = request.getParameter("gu_category");

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ",");
  int iDot;
  PreparedStatement oStm;
  JDCConnection oCon = GlobalDBBind.getConnection("product_reorder");
      
  try {
    oCon.setAutoCommit (true);
    
    oStm = oCon.prepareStatement("UPDATE " + DB.k_x_cat_objs + " SET " + DB.od_position + "=? WHERE " + DB.gu_category + "='" + gu_category + "' AND " + DB.gu_object + "=?");
    for (int i=0;i<a_items.length;i++) {
      iDot = a_items[i].indexOf(':');
      oStm.setInt(1, Integer.parseInt(a_items[i].substring(iDot+1)));
      oStm.setString(2, a_items[i].substring(0,iDot));
      oStm.executeUpdate();            
    } // next ()
    
    oStm.close();
    oCon.close("product_reorder");

    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>parent.msgslist.document.location = 'item_list.jsp?gu_shop=" + request.getParameter("gu_shop") + "&gu_category=" + request.getParameter("gu_category") + "&tr_category=" + Gadgets.URLEncode(request.getParameter("tr_category")) + "&top_parent_cat=" + request.getParameter("top_parent_cat") + "&orderby=10&screen_width=' + String(screen.width); self.document.location='../blank.htm';</SCRIPT></HEAD></HTML>");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"product_reorder");
      oCon = null; 
      out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.open('../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back'); self.document.location='../blank.htm';</SCRIPT></HEAD></HTML>");
    }
%>