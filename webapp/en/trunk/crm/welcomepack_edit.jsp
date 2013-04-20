<%@ page import="java.text.SimpleDateFormat,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.hipergate.DBLanguages,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.crm.WelcomePack,com.knowgate.crm.WelcomePackChangeLog,com.knowgate.crm.Company,com.knowgate.crm.Contact" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
/*
  Form for editing a WelcomePack object.
  
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

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String gu_pack = request.getParameter("gu_pack");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_company = request.getParameter("gu_company");
  String gu_contact = request.getParameter("gu_contact");
  
  String sTomorrow = new SimpleDateFormat("yyyy-MM-dd").format(new Date(new Date().getTime()+86400000l));

  WelcomePack oWPak = null;
  WelcomePackChangeLog[] oWLog = null;
  Company oCom = new Company();
  Contact oCon = new Contact();
  DBSubset oAdr = null;
  String sStatusLookUp = "", sCourierLookUp = "", sTr;
  boolean bNew = false;
  JDCConnection oConn = null;

  try {

    oConn = GlobalDBBind.getConnection("welcomepack_edit");  

    sStatusLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_welcome_packs_lookup, gu_workarea, DB.id_status, sLanguage);
    sCourierLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_welcome_packs_lookup, gu_workarea, DB.id_courier, sLanguage);

    if (gu_pack!=null) {
      oWPak = new WelcomePack();
      if (!oWPak.load(oConn, new Object[]{gu_pack})) oWPak = null;
    }
    
    if (gu_company!=null) {
      if (oCom.load(oConn, new Object[]{gu_company})) {
        if (gu_contact==null) {
          if (oWPak==null) oWPak = WelcomePack.forCompany(oConn, gu_company);
          oAdr = oCom.getAddresses(oConn);
        }
      }
    }
    
    if (gu_contact!=null) {
      if (oCon.load(oConn, new Object[]{gu_contact})) {
        if (oWPak==null) oWPak = WelcomePack.forContact(oConn, gu_contact);
        oAdr = oCon.getAddresses(oConn);
        if (!oCon.isNull(DB.gu_company)) {
          oCom.load(oConn, new Object[]{oCon.getString(DB.gu_company)});
        }
      }
    }

    if (null==oWPak) {
      bNew = true;
      oWPak = new WelcomePack();
    } else {
      oWLog = oWPak.changeLog(oConn);    
      if (null!=oWLog) {
        for (int l=0; l<oWLog.length; l++) {
          if (oWLog[l].getStringNull(DB.id_old_status,"").length()!=0) {
            sTr = DBLanguages.getLookUpTranslation(oConn, DB.k_welcome_packs_lookup, gu_workarea, DB.id_status, sLanguage, oWLog[l].getStringNull(DB.id_old_status,""));
            if (sTr!=null) oWLog[l].replace(DB.id_old_status, sTr);
          }
          if (oWLog[l].getStringNull(DB.id_new_status,"").length()!=0) {
            sTr = DBLanguages.getLookUpTranslation(oConn, DB.k_welcome_packs_lookup, gu_workarea, DB.id_status, sLanguage, oWLog[l].getStringNull(DB.id_new_status,""));
            if (sTr!=null) oWLog[l].replace(DB.id_new_status, sTr);
          }
        } // next
      } // fi (oWLog)
    } // fi (oWPak)

    oConn.close("welcomepack_edit");
  }
  catch (NullPointerException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("welcomepack_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Welcome Pack</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      function createAddress() {
        window.open("../common/addr_edit_f.jsp?nm_company=" + escape("<%=oCom.getStringNull(DB.nm_commercial,"")%>") + "&linktable=" + getURLParam("linktable") + "&linkfield=" + getURLParam("linkfield") + "&linkvalue=" + getURLParam("linkvalue"), "editcompaddr", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
      } // createAddress()

      // ------------------------------------------------------
	
      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
	var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_welcome_packs_lookup&id_language=" + getUserLanguage() + "&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_welcome_packs_lookup&id_language=" + getUserLanguage() + "&id_section=id_courier&tp_control=2&nm_control=sel_courier&nm_coding=id_courier", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	if (frm.gu_address.selectedIndex<=0) {
	  alert ("A delivery address must be specified");
	  return false;	  
	}

	if (!isDate(frm.dt_sent.value, "d") && frm.dt_sent.value.length>0) {
	  alert ("Send Date is not valid");
	  return false;	  
	}
	if (!isDate(frm.dt_cancel.value, "d") && frm.dt_cancel.value.length>0) {
	  alert ("Cancel date is not valid");
	  return false;
	}
	if (frm.dt_promised.value.length>0) {
	  if (!isDate(frm.dt_promised.value, "d")) {
	    alert ("Forseen delivery date is not valid");
	    return false;	  
	  }
	  if (parseDate(frm.dt_promised.value, "d")<parseDate(frm.dt_sent.value, "d")) {
	    alert ("Forseen delivery date may not be prior to send date");
	    return false;
	  }
	}
	if (frm.dt_delivered.value.length>0) {
	  if (!isDate(frm.dt_delivered.value, "d")) {
	    alert ("Actual delivery date is not valid");
	    return false;	  
	  }
	  if (parseDate(frm.dt_delivered.value, "d")<parseDate(frm.dt_sent.value, "d")) {
	    alert ("Delivery date may not be prior to send date");
	    return false;
	  }
	  if (frm.dt_sent.value.length==0) {
	    alert ("A delivery date may not be specified if a send date does not exist");
	    return false;
	  }
        }
	if (frm.dt_returned.value.length>0) {
	  if (!isDate(frm.dt_returned.value, "d")) {
	    alert ("Actual return date is not valid");
	    return false;	  
	  }
	  if (parseDate(frm.dt_returned.value, "d")<parseDate(frm.dt_sent.value, "d")) {
	    alert ("Return date may not be prior to sent date");
	    return false;
	  }
	  if (frm.dt_sent.value.length==0) {
	    alert ("A Return Date cannot be specified without a Send Date");
	    return false;
	  }
	}
		
	if (frm.tx_remarks.value.length>254) {
	  alert ("Comments may not exceed 255 characters");
	  return false;
	}

	frm.id_status.value = getCombo(frm.sel_status);
	frm.id_courier.value = getCombo(frm.sel_courier);
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.gu_address,"<% out.write(oWPak.getStringNull(DB.gu_address,"")); %>");
        setCombo(frm.sel_status,"<% out.write(oWPak.getStringNull(DB.id_status,"")); %>");
        setCombo(frm.sel_courier,"<% out.write(oWPak.getStringNull(DB.id_courier,"")); %>");

        return true;
      } // validate;
    //-->
  </SCRIPT> 
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Welcome Pack</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="welcomepack_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_pack" VALUE="<%=oWPak.getStringNull(DB.gu_pack,"")%>">
    <INPUT TYPE="hidden" NAME="ix_pack" VALUE="<% if (!oWPak.isNull(DB.ix_pack)) out.write(String.valueOf(oWPak.getInt(DB.ix_pack))); %>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=getCookie (request, "userid", "")%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=nullif(gu_contact)%>">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=nullif(gu_company)%>">
    <INPUT TYPE="hidden" NAME="linktable" VALUE="<%=request.getParameter("linktable")%>">
    <INPUT TYPE="hidden" NAME="linkfield" VALUE="<%=request.getParameter("linkfield")%>">
    <INPUT TYPE="hidden" NAME="linkvalue" VALUE="<%=request.getParameter("linkvalue")%>">

    <TABLE ALIGN="center" CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Address:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT NAME="gu_address"><OPTION VALUE=""></OPTION>
<% if (oAdr!=null) {
     for (int a=0; a<oAdr.getRowCount(); a++) {
       out.write("<OPTION VALUE=\""+oAdr.getString(DB.gu_address,a)+"\">");
       if (sLanguage.startsWith("es"))
         out.write( (oAdr.getStringNull(DB.tp_street,a,"")+" "+oAdr.getStringNull(DB.nm_street,a,"")+" "+oAdr.getStringNull(DB.nu_street,a,"")).trim());
       else
         out.write((oAdr.getStringNull(DB.nu_street,a,"")+" "+oAdr.getStringNull(DB.nm_street,a,"")+" "+oAdr.getStringNull(DB.tp_street,a,"")).trim());
       if (!oAdr.isNull(DB.tp_location,a))
         out.write("("+oAdr.getString(DB.tp_location,a)+")");
     } // next
  } // fi
%>
              </SELECT>
              <A HREF="#" onclick="createAddress()" TITLE="New Address"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Address List"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Status:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <INPUT TYPE="hidden" NAME="id_status">
              <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Status List"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Courier:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <INPUT TYPE="hidden" NAME="id_courier" VALUE="<%=oWPak.getStringNull(DB.id_courier,"")%>">
              <SELECT NAME="sel_courier"><OPTION VALUE=""></OPTION><%=sCourierLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Courier List"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Reference:</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="20" VALUE="<%=oWPak.getStringNull(DB.id_ref,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">Send Date:</TD>
            <TD><INPUT TYPE="text" MAXLENGTH="10" SIZE="12" NAME="dt_sent" VALUE="<% if (!oWPak.isNull(DB.dt_sent)) out.write(oWPak.getDateShort(DB.dt_sent)); else if (bNew) out.write(sTomorrow); %>">&nbsp;<A HREF="javascript:showCalendar('dt_sent')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">Forseen Delivery Date:</TD>
            <TD><INPUT TYPE="text" MAXLENGTH="10" SIZE="12" NAME="dt_promised" VALUE="<% if (!oWPak.isNull(DB.dt_promised)) out.write(oWPak.getDateShort(DB.dt_promised)); %>">&nbsp;<A HREF="javascript:showCalendar('dt_promised')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">Actual Delivery Date:</TD>
            <TD><INPUT TYPE="text" MAXLENGTH="10" SIZE="12" NAME="dt_delivered" VALUE="<% if (!oWPak.isNull(DB.dt_delivered)) out.write(oWPak.getDateShort(DB.dt_delivered)); %>">&nbsp;<A HREF="javascript:showCalendar('dt_delivered')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">Cancellation Date:</TD>
            <TD><INPUT TYPE="text" MAXLENGTH="10" SIZE="12" NAME="dt_cancel" VALUE="<% if (!oWPak.isNull(DB.dt_cancel)) out.write(oWPak.getDateShort(DB.dt_cancel)); %>">&nbsp;<A HREF="javascript:showCalendar('dt_cancel')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">Return Date:</TD>
            <TD><INPUT TYPE="text" MAXLENGTH="10" SIZE="12" NAME="dt_returned" VALUE="<% if (!oWPak.isNull(DB.dt_returned)) out.write(oWPak.getDateShort(DB.dt_returned)); %>">&nbsp;<A HREF="javascript:showCalendar('dt_returned')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><TEXTAREA NAME="tx_remarks" ROWS="4" STYLE="width:360px"><%=oWPak.getStringNull(DB.tx_remarks,"")%></TEXTAREA></TD>
          </TR>
<% if (oWLog!=null) { %>
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="90"><FONT CLASS="formplain">History:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <TABLE SUMMARY="History" BORDER="0">              
<%   for (int l=0; l<oWLog.length; l++) {       
       if (oWLog[l].getStringNull(DB.id_old_status,"").length()==0) {
         out.write("<TR CLASS=\"formplain\"><TD NOWRAP>"+oWLog[l].getDateTime(DB.dt_last_update)+"</TD><TD COLSPAN=2>"+oWLog[l].getStringNull(DB.id_new_status,"")+"</TD></TR>\n");
       } else {
         out.write("<TR CLASS=\"formplain\"><TD NOWRAP>"+oWLog[l].getDateTime(DB.dt_last_update)+"</TD><TD NOWRAP>update&nbsp;"+oWLog[l].getStringNull(DB.id_old_status,"")+"</TD><TD NOWRAP>to&nbsp;"+oWLog[l].getStringNull(DB.id_new_status,"")+"<TD></TR>\n");
       }
     } // next
   } // fi %>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
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
