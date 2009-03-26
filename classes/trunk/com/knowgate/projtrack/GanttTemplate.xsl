<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="4.0" media-type="text/xml" indent="yes" />
<xsl:template match="/">
<project name="{ProjectSnapshot/Project/nm_project}" company="{ProjectSnapshot/Project/Company/nm_legal}" webLink="{ProjectSnapshot/Project/Company/Addresses/Address/url_addr}" view-date="{ProjectSnapshot/Project/dt_start}" view-index="0" gantt-divider-location="286" resource-divider-location="322" version="2.0">
    <description><xsl:value-of select="ProjectSnapshot/Project/de_project" /></description>
    <view zooming-state="default:6" id="gantt-chart"/>
    <calendars>
        <day-types>
            <day-type id="0"/>
            <day-type id="1"/>
            <calendar id="1" name="default">
                <default-week sun="1" mon="0" tue="0" wed="0" thu="0" fri="0" sat="1"/>
                <overriden-day-types/>
                <days/>
            </calendar>
        </day-types>
    </calendars>
    <tasks color="#99ccff">
        <taskproperties>
            <taskproperty id="tpd0" name="type" type="default" valuetype="icon"/>
            <taskproperty id="tpd1" name="priority" type="default" valuetype="icon"/>
            <taskproperty id="tpd2" name="info" type="default" valuetype="icon"/>
            <taskproperty id="tpd3" name="name" type="default" valuetype="text"/>
            <taskproperty id="tpd4" name="begindate" type="default" valuetype="date"/>
            <taskproperty id="tpd5" name="enddate" type="default" valuetype="date"/>
            <taskproperty id="tpd6" name="duration" type="default" valuetype="int"/>
            <taskproperty id="tpd7" name="completion" type="default" valuetype="int"/>
            <taskproperty id="tpd8" name="coordinator" type="default" valuetype="text"/>
            <taskproperty id="tpd9" name="predecessorsr" type="default" valuetype="text"/>
        </taskproperties>

        <xsl:for-each select="ProjectSnapshot/Project">
          <xsl:call-template name="formatProject"/>    
        </xsl:for-each>        
        
    </tasks>
    
    <resources>
    <xsl:for-each select="ProjectSnapshot/Resources/Resource">    
        <resource id="{pg_resource}" name="{tx_full_name}" function="0" contacts="{tx_email}" phone="{tx_phone}"/>
    </xsl:for-each>        
    </resources>

    <allocations>
    <xsl:for-each select="ProjectSnapshot/Allocations/Allocation">    
        <allocation task-id="{@id_duty}" resource-id="{@pg_resource}" function="0" responsible="false" load="{@load}"/>
    </xsl:for-each>        
    </allocations>

    <vacations/>
    <taskdisplaycolumns>
        <displaycolumn property-id="tpd3" order="0" width="75"/>
        <displaycolumn property-id="tpd4" order="1" width="75"/>
        <displaycolumn property-id="tpd5" order="2" width="75"/>
    </taskdisplaycolumns>
    <previous/>
    <roles roleset-name="Default"/>

</project>
</xsl:template>

<xsl:template name="formatProject">
    <task id="{@id_project}" name="{nm_project}" color="#99ccff" meeting="false" start="{dt_start}" duration="{ti_duration}" complete="100" priority="2" expand="true">

    	<xsl:for-each select="Duties/Duty">
        <xsl:choose>
          <xsl:when test="od_priority='1' or od_priority='2' or od_priority='3'">
				    <task id="{@id_duty}" name="{nm_duty}" color="#99ccff" meeting="false" start="{substring(dt_start,1,10)}" duration="{floor(ti_duration)}" complete="{pct_complete}" priority="2" expand="false">
        	    <notes><xsl:value-of select="de_duty" /></notes>
            </task>
					</xsl:when>
          <xsl:when test="od_priority='5' or od_priority='6'">
				    <task id="{@id_duty}" name="{nm_duty}" color="#99ccff" meeting="false" start="{substring(dt_start,1,10)}" duration="{floor(ti_duration)}" complete="{pct_complete}" priority="0" expand="false">
        	    <notes><xsl:value-of select="de_duty" /></notes>
            </task>
					</xsl:when>
					<xsl:otherwise>
				    <task id="{@id_duty}" name="{nm_duty}" color="#99ccff" meeting="false" start="{substring(dt_start,1,10)}" duration="{floor(ti_duration)}" complete="{pct_complete}" priority="1" expand="false">
        	    <notes><xsl:value-of select="de_duty" /></notes>
            </task>
					</xsl:otherwise>
				</xsl:choose>
    	</xsl:for-each>

      <xsl:for-each select="Subprojects/Project">
      	<xsl:call-template name="formatProject"/>	      
      </xsl:for-each>
    </task>
</xsl:template>

</xsl:stylesheet>