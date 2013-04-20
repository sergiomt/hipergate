<%@ page import="java.util.Properties,java.math.BigDecimal,java.net.URLDecoder,java.io.File,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.debug.DebugFile,com.knowgate.hipergate.Category,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %><%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution
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
%><%!
  public static void paintFolders (JDCConnection oConn, String sParentGuid, String sLanguage, String sLevel, StringBuffer oOutBuffer)
    throws SQLException {
      String sLabel;
      DBSubset oSubfolders = new DBSubset (DB.k_categories + " c, " + DB.k_cat_tree + " t",
      				           DB.gu_category + "," + DB.nm_category,
      				           "c."+DB.gu_category+"=t."+DB.gu_child_cat + " AND t."+DB.gu_parent_cat+"=?", 10);
      int iSubfolders = oSubfolders.load(oConn, new Object[]{sParentGuid});
      
      for (int f=0; f<iSubfolders; f++) {
        PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.tr_category + " FROM " + DB.k_cat_labels + " WHERE " + DB.gu_category + "=? AND " + DB.id_language + "=?");
        oStmt.setString (1, oSubfolders.getString(0,f));
        oStmt.setString (2, sLanguage);
        ResultSet oRSet = oStmt.executeQuery();
        if (oRSet.next())
          sLabel = oRSet.getString(1);
        else
          sLabel = null;
        oRSet.close();
        if (null==sLabel) {
          oStmt.setString (2, "en");
          oRSet = oStmt.executeQuery();
          if (oRSet.next())
            sLabel = oRSet.getString(1);
          else
            sLabel = null;
          oRSet.close();
          if (null==sLabel) {
	    sLabel = oSubfolders.getString(1,f);
	  }
        }
        oStmt.close();
        
        if (!oSubfolders.getString(1,f).endsWith("_inbox") && !oSubfolders.getString(1,f).endsWith("_outbox"))
          oOutBuffer.append("<OPTION VALUE=\"" + oSubfolders.getString(0,f) + "\">" + sLevel + sLabel + "</OPTION>");
        
        paintFolders (oConn, oSubfolders.getString(0,f), sLanguage, sLevel+"&nbsp;&nbsp;&nbsp;&nbsp;", oOutBuffer);
      } // next
    }
