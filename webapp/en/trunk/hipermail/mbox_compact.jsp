<%@ page import="java.math.BigDecimal,java.util.*,java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.misc.Environment,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets,com.knowgate.hipermail.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String gu_folder = request.getParameter("gu_folder");

  String sFsp = System.getProperty("file.separator");
  String sStorDir = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sFileProt = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  String sFileSrvr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  String sWrkAPath = "domains" + sFsp + getCookie(request, "domainid", "") + sFsp + "workareas" + sFsp + getCookie(request,"workarea","") + sFsp;
   
  String sMBoxDirectory, sMBoxFilePath ;
  sMBoxDirectory = sStorDir + sWrkAPath;

  JDCConnection oCon = null;
  PreparedStatement oStm = null;
  ResultSet oRst = null;
  Category oFld = new Category();
  DBSubset oDel = new DBSubset(DB.k_mime_msgs, DB.gu_mimemsg+","+DB.pg_message, DB.gu_category + "=? AND " + DB.bo_deleted + "=1", 1000);
  DBSubset oMsg = new DBSubset(DB.k_mime_msgs, DB.gu_mimemsg+","+DB.pg_message, DB.gu_category + "=? ORDER BY 2", 1000);
  int nMsg = 0, nDel = 0;
  
  try {
    oCon = GlobalDBBind.getConnection("mbox_compact");

    oFld.load(oCon, new Object[]{gu_folder});
    sMBoxFilePath = sMBoxDirectory + oFld.getPath(oCon) + sFsp + oFld.getString(DB.nm_category) + ".mbox";
    
    oStm = oCon.prepareStatement("SELECT COUNT(*) FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_category + "=?");
    oStm.setString(1, gu_folder);
    oRst = oStm.executeQuery();
    oRst.next();
    nMsg = oRst.getInt(1);
    oRst.close();
    oStm.close();
    
    nDel = oDel.load (oCon, new Object[]{gu_folder});
  
    oCon.close("mbox_compact");
  } 
  catch(SQLException e) {
      if (oCon!=null)
        if (!oCon.isClosed()) {
          oCon.close("mbox_compact");      
        }
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
      return;
  }
  
  File oFile;
  MboxFile oMbox = null;
  
  try {
    oFile = new File(sMBoxFilePath);
    if ((nMsg==nDel) && nMsg!=0) {
      oFile.delete();

      oCon = GlobalDBBind.getConnection("mbox_compact2");
      oCon.setAutoCommit(true);
      
      for (int d=0;d<nDel; d++)
        DBMimeMessage.delete(oCon, gu_folder, oDel.getString(0,d));

      oCon.close("mbox_compact2");
    }
    else if (nDel>0) {
      int[] aMsgNums = new int[nDel];
      for (int m=0; m<nDel; m++)
        aMsgNums[m] = oDel.getDecimal(1,m).intValue();
      oMbox = new MboxFile(oFile, MboxFile.READ_WRITE);
      oMbox.purge(aMsgNums);
      long[] aMsgPos = oMbox.getMessagePositions();
      oMbox.close();
      oMbox=null;
      oCon = GlobalDBBind.getConnection("mbox_compact2");
      oCon.setAutoCommit(true);
      
      for (int d=0;d<nDel; d++)
        DBMimeMessage.delete(oCon, gu_folder, oDel.getString(0,d));
        
      nMsg = oMsg.load (oCon, new Object[]{gu_folder});
      oStm = oCon.prepareStatement("UPDATE " + DB.k_mime_msgs + " SET " + DB.pg_message + "=?," + DB.nu_position + "=? WHERE " + DB.gu_mimemsg + "=?");
      for (int i=0; i<nMsg; i++) {
        oStm.setBigDecimal(1, new BigDecimal(i));
        oStm.setBigDecimal(2, new BigDecimal(aMsgPos[i]));
        oStm.executeUpdate();
      }  
      oStm.close();
 
      oCon.close("mbox_compact2");
    }    
  } 
  catch(IOException e) {
    if (oMbox!=null) { try {oMbox.close();} catch (Exception ignore) {} }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    return;
  }
  catch(SQLException e) {
      if (oCon!=null)
        if (!oCon.isClosed())
          oCon.close("mbox_compact2");      
      oCon = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
      return;
  }
  response.sendRedirect (response.encodeRedirectUrl ("fldr_opts.jsp?gu_folder="+gu_folder+"&nm_folder="+Gadgets.URLEncode(request.getParameter("nm_folder"))));
%>