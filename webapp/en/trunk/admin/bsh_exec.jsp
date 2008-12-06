<%@ page import="com.knowgate.debug.DebugFile,java.util.Properties,java.util.Enumeration,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.beanservices.JInterpreterFactory,com.knowgate.beanservices.JInterpreterLocal,com.knowgate.beanservices.JInterpreterException,com.knowgate.misc.Environment,java.io.File,java.io.FileInputStream" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/propertiesreqload.jspf" %>
<%
  if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 0");
    
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 1");
       
  String id_user = getCookie (request, "userid", null);
  
  String sScript = request.getParameter("tx_script");
  String sNameScript = request.getParameter("sel_script");
    
  File oSource;
  FileInputStream oStream;
  byte byBuffer[];
  String sSource = null;

  Object oRetVal;
  JInterpreterLocal oIntr = null;

  if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 2");

  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");  	

  Properties oEnvProps = Environment.getProfile("appserver");
  String s3Tiers = oEnvProps.getProperty("threetiers", "disabled");
  boolean b3Tiers = s3Tiers.equalsIgnoreCase("enabled") || s3Tiers.equalsIgnoreCase("yes") || s3Tiers.equalsIgnoreCase("true") || s3Tiers.equalsIgnoreCase("on") || s3Tiers.equals("1");

  // [~//Carga los parámetros de la url en oParams para su posterior fusión con el script~]

  Properties oParams = new Properties();
  loadRequest(request, oParams); 

  if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 3");
  
  // [~//para habilitar el paso del nombre del archivo java que tiene que cargar~]
  if (sScript.length() == 0) {

    if (DebugFile.trace) {
      DebugFile.writeln("bsh_exec checkpoint 4");
      DebugFile.writeln("filename=" + sStorage + "/scripts/" + sNameScript);
    }
    	
    oSource = new File(sStorage + "/scripts/" + sNameScript);
    
    byBuffer = new byte[new Long(oSource.length()).intValue()];

    if (DebugFile.trace) DebugFile.writeln("filelen=" + new Long(oSource.length()).toString());

    oStream = new FileInputStream(oSource);
    oStream.read(byBuffer);
    oStream.close();
    oStream = null;
    
    sSource = new String(byBuffer);
    byBuffer = null;
    oSource = null;
  
    sScript = sSource;
  } // fi ()

  if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 5");
            
  try {
    if (b3Tiers) {
      if (DebugFile.trace) DebugFile.writeln("bsh_exec 3 tier mode");

      oIntr = JInterpreterFactory.createInterpreter(oEnvProps);
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("bsh_exec 2 tier mode");

      oIntr = JInterpreterFactory.createInterpreter(GlobalDBBind);
    }

    if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 6");

    oIntr.connect("DefaultConnection");  
    oIntr.connect("AlternativeConnection");

    if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 7");
    
    oRetVal = oIntr.eval(sScript, oParams);

    if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 8");

    oIntr.commit("AlternativeConnection");
    oIntr.commit("DefaultConnection");        
  }
  catch (JInterpreterException e) {
    oRetVal = e.getMessage();
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error BSF&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  finally {
    if (null!=oIntr) {
      oIntr.disconnect("AlternativeConnection");
      oIntr.disconnect("DefaultConnection");
      oIntr = null;
    }
  }    
  
  //oRetVal = "5";
%>
<HTML>
  <HEAD>
  <TITLE>hipergate :: Script result</TITLE>
  </HEAD>
  <BODY>
    Script successfully executed
    <BR>
    Return value: <%=oRetVal%>
    <BR>
    <A HREF="#" onClick="window.history.back()">Return</A>
  </BODY>
</HTML>