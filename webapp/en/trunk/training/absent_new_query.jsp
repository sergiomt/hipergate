<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = getCookie (request, "workarea", null);
  String id_user = getCookie (request, "userid", null);

  JDCConnection oConn = null;  
  DBSubset oACourses = null;
  int iACourses = 0;
  String sNmACourse;
  
  try {
    oConn = GlobalDBBind.getConnection("absent_new_query");

		if (WorkArea.isAdmin(oConn, gu_workarea, id_user)) {
      oACourses = new DBSubset ("v_active_courses", "gu_acourse,gu_course,id_acourse,nm_course,tx_start,tx_end", DB.gu_workarea+"=? ORDER BY 2,3", 100);
      iACourses = oACourses.load(oConn, new Object[]{gu_workarea});
		} else {
      oACourses = new DBSubset ("v_active_courses a", "a.gu_acourse,a.gu_course,a.id_acourse,a.nm_course,a.tx_start,a.tx_end",
																" (  EXISTS (SELECT u."+DB.gu_acourse+" FROM "+DB.k_x_user_acourse+" u WHERE u."+DB.gu_acourse+"=a."+DB.gu_acourse+" AND u."+DB.gu_user+"=? AND u."+DB.bo_user+"<>0) OR "+
                                "NOT EXISTS (SELECT u."+DB.gu_acourse+" FROM "+DB.k_x_user_acourse+" u WHERE u."+DB.gu_acourse+"=a."+DB.gu_acourse+" AND u."+DB.gu_user+"=?)) AND "+      													
      													DB.gu_workarea+"=? ORDER BY 2,3", 100);
      iACourses = oACourses.load(oConn, new Object[]{id_user,id_user,gu_workarea});		
		}

    oConn.close("absent_new_query");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("absent_new_query");      
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
  <script language="JavaScript" type="text/javascript" src="../javascript/combobox.js"></script>
  <script language="JavaScript" type="text/javascript">
    <!--
      var jsCourses = new Array("",<% for (int c=0; c<iACourses; c++) out.write((c>0?",":"")+"\""+oACourses.getString(1,c)+"\""); %>);
      
      function validate() {
        var frm = document.forms[0];
                
        if ((frm.sel_acourse.selectedIndex<1) && (frm.nm_alumni.value.length==0)) {
          alert ("Name of course or student to be searched is required");
          return false;
        }
        frm.gu_acourse.value = getCombo(frm.sel_acourse);
        frm.gu_course.value = jsCourses[frm.sel_acourse.selectedIndex];
        
        return true;
      }
    //-->
  </script>
</head>
<body scrolling="no">
  <table width="98%">
    <tr><td><img src="../images/images/spacer.gif" height="4" width="1" border="0"></td></tr>
    <tr><td class="striptitle"><font class="title1">Reportar Faltas de Asistencia</font></td></tr>
  </table>
  <form method="post" action="absent_new_list.jsp" target="listabsents">
    <input type="hidden" name="gu_workarea" value="<%=gu_workarea%>">
    <input type="hidden" name="gu_acourse">
    <input type="hidden" name="gu_course">
    <table cellspacing="2" cellpadding="2">
      <tr>
        <td valign="bottom">&nbsp;&nbsp;<img src="../images/images/find16.gif" height="16" border="0" alt="Search"></td>
        <td class="textplain">
          Course:&nbsp;
          <select class="combomini" name="sel_acourse"><option value=""></option>
<% for (int a=0; a<iACourses; a++) {
     sNmACourse = oACourses.getStringNull(2,a,"");
     if (oACourses.isNull(2,a))
       sNmACourse = oACourses.getStringNull(4,a,"")+" - "+oACourses.getStringNull(5,a,"");
     else
       sNmACourse = oACourses.getString(3,a);
     out.write("<option value=\""+oACourses.getString(0,a)+"\">"+Gadgets.HTMLEncode(sNmACourse)+"</option>");
   } // next
%>        </select>
          &nbsp;&nbsp;&nbsp;&nbsp;
          Student's Name&nbsp;
          <input type="text" class="combomini" name="nm_alumni" maxlength="100">
          &nbsp;&nbsp;&nbsp;&nbsp;
	  <a href="#" onclick="if (validate()) document.forms[0].submit()" class="linkplain">Search</A>
      </tr>
    </table>
  </form>
</body>
</html>
<%@ include file="../methods/page_epilog.jspf" %>