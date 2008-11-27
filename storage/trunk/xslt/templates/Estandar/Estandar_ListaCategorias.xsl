<!DOCTYPE xsl:stylesheet SYSTEM "http://www.hipergate.org/xslt/schemas/entities.dtd">
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/jsp" omit-xml-declaration="yes"/>
<xsl:param name="param_page"/>
<xsl:param name="param_domain"/>
<xsl:param name="param_workarea"/>
<xsl:param name="param_pageset"/>
<xsl:param name="param_imageserver"/>
<xsl:param name="param_storage"/>
<xsl:include href="../Portlet.xsl"/>
<xsl:template match="/">
<xsl:call-template name="portlet"/>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="cache-control" content="no-store" />
    <meta http-equiv="Expires" content="0" />
    <title><xsl:value-of select="$param_page"/></title>
    <link rel="stylesheet" href="{$param_imageserver}/styles/estandar/{pageset/color}/{pageset/font}.css" />    
    <script language="javascript">
    <xsl:comment>
    <![CDATA[
    	editMode = '';

	function callPage(page) { 
	  if (editMode=='_')
	   document.location = "../../../../../../webbuilder/wb_document.jsp?gu_workarea="+frmLstBlocks.gu_workarea.value+"&gu_pageset="+frmLstBlocks.gu_pageset.value+"&doctype=website&page="+page; 
	  else
	   document.location = "./" + page + ".html"; 
	}

	function MM_openBrWindow(theURL,winName,features) { 
		window.open(theURL,winName,features);
	}

	function mOvr(src,clrOver) {
		if (!src.contains(event.fromElement)) {
			src.style.cursor = 'default';src.bgColor = clrOver;
		}
	}

	function mOut(src,clrIn) {
		if (!src.contains(event.toElement)) {
			src.style.cursor = 'default';src.bgColor = clrIn;
		}
	}
    ]]>
    </xsl:comment>
    </script>
  </head>
