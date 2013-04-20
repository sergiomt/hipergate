<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.Contact,com.knowgate.misc.Gadgets,com.knowgate.training.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  
  Copyright (C) 2007  Know Gate S.L. All rights reserved.
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
  String gu_absentism = request.getParameter("gu_absentism");
  
  Absentism oAbsm = new Absentism();
  Contact oCntt = null; 
  DBSubset oAcrs = new DBSubset(DB.k_courses+" c,"+DB.k_academic_courses+" a",
                                "a."+DB.gu_acourse+",a."+DB.nm_course+",c."+DB.gu_course,
                                "a."+DB.gu_course+"=c."+DB.gu_course+" AND "+
                                "c."+DB.gu_workarea+"=? AND "+
                                "(a."+DB.bo_active+"<>0 OR a."+DB.gu_acourse+"=?) "+
                                "ORDER BY 2", 50);
  int iAcrs = 0;
  DBSubset oSbjs = new DBSubset(DB.k_subjects + " s," + DB.k_x_course_subject + " x",
    			        "s."+DB.gu_subject+",s."+DB.nm_subject+",s."+DB.nm_short+",s."+DB.id_subject,
    			        "s."+DB.gu_subject+"=x."+DB.gu_subject+" AND " +
    			        "s."+DB.bo_active+"<>0 AND x."+DB.gu_course+"=? ORDER BY 2", 10);  
  int iSbjs = 0;
  JDCConnection oConn = null;
    
  try {
    
    oConn = GlobalDBBind.getConnection("absentism_edit", true);  
    
    if (oAbsm.load(oConn, new Object[]{gu_absentism})) {
      iAcrs = oAcrs.load(oConn, new Object[]{gu_workarea, oAbsm.get(DB.gu_acourse)});
      if (iAcrs>0) {
        iSbjs = oSbjs.load(oConn, new Object[]{oAcrs.getString(2,0)});
      }
      oCntt = oAbsm.getContact(oConn);
    }

    oConn.close("absentism_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("absentism_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Absentism</TITLE>
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

      // ------------------------------------------------------

      function listSubjects(ac) {
        var cmb = document.forms[0].gu_subject;        
        clearCombo(cmb);
        var subjs = httpRequestText("subjects_for_course.jsp?gu_acourse="+ac);
        if (subjs.length>0) {
          var lins = subjs.split("\n");
          for (var l=0; l<lins.length; l++) {
            if (lins[l].length>0) {
              var subjt = lins[l].split(";");
              cmb.options[cmb.options.length] = new Option(subjt[1], subjt[0], false, false);
            }
          } // next
        } // fi
      } // listSubjects

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        var fr = Number(getCombo(frm.sel_year_from)+getCombo(frm.sel_month_from)+getCombo(frm.sel_day_from)+getCombo(frm.sel_hour_from)+getCombo(frm.sel_min_from));
        var to = Number(getCombo(frm.sel_year_to)+getCombo(frm.sel_month_to)+getCombo(frm.sel_day_to)+getCombo(frm.sel_hour_to)+getCombo(frm.sel_min_to));

	if (fr>to) {
	  alert("Start date must be prior to end date");
	  return false;
	}

	if (frm.tx_comments.value.length>254) {
	  alert ("Comments may not exceed 254 characters");
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
        setCombo(frm.gu_acourse,"<% out.write(oAbsm.getStringNull(DB.gu_acourse,"")); %>");
        setCombo(frm.gu_subject,"<% out.write(oAbsm.getStringNull(DB.gu_subject,"")); %>");
        setCombo(frm.sel_year_from,"<% out.write(String.valueOf(oAbsm.getDate(DB.dt_from).getYear()+1900)); %>");
        setCombo(frm.sel_month_from,"<% out.write(Gadgets.leftPad(String.valueOf(oAbsm.getDate(DB.dt_from).getMonth()),'0',2)); %>");
        setCombo(frm.sel_day_from,"<% out.write(Gadgets.leftPad(String.valueOf(oAbsm.getDate(DB.dt_from).getDate()),'0',2)); %>");
        setCombo(frm.sel_hour_from,"<% out.write(Gadgets.leftPad(String.valueOf(oAbsm.getDate(DB.dt_from).getHours()),'0',2)); %>");
        setCombo(frm.sel_min_from,"<% out.write(Gadgets.leftPad(String.valueOf(oAbsm.getDate(DB.dt_from).getMinutes()),'0',2)); %>");
        setCombo(frm.sel_year_to,"<% out.write(String.valueOf(oAbsm.getDate(DB.dt_to).getYear()+1900)); %>");
        setCombo(frm.sel_month_to,"<% out.write(Gadgets.leftPad(String.valueOf(oAbsm.getDate(DB.dt_to).getMonth()),'0',2)); %>");
        setCombo(frm.sel_day_to,"<% out.write(Gadgets.leftPad(String.valueOf(oAbsm.getDate(DB.dt_to).getDate()),'0',2)); %>");
        setCombo(frm.sel_hour_to,"<% out.write(Gadgets.leftPad(String.valueOf(oAbsm.getDate(DB.dt_to).getHours()),'0',2)); %>");
        setCombo(frm.sel_min_to,"<% out.write(Gadgets.leftPad(String.valueOf(oAbsm.getDate(DB.dt_to).getMinutes()),'0',2)); %>");
        return true;
      } // validate;
    //-->
  </SCRIPT> 
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Absentism</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="absentism_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_absentism" VALUE="<%=gu_absentism%>">
    <INPUT TYPE="hidden" NAME="gu_alumni" VALUE="<%=oAbsm.getString(DB.gu_alumni)%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD CLASS="formstrong" ALIGN="right">Student</TD>
            <TD CLASS="formplain"><%=oCntt.getStringNull(DB.tx_name,"")+" "+oCntt.getStringNull(DB.tx_surname,"")%></TD>
          </TR>
          <TR>
            <TD CLASS="formstrong" ALIGN="right">Course</TD>
            <TD CLASS="formplain"><SELECT NAME="gu_acourse" onchange="listSubjects(this.options[this.selectedIndex].value)"><% for (int a=0; a<iAcrs; a++) out.write("<OPTION VALUE=\""+oAcrs.getString(0,a)+"\">"+oAcrs.getString(1,a)+"</OPTION>"); %></SELECT></TD>
          </TR>
          <TR>
            <TD CLASS="formstrong" ALIGN="right">Subjects</TD>
            <TD CLASS="formplain"><SELECT NAME="gu_subject"><% for (int s=0; s<iSbjs; s++) out.write("<OPTION VALUE=\""+oSbjs.getString(0,s)+"\">"+oSbjs.getString(1,s)+"</OPTION>"); %></SELECT></TD>
          </TR>
          <TR>
            <TD CLASS="formstrong" ALIGN="right">From</TD>
            <TD>
              <select name="sel_year_from" class="combomini"><option value="2005">2005</option><option value="2006">2006</option><option value="2007">2007</option><option value="2008">2008</option><option value="2009">2009</option><option value="2010">2010</option></select>
              <select name="sel_month_from" class="combomini"><option value="00">January</option><option value="01">February</option><option value="02">March</option><option value="03">April</option><option value="04">May</option><option value="05">June</option><option value="06">July</option><option value="07">August</option><option value="08">September</option><option value="09">October</option><option value="10">November</option><option value="11">December</option></select>
              <select name="sel_day_from" class="combomini"><option value="01">01</option><option value="02">02</option><option value="03">03</option><option value="04">04</option><option value="05">05</option><option value="06">06</option><option value="07">07</option><option value="08">08</option><option value="09">09</option><option value="10">10</option><option value="11">11</option><option value="12">12</option><option value="13">13</option><option value="14">14</option><option value="15"selected="selected">15</option><option value="16">16</option><option value="17">17</option><option value="18">18</option><option value="19">19</option><option value="21">11</option><option value="22">12</option><option value="23">23</option><option value="24">24</option><option value="25">25</option><option value="26">26</option><option value="27">27</option><option value="28">28</option><option value="29">29</option><option value="30">30</option><option value="31">31</option></select>
              <select name="sel_hour_from" class="combomini"><option value="01">01</option><option value="02">02</option><option value="03">03</option><option value="04">04</option><option value="05">05</option><option value="06">06</option><option value="07">07</option><option value="08">08</option><option value="09" selected>09</option><option value="10">10</option><option value="11">11</option><option value="12">12</option><option value="13">13</option><option value="14">14</option><option value="15">15</option><option value="16" selected>16</option><option value="17">17</option><option value="18">18</option><option value="19">19</option><option value="21">11</option><option value="22">12</option><option value="23">23</select>	  
              <select name="sel_min_from" class="combomini"><option value="00" selected>00</option><option value="05">05</option><option value="10">10</option><option value="15">15</option><option value="20">20</option><option value="25">25</option><option value="30">30</option><option value="35">35</option><option value="40">40</option><option value="45">45</option><option value="50">50</option><option value="55">55</option></select>
            </TD>
          </TR>
          <TR>
            <TD CLASS="formstrong" align="right">To</TD>
            <TD>
              <select name="sel_year_to" class="combomini"><option value="2005">2005</option><option value="2006">2006</option><option value="2007">2007</option><option value="2008">2008</option><option value="2009">2009</option><option value="2010">2010</option></select>
              <select name="sel_month_to" class="combomini"><option value="00">January</option><option value="01">February</option><option value="02">March</option><option value="03">April</option><option value="04">May</option><option value="05">June</option><option value="06">July</option><option value="07">August</option><option value="08">September</option><option value="09">October</option><option value="10">November</option><option value="11">December</option></select>
              <select name="sel_day_to" class="combomini"><option value="01">01</option><option value="02">02</option><option value="03">03</option><option value="04">04</option><option value="05">05</option><option value="06">06</option><option value="07">07</option><option value="08">08</option><option value="09">09</option><option value="10">10</option><option value="11">11</option><option value="12">12</option><option value="13">13</option><option value="14">14</option><option value="15"selected="selected">15</option><option value="16">16</option><option value="17">17</option><option value="18">18</option><option value="19">19</option><option value="21">11</option><option value="22">12</option><option value="23">23</option><option value="24">24</option><option value="25">25</option><option value="26">26</option><option value="27">27</option><option value="28">28</option><option value="29">29</option><option value="30">30</option><option value="31">31</option></select>
              <select name="sel_hour_to" class="combomini"><option value="01">01</option><option value="02">02</option><option value="03">03</option><option value="04">04</option><option value="05">05</option><option value="06">06</option><option value="07">07</option><option value="08">08</option><option value="09" selected>09</option><option value="10">10</option><option value="11">11</option><option value="12">12</option><option value="13">13</option><option value="14">14</option><option value="15">15</option><option value="16" selected>16</option><option value="17">17</option><option value="18">18</option><option value="19">19</option><option value="21">11</option><option value="22">12</option><option value="23">23</select>	  
              <select name="sel_min_to" class="combomini"><option value="00" selected>00</option><option value="05">05</option><option value="10">10</option><option value="15">15</option><option value="20">20</option><option value="25">25</option><option value="30">30</option><option value="35">35</option><option value="40">40</option><option value="45">45</option><option value="50">50</option><option value="55">55</option></select>
            </TD>
          </TR>
          <TR>
            <TD CLASS="formplain" ALIGN="right">Justificada</TD>
            <TD CLASS="formplain"><INPUT TYPE="radio" NAME="tp_absentism" VALUE="JUSTIFIED" <% if (oAbsm.getStringNull(DB.tp_absentism,"").equalsIgnoreCase("JUSTIFIED")) out.write("CHECKED"); %>>Yes&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="tp_absentism" VALUE="UNJUSTIFIED" <% if (oAbsm.getStringNull(DB.tp_absentism,"").equalsIgnoreCase("UNJUSTIFIED")) out.write("CHECKED"); %>>&nbsp;No</TD>
          </TR>
          <TR>
            <TD CLASS="formplain" ALIGN="right">All day</TD>
            <TD><INPUT TYPE="checkbox" NAME="bo_wholeday" VALUE="1" <%if (oAbsm.getShort(DB.bo_wholeday)==(short)1) out.write("CHECKED"); %>></TD>
          </TR>
          <TR>
            <TD CLASS="formplain" ALIGN="right">Comments</TD>
            <TD><TEXTAREA NAME="tx_comments" ROWS="2"><%=oAbsm.getStringNull(DB.tx_comments,"")%></TEXTAREA></TD>
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
