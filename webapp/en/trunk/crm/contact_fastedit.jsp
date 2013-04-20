<%@ page import="java.io.IOException,java.io.UnsupportedEncodingException,java.io.File,java.net.URLDecoder,java.sql.SQLException,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.CSVParser,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%!
/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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

  public static String getField (CSVParser oCsv, int iCol, int iRow)
    throws IllegalStateException, ArrayIndexOutOfBoundsException,
           StringIndexOutOfBoundsException, UnsupportedEncodingException {
    String sRetVal;
    if (null==oCsv) {
      sRetVal = "";
    } else {
      String sFld = oCsv.getField(iCol, iRow);
      if (sFld.indexOf(34)>=0) {
        StringBuffer oFld = new StringBuffer(sFld.length());
        int q = 1;
        for (int c=0; c<sFld.length(); c++) {
          if (sFld.charAt(c)=='"') {
            oFld.append(1==q ? "«" : "»");
            q *= -1;
          } // fi
        } // next
        sRetVal = oFld.toString().trim().toUpperCase();
      } else {
        sRetVal = sFld.trim().toUpperCase();
      } // fi ()
    } // fi (sFld.indexOf('"')>=0)
    if (15==iCol) sRetVal = sRetVal.toLowerCase(); 
    return sRetVal;
  } // getField
