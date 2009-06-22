<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Categories" language="java" session="true" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="pwdtemplates.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%

/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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
  
  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  
  String id_domain = getCookie(request, "domainid", "0");
  String gu_user = getCookie(request, "userid", "");
  String gu_workarea = getCookie(request, "workarea", "");

  JDCConnection oConn = null;  
  
	boolean bSession = (session.getAttribute("validated")!=null);
  boolean bIsGuest = true;
	String sPwdSign = null;
  DBSubset oCatgs = null;
  int iCatgs = 0;
  String sPwdsCat = "";
  
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("pwdmanhome");

    sPwdSign = DBCommand.queryStr(oConn, "SELECT "+DB.tx_pwd_sign+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+gu_user+"'");

		if (bSession) {
			String sCatName = DBCommand.queryStr(oConn, "SELECT d."+DB.nm_domain+",'_',u."+DB.tx_nickname+",'_pwds' FROM "+DB.k_domains+" d,"+DB.k_users+" u WHERE d."+DB.id_domain+"=u."+DB.id_domain+" AND u."+DB.gu_user+"='"+gu_user+"'");
			
		  sPwdsCat = DBCommand.queryStr(oConn, "SELECT "+DB.gu_category+" FROM "+DB.k_categories+" c, " + DB.k_cat_tree+ " t WHERE c."+DB.gu_category+"=t."+DB.gu_child_cat+" AND t."+DB.gu_parent_cat+" IN (SELECT "+DB.gu_category+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+gu_user+"') AND c."+DB.nm_category+"='"+sCatName+"'");

			if (null!=sPwdsCat)
		    oCatgs = new Categories().getChildsNamed(oConn, sPwdsCat, sLanguage, Categories.ORDER_BY_LOCALE_NAME);
	      iCatgs = oCatgs.getRowCount();
	  }

	  oConn.close("pwdman");
  }
  catch (SQLException e) {  
    
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("pwdman");

    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  oConn = null;
  
%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: [~Gestor de Contraseñas~]</TITLE> 
  <STYLE TYPE="text/css">
    .columnleft {
      width:340px;float:left;clear:left;text-align:left;
    }

    .columnright {
      float:left;right:340px;clear:right;text-align:left;
    }
  </STYLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
  <!--

    // ----------------------------------------------------------------
        
    var req = false;

    function createPassword() {
      var frm = document.forms["pwdsfrm"];
      if (frm.sel_templates.selectedIndex<=0) {
    	  alert ("[~Debe elegir una plantilla para la contraseña~]");        
        return false;
      } else {
	      open ("pwd_new.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&nm_template="+getCombo(frm.sel_templates),
	      		  "newpassword", "directories=no,toolbar=no,menubar=no,width=500,height=460");

      }
    } // createPassword
    
    function addNewCategory() {
        if (req.readyState == 4) {
          if (req.status == 200) {
          	if (req.responseText.substr(0,5)=="ERROR") {
          	  alert (req.responseText);
          	} else {
          		var id = req.responseText.substr(0,32);
          		var lt = req.responseText.substr(33);
          		var clst = document.getElementById("catlist");
          		clst.innerHTML = clst.innerHTML + "<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"listPasswords('"+id+"')\">"+lt+"</A><BR/>";
          	} // fi
          	req = false;
          } else {
          }
        }
    } // addNewCategory

    function createCategory() {
    	var par;
    	var sCatName;
		  if (!req) {
    	  sCatName = window.prompt("[~Nombre de la nueva categoría~]","");
    	  if (hasForbiddenChars(sCatName)) {
    	    alert ("[~El nombre introducido contiene caracteres no válidos~]");
    	  } else if (sCatName.length==0) {
    	    alert ("[~El nombre introducido no puede ser vacío~]");    
        } else if (sCatName.length>30) {
    	    alert ("[~El nombre introducido no puede superar los 30 caracteres~]");    
        } else {
      	  par = "id_parent_cat=<%=sPwdsCat%>&tr1st="+encodeURIComponent(sCatName);
			    req = createXMLHttpRequest();
			    req.onreadystatechange = addNewCategory;
			  
			    req.open("POST", "category_store.jsp", true);
  		    req.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  			  req.setRequestHeader("Content-length", par.length);
  			  req.setRequestHeader("Connection", "close");
			    req.send(par);
    		  //window.prompt("URL", "category_store.jsp?id_parent_cat="+currentCategoryGuid+"&tr1st="+sCatName);
    	  }
    	}    	
    } // createCategory()

    // ----------------------------------------------------------------

    function writePasswordsHtml() {
        if (req.readyState == 4) {
          if (req.status == 200) {
          	if (req.responseText.substr(0,5)=="ERROR") {
          	  alert (req.responseText);
          	} else {
						  var lins = req.responseText.split("\n");
						  var nlin = lins.length;
						  var html = "<TABLE>";
						  for (var l=0; l<nlin; l++) {
						  	var lin = lins[l].split("|");
						    html += "<TR><TD>"+lin[1]+"</TD></TR>";
						  }
						  html += "</TABLE>";
          	} // fi
          	req = false;
          } else {
          }
        }
    } // addNewCategory

	  function listPasswords(gu) {
	    if (!req) {
	      req = createXMLHttpRequest();
			  req.onreadystatechange = writePasswordsHtml;			  
			  req.open("GET", "pwdlist.jsp?gu_category="+gu, true);
			  req.send(null);
			} 
	  }

    // ----------------------------------------------------------------

    var stre = new Array("[~Insuficiente~]", "[~Insuficiente~]", "[~Insuficiente~]", "[~Insuficiente~]", "[~Insuficiente~]",  "[~Moderada~]", "[~Moderada~]", "[~Moderada~]", "[~Fuerte~]", "[~Fuerte~]", "[~Muy fuerte~]");

    var streCSS = 	new Array("#FF3300", "#FF3300", "#FFA400", "#FFB700", "#FCE200",  "#CBF400", "#8DFC00", "#78FE00", "#5BFF00", "#4CFF00", "#1CFF00");

    function easeInOut(minValue,maxValue,totalSteps,actualStep,powr) { 
	    var delta = maxValue - minValue; 
	    var stepp = minValue+(Math.pow(((1 / totalSteps) * actualStep), powr) * delta); 
	    return Math.ceil(stepp) 
    } 
    
    function doWidthChangeMem(elem,startWidth,endWidth,steps,intervals,powr) { 
    	if (elem.widthChangeMemInt)
    		window.clearInterval(elem.widthChangeMemInt);
    	var actStep = 0;
    	elem.widthChangeMemInt = window.setInterval(
    		function() { 
    		  elem.currentWidth = easeInOut(startWidth,endWidth,steps,actStep,powr);
    		  elem.style.width = elem.currentWidth + "px"; 
    		  actStep++;
    		  if (actStep > steps) window.clearInterval(elem.widthChangeMemInt);
    		} 
    	,intervals)
    }

    function updateMeter(p) {

    	var score = 0 
    	var maxWidth = document.getElementById("strengthMeter").offsetWidth-2;
    	var nScore = this.calcStrength(p);
      
    	// Set new width
    	var nRound = Math.round(nScore * 2);

    	if (nRound > 100) {
    		nRound = 100;
    	}
    
    	var scoreWidth = (maxWidth / 100) * nRound;		
    	
    	var elem = document.getElementById("scoreBar");
    	var startWidth= elem.offsetWidth;
    	var endWidth= scoreWidth;
    	doWidthChangeMem(elem, elem.offsetWidth, scoreWidth,  10, 10, 0.5 );
    	
    	document.getElementById("fuerza").innerHTML = "[~Fortaleza~]&nbsp;" + stre[Math.round(nRound/10)];
    	//document.getElementById("fuerza").style.color=streCSS[Math.round(nRound/10)];
    	//document.getElementById("fuerza").style.fontSize='90%';
    }

    function validateNewPassword() {
      var frm = document.forms[0];
      if (frm.pwd1.value.length<8) {
        alert ("[~La clave de firma debe ser de al menos 8 caracteres de longuitud~]");
        frm.pwd1.focus();
        return false;
      }
      if (frm.pwd1.value!=frm.pwd2.value) {
        alert ("[~La clave de firma no coincide con su verificación~]");
        frm.pwd1.value = frm.pwd2.value = "";
        frm.pwd1.focus();
        return false;
      }
      if (calcStrength(frm.pwd1.value)<23) {
        alert ("[~La fortaleza de la clave de firma es insuficiente~]");
        frm.pwd1.focus();
        return false;
      }

      return true;
    } // validate

  //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0">
<%@ include file="../common/tabmenu.jspf" %>
<BR>
<TABLE SUMMARY="Page Header"><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">[~Gestor de Contraseñas~]</FONT></TD></TR></TABLE>
<% if (null==sPwdSign) { %>
  <FORM METHOD="post" ACTION="pwdset.jsp" onSubmit="return validateNewPassword()">
  	<INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
  	<INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
    <FONT CLASS="textplain">[~Debe establecer una clave de firma adicional para el gestor de contraseñas~]</FONT>
    <BR/>
    <FONT CLASS="textplain">[~Esta clave debe contener al menos ocho caracteres y ser diferente de la clave ordinaria de acceso~]</FONT>
    <BR/>
    <FONT CLASS="textplain">[~hipergate no almacena la clave de firma, y no puede ser recuperada de ninguna manera tras ser establecida~]</FONT>    <BR/>
    <BR/>
    <FONT CLASS="textplain">[~Clave de firma~]</FONT>&nbsp;<INPUT TYPE="password" NAME="pwd1" MAXLENGTH="20" onKeyUp="updateMeter(this.value)">&nbsp;&nbsp;<FONT CLASS="textplain">[~repetir clave~]</FONT>&nbsp;<INPUT TYPE="password" NAME="pwd2" MAXLENGTH="20">&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="[~Establecer~]">
		<BR/>
		<SPAN ID="fuerza" class="textsmall"></SPAN><DIV ID='strengthMeter' CLASS="strengthMeter" STYLE='width:160;height:12;'><DIV id='scoreBar' class="scoreBar"></DIV></DIV>
  </FORM>
<% } else {
     if (bSession) {
		   if (oCatgs!=null) { %>
  <DIV CLASS="columnleft">
  <TABLE SUMMARY="Actions">
    <TR>
    	<TD>&nbsp;&nbsp;<IMG SRC="../images/images/newfolder16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="createCategory()" CLASS="linkplain">[~Nueva Categoría~]</A></TD>
    	<TD>&nbsp;&nbsp;<IMG SRC="../images/images/deletefolder.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="deleteCategory()" CLASS="linkplain">[~Eliminar Categoría~]</A></TD>
    </TR>
  </TABLE>
  <FORM METHOD="post" ACTION="category_delete.jsp">
  <DIV id="catlist"><%
  for (int c=0; c<iCatgs; c++) {
    out.write("<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"listPasswords('"+oCatgs.getString(0,c)+"')\">"+oCatgs.getStringNull(2,c,oCatgs.getString(1,c))+"</A><BR/>");
  } // next
%></DIV>
  </FORM>
  </DIV>
  <DIV id="pwdlist" CLASS="columnright">
  <FORM NAME="pwdsfrm">
<%
   String sTemplates = GlobalCacheClient.getString("PasswordTemplatesSelect["+gu_user+"]");
   if (null==sTemplates) {
     sTemplates = "";
     File[] aTemplates = new File(getTemplatesPath(sStorage, id_domain, gu_workarea, gu_user)).listFiles();
		 if (null!=aTemplates) {
       PasswordRecordTemplate oRec = new PasswordRecordTemplate();
		   final int nTemplates = aTemplates.length;
		   for (int p=0; p<nTemplates; p++) {
		     oRec.load(aTemplates[p].getPath());
		     sTemplates += "<OPTION VALUE=\""+aTemplates[p].getName()+"\">"+oRec.getName()+"</OPTION>";
		   } // next
		 } // fi
   GlobalCacheClient.put("PasswordTemplatesSelect["+gu_user+"]", sTemplates);
   } // fi
%>
  <TABLE SUMMARY="Pwd Controls">
    <TR>
      <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
      <TD VALIGN="middle" CLASS="textplain">[~Nueva~]</TD>
  	  <TD><SELECT NAME="sel_templates"><OPTION VALUE=""></OPTION><%=sTemplates%></SELECT></TD>
  	  <TD><INPUT TYPE="button" CLASS="minibutton" VALUE="[~Crear~]" onclick="createPassword()"></TD>
  	</TR>
  </TABLE>
  </DIV>
  </FORM>
<%  	}
   } else { %>
  <FORM METHOD="post" ACTION="pwdlogin.jsp">
  <INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
  <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
  <FONT CLASS="textplain">[~Clave de firma~]</FONT>&nbsp;<INPUT TYPE="password" NAME="pwd1" MAXLENGTH="20">&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="[~Entrar~]">
  </FORM>
<%   }
   } %>
</BODY>
</HTML>