%><%

  if (oMacc==null) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Account not found&desc=There is no mail account configured for current user&resume=../hipermail/account_list.jsp"));
    return;
  }
  if (oMacc.isNull(DB.gu_account)) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Account not found&desc=There is no mail account configured for current user&resume=../hipermail/account_list.jsp"));
    return;
  }

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("cache-control", "private");
  
  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");
  
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

  // **********************************************

  int iMailCount = 0;
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;
  
  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "50"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 50; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;
    
  if (iSkip<0) iSkip = 0;

  // **********************************************
  
  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "7 DESC";    
  if (sOrderBy.equals("7")) sOrderBy += " DESC";
  
  JDCConnection oConn = null;
  StringBuffer oFoldersBuffer = new StringBuffer();
  String sInboxGuid = null;
  String sReceivedGuid = null;
  String sSpamGuid = null;
  ACLUser oMe = new ACLUser();
  DBSubset oMsgs = new DBSubset (DB.k_mime_msgs, DB.gu_mimemsg+","+DB.id_message+","+DB.id_priority+","+DB.nm_from+","+DB.nm_to+","+DB.tx_subject+","+DB.dt_received+","+DB.dt_sent+","+DB.len_mimemsg+","+DB.pg_message,
      			         DB.gu_category+"=? AND "+DB.gu_workarea+"=? AND " + DB.bo_deleted + "<>1 AND " + DB.gu_parent_msg + " IS NULL ORDER BY " + sOrderBy, 100);
  int iMsgs = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("folder_listing");

    oMe.put(DB.gu_user, id_user);
    
    sInboxGuid = oMe.getMailFolder (oConn, "inbox");
    sReceivedGuid = oMe.getMailFolder (oConn, "received");
    sSpamGuid = oMe.getMailFolder (oConn, "spam");
    
    iMsgs = oMsgs.load(oConn, new Object[]{sInboxGuid,gu_workarea});

    paintFolders (oConn, oMe.getMailRoot(oConn), sLanguage, "", oFoldersBuffer);

    oConn.close("folder_listing");
  }
  catch (SQLException sqle) {
    if (null!=oConn)
       if (!oConn.isClosed())
         oConn.close("folder_listing");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getLocalizedMessage() + "&resume=../blank.htm"));
  }
  if (null==oConn) return;
  oConn=null;  

  sendUsageStats(request, "folder_listing"); 
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <LINK HREF="../javascript/activewidgets/styles/<%=sSkin%>/grid.css" REL="stylesheet" TYPE="text/css" ></LINK>
  <LINK HREF="../skins/<%=sSkin%>/mailgrid.css" REL="stylesheet" TYPE="text/css" ></LINK>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
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
      loadXMLData(false,false);
    }
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/activewidgets/lib/grid.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      var jsSkip = 0;
      var jsMaxRows = getCookie("maxrows");
      jsMaxRows = ((jsMaxRows==null || jsMaxRows=="") ? 100 : Number(jsMaxRows));
      
      // ***************************************************************
      // Global variables for moving the clicked row to the context menu
      var jsMsgId, jsMsgGuid, jsMsgNum, jsSpamCount, jsMsgCount, jsReceiptsCount;

      // **************************
      // ActiveWidgets grid loading

      var req;
      var acc;
      var cac;
      var scanning=false;
      var filterspam=false;
      var movereceipts=true;
      var gdata = new Array();
      var cols = ["", "From", "Subject", "Date", "Kb", "Id", "Num", "Guid"];
      var grid = new Active.Controls.Grid;

      grid.setColumnCount(8);
      grid.setColumnProperty("text", function(i){return cols[i]});
      grid.setSelectionProperty("multiple", true); 

      // *******************************************************************
      // XMLHttpRequest for adding cached messages from inbox asynchronously
      
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
	      
	      grid.setRowCount(irows);
              grid.setStyle("height",(18*irows)+36); 
              grid.refresh();
            }
            cac = false;
	  }
      } // processCacheScan

      // ****************************************************************
      // XMLHttpRequest for adding new messages from inbox asynchronously
      
      function processMailboxScan() {
          
          // **************************
          // only if req shows "loaded"
          if (req.readyState == 4) {

	    // turn off flag indicating scanning progress
	    scanning=false;

	    // ************
            // only if "OK"
            if (req.status == 200) {

    	      var id,num,subject,from,sent,kb,spam,content_type;
    	      var node;
    	      var emsg;

	      // *************************
	      // Get error message XML tag
    	      var errs = req.responseXML.getElementsByTagName("error");
	      if (errs) { if (errs[0].firstChild) emsg = errs[0].firstChild.nodeValue; else emsg = ""; }

	      // ***********************************************************
	      // If there is no error message then proceed to paint the grid
    	      if (emsg.length==0) {
    	      
    	        // *****************************************
    	        // Show previous and next links if neccesary
    	        var prev = getElementText(req.responseXML,"prev");
    	        var next = getElementText(req.responseXML,"next");
    	        
    if (null==prev) {
		  hideLayer("firstlink");
		  hideLayer("prevlink");
		} else {
		  showLayer("firstlink");
		  showLayer("prevlink");
		}
		        
    if (null==next) {
		  hideLayer("nextlink");
		  hideLayer("lastlink");
		} else {
		  showLayer("nextlink");
		  showLayer("lastlink");
		}

    	        // ******************
    	        // Show message count
    	        
						  jsMsgCount = Number(req.responseXML.getElementsByTagName("messages")[0].attributes.item(0).value);

    	        // ***********************
    	        // Get array os <msg> tags
    	        var msgs = req.responseXML.getElementsByTagName("msg");
    	        var imsg = msgs.length;
    	        var ids = document.forms[1].ids;
    	        var nms = document.forms[1].nums;    	        

		          // ****************************************************************************
		          // Inspect tag <spam> for each <msg>
		          // Messages marked as spam are not shown and automatically moved to spam folder
    	        // by a background process running on hidden frame listhide
    	        
    	        nms.value = ids.value = "";
    	        jsSpamCount = 0;
    	        if (filterspam) {
    	          for (var i = 0; i < imsg; i++) {
    	            spam = getElementText(msgs[i],"spam");
		              if (spam=="YES" || spam=="yes" || spam=="1" || spam=="true") {
		                ids.value += (jsSpamCount==0 ? "" : ",") + getElementText(msgs[i],"id");
		                nms.value += (jsSpamCount==0 ? "" : ",") + String(i+1);
		                jsSpamCount++;
		              } // fi		    
		            } // next
    	        } // fi (filterspam)

		          // ****************************************************************************
		          // Inspect tag <type> for each <msg>

							var rids = "";
							var rnms = "";
    	        jsReceiptsCount = 0;
							if (movereceipts) {
    	          for (var i = 0; i < imsg; i++) {
    	            content_type = getElementText(msgs[i],"type");
									if (content_type=="multipart/report") {
		                rids += (jsReceiptsCount==0 ? "" : ",") + getElementText(msgs[i],"id");
		                rnms += (jsReceiptsCount==0 ? "" : ",") + String(i+1);
									  jsReceiptsCount++;
									}
		            } // next
							}

    	        document.getElementById("msgcount").innerHTML = "<FONT CLASS=textplain>Total:&nbsp;"+String(jsMsgCount-jsSpamCount-jsReceiptsCount)+"</FONT>";

		          // *****************************************************************
		          // Display messages that are not spam nor read confirmation receipts
		
    	        gdata = new Array(imsg-jsSpamCount-jsReceiptsCount);    	      	      
    	        var r = 0;
    	        for (var i = 0; i < imsg ; i++) {
    	          spam = getElementText(msgs[i],"spam");
    	          content_type = getElementText(msgs[i],"type");
		            if ((!filterspam || (spam!="YES" && spam!="yes" && spam!="1" && spam!="true")) && content_type!="multipart/report") {
    	            id = getElementText(msgs[i],"id");
    	            num = getElementText(msgs[i],"num");
    	            from = "<SPAN onmouseover=\"hideRightMenu()\"><B>"+getElementText(msgs[i],"from")+"</B></SPAN>";    	        
    	            subject = "<A HREF=\"msg_view.jsp?gu_account=<%=oMacc.getString(DB.gu_account)%>&nm_folder=inbox&nu_msg="+num+"&id_msg="+escape(id)+"\" TARGET=\"editmail"+num+"\" onmouseover=\"jsMsgId='"+id+"';jsMsgNum="+num+";jsMsgGuid=null;showRightMenu(event)\"><B>"+getElementText(msgs[i], "subject")+"</B></A>";
		              sent = "<SPAN onmouseover=\"hideRightMenu()\"><B>"+getElementText(msgs[i],"sent")+"</B></SPAN>";
		              kb = Number(getElementText(msgs[i],"kb")); 
		              gdata[r] = new Array("",from,subject,sent,kb,id,num,null);
		              r++;
		            } // fi
    	        } // next
    	        		
                grid.setRowCount(gdata.length);
                grid.setStyle("height",(18*gdata.length)+36);

	        var rownums = new Array(gdata.length);
	        for (var o=0; o<gdata.length; o++) rownums[o] = String(jsSkip+o+1);
		      grid.setRowProperty("texts", rownums); 
	        grid.refresh();

		      // If there is spam then move it to unsolicited mail folder
		      if (filterspam && nms.value.length>0) {
		        document.forms[1].target="listhide";
		        document.forms[1].destination.value="spam";
	          document.forms[1].action="msg_move_exec.jsp";
		        document.forms[1].submit();
		      } // fi
		      
				  if (movereceipts && rnms.length>0) {
		        ids.value=rids;
		        nms.value=rnms;
		        document.forms[1].target="listhide";
		        document.forms[1].destination.value="receipts";
	          document.forms[1].action="msg_move_exec.jsp";
		        document.forms[1].submit();
    	    }
    	  
    	      } else {
                alert(emsg);
    	      }
    	      req = false;
            } else {
              alert("There was a problem retrieving the XML data:\n" + req.statusText);
            }            
	    document.getElementById("receivingtxt").style.visibility="hidden";
	    document.getElementById("receivingimg").src="../images/images/spacer.gif";
          }
      } // processMailboxScan


      // -----------------------------------------------------------------

      function processAccLoad() {
          if (acc.readyState == 4) {
            if (acc.status == 200) {
	      var gu,tl,em;
	      var acmb = document.forms[0].sel_account;
	      var guac = getCombo(acmb);
    	      var accs = acc.responseXML.getElementsByTagName("k_user_mail");
    	      for (var a = 0; a < accs.length; a++) {
    	        gu = getElementText(accs[a], "gu_account");
    	        tl = getElementText(accs[a], "tl_account");
    	        em = getElementText(accs[a], "tx_main_email");
		if (-1==comboIndexOf(acmb,gu))
		  comboPush (acmb, tl+" ("+em+")", gu, false, false);
	      } // next (a)
	      acc = false;
	      sortCombo(acmb);
	      setCombo (acmb,guac);
            }
	  }
      } // processAccLoad

      // -----------------------------------------------------------------
      
      function scanFolder(filter,update) {
	  if (!scanning) {
	    req = createXMLHttpRequest();
	    if (req) {
	      document.getElementById("receivingtxt").style.visibility="visible";
	      document.getElementById("receivingimg").src="../images/images/hipermail/loading.gif";
	      req.onreadystatechange = processMailboxScan;
	      scanning=true;
	      filterspam=filter;
	      req.open("GET", "folder_xmlfeed.jsp?gu_account=<%=oMacc.getString(DB.gu_account)%>&skip="+String(jsSkip)+"&bo_update="+(update ? "1" : "0"), true);
	      req.send(null);
	    }
	  } // fi (!scanning)
      } // scanFolder()

      // -----------------------------------------------------------------

      function loadXMLData(filter,update) {

      	  acc = createXMLHttpRequest();
	        if (acc) {
	          acc.onreadystatechange = processAccLoad;
	          acc.open("GET", "account_xmlfeed.jsp", true);
	          acc.send(null);
	        }

      	  scanFolder(filter,update);
      }
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
	function firstN() {
          gdata = new Array();
          grid.setRowCount(0);
	  grid.refresh();
	  jsSkip = 0;
	  scanFolder(true,false);
	}

        // ----------------------------------------------------

	function nextN() {
          gdata = new Array();
          grid.setRowCount(0);
	  grid.refresh();
	  jsSkip += jsMaxRows;
	  scanFolder(true,false);
	}

        // ----------------------------------------------------

	function prevN() {
          gdata = new Array();
          grid.setRowCount(0);
	  grid.refresh();
	  jsSkip -= jsMaxRows;
	  if (jsSkip<0) jsSkip=0;
	  scanFolder(true,false);
	}

        // ----------------------------------------------------

	function lastN() {
          gdata = new Array();
          grid.setRowCount(0);
	  grid.refresh();
	  jsSkip = jsMsgCount-jsMaxRows;
	  if (jsSkip<0) jsSkip=0;
	  scanFolder(true,false);
	}

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
            grid.setStyle("height",(18*gdata.length)+36); 
	    grid.refresh();
	  } // fi (sel.length>0)
	} // removeSelected

        // ----------------------------------------------------

	function removeSingleMessageFromGrid(id) {
	  var ldata = new Array(gdata.length-1);
	  var gdlen = gdata.length;
	  var count = 0;
	  for (var r=0; r<gdlen; r++) {
	    if (gdata[r][5]!=id) ldata[count++] = gdata[r];
	  } // next (r)            
          gdata = ldata;            
          grid.setRowCount(gdata.length);
          grid.setStyle("height",(18*gdata.length)+36); 
	  grid.refresh();
	}

        // ----------------------------------------------------
	
	function deleteSingleMessage(num, id, guid) {
	  hideRightMenu();

	  if (window.confirm("Are you sure that you want to delete message?")) {

	    var frm1 = document.forms[1];
	    frm1.ids.value = id;
	    frm1.nums.value = num;
	    frm1.guids.value = (guid==null ? "null" : guid);
	    frm1.perform.value = "delete";
	    frm1.action="msg_delete.jsp";
	    frm1.submit();  

	    removeSingleMessageFromGrid(id);
          } // fi (confirm)
	} // deleteSingleMessage()
	
        // ----------------------------------------------------
	
	function deleteMessages() {	  	  
	  hideRightMenu();
	  if (window.confirm("Are you sure that you want to delete messages:")) {
	    var frm1 = document.forms[1];
	    var ids = frm1.ids;
	    var nms = frm1.nums;
	    var uid = frm1.guids;
	    var sel = grid.getSelectionProperty("values"); 
	       	 
	    uid.value = nms.value = ids.value = "";
	    for (var s=0; s< sel.length; s++) {	    
	      ids.value += (0==s ? "" : ",") + gdata[sel[s]][5];
	      nms.value += (0==s ? "" : ",") + gdata[sel[s]][6];
	      uid.value += (0==s ? "" : ",") + (gdata[sel[s]][7]==null ? "null" : gdata[sel[s]][7]);
	    }
	    
	    frm1.perform.value = "delete";
	    frm1.action="msg_delete.jsp";
	    frm1.submit();
	    removeSelected(sel);
          } // fi (confirm)
	} // deleteMessages()
	
        // ----------------------------------------------------

	function viewMessage(num,id) {
	  hideRightMenu();
<%        if (oMacc.isNull(DB.incoming_server)) { %>
	    alert ("There is no incoming server configured for this account");
<%        } else { %>	    
	    open ("msg_view.jsp?gu_account=<%=oMacc.getString(DB.gu_account)%>&nm_folder=inbox&id_msg="+escape(id)+"&nu_msg="+num, "viewmail"+String(num));
<%        } %>	    	
	  return false;
	} // viewMessage

        // ----------------------------------------------------

	function viewSourceInbox(num) {
	  hideRightMenu();
<%        if (oMacc.isNull(DB.incoming_server)) { %>
	    alert ("There is no incoming server configured for this account");
<%        } else { %>   
	    if (null==jsMsgGuid)
	      open ("msg_src_inbox.jsp?&gu_account=<%=oMacc.getString(DB.gu_account)%>&nu_msg=" + String(num), "viewmailsrc"+String(num));
	    else
	      open ("msg_src.jsp?&gu_account=<%=oMacc.getString(DB.gu_account)%>&gu_folder=inbox&gu_mimemsg=" + jsMsgGuid, "viewmailsrc"+String(num));
<%        } %>
	  return false;
	} // viewSourceInbox

        // ----------------------------------------------------

	function copyMessages(action) {
	  hideRightMenu();
	  var frm0 = document.forms[0];
	  var frm1 = document.forms[1];

	  if (getCombo(frm0.sel_target)=="") {
	    alert ("Select a target folder first");
	    return false;
	  }
	  	  
	  if (action=="move")
	    msg = "Are you sure that you want to move selected messages?";
	  else
	    msg = "Are you sure that you want to copy selected messages?";
	  
	  if (window.confirm(msg)) {

	    var ids = frm1.ids;
	    var nms = frm1.nums;
	    var sel = grid.getSelectionProperty("values"); 
	       	 
	    nms.value = ids.value = "";
	    for (var s=0; s< sel.length; s++) {	 
	      ids.value += (0==s ? "" : ",") + gdata[sel[s]][5];
	      nms.value += (0==s ? "" : ",") + gdata[sel[s]][6];	      
	    }
	    
	    if (nms.value.length>0) {
	      frm1.destination.value=getCombo(frm0.sel_target);
	      frm1.perform.value = action;
	      frm1.action="msg_move_exec.jsp";
	      frm1.submit();
	    }	    
	    if (action=="move") removeSelected(sel);
          } // fi (confirm)
	  
	  return false;
	} // copyMessages

        // ----------------------------------------------------

	function moveMessagesToReceived(num, id, guid) {
	  hideRightMenu();
	  removeSingleMessageFromGrid(id);
	  var frm1 = document.forms[1];
	  frm1.ids.value = id;
	  frm1.nums.value=num;
	  frm1.guids.value=guid;
	  frm1.destination.value = "<%=sReceivedGuid%>";
	  frm1.perform.value = "move";
	  frm1.action="msg_move_exec.jsp";
	  frm1.submit();
	}

        // ----------------------------------------------------

	function forwardToList(num, id, guid) {
	  document.location = "msg_forward.jsp?num"+String(num)+"&id="+id+"&guid="+guid;
  }

        // ----------------------------------------------------

	function moveMessagesToSpam(num, id, guid) {
	  hideRightMenu();
	  removeSingleMessageFromGrid(id);
	  var frm1 = document.forms[1];
	  frm1.ids.value = id;
	  frm1.nums.value=num;
	  frm1.guids.value=guid;
	  frm1.destination.value = "<%=sSpamGuid%>";
	  frm1.perform.value = "move";
	  frm1.action="msg_move_exec.jsp";
	  frm1.submit();
	}

      // ------------------------------------------------------	
    
      function filterSpam() {
	      var threshold = 0.99;
	      if (!scanning) {
	        document.getElementById("receivingimg").src="../images/images/hipermail/loading.gif";
	        for (var m=gdata.length-1; m<=0; m--) {
	          var spm = httpRequestText("msg_spam_score.jsp?nu_msg="+gdata[m][6]+"&id_msg="+escape(gdata[m][5])+"&pct_threshold="+String(threshold)).split("\n");
					  if (spm[0]=="completed") {
					    if (Number(spm[1])>=threshold) {
					      moveMessagesToSpam(gdata[m][6],gdata[m][5], null);
					    } // fi
					  } else {
					    alert (spm);
					  }
	        } // next
	        document.getElementById("receivingimg").src="../images/images/spacer.gif";    
	      } // fi (!scanning)
      } // filterSpam

      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <TITLE><%=oMacc.getString(DB.incoming_account)%> :: Inbox</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
    <FORM METHOD="post" ACTION="msg_delete.jsp">
      <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1">Inbox</FONT></TD></TR></TABLE>  
      <TABLE BORDER="0">
        <TR>
          <TD><FONT CLASS="textsmall"><B>Account</B></FONT></TD>
          <TD><SELECT NAME="sel_account" CLASS="combomini" onchange="document.location.href='folder_listing.jsp?gu_account='+this.options[this.selectedIndex].value+'&screen_width='+String(screen.width)"><OPTION VALUE="<%=oMacc.getString(DB.gu_account)%>" SELECTED><%=oMacc.getString(DB.tl_account)%> (<%=oMacc.getString(DB.tx_main_email)%>) *</OPTION></SELECT></TD>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/hipermail/options.gif" WIDTH="16" HEIGHT="18" BORDER="0" HSPACE="4" ALT="Options"></TD>
          <TD VALIGN="middle"><A HREF="fldr_opts.jsp?gu_folder=<%=sInboxGuid%>&nm_folder=<%=Gadgets.URLEncode("Inbox")%>" onmouseover="hideRightMenu()" CLASS="linkplain">Options</A></TD>
        </TR>
      </TABLE>
      <INPUT TYPE="hidden" NAME="gu_account" VALUE="<%=oMacc.getString(DB.gu_account)%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">
      <INPUT TYPE="hidden" NAME="folder" VALUE="inbox">
      <INPUT TYPE="hidden" NAME="perform">
      <INPUT TYPE="hidden" NAME="destination">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <INPUT TYPE="hidden" NAME="screen_width">

      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="10" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="msg_new_f.jsp?folder=drafts" TARGET="_blank" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/hipermail/deletemsgs.gif" WIDTH="23" HEIGHT="17" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="#" onclick="deleteMessages()" onmouseover="hideRightMenu()" CLASS="linkplain">Delete</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/hipermail/refresh.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Refresh"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="loadXMLData(true,true)" onmouseover="hideRightMenu()" CLASS="linkplain">Refresh</A></TD>
        <TD VALIGN="middle"></TD>
        <TD VALIGN="bottom"></TD>
        <TD VALIGN="bottom"></TD>
        <TD><DIV ID="receivingtxt" STYLE="visibility:hidden"><FONT CLASS="textplain">Receiving messages</FONT></DIV></TD>
      </TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/copyfiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Copy Messages"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="copyMessages('copy')" onmouseover="hideRightMenu()" CLASS="linkplain">Copy</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/movefiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Move Messages"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="copyMessages('move')" onmouseover="hideRightMenu()" CLASS="linkplain">Move</A></TD>
        <TD COLSPAN="5">
	        <SELECT NAME="sel_target" onclick="hideRightMenu()" CLASS="combomini"><OPTION VALUE=""></OPTION><% out.write(oFoldersBuffer.toString());%></SELECT>
	      </TD>
        <TD><IMG ID="receivingimg" SRC="../images/images/spacer.gif" WIDTH="78" HEIGHT="7" BORDER="0" ALT="Receiving messages"></TD>
      </TR>
