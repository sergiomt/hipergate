<%@ page import="java.net.URLDecoder,java.io.File,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.debug.DebugFile,com.knowgate.hipergate.Category,com.knowgate.hipermail.MailAccount,com.knowgate.hipermail.DBStore,com.knowgate.hipermail.DBMimeMessage,com.knowgate.misc.Environment" language="java" session="false" contentType="text/plain;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %><%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution
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

  // ************************************************************
  // Get list of messages placed at local cache for inbox folders
  // Result is written as tabbed separated plaintext
  
  response.addHeader ("cache-control", "private");
  response.setHeader("Content-Disposition","inline; filename=\"tsvfeed.txt\"");
  
  String sLanguage = getNavigatorLanguage(request);  

  String gu_folder = request.getParameter("gu_folder");
  
  // **********************************************

  Short oOne = new Short((short)1);
  int iMailCount = 0;
  String sOrderBy = null;
  int iMaxRows;
  int iSkip;
  
  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "100"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 100; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;
  if (iSkip<0) iSkip = 0;

  // **********************************************
  
  if (request.getParameter("orderby")!=null) {
    sOrderBy = request.getParameter("orderby");   
    if (sOrderBy.equals("7") || sOrderBy.equals("8")) sOrderBy += " DESC";
  }

  JDCConnection oConn = null;
  StringBuffer oFoldersBuffer = new StringBuffer();
  String sDrafts = null;
  ACLUser oMe = new ACLUser(id_user);
  DBSubset oMsgs = new DBSubset (DB.k_mime_msgs, DB.gu_mimemsg+","+DB.id_message+","+DB.id_priority+","+DB.nm_from+","+DB.nm_to+","+DB.tx_subject+","+DB.dt_received+","+DB.dt_sent+","+DB.len_mimemsg+","+DB.pg_message+","+DB.bo_deleted+","+DB.tx_email_from,
      			         DB.gu_category+"=? AND "+DB.gu_workarea+"=? AND " + DB.bo_deleted + "<>1 AND " + DB.gu_parent_msg + " IS NULL " + (sOrderBy==null ? "" : " ORDER BY "+sOrderBy), iMaxRows);
  int iMsgs = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("msg_listing");

    oMe.put(DB.gu_user, id_user);
    
    if (null==gu_folder)
      gu_folder = oMe.getMailFolder (oConn, "inbox");

    sDrafts = oMe.getMailFolder(oConn, "drafts");

    oMsgs.setMaxRows(iMaxRows);    
    iMsgs = oMsgs.load(oConn, new Object[]{gu_folder,gu_workarea}, iSkip);

    // *******************
    // Remove empty drafts
    if (gu_folder.equals(sDrafts)) {
        PreparedStatement oUdpt = oConn.prepareStatement( "UPDATE " + DB.k_mime_msgs + " SET " + DB.bo_deleted + "=1 WHERE " + DB.gu_mimemsg + "=?");
        PreparedStatement oPart = oConn.prepareStatement( "SELECT COUNT(*) FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "=?");
        ResultSet rPart;
        int nParts;
        for (int d=0; d<iMsgs; d++) {
          if (oMsgs.getStringNull(5,d,"").length()==0 && oMsgs.getInt(8,d)==0) {
            oPart.setString(1, oMsgs.getString(0,d));
            rPart = oPart.executeQuery();
            rPart.next();
            nParts = rPart.getInt(1);
            rPart.close();
            if (nParts==0) {
              oUdpt.setString(1, oMsgs.getString(0,d));
              oUdpt.executeUpdate();
              oMsgs.setElementAt(oOne,10,d);
	    }
          }
        }
        oPart.close();
        oUdpt.close();
    } // fi

    oConn.close("msg_listing");
  }
  catch (SQLException sqle) {
    if (null!=oConn)
       if (!oConn.isClosed())
         oConn.close("msg_listing");
    oConn = null;
  }
  if (null==oConn) return;
  oConn=null;
  
  int nonempty = 0;
  for (int m=0; m<iMsgs; m++) {
    if (oMsgs.getShort(10,m)!=(short)1) {
      if (nonempty>0) out.write("\n");
      String sGuid = oMsgs.getString(0, m);
      String sId = oMsgs.getString(1, m);
      String sPriority = oMsgs.getStringNull(2, m, "3");
      String sFrom = oMsgs.getStringNull(3, m, oMsgs.getStringNull(11, m, ""));
      String sTo = oMsgs.getStringNull(4, m, "");
      String sSubject = oMsgs.getStringNull(5, m, "<I>&lt;sin asunto&gt;</I>");
      String sDateReceived = nullif(oMsgs.getDateTime(6, m));
      String sDateSent = nullif(oMsgs.getDateTime(7, m));
      int iLen;
      String sSize;
      if (!oMsgs.isNull(8,m))
        iLen = oMsgs.getInt(8, m);
      else
        iLen = -1;           
      if (iLen==-1)
        sSize = "";
      else if (iLen<=1024)
        sSize = "1";
      else
        sSize = String.valueOf(iLen/1024);
      String sNum = String.valueOf(oMsgs.getInt(9, m));

      out.write(sPriority+"\t");    
      out.write("<SPAN onmouseover=\"hideRightMenu()\">"+sFrom.replace('\t',' ')+"</SPAN>"+"\t");
      out.write("<A HREF=\"msg_view.jsp?gu_account="+oMacc.getString(DB.gu_account)+"&nm_folder="+gu_folder+"&nu_msg=-1&id_msg="+Gadgets.URLEncode(sId)+"\" TARGET=\"editmail-"+String.valueOf(m)+"\" onmouseover=\"jsMsgId='"+sId+"';jsMsgNum=-"+String.valueOf(m)+";jsMsgGuid='"+sGuid+"';showRightMenu(event)\">"+sSubject.replace('\t',' ')+"</A>\t");
      out.write("<SPAN onmouseover=\"hideRightMenu()\">"+sDateSent+"</SPAN>\t");
      out.write(sSize+"\t");
      out.write(sId+"\t");
      out.write(sNum+"\t");
      out.write(sGuid);
      nonempty++;
    } // fi (bo_deleted!=1)
  } // next(m)
%>