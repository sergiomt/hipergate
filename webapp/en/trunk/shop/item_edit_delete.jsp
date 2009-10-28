<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Product,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ",");
  Product oProd;
  Object aItemPK[] = { null };
  
  JDCConnection oCon = GlobalDBBind.getConnection("product_delete");
    
  try {
    oCon.setAutoCommit (false);
    
    for (int i=0;i<a_items.length;i++) {
      oProd = new Product();
      
      aItemPK[0] = a_items[i];
      
      if (oProd.load(oCon, aItemPK)) {
        oProd.delete(oCon);
        DBAudit.log(oCon, Product.ClassId, "DOBJ", id_user, a_items[i], null, 0, 0, oProd.getStringNull(DB.nm_product,""), null);
      }
      
      oProd = null;      
    } // next ()
    oCon.commit();
    oCon.close("product_delete");

    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>parent.msgslist.document.location.reload(true); self.document.location='../blank.htm';</SCRIPT></HEAD></HTML>");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"product_delete");
      oCon = null; 
      out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.open('../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back'); self.document.location='../blank.htm';</SCRIPT></HEAD></HTML>");
    }
%>
