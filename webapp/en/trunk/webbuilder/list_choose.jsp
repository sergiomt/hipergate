<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
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

  // obtener el idioma del navegador cliente
  String sLanguage = getNavigatorLanguage(request);

  // Obtener el skin actual
  String sSkin = getCookie(request, "skin", "default");

  // Obtener el dominio y la workarea
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String gu_list = request.getParameter("gu_list");
  String gu_pageset = request.getParameter("gu_pageset");

  DBSubset oLists;        
  int iListCount = 0;

  // Obtener una conexión del pool a bb.dd. (el nombre de la conexión es arbitrario)
  JDCConnection oConn = GlobalDBBind.getConnection("listlisting");  
    
  try {
      oLists = new DBSubset(DB.k_lists, DB.gu_list +"," + DB.tp_list + "," + DB.gu_query + "," + DB.tx_subject + "," + DB.de_list,
      			    DB.gu_workarea + "='" + gu_workarea + "'", 100 );
      iListCount = oLists.load (oConn);
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
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" DEFER="defer">
    <!--
        function programJob() {
          var cmd = "MAIL";
          var frm = document.forms[0];
          var ele = frm.elements.length;
          var chk = 0;
	  var par;
	  var lst;
	            
          for (var idx=0; idx<ele; idx++) {
	    if (frm.elements[idx].type=="checkbox")
	      if (frm.elements[idx].checked) {
	        lst = frm.elements[idx].value;
	        chk++;
	      } // fi (checked)
          } // next
          
          if (0==chk) {
            alert ("[~Debe seleccionar una lista a la cual realizar el envío~]");
            return false;
          }

          if (chk>1) {
            alert ("[~Debe seleccionar una única lista a la cual realizar el envío~]");
            return false;
          }
          
          par = "gu_pageset:" + getURLParam("gu_pageset") + ",gu_list:" + lst;
          
          document.location = "../jobs/job_edit.jsp?gu_pageset=" + getURLParam("gu_pageset") + "&id_command=" + cmd + "&parameters=" + par;
        }

        // ----------------------------------------------------
        	
	function createList() {
		  	  
	  self.open ("../crm/list_wizard_01.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" , "listwizard", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-320)/2 + ",left=" + (screen.width-340)/2 + ",width=340,height=320");	  
	} // createList()
        
        //---------------------------------------------------------------------
        
        function modifyList(id,nm) {
	  
	  self.open ("../crm/list_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_list=" + id + "&n_list=" + nm, "editlist", "directories=no,toolbar=no,menubar=no,top=" + (screen.height-420)/2 + ",left=" + (screen.width-600)/2 + ",width=600,height=420");
	}
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: [~Programar Tarea (1/2)~]</TITLE>
</HEAD>
<BODY >
  <TABLE CELLSPACING="0" CELLPADDING="0" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="8" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">[~Programar Tarea: seleccionar lista de distribuci&oacute;n~]</FONT></TD><TD CLASS="striptitle" align="right"><FONT CLASS="title1">[~(1 de 2)~]</FONT></TD></TR>
  </TABLE>  
  <BR>
  <FONT CLASS="textplain">[~Seleccione una lista de distribución como destino del envío.~]</FONT>
  <FORM>  
      <TABLE WIDTH="100%" CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD WIDTH="18px"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Nueva Lista~]"></TD>
          <TD ALIGN="left" VALIGN="middle"><A HREF="#" onclick="createList();" CLASS="linkplain" TITLE="[~Nueva Lista~]">[~Nueva Lista de Distribuci&oacute;n~]</A></TD>
        </TR>
        <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>  
     <TABLE WIDTH="100%" BORDER="0">
        <TR>
          <TD CLASS="tableheader" WIDTH="20px" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="#" oncontextmenu="return false;"></A>&nbsp;<B>[~Lista~]</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="#" oncontextmenu="return false;"></A>&nbsp;<B>[~Descripci&oacute;n~]</B></TD>
        </TR>
<%
	  String sInstId;
	  for (int i=0; i<iListCount; i++) {
            sInstId = oLists.getString(0,i);
%>            
            <TR>
              <TD HEIGHT="14" CLASS="tabletd"><INPUT TYPE="checkbox" VALUE="<%=sInstId%>"></TD>
              <TD HEIGHT="14" CLASS="tabletd">&nbsp;<A HREF="#" onclick="modifyList('<%=sInstId%>','<%=Gadgets.URLEncode(oLists.getStringNull(3,i,""))%>')" TITLE="[~Editar Lista~]"><%=oLists.getStringNull(3,i,"[~(sin asunto)~]")%></A></TD>
              <TD HEIGHT="14" CLASS="tabletd">&nbsp;<%=oLists.getStringNull(4,i,"")%></TD>
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
      <HR>
      <CENTER>
      <INPUT TYPE="button" CLASS="closebutton" ACCESSKEY="c" TITLE="ALT+c" VALUE="[~Cancelar~]" onClick="window.close()">
      <INPUT TYPE="button" CLASS="pushbutton" ACCESSKEY="n" TITLE="ALT+n" VALUE="[~Siguiente~] >>" onClick="programJob()">
      </CENTER>
  </FORM>
</BODY>
</HTML>
