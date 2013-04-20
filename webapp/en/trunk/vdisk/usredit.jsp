<%@ page import="java.net.URLDecoder,java.sql.Connection,java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  final int CollaborativeTools=17, HiperMail=21;

  String sSkin = getCookie(request, "skin", "xp");  
  String sLanguage = getNavigatorLanguage(request);
  String sHeadStrip= "";
  String gu_user = request.getParameter("gu_user")!=null ? request.getParameter("gu_user") : "";
  String id_domain = nullif(request.getParameter("id_domain"),getCookie(request,"domainid",""));
  String n_domain = nullif(request.getParameter("n_domain"),getCookie(request,"domainnm",""));
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  DBSubset oWrks = null;  
  DBSubset oGrps = null;
  DBSubset oGrpx = null;
  String   sGrpx = null;
  
  int iMaxUsers = 1073741823;
  int iActualUsers;
  
  ACLUser oUser = new ACLUser();
  ACLDomain oDom = new ACLDomain();
  boolean bDomAdm = false;
  Object  aUser[] = { gu_user } ;
  Object  aDom[] = { new Integer(id_domain) } ;
  Object  aDomU[] = { new Integer(id_domain), gu_user } ;
  JDCConnection oConn = null;
  Statement oStmt;
  ResultSet oRSet;
  
  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

  if (0!=gu_user.length()) {
    sHeadStrip = "Edit User";    

    try {

      if (id_domain.equals("1025")) {
        throw new SQLException("It is not allowed to create new users at the MODEL domain", "28000", 28000);
      }

      if (!bIsAdmin) {
        throw new SQLException("Administrator role is required for editing users", "28000", 28000);
      }

      oConn = GlobalDBBind.getConnection("usredit1");
      
      oWrks = new DBSubset(DB.k_workareas, DB.gu_workarea + "," + DB.nm_workarea, DB.id_domain + "=" + id_domain + " AND " + DB.bo_active + "<>0", 10);
      oWrks.load(oConn);
      
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL) {
        oGrps = new DBSubset(DB.k_acl_groups,"'<OPTION VALUE=\"'+" + DB.gu_acl_group + "+'\">' + " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "'<OPTION VALUE=\"'+g." + DB.gu_acl_group + "+'\">' + g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oGrps = new DBSubset(DB.k_acl_groups, "'<OPTION VALUE=\"' || CAST(" + DB.gu_acl_group + " AS VARCHAR) || '\">' || " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "'<OPTION VALUE=\"' || CAST(g." + DB.gu_acl_group + " AS VARCHAR) || '\">' || g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
        oGrps = new DBSubset(DB.k_acl_groups,"CONCAT('<OPTION VALUE=\"'," + DB.gu_acl_group + ",'\">'," + DB.nm_acl_group + ")", DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "CONCAT('<OPTION VALUE=\"',g." + DB.gu_acl_group + ",'\">',g." + DB.nm_acl_group + ")",
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }
      else {
        oGrps = new DBSubset(DB.k_acl_groups,"'<OPTION VALUE=\"' || " + DB.gu_acl_group + " || '\">' || " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "'<OPTION VALUE=\"' || g." + DB.gu_acl_group + " || '\">' || g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }

      oGrps.setRowDelimiter("</OPTION>");
      oGrpx.setRowDelimiter("</OPTION>");
            
      oUser.load(oConn, aUser);
      oGrps.load(oConn, aDom);
      oGrpx.load(oConn, aDomU);
      sGrpx = oGrpx.toString();
      oGrpx = null;
      
      oDom.load(oConn, aDom);
      bDomAdm = oDom.getString(DB.gu_owner).equals(gu_user);
      
      oConn.close("usredit1");
      oConn = null;
    }
    catch (SQLException e) {
      if (null!=oConn) oConn.close("usredit1");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getMessage() + "&resume=_back"));
      return;    			   
    }
  }
  else {  
    sHeadStrip = "New User";

    if (id_domain.equals("1024") || id_domain.equals("1025")) {
      throw new SQLException("It is not allowed to create new users at SYSTEM nor MODEL domains", "28000", 28000);
    }

    oConn = GlobalDBBind.getConnection("usredit2");

    oWrks = new DBSubset(DB.k_workareas, DB.gu_workarea + "," + DB.nm_workarea, DB.id_domain + "=" + id_domain + " AND " + DB.bo_active + "<>0", 10);
    oWrks.load(oConn);

    oUser.put(DB.bo_active, (short)1);
    oUser.put(DB.bo_searchable, (short)1);
    oUser.put(DB.bo_change_pwd, (short)1);

    try {
    
      if (DBBind.exists(oConn, DB.k_accounts, "U")) {
        oStmt = oConn.createStatement();
        oRSet = oStmt.executeQuery("SELECT " + DB.max_users + " FROM " + DB.k_accounts + " WHERE " + DB.id_domain + "=" + id_domain);
   	    if (oRSet.next())
   	      iMaxUsers = oRSet.getInt(1);
   	    oRSet.close();
   	    oStmt.close();
      }
            
      oStmt = oConn.createStatement();
      oRSet = oStmt.executeQuery("SELECT COUNT(" + DB.gu_user + ") FROM " + DB.k_users + " WHERE " + DB.id_domain + "=" + id_domain);
      oRSet.next();
      iActualUsers = oRSet.getInt(1);
      oRSet.close();
      oStmt.close();

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL) {
        oGrps = new DBSubset(DB.k_acl_groups,"'<OPTION VALUE=\"'+" + DB.gu_acl_group + "+'\">' + " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "'<OPTION VALUE=\"'+g." + DB.gu_acl_group + "+'\">' + g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oGrps = new DBSubset(DB.k_acl_groups, "'<OPTION VALUE=\"' || CAST(" + DB.gu_acl_group + " AS VARCHAR) || '\">' || " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "'<OPTION VALUE=\"' || CAST(g." + DB.gu_acl_group + " AS VARCHAR) || '\">' || g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }
      else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {
        oGrps = new DBSubset(DB.k_acl_groups,"CONCAT('<OPTION VALUE=\"'," + DB.gu_acl_group + ",'\">'," + DB.nm_acl_group + ")", DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "CONCAT('<OPTION VALUE=\"',g." + DB.gu_acl_group + ",'\">',g." + DB.nm_acl_group + ")",
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }
      else {
        oGrps = new DBSubset(DB.k_acl_groups,"'<OPTION VALUE=\"' || " + DB.gu_acl_group + " || '\">' || " + DB.nm_acl_group, DB.id_domain + "=?", 50 );
        oGrpx = new DBSubset(DB.k_acl_groups + " g, " + DB.k_x_group_user + " x", "'<OPTION VALUE=\"' || g." + DB.gu_acl_group + " || '\">' || g." + DB.nm_acl_group,
  			     "g." + DB.gu_acl_group + "=x." + DB.gu_acl_group + " AND g." + DB.id_domain + "=? AND x." + DB.gu_user +"=?", 50 );
      }

      oGrps.setRowDelimiter("</OPTION>");
      oGrpx.setRowDelimiter("</OPTION>");
      
      oGrps.load(oConn, aDom);
      sGrpx = "";
      
      oConn.close("usredit2");
      oConn = null;

      if (iActualUsers>=iMaxUsers) {
        response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Maximum number of concurrent users reached&desc=The maximum number of concurrent users for your licese contract has been reached. For creating more users please extend your license first.&resume=_back"));
        return;
      }
    }
    catch (SQLException e) {
      if (oConn!=null) oConn.close("usredit2");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() +  "&resume=_back"));
      return;
    }
    catch (IllegalStateException e) {
      if (oConn!=null) oConn.close("usredit2");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() +  "&resume=_back"));
      return;
    }
    catch (NullPointerException e) {
      if (oConn!=null) oConn.close("usredit2");
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() +  "&resume=_back"));
      return;
    }
  }

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");    
%>
  <!-- +-----------------------+ -->
  <!-- | Edición de Usuarios   | -->
  <!-- | © KnowGate 2001       | -->
  <!-- +-----------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=sHeadStrip%></TITLE>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--

    function showCalendar(ctrl) {
      var dtnw = new Date();

      window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
    } // showCalendar()

    var stre = new Array("Very Weak", "Very Weak", "Weak", "Moderated", "Moderated",  "Strong", "Strong", "Strong", "Very Strong", "Very Strong", "Very Strong");

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
    	
    	document.getElementById("fuerza").innerHTML=stre[Math.round(nRound/10)];
    	//document.getElementById("fuerza").style.color=streCSS[Math.round(nRound/10)];
    	//document.getElementById("fuerza").style.fontSize='90%';
    }

    function validate() {
      var frm = document.forms[0];
      var txt;
      var opt;
                  
      var txt = frm.tx_nickname.value;
             
      if (txt.length<4) {
        alert ("Alias must be at least 4 characters long");
        return false;
      }

      if (!check_nick(txt)) {
        alert ("Alias contains forbidden characters");
        return false;        
      }

<%  if (0==gu_user.length()) { %>
      if (lookup_nickname(<%=id_domain%>,txt,"../common/nickname_lookup.jsp")) {
        alert ("The alias is alredy assigned to another user of the same Domain");
        return false;
      }
<% } %>

      if (frm.tx_pwd.value.length<4) {
        alert ("Password must contain at least 4 characters");
        return false;
      }

      if (frm.tx_pwd.value!=frm.tx_pwd2.value) {
        alert ("Original and verified password do not coincide");
        return false;
      }

      if (frm.tx_pwd.value.indexOf("'")>=0 || frm.tx_pwd.value.indexOf('"')>=0) {
        alert ("The key contains invalid characters");
        return false;        
      }

		  if (frm.tx_pwd.value==frm.tx_nickname.value) {
        alert ("The nickname may not be the same as the password");
        return false;		  
		  }

      txt = rtrim(ltrim(frm.tx_main_email.value));
      if (txt.length==0) {
        alert ("e-mail address is mandatory");
        return false;      
      }
      
      if (txt.length>0) {
        if (!check_email(txt)) {
          alert ("e-mail address is not valid");
          return false;
        }
      }

<%  if (0==gu_user.length()) { %>
      if (lookup_email(txt,"../common/email_lookup.jsp")) {
        alert ("The given e-mail address is already assigned to another user");
        return false;
      }
<% } %>

<% if (!bDomAdm) { %>

		  if (frm.rad_pwd_expires[0].checked) {
		  	frm.dt_pwd_expires.value = "";
		  } else if (frm.rad_pwd_expires[1].checked) {
		  	frm.dt_pwd_expires.value = "1972-01-01";
		  } else if (!isDate(frm.dt_pwd_expires.value, "d")) {
	      alert ("The key expiration date is not valid");
	      return false;	  
	    }
<% } %>

<%    if (gu_user.length()==0 && (iAppMask & (1<<CollaborativeTools))!=0) { %>

		  if (frm.chk_fellow.checked && frm.nm_user.value.length==0) {
        alert ("User name is required");
        return false;			  		  	
		  }
		  if (frm.chk_fellow.checked && frm.tx_surname1.value.length==0) {
        alert ("User surname is required");
        return false;			  		  	
		  }
<% } %>

      frm.tx_main_email.value = txt.toLowerCase();

      if (frm.sel_workarea.options.selectedIndex>=0)
        frm.gu_workarea.value = getCombo(frm.sel_workarea);
        
      frm.memberof.value = "";     
      opt = frm.group2.options;
      for (var g=0; g<opt.length; g++) {
        frm.memberof.value += opt[g].value + ",";
      }
      txt = frm.memberof.value; 
      if (txt.charAt(txt.length-1)==',') frm.memberof.value = txt.substr(0,txt.length-1);      
                        
      return true;
    }        

    // --------------------------------------------------------
    
    function findValue(opt,val) {
      var fnd = -1;
      
      for (var g=0; g<opt.length; g++) {
        if (opt[g].value==val) {
          fnd = g;
          break;
        }      
      }
      return fnd;
    }

    // --------------------------------------------------------
    
    function addGrps() {
      var opt1 = document.forms[0].groups.options;
      var opt2 = document.forms[0].group2.options;
      var sel2 = document.forms[0].group2;
      var opt;
      
      for (var g=0; g<opt1.length; g++) {
        if (opt1[g].selected && (-1==findValue(opt2,opt1[g].value))) {
<%   if (0!=gu_user.length()) { %>
          if ("<%=oDom.getString(DB.gu_owner)%>"=="<%=gu_user%>" && "<%=oDom.getString(DB.gu_admins)%>"!=opt1[g].value) {
            alert ("The administrator user may not be added to any group other than administrators");
          } else {
            opt = new Option(opt1[g].text, opt1[g].value);
            opt2[sel2.length] = opt;
          }
<% } else { %>
          opt = new Option(opt1[g].text, opt1[g].value);
          opt2[sel2.length] = opt;
<% } %>
        }
      } // next
    } // addGrps

    // --------------------------------------------------------

    function remGrps() {
      var opt2 = document.forms[0].group2.options;
      
      for (var g=0; g<opt2.length; g++) {
        if (opt2[g].selected){
<%   if (0!=gu_user.length()) { %>
          if ("<%=oDom.getString(DB.gu_owner)%>"=="<%=gu_user%>" && "<%=oDom.getString(DB.gu_admins)%>"==opt2[g].value) {
            alert ("The administrator user may not be removed from administrators group for the domain");
          } else {
            opt2[g--] = null;
          }
<% } else { %>
          opt2[g--] = null;
<% } %>
        } // fi
      } // next
    } // remGrps
    
    // --------------------------------------------------------

    function setCombos() {
    	var frm = document.forms[0];
    	
	    setCombo(document.forms[0].sel_workarea, '<%=oUser.getStringNull(DB.gu_workarea, "")%>');
		  frm.tx_pwd2.value = frm.tx_pwd.value = "<%=oUser.getStringNull(DB.tx_pwd,"")%>";
		  
<% if (!bDomAdm) {
	    if (oUser.isNull(DB.dt_pwd_expires)) {
	      out.write("	    frm.rad_pwd_expires[0].checked=true;\n");
	    } else if (oUser.getDateShort(DB.dt_pwd_expires).equals("1972-01-01")) {
	      out.write("	    frm.rad_pwd_expires[1].checked=true;\n");
	    } else {
	      out.write("	    frm.rad_pwd_expires[2].checked=true;\n");
	      out.write("	    frm.dt_pwd_expires.value=\""+oUser.getDateShort(DB.dt_pwd_expires)+"\";\n");	    
	    }
} %>
    } // setCombos

  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4" onLoad="setCombos()">
  <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>
  <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>
  <TABLE WIDTH="100%"><TR><TD CLASS="strip1"><FONT CLASS="title1"><%=sHeadStrip%> for domain &nbsp;<I><%=n_domain%></I></FONT></TD></TR></TABLE>
  <FORM NAME="usredit" METHOD="post" ACTION="<% if (0==gu_user.length()) out.write("usernew_store.jsp"); else out.write("usredit_modify.jsp"); %>" onSubmit="return validate();">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=gu_user%>">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="bo_searchable" VALUE="<% if (!oUser.isNull(DB.bo_searchable)) out.write(oUser.get(DB.bo_searchable).toString());%>">
    <INPUT TYPE="hidden" NAME="bo_change_pwd" VALUE="<% if (!oUser.isNull(DB.bo_change_pwd)) out.write(oUser.get(DB.bo_change_pwd).toString());%>">
    <INPUT TYPE="hidden" NAME="len_quota" VALUE="<% if (oUser.isNull(DB.len_quota)) out.write("0"); else oUser.getDecimal(DB.len_quota).toString(); %>">
    <INPUT TYPE="hidden" NAME="max_quota" VALUE="<% if (oUser.isNull(DB.max_quota)) out.write("104857600"); else oUser.getDecimal(DB.max_quota).toString(); %>">
    <INPUT TYPE="hidden" NAME="gu_category" VALUE="<%=oUser.getStringNull(DB.gu_category,"")%>">
    <INPUT TYPE="hidden" NAME="id_account" VALUE="<%=oUser.getStringNull(DB.id_account,"")%>">
    <INPUT TYPE="hidden" NAME="tp_account" VALUE="<%=oUser.getStringNull(DB.tp_account,"")%>">
    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
	        <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="checkbox" NAME="chk_active" VALUE="1" <% if (!oUser.isNull(DB.bo_active)) { if (oUser.getShort(DB.bo_active)==(short)1 || bDomAdm) out.write("CHECKED"); } else out.write("CHECKED"); %> <% if (bDomAdm) out.write("onclick=\"alert('Domain Administrator Account cannot be deactivated'); return false;\""); %>></TD>          
            <TD ALIGN="left" WIDTH="470"><FONT CLASS="formstrong">Active</FONT></TD>
				  </TR>
