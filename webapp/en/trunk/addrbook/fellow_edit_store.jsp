<%@ page import="com.oreilly.servlet.MultipartRequest,java.io.File,java.io.FileInputStream,java.io.IOException,java.net.URLDecoder,java.util.Enumeration,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.addrbook.Fellow" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/multipartreqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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
  String sUserIdCookiePrologValue = null;
  
  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = com.knowgate.misc.Gadgets.chomp(sTmpDir,java.io.File.separator);

  if (com.knowgate.debug.DebugFile.trace) {

    Cookie aCookies[] = request.getCookies();
    
    if (null != aCookies) {
      for (int c=0; c<aCookies.length; c++) {
      	if (aCookies[c].getName().equals("userid")) {
          sUserIdCookiePrologValue = java.net.URLDecoder.decode(aCookies[c].getValue());
          break;
        }
      } // for
      
    } // fi
      
    com.knowgate.dataobjs.DBAudit.log ((short)0, "OJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, "", "", "");
  }
           
  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, "UTF-8");
    
  String gu_fellow = oReq.getParameter("gu_fellow");
  String id_user = oReq.getParameter("id_user");
  
  boolean bRemoveFile;

  String sOpCode = gu_fellow.length()>0 ? "NFLW" : "MFLW";
  
  Enumeration oFileNames;  
  String sFileName = null;
  int iFileLen;
  File oFile;
  FileInputStream oFileStream;

  JDCConnection oConn = GlobalDBBind.getConnection("felloweditstore");  
  PreparedStatement oStmt;
  
  Fellow oObj = new Fellow();

  oFileNames = oReq.getFileNames();

  if (oFileNames.hasMoreElements())
    sFileName = oReq.getOriginalFileName(oFileNames.nextElement().toString());
    
  try {
    loadRequest(oConn, oReq, oObj);

    oConn.setAutoCommit (false);
    
    oObj.store(oConn);
        
    if (0!=gu_fellow.length()) {
            
      bRemoveFile = nullif(oReq.getParameter("remove_file"),"").equals("1");

      if (bRemoveFile || (sFileName!=null)) {
        oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_fellows_attach + " WHERE " + DB.gu_fellow + "=?");
        oStmt.setString(1, gu_fellow);
        oStmt.execute();
        oStmt.close();
      }
    }

    oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_fellows_attach + "(" + DB.gu_fellow + "," + DB.tx_file + "," + DB.len_file + "," + DB.bin_file + ") VALUES (?,?,?,?)");
      
    if (sFileName!=null) {

        // Get file length
        oFile = new File(sTmpDir + sFileName);

        if (oFile==null) throw new IOException("Null file pointer");

        iFileLen = new Long(oFile.length()).intValue();
      
        if (iFileLen>0) {
          // Move file into database blob field
          oFileStream = new FileInputStream (oFile);
          oStmt.setString(1, oObj.getString(DB.gu_fellow));
          oStmt.setString(2, sFileName);
          oStmt.setInt(3, iFileLen);
          oStmt.setBinaryStream(4, oFileStream, iFileLen);
          oStmt.execute();
          oFileStream.close();
          oFileStream = null;
        } // fi(iFileLen>0)
      
        // Delete temporary upload file      
        oFile.delete();
        oFile = null;

    } // fi (sFileName)
    
    DBAudit.log(oConn, Fellow.ClassId, sOpCode, id_user, oObj.getString(DB.gu_fellow), null, 0, 0, null, null);

    GlobalCacheClient.expire("k_fellows.id_domain[" + oReq.getParameter("id_domain") + "]");
    GlobalCacheClient.expire("k_fellows.gu_workarea[" + oReq.getParameter("gu_workarea") + "]");
    GlobalCacheClient.expire("["+oReq.getParameter("gu_workarea")+",users]");


    // ***************************************************************************
    // Check whether or not there is an active LDAP server and synchronize with it
    
    String sLdapConnect = Environment.getProfileVar(GlobalDBBind.getProfileName(), "ldapconnect", "");

    if (sLdapConnect.length()>0) {

      Class oLdapCls = Class.forName(Environment.getProfileVar(GlobalDBBind.getProfileName(),"ldapclass", "com.knowgate.ldap.LDAPNovell"));

      com.knowgate.ldap.LDAPModel oLdapImpl = (com.knowgate.ldap.LDAPModel) oLdapCls.newInstance();

      oLdapImpl.connectAndBind(Environment.getProfile(GlobalDBBind.getProfileName()));
      
      try {
        oLdapImpl.deleteUser (oConn, oObj.getString(DB.gu_fellow));
      } catch (com.knowgate.ldap.LDAPException ignore) { }
      
      if (!oObj.isNull(DB.tx_email))
        oLdapImpl.addUser (oConn, oObj.getString(DB.gu_fellow));
        
      oLdapImpl.disconnect();
    }
      
    // End LDAP synchronization
    // ***************************************************************************    

    oConn.commit();
    oConn.close("felloweditstore");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"felloweditstore");

    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, oReq.getServletPath(), "", 0, "", "SQLException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (com.knowgate.ldap.LDAPException e) {  
    disposeConnection(oConn,"felloweditstore");

    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, oReq.getServletPath(), "", 0, "", "LDAPException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=LDAPException&desc=" + e.getMessage() + "&resume=_back"));
  }

  if (null==oConn) return;
  
  oConn = null;
  
  if (nullif(oReq.getParameter("chk_webmail")).equals("1")) {
    response.sendRedirect (response.encodeRedirectUrl ("../hipermail/account_edit.jsp?bo_popup=true&id_user=" + oObj.getString(DB.gu_fellow)));
  } else {
    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>if (window.opener) if (!window.opener.closed) window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");
	}

  if (com.knowgate.debug.DebugFile.trace) {   
    com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, oReq.getServletPath(), "", 0, "", "", "");
  }
%>