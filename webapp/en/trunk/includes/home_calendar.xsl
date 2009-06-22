<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_domain" />
<xsl:param name="param_workarea" />
<xsl:param name="param_user" />
<xsl:param name="param_windowstate" />
<xsl:param name="param_zone" />
<xsl:param name="param_language" />
<xsl:param name="param_skin" />

<xsl:template match="/">
  <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
    <TR>  
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"/></TD>
      <TD BACKGROUND="../images/images/graylinebottom.gif">
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"/></TD>
	    <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/{$param_skin}/tab/angle45_24x24.gif" style="display:block" WIDTH="24" HEIGHT="24" BORDER="0"/></TD>
	  </TR>
          <TR>
      	    <TD COLSPAN="2" CLASS="subtitle" ALIGN="left" VALIGN="middle">
      	      <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0"><TR CLASS="subtitle" VALIGN="middle">
      	          <TD>
	          <xsl:if test="$param_windowstate='NORMAL'">
      	            <A HREF="windowstate.jsp?gu_user={$param_user}&amp;nm_page=desktop.jsp&amp;nm_portlet=com.knowgate.http.portlets.CalendarTab&amp;gu_workarea={$param_workarea}&amp;nm_zone={$param_zone}&amp;id_state=MINIMIZED"><IMG SRC="../skins/{$param_skin}/tab/minimize12.gif" WIDTH="16" HEIGHT="16" BORDER="0" HSPACE="4" VSPACE="2"/></A>
	          </xsl:if>
	          <xsl:if test="$param_windowstate='MINIMIZED'">
      	            <A HREF="windowstate.jsp?gu_user={$param_user}&amp;nm_page=desktop.jsp&amp;nm_portlet=com.knowgate.http.portlets.CalendarTab&amp;gu_workarea={$param_workarea}&amp;nm_zone={$param_zone}&amp;id_state=NORMAL"><IMG SRC="../skins/{$param_skin}/tab/maximize12.gif" WIDTH="16" HEIGHT="16" BORDER="0" HSPACE="4" VSPACE="2"/></A>
	          </xsl:if>
	          </TD>
	          <TD BACKGROUND="../skins/{$param_skin}/tab/tabbackflat.gif" CLASS="subtitle">Calendar</TD>	          
	        </TR></TABLE>
      	    </TD>
          </TR>
        </TABLE>
      </TD>
      <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" CLASS="htmlbody"><IMG style="display:block" SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0"/></TD>
    </TR>
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"/></TD>
      <TD CLASS="menu1">
	<xsl:if test="$param_windowstate='NORMAL'">
        <TABLE CELLSPACING="8" BORDER="0">
          <TR>
            <TD ALIGN="middle">
              <IMG SRC="../images/images/addrbook/calendarxp32.gif" BORDER="0" ALT=""/>
            </TD>
            <TD ALIGN="left" VALIGN="middle">
              <TABLE>
                <TR>
                  <TD VALIGN="middle"><A HREF="#" onclick="window.open('../addrbook/todo_edit.jsp?gu_workarea={$param_workarea}',null,'directories=no,toolbar=no,menubar=no,width=500,height=400')" CLASS="linkplain">New Task</A></TD>
                  <TD VALIGN="middle"><A HREF="#" onclick="window.open('../addrbook/meeting_edit_f.htm?id_domain={$param_domain}&amp;gu_workarea={$param_workarea}&amp;gu_fellow={$param_user}', null, 'toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580')" CLASS="linkplain">New Activity</A></TD>
                </TR>
              </TABLE>
	    </TD>
	  </TR>
	  <TR>
	    <TD COLSPAN="2">
	      <FONT CLASS="textplain"><B>Today</B></FONT><BR/>
	      <xsl:for-each select="calendar/today/meeting">
	        <FONT CLASS="formplain">from <xsl:value-of select="dt_start"/> to <xsl:value-of select="dt_end"/></FONT>&#160;&#160;<A CLASS="linkplain" HREF="#" onClick="modifyMeeting('{gu_meeting}');return false"><xsl:value-of select="tx_meeting"/></A><BR/>     
	      </xsl:for-each>	      
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2">
	      <FONT CLASS="textplain"><B>Pending Tasks</B></FONT><BR/>
	      <TABLE>
	      <xsl:for-each select="calendar/todo/activity">
    	        <TR>
    	          <TD><FONT CLASS="textplain"><xsl:value-of select="od_priority"/></FONT></TD><TD><A CLASS="linkplain" HREF="#" onclick="window.open('../addrbook/todo_edit.jsp?gu_workarea={$param_workarea}&amp;gu_to_do={gu_to_do}',null,'directories=no,toolbar=no,menubar=no,width=500,height=400')"><xsl:value-of select="tl_to_do"/></A></TD>
    	          <TD><A HREF="#" onclick="window.open('../addrbook/todo_finish.jsp?gu_workarea={$param_workarea}&amp;gu_to_do={gu_to_do}',null,'directories=no,toolbar=no,menubar=no,width=500,height=400')" TITLE="Finalize Task"><IMG SRC="../images/images/checkmark16.gif" WIDTH="16" HEIGHT="16" BORDER="0"/></A></TD>
    	        </TR>
	      </xsl:for-each>	      
	      </TABLE>
            </TD>
          </TR>
        </TABLE>
        </xsl:if>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="3" BORDER="0"/></TD>
    </TR>
    <TR> 
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"/></TD>
      <TD CLASS="subtitle"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0"/></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0"/></TD>
    </TR>
    <TR>
      <TD WIDTH="2px" CLASS="subtitle"><IMG style="display:block" SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0"/></TD>
      <TD CLASS="htmlbody" BACKGROUND="../images/images/graylinefloor.gif"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG style="display:block" SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0"/></TD>
    </TR>
  </TABLE>
</xsl:template>
</xsl:stylesheet>