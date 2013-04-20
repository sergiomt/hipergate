<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.QueryByForm" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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

  // [~//Obtener la raiz del directorio /storage~]
  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");
  
  // [~//Resolucion de pantalla en el cliente~]
  int iScreenWidth;
  float fScreenRatio;

  // [~//Obtener el dominio y la workarea~]
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String screen_width = request.getParameter("screen_width");

  // [~//La resolución de pantalla debe pasarse como parámetro por JavaScript cliente~]
  // [~//en caso de que el parámetro no exista, se asume 800x600~]
  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else {
    try { iScreenWidth = Integer.parseInt(screen_width); } catch (NumberFormatException nfe) { iScreenWidth = 800; }
  }
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;
    
  // [~//Cadena de de filtrado (claúsula WHERE)~]
        
  String sField = request.getParameter("field")==null ? "" : request.getParameter("field");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
        

  int iFellowCount = 0;
  DBSubset oFellows;        
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
  
  if (request.getParameter("skip")!=null) {
    try { iSkip = Integer.parseInt(request.getParameter("skip")); } catch (NumberFormatException nfe) { iSkip = 0; }  
  }
  else {
    iSkip = 0;
  }
  
  if (iSkip<0) iSkip = 0;

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  // [~//Obtener una conexión del pool a bb.dd. (el nombre de la conexión es arbitrario)~]
  JDCConnection oConn = null;
  
  boolean bIsGuest = true;
  boolean bIsAdmin = false;

  try {
  
    oConn = GlobalDBBind.getConnection("fellowlisting");

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
    
    if (sWhere.length()>0) {
      QueryByForm oQBF = new QueryByForm("file://" + sStorage + "/qbf/" + request.getParameter("queryspec") + ".xml");
    
      oFellows = new DBSubset (oQBF.getBaseObject(), 
      			       "gu_fellow,tx_name,tx_surname,de_title,tx_company,tx_dept,tx_division,tx_location,tx_email,work_phone,ext_phone,mov_phone",
      				 "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oFellows.setMaxRows(iMaxRows);
      iFellowCount = oFellows.load (oConn, iSkip);
    }
    
    else if (sFind.length()==0 || sField.length()==0) {
      // [~//Listados sin filtro~]
      
      oFellows = new DBSubset ("k_fellows", 
      			       "gu_fellow,tx_name,tx_surname,de_title,tx_company,tx_dept,tx_division,tx_location,tx_email,work_phone,ext_phone,mov_phone",
      				 DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oFellows.setMaxRows(iMaxRows);
      iFellowCount = oFellows.load (oConn, iSkip);

    }
    else {
      oFellows = new DBSubset ("k_fellows b", 
      			       "gu_fellow,tx_name,tx_surname,de_title,tx_company,tx_dept,tx_division,tx_location,tx_email,work_phone,home_phone,mov_phone,ext_phone",
      			       "(" + DB.gu_workarea+ "='" + gu_workarea + "') AND (" + sField + " " + DBBind.Functions.ILIKE + " ?)" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oFellows.setMaxRows(iMaxRows);
      Object[] aFind = { "%" + sFind + "%" };      
      iFellowCount = oFellows.load (oConn, aFind, iSkip);
    }
    
    oConn.close("fellowlisting"); 
  }
  catch (SQLException e) {  
    oFellows = null;
    oConn.close("fellowlisting");
    oConn = null;  

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Corporate Directory</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript">
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript">
    var menuLayer;
    dynapi.onLoad(init);
    function init() {
 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setHTML(rightMenuHTML);
    }
  </SCRIPT>
  <SCRIPT SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
        var jsFellowId;
        var jsFellowNm;
            
        <%
          
          out.write("var jsFellows = new Array(");
            for (int i=0; i<iFellowCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oFellows.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createFellow() {	  
	  
	  self.open ("fellow_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "editfellow", "directories=no,toolbar=no,menubar=no,width=640,height=" + (screen.height<=600 ? "520" : "600"));	  
	} // createFellow()

        // ----------------------------------------------------
	
	function deleteFellows() {
	  // [~//Borrar las instancias marcadas con checkboxes~]

<% if (!bIsAdmin) { %>
	alert ("Your priviledge level as guest does not allow you to perform this action");
<% } else { %>
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to delete selected instances?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "fellow_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsFellows.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsFellows[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
<% } %>
	} // deleteFellows()
	
        // ----------------------------------------------------

	function modifyFellow(id) {	  
	  self.open ("fellow_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_fellow=" + id + "&gu_workarea=<%=gu_workarea%>", "editfellow", "directories=no,toolbar=no,menubar=no,width=640,height=" + (screen.height<=600 ? "520" : "600"));
	}	

        // ----------------------------------------------------

	function sortBy(fld) {
	  // [~//Ordenar por un campo~]
	  
	  window.location = "fellow_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>" + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	}			

        // ----------------------------------------------------

        function selectAll() {
          // [~//Seleccionar/Deseleccionar todas las instancias~]
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsFellows.length; c++)                        
            eval ("frm.elements['" + jsFellows[c] + "'].click()");
        } // selectAll()

       // ----------------------------------------------------
	
	function showSchedule(id) {
	  var dt = new Date();
	  
	  window.location = "month_schedule.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + id + "&selected=" + getURLParam("selected") + "&subselected=1" + "&year=" + String(dt.getFullYear()-1900) + "&month=" + String(dt.getMonth()) + "&screen_width=" + screen.width;
	}
       
       // ----------------------------------------------------
	
	function findFellow() {
	  // [~//Recargar la página para buscar una instancia~]
	  	  
	  var frm = document.forms[0];
	  
	  if (frm.find.value.length>0)
	    window.location = "fellow_listing.jsp?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	} // findFellow()

      // ------------------------------------------------------

      function addPhoneCall(gu) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        window.open("phonecall_edit_f.jsp?gu_workarea=<%=gu_workarea%>&gu_fellow=" + gu, "addphonecall", "directories=no,toolbar=no,menubar=no,width=500,height=400");       
<% } %>        
      } // addPhoneCall

      // ----------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {
        // [~//Funcion temporizada que se llama cada 100 milisegundos para ver si ha terminado el clonado~]
        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.tx_surname%>");
          document.forms[0].find.value = unescape(jsFellowNm);
          findFellow();
        }
      } // findCloned()
      
      function clone() {        
        // [~//Abrir una ventana de clonado y poner un temporizador para recargar la página cuando se termine el clonado~]
        
<% if (!bIsAdmin) { %>
	alert ("Your priviledge level as guest does not allow you to perform this action");
<% } else { %>
        winclone = window.open ("../common/clone.jsp?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&datastruct=fellow_clon&gu_instance=" + jsFellowId +"&opcode=CFLW&classid=20", "clonefellow", "directories=no,toolbar=no,menubar=no,width=320,height=200");                
        intervalId = setInterval ("findCloned()", 100);
<% } %>

      }	// clone()
      
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	} // setCombos()
    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="get" onSubmit="findFellow();return false;">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Corporate Personel Listing</FONT></TD></TR></TABLE>  
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
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle">
<% if (!bIsAdmin) { %>
          <A HREF="#" onclick="alert('Your priviledge level as guest does not allow you to perform this action')" CLASS="linkplain">New</A>
<% } else { %>
          <A HREF="#" onclick="createFellow()" CLASS="linkplain">New</A>
<% } %>
        </TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD>
<% if (!bIsAdmin) { %>
          <A HREF="#" onclick="alert('Your priviledge level as guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
          <A HREF="javascript:deleteFellows()" CLASS="linkplain">Delete</A>
<% } %>
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE="tx_name">Name<OPTION VALUE="tx_surname">Surname<OPTION VALUE="de_title">Position<OPTION VALUE="tx_company">Company<OPTION VALUE="tx_dept">Department<OPTION VALUE="tx_division">Division</SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="#" onclick="findFellow();return false;" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></TD>
        <TD VALIGN="bottom">
          <A HREF="#" onclick="window.document.location='fellow_listing.jsp?id_domain=' + getCookie('domainid') + '&n_domain=' + escape(getCookie('domainnm')) + '&skip=0&selected=' + getURLParam('selected') + '&subselected=' + getURLParam('subselected');" CLASS="linkplain" TITLE="Discard Find Filter">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  // [~//Pintar los enlaces de siguiente y anterior~]
          
          if (iFellowCount>0) {
            if (iSkip>0) // [~//Si iSkip>0 entonces hay registros anteriores~]
              out.write("            <A HREF=\"fellow_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oFellows.eof())
              out.write("            <A HREF=\"fellow_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iFellowCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Position</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>E-mail</B></TD>
          <TD CLASS="tableheader" WIDTH="100px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Telephone</B></TD>
          <TD CLASS="tableheader" WIDTH="80px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Extension</B></TD>
          <TD CLASS="tableheader" WIDTH="100px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Mobile</B></TD>
          <TD CLASS="tableheader" WIDTH="20px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" ALIGN="center"><A HREF="#" onclick="selectAll()" TITLE="Select all"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%
	  String sFellowId,sTxName,sTxSurname;
	  for (int i=0; i<iFellowCount; i++) {
            sFellowId = oFellows.getString(0,i);
            sTxName = oFellows.getStringNull(1,i,"");
            sTxSurname = oFellows.getStringNull(2,i,"");
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<%=((i%2)+1)%>">&nbsp;<A HREF="#" onclick="modifyFellow('<%=sFellowId%>');" oncontextmenu="jsFellowId='<%=sFellowId%>'; jsFellowNm='<%=Gadgets.URLEncode(sTxSurname)%>'; return showRightMenu(event);" onmouseover="window.status='Edit Employee'; return true;" onmouseout="window.status='';" TITLE="Click Right Mouse Button for Context Menu"><%=sTxSurname + "," + sTxName%></A></TD>
              <TD CLASS="strip<%=((i%2)+1)%>">&nbsp;<%=oFellows.getStringNull(3,i,"")%></TD>
              <TD CLASS="strip<%=((i%2)+1)%>">&nbsp;<%=oFellows.getStringNull(8,i,"")%></TD>
              <TD WIDTH="100px" CLASS="strip<%=((i%2)+1)%>">&nbsp;<%=oFellows.getStringNull(9,i,"")%></TD>
              <TD WIDTH="80px" CLASS="strip<%=((i%2)+1)%>">&nbsp;<%=oFellows.getStringNull(10,i,"")%></TD>
              <TD WIDTH="100px" CLASS="strip<%=((i%2)+1)%>">&nbsp;<%=oFellows.getStringNull(11,i,"")%></TD>
              <TD CLASS="strip<%=((i%2)+1)%>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<%=sFellowId%>">
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
    <SCRIPT language="JavaScript" type="text/javascript">
      addMenuOption("Open","modifyFellow(jsFellowId)",1);
      addMenuOption("Duplicate","clone()",0);
      addMenuSeparator();
      addMenuOption("Show Calendar","showSchedule(jsFellowId)",0);
      addMenuSeparator();
      addMenuOption("New Call","addPhoneCall(jsFellowId)",0);      
    </SCRIPT>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>