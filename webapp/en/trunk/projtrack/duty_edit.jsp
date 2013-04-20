<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%

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

  String gu_duty = request.getParameter("gu_duty");
  Project oPrj = new Project();
  JDCConnection oCon1 = null;
  int iRowCount = 0;
  
  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");
  String sLanguage = getNavigatorLanguage(request);

  int iDomainId = Integer.parseInt(getCookie(request,"domainid","0"));
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  DBSubset oTopLevel = new DBSubset(DB.k_projects, DB.gu_project + "," + DB.nm_project, DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_parent + " IS NULL ORDER BY " + DB.nm_project, 10);
  DBSubset oAttachs = new DBSubset(DB.k_duties_attach, DB.tx_file, DB.gu_duty + "='" + request.getParameter("gu_duty") + "'", 1);
  DBSubset oResources = new DBSubset(DB.k_x_duty_resource, DB.nm_resource, DB.gu_duty + "='" + request.getParameter("gu_duty") + "'", 1);
  DBSubset oPrjChlds = null;
  int iPrjChlds = 0;
  int iAttachs = 0;
  int iResources;
  String sPriorityLookUp, sResourceLookUp, sStatusLookUp, sTypesLookUp; 
  Duty oDuty;
  
  boolean bIsGuest = true;
    
  try {
    
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oCon1 = GlobalDBBind.getConnection("duty_edit");

    sPriorityLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.od_priority, sLanguage);
    sResourceLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, "nm_resource", sLanguage);
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp   (oCon1, DB.k_duties_lookup, sWorkArea, DB.tx_status, sLanguage);
    sTypesLookUp = DBLanguages.getHTMLSelectLookUp    (oCon1, DB.k_duties_lookup, sWorkArea, DB.tp_duty, sLanguage);
    
    oTopLevel.load(oCon1);
    
    oDuty = new Duty(oCon1, gu_duty);
    iAttachs = oAttachs.load(oCon1);
    iResources = oResources.load(oCon1);

    DBSubset oSupervisors = new DBSubset(DB.k_users, DB.gu_user+","+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2,
    																		 DB.gu_workarea+"=? AND (" + DB.gu_user + "=? OR " + DB.gu_user + " IN (SELECT " + DB.vl_lookup + " FROM " + DB.k_duties_lookup + " WHERE " + DB.id_section + "='nm_resource' AND " + DB.gu_owner + "=?)) ORDER BY 2,3,4", 100);
    int iSupervisors = oSupervisors.load(oCon1, new Object[]{sWorkArea,sUserId,sWorkArea});

	  sendUsageStats(request, "duty_edit");

