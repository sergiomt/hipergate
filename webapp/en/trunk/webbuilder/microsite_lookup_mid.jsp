<%@ page import="java.io.File,java.util.Date,com.knowgate.misc.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.dfs.FileSystem" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%  response.setHeader("Cache-Control","no-cache");response.setHeader("Pragma","no-cache"); response.setIntHeader("Expires", 0); %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%!
  static String esc (String sPath) {
    String sRetVal;

    if (System.getProperty("file.separator").equals("/"))
      sRetVal = sPath;
    else {
      sRetVal = "";
      for (int p=0; p<sPath.length(); p++)
        if (sPath.charAt(p)=='\\')
          sRetVal += "\\\\";
        else
          sRetVal += sPath.charAt(p);
    }
        
    return sRetVal;
  }
  
  static String back (String sPath) {
    String sRetVal;

    if (System.getProperty("file.separator").equals("/")) {
      sRetVal = "";
      for (int p=0; p<sPath.length(); p++)
        if (sPath.charAt(p)=='\\')
          sRetVal += "/";
        else
          sRetVal += sPath.charAt(p);    }
    else {
      sRetVal = "";
      for (int p=0; p<sPath.length(); p++)
        if (sPath.charAt(p)=='/')
          sRetVal += "\\\\";
        else
          sRetVal += sPath.charAt(p);
    }      
    return sRetVal;
  }
%>    
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
  
  String sLanguage = getNavigatorLanguage(request);  

  String sSkin = getCookie(request, "skin", "xp");
  String id_domain = getCookie(request,"domainid","");
  String sWorkArea = getCookie(request,"workarea", "");

  String nm_table = request.getParameter("nm_table");
  String id_language = nullif(request.getParameter("id_language"), sLanguage);
  String id_section = request.getParameter("id_section");
  String n_domain = request.getParameter("n_domain");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");
  String sDocType = request.getParameter("doctype");
  String gu_workarea = request.getParameter("gu_workarea");
  String tipo_msite = request.getParameter("tipo_msite");
  
  String sProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(),"fileprotocol", "file://");
  
  String sDefImgSrv = request.getRequestURI();
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv + "/images";
  
  String sImageServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "imageserver", sDefImgSrv);
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sWrkAPut = Environment.getProfilePath(GlobalDBBind.getProfileName(), "workareasput");

  String sSelLang = id_language;
  String sGuMicrosite, sNmMicrosite, sMetaDataPath, sSubPath, sOutputPath, sTitle;

  final String sSep = sProtocol.equals("ftp://") ? "/" : System.getProperty("file.separator");

  if (null==sStorage) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=storage property not set at .cnf file&resume=_back"));
    return;  
  }
    
  if (sDocType.equals("newsletter")) {
    sTitle = "NewsLetter";
    sSubPath = "domains" + sSep + id_domain + sSep + "workareas" + sSep + gu_workarea + sSep + "apps" + sSep + "Mailwire" + sSep + "data";
  }
  else if (sDocType.equals("survey")) {
    sTitle = "Questionnaire";
    sSubPath = "domains" + sSep + id_domain + sSep + "workareas" + sSep + gu_workarea + sSep + "apps" + sSep + "Surveys" + sSep + "data";
  }
  else {
    sTitle = "WebSite";
    sSubPath = "domains" + sSep + id_domain + sSep + "workareas" + sSep + gu_workarea + sSep + "apps" + sSep + "WebBuilder" + sSep + "data";
  }
  
  sOutputPath = sStorage + sSubPath;
  
  String sTextDate = Gadgets.replace(" (" + DBBind.escape(new Date(),"dateTime") + ")", ":",".");

  String sFileOut = sOutputPath + sSep + "$" + sTextDate + ".xml";
  String sNmPageset = "$" + sTextDate;
  
  FileSystem oFS = new FileSystem(Environment.getProfile(GlobalDBBind.getProfileName()));
  
  try {
  
    if (sProtocol.equals("ftp://"))

      oFS.mkdirs (sProtocol + Environment.getProfileVar(GlobalDBBind.getProfileName(),"fileserver", "localhost") + sStorage + sSubPath);

    else

      oFS.mkdirs (sProtocol + sStorage + sSubPath);

  }
  catch (IOException ioe) {
    oFS = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", ioe.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + ioe.getMessage() + "&resume=_back"));
  }
  catch (Exception xcpt) {
    oFS = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "Exception", xcpt.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + xcpt.getClass().getName() + "&desc=" + xcpt.getMessage() + "&resume=_back"));
  }
  
  if (null==oFS) return;  
  oFS = null;
   
