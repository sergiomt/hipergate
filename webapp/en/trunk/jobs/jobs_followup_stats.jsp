<%@ page import="java.util.Arrays,java.util.TreeSet,java.util.Date,java.text.NumberFormat,java.text.SimpleDateFormat,java.net.URLDecoder,java.sql.Timestamp,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Atom,com.knowgate.hipermail.Statistics" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="jobs_followup_stats.jspf" %>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Statistics</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--

      function listSentNewsletters() {
	      var frm = document.forms[0];

        if (!isDate(frm.dt_from.value,"d") && frm.dt_from.value.length>0) {
	  			alert ("La fecha no es valida");
	  			frm.dt_from.setFocus();
	  			return false;
				}

        if (!isDate(frm.dt_to.value,"d") && frm.dt_to.value.length>0) {
	  			alert ("La fecha no es valida");
	  			frm.dt_to.setFocus();
	  			return false;
				}

      	document.location = "jobs_followup_stats.jsp?selected="+getURLParam("selected")+"&subselected="+getURLParam("subselected")+"&dt_from="+frm.dt_from.value+"&dt_to="+frm.dt_to.value;      	
      }
  
		  function listStats(docid) {
	      document.location = "../jobs/job_followup_stats_xls.jsp?gu_job_group="+docid;
	    } // listStats
	  
	  var collecting = false;

    function reloadPage() {
      if (collecting.readyState == 4) {
        if (collecting.status == 200) {
          document.location.reload();
        }
      }
    } // reloadPage

	  function collect(docid) {
<%    for (int i=0; i<nDocCount; i++) out.write("	    document.images[\"i"+oMailings.getString(0,i)+"\"].src=\"../images/images/spacer.gif\";\n"); %>
      document.images["i"+docid].src = "../images/images/processing.gif";
      collecting = createXMLHttpRequest();
	    collecting.onreadystatechange = reloadPage;
	    collecting.open("GET", "jobs_collect_stats.jsp?gu_job_group="+docid, true);
	    collecting.send(null);      
	  }
	  
	  function inspectEmail() {
	    var frm = document.forms[0];

	    if (!check_email(frm.tx_email.value)) {
	      alert ("The e-mail address is not valid");
	      frm.tx_email.focus();
	      return false;
	    }
	    
	    document.forms[0].action = "email_followup.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>";
	    document.forms[0].submit();
	    
	    return true;
	  }
  //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
	  <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1">Statistics<% if (nullif(request.getParameter("dt_from")).length()>0) out.write("&nbsp;desde&nbsp;"+request.getParameter("dt_from")); %><% if (nullif(request.getParameter("dt_to")).length()>0) out.write("&nbsp;hasta&nbsp;"+request.getParameter("dt_to")); %></FONT></TD></TR></TABLE>  
      <TABLE SUMMARY="Top controls and filters" CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
        	<TD>&nbsp;&nbsp;<IMG SRC="../images/images/wlink.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="URL"></TD>
          <TD COLSPAN="7">
          	<A HREF="urls_followup_list.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>" CLASS="linkplain">Listingb y URL</A>
          	&nbsp;&nbsp;&nbsp;&nbsp;
          	<IMG SRC="../images/images/jobs/statistics16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Graficas">&nbsp;<A HREF="jobs_followup_graphs.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>" CLASS="linkplain">Charts</A>
          </TD>
        </TR>
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <!--
        <TR>
        	<TD><IMG SRC="../images/images/excel16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Excel"></TD>
        	<TD><A HREF="#" CLASS="linkplain">Mostrar como Excel</A></TD>
        </TR>
        -->
        <TR>
        	<TD><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Filter"></TD>
        	<TD CLASS="textplain">Change dates</TD>
        	<TD CLASS="textplain">from</TD>
        	<TD><INPUT TYPE="text" SIZE="10" NAME="dt_from" VALUE="<%=dt_from%>">&nbsp;<A HREF="javascript:showCalendar('dt_from')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Calendar"></A></TD>
        	<TD CLASS="textplain">to</TD>
        	<TD><INPUT TYPE="text" SIZE="10" NAME="dt_to" VALUE="<%=dt_to%>">&nbsp;<A HREF="javascript:showCalendar('dt_to')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Calendar"></A></TD>
        	<TD><A HREF="#" CLASS="linkplain" onclick="listSentNewsletters()">Filter</A></TD>
        </TR>
        <TR>
        	<TD></TD>
        	<TD CLASS="textplain">Search email</TD>
        	<TD></TD>
        	<TD CLASS="textplain" colspan="3"><INPUT TYPE="text" SIZE="40" NAME="tx_email"></TD>
        	<TD><A HREF="#" CLASS="linkplain" onclick="inspectEmail()">Search</A></TD>
        </TR>
        <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE SUMMARY="Totals">
      	<TR><TD><FONT CLASS="textstrong">Sent newsletters:</FONT></TD><TD><FONT CLASS="textplain"><%=String.valueOf(nDocCount)%></FONT></TD><TD COLSPAN="2"></TD></TR>
        <TR><TD><FONT CLASS="textstrong">Total messages sent</FONT></TD><TD><FONT CLASS="textplain"><%=String.valueOf(nTotalMsgsSent)%></FONT></TD><TD COLSPAN="2"></TD></TR>
        <TR><TD><FONT CLASS="textstrong">Unique recipients</FONT></TD><TD><FONT CLASS="textplain"><%=String.valueOf(nDistinctRecipients)%></FONT></TD><TD><FONT CLASS="textstrong">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Black-List:</FONT></TD><TD><FONT CLASS="textplain"><%=String.valueOf(nBlackListed)%></FONT></TD></TR>
        <TR><TD><FONT CLASS="textstrong">Confirmations:</FONT></TD><TD><FONT CLASS="textplain"><%=String.valueOf(nTotalMsgsOpen)%></FONT></TD><TD><FONT CLASS="textstrong">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Grey-List:</FONT></TD><TD><FONT CLASS="textplain"><%=String.valueOf(nGreyListed)%></FONT></TD></TR>
        <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
