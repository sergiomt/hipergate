<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets,com.knowgate.marketing.Activity,com.knowgate.marketing.ActivityAudience,com.knowgate.addrbook.Meeting,com.knowgate.hipermail.AdHocMailing,com.knowgate.dataxslt.db.PageSetDB,com.knowgate.misc.Calendar" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.

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
  
  final String PAGE_NAME = "activity_edit";

  final int WebBuilder = 14;
  final int Hipermail = 21;
  final int CollaborativeTools = 17;
  final int MarketingTools = 18;
  
  final String sSkin = getCookie(request, "skin", "xp");
  final String sLanguage = getNavigatorLanguage(request);
  final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  final String sStorage = GlobalDBBind.getPropertyPath("storage");
  final String sProtocol = GlobalDBBind.getProperty("fileprotocol", "file://");
  final char cSep = sProtocol.equals("ftp://") ? '/' : System.getProperty("file.separator").charAt(0);

  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_activity = request.getParameter("gu_activity");
  String gu_microsite = null;

  String id_user = getCookie(request, "userid", "");
  
  Activity oActy = new Activity();
  ACLUser oCusr = new ACLUser();
  Meeting oMeet = new Meeting();
  AdHocMailing oAdhm = new AdHocMailing();
  PageSetDB oPgst = new PageSetDB();
  DBSubset oMfllw = null;
  DBSubset oMroom = null;
  DBSubset oFllws = GlobalCacheClient.getDBSubset("k_fellows.gu_workarea[" + gu_workarea + "]"); 
  DBSubset oRooms = GlobalCacheClient.getDBSubset("k_rooms.nm_room[" + gu_workarea + "]");  
  DBSubset oAttc = new DBSubset(DB.v_activity_locat, DB.gu_product + "," + DB.nm_product + "," + DB.gu_location + "," + DB.pg_product,
                                DB.gu_activity+"=?", 10);
  DBSubset oCnts = new DBSubset(DB.k_x_activity_audience, "COUNT(*),"+DB.bo_confirmed, DB.gu_activity+"=? GROUP BY 2", 10);
  DBSubset oRcps = new DBSubset(DB.k_x_adhoc_mailing_list, DB.gu_list, DB.gu_mailing+"=?", 12);
  DBSubset oCamp = new DBSubset(DB.k_campaigns, DB.gu_campaign+","+DB.nm_campaign+","+DB.dt_created,
  														  DB.gu_workarea+"=? AND "+DB.bo_active+"<>0 ORDER BY 3 DESC", 100);
  DBSubset oLsts = new DBSubset(DB.k_lists, DB.gu_list + "," + DB.de_list + "," + DB.tx_subject,
                                DB.gu_workarea+"=? ORDER BY 2", 100);
  DBSubset oTmpl = new DBSubset(DB.k_microsites, DB.nm_microsite + "," + DB.gu_microsite + "," + DB.path_metadata,
                                DB.id_app+"=13 AND ("+DB.gu_workarea+" IS NULL OR "+DB.gu_workarea+"=?)", 10);
  DBSubset oTags = new DBSubset(DB.k_activity_tags, DB.nm_tag, DB.gu_activity+"=?", 10);

  int iTags = 0;
  int iTmpl = 0;
  int iLsts = 0;
  int iRcps = 0;
  int iCamp = 0;
  int iAttc = 0;
  int iConf = -1;
  int iRooms = 0;
  int iFllws = 0;
  
  String sDeptLookUp = "";
  String sAddrLookUp = "";
  String sMailLookUp = "";
  String sFromLookUp = "";
  String sLangsList = "";

  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);

		oCusr.load(oConn, new Object[]{id_user});
		
		iTmpl = oTmpl.load(oConn, new Object[]{gu_workarea});
		
		iLsts = oLsts.load(oConn, new Object[]{gu_workarea});
		
		iCamp = oCamp.load(oConn, new Object[]{gu_workarea});
				
    sLangsList = GlobalDBLang.toHTMLSelect(oConn, sLanguage);
    
    sDeptLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_activity_audience_lookup", gu_workarea, "tx_dept", sLanguage);
    sAddrLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_meetings_lookup", gu_workarea, "gu_address", sLanguage);
    if (((iAppMask & (1<<Hipermail))!=0) && ((iAppMask & (1<<WebBuilder))!=0)) {
      sMailLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_activity_audience_lookup", gu_workarea, "tx_email_from", sLanguage);
      sFromLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_activity_audience_lookup", gu_workarea, "nm_from", sLanguage);
    }

    if (null!=gu_activity) {
      oActy.load(oConn, new Object[]{gu_activity});
      oCnts.load(oConn, new Object[]{gu_activity});
      iTags = oTags.load(oConn, new Object[]{gu_activity});
      iAttc = oAttc.load(oConn, new Object[]{gu_activity});
      if (!oActy.isNull(DB.gu_mailing)) {
        oAdhm.load(oConn, new Object[]{oActy.getString(DB.gu_mailing)});
        iRcps = oRcps.load(oConn, new Object[]{oActy.getString(DB.gu_mailing)});
      }
      if (!oActy.isNull(DB.gu_pageset)) oPgst.load(oConn, new Object[]{oActy.getString(DB.gu_pageset)});
    } // fi

    if (((iAppMask & (1<<CollaborativeTools))!=0)) {

      if (null==oRooms) {
        oRooms = new DBSubset (DB.k_rooms,
       	              		     DB.nm_room + "," + DB.tx_company + "," + DB.tx_location + "," + DB.tp_room + "," + DB.tx_comments,
      			                   DB.bo_available + "=1 AND " + DB.gu_workarea + "=? ORDER BY 4,1", 50);
      
        iRooms = oRooms.load (oConn, new Object[]{gu_workarea});
            
        GlobalCacheClient.putDBSubset("k_rooms", "k_rooms.nm_room[" + gu_workarea + "]", oRooms);           
      } // fi(oRooms)
      else {
        iRooms = oRooms.getRowCount();
      }

		  if (!oActy.isNull(DB.gu_meeting)) {
		    oMeet.load(oConn, new Object[]{oActy.get(DB.gu_meeting)});
        oMfllw = oMeet.getFellows(oConn);
        oMroom = oMeet.getRooms(oConn);
		  }

		  if (!oActy.isNull(DB.gu_pageset)) {
		    gu_microsite = DBCommand.queryStr(oConn, "SELECT m.gu_microsite FROM k_microsites m, k_pagesets p WHERE p.gu_microsite=m.gu_microsite AND p.gu_pageset='"+oActy.getString(DB.gu_pageset)+"'");
		  }

      if (null==oFllws) {
        oFllws = new DBSubset(DB.k_fellows, DB.gu_fellow + "," + DB.tx_name + "," + DB.tx_surname,
                              DB.gu_workarea + "='" + gu_workarea + "' ORDER BY 2,3", 100);
      	iFllws = oFllws.load(oConn);        	
      	GlobalCacheClient.putDBSubset("k_fellows", "k_fellows.gu_workarea[" + gu_workarea + "]", oFllws);
      } else {
        iFllws = oFllws.getRowCount();
		  }

    } // fi (CollaborativeTools)
    
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%= gu_activity==null ? "New Activity" : "Edit Activity" %></TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/protomultiselect/protoculous-effects-shrinkvars.js" CHARSET="utf-8"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/protomultiselect/textboxlist.js" CHARSET="utf-8"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/protomultiselect/protomultiselect.js" CHARSET="utf-8"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      var met = false;
      var lst = new Array();
      var available = true;

