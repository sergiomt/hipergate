<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
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
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String sSkin = getCookie(request, "skin", "default");
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_contact  = request.getParameter("gu_contact");
  String gu_company  = request.getParameter("gu_company");
  String tx_email    = request.getParameter("tx_email");

  String gu_member;
  short  tp_member;

   String sListId;
      
  /***********************************************************/
  /* Load Dynamic, Static and Direct Lists for this WorkArea */
  
  DBSubset oLists = new DBSubset ( DB.k_lists,
                                   DB.gu_list + "," + DB.tp_list + "," + DB.gu_query + "," + DB.tx_subject + ", 0 AS bo_member, 0 AS bo_active, 0 AS bo_blocked",
                                   DB.gu_workarea + "='" + gu_workarea + "' AND " + DB.tp_list + "<>" + String.valueOf(DistributionList.TYPE_BLACK) + " ORDER BY 4", 10);
  int iLists = 0;
    
  JDCConnection oConn = null;  
  ListMember oMmbr;
  DistributionList oList = new DistributionList();

  oList.put(DB.gu_workarea, gu_workarea);

  if (null!=gu_contact) {
    gu_member = gu_contact;
    tp_member = Contact.ClassId;
  }
  else if (null!=gu_company) {
    gu_member = gu_company;
    tp_member = Company.ClassId;
  }
  else {
    gu_member = tx_email;
    tp_member = ListMember.ClassId;
  }

  boolean bIsGuest = true;

  try {
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);

    oConn = GlobalDBBind.getConnection("subscriptions_listing");

    /************************************/
    /* Load all lists for this WorkArea */
            
    iLists = oLists.load(oConn);

    /**************************************************/
    /* For Each List check if Contact is member of it */
    
    for (int l=0; l<iLists; l++) {

      // Reuse the same DistributionList object    
      oList.replace(DB.gu_list, oLists.getString(0,l));
      oList.replace(DB.tp_list, oLists.getShort (1,l));
      oList.replace(DB.gu_query,oLists.getString(2,l));
      
      if (oList.contains(oConn, gu_member)) {

        // If list contains member then see if member is unactive or blocked

	switch (oLists.getShort(1,l)) {

	  case DistributionList.TYPE_DYNAMIC:

            oMmbr = new ListMember();
            oMmbr.put(DB.gu_list, oLists.getString(0,l));
            oMmbr.put(DB.tp_member, tp_member);
	    
	    switch (tp_member) {

	      case Contact.ClassId:
                oMmbr.put(DB.gu_contact, gu_member);
	        break;

	      case Company.ClassId:
                oMmbr.put(DB.gu_company, gu_member);
	        break;

	      case ListMember.ClassId:
                oMmbr.put(DB.tx_email, gu_member);
	        break;
            } // end switch(tp_member)

            oLists.setElementAt(new Boolean(true), 4, l);
            oLists.setElementAt(new Boolean(true), 5, l);
            oLists.setElementAt(new Boolean(oMmbr.isBlocked(oConn)), 6, l);
            
            break;

          case DistributionList.TYPE_STATIC:

            oMmbr = new ListMember(oConn, gu_member, oLists.getString(0,l));
            oMmbr.replace (DB.tp_member, tp_member);
            
            oLists.setElementAt(new Boolean(true), 4, l);
            oLists.setElementAt(new Boolean(oMmbr.getShort(DB.bo_active)!=(short)0), 5, l);
            oLists.setElementAt(new Boolean(oMmbr.isBlocked(oConn)), 6, l);
        
            break;

          case DistributionList.TYPE_DIRECT:
            
            oMmbr = new ListMember(oConn, gu_member, oLists.getString(0,l));
            
            oMmbr.replace (DB.tp_member, ListMember.ClassId);

            oLists.setElementAt(new Boolean(true), 4, l);
            oLists.setElementAt(new Boolean(oMmbr.getShort(DB.bo_active)!=(short)0), 5, l);
            oLists.setElementAt(new Boolean(oMmbr.isBlocked(oConn)), 6, l);

        } // end switch(tp_list)
      }
      else {
      
        // If list does not contain member set it as unactive and blocked
        
        oLists.setElementAt(new Boolean(false), 4, l);
        oLists.setElementAt(new Boolean(false), 5, l);
        oLists.setElementAt(new Boolean(true ), 6, l);
      }      
    }
            
    oConn.close("subscriptions_listing");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("subscriptions_listing");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NullPointerException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("subscriptions_listing");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=subscriptions_listing.jsp&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

