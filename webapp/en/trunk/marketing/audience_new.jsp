<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "audience_new";
  
  final String sLanguage = getNavigatorLanguage(request);
  final String sSkin = getCookie(request, "skin", "xp");

  final String id_user = getCookie(request, "userid", "");
  final String id_domain = request.getParameter("id_domain");
  final String gu_workarea = request.getParameter("gu_workarea");  
  final String gu_activity = request.getParameter("gu_activity");  
  
  String sOriginLookUp = "", sDataLookUp="";
    
  JDCConnection oConn = null;
  DBSubset oSalesMen = null;
  int iSalesMen = 0;

  try {

    oSalesMen = GlobalCacheClient.getDBSubset(DB.k_sales_men + ".DBSubset.[" + gu_workarea + "]");
    
    oConn = GlobalDBBind.getConnection(PAGE_NAME,true); 
     
    if (null==oSalesMen) {
      oSalesMen = new DBSubset (DB.k_sales_men+" s,"+DB.k_users+" u",
                                "s."+DB.gu_sales_man+",u."+DB.nm_user+",u."+DB.tx_surname1+",u."+DB.tx_surname2+","+
                                "s."+DB.gu_workarea+",s."+DB.gu_geozone+",s."+DB.id_country+",s."+DB.id_state+","+
                                "s."+DB.id_sales_group,
                                "s."+DB.gu_sales_man+"=u."+DB.gu_user+" AND u."+DB.bo_active+"<>0 AND s."+DB.gu_workarea+"=?",10);    
      iSalesMen = oSalesMen.load(oConn, new Object[]{gu_workarea});
      GlobalCacheClient.putDBSubset(DB.k_sales_men, DB.k_sales_men + ".DBSubset.[" + gu_workarea + "]", oSalesMen);
    } else {
      iSalesMen = oSalesMen.getRowCount();
    }// fi

    sOriginLookUp = GlobalDBLang.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_activity_audience_lookup, gu_workarea, DB.tp_origin, sLanguage);
    sDataLookUp = GlobalDBLang.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_activity_audience_lookup, gu_workarea, "id_data", sLanguage);

    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&"+e.getClass().getName()+"=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Add Attendant</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/autosuggest20.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      // ------------------------------------------------------
              
      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_activity_audience_lookup&id_language=" + getUserLanguage() + "&id_section=tp_origin&tp_control=2&nm_control=sel_origin&nm_coding=tp_origin", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_activity_audience_lookup&id_language=" + getUserLanguage() + "&id_section=id_data&tp_control=2&nm_control=sel_data1&nm_coding=id_data1", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      

      // ------------------------------------------------------

			function fillContactData(gu) {
      	parent.msgsexec.document.location = "audience_fill.jsp?gu_workarea=<%=gu_workarea%>&gu_contact=" + gu;
			}

      // ------------------------------------------------------

			function fillAddressData(gu) {
      	parent.msgsexec.document.location = "audience_fill.jsp?gu_workarea=<%=gu_workarea%>&gu_address=" + gu;
			}

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	      if (frm.tx_name.value.length<3) {
	        alert ("Attendant name is required");
	        frm.tx_name.focus();
	        return false;
	      }
	      
	      if (frm.tx_surname.value.length<3) {
	        alert ("Attendant surname is required");
	        frm.tx_surname.focus();
	        return false;
	      }
        
	      if (!check_email(frm.tx_email.value) && frm.tx_email.value.length>0) {
	        alert ("The e-mail is not valid");
	        frm.tx_email.focus();
	        return false;
	      }

				frm.tx_email.value = frm.tx_email.value.toLowerCase();

	      if (!isDate(frm.dt_paid.value, "d") && frm.dt_paid.value.length>0) {
	        alert ("The payment date is not valid");
	        frm.dt_payment.focus();
	        return false;
	      }

	      if (!isDate(frm.dt_confirmed.value, "d") && frm.dt_confirmed.value.length>0) {
	        alert ("The confirmation date is not valid");
	        frm.dt_payment.focus();
	        return false;
	      }

	      if (!isFloatValue(frm.im_paid.value) && frm.im_paid.value.length>0) {
	        alert ("The amount is not valid");
	        frm.im_paid.focus();
	        return false;
	      }
        
        if (frm.id_data1.value.length>0) frm.de_data1.value = getComboText(frm.id_data1);
        if (frm.id_data2.value.length>0) frm.de_data2.value = getComboText(frm.id_data2);
        if (frm.id_data3.value.length>0) frm.de_data3.value = getComboText(frm.id_data3);

				frm.nm_legal.value = frm.nm_legal.value.toUpperCase();

        return true;
      } // validate;

      // ------------------------------------------------------

    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <DIV class="cxMnu1" style="width:100px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">New Attendant</FONT></TD></TR>
  </TABLE>  
  <FORM TARGET="_top" METHOD="post" ACTION="audience_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_activity" VALUE="<%=gu_activity%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="">
    <INPUT TYPE="hidden" NAME="gu_address" VALUE="">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" ><FONT CLASS="formstrong">Name</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" NAME="tx_name" MAXLENGTH="50" SIZE="50" onchange="document.forms[0].gu_contact.value=''"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" ><FONT CLASS="formstrong">Surname</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" NAME="tx_surname" MAXLENGTH="50" SIZE="50" onchange="document.forms[0].gu_contact.value=''"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" ><FONT CLASS="formstrong">e-mail</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" STYLE="text-transform:lowercase" NAME="tx_email" MAXLENGTH="100" SIZE="50" onchange="document.forms[0].gu_address.value=''"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" ><FONT CLASS="formstrong">Telephone</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" NAME="work_phone" MAXLENGTH="16" SIZE="20"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" ><FONT CLASS="formstrong">Mobile</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" NAME="mov_phone" MAXLENGTH="16" SIZE="20"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" ><FONT CLASS="formstrong">Id. Doc.</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" NAME="sn_passport" MAXLENGTH="16" SIZE="20" onchange="document.forms[0].gu_contact.value=''"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" ><FONT CLASS="formstrong">Company</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" NAME="nm_legal" STYLE="text-transform:uppercase" MAXLENGTH="70" SIZE="50" VALUE="" onchange="document.forms[0].gu_company.value=''"></TD>
          </TR>
          <TR>
            <TD ALIGN="right"  CLASS="formplain">Salesman</TD>
            <TD ALIGN="left" ><SELECT NAME="gu_sales_man" CLASS="combomini"><OPTION VALUE=""></OPTION><% for (int s=0; s<iSalesMen; s++) out.write ("<OPTION VALUE=\""+oSalesMen.getString(0,s)+"\">"+oSalesMen.getStringNull(1,s,"")+" "+oSalesMen.getStringNull(2,s,"")+" "+oSalesMen.getStringNull(3,s,"")+"</OPTION>"); %></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" ><FONT CLASS="formplain">Origin</FONT></TD>
            <TD ALIGN="left" >
              <INPUT TYPE="hidden" NAME="tp_origin">
              <SELECT NAME="sel_origin"><OPTION VALUE=""></OPTION><%=sOriginLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Create Origin"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" ><INPUT TYPE="checkbox" NAME="bo_allows_ads" VALUE="1" CHECKED></TD>
            <TD ALIGN="left"  CLASS="formplain">Allows commercial messages</TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain" VALIGN="top">Payment</TD>
            <TD ALIGN="left" CLASS="formplain">
            	<TABLE CLASS="formback"><TR><TD CLASS="formplain">
            	<INPUT TYPE="radio" NAME="bo_paid" VALUE="1" onclick="showLayer('payment_info'); if (getCheckedValue(document.forms[0].bo_confirmed)!='1') setCheckedValue(document.forms[0].bo_confirmed,'1')">&nbsp;Paid&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="bo_paid" VALUE="0" onclick="hideLayer('payment_info'); document.forms[0].im_paid.value=document.forms[0].dt_paid.value=''" CHECKED>&nbsp;Not paid
            	<BR>
            	<DIV ID="payment_info" STYLE="visibility:hidden">Paid amount&nbsp;<INPUT TYPE="text" NAME="im_paid" MAXLENGTH="10" SIZE="10">&nbsp;&nbsp;&nbsp;
            	Payment date&nbsp;<INPUT TYPE="text" NAME="dt_paid" MAXLENGTH="10" SIZE="10">
              <A HREF="javascript:showCalendar('dt_paid ')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A></DIV></TD>
              </TD></TR></TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain" VALIGN="top">Attendance conformation</TD>
            <TD ALIGN="left" CLASS="formplain">
            	<TABLE CLASS="formback"><TR><TD CLASS="formplain">
            	  <INPUT TYPE="radio" NAME="bo_confirmed" VALUE="1" onclick="if (document.forms[0].dt_confirmed.value.length==0) document.forms[0].dt_confirmed.value=dateToString(new Date(), 'd')">&nbsp;Confirmed&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="bo_confirmed" VALUE="0" CHECKED>&nbsp;Not confirmed
            	  <BR>
            	  Confirmation date&nbsp;<INPUT TYPE="text" NAME="dt_confirmed" MAXLENGTH="10" SIZE="10">
                <A HREF="javascript:showCalendar('dt_confirmed')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
              </TD></TR></TABLE>
          </TR>
          <TR>
            <TD ALIGN="right" ><FONT CLASS="formplain">Actually attended</FONT></TD>
            <TD ALIGN="left"  CLASS="formplain"><INPUT TYPE="radio" NAME="bo_went" VALUE="1">&nbsp;Attended&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="bo_went" VALUE="0">&nbsp;Did not attended</TD>
          </TR>
          <TR>
            <TD ALIGN="right" FONT CLASS="formplain" VALIGN="top">Additional information&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT=""></A></TD>
            <TD ALIGN="left" CLASS="formplain">
            	<INPUT TYPE="hidden" NAME="id_data1"><INPUT TYPE="hidden" NAME="de_data1">
            	<SELECT NAME="sel_data1"><OPTION VALUE=""></OPTION><%=sDataLookUp%></SELECT>&nbsp;<INPUT TYPE="text" NAME="tx_data1" MAXLENGTH="100" SIZE="20">
              <BR>
            	<INPUT TYPE="hidden" NAME="id_data2"><INPUT TYPE="hidden" NAME="de_data2">
            	<SELECT NAME="sel_data2"><OPTION VALUE=""></OPTION><%=sDataLookUp%></SELECT>&nbsp;<INPUT TYPE="text" NAME="tx_data2" MAXLENGTH="100" SIZE="20">
              <BR>
            	<INPUT TYPE="hidden" NAME="id_data3"><INPUT TYPE="hidden" NAME="de_data3">
            	<SELECT NAME="sel_data3"><OPTION VALUE=""></OPTION><%=sDataLookUp%></SELECT>&nbsp;<INPUT TYPE="text" NAME="tx_data3" MAXLENGTH="100" SIZE="20">
            </TD>
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
<SCRIPT TYPE="text/javascript">
    <!--  
      
      var AutoSuggestNameOptions = { script:"'../common/autocomplete.jsp?nm_table=k_contacts&nm_valuecolumn=gu_contact&nm_textcolumn=tx_name&nm_infocolumn=<%=Gadgets.replace(DBBind.Functions.strCat(new String[]{DB.tx_name,DB.tx_surname,DB.sn_passport},' '),"'","%27")%>&gu_workarea=<%=gu_workarea%>&tx_where=tx_name&'", varname:"tx_like",minchars:3,form:0, callback: function (obj) { fillContactData(obj.id); } };

      var AutoSuggestSurnameOptions = { script:"'../common/autocomplete.jsp?nm_table=k_contacts&nm_valuecolumn=gu_contact&nm_textcolumn=tx_surname&nm_infocolumn=<%=Gadgets.replace(DBBind.Functions.strCat(new String[]{DB.tx_surname,DB.tx_name,DB.sn_passport},','),"'","%27")%>&gu_workarea=<%=gu_workarea%>&tx_where=tx_name&'", varname:"tx_like",minchars:3,form:0, callback: function (obj) { fillContactData(obj.id); } };

      var AutoSuggestDocIdOptions = { script:"'../common/autocomplete.jsp?nm_table=k_contact_doc_id&gu_workarea=<%=gu_workarea%>&'", varname:"tx_like",minchars:3,form:0, callback: function (obj) { fillContactData(obj.id); } };

      var AutoSuggestEmailOptions = { script:"'../common/autocomplete.jsp?nm_table=k_member_address&gu_workarea=<%=gu_workarea%>&nm_valuecolumn=gu_address&nm_textcolumn=tx_email&nm_infocolumn=<%=Gadgets.replace(DBBind.Functions.strCat(new String[]{DB.tx_name,DB.tx_surname,DB.nm_legal,DB.sn_passport},' '),"'","%27")%>&tx_where=gu_contact%20IS%20NOT%20NULL%20AND%20tx_email&'", varname:"tx_like",minchars:2,form:0, callback: function (obj) { fillAddressData(obj.id); } };

      var AutoSuggestCompanyOptions = { script:"'../common/autocomplete.jsp?nm_table=k_companies&nm_valuecolumn=gu_company&nm_textcolumn=nm_legal&gu_workarea=<%=gu_workarea%>&tx_where=nm_legal&'", varname:"tx_like",minchars:3,form:0, callback: function (obj) { } };

      var AutoSuggestPhoneOptions = { script:"'../common/autocomplete.jsp?nm_table=k_contact_telephone&gu_workarea=<%=gu_workarea%>&tx_where='+document.forms[0].gu_contact.value+'&'", varname:"tx_like",minchars:2,form:0, callback: function (obj) { } };

      var AutoSuggestMobileOptions = { script:"'../common/autocomplete.jsp?nm_table=k_contact_telephone&gu_workarea=<%=gu_workarea%>&tx_where='+document.forms[0].gu_contact.value+'&'", varname:"tx_like",minchars:2,form:0, callback: function (obj) { } };

      var AutoSuggestName = new AutoSuggest("tx_name", AutoSuggestNameOptions);

      var AutoSuggestSurname = new AutoSuggest("tx_surname", AutoSuggestSurnameOptions);

      var AutoSuggestDocId = new AutoSuggest("id_legal", AutoSuggestDocIdOptions);

      var AutoSuggestEmail = new AutoSuggest("tx_email", AutoSuggestEmailOptions);

      var AutoSuggestCompany = new AutoSuggest("nm_legal", AutoSuggestCompanyOptions);

      var AutoSuggestPhone = new AutoSuggest("work_phone", AutoSuggestPhoneOptions);

      var AutoSuggestMobile = new AutoSuggest("mov_phone", AutoSuggestMobileOptions);

    //-->
</SCRIPT>
</HTML>
