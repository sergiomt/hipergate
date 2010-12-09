&lt;%@ page import="com.mysql.jdbc.Driver,javax.naming.NamingException,javax.naming.Context,javax.naming.InitialContext,javax.sql.DataSource,javax.servlet.http.HttpServletRequest,java.sql.*,com.knowgate.debug.StackTraceUtil,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.workareas.WorkArea,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %&gt;&lt;%!

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
%&gt;&lt;%
  /* hipergate Connection Test
  
     This page performs a variety of step by step database connection actions
     for verifying a correct connectivity to your DBMS
  */
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  
  String sCnf = request.getParameter("cnf");
  if (null==sCnf) sCnf = "hipergate";

%&gt;&lt;!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"&gt;
&lt;HTML&gt;
&lt;HEAD&gt;
  &lt;TITLE&gt;hipergate :: JDBC Connection test&lt;/TITLE&gt;
  &lt;META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8"&gt;
  &lt;META NAME="robots" CONTENT="noindex,nofollow"&gt;
  &lt;LINK REL="stylesheet" TYPE="text/css" HREF="../skins/xp/styles.css"&gt;
&lt;/HEAD&gt;
&lt;BODY CLASS="textplain"&gt;
&lt;%
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

  out.write("&lt;B&gt;Begin hipergate Connection Test&lt;/B&gt;&lt;BR&gt;&lt;BR&gt;");
  
  try {
    
    // Read driver property from hipergate.cnf.
    // is this file could not be found,
    // application will be unable to read parameters for database econnection
    
    sDriver = getProp(request, sCnf, "driver");
  
    if (null==sDriver)
      throw new NullPointerException ("driver property not found at "+sCnf+".cnf");
    
    out.write("driver = " + sDriver + "&lt;BR&gt;");

    // Load JDBC driver class
    // This Java class must be at jour CLASSPATH
    // JDBC driver version must match your database server
    // check that the version supplied with product is compatible with your DBMS
      
    oDriver = Class.forName(sDriver);
  
    out.write("dburl = " + getProp(request, sCnf, "dburl") + "&lt;BR&gt;");
    out.write("dbuser = " + getProp(request, sCnf, "dbuser") + "&lt;BR&gt;");
    out.write("schema = " + getProp(request, sCnf, "schema") + "&lt;BR&gt;");

    // Connect to database
      
    oConn = DriverManager.getConnection(getProp(request, sCnf, "dburl"),
                                        getProp(request, sCnf, "dbuser"),
                                        getProp(request, sCnf, "dbpassword"));


    out.write ("Direct JDBC connection was successfull" + "&lt;BR&gt;");

    oMData = oConn.getMetaData();
    
    out.write ("Database is " + oMData.getDatabaseProductName() + "&lt;BR&gt;");
    out.write ("Catalog is " + oConn.getCatalog() + "&lt;BR&gt;");
 
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
    
    out.write (String.valueOf(iTableCount) + " tables found" + "&lt;BR&gt;");
    
    oRSet.close();

    oMData = null;

    oConn.close();
    oConn = null;
    
    oBind = new DBBind(sCnf);

    out.write ("DBBind successfully created&lt;BR&gt;");
    
    oJCon = oBind.getConnection("test_connect");

    if (oJCon==null) {

      out.write ("Impossible to get database connection&lt;BR&gt;");
    
    }
    else {
      out.write ("DBBind.getConnection() was successfull&lt;BR&gt;");
    
      // Check that k_users table exists at database
    
      if (DBBind.exists(oJCon, "k_users", "U")) {

        out.write ("k_users table found&lt;BR&gt;");
    
        oTbl = new DBTable(oJCon.getCatalog(), getProp(request, sCnf, "schema"), "k_users", 1);

        oMData = oJCon.getMetaData();

        oTbl.readColumns(oJCon, oMData);

        out.write ("k_users has " + String.valueOf(oTbl.columnCount()) + " columns&lt;BR&gt;");
    
        // Check that the primary key for k_users can be correctly readed
    
        if (oTbl.getPrimaryKey().size()==0)
          if (getProp(request, sCnf, "schema", "").length()&gt;0)
            throw new SQLException("Primary key for " + getProp(request, sCnf, "schema") + ".k_users not found");
          else
            throw new SQLException("Primary key for k_users not found");
      }

      CallableStatement oCall = oJCon.prepareCall("{ call k_get_user_from_email (?,?)}");
      oCall.setString(1, "administrator@hipergate-test.com");
      oCall.registerOutParameter(2, java.sql.Types.CHAR);
      oCall.execute();
      String sUid = oCall.getString(2);
      oCall.close();

      out.write ("Call to k_get_user_from_email was successfull&lt;BR&gt;");

			sUid = ACLUser.getIdFromEmail(oJCon, "administrator@hipergate-test.com");
      if (sUid==null)
        out.write ("Test account administrator@hipergate-test.com not found at k_users table&lt;BR&gt;");
      else
        out.write ("Test account administrator@hipergate-test.com correctly found at k_users table&lt;BR&gt;");

			ACLUser oUsr = new ACLUser(oJCon, sUid);
			ACLDomain oUdo = new ACLDomain(oJCon, oUsr.getInt(DB.id_domain));
			WorkArea oWrk = new WorkArea(oJCon, oUsr.getString(DB.gu_workarea));
			ACL.autenticate(oJCon, sUid, "TEST", ACL.PWD_CLEAR_TEXT);
			WorkArea.getUserAppMask(oJCon, oUsr.getString(DB.gu_workarea), sUid);
			oUsr.isDomainAdmin(oJCon);
						
      oJCon.close("test_connect");
    }
	  oBind.close();
	
    out.write ("&lt;BR&gt; &lt;B&gt;Connection test finished&lt;/B&gt; " + "&lt;BR&gt;");

  }
  catch (NullPointerException npe) {
    out.write ("NullPointerException " + npe+"&lt;BR&gt;"+Gadgets.replace(StackTraceUtil.getStackTrace(npe),"\n","&lt;BR&gt;"));
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

    out.write ("SQLException " + sql.getSQLState() + " " + sql.getMessage()+"&lt;BR&gt;"+Gadgets.replace(StackTraceUtil.getStackTrace(sql),"\n","&lt;BR&gt;"));
  }
%&gt;
&lt;/BODY&gt;
&lt;/HTML&gt;