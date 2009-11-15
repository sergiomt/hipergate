<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
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
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = getCookie (request, "workarea", null);
  String id_user = getCookie (request, "userid", null);

  String gu_course  = request.getParameter("gu_course");
  String gu_acourse = request.getParameter("gu_acourse");
  String nm_alumni  = request.getParameter("nm_alumni");
  
  JDCConnection oConn = null;  
  DBSubset oStudents;
  DBSubset oSubjects;
  int iStudents = 0;
  int iSubjects = 0;
  Object[] aStudentParams;
  Object[] aSubjectParams;
  
  if (gu_acourse.length()>0 && nm_alumni.length()>0) {
    oStudents = new DBSubset(DB.k_contacts + " c," + DB.k_x_course_alumni + " x," + DB.k_academic_courses + " a",    			     
    			     "x."+DB.gu_alumni+",c."+DB.tx_name+",c."+DB.tx_surname+",a."+DB.gu_acourse,
    			     "a."+DB.gu_acourse+"=x."+DB.gu_acourse+ " AND x."+DB.gu_alumni+"=c."+DB.gu_contact+" AND "+
    			     "c."+DB.gu_workarea+"=? AND a."+DB.gu_acourse+"=? AND (c."+DB.tx_name+" " + DBBind.Functions.ILIKE + " ? OR c."+DB.tx_surname+" " + DBBind.Functions.ILIKE + " ?) "+
    			     " ORDER BY 2,3", 50);
    aStudentParams = new Object[]{gu_workarea,gu_acourse,"%"+nm_alumni+"%","%"+nm_alumni+"%"};
    oSubjects = new DBSubset(DB.k_subjects + " s," + DB.k_x_course_subject + " x",
    			     "s."+DB.gu_subject+",s."+DB.nm_subject+",s."+DB.nm_short+",s."+DB.id_subject,
    			     "s."+DB.gu_subject+"=x."+DB.gu_subject+" AND " +
    			     "s."+DB.bo_active+"<>0 AND x."+DB.gu_course+"=? ORDER BY 2", 10);
    aSubjectParams = new Object[]{gu_course};
  }
  else if (gu_acourse.length()>0) {
    oStudents = new DBSubset(DB.k_contacts + " c," + DB.k_x_course_alumni + " x," + DB.k_academic_courses + " a",    			     
    			     "x."+DB.gu_alumni+",c."+DB.tx_name+",c."+DB.tx_surname+",a."+DB.gu_acourse,
    			     "a."+DB.gu_acourse+"=x."+DB.gu_acourse+ " AND x."+DB.gu_alumni+"=c."+DB.gu_contact+" AND "+
    			     "c."+DB.gu_workarea+"=? AND a."+DB.gu_acourse+"=? ORDER BY 2,3", 50);
    aStudentParams = new Object[]{gu_workarea,gu_acourse};
    oSubjects = new DBSubset(DB.k_subjects + " s," + DB.k_x_course_subject + " x",
    			     "s."+DB.gu_subject+",s."+DB.nm_subject+",s."+DB.nm_short+",s."+DB.id_subject,
    			     "s."+DB.gu_subject+"=x."+DB.gu_subject+" AND " +
    			     "s."+DB.bo_active+"<>0 AND x."+DB.gu_course+"=? ORDER BY 2", 10);  
    aSubjectParams = new Object[]{gu_course};
  }
  else {
    oStudents = new DBSubset(DB.k_contacts + " c," + DB.k_x_course_alumni + " x," + DB.k_academic_courses + " a",
    			     "x."+DB.gu_alumni+",c."+DB.tx_name+",c."+DB.tx_surname+",a."+DB.gu_acourse,
    			     "a."+DB.gu_acourse+"=x."+DB.gu_acourse+ " AND x."+DB.gu_alumni+"=c."+DB.gu_contact+" AND "+
    			     "c."+DB.gu_workarea+"=? AND a."+DB.bo_active+"<>0 AND (c."+DB.tx_name+" " + DBBind.Functions.ILIKE + " ? OR c."+DB.tx_surname+" " + DBBind.Functions.ILIKE + " ?) "+
    			     " ORDER BY 2,3", 50);
    aStudentParams = new Object[]{gu_workarea,"%"+nm_alumni+"%","%"+nm_alumni+"%"};
    oSubjects = new DBSubset(DB.k_subjects + " s," + DB.k_x_course_subject + " x," + DB.k_courses + " c",
    			     "s."+DB.gu_subject+",s."+DB.nm_subject+",s."+DB.nm_short+",s."+DB.id_subject,
    			     "s."+DB.gu_subject+"=x."+DB.gu_subject+" AND x."+DB.gu_course+"=c."+DB.gu_course+" AND " +
    			     "c."+DB.gu_workarea+"=? AND s."+DB.bo_active+"<>0 AND c."+DB.bo_active+"<>0 ORDER BY 2", 10); 
    aSubjectParams = new Object[]{gu_workarea};
  }
  
  try {
    oConn = GlobalDBBind.getConnection("absent_new_list", true);
    
    iStudents = oStudents.load(oConn, aStudentParams);
    iSubjects = oSubjects.load(oConn, aSubjectParams);

    oConn.close("absent_new_list");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("absent_new_list");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;
%>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <script language="JavaScript" src="../javascript/cookies.js"></script>  
  <script language="JavaScript" src="../javascript/setskin.js"></script>
  <script language="JavaScript" src="../javascript/combobox.js"></script>
  <script language="JavaScript" src="../javascript/datefuncs.js"></script>
  <script language="JavaScript" type="text/javascript">
    <!--
      function setCombos() {
        var now = new Date();
        var frm = document.forms[0];
       
        var day = String(now.getDate());
        if (day.length==1) day = "0"+day;
        var mon = String(now.getMonth());
        if (mon.length==1) mon = "0"+mon;
      
        setCombo(frm.sel_day_from, day);
        setCombo(frm.sel_day_to, day);
        setCombo(frm.sel_month_from, mon);
        setCombo(frm.sel_month_to, mon);
        setCombo(frm.sel_year_from, String(now.getYear()));
        setCombo(frm.sel_year_to, String(now.getYear())); 
      }

      // ----------------------------------------------------------------------

      function validate() {
        var frm = document.forms[0];
	var opt = frm.sel_students.options;
        var fr = Number(getCombo(frm.sel_year_from)+getCombo(frm.sel_month_from)+getCombo(frm.sel_day_from)+getCombo(frm.sel_hour_from)+getCombo(frm.sel_min_from));
        var to = Number(getCombo(frm.sel_year_to)+getCombo(frm.sel_month_to)+getCombo(frm.sel_day_to)+getCombo(frm.sel_hour_to)+getCombo(frm.sel_min_to));

	if (fr>to) {
	  alert("Start date must be prior to end date");
	  return false;
	}

	frm.students.value = "";
        for (var s=0; s<opt.length; s++) {
          if (opt[s].selected) {
	    frm.students.value += (frm.students.value.length==0 ? "" : ",") + opt[s].value;
          }
        }
        if (frm.students.value.length==0) {
	  alert("At least one student must be selected");
	  return false;          
        }

        if (frm.tx_comments.value.length>1000) {
	  alert("Comments may not exceed 1000 characters");
	  return false;                  
        }
        
        return true;
      }
    //-->
  </script>
</head>
<body  onload="setCombos()">
  <form method="post" action="absent_new_store.jsp" onsubmit="return validate()">
    <input type="hidden" name="gu_course" value="<%=gu_course%>">
    <input type="hidden" name="gu_acourse" value="<%=gu_acourse%>">
    <input type="hidden" name="students">

    <table>
      <tr>
        <td class="textplain" align="right">Since</td>
        <td>
          <select name="sel_day_from" class="combomini"><option value="01">01</option><option value="02">02</option><option value="03">03</option><option value="04">04</option><option value="05">05</option><option value="06">06</option><option value="07">07</option><option value="08">08</option><option value="09">09</option><option value="10">10</option><option value="11">11</option><option value="12">12</option><option value="13">13</option><option value="14">14</option><option value="15">15</option><option value="16">16</option><option value="17">17</option><option value="18">18</option><option value="19">19</option><option value="21">11</option><option value="22">12</option><option value="23">23</option><option value="24">24</option><option value="25">25</option><option value="26">26</option><option value="27">27</option><option value="28">28</option><option value="29">29</option><option value="30">30</option><option value="31">31</option></select>
          <select name="sel_month_from" class="combomini"><option value="00">January</option><option value="01">February</option><option value="02">March</option><option value="03">April</option><option value="04">May</option><option value="05">June</option><option value="06">July</option><option value="07">August</option><option value="08">September</option><option value="09">October</option><option value="10">November</option><option value="11">December</option></select>
          <select name="sel_year_from" class="combomini"><option value="2005">2005</option><option value="2006">2006</option><option value="2007">2007</option><option value="2008">2008</option><option value="2009">2009</option><option value="2010">2010</option></select>
          <select name="sel_hour_from" class="combomini"><option value="01">01</option><option value="02">02</option><option value="03">03</option><option value="04">04</option><option value="05">05</option><option value="06">06</option><option value="07">07</option><option value="08">08</option><option value="09" selected>09</option><option value="10">10</option><option value="11">11</option><option value="12">12</option><option value="13">13</option><option value="14">14</option><option value="15">15</option><option value="16">16</option><option value="17">17</option><option value="18">18</option><option value="19">19</option><option value="21">11</option><option value="22">12</option><option value="23">23</select>	  
          <select name="sel_min_from" class="combomini"><option value="00" selected>00</option><option value="05">05</option><option value="10">10</option><option value="15">15</option><option value="20">20</option><option value="25">25</option><option value="30">30</option><option value="35">35</option><option value="40">40</option><option value="45">45</option><option value="50">50</option><option value="55">55</option></select>
	</td>
        <td></td>
      </tr>
      <tr>
        <td class="textplain" align="right">until</td>
        <td>
          <select name="sel_day_to" class="combomini"><option value="01">01</option><option value="02">02</option><option value="03">03</option><option value="04">04</option><option value="05">05</option><option value="06">06</option><option value="07">07</option><option value="08">08</option><option value="09">09</option><option value="10">10</option><option value="11">11</option><option value="12">12</option><option value="13">13</option><option value="14">14</option><option value="15"selected="selected">15</option><option value="16">16</option><option value="17">17</option><option value="18">18</option><option value="19">19</option><option value="21">11</option><option value="22">12</option><option value="23">23</option><option value="24">24</option><option value="25">25</option><option value="26">26</option><option value="27">27</option><option value="28">28</option><option value="29">29</option><option value="30">30</option><option value="31">31</option></select>
          <select name="sel_month_to" class="combomini"><option value="00">January</option><option value="01">February</option><option value="02">March</option><option value="03">April</option><option value="04">May</option><option value="05">June</option><option value="06">July</option><option value="07">August</option><option value="08">September</option><option value="09">October</option><option value="10">November</option><option value="11">December</option></select>
          <select name="sel_year_to" class="combomini"><option value="2005">2005</option><option value="2006">2006</option><option value="2007">2007</option><option value="2008">2008</option><option value="2009">2009</option><option value="2010">2010</option></select>
          <select name="sel_hour_to" class="combomini"><option value="01">01</option><option value="02">02</option><option value="03">03</option><option value="04">04</option><option value="05">05</option><option value="06">06</option><option value="07">07</option><option value="08">08</option><option value="09" selected>09</option><option value="10">10</option><option value="11">11</option><option value="12">12</option><option value="13">13</option><option value="14">14</option><option value="15">15</option><option value="16" selected>16</option><option value="17">17</option><option value="18">18</option><option value="19">19</option><option value="21">11</option><option value="22">12</option><option value="23">23</select>	  
          <select name="sel_min_to" class="combomini"><option value="00" selected>00</option><option value="05">05</option><option value="10">10</option><option value="15">15</option><option value="20">20</option><option value="25">25</option><option value="30">30</option><option value="35">35</option><option value="40">40</option><option value="45">45</option><option value="50">50</option><option value="55">55</option></select>
        </td>
        <td></td>
      </tr>
      <tr>
        <td class="textplain" align="right" valign="top">Comments</td>
        <td><textarea name="tx_comments" rows="2" cols="34"></textarea></td>
        <td valign="top">
          <table>
            <tr>
              <td class="textplain">Justified</td>
              <td class="textplain"><input type="radio" name="tp_absentism" value="JUSTIFIED">&nbsp;Yes&nbsp;&nbsp;<input type="radio" name="tp_absentism" value="UNJUSTIFIED" checked>&nbsp;No</td>
            </tr>
            <tr>
              <td class="textplain">Whole Day</td>
              <td><input type="checkbox" name="bo_wholeday" VALUE="1"></td>
            </tr>
          </table>        
	</td>
      </tr>        	  
      <tr>
        <td class="textplain" align="right" valign="top">Students</td>
	<td>
	  <select name="sel_students" size="11" style="width:292px" multiple>
<% for (int a=0; a<iStudents; a++) {
     out.write("<option value=\""+oStudents.getString(0,a)+"\">"+Gadgets.HTMLEncode(oStudents.getStringNull(1,a,"")+" "+oStudents.getStringNull(2,a,""))+"</option>");
   }
%>
	  </select>
	</td>
	<td valign="top" class="textplain">
	Subject<br>
<% for (int s=0; s<iSubjects; s++) {
     out.write("<input type=\"radio\" value=\""+oSubjects.getString(0,s)+"\" name=\"gu_subject\">&nbsp;"+oSubjects.getString(1,s)+"<br>");
   }
%>
	</td>
      </tr>       
    </table>
    <hr>
    <center><input type="submit" class="pushbutton" value="Save" accesskey="s">&nbsp;&nbsp;<input type="button" class="closebutton" value="Cancel" accesskey="c" onclick="window.parent.close()"></center>
  </form>
</body>
</html>
<%@ include file="../methods/page_epilog.jspf" %>