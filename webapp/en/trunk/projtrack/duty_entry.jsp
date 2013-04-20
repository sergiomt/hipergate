<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/projtrack.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%

/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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

  final int NU_DUTIES = 20;
  
  String sSkin = getCookie(request, "skin", "xp");
  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");

  String sLanguage = getNavigatorLanguage(request);

  String gu_project = nullif(request.getParameter("gu_project"));

  String sStatusLookUp = "", sTypeLookUp = "";
  
  JDCConnection oCon1 = null;

  DBSubset oMyOpenProjects = new DBSubset(DB.k_projects + " p," + DB.k_duties + " d," + DB.k_x_duty_resource + " x",
  																			  "DISTINCT(p." + DB.gu_project + "),p." + DB.nm_project,
																		      "p." + DB.gu_project + "=d." + DB.gu_project + " AND " +
																		      "d." + DB.gu_duty + "=x." + DB.gu_duty + " AND " +
  																			  "p." + DB.gu_owner+"=?  AND (p."+DB.id_status + " IS NULL OR p."+DB.id_status+"='ABIERTO') ORDER BY 2", 10);
  int iMyOpenProjects = 0;

  DBSubset oOpenProjects = new DBSubset(DB.k_projects, DB.gu_project+","+DB.nm_project,  																								 
  																			DB.gu_owner+"=?  AND ("+DB.id_status + " IS NULL OR "+DB.id_status+"='ABIERTO') ORDER BY 2", 100);
  int iOpenProjects = 0;

  DBSubset oOpenDuties = new DBSubset (DB.k_duties + " d",
  																		 DB.gu_duty+","+DB.nm_duty+","+DB.gu_writer+","+DB.dt_created+","+DB.dt_modified+","+
  																		 DB.dt_start+","+DB.dt_scheduled+","+DB.dt_end+","+DB.ti_duration+","+DB.od_priority+","+
  																		 DB.gu_contact+","+DB.tx_status+","+DB.pct_complete+","+DB.pr_cost+","+DB.tp_duty+","+
  																		 DB.de_duty+","+DB.tx_comments,
  																		 DB.gu_project+"=? AND " + DB.tx_status + " NOT IN ('CANCELADA','TERMINADA','RECHAZADA') AND ("+
  																		 DB.gu_writer +"=? OR EXISTS (SELECT NULL FROM "+DB.k_x_duty_resource+" x WHERE x."+
  																		 DB.gu_duty+"=d."+DB.gu_duty+" AND x."+DB.nm_resource+"=?))", 100);
  int iOpenDuties = 0;
  boolean bIsGuest = true;
  boolean bIsAdmin = false;  

  try {
  
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
       
    oCon1 = GlobalDBBind.getConnection("duty_entry");

		iMyOpenProjects = oMyOpenProjects.load(oCon1, new Object[]{sWorkArea});

		iOpenProjects = oOpenProjects.load(oCon1, new Object[]{sWorkArea});

		if (gu_project.length()>0) iOpenDuties = oOpenDuties.load(oCon1, new Object[]{gu_project, sUserId, sUserId});
		
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.tx_status, sLanguage);

    sTypeLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.tp_duty, sLanguage);

    oCon1.close("duty_entry");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("duty_entry");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  if (null==oCon1) return;
  oCon1=null;