<%  
			out.write("      var jsAttachs = new Array(");
      for (int a=0; a<iAttc; a++) {
        out.write((a==0 ? "" : ",") + "\"" + oAttc.getString(0,a) + "_" + String.valueOf(oAttc.getInt(3,a)) + "\"");
      }
      out.write(");\n");

      if (((iAppMask & (1<<CollaborativeTools))!=0)) {

      out.write("      var jsComments = new Array(");
      for (int r=0; r<iRooms; r++) {
        if (r>0) out.write(",");
        out.write("\"" + oRooms.getStringNull(DB.tx_comments,r,"").replace('\n',' ').replace('"',' ').replace('\r',' ') + "\"");
      }
      out.write(");\n");
%>      
      function showComments() {
        var frm = document.forms[0];
        var opt = frm.sel_rooms.options;
        var idx = opt.selectedIndex;
                
        if (idx>=0) {
          var txt = jsComments[idx-1];
          if (txt)
            frm.read_comments.value = txt;
          else
            frm.read_comments.value = "";
        }
      }

      // ------------------------------------------------------
      
      function checkAvailability() {
	      available = true;
	      var frm = document.forms[0];
	      var crm = frm.sel_rooms;
                
        if (frm.chk_meeting.checked && isDate(frm.dt_start.value,"d") && isDate(frm.dt_end.value,"d")) {
          var s = frm.dt_start.value;
          var e = frm.dt_end.value;          
          var dts = new Date (parseInt(s.substr(0,4)),parseFloat(s.substr(5,2))-1,parseFloat(s.substr(8,2)),parseFloat(getCombo(frm.sel_h_start)),parseFloat(getCombo(frm.sel_m_start)), 0);
          var dte = new Date (parseInt(e.substr(0,4)),parseFloat(e.substr(5,2))-1,parseFloat(e.substr(8,2)),parseFloat(getCombo(frm.sel_h_end))  ,parseFloat(getCombo(frm.sel_m_end))  ,59);
      	  for (var r=0; r<crm.options.length; r++) {
      	    if (crm.options[r].selected) {
      	      for (var m=0; m<lst.length; m++) {
      	        var mts = lst[m][2];
      	        var mte = lst[m][3];	        
      	        if ("<%=oActy.getStringNull(DB.gu_meeting,"")%>"!=lst[m][0] && crm.options[r].value==lst[m][1] && ((dts<=mts && dte>mts) || (dts>=mts && dts<=mte) || (dts<mte && dte>=mte))) {
      	          alert (lst[m][1]+" The resource is already allocated to another activity at the same time Booked by  "+lst[m][4]);
      	          available = false;
      	          break;
      	        }
      	      }
      	    }
      	  } // next
   	      if (dte<dts) frm.dt_end.value=frm.dt_start.value;
	      } //	
	      return available;
      } // checkAvailability

      // ------------------------------------------------------
      
      function processMeetingsList() {
          if (met.readyState == 4) {
            if (met.status == 200) {
              var meetings = met.responseXML.getElementsByTagName("meeting");
              var imeetings = meetings.length;
              if (imeetings>0) {
                lst = new Array(imeetings);
                for (var m=0; m<imeetings; m++) {
		              var gum = getElementText(meetings[m],"gu_meeting");
		              var nmr = getElementText(meetings[m],"nm_room");
		              var nmf = getElementText(meetings[m],"tx_name")+" "+getElementText(meetings[m],"tx_surname");
                  var s = getElementText(meetings[m],"dt_start");
                  var e = getElementText(meetings[m],"dt_end");                
                  var dts = new Date (parseInt(s.substr(0,4)),parseFloat(s.substr(5,2))-1,parseFloat(s.substr(8,2)),parseFloat(s.substr(11,2)),parseFloat(s.substr(14,4)),parseFloat(s.substr(17,2)));
                  var dte = new Date (parseInt(e.substr(0,4)),parseFloat(e.substr(5,2))-1,parseFloat(e.substr(8,2)),parseFloat(e.substr(11,2)),parseFloat(e.substr(14,4)),parseFloat(e.substr(17,2)));
                  lst[m] = new Array(gum,nmr,dts,dte,nmf);
                }
              } else {
                lst = new Array();
              }
              met = false;
            }
	        }
      } // processMeetingsList
      
      function loadDailyMeetings() {
      	var frm = document.forms[0];

      	frm.dt_start.value = getCombo(frm.sel_year_start)+"-"+getCombo(frm.sel_month_start)+"-"+getCombo(frm.sel_day_start)+ " "+getCombo(frm.sel_h_start)+":"+getCombo(frm.sel_m_start)+":00";
      	frm.dt_end.value = getCombo(frm.sel_year_end)+"-"+getCombo(frm.sel_month_end)+"-"+getCombo(frm.sel_day_end)+ " "+getCombo(frm.sel_h_end)+":"+getCombo(frm.sel_m_end)+":59";

        met = createXMLHttpRequest();
        if (met) {
        	var dts = frm.dt_start.value.substr(0,10);
        	var dte = frm.dt_end.value.substr(0,10);
        	if (isDate(dts,"d") && isDate(dte,"d")) {
	          met.onreadystatechange = processMeetingsList;
            met.open("GET", "../addrbook/room_availability.jsp?gu_workarea=<%=gu_workarea%>&dt_start="+dts+"&dt_end="+dte, true);
            met.send(null);
          }
        }
      } // loadDailyMeetings

<% } // fi (CollaborativeTools) %>

      // ------------------------------------------------------

      function setRefId() {
      	var frm = document.forms[0];
				var res = httpRequestText("activity_ref_lookup.jsp?gu_workarea="+frm.gu_workarea.value+"&gu_activity="+frm.gu_activity.value+"&id_ref="+
				                          escape(frm.id_ref.value.length>0 ? frm.id_ref.value : frm.tl_activity.value)).split("\n");
        if (res[0]=="true") {
          alert("Another activity with the same reference already exists");
          frm.id_ref.focus();
        } else if (res[0]=="false") {
          frm.id_ref.value = res[1];
        } else {
          alert("Error: "+res[1]);        
        }
        return true;
      }
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
	      var frm = window.document.forms[0];
       
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_activity_audience_lookup&id_language=" + getUserLanguage() + "&id_section=tx_dept&tp_control=2&nm_control=sel_dept&nm_coding=tx_dept", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_activity_audience_lookup&id_language=" + getUserLanguage() + "&id_section=tx_email_from&tp_control=2&nm_control=sel_email_from&nm_coding=tx_email_from", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_activity_audience_lookup&id_language=" + getUserLanguage() + "&id_section=nm_from&tp_control=2&nm_control=sel_from&nm_coding=nm_from", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------

      function deleteAttachment(n) {
        document.getElementById("a"+String(n)).style.display="none";
        document.getElementById("d"+String(n)).style.display="none";
        var dlte = createXMLHttpRequest();
        dlte.open("GET","activity_attach_edit_delete.jsp?gu_activity<%=gu_activity%>&checkeditems="+jsAttachs[n],true);
        dlte.send(null);
      }

      // ------------------------------------------------------
      
      function validate() {
        var frm = document.forms[0];
        var opt;

        if (frm.tl_activity.value.length==0) {
          alert ("Activity title is required");
          frm.tl_activity.focus();
          return false;
        } 

        if (frm.id_ref.value.length==0) {
          alert ("Activity reference is required");
          frm.id_ref.focus();
          return false;
        } 

        if (hasForbiddenChars(frm.id_ref.value)) {
          alert ("Activityreferenc e contains invalid characters");
          frm.id_ref.focus();
          return false;
        } 

				var ref = httpRequestText("activity_ref_lookup.jsp?gu_workarea="+frm.gu_workarea.value+"&gu_activity="+frm.gu_activity.value+"&id_ref="+escape(frm.id_ref.value)).split("\n");
				if (ref[0]=="true") {
          alert("Another activity with the same reference already exists");
          frm.id_ref.focus();
          return false;
				} else {
			    frm.id_ref.value = ref[1];
			  }

        if (frm.nu_capacity.value.length>0) {
        	if (isIntValue(frm.nu_capacity.value)) {
            if (parseInt(frm.nu_capacity.value)<0) {
              alert ("Capacity is not a valid integer number");
              frm.nu_capacity.focus();
              return false;
            }
        	} else {
            alert ("Capacity is not a valid integer number");
            frm.nu_capacity.focus();
            return false;
          }
        }

        if (frm.pr_sale.value.length>0) {
        	if (isFloatValue(frm.pr_sale.value)) {
            if (parseFloat(frm.pr_sale.value)<0) {
              alert ("Sale price is not a valid amount");
              frm.pr_sale.focus();
              return false;
            }
        	} else {
            alert ("Sale price is not a valid amount");
            frm.pr_sale.focus();
            return false;
          }
        }

        if (frm.pr_discount.value.length>0) {
        	if (isFloatValue(frm.pr_discount.value)) {
            if (parseFloat(frm.pr_discount.value)<0) {
              alert ("The discounted price is not a valid amount");
              frm.pr_discount.focus();
              return false;
            }
        	} else {
            alert ("The discounted price is not a valid amount");
            frm.pr_discount.focus();
            return false;
          }
        }

      	frm.dt_start.value = getCombo(frm.sel_year_start)+"-"+getCombo(frm.sel_month_start)+"-"+getCombo(frm.sel_day_start)+" "+getCombo(frm.sel_h_start)+":"+getCombo(frm.sel_m_start)+":00";
      	frm.dt_end.value = getCombo(frm.sel_year_end)+"-"+getCombo(frm.sel_month_end)+"-"+getCombo(frm.sel_day_end)+" "+getCombo(frm.sel_h_end)+":"+getCombo(frm.sel_m_end)+":59";

        if (!isDate(frm.dt_start.value,"ts")) {
          alert ("Start date is not valid");
          return false;
        } 

        if (!isDate(frm.dt_end.value,"ts")) {
          alert ("End date is not valid");
          return false;
        } 

        if (parseDate(frm.dt_start.value, "ts")>parseDate(frm.dt_end.value, "ts")) {
          alert ("Start date must be prior to end date");
          return false;
        }

        if (frm.de_activity.value.length>1000) {
          alert ("Activity description may not be longer that 1,000 characters");
          frm.de_activity.focus();
          return false;
        } 

        if (frm.tx_comments.value.length>254) {
          alert ("Comments may not be longer than 254 characters");
          frm.tx_comments.focus();
          return false;
        } 

<%      if (((iAppMask & (1<<Hipermail))!=0) && ((iAppMask & (1<<WebBuilder))!=0)) { %>

          var bmail = <%= !oActy.isNull(DB.gu_mailing) || !oActy.isNull(DB.gu_pageset) ? "true" : "frm.chk_emailing.checked" %>;

  				if (bmail) {

      	    frm.dt_execution.value = getCombo(frm.sel_year)+"-"+getCombo(frm.sel_month)+"-"+getCombo(frm.sel_day);

            if (!isDate(frm.dt_execution.value,"d")) {
              alert ("E-mailing date is not valid");
              return false;
            } 

            if (parseDate(frm.dt_start.value, "d")<parseDate(frm.dt_execution.value, "d")) {
              alert ("Start date is before mailing date");
              return false;
            }

  				  if (frm.tx_subject.value.length==0) {
              alert ("Subject is required");
              frm.tx_subject.focus();
              return false;
  				  }
  					if (frm.sel_email_from.selectedIndex>0) {
  					  frm.tx_email_from.value = getCombo(frm.sel_email_from);					  
  					} else {
              alert ("Sender e-mail address is required");
              frm.tx_email_from.focus();
              return false;
  					}
  					if (frm.sel_from.selectedIndex>0) {
  					  frm.nm_from.value = getCombo(frm.sel_from);					  
  					} else {
              alert ("Display-Name isrequir ed");
              frm.sel_from.focus();
              return false;
  					}
  				} else {
  					frm.nm_from.value = "";
  					frm.tx_email_from.value = "";
  				}
  				
				  frm.lists.value = getCombo(frm.sel_lists);
				  frm.tx_email_from.value = getComboText(frm.sel_email_from);
				  frm.nm_from.value = getComboText(frm.sel_from);
<% }
   if (((iAppMask & (1<<CollaborativeTools))!=0)) { %>
          
  		  if (frm.chk_meeting.checked) {

				  frm.fellows.value = getCombo(frm.sel_fellows);
				  if (frm.fellows.value.length==0) {
            alert ("The activity must be assigned to at least one calendar");
            frm.sel_fellows.focus();
            return false;
				  }

				  frm.tp_meeting.value = getCombo(frm.sel_tp_meeting);
				  frm.rooms.value = getCombo(frm.sel_rooms);
				}
<% } %>

				frm.tx_dept.value = getCombo(frm.sel_dept);
				frm.gu_address.value = getCombo(frm.sel_address);
 				frm.bo_active.value = getCheckedValue(frm.chk_active);

				frm.tags.value = $F('facebook-demo');

        return true;
      } // validate

      // ------------------------------------------------------

      function setCombos() {

        var frm = document.forms[0];

				setCombo(frm.id_language, "<%=oActy.getStringNull(DB.id_language,sLanguage)%>");
				setCombo(frm.sel_dept, "<%=oActy.getStringNull(DB.tx_dept,"")%>");
				setCombo(frm.sel_address, "<%=oActy.getStringNull(DB.gu_address,"")%>");

<%      if (!oActy.isNull(DB.dt_start)) { %>
          setCombo(frm.sel_year_start,"<% out.write(String.valueOf(oActy.getDate(DB.dt_start).getYear()+1900)); %>");
          setCombo(frm.sel_month_start,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_start).getMonth()+1),'0',2)); %>");
          setCombo(frm.sel_day_start,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_start).getDate()),'0',2)); %>");
          setCombo(frm.sel_h_start,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_start).getHours()),'0',2)); %>");
          setCombo(frm.sel_m_start,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_start).getMinutes()),'0',2)); %>");
