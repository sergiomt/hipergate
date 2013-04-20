<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>

<xsl:param name="param_domain" />
<xsl:param name="param_workarea" />
<xsl:param name="param_skin" />

<xsl:template match="/">

  <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0" />
    <TR>  
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleftcorner.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0" /></TD>
      <TD BACKGROUND="../images/images/graylinebottom.gif">
        <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
          <TR>
            <TD COLSPAN="2" CLASS="subtitle" BACKGROUND="../images/images/graylinetop.gif"><IMG SRC="../images/images/spacer.gif" HEIGHT="2" BORDER="0" /></TD>
	        <TD ROWSPAN="2" CLASS="subtitle" ALIGN="right"><IMG SRC="../skins/{$param_skin}/tab/angle45_24x24.gif" style="display:block" WIDTH="24" HEIGHT="24" BORDER="0" /></TD>
	      </TR>
          <TR>
      	    <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" WIDTH="4" BORDER="0" /></TD>
      	    <TD BACKGROUND="../skins/{$param_skin}/tab/tabback.gif" CLASS="subtitle" ALIGN="left" VALIGN="middle">
      	      <IMG SRC="../images/images/3x3puntos.gif" BORDER="0" />Hello World!
      	    </TD>
          </TR>
        </TABLE>
      </TD>
      <TD VALIGN="bottom" ALIGN="right" WIDTH="3px" CLASS="htmlbody"><IMG SRC="../images/images/graylinerightcornertop.gif" WIDTH="3" BORDER="0" /></TD>
    </TR>
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0" /></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0" /></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0" /></TD>
    </TR>
    <TR>
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG SRC="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0" /></TD>
      <TD CLASS="menu1">
        <TABLE SUMMARY="" CELLSPACING="8" BORDER="0" />
          <TR>
            <TD ALIGN="middle">
              <IMG SRC="../images/images/chequeredflag.gif" BORDER="0" ALT="Chequered Falg">
            </TD>
            <TD ALIGN="left" VALIGN="middle">
              <TABLE>
                <TR>
                  <TD><IMG SRC="../images/images/new16x16.gif" BORDER="0" /></TD>
                  <TD VALIGN="middle"><A HREF="#" onclick="window.open('#',null,'directories=no,toolbar=no,menubar=no,width=500,height=400')" CLASS="linkplain">New Item</A></TD>
                </TR>
              </TABLE>
	          </TD>
	        </TR>
	        <TR>
	          <TD COLSPAN="2">

		        <!-- *** Content HERE *** -->

									HELLO WORLD!
									
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2">

						<!-- *** Content HERE *** -->
						
						<xsl:value-of select="FullName"/>

            </TD>
          </TR>          
        </TABLE>
      </TD>
      <TD WIDTH="3px" ALIGN="right" BACKGROUND="../images/images/graylineright.gif"><IMG src="../images/images/spacer.gif" WIDTH="3" BORDER="0" /></TD>
    </TR>
    <TR> 
      <TD WIDTH="2px" CLASS="subtitle" BACKGROUND="../images/images/graylineleft.gif"><IMG src="../images/images/spacer.gif" WIDTH="2" HEIGHT="1" BORDER="0" /></TD>
      <TD CLASS="subtitle"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" BORDER="0" /></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylineright.gif" WIDTH="3" HEIGHT="1" BORDER="0" /></TD>
    </TR>
    <TR>
      <TD WIDTH="2px" CLASS="subtitle"><IMG SRC="../images/images/graylineleftcornerbottom.gif" WIDTH="2" HEIGHT="3" BORDER="0" /></TD>
      <TD CLASS="htmlbody" BACKGROUND="../images/images/graylinefloor.gif"></TD>
      <TD WIDTH="3px" ALIGN="right"><IMG SRC="../images/images/graylinerightcornerbottom.gif" WIDTH="3" HEIGHT="3" BORDER="0" /></TD>
    </TR>
  </TABLE>
</xsl:template>
</xsl:stylesheet>