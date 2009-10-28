<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String gu_category = request.getParameter("gu_category");

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  
  PreparedStatement oStm;
  JDCConnection oCon = GlobalDBBind.getConnection("product_move");
      
  try {
    oCon.setAutoCommit (true);
    
    oStm = oCon.prepareStatement("UPDATE " + DB.k_x_cat_objs + " SET " + DB.gu_category + "='" + gu_category + "' WHERE " + DB.gu_object + "=?");
    for (int i=0;i<a_items.length;i++) {
      oStm.setString(1, a_items[i]);
      oStm.executeUpdate();
      
      DBAudit.log(oCon, (short)91, "MITM", id_user, a_items[i], gu_category, 0, 0, null, null);
      
    } // next ()
    
    oStm.close();
    oCon.close("product_move");

    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>parent.msgslist.document.location.reload(true); self.document.location='../blank.htm';</SCRIPT></HEAD></HTML>");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"product_move");
      oCon = null; 
      out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.open('../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back'); self.document.location='../blank.htm';</SCRIPT></HEAD></HTML>");
    }
%>
