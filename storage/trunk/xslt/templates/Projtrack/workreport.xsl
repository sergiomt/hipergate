<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_logo" />
<xsl:template match="/">
<HTML xmlns="http://www.w3.org/1999/xhtml">
<HEAD>
  <META http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <TITLE>[~Parte de Trabajo~] <xsl:value-of select="DutiesWorkReport/tl_workreport"/></TITLE>
  <STYLE type="text/css">
  <xsl:comment>
    BODY,TH,TD { font-family:verdana,arial,helvetica;font-size:9pt;color:#000; }
  </xsl:comment>
  </STYLE>
</HEAD>
<BODY>
  <H1>[~PARTE DE TRABAJO~]</H1>
  <BR/>
  <B>[~Proyecto:~]</B>&#160;<xsl:value-of select="DutiesWorkReport/Project/nm_project" /><BR/>
  <B>[~Redactor:~]</B>&#160;<xsl:value-of select="DutiesWorkReport/Writer/tx_full_name" /><BR/>
  <B>[~Fecha:~]</B>&#160;<xsl:value-of select="DutiesWorkReport/dt_created" /><BR/>
  <B>[~Resumen:~]</B>&#160;<xsl:value-of select="DutiesWorkReport/de_workreport" /><BR/>

  <xsl:for-each select="DutiesWorkReport/Duties/Duty">
    <HR/>
    <H2>[~Tarea:~]&#160;<xsl:value-of select="nm_duty" /></H2><BR/>
	  <B>[~Estado:~]</B>&#160;<xsl:value-of select="tx_status" /><BR/>
	  <B>[~Prioridad:~]</B>&#160;<xsl:value-of select="od_priority" /><BR/>
	  <B>[~Coste:~]</B>&#160;<xsl:value-of select="pr_cost" /><BR/>
	  <B>[~Porcentaje completado:~]</B>&#160;<xsl:value-of select="pct_complete" />%<BR/>
	  <B>[~Fecha prevista de inicio:~]</B>&#160;<xsl:value-of select="dt_scheduled" /><BR/>
	  <B>[~Fecha real de inicio:~]</B>&#160;<xsl:value-of select="dt_start" /><BR/>
	  <B>[~Fecha de finalización:~]</B>&#160;<xsl:value-of select="dt_end" /><BR/>
	  <B>[~Duración:~]</B>&#160;<xsl:value-of select="ti_duration" /><BR/>
	  <B>[~Recursos:~]</B>&#160;<xsl:for-each select="DutiesWorkReport/Duties/Duty/Resources"><xsl:value-of select="Resource" />,&#160;</xsl:for-each><BR/>
	  <B>[~Descripción:~]</B>&#160;<xsl:value-of select="de_duty" /><BR/>
	  <B>[~Comentarios:~]</B>&#160;<xsl:value-of select="tx_comments" /><br/>
	      
  </xsl:for-each>

  
</BODY>
</HTML>
</xsl:template>
</xsl:stylesheet>