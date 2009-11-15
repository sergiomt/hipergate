<%@ page import="com.knowgate.misc.Environment,java.util.Properties,java.util.Enumeration,java.io.File" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@include file="../methods/dbbind.jsp"%>
<%
  String sKey;
  String sVal;
  String sCNF;
  Enumeration e;
  
  sCNF = Environment.getEnvVar("KNOWGATE_PROFILES");
  if (sCNF.equals(""))
    sCNF = (System.getProperty("os.name").startsWith("Windows")) ? "C:\\WINNT\\" : "/etc/";
  if (sCNF.lastIndexOf(File.separator) < sCNF.length())
    sCNF += File.separator;
  sCNF += GlobalDBBind.getProfileName() + ".cnf";
%>

<HTML>
  <HEAD>
    <META http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <TITLE>hipergate :: Installation Info</TITLE>
    <STYLE type="text/css">
      DT { font-weight:bolder; }
      DD { font-family:'Courier New',Courier,monospaced; }
    </STYLE>
  </HEAD>
  <BODY>
    <H1>Basic Setup</H1>
    <UL>
      <LI>This file is located at <B><%=request.getRealPath(request.getServletPath())%></B></LI>
      <LI>GlobalDBBind is <%=((null==GlobalDBBind) ? "<B>not</B>" : "")%> correctly set. Using the <B><%=GlobalDBBind.getProfileName()%></B> DBBind profile</LI>
      <LI>The environment variable KNOWGATE_PROFILES is <%=((Environment.getEnvVar("KNOWGATE_PROFILES").equals("")) ? "not" : "")%> set</LI>
      <LI>Your configuration file is <B><%=sCNF%></B></LI>
      <LI>Your are running <B><%=application.getServerInfo()%> (<%=application.getMajorVersion()%>/<%=application.getMinorVersion()%>)</B></LI>
    </UL>

    <H1>Configuration File</H1>
    <DL>
<%
  Properties oEnvProps = Environment.getProfile(GlobalDBBind.getProfileName());
  for (e = oEnvProps.propertyNames(); e.hasMoreElements();) {
    sKey = e.nextElement().toString();
    sVal = oEnvProps.getProperty(sKey);
    sVal = ((null==sVal) ? "[<I>null</I>]" : (sVal.equals("") ? "[<I>empty</I>]" : sVal));
    out.write("      <DT>" + sKey + "</DT><DD>" + sVal + "</DD>\n");
  }
%>
    </DL>

    <H1>Servlet Context Attributes</H1>
    <DL>
<%
  for (e = application.getAttributeNames(); e.hasMoreElements();) {
    sKey = e.nextElement().toString();
    sVal = application.getAttribute(sKey).toString();
    sVal = ((null==sVal) ? "[<I>null</I>]" : (sVal.equals("") ? "[<I>empty</I>]" : sVal));
    out.write("      <DT>" + sKey + "</DT><DD>" + sVal + "</DD>\n");
  }
%>
    </DL>    

    <H1>Servlet Context Parameters</H1>
    <DL>
<%
  for (e = application.getInitParameterNames(); e.hasMoreElements();) {
    sKey = e.nextElement().toString();
    sVal = application.getInitParameter(sKey).toString();
    sVal = ((null==sVal) ? "[<I>null</I>]" : (sVal.equals("") ? "[<I>empty</I>]" : sVal));
    out.write("      <DT>" + sKey + "</DT><DD>" + sVal + "</DD>\n");
  }
%>
    </DL>    

    <H1>System Properties</H1>
    <DL>
<%
  Properties oSysProps = System.getProperties();
  for (e = oSysProps.propertyNames(); e.hasMoreElements();) {
    sKey = e.nextElement().toString();
    sVal = oSysProps.getProperty(sKey);
    sVal = ((null==sVal) ? "[<I>null</I>]" : (sVal.equals("") ? "[<I>empty</I>]" : sVal));
    out.write("      <DT>" + sKey + "</DT><DD>" + sVal + "</DD>\n");
  }
%>
    </DL>
  </BODY>
</HTML>