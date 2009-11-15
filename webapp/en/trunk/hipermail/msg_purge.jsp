<%@ page import="java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  String id_user = getCookie(request,"userid","");
  String gu_workarea = getCookie(request,"workarea",""); 
  String gu_folder = request.getParameter("gu_folder");
  
  // **********************************************

  int iMailCount = 0;
  String sMsgIds = request.getParameter("checkeditems");

  if (DebugFile.trace) DebugFile.writeln("<JSP:msg_purge.jsp deleting " + Gadgets.dechomp(sMsgIds,","));

  String[] aMsgsIds = Gadgets.split(sMsgIds, ',');

  ACLUser oMe = new ACLUser();
  JDCConnection oCon = null;
  PreparedStatement oStm = null;
  
  try {
    oCon = GlobalDBBind.getConnection("msg_purge");
    
    oMe.load (oCon, new Object[]{id_user}); 

    oCon.setAutoCommit(true);
    
    String sDeleted = oMe.getMailFolder(oCon, "deleted");
    String sDrafts = oMe.getMailFolder(oCon, "drafts");

    if (sDeleted.equals(gu_folder) || sDrafts.equals(gu_folder)) {
      for (int m=0; m<aMsgsIds.length; m++) {
        if (aMsgsIds[m].length()>0) {
	  MimeMessageDB.delete(oCon, aMsgsIds[m]);
        }
      }
    } else {    
      oStm = oCon.prepareStatement("UPDATE " + DB.k_mime_msgs + " SET " + DB.gu_category + "='" + sDeleted + "' WHERE (" + DB.gu_mimemsg + "=? OR " + DB.id_message + "=?) AND " + DB.gu_workarea + "='" + gu_workarea + "'");
    
      for (int m=0; m<aMsgsIds.length; m++) {
        if (aMsgsIds[m].length()>0) {
          oStm.setString(1,aMsgsIds[m]);
          oStm.setString(2,aMsgsIds[m]);
          oStm.executeUpdate();
        }
      }
      oStm.close();
    }
    
    oCon.close("msg_purge");
    oCon = null;
  }
  catch (SQLException sqle) {
    if (oCon!=null)
      if (!oCon.isClosed())
        oCon.close("msg_purge");
    oCon = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_back"));
    return;
  }
%><%@ include file="../methods/page_epilog.jspf" %>
<% if (null!=request.getParameter("gu_folder")) { %>
<jsp:forward page="folder_listing_local.jsp">
  <jsp:param name="gu_folder" value="<%=request.getParameter(\"gu_folder\")%>" />
</jsp:forward>    
<% } %>