<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
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
    
  //if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = request.getParameter("gu_pageset");
  String gu_datasheet = request.getParameter("gu_datasheet");
  String pg_previous = request.getParameter("gu_previous");
  
  String sCountriesLookUp = "", sEducationLookUp = "", sMaritalLookUp = "", sHomeLookUp = "", sPoliticsLookUp = "";
    
  JDCConnection oConn = null;
  DBPersist oInfo = new DBPersist(DB.k_pageset_datasheets, "DataSheetInfo");
    
  try {

    oConn = GlobalDBBind.getConnection("survey_info");  

    oInfo.load(oConn, new Object[]{gu_datasheet});

    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);    
    sEducationLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_datasheets_lookup, gu_pageset, "tx_education", sLanguage);
    sMaritalLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_datasheets_lookup, gu_pageset, "marital_status", sLanguage);
    sHomeLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_datasheets_lookup, gu_pageset, "tp_home", sLanguage);
    sPoliticsLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_datasheets_lookup, gu_pageset, "tx_politics", sLanguage);
        
    oConn.close("survey_info");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("survey_info");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));  
  }
  if (null==oConn) return;  
  oConn = null;
  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      // ------------------------------------------------------
      
      function loadstates(setval) {
	var frm = window.document.forms[0];

        clearCombo(frm.sel_state);
        
        if (frm.sel_country.options.selectedIndex>0) {          
          if (setval==null)
            parent.frames[1].location.href = "../common/addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getURLParam("gu_workarea") + "&id_section=" + getCombo(frm.sel_country) + "&control=sel_state";        
          else
            parent.frames[1].location.href = "../common/addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getURLParam("gu_workarea") + "&id_section=" + getCombo(frm.sel_country) + "&control=sel_state&set_value=" + setval;
        
          sortCombo(frm.sel_state);
        }  
      } // loadstates

      // ------------------------------------------------------
              
      function lookup(odctrl) {
        var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_datasheets_lookup&id_language=" + getUserLanguage() + "&id_section=tx_field&tp_control=2&nm_control=sel_field&nm_coding=tx_field", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            if (frm.sel_country.options.selectedIndex>=0)
              window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=" + getCombo(frm.sel_country) + "&tp_control=2&nm_control=sel_state&nm_coding=id_state", "lookupaddrstate", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            else
              alert ("[~Debe seleccionar un Pais antes de poder escoger la Provincia o Estado~]");
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------


      function validate() {
        var frm = window.document.forms[0];

	/*
	if (frm.tx_comments.value.length>254) {
	  alert ("Comments cannot exceed 254 characters");
	  return false;
	}
	
	if (!isDate(frm.dt_xxxx.value, "d") && frm.dt_xxxx.value.length>0) {
	  alert ("Invalid Date");
	  return false;	  
	}

	// Move selected combo value into hidden field
	frm.id_status.value = getCombo(frm.sel_status);
        */

        if (frm.sel_country.options.selectedIndex<0) {
	  alert ("[~El pais es obligatorio~]");
	  return false;	  
        }

        if (frm.sel_state.options.selectedIndex<0) {
	  alert ("[~La provincia es obligatoria~]");
	  return false;	  
        }

        if (rtrim(getCombo(frm.sel_country))=="es") {
          if (frm.zip_code.value.length!=0 && frm.zip_code.value.length!=5) {
	    alert ("[~El código postal debe contener exactamente 5 cifras~]");
	    return false;
	  }

	  if (!isIntValue(frm.zip_code.value)) {
	    alert ("[~El código postal debe contener exactamente 5 cifras~]");
	    return false;
	  }
        } // fi sel_country == es
        
        if (frm.sel_education.options.selectedIndex<=0) {
	  alert ("[~El nivel de estudios es obligatorio~]");
	  return false;	  
        }

        if (frm.sel_marital.options.selectedIndex<=0) {
	  alert ("[~El estado civil es obligatorio~]");
	  return false;	  
        }

        if (frm.sel_home.options.selectedIndex<=0) {
	  alert ("[~El tipo de vivienda es obligatorio~]");
	  return false;	  
        }

	if (!isIntValue(frm.nu_income.value)) {
	  alert ("[~El nivel de ingresos debe ser una cantidad entera válida~]");
	  return false;
	}

	if (frm.pr_mortgage.value.length==0 || isIntValue(frm.pr_mortgage.value)) {
	  alert ("[~El coste mensual de la hipoteca debe ser una cantidad entera válida~]");
	  return false;
	}

        frm.id_gender.value = getCombo(frm.sel_gender);
        frm.id_country.value = getCombo(frm.sel_country);
	frm.id_state.value = getCombo(frm.sel_state);
	frm.nm_state.value = getComboText(frm.sel_state);
	frm.marital_status.value = getComboText(frm.sel_marital);
	frm.tp_home.value = getComboText(frm.sel_home);
	frm.nu_children.value = getComboText(frm.sel_children);        
        frm.bo_wantschilds.value = (frm.chk_wantschilds[0].checked ? "Y" : "N");
          
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = window.document.forms[0];

        setCombo  (frm.sel_gender, "<%=oInfo.getStringNull(DB.id_gender,"")%>");
        setCombo  (frm.sel_marital, "<%=oInfo.getStringNull(DB.marital_status,"")%>");
        setCombo  (frm.sel_home, "<%=oInfo.getStringNull(DB.tp_home,"")%>");
        setCombo  (frm.sel_children, "<% if (!oInfo.isNull(DB.nu_children)) out.write(oInfo.getInt(DB.nu_children)); %>");
        setCombo  (frm.sel_education, "<%=oInfo.getStringNull(DB.tx_education,"")%>");
        setCombo  (frm.sel_politics, "<%=oInfo.getStringNull(DB.tx_politics,"")%>");

	if (""=="<%=oInfo.getStringNull(DB.id_country,"").trim()%>")
          setCombo (frm.sel_country, "es");
	else
          setCombo  (frm.sel_country, "<%=oInfo.getStringNull(DB.id_country,"").trim()%>");
        
        loadstates(frm.id_state.value);
        
        return true;
      } // setCombos()
    //-->
  </SCRIPT>    
</HEAD>
<BODY  LEFTMARGIN="8" MARGINWIDTH="8" TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">[~Informacion adicional~]</FONT></TD></TR>
  </TABLE>
  <FORM METHOD="post" ACTION="survey_verify.jsp" TARGET="_top" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_pageset" VALUE="<%=gu_pageset%>">
    <INPUT TYPE="hidden" NAME="gu_datasheet" VALUE="<%=gu_datasheet%>">
    <INPUT TYPE="hidden" NAME="pg_previous" VALUE="<%=pg_previous%>">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~Pais:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
	      <SELECT NAME="sel_country" onchange="loadstates()"><OPTION VALUE="es">Espa&ntilde;a</OPTION></SELECT>
              <INPUT TYPE="hidden" NAME="id_country" VALUE="<%=oInfo.getStringNull(DB.id_country,"").trim()%>">
              <INPUT TYPE="hidden" NAME="nm_country" VALUE=""><!-- not used but do not remove -->
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">State:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="[~Ver provincias~]"></A>&nbsp;<SELECT CLASS="combomini" NAME="sel_state"></SELECT>
              <INPUT TYPE="hidden" NAME="id_state" MAXLENGTH="16" VALUE="<%=oInfo.getStringNull(DB.id_state,"")%>">
              <INPUT TYPE="hidden" NAME="nm_state" MAXLENGTH="30" VALUE="<%=oInfo.getStringNull(DB.nm_state,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~C&oacute;digo Postal:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
	      <INPUT NAME="zip_code" TYPE="text" MAXLENGTH="16" SIZE="10" VALUE="<%=oInfo.getStringNull("zip_code","")%>" onkeypress="return ((rtrim(getCombo(document.forms[0].sel_country))=='es') ? acceptOnlyNumbers(this) : true);">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~Sexo:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="id_gender">
              <SELECT NAME="sel_gender"><OPTION VALUE="M">[~Hombre~]</OPTION><OPTION VALUE="M">[~Mujer~]</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~Estado civil:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="marital_status">
              <SELECT NAME="sel_marital"><OPTION VALUE=""></OPTION><%=sMaritalLookUp%></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~Tipo de vivienda:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tp_home">
              <SELECT NAME="sel_home"><OPTION VALUE=""></OPTION><%=sHomeLookUp%></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~Hipoteca:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
	      <INPUT TYPE="text" NAME="pr_mortgage" MAXLENGTH="8" SIZE="8" VALUE="<% if (!oInfo.isNull(DB.pr_mortgage)) out.write(String.valueOf(oInfo.getInt(DB.pr_mortgage))); %>" onkeypress="return acceptOnlyNumbers(this);">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~Ingresos anuales:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
	      <INPUT TYPE="text" NAME="nu_income" MAXLENGTH="8" SIZE="8" VALUE="<% if (!oInfo.isNull(DB.nu_income)) out.write(String.valueOf(oInfo.getInt(DB.nu_income))); %>" onkeypress="return acceptOnlyNumbers(this);">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~Hijos:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="nu_children">
              <SELECT NAME="sel_children"><OPTION VALUE="0">Ninguno</OPTION><OPTION VALUE="1">1</OPTION><OPTION VALUE="2">2</OPTION><OPTION VALUE="3">3</OPTION><OPTION VALUE="4">4</OPTION><OPTION VALUE="5">5</OPTION><OPTION VALUE="6">6</OPTION><OPTION VALUE="7">7</OPTION><OPTION VALUE="8">8</OPTION><OPTION VALUE="9">9</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">+10</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~¿Quieres tener hijos?~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="bo_wantchilds">
	      <INPUT TYPE="radio" NAME="chk_wantchilds" <% if (oInfo.isNull(DB.bo_wantchilds)) out.write("CHECKED"); else out.write((oInfo.getString(DB.bo_wantchilds).equals("Y") ? "CHECKED" : "")); %>>&nbsp;<FONT CLASS="formplain">[~Si~]</FONT>&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="chk_wantschilds" <% if (!oInfo.isNull(DB.bo_wantchilds)) out.write((oInfo.getString(DB.bo_wantchilds).equals("N") ? "CHECKED" : "")); %>>&nbsp;<FONT CLASS="formplain">No</FONT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~Nivel de estudios:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tx_education">
              <SELECT NAME="sel_education"><OPTION VALUE=""></OPTION><%=sEducationLookUp%></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">[~Orientaci&oacute;n Pol&iacute;tica:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tx_politics">
              <SELECT NAME="sel_politics"><OPTION VALUE=""></OPTION><%=sPoliticsLookUp%></SELECT>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT onclick="validate()" TYPE="button" ACCESSKEY="s" VALUE="[~Finalizar~]" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
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
