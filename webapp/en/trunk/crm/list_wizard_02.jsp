<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%
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
  
  String gu_workarea = request.getParameter("gu_workarea"); 
  DBSubset oQueries = null;
  int iQueryCount = 0;  

  JDCConnection oConn = GlobalDBBind.getConnection("listwizard02");  
  
  try {
    
    oQueries = new DBSubset (DB.k_queries, DB.gu_query + "," + DB.tl_query, DB.gu_workarea + "='" + gu_workarea + "' AND " + DB.nm_queryspec + "='listmember' ORDER BY 2", 10);
    iQueryCount = oQueries.load(oConn);
    oConn.close("listwizard02");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("...");
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  oConn = null;
%>

<HTML>
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function setInputs() {
        window.resizeTo(420,340);
      
	var frm = document.forms[0];
	frm.id_domain.value = getURLParam("id_domain");
	frm.n_domain.value = getURLParam("n_domain");
	frm.gu_workarea.value = getURLParam("gu_workarea");
	frm.tp_list.value = getURLParam("tp_list");
	
	if (getURLParam("gu_query")!="" && getURLParam("gu_query")!="null")
	  setCombo(frm.gu_query, getURLParam("gu_query"));
      }
      
      function createQuery() {
        window.open("../common/qbf.jsp?queryspec=listmember&caller=list_wizard_02.jsp","qbf","height=460,width=560");
      }

      function editQuery() {
      	if (document.forms[0].gu_query.selectedIndex<0) {
      	  alert ("A query to be edited must be selected first");
          return false;
        } else {
        	window.open("../common/qbf.jsp?queryid="+getCombo(document.forms[0].gu_query)+"&queryspec=listmember&caller=list_wizard_02.jsp","qbf","height=460,width=560");
          return true;
        }
      }

      function validate() {
	var frm = document.forms[0];

	if (frm.action!="list_wizard_01.jsp")
	  frm.action='list_wizard_03.jsp';
        
        if (("1"==frm.tp_list.value || "2"==frm.tp_list.value) && frm.gu_query.selectedIndex<0 &&
            frm.action=='list_wizard_03.jsp') {
          alert ("Must select a Query from with List Members are to be extracted");
          return false;
        }
        frm.submit();                  	
        return true;
      }
    //-->
  </SCRIPT>
  <TITLE>hipergate :: Create Distribution List - Step 2 of 4</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setInputs()">
  <!--<DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>-->
  <!--<SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>  -->
  <FORM NAME="frmLists" METHOD="get">
    <INPUT TYPE="hidden" NAME="id_domain">
    <INPUT TYPE="hidden" NAME="n_domain">
    <INPUT TYPE="hidden" NAME="gu_workarea">
    <INPUT TYPE="hidden" NAME="tp_list" VALUE="">
    <CENTER>            
    <TABLE><TR><TD WIDTH="310px" CLASS="striptitle"><FONT CLASS="title1">Create List - Step 2 of 4</FONT></TD></TR></TABLE>
    <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR>
        <TD><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createQuery()" CLASS="linkplain">Create new Query</A></TD>
      </TR>
    </TABLE>
    <TABLE WIDTH="310px" CLASS="formback">
      <TR>
        <TD ALIGN="left" CLASS="formstrong">
          Choose a Query
        </TD>
      </TR>
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="left">
	      <SELECT NAME="gu_query" CLASS="combomini">
<%
	      for (int q=0; q<iQueryCount; q++) {
	        out.write("	        <OPTION VALUE=\"" + oQueries.getString(0,q) + "\">" + oQueries.getString(1,q) + "</OPTION>\n");
	      } // next ()
%>
	    </SELECT>&nbsp;&nbsp;<A HREF="#" onclick="editQuery()" TITLE="Edit Query"><IMG SRC="../images/images/edit16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Edit Query"></A>
            </TD>
          </TR>
        </TABLE>
      </TD></TR>
    </TABLE>
    <BR>
    <TABLE WIDTH="400px"><TR><TD ALIGN="center"><INPUT TYPE="button" CLASS="closebutton" VALUE="Cancel" STYLE="width:100px" onClick="self.close()">&nbsp;<INPUT TYPE="button" CLASS="pushbutton" VALUE="<< Previous" STYLE="width:100px" onClick="document.forms[0].action='list_wizard_01.jsp';document.forms[0].submit()">&nbsp;<INPUT TYPE="button" CLASS="pushbutton" VALUE="Next >>" STYLE="width:100px" onClick="return validate()"></TD></TR></TABLE>
    </CENTER>
  </FORM>
</BODY>
</HTML>