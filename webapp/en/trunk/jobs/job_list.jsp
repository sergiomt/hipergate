<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataxslt.db.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Job" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);

  String sSkin = getCookie(request, "skin", "default");

  int iScreenWidth;
  float fScreenRatio;

  String id_domain = getCookie(request,"domainid","");   
  String gu_workarea = getCookie(request,"workarea",""); 
  String screen_width = request.getParameter("screen_width");
  String sFilter = "";
  String id_command = request.getParameter("id_command");
  
  if (id_command!=null)
    sFilter = " AND id_command='" + id_command + "'";

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);

  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;
  
  int iInstanceCount = 0;
  DBSubset oInstances = null;        
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;
  int iShow;

  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "10"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (request.getParameter("viewonly")!=null)
    iShow = Integer.parseInt(request.getParameter("viewonly"));      
  else
    iShow = 0;

  switch (iShow) {
    case 0:
      sFilter += " AND (" + DB.id_status + "=" + String.valueOf(Job.STATUS_PENDING) + " OR " + DB.id_status + "=" + String.valueOf(Job.STATUS_RUNNING) + " OR " + DB.id_status + "=" + String.valueOf(Job.STATUS_SUSPENDED) + ") ";
      break;
    case 1:
      sFilter += " AND (" + DB.id_status + "=" + String.valueOf(Job.STATUS_ABORTED) + " OR " + DB.id_status + "=" + String.valueOf(Job.STATUS_FINISHED) + ")";
      break;    
  }
  
  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    try {
      iOrderBy = Integer.parseInt(sOrderBy);
    }
    catch (NumberFormatException e) {
      iOrderBy = 4;
    }
  else
    iOrderBy = 0;

  JDCConnection oConn = GlobalDBBind.getConnection("joblisting");  
    
  try {
      oInstances = new DBSubset (DB.v_jobs, 
      				 DB.gu_job + "," + DB.gu_job_group + "," + DB.tx_command + "," + DB.tr_ + sLanguage + "," + DB.dt_execution + "," + DB.dt_created + "," + DB.id_command + "," + DB.tx_parameters + "," + DB.id_status + "," + DB.tl_job,
      				 DB.gu_workarea+ "='" + gu_workarea + "' " + sFilter + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oInstances.setMaxRows(iMaxRows);
      iInstanceCount = oInstances.load (oConn, iSkip);
    oConn.close("joblisting"); 
  }
  catch (SQLException e) {  
    oInstances = null;
    oConn.close("joblisting");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" DEFER="defer">
    <!--
        var jsInstanceId;
        var jsInstanceNm;
            
        <%
          
          out.write("var jsInstances = new Array(");
            for (int i=0; i<iInstanceCount; i++) {
              if (oInstances.getShort(8,i)==Job.STATUS_PENDING || oInstances.getShort(8,i)==Job.STATUS_RUNNING) {
                if (i>0) out.write(","); 
                out.write("\"" + oInstances.getString(0,i) + "\"");
              }
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

        function viewOnly(flag) {
          var url = window.document.location.href;
          var flg = url.indexOf("&viewonly=");
                    
          if (url.charAt(url.length-1)=='#')
            url = url.substr(0,url.length-1);
                      
          if (flg>0) {
            if (flg+11<url.length)
              url = url.substring(0, flg+10) + String(flag) + url.substr(flg+11);            
            else
              url = url.substring(0, flg+10) + String(flag);
          }
          else
            url += "&viewonly=" + String(flag);
                          
          window.document.location = url;
        } // viewOnly        

        // ----------------------------------------------------
        
	function sortBy(fld) {
	  var sFld = "";
	  if (fld==4) 
	   sFld = new String("4,6");
	  else 
	   sFld = new String(fld);
	  document.location = "job_list.jsp?id_domain=<%=id_domain%>&skip=0&orderby=" + sFld + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + (getURLParam("id_command")!=null ? "&id_command="+getURLParam("id_command") : "") + "&list_title=:%20Envios";
	}
        // ----------------------------------------------------
        	
	function createInstance() {	  
	  self.open ("job_edit.jsp?command=MAIL&id_domain=<%=id_domain%>", "editjob", "directories=no,toolbar=no,menubar=no,top=" + (screen.heigt-460)/2 + ",left=" + (screen.heigt-500)/2 + ",width=500,height=460");	  
	} // createInstance()

        // ----------------------------------------------------
	
	function cancelJobs() {
	  // [~//Borrar las instancias marcadas con checkboxes~]
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Pending task will be cancelled. Are you sure?")) {
	  	  
	    chi.value = "void,";	  	  
	    frm.action = "job_cancel.jsp";
	  	
	    while (frm.elements[offset].type!="checkbox") offset++;
	      
	    for (var i=0;i<jsInstances.length; i++) {              
    	      if (frm.elements[offset].type=="checkbox")
    	        if (frm.elements[offset].checked)
                  chi.value += jsInstances[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>5) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
            else {
              alert("Must check at least one task");
            }
          } // fi (confirm)
	} // deleteInstances()
	
        // ----------------------------------------------------

	function delayJobs()
	{
	  
	  var offset = 0;
	  var counter = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  
	  	  	  
	    for (var i=0;i<jsInstances.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked) {
    	        counter++;
                chi.value += jsInstances[i];
              }
              offset++;
	    } // next()
	    
	    
	    if (counter==0) {
	     alert("Must select a task");
	     return(false);
	    }
	    
   	    if (counter>1) {
	     alert("Must check only one task");
	     return(false);
	    }
            window.open("job_delay.jsp?gu_job="+chi.value+"&id_domain=<%=id_domain%>","delay","top=100,left=100,width=320,height=280,menubar=no,toolbar=no,directories=no");
	}

        // ----------------------------------------------------
        
        function viewJob(id) {
          window.open("job_modify_f.jsp?gu_job=" + id, "jobmodify","width=600,height=350,menubar=no,toolbar=no,directories=no");          
        }

        // ----------------------------------------------------

	var cac = false;
	var scheduler_status = "unknown";
		
	function processSchedulerInfo() {
	  var txt;        
    if (cac.readyState == 4) {
      if (cac.status == 200) {
        var frm = document.forms[0];
	      var sch = cac.responseXML.getElementsByTagName("scheduler");
	      var err = getElementText(sch[0],"error");
	      if (!err) err = "";
	      if (err.length>0) {
	        alert (err);
	      } else {
                scheduler_status = getElementText(sch[0],"status");
                if (scheduler_status=="running" || scheduler_status=="started" || scheduler_status=="start") {
                  frm.switcher.value = "Stop";
                  frm.status.value = "Executing";
                } else if (scheduler_status=="stop" || scheduler_status=="stopped") {
                  frm.switcher.value = "Start";
                  frm.status.value = "Stopped";
                } else if (scheduler_status=="death") {
                  frm.switcher.value = "Start";
                  frm.status.value = "Dead";
                }
                txt = getElementText(sch[0],"livethreads");
                frm.livethreads.value = (txt!=null ? txt : "0");
                txt = getElementText(sch[0],"queuelength");
                frm.queuelength.value = (txt!=null ? txt : "0");
              }
              document.forms[0].switcher.disabled=false;
              document.getElementById("loading").src="../images/images/spacer.gif";
              if (navigator.appName=="Microsoft Internet Explorer") window.document.body.style.cursor = "auto";
      } else if (cac.status == 404) {
      	document.location = "../common/errmsg.jsp?title=HTTP 404&desc=HttpSchedulerServlet not found check /WEB-INF/web.xml&resume="+escape("desktop.jsp?selected=0&subselected=0");
      }// fi (status)
      cac = false;
	  } // fi (readyState==4)
	}
	
        // ----------------------------------------------------

	function paint() {
	  var frm = document.forms[0];	  
	  frm.viewonly[<%=iShow%>].checked=true;

    cac = createXMLHttpRequest();
    if (cac) {
	    cac.onreadystatechange = processSchedulerInfo;
      cac.open("GET", "../servlet/HttpSchedulerServlet?action=info", true);
      cac.send(null);
    }
	} // paint

        // ----------------------------------------------------
	
	function switchOnOff() {
          cac = createXMLHttpRequest();
          if (cac) {
            document.forms[0].switcher.disabled=true;
            document.getElementById("loading").src="../images/images/jobs/loading.gif";
	    if (scheduler_status=="stop" || scheduler_status=="stopped" || scheduler_status=="death") {
	      cac.onreadystatechange = processSchedulerInfo;
              cac.open("GET", "../servlet/HttpSchedulerServlet?action=start", true);
              cac.send(null);
            } else if (scheduler_status=="running" || scheduler_status=="started") {
	      cac.onreadystatechange = processSchedulerInfo;
              cac.open("GET", "../servlet/HttpSchedulerServlet?action=stop", true);
              cac.send(null);
              if (navigator.appName=="Microsoft Internet Explorer") window.document.body.style.cursor = "wait";
            }
	  } // fi (cac)
        } // switchOnOff

        // ----------------------------------------------------
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Scheduled Tasks</TITLE>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0" onLoad="paint()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Scheduled Tasks <%=nullif(request.getParameter("list_title"))%></FONT></TD></TR></TABLE>  
      <FONT CLASS=""></FONT><DIV ID="div_status"></DIV>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD COLSPAN="4" CLASS="textstrong">Jobs Scheduler</TD>
        <TD COLSPAN="2" ALIGN="right"><IMG ID="loading" SRC="../images/images/spacer.gif" WIDTH="78" HEIGHT="7" BORDER="0"></TD>
        <TD COLSPAN="2"><INPUT TYPE="button" NAME="switcher" CLASS="minibutton" onclick="switchOnOff()"></TD>
      </TR>
      <TR>
        <TD COLSPAN="8" CLASS="textplain">
          Status&nbsp;<INPUT TYPE="text" CLASS="flatinput" TABINDEX="-1" NAME="status" SIZE="16">
          Execution Threads&nbsp;<INPUT TYPE="text" CLASS="flatinput" TABINDEX="-1" NAME="livethreads" SIZE="4">
          Queued Jobs&nbsp;<INPUT TYPE="text" CLASS="flatinput" TABINDEX="-1" NAME="queuelength" SIZE="5">          
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD><!--&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New">--></TD>
        <TD VALIGN="middle"><!--<A HREF="#" onclick="createInstance()" CLASS="linkplain">New</A>--></TD>
        <TD><IMG SRC="../images/images/jobs/cancel.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Cancel"></TD>
        <TD><A HREF="javascript:cancelJobs()" CLASS="linkplain">Cancel</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/jobs/sandclock.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delay Execution"></TD>
        <TD><A HREF="javascript:void(0)" onclick="delayJobs()" CLASS="linkplain">Chage execution date</A></TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/refresh.gif" HEIGHT="16" BORDER="0" ALT="Refresh"></TD>
        <TD><A HREF="#" onclick="window.document.location.reload()" CLASS="linkplain">Refresh</A></TD>
      </TR>
      <TR>
        <TD COLSPAN="8">
          <FONT CLASS="textplain"><B>View Tasks</B>&nbsp;<INPUT TYPE="radio" NAME="viewonly" onclick="viewOnly(0)">Pending&nbsp;&nbsp;<INPUT TYPE="radio" NAME="viewonly" onclick="viewOnly(1)">finished/cancelled&nbsp;&nbsp;<INPUT TYPE="radio" NAME="viewonly" onclick="viewOnly(2)">all</FONT>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="5" ALIGN="left">
<%
    	  // [~//Pintar los enlaces de siguiente y anterior~]
    
          if (iSkip>0) // [~//Si iSkip>0 entonces hay registros anteriores~]
            out.write("            <A HREF=\"job_list.jsp?list_title=:Envios&id_domain=" + id_domain + (id_command!=null ? "&id_command="+id_command : "") + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
          if (!oInstances.eof())
            out.write("            <A HREF=\"job_list.jsp?list_title=:Envios&id_domain=" + id_domain + (id_command!=null ? "&id_command="+id_command : "") + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader"  BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;&nbsp;<B>Task</B></TD>
          <TD CLASS="tableheader" WIDTH="90px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Status</B></TD>
          <TD CLASS="tableheader" WIDTH="110px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(6);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==6 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>New</B></TD>
          <TD CLASS="tableheader" WIDTH="160px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Execution</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
<%
	  String sStrip;
	  	  
	  for (int i=0; i<iInstanceCount; i++) {
	  
	  sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="14">
              <TD VALIGN="CENTER" WIDTH="320" CLASS="strip<% out.write(sStrip); %>"><% out.write("<A HREF=\"#\" CLASS=\"linknodecor\" oncontextmenu=\"return false;\" onclick=\"viewJob('" + oInstances.getString(0,i) + "')\" TITLE=\"View details\"><B>" + oInstances.getString(9,i)); %></TD>
              <TD VALIGN="CENTER" WIDTH="100" CLASS="strip<% out.write(sStrip); %>">&nbsp;<%=oInstances.getStringNull(3,i,"")%></TD>
              <TD ALIGN="center" VALIGN="CENTER" CLASS="strip<% out.write(sStrip); %>">&nbsp;<%=Gadgets.split(oInstances.getStringNull(5,i,"")," ")[0]%></TD>
              <TD VALIGN="CENTER" CLASS="strip<% out.write(sStrip); %>">&nbsp;<%=oInstances.getStringNull(4,i,"").equals("")?"As soon as possible":Gadgets.split(oInstances.getString(4,i)," ")[0]%></TD>
              <TD VALIGN="CENTER" CLASS="strip<% out.write(sStrip); %>">
<% if (oInstances.getShort(8,i)==Job.STATUS_PENDING || oInstances.getShort(8,i)==Job.STATUS_RUNNING) {
     out.write("                <INPUT TYPE=\"checkbox\" NAME=\"chk-" + oInstances.getStringNull(0,i,"") +"\" ID=\"chk-" + oInstances.getStringNull(0,i,"") + "\">");
   }
%>
              </TD>
            </TR>
<%        
	} // next(i) 
%>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
