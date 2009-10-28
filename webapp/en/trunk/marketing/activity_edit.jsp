<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.marketing.Activity,com.knowgate.marketing.ActivityAudience" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "activity_edit";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_activity = request.getParameter("gu_activity");

  String id_user = getCookie(request, "userid", "");
  
  Activity oActy = new Activity();
  
  DBSubset oCnts = new DBSubset(DB.k_x_activity_audience, "COUNT(*),"+DB.bo_confirmed, DB.gu_activity+"=? GROUP BY 2", 10);
  DBSubset oCamp = new DBSubset(DB.k_campaigns, DB.gu_campaign+","+DB.nm_campaign+","+DB.dt_created,
  														  DB.gu_workarea+"=? AND "+DB.bo_active+"<>0 ORDER BY 3 DESC", 100);
  int iCamp = 0;
  int iConf = -1;
  
  String sDeptLookUp = "";

  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

		iCamp = oCamp.load(oConn, new Object[]{gu_workarea});
		
    sDeptLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_activity_audience_lookup", gu_workarea, "tx_dept", sLanguage);

    if (null!=gu_activity) {
      oActy.load(oConn, new Object[]{gu_activity});
      oCnts.load(oConn, new Object[]{gu_activity});
    }

    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%= gu_activity==null ? "[~Nueva Actividad~]" : "[~Editar Actividad~]" %></TITLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
	      var frm = window.document.forms[0];
       
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_activity_audience_lookup&id_language=" + getUserLanguage() + "&id_section=tx_dept&tp_control=2&nm_control=sel_dept&nm_coding=tx_dept", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------
      
      function validate() {
        var frm = document.forms[0];
        
        if (frm.tl_activity.value.length==0) {
          alert ("[~El título de la actividad es obligatorio~]");
          frm.tl_activity.focus();
          return false;
        } 

        if (frm.nu_capacity.value.length>0) {
        	if (isIntValue(frm.nu_capacity.value)) {
            if (parseInt(frm.nu_capacity.value)<0) {
              alert ("[~El aforo no es una cantidad entera válida~]");
              frm.nu_capacity.focus();
              return false;
            }
        	} else {
            alert ("[~El aforo no es una cantidad entera válida~]");
            frm.nu_capacity.focus();
            return false;
          }
        }

        if (frm.pr_sale.value.length>0) {
        	if (isFloatValue(frm.pr_sale.value)) {
            if (parseFloat(frm.pr_sale.value)<0) {
              alert ("[~El precio de venta no es una cantidad entera válida~]");
              frm.pr_sale.focus();
              return false;
            }
        	} else {
            alert ("[~El precio de venta no es una cantidad entera válida~]");
            frm.pr_sale.focus();
            return false;
          }
        }

        if (frm.pr_discount.value.length>0) {
        	if (isFloatValue(frm.pr_discount.value)) {
            if (parseFloat(frm.pr_discount.value)<0) {
              alert ("[~El precio con descuento no es una cantidad entera válida~]");
              frm.pr_discount.focus();
              return false;
            }
        	} else {
            alert ("[~El precio con descuento no es una cantidad entera válida~]");
            frm.pr_discount.focus();
            return false;
          }
        }

        if (frm.dt_start.value.length>0 && !isDate(frm.dt_start.value)) {
          alert ("[~La fecha de inicio no es válida~]");
          frm.dt_start.focus();
          return false;
        } 

        if (frm.dt_end.value.length>0 && !isDate(frm.dt_end.value)) {
          alert ("[~La fecha de fin no es válida~]");
          frm.dt_end.focus();
          return false;
        } 

        if (frm.dt_start.value.length>0 && frm.dt_end.value.length>0) {
          if (parseDate(frm.dt_start.value, "d")>parseDate(frm.dt_end.value, "d")) {
            alert ("[~La fecha de inicio es posterior a la fecha de fin~]");
            return false;
          }
        } 

        if (frm.de_activity.value.length>1000) {
          alert ("[~La descripción de la actividad puede superar los 1000 caracteres~]");
          frm.de_activity.focus();
          return false;
        } 

        if (frm.tx_comments.value.length>254) {
          alert ("[~Los comentarios no pueden superar los 254 caracteres~]");
          frm.tx_comments.focus();
          return false;
        } 

				frm.tx_dept.value = getCombo(sel_dept);

        return true;
      } // validate;

      // ------------------------------------------------------

      function setCombos() {
        var frm = document.forms[0];
				setCombo(frm.sel_dept, "<%=oActy.getStringNull(DB.tx_dept,"")%>"); 
				setCombo(frm.gu_campaign, "<%=oActy.getStringNull(DB.gu_campaign,"")%>"); 
      }    

    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="[~Atras~]"> [~Atras~]</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="[~Actualizar~]"> [~Actualizar~]</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="[~Imprimir~]"> [~Imprimir~]</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%" SUMMARY="Title">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1"><%= gu_activity==null ? "[~Nueva Actividad~]" : "[~Editar Actividad~]" %></FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="activity_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_activity" VALUE="<%=oActy.getStringNull("gu_activity","")%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">[~T&iacute;tulo~]</FONT></TD>
            <TD ALIGN="left" WIDTH="330"><INPUT TYPE="text" NAME="tl_activity" MAXLENGTH="100" SIZE="40" VALUE="<%=oActy.getStringNull(DB.tl_activity,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formplain">[~Referencia~]</FONT></TD>
            <TD ALIGN="left" WIDTH="330"><INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="20" VALUE="<%=oActy.getStringNull(DB.id_ref,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formplain">[~Campa&ntilde;a~]</FONT></TD>
            <TD ALIGN="left" WIDTH="330">
              <INPUT TYPE="hidden" NAME="tx_dept">
              <SELECT NAME="gu_campaign"><OPTION VALUE=""></OPTION><% for (int c=0; c<iCamp; c++) out.write("<OPTION VALUE=\""+oCamp.getString(0,c)+"\">"+oCamp.getString(1,c)+"</OPTION>"); %></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formplain">[~Departamento~]</FONT></TD>
            <TD ALIGN="left" WIDTH="330">
              <INPUT TYPE="hidden" NAME="tx_dept">
              <SELECT NAME="sel_dept"><OPTION VALUE=""></OPTION><%=sDeptLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="[~Lista de Departamentos~]"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="130" CLASS="formplain">[~Aforo~]</TD>
            <TD ALIGN="left" WIDTH="330" CLASS="textsmall">
            	<INPUT TYPE="text" NAME="nu_capacity" MAXLENGTH="9" SIZE="4" VALUE="<% if (!oActy.isNull(DB.nu_capacity)) out.write(String.valueOf(oActy.getInt(DB.nu_capacity))); %>" onkeypress="return acceptOnlyNumbers();">
            	<% if (oCnts.sum(0)!=null) { %> &nbsp;[~Invitados~]&nbsp;<%=oCnts.sum(0)%>&nbsp;&nbsp; <% } %>
            	<% iConf = oCnts.find(1, new Short(ActivityAudience.CONFIRMED)); if (iConf>=0) out.write("&nbsp;[~Confirmados~]&nbsp;"+String.valueOf(oCnts.getInt(0,iConf))); %>&nbsp;&nbsp;
            	<% iConf = oCnts.find(1, new Short(ActivityAudience.REFUSED)); if (iConf>=0) out.write("&nbsp;[~No asistirán~]&nbsp;"+String.valueOf(oCnts.getInt(0,iConf))); %>
            </TD>
				
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="130" CLASS="formplain">[~Precio Est&aacute;ndar~]</TD>
            <TD ALIGN="left" WIDTH="330" CLASS="formplain"><INPUT TYPE="text" NAME="pr_sale" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oActy.isNull(DB.pr_sale)) out.write(String.valueOf(oActy.getDecimal(DB.pr_sale))); %>">
            &nbsp;&nbsp;&nbsp;&nbsp;[~Precio Descuento~]&nbsp;<INPUT TYPE="text" NAME="pr_discount" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oActy.isNull(DB.pr_discount)) out.write(String.valueOf(oActy.getDecimal(DB.pr_discount))); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="130" CLASS="formplain">[~Fecha inicio~]</TD>
            <TD ALIGN="left" WIDTH="330" CLASS="formplain">
              <INPUT TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oActy.isNull("dt_start") ? "" : oActy.getDateFormated("dt_start","yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Ver Calendario~]"></A>
							&nbsp;&nbsp;&nbsp;&nbsp;[~Fecha fin~]&nbsp;
              <INPUT TYPE="text" NAME="dt_end" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oActy.isNull("dt_end") ? "" : oActy.getDateFormated("dt_end","yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Ver Calendario~]"></A>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">[~Descripci&oacute;n~]</FONT></TD>
            <TD ALIGN="left" WIDTH="330"><TEXTAREA NAME="de_activity" COLS="36"><%=oActy.getStringNull("de_activity","")%></TEXTAREA></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="130"><FONT CLASS="formstrong">[~Comentarios~]</FONT></TD>
            <TD ALIGN="left" WIDTH="330"><TEXTAREA NAME="tx_comments" COLS="36"><%=oActy.getStringNull("tx_comments","")%></TEXTAREA></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="[~Guardar~]" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="[~Cancelar~]" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
