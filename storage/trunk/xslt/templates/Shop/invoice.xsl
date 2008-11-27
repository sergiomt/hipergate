<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			      xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-1.0"
			      xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-1.0"
			      xmlns:cur="urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0">
<xsl:output method="html" version="4.0" media-type="text/html" omit-xml-declaration="yes"/>
<xsl:param name="param_logo" />
<xsl:template match="Invoice">
<HTML xmlns="http://www.w3.org/1999/xhtml">
<HEAD>
  <META http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <TITLE>[~Factura~] <xsl:value-of select="ID"/></TITLE>
  <STYLE type="text/css">
  <xsl:comment>
    BODY,TH,TD { font-family:verdana,arial,helvetica;font-size:9pt;color:#000; }
  </xsl:comment>
  </STYLE>
</HEAD>
<BODY>
  <TABLE width="740" border="0" cellpadding="6" cellspacing="2" ALIGN="center">
    <TR>
      <TD valign="top" width="90%"><IMG src="{$param_logo}"/></TD>
      <TD>
        <TABLE>
          <TR>
            <TD nowrap="true">
              <xsl:value-of select="cac:SellerParty/cac:Party/cac:PartyName/cbc:Name"/><BR/>
              <xsl:value-of select="cac:OrderReference/cac:SellerID"/><xsl:if test="cac:OrderReference/cac:SellerID!=''"><BR/></xsl:if>
              <xsl:if test="cac:SellerParty/cac:Party/cac:Address/cbc:StreetName!=''">
                <xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:AdditionalStreetName"/>&#160;<xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:StreetName"/>&#160;<xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:BuildingNumber"/><BR/>
              </xsl:if>
              <xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:PostalZone"/>&#160;<xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/cbc:CountrySubentity"/><BR />
              <xsl:value-of select="cac:SellerParty/cac:Party/cac:Address/Country"/>
              <xsl:if test="cac:SellerParty/cac:AccountsContact/cbc:Telephone!=''">
                <BR/>Tel.&#160;<xsl:value-of select="cac:SellerParty/cac:AccountsContact/cbc:Telephone"/>
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
    </TR>
    <TR>
      <TD valign="top">
        <TABLE border="0" cellpadding="2" cellspacing="2">
          <TR>
            <TD><B>Nº de Factura:</B></TD><TD><xsl:value-of select="ID"/></TD>
            <TD></TD>
          </TR>
          <TR>
            <TD><B>Fecha de Emisión:</B></TD><TD><xsl:value-of select="cbc:IssueDate"/></TD>
          </TR>
          <TR>
            <TD><B>Fecha de Vencimiento:</B></TD><TD><xsl:value-of select="cac:PaymentMeans/cbc:DuePaymentDate"/></TD>
          </TR>
        </TABLE>
      </TD>
      <TD valign="top">
        <TABLE>
          <TR>
            <TD nowrap="true">
              <B>Datos del cliente</B><BR/>
              <xsl:value-of select="cac:BuyerParty/cac:Party/cac:PartyName/cbc:Name"/><BR/>
              <xsl:if test="cac:OrderReference/cac:BuyersID!=''"><xsl:value-of select="cac:OrderReference/cac:BuyersID"/><BR/></xsl:if>
              <xsl:if test="cac:BuyerParty/cac:Party/cac:Address/cbc:StreetName!=''">
                <xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/cbc:AdditionalStreetName"/>&#160;<xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/cbc:StreetName"/>&#160;<xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/cbc:BuildingNumber"/><BR/>
              </xsl:if>
              <xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/cbc:PostalZone"/> <xsl:value-of select="cac:BuyerParty/cac:Party/cac:Address/Country"/>
              <xsl:if test="cac:PaymentMeans/PayerFinancialAccount/ID!=''">
                <BR/>
                <xsl:if test="cac:PaymentMeans/PayerFinancialAccount/FinancialInstitutionBranch!=''"><xsl:value-of select="cac:PaymentMeans/PayerFinancialAccount/FinancialInstitutionBranch"/>&#160;</xsl:if>
                <xsl:value-of select="cac:PaymentMeans/PayerFinancialAccount/ID"/>                
              </xsl:if>
            </TD>
          </TR>
        </TABLE>
      </TD>
    </TR>
  </TABLE>

  <xsl:variable name="currency">
    <xsl:choose>
      <xsl:when test="InvoiceCurrencyCode='978'"><xsl:value-of select="'€'"/></xsl:when>
      <xsl:when test="InvoiceCurrencyCode='840' or InvoiceCurrencyCode='124' or InvoiceCurrencyCode='344'"><xsl:value-of select="'$'"/></xsl:when>
      <xsl:when test="InvoiceCurrencyCode='826' or InvoiceCurrencyCode='818' or InvoiceCurrencyCode='372' or InvoiceCurrencyCode='292'"><xsl:value-of select="'£'"/></xsl:when>
      <xsl:when test="InvoiceCurrencyCode='533' or InvoiceCurrencyCode='348' or InvoiceCurrencyCode='344'"><xsl:value-of select="'ƒ'"/></xsl:when>
      <xsl:when test="InvoiceCurrencyCode='392'"><xsl:value-of select="'¥'"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="'¤'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <TABLE width="740" border="1" cellpadding="4" cellspacing="0" ALIGN="center">

    <TR>
      <TH>Concepto</TH>
      <TH>Precio</TH>
      <TH>Cantidad</TH>
      <TH>Importe</TH>
    </TR>

    <xsl:for-each select="cac:InvoiceLine">
    <TR>
      <TD width="90%"><xsl:value-of select="cac:Item/cbc:Description"/></TD>
      <TD><xsl:value-of select="BasePrice"/>&#160;<xsl:value-of select="$currency"/></TD>
      <TD align="center"><xsl:value-of select="cbc:InvoicedQuantity"/></TD>
      <TD align="right"><xsl:value-of select="cbc:LineExtensionAmount"/>&#160;<xsl:value-of select="$currency"/></TD>
    </TR>
    </xsl:for-each>

    <TR>
      <TD></TD>
      <TD colspan="2" align="right"><B>Subtotal</B></TD>
      <TD align="right"><xsl:value-of select="cac:LegalTotal/cbc:LineExtensionTotalAmount"/>&#160;<xsl:value-of select="$currency"/></TD>
    </TR>

    <TR>
      <TD></TD>
      <TD colspan="2" align="right"><B>IVA 16%</B></TD>
      <TD align="right"><xsl:value-of select="cac:TaxTotal/cbc:TotalTaxAmount"/>&#160;<xsl:value-of select="$currency"/></TD>
    </TR>

    <TR>
      <TD></TD>
      <TD colspan="2" align="right"><B>TOTAL</B></TD>
      <TD align="right"><B><xsl:value-of select="cac:LegalTotal/cbc:TaxInclusiveTotalAmount"/>&#160;<xsl:value-of select="$currency"/></B></TD>
    </TR>
    
  </TABLE>

</BODY>
</HTML>
</xsl:template>
</xsl:stylesheet>