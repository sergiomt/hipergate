<%@ page import="java.util.HashMap,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%
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

  // [~//obtener el idioma del navegador cliente~]
  String sLanguage = getNavigatorLanguage(request);

  // [~//Obtener el skin actual~]
  String sSkin = getCookie(request, "skin", "default");

  // [~//Resolucion de pantalla en el cliente~]
  int iScreenWidth;
  float fScreenRatio;

  // [~//Obtener el dominio y la workarea~]
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String gu_list = request.getParameter("gu_list");
  String de_list = request.getParameter("de_list");
  String screen_width = request.getParameter("screen_width");
  String tp_list = null;
  String gu_blacklist = null;
  
  // [~//La resolución de pantalla debe pasarse como parámetro por JavaScript cliente~]
  // [~//en caso de que el parámetro no exista, se asume 800x600~]
  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = (float) iScreenWidth;
  if (fScreenRatio<1) fScreenRatio=1;
  
  // [~//Cadena de de filtrado (claúsula WHERE)~]
        
  String sField = request.getParameter("field")==null ? "" : request.getParameter("field");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
  
  int iOnly;
  String sOnly;
  
  if (request.getParameter("viewonly")==null)
    iOnly = 0;
  else
    iOnly = Integer.parseInt(request.getParameter("viewonly"));
  
  switch (iOnly) {
    case 1:
      sOnly = " AND b." + DB.bo_active + "<>0 AND b." + DB.tx_email + " NOT IN (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + " IN (SELECT " + DB.gu_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_workarea + "='" + gu_workarea + "' AND " + DB.tp_list + "=" + String.valueOf(DistributionList.TYPE_BLACK) + " AND " + DB.gu_query + "='" + gu_list + "'))";
      break;
    case 2:
      sOnly = " AND b." + DB.bo_active + "=0 ";
      break;
    case 3:
      sOnly = " AND b." + DB.tx_email + " IN (SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + " IN (SELECT " + DB.gu_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_workarea + "='" + gu_workarea + "' AND " + DB.tp_list + "=" + String.valueOf(DistributionList.TYPE_BLACK) + " AND " + DB.gu_query + "='" + gu_list + "'))";
      break;
    default:
      sOnly = "";
      break;    
  }
  
  int iMaxRows;
  
  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "100"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 10; }
  
  int iSkip;

  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (iSkip<0) iSkip = 0;

  String sOrderBy;
  int iOrderBy;  

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  int iMemberCount = 0;
  Boolean bBlocked = new Boolean(true);
  HashMap oBlockMap = null;
  DBSubset oMembers = null;        

  DistributionList oList;  
  Statement oStmt;
  ResultSet oRSet;
    
  // [~//Obtener una conexión del pool a bb.dd. (el nombre de la conexión es arbitrario)~]
  JDCConnection oConn = null;  
  boolean bIsGuest = true;
    
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("memberlisting");
    
    oList = new DistributionList(oConn, gu_list);
    
    tp_list = String.valueOf(oList.getShort(DB.tp_list));
                
    // [~//Si el filtro no existe devolver todos los registros~]

    if (sFind.length()==0) {
      oMembers = new DBSubset (DB.k_x_list_members + " b", 
      			       "b." + DB.tx_surname + ", b." + DB.tx_name + ", b." + DB.tx_email + ", b." + DB.gu_company + ", b." + DB.gu_contact + ", b." + DB.bo_active,
      			       "b." + DB.gu_list + "='" + gu_list + "' " + sOnly + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      oMembers.setMaxRows(iMaxRows);
      iMemberCount = oMembers.load (oConn, iSkip);
    }
    else {
      // [~//Listados con filtro~]

      oMembers = new DBSubset (DB.k_x_list_members + " b", 
      			       "b." + DB.tx_surname + ", b." + DB.tx_name + ", b." + DB.tx_email + ", b." + DB.gu_company + ", b." + DB.gu_contact + ", b." + DB.bo_active,
      			       sField + " " + DBBind.Functions.ILIKE + " ? AND b." + DB.gu_list + "='" + gu_list + "' " + sOnly + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);
      oMembers.setMaxRows(iMaxRows);
      iMemberCount = oMembers.load (oConn, new Object[] { "%" + sFind +"%" }, iSkip);
    }

    if (iMemberCount>0) {
      
      gu_blacklist = oList.blackList(oConn);
      
      if (gu_blacklist!=null) {
        
        StringBuffer oMbrsStr = new StringBuffer();
        
        oBlockMap = new HashMap(iMaxRows/2);
    
    	oMbrsStr.append("SELECT " + DB.tx_email + " FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + gu_blacklist + "' AND " + DB.tx_email + " IN ('" + oMembers.getString(2,0) + "'");
    	
        for (int m=1; m<iMemberCount; m++)
          oMbrsStr.append(",'" + oMembers.getString(2,m) + "'");
        
        oMbrsStr.append(")");
        
        oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        
        try { oStmt.setQueryTimeout(20); }  catch (SQLException e) { }
        
        oRSet = oStmt.executeQuery(oMbrsStr.toString());
        
        while (oRSet.next())
          oBlockMap.put(oRSet.getString(1), bBlocked);
        
        oRSet.close();
        oStmt.close();
        
      } // fi (gu_blacklist)
    } // fi (iMemberCount)
    
    oConn.close("memberlisting"); 
  }
  catch (SQLException e) {  
    oMembers = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("memberlisting");
    oConn = null;  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=de_list%>[~: miembros de la lista de distribuci&oacute;n~]</TITLE>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" DEFER="defer">
    <!--
        // [~//Variables globales para traspasar la instancia clickada al menu contextual~]
        var jsInstanceId;
        var jsInstanceNm;
            
<%
          // [~//Escribir los nombres de instancias en Arrays JavaScript~]
          // [~//Estos arrays se usan en las llamadas de borrado múltiple.~]
          
          out.write("        var jsInstances = new Array(");
            for (int i=0; i<iMemberCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oMembers.getString(2,i) + "\"");
            }
          out.write(");\n");          
%>

        // ----------------------------------------------------
        	
	function createInstance() {	  
	  // [~//Crear una nueva instancia del tipo de objeto listado~]
	  self.open ("member_wizard_01.jsp?gu_list=<%=gu_list%>&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>"), "editinstance", "directories=no,toolbar=no,menubar=no,top=" +  (screen.height-600)/2+ ",left=" + (screen.width-800)/2 + ",width=800,height=600,scrollbars=yes,toolbar=no,menubar=no");	  
	} // createInstance()

        // ----------------------------------------------------

	function listEMails() {
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;

          chi.value = "";	  	  
  	  
          for (var i=0;i<jsInstances.length; i++) {
            while (frm.elements[offset].type!="checkbox") offset++;
  	      if (frm.elements[offset].checked)
              chi.value += jsInstances[i] + ",";
            offset++;
          } // next()

          if (chi.value.length>0)
            return chi.value.substr(0,chi.value.length-1);
          else
            return "";
	      
	}  // listEMails
	
        // ----------------------------------------------------
	
	function deleteMembers() {
	  // [~//Borrar las instancias marcadas con checkboxes~]
	  
	  var frm = document.forms[0];
	  	  
	  if (window.confirm("[~¿Está seguro de que desea eliminar los miembros seleccionados?~]")) {
	  	  
	    frm.checkeditems.value = listEMails();
	    
	    if (frm.checkeditems.value.length>0) {
	      frm.action = "member_edit_delete.jsp";
              frm.submit();
            }

          } // fi (confirm)
	} // deleteMembers()

        // ----------------------------------------------------
	
	function deactivateMembers() {
	  // [~//Borrar las instancias marcadas con checkboxes~]
	  
	  var frm = document.forms[0];
	  	  
	  if (window.confirm("[~¿Está seguro de que desea desactivar los miembros seleccionados?~]")) {
	  	  
	    frm.checkeditems.value = listEMails();
	    
	    if (frm.checkeditems.value.length>0) {
	      frm.action = "member_edit_activate.jsp";
              frm.submit();
            }

          } // fi (confirm)
	} // deactivateMembers()

        // ----------------------------------------------------
	
	function blockMembers() {
	  // [~//Borrar las instancias marcadas con checkboxes~]
	  
	  var frm = document.forms[0];
	  	  
	  if (window.confirm("[~¿Está seguro de que desea bloquear los miembros seleccionados?~]")) {
	  	  
	    frm.checkeditems.value = listEMails();
	    
	    if (frm.checkeditems.value.length>0) {
	      frm.action = "member_edit_block.jsp?de_list=" + getURLParam("de_list");
              frm.submit();
            }

          } // fi (confirm)
	} // blockMembers()
	
        // ----------------------------------------------------

	function modifyMember(id) {
	  
	  window.open ("member_edit.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&gu_list=" + getURLParam("gu_list") + "&de_list=" + getURLParam("de_list") + "&tp_list=<%=tp_list%>&gu_member=" + id, "editmember", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-460)/2 + ",left=" + (screen.width-500)/2 + ",width=500,height=460");
	}

        // ----------------------------------------------------

	function sortBy(fld) {
	  // Ordenar por un campo
	  
	  window.location = "member_listing.jsp?gu_list=<%=gu_list%>&de_list=" + escape("<%=de_list%>") + "&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>" + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	}			

        // ----------------------------------------------------

        function selectAll() {
          // [~//Seleccionar/Deseleccionar todas las instancias~]
          
          var frm = document.forms[0];
          var offset = 0;

          while (frm.elements[offset].type!="checkbox") offset++;
          
	  for (var i=0;i<jsInstances.length; i++) {
    	    frm.elements[offset].checked = !frm.elements[offset].checked;
            offset++;
	  } // next()            
                        
        } // selectAll()
       
       // ----------------------------------------------------
	
	function findInstance() {
	  // [~//Recargar la página para buscar una instancia~]
	  	  
	  var frm = document.forms[0];
	  
	  if (frm.find.value.length>0)
	    window.location = "member_listing.jsp?gu_list=<%=gu_list%>&de_list=<%=de_list%>&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value);
	  else
	    window.location = "member_listing.jsp?gu_list=<%=gu_list%>&de_list=<%=de_list%>&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>";
	  
	} // findInstance()

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
      
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	} // setCombos()
    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <!--%@ include file="../common/tabmenu.jspf" %-->
    <FORM METHOD="post">
      <TABLE WIDTH="100%"><TR><TD><IMG SRC="../skins/<%=sSkin%>/hglogopeq.jpg" BORDER="0" ALIGN="MIDDLE"></TD></TR></TABLE>  
      <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1"><%=de_list%>[~: miembros de la lista de distribuci&oacute;n~]</FONT></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=request.getParameter("maxrows")%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=request.getParameter("skip")%>">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <INPUT TYPE="hidden" NAME="gu_list" value="<%=gu_list%>">
      <INPUT TYPE="hidden" NAME="de_list" value="<%=de_list%>">
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Nuevo~]"></TD>
        <TD VALIGN="middle">
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert ('[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]')" CLASS="linkplain">[~Nuevo~]</A>
<% } else { %>
          <A HREF="#" onclick="createInstance()" CLASS="linkplain">[~Nuevo~]</A>
<% } %>
        </TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Eliminar~]"></TD>
        <TD>
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert ('[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]')" CLASS="linkplain">[~Eliminar~]</A>
<% } else { %>
          <A HREF="javascript:deleteMembers()" CLASS="linkplain">[~Eliminar~]</A>
<% } %>
        </TD>
        <TD ALIGN="right" VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="[~Buscar~]"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE="b.<%=DB.tx_name%>">[~Nombre~]<OPTION VALUE="b.<%=DB.tx_surname%>">[~Apellidos~]<OPTION VALUE="b.<%=DB.tx_email%>">[~e-mail~]</SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="#" onclick="findInstance();return false;" CLASS="linkplain" TITLE="[~Buscar~]">[~Buscar~]</A>
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="[~Descartar búsqueda~]"></TD>
        <TD VALIGN="bottom">
          <A HREF="#" onclick="document.forms[0].find.value='';findInstance();" CLASS="linkplain" TITLE="Descartar búsqueda">[~Descartar~]</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;[~Mostrar~]&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100</SELECT><FONT CLASS="textplain"></FONT>
        </TD>
        </TR>
        <TR>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/crm/inactive18.gif" BORDER="0" ALT="[~Desactivar~]"></TD>
          <TD VALIGN="middle">
