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

	sendUsageStats(request, "pwdmanhome");
  
%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Passwords Manager</TITLE> 
  <STYLE TYPE="text/css">
    .columnleft {
      width:340px;float:left;clear:left;text-align:left;background:#e7e3e7;
    }

    .columnright {
      float:left;right:340px;margin-left:8px;clear:right;text-align:left;visibility:hidden;
    }
  </STYLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--

    // ----------------------------------------------------------------
        
    var req = false;

		var cts = new Array (<% for (int c=0; c<iCatgs; c++) if ((aPermissions[c]&P)!=0) out.write((c==0 ? "" : ",")+"\""+oCatgs.getString(0,c)+"\""); %>);
		var ctn = new Array (<% for (int c=0; c<iCatgs; c++) if ((aPermissions[c]&P)!=0) out.write((c==0 ? "" : ",")+"\""+oCatgs.getStringNull(2,c,oCatgs.getString(1,c)).replace('"',' ')+"\""); %>);
    var cur = null;
    var pws = null;

    // ----------------------------------------------------------------

		function writeCategoriesList() {
	    var htm = "<TABLE WIDTH=\"100%\" SUMMARY=\"Categories List\"><TR><TD WIDTH=\"28px\" CLASS=\"tableheader\" BACKGROUND=\"../skins/<%=sSkin%>/tablehead.gif\"></TD><TD CLASS=\"tableheader\" BACKGROUND=\"../skins/<%=sSkin%>/tablehead.gif\"></TD></TR>";
	    for (var c=0; c<cts.length; c++) {
	      htm += "<TR><TD WIDTH=\"28px\" ALIGN=\"center\" CLASS=\"strip1\">&nbsp;&nbsp;<INPUT TYPE=\"checkbox\" NAME=\"c_"+cts[c]+"\" VALUE=\""+cts[c]+"\"></TD><TD CLASS=\"strip1\"><A CLASS=\"linkplain\" HREF=\"#\" onclick=\"listPasswords('"+cts[c]+"')\">";
	      if (cur==cts[c])
	        htm += "<B>"+ctn[c]+"</B>";
	      else
	        htm += ctn[c];
	      htm += "</A></TD></TR>";
	    } // next
	    htm += "<TABLE SUMMARY=\"Close Session\" BORDER=\"0\"><TR><TD>&nbsp;&nbsp;<IMG SRC=\"../images/images/padlock.gif\" WIDTH=19 HEIGHT=22 BORDER=0 ALT=\"Padlock\" /></TD><TD><A HREF=\"pwdlogout.jsp<%=sSelParams%>\" CLASS=\"linkplain\">Close Passwords Manager</A></TD></TR></TABLE>";
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
    	  alert ("Pleas echose a category for the new password");
        return false;
      } else if (frm.sel_templates.selectedIndex<=0) {
    	  alert ("Please choose a template for the password");        
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
          	  req = false;
          	} else {
          		var id = req.responseText.substr(0,32);
          		var lt = req.responseText.substr(33);
          		cts.push(id);
          		ctn.push(lt);
          	  req = false;
							writeCategoriesList();
          	} // fi
          } else {
          }
        }
    } // addNewCategory

    // ----------------------------------------------------------------

    function createCategory() {
    	var par;
    	var sCatName;
		  if (!req) {
    	  sCatName = window.prompt("Name of the category","");
    	  if (hasForbiddenChars(sCatName)) {
    	    alert ("The name contains invalid characters");
    	  } else if (sCatName.length==0) {
    	    alert ("The name may not be empty");    
        } else if (sCatName.length>30) {
    	    alert ("The name may not be longer than 30 characters");    
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
    	    alert ("At least one category to be deleted must be specified");
        } else {
	        if (window.confirm("Are you sure that you want to delete the selected categories?")) {
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
	  	  
	        if (window.confirm("Are you sure that you want to delete the selected passwords?")) {

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
						    pwdlinkshtml = "<IMG SRC=\"../images/images/spacer.gif\" WIDTH=\"12\" HEIGHT=\"1\" BORDER=\"0\" ALT=\"\"><IMG SRC=\"../images/images/papelera.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Delete\">&nbsp;<A HREF=\"#\" onclick=\"deletePasswords()\" CLASS=\"linkplain\">Delete selected passwords</A><BR/><TABLE SUMMARY=\"Passwords List\"><TR><TD CLASS=tableheader BACKGROUND=\"../skins/<%=sSkin%>/tablehead.gif\"><TD CLASS=tableheader BACKGROUND=\"../skins/<%=sSkin%>/tablehead.gif\"><TD CLASS=tableheader BACKGROUND=\"../skins/<%=sSkin%>/tablehead.gif\"></TD><TD CLASS=tableheader BACKGROUND=\"../skins/<%=sSkin%>/tablehead.gif\"><A HREF=\"#\" onclick=\"selectAll()\" TITLE=\"Select All\"><IMG SRC=\"../images/images/selall16.gif\" BORDER=\"0\" ALT=\"Select all\"></A></TD></TR>";
						    
						    pws = new Array();
						    for (var l=0; l<nlin; l++) {
						  	  var lin = lins[l].split("|");
						  	  pws.push(lin[0]);
						      pwdlinkshtml += "<TR><TD CLASS=\"textplain\">"+lin[1]+"</TD><TD><A HREF=\"#\" CLASS=\"linkplain\" onclick=\"viewPassword('"+lin[0]+"')\">Show Password</A></TD>";
						      if (lin[2].length==0)
						        pwdlinkshtml += "<TD></TD>";
						      else
						        pwdlinkshtml += "<TD><A CLASS=\"linkplain\" TARGET=\"_blank\" HREF=\"loginforms/"+lin[2]+".jsp?gu_pwd="+lin[0]+"\">Go To WebSite</A></TD>";
						      pwdlinkshtml += "<TD><INPUT TYPE=\"checkbox\" NAME=\"chk_"+lin[0]+"\" VALUE=\""+lin[0]+"\" /></TD></TR>";
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
				pwdhtm = "<DIV class=cxMnu1 style=\"width:100px\"><DIV class=cxMnu2><SPAN class=hmMnuOff onMouseOver=\"this.className='hmMnuOn'\" onMouseOut=\"this.className='hmMnuOff'\" onClick=\"document.getElementById('pwdlinks').innerHTML=pwdlinkshtml;\"><IMG src=\"../images/images/toolmenu/historyback.gif\" width=16 style=\"vertical-align:middle\" height=16 border=0 alt=\"Back\"> Back</SPAN></DIV></DIV><BR/><TABLE><TR><TD CLASS=striptitle><FONT CLASS=title1>"+getElementText(pwdxml, "tl_pwd")+"</FONT></TD></TR></TABLE><TABLE CLASS=\"formback\"><TR><TD><TABLE WIDTH=\"100%\" CLASS=\"formfront\">";
				for (var l=0; l<pwdlins.length; l++) {
					var lin = pwdlins[l].split("|");
					if (lin[3].length>0 && lin[2]!="null") {
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

    function checkNewAuthStr() {
      frm = document.forms["newauthstr"];
      if (frm.tx_pwd_new1.value.length<4) {
        alert ("The password must be of at least 4 characters");
        frm.tx_pwd_new1.value=frm.tx_pwd_new2.value="";
        frm.tx_pwd_new1.focus();
        return false;
      }
      if (frm.tx_pwd_new1.value!=frm.tx_pwd_new2.value) {
        alert ("The new password does not match its verification");
        frm.tx_pwd_new1.value=frm.tx_pwd_new2.value="";
        frm.tx_pwd_new1.focus();
        return false;
      }
      return true;
    }

    // ----------------------------------------------------------------

    function forceNewSignaturePassword() {
      if (window.confirm("If a new signature password is set then all the previously stored data under the passwords manager will be lost. Are you sure that you want to continue?")) {
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
    
    var stre = new Array("Not enought", "Not enought", "Not enought", "Not enought", "Not enought",  "Medium", "Medium", "Medium", "Strong", "Strong", "Very Strong");

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
    	
    	document.getElementById("fuerza").innerHTML = "Strength&nbsp;" + stre[Math.round(nRound/10)];
    	//document.getElementById("fuerza").style.color=streCSS[Math.round(nRound/10)];
    	//document.getElementById("fuerza").style.fontSize='90%';
    }

    function validateNewPassword() {
      var frm = document.forms[0];
      if (frm.pwd1.value.length<8) {
        alert ("The signature password must be of at least 8 characters length");
        frm.pwd1.focus();
        return false;
      }
      if (frm.pwd1.value!=frm.pwd2.value) {
        alert ("The signature password does not match its verification");
        frm.pwd1.value = frm.pwd2.value = "";
        frm.pwd1.focus();
        return false;
      }
      if (calcStrength(frm.pwd1.value)<23) {
        alert ("The strength of the signature password is not enought");
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
<TABLE SUMMARY="Page Header"><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Passwords Manager</FONT></TD></TR></TABLE>
<% if (null==aStr[0]) { %>
  <FORM METHOD="post" ACTION="pwdset.jsp" AUTOCOMPLETE="off" onSubmit="return validateNewPassword()">
  	<INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
  	<INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
    <FONT CLASS="textplain">An additional signature password must be set for the passwords manager</FONT>
    <BR/>
    <FONT CLASS="textplain">The signature password must be of at least 8 characters length and must be different from the ordinary application entry password</FONT>
    <BR/>
    <FONT CLASS="textplain">hipergate does not store the signature password and it may not be recovered after it is set</FONT>    <BR/>
    <BR/>
    <FONT CLASS="textplain">Signature password</FONT>&nbsp;<INPUT CLASS="combomini" TYPE="password" NAME="pwd1" MAXLENGTH="20" onKeyUp="updateMeter(this.value)">&nbsp;&nbsp;<FONT CLASS="textplain">repeat password</FONT>&nbsp;<INPUT CLASS="combomini" TYPE="password" NAME="pwd2" MAXLENGTH="20">
		<BR/>
		<SPAN ID="fuerza" class="textsmall"></SPAN><DIV ID='strengthMeter' CLASS="strengthMeter" STYLE='width:160;height:12;'><DIV id='scoreBar' class="scoreBar"></DIV></DIV>
    <FONT CLASS="textplain">Enter a phrase which helps you to remind your signature password in case that you forget it (Optional)</FONT>
    <BR/>
    <INPUT TYPE="text" CLASS="combomini" NAME="tx_challenge" MAXLENGTH="100" SIZE="70" VALUE="">
    <BR/><BR/>
    <INPUT TYPE="submit" VALUE="Set">
  </FORM>
<% } else {
	   if (bSession) {
		   if (oCatgs!=null) { %>
  <FORM METHOD="post" NAME="fcats" ACTION="category_delete.jsp">
  <DIV CLASS="columnleft">
  <TABLE SUMMARY="Actions">
    <TR>
    	<TD>&nbsp;&nbsp;<IMG SRC="../images/images/newfolder16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="createCategory()" CLASS="linkplain">New Category</A></TD>
    	<TD>&nbsp;&nbsp;<IMG SRC="../images/images/deletefolder.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="deleteCategories()" CLASS="linkplain">Delete Categories</A></TD>
    </TR>
  </TABLE>
  <DIV id="catlist">
  <TABLE WIDTH="100%" SUMMARY="Categories List"><TR><TD WIDTH="28px" CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD><TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD></TR>
<%
  for (int c=0; c<iCatgs; c++) {
    if ((aPermissions[c]&P)!=0) 
      out.write("<TR><TD WIDTH=\"28px\" ALIGN=\"center\" CLASS=\"strip1\">&nbsp;&nbsp;<INPUT TYPE=\"checkbox\" NAME=\"c_"+oCatgs.getString(0,c)+"\" VALUE=\""+oCatgs.getString(0,c)+"\"></TD><TD CLASS=\"strip1\"><A CLASS=\"linkplain\" HREF=\"#\" onclick=\"listPasswords('"+oCatgs.getString(0,c)+"')\">"+oCatgs.getStringNull(2,c,oCatgs.getString(1,c))+"</A></TD></TR>");
  } // next
%></TABLE><TABLE SUMMARY="Close Session" BORDER="0"><TR><TD>&nbsp;&nbsp;<IMG SRC="../images/images/padlock.gif" WIDTH=19 HEIGHT=22 BORDER=0 ALT="Padlock" /></TD><TD><A HREF="pwdlogout.jsp<%=sSelParams%>" CLASS="linkplain">Close Passwords Manager</A></TD></TR></TABLE></DIV>
  </DIV>
  </FORM>
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
		   sTemplates += "<OPTGROUP LABEL=\"Predefined Services\">";
		   final int nBrands = aBrands.length;
		   for (int b=0; b<nBrands; b++) {
			   if (!aBrands[b].isDirectory() && !aBrands[b].isHidden()) {
	 	       oRec.load(aBrands[b].getPath());
		       sTemplates += "<OPTION VALUE=\"brands"+File.separator+""+aBrands[b].getName()+"\">"+oRec.getName()+"</OPTION>";		   
			   }
			 } // for
		   sTemplates += "</OPTGROUP>";
		 } // fi

		 if (null!=aTemplates) {
		   sTemplates += "<OPTGROUP LABEL=\"Generic Services\">";       
		   final int nTemplates = aTemplates.length;
		   for (int p=0; p<nTemplates; p++) {
		     if (!aTemplates[p].isDirectory() && !aTemplates[p].isHidden()) {
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
      <TD VALIGN="middle" CLASS="textplain">new</TD>
  	  <TD><SELECT NAME="sel_templates" onchange="if (this.selectedIndex>0) createPassword()"><%=sTemplates%></SELECT></TD>
  	</TR>
  </TABLE>
  <BR/>
  <DIV id="pwdlinks"></DIV>
  </DIV>
  </FORM>
<%  	}
   } else { %>
  <FORM METHOD="post" AUTOCOMPLETE="off" ACTION="pwdlogin.jsp">
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
    <TABLE CLASS="formback" SUMMARY="Form Back frame">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront" SUMMARY="Form Background">
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain">Signature password</TD>
            <TD ALIGN="left" WIDTH="340"><INPUT TYPE="password" NAME="pwd1" MAXLENGTH="20">&nbsp;&nbsp;<INPUT TYPE="submit" VALUE="Enter"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"></TD>
            <TD ALIGN="left" WIDTH="340">
  					  <DIV id="reminderlink" STYLE="display:block">
  						  <A HREF="#" CLASS="linkplain" onclick="document.getElementById('reminderlink').style.display='none'; document.getElementById('reminder').style.display='block';"><IMG SRC="../images/images/forgotpwd.gif" WIDTH="17" HEIGHT="16" BORDER="0" ALT="Forgot password?">&nbsp;Forgot your signature password?</A>
  						</DIV>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2">
              <DIV id="reminder" STYLE="display:none">
                <FONT CLASS="textplain">For security reasons the signature password may not be retrieved nor re-send to you in the future</FONT>
				        <% if (aStr[1]!=null) { %>
                <BR/>
                <FONT CLASS="textplain">The phrase that you entered as reminder of your signature password is&nbsp;"<%=aStr[1]%>"</FONT>
                <% } %>
                <BR/>
                <A HREF="#" CLASS="linkplain" onclick="forceNewSignaturePassword()">Change signature password</A>
              </DIV>
            </TD>
          </TR>
        </TABLE>
      </TD><TR>
    </TABLE>  
  </FORM>
  <FORM NAME="newauthstr" AUTOCOMPLETE="off" METHOD="post" ACTION="pwd_change.jsp" onsubmit="return checkNewAuthStr()">
    <INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
    <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
    <TABLE CLASS="formback" SUMMARY="Form Back frame">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront" SUMMARY="Form Background">
          <TR>
            <TD ALIGN="left" WIDTH="500" COLSPAN="2"><A HREF="\#\" CLASS="linkplain" onclick="for (var c=1; c<=8; c++) document.getElementById('c'+String(c)).style.display='block';">Change ordinary application entry password</A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain"><DIV id="c1" style="display:none">Current password</DIV></TD>            
            <TD WIDTH="340"><DIV id="c2" style="display:none"><INPUT TYPE="password" NAME="tx_pwd_old"></DIV></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain"><DIV id="c3" style="display:none">New password</DIV></TD>            
            <TD WIDTH="340"><DIV id="c4" style="display:none"><INPUT TYPE="password" NAME="tx_pwd_new1"></DIV></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain"><DIV id="c5" style="display:none">Repeat password</DIV></TD>            
            <TD WIDTH="340"><DIV id="c6" style="display:none"><INPUT TYPE="password" NAME="tx_pwd_new2"></DIV></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><DIV id="c7" style="display:none"></DIV></TD>            
            <TD WIDTH="340"><DIV id="c8" style="display:none"><INPUT TYPE="submit" CLASS="pushbutton" VALUE="Change"></DIV></TD>
          </TR>
        </TABLE>
      </TD><TR>
    </TABLE>  
  </FORM>
<%   }
   } %>
</BODY>
</HTML>