%>
<HTML LANG="<%=sLanguage%>">
  <HEAD>
    <TITLE>hipergate :: Work Reports / Duty Entry</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
        function chkActivProj() {
          if (document.forms[0].gu_project.selectedIndex<=0) {
				    alert ("A project to which associate the duties is required");
						document.forms[0].gu_project.focus();
						return false;
          } else {
            return true;
          }// fi
        } // chkActivProj

        // --------------------------------------------------------------------
              
        function setCombos() {
        	var frm = document.forms[0];
        	setCombo(frm.gu_project, "<%=gu_project%>");
<%        for (int o=0; o<iOpenDuties; o++) {
					  out.write("        	setCombo(frm.sel_type"+String.valueOf(o)+", \""+oOpenDuties.getStringNull(14,o,"")+"\");\n");
					  out.write("        	setCombo(frm.sel_status"+String.valueOf(o)+", \""+oOpenDuties.getStringNull(11,o,"")+"\");\n");
					  if (!oOpenDuties.isNull(12,o)) out.write("        	setCombo(frm.sel_pct_complete"+String.valueOf(o)+", \""+String.valueOf(oOpenDuties.getShort(12,o))+"\");\n");
        	} // next %>
        } // setCombos

        // --------------------------------------------------------------------

        function validate() {
          
          var frm = document.forms[0];
          
          if (!chkActivProj()) return false;
          
          if (frm.de_workreport.value.length>2000) {
            alert ("Work Report briefing may not exceed 2000 characters");
						frm.de_workreport.focus();            
						return false;
          }
          
          for (var i=0; i<<%=String.valueOf(NU_DUTIES)%>; i++) {
            var s = String(i);
            if (frm.elements["nm_duty"+s].value.length>0) {
              if (frm.elements["dt_start"+s].value.length>0 && !isDate(frm.elements["dt_start"+s].value,"d")) {
						    alert ("The date format must be yyyy-mm-dd");
						    frm.elements["dt_start"+s].focus();
						    return false;
              }
              if (frm.elements["dt_end"+s].value.length>0 && !isDate(frm.elements["dt_end"+s].value,"d")) {
						    alert ("The date format must be yyyy-mm-dd");
						    frm.elements["dt_end"+s].focus();
						    return false;
              }
              if (isDate(frm.elements["dt_start"+s].value,"d") && isDate(frm.elements["dt_end"+s].value,"d") &&
                  parseDate(frm.elements["dt_end"+s].value,"d")<parseDate(frm.elements["dt_start"+s].value,"d")) {
						      alert ("End date must be later than start date");
						      frm.elements["dt_end"+s].focus();
						      return false;                  
						  }
						  if (frm.elements["pr_cost"+s].value.length>0 && !isFloatValue(frm.elements["pr_cost"+s].value)) {
						      alert ("The cost/hours is not a valid figure");
						      frm.elements["dt_end"+s].focus();
						      return false;                  						  	
						  }
            } else if (frm.elements["dt_start"+s].value.length>0  || frm.elements["dt_end"+s].value.length>0 ||
            					 frm.elements["sel_type"+s].selectedIndex>0 || frm.elements["sel_status"+s].selectedIndex>0) {
						  alert ("Duty description is required");
						  frm.elements["nm_duty"+s].focus();
						  return false;
            }
          } // next
          return true;
        }
      //-->
    </SCRIPT>
  </HEAD>
  <BODY TOPMARGIN="0" MARGINHEIGHT="0" onload="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM NAME="frmDuties" METHOD="POST" ACTION="duty_entry_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=nullif(request.getParameter("selected"),"4")%>">
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=nullif(request.getParameter("subselected"),"3")%>">
    <INPUT TYPE="hidden" NAME="nm_resource" VALUE="<%=sUserId%>">
    <INPUT TYPE="hidden" NAME="nu_duties" VALUE="<%=String.valueOf(NU_DUTIES+iOpenDuties)%>">
    <INPUT TYPE="hidden" NAME="gu_workreport" VALUE="<%=Gadgets.generateUUID()%>">

    <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Work Reports / Duty Entry</FONT></TD></TR></TABLE>
    <TABLE SUMMARY="Project" CELLSPACING="0" CELLPADDING="2">
      <TR>
        <TD CLASS="textplain">Project&nbsp;<SELECT NAME="gu_project" onchange="document.location='duty_entry.jsp?selected='+getURLParam('selected')+'&subselected='+getURLParam('subselected')+'&gu_project='+this.options[this.selectedIndex].value"><OPTION VALUE=""></OPTION><OPTGROUP LABEL="My Open projects"></OPTION><% for (int p=0; p<iMyOpenProjects; p++) out.write("<OPTION VALUE=\""+oMyOpenProjects.getString(0,p)+"\">"+oMyOpenProjects.getString(1,p)+"</OPTION>"); %> %><OPTGROUP LABEL="All Open Projects"><% for (int p=0; p<iOpenProjects; p++) out.write("<OPTION VALUE=\""+oOpenProjects.getString(0,p)+"\">"+oOpenProjects.getString(1,p)+"</OPTION>"); %></OPTGROUP></SELECT></TD>
        <TD><% if (gu_project.length()>0) out.write("<A HREF=\"duty_entry_list.jsp?gu_project="+gu_project+"&selected="+nullif(request.getParameter("selected"),"4")+"&subselected="+nullif(request.getParameter("subselected"),"3")+(bIsAdmin ? "" : "&gu_writer="+sUserId)+"\" CLASS=\"linkplain\">List of previous work reports</A>"); %></TD>
      </TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    </TABLE>
