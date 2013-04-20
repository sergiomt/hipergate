<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.Fellow,com.knowgate.hipergate.DBLanguages,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
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

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  String sTitleLookUp = "", sDeptLookUp = null, sDivLookUp = null, sLocLookUp = null, sCompLookUp = null;
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String chk_webmail = request.getParameter("chk_webmail");
  
  String id_user = getCookie (request, "userid", null);
  
  String gu_fellow = nullif(request.getParameter("gu_fellow"));
  boolean bHasPhoto = false;
  
  Fellow oObj = new Fellow();
  DBSubset oTitleLookUp = new DBSubset (DB.k_lu_fellow_titles, DB.de_title, DB.gu_workarea + "='" + gu_workarea + "' ORDER BY 1", 100);
  int iTitleCount;
  
  JDCConnection oConn = null;  
  
  boolean bIsGuest = true;
  boolean bIsAdmin = false;
  boolean bIsPwUsr = false;
  
  try {
  
    oConn = GlobalDBBind.getConnection("fellowedit");
    
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsPwUsr = WorkArea.isPowerUser(oConn, gu_workarea, id_user);
    bIsAdmin = WorkArea.isAdmin(oConn, gu_workarea, id_user)  || isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
    
    if (gu_fellow.length()>0) {
      
      if (oObj.load (oConn, new Object[]{gu_fellow}))      
        bHasPhoto = oObj.hasPhoto(oConn);
      else
        throw new SQLException ("Fellow " + gu_fellow + " not found at k_fellows table");
    }
    else {
      bHasPhoto = false;
    }
            
    sDeptLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_fellows_lookup, gu_workarea, DB.tx_dept, sLanguage);
    sDivLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_fellows_lookup, gu_workarea, DB.tx_division, sLanguage);
    sLocLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_fellows_lookup, gu_workarea, DB.tx_location, sLanguage);
    sCompLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_fellows_lookup, gu_workarea, DB.tx_company, sLanguage);

    iTitleCount = oTitleLookUp.load(oConn);

    oConn.close("fellowedit");
    
    for (int t=0; t<iTitleCount; t++)
      sTitleLookUp += "<OPTION VALUE=\"" + oTitleLookUp.getString(0,t) + "\">" + oTitleLookUp.getString(0,t) + "</OPTION>";

    oTitleLookUp = null;
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("fellowedit");
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
  <TITLE>hipergate :: Edit Employee</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_fellows_lookup&id_language=" + getUserLanguage() + "&id_section=de_title&tp_control=2&nm_control=sel_title&nm_coding=de_title", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_fellows_lookup&id_language=" + getUserLanguage() + "&id_section=tx_dept&tp_control=2&nm_control=sel_dept&nm_coding=tx_dept", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_fellows_lookup&id_language=" + getUserLanguage() + "&id_section=tx_division&tp_control=2&nm_control=sel_division&nm_coding=tx_division", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
            window.open("../common/lookup_f.jsp?nm_table=k_fellows_lookup&id_language=" + getUserLanguage() + "&id_section=tx_location&tp_control=2&nm_control=sel_location&nm_coding=tx_location", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 5:
            window.open("../common/lookup_f.jsp?nm_table=k_fellows_lookup&id_language=" + getUserLanguage() + "&id_section=tx_company&tp_control=2&nm_control=sel_company&nm_coding=tx_company", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------

      function lookupOrgTree() {
        window.open("org_nav_f.jsp", "organizationtree", "menubar=yes,toolbar=no,width=780,height=460");
      }
            
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	frm.de_title.value = getCombo(frm.sel_title);
	frm.tx_dept.value = getCombo(frm.sel_dept);
	frm.tx_division.value = getCombo(frm.sel_division);
	frm.tx_location.value = getCombo(frm.sel_location);
	frm.tx_company.value = getCombo(frm.sel_company);
	frm.tx_timezone.value = getCombo(frm.sel_timezone);

	if (frm.tx_email.length>0)
	  if (!check_email(frm.tx_email.value)) {
	    alert ("e-mail address is not valid");
	    return false;
	  }
     <% if (gu_fellow.length()>0 && bHasPhoto) { %>
        
          frm.remove_file.value = (frm.chk_remove.checked ? "1" : "0");
          
     <% } %>   
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_title,"<% out.write(oObj.getStringNull(DB.de_title,"")); %>");
        setCombo(frm.sel_dept,"<% out.write(oObj.getStringNull(DB.tx_dept,"")); %>");
        setCombo(frm.sel_division,"<% out.write(oObj.getStringNull(DB.tx_division,"")); %>");
        setCombo(frm.sel_location,"<% out.write(oObj.getStringNull(DB.tx_location,"")); %>");
        setCombo(frm.sel_company,"<% out.write(oObj.getStringNull(DB.tx_company,"")); %>");
        setCombo(frm.sel_timezone,"<% out.write(oObj.getStringNull(DB.tx_timezone,"")); %>");
        
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
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Employee</FONT></TD></TR>
  </TABLE>  
  <FORM ENCTYPE="multipart/form-data" NAME="" METHOD="post" ACTION="fellow_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_fellow" VALUE="<%=gu_fellow%>">
    <INPUT TYPE="hidden" NAME="id_user" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="chk_webmail" VALUE="<%=chk_webmail%>">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Employee Num</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="10" VALUE="<%=oObj.getStringNull(DB.id_ref,"")%>"></TD>
            <TD ROWSPAN="4"><IMG SRC="<%=(bHasPhoto ? "../servlet/HttpBLOBServlet?nm_field=tx_file&bin_field=bin_file&nm_table=k_fellows_attach&pk_field=gu_fellow&pk_value=" + oObj.getString(DB.gu_fellow) : "../images/images/nofoto.gif")%>" WIDTH="120" HEIGHT="120" LOWRES="../images/images/spacer.gif" BORDER="0"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tx_name" MAXLENGTH="100" SIZE="30" VALUE="<%=oObj.getStringNull(DB.tx_name,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Surname:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tx_surname" MAXLENGTH="100" SIZE="30" VALUE="<%=oObj.getStringNull(DB.tx_surname,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Position:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <SELECT NAME="sel_title"><OPTION VALUE=""></OPTION><% out.write(sTitleLookUp); %></SELECT><INPUT TYPE="hidden" NAME="de_title" MAXLENGTH="50">
              &nbsp;<A HREF="javascript:lookupOrgTree()"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Corporate Chart Tree"></A>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Company:</FONT></TD>
            <TD ALIGN="left" COLSPAN="2">
              <TABLE WIDTH="100%">
                <TR>
                  <TD>
                    <SELECT NAME="sel_company" STYLE="width:180px"><OPTION VALUE=""></OPTION><%=sCompLookUp%></SELECT>
                    <INPUT TYPE="hidden" NAME="tx_company" VALUE="<%=oObj.getStringNull(DB.tx_company,"")%>">
              	    <A HREF="javascript:lookup(5)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Company Listing"></A>
                  </TD>
                  <TD ALIGN="right">
                    <INPUT TYPE="file" NAME="bin_file">
                  </TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Division:</FONT></TD>
            <TD ALIGN="left" COLSPAN="2">
              <TABLE WIDTH="100%" CELLSPACING="0" CELLPADDING="0">
                <TR>
                  <TD ALIGN="left">
                    <SELECT NAME="sel_division"><OPTION VALUE=""></OPTION><%=sDivLookUp%></SELECT><INPUT TYPE="hidden" NAME="tx_division" MAXLENGTH="50" SIZE="10">
                    &nbsp;<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Division Listing"></A>
                  </TD>
                  <TD ALIGN="right">
<% if (gu_fellow.length()>0 && bHasPhoto) { %>
                    <IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0">&nbsp;<INPUT TYPE="checkbox" NAME="chk_remove" VALUE="1">&nbsp;<FONT CLASS="formplain">Remove Image</FONT>
                    <INPUT TYPE="hidden" NAME="remove_file">
<% } %>
                  </TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Department:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <SELECT NAME="sel_dept"><OPTION VALUE=""></OPTION><%=sDeptLookUp%></SELECT><INPUT TYPE="hidden" NAME="tx_dept" MAXLENGTH="50" SIZE="10">
              &nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Department Listing"></A>
            </TD>
            <TD></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Location:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <SELECT NAME="sel_location"><OPTION VALUE=""></OPTION><%=sLocLookUp%></SELECT><INPUT TYPE="hidden" NAME="tx_location" MAXLENGTH="50" SIZE="10">
              &nbsp;<A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Location List"></A>
            </TD>
            <TD></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140">
              <FONT CLASS="formplain">Telephones:</FONT>
            </TD>
            <TD ALIGN="left" COLSPAN="2">
              <TABLE BGCOLOR="#E5E5E5">
                <TR>
                  <TD><FONT CLASS="textsmall">Fixed</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="work_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oObj.getStringNull(DB.work_phone,"")%>"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Extension</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="ext_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oObj.getStringNull(DB.ext_phone,"")%>"></TD>
                </TR>
                <TR>
                  <TD><FONT CLASS="textsmall">Personal</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="home_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oObj.getStringNull(DB.home_phone,"")%>"></TD>              
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Mobile</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="mov_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oObj.getStringNull(DB.mov_phone,"")%>"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                </TR>
              </TABLE>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="tx_email" MAXLENGTH="100" SIZE="48" VALUE="<%=oObj.getStringNull(DB.tx_email,"")%>">
            </TD>
            <TD></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Time Zone:</FONT></TD>
            <TD>
              <INPUT TYPE="hidden" NAME="tx_timezone">
              <SELECT name="sel_timezone">
              <option value=""></option>
              <option value="-12:00" > GMT -12:00 Dateline : Eniwetok, Kwajalein, Fiji, New Zealand
              <option value="-11:00" > GMT -11:00 Samoa : Midway Island, Samoa
              <option value="-10:00" > GMT -10:00 Hawaiian : Hawaii
              <option value="-09:00" > GMT -09:00 Alaskan : Alaska              
              <option value="-08:00" > GMT -08:00 Pacific Time (U.S. & Canada)
              <option value="-07:00" > GMT -07:00 Mountain : Mountain Time (US & Can.)
              <option value="-06:00" > GMT -06:00 Central Time (U.S. & Canada), Mexico City
              <option value="-05:00" > GMT -05:00 Eastern Time (U.S & Can.), Bogota, Lima
              <option value="-04:00" > GMT -04:00 Atlantic Time (Canada), Caracas, La Paz
              <option value="-03:00" > GMT -03:00 Brasilia, Buenos Aires              
              <option value="-03:30" > GMT -03:30 Newfoundland
              <option value="-02:00" > GMT -02:00 Mid-Atlantic
              <option value="-01:00" selected> GMT -01:00 Azores : Azores, Cape Verde Is.
              <option value="00:00"  > GMT 0 Greenwich Mean Time : Dublin, Lisbon, London
              <option value="+01:00" > GMT +01:00 Western &amp; Central Europe
              <option value="+02:00" > GMT +02:00 East. Europe, Egypt, Finland, Israel, S. Africa
              <option value="+03:00" > GMT +03:00 Russia, Saudi Arabia, Nairobi
              <option value="+03:30" > GMT +03:30 Iran              
              <option value="+04:00" > GMT +04:00 Arabian : Abu Dhabi, Muscat
              <option value="+05:00" > GMT +05:00 West Asia : Islamabad, Karachi
              <option value="+05:30" > GMT +05:30 India : Bombay, New Delhi
              <option value="+06:00" > GMT +06:00 Central Asia : Almaty, Dhaka, Colombo
              <option value="+07:00" > GMT +07:00 Bangkok, Hanoi, Jakarta
              <option value="+08:00" > GMT +08:00 China, Singapore, Taiwan, W. Australia
              <option value="+09:00" > GMT +09:00 Korea, Japan
              <option value="+09:30" > GMT +09:30 Cen. Australia : Adelaide
              <option value="+10:00" > GMT +10:00 E. Australia : Brisbane, Vladivostok, Guam              
              <option value="+11:00" > GMT +11:00 Central Pacific : Magadan, Sol. Is.
              </SELECT>            
            </TD>
            <TD></TD>
          </TR>
          <TR>
            <TD COLSPAN="3"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="3" ALIGN="center">
<% if (!bIsAdmin && !bIsPwUsr) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your priviledge level as guest does not allow you to perform this action')">&nbsp;
<% } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
<% } %>
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>