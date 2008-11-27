<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="4.0" encoding="UTF-8" omit-xml-declaration="yes" indent="no" media-type="text/html"/>
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
        <LINK rel="stylesheet" type="text/css" href="{$param_imageserver}/styles/Traditional/{pageset/color}/{pageset/font}.css" />
      </HEAD>
      <BODY>
      &#160;
        <DIV class="TP_body_div">
          <TABLE width="600" border="0" cellpadding="0" cellspacing="0">
            <TR>
              <TD width="17" class="TP_fondo1"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/curve_ul.gif" width="17" height="17" border="0" alt="" /></TD>
              <TD rowspan="2" class="TP_TITULAR_TEXTO" width="100%">
              <div id="TITULAR_1" name="TITULAR_1"> 
                <xsl:if test="pageset/pages/page/blocks/block[metablock='TITULAR']/paragraphs/paragraph[@id='TITULAR_TEXTO']/text!=''">
                  <xsl:variable name="titular" select="pageset/pages/page/blocks/block[metablock='TITULAR']/paragraphs"/>
                  <xsl:value-of select="$titular/paragraph[@id='TITULAR_TEXTO']/text" disable-output-escaping="no"/>
                </xsl:if>
              </div>
              </TD>
              <TD width="17" class="TP_fondo1"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/curve_ur.gif" width="17" height="17" border="0" alt="" /></TD>
            </TR>
            <TR>
              <TD class="TP_fondo1" width="17"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/spacer.gif" width="17" height="25" border="0" alt="" /></TD>
              <TD class="TP_fondo1" width="17"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/spacer.gif" width="17" height="25" border="0" alt="" /></TD>
            </TR>
          </TABLE>
          <TABLE width="600" border="0" cellpadding="0" cellspacing="0">
            <TR>
              <TD class="TP_fondo2"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/spacer.gif" width="7" height="7" border="0" alt="" /></TD>
            </TR>
          </TABLE>
          <TABLE width="600" border="0" cellpadding="0" cellspacing="0">
            <TR>
              <TD colspan="3" class="TP_fondo1"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/spacer.gif" width="2" height="2" border="0" alt="" /></TD>
            </TR>
            <TR>
              <TD width="2" class="TP_fondo1"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/spacer.gif" width="2" height="2" border="0" alt="" /></TD>
              <TD width="100%">
                <span id="BIENVENIDA_1" name="BIENVENIDA_1"> 
                <TABLE width="100%" border="0" cellpadding="5" cellspacing="0">
                  <TR>
                    <TD>
                      <xsl:if test="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs/paragraph[@id='BIENVENIDA_INTRO']/text!=''">
                        <xsl:variable name="titular" select="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs"/>
                        <DIV class="TP_BIENVENIDA_INTRO"><xsl:value-of select="$titular/paragraph[@id='BIENVENIDA_INTRO']/text" disable-output-escaping="no"/><BR/><BR/></DIV>
                      </xsl:if>
                      <xsl:if test="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs/paragraph[@id='BIENVENIDA_TEXTO']/text!=''">
                        <xsl:variable name="titular" select="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs"/>
                        <DIV class="TP_BIENVENIDA_TEXTO"><xsl:value-of select="$titular/paragraph[@id='BIENVENIDA_TEXTO']/text" disable-output-escaping="no"/><BR/><BR/></DIV>
                      </xsl:if>
                    </TD>
                  </TR>
                </TABLE>
                </span>
                <TABLE width="100%" border="0" cellpadding="0" cellspacing="0">
                  <TR>
                    <TD class="TP_fondo2"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/spacer.gif" width="7" height="7" border="0" alt="" /></TD>
                  </TR>
                </TABLE>
                <!-- Start Loop -->
                <xsl:for-each select="pageset/pages/page/blocks/block[metablock='ARTICULO']"> 
                  <xsl:sort select="@id"/>
                  <span id="ARTICULO_{position()}" name="ARTICULO_{position()}"> 
                    <TABLE width="100%" border="0" cellpadding="2" cellspacing="0">
                      <TR>
                        <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/path!=''">
                          <TD rowspan="2" width="1" align="left" valign="middle">
                            <xsl:choose>
                              <xsl:when test="images/image[@id='IMAGEN_ARTICULO']/url!=''">
                               <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/width!=''"> 
                                <A href="{images/image[@id='IMAGEN_ARTICULO']/url}" target="_blank"><IMG src="{images/image[@id='IMAGEN_ARTICULO']/path}" width="{images/image[@id='IMAGEN_ARTICULO']/width}" height="{images/image[@id='IMAGEN_ARTICULO']/height}" alt="{images/image[@id='IMAGEN_ARTICULO']/alt}" border="" /></A>
                               </xsl:if>
                               <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/width=''"> 
                                <A href="{images/image[@id='IMAGEN_ARTICULO']/url}" target="_blank"><IMG src="{images/image[@id='IMAGEN_ARTICULO']/path}" alt="{images/image[@id='IMAGEN_ARTICULO']/alt}" border="" /></A>
                               </xsl:if>
                              </xsl:when>
                              <xsl:otherwise>
                               <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/width!=''"> 
                                <IMG src="{images/image[@id='IMAGEN_ARTICULO']/path}" width="{images/image[@id='IMAGEN_ARTICULO']/width}" height="{images/image[@id='IMAGEN_ARTICULO']/height}" alt="{images/image[@id='IMAGEN_ARTICULO']/alt}" border="" />
                               </xsl:if>
                               <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/width=''"> 
                                <IMG src="{images/image[@id='IMAGEN_ARTICULO']/path}" alt="{images/image[@id='IMAGEN_ARTICULO']/alt}" border="" />
                               </xsl:if>
                              </xsl:otherwise>
                            </xsl:choose>
                          </TD>
                          <TD rowspan="2" width="1"><IMG src="{$param_imageserver}/styles/Traditional/{../../../../../pageset/color}/spacer.gif" width="3" height="3" border="0" alt="" /></TD>
                        </xsl:if>
                        <TD align="left" valign="top">
                          <xsl:if test="paragraphs/paragraph[@id='TITULO_ARTICULO']/text!=''">
                            <DIV class="TP_TITULAR_ARTICULO"><xsl:value-of select="paragraphs/paragraph[@id='TITULO_ARTICULO']/text" disable-output-escaping="no"/></DIV>
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
                  </span>
                  <TABLE width="100%" border="0" cellpadding="0" cellspacing="0">
                    <TR>
                      <TD class="TP_fondo2"><IMG src="{$param_imageserver}/styles/Traditional/{../../../../../pageset/color}/spacer.gif" width="7" height="7" border="0" alt="" /></TD>
                    </TR>
                  </TABLE>
                </xsl:for-each>
                <!-- End Loop -->
                <span id="PIE_1" name="PIE_1"> 
                <TABLE width="100%" border="0" cellpadding="3" cellspacing="0">
                  <TR>
                    <TD class="TP_PIE_TEXTO" valign="top">
                      <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_TEXTO']/text!=''">
                        <xsl:variable name="titular" select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs"/>
                        <DIV class="TP_PIE_TEXTO"><xsl:value-of select="$titular/paragraph[@id='PIE_TEXTO']/text" disable-output-escaping="no"/><BR/><BR/></DIV>
                      </xsl:if>
                    </TD>
                    <TD class="TP_FOTO_PIE">
                      <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/path!=''">
                        <xsl:variable name="imagen" select="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']"/>
                        <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/url!=''">
                        <A href="{$imagen/url}" target="_blank">
                        <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width!=''">
                        <IMG src="{$imagen/path}" width="{$imagen/width}" height="{$imagen/height}" alt="{$imagen/alt}" border="0" />
                        </xsl:if>
                        <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width=''">
                        <IMG src="{$imagen/path}" alt="{$imagen/alt}" border="0" />
                        </xsl:if>
                        </A>
                        </xsl:if>
                        <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/url=''">
                        <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width!=''">
                        <IMG src="{$imagen/path}" width="{$imagen/width}" height="{$imagen/height}" alt="{$imagen/alt}" border="0" />
                        </xsl:if>
                        <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width=''">
                        <IMG src="{$imagen/path}" alt="{$imagen/alt}" border="0" />
                        </xsl:if>
                        </xsl:if>
                      </xsl:if>
                    </TD>
                  </TR>
                </TABLE>
                </span>
              </TD>
              <TD width="2" class="TP_fondo1"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/spacer.gif" width="2" height="2" border="0" alt="" /></TD>
            </TR>
            <TR>
              <TD colspan="3" class="TP_fondo1"><IMG src="{$param_imageserver}/styles/Traditional/{pageset/color}/spacer.gif" width="2" height="2" border="0" alt="" /></TD>
            </TR>
          </TABLE>
        </DIV>
      </BODY>
    </HTML>
  </xsl:template>
</xsl:stylesheet>