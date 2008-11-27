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
        <LINK rel="stylesheet" type="text/css" href="{$param_imageserver}/styles/Modern/{pageset/color}/{pageset/font}.css" />
      </HEAD>
      <BODY>
      &#160;
        <DIV class="TP_body_div">
          <TABLE border="0" cellpadding="0" cellspacing="0" width="600">
            <TR>
              <TD width="2"><IMG src="{$param_imageserver}/styles/Modern/_transparent/uplf1px.gif" width="2" height="2" border="0" alt=""/></TD>
              <TD background="{$param_imageserver}/styles/Modern/_transparent/up1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="2" border="0" alt=""/></TD>
              <TD background="{$param_imageserver}/styles/Modern/_transparent/up1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="2" border="0" alt=""/></TD>
              <TD rowspan="2" width="24" class="TP_fondo1"><IMG src="{$param_imageserver}/styles/Modern/_transparent/cuesta.gif" width="24" height="24" border="0" alt=""/></TD>
              <TD rowspan="2" width="100%" background="{$param_imageserver}/styles/Modern/_transparent/up24px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="1" height="24" border="0" alt=""/></TD>
              <TD rowspan="2" width="3" background="{$param_imageserver}/styles/Modern/_transparent/rg24px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="3" height="24" border="0" alt=""/></TD>
            </TR>
            <TR>
              <TD width="2" background="{$param_imageserver}/styles/Modern/_transparent/lf1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="2" border="0" alt=""/></TD>
              <TD class="TP_fondo1"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="4" height="22" border="0" alt=""/></TD>
              <TD nowrap="nowrap" class="TP_TITULAR_TEXTO" NAME="TITULAR_1" ID="TITULAR_1"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='TITULAR']/paragraphs/paragraph[@id='TITULAR_TEXTO']/text" disable-output-escaping="no"/></TD>
            </TR>
          </TABLE>
          <TABLE border="0" cellpadding="0" cellspacing="0" width="600"><TR><TD width="2" background="{$param_imageserver}/styles/Modern/_transparent/lf1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD><TD class="TP_fondo1"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="1" height="1" border="0" alt=""/></TD><TD width="3" background="{$param_imageserver}/styles/Modern/_transparent/rg2px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD></TR></TABLE>
          <TABLE border="0" cellpadding="0" cellspacing="0" width="600">
            <TR>
              <TD width="2" background="{$param_imageserver}/styles/Modern/_transparent/lf1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
              <TD width="2" class="TP_fondo2"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
              <TD ID="BIENVENIDA_1" NAME="BIENVENIDA_1" class="TP_fondo2">
                <TABLE width="100%" border="0" cellpadding="3" cellspacing="0">
                  <TR>
                    <TD class="TP_BIENVENIDA_INTRO"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs/paragraph[@id='BIENVENIDA_INTRO']/text" disable-output-escaping="no"/></TD>
                  </TR>
                  <TR>
                    <TD class="TP_BIENVENIDA_TEXTO"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs/paragraph[@id='BIENVENIDA_TEXTO']/text" disable-output-escaping="no"/></TD>
                  </TR>
                </TABLE>
              </TD>
              <TD width="2" class="TP_fondo2"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
              <TD width="3" background="{$param_imageserver}/styles/Modern/_transparent/rg2px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
            </TR>
          </TABLE>
          <TABLE border="0" cellpadding="0" cellspacing="0" width="600"><TR><TD width="2" background="{$param_imageserver}/styles/Modern/_transparent/lf1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD><TD class="TP_fondo1"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="1" height="1" border="0" alt=""/></TD><TD width="3" background="{$param_imageserver}/styles/Modern/_transparent/rg2px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD></TR></TABLE>
          <!-- Loop -->
          <xsl:for-each select="pageset/pages/page/blocks/block[metablock='ARTICULO']"> 
          <xsl:sort select="@id"/>
          <TABLE border="0" cellpadding="0" cellspacing="0" width="600">
            <TR>
              <TD width="2" background="{$param_imageserver}/styles/Modern/_transparent/lf1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
              <TD width="2" class="TP_fondo2"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
              <TD id="ARTICULO_{position()}" name="ARTICULO_{position()}" class="TP_fondo2">
                  <TABLE width="100%" border="0" cellpadding="2" cellspacing="0">
                    <TR>
                      <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/path!=''">
                        <TD rowspan="2" width="1" align="left" valign="middle">
                        <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/url!=''">
                        <xsl:choose>
                            <xsl:when test="images/image[@id='IMAGEN_ARTICULO']/width!=''">
                              <A href="{images/image[@id='IMAGEN_ARTICULO']/url}" target="_blank">
                              <IMG src="{images/image[@id='IMAGEN_ARTICULO']/path}" border="0" width="{images/image[@id='IMAGEN_ARTICULO']/width}" height="{images/image[@id='IMAGEN_ARTICULO']/height}" alt="{images/image[@id='IMAGEN_ARTICULO']/alt}" />
                              </A>
                            </xsl:when>
                            <xsl:when test="images/image[@id='IMAGEN_ARTICULO']/width=''">
                              <A href="{images/image[@id='IMAGEN_ARTICULO']/url}" target="_blank">
                              <IMG src="{images/image[@id='IMAGEN_ARTICULO']/path}" border="0" alt="{images/image[@id='IMAGEN_ARTICULO']/alt}" />
                              </A>
                            </xsl:when>
                        </xsl:choose>
                        </xsl:if>
                        <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/url=''">
                        <xsl:choose>
                            <xsl:when test="images/image[@id='IMAGEN_ARTICULO']/width!=''">
                              <IMG src="{images/image[@id='IMAGEN_ARTICULO']/path}" border="0" width="{images/image[@id='IMAGEN_ARTICULO']/width}" height="{images/image[@id='IMAGEN_ARTICULO']/height}" alt="{images/image[@id='IMAGEN_ARTICULO']/alt}" />
                            </xsl:when>
                            <xsl:when test="images/image[@id='IMAGEN_ARTICULO']/width=''">
                              <IMG src="{images/image[@id='IMAGEN_ARTICULO']/path}" border="0" alt="{images/image[@id='IMAGEN_ARTICULO']/alt}" />
                            </xsl:when>
                          </xsl:choose>
                        </xsl:if>
                        </TD>
                        <TD rowspan="2" width="1"><IMG src="{$param_imageserver}/styles/Newsletter02/{pageset/color}/spacer.gif" width="3" height="3" border="0" alt="" /></TD>
                      </xsl:if>
                      <TD align="left" valign="top">
                        <xsl:if test="paragraphs/paragraph[@id='TITULO_ARTICULO']/text!=''">
                          <DIV class="TP_TITULAR_ARTICULO"><xsl:value-of select="paragraphs/paragraph[@id='TITULO_ARTICULO']/text"  disable-output-escaping="no"/></DIV>
                        </xsl:if>
                        <xsl:if test="paragraphs/paragraph[@id='PARRAFO_ARTICULO']/text!=''">
                          <DIV class="TP_PARRAFO_ARTICULO"><xsl:value-of select="paragraphs/paragraph[@id='PARRAFO_ARTICULO']/text" disable-output-escaping="no"/></DIV>
                        </xsl:if>
                      </TD>
                    </TR>
                    <TR>
                      <TD>
                        <xsl:if test="paragraphs/paragraph[@id='ENLACE_ARTICULO']/text!=''">
                          <DIV class="TP_ENLACE_ARTICULO_div"><A class="TP_ENLACE_ARTICULO" target="_blank" href="{paragraphs/paragraph[@id='ENLACE_ARTICULO']/url}"><xsl:value-of select="paragraphs/paragraph[@id='ENLACE_ARTICULO']/text" disable-output-escaping="no"/></A></DIV>
                        </xsl:if>
                      </TD>
                    </TR>
                  </TABLE>
              </TD>
              <TD width="2" class="TP_fondo2"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
              <TD width="3" background="{$param_imageserver}/styles/Modern/_transparent/rg2px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
            </TR>
          </TABLE>
          <TABLE border="0" cellpadding="0" cellspacing="0" width="600"><TR><TD width="2" background="{$param_imageserver}/styles/Modern/_transparent/lf1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD><TD class="TP_fondo1"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="1" height="1" border="0" alt=""/></TD><TD width="3" background="{$param_imageserver}/styles/Modern/_transparent/rg2px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD></TR></TABLE>
          </xsl:for-each>
          <!-- Fin -->
          <TABLE border="0" cellpadding="0" cellspacing="0" width="600">
            <TR>
              <TD width="2" background="{$param_imageserver}/styles/Modern/_transparent/lf1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
              <TD width="2" class="TP_fondo2"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
              <TD id="PIE_1" name="PIE_1" class="TP_fondo2">
                <TABLE width="100%" border="0" cellpadding="3" cellspacing="0">
                  <TR>
                    <TD class="TP_PIE_TEXTO"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_TEXTO']/text" disable-output-escaping="no"/></TD>
                    <TD class="TP_FOTO_PIE">
                      <A href="{pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/url}" target="_blank">
                      <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width!=''">
                      <IMG src="{pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/path}" width="{pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width}" height="{pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/height}" alt="{pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/alt}" border="0"/>
                      </xsl:if>
                      <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width=''">
                      <IMG src="{pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/path}" alt="{pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/alt}" border="0"/>
                      </xsl:if>
                      </A>
                    </TD>
                  </TR>
                </TABLE>
              </TD>
              <TD width="2" class="TP_fondo2"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
              <TD width="3" background="{$param_imageserver}/styles/Modern/_transparent/rg2px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD>
            </TR>
          </TABLE>
          <TABLE border="0" cellpadding="0" cellspacing="0" width="600"><TR><TD width="2" background="{$param_imageserver}/styles/Modern/_transparent/lf1px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD><TD class="TP_fondo1"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="1" height="1" border="0" alt=""/></TD><TD width="3" background="{$param_imageserver}/styles/Modern/_transparent/rg2px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="2" height="1" border="0" alt=""/></TD></TR></TABLE>
          <TABLE border="0" cellpadding="0" cellspacing="0" width="600">
            <TR>
              <TD width="2"><IMG src="{$param_imageserver}/styles/Modern/_transparent/dwlf.gif" width="3" height="3" border="0" alt=""/></TD>
              <TD background="{$param_imageserver}/styles/Modern/_transparent/dw2px.gif"><IMG src="{$param_imageserver}/styles/common/spacer.gif" width="3" height="3" border="0" alt=""/></TD>
              <TD width="2"><IMG src="{$param_imageserver}/styles/Modern/_transparent/dwrg.gif" width="3" height="3" border="0" alt=""/></TD>
            </TR>
          </TABLE>
        </DIV>
      </BODY>
    </HTML>
  </xsl:template>
</xsl:stylesheet>