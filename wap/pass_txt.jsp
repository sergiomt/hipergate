<%@ page import="java.security.AccessControlException,java.io.IOException,java.net.URLDecoder,com.knowgate.acl.ACL,com.knowgate.acl.PasswordRecord,com.knowgate.acl.PasswordRecordLine,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.misc.Gadgets" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><%@ include file="inc/dbbind.jsp" %><%

	if (session.getAttribute("validated")==null) {
	  response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"&desc="+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"&resume=passwords.jsp"));
    return;	
	} else if (!((Boolean) session.getAttribute("validated")).booleanValue()) {
	  response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"&desc="+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"&resume=passwords.jsp"));
    return;	
	}

  PasswordRecord oRec = new PasswordRecord((String) session.getAttribute("signature"));

  try {
    oConn = GlobalDBBind.getConnection("pwd_txt");
    
		boolean bPwd = oRec.load(oConn,request.getParameter("gu_pwd"));

		if (bPwd) {
			if (!oRec.getString(DB.gu_user).equals(oUser.getString(DB.gu_user))) {
	      throw new AccessControlException(ACL.getErrorMessage(ACL.USER_NOT_FOUND));
			}
		} else {
	    throw new AccessControlException("No password with such GUID was found at the database");
		}

    oConn.close("pwd_txt");
  }
  catch (java.security.AccessControlException a) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("pwd_txt");
      }
    oConn = null;
	  response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=AccessControlException&desc="+a.getMessage()+"&resume=passwords.jsp"));
    return;
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("pwd_txt");
      }
    oConn = null;
	  response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+e.getClass().getName()+"&desc="+e.getMessage()+"&resume=passwords.jsp"));
    return;
  }
  
%><?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
"http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <head><meta http-equiv="cache-control" content="no-cache"/></head>
  <card id="pass_txt">
  <br/>&nbsp;<b><%=oRec.getString(DB.tl_pwd)%></b><br/>
  <table columns="2">
<% for (PasswordRecordLine l : oRec.lines()) {     
     if (l.getLabel()!=null) if (!l.getLabel().equals("null")) out.write("<tr><td>"+l.getLabel()+"</td><td>"+l.getValue()+"</td></tr>");
   } // next
%>
  </table>
  <br/>&nbsp;<b><%=oRec.getStringNull(DB.tx_comments,"")%></b><br/>
  </card>
  <p><a href="home.jsp"><%=Labels.getString("a_home")%></a> <do type="accept" label="<%=Labels.getString("a_back")%>"><prev/></do> <a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>
</wml>