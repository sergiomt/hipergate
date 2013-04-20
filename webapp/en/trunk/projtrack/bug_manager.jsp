<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.ResultSet,java.sql.Timestamp,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%

  boolean bIsGuest = isDomainGuest (GlobalDBBind, request, response);
  String sSkin = getCookie(request, "skin", "xp");  

%><HTML>
  <HEAD>
    <TITLE>hipergate :: Project Management</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>  
    <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
      <!--        
        var sWorkArea;
        var sWorkDir;
                
        // Get workarea from URL
        sWorkArea = getCookie("workarea");
        sWorkDir = getCookie("path_workarea");
		                  
      //-->
    </SCRIPT>

    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
      <!--
      function reportBug() {
        self.open("bug_new.jsp",null,"menubar=no,toolbar=no,width=700,height=520");
      }
      
      // ------------------------------------------------------
      
      function searchBug() {
        
        var frm = document.forms[0];
        var sSearched = frm.nm_bug.value;
        
        if (sSearched.length>0) {
          if (isIntValue(sSearched)) {
            frm.tl_bug.value = "";
            frm.pg_bug.value = sSearched;
          }
	  else {
            frm.tl_bug.value = sSearched.toUpperCase();
            frm.pg_bug.value = "";
          }	  
        }
        frm.action = "bug_list.jsp"
        frm.submit();
      }
      
      // ------------------------------------------------------

      function newProject() {
        window.open("prj_new.jsp", "newproject", "menubar=no,toolbar=no,width=780,height=520");       
      }

      // ------------------------------------------------------

      function searchProject() {
        window.location = "project_listing.jsp?field=nm_project&find=" + document.forms[0].nm_project.value.toUpperCase() + "&selected=4&subselected=0";
      }
      
      // ------------------------------------------------------

      function newDuty() {
        window.open("duty_new.jsp", "newduty", "menubar=no,toolbar=no,width=780,height=" + (screen.height<=600 ? "520" : "640"));
      }

      // ------------------------------------------------------

      function editBug(guBug) {
        window.open("bug_edit.jsp?gu_bug=" + guBug, guBug, "width=780,height=480");
      }

      // ------------------------------------------------------

      function editDuty(guDuty) {
        window.open("duty_edit.jsp?gu_duty=" + guDuty, "editduty", "width=780,height=" + (screen.height<=600 ? "520" : "640"));
      }

      // ------------------------------------------------------

      function searchDuty() {
        var frm = document.forms[0];
		
	frm.where.value = " AND b.nm_duty <%=DBBind.Functions.ILIKE%> '%" + frm.nm_duty.value.toUpperCase() + "%' ";
        frm.action = "duty_list.jsp"
        frm.submit();
      }
      
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  TOPMARGIN="0" MARGINHEIGHT="0">
  <%@ include file="../common/tabmenu.jspf" %>
  <FORM>
  <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Project Management</FONT></TD></TR></TABLE>  
  <TABLE>
    <TR>
      <TD VALIGN="top">
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <!-- Espacio entre la barra de título y la tabla -->
          <TR>
            <TD COLSPAN="3"><IMG SRC="../images/images/spacer.gif" HEIGHT="8" WIDTH="1" BORDER="0"></TD>
          </TR>
