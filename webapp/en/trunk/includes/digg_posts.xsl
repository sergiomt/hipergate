<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_domain" />
<xsl:param name="param_workarea" />
<xsl:param name="param_newsgrp" />
<xsl:param name="param_user" />
<xsl:param name="param_language" />
<xsl:template match="/">
  <TABLE SUMMARY="Outer Table" CELLSPACING="0" CELLPADDING="0" BORDER="0">
    <xsl:for-each select="posts/newsmsg">
    <TR>
      <TD>
        <TABLE SUMMARY="Vote Count" CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD>
              <xsl:value-of select="nu_votes"/>
            </TD>
          </TR>
        </TABLE>
        <TABLE SUMMARY="Vote Click" CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD>
              <A HREF="#" onclick="voteMsg('{gu_msg}','{$param_user}')">Vote</A>
            </TD>
          </TR>
        </TABLE>
      </TD>
      <TD>
	<TABLE SUMMARY="Post Briefing" CELLSPACING="0" CELLPADDING="0" BORDER="0">
	  <TR>
	    <TD>
	      <xsl:value-of select="tx_subject"/>
	      <BR/>
	      <xsl:value-of select="tx_msg"/>	      
	    </TD>
	  </TR>
	</TABLE>
      </TD>
    </TR>
    </xsl:for-each>
  </TABLE>
</xsl:template>
</xsl:stylesheet>