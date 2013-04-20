<%@ page import="java.util.Vector,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%!

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

  static void addSubordinates (PreparedStatement oStmt, StringBuffer oBuffer, String sWorkArea, String sBoss, int iLevel) throws SQLException {
    ResultSet oRSet;
    Vector oSubs = new Vector();
    
    oStmt.setString(1, sWorkArea);
    oStmt.setObject(2, sBoss, java.sql.Types.VARCHAR);
    
    oRSet = oStmt.executeQuery();
    
    while (oRSet.next())
      oSubs.add(oRSet.getString(1));
    oRSet.close();

    int iSubs = oSubs.size();
    
    for (int t=0; t<iSubs; t++) {  
      oBuffer.append("<OPTION VALUE=\"" + oSubs.get(t) + "\">");
      
      for (int s=0; s<iLevel; s++)
        oBuffer.append("&nbsp;&nbsp;");

      oBuffer.append(oSubs.get(t) + "</OPTION>");
      
      addSubordinates (oStmt, oBuffer, sWorkArea, (String) oSubs.get(t), iLevel+1);
    } // next
        
  } // addSubordinates()
  
%>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String gu_workarea = getCookie(request, "workarea", "");
  
  StringBuffer oStrBuffer = new StringBuffer();
  DBSubset oTopTitles;
  int iTopTitles = 0;  
  
  JDCConnection oConn = null;  
  
  boolean bIsGuest = true;
    
  try {
   oConn = GlobalDBBind.getConnection("newfellowtitle");

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
   
   oTopTitles = new DBSubset(DB.k_lu_fellow_titles, DB.de_title, DB.gu_workarea + "='" + gu_workarea + "' AND " + DB.id_boss + " IS NULL", 10);
   iTopTitles = oTopTitles.load (oConn);
    
   PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.de_title + " FROM " + DB.k_lu_fellow_titles + " WHERE " + DB.gu_workarea + "=? AND " + DB.id_boss + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
  
   for (int t=0; t<iTopTitles; t++) {
     oStrBuffer.append("<OPTION VALUE=\"" + oTopTitles.getString(0,t) + "\">" + oTopTitles.getString(0,t) + "</OPTION>");
     addSubordinates(oStmt, oStrBuffer, gu_workarea, oTopTitles.getString(0,t), 0);
   }
    
   oStmt.close();
   oConn.close("newfellowtitle");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("newfellowtitle");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
        
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML>
<HEAD>
  <TITLE>hipergate :: New Position</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      // ------------------------------------------------------

      function check_varname(nick) {
        var nlen = nick.length;
        var ccod;
      
        var blank = 32;  
        var zero = 48;
        var nine = 57;
        var Aupr = 65;
        var Zupr = 90;
        var alwr = 97;
        var zlwr = 122;
        var underscore = 95;
          
        for (var i=0; i<nlen; i++) {
          ccod = nick.charCodeAt();
          if ((ccod<zero && ccod!=blank) || (ccod>nine && ccod<Aupr) || (ccod>Zupr && ccod<alwr && ccod!=underscore) || (ccod>zlwr))
            return false;
        } // next
        return true;
      } //check_varname
                  
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        
        if (rtrim(frm.de_title.value)=="") {
          alert("Position Name is mandatory");
          return false;
        }

        if (!check_varname(frm.de_title.value)) {
          alert("Position Name contains invalid characters");
          return false;        
        }
        
        if (-1!=comboIndexOf(frm.sel_boss, frm.de_title.value)) {
          alert("Another Position with such name already exists");
          return false;
        }
        
        frm.id_boss.value = getCombo(frm.sel_boss);
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">New Position</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="fellowtitle_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="200px"><FONT CLASS="formstrong">Position Name:</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" NAME="de_title" MAXLENGTH="50" SIZE="40" VALUE=""></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200px"><FONT CLASS="formplain">Position Code:</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" NAME="id_title" MAXLENGTH="50" SIZE="10" VALUE=""></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200px"><FONT CLASS="formplain">Proffesional Category:</FONT></TD>
            <TD ALIGN="left" ><INPUT TYPE="text" NAME="tp_title" MAXLENGTH="50" SIZE="40" VALUE=""></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200px"><FONT CLASS="formplain">Functional Dependency:</FONT></TD>
            <TD ALIGN="left" >
              <INPUT TYPE="hidden" NAME="id_boss" MAXLENGTH="30" VALUE="">
              <SELECT NAME="sel_boss"><OPTION VALUE="" SELECTED></OPTION><% out.write(oStrBuffer.toString()); %></SELECT>
            </TD>
          </TR>          
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your credential level as Guest does not allow you to perform this action')">&nbsp;
<% } else { %>    	    
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
<% } %>
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>