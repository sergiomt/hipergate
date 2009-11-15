<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Gadgets,com.knowgate.forums.*" language="java" session="false" contentType="text/xml;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*

  Create an RSS 2.0 file with a message list
  Check generated RSS with UserLand RSS 2.0 Validator at: http://rss.scripting.com/

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
 
  // Set how descriptions will be encoded, either has HTML entities, CDATA or NONE.
  final int ENCODE_NONE  = 0;
  final int ENCODE_HTML  = 1;
  final int ENCODE_CDATA = 2;
  
  final int ENCODING = ENCODE_HTML;
  
  // Maximum length of message description text.
  // Messages longer than the number of characters set here will be truncated
  final int MAX_MSG_DESC_LEN = 200;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String gu_newsgrp = request.getParameter("gu_newsgrp");
  String nm_newsgrp = request.getParameter("nm_newsgrp");  
  String id_language = nullif(request.getParameter("id_language"), getNavigatorLanguage(request));
  String tl_newsgrp = null; 

  // Maximum number of messages to be listed as items  
  int nu_messages = Integer.parseInt(nullif(request.getParameter("nu_messages"), "10"));
  
  int iMessageCount = 0;
  DBSubset oMessages;
  NewsGroup oNewsGrp = null;
  
  // Category oNewsGrp;
  JDCConnection oConn = GlobalDBBind.getConnection("rssmessagelisting");  
  
  try {
    if (null==gu_newsgrp) {
      PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.gu_category + " FROM" + DB.k_categories + " WHERE " + DB.nm_category + "=?");
      oStmt.setString (1, nm_newsgrp);
      ResultSet oRSet = oStmt.executeQuery();
      if (oRSet.next())
        gu_newsgrp = oRSet.getString(1);
      oRSet.close();
      oStmt.close();
    }
    
    oNewsGrp = new NewsGroup (oConn, gu_newsgrp);
    
    tl_newsgrp = oNewsGrp.getLabel(oConn, id_language);

    if (null==tl_newsgrp) tl_newsgrp = oNewsGrp.getStringNull(DB.nm_category, nm_newsgrp);
    
    oMessages = new DBSubset(DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x",

	" m." + DB.gu_msg     + ",m." + DB.gu_product      + ",m." + DB.nm_author + 
	",m." + DB.tx_subject + ",m." + DB.dt_published    + ",m." + DB.id_status + 
	",m." + DB.tx_email   + ",m." + DB.nu_thread_msgs  + ",m." + DB.tx_msg,

	"m." + DB.id_status + "=" + String.valueOf(NewsMessage.STATUS_VALIDATED) + " AND m." + DB.gu_parent_msg + " IS NULL AND m." + DB.gu_msg + 
	"=x." + DB.gu_object + " AND x." + DB.gu_category + "='" + gu_newsgrp + "'", 
	nu_messages);

    oMessages.setMaxRows(nu_messages);
    iMessageCount = oMessages.load (oConn);

    oConn.close("rssmessagelisting"); 
  }
  catch (SQLException e) {  
    oMessages = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("rssmessagelisting");
    oConn = null;  
	out.write(e.getMessage());
  }
  catch (NullPointerException e) {  
    oMessages = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("rssmessagelisting");
    oConn = null;  
	out.write("NullPointerException");
  }

  if (null==oConn) return;
  
  oConn = null;  

%>
<rss version="2.0">
  <channel>
    <title><%=tl_newsgrp%></title>
    <link></link>
    <description><%=oNewsGrp.getStringNull(DB.de_newsgrp, "")%></description>
    <copyright>Copyright (C) 2009  Know Gate S.L.</copyright>
    <managingEditor>editor@thechannel.com</managingEditor>
    <webMaster>webmaster@thechannel.com</webMaster>
    <pubDate><%=nullif(oNewsGrp.getDateFormated(DB.dt_last_update, "EEE, dd MMM yyyy hh:mm:ss z"))%></pubDate>
    <lastBuildDate><%=nullif(oNewsGrp.getDateFormated(DB.dt_last_update, "EEE, dd MMM yyyy hh:mm:ss z"))%></lastBuildDate>
    <docs>http://blogs.law.harvard.edu/tech/rss</docs>
    <generator>hipergate.org RSS 2.0 Feed Generator</generator>
    <category>Weblog</category>
    <language><%=id_language%></language>
<%

  String sMsgId,sAuthor,sSubject,sDtPub,sMail,sMsg;
  int iStatus;
  boolean bAttachs;

  for (int i=0; i<iMessageCount; i++) {
    sMsgId   = oMessages.getString(0,i);
    bAttachs = !oMessages.isNull(1,i);
    sAuthor  = oMessages.getStringNull(2,i,"");
    sSubject = oMessages.getStringNull(3,i,"");
    sDtPub   = oMessages.getDateFormated(4, i, "EEE, dd MMM yyyy hh:mm:ss z");
    iStatus  = (int) oMessages.getShort(5,i);
    sMail    = oMessages.getStringNull(6,i,"");
    
    sMsg = oMessages.getStringNull(8,i,"");

    if(sMsg.length()>MAX_MSG_DESC_LEN)
      sMsg = sMsg.substring(0,MAX_MSG_DESC_LEN) + "...";
    
    if (ENCODING==ENCODE_HTML)
      sMsg = Gadgets.HTMLEncode(sMsg);
    else if (ENCODING==ENCODE_CDATA)    
      sMsg = "<![CDATA[" + sMsg + "]]>";
    
    if (!sMail.equals(""))
      sAuthor += " (" + sMail + ")";
      
    out.write("    <item>\n");
    out.write("      <title>"+sSubject+"</title>\n");
    out.write("      <link>http://www.hipergate.org/forums/forum_view.jsp?gu_msg="+sMsgId+"</link>\n");
    out.write("      <description>"+sMsg+"</description>\n");
    out.write("      <author>"+sAuthor+"</author>\n");
    out.write("      <guid isPermaLink=\"true\">http://www.hipergate.org/forums/forum_view.jsp?gu_msg="+sMsgId+"</guid>\n");
    out.write("      <pubDate>"+sDtPub+"</pubDate>\n");
    out.write("    </item>\n");
      
  }
%>
  </channel>
</rss>