<% if (nMsgsByDay>0) { %>
      <TABLE SUMMARY="Messages by day" BORDER="0" CELLSPACING="1" CELLPADDING="1">
        <TR>
          <TD CLASS="tableheader" COLSPAN="<%=String.valueOf(nMsgsByDay)%>"><B>Daily figures for last month</B></TD>
        </TR>
      	<TR>
          <TD CLASS="tableheader"></TD>
<% for (int d=0; d<nMsgsByDay; d++) {
     out.write("<TD CLASS=\"textstrong\" BACKGROUND=\"../skins/"+sSkin+"/tablehead.gif\">"+aDates[d]+"</TD>");
   } %>
        </TR>
<!--
      	<TR>
          <TD CLASS="textstrong">Newsletters</TD>
<% for (int d=0; d<nMsgsByDay; d++) {
       out.write("<TD CLASS=\"textplain\" ALIGN=\"center\">"+aNuDoc[d]+"</TD>");
   } %>
        </TR>
-->
      	<TR>
          <TD CLASS="textstrong">Enviados</TD>
<% for (int d=0; d<nMsgsByDay; d++) {
     out.write("<TD CLASS=\"textplain\" ALIGN=\"center\">"+aNuMsg[d]+"</TD>");
   } %>
        </TR>
        <TR><TD COLSPAN="<%=String.valueOf(nMsgsByDay+1)%>" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
<% }
   if (nReadedByHour>0) {
     int nTotalReadByHour = Integer.parseInt(oReadedByHour.sum(0).toString()); %>
      <TABLE SUMMARY="Messages by hour" BORDER="0" CELLSPACING="1" CELLPADDING="1">
        <TR>
          <TD CLASS="tableheader" COLSPAN="24"><B>Messages readed by hour</B></TD>
        </TR>
      	<TR>
<% int iHourSlice;
   for (int h=7; h<19; h++)
     out.write("<TD CLASS=\"textstrong\" BACKGROUND=\"../skins/"+sSkin+"/tablehead.gif\">"+(h<10 ? "0" : "")+String.valueOf(h)+":00-"+(h<10 ? "0" : "")+String.valueOf(h)+":59</TD>"); %>
        </TR><TR>
<% iHourSlice=-1;
   for (double h=7d; h<19d; h++) {
     for (int s=0; s<oReadedByHour.getRowCount(); s++) { if (oReadedByHour.getDouble(1,s)==h) { iHourSlice=s; break; } } // next
     if (-1==iHourSlice)
       out.write("<TD CLASS=\"textplain\" ALIGN=\"center\">0</TD>");
     else
       out.write("<TD CLASS=\"textplain\" ALIGN=\"center\">"+String.valueOf(oReadedByHour.getInt(0,iHourSlice))+"&nbsp;("+String.valueOf(((10000*oReadedByHour.getInt(0,iHourSlice))/nTotalReadByHour)/100f)+"%)</TD>");
   } %>
        </TR><TR> 
<% for (int h=19; h<=23; h++)
     out.write("<TD CLASS=\"textstrong\" BACKGROUND=\"../skins/"+sSkin+"/tablehead.gif\">"+String.valueOf(h)+":00-"+String.valueOf(h)+":59</TD>");
   for (int h=0; h<7; h++)
     out.write("<TD CLASS=\"textstrong\" BACKGROUND=\"../skins/"+sSkin+"/tablehead.gif\">0"+String.valueOf(h)+":00-0"+String.valueOf(h)+":59</TD>"); %>
        </TR><TR>
<% iHourSlice=-1;
   for (double h=19d; h<=23d; h++) {
     for (int s=0; s<oReadedByHour.getRowCount(); s++) { if (oReadedByHour.getDouble(1,s)==h) { iHourSlice=s; break; } } // next
     if (-1==iHourSlice)
       out.write("<TD CLASS=\"textplain\" ALIGN=\"center\">0</TD>");
     else
       out.write("<TD CLASS=\"textplain\" ALIGN=\"center\">"+String.valueOf(oReadedByHour.getInt(0,iHourSlice))+"&nbsp;("+String.valueOf(((10000*oReadedByHour.getInt(0,iHourSlice))/nTotalReadByHour)/100f)+"%)</TD>");
   }
   for (double h=0d; h<7d; h++) {
     for (int s=0; s<oReadedByHour.getRowCount(); s++) { if (oReadedByHour.getDouble(1,s)==h) { iHourSlice=s; break; } } // next
     if (-1==iHourSlice)
       out.write("<TD CLASS=\"textplain\" ALIGN=\"center\">0</TD>");
     else
       out.write("<TD CLASS=\"textplain\" ALIGN=\"center\">"+String.valueOf(oReadedByHour.getInt(0,iHourSlice))+"&nbsp;("+String.valueOf(((10000*oReadedByHour.getInt(0,iHourSlice))/nTotalReadByHour)/100f)+"%)</TD>");
   }
%>      </TR>
        <TR><TD COLSPAN="12" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
<% }
   if (nUserAgents>0) { %>
      <TABLE SUMMARY="User Agents" CELLSPACING="2" CELLPADDING="2">
        <TR>
          <TD CLASS="tableheader" COLSPAN="5">&nbsp;<B>User-Agents</B></TD>
        </TR>
<%
		 NumberFormat oPctFmt = NumberFormat.getPercentInstance();
		 oPctFmt.setMaximumFractionDigits(2);
		 float nAgents = 0f;
     for (int u=0; u<nUserAgents; u++) nAgents += (float) oUserAgents.getInt(1,u);
     for (int u=0; u<nUserAgents; u=u+2) {
       out.write("<TR>");
       out.write("<TD CLASS=\"textsmall\">"+oUserAgents.getString(0,u)+"</TD><TD ALIGN=\"right\" CLASS=\"formplain\">"+oPctFmt.format(((float)oUserAgents.getInt(1,u))/nAgents)+"</TD>");
       if (u+1<nUserAgents)
         out.write("<TD WIDTH=\"20\"></TD><TD CLASS=\"textsmall\">"+oUserAgents.getString(0,u+1)+"</TD><TD ALIGN=\"right\" CLASS=\"formplain\">"+oPctFmt.format(((float)oUserAgents.getInt(1,u+1))/nAgents)+"</TD>");
       else
       	 out.write("<TD COLSPAN=\"3\"></TD>");
       out.write("</TR>");
     }
%>
        <TR><TD COLSPAN="5" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
<% } %>

      <TABLE SUMMARY="Sent Newsletters" CELLSPACING="1" CELLPADDING="1">
        <TR>
          <TD CLASS="tableheader" COLSPAN="6">&nbsp;<B>Sent newsletters</B></TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Num</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Date*</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Subject</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Sent</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Opened**</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Clicks</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Interest</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Popularity</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
