<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");

  String sLanguage = getNavigatorLanguage(request);

  String sStatusLookUp = "", sPriorityLookUp = "", sResourceLookUp = "";
  
  String sProjectFilter = nullif(request.getParameter("projectfilter"),"p.id_status='ABIERTO'");
  
  String sStatusList = nullif(request.getParameter("statuslist"),"'PENDIENTE','APROBADA','APLAZADA','ENESPERA','PROPUESTA','ENDEFINICION','ENCURSO'");
  
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  JDCConnection oCon1 = null;

  DBSubset oProjects = new DBSubset(DB.k_projects, DB.gu_project+","+DB.nm_project,
  																								 DB.gu_owner+"=?  AND ("+DB.id_status + " IS NULL OR "+DB.id_status+"='ABIERTO') ORDER BY 2", 100);
  int iProjects = 0;

  DBSubset oResources = new DBSubset(DB.k_duties + " d," + DB.k_x_duty_resource + " x," + DB.k_duties_lookup + " l",
                                     "x." + DB.nm_resource + ",l." + DB.tr_ + sLanguage,
                                     "d." + DB.tx_status + " IN (" + sStatusList + ") AND " +
  																   "l." + DB.gu_owner + "=? AND d." + DB.gu_duty + "=x." + DB.gu_duty + " AND " +
  																   "x." + DB.nm_resource + "=l." + DB.vl_lookup + " AND " +
  																   "d." + DB.gu_writer + "=? " + " ORDER BY 2", 20);
  int iResources = 0;
  
  DBSubset oMyOwnDuties = new DBSubset (DB.k_duties + " d," + DB.k_projects + " p," + DB.k_duties_lookup + " l",
  																	    "p." + DB.nm_project + ",d." + DB.gu_duty + ",d." + DB.od_priority + "," +
  																	    "d." + DB.nm_duty + ",l." + DB.tr_ + sLanguage + ",d." + DB.pct_complete + "," +
  																	    DBBind.Functions.ISNULL + "(d." + DB.dt_end + ",d." + DB.dt_scheduled + ")",
  																	    (sProjectFilter.length()>0 ? sProjectFilter + " AND " : "") +
  																	    "d." + DB.tx_status + " IN (" + sStatusList + ") AND " +
  																      "p." + DB.gu_owner + "=? AND " +
  																	    "p." + DB.gu_owner + "=l." + DB.gu_owner + " AND l." + DB.id_section + "='tx_status' AND " +
  																	    "d." + DB.tx_status + "=l." + DB.vl_lookup + " AND " +
  																	    "d." +  DB.gu_project + "=p." + DB.gu_project + " AND (d." + DB.gu_writer + "=? OR "+
  																	    "EXISTS (SELECT x." + DB.gu_duty + " FROM " + DB.k_x_duty_resource + " x WHERE " +
  																	    "d." + DB.gu_duty + "=x." + DB.gu_duty + ")) ORDER BY 1", 50);

  DBSubset oByMeDuties = new DBSubset (DB.k_duties + " d," + DB.k_projects + " p," + DB.k_x_duty_resource + " x," + DB.k_duties_lookup + " l",
  																	   "p." + DB.nm_project + ",d." + DB.gu_duty + ",d." + DB.od_priority + "," +
  																	   "d." + DB.nm_duty + ",l." + DB.tr_ + sLanguage + ",d." + DB.pct_complete + "," +
  																	   DBBind.Functions.ISNULL + "(d." + DB.dt_end + ",d." + DB.dt_scheduled + ")",
  																	   (sProjectFilter.length()>0 ? sProjectFilter + " AND " : "") +
  																	   "d." + DB.tx_status + " IN (" + sStatusList + ") AND " +
  																	   "p." + DB.gu_owner + "=l." + DB.gu_owner + " AND l." + DB.id_section + "='tx_status' AND " +
  																	   "d." + DB.tx_status + "=l." + DB.vl_lookup + " AND " +
  																	   "d." + DB.gu_project + "=p." + DB.gu_project + " AND " +
  																	   "p." + DB.gu_owner + "=? AND d." + DB.gu_duty + "=x." + DB.gu_duty + " AND " +
  																	   "x." + DB.nm_resource + "=? AND d." + DB.gu_writer + "=? ORDER BY 1", 50);

  boolean bIsGuest = true;

  try {
  
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
       
    oCon1 = GlobalDBBind.getConnection("duty_resource");

		iProjects = oProjects.load(oCon1, new Object[]{sWorkArea});

    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.tx_status, sLanguage);
    sPriorityLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.od_priority, sLanguage);
    sResourceLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.nm_resource, sLanguage);
      
    iResources = oResources.load(oCon1, new Object[]{sWorkArea,sUserId});

  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("duty_resource");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  if (null==oCon1) return;
