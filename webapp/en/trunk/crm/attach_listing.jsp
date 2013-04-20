<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.crm.Contact" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
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

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = getCookie(request,"workarea",""); 
  
  String gu_contact = request.getParameter("gu_contact");
  String full_name = null;
  
        
  String sField = request.getParameter("field")==null ? "" : request.getParameter("field");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
        
  int iAttachCount = 0;
  DBSubset oAttachLocats = null;        
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
  Contact oCont; 
  
  boolean bIsGuest = true;
   
  try {
  
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("attachmentlisting");
      
    oCont = new Contact(oConn, gu_contact);
    
    full_name = oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,"");
    
    // Si el filtro no existe devolver todos los registros
    if (sFind.length()==0) {
      oAttachLocats = new DBSubset (DB.v_attach_locat, 
      				    DB.gu_product + "," + DB.len_file + "," + DB.nm_product + "," + DB.de_product + "," + DB.dt_uploaded + "," + DB.pg_product + "," + DB.gu_location,
      				    DB.gu_contact + "='" + gu_contact + "' " + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oAttachLocats.setMaxRows(iMaxRows);
      iAttachCount = oAttachLocats.load (oConn, iSkip);
    }
    else {
      // Listados con filtro
    }
    
    oConn.close("attachmentlisting"); 
  }
  catch (SQLException e) {  
    oAttachLocats = null;
    oConn.close("attachmentlisting");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  oConn = null;  
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Archivos Adjuntos</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        var jsInstanceId;
        var jsInstanceNm;
            
        <%
          
          out.write("var jsAttachments = new Array(");
            for (int i=0; i<iAttachCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oAttachLocats.getString(0,i) + "_" + String.valueOf(oAttachLocats.getInt(5,i)) + "\"");
            }
          out.write(");\n        ");
        %>

      // ------------------------------------------------------

      function addAttachment() {
        window.open("attach_edit.jsp?gu_contact=<%=gu_contact%>", "addattachment", "directories=no,toolbar=no,menubar=no,width=480,height=360");          
        
      }

        // ----------------------------------------------------
	
	function deleteAttachments() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure that you want to delete the selected attached files?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "attach_edit_delete.jsp";
	  	  
	    for (var i=0;i<jsAttachments.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsAttachments[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteAttachments()
	
        // ----------------------------------------------------

	function modifyAttachment(id,pg,nm) {
	  // //Modificar una instancia
	  // //Parametros:
	  // 		//id -> Identificador unico de la instancia a modificar
	  // 		//nm -> Nombre de la instancia a modificar

          window.open("attach_edit.jsp?gu_contact=<%=gu_contact%>&id_product=" + id + "&pg_product=" + pg, "addattachment", "directories=no,toolbar=no,menubar=no,width=480,height=360");          
	  
	}	

        // ----------------------------------------------------

	      function sortBy(fld) {
	  
	        window.location = "attach_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=<%=gu_contact%>&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>" + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	      }			

        // ----------------------------------------------------

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsAttachments.length; c++)                        
            eval ("frm.elements['" + jsAttachments[c] + "'].click()");
        } // selectAll()
       
       // ----------------------------------------------------
	
	function findInstance() {
	  	  
	  var frm = document.forms[0];
	  
	  if (frm.find.value.length>0)
	    window.location = "attach_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=<%=gu_contact%>&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	} // findInstance()

      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	} // setCombos()
    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <!---------- BEGIN ALLWEBMENUS CODE ---------->
  <IMG NAME="awmMenuPathImg" ID="awmMenuPathImg" SRC="../javascript/awmmenupath.gif" WIDTH="1" HEIGHT="1" BORDER="0">
  <SCRIPT>var MenuCreatedBy='AllWebMenus 1.3.360.'; awmAltUrl='';</SCRIPT>
  <SCRIPT SRC='../javascript/toolmenu/toolmenu.js' LANGUAGE='JavaScript1.2' TYPE='text/javascript'></SCRIPT>
  <SCRIPT>awmBuildMenu();</SCRIPT>
  <!----------- END ALLWEBMENUS CODE ----------->
  <BR><BR><BR>
    <FORM METHOD="post">
      <TABLE><TR><TD CLASS="striptitle"><FONT CLASS="title1">Attached files of <%=full_name%></FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=request.getParameter("maxrows")%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=request.getParameter("skip")%>">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="5" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>      
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Nuevo"></TD>
        <TD VALIGN="middle">
<% if (bIsGuest) { %>
         <A HREF="#" onclick="alert('Your credential leveoes not allow you to perform this actionl as Guest d')" CLASS="linkplain">New</A>
<% } else { %>
         <A HREF="#" onclick="addAttachment()" CLASS="linkplain">New</A>
<% } %>
        </TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD>
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert('Your credential leveoes not allow you to perform this actionl as Guest d')" CLASS="linkplain">Delete</A>
<% } else { %>
          <A HREF="javascript:deleteAttachments()" CLASS="linkplain">Delete</A>
<% } %>
        </TD>
        <TD VALIGN="bottom">
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;files&nbsp;</FONT>
        </TD>
        </TR>
      <TR><TD COLSPAN="5" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>      
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	    // Pintar los enlaces de siguiente y anterior
    
          if (iSkip>0) // //Si iSkip>0 entonces hay registros anteriores
            out.write("            <A HREF=\"attach_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&gu_contact="+gu_contact+"&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
          if (!oAttachLocats.eof())
            out.write("            <A HREF=\"attach_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&gu_contact="+gu_contact+"&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
          <TD CLASS="tableheader" WIDTH="400" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" WIDTH="100" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Sort by this field"></A>&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select all"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%
	  String sInstId, sInstLn, sInstNm, sInstDt;
	  int iInstPg;	  
	  for (int i=0; i<iAttachCount; i++) {
            sInstId = oAttachLocats.getString(0,i);
            if (null!=oAttachLocats.get(1,i))
              sInstLn = " " + String.valueOf(oAttachLocats.getInt(1,i)) + " bytes";
            else
              sInstLn = "";
            sInstNm = oAttachLocats.getString(2,i);
            sInstDt = oAttachLocats.getDateShort(4,i);
            iInstPg = oAttachLocats.getInt(5,i);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<%=((i%2)+1)%>"><A HREF="../servlet/HttpBinaryServlet?id_product=<%=sInstId%>&id_user=<%=id_user%>" onContextMenu="return false;"><IMG SRC="../images/images/download.gif" BORDER="0" ALT="Download/Open <%=sInstLn%>"></A></TD>            
              <TD CLASS="strip<%=((i%2)+1)%>">&nbsp;<A HREF="#" onclick="modifyAttachment('<%=sInstId%>',<%=String.valueOf(iInstPg)%>,'<%=sInstNm %>')" ><%=sInstNm %></A></TD>
              <TD CLASS="strip<%=((i%2)+1)%>" ALIGN="right"><%=sInstDt%></TD>
              <TD CLASS="strip<%=((i%2)+1)%>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<%=sInstId+"_"+String.valueOf(iInstPg)%>"></TD>
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM> 
</BODY>
</HTML>
