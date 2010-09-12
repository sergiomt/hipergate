<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/csv;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  String gu_workarea = getCookie(request,"workarea","");
  String gu_list = request.getParameter("gu_list");
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("list_members_csv");
    
    DistributionList oList = new DistributionList(oConn, gu_list);
    
    if (oList.getString(DB.gu_workarea).equals(gu_workarea)) {
  		response.setHeader("Content-Disposition","attachment; filename=\"" + oList.getStringNull(DB.de_list,"list") + ".csv\"");
      out.write(oList.print(oConn, true));
    } else {
    	out.write("FORBIDDEN: The requested list belongs to a WorkArea different from the current one");
    }
    
    oConn.close("list_members_csv");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("list_members_csv");
      }
    oConn = null;
		out.write("ERROR "+e.getClass().getName()+" "+e.getMessage());
  }
%>