%>
<HTML LANG="<%=sLanguage%>">
  <HEAD>
    <TITLE>hipergate :: List of duties by resource</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript">
      <!--

      // ------------------------------------------------------

      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_duties_lookup&id_language=" + getUserLanguage() + "&id_section=nm_resource&tp_control=2&nm_control=sel_new_resource&nm_coding=nm_resource", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------
            
      function editDuty(guDuty) {
        window.open("duty_edit.jsp?gu_duty=" + guDuty, "editduty", "width=780,height=" + (screen.height<=600 ? "520" : "640"));
      }

      // ------------------------------------------------------
      
      function deleteDuties() {
        var frm = document.forms[0];
        if (confirm("Are you sure that you want  to delete the selected duties?")) {
          frm.action = "dutyedit_delete.jsp";
          frm.submit();
        } // fi(confirm)
      } // deleteDuties()

      // ------------------------------------------------------

      function updateDuties() {

    	  var frm = document.forms[0];
    	  var chi = frm.checkeditems;
    	  	  
    	  if (frm.sel_new_status.selectedIndex<=0 && frm.sel_new_priority.selectedIndex<=0 && frm.sel_new_completed.selectedIndex<=0 && frm.sel_new_resource.selectedIndex<=0) {
    	    alert ("An attribute to be updated must be selected");
    	    return false;
    	  }

    	  if (window.confirm("Are you sure that you want to update the selected duties?")) {

	        chi.value = "";
	        frm.action = "dutyedit_update.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");

	        for (var i=0;i<frm.elements.length; i++) {
    	      if (frm.elements[i].checked)
              chi.value += frm.elements[i].value + ",";
	        } // next()

	        if (chi.value.length>0) {
	          chi.value = chi.value.substr(0,chi.value.length-1);
            frm.nm_resource.value = (getCombo(frm.sel_new_resource)==null ? "" : getCombo(frm.sel_new_resource));
            frm.submit();
          } // fi(chi!="")
        } // fi (confirm)
      } // updateDuties()

      // ----------------------------------------------------
      
      function setCombos() {
        var frm = document.forms[0];        

        var copyOption = new Array();
        var optCount = frm.sel_new_priority.options.length;   
        for (var i=0; i<optCount; i++)   
          copyOption[i] = new Array(frm.sel_new_priority.options[i].value, frm.sel_new_priority.options[i].text);
        copyOption.sort(function(a,b) { return (a[0]-b[0]); });
        clearCombo (frm.sel_new_priority);      	
        for (var i=0; i<copyOption.length; i++)
          comboPush (frm.sel_new_priority, copyOption[i][1], copyOption[i][0], false, false)

			  setCombo(frm.projectfilter, "<%=sProjectFilter%>");
      } // setCombos      

      //-->
    </SCRIPT>
  </HEAD>
  <BODY  TOPMARGIN="0" MARGINHEIGHT="0" onload="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM NAME="frmDuties" METHOD="POST" ACTION="duty_resource.jsp">
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=nullif(request.getParameter("selected"),"4")%>">
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=nullif(request.getParameter("subselected"),"2")%>">
    <INPUT TYPE="hidden" NAME="checkeditems" VALUE="">
    <INPUT TYPE="hidden" NAME="nm_resource" VALUE="">

    <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">List of duties by resource</FONT></TD></TR></TABLE>
    <TABLE SUMMARY="Create and Delete Options" CELLSPACING="0" CELLPADDING="2">
      <TR><TD CLASS="textplain">Projects Filter&nbsp;<SELECT NAME="projectfilter" onchange="document.forms[0].submit()"><OPTION VALUE="">All Projects</OPTION><OPTION VALUE="p.id_status='ABIERTO'" SELECTED>Open projects only</OPTION><OPTGROUP LABEL="Only the Project "><% for (int p=0; p<iProjects; p++) out.write("<OPTION VALUE=\"p.gu_project='"+oProjects.getString(0,p)+"'\">"+oProjects.getString(1,p)+"</OPTION>"); %></OPTGROUP></SELECT></TD></TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD COLSPAN="8" ALIGN="left">
          <IMG SRC="../images/images/new16x16.gif" BORDER="0">&nbsp;