%><% 
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = Gadgets.chomp(sTmpDir,File.separator);
  MultipartRequest oReq = null;
  
  try {
    oReq = new MultipartRequest(request, sTmpDir, "UTF-8");
  } catch (IOException ignore) { }

  String D, sRow;
  int iRows = Integer.parseInt(nullif(request.getParameter("rows"),"10"));
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);  

  boolean bLatinLanguage = (sLanguage.startsWith("es") || sLanguage.startsWith("en") || sLanguage.startsWith("fr") || sLanguage.startsWith("de") || sLanguage.startsWith("pt") || sLanguage.startsWith("nl") || sLanguage.startsWith("pl"));
  boolean bChineseTraditional = sLanguage.startsWith("tw");
  boolean bChineseSimplified = sLanguage.startsWith("cn");
  boolean bRussianLanguage = sLanguage.startsWith("ru");

  String gu_workarea = getCookie(request,"workarea","");

  File oCsvFile = null;
  
  if (null!=oReq) {
    oCsvFile = oReq.getFile(0);
    D = oReq.getParameter("sel_delim").replace('T','\t');
  } else {
    D = "|";
  }

  String sDescriptor = "id_contact_ref"+D+"tx_name"+D+"tx_surname"+D+"nm_legal"+D+"tx_email"+D+"direct_phone"+D+"id_sector"+D+"de_title"+D+"sn_passport"+D+"tp_passport"+D+"dt_birth"+D+"ny_age"+D+"tp_street"+D+"nm_street"+D+"nu_street"+D+"tx_addr1"+D+"tx_addr2"+D+"id_country"+D+"id_state"+D+"mn_city"+D+"zipcode";
  CSVParser oCsv = null;
  JDCConnection oConn = null;  
  String sSectorsLookUp="", sTitlesLookUp="", sPassportsLookUp="", sStreetsLookUp="", sCountriesLookUp="";

  if (oCsvFile!=null) {
    oCsv = new CSVParser(oReq.getParameter("sel_encoding"));
    try {
      oCsv.parseFile(oCsvFile, sDescriptor);
      iRows = oCsv.getLineCount();
    } catch (ArrayIndexOutOfBoundsException aiob) {
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=" + aiob.getMessage() + "&resume=_back"));
      oCsv = null;
    } finally {
      if (null!=oCsvFile) oCsvFile.delete();
    }
    if (null==oCsv) return;
  } // fi

  if (!isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response)) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=Administror role is required for accessing this page&resume=_back"));  
    return;
  }

  try {
    oConn = GlobalDBBind.getConnection("contact_fastedit");
         
    sSectorsLookUp = GlobalDBLang.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_companies_lookup, gu_workarea, DB.id_sector, sLanguage);
    sTitlesLookUp = GlobalDBLang.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_contacts_lookup, gu_workarea, DB.de_title, sLanguage);
    sPassportsLookUp = GlobalDBLang.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_contacts_lookup, gu_workarea, DB.tp_passport, sLanguage);
    sStreetsLookUp = GlobalDBLang.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_street, sLanguage);
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);

    oConn.close("contact_fastedit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("contact_fastedit");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oConn) return;    
  oConn = null;
  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      var nrows = <%=String.valueOf(iRows)%>;

      // ------------------------------------------------------

      function reference(nm_legal, odctrl) {
        var frm = document.forms[0];
        var c1,c2,c12;
        
        switch(parseInt(odctrl)) {
          case 1:
            if (frm.elements[nm_legal].value.indexOf("'")>=0)
              alert("The company name contains forbidden characters");
            else
              window.open("../common/reference.jsp?nm_table=k_companies&tp_control=1&nm_control=nm_legal AS "+nm_legal+"&nm_coding="+(frm.elements[nm_legal].value.length==0 ? "" : "&where=" + escape(" <%=DB.nm_legal%> LIKE '"+frm.elements[nm_legal].value+"%' ")), "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // reference()

      // ------------------------------------------------------

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      // ------------------------------------------------------

      function loadstates(sel_country, sel_state, setval) {
	var frm = window.document.forms[0];

        clearCombo(frm.elements[sel_state]);
        
        if (frm.elements[sel_country].options.selectedIndex>0) {
          if (setval==null)
            parent.frames[1].location.href = "../common/addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.elements[sel_country]) + "&control="+sel_state;
          else
            parent.frames[1].location.href = "../common/addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.elements[sel_country]) + "&control="+sel_state+"&set_value=" + setval;
        
        } // fi
      } // loadstates

      // ------------------------------------------------------

      function validate() {
        var frm = document.forms[0];
	var txt;
	
	for (var r=0; r<nrows; r++) {
	  txt = frm.elements["ny_age"+String(r)].value;
	  if (txt.length>0 && !isIntValue(txt)) {
	    alert ("Row "+String(r+1)+" Age must be a positive integer number");
	    return false;
	  }
	  txt = frm.elements["dt_birth"+String(r)].value;
	  if (txt.length>0 && !isDate(txt,"d")) {
	    alert ("Row "+String(r+1)+" Birth Date is not valid, it must be AAAA-MM-DD");
	    return false;
	  }
	  /*
	  txt = frm.elements["tx_email"+String(r)].value;
	  if (txt.length>0 && !check_email(txt)) {
	    alert ("Row "+String(r+1)+" e-mail address is not valid");
	    return false;
	  }
	  */
	  if ((frm.elements["tx_name"+String(r)].value.length==0  && frm.elements["tx_surname"+String(r)].value.length==0) &&
	      (frm.elements["nm_legal"+String(r)].value.length >0 || frm.elements["id_sector"+String(r)].value.length>0 ||
	       frm.elements["de_title"+String(r)].value.length >0 || frm.elements["direct_phone"+String(r)].value.length >0 ||
	       frm.elements["dt_birth"+String(r)].value.length >0 || frm.elements["tx_email"+String(r)].value.length >0 ||
	       frm.elements["nm_street"+String(r)].value.length>0 || frm.elements["tp_street"+String(r)].selectedIndex>0 ||	       	       
	       frm.elements["sn_passport"+String(r)].value.length>0 || frm.elements["tp_passport"+String(r)].selectedIndex>0)) {
	    alert ("Row "+String(r+1)+" Name or Surname is required");
	    return false;	       
	   }  
	} // next
	
	frm.id_mode.value = (frm.rad_ins_updt[0].checked ? "append" : "appendupdate");
	
	return true;
      } // validate

      // ------------------------------------------------------
      
      function setCombos() {
        var frm = document.forms[0];
	var opt = frm.id_country0.options;
	var len = opt.length; 
	var cnt;
	for (var r=0; r<nrows; r++) {
	  cnt = frm.elements["id_country"+String(r)].options;
	  for (var o=0; o<len; o++) {
	    cnt[o] = new Option(opt[o].text, opt[o].value, false, false);
	  }
	} // next (r)
<%
	if (oCsv==null) {
	  if (sLanguage.equals("es"))
	    for (int r=0; r<iRows; r++) out.write("        setCombo(frm.id_country"+String.valueOf(r)+",\"es\");\n");
	  else if (sLanguage.equals("en"))
	    for (int r=0; r<iRows; r++) out.write("        setCombo(frm.id_country"+String.valueOf(r)+",\"us\");\n");
	  else if (sLanguage.equals("en")  || sLanguage.equalsIgnoreCase("en_GB"))
	    for (int r=0; r<iRows; r++) out.write("        setCombo(frm.id_country"+String.valueOf(r)+",\"gb\");\n");
	  else if (sLanguage.equals("fr"))
	    for (int r=0; r<iRows; r++) out.write("        setCombo(frm.id_country"+String.valueOf(r)+",\"fr\");\n");
	  else if (sLanguage.equals("de"))
	    for (int r=0; r<iRows; r++) out.write("        setCombo(frm.id_country"+String.valueOf(r)+",\"de\");\n");
	  else if (sLanguage.equals("it"))
	    for (int r=0; r<iRows; r++) out.write("        setCombo(frm.id_country"+String.valueOf(r)+",\"it\");\n");
	  else if (sLanguage.equals("cn") || sLanguage.equalsIgnoreCase("zh_CN"))
	    for (int r=0; r<iRows; r++) out.write("        setCombo(frm.id_country"+String.valueOf(r)+",\"cn\");\n");
	  else if (sLanguage.equals("tw") || sLanguage.equalsIgnoreCase("zh_TW"))
	    for (int r=0; r<iRows; r++) out.write("        setCombo(frm.id_country"+String.valueOf(r)+",\"tw\");\n");
	} else {
	  for (int r=0; r<iRows; r++) {
	    sRow = String.valueOf(r);
	    out.write("        setCombo(frm.id_sector"+sRow+",\""+oCsv.getField(6,r)+"\");\n");
	    out.write("        setCombo(frm.de_title"+sRow+",\""+oCsv.getField(7,r)+"\");\n");
	    out.write("        setCombo(frm.tp_passport"+sRow+",\""+oCsv.getField(9,r)+"\");\n");
	    out.write("        setCombo(frm.tp_street"+sRow+",\""+oCsv.getField(12,r)+"\");\n");
	    out.write("        setCombo(frm.id_country"+sRow+",\""+oCsv.getField(17,r)+"\");\n");
	    out.write("        setCombo(frm.id_state"+sRow+",\""+oCsv.getField(18,r)+"\");\n");
	  } // next
	} // fi
%>
      } // setCombos()
    // -->
  </SCRIPT>
  <TITLE>hipergate :: Contacts Fast Edit</TITLE>
</HEAD>
<BODY MARGINWIDTH="8" LEFTMARGIN="8" TOPMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">
  <%@ include file="../common/header.jspf" %>
  <TABLE>
    <TR>
      <TD>
        <DIV class="cxMnu1" style="width:220px"><DIV class="cxMnu2">
          <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.parent.location='crmhome.jsp?selected=2&subselected=-1'"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
          <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
        </DIV></DIV>
      </TD>
      <TD CLASS="striptitle"><FONT CLASS="title1">Contacts Fast Edit</FONT></TD>
    </TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="contact_fastedit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="tx_descriptor" VALUE="<%=sDescriptor%>">
    <INPUT TYPE="hidden" NAME="nu_rows" VALUE="<%=String.valueOf(iRows)%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="id_mode" VALUE="">
    <INPUT TYPE="radio" NAME="rad_ins_updt" CHECKED>&nbsp;<FONT CLASS="textplain">Insert</FONT>&nbsp;&nbsp;<INPUT TYPE="radio" NAME="rad_ins_updt">&nbsp;<FONT CLASS="textplain">Insert and Update</FONT>&nbsp;&nbsp;&nbsp;<A TARGET="_top" HREF="../admin/lookups.jsp?nm_table=k_contacts_lookup&nm_referer=contact_fastedit_f.jsp" CLASS="linkplain">Manual Maintenance of Lookup Values</A>
    <BR>
    <INPUT TYPE="checkbox" NAME="chk_dup_names" VALUE="1" CHECKED>&nbsp;<FONT CLASS="textplain">Avoid duplicated names</FONT>&nbsp;&nbsp;<INPUT TYPE="checkbox" NAME="chk_dup_emails" VALUE="1" CHECKED>&nbsp;<FONT CLASS="textplain">Avoid duplicated e-mails</FONT>
    <BR>
    <INPUT TYPE="submit" VALUE="Save" CLASS="pushbutton">
    <TABLE CELLSPACING="1" CELLPADDING="0">
      <TR>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Reference</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Name</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Surname</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Company</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>e-mail</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Telephone</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Sector</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Position</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Identity Document</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Id. Doc. Type</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Birth Data</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Age</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Street Type</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Street Name</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Number</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Suite/Floor</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Other Address</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Country</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>State</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>City</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP>&nbsp;<B>Zipcode</B></TD>
      </TR>
<% 
   for (int r=0; r<iRows; r++) {
     sRow = String.valueOf(r);
%>
      <TR>
        <TD CLASS="textsmall" ALIGN="right"><A HREF="row<%=sRow%>"></A><%=String.valueOf(r+1)%>&nbsp;</TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="id_contact_ref<%=sRow%>" SIZE="10" MAXLENGTH="50" VALUE="<%=getField(oCsv,0,r)%>"></TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="tx_name<%=sRow%>" SIZE="12" MAXLENGTH="100" VALUE="<%=getField(oCsv,1,r)%>"></TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="tx_surname<%=sRow%>" SIZE="20" MAXLENGTH="100" VALUE="<%=getField(oCsv,2,r)%>"></TD>
        <TD NOWRAP>
          <INPUT TYPE="text" CLASS="combomini" NAME="nm_legal<%=sRow%>" SIZE="20" MAXLENGTH="100" VALUE="<%=getField(oCsv,3,r)%>">
          <A HREF="javascript:reference('nm_legal<%=sRow%>',1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View listing"></A>
          &nbsp;&nbsp;
        </TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="tx_email<%=sRow%>" SIZE="20" MAXLENGTH="100" VALUE="<%=getField(oCsv,4,r)%>"></TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="direct_phone<%=sRow%>" SIZE="10" MAXLENGTH="16" VALUE="<%=getField(oCsv,5,r)%>"></TD>
        <TD><SELECT CLASS="combomini" NAME="id_sector<%=sRow%>"><OPTION VALUE=""></OPTION><%=sSectorsLookUp%></SELECT></TD>
        <TD><SELECT CLASS="combomini" NAME="de_title<%=sRow%>"><OPTION VALUE=""></OPTION><%=sTitlesLookUp%></SELECT></TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="sn_passport<%=sRow%>" SIZE="10" MAXLENGTH="16" VALUE="<%=getField(oCsv,8,r)%>"></TD>
        <TD><SELECT CLASS="combomini" NAME="tp_passport<%=sRow%>"><OPTION VALUE=""></OPTION><%=sPassportsLookUp%></SELECT></TD>
        <TD NOWRAP>
          <INPUT TYPE="text" CLASS="combomini" NAME="dt_birth<%=sRow%>" SIZE="12" MAXLENGTH="10" VALUE="<%=getField(oCsv,10,r)%>">
          <A HREF="javascript:showCalendar('dt_birth<%=sRow%>')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
          &nbsp;&nbsp;
        </TD>
        <TD ALIGN="center"><INPUT TYPE="text" CLASS="combomini" NAME="ny_age<%=sRow%>" SIZE="3" MAXLENGTH="3" onkeypress="acceptOnlyNumbers(this)" VALUE="<%=getField(oCsv,11,r)%>"></TD>
        <TD><SELECT CLASS="combomini" NAME="tp_street<%=sRow%>"><OPTION VALUE=""></OPTION><%=sStreetsLookUp%></SELECT></TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="nm_street<%=sRow%>" SIZE="20" MAXLENGTH="100" VALUE="<%=getField(oCsv,13,r)%>"></TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="nu_street<%=sRow%>" SIZE="4" MAXLENGTH="16" VALUE="<%=getField(oCsv,14,r)%>"></TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="tx_addr1<%=sRow%>" SIZE="10" MAXLENGTH="100" VALUE="<%=getField(oCsv,15,r)%>"></TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="tx_addr2<%=sRow%>" SIZE="10" MAXLENGTH="100" VALUE="<%=getField(oCsv,16,r)%>"></TD>
        <TD>
          <INPUT TYPE="hidden" NAME="nm_country<%=sRow%>">
          <SELECT CLASS="combomini" NAME="id_country<%=sRow%>" onchange="loadstates('id_country<%=sRow%>','id_state<%=sRow%>',null)"><OPTION VALUE=""></OPTION><% if (0==r) out.write(sCountriesLookUp); %></SELECT>
        </TD>
        <TD>
          <INPUT TYPE="hidden" NAME="nm_state<%=sRow%>">
          <SELECT CLASS="combomini" NAME="id_state<%=sRow%>"></SELECT>
        </TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="mn_city<%=sRow%>" SIZE="15" MAXLENGTH="50" VALUE="<%=getField(oCsv,19,r)%>"></TD>
        <TD><INPUT TYPE="text" CLASS="combomini" NAME="zipcode<%=sRow%>" SIZE="8" MAXLENGTH="30" VALUE="<%=getField(oCsv,20,r)%>"></TD>
      </TR>
<% } %>
    </TABLE>
  </FORM>
  <HR>
  <FORM ENCTYPE="multipart/form-data" METHOD="post" ACTION="contact_fastedit.jsp" onsubmit="return (document.forms[1].nm_csvfile.value.length>0)">
    <TABLE>
      <TR>
        <TD CLASS="textplain">Load File</TD>
        <TD><INPUT TYPE="file" NAME="nm_csvfile" SIZE="40"></TD>
      </TR>
      <TR>
        <TD CLASS="textplain">Character set </TD>
        <TD>
              <SELECT NAME="sel_encoding">
                <OPTION VALUE="UTF8">UTF-8</OPTION>
                <OPTION VALUE="UTF-16">UTF-16</OPTION>
                <OPTION VALUE="UnicodeBig">Sixteen-bit Unicode big endian with byte-order mark</OPTION>
                <OPTION VALUE="UnicodeBigUnmarked">Sixteen-bit Unicode big endian</OPTION>
                <OPTION VALUE="UnicodeLittle">Sixteen-bit Unicode little endian with byte-order mark</OPTION>
                <OPTION VALUE="UnicodeLittleUnmarked">Sixteen-bit Unicode little endian</OPTION>
                <OPTION VALUE="Cp1252">Windows Latin 1</OPTION>
                <OPTION VALUE="ISO8859_1" <%=bLatinLanguage ? "SELECTED" : ""%>>ISO 8859-1 Latin 1</OPTION>
                <OPTION VALUE="ISO8859_2">ISO 8859-1 Latin 2</OPTION>
                <OPTION VALUE="ISO8859_3">ISO 8859-1 Latin 3</OPTION>
                <OPTION VALUE="ISO8859_4">ISO 8859-1 Latin 4</OPTION>
                <OPTION VALUE="ISO8859_5" <%=bRussianLanguage ? "SELECTED" : ""%>>ISO 8859-5, Latin/Cyrillic</OPTION>
                <OPTION VALUE="ISO8859_6">ISO 8859-6, Latin/Arabic</OPTION>
                <OPTION VALUE="ISO8859_7">ISO 8859-7, Latin/Greek</OPTION>
                <OPTION VALUE="ISO8859_8">ISO 8859-8, Latin/Hebrew</OPTION>
                <OPTION VALUE="JIS0201">JIS X 0201, Japanese</OPTION>
                <OPTION VALUE="KOI8_R">KOI8-R, Russian</OPTION>
                <OPTION VALUE="ASCII">ASCII</OPTION>
                <OPTION VALUE="Cp437">MS-DOS</OPTION>
                <OPTION VALUE="Cp500">EBCDIC 500V1</OPTION>
                <OPTION VALUE="Big5" <%=bChineseTraditional ? "SELECTED" : ""%>>Big5 Traditional Chinese</OPTION>
                <OPTION VALUE="MS936" <%=bChineseSimplified ? "SELECTED" : ""%>>MS936 Windows Simplified Chinese</OPTION>
                <OPTION VALUE="MS950">MS950 Windows Traditional Chinese</OPTION>
                <OPTION VALUE="MS932">MS932 Windows Japanese</OPTION>
                <OPTION VALUE="MS874">MS874 Windows Thai</OPTION>
              </SELECT>        
        </TD>
      </TR>
      <TR>
        <TD CLASS="textplain">Column Delimiter</TD>
        <TD>
          <SELECT NAME="sel_delim"><OPTION VALUE="T" SELECTED>Tab</OPTION><OPTION VALUE=";">;</OPTION><OPTION VALUE=",">,</OPTION><OPTION VALUE="|">|</OPTION></SELECT>
          &nbsp;&nbsp;&nbsp;
          <INPUT TYPE="submit" CLASS="pushbutton" VALUE="Load">
        </TD>
      </TR>
      <TR>
        <TD CLASS="textsmall">
          The file must have structure
        </TD>
        <TD CLASS="textsmall">
          id_ref|tx_name|tx_surname|nm_legal|tx_email|direct_phone|id_sector|de_title|sn_passport|tp_passport|dt_birth|ny_age|tp_street|nm_street|nu_street|tx_addr1|tx_addr2|id_country|id_state|mn_city|zipcode
        </TD>
      </TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>