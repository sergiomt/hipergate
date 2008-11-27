<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template name="portlet">
<xsl:text disable-output-escaping="yes"><![CDATA[
<%@ page import="java.io.File,javax.servlet.jsp.JspWriter,javax.portlet.GenericPortlet,javax.portlet.PortletException,javax.portlet.RenderRequest,javax.portlet.RenderResponse,com.knowgate.jdc.*,com.knowgate.misc.Gadgets,com.knowgate.dataxslt.db.*,com.knowgate.http.portlets.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../../../../../../methods/dbbind.jsp" %>
<%@ include file="../../../../../../methods/portletcontext.jspf" %>
<%
  String sPageSetGUID = "]]></xsl:text><xsl:value-of select="$param_pageset"/><xsl:text disable-output-escaping="yes"><![CDATA[";
  String sStoragePath = "]]></xsl:text><xsl:value-of select="$param_storage"/><xsl:text disable-output-escaping="yes"><![CDATA[";
  String sCatalogGUID = "]]></xsl:text><xsl:value-of select="pageset/catalog"/><xsl:text disable-output-escaping="yes"><![CDATA[";
  String sColor = "]]></xsl:text><xsl:value-of select="pageset/color"/><xsl:text disable-output-escaping="yes"><![CDATA[";
   
  JDCConnection oConn = GlobalDBBind.getConnection("xsl_template");
         
  PageSetDB oPageSet = new PageSetDB (oConn, sPageSetGUID);
	 
  MicrositeDB oMicroSite = new MicrositeDB(oConn, oPageSet.getString("gu_microsite"));
	          
  oConn.close("xsl_template");
         
  String sTemplatesPath = Gadgets.chomp(sStoragePath, File.separator) + "xslt" + File.separator + "templates" + File.separator + oMicroSite.getString("nm_microsite") + File.separator;

  portletRequest.setAttribute ("catalog" , sCatalogGUID);

  portletRequest.setProperty  ("color", sColor);
%>
<%!
  public static void RenderPortlet (String sPortletClass, javax.servlet.jsp.JspWriter oOut,
  				    com.knowgate.http.portlets.HipergatePortletConfig oConfig,
  				    javax.portlet.RenderRequest oReq, javax.portlet.RenderResponse oRes)
    throws java.io.IOException {
    
    Class oPortletClass = null;
    
    try {
      oPortletClass = Class.forName("com.knowgate.http.portlets." + sPortletClass);
    }
    catch (java.lang.ClassNotFoundException xcpt) {
      oOut.write ("<B>PortletException " + xcpt.getMessage() + "</B>");
    }

    if (null!=oPortletClass) {
      GenericPortlet oPortlet = null;

      try {
        oPortlet = (javax.portlet.GenericPortlet) oPortletClass.newInstance();
      }
      catch (java.lang.InstantiationException xcpt) {
        oOut.write ("<B>InstantiationException " + xcpt.getMessage() + "</B>");
      }
      catch (java.lang.IllegalAccessException xcpt) {
        oOut.write ("<B>IllegalAccessException " + xcpt.getMessage() + "</B>");
      }
    
      if (null!=oPortlet) {
	 
        try {
          oPortlet.init (oConfig);
          oOut.flush();
          oPortlet.render(oReq, oRes);
        }
        catch (javax.portlet.PortletException xcpt) {
          oOut.write ("<B>PortletException " + xcpt.getMessage() + "</B>");
        }
        catch (java.io.IOException xcpt) {
          oOut.write ("<B>IOException " + xcpt.getMessage() + "</B>");
        }
      }
    }    
  } // RenderPortlet
%>
]]></xsl:text>
</xsl:template>
</xsl:stylesheet>