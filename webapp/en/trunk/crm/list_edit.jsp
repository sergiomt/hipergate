<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.misc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.DistributionList,com.knowgate.hipergate.Category" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><% 
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
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = getCookie(request,"workarea",null);
  String gu_list = request.getParameter("gu_list");
  String gu_query = "";
  int nu_members = 0;
  
  String sTpList = "";
  String sTlQuery = null;
  short tp_list;
  
  DistributionList oList = null;
  Statement oStmt;
  ResultSet oRSet;

  boolean bIsGuest = true;
  JDCConnection oConn = null;  
  DBSubset oCatgs = new DBSubset (DB.k_cat_expand + " e," + DB.k_categories + " c",
                                  "e." + DB.gu_category + ",c." + DB.nm_category + ",e." + DB.od_level + ",e." + DB.od_walk + ",e." + DB.gu_parent_cat + ",'' AS "+DB.tr_+sLanguage,
    				                      "e." + DB.gu_category + "=c." + DB.gu_category + " AND "+
    				                      "e." + DB.od_level + ">1 AND e." + DB.gu_rootcat + "=? AND e." + DB.gu_parent_cat + " IS NOT NULL ORDER BY e." + DB.od_walk, 50);
  int iCatgs = 0;
  String sGuRootCategory = "";
  
  try {
  
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("list_edit");
    
    oList = new DistributionList();
    
    if (!oList.load(oConn, new Object[]{gu_list}))
      throw new SQLException ("List " + gu_list + " not found at k_lists table");
      
    gu_query = oList.getStringNull(DB.gu_query,"");    

    tp_list = oList.getShort(DB.tp_list);    

    nu_members = oList.memberCount(oConn);
    
    switch (tp_list) {
      case DistributionList.TYPE_STATIC:
        sTpList = "Static";
        break;        
      case DistributionList.TYPE_DYNAMIC:        
        sTpList = "Din&aacute;mica";
        oStmt = oConn.createStatement();
        oRSet = oStmt.executeQuery("SELECT " + DB.tl_query + " FROM " + DB.k_queries + " WHERE " + DB.gu_query + "='" + gu_query + "'");
        if (oRSet.next()) sTlQuery = oRSet.getString(1);
        oRSet.close();
        oStmt.close();                
        break;
      case DistributionList.TYPE_DIRECT:
        sTpList = "Direct";
        break;
    } // end switch()
  
    sGuRootCategory = Category.getIdFromName(oConn, n_domain+"_apps_sales_lists_"+gu_workarea);
		iCatgs = oCatgs.load(oConn, new Object[]{sGuRootCategory});
    Category oCatg = new Category();
    for (int l=0; l<iCatgs; l++) {
      oCatg.replace (DB.gu_category, oCatgs.getString(0,l));
      oCatgs.setElementAt(oCatg.getLabel(oConn, sLanguage), 5, l); 
    } // next
  }
  catch (SQLException e) {  
    tp_list = -100;
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("list_edit");
        response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close")); 
    oConn=null;
  }
  
  if (null==oConn) return;
  
  oConn.close("list_edit");
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Distribution List</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function showCalendar(ctrl) {       
        var dtnw = new Date();
        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

	
	function editMembers() {
<%        if (tp_list==DistributionList.TYPE_DYNAMIC) { %>
              window.open('../common/qbf.jsp?caller=list_listing.jsp&queryspec=listmember&caller=list_listing.jsp?gu_list=<%=oList.getString(DB.gu_list)%>&de_title=' + escape('Consulta de Miembros: <%=oList.getString(DB.tx_subject)%>') + '&queryspec=listmember&queryid=<%=gu_query%>','wMemberList','height=' + (screen.height>600 ? '600' : '520') + ',width= ' + (screen.width>800 ? '800' : '760') + ',scrollbars=yes,toolbar=no,menubar=no');
<%        } else { %>
              window.open('member_listing.jsp?gu_list=<%=oList.getString(DB.gu_list)%>&de_list=' + escape('<%=oList.getString(DB.tx_subject)%>'),'wMembers','height=' + (screen.height>600 ? '600' : '520') + ',width= ' + (screen.width>800 ? '800' : '760') + ',scrollbars=yes,toolbar=no,menubar=no');
<%        } %>
        }

      // ------------------------------------------------------
              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_table_lookup&id_language=" + getUserLanguage() + "&id_section=tx_field&tp_control=2&nm_control=sel_field&nm_coding=tx_field", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,top=" + (screen.height-520)/2 + ",left=" + (screen.width-480)/2 + ",width=480,height=520");
            break;
          case 2:
	    // window.open("...
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	      if (frm.de_list.value.length>50) {
	        alert ("List description may not be longer than 50 characters");
	        return false;
	      }
        
	      if (!check_email(frm.tx_from.value)) {
	        alert ("sender e-mail address is not valid");
	        return false;
              }
        
	      /*
	      if (!check_email(frm.tx_reply.value)) {
	        alert ("return e-mail address is not valid");
	        return false;
              }
              */
        	        
        return true;
      } // validate;
      
      function setCombos() {
        setCombo(document.forms[0].gu_category, "<%=oList.getStringNull(DB.gu_category,sGuRootCategory)%>");
      }
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <FORM NAME="" METHOD="post" ACTION="list_wizard_store.jsp" onSubmit="return validate()">
  <DIV class="cxMnu1" style="width:300px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=gu_list%>">    
    <INPUT TYPE="hidden" NAME="gu_query" VALUE="<%=gu_query%>">    
    <INPUT TYPE="hidden" NAME="tp_list" VALUE="<%=String.valueOf(tp_list)%>">    
    <INPUT TYPE="hidden" NAME="caller" VALUE="edit">    
    <BR>
    <TABLE CELLSPACING="0" CELLPADDING="0" WIDTH="100%" BORDER="0">
      <TR><TD ALIGN="LEFT" CLASS="striptitle"><FONT CLASS="title1">Edit Distribution List</FONT></TD></TR>
      <TR><TD><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="4" BORDER="0"></TD></TR>
    </TABLE>  
    <% if (tp_list==DistributionList.TYPE_STATIC) {%>
    <TABLE CELLSPACING="0" CELLPADDING="0" WIDTH="80%" BORDER="0" ALIGN="center">
      <TR>
      	<TD ALIGN="LEFT"><IMG SRC="../images/images/crm/subscriptions16.gif" BORDER="0" ALT="Click for editing members" ALIGN="center">&nbsp;<FONT FACE="Arial" SIZE="-1" COLOR="black"><A HREF="#" onclick="javascript:window.open('member_listing.jsp?gu_list=<%=oList.getStringNull(DB.gu_list,"")%>&de_list=<%=oList.getStringNull(DB.de_list,"")%>','wMemeberListing','height=' + (screen.height>600 ? '600' : '520') + ',width= ' + (screen.width>800 ? '800' : '760') + ',scrollbars=yes,toolbar=no,menubar=no');window.close();" CLASS="linkplain">Edit Members</A>&nbsp;&nbsp;</FONT></TD>
      	<TD ALIGN="LEFT"><IMG SRC="../images/images/excel16.gif" BORDER="0" ALT="Click for exporting members" ALIGN="center">&nbsp;<FONT FACE="Arial" SIZE="-1" COLOR="black"><A HREF="#" onclick="javascript:window.open('list_members_csv.jsp?gu_list=<%=oList.getStringNull(DB.gu_list,"")%>')" CLASS="linkplain">Export members</A>&nbsp;&nbsp;</FONT></TD>
      </TR>
    </TABLE>
    <% } %>
    <CENTER>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">List Type:</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="locked_tp_list"  SIZE="16" VALUE="<%=sTpList%>" DISABLED>