<%  if (gu_user.length()==0) { %>
<%    if ((iAppMask & (1<<CollaborativeTools))!=0) { %>
	        <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="checkbox" NAME="chk_fellow" VALUE="1" CHECKED></TD>
            <TD ALIGN="left" WIDTH="470"><FONT CLASS="formplain">Create an Employee account for the User</FONT></TD>
				  </TR>
<%    } %>
<%    if ((iAppMask & (1<<HiperMail))!=0) { %>
	        <TR>
            <TD ALIGN="right" WIDTH="90"><INPUT TYPE="checkbox" NAME="chk_webmail" VALUE="1"></TD>
            <TD ALIGN="left" WIDTH="470"><FONT CLASS="formplain">Create a WebMail account for the user</FONT></TD>
				  </TR>
<%    } %>
<%  } else { %>
<%    if ((iAppMask & (1<<HiperMail))!=0) { %>
	        <TR>
            <TD></TD>
            <TD ALIGN="left" WIDTH="470"><A CLASS="linkplain" HREF="../hipermail/account_edit.jsp?id_user=<%=gu_user%>&bo_popup=true">Create a WebMail account for this user</A></TD>
				  </TR>
<%    } %>
<%  } %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><SPAN onmouseover="popover('Alias is the nickname used by used for login into system')" onmouseout="popout()"><FONT CLASS="formstrong">Alias:</FONT></SPAN></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="text" NAME="tx_nickname" MAXLENGTH="32" SIZE="15" <% if (gu_user.length()>0) out.write("TABINDEX=\"-1\" onfocus=\"document.forms[0].tx_pwd.focus()\""); %>VALUE="<% if (0!=gu_user.length()) out.write(oUser.getStringNull(DB.tx_nickname,"")); %>"></TD>
          </TR>
          <TR>          	
            <TD ALIGN="right" WIDTH="90"><SPAN onmouseover="popover('Type password TWICE,<BR>one time for each text box')" onmouseout="popout()"><FONT CLASS="formstrong">Password:</FONT></SPAN></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="password" NAME="tx_pwd" MAXLENGTH="50" SIZE="12" VALUE="<% out.write(oUser.getStringNull(DB.tx_pwd,"")); %>" TITLE="Original key" <% if (!bIsAdmin && oUser.getShort(DB.bo_change_pwd)==(short)0) out.write("TABINDEX=-1 onfocus=\"alert('Change Password is disabled for this user');document.forms[0].nm_user.focus();\"");%> onKeyUp="updateMeter(this.value)">&nbsp;<INPUT TYPE="password" NAME="tx_pwd2" MAXLENGTH="50" SIZE="12" VALUE="<% out.write(oUser.getStringNull(DB.tx_pwd,"")); %>" TITLE="Repeat Password"></TD>
          </TR>
          <TR>          	
            <TD ALIGN="right" WIDTH="90"><SPAN ID='fuerza' class='textsmall'></SPAN></TD>
            <TD ALIGN="left" WIDTH="470"><DIV ID='strengthMeter' CLASS="strengthMeter" STYLE='width:160;height:12;'><DIV id='scoreBar' class="scoreBar"></DIV></DIV></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="470">
              <TABLE SUMMARY="Password Expiration">
                <TR><TD><INPUT TYPE="radio" NAME="rad_pwd_expires" onclick="document.forms[0].dt_pwd_expires.value=''" CHECKED></TD><TD CLASS="formplain">The key never expires</TD></TR>
