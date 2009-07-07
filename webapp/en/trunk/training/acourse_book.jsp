<%@ page import="java.text.DecimalFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.training.AcademicCourse,com.knowgate.training.AcademicCourseBooking" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%!
  public AcademicCourseBooking seekContact(AcademicCourseBooking[] aBooks, String sGuContact) {
    AcademicCourseBooking oACBk = null;
    if (null!=aBooks) {
      for (int b=0; b<aBooks.length && null==oACBk; b++) {
        if (aBooks[b].getString(DB.gu_contact).equals(sGuContact)) {
          oACBk = aBooks[b];
        } // fi
      } // next
    } // fi (aBooks)
    return oACBk;
  } // seekContact
%><%
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
  
  String gu_acourse = request.getParameter("gu_acourse");
  String chckditems = request.getParameter("checkeditems");
  String gu_discard = request.getParameter("gu_discard");
  if (null!=gu_discard) chckditems = Gadgets.replace(Gadgets.replace(chckditems,gu_discard,""),",,",",");
  String alumnilist = "('"+Gadgets.replace(chckditems,",","','")+"')";

  JDCConnection oConn = null;
  AcademicCourseBooking oBook;
  AcademicCourseBooking[] aBook = null;
  AcademicCourse oAcrs = new AcademicCourse();
  DBSubset oList = new DBSubset(DB.k_contacts, DB.tx_name+","+DB.tx_surname+","+DB.gu_contact, DB.gu_contact+" IN "+alumnilist+" ORDER BY 1,2", 100);
  int nAlmn = 0;

  try {    
    oConn = GlobalDBBind.getConnection("acourse_book");
    oAcrs.load(oConn, new Object[]{gu_acourse});
    aBook = oAcrs.getAllBookings(oConn);
    nAlmn = oList.load(oConn);
    oConn.close("acourse_book");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("...");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Registrations</TITLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" DEFER="defer">
    <!--
      
      var pr_acourse = "<% if (!oAcrs.isNull(DB.pr_acourse)) { DecimalFormat oFmt2 = new DecimalFormat(); oFmt2.setMaximumFractionDigits(2); out.write(oFmt2.format(oAcrs.getDecimal(DB.pr_acourse).doubleValue())); } %>";

      // ------------------------------------------------------

      function remove(guid) {
 	      var frm = window.document.forms[0];
 	      frm.gu_discard.value = guid;
        frm.action = "acourse_book.jsp";
        frm.submit();
      }

      function validate() {
        var frm = window.document.forms[0];

	      if (frm.im_paid.value.length>0 && !isFloatValue(frm.im_paid.value.replace(",","."))) {
	        alert ("Paid amount is not valid");
	        return false;	
	      } else {
	        frm.im_paid.value = frm.im_paid.value.replace(",",".");
	      }

        if (frm.dt_paid.value.length>0 && !isDate(frm.frm.dt_paid.value, "d")) {
	        alert ("[~La fecha de pago no es válida~]");
	        return false;	
        }

				if (frm.im_paid.value.length>0) {
				  frm.bo_paid.checked = true;
				}

        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Add or modify course registrations</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="acourse_book_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_acourse" VALUE="<%=gu_acourse%>">
    <INPUT TYPE="hidden" NAME="chekeditems" VALUE="<%=chckditems%>">
    <INPUT TYPE="hidden" NAME="gu_discard" VALUE="<% if (aBook!=null) for (int d=0; d<aBook.length; d++) out.write((0==d ? "" : ",")+aBook[d].getString(DB.gu_contact)); %>">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Course</TD>
            <TD ALIGN="left" WIDTH="420" CLASS="formplain"><%=oAcrs.getString(DB.nm_course)%><% if (!oAcrs.isNull(DB.id_course)) out.write("&nbsp;("+oAcrs.getString(DB.id_course)+")"); %></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right"><INPUT TYPE="radio" NAME="bo_waiting" VALUE="0" CHECKED></TD>
            <TD ALIGN="left" WIDTH="420" CLASS="formplain">Reserved</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right"><INPUT TYPE="radio" NAME="bo_waiting" VALUE="1"></TD>
            <TD ALIGN="left" WIDTH="420" CLASS="formplain">Waiting List</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right"><INPUT TYPE="checkbox" NAME="bo_confirmed" VALUE="1"></TD>
            <TD ALIGN="left" WIDTH="420" CLASS="formplain">Confirmed</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right"><INPUT TYPE="checkbox" NAME="bo_paid" VALUE="1" onclick="if (this.checked) { if (document.forms[0].im_paid.value.length==0) document.forms[0].im_paid.value=pr_acourse; if (document.forms[0].dt_paid.value.length==0) document.forms[0].dt_paid.value=dateToString(new Date(),'d'); } else { document.forms[0].im_paid.value=''; document.forms[0].dt_paid.value=''; }"></TD>
            <TD ALIGN="left" WIDTH="420" CLASS="formplain">Paid&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="text" NAME="im_paid" MAXLENGTH="14" SIZE="10" VALUE="<% if (!oAcrs.isNull(DB.im_paid)) { DecimalFormat oFmt2 = new DecimalFormat(); oFmt2.setMaximumFractionDigits(2); out.write(oFmt2.format(oAcrs.getDecimal(DB.im_paid).doubleValue())); } %>">&nbsp;Amount&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="text" NAME="dt_paid" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oAcrs.isNull(DB.dt_paid)) out.write(oAcrs.getDateShort(DB.dt_paid)); %>">&nbsp;[~Fecha~]</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" ALIGN="right"></TD>
            <TD ALIGN="left" WIDTH="420" CLASS="formplain">[~Forma de pago~]&nbsp;<SELECT NAME="tp_biling"><OPTION VALUE=""></OPTION><OPTION VALUE="T">[~Transferencia~]</OPTION><OPTION VALUE="C">[~Cheque~]</OPTION><OPTION VALUE="M">[~Efectivo~]</OPTION><OPTION VALUE="A">[~Tarjeta de Crédito~]</OPTION></SELECT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Room</TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="id_classroom" MAXLENGTH="30" SIZE="30"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong" VALIGN="top">Students</TD>
            <TD ALIGN="left" WIDTH="420" CLASS="formplain">
	      <TABLE SUMMARY="Alumni List" WIDTH="100%" CLASS="formback">
	      
<% for (int a=0; a<nAlmn; a++) {
     oBook = seekContact(aBook, oList.getString(DB.gu_contact,a));
     if (null==oBook) {
       out.write("<TR CLASS=\"formfront\"><TD ALIGN=\"left\" CLASS=\"formplain\">"+oList.getStringNull(DB.tx_name,a,"")+"&nbsp;"+oList.getStringNull(DB.tx_surname,a,"")+"</TD>");
       out.write("<TD ALIGN=\"right\" WIDTH=\"128\"><A HREF=\"#\" CLASS=\"linkplain\" TITLE=\"Discard Student\" onclick=\"remove('"+oList.getString(DB.gu_contact,a)+"')\"><IMG SRC=\"../images/images/delete.gif\" WIDTH=\"13\" HEIGHT=\"13\" HSPACE=\"4\" BORDER=\"0\" ALT=\"Discard\">Discard</A></TD></TR>");
     } else {
       out.write("<TR CLASS=\"formback\"><TD ALIGN=\"left\" CLASS=\"formplain\">"+oList.getStringNull(DB.tx_name,a,"")+"&nbsp;"+oList.getStringNull(DB.tx_surname,a,"")+"</TD>");
       out.write("<TD ALIGN=\"right\" WIDTH=\"128\" CLASS=\"formplain\">");
       if (oBook.canceled())
         out.write("Cancelled");
       else if (oBook.paid())
         out.write("Paid");
       else if (oBook.confirmed())
         out.write("Confirmed");
       else if (oBook.waiting())
         out.write("Waiting");
       else
         out.write("Reserved");
       out.write("</TD></TR>");
     } // fi (oBook)
   } // next %>
	      </TABLE>
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