<%      }

        if (!oActy.isNull(DB.dt_end)) { %>
          setCombo(frm.sel_year_end,"<% out.write(String.valueOf(oActy.getDate(DB.dt_end).getYear()+1900)); %>");
          setCombo(frm.sel_month_end,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_end).getMonth()+1),'0',2)); %>");
          setCombo(frm.sel_day_end,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_end).getDate()),'0',2)); %>");			
          setCombo(frm.sel_h_end,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_end).getHours()),'0',2)); %>");
          setCombo(frm.sel_m_end,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_end).getMinutes()),'0',2)); %>");
<%      }

        if ((iAppMask & (1<<MarketingTools))!=0) { %>

				  setCombo(frm.gu_campaign, "<%=oActy.getStringNull(DB.gu_campaign,"")%>");
<%      }

        if (((iAppMask & (1<<Hipermail))!=0) && ((iAppMask & (1<<WebBuilder))!=0)) { %>
          frm.tx_subject.value = "<%=oActy.getStringHtml(DB.tx_subject,"")%>";
          frm.url_activity.value = "<%=oActy.getStringNull(DB.url_activity,"")%>";
				  setCombo(frm.sel_email_from, "<%=oActy.getStringNull(DB.tx_email_from,"")%>");
				  setCombo(frm.sel_from, "<%=oActy.getStringNull(DB.nm_from,"")%>");
<%        if (!oAdhm.isNull(DB.dt_execution)) { %>
            setCombo(frm.sel_year,"<% out.write(String.valueOf(oAdhm.getDate(DB.dt_execution).getYear()+1900)); %>");
            setCombo(frm.sel_month,"<% out.write(Gadgets.leftPad(String.valueOf(oAdhm.getDate(DB.dt_execution).getMonth()+1),'0',2)); %>");
            setCombo(frm.sel_day,"<% out.write(Gadgets.leftPad(String.valueOf(oAdhm.getDate(DB.dt_execution).getDate()),'0',2)); %>");			
<%        } else if (!oActy.isNull(DB.dt_mailing)) { %>
            setCombo(frm.sel_year,"<% out.write(String.valueOf(oActy.getDate(DB.dt_mailing).getYear()+1900)); %>");
            setCombo(frm.sel_month,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_mailing).getMonth()+1),'0',2)); %>");
            setCombo(frm.sel_day,"<% out.write(Gadgets.leftPad(String.valueOf(oActy.getDate(DB.dt_mailing).getDate()),'0',2)); %>");			
