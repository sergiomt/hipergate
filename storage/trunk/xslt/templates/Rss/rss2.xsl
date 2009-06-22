<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="4.0" media-type="text/xml" omit-xml-declaration="no"/>
<xsl:param name="param_language" />
<xsl:param name="param_basehref" />
<xsl:template match="/">
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <channel>
    <title><xsl:value-of select="Journal/NewsGroup/labels/label[@id_language=$param_language]" /></title> 
    <link><xsl:value-of select="$param_basehref" /></link>
    <description><xsl:value-of select="Journal/NewsGroup/de_newsgroup" /></description>
    <dc:language><xsl:value-of select="$param_language" /></dc:language>
    <dc:date><xsl:value-of select="Journal/NewsGroup/dt_last_update" /></dc:date>
    <sy:updatePeriod>hourly</sy:updatePeriod>
    <sy:updateFrequency>1</sy:updateFrequency>
    <sy:updateBase>2000-01-01T12:00+00:00</sy:updateBase>
		<xsl:for-each select="Journal/NewsMessages/NewsMessage">
	    <item>
	      <title><xsl:value-of select="tx_subject" /></title>
	      <link><xsl:value-of select="$param_basehref" /><xsl:value-of select="gu_msg" />.html</link>
	      <description><![CDATA[<xsl:value-of select="tx_msg" />]]></description>
				<guid isPermaLink="false"><xsl:value-of select="gu_msg" /></guid>
  		  <dc:subject><xsl:value-of select="NewsMessageTags/NewsMessageTag/tl_tag" /></dc:subject> 
  			<dc:date><xsl:value-of select="dt_published" /></dc:date> 
	    </item>
	  </xsl:for-each>
  </channel>
</rss>
</xsl:template>
</xsl:stylesheet>

