<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");  
  String sLanguage = getNavigatorLanguage(request);
  int iDomainId = Integer.parseInt(getCookie(request,"domainid","0"));
  String sFullName = "", sTxEMail = "";
    
  Project oPrj = null;
  JDCConnection oCon1 = null;
  ACLUser oMe = new ACLUser();
  DBSubset oPrjChlds = null;
  int iPrjChlds = 0;
  int iPrjRoot = 0;
  String sSeverityLookUp = null, sPriorityLookUp = null, sTypeLookUp = null, sVersionLookUp = null;
  boolean bIsAdmin = false;
  
  DBSubset oPrjRoots = new DBSubset(DB.k_projects,DB.gu_project + "," + DB.nm_project,DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_parent + " IS NULL ORDER BY 2", 10);

  try {
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
    
    oCon1 = GlobalDBBind.getConnection("bug_new");
   
    if (oMe.load(oCon1, new Object[]{sUserId})) {
      sFullName = oMe.getStringNull(DB.nm_user,"")+" "+oMe.getStringNull(DB.tx_surname1,"")+" "+oMe.getStringNull(DB.tx_surname2,"");
      sFullName = sFullName.trim().toUpperCase();
      sTxEMail = oMe.getStringNull(DB.tx_main_email,"");
    }
    
    sSeverityLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.od_severity, sLanguage);
    sPriorityLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.od_priority, sLanguage);
    sTypeLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.tp_bug, sLanguage);
    sVersionLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_bugs_lookup, sWorkArea, DB.vs_found, sLanguage);

    iPrjRoot = oPrjRoots.load(oCon1);
    
	  sendUsageStats(request, "bug_new");    
%>
<HTML>
  <HEAD>
    <TITLE>hipergate :: Report Incident</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
    <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');
      //-->
    </SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
      <!--
