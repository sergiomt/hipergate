<%@ page import="java.io.File,java.util.Properties,java.text.SimpleDateFormat,java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*,com.knowgate.hipergate.DBLanguages,com.knowgate.dataxslt.StylesheetCache,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/projtrack.jspf" %><%@ include file="templates.jspf" %>
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

  final String sSep = File.separator;

  String sSkin = getCookie(request, "skin", "xp");
  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");
  String sIdDomain = getCookie(request,"domainid","");
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  int nDuties = Integer.parseInt(request.getParameter("nu_duties"));

  String sLanguage = getNavigatorLanguage(request);
  
  JDCConnection oCon1 = null;
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd");
  HashMap oStatusMap = null;
  Project oPrj = new Project();
  String aGuids[] = new String[nDuties];
  boolean bIsGuest = true;
  boolean bIsAdmin = false;

  DutiesWorkReport oDwr1 = new DutiesWorkReport();

  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

    oCon1 = GlobalDBBind.getConnection("duty_entry_store");

    oStatusMap = DBLanguages.getLookUpMap(oCon1, DB.k_duties_lookup, sWorkArea, "tx_status", sLanguage);

    oPrj.load(oCon1, request.getParameter("gu_project"));


		if (!DBCommand.queryExists(oCon1, DB.k_duties_lookup, DB.gu_owner+"='"+sWorkArea+"' AND "+DB.id_section+"='nm_resource' AND "+DB.vl_lookup+"='"+sUserId+"'")) {
		  ACLUser oUsr = new ACLUser(oCon1,sUserId);
		  String sFullName = (oUsr.getStringNull(DB.nm_user,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")).trim();
		  HashMap oUserName = new HashMap(DBLanguages.SupportedLanguages.length*2);
		  for (int l=DBLanguages.SupportedLanguages.length-1; l<=0; l--)
		    oUserName.put(DBLanguages.SupportedLanguages[l], sFullName);
			DBLanguages.addLookup (oCon1, DB.k_duties_lookup, sWorkArea, "nm_resource", sUserId, oUserName);		  
		} // fi

	  if (!oDwr1.load(oCon1, new Object[]{request.getParameter("gu_workreport")})) {
      oCon1.setAutoCommit (false);
      oDwr1.put(DB.gu_workreport, request.getParameter("gu_workreport"));
      oDwr1.put(DB.gu_project, request.getParameter("gu_project"));
      oDwr1.put(DB.gu_writer, sUserId);
      if (request.getParameter("de_workreport").length()>0)
        oDwr1.put(DB.de_workreport, request.getParameter("de_workreport"));
    
      for (int d=0; d<nDuties; d++) {
        Duty oDut1 = new Duty();
        oDut1.put(DB.gu_project, request.getParameter("gu_project"));
        oDut1.put(DB.gu_writer, sUserId);

        String s = String.valueOf(d);
        String sGuDuty = request.getParameter("gu_duty"+s);
        String sNmDuty = request.getParameter("nm_duty"+s);
        if (sNmDuty.length()>0) {

          if (sGuDuty.length()>0) oDut1.load(oCon1, new Object[]{sGuDuty});

          String sDtStart = request.getParameter("dt_start"+s);
          String sDtEnd = request.getParameter("dt_end"+s);
          String sPrCost = request.getParameter("pr_cost"+s);
          String sTxStatus = request.getParameter("sel_status"+s);
          String sPctComp = request.getParameter("sel_pct_complete"+s);
          String sTxComm = request.getParameter("tx_comments"+s);
        
          oDut1.replace(DB.nm_duty, sNmDuty);
          if (sDtStart.length()>0) oDut1.replace(DB.dt_start, sDtStart, oFmt);
          if (sDtEnd.length()>0) oDut1.replace(DB.dt_end, sDtEnd, oFmt);
          if (sPrCost.length()>0) oDut1.replace(DB.pr_cost, Float.parseFloat(sPrCost));
          if (sTxStatus.length()>0) oDut1.replace(DB.tx_status, sTxStatus);
          if (sPctComp.length()>0) oDut1.replace(DB.pct_complete, Short.parseShort(sPctComp));
          if (sTxComm.length()>0) oDut1.replace(DB.tx_comments, sTxComm);
          oDut1.store(oCon1);
          oDwr1.addDuty(oDut1);
          aGuids[d] = oDut1.getString(DB.gu_duty);
          if (sGuDuty.length()==0)
			      DBCommand.executeUpdate(oCon1, "INSERT INTO " + DB.k_x_duty_resource + "(" + DB.gu_duty + "," + DB.nm_resource + ") VALUES ('" + aGuids[d] + "', '" + sUserId + "')");
        } // fi
      } // next
		  oDwr1.store(oCon1, sLanguage);
      oCon1.commit();
    } // fi

    
    oCon1.close("duty_entry_store");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("duty_entry_store");
        oCon1 = null;
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));    
  }
  if (null==oCon1) return;
  oCon1=null;

  String sXslPath = getXSLTemplatePath(sStorage,sIdDomain,sWorkArea,request.getParameter("gu_project"),"dutieslist.xsl");
  
  if (sXslPath==null)
    throw new java.io.FileNotFoundException("Cannot find dutieslist.xsl template file at storage " + sStorage + " for WorkArea " + sWorkArea + " of Domain " + sIdDomain + " nor at " + sStorage+"xslt"+sSep+"templates"+sSep+"Projtrack"+sSep+"dutieslist.xsl");

	String sDutiesDataTable = null;
  try {
    sDutiesDataTable = StylesheetCache.transform(sXslPath, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"+oDwr1.toXML(), new Properties());
  } catch (Exception e) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));      
  }
  if (null==sDutiesDataTable) return;
