<%@ page import="java.text.NumberFormat,java.util.Date,java.text.SimpleDateFormat,java.net.URLDecoder,java.sql.Timestamp,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Atom" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sSkin = getCookie(request, "skin", "xp");

  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
  
  String sStrip;
  final String id_domain = getCookie(request,"domainid","");   
  final String gu_workarea = getCookie(request,"workarea","");
  final String tx_email = request.getParameter("tx_email").toLowerCase().trim();

  JDCConnection oConn = null;

  DBSubset oSent = new DBSubset (DB.k_jobs+" j,"+DB.k_job_atoms_archived+" a",
  															 "j."+DB.gu_job+",j."+DB.tl_job+","+DBBind.Functions.ISNULL+"(a."+DB.dt_execution+",j.dt_execution),a."+DB.id_status+",a."+DB.tx_log,
  															 "a."+DB.id_status+" NOT IN ("+String.valueOf(Atom.STATUS_ABORTED)+") AND "+
  															 "j."+DB.gu_job+"=a."+DB.gu_job+" AND "+DBBind.Functions.LOWER+"(a."+DB.tx_email+")=? AND j.gu_workarea=? ORDER BY 3 DESC", 500);

  DBSubset oTrack = new DBSubset (DB.k_jobs+" j,"+DB.k_job_atoms_tracking+" a",
  															 "j."+DB.gu_job+",j."+DB.tl_job+",a."+DB.dt_action+",a."+DB.ip_addr+",a."+DB.user_agent,
  															 "j."+DB.gu_job+"=a."+DB.gu_job+" AND "+DBBind.Functions.LOWER+"(a."+DB.tx_email+")=? AND j.gu_workarea=?", 500);

  DBSubset oClicks = new DBSubset (DB.k_jobs+" j,"+DB.k_job_atoms_clicks+" a,"+DB.k_urls+" u",
  															 "j."+DB.gu_job+",a."+DB.dt_action+",u."+DB.url_addr+",u."+DB.tx_title,
  															 "a."+DB.gu_url+"=u."+DB.gu_url+" AND j."+DB.gu_job+"=a."+DB.gu_job+" AND "+DBBind.Functions.LOWER+"(a."+DB.tx_email+")=? AND j."+DB.gu_workarea+"=?", 500);

  DBSubset oLists = new DBSubset (DB.k_lists+" l,"+DB.k_x_list_members+" m",
  															 "l."+DB.gu_list+",l."+DB.de_list+",m."+DB.bo_active,
  															 "l."+DB.tp_list+"<>4 AND l."+DB.gu_list+"=m."+DB.gu_list+" AND "+DBBind.Functions.LOWER+"(m."+DB.tx_email+")=? AND l."+DB.gu_workarea+"=? ORDER BY 2", 500);

  DBSubset oBlack = new DBSubset (DB.k_global_black_list, DB.dt_created,
  															  DBBind.Functions.LOWER+"("+DB.tx_email+")=? AND ("+DB.gu_workarea+"=? OR "+DB.gu_workarea+"='00000000000000000000000000000000') AND "+DB.id_domain+"=?",1);

  DBSubset oGrey = new DBSubset ("k_grey_list", DB.tx_email,
  															 DBBind.Functions.LOWER+"("+DB.tx_email+")=?",1);

  DBSubset oBlckl = new DBSubset (DB.k_lists+" l,"+DB.k_x_list_members+" m",
  															 "l."+DB.de_list+",m."+DB.dt_created+",l."+DB.gu_query,
  															 "l."+DB.tp_list+"=4 AND l."+DB.gu_list+"=m."+DB.gu_list+" AND "+DBBind.Functions.LOWER+"(m."+DB.tx_email+")=? AND l."+DB.gu_workarea+"=?", 500);

  int iSent=0, iClicks=0, iTrack=0, iLists=0, iBlck=0, iBlcl=0, iGrey=0;

  try  {
    oConn = GlobalDBBind.getConnection("email_followup",true);
    
    iSent = oSent.load(oConn, new Object[]{tx_email,gu_workarea});

    iClicks = oClicks.load(oConn, new Object[]{tx_email,gu_workarea});

    iTrack = oTrack.load(oConn, new Object[]{tx_email,gu_workarea});

    iLists = oLists.load(oConn, new Object[]{tx_email,gu_workarea});

    iBlck = oBlack.load(oConn, new Object[]{tx_email,gu_workarea,new Integer(id_domain)});

    iBlcl = oBlckl.load(oConn, new Object[]{tx_email,gu_workarea});

	  if (GlobalDBBind.exists(oConn,"k_grey_list","U")) {
	    iGrey = oGrey.load(oConn, new Object[]{tx_email});
	  }

    oConn.close("email_followup");

  } catch (NullPointerException sqle) {
    if (null!=oConn) if (!oConn.isClosed()) oConn.close("email_followup");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_back"));
    return;
  }	
	
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Messages sent to the email account</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
        
    function viewJob(id) {
      window.open("job_modify_f.jsp?gu_job=" + id, "modifyjob_"+ id, "width=700,height=500,menubar=no,toolbar=no,directories=no,scrollbars=yes");          
    }
    
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
	  <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1">Messages sent to the email account <%=tx_email%></FONT></TD></TR></TABLE>
      <DIV class="cxMnu1" style="width:100px"><DIV class="cxMnu2">
        <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> <A CLASS="linkplain" HREF="jobs_followup_stats.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>">Back</A></SPAN>
      </DIV></DIV>
      <TABLE SUMMARY="Totals">
      	<TR><TD><FONT CLASS="textstrong">Sent messages:</FONT></TD><TD><FONT CLASS="textplain"><%=String.valueOf(iSent)%></FONT></TD></TR>
        <TR><TD><FONT CLASS="textstrong">Opening confirmations:</FONT></TD><TD><FONT CLASS="textplain"><%=String.valueOf(iTrack)%></FONT></TD></TR>
        <TR><TD><FONT CLASS="textstrong">Clicks:</FONT></TD><TD><FONT CLASS="textplain"><%=String.valueOf(iClicks)%></FONT></TD></TR>
        <TR><TD><FONT CLASS="textstrong">Is it at black-list?</FONT></TD><TD><FONT CLASS="textplain"><% if (iBlck>0) out.write("Yes from "+oFmt.format(oBlack.getDate(0,0))); else out.write("No"); %></FONT></TD></TR>
        <TR><TD><FONT CLASS="textstrong">Is it at grey list?</FONT></TD><TD><FONT CLASS="textplain"><% if (iGrey>0) out.write("Yes"); else out.write("No"); %></FONT></TD></TR>
        <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE SUMMARY="Lists" CELLSPACING="1" CELLPADDING="1">
        <TR>
          <TD CLASS="tableheader" COLSPAN="4">&nbsp;<B>Lists to which it belongs (<%=iLists%>)</B></TD>
        </TR>
