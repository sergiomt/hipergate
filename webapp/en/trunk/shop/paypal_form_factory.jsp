<%@ page import="java.text.DecimalFormat,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%
  String sPayPalMerchantId = "info@knowgate.es";
  boolean bPayPalIPNEnabled = false;
  String sPayPalReturnURL  = "";
  String sPayPalReturnCancelURL = "";
  
  // Want to add fees charged by PayPal to the final order costs?
  boolean bPayPalAddChargedFees = true;

  // PayPal Merchant Accounts could have "Standard" (higher) or "Merchant" (lower) rates.
  // Rates are calculated depending on the type of the account.
  boolean bPayPalUseMerchantRate = false;

  // DO NOT EDIT BELOW THIS LINE!!!
  
  JDCConnection oConn = null;
  String gu_order = request.getParameter("gu_order");
  String sOrderId = "";
  double lOrderCost = 0;
  String sCurrency = "";

  String sSQL = "";
  sSQL += "SELECT o.pg_order,o.im_total,lc.alpha_code FROM k_orders o, k_lu_currencies lc ";
  sSQL += "WHERE lc.numeric_code=o.id_currency AND o.gu_order=?";

  try {
    oConn = GlobalDBBind.getConnection("paypal_form_factory");
    PreparedStatement oStmt = oConn.prepareStatement(sSQL);
    oStmt.setString (1, gu_order);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      sOrderId   = oRSet.getString(1);
      lOrderCost = oRSet.getDouble(2);
      sCurrency  = oRSet.getString(3);
    }
    oRSet.close();
    oStmt.close();
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("paypal_form_factory");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  oConn = null;  
  
  // Check currency type and calculate rates.
  if (bPayPalAddChargedFees) {
    if (bPayPalUseMerchantRate) {
      // Merchant Rates
      if (sCurrency.equals("USD"))
        lOrderCost = (lOrderCost * 1.022) + 0.30;
      else if (sCurrency.equals("CAD"))
        lOrderCost = (lOrderCost * 1.027) + 0.55;
      else if (sCurrency.equals("EUR"))
        lOrderCost = (lOrderCost * 1.027) + 0.35;
      else if (sCurrency.equals("GBP"))
        lOrderCost = (lOrderCost * 1.027) + 0.20;
      else if (sCurrency.equals("JPY"))
        lOrderCost = (lOrderCost * 1.027) + 40;
    } else {
      // Standard Rates
      if (sCurrency.equals("USD"))
        lOrderCost = (lOrderCost * 1.029) + 0.30;
      else if (sCurrency.equals("CAD"))
        lOrderCost = (lOrderCost * 1.034) + 0.55;
      else if (sCurrency.equals("EUR"))
        lOrderCost = (lOrderCost * 1.034) + 0.35;
      else if (sCurrency.equals("GBP"))
        lOrderCost = (lOrderCost * 1.034) + 0.20;
      else if (sCurrency.equals("JPY"))
        lOrderCost = (lOrderCost * 1.034) + 40;
    }
  }
  
  String sFinalCost = String.valueOf(lOrderCost);
  sFinalCost = sFinalCost.substring(0,sFinalCost.indexOf(".") + 3);

  String sThisURL = "http://saturno:8001/knowgate/shop";

  if (sPayPalReturnURL.equals("")) {
    if (bPayPalIPNEnabled)
      sPayPalReturnURL = sThisURL + "/paypal_return_ipn.jsp";
    else
      sPayPalReturnURL = sThisURL + "/paypal_return.jsp";
  }
  if (sPayPalReturnCancelURL.equals("")) {
    if (bPayPalIPNEnabled)
      sPayPalReturnCancelURL = sThisURL + "/paypal_cancel_ipn.jsp";
    else
      sPayPalReturnCancelURL = sThisURL + "/paypal_cancel.jsp";
  }
%>
<!-- PayPal method. Last Revision: February 12, 2004 -->
<form name="hgPayPal" action="https://www.sandbox.paypal.com/cgi-bin/webscr" method="post">
<input type="hidden" name="cmd"			value="_xclick">
<input type="hidden" name="business"		value="<%=sPayPalMerchantId%>">
<input type="hidden" name="amount"		value="<%=sFinalCost%>">
<input type="hidden" name="currency_code"	value="<%=sCurrency%>">
<input type="hidden" name="item_name"		value="Order #<%=sOrderId%>">
<input type="hidden" name="invoice"		value="<%=gu_order%>">
<input type="hidden" name="image_url"		value="https://www.hipergate.org/images/hgLogo-paypal.gif">
<input type="hidden" name="page_style"		value="paypal">
<input type="hidden" name="no_note"		value="1">
<input type="hidden" name="no_shipping"		value="1">
<input type="hidden" name="return"		value="<%=sPayPalReturnURL%>">
<input type="hidden" name="cancel_return"	value="<%=sPayPalReturnCancelURL%>">
<input type="hidden" name="rm"			value="2">
<!--
Other Buttons:
Pill,  "Buy Now":		https://www.paypal.com/en_US/i/btn/x-click-but23.gif
Pill,  "Subscribe":		https://www.paypal.com/en_US/i/btn/x-click-but24.gif
Small, "Credit Cards":		https://www.paypal.com/en_US/i/btn/x-click-butcc.gif
Small, "Buy Now":		https://www.paypal.com/en_US/i/btn/x-click-but01.gif
Small, "Payments":		https://www.paypal.com/en_US/i/btn/x-click-but02.gif
Small, "Check Out":		https://www.paypal.com/en_US/i/btn/x-click-but03.gif
Small, "Pay Now":		https://www.paypal.com/en_US/i/btn/x-click-but06.gif
Small, "Subscribe":		https://www.paypal.com/en_US/i/btn/x-click-but20.gif
Large, "Click here to buy":	https://www.paypal.com/en_US/i/btn/x-click-but5.gif
Large, "Click here to pay":	https://www.paypal.com/en_US/i/btn/x-click-but6.gif
-->
<input type="image" src="https://www.paypal.com/en_US/i/btn/x-click-but01.gif" style="border:0" name="submit" alt="Process payment using Paypal">
</form>
<!--
  <script language="JavaScript">document.forms['hgPayPal'].submit()</script>
-->