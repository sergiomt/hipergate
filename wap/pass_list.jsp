<%@ page import="com.knowgate.acl.ACL,com.knowgate.acl.PasswordRecord,java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.hipergate.Category" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><%@ include file="inc/dbbind.jsp" %><%

	if (session.getAttribute("validated")==null) {
	  response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"&desc="+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"&resume=passwords.jsp"));
    return;	
	} else if (!((Boolean) session.getAttribute("validated")).booleanValue()) {
	  response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"&desc="+ACL.getErrorMessage(ACL.SESSION_EXPIRED)+"&resume=passwords.jsp"));
    return;	
	}

  String gu_category = request.getParameter("gu_category");
  Category oCatg = new Category(gu_category);
  String sTrCategory = "";
  
  DBSubset oCatgs = new DBSubset(DB.k_user_pwd+" u,"+DB.k_x_cat_objs+" x",
  															 "u."+DB.gu_pwd+",u."+DB.tl_pwd+",u."+DB.id_pwd,
  															 "u."+DB.gu_pwd+"=x."+DB.gu_object+" AND "+
  															 "x."+DB.id_class+"="+String.valueOf(PasswordRecord.ClassId)+" AND "+
  															 "x."+DB.gu_category+"=?",20);
  StringBuffer oPwds = new StringBuffer();

  try {
    oConn = GlobalDBBind.getConnection("pwdlist");
    
    int iPerms = new Category(gu_category).getUserPermissions(oConn, oUser.getString(DB.gu_user));
    if ((iPerms&ACL.PERMISSION_LIST)!=0) {
      final int nCatgs = oCatgs.load(oConn, new Object[]{gu_category});
		  for (int c=0; c<nCatgs; c++) {
		    oPwds.append("<br/>&nbsp;<a href=\"pass_txt.jsp?gu_pwd="+oCatgs.getString(0,c)+"\">"+oCatgs.getString(1,c)+"</a>");
		  } // next
    } // fi

    sTrCategory = oCatg.getLabel(oConn, sLanguage);

    oConn.close("pwdlist");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("pwdlist");
      }
    oConn = null;
	  out.write("ERROR "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

%><?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
"http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <head><meta http-equiv="cache-control" content="no-cache"/></head>
  <card id="pass_list">
  <br/>&nbsp;<%=sTrCategory%>
<% out.write(oPwds.toString()); %>
  </card>
  <p><a href="home.jsp"><%=Labels.getString("a_home")%></a> <do type="accept" label="<%=Labels.getString("a_back")%>"><prev/></do> <a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>
</wml>