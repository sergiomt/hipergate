<%@ page import="java.io.File,java.util.ArrayList,java.util.Properties,java.io.File,java.util.Date,java.text.SimpleDateFormat,java.util.ArrayList,java.io.IOException,java.net.URL,java.net.URLDecoder,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Gadgets,com.knowgate.dfs.FileSystem,com.knowgate.dfs.chardet.CharacterSetDetector,com.knowgate.hipermail.HtmlMimeBodyPart,com.knowgate.hipermail.MailAccount,com.knowgate.hipermail.SendMail" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  boolean bAttachments = nullif(request.getParameter("bo_attachments"),"0").equals("1");
  String sGuAccount = request.getParameter("gu_account");
  String sBasePath = Gadgets.chomp(request.getParameter("base_path"),File.separator);
  String sBaseHref = request.getParameter("base_href");
  String sHtmlFile = request.getParameter("html_file");
  String sPlainFile = request.getParameter("plain_file");
  int iDocType = Integer.parseInt(request.getParameter("doc_type"));
  
  String[] aRecipients = Gadgets.split(request.getParameter("recipients"),',');
  
  ArrayList oMsgs = null;
  Date oDtNow = new Date();
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyyMMDDhhmmss");
  
  FileSystem oFs = new FileSystem();
  CharacterSetDetector oCSet = new CharacterSetDetector();
  String sEncoding = oCSet.detect(sBasePath+sHtmlFile,"ISO8859_1");
  MailAccount oMacc = null;

  URL oWebSrv = new URL(GlobalDBBind.getProperty("webserver"));
  ArrayList<String> oAttachments = new ArrayList<String>();
  String[] aFiles = new File(sBasePath).list();
  if (aFiles!=null) {
    for (int f=0; f<aFiles.length; f++) {
      String sFileName = aFiles[f].toLowerCase();
      if (sFileName.endsWith(".pdf") || sFileName.endsWith(".doc") || sFileName.endsWith(".xls") || sFileName.endsWith(".ppt") ||
          sFileName.endsWith(".odf") || sFileName.endsWith(".odg") || sFileName.endsWith(".zip") || sFileName.endsWith(".arj") ||
          sFileName.endsWith(".rar") || sFileName.endsWith(".avi") || sFileName.endsWith(".mpg") || sFileName.endsWith(".mpeg") ||
          sFileName.endsWith(".wmv") || sFileName.endsWith(".docx") || sFileName.endsWith(".xlsx"))
        oAttachments.add(aFiles[f]);    
    } // next
  } // fi
  String[] aAttachments;
  if (oAttachments.size()==0)
    aAttachments = null;
  else
    aAttachments = oAttachments.toArray(new String[oAttachments.size()]);
  
  try {
    JDCConnection oConn = GlobalDBBind.getConnection("adhoc_mailing_send");
    oMacc = new MailAccount(oConn, sGuAccount);
    oConn.close("adhoc_mailing_send");
		String sHtmlText = sHtmlFile.length()==0 ? null : oFs.readfilestr(sBasePath+sHtmlFile,sEncoding);
		if (bAttachments) {
		  HtmlMimeBodyPart oHtml = new HtmlMimeBodyPart(sHtmlText, sEncoding);
		  sHtmlText = oHtml.replacePreffixFromImgSrcs(sBaseHref, sBasePath);
		}
		Properties oProps = oMacc.getProperties();
		if (bAttachments) oProps.put("attachimages","yes"); else oProps.put("attachimages","no");
	  oMsgs = SendMail.send(oMacc, oProps, sBasePath,
					   	            sHtmlText,
					   	            sPlainFile.length()==0 ? null : oFs.readfilestr(sBasePath+sPlainFile,sEncoding),
							            sEncoding, aAttachments,
							     				request.getParameter("tx_subject"),
							     				request.getParameter("tx_email_from"),
							     				request.getParameter("nm_from"),
							     				request.getParameter("tx_email_reply"),
							     				aRecipients, "to",
							     				"test_"+request.getParameter("gu_mailing")+"_"+oFmt.format(oDtNow),
							     				GlobalDBBind.getProfileName(), "Test "+request.getParameter("nm_mailing")+" "+oFmt.format(oDtNow), true, GlobalDBBind);
  }
  catch (Exception e) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
    return;
  }
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Test of ad-hoc e-mailing</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
  <BODY>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Test results</FONT></TD></TR>
  </TABLE>
  <BR/>
<% for (int m=0; m<oMsgs.size(); m++) {
     out.write("<FONT CLASS=\"textplain\">"+oMsgs.get(m)+"</FONT><BR/>\n");
   } %>
   <BR/>
   <FORM>
     <INPUT TYPE="button" VALUE="OK" onclick="document.location='<%=(iDocType==21 ? "adhoc_mailing_edit.jsp?gu_mailing=" : "pageset_change.jsp?gu_pageset=")+request.getParameter("gu_mailing")+"&gu_workarea="+request.getParameter("gu_workarea")+"&id_domain="+request.getParameter("id_domain")%>'">
   </FORM>
  </BODY>
</HTML>