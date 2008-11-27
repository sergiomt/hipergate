<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>

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
	  <TD class="Breadcrumb" align="left">Fundacion Campus Comillas > Comunidades > Foros</TD>
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
	  <H1>Preguntas frecuentes</H1>
	  <BR/>
	    <TABLE width="100%">
	    <xsl:for-each select="Forums/NewsMessages/NewsMessage">
	    <xsl:variable name="MSGNUM" select="position()"/>
	    <TR>
	      <TD class="Strip{$MSGNUM mod 2}">
	        <b><xsl:value-of select="tx_subject" disable-output-escaping="no"/></b>
	        <BR/>
		      <xsl:value-of select="tx_msg" disable-output-escaping="no"/>
	      </TD>
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