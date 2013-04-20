<%@ page import="java.util.Date,java.util.Properties,java.io.IOException,java.io.File,java.io.FileWriter,java.io.FileInputStream,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %><% 
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

  final String sSep = System.getProperty("file.separator");

  String sCnf = request.getParameter("cnf");
  if (null==sCnf) sCnf = "hipergate";

  String sUri = request.getRequestURI();

  String sDefWrkArGet = request.getRequestURI();
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet + "/workareas";

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

	String sWebServer = Gadgets.dechomp(request.getRequestURL().toString(), "/admin/setup2.jsp");

%><HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
  
    function setCombos() {
      var frm = document.forms[0];
      var win = <%= System.getProperty("os.name").startsWith("Windows") ? "true" : "false" %>;
      
      setCombo (frm.cnf, "<%=sCnf%>");

      frm.driver.options.selectedIndex = (win ? 2 : 0);      
      frm.schema.value = (win ? "dbo" : "");
      frm.temp.options.selectedIndex = (win ? 2 : 0);
<%
      Properties oProfile = new Properties();
      String sCnfFilePath = Gadgets.chomp(Environment.getEnvVar("KNOWGATE_PROFILES"),java.io.File.separator)+sCnf+".cnf";

      try {
        File oFile = new File(sCnfFilePath);
        if (oFile.exists()) {

          out.write("      // found properties file "+sCnfFilePath+"\n");
        
          FileInputStream oFileStream = new FileInputStream(oFile);
  
          oProfile.load(oFileStream);
        
          if (null!=oProfile.getProperty("driver")) {
            out.write("      setCombo(frm.driver, \"" + oProfile.getProperty("driver") + "\");\n");
          
            if (null!=oProfile.getProperty("dburl")) {
              int iSlash;
              int iBlash;
              if (oProfile.getProperty("driver").equals("org.postgresql.Driver") ||
                  oProfile.getProperty("driver").equals("com.mysql.jdbc.Driver") ||
                  oProfile.getProperty("driver").equals("com.ibm.db2.jcc.DB2Driver")) {
                iSlash = oProfile.getProperty("dburl").lastIndexOf("/");
                if (iSlash>0)
                  out.write("      frm.database.value=\"" + oProfile.getProperty("dburl").substring(iSlash+1).trim() + "\";\n");                
              } else if (oProfile.getProperty("driver").equals("oracle.jdbc.driver.OracleDriver")) {
                iSlash = oProfile.getProperty("dburl").lastIndexOf(":");
                if (iSlash>0)
                  out.write("      frm.database.value=\"" + oProfile.getProperty("dburl").substring(iSlash+1).trim() + "\";\n");            
              } else if (oProfile.getProperty("driver").equals("com.microsoft.jdbc.sqlserver.SQLServerDriver") ||
                         oProfile.getProperty("driver").equals("com.microsoft.sqlserver.jdbc.SQLServerDriver")) {
                iSlash = oProfile.getProperty("dburl").toLowerCase().indexOf("database=");
                if (iSlash>0) {
                  iBlash = oProfile.getProperty("dburl").indexOf(";", iSlash);
  		            if (iBlash>0)
                    out.write("      frm.database.value=\"" + oProfile.getProperty("dburl").substring(iSlash+1,iBlash).trim() + "\";\n");
                  else
                    out.write("      frm.database.value=\"" + oProfile.getProperty("dburl").substring(iSlash+1).trim() + "\";\n");
                } // fi (iSlash>0)            
              }
            } // fi (dburl)
          } // fi (driver)
          
          if (null!=oProfile.getProperty("schema"))
            out.write("      frm.schema.value=\"" + oProfile.getProperty("schema") + "\";\n");
  
          if (null!=oProfile.getProperty("dburl")) {
  	        String sServerIP = Gadgets.getFirstMatchSubStr(oProfile.getProperty("dburl"),"[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+");
            if (sServerIP!=null)   
              out.write("      frm.server.value=\"" + sServerIP + "\";\n");
  
  	        String sPortNum = Gadgets.getFirstMatchSubStr(oProfile.getProperty("dburl"),"[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+:[0-9]+.*");
            if (sPortNum!=null) {
              sPortNum = sPortNum.substring(sPortNum.indexOf(":")+1);
              int nPortLen = 0;
              for (int c=0; c<sPortNum.length(); c++) {
                if (sPortNum.charAt(c)>=(char)48 && sPortNum.charAt(c)<=(char)57)
                  nPortLen++;
                else
                  break;
              } // next (c)
              sPortNum = sPortNum.substring(0, nPortLen);
              out.write("      setCombo(frm.default_port, \"" + sPortNum + "\");\n");
              out.write("       if (frm.default_port.selectedIndex==0) { \n");
              out.write("         frm.alt_port.value = \""+sPortNum+"\"; }\n");
            } else {
  	          out.write("         frm.default_port.options.selectedIndex = (win ? 3 : 2);\n");        
            }
          } else {
  	        out.write("         frm.default_port.options.selectedIndex = (win ? 3 : 2);\n");
          }// fi (dburl)
          
          if (null!=oProfile.getProperty("dbuser"))
            out.write("      frm.dbuser.value=\"" + oProfile.getProperty("dbuser") + "\";\n");
  
          if (null!=oProfile.getProperty("dbpassword"))
            out.write("      frm.dbpassword.value=\"" + oProfile.getProperty("dbpassword") + "\";\n");
  
          if (null!=oProfile.getProperty("poolsize"))
            out.write("      frm.poolsize.value=\"" + oProfile.getProperty("poolsize") + "\";\n");
  
          if (null!=oProfile.getProperty("maxconnections"))
            out.write("      frm.maxconnections.value=\"" + oProfile.getProperty("maxconnections") + "\";\n");
  
          if (null!=oProfile.getProperty("workareasget"))
            out.write("      frm.workareasget.value=\"" + oProfile.getProperty("workareasget",sDefWrkArGet) + "\";\n");
  
  				out.write("      // sDefWrkArPut="+sDefWrkArPut+"\n");
  				out.write("      // oProfile.getProperty(workareasput="+oProfile.getProperty("workareasput")+"\n");
  				out.write("      // Gadgets.escapeChars(oProfile.getProperty(workareasput)="+Gadgets.escapeChars(oProfile.getProperty("workareasput"),"\\",'\\')+"\n");

  				out.write("      // oProfile.getProperty(storage="+oProfile.getProperty("storage")+"\n");
  				out.write("      // Gadgets.escapeChars(oProfile.getProperty(storage)="+Gadgets.escapeChars(oProfile.getProperty("storage"),"\\",'\\')+"\n");

          if (null!=oProfile.getProperty("workareasput"))
            out.write("      frm.workareasput.value=\"" + Gadgets.escapeChars(oProfile.getProperty("workareasput"),"\\",'\\') + "\"; // Use value from .cnf file\n");
  				else
            out.write("      frm.workareasput.value=\"" + Gadgets.escapeChars(sDefWrkArPut,"\\",'\\') + "\"; // Use default\n");

          if (null!=oProfile.getProperty("storage"))
            out.write("      frm.storage.value=\"" + Gadgets.escapeChars(oProfile.getProperty("storage"),"\\",'\\') + "\";\n");
  
          if (null!=oProfile.getProperty("temp"))
            out.write("      frm.temp.value=\"" + Gadgets.escapeChars(oProfile.getProperty("temp"),"\\",'\\') + "\";\n");
  
          if (null!=oProfile.getProperty("webserver"))
            out.write("      frm.webserver.value=\"" + oProfile.getProperty("webserver") + "\";\n");

          if (null!=oProfile.getProperty("maxfileupload"))
            out.write("      setCombo(frm.maxfileupload, \"" + oProfile.getProperty("maxfileupload") + "\");\n");

          if (null!=oProfile.getProperty("mail.store.protocol"))
            out.write("      frm.store.value=\"" + oProfile.getProperty("mail.store.protocol") + "\";\n");
  
          if (null!=oProfile.getProperty("mail.transport.protocol"))
            out.write("      frm.transport.value=\"" + oProfile.getProperty("mail.transport.protocol") + "\";\n");
  
          if (null!=oProfile.getProperty("mail.incoming"))
            out.write("      frm.incoming.value=\"" + oProfile.getProperty("mail.incoming") + "\";\n");
  
          if (null!=oProfile.getProperty("mail.outgoing"))
            out.write("      frm.outgoing.value=\"" + oProfile.getProperty("mail.outgoing") + "\";\n");

          if (null!=oProfile.getProperty("authmethod"))
            out.write("      setCombo(document.getElementById(\"authmethod\"), \"" + oProfile.getProperty("authmethod") + "\");\n");

          if (null!=oProfile.getProperty("googlemapskey"))
            out.write("      frm.googlemapskey.value=\"" + oProfile.getProperty("googlemapskey") + "\";\n");

          if (null!=oProfile.getProperty("yahoobosskey"))
            out.write("      frm.yahoobosskey.value=\"" + oProfile.getProperty("yahoobosskey") + "\";\n");

          if (null!=oProfile.getProperty("backtypekey"))
            out.write("      frm.backtypekey.value=\"" + oProfile.getProperty("backtypekey") + "\";\n");

        } else {
          FileWriter oWrtr = new FileWriter(oFile);
          oWrtr.write("#hipergate configuration file\n");
          oWrtr.write("#"+new Date().toString()+"\n");
          
	} // fi (oFile.exists())
      }
      catch (IOException ioe) {
      }
%>
      if (frm.storage.value.length==0) frm.storage.value = (win ? "C:\\ARCHIV~1\\Tomcat\\storage" : "/opt/hipergate/storage");
      if (frm.workareasput.value.length==0) frm.workareasput.value = (win ? "C:\\ARCHIV~1\\Tomcat\\webapps\\hipergate\\workareas" : "/opt/apache-tomcat/webapps/hipergate/workareas");
    }

    // ------------------------------------------------------------------------
    
    function testConnect() {
      var url;
      var frm = document.forms[0];
      var drv = frm.driver.value;
      var prt = frm.alt_port.value;

      if (prt.length==0) prt = getCombo(frm.default_port);

      if (drv=="org.postgresql.Driver")
        url = "jdbc:postgresql://" + frm.server.value + ":" + prt + "/" + frm.database.value;
      else if (drv=="oracle.jdbc.driver.OracleDriver")
        url = "jdbc:oracle:thin:@" + frm.server.value + ":" + prt + ":" + frm.database.value;
      else if (drv=="com.microsoft.jdbc.sqlserver.SQLServerDriver")
        url = "jdbc:microsoft:sqlserver://" + frm.server.value + ":" + prt + ";SelectMethod=cursor;DatabaseName=" + frm.database.value;
      else if (drv=="com.microsoft.sqlserver.jdbc.SQLServerDriver")
        url = "jdbc:sqlserver://" + frm.server.value + ":" + prt + ";SelectMethod=cursor;DatabaseName=" + frm.database.value;
      else if (drv=="com.mysql.jdbc.Driver")
        url = "jdbc:mysql://" + frm.server.value + "/" + frm.database.value;
      else if (drv=="com.ibm.db2.jcc.DB2Driver")
        url = "jdbc:db2://" + frm.server.value + ":" + prt + "/" + frm.database.value;
              
      window.open("test_connect.jsp?driver="+drv+"&dburl="+escape(url)+"&dbuser="+escape(frm.dbuser.value)+"&schema="+escape(frm.schema.value)+"&dbpassword="+escape(frm.dbpassword.value), "test_connect", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=500");
    }
    
    // ------------------------------------------------------------------------
    
    function adjustDefaultSettingForDriver() {
      var frm = document.forms[0];
      frm.default_port.options.selectedIndex=frm.driver.options.selectedIndex+1;
      if (frm.driver.options.selectedIndex==0) frm.schema.value="";
    }
    // ------------------------------------------------------------------------
    
    function validate() {
      var frm = document.forms[0];
      var driver = frm.driver[frm.driver.selectedIndex].value;
            
      if (frm.server.value.length==0) {
        alert ("The name or IP address of the database server is requiered");
        return false;
      }

      if ((frm.default_port.options.selectedIndex==0) && (frm.alt_port.value.length==0) && driver.driver.selectedIndex!=1) {
        alert ("The port of the database server is requiered");
        return false;
      }

      if (frm.default_port.options.selectedIndex>0 && frm.alt_port.value.length==0) {
        frm.alt_port.value = frm.default_port.options[frm.default_port.options.selectedIndex].value;
      }
      
      if (frm.dbuser.value.length==0) {
        alert ("The name of the database user is requiered");
        return false;
      }

      if ((frm.schema.value.length>0) && (driver=="org.postgresql.Driver")) {
        alert ("Schema must be empty for PostgreSQL");
        return false;
      }

      if ((frm.schema.value.length==0) && ((driver=="com.microsoft.sqlserver.jdbc.SQLServerDriver") || (driver=="oracle.jdbc.driver.OracleDriver"))) {
        alert ("Schema is requiered for Oracle and SQL Server");
        return false;
      }

      if (frm.database.value.length==0) {
        alert ("The database name is requiered");
        return false;
      }
      
      frm.store.value = frm.store.value.toLowerCase();
      frm.transport.value = frm.transport.value.toLowerCase();

    }
  //-->
  </SCRIPT>    
</HEAD>
<BODY  onload="setCombos()">
<TABLE WIDTH="98%" SUMMARY="Title"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Setup Wizard</FONT></TD></TR></TABLE> 
<FORM ACTION="setup2_do.jsp" onsubmit="return validate()" TARGET="setupoutput">
  <INPUT TYPE="hidden" NAME="workareasget" VALUE="<%=sDefWrkArGet%>">
	<INPUT TYPE="hidden" NAME="workareasput" VALUE="<%=Gadgets.escapeChars(sDefWrkArPut,"\\",'\\')%>">
  <FIELDSET>
  <LEGEND CLASS="formstrong">Required Parameters</LEGEND>
  <TABLE SUMMARY="Required Parameters">
    <TR>
      <TD COLSPAN="6">
        <TABLE SUMMARY="Database Title">
          <TR>
            <TD><IMG SRC="../images/images/setup/database16.gif" ALT="Database" BORDER="0" WIDTH="20" HEIGHT="24"></TD>
	          <TD CLASS="textstrong">Database</TD>
          </TR>
        </TABLE>
      </TD>
    </TR>
    <TR CLASS="strip1">
      <TD><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#driver" TITLE="What is this?">Driver</A></TD>
      <TD>  
        <SELECT NAME="driver" CLASS="combomini" onchange="adjustDefaultSettingForDriver()">
          <OPTION VALUE="org.postgresql.Driver">PostgreSQL 9</OPTION>
          <OPTION VALUE="com.mysql.jdbc.Driver">MySQL 5</OPTION>
          <OPTION VALUE="com.microsoft.sqlserver.jdbc.SQLServerDriver">SQL Server 2012</OPTION>
          <OPTION VALUE="oracle.jdbc.driver.OracleDriver">Oracle 11</OPTION>
          <!-- <OPTION VALUE="com.microsoft.jdbc.sqlserver.SQLServerDriver">SQL Server 2000</OPTION>-->
          <!-- <OPTION VALUE="com.ibm.db2.jcc.DB2Driver">DB 2</OPTION>-->
          <!-- <OPTION VALUE="org.apache.derby.jdbc.ClientDriver">Apache Derby</OPTION>-->
        </SELECT>
      </TD>
      <TD><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#dburl" TITLE="What is this?">Server</A></TD>
      <TD><INPUT TYPE="text" NAME="server" VALUE="127.0.0.1" SIZE="16" CLASS="combomini"></TD>
      <TD ALIGN="right"><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#dburl" TITLE="What is this?">Port</A></TD>
      <TD>
        <SELECT NAME="default_port" CLASS="combomini">
        	  <OPTION VALUE="" SELECTED="selected"></OPTION>
        	  <OPTION VALUE="5432">5432 (PostgreSQL)</OPTION>
        	  <OPTION VALUE="3306">3306 (MySQL)</OPTION>
        	  <OPTION VALUE="1433">1433 (SQL Server)</OPTION>
        	  <OPTION VALUE="1521">1521 (Oracle)</OPTION>
        	  <!--<OPTION VALUE="1527">1527 (DB2)</OPTION>-->
        	</SELECT>
        <INPUT TYPE="text" NAME="alt_port" MAXLENGTH="5" SIZE="5" CLASS="combomini" onchange="document.forms[0].default_port.options.selectedIndex=0;" onkeypress="return acceptOnlyNumbers();">
      </TD>
    </TR>
    <TR CLASS="strip2">
      <TD><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#dbuser" TITLE="What is this?">User</A></TD>
      <TD><INPUT TYPE="text" NAME="dbuser" VALUE="" SIZE="14" CLASS="combomini"></TD>    
      <TD><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#dbuser" TITLE="What is this?">Password</A></TD>
      <TD><INPUT TYPE="text" NAME="dbpassword" VALUE="" SIZE="14" CLASS="combomini"></TD>    
      <TD ALIGN="right"><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#schema" TITLE="What is this?">Schema</A></TD>
      <TD><INPUT TYPE="text" NAME="schema" VALUE="" SIZE="12" CLASS="combomini"></TD>    
    </TR>
    <TR CLASS="strip1">
      <TD><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#dburl" TITLE="What is this?">Database</A></TD>
      <TD><INPUT TYPE="text" NAME="database" VALUE="" SIZE="10" CLASS="combomini"></TD>    
      <TD COLSPAN="2">
        <FONT CLASS="formplain">Pooled connections</FONT>
        <INPUT TYPE="text" NAME="poolsize" VALUE="30" SIZE="5" MAXLENGTH="3" CLASS="combomini" onkeypress="return acceptOnlyNumbers();">
      </TD>
      <TD COLSPAN="2">
        <FONT CLASS="formplain">Maximum connections</FONT>
        <INPUT TYPE="text" NAME="maxconnections" VALUE="100" SIZE="5" MAXLENGTH="3" CLASS="combomini" onkeypress="return acceptOnlyNumbers();">&nbsp;&nbsp;<INPUT TYPE="button" CLASS="minibutton" VALUE="Test Connection" onclick="testConnect()">
      </TD>
    </TR>
    <TR>
      <TD COLSPAN="6">
        <TABLE>
          <TR>
            <TD><IMG SRC="../images/images/setup/folders16.gif" ALT="" BORDER="0" WIDTH="20" HEIGHT="24"></TD>
	    <TD><FONT CLASS="textstrong">Directories</FONT></TD>
	  </TR>
	</TABLE>
      </TD>
    </TR>
    <TR CLASS="strip2">
      <TD COLSPAN="3">
        <A HREF="http://www.hipergate.org/docs/install/#temp" TARGET="_blank" CLASS="linkplain">Temporary Directory</A>
        &nbsp;
        <SELECT NAME="temp" CLASS="combomini"><OPTION VALUE="/tmp">/tmp</OPTION><OPTION VALUE="C:\TEMP">C:\TEMP</OPTION><OPTION VALUE="C:\WINNT\Temp">C:\WINNT\Temp</OPTION><OPTION VALUE="C:\Windows\Temp">C:\Windows\Temp</OPTION></SELECT>
      </TD>
      <TD COLSPAN="3">
        <A HREF="http://www.hipergate.org/docs/install/#storage" CLASS="linkplain" TARGET="_blank">Storage Directory</A>
	      <INPUT TYPE="text" NAME="storage" SIZE="50" CLASS="combomini">
      </TD>
    </TR>
    <TR CLASS="strip2">
      <TD COLSPAN="3">
        <A HREF="http://www.hipergate.org/docs/install/#webserver" TARGET="_blank" CLASS="linkplain">WebApp</A>
	      <INPUT TYPE="text" NAME="webserver" SIZE="40" CLASS="combomini" VALUE="<%=sWebServer%>">
      </TD>
      <TD COLSPAN="3">
        <FONT CLASS="formplain">Max. File Size</FONT>
	      <SELECT NAME="maxfileupload" CLASS="combomini"><OPTION VALUE="1048576">1</OPTION><OPTION VALUE="2097152">2</OPTION><OPTION VALUE="5242880">5</OPTION><OPTION VALUE="10485760" SELECTED="selected">10</OPTION><OPTION VALUE="20971520">20</OPTION><OPTION VALUE="52428800">50</OPTION><OPTION VALUE="104857600">100</OPTION></SELECT><FONT CLASS="formplain">Mb</FONT>
      </TD>
    </TR>
    <TR>
      <TD COLSPAN="6">
        <TABLE>
          <TR>
            <TD><IMG SRC="../images/images/setup/mailbox16.gif" WITH="27" HEIGHT="18" ALT="Mail" BORDER="0"></TD>
	    <TD><FONT CLASS="textstrong">e-mail</FONT></TD>
	  </TR>
	</TABLE>
      </TD>
    </TR>
    <TR CLASS="strip2">
      <TD><FONT CLASS="formplain">Storage</FONT></TD>
      <TD><INPUT TYPE="text" NAME="store" VALUE="pop3" SIZE="5" CLASS="combomini" STYLE="text-transform:lowercase"></TD>    
      <TD><FONT CLASS="formplain">Transport</FONT></TD>
      <TD><INPUT TYPE="text" NAME="transport" VALUE="smtp" SIZE="5" CLASS="combomini" STYLE="text-transform:lowercase"></TD>    
      <TD ALIGN="right" CLASS="formplain">Incoming mail server</TD>
      <TD><INPUT TYPE="text" NAME="incoming" VALUE="pop3.server.com" SIZE="20" CLASS="combomini"></TD>    
    </TR>
    <TR CLASS="strip2">
      <TD COLSPAN="4"></TD>
      <TD ALIGN="right" CLASS="formplain">Outgoing mail server</TD>
      <TD><INPUT TYPE="text" NAME="outgoing" VALUE="smtp.server.com" SIZE="20" CLASS="combomini"></TD>    
    </TR>
  </TABLE>
</FIELDSET>

<FIELDSET>
  <LEGEND CLASS="formstrong">Optional Parameters</LEGEND>

<TABLE SUMMARY="Google">
  <TR>
    <TD><IMG SRC="../images/images/setup/google16.gif" ALT="Google" WIDTH="16" HEIGHT="16" HSPACE="2" BORDER="0"></TD>
		<TD><A HREF="#" CLASS="linknodecor" STYLE="border-bottom:1px dotted" onclick="document.getElementById('google').style.display=(document.getElementById('google').style.display=='block' ? 'none' : 'block')">Google</A></TD>
	</TR>
</TABLE>
<DIV ID="google" STYLE="display:none">
  <TABLE SUMMARY="Google Keys">
    <TR CLASS="strip2">
      <TD CLASS="formplain">Google Maps Key</TD><TD><INPUT TYPE="text" NAME="googlemapskey" VALUE="" SIZE="120" CLASS="combomini"></TD>
    </TR>
    <TR CLASS="strip2">
      <TD></TD><TD><A HREF="http://code.google.com/intl/en/apis/maps/signup.html" CLASS="linksmall" TARGET="_blank">Get a keyf or Google Maps</A></TD>
    </TR>  
    <TR CLASS="strip2">
      <TD CLASS="formplain"><INPUT NAME="gdatasync" TYPE="checkbox" VALUE="1"></TD><TD>Enable synchronization with Google Calendar</TD>
    </TR>
  </TABLE>
</DIV>
<TABLE SUMMARY="Yahoo!">
  <TR>
    <TD><IMG SRC="../images/images/setup/yahoo16.gif" ALT="Yahoo!" WIDTH="22" HEIGHT="22" HSPACE="2" BORDER="0"></TD>
		<TD><A HREF="#" CLASS="linknodecor" STYLE="border-bottom:1px dotted" onclick="document.getElementById('yahoo').style.display=(document.getElementById('yahoo').style.display=='block' ? 'none' : 'block')">Yahoo!</A></TD>
	</TR>
</TABLE>
<DIV ID="yahoo" STYLE="display:none">
<TABLE SUMMARY="Yahoo Search BOSS Key">
    <TR CLASS="strip2">
      <TD CLASS="formplain">Yahoo! Search BOSS Key</TD><TD><INPUT TYPE="text" NAME="yahoobosskey" VALUE="" SIZE="120" CLASS="combomini"></TD>
    </TR>
    <TR CLASS="strip2">
      <TD></TD><TD><A HREF="https://developer.apps.yahoo.com/wsregapp/" CLASS="linksmall" TARGET="_blank">get a key for Yahoo! Search BOSS</A></TD>
    </TR>
</TABLE>
</DIV>
<TABLE SUMMARY="BackType">
  <TR>
    <TD><IMG SRC="../images/images/setup/twitter20.gif" ALT="BackType" WIDTH="20" HEIGHT="20" HSPACE="2" BORDER="0"></TD>
		<TD><A HREF="#" CLASS="linknodecor" STYLE="border-bottom:1px dotted" onclick="document.getElementById('backtype').style.display=(document.getElementById('backtype').style.display=='block' ? 'none' : 'block')">BackType</A></TD>
	</TR>
</TABLE>
<DIV ID="backtype" STYLE="display:none">
<TABLE SUMMARY="BackType Key">
    <TR CLASS="strip2">
      <TD CLASS="formplain">BackType key</TD><TD><INPUT TYPE="text" NAME="backtypekey" VALUE="" SIZE="40" CLASS="combomini"></TD>
    </TR>
    <TR CLASS="strip2">
      <TD></TD><TD><A HREF="http://www.backtype.com/developers" CLASS="linksmall" TARGET="_blank">Get a new key for BackType</A></TD>
    </TR>
</TABLE>
</DIV>
<TABLE SUMMARY="Auth method">
  <TR>
    <TD><IMG SRC="../images/images/setup/authmethod20.gif" ALT="Key" WIDTH="20" HEIGHT="24" BORDER="0"></TD>
		<TD><A HREF="#" CLASS="linknodecor" STYLE="border-bottom:1px dotted" onclick="document.getElementById('auth').style.display=(document.getElementById('auth').style.display=='block' ? 'none' : 'block');document.getElementById('authmethod').style.visibility=(document.getElementById('authmethod').style.visibility=='visible' ? 'hidden' : 'visible');">Authentication Method</A></TD>
	</TR>
</TABLE>
<DIV ID="auth" STYLE="display:none">
  <TABLE SUMMARY="Auth Options">
	  <TR>
      <TD CLASS="strip2">
        <SELECT ID="authmethod" NAME="authmethod" CLASS="combomini" STYLE=""display:hidden">
          <OPTION VALUE="native" SELECTED="selected">Standard</OPTION>
          <OPTION VALUE="captcha">Captcha</OPTION>
          <OPTION VALUE="ntlm">NTLM</OPTION>
          <OPTION VALUE="ldap">LDAP</OPTION>
      </TD>
    </TR>
  </TABLE>
</DIV>
<TABLE >
	<TR>
    <TD><IMG SRC="../images/images/setup/computers.gif" ALT="Computers" WIDTH="20" HEIGHT="22" BORDER="0"></TD>
		<TD><A HREF="#" CLASS="linknodecor" STYLE="border-bottom:1px dotted" onclick="document.getElementById('multi').style.display=(document.getElementById('multi').style.display=='block' ? 'none' : 'block'); document.getElementById('cnf').style.visibility=(document.getElementById('cnf').style.visibility=='visible' ? 'hidden' : 'visible');">Multiple instances configuration</A></TD>
  </TR>
</TABLE>
<DIV ID="multi" STYLE="display:none">
  <TABLE SUMMARY="CNF Info" BORDER="0">
    <TR><TD CLASS="textplain">Current location</TD><TD CLASS="textstrong"><%=Gadgets.chomp(Environment.getEnvVar("KNOWGATE_PROFILES"),java.io.File.separator)+sCnf+".cnf"%></TD></TR>
    <TR><TD CLASS="textplain">Select another location</TD><TD><SELECT ID="cnf" NAME="cnf" CLASS="combomini" onchange="document.location.href='setup2.jsp?cnf='+this.options[this.selectedIndex].value"><OPTION VALUE="hipergate">hipergate</OPTION><OPTION VALUE="devel">devel</OPTION><OPTION VALUE="test">test</OPTION><OPTION VALUE="work">work</OPTION><OPTION VALUE="demo">demo</OPTION><OPTION VALUE="portal">portal</OPTION><OPTION VALUE="web">web</OPTION><OPTION VALUE="intranet">intranet</OPTION><OPTION VALUE="extranet">extranet</OPTION><OPTION VALUE="crm">crm</OPTION><OPTION VALUE="support">support</OPTION></SELECT></TD></TR>
    <TR><TD CLASS="textsmall" COLSPAN="2">If another location is chosen, file /methods/DBBind.jsp must be modified</TD></TR>
  </TABLE>
</DIV>
</FIELDSET>
<BR/>
<INPUT TYPE="submit" CLASS="pushbutton" VALUE="Next">
</FORM>
</BODY>
</HTML>