<% if (bIsGuest) { %>
          <A HREF="#" onClick="alert ('Your proviledge level as guest does not allow you to perform this action')" CLASS="linkplain">Create Duty</A>
<% } else { %>
          <A HREF="#" onClick="window.open('duty_new.jsp', 'newduty', 'menubar=no,toolbar=no,width=780,height=' + (screen.height<=600 ? '520' : '640'))" CLASS="linkplain">Create Duty</A>
<% } %>
          &nbsp;&nbsp;&nbsp;&nbsp;
          <IMG SRC="../images/images/refresh.gif" BORDER="0">&nbsp;<A HREF="#" onClick="document.forms[0].submit()" CLASS="linkplain">Update</A>
	  &nbsp;&nbsp;&nbsp;&nbsp;
          <IMG SRC="../images/images/papelera.gif" BORDER="0">&nbsp;
<% if (bIsGuest) { %>
          <A HREF="#" onClick="alert ('Your proviledge level as guest does not allow you to perform this action')" CLASS="linkplain">Delete selected duties</A>
<% } else { %>
          <A HREF="javascript:deleteDuties()" CLASS="linkplain">Delete selected duties</A>
<% } %>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    </TABLE>
    <TABLE SUMMARY="Duties by Resource" CELLPADDING="4" BORDER="1">
      <TR>
        <TD NOWRAP="NOWRAP" VALIGN="top">
        	<TABLE><%

	  int chkbox = 0;
    oMyOwnDuties.load(oCon1, new Object[]{sWorkArea,sUserId});
    int nDuties = oMyOwnDuties.getRowCount();
    
    String sLastProj = "";
    
    out.write("        	  <TR><TD COLSPAN=\"2\" CLASS=\"textstrong\">My Duties</TD></TR>");
    for (int d=0; d<nDuties; d++) {      
      if (!sLastProj.equals(oMyOwnDuties.getString(0,d))) {
        sLastProj = oMyOwnDuties.getString(0,d);
        out.write("<TR><TD COLSPAN=\"2\" CLASS=\"textstrong\">Project&nbsp;"+sLastProj+"</TD></TR>");
      }
      out.write("<TR><TD CLASS=\"textplain\">&nbsp;&nbsp;");
      if (!oMyOwnDuties.isNull(2,d)) out.write(String.valueOf(oMyOwnDuties.getShort(2,d))+"&nbsp;");
      out.write("<A HREF=\"#\" CLASS=\"linkplain\" onClick=\"javascript:editDuty('"+oMyOwnDuties.getString(1,d)+"')\">"+oMyOwnDuties.getString(3,d)+"</A> ("+oMyOwnDuties.getString(4,d));
      if (!oMyOwnDuties.isNull(5,d)) if (oMyOwnDuties.getShort(5,d)!=0) out.write("&nbsp;"+String.valueOf(oMyOwnDuties.getShort(5,d))+"%");
      out.write(") ");
      if (!oMyOwnDuties.isNull(6,d)) out.write(oMyOwnDuties.getDateFormated(6,d,oSimpleDate));
      out.write("</TD><TD><INPUT TYPE=\"checkbox\" NAME=\"chkbox"+String.valueOf(chkbox++)+"\" VALUE=\""+oMyOwnDuties.getString(1,d)+"\"></TD></TR>");
    } %>
          </TABLE>
        </TD>
