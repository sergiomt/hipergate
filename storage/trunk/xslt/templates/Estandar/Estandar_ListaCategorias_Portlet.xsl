<!DOCTYPE xsl:stylesheet SYSTEM "http://www.hipergate.org/xslt/schemas/entities.dtd">
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_imageserver"/>
<xsl:param name="param_color"/>
<xsl:template match="/">

      <table border="0" cellspacing="8" cellpadding="0" width="97%" class="fondoblanco">

	<xsl:for-each select="/categories/category">
	<xsl:if test="(position() mod 2)=1">
	<xsl:text disable-output-escaping="yes"><![CDATA[<tr valign="top">]]></xsl:text>
        </xsl:if>
          <td width="50%">
	    <table width="100%" border="0" cellspacing="0" cellpadding="0" class="miiiftitular">
              <tr>
	        <td class="miiiftitularizq"><img src="{$param_imageserver}/styles/estandar/{$param_color}/recuadro.gif" alt="" border="0" vspace="0" hspace="0" /></td>
		<td class="miiiftitularder" width="100%">
		  <table width="100%" border="0" cellspacing="0" cellpadding="0" class="miiftitularderii">
		    <tr valign="MIDDLE">
		      <td><a href="Estandar_Categoria.jsp?category={gu_category}&amp;offset=0&amp;limit=6" style="text-decoration: none" class="miiittitular"><span class="miiittitular"><xsl:value-of select="tr_category"/></span></a></td>
		    </tr>
		  </table>
		</td>
	      </tr>
	      <xsl:if test="images/image">
	      <tr>
	        <td></td>
	        <td>
		  <table border="0" cellspacing="0" cellpadding="0" width="100%">
		    <tr>
	              <td class="miiifborde" background="{$param_imageserver}/styles/estandar/{$param_color}/transpa.gif">
	                <img src='{images/image/src_image}' border="0" alt="{images/image/tl_image}"/></td>
	              <td valign="bottom" width="100%" background="{$param_imageserver}/styles/estandar/{$param_color}/mod_fondo_puntos.gif"> </td>
	            </tr>
                  </table>
                </td>
              </tr>
              </xsl:if>
	      <tr valign="top">
	        <td></td>
		<td>
		  <table border="0" cellspacing="2" cellpadding="0" width="100%">
		    <tr>
		      <td class="miiifentradilla" width="100%"><span class="textomodulo"><span class="miiitentradilla"><xsl:value-of select="de_category"/></span></span></td>
		    </tr>
                  </table>
	        </td>
	      </tr>
	    </table>
	  </td>
	<xsl:if test="(position() mod 2)=0">
	<xsl:text disable-output-escaping="yes"><![CDATA[</tr>]]></xsl:text>
	</xsl:if>
	
	</xsl:for-each>
      </table>
     
</xsl:template>
</xsl:stylesheet>
