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
	  <TD class="Breadcrumb" align="left">Fundacion Comillas > Comunidades > Foros</TD>
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
	  <FORM NAME="buscaforo" METHOD="get" ACTION="forum_search.jsp" onsubmit="return (document.forms['buscaforo'].tx_sought.value.length!=0)">	  
	    <INPUT TYPE="hidden" NAME="gu_newsgrp" VALUE="{Forums/NewsGroup/gu_newsgrp}" />
	    <TABLE SUMMARY="Caja de Busqueda" WIDTH="100%">
	      <TR>
	        <TD ALIGN="left"><A HREF="forum_list.jsp?gu_newsgrp={Forums/NewsGroup/gu_newsgrp}">Volver</A></TD>
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
	  </FORM>
	  <br/>
	  <TABLE class="mainContents" summary="Messages" width="100%" border="0" cellpadding="3" cellspacing="0">
	    <TR>
	      <TD class="StripHead" width="120">Relevancia</TD>
	      <TD class="StripHead" width="100">Fecha</TD>
        <TD class="StripHead">Asunto</TD>
      </TR>
	    <xsl:variable name="topscore" select="Forums/NewsMessages/@topscore"/>
	    <xsl:for-each select="Forums/NewsMessages/NewsMessageRecord">
	    <xsl:variable name="scoreyes" select="floor(100*number(nu_score) div number($topscore))"/>
	    <xsl:variable name="scoreno" select="100-$scoreyes"/>
	    <xsl:variable name="MSGNUM" select="position()"/>

	    <TR>
			  <TD class="Strip{$MSGNUM mod 2}" width="120">
 			    <IMG vspace="2" src="/images/images/forums/score_tap.gif" width="1" height="8" border="0" alt="" />
 					<IMG vspace="2" src="/images/images/forums/score_yes.gif" width="{$scoreyes}" height="8" border="0" alt="{$scoreyes}" />
 					<IMG vspace="2" src="/images/images/forums/score_no.gif" width="{$scoreno}" height="8" border="0" alt="{$scoreno}" />
 					<IMG vspace="2" src="/images/images/forums/score_tap.gif" width="1" height="8" border="0" alt="" />
		    </TD>
        <TD class="Strip{$MSGNUM mod 2}" width="100"><xsl:value-of select="substring(dt_published,1,10)" disable-output-escaping="no"/></TD>
	      <TD class="Strip{$MSGNUM mod 2}"><A href="forum_msg_view.jsp?gu_msg={gu_msg}"><xsl:value-of select="tx_subject" disable-output-escaping="no"/></A></TD>
      </TR>
	    <TR>
	      <TD class="Strip{$MSGNUM mod 2}" colspan="3"><xsl:value-of select="tx_abstract" disable-output-escaping="no"/></TD>
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