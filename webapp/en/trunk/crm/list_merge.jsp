<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_list = request.getParameter("gu_list");
  
  
  DBSubset oLists = null;
  int iListCount = 0;
    
  JDCConnection oConn = null;  
  boolean bIsGuest = true;
     
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("list_merge");
    
    oLists = new DBSubset (DB.k_lists, 
      			   DB.gu_list + "," + DB.tp_list + "," + DB.tx_subject,
      		           DB.tp_list + "<>" + String.valueOf(DistributionList.TYPE_BLACK) + " AND " + DB.gu_workarea + "='" + gu_workarea + "' ORDER BY 3", 10);
    iListCount = oLists.load (oConn);

    oConn.close("list_merge");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("list_merge");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Combine lists</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      var jsTypes = new Array(<% for (int t=0; t<iListCount; t++) out.write((t>0 ? "," : "") + String.valueOf(oLists.getShort(1,t))); %>);
      
      // ------------------------------------------------------

      function showFields(b) {
        var frm = document.forms[0];
        
        if (b) {
          frm.tx_subject.style.visibility = "visible";
          frm.de_list.style.visibility = "visible";          
        }
        else {
          frm.tx_subject.style.visibility = "hidden";
          frm.de_list.style.visibility = "hidden";
        }
      }

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
	var len;
	var msg;
	
	if (frm.sel_added_list.options.selectedIndex==0) {
	  alert ("Must select a List to be combined");
	  return false;
	}
	
	if (frm.target[0].checked && jsTypes[frm.sel_base_list.options.selectedIndex]==<%=DistributionList.TYPE_DYNAMIC%>) {
	  alert ("It is not possible to put results in the base list because&nbsp;" + getComboText(frm.sel_base_list) + " is a dynamic list");
	  return false;
	}
	
	if (getCombo(frm.sel_base_list)==getCombo(frm.sel_added_list)) {
	  alert ("Base list and combined list may not be the same");
	  return false;	
	}
	
	if (frm.target[1].checked) {	
	  if (ltrim(frm.tx_subject.value)=="") {
	    alert ("Must specify a subject for new list containing combined data");
	    return false;	  
	  }
	  
	  len = frm.sel_base_list.options.length;
	  for (var l=0; l<len; l++) {
	    if (frm.sel_base_list.options[l].value==frm.tx_subject.value) {
	      alert ("Another list with same subject already exists");
	      return false;
	    }
	  } // next
	} // fi (frm.target[1].checked)
	
	if (frm.action[0].checked) {
	  frm.tp_action.value = "add";
	  if (frm.target[0].checked)
	    msg = "You are about to add members from list&nbsp;" + getComboText(frm.sel_added_list) + " to list&nbsp;" + getComboText(frm.sel_base_list) + " overwritting those that already exist. Are you sure you want to continue?";
          else
	    msg = "You are about to add members from list&nbsp;" + getComboText(frm.sel_base_list) + " and the list&nbsp;" + getComboText(frm.sel_added_list) + " putting results in a new list" + frm.tx_subject.value + " Are you sure you want to continue?";
        }
        else if (frm.action[1].checked) {
	  frm.tp_action.value = "append";
	  if (frm.target[0].checked)
	    msg = "You are about to add members from list&nbsp;" + getComboText(frm.sel_added_list) + " to list&nbsp;" + getComboText(frm.sel_base_list) + " without altering those already existing at base list. Are you sure you want to continue?";
          else
	    msg = "You are about to add members from list&nbsp;" + getComboText(frm.sel_added_list) + " and the list&nbsp;" + getComboText(frm.sel_base_list) + " putting results in a new list" + frm.tx_subject.value + " Are you sure you want to continue?";
        }
        else {
	  frm.tp_action.value = "substract";
	  if (frm.target[0].checked)
	    msg = "You are about to remove from list" + getComboText(frm.sel_base_list) + " members from list&nbsp;" + getComboText(frm.sel_added_list) + " Are you sure you want to continue?";
          else
	    msg = "You are about to create list t&nbsp;" + frm.tx_subject.value + " removing members of&nbsp;" + getComboText(frm.sel_added_list) + " from list&nbsp;" + getComboText(frm.sel_base_list) + " Are you sure you want to continue?";
        }
                
        if (frm.target[0].checked)
          frm.gu_target.value = getCombo(frm.sel_base_list);
        else
          frm.gu_target.value = "";
	
	frm.gu_base_list.value = getCombo(frm.sel_base_list);
	frm.gu_added_list.value = getCombo(frm.sel_added_list);
	        
        return window.confirm(msg);
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_base_list, getURLParam("gu_list"));
        
        return true;
      } // validate;
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Combine lists</FONT></TD></TR>
  </TABLE>
  <CENTER>
  <FORM METHOD="post" ACTION="list_merge_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_base_list">
    <INPUT TYPE="hidden" NAME="gu_added_list">
    <INPUT TYPE="hidden" NAME="tp_action">
    <INPUT TYPE="hidden" NAME="gu_target">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formstrong">Base List:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <SELECT NAME="sel_base_list">
