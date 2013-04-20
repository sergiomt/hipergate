<%@ page import="java.text.DecimalFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.InvoicePayment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "invoice_payment_edit";
  
  DecimalFormat oFmt2 = new DecimalFormat("#0.00");
	oFmt2.setMaximumFractionDigits(2);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_invoice = request.getParameter("gu_invoice");
  Integer pg_payment = new Integer(request.getParameter("pg_payment"));

  String id_user = getCookie(request, "userid", "");
  
  InvoicePayment oObj = new InvoicePayment();
  
  String sBillingLookUp = "";
    
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

    sBillingLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_invoices_lookup, gu_workarea, DB.tp_billing, sLanguage);
    
    oObj.load(oConn, new Object[]{gu_invoice,pg_payment});
    
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Payment</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_invoices_lookup&id_language=" + getUserLanguage() + "&id_section=tp_billing&tp_control=2&nm_control=sel_billing&nm_coding=tp_billing", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
	          // window.open("...
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

				if (frm.tx_comments.value.length>254) {
					alert ("Comments may not be longer that 254 characters");
				  frm.tx_comments.focus();
				  return false;
				}

				if (frm.dt_payment.value.length>0 && !isDate(frm.dt_payment.value, "d")) {
					alert ("Estimated payment date is not valid");
				  frm.dt_payment.focus();
				  return false;
				}

				if (frm.dt_paid.value.length>0 && !isDate(frm.dt_paid.value, "d")) {
					alert ("Actual payment date is not valid");
				  frm.dt_paid.focus();
				  return false;
				}
				
				if (isFloatValue(removeThousandsDelimiter(frm.im_paid.value))) {
			    frm.im_paid.value = removeThousandsDelimiter(frm.im_paid.value);
			  } else {
					alert ("Amount is not valid");
				  frm.im_paid.focus();
				  return false;				
				}

				frm.tp_billing.value = getCombo(frm.sel_billing);
				frm.bo_active.value = frm.chk_active.checked ? "1" : "0";
        
        return true;
      } // validate;

      // ------------------------------------------------------

			function openTPV() {
        var frm = document.forms[0];
				if (isFloatValue(removeThousandsDelimiter(frm.im_paid.value))) {
			    document.location = "invoice_payment_payonline.jsp?gu_invoice=<%=gu_invoice%>&pg_payment=<%=pg_payment.toString()%>&im_paid="+removeThousandsDelimiter(frm.im_paid.value);
				} else {
					alert ("Amount is not valid");
				  frm.im_paid.focus();
				  return false;				
			  }
			} // openTPV

      // ------------------------------------------------------

      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_billing,"<% out.write(oObj.getStringNull(DB.tp_billing ,"")); %>");
        setCombo(frm.id_currency,"<% out.write(oObj.getStringNull(DB.id_currency,"")); %>");
        
        return true;
      } // validate;
    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Payment</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="invoice_payment_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_invoice" VALUE="<%=oObj.getString(DB.gu_invoice)%>">
    <INPUT TYPE="hidden" NAME="pg_payment" VALUE="<%=String.valueOf(oObj.getInt(DB.pg_payment))%>">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="<% if (oObj.isNull(DB.bo_active)) out.write("1"); else out.write(String.valueOf(oObj.getShort(DB.bo_active))); %>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="180"><FONT CLASS="formstrong">Active</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="checkbox" NAME="chk_active" VALUE="1" <% if (oObj.isNull(DB.bo_active)) out.write("CHECKED"); else out.write(oObj.getShort(DB.bo_active)!=0 ? "CHECKED" : ""); %>></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="180"><FONT CLASS="formstrong">Amount</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
            	<INPUT TYPE="text" NAME="im_paid" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oObj.isNull(DB.im_paid)) out.write(oFmt2.format(oObj.getDecimal(DB.im_paid))); %>">
            	&nbsp;&nbsp;
            	<SELECT NAME="id_currency"><OPTION VALUE=""></OPTION><OPTION VALUE="978">EUR</OPTION><OPTION VALUE="840">USD</OPTION><OPTION VALUE="826">GBP</OPTION><OPTION VALUE="392">YEN</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Payment mean</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tp_billing">
              <SELECT NAME="sel_billing"><OPTION VALUE=""></OPTION><%=sBillingLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Show payment means"></A>
            </TD>
          </TR>
<% if (oObj.isNull(DB.dt_paid)) { %>          
          <TR>
            <TD ALIGN="right" WIDTH="180"><IMG SRC="../images/images/shop/credicards16.gif" WIDTH="16" HEIGHT="16" ALT="Credit Cards" BORDER="0"></TD>
            <TD ALIGN="left" WIDTH="370">
              <A CLASS="linkplain" HREF="#" onclick="openTPV()">Pay with Card</A>
            </TD>
          </TR>
<% } %>          
          <TR>
            <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Estimated payment date</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_payment" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oObj.isNull(DB.dt_payment) ? "" : oObj.getDateFormated(DB.dt_payment,"yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_payment')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Actual payment date</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_paid" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oObj.isNull(DB.dt_paid) ? "" : oObj.getDateFormated(DB.dt_paid,"yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_paid')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Client</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_client" MAXLENGTH="200" SIZE="40" VALUE="<%=oObj.getStringNull(DB.nm_client,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Reference</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="20" VALUE="<%=oObj.getStringNull(DB.id_ref,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Transaction Num.</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="id_transact" MAXLENGTH="32" SIZE="20" VALUE="<%=oObj.getStringNull(DB.id_transact,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Comments</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><TEXTAREA NAME="tx_comments"><%=oObj.getStringNull(DB.tx_comments,"")%></TEXTAREA></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.history.back()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
