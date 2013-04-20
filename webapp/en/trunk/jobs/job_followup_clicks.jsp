<%@ page import="java.util.ArrayList,java.util.Collections,java.util.Comparator,java.util.HashMap,java.util.Date,java.text.SimpleDateFormat,java.net.URLDecoder,java.sql.Timestamp,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Atom" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_mailing = request.getParameter("gu_mailing");
  String nm_mailing = "";
  
  JDCConnection oConn = null;
  DBSubset oClicks = new DBSubset ("k_job_atoms_clicks c, k_urls u, k_jobs j",
                                   "c.tx_email,c.dt_action,c.ip_addr,c.gu_url,u.url_addr,u.tx_title",
                                   "u.gu_workarea=? AND j.gu_job_group=? AND "+
                                   "c.gu_url=u.gu_url AND c.gu_job=j.gu_job ORDER BY 2 DESC", 1000);
  int nClicks = 0;
  HashMap<String,Integer> oUrlCounter = new HashMap<String,Integer>();
  ArrayList<java.util.Map.Entry<String, Integer>> aKeys = null;
  
  try {
    oConn = GlobalDBBind.getConnection("job_follwoup_clicks");
    nm_mailing = DBCommand.queryStr(oConn, "SELECT "+DB.nm_mailing+" FROM "+DB.k_adhoc_mailings+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_mailing+"='"+gu_mailing+"'");
    if (null==nm_mailing)
      nm_mailing = DBCommand.queryStr(oConn, "SELECT "+DB.nm_pageset+" FROM "+DB.k_pagesets+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_pageset+"='"+gu_mailing+"'");

    nClicks = oClicks.load(oConn, new Object[]{gu_workarea,gu_mailing});
		
		oConn.close("job_follwoup_clicks");

		for (int u=0; u<nClicks; u++) {
		  String sGuUrl = oClicks.getString(3,u);
		  if (oUrlCounter.containsKey(sGuUrl)) {
		    Integer iCount = oUrlCounter.get(sGuUrl);
		    oUrlCounter.remove(sGuUrl);
		    oUrlCounter.put(sGuUrl, new Integer(iCount.intValue()+1));
		  } else {
		    oUrlCounter.put(sGuUrl, new Integer(1));		  
		  }
		} // next

    aKeys = new ArrayList<java.util.Map.Entry<String, Integer>>(oUrlCounter.entrySet());
	  Collections.sort(aKeys, new Comparator<java.util.Map.Entry<String, Integer>>() {
			                      public int compare(java.util.Map.Entry<String, Integer> o1, java.util.Map.Entry<String, Integer> o2)
			                      { return o2.getValue().compareTo(o1.getValue());}});

  } catch (SQLException sqle) {  
    if (oConn!=null) if (!oConn.isClosed()) oConn.close("job_follwoup_clicks");
  }
  if (oConn==null) return;
  oConn=null;
%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Click-through rate</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1">Click-through rate <%=nm_mailing%></FONT></TD></TR></TABLE>  
			<A HREF="#" CLASS="linkplain" onclick="window.history.back()">Atr&aacute;s</A>
      <TABLE SUMMARY="Click-through rate by URL" CELLSPACING="1" CELLPADDING="1">
        <TR><TD CLASS="tableheader" COLSPAN="2">&nbsp;<B>Clicks por URL</B></TD></TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>URL</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" ALIGN="right"><B>Clicks</B></TD>
				</TR>
<%    String sStrip;      
      int u = 0;
      for (java.util.Map.Entry<String, Integer> k : aKeys) {
        sStrip = String.valueOf((u++%2)+1);
        String sUrl = oClicks.getString(4,oClicks.find(3,k.getKey()));
        out.write("<TR><TD CLASS=\"strip"+sStrip+"\">"+sUrl+"</TD><TD ALIGN=\"right\" CLASS=\"strip"+sStrip+"\">"+k.getValue()+"</TD></TR>\n");
      }
        out.write("<TR><TD CLASS=\"textplain\" ALIGN=\"right\"><B>Total</B></TD><TD CLASS=\"textplain\" ALIGN=\"right\"><B>"+String.valueOf(nClicks)+"</B></TD></TR>\n");
%>
		  </TABLE>
		  <BR>
      <TABLE SUMMARY="Click-through rate by recipient" CELLSPACING="1" CELLPADDING="1">
        <TR>
          <TD CLASS="tableheader" COLSPAN="4">&nbsp;<B>Clicks por direcci&oacute;n del destinatario</B></TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>e-mail</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Fecha y hora</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>URL</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>T&iacute;tulo</B></TD>
<%
	        String sTxEmail, sDtAction, sUrlAddr, sTitle;

	        for (int i=0; i<nClicks; i++) {
            sTxEmail = oClicks.getString(0,i);
            sDtAction = oFmt.format(oClicks.getDate(1,i));
            sUrlAddr = oClicks.getString(4,i);
            sTitle = Gadgets.removeChars(oClicks.getStringNull(5,i,""),"\n\r");
            sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right">&nbsp;<%=String.valueOf(i+1)%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">&nbsp;<%=sTxEmail%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sDtAction%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="<%=sUrlAddr%>" TARGET="_blank" TITLE="<%=sTitle%>"><%=sUrlAddr%></TD>              
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>    
</BODY>
</HTML>