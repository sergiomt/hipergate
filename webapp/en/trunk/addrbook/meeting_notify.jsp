<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.Meeting" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 
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
  
  String gu_meeting = request.getParameter("gu_meeting");
  
  Meeting oMeet = new Meeting();
  
  JDCConnection oConn = null;
  ACLUser oMe = new ACLUser();
  
  DBSubset oContacts = new DBSubset(DB.k_member_address + " c," + DB.k_x_meeting_contact + " x",
                                    " c." + DB.tx_email,
                                    "c." + DB.gu_contact + "=x." + DB.gu_contact + " AND x." + DB.gu_meeting + "=? AND c." + DB.tx_email + " IS NOT NULL", 4);

  DBSubset oFellows = new DBSubset(DB.k_users + " c," + DB.k_x_meeting_fellow + " x",
                                    " c." + DB.tx_main_email,
                                    "c." + DB.gu_user + "=x." + DB.gu_fellow + " AND x." + DB.gu_meeting + "=?", 4);
  int iContacts=0, iFellows=0;
  
  try {    
    oConn = GlobalDBBind.getConnection("meeting_notify");  

    oMe.load(oConn, new Object[]{getCookie (request, "userid", null)}) ;
    
    oMeet.load(oConn, new Object[]{gu_meeting});

    iContacts = oContacts.load(oConn, new Object[]{gu_meeting});
    iFellows = oFellows.load(oConn, new Object[]{gu_meeting});

    oConn.close("meeting_notify");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("meeting_notify");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_topclose"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Example Form</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        
        if (ltrim(frm.recipients.value)=="") {
	  alert ("The message must have at least one recipient");
	  return false;
        }
        
        var rec = frm.recipients.value.split(";");
	for (var r=0; r<rec.length; r++) {
	  if (!check_email(rec[r])) {
	    alert (rec[r]+" the e-mail address is not valid");
	    return false;	  
	  }
	} // next

        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Notify activity</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="meeting_notify_mail.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_meeting" VALUE="<%=gu_meeting%>">
    <INPUT TYPE="hidden" NAME="from" VALUE="<%=oMe.getStringNull(DB.tx_main_email,"")%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Subject</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="subject" MAXLENGTH="254" SIZE="48" VALUE="<%=oMeet.getStringNull(DB.tx_meeting,"")+" "+oMeet.get(DB.dt_start).toString()%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Attendants</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
            <TEXTAREA NAME="recipients" ROWS="4" COLS="38"><%
for (int c=0; c<iContacts; c++) {
     out.write((c==0 ? "" : ";") + oContacts.getString(0,c));
   } // next
 for (int f=0; f<iFellows; f++) {
     out.write((f==0 && iContacts==0 ? "" : ";") + oFellows.getString(0,f));
   } // next
%></TEXTAREA></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="370">
            <TEXTAREA NAME="de_meeting" ROWS="12" COLS="38"><%=oMeet.getStringNull(DB.de_meeting,"")%></TEXTAREA></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Send" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.parent.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
