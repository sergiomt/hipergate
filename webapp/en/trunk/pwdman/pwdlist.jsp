<%@ page import="com.knowgate.acl.ACL,com.knowgate.acl.PasswordRecord,java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.hipergate.Category" language="java" session="true" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

	if (session.getAttribute("validated")==null) {
    out.write("ERROR "+ACL.getErrorMessage(ACL.SESSION_EXPIRED));
    return;	
	} else if (!((Boolean) session.getAttribute("validated")).booleanValue()) {
    out.write("ERROR "+ACL.getErrorMessage(ACL.SESSION_EXPIRED));
    return;	
	}

  short iStatus = autenticateCookie(GlobalDBBind, request, response);
    
  if (iStatus>=0) iStatus = verifyUserAccessRights(GlobalDBBind, request, response);

  if (iStatus<(short)0) {
    out.write("ERROR "+ACL.getErrorMessage(iStatus));
    return;
  }

  String gu_category = request.getParameter("gu_category");
  String gu_user = getCookie(request, "userid", "");
  
  String sFormsPath = getServletConfig().getServletContext().getRealPath("/pwdman/pwdlist.jsp");
  sFormsPath = sFormsPath.substring(0, sFormsPath.lastIndexOf(File.separator)+1)+"loginforms"+File.separator;
  
  JDCConnection oConn = null;
  
  DBSubset oCatgs = new DBSubset(DB.k_user_pwd+" u,"+DB.k_x_cat_objs+" x",
  															 "u."+DB.gu_pwd+",u."+DB.tl_pwd+",u."+DB.id_pwd,
  															 "u."+DB.gu_pwd+"=x."+DB.gu_object+" AND "+
  															 "x."+DB.id_class+"="+String.valueOf(PasswordRecord.ClassId)+" AND "+
  															 "x."+DB.gu_category+"=?",20);
  try {
    oConn = GlobalDBBind.getConnection("pwdlist");
    
    int iPerms = new Category(gu_category).getUserPermissions(oConn, gu_user);
    if ((iPerms&ACL.PERMISSION_LIST)!=0) {
      final int nCatgs = oCatgs.load(oConn, new Object[]{gu_category});
		  for (int c=0; c<nCatgs; c++) {
		    out.write((c>0 ? "\n" : "")+oCatgs.getString(0,c)+"|"+oCatgs.getString(1,c).replace('|',' ')+"|");
		    if (!oCatgs.isNull(2,c)) {
		      File oForm = new File(sFormsPath+oCatgs.getString(2,c)+".jsp");
		      if (oForm.exists()) out.write(oCatgs.getString(2,c));
		    } // fi
		  } // next
    } // fi

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
%>