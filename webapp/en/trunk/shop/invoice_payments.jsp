<%@ page import="java.math.BigDecimal,java.text.SimpleDateFormat,java.util.Date,java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Gadgets,com.knowgate.dataobjs.*,com.knowgate.hipergate.*,com.knowgate.math.CurrencyCode" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 

  String gu_workarea = request.getParameter("gu_workarea");
  String gu_invoice = request.getParameter("gu_invoice");

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  String sBillingLookUp = null;
  HashMap oBillingLookUp = null;
  JDCConnection oConn = null;
  Invoice oInvc = new Invoice();
  DBSubset oPays = new DBSubset("k_invoice_payments",
  															"gu_invoice,pg_payment,dt_payment,id_currency,im_paid,tp_billing,nm_client,tx_comments",
  															DB.gu_invoice + "=? ORDER BY 3 DESC", 10);
  int nPays = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("invoice_payments");

		DBCurrencies.currencyCodes(oConn);

    sBillingLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_invoices_lookup, gu_workarea, DB.tp_billing, sLanguage);

    oBillingLookUp = DBLanguages.getLookUpMap(oConn, DB.k_invoices_lookup, gu_workarea, DB.tp_billing, sLanguage);
    
    oInvc.load(oConn, new Object[]{gu_invoice});
    
    nPays = oPays.load(oConn, new Object[]{gu_invoice});

    oConn.close("invoice_payments");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("invoice_payments");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;
%>
<HTML LANG="<% out.write(sLanguage); %>">
  <HEAD>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
      <!--
        function validate () {
          var frm = document.forms[0];
          if (!isDate(frm.dt_payment.value,"d")) {
          	alert("[~La fecha no es válida~]");
          	frm.dt_payment.focus();
            return false;
          } // fi
          if (!isFloatValue(frm.im_paid.value)) {
          	alert("[~El importe es válido~]");
          	frm.im_paid.focus();
            return false;
          }
          if (frm.tp_billing.selectedIndex<=0) {
          	alert("Payment mean is required");
          	frm.tp_billing.focus();
            return false;
          }
          return true;
        } // validate
      //-->
    </SCRIPT>
    <TITLE>hipergate :: Payments List</TITLE>
  </HEAD>
  <BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombo(document.forms[0].id_currency,'<% out.write(oInvc.getString(DB.id_currency)); %>')">
    <DIV class="cxMnu1" style="width:190px"><DIV class="cxMnu2">
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='invoice_edit.jsp?gu_invoice=<%=gu_invoice%>&gu_workarea=<%=gu_workarea%>'"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
    </DIV></DIV>
    <TABLE WIDTH="100%">
      <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
      <TR><TD CLASS="striptitle"><FONT CLASS="title1">Payments for Invoice <% out.write(String.valueOf(oInvc.getInt(DB.pg_invoice))); %></FONT></TD></TR>
    </TABLE>
    <FORM METHOD="post" ACTION="invoice_payment_store.jsp" onSubmit="return validate()">
    	<INPUT TYPE="hidden" NAME="gu_invoice" VALUE="<%=gu_invoice%>">
    	<INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <TABLE SUMMARY="Payments" CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Amount</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Payment mean</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Paid by</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Comments</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
				</TR>
<% BigDecimal oTotal = new BigDecimal(0);
   for (int p=0; p<nPays; p++) {
      String sStrip = String.valueOf((p%2)+1);
      oTotal = oTotal.add(oPays.getDecimal(4,p));
      CurrencyCode oCurCod = DBCurrencies.currencyCodeFor(Integer.parseInt(oPays.getString(3,p).trim()));
      if (oCurCod==null) throw new NullPointerException("Cannot find currency code for \""+oPays.getString(3,p).trim()+"\"");
      out.write("<TR><TD CLASS=\"strip"+sStrip+"\">"+oPays.getDateShort(2,p)+"</TD>");      
      out.write("<TD CLASS=\"strip"+sStrip+"\" ALIGN=\"right\">"+Gadgets.formatCurrency(oPays.getDecimal(4,p),oCurCod.alphaCode(),sLanguage,null)+"</TD>");
      out.write("<TD CLASS=\"strip"+sStrip+"\">"+oBillingLookUp.get(oPays.getString(5,p))+"</TD>");
      out.write("<TD CLASS=\"strip"+sStrip+"\">"+oPays.getStringNull(6,p,"")+"</TD>");
      out.write("<TD CLASS=\"strip"+sStrip+"\">"+oPays.getStringNull(7,p,"")+"</TD>");
      out.write("<TD CLASS=\"strip"+sStrip+"\"><A HREF=\"invoice_payment_delete.jsp?gu_invoice="+gu_invoice+"&gu_workarea="+gu_workarea+"&pg_payment="+String.valueOf(oPays.getInt(1,p))+"\" TITLE=\"Delete Payent\"><IMG SRC=\"../images/images/delete.gif\" WIDTH=\"13\" HEIGHT=\"13\" BORDER=\"0\" ALT=\"Delete\"></A></TD></TR>");
   } %>
        <TR>
          <TD CLASS="strip1"><B>Total Paid</B></TD>
          <TD CLASS="strip1" ALIGN="right"><B><%=Gadgets.formatCurrency(oTotal,DBCurrencies.currencyCodeFor(Integer.parseInt(oInvc.getString(DB.id_currency).trim())).alphaCode(),sLanguage,null)%></B></TD>
          <TD COLSPAN="5"></TD>
        </TR>
        <TR>        	
          <TD CLASS="strip1"><INPUT TYPE="text" MAXLENGTH="10" SIZE="12" NAME="dt_payment" VALUE="<%=new SimpleDateFormat("yyyy-MM-dd").format(new Date())%>"></TD>
          <TD CLASS="strip1"><INPUT TYPE="text" MAXLENGTH="10" SIZE="8" NAME="im_paid">&nbsp<SELECT NAME="id_currency"><OPTION VALUE=""></OPTION><OPTION VALUE="978">EUR</OPTION><OPTION VALUE="840">USD</OPTION><OPTION VALUE="826">GBP</OPTION><OPTION VALUE="392">YEN</OPTION></SELECT></TD>
          <TD CLASS="strip1"><SELECT NAME="tp_billing"><OPTION VALUE=""></OPTION><%=sBillingLookUp%></SELECT></TD>
          <TD CLASS="strip1"><INPUT TYPE="text" MAXLENGTH="200" NAME="nm_client"></TD>
          <TD CLASS="strip1"><INPUT TYPE="text" MAXLENGTH="254" NAME="tx_comments"></TD>
          <TD CLASS="strip1"><INPUT TYPE="image" SRC="../images/images/floppy.gif"></TD>
				</TR>
		  </TABLE>      
    </FORM>
</HTML>
