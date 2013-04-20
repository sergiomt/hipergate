<%@ page import="java.math.BigDecimal,java.net.URLDecoder,javax.mail.internet.MimeUtility,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Category,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="fldr_combo.jspf" %><%@ include file="mail_env.jspf" %><%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  if (oMacc.isNull(DB.gu_account)) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Account not found&desc=There is no mail account configured for current user&resume=../hipermail/account_list.jsp"));
    return;
  }

  response.addHeader ("cache-control", "no-cache");

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");
  
  String gu_folder = request.getParameter("gu_folder");
  String nm_folder = null;
  String screen_width = request.getParameter("screen_width");

  int iScreenWidth;
  float fScreenRatio;

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;

  int iMaxRows;
  
  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = 100;
  }
  catch (NumberFormatException nfe) { iMaxRows = 100; }

  // **********************************************

  int iMailCount = 0;
  String sOrderBy = null;
  
  // **********************************************
  
  ACLUser oMe = new ACLUser();
  Category oFolder = new Category();
  String sFolderLabel = "";
  JDCConnection oConn = null;
  DBSubset oMsgs = null;
  int iMsgs = 0;
  String sOutBox = null, sDrafts = null, sSent = null, sSpam = null, sDeleted = null, sReceived = null, sReceipts = null;
  StringBuffer oFoldersBuffer = new StringBuffer();

  try {
    oConn = GlobalDBBind.getConnection("msg_listing_local");
    oConn.setAutoCommit(true);

    if (gu_folder!=null) {
      oMe.load(oConn, new Object[]{id_user});

      sOutBox = oMe.getMailFolder(oConn, "outbox");
      sDrafts = oMe.getMailFolder(oConn, "drafts");
      sSent = oMe.getMailFolder(oConn, "sent");
      sSpam = oMe.getMailFolder(oConn, "spam");
      sDeleted = oMe.getMailFolder(oConn, "deleted");
      sReceived = oMe.getMailFolder(oConn, "received");
      sReceipts = oMe.getMailFolder(oConn, "receipts");

      if (request.getParameter("orderby")!=null) {
        sOrderBy = request.getParameter("orderby");
      } else if (gu_folder.equals(sOutBox) || gu_folder.equals(sDrafts)) {
        sOrderBy = "10";
      } else if (gu_folder.equals(sSent)) {
        sOrderBy = "8";
      } else if (gu_folder.equals(sReceived) || gu_folder.equals(sReceipts)) {
        sOrderBy = "7";
      }
      
      if (oFolder.load (oConn, new Object[]{gu_folder})) {

        if (gu_folder.equals(sOutBox)) {
          sFolderLabel = "Outbox";
					nm_folder = "outbox";
        } else if (gu_folder.equals(sReceived)) {
          sFolderLabel = "Received messages";
					nm_folder = "received";
        } else if (gu_folder.equals(sDeleted)) {
          sFolderLabel = "Deleted Messages";
					nm_folder = "deleted";
        } else if (gu_folder.equals(sDrafts)) {
          sFolderLabel = "Dratf";
					nm_folder = "drafts";
        } else if (gu_folder.equals(sSent)) {
          sFolderLabel = "Sent Messages";
					nm_folder = "sent";
        } else if (gu_folder.equals(sSpam)) {
          sFolderLabel = "Bulk Mail";
					nm_folder = "spam";
        } else if (gu_folder.equals(sReceipts)) {
        	sFolderLabel = "Read receipts";
					nm_folder = "receipts";
				} else {
					nm_folder = oFolder.getStringNull(DB.nm_category, "unnamed");
          sFolderLabel = oFolder.getLabel(oConn, sLanguage);
          if (null==sFolderLabel) sFolderLabel = oFolder.getLabel(oConn, Gadgets.left(sLanguage,2));
          if (null==sFolderLabel) sFolderLabel = nm_folder;
        }
      }
      else {
        throw new SQLException ("Mail Folder " + gu_folder + " not found");
      }
      
      paintFolders (oConn, oMe.getMailRoot(oConn), sLanguage, "", oFoldersBuffer);
    }
    
    oConn.close("msg_listing_local");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("msg_listing_local");
    oConn = null;    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  oConn = null;
  
  sendUsageStats(request, "folder_listing_local"); 
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <LINK HREF="../javascript/activewidgets/styles/<%=sSkin%>/grid.css" REL="stylesheet" TYPE="text/css" ></LINK>
  <LINK HREF="../skins/<%=sSkin%>/mailgrid.css" REL="stylesheet" TYPE="text/css" ></LINK>

  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/findit.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');
    var menuLayer;
    dynapi.onLoad(init);
    function init() {
 
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setHTML(rightMenuHTML);
      loadXMLData(0);
    }
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/activewidgets/lib/grid.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      // **************************
      // ActiveWidgets grid loading

      var cac;
      var gdata = new Array();
      var cols = ["", "From", "Subject", "Date", "Kb", "Id", "Num", "Guid"];
      var grid = new Active.Controls.Grid;
      var skip = 0;

      grid.setColumnCount(8);
      grid.setColumnProperty("text", function(i){return cols[i]});
      grid.setSelectionProperty("multiple", true); 
      
      function processCacheScan() {
          var irows;
          if (cac.readyState == 4) {
            if (cac.status == 200) {
	      if (cac.responseText.length>0) {
	        var arows = cac.responseText.split("\n");
	        irows = arows.length;
	        gdata = new Array(irows);
	        for (var r=0; r<irows; r++) {
		        gdata[r] = arows[r].split("\t");
	        }
	      } else {
	        irows = 0;
	        gdata = new Array();
	      }
	      document.getElementById("rcvng").style.display="none";
	      document.getElementById("rcimg").src="../images/images/spacer.gif";
	      grid.setRowCount(irows);
              grid.setDataProperty("text", function(i,j){return gdata[i][j]});
              grid.setStyle("height",(18*irows)+36); 
              grid.refresh();
              showLayer("prev");
              showLayer("next");
	      document.getElementById("next").style.display=(irows==<%=String.valueOf(iMaxRows)%> ? "block" : "none");
	      document.getElementById("prev").style.display=(skip>0 ? "block" : "none");
            }
            cac = false;
	  }
      } // processCacheScan

      // -----------------------------------------------------------------

      function loadXMLData(scroll) {
          cac = createXMLHttpRequest();
          if (cac) {
            hideLayer("prev");
            hideLayer("next");
	          document.getElementById("rcvng").style.display="block";
	          document.getElementById("rcimg").src="../images/images/hipermail/loading.gif";
            skip += scroll;
	          cac.onreadystatechange = processCacheScan;
            cac.open("GET", "folder_tsvfeed.jsp?gu_account=<%=oMacc.getString(DB.gu_account)%>&gu_folder=<%=gu_folder%>&skip="+String(skip)+"&maxrows=<%=String.valueOf(iMaxRows)%><%=(sOrderBy==null ? "" : "&orderby="+sOrderBy)%>", true);
            cac.send(null);
          } // fi
      } // loadXMLData
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // Global variables for moving the clicked row to the context menu

	var jsMsgId, jsMsgNum, jsMsgGuid;

        // ----------------------------------------------------

	function removeSelected(sel) {
	  grid.setSelectionProperty("values", new Array()); 
	    
          if (sel.length>0) {
	    var ldata = new Array(gdata.length-sel.length);
	    var gdlen = gdata.length;
	    var sllen = sel.length;
	    var count = 0;
	    var selected;
	    for (var r=0; r<gdlen; r++) {
	      selected=false;
	      for (var s=0; s<sllen && !selected; s++)
	        if (sel[s]==r) selected=true;
	          if (!selected)
	            ldata[count++] = gdata[r];
	    } // next (r)
            
            gdata = ldata;
            
            grid.setRowCount(gdata.length);
	    grid.setDataProperty("text", function(i,j){return gdata[i][j]});	  
            grid.setStyle("height",(18*gdata.length)+36); 
	    grid.refresh();
	  } // fi (sel.length>0)
	} // removeSelected

        // ----------------------------------------------------
	
	function deleteSingleMessage(num, id, guid) {
	  	  
	  if (window.confirm("Are you sure that you want to delete message?")) {

	    var frm = document.forms[0];
	    frm.guids.value = (guid==null ? "null" : guid);
	    frm.perform.value = "delete";
	    frm.target = "listhide";
	    frm.action="msg_delete_local.jsp";
	    frm.submit();  

	    // Remove message from grid
	    var ldata = new Array(gdata.length-1);
	    var gdlen = gdata.length;
	    var count = 0;
	    for (var r=0; r<gdlen; r++) {
	      if (gdata[r][5]!=id) ldata[count++] = gdata[r];
	    } // next (r)            
            gdata = ldata;            
            grid.setRowCount(gdata.length);
	    grid.setDataProperty("text", function(i,j){return gdata[i][j]});	  
            grid.setStyle("height",(18*gdata.length)+36); 
	    grid.refresh();
          } // fi (confirm)
	} // deleteSingleMessage()
	
        // ----------------------------------------------------
	
	function deleteMessages() {
	  	  
	  if (window.confirm("Are you sure that you want to delete messages:")) {

	    var frm = document.forms[0];
	    var uid = frm.guids;
	    var sel = grid.getSelectionProperty("values"); 
	       	 
	    uid.value = "";
	    for (var s=0; s< sel.length; s++) {	    
	      uid.value += (0==s ? "" : ",") + (gdata[sel[s]][7]==null ? "null" : gdata[sel[s]][7]);
	    }
	    frm.target = "listhide";
	    frm.action="msg_delete_local.jsp";
	    frm.submit();
	    removeSelected(sel);
          } // fi (confirm)
	} // deleteMessages()
	
        // ----------------------------------------------------

	function viewMessage(num,id) {
<%        if (oMacc.isNull(DB.incoming_server)) { %>
	    alert ("There is no incoming server configured for this account");
<%        } else { %>	    
	    open ("msg_view.jsp?gu_account=<%=oMacc.getString(DB.gu_account)%>&nm_folder=<%=nm_folder%>&id_msg="+escape(id)+"&nu_msg="+num, "editmail"+String(num));
<%        } %>	    	
	  return false;
	} // viewMessage

        // ----------------------------------------------------

	function replyMessage(gu,id) {
	  hideRightMenu();
	  open ("msg_new_f.jsp?action=reply&folder=inbox&gu_mimemsg="+gu+"&msgid="+escape(id));
	} // replyMessage

        // ----------------------------------------------------

	function forwardMessage(gu,id) {
	  hideRightMenu();
	  open ("msg_new_f.jsp?action=reply&folder=inbox&gu_mimemsg="+gu+"&msgid="+escape(id));
	} // forwardMessage

        // ----------------------------------------------------

	      function viewSource(guid) {
	  
<%        if (oMacc.isNull(DB.incoming_server)) { %>
	          alert ("There is no incoming server configured for this account");
<%        } else { %>	    
	          open ("msg_src.jsp?&gu_account=<%=oMacc.getString(DB.gu_account)%>&gu_folder=<%=gu_folder%>&gu_mimemsg="+guid, "viewmailsrc"+guid);
<%        } %>
	      return false;
	      } // viewSource

        // ----------------------------------------------------

	      function viewFollowUpStats(guid) {
	  			document.location = "msg_followup_stats.jsp?gu_mimemsg="+guid;
	  		  return true;
				} // viewFollowUpStats

        // ----------------------------------------------------

	function copyMessages(action) {
	  var frm = document.forms[0];

	  if (getCombo(frm.sel_target)=="") {
	    alert ("Select a target folder first");
	    return false;
	  }
	  	  
	  if (action=="move")
	    msg = "Are you sure that you want to move selected messages?";
	  else
	    msg = "Are you sure that you want to copy selected messages?";
	  
	  if (window.confirm(msg)) {

	    var ids = frm.ids;
	    var nms = frm.nums;
	    var sel = grid.getSelectionProperty("values"); 
	       	 
	    ids.value = "";
	    nms.value = "";
	    for (var s=0; s< sel.length; s++) {	 
	      ids.value += (0==s ? "" : ",") + gdata[sel[s]][5];
	      nms.value += (0==s ? "" : ",") + gdata[sel[s]][6];	      
	    }
	    
	    if (nms.value.length>0) {
	      frm.target = "listhide";
	      frm.destination.value=getCombo(frm.sel_target);
	      frm.perform.value = action;
	      frm.action="msg_move_exec.jsp";
	      frm.submit();  
	      if (action=="move") removeSelected(sel);
	    } // fi (sel.length>0)
          } // fi (confirm)
	  
	  return false;
	} // copyMessages

        // ----------------------------------------------------

        function selectAll() {          
          var frm = document.forms[0];
          
          for (var c=0; c<frm.elements.length; c++)
            if (frm.elements[c].type!="checkbox")
              frm.elements[c].click();
        } // selectAll()
      
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1"><%=sFolderLabel%></FONT></TD></TR></TABLE>
      <INPUT TYPE="hidden" NAME="screen_width" VALUE="<%=screen_width%>">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="gu_folder" VALUE="<%=gu_folder%>">
      <INPUT TYPE="hidden" NAME="folder" VALUE="<%=oFolder.getString(DB.nm_category)%>">   
      <INPUT TYPE="hidden" NAME="perform">
      <INPUT TYPE="hidden" NAME="destination">
      <INPUT TYPE="hidden" NAME="ids" VALUE="">    
      <INPUT TYPE="hidden" NAME="nums" VALUE="">
      <INPUT TYPE="hidden" NAME="guids">

      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD><TD ROWSPAN="5" WIDTH="120px"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="msg_new_f.jsp?folder=drafts" TARGET="_blank" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="deleteMessages()" CLASS="linkplain">Delete</A></TD>
<% if (!sOutBox.equals(gu_folder)) { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/hipermail/options.gif" WIDTH="16" HEIGHT="18" BORDER="0" ALT="Options"></TD>
        <TD VALIGN="middle"><A HREF="fldr_opts.jsp?gu_folder=<%=gu_folder%>&nm_folder=<%=Gadgets.URLEncode(oFolder.getString(DB.nm_category))%>" CLASS="linkplain">Options</A></TD>
<% } else { %>
        <TD COLSPAN="2"></TD>
<% } %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle"><A HREF="mailhome.jsp?screen_width=<%=iScreenWidth%>" CLASS="linkplain">Search</A></TD>
        <!--
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Messages&nbsp;</FONT>
        -->
        </TD>
      </TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/copyfiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Copy Messages"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="copyMessages('copy')" CLASS="linkplain">Copy</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/movefiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Move Messages"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="copyMessages('move')" CLASS="linkplain">Move</A></TD>
        <TD COLSPAN="4">
	  <SELECT NAME="sel_target" CLASS="combomini"><OPTION VALUE=""></OPTION><% out.write(oFoldersBuffer.toString());%></SELECT>
	</TD>
      </TR>
      <!--
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/findglass.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Find on this folder"></TD>
        <TD COLSPAN="7" VALIGN="middle">
          <INPUT TYPE="text" CLASS="combomini" NAME="tx_sought">
          &nbsp;&nbsp;<A HREF="#" onclick="findit(document.forms[0].tx_sought.value)" CLASS="linkplain">Find on this folder</A>
        </TD>
      </TR>
      -->
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD COLSPAN="9">
          <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0">
            <TR>
              <TD COLSPAN="3" WIDTH="310px"><IMG SRC="../images/images/spacer.gif" WIDTH="310" HEIGHT="1" BORDER="0" ALT=""></TD>
	      <TD ROWSPAN="2" NOWRAP><DIV ID="rcvng" STYLE="display:none"><FONT CLASS="textplain">Receiving messages</FONT>&nbsp;<IMG ID="rcimg" SRC="../images/images/spacer.gif" WIDTH="78" HEIGHT="7" BORDER="0" ALT="Receiving messages"></DIV></TD>
            </TR>
            <TR>
              <TD><DIV ID="prev" STYLE="display:none"><SPAN onmouseover="hideRightMenu()"><A HREF="#" CLASS="linkplain" onclick="skip=0;loadXMLData(0);">Start</A>&nbsp;&nbsp;&nbsp;<A HREF="#" CLASS="linkplain" onclick="loadXMLData(-<%=String.valueOf(iMaxRows)%>)">Previous&nbsp;<%=String.valueOf(iMaxRows)%></A></SPAN>&nbsp;&nbsp;&nbsp;</DIV></TD>
              <TD><DIV ID="next" STYLE="display:none"><SPAN onmouseover="hideRightMenu()"><A HREF="#" CLASS="linkplain" onclick="loadXMLData(<%=String.valueOf(iMaxRows)%>)">Next&nbsp;<%=String.valueOf(iMaxRows)%></A></SPAN></DIV></TD>
              <TD WIDTH="100%"></TD>
            </TR>
          </TABLE>
        </TD>
      </TR>
      </TABLE>
      <!-- End Top Menu -->
      <SCRIPT TYPE="text/javascript">
        <!--
	        grid.setRowCount(0);
          grid.setDataProperty("text", function(i,j){return gdata[i][j]});
          document.write(grid);
        //-->
      </SCRIPT>    
    </FORM>
    <SCRIPT TYPE="text/javascript">
      <!--
        addMenuOption("Open","viewMessage(jsMsgNum, jsMsgId, jsMsgGuid)",1);
        addMenuSeparator();
        addMenuOption("Reply","replyMessage(jsMsgGuid, jsMsgId)",0);
        addMenuOption("Forward","forwardMessage(jsMsgGuid, jsMsgId)",0);
        addMenuSeparator();
        addMenuOption("Delete","deleteSingleMessage(jsMsgNum, jsMsgId, jsMsgGuid)",0);
        addMenuSeparator();
        addMenuOption("View Source","viewSource(jsMsgGuid)",0);
<% if (gu_folder!=null) {
     if (gu_folder.equals(sSent)) { %>
        addMenuSeparator();
        addMenuOption("Followup","viewFollowUpStats(jsMsgGuid)",0);
<% } } %>
      //-->
    </SCRIPT>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>