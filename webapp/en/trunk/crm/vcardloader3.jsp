<%@ page import="java.io.IOException,java.io.File,java.net.URLDecoder,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.datamodel.ImportExport,com.knowgate.hipergate.datamodel.ImportExportException" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%!

  public static String escapeFileSeparator(String sInput, String sEscFileSep) {
    if (sEscFileSep.length()==1) {
      return sInput;
    } else {
      int nChars = sInput.length();
      StringBuffer oBuff = new StringBuffer(nChars+20);
	    for (int c=0; c<nChars; c++) {
	      if (sInput.charAt(c)==File.separatorChar)
	        oBuff.append(sEscFileSep);
	      else
	        oBuff.append(sInput.charAt(c));	      	
	    } // next
	    return oBuff.toString();
    }
  } // escapeFileSeparator
%><%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String nm_workarea = request.getParameter("nm_workarea");
  String nm_file = request.getParameter("nm_file");
  String id_encoding = request.getParameter("id_encoding");
  String id_action = request.getParameter("id_action");
  String nu_maxerrors = request.getParameter("nu_maxerrors");
  String is_recoverable = request.getParameter("is_recoverable");
  String is_loadlookups = request.getParameter("is_loadlookups");
  
  String sEscFileSep = (File.separator.equals("\\") ? File.separator+File.separator : File.separator);
  String sConnStr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "dburl");
  String sUsr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "dbuser");
  String sPwd = Environment.getProfileVar(GlobalDBBind.getProfileName(), "dbpassword");
  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  String sWrkADir = Gadgets.chomp(escapeFileSeparator(sTmpDir,sEscFileSep),sEscFileSep)+gu_workarea+sEscFileSep;
  
  ImportExport oImp = new ImportExport();
  int iErrCount = 0;
  
  try {
    iErrCount = oImp.perform(id_action+" VCARDS CONNECT "+sUsr+" TO \""+sConnStr+"\" IDENTIFIED BY "+sPwd+" WORKAREA "+nm_workarea+" "+is_recoverable+" "+is_loadlookups+" MAXERRORS "+nu_maxerrors+" INPUTFILE \""+sWrkADir+nm_file+"\" CHARSET "+id_encoding+" BADFILE \""+sWrkADir+"bad_"+nm_file+"\" DISCARDFILE \""+sWrkADir+"dis_"+nm_file+"\"");
    response.sendRedirect (response.encodeRedirectUrl ("textloader4f.jsp?gu_workarea="+gu_workarea+"&nm_file="+Gadgets.URLEncode(nm_file)+"&id_status="+(0==iErrCount ? "success" : "warning")));
  }
  catch (ImportExportException e) {  
    response.sendRedirect (response.encodeRedirectUrl ("textloader4f.jsp?gu_workarea="+gu_workarea+"&nm_file="+Gadgets.URLEncode(nm_file)+"&id_status=error&desc=" + e.getMessage()));
  }
%>