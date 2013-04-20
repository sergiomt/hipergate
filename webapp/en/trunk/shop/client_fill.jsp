<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_client = request.getParameter("gu_client");
  String gu_workarea = request.getParameter("gu_workarea");
  
  String nm_client = "";
  String gu_contact = "";
  String gu_company = "";
  String id_legal = "";
  String tx_email_to = "";
  
  JDCConnection oConn = null;
    
  try {  
    oConn = GlobalDBBind.getConnection("client_fill");  
    
    if (DBCommand.queryExists(oConn, DB.k_contacts, DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_contact+"='"+gu_client+"'")) {
      gu_contact = gu_client;
      nm_client = Gadgets.join(DBCommand.queryStrs(oConn, "SELECT "+DB.tx_name+","+DB.tx_surname+" FROM "+DB.k_contacts+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_contact+"='"+gu_client+"'"), " ").trim();
      id_legal = nullif(DBCommand.queryStr(oConn, "SELECT "+DB.sn_passport+" FROM "+DB.k_contacts+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_contact+"='"+gu_client+"'"));
      tx_email_to = nullif(DBCommand.queryStr(oConn, "SELECT "+DB.tx_email+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_contact+"='"+gu_client+"' AND "+DB.tx_email+" IS NOT NULL ORDER BY "+DB.ix_address));
    } else if (DBCommand.queryExists(oConn, DB.k_companies, DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_company+"='"+gu_client+"'")) {
      gu_company = gu_client;
      nm_client = DBCommand.queryStr(oConn, "SELECT "+DB.nm_legal+" FROM "+DB.k_companies+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_company+"='"+gu_client+"'");
      id_legal = nullif(DBCommand.queryStr(oConn, "SELECT "+DB.sn_passport+" FROM "+DB.k_companies+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_company+"='"+gu_client+"'"));
      tx_email_to = nullif(DBCommand.queryStr(oConn, "SELECT "+DB.tx_email+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_company+"='"+gu_client+"' AND "+DB.tx_email+" IS NOT NULL ORDER BY "+DB.ix_address));
    } 
    
    oConn.close("client_fill");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("client_fill");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (oConn==null) return;
  oConn = null;
%>
<HTML>
<HEAD>
<TITLE>Wait...</TITLE>
<SCRIPT TYPE="text/javascript">
<!--
  function setCombo() {
    var opt;
    var frm = parent.msgslist.document.forms[0];

		frm.nm_client.value = "<%=nm_client%>";
		frm.gu_contact.value = "<%=gu_contact%>";
		frm.gu_company.value = "<%=gu_company%>";
		frm.id_legal.value = "<%=id_legal%>";
		frm.tx_email_to.value = "<%=tx_email_to%>";
				
		frm.tp_client[1].checked = (frm.gu_company.value.length>0);
		frm.tp_client[0].checked = (frm.gu_contact.value.length>0);
		 
    self.document.location = "../blank.htm";
  } // setCombo()    
//-->
</SCRIPT>
</HEAD>
<BODY onload="setCombo()"></BODY>
</HTML>