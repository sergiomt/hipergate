<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<%
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final int IncidentsManager=10;
  final int ProjectManager=12;
  final int Sales=16;
  final int CollaborativeTools=17;
  final int Directory=19;
  final int Shop=20;
  final int Hipermail=21;

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

  String gu_workarea = getCookie(request, "workarea", "");
  String gu_user = getCookie(request, "userid", "");

  JDCConnection oConn = null;
  DBSubset oPortlets = null;
  int iPortlets = 0;

  try {

    oConn = GlobalDBBind.getConnection("desktop_custom");

    oPortlets = new DBSubset (DB.k_x_portlet_user, DB.nm_portlet+","+DB.nm_zone+","+DB.od_position, DB.gu_user+"=? AND "+DB.gu_workarea+"=? AND "+DB.nm_page+"='desktop.jsp' ORDER BY 3", 10);

    iPortlets = oPortlets.load (oConn, new Object[]{gu_user,gu_workarea});

    oConn.close("desktop_custom");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("desktop_custom");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_close"));
  }

  if (null==oConn) return;

  oConn = null;
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>Customize this page</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>

  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
    
      function belongsTo(portlet,set) {
        for (var n=0;n<set.length;n++) {
	  if (set[n]==portlet)
	    return true;
        }
        return false;
      }
    
      // ----------------------------------------------------------------------

      function setCombos() {
        var left = new Array (<% for (int n=0,l=0;l<iPortlets;l++) if (oPortlets.getString(1,l).equals("left")) { out.write((n>0 ? ",\"" : "\"")+oPortlets.getString(0,l)+"\""); n++; } %>);
        var right = new Array (<% for (int n=0,l=0;l<iPortlets;l++) if (oPortlets.getString(1,l).equals("right")) { out.write((n>0 ? ",\"" : "\"")+oPortlets.getString(0,l)+"\""); n++; } %>);         
	      var portlets = new Array("com.knowgate.http.portlets.CalendarTab",
	                               "com.knowgate.http.portlets.CallsTab",
	                               "com.knowgate.http.portlets.MyIncidencesTab",
	                               "com.knowgate.http.portlets.OportunitiesTab",
	                               "com.knowgate.http.portlets.RecentContactsTab",
	                               "com.knowgate.http.portlets.RecentPostsTab",
	                               "com.knowgate.http.portlets.NewMail",
	                               "com.knowgate.http.portlets.Favorites",
	                               "com.knowgate.http.portlets.Invoicing");
	      var labels =  new Array("Calendar",
	      												"Calls",
	      												"Incidents",
	      												"Oportunities",
	      												"Contacts",
	      												"Forums",
	      												"E-Mail",
	      												"Favourites",
	      												"Invoicing");
	      var enabled =  new Array(<%=(((iAppMask & (1<<CollaborativeTools))==0) ? "false" : "true")%>,
	      												 <%=(((iAppMask & (1<<CollaborativeTools))==0) ? "false" : "true")%>,
	      												 <%=(((iAppMask & (1<<IncidentsManager))==0) ? "false" : "true")%>,
	      												 <%=(((iAppMask & (1<<Sales))==0) ? "false" : "true")%>,
	      												 <%=(((iAppMask & (1<<Sales))==0) ? "false" : "true")%>,
	      												 <%=(((iAppMask & (1<<CollaborativeTools))==0) ? "false" : "true")%>,
	      												 <%=(((iAppMask & (1<<Hipermail))==0) ? "false" : "true")%>,
	      												 <%=(((iAppMask & (1<<Directory))==0) ? "false" : "true")%>,
	      												 <%=(((iAppMask & (1<<Shop))==0) ? "false" : "true")%>);

        var frm = document.forms[0];

	      for (var p=0;p<portlets.length;p++) {
	        if (enabled[p]) {
	          if (belongsTo(portlets[p],left))
	            comboPush (frm.sel_left, labels[p], portlets[p], false, false);
	          else if (belongsTo(portlets[p],right))
	            comboPush (frm.sel_right, labels[p], portlets[p], false, false);
	          else
	            comboPush (frm.sel_all, labels[p], portlets[p], false, false);
	        }
	      }

        return true;
      } // validate;

      // ----------------------------------------------------------------------

      function add(cmb) {
        var frm = document.forms[0];
        var opt = frm.sel_all.options;
        
        for (var o=0; o<opt.length; o++) {
          if (opt[o].selected) {
            cmb.options[cmb.options.length] = new Option(opt[o].text, opt[o].value, false, false);
            opt[o--]=null;
          }
        }
      }

      // ----------------------------------------------------------------------

      function remove(cmb) {
        var frm = document.forms[0];
        var opt = cmb.options;
        
        for (var o=0; o<opt.length; o++) {
          if (opt[o].selected) {
            frm.sel_all.options[frm.sel_all.options.length] = new Option(opt[o].text, opt[o].value, false, false);
            opt[o--]=null;
          }
        }
      }

      // ----------------------------------------------------------------------

      function validate() {
        var frm = document.forms[0];
	
        for (var l=0; l<frm.sel_left.options.length; l++)
          frm.left.value += (l>0 ? "," : "") + frm.sel_left.options[l].value;

        for (var r=0; r<frm.sel_right.options.length; r++)
          frm.right.value += (r>0 ? "," : "") + frm.sel_right.options[r].value;
	
	return true;
      }
            
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Customize this page</FONT></TD></TR>
  </TABLE>
  <FORM METHOD="post" ACTION="desktop_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="left" VALUE=""><INPUT TYPE="hidden" NAME="right" VALUE="">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE CELLSPACING="4" CELLPADDING="4" WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="center" ><FONT CLASS="formstrong">Left Column</FONT></TD>
	    <TD></TD>
            <TD ALIGN="center"><FONT CLASS="formstrong">Available Items</FONT></TD>
	    <TD></TD>
            <TD ALIGN="center"><FONT CLASS="formstrong">Right Colum</FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="center"><SELECT NAME="sel_left" MULTIPLE></SELECT></TD>
            <TD ALIGN="center" VALIGN="middle">
              <INPUT TYPE="button" VALUE="<< Add" STYLE="width:70" onclick="add(document.forms[0].sel_left)">
              <BR><BR>
              <INPUT TYPE="button" VALUE="Remove >>" STYLE="width:70" onclick="remove(document.forms[0].sel_left)">
            </TD>
            <TD ALIGN="center"><SELECT NAME="sel_all" MULTIPLE></TD>
            <TD ALIGN="center" VALIGN="middle">
              <INPUT TYPE="button" VALUE="Add >>" STYLE="width:80" onclick="add(document.forms[0].sel_right)">
              <BR><BR>
              <INPUT TYPE="button" VALUE="<< Remove" STYLE="width:80" onclick="remove(document.forms[0].sel_right)">
            </TD>
            <TD ALIGN="center"><SELECT NAME="sel_right" MULTIPLE></SELECT></TD>
          </TR>
          <TR>
            <TD COLSPAN="5"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="5" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" TITLE="ALT+c" onclick="window.document.location.href='desktop.jsp'">
    	      <BR><BR>
    	    </TD>
    	  </TR>
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>
