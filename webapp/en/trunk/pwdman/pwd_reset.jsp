<%@ page import="com.knowgate.acl.PasswordRecord,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="true" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String sLanguage = getNavigatorLanguage(request);

  JDCConnection oCon = null;
    
  try {
    oCon = GlobalDBBind.getConnection("pwd_reset");
  
	  String sCatName = DBCommand.queryStr(oCon, "SELECT d."+DB.nm_domain+",'_',u."+DB.tx_nickname+",'_pwds' FROM "+DB.k_domains+" d,"+DB.k_users+" u WHERE d."+DB.id_domain+"=u."+DB.id_domain+" AND u."+DB.gu_user+"='"+id_user+"'");

		String sPwdsCat = DBCommand.queryStr(oCon, "SELECT "+DB.gu_category+" FROM "+DB.k_categories+" c, " + DB.k_cat_tree+ " t WHERE c."+DB.gu_category+"=t."+DB.gu_child_cat+" AND t."+DB.gu_parent_cat+" IN (SELECT "+DB.gu_category+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+id_user+"') AND c."+DB.nm_category+"='"+sCatName+"'");

	  if (null!=sPwdsCat) {
      oCon.setAutoCommit (false);

		  DBSubset oCatgs = new Categories().getChildsNamed(oCon, sPwdsCat, sLanguage, Categories.ORDER_BY_NONE);

	    int iCatgs = oCatgs.getRowCount();
     
      for (int c=0; c<iCatgs; c++) {
        Category.delete(oCon, oCatgs.getString(0,c));
      }

      DBCommand.executeUpdate(oCon, "UPDATE "+DB.k_users+" SET "+DB.tx_pwd_sign+"=NULL,"+DB.tx_challenge+"=NULL WHERE "+DB.gu_user+"='"+id_user+"'");
      
      oCon.commit();
    } // fi

    oCon.close("pwd_reset");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"pwd_reset");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  response.sendRedirect (response.encodeRedirectUrl ("pwdlogout.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));

 %>