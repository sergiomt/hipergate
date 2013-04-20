<%@ page import="java.util.Date,java.util.HashMap,java.util.ListIterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.DBLanguages,com.knowgate.crm.Contact,com.knowgate.misc.Gadgets,com.knowgate.crm.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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
  
  final boolean ENABLE_ONGOING_CALLS_HANDLING = false;
  
  String sSkin = getCookie(request, "skin", "xp");

  final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String sLanguage = getNavigatorLanguage(request);
  Date dtNow = new Date();
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_user = request.getParameter("gu_user");
  String gu_oportunity = nullif(request.getParameter("gu_oportunity"));
  String gu_contact = nullif(request.getParameter("gu_contact"));
  String gu_campaign = nullif(request.getParameter("gu_campaign"));
  String nm_campaign = ""; 

  JDCConnection oConn = null;
  Contact oCont = new Contact();
  Oportunity oOprt = new Oportunity();
  HashMap oStatusLookUp = null;
  HashMap oLocationLookUp = null;
  String sLocationLookUp = "";
  String sStatusLookUp = "";
  String sTitleLookUp = "";
  String sUsersCombo = null;    
  String sIdPrevStatus = null;
  Short oLvInt = new Short((short)0);
  DBSubset oUsrs = null;
  DBSubset oOprs = new DBSubset (DB.k_oportunities, DB.gu_oportunity+","+DB.gu_contact,
  															 DB.gu_workarea+"=? AND "+DB.gu_campaign+"=? AND "+DB.id_status+"='PTE_LLAMAR' AND "+DB.gu_contact+" IS NOT NULL", 1);
  DBSubset oCmps = new DBSubset (DB.k_companies, DB.gu_company + "," + DB.nm_legal , DB.gu_company + "=? ORDER BY 2", 100);
  DBSubset oAdrs = new DBSubset (DB.k_addresses+" a,"+DB.k_x_contact_addr+" x",
  						                   "a."+DB.gu_address+",a."+DB.tp_location+",a."+DB.work_phone+",a."+DB.direct_phone+",a."+DB.home_phone+",a."+DB.mov_phone,
  						                   "a."+DB.gu_address+"=x."+DB.gu_address+" AND a."+DB.bo_active+"<>0 AND x."+DB.gu_contact+"=? AND "+
  						                   "(a."+DB.work_phone+" IS NOT NULL OR a."+DB.direct_phone+" IS NOT NULL OR a."+DB.home_phone+" IS NOT NULL OR a."+DB.mov_phone+" IS NOT NULL)", 10);
  int iCompanyCount = 0;
  int iUsrs = 0;
  int iAdrs = 0;

  try {

    oConn = GlobalDBBind.getConnection("phonecall_record");      

	  if ((gu_oportunity.length()==0 || gu_contact.length()==0) && gu_campaign.length()>0) {
	    oOprs.setMaxRows(1);
	    if (oOprs.load(oConn, new Object[]{gu_workarea,gu_campaign})>0) {
	      gu_oportunity = oOprs.getString(0,0);
	      gu_contact = oOprs.getString(1,0);
	  	  sIdPrevStatus = nullif(DBCommand.queryStr(oConn, "SELECT "+DB.id_status+" FROM "+DB.k_oportunities+" WHERE "+DB.gu_oportunity+"='"+gu_oportunity+"'"));
				
				if (ENABLE_ONGOING_CALLS_HANDLING) {
	        DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_oportunities+" SET "+DB.id_status+"='ENCURSO' WHERE "+DB.gu_oportunity+"='"+gu_oportunity+"' AND "+DB.gu_workarea+"='"+gu_workarea+"'");
	      }
	    } else {
        oConn.close("phonecall_record");
        if (com.knowgate.debug.DebugFile.trace) com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "", "");
        response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=No data found&desc=There are no pending calls&resume=_close"));
	    	return;
	    }
	    nm_campaign = nullif(DBCommand.queryStr(oConn, "SELECT "+DB.nm_campaign+" FROM "+DB.k_campaigns+" WHERE "+DB.gu_campaign+"='"+gu_campaign+"'"));
	  } else {
	  	oLvInt = DBCommand.queryShort(oConn, "SELECT "+DB.lv_interest+" FROM "+DB.k_oportunities+" WHERE "+DB.gu_oportunity+"='"+gu_oportunity+"'");
	  	if (null==oLvInt) oLvInt = new Short((short)0);
	  	sIdPrevStatus = nullif(DBCommand.queryStr(oConn, "SELECT "+DB.id_status+" FROM "+DB.k_oportunities+" WHERE "+DB.gu_oportunity+"='"+gu_oportunity+"'"));
		  if (ENABLE_ONGOING_CALLS_HANDLING) {
	      DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_oportunities+" SET "+DB.id_status+"='ENCURSO' WHERE "+DB.gu_oportunity+"='"+gu_oportunity+"' AND "+DB.gu_workarea+"='"+gu_workarea+"'");
	    }
	  }

    oCont.load(oConn, gu_contact);
	  oOprt.load(oConn, gu_oportunity);
    iAdrs = oAdrs.load(oConn, new Object[]{gu_contact});

    if (!oCont.isNull(DB.gu_company))
      iCompanyCount = oCmps.load (oConn, new Object[]{oCont.get(DB.gu_company)});

    oLocationLookUp = DBLanguages.getLookUpMap(oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_location, sLanguage);

		ListIterator oLocations = oAdrs.distinct(1).listIterator();
		while (oLocations.hasNext()) {
		  Object oLoc = oLocations.next();
		  sLocationLookUp += "<OPTION VALUE=\""+oLoc+"\">"+oLocationLookUp.get(oLoc)+"</OPTION>";
		}		 

    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_contacts_lookup, gu_workarea, "id_status", sLanguage);
    sTitleLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_contacts_lookup, gu_workarea, "de_title", sLanguage);    

    sUsersCombo = GlobalCacheClient.getString("["+gu_workarea+",users]");
      
    if (null==sUsersCombo) {
      oUsrs = new DBSubset(DB.k_users, DB.gu_user + "," + DBBind.Functions.ISNULL + "(" + DB.nm_user + "," + DB.tx_nickname + ") ," + DB.tx_surname1 + "," + DB.tx_surname2, DB.gu_workarea + "=? ORDER BY 2,3,4", 100);
      iUsrs = oUsrs.load(oConn, new Object[]{gu_workarea});      
    } // fi (null==sUsersCombo)

    oConn.close("phonecall_record");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("phonecall_record");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  

  if (null==sUsersCombo) {

    StringBuffer oStrBuff = new StringBuffer(100*iUsrs);

    for (int u=0; u<iUsrs; u++) {
      oStrBuff.append("<OPTION VALUE=\"" + oUsrs.getString(0,u) + "\">");
      oStrBuff.append(Gadgets.HTMLEncode(oUsrs.getStringNull(1,u,"")));
      if (!oUsrs.isNull(2,u)) oStrBuff.append (" " + Gadgets.HTMLEncode(oUsrs.getString(2,u)));
      if (!oUsrs.isNull(3,u)) oStrBuff.append (" " + Gadgets.HTMLEncode(oUsrs.getString(3,u)));
      oStrBuff.append("</OPTION>");
    } // next (u)
  
    sUsersCombo = oStrBuff.toString();
    
    GlobalCacheClient.put ("["+gu_workarea+",users]", sUsersCombo);

    oStrBuff = null;
  }
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: New Call</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

			var req;

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      // ------------------------------------------------------
              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            open("../common/lookup_f.jsp?nm_table=k_contacts_lookup&id_language=" + getUserLanguage() + "&id_section=de_title&tp_control=2&nm_control=sel_title&nm_coding=de_title", "lookuptitles", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            open("../common/lookup_f.jsp?nm_table=k_contacts_lookup&id_language=" + getUserLanguage() + "&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "lookupstatus", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()

      // ------------------------------------------------------
	
      function reference(odctrl) {
        var frm = document.forms[0];
        var c1,c2,c12;
        
        switch(parseInt(odctrl)) {
          case 1:
            if (frm.nm_company.value.indexOf("'")>=0)
              alert("El nombre de la compañía contiene caracteres no permitidos");
            else
              window.open("../common/reference.jsp?nm_table=k_companies&tp_control=1&nm_control=nm_legal AS nm_company&nm_coding=gu_company" + 
                          (frm.nm_company.value.length==0 || frm.gu_company.value.length==32 ? "" : "&where=" + escape(" <%=DB.nm_legal%> LIKE '"+frm.nm_company.value+"%' ")),
                          "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
            
        }
      } // reference()
	
	    // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        
	      if (frm.tx_comments.value.length>254) {
	        alert ("Comments may not exceed 254 characters");
	        return false;
	      }

	      if (frm.tx_comments.value.indexOf('"')>=0 || frm.tx_comments.value.indexOf("'")>=0) {
	        alert ("The comments contain invalid characters");
       	  return false;
	      }
	        
			  if (!isDate(frm.tx_start.value,"d")) {
	  	    alert ("The date for the call is not valid");
	        frm.tx_start.focus();
	        return false;
			  }	

	      frm.dt_start.value = frm.tx_start.value + " " + getCombo(frm.sel_h_start) + ":" + getCombo(frm.sel_m_start) + ":00";
	
        frm.gu_user.value = getCombo(frm.sel_users);
        
        frm.de_title.value = getCombo(frm.sel_title);

        frm.id_contact_status.value = getCombo(frm.sel_status);

        if (getCheckedValue(frm.telf)=="O") {
        	if (rtrim(frm.tx_other_phone.value).length<3) {
	  	      alert ("El número de contacto no es válido");
	          frm.tx_other_phone.focus();
	          return false;
	        } else {
	          frm.tx_phone.value = ltrim(rtrim(frm.tx_other_phone.value));
	        }
        }

<% if (iAdrs==1) { %>
	      if (frm.tx_phone.value.length==0)
	        frm.tx_phone.value="<%=oAdrs.getString(2,0)%>";
<% } %>

        if (frm.tx_phone.value.length==0) {
	  	    alert ("The number that was called is required");
	        return false;
	      }
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];

        setCombo (frm.sel_h_start,"<% out.write(Gadgets.leftPad(String.valueOf(dtNow.getHours()), '0', 2)); %>");
        setCombo (frm.sel_m_start,"<% out.write(Gadgets.leftPad(String.valueOf(dtNow.getMinutes()), '0', 2)); %>");
        setCombo (frm.sel_users,getURLParam("gu_user"));
        setCombo(frm.sel_status,"<%=oCont.getStringNull(DB.id_status,"")%>");
        setCombo(frm.sel_title,"<%=oCont.getStringNull(DB.de_title,"")%>");
        setCheckedValue(frm.lv_interest, <%=String.valueOf(oLvInt.shortValue())%>);

        return true;
      } // validate
    //-->
  </SCRIPT>    
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()" onUnLoad="<% if (sIdPrevStatus!=null && ENABLE_ONGOING_CALLS_HANDLING) { out.write("req=createXMLHttpRequest(); req.open('GET','phonecall_status_update.jsp?gu_oportunity="+gu_oportunity+"&id_status="+sIdPrevStatus+"',true); req.send(null);"); } %>">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">New Call</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="phonecall_record_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_oportunity" VALUE="<%=gu_oportunity%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=getCookie (request, "userid", null)%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<% out.write(gu_contact); %>">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=oCont.getStringNull(DB.gu_company,"")%>">
    <INPUT TYPE="hidden" NAME="tp_phonecall" VALUE="S">
    <INPUT TYPE="hidden" NAME="id_status" VALUE="1">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
<% if (nm_campaign.length()>0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Campaign</TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain"><%=nm_campaign%></TD>
	        </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Objective</TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain"><%=oOprt.getStringNull(DB.tl_oportunity,"")%></TD>
	        </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Date</FONT></TD>
            <TD ALIGN="left" WIDTH="470">
              <INPUT TYPE="hidden" NAME="dt_start">
              <INPUT TYPE="text" NAME="tx_start" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(DBBind.escape(dtNow, "shortDate")); %>">
              <A HREF="javascript:showCalendar('tx_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Ver Calendario"></A>
              <SELECT NAME="sel_h_start"><OPTION VALUE=""><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT NAME="sel_m_start"><OPTION VALUE=""><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="19">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="19">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="19">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="19">59</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">From</FONT></TD>
            <TD ALIGN="left" WIDTH="470">
	            <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=gu_user%>">
              <SELECT NAME="sel_users" STYLE="width:400px"><% out.write(sUsersCombo); %></SELECT>
	          </TD>
	        </TR>
          <TR>
            <TD VALIGN="top" ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">For</FONT></TD>
            <TD ALIGN="left" WIDTH="470">
              <INPUT TYPE="text" NAME="tx_name" SIZE="28" MAXLENGTH="200" VALUE="<%=oCont.getStringNull(DB.tx_name,"")%>">&nbsp;
	            <INPUT TYPE="text" NAME="tx_surname" SIZE="28" MAXLENGTH="200" VALUE="<%=oCont.getStringNull(DB.tx_surname,"")%>">
	          </TD>
	        </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Company:</TD>            
            <TD ALIGN="left" WIDTH="470">
              <INPUT TYPE="text" SIZE="50" NAME="nm_company" MAXLENGTH="70" VALUE="<% if (iCompanyCount>0) out.write(oCmps.getString(DB.nm_legal,0)); %>">
              &nbsp;&nbsp;<A HREF="javascript:reference(1)" TITLE="View companies listing"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View"></A>
              &nbsp;&nbsp;<A HREF="#" onclick="document.forms[0].gu_company.value=document.forms[0].nm_company.value=''" TITLE="Remove from company"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Position:</TD>
            <TD ALIGN="left" WIDTH="470">
              <SELECT CLASS="combomini" NAME="sel_title"><OPTION VALUE=""></OPTION><%=sTitleLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(1)" TITLE="Ver Lista de Empleos"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Ver"></A>
              <INPUT TYPE="hidden" NAME="de_title" VALUE="<%=oCont.getStringNull(DB.de_title,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110" CLASS="formplain">Status:</TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT CLASS="combomini" NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(2)" TITLE="Ver Lista de Estados"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Ver"></A>
              <INPUT TYPE="hidden" NAME="id_contact_status" VALUE="<%=oCont.getStringNull(DB.id_status,"")%>">              
            </TD>
          </TR>                              
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="90" CLASS="formstrong">Telephone</TD>
            <TD ALIGN="left" WIDTH="470" CLASS="formplain">
              <INPUT TYPE="hidden" NAME="tx_phone" VALUE="">
<%					  for (int a=0; a<iAdrs; a++) {
							  if (!oAdrs.isNull(2,a)) {
							    out.write("<INPUT TYPE=\"radio\" VALUE=\"P\" NAME=\"telf\" onclick=\"document.forms[0].tx_phone.value='"+oAdrs.getString(2,a)+"'\" "+(iAdrs==1 ? "CHECKED" : "")+">&nbsp;");
							    if (!oAdrs.isNull(1,a))
							      out.write(nullif((String)oLocationLookUp.get(oAdrs.get(1,a)),oAdrs.getString(1,a))+"&nbsp;");							      
							    out.write("Work Phone&nbsp;"+oAdrs.getString(2,a)+"<BR/>");
							  } // fi
							  if (!oAdrs.isNull(3,a)) {
							    out.write("<INPUT TYPE=\"radio\" VALUE=\"P\" NAME=\"telf\" onclick=\"document.forms[0].tx_phone.value='"+oAdrs.getString(3,a)+"'\">&nbsp;");
							    if (!oAdrs.isNull(1,a))
							      out.write(nullif((String)oLocationLookUp.get(oAdrs.get(1,a)),oAdrs.getString(1,a))+"&nbsp;");							      
							    out.write("Direct Phone&nbsp;"+oAdrs.getString(3,a)+"<BR/>");
							  } // fi
							  if (!oAdrs.isNull(4,a)) {
							    out.write("<INPUT TYPE=\"radio\" VALUE=\"P\" NAME=\"telf\" onclick=\"document.forms[0].tx_phone.value='"+oAdrs.getString(4,a)+"'\">&nbsp;");
							    if (!oAdrs.isNull(1,a))
							      out.write(nullif((String)oLocationLookUp.get(oAdrs.get(1,a)),oAdrs.getString(1,a))+"&nbsp;");
							    out.write("Personal&nbsp;"+oAdrs.getString(4,a)+"<BR/>");
							  } // fi
							  if (!oAdrs.isNull(5,a)) {
							    out.write("<INPUT TYPE=\"radio\" VALUE=\"P\" NAME=\"telf\" onclick=\"document.forms[0].tx_phone.value='"+oAdrs.getString(5,a)+"'\">&nbsp;");
							    if (!oAdrs.isNull(1,a))
							      out.write(nullif((String)oLocationLookUp.get(oAdrs.get(1,a)),oAdrs.getString(1,a))+"&nbsp;");
							    out.write("Mobile Phone&nbsp;"+oAdrs.getString(5,a)+"<BR/>");
							  } // fi
							} // next
							out.write("<INPUT TYPE=\"radio\" NAME=\"telf\" VALUE=\"O\" onclick=\"document.forms[0].tx_phone.value=document.forms[0].tx_other_phone.value\">&nbsp;Other&nbsp;<INPUT CLASS=\"combomini\" TYPE=\"text\" MAXLENGTH=\"16\" SIZE=\"16\" NAME=\"tx_other_phone\">&nbsp;<SELECT CLASS=\"combomini\" NAME=\"tp_location\"><OPTION VALUE=\"\"></OPTION>"+sLocationLookUp+"</SELECT>&nbsp;<SELECT CLASS=\"combomini\" NAME=\"tp_phone\"><OPTION VALUE=\""+DB.work_phone+"\">Work Phone</OPTION><OPTION VALUE=\""+DB.direct_phone+"\">Direct Phone</OPTION><OPTION VALUE=\""+DB.home_phone+"\">Personal</OPTION><OPTION VALUE=\""+DB.mov_phone+"\">Mobile Phone</OPTION></SELECT>");
%>
	          </TD>
	        </TR>
          <TR>
            <TD VALIGN="top" ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="470">
	      <TEXTAREA ROWS="3" STYLE="width:400px" NAME="tx_comments"></TEXTAREA>
	    </TD>
	  </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>          	
    	    <TD COLSPAN="2" ALIGN="center" CLASS="formplain">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="<% if (sIdPrevStatus!=null && ENABLE_ONGOING_CALLS_HANDLING) { out.write("req=createXMLHttpRequest(); req.open('GET','phonecall_status_update.jsp?gu_oportunity="+gu_oportunity+"&id_status="+(sIdPrevStatus.equals("ENCURSO") ? "PTE_LLAMAR" : sIdPrevStatus)+"',true); req.send(null);"); } %> window.parent.close()">
    	      <BR>
    	    </TD>
    	  </TR>            
        </TABLE>        
      </TD></TR>      
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>
