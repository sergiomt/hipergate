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
  <H1>[~INSTANTÁNEA DE PROYECTO~]</H1>
  <BR/>
  <B>[~Creador:~]</B>&#160;<xsl:value-of select="ProjectSnapshot/tx_full_name" /><BR/>
  <B>[~Fecha:~]</B>&#160;<xsl:value-of select="ProjectSnapshot/dt_created" /><BR/>

  <H2>[~Proyecto:~]&#160;<xsl:value-of select="ProjectSnapshot/Project/nm_project" /></H2><BR/>
	<B>[~Estado:~]</B>&#160;<xsl:value-of select="ProjectSnapshot/Project/id_status" /><BR/>
	<B>[~Coste:~]</B>&#160;<xsl:value-of select="ProjectSnapshot/Project/pr_cost" /><BR/>
	<B>[~Inicio previsto:~]</B>&#160;<xsl:value-of select="ProjectSnapshot/Project/dt_scheduled" /><BR/>
	<B>[~Inicio real:~]</B>&#160;<xsl:value-of select="ProjectSnapshot/Project/dt_start" /><BR/>
	<B>[~Finalización:~]</B>&#160;<xsl:value-of select="ProjectSnapshot/Project/dt_end" /><BR/>

  <xsl:if test="ProjectSnapshot/Project/Duties/@count!='0'">
    <H2>[~Tareas~]&#160;(<xsl:value-of select="ProjectSnapshot/Project/Duties/@count" />)</H2>
    <xsl:for-each select="ProjectSnapshot/Project/Duties/Duty">
      <H3>[~Tarea:~]&#160;<xsl:value-of select="nm_duty" /></H3><BR/>
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
  </xsl:if>
  
  <xsl:if test="ProjectSnapshot/Project/Bugs/@count!='0'">
    <H2>[~Incidencias~]&#160;(<xsl:value-of select="ProjectSnapshot/Project/Bugs/@count" />)</H2>
    <xsl:for-each select="ProjectSnapshot/Project/Bugs/Bug">
      <H3>[~Incidencia:~]&#160;<xsl:value-of select="tl_bug" /></H3><BR/>
	    <B>[~Estado:~]</B>&#160;<xsl:value-of select="tx_status" /><BR/>
	    <B>[~Prioridad:~]</B>&#160;<xsl:value-of select="od_priority" /><BR/>
	    <B>[~Fecha:~]</B>&#160;<xsl:value-of select="dt_created" /><BR/>
	    <B>[~Descripción:~]</B>&#160;<xsl:value-of select="tx_bug_brief" /><BR/>
	    <B>[~Comentarios:~]</B>&#160;<xsl:value-of select="tx_comments" /><BR/>
	    <B>[~Más Info:~]</B>&#160;<xsl:value-of select="tx_bug_info" /><BR/>
    </xsl:for-each>
  </xsl:if>

  <xsl:for-each select="ProjectSnapshot/Project/Subprojects/Project">
    <xsl:call-template name="formatProject"/>	      
  </xsl:for-each>
  
</BODY>
</HTML>
</xsl:template>

<xsl:template name="formatProject">
    <BR/><HR/>
    <H2>[~Subproyecto:~]&#160;<xsl:value-of select="nm_project" /></H2><BR/>
	  <B>[~Estado:~]</B>&#160;<xsl:value-of select="id_status" /><BR/>
	  <B>[~Coste:~]</B>&#160;<xsl:value-of select="pr_cost" /><br/>
	  <B>[~Inicio previsto:~]</B>&#160;<xsl:value-of select="dt_scheduled" /><BR/>
	  <B>[~Inicio real:~]</B>&#160;<xsl:value-of select="dt_start" /><BR/>
	  <B>[~Finalización:~]</B>&#160;<xsl:value-of select="dt_end" /><BR/>
	  
    <xsl:if test="Duties/@count!='0'">
    <H2>[~Tareas~]&#160;(<xsl:value-of select="Duties/@count" />)</H2>
    <xsl:for-each select="Duties/Duty">
      <H3>[~Tarea:~]&#160;<xsl:value-of select="nm_duty" /></H3><BR/>
      <xsl:if test="tx_status!=''"><B>[~Estado:~]</B>&#160;<xsl:value-of select="tx_status" /><BR/></xsl:if>
	    <xsl:if test="od_priority!=''"><B>[~Prioridad:~]</B>&#160;<xsl:value-of select="od_priority" /><BR/></xsl:if>
	    <xsl:if test="pr_cost!=''"><B>[~Coste:~]</B>&#160;<xsl:value-of select="pr_cost" /><BR/></xsl:if>
	    <xsl:if test="pct_complete!=''"><B>[~Porcentaje completado:~]</B>&#160;<xsl:value-of select="pct_complete" />%<BR/></xsl:if>
	    <xsl:if test="dt_scheduled!=''"><B>[~Fecha prevista de inicio:~]</B>&#160;<xsl:value-of select="dt_scheduled" /><BR/></xsl:if>
	    <xsl:if test="dt_start!=''"><B>[~Fecha real de inicio:~]</B>&#160;<xsl:value-of select="dt_start" /><BR/></xsl:if>
	    <xsl:if test="dt_end!=''"><B>[~Fecha de finalización:~]</B>&#160;<xsl:value-of select="dt_end" /><BR/></xsl:if>
	    <xsl:if test="ti_duration!=''"><B>[~Duración:~]</B>&#160;<xsl:value-of select="ti_duration" /><BR/></xsl:if>
	    <B>[~Recursos:~]</B>&#160;<xsl:for-each select="DutiesWorkReport/Duties/Duty/Resources"><xsl:value-of select="Resource" />,&#160;</xsl:for-each><BR/>
	    <xsl:if test="de_duty!=''"><B>[~Descripción:~]</B>&#160;<xsl:value-of select="de_duty" /><BR/></xsl:if>
	    <xsl:if test="tx_comments!=''"><B>[~Comentarios:~]</B>&#160;<xsl:value-of select="tx_comments" /><BR/></xsl:if>      
    </xsl:for-each>
    </xsl:if>

    <xsl:if test="Bugs/@count!='0'">
    <H2>[~Incidencias~]&#160;(<xsl:value-of select="Bugs/@count" />)</H2>
    <xsl:for-each select="Bugs/Bug">
      <H3>[~Incidencia:~]&#160;<xsl:value-of select="tl_bug" /></H3><BR/>
	    <B>[~Estado:~]</B>&#160;<xsl:value-of select="tx_status" /><BR/>
	    <B>[~Prioridad:~]</B>&#160;<xsl:value-of select="od_priority" /><BR/>
	    <B>[~Fecha:~]</B>&#160;<xsl:value-of select="dt_created" /><BR/>
	    <xsl:if test="tx_bug_brief!=''"><B>[~Descripción:~]</B>&#160;<xsl:value-of select="tx_bug_brief" /><BR/></xsl:if>
	    <xsl:if test="tx_comments!=''"><B>[~Comentarios:~]</B>&#160;<xsl:value-of select="tx_comments" /><BR/></xsl:if>
	    <xsl:if test="tx_bug_info!=''"><B>[~Más Info:~]</B>&#160;<xsl:value-of select="tx_bug_info" /><BR/></xsl:if>
    </xsl:for-each>
    </xsl:if>

    <xsl:for-each select="Subprojects/Project">
      <xsl:call-template name="formatProject"/>	      
    </xsl:for-each>
</xsl:template>

</xsl:stylesheet>