<%	      }
          if (!oActy.isNull(DB.gu_mailing) || !oActy.isNull(DB.gu_pageset)) { %>
					  document.getElementById("emailopts").style.display="block";
<%        }
          for (int r=0; r<iRcps; r++) { %>
            setCombo(frm.sel_lists,"<% out.write(oRcps.getString(0,r)); %>");                
<%        } // next
        } // fi (iAppMask&Hipermail)

        if (((iAppMask & (1<<CollaborativeTools))!=0)) { %>

				  setCombo(frm.sel_tp_meeting, "<%=oMeet.getStringNull(DB.tp_meeting,"")%>");
				  loadDailyMeetings();
<%        
          if (oMfllw!=null) {
            for (int f=0; f<oMfllw.getRowCount(); f++) { %>
				      setCombo(frm.sel_fellows, "<%=oMfllw.getString(0,f)%>");
<%          }
          } // fi

					if (oMroom!=null) {
            for (int r=0; r<oMroom.getRowCount(); r++) { %> 
				      setCombo(frm.sel_rooms, "<%=oMroom.getString(0,r)%>");					
<%			    }
          }
        } // fi (iAppMask&CollaborativeTools) %>
      } // setCombos

    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:300px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%" SUMMARY="Title">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1"><%= gu_activity==null ? "New Activity" : "Edit Activity" %></FONT></TD></TR>
  </TABLE>
  <FORM ENCTYPE="multipart/form-data" METHOD="post" ACTION="activity_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_activity" VALUE="<%=oActy.getStringNull(DB.gu_activity,"")%>">
    <INPUT TYPE="hidden" NAME="pg_activity" VALUE="<% if (!oActy.isNull(DB.pg_activity)) out.write(String.valueOf(oActy.getInt(DB.pg_activity))); %>">
    <INPUT TYPE="hidden" NAME="gu_pageset" VALUE="<%=oActy.getStringNull(DB.gu_pageset,"")%>">
    <INPUT TYPE="hidden" NAME="gu_mailing" VALUE="<%=oActy.getStringNull(DB.gu_mailing,"")%>">
    <INPUT TYPE="hidden" NAME="gu_meeting" VALUE="<%=oActy.getStringNull(DB.gu_meeting,"")%>">
    <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=oActy.getStringNull(DB.gu_list,"")%>">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="">
    <INPUT TYPE="hidden" NAME="fellows" VALUE="">
    <INPUT TYPE="hidden" NAME="rooms" VALUE="">
    <INPUT TYPE="hidden" NAME="lists" VALUE="">
    <INPUT TYPE="hidden" NAME="tags" VALUE="">
