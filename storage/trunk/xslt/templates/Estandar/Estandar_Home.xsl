<!DOCTYPE xsl:stylesheet SYSTEM "http://www.hipergate.org/xslt/schemas/entities.dtd">
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_page"/>
<xsl:param name="param_domain"/>
<xsl:param name="param_workarea"/>
<xsl:param name="param_pageset"/>
<xsl:param name="param_imageserver"/>
<xsl:template match="/">
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
   <a href="{$logo/url}">
   <img alt="{$logo/alt}" src="{$logo/path}" width="{$logo/width}" height="{$logo/height}" border="0"/>
   </a>
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
     <a href="{url}" class="menu">
      <span style="text-transform:uppercase;" class="menu"><xsl:value-of select="text"/></span>
     </a>&nbsp;
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
          <span class="titularseccion" style="text-transform:uppercase;"><xsl:value-of select="pageset/pages/page[title = $param_page]/blocks/block[metablock = 'ENTRADA']/paragraphs/paragraph[@id = 'TITULO']/text" disable-output-escaping="no"/></span>
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
        <td colspan="2" class="fondocabeceraii">
        <img src="{$param_imageserver}/styles/estandar/{pageset/color}/cierret.gif" width="18" height="18" alt="" border="0" /></td>
      </tr>
      <tr class="fondocabeceraii">
        <td width="105" class="fondocabecerai">
        <img src="{$param_imageserver}/styles/estandar/{pageset/color}/pixeltrans.gif" width="105" height="1" /></td>
        <td class="fondocabeceraii" colspan="4">
        <img src="{$param_imageserver}/styles/estandar/{pageset/color}/recuadro_1.gif" width="18" height="19" alt="" border="0" />&nbsp;
        <span class="titular2"><span class="textobienvenida"><xsl:value-of select="pageset/pages/page[title = $param_page]/blocks/block[metablock = 'ENTRADA']/paragraphs/paragraph[@id = 'SUBTITULO']/text" disable-output-escaping="no"/></span></span>
        </td>
      </tr>
    </table>
  </span>

<xsl:for-each select="pageset/pages/page[title = $param_page]/blocks/block[metablock = 'LOGOHOME']">
<xsl:variable name="logohome" select="images/image[@id='LOGO-HOME']" />
  <table id="LOGOHOME_{position()}" name="LOGOHOME_{position()}" width="98%" border="0" cellpadding="5" cellspacing="0">
    <tr>
      <td valign="top" rowspan="2">
        <table border="0" cellpadding="1" cellspacing="0" class="fondoiii">
          <tr>
            <td>
              <table width="100%" border="0" bgcolor="#FFFFFF" cellpadding="0" cellspacing="0">
                <tr>
                  <td>
                  <xsl:if test="$logohome/url!=''">
                    <a href="{$logohome/url}"><img border="0" src="{$logohome/path}" alt="{$logohome/alt}" /></a>
                  </xsl:if>
                  <xsl:if test="$logohome/url=''">
                  <img border="0" src="{$logohome/path}" alt="{$logohome/alt}" />
                  </xsl:if>                  
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </td>
      <td width="100%" valign="top">
        <xsl:if test="paragraphs/paragraph[@id='TEXTO-LOGO']">
          <span class="raq">&raquo;&nbsp;</span>
          <span class="mxxvttextor">
            <xsl:if test="paragraphs/paragraph[@id='TEXTO-LOGO' and ./url!='']">
              <a href="{paragraphs/paragraph[@id='TEXTO-LOGO']/url}"><xsl:value-of select="paragraphs/paragraph[@id='TEXTO-HOME']/text"/></a>
            </xsl:if>
            <xsl:if test="paragraphs/paragraph[@id='TEXTO-LOGO' and ./url='']">
              <xsl:value-of select="paragraphs/paragraph[@id='TEXTO-LOGO']/text"/>
            </xsl:if>
          </span>
        </xsl:if>
        <br/><br/>
        <xsl:if test="paragraphs/paragraph[@id='TEXTO-HOME' and ./url='']">
          <xsl:value-of select="paragraphs/paragraph[@id='TEXTO-HOME']/text"/>
        </xsl:if>
      </td>
    </tr>
    <tr>
      <td width="100%" valign="bottom">

        <table width="100%" border="0" cellpadding="0" cellspacing="0">
          <tr><td height="1" background="{$param_imageserver}/styles/estandar/{/pageset/color}/fondo_linea.gif">
          </td></tr>
          <tr align="left">
            <td class="mxviitentradilla">
              <xsl:for-each select="/pageset/addresses/address[ix_address='1']">   
                <xsl:value-of select="nm_street"/>&nbsp;<xsl:value-of select="nu_street"/><br />
                <xsl:if test="./zipcode!='' or ./nm_state!=''">
                  <xsl:value-of select="zipcode"/>
                  <xsl:if test="./zipcode!='' and ./nm_state!=''">&nbsp;-&nbsp;</xsl:if>
                  <xsl:value-of select="nm_state"/>
                  <br />
                </xsl:if>
                <xsl:if test="address[work_phone!='']">Tlf. <b><xsl:value-of select="work_phone"/></b><br /></xsl:if>
              </xsl:for-each>
            </td>
          </tr>
        </table>

        <table width="100%" border="0" cellpadding="0" cellspacing="0">
          <tr>
            <td background="{$param_imageserver}/styles/estandar/{pageset/color}/fondo_linea.gif">
            <img src="{$param_imageserver}/styles/estandar/{pageset/color}/transpa.gif" width="1" height="1" />
            </td>
          </tr>
        </table>
      </td>
    </tr>
    
  </table>

