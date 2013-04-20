<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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
  
  int iScreenWidth;
  float fScreenRatio;

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String screen_width = request.getParameter("screen_width");

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  fScreenRatio = ((float) iScreenWidth) / 800f;
  
  int iRoomCount = 0;
  DBSubset oRooms;        
  String sOrderBy;
  int iOrderBy;  

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  boolean bIsGuest = true;

  JDCConnection oConn = null;  
      
  try {
      oConn = GlobalDBBind.getConnection("roomlisting");  

      bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
            
      oRooms = new DBSubset (DB.k_rooms, 
      			     DB.nm_room + "," + DB.tx_location + "," + DB.tx_company + "," + DB.tp_room + "," + DB.bo_available + "," + DB.tx_comments,
      			     DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), 50);
      iRoomCount = oRooms.load (oConn);    
  }
  catch (SQLException e) {  
    oRooms = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("roomlisting");
    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Resource Listing</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--            
        <%
          
          out.write("var jsRooms = new Array(");
            for (int i=0; i<iRoomCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oRooms.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	      function createRoom() {	  
	  
	        self.open ("room_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "editroom", "directories=no,toolbar=no,menubar=no,width=640,height=440");	  
	      } // createRoom()

        // ----------------------------------------------------
	
	function deleteRooms() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure you want to delete selected resources?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "room_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsRooms.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsRooms[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteRooms()
	
        // ----------------------------------------------------

	      function modifyRoom(nm) {
	  
	        self.open ("room_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&nm_room=" + escape(nm) + "&gu_workarea=<%=gu_workarea%>", "editroom", "directories=no,toolbar=no,menubar=no,width=640,height=440");
	      }	

        // ----------------------------------------------------

	      function sortBy(fld) {
	  
	        window.location = "room_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	      }			

        // ----------------------------------------------------

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsRooms.length; c++)                        
            eval ("frm.elements['" + jsRooms[c] + "'].click()");
        } // selectAll()
             
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Resource Listing</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle">
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">New</A>
<% } else { %>
          <A HREF="#" onclick="createRoom()" CLASS="linkplain">New</A>
<% } %>
        </TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD>
<% if (bIsGuest) { %>
          <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
          <A HREF="javascript:deleteRooms()" CLASS="linkplain">Delete</A>
<% } %>
        </TD>
      </TR>
      <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Type</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=floor(300f*fScreenRatio)%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(1);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==1 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=floor(150f*fScreenRatio)%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Location</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=floor(150f*fScreenRatio)%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Company</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Comments</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%
      try {
	  String sRoomNm,sLocation,sCompNm,sTpRoom,sComm;
	  boolean bAvailable;
	  for (int i=0; i<iRoomCount; i++) {
            sRoomNm = oRooms.getString(0,i);
            sLocation = oRooms.getStringNull(1,i,"");
            if (sLocation.length()>0)
              sLocation = DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_rooms_lookup, gu_workarea, "tx_location", sLanguage, sLocation);
            sCompNm = oRooms.getStringNull(2,i,"");
            if (sCompNm.length()>0)
              sCompNm = DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_rooms_lookup, gu_workarea, "tx_company", sLanguage, sCompNm);
            sTpRoom = oRooms.getStringNull(3,i,"");
            if (sTpRoom.length()>0)
              sTpRoom = DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_rooms_lookup, gu_workarea, "tp_room", sLanguage, sTpRoom);
            if (oRooms.isNull(4,i))
              bAvailable = false;
            else
            	bAvailable = (oRooms.getShort(4,i)!=(short)0);
            sComm = Gadgets.left(oRooms.getStringNull(5,i,""),80);
%>            
            <TR>
              <TD HEIGHT="14" CLASS="strip<%=((i%2)+1)%>"><% if (!bAvailable) out.write("<IMG SRC=\"../images/images/addrbook/halt15.gif\" WIDTH=\"15\" HEIGHT=\"15\" BORDER=\"0\" ALT=\"Resource not available\""); %></TD>
              <TD HEIGHT="14" CLASS="strip<%=((i%2)+1)%>">&nbsp;<% out.write(nullif(sTpRoom,oRooms.getStringNull(3,i,""))); %></TD>
              <TD HEIGHT="14" CLASS="strip<%=((i%2)+1)%>">&nbsp;<A HREF="#" onclick="modifyRoom('<% out.write(sRoomNm); %>')"><% out.write(sRoomNm); %></A></TD>
              <TD HEIGHT="14" CLASS="strip<%=((i%2)+1)%>">&nbsp;<% out.write(nullif(sLocation)); %></TD>
              <TD HEIGHT="14" CLASS="strip<%=((i%2)+1)%>">&nbsp;<% out.write(nullif(sCompNm)); %></TD>
              <TD HEIGHT="14" CLASS="strip<%=((i%2)+1)%>">&nbsp;<% out.write(sComm); %></TD>
              <TD HEIGHT="14" CLASS="strip<%=((i%2)+1)%>" ALIGN="center"><INPUT VALUE="<% out.write(nullif(sRoomNm)); %>" TYPE="checkbox" NAME="<% out.write("chk"+String.valueOf(i)); %>">
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
<%
	  oConn.close("roomlisting"); 
	  oConn = null;
      } catch (SQLException e) {
    	  if (oConn!=null)
      	    if (!oConn.isClosed())
              oConn.close("roomlisting");
	  oConn = null;      
      }
%>
<%@ include file="../methods/page_epilog.jspf" %>