<% if (((iAppMask & (1<<ProjectManager))!=0)) { %>
          <!-- Pestaña superior -->
          <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD BACKGROUND="../images/images/graylinebottom.gif">
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
                  <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
      	          <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_24x24.gif" WIDTH="24" HEIGHT="24" BORDER="0"></TD>
      	        </TR>
                <TR>
            	  <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" COLSPAN="2" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">Projects</TD>
                </TR>
              </TABLE>
            </TD>
            <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea gris y roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Proyectos -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">
              <TABLE CELLSPACING="8" BORDER="0">
                <TR>
                  <TD ROWSPAN="2">
                    <A HREF="project_listing.jsp?selected=4&subselected=0"><IMG SRC="../images/images/projtrack/projects.gif" BORDER="0" ALT="Projects"></A>
                  </TD>
                  <TD>
        	      <INPUT TYPE="text" NAME="nm_project" MAXLENGTH="50" STYLE="text-transform:uppercase">            
                  </TD>
                  <TD>
                    <A HREF="javascript:searchProject();" CLASS="linkplain">Find Project</A>
                  </TD>
                </TR>
      	  <TR>
                  <TD></TD>
                  <TD>
      <% if (bIsGuest) { %>
                    <A HREF="#" onclick="alert ('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New Project</A>
      <% } else { %>            
                    <A HREF="#" onclick="newProject()" CLASS="linkplain">New Project</A>
      <% } %>
                  </TD>
      	  </TR>	  
              </TABLE>
            </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
            <TD ><IMG SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
          </TR>
          <!-- Pestaña media -->
<% } else { %>
          <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD  BACKGROUND="../images/images/graylinetop.gif"></TD>
            <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
<% } if ((iAppMask & (1<<DutyManager))!=0) { %>
          <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD>
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
                  <TD COLSPAN="2" CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
      	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
      	  </TR>
                <TR>
            	  <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">Tasks</TD>
                </TR>
              </TABLE>
            </TD>
            <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Tareas -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">
              <TABLE CELLSPACING="8" BORDER="0">
                <TR>
                  <TD ROWSPAN="2">
                    <A HREF="duty_list.jsp?selected=4&subselected=1"><IMG SRC="../images/images/projtrack/duties.gif" BORDER="0" ALT="Tasks"></A>
                  </TD>
                  <TD>
        	      <INPUT TYPE="text" NAME="nm_duty" MAXLENGTH="50" STYLE="text-transform:uppercase">
                  </TD>
                  <TD>
                    <A HREF="javascript:searchDuty();" CLASS="linkplain">Find Duty</A>
                  </TD>
                </TR>
      	  <TR>
                  <TD></TD>
                  <TD>
      <% if (bIsGuest) { %>
                    <A HREF="#" onclick="alert ('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New Duty</A>
      <% } else { %>
                    <A HREF="#" onclick="newDuty()" CLASS="linkplain">New Duty</A>
      <% } %>
                  </TD>
      	  </TR>	  
              </TABLE>
            </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
            <TD ><IMG SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
          </TR>
          <!-- Pestaña media -->
<% } if (((iAppMask & (1<<BugTracker))!=0)) { %>         
          <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD>
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
                  <TD COLSPAN="2" CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
      	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
      	  </TR>
                <TR>
            	  <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">Incidents</TD>
                </TR>
              </TABLE>
            </TD>
            <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Incidencias -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">
              <TABLE CELLSPACING="8" BORDER="0">
                <TR>
                  <TD ROWSPAN="2">
                    <A HREF="bug_list.jsp?selected=4&subselected=2"><IMG SRC="../images/images/projtrack/bugs.gif" BORDER="0" ALT="Incidents"></A>
                  </TD>
                  <TD>
        	      <INPUT TYPE="text" NAME="nm_bug" MAXLENGTH="50" STYLE="text-transform:uppercase">
                  </TD>
                  <TD>
      	      <A HREF="javascript:searchBug();" CLASS="linkplain">Find Incident</A>
      	    </TD>
                </TR>
      	  <TR>
                  <TD></TD>
                  <TD>
      <% if (bIsGuest) { %>
                    <A HREF="#" onclick="alert ('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New Incident</A>
      <% } else { %>            
                    <A HREF="#" onclick="reportBug()" CLASS="linkplain">New Incident</A>
      <% } %>
                  </TD>
      	  </TR>	  
              </TABLE>
            </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>              
          <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
<% }  %>
          <!-- Línea gris -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle"><IMG SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0"></TD>
            <TD  BACKGROUND="../images/images/graylinefloor.gif"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0"></TD>
          </TR>
        </TABLE>
      </TD>
      <TD VALIGN="top">

        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <!-- Espacio entre la barra de título y la tabla -->
          <TR>
            <TD COLSPAN="3"><IMG SRC="../images/images/spacer.gif" HEIGHT="8" WIDTH="1" BORDER="0"></TD>
          </TR>
          <!-- Pestaña superior -->
