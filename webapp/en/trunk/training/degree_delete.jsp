<%@ page import="com.knowgate.training.EducationDegree,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = request.getParameter("gu_workarea");

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = null;
  EducationDegree oCne = new EducationDegree();
  
  try {
    oCon = GlobalDBBind.getConnection("degree_delete");

    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_items.length;i++) {
      oCne.replace(DB.gu_degree,a_items[i]);
      oCne.delete(oCon);

      DBAudit.log(oCon, EducationDegree.ClassId, "DDGR", id_user, a_items[i], null, 0, 0, null, null);
    } // next ()
  
    final int nLangs = DBLanguages.SupportedLanguages.length;
    for (int l=0; l<nLangs; l++) {
      GlobalCacheClient.expire("k_education_degree["+gu_workarea+","+DBLanguages.SupportedLanguages[l]+"]");
    }

    oCon.commit();
    oCon.close("degree_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"degree_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  response.sendRedirect (response.encodeRedirectUrl ("degree_lookup.jsp"));
 %>