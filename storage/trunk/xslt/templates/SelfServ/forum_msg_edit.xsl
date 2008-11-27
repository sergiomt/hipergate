<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>

<xsl:param name="param_domain" />
<xsl:param name="param_workarea" />
<xsl:param name="param_newsgroup" />
<xsl:param name="param_groupname" />
<xsl:param name="param_parent" />
<xsl:param name="param_thread" />
<xsl:param name="param_language" />
<xsl:param name="param_user" />
<xsl:param name="param_subject" />

<xsl:template match="/">

  <FORM METHOD="post" ACTION="forum_msg_store.jsp" onSubmit="return validate()">
    <BR />
    <CENTER>
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="{$param_domain}" />
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="{$param_workarea}" />

    <INPUT TYPE="hidden" NAME="gu_newsgrp" VALUE="{$param_newsgroup}" />
    <INPUT TYPE="hidden" NAME="gu_parent_msg" VALUE="{$param_parent}" />
    <INPUT TYPE="hidden" NAME="gu_thread_msg" VALUE="{$param_thread}" />
    <INPUT TYPE="hidden" NAME="id_language" VALUE="{$param_language}" />
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="{$param_user}" />
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="{$param_user}" />

    <TABLE>

      <TR><TD>
        <TABLE WIDTH="100%">
					<TR>
					  <TD COLSPAN="2" CLASS="striptitle">
					    <FONT CLASS="title1">Redactar Mensaje</FONT>
					  </TD>
					</TR>
          <TR>
            <TD ALIGN="left" WIDTH="110px">Foro:</TD>
            <TD ALIGN="left" CLASS="textplain"><xsl:value-of select="$param_groupname" disable-output-escaping="no"/></TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="110px">De:</TD>
            <TD ALIGN="left" CLASS="textplain"><INPUT TYPE="text" NAME="nm_author" MAXLENGTH="100" SIZE="80" VALUE="anónimo" onFocus="if (this.value=='anónimo') this.value='';" /></TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="110px">e-mail:</TD>
            <TD ALIGN="left" CLASS="textplain"><INPUT TYPE="text" NAME="tx_email" MAXLENGTH="100" SIZE="80" VALUE="" STYLE="text-transform:lowercase" /></TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="110px">Asunto:</TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="tx_subject" MAXLENGTH="254" SIZE="80" VALUE="{$param_subject}" />
            </TD>
          </TR>
        </TABLE>

        <TABLE>
          <TR>
	          <TD COLSPAN="2" ALIGN="left"><TEXTAREA CLASS="textcode" NAME="tx_msg" ID="tx_msg" ROWS="17" COLS="80"></TEXTAREA></TD>
          </TR>                    
          <TR>
            <TD COLSPAN="2"><HR /></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Enviar" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s"  />&#160;
    	      &#160;&#160;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancelar" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()" />
    	      <BR /><BR />
    	    </TD>
    	    </TR>   
        </TABLE>
      </TD></TR>
    </TABLE>
    </CENTER>
  </FORM>
</xsl:template>

</xsl:stylesheet>
