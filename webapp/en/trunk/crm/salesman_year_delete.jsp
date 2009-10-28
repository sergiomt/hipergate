<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.SalesObjectives" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
    
  JDCConnection oCon = null;
    
  try {
    oCon = GlobalDBBind.getConnection("salesman_year_delete");

    oCon.setAutoCommit (false);
  
    SalesObjectives oObj = new SalesObjectives();

    oObj.put (DB.gu_sales_man, request.getParameter("gu_sales_man"));
    oObj.put (DB.tx_year, request.getParameter("tx_year"));
      
    oObj.delete(oCon);

    oCon.commit();
    oCon.close("salesman_year_delete");
  } 
  catch (SQLException e) {
      disposeConnection(oCon,"salesman_year_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;

  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.parent.document.location.href='salesman_edit_f.jsp?gu_sales_man=" + request.getParameter("gu_sales_man") + "&n_sales_man=' + escape(\"" + request.getParameter("n_sales_man") + "\");<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>