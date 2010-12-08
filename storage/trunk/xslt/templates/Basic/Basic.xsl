<!DOCTYPE xsl:stylesheet SYSTEM "http://www.hipergate.org/xslt/schemas/entities.dtd">
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>

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
 <LINK rel="stylesheet" type="text/css" href="{$param_imageserver}/styles/basic/{pageset/color}/{pageset/font}.css" />
</HEAD>

<BODY CLASS="htmlbody">
 &#160;
 <CENTER>
  <TABLE border="0" cellPadding="0" cellSpacing="0" width="650">
   <TBODY>
    <TR>
     <TD><img src="{$param_imageserver}/styles/basic/{pageset/color}/spacer.gif" width="1" height="1" border="0" /></TD>
    </TR>
    <TR>
     <TD width="646">
      <CENTER>
       <TABLE border="0" cellPadding="0" cellSpacing="0" width="85%">
        <TBODY>
          <TR>
           <TD colSpan="2">&#160; </TD>
          </TR>
          <TR>
           <TD align="middle" colSpan="2" vAlign="top" width="100%">
            <TABLE cellPadding="5" width="95%" >
             <TBODY>
              <xsl:comment> Comienza el encabezado poniendo el logo de la empresa </xsl:comment>
              <xsl:variable name="logo" select="pageset/pages/page/blocks/block[metablock='LOGOSUPERIOR']/images/image"/>                                 
              <TR>             
               <TD>
                <TABLE bgColor="#ffffff" border="0" cellPadding="0" cellSpacing="0" width="100%">
                 <TBODY>
                  <TR>
                   <TD>
                    <span name="LOGOSUPERIOR_1" id="LOGOSUPERIOR_1">                       
            	        <xsl:if test="pageset/pages/page/blocks/block[metablock='LOGOSUPERIOR']/images/image/width!=''">
            	          <img alt="{$logo/alt}" src="{$logo/path}" width="{$logo/width}" height="{$logo/height}" border="0" />         
            	        </xsl:if>
            	        <xsl:if test="pageset/pages/page/blocks/block[metablock='LOGOSUPERIOR']/images/image/width=''">
            	          <img alt="{$logo/alt}" src="{$logo/path}" border="0" />         
            	        </xsl:if>
                    </span>              
                    <xsl:comment> Final del logo principal </xsl:comment>  
                    <xsl:comment> Comienza la Minicabecera </xsl:comment> 
                    <span name="CABECERA_1" id="CABECERA_1"> 
                     <font class="plaintext"><BR></BR>~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<BR></BR></font>
                     <xsl:variable name="cab" select="pageset/pages/page/blocks/block[metablock='CABECERA']/paragraphs"/>
                     <font class="subtitle"><b><xsl:value-of select="$cab/paragraph[@id='CABECERA-TEXTO']/text" disable-output-escaping="no"/></b><br /></font>
                     <font class="plaintext"><xsl:value-of select="$cab/paragraph[@id='CABECERA-FECHA']/text" disable-output-escaping="no"/></font>
                    </span>
                    <font class="plaintext">
                     <BR></BR>~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<BR></BR>
                     <xsl:comment> Principio de Bienvenida </xsl:comment>                                                
                     <b>En este numero...</b>
                    </font>
                    <span name="SUMARIO_1" id="SUMARIO_1">
                     <ul>
                      <xsl:for-each select="pageset/pages/page/blocks/block[metablock='ARTICULO']/paragraphs/paragraph[starts-with(@id,'TITULO-ARTICULO')]">
                       <xsl:sort select="../../@id"/>
                       <li style="list-style: none">
                        <font class="plaintext"><a href="{@url}"><xsl:value-of select="text" disable-output-escaping="no"/></a></font>
                       </li>
                      </xsl:for-each>
                     </ul>  
                    </span>
                    <br></br>
                    <xsl:variable name="cab" select="pageset/pages/page/blocks/block[metablock='BIENVENIDA']/paragraphs"/>
                    <span name="BIENVENIDA_1" id="BIENVENIDA_1">
                     <font class="plaintext"><xsl:value-of select="$cab/paragraph[@id='BIENVENIDA-TEXTO']"/></font>                                                          
                     <xsl:comment> Final de la Bienvenida </xsl:comment>
                    </span>
                    <br /><br />
                    <span name="DESTACADO_1" id="DESTACADO_1">
                    <font class="plaintext">
                     <br />
                     <xsl:variable name="destacado" select="pageset/pages/page/blocks/block[metablock='DESTACADO']"/>
                     <b><xsl:value-of select="$destacado/paragraphs/paragraph[@id='TITULO-DESTACADO']" disable-output-escaping="no"/></b>
                     <BR></BR>~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<BR></BR>
                    </font> 
                    <xsl:variable name="destacado" select="pageset/pages/page/blocks/block[metablock='DESTACADO']/images/image"/>
                    
                     <xsl:if test="pageset/pages/page/blocks/block[metablock='DESTACADO']/images/image/width!=''">
                      <img alt="{$destacado/alt}" src="{$destacado/path}" width="{$destacado/width}" height="{$destacado/height}" border="0"/>         
                     </xsl:if>
                     <xsl:if test="pageset/pages/page/blocks/block[metablock='DESTACADO']/images/image/width=''">
                      <img alt="{$destacado/alt}" src="{$destacado/path}" border="0"/>         
                     </xsl:if>
                    
                    <br />
                    <xsl:variable name="destacado" select="pageset/pages/page/blocks/block[metablock='DESTACADO']"/>
                    <xsl:for-each select="$destacado/paragraphs/paragraph[starts-with(@id,'TEXTO-DESTACADO')]">
                     <p><font class="plaintext"><xsl:value-of select="text" disable-output-escaping="no" /></font></p>
                    </xsl:for-each> 
                    <br /><br />
                    <xsl:variable name="destacado" select="pageset/pages/page/blocks/block[metablock='DESTACADO']"/>
                    <xsl:for-each select="$destacado/paragraphs/paragraph[starts-with(@id,'ENLACE')]">
                     <p><a style="COLOR: #000000" href="{url}"><font class="plaintext"><xsl:value-of select="text" disable-output-escaping="no"/></font></a></p>
                    </xsl:for-each>
                    <br />
                   </span>
                   <xsl:comment> Principio del Formato de Articulos </xsl:comment>             
                   <xsl:for-each select="pageset/pages/page/blocks/block[metablock='ARTICULO']">	
                     <xsl:comment> Llama al Template en el que se escribe el articulo </xsl:comment>		
                     <xsl:call-template name="formatArticle">
                     <xsl:with-param name="blkid" select="@id"/>
                     </xsl:call-template>                        
		               </xsl:for-each>		      
                   <xsl:comment> Final del Formato de articulos </xsl:comment>
                   <span name="LINKS_1" id="LINKS_1">
                    <xsl:variable name="links" select="pageset/pages/page/blocks/block[metablock='LINKS']"/>  
                    <br /><br />
                    <font class="plaintext"><b><xsl:value-of select="$links/paragraphs/paragraph[@id='TITULO-LINKS']" disable-output-escaping="no"/></b></font>
                    <font class="plaintext"><BR></BR>~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<BR></BR></font>
                    <font class="plaintext">
                     <xsl:for-each select="pageset/pages/page/blocks/block[metablock='LINKS']/paragraphs/paragraph[starts-with(@id,'ENLACE')]">
                      <a style="COLOR #000000" href="{url}">
                       <xsl:value-of select="text" disable-output-escaping="no"/>
                      </a>
                      <br />
                     </xsl:for-each>
                    </font>  
                   </span>
                  </TD>
                 </TR>
                </TBODY>
               </TABLE>
              </TD>
             </TR>
            </TBODY>
           </TABLE>
          </TD>
         </TR>
        </TBODY>
       </TABLE>
      </CENTER>
     </TD>
    </TR>
   </TBODY>
  </TABLE>
 </CENTER>
