<%@ page import="java.util.ArrayList,java.util.TreeSet,java.util.Arrays,java.util.Date,java.text.NumberFormat,java.text.SimpleDateFormat,java.net.URLDecoder,java.sql.Timestamp,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets,com.knowgate.misc.NameValuePair,com.knowgate.scheduler.Atom" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="jobs_followup_graphs.jspf" %>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>Mailing Graphs</TITLE>
  <LINK REL="stylesheet" TYPE="text/css" HREF="../skins/xp/styles.css">
  <LINK REL="stylesheet" TYPE="text/css" HREF="../javascript/dijit/themes/tundra/tundra.css" />
  <LINK REL="stylesheet" TYPE="text/css" HREF="../javascript/dijit/themes/tundra/tundra_rtl.css" />
  <LINK REL="stylesheet" TYPE="text/css" HREF="../javascript/dijit/themes/tundra/Dialog.css" />
  <LINK REL="stylesheet" TYPE="text/css" HREF="../javascript/dijit/themes/tundra/Dialog_rtl.css" />
  <LINK REL="stylesheet" TYPE="text/css" HREF="../javascript/dijit/themes/tundra/Menu.css" />
  <LINK REL="stylesheet" TYPE="text/css" HREF="../javascript/dijit/themes/tundra/Menu_rtl.css" />
  <STYLE TYPE="text/css">
    body { 
	    font: 12px Verdana,Arial,Helvetica,clean,sans-serif;
      color:black;
    }
  </STYLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dojo/dojo.js" djConfig="parseOnLoad:true"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
		  dojo.require("dojo.html");
		  dojo.require("dojo._base.xhr");
      dojo.require("dijit.layout.BorderContainer");
  	  dojo.require("dijit.layout.TabContainer");
      dojo.require("dijit.layout.ContentPane");
      dojo.require("dojox.charting.Chart2D");
      dojo.require("dojox.charting.plot2d.Pie");
      dojo.require("dojox.charting.themes.IndigoNation");
			dojo.require("dojox.charting.action2d.Highlight");
      dojo.require("dojox.charting.action2d.MoveSlice");
      dojo.require("dojox.charting.action2d.Tooltip");

			var c;

      var bClickthroughRendered = false;
      var bReferersRendered = false;
      var bPopularUrls = false;
			var bPopularNewsletters = false;
			var bUnpopularNewsletters = false;
			var bByHour = false;
			
      function listSentNewsletters() {
	      var frm = document.forms[0];

        if (!isDate(frm.dt_from.value,"d") && frm.dt_from.value.length>0) {
	  			alert ("date is not valid");
	  			frm.dt_from.setFocus();
	  			return false;
				}

        if (!isDate(frm.dt_to.value,"d") && frm.dt_to.value.length>0) {
	  			alert ("date is not valid");
	  			frm.dt_to.setFocus();
	  			return false;
				}

      	document.location = "jobs_followup_graphs.jsp?selected="+getURLParam("selected")+"&subselected="+getURLParam("subselected")+"&dt_from="+frm.dt_from.value+"&dt_to="+frm.dt_to.value;      	
      }
      
      function showClickthrough() {
      	<% if (nClickDays>0) { %>
      	if (!bClickthroughRendered) {
      		bClickthroughRendered=true;
          c = new dojox.charting.Chart2D("clicksChart");
          c.addPlot("default", {
              type: "StackedAreas",
              tension: 3
          }).addAxis("x", {
              fixLower: "none",
              fixUpper: "none",
              labels: [<% for (int d=0; d<nClickDays; d++) out.write((d==0 ? "" : ",")+"{value: "+String.valueOf(d+1)+", text: \""+aCDates[d]+"\"}"); %>]
          }).addAxis("y", {
              vertical: true,
              fixLower: "none",
              fixUpper: "none",
              min: 0
          });
          c.setTheme(dojox.charting.themes.IndigoNation);
          c.addSeries("Visitors", [<% for (int v=0; v<nClickDays; v++) out.write((v==0 ? "" : ",")+String.valueOf(aVisits[v])); %>]);
          c.addSeries("Hits", [<% for (int c=0; c<nClickDays; c++) out.write((c==0 ? "" : ",")+String.valueOf(aClicks[c])); %>]);
          c.render();
          document.getElementById("clickthrough").replaceChild(document.getElementById("clicksChart"), document.getElementById("clickthrough_dummy"));
      	}
      <% } %>
      }
      
      function showReferers() {
      	if (!bReferersRendered) {
      		bReferersRendered = true;
          c = new dojox.charting.Chart2D("referersChart");
          c.setTheme(dojox.charting.themes.IndigoNation).addPlot("default", {
              type: "Pie",
              font: "normal normal 8pt Arial",
              fontColor: "black",
              labelOffset: -60,
              radius: 120
          });
          
          c.addSeries("Referers", [<%
            out.write("{y:"+String.valueOf(nOtherReferers)+",text:\"Otros\",stroke:\"black\",tooltip:\"Otros "+String.valueOf(nOtherReferers)+"%\"}");
            for (NameValuePair vp : aTopReferers)
              out.write(",{y:" + vp.getValue() + ",text:\"" + (Integer.parseInt(vp.getValue())>=5 ? vp.getName() : "") + "\",stroke:\"black\",tooltip:\"" + oMailings.getStringNull(3,oMailings.find(2,vp.getName()),vp.getName()).replace('"',' ') + " " + vp.getValue() + " %\"}");
          %>]);
          var a1 = new dojox.charting.action2d.MoveSlice(c, "default");
          var a2 = new dojox.charting.action2d.Highlight(c, "default");
          var a3 = new dojox.charting.action2d.Tooltip(c, "default");
          c.render();
          document.getElementById("referrers").replaceChild(document.getElementById("referersChart"), document.getElementById("referrers_dummy"));
      	}
      }
    
      function showPopularUrls() {
      	if (!bPopularUrls) {
      		bPopularUrls=true;
          c = new dojox.charting.Chart2D("urlsChart");
          c.addPlot("default", {
              type: "Bars",
              gap: 2
          }).addAxis("x", {
              fixLower: "none",
              fixUpper: "none"
          }).addAxis("y", {
              vertical: true,
              fixLower: "none",
              fixUpper: "none",
              min: 0,
              labels: [<% for (int d=0; d<nUrls; d++) out.write((d==0 ? "" : ",")+"{value: "+String.valueOf(d+1)+", text: \""+Gadgets.left(oUrls.getStringNull(2,d,"").replace('"',' '),96)+"\"}"); %>]
          });
          c.setTheme(dojox.charting.themes.IndigoNation);
          c.addSeries("URLs", [<% for (int v=0; v<nUrls; v++) out.write((v==0 ? "" : ",")+oUrls.get(3,v)); %>]);
          c.render();
          document.getElementById("urls").replaceChild(document.getElementById("urlsChart"), document.getElementById("urls_dummy"));
				}      	
      } // showPopularUrls

      function showPopularNewsletters() {
      	<% if (nDocCount>0) { %>
      	if (!bUnpopularNewsletters) {
      		bUnpopularNewsletters=true;
          c = new dojox.charting.Chart2D("popularChart");
          c.addPlot("default", {
              type: "Bars",
              gap: 2
          }).addAxis("x", {
              fixLower: "none",
              fixUpper: "none"
          }).addAxis("y", {
              vertical: true,
              fixLower: "none",
              fixUpper: "none",
              min: 0,
              labels: [<%
                          oMailings.sortByDesc(8);
                          int nTopDocs = nDocCount>10 ? 10 : nDocCount;
                          for (int d=0; d<nTopDocs; d++)
                            out.write((d==0 ? "" : ",")+"{value: "+String.valueOf(d+1)+", text: \""+Gadgets.left(oMailings.getStringNull(3,d,"").replace('"',' '),80)+"\"}"); %>]
          });
          c.setTheme(dojox.charting.themes.IndigoNation);
          c.addSeries("URLs", [<% for (int v=0; v<nTopDocs; v++) out.write((v==0 ? "" : ",")+String.valueOf(oMailings.getFloat(8,v))); %>]);
          c.render();
          document.getElementById("mostpopular").replaceChild(document.getElementById("popularChart"), document.getElementById("mostpopular_dummy"));      	
      	}      	
        <% } %>
      } // showPopularUrl

      function showUnpopularNewsletters() {
      	<% if (nDocCount>0) { %>
      	if (!bPopularNewsletters) {
      		bPopularNewsletters=true;
          c = new dojox.charting.Chart2D("unpopularChart");
          c.addPlot("default", {
              type: "Bars",
              gap: 2
          }).addAxis("x", {
              min: 0,
              max: 100
          }).addAxis("y", {
              vertical: true,
              fixLower: "none",
              fixUpper: "none",
              min: 0,
              labels: [<%
                          oMailings.sortBy(8);
                          int nBottomDocs = nDocCount>12 ? 12 : nDocCount;
                          boolean b1st = true;
                          for (int d=nBottomDocs-1; d>=0; d--) {
                            if (oMailings.getFloat(8,d)>0f) {
                              out.write((b1st ? "" : ",")+"{value: "+String.valueOf(nBottomDocs-d)+", text: \""+Gadgets.left(oMailings.getStringNull(3,d,"").replace('"',' '),80)+"\"}");
                              b1st = false;
                            }
                          } %>]
          });
          c.setTheme(dojox.charting.themes.IndigoNation);
          c.addSeries("URLs", [<% b1st = true;
                                  for (int v=nBottomDocs-1; v>=0; v--) {
                                    if (oMailings.getFloat(8,v)>0f) {
                                      out.write((b1st ? "" : ",")+String.valueOf(oMailings.getFloat(8,v)));
                              				b1st = false;
                                    }
                                  }
                              %>]);
          c.render();
          document.getElementById("lesspopular").replaceChild(document.getElementById("unpopularChart"), document.getElementById("lesspopular_dummy"));
      	}      	
        <% } %>
      } // showUnpopularUrls

  //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" CLASS="tundra">
	<%@ include file="../common/tabmenu.jspf" %>
  <FORM METHOD="post">
    <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1">Gr&aacute;ficas comparativas de env&iacute;os<% if (nullif(request.getParameter("dt_from")).length()>0) out.write("&nbsp;desde&nbsp;"+request.getParameter("dt_from")); %><% if (nullif(request.getParameter("dt_to")).length()>0) out.write("&nbsp;hasta&nbsp;"+request.getParameter("dt_to")); %></FONT></TD></TR></TABLE>  
    <TABLE SUMMARY="Top controls and filters" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
      	<TD>&nbsp;&nbsp;<IMG SRC="../images/images/wlink.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="URL"></TD>
        <TD COLSPAN="7">
        	<A HREF="urls_followup_list.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>" CLASS="linkplain">Listing by URL</A>
					&nbsp;&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/forums/emoticons/opentopic.gif" WIDTH="18" HEIGHT="12" BORDER="0" ALT="Newsletter">
          &nbsp;<A HREF="jobs_followup_stats.jsp?selected=5&subselected=4" CLASS="linkplain">Listing by newsletter</A>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
      	<TD><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Filter"></TD>
      	<TD CLASS="textplain">Change dates</TD>
      	<TD CLASS="textplain">from</TD>
      	<TD><INPUT TYPE="text" SIZE="10" NAME="dt_from" VALUE="<%=dt_from%>">&nbsp;<A HREF="javascript:showCalendar('dt_from')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Calendar"></A></TD>
      	<TD CLASS="textplain">to</TD>
      	<TD><INPUT TYPE="text" SIZE="10" NAME="dt_to" VALUE="<%=dt_to%>">&nbsp;<A HREF="javascript:showCalendar('dt_to')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Calendar"></A></TD>
      	<TD><A HREF="#" CLASS="linkplain" onclick="listSentNewsletters()">Filter</A></TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    </TABLE>
  </FORM>

  <DIV dojoType="dijit.layout.BorderContainer" style="width:980px;height:480px">
  <DIV dojoType="dijit.layout.TabContainer" region="center">
    <DIV dojoType="dijit.layout.ContentPane" title="Clickthrough" id="clickthrough">
      <TABLE CELLSPACING=2 CELLPADDING=2>
      	<TR>
      		<TD CLASS=textstrong>Clickthrough</FONT></TD>
      		<TD BGCOLOR=#93a4d0 CLASS=textplain><FONT COLOR=white>Hits</FONT></TD>
      		<TD BGCOLOR=#3b4152 CLASS=textplain><FONT COLOR=white>Unique visitors</FONT></TD>
        </TR>
      </TABLE>
    <DIV ID="clickthrough_dummy"></DIV></DIV>
    <DIV dojoType="dijit.layout.ContentPane" title="Referrers" id="referrers"><TABLE CELLSPACING=2 CELLPADDING=2><TR><TD CLASS=textstrong>Top referrers</FONT></TD></TR></TABLE><DIV ID="referrers_dummy"></DIV></DIV>
    <DIV dojoType="dijit.layout.ContentPane" title="URLs" id="urls"><TABLE CELLSPACING=2 CELLPADDING=2><TR><TD CLASS=textstrong>Clicks towards most visited URLs</FONT></TD></TR></TABLE><DIV ID="urls_dummy"></DIV></DIV>
    <DIV dojoType="dijit.layout.ContentPane" title="Most popular" id="mostpopular"><TABLE CELLSPACING=2 CELLPADDING=2><TR><TD CLASS=textstrong>Most popular newsletters (percentage)</FONT></TD></TR></TABLE><DIV ID="mostpopular_dummy"></DIV></DIV>
    <DIV dojoType="dijit.layout.ContentPane" title="Less popular" id="lesspopular"><TABLE CELLSPACING=2 CELLPADDING=2><TR><TD CLASS=textstrong>Less popular newsletters (percentage)</FONT></TD></TR></TABLE><DIV ID="lesspopular_dummy"></DIV></DIV>
  </DIV></DIV>
  <DIV ID="clicksChart" STYLE="width: 800px; height: 240px;"></DIV></DIV>
  <DIV ID="referersChart" STYLE="width: 600px; height: 270px;"></DIV>
  <DIV ID="urlsChart" STYLE="width: 960px; height: 400px;"></DIV> 
  <DIV ID="popularChart" STYLE="width: 960px; height: 400px;"></DIV>  
  <DIV ID="unpopularChart" STYLE="width: 960px; height: 400px;"></DIV>

</BODY>
<SCRIPT TYPE="text/javascript">
  <!--
      dojo.addOnLoad(function() {
      	showClickthrough(); 	
      	showReferers();
        <% if (nUrls>0) { %> showPopularUrls(); <% } else { %> document.getElementById("urlsChart").style.height="80px"; document.getElementById("urlsChart").innerHTML="<FONT class=textplain>No existen datos en la BB.DD. para esta gr&aacute;fica</FONT>"; <% } %>
      	showPopularNewsletters();
      	showUnpopularNewsletters();
      });
  //-->
</SCRIPT>
</HTML>