<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/projtrack.jspf" %>
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

  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_project = request.getParameter("gu_project");
  
  String sUserId = getCookie(request,"userid","");
  String sWorkArea = getCookie(request,"workarea","");
  String sLanguage = getNavigatorLanguage(request);
  
  int iDomainId = Integer.parseInt(getCookie(request,"domainid","0"));

  Project oPrj = new Project();
  JDCConnection oCon1 = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;
  int iRowCount = 0;

  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
  DBSubset oTopLevel = new DBSubset(DB.k_projects, DB.gu_project + "," + DB.nm_project, DB.gu_owner + "='" + sWorkArea + "' AND " + DB.id_parent + " IS NULL ORDER BY " + DB.nm_project, 10);
  DBSubset oPrjChlds = null;
  int iPrjChlds = 0;
  String sPriorityLookUp, sResourceLookUp, sStatusLookUp, sTypesLookUp;    
  String sProjCombo;
  boolean bShowOnlyMyProjects = nullif(request.getParameter("bo_showonlymine"),"true").equals("true");
  boolean bShowOnlyOpenProjects = nullif(request.getParameter("bo_showonlyopen"),"true").equals("true");

  try {
    oCon1 = GlobalDBBind.getConnection("duty_new");

    sPriorityLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oCon1, DB.k_duties_lookup, sWorkArea, DB.od_priority, sLanguage);
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oCon1, DB.k_duties_lookup, sWorkArea, DB.tx_status, sLanguage);
    sResourceLookUp = DBLanguages.getHTMLSelectLookUp (oCon1, DB.k_duties_lookup, sWorkArea, DB.nm_resource, sLanguage);
    sTypesLookUp = DBLanguages.getHTMLSelectLookUp    (oCon1, DB.k_duties_lookup, sWorkArea, DB.tp_duty, sLanguage);

    if (gu_project==null) {
      sProjCombo = getHTMLSelectProject(oCon1, sWorkArea, bShowOnlyMyProjects ? sUserId : null, bShowOnlyOpenProjects ? "ABIERTO" : null);
      if (sProjCombo.length()==0 && (!bShowOnlyMyProjects || !bShowOnlyOpenProjects)) {
        sProjCombo = getHTMLSelectProject(oCon1, sWorkArea, null, null);
		    bShowOnlyOpenProjects = bShowOnlyMyProjects = false;
      }
    } else if (oPrj.load(oCon1, new Object[]{gu_project})) {
      sProjCombo = "<OPTION VALUE=\"" + oPrj.getString(DB.gu_project) + "\" SELECTED>" + oPrj.getString(DB.nm_project) + "</OPTION>";
    } else {
      sProjCombo = "";
    }
