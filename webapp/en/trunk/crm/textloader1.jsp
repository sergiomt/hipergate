<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
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
    
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  boolean bLatinLanguage = (sLanguage.startsWith("es") || sLanguage.startsWith("en") || sLanguage.startsWith("fr") || sLanguage.startsWith("de") || sLanguage.startsWith("pt") || sLanguage.startsWith("nl") || sLanguage.startsWith("pl"));
  boolean bChineseTraditional = sLanguage.startsWith("tw");
  boolean bChineseSimplified = sLanguage.startsWith("cn");
  boolean bRussianLanguage = sLanguage.startsWith("ru");

  JDCConnection oConn = null;
  DBSubset oLists = new DBSubset(DB.k_lists, DB.gu_list+","+DB.de_list+","+DB.dt_created,
  													     DB.gu_workarea+"=? AND ("+DB.tp_list+"=? OR "+DB.tp_list+"=?) AND "+DB.de_list+" IS NOT NULL ORDER BY 2", 100);
  int nLists = 0;

  try {
    oConn = GlobalDBBind.getConnection("textloader1");

    nLists = oLists.load(oConn, new Object[]{getCookie(request,"workarea",""), new Short(DistributionList.TYPE_STATIC), new Short(DistributionList.TYPE_DIRECT)});
  
    oConn.close("textloader1");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("textloader1");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;    
  oConn = null;
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Contact Loader</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      function showLists(a) {
        var frm = window.document.forms[0];

      	if (a=="APPEND") {
					document.getElementById("add_list_label").style.display="block";
					document.getElementById("add_list_text").style.display="block";
					frm.sel_list.style.display="block";
      	} else {
					document.getElementById("add_list_label").style.display="none";
					document.getElementById("add_list_text").style.display="none";
					document.getElementById("new_list_label").style.display="none";
					document.getElementById("new_list_text").style.display="none";
					frm.sel_list.style.display="none";
					frm.sel_list.selectedIndex=0;
					frm.de_list.value="";
      	}
      } // showLists

      function nameList(v) {
        var frm = window.document.forms[0];
			  if (v.length==0) {
					frm.de_list.value = "";
					document.getElementById("new_list_label").style.display="none";
					document.getElementById("new_list_text").style.display="none";
			  } else if (v=="*new*") {
			  	frm.de_list.value = "";
					document.getElementById("new_list_label").style.display="block";
					document.getElementById("new_list_text").style.display="block";
			  } else {
					frm.de_list.value = getComboText(frm.sel_list);
					document.getElementById("new_list_label").style.display="none";
					document.getElementById("new_list_text").style.display="none";			  
			  }
      } // nameList

      function validate() {
        var frm = window.document.forms[0];

				if (getCombo(frm.sel_list)=="*new*") {
					if (frm.de_list.value.length==0) {
	          alert ("A name for the new list is required");
	          frm.de_list.focus();
	          return false;
				  } else {
				    for (var l=1; l<frm.sel_list.options.length; l++) {
				      if (frm.sel_list.options[l].text==frm.de_list.value) {
	              alert ("Another list with the same name already exists");
	              frm.de_list.focus();
	              return false;
				      }
				    } // next
				    if (hasForbiddenChars(frm.de_list.value)) {
	            alert ("List Name contains invalid characters");
	            frm.de_list.focus();
	            return false;
				    }
				  } // fi 
				} // fi

	      if (getCombo(frm.sel_action)!="APPEND" && frm.sel_list.selectedIndex>0) {
	        alert ("It is only allowed to add contacts to a list by using Insert Action");
	        return false;
	      }

	      if (frm.textfile.value.length==0) {
	        alert ("Select file to be loaded");
	        return false;
	      }

        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Contact Loader</FONT></TD></TR>
  </TABLE>  
  <FORM ENCTYPE="multipart/form-data" METHOD="post" ACTION="textloader2.jsp" onSubmit="return validate()">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Contact Type</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_type"><OPTION VALUE="CONTACTS" SELECTED>Individual</OPTION><OPTION VALUE="COMPANIES">Company</OPTION><OPTION VALUE="OPORTUNITIES">Opportunity</OPTION></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Action</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_action" onchange="showLists(this.options[this.selectedIndex].value)"><OPTION VALUE="APPEND" SELECTED="selected">Insert</OPTION><OPTION VALUE="UPDATE">Refresh</OPTION><OPTION VALUE="APPENDUPDATE">Insert and Update</OPTION></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Column Delimiter</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_delim"><OPTION VALUE="TAB" SELECTED>Tab</OPTION><OPTION VALUE=";">;</OPTION><OPTION VALUE=",">,</OPTION><OPTION VALUE="|">|</OPTION><OPTION VALUE="S">Space</OPTION></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Decimal Delimiter</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="sel_decimal"><OPTION VALUE="." SELECTED>.</OPTION><OPTION VALUE=",">,</OPTION></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Character set </FONT></TD>
            <TD ALIGN="left">
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
            <TD ALIGN="right"><FONT CLASS="formstrong">File</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="FILE" NAME="textfile" SIZE="30"></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><INPUT TYPE="CHECKBOX" NAME="colnames" VALUE="1"></TD>
            <TD ALIGN="left"><FONT CLASS="formplain">The first row contains column names</FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain"><DIV ID="add_list_label">Add to List</DIV></TD>
            <TD ALIGN="left"><DIV ID="add_list_text"><SELECT NAME="sel_list" onchange="nameList(this.options[this.selectedIndex].value)"><OPTION VALUE="" SELECTED="selected"></OPTION><OPTION VALUE="*new*">Add to a new list</OPTION><OPTGROUP LABEL="Already existing lists"><% for (int l=0;l<nLists; l++) out.write("<OPTION VALUE=\""+oLists.getString(0,l)+"\">"+oLists.getString(1,l)+"</OPTION>"); %></OPTGROUP></SELECT></DIV>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain"><DIV ID="new_list_label" STYLE="display:none">List Name</DIV></TD>
            <TD ALIGN="left">
              <DIV ID="new_list_text" STYLE="display:none"><INPUT TYPE="text" NAME="de_list" SIZE="40" MAXLENGTH="50" /></DIV>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><A HREF="#" CLASS="linkplain" onclick="document.getElementById('advanced').style.display='block'">Opciones Avanzadas</A></TD>
	          <TD></TD>
          </TR>
          <TR>
            <TD></TD>
            <TD>
              <DIV ID="advanced" STYLE="display:none">
                <INPUT TYPE="TEXT" NAME="maxerrors" SIZE="4" VALUE="100" onkeypress="acceptOnlyNumbers(this)">&nbsp;<FONT CLASS="formplain">More Errors</FONT>
                <BR>
                <INPUT TYPE="CHECKBOX" NAME="loadlookups" VALUE="INSERTLOOKUPS" CHECKED>&nbsp;<FONT CLASS="formplain">Autoload lookup tables</FONT>
                <BR>
                <INPUT TYPE="CHECKBOX" NAME="recoverable" VALUE="RECOVERABLE">&nbsp;<FONT CLASS="formplain">Execute in a single transaction</FONT>
                <BR>
                <INPUT TYPE="CHECKBOX" NAME="allcaps" VALUE="ALLCAPS">&nbsp;<FONT CLASS="formplain">To Uppercase</FONT>
              </DIV>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Next" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
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
