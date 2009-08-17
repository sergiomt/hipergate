<%@ page import="com.knowgate.acl.ACL,com.knowgate.acl.PasswordRecord,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.hipergate.Category" language="java" session="true" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_category = request.getParameter("gu_category");
  String gu_user = getCookie(request, "userid", "");
  
	boolean bSession = (session.getAttribute("validated")!=null);

  JDCConnection oConn = null;
  
  DBSubset oCatgs = new DBSubset(DB.k_user_pwd+" u,"+DB.k_x_cat_objs+" x",
  															 "u."+DB.gu_pwd+",u."+DB.tl_pwd,
  															 "u."+DB.gu_pwd+"=x."+DB.gu_object+" AND "+
  															 "x."+DB.id_class+"="+String.valueOf(PasswordRecord.ClassId)+" AND "+
  															 "x."+DB.gu_category+"=?",20);
  try {
    oConn = GlobalDBBind.getConnection("pwdlist");
    
    int iPerms = new Category(gu_category).getUserPermissions(oConn, gu_user);
    if ((iPerms&ACL.PERMISSION_LIST)!=0) {
      final int nCatgs = oCatgs.load(oConn, new Object[]{gu_category});
		  for (int c=0; c<nCatgs; c++) {
		    out.write((c>0 ? "\n" : "")+oCatgs.getString(0,c)+"|"+oCatgs.getString(1,c).replace('|',' '));
		  }
    } // fi

    oConn.close("pwdlist");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("pwdlist");
      }
    oConn = null;
	  out.write("ERROR "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;
%>