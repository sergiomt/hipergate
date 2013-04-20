<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
%>
<HTML>
<HEAD>
<SCRIPT TYPE="text/javascript">
  <!--
  function setList() {
    var doc = parent.frames[0].document;
        
    var frm = doc.forms[0];
    var opt;    

<%
  String sDisp;
  String sFind = request.getParameter("find");
  String sCtrl = request.getParameter("control");
  String sType = request.getParameter("type");
  String sMaxr = request.getParameter("max_rows");
  if (sCtrl==null) sCtrl = "sel_users";
  if (sMaxr==null) sMaxr = "100";

  DBSubset oMembers = null;
  if ("company".equalsIgnoreCase(sType)) {
	  sDisp = DB.nm_commercial+","+DB.nm_legal+","+DB.tp_location+","+DB.mn_city;
  } else {
    sDisp = DB.tx_name + "," + DB.tx_surname;
  }
    
  if (null==sFind) {
    oMembers = new DBSubset(DB.k_member_address, DB.gu_address + "," + sDisp, DB.gu_workarea + "=? "+(sType==null ? "" : " AND gu_"+sType+" IS NOT NULL ")+" ORDER BY 2,3", 100);
  } else {
    oMembers = new DBSubset(DB.k_member_address, DB.gu_address + "," + sDisp,
    			     DB.gu_workarea + "=? AND (" +    			     
    			     ("company".equalsIgnoreCase(sType) ?
    			      DB.nm_legal + " "+DBBind.Functions.ILIKE+" ? OR " + DB.nm_commercial + " "+DBBind.Functions.ILIKE+" ?) "+" AND gu_"+sType+" IS NOT NULL "
    			     : DB.tx_name + " "+DBBind.Functions.ILIKE+" ? OR " + DB.tx_surname + " "+DBBind.Functions.ILIKE+" ?) ")+
    			     " ORDER BY 2,3", 100);  
  }
  oMembers.setMaxRows(Integer.parseInt(sMaxr));
  
  JDCConnection oConn = null;  
  int iMembers = 0; 
  try {
    oConn = GlobalDBBind.getConnection("loadcontacts");
    
    if (null==sFind)
      iMembers = oMembers.load(oConn, new Object[]{request.getParameter("gu_workarea")});
    else
      iMembers = oMembers.load(oConn, new Object[]{request.getParameter("gu_workarea"),"%"+sFind+"%","%"+sFind+"%"});
          
    oConn.close("loadcontacts");

    oConn = null;

    for (int c=0; c<iMembers; c++) {
      out.write("    opt = doc.createElement(\"OPTION\");\n");
      out.write("    opt.value = \"" + oMembers.getString(0,c) + "\";\n");
      if ("company".equalsIgnoreCase(sType)) {
        out.write("    opt.text = \"" + oMembers.getStringNull(1,c,oMembers.getString(2,c)) + " ("+oMembers.getStringNull(3,c,"")+" "+oMembers.getStringNull(4,c,"")+")\";\n");
      } else {
        out.write("    opt.text = \"" + oMembers.getStringNull(1,c,"") + " " + oMembers.getStringNull(2,c,"") + "\";\n");
      }  
      out.write("    frm."+sCtrl+".options.add(opt);\n");    
    } // next c
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("loadcontacts");

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));  
  }  
%>

  if (frm.<%=sCtrl%>.options.length>0)
    if ("COMBOLOADING"==frm.<%=sCtrl%>.options[0].value)
      frm.<%=sCtrl%>.options[0].value = null;

  self.document.location.href = "../blank.htm";
  } //-->
</SCRIPT>
</HEAD>
<BODY onLoad="setList()">
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>