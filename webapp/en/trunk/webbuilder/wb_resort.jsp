<%@ page import="org.w3c.dom.DOMException,java.util.Vector,java.io.FileNotFoundException,java.io.IOException,java.net.URLDecoder,com.knowgate.dataxslt.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
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
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = request.getParameter("gu_pageset");
  String gu_page = request.getParameter("gu_page");
  String doctype = request.getParameter("doctype");  
  String id_metablock = request.getParameter("id_metablock");
  String nm_metablock = request.getParameter("nm_metablock");
  String file_pageset = request.getParameter("file_pageset");
  String file_template = request.getParameter("file_template");

  Block oBlk;
  String sNxt, sPrv;
  Vector oBlocks = null;
  Vector oBlocksSorted = null;
  Vector oParagraphs;
  int iBlocks = 0;
  
  PageSet oPageSet = null;
    
  try {
    oPageSet = new PageSet(file_template,file_pageset);
    
    Page oPage = oPageSet.page(gu_page);
    
    oBlocks = oPage.blocks(id_metablock, null, null);
    iBlocks = oBlocks.size();
    
    oBlocksSorted = new Vector(iBlocks);
    
    int iMin,iPos,iId;
    
    for (int cOrdered=0; cOrdered<iBlocks; cOrdered++) {
      iId = -1;
      iPos = -1;
      iMin = 2147483647;
      
      for (int b=0; b<iBlocks; b++) {
	      if (null!=oBlocks.get(b)) {
          iId = Integer.parseInt(((Block)oBlocks.get(b)).id()); 
          if (iId<iMin) {
            iMin = iId;
            iPos = b;
          } // fi ()      
        } // fi ()
      } // next

      oBlocksSorted.add(oBlocks.get(iPos));
      oBlocks.setElementAt(null, iPos);
    } // next
    
    oBlocks = null;
  }
  catch (DOMException e) {
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "DOMException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DOMException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (NullPointerException e) {
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NullPointerException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=_back"));
  } 
  catch (ClassNotFoundException e) {
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "ClassNotFoundException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ClassNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (IllegalAccessException e) {  
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IllegalAccessException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalAccessException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (FileNotFoundException e) {  
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "FileNotFoundException", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (Exception e) {  
    oPageSet = null;
    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "Exception", e.getMessage());
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oPageSet) return;
%>
<HTML>
  <HEAD>
    <TITLE>hipergate :: Reorder blocks</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>  
    <SCRIPT TYPE="text/javascript" DEFER="defer">
      <!--
        function swap(sa,sb) {
        
          if (sa.length==0 || sa.length==0) return;
          
          var frm = document.forms[0];
                    
          var id = frm.elements["block-"+sa].value;
          var nm = frm.elements["name-"+sa].value;
          var tx = frm.elements["text-"+sa].value;

      	  frm.elements["block-"+sa].value = frm.elements["block-"+sb].value;
      	  frm.elements["name-"+sa].value = frm.elements["name-"+sb].value;
      	  frm.elements["text-"+sa].value = frm.elements["text-"+sb].value;
      
      	  frm.elements["block-"+sb].value = id;
      	  frm.elements["name-"+sb].value = nm;
      	  frm.elements["text-"+sb].value = tx;          
        }
        
        // --------------------------------------------------------------------
        
        function validate() {
	  var frm = document.forms[0];
	  var olo = frm.old_order.value.split(",");
          var nwo = frm.new_order;
          
          nwo.value = "";

	  for (var b=0; b<olo.length; b++) {
	    if (b>0) nwo.value += ",";
	    
	    nwo.value += frm.elements["block-" + olo[b]].value;	    
	  } // next
	  
	  return true;
        } // validate
        
      //-->
    </SCRIPT>
  <STYLE TYPE="text/css">
    <!--
      .flat1 { border-style:none;background-color:white }
      .flat2 { border-style:none;background-color:whitesmoke }
    -->
  </STYLE>    
  </HEAD>
  <BODY>
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
    <TABLE WIDTH="100%">
      <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
      <TR><TD CLASS="striptitle"><FONT CLASS="title1">Reorder blocks</FONT></TD></TR>
    </TABLE>  
    <FORM METHOD="post" ACTION="wb_resort_store.jsp" onsubmit="return validate()">
      <TABLE>
<%  
  for (int b=0; b<iBlocks; b++) {

    oBlk = (Block) oBlocksSorted.get(b);

    if (b>0)
      sPrv = ((Block) oBlocksSorted.get(b-1)).id();
    else    
      sPrv = "";
    
    if (b<iBlocks-1)
      sNxt = ((Block) oBlocksSorted.get(b+1)).id();
    else
      sNxt = "";
      
    out.write ("        <TR><TD CLASS=\"strip" + String.valueOf((b%2)+1) + "\">");

    if (0==b)
      out.write ("<IMG SRC=\"../images/images/spacer.gif\" WIDTH=\"14\" HEIGHT=\"14\" BORDER=\"0\">&nbsp;<A HREF=\"#\" TITLE=\"Move down\" onclick=\"swap('" + oBlk.id() + "','" + sNxt + "')\"><IMG SRC=\"../images/images/webbuilder/movedown.gif\" WIDTH=\"14\" HEIGHT=\"14\" BORDER=\"0\"></A>&nbsp;");
    else if (iBlocks-1==b)
      out.write ("<A HREF=\"#\" TITLE=\"Move up\" onclick=\"swap('" + sPrv + "','" + oBlk.id() + "')\"><IMG SRC=\"../images/images/webbuilder/moveup.gif\" WIDTH=\"14\" HEIGHT=\"14\" BORDER=\"0\"></A>&nbsp;<IMG SRC=\"../images/images/spacer.gif\" WIDTH=\"14\" HEIGHT=\"14\" BORDER=\"0\">&nbsp;");
    else
      out.write ("<A HREF=\"#\" TITLE=\"Move up\" onclick=\"swap('" + sPrv + "','" + oBlk.id() + "')\"><IMG SRC=\"../images/images/webbuilder/moveup.gif\" WIDTH=\"14\" HEIGHT=\"14\" BORDER=\"0\"></A>&nbsp;<A HREF=\"#\" TITLE=\"Move down\" onclick=\"swap('" + oBlk.id() + "','" + sNxt + "')\"><IMG SRC=\"../images/images/webbuilder/movedown.gif\" WIDTH=\"14\" HEIGHT=\"14\" BORDER=\"0\"></A>&nbsp;");
        
    out.write ("<INPUT TYPE=\"hidden\" NAME=\"block-" + oBlk.id() + "\" VALUE=\"" + oBlk.id() + "\">");
    out.write ("<INPUT CLASS=\"flat" + String.valueOf((b%2)+1) + "\" NAME=\"name-" + oBlk.id() + "\" TABINDEX=\"-1\" SIZE=\"30\" TYPE=\"text\" VALUE=\"" + nm_metablock + " (" + String.valueOf(b+1) + ")\">&nbsp;");


    out.write ("<INPUT CLASS=\"flat" + String.valueOf((b%2)+1) + "\" NAME=\"text-" + oBlk.id() + "\" TABINDEX=\"-1\" SIZE=\"60\" TYPE=\"text\" VALUE=\"");
    
    oParagraphs = oBlk.paragraphs();

    if (oParagraphs.size()>1) {
      
      if (((Paragraph)oParagraphs.get(0)).id().equals("REMOVABLE"))
        out.write (Gadgets.left(((Paragraph)oParagraphs.get(1)).text(), 40));
      else
        out.write (Gadgets.left(((Paragraph)oParagraphs.get(0)).text(), 40));

    }

    out.write ("\">");
    out.write ("        </TD></TR>\n");

  } // next (b)
%>
      </TABLE>
      <HR>
      <CENTER>
      <INPUT TYPE="submit" ACCESSKEY="r" VALUE="Reorder" NAME="do" CLASS="pushbutton" STYLE="width:100" TITLE="ALT+r">
      &nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:100" TITLE="ALT+c" onclick="window.close()">
      </CENTER>
      <INPUT TYPE="hidden" NAME="old_order" VALUE="<% for (int b=0; b<iBlocks; b++) { if (b>0) out.write (","); out.write (((Block) oBlocksSorted.get(b)).id()); } %>">
      <INPUT TYPE="hidden" NAME="new_order">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="gu_pageset" VALUE="<%=gu_pageset%>">
      <INPUT TYPE="hidden" NAME="gu_page" VALUE="<%=gu_page%>">
      <INPUT TYPE="hidden" NAME="doctype" VALUE="<%=doctype%>">
      <INPUT TYPE="hidden" NAME="id_metablock" VALUE="<%=id_metablock%>">
      <INPUT TYPE="hidden" NAME="nm_metablock" VALUE="<%=nm_metablock%>">
      <INPUT TYPE="hidden" NAME="file_pageset" VALUE="<%=file_pageset%>">
      <INPUT TYPE="hidden" NAME="file_template" VALUE="<%=file_template%>">
    </FORM>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>