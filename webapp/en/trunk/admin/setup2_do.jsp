<%@ page import="java.util.Properties,java.io.*,java.sql.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");

/*
  Copyright (C) 2004-2010  Know Gate S.L. All rights reserved.

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

String sError = "";

String sCnf = request.getParameter("cnf");

String sPath = Gadgets.chomp(Environment.getEnvVar("KNOWGATE_PROFILES"),java.io.File.separator)+sCnf+".cnf";

Properties oProfile = null;

String sDriver = "";
Class oDriver;
Connection oConn = null;

try {

  // **************************
  // Save hipergate.cnf changes
  
  oProfile = new Properties();
  
  FileInputStream oFileStream = new FileInputStream(sPath);
  
  oProfile.load(oFileStream);
  
  oProfile.setProperty("driver", request.getParameter("driver"));

  if (request.getParameter("driver").equals("org.postgresql.Driver"))  
    oProfile.setProperty("dburl", "jdbc:postgresql://" + request.getParameter("server") + ":" + request.getParameter("alt_port") + "/" + request.getParameter("database"));
  else if (request.getParameter("driver").equals("oracle.jdbc.driver.OracleDriver"))
    oProfile.setProperty("dburl", "jdbc:oracle:thin:@" + request.getParameter("server") + ":" + request.getParameter("alt_port") + ":" + request.getParameter("database"));
  else if (request.getParameter("driver").equals("com.microsoft.jdbc.sqlserver.SQLServerDriver"))
    oProfile.setProperty("dburl", "jdbc:microsoft:sqlserver://" + request.getParameter("server") + ":" + request.getParameter("alt_port") + ";SelectMethod=cursor;DatabaseName=" + request.getParameter("database"));
  else if (request.getParameter("driver").equals("com.microsoft.sqlserver.jdbc.SQLServerDriver"))
    oProfile.setProperty("dburl", "jdbc:sqlserver://" + request.getParameter("server") + ":" + request.getParameter("alt_port") + ";SelectMethod=cursor;DatabaseName=" + request.getParameter("database")); 
  else if (request.getParameter("driver").equals("com.mysql.jdbc.Driver"))
    oProfile.setProperty("dburl", "jdbc:mysql://" + request.getParameter("server") + "/" + request.getParameter("database"));
  else if (request.getParameter("driver").equals("com.ibm.db2.jcc.DB2Driver"))
    oProfile.setProperty("dburl", "jdbc:db2://" + request.getParameter("server") + ":" + request.getParameter("alt_port") + "/" + request.getParameter("database"));
  
  oProfile.setProperty("dbuser", request.getParameter("dbuser"));
  oProfile.setProperty("dbpassword", request.getParameter("dbpassword"));
  oProfile.setProperty("schema", request.getParameter("schema"));

  oProfile.setProperty("fileprotocol", "file://");
  oProfile.setProperty("fileserver", "localhost");

  oProfile.setProperty("temp", request.getParameter("temp"));
  oProfile.setProperty("storage", request.getParameter("storage"));
  oProfile.setProperty("maxfileupload", request.getParameter("maxfileupload"));

  oProfile.setProperty("workareasget", request.getParameter("workareasget"));
  oProfile.setProperty("workareasput", request.getParameter("workareasput"));

  oProfile.setProperty("webserver", request.getParameter("webserver"));
  oProfile.setProperty("imageserver", Gadgets.chomp(request.getParameter("webserver"),"/")+"images");

  oProfile.setProperty("mail.store.protocol", request.getParameter("store"));
  oProfile.setProperty("mail.transport.protocol", request.getParameter("transport"));
  oProfile.setProperty("mail.store.protocol", request.getParameter("store"));
  oProfile.setProperty("mail.incoming", request.getParameter("incoming"));
  oProfile.setProperty("mail.outgoing", request.getParameter("outgoing"));

  oProfile.setProperty("authmethod", request.getParameter("authmethod"));

  oProfile.setProperty("luceneindex", Gadgets.chomp(request.getParameter("storage"),File.separator)+"luceneindex");
  oProfile.setProperty("analyzer", "org.apache.lucene.analysis.WhitespaceAnalyzer");

  oProfile.setProperty("googlemapskey", request.getParameter("googlemapskey"));
  oProfile.setProperty("gdatasync", request.getParameter("gdatasync")==null ? "0" : request.getParameter("gdatasync"));

  oProfile.setProperty("yahoobosskey", request.getParameter("yahoobosskey"));

  oProfile.setProperty("backtypekey", request.getParameter("backtypekey"));

  oProfile.setProperty("face", "crm");
  oProfile.setProperty("skin", "xp");
  
  oFileStream.close();

  FileOutputStream oOutStream = new FileOutputStream(sPath, false);
  
  oProfile.store(oOutStream, "hipergate configuration file");
  
  oOutStream.close();

  Environment.refresh();
  
  // ***********************
  // Try database connection
      
    // Read driver property from hipergate.cnf.
    // is this file could not be found,
    // application will be unable to read parameters for database econnection
    
    sDriver = Environment.getProfileVar(sCnf, "driver");
  
    if (null==sDriver)
      throw new NullPointerException ("driver property not found at "+sCnf+".cnf");
    
    out.write ("<FONT CLASS=\"textplain\">");
    out.write("driver = " + sDriver + "<BR>");
    out.write ("</FONT>");
    out.flush();

    // Load JDBC driver class
    // This Java class must be at jour CLASSPATH
    // JDBC driver version must match your database server
    // check that the version supplied with product is compatible with your DBMS
      
    oDriver = Class.forName(sDriver);
    
    out.write ("<FONT CLASS=\"textplain\">");
    out.write("dburl = " + Environment.getProfileVar(sCnf, "dburl") + "<BR>");
    out.write("dbuser = " + Environment.getProfileVar(sCnf, "dbuser") + "<BR>");
    out.write("schema = " + Environment.getProfileVar(sCnf, "schema") + "<BR>");
    out.write ("</FONT>");
    out.flush();

    // Connect to database
      
    oConn = DriverManager.getConnection(Environment.getProfileVar(sCnf, "dburl"),
                                        Environment.getProfileVar(sCnf, "dbuser"),
                                        Environment.getProfileVar(sCnf, "dbpassword"));


    out.write ("<FONT CLASS=\"textplain\">");
    out.write ("JDBC connection successfully accomplished" + "<BR><BR>");    
    out.write ("</FONT>");
    out.flush();
 
    oConn.close();
    oConn = null;
    
    File oDir;
    
    oDir = new File (Environment.getProfileVar(sCnf, "storage"));
    
    if (!oDir.exists())
      sError = "Directory does not exist " + Gadgets.escapeChars(Environment.getProfileVar(sCnf, "storage"),"\\",'\\');

    oDir = new File (Environment.getProfileVar(sCnf, "workareasput"));
    
    if (!oDir.exists())
      sError = "Directory does not exist " + Gadgets.escapeChars(Environment.getProfileVar(sCnf, "workareasput"), "\\",'\\');

    oDir = new File (Environment.getProfileVar(sCnf, "temp"));
    
    if (!oDir.exists())
      sError = "Directory does not exist " + Gadgets.escapeChars(Environment.getProfileVar(sCnf, "temp"), "\\",'\\');
    
}
catch (IOException ioe) {
  sError = "IOException " + ioe.getMessage();
}
catch (NullPointerException npe) {
  sError = "NullPointerException " + npe;
}
catch (ClassNotFoundException cnf) {
  sError = "ClassNotFoundException " + Environment.getProfileVar(sCnf, "driver") + " " + cnf;
}
catch (UnsupportedOperationException uso) {
  if (null!=oConn) oConn.close();

  sError = "UnsupportedOperationException " + uso;
}
catch (SQLException sql) {
  if (null!=oConn) oConn.close();

  sError = "SQLException " + sql.getSQLState() + " " + sql.getMessage();
}
%>

<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    function setErrorLevel() {
      <%
	if (sError.length()>0)
	  out.write("alert (\"" + sError + "\");");
	else
	  out.write("window.parent.frames[0].document.location.href='setup3.jsp?cnf="+sCnf+"'; window.document.location.href='../common/blank.htm';");
      %>
    }
  //-->
  </SCRIPT>  
</HEAD>
<BODY  onload="setErrorLevel()">
<% if (sError.length()==0) { %>
<FONT FACE="Arial,Helvetica,sans-serif" COLOR="red" SIZE="2">
<B><%= "<BR><B>"+sCnf+".cnf sucessfully saved</B>" %></B>
</FONT>
<% } else { %>
<FONT FACE="Arial,Helvetica,sans-serif" COLOR="red" SIZE="2">
<B><%= "<BR><B>" + sError + "</B>" %></B>
</FONT>
<% } %>
</BODY>
</HTML>