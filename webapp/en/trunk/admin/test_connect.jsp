<%@ page import="javax.servlet.http.HttpServletRequest,java.sql.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%!

  public static String getProp(HttpServletRequest oReq, String sConf, String sName) {
    String sProp = oReq.getParameter(sName);
    if (sProp==null) sProp = Environment.getProfileVar(sConf, sName);
    return sProp;
  }

  public static String getProp(HttpServletRequest oReq, String sConf, String sName, String sDefault) {
    String sProp = oReq.getParameter(sName);
    if (sProp==null) sProp = Environment.getProfileVar(sConf, sName, sDefault);
    return sProp;
  }
%><%
  /* hipergate Connection Test
  
     This page performs a variety of step by step database connection actions
     for verifying a correct connectivity to your DBMS
  */
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  
  String sCnf = request.getParameter("cnf");
  if (null==sCnf) sCnf = sCnf;

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML>
<HEAD>
  <TITLE>hipergate :: JDBC Connection test</TITLE>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">
  <META NAME="robots" CONTENT="noindex,nofollow">
</HEAD>
<BODY>
<%
  String sDriver = "";
  Class oDriver;
  Connection oConn = null;
  DatabaseMetaData oMData;
  ResultSet oRSet;
  DBTable oTbl;
  DBBind oBind = null;
  JDCConnection oJCon = null;
  
  String TableTypes[] = new String[1];
  int iTableCount;

  out.write("Begin hipergate Connection Test<BR><BR>");
  
  try {
    
    // Read driver property from hipergate.cnf.
    // is this file could not be found,
    // application will be unable to read parameters for database econnection
    
    sDriver = getProp(request, sCnf, "driver");
  
    if (null==sDriver)
      throw new NullPointerException ("driver property not found at "+sCnf+".cnf");
    
    out.write("driver = " + sDriver + "<BR>");

    // Load JDBC driver class
    // This Java class must be at jour CLASSPATH
    // JDBC driver version must match your database server
    // check that the version supplied with product is compatible with your DBMS
      
    oDriver = Class.forName(sDriver);
  
    out.write("dburl = " + getProp(request, sCnf, "dburl") + "<BR>");
    out.write("dbuser = " + getProp(request, sCnf, "dbuser") + "<BR>");
    out.write("schema = " + getProp(request, sCnf, "schema") + "<BR>");

    // Connect to database
      
    oConn = DriverManager.getConnection(getProp(request, sCnf, "dburl"),
                                        getProp(request, sCnf, "dbuser"),
                                        getProp(request, sCnf, "dbpassword"));


    out.write ("Direct JDBC connection was successfull" + "<BR>");

    oMData = oConn.getMetaData();
    
    out.write ("Database is " + oMData.getDatabaseProductName() + "<BR>");
    out.write ("Catalog is " + oConn.getCatalog() + "<BR>");
 
    TableTypes[0] = "TABLE";

    // Count tables
    // If no tables were found either thay have not been properly created
    // or there is a permissions problem over system internal catalog views
    
    if (oMData.getDatabaseProductName().equals("Oracle"))
      oRSet = oMData.getTables(oConn.getCatalog(), null, "%", TableTypes);  
    else
      oRSet = oMData.getTables(oConn.getCatalog(), getProp(request, sCnf, "schema"), "%", TableTypes);  
    
    iTableCount = 0;
    
    while (oRSet.next())
      iTableCount++;
    
    out.write (String.valueOf(iTableCount) + " tables found" + "<BR>");
    
    oRSet.close();

    oMData = null;

    oConn.close();
    oConn = null;
    
    oBind = new DBBind();

    out.write ("DBBind successfully created<BR>");
    
    oJCon = oBind.getConnection("test_connect");

    if (oJCon==null) {

      out.write ("Impossible to get database connection<BR>");
    
    }
    else {
      out.write ("DBBind.getConnection() was successfull<BR>");
    
      // Check that k_users table exists at database
    
      if (DBBind.exists(oJCon, "k_users", "U")) {

        out.write ("k_users table found<BR>");
    
        oTbl = new DBTable(oJCon.getCatalog(), getProp(request, sCnf, "schema"), "k_users", 1);

        oMData = oJCon.getMetaData();

        oTbl.readColumns(oJCon, oMData);

        out.write ("k_users has " + String.valueOf(oTbl.columnCount()) + " columns<BR>");
    
        // Check that the primary key for k_users can be correctly readed
    
        if (oTbl.getPrimaryKey().size()==0)
          if (getProp(request, sCnf, "schema", "").length()>0)
            throw new SQLException("Primary key for " + getProp(request, sCnf, "schema") + ".k_users not found");
          else
            throw new SQLException("Primary key for k_users not found");
      }
      oJCon.close("test_connect");
    }
    
    out.write ("<BR> Connection test finished " + "<BR>");

  }
  catch (NullPointerException npe) {
    out.write ("NullPointerException " + npe);
  }
  catch (ClassNotFoundException cnf) {
    out.write ("ClassNotFoundException " + sDriver + " " + cnf);
  }
  catch (UnsupportedOperationException uso) {
    if (null!=oConn) oConn.close();
    if (null!=oJCon) oJCon.close();

    out.write ("UnsupportedOperationException " + uso);
  }
  catch (SQLException sql) {
    if (null!=oConn) oConn.close();
    if (null!=oJCon) oJCon.close();

    out.write ("SQLException " + sql.getSQLState() + " " + sql.getMessage());
  }
%>
</BODY>
</HTML>