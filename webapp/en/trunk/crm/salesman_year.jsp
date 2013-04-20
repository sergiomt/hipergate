<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.SalesObjectives,java.math.BigDecimal" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%!
  public String dectostr(BigDecimal d) {
    String s;
    int i;
    
    if (d==null)
      return "";
    else {
      s = d.toString();
      i = s.indexOf(".");
      if (i<0)
        return s;
      else
        return s.substring(0,i);
    }
  }
%>
<% 
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
  final int Shop=20;
    
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  String sLanguage = getNavigatorLanguage(request);
  
  String gu_sales_man = request.getParameter("gu_sales_man");
  String tx_year = request.getParameter("tx_year");
  
  SalesObjectives oSalesYear = new SalesObjectives();
      
  JDCConnection oConn = null;

  boolean bIsGuest = true;
          
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("salesman_year");  
    
    oSalesYear.load(oConn, new Object[]{gu_sales_man,tx_year});
    
    oConn.close("salesman_year");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("salesman_year");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.3" TYPE="text/javascript" DEFER="defer">
    <!--

      function sum() {
	var frm = window.document.forms[0];
        var planed = 0;
        var achieved = 0;
        
        if (frm.im_jan_planed.value.length>0 && isFloatValue(frm.im_jan_planed.value))
          planed += parseFloat(frm.im_jan_planed.value);
        
        if (frm.im_jan_achieved.value.length>0 && isFloatValue(frm.im_jan_achieved.value))
	  achieved += parseFloat(frm.im_jan_achieved.value);

        if (frm.im_feb_planed.value.length>0 && isFloatValue(frm.im_feb_planed.value))
          planed += parseFloat(frm.im_feb_planed.value);
        
        if (frm.im_feb_achieved.value.length>0 && isFloatValue(frm.im_feb_achieved.value))
	  achieved += parseFloat(frm.im_feb_achieved.value);

        if (frm.im_mar_planed.value.length>0 && isFloatValue(frm.im_mar_planed.value))
          planed += parseFloat(frm.im_mar_planed.value);
        
        if (frm.im_mar_achieved.value.length>0 && isFloatValue(frm.im_mar_achieved.value))
	  achieved += parseFloat(frm.im_mar_achieved.value);

        if (frm.im_apr_planed.value.length>0 && isFloatValue(frm.im_apr_planed.value))
          planed += parseFloat(frm.im_apr_planed.value);
        
        if (frm.im_apr_achieved.value.length>0 && isFloatValue(frm.im_apr_achieved.value))
	  achieved += parseFloat(frm.im_apr_achieved.value);

        if (frm.im_may_planed.value.length>0 && isFloatValue(frm.im_may_planed.value))
          planed += parseFloat(frm.im_may_planed.value);
        
        if (frm.im_may_achieved.value.length>0 && isFloatValue(frm.im_may_achieved.value))
	  achieved += parseFloat(frm.im_may_achieved.value);

        if (frm.im_jun_planed.value.length>0 && isFloatValue(frm.im_jun_planed.value))
          planed += parseFloat(frm.im_jun_planed.value);
        
        if (frm.im_jun_achieved.value.length>0 && isFloatValue(frm.im_jun_achieved.value))
	  achieved += parseFloat(frm.im_jun_achieved.value);

        if (frm.im_jul_planed.value.length>0 && isFloatValue(frm.im_jul_planed.value))
          planed += parseFloat(frm.im_jul_planed.value);
        
        if (frm.im_jul_achieved.value.length>0 && isFloatValue(frm.im_jul_achieved.value))
	  achieved += parseFloat(frm.im_jul_achieved.value);

        if (frm.im_aug_planed.value.length>0 && isFloatValue(frm.im_aug_planed.value))
          planed += parseFloat(frm.im_aug_planed.value);
        
        if (frm.im_aug_achieved.value.length>0 && isFloatValue(frm.im_aug_achieved.value))
	  achieved += parseFloat(frm.im_aug_achieved.value);

        if (frm.im_sep_planed.value.length>0 && isFloatValue(frm.im_sep_planed.value))
          planed += parseFloat(frm.im_sep_planed.value);
        
        if (frm.im_sep_achieved.value.length>0 && isFloatValue(frm.im_sep_achieved.value))
	  achieved += parseFloat(frm.im_sep_achieved.value);

        if (frm.im_oct_planed.value.length>0 && isFloatValue(frm.im_oct_planed.value))
          planed += parseFloat(frm.im_oct_planed.value);
        
        if (frm.im_oct_achieved.value.length>0 && isFloatValue(frm.im_oct_achieved.value))
	  achieved += parseFloat(frm.im_oct_achieved.value);

        if (frm.im_nov_planed.value.length>0 && isFloatValue(frm.im_nov_planed.value))
          planed += parseFloat(frm.im_nov_planed.value);
        
        if (frm.im_nov_achieved.value.length>0 && isFloatValue(frm.im_nov_achieved.value))
	  achieved += parseFloat(frm.im_nov_achieved.value);

        if (frm.im_dec_planed.value.length>0 && isFloatValue(frm.im_dec_planed.value))
          planed += parseFloat(frm.im_dec_planed.value);
        
        if (frm.im_dec_achieved.value.length>0 && isFloatValue(frm.im_dec_achieved.value))
	  achieved += parseFloat(frm.im_jan_achieved.value);
        
        frm.im_tot_planed.value = String(planed);
        frm.im_tot_achieved.value = String(achieved);
      }

      // ----------------------------------------------------------------------

      function viewSalesHistory() {

	var w = window.opener;
		
	if (typeof(w)=="undefined")
	  window.open("../shop/order_list.jsp?salesman=<% out.write(gu_sales_man); %>&selected=7&subselected=1");
	else {
	  w.document.location.href = "../shop/order_list.jsp?salesman=<% out.write(gu_sales_man); %>&selected=7&subselected=1";
	  w.focus();
        }
      }

      // ----------------------------------------------------------------------
            
      function validate() {
        var frm = window.document.forms[0];

        if (frm.im_jan_planed.value.length>0 && !isFloatValue(frm.im_jan_planed.value)) {
          alert ("Forseen value for January is not valid");
          return false;
        }
        if (frm.im_jan_achieved.value.length>0 && !isFloatValue(frm.im_jan_achieved.value)) {
          alert ("Achieved value for January is not valid");
          return false;
        }

        if (frm.im_feb_planed.value.length>0 && !isFloatValue(frm.im_feb_planed.value)) {
          alert ("Forseen value for February is not valid");
          return false;
        }
        if (frm.im_feb_achieved.value.length>0 && !isFloatValue(frm.im_feb_achieved.value)) {
          alert ("Achieved value for February is not valid");
          return false;
        }

        if (frm.im_mar_planed.value.length>0 && !isFloatValue(frm.im_mar_planed.value)) {
          alert ("Forseen value for March is not valid");
          return false;
        }
        if (frm.im_mar_achieved.value.length>0 && !isFloatValue(frm.im_mar_achieved.value)) {
          alert ("Achieved value for March is not valid");
          return false;
        }

        if (frm.im_apr_planed.value.length>0 && !isFloatValue(frm.im_apr_planed.value)) {
          alert ("Forseen value for April is not valid");
          return false;
        }
        if (frm.im_apr_achieved.value.length>0 && !isFloatValue(frm.im_apr_achieved.value)) {
          alert ("Achieved value for April is not valid");
          return false;
        }

        if (frm.im_may_planed.value.length>0 && !isFloatValue(frm.im_may_planed.value)) {
          alert ("Forseen value for May is not valid");
          return false;
        }
        if (frm.im_may_achieved.value.length>0 && !isFloatValue(frm.im_may_achieved.value)) {
          alert ("Achieved value for May is not valid");
          return false;
        }

        if (frm.im_jun_planed.value.length>0 && !isFloatValue(frm.im_jun_planed.value)) {
          alert ("Forseen value for June is not valid");
          return false;
        }
        if (frm.im_jun_achieved.value.length>0 && !isFloatValue(frm.im_jun_achieved.value)) {
          alert ("Achieved value for June is not valid");
          return false;
        }

        if (frm.im_jul_planed.value.length>0 && !isFloatValue(frm.im_jul_planed.value)) {
          alert ("Forseen value for July is not valid");
          return false;
        }
        if (frm.im_jul_achieved.value.length>0 && !isFloatValue(frm.im_jul_achieved.value)) {
          alert ("Achieved value for July is not valid");
          return false;
        }

        if (frm.im_aug_planed.value.length>0 && !isFloatValue(frm.im_aug_planed.value)) {
          alert ("Forseen value for August is not valid");
          return false;
        }
        if (frm.im_aug_achieved.value.length>0 && !isFloatValue(frm.im_aug_achieved.value)) {
          alert ("Achieved value for August is not valid");
          return false;
        }

        if (frm.im_sep_planed.value.length>0 && !isFloatValue(frm.im_sep_planed.value)) {
          alert ("Forseen value for September is not valid");
          return false;
        }
        if (frm.im_sep_achieved.value.length>0 && !isFloatValue(frm.im_sep_achieved.value)) {
          alert ("Achieved value for September is not valid");
          return false;
        }

        if (frm.im_oct_planed.value.length>0 && !isFloatValue(frm.im_oct_planed.value)) {
          alert ("Forseen value for October is not valid");
          return false;
        }
        if (frm.im_oct_achieved.value.length>0 && !isFloatValue(frm.im_oct_achieved.value)) {
          alert ("Achieved value for October is not valid");
          return false;
        }

        if (frm.im_nov_planed.value.length>0 && !isFloatValue(frm.im_nov_planed.value)) {
          alert ("Forseen value for November is not valid");
          return false;
        }
        if (frm.im_nov_achieved.value.length>0 && !isFloatValue(frm.im_nov_achieved.value)) {
          alert ("Achieved value for November is not valid");
          return false;
        }

        if (frm.im_dec_planed.value.length>0 && !isFloatValue(frm.im_dec_planed.value)) {
          alert ("Forseen value for December is not valid");
          return false;
        }
        if (frm.im_dec_achieved.value.length>0 && !isFloatValue(frm.im_dec_achieved.value)) {
          alert ("Achieved value for December is not valid");
          return false;
        }

        if (frm.im_tot_planed.value.length>0 && !isFloatValue(frm.im_tot_planed.value)) {
          alert ("Forseen total is not valid");
          return false;
        }
        if (frm.im_tot_achieved.value.length>0 && !isFloatValue(frm.im_tot_achieved.value)) {
          alert ("Achieved total is not valid");
          return false;
        }
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0" MARGINWIDTH="8" LEFTMARGIN="8" onload="sum()">
<% if ((iAppMask & (1<<Shop))!=0) { %>
    <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" HEIGHT="4"></TD></TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD VALIGN="middle"><IMG SRC="../images/images/crm/history16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="viewSalesHistory()" CLASS="linkplain">Order History</A></TD>
      </TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    </TABLE>    
<% } %>
  <CENTER>
  <FORM NAME="" METHOD="post" ACTION="salesman_year_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_sales_man" VALUE="<%=gu_sales_man%>">
    <INPUT TYPE="hidden" NAME="tx_year" VALUE="<%=tx_year%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD><FONT CLASS="formstrong">Month</FONT></TD>
            <TD><FONT CLASS="formstrong">Forseen</FONT></TD>
            <TD><FONT CLASS="formstrong">Achieved</FONT></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">January</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_jan_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_jan_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_jan_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_jan_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">February</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_feb_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_feb_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_feb_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_feb_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">March</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_mar_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_mar_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_mar_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_mar_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">April</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_apr_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_apr_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_apr_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_apr_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">May</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_may_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_may_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_may_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_may_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">June</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_jun_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_jun_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_jun_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_jun_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">July</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_jul_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_jul_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_jul_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_jul_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">August</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_aug_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_aug_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_aug_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_aug_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">September</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_sep_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_sep_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_sep_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_sep_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">October</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_oct_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_oct_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_oct_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_oct_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">November</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_nov_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_nov_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_nov_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_nov_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formplain">December</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_dec_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_dec_planed"))); %>"></TD>
            <TD><INPUT TYPE="text" NAME="im_dec_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();" onchange="sum()" VALUE="<% out.write(dectostr(oSalesYear.getDecimal("im_dec_achieved"))); %>"></TD>
          </TR>
          <TR>
            <TD><FONT CLASS="formstrong">Total</FONT></TD>
            <TD><INPUT TYPE="text" NAME="im_tot_planed" SIZE="8" onkeypress="return acceptOnlyNumbers();"></TD>
            <TD><INPUT TYPE="text" NAME="im_tot_achieved" SIZE="8" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR>
        </TABLE>
      </TD></TR>
    </TABLE>
    <BR>
<% if (bIsGuest) { %>
    <INPUT TYPE="submit" CLASS="pushbutton" ACCESSKEY="s" TITLE="ALT+s" VALUE="Save">
<% } else { %>
    <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<% } %>
    &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.parent.close()">
  </FORM>
  </CENTER>
</BODY>
</HTML>
