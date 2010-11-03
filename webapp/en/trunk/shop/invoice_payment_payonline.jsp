<%@ page import="java.math.BigDecimal,java.util.Date,java.text.SimpleDateFormat,java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.cyberpac.TPV,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.InvoicePayment" language="java" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_user = getCookie (request, "userid", null);

  String gu_invoice = request.getParameter("gu_invoice");
  Integer pg_payment = new Integer(request.getParameter("pg_payment"));
  BigDecimal im_paid = new BigDecimal(request.getParameter("im_paid"));

  SimpleDateFormat oDtFmt = new SimpleDateFormat("yyMMdd");

  JDCConnection oConn = null;
  InvoicePayment oPaym = new InvoicePayment();

  try {
    oConn = GlobalDBBind.getConnection("invoice_payment_payonline");
      	
    String sInvcDesc = DBCommand.queryStr(oConn, "SELECT "+DB.de_order+" FROM "+DB.k_invoices+" WHERE "+DB.gu_invoice+"='"+gu_invoice+"'");

    int iTransactId = GlobalDBBind.nextVal(oConn, "seq_k_transactions");
    String sTransactId = oDtFmt.format(new Date())+Gadgets.leftPad(String.valueOf(iTransactId),'0',6);


		if (!oPaym.load(oConn, new Object[]{gu_invoice,pg_payment}))
		  throw new SQLException ("Invoice payment "+gu_invoice+" "+pg_payment+" not found");
		
		oPaym.replace(DB.id_transact, sTransactId);

	  oConn.setAutoCommit(false);

		oPaym.store(oConn);

    DBAudit.log(oConn, InvoicePayment.ClassId, "TPV0", id_user, gu_invoice, null, iTransactId, getClientIP(request), pg_payment.toString(), oPaym.getStringNull(DB.id_ref,""));
    
    oConn.commit();

    oConn.close("invoice_payment_payonline");

		TPV oSermepa = new TPV(new File("C:\\caixa.txt"));

	  out.write(oSermepa.post(sTransactId,
	  												sInvcDesc==null ? "" : sInvcDesc,
	  												new BigDecimal(im_paid.intValue()),
	  												"gu_invoice:"+gu_invoice+";pg_payment:"+pg_payment.toString()+";id_ref:"+oPaym.getStringNull(DB.id_ref,"") ) );

  }
  catch (SQLException e) {
    disposeConnection(oConn,"invoice_payment_payonline");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  /* TO DO: Write HTML or redirect to another page */
%>