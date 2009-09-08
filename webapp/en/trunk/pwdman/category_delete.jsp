<%@ page import="com.knowgate.hipergate.Category,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("lst"), ',');
   
  JDCConnection oCon = null;
   
  try {
    oCon = GlobalDBBind.getConnection("category_delete");

    oCon.setAutoCommit (false);
 
    for (int i=0;i<a_items.length;i++) {
      Category.delete(oCon, a_items[i]);

      DBAudit.log(oCon, Category.ClassId, "DCAT", id_user, a_items[i], null, 0, 0, null, null);
    } // next

    oCon.commit();
    oCon.close("object_delete");
  } 
  catch (SQLException e) {
      disposeConnection(oCon,"category_delete");
      oCon = null; 
      out.write("ERROR " + e.getMessage());
    }

  if (null==oCon) return;

  oCon = null;

  out.write("Delete Categories 1.0:OK");
%>