<% if (null!=gu_activity) { %>
    <TABLE SUMMARY="Audience">
      <TR><TD><IMG SRC="../images/images/marketing/audience.gif" HEIGHT="20" WIDTH="20" BORDER="0" ALT="Audience"></TD>
          <TD><A HREF="activity_audience.jsp?gu_activity=<%=gu_activity%>" CLASS="linkplain">Show Audience</A></TD></TR>
    </TABLE>  
<% } %>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="160"></TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain"><INPUT TYPE="radio" NAME="chk_active" VALUE="1" <% if (oActy.isNull(DB.bo_active)) out.write("CHECKED"); else if (oActy.getShort(DB.bo_active)!=0) out.write("CHECKED"); %>>&nbsp;Visible&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="chk_active" VALUE="0" <% if (!oActy.isNull(DB.bo_active)) if (oActy.getShort(DB.bo_active)==0) out.write("CHECKED"); %>>&nbsp;Hidden</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formstrong">Title</FONT></TD>
            <TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="tl_activity" MAXLENGTH="100" SIZE="50" VALUE="<%=oActy.getStringHtml(DB.tl_activity,"")%>" onblur="setRefId()"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Reference</FONT></TD>
            <TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="id_ref" MAXLENGTH="30" SIZE="30" VALUE="<%=oActy.getStringHtml(DB.id_ref,"")%>" onblur="setRefId()"></TD>
          </TR>
