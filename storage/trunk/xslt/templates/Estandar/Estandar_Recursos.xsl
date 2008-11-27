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
<xsl:variable name="logo" select="pageset/pages/page[title = $param_page]/blocks/block[metablock='LOGOTIPO']/images/image"/>
<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<font face="Verdana" size="3"><b>&nbsp;Recursos comunes</b></font><br/>
<font face="Verdana" size="2"><p align="justify">&nbsp;Esta pagina es un agregador de recursos comunes a todas las paginas de la web. No sera visible al navegar la web.</p></font><br/>
<table border="0" cellspacing="1" cellpadding="0">
<tr><td colspan="2"><hr size="1"/></td></tr>
<xsl:comment>Inicio Logotipo</xsl:comment>
<tr name="LOGOTIPO_1" id="LOGOTIPO_1">
<td valign="top"><font face="Verdana" size="2"><b>&nbsp;:: Logotipo&nbsp;&nbsp;</b></font></td>
<td valign="middle" align="left"><img valign="middle" alt="{$logo/alt}" src="{$logo/path}" width="{$logo/width}" height="{$logo/height}" border="0"/></td>
</tr>
<tr><td colspan="2"><hr size="1"/></td></tr>
<xsl:comment>Fin Logotipo</xsl:comment>
<xsl:comment>Inicio Menu</xsl:comment>
<tr name="MENU_1" id="MENU_1">
<td valign="top"><font face="Verdana" size="2"><b>&nbsp;:: Menu&nbsp;&nbsp;</b></font><br/></td>
<td valign="middle">
<table>
<tr>
<xsl:for-each select="pageset/pages/page[title = $param_page]/blocks/block[metablock='MENU']/paragraphs/paragraph">
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
</td>
</tr>
<tr><td colspan="2"><hr size="1"/></td></tr>
<xsl:comment>Fin Menu</xsl:comment>
</table>
<br />
<table width="100%" border="0" cellspacing="0" cellpadding="0">
 <tr align="left">
  <td>
    <a href="http://www.hipergate.org" target="_blank">
     <img src="{$param_imageserver}/styles/estandar/{pageset/color}/powerd_horizontal.gif" alt="" border="0" vspace="10" hspace="10" />
    </a>
  </td>
 </tr>
</table>
</body>
</html>
</xsl:template>
</xsl:stylesheet>
