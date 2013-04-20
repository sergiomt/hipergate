<%@ page import="java.text.DecimalFormat,java.util.Arrays,java.util.Comparator,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.crm.Contact,com.knowgate.training.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  final class BookingContactComparator<AcademicCourseBooking> implements Comparator {
    public int compare(Object o1, Object o2) {
      com.knowgate.training.AcademicCourseBooking b1 = (com.knowgate.training.AcademicCourseBooking) o1;
      com.knowgate.training.AcademicCourseBooking b2 = (com.knowgate.training.AcademicCourseBooking) o2;
      String sFullName1 = b1.getStringNull(DB.tx_name,"")+" "+b1.getStringNull(DB.tx_surname,"");
      String sFullName2 = b2.getStringNull(DB.tx_name,"")+" "+b2.getStringNull(DB.tx_surname,"");
      return sFullName1.compareTo(sFullName2);
    }
	  public boolean equals(Object o) {
	    return this.equals(o);
	  }
  } 
    
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);

  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_acourse = request.getParameter("gu_acourse");
  boolean bPayInfo = nullif(request.getParameter("bo_payinfo"),"0").equals("1");
  int iFilter= Integer.parseInt(nullif(request.getParameter("filter"),"0"));

  JDCConnection oConn = null;
  AcademicCourse oAcrs = new AcademicCourse();
  int iBooks = 0;
  AcademicCourseBooking[] aBooks = null;
  AcademicCourseAlumni [] aAlmni = null;
  AcademicCourseAlumni oAlmni = new AcademicCourseAlumni(gu_acourse, null);
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
      PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.tx_name+","+DB.tx_surname+" FROM "+DB.k_contacts+" WHERE "+DB.gu_contact+"=?");
      for (int c=0; c<iBooks; c++) {
        oStmt.setString(1, aBooks[c].getString(DB.gu_contact));
        ResultSet oRSet = oStmt.executeQuery();
        oRSet.next();
        aBooks[c].put(DB.tx_name, oRSet.getString(1));
        aBooks[c].put(DB.tx_surname, oRSet.getString(2));
        oRSet.close();
      } // next
      oStmt.close();
      Arrays.sort(aBooks,new BookingContactComparator<AcademicCourseBooking>());
    }

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
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" >
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');

    var addrLayer;

    dynapi.onLoad(init);

		function init() { 
      addrLayer = new DynLayer();
      addrLayer.setWidth(300);
      addrLayer.setHeight(160);
      addrLayer.setZIndex(200);
      setCombos();
    }
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      var pr_acourse = "<% if (!oAcrs.isNull(DB.pr_acourse)) { out.write(oFmt2.format(oAcrs.getDecimal(DB.pr_acourse).doubleValue())); } %>";

      var cnt = new Array(<%
	      for (int b=0; b<iBooks; b++) {
          out.write((b>0 ? ",\"" : "\"")+aBooks[b].getString(DB.gu_contact)+"\"");
        }
        out.write(");\n"); %>

      // ----------------------------------------------------

      function viewAddrs(ev,gu,nm) {
        showDiv(ev,"../common/addr_layer.jsp?nm_company=" + escape(nm) + "&linktable=k_x_contact_addr&linkfield=gu_contact&linkvalue=" + gu);
        //open("../common/addr_layer.jsp?nm_company=" + escape(nm) + "&linktable=k_x_contact_addr&linkfield=gu_contact&linkvalue=" + gu);
      }

      // ----------------------------------------------------

	    function modifyContact(id) {
	      self.open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&gu_contact=" + id + "&face=edu", "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=760,height=660");
	    }	

      // ------------------------------------------------------

      function switchAlumni(gu,ix) {
  	    var req = createXMLHttpRequest();
        var frm = window.document.forms[0];
        var btn = document.getElementById(gu+"_buttonAlumni");
				var wit = frm.elements[gu+"_waiting"];
				var cnf = frm.elements[gu+"_confirmed"];
        var sta = frm.elements["alumni_"+String(ix)];
        if (sta.value=="0") {
          if (frm.elements[gu+"_canceled"].checked) {
            alert ("It is not possible to admit students whose registration has been cancelled");
          } else {
            sta.value = "1";
            wit.checked=false;
            cnf.checked=true;
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

			function clickConfirmed(gu,bo,al) {
        var frm = window.document.forms[0];
				var cnf = frm.elements[gu+"_confirmed"];
				var wit = frm.elements[gu+"_waiting"];
				var cnl = frm.elements[gu+"_canceled"];
				var alm = frm.elements["alumni_"+al];

				if (bo && cnl.checked) {
	  			cnf.checked=false;
	  			alert ("It is not posible to confirm cancelled inscriptions");
				  return false;
				}	

				if (!bo && alm.value=="1") {
	  			cnf.checked=true;
	  			alert ("It is not possible to unconfirm already accepted students");
				  return false;
				}	

				if (bo) wit.checked = false;
				wit.style.visibility=(bo ? "hidden" : "visible");				
			}

      // ------------------------------------------------------

      function clickWaiting(gu,bo) {
        var frm = window.document.forms[0];
				var cnf = frm.elements[gu+"_confirmed"];
				var cnl = frm.elements[gu+"_canceled"];
				var wit = frm.elements[gu+"_waiting"];
		
				if (wit.checked && cnl.checked) {	  
	  			wit.checked=false;
	  			alert ("It is not possible to put cancelled registrations into the waiting list");
				  return false;
				}	

				if (bo) cnf.checked = false;
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

      // ------------------------------------------------------

			function applyFilter(fid) {
			  document.location = "bookings_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_acourse=<%=gu_acourse%>&filter="+fid
			}

      // ------------------------------------------------------
			
			function setCombos() {
        var frm = window.document.forms[0];
				setCombo(frm.sel_filter,"<% out.write(String.valueOf(iFilter)); %>");
			}
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
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
      <INPUT TYPE="hidden" NAME="bo_payinfo" VALUE="<%=bPayInfo ? "1" : "0"%>">
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
      &nbsp;&nbsp;
      <A CLASS="linkplain" TARGET="_blank" HREF="bookings_edit_xls.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_acourse=<%=gu_acourse%>&filter=<%=iFilter%>">List as Excel</A>
      <BR/>
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_acourse" VALUE="<%=gu_acourse%>">
    <TABLE SUMMARY="Bookings">
      <TR>
        <TD CLASS="tableheader"></TD>
        <TD CLASS="tableheader" NOWRAP><B>Name and Surname</B></TD>
        <TD CLASS="tableheader" NOWRAP><B>Waiting List</B></TD>
        <TD CLASS="tableheader"><B>Confirmed</B></TD>
        <TD CLASS="tableheader"><B>Accepted</B></TD>
        <TD CLASS="tableheader"><B>Cancelled</B></TD>
<% if (bPayInfo) { %>
        <TD CLASS="tableheader"><B>Paid</B></TD>
        <TD CLASS="tableheader"><B>Amount</B></TD>
        <TD CLASS="tableheader"><B>Date</B></TD>
        <TD CLASS="tableheader"></TD>
<% } else { %>
        <TD CLASS="tableheader"><A CLASS=\"linkplain\" HREF="#" onclick="document.forms[0].bo_payinfo.value='1';document.forms[0].submit();">Show information about payments</A></TD>
<%} %>
      </TR>
<% for (int b=0; b<iBooks; b++) {
     String sContactId = aBooks[b].getString(DB.gu_contact);
     String sFullName = (aBooks[b].getStringHtml(DB.tx_name,"")+"&nbsp;"+aBooks[b].getStringHtml(DB.tx_surname,"")).replace((char)39,(char)32);
     
     oAlmni.replace(DB.gu_alumni, sContactId);
     boolean bCancelled = aBooks[b].canceled();
     boolean bIsAlumni;
     if (bCancelled) bIsAlumni=false; else if (null==aAlmni) bIsAlumni=false; else bIsAlumni = (Arrays.binarySearch(aAlmni, oAlmni, oAlmni)>=0);
     boolean bWaiting = (bCancelled ? false : aBooks[b].waiting());
     boolean bConfrimed = (bCancelled ? false : aBooks[b].confirmed());
     
     out.write("<TR CLASS=\"strip"+String.valueOf((b%2)+1)+"\">\n");
     out.write("<TD><A HREF=\"#\" onContextMenu='return false;' onClick='hideDiv();viewAddrs(event,\"" + sContactId + "\",\"" + sFullName + "\");return false'><IMG SRC=\"../images/images/theworld16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Show Addresses\"></A></TD>\n");
     out.write("<TD NOWRAP><A HREF=\"#\" onclick=\"modifyContact('"+sContactId+"')\">"+sFullName+"</A></TD>\n");
     out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"checkbox\" ID=\""+sContactId+"_waiting\" NAME=\""+sContactId+"_waiting\" onclick=\"clickWaiting('"+sContactId+"',this.checked)\" VALUE=\"1\" "+(bWaiting ? "CHECKED" : "")+" "+(bConfrimed || bIsAlumni || bCancelled ? "STYLE=\"visibility:hidden\"" : "" )+"></TD>\n");
     out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"checkbox\" ID=\""+sContactId+"_confirmed\" NAME=\""+sContactId+"_confirmed\" VALUE=\"1\" "+(bConfrimed ? "CHECKED" : "")+" onclick=\"clickConfirmed('"+sContactId+"',this.checked,'"+String.valueOf(b)+"')\"></TD>\n");
     if (null==aAlmni) {
       out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"hidden\" NAME=\"alumni_"+String.valueOf(b)+"\" VALUE=\""+0+"\"><A HREF=\"#\" onclick=\"switchAlumni('"+sContactId+"',"+String.valueOf(b)+")\"><IMG ID=\""+sContactId+"_buttonAlumni\" SRC=\"../images/images/pending.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\"></A></TD>\n");
     } else {
       out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"hidden\" NAME=\"alumni_"+String.valueOf(b)+"\" VALUE=\""+(bIsAlumni ? "1" : "0")+"\"><A HREF=\"#\" onclick=\"switchAlumni('"+sContactId+"',"+String.valueOf(b)+")\"><IMG ID=\""+sContactId+"_buttonAlumni\" SRC=\"../images/images/"+(bIsAlumni ? "corrected" : "pending")+".gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\"></A></TD>\n");
     }
     out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"checkbox\" NAME=\""+sContactId+"_canceled\" VALUE=\"1\" onclick=\"clickCancel('"+sContactId+"')\" "+(bCancelled ? "CHECKED" : "")+"></TD>\n");

     if (bPayInfo) {
       out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"checkbox\" NAME=\""+sContactId+"_paid\" onclick=\"clickPaid('"+sContactId+"')\" VALUE=\"1\" "+(aBooks[b].paid() ? "CHECKED" : "")+"></TD>\n");
       out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"text\" MAXLENGTH=\"10\" SIZE=\"5\" NAME=\""+sContactId+"_amount\" onfocus=\"if (!document.forms[0].elements['"+sContactId+"_paid'].checked) document.forms[0].elements['"+aBooks[b].getString(DB.gu_contact)+"_canceled'].focus();\" VALUE=\""+(aBooks[b].isNull(DB.im_paid) ? "" : oFmt2.format(aBooks[b].amount().doubleValue()))+"\"></TD>\n");
       out.write("<TD ALIGN=\"center\"><INPUT TYPE=\"text\" MAXLENGTH=\"10\" SIZE=\"8\" NAME=\""+sContactId+"_date\" onfocus=\"if (!document.forms[0].elements['"+sContactId+"_paid'].checked) document.forms[0].elements['"+aBooks[b].getString(DB.gu_contact)+"_canceled'].focus();\" VALUE=\""+(aBooks[b].isNull(DB.dt_paid) ? "" : aBooks[b].getDateShort(DB.dt_paid))+"\"></TD>\n");
     } else {
       out.write("<TD ALIGN=\"center\"><INPUT STYLE=\"visibility:hidden;\" TYPE=\"checkbox\" NAME=\""+sContactId+"_paid\" VALUE=\"1\" "+(aBooks[b].paid() ? "CHECKED" : ""));
       out.write("<INPUT TYPE=\"hidden\" NAME=\""+sContactId+"_amount\" VALUE=\""+(aBooks[b].isNull(DB.im_paid) ? "" : oFmt2.format(aBooks[b].amount().doubleValue()))+"\">");
       out.write("<INPUT TYPE=\"hidden\" NAME=\""+sContactId+"_date\" VALUE=\""+(aBooks[b].isNull(DB.dt_paid) ? "" : aBooks[b].getDateShort(DB.dt_paid))+"\"></TD>\n");
     }
	
     out.write("<TD ALIGN=\"center\"></TD>\n");
     out.write("</TR>\n");
   } //next
%>
      <TR><TD COLSPAN="8"><HR></TD></TR>
      <TR>
        <TD COLSPAN="8" ALIGN="center">
          <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	  &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="if (window.opener) window.close(); else window.history.back();">
    	</TD>
      </TR>
    </TABLE> 
  </FORM>
  <IFRAME name="addrIFrame" src="../common/blank.htm" width="0" height="0" border="0" frameborder="0"></IFRAME>
</BODY>
</HTML>
