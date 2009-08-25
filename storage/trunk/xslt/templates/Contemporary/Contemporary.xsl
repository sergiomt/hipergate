<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" encoding="UTF-8" omit-xml-declaration="yes" indent="no" media-type="text/html"/>
<xsl:param name="param_domain" />
<xsl:param name="param_workarea" />
<xsl:param name="param_imageserver" />
<xsl:param name="param_pageset" />
<xsl:param name="storage" />
<xsl:template match="/">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title><xsl:value-of select="pageset/pages/page/title"/></title>
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="cache-control" content="no-store" />
    <meta http-equiv="Expires" content="0" />
    <link rel="stylesheet" type="text/css" href="{$param_imageserver}/styles/Contemporary/{pageset/color}/{pageset/font}.css" />
  </head>
  <body class="TP_body">
  &#160;
  <div class="TP_body_div">
    <table class="TP_main_table">
      <tbody>
        <tr>
          <td class="TP_main_td">
            <table cellspacing="0" cellpadding="0" width="100%" border="0">
              <tbody>
                <xsl:if test="pageset/pages/page/blocks/block[metablock='LOGO_SUPERIOR']/images/image!=''">
                <xsl:variable name="logoSuperior" select="pageset/pages/page/blocks/block[metablock='LOGO_SUPERIOR']/images/image[@id='LOGOTIPO_CENTRAL']"/>
                <tr>
                  <td name="LOGO_SUPERIOR_1" id="LOGO_SUPERIOR_1" class="TP_LOGO_SUPERIOR" colspan="3"><img alt="{$logoSuperior/alt}" src="{$logoSuperior/path}" border="0" /></td>
                </tr>
                </xsl:if>
                <tr>
                  <td class="TP_fondo3" colspan="3"><img height="5" width="5" border="0" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" /></td>
                </tr>
                <xsl:if test="pageset/pages/page/blocks/block[metablock='TITULAR']/paragraphs/paragraph[@id='TITULAR_TEXTO']/text!=''">
                <xsl:variable name="titular" select="pageset/pages/page/blocks/block[metablock='TITULAR']/paragraphs"/>
                <tr name="TITULAR_1" id="TITULAR_1">
                  <td class="TP_TITULAR_TEXTO">&#160;<xsl:value-of select="$titular/paragraph[@id='TITULAR_TEXTO']/text" disable-output-escaping="no"/></td>
                  <td class="TP_TITULAR_TEXTO"><img height="35" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="2" border="0" /></td>
                  <td class="TP_TITULAR_otros">
                    <div class="TP_TITULAR_COMENTARIO"><xsl:value-of select="$titular/paragraph[@id='TITULAR_COMENTARIO']/text" disable-output-escaping="no"/>&#160;</div>
                    <div class="TP_TITULAR_FECHA"><xsl:value-of select="$titular/paragraph[@id='TITULAR_FECHA']/text" disable-output-escaping="no"/>&#160;</div>
                  </td>
                </tr>
                </xsl:if>
                <tr>
                  <td class="TP_fondo5" colspan="3"><img height="4" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="600" border="0" /></td>
                </tr>
              </tbody>
            </table>
            <table cellpadding="0" cellspacing="0" border="0" width="100%">
              <tbody>
                <tr>
                  <td width="1" class="TP_fondo5" rowspan="6"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="1" border="0" /></td>
                  <td width="10" class="TP_fondo1" rowspan="2"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="10" border="0" /></td>
                  <td width="1" class="TP_fondo5" rowspan="2"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="1" border="0" /></td>
                  <td width="7" class="TP_fondo1" rowspan="2"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="7" border="0" /></td>
                  <td width="100%" class="TP_fondo1"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="400" border="0" /></td>
                  <td width="7" class="TP_fondo1" rowspan="2"><img height="1"  src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="7" border="0" /></td>
                  <td width="1" class="TP_fondo5" rowspan="2"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="1" border="0" /></td>
                  <td width="175" class="TP_fondo5"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="175" border="0" /></td>
                  <td width="1" class="TP_fondo5" rowspan="6"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="1" border="0" /></td>
                </tr>
                <tr>
                  <td valign="top" width="100%" class="TP_fondo1">
                    <xsl:if test="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs/paragraph[@id='BIENVENIDA_TEXTO']/text!=''">
                      <div id="BIENVENIDA_1" name="BIENVENIDA_1" class="TP_BIENVENIDA_TEXTO"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs/paragraph[@id='BIENVENIDA_TEXTO']/text" disable-output-escaping="no"/></div>
                    </xsl:if>
                    <table cellspacing="0" cellpadding="0" width="100%" border="0" name="SUMARIO_1" id="SUMARIO_1">
                      <tbody>
                        <tr>
                          <td class="TP_este_numero">En este numero...</td>
                        </tr>
                        <tr>
                          <td class="TP_fondo5"><img height="2" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="2" border="0" /></td>
                        </tr>
                        <tr>
                          <td class="TP_sumario_td">
                            <ul>
                              <xsl:for-each select="pageset/pages/page/blocks/block[metablock='ARTICULO']/paragraphs/paragraph[starts-with(@id,'TITULO_ARTICULO')]"> 
                               <xsl:sort select="../../@id"/>
                                <li class="TP_sumario_item"><xsl:value-of select="text"/></li>
                              </xsl:for-each>
                            </ul>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                    <xsl:for-each select="pageset/pages/page/blocks/block[metablock='ARTICULO']"> 
                    <xsl:sort select="@id"/>
                    <span id="ARTICULO_{position()}" name="ARTICULO_{position()}"> 
                      <xsl:call-template name="formatArticle">
                      <xsl:with-param name="blkid" select="@id"/>
                      </xsl:call-template>
                    </span>
                    </xsl:for-each>
                    <br />
                  </td>
                  <td class="TP_LATERAL_td">
                    <span name="LATERAL_SUPERIOR_1" id="LATERAL_SUPERIOR_1">
                    <table cellspacing="0" cellpadding="5" width="100%" border="0">
                      <xsl:variable name="latSuperior" select="pageset/pages/page/blocks/block[metablock='LATERAL_SUPERIOR']"/>
                      <tbody>
                        <tr>
                          <td class="TP_TITULO_LATERAL_SUPERIOR"><xsl:value-of select="$latSuperior/paragraphs/paragraph[@id='TITULO_LATERAL_SUPERIOR']/text"/></td>
                        </tr>
                        <xsl:variable name="latFoto" select="pageset/pages/page/blocks/block[metablock='LATERAL_SUPERIOR']/images/image[@id='FOTO_LATERAL_SUPERIOR']"/>
                        <tr>
                          <td class="TP_FOTO_LATERAL_SUPERIOR_cell"><a target="_blank" href="{$latFoto/url}"><img src="{$latFoto/path}" border="0" /></a></td>
                        </tr>
                        <tr>
                          <td class="TP_LATERAL_SUPERIOR_cont">
                            <xsl:for-each select="pageset/pages/page/blocks/block[metablock='LATERAL_SUPERIOR']/paragraphs/paragraph[starts-with(@id,'TEXTO_LATERAL_SUPERIOR')]">
                            <xsl:sort select="@id"/>
                              <xsl:choose>
                                <xsl:when test="url!=''">
                                  <div class="TP_TEXTO_LATERAL_SUPERIOR"><a class="TP_TEXTO_LATERAL_SUPERIOR_link" target="_blank" href="{url}"><xsl:value-of select="text" /></a></div>
                                </xsl:when>
                                <xsl:otherwise>
                                  <div class="TP_TEXTO_LATERAL_SUPERIOR"><xsl:value-of select="text" /></div>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:for-each>
                            <br />
                            <xsl:for-each select="pageset/pages/page/blocks/block[metablock='LATERAL_SUPERIOR']/paragraphs/paragraph[starts-with(@id,'ENLACE_LATERAL_SUPERIOR')]">
                            <xsl:sort select="@id"/>
                              <div class="TP_ENLACE_LATERAL_SUPERIOR_div"><span class="TP_ENLACE_LATERAL_SUPERIOR_raquo">&#160;</span>&#160;<a class="ENLACE_LATERAL_SUPERIOR" target="_blank" href="{url}"><xsl:value-of select="text" /></a></div>
                            </xsl:for-each>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                    </span>

                    <table cellspacing="0" cellpadding="0" width="100%" border="0">
                      <tbody>
                        <tr><td colspan="2"><img height="15" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="10" border="0" /></td></tr>
                        <tr><td class="TP_fondo5" colspan="2"><img height="15" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="175" border="0" /></td></tr>
                        <tr><td class="TP_fondo2" colspan="2"><img height="4" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="10" border="0" /></td></tr>
                      </tbody>
                    </table>
                    <span name="LATERAL_CENTRAL_1" id="LATERAL_CENTRAL_1">
                    
                    <table cellspacing="0" cellpadding="5" width="100%" border="0">
                      <xsl:variable name="latSuperior" select="pageset/pages/page/blocks/block[metablock='LATERAL_CENTRAL']"/>
                      <tbody>
                        <tr>
                          <td class="TP_TITULO_LATERAL_CENTRAL"><xsl:value-of select="$latSuperior/paragraphs/paragraph[@id='TITULO_LATERAL_CENTRAL']/text"/></td>
                        </tr>
                        <xsl:variable name="latFoto" select="pageset/pages/page/blocks/block[metablock='LATERAL_CENTRAL']/images/image[@id='FOTO_LATERAL_CENTRAL']"/>
                        <tr>
                          <td class="TP_FOTO_LATERAL_CENTRAL_cell"><a target="_blank" href="{$latFoto/url}"><img src="{$latFoto/path}" border="0" /></a></td>
                        </tr>
                        <tr>
                          <td class="TP_LATERAL_CENTRAL_cont">
                            <xsl:for-each select="pageset/pages/page/blocks/block[metablock='LATERAL_CENTRAL']/paragraphs/paragraph[starts-with(@id,'TEXTO_LATERAL_CENTRAL')]">
                            <xsl:sort select="@id"/>
                              <xsl:choose>
                                <xsl:when test="url!=''">
                                  <div class="TP_TEXTO_LATERAL_CENTRAL"><a class="TP_TEXTO_LATERAL_CENTRAL_link" target="_blank" href="{url}"><xsl:value-of select="text" /></a></div>
                                </xsl:when>
                                <xsl:otherwise>
                                  <div class="TP_TEXTO_LATERAL_CENTRAL"><xsl:value-of select="text" /></div>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:for-each>
                            <br />
                            <xsl:for-each select="pageset/pages/page/blocks/block[metablock='LATERAL_CENTRAL']/paragraphs/paragraph[starts-with(@id,'ENLACE_LATERAL_CENTRAL')]">
                            <xsl:sort select="@id"/>
                              <div class="TP_ENLACE_LATERAL_CENTRAL_div"><span class="TP_ENLACE_LATERAL_CENTRAL_raquo">&#187;</span>&#160;<a class="ENLACE_LATERAL_CENTRAL" target="_blank" href="{url}"><xsl:value-of select="text" /></a></div>
                            </xsl:for-each>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                    </span>

                    <table cellspacing="0" cellpadding="0" width="100%" border="0">
                      <tbody>
                        <tr><td colspan="2"><img height="15" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="10" border="0" /></td></tr>
                        <tr><td class="TP_fondo5" colspan="2"><img height="15" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="175" border="0" /></td></tr>
                        <tr><td class="TP_fondo2" colspan="2"><img height="4" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="10" border="0" /></td></tr>
                      </tbody>
                    </table>
                    <span name="LATERAL_INFERIOR_1" id="LATERAL_INFERIOR_1">
                    
                    <table cellspacing="0" cellpadding="5" width="100%" border="0">
                      <xsl:variable name="latSuperior" select="pageset/pages/page/blocks/block[metablock='LATERAL_INFERIOR']"/>
                      <tbody>
                        <tr>
                          <td class="TP_TITULO_LATERAL_INFERIOR"><xsl:value-of select="$latSuperior/paragraphs/paragraph[@id='TITULO_LATERAL_INFERIOR']/text"/></td>
                        </tr>
                        <xsl:variable name="latFoto" select="pageset/pages/page/blocks/block[metablock='LATERAL_INFERIOR']/images/image[@id='FOTO_LATERAL_INFERIOR']"/>
                        <tr>
                          <td class="TP_FOTO_LATERAL_INFERIOR_cell"><a target="_blank" href="{$latFoto/url}"><img src="{$latFoto/path}" border="0" /></a></td>
                        </tr>
                        <tr>
                          <td class="TP_LATERAL_INFERIOR_cont">
                            <xsl:for-each select="pageset/pages/page/blocks/block[metablock='LATERAL_INFERIOR']/paragraphs/paragraph[starts-with(@id,'TEXTO_LATERAL_INFERIOR')]">
                            <xsl:sort select="@id"/>
                              <xsl:choose>
                                <xsl:when test="url!=''">
                                  <div class="TP_TEXTO_LATERAL_INFERIOR"><a class="TP_TEXTO_LATERAL_INFERIOR_link" target="_blank" href="{url}"><xsl:value-of select="text" /></a></div>
                                </xsl:when>
                                <xsl:otherwise>
                                  <div class="TP_TEXTO_LATERAL_INFERIOR"><xsl:value-of select="text" /></div>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:for-each>
                            <br />
                            <xsl:for-each select="pageset/pages/page/blocks/block[metablock='LATERAL_INFERIOR']/paragraphs/paragraph[starts-with(@id,'ENLACE_LATERAL_INFERIOR')]">
                            <xsl:sort select="@id"/>
                              <div class="TP_ENLACE_LATERAL_INFERIOR_div"><span class="TP_ENLACE_LATERAL_INFERIOR_raquo">&#187;</span>&#160;<a class="ENLACE_LATERAL_INFERIOR" target="_blank" href="{url}"><xsl:value-of select="text" /></a></div>
                            </xsl:for-each>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                    </span>
                  </td>
                </tr>
                <tr>
                  <td class="TP_fondo2" colspan="7"> <img height="5" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="10" border="0" /> </td>
                </tr>
                <tr>
                  <td align="center" class="TP_PIE_table" colspan="7">
                    <span name="PIE_1" id="PIE_1">
                    <table width="100%" border="0" cellpadding="5" cellspacing="0">
                      <tbody>
                        <tr>
                          <td valign="top" width="100%">
                            <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_WEB']/text!=''">
                              <xsl:choose>
                                <xsl:when test="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_WEB']/url=''">
                                  <div class="TP_PIE_WEB_div"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_WEB']/text"/></div>
                                </xsl:when>
                                <xsl:otherwise>
                                  <div class="TP_PIE_WEB_div"><a class="TP_PIE_WEB_link" target="_blank" href="{pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_WEB']/url}"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_WEB']/text" disable-output-escaping="no"/></a></div>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:if>
                            <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_EMAIL']/text!=''">
                              <xsl:choose>
                                <xsl:when test="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_EMAIL']/url=''">
                                  <div class="TP_PIE_EMAIL_div"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_EMAIL']/text" disable-output-escaping="no"/></div>
                                </xsl:when>
                                <xsl:otherwise>
                                  <div class="TP_PIE_EMAIL_div"><a class="TP_PIE_EMAIL_link" target="_blank" href="{pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_EMAIL']/url}"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_EMAIL']/text" disable-output-escaping="no"/></a></div>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:if>
                            <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_CONTACTO']/text!=''">
                              <xsl:choose>
                                <xsl:when test="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_CONTACTO']/url=''">
                                  <div class="TP_PIE_CONTACTO_div"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_CONTACTO']/text" disable-output-escaping="no"/></div>
                                </xsl:when>
                                <xsl:otherwise>
                                  <div class="TP_PIE_CONTACTO_div"><a class="TP_PIE_CONTACTO_link" target="_blank" href="{pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_CONTACTO']/url}"><xsl:value-of select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_CONTACTO']/text" disable-output-escaping="no"/></a></div>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:if>
                          </td>
                          <td align="right" valign="top" width="1">
                            <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/path!=''">
                              <xsl:variable name="fotoPie" select="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']"/>
                              <xsl:choose>
                                <xsl:when test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/url=''">
                                  <div class="TP_FOTO_PIE_div">
                                  <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width!=''">
                                  <img alt="{$fotoPie/alt}" src="{$fotoPie/path}" width="{$fotoPie/width}" height="{$fotoPie/height}" border="0" />
                                  </xsl:if>
                                  <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width=''">
                                  <img alt="{$fotoPie/alt}" src="{$fotoPie/path}" border="0" />
                                  </xsl:if>
                                  </div>
                                </xsl:when>
                                <xsl:otherwise>
                                  <div class="TP_FOTO_PIE_div">
                                  <a target="_blank" href="{pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/url}">
                                  <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width!=''">
                                  <img alt="{$fotoPie/alt}" src="{$fotoPie/path}" width="{$fotoPie/width}" height="{$fotoPie/height}" border="0" />
                                  </xsl:if>
                                  <xsl:if test="pageset/pages/page/blocks/block[metablock='PIE']/images/image[@id='FOTO_PIE']/width=''">
                                  <img alt="{$fotoPie/alt}" src="{$fotoPie/path}" border="0" />
                                  </xsl:if>
                                  </a>
                                  </div>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:if>
                          </td>
                        </tr>
                        <tr>
                          <td colspan="2" class="TP_PIE_TEXTO">
                            <xsl:value-of select="pageset/pages/page/blocks/block[metablock='PIE']/paragraphs/paragraph[@id='PIE_TEXTO']/text" disable-output-escaping="no"/>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                    <table width="100%" border="0" cellpadding="0" cellspacing="0">
                      <tbody>
                        <tr>
                          <td class="TP_fondo5"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="1" border="0" /></td>
                        </tr>
                      </tbody>
                    </table>
                    <table width="100%" border="0" cellpadding="6" cellspacing="0">
                      <tbody>
                        <tr>
                          <td class="TP_PIE_TEXTO">
                            Informacion al usuario: Este correo electronico ha sido enviado a traves 
                            del sistema <a class="TP_PIE_TEXTO" href="http://www.hipergate.com/" target="_blank">HiperGate</a>
                            en nombre de {#Datos.Remitente}.
                            Si no desea recibir mas comunicados de este remitente haga click en la siguiente 
                            <xsl:element name="a">
                              <xsl:attribute name="href"><![CDATA[{#Sistema.BajaURL}]]></xsl:attribute>
                              <xsl:attribute name="class">TP_PIE_TEXTO</xsl:attribute>
                              <xsl:attribute name="target">_blank</xsl:attribute>
                              Direccion
                            </xsl:element>
                            Para consultas puede ponerse en contacto con la direcion <a class="TP_PIE_TEXTO" href="mailto:abuse@hipergate.com" target="_blank">abuse@hipergate.com</a>.
                          </td>
                        </tr>
                      </tbody>
                    </table>
                    </span>
                  </td>
                </tr>
                <tr height="1">
                  <td class="TP_fondo5" colspan="7"><img height="1" src="{$param_imageserver}/styles/Contemporary/{pageset/color}/spacer.gif" width="1" border="0" /></td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
  </body>
</html>
</xsl:template>
<xsl:template name="formatArticle">
  <xsl:param name="blkid" />
  <xsl:variable name="titulo" select="paragraphs/paragraph[starts-with(@id,'TITULO_ARTICULO')]"/>
  <table cellspacing="0" cellpadding="0" width="100%" border="0">
    <tbody>
      <tr>
        <td colspan="2" class="TP_TITULO_ARTICULO"><xsl:value-of select="paragraphs/paragraph[starts-with(@id,'TITULO_ARTICULO')]/text" disable-output-escaping="no"/></td>
      </tr>
      <tr>
        <td colspan="2" class="TP_fondo5"><img height="1" src="{$param_imageserver}/images/spacer.gif" width="10" border="0" /></td>
      </tr>
      <tr>
        <td class="TP_ARTICULO_cell" style="text-align:justify;padding-right:3px">
          <xsl:for-each select="paragraphs/paragraph[starts-with(@id,'PARRAFO_ARTICULO')]">
            <xsl:sort select="@id"/>
            <xsl:choose>
              <xsl:when test="url=''">
                <div class="TP_PARRAFO_ARTICULO"><xsl:value-of select="text"/></div>
              </xsl:when>
              <xsl:otherwise>
                <div class="TP_PARRAFO_ARTICULO"><a class="TP_PARRAFO_ARTICULO_link" target="_blank" href="{url}"><xsl:value-of select="text"/></a></div>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </td>
        <xsl:if test="images/image[@id='IMAGEN_ARTICULO']!=''">
        <td class="TP_IMAGEN_ARTICULO">
          <xsl:variable name="logoArt" select="images/image[@id='IMAGEN_ARTICULO']"/>
          <xsl:choose>
            <xsl:when test="images/image[@id='IMAGEN_ARTICULO']/url!=''">
              <a target="_blank" href="{$logoArt/url}">
              <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/width!=''">
              <img alt="{$logoArt/alt}" src="{$logoArt/path}" width="{$logoArt/width}" height="{$logoArt/height}" border="0" />
              </xsl:if>
              <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/width=''">
              <img alt="{$logoArt/alt}" src="{$logoArt/path}" border="0" />
              </xsl:if>
              </a>
            </xsl:when>
            <xsl:otherwise>
	      <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/width!=''">
              <img alt="{$logoArt/alt}" src="{$logoArt/path}" width="{$logoArt/width}" height="{$logoArt/height}" border="0" />
              </xsl:if>
	      <xsl:if test="images/image[@id='IMAGEN_ARTICULO']/width=''">
              <img alt="{$logoArt/alt}" src="{$logoArt/path}" border="0" />
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </td>
        </xsl:if>
      </tr>
      <tr>
        <td colspan="2">
          <xsl:for-each select="paragraphs/paragraph[starts-with(@id,'ENLACE_ARTICULO')]"><xsl:sort select="@id"/>
            <div class="TP_ENLACE_ARTICULO_div"><a class="TP_ENLACE_ARTICULO" target="_blank" href="{url}"><xsl:value-of select="text"/></a></div>
          </xsl:for-each>
        </td>
      </tr>
    </tbody>
  </table>
</xsl:template></xsl:stylesheet>