<% try { Class.forName("org.jasen.core.engine.Jasen"); %>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/hipermail/filterspam.gif" WIDTH="25" HEIGHT="16" BORDER="0" ALT="Spam filter"></TD>
        <TD VALIGN="middle" COLSPAN="8"><A HREF="#" onclick="filterSpam()" onmouseover="hideRightMenu()" CLASS="linkplain">Run spam filter</A></TD>
        <TD></TD>
      </TR>
<% } catch (Exception JasenSpamFilterNotInstalled) { } %>      
      <TR><TD COLSPAN="10" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD COLSPAN="2">
          <A ID="firstlink" HREF="#" CLASS="linkplain" STYLE="visibility:hidden" onclick="firstN()" onmouseover="hideRightMenu()">Start</A>
        </TD>
        <TD COLSPAN="2">
          <A ID="prevlink" HREF="#" CLASS="linkplain" STYLE="visibility:hidden" onclick="prevN()" onmouseover="hideRightMenu()">Previous</A>
        </TD>
        <TD COLSPAN="2">
          <A ID="nextlink" HREF="#" CLASS="linkplain" STYLE="visibility:hidden" onclick="nextN()" onmouseover="hideRightMenu()">Next</A>
        </TD>
        <TD COLSPAN="2">
          <A ID="lastlink" HREF="#" CLASS="linkplain" STYLE="visibility:hidden" onclick="lastN()" onmouseover="hideRightMenu()">Last</A>
        </TD>
        <TD COLSPAN="2">
	      <DIV ID="msgcount"></DIV>
        </TD>
      </TR>
    </TABLE>
    <!-- End Top Menu -->
    <SCRIPT TYPE="text/javascript">
      <!--
	      grid.setRowCount(0);
        grid.setDataProperty("text", function(i,j){ if (gdata instanceof Array) {
        																							if (gdata.length==0) {
        	                                              return "*Data array has zero length!";
        	                                            } else {
        	                                            	if (i<gdata.length)
        	                                            	  if (gdata[i] instanceof Array)
        	                                            	    if (j<gdata[i].length)
        	                                                    return gdata[i][j];
        	                                                  else
        	                                            	      return "*Subscript ["+String(i)+"]["+String(j)+"] out of range for array of size ["+String(gdata.length)+"]["+String(gdata[i].length)+"]!";
        	                                                else
        	                                                	return "*Subscript "+String(i)+" does not contain an array of data!";
        	                                              else
        	                                            	  return "*Subscript ["+String(i)+"] out of range for array of size ["+String(gdata.length)+"]!";
        	                                                
        	                                            }
        	                                          } else {
        	                                            return "*Data array is empty!";
        	                                          }
        	                                        } );        
        document.write(grid);
      //-->
    </SCRIPT>    
  </FORM>
  <FORM METHOD="post" target="listhide">
    <INPUT TYPE="hidden" NAME="folder" VALUE="inbox">
    <INPUT TYPE="hidden" NAME="destination" VALUE="">
    <INPUT TYPE="hidden" NAME="perform" VALUE="">
    <INPUT TYPE="hidden" NAME="ids" VALUE="">    
    <INPUT TYPE="hidden" NAME="nums" VALUE="">
    <INPUT TYPE="hidden" NAME="guids" VALUE="">    
    <INPUT TYPE="hidden" NAME="screen_width">
  </FORM>
  <SCRIPT TYPE="text/javascript">
    <!--
      addMenuOption("Open","viewMessage(jsMsgNum, jsMsgId)",1);
      addMenuOption("Move to received","moveMessagesToReceived(jsMsgNum, jsMsgId, jsMsgGuid)",0);
      addMenuSeparator();
      addMenuOption("Delete","deleteSingleMessage(jsMsgNum, jsMsgId, jsMsgGuid)",0);
      addMenuOption("Move to Spam","moveMessagesToSpam(jsMsgNum, jsMsgId, jsMsgGuid)",0);
      // addMenuOption("Re-send to a list","forwardToList(jsMsgNum, jsMsgId, jsMsgGuid)",0);
      addMenuSeparator();
      addMenuOption("View Source","viewSourceInbox(jsMsgNum,jsMsgId)",0);
    //-->
  </SCRIPT>