%>
<HTML>
  <HEAD>
    <TITLE>Edit Subscriptions</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function validate() {
        var settings = "";
        var frm = document.forms[0];
        
<%      for (int n=0; n<iLists; n++) {
          
          sListId = oLists.getString(0,n);
          
	  out.write("        settings += \"" + sListId + "\" + \",\";\n");
	  out.write("        settings += (frm.member_" + sListId + ".checked ? \"1\" : \"0\") + \",\";\n");
	  out.write("        settings += (frm.active_" + sListId + ".checked ? \"1\" : \"0\") + \",\";\n");
	  out.write("        settings += (frm.bloked_" + sListId + ".checked ? \"1\" : \"0\") + \";\";\n");
        }
%>
        frm.new_settings.value = settings;
        
        return true;
      } // validate
    //-->
    </SCRIPT>
  </HEAD>
  <BODY>
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
    
    <FORM METHOD="post" ACTION="subscriptions_store.jsp" onsubmit="return validate()">

    <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Subscriptions of <%=Gadgets.HTMLEncode(request.getParameter("full_name"))%></FONT></TD></TR></TABLE>  
    
<%
    out.write ("    <INPUT TYPE=\"hidden\" NAME=\"old_settings\" VALUE=\"");
    
    for (int f=0; f<iLists; f++) {
      
      out.write(oLists.getString(0,f) + "," + (oLists.getBoolean(4,f) ? "1" : "0") + "," + (oLists.getBoolean(5,f) ? "1" : "0") + "," + (oLists.getBoolean(6,f) ? "1" : "0") + ";");
    }
    out.write("\">\n");
%>
    <INPUT TYPE="hidden" NAME="new_settings">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=nullif(gu_workarea)%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=nullif(gu_contact)%>">
    <INPUT TYPE="hidden" NAME="tx_email" VALUE="<%=nullif(tx_email)%>">
    <INPUT TYPE="hidden" NAME="gu_member" VALUE="<%=nullif(gu_member)%>">
    <TABLE>
      <TR>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>List</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Is Member</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Active</B></TD>
        <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Blocked</B></TD>
      </TR>
<% String sDisabled;
   String sStrip;
   
   for (int i=0; i<iLists; i++) {
     sListId = oLists.getString(0,i);
     sDisabled = (oLists.getShort(1,i)==DistributionList.TYPE_DYNAMIC ? " DISABLED" : "");
     sStrip = String.valueOf((i%2)+1);
%>
      <TR>
        <TD CLASS="strip<% out.write (sStrip); %>"><% out.write(oLists.getString(3,i)); %></TD>
        <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><% out.write("<INPUT NAME=\"member_" + sListId + "\" TYPE=\"checkbox\"" + (oLists.getBoolean(4,i) ? " CHECKED" : "") + sDisabled + ">"); %></TD>
        <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><% out.write("<INPUT NAME=\"active_" + sListId + "\" TYPE=\"checkbox\"" + (oLists.getBoolean(5,i) ? " CHECKED" : "") + sDisabled + ">"); %></TD>
        <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><% out.write("<INPUT NAME=\"bloked_" + sListId + "\" TYPE=\"checkbox\"" + (oLists.getBoolean(6,i) ? " CHECKED" : "") + ">"); %></TD>
      </TR>
<% } %>
    </TABLE>
    <HR>
    <CENTER>
<% if (bIsGuest) { %>
          <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your credential level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
<% } else { %>
          <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<% } %>
    	  <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    </CENTER>
    </FORM>
  </BODY>
</HTML>