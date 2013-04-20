<%@ page import="java.net.URLDecoder,java.sql.Statement,java.sql.ResultSet,java.sql.ResultSetMetaData,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.datamodel.ModelManager" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
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

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);  
  int iRows = Integer.parseInt(nullif(request.getParameter("rows"),"10"));

  String gu_workarea = getCookie(request,"workarea","");
  String nm_table = request.getParameter("nm_table");
  String id_section = request.getParameter("id_section");
  String nm_referer = nullif(request.getParameter("nm_referer"));

  String sCountryList = "id_country,tr_country_en,tr_country_es,tr_country_fr,tr_country_de,tr_country_it,tr_country_pt,tr_country_ca,tr_country_eu,tr_country_ja,tr_country_cn,tr_country_tw,tr_country_fi,tr_country_ru,tr_country_pl,tr_country_nl,tr_country_th,tr_country_cs,tr_country_uk,tr_country_no";
  DBSubset oCountries = new DBSubset(DB.k_lu_countries, sCountryList, null, 250);
  int iCountries = 0;
  DBSubset oLookups = null;
  int iLookups = 0;  
  int iColPos = -1;
  String sColList = "pg_lookup,vl_lookup,"+DBLanguages.getLookupTranslationsColumnList();
  String sMaxVlLen = "255", sMaxTrLen = "50";
  
  JDCConnection oConn = null;
  
  try {

		ModelManager oMMan = new ModelManager();
		oMMan.connect(GlobalDBBind.getProperty("driver"),GlobalDBBind.getProperty("dburl"),GlobalDBBind.getProperty("schema"),
									GlobalDBBind.getProperty("dbuser"),GlobalDBBind.getProperty("dbpassword"));
    int nFixes = oMMan.fixTranslationColumns();
    oMMan.disconnect();
    
    if (nFixes>0) GlobalDBBind.restart();

    oConn = GlobalDBBind.getConnection("lookups");  
    iCountries = oCountries.load(oConn);
    if (null!=nm_table && null!=id_section) {
      oLookups = new DBSubset (nm_table, sColList, DB.gu_owner+"=? AND "+DB.id_section+"=?", 100);
      iLookups = oLookups.load(oConn, new Object[]{gu_workarea, id_section});
      Statement oStmt = oConn.createStatement();
      ResultSet oRSet = oStmt.executeQuery("SELECT vl_lookup,tr_en FROM "+nm_table+" WHERE 1=0");
      ResultSetMetaData oMDat = oRSet.getMetaData();
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        sMaxVlLen = String.valueOf(oMDat.getColumnDisplaySize(1));
        sMaxTrLen = String.valueOf(oMDat.getColumnDisplaySize(2));
      } else {
        sMaxVlLen = String.valueOf(oMDat.getPrecision(1));
        sMaxTrLen = String.valueOf(oMDat.getPrecision(2));
      }
      oRSet.close();
      oRSet=null;
      oStmt.close();
      oStmt=null;
    }
    oConn.close("lookups");

  } catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("lookups");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }

  iColPos = oCountries.getColumnPosition("tr_country_"+sLanguage);
  oCountries.sortBy(iColPos);
  
  if (-1==iColPos) iColPos = 1;
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//en">
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <TITLE>hipergate :: Lookup values fastedit</TITLE>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--      
      var sections = new Array(null,
      			       new Array("tx_dept","tx_email_from","nm_from"),
      			       new Array("tp_location","tp_street"),
      			       new Array("id_sector","id_status","tp_company"),
      			       new Array("de_title","id_status","tp_passport"),
      			       new Array("de_title","tp_passport"),
      			       new Array("id_objetive","tp_oportunity","tp_origin","tx_cause"),
      			       new Array("tp_room")
      			       );

      function displaySections(i) {
        var frm = document.forms[0];
        var sec;
        clearCombo(frm.sel_section);
        if (frm.sel_section.firstChild)
          frm.sel_section.removeChild(frm.sel_section.firstChild);
        if (i>0) {
          frm.sel_section.options[0] = new Option("","",false,false);
          sec = sections[i];          
          for (var o=0; o<sec.length; o++) {
            frm.sel_section.options[o+1] = new Option(sec[o],sec[o],false,false);            
          }
          if (frm.sel_table.selectedIndex==1) {
      	    var countryGroup = document.createElement('optgroup');
            countryGroup.label = "Countries";
<%
            for (int c=0; c<iCountries; c++) {
	      out.write("            countryGroup.appendChild(new Option(\""+oCountries.getStringNull(iColPos,c,oCountries.getString(1,c))+"\",\""+oCountries.getString(0,c).trim()+"\",false,false));\n");
            }
%>
            frm.sel_section.appendChild(countryGroup);
          }
        }
      } // displaySections

      function loadValues() {
        var frm = document.forms[0];
        if (frm.sel_table.selectedIndex>0 && frm.sel_section.selectedIndex>0)
	  document.location.href = "lookups.jsp?nm_table="+getCombo(frm.sel_table)+"&id_section="+getCombo(frm.sel_section);
	else if (frm.sel_table.selectedIndex>0)
	  document.location.href = "lookups.jsp?nm_table="+getCombo(frm.sel_table);
      } // loadValues
      
      function deleteValues() {
        var frm = document.forms[0];
        var lok = <%=String.valueOf(iLookups)%>;
        var doit = false;
        
        for (var l=0; l<lok; l++) {
          if (frm.elements["chk"+String(l)].checked) {          	
            doit = true;
            frm.elements["vl_lookup"+String(l)].value="";
          }
        } // next
	      if (doit) {
	        frm.submit();
	      } else {
	        alert ("You must select at least one value to be deleted");
	      }
      } // deleteValues()

      function setCombos() {
        var frm = document.forms[0];
	var par;
	par = getURLParam("nm_table");
	if (par!=null) {
	  setCombo(frm.sel_table, par);
	  displaySections(frm.sel_table.selectedIndex);
	  par = getURLParam("id_section");
	  if (par!=null) {
	    setCombo(frm.sel_section, par);
	  }
	}
      }

      function hasTarget() {
	return document.forms[0].sel_table.selectedIndex>0 && document.forms[0].sel_section.selectedIndex>0;
      }

      function validate() {
        var frm = document.forms[0];
        var s;
        
        if (frm.sel_table.selectedIndex<=0) {
          alert ("The table name is required");
          return false;
        }
        if (frm.sel_section.selectedIndex<=0) {
          alert ("Section name is required");
          return false;
        }
        for (var r=0; r<<%=String.valueOf(iLookups+iRows)%>; r++) {
          s = String(r);
          if (frm.elements["pg_lookup"+s].value.length==0 &&
              ltrim(frm.elements["vl_lookup"+s].value).length==0 &&
             (frm.elements["tr_en"+s].value.length>0 || frm.elements["tr_es"+s].value.length>0)) {
            alert ("Row "+ s +" The internal value for the lookup is required");
            return false;
          } else {
            frm.elements["vl_lookup"+s].value = rtrim(frm.elements["vl_lookup"+s].value.toUpperCase());
          }
          if (hasForbiddenChars(frm.elements["vl_lookup"+s].value)) {
            alert ("Row "+ s +" The internal value has forbidden characters");
            return false;          
          }
        } // next
      } // validate
    // -->
  </SCRIPT>
