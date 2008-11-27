<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_events_es" />
<xsl:include href="left_menu.xsl" />
<xsl:template match="/">

<TABLE class="BodyTable" cellspacing="0" cellpadding="0" border="0">
  <TR>
    <TD class="Crumb" colspan="3">
      <TABLE width="100%" cellspacing="0" cellpadding="0" border="0" align="left" summary="you are here">
	<TR>
	  <TD width="100%" bgcolor="#c9282d" height="1"></TD>
        </TR>
	<TR>
	  <TD class="Breadcrumb" align="left">Fundacion Campus Comillas > Foros</TD>
        </TR>
	<TR>
	  <TD width="100%" bgcolor="white" height="1"></TD>
        </TR>
	<TR>
	  <TD width="100%" bgcolor="#c9282d" height="1"></TD>
        </TR>
      </TABLE>
    </TD>
  </TR>
</TABLE>
<TABLE class="BodyTable" cellspacing="0" cellpadding="0" border="0">
  <TR>
	<xsl:call-template name="leftmenu"/>
	<TD class="mainColumn">
	  <DIV id="mainColumnRound">
	  <H1>Foros</H1>
	  <TABLE class="mainContents" summary="Newsgroups" width="100%" border="0" cellpadding="2" cellspacing="0">
	    <xsl:for-each select="Forums/NewsGroups/NewsGroup">
	      <xsl:variable name="ROWNUM" select="position()"/>
	        <xsl:if test="labels/label[@id_language='es']!='EVENTOS-ES'">
    	      <TR>
      	 	    <TD colspan="2" class="Strip{$ROWNUM mod 2}">&#149;&#160;<A href="#" onclick="forumList('{gu_newsgrp}',{bo_active})"><xsl:value-of select="labels/label[@id_language='es']" disable-output-escaping="no"/></A></TD>
    	      </TR>
    	      <xsl:if test="string-length(de_newsgrp)!=0">
      	      <TR>
        	      <TD width="20" style="Strip{$ROWNUM mod 2}"><IMG src="/images/s.gif" width="20" height="15" border="0" alt=""/></TD>
        	      <TD width="100%" style="Strip{$ROWNUM mod 2}" class="mini" valign="top"><xsl:value-of select="de_newsgrp" disable-output-escaping="no"/></TD>
      	      </TR>
    	      </xsl:if>  
    	    </xsl:if>  
  	    </xsl:for-each>
	  </TABLE>
	  <TABLE summary="Recent Messages" width="100%" border="0" cellpadding="3" cellspacing="0">
	    <TR>
	      <TD class="StripHead">Asunto</TD>
        <TD class="StripHead">Remitente</TD>
	      <TD class="StripHead">Fecha</TD>
	      <TD class="StripHead">Respuestas</TD>
      </TR>
	    <xsl:for-each select="Forums/NewsMessages/NewsMessage">  
	    <xsl:variable name="MSGNUM" select="position()"/>
	    <TR>
	      <TD class="Strip{$MSGNUM mod 2}"><A href="forum_msg_view.jsp?gu_message={gu_msg}"><xsl:value-of select="tx_subject" disable-output-escaping="no"/></A></TD>
        <TD class="Strip{$MSGNUM mod 2}"><xsl:value-of select="nm_author" disable-output-escaping="no"/></TD>
	      <TD class="Strip{$MSGNUM mod 2}"><xsl:value-of select="dt_published" disable-output-escaping="no"/></TD>
	      <TD class="Strip{$MSGNUM mod 2}"><xsl:value-of select="string(number(nu_thread_msgs)-1)" disable-output-escaping="no"/></TD>
     </TR>
  	 </xsl:for-each>
	  </TABLE>
	  </DIV>
	</TD>

  </TR>
</TABLE>
<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript"><![CDATA[Rounded("div#mainColumnRound","black","white");]]></SCRIPT>

</xsl:template>

</xsl:stylesheet>