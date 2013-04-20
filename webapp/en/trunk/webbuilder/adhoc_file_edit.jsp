<%@ page import="java.io.File,java.io.IOException,java.io.ByteArrayOutputStream,java.io.StringBufferInputStream,java.net.URL,java.net.URLDecoder,java.sql.SQLException,org.w3c.tidy.Tidy,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dfs.FileSystem,com.knowgate.hipergate.*,com.knowgate.hipermail.AdHocMailing,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
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
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "adhoc_file_edit";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_mailing = request.getParameter("gu_mailing");
  String pg_mailing = request.getParameter("pg_mailing");
  String nm_file = request.getParameter("nm_file");

  String id_user = getCookie(request, "userid", "");

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut + File.separator + "workareas/";
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;
  String sTargetDir = null;
  String sHtmlSource = "";
  String sEncoding = "";

  AdHocMailing oObj = new AdHocMailing();    
  JDCConnection oConn = null;
  FileSystem oFs = new FileSystem();
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

		oConn.setReadOnly(true);
    
    oObj.load(oConn, new Object[]{gu_mailing});

		if (!oObj.isNull(DB.pg_mailing)) {
      sTargetDir = sWrkAPut + gu_workarea + File.separator + "apps" + File.separator + "Hipermail" + File.separator + "html" + File.separator + Gadgets.leftPad(String.valueOf(oObj.getInt(DB.pg_mailing)), '0', 5);
    }

    oConn.close(PAGE_NAME);
    
    sEncoding = oFs.detectEncoding("file://"+sTargetDir+File.separator+nm_file, "ASCII");
    sHtmlSource = oFs.readfilestr("file://"+sTargetDir+File.separator+nm_file,sEncoding);
    
    if (nm_file.endsWith(".htm") || nm_file.endsWith(".html")) {
      ByteArrayOutputStream oPPrnt = new ByteArrayOutputStream();
      Tidy oTdy = new Tidy();
      oTdy.setIndentContent(true);
      oTdy.setIndentAttributes(false);
		  oTdy.setWraplen(80);
		  // oTdy.setOutputEncoding(sEncoding);
		  oTdy.parseDOM(new StringBufferInputStream(sHtmlSource), oPPrnt);
		  sHtmlSource = new String(oPPrnt.toByteArray(), sEncoding);
		  String sGenerator = "    <meta name=\"generator\" content=\"HTML Tidy, see www.w3.org\">";
		  int iGenerator = sHtmlSource.indexOf(sGenerator);
		  if (iGenerator>0) sHtmlSource = sHtmlSource.substring(0,iGenerator)+sHtmlSource.substring(iGenerator+sGenerator.length());
    }
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.dispose(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Ad hoc e-mailing</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
 			var lastsought = "";
 			var findfrom = 0;
 			var htmlsrc = "<%=Gadgets.removeChar(Gadgets.replace(Gadgets.escapeChars(sHtmlSource, "\"", '\\'),(char)13,"\n"),(char)10)%>";
 			
      // ------------------------------------------------------

		  function findSubstr() {
        var frm = window.document.forms[0];
        var sgh = frm.sought.value;
        var txa = frm.html_src;
        if (sgh.length>0) {
        	lastsought = sgh;
          if (sgh!=lastsought) {
				    findfrom = 0;
				  }
				  var mtc = txa.value.indexOf(sgh,findfrom);
				  if (mtc>=0) {
					  findfrom = mtc + sgh.length;
					  if (findfrom>=txa.value.length) findfrom = 0;
						txa.focus();
  					var lnn = -1;
  					var nwl = 0;
  					while (nwl<mtc) {
  					  nwl = txa.value.indexOf("\n",nwl);
  					  if (nwl++>0) lnn++; else break;
  					}
  					txa.scrollTop = lnn * txa.clientHeight / txa.rows;
						if (navigator.userAgent.indexOf("MSIE")>1) {
              var rng = txa.createTextRange();
              rng.collapse(true);
              rng.moveStart("character", mtc);
           		rng.moveEnd("character", -txa.value.length + mtc+sgh.length);
              rng.select();                                              
            } else {
              txa.setSelectionRange(mtc, mtc+sgh.length);
            }
				  } else {
				  	if (findfrom>0) {
				      findfrom = 0;
				      findSubstr();
				    }
				  } // fi
				} // fi
		  }       

      // ------------------------------------------------------


      function validate() {
        var frm = window.document.forms[0];

      
        return true;
      } // validate;

    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Ad hoc e-mailing <% if (!oObj.isNull(DB.pg_mailing)) out.write(String.valueOf(oObj.getInt(DB.pg_mailing))); %></FONT></TD></TR>
  </TABLE>
  <FORM METHOD="post" ACTION="adhoc_file_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_mailing" VALUE="<%=oObj.getStringNull("gu_mailing","")%>">
    <INPUT TYPE="hidden" NAME="pg_mailing" VALUE="<% if (!oObj.isNull(DB.pg_mailing)) out.write(String.valueOf(oObj.getInt(DB.pg_mailing))); %>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="id_encoding" VALUE="<%=sEncoding%>">
    <INPUT TYPE="hidden" NAME="nm_file" VALUE="<%=Gadgets.HTMLEncode(nm_file)%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="left">
            	<INPUT NAME="sought">&nbsp;<INPUT TYPE="button" VALUE="Find" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+f" onclick="findSubstr()">
    	      </TD>
    	    </TR>
          <TR>
            <TD ALIGN="center">
            	<TEXTAREA WRAP="off" NAME="html_src" ROWS="20" COLS="94" STYLE="font-family:Monospace;font-size:12px"><%=Gadgets.HTMLEncode(sHtmlSource)%></TEXTAREA>
						  <BR/>
						  <INPUT TYPE="submit" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;<INPUT TYPE="button" VALUE="Cancel" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+c" onclick="window.history.back()">
    	      </TD>
    	    </TR>
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
