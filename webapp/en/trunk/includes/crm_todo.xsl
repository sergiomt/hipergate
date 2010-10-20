<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_workarea" />

<xsl:template match="/">
  <TABLE SUMMARY="To Do List for Today" CELLSPACING="4" CELLPADDING="0" BORDER="0">
    <TR>
      <TD COLSPAN="3">
        <A HREF="#" onclick="window.open('../addrbook/todo_edit.jsp?gu_workarea={$param_workarea}',null,'directories=no,toolbar=no,menubar=no,width=500,height=400')" CLASS="linkplain">New Task</A>
			</TD>
	  </TR>
	  <xsl:for-each select="calendar/todo/activity">
    <TR>
      <TD CLASS="formplain"><xsl:value-of select="od_priority"/></TD>
      <TD><A CLASS="linkplain" HREF="#" onclick="window.open('../addrbook/todo_edit.jsp?gu_workarea={$param_workarea}&amp;gu_to_do={gu_to_do}',null,'directories=no,toolbar=no,menubar=no,width=500,height=400')"><xsl:value-of select="tl_to_do"/></A></TD>
    	<TD><A HREF="#" onclick="window.open('../addrbook/todo_finish.jsp?gu_workarea={$param_workarea}&amp;gu_to_do={gu_to_do}',null,'directories=no,toolbar=no,menubar=no,width=500,height=400')" TITLE="End Task"><IMG SRC="../images/images/checkmark16.gif" WIDTH="16" HEIGHT="16" BORDER="0"/></A></TD>
    </TR>
	  </xsl:for-each>
    <TR>
      <TD COLSPAN="3">
        <A CLASS="linkplain" HREF="../addrbook/to_do_listing.jsp" TARGET="_top">more...</A>
		  </TD>
	  </TR>
  </TABLE>
</xsl:template>
</xsl:stylesheet>