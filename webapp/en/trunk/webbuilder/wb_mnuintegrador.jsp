<%@ page import="java.lang.StringBuffer,java.util.Vector,com.knowgate.misc.*,java.io.File,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.debug.DebugFile,com.knowgate.misc.*,com.knowgate.dataxslt.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.db.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%!

  static String esc (String sPath) {
    String sRetVal;

    if (System.getProperty("file.separator").equals("/"))
      sRetVal = sPath;
    else {
      sRetVal = "";
      for (int p=0; p<sPath.length(); p++)
        if (sPath.charAt(p)=='\\')
          sRetVal += "\\\\";
        else
          sRetVal += sPath.charAt(p);
    }
        
    return sRetVal;
  }
%><%
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

  final String sSep = System.getProperty("file.separator");
 
  if (DebugFile.trace) DebugFile.writeln("<JSP:wb_mnuintegrador.jsp?id_domain=" + request.getParameter("id_domain") + "&gu_workarea=" + request.getParameter("gu_workarea") + "&gu_pageset=" + request.getParameter("gu_pageset") + "&doctype=" + request.getParameter("doctype") + "&page=" + request.getParameter("page"));
    
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
   
  // Rutas y parametros
  String gu_microsite;
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = request.getParameter("gu_pageset");
  
  String sDefURLRoot = request.getRequestURI();
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));

  String sURLRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver", sDefURLRoot);
  
  if (sURLRoot.endsWith("/") && sURLRoot.length()>0) sURLRoot = sURLRoot.substring(0, sURLRoot.length()-1);
  
  String sDefImgSrv = request.getRequestURI();
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv + "/images";
  
  String sImagesRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(), "imageserver", sDefImgSrv);
  String sStorageRoot = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  String sDocType = request.getParameter("doctype");
  String sPage = request.getParameter("page");
  String sURLEditBlock = "";
  
  // Instanciacion de clases y acceso a base de datos
  
  JDCConnection oConn = GlobalDBBind.getConnection("wb_mnuintegrador");
  PageSetDB oPageSetDB = new PageSetDB(oConn, gu_pageset);
  
  String sFilePageSet = sStorageRoot + (sSep.equals("/") ? oPageSetDB.getStringNull(DB.path_data,"") : oPageSetDB.getStringNull(DB.path_data,"").replace('/','\\'));
  String sFileTemplate = sStorageRoot + (sSep.equals("/") ? oPageSetDB.getStringNull(DB.path_metadata,"") : oPageSetDB.getStringNull(DB.path_metadata,"").replace('/','\\'));
  
  gu_microsite = oPageSetDB.getStringNull(DB.gu_microsite,"");
  
  oPageSetDB = null;
  
  oConn.close("wb_mnuintegrador");
  oConn = null;
  
  if (DebugFile.trace) DebugFile.writeln("<JSP:wb_mnuintegrador.jsp new PageSet(" + sFileTemplate + "," + sFilePageSet + "true)");
  
  PageSet oPageSet = new PageSet(sFileTemplate, sFilePageSet, true);
  
  Page oPage = null;
  
  java.util.Vector vPages = oPageSet.pages();

  if (sPage.length()==0) 
    oPage = (Page) vPages.firstElement();
  else
    for (int numPage=0; numPage<vPages.size(); numPage++)
    {
     oPage = (Page) vPages.elementAt(numPage);
     if (oPage.getTitle().equals(sPage)) break;
    }
  
  String sPageSetTitle = oPage.getTitle();
  if (sPageSetTitle.length()>40) sPageSetTitle = "<B>" + sPageSetTitle.substring(0,39) + "..." + "</B>";
  
  // Código del integrador  
  StringBuffer integraOut = new StringBuffer(16384);
  
  integraOut.append("<form name=\"frmLstBlocks\">");

  integraOut.append("<input type=\"hidden\" name=\"gu_workarea\" value=\"" + gu_workarea + "\">");
  integraOut.append("<input type=\"hidden\" name=\"gu_pageset\" value=\"" + gu_pageset + "\">");
  integraOut.append("<input type=\"hidden\" name=\"gu_page\" value=\"" + oPage.guid() + "\">");
  integraOut.append("<input type=\"hidden\" name=\"doctype\" value=\"" + sDocType + "\">");
  integraOut.append("<input type=\"hidden\" name=\"page_title\" value=\"" + sPage + "\">");
  integraOut.append("<input type=\"hidden\" name=\"gu_microsite\" value=\"" + gu_microsite + "\">");
  integraOut.append("<input type=\"hidden\" name=\"file_pageset\" value=\"" + esc(sFilePageSet) + "\">");
  integraOut.append("<input type=\"hidden\" name=\"id_domain\" value=\"" + id_domain + "\">");  
  integraOut.append("<input type=\"hidden\" name=\"file_template\" value=\"" + esc(sFileTemplate) + "\">");

  integraOut.append("<font face=\"Arial\" size=\"2\" color=\"#ffffff\"><b>" + sPageSetTitle + "</b></font>");

  integraOut.append("<table width=\"100%\" cellspacing=\"0\" cellpadding=\"0\">");
  integraOut.append("<tr><td colspan=\"3\" background=\"" + sImagesRoot + "/images/spacer.gif\" height=\"3\"></td></tr>");  
  integraOut.append("<tr valign=\"middle\">");
  integraOut.append("<td>&nbsp;<img src=\"" + sImagesRoot + "/images/integrador/addblock16x16.gif\" width=\"16\" height=\"16\" border=\"0\" alt=\"New Block\">");
  integraOut.append("&nbsp;<a href=\"javascript:addNewBlock();\" style=\"font-family:arial; font-size:10px; color:#ffffff\">New</a></td>");
  integraOut.append("<td>&nbsp;<img src=\"" + sImagesRoot + "/images/integrador/delblock16x16.gif\" width=\"16\" height=\"16\" border=\"0\" alt=\"Remove selected blocks\">");
  integraOut.append("&nbsp;<a href=\"javascript:deleteCheckedBlocks();\" style=\"font-family:arial; font-size:10px; color:#ffffff\">Delete</a></td>");
  integraOut.append("<td>&nbsp;<img src=\"" + sImagesRoot + "/images/integrador/palete16x16.gif\" width=\"16\" height=\"16\" border=\"0\" alt=\"Change style\">");
  integraOut.append("&nbsp;<a href=\"javascript:changeStyles();\" style=\"font-family:arial; font-size:10px; color:#ffffff\">Style</a></td>");
  integraOut.append("</tr>");
  integraOut.append("<tr><td colspan=\"3\" background=\"" + sImagesRoot + "/images/spacer.gif\" height=\"3\"></td></tr>");  
  integraOut.append("<tr><td colspan=\"3\" background=\"" + sImagesRoot + "/images/loginfoot_med.gif\" height=\"3\"></td></tr>");  
  integraOut.append("<tr><td colspan=\"3\" background=\"" + sImagesRoot + "/images/spacer.gif\" height=\"3\"></td></tr>");  
  integraOut.append("</table>");

  integraOut.append("<div style=\"width:100%;height:480px;overflow-y:scroll;scrollbar-arrow-color:blue;scrollbar-face-color:#e7e7e7;scrollbar-3dlight-color:#a0a0a0;scrollbar-darkshadow-color:#888888\">");
  integraOut.append("<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" style=\"font-family:verdana; font-size:11px; color:#ffffff\">");

  java.util.Vector vBlocks = oPage.blocks();

  int iBlocks = vBlocks.size();

  if (DebugFile.trace) DebugFile.writeln("<JSP:wb_mnuintegrador.jsp " + String.valueOf(iBlocks) + " blocks found");

  String sURLWrkPage = "?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_pageset="  + gu_pageset;
  String lastTag = "";
  int tagCounter = 1;
  Block oBlk;
  
  for (int i = 0; i<iBlocks; i++) {
    oBlk = ((Block)vBlocks.get(i));
    
		if (oBlk!=null) {
      String sTag = nullif(oBlk.tag()).length()==0 ? oBlk.metablock().toLowerCase() : oBlk.tag();

      sURLEditBlock  = sURLRoot + "/webbuilder/wb_editblock.jsp" + sURLWrkPage + "&gu_page=" + oPage.guid() + "&doctype=" + sDocType + "&page=" + sPage + "&id_block=" + oBlk.id() + "&id_metablock=" + oBlk.metablock()+ "&nm_metablock=" + Gadgets.URLEncode(sTag);
    
      if (sTag.equals(lastTag))
       tagCounter++;
      else
       tagCounter = 1;
    
      lastTag = sTag;
    
      integraOut.append("<tr>");
      integraOut.append("<td onmouseover=activateBlock(\"" + oBlk.metablock() + "_" + tagCounter + "\") onmouseout=deactivateBlock(\"" + oBlk.metablock() + "_" + tagCounter + "\") align=\"left\" valign=\"middle\"><font class=\"formplain\" face=\"Verdana\" color=\"white\">&nbsp;&#149;&nbsp;<a class=\"formplain\" style=\"color:white\" href=\"" + sURLEditBlock + "\">" + lastTag + " (" + tagCounter + ")</a></font></td>");
      integraOut.append("<td valign=\"middle\" align=\"right\" ><font size=\"1\"><input name=\"" + oBlk.id() + "\" type=\"checkbox\"></font></td>");
      integraOut.append("</tr>");
    }
    
  } // next (i)
  
  integraOut.append("</table>");
  integraOut.append("</div");
  integraOut.append("</form>");
  
  out.write("var webserver_param='" + sURLRoot + "';\nvar integradorHTML='" + integraOut.toString() + "';");

  if (DebugFile.trace) DebugFile.writeln("<JSP:wb_mnuintegrador.jsp finished sucessfully");
%>
<%@ include file="../methods/page_epilog.jspf" %>