<%  if (bIsAdmin) { %>      
      function lookup(odctrl) {
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_bugs_lookup&id_language=" + getUserLanguage() + "&id_section=od_severity&tp_control=2&nm_control=sel_severity&nm_coding=od_severity", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_bugs_lookup&id_language=" + getUserLanguage() + "&id_section=od_priority&tp_control=2&nm_control=sel_priority&nm_coding=od_priority", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_bugs_lookup&id_language=" + getUserLanguage() + "&id_section=tp_bug&tp_control=2&nm_control=sel_type&nm_coding=tp_bug", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
            window.open("../common/lookup_f.jsp?nm_table=k_bugs_lookup&id_language=" + getUserLanguage() + "&id_section=vs_found&tp_control=2&nm_control=sel_found&nm_coding=vs_found", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()
<%  } %>
      // ------------------------------------------------------
      
      function validate() {
	var frm = window.document.forms[0];
	var str;

	if (frm.gu_project.options.selectedIndex<0) {
	  alert ("Must create at least one Project before reporting Incidents");
	  return false;
	}

	if (getCombo(frm.gu_project).length==0) {
	  alert ("Field Applies to is mandatory");
	  return false;
	}
	
	str = rtrim(frm.tl_bug.value);
	if (str.length==0) {
	  alert ("Subject is mandatory");
	  return false;
	}
	else
	  frm.tl_bug.value = str.toUpperCase();

	str = rtrim(frm.nm_reporter.value);
	if (str.length==0) {
	  alert ("Field Reported by is mandatory");
	  return false;
	}
	else
	  frm.nm_reporter.value = str.toUpperCase();

	str = rtrim(frm.tx_rep_mail.value);
	if (str.length==0) {
	  alert ("Contact e-mail is mandatory");
	  return false;
	}
	else if (str.indexOf("@")<0 || str.indexOf(".")<0) {
	  alert ("Mail address is not valid");
	  return false;	
	}
	else
	  frm.tx_rep_mail.value = str.toLowerCase();

	str = frm.tx_bug_brief.value;
	if (str.length==0) {
	  alert ("Incident description is mandatory");
	  return false;
	}

	if (str.length>2000) {
	  alert ("Incident description may not be longer than 2000 characters");
	  return false;
	}
	
	frm.od_severity.value = getCombo(frm.sel_severity);
	frm.od_priority.value = getCombo(frm.sel_priority);
	frm.tp_bug.value = getCombo(frm.sel_type);
	frm.vs_found.value = getCombo(frm.sel_found);
	
	return true;	
      }
      //-->
    </SCRIPT>
  </HEAD>
  <BODY >
    <TABLE WIDTH="90%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Report Incident</FONT></TD></TR></TABLE>  
    <BR><CENTER>
    <FORM NAME="frmReportBug" ENCTYPE="multipart/form-data" METHOD="post" ACTION="bugedit_store.jsp" onSubmit="return validate()">
      <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<% out.write(sUserId); %>">
      <INPUT TYPE="hidden" NAME="is_new" VALUE="1">
      <INPUT TYPE="hidden" NAME="tx_status" VALUE="">
      <TABLE SUMMARY="Alta de Incidencia" CLASS="formfront">
        <TR>
          <TD ALIGN="right"><FONT CLASS="formstrong">Subject</FONT></TD>
          <TD><INPUT TYPE="text" MAXLENGTH="250" NAME="tl_bug" SIZE="50" STYLE="text-transform:uppercase"></TD>
        </TR>
        <TR>
          <TD ALIGN="right"><FONT CLASS="formstrong">Type</FONT></TD>
          <TD><INPUT TYPE="hidden" NAME="tp_bug"><SELECT NAME="sel_type"><%=sTypeLookUp%></SELECT>
<%  if (bIsAdmin) { %>     
          &nbsp;<A HREF="#" onclick="lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View incident types"></A></TD>
<%  } %>
        </TR>
        <TR>
          <TD ALIGN="right"><FONT CLASS="formstrong">Applies to&nbsp;</FONT></TD>
          <TD><SELECT NAME="gu_project">
                    <%
                      oPrj = new Project();
                      
		      for (int r=0; r<iPrjRoot; r++) {
    		        
    		        oPrj.replace(DB.gu_project, oPrjRoots.getString(0,r));
    		        
    		        oPrjChlds = oPrj.getAllChilds(oCon1);
    		        iPrjChlds = oPrjChlds.getRowCount();
    		        
                        out.write("                      ");
                        out.write("<OPTION VALUE=\"" + oPrjRoots.getString(0,r) + "\">" + oPrjRoots.getString(1,r) + "</OPTION>");
                        for (int p=0;p<iPrjChlds; p++) {
                          if (oPrjChlds.getInt(2,p)>1) {
                            // Project GUIDs as values
                            out.write("<OPTION VALUE=\"" + oPrjChlds.getString(0,p) + "\">");
                            // Indent project names
                            for (int s=1;s<oPrjChlds.getInt(2,p); s++) out.write("&nbsp;&nbsp;&nbsp;&nbsp;");
                            // Project Names
                            out.write(oPrjChlds.getString(1,p));

                            out.write("</OPTION>");
                          } // fi (od_level>1)
                        } // next (p)
                                              
                      } // next (r)

                    out.write("\n");
                    %>
              </SELECT>
          </TD>
        </TR>
        <TR>
          <TD ALIGN="right"><FONT CLASS="formstrong">Version</FONT></TD>
          <TD>
            <INPUT TYPE="hidden" NAME="vs_found">
            <SELECT NAME="sel_found"><OPTION VALUE=""></OPTION><%=sVersionLookUp%></SELECT>
<%  if (bIsAdmin) { %>     
              &nbsp;<A HREF="#" onclick="lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A>
<%  } %>
    	  </TD>
    	</TR>
        <TR>
          <TD ALIGN="right"><FONT CLASS="formstrong">Severity</FONT></TD>
          <TD><INPUT TYPE="hidden" NAME="od_severity">
              <SELECT NAME="sel_severity"><%=sSeverityLookUp%></SELECT>
<%  if (bIsAdmin) { %>     
              &nbsp;<A HREF="#" onclick="lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A>
<%  } %>
              &nbsp;&nbsp;&nbsp;&nbsp;
              <FONT CLASS="formstrong">Priority&nbsp;</FONT>
              <INPUT TYPE="hidden" NAME="od_priority">
	      <SELECT NAME="sel_priority"><%=sPriorityLookUp%></SELECT>
<% if (1025==iDomainId) { %>
	      &nbsp;<A HREF="#" onclick="lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A>
<% } %>
          </TD>
        </TR>
        <TR>
          <TD ALIGN="right"><FONT CLASS="formstrong">Reported by:</FONT></TD>
          <TD><INPUT TYPE="text" MAXLENGTH="50" NAME="nm_reporter" SIZE="36" STYLE="text-transform:uppercase" VALUE="<%=sFullName%>"></TD>
        </TR>
        <TR>
          <TD ALIGN="right"><FONT CLASS="formstrong">e-mail:</FONT></TD>
          <TD><INPUT TYPE="text" MAXLENGTH="100" NAME="tx_rep_mail" SIZE="36" STYLE="text-transform:lowercase" VALUE="<%=sTxEMail%>"></TD>
        </TR>
<!--
        <TR>
          <TD></TD>
          <TD ALIGN="left"><INPUT TYPE="checkbox" NAME="chk_send_mail" VALUE="1">&nbsp;<FONT CLASS="formplain">Send me a copy of this incident by e-mail</FONT></TD>
        </TR>
-->
        <TR>
          <TD ALIGN="right"><FONT CLASS="formstrong">Description:</FONT></TD>
          <TD>
            <TEXTAREA NAME="tx_bug_brief" rows="8" COLS="78" STYLE="font-family:Arial;font-size:9pt"></TEXTAREA>
          </TD>
        </TR>
        <TR>
          <TD ALIGN="right"><FONT CLASS="formstrong">Attached File 1:</FONT></TD>
          <TD>
	    <INPUT TYPE="file" NAME="bugfile1_<%=sUserId%>" SIZE="40">	    
          </TD>
        </TR>
        <TR>
          <TD COLSPAN="2"><HR></TD>
        </TR>
        <TR>
          <TD ALIGN="right"></TD>
          <TD ALIGN="center">
            <INPUT TYPE="submit" CLASS="pushbutton" ACCESSKEY="a" TITLE="ALT+a" VALUE="Send" STYLE="width:80">
            &nbsp;&nbsp;&nbsp;
            <INPUT TYPE="button" CLASS="closebutton" ACCESSKEY="c" TITLE="ALT+c" VALUE="Cancel" onClick="window.close()" STYLE="width:80">
            <BR>
          </TD>
        </TR>        
      </TABLE>
    </FORM>
    </CENTER>
  </BODY>
</HTML>
<%
    oCon1.close("bug_new");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("bug_new");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Database access error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }  
%>
<%@ include file="../methods/page_epilog.jspf" %>