<% if ((iAppMask & (1<<DutyManager))!=0) { %>
          <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD BACKGROUND="../images/images/graylinebottom.gif">
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
                  <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
      	          <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_24x24.gif" WIDTH="24" HEIGHT="24" BORDER="0"></TD>
      	        </TR>
                <TR>
            	  <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" COLSPAN="2" CLASS="subtitle" ALIGN="left" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">My Duties</TD>
                </TR>
              </TABLE>
            </TD>
            <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea gris y roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Mis Tareas -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">
<%
  JDCConnection oCon1 = null;
  int iDuties;
  DBSubset oDuties;
  
  try {
    Timestamp oToday00 = new Timestamp(new Date().getTime());
    oToday00.setHours(0); oToday00.setMinutes(0); oToday00.setSeconds(0);
    Timestamp oToday24 = new Timestamp(new Date().getTime());
    oToday24.setHours(23); oToday24.setMinutes(59); oToday24.setSeconds(59);
    
    oCon1 = GlobalDBBind.getConnection("myduties");

    oDuties = new DBSubset (DB.k_duties + " d," + DB.k_x_duty_resource + " x",
    				                "d." + DB.gu_duty + ",d." + DB.nm_duty + ",x." + DB.nm_resource,
    				                "d." + DB.gu_duty + "=x." + DB.gu_duty + " AND d." + DB.tx_status + " IN ('PENDIENTE','ENCURSO') AND d." + DB.dt_scheduled + " BETWEEN ? AND ? AND (x." + DB.nm_resource + "=? OR " + DB.gu_writer + "=?) ORDER BY d." + DB.od_priority + " DESC", 5);

    oDuties.setMaxRows(5);
    iDuties = oDuties.load(oCon1, new Object[]{oToday00,oToday24,sTabMenuUser,sTabMenuUser});

	  if (iDuties>0) {
      out.write("&nbsp;&nbsp;<FONT CLASS=\"textstrong\">To do today<BR></FONT>");
      for (int d=0; d<iDuties; d++) {
        out.write("&nbsp;&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"editDuty('" + oDuties.getString(0,d) + "')\">" + oDuties.getString(1,d) + "</A>");
			  if (!sTabMenuUser.equals(oDuties.getString(2,d)))
			    out.write("&nbsp;<FONT CLASS=\"textsmall\">("+DBLanguages.getLookUpTranslation(oCon1, DB.k_duties_lookup, sTabMenuWrkA, DB.nm_resource, getNavigatorLanguage(request), oDuties.getString(2,d))+")</FONT>");
        out.write("<BR>");
      }
	  }
    
    oDuties = new DBSubset (DB.k_duties + " d," + DB.k_x_duty_resource + " x",
    				                "d." + DB.gu_duty + ",d." + DB.nm_duty ,
    				                "d." + DB.gu_duty + "=x." + DB.gu_duty + " AND d." + DB.tx_status + " IN ('PENDIENTE','ENCURSO') AND d. " + DB.dt_scheduled + " NOT BETWEEN ? AND ? AND x." + DB.nm_resource + "=? ORDER BY d." + DB.od_priority + " DESC", 5);

    oDuties.setMaxRows(5);
    iDuties = oDuties.load(oCon1, new Object[]{oToday00,oToday24,sTabMenuUser});

	  if (iDuties>0) {
      out.write("&nbsp;&nbsp;<FONT CLASS=\"textstrong\">Assigned to me<BR></FONT>");
      for (int d=0; d<iDuties; d++) {
        out.write("&nbsp;&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"editDuty('" + oDuties.getString(0,d) + "')\">" + oDuties.getString(1,d) + "</A><BR>");
      }
	  }

    oDuties = new DBSubset (DB.k_duties + " d," + DB.k_x_duty_resource + " x",
    				                "d." + DB.gu_duty + ",d." + DB.nm_duty + ",x." + DB.nm_resource + ",d." + DB.tx_status,
    				                "d." + DB.gu_duty + "=x." + DB.gu_duty + " AND d." + DB.tx_status + " IN ('PENDIENTE','ENCURSO','ENESPERA') AND d." + DB.dt_scheduled + " NOT BETWEEN ? AND ? AND " + DB.dt_scheduled + ">=? AND x." + DB.nm_resource + "<>? AND d." + DB.gu_writer + "=? ORDER BY d." + DB.od_priority + " DESC", 5);

    oDuties.setMaxRows(5);
    iDuties = oDuties.load(oCon1, new Object[]{oToday00,oToday24,oToday24,sTabMenuUser,sTabMenuUser});

    out.write("&nbsp;&nbsp;<FONT CLASS=\"textstrong\">Assigned by me<BR></FONT>");

	  if (iDuties>0) {
      for (int d=0; d<iDuties; d++) {
        out.write("&nbsp;&nbsp;" + (oDuties.getStringNull(3,d,"").equals("ENESPERA") ? "<A HREF=\"#\" TITLE=\"Waiting Duty\"><IMG SRC=\"../images/images/projtrack/l_timer_off.gif\" WIDTH=\"16\" HEIGHT=\"15\" ALT=\"Waiting Duty\" BORDER=\"0\"></A>&nbsp;" : "") + "<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"editDuty('" + oDuties.getString(0,d) + "')\">" + oDuties.getString(1,d) + "</A>&nbsp;<FONT CLASS=\"textsmall\">("+DBLanguages.getLookUpTranslation(oCon1, DB.k_duties_lookup, sTabMenuWrkA, DB.nm_resource, getNavigatorLanguage(request), oDuties.getString(2,d))+")</FONT><BR>");
      }
	  }
    oDuties = new DBSubset (DB.k_duties + " d," + DB.k_x_duty_resource + " x",
    				                "d." + DB.gu_duty + ",d." + DB.nm_duty + ",x." + DB.nm_resource,
    				                "d." + DB.gu_duty + "=x." + DB.gu_duty + " AND d." + DB.tx_status + " IN ('PENDIENTE','ENCURSO','ENESPERA') AND d." + DB.dt_scheduled + " < ? AND x." + DB.nm_resource + "<>? AND d." + DB.gu_writer + "=? ORDER BY d." + DB.od_priority + " DESC", 5);

    oDuties.setMaxRows(5);
    iDuties = oDuties.load(oCon1, new Object[]{oToday24,sTabMenuUser,sTabMenuUser});

	  if (iDuties>0) {
      for (int d=0; d<iDuties; d++) {
        out.write("&nbsp;&nbsp;<A HREF=\"#\" TITLE=\"Delayed Duty\"><IMG SRC=\"../images/images/projtrack/l_clock.gif\" WIDTH=\"16\" HEIGHT=\"15\" ALT=\"Delayed Duty\" BORDER=\"0\"></A>&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"editDuty('" + oDuties.getString(0,d) + "')\">" + oDuties.getString(1,d) + "</A>&nbsp;<FONT CLASS=\"textsmall\">("+DBLanguages.getLookUpTranslation(oCon1, DB.k_duties_lookup, sTabMenuWrkA, DB.nm_resource, getNavigatorLanguage(request), oDuties.getString(2,d))+")</FONT><BR>");
      }
	  }

    oDuties = new DBSubset (DB.k_duties + " d",
    				                "d." + DB.gu_duty + ",d." + DB.nm_duty + ",d." + DB.tx_status,
    				                "d." + DB.gu_writer + "=? AND " + DB.dt_modified + " IS NOT NULL ORDER BY d." + DB.dt_modified + " DESC", 5);

    oDuties.setMaxRows(5);
    iDuties = oDuties.load(oCon1, new Object[]{sTabMenuUser});

	  if (iDuties>0) {
      out.write("&nbsp;&nbsp;<FONT CLASS=\"textstrong\">Recent changes<BR></FONT>");
      for (int d=0; d<iDuties; d++) {
        out.write("&nbsp;&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"editDuty('" + oDuties.getString(0,d) + "')\">" + oDuties.getString(1,d) + "</A>&nbsp;<FONT CLASS=\"textsmall\">("+DBLanguages.getLookUpTranslation(oCon1, DB.k_duties_lookup, sTabMenuWrkA, DB.tx_status, getNavigatorLanguage(request), oDuties.getString(2,d))+")</FONT><BR>");
      }
	  }
    
    oCon1.close("myduties");    
  }
  catch (SQLException e) {  
    if (oCon1!=null)
      if (!oCon1.isClosed()) oCon1.close("myduties");
    oCon1 = null;
    out.write ("SQLException: " + e.getMessage());
  }

%>
            </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <TR> 
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="12" BORDER="0"></TD>
            <TD ><IMG SRC="../images/images/spacer.gif" HEIGHT="12" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="12" BORDER="0"></TD>
          </TR>
<% } else { %>
          <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD BACKGROUND="../images/images/graylinetop.gif"></TD>
            <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" ><IMG SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
<% } if ((iAppMask & (1<<BugTracker))!=0) { %>
          <!-- Pestaña media -->
          <TR>  
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD>
              <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
                <TR>
                  <TD COLSPAN="2" CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"></TD>
      	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/<%=sSkin%>/tab/angle45_22x22.gif" WIDTH="22" HEIGHT="22" BORDER="0"></TD>
      	  </TR>
                <TR>
            	  <TD BACKGROUND="../skins/<%=sSkin%>/tab/tabback.gif" CLASS="subtitle" VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" HEIGHT="1" BORDER="0"><IMG SRC="../images/images/3x3puntos.gif" WIDTH="18" HEIGHT="10" ALT="3x3" BORDER="0">My Incidents</TD>
                </TR>
              </TABLE>
            </TD>
            <TD ALIGN="right" WIDTH="3px"  BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>
          <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
          <!-- Cuerpo de Mis Incidencias -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="menu1">
<%
  JDCConnection oCon2 = null;
  int iBugs = 0;

  DBSubset oBugs = new DBSubset (DB.k_bugs,
    				 DB.gu_bug + "," + DB.tl_bug,
    				 "(" + DB.tx_status + " IS NULL OR " + DB.tx_status + " IN ('EN ESPERA', 'ASIGNADO', 'VERIFICADO')) AND (" + DB.nm_assigned + "=? OR " + DB.tx_rep_mail + " IN (SELECT " + DB.tx_main_email + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?)) ORDER BY " + DB.od_priority + " DESC", 10);
  try {
    oCon2 = GlobalDBBind.getConnection("mybugs");
    
    oBugs.setMaxRows(10);
    
    iBugs = oBugs.load(oCon2, new Object[]{sTabMenuUser,sTabMenuUser});
    
    oCon2.close("mybugs");    
  }
  catch (SQLException e) {  
    if (oCon2!=null)
      if (!oCon2.isClosed()) oCon2.close("mybugs");
    oCon2 = null;
    out.write ("SQLException: " + e.getMessage());
  }

  for (int b=0; b<iBugs; b++) {
    out.write("&nbsp;&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"editBug('" + oBugs.getString(0,b) + "')\">" + oBugs.getString(1,b) + "</A><BR>");
  }
%>	    </TD>
            <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"></TD>
          </TR>          
          <!-- Línea roja -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"></TD>
            <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"></TD>
          </TR>
<% } %>                   
          <!-- Línea gris -->
          <TR>
            <TD WIDTH="2px" CLASS="subtitle"><IMG SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0"></TD>
            <TD  BACKGROUND="../images/images/graylinefloor.gif"></TD>
            <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0"></TD>
          </TR>
        </TABLE>
      </TD>
    <TR>
  </TABLE>
  <INPUT TYPE="hidden" NAME="pg_bug">
  <INPUT TYPE="hidden" NAME="tl_bug">
  <INPUT TYPE="hidden" NAME="qrymode" VALUE="4">
  <INPUT TYPE="hidden" NAME="where">
  </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>