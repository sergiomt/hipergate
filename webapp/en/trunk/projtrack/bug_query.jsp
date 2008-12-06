<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
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

  String sSkin = getCookie(request, "skin", "default");
%>
<HTML>
  <HEAD>
    <TITLE>hipergate :: Search Incidents</TITLE>
    <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/layer.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/usrlang.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');

      // ------------------------------------------------------

      function filterOperators(odctrl) {
        var operators = new Array("=","<>",">","<","S","C","N","M");
        var names_es = new Array("Equal to","Not equal","Greater than","Less than","Starts with&nbsp;","Contains","Is NULL","Is not NULL");
	var fld;
	var opts;
	var nOpers;
	
	switch (odctrl) {
	  case 1:
	    fld = getCombo(document.forms[0].field1);
	    opts = document.forms[0].operator1.options;
	    break;
	  case 2:
	    fld = getCombo(document.forms[0].field2);
	    opts = document.forms[0].operator2.options;
	    break;
	  case 3:
	    fld = getCombo(document.forms[0].field3);	  
	    opts = document.forms[0].operator3.options;
	    break;
	}
	
	opts.length = 0;
	
	if (fld=="tx_status")
	  nOpers = 2;
	else if (fld=="od_severity" || fld=="od_priority" || fld=="dt_created" || fld=="dt_closed" || fld=="pg_bug")
	  nOpers = 4;
	else
	  nOpers = 8;
	  
	for (var i=0; i<nOpers; i++)
	  opts[i] = new Option(names_es[i], operators[i]);	                
      } // filterOperators()
      
            
      // ------------------------------------------------------

      function showLookUp(odctrl) {
        var frm = document.forms[0];
        var fld;
        
        filterOperators(odctrl);
        
	switch (odctrl) {
	  case 1:
	    fld = getCombo(frm.field1);
	    break;
	  case 2:
	    fld = getCombo(frm.field2);
	    break;
	  case 3:
	    fld = getCombo(frm.field3);
	    break;
        }
        
        if (fld=="tx_status" || fld=="od_severity" || fld=="od_priority" || fld=="dt_created" || fld=="dt_closed" || fld=="nm_project" || fld=="nm_assigned")
          showLayer("lookup" + odctrl);
        else
          hideLayer("lookup" + odctrl);
          
        return true;
      } // showLookUp()

      // ------------------------------------------------------

      function getClause(fld,opr,vle) {
        var ret;
        
        if (fld=="nm_project") {
          if (opr=="S")
            ret = "p.nm_project <%=DBBind.Functions.ILIKE%> '" + vle + "%' ";
          else if (opr=="C")
            ret = "p.nm_project <%=DBBind.Functions.ILIKE%> '%" + vle + "%' ";
          else if (opr=="N")
            ret = "p.nm_project IS NULL ";
          else if (opr=="M")
            ret = "p.nm_project IS NOT NULL ";
          else
            ret = "p.nm_project " + opr + " '" + vle + "' ";
        }
        else if (fld=="od_severity" || fld=="od_priority" || fld=="dt_created" || fld=="dt_closed" || fld=="pg_bug") {
          ret = "b."+ fld + opr + vle + " ";
        }
        else {
          if (opr=="S")
            ret = "b." + fld + " <%=DBBind.Functions.ILIKE%> '" + vle + "%' ";
          else if (opr=="C")
            ret = "b." + fld + " <%=DBBind.Functions.ILIKE%> '%" + vle + "%' ";
          else if (opr=="N")
            ret = "b." + fld + " IS NULL ";
          else if (opr=="M")
            ret = "b." + fld + " IS NOT NULL ";
          else
            ret = "b." + fld + opr + " '" + vle + "' ";
        }
        return ret;
      } // getClause()

      // ------------------------------------------------------
      
      function lookup(odctrl) {
        var frm = document.forms[0];
        var sect;
        var ctrl;
        var code;
        var dtnw = new Date();
        
        switch (parseInt(odctrl)) {
          case 1:
            sect = getCombo(frm.field1);
            ctrl = "value1";
            code = "code1";
            break;
          case 2:
            sect = getCombo(frm.field2);
            ctrl = "value2";
            code = "code2";
            break;
          case 3:
            sect = getCombo(frm.field3);
            ctrl = "value3";
            code = "code3";
            break;            
        }

        if (sect=="tx_status" || sect=="od_severity" || sect=="od_priority" || sect=="nm_assigned")
          window.open("../common/lookup_f.jsp?nm_table=k_bugs_lookup&id_language=" + getUserLanguage() + "&id_section=" + sect + " &tp_control=1&nm_control=" + ctrl + "&nm_coding=" + code, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
        else if (sect=="dt_created" || sect=="dt_closed")
          window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
        else if (sect=="nm_project")
          window.open("proj_tree_f.jsp?id_language=" + getUserLanguage() + "&id_section=" + sect + " &tp_control=1&nm_control=" + ctrl + "&nm_coding=" + code, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=276,height=440");         
      } // lookup()

      // ------------------------------------------------------
      
      function validate() {
        var frm = document.forms[0];
        var qry = "";
        var cmb;
        var opr;
        var val;
        var cod;
	
        cmb = getCombo(frm.field1);
	opr = getCombo(frm.operator1);
        val = frm.value1.value;
        cod = frm.code1.value;

        if (val.length==0) {
            alert ("Must specify a value to be searched at least for the first condition");
            return false;
          }
                  
        if (cmb=="pg_bug")
          if (isNaN(val)) {
            alert ("Incident number is not valid");
            return false;
          }

        if (cmb=="od_priority")
          if (isNaN(cod)) {
            alert ("Priority is not valid");
            return false;
          }
            
        if (cmb=="od_severity")
          if (isNaN(cod)) {
            alert ("Severity is not valid");
            return false;
          }
                
        // * Cambio del estado PENDIENTE por tx_status==NULL
        if (cmb=="tx_status" && val=="PENDIENTE")
          if (opr=="=") opr="N"; else if (opr=="<>") opr="M";
        // ***
        
        if (cmb=="dt_created" || cmb=="dt_closed")
          if (!isDate(val,"d")) {
            alert ("Date for field 1 is not valid, use format yyyy-mm-dd");
            return false;
          }
          else
            cod = "{ d '" + val + "'}";
        // ***
                          
        if (val.length>0 || opr=="N" || opr=="M") {
            qry = getClause(cmb, opr, cod.length>0 && cmb!="nm_project" ? cod : val);
        
	  if (frm.condition1.value.length>0) {
	    qry += frm.condition1.value + " ";
	    
            cmb = getCombo(frm.field2);
	    opr = getCombo(frm.operator2);
            val = frm.value2.value;
            cod = frm.code2.value;

            if (cmb=="pg_bug")
              if (isNaN(val)) {
                alert ("Incident number is not valid");
                return false;
            }

            if (cmb=="od_priority")
              if (isNaN(cod)) {
                alert ("Priority is not valid");
                return false;
              }
              else
                frm.value2.value = cod;
                        
            if (cmb=="od_severity")
              if (isNaN(cod)) {
                alert ("Severity is not valid");
                return false;
              }
              else
                frm.value2.value = cod;              

            // * Cambio del estado PENDIENTE por tx_status==NULL
            if (cmb=="tx_status" && val=="PENDIENTE")
            if (opr=="=") opr="N"; else if (opr=="<>") opr="M";
            // ***

            if (cmb=="dt_created" || cmb=="dt_closed")
              if (!isDate(val,"d")) {
                alert ("Date for field 2 is not valid, use format yyyy-mm-dd");
                return false;
              }
              else
                cod = "{ d '" + val + "'}";
            // ***
            
            qry += getClause(cmb, opr, cod.length>0 && cmb!="nm_project" ? cod : val);
	
	    if (frm.condition2.value.length>0) {
	      qry += frm.condition2.value + " ";

              cmb = getCombo(frm.field3);
	      opr = getCombo(frm.operator3);	
              val = frm.value3.value;
              cod = frm.code3.value;

              if (cmb=="pg_bug")
                if (isNaN(val)) {
                  alert ("Incident number is not valid");
                  return false;
                }

              if (cmb=="od_priority")
                if (isNaN(cod)) {
                  alert ("Priority is not valid");
                  return false;
                }
                else
                  frm.value3.value = cod;
                  
              if (cmb=="od_severity")
                if (isNaN(cod)) {
                  alert ("Severity is not valid");
                  return false;
                }
                else
                  frm.value3.value = cod;

              // * Cambio del estado PENDIENTE por tx_status==NULL
              if (cmb=="tx_status" && val=="PENDIENTE")
              if (opr=="=") opr="N"; else if (opr=="<>") opr="M";
              // ***

              if (cmb=="dt_created" || cmb=="dt_closed")
                if (!isDate(val,"d")) {
                  alert ("Date for field 3 is not valid, use format yyyy-mm-dd");
                  return false;
                }
                else
                  cod = "{ d '" + val + "'}";
              // ***

              qry += getClause(cmb, opr, cod.length>0 && cmb!="nm_project" ? cod : val);
	    }
	  }
	}
	
	frm.where.value = " AND (" + qry + ")";
	
        return true;
      } // validate()
                  
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  TOPMARGIN="0" MARGINHEIGHT="0">
    <%@ include file="../common/header.jspf" %>
    <FORM METHOD="post" ACTION="bug_list.jsp" onSubmit="return validate()">
      <TABLE><TR><TD WIDTH="420px" CLASS="striptitle"><FONT CLASS="title1">Search Incidents</FONT></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="where">
      <TABLE BORDER="0">
        <TR>
          <TD>
            <SELECT NAME="field1" onClick="showLookUp(1)">
              <OPTION VALUE="tl_bug">Subject</OPTION>
              <OPTION VALUE="nm_project">Project</OPTION>
              <OPTION VALUE="od_severity">Severity</OPTION>
              <OPTION VALUE="od_priority">Priority</OPTION>
              <OPTION VALUE="tx_status">Status</OPTION>
              <OPTION VALUE="dt_created">Date Reported</OPTION>
              <OPTION VALUE="dt_closed">Date Corrected</OPTION>
              <OPTION VALUE="pg_bug">Ref. Number</OPTION>
              <OPTION VALUE="nm_reporter">Reported by</OPTION>
              <OPTION VALUE="nm_assigned">Assigned to&nbsp;</OPTION>
              <OPTION VALUE="tx_bug_brief">Description</OPTION>
            </SELECT>
          </TD>
          <TD>
            <SELECT NAME="operator1" STYLE="width:100">
              <OPTION VALUE="=">Equal to</OPTION>
              <OPTION VALUE="<>">Not equal</OPTION>
              <OPTION VALUE=">">Greater than</OPTION>
              <OPTION VALUE="<">Less than</OPTION>
              <OPTION VALUE="S">Starts with&nbsp;</OPTION>
              <OPTION VALUE="C">Contains</OPTION>
              <OPTION VALUE="N">Is NULL</OPTION>
              <OPTION VALUE="M">Is not NULL</OPTION>
            </SELECT>
          </TD>
          <TD>
            <INPUT TYPE="hidden" NAME="code1">
            <DIV ID="val1txt" STYLE="position:relative;visibility:visible"><INPUT TYPE="text" NAME="value1" onChange="document.forms[0].code1.value=''"></DIV>
          </TD>
          <TD>
            <DIV ID="lookup1" STYLE="position:relative;visibility:hidden"><A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A></DIV>           
          </TD>
        </TR>
        <TR>        
          <TD COLSPAN="4">
            <SELECT NAME="condition1">
              <OPTION VALUE=""></OPTION>
              <OPTION VALUE="AND">Y</OPTION>
              <OPTION VALUE="OR">O</OPTION>
            </SELECT>
            <BR>
          </TD>
        </TR>
        <TR>
          <TD>
            <SELECT NAME="field2" onClick="showLookUp(2)">
              <OPTION VALUE="tl_bug">Subject</OPTION>
              <OPTION VALUE="nm_project">Project</OPTION>
              <OPTION VALUE="od_severity">Severity</OPTION>
              <OPTION VALUE="od_priority">Priority</OPTION>
              <OPTION VALUE="tx_status">Status</OPTION>
              <OPTION VALUE="dt_created">Date Reported</OPTION>
              <OPTION VALUE="dt_closed">Date Corrected</OPTION>
              <OPTION VALUE="pg_bug">Ref. Number</OPTION>
              <OPTION VALUE="nm_reporter">Reported by</OPTION>
              <OPTION VALUE="nm_assigned">Assigned to&nbsp;</OPTION>
              <OPTION VALUE="tx_bug_brief">Description</OPTION>
            </SELECT>
          </TD>
          <TD>    
            <SELECT NAME="operator2" STYLE="width:100">
              <OPTION VALUE="=">Equal to</OPTION>
              <OPTION VALUE="<>">Not equal</OPTION>
              <OPTION VALUE=">">Greater than</OPTION>
              <OPTION VALUE="<">Less than</OPTION>
              <OPTION VALUE="S">Starts with&nbsp;</OPTION>
              <OPTION VALUE="C">Contains</OPTION>
            </SELECT>
          </TD>
          <TD>
            <INPUT TYPE="hidden" NAME="code2">
            <DIV ID="val2txt" STYLE="position:relative;visibility:visible"><INPUT TYPE="text" NAME="value2" onChange="document.forms[0].code2.value=''"></DIV>
          </TD>
          <TD VALIGN="middle">
            <DIV ID="lookup2" STYLE="position:relative;visibility:hidden"><A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A></DIV>
          </TD>
        </TR>
        <TR>
          <TD COLSPAN="3">          
            <SELECT NAME="condition2">
              <OPTION VALUE=""></OPTION>
              <OPTION VALUE="AND">Y</OPTION>
              <OPTION VALUE="OR">O</OPTION>
            </SELECT>
            <BR>
          </TD>
        </TR>
        <TR>
          <TD>
            <SELECT NAME="field3" onClick="showLookUp(3)">
              <OPTION VALUE="tl_bug">Subject</OPTION>
              <OPTION VALUE="nm_project">Project</OPTION>
              <OPTION VALUE="od_severity">Severity</OPTION>
              <OPTION VALUE="od_priority">Priority</OPTION>
              <OPTION VALUE="tx_status">Status</OPTION>
              <OPTION VALUE="dt_created">Date Reported</OPTION>
              <OPTION VALUE="dt_closed">Date Corrected</OPTION>
              <OPTION VALUE="pg_bug">Ref. Number</OPTION>
              <OPTION VALUE="nm_reporter">Reported by</OPTION>
              <OPTION VALUE="nm_assigned">Assigned to&nbsp;</OPTION>
              <OPTION VALUE="tx_bug_brief">Description</OPTION>
            </SELECT>
          </TD>
          <TD>          
            <SELECT NAME="operator3" STYLE="width:100">
              <OPTION VALUE="=">Equal to</OPTION>
              <OPTION VALUE="<>">Not equal</OPTION>
              <OPTION VALUE=">">Greater than</OPTION>
              <OPTION VALUE="<">Less than</OPTION>
              <OPTION VALUE="S">Starts with&nbsp;</OPTION>
              <OPTION VALUE="C">Contains</OPTION>
            </SELECT>
          </TD>
          <TD>
            <INPUT TYPE="hidden" NAME="code3">
            <DIV ID="val2txt" STYLE="position:relative;visibility:visible"><INPUT TYPE="text" NAME="value3" onChange="document.forms[0].code3.value=''"></DIV>
          </TD>
          <TD>
            <DIV ID="lookup3" STYLE="position:relative;visibility:hidden"><A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A></DIV>          
          </TD>
        </TR>
      </TABLE>
      <BR>
      <INPUT TYPE="submit" ACCESSKEY="q" TITLE="ALT+q" VALUE="Query" CLASS="pushbutton">      
    </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>