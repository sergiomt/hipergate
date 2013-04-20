<%@ page language="java" session="true" contentType="text/html;charset=ISO-8859-1" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  session.removeAttribute("validated");
  session.removeAttribute("signature");
  
  String gu_user = getCookie (request, "userid", null);

  if (null!=gu_user) {
    GlobalCacheClient.expire ("["+gu_user+",authstr]");
    GlobalCacheClient.expire ("["+gu_user+",admin]");
    GlobalCacheClient.expire ("["+gu_user+",user]");
    GlobalCacheClient.expire ("["+gu_user+",poweruser]");
    GlobalCacheClient.expire ("["+gu_user+",guest]");
    GlobalCacheClient.expire ("["+gu_user+",trial]");
    GlobalCacheClient.expire ("["+gu_user+",owner]");   
    GlobalCacheClient.expire ("["+gu_user+",mailbox]");
    GlobalCacheClient.expire ("["+gu_user+",mailpwd]");
    GlobalCacheClient.expire ("["+gu_user+",mailhost]");
    GlobalCacheClient.expire ("["+gu_user+",left]");
    GlobalCacheClient.expire ("["+gu_user+",right]");

    for (int o=0; o<10; o++) {
      GlobalCacheClient.expire ("["+gu_user+",options," + String.valueOf(o) + "]");    
      for (int s=0; s<10; s++)
        GlobalCacheClient.expire ("["+gu_user+",suboptions," + String.valueOf(s) + "," + String.valueOf(o) + "]");    
    }    
  } // fi (gu_user)
  
%>
<HTML>
  <HEAD>
    <TITLE>Wait...</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--      
        deleteCookie ("domainid");
        deleteCookie ("domainnm");
        deleteCookie ("skin");
        deleteCookie ("authstr");
        deleteCookie ("appmask");

        deleteCookie ("userid");
        deleteCookie ("workarea");
        deleteCookie ("tour");
        
        document.location = '../login.html';
      //-->
    </SCRIPT>
  </HEAD>
</HTML>
