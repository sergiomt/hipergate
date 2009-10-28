<%@ page import="com.knowgate.training.ContactEducation,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = null;
  ContactEducation oCne = new ContactEducation();
  oCne.put(DB.gu_contact, request.getParameter("gu_contact"));
  
  try {
    oCon = GlobalDBBind.getConnection("contact_education_delete");

    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_items.length;i++) {
      oCne.replace(DB.gu_degree,a_items[i]);
      oCne.delete(oCon);

      DBAudit.log(oCon, (short)9067, "DCDE", id_user, a_items[i], null, 0, 0, null, null);
    } // next ()
  
    oCon.commit();
    oCon.close("contact_education_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"contact_education_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  response.sendRedirect (response.encodeRedirectUrl ("contact_education_listing.jsp?gu_contact="+request.getParameter("gu_contact")+"&fullname="+Gadgets.URLEncode(request.getParameter("tx_fullname"))));
 %>