<% if (tp_list==DistributionList.TYPE_STATIC || tp_list==DistributionList.TYPE_DIRECT) { %>
	      &nbsp;<A HREF="#" CLASS="linkplain" onclick="editMembers()">Edit Members</A>
<% } %>            
            </TD>
          </TR>
<%  if (tp_list==DistributionList.TYPE_DYNAMIC) { %>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Query:</FONT></TD>
            <TD ALIGN="left"><A HREF="#" CLASS="linkplain" onclick="editMembers()"><% out.write (sTlQuery); %></A></TD>
          </TR>
<% } %>
          <TR>
            <TD></TD>
            <TD ALIGN="left"><FONT CLASS="formplain"><I>(<% out.write (String.valueOf(nu_members)); %>&nbsp;members)</I></FONT></TD>
          </TR>
					<TR>
				    <TD CLASS="formstrong" ALIGN="right">Category</TD>
				    <TD><SELECT name="gu_category" class="combomini"><%
    		      out.write ("<OPTION VALUE=\"" + sGuRootCategory + "\"></OPTION>");
    			    for (int c=0; c<iCatgs; c++) {		    
        	      out.write ("<OPTION VALUE=\"" + oCatgs.getString(0,c) + "\">");
        		    for (int s=1; s<oCatgs.getInt(2,c); s++) out.write("&nbsp;&nbsp;&nbsp;");
        		    out.write (oCatgs.getString(5,c));
                out.write ("</OPTION>");
        	    }					
		 	      %></SELECT></TD>
				  </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">Description:</FONT></TD>
            <TD ALIGN="left"><TEXTAREA NAME="de_list" COLS="28"><%=oList.getStringNull(DB.de_list,"")%></TEXTAREA></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Subject:</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="tx_subject" MAXLENGTH="100" SIZE="40" VALUE="<%=oList.getStringNull(DB.tx_subject,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Sender Name:</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="tx_sender" MAXLENGTH="100" SIZE="40" VALUE="<%=oList.getStringNull(DB.tx_sender,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Sender e-mail:</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="tx_from" MAXLENGTH="100" SIZE="40" VALUE="<%=oList.getStringNull(DB.tx_from,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Return e-mail:</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="tx_reply" MAXLENGTH="100" SIZE="40" VALUE="<%=oList.getStringNull(DB.tx_reply,"")%>"></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>          
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert ('Your credential level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
<% } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<% } %>
              <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>
    </CENTER>
  </FORM>
</BODY>
</HTML>
<% if (request.getParameter("wizard")!=null) out.write("<script>window.moveTo((screen.width-window.width)/2,(screen.height-window.height)/2);alert('Lista creada con éxito. Puede consultar los contactos que componen la lista desde la opción Editar Miembros.')</script>"); %>    