<%    if ((iAppMask & (1<<MarketingTools))!=0) { %>          
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Campaign</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <SELECT NAME="gu_campaign"><OPTION VALUE=""></OPTION><% for (int c=0; c<iCamp; c++) out.write("<OPTION VALUE=\""+oCamp.getString(0,c)+"\">"+oCamp.getString(1,c)+"</OPTION>"); %></SELECT>
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formstrong">Created by</FONT></TD>
            <TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="nm_author" MAXLENGTH="200" SIZE="40" VALUE="<%=oActy.getStringHtml(DB.nm_author,oCusr.getFullName())%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Department</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <INPUT TYPE="hidden" NAME="tx_dept">
              <SELECT NAME="sel_dept"><OPTION VALUE=""></OPTION><%=sDeptLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Departments List"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain">Start date</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">
              <INPUT TYPE="hidden" NAME="dt_start" VALUE="<% out.write(oActy.isNull(DB.dt_start) ? "" : oActy.getDateTime24(DB.dt_start)); %>">
              <SELECT CLASS="combomini" NAME="sel_day_start" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> loadDailyMeetings();checkAvailability(); <% } %>"><% for (int d=1; d<=31; d++) out.write("<OPTION VALUE=\""+Gadgets.leftPad(String.valueOf(d),'0',2)+"\">"+Gadgets.leftPad(String.valueOf(d),'0',2)+"</OPTION>"); %></SELECT>
              <SELECT CLASS="combomini" NAME="sel_month_start" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> loadDailyMeetings();checkAvailability(); <% } %>"><% for (int m=0; m<=11; m++) out.write("<OPTION VALUE=\""+(m<9 ? "0" : "")+String.valueOf(m+1)+"\">"+Calendar.MonthName(m, sLanguage)+"</OPTION>"); %></SELECT>
              <SELECT CLASS="combomini" NAME="sel_year_start" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> loadDailyMeetings();checkAvailability(); <% } %>"><OPTION VALUE="2011">2011</OPTION><OPTION VALUE="2012">2012</OPTION><OPTION VALUE="2013">2013</OPTION><OPTION VALUE="2014">2014</OPTION><OPTION VALUE="2015">2015</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_h_start" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> checkAvailability(); <% } %>"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_m_start" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> checkAvailability(); <% } %>"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain">End Date</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">
              <INPUT TYPE="hidden" NAME="dt_end" VALUE="<% out.write(oActy.isNull(DB.dt_end) ? "" : oActy.getDateTime24(DB.dt_end)); %>">
              <SELECT CLASS="combomini" NAME="sel_day_end" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> loadDailyMeetings();checkAvailability(); <% } %>"><% for (int d=1; d<=31; d++) out.write("<OPTION VALUE=\""+Gadgets.leftPad(String.valueOf(d),'0',2)+"\">"+Gadgets.leftPad(String.valueOf(d),'0',2)+"</OPTION>"); %></SELECT>
              <SELECT CLASS="combomini" NAME="sel_month_end" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> loadDailyMeetings();checkAvailability(); <% } %>"><% for (int m=0; m<=11; m++) out.write("<OPTION VALUE=\""+(m<9 ? "0" : "")+String.valueOf(m+1)+"\">"+Calendar.MonthName(m, sLanguage)+"</OPTION>"); %></SELECT>
              <SELECT CLASS="combomini" NAME="sel_year_end" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> loadDailyMeetings();checkAvailability(); <% } %>"><OPTION VALUE="2010">2010</OPTION><OPTION VALUE="2011">2011</OPTION><OPTION VALUE="2012">2012</OPTION><OPTION VALUE="2013">2013</OPTION><OPTION VALUE="2014">2014</OPTION><OPTION VALUE="2015">2015</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_h_end" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> checkAvailability(); <% } %>"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_m_end" onchange="<% if (((iAppMask & (1<<CollaborativeTools))!=0)) { %> checkAvailability(); <% } %>"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Location</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <INPUT TYPE="hidden" NAME="gu_address" VALUE="<%=oActy.getStringNull(DB.gu_address,"")%>">
              <SELECT NAME="sel_address" CLASS="combomini"><OPTION VALUE=""></OPTION><%=sAddrLookUp%></SELECT>&nbsp;
              <A HREF="../common/addr_list.jsp?linktable=k_meetings_lookup&linkfield=gu_owner&linkvalue=<%=gu_workarea%>&noreload=1"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Locations"></A>
            </TD>
          </TR>
<%      if (((iAppMask & (1<<Hipermail))!=0) && ((iAppMask & (1<<WebBuilder))!=0)) {
          if (oActy.isNull(DB.gu_mailing) && oActy.isNull(DB.gu_pageset)) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain"><INPUT TYPE="checkbox" NAME="chk_emailing" VALUE="1" onclick="document.getElementById('emailopts').style.display=this.checked ? 'block' : 'none'"></TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">e-mailing required</TD>
          </TR>
<%        } else if (!oActy.isNull(DB.gu_mailing)) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain"><INPUT TYPE="hidden" NAME="chk_emailing" VALUE="1"></TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain"><A HREF="../webbuilder/adhoc_mailing_edit.jsp?gu_mailing=<%=oActy.getString(DB.gu_mailing)%>&gu_workarea=<%=gu_workarea%>&id_domain=<%=id_domain%>">Edit e-mailing</A></TD>
          </TR>
<%        } else if (!oActy.isNull(DB.gu_pageset)) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain"><INPUT TYPE="hidden" NAME="chk_emailing" VALUE="1"></TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain"><A HREF="../webbuilder/pageset_change.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&doctype=newsletter&gu_pageset=<%=oActy.getString(DB.gu_pageset)%>">Edit e-mailing</A></TD>
          </TR>
