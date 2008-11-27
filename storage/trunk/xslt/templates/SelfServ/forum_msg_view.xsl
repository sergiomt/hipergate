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
	  <TD class="Breadcrumb" align="left"><a href="http://www.fundacioncomillasweb.com">Fundacion Campus Comillas</a> > <a href="comunidades.jsp">Comunidades</a> > Ver mensaje</TD>
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

	<TD width="100%" class="mainColumn">
		<DIV id="mainColumnRound"> 
	  <H1>Foro&#160;<xsl:value-of select="Forums/NewsGroup/labels/label[@id_language='es']" disable-output-escaping="no"/></H1>
	  <BR/>
	  &#160;&#160;&#160;<A HREF="forum_list.jsp?gu_newsgrp={Forums/NewsGroup/gu_newsgrp}">Volver</A>
	  <BR/><BR/>
	  
	    <xsl:for-each select="Forums/NewsMessages/NewsMessage">

          <TABLE bgcolor="black" cellpadding="0" cellspacing="0" border="0" width="100%">
            <tr>
              <td>
                <TABLE bgcolor="black" cellpadding="4" cellspacing="1" border="0" width="100%">
                  <tr bgcolor="#c9282d">
                    <td>
                      <TABLE cellpadding="0" cellspacing="0" border="0" width="100%">
                        <tr>
                          <td width="98%" class="StripText"><a name="{gu_msg}"></a><b><xsl:value-of select="tx_subject"/></b><br/><b>Autor</b>: <xsl:value-of select="nm_author"/></td>
                          <td width="1%" class="StripText" nowrap="nowrap"><xsl:value-of select="dt_published"/></td>
                        </tr>
                      </TABLE>
                    </td>
                  </tr>
                  <tr bgcolor="#ffffff">
                    <td>
                      <tt><xsl:value-of select="tx_msg"/></tt>
                    </td>
                  </tr>
                  <tr>
                    <td bgcolor="#ffffff" class="mini" align="right" valign="middle">
                      <a href="#" onclick="createMessage('{gu_thread_msg}','{gu_msg}')">responder</a>
                    </td>
                  </tr>
                </TABLE>
              </td>
            </tr>
          </TABLE>
  	  </xsl:for-each>
  	</DIV>
	</TD>

  </TR>
</TABLE>
<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript"><![CDATA[Rounded("div#mainColumnRound","black","white");]]></SCRIPT>

</xsl:template>

</xsl:stylesheet>