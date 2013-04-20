<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.dataxslt.db.MicrositeDB" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
  
  // 01. Authenticate user session by checking cookies
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String sSkin = getCookie(request, "skin", "xp");
  final String sLanguage = getNavigatorLanguage(request);

  final String sSep = java.io.File.separator;
  final String sProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  final String sFileSrvr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  final String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  final String sTemplates = sStorage + "xslt" + sSep + "templates" + sSep;
  final String sThumbPath = Gadgets.chomp(request.getRealPath("/images"), sSep)+"styles"+sSep+"thumbnails"+sSep;

  String sDefImgSrv = request.getRequestURI();
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv + "/images";
  
  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + sSep + "workareas";

  String sImageServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "imageserver", sDefImgSrv);

  String sEnvWorkPut	= Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasput", sDefWrkArPut);
  
  final String id_domain = request.getParameter("id_domain");
  final String gu_workarea = request.getParameter("gu_workarea");
  final String gu_microsite = request.getParameter("gu_microsite");
  String nm_microsite = "";

  String sOutputPathEdit = sEnvWorkPut + sSep + gu_workarea + sSep + "apps" + sSep + "Mailwire" + sSep + "html" + sSep + gu_microsite + sSep;
  
  File oFl;
  
  MicrositeDB oMSite = new MicrositeDB();
      
  JDCConnection oConn = null;
    
  try {
    
    oConn = GlobalDBBind.getConnection("microsite_edit");  
    
    if (null!=gu_microsite) {
      oMSite.load(oConn, new Object[]{gu_microsite});
      nm_microsite = oMSite.getStringNull(DB.nm_microsite,"");
    }
    
    oConn.close("microsite_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("microsite_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Microsite</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	if (hasForbiddenChars(frm.nm_microsite.value)) {
	  alert ("Microsite name contains forbidden characters");
	  return false;
	}

<% if (oMSite.isNull(DB.tp_microsite)) { %>
	
	if (frm.sel_type.selectedIndex<=0) {
	  alert ("Microsite type is required");
	  return false;	
	}
	
	// Move selected combo value into hidden field
	frm.tp_microsite.value = getCombo(frm.sel_type);
		
        switch (parseInt(frm.tp_microsite.value)) {
          case 1:
            frm.id_app.value="13";
            break;
          case 2:
            frm.id_app.value="14";
            break;
          case 4:
            frm.id_app.value="23";
            break;
        }
<% } else {
	out.write("        frm.id_app.value=\""+String.valueOf(oMSite.getInt(DB.id_app))+"\";\n");
	out.write("        frm.tp_microsite.value=\""+String.valueOf(oMSite.getShort(DB.tp_microsite))+"\";\n");
   }
%>
	
        return true;
      } // validate
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
<% if (!oMSite.isNull(DB.tp_microsite)) { 
	out.write ("        frm.id_app.value =\""+String.valueOf(oMSite.getInt(DB.id_app))+"\";\n");
	out.write ("        frm.tp_microsite.value =\""+String.valueOf(oMSite.getShort(DB.tp_microsite))+"\";\n");
  } %>
        return true;
      } // setCombos
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Microsite</FONT></TD></TR>
  </TABLE>
  <FORM ACTION="microsite_edit_store.jsp" METHOD="post" ENCTYPE="multipart/form-data" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_microsite" VALUE="<%=oMSite.getStringNull(DB.gu_microsite,"")%>">
    <INPUT TYPE="hidden" NAME="tp_microsite">
    <INPUT TYPE="hidden" NAME="id_app">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_microsite" MAXLENGTH="128" SIZE="30" VALUE="<%=nm_microsite%>"></TD>
          </TR>
<% if (oMSite.isNull(DB.tp_microsite)) { %>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Type:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">              
              <SELECT NAME="sel_type"><OPTION VALUE=""></OPTION><OPTION VALUE="1">Newsletter</OPTION><OPTION VALUE="2">WebSite</OPTION><OPTION VALUE="4">Questionnaire</OPTION></SELECT>
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Definition:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="file" NAME="path_metadata" SIZE="30"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"></TD>
            <TD ALIGN="left" WIDTH="370">
<% if (!oMSite.isNull(DB.path_metadata)) {
     String sPath = oMSite.getString(DB.path_metadata);
     int iSlash = 0;
     for (int i=sPath.length()-1; i>0; i--) {
       if (sPath.charAt(i)=='/' || sPath.charAt(i)=='\\') {
         iSlash = i;
         break;
       }
     } // next
     String sFileName = sPath.substring(0, iSlash);

       out.write("<A TARGET=\"blank\" CLASS=\"linkplain\" HREF=\"microsite_download.jsp?site_name="+nm_microsite+"&file_name="+nm_microsite+".xml\">"+nm_microsite+".xml</A>");
   } %>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Data</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="file" NAME="path_defdata" SIZE="30"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"></TD>
            <TD ALIGN="left" WIDTH="370">
<% if (nm_microsite.length()>0) {
     oFl = new File(sTemplates+nm_microsite+sSep+nm_microsite+".datatemplate.xml");
     if (oFl.exists()) {
       out.write("<A TARGET=\"blank\" CLASS=\"linkplain\" HREF=\"microsite_download.jsp?site_name="+nm_microsite+"&file_name="+nm_microsite+".datatemplate.xml\">"+nm_microsite+".datatemplate.xml</A>");
     }
   }
%>          </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Template</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="file" NAME="path_template" SIZE="30"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"></TD>
            <TD ALIGN="left" WIDTH="370">
<% if (nm_microsite.length()>0) {
     oFl = new File(sTemplates+nm_microsite+sSep+nm_microsite+".xsl");
     if (oFl.exists()) {
       out.write("<A TARGET=\"blank\" CLASS=\"linkplain\" HREF=\"microsite_download.jsp?site_name="+nm_microsite+"&file_name="+nm_microsite+".xsl\">"+nm_microsite+".xsl</A>");
     }
   }
%>          </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Preview:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="file" NAME="path_thumbnail" SIZE="30"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"></TD>
            <TD ALIGN="left" WIDTH="370">
<% if (nm_microsite.length()>0) {
     oFl = new File(sThumbPath+nm_microsite+".gif");
     if (oFl.exists()) {
       out.write("<A CLASS=\"linkplain\" HREF=\""+sImageServer+"/styles/thumbnails/"+nm_microsite+".gif\">"+nm_microsite+".gif</A>");
     }
   }
%>          </TD>
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
