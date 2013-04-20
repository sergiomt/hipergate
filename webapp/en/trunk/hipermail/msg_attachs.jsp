<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_mimemsg = request.getParameter("gu_mimemsg");
  String id_message = request.getParameter("msgid");
  String nm_folder = request.getParameter("folder");
    
  JDCConnection oConn = null;
  DBSubset oParts;
  
  if (gu_mimemsg!=null)
    oParts = new DBSubset(DB.k_mime_parts, "id_part,de_part,file_name,len_part,id_disposition",
  			  DB.gu_mimemsg+"=? AND ("+DB.id_disposition+"='attachment' OR "+DB.id_disposition+"='reference' OR "+DB.id_disposition+"='poiter') ORDER BY 1", 10);
  else
    oParts = new DBSubset(DB.k_mime_parts, "id_part,de_part,file_name,len_part,id_disposition",
  			  DB.id_message+"=? AND DB.gu_folder='"+nm_folder+"' AND ("+DB.id_disposition+"='attachment' OR "+DB.id_disposition+"='reference' OR "+DB.id_disposition+"='poiter') ORDER BY 1", 10);
  
  int iParts = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("msg_attachs");

    if (gu_mimemsg!=null)
      iParts = oParts.load (oConn, new Object[]{gu_mimemsg});
    else
      iParts = oParts.load (oConn, new Object[]{gu_mimemsg,nm_folder});
    
    oConn.close("msg_attachs");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"msg_attachs");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;
%>
<HTML>
  <HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function removeAttachments() {
        var frm = document.forms[0];
        var chi = "";
        
        
        for (var e=0; e<frm.elements.length; e++) {
          if (frm.elements[e].type=="checkbox") {
            if (frm.elements[e].checked)
              chi += (chi.length==0 ? "" : ",") + frm.elements[e].value;
          }
        } // next

        if (chi.length>0) {
          frm.checkeditems.value = chi;
          frm.submit();
        }
      }
    //-->
  </SCRIPT>
  
</HEAD>
<BODY >
<% if (iParts>0) { %>
<TABLE BORDER="0">
  <TR>
    <TD VALIGN="middle"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0"></TD>
    <TD VALIGN="middle"><A HREF="#" CLASS="linkplain" onclick="removeAttachments()">Remove selected files</A></TD>
</TABLE>
<FORM METHOD="post" ACTION="msg_attachs_delete.jsp">
<INPUT TYPE="hidden" NAME="gu_mimemsg" VALUE="<%=gu_mimemsg%>">
<INPUT TYPE="hidden" NAME="folder" VALUE="<%=nullif(nm_folder)%>">
<INPUT TYPE="hidden" NAME="checkeditems">
<% for (int a=0; a<iParts; a++) {
     if (oParts.getStringNull(4,a,"").equals("reference"))
       out.write("<INPUT TYPE=\"checkbox\" VALUE=\""+String.valueOf(oParts.getInt(0,a))+"\">&nbsp;");

     out.write("<A HREF=\"msg_part.jsp?msgid="+gu_mimemsg+"&part="+String.valueOf(oParts.getInt(0,a))+"\" TARGET=\"_blank\" CLASS=\"linkplain\">" + oParts.getStringNull(1,a,oParts.getStringNull(2,a,"no name"+String.valueOf(a))) + "</A>&nbsp;");

     if (!oParts.isNull(3,a)) {
       int iLen = oParts.getInt(3,a);
            
       if (iLen>=0 && iLen<=1024)
         out.write("<FONT CLASS=\"textsmall\">(" + String.valueOf(iLen) + " bytes)</FONT>");
       else
         out.write("<FONT CLASS=\"textsmall\">("+String.valueOf(iLen/1024) + " Kb)</FONT>");
     }
     out.write("&nbsp;&nbsp;&nbsp;&nbsp;");
   }%>
</FORM>
<% } %>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>