%>
<!-- +-----------------------+ -->
<!-- | Lista de Plantillas   | -->
<!-- | © KnowGate 2003-2009  | -->
<!-- +-----------------------+ -->
<HTML>
  <HEAD>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
      var counter = 0;
      var skin = getCookie("skin"); if (""==skin) skin="xp";
      
      //-----------------------------------------------------------------------
                  
      function choose() {               
        var frm = document.forms[0];
				var myString;

        if (counter==1) 
         myString = frm.tipo_msite.value;
        else
         for (i=0;i<frm.tipo_msite.length;i++) {
          if (frm.tipo_msite[i].checked) 
           myString = frm.tipo_msite[i].value;
      	 } // next

			  if (myString=="adhoc") {

      	  frm.nm_microsite.value = "";
          frm.path_metadata.value = "";
          frm.gu_microsite.value = "adhoc";
        
          frm.nm_pageset.value = frm.nm_mailing.value;
          frm.path_data.value = "<%=esc(sWrkAPut+File.separator+gu_workarea+File.separator+"apps"+File.separator+"Hipermail"+File.separator+"html")%>";
      	  frm.tp_microsite.value = "1";

			  } else { 
      	  splitString = myString.split(",");
      	
      	  nmstr = splitString[0];
      	  vlstr = splitString[1];
      	  hdstr = splitString[2];
      	
      	  frm.nm_microsite.value = nmstr;
          frm.path_metadata.value = hdstr;
          frm.gu_microsite.value = vlstr;
        
          frm.nm_pageset.value = "<% out.write(sNmPageset); %>";
          frm.path_data.value = "<% out.write(esc(sSubPath + sSep + "$" + sTextDate + ".xml")); %>";
        
          frm.nm_pageset.value = frm.nm_pageset.value.replace("$",frm.nm_microsite.value);
          frm.path_data.value = frm.path_data.value.replace("$",frm.nm_microsite.value);
      
      	  if (frm.doctype.value=="newsletter")
      	    frm.tp_microsite.value = "1";
      	  else if (frm.doctype.value=="website")
      	    frm.tp_microsite.value = "2";
      	  else if (frm.doctype.value=="survey")
      	    frm.tp_microsite.value = "4";
        }
        if (validate()) frm.submit();
      }

      //-----------------------------------------------------------------------
            
      function showThumbnail(file)
      {
        document.getElementById('imgThumb').src = '<%=sImageServer%>/styles/thumbnails/' + file;
      }

      //-----------------------------------------------------------------------
      
      function cleanThumbnail()
      {
        var s = '<%=sImageServer%>/images/webbuilder/pixeltrans.gif';
        var q = document.forms[0].tipo_msite;
        if (q.length)
        {
        for(var i=0;i<q.length;i++) {
          if(q[i].checked==true) {
            r = q[i].value;
            r = r.split(",");
            r = r[0];
            r = r.replace(" ","");
            s = '<%=sImageServer%>/styles/thumbnails/' +r+ '.gif';
          }
        }
        }
        else
        {
            if (q.length)
             r = q[0].value;
            else
             r = q.value;
            r = r.split(",");
            r = r[0];
            r = r.replace(" ","");
            s = '<%=sImageServer%>/styles/thumbnails/' +r+ '.gif';
        }
        document.getElementById('imgThumb').src = s;
      }

      //-----------------------------------------------------------------------

      function showFirstThumbnail()
      {
        var s = "<%=sImageServer%>/images/webbuilder/pixeltrans.gif";
        var q = document.forms[0].tipo_msite;

        setCombo(document.forms[0].sel_language, "<%=id_language%>");

<% if (tipo_msite!=null) { %>
        setCheckedValue(q,"<%=tipo_msite%>");
        choose();
<% } else { %>

        if (q.length)
         r = q[0].value;
        else
         r = q.value;
        
        if (r!="adhoc") {
          r = r.split(",");
          r = r[0];
          r = r.replace(" ","");
          s = "<%=sImageServer%>/styles/thumbnails/" +r+ ".gif";
        }

        document.getElementById('imgThumb').src = s;

				document.getElementById("mailing_name").style.display = (q.checked ? "block" : "none");
<% } %>
      }

      //-----------------------------------------------------------------------
      
      function activateRadio(s)
      {
        var q = document.forms[0].tipo_msite;
        for(var i=0;i<q.length;i++) {
          if (q[i].value==s) {
            q[i].checked=true;
          }
        }
      }

      // ------------------------------------------------------

      function reference(odctrl) {
        var frm = document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/reference.jsp?nm_table=k_companies&tp_control=1&nm_control=nm_legal&nm_coding=gu_company", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // reference()

      //-----------------------------------------------------------------------
      
      function validate() {
      
        var frm = document.forms[0];
         
        if (frm.tx_comments.value.length>255) {
          alert ("Comments may not be longer than 255 characters");
          return false;
        }

				if (frm.tipo_msite.value=="adhoc") {
				  if (frm.nm_mailing.value.length==0) {
            alert ("e-mailing short name is required");
            frm.nm_mailing.focus();
            return false;				  
				  }

				  if (hasForbiddenChars(frm.nm_mailing.value) || frm.nm_mailing.value.indexOf(" ")>=0) {
            alert ("e-mailing short name contains invalid characters");
            frm.nm_mailing.focus();
            return false;
			    } else {
			      frm.nm_mailing.value = frm.nm_mailing.value.toLowerCase();
			    }
				}
			
	      frm.id_language.value = getCombo(frm.sel_language);

        return true;
      } // validate
      
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  SCROLL="yes" TOPMARGIN="4" MARGINHEIGHT="4" LEFTMARGIN="4" RIGHTMARGIN="4" onLoad="showFirstThumbnail();">
    <FORM target="_self" NAME="frm_pageset_edit" METHOD="post" ACTION="pageset_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="doctype" VALUE="<%=sDocType%>">
    <INPUT TYPE="hidden" NAME="id_language" VALUE="<%=id_language%>">
    <INPUT TYPE="hidden" NAME="vs_stamp" VALUE="1.0.0">
    <INPUT TYPE="hidden" NAME="gu_pageset" VALUE="<%=Gadgets.generateUUID()%>">
    <INPUT TYPE="hidden" NAME="gu_microsite" VALUE="xxxx">
    <INPUT TYPE="hidden" NAME="tp_microsite" VALUE="1">
    <INPUT TYPE="hidden" NAME="nm_microsite" VALUE="xxxx">
    <INPUT TYPE="hidden" NAME="path_metadata" VALUE="xxxx">
    <INPUT TYPE="hidden" NAME="path_data" VALUE="xxxx">
    <INPUT TYPE="hidden" NAME="nm_pageset" VALUE="xxxx">
    <INPUT TYPE="hidden" NAME="title" VALUE="<%=sTitle%>">
    
    <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
    <TR>
    <TD VALIGN="TOP">
    <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<% if (sDocType.equals("newsletter")) { %>    	
    <TR><TD CLASS="strip1"><input type="radio" name="tipo_msite" value="adhoc" onclick="document.getElementById('mailing_name').style.display = (this.checked ? 'block' : 'none')">&nbsp;<A STYLE="text-decoration:none" CLASS="linkplain" onmouseout="javascript:cleanThumbnail()" onmouseover="javascript:document.getElementById('imgThumb').src = '../images/images/spacer.gif' ">Ad-Hoc (Sin plantilla)</A></TD></TR>
  <TR><TD CLASS="strip1"><DIV ID="mailing_name" STYLE="display:none"><FONT CLASS="textsmall">Short Name&nbsp;</FONT><INPUT TYPE="text" CLASS="combomini" NAME="nm_mailing" MAXLENGTH="30" STYLE="text-transform:lowercase"></DIV></TD></TR>
<% } 
  JDCConnection oConn = null;
  PreparedStatement oStmt;
  ResultSet oRSet;
  int iOdPos = 0;
  int counter = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("lookup_mid");

    sSelLang = GlobalDBLang.toHTMLSelect(oConn, sLanguage);
  
    if (sDocType.equals("newsletter"))
     oStmt = oConn.prepareStatement("SELECT " + DB.nm_microsite + "," + DB.gu_microsite  +", " + DB.path_metadata + " FROM " + nm_table + " WHERE id_app=13 AND ("+DB.gu_workarea+" IS NULL OR "+DB.gu_workarea+"=?)");
    else if (sDocType.equals("survey"))
     oStmt = oConn.prepareStatement("SELECT " + DB.nm_microsite + "," + DB.gu_microsite  +", " + DB.path_metadata + " FROM " + nm_table + " WHERE id_app=23 AND ("+DB.gu_workarea+" IS NULL OR "+DB.gu_workarea+"=?)");
    else
     oStmt = oConn.prepareStatement("SELECT " + DB.nm_microsite + "," + DB.gu_microsite  +", " + DB.path_metadata + " FROM " + nm_table + " WHERE id_app=14 AND ("+DB.gu_workarea+" IS NULL OR "+DB.gu_workarea+"=?)");
		oStmt.setString(1, sWorkArea);
    oRSet = oStmt.executeQuery(); 
    
    iOdPos = 0;       
    while (oRSet.next()) {
      sNmMicrosite = oRSet.getString(1);     
      sGuMicrosite = oRSet.getString(2);
      sMetaDataPath = Gadgets.replace(oRSet.getString(3),"/",sSep);       
      if (sSep.equals("/")) sMetaDataPath = sMetaDataPath.replace('\\','/');
      out.write ("<TR><TD CLASS=\"strip" + String.valueOf(++iOdPos%2+1) + "\">");
      out.write ("<A style='text-decoration:none' onmouseout='javascript:cleanThumbnail()' onmouseover='javascript:showThumbnail(\"" + Gadgets.removeChar(sNmMicrosite,' ') + ".gif\")' href='javascript:void(0)' CLASS='linkplain'>");
      out.write ("\n<input type=\"radio\" name=\"tipo_msite\" value=\"" + sNmMicrosite + "," + sGuMicrosite + "," + sStorage + sMetaDataPath + "\" ");
      if (counter==0) out.write("checked");
      out.write(">");
      out.write("</a>");
      out.write ("<A STYLE='text-decoration:none' onmouseout='javascript:cleanThumbnail()' onClick='activateRadio(\"" + sNmMicrosite + "," + sGuMicrosite + "," + esc(sStorage) + back(sMetaDataPath) + "\")' onmouseover='javascript:showThumbnail(\"" + Gadgets.removeChar(sNmMicrosite,' ') + ".gif\")' href='javascript:void(0)' CLASS='linkplain'>" + sNmMicrosite + "<A></TD></TR>\n");
      counter++;
    } // wend

    out.write ("<SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\"> counter=" + String.valueOf(counter+1) + "; </SCRIPT>\n");
   
    oRSet.close();
    oRSet = null;
    oStmt.close();
    oStmt = null;
    oConn.close("lookup_mid");
  }
  catch (SQLException e) {
    if (null!=oConn)
      if (!oConn.isClosed()) {
        oConn.close("lookup_mid");
        oConn = null;
      }
      
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
          
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  
  if (null==oConn) return;
  
  oConn = null;

%>          
     <TR><TD ALIGN="left" WIDTH="90">&nbsp;<BR></TD></TR>
     <TR><TD ALIGN="left" WIDTH="90"><FONT CLASS="formstrong">Language:</FONT><BR></TD></TR>
     <TR><TD><SELECT NAME="sel_language"><OPTION VALUE="es" SELECTED>Spanish<% out.write (sSelLang); %></SELECT></TD></TR>
     <TR><TD ALIGN="left" WIDTH="90"><FONT CLASS="formstrong">Company</FONT><BR></TD></TR>
     <TR><TD><INPUT TYPE="hidden" NAME="gu_company"><INPUT TYPE="text" NAME="nm_legal" SIZE="30" TABINDEX="-1">&nbsp;&nbsp;<A HREF="javascript:reference(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View list of companies"></A></TD></TR>
     <TR><TD ALIGN="left" WIDTH="90">&nbsp;<BR></TD></TR>
     <TR><TD ALIGN="left" WIDTH="90"><FONT CLASS="formplain">Comments:</FONT><BR></TD></TR>
     <TR><TD ALIGN="left" WIDTH="370"><TEXTAREA NAME="tx_comments" COLS="30" ROWS="5"></TEXTAREA></TD></TR>
    </TABLE>
    </TD>
    <TD WIDTH="180" VALIGN="TOP" ALIGN="right" CLASS="formplain">
    <IMG ID="imgThumb" NAME="imgThumb" HEIGHT="282" WIDTH="242" BORDER="1" SRC="../images/images/webbuilder/pixeltrans.gif"><BR>
    <b>Preview</b>
    </TD>
    </TR>
    </TABLE>
    <INPUT TYPE="hidden" NAME="chkcount" VALUE="<%=iOdPos%>">
    </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>