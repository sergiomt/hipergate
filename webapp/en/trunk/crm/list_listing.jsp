<%@ page import="java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %>
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

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String id_user = getCookie(request,"userid",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String screen_width = request.getParameter("screen_width");
  String gu_list = request.getParameter("gu_list");

  int iScreenWidth;
  float fScreenRatio;

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;
        
  String sField = request.getParameter("field")==null ? "" : request.getParameter("field");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
  boolean bHasAccounts = false;
        
  int iListCount = 0;
  DBSubset oLists = null;        
  Object[] aFind = { '%' + sFind + '%' };
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

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

  if (iSkip<0) iSkip = 0;

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";   
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  JDCConnection oConn = null;  
  boolean bIsGuest = true;
    
  try {
    
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("listlisting");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM "+DB.k_user_mail+" WHERE "+DB.gu_user+"=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, id_user);
    ResultSet oRSet = oStmt.executeQuery();
    bHasAccounts = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (sFind.length()==0) {
      oLists = new DBSubset (DB.k_lists, 
      			     "gu_list,tp_list,gu_query,tx_subject,de_list",
      		             DB.tp_list + "<>" + String.valueOf(DistributionList.TYPE_BLACK) + " AND " + DB.gu_workarea + "='" + gu_workarea + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oLists.setMaxRows(iMaxRows);
      iListCount = oLists.load (oConn, iSkip);
    }
    else {
      oLists = new DBSubset (DB.k_lists, 
      			     "gu_list,tp_list,gu_query,tx_subject,de_list",
      		             DB.tp_list + "<>" + String.valueOf(DistributionList.TYPE_BLACK) + " AND " + DB.gu_workarea + "='" + gu_workarea + "' AND " + sField + " " + DBBind.Functions.ILIKE + " ? " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oLists.setMaxRows(iMaxRows);
      iListCount = oLists.load (oConn, new Object[] { "%" + sFind +"%" }, iSkip);
    }
    
    oConn.close("listlisting"); 
  }
  catch (SQLException e) {  
    oLists = null;
    oConn.close("listlisting");
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

  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/dynapi/dynapi.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript">
    DynAPI.setLibraryPath('../javascript/dynapi/lib/');
    DynAPI.include('dynapi.api.*');
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript">
    var menuLayer,addrLayer;
    DynAPI.onLoad = function() { 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setVisible(true);
      menuLayer.setHTML(rightMenuHTML);
    }
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/dynapi/rightmenu.js"></SCRIPT>

  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" DEFER="defer">
    <!--
        // Variables globales para traspasar la instancia clickada al menu contextual
        var jsListId;
        var jsListTp;
        var jsListNm;
        var jsListDe;
        var jsListQr;
                    
        <%
          
          out.write("var jsLists = new Array(");
            for (int i=0; i<iListCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oLists.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createList() {	  	  
	  self.open ("list_wizard_01.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" , "listwizard", "directories=no,scrollbars=yes,toolbar=no,menubar=no,top=" + (screen.height-420)/2 + ",left=" + (screen.width-420)/2 + ",width=420,height=420");	  
	} // createList()

        // ----------------------------------------------------
	
	function deleteLists() {	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("[~¿Está seguro de que desea eliminar las listas seleccionadas?~]")) {
	  	  
	    chi.value = "";	  	  
	    
	    frm.action = "list_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsLists.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsLists[i] + ",";
              offset++;
	    } // next()

	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteLists()
	
        // ----------------------------------------------------

	function modifyList(id,nm) {	  
	  self.open ("list_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_list=" + id + "&n_list=" + escape(nm), "editlist", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-420)/2 + ",left=" + (screen.width-600)/2 + ",width=600,height=420");
	}	

        // ----------------------------------------------------

	function sortBy(fld) {
	  // Ordenar por un campo
	  
	  window.location = "list_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>" + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	}			

        // ----------------------------------------------------

        function selectAll() {
          // Seleccionar/Deseleccionar todas las instancias
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsLists.length; c++)                        
            eval ("frm.elements['" + jsLists[c] + "'].click()");
        } // selectAll()
       
       // ----------------------------------------------------
	
	function findList() {	  	  
	  var frm = document.forms[0];

	  if (frm.find.value!="")
	    window.location = "list_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=tx_subject&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&maxrows=" + document.forms[0].maxrows.value;
          else
	    window.location = "list_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&maxrows=" + document.forms[0].maxrows.value;
	} // findList()

       // ----------------------------------------------------
	
	function editMembers(id,de) {
          if (jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_STATIC)); %> || jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_DIRECT)); %>)
            window.open('member_listing.jsp?gu_list=' + id + '&de_list=' + escape(de),'wMembers','height=' + (screen.height>600 ? '600' : '520') + ',width= ' + (screen.width>800 ? '800' : '760') + ',scrollbars=yes,toolbar=no,menubar=no');
          else if (jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_DYNAMIC)); %>)
            window.open('../common/qbf.jsp?caller=list_listing.jsp&queryspec=listmember&caller=list_listing.jsp?gu_list=' + id + '&de_title=' + escape('Consulta de Miembros: ' + de) + '&queryspec=listmember&queryid=' + jsListQr,'wMemberList','height=' + (screen.height>600 ? '600' : '520') + ',width= ' + (screen.width>800 ? '800' : '760') + ',scrollbars=yes,toolbar=no,menubar=no');
        }

       // ----------------------------------------------------
	
	function editQuery(id,de) {
          if (jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_DYNAMIC)); %>)
            window.open('../common/qbf.jsp?caller=list_listing.jsp&queryspec=listmember&caller=list_listing.jsp?gu_list=' + id + '&de_title=' + escape('Consulta de Miembros: ' + de) + '&queryspec=listmember&queryid=' + jsListQr,'wMemberQuery','height=' + (screen.height>600 ? '600' : '520') + ',width= ' + (screen.width>800 ? '800' : '760') + ',scrollbars=yes,toolbar=no,menubar=no');
        }

       // ----------------------------------------------------
	
	function mergeMembers(id,de) {
          if (isRightMenuOptionEnabled(3)) {
            window.open('list_merge.jsp?id_domain=' + getCookie('domainid') + '&gu_workarea=' + getCookie('workarea') + '&gu_list=' + id + '&de_list=' + escape(de),'wListMerge','height=460,width=600,scrollbars=yes,toolbar=no,menubar=no');
          }
        }

      // ----------------------------------------------------
        	
	function createOportunity (id,de) {	  
<% if (bIsGuest) { %>
        alert("[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]");
<% } else { %>
	  self.open ("oportunity_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_list=" + id + "&de_list=" + escape(de), "createoportunity", "directories=no,toolbar=no,menubar=no,width=640,height=560");	  
<% } %>
	} // createOportunity()

      // ------------------------------------------------------

      function createProject(gu,de) {
<% if (bIsGuest) { %>
        alert("[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]");
<% } else { %>
        window.open("prj_create.jsp?gu_workarea=<%=gu_workarea%>&gu_list=" + gu + "&de_list=" + escape(de), "addproject", "directories=no,toolbar=no,menubar=no,width=540,height=280");       
<% } %>
      } // createProject

      // ------------------------------------------------------