<% if (!bDomAdm) { %>
                <TR><TD><INPUT TYPE="radio" NAME="rad_pwd_expires" onclick="document.forms[0].dt_pwd_expires.value=''"></TD><TD CLASS="formplain">The user must change the password upon his next logon</TD></TR>
                <TR><TD><INPUT TYPE="radio" NAME="rad_pwd_expires" CHECKED></TD><TD CLASS="formplain">The key expires at &nbsp;<INPUT TYPE="text" NAME="dt_pwd_expires" SIZE="12" onfocus="if (!document.forms[0].rad_pwd_expires[2].checked) document.forms[0].nm_user.focus()" VALUE="<% if (!oUser.isNull(DB.dt_pwd_expires)) out.write(oUser.getDateShort(DB.dt_pwd_expires).equals("1972-01-01") ? "" : oUser.getDateShort(DB.dt_pwd_expires)); %>"> <A HREF="javascript:if (document.forms[0].rad_pwd_expires[2].checked) showCalendar('dt_pwd_expires')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A></TD></TR>
<% } else { %>
                <TR><TD></TD><TD><INPUT TYPE="hidden" NAME="dt_pwd_expires" VALUE=""></TD></TR>
<% }%>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="text" NAME="nm_user" MAXLENGTH="100" SIZE="50" VALUE="<% out.write(oUser.getStringNull(DB.nm_user,"")); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Surname:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="text" NAME="tx_surname1" MAXLENGTH="100" SIZE="24" VALUE="<% out.write(oUser.getStringNull(DB.tx_surname1,"")); %>" TITLE="First Surname">&nbsp;<INPUT TYPE="text" NAME="tx_surname2" MAXLENGTH="100" SIZE="24" VALUE="<% out.write(oUser.getStringNull(DB.tx_surname2,"")); %>" TITLE="Second Surname"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="text" NAME="tx_main_email" MAXLENGTH="100" SIZE="50" VALUE="<%out.write(oUser.getStringNull(DB.tx_main_email,"")); %>" STYLE="text-transform:lowercase"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Area:</FONT></TD>
            <TD ALIGN="left" WIDTH="470">
              <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<% out.write(oUser.getStringNull(DB.gu_workarea,"")); %>">
              <SELECT NAME="sel_workarea"><%
              for (int w=0; w<oWrks.getRowCount(); w++)
                out.write ("<OPTION VALUE=\"" + oWrks.getString(0,w) + "\">" + oWrks.getString(1,w) + "</OPTION>");
