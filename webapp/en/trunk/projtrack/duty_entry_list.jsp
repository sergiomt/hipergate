<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
  
  String sSkin = getCookie(request, "skin", "xp");
  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");

  String sLanguage = getNavigatorLanguage(request);

  String gu_project = nullif(request.getParameter("gu_project"));
  String gu_writer = nullif(request.getParameter("gu_writer"));
  String dt_created = nullif(request.getParameter("dt_created"));
  
  JDCConnection oCon1 = null;

	HashMap oWriters = null;
	HashMap oProjects = null;
	HashMap oDates = null;
	
  DBSubset oWorkReports = new DBSubset (DB.k_duties_workreports + " w," + DB.k_users + " u," + DB.k_projects + " p",
																			  "w."+DB.gu_workreport+",w."+DB.tl_workreport+",w."+DB.gu_writer+",u."+DB.nm_user+",u."+DB.tx_surname1+",u."+DB.tx_surname2+",u."+DB.nm_company+",w."+DB.dt_created+",w."+DB.gu_project+",p."+DB.nm_project+",w."+DB.tx_workreport,
  																		  "w."+DB.gu_writer+"=u."+DB.gu_user+" AND w."+DB.gu_project+"=p."+DB.gu_project+" AND p."+DB.gu_owner+"=? "+
																			  (dt_created.length()>0 ? " AND w."+DB.dt_created+" BETWEEN { ts '"+dt_created+" 00:00:00' } AND { ts '"+dt_created+" 23:59:59' } AND " : "")+
  																		  " AND p."+DB.gu_project+"=? " + (gu_writer.length()>0 ? " AND "+DB.gu_writer+"='"+gu_writer+"'" : "")+
  																		  " ORDER BY "+DB.dt_created+" DESC", 100);
  int iWorkReports = 0;
  boolean bIsAdmin = false;  

  try {
  
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
       
    oCon1 = GlobalDBBind.getConnection("duty_entry_list");

    iWorkReports = oWorkReports.load(oCon1, new Object[]{sWorkArea,gu_project});

	  oWriters = new HashMap(iWorkReports*2);
		oProjects = new HashMap(iWorkReports*2);
		oDates = new HashMap(iWorkReports*2);

    oCon1.close("duty_entry_list");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("duty_entry_list");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }

  if (null==oCon1) return;
  oCon1=null;

  StringBuffer oWritersSelect = new StringBuffer();
  StringBuffer oProjectsSelect = new StringBuffer();
  StringBuffer oDatesSelect = new StringBuffer();
  
	for (int w=0; w<iWorkReports; w++) {
	  if (!oWriters.containsKey(oWorkReports.getString(2,w))) {
	    oWriters.put(oWorkReports.getString(2,w),oWorkReports.getString(2,w));
	    oWritersSelect.append("<OPTION VALUE=\""+oWorkReports.getString(2,w)+"\">"+oWorkReports.getStringNull(3,w,"")+" "+oWorkReports.getStringNull(4,w,"")+" "+oWorkReports.getStringNull(5,w,"")+"</OPTION>");
	  }
	  if (!oProjects.containsKey(oWorkReports.getString(8,w))) {
	    oProjects.put(oWorkReports.getString(8,w),oWorkReports.getString(8,w));
	    oProjectsSelect.append("<OPTION VALUE=\""+oWorkReports.getString(8,w)+"\">"+oWorkReports.getStringNull(9,w,"")+"</OPTION>");
	  }
	  if (!oDates.containsKey(oWorkReports.getDateShort(7,w))) {
	    oDates.put(oWorkReports.getDateShort(7,w),oWorkReports.getDateShort(7,w));
	    oDatesSelect.append("<OPTION VALUE=\""+oWorkReports.getDateShort(7,w)+"\">"+oWorkReports.getDateShort(7,w)+"</OPTION>");
	  }
	} // next
