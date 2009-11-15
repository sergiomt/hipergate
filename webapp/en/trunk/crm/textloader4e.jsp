<%@ page import="java.io.IOException,java.io.File,java.net.URLDecoder,java.io.File,com.knowgate.dfs.FileSystem,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><% 
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String sWorkArea = request.getParameter("gu_workarea");
  String sFileName = request.getParameter("nm_file");
  String sFileType = request.getParameter("tp_file");

  FileSystem oFS = new FileSystem();

  String sTmpDir = Gadgets.chomp(Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir()),File.separator) + sWorkArea;

  File oTxt = new File(sTmpDir+File.separator+sFileType+"_"+sFileName);  
  String sTxt = "";

  if (oTxt.exists()) {  
    sTxt = oFS.readfilestr(sTmpDir+File.separator+sFileType+"_"+sFileName,System.getProperty("file.encoding"));
    oTxt.delete();
  }

  out.write(sTxt);
%>