</HEAD>
<BODY MARGINWIDTH="8" LEFTMARGIN="8" TOPMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">
  <%@ include file="../common/header.jspf" %>
  <TABLE>
    <TR>
      <TD>
        <DIV class="cxMnu1" style="width:220px"><DIV class="cxMnu2">
          <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.location='<%=(nm_referer.length()==0 ? "../vdisk/usr_top_f.htm?selected=9&subselected=0" : "../crm/"+nm_referer)%>'"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
          <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
        </DIV></DIV>
      </TD>
      <TD CLASS="striptitle"><FONT CLASS="title1">Lookup values fastedit</FONT></TD>
    </TR>
  </TABLE>
  <FORM METHOD="post" ACTION="lookups_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="nu_rows" VALUE="<%=String.valueOf(iLookups+iRows)%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="collist" VALUE="<%=sColList%>">
    <TABLE>
      <TR>
        <TD>
          <SELECT NAME="sel_table" onchange="displaySections(this.selectedIndex)">
          	<OPTION VALUE=""></OPTION>
          	<OPTION VALUE="k_activity_audience_lookup">k_activity_audience_lookup</OPTION>
          	<OPTION VALUE="k_addresses_lookup">k_addresses_lookup</OPTION>
          	<OPTION VALUE="k_companies_lookup">k_companies_lookup</OPTION>
          	<OPTION VALUE="k_contacts_lookup">k_contacts_lookup</OPTION>
          	<OPTION VALUE="k_fellows_lookup">k_fellows_lookup</OPTION>
          	<OPTION VALUE="k_oportunities_lookup">k_oportunities_lookup</OPTION>
          	<OPTION VALUE="k_rooms_lookup">k_rooms_lookup</OPTION>
         </SELECT>
        </TD>
        <TD>
          <SELECT NAME="sel_section" onchange="loadValues()"><OPTION VALUE=""></OPTION></SELECT>
        </TD>
        <TD>
          <INPUT TYPE="submit" CLASS="pushbutton" VALUE="Save">
        </TD>
      </TR>
      <TR>
        <TD>
          <% if (iLookups>0) { %> 
          <IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete">
          <A HREF="#" onclick="deleteValues()" CLASS="linkplain">Delete Selected</A>
          <% } %>
        </TD>
        <TD></TD>
        <TD></TD>
      </TR>
    </TABLE>
    <TABLE>