<%        } %>
          <TR>
            <TD ALIGN="right" WIDTH="160"></TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">
              <DIV ID="emailopts" NAME="emailopts" STYLE="display:none">
              <INPUT TYPE="checkbox" NAME="bo_urgent" VALUE="1" <% if (!oAdhm.isNull(DB.bo_urgent)) out.write(oAdhm.getShort("bo_urgent")==0 ? "" : "CHECKED"); %>>&nbsp;E-mail urgente
              <BR/>
              Requested sent date:<BR/>
              <INPUT TYPE="hidden" NAME="dt_execution" VALUE="<% out.write(oAdhm.isNull(DB.dt_execution) ? (oActy.isNull(DB.dt_mailing) ? "" : oActy.getDateShort(DB.dt_mailing)) : oAdhm.getDateShort(DB.dt_execution)); %>">
              <SELECT CLASS="combomini" NAME="sel_day"><% for (int d=1; d<=31; d++) out.write("<OPTION VALUE=\""+Gadgets.leftPad(String.valueOf(d),'0',2)+"\">"+Gadgets.leftPad(String.valueOf(d),'0',2)+"</OPTION>"); %></SELECT>
              <SELECT CLASS="combomini" NAME="sel_month"><OPTION VALUE="01">Enero</OPTION><OPTION VALUE="02">Febrero</OPTION><OPTION VALUE="03">Marzo</OPTION><OPTION VALUE="04">Abril</OPTION><OPTION VALUE="05">Mayo</OPTION><OPTION VALUE="06">Junio</OPTION><OPTION VALUE="07">Julio</OPTION><OPTION VALUE="08">Agosto</OPTION><OPTION VALUE="09">Septiembre</OPTION><OPTION VALUE="10">Octubre</OPTION><OPTION VALUE="11">Noviembre</OPTION><OPTION VALUE="12">Diciembre</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_year"><OPTION VALUE="2009">2009</OPTION><OPTION VALUE="2010">2010</OPTION><OPTION VALUE="2011">2011</OPTION><OPTION VALUE="2012">2012</OPTION><OPTION VALUE="2013">2013</OPTION><OPTION VALUE="2014">2014</OPTION></SELECT>
              &nbsp;<INPUT TYPE="checkbox" NAME="bo_reminder" VALUE="1" <% if (!oAdhm.isNull(DB.bo_reminder)) out.write(oAdhm.getShort("bo_reminder")==0 ? "" : "CHECKED"); %>>&nbsp;Con recordatorio
              <BR/>
              <INPUT TYPE="hidden" NAME="tx_email_from" VALUE="<%=oActy.getStringNull(DB.tx_email_from,"")%>">
              Sender E-mail:&nbsp;<SELECT CLASS="combomini" NAME="sel_email_from"><OPTION VALUE=""></OPTION><%=sMailLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Senders"></A>
              <BR/>
              <INPUT TYPE="hidden" NAME="nm_from" VALUE="<%=oActy.getStringNull(DB.nm_from,"")%>">
              Display-Name:&nbsp;<SELECT CLASS="combomini" NAME="sel_from"><OPTION VALUE=""></OPTION><%=sFromLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Senders"></A>
              <BR/>
              <TABLE><TR><TD CLASS="formplain">
              Subject:</TD><TD><INPUT TYPE="text" NAME="tx_subject" CLASS="combomini" MAXLENGTH="254" SIZE="50" VALUE="<%=oActy.getStringHtml(DB.tx_subject,"")%>">
              </TD></TR><TR><TD CLASS="formplain">
              URL:</TD><TD><INPUT TYPE="text" NAME="url_activity" CLASS="combomini" MAXLENGTH="254" SIZE="50"  VALUE="<%=oActy.getStringNull(DB.url_activity,"")%>">
              </TD></TR>
              <TR><TD CLASS="formplain">
              Template:</TD>
              <TD>
<% if (!oActy.isNull(DB.gu_mailing)) { %>
                	<SELECT CLASS="combomini" NAME="id_template"><OPTION VALUE="adhoc" SELECTED="selected">Ad Hoc</OPTION></SELECT>
<% } else if (!oActy.isNull(DB.gu_pageset)) { %>
                	<SELECT CLASS="combomini" NAME="id_template"><% for (int t=0; t<iTmpl; t++) if (gu_microsite.equals(oTmpl.getString(1,t))) out.write("<OPTION VALUE=\""+oTmpl.getString(0,t)+","+oTmpl.getString(1,t)+","+oTmpl.getString(2,t).replace('/',cSep).replace('\\',cSep)+"\" SELECTED=\"selected\">"+oTmpl.getString(0,t)+"</OPTION>"); %></SELECT>
<% } else { %>
                	<SELECT CLASS="combomini" NAME="id_template"><OPTION VALUE="adhoc">Ad Hoc</OPTION><% for (int t=0; t<iTmpl; t++) out.write("<OPTION VALUE=\""+oTmpl.getString(0,t)+","+oTmpl.getString(1,t)+","+oTmpl.getString(2,t).replace('/',cSep).replace('\\',cSep)+"\">"+oTmpl.getString(0,t)+"</OPTION>"); %></SELECT>
<% } %>
              </TD></TR><TR><TD CLASS="formplain">
              Recipients</TD><TD><SELECT CLASS="textsmall" NAME="sel_lists" SIZE="10" STYLE="width:340px" MULTIPLE><% for (int l=0; l<iLsts; l++) out.write("<OPTION VALUE=\""+oLsts.getString(0,l)+"\" "+(oRcps.find(0,oLsts.getString(0,l))>=0 ? "SELECTED" : "")+">"+oLsts.getStringNull(1,l,oLsts.getStringNull(2,l,"n/a"))+"</OPTION>"); %></SELECT>
              </TD></TR></TABLE>
              </DIV>
            </TD>
          </TR>
