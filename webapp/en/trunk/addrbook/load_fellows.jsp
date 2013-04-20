<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Address,com.knowgate.hipergate.Term" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/nullif.jspf" %><%
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
    var doc = parent.meettext.document;
    var frm = doc.forms[0];
    var opt;    
<%
  String sGuTrm = null;
  String sTxTrm = null;
  String sFind = request.getParameter("find");
  String sAddr = request.getParameter("address");
  String sList = nullif(request.getParameter("list"));
  String sMaxr = request.getParameter("max_rows");
  if (sMaxr==null) sMaxr = "500";
  Address oAddr = new Address();
  
  DBSubset oContacts = new DBSubset(DB.k_fellows, DB.gu_fellow + "," + DB.tx_name + "," + DB.tx_surname + "," + DB.tx_location,
  			     	   (null==sFind ? "" : "(" + DB.tx_name + " LIKE ? OR " + DB.tx_surname + " LIKE ?) AND ") +
  			     	   DB.gu_workarea + "=? " + (sList.length()>0 ? "AND "+DB.gu_fellow+" IN ("+sList+")" : "") + " ORDER BY 2,3", 100);
  oContacts.setMaxRows(Integer.parseInt(sMaxr));

  JDCConnection oConn = null;  
  int iContacts = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("loadfellows");
    if (null==sFind)
      iContacts = oContacts.load(oConn, new Object[]{request.getParameter("gu_workarea")});
    else
      iContacts = oContacts.load(oConn, new Object[]{"%"+sFind+"%","%"+sFind+"%",request.getParameter("gu_workarea")});

	  if (sAddr!=null) {
	    oAddr.load(oConn, sAddr);

	    //sGuTrm = Term.getIdFromText(oConn, 2050, oAddr.getStringNull(DB.nm_state,""));

	    sGuTrm = Term.getIdFromText(oConn, ACLDomain.forWorkArea(oConn, oAddr.getString(DB.gu_workarea)).intValue(), oAddr.getStringNull(DB.nm_state,""));
	    if (null!=sGuTrm) {
	      Term oTerm = new Term();	      
	      oTerm.load(oConn, sGuTrm);
	      sGuTrm = oTerm.getParent (oConn);
	      if (null==sGuTrm) sGuTrm = oTerm.getString(DB.gu_term);
	      Term oParent = new Term();	      
	      oParent.load(oConn, sGuTrm);
	      sTxTrm = oParent.getString(DB.tx_term);
	    } // fi
	  } // fi
	  
    out.write("    // gu_address= "+sAddr+";\n");
    out.write("    // id_domain= "+ACLDomain.forWorkArea(oConn, oAddr.getStringNull(DB.gu_workarea,""))+";\n");
    out.write("    // gu_workarea= "+oAddr.getStringNull(DB.gu_workarea,"")+";\n");
    out.write("    // nm_state= "+oAddr.getStringNull(DB.nm_state,"")+";\n");
    out.write("    // gu_term= "+sGuTrm+";\n");
    out.write("    // tx_term= "+sTxTrm +";\n");

    oConn.close("loadfellows");
    oConn = null;  

    if (null==sGuTrm) {
      for (int c=0; c<iContacts; c++) {
        out.write("    opt = doc.createElement(\"OPTION\");\n");
        out.write("    opt.value = \"" + oContacts.getString(0,c) + "\";\n");
        out.write("    opt.text = \"" + oContacts.getStringNull(1,c,"") + " " + oContacts.getStringNull(2,c,""));
        if (!oContacts.isNull(3,c)) out.write(" ("+oContacts.getString(3,c)+")");
        out.write("\";\n");
        out.write("    frm.sel_users.options.add(opt);\n");
      } // next c
    } else {
      for (int c=0; c<iContacts; c++) {
        if (sTxTrm.equals(oContacts.getStringNull(3,c,""))) {
          out.write("    opt = doc.createElement(\"OPTION\");\n");
          out.write("    opt.value = \"" + oContacts.getString(0,c) + "\";\n");
          out.write("    opt.text = \"" + oContacts.getStringNull(1,c,"") + " " + oContacts.getStringNull(2,c,"") + " (" + oContacts.getString(3,c) + ")\";\n");
          out.write("    frm.sel_users.options.add(opt);\n");
        } // fi
      } // next c    
      for (int c=0; c<iContacts; c++) {
        if (!sTxTrm.equals(oContacts.getStringNull(3,c,""))) {
          out.write("    opt = doc.createElement(\"OPTION\");\n");
          out.write("    opt.value = \"" + oContacts.getString(0,c) + "\";\n");
          out.write("    opt.text = \"" + oContacts.getStringNull(1,c,"") + " " + oContacts.getStringNull(2,c,""));
          if (!oContacts.isNull(3,c)) out.write(" ("+oContacts.getString(3,c)+")");
          out.write("\";\n");
          out.write("    frm.sel_users.options.add(opt);\n");
        }
      } // next c
    } // fi
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("loadfellows");

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
      
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));  
  }

%>
  } //-->
</SCRIPT>
</HEAD>
<BODY onLoad="setList()">
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>