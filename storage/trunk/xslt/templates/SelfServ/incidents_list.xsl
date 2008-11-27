<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_domain" />
<xsl:param name="param_workarea" />
<xsl:param name="param_user" />
<xsl:template match="/">
<TABLE SUMMARY="Incidents Listing" CELLSPACING="0" CELLPADDING="0" BORDER="0">
  <xsl:for-each select="bugs/bug">
    <xsl:variable name="ROWNUM" select="position()"/>
    <TR>
      <TD CLASS="Strip{$ROWNUM mod 2}"><xsl:value-of select="pg_bug"/></TD>
      <TD CLASS="Strip{$ROWNUM mod 2}"><xsl:value-of select="tx_status"/></TD>
      <TD CLASS="Strip{$ROWNUM mod 2}"><xsl:value-of select="od_priority"/></TD>
      <TD CLASS="Strip{$ROWNUM mod 2}"><xsl:value-of select="dt_created"/></TD>
      <TD CLASS="Strip{$ROWNUM mod 2}"><xsl:value-of select="tl_bug"/></TD>
    </TR>
  </xsl:for-each>
</TABLE>
</xsl:template>
</xsl:stylesheet>