<% 
try {
for (int l=0; l<iLists; l++) {
     sStrip = String.valueOf((l%2)+1); %>
        <TR>
     	    <TD CLASS="strip<% out.write (sStrip); %>"><%=oLists.getStringNull(1,l,"n/a")%></TD>
     	    <TD CLASS="strip<% out.write (sStrip); %>"><%
     	    	if (oBlckl.find(2,oLists.getString(0,l))<0) {
     	        if (oLists.isNull(2,l))
     	          out.write("Active");
     	        else if (oLists.getShort(2,l)!=0)
     	          out.write("Active");
     	        else 
     	          out.write("Inactive");
     	      } else {
     	        if (oLists.isNull(2,l))
     	          out.write("Blocked");
     	        else if (oLists.getShort(2,l)!=0)
     	          out.write("Blocked");
     	        else 
     	          out.write("Inactive and blocked");
     	      }
     	    %></TD>
        </TR>
<% } %>      	
      </TABLE>
      <TABLE SUMMARY="Sent Newsletters" CELLSPACING="1" CELLPADDING="1">
        <TR>
          <TD CLASS="tableheader" COLSPAN="4">&nbsp;<B>Sent newsletters</B></TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="240">&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="96">&nbsp;<B>Status</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" WIDTH="140">&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Warnings</B></TD>
				</TR>
<%				for (int i=0; i<iSent; i++) { %>
            <TR HEIGHT="14">
              <TD CLASS="strip2" VALIGN="top"><A CLASS="linknodecor" HREF="#" onclick="viewJob('<%=oSent.getString(0,i)%>')"><%=oSent.getStringNull(1,i,"")%></A></TD>
<% if (oSent.isNull(3,i)) { %>
              <TD CLASS="strip2" VALIGN="top" ALIGN="center"></TD>
<% } else { %>
							<TD CLASS="strip2" ALIGN="center">
<%	 switch (oSent.getShort(3,i)) {
		   case Atom.STATUS_FINISHED:
		   case Atom.STATUS_RUNNING:
		   case Atom.STATUS_PENDING:
		     out.write("Sent");
				 break;
		   case Atom.STATUS_SUSPENDED:
		     out.write("Suspended");
				 break;
		   case Atom.STATUS_ABORTED:
		     out.write("Aborted");
				 break;
		   case Atom.STATUS_INTERRUPTED:
		     out.write("Interrumpted");
				 break;
	   }
   } %></TD>
              <TD CLASS="strip2" VALIGN="top" ALIGN="right"><% if (!oSent.isNull(2,i)) out.write(oFmt.format(oSent.getDate(2,i))); %></TD>
              <TD CLASS="strip2" ALIGN="center">&nbsp;<%=oSent.getStringNull(4,i,"")%></TD>
            </TR>
<% 
int iOpened = 0;
   for (int k=0; k<iTrack; k++) {
     if (oTrack.getString(0,k).equals(oSent.getString(0,i))) { %>
            <TR HEIGHT="14">
              <TD CLASS="strip1"></TD>
              <TD CLASS="strip1" VALIGN="top" ALIGN="center"><%=++iOpened==1 ? "Openings" : ""%></TD>
              <TD CLASS="strip1" VALIGN="top" ALIGN="right"><% if (!oTrack.isNull(2,k)) out.write(oFmt.format(oTrack.getDate(2,k))); %></TD>
              <TD CLASS="strip1">&nbsp;<%=oTrack.getStringNull(4,k,"")%></TD>
            </TR>
<% } } 
   int iClicked = 0;
   for (int c=0; c<iClicks; c++) {
     if (oClicks.getString(0,c).equals(oSent.getString(0,i))) { %>
            <TR HEIGHT="14">
              <TD CLASS="strip1"></TD>
              <TD CLASS="strip1" VALIGN="top" ALIGN="center"><%=++iClicked==1 ? "Clicks" : ""%></TD>
              <TD CLASS="strip1" VALIGN="top" ALIGN="right"><% if (!oClicks.isNull(1,c)) out.write(oFmt.format(oClicks.getDate(1,c))); %></TD>
              <TD CLASS="strip1"><A CLASS="linkplain" HREF="<%=oClicks.getStringNull(2,c,"")%>"><%=oClicks.getStringNull(3,c,"")%></A></TD>
            </TR>
<% } } 
     } // next(i)
} catch (Exception xcpt) {
  out.write(Gadgets.replace(com.knowgate.debug.StackTraceUtil.getStackTrace(xcpt),"\n","<BR>"));
}     
%>          	  
      </TABLE>
    </FORM>    
</BODY>
</HTML>