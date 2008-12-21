<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.forums.NewsMessage" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sSkin = getCookie(request, "skin", "default");
  String sUserId = getCookie(request, "userid", "default");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));  
    
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_newsgrp = request.getParameter("gu_newsgrp");
  String gu_parent_msg = nullif(request.getParameter("gu_parent_msg"));
  String gu_thread_msg = "";
  String tx_subject = "";
  String screen_width = request.getParameter("screen_width");
  
  int iScreenWidth;
  float fScreenRatio;

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  fScreenRatio = ((float) iScreenWidth) / 800f;  
  
  String sStatusLookUp = "";
    
  JDCConnection oConn = GlobalDBBind.getConnection("msg_edit");  
  ACLUser oUsr = null;
  NewsMessage oParent;
  
  try {
    oUsr = new ACLUser(oConn, sUserId);
    
    if (gu_parent_msg.length()>0) {
      oParent = new NewsMessage();
      oParent.load(oConn, new Object[]{gu_parent_msg});
      gu_thread_msg = oParent.getString(DB.gu_thread_msg);
      tx_subject = oParent.getStringNull(DB.tx_subject,"");
      if (!tx_subject.startsWith("Re: ")) tx_subject = "Re: " + tx_subject;
    }
    
    oConn.close("msg_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("msg_edit");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: [~Redactar Mensaje~]</TITLE>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      

      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        var txt;
        
	      if (!isDate(frm.dt_expire.value, "d") && frm.dt_expire.value.length>0) {
      	  alert ("[~La fecha de fin de validez no es correcta~]");
      	  return false;	  
      	}
       
	      if (!isDate(frm.dt_start.value, "d") && frm.dt_start.value.length>0) {
      	  alert ("[~La fecha de inicio de validez no es correcta~]");
      	  return false;	  
      	}

	      if (isDate(frm.dt_expire.value, "d")) {
	        if (isDate(frm.dt_start.value, "d")) {
      	    if (parseDate(frm.dt_expire.value, "d")<parseDate(frm.dt_start.value, "d")) {
      	      alert ("[~La fecha de inicio de validez debe ser anterior a la fecha de fin~]");
      	      return false;	        	  
      	    }
      	  }
      	  if (parseDate(frm.dt_expire.value+" 23:59:59", "ts")<new Date()) {
      	    alert ("[~La fecha de fin de validez debe ser posterior a hoy~]");
      	    return false; 	
      	  }
        }

      	txt = frm.tx_subject.value;
      	
      	if (txt.length==0) {
      	  alert ("[~El campo Asunto es obligatorio~]");
      	  return false;	  
      	}
      
      	if (txt.indexOf("'")>=0) {
      	  alert ("[~El campo Asunto contiene caracteres no válidos~]");
      	  return false;	  
      	}
	
        return true;
      } // validate;
    //-->
  </SCRIPT>

  <SCRIPT TYPE="text/javascript">
  <!--
  	var _editor_url = "../javascript/htmlarea/";
  	var _editor_lang = "en";

  	window.onload = function() {
			editor = new HTMLArea("tx_msg");
			editor.config.statusBar = false;
			editor.config.toolbar = [
				[
			  "bold", "italic", "underline", "separator",
			  "insertorderedlist", "insertunorderedlist", "outdent", "indent", "separator",
			  "inserthorizontalrule", "createlink", "inserttable", "separator",
			  "htmlmode",
			  ]
			];
			editor.generate();
  	}

    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/htmlarea/htmlarea.js"></SCRIPT>

</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
    <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="[~Atras~]"> [~Atras~]</SPAN>
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="[~Actualizar~]"> [~Actualizar~]</SPAN>
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="[~Imprimir~]"> [~Imprimir~]</SPAN>
    </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">[~Redactar Mensaje~]</FONT></TD></TR>
  </TABLE>  
  <FORM ENCTYPE="multipart/form-data" METHOD="post" ACTION="msg_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_newsgrp" VALUE="<%=gu_newsgrp%>">
    <INPUT TYPE="hidden" NAME="gu_parent_msg" VALUE="<%=gu_parent_msg%>">
    <INPUT TYPE="hidden" NAME="gu_thread_msg" VALUE="<%=gu_thread_msg%>">
    <INPUT TYPE="hidden" NAME="id_language" VALUE="<%=sLanguage%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=sUserId%>">    
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=sUserId%>">
    <INPUT TYPE="hidden" NAME="nm_author" VALUE="<%=(oUsr.getStringNull(DB.nm_user,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname2,"")).trim()%>">
    <INPUT TYPE="hidden" NAME="tx_email" VALUE="<%=oUsr.getStringNull(DB.tx_main_email,"")%>">
    <CENTER>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formstrong">[~De:~]</FONT></TD>
            <TD ALIGN="left" CLASS="textplain"><%=(oUsr.getStringNull(DB.nm_user,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname2,"")).trim()%></TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formplain">[~Grupo:~]</FONT></TD>
            <TD ALIGN="left" CLASS="textplain"><% out.write(request.getParameter("nm_newsgrp")); %></TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formplain">[~Inicio de Visibilidad el:~]</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="10" VALUE="">
              <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Ver Calendario~]"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formplain">[~Fecha de Caducidad:~]</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="dt_expire" MAXLENGTH="10" SIZE="10" VALUE="">
              <A HREF="javascript:showCalendar('dt_expire')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Ver Calendario~]"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formplain">[~Asunto:~]</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="tx_subject" MAXLENGTH="254" SIZE="80" VALUE="<%=tx_subject%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="left"><FONT CLASS="formplain">[~Texto:~]</FONT></TD>
            <TD ALIGN="left"><SELECT NAME="id_msg_type"><OPTION VALUE="HTM" SELECTED>HTML</OPTION><OPTION VALUE="TXT">Texto</OPTION></SELECT></TD>
          </TR>
        </TABLE>
        <TABLE CLASS="formfront">
          <TR>
	          <TD COLSPAN="2" ALIGN="left"><TEXTAREA CLASS="textcode" NAME="tx_msg" ID="tx_msg" ROWS="<% out.write(String.valueOf(floor(8f*fScreenRatio*1.4f))); %>" COLS="<% out.write(String.valueOf(floor(87f*fScreenRatio))); %>"></TEXTAREA></TD>
          </TR>                    
          <TR>
	    <TD COLSPAN="2" CLASS="formplain">
	      [~Archivo 1:~] <INPUT TYPE="file" NAME="attach1">
	      [~Archivo 2:~] <INPUT TYPE="file" NAME="attach2">
	      <BR>
	      [~Archivo 3:~] <INPUT TYPE="file" NAME="attach3">	      
	      [~Archivo 4:~] <INPUT TYPE="file" NAME="attach4">	      
	    </TD>
          </TR>                    
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="[~Enviar~]" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="[~Cancelar~]" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>
    </CENTER>
  </FORM>
</BODY>
</HTML>
