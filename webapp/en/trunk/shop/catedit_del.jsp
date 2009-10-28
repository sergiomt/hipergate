<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = GlobalDBBind.getConnection("shopcatedit_delete");
  oCon.setAutoCommit (false);
    
  try {
    for (int i=0;i<a_items.length;i++) {
      Category.delete(oCon, a_items[i]);
      DBAudit.log(oCon, Category.ClassId, "DCAT", id_user, a_items[i], null, 0, 0, null, null);
    } // next ()
    
    Categories.expand (oCon, request.getParameter("top_parent_cat"));
    
    oCon.commit();
    oCon.close("shopcatedit_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"shopcatedit_delete");
     oCon = null; 
     out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">window.open(\"../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back\");</SCRIPT></HEAD></HTML>");
    }
  
  if (null==oCon) return;
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">window.parent.document.location.reload(true);window.location=\"../blank.htm\";<" + "/SCRIPT" +"></HEAD></HTML>"); 
%>