<% if (bIsGuest) { %>
            <A HREF="#" onclick="alert ('[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]')" CLASS="linkplain">[~Desactivar~]</A>
<% } else { %>
            <A HREF="javascript:deactivateMembers()" CLASS="linkplain">[~Desactivar~]</A>
<% } %>
          </TD>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/crm/halt18.gif" BORDER="0" ALT="[~Bloquear~]"></TD>
          <TD VALIGN="middle">
<% if (bIsGuest) { %>
            <A HREF="#" onclick="alert ('[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]')" CLASS="linkplain">[~Bloquear~]</A>
<% } else { %>
            <A HREF="javascript:blockMembers()" CLASS="linkplain">[~Bloquear~]</A>
<% } %>
          </TD>
          <TD ALIGN="center" VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/refresh.gif" HEIGHT="16" BORDER="0" ALT="[~Actualizar~]"></TD>
          <TD COLSPAN="3">
	  <A HREF="javascript:window.document.location.reload()" CLASS="linkplain" TITLE="Actualizar">[~Actualizar~]</A>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<%        if (sWhere.length()==0) {
            out.write("            <FONT CLASS=\"textplain\"><B>Ver</B>&nbsp;&nbsp;<INPUT TYPE=\"radio\" NAME=\"viewonly\"");
            if (0==iOnly) out.write("CHECKED");
            out.write(" onclick=\"viewOnly(0)\">&nbsp;[~Todos~]&nbsp;&nbsp;<INPUT TYPE=\"radio\" NAME=\"viewonly\"");
            if (1==iOnly) out.write("CHECKED");
            out.write(" onclick=\"viewOnly(1)\">&nbsp;[~Activos~]&nbsp;&nbsp;<INPUT TYPE=\"radio\" NAME=\"viewonly\"");            
            if (2==iOnly) out.write("CHECKED");
            out.write(" onclick=\"viewOnly(2)\">&nbsp;[~Inactivos~]&nbsp;&nbsp;<INPUT TYPE=\"radio\" NAME=\"viewonly\"");
            if (3==iOnly) out.write("CHECKED");
            out.write(" onclick=\"viewOnly(3)\">&nbsp;[~Bloqueados~]");
          }
