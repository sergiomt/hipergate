<%@ page import="java.text.SimpleDateFormat,java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets,com.knowgate.forums.NewsMessage" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_newsgrp = request.getParameter("gu_newsgrp");
  String nm_newsgrp = Gadgets.URLEncode(request.getParameter("nm_newsgrp"));
  String gu_msg = request.getParameter("gu_msg");
  
  String sUserId = getCookie(request, "userid", "default");  
  String sSkin = getCookie(request, "skin", "xp");
  String sPathLogo = getCookie(request, "path_logo", "hglogopeq.jpg");
  if (sPathLogo.length()==0) sPathLogo = "hglogopeq.jpg";

  boolean bIsGuest = true;
  
  JDCConnection oConn = null;
  NewsMessage oMsg = new NewsMessage();
      
  try {
    
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
        
    oConn = GlobalDBBind.getConnection("messageread");
    
    oMsg.load(oConn, gu_msg);
 
    out.write("  <TITLE>hipergate :: Read Message" + oMsg.getStringNull(DB.tx_subject,"") + "</TITLE>\n");
    out.write("</HEAD>\n");
    out.write("<BODY CLASS=\"htmlbody\" LEFTMARGIN=\"16\" MARGINWIDTH=\"16\">\n");
    out.write("  <IMG SRC=\"../skins/" + sSkin + "/" + sPathLogo + "\" BORDER=\"0\">\n");

    out.write("  <TABLE WIDTH=\"100%\" CELLSPACING=\"2\" CELLPADDING=\"2\">\n");
    out.write("    <TR><TD BACKGROUND=\"../images/images/loginfoot_med.gif\" HEIGHT=\"3\"></TD></TR>\n");
    out.write("    <TR><TD><FONT CLASS=\"textplain\"><B>From</B>: <A HREF=\"mailto:" + oMsg.getStringNull(DB.tx_email,"") + "\">" + oMsg.getStringNull(DB.nm_author,"") + "</A></TD></TR>\n");
    out.write("    <TR><TD><FONT CLASS=\"textplain\"><B>Publishing Date</B>: " + oMsg.getDateFormated(DB.dt_published, "yyy-MM-dd hh:mm:ss") + "</TD></TR>\n");
    if (!oMsg.isNull(DB.dt_start) ) out.write("    <TR><TD><FONT CLASS=\"textplain\"><B>Start been visible at date:</B>: " + oMsg.getDateFormated(DB.dt_start, "yyy-MM-dd") + "</TD></TR>\n");
    if (!oMsg.isNull(DB.dt_expire)) out.write("    <TR><TD><FONT CLASS=\"textplain\"><B>Expiration Date:</B>: " + oMsg.getDateFormated(DB.dt_expire, "yyy-MM-dd") + "</TD></TR>\n");
    out.write("    <TR><TD><FONT CLASS=\"textplain\">There are&nbsp;" + String.valueOf(oMsg.getInt(DB.nu_thread_msgs)) + (oMsg.getInt(DB.nu_thread_msgs)==1 ? " message" : " messages") + " on this thread&nbsp;&nbsp;&nbsp;<A CLASS=\"linkplain\" HREF=\"msg_thread.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_newsgrp="+gu_newsgrp+"&nm_newsgrp="+Gadgets.URLEncode(nm_newsgrp)+"&gu_thread_msg=" + oMsg.getStringNull(DB.gu_thread_msg,"") + "\">View complete thread</A></TD></TR>\n");
    
    if (bIsGuest)
      out.write("    <TR><TD><IMG SRC=\"../images/images/forums/replytoall.gif\" ALT=\"Reply to All\">&nbsp;<A CLASS=\"linkplain\" HREF=\"#\" onclick=\"alert('Your credential level as Guest does not allow you to perform this action')\">Reply to All</A></TD></TR>\n");
    else
      out.write("    <TR><TD><IMG SRC=\"../images/images/forums/replytoall.gif\" ALT=\"Reply to All\">&nbsp;<A CLASS=\"linkplain\" HREF=\"msg_edit.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_newsgrp=" + gu_newsgrp + "&nm_newsgrp=" + nm_newsgrp + "&gu_parent_msg=" + gu_msg + "\">Reply to All</A></TD></TR>\n");
        
    if (!oMsg.isNull(DB.gu_product)) {
      DBSubset oLocs = oMsg.getAttachments(oConn);
      out.write("    <TR><TD>");
      for (int a=0; a<oLocs.getRowCount(); a++)
        out.write("<A HREF=\"../servlet/HttpBinaryServlet?id_user=" + sUserId + "&id_product=" + oMsg.getString(DB.gu_product) + "&id_location=" + oLocs.getString(DB.gu_location,a) + "\" CLASS=\"linkplain\" TARGET=\"blank\" TITLE=\"Open/Download\">" + oLocs.getStringNull(DB.xfile,a,"attached File" + String.valueOf(a)) + "</A>&nbsp;<FONT CLASS=\"textsmall\">(" + String.valueOf(oLocs.getInt(DB.len_file,a)/1024) + " Kb)</FONT>&nbsp;&nbsp;&nbsp;&nbsp;");        
      out.write("</TD></TR>");
    } // fi

    out.write("    <TR><TD BACKGROUND=\"../images/images/loginfoot_med.gif\" HEIGHT=\"3\"></TD></TR>\n");
    out.write("  </TABLE><BR>\n");

    out.write("  <FONT CLASS='textcode'>\n");
    out.write("<B>" + oMsg.getStringNull(DB.tx_subject,"") + "</B><BR>");
    out.write(oMsg.getStringNull(DB.tx_msg,""));

    out.write("</FONT>");

    oConn.close("messageread");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("messageread");
    out.write("  <META HTTP-EQUIV=\"refresh\" content=\"0; url=../common/errmsg.jsp?title=Error&desc=" + e.getMessage() + "&resume=_close\"></HEAD>");
  }
%>
</BODY>
</HTML>