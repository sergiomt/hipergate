<%@ page import="java.util.StringTokenizer,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.DistributionList,com.knowgate.projtrack.Project" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
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
      
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  String gu_project = request.getParameter("gu_project");
  String gu_list = request.getParameter("gu_list");

  String sClon;
  
  Project oPrj = new Project(gu_project);
  
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("prj_create_store"); 
  
    oConn.setAutoCommit (false);
  
    if (gu_list.length()==0) {
      sClon = oPrj.clone(oConn);
    
      oPrj = new Project (oConn, sClon);
      oPrj.replace(DB.nm_project, request.getParameter("nm_project"));
      oPrj.replace(DB.gu_company, request.getParameter("gu_company").length()==0 ? null : request.getParameter("gu_company"));
      oPrj.replace(DB.gu_contact, request.getParameter("gu_contact").length()==0 ? null : request.getParameter("gu_contact"));
      oPrj.replace(DB.de_project, request.getParameter("de_project").length()==0 ? null : request.getParameter("de_project"));
      oPrj.store (oConn);
    }
    else {

      DistributionList oList = new DistributionList(oConn, gu_list);
      String sContacts = oList.activeContacts(oConn);
      
      if (com.knowgate.debug.DebugFile.trace) com.knowgate.debug.DebugFile.writeln("contacts = {" + sContacts + "}");
       
      PreparedStatement oCont = oConn.prepareStatement("SELECT " + DB.gu_company + " FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?");
      ResultSet oRSet;
      String sContactId, sCompanyId;
            
      StringTokenizer oStrTok = new StringTokenizer(sContacts, ",");

      while (oStrTok.hasMoreElements()) {
        sClon = oPrj.clone(oConn);
    
        oPrj = new Project (oConn, sClon);

        sContactId = oStrTok.nextToken();
        
        oCont.setString(1, sContactId);
        oRSet = oCont.executeQuery(); 

	if (oRSet.next()) {
          sCompanyId = oRSet.getString(1);

          if (oRSet.wasNull())
            oPrj.remove(DB.gu_company);
          else
	    oPrj.replace(DB.gu_company, sCompanyId);
          
          oPrj.replace(DB.gu_contact, sContactId);    
        }
          
        oRSet.close();
	
        oPrj.replace(DB.nm_project, request.getParameter("nm_project"));
        oPrj.replace(DB.de_project, request.getParameter("de_project").length()==0 ? null : request.getParameter("de_project"));
        oPrj.store (oConn);
      } // wend
      
      oCont.close();
    }
    
    oConn.commit();
    oConn.close("prj_create_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"prj_create_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
%>
<HTML>
  <HEAD>
    <SCRIPT TYPE="text/javascript">
      <!--
        function refreshAndClose() {
	  var w = window.opener;
		
	  if (typeof(w)!="undefined") {
<%          if (request.getParameter("gu_contact").length()!=0) { %>	  
	      w.document.location.href = "../projtrack/project_listing.jsp?where=" +  escape(" AND b.gu_contact='<% out.write(request.getParameter("gu_contact")); %>'") + "&selected=4&subselected=0";
<%          } else { %>
	      w.document.location.href = "../projtrack/project_listing.jsp?where=" +  escape(" AND b.gu_company='<% out.write(request.getParameter("gu_company")); %>'") + "&selected=4&subselected=0";
<%          } %>
	    w.focus();
	  }
	  window.close();
        }  
      //-->
    </SCRIPT>
  </HEAD>
  <BODY onload="refreshAndClose()"></BODY>
</HTML>