</BODY>
</HTML>
</xsl:template>

<xsl:template name="formatArticle">
<xsl:param name="blkid"/>
<xsl:variable name="titulo" select="paragraphs/paragraph[starts-with(@id,'TITULO')]"/>
<a id="{$titulo/@url}" name="{$titulo/@url}"></a>
 <table cellspacing="0" cellpadding="0" width="100%" border="0">
  <tbody>
   <tr>
    <td valign="top" name="ARTICULO_{position()}" id="ARTICULO_{position()}">
     <br></br>
     <font class="plaintext">
      <b><xsl:value-of select="$titulo/text" disable-output-escaping="no"/></b>
      <BR></BR>~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<BR></BR>
     </font>
    </td>
   </tr>
   <tr>
    <td valign="top">
     <img src="{$param_imageserver}/styles/basic/{pageset/color}/spacer.gif" width="1" height="1" border="0" />
    </td>
   </tr>
   <tr>
    <td valign="center" align="left">
     <xsl:for-each select="paragraphs/paragraph[starts-with(@id,'PARRAFO')]">
      <xsl:sort select="@id"/>
      <p><font class="plaintext"><xsl:value-of select="text" disable-output-escaping="no"/></font></p>
     </xsl:for-each>
     <xsl:for-each select="paragraphs/paragraph[starts-with(@id,'ENLACE')]">			      
      <p align="left">
       <font class="plaintext"><a style="COLOR: #000000" href="{url}"><xsl:value-of select="text" disable-output-escaping="no"/></a>&#187;</font>
      </p>
     </xsl:for-each>
    </td>
   </tr>
  </tbody>
 </table>
</xsl:template>
</xsl:stylesheet>