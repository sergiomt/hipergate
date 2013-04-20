<%@ page import="com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
  
  int iMaxLength = 30;
  String nm_table = request.getParameter("nm_table");
  String id_language = request.getParameter("id_language");
  String id_section = request.getParameter("id_section");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");
  String id_form = nullif(request.getParameter("id_form"), "0");

  DBTable oTable = null;
  DBColumn oColumn = null;
  String sWorkArea = nullif(request.getParameter("gu_workarea"), getCookie(request,"workarea", request.getParameter("gu_workarea")));
  String sQryStr = "?gu_workarea="+sWorkArea+"&nm_table="+ nm_table + "&id_language=" + id_language + "&id_section=" + id_section + "&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding + "&id_form=" + id_form;

  if (nm_table.endsWith("_lookup")) {    
    oTable = GlobalDBBind.getDBTable(nm_table.substring(0,nm_table.length()-7));    
    if (oTable!=null) oColumn = oTable.getColumnByName(id_section);    
    if (oColumn!=null) iMaxLength = oColumn.getPrecision();
    if (0==iMaxLength) iMaxLength = 30;
    if (nm_table.equals("k_addresses_lookup") && nm_coding.equals("id_state")) iMaxLength = 9;    
    oColumn = null;
    oTable = null;  
  } // fi()   
%>
<HTML>
  <HEAD>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
      
      function validate() {
        var frm = document.forms[0];
        var str;
        
        if (frm.tr_<%=id_language%>.value.length==0) {
          alert ("Description is mandatory");
          return false;
        }

	      str = frm.vl_lookup.value;

        if (str.length==0) {
          alert ("Value is mandatory");
          return false;
        }
	
        if (hasForbiddenChars(str)) {
          alert ("Value contains invalid characters");
          return false;
        }

	      frm.vl_lookup.value = str.toUpperCase();
        
        window.parent.lookupup.location.href = "lookup_up.jsp<%=sQryStr%>";
        
        return true;
      } // validate()
      
      //-->
    </SCRIPT>  
    <TITLE>hipergate :: Add Value</TITLE>
  </HEAD>
  
  <BODY  LEFTMARGIN="4" TOPMARGIN="4" SCROLL="no">
    <CENTER>
      <TABLE WIDTH="80%"><TR><TD ALIGN="center" CLASS="striptitle"><FONT CLASS="title1">Add value</FONT></TD></TR></TABLE></CENTER>
    <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>
    <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>
    <FORM METHOD="POST" ACTION="lookup_store.jsp<%=sQryStr%>&xxx=1" onsubmit="return validate()">
      <CENTER>
      <TABLE CLASS="formback">
        <TR><TD>
          <TABLE CLASS="formfront">
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Actual value stored internally at database"><FONT CLASS="formstrong">Value:</FONT></A></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="<%=String.valueOf(iMaxLength>30 ? 30 : iMaxLength)%>" MAXLENGTH="<%=String.valueOf(iMaxLength)%>" NAME="vl_lookup" STYLE="text-transform:uppercase"></TD>          
              <TD></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">English Description:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_en"></TD>
              <TD><IMG SRC="../images/images/flags/en.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">Spanish Description:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_es"></TD>
              <TD><IMG SRC="../images/images/flags/es.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">French Description:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_fr"></TD>
              <TD><IMG SRC="../images/images/flags/fr.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">Portuguese Description:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_pt"></TD>
              <TD><IMG SRC="../images/images/flags/br.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">German Description:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_de"></TD>
              <TD><IMG SRC="../images/images/flags/de.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">Italian Description:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_it"></TD>
              <TD><IMG SRC="../images/images/flags/it.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">Finnish Description:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_fi"></TD>
              <TD><IMG SRC="../images/images/flags/fi.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">Russian Description:</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_ru"></TD>
              <TD><IMG SRC="../images/images/flags/ru.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">Traditional Chinese</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_cn"></TD>
              <TD><IMG SRC="../images/images/flags/tw.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
            <TR>
              <TD ALIGN="right"><A style="cursor:help" title="Descriptive text shown<BR>when value is chosen"><FONT CLASS="formplain">Simplified Chinese</FONT></SPAN></TD>
              <TD ALIGN="left"><INPUT TYPE="text" SIZE="30" MAXLENGTH="50" NAME="tr_tw"></TD>
              <TD><IMG SRC="../images/images/flags/cn.gif" WIDTH="16" HEIGHT="11" BORDER="0"></TD>
            </TR>
          </TABLE>
        </TD></TR>
      </TABLE>
      <BR>
      <INPUT TYPE="submit" VALUE="Save" CLASS="pushbutton" STYLE="width:80">&nbsp;&nbsp;<INPUT TYPE="button" VALUE="Cancel" CLASS="closebutton" onClick="window.parent.lookupup.location=('<%=nm_table%>'=='k_duties_lookup' ? '../projtrack/resource_' : '')+'lookup_up.jsp<%=sQryStr%>';document.location=('<%=nm_table%>'=='k_duties_lookup' ? '../projtrack/resource_' : '')+'lookup_mid.jsp<%=sQryStr%>';">
      </CENTER>
    </FORM>
  </BODY>
</HTML>