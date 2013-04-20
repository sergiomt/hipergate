<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.training.ContactEducation" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "contact_education_edit";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_contact = request.getParameter("gu_contact");
  String gu_degree = request.getParameter("gu_degree");
  String sFullName = request.getParameter("fullname");

  String id_user = getCookie(request, "userid", "");

  ContactEducation oObj = new ContactEducation();
  
  String sTypeLookUp = "";
  DBSubset oDegreeTypes = new DBSubset(DB.k_education_degree, DB.tp_degree+","+DB.gu_degree+","+DB.nm_degree, DB.gu_workarea+"=? ORDER BY 1,3", 20);
  DBSubset oInstitutions= new DBSubset(DB.k_education_institutions, DB.gu_institution+","+DB.nm_institution,
                          DB.gu_workarea+"=? AND "+DB.bo_active+"<>0 ORDER BY 2", 20);
  int iInstitutions = 0;
  
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

    iInstitutions = oInstitutions.load(oConn, new Object[]{gu_workarea});

    int iDegreeTypes = oDegreeTypes.load(oConn, new Object[]{gu_workarea});
    String sPrevType = "";
    int nTyped = 0;
    for (int t=0; t<iDegreeTypes; t++) {
      if (!oDegreeTypes.isNull(0,t)) {
        if (!oDegreeTypes.getString(0,t).equals(sPrevType)) {
          if (sPrevType.length()>0) sTypeLookUp += "</OPTGROUP>"; 
          sTypeLookUp += "<OPTGROUP LABEL=\""+DBLanguages.getLookUpTranslation(oConn, DB.k_education_degree_lookup, gu_workarea, "tp_degree", sLanguage, oDegreeTypes.getString(0,t))+"\">"; 
          sPrevType = oDegreeTypes.getString(0,t);
        } // fi
        sTypeLookUp += "<OPTION VALUE=\""+oDegreeTypes.getString(1,t)+"\">"+oDegreeTypes.getString(2,t)+"</OPTION>";
        nTyped++;
      } // fi
    } // next
    if (sPrevType.length()>0) sTypeLookUp += "</OPTGROUP>"; 
    if (nTyped!=iDegreeTypes) {
      sTypeLookUp += "<OPTGROUP LABEL=\"Other qualifications\">"; 
      for (int t=0; t<iDegreeTypes; t++) {
        if (oDegreeTypes.isNull(0,t)) {
          sTypeLookUp += "<OPTION VALUE=\""+oDegreeTypes.getString(1,t)+"\">"+oDegreeTypes.getString(2,t)+"</OPTION>";
          sPrevType = oDegreeTypes.getString(0,t);
        } // fi
      } // next
      sTypeLookUp += "</OPTGROUP>"; 
    } // fi
     
    if (null!=gu_degree) oObj.load(oConn, new Object[]{gu_contact,gu_degree});
    
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Qualifications of&nbsp;<%=sFullName%></TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_education_degree_lookup&id_language=" + getUserLanguage() + "&id_section=tp_degree&tp_control=2&nm_control=sel_type&nm_coding=tp_degree", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

        if (frm.gu_degree.selectedIndex<=0) {
	        alert ("Qualification is required");
	        frm.gu_degree.focus();
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
        
        setCombo(frm.gu_degree,"<% out.write(oObj.getStringNull(DB.gu_degree,"")); %>");
        setCombo(frm.gu_institution,"<% out.write(oObj.getStringNull(DB.gu_institution,"")); %>");

<% if (!oObj.isNull(DB.bo_completed)) { %>
        setCheckedValue(frm.bo_completed,<% out.write(String.valueOf(oObj.getShort(DB.bo_completed))); %>);
<% } %>
        
        return true;
      } // validate;
    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE SUMMARY="Academic Degree" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Qualifications of&nbsp;<%=sFullName%></FONT></TD></TR>
  </TABLE>
  <FORM NAME="" METHOD="post" ACTION="contact_education_store.jsp">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="tx_fullname" VALUE="<%=sFullName%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Qualification</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <SELECT NAME="gu_degree"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT>&nbsp;
              <A HREF="../training/degree_lookup.jsp"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Edit Qualifications"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Completed</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">
            	<INPUT TYPE="radio" NAME="bo_completed" VALUE="1" CHECKED="checked">&nbsp;YesInst&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="bo_completed" VALUE="0">&nbsp;No
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Institution</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <SELECT NAME="gu_institution"><OPTION VALUE=""></OPTION><% for (int n=0; n<iInstitutions; n++) out.write("<OPTION VALUE=\""+oInstitutions.getString(0,n)+"\">"+oInstitutions.getString(1,n)+"</OPTION>"); %></SELECT>&nbsp;
              <A HREF="../training/institutions_lookup.jsp"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Edit Institutions"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Location</FONT></TD>
            <TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="nm_center" MAXLENGTH="50" SIZE="40" VALUE="<% out.write(oObj.getStringNull("nm_center","")); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">From</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain"><INPUT TYPE="text" NAME="tx_dt_from" MAXLENGTH="30" SIZE="10" VALUE="<% out.write(oObj.getStringNull("tx_dt_from","")); %>">&nbsp;&nbsp;&nbsp;To&nbsp;<INPUT TYPE="text" NAME="tx_dt_to" MAXLENGTH="30" SIZE="10" VALUE="<% out.write(oObj.getStringNull("tx_dt_to","")); %>"></TD>
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
