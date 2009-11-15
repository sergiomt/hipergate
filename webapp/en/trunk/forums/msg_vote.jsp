<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.forums.NewsMessageVote" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%      

  String sGuMsg = request.getParameter("gu_msg");
  String sNmAuthor = request.getParameter("nm_author");
  Integer oScore = null;
  if (request.getParameter("od_score")!=null) oScore = Integer.parseInt(request.getParameter("od_score"));
  String sTxEmail = request.getParameter("tx_email");
  String sTxVote = request.getParameter("tx_vote");  
  String sGuWriter = nullif(request.getParameter("gu_user"),getCookie (request, "userid", null));
  String sIpAddrPlusProxiesInc = request.getRemoteAddr() + ((null!=request.getHeader("X-Forwarded-For"))?";"+request.getHeader("X-Forwarded-For").replaceAll(" ",";"):"");
  int nVote = 0;
  JDCConnection oConn = null;  

  try {
    oConn = GlobalDBBind.getConnection("msg_vote");
    
    oConn.setAutoCommit(false);
    
    nVote = NewsMessageVote.insert(oConn, sGuMsg, oScore, sIpAddrPlusProxiesInc, sNmAuthor, sGuWriter, sTxEmail, sTxVote);

    oConn.commit();
      
    oConn.close("msg_vote");
  }
  catch (Exception e) {  
    disposeConnection(oConn,"msg_vote");
    oConn = null;
    out.write("ERROR: "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

  out.write(String.valueOf(nVote));
%>