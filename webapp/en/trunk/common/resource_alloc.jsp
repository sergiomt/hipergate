<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.projtrack.Project,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

  final Boolean oTrue = new Boolean(true);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);

  String id_domain = nullif(request.getParameter("id_domain"),getCookie(request,"domainid",""));
  String gu_workarea = nullif(request.getParameter("gu_workarea"),getCookie(request,"workarea",""));
    
  JDCConnection oConn = null;
  DBSubset oRooms = new DBSubset(DB.k_rooms+" r,"+DB.k_rooms_lookup+" l",
  				 "l."+DB.tr_+sLanguage+",r."+DB.nm_room,
  				 "r."+DB.tp_room+"=l."+DB.vl_lookup+" AND "+DB.id_section+"='"+DB.tp_room+"' AND "+DB.gu_owner+"=?", 10);
  int iRooms = 0;

  StringBuffer oPrjSelect = new StringBuffer();
  DBSubset oPrjRoots = new DBSubset (DB.k_projects, DB.gu_project + "," + DB.nm_project + "," + DB.id_parent,
  				     DB.gu_owner + "=? AND " + DB.id_parent + " IS NULL ORDER BY 2", 10);
  DBSubset oPrjChlds = null;

  StringBuffer oCatSelect = new StringBuffer();
  DBSubset oRootCat = new DBSubset (DB.k_shops, DB.gu_root_cat+","+DB.gu_shop, DB.gu_workarea+"=? AND "+DB.bo_active+"=1", 1);
  DBSubset oCatChlds = new DBSubset (DB.k_cat_expand + " e," + DB.k_categories + " c",
                                     "e." + DB.gu_category + ",c." + DB.nm_category + ",e." + DB.od_level + ",e." + DB.od_walk + ",e." + DB.gu_parent_cat,
    				     "e." + DB.gu_category + "=c." + DB.gu_category + " AND e." + DB.gu_rootcat + "=? AND e." + DB.gu_category + "<>? ORDER BY e." + DB.od_walk, 50);
  int iCatChlds = 0;

  try {
    
    oConn = GlobalDBBind.getConnection("resource_book");  
    
    iRooms = oRooms.load(oConn, new Object[]{gu_workarea});

    int iPrjRoot = oPrjRoots.load(oConn, new Object[]{gu_workarea});
    HashMap oPrjChilds = new HashMap(31);
    int iPrjChlds = 0;
    Project oChl = new Project();

    for (int r=0; r<iPrjRoot; r++) {    		        
      oChl.replace(DB.gu_project, oPrjRoots.getString(0,r));	        
      oPrjChlds = oChl.getAllChilds(oConn);
      iPrjChlds = oPrjChlds.getRowCount();    		        
      oPrjSelect.append("<OPTION VALUE=\"" + oPrjRoots.getString(0,r) + "\">" + oPrjRoots.getString(1,r) + "</OPTION>");
      for (int p=0;p<iPrjChlds; p++) {
        if (oPrjChlds.getInt(2,p)>1) {
	  if (oPrjChilds.containsKey(oPrjChlds.getString(4,p)))
	    oPrjChilds.put(oPrjChlds.getString(0,p), oTrue);		    
	  else {
	    oPrjSelect.append("<OPTION VALUE=\"" + oPrjChlds.getString(0,p) + "\">");
	    for (int s=1;s<oPrjChlds.getInt(2,p); s++) out.write("&nbsp;&nbsp;&nbsp;&nbsp;");
	      oPrjSelect.append(oPrjChlds.getString(1,p));                            
	    oPrjSelect.append("</OPTION>");
          } // fi (oPrjChilds.containskey(id_parent))
        } // fi (od_level>1)
      } // next (p)
    } // next (r)
    oPrjSelect.append("\n");
    oPrjChilds = null;

    oRootCat.load(oConn, new Object[]{gu_workarea});

    if (oRootCat.getRowCount()>0) {
      iCatChlds = oCatChlds.load(oConn, new Object[]{oRootCat.getString(0,0),oRootCat.getString(0,0)});

      Category oCurrentCat = new Category ();
        		        
      oCatSelect.append ("<OPTION VALUE=\"" + oRootCat.getString(0,0) + "\">RAIZ</OPTION>");

      for (int p=0; p<iCatChlds; p++) {
        if (oCatChlds.getInt(2,p)>1) {
          oCurrentCat.replace (DB.gu_category, oCatChlds.getString(0,p));		    
          oCatSelect.append ("<OPTION VALUE=\"" + oCatChlds.getString(0,p) + "\">");
          for (int s=1; s<oCatChlds.getInt(2,p); s++) out.write("&nbsp;&nbsp;&nbsp;&nbsp;");
          oCatSelect.append (nullif(oCurrentCat.getLabel(oConn, sLanguage), oCatChlds.getString(1,p)));                            
          oCatSelect.append ("</OPTION>");
        } // fi (od_level>1)
      } // next (p)
    }
    
    oConn.close("resource_book");    
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("resource_book");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  if (null==oConn) return;
  oConn=null;
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Gestión de Peticiones</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      // 07. Pop up for showing calendar.

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

      // 08. Generic pop up for lookup values.
              
      function lookup(odctrl) {
	var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_table_lookup&id_language=" + getUserLanguage() + "&id_section=tx_field&tp_control=2&nm_control=sel_field&nm_coding=tx_field", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
	    // window.open("...
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      // 09. Fields values validation.

      function validate() {
        var frm = window.document.forms[0];

	if (!check_email(frm.my_email.value)) {
	  alert ("Su dirección de e-mail no es válida");
	  return false;
	}
	
	if (frm.chk_type[0].checked) {
	  if (!isDate(frm.dt_from.value, "d") || !isDate(frm.dt_to.value, "d")) {
	    alert ("La fecha para la reserva no es válida");
	    return false;	  
	  }

	  if (frm.dt_from.value==frm.dt_to.value) {  
	    if (parseInt(getCombo(frm.sel_h_start),10)*100+parseInt(getCombo(frm.sel_m_start),10)>=parseInt(getCombo(frm.sel_h_end),10)*100+parseInt(getCombo(frm.sel_m_end),10)) {
	      alert ("End time must be later than start time");
	      return false;	  
	    }
	  }	  
	  frm.ts_start.value = frm.dt_from.value + " " + getCombo(frm.sel_h_start) + ":" + getCombo(frm.sel_m_start) + ":00";
	  frm.ts_end.value = frm.dt_to.value + " " + getCombo(frm.sel_h_end) + ":" + getCombo(frm.sel_m_end) + ":00";

        }
	
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function showResources() {
	document.getElementById("div_rooms").style.display = "block";
	document.getElementById("div_projects").style.display = "none";
	document.getElementById("div_categories").style.display = "none";
	document.getElementById("div_other").style.display = "none";
      }

      function showProjects() {
	document.getElementById("div_rooms").style.display = "none";
	document.getElementById("div_projects").style.display = "block";
	document.getElementById("div_categories").style.display = "none";
	document.getElementById("div_other").style.display = "none";
      }

      function showCategories() {
	document.getElementById("div_rooms").style.display = "none";
	document.getElementById("div_projects").style.display = "none";
	document.getElementById("div_categories").style.display = "block";
	document.getElementById("div_other").style.display = "none";
      }

      function showProducts() {        
        var frm = document.forms[0];
	var cid = frm.sel_categories.options[frm.sel_categories.options.selectedIndex].value;
	clearCombo (frm.sel_products);
	loadCombo("select_xml.jsp", "sel_products", 0, null, cid, "v_prod_cat", "gu_product", "nm_product", null, "2", 0, 1000);
      }

      function showOther() {
	document.getElementById("div_rooms").style.display = "none";
	document.getElementById("div_projects").style.display = "none";
	document.getElementById("div_categories").style.display = "none";
	document.getElementById("div_other").style.display = "block";
      }

    //-->
  </SCRIPT> 
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/bridgestonebig.gif" HEIGHT="36" WIDTH="229" BORDER="0"></TD></TR>
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Reserva de Recursos y Peticiones</FONT></TD></TR>
  </TABLE>  
  <FORM ENCTYPE="multipart/form-data" METHOD="post" ACTION="resource_alloc_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_shop" VALUE="<%=oRootCat.getString(1,0)%>">
    <INPUT TYPE="hidden" NAME="ts_start">
    <INPUT TYPE="hidden" NAME="ts_end">

    <TABLE WIDTH="600px" CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD>
              <TABLE BORDER="0">
                <TR>
                  <TD></TD>
	          <TD CLASS="formstrong">e-mail&nbsp;<INPUT TYPE="text" NAME="my_email" MAXLENGTH="200" SIZE="50" STYLE="text-transform:lowercase" VALUE="administrator@hipergate-test.com"></TD>
	        </TR>
                <TR>
                  <TD><INPUT TYPE="radio" NAME="chk_type" VALUE="Room" onclick="showResources()"></TD><TD CLASS="formstrong">Reserva de Recursos</TD>
                </TR>
                <TR>
                  <TD><INPUT TYPE="radio" NAME="chk_type" VALUE="Incident" onclick="showProjects()"></TD><TD CLASS="formstrong">Solicitud de Soporte Técnico</TD>
                </TR>
                <TR>
                  <TD><INPUT TYPE="radio" NAME="chk_type" VALUE="Product" onclick="showCategories()"></TD><TD CLASS="formstrong">Petición de Material</TD>
                </TR>
                <TR>
                  <TD><INPUT TYPE="radio" NAME="chk_type" VALUE="Other" onclick="showOther()"></TD><TD CLASS="formstrong">Otro</TD>
                </TR>
              </TABLE>

	      <DIV ID="div_rooms" STYLE="display:none">
	      <TABLE BORDER="0">
	        <TR>
	          <TD CLASS="formstrong">Asunto</TD>
	          <TD ALIGN="left"><INPUT TYPE="text" NAME="tx_meeting" MAXLENGTH="100" SIZE="50"></TD>
	        </TR>
	        <TR>
	          <TD>
                    <SELECT NAME="tp_meeting"><OPTION VALUE=""></OPTION><OPTION VALUE="meeting">Reunión</OPTION><OPTION VALUE="breakfast">Desayuno<OPTION VALUE="lunch">Comida</OPTION><OPTION VALUE="course">Curso</OPTION><OPTION VALUE="demo">Demo</OPTION><OPTION VALUE="workshop">Jornada</OPTION></SELECT>
	          </TD>
	          <TD ALIGN="left">
 	            <SELECT NAME="sel_rooms">
                    <% String sTp = "nil value";
                       for (int r=0; r<iRooms; r++) {
		         if (!sTp.equals(oRooms.getStringNull(0,r,"nil value"))) {
		           sTp = oRooms.getStringNull(0,r,"nil value");
		             out.write("<OPTGROUP LABEL=\""+oRooms.getStringNull(0,r,"")+"\">");
		          }
		       out.write("<OPTION VALUE=\""+oRooms.getString(1,r)+"\">"+oRooms.getString(1,r)+"</OPTION>");
                       }
                    %>
	            </SELECT>
	          </TD>
	        </TR>
		<TR>
		  <TD CLASS="formstrong">Desde</TD>
		  <TD CLASS="formstrong" ALIGN="left">
		    <INPUT TYPE="text" NAME="dt_from" MAXLENGTH="10" SIZE="10">
                    <A HREF="javascript:showCalendar('dt_from')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Ver Calendario"></A>
                    &nbsp;<SELECT NAME="sel_h_start"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
                    &nbsp;<SELECT NAME="sel_m_start"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>
	            &nbsp;&nbsp;hasta&nbsp;<INPUT TYPE="text" NAME="dt_to" MAXLENGTH="10" SIZE="10">
                    <A HREF="javascript:showCalendar('dt_to')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Ver Calendario"></A>
                    <SELECT NAME="sel_h_end"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
                    <SELECT NAME="sel_m_end"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>	      
	          </TD>
	        </TR>
	      </TABLE>
	      </DIV>

	      <DIV ID="div_projects" STYLE="display:none">
              <TABLE BORDER="0">
	        <TR>
	          <TD CLASS="formstrong">Categor&iacute;a</TD>
                  <TD ALIGN="left" WIDTH="100%"><SELECT NAME="sel_projects"><%=oPrjSelect.toString()%></SELECT>
	        </TR>
	        <TR>
	          <TD CLASS="formstrong">Asunto</TD>
	          <TD ALIGN="left"><INPUT TYPE="text" NAME="tl_bug" MAXLENGTH="100" SIZE="50"></TD>
	        </TR>
	        <TR>
	          <TD CLASS="formstrong">Descripci&oacute;n</TD>
	          <TD><TEXTAREA NAME="tx_brief" ROWS="7" COLS="60" CLASS="textsmall"></TEXTAREA></TD>
	        </TR>
	        <TR>
	          <TD CLASS="formstrong">Archivo</TD>
	          <TD><INPUT TYPE="file" SIZE="40" NAME="attachment"></TD>
	        </TR>
	      </TABLE>
	      </DIV>

	      <DIV ID="div_categories" STYLE="display:none">
              <TABLE BORDER="0">
	        <TR>
	          <TD CLASS="formstrong">Categor&iacute;a</TD>
                  <TD ALIGN="left" WIDTH="100%"><SELECT NAME="sel_categories" onchange="showProducts()"><%=oCatSelect.toString()%></SELECT></TD>
		</TR>
	        <TR>
	          <TD CLASS="formstrong">&Iacute;tem</TD>
                  <TD ALIGN="left" WIDTH="100%"><SELECT NAME="sel_products"></SELECT></TD>
		</TR>
	        <TR>
	          <TD CLASS="formstrong">Cantidad</TD>
                  <TD ALIGN="left" WIDTH="100%"><SELECT NAME="sel_quantity"><% for (int q=1; q<=99; q++) out.write("<OPTION VALUE=\""+String.valueOf(q)+"\">"+String.valueOf(q)+"</OPTION>"); %></SELECT></TD>
		</TR>
	      </TABLE>
	      </DIV>

	      <DIV ID="div_other" STYLE="display:none">
              <TABLE BORDER="0">
	        <TR>
	          <TD CLASS="formstrong">Asunto</TD>
	          <TD><INPUT NAME="tx_subject" STYLE="width:468px"></TD>
	        </TR>
	        <TR>
	          <TD CLASS="formstrong">Texto</TD>
	          <TD><TEXTAREA NAME="tx_body" ROWS="7" STYLE="width:468px" CLASS="textsmall"></TEXTAREA></TD>
	        </TR>
	      </TABLE>
	      </DIV>

            </TD>
          </TR>          
          <!-- 14. Date Field -->
          <TR>
            <TD><HR></TD>
          </TR>
          <TR>
    	    <TD ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Enviar" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancelar" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
