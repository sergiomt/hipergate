<%@ page import="java.text.SimpleDateFormat,java.util.Comparator,java.util.Vector,java.math.BigDecimal,java.net.URLDecoder,javax.mail.internet.MimeUtility,java.io.FileNotFoundException,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Category,com.knowgate.hipermail.*,com.knowgate.lucene.MailRecord,com.knowgate.lucene.MailSearcher" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  response.addHeader ("cache-control", "no-cache");

  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd");

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");

  String id_user = getCookie(request,"userid","");
  String id_domain = getCookie(request,"domainid","0");
  String gu_workarea = getCookie(request,"workarea",""); 
  
  String screen_width = request.getParameter("screen_width");
  String gu_folder = nullif(request.getParameter("gu_folder"));
  String fromrec = nullif(request.getParameter("from"));
  String torec = nullif(request.getParameter("to"));
  String subject = nullif(request.getParameter("subject"));
  String dt_before = nullif(request.getParameter("dt_before"));
  String dt_after = nullif(request.getParameter("dt_after"));
  String body = nullif(request.getParameter("body"));
  
  int iScreenWidth;
  float fScreenRatio;

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;

  String sLuceneIndex = Environment.getProfileVar(GlobalDBBind.getProfileName(), "luceneindex", "");
  
  // **********************************************

  int iMailCount = 0;
  String sOrderBy=nullif(request.getParameter("orderby"),"6,7 DESC");
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
    
  String sWhere = "m." + DB.gu_workarea + "=? AND m." + DB.bo_deleted + "<>1 AND m." + DB.gu_parent_msg + " IS NULL ";
  
  Vector vParams = new Vector();
  
  vParams.add(gu_workarea);

  if (fromrec.length()!=0) {
    sWhere += " AND " + DB.gu_mimemsg + " IN (SELECT " + DB.gu_mimemsg + " FROM " + DB.k_inet_addrs + " WHERE " + DB.tp_recipient + "='from' AND (" + DB.nm_from + " " + DBBind.Functions.ILIKE + " ? OR " + DB.tx_email + " " + DBBind.Functions.ILIKE + " ?)) AND " + DB.gu_mimemsg + " IN (SELECT " + DB.gu_mimemsg + " FROM " + DB.k_inet_addrs + " WHERE (" + DB.tp_recipient + "='to' OR " + DB.tp_recipient + "='cc' OR " + DB.tp_recipient + "='bcc')) ";
    vParams.add("%"+fromrec+"%");
    vParams.add("%"+fromrec+"%");
  }
  if (torec.length()!=0) {
    sWhere += " AND " + DB.gu_mimemsg + " IN (SELECT " + DB.gu_mimemsg + " FROM " + DB.k_inet_addrs + " WHERE " + DB.tp_recipient + "='to' AND (" + DB.nm_to + " " + DBBind.Functions.ILIKE + " ? OR " + DB.tx_email + " " + DBBind.Functions.ILIKE + " ?)) AND " + DB.gu_mimemsg + " IN (SELECT " + DB.gu_mimemsg + " FROM " + DB.k_inet_addrs + " WHERE (" + DB.tp_recipient + "='to' OR " + DB.tp_recipient + "='cc' OR " + DB.tp_recipient + "='bcc')) ";
    vParams.add("%"+torec+"%");
    vParams.add("%"+torec+"%");
  }
  if (subject.length()!=0) {
    sWhere += " AND " + DB.tx_subject + " " + DBBind.Functions.ILIKE + " ?";
    vParams.add("%"+subject+"%");
  }
  if (gu_folder.length()!=0) {
    sWhere += " AND " + DB.gu_category + " = ?";
    vParams.add(gu_folder);
  }
  if (dt_before.length()!=0) {
    sWhere += " AND " + DB.dt_received + ">={ ts '"+dt_before+" 00:00:00'}";
  }
  if (dt_after.length()!=0) {
    sWhere += " AND " + DB.dt_received + "<={ ts '"+dt_after+" 23:59:59'}";
  }
  
  ACLUser oMe = new ACLUser();
  Category oFolder = new Category();
  String sFolderName = "";
  JDCConnection oConn = null;
  Comparator oSort;
  MailRecord[] aMsgs = null;
  DBSubset oMsgs = null;
  int iMsgs = 0;
  String sOutBox = null, sDrafts = null;
  String[] aMailFolders;
   
  try {
    oConn = GlobalDBBind.getConnection("msg_search");
    oConn.setAutoCommit(true);

      oMe.load(oConn, new Object[]{id_user});

      sOutBox = oMe.getMailFolder(oConn, "outbox");
      sDrafts = oMe.getMailFolder(oConn, "drafts");

      if (sLuceneIndex.length()==0) {
  
        oMsgs = new DBSubset (DB.k_mime_msgs + " m", DB.gu_mimemsg+","+DB.id_message+","+DB.id_priority+","+DB.nm_from+","+DB.nm_to+","+DB.tx_subject+","+DB.dt_received+","+DB.dt_sent+","+DB.len_mimemsg+","+DB.pg_message+","+DB.gu_category,
      			      sWhere + " AND " + DB.gu_category + "<>'"+sOutBox+"' AND "+DB.gu_category+"<>'"+sDrafts+"' ORDER BY " + sOrderBy, 100);
      
        iMsgs = oMsgs.load(oConn, vParams.toArray());
      }
      else {
  	  if (sOrderBy!=null) {
  	    switch (Integer.parseInt(sOrderBy.substring(0,1))) {
  	      case 4:
  	     	oSort = new MailRecord.CompareAuthor();
  	     	break;
  	      case 6:
  	     	oSort = new MailRecord.CompareSubject();
  	     	break;
  	      case 7:
  	     	oSort = new MailRecord.CompareDateSent();
  	     	break;
  	      case 9:
  	     	oSort = new MailRecord.CompareSize();
  	     	break;
  	      default:
  	     	oSort = null;
  	     	break;  	      
  	    } // end switch
  	  } else {
  	    oSort = null;
  	  }

  	  if (gu_folder.length()>0) {
  	    oFolder.load(oConn, new Object[]{gu_folder});
  	  }

		  if (oFolder.isNull(DB.nm_category))
		    aMailFolders = oMe.getMailFolderNames(oConn);
		  else
		  	aMailFolders = new String[]{oFolder.getString(DB.nm_category)};
  	  
  	  aMsgs = MailSearcher.search (sLuceneIndex, gu_workarea, aMailFolders,
                                   fromrec.length()>0 ? fromrec : null,
                                   torec.length()>0 ? torec : null,
      				                     subject.length()>0 ? subject : null,
				                           dt_before.length()>0 ? oFmt.parse(dt_before) : null,
				                           dt_after.length()>0 ? oFmt.parse(dt_after) : null,
				                           body.length()>0 ? body : null, -1, oSort);	  
	    if (aMsgs!=null) iMsgs = aMsgs.length; else iMsgs = 0;

  	} // fi (sLuceneIndex=="")

    oConn.close("msg_search");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("msg_search");
    oConn = null;    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("msg_search");
    oConn = null;    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (FileNotFoundException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("msg_search");
    oConn = null;    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }

  
  if (null==oConn) return;
  oConn = null;
    
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

	function viewMessage(fld,num,id) {
	  
	  open ("msg_view.jsp?mailbox=<%=id_user%>&nm_folder="+fld+"&nu_msg=" + String(num) + "&id_msg=" + escape(id) + "&resume=" + escape("number="+String(num)+"&msgid="+id), "editmailmsg"+String(num), "scrollbars=no,resizable=yes,directories=no,toolbar=no,menubar=no,width=" + String(600*screen.width/800) + ",height=" + String(460*screen.height/640));
	
	  return false;
	} // viewMessage
      
      // ------------------------------------------------------

	function sortBy(fld) {
	  
	  var frm = document.forms[0];
	
	  frm.orderby.value = String(fld);
	  
	  frm.submit();
	  
	} // sortBy		

    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  var frm = document.forms[0];
	  
	  frm.screen_width.value = String(screen.width);
	  
	} // setCombos()
    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <FORM METHOD="post" ACTION="msg_search.jsp">
      <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1"><% out.write("Search Results"); %></FONT></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">
      <INPUT TYPE="hidden" NAME="screen_width">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="from" VALUE="<%=fromrec%>">
      <INPUT TYPE="hidden" NAME="to" VALUE="<%=torec%>">
      <INPUT TYPE="hidden" NAME="subject" VALUE="<%=subject%>">
      <INPUT TYPE="hidden" NAME="gu_folder" VALUE="<%=gu_folder%>">
      <INPUT TYPE="hidden" NAME="dt_before" VALUE="<%=dt_before%>">
      <INPUT TYPE="hidden" NAME="dt_after" VALUE="<%=dt_after%>">
      <INPUT TYPE="hidden" NAME="orderby" VALUE="<%=sOrderBy%>">

      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="msg_new_f.jsp?folder=drafts" TARGET="_blank" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="New Search"></TD>
        <TD VALIGN="middle"><A HREF="mailhome.jsp?screen_width=<%=iScreenWidth%>" CLASS="linkplain">New Search</A></TD>
      </TR>
      <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top Menu -->
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%

	String f150 = String.valueOf(floor(150f*fScreenRatio));
	String f320 = String.valueOf(floor(320f*fScreenRatio));

	String sFolder, sGuid, sId, sFrom, sTo, sSubject, sStrip, sSize, sPriority, sDateSent, sDateReceived;
	int iLen;
	BigDecimal pgMsg;
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
          <TD CLASS="tableheader" WIDTH="<%=f150%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (sOrderBy.equals("4") ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by sender"></A>&nbsp;<B>De</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=f320%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="javascript:sortBy(6);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (sOrderBy.equals("6") ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by subject"></A>&nbsp;<B>Asunto</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="javascript:sortBy(7);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (sOrderBy.equals("7") ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by received date"></A>&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="javascript:sortBy(9);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (sOrderBy.equals("9") ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by size"></A>&nbsp;<B>Size</B></TD>
        </TR>
