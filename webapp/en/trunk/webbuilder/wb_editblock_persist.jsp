<%@ page import="org.w3c.dom.*,com.knowgate.misc.*,java.io.File,java.lang.*,java.util.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.dataxslt.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.db.*,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);  
  String id_domain = getCookie(request,"domainid","");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = request.getParameter("gu_pageset");
  String gu_page = request.getParameter("gu_page");
  String sPage = request.getParameter("page");
  String sDocType = request.getParameter("doctype");
  String sFileTemplate = request.getParameter("file_template");
  String sFilePageSet = request.getParameter("file_pageset");
  String sBlockId = request.getParameter("id_block");
  String id_metablock = nullif(request.getParameter("id_metablock"),"");
  String nm_metablock = nullif(request.getParameter("nm_metablock"),"");
  String sBlockXML = new String("\t<block id=\"" + sBlockId + "\">\n\t  <metablock>" + id_metablock + "</metablock>\n\t  <tag>" + nm_metablock + "</tag>\n\t  <paragraphs>\n\t    <paragraph id=\"REMOVABLE\"></paragraph>\n\t  </paragraphs>\n\t  <images>\n\t    <image id=\"REMOVABLE\"></image>\n\t  </images>\n\t  <zone/>\n\t</block>");

  Microsite oMicrosite = MicrositeFactory.getInstance(sFileTemplate);
  PageSet oPageSet = new PageSet(sFileTemplate,sFilePageSet);
  MetaBlock oMetablock = oMicrosite.container(oPageSet.page(gu_page).container()).metablock(id_metablock);
  boolean bAllowHTML = oMetablock.allowHTML();
  
  XMLDocument oXMLDocument = new XMLDocument(sFilePageSet);
  oXMLDocument.removeNode("pageset/pages/page[@guid=\"" + gu_page + "\"]/blocks/block[@id=\"" + sBlockId + "\"]");
  oXMLDocument.addNode("pageset/pages/page[@guid=\"" + gu_page + "\"]/blocks/block",sBlockXML);
  int removeParagraph = 0;  
  int removeImage = 0;