<%	out.write("      <TR>\n");
	String[] aColList = Gadgets.split(sColList,',');
	int iListLen = aColList.length;
	out.write("<TD CLASS=\"tableheader\" BACKGROUND=\"../skins/"+sSkin+"/tablehead.gif\"></TD>");
	out.write("<TD CLASS=\"tableheader\" BACKGROUND=\"../skins/"+sSkin+"/tablehead.gif\"></TD>");
	for (int c=1; c<iListLen; c++) {
	  out.write("<TD CLASS=\"tableheader\" BACKGROUND=\"../skins/"+sSkin+"/tablehead.gif\">&nbsp;<B>"+aColList[c]+"</B>&nbsp;</TD>");
	}
	out.write("      </TR>\n");
	for (int l=0; l<iLookups; l++) {
	  out.write("      <TR>\n");
	  out.write("<TD><INPUT TYPE=\"checkbox\" NAME=\"chk"+String.valueOf(l)+"\"></TD>");	  
	  out.write("<TD align=\"right\" CLASS=\"textplain\">"+String.valueOf(l+1)+"&nbsp;<INPUT TYPE=\"hidden\" NAME=\"pg_lookup"+String.valueOf(l)+"\" VALUE=\""+String.valueOf(oLookups.getInt(0,l))+"\"></TD>");
	  out.write("<TD CLASS=\"strip"+String.valueOf((l%2)+1)+"\"><INPUT TYPE=\"text\" NAME=\"vl_lookup"+String.valueOf(l)+"\" CLASS=\"combomini\" VALUE=\""+oLookups.getStringNull(1,l,"")+"\" STYLE=\"background:lightgray\" onkeypress=\"return false;\"></TD>");
	  for (int c=2; c<iListLen; c++) {
	    out.write("<TD CLASS=\"strip"+String.valueOf((l%2)+1)+"\"><INPUT TYPE=\"text\" NAME=\""+aColList[c]+String.valueOf(l)+"\" MAXLENGTH=\""+sMaxTrLen+"\" CLASS=\"combomini\" VALUE=\""+oLookups.getStringNull(c,l,"")+"\" onkeypress=\"return hasTarget();\"></TD>");
	  }
	  out.write("      </TR>\n");
	}
	for (int r=0; r<iRows; r++) {
	  out.write("      <TR>\n");
	  out.write("<TD></TD>");	  
	  out.write("<TD align=\"right\" CLASS=\"textplain\">"+String.valueOf(r+1+iLookups)+"&nbsp;</TD>");	  
	  out.write("<TD CLASS=\"strip"+String.valueOf((r%2)+1)+"\"><INPUT TYPE=\"text\" NAME=\"vl_lookup"+String.valueOf(r+iLookups)+"\" MAXLENGTH=\""+sMaxVlLen+"\" CLASS=\"combomini\" STYLE=\"text-transform:uppercase\" onkeypress=\"return hasTarget();\"></TD>");
	  for (int c=2; c<iListLen; c++) {
	    out.write("<TD CLASS=\"strip"+String.valueOf((r%2)+1)+"\"><INPUT TYPE=\"text\" NAME=\""+aColList[c]+String.valueOf(r+iLookups)+"\" MAXLENGTH=\""+sMaxTrLen+"\" CLASS=\"combomini\" onkeypress=\"return hasTarget();\"></TD>");
	  }
	  out.write("      </TR>\n");
	}
%>
    </TABLE>
  </FORM>
</HTML> 