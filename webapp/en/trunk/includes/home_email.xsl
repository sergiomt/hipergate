<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_domain" />
<xsl:param name="param_workarea" />
<xsl:param name="param_user" />
<xsl:param name="param_windowstate" />
<xsl:param name="param_zone" />
<xsl:param name="param_language" />
<xsl:param name="param_skin" />
<xsl:param name="param_account" />

<xsl:template match="/">
  <TABLE SUMMARY="Portlet Outer Frame" CELLSPACING="0" CELLPADDING="0" BORDER="0">
    <TR>  
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0"/></TD>
      <TD BACKGROUND="../images/images/graylinebottom.gif">
        <TABLE SUMMARY="Top Tab" CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0"/></TD>
	          <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/{$param_skin}/tab/angle45_24x24.gif" style="display:block" WIDTH="24" HEIGHT="24" BORDER="0"/></TD>
	        </TR>
          <TR>
      	    <TD COLSPAN="2" CLASS="subtitle" ALIGN="left" VALIGN="middle">
      	      <TABLE SUMMARY="Max/Min Buttons" CELLSPACING="0" CELLPADDING="0" BORDER="0"><TR CLASS="subtitle" VALIGN="middle">
      	        <TD>
	              <xsl:if test="$param_windowstate='NORMAL'">
      	            <A HREF="windowstate.jsp?gu_user={$param_user}&amp;nm_page=desktop.jsp&amp;nm_portlet=com.knowgate.http.portlets.NewMail&amp;gu_workarea={$param_workarea}&amp;nm_zone={$param_zone}&amp;id_state=MINIMIZED"><IMG SRC="../skins/{$param_skin}/tab/minimize12.gif" WIDTH="16" HEIGHT="16" BORDER="0" HSPACE="4" VSPACE="2"/></A>
	              </xsl:if>
	              <xsl:if test="$param_windowstate='MINIMIZED'">
      	            <A HREF="windowstate.jsp?gu_user={$param_user}&amp;nm_page=desktop.jsp&amp;nm_portlet=com.knowgate.http.portlets.NewMail&amp;gu_workarea={$param_workarea}&amp;nm_zone={$param_zone}&amp;id_state=NORMAL"><IMG SRC="../skins/{$param_skin}/tab/maximize12.gif" WIDTH="16" HEIGHT="16" BORDER="0" HSPACE="4" VSPACE="2"/></A>
	              </xsl:if>
	              </TD>
	              <TD BACKGROUND="../skins/{$param_skin}/tab/tabbackflat.gif" CLASS="subtitle">e-mail</TD>	          
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
        <TABLE SUMMARY="Recent messages List" CELLSPACING="8" BORDER="0">
          <TR>
            <TD ALIGN="left" VALIGN="middle">
              <TABLE SUMMARY="New Message" BORDER="0">
                <TR>
                  <TD VALIGN="middle"><IMG SRC="../images/images/hipermail/inbox.gif" BORDER="0" ALT=""/></TD>
                  <TD VALIGN="middle" NOWRAP="nowrap"><A HREF="#" onclick="window.open('../hipermail/msg_new_f.jsp?folder=drafts')" CLASS="linkplain">New Message</A></TD>
                </TR>
              </TABLE>
	          </TD>
	        </TR>
	        <TR>
	          <TD>
	          <xsl:if test="$param_account=''">         
	            <A HREF="#" CLASS="linkplain" onclick="window.open('../hipermail/account_edit.jsp?id_user={$param_user}&amp;gu_account={$param_account}&amp;bo_popup=true','createmailaccount','toolbar=no,directories=no,menubar=no,resizable=yes,width=560,height=600')">Create New Account</A>
            </xsl:if>
	          <xsl:for-each select="folder/messages/msg">
	            <A HREF="#" CLASS="linkplain" onclick="window.open('../hipermail/msg_view.jsp?gu_account={$param_account}&amp;nm_folder=inbox&amp;id_msg={id}&amp;nu_msg={num}','viewmail{num}')"><xsl:value-of select="subject"/></A><BR/>
	          </xsl:for-each>
	          <xsl:if test="$param_account!=''">	              
	            <A HREF="../hipermail/mail_top_f.htm?goinbox=true&amp;selected=1&amp;subselected=0" CLASS="linkplain"><B>all...</B></A>
            </xsl:if>
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