%>
<%
  Enumeration oParameterNames = request.getParameterNames();
  SortedMap oMap = new TreeMap();
  
  while (oParameterNames.hasMoreElements())
  {
   String sKey = oParameterNames.nextElement().toString();
   String sValue = request.getParameter(sKey).trim();
   try { 
     String sAux = Gadgets.split(sKey, '.')[2];
     oMap.put(sKey,sValue);  
   } catch (Exception e) {}
  }
  
  String sLastClassName = "";
  String sLastObjectId = "";
  String sLastField = "";
  
  // Variables temporales para almacenar datos de items
  
  String sCurrentItemId = "";
  String sCurrentItemText = "";
  String sCurrentItemURL = "";
  String sCurrentItemWidth = "";
  String sCurrentItemHeight = "";
  String sCurrentItemAlt = "";
  String sCurrentItemPath = "";
  int iCurrentItemURLLen = 0;

  Set oSet = oMap.entrySet();
  Iterator iSet = oSet.iterator();
  
  while (iSet.hasNext())
  {
    String sKeyValue = iSet.next().toString();
    
    if (DebugFile.trace) DebugFile.writeln("<JSP:wb_editblock_persist Processing value "+sKeyValue);
    
    sKeyValue += "\0";

    String aKeyValue[] = Gadgets.split2(sKeyValue,'=');
    String sKey = aKeyValue[0];
    String sValue = aKeyValue[1];
   
    String sClassName = new String();
    String sObjectId = new String();
    String sField = new String();

    if (DebugFile.trace) DebugFile.writeln("<JSP:wb_editblock_persist key is "+sKey);
    
    String aItems[] = Gadgets.split(sKey,'.');
    sClassName = aItems[0];
    sObjectId = aItems[1];
    sField = aItems[2];
    
    if (sClassName.indexOf("Paragraph")!=-1)
     {
      if (!((sLastClassName==sClassName) && (sLastObjectId==sObjectId)))
       if (sField.indexOf("id")!=-1)
       {
        sCurrentItemId = sValue.trim();
       }
      if (sField.indexOf("text")!=-1)
      {
       sCurrentItemText = sValue.trim();
       if (bAllowHTML) sCurrentItemText = Gadgets.XHTMLEncode(sCurrentItemText);
      }
      if (sField.indexOf("url")!=-1)
      {
       sCurrentItemURL = sValue.trim();
       if ((!(sCurrentItemURL.startsWith("javascript:"))))
       {
        sCurrentItemURL = "";
        // Replace & by &amp;
        iCurrentItemURLLen = sValue.length();
        for (int a=0; a<iCurrentItemURLLen; a++) {
          if (sValue.charAt(a)=='&') {
            if (a>iCurrentItemURLLen-5) {
              sCurrentItemURL += "&amp;";
            } else {
              if (sValue.substring(a,a+5).equals("&amp;")) {
                sCurrentItemURL += sValue.charAt(a);
              } else {
                sCurrentItemURL += "&amp;";            	
              }               
            }
          } else {
            sCurrentItemURL += sValue.charAt(a);
          }
        } // next
        sCurrentItemURL = sCurrentItemURL.trim();
        if (!((sCurrentItemURL.startsWith("http://")) || (sCurrentItemURL.startsWith("https://")))&& sCurrentItemURL.length()>0)
        sCurrentItemURL = "http://" + sCurrentItemURL;
       } else {
       	 sCurrentItemURL = sValue.trim();
       }

        // Ultimo field, modificar XMLDocument y grabar
				if (sCurrentItemText.length()>0 || sCurrentItemURL.length()>0)
        {
          oXMLDocument.addNode("pageset/pages/page[@guid=\"" + gu_page + "\"]/blocks/block[@id=\"" + sBlockId + "\"]/paragraphs/paragraph[@id=\"REMOVABLE\"]",
                               "<paragraph id=\"" + sCurrentItemId + "\">\n\t    <url>" + sCurrentItemURL + "</url>\n\t    <text><![CDATA[" + sCurrentItemText + "]]></text>\n\t</paragraph>");
        }
      }
     } // if "Paragraph"
    
    if (sClassName.indexOf("Image")!=-1)
     {
      if (!((sLastClassName==sClassName) && (sLastObjectId==sObjectId)))
       if ((sField.indexOf("id")!=-1)&&(sField.indexOf("width")==-1))
       {
        sCurrentItemId = sValue.trim();
       }
      if (sField.indexOf("path")!=-1)
      {
       sCurrentItemPath = sValue.trim();
      }
      if (sField.indexOf("alt")!=-1)
      {
       sCurrentItemAlt = sValue.trim();
      }
      if (sField.indexOf("height")!=-1)
      {
       sCurrentItemHeight = sValue.trim();
      }
      if (sField.indexOf("url")!=-1)
      {
       sCurrentItemURL = sValue.trim();
       if ((!(sCurrentItemURL.startsWith("javascript:"))))
       {
        sCurrentItemURL = "";
        // Replace & by &amp;
        iCurrentItemURLLen = sValue.length();
        for (int a=0; a<iCurrentItemURLLen; a++) {
          if (sValue.charAt(a)=='&') {
            if (a>iCurrentItemURLLen-5) {
              sCurrentItemURL += "&amp;";
            } else {
              if (sValue.substring(a,a+5).equals("&amp;")) {
                sCurrentItemURL += sValue.charAt(a);
              } else {
                sCurrentItemURL += "&amp;";            	
              }               
            }
          } else {
            sCurrentItemURL += sValue.charAt(a);
          }
        } // next
        sCurrentItemURL = sCurrentItemURL.trim();
        if (!((sCurrentItemURL.startsWith("http://")) || (sCurrentItemURL.startsWith("https://")))&& sCurrentItemURL.length()>0)
        sCurrentItemURL = "http://" + sCurrentItemURL;
       } else {
       	 sCurrentItemURL = sValue.trim();
       }
      }
       if (sField.indexOf("width")!=-1)
      {
       sCurrentItemWidth = sValue.trim();
       
       // Ultimo field, modificar XMLDocument y grabar
        if (!sCurrentItemPath.equals(""))
	        oXMLDocument.addNode("pageset/pages/page[@guid='" + gu_page + "']/blocks/block[@id='" + sBlockId + "']/images/image[@id='REMOVABLE']","<image id=\"" + sCurrentItemId + "\">\n\t    <path>" + sCurrentItemPath + "</path>\n\t    <url>" + sCurrentItemURL + "</url>\n\t    <alt><![CDATA[" + sCurrentItemAlt + "]]></alt>\n\t    <width>" + sCurrentItemWidth + "</width>\n\t    <height>" + sCurrentItemHeight + "</height>\n\t</image>");
      }
     } // if "Image"

   // Ultimos items recuperados
   sLastClassName = new String(sClassName);
   sLastObjectId = new String(sObjectId);
   sLastField = new String(sField);

  } // while
 
 oXMLDocument.save();
%>
<html>
<head> 
  <TITLE>Wait...</TITLE>
  <script language="JavaScript" type="text/javascript">
  <!--
    document.location = "wb_document.jsp?id_domain=<%=id_domain%>&doctype=<%=sDocType%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=gu_pageset%>&page=<%=sPage%>";    
  //-->
  </script>
</head>
</html>
<%@ include file="../methods/page_epilog.jspf" %>