</xsl:for-each>



<xsl:for-each select="pageset/pages/page[title = $param_page]/blocks/block[metablock = 'FOTOYTEXTO']">
<xsl:sort select="@id"/>
<table id="FOTOYTEXTO_{position()}" name="FOTOYTEXTO_{position()}" background="{$param_imageserver}/styles/estandar/{pageset/color}/fondo_izq.gif" width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td><img src="{$param_imageserver}/styles/estandar/{/pageset/color}/pixeltrans.gif" width="105" height="1" /><br /><br /><br /></td>
<td width="100%" valign="top" class="fondoblanco" align="center">
 <table width="100%" border="0" cellspacing="0" cellpadding="0">
 <tr align="right">
 <td width="100%" height="19">&nbsp;</td>
 </tr>
 </table>
 <table width="97%" border="0" cellspacing="0" cellpadding="0" class="mxxvftabla">
 <tr>
 <td class="mxxvfizq"><img src="{$param_imageserver}/styles/estandar/{/pageset/color}/mod_subtit.gif" hspace="5" vspace="5" /></td>
 <td width="100%" class="mxxvfder">
  <table width="100%" border="0" cellspacing="0" cellpadding="0" class="mxxvfderii">
  <tr>
  <td width="100%"><span class="mxxvttextor"><xsl:value-of select="paragraphs/paragraph[@id='PARRAFO-TITULO']/text" disable-output-escaping="no"/></span> </td>
  </tr>
  </table>
 </td>
 </tr>
 </table>
 <table width="97%" border="0" cellspacing="8" cellpadding="0">
 <tr valign="top">
 <td class="mxviifentradilla" width="100%"><span class="mxviitentradilla"><p align="justify"><xsl:value-of select="paragraphs/paragraph[@id='PARRAFO-INTRO']/text" disable-output-escaping="no"/></p></span></td>
 </tr>
 </table>
 <table width="97%" border="0" cellspacing="8" cellpadding="0">
 <tr valign="top">
 <td align="right" width="250">
  <table border="0" cellspacing="0" cellpadding="0">
  <tr background="{$param_imageserver}/styles/estandar/{/pageset/color}/transpa.gif">
  <xsl:variable name="fotoarticulo" select="images/image[@id='FOTO-ARTICULO']" />
  <xsl:if test="$fotoarticulo/url=''">
  <td><img border="0" vspace="1" hspace="1" src="{$fotoarticulo/path}" width="{$fotoarticulo/width}" height="{$fotoarticulo/height}" alt="{$fotoarticulo/alt}" /></td>
  </xsl:if>
  <xsl:if test="$fotoarticulo/url!=''">
  <td><a href="{$fotoarticulo/url}"><img border="0" vspace="1" hspace="1" src="{$fotoarticulo/path}" width="{$fotoarticulo/width}" height="{$fotoarticulo/height}" alt="{$fotoarticulo/alt}" /></a></td>
  </xsl:if>
  </tr>
  </table>
 </td>
 <td class="mxifentradilla" width="100%"><span class="mxiiitentradilla"><p align="justify"><xsl:value-of select="paragraphs/paragraph[@id='PARRAFO-ARTICULO']/text" disable-output-escaping="no"/></p></span> </td>
 </tr>
 </table>
