<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %>
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
   
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 
  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);

  String sLinkTable = request.getParameter("linktable")==null ? "" : request.getParameter("linktable");
  String sLinkField = request.getParameter("linkfield")==null ? "" : request.getParameter("linkfield");
  String sLinkValue = request.getParameter("linkvalue")==null ? "" : request.getParameter("linkvalue");
  
  String sTpCardLookUp = null;
  
  String nu_bank_acc = nullif(request.getParameter("nu_bank_acc"));
  
  String nm_company = "";
  
  JDCConnection oConn = null;
  BankAccount oBank = null;  
  boolean bIsGuest = true;
   
  try {
    oConn = GlobalDBBind.getConnection("bank_edit");
    
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    if (nu_bank_acc.length()>0) {
      oBank = new BankAccount();
      oBank.load (oConn, new Object[]{nu_bank_acc,gu_workarea});
    }
    else
      oBank = new BankAccount();
    
    if (nullif(request.getParameter("nm_company")).length()>0)
      nm_company = request.getParameter("nm_company");
    else
      nm_company = oBank.getStringNull(DB.nm_company,"");

    sTpCardLookUp = DBLanguages.getHTMLSelectLookUp (oConn, "k_bank_accounts_lookup", gu_workarea, "tp_card", sLanguage);
        
    oConn.close("bank_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("bank_edit");
    oConn = null;
    
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML LANG="<%=sLanguage.toUpperCase()%>">
<HEAD>
  <TITLE>hipergate :: Edit Account</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT SRC="../javascript/layer.js"></SCRIPT>  
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
      <!--        

      function lookup(odctrl) {
        var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
        
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_bank_accounts_lookup&id_language=" + getUserLanguage() + "&id_section=tp_card&tp_control=2&nm_control=sel_card&nm_coding=tp_card", "lookupcardtype", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()

      // ------------------------------------------------------
            
      function validate() {
	var frm = window.document.forms[0];
	var txt;
	
	if (frm.validateAccount.checked) {
 	  if (frm.entity.value.length!=4) {
 	    alert("Bank Entity Code is not valid");
	    return false;
	  }

	  if (frm.office.value.length!=4) {
	    alert("Bank office code is not valid");
	    return false;
	  }

	  if (frm.cc.value.length==0) {
	    alert("Bank account number is not valid");
	    return false;
	  }
	  else {
	    while (frm.cc.value.length<10)
	      frm.cc.value = "0" + frm.cc.value;
	  }
	
	  if (frm.dc.value.length==0)
	    frm.dc.value = String(getBankAccountDigit("00" + frm.entity.value + frm.office.value)) + String(getBankAccountDigit(frm.cc.value));

          if (!isBankAccount (frm.entity.value, frm.office.value, frm.dc.value, frm.cc.value)) {
	    alert("Invalid Bank Account");
	    return false;
	  }
	frm.nu_bank_acc.value = frm.entity.value + frm.office.value + frm.dc.value + frm.cc.value;
	}
		
	if (frm.de_bank_acc.value.length>254) {
	  alert("Description length must not exceed 254 characters");
	  return false;
	}

	if ((frm.sel_month.options.selectedIndex>0 && frm.sel_year.options.selectedIndex<0) ||
	    (frm.sel_month.options.selectedIndex<0 && frm.sel_year.options.selectedIndex>0)) {

	  alert("Invalid Expiration Date");
	  return false;
	}
	else if (frm.sel_month.options.selectedIndex>0 && frm.sel_year.options.selectedIndex>0) {
	  frm.tx_expire.value = getCombo(frm.sel_month) + "/" + getCombo(frm.sel_year);
	}
	else {
	  frm.tx_expire.value = "";
	}
		    
	if(hasForbiddenChars(frm.nm_cardholder.value)) {
	  alert("Name on card contains invalid characters");
	  return false;
	}

        frm.nm_cardholder.value = frm.nm_cardholder.value.toUpperCase();

	frm.nm_bank.value = frm.nm_bank.value.toUpperCase();
	
	return true;
       } // validate()

      // ------------------------------------------------------
      
      function setCombos() {
        var frm = document.forms[0];
        var acc = frm.nu_bank_acc.value;
	var exd = frm.tx_expire.value;
	var axd;
	
  	if (acc.length==20 && isIntValue(acc)) {
  	  frm.entity.value = acc.substring(0,4);
  	  frm.office.value = acc.substring(4,8);
  	  frm.dc.value = acc.substring(8,10);
  	  frm.cc.value = acc.substring(10);
  	  frm.validateAccount.checked = true;
  	  showLayer('ac20');
  	  hideLayer('acfree');  	  
  	}
  	else {
  	  frm.validateAccount.checked = false;
  	  showLayer('acfree');
  	  hideLayer('ac20');
  	}
  	
        setCombo (frm.sel_card, frm.tp_card.value);
        
        if (exd.length>0) {
          axd = exd.split("/");

          setCombo (frm.sel_month, axd[0]);
          setCombo (frm.sel_year , axd[1]);
        }
        
      } // setCombos()          
      //-->
    </SCRIPT>  
</HEAD>
<BODY  TOPMARGIN="8" LEFTMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">

   <TABLE><TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Bank Account<%=(nm_company.length()>0 ? "&nbsp;-&nbsp;" + nm_company : "")%></FONT></TD></TR></TABLE>
  <BR>
  <FORM NAME="editaddr" METHOD="post" ACTION="bank_edit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="1">
    <INPUT TYPE="hidden" NAME="linktable" VALUE="<%=sLinkTable%>">
    <INPUT TYPE="hidden" NAME="linkfield" VALUE="<%=sLinkField%>">    
    <INPUT TYPE="hidden" NAME="linkvalue" VALUE="<%=sLinkValue%>">
    <INPUT TYPE="hidden" NAME="linkvalue" VALUE="<%=sLinkValue%>">
    <INPUT TYPE="hidden" NAME="noreload" VALUE="<%=nullif(request.getParameter("noreload"),"0")%>">
        
    <CENTER>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="140"><FONT CLASS="formstrong">Account Number</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <DIV NAME="ac20" ID="ac20">
              <INPUT NAME="entity" TYPE="text" MAXLENGTH="4" SIZE="4" onChange="acceptOnlyNumbers(this)">
              &nbsp;
              <INPUT NAME="office" TYPE="text" MAXLENGTH="4" SIZE="4" onChange="acceptOnlyNumbers(this)">              
              &nbsp;
              <INPUT NAME="dc" TYPE="text" MAXLENGTH="2" SIZE="2" onChange="acceptOnlyNumbers(this)">              
              &nbsp;
              <INPUT NAME="cc" TYPE="text" MAXLENGTH="10" SIZE="10" onChange="acceptOnlyNumbers(this)">              
    	      </DIV>
    	      <DIV NAME="acfree" ID="acfree"><INPUT TYPE="text" NAME="nu_bank_acc" MAXLENGTH="20" SIZE="20" VALUE="<%=nu_bank_acc%>"></DIV>

            </TD>
          </TR>
          <TR>
            <TD align="right" width="140">&nbsp;</TD>
            <TD align="left" width="460">
              <INPUT type="checkbox" name="validateAccount" checked onclick="if (this.checked) { showLayer('ac20'); hideLayer('acfree'); } else { showLayer('acfree'); hideLayer('ac20'); } "><FONT CLASS="formplain">Validate Account Number</FONT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Entity</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="nm_bank" MAXLENGTH="50" SIZE="41" STYLE="text-transform:uppercase" VALUE="<%=oBank.getStringNull(DB.nm_bank,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Address</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="tx_addr" MAXLENGTH="100" SIZE="41" VALUE="<%=oBank.getStringNull("tx_addr","")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Card Type</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="hidden" NAME="tp_card" VALUE="<%=oBank.getStringNull(DB.tp_card,"")%>">&nbsp;
              <SELECT CLASS="combomini" NAME="sel_card"><OPTION VALUE=""></OPTION><% out.write(sTpCardLookUp); %></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Card Types"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Card Number</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="nu_card" MAXLENGTH="16" SIZE="20" VALUE="<%=oBank.getStringNull(DB.nu_card,"")%>"  onChange="acceptOnlyNumbers(this)"></TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Expiration date</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="hidden" NAME="tx_expire" VALUE="<%=oBank.getStringNull(DB.tx_expire,"")%>">
              <SELECT NAME="sel_month"><OPTION VALUE=""><OPTION VALUE="01">01<OPTION VALUE="02">02<OPTION VALUE="03">03<OPTION VALUE="04">04<OPTION VALUE="05">05<OPTION VALUE="06">06<OPTION VALUE="07">07<OPTION VALUE="08">08<OPTION VALUE="09">09<OPTION VALUE="10">10<OPTION VALUE="11">11<OPTION VALUE="12">12</SELECT>
              <SELECT NAME="sel_year"><OPTION VALUE=""><OPTION VALUE="04">04<OPTION VALUE="05">05<OPTION VALUE="06">06<OPTION VALUE="07">07<OPTION VALUE="08">08<OPTION VALUE="09">09<OPTION VALUE="10">10<OPTION VALUE="11">11<OPTION VALUE="12">12<OPTION VALUE="13">13<OPTION VALUE="14">14<OPTION VALUE="15">15<OPTION VALUE="16">16<OPTION VALUE="17">17<OPTION VALUE="18">18<OPTION VALUE="19">19</SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Name on the Card</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="nm_cardholder" MAXLENGTH="100" SIZE="41" VALUE="<%=oBank.getStringNull(DB.nm_cardholder,"")%>" STYLE="text-transform:uppercase"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Credit Limit</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="im_credit_limit" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oBank.isNull(DB.im_credit_limit)) out.write(String.valueOf(oBank.getDecimal(DB.im_credit_limit).longValue())); %>"  onChange="acceptOnlyNumbers(this)"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Description</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><TEXTAREA NAME="de_bank_acc" ROWS="2" COLS="40"><%=oBank.getStringNull(DB.de_bank_acc,"")%></TEXTAREA></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your credential level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
<% } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<% } %>
              <INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.parent.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>
    </CENTER>                 
  </FORM>
</BODY>
</HTML>