%><HTML>
  <HEAD>
    <TITLE>hipergate :: Edit Duty</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
    <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');

      // ------------------------------------------------------

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

      function lookup(odctrl) {
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_duties_lookup&id_language=<%=sLanguage%>&id_section=od_priority&tp_control=2&nm_control=sel_priority&nm_coding=od_priority", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_duties_lookup&id_language=<%=sLanguage%>&id_section=tx_status&tp_control=2&nm_control=sel_status&nm_coding=tx_status", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("resource_lookup_f.jsp?id_language=<%=sLanguage%>&tp_control=2&nm_control=sel_resources&nm_coding=nm_resource", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
            window.open("../common/lookup_f.jsp?nm_table=k_duties_lookup&id_language=<%=sLanguage%>&id_section=tp_duty&tp_control=2&nm_control=sel_tp_duty&nm_coding=tp_duty", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()

      // ------------------------------------------------------

      function setCombos() {
        var frm = document.forms[0];
        var sel = frm.sel_resources.options;
        var i;

        setCombo(frm.sel_project, "<%=oDuty.getString(DB.gu_project)%>");
        setCombo(frm.sel_pct_complete, "<% if (!oDuty.isNull(DB.pct_complete)) out.write(String.valueOf(oDuty.getShort(DB.pct_complete))); %>");
		    setCombo(frm.sel_priority, "<% if (!oDuty.isNull(DB.od_priority)) out.write(String.valueOf(oDuty.getShort(DB.od_priority))); %>");
        setCombo(frm.sel_status, "<%=oDuty.getStringNull(DB.tx_status,"")%>");
        setCombo(frm.sel_tp_duty, "<%=oDuty.getStringNull(DB.tp_duty,"")%>");
        setCombo(frm.gu_writer, "<%=oDuty.getStringNull(DB.gu_writer,"")%>");

        <%
          for (int r=0;r<iResources;r++) {
            out.write("        for (i=1;i<sel.length; i++)\n");
            out.write("        if (sel[i].value==\"" + oResources.getString(0,r) +"\") sel[i].selected = true;\n");
          }
        %>
      } // setCombos()

      // ------------------------------------------------------
      
      function deleteDuty() {
        if (confirm("Are you sure you want to delete this duty?"))
          window.location.href = "dutyedit_delete.jsp?chkbox0=<%=oDuty.get(DB.gu_duty)%>&nu_duties=1";
      }
                 
      // ------------------------------------------------------
      
      function validate() {
	var frm = window.document.forms[0];
        var prj = frm.sel_project.options;
        var res = frm.sel_resources.options;
	var str;
	var npj;
	var aStart;
	var aEnd;
	var dtStart;
	var dtEnd;
	
	if (rtrim(frm.nm_duty.value)=="") {
	  alert ("Duty name is mandatory");
	  return false;
	}
		
	npj = 0;
        for (var n=0; n<prj.length; n++)
          if (prj[n].selected) npj++;

	if (npj==0) {
	  alert ("Must select a Project");
	  return false;
	}
	else if (npj>1) {
	  alert ("Must select only one Project");
	  return false;
	}	
	else (npj==1)
	
	frm.gu_project.value = getCombo(frm.sel_project);
	  
	frm.od_priority.value = getCombo(frm.sel_priority);

	frm.tx_status.value = getCombo(frm.sel_status);

	frm.tp_duty.value = getCombo(frm.sel_tp_duty);
	
	frm.pct_complete.value = getCombo(frm.sel_pct_complete);
	
	if (frm.tx_status.value == 'FINISHED')
		frm.pct_complete.value = 100;
		
	if (frm.pct_complete.value == 100)
	  frm.tx_status.value = 'FINISHED';

	if (!isIntValue(frm.pr_cost.value)) {
	  alert ("Cost must be an integer quantity");
	  return false;
	}
			
	str = frm.dt_start.value;
	
	if (str.length>0 && !isDate(str, "d")) {
	  alert ("Start date is not valid");
	  return false;
	}		
	
	str = frm.dt_end.value;

	if (str.length>0 && !isDate(str, "d")) {
	  alert ("End date is not valid");
	  return false;
	}

	if (frm.dt_start.value.length>0 && frm.dt_end.value.length>0) {
	  aStart = frm.dt_start.value.split("-");
	  aEnd = frm.dt_end.value.split("-");
	  dtStart = new Date(parseInt(aStart[0]), parseInt(parseFloat(parseFloat(aStart[1]))-1), parseInt(parseFloat(aStart[2])));
	  dtEnd = new Date(parseInt(aEnd[0]), parseInt(parseFloat(aEnd[1])-1), parseInt(parseFloat(aEnd[2])));
	  if (dtStart>dtEnd) {
	    alert ("Start date must be previous to end date");
	    return false;
	  }
	}
	
	frm.nm_resource.value = "";	
	for (var r=0;r<res.length; r++)
	  if (res[r].selected && res[r].value.length>0)
	    frm.nm_resource.value += (0==frm.nm_resource.value.length ? res[r].value : "," + res[r].value);
	
	if (frm.de_duty.value.length>2000) {
	  alert ("Description must not be longer than 2000 characters");
	  return false;
	}
	
	if (frm.tx_comments.value.length>1000) {
	  alert ("Comments may not be longer than 1000 characters");
	  return false;
	}
	

	return true;	
      }      
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  onLoad="setCombos()">
    <TABLE WIDTH="90%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Duty</FONT></TD></TR></TABLE>  

    <FORM NAME="frmNewProject" ENCTYPE="multipart/form-data" METHOD="POST" ACTION="dutyedit_store.jsp" onSubmit="return validate()">
      <INPUT TYPE="hidden" NAME="is_new" VALUE="0">
      <INPUT TYPE="hidden" NAME="gu_duty" VALUE="<%=gu_duty%>">
      <INPUT TYPE="hidden" NAME="tp_duty" VALUE="<%=oDuty.getStringNull(DB.tp_duty,"")%>">
      <TABLE SUMMARY="Tabla Principal" CLASS="formback">
        <TR>
          <TD CLASS="formfront">
            <TABLE SUMMARY="Proyecto" CLASS="formfront">
              <TR>
                <TD>
                  <FONT CLASS="formstrong">Project</FONT><BR>
                  
                  <INPUT TYPE="hidden" NAME="gu_project" VALUE="<%=oDuty.getString(DB.gu_project)%>">
                  <SELECT NAME="sel_project" SIZE="22" STYLE="width:256" MULTIPLE>
                    <%
                      for (int t=0; t<oTopLevel.getRowCount(); t++) {
    		        oPrj.replace(DB.gu_project, oTopLevel.getString(0,t));
    		        oPrjChlds = oPrj.getAllChilds(oCon1);
    			iPrjChlds = oPrjChlds.getRowCount();
                        out.write("                      ");
                        out.write("<OPTION VALUE=\"" + oTopLevel.getString(0,t) + "\">" + oTopLevel.getString(1,t) + "</OPTION>");
                        for (int p=0;p<iPrjChlds; p++) {
                          if (oPrjChlds.getInt(2,p)>1) {
                            // Project GUIDs as values
                            out.write("<OPTION VALUE=\"" + oPrjChlds.getString(0,p) + "\">");
                            // Indent project names
                            for (int s=1;s<oPrjChlds.getInt(2,p); s++) out.write("&nbsp;&nbsp;&nbsp;&nbsp;");
                            // Project names
                            out.write(oPrjChlds.getString(1,p));

                            out.write("</OPTION>");
                          } // fi (od_level>1)
                        } // next (p)
                      out.write("\n");
                    } // next (t)
                    %>
                  </SELECT>
                </TD>
              </TR>
            </TABLE>
          </TD>          
          <TD VALIGN="top" CLASS="formfront">
	    <TABLE SUMMARY="Maintenance Data">
              <TR>
                <TD ALIGN="right"></TD>
                <TD>
                  <IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">Name</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="50" SIZE="36" NAME="nm_duty" VALUE="<%=oDuty.getString(DB.nm_duty)%>">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Type</FONT></TD>
                <TD>
                  <SELECT NAME="sel_tp_duty"><%=sTypesLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Duty types"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Scheduled Date</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="9" NAME="dt_scheduled" VALUE="<% if (null!=oDuty.get(DB.dt_scheduled)) out.write(oSimpleDate.format(oDuty.get(DB.dt_scheduled))); %>">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_scheduled')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
		</TD>
	      </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Start Date</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="9" NAME="dt_start" VALUE="<% if (null!=oDuty.get(DB.dt_start)) out.write(oSimpleDate.format(oDuty.get(DB.dt_start))); %>">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
		  &nbsp;
		  <FONT CLASS="formplain">End Date</FONT>
		  &nbsp;
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="9" NAME="dt_end" VALUE="<% if (null!=oDuty.get(DB.dt_end)) out.write(oSimpleDate.format(oDuty.get(DB.dt_end))); %>">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
                </TD>
              </TR>
               <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Percentage Completed</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" NAME="pct_complete" VALUE="<% if(null!=oDuty.get(DB.pct_complete)) out.write(String.valueOf(oDuty.get(DB.pct_complete))); %>">
				  <SELECT NAME="sel_pct_complete">
				  <%
				  	/*String pct_complete = oSimpleDate.format(oDuty.get(DB.pct_complete));?*/
				  	int i;
					for (i=0;i<=100;i+=10) { 
						/*
						String str_selected = " SELECTED ";
						if (i!=pct_complete) 
							str_selected = "";*/
						%>
				  	<option value="<%=i%>"><%=i%>%</option>
				  <% } %>	
				  </select>
				  &nbsp;&nbsp;
		  &nbsp;&nbsp;&nbsp;&nbsp;
		  <FONT CLASS="formplain">Cost (¤)</FONT>
		  &nbsp;
                 <INPUT TYPE="text" MAXLENGTH="10" SIZE="9" NAME="pr_cost" onkeypress="return acceptOnlyNumbers();" VALUE="<% if (null!=oDuty.get(DB.pr_cost)) out.write(floor(oDuty.getFloat(DB.pr_cost))); %>">&nbsp;&nbsp;
                </TD>
              </TR>
			  <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Priority</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" NAME="od_priority" VALUE="<% if(null!=oDuty.get(DB.od_priority)) out.write(String.valueOf(oDuty.get(DB.od_priority))); %>">
                  <SELECT NAME="sel_priority"><OPTION VALUE=""></OPTION><%=sPriorityLookUp%></SELECT>
<% if (1025==iDomainId) { %>
                  <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A>
<% } %>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Status</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" NAME="tx_status" VALUE="<%=oDuty.getStringNull(DB.tx_status,"")%>">
                  <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>
<% if (1025==iDomainId) { %>
                  <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Values List"></A>
<% } %>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">Assigned to&nbsp;</FONT></TD>
                <TD VALIGN="middle">
                  <INPUT TYPE="hidden" NAME="nm_resource" VALUE="">
                  <SELECT NAME="sel_resources" SIZE="6" MULTIPLE><OPTION VALUE=""></OPTION><%=sResourceLookUp%></SELECT>
                  <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" VSPACE="20" ALT="View Values List"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" CLASS="formplain">Supervised by</TD>
                <TD><SELECT NAME="gu_writer"><OPTION VALUE=""></OPTION><% for (int s=0; s<iSupervisors; s++) out.write("<OPTION VALUE=\""+oSupervisors.getString(0,s)+"\">"+oSupervisors.getStringNull(1,s,"")+" "+oSupervisors.getStringNull(2,s,"")+" "+oSupervisors.getStringNull(3,s,"")+"</OPTION>"); %></SELECT></TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">Description</FONT></TD>
                <TD>
                  <TEXTAREA NAME="de_duty" ROWS="4" COLS="36"><%=oDuty.getStringNull(DB.de_duty,"")%></TEXTAREA>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">Comments</FONT></TD>
                <TD>
                  <TEXTAREA NAME="tx_comments" ROWS="3" COLS="36"><%=oDuty.getStringNull(DB.tx_comments,"")%></TEXTAREA>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">Attached File</FONT></TD>
                <TD>
                  <INPUT TYPE="file" NAME="dutyfile1_<%=sUserId%>" SIZE="26">
                </TD>
              </TR>              
	      <%
	        for (int a=0; a<iAttachs; a++) {
	          out.write ("              <TR>\n");
	          out.write ("                <TD VALIGN=\"middle\" ALIGN=\"right\"><FONT CLASS=\"formplain\">Delete</FONT>&nbsp;<INPUT TYPE=\"checkbox\" VALUE=\"" + oAttachs.getString(0,a) + "\"></TD>\n");
	          out.write ("                <TD VALIGN=\"middle\">\n");
	          out.write ("                  <A HREF=\"../servlet/HttpBLOBServlet?nm_table=" + DB.k_duties_attach + "&nm_field=" +  DB.tx_file + "&bin_field=" + DB.bin_file + "&pk_field=" + DB.gu_duty + "&pk_value=" + request.getParameter("gu_duty") + "\" TARGET=\"_blank\" CLASS=\"linknodecor\" TITLE=\"View File\"><IMG SRC=\"../images/images/viewtxt.gif\" BORDER=\"0\">&nbsp;<I>" + oAttachs.getString(0,a) + "</I></A>");
	          out.write ("                </TD>\n");
	          out.write ("              </TR>\n");
	        }
	      %>
              <TR>
                <TD ALIGN="right"></TD>
                <TD>
                  <BR>
<% if (bIsGuest) { %>
                  <INPUT TYPE="button" CLASS="pushbutton" STYLE="WIDTH:80" VALUE="Save" onclick="alert ('Your credential level as Guest does not allow you to perform this action')">
<% } else { %>
                  <INPUT TYPE="submit" CLASS="pushbutton" STYLE="WIDTH:80" VALUE="Save">
<% } %>
                  &nbsp;&nbsp;&nbsp;
<% if (bIsGuest) { %>
                  <INPUT TYPE="button" CLASS="pushbutton" STYLE="WIDTH:80" VALUE="Delete" onClick="alert ('Your credential level as Guest does not allow you to perform this action')">
<% } else { %>
                  <INPUT TYPE="button" CLASS="pushbutton" STYLE="WIDTH:80" VALUE="Delete" onClick="javascript:deleteDuty()">
<% } %>
                  &nbsp;&nbsp;&nbsp;
                  <INPUT TYPE="button" CLASS="closebutton" STYLE="WIDTH:80" VALUE="Close" onClick="javascript:window.close()">
                </TD>
              </TR>              
            </TABLE>
          </TD>
        </TR>
      </TABLE> 
    </FORM>
  </BODY>
</HTML>
<%
    oCon1.close("duty_edit");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("duty_edit");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
      
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }

  if (null==oCon1) return;
  oCon1=null;
%>
<%@ include file="../methods/page_epilog.jspf" %>