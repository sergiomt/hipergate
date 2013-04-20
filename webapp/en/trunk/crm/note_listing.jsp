<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.crm.Contact" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><% 

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

  // [~//Obtener el dominio y la workarea~]
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String id_user = getCookie (request, "userid", null);
  
  // [~//Cadena de de filtrado (claúsula WHERE)~]
        
  String sCompanyNm = request.getParameter("nm_company");
  String sContactId = request.getParameter("gu_contact");
  String sContactNm = "";
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
        

  int iInstanceCount = 0;
  DBSubset oInstances = null;        
  Contact oCont;
  Object[] aCont = { sContactId };
  String sOrderBy;
  int iOrderBy;  

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "1 DESC";   
  
  iOrderBy = Integer.parseInt(sOrderBy.substring(0,1));

  // [~//Obtener una conexión del pool a bb.dd. (el nombre de la conexión es arbitrario)~]
  JDCConnection oConn = null;  
  
  boolean bIsGuest = true;
  
  try {

    bIsGuest = isDomainGuest (GlobalDBBind, request, response);

    oConn = GlobalDBBind.getConnection("instancelisting");
    
    oCont = new Contact();
    oCont.load(oConn, aCont);
    sContactNm = oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,"");
    oCont = null;
    
    // [~//Si el filtro no existe devolver todos los registros~]
    if (sFind.length()==0) {
      oInstances = new DBSubset (DB.k_contact_notes, 
      				 DB.pg_note + "," + DB.dt_created + "," + DB.dt_modified + "," + DB.gu_writer + "," + DB.tl_note + ",tx_fullname," + DB.tx_main_email + "," + DB.tx_note,
      				 DB.gu_contact + "='" + sContactId + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), 10);      				 
      iInstanceCount = oInstances.load (oConn);
    }
    else {
      Object[] aFind = { '%' + sFind + '%', '%' + sFind + '%', '%' + sFind + '%' };
      oInstances = new DBSubset (DB.k_contact_notes, 
      				 DB.pg_note + "," + DB.dt_created + "," + DB.dt_modified + "," + DB.gu_writer + "," + DB.tl_note + ",tx_fullname," + DB.tx_main_email + "," + DB.tx_note,
      				 "(tx_fullname " + DBBind.Functions.ILIKE + " ? OR " + DB.tl_note + " " + DBBind.Functions.ILIKE + " ? OR " + DB.tx_note + " " + DBBind.Functions.ILIKE + " ?) " +
      				 " AND " + DB.gu_contact + "='" + sContactId + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), 10);      				 
      iInstanceCount = oInstances.load (oConn, aFind);

    }
    
    oConn.close("instancelisting"); 
  }
  catch (SQLException e) {  
    oInstances = null;
    oConn.close("instancelisting");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Notes about&nbsp;<%=sContactNm%></TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/defined.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // [~//Variables globales para traspasar la instancia clickada al menu contextual~]
        var jsInstanceId;
        var jsInstanceNm;
        var intervalId;
                  
        <%
          // [~//Escribir los nombres de instancias en Arrays JavaScript~]
          // [~//Estos arrays se usan en las llamadas de borrado múltiple.~]
          
          out.write("var jsInstances = new Array(");
            for (int i=0; i<iInstanceCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oInstances.getInt(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ------------------------------------------------------

	var winadded;
	
        function findAdded() {
          // [~//Obtener una referencia a la ventana de ejecución del borrado~]
          
          if (winadded.closed) {
            clearInterval(intervalId);
            window.location.reload();
          }
        } // findAdded()

        function addNote() {
          winadded = self.open ("note_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=<%=sContactId%>&nm_contact=" + escape("<%=sContactNm%>"), "addnote", "directories=no,toolbar=no,menubar=no,width=610,height=400");
	  intervalId = setInterval ("findAdded()", 100);          
        }

        // ----------------------------------------------------
      
        function findDeleted() {
          // [~//Obtener una referencia a la ventana de ejecución del borrado~]
          var windelete = open ("","notesdelete");
          
          if (defined(windelete))
            if (windelete.closed) {
              clearInterval(intervalId);
              window.location.reload();
            }
          else {
            clearInterval(intervalId);
            window.location.reload();
          }
        } // findDeleted()
	
	// ----------------------------------------------------
	
	function deleteInstances() {
	  // [~//Borrar las instancias marcadas con checkboxes~]
	  
	  var offset = 0;
	  var frm = document.forms[1];
	  var chi = document.forms[0].checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to delete selected notes?")) {
	  	  
	    chi.value = "";	  	  
	    document.forms[0].action = "note_edit_delete.jsp";
	  	  
	    for (var i=0;i<jsInstances.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
              if (frm.elements[offset].checked)
                chi.value += jsInstances[i] + ",";
              offset++;  
            } // next()
            	    	    	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
	      
              document.forms[0].submit();
	      
	      intervalId = setInterval ("findDeleted()", 100);
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteInstances()
	
        // ----------------------------------------------------

	function sortBy(fld) {
	  // [~//Ordenar por un campo~]
	  
	  window.location = "note_listing.jsp?gu_contact=<%=sContactId%>&nm_company=" + escape("<%=sCompanyNm%>") + "&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&orderby=" + fld + "&find=<%=sFind%>";
	}			

        // ----------------------------------------------------

        function selectAll() {
          // [~//Seleccionar/Deseleccionar todas las instancias~]
          
          var frm = document.forms[1];
          
          for (var c=0; c<jsInstances.length; c++)                        
            eval ("frm.elements['n" + jsInstances[c] + "'].click()");
        } // selectAll()
       
       // ----------------------------------------------------
	
	function findNote() {
	  // [~//Recargar la página para buscar una instancia~]
	  	  
	  var frm = document.forms[1];
	  
	  if (frm.find.value.length>0)
	    window.location = "note_listing.jsp?gu_contact=<%=sContactId%>&nm_company=" + escape("<%=sCompanyNm%>") + "&id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&orderby=<%=sOrderBy%>&find=" + escape(frm.find.value);
	} // findInstance()

    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      // ----------------------------------------------------
      
      function saveNote(pg) {      	 
	  eval ("document.forms[0].tx_note.value = document.forms[1].tx_" + pg + ".value;");
	  eval ("document.forms[0].pg_note.value = '" + pg + "';");
	  document.forms[0].submit();
      } // saveNote()
    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <BR><BR>
  <TABLE><TR><TD CLASS="striptitle"><FONT CLASS="title1">Notes about&nbsp;<%=sContactNm%> (<%=sCompanyNm%>)</FONT></TD></TR></TABLE>
  <FORM METHOD="post" ACTION="note_edit_store.jsp" TARGET="notesdelete">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=sContactId%>">
      <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <INPUT TYPE="hidden" NAME="pg_note">
      <INPUT TYPE="hidden" NAME="tx_note">
  </FORM><FORM>
  <TABLE CELLSPACING="2" CELLPADDING="2">
     <TR><TD COLSPAN="7" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
     <TR>
       <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" HEIGHT="16" BORDER="0" ALT="New"></TD>
       <TD VALIGN="middle">
<% if (bIsGuest) { %>
         <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New</A>
<% } else { %>
         <A HREF="#" onclick="addNote()" CLASS="linkplain">New</A>
<% } %>
       </TD>
       <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
       <TD>
<% if (bIsGuest) { %>
         <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
         <A HREF="#" onclick="deleteInstances()" CLASS="linkplain">Delete</A>
<% } %>
       </TD>
       <TD>&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Search"></TD>
       <TD><INPUT TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>"></TD>
       <TD><A CLASS="linkplain" HREF="javascript:findNote()">Search</A></TD>
     </TR>
     <TR><TD COLSPAN="7" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  </TABLE>
<% if (sFind.length()>0 && iInstanceCount==0)
     out.write("<BR><FONT CLASS=\"textplain\">Could not find any note containing substring;nbsp;<I>" + sFind + "</I></FONT><BR>");
%>
      <TABLE CELLSPACING="1" CELLPADDING="0">
<%

      int iNoteId;
      String sNoteDt, sNoteTl, sFullNm, sEmail, sNoteTx;

      for (int i=0; i<iInstanceCount; i++) {
        iNoteId = oInstances.getInt(0,i);
        if (null==oInstances.get(2,i))
          sNoteDt = oInstances.getDateFormated(1,i,"yyyy-MM-dd");
	else
          sNoteDt = oInstances.getDateFormated(2,i,"yyyy-MM-dd");
        sNoteTl = oInstances.getStringNull(4,i,"");
	sFullNm = oInstances.getStringNull(5,i,"");
	sEmail = oInstances.getStringNull(6,i,"");
	sNoteTx = oInstances.getStringNull(7,i,"");
%>            
        <TR>
          <!-- Titulo -->
          <TD CLASS="tableheader" WIDTH="510px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B><%=sNoteTl%></B></TD>
          <TD CLASS="tableheader" WIDTH="80px" ALIGN="right" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by Date"></A>&nbsp;<B>Date</B>&nbsp;</TD>
<%        if (0==i) { %> 
          <TD CLASS="tableheader" WIDTH="20px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" ALIGN="center"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Select all"></A></TD>
<%        } else  {%> 
          <TD CLASS="tableheader" WIDTH="20px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
<%        } %> 
	</TR>
        <TR>
          <!-- Redactor -->
          <TD CLASS="strip2"><FONT CLASS="textplain">De:&nbsp;</FONT><A CLASS="linkplain" HREF="mailto:<%=sEmail%>" TITLE="mailto:<%=sEmail%>"><%=sFullNm%></A></TD>
          <!-- Fecha -->
          <TD CLASS="strip2" WIDTH="80px" ALIGN="right" NOWRAP><FONT FACE="textplain"><%=sNoteDt%>&nbsp;</FONT></TD>
          <!-- Checkbox -->
          <TD CLASS="strip2" WIDTH="20px" ALIGN="center"><INPUT TYPE="checkbox" NAME="<%="n" + String.valueOf(iNoteId)%>"></TD>
	</TR>
        <TR>
          <TD CLASS="strip1" COLSPAN="3">
            <TEXTAREA NAME="tx_<%=iNoteId%>" COLS="70" ROWS="5"><%=sNoteTx%></TEXTAREA>
          </TD>
        </TR>
        <TR>
          <TD CLASS="strip1" COLSPAN="3">
            <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onClick="saveNote(<%=iNoteId%>)">
          </TD>
        </TR>
        <TR><TD CLASS="strip1" COLSPAN="3"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="2" BORDER="0"></TD></TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