<% if (bHasAccounts) { %>
      function sendEmail(gu,de) {
<% if (bIsGuest) { %>
        alert("[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]");
<% } else { %>
        window.open("../hipermail/msg_new_f.jsp?folder=drafts&to={"+escape(de)+"}", "sendmailtolist");       
<% } %>
      } // sendEmail
<% } %>

      // ------------------------------------------------------

<% if (!bHasAccounts) { %>
      function configEmail() {
<% if (bIsGuest) { %>
        alert("[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]");
<% } else { %>
	alert ("[~Debe configurar previamente el servidor de correo para enviar e-mails~]");
	top.document.location.href="../hipermail/mail_config_f.htm?selected=1&subselected=0"
<% } %>
      } // configEmail
<% } %>
	
      // ------------------------------------------------------

      function configureMenu() {
        if (jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_STATIC)); %> || jsListTp==<% out.write(String.valueOf(DistributionList.TYPE_DIRECT)); %>) {
          enableRightMenuOption(4);
          disableRightMenuOption(5);
        }
        else {
          disableRightMenuOption(4);
          enableRightMenuOption(5);
        }          
      }
      
      // ----------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {
        // [~//Funcion temporizada que se llama cada 100 milisegundos para ver si ha terminado el clonado~]
        
        if (winclone.closed) {
          clearInterval(intervalId);
          document.forms[0].find.value = jsListNm;
          findList();
        }
      } // findCloned()
      
      function clone() {        
        // [~//Abrir una ventana de clonado y poner un temporizador para recargar la página cuando se termine el clonado~]
<% if (bIsGuest) { %>
        alert ("[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]");
<% } else { %>
        winclone = window.open ("list_clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_instance=" + jsListId + "&opcode=CLST&classid=96", "clonelist", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-200)/2 + ",left=" + (screen.width-320)/2 + ",width=320,height=200");                
        intervalId = setInterval ("findCloned()", 100);
<% } %>
      }	// clone()
      
    //-->    
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	} // setCombos()  
    //-->    
  </SCRIPT>  
  <TITLE>hipergate :: [~Listas de distribución~]</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post" onSubmit="findList();return false;">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">[~Listas de Distribuci&oacute;n~]</FONT></TD></TR></TABLE>      
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      
      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Nueva~]"></TD>
        <TD VALIGN="middle">
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert ('[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]')" CLASS="linkplain">[~Nueva~]</A>
<% } else { %>
          <A HREF="#" onclick="createList();return false;" CLASS="linkplain">[~Nueva~]</A>
<% } %>
        </TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Eliminar~]"></TD>
        <TD>
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert ('[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]')" CLASS="linkplain">[~Eliminar~]</A>
<% } else { %>
          <A HREF="#" onclick="deleteLists();return false;" CLASS="linkplain">[~Eliminar~]</A>
<% } %>
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="[~Buscar Lista~]"></TD>
        <TD VALIGN="middle">
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="javascript:findList()" CLASS="linkplain" TITLE="[~Buscar~]">[~Buscar~]</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="[~Descartar búsqueda~]"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:document.forms[0].find.value='';findList();" CLASS="linkplain" TITLE="[~Descartar búsqueda~]">[~Descartar~]</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;[~Mostrar~]&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;[~resultados~]&nbsp;</FONT>
        </TD>
        </TR>
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  // [~//Pintar los enlaces de siguiente y anterior~]
    
          if (iSkip>0) // [~//Si iSkip>0 entonces hay registros anteriores~]
            out.write("            <A HREF=\"list_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;[~Anteriores~]" + "</A>&nbsp;&nbsp;&nbsp;");
    
          if (!oLists.eof())
            out.write("            <A HREF=\"list_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">[~Siguientes~]&nbsp;&gt;&gt;</A>");
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(300f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4)" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="[~Ordenar por este campo~]"></A>&nbsp;<B>[~Asunto~]</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(400f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5)" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="[~Ordenar por este campo~]"></A>&nbsp;<B>[~Descripci&oacute;n~]</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="[~Seleccionar todos~]"></A></TD></TR>
<%
	  String sInstId, sInstQr, sInstTp, sInstNm, sInstDe;
	  for (int i=0; i<iListCount; i++) {
            sInstId = oLists.getString(0,i);
            sInstTp = String.valueOf(oLists.getShort(1,i));
            sInstQr = oLists.getStringNull(2,i,"");
            sInstNm = oLists.getStringNull(3,i,"");
            sInstDe = oLists.getStringNull(4,i,"");            
%>
            <TR HEIGHT="14">
              <TD CLASS="strip<%=(i%2)+1%>" VALIGN="middle">&nbsp;<A HREF="#" oncontextmenu="jsListId='<%=sInstId%>'; jsListTp=<%=sInstTp%>; jsListQr='<%=sInstQr%>'; jsListNm='<%=sInstNm%>'; jsListDe='<%=sInstDe%>'; configureMenu(); return showRightMenu(event);" onmouseover="window.status='[~Editar Lista~]'; return true;" onmouseout="window.status='';" onclick="modifyList('<%=sInstId%>','<%=sInstNm%>')" TITLE="[~Bot&oacute;n Derecho para Ver el Men&uacute; Contextual~]"><%=oLists.getStringNull(3,i,"([~sin asunto~])")%></A></TD>
              <TD CLASS="strip<%=(i%2)+1%>">&nbsp;<%=oLists.getStringNull(4,i,"")%></TD>
              <TD CLASS="strip<%=(i%2)+1%>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<%=sInstId%>">
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>

    <SCRIPT language="JavaScript" type="text/javascript">
      addMenuOption("[~Abrir~]","modifyList(jsListId,jsListNm)",1);
      addMenuOption("[~Duplicar~]","clone()",0);
      addMenuOption("[~Combinar~]","mergeMembers(jsListId,jsListDe)",0);
      addMenuSeparator();
      addMenuOption("[~Editar Miembros~]","editMembers(jsListId,jsListDe)",0);
      addMenuOption("[~Editar Consulta~]","editQuery(jsListId,jsListDe)",2);
      addMenuSeparator();
      addMenuOption("[~Nueva Oportunidad~]","createOportunity(jsListId,jsListDe)",0);
<% if (((iAppMask & (1<<ProjectManager))!=0)) { %>
      addMenuOption("[~Nuevo Proyecto~]","createProject(jsListId,jsListDe)",0);
<% } %>
<% if (((iAppMask & (1<<Hipermail))!=0)) {
      if (bHasAccounts) { %>
      addMenuOption("[~Enviar e-mail~]","sendEmail(jsListId,jsListDe)",0);
<%    } else { %>
      addMenuOption("[~Enviar e-mail~]","configEmail()",0);
<% }  } %>
    </SCRIPT>
</BODY>
</HTML>
