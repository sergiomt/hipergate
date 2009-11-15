<%@ page import="java.io.IOException,java.io.File,java.util.Enumeration,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.oreilly.servlet.MultipartRequest,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
                      C/Oña 107 1º2 28050 Madrid (Spain)

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

  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = com.knowgate.misc.Gadgets.chomp(sTmpDir,java.io.File.separator);

  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, "UTF-8");

  String gu_mimemsg = oReq.getParameter("gu_mimemsg");
  String id_message = nullif(oReq.getParameter("id_message"));
  String nm_folder = "";
  
  Enumeration oFileNames = oReq.getFileNames();
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet;
  int iLastPart = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("attachfiles_store");  

    oStmt = oConn.prepareStatement("SELECT "+DB.id_message+","+DB.gu_category+" FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_mimemsg + "=?");
    oStmt.setString(1, gu_mimemsg);
    oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      if (id_message==null) id_message = oRSet.getString(1);
      nm_folder = oRSet.getString(2);
    }
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace)
      DebugFile.writeln("<JSP:Connection.prepareStatement(SELECT MAX("+DB.id_part+") FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "='"+gu_mimemsg+"')");
      
    oStmt = oConn.prepareStatement("SELECT MAX("+DB.id_part+") FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "=?");
    oStmt.setString(1, gu_mimemsg);
    oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      Object oMax = oRSet.getObject(1);
      if (!oRSet.wasNull())
        iLastPart = Integer.parseInt(oMax.toString());
    }
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace)
      DebugFile.writeln("<JSP:Connection.prepareStatement(INSERT INTO " + DB.k_mime_parts + "("+DB.gu_mimemsg+","+DB.id_message+","+DB.id_part+","+DB.id_disposition+","+DB.id_content+","+DB.id_type+","+DB.len_part+","+DB.de_part+","+DB.file_name+") VALUES ('"+gu_mimemsg+"',?,?,'reference',?,?,?,?,?))");

    oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_mime_parts + "("+DB.gu_mimemsg+","+DB.id_message+","+DB.id_part+","+DB.id_disposition+","+DB.id_content+","+DB.id_type+","+DB.len_part+","+DB.de_part+","+DB.file_name+") VALUES ('"+gu_mimemsg+"',?,?,'reference',?,?,?,?,?)");
    
    oConn.setAutoCommit (false);
    
    int iPart = 1;
    while (oFileNames.hasMoreElements()) {
      Object oNextFile = oFileNames.nextElement();
      String sFileName = oReq.getOriginalFileName(oNextFile.toString());
            
      if (sFileName!=null) {
        if (DebugFile.trace) DebugFile.writeln("<JSP:saving file " + sFileName);

        String sGuid = Gadgets.generateUUID();
        String sType = com.knowgate.hipermail.DBMimePart.getMimeType(oConn,sFileName);
        
        if (DebugFile.trace) DebugFile.writeln("<JSP:file mime type is " + sType);
        
        File oFile = new File(sTmpDir + sFileName);

        int iFileLen = new Long(oFile.length()).intValue();

	      File oRenamed = new File(sTmpDir + sGuid);
	
        oFile.renameTo(oRenamed);

	      oStmt.setString(1, id_message.length()>0 ? id_message : gu_mimemsg);
        oStmt.setInt(2, iLastPart+iPart);
	      oStmt.setString(3, sType);        
	      oStmt.setString(4, sType);        
        oStmt.setInt(5, iFileLen);
	      oStmt.setString(6, sFileName);
	      oStmt.setString(7, sTmpDir + sGuid);
	
	      if (DebugFile.trace) DebugFile.writeln("<JSP:PreparedStatement.executeUpdate()");
	
	      oStmt.executeUpdate();
	      iPart++;
      }
    } // wend
    oStmt.close();
    oStmt = null;
    
    oConn.commit();
    oConn.close("attachfiles_store");
  }
  catch (SQLException e) {
    if (null!=oStmt) { try {oStmt.close(); } catch (Exception ignore) {} }
    disposeConnection(oConn,"attachfiles_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn = null;
%>
<HTML><BODY onload="window.opener.parent.frames['msgattachments'].location.href='msg_attachs.jsp?gu_mimemsg=<%=gu_mimemsg%>&id_message=<%=id_message%>&folder=<%=nm_folder%>&timestamp=<%=String.valueOf(new java.util.Date().getTime())%>'; close();"></BODY></HTML>