<%@ page import="com.knowgate.acl.ACL,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Gadgets,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Category,com.knowgate.hipergate.Categories" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%@ include file="inc/dbbind.jsp" %><%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final int P = ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_MODIFY;

  final String PAGE_NAME = "passwords";

	String[] aStr = null;
  DBSubset oCatgs = null;
  int iCatgs = 0;
  int[] aPermissions = null;
  String sPwdsCat = "";

	boolean bSession = (session.getAttribute("validated")!=null);
  if (bSession) bSession = ((Boolean) session.getAttribute("validated")).booleanValue();

  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);

		if (bSession) {
			String sCatName = DBCommand.queryStr(oConn, "SELECT d."+DB.nm_domain+",'_',u."+DB.tx_nickname+",'_pwds' FROM "+DB.k_domains+" d,"+DB.k_users+" u WHERE d."+DB.id_domain+"=u."+DB.id_domain+" AND u."+DB.gu_user+"='"+oUser.getString(DB.gu_user)+"'");
			
		  sPwdsCat = DBCommand.queryStr(oConn, "SELECT "+DB.gu_category+" FROM "+DB.k_categories+" c, " + DB.k_cat_tree+ " t WHERE c."+DB.gu_category+"=t."+DB.gu_child_cat+" AND t."+DB.gu_parent_cat+" IN (SELECT "+DB.gu_category+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+oUser.getString(DB.gu_user)+"') AND c."+DB.nm_category+"='"+sCatName+"'");

			if (null!=sPwdsCat)
		    oCatgs = new Categories().getChildsNamed(oConn, sPwdsCat, sLanguage, Categories.ORDER_BY_LOCALE_NAME);
	      iCatgs = oCatgs.getRowCount();
	      if (iCatgs>0) { 
	        aPermissions = new int[iCatgs];
	        for (int p=0; p<iCatgs; p++) {
	          Category oPerms = new Category(oCatgs.getString(0,p));
	          aPermissions[p] = oPerms.getUserPermissions(oConn, oUser.getString(DB.gu_user));
	        } //next
	      } // fi
	  } // fi

		oConn.close(PAGE_NAME);
    
  } catch (Exception xcpt) {
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+xcpt.getClass().getName()+"&desc=" + xcpt.getMessage() + "&resume=home.jsp"));    
    return;
  }
  
%><?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
"http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <head><meta http-equiv="cache-control" content="no-cache"/></head>
  <card id="passwords">
<%  if (bSession) {
      out.write("<br/>&nbsp;"+Labels.getString("lbl_passw_catgs")+"<br/>");
      for (int c=0; c<iCatgs; c++) {
       if ((aPermissions[c]&P)!=0) 
         out.write("<br/>&nbsp;<a href=\"pass_list.jsp?gu_category="+oCatgs.getString(0,c)+"\">"+oCatgs.getStringNull(2,c,oCatgs.getString(1,c))+"</a><br/>");
      } // next
   } else {
     out.write (Labels.getString("lbl_enter_signatute")+"<br/>");
     out.write ("<input type=\"password\" name=\"signpwd\" /><br/>"); %>
     <anchor><%=Labels.getString("a_enter")%>
       <go href="passlogin.jsp" accept-charset="UTF-8" method="post">
         <postfield name="tx_pwd_sign" value="$(signpwd)" />
       </go>
     </anchor>
<% } %>
  </card>
  <p><a href="home.jsp"><%=Labels.getString("a_home")%></a> <do type="accept" label="<%=Labels.getString("a_back")%>"><prev/></do> <a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>
</wml>