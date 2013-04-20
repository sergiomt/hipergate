<%@ page contentType="image/jpeg" import="java.net.URLDecoder,java.io.IOException,java.io.OutputStream,java.io.File,java.io.FileInputStream,java.io.FileOutputStream" language="java" session="false" contentType="image/jpeg" %><%
String sServletPath = request.getRealPath(request.getServletPath());
sServletPath = sServletPath.substring(0,sServletPath.lastIndexOf(File.separator));
sServletPath = sServletPath.substring(0,sServletPath.lastIndexOf(File.separator));

File oImg = new File(sServletPath+File.separator+"images"+File.separator+"images"+File.separator+"login"+File.separator+"captchaerror.gif");
  
Long lImg = new Long (oImg.length());
byte aImg[] = new byte[lImg.intValue()];
    
FileInputStream oInStrm = new FileInputStream(oImg);
oInStrm.read(aImg);
oInStrm.close();

OutputStream oOut = response.getOutputStream();
oOut.write(aImg);

if (1==1) return;
%>