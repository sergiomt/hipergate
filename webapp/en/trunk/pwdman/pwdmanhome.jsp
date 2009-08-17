<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Category,com.knowgate.hipergate.Categories" language="java" session="true" contentType="text/html;charset=UTF-8" %>
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
  
  final int P = ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_MODIFY;

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  
  String id_domain = getCookie(request, "domainid", "0");
  String gu_user = getCookie(request, "userid", "");
  String gu_workarea = getCookie(request, "workarea", "");
  String gu_category = request.getParameter("gu_category");
  String sSelParams = "?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected");

  JDCConnection oConn = null;  
  
	boolean bSession = (session.getAttribute("validated")!=null);
  if (bSession) bSession = ((Boolean) session.getAttribute("validated")).booleanValue();

  boolean bIsGuest = true;
	String[] aStr = null;
  DBSubset oCatgs = null;
  int iCatgs = 0;
  int[] aPermissions = null;
  
  String sPwdsCat = "";
  
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("pwdmanhome");

    aStr = DBCommand.queryStrs(oConn, "SELECT "+DB.tx_pwd_sign+","+DB.tx_challenge+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+gu_user+"'");

		if (bSession) {
			String sCatName = DBCommand.queryStr(oConn, "SELECT d."+DB.nm_domain+",'_',u."+DB.tx_nickname+",'_pwds' FROM "+DB.k_domains+" d,"+DB.k_users+" u WHERE d."+DB.id_domain+"=u."+DB.id_domain+" AND u."+DB.gu_user+"='"+gu_user+"'");
			
		  sPwdsCat = DBCommand.queryStr(oConn, "SELECT "+DB.gu_category+" FROM "+DB.k_categories+" c, " + DB.k_cat_tree+ " t WHERE c."+DB.gu_category+"=t."+DB.gu_child_cat+" AND t."+DB.gu_parent_cat+" IN (SELECT "+DB.gu_category+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+gu_user+"') AND c."+DB.nm_category+"='"+sCatName+"'");

			if (null!=sPwdsCat)
		    oCatgs = new Categories().getChildsNamed(oConn, sPwdsCat, sLanguage, Categories.ORDER_BY_LOCALE_NAME);
	      iCatgs = oCatgs.getRowCount();
	      if (iCatgs>0) { 
	        aPermissions = new int[iCatgs];
	        for (int p=0; p<iCatgs; p++) {
	          Category oPerms = new Category(oCatgs.getString(0,p));
	          aPermissions[p] = oPerms.getUserPermissions(oConn, gu_user);
	        } //next
	      } // fi
	  } // fi

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
      float:left;right:340px;clear:right;text-align:left;visibility:hidden;
    }
  </STYLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
  <!--

    // ----------------------------------------------------------------
        
    var req = false;

		var cts = new Array (<% for (int c=0; c<iCatgs; c++) if ((aPermissions[c]&P)!=0) out.write((c==0 ? "" : ",")+"\""+oCatgs.getString(0,c)+"\""); %>);
		var ctn = new Array (<% for (int c=0; c<iCatgs; c++) if ((aPermissions[c]&P)!=0) out.write((c==0 ? "" : ",")+"\""+oCatgs.getStringNull(2,c,oCatgs.getString(1,c)).replace('"',' ')+"\""); %>);
    var cur = null;
    var pws = null;

    // ----------------------------------------------------------------

		function writeCategoriesList() {
	    var htm = "";	
	    for (var c=0; c<cts.length; c++) {
	      htm += "<INPUT TYPE=\"checkbox\" NAME=\"c_"+cts[c]+"\" VALUE=\""+cts[c]+"\">&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"listPasswords('"+cts[c]+"')\">"+(cur==cts[c] ? "<B>" : "")+ctn[c]+(cur==cts[c] ? "</B>" : "")+"</A><BR/>";
	    } // next
	    htm += "<BR/><TABLE SUMMARY=\"Close Session\" BORDER=\"0\"><TR><TD><IMG SRC=\"../images/images/padlock.gif\" WIDTH=19 HEIGHT=22 BORDER=0 ALT=\"Padlock\" /></TD><TD><A HREF=\"pwdlogout.jsp<%=sSelParams%>\" CLASS=\"linkplain\">[~Cerrar Gestor de Contraseñas~]</A></TD></TR></TABLE>";
	    document.getElementById("catlist").innerHTML = htm;
		} // writeCategoriesList

    // ----------------------------------------------------------------
		
    function refreshPasswordList() {
	      if (!req) {
          document.getElementById("pwdlinks").innerHTML = "";
	        req = createXMLHttpRequest();
			    req.onreadystatechange = writePasswordsHtml;			  
			    req.open("GET", "pwdlist.jsp?gu_category="+cur, true);
			    req.send(null);
			  } // fi
    } // refreshPasswordList()
		
    function createPassword() {
      var frm = document.forms["pwdsfrm"];
      
      if (null==cur) {
    	  alert ("[~Debe elegir una categoría a la cual añadir la contraseña~]");
        return false;
      } else if (frm.sel_templates.selectedIndex<=0) {
    	  alert ("[~Debe elegir una plantilla para la contraseña~]");        
        return false;
      } else {
	      open ("pwd_new.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&nm_template="+getCombo(frm.sel_templates)+"&gu_category="+cur,
	      		  "newpassword", "directories=no,toolbar=no,menubar=no,width=500,height=460");
      	frm.sel_templates.selectedIndex=0;
      }
    } // createPassword

    // ----------------------------------------------------------------
    
    function addNewCategory() {
        if (req.readyState == 4) {
          if (req.status == 200) {
          	if (req.responseText.substr(0,5)=="ERROR") {
          	  alert (req.responseText);
          	} else {
          		var id = req.responseText.substr(0,32);
          		var lt = req.responseText.substr(33);
          		cts.push(id);
          		ctn.push(lt);
          		var clst = document.getElementById("catlist");
          		clst.innerHTML = clst.innerHTML + "<INPUT TYPE=\"checkbox\" NAME=\"c_"+id+"\" VALUE=\""+id+"\" />&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"listPasswords('"+id+"')\">"+lt+"</A><BR/>";
          	} // fi
          	req = false;
          } else {
          }
        }
    } // addNewCategory

    // ----------------------------------------------------------------

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
    		  // window.prompt("URL", "category_store.jsp?id_parent_cat="+currentCategoryGuid+"&tr1st="+sCatName);
    	  }
    	}    	
    } // createCategory()

    // ----------------------------------------------------------------

    function deleteCategories() {
    	var par;
    	var frm = document.forms["fcats"];
		  var par = "";
		  var htm = "";
		  var c2s = new Array();
		  var c2n = new Array();
		  var c;
		  
		  if (!req) {
    	  for (c=0; c<cts.length; c++) {
    	  	if (frm.elements["c_"+cts[c]].checked) {
    	  		par += (par.length==0 ? "" : ",")+frm.elements["c_"+cts[c]].value;
    	    } else {
    	      c2s.push(cts[c]);
    	      c2n.push(ctn[c]);
    	    }
    	  } // next
    	  
    	  if (par.length==0) {
    	    alert ("[~Debe seleccionar al menos una categoría a eliminar~]");
        } else {
	        if (window.confirm("[~¿Está seguro de que desea eliminar las categorías seleccionadas?~]")) {
        	  cts = c2s;
        	  ctn = c2n;
		  			hideLayer("pwdlist");
	    			document.getElementById("pwdlinks").innerHTML = "";

            writeCategoriesList();

      	    par = "lst="+par;
			      req = createXMLHttpRequest();

			      req.open("POST", "category_delete.jsp", false);
  		      req.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  			    req.setRequestHeader("Content-length", par.length);
  			    req.setRequestHeader("Connection", "close");
			      req.send(par);
			      req = false;
    	    } // fi (confirm)
    	  } // fi (par.length) 
    	} // fi (req)    	    
    } // deleteCategories

    // ----------------------------------------------------------------

	  function deletePasswords() {
	        var offset = 0;
	        var frm = document.forms["pwdsfrm"];
	        var chi = frm.checkeditems;
	  	  
	        if (window.confirm("[~¿Está seguro de que desea eliminar las contraseñas seleccionadas?~]")) {

	          chi.value = "";	  	  
	          frm.action = "pwd_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&gu_category=" + cur;
	  	  
	          for (var i=0;i<pws.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	        if (frm.elements[offset].checked)
                chi.value += pws[i] + ",";
                offset++;
	          } // next()
	    
	          if (chi.value.length>0) {
	            chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	  } // deletePasswords()

    // ----------------------------------------------------------------

    function selectAll() {          
      var frm = document.forms["pwdsfrm"];
      
      for (var p=0; p<pws.length; p++)
        frm.elements["chk_"+pws[p]].click();
    } // selectAll()

    // ----------------------------------------------------------------

    var pwdlinkshtml = "";
    
    function writePasswordsHtml() {
        if (req.readyState == 4) {
          if (req.status == 200) {
          	if (req.responseText.length>1) {
          	  if (req.responseText.substr(0,5)=="ERROR") {
          	    document.getElementById("pwdlist").innerHTML = "";
          	  } else {
						    var lins = req.responseText.split("\n");
						    var nlin = lins.length;
						    pwdlinkshtml = "<IMG SRC=\"../images/images/spacer.gif\" WIDTH=\"12\" HEIGHT=\"1\" BORDER=\"0\" ALT=\"\"><IMG SRC=\"../images/images/papelera.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"[~Eliminar~]\">&nbsp;<A HREF=\"#\" onclick=\"deletePasswords()\" CLASS=\"linkplain\">[~Eliminar Contrase&ntilde;as Seleccionadas~]</A><BR/><TABLE SUMMARY=\"Passwords List\"><TR><TD CLASS=tableheader BACKGROUND=\"../skins/<%=sSkin%>/tablehead.gif\"></TD><TD CLASS=tableheader BACKGROUND=\"../skins/<%=sSkin%>/tablehead.gif\"><A HREF=\"#\" onclick=\"selectAll()\" TITLE=\"Select all\"><IMG SRC=\"../images/images/selall16.gif\" BORDER=\"0\" ALT=\"Select all\"></A></TD></TR>";
						    
						    pws = new Array();
						    for (var l=0; l<nlin; l++) {
						  	  var lin = lins[l].split("|");
						  	  pws.push(lin[0]);
						      pwdlinkshtml += "<TR><TD><A HREF=\"#\" CLASS=\"linkplain\" onclick=\"viewPassword('"+lin[0]+"')\">"+lin[1]+"</A></TD><TD><INPUT TYPE=\"checkbox\" NAME=\"chk_"+lin[0]+"\" VALUE=\""+lin[0]+"\" /></TD></TR>";
						    }
						    pwdlinkshtml += "</TABLE>";
          	    document.getElementById("pwdlinks").innerHTML = pwdlinkshtml;
          	  } // fi
            } // fi
          	req = false;
          } // fi
        } // fi
    } // writePasswordsHtml

    // ----------------------------------------------------------------

	  function listPasswords(gu) {
	      showLayer("pwdlist");
	      if (!req) {
	    	  cur = gu;
          writeCategoriesList();
          document.getElementById("pwdlinks").innerHTML = "";
	        req = createXMLHttpRequest();
			    req.onreadystatechange = writePasswordsHtml;			  
			    req.open("GET", "pwdlist.jsp?gu_category="+gu, true);
			    req.send(null);
			  } // fi
	  } // listPasswords

    // ----------------------------------------------------------------

    function viewPassword(gu) {
		  var pwdxml = httpRequestXML("pwd_txt.jsp?gu_pwd="+gu);
		  var pwdrec = pwdxml.getElementsByTagName("PasswordRecord")[0];
		  var pwdhtm = "";
		  if (getElementAttribute(pwdrec, "error", "status")=="0") {
				var pwdlins = pwdxml.getElementsByTagName("tx_lines")[0].childNodes[0].data.split("\n");				 
				pwdhtm = "<DIV class=cxMnu1 style=\"width:100px\"><DIV class=cxMnu2><SPAN class=hmMnuOff onMouseOver=\"this.className='hmMnuOn'\" onMouseOut=\"this.className='hmMnuOff'\" onClick=\"document.getElementById('pwdlinks').innerHTML=pwdlinkshtml;\"><IMG src=\"../images/images/toolmenu/historyback.gif\" width=16 style=\"vertical-align:middle\" height=16 border=0 alt=\"[~Atras~]\"> [~Atras~]</SPAN></DIV></DIV><BR/><TABLE><TR><TD CLASS=striptitle><FONT CLASS=title1>"+getElementText(pwdxml, "tl_pwd")+"</FONT></TD></TR></TABLE><TABLE CLASS=\"formback\"><TR><TD><TABLE WIDTH=\"100%\" CLASS=\"formfront\">";
				for (var l=0; l<pwdlins.length; l++) {
					var lin = pwdlins[l].split("|");
					if (lin[3].length>0) {
				    pwdhtm += "<TR><TD CLASS=\"formstrong\">"+lin[2]+"</TD>";
				    if (lin[1]=="&") {
				    	if (lin[3].substr(0,6)!="ftp://" && lin[3].substr(0,7)!="http://" && lin[3].substr(0,8)!="https://")
				    	  lin[3] = "http://" + lin[3];
				      pwdhtm += "<TD><A HREF=\""+lin[3]+"\" CLASS=\"linkplain\" TARGET=\"_blank\">"+lin[3]+"</A></TD>";
				    } else if (lin[1]=="@") {
				      pwdhtm += "<TD><A HREF=\"mailto:"+lin[3]+"\" CLASS=\"linkplain\">"+lin[3]+"</A></TD>"
				    } else {
				      pwdhtm += "<TD CLASS=\"formplain\">"+lin[3]+"</TD>";
				    }
				    pwdhtm += "</TR>";
				  }
				}
				pwdhtm += "</TABLE></TD></TR></TABLE>";
        document.getElementById("pwdlinks").innerHTML = pwdhtm;				
		  } else {
		    alert (getElementText(pwdxml, "error")); 
		  }
    } // viewPassword

    // ----------------------------------------------------------------

    function forceNewSignaturePassword() {
      if (window.confirm("[~Si establece una nueva clave de acceso PERDERÁ todas las contraseñas previamente almacenadas. ¿Está seguro de que desea continuar y borrar todas las contraseñas?~]")) {
        window.location = "pwd_reset.jsp<%=sSelParams%>";
      }
    }
    
    // ----------------------------------------------------------------

    function setCombos() {
      var gct = getURLParam("gu_category");
      if (null!=gct) listPasswords(gct);
<%    if (bSession && iCatgs==1) { %>
			  listPasswords("<%=oCatgs.getString(0,0)%>");
<%    } %>
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
    } // validateNewPassword
    
  //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0" onload="setCombos()">
<%@ include file="../common/tabmenu.jspf" %>
<BR>
<TABLE SUMMARY="Page Header"><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">[~Gestor de Contraseñas~]</FONT></TD></TR></TABLE>
<% if (null==aStr[0]) { %>
  <FORM METHOD="post" ACTION="pwdset.jsp" onSubmit="return validateNewPassword()">
  	<INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
  	<INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
    <FONT CLASS="textplain">[~Debe establecer una clave de firma adicional para el gestor de contraseñas~]</FONT>
    <BR/>
    <FONT CLASS="textplain">[~Esta clave debe contener al menos ocho caracteres y ser diferente de la clave ordinaria de acceso~]</FONT>
    <BR/>
    <FONT CLASS="textplain">[~hipergate no almacena la clave de firma, y no puede ser recuperada de ninguna manera tras ser establecida~]</FONT>    <BR/>
    <BR/>
    <FONT CLASS="textplain">[~Clave de firma~]</FONT>&nbsp;<INPUT CLASS="combomini" TYPE="password" NAME="pwd1" MAXLENGTH="20" onKeyUp="updateMeter(this.value)">&nbsp;&nbsp;<FONT CLASS="textplain">[~repetir clave~]</FONT>&nbsp;<INPUT CLASS="combomini" TYPE="password" NAME="pwd2" MAXLENGTH="20">
		<BR/>
		<SPAN ID="fuerza" class="textsmall"></SPAN><DIV ID='strengthMeter' CLASS="strengthMeter" STYLE='width:160;height:12;'><DIV id='scoreBar' class="scoreBar"></DIV></DIV>
    <FONT CLASS="textplain">[~Introduzca una frase que le ayude a recordar su clave de firma en caso de olvidarla~] [~(Opcional)~]</FONT>
    <BR/>
    <INPUT TYPE="text" CLASS="combomini" NAME="tx_challenge" MAXLENGTH="100" SIZE="70" VALUE="">
    <BR/><BR/>
    <INPUT TYPE="submit" VALUE="[~Establecer~]">
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
      <TD VALIGN="middle"><A HREF="#" onclick="deleteCategories()" CLASS="linkplain">[~Eliminar Categorías~]</A></TD>
    </TR>
  </TABLE>
  <FORM METHOD="post" NAME="fcats" ACTION="category_delete.jsp">
  <DIV id="catlist"><%
  for (int c=0; c<iCatgs; c++) {
    if ((aPermissions[c]&P)!=0) 
      out.write("<INPUT TYPE=\"checkbox\" NAME=\"c_"+oCatgs.getString(0,c)+"\" VALUE=\""+oCatgs.getString(0,c)+"\">&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"listPasswords('"+oCatgs.getString(0,c)+"')\">"+oCatgs.getStringNull(2,c,oCatgs.getString(1,c))+"</A><BR/>");
  } // next
%><BR/><TABLE SUMMARY="Close Session" BORDER="0"><TR><TD><IMG SRC="../images/images/padlock.gif" WIDTH=19 HEIGHT=22 BORDER=0 ALT="Padlock" /></TD><TD><A HREF="pwdlogout.jsp<%=sSelParams%>" CLASS="linkplain">[~Cerrar Gestor de Contraseñas~]</A></TD></TR></TABLE></DIV>
  </FORM>
  </DIV>
  <DIV id="pwdlist" CLASS="columnright">
  <FORM NAME="pwdsfrm" METHOD="POST">
  <INPUT TYPE="hidden" NAME="checkeditems" />
<%
   PasswordRecordTemplate oRec = new PasswordRecordTemplate();
   String sTemplates = GlobalCacheClient.getString("PasswordTemplatesSelect["+gu_user+"]");
   if (null==sTemplates) {
     sTemplates = "<OPTION VALUE=\"\"></OPTION>";
     File[] aTemplates = new File(getTemplatesPath(sStorage, id_domain, gu_workarea, gu_user)).listFiles();
     File[] aBrands = new File(getTemplatesPath(sStorage, id_domain, gu_workarea, gu_user)+File.separator+"brands").listFiles();
		 if (null!=aBrands) {
		   sTemplates += "<OPTGROUP LABEL=\"[~Servicios Predefinidos~]\">";
		   final int nBrands = aBrands.length;
		   for (int b=0; b<nBrands; b++) {
		     oRec.load(aBrands[b].getPath());
		     sTemplates += "<OPTION VALUE=\""+aBrands[b].getName()+"\">"+oRec.getName()+"</OPTION>";		   
		   } // for
		   sTemplates += "</OPTGROUP>";
		 } // fi

		 if (null!=aTemplates) {
		   sTemplates += "<OPTGROUP LABEL=\"[~Servicios Genéricos~]\">";       
		   final int nTemplates = aTemplates.length;
		   for (int p=0; p<nTemplates; p++) {
		     if (!aTemplates[p].isDirectory()) {
		       oRec.load(aTemplates[p].getPath());
		       sTemplates += "<OPTION VALUE=\""+aTemplates[p].getName()+"\">"+oRec.getName()+"</OPTION>";
		     } // fi
		   } // next
		   sTemplates += "</OPTGROUP>";
		 } // fi
   GlobalCacheClient.put("PasswordTemplatesSelect["+gu_user+"]", sTemplates);
   } // fi
%>
  <TABLE SUMMARY="Pwd Controls">
    <TR>
      <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
      <TD VALIGN="middle" CLASS="textplain">[~Nueva~]</TD>
  	  <TD><SELECT NAME="sel_templates"><%=sTemplates%></SELECT></TD>
  	  <TD><INPUT TYPE="button" CLASS="minibutton" VALUE="[~Crear~]" onclick="createPassword()"></TD>
  	</TR>
  </TABLE>
  <BR/>
  <DIV id="pwdlinks"></DIV>
  </DIV>
  </FORM>
<%  	}
   } else { %>
  <FORM METHOD="post" ACTION="pwdlogin.jsp">
  <INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
  <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
  <FONT CLASS="textplain">[~Clave de firma~]</FONT>&nbsp;<INPUT TYPE="password" NAME="pwd1" MAXLENGTH="20">&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="[~Entrar~]">
  <BR/>
  <DIV id="reminderlink" STYLE="visibility:visible">
  <BR/>
  <A HREF="#" CLASS="linkplain" onclick="hideLayer('reminderlink'); showLayer('reminder');"><IMG SRC="../images/images/forgotpwd.gif" WIDTH="17" HEIGHT="16" BORDER="0" ALT="Forgot password?">&nbsp;[~&iquest;Olvid&oacute; la clave de firma?~]</A>
  <BR/>
  </DIV>
  <DIV id="reminder" STYLE="visibility:hidden">
  <FONT CLASS="textplain">[~Por motivos de seguridad, la clave de firma no puede ser recuperada ni re-enviada~]</FONT>
<% if (aStr[1]!=null) { %>
  <BR/>
  <FONT CLASS="textplain">[~La frase que introdujo como recordatorio de su clave es~]&nbsp;"<%=aStr[1]%>"</FONT>
<% } %>
  <BR/>
  <A HREF="#" CLASS="linkplain" onclick="forceNewSignaturePassword()">[~Establecer una nueva clave de firma~]</A>
  </DIV>
  </FORM>
<%   }
   } %>
</BODY>
</HTML>
