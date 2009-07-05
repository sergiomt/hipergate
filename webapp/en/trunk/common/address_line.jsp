<%@ page import="java.io.IOException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser,com.knowgate.dataobjs.DB,com.knowgate.hipergate.Address" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%   

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
   
  String sGuAddr = request.getParameter ("address");
  String sGuWorkA = request.getParameter("workarea");

  if (null==sGuAddr) {
    out.write ("error NullPointerException parameter address is required");
    return;
  }

  if (null==sGuWorkA) {
    out.write ("error NullPointerException parameter workarea is required");
    return;
  }

  JDCConnection oConn = null;  
  Address oAddr = new Address();
  boolean bFound = false;

  try {
    oConn = GlobalDBBind.getConnection("address_line");
        
    bFound = oAddr.load(oConn, new Object[]{sGuAddr});
    if (!oAddr.getString(DB.gu_workarea).equals(sGuWorkA)) bFound = false;

    oConn.close("address_line");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("address_line");
      }
    oConn = null;
    out.write ("error "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (bFound)
    out.write (oAddr.toLocaleString());
  else
    out.write ("notfound");
%>