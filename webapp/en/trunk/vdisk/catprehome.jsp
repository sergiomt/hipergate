<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Category,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  JDCConnection oConn = GlobalDBBind.getConnection("catprehome");
  String sLabel = "";
  String sCatg = "";
    
  try {
    
    ACLUser oUser = new ACLUser(oConn, getCookie(request,"userid", ""));
    sCatg = oUser.getStringNull(DB.gu_category,"");
    
    if (sCatg.length()>0) {
      Category oCatg = new Category (oConn, sCatg);
      sLabel = nullif(oCatg.getLabel(oConn, getNavigatorLanguage(request)));
    }
        
    oConn.close("catprehome");
  }
  catch (SQLException e) {
    if(null!=oConn)
      if (!oConn.isClosed()) {
        oConn.close("catprehome");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));
  }
  if (null==oConn) return;
  
  oConn = null;
%>
  
  <!-- +----------------------------------------+ -->
  <!-- | Pre-Home de productos de una categoria | -->
  <!-- | © KnowGate 2001                        | -->
  <!-- +----------------------------------------+ -->
<HTML>
  <HEAD>
<% if (sLabel.length()>0) out.write("    <META HTTP-EQUIV=\"refresh\" content=\"0; url=catprods.jsp?id_category=" + sCatg + "&tr_category=" + Gadgets.URLEncode(sLabel) + "\""); %>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" DEFER="defer">
      <!--
        function viewProducts() {
          var dipuwnd = window.parent.frames[1];

	  if (dipuwnd.id_category.length==0)
	    alert ("Debe seleccionar primero una categoría en el árbol");
	  else	                      
            window.document.location.href = "catprods.jsp?id_category=" + dipuwnd.id_category + "&tr_category=" + escape(dipuwnd.tr_category);
        }
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  TOPMARGIN="28" MARGINHEIGHT="4">
    <A CLASS="linkplain" HREF="#" onClick="javascript:viewProducts();">View Files & Links for this Category</A>
  </BODY>
</HTML>