<%
	        float fMaxInt = 0f;
	        float fTotInt = 0f;
	        
	        for (int i=0; i<nDocCount; i++) {
	          float fInt = (100f*oMailings.getInt(5,i)) / (float) oMailings.getInt(4,i);
	          fTotInt += fInt;
	          if (fInt>fMaxInt) fMaxInt = fInt;
					}
					
	        int iCheckSum1=0,iCheckSum2=0,iInterest;	         
	        String sInstId, sInstNm, sInstNu, sInstTx, sNuMsgs, sNuOpen, sNuClicks, sInstDt, sStrip;
	    
	        for (int i=0; i<nDocCount; i++) {
            sInstId = oMailings.getString(0,i);
            
            if (oMailings.getInt(1,i)==-1)
              sInstNu = "";
            else
              sInstNu = String.valueOf(oMailings.getInt(1,i));
            
            sInstNm = oMailings.getStringNull(2,i,"");
            sInstTx = Gadgets.left(oMailings.getStringHtml(3,i,""),80);
						iCheckSum1+=oMailings.getInt(4,i);
						sNuMsgs = String.valueOf(oMailings.getInt(4,i));
						iCheckSum2+=oMailings.getInt(5,i);
						sNuOpen = String.valueOf(oMailings.getInt(5,i));

						if (oMailings.isNull(7,i))
						  sNuClicks = "n/d";
						else
							sNuClicks = "<A HREF=\"job_followup_clicks.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_mailing="+sInstId+"&selected="+sel+"&subselected="+sub+"\">"+String.valueOf(oMailings.getInt(7,i))+"</A>";

            if (oMailings.isNull(6,i))
              sInstDt = "";
            else
            	sInstDt = oMailings.getDateShort(6,i);

            sStrip = String.valueOf((i%2)+1);
						
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">&nbsp;<%=sInstNu%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sInstDt%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" onclick="listStats('<%=sInstId%>')"><%=sInstNm%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sInstTx%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right">&nbsp;<%=sNuMsgs%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right">&nbsp;<%=sNuOpen%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right">&nbsp;<%=sNuClicks%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right">&nbsp;<% if (oMailings.getInt(4,i)>0) out.write(String.valueOf((100*oMailings.getInt(5,i))/oMailings.getInt(4,i))); %>%</TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right">&nbsp;<% if (oMailings.getInt(4,i)>0) out.write(String.valueOf((int)(((100f*oMailings.getInt(5,i))/(float)oMailings.getInt(4,i)/fMaxInt)*100f))); %>&nbsp;/&nbsp;100</TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><A HREF="#" onclick="collect('<%=sInstId%>')" TITLE="Actualizar Estadisticas"><IMG NAME="i<%=sInstId%>" ID="i<%=sInstId%>" SRC="../images/images/processing16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Actualizar Estadisticas"></A></TD>
              
            </TR>
<%        } // next(i) %>          	  
            <TR HEIGHT="14">
              <TD CLASS="strip1"></TD>
              <TD CLASS="strip1" COLSPAN="2">* La fecha se establece manualmente<BR/>por consiguiente puede no corresponderse<BR/>exactamente con la del envio real</TD>
              <TD CLASS="strip1" ALIGN="right" VALIGN="top"><B>Total</B></TD>
              <TD CLASS="strip1" ALIGN="right" VALIGN="top"><B><%=String.valueOf(iCheckSum1)%></B></TD>
              <TD CLASS="strip1" ALIGN="right" VALIGN="top"><B><%=String.valueOf(iCheckSum2)%></B></TD>
              <TD CLASS="strip1" ALIGN="right" VALIGN="top"><B>&Mu;<%=String.valueOf((int)(fTotInt/(float)nDocCount))%>%</B></TD>
              <TD></TD>
            </TR>
      </TABLE>
    </FORM>    
</BODY>
</HTML>