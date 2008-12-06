<%@ page import="java.util.Date,java.util.Properties,java.io.IOException,java.io.File,java.io.FileWriter,java.io.FileInputStream,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %><% 
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  String sCnf = request.getParameter("cnf");
  if (null==sCnf) sCnf = "hipergate";
%><HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
  <!--
  
    function setCombos() {
      var frm = document.forms[0];
      var win = <%= System.getProperty("os.name").startsWith("Windows") ? "true" : "false" %>;
      
      setCombo (frm.cnf, "<%=sCnf%>");

      frm.driver.options.selectedIndex = (win ? 2 : 0);      
      frm.schema.value = (win ? "dbo" : "");
      frm.temp.options.selectedIndex = (win ? 2 : 0);
      frm.storage.value = (win ? "C:\hipergate\storage" : "/opt/hipergate/storage");
      frm.workareasput.value = (win ? "C:\hipergate\web\workareas" : "/opt/hipergate/web/workareas");
<%
      Properties oProfile = new Properties();
      String sCnfFilePath = Gadgets.chomp(Environment.getEnvVar("KNOWGATE_PROFILES"),java.io.File.separator)+sCnf+".cnf";

      try {
        File oFile = new File(sCnfFilePath);
        if (oFile.exists()) {
        
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
            out.write("      frm.workareasget.value=\"" + oProfile.getProperty("workareasget") + "\";\n");
  
          if (null!=oProfile.getProperty("workareasput"))
            out.write("      frm.workareasput.value=\"" + Gadgets.escapeChars(oProfile.getProperty("workareasput"),"\\",'\\') + "\";\n");
  
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
            out.write("      setCombo(frm.authmethod, \"" + oProfile.getProperty("authmethod") + "\");\n");

        } else {
          FileWriter oWrtr = new FileWriter(oFile);
          oWrtr.write("#hipergate configuration file\n");
          oWrtr.write("#"+new Date().toString()+"\n");
          
	} // fi (oFile.exists())
      }
      catch (IOException ioe) {
      }
%>
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
<TABLE WIDTH="98%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Setup Wizard : Step 2</FONT></TD></TR></TABLE> 
<BR>
<TABLE>
  <TR>
    <TD><IMG SRC="../images/images/setup/cnf.gif" WIDTH="54" HEIGHT="48" ALT="" BORDER="0"></TD>
    <TD VALIGN="middle"><FONT CLASS="textplain"><BIG>Configuration of .cnf file</BIG></TD>
  </TR>
</TABLE>
<BR>
<FORM ACTION="setup2_do.jsp" onsubmit="return validate()" TARGET="setupoutput">
  <TABLE SUMMARY="CNF Info" BORDER="0">
    <TR><TD CLASS="textplain">Current location</TD><TD CLASS="textstrong"><%=Gadgets.chomp(Environment.getEnvVar("KNOWGATE_PROFILES"),java.io.File.separator)+sCnf+".cnf"%></TD></TR>
    <TR><TD CLASS="textplain">Select another location</TD><TD><SELECT NAME="cnf" CLASS="combomini" onchange="document.location.href='setup2.jsp?cnf='+this.options[this.selectedIndex].value"><OPTION VALUE="hipergate">hipergate</OPTION><OPTION VALUE="devel">devel</OPTION><OPTION VALUE="test">test</OPTION><OPTION VALUE="work">work</OPTION><OPTION VALUE="demo">demo</OPTION><OPTION VALUE="portal">portal</OPTION><OPTION VALUE="web">web</OPTION><OPTION VALUE="intranet">intranet</OPTION><OPTION VALUE="extranet">extranet</OPTION><OPTION VALUE="crm">crm</OPTION><OPTION VALUE="support">support</OPTION></SELECT></TD></TR>
    <TR><TD CLASS="textsmall" COLSPAN="2">If another location is chosen, file /methods/DBBind.jsp must be modified</TD></TR>
  </TABLE>
  <TABLE>
    <TR><TD COLSPAN="6"><HR></TD></TR>     
    <TR>
      <TD COLSPAN="6">
        <TABLE>
          <TR>
            <TD><IMG SRC="../images/images/setup/database16.gif" ALT="" BORDER="0"></TD>
	    <TD>
              <FONT CLASS="formstrong">Database</FONT>
            </TD>
          </TR>
        </TABLE>
      </TD>
    </TR>
    <TR CLASS="strip1">
      <TD><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#driver" TITLE="What is this?">Driver</A></TD>
      <TD>  
        <SELECT NAME="driver" CLASS="combomini" onchange="if (document.forms[0].alt_port.value.length==0) document.forms[0].default_port.options.selectedIndex=this.options.selectedIndex+1;">
          <OPTION VALUE="org.postgresql.Driver">PostgreSQL 8.3</OPTION>
          <OPTION VALUE="com.mysql.jdbc.Driver">MySQL 5</OPTION>
          <OPTION VALUE="com.microsoft.sqlserver.jdbc.SQLServerDriver">SQL Server 2005</OPTION>
          <OPTION VALUE="oracle.jdbc.driver.OracleDriver">Oracle 10</OPTION>
          <!-- <OPTION VALUE="com.microsoft.jdbc.sqlserver.SQLServerDriver">SQL Server 2000</OPTION>-->
          <!-- <OPTION VALUE="com.ibm.db2.jcc.DB2Driver">DB 2</OPTION>-->
          <!-- <OPTION VALUE="org.apache.derby.jdbc.ClientDriver">Apache Derby</OPTION>-->
        </SELECT>
      </TD>
      <TD><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#dburl" TITLE="What is this?">Server</A></TD>
      <TD><INPUT TYPE="text" NAME="server" VALUE="127.0.0.1" SIZE="16" CLASS="combomini"></TD>
      <TD ALIGN="right"><A CLASS="linkplain" TARGET="_blank" HREF="http://www.hipergate.org/docs/install/#dburl" TITLE="What is this?">Port</A></TD>
      <TD>
        <SELECT NAME="default_port" CLASS="combomini"><OPTION VALUE="" SELECTED="selected"></OPTION><OPTION VALUE="">None (MySQL)</OPTION><OPTION VALUE="5432">5432 (PostgreSQL)</OPTION><OPTION VALUE="1433">1433 (SQL Server)</OPTION><OPTION VALUE="1521">1521 (Oracle)</OPTION><!--<OPTION VALUE="1527">1527 (DB2)</OPTION>--></SELECT>
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
        <INPUT TYPE="text" NAME="maxconnections" VALUE="100" SIZE="5" MAXLENGTH="3" CLASS="combomini" onkeypress="return acceptOnlyNumbers();">
      </TD>
    </TR>
    <TR>
    <TD COLSPAN="6">
      <INPUT TYPE="button" CLASS="minibutton" VALUE="Test Connection" onclick="testConnect()"></TD>
    </TR>    
    <TR><TD COLSPAN="6"><HR></TD></TR>
    <TR>
      <TD COLSPAN="6">
        <TABLE>
          <TR>
            <TD><IMG SRC="../images/images/setup/folders16.gif" ALT="" BORDER="0"></TD>
	    <TD><FONT CLASS="formstrong">Directories</FONT></TD>
	  </TR>
	</TABLE>
      </TD>
    </TR>
    <TR CLASS="strip2">
      <TD COLSPAN="3">
        <FONT CLASS="formplain">Temporary Directory</FONT>
        &nbsp;
        <SELECT NAME="temp" CLASS="combomini"><OPTION VALUE="/tmp">/tmp</OPTION><OPTION VALUE="C:\TEMP">C:\TEMP</OPTION><OPTION VALUE="C:\WINNT\Temp">C:\WINNT\Temp</OPTION><OPTION VALUE="C:\Windows\Temp">C:\Windows\Temp</OPTION>
      </TD>
      <TD COLSPAN="3">
        <FONT CLASS="formplain">Storage Directory</FONT>
	<INPUT TYPE="text" NAME="storage" SIZE="40" CLASS="combomini">
      </TD>
    </TR>
    <TR CLASS="strip1">
      <TD COLSPAN="3">
        <FONT CLASS="formplain">HTTP subdirectory of WorkAreas</FONT>
	<INPUT TYPE="text" NAME="workareasget" SIZE="15" CLASS="combomini" VALUE="/workareas">
      </TD>
      <TD COLSPAN="3">
        <FONT CLASS="formplain">Full path to WorkAreas</FONT>
	<INPUT TYPE="text" NAME="workareasput" SIZE="40" CLASS="combomini">
      </TD>
    </TR>
    <TR CLASS="strip2">
      <TD COLSPAN="3">
        <FONT CLASS="formplain">Web Server</FONT>
	<INPUT TYPE="text" NAME="webserver" SIZE="40" CLASS="combomini" VALUE="http://localhost:8080/<%=sCnf%>">
      </TD>
      <TD COLSPAN="3">
        <FONT CLASS="formplain">Max. File Size</FONT>
	      <SELECT NAME="maxfileupload" CLASS="combomini"><OPTION VALUE="1048576">1</OPTION><OPTION VALUE="2097152">2</OPTION><OPTION VALUE="5242880">5</OPTION><OPTION VALUE="10485760" SELECTED="selected">10</OPTION><OPTION VALUE="20971520">20</OPTION><OPTION VALUE="52428800">50</OPTION><OPTION VALUE="104857600">100</OPTION></SELECT><FONT CLASS="formplain">Mb</FONT>
      </TD>
    </TR>
    <TR><TD COLSPAN="6"><HR></TD></TR>     
    <TR>
      <TD COLSPAN="6">
        <TABLE>
          <TR>
            <TD><IMG SRC="../images/images/setup/mailbox16.gif" ALT="" BORDER="0"></TD>
	    <TD><FONT CLASS="formstrong">e-mail</FONT></TD>
	  </TR>
	</TABLE>
      </TD>
    </TR>
    <TR CLASS="strip2">
      <TD><FONT CLASS="formplain">Storage</FONT></TD>
      <TD><INPUT TYPE="text" NAME="store" VALUE="pop3" SIZE="5" CLASS="combomini" STYLE="text-transform:lowercase"></TD>    
      <TD><FONT CLASS="formplain">Transport</FONT></TD>
      <TD><INPUT TYPE="text" NAME="transport" VALUE="smtp" SIZE="5" CLASS="combomini" STYLE="text-transform:lowercase"></TD>    
      <TD ALIGN="right"><FONT CLASS="formplain">Incoming mail server</FONT></TD>
      <TD><INPUT TYPE="text" NAME="incoming" VALUE="pop3.server.com" SIZE="20" CLASS="combomini"></TD>    
    </TR>
    <TR CLASS="strip2">
      <TD COLSPAN="4"></TD>
      <TD ALIGN="right"><FONT CLASS="formplain">Outgoing mail server</FONT></TD>
      <TD><INPUT TYPE="text" NAME="outgoing" VALUE="smtp.server.com" SIZE="20" CLASS="combomini"></TD>    
    </TR>
    <TR><TD COLSPAN="6"><HR></TD></TR>     
    <TR>
      <TD COLSPAN="6">
        <TABLE>
          <TR>
            <TD><IMG SRC="../images/images/setup/authmethod20.gif" ALT="" WIDTH"=20" HEIGHT="20" BORDER="0"></TD>
	    <TD><FONT CLASS="formstrong">Authentication Method</FONT></TD>
	  </TR>
	</TABLE>
      </TD>
    </TR>
    <TR CLASS="strip2">
      <TD COLSPAN="6">
        <SELECT NAME="authmethod" CLASS="combomini">
          <OPTION VALUE="native" SELECTED="selected">Standard</OPTION>
          <OPTION VALUE="captcha">Captcha</OPTION>
          <OPTION VALUE="ntlm">NTLM</OPTION>
          <OPTION VALUE="ldap">LDAP</OPTION>
      </TD>
    </TR>
  </TABLE>
  <BR>
<INPUT TYPE="button" CLASS="pushbutton" VALUE="Previous" onclick="window.document.location.href='setup1.jsp';"> 
&nbsp;&nbsp;&nbsp;&nbsp;
<INPUT TYPE="submit" CLASS="pushbutton" VALUE="Next">
</FORM>
</BODY>
</HTML>