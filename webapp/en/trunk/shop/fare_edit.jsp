<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2007  Know Gate S.L. All rights reserved.
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
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_product = request.getParameter("gu_product");
  String id_fare = request.getParameter("id_fare");
  
  Product oProd = new Product();
  ProductFare oFare = new ProductFare();
  DBSubset oFares = null;
  int nFares = 0;  
  String sFaresLookUp = "", sTypesLookUp = "";
    
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection("fare_edit");  
    
    sFaresLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_prod_fares_lookup", gu_workarea, "id_fare", sLanguage);
    sTypesLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_prod_fares_lookup", gu_workarea, "tp_fare", sLanguage);

	  if (id_fare!=null) oFare.load(oConn, new Object[]{gu_product,id_fare});

    oProd.load(oConn, new Object[]{gu_product});
    
    oFares = oProd.getFares(oConn);
    nFares = oFares.getRowCount();

    oConn.close("fare_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("fare_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }

  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Fares</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
		  var fares = new Array(<%=nFares>0 ? String.valueOf(nFares) : ""%>);
<%    for (int f=0; f<nFares; f++)
		    out.write("		  fares["+String.valueOf(f)+"]=\""+oFares.getString(0,f)+"\";\n");
%>
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
            window.open("../common/lookup_f.jsp?nm_table=k_prod_fares_lookup&id_language=" + getUserLanguage() + "&id_section=id_fare&tp_control=2&nm_control=sel_id_fare&nm_coding=id_fare", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_prod_fares_lookup&id_language=" + getUserLanguage() + "&id_section=tp_fare&tp_control=2&nm_control=sel_tp_fare&nm_coding=tp_fare", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      function reloadFare(id) {
	      var frm = window.document.forms[0];
        
        frm.sel_id_fare.selectedIndex = frm.sel_currency.selectedIndex = frm.sel_tp_fare.selectedIndex = 0;
        frm.pr_sale.value = frm.pct_tax_rate.value = frm.dt_start.value = frm.dt_end.value = "";
        frm.is_tax_included.checked = false;

        if (id.length!=0) {
          var e = false;
          for (var f=0; f<<%=nFares%> && !e; f++) e = (fares[f]==id);
          if (e) document.location = "fare_edit.jsp?gu_workarea="+frm.gu_owner.value+"&gu_product="+frm.gu_product.value+"&id_fare="+escape(id);
        }
      } // reloadFare
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	      if (!isDate(frm.dt_start.value, "d") && frm.dt_start.value.length>0) {
	        alert ("Start date is not valid");
	        return false;
	      }

	      if (!isDate(frm.dt_end.value, "d") && frm.dt_end.value.length>0) {
	        alert ("End date is not valid");
	        return false;
	      }

			  if (frm.dt_start.value.length>0 && frm.dt_end.value.length>0) {
			  	if (parseDate(frm.dt_start.value,"d")>parseDate(frm.dt_end.value,"d")) {
	          alert ("End date must be later than start date");
	          return false;			    
			    }
			  }
			  
			  if (frm.sel_id_fare.selectedIndex<0) {
	        alert ("Fare name is required");
	        return false;
			  }

			  if (getCombo(frm.sel_id_fare)=="") {
	        alert ("Fare name is required");
	        return false;
			  }

		    if (hasForbiddenChars(getCombo(frm.sel_id_fare))) {
	        alert ("The fare name contains invalid characters");
	        return false;
		    }
		    
      	if (!isFloatValue(frm.pr_sale.value)) {
      	  alert ("Fare price is not valid ");
      	  return false;
      	}

      	if (frm.pct_tax_rate.value.length>0) {
      	  if (!isFloatValue(frm.pct_tax_rate.value)) {
      	    alert ("Tax rate percentage is not valid");
      	    return false;
      	  }
      	  if (parseFloat(frm.pct_tax_rate.value.replace(new RegExp(","), "."))>100) {
      	    alert ("Tax rate percentage is not valid");
      	    return false;
      	  }
      	}
        
        frm.id_fare.value = getCombo(frm.sel_id_fare);
        frm.tp_fare.value = getCombo(frm.sel_tp_fare);
        frm.id_currency.value = getCombo(frm.sel_currency);
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_id_fare,"<% out.write(oFare.getStringNull(DB.id_fare,"")); %>");
        setCombo(frm.sel_tp_fare,"<% out.write(oFare.getStringNull(DB.tp_fare,"")); %>");
        setCombo(frm.sel_currency,"<% out.write(oFare.getStringNull(DB.id_currency,"")); %>");
        
        return true;
      } // validate;
    //-->
  </SCRIPT> 
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:230px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Fare</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="fare_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_owner" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_product" VALUE="<%=gu_product%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Product:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><FONT CLASS="formplain"><%=oProd.getStringNull(DB.nm_product,"")%></FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="hidden" NAME="id_fare" VALUE="<%=nullif(id_fare)%>">
            <SELECT NAME="sel_id_fare" onchange="reloadFare(this.options[this.selectedIndex].value)"><OPTION VALUE=""></OPTION><%=sFaresLookUp%></SELECT>&nbsp;
            <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Fares"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Type:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tp_fare">
              <SELECT NAME="sel_tp_fare"><OPTION VALUE=""></OPTION><%=sTypesLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Fare Types"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Price:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
            	<INPUT TYPE="text" NAME="pr_sale" MAXLENGTH="12" SIZE="9" VALUE="<% if (!oFare.isNull(DB.pr_sale)) out.write(String.valueOf(oFare.getFloat(DB.pr_sale))); %>">
              <INPUT TYPE="hidden" NAME="id_currency">
              <SELECT NAME="sel_currency" CLASS="combomini"><OPTION VALUE="999"></OPTION><OPTION VALUE="978" SELECTED>€</OPTION><OPTION VALUE="840">$</OPTION><OPTION VALUE="826">£</OPTION><OPTION VALUE="392">¥</OPTION></SELECT>              
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Tax %</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="pct_tax_rate" MAXLENGTH="5" SIZE="4"  VALUE="<% if (!oFare.isNull(DB.pct_tax_rate)) out.write(String.valueOf(oFare.getFloat(DB.pct_tax_rate))); %>"> 
              &nbsp;           
              <INPUT TYPE="checkbox" NAME="is_tax_included" VALUE="1" <% if (!oFare.isNull(DB.is_tax_included)) out.write(oFare.getShort(DB.is_tax_included)==0 ? "" : " CHECKED"); %>>
              <FONT CLASS="formplain">Taxes included at price</FONT>
            </TD>                            
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Start:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oFare.get(DB.dt_start)!=null ? oFare.getDateFormated(DB.dt_start,"yyyy-MM-dd") : ""); %>">
              <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">End:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_end" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oFare.get(DB.dt_end)!=null ? oFare.getDateFormated(DB.dt_end,"yyyy-MM-dd") : ""); %>">
              <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
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
