<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.datamodel.ModelManager" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
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
      
  String id_domain = request.getParameter("id_domain");
  
  if (!getCookie (request, "domainid", "0").equals("1024")) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=You cannot modify doding all your Windows Address Book entries into hipergate.mains if you are not conne&resume=_close"));
    return;
  }
  
  String nm_domain = request.getParameter("nm_domain");
  String gu_admins = request.getParameter("gu_admins");
  String bo_active = nullif(request.getParameter("bo_active"));
  String id_user = getCookie (request, "userid", null);
      
  ACLDomain oDom = new ACLDomain();

  JDCConnection oConn = null;
  
  boolean bAlreadyExists = false;
  
  try {
    oConn = GlobalDBBind.getConnection("domedit_store");
  
    if (id_domain.length()!=0) {
      oDom.load(oConn, new Object[]{new Integer(id_domain)});

      oConn.setAutoCommit (false);

      oDom.replace(DB.nm_domain, nm_domain);
      oDom.replace(DB.bo_active, (bo_active.equals("1") ? (short)1 : (short)0));
      oDom.replace(DB.gu_admins, gu_admins);
      oDom.store(oConn);
      
      oConn.commit();
    }
    else {
      Statement oStmt = oConn.createStatement();
      ResultSet oRSet = oStmt.executeQuery("SELECT NULL FROM " + DB.k_domains + " WHERE " + DB.nm_domain + "='" + nm_domain + "'");
      bAlreadyExists = oRSet.next();
      oRSet.close();
      oStmt.close();
      
      if (!bAlreadyExists) {

        oConn.setAutoCommit (false);

        ModelManager oMan = new ModelManager();
        oMan.setConnection(oConn);
        int iNewDomain = oMan.createDomain(nm_domain);

	oMan.cloneWorkArea("MODEL.model_default", nm_domain + "." + nm_domain.toLowerCase() + "_default");
	
        oConn.commit();
      } // fi (!bAlreadyExists)
    } // fi (id_domain=="")
            
    oConn.close("domedit_store");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        try { if (!oConn.getAutoCommit()) oConn.rollback(); } catch (SQLException r) { }
        oConn.close("domedit_store");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  catch (NumberFormatException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        try { if (!oConn.getAutoCommit()) oConn.rollback(); } catch (SQLException r) { }
        oConn.close("domedit_store");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }

  
  if (null==oConn) return;
  
  oConn = null;

  if (bAlreadyExists)
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=Another Domain with same name already exists&resume=_close"));
  else {
    out.write ("<HTML>");

          
    out.write ("<HTML><HEAD><TITLE>Domain Created</TITLE>\n");
    
    if (id_domain.length()==0) {
      out.write ("<SCRIPT LANGUAGE='JavaScript' SRC='../javascript/cookies.js'></SCRIPT><SCRIPT LANGUAGE='JavaScript' SRC='../javascript/setskin.js'></SCRIPT><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true);<" + "/SCRIPT" +"></HEAD>");
      out.write ("<BODY TOPMARGIN=8 LEFTMARGIN=8 MARGINWIDTH=8 MARGINHEIGHT=8>");
      out.write ("<TABLE WIDTH=\"100%\"><TR><TD><IMG SRC=\"../images/images/spacer.gif\" HEIGHT=\"4\" WIDTH=\"1\" BORDER=\"0\"></TD></TR><TR><TD CLASS=\"striptitle\"><FONT CLASS=\"title1\">Domain Created&nbsp;<I>" + nm_domain + "</I></FONT></TD></TR></TABLE><BR>");    
      out.write ("<FONT CLASS='textplain'>");
      out.write ("For using the new domain disconnect from SYSTEM domain and log in into the new one as:<BR>");
      out.write ("User<I><B>administrator@hipergate-" + nm_domain.toLowerCase() + ".com</B></I><BR>");
      out.write ("Password<I><B>" + nm_domain.toUpperCase() + "</B></I><BR>");    
      out.write ("</FONT>");
      out.write ("<HR>");
      out.write ("<CENTER><FORM>");
      out.write ("<INPUT TYPE=\"button\" CLASS=\"closebutton\" onclick=\"window.close()\" VALUE=\"Close Window\">");
      out.write ("</FORM></CENTER>");
    }
    else {
      out.write ("</SCRIPT><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>close();<" + "/SCRIPT" +"></HEAD>");
    }    
    
    out.write ("</BODY>");
    out.write ("</HTML>");
  }
%>