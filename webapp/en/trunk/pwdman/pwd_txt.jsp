<%@ page import="java.io.IOException,java.net.URLDecoder,com.knowgate.acl.ACL,com.knowgate.acl.PasswordRecord,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.misc.Gadgets" language="java" session="true" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><% 

  out.write("<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n");

	if (session.getAttribute("validated")==null) {
    out.write("<PasswordRecord><error status=\""+String.valueOf(ACL.SESSION_EXPIRED)+"\">"+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"</error></PasswordRecord>");
    return;	
	} else if (!((Boolean) session.getAttribute("validated")).booleanValue()) {
    out.write("<PasswordRecord><error status=\""+String.valueOf(ACL.SESSION_EXPIRED)+"\">"+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"</error></PasswordRecord>");
    return;	
	}

  short iStatus = autenticateCookie(GlobalDBBind, request, response);
    
  if (iStatus>=0) iStatus = verifyUserAccessRights(GlobalDBBind, request, response);

  if (iStatus<(short)0) {
    out.write("<PasswordRecord><error status=\""+String.valueOf(iStatus)+"\">"+ACL.getErrorMessage(iStatus)+"</error></PasswordRecord>");
    return;
  }

  String gu_user = getCookie(request, "userid", "");
  
  JDCConnection oCon = null;  
  PasswordRecord oRec = new PasswordRecord((String) session.getAttribute("signature"));

  try {
    oCon = GlobalDBBind.getConnection("pwd_txt");
    
		boolean bPwd = oRec.load(oCon,request.getParameter("gu_pwd"));

		if (bPwd) {
			if (!oRec.getString(DB.gu_user).equals(gu_user)) {
        out.write("<PasswordRecord><error status=\""+String.valueOf(ACL.USER_NOT_FOUND)+"\">"+ACL.getErrorMessage(ACL.USER_NOT_FOUND)+"</error></PasswordRecord>");
			} else {
				StringBuffer oXml = new StringBuffer();
				oXml.append("<PasswordRecord><error status=\"0\" />\n");
				oXml.append("<gu_pwd>"+oRec.getString(DB.gu_pwd)+"</gu_pwd>\n");
				oXml.append("<id_pwd>"+oRec.getStringNull(DB.id_pwd,"")+"</id_pwd>\n");
				oXml.append("<tl_pwd>"+oRec.getString(DB.tl_pwd)+"</tl_pwd>\n");
				oXml.append("<tx_comments><![CDATA["+oRec.getStringNull(DB.tx_comments,"")+"]]></tx_comments>\n");
				oXml.append("<tx_lines><![CDATA["+oRec.toString()+"]]></tx_lines>\n");
				oXml.append("</PasswordRecord>\n");
			  out.write(oXml.toString());	
			}
		} else {
      out.write("<PasswordRecord><error status=\"-100\">No password with such GUID was found at the database</error></PasswordRecord>");		
		}
    
    oCon.close("pwd_txt");
  }
  catch (java.security.AccessControlException a) {
    if (oCon!=null)
      if (!oCon.isClosed()) {
        oCon.close("pwd_txt");
      }
    oCon = null;
    out.write("<PasswordRecord><error status=\""+String.valueOf(ACL.INVALID_PASSWORD)+"\">AccessControlException "+a.getMessage()+"</error></PasswordRecord>");		
  }
  catch (Exception e) {
    if (oCon!=null)
      if (!oCon.isClosed()) {
        oCon.close("pwd_txt");
      }
    oCon = null;
    out.write("<PasswordRecord><error status=\"-255\">"+e.getClass().getName()+" "+e.getMessage()+"</error></PasswordRecord>");		
  }
  
  if (null==oCon) return;    
  oCon = null;

%>