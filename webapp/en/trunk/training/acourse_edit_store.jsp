<%@ page import="java.math.BigDecimal,java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Address,com.knowgate.hipergate.Category,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Product,com.knowgate.training.AcademicCourse,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*  
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_category = request.getParameter("gu_category");
  String id_user = getCookie (request, "userid", null);  
  String gu_acourse = nullif(request.getParameter("gu_acourse"));

  String sLanguage = getNavigatorLanguage(request);

  String sOpCode = gu_acourse.length()>0 ? "NACR" : "MACR";
  
  Product oProd = null;
  AcademicCourse oAcr = new AcademicCourse();
  Address oAdr = new Address();
  oAdr.put(DB.gu_address,request.getParameter("gu_address"));
  
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("acourse_edit_store"); 
  
    loadRequest(oConn, request, oAcr);

		if (nullif(request.getParameter("gu_category")).length()>0) {
		  oAcr.replace(DB.gu_category, request.getParameter("gu_category"));
      oAcr.replace(DB.gu_owner, id_user);
    }
    
    oConn.setAutoCommit (false);
    
    if (!oAdr.exists(oConn)) oAcr.remove(DB.gu_address);

    oAcr.store(oConn);

    if (WorkArea.saveAcademicCoursesAsOportunityObjetives(oConn,gu_workarea)) {
    	HashMap<String,String> oTr = new HashMap<String,String>();
    	for (int l=0; l<DBLanguages.SupportedLanguages.length; l++)
    	  oTr.put(DBLanguages.SupportedLanguages[l], oAcr.getString(DB.nm_course));    		
    	DBLanguages.storeLookup (oConn, DB.k_oportunities_lookup, gu_workarea, DB.id_objetive,
    			                     oAcr.isNull(DB.bo_active) ? true : oAcr.getShort(DB.bo_active)!=0,
    													 oAcr.getString(DB.gu_acourse), null, null, oTr);
      GlobalCacheClient.expire(DB.k_oportunities_lookup + ".id_objetive[" + gu_workarea + "]");
      GlobalCacheClient.expire(DB.k_oportunities_lookup + ".id_objetive#" + sLanguage + "[" + gu_workarea + "]");
    }
    
    DBAudit.log(oConn, oAcr.ClassId, sOpCode, id_user, oAcr.getString(DB.gu_acourse), oAcr.getStringNull(DB.gu_category,null), 0, 0, oAcr.getStringNull(DB.nm_acourse,null), null);
    
    oConn.commit();
    oConn.close("acourse_edit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"acourse_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,"acourse_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Espere...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>