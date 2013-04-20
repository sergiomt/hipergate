<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.io.File,java.sql.SQLException,com.oreilly.servlet.MultipartRequest,org.apache.oro.text.regex.MalformedPatternException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.misc.VCardParser,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_domain = null, gu_workarea = null, nm_workarea = null;

  Cookie aCookies[] = request.getCookies();
    
  if (null != aCookies) {
      for (int c=0; c<aCookies.length; c++) {
      	if (aCookies[c].getName().equals("workarea")) {
          gu_workarea = java.net.URLDecoder.decode(aCookies[c].getValue());
        } else if (aCookies[c].getName().equals("workareanm")) {
          nm_workarea = java.net.URLDecoder.decode(aCookies[c].getValue());
        } else if (aCookies[c].getName().equals("domainid")) {
          id_domain = java.net.URLDecoder.decode(aCookies[c].getValue());
        }  
      } // for      
  } // fi
  

  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  String sSkin = getCookie(request, "skin", "xp");

  File oTmp = new File(sTmpDir);
  if (!oTmp.canWrite()) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=It is not possible to write into directory "+sTmpDir+"&resume=_back"));  
    return;
  }

  sTmpDir = Gadgets.chomp(sTmpDir,File.separator) + gu_workarea;
  oTmp = new File(sTmpDir);
  if (!oTmp.exists()) oTmp.mkdir();

  int iMaxPostSize = Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "10485760"));

  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, iMaxPostSize, "UTF-8");

  String id_action = oReq.getParameter("sel_action");
  String id_encoding = oReq.getParameter("sel_encoding");
  String nu_maxerrors = oReq.getParameter("maxerrors");
  String is_loadlookups = nullif(oReq.getParameter("loadlookups")).equals("INSERTLOOKUPS") ? "INSERTLOOKUPS" : "";
  String is_recoverable = nullif(oReq.getParameter("recoverable")).equals("RECOVERABLE") ? "RECOVERABLE" : "UNRECOVERABLE";

  File oVcfFile = oReq.getFile(0);
  int iFLen = (int) oVcfFile.length();
  
  if (iFLen==0) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=The file to be loaded is empty&resume=_back"));
    return;
  }

  VCardParser oPrsr = new VCardParser();
  oPrsr.parse(oVcfFile, id_encoding);
  
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Load Contacts from VCard</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function validate() {
	      return window.confirm("You are about to import the selected file");
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <FORM method="post" ACTION="vcardloader3.jsp" onsubmit="return validate()">
  <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
  <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
  <INPUT TYPE="hidden" NAME="nm_workarea" VALUE="<%=nm_workarea%>">
  <INPUT TYPE="hidden" NAME="nm_file" VALUE="<%=oVcfFile.getName()%>">
  <INPUT TYPE="hidden" NAME="id_encoding" VALUE="<%=id_encoding%>">
  <INPUT TYPE="hidden" NAME="id_action" VALUE="<%=id_action%>">
  <INPUT TYPE="hidden" NAME="nu_maxerrors" VALUE="<%=nu_maxerrors%>">
  <INPUT TYPE="hidden" NAME="is_recoverable" VALUE="<%=is_recoverable%>">
  <INPUT TYPE="hidden" NAME="is_loadlookups" VALUE="<%=is_loadlookups%>">
  
  <TABLE SUMMARY="Form Title" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Load Contacts from VCard</FONT></TD></TR>
  </TABLE>  
  <TABLE SUMMARY="Preview">
    <TR>
      <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Name</B></TD>
      <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Company</B></TD>
      <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>e-mail</B></TD>
    </TR>
<%
  int nCards = oPrsr.getVCardsCount();
  if (nCards>5) nCards = 5;
  
  for (int c=0; c<nCards; c++) {
    String sStrip = String.valueOf((c%2)+1);
    HashMap<String,String> oVCard = oPrsr.vcard(c);
    out.write("<TR><TD CLASS=\"strip"+sStrip+"\">"+nullif(oVCard.get("FN"), oVCard.get("N"))+"</TD>");
    out.write("<TD CLASS=\"strip"+sStrip+"\">"+nullif(oVCard.get("ORG"))+"</TD>");
    out.write("<TD CLASS=\"strip"+sStrip+"\">"+nullif(oVCard.get("EMAIL;INTERNET"))+"</TD></TR>");     
  } // next
  
%>
  </TABLE>
  <INPUT TYPE="button" class="pushbutton" VALUE="Previous" TITLE="ALT+b" ACCESSKEY="b" onclick="document.location='textloader2undo.jsp?action=_back&workarea=<%=gu_workarea%>&filename=<%=oVcfFile.getName()%>'">
  &nbsp;&nbsp;&nbsp;
  <INPUT TYPE="submit" class="pushbutton" VALUE="Import" TITLE="ALT+i" ACCESSKEY="i">
  &nbsp;&nbsp;&nbsp;
  <INPUT TYPE="button" class="closebutton" VALUE="Cancel" TITLE="ALT+c" ACCESSKEY="c" onclick="document.location='textloader2undo.jsp?action=_close&workarea=<%=gu_workarea%>&filename=<%=oVcfFile.getName()%>'">
  </FORM>
</BODY>
</HTML>