<% if (sLuceneIndex.length()==0) {
     for (int m=0; m<iMsgs; m++) {
         sStrip = String.valueOf((m%2)+1);
         
         sGuid = oMsgs.getString(0, m);
         sId = oMsgs.getString(1, m);
         sPriority = oMsgs.getStringNull(2, m, "3");
         sFrom = MimeUtility.decodeText(oMsgs.getStringNull(3, m, ""));
         sTo = MimeUtility.decodeText(oMsgs.getStringNull(4, m, ""));
         sSubject = MimeUtility.decodeText(oMsgs.getStringNull(5, m, "<I>&lt;sin asunto&gt;</I>"));
	 sDateReceived = nullif(oMsgs.getDateShort(6, m));
	 sDateSent = nullif(oMsgs.getDateShort(7, m));
	 if (!oMsgs.isNull(8,m))
           iLen = oMsgs.getInt(8, m);
         else
           iLen = -1;

         if (iLen==-1)
           sSize = "";
         else if (iLen<=1024)
           sSize = "1Kb";
         else
           sSize = String.valueOf(iLen/1024) + "Kb";	          
	 
	 pgMsg = oMsgs.getDecimal(9,m);
	 
	 sFolder = oMsgs.getString(10,m);
	   
         out.write("<TR>");         
         out.write("<TD CLASS=\"strip\""+sStrip+">");
         if (sPriority.startsWith("1"))
           out.write ("<IMG SRC=\"../images/images/hipermail/highp.gif\" WIDTH=\"10\" HEIGHT=\"18\" BORDER=\"0\">");
         else if (sPriority.startsWith("5"))
           out.write ("<IMG SRC=\"../images/images/hipermail/lowp.gif\" WIDTH=\"10\" HEIGHT=\"18\" BORDER=\"0\">");         
         out.write("</TD>");
         out.write("<TD CLASS=\"strip\""+sStrip+"><FONT CLASS=\"textplain\">"+sFrom+"</FONT></TD>");
         out.write("<TD CLASS=\"strip\""+sStrip+"><A HREF=\"#\" CLASS=\"linkplain\" onclick=\"viewMessage('"+sFolder+"',"+pgMsg.toString()+",'"+sId+"')\">"+sSubject+"</FONT></TD>");
         out.write("<TD CLASS=\"strip\""+sStrip+"><FONT CLASS=\"textplain\">"+sDateReceived+"</FONT></TD>");
         out.write("<TD CLASS=\"strip\""+sStrip+" ALIGN=\"right\"><FONT CLASS=\"textplain\">"+sSize+"</FONT></TD>");
         out.write("</TR>\n");         

       } // next (m)
     } else {
       for (int m=0; m<iMsgs; m++) {
         sStrip = String.valueOf((m%2)+1);
         
         sGuid = aMsgs[m].getGuid();
         sPriority = "";
         sFrom = aMsgs[m].getAuthor();
         sSubject = aMsgs[m].getSubject();
	 sDateReceived = aMsgs[m].getDateCreatedAsString();
	 iLen = aMsgs[m].getSize();

         if (iLen==-1)
           sSize = "";
         else if (iLen<=1024)
           sSize = "1Kb";
         else
           sSize = String.valueOf(iLen/1024) + "Kb";	          
	 
	 pgMsg = new BigDecimal(aMsgs[m].getNumber());
	 
	 sFolder = aMsgs[m].getFolderName();
	   
         out.write("<TR>");         
         out.write("<TD CLASS=\"strip\""+sStrip+">");
         if (sPriority.startsWith("1"))
           out.write ("<IMG SRC=\"../images/images/hipermail/highp.gif\" WIDTH=\"10\" HEIGHT=\"18\" BORDER=\"0\">");
         else if (sPriority.startsWith("5"))
           out.write ("<IMG SRC=\"../images/images/hipermail/lowp.gif\" WIDTH=\"10\" HEIGHT=\"18\" BORDER=\"0\">");         
         out.write("</TD>");
         out.write("<TD CLASS=\"strip\""+sStrip+"><FONT CLASS=\"textplain\">"+sFrom+"</FONT></TD>");
         out.write("<TD CLASS=\"strip\""+sStrip+"><A HREF=\"#\" CLASS=\"linkplain\" onclick=\"viewMessage('"+sFolder+"',"+pgMsg.toString()+",'"+sGuid+"')\">"+sSubject+"</FONT></TD>");
         out.write("<TD CLASS=\"strip\""+sStrip+"><FONT CLASS=\"textplain\">"+sDateReceived+"</FONT></TD>");
         out.write("<TD CLASS=\"strip\""+sStrip+" ALIGN=\"right\"><FONT CLASS=\"textplain\">"+sSize+"</FONT></TD>");
         out.write("</TR>\n");         

       } // next (m)     
     }
%>  	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>