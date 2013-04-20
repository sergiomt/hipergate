<%@ page import="java.rmi.RemoteException,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.cache.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  // Inicio de sesion anónimo permitido
  // if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String nm_table = request.getParameter("nm_table");
  String id_language = request.getParameter("id_language");
  String id_section = request.getParameter("id_section");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");

  if (null!=nm_coding) nm_coding = nm_coding.trim();

  String sWorkArea = nullif(request.getParameter("gu_workarea"), getCookie(request,"workarea", request.getParameter("gu_workarea")));
  String sQryStr = "?gu_workarea="+sWorkArea+"&nm_table="+ nm_table + "&id_language=" + id_language + "&id_section=" + id_section + "&tp_control=" + tp_control + "&nm_control=" + nm_control + (nm_coding==null ? "" : "&nm_coding=" + nm_coding) + "&id_form=" + nullif(request.getParameter("id_form"),"0");
  String sTr;

%>
<!-- +-----------------------+ -->
<!-- | Listado de Remonte    | -->
<!-- | KnowGate 2002-2008    | -->
<!-- +-----------------------+ -->
<% out.write ("<!-- " + nm_table + "." + id_section + "#" + id_language + "[" + sWorkArea + "] -->"); %>
<HTML>
  <HEAD>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript" SRC="../javascript/findit.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');
            
      function choose(vlstr,nmstr) {
        var prnt = window.parent;
	var frm = prnt.opener.document.forms[<%=nullif(request.getParameter("id_form"),"0")%>];
	var opt;	
        <% if (tp_control.equals("1"))
             // El control de entrada es de tipo TEXT
             out.write("	frm." + nm_control + ".value = nmstr;\n");           
           else {
             // El control de entrada es de tipo SELECT
             out.write("if (-1==comboIndexOf(frm." + nm_control + ",vlstr)) {\n");             
             out.write("            opt = prnt.opener.document.createElement(\"OPTION\");\n");
             out.write("            opt.text = nmstr;\n");
             out.write("            opt.value = vlstr;\n");
             out.write("            frm." + nm_control + ".options.add(opt);\n");                          
             out.write("        } // fi(comboIndexOf())\n");
             out.write("        setCombo(frm." + nm_control + ",nmstr);\n");
           }           
           if (null!=nm_coding) out.write("        frm." + nm_coding + ".value = vlstr;\n");
        %>        
        prnt.close();
      }      
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  SCROLL="yes" TOPMARGIN="4" MARGINHEIGHT="4" LEFTMARGIN="4" RIGHTMARGIN="4">
    <FORM METHOD="POST" ACTION="lookup_delete.jsp<%=sQryStr%>">
    <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<%  
  int iOdPos = 0;
  JDCConnection oConn = null;
  Object aParams[] = { sWorkArea, id_section };
  DBSubset oLookup;
  int iLookup = -1;
  
  try {
    // GlobalCacheClient.expire(nm_table + "." + id_section + "#" + id_language + "[" + sWorkArea + "]"); 

    oLookup = GlobalCacheClient.getDBSubset(nm_table + "." + id_section + "#" + id_language + "[" + sWorkArea + "]");
    
    if (null==oLookup) {

      oConn = GlobalDBBind.getConnection("lookup_mid");
      oLookup = new DBSubset (nm_table,
       			      DB.vl_lookup + "," + DB.tr_ + id_language + "," + DB.pg_lookup,
      			      DB.gu_owner + "=? AND " + DB.id_section + "=? ORDER BY 2", 50);
      iLookup = oLookup.load (oConn, aParams);
      
      GlobalCacheClient.putDBSubset(nm_table, nm_table + "." + id_section + "#" + id_language + "[" + sWorkArea + "]", oLookup); 
      oConn.close("lookup_mid");
      oConn = null;
    } // fi(oLookup)
    else
      iLookup = oLookup.getRowCount();
                    
    for (iOdPos=0; iOdPos<iLookup; iOdPos++) {
      
      sTr = oLookup.getStringNull(1,iOdPos,oLookup.getString(0,iOdPos));
      if (sTr.length()==0) sTr = oLookup.getString(0,iOdPos);
      
      out.write ("      <TR><TD WIDTH=\"16\"><INPUT TYPE=\"checkbox\" NAME=\"chkbox" + String.valueOf(iOdPos) + "\" VALUE=\"" + String.valueOf(oLookup.getInt(2,iOdPos)) + "\"></TD>");
      out.write ("<TD CLASS=\"strip" + String.valueOf(iOdPos%2+1) + "\"><A HREF='javascript:choose(\"" + oLookup.getString(0,iOdPos) + "\",\""+ sTr + "\")' CLASS='linkplain' TITLE=\"" + oLookup.getString(0,iOdPos) + "\">" + sTr + "<A></TD></TR>\n");
    } // next (i)
    
  }
  catch (SQLException e) {
    if (null!=oConn)
      if (!oConn.isClosed()) {
        oConn.close("lookup_mid");
        oConn = null;
      }        
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  catch (RemoteException r) {
    if (null!=oConn)
      if (!oConn.isClosed()) {
        oConn.close("lookup_mid");
        oConn = null;
      }        
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=AppServer Access Error&desc=" + r.getMessage() + "&resume=_back"));
  }
%>
    </TABLE>
    <INPUT TYPE="hidden" NAME="chkcount" VALUE="<%=iOdPos%>">
    </FORM>
  </BODY>
</HTML>
