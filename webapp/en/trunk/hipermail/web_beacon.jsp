<%@ page import="java.io.File,java.io.IOException,java.io.OutputStream,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,java.sql.Types,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Gadgets,com.knowgate.dfs.FileSystem" language="java" session="false" contentType="image/gif" %><%@ include file="../methods/dbbind.jsp" %><% 

  JDCConnection oConn = null;
  PreparedStatement oStmt = null;

  try {
    String sGuJob = request.getParameter("gu_job");
    int iPgAtm = Integer.parseInt(request.getParameter("pg_atom"));
    String sGuCm = request.getParameter("gu_company");
    if (sGuCm!=null) if (sGuCm.length()==0) sGuCm="";
    String sGuCn = request.getParameter("gu_contact");
    if (sGuCn!=null) if (sGuCn.length()==0) sGuCn="";
    String sEmail = request.getParameter("tx_email");
    if (sEmail!=null) if (sEmail.length()==0) sEmail="";
    String sIp = Gadgets.left(request.getRemoteAddr(),16);
    
    oConn = GlobalDBBind.getConnection("web_beacon");
    
    oConn.setAutoCommit(true);
    
    oStmt = oConn.prepareStatement("INSERT INTO k_job_atoms_tracking (gu_job,pg_atom,gu_company,gu_contact,ip_addr,tx_email,user_agent) VALUES (?,?,?,?,?,?,?)");
    oStmt.setString(1, sGuJob);
    oStmt.setInt(2, iPgAtm);
    if (null==sGuCm)
      oStmt.setNull(3, Types.CHAR);
    else
      oStmt.setString(3, sGuCm);
    if (null==sGuCn)
      oStmt.setNull(4, Types.CHAR);
    else
      oStmt.setString(4, sGuCn);
    if (null==sIp)
      oStmt.setNull(5, Types.VARCHAR);
    else
      oStmt.setString(5, sIp);
    if (null==sEmail)
      oStmt.setNull(6, Types.VARCHAR);
    else
      oStmt.setString(6, sEmail);
    oStmt.setString(7, Gadgets.left(request.getHeader("User-Agent"),254));
    oStmt.executeUpdate();
	  oStmt.close();
	  oStmt=null;
    oConn.close("web_beacon");
    oConn = null;
  }
  catch (Exception e) {
    if (oStmt!=null) oStmt.close(); 
    if (oConn!=null) if (!oConn.isClosed()) oConn.close("web_beacon");
  }
  
  String sImgPath = request.getRealPath(request.getServletPath());
  sImgPath = sImgPath.substring(0,sImgPath.lastIndexOf(File.separator));
  sImgPath = sImgPath.substring(0,sImgPath.lastIndexOf(File.separator));
  sImgPath = "file://" + sImgPath + File.separator + "images" + File.separator + "images" + File.separator + "spacer.gif";

  FileSystem oFs = new FileSystem();
  OutputStream oOut = response.getOutputStream();
  if (oFs.exists(sImgPath))
    oOut.write(oFs.readfilebin(sImgPath));
  oOut.flush();
  
  if (true) return; // Do not remove this line or you will get an error "getOutputStream() has already been called for this response"
%>