%>
	  </TD>
	</TR>
	<TR>
          <TD VALIGN="bottom">&nbsp;<IMG SRC="../images/images/crm/member_load.gif" BORDER="0" WIDTH="24" HEIGHT="24" ALT="[~Combinar con otra Lista~]"></TD>
          <TD COLSPAN="3" VALIGN="middle"><A HREF="list_merge.jsp?id_domain?<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_list=<%=gu_list%>" CLASS="linkplain">[~Combinar con otra Lista~]</A></TD>
          <TD COLSPAN="4"></TD>
	</TR>
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0" WIDTH="100%">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  // [~//Pintar los enlaces de siguiente y anterior~]
    
          if (iSkip>0) // [~//Si iSkip>0 entonces hay registros anteriores~]
            out.write("            <A HREF=\"member_listing.jsp?gu_list=" + gu_list + "&de_list=" + Gadgets.URLEncode(de_list) + "&id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;[~Anteriores~]" + "</A>&nbsp;&nbsp;&nbsp;");
    
          if (!oMembers.eof())
            out.write("            <A HREF=\"member_listing.jsp?gu_list=" + gu_list + "&de_list=" + Gadgets.URLEncode(de_list) + "&id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">[~Siguientes~]&nbsp;&gt;&gt;</A>");
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(1);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==1 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="[~Ordenar por este campo~]"></A>&nbsp;<B>[~Miembro~]</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="[~Ordenar por este campo~]"></A>&nbsp;<B>[~e-mail~]</B></TD>
          <TD CLASS="tableheader" WIDTH="20px" ALIGN="center" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="[~Seleccionar todos~]"></A></TD></TR>
<%
  	  String sStrip,sMemberId,sContact;

	  for (int i=0; i<iMemberCount; i++) {  
  	    
  	    if (oMembers.isNull(0,i) && oMembers.isNull(1,i))
  	      sContact = "<I>([~sin nombre~])</I>";
  	    else
    	      sContact = oMembers.getStringNull(0,i,"") + ", " + oMembers.getStringNull(1,i,"");

	    sMemberId = oMembers.getStringNull(4,i,null);
	    if (null==sMemberId) sMemberId = oMembers.getStringNull(3,i,null);
	    
	    sStrip = String.valueOf((i%2)+1);	    
%>            
            <TR>              
              <TD CLASS="strip<% out.write(sStrip); %>" valign="middle">&nbsp;
<%
              if (null!=sMemberId)
                out.write("                <A CLASS=\"linkplain\" HREF=\"#\" TITLE=\"[~Editar miembro~]\" onclick=\"modifyMember('" + sMemberId + "')\">" + sContact + "</A>\n");
	      else
                out.write("                " + sContact + "\n");
%>
              </TD>
              <TD CLASS="strip<% out.write(sStrip); %>" valign="middle">&nbsp;
<%	      if (oMembers.getShort(5,i)==(short)0)	      
	        out.write("<SPAN onmouseover=\"this.style.cursor='help';\" onmouseout=\"this.style.cursor='auto';\" TITLE='[~Miembro Inactivo~]'><FONT COLOR=gray>" + oMembers.getString(2,i) + "</FONT></SPAN>");
	      else {
	        if (gu_blacklist!=null) {
	          if (oBlockMap.get(oMembers.getString(2,i))!=null)
	            out.write("<SPAN onmouseover=\"this.style.cursor='help';\" onmouseout=\"this.style.cursor='auto';\" TITLE='[~Miembro Bloqueado~]'><FONT COLOR=red>" + oMembers.getString(2,i) + "</FONT></SPAN>");
	          else
	            out.write(oMembers.getString(2,i));
	        }
	        else
	          out.write(oMembers.getString(2,i));	        
	      }
%>
	      </TD>
              <TD CLASS="strip<% out.write(sStrip); %>" valign="middle" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="M<% out.write(oMembers.getStringNull(3,i,"")+"_"+oMembers.getStringNull(4,i,"")); %>">
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
    <!-- DynFloat -->
    <DIV id="divHolder" style="width:100px;height:20px;z-index:200;visibility:hidden;position:absolute;top:31px;left:0px"></DIV>
    <FORM name="divForm"><input type="hidden" name="divField" value=""></FORM>
    <SCRIPT LANGUAGE="JavaScript" src="../javascript/dynfloat.js"></SCRIPT>    
    <!-- DynFloat -->

    <!-- RightMenuBody -->
    <DIV class="menuDiv" id="rightMenuDiv">
      <TABLE border="0" cellpadding="0" cellspacing="0" width="100">
        <TR height="1">
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR height="1">
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#FFFFFF"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#FFFFFF"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR>
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#FFFFFF"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#D6D3CE">
            <!-- Opciones -->
            <DIV class="menuCP" onMouseOver="menuHighLight(this)" onMouseOut="menuHighLight(this)" onClick="modifyInstace(jsInstanceId)">[~Abrir~]</DIV>
            <DIV id="menuOpt01" class="menuE" onMouseOver="menuHighLight(this)" onMouseOut="menuHighLight(this)" onClick="clone()">[~Duplicar~]</DIV>
            <HR size="2" width="98%">
            <!-- /Opciones -->
          </TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR height="1">
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR height="1">
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
      </TABLE>
    </DIV>
    <!-- /RightMenuBody -->    
</BODY>
</HTML>
