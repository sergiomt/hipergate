<%@ page import="java.io.IOException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser" language="java" session="false" contentType="text/plain;charset=ISO-8859-1" %><%@ include file="../methods/dbbind.jsp" %><%   
   
  int iIdDomain = Integer.parseInt(request.getParameter("domainid"));
  String sNickName = request.getParameter("nickname");

  if (null==sNickName) {
    out.write ("Error NullPointerException parameter nickname is required");
    return;
  }

  JDCConnection oConn = null;  
  String sUserGuid=null;

  try {
    oConn = GlobalDBBind.getConnection("nickname_lookup");
        
    sUserGuid = ACLUser.getIdFromNick(oConn, iIdDomain, sNickName);

    oConn.close("nickname_lookup");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("nickname_lookup");      
      }
    oConn = null;
    out.write ("error "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (null==sUserGuid)
    out.write ("notfound");
  else
    out.write ("found");
%>