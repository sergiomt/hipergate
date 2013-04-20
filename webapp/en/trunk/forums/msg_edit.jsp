<%@ page import="java.util.Date,java.util.Iterator,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.forums.NewsMessage,com.knowgate.forums.NewsMessageTag,com.knowgate.hipergate.Product,com.knowgate.hipergate.ProductLocation" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 

/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  String sSkin = getCookie(request, "skin", "xp");
  String sUserId = getCookie(request, "userid", "default");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));  
    
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_msg = request.getParameter("gu_msg");
  String gu_newsgrp = request.getParameter("gu_newsgrp");
  String gu_parent_msg = nullif(request.getParameter("gu_parent_msg"));
  String gu_thread_msg = "";
  String tx_subject = "";
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
  
  String sStatusLookUp = "";

  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd");
    
  JDCConnection oConn = GlobalDBBind.getConnection("msg_edit");  
  ACLUser oUsr = new ACLUser();
  NewsMessage oMsg = new NewsMessage();
  NewsMessage oParent;
  Product oProd = null;
  DBSubset oLoca = null;
  DBSubset oTags = null;
  int nTags = 0, nLoca = 0;
  Short oBinaries = new Short ((short)1);

  try {

    oBinaries = DBCommand.queryShort(oConn, "SELECT "+DB.bo_binaries+" FROM "+DB.k_newsgroups+" WHERE "+DB.gu_newsgrp+"='"+gu_newsgrp+"'");
  
    if (null!=gu_msg) {      
      oMsg.load(oConn, new Object[]{gu_msg});
      if (null==oBinaries) oBinaries = new Short ((short)1);
      gu_parent_msg = oMsg.getStringNull(DB.gu_parent_msg,"");
      gu_thread_msg = oMsg.getStringNull(DB.gu_thread_msg,"");
      tx_subject = oMsg.getStringNull(DB.tx_subject,"");
      if (oBinaries.shortValue()!=(short)0 && !oMsg.isNull(DB.gu_product)) {
        oProd = new Product(oConn, oMsg.getString(DB.gu_product));
        oLoca = oProd.getLocations(oConn);
        nLoca = oLoca.getRowCount();
      } // fi
    } // fi

    if (!oUsr.load(oConn, new Object[]{sUserId})) throw new SQLException("User "+sUserId+" not found");
    
    oTags = GlobalCacheClient.getDBSubset("NewsGroupTags["+gu_newsgrp+"]");
    if (null==oTags) {
      oTags = new DBSubset(DB.k_newsgroup_tags, DB.gu_tag+","+DB.tl_tag, DB.gu_newsgrp+"=? ORDER BY 2", 30);
      nTags = oTags.load(oConn, new Object[]{gu_newsgrp});
    } else {
      nTags = oTags.getRowCount();
    }
    
    if (gu_parent_msg.length()>0) {
      oParent = new NewsMessage();
      oParent.load(oConn, new Object[]{gu_parent_msg});
      gu_thread_msg = oParent.getString(DB.gu_thread_msg);
      if (tx_subject.length()==0) tx_subject = oParent.getStringNull(DB.tx_subject,"");
      if (!tx_subject.startsWith("Re: ")) tx_subject = "Re: " + tx_subject;
    }
    
    oConn.close("msg_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("msg_edit");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  oConn = null;

	sendUsageStats(request, "msg_edit");  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Write Message</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
            
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        var tgs = frm.sel_tags.options;
        var txt;

	      if (!isDate(frm.dt_published.value, "d") && frm.dt_published.value.length>0) {
      	  alert ("Publish date is not valid");
      	  return false;	  
      	}
        
	      if (!isDate(frm.dt_expire.value, "d") && frm.dt_expire.value.length>0) {
      	  alert ("End date is not vald結束日期無效");
      	  return false;	  
      	}
       
	      if (!isDate(frm.dt_start.value, "d") && frm.dt_start.value.length>0) {
      	  alert ("Start date is not valid");
      	  return false;	  
      	}

	      if (isDate(frm.dt_expire.value, "d")) {
	        if (isDate(frm.dt_start.value, "d")) {
      	    if (parseDate(frm.dt_expire.value, "d")<parseDate(frm.dt_start.value, "d")) {
      	      alert ("End date must by later than Start date");
      	      return false;	        	  
      	    }
      	  }
      	  if (parseDate(frm.dt_expire.value+" 23:59:59", "ts")<new Date()) {
      	    alert ("End date must by later than Start date");
      	    return false; 	
      	  }
        }

      	txt = frm.tx_subject.value;
      	
      	if (txt.length==0) {
      	  alert ("Subject is mandatory");
      	  return false;	  
      	}
      
      	if (txt.indexOf("'")>=0) {
      	  alert ("Subject contains forbidden characters");
      	  return false;	  
      	}

				frm.tx_tags.value = "";
				for (var t=0;t<tgs.length; t++) {
				  if (tgs[t].selected) {
				    frm.tx_tags.value += (frm.tx_tags.value.length==0 ? "" : ",") + tgs[t].value.trim();
				  } // fi
				}	// next
				
        return true;
      } // validate;

      // ------------------------------------------------------

      function addTag() {
        var frm = window.document.forms[0];
        var ttl = window.prompt("Type the name for the new tag","");
        if (ttl) {
        	ttl = ttl.trim();
          var tgs = frm.sel_tags.options;
          var len = tgs.length;
          for (var t=0; t<len; t++) {
            if (tgs[t].value.toUpperCase()==ttl.toUpperCase()) {
              alert ("Another tag with the same name already exists");
              tgs[t].selected=true;
              return false;
            } // fi
          } // next
          var tgu = httpRequestText("forum_tag_add.jsp?gu_newsgroup=<%=gu_newsgrp%>&tl_tag="+escape(ttl));
          comboPush (frm.sel_tags, ttl, tgu, false, true);
          sortCombo (frm.sel_tags);
			  }
			} // addTag
			
    //-->
  </SCRIPT>

  <SCRIPT TYPE="text/javascript">
  <!--
  	var _editor_url = "../javascript/htmlarea/";
  	var _editor_lang = "<%=sLanguage%>";

  	window.onload = function() {
    	var frm = document.forms[0];
    	var idx;

			editor = new HTMLArea("tx_msg");
			editor.config.statusBar = false;
			editor.config.toolbar = [
				[
			  "bold", "italic", "underline", "separator",
			  "insertorderedlist", "insertunorderedlist", "outdent", "indent", "separator",
			  "inserthorizontalrule", "createlink", "inserttable", "insertimage", "separator",
			  "htmlmode",
			  ]
			];
			editor.generate();

<%
		  Iterator iTags = oMsg.tags().keySet().iterator();
      while (iTags.hasNext()) {
        NewsMessageTag oTag = (NewsMessageTag) oMsg.tags().get(iTags.next());
        out.write("      idx = comboIndexOf(frm.sel_tags,\""+oTag.getString(DB.gu_tag)+"\");\n");
        out.write("      if (idx>0) frm.sel_tags.options[idx].selected = true;\n");
      } // wend
      
      if (!oMsg.isNull(DB.dt_expire)) {
        if (oMsg.getDate(DB.dt_expire).compareTo(new Date())<0) {
          out.write("      setCombo(frm.id_status,\"3\");\n");
        } else if (!oMsg.isNull(DB.id_status)) {
          out.write("      setCombo(frm.id_status,\""+String.valueOf(oMsg.getShort(DB.id_status))+"\");\n");        
        }
      } else if (!oMsg.isNull(DB.id_status)) {
          out.write("      setCombo(frm.id_status,\""+String.valueOf(oMsg.getShort(DB.id_status))+"\");\n");        
      }      

			Date dtPub;
      if (oMsg.isNull(DB.dt_published))
        dtPub = new Date();
      else
      	dtPub = oMsg.getDate(DB.dt_published);
      out.write("      setCombo(frm.dt_hour,\""+String.valueOf(dtPub.getHours())+"\");\n");        
      out.write("      setCombo(frm.dt_min,\""+String.valueOf(dtPub.getMinutes())+"\");\n");        
      out.write("      setCombo(frm.dt_sec,\""+String.valueOf(dtPub.getSeconds())+"\");\n");        
%>
  	}

    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" TYPE="text/javascript" SRC="../javascript/htmlarea/htmlarea.js"></SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" >
    <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
    </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Write Message</FONT></TD></TR>
  </TABLE>  
  <FORM ENCTYPE="multipart/form-data" METHOD="post" ACTION="msg_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_msg" VALUE="<%=nullif(gu_msg)%>">
    <INPUT TYPE="hidden" NAME="gu_newsgrp" VALUE="<%=gu_newsgrp%>">
    <INPUT TYPE="hidden" NAME="gu_parent_msg" VALUE="<%=gu_parent_msg%>">
    <INPUT TYPE="hidden" NAME="gu_thread_msg" VALUE="<%=gu_thread_msg%>">
    <INPUT TYPE="hidden" NAME="id_language" VALUE="<%=sLanguage%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=sUserId%>">    
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=sUserId%>">
    <INPUT TYPE="hidden" NAME="nm_author" VALUE="<%=(oUsr.getStringNull(DB.nm_user,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname2,"")).trim()%>">
    <INPUT TYPE="hidden" NAME="tx_email" VALUE="<%=oUsr.getStringNull(DB.tx_main_email,"")%>">
    <INPUT TYPE="hidden" NAME="tx_tags" VALUE="">
    <CENTER>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formstrong">From:</FONT></TD>
            <TD ALIGN="left" CLASS="textplain"><%=(oUsr.getStringNull(DB.nm_user,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname2,"")).trim()%></TD>
            <TD ALIGN="left"><FONT CLASS="formplain">Tags:</FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formplain">Group</FONT></TD>
            <TD ALIGN="left" CLASS="textplain"><% out.write(request.getParameter("nm_newsgrp")); %></TD>
            <TD ALIGN="left" CLASS="textplain" ROWSPAN="5" VALIGN="top">
            	<SELECT NAME="sel_tags" SIZE="7" MULTIPLE><%
            	  for (int t=0; t<nTags; t++) {
            	    out.write("<OPTION VALUE=\""+oTags.getString(0,t)+"\">"+oTags.getString(1,t)+"</OPTION>");
            	  }
            	%></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formplain">Date when Published</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="dt_published" MAXLENGTH="10" SIZE="10" VALUE="<% if (oMsg.isNull(DB.dt_published)) out.write(oFmt.format(new Date())); else out.write(oFmt.format(oMsg.getDate(DB.dt_published))); %>">
              <A HREF="javascript:showCalendar('dt_published')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
              &nbsp;&nbsp;
              <SELECT NAME="dt_hour"><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              :<SELECT NAME="dt_min"><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="29">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="39">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="49">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="59">59</OPTION></SELECT>
              :<SELECT NAME="dt_sec"><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="29">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="39">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="49">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="59">59</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formplain">Start been visible at date:</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="10" VALUE="<% if (oMsg.isNull(DB.dt_start)) out.write(oFmt.format(new Date())); else out.write(oFmt.format(oMsg.getDate(DB.dt_start))); %>">
              <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
              &nbsp;&nbsp;&nbsp;&nbsp;
              <FONT CLASS="formplain">Expiration date:</FONT>
              &nbsp;
              <INPUT TYPE="text" NAME="dt_expire" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oMsg.isNull(DB.dt_expire)) out.write(oFmt.format(oMsg.getDate(DB.dt_expire))); %>">
              <A HREF="javascript:showCalendar('dt_expire')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formplain">Status:</FONT></TD>
            <TD ALIGN="left">
            	<SELECT NAME="id_status"><OPTION VALUE="0" SELECTED="selected">Published</OPTION><OPTION VALUE="1">Pending</OPTION><OPTION VALUE="2">Not approved</OPTION><OPTION VALUE="3">Expired</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="left" WIDTH="160px"><FONT CLASS="formplain">Subject:</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="tx_subject" MAXLENGTH="254" SIZE="64" VALUE="<%=tx_subject%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="left"><FONT CLASS="formplain">Format:</FONT></TD>
            <TD ALIGN="left">
            	<SELECT NAME="id_msg_type"><OPTION VALUE="HTM" SELECTED="selected">HTML</OPTION><OPTION VALUE="TXT">Texto</OPTION></SELECT>
              &nbsp;&nbsp;<A CLASS="linkplain" HREF="#" onclick="window.open('file_listing.jsp', 'file_listing', 'directories=no,toolbar=no,menubar=no,width=760,height=580')">Ver galer&iacute;a de im&aacute;genes y archivos</A>
            </TD>
            <TD ALIGN="left">
            	<A HREF="#" onclick="addTag()" CLASS="linkplain">Add tag</A>
            	&nbsp;&nbsp;&nbsp;
            	<A HREF="#" CLASS="linkplain">Edit tags</A>
            </TD>
          </TR>
        </TABLE>
        <TABLE CLASS="formfront">
          <TR>
	          <TD COLSPAN="2" ALIGN="left"><TEXTAREA CLASS="textcode" NAME="tx_msg" ID="tx_msg" ROWS="<% out.write(String.valueOf(floor(8f*fScreenRatio*1.4f))); %>" COLS="<% out.write(String.valueOf(floor(87f*fScreenRatio))); %>"><%=oMsg.getStringNull(DB.tx_msg,"")%></TEXTAREA></TD>
          </TR>