<%
	      for (int l=0; l<iListCount; l++) {
	        out.write("<OPTION VALUE=\"" + oLists.getString(0,l) + "\">" + oLists.getStringNull(2,l,"(sin asunto" + String.valueOf(l) + ")") + "</OPTION>");        
	      }
%>
              </SELECT>
            </TD>
          </TR>
          <TR>
            <TD VALIGN="top" ALIGN="right" WIDTH="140"><FONT CLASS="formstrong">Action:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <FONT CLASS="formplain">
              <INPUT TYPE="radio" NAME="action" CHECKED>&nbsp;Add members overwriting existing ones.
              <BR>
              <INPUT TYPE="radio" NAME="action">&nbsp;Add members without modifying already existing ones.
              <BR>
              <INPUT TYPE="radio" NAME="action">&nbsp;Remove members
              </FONT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formstrong">List to be Combined:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <SELECT NAME="sel_added_list"><OPTION VALUE="" SELECTED></OPTION>
<%
	      for (int l=0; l<iListCount; l++) {
	        if (!oLists.getString(0,l).equals(gu_list))
	          out.write("<OPTION VALUE=\"" + oLists.getString(0,l) + "\">" + oLists.getStringNull(2,l,"(no subject" + String.valueOf(l) + ")") + "</OPTION>");        
	      }
%>
              </SELECT>
            </TD>
          </TR>
          <TR>
            <TD VALIGN="top" ALIGN="right" WIDTH="140"><FONT CLASS="formstrong">Put result:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <TABLE>
                <TR>
                  <TD><INPUT TYPE="radio" NAME="target" onclick="showFields(false)"></TD>
                  <TD><FONT CLASS="formplain">on the base list.</FONT></TD>
                </TR>
                <TR>
                  <TD><INPUT TYPE="radio" NAME="target" CHECKED></TD>
                  <TD><FONT CLASS="formplain">on a new list.</FONT></TD>
                </TR>                
                <TR>
                  <TD></TD>
                  <TD>
                    <TABLE>
                      <TR>
                        <TD><FONT CLASS="formplain">Subject:</FONT></TD>
                        <TD><INPUT TYPE="text" NAME="tx_subject" MAXLENGTH="100" SIZE="40" VALUE=""></TD>
                      </TR>
                      <TR>
                        <TD><FONT CLASS="formplain">Description:&nbsp;</FONT></TD>
                        <TD><INPUT TYPE="text" NAME="de_list" MAXLENGTH="50" SIZE="40" VALUE=""></TD>
                      </TR>
		    </TABLE>
		  </TD>                      
		</TR>
	      </TABLE>
            </TD>
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
              <INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
  </CENTER>
</BODY>
</HTML>