%>
<HTML LANG="<%=sLanguage%>">
  <HEAD>
    <TITLE>hipergate :: Work Reports / Duties recently added</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--

      // ------------------------------------------------------
            
      function editDuty(guDuty) {
        window.open("duty_edit.jsp?gu_duty=" + guDuty, "editduty", "width=780,height=" + (screen.height<=600 ? "520" : "640"));
      }

      //-->
    </SCRIPT>
  </HEAD>
  <BODY TOPMARGIN="0" MARGINHEIGHT="0">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM NAME="frmDutiesWorkReport" METHOD="POST">
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=nullif(request.getParameter("selected"),"4")%>">
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=nullif(request.getParameter("subselected"),"3")%>">
    <INPUT TYPE="hidden" NAME="nm_resource" VALUE="<%=sUserId%>">

    <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Work Reports / Duties recently added</FONT></TD></TR></TABLE>
    <TABLE SUMMARY="Project" CELLSPACING="0" CELLPADDING="2">
      <TR><TD CLASS="textplain" COLSPAN="4">Project&nbsp;<%=oPrj.getString(DB.nm_project)%></TD></TR>
      <TR>
      	<TD><IMG SRC="../images/images/new16x16.gif" BORDER="0"></TD>
				<TD><A HREF="duty_entry.jsp?selected=<%=nullif(request.getParameter("selected"),"4")%>&subselected=<%=nullif(request.getParameter("subselected"),"3")%>" CLASS="linkplain">Enter more duties</A>&nbsp;&nbsp;&nbsp;&nbsp;
      	<TD COLSPAN="2"></TD>
		  </TR>
      <TR>
      	<TD><IMG SRC="../images/images/printer16x16.gif" BORDER="0" ALT="Printable Version"></TD>
      	<TD><A HREF="duties_workreport_preview.jsp?gu_workreport=<%=oDwr1.getString(DB.gu_workreport)%>" target="_blank" CLASS="linkplain">Print friendly version</A></TD>
      	<TD><IMG SRC="../images/images/crm/history16.gif" BORDER="0" ALT="Other WorkReports"></TD>
				<% out.write("<TD><A HREF=\"duty_entry_list.jsp?gu_project="+request.getParameter("gu_project")+"&selected="+nullif(request.getParameter("selected"),"4")+"&subselected="+nullif(request.getParameter("subselected"),"3")+(bIsAdmin ? "" : "&gu_writer="+sUserId)+"\" CLASS=\"linkplain\">Listing of other work reports from the same project</A></TD>"); %>
		  </TR>
      <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    </TABLE>
    
    <TABLE SUMMARY="Newly Added Duties" CELLSPACING="1" CELLPADDING="0">
      <TR>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Duty Name</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Start</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>End</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Cost/hours</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Status</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Completed</B></TD>
      </TR>
<% out.write(sDutiesDataTable); %>
    </TABLE>
  </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>