<%@ page import="java.util.HashMap,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Category" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
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
 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "default");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String gu_user = getCookie (request, "userid", null);

  String gu_shop = request.getParameter("gu_shop");
  String gu_top_parent = request.getParameter("top_parent_cat");
    
  // **********************************************

  String sDefWrkArGet = request.getRequestURI();
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet + "/workareas";
    
  String sWrkArGet = Gadgets.chomp(Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasget", sDefWrkArGet),'/');

  Category oCurrentCat;
  StringBuffer oCatSelect = new StringBuffer();
  int iCatChlds = 0;
  DBSubset oCatChlds = new DBSubset (DB.k_cat_expand + " e," + DB.k_categories + " c",
                                     "e." + DB.gu_category + ",c." + DB.nm_category + ",e." + DB.od_level + ",e." + DB.od_walk + ",e." + DB.gu_parent_cat,
    				     "e." + DB.gu_category + "=c." + DB.gu_category + " AND e." + DB.gu_rootcat + "='" + gu_top_parent + "' AND e." + DB.gu_category + "<>'" + gu_top_parent + "' ORDER BY e." + DB.od_walk, 50);

  DBSubset oImages = new DBSubset (DB.k_cat_expand + " e," + DB.k_images + " i," + DB.k_x_cat_objs + " x",
  				   "e." + DB.gu_category + ",i." + DB.gu_image + ",i." + DB.nm_image,
    		                   "e." + DB.gu_category + "=x." + DB.gu_category + " AND x." + DB.gu_object + "=i." + DB.gu_image + " AND e." + DB.gu_rootcat + "='" + gu_top_parent + "' AND x." + DB.id_class + "=13", 50);
  int iImages = 0;
  HashMap oImageMap = new HashMap();
  
  JDCConnection oConn = null;  
  
  try {

    oConn = GlobalDBBind.getConnection("cat_fastedit");  

    iCatChlds = oCatChlds.load(oConn);
    
    iImages = oImages.load(oConn);
    
    for (int g=0; g< iImages; g++) {
      oImageMap.put (oImages.getString(0,g), oImages.getString(2,g));
    }
    
    oCurrentCat = new Category ();
        		        
    oCatSelect.append ("<OPTION VALUE=\"" + gu_top_parent + "\">ROOT</OPTION>");

    for (int p=0; p<iCatChlds; p++) {

      if (oCatChlds.getInt(2,p)>1) {

        oCurrentCat.replace (DB.gu_category, oCatChlds.getString(0,p));
		    
        oCatSelect.append ("<OPTION VALUE=\"" + oCatChlds.getString(0,p) + "\">");

        // Indent category names
        for (int s=1; s<oCatChlds.getInt(2,p); s++) out.write("&nbsp;&nbsp;&nbsp;&nbsp;");

    
        // Category name
        oCatSelect.append (nullif(oCurrentCat.getLabel(oConn, sLanguage), oCatChlds.getString(1,p)));
                            
       oCatSelect.append ("</OPTION>");
       } // fi (od_level>1)
     } // next (p)

  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("instancelisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <TITLE>Categories fast edit</TITLE>
  <SCRIPT LANGUAGE="text/javascript">
  <!--
    function validate () {
      var frm = document.forms[0];
      var cnt = parseInt(frm.nu_images.value);
      var gu, es, en, ds, dn;
      
      for (var i=0; i<cnt; i++) {
        eval ("gu = frm.gu_category" + String(i) + ".value");
        eval ("es = frm.tr_es" + String(i) + ".value");
        eval ("en = frm.tr_en" + String(i) + ".value");
        eval ("ds = frm.de_es" + String(i) + ".value");
        eval ("dn = frm.de_en" + String(i) + ".value");
        
        if (gu.length>0) {
          if ((es.length==0) && (en.length==0)) {
            alert ("Category title is mandatory");
            return false;
          }
          
          if (getCombo(frm["parent"+String(i)])==gu) {
            alert ("Category may not be parent of itself");
            return false;
          }
        }

        if ((ds.length>254) || (dn.length>254)) {
          alert ("Category description " + (es!=null ? es : en) + " cannot be longer than 254 characters");
          return false;
        }
      } // next (i)

      return true;

    } // validate
    
    function setCombos() {
      var frm = document.forms[0];
      
<%    for (int c=0; c<iCatChlds; c++)
	out.write ("      setCombo (frm.parent" + String.valueOf(c) + ", \"" + oCatChlds.getString(4,c) + "\");\n");
%>
    }
    
  //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">
    <TABLE><TR><TD WIDTH="98%" CLASS="striptitle"><FONT CLASS="title1">Categories fast edit</FONT></TD></TR></TABLE>
    <FORM METHOD="post" ENCTYPE="multipart/form-data" ACTION="cat_fastedit_store.jsp" onsubmit="return validate()">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="gu_shop" VALUE="<%=gu_shop%>">
      <INPUT TYPE="hidden" NAME="top_parent_cat" VALUE="<%=gu_top_parent%>">
      <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=gu_user%>">      
      <INPUT TYPE="hidden" NAME="nu_images" VALUE="<% out.write(String.valueOf(iCatChlds+4)); %>">
      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Parent</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Spanish</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>English</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Image</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" COLSPAN="2"><B>Delete</B></TD>
<%
          oCurrentCat = new Category();
          
          PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.id_language + "," + DB.tr_category + "," + DB.de_category + " FROM " + DB.k_cat_labels + " WHERE " + DB.gu_category + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

          ResultSet oRSet;
    
	  String sCatId, sCatEn, sCatEs, sCatDeEn, sCatDeEs, sStrip, sIndex;
	  for (int i=0; i<iCatChlds; i++) {
	  
            sCatId = oCatChlds.getString(0,i);            
            sStrip = String.valueOf(i%2+1);
            sIndex = String.valueOf(i);
	    sCatEn = "";
	    sCatEs = "";
	    sCatDeEs = "";
	    sCatDeEn = "";
	    
            oStmt.setString(1, sCatId);
            
            oRSet = oStmt.executeQuery();

	    while (oRSet.next()) {	      
	      if (oRSet.getString(1).equals("es")) {
	        sCatEs = nullif(oRSet.getString(2));
	        sCatDeEs = nullif(oRSet.getString(3));
	      }
	      else if (oRSet.getString(1).equals("en")) {
	        sCatEn = nullif(oRSet.getString(2));
	        sCatDeEn = nullif(oRSet.getString(3));
	      }
	    }  // wend
	    
	    oRSet.close();
	    
	    oCurrentCat.replace(DB.gu_category, sCatId);  
%>            
            <TR>
              <INPUT NAME="gu_category<% out.write(sIndex); %>" TYPE="hidden" VALUE="<% out.write(sCatId); %>">
              <INPUT NAME="nm_category<% out.write(sIndex); %>" TYPE="hidden" VALUE="<% out.write(oCatChlds.getString(1,i)); %>">
              <TD CLASS="strip<% out.write (sStrip); %>"><SELECT NAME="parent<% out.write(sIndex); %>" CLASS="combomini"><% out.write(oCatSelect.toString()); %></SELECT></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" WIDTH="8"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/flags/es.gif" WIDTH="22" HEIGHT="11" BORDER="0"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><INPUT NAME="tr_es<% out.write(sIndex); %>" TYPE="text" MAXLENGTH="50" SIZE="20" CLASS="combomini" VALUE="<% out.write (sCatEs); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" WIDTH="8"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/flags/en.gif" WIDTH="22" HEIGHT="11" BORDER="0"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><INPUT NAME="tr_en<% out.write(sIndex); %>" TYPE="text" MAXLENGTH="50" SIZE="20" CLASS="combomini" VALUE="<% out.write (sCatEn); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" WIDTH="8"></TD>
<% if (oImageMap.containsKey(sCatId)) { %>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0"><INPUT NAME="removeimage<% out.write(sIndex); %>" TYPE="checkbox" VALUE="1"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><INPUT NAME="image<% out.write(sIndex); %>" TYPE="file" SIZE="20" CLASS="combomini"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="<% out.write(sWrkArGet+gu_workarea+"/apps/Shop/"+oCurrentCat.getPath(oConn)+"/"+oImageMap.get(sCatId)); %>" TARGET="_blank" TITLE="View image"><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" BORDER="0"></A></TD>
<% } else { %>
              <TD CLASS="strip<% out.write (sStrip); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><INPUT NAME="image<% out.write(sIndex); %>" TYPE="file" SIZE="20" CLASS="combomini"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"></TD>
<% } %>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" WIDTH="8"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="right"><IMG SRC="../images/images/deletefolder.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="left"><INPUT NAME="delete<% out.write(sIndex); %>" TYPE="checkbox" VALUE="1"></TD>
            </TR>
            <TR>
              <TD CLASS="strip<% out.write (sStrip); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" COLSPAN="2"><TEXTAREA NAME="de_es<% out.write(sIndex); %>" CLASS="combomini" ROWS="2" COLS="24"><% out.write(sCatDeEs); %></TEXTAREA></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" COLSPAN="2"><TEXTAREA NAME="de_en<% out.write(sIndex); %>" CLASS="combomini" ROWS="2" COLS="24"><% out.write(sCatDeEn); %></TEXTAREA></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" COLSPAN="7"></TD>
            <TR>

<%        } // next(i)

          oStmt.close();
%>
            <TR>
              <TD COLSPAN="14"><HR></TD>
            </TR>
<%
	  for (int i=0; i<4; i++) {
	  
            sStrip = String.valueOf((i%2)+1);
            sIndex = String.valueOf(i+iCatChlds);
	  %>
            <TR>
              <INPUT NAME="gu_category<% out.write(sIndex); %>" TYPE="hidden" VALUE="">
              <INPUT NAME="nm_category<% out.write(sIndex); %>" TYPE="hidden" VALUE="">
              <TD CLASS="strip<% out.write (sStrip); %>"><SELECT NAME="parent<% out.write(sIndex); %>" CLASS="combomini"><% out.write(oCatSelect.toString()); %></SELECT></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" WIDTH="8"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/flags/es.gif" WIDTH="22" HEIGHT="11" BORDER="0"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><INPUT NAME="tr_es<% out.write(sIndex); %>" TYPE="text" MAXLENGTH="50" SIZE="20" CLASS="combomini"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" WIDTH="8"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/flags/en.gif" WIDTH="22" HEIGHT="11" BORDER="0"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><INPUT NAME="tr_en<% out.write(sIndex); %>" TYPE="text" MAXLENGTH="50" SIZE="20" CLASS="combomini"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><IMG SRC="../images/images/spacer.gif" HEIGHT="1" WIDTH="8"></TD>
	      <TD CLASS="strip<% out.write (sStrip); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"><INPUT NAME="image<% out.write(sIndex); %>" TYPE="file" SIZE="20" CLASS="combomini"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" COLSPAN="4"></TD>
            </TR>
            <TR>
              <TD CLASS="strip<% out.write (sStrip); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" COLSPAN="2"><TEXTAREA NAME="de_es<% out.write(sIndex); %>" CLASS="combomini" ROWS="2" COLS="24"></TEXTAREA></TD>
              <TD CLASS="strip<% out.write (sStrip); %>"></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" COLSPAN="2"><TEXTAREA NAME="de_en<% out.write(sIndex); %>" CLASS="combomini" ROWS="2" COLS="24"></TEXTAREA></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" COLSPAN="7"></TD>
            <TR>
<%        } // next(i) %>
            <TR>
              <TD COLSPAN="14" ALIGN="center"><HR><BR><INPUT TYPE="submit" CLASS="pushbutton" VALUE="Save"></TD>
            </TR>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
<% oConn.close("cat_fastedit"); %>