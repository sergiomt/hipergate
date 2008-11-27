<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="4.0" encoding="UTF-8" omit-xml-declaration="no" indent="no" media-type="text/html"/>
  <xsl:param name="param_domain" />
  <xsl:param name="param_workarea" />
  <xsl:param name="param_imageserver" />
  <xsl:param name="param_pageset" />
  <xsl:param name="storage" />
  <xsl:template match="/">
    <HTML xmlns="http://www.w3.org/1999/xhtml">
      <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <TITLE><xsl:value-of select="pageset/pages/page/title"/></TITLE>
        <META http-equiv="Pragma" content="no-cache" />
        <META http-equiv="cache-control" content="no-store" />
        <META http-equiv="Expires" content="0" />
        <LINK rel="stylesheet" type="text/css" href="{$param_imageserver}/styles/Professional/{pageset/color}/{pageset/font}.css" />
      </HEAD>
      <BODY>
      &#160;
        <div style="text-align:center">
          <table width="600" border="0" cellpadding="0" cellspacing="0">
            <tr>
              <td width="25" class="fondo_1"><img src="{$param_imageserver}/styles/Professional/{pageset/color}/up.gif" width="25" height="25" border="0"/></td>
              <td width="550" class="fondo_1"><img src="{$param_imageserver}/styles/common/spacer.gif" height="25" width="550" border="0"/></td>
              <td width="25" class="fondo_1"><img src="{$param_imageserver}/styles/common/spacer.gif" height="25" width="25" border="0"/></td>
            </tr>
            <tr>
              <td width="25" class="fondo_1"><img src="{$param_imageserver}/styles/common/spacer.gif" width="25" height="25" border="0"/></td>
              <td width="550" class="fondo_2"><table width="550" border="0" cellpadding="4" cellspacing="0"><tr><td id="TITULAR_1" name="TITULAR_1" class="TP_TITULAR_TEXTO"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='TITULAR']/paragraphs/paragraph[@id='TITULAR_TEXTO']/text" disable-output-escaping="no"/></td></tr></table></td>
              <td width="25" class="fondo_1"><img src="{$param_imageserver}/styles/common/spacer.gif" height="25" width="25" border="0"/></td>
            </tr>
            <tr>
              <td width="25" class="fondo_1"><img src="{$param_imageserver}/styles/common/spacer.gif" width="25" height="25" border="0"/></td>
              <td width="550" class="fondo_2" align="right"><table width="550" border="0" cellpadding="4" cellspacing="0"><tr><td class="TP_TITULAR_FECHA"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='TITULAR']/paragraphs/paragraph[@id='TITULAR_FECHA']/text" disable-output-escaping="no"/></td></tr></table></td>
              <td width="25" class="fondo_1"><img src="{$param_imageserver}/styles/common/spacer.gif" height="25" width="25" border="0"/></td>
            </tr>
            <tr>
              <td colspan="3" width="600" class="fondo_1"><img src="{$param_imageserver}/styles/common/spacer.gif" height="1" width="600" border="0"/></td>
            </tr>
            <tr>
              <td width="25" class="fondo_3"><img src="{$param_imageserver}/styles/common/spacer.gif" width="25" height="25" border="0"/></td>
              <td width="550" class="fondo_4">
                <span id="BIENVENIDA_1" name="BIENVENIDA_1">
                <table width="550" border="0" cellpadding="4" cellspacing="0"><tr><td class="TP_BIENVENIDA_INTRO"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs/paragraph[@id='BIENVENIDA_INTRO']/text"  disable-output-escaping="no"/></td></tr></table>
                <table width="550" border="0" cellpadding="4" cellspacing="0"><tr><td class="TP_BIENVENIDA_TEXTO"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs/paragraph[@id='BIENVENIDA_TEXTO']/text"  disable-output-escaping="no"/></td></tr></table>
                </span>
                <xsl:for-each select="pageset/pages/page/blocks/block[metablock='ARTICULO']"> 
                  <xsl:sort select="@id"/>
                  <SPAN id="ARTICULO_{position()}" name="ARTICULO_{position()}"> 
                    <table width="550" border="0" cellpadding="4" cellspacing="0"><tr><td class="TP_ARTICULO_TITULO"><xsl:value-of select="paragraphs/paragraph[@id='TITULO_ARTICULO']/text"  disable-output-escaping="no"/></td></tr></table>
                    <table width="550" border="0" cellpadding="4" cellspacing="0"><tr><td class="TP_ARTICULO_TEXTO"><xsl:value-of select="paragraphs/paragraph[@id='PARRAFO_ARTICULO']/text" disable-output-escaping="no"/></td></tr></table>
                    <table width="550" border="0" cellpadding="4" cellspacing="0"><tr><td class="TP_ARTICULO_ENLACE"><a class="TP_ARTICULO_ENLACE" href="{paragraphs/paragraph[@id='ENLACE_ARTICULO']/url}" target="_blank"><xsl:value-of select="paragraphs/paragraph[@id='ENLACE_ARTICULO']/text" disable-output-escaping="no"/></a></td></tr></table>
                  </SPAN>
                </xsl:for-each>
                <span id="PIE_1" name="PIE_1">
                <table width="550" border="0" cellpadding="4" cellspacing="0"><tr><td class="TP_PIE_TEXTO">
                <hr size="1" width="275" color="#000000" align="left"/><xsl:value-of select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_TEXTO']/text" disable-output-escaping="no"/></td></tr></table>
                </span>
              </td>
              <td width="25" class="fondo_3"><img src="{$param_imageserver}/styles/common/spacer.gif" height="25" width="25" border="0"/></td>
            </tr>
            <tr>
              <td width="25" class="fondo_3"><img src="{$param_imageserver}/styles/common/spacer.gif" width="25" height="25" border="0"/></td>
              <td width="550" class="fondo_3"><img src="{$param_imageserver}/styles/common/spacer.gif" height="25" width="550" border="0"/></td>
              <td width="25" class="fondo_3"><img src="{$param_imageserver}/styles/Professional/{pageset/color}/down.gif" height="25" width="25" border="0"/></td>
            </tr>
          </table>
        </div>
      </BODY>
    </HTML>
  </xsl:template>
</xsl:stylesheet>