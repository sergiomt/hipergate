<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:template match="/">
<xsl:for-each select="DutiesWorkReport/Duties/Duty">
    <TR HEIGHT="14">
      <TD CLASS="textplain"><A HREF="#" onclick="editDuty('{gu_duty}')"><xsl:value-of select="nm_duty"/></A></TD>
      <TD CLASS="textplain"><xsl:value-of select="dt_start"/></TD>
      <TD CLASS="textplain"><xsl:value-of select="dt_end"/></TD>
      <TD CLASS="textplain"><xsl:value-of select="pr_cost"/></TD>
      <TD CLASS="textplain"><xsl:value-of select="tx_status"/></TD>
      <TD CLASS="textplain" ALIGN="center"><xsl:value-of select="pct_complete"/>%</TD>
    </TR> 
</xsl:for-each>  
</xsl:template>
</xsl:stylesheet>