<xsl:variable name="logo" select="pageset/pages/page[title = 'Recursos']/blocks/block[metablock='LOGOTIPO']/images/image"/>
<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<!-- Tabla Principal toda la página -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td align="left" valign="bottom"><img src="{$param_imageserver}/styles/estandar/{pageset/color}/predefinidas/imagen1-4.jpg" border="0"/></td>
          <td name="LOGOTIPO_1" id="LOGOTIPO_1" align="right">
            <xsl:if test="$logo/url=''">
              <img alt="{$logo/alt}" src="{$logo/path}" width="{$logo/width}" height="{$logo/height}" border="0"/>
            </xsl:if>
            <xsl:if test="$logo/url!=''">
              <a href="{$logo/url}"><img alt="{$logo/alt}" src="{$logo/path}" width="{$logo/width}" height="{$logo/height}" border="0"/></a>
            </xsl:if>
          </td>
        </tr>
      </table>
      <table width="368" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td colspan="2" width="100%" align="left" valign="bottom" background="{$param_imageserver}/styles/estandar/{pageset/color}/1_bot.jpg">&nbsp;</td>
        </tr>
      </table>
      <table width="100%" border="0" cellspacing="1" cellpadding="0">
        <tr>
          <td class="fondomenui" width="100%" align="right">
            <img src="{$param_imageserver}/styles/estandar/{pageset/color}/nav_remate.gif" width="3" height="21" />
          </td>
          <xsl:for-each select="pageset/pages/page[title = 'Recursos']/blocks/block[metablock='MENU']/paragraphs/paragraph">
          <xsl:sort select="@id"/>
          <td bgcolor="#8081af">
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td class="subcategoria">
                  <img src="{$param_imageserver}/styles/estandar/{../../../../../../color}/remate_nav_izq.gif" width="3" height="21" />
                </td>
                <td class="subcategoria" nowrap="nowrap">
                  <a href="{url}" class="menu"><span style="text-transform:uppercase;" class="menu"><xsl:value-of select="text"/></span></a>&nbsp;
                </td>
              </tr>
            </table>
          </td>
          </xsl:for-each>
        </tr>
      </table>

      <span id="ENTRADA_1" name="ENTRADA_1">
      <table name="MSuperior03" cellspacing="0" cellpadding="0" border="0" width="100%" class="fondocabeceranaranja">
        <tr>
          <td colspan="5" class="fondocabecerai">
            <img src="{$param_imageserver}/styles/estandar/{pageset/color}/pixeltrans.gif" width="10" height="10" />
          </td>
        </tr>
        <tr>
          <td class="fondocabecerai" colspan="2" valign="MIDDLE">&nbsp;
            <img src="{$param_imageserver}/styles/estandar/{pageset/color}/recuadroTit.gif" align="absmiddle" width="27" height="19" alt="" border="0" hspace="2" vspace="0" />&nbsp;
            <span class="titularseccion" style="text-transform:uppercase;">CATEGOR&Iacute;AS DE PRODUCTOS</span>
          </td>
          <td class="fondocabeceraiii" width="30">
            <img src="{$param_imageserver}/styles/estandar/{pageset/color}/cierre.gif" width="34" height="34" alt="" border="0" /></td>
          <td class="fondocabeceraiii" colspan="2">
            <img src="{$param_imageserver}/styles/estandar/{pageset/color}/enviarimprimir.gif" width="251" height="31" border="0" usemap="#Map1" />
            <map id="Map1" name="Map1">
              <area shape="rect" coords="3,5,153,26" href="javascript:recomendar();" />
              <area shape="rect" coords="158,5,243,25" href="javascript:window.print();" />
            </map> 
          </td>
        </tr>
        <tr>
          <td class="fondocabeceraiii" width="120" />
          <td class="fondocabeceraiii" width="100%" />
          <td class="fondocabeceraiii" width="30">&nbsp;</td>
          <td colspan="2" class="fondocabeceraii"><img src="{$param_imageserver}/styles/estandar/{pageset/color}/cierret.gif" width="18" height="18" alt="" border="0" /></td>
        </tr>
        <tr class="fondocabeceraii">
          <td width="105" class="fondocabecerai"><img src="{$param_imageserver}/styles/estandar/{pageset/color}/pixeltrans.gif" width="105" height="1" /></td>
          <td class="fondocabeceraii" colspan="4">
            <!--
            <img src="{$param_imageserver}/styles/estandar/{pageset/color}/recuadro_1.gif" width="18" height="19" alt="" border="0" />&nbsp;
            <span class="titular2"><span class="textobienvenida">Subtitulo de Categorias</span></span>
            -->
          </td>
        </tr>
      </table>
      </span>

      <xsl:text disable-output-escaping="yes"><![CDATA[<%]]></xsl:text>

        portletRequest.setAttribute ("template", sTemplatesPath + "Estandar_ListaCategorias_Portlet.xsl");

        RenderPortlet ("CategoryList", out, GlobalPortletConfig, portletRequest, portletResponse);
        
      <xsl:text disable-output-escaping="yes"><![CDATA[%>]]></xsl:text>
      
      <br/><br/><br/><br/>
      
      <table width="100%" border="0" cellspacing="0" cellpadding="0" class="fondocabeceraii">
        <tr align="right">
        <td>
          <a href="http://www.hipergate.org" target="_blank">
            <img src="{$param_imageserver}/styles/estandar/{pageset/color}/powerd_horizontal.gif" alt="" border="0" vspace="10" hspace="10" />
          </a>
        </td>
        </tr>
      </table>

      <form name="hojas" id="hojas">
        <input type="hidden" name="ohoja" id="ohoja" value="quienes.html" />
      </form>
      </td>
    </tr>
  </table>    
</body>
</html>
</xsl:template>
</xsl:stylesheet>