</td>
</tr>
</table>
</xsl:for-each>

<table width="95%" border="0" cellpadding="0" cellspacing="0">
 <tr>
 <xsl:if test="pageset/pages/page[title = $param_page]/blocks/block[metablock = 'DOCUMENTO']">
  <td name="DOCUMENTO_1" id="DOCUMENTO_1" valign="top">
   <table width="95%" border="0" cellspacing="0" cellpadding="0">
    <tr>
     <td width="18" class="fondoi" align="left" valign="middle"><img align="middle" src="{$param_imageserver}/styles/estandar/{/pageset/color}/recuadro.gif" width="18" height="17" /></td>
     <td width="100%" class="fondoi"><span class="titularseccion">&nbsp;ARCHIVOS ADJUNTOS</span></td>
    </tr>
   </table>
   <xsl:for-each select="pageset/pages/page[title = $param_page]/blocks/block[metablock = 'DOCUMENTO']/paragraphs/paragraph[starts-with(@id,'DOCUMENTO')]"> 
   <table width="95%" border="0" cellspacing="0" cellpadding="0">
    <tr>
     <td width="18" class="navegacionoff"><img src="{$param_imageserver}/styles/estandar/{/pageset/color}/pixeltrans.gif" width="18" height="1" /></td>
     <td width="100%" align="left" valign="middle" class="enlaces">
      <b class="raq">::</b>
      <xsl:if test="url!=''">
      <a target="_blank" href="{url}" class="textolinks">
       <span class="links"><xsl:value-of select="text" disable-output-escaping="no"/></span>
      </a>
      </xsl:if>
      <xsl:if test="url=''">
       <span class="links"><xsl:value-of select="text" disable-output-escaping="no"/></span>
      </xsl:if>
     </td>
    </tr>
   </table>
   </xsl:for-each>
   <br />
  </td>
  </xsl:if>
  <xsl:if test="pageset/pages/page[title = $param_page]/blocks/block[metablock = 'ENLACE']">
  <td width="10"><img src="{$param_imageserver}/styles/estandar/{/pageset/color}/pixeltrans.gif" width="10" height="10" /></td>
  <td name="ENLACE_1" id="ENLACE_1" valign="top">
   <table width="95%" border="0" cellspacing="0" cellpadding="0">
    <tr>
     <td width="18" class="fondoi" align="left" valign="middle"><img align="middle" src="{$param_imageserver}/styles/estandar/{/pageset/color}/recuadro.gif" width="18" height="17" /></td>
     <td width="100%" class="fondoi"><span class="titularseccion">&nbsp;ENLACES RELACIONADOS</span></td>
    </tr>
   <xsl:for-each select="pageset/pages/page[title = $param_page]/blocks/block[metablock = 'ENLACE']/paragraphs/paragraph[starts-with(@id,'ENLACE')]"> 
    <tr>
     <td width="18" class="navegacionoff"><img src="{$param_imageserver}/styles/estandar/{/pageset/color}/pixeltrans.gif" width="18" height="1" /></td>
     <td width="100%" align="left" valign="middle" class="enlaces">
      <b class="raq">::</b>
      <xsl:if test="url!=''">
      <a target="_blank" href="{url}" class="textolinks">
       <span class="links"><xsl:value-of select="text" disable-output-escaping="no"/></span>
      </a>
      </xsl:if>
      <xsl:if test="url=''">
       <span class="links"><xsl:value-of select="text" disable-output-escaping="no"/></span>
      </xsl:if>
     </td>
    </tr>
   </xsl:for-each>
   </table>
   <br />
  </td>
  </xsl:if>
 </tr>
</table>

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