%>
<HTML LANG="<%=sLanguage%>">
  <HEAD>
    <TITLE>hipergate :: Work Reports</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
        <%

          out.write("var jsWorkReports = new Array(");
            
            for (int i=0; i<iWorkReports; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oWorkReports.getString(0,i) + "\"");
            }
  
          out.write(");\n        ");
        %>

        function selectAll() {          
          var frm = document.forms[0];          
          for (var c=0; c<jsWorkReportslength; c++)                        
            eval ("frm.elements['" + jsWorkReports[c] + "'].click()");
        } // selectAll()

        function setCombos() {
        	var frm = document.forms[0];
        	sortCombo(frm.gu_project);
        	setCombo (frm.gu_project, "<%=gu_project%>");
        	sortCombo(frm.dt_created);
        	setCombo (frm.dt_created, "<%=dt_created%>");
<% if (bIsAdmin) { %>
        	sortCombo(frm.gu_writer);
        	setCombo (frm.gu_writer, "<%=gu_writer%>");
<% } %>
        } // setCombos

      //-->
    </SCRIPT>
  </HEAD>
  <BODY TOPMARGIN="0" MARGINHEIGHT="0" onload="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM NAME="frmDuties" METHOD="POST" ACTION="duty_entry_delete.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=nullif(request.getParameter("selected"),"4")%>">
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=nullif(request.getParameter("subselected"),"3")%>">

    <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Work Reports</FONT></TD></TR></TABLE>
    <TABLE SUMMARY="Project" CELLSPACING="0" CELLPADDING="2">
      <TR>
        <TD CLASS="textplain">Project</TD>
        <TD><SELECT NAME="gu_project" onchange="document.location='duty_entry_list.jsp?selected='+getURLParam('selected')+'&subselected='+getURLParam('subselected')+'<%=(bIsAdmin ? "" : "&gu_writer="+sUserId)%>&gu_project='+this.options[this.selectedIndex].value"><OPTION VALUE=""></OPTION><%=oProjectsSelect.toString()%></SELECT></TD>
      </TR>
<% if (bIsAdmin) { %>
      <TR>
        <TD CLASS="textplain">Written by</TD>
        <TD><SELECT NAME="gu_writer" onchange="document.location='duty_entry_list.jsp?selected='+getURLParam('selected')+'&subselected='+getURLParam('subselected')+'&gu_writer='+this.options[this.selectedIndex].value"><OPTION VALUE=""></OPTION><%=oWritersSelect.toString()%></SELECT></TD>
      </TR>
<% } %>
      <TR>
        <TD CLASS="textplain">Date</TD>
        <TD><SELECT NAME="dt_created" onchange="document.location='duty_entry_list.jsp?selected='+getURLParam('selected')+'&subselected='+getURLParam('subselected')+'<%=(bIsAdmin ? "" : "&gu_writer="+sUserId)%>&dt_created='+this.options[this.selectedIndex].value"><OPTION VALUE=""></OPTION><%=oDatesSelect.toString()%></SELECT></TD>
      </TR>
      <TR>
        <TD ALIGN="right"><IMG SRC="../images/images/new16x16.gif" BORDER="0"></TD>
        <TD><A HREF="duty_entry.jsp?selected=<%=nullif(request.getParameter("selected"),"4")%>&subselected=<%=nullif(request.getParameter("subselected"),"3")%>" CLASS="linkplain">New Work Report</A></TD>
      </TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    </TABLE>
    <TABLE SUMMARY="WorkReports List" CELLSPACING="1" CELLPADDING="0">
      <TR>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Work Report</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Written by</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Date</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select All"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD></TR>
      </TR>
<%
   for (int i=0; i<iWorkReports; i++) {
     String sStrip = String.valueOf((i%2)+1);
%>
      <TR>      	
        <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="duties_workreport_preview.jsp?gu_workreport=<%=oWorkReports.getString(0,i)%>" TARGET="_blank" CLASS="linkplain"><%=oWorkReports.getStringNull(1,i,"")%></A></TD>
        <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oWorkReports.getStringNull(3,i,"")+" "+oWorkReports.getStringNull(4,i,"")+" "+oWorkReports.getStringNull(5,i,"")%></TD>
        <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oWorkReports.getDateTime24(7,i)%></TD>
        <TD CLASS="strip<% out.write (sStrip); %>"><INPUT TYPE="checkbox" VALUE="1" NAME="<%=oWorkReports.getString(0,i)%>"></TD>
      </TR>  
<% } %>
    </TABLE>
  </FORM>
</BODY>
</HTML>