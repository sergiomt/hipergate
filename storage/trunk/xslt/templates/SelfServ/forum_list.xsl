<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:include href="left_menu.xsl" />
<xsl:template match="/">

<TABLE class="BodyTable" cellspacing="0" cellpadding="0" border="0">
  <TR>
    <TD class="Crumb" colspan="3">
      <TABLE width="100%" cellspacing="0" cellpadding="0" border="0" align="left" summary="you are here">
	<TR>
	  <TD width="100%" bgcolor="#c9282d" height="1"></TD>
        </TR>
	<TR>
	  <TD class="Breadcrumb" align="left">Fundaci&#243;n Comillas > Comunidades > Foros</TD>
        </TR>
	<TR>
	  <TD width="100%" bgcolor="#c9282d" height="1"></TD>
        </TR>
      </TABLE>
    </TD>
  </TR>
</TABLE>
<TABLE class="BodyTable" cellspacing="0" cellpadding="0" border="0">
  <TR>
	<xsl:call-template name="leftmenu"/>
	<TD class="mainColumn">
	  <DIV id="mainColumnRound"> 
	  <H1>Foro <xsl:value-of select="Forums/NewsGroup/labels/label[@id_language='es']" disable-output-escaping="no"/></H1>
	  <FORM NAME="radios" METHOD="get" ACTION="forum_search.jsp" onsubmit="return (document.forms['radios'].tx_sought.value.length!=0)">
	    <INPUT TYPE="hidden" NAME="gu_newsgrp" VALUE="{Forums/NewsGroup/gu_newsgrp}" />
	    <TABLE SUMMARY="Caja de Busqueda" WIDTH="100%">
	      <TR>
	        <TD ALIGN="left">&#160;&#160;&#160;&#160;<A HREF="#" onclick="createMessage('','')">Nuevo mensaje</A></TD>
	        <TD ALIGN="right">
	    		  <TABLE BORDER="0" CELLSPACING="2">
	            <TR>
	              <TD VALIGN="middle">Buscar</TD>
	              <TD VALIGN="middle"><INPUT CLASS="combomini" TYPE="text" NAME="tx_sought" /></TD>
	              <TD VALIGN="middle"><INPUT TYPE="image" SRC="http://www.fundacioncomillasweb.com/dms/comillas3/img/btn_buscador_gnral/btn_buscador_gnral.gif" TITLE="Buscar" /></TD>
	            </TR>
	          </TABLE>
	        </TD>
	      </TR>
	    </TABLE>
	    <TABLE SUMMARY="Radios de filtro" CELLSPACING="4">
	      <TR>
			    <TD><INPUT NAME="bo_toplevel" TYPE="radio" VALUE="true" onclick="showTopLevel(true)" /></TD>
			    <TD VALIGN="middle">&#160;Mostrar s&#243;lo los mensajes de primer nivel</TD><TD VALIGN="middle">&#160;&#160;&#160;</TD><TD VALIGN="middle"><INPUT NAME="bo_toplevel" TYPE="radio" VALUE="false" onclick="showTopLevel(false)" /></TD>
			    <TD VALIGN="middle">&#160;Mostrar los mensajes de primer nivel y las respuestas</TD>
			  </TR>
			</TABLE>
	  </FORM>
	  <TABLE class="mainContents" summary="Messages" width="100%" border="0" cellpadding="3" cellspacing="0">
	    <TR>
	      <TD class="StripHead">Asunto</TD>
        <TD class="StripHead">Remitente</TD>
	      <TD class="StripHead">Fecha</TD>
	      <TD class="StripHead">Respuestas</TD>
      </TR>
	    <xsl:for-each select="Forums/NewsMessages/NewsMessage">
	    <xsl:variable name="MSGNUM" select="position()"/>
	    <TR>
	      <TD class="Strip{$MSGNUM mod 2}"><A href="forum_msg_view.jsp?gu_thread_msg={gu_thread_msg}#{gu_msg}"><xsl:value-of select="tx_subject" disable-output-escaping="no"/></A></TD>
        <TD class="Strip{$MSGNUM mod 2}"><xsl:value-of select="nm_author" disable-output-escaping="no"/></TD>
	      <TD class="Strip{$MSGNUM mod 2}"><xsl:value-of select="dt_published" disable-output-escaping="no"/></TD>
	      <TD class="Strip{$MSGNUM mod 2}"><xsl:if test="string-length(gu_parent_msg)=0"><xsl:value-of select="string(number(nu_thread_msgs)-1)" disable-output-escaping="no"/></xsl:if></TD>
      </TR>
  	  </xsl:for-each>
	  </TABLE>
	  </DIV>
	</TD>

  </TR>
</TABLE>
<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript"><![CDATA[Rounded("div#mainColumnRound","black","white");]]></SCRIPT>

</xsl:template>

</xsl:stylesheet>