<% if (oBinaries.shortValue()!=(short) 0) { %>
          <TR>
	    <TD COLSPAN="2" CLASS="formplain">
	    	<TABLE SUMMARY="Attachments">
	        <TR><TD CLASS="formplain">File 1:</TD><TD><INPUT TYPE="file" NAME="attach1"></TD><TD CLASS="formplain">File 2:</TD><TD><INPUT TYPE="file" NAME="attach2"></TD></TR>
	        <TR><TD></TD><TD><% if (nLoca>0) { out.write ("<A CLASS=\"linkplain\" HREF=\"../servlet/HttpBinaryServlet?id_product="+oLoca.getString(DB.gu_product,0)+"&id_location="+oLoca.getString(DB.gu_location,0)+"&id_user="+sUserId+"\">"+oLoca.getStringNull(DB.xfile,0,"N/A")+"</A>"); } %></TD><TD></TD><TD><% if (nLoca>1) { out.write ("<A CLASS=\"linkplain\" HREF=\""+oLoca.getStringNull(DB.xfile,1,"N/A")+"\">"+oLoca.getStringNull(DB.xfile,1,"N/A")+"</A>"); } %></TD></TR>
	        <TR><TD CLASS="formplain">File 3:</TD><TD><INPUT TYPE="file" NAME="attach3"></TD><TD CLASS="formplain">File 4:</TD><TD><INPUT TYPE="file" NAME="attach4"></TD></TR>
	        <TR><TD></TD><TD><% if (nLoca>2) { out.write ("<A CLASS=\"linkplain\" HREF=\""+oLoca.getStringNull(DB.xfile,2,"N/A")+"\">"+oLoca.getStringNull(DB.xfile,2,"N/A")+"</A>"); } %></TD><TD></TD><TD><% if (nLoca>3) { out.write ("<A CLASS=\"linkplain\" HREF=\""+oLoca.getStringNull(DB.xfile,3,"N/A")+"\">"+oLoca.getStringNull(DB.xfile,3,"N/A")+"</A>"); } %></TD></TR>	        
	      </TABLE>
	    </TD>
          </TR>                    
<% } %>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton"  TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>
    </CENTER>
  </FORM>
</BODY>
</HTML>
