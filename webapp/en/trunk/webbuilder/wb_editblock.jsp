<%@ page import="org.w3c.dom.*,com.knowgate.misc.*,java.io.File,java.lang.*,java.util.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.dataxslt.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.db.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%!
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
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // Rutas y parámetros
  String sSkin = getCookie (request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
    
  String id_domain = getCookie(request,"domainid","");
  String n_domain = request.getParameter("n_domain");
  
  String sDefURLRoot = request.getRequestURI();
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));

  String sURLRoot	= Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver", sDefURLRoot);

  if (sURLRoot.endsWith("/") && sURLRoot.length()>0) sURLRoot = sURLRoot.substring(0, sURLRoot.length()-1);

  String sDefImgSrv = request.getRequestURI();
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv + "/images";
  
  String sImagesRoot    = Environment.getProfileVar(GlobalDBBind.getProfileName(),"imageserver",sDefImgSrv);
  String sStorage	= Environment.getProfilePath(GlobalDBBind.getProfileName(),"storage");
  String sDocType	= request.getParameter("doctype");
  String gu_workarea	= request.getParameter("gu_workarea");
  String gu_pageset	= nullif(request.getParameter("gu_pageset"));
  String gu_page	= nullif(request.getParameter("gu_page"));
  String sPage		= request.getParameter("page");
  String id_block	= nullif(request.getParameter("id_block"),"");
  String id_metablock	= nullif(request.getParameter("id_metablock"),"");
  String nm_metablock	= nullif(request.getParameter("nm_metablock"),"");
  String sMenuPath	= sURLRoot + "/webbuilder/wb_mnuintegrador.jsp?id_domain" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_pageset=" + gu_pageset;
  
  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sOutputPath	= new String(sStorage + "domains/" + id_domain + "/workareas/" + gu_workarea + "/apps/Mailwire/html/" + gu_pageset + "/");
  String sBlockXML	= new String("\t<block>\n\t  <metablock>" + id_metablock + "</metablock>\n\t  <tag>" + nm_metablock + "</tag>\n\t  <paragraphs>\n\t    <paragraph id=\"REMOVABLE\"></paragraph>\n\t  </paragraphs>\n\t  <images>\n\t    <image id=\"REMOVABLE\"></image>\n\t  </images>\n\t  <zone/>\n\t</block>");
  String sEnvWorkPut	= Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasput", sDefWrkArPut);
  String sImagesUrl 	= sEnvWorkPut + File.separator + gu_workarea + File.separator + "apps" + File.separator + "Mailwire" + File.separator + "data" + File.separator + "images";
  
  boolean bAllowHTML = false;
  int bAddBlock = 0;
  PageSetDB oPageSetDB = new PageSetDB();
  MicrositeDB oMicrositeDB = new MicrositeDB();
  String gu_microsite = null;
  
  // Clave primaria para Recuperar el PageSet
  Object aPKs[] = {gu_pageset};

  JDCConnection oConn = null;
  boolean bIsGuest = true;

  try {
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
  
    oConn = GlobalDBBind.getConnection("wb_editblock");
    
    oPageSetDB.load(oConn,aPKs);
    
    gu_microsite = oPageSetDB.getString("gu_microsite");

    oMicrositeDB.load(oConn,new Object[]{gu_microsite});

    oConn.close("wb_editblock");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("wb_editblock");
    oConn=null;
    
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
        
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  
  if (oConn==null) return;
  
  // Proceso de rendering en modo edición

  String sFilePageSet = sStorage + oPageSetDB.getString(DB.path_data);
  String sFileTemplate = sStorage + oMicrositeDB.getString(DB.path_metadata);

  PageSet oPageSet = new PageSet(sFileTemplate,sFilePageSet);
  Page oPage = null;
  java.util.Vector vPages = oPageSet.pages();

  for (int numPage=0; numPage<vPages.size(); numPage++) {
   oPage = (Page) vPages.elementAt(numPage);
   if (oPage.guid().equals(gu_page)) break;
  } // next

  if (id_block.length()==0) {
  
     //try {
       id_block = oPageSet.addBlock (sFilePageSet,oPage.guid(), sBlockXML);
       bAddBlock = 1;

       oPageSet = new PageSet(sFileTemplate,sFilePageSet);
       oPage = null;

       vPages = oPageSet.pages();

       for (int numPage=0; numPage<vPages.size(); numPage++) {
         oPage = (Page) vPages.elementAt(numPage);
         if (oPage.guid().equals(gu_page)) break;
       } // next
     /*
     }
     catch (java.io.UTFDataFormatException utfe) {
       bAddBlock = 0;
       response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=UTFDataFormatException&desc=UTFDataFormatException " + utfe.getMessage() + " " + sFilePageSet + "&resume=_close"));  
     }
     */
     if (0==bAddBlock) return;
     
  } // fi (id_block.length())

  
  // Recuperar información de bloque de XML de datos

  int bFound = 0;
  Vector vBlocks = oPage.blocks();
  int iBlocks = vBlocks.size();
  int iIdBlock = Integer.parseInt(id_block);
  
  for (int i=0; ((bFound==0) && (i<iBlocks)); i++) {
     int iId = Integer.parseInt((((Block)(vBlocks.get(i))).id()));
     if (iId==iIdBlock) 
     	bFound=i;
  } // next

  Block oBlock = (Block)(vBlocks.get(bFound));
  Microsite oMicrosite = MicrositeFactory.getInstance(sFileTemplate);
  
  Vector vContainers = oMicrosite.containers();
  Vector oMetablocks = null;
  
  for (int i=0; i<vContainers.size(); i++) {
    if (((Container)(vContainers.elementAt(i))).guid().equals(oPage.container())) {
  	oMetablocks = ((Vector)(((Container)(vContainers.elementAt(i))).metablocks()));
  	break;
    } // fi (Containers.elementAt(i).guid()==ThisPage.container())
  } // next (Container)
  
  Vector vParagraphs = new Vector();
  Vector vImages = new Vector();
  Vector vParagraphsState = new Vector();
  Vector vImagesState = new Vector();
  
  Integer iMenosUno = new Integer(-1);

  int iMetaBlocks = oMetablocks.size();

  if (oMetablocks.size()>0) {
    MetaBlock oCurMetaBlock = (MetaBlock)(oMetablocks.elementAt(0));
    for (int i=0; i<iMetaBlocks; i++) {
  
       oCurMetaBlock = (MetaBlock)(oMetablocks.elementAt(i));
       if (oBlock.metablock().equals(oCurMetaBlock.id())) {
         bAllowHTML = oCurMetaBlock.allowHTML();
         break;
       }
    }
  
    String[] sObjects = oCurMetaBlock.objects();
    
    for (int i=0;i<sObjects.length;i++) {
      String sItems = sObjects[i];
      String aSplittedItems[] = Gadgets.split2(sItems,':');
      String sType = aSplittedItems[0];
      if (aSplittedItems[1].indexOf("..")!=-1)
      {
        String sFullIdentifier = aSplittedItems[1];
      
        int iPosCardinality = sFullIdentifier.indexOf("[");
        int iStartMaxOccurrences = iPosCardinality + 4;
        int iFinishMaxOccurrences = sFullIdentifier.indexOf("]");
        int iMaxDigits = iFinishMaxOccurrences - iStartMaxOccurrences;
        String sNumOccurrences = sFullIdentifier.substring(iStartMaxOccurrences,iFinishMaxOccurrences);
        String sIdentifier = sFullIdentifier.substring(0,iPosCardinality);
      
        Integer iCounter = new Integer(sNumOccurrences);

        for (int j=0; j<iCounter.intValue(); j++)
        {
      	  String sItemIndex = (new Integer(j+1)).toString();
      	
      	  //Aplicar padding de ceros
      	  while (sItemIndex.length()<iMaxDigits) sItemIndex = "0" + sItemIndex;
      	
        	String sFinalIdentifier = sIdentifier + sItemIndex;
        	if (sType.indexOf("p")==0)
        	{
           	vParagraphs.add(sFinalIdentifier);
           	vParagraphsState.add(iMenosUno);
         	}
         	else
         	{
           	vImages.add(sFinalIdentifier);
           	vImagesState.add(iMenosUno);
          }
         }
      }
      else
         if (sType.indexOf("p")==0)
         {
                  vParagraphs.add(aSplittedItems[1]);
                  vParagraphsState.add(iMenosUno);
         }
         else
         {
           	vImages.add(aSplittedItems[1]);
           	vImagesState.add(iMenosUno);
         }
     }

     // Marcar los parrafos presentes
     try {
       int iParagraphs = vParagraphs.size();
       for (int j=0; j<iParagraphs; j++)
         for (int i=0; i<oBlock.paragraphs().size(); i++)
           if (((Paragraph) oBlock.paragraphs().elementAt(i)).id().equals((String)vParagraphs.elementAt(j)))
       vParagraphsState.add(j,(new Integer(i)));
     } catch (java.lang.NullPointerException e) {}
     
     // Marcar las imagenes presentes
     try {
       if (oBlock.images()!=null)
         for (int j=0; j<vImages.size(); j++)
           for (int i=0; i<oBlock.images().size(); i++)
             if (((Image)oBlock.images().elementAt(i)).id().compareTo((String)vImages.elementAt(j))==0)
               vImagesState.add(j,(new Integer(i)));
     } catch (java.lang.NullPointerException e) {}

   } // fi
%>
<html lang="<%=sLanguage%>">
<head>
  <META HTTP-EQUIV="content-type" CONTENT="text/html; charset=UTF-8">
  <TITLE>hipergate :: Editar bloque</TITLE>
  <SCRIPT LANGUAGE="Javascript" TYPE="text/javascript">
    <!--
    var htmlAreaEnabled = true;
  	_editor_url = "../javascript/htmlarea/";
    _editor_lang = "<%=sLanguage%>";
    _editors = new Object();
    // -->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT> 
  <SCRIPT TYPE="text/javascript" SRC="../javascript/htmlarea/htmlarea.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/htmlarea/lang/es.js"></SCRIPT>
  <SCRIPT LANGUAGE="Javascript" TYPE="text/javascript">
    <!--
    HTMLArea.init();
    
    var config = new HTMLArea.Config();
    
    config.width = "100%";
    config.height = "70px";
    config.bodyStyle = 'background-color: white; font-family: "Verdana"; font-size: x-small;';
    config.debug = 0;
        
    config.toolbar = [
    [ 
      "bold", "italic", "underline", "strikethrough", "subscript", "superscript", "separator", "createlink", "separator",
      "copy", "cut", "paste", "space", "undo", "redo"],
    ];
    // -->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
     <!--
      
     // **********************************************
     // Funciones para incorporar campos de Mail Merge

     function storeCaret (textEl) {
       if (textEl.createTextRange) 
         textEl.caretPos = document.selection.createRange().duplicate();
     }

     // -------------------------------------------------------
          
     function insertVariable (id,val) {
       if (id.indexOf(".text")!=-1 && htmlAreaEnabled) {
		     _editors[id].insertHTML(val);
       } else {
         document.getElementById(id).focus();
         insertAtCaret(document.getElementById(id),val);
       }
     } // insertVariable

     // -------------------------------------------------------

     function insertAtCaret (textEl, text) {
       if (textEl.createTextRange && textEl.caretPos) {
         var caretPos = textEl.caretPos;
         caretPos.text =
           caretPos.text.charAt(caretPos.text.length - 1) == ' ' ?
             text + ' ' : text;
       }
       else
         textEl.value  += text;
     } // insertAtCaret
     
     // *****************************************************************************
     // Funciones para reemplazar valores de formulario desde una ventana con remonte     

     function setItem (itemName,itemValue)
     {
       var i;
       for (i=0; i<document.forms[0].length; i++)
         if (document.forms[0].elements[i].name==itemName) {
           if (itemName.indexOf(".text")!=-1 && htmlAreaEnabled) {
             _editors[itemName].setHTML(itemValue);
           } else {
             document.forms[0].elements[i].value = itemValue;
           }
         }
     } // setItem

     // -------------------------------------------------------

     function getItem(itemName)
     {
       var i;
       for (i=0; i<document.forms[0].length; i++) {
         if (document.forms[0].elements[i].name==itemName) {
           if (itemName.indexOf(".text")!=-1 && htmlAreaEnabled) {
             return _editors[itemName].getHTML();
           } else
             return (document.forms[0].elements[i].value);
         }
       }
     }
     
     // *****************************
     // Funciones para vaciar un item

     function cleanParagraph(id)
     {
       setItem('Paragraph.'+id+'.text','');
       setItem('Paragraph.'+id+'.url','');
     }

     // -------------------------------------------------------

     function cleanImage(id)
     {
       setItem('Image.'+id+'.path','');
       setItem('Image.'+id+'.height','');
       setItem('Image.'+id+'.width','');
       setItem('Image.'+id+'.url','');
       setItem('Image.'+id+'.alt','');
     }

     // -------------------------------------------------------

     function openPicture (pictureName) 
     { 
      	var w2 = window.open("about:blank", "wViewImage", "directories=no,toolbar=no,menubar=no,theatermode,resizable=false,width=1,height=1,top=" + screen.height/2 + ",left=" + screen.width/2); 
      	w2.blur();
      	window.focus();
      	w2.document.write("<html>"); w2.document.write("\n");
      	w2.document.write("<head>"); w2.document.write("\n");
      	w2.document.write("<title>"); w2.document.write("\n");
      	w2.document.write("hipergate :: View image (" + pictureName + ")"); w2.document.write("\n");
      	w2.document.write("</title>"); w2.document.write("\n");
      	w2.document.write("</head>"); w2.document.write("\n");
      	w2.document.write("<body topmargin=0 marginheight=0 leftmargin=0>"); w2.document.write("\n");
      	w2.document.write("<center>"); w2.document.write("\n");
      	w2.document.write("<table width=100% height=100% border=0 cellspacing=0 cellpadding=0>"); w2.document.write("\n");
      	w2.document.write("<tr>"); w2.document.write("\n");
      	w2.document.write("<td align=middle valign=middle>"); w2.document.write("\n");
      	w2.document.write("<img name='laimagen' border='0' align='middle' src='" + pictureName + "'>"); w2.document.write("\n");
      	w2.document.write("</td>"); w2.document.write("\n");
      	w2.document.write("</tr>"); w2.document.write("\n");
      	w2.document.write("</table>"); w2.document.write("\n");
      	w2.document.write("</body>"); w2.document.write("\n");
      	w2.document.write("<script>"); w2.document.write("\n");
      	w2.document.write("window.resizeTo(laimagen.width+10,laimagen.height+20);"); w2.document.write("\n");
      	w2.document.write("window.moveTo(parseInt((screen.width-laimagen.width-10)/2),parseInt((screen.height-laimagen.height-20)/2));"); w2.document.write("\n");
      	w2.document.write("a=0;"); w2.document.write("\n");
      	w2.document.write("</script>"); w2.document.write("\n");
      	w2.document.write("</html>"); w2.document.write("\n");
      	w2.focus();
     }    

     // -------------------------------------------------------
     
     function openLink(url) { window.open(url,"menubar=no,top=" + (screen.height-600)/2 + ",left=" + (screen.width-800)/2 + ",width=800,height=600,scrollbars=yes"); }

     // -------------------------------------------------------
  
     function reSort() {
       document.location.href="wb_resort.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=gu_pageset%>&gu_page=<%=gu_page%>&doctype=<%=sDocType%>&id_metablock=<%=id_metablock%>&nm_metablock=<%=nm_metablock%>&file_pageset=" + escape(document.forms[0].file_pageset.value) + "&file_template=" + escape(document.forms[0].file_template.value);
     }

     // -------------------------------------------------------

     function submitChanges() {
       var frm = document.forms[0];
       if (htmlAreaEnabled && <%=String.valueOf(bAllowHTML)%>) {
<%      if (vParagraphs.size()>0) { 
				  for (int i=0; i<vParagraphs.size(); i++) {
             int iParPos = ((Integer)vParagraphsState.elementAt(i)).intValue();
             String sParId = "";
             if (iParPos<0) {
               sParId = (String)(vParagraphs.elementAt(i));
             } else {
               Paragraph oParCur = (Paragraph) oBlock.paragraphs().elementAt(iParPos);
               sParId = oParCur.id();
             } %>
             frm.elements["Paragraph.<%=sParId%>.text"].value = _editors["Paragraph.<%=sParId%>.text"].getHTML();
                         var wDoc = "<"+"w"+":"+"WordDocument"+">";
						 if (frm.elements["Paragraph.<%=sParId%>.text"].value.indexOf(wDoc)>0) {
						   alert ("Paragraph <%=sParId%>. It is not allowed to paste Word contents into HTML documents");
						   return false;
						 }
						 var cData = "<"+"!"+"[CDATA[";
						 if (frm.elements["Paragraph.<%=sParId%>.text"].value.indexOf(cData)>0) {
						   alert ("Párrafo <%=sParId%>. Paragraph does not have a valid HTML format");
						   return false;
						 }<%      } } %>
       } // fi
       frm.submit();
     } // submitChanges

     // -------------------------------------------------------

     function setCombos() {
       var frm = document.forms[0];
       scroll(0,0);
       if (htmlAreaEnabled && <%=String.valueOf(bAllowHTML)%>) {
<%      if (vParagraphs.size()>0) { 
				  for (int i=0; i<vParagraphs.size(); i++) {
      			 String sCurText = "";
             int iParPos = ((Integer)vParagraphsState.elementAt(i)).intValue();
             String sParId = "";
             if (iParPos<0) {
               sParId = (String)(vParagraphs.elementAt(i));
             } else {
               Paragraph oParCur = (Paragraph) oBlock.paragraphs().elementAt(iParPos);
               sParId = oParCur.id();
        			 try { sCurText = oParCur.text(); } catch (NullPointerException e) { sCurText = ""; }
             }
             if (sCurText.length()==0) out.write("cleanParagraph(\""+sParId+"\");\n");
           } } %>
       } // fi
     }

    -->
  </SCRIPT>
</head>
<body topmargin="0" marginheight="0" onload="setCombos()">
<table cellspacing="0" cellpadding="0" border="0" width="99%">
  <tr>
    <td valign="top" bgcolor="#ffffff">
    <% out.write("      <img src=\"" + sURLRoot + "/skins/" + sSkin + "/hglogopeq.jpg\" border=\"0\">"); %>
    </td>
  </tr>
  <tr>
    <td valign="center" bgcolor="#cccccc">
      <span class="title1">&nbsp;Block:&nbsp;<%=oBlock.tag()%></span>
    </td>
  </tr>
  <tr>
    <td align="left">
      <hr size="1">
      <img src="../images/images/floppy.gif" border="0" align="middle">&nbsp;
<% if (bIsGuest) { %>
      <a class="linkplain" href="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')">Guardar</a>
<% } else { %>
      <a class="linkplain" href="#" onclick="submitChanges()">Save</a>
<% } %>
      &nbsp;&nbsp;<img src="../images/images/back.gif" border="0" align="middle">&nbsp;<a class="linkplain" href="#" onclick="if (window.confirm('Are you sure?Changes will be lost and original data wil be restored. ')) document.location = 'wb_document.jsp?id_domain=<%=id_domain%>&doctype=<%=sDocType%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=gu_pageset%>&page=<%=sPage%>';">Back</a>
      &nbsp;&nbsp;<img src="../images/images/resort.gif" border="0" align="middle">&nbsp;<a class="linkplain" href="javascript:reSort()">Reorder</a>

      <hr size="1">
    </td>
  </tr>
</table>
<form name="frmEditBlock" id="frmEditBlock" action="wb_editblock_persist.jsp" method="post">
<input type="hidden" name="add_block" value="<%=bAddBlock%>">
<input type="hidden" name="id_domain" value="<%=id_domain%>">
<input type="hidden" name="n_domain" value="<%=n_domain%>">
<input type="hidden" name="gu_workarea" value="<%=gu_workarea%>">
<input type="hidden" name="gu_pageset" value="<%=gu_pageset%>">
<input type="hidden" name="gu_page" value="<%=gu_page%>">
<input type="hidden" name="page" value="<%=sPage%>">
<input type="hidden" name="doctype" value="<%=sDocType%>">
<input type="hidden" name="file_template" value="<%=sFileTemplate%>">
<input type="hidden" name="file_pageset" value="<%=sFilePageSet%>">
<input type="hidden" name="id_metablock" value="<%=id_metablock%>">
<input type="hidden" name="id_block" value="<%=id_block%>">
<input type="hidden" name="Block.<%=id_block%>.id" value="<%=id_block%>">
<%
     int vParSize = vParagraphs.size();
     if (vParSize>0) {
%>
<table cellspacing="0" cellpadding="0" border="0" width="95%">
<tr>
<td valign="center" width="32"></td>
<td valign="center">
<span class="title1">NOMBRE DEL BLOQUE</span><br>
<input type="text" name="nm_metablock" size="70" maxlength="100" value="<%=nullif(nm_metablock).length()==0 ? oBlock.tag() : nm_metablock%>">
<br>
</td>
</tr>
<tr>
<td valign="center" width="32">
<!--<img width="32" height="32" align="middle" border="0" src="../images/images/webbuilder/text.jpg">-->
</td>
<td valign="center">
<span class="title1">TEXTOS</span>
</td>
</tr>
</table>
<%  
    for (int i=0; i<vParSize; i++)
    {
      int iPosition = ((Integer)vParagraphsState.elementAt(i)).intValue();
      String sCurId = "";
      String sCurUrl = "";
      String sCurText = "";
       
      if (iPosition<0)
        sCurId = (String)(vParagraphs.elementAt(i));
      else
      {
        Paragraph curParagraph = (Paragraph) oBlock.paragraphs().elementAt(iPosition);
        sCurId = curParagraph.id();
        try { sCurUrl = curParagraph.url(); } catch (NullPointerException e) { sCurUrl = ""; }
        try { sCurText = curParagraph.text(); } catch (NullPointerException e) { sCurText = ""; }
      }
%>
<center>
<table cellspacing="0" class="formfront" cellpadding="3" style="border-style:dashed;border-width:1px;border-color:dimgray" width="95%">
  <tr>
    <td colspan="2" class="formstrong"><% out.write(sCurId.replace('_',' ')); %></td>
    <td align="right">
      <img src="../images/images/webbuilder/cleanup.gif" width="16" height="16" border="0" align="middle">&nbsp;<a class="linkplain" href="javascript:void(0)" onclick="javascript:cleanParagraph('<%=sCurId%>');">Limpiar contenido</a>
    </td>
  </tr>
  <tr>
    <td colspan="3" class="formplain">
      <input type="hidden" name="Paragraph.<%=sCurId%>.id" value="<%=sCurId%>"> 
      <textarea rows="<%=bAllowHTML ? "7" : "5"%>" cols="88" id="Paragraph.<%=sCurId%>.text" name="Paragraph.<%=sCurId%>.text" WRAP="soft" onselect="storeCaret(this);" onclick="storeCaret(this);" onkeyup="storeCaret(this);"><%=sCurText%></textarea>
      <script type="text/javascript">if (htmlAreaEnabled && <%=String.valueOf(bAllowHTML)%>) { var t = "Paragraph.<%=sCurId%>.text"; var e = new HTMLArea(HTMLArea.getElementById('textarea',t), config); e.generate(); _editors[t]=e; } </script>
    </td>
  </tr>
  <tr>
    <td width="" class="formstrong">Link:&nbsp;</td>
    <td class="formplain">
<%
  String sUrl;
  if (sCurUrl!=null)
    sUrl = Gadgets.HTMLEncode(sCurUrl);
  else
    sUrl = "";
%>
      <input type="text" name="Paragraph.<% out.write(sCurId); %>.url" value="<% out.write(sUrl); %>" size="50">
<%
 if (sDocType.equals("website")) {
%>
      <a href="javascript:void(0)" onclick="window.open('wb_addlink.jsp?itemid=Paragraph.<% out.write(sCurId); %>.url&file_pageset=<%=sFilePageSet%>&file_template=<%=sFileTemplate%>','wAddLink','top=' + (screen.height-320)/2 + ',left=' + (screen.width-200)/2 + ',height=320,width=200')">Enlace especial</a>
<% } %>
    </td>
    <td class="formplain" valign="middle" align="right">
      <table border="0">
        <tr>
          <td>
            <img src="../images/images/webbuilder/mailmerge.gif" border="0" align="middle">
          </td>
          <td class="formplain" valign="middle" align="left">
            Insert variable field&nbsp;
            <select name="Mailmerge_<%=sCurId%>"><option value="{#Datos.Nombre}">Name<option value="{#Datos.Apellidos}">Surname<option value="{#Datos.Email}">e-mail<option value="{#Sistema.Hora}">Hour<option value="{#Sistema.Fecha}">Date</select>&nbsp;
            <a class="linkplain" href="javascript:void(0)" onclick="insertVariable('Paragraph.<%=sCurId%>.text',document.frmEditBlock.elements['Mailmerge_<%=sCurId%>'].options[document.frmEditBlock.elements['Mailmerge_<%=sCurId%>'].selectedIndex].value)">Insert</a>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
</center>
<br>
<% 
    } //for
  
} //if  
    try{
     if (vImages.size()>0) {
%>
<table cellspacing="0" cellpadding="0" border="0" width="95%">
  <tr>
    <td width="32" valign="center">
      <img align="middle" width="32" height="32" border="0" src="../images/images/webbuilder/picture.jpg">
    </td>
    <td valign="center">
      <span class="title1">IMAGES</span>
    </td>
  </tr>
</table>
<%  }
    } catch (java.lang.NullPointerException e) { }
    
    try{
    int vImageSize = vImages.size();
    for (int i=0; i<vImageSize; i++)
    {
      int iPosition = ((Integer)vImagesState.elementAt(i)).intValue();
      
      String sCurId = new String("");
      String sCurAlt = new String("");
      String sCurPath = new String("");
      String sCurHeight = new String("");
      String sCurWidth = new String("");
      String sCurUrl = new String("");
      
      if (iPosition<0)
        sCurId = (String)(vImages.elementAt(i));
      else
      {
        Image curImage = (Image)oBlock.images().elementAt(iPosition);
        sCurId = curImage.id();
        try { sCurUrl = curImage.url(); } catch (NullPointerException e) { sCurUrl = ""; }
        try { sCurAlt = curImage.alt(); } catch (NullPointerException e) { sCurAlt = ""; }
        try { sCurPath = curImage.path(); } catch (NullPointerException e) { sCurPath = ""; }
	try { sCurHeight = curImage.height(); } catch (NullPointerException e) { sCurHeight = ""; }        
        try { sCurWidth = curImage.width(); } catch (NullPointerException e) { sCurWidth = ""; }
      }
%>
<center>
<table cellspacing="0" cellpadding="0" class="formfront" border="1" width="95%">
  <tr>
    <td colspan="2" class="formstrong">
      <table cellspacing="0" cellpadding="0" class="formfront" border="0" width="100%">
        <tr>
          <td align="left" class="formstrong"><%=sCurId%></td>
          <td align="right"><img src="../images/images/webbuilder/cleanup.gif" width="16" height="16" border="0" align="middle">&nbsp;<a class="linkplain" href="javascript:void(0)" onclick="javascript:cleanImage('<%=sCurId%>')">Limpiar contenido</a>&nbsp;&nbsp;<img border="0" name="Image.<%=sCurId%>.view" align="middle" border="0" src="../images/images/viewtxt.gif" alt="Ver imagen actual">&nbsp;<a href="javascript:void(0)" onclick="javascript:openPicture(document.forms[0].elements['Image.<%=sCurId%>.path'].value);" class="linkplain">View image</a></td>
        </tr>
      </table>
      <input type="hidden" name="Image.<%=sCurId%>.id" value="<%=sCurId%>">
      <input type="hidden" name="Image.<%=sCurId%>.path" value="<%=sCurPath%>">
    </td>
  </tr>
  <tr>
    <td class="formplain">
    <b>Descripci&oacute;n:</b></td>
    <td>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td><input style="width:600" type="text" name="Image.<%=sCurId%>.alt" value="<%=sCurAlt%>"></td>
          <td align="right">
            <a href="javascript:void(0);"><img border="0" src="../images/images/find16.gif" onclick="javascript:setItem('Image.<%=sCurId%>.height','');setItem('Image.<%=sCurId%>.width','');window.open('wb_imageslist.jsp?doctype=<%=sDocType%>&id_domain=<%=id_domain%>&n_domain=<%=n_domain%>&gu_workarea=<%=gu_workarea%>&refreshitem=Image.<%=sCurId%>','wImagesList','top=' + (screen.height-600)/2 + ',left=' + (screen.width-800)/2 + ',width=800,height=600,scrollbars=yes');" alt="Select another image"></a>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td class="formplain"><b>Size</b></td>
    <td class="formplain"><b>Width:&nbsp;</b><input type="text" size="1" name="Image.<%=sCurId%>.width" value="<%=sCurWidth%>">&nbsp;<b>Height:&nbsp;</b><input type="text" size="1" name="Image.<%=sCurId%>.height" value="<%=sCurHeight%>"></td>
  </tr>
  <tr>
    <td class="formplain"><b>Link:</b></td>
    <td class="formplain">
      <input type="text" name="Image.<%=sCurId%>.url" value="<%=sCurUrl%>" size="60">
<%
 if (sDocType.equals("website")) {
%>
      <a href="javascript:void(0)" onclick="window.open('wb_addlink.jsp?itemid=Image.<%=sCurId%>.url&file_pageset=<%=sFilePageSet%>&file_template=<%=sFileTemplate%>','wAddLink','top=' + (screen.height-320)/2 + ',left=' + (screen.width-200)/2 + ',height=320,width=200')">Special link</a>
<%
 }
%>
    </td>
  </tr>
</table>
</center>
<br>
<%
    }
  } catch (NullPointerException npe) {}
%>
</form>
</body>
</html>
<%@ include file="../methods/page_epilog.jspf" %>