<%@ page import="java.text.DecimalFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.training.AcademicCourse,com.knowgate.training.AcademicCourseBooking" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%!
  public AcademicCourseBooking seekContact(AcademicCourseBooking[] aBooks, String sGuContact) {
    AcademicCourseBooking oACBk = null;
    if (null!=aBooks) {
      for (int b=0; b<aBooks.length && null==oACBk; b++) {
        if (aBooks[b].getString(DB.gu_contact).equals(sGuContact)) {
          oACBk = aBooks[b];
        } // fi
      } // next
    } // fi (aBooks)
    return oACBk;
  } // seekContact
%><%
/*
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

  DecimalFormat oFmt2 = new DecimalFormat("#0.00");
  oFmt2.setMaximumFractionDigits(2);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String gu_workarea = getCookie(request,"workarea","");  
  String gu_acourse = request.getParameter("gu_acourse");
  String chckditems = request.getParameter("checkeditems");
  String gu_discard = request.getParameter("gu_discard");
  if (null!=gu_discard) chckditems = Gadgets.replace(Gadgets.replace(chckditems,gu_discard,""),",,",",");
  String alumnilist = "('"+Gadgets.replace(chckditems,",","','")+"')";

  JDCConnection oConn = null;
  AcademicCourseBooking oBook;
  AcademicCourseBooking[] aBook = null;
  AcademicCourse oAcrs = new AcademicCourse();
  DBSubset oList = new DBSubset(DB.k_contacts, DB.tx_name+","+DB.tx_surname+","+DB.gu_contact, DB.gu_contact+" IN "+alumnilist+" ORDER BY 1,2", 100);
  DBSubset oShop = new DBSubset(DB.k_shops, DB.gu_shop+","+DB.nm_shop, DB.gu_workarea+"=? ORDER BY 2", 10);
  int nShop = 0;
  int nAlmn = 0;
  boolean bCanCreateInvoice = false;
  
  try {    
    oConn = GlobalDBBind.getConnection("acourse_book", true);
    oAcrs.load(oConn, new Object[]{gu_acourse});
    aBook = oAcrs.getAllBookings(oConn);
    nAlmn = oList.load(oConn);
    nShop = oShop.load(oConn, new Object[]{gu_workarea});
    bCanCreateInvoice = DBCommand.queryExists(oConn, DB.k_products, DB.gu_product+"='"+gu_acourse+"'");
    oConn.close("acourse_book");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("acourse_book");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Registrations</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/grid.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      var jsPaymentsGrid;

      var jsTableHeader = "<TABLE WIDTH=200><TR><TD CLASS=formplain>Amount</TD><TD CLASS=formplain>Date</TD></TR>";
      var jsTableFooter = "</TABLE>";
      var jsTableName = "paymentlines";
      
      var pr_acourse = "<% if (!oAcrs.isNull(DB.pr_acourse)) { out.write(oFmt2.format(oAcrs.getDecimal(DB.pr_acourse).doubleValue())); } %>";
      var pr_payment = "<% if (!oAcrs.isNull(DB.pr_payment)) { out.write(oFmt2.format(oAcrs.getDecimal(DB.pr_payment).doubleValue())); } %>";

      // ------------------------------------------------------

      function switchInvoicing(onoff) {
        if (onoff) {
        	document.getElementById("paymentsyesno").style.display="block";
        	document.getElementById("paymentslabel").style.display="block";
        	document.getElementById("forwhat").style.visibility="visible";  	
        	document.getElementById("shop").style.display="block";
        	document.forms[0].gu_shop.style.visibility="visible";
        } else {
        	document.forms[0].bo_payments.checked=false;
        	document.forms[0].sel_payments.selectedIndex=0;
        	document.forms[0].sel_payments.style.visibility="hidden";
        	document.forms[0].gu_shop.style.visibility="hidden";
        	document.getElementById("shop").style.display="none";
        	document.getElementById("paymentsyesno").style.display="none";
        	document.getElementById("paymentslabel").style.display="none";
        	document.getElementById("forwhat").style.visibility="hidden";
        }
      }

      // ------------------------------------------------------

      function switchPayments(onoff) {
        if (onoff) {
        	document.getElementById("paymentscount").style.display="block";
        	document.getElementById("paymentlines").style.display="block";
        	document.forms[0].sel_payments.style.visibility="visible";
        } else {
        	document.getElementById("paymentscount").style.display="none";
        	document.getElementById("paymentlines").style.display="none";
        	document.forms[0].sel_payments.style.visibility="hidden";        
        }
      }

      // ------------------------------------------------------
    
			function showPaymentLines() {
        var oRow;
        var nRows = Number(getCombo(document.forms[0].sel_payments));
          				
				jsPaymentsGrid = GridCreate(nRows,2);

				for (var r=0; r<nRows; r++) {
          var s = String(r);
          oRow = GridCreateRow(jsPaymentsGrid, s);       
  	      GridCreateInputCell(oRow, 0, "im_paid_"+s, "im_paid_"+s, "text", pr_payment, 12, 12, "onchange='GridSetCellValue(jsPaymentsGrid,0,"+s+",this.value)'");
  	      GridCreateInputCell(oRow, 1, "dt_payment_"+s, "dt_payment_"+s, "text", "", 12, 10, "onchange='GridSetCellValue(jsPaymentsGrid,1,"+s+",this.value)'");
        }

	      GridDraw (jsPaymentsGrid, jsTableName, jsTableHeader, jsTableFooter);

			} // showPaymentLines

      // ------------------------------------------------------

      function remove(guid) {
 	      var frm = window.document.forms[0];
 	      var ls1 = frm.checkeditems.value.split(",");
 	      var ls2 = new Array();
 	      for (var a=0; a<ls1.length; a++) {
 	        if (ls1[a]!=guid) ls2.push(ls1[a]);
 	      }
 	      frm.gu_discard.value = guid;
        frm.action = "acourse_book.jsp";        
        frm.checkeditems.value = ls2.join(","); 
        frm.submit();
      }

      // ------------------------------------------------------

      function validate() {
        var cvl, cdt;
        var frm = window.document.forms[0];

				if (frm.im_paid.value.length>0) {
	        if (!isFloatValue(frm.im_paid.value.replace(",","."))) {
	          alert ("Paid amount is not valid");
	          return false;	
	        } else {
	          frm.im_paid.value = frm.im_paid.value.replace(",",".");
	        }
	      }

				if (frm.im_paid.value.length>0) {
				  frm.bo_paid.checked = true;
				}

        if (frm.dt_paid.value.length>0 && !isDate(frm.frm.dt_paid.value, "d")) {
	        alert ("Payment date is not valid");
	        return false;	
        }

				if (frm.bo_invoice.checked) {
			    if (getCheckedValue(frm.invoice_for)==null) {
	      		alert ("Please set whether the invoice must be sent to the company or to the individual");
	      		return false;
			    } // fi
			    if (frm.gu_shop.selectedIndex<=0) {
	      		alert ("The catalog for the invoice is required");
	      		frm.gu_shop.focus();
	      		return false;
			    }
			  } // fi

				if (frm.bo_payments.checked) {
			    for (var r=0; r<jsPaymentsGrid.rowcount; r++) {
	  		    cvl = GridGetCellValue(jsPaymentsGrid, 0, r);
	  	  
	  		    if (null!=cvl) {
	  		    	cvl = cvl.replace(",",".");
	    		    if (!isFloatValue(cvl)) {
	      		    alert ("Amount paid " + String(r+1) + " is not valid");
	      		    return false;
	            } else {
	              GridSetCellValue(jsPaymentsGrid,0,r,cvl);
	            }
            }
            
	  		    cdt = GridGetCellValue(jsPaymentsGrid, 1, r);
	  	  
	  		    if (null!=cdt) {
	    		    if (cdt.length>0) {
	    		    	if (!isDate(cdt,"d")) {
	      		      alert ("Date " + cdt + " for payment " + String(r+1) + " is not valid");
	      		      return false;
	              } else if (r>0 && isDate(GridGetCellValue(jsPaymentsGrid, 1, r-1))) {
	              	if (parseDate(cdt, "d")<parseDate(GridGetCellValue(jsPaymentsGrid, 1, r-1), "d")) {
	      		        alert ("Payment date " + String(r+1) + " must be after the payment one "+String(r));
	      		        return false;
	              	}
	              }
	              if (!isFloatValue(cvl)) {
	      		      alert ("The amounts for all payments must be specified");
	      		      return false;	                
	              }
	            } // fi (cdt!="")
	          } // fi (cdt!=null)

	        } // next
        } // fi

        frm.payments.value = GridToString(jsPaymentsGrid,";","|");

        return true;
      } // validate;

      // ------------------------------------------------------
      
      function setCombos() {
        var frm = document.forms[0];
<% if (bCanCreateInvoice) {
     if (!oAcrs.isNull(DB.nu_payments)) { %>
        // Do not generate monthly payments by defualt, even if they are set at academic course definition
        // setCombo(frm.sel_payments, "<%=String.valueOf(oAcrs.getInt(DB.nu_payments))%>");
        // showPaymentLines();      
<% } } %>        
      }
      
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Add or modify course registrations</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="acourse_book_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_acourse" VALUE="<%=gu_acourse%>">
    <INPUT TYPE="hidden" NAME="checkeditems" VALUE="<%=chckditems%>">
    <INPUT TYPE="hidden" NAME="payments" VALUE="">
    <INPUT TYPE="hidden" NAME="gu_discard" VALUE="<% if (aBook!=null) for (int d=0; d<aBook.length; d++) out.write((0==d ? "" : ",")+aBook[d].getString(DB.gu_contact)); %>">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Course</TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain"><%=oAcrs.getString(DB.nm_course)%><% if (!oAcrs.isNull(DB.id_course)) out.write("&nbsp;("+oAcrs.getString(DB.id_course)+")"); %></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right"><INPUT TYPE="radio" NAME="bo_waiting" VALUE="0" CHECKED></TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain">Reserved</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right"><INPUT TYPE="radio" NAME="bo_waiting" VALUE="1"></TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain">Waiting List</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right"><INPUT TYPE="checkbox" NAME="bo_confirmed" VALUE="1"></TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain">Confirmed</TD>
          </TR>
          <TR><TD COLSPAN="2"><HR></TD></TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Booking</TD>
            <TD ALIGN="left" WIDTH="470"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right" CLASS="formplain">Amount</TD>
            </TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain">
            	<INPUT TYPE="text" NAME="im_paid" MAXLENGTH="14" SIZE="10" VALUE="<% if (!oAcrs.isNull(DB.im_paid)) { out.write(oFmt2.format(oAcrs.getDecimal(DB.im_paid).doubleValue())); } else if (!oAcrs.isNull(DB.pr_booking)) { out.write(oFmt2.format(oAcrs.getDecimal(DB.pr_booking).doubleValue())); } %>">&nbsp;&nbsp;&nbsp;
            	Paid&nbsp;<INPUT TYPE="checkbox" NAME="bo_paid" VALUE="1" onclick="if (this.checked) { if (document.forms[0].im_paid.value.length==0) document.forms[0].im_paid.value=pr_acourse; if (document.forms[0].dt_paid.value.length==0) document.forms[0].dt_paid.value=dateToString(new Date(),'d'); } else { document.forms[0].im_paid.value=''; document.forms[0].dt_paid.value=''; }">&nbsp;&nbsp;&nbsp;
            	Date&nbsp;<INPUT TYPE="text" NAME="dt_paid" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oAcrs.isNull(DB.dt_paid)) out.write(oAcrs.getDateShort(DB.dt_paid)); %>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right"></TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain">Payment means&nbsp;<SELECT NAME="tp_billing"><OPTION VALUE=""></OPTION><OPTION VALUE="T">Wire Transfer</OPTION><OPTION VALUE="C">Check</OPTION><OPTION VALUE="M">Cash</OPTION><OPTION VALUE="A">Credit Card</OPTION></SELECT></TD>
          </TR>
<% if (bCanCreateInvoice) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="checkbox" NAME="bo_invoice" VALUE="1" onclick="switchInvoicing(this.checked)"></TD>
            <TD ALIGN="left" WIDTH="470">
            <TABLE BORDER="0"><TR><TD CLASS="formplain">Generate Invoice</TD><TD><DIV ID="forwhat" STYLE="visibility:hidden" CLASS="formplain"><INPUT TYPE="radio" NAME="invoice_for" VALUE="90" CHECKED="checked">&nbsp;For Individual&nbsp;&nbsp;<INPUT TYPE="radio" NAME="invoice_for" VALUE="91">&nbsp;For Company</DIV></TD></TR></TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="470">
              <DIV ID="shop" STYLE="display:none" CLASS="formplain">At Catalog&nbsp;<SELECT NAME="gu_shop" CLASS="combomini" STYLE="display:hidden"><OPTION VALUE=""></OPTION><% for (int s=0; s<nShop; s++) out.write("<OPTION VALUE=\""+oShop.getString(0,s)+"\" "+(s==0 ? "SELECTED=\"selected\"" : "")+">"+oShop.getString(1,s)+"</OPTION>"); %></SELECT></DIV>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><DIV ID="paymentsyesno" STYLE="display:none"><INPUT TYPE="checkbox" NAME="bo_payments" VALUE="1" onclick="switchPayments(this.checked)"></DIV></TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain"><DIV ID="paymentslabel" STYLE="display:none">Create additional payments</DIV></TD>
          </TR>
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="90"><DIV ID="paymentscount" STYLE="display:none"><SELECT NAME="sel_payments" STYLE="display:hidden" CLASS="combomini" onchange="showPaymentLines()"><OPTION VALUE="0" SELECTED="selected">0</OPTION><OPTION VALUE="1">1</OPTION><OPTION VALUE="2">2</OPTION><OPTION VALUE="3">3</OPTION><OPTION VALUE="4">4</OPTION><OPTION VALUE="5">5</OPTION><OPTION VALUE="6">6</OPTION><OPTION VALUE="7">7</OPTION><OPTION VALUE="8">8</OPTION><OPTION VALUE="9">9</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION></SELECT></DIV></TD>
            <TD ALIGN="left" WIDTH="470"><DIV ID="paymentlines" STYLE="display:none"></DIV></TD>
          </TR>
<% } %>
          <TR><TD COLSPAN="2"><HR></TD></TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Room</TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="text" NAME="id_classroom" MAXLENGTH="30" SIZE="30"></TD>
          </TR>
          <TR><TD COLSPAN="2"><HR></TD></TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong" VALIGN="top">Students</TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain">
	      <TABLE SUMMARY="Alumni List" WIDTH="100%" CLASS="formback">
	      
<% for (int a=0; a<nAlmn; a++) {
     oBook = seekContact(aBook, oList.getString(DB.gu_contact,a));
     if (null==oBook) {
       out.write("<TR CLASS=\"formfront\"><TD ALIGN=\"left\" CLASS=\"formplain\">"+oList.getStringNull(DB.tx_name,a,"")+"&nbsp;"+oList.getStringNull(DB.tx_surname,a,"")+"</TD>");
       out.write("<TD ALIGN=\"right\" WIDTH=\"128\"><A HREF=\"#\" CLASS=\"linkplain\" TITLE=\"Discard Student\" onclick=\"remove('"+oList.getString(DB.gu_contact,a)+"')\"><IMG SRC=\"../images/images/delete.gif\" WIDTH=\"13\" HEIGHT=\"13\" HSPACE=\"4\" BORDER=\"0\" ALT=\"Discard\">Discard</A></TD></TR>");
     } else {
       out.write("<TR CLASS=\"formback\"><TD ALIGN=\"left\" CLASS=\"formplain\">"+oList.getStringNull(DB.tx_name,a,"")+"&nbsp;"+oList.getStringNull(DB.tx_surname,a,"")+"</TD>");
       out.write("<TD ALIGN=\"right\" WIDTH=\"128\" CLASS=\"formplain\">");
       if (oBook.canceled())
         out.write("Cancelled");
       else if (oBook.paid())
         out.write("Paid");
       else if (oBook.confirmed())
         out.write("Confirmed");
       else if (oBook.waiting())
         out.write("Waiting");
       else
         out.write("Reserved");
       out.write("</TD></TR>");
     } // fi (oBook)
   } // next %>
	      </TABLE>
            </TD>
          </TR>
          <TR><TD COLSPAN="2"><HR></TD></TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>
    	</TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
