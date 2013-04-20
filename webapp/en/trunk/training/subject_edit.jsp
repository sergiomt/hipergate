<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.*,com.knowgate.training.Subject" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<% 
/*  
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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
  
  // 01. Authenticate user session by checking cookies
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // 02. Add no-cache headers
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_subject = nullif(request.getParameter("gu_subject"));
    
  Subject oSub = new Subject();
  
  String sAreasLookUp = "";
    
  JDCConnection oConn = null;
  DBSubset oCourses = new DBSubset(DB.k_courses, DB.gu_course+","+DB.nm_course, DB.gu_workarea+"=? AND "+DB.bo_active+"<>0 ORDER BY 2", 100);
  int iCourses = 0;
  
  try {
    
    oConn = GlobalDBBind.getConnection("subject_edit", true);  
    
    iCourses = oCourses.load(oConn, new Object[]{gu_workarea});

    sAreasLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_subjects_lookup", gu_workarea, DB.tx_area, sLanguage);
    
    if (gu_subject.length()>0) {
      oSub.load(oConn, new Object[]{gu_subject});
    }

    oConn.close("subject_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("subject_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }

  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Subject</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      function createCourse() {
        window.open ("course_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>", "editcourse", "directories=no,toolbar=no,menubar=no,width=500,height=400");
      } // createCourse()
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_subjects_lookup&id_language=" + getUserLanguage() + "&id_section=tx_area&tp_control=2&nm_control=sel_area&nm_coding=tx_area", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

      	if (frm.nm_subject.value.length==0) {
      	  alert ("Subject name is required");
      	  return false;
      	}
      
      	if ((frm.nm_subject.value.indexOf("'")>=0) || (frm.nm_subject.value.indexOf('"')>=0)) {
      	  alert ("Subject name contains forbidden characters");
      	  return false;
      	}
      
      	if ((frm.nm_short.value.indexOf("'")>=0) || (frm.nm_short.value.indexOf('"')>=0)) {
      	  alert ("Subject short name contains forbidden characters");
      	  return false;
      	}
      
      	if (frm.de_subject.value.length>2000) {
      	  alert ("Subject description cannot exceed 2000 characters");
      	  return false;
      	}
      	
      	if (frm.nu_credits.value.length>0) {
      	  if (!isFloatValue(frm.nu_credits.value)) {
      	    alert ("Credits number is not valid");
      	    return false;	  
      	  }
      	}
      	
      	if ((frm.sel_h_start.selectedIndex<=0 && frm.sel_m_start.selectedIndex> 0) ||
      	    (frm.sel_h_start.selectedIndex> 0 && frm.sel_m_start.selectedIndex<=0)) {
      	  alert ("Start date is not valid");
      	  return false;
      	}

      	if ((frm.sel_h_end.selectedIndex<=0 && frm.sel_m_end.selectedIndex> 0) ||
      	    (frm.sel_h_end.selectedIndex> 0 && frm.sel_m_end.selectedIndex<=0)) {
      	  alert ("End date is not valid");
      	  return false;
      	}

      	if (frm.sel_h_start.selectedIndex>0 && frm.sel_m_start.selectedIndex>0 &&
      	    frm.sel_h_end.selectedIndex>0 && frm.sel_m_end.selectedIndex>0 &&
      	    parseFloat(getCombo(frm.sel_h_start)+getCombo(frm.sel_m_start))>parseFloat(getCombo(frm.sel_h_end)+getCombo(frm.sel_m_end))) {
      	  alert ("Start date must be prior to end date");
      	  return false;
      	}

      	frm.nm_subject.value = frm.nm_subject.value.toUpperCase();
      	frm.nm_short.value = frm.nm_short.value.toUpperCase();
      	frm.id_subject.value = frm.id_subject.value.toUpperCase();
      	
      	frm.gu_course.value = getCombo(frm.sel_course);
      	frm.tx_area.value = getCombo(frm.sel_area);

	      if (frm.chk_active.checked) frm.bo_active.value = "1"; else frm.bo_active.value = "0";

        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];

        setCombo(frm.sel_area,"<%out.write(oSub.getStringNull(DB.tx_area,""));%>");
        setCombo(frm.sel_course,"<%out.write(oSub.getStringNull(DB.gu_course,""));%>");

<%			if (!oSub.isNull(DB.tm_start)) { %>
        setCombo(frm.sel_h_start,"<% out.write(oSub.getString(DB.tm_start).substring(0,2)); %>");
        setCombo(frm.sel_m_start,"<% out.write(oSub.getString(DB.tm_start).substring(3)); %>");				  
<%      }
		  if (!oSub.isNull(DB.tm_end)) { %>
        setCombo(frm.sel_h_end,"<% out.write(oSub.getString(DB.tm_end).substring(0,2)); %>");
        setCombo(frm.sel_m_end,"<% out.write(oSub.getString(DB.tm_end).substring(3)); %>");				  

<%    } %> 
        return true;
      } // validate;
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Subject</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="subject_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_subject" VALUE="<%=gu_subject%>">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="<% if (!oSub.isNull(DB.bo_active)) out.write(String.valueOf(oSub.getShort(DB.bo_active))); else out.write("1"); %>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Active:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="checkbox" NAME="chk_active" <% if (!oSub.isNull(DB.bo_active)) out.write(oSub.getShort(DB.bo_active)!=0 ? "CHECKED" : ""); else out.write("CHECKED"); %>></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_subject" MAXLENGTH="200" SIZE="48" STYLE="text-transform:uppercase" VALUE="<%=oSub.getStringNull(DB.nm_subject,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Short Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_short" MAXLENGTH="100" SIZE="48" STYLE="text-transform:uppercase" VALUE="<%=oSub.getStringNull(DB.nm_subject,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Identifier:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="id_subject" MAXLENGTH="50" SIZE="10" STYLE="text-transform:uppercase" VALUE="<%=oSub.getStringNull(DB.id_subject,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Course:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="gu_course">
              <SELECT NAME="sel_course" CLASS="combomini"><OPTION VALUE=""></OPTION>
              <% for (int c=0; c<iCourses; c++)
                   out.write ("<OPTION VALUE=\""+oCourses.getString(0,c)+"\">"+Gadgets.HTMLEncode(oCourses.getString(1,c))+"</OPTION>");
              %>
              </SELECT>
              &nbsp;
              <A HREF="#" onclick="createCourse()" TITLE="New Course"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Course"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Area:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tx_area">
              <SELECT NAME="sel_area" CLASS="combomini"><OPTION VALUE=""></OPTION><%=sAreasLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="List Areas"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Credits:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nu_credits" MAXLENGTH="5" SIZE="6" VALUE="<% if (!oSub.isNull(DB.nu_credits)) out.write(String.valueOf(oSub.getFloat(DB.nu_credits))); %>" onkeypress="acceptOnlyNumbers(this)"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Start:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
            	<SELECT NAME="sel_h_start" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
            	:
            	<SELECT NAME="sel_m_start" CLASS="combomini"><OPTION VALUE=""><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="29">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="39">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="49">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="59">59</OPTION></OPTION></SELECT>
							&nbsp;&nbsp;&nbsp;&nbsp;
							<FONT CLASS="formplain">End:</FONT>
            	<SELECT NAME="sel_h_end" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
            	:
            	<SELECT NAME="sel_m_end" CLASS="combomini"><OPTION VALUE=""><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="29">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="39">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="49">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="59">59</OPTION></OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Description:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><TEXTAREA ROWS="3" COLS="40" NAME="de_subject"<%=oSub.getStringNull(DB.de_subject,"")%>></TEXTAREA></TD>
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
