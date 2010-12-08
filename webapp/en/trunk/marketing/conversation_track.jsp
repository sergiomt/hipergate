<%@ page import="java.text.SimpleDateFormat,java.net.URLDecoder,java.util.LinkedList,java.util.ListIterator,java.io.IOException,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.workareas.FileSystemWorkArea,com.sun.syndication.feed.synd.*,com.knowgate.syndication.FeedEntry,com.knowgate.syndication.fetcher.FeedReader" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%

/*  
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String BASE_TABLE = "k_syndentries b";
  final String COLUMNS_LIST = "b.uri_entry,b.id_type,b.gu_feed,b.dt_published,b.dt_modified,b.gu_contact,b.nm_author,b.tl_entry,b.de_entry,b.url_addr,b.nu_influence";

  final String sLanguage = getNavigatorLanguage(request);  
  final String sSkin = getCookie(request, "skin", "xp");
  final String sBackTypeKey = GlobalDBBind.getProperty("backtypekey","");

  final String id_domain = getCookie(request,"domainid","");
  final String gu_workarea = getCookie(request,"workarea","");

  final String sFind = nullif(request.getParameter("find"),"");
  
  // **********************************************

  SimpleDateFormat oFmt = new SimpleDateFormat("EEE dd MMM HH:mm");
  JDCConnection oConn = null;  
  DBSubset oEntries = new DBSubset (BASE_TABLE, COLUMNS_LIST, DB.id_domain+"=? AND "+DB.gu_workarea+"=? AND "+DB.tx_query+"=? ORDER BY "+DB.dt_published+" DESC", 500);
  int iEntryCount = 0;
  LinkedList oNewEntries = new LinkedList<FeedEntry>();
  ListIterator oIter;
  SyndEntryImpl oEntr;
  int iMaxRows = 10;
  int iSkip = 0;

  try {  
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "10"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 100; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;
    
  if (iSkip<0) iSkip = 0;

  // **********************************************

  try {

    FileSystemWorkArea oFswa = new FileSystemWorkArea(GlobalDBBind.getProperties());
    oFswa.mkstorpath (Integer.parseInt(id_domain), gu_workarea, "cache"+File.separator+"syndication");
    FeedReader oFrdr = new FeedReader(oFswa.getstorpath(GlobalDBBind.getProperties(),Integer.parseInt(id_domain), gu_workarea)+File.separator+"cache"+File.separator+"syndication");
    
    if (sFind.length()>0) {
      SyndFeed oFeed = oFrdr.retrieveFeed("http://backtweets.com/search.rss?q="+Gadgets.URLEncode(sFind));
      
      oConn = GlobalDBBind.getConnection("entrylisting");  
      
      oEntries.setMaxRows(iMaxRows);
      iEntryCount = oEntries.load (oConn, new Object[]{new Integer(id_domain),gu_workarea,sFind}, iSkip);
      
	    oIter = oFeed.getEntries().listIterator();
		  while (oIter.hasNext()) {
		    oEntr = (SyndEntryImpl) oIter.next();
		    if (oEntries.find(0,oEntr.getUri())<0) {
		      Integer oInfluence = null;
		      if (sBackTypeKey.length()>0) {
		  			try {
		  			  String sScore = Gadgets.substrBetween(oFswa.readfilestr ("http://api.backtype.com/user/influencer_score.xml?user_name="+oEntr.getAuthor()+"&key="+sBackTypeKey, "UTF-8"), "<score>", "</score>");
		  			  if (null!=sScore) oInfluence = new Integer(sScore);
		        } catch (IOException ignore) {}
		      } // fi
		      oNewEntries.add(FeedEntry.store(oConn, Integer.parseInt(id_domain), gu_workarea, "backtype", null, sFind, oInfluence, oEntr));
		    } //fi
		  } // wend
      
      oConn.close("entrylisting"); 
    }
  }
  catch (Exception e) {  
    oEntries = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("entrylisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
    return;
  }
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
    <!--
       
      // ----------------------------------------------------
	
	      function findInstance() {
	  	  
	        var frm = document.forms[0];

			    if (hasForbiddenChars(frm.find.value)) {
			      alert ("The string sought contains invalid characters");
				    frm.find.focus();
				    return false;
			    }
	  
	        if (frm.find.value.length>0)
	          window.location = "conversation_track.jsp?id_domain=<%=id_domain%>&skip=0&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	        else
	          window.location = "conversation_track.jsp?id_domain=<%=id_domain%>&skip=0&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  
	      } // findInstance()
      
      // ------------------------------------------------------	

	      function setCombos() {
	        setCookie ("maxrows", "<%=iMaxRows%>");
	      } // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Conversations tracker</TITLE>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onClick="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Conversations tracker</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <TABLE SUMMARY="Top controls and filters" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD VALIGN="bottom" CLASS="textplain">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search">&nbsp;Search comments about URL&nbsp;</TD>
        <TD VALIGN="middle">
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" SIZE="30" VALUE="<%=sFind%>">
	        <A HREF="javascript:findInstance();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top controls and filters -->
      <TABLE SUMMARY="Data" CELLSPACING="0" CELLPADDING="2">
        <TR>
          <TD ALIGN="left" COLSPAN="4">
<%      if (sFind.length()>0) {

    	  // 20. Paint Next and Previous Links
    
    	  if (iEntryCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"conversation_track.jsp?id_domain=" + id_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oEntries.eof())
              out.write("            <A HREF=\"conversation_track.jsp?id_domain=" + id_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } } // fi (iEntryCount)
%>
          </TD>
        </TR>
        <TR>
          <TD COLSPAN="2" CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Influence</B></TD>
				</TR>
<%      if (sFind.length()>0) {
					oIter = oNewEntries.listIterator();
					while (oIter.hasNext()) {
					  FeedEntry oFntr = (FeedEntry) oIter.next();
					  oEntr = oFntr.getEntry();
%>            
            <TR>
              <TD CLASS="textplain">
              	<A HREF="<%=oEntr.getLink()%>" CLASS="linkplain"><B>@<%=oEntr.getAuthor()%></B></A>
              </TD>
              <TD CLASS="textplain">
              	<%=oEntr.getDescription().getValue()%>
              </TD>
              <TD CLASS="textplain">
              	<%=oFmt.format(oEntr.getPublishedDate())%>
              </TD>
              <TD CLASS="textplain" ALIGN="center">
              	<% if (!oFntr.isNull(DB.nu_influence)) out.write(String.valueOf(oFntr.getInt(DB.nu_influence))); %>
              </TD>
            </TR>
<%        } // wend
					for (int e=0; e<iEntryCount; e++) {
%>            
            <TR>
              <TD CLASS="textplain">
              	<A HREF="<%=oEntries.getStringNull(9,e,"#")%>" CLASS="linkplain"><B>@<%=oEntries.getStringNull(6,e,"#")%></B></A>
              </TD>
              <TD CLASS="textplain">
              	<%=oEntries.getStringNull(8,e,"#")%>
              </TD>
              <TD CLASS="textplain">
              	<%=oEntries.getDateFormated(3,e,oFmt)%>
              </TD>
              <TD CLASS="textplain" ALIGN="center">
              	<% if (!oEntries.isNull(10,e)) out.write(String.valueOf(oEntries.getInt(10,e))); %>
              </TD>
            </TR>
<%        } // next
				} %>
      </TABLE>
    </FORM>
</BODY>
</HTML>