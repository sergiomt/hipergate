<%@ page import="java.sql.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.storage.Column" language="java" session="false" contentType="text/html;charset=UTF-8" %><%
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

  request.setCharacterEncoding("UTF-8");

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  Connection oConn = null;  
  Statement oStmt = null;
  ResultSet oRSet = null;
  ResultSetMetaData oMDat = null;
  StringBuffer oResults = new StringBuffer();
  
  int iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
  int iRow = 0;
  
  String sProfile = request.getParameter("profile");
  String sStatements = request.getParameter("sqlstatements");

  try {
    String sDrvCls = Environment.getProfileVar(sProfile, "driver");

    if (null==sDrvCls) throw new SQLException("Could not find property driver at "+sProfile+".cnf");
    if (sDrvCls.length()==0) throw new SQLException("Property driver at "+sProfile+".cnf is empty");

    Class oDriver = Class.forName(sDrvCls);
    
    oConn = DriverManager.getConnection(Environment.getProfileVar(sProfile, "dburl"), Environment.getProfileVar(sProfile, "dbuser"), Environment.getProfileVar(sProfile, "dbpassword"));

    oConn.setAutoCommit (true);
    
    oStmt = oConn.createStatement();
    
    String Statements[] = null;
    
    if (sStatements.length()>0) {
      if (request.getParameter("delimiter").length()==0)
        Statements = new String[]{sStatements};
      else
        if (request.getParameter("delimiter").length()==1)
          Statements = Gadgets.split(sStatements, request.getParameter("delimiter").charAt(0));
        else
          Statements = Gadgets.split(sStatements, request.getParameter("delimiter"));
    }

    oResults.append("<TABLE>");
    
    for (int s=0; s<Statements.length; s++) {
      if (Statements[s].trim().length()>0) {
        String UCaseStmt = Statements[s].trim().toUpperCase();
        
        if (UCaseStmt.startsWith("SELECT"))
          oRSet = oStmt.executeQuery(Statements[s]);
        else if (UCaseStmt.startsWith("INSERT") || UCaseStmt.startsWith("UPDATE"))
          iRow = oStmt.executeUpdate(Statements[s]);
        else if (UCaseStmt.startsWith("DESC")) {
          oRSet = oStmt.executeQuery("SELECT * FROM "+UCaseStmt.substring(5)+" WHERE 1=0");          
        } else {
          if (oDriver.getName().equals("oracle.jdbc.driver.OracleDriver")) {
            oStmt.execute(Gadgets.removeChar(Statements[s], (char)13));
            iRow = 0;
            if ((UCaseStmt.startsWith("ALTER") || UCaseStmt.startsWith("CREATE") || UCaseStmt.startsWith("REPLACE")) &&
                (UCaseStmt.indexOf("PROCEDURE")>0 || UCaseStmt.indexOf("TRIGGER")>0 || UCaseStmt.indexOf("FUNCTION")>0)) {
              String[] Tokens = Gadgets.split(UCaseStmt," ");
              int t = 0;
              while (Tokens[t].equals("ALTER") || Tokens[t].equals("CREATE") || Tokens[t].equals("OR") || Tokens[t].equals("REPLACE") || Tokens[t].equals("PROCEDURE") || Tokens[t].equals("FUNCTION") || Tokens[t].equals("TRIGGER")) t++;
              oRSet = oStmt.executeQuery("SELECT * FROM USER_ERRORS WHERE NAME='"+Tokens[t]+"' ORDER BY SEQUENCE");
            } // fi
          } else {
            oStmt.execute(Statements[s]);
            iRow = 0;
          }
        }
        
        if ((oRSet!=null) && (Statements.length==1)) {
          oMDat = oRSet.getMetaData();
          int iColCount = oMDat.getColumnCount();
          oResults.append("<TR>");
          for (int c=1; c<=iColCount; c++) {
            oResults.append("<TD CLASS=\"strip2\"><B>" + oMDat.getColumnName(c) + "</B></TD>");
          }
          oResults.append("</TR>");       
	
	        iRow = 0;
	        if (UCaseStmt.startsWith("DESC")) {
            for (int f=1; f<=iColCount; f++) {
              oResults.append("<TD CLASS=\"strip2\">"+Column.typeName(oMDat.getColumnType(f)));
              if (oMDat.getColumnType(f)==java.sql.Types.CHAR || oMDat.getColumnType(f)==java.sql.Types.VARCHAR)
                oResults.append("("+String.valueOf(oMDat.getPrecision(f))+")");
              oResults.append((oMDat.isNullable(f)==1 ? "" : " NOT")+" NULL</TD>");
	          }
	        } else {
	        	while (oRSet.next() && (iRow<iMaxRows)) {
              oResults.append("<TR>");
              for (int f=1; f<=iColCount; f++)
	              if (oMDat.getColumnType(f)!=java.sql.Types.LONGVARBINARY && oMDat.getColumnType(f)!=java.sql.Types.BLOB)
                  oResults.append("<TD CLASS=\"strip2\">"+oRSet.getObject(f)+"</TD>");
              oResults.append("</TR>");
	            iRow++;
	          }  // wend
          } // fi
        } // fi (oRSet!=null && Statements.length==1)
      
        if (oRSet!=null) oRSet.close(); 
        oRSet=null;
      } // fi (Statements[s]!="")      
    } // next

    oResults.append("</TABLE>");

    if (oStmt!=null) oStmt.close();
    
    oConn.close();
  }
  catch (SQLException e) {
    if (oRSet!=null) oRSet.close();
    if (oStmt!=null) oStmt.close();
       
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close();
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

%><HTML>
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY >
<BR>
<% out.write(oResults.toString()); %>
<BR>
<% out.write("<FONT CLASS=\"textplain\">" + String.valueOf(iRow) + " " + "affected rows</FONT>"); %>
</BODY>
</HTML>