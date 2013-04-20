<%@ page import="java.math.BigDecimal,com.knowgate.addrbook.Room,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  String sFace = nullif(request.getParameter("face"),getCookie(request,"face","crm"));
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String gu_user = getCookie (request, "userid", null);
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String nm_room = nullif(request.getParameter("nm_room"));
  
  String sCompanyLookUp = "";
  String sLocationLookUp = "";
  String sTpRoomLookUp = "";

  int iFareIdx = -1;
  
  Room oRoom = new Room();
  
  DBSubset oNextMeetings = new DBSubset (DB.k_x_meeting_room + " x," + DB.k_meetings + " m",
  																		   "m."+DB.gu_meeting+",m."+DB.dt_start+",m."+DB.tx_meeting,
  																		   "m."+DB.gu_meeting+"=x."+DB.gu_meeting+" AND "+
  																		   "m."+DB.id_domain+"=? AND m."+DB.gu_workarea+"=? AND "+
  																		   "x."+DB.nm_room+"=? AND m."+DB.dt_start+">"+DBBind.Functions.GETDATE+" AND "+
  																		   "(m."+DB.bo_private+"=0 OR m."+DB.gu_writer+"=?) ORDER BY 2",10);
  oNextMeetings.setMaxRows(10);
  int iNextMeetings = 0;
  
  JDCConnection oConn = GlobalDBBind.getConnection("roomedit");  
    
  try {
    
    sCompanyLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_rooms_lookup, gu_workarea, "tx_company", sLanguage);
    sLocationLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_rooms_lookup, gu_workarea, "tx_location", sLanguage);
    sTpRoomLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_rooms_lookup, gu_workarea, "tp_room", sLanguage);

    if (nm_room.length()>0) {
      oRoom.load(oConn, new Object[]{nm_room,gu_workarea});
    } else {
      oRoom.put(DB.id_domain, Integer.parseInt(id_domain));
      oRoom.put(DB.gu_workarea, gu_workarea);
      oRoom.put(DB.bo_available, (short)1);      
    }
    
    iNextMeetings = oNextMeetings.load(oConn, new Object[]{new Integer(id_domain), gu_workarea, nm_room, gu_user});
    
    oConn.close("roomedit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("roomedit");

    oConn = null;  

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
      
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }

  if (null==oConn) return;

  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Resource</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      var activity_edition_page = "<% out.write(sFace.equalsIgnoreCase("healthcare") ? "appointment_edit_f.htm" : "meeting_edit_f.htm"); %>";

      // ------------------------------------------------------
      
      function modifyMeeting(gu) {
        window.open(activity_edition_page+"?id_domain=<%=id_domain%>&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=<%=gu_workarea%>&gu_fellow=" + getCookie("userid") + "&gu_meeting=" + gu, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
      }

      // ------------------------------------------------------
              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_rooms_lookup&id_language=" + getUserLanguage() + "&id_section=tx_location&tp_control=2&nm_control=sel_location&nm_coding=tx_location", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_rooms_lookup&id_language=" + getUserLanguage() + "&id_section=tx_company&tp_control=2&nm_control=sel_company&nm_coding=tx_company", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_rooms_lookup&id_language=" + getUserLanguage() + "&id_section=tp_room&tp_control=2&nm_control=sel_room&nm_coding=tp_room", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
      	var txt;
      
      	txt = rtrim(frm.nm_room.value.toUpperCase());
      
      	if (txt.length==0) {
      	  alert ("El nombre del recurso es obligatorio");
      	  return false;
      	}
      	frm.nm_room.value = txt;
      
      	if (hasForbiddenChars(txt)) {
      	  alert ("Resource Name contains invalid characters");
      	  return false;
      	}
      		
      	if (txt.indexOf("Ñ")>=0 || txt.indexOf("Ç")>=0 || txt.indexOf("Á")>=0 || txt.indexOf("É")>=0 || txt.indexOf("Í")>=0 || txt.indexOf("Ó")>=0 || txt.indexOf("Ú")>=0 || txt.indexOf("À")>=0 || txt.indexOf("È")>=0 || txt.indexOf("Ì")>=0 || txt.indexOf("Ò")>=0 || txt.indexOf("Ù")>=0 || txt.indexOf("Ä")>=0 || txt.indexOf("Ë")>=0 || txt.indexOf("Ï")>=0 || txt.indexOf("Ö")>=0 || txt.indexOf("Ü")>=0) {
      	  alert ("Resource Name contains invalid characters");
      	  return false;
      	}
      	
      	frm.bo_available.value = (frm.chk_available.checked ? "1" : "0");
      	frm.tp_room.value = getCombo(frm.sel_room);
      	frm.tx_location.value = getCombo(frm.sel_location);
      	frm.tx_company.value = getCombo(frm.sel_company);

				if (frm.tp_room.value.length==0) {
      	  alert ("The resource type is required");
      	  return false;
				}
        return true;
      } // validate;
      
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_location,"<% out.write(oRoom.getStringNull(DB.tx_location,"")); %>");
        setCombo(frm.sel_company,"<% out.write(oRoom.getStringNull(DB.tx_company,"")); %>");
        setCombo(frm.sel_room,"<% out.write(oRoom.getStringNull(DB.tp_room,"")); %>");
        
        return true;
      } // validate;
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Resource</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="room_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<% out.write(id_domain); %>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<% out.write(gu_workarea); %>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Available:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="hidden" MAXLENGTH="1" NAME="bo_available"><INPUT TYPE="checkbox" NAME="chk_available" VALUE="1" <% if (!oRoom.isNull(DB.bo_available)) if (oRoom.getShort(DB.bo_available)==1) out.write("CHECKED");%>></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="text" NAME="nm_room" MAXLENGTH="50" SIZE="55" STYLE="text-transform:uppercase" VALUE="<% out.write(nullif(nm_room)); %>" <% if (nm_room.length()>0) out.write("TABINDEX=\"-1\" onfocus=\"document.forms[0].sel_room.focus()\""); %>></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Resource Type:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="hidden" NAME="tp_room" MAXLENGTH="16" VALUE=""><SELECT NAME="sel_room"><OPTION VALUE=""></OPTION><%=sTpRoomLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Resource Types"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Location:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="hidden" NAME="tx_location" MAXLENGTH="50" SIZE="50" VALUE=""><SELECT NAME="sel_location"><OPTION VALUE=""></OPTION><%=sLocationLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Location List"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Company:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="hidden" NAME="tx_company" MAXLENGTH="50" SIZE="50" VALUE=""><SELECT NAME="sel_company"><OPTION VALUE=""></OPTION><%=sCompanyLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Companies List"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="text" NAME="tx_comments" MAXLENGTH="255" SIZE="70" VALUE="<% out.write(oRoom.getStringNull(DB.tx_comments,"")); %>"></TD>
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
        </TABLE>
      </TD></TR>
    </TABLE>         
  </FORM>
<% if (iNextMeetings>0) {
     out.write("Next commitments<BR>");
     for (int m=0; m<iNextMeetings; m++) {
       out.write("<FONT CLASS=\"textplain\">"+oNextMeetings.getDateShort(1,m)+"</FONT>&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"modifyMeeting('"+oNextMeetings.getString(0,m)+"')\">"+oNextMeetings.getStringNull(2,m,"")+"</A><BR>\n");
     } // next
   } // fi
%>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>