<%
  int nCol = 1;
  for (int r=0; r<iResources; r++) {
    nDuties = oByMeDuties.load(oCon1, new Object[]{sWorkArea,oResources.getString(0,r),sUserId});
    if (nDuties>0) {
      sLastProj = "";
      out.write("        <TD VALIGN=\"top\">\n          <TABLE VALIGN=\"top\"><TR><TD COLSPAN=\"2\" NOWRAP=\"NOWRAP\" CLASS=\"textstrong\">" + oResources.getStringNull(1,r,"") + "</TD></TR>");
      for (int d=0; d<nDuties; d++) {      
        if (!sLastProj.equals(oByMeDuties.getString(0,d))) {
          sLastProj = oByMeDuties.getString(0,d);
          out.write("<TR><TD COLSPAN=\"2\" CLASS=\"textstrong\">Project&nbsp;"+sLastProj+"</TD></TR>");
        }
        out.write("<TR><TD CLASS=\"textplain\">&nbsp;&nbsp;");
        if (!oByMeDuties.isNull(2,d)) out.write(String.valueOf(oByMeDuties.getShort(2,d))+"&nbsp;");
        out.write("<A HREF=\"#\" CLASS=\"linkplain\" onClick=\"javascript:editDuty('"+oByMeDuties.getString(1,d)+"')\">"+oByMeDuties.getString(3,d)+"</A> ("+oByMeDuties.getString(4,d));
        if (!oByMeDuties.isNull(5,d)) if (oByMeDuties.getShort(5,d)!=0) out.write("&nbsp;"+String.valueOf(oByMeDuties.getShort(5,d))+"%");
        out.write(") ");
        if (!oByMeDuties.isNull(6,d)) out.write(oByMeDuties.getDateFormated(6,d,oSimpleDate));
        out.write("</TD><TD><INPUT TYPE=\"checkbox\" NAME=\"chkbox"+String.valueOf(chkbox++)+"\" VALUE=\""+oByMeDuties.getString(1,d)+"\"></TD></TR>");
      } // next
      out.write("</TABLE>\n        </TD>");
      nCol++;      
    } // fi

    if (nCol%2==0) { out.write("</TR>"); if (r<iResources-1) out.write("<TR>"); }
  } // next
  if (nCol==1) out.write("</TR>");
%>
    </TABLE>
	        <TABLE BORDER="0" SUMMARY="Massive Update">
            <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
	          <TR>
	            <TD CLASS="textsmall" COLSPAN="3">&nbsp;&nbsp;&nbsp;&nbsp;<B>Massive update options:</B></TD>
	          </TR>
	          <TR>
	            <TD CLASS="textsmall">&nbsp;&nbsp;&nbsp;&nbsp;Change to&nbsp;Status&nbsp;</TD>
	            <TD CLASS="textsmall">
	              <SELECT CLASS="combomini" NAME="sel_new_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;&nbsp;Priority<SELECT CLASS="combomini" NAME="sel_new_priority"><OPTION VALUE=""></OPTION><%=sPriorityLookUp%></SELECT>
	            </TD>
              <TD CLASS="textsmall">
                &nbsp;&nbsp;
                <FONT >Completed:&nbsp;<SELECT CLASS="combomini" NAME="sel_new_completed"><OPTION VALUE=""></OPTION><% for (int c=0;c<=100;c+=10) out.write("<OPTION VALUE=\""+String.valueOf(c)+"\">"+String.valueOf(c)+"%</OPTION>"); %></SELECT>
	            </TD>
	          </TR>
	          <TR>
	            <TD CLASS="textsmall">
	              &nbsp;&nbsp;&nbsp;&nbsp;Assign to &nbsp;
	            </TD>
	            <TD>
	              <SELECT CLASS="combomini" NAME="sel_new_resource" onchange="setCombo(document.forms[0].sel_resource,this.options[this.selectedIndex].value);document.forms[0].nm_resource.value=this.options[this.selectedIndex].value;"><OPTION VALUE=""></OPTION><%=sResourceLookUp%></SELECT>
	              &nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Add resources"></A>
	            </TD>
	            <TD COLSPAN="2" ALIGN="right">
                <A HREF="javascript:updateDuties()" CLASS="linkplain">Change</A>
	            </TD>
	          </TR>
	        </TABLE>
	        <INPUT TYPE="hidden" NAME="nu_duties" VALUE="<%=String.valueOf(chkbox)%>">
  </FORM>
  </BODY>
</HTML>
<% oCon1.close("duty_resource"); %>
<%@ include file="../methods/page_epilog.jspf" %>