%>
<HTML>
  <HEAD>
    <TITLE>hipergate :: [~Crear Tarea~]</TITLE>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
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
	  alert ("[~El nombre de la tarea es obligatorio~]");
	  return false;
	}
		
	npj = 0;
        for (var n=0; n<prj.length; n++)
          if (prj[n].selected) npj++;

	if (npj==0) {
	  alert ("[~Debe seleccionar un proyecto~]");
	  return false;
	}
	else if (npj>1) {
	  alert ("[~Debe seleccionar un único proyecto~]");
	  return false;
	}	
	else (npj==1)
	  frm.gu_project.value = getCombo(frm.sel_project);
	  
	frm.od_priority.value = getCombo(frm.sel_priority);
	if (frm.od_priority.value == ''){
	  alert ("[~Debe asignar una prioridad~]");
	  return false;
	}	

	frm.tp_duty.value = getCombo(frm.sel_tp_duty);

	frm.tx_status.value = getCombo(frm.sel_status);
	if (frm.tx_status.value == ''){
	  alert ("[~Debe asignar un estado~]");
	  return false;
	}	
	
	frm.pct_complete.value = getCombo(frm.sel_pct_complete);
	
	if (!isIntValue(frm.pr_cost.value)) {
	  alert ("[~El coste debe ser una cantidad numérica entera~]");
	  return false;
	}
	
	str = frm.dt_start.value;
	
	if (str.length>0 && !isDate(str, "d")) {
	  alert ("[~La fecha de inicio no es válida~]");
	  return false;
	}
	
	str = frm.dt_end.value;

	if (str.length>0 && !isDate(str, "d")) {
	  alert ("[~La fecha de fin no es válida~]");
	  return false;
	}

	if (frm.dt_start.value.length>0 && frm.dt_end.value.length>0) {
	  aStart = frm.dt_start.value.split("-");
	  aEnd = frm.dt_end.value.split("-");	  
	  dtStart = new Date(parseInt(aStart[0]), parseInt(parseFloat(aStart[1]))-1, parseInt(parseFloat(aStart[2])));
	  dtEnd = new Date(parseInt(aEnd[0]), parseInt(aEnd[1])-1, parseInt(aEnd[2]));
	  if (dtStart>dtEnd) {
	    alert ("[~La fecha de inicio debe ser anterior a la fecha de fin~]");
	    return false;
	  }
	}
	
	frm.nm_resource.value = "";	
	for (var r=0;r<res.length; r++)
	  if (res[r].selected && res[r].value.length>0)
	    frm.nm_resource.value += (0==r ? res[r].value : "," + res[r].value);
	
	if (frm.de_duty.value.length>2000) {
	  alert ("[~La descripci&oacute;n no debe exceder los 2000 caracteres~]");
	  return false;
	}

	if (frm.tx_comments.value.length>1000) {
	  alert ("[~Los comentarios no deben exceder los 1000 caracteres~]");
	  return false;
	}
	
	return true;	
      }
      
      function setCombos() {
        setCombo(document.forms[0].sel_priority, "4");
        setCombo(document.forms[0].sel_status, "PENDIENTE");        
      }
      
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  TOPMARGIN="4" MARGINHEIGHT="4" onLoad="setCombos()">    
    <FORM NAME="frmNewProject" ENCTYPE="multipart/form-data" METHOD="post" ACTION="dutyedit_store.jsp" onSubmit="return validate()">
      <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">[~Crear Tarea~]</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="is_new" VALUE="1">
      <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=sUserId%>">
      <INPUT TYPE="hidden" NAME="tp_duty" VALUE="">
      <CENTER>      
      <TABLE SUMMARY="Tabla Principal" CLASS="formback">
        <TR>
          <TD CLASS="formfront">
            <TABLE SUMMARY="Proyecto" CLASS="formfront">
              <TR>
                <TD VALIGN="top" CLASS="formplain">
								  <INPUT TYPE="radio" NAME="viewallmine" VALUE="true" <% out.write(bShowOnlyMyProjects ? "CHECKED" : ""); %> onclick="document.location='duty_new.jsp?bo_showonlymine=true&bo_showonlyopen='+getCheckedValue(document.forms[0].viewonlyopen)">&nbsp;[~Ver s&oacute;lo mis proyectos~]
								  <BR/>
								  <INPUT TYPE="radio" NAME="viewallmine" VALUE="false" <% out.write(bShowOnlyMyProjects ? "" : "CHECKED"); %> onclick="document.location='duty_new.jsp?bo_showonlymine=false&bo_showonlyopen='+getCheckedValue(document.forms[0].viewonlyopen)">&nbsp;[~Ver todos los proyectos~]
								  <BR/><BR/>
								  <INPUT TYPE="radio" NAME="viewonlyopen" VALUE="true" <% out.write(bShowOnlyOpenProjects ? "CHECKED" : ""); %> onclick="document.location='duty_new.jsp?bo_showonlyopen=true&bo_showonlyopen='+getCheckedValue(document.forms[0].viewallmine)">&nbsp;[~Ver s&oacute;lo proyectos abiertos~]
								  <BR/>
								  <INPUT TYPE="radio" NAME="viewonlyopen" VALUE="false" <% out.write(bShowOnlyOpenProjects ? "" : "CHECKED"); %> onclick="document.location='duty_new.jsp?bo_showonlyopen=false&bo_showonlyopen='+getCheckedValue(document.forms[0].viewallmine)">&nbsp;[~Ver proyectos en cualquier estado~]

                </TD>
              </TR>
              <TR>
                <TD VALIGN="top">
                  <FONT CLASS="formstrong">[~Proyecto~]</FONT><BR>                  
                  <INPUT TYPE="hidden" NAME="gu_project">
                  <SELECT NAME="sel_project" SIZE="22" STYLE="width:256" MULTIPLE><%=sProjCombo%></SELECT>
                </TD>
              </TR>
            </TABLE>
          </TD>          
          <TD VALIGN="top" CLASS="formfront">
	    <TABLE SUMMARY="[~Datos de Mantenimiento~]">
              <TR>
                <TD ALIGN="right"></TD>
                <TD>
                  <IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formstrong">[~Nombre~]</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="50" SIZE="36" NAME="nm_duty">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">[~Tipo~]</FONT></TD>
                <TD>
                  <SELECT NAME="sel_tp_duty"><%=sTypesLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="[~Ver tipos de tareas~]"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">[~Fecha Prevista~]</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="9" NAME="dt_scheduled" VALUE="<% out.write(oSimpleDate.format(new Date())); %>">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_scheduled')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Ver Calendario~]"></A>
		</TD>
	      </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">[~Fecha Inicio~]</FONT></TD>
                <TD>
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="9" NAME="dt_start" VALUE="<% out.write(oSimpleDate.format(new Date())); %>">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Ver Calendario~]"></A>
		  &nbsp;
		  <FONT CLASS="formplain">[~Fecha Fin~]</FONT>
		  &nbsp;
                  <INPUT TYPE="text" MAXLENGTH="10" SIZE="9" NAME="dt_end">&nbsp;&nbsp;
                  <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Ver Calendario~]"></A>
                </TD>
              </TR>
			  <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">[~Porcentaje Completado~]</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" NAME="pct_complete" VALUE="0">
				  <SELECT NAME="sel_pct_complete">
				  <% for (int i=0;i<=100;i+=10) { %>
				  	<option value="<%=i%>"><%=i%>%</option>
				  <% } %>	
				  </select>
				  &nbsp;&nbsp;
		  &nbsp;&nbsp;&nbsp;&nbsp;
		  <FONT CLASS="formplain">[~Coste ( <b>¤</b> )~]</FONT>
		  &nbsp;
                 <INPUT TYPE="text" MAXLENGTH="10" SIZE="9" NAME="pr_cost" onkeypress="return acceptOnlyNumbers();" VALUE="0">&nbsp;&nbsp;
                  
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">[~Prioridad~]</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" NAME="od_priority" VALUE="4">
                  <SELECT NAME="sel_priority"><OPTION VALUE=""></OPTION><%=sPriorityLookUp%></SELECT>
