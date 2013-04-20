<%@ page import="java.text.SimpleDateFormat,java.net.URLDecoder,java.io.Reader,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<HTML>
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
<%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

  final int BufferSize = 2048;
  PreparedStatement oStmt;
  ResultSet oRSet;
  Reader oRead;
  char Buffer[] = new char[BufferSize];
  int iReaded;

  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_newsgrp = request.getParameter("gu_newsgrp");
  String nm_newsgrp = Gadgets.URLEncode(request.getParameter("nm_newsgrp"));
    
  String sUserId = getCookie(request, "userid", "default");
  String sSkin = getCookie(request, "skin", "default");
    
  SimpleDateFormat oFmt = new SimpleDateFormat("yyy-MM-dd hh:mm:ss");
  Product oProd;    
  DBSubset oLocs;    
  StringBuffer oBody = new StringBuffer();
  String sAuthor, sDtPublished, sMail, sSubject,sThreadId, sAttachsId, sGuMsg;
  int nThreadMsgs;

  boolean bIsGuest = true;
  
  JDCConnection oConn = null;
    
  try {
    
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("messagethread");
    
    sThreadId = request.getParameter("gu_thread_msg");
    sSubject = "View thread";
     
    if (null==sThreadId) {
      oStmt = oConn.prepareStatement("SELECT " + DB.gu_thread_msg + "," + DB.tx_subject + " FROM " + DB.k_newsmsgs + " WHERE " + DB.gu_msg + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, request.getParameter("gu_msg"));
      oRSet = oStmt.executeQuery();
      oRSet.next();
      sThreadId = oRSet.getString(1);
      sSubject = oRSet.getString(2);
      oRSet.close();
      oStmt.close();
    }
        
    oStmt = oConn.prepareStatement("SELECT " + DB.gu_msg + "," + DB.nm_author + "," + DB.dt_published + "," + DB.nu_thread_msgs + "," + DB.gu_thread_msg + "," + DB.tx_email + "," + DB.tx_subject + "," + DB.gu_product + "," + DB.tx_msg + " FROM " + DB.k_newsmsgs + " WHERE " + DB.gu_thread_msg + "=? ORDER BY 3", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sThreadId);
    oRSet = oStmt.executeQuery();

    out.write("  <TITLE>hipergate :: " + sSubject + "</TITLE>\n");
    out.write("</HEAD>\n");
    out.write("<BODY CLASS='htmlbody' LEFTMARGIN=16 MARGINWIDTH=16>\n");
    out.write("  <IMG SRC=\"../skins/" + sSkin + "/hglogopeq.jpg\" BORDER=\"0\">\n");

    while(oRSet.next()) {
      sGuMsg = oRSet.getString(1);
      sAuthor = oRSet.getString(2);
      sDtPublished = oFmt.format(oRSet.getTimestamp(3));
      nThreadMsgs = oRSet.getInt(4);
      sMail = oRSet.getString(6);
      sSubject = oRSet.getString(7);
      sAttachsId = oRSet.getString(8);
      oRead = oRSet.getCharacterStream(9);
      if (null!=oRead) {
        do {
          iReaded = oRead.read(Buffer,0,BufferSize);
          if (iReaded>0) oBody.append(Buffer,0,iReaded);
        } while (BufferSize==iReaded);
        oRead.close();
      } // fi (oRead)

      out.write("  <TABLE WIDTH=\"100%\" CELLSPACING=\"2\" CELLPADDING=\"2\">\n");
      out.write("    <TR><TD BACKGROUND=\"../images/images/loginfoot_med.gif\" HEIGHT=\"3\"></TD></TR>\n");
      out.write("    <TR><TD><FONT CLASS=\"textplain\"><B>from</B>: </FONT><A HREF=\"mailto:" + sMail + "\">" + sAuthor + "</A></TD></TR>\n");
      out.write("    <TR><TD><FONT CLASS=\"textplain\"><B>Date</B>: " + sDtPublished + "</FONT></TD></TR>\n");
      
      if (!bIsGuest)
        out.write("    <TR><TD><A CLASS=\"linkplain\" HREF=\"msg_edit.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_newsgrp=" + gu_newsgrp + "&nm_newsgrp=" + nm_newsgrp + "&gu_parent_msg=" + sGuMsg + "\">Reply to All</A></TD></TR>\n");
        
      if (sAttachsId!=null) {
        out.write("    <TR><TD>");
        oProd = new Product(sAttachsId);
        oLocs = oProd.getLocations(oConn);
        for (int a=0; a<oLocs.getRowCount(); a++)
          out.write("<A HREF=\"../servlet/HttpBinaryServlet?id_user=" + sUserId + "&id_product=" + sAttachsId + "&id_location=" + oLocs.getString(DB.gu_location,a) + "\" CLASS=\"linkplain\" TARGET=\"blank\" TITLE=\"Open/Download\">" + oLocs.getStringNull(DB.xfile,a,"attached File" + String.valueOf(a)) + "</A>&nbsp;<FONT CLASS=\"textsmall\">(" + String.valueOf(oLocs.getInt(DB.len_file,a)/1024) + " Kb)</FONT>&nbsp;&nbsp;&nbsp;&nbsp;");        
        out.write("</TD></TR>");
      } // fi (sAttachsId)
      
      out.write("  </TABLE><BR>\n");

      out.write("  <FONT CLASS='textcode'>\n");
      out.write("<B>" + sSubject + "</B><BR>");
      out.write(oBody.toString());          
      out.write("</FONT><BR>\n");
      
      oBody.setLength(0);
    } // wend
    
    oRSet.close();
    oStmt.close();
    oConn.close("messagethread");
  }
  catch (SQLException e) {  
    iReaded = 0;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("messagethread");
    out.write("  <META HTTP-EQUIV=\"refresh\" content=\"0; url=../common/errmsg.jsp?title=Error&desc=" + e.getMessage() + "&resume=_close\"");
  }
%>
</BODY>
</HTML>