%>            </SELECT>
              </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="470"><INPUT TYPE="text" NAME="tx_comments" MAXLENGTH="254" SIZE="60" VALUE="<% out.write(oUser.getStringNull(DB.tx_comments,"")); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" VALIGN="top"><FONT CLASS="formstrong">Groups</FONT></TD>
            <TD ALIGN="left" WIDTH="470">
              <TABLE CELLSPACING="0" CELLPADDING="0" BACKGROUND="../skins/<%=sSkin%>/fondoc.gif">
                <TR HEIGHT="20"><TD WIDTH="8">&nbsp;</TD><TD><FONT CLASS="textsmallfront">All Groups</FONT></TD><TD WIDTH="50"></TD><TD><FONT CLASS="textsmallfront">Belongs to</FONT></TD><TD WIDTH="8">&nbsp;</TD></TR>
                <TR><TD WIDTH="8">&nbsp;</TD><TD><SELECT NAME="groups" CLASS="textsmall" STYLE="width:160" SIZE="7" MULTIPLE><%=oGrps.toString()%></SELECT></TD><TD ALIGN="center" VALIGN="middle"><INPUT TYPE="button" NAME="AddGrps" VALUE="++ >>" TITLE="Add" STYLE="width:40" onclick="addGrps()"><BR><BR><INPUT TYPE="button" NAME="RemGrps" VALUE="<< - -" TITLE="Remove" STYLE="width:40" onclick="remGrps()"></TD><TD><SELECT NAME="group2" CLASS="textsmall" STYLE="width:160" SIZE="7" MULTIPLE><%=sGrpx%></SELECT><INPUT TYPE="hidden" NAME="memberof" VALUE=""></TD><TD WIDTH="8">&nbsp;</TD></TR>
                <TR HEIGHT="8"><TD COLSPAN="5"></TD></TR>
              </TABLE>
            </TD>
          </TR>          
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	    
          </TR>           
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>
