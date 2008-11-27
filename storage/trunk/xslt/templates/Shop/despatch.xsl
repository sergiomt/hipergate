<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			      xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-1.0"
			      xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-1.0"
			      xmlns:cur="urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_logo" />
<xsl:template match="DespatchAdvice">
<HTML xmlns="http://www.w3.org/1999/xhtml">
<HEAD>
  <META http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <TITLE>[~Albarán~] <xsl:value-of select="ID"/></TITLE>
  <STYLE type="text/css">
  <xsl:comment>
    BODY,TH,TD { font-family:verdana,arial,helvetica;font-size:9pt;color:#000; }
  </xsl:comment>
  </STYLE>
</HEAD>
<BODY>
  <TABLE width="740" border="0" cellpadding="6" cellspacing="2" ALIGN="center">
    <TR>
      <TD valign="top" width="90%"><IMG src="{$param_logo}"/>
        <TABLE SUMMARY="SellerParty">
          <TR>
            <TD nowrap="true">
              <B>Emisor</B><BR/>           
              <xsl:value-of select="cac:SellerParty/cac:Party/cac:PartyName/cbc:Name"/><BR/>
              <xsl:value-of select="cac:OrderReference/cac:SellerID"/><xsl:if test="cac:OrderReference/cac:SellerID!=''"><BR/></xsl:if>
              <xsl:if test="cac:SellerParty/cac:Party/cac:Address/cbc:StreetName!=''">
                <xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:AdditionalStreetName"/>&#160;<xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:StreetName"/>&#160;<xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:BuildingNumber"/><BR/>
              </xsl:if>
              <xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:PostalZone"/>&#160;<xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:CountrySubentity"/><BR />
              <xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/Country"/>
              <xsl:if test="cac:SellerParty/cac:AccountsContact/cbc:Telephone!=''">
                <br/>[~Telefono~]&#160;<xsl:value-of select="cac:SellerParty/cac:AccountsContact/cbc:Telephone"/>
              </xsl:if>
              <xsl:if test="cac:PaymentMeans/PayeeFinancialAccount/ID!=''">
                <BR/>
                <xsl:if test="cac:PaymentMeans/PayeeFinancialAccount/FinancialInstitutionBranch!=''"><xsl:value-of select="cac:PaymentMeans/PayeeFinancialAccount/FinancialInstitutionBranch"/>&#160;</xsl:if>
                <xsl:value-of select="cac:PaymentMeans/PayeeFinancialAccount/ID"/>                
              </xsl:if>
            </TD>
          </TR>
        </TABLE>
      </TD>
      <TD>

        <TABLE SUMMARY="BuyerParty">
          <TR>
            <TD nowrap="true">
              <B>[~Cliente~]</B><BR/>           
              <xsl:value-of select="cac:BuyerParty/cac:Party/cac:PartyName/cbc:Name"/><BR/>
              <xsl:if test="cac:BuyerParty/cac:Party/cac:Address/cbc:StreetName!=''">
                <xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/cbc:AdditionalStreetName"/>&#160;<xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/cbc:StreetName"/>&#160;<xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/cbc:BuildingNumber"/><BR/>
              </xsl:if>
              <xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/cbc:PostalZone"/>&#160;<xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/cbc:CountrySubentity"/><BR />
              <xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/Country"/>
              <xsl:if test="cac:BuyerParty/cac:AccountsContact/cbc:Telephone!=''">
                <BR/>Tel.&#160;<xsl:value-of select="cac:BuyerParty/cac:AccountsContact/cbc:Telephone"/>
              </xsl:if>
            </TD>
          </TR>
        </TABLE>
      </TD>
    </TR>
    <TR>
      <TD valign="top">
        <TABLE border="0" cellpadding="2" cellspacing="2">
          <TR>
            <TD><B>[~Nº de Albarán~]</B>&#160;</TD><TD><xsl:value-of select="ID"/></TD>
            <TD></TD>
          </TR>
          <TR>
            <TD><B>[~Fecha de Emisión~]&#160;</B></TD><TD><xsl:value-of select="cbc:IssueDate"/></TD>
          </TR>
        </TABLE>
      </TD>
      <TD valign="top">
        <TABLE>
          <TR>
            <TD nowrap="true">
              <B>[~Dirección del envío~]</B><BR/>
              <xsl:value-of select="cac:BuyerParty/cac:Party/cac:PartyName/cbc:Name"/><BR/>
              <xsl:value-of select="cac:Delivery/cac:DeliveryAddress/cbc:AdditionalStreetName"/>&#160;<xsl:value-of select="cac:Delivery/cac:DeliveryAddress/cbc:StreetName"/>&#160;<xsl:value-of select="cac:Delivery/cac:DeliveryAddress/cbc:BuildingNumber"/><BR/>
              <xsl:value-of select="cac:Delivery/cac:DeliveryAddress/cbc:PostalZone"/>&#160;<xsl:value-of select="cac:Delivery/cac:DeliveryAddress/CityName"/>
            </TD>
          </TR>
        </TABLE>
      </TD>
    </TR>
  </TABLE>

  <TABLE width="740" border="1" cellpadding="4" cellspacing="0" ALIGN="center">

    <TR>
      <TH>[~Concepto~]</TH>
      <TH>[~Cantidad~]</TH>
      <TH>[~Precio~]</TH>
      <TH>[~IVA~]</TH>
      <TH>[~Total con IVA~]</TH>
    </TR>

    <xsl:for-each select="cac:DespatchLine">
    <TR>
      <TD width="70%"><xsl:value-of select="cac:Item/cbc:Description"/></TD>
      <TD align="center"><xsl:value-of select="cbc:DeliveredQuantity"/></TD>
      <TD NOWRAP="nowrap"><xsl:value-of select="BasePrice"/> &#8364;</TD>
      <TD NOWRAP="nowrap"><xsl:value-of select="number(translate(cac:Item/TaxCategory/Percent,',','.'))*100"/>%</TD>
      <TD NOWRAP="nowrap"><xsl:value-of select="cbc:LineExtensionAmount"/> &#8364;</TD>
    </TR>
    </xsl:for-each>
    <TR>
      <TD colspan="2"></TD>
      <TD align="right"><B>[~Total~]</B></TD>
      <TD NOWRAP="nowrap"><xsl:value-of select="cac:TaxTotal/cbc:TotalTaxAmount"/> &#8364;</TD>
      <TD NOWRAP="nowrap"><xsl:value-of select="cac:LegalTotal/cbc:TaxInclusiveTotalAmount"/> &#8364;</TD>
    </TR>
    
  </TABLE>

</BODY>
</HTML>
</xsl:template>
</xsl:stylesheet>