<% }
   if (((iAppMask & (1<<CollaborativeTools))!=0)) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain"><INPUT TYPE="checkbox" NAME="chk_meeting" VALUE="1" onclick="document.getElementById('meetopts').style.display=this.checked ? 'block' : 'none'" <% if (!oActy.isNull(DB.gu_meeting)) out.write("CHECKED"); %>></TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">Add to Calendar</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"></TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">
              <DIV ID="meetopts" NAME="meetopts" STYLE="display:<% if (oActy.isNull(DB.gu_meeting)) out.write("none"); else out.write("block"); %>">
                <TABLE>
                  <TR>
                    <TD><FONT CLASS="formplain">Type:</FONT></TD>
                    <TD>
                      <INPUT TYPE="hidden" NAME="tp_meeting">
                      <SELECT CLASS="combomini" NAME="sel_tp_meeting"><OPTION VALUE=""></OPTION><OPTION VALUE="meeting">Meeting</OPTION><OPTION VALUE="call">Call</OPTION><OPTION VALUE="followup">Follow-up</OPTION><OPTION VALUE="breakfast">Breakfast<OPTION VALUE="lunch">Lunch</OPTION><OPTION VALUE="course">Course</OPTION><OPTION VALUE="demo">Demo</OPTION><OPTION VALUE="workshop">Journey<OPTION VALUE="congress">Congress</OPTION><OPTION VALUE="tradeshow">Tradeshow</OPTION><OPTION VALUE="bill">Send Invoice</OPTION><OPTION VALUE="pay">Pay</OPTION><OPTION VALUE="holidays">Holydays</OPTION></SELECT>
                    </TD>
                  </TR>
                	<TR><TD VALIGN="top" CLASS="formplain">
                  Guests:</TD><TD>
                  <SELECT NAME="sel_fellows" CLASS="textsmall" SIZE="4" STYLE="width:340px" MULTIPLE>
                    <OPTION VALUE=""></OPTION><%
                    for (int f=0; f<iFllws; f++) {
		                  out.write("<OPTION VALUE=\"" + oFllws.getString(0,f) + "\">"+oFllws.getStringNull(1,f,"")+" "+oFllws.getStringNull(2,f,"")+"</OPTION>");
	                  }
	                  %></SELECT>
                  </TD></TR>
                	<TR><TD VALIGN="top" CLASS="formplain">
                  Resources:</TD><TD>
                  <SELECT NAME="sel_rooms" CLASS="textsmall" SIZE="4" STYLE="width:340px" onChange="showComments();checkAvailability();" MULTIPLE>
                    <OPTION VALUE=""></OPTION><%
								    oConn = GlobalDBBind.getConnection(PAGE_NAME,true);
                    for (int r=0; r<iRooms; r++) {
		                  out.write("<OPTION VALUE=\"" + oRooms.getString(0,r) + "\">");
		                  if (!oRooms.isNull(DB.tp_room,r)) {
		                    String sTrTp = DBLanguages.getLookUpTranslation(oConn, DB.k_rooms_lookup, gu_workarea, "tp_room", sLanguage, oRooms.getString(DB.tp_room,r));
		                    if (sTrTp!=null) out.write(sTrTp + " ");
		                  }
		                  out.write(oRooms.getString(0,r) + "</OPTION>");
	                  }
	                  oConn.close(PAGE_NAME); %></SELECT>
	                  <BR/>
	                  <TEXTAREA ROWS="2" CLASS="textsmall" NAME="read_comments" STYLE="border-style:none;width:340px" TABINDEX="-1" onfocus="document.forms[0].sel_rooms.focus()"></TEXTAREA>
                  </TD></TR>
                </TABLE>
              </DIV>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain">Capacity</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="textsmall">
            	<INPUT TYPE="text" NAME="nu_capacity" MAXLENGTH="9" SIZE="4" VALUE="<% if (!oActy.isNull(DB.nu_capacity)) out.write(String.valueOf(oActy.getInt(DB.nu_capacity))); %>" onkeypress="return acceptOnlyNumbers();">
            	<% if (oCnts.sum(0)!=null) { %> &nbsp;Guests&nbsp;<%=oCnts.sum(0)%>&nbsp;&nbsp; <% } %>
            	<% iConf = oCnts.find(1, new Short(ActivityAudience.CONFIRMED)); if (iConf>=0) out.write("&nbsp;Confirmed&nbsp;"+String.valueOf(oCnts.getInt(0,iConf))); %>&nbsp;&nbsp;
            	<% iConf = oCnts.find(1, new Short(ActivityAudience.REFUSED)); if (iConf>=0) out.write("&nbsp;Will not go&nbsp;"+String.valueOf(oCnts.getInt(0,iConf))); %>
            </TD>				
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Language</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
            	<SELECT NAME="id_language" CLASS="combomini"><OPTION VALUE=""></OPTION><%=sLangsList%></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160" CLASS="formplain">List Price</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain"><INPUT TYPE="text" NAME="pr_sale" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oActy.isNull(DB.pr_sale)) out.write(String.valueOf(oActy.getDecimal(DB.pr_sale))); %>">
            &nbsp;&nbsp;&nbsp;&nbsp;Discount Price&nbsp;<INPUT TYPE="text" NAME="pr_discount" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oActy.isNull(DB.pr_discount)) out.write(String.valueOf(oActy.getDecimal(DB.pr_discount))); %>"></TD>
          </TR>
<%    if (iAttc>0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Files</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <TABLE SUMMARY="Activity Attachments">
              <% for (int a=0; a<iAttc; a++) {
                   out.write("                <TR><TD><DIV ID=\"a"+String.valueOf(iAttc)+"\"><A CLASS=\"linksmall\" HREF=\"../servlet/HttpBinaryServlet?id_product="+oAttc.getString(0,a)+"&id_user="+id_user+"\" onContextMenu=\"return false;\">"+oAttc.getString(1,a)+"</A></DIV></TD><TD><A HREF=\"#\" TITLE=\"Delete\" onclick=\"deleteAttachment("+String.valueOf(iAttc)+")\"><DIV ID=\"d"+String.valueOf(iAttc)+"\"><IMG SRC=\"../images/images/delete.gif\" WIDTH=\"13\" HEIGHT=\"13\" BORDER=\"0\" ALT=\"Delete\"></A></DIV></TD></TR>\n");
                 }
              %>
              </TABLE>
            </TD>
          </TR>
<%    } %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Attach File</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <INPUT TYPE="file" NAME="nm_attachment" SIZE="50">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formstrong">Labels</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <OL>                
                <LI ID="facebook-list" CLASS="input-text">
                  <INPUT TYPE="text" VALUE="" ID="facebook-demo" />
                  <DIV ID="facebook-auto">        
                    <DIV CLASS="default">Enter the labels that you want to assign to the activity</DIV> 
                    <UL CLASS="feed"><%
                    	for (int t=0; t<iTags; t++)
                    	  out.write("<LI VALUE=\""+oTags.getString(0,t)+"\">"+oTags.getString(0,t)+"</LI>");
                    %></UL>
                  </DIV>                
                </LI>
              </OL>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formstrong">Description</FONT></TD>
            <TD ALIGN="left" WIDTH="480"><TEXTAREA NAME="de_activity" ROWS="2" COLS="50"><%=oActy.getStringNull("de_activity","")%></TEXTAREA></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formstrong">Comments</FONT></TD>
            <TD ALIGN="left" WIDTH="480"><TEXTAREA NAME="tx_comments" ROWS="2" COLS="50"><%=oActy.getStringNull("tx_comments","")%></TEXTAREA></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
<SCRIPT TYPE="text/javascript">
  <!--
  document.observe('dom:loaded', function() { tlist2 = new FacebookList('facebook-demo', 'facebook-auto',{fetchFile:'activity_tags_json.jsp'}); });
  //-->
  </SCRIPT>
</HTML>