<% if (1025==iDomainId || true) { %>
                  <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="[~Ver Lista de Valores~]"></A>
<% } %>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">[~Estado~]</FONT></TD>
                <TD>
                  <INPUT TYPE="hidden" NAME="tx_status" VALUE="">
                  <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>
<% if (1025==iDomainId) { %>
                  <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="[~Ver Lista de Valores~]"></A>
<% } %>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right"><FONT CLASS="formplain">[~Asignada a~]</FONT></TD>
                <TD VALIGN="middle">
                  <INPUT TYPE="hidden" NAME="nm_resource" VALUE="">
                  <SELECT NAME="sel_resources" MULTIPLE><OPTION VALUE=""></OPTION><%=sResourceLookUp%></SELECT>
                  <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" VSPACE="20" ALT="[~Ver Lista de Valores~]"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">[~Descripci&oacute;n~]</FONT></TD>
                <TD>
                  <TEXTAREA NAME="de_duty" ROWS="4" COLS="36"></TEXTAREA>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">[~Comentarios~]</FONT></TD>
                <TD>
                  <TEXTAREA NAME="tx_comments" ROWS="3" COLS="36"></TEXTAREA>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" VALIGN="top"><FONT CLASS="formplain">[~Archivo Adjunto~]</FONT></TD>
                <TD>
                  <INPUT TYPE="file" NAME="dutyfile1_<%=sUserId%>" SIZE="26">
                </TD>
              </TR>              
              <TR>
                <TD ALIGN="right" VALIGN="top">
                  <INPUT TYPE="checkbox" NAME="chk_notify" VALUE="1">
                <TD>
		  <FONT CLASS="formplain">[~Notificar a los asignados por e-mail~]</FONT>
                </TD>
              </TR>              
              <TR>
                <TD ALIGN="right"></TD>
                <TD>
                  <BR><INPUT TYPE="submit" CLASS="pushbutton" STYLE="WIDTH:80" VALUE="[~Guardar~]">
                  &nbsp;&nbsp;&nbsp;
                  <INPUT TYPE="button" CLASS="closebutton" STYLE="WIDTH:80" VALUE="[~Cerrar~]" onClick="javascript:window.close()">
                </TD>
              </TR>              
            </TABLE>
          </TD>
        </TR>
      </TABLE>
      </CENTER>
    </FORM>
  </BODY>
</HTML>
<%
    oCon1.close("duty_new");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.close("duty_new");
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