<%@ page import="java.io.*,java.sql.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.datamodel.ModelManager" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><% 
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

String sCnf = request.getParameter("cnf");

String sError = "";

String sPath = Gadgets.chomp(Environment.getEnvVar("KNOWGATE_PROFILES"),java.io.File.separator)+sCnf+".cnf";

ModelManager oMan = new ModelManager();

try {
  oMan.connect(Environment.getProfileVar(sCnf, "driver"), Environment.getProfileVar(sCnf, "dburl"),
  	       Environment.getProfileVar(sCnf, "schema"),
  	       Environment.getProfileVar(sCnf, "dbuser"), Environment.getProfileVar(sCnf, "dbpassword"));

  if (null!=request.getParameter("dropall"))
    oMan.dropAll();
  else {
    if (request.getParameter("version").equals("0")) {    
      oMan.createDefaultDatabase();
    
       DBBind oBind = new DBBind(sCnf);

       DatabaseMetaData oMData;
       Statement oStmt;
       ResultSet oRSet;
       DBTable oTbl;
  
       String TableTypes[] = new String[1];
       TableTypes[0] = "TABLE";
       int iTableCount;
       
       JDCConnection oJCon = oBind.getConnection("test_connect");

       if (oJCon==null) {
         sError = "Impossible to get connection to database";
       }
       else {
    
        // Check that k_users table exists at database
    
        if (!DBBind.exists(oJCon, "k_users", "U"))
          throw new SQLException("Table k_users not found");
    
        oTbl = new DBTable(oJCon.getCatalog(), Environment.getProfileVar(sCnf, "schema"), "k_users", 1);

        oMData = oJCon.getMetaData();

        oTbl.readColumns(oJCon, oMData);
    
        // Check that the primary key for k_users can be correctly readed
    
        if (oTbl.getPrimaryKey().size()==0) {
          if (Environment.getProfileVar(sCnf, "schema", "").length()>0)
            { oJCon.close("test_connect");
              throw new SQLException("Primary key for " + Environment.getProfileVar(sCnf, "schema") + ".k_users not found"); }
          else
            { oJCon.close("test_connect");
              throw new SQLException("Primary key for k_users not found"); }
        }

    	oStmt = oJCon.createStatement();
    	oRSet = oStmt.executeQuery("SELECT nm_domain from k_domains WHERE nm_domain='TEST'");
    	boolean bTest = oRSet.next();
    	oRSet.close();
    	oStmt.close();
    	
        oJCon.close("test_connect");
        
        if (!bTest) throw new SQLException("TEST domain not found");
        
        oJCon = null;
      }
    }
    else {
      if (request.getParameter("version").startsWith("2")) {
        oMan.upgrade("210", "300", Environment.getProfile("sCnf"));
        oMan.upgrade("300", "400", Environment.getProfile("sCnf"));
        oMan.upgrade("400", "500", Environment.getProfile("sCnf"));
        oMan.upgrade("500", "550", Environment.getProfile("sCnf"));
      } else if (request.getParameter("version").startsWith("3")) {
        oMan.upgrade("300", "400", Environment.getProfile("sCnf"));
        oMan.upgrade("400", "500", Environment.getProfile("sCnf"));
        oMan.upgrade("500", "550", Environment.getProfile("sCnf"));
      } else if (request.getParameter("version").startsWith("4")) {
        oMan.upgrade("400", "500", Environment.getProfile("sCnf"));
        oMan.upgrade("500", "550", Environment.getProfile("sCnf"));
      } else if (request.getParameter("version").startsWith("5") && !request.getParameter("version").startsWith("55")) {
        oMan.upgrade("500", "550", Environment.getProfile("sCnf"));
      }      
    }
  }
}
catch (IOException ioe) {
  sError = "IOException " + ioe.getMessage();
}
catch (NullPointerException npe) {
  sError = "NullPointerException " + npe;
}
catch (SQLException sql) {
  sError = "SQLException " + sql.getSQLState() + " " + sql.getMessage();
}
try {
      File oLog = new File (Environment.getProfilePath(sCnf, "temp")+"modeltrc.txt");
      
      oLog.delete();

      FileWriter oLogWrt = new FileWriter(oLog, true);

      oLogWrt.write(oMan.report());

      oLogWrt.close();
}
catch (IOException ignore) { }

try {
  oMan.disconnect();
}
catch (SQLException ignore) { }

GlobalDBBind.restart();

%><HTML>
<HEAD>
	<TITLE>DONE</TITLE>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    function setErrorLevel() {
      <%
        if (sError.length()==0) {
          if (null!=request.getParameter("dropall")) {
            out.write("top.document.location.href=\"setup.htm\";");        
          }
          else {
            out.write("if (parent.frames[0].document.getElementById(\"registration\").style.visibility!=\"visible\") top.document.location.href=\"../login.html\";");        
          }
        }
      %>
    }
  //-->
  </SCRIPT>  
</HEAD>
<BODY  onload="setErrorLevel()">
<%=sError%>
<BR><BR>
</BODY>
</HTML>