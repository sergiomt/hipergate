<%@ page import="java.util.Date,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/customattrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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
   
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final int Marketing = 18;
  final int CollabTools = 17;
  final int Hipermail = 21;
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = getCookie(request,"workarea",null);
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
    
  String gu_oportunity = nullif(request.getParameter("gu_oportunity"));
  String gu_contact = nullif(request.getParameter("gu_contact"));
  String gu_company = nullif(request.getParameter("gu_company"));
  String gu_list = nullif(request.getParameter("gu_list"));
  String de_list = request.getParameter("de_list");
  
  com.knowgate.crm.Oportunity oOprt = new com.knowgate.crm.Oportunity();
  com.knowgate.crm.Contact oCont = new com.knowgate.crm.Contact();
  com.knowgate.crm.Company oComp = new com.knowgate.crm.Company();
  
  ACLUser oUser = null;
    
  StringBuffer sSalesMen = null;
  String sStatusLookUp = "";
  String sOriginLookUp = "";
  String sObjectiveLookUp = "";
  String sCauseLookUp = "";
  String sCampaigns = "";
  String sPrivate = "";
  String sDtCreated = "";
  String sDtModified = "";
  String sTxEMails = "";
  /*Inicio 2009-12-15*/
  String tx_nickname ="";
  /* Fin I2E*/
  int iNuEMails = 0;
 
  String sToday = DBBind.escape(new java.util.Date(), "shortDate").trim();
 
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");  
  JDCConnection oConn = GlobalDBBind.getConnection("oportunity_edit");    
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;
  boolean bLoaded = false;
  boolean bIsGuest = true;
  boolean bAllCaps = false;
  boolean bHasMailAccount = false;
  boolean bUseSecondaryContacts = (gu_list.length()==0 && gu_oportunity.length()>0);
  int nSecondaryContacts = 0;
  
  try {    
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    bAllCaps = WorkArea.allCaps(oConn, gu_workarea);
    
    if (gu_oportunity.length()>0) {
      Object aOprt[] = { gu_oportunity };
      bLoaded = oOprt.load(oConn, aOprt);
      sPrivate = oOprt.getShort(DB.bo_private)!=(short)0 ? "CHECKED" : "";
      if (bLoaded) {
        oStmt = oConn.prepareStatement("SELECT " +  DB.dt_created + "," + DB.dt_modified + " FROM " + DB.k_oportunities + " WHERE " + DB.gu_oportunity + "=?");
        oStmt.setString(1, gu_oportunity);
        oRSet = oStmt.executeQuery();
        oRSet.next();
        sDtCreated = oSimpleDate.format(oRSet.getDate(1));
        if (null!=oRSet.getObject(2))
          sDtModified = oSimpleDate.format(oRSet.getDate(2));
        oRSet.close();
        oRSet = null;
        oStmt.close();
        oStmt = null;
      
        DBSubset oEMails = new DBSubset (DB.k_member_address, DB.tx_email, 
        																 DB.gu_workarea+"=? AND "+DB.tx_email+" IS NOT NULL AND ("+DB.gu_contact+"=? OR "+DB.gu_company+"=?)", 10);

        iNuEMails = oEMails.load(oConn, new Object[]{gu_workarea,gu_contact,gu_company});
        for (int e=0; e<iNuEMails; e++) sTxEMails += "<OPTION VALUE=\""+oEMails.getString(0,e)+"\" "+(e==0 ? "SELECTED" : "")+">"+oEMails.getString(0,e)+"</OPTION>";
        
        if (bUseSecondaryContacts) nSecondaryContacts = oOprt.countSecondaryContacts(oConn);
      } // fi (bLoaded)
      
      bHasMailAccount = DBCommand.queryExists(oConn, DB.k_user_mail, DB.gu_user+"='"+id_user+"'");
    }

    if (gu_contact.length()>0) {
      Object aCont[] = { gu_contact };
      oCont.load(oConn, aCont);
    }

    if (gu_company.length()>0) {
      Object aComp[] = { gu_company };
      oComp.load(oConn, aComp);
    }

    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_oportunities_lookup, gu_workarea, DB.id_status, sLanguage);
    sOriginLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_oportunities_lookup, gu_workarea, DB.tp_origin, sLanguage);
    sCauseLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_oportunities_lookup, gu_workarea, DB.tx_cause, sLanguage);

    %><%@ include file="oportunity_listbox.jspf" %><%
    
		DBSubset oSalesMen = new DBSubset (DB.k_sales_men+" m,"+DB.k_users+" u",
		                                   "m."+DB.gu_sales_man+",u."+DB.nm_user+",u."+DB.tx_surname1+",u."+DB.tx_surname2,
		                                   "m."+DB.gu_sales_man+"=u."+DB.gu_user+" AND m."+DB.gu_workarea+"=? ORDER BY 2,3,4", 100);
    int iSalesMen = oSalesMen.load(oConn, new Object[]{gu_workarea});
    sSalesMen = new StringBuffer(200+iSalesMen*200);
    for (int s=0; s<iSalesMen; s++) {
      sSalesMen.append("<OPTION VALUE=\"");
      sSalesMen.append(oSalesMen.getString(0,s));
      sSalesMen.append("\">");
      sSalesMen.append(oSalesMen.getStringNull(1,s,"")+" "+oSalesMen.getStringNull(2,s,"")+" "+oSalesMen.getStringNull(3,s,""));
      sSalesMen.append("</OPTION>");
    }

	  DBSubset oCampaigns = new DBSubset (DB.k_campaigns, DB.gu_campaign+","+DB.nm_campaign, DB.bo_active+"<>0 AND "+DB.gu_workarea+"=? ORDER BY 2", 10);
	  int iCampaigns = oCampaigns.load(oConn, new Object[]{gu_workarea});
	  for (int c=0; c<iCampaigns; c++) sCampaigns += "<OPTION VALUE=\""+oCampaigns.getString(DB.gu_campaign,c)+"\">"+oCampaigns.getString(DB.nm_campaign,c)+"</OPTION>";
	  
    oConn.setAutoCommit (true);

    com.knowgate.http.portlets.HipergatePortletConfig.touch(oConn, id_user, "com.knowgate.http.portlets.OportunitiesTab", gu_workarea);
    
    /* Inicio I2E 2009-12-15*/
    String gu_writer = null;
    try{
    	gu_writer=oOprt.getString(DB.gu_writer);
    }catch(Exception e){}
    
   	if (gu_writer!=null){
	    oStmt = oConn.prepareStatement("SELECT " +  DB.tx_nickname + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?");
	    oStmt.setString(1, gu_writer);
	    oRSet = oStmt.executeQuery();
	    oRSet.next();
	    tx_nickname = oRSet.getString(1);
	    oRSet.close();
	    oRSet = null;
	    oStmt.close();
	    oStmt = null;
   	}
    /* Fin I2E*/

    sendUsageStats(request, "oportunity_edit"); 
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (null!=oRSet) oRSet.close();
        if (null!=oStmt) oStmt.close();
        oConn.close("oportunity_edit");
      }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
    oConn = null;
    return;
  }       
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//en">
<HTML LANG="<%=sLanguage.toUpperCase()%>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>    
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>      
  <TITLE>hipergate :: Edit Opportunity</TITLE>
    <SCRIPT TYPE="text/javascript">
      <!--        

      var allcaps = <%=String.valueOf(bAllCaps)%>;
      
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("oportunity_lookups.jsp", "lookupobjective", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=yes,width=960,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_oportunities_lookup&id_language=" + getUserLanguage() + "&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "lookupstatus", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_oportunities_lookup&id_language=" + getUserLanguage() + "&id_section=tx_cause&tp_control=2&nm_control=sel_cause&nm_coding=tx_cause", "lookupcause", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
            window.open("../common/lookup_f.jsp?nm_table=k_oportunities_lookup&id_language=" + getUserLanguage() + "&id_section=tp_origin&tp_control=2&nm_control=sel_origin&nm_coding=tp_origin", "lookuporigin", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()


      // ------------------------------------------------------

      function createVisit() {
        if (document.forms[0].sel_salesmen.options.selectedIndex>0) {
          window.open("../addrbook/visit_edit_f.htm?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCombo(document.forms[0].sel_salesmen) + "&date=<%=sToday%>&gu_sales_man=" + getCombo(document.forms[0].sel_salesmen) + (document.forms[0].gu_contact.length==0 ? "" : "&gu_contact="+document.forms[0].gu_contact.value), "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
        } else {
          window.open("../addrbook/meeting_edit_f.htm?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=<%=id_user%>&date=<%=sToday%>" + (document.forms[0].gu_contact.length==0 ? "" : "&gu_contact="+document.forms[0].gu_contact.value), "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
        }
      } // createVisit
            
      // ------------------------------------------------------

      function sendEMail() {
        var frm = document.forms[0];
<% if (bHasMailAccount) { %>
	      var w = open("../hipermail/msg_new_f.jsp?folder=drafts"+(frm.gu_contact.value.length>0 ? "&gu_contact="+frm.gu_contact.value : "")+"&to="+getCombo(frm.sel_email));
        w.focus();
<% } else { %>
        alert ("An e-mail account must be previously configured before sending a proposal");
<% } %>
	      return false;
      }

      // ------------------------------------------------------
      
      var dt_created = "<%=sDtCreated%>";
      var dt_modified = "<%=sDtModified%>";
      var dt_next;
            
      function validate() {
        var frm = window.document.forms[0];
	      var txt;
      	var dtc;
      	var dtn;
      	var dtm;
      
      	txt = frm.tl_oportunity.value = ltrim(frm.tl_oportunity.value);
      	if (txt.length==0)
      		frm.tl_oportunity.value=getComboText(document.forms[0].sel_objetive);
      	if (allcaps) frm.tl_oportunity.value=frm.tl_oportunity.value.toUpperCase();
      	
      	if (frm.tl_oportunity.value.length==0) {
      	  alert ("Opportunity title is mandtory");
      	  return false;	  
      	}
      
      	if (hasForbiddenChars(txt)) {
      	  alert ("Opportunity title contains invalid characters");
      	  return false;	  
      	}
      	
      	frm.id_objetive.value = getCombo(frm.sel_objetive);      	
      	frm.id_status.value = getCombo(frm.sel_status);
      	frm.tx_cause.value = getCombo(frm.sel_cause);
      	frm.tp_origin.value = getCombo(frm.sel_origin);
      	
      	txt = frm.im_revenue.value;
      	for (var c=0; c<txt.length; c++)
      	  if (txt.charCodeAt(c)<48 || txt.charCodeAt(c)>57) {
      	    alert ("Amount must be an integer quantity");
      	    return false;
      	  }
      
      	dt_next = frm.dt_next_action.value;
      
              if (!isDate(dt_next, "d") && dt_next.length>0) {
      	  alert ("Next action date is not valid");
      	  return false;
      	}
      
      	if (dt_created.length>0 && dt_next.length>0) {
      	  dtc = dt_created.split("-");	  
      	  dtc = new Date(parseFloat(dtc[0]), parseFloat(dtc[1])-1, parseFloat(dtc[2]));
      	  dtn = dt_next.split("-");
      	  dtn = new Date(parseFloat(dtn[0]), parseFloat(dtn[1])-1, parseFloat(dtn[2]));
      	  
      	  if (dtn<dtc) {
      	    alert ("Next action date may not be before opportunity creation date" + dt_created);
      	    return false;	  
      	  }
      	}
      	
      	if (dt_modified.length>0 && dt_next.length>0) {
      	  dtm = dt_modified.split("-");	  
      	  dtm = new Date(parseFloat(dtm[0]), parseFloat(dtm[1])-1, parseFloat(dtm[2]));
      	  dtn = dt_next.split("-");
      	  dtn = new Date(parseFloat(dtn[0]), parseFloat(dtn[1])-1, parseFloat(dtn[2]));
      	  
      	  if (dtn<dtm) {
      	    alert ("Next action date may not be before opportunity last modification date" + dt_modified);
      	    return false;	  
      	  }
      	}
      
      	if (frm.tx_note.value.length>1000) {
      	  alert ("Comments may not be longer than 1000 characters");
      	  return false;
      	}
      
      	frm.bo_private.value = frm.chk_private.checked ? "1" : "0";

        return true;
      } // validate()

      // ------------------------------------------------------

      function viewNotes() {
        var frm = document.forms["fixedAttrs"];        
        document.location.href = "note_listing.jsp?gu_contact=" + frm.gu_contact.value + "&nm_company=";        
        return true;
      }

      // ------------------------------------------------------

      function viewAttachments() {
        var frm = document.forms["fixedAttrs"];
        document.location.href = "attach_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + frm.gu_contact.value;
        return true;
      }

      // ------------------------------------------------------

      function setCombos() {
        var frm = window.document.forms[0];

<% if (!oOprt.isNull(DB.lv_interest)) { %>
        setCheckedValue(frm.lv_interest, <%=String.valueOf(oOprt.getShort(DB.lv_interest))%>);
<% } %>
	      setCombo(frm.sel_objetive,"<%=oOprt.getStringNull(DB.id_objetive,"")%>");
	      setCombo(frm.sel_status,"<%=oOprt.getStringNull(DB.id_status,"")%>");
	      setCombo(frm.sel_cause,"<%=oOprt.getStringNull(DB.tx_cause,"")%>");
	      setCombo(frm.sel_origin,"<%=oOprt.getStringNull(DB.tp_origin,"")%>");	      
<% if ((iAppMask & (1<<Marketing))!=0) { %>
	      setCombo(frm.gu_campaign,"<%=oOprt.getStringNull(DB.gu_campaign,"")%>");
<% } %>
      } // setCombos() 

      // ------------------------------------------------------

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      //-->
    </SCRIPT>
    <!--
    tabbed panel by Jamie Jaworski taken from builder.com
    http://builder.cnet.com/webbuilding/0-7701-8-5056260-1.html?tag=st.bl.3882.dir1.7701-8-5056260-1
    -->    
    <SCRIPT TYPE="text/javascript">
      <!--
        function selectTab(n) {
        	
        	var panelID = "p1";
        	var numDiv = 2;
        	// iterate all tab-panel pairs
        	for(var i=0; i < numDiv; i++) {
        		var panelDiv = window.document.getElementById(panelID+"panel"+i);
        		var tabDiv = document.getElementById(panelID+"tab"+i);
        		z = panelDiv.style.zIndex;
        		// if this is the one clicked and it isn't in front, move it to the front
        		if (z != numDiv && i == n) { z = numDiv; }
        		// in all other cases move it to the original position
        		else { z = (numDiv-i); }
        		panelDiv.style.zIndex = z;
        		tabDiv.style.zIndex = z;
        	}
        	if(n==1){
        	 document.fixedAttrs.sel_objetive.style.visibility = "hidden";
        	 document.fixedAttrs.sel_status.style.visibility= "hidden";
        	 document.fixedAttrs.sel_cause.style.visibility = "hidden";
        	 document.fixedAttrs.sel_origin.style.visibility= "hidden";
        	 document.fixedAttrs.sel_delcustomfield.style.visibility= "visible";        	 
        	}
        	if(n==0){
        	document.fixedAttrs.sel_objetive.style.visibility="visible";
        	document.fixedAttrs.sel_status.style.visibility="visible";
        	document.fixedAttrs.sel_cause.style.visibility="visible";
        	document.fixedAttrs.sel_origin.style.visibility="visible";
        	 document.fixedAttrs.sel_delcustomfield.style.visibility= "hidden";        	 
        	}
        	
        }
      //-->
    </SCRIPT>
    <STYLE TYPE="text/css">
      <!--
      .tab {
      font-family: sans-serif; font-size: 12px; line-height:150%; font-weight: bold; position:absolute; text-align: center; border: 2px; border-color:#999999; border-style: outset; border-bottom-style: none; width:180px; margin:0px;
      }

      .panel {
      font-family: sans-serif; font-size: 12px; position:absolute; border: 2px; border-color:#999999; border-style:outset; width:600px; height:500px; left:0px; top:24px; margin:0px; padding:6px;
      }
      -->
    </STYLE>                
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
<FORM NAME="fixedAttrs" METHOD="post" ACTION="oportunity_edit_store.jsp" onSubmit="return validate()">
  <DIV class="cxMnu1" style="width:300px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
      <TABLE BORDER="0">
        <TR HEIGHT="18">
<% if (gu_contact.length()>0) { %>
        	  <TD><IMG SRC="../images/images/note16x16.gif" HEIGHT="18" WIDTH="15" BORDER="0" ALT="View Notes"></TD>
        	  <TD><A HREF="#" CLASS="linkplain" onclick="viewNotes()">View Notes</A></TD>
        	  <TD WIDTH="8"></TD>
<% } %>
<% if (gu_oportunity.length()>0 && (iAppMask & (1<<CollabTools))!=0) { %>
        	  <TD><IMG SRC="../images/images/crm/newmeeting18.gif" HEIGHT="18" WIDTH="18" BORDER="0" ALT="New Visit"></TD>
        	  <TD><A HREF="#" CLASS="linkplain" onclick="createVisit()">Organize Visit</A></TD>
        	  <TD COLSPAN="2"><SELECT CLASS="combomini" NAME="sel_salesmen"><OPTION VALUE="" SELECTED="selected">For myself</OPTION><OPTGROUP LABEL="For another salesman"><%=sSalesMen%></OPTGROUP></SELECT></TD>
<% } %>
        </TR>
        <TR>
<% if (gu_contact.length()>0) { %>
        	  <TD><IMG SRC="../images/images/attachedfile16x16.gif" HEIGHT="17" WIDTH="21" BORDER="0" ALT="View Files"></TD>
        	  <TD><A HREF="#" CLASS="linkplain" onclick="viewAttachments()">View files</A></TD>
        	  <TD WIDTH="8"></TD>
<% } %>
<% if (gu_oportunity.length()>0 && (iAppMask & (1<<Hipermail))!=0) { %>
        	  <TD><IMG SRC="../images/images/sendmail16.gif" HEIGHT="18" WIDTH="18" BORDER="0" ALT="New e-mail"></TD>
        	  <TD><A HREF="#" CLASS="linkplain" onclick="sendEMail()">Send Proposal</A></TD>
        	  <TD COLSPAN="2"><SELECT CLASS="combomini" NAME="sel_email"><OPTION VALUE=""><%=sTxEMails%></SELECT></TD>
<% } %>
        </TR>
<% if (gu_oportunity.length()>0 && gu_contact.length()>0) { %>
        <TR HEIGHT="18">
        	  <TD><IMG SRC="../images/images/addrbook/telephone16.gif" HEIGHT="16" WIDTH="16" BORDER="0" ALT="View Calls"></TD>
        	  <TD><A HREF="phonecall_listing.jsp?id_domain=<%=id_domain%>&n_domain=<%=Gadgets.URLEncode(n_domain)%>&gu_workarea=<%=gu_workarea%>&gu_contact=<%=gu_contact%>&gu_oportunity=<%=gu_oportunity%>" CLASS="linkplain">View calls</A></TD>
        	  <TD WIDTH="8"></TD>
        	  <TD><% if (nSecondaryContacts>0) out.write("<IMG SRC=\"../images/images/contactos.gif\" WIDTH=\"20\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"List Other Contacts\">"); %></TD>
        	  <TD><% if (nSecondaryContacts>0) out.write("<A CLASS=\"linksmall\" HREF=\"oportunity_sec_list.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_oportunity="+gu_oportunity+"\">"+Gadgets.replace("List another NNN contacts", "NNN", String.valueOf(nSecondaryContacts))+"</A>");  %></TD>
        	  <TD><% if (bUseSecondaryContacts) out.write("<IMG SRC=\"../images/images/contactos_add.gif\" WIDTH=\"20\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Add Contact\">"); %></TD>
						<TD><% if (bUseSecondaryContacts) out.write("<A CLASS=\"linksmall\" HREF=\"oportunity_sec_edit.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_oportunity="+gu_oportunity+"\">Add another contact</A>"); %></TD>
        </TR>
<% } %>
	    <!--
	      <TR HEIGHT="18">
        	  <TD><IMG SRC="../images/images/training/diploma16.gif" HEIGHT="16" WIDTH="16" BORDER="0" ALT="View Admission"></TD>
        	  <TD><A HREF="admission_edit.jsp?id_domain=<%=id_domain%>&n_domain=<%=Gadgets.URLEncode(n_domain)%>&gu_workarea=<%=gu_workarea%>&gu_contact=<%=gu_contact%>&gu_oportunity=<%=gu_oportunity%>" CLASS="linkplain">Show Admission</A></TD>
        	  <TD WIDTH="8"></TD>
        	  <TD><IMG SRC="../images/images/training/student16.gif" HEIGHT="16" WIDTH="16" BORDER="0" ALT="View Registration"></TD>
        	  <TD><A HREF="../training/registration_edit.jsp?id_domain=<%=id_domain%>&n_domain=<%=Gadgets.URLEncode(n_domain)%>&gu_workarea=<%=gu_workarea%>&gu_contact=<%=gu_contact%>&gu_oportunity=<%=gu_oportunity%>" CLASS="linkplain">Show Enrollment</A></TD>
        </TR>
      -->
      </TABLE>
  <DIV style="background-color:transparent; position: relative;width:600px;height:496px">
  <DIV id="p1panel0" class="panel" style="background-color:#eee;z-index:2">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_oportunity" VALUE="<%=gu_oportunity%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=gu_company%>">
    <INPUT TYPE="hidden" NAME="tx_contact" VALUE="<%=oCont.getStringNull(DB.tx_surname,"") + ", " + oCont.getStringNull(DB.tx_name,"")%>">         
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=gu_list%>">
    <INPUT TYPE="hidden" NAME="id_former_status" VALUE="<%=oOprt.getStringNull(DB.id_status,"")%>">
    <INPUT TYPE="hidden" NAME="nu_oportunities" VALUE="<% if (oOprt.isNull(DB.nu_oportunities)) out.write("1"); else out.write(String.valueOf(oOprt.getInt(DB.nu_oportunities))); %>">

<% if ((iAppMask & (1<<Marketing))==0) { %>
    <INPUT TYPE="hidden" NAME="gu_campaign" VALUE="<%=oOprt.getStringNull(DB.gu_campaign,"")%>">
<% } %>
    <TABLE SUMMARY="Fixed Attributes" WIDTH="100%">
      <TR><TD>
        <TABLE ALIGN="center">
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Opportunity for</FONT></TD>
            <TD ALIGN="left" WIDTH="420" CLASS="formplain"><TABLE><TR><TD VALIGN="middle">
              &nbsp;<I>
              <%
                if (de_list!=null)
                  out.write (" (" + de_list + ")");
	        else {
                  if (!oCont.isNull(DB.tx_surname) || !oCont.isNull(DB.tx_name))
                    out.write (" <A HREF=\"contact_edit.jsp?id_domain="+id_domain+"&n_domain=" + Gadgets.URLEncode(n_domain) + "&gu_contact=" + gu_contact + "&noreload=1\" onclick=\"modifyContact()\">" + oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,"")+"</A>");

                  if (!oComp.isNull(DB.nm_legal))
                    out.write (" (<A HREF=\"company_edit.jsp?id_domain="+ id_domain + "&n_domain=" + Gadgets.URLEncode(n_domain) + "&gu_company=" + gu_company + "&n_company=" + Gadgets.URLEncode(oComp.getString(DB.nm_legal)) + "&gu_workarea=" + gu_workarea + "&noreload=1\">" + oComp.getString(DB.nm_legal) + "</A>)");
                }
              %>
              </I></TD>
            </TR></TABLE></TD>
          </TR>
		  <!-- Inicio I2E 2009-12-15 -->	         
          <TR>
          	<TD colspan="2">
	          	<TABLE>
	          	<TR>
		          	<TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Responsible</FONT></TD>
		            <TD ALIGN="left" WIDTH="420" CLASS="formplain"><%=tx_nickname%></TD>
		            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Date</FONT></TD>
		            <TD ALIGN="left" WIDTH="420" CLASS="formplain"><%=sDtCreated%></TD>
	            </TR>
	            </TABLE>
            </TD>
          </TR>
          <!-- Fin I2E -->
<% if (0==gu_oportunity.length() || oOprt.getStringNull(DB.gu_writer,"").equals(id_user)) { %>
          <TR>            
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formstrong">Private:</FONT></TD>            
            <TD ALIGN="left" WIDTH="420">
            	<INPUT TYPE="hidden" NAME="bo_private" VALUE="<%=(sPrivate.length()>0 ? "1" : "0")%>"><INPUT TYPE="checkbox" NAME="chk_private" VALUE="1" <%=sPrivate%> >
<%            if (!oOprt.getStringNull(DB.gu_writer,"").equals(id_user)) {
                oUser = new ACLUser(oConn,oCont.getStringNull(DB.gu_writer, id_user));
                out.write("&nbsp;Owner:&nbsp;"+oUser.getStringNull(DB.nm_user,"") + " " + oUser.getStringNull(DB.tx_surname1,"") + " " + oUser.getStringNull(DB.tx_surname2,""));
              }
%>          </TD>
<% } else { %>
          <TR>            
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Private:</FONT></TD>            
            <TD ALIGN="left" WIDTH="420">
            	<INPUT TYPE="hidden" NAME="bo_private" VALUE="<%=(sPrivate.length()>0 ? "1" : "0")%>"><INPUT TYPE="checkbox" NAME="chk_private" VALUE="1" onClick="return false;" <%=sPrivate%>>
<%            if (!oOprt.getStringNull(DB.gu_writer,"").equals(id_user)) {
                oUser = new ACLUser(oConn,oCont.getStringNull(DB.gu_writer, id_user));
                out.write("&nbsp;Owner:&nbsp;"+oUser.getStringNull(DB.nm_user,"") + " " + oUser.getStringNull(DB.tx_surname1,"") + " " + oUser.getStringNull(DB.tx_surname2,""));
              }
%>          </TD>
          </TR>
<% } %>
          <TR>
          <!-- Inicio I2E 2009-12-15 -->
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formstrong">Objective:</FONT></TD>
            <!-- Fin I2E -->
            <TD ALIGN="left" WIDTH="420">
              <SELECT NAME="sel_objetive"><OPTION VALUE=""></OPTION><%=sObjectiveLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Objectives List"></A>
              <INPUT TYPE="hidden" NAME="id_objetive" VALUE="<%=oOprt.getStringNull(DB.id_objetive,"")%>">
            </TD>
          </TR>
<% if ((iAppMask & (1<<Marketing))!=0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formstrong">Campaign</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT NAME="gu_campaign"><OPTION VALUE=""></OPTION><%=sCampaigns%></SELECT>
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formstrong">Title</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="tl_oportunity" MAXLENGTH="128" SIZE="40" VALUE="<%=oOprt.getStringNull(DB.tl_oportunity,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formstrong">Status:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT NAME="sel_status" onchange="if (this.options[this.selectedIndex].value=='GANADA') setCombo(document.forms[0].sel_cause,'VENTA')"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Status List"></A>
              <INPUT TYPE="hidden" NAME="id_status" VALUE="<%=oOprt.getStringNull(DB.id_status,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Close reason:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT NAME="sel_cause"><OPTION VALUE=""></OPTION><%=sCauseLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Causes"></A>
              <INPUT TYPE="hidden" NAME="tx_cause" VALUE="<%=oOprt.getStringNull(DB.tx_cause,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Interest Degree</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><FONT CLASS="formplain">
            	<INPUT TYPE="radio" NAME="lv_interest" VALUE="0">&nbsp;None&nbsp;&nbsp;&nbsp;
            	<INPUT TYPE="radio" NAME="lv_interest" VALUE="1">&nbsp;Few&nbsp;&nbsp;&nbsp;
            	<INPUT TYPE="radio" NAME="lv_interest" VALUE="2">&nbsp;Average&nbsp;&nbsp;&nbsp;
            <INPUT TYPE="radio" NAME="lv_interest" VALUE="3">&nbsp;Much&nbsp;&nbsp;&nbsp;</FONT>            	
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Information Media</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT NAME="sel_origin"><OPTION VALUE=""></OPTION><%=sOriginLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Origins List"></A>
              <INPUT TYPE="hidden" NAME="tp_origin" VALUE="<%=oOprt.getStringNull(DB.tp_origin,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Amount:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
            	<INPUT TYPE="text" NAME="im_revenue" MAXLENGTH="11" SIZE="11" VALUE="<% if (oOprt.get(DB.im_revenue)!=null) out.write(String.valueOf((int)oOprt.getFloat(DB.im_revenue))); %>">
              &nbsp;&nbsp;&nbsp;<FONT CLASS="formplain">Cost:</FONT>&nbsp;<INPUT TYPE="text" NAME="im_cost" MAXLENGTH="11" SIZE="11" VALUE="<% if (oOprt.get(DB.im_cost)!=null) out.write(String.valueOf((int)oOprt.getFloat(DB.im_cost))); %>">              
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Last Call</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><FONT CLASS="formplain"><% if (!oOprt.isNull("dt_last_call")) out.write(oOprt.getDateFormated("dt_last_call", "yyyy-MM-dd HH:mm")); else out.write("No llamado nunca"); %></FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">Next Date</FONT></TD>
            <TD>
              <INPUT TYPE="text" MAXLENGTH="10" SIZE="11" NAME="dt_next_action" VALUE="<% if (oOprt.get(DB.dt_next_action)!=null) out.write(oSimpleDate.format((Date)oOprt.get(DB.dt_next_action))); %>">&nbsp;&nbsp;
              <A HREF="javascript:showCalendar('dt_next_action')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>
<% if ((iAppMask & (1<<CollabTools))!=0) { %>
          <TR>
            <TD ALIGN="right"><INPUT TYPE="checkbox" NAME="chk_meeting" VALUE="1"></TD>
            <TD><FONT CLASS="formplain">Create an activity at calendar for next action</FONT></TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><TEXTAREA NAME="tx_note" ROWS="2" COLS="40"><%=oOprt.getStringNull(DB.tx_note,"")%></TEXTAREA></TD>
          </TR>          
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your credential level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
<% } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<% } %>
              <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </DIV>
  <DIV onclick="selectTab(0)" id="p1tab0" class="tab" style="background-color:#eee; height:26px; left:0px; top:0px; z-index:2"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Fixed fields</SPAN></DIV>
  <DIV id="p1panel1" class="panel" style="background-color: #ddd;  z-index:1">
  <BR><BR><BR>
    <TABLE WIDTH="100%">
      <TR><TD>
        <TABLE ALIGN="center">
          <%=paintAttributes (oConn, GlobalCacheClient, id_domain, id_user, iAppMask, DB.k_oportunities_attrs, "Oportunidades", gu_workarea, sLanguage, gu_oportunity) %>
        </TABLE>
      </TD></TR>
    </TABLE>    
  </DIV>
  <DIV onclick="selectTab(1)" id="p1tab1" class="tab" style="width:240px; background-color:#ddd; height:26px; left:180px; top:0px; z-index:1"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Defined by User</SPAN></DIV>
  </DIV>  
</FORM>
</BODY>
</HTML>
<%
if (null!=oConn)  oConn.close("oportunity_edit");
oConn=null; 
%>