<% if (gu_project.length()>0) { %>   
    <TABLE SUMMARY="New Duties" CELLSPACING="1" CELLPADDING="0">
      <TR>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Type</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Duty Name</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Start</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>End</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Cost/Hours</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Status</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Completed</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Additional Comments</B></TD>
      </TR>
<% String s;
   for (int i=0; i<iOpenDuties; i++) {
     s = String.valueOf(i);
%>
      <TR>
        <TD><INPUT TYPE="hidden" NAME="gu_duty<%=s%>" VALUE="<%=oOpenDuties.getString(0,i)%>"><SELECT NAME="sel_type<%=s%>" CLASS="combomini" onFocus="chkActivProj()"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT></TD>
        <TD><INPUT TYPE="text" NAME="nm_duty<%=s%>" MAXLENGTH="50" SIZE="40" CLASS="combomini" onFocus="chkActivProj()" VALUE="<%=oOpenDuties.getStringNull(1,i,"")%>"></TD>
        <TD><INPUT TYPE="text" NAME="dt_start<%=s%>" MAXLENGTH="10" SIZE="12" CLASS="combomini" onFocus="chkActivProj()" VALUE="<% if (!oOpenDuties.isNull(5,i)) out.write(oOpenDuties.getDateShort(5,i)); %>"></TD>
        <TD><INPUT TYPE="text" NAME="dt_end<%=s%>" MAXLENGTH="10" SIZE="12" CLASS="combomini" onFocus="chkActivProj()" VALUE="<% if (!oOpenDuties.isNull(7,i)) out.write(oOpenDuties.getDateShort(7,i)); %>"></TD>
        <TD ALIGN="center"><INPUT TYPE="text" NAME="pr_cost<%=s%>" MAXLENGTH="10" SIZE="12" CLASS="combomini" onFocus="chkActivProj()" VALUE="<% if (!oOpenDuties.isNull(13,i)) out.write(String.valueOf(oOpenDuties.getFloat(13,i))); %>"></TD>
        <TD><SELECT NAME="sel_status<%=s%>" CLASS="combomini" onFocus="chkActivProj()"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT></TD>
        <TD ALIGN="center"><SELECT NAME="sel_pct_complete<%=s%>" CLASS="combomini" onFocus="chkActivProj()"><OPTION VALUE="0">0%</OPTION><OPTION VALUE="10">10%</OPTION><OPTION VALUE="20">20%</OPTION><OPTION VALUE="30">30%</OPTION><OPTION VALUE="40">40%</OPTION><OPTION VALUE="50">50%</OPTION><OPTION VALUE="60">60%</OPTION><OPTION VALUE="70">70%</OPTION><OPTION VALUE="80">80%</OPTION><OPTION VALUE="90">90%</OPTION><OPTION VALUE="100" SELECTED="selected">100%</OPTION></SELECT></TD>
        <TD><INPUT TYPE="text" NAME="tx_comments<%=s%>" MAXLENGTH="1000" SIZE="50" CLASS="combomini" onFocus="chkActivProj()" VALUE="<%=oOpenDuties.getStringNull(DB.tx_comments,i,"")%>"></TD>
      </TR>
<% } %>

<% for (int i=0; i<NU_DUTIES; i++) {
     s = String.valueOf(i+iOpenDuties);
%>
      <TR>
        <TD><INPUT TYPE="hidden" NAME="gu_duty<%=s%>" VALUE=""><SELECT NAME="sel_type<%=s%>" CLASS="combomini" onFocus="chkActivProj()"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT></TD>
        <TD><INPUT TYPE="text" NAME="nm_duty<%=s%>" MAXLENGTH="50" SIZE="40" CLASS="combomini" onFocus="chkActivProj()"></TD>
        <TD><INPUT TYPE="text" NAME="dt_start<%=s%>" MAXLENGTH="10" SIZE="12" CLASS="combomini" onFocus="chkActivProj()"></TD>
        <TD><INPUT TYPE="text" NAME="dt_end<%=s%>" MAXLENGTH="10" SIZE="12" CLASS="combomini" onFocus="chkActivProj()"></TD>
        <TD ALIGN="center"><INPUT TYPE="text" NAME="pr_cost<%=s%>" MAXLENGTH="10" SIZE="12" CLASS="combomini" onFocus="chkActivProj()"></TD>
        <TD><SELECT NAME="sel_status<%=s%>" CLASS="combomini" onFocus="chkActivProj()"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT></TD>
        <TD ALIGN="center"><SELECT NAME="sel_pct_complete<%=s%>" CLASS="combomini" onFocus="chkActivProj()"><OPTION VALUE="0">0%</OPTION><OPTION VALUE="10">10%</OPTION><OPTION VALUE="20">20%</OPTION><OPTION VALUE="30">30%</OPTION><OPTION VALUE="40">40%</OPTION><OPTION VALUE="50">50%</OPTION><OPTION VALUE="60">60%</OPTION><OPTION VALUE="70">70%</OPTION><OPTION VALUE="80">80%</OPTION><OPTION VALUE="90">90%</OPTION><OPTION VALUE="100" SELECTED="selected">100%</OPTION></SELECT></TD>
        <TD><INPUT TYPE="text" NAME="tx_comments<%=s%>" MAXLENGTH="1000" SIZE="50" CLASS="combomini" onFocus="chkActivProj()"></TD>
      </TR>
<% } %>
      <TR>
        <TD COLSPAN="2" VALIGN="top" ALIGN="right" CLASS="textstrong">Briefing and Notes</TD>
        <TD COLSPAN="6" ALIGN="left"><TEXTAREA NAME="de_workreport" ROWS="6" COLS="80"></TEXTAREA></TD>
      </TR>
      <TR>
        <TD COLSPAN="8" ALIGN="center"><BR><INPUT TYPE="submit" CLASS="pushbutton" VALUE="Save"></TD>
      </TR>
    </TABLE>
<% } %>   
  </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>