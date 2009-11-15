<%@ page import="java.text.DecimalFormat,java.util.Arrays,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.crm.Contact,com.knowgate.training.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_acourse = request.getParameter("gu_acourse");
  int iFilter= Integer.parseInt(nullif(request.getParameter("filter"),"0"));

  JDCConnection oConn = null;
  AcademicCourse oAcrs = new AcademicCourse();
  int iBooks = 0;
  AcademicCourseBooking[] aBooks = null;
  AcademicCourseAlumni [] aAlmni = null;
  AcademicCourseAlumni oAlmni = new AcademicCourseAlumni(gu_acourse, null);
  Contact[] aCont = null;
  DecimalFormat oFmt2 = new DecimalFormat();
  oFmt2.setMaximumFractionDigits(2);
      
  try {
    oConn = GlobalDBBind.getConnection("bookings_edit", true);  

    oAcrs.load(oConn, new Object[]{gu_acourse});
    
    switch (iFilter) { 
      case 0: aBooks = oAcrs.getAllBookings(oConn); break;
      case 1: aBooks = oAcrs.getActiveBookings(oConn); break;
      case 2: aBooks = oAcrs.getConfirmedBookings(oConn); break;
      case 3: aBooks = oAcrs.getUnconfirmedBookings(oConn); break;
      case 4: aBooks = oAcrs.getWaitingBookings(oConn); break;
      case 5: aBooks = oAcrs.getPaidBookings(oConn); break;
      case 6: aBooks = oAcrs.getUnpaidBookings(oConn); break;
      case 7: aBooks = oAcrs.getCancelledBookings(oConn); break;
    }
    
    if (aBooks!=null) {
      iBooks = aBooks.length;
      aCont = new Contact[iBooks];
    }
    
    for (int c=0; c<iBooks; c++) aCont[c] = aBooks[c].getContact(oConn);

    aAlmni = oAcrs.getAlumni(oConn);
    
    oConn.close("bookings_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("bookings_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Course Registrations</TITLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
    <!--

      var pr_acourse = "<% if (!oAcrs.isNull(DB.pr_acourse)) { out.write(oFmt2.format(oAcrs.getDecimal(DB.pr_acourse).doubleValue())); } %>";

      var cnt = new Array(<%
	      for (int b=0; b<iBooks; b++) {
          out.write((b>0 ? ",\"" : "\"")+aBooks[b].getString(DB.gu_contact)+"\"");
        }
        out.write(");\n"); %>

      // ------------------------------------------------------

      function switchAlumni(gu,ix) {
  	var req = createXMLHttpRequest();
        var frm = window.document.forms[0];
        var btn = document.getElementById(gu+"_buttonAlumni");
        var sta = frm.elements["alumni_"+String(ix)];
        if (sta.value=="0") {
          if (frm.elements[gu+"_canceled"].checked) {
            alert ("It is not possible to admit students whose registration has been cancelled");
          } else {
            sta.value = "1";
            btn.src = "../images/images/corrected.gif";
  	    req.open("GET","bookings_to_alumni.jsp?gu_acourse=<%=gu_acourse%>&alumni="+gu,true);
            req.send(null);
          }
        } else {
          sta.value = "0";
          btn.src = "../images/images/pending.gif";          
  	  req.open("GET","alumni_delete.jsp?gu_acourse=<%=gu_acourse%>&alumni="+gu,true);
          req.send(null);
        }
      } // switchAlumni

      // ------------------------------------------------------
      
      function clickCancel(gu) {
        var frm = window.document.forms[0];
	var cnl = frm.elements[gu+"_canceled"];
	var wit = frm.elements[gu+"_waiting"];
	if (cnl.checked) wit.checked = false;
      }

      // ------------------------------------------------------

      function clickWaiting(gu) {
        var frm = window.document.forms[0];
	var cnl = frm.elements[gu+"_canceled"];
	var wit = frm.elements[gu+"_waiting"];
		
	if (wit.checked && cnl.checked) {	  
	  wit.checked=false;
	  alert ("It is not possible to put cancelled registrations into the waiting list");
	}	
      }

      // ------------------------------------------------------

      function clickPaid(gu) {
        var frm = window.document.forms[0];
	      var pid = frm.elements[gu+"_paid"];
		
	      if (pid.checked ) {
	        if (frm.elements[gu+"_amount"].value.length==0)
	          frm.elements[gu+"_amount"].value = pr_acourse;
	        if (frm.elements[gu+"_date"].value.length==0)
	          frm.elements[gu+"_date"].value=dateToString(new Date(),'d');
	        
	      }  else {
	        frm.elements[gu+"_amount"].value = "";
	      }	
      }

      // ------------------------------------------------------

      function convertToAlumni() {
        var frm = window.document.forms[0];
        var lst = "";
        if (window.confirm("Are you sure that you want to promote all registrations to actual course students?")) {
	  for (var c=0; c<<%=String.valueOf(iBooks)%>; c++) {
	    if (frm.elements[cnt[c]+"_confirmed"].checked) {
	      lst += (lst.length==0 ? "" : ",") + cnt[c];
	    }
	  } // next
	  if (lst.length>0) {
	    httpRequestText("bookings_to_alumni.jsp?gu_acourse=<%=gu_acourse%>&alumni="+lst);
	    document.location.reload();
          }
        } // fi 
      } // convertToAlumni

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
	      for (var c=0; c<<%=String.valueOf(iBooks)%>; c++) {
	        if (frm.elements[cnt[c]+"_amount"].value.length>0 && !isFloatValue(frm.elements[cnt[c]+"_amount"].value)) {
	          alert ("Amount is not valid");
	          frm.elements[cnt[c]+"_amount"].focus();
	          return false;
	        }
	        frm.elements[cnt[c]+"_amount"].value = frm.elements[cnt[c]+"_amount"].value.replace(",",".");
	        if (frm.elements[cnt[c]+"_date"].value.length>0 && !isDate(frm.elements[cnt[c]+"_date"].value,"d")) {
	          alert ("Payment date is not valid");
	          frm.elements[cnt[c]+"_date"].focus();
	          return false;
	        }
	      } // next
        return true;
      } // validate;

			function applyFilter(fid) {
			  document.location = "bookings_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_acourse=<%=gu_acourse%>&filter="+fid
			}
			
			function setCombos() {
        var frm = window.document.forms[0];
				setCombo(frm.sel_filter,"<% out.write(String.valueOf(iFilter)); %>");
			}
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">
  <DIV class="cxMnu1" style="width:220px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Course registrations&nbsp;<%=oAcrs.getString(DB.nm_course)%></FONT></TD></TR>
  </TABLE>
  <IMG SRC="../images/images/training/student16.gif" WIDTH="15" HEIGHT="18" BORDER="0"><A HREF="#" CLASS="linkplain" onclick="convertToAlumni()">Convert Registrations into Actual Course Students</A>
  <FORM NAME="" METHOD="post" ACTION="bookings_edit_store.jsp" onSubmit="return validate()">
      <FONT CLASS="textplain">Filter</FONT>&nbsp;
      <SELECT CLASS="combomini" NAME="sel_filter" onchange="applyFilter(this.options[this.selectedIndex].value)">
      <OPTION VALUE="1">List active bookings</OPTION>
      <OPTION VALUE="2">List confirmed students</OPTION>
      <OPTION VALUE="3">List not confirmed students</OPTION>  
      <OPTION VALUE="4">List students at waiting list</OPTION>
      <OPTION VALUE="5">List students who have already paid</OPTION>
      <OPTION VALUE="6">List students who still have not paid</OPTION>
      <OPTION VALUE="7">List only cancelled bookings</OPTION>
      <OPTION VALUE="0" SELECTED="selected">List All</OPTION>
      </SELECT>
      <BR/>
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_acourse" VALUE="<%=gu_acourse%>">
    <TABLE SUMMARY="Bookings">
      <TR>
        <TD CLASS="tableheader" NOWRAP><B>Name and Surname</B></TD>
        <TD CLASS="tableheader" NOWRAP><B>Waiting List</B></TD>
        <TD CLASS="tableheader"><B>Confirmed</B></TD>
        <TD CLASS="tableheader"><B>Paid</B></TD>
        <TD CLASS="tableheader"><B>Amount</B></TD>
        <TD CLASS="tableheader"><B>Date</B></TD>
        <TD CLASS="tableheader"><B>Cancelled</B></TD>
        <TD CLASS="tableheader"><B>Accepted</B></TD>
      </TR>
<% for (int b=0; b<iBooks; b++) {
     String sContactId = aBooks[b].getString(DB.gu_contact);
     oAlmni.replace(DB.gu_alumni, sContactId);
     out.write("<TR CLASS=\"strip"+String.valueOf((b%2)+1)+"\">\n");
     out.write("<TD NOWRAP>"+aCont[b].getStringNull(DB.tx_name,"")+"&nbsp;"+aCont[b].getStringNull(DB.tx_surname,"")+"</TD>\n");
     out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"checkbox\" NAME=\""+sContactId+"_waiting\" onclick=\"clickWaiting('"+sContactId+"')\" VALUE=\"1\" "+(aBooks[b].waiting() ? "CHECKED" : "")+"></TD>\n");
     out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"checkbox\" NAME=\""+sContactId+"_confirmed\" VALUE=\"1\" "+(aBooks[b].confirmed() ? "CHECKED" : "")+"></TD>\n");
     out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"checkbox\" NAME=\""+sContactId+"_paid\" onclick=\"clickPaid('"+sContactId+"')\" VALUE=\"1\" "+(aBooks[b].paid() ? "CHECKED" : "")+"></TD>\n");
     out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"text\" MAXLENGTH=\"10\" SIZE=\"5\" NAME=\""+sContactId+"_amount\" onfocus=\"if (!document.forms[0].elements['"+sContactId+"_paid'].checked) document.forms[0].elements['"+aBooks[b].getString(DB.gu_contact)+"_canceled'].focus();\" VALUE=\""+(aBooks[b].isNull(DB.im_paid) ? "" : oFmt2.format(aBooks[b].amount().doubleValue()))+"\"></TD>\n");
     out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"text\" MAXLENGTH=\"10\" SIZE=\"8\" NAME=\""+sContactId+"_date\" onfocus=\"if (!document.forms[0].elements['"+sContactId+"_paid'].checked) document.forms[0].elements['"+aBooks[b].getString(DB.gu_contact)+"_canceled'].focus();\" VALUE=\""+(aBooks[b].isNull(DB.dt_paid) ? "" : aBooks[b].getDateShort(DB.dt_paid))+"\"></TD>\n");
     out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"checkbox\" NAME=\""+sContactId+"_canceled\" VALUE=\"1\" onclick=\"clickCancel('"+sContactId+"')\" "+(aBooks[b].canceled() ? "CHECKED" : "")+"></TD>\n");
     if (null==aAlmni) {
       out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"hidden\" NAME=\"alumni_"+String.valueOf(b)+"\" VALUE=\""+0+"\"><A HREF=\"#\" onclick=\"switchAlumni('"+sContactId+"',"+String.valueOf(b)+")\"><IMG ID=\""+sContactId+"_buttonAlumni\" SRC=\"../images/images/pending.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\"></A></TD>\n");
     } else {
       boolean bIsAlumni = (Arrays.binarySearch(aAlmni, oAlmni, oAlmni)>=0);
       out.write("<!-- *** "+String.valueOf(Arrays.binarySearch(aAlmni, oAlmni, oAlmni))+" *** -->\n");
       out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"hidden\" NAME=\"alumni_"+String.valueOf(b)+"\" VALUE=\""+(bIsAlumni ? "1" : "0")+"\"><A HREF=\"#\" onclick=\"switchAlumni('"+sContactId+"',"+String.valueOf(b)+")\"><IMG ID=\""+sContactId+"_buttonAlumni\" SRC=\"../images/images/"+(bIsAlumni ? "corrected" : "pending")+".gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\"></A></TD>\n");
     }
     out.write("</TR>\n");
   } //next
%>
      <TR><TD COLSPAN="8"><HR></TD></TR>
      <TR>
        <TD COLSPAN="8" ALIGN="center">
          <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	  &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	</TD>
      </TR>
    </TABLE> 
  </FORM>
</BODY>
</HTML>