</BODY>
</HTML>
<%
  
  // *********************************************************************

  // If there are no messages on the POP3 inbox then clear the local cache
  
  if (0==iMsgs) {
    try {
      oConn = GlobalDBBind.getConnection("msg_clear_cache");

      Category oCatInbox = new Category(oConn, sInboxGuid);
      
      DBSubset oInboxCache = new DBSubset (DB.k_mime_msgs, DB.gu_mimemsg,
      				           DB.gu_category+"='"+sInboxGuid+"' AND "+DB.gu_parent_msg+" IS NULL", 100);
      int iInboxCache = oInboxCache.load(oConn);

      oConn.setAutoCommit(false);
      
      for (int d=0; d<iInboxCache; d++) {
        DBMimeMessage.delete(oConn, sInboxGuid, oInboxCache.getString(0, d));
      }

      String sFsp = System.getProperty("file.separator");
      
      File oMbox = new File(Gadgets.chomp(sMBoxDir, sFsp)+oCatInbox.getString(DB.nm_category)+".mbox");
      
      if (oMbox.exists()) oMbox.delete();
      oConn.commit();
      oConn.close("msg_clear_cache");    
    }
    catch (Exception e) {
      if (null!=oConn)
         if (!oConn.isClosed()) {
           if (!oConn.getAutoCommit()) oConn.rollback();
           oConn.close("msg_clear_cache");
         }
      oConn = null;    
      out.write(e.getClass().getName() + " " + e.getMessage());   
    }  
  } // fi (iMsgs)

%>
<%@ include file="../methods/page_epilog.jspf" %>