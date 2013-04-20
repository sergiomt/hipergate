<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Term,com.knowgate.hipergate.Thesauri" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
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

  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_scope = request.getParameter("id_scope");
  String id_language = request.getParameter("id_language");
  String gu_term = request.getParameter("gu_term");
  String id_term = request.getParameter("id_term");
  String id_level = nullif(request.getParameter("id_level"),"0");
  String bo_mainterm = request.getParameter("bo_mainterm");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");
  
  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "default");
  int iSkip = Integer.parseInt(request.getParameter("skip"));
  int iLevel = Integer.parseInt(id_level);
  int iDomain = Integer.parseInt(id_domain);
  String sTerm;
    
  Term[] aParents = new Term[iLevel+1];
    
  String sFind = nullif(request.getParameter("find"));
  String sWhere = "t." + DB.gu_rootterm + "=r." + DB.gu_rootterm + " AND r." + DB.gu_workarea + "='" + gu_workarea + "' AND r." + DB.id_domain + "=" + id_domain + " AND (t." + DB.id_scope + "='" + id_scope + "' OR t." + DB.id_scope + "='all')";
  
  if (null!=id_language)
    sWhere += " AND t." + DB.id_language + "='" + id_language + "'";

  if (null!=id_term) {
    sWhere += " AND t.id_term" + String.valueOf(iLevel-1) + "='" + id_term + "'";
  }

  if (iLevel<9)
    sWhere += " AND t.id_term" + String.valueOf(iLevel) + " IS NOT NULL AND t.id_term" + String.valueOf(iLevel+1) + " IS NULL";
  else
    sWhere += " AND t.id_term" + String.valueOf(iLevel) + " IS NOT NULL"; 
  
  if (null!=bo_mainterm)
    sWhere = " AND t." + DB.bo_mainterm + "='" + bo_mainterm + "'";
    
  DBSubset oTerms = new DBSubset (DB.k_thesauri_root + " r," + DB.k_thesauri + " t",
  				  "t.gu_term,t.bo_mainterm,t.tx_term,t.de_term,t.id_term0,t.id_term1,t.id_term2,t.id_term3,t.id_term4,t.id_term5,t.id_term6,t.id_term7,t.id_term8,t.id_term9,t.id_scope",
  				  sWhere, 100);
  boolean aChilds[] = null;
  oTerms.setMaxRows(500);

  int iTerms = 0;
  
  JDCConnection oConn = null;  
  boolean bIsAdmin = false;
    
  try {
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
  
    oConn = GlobalDBBind.getConnection("thesauri_listing");
      
    iTerms = oTerms.load (oConn, iSkip);

    if (iTerms>0) {
      aChilds = new boolean[iTerms];
      for (int t=0; t<iTerms; t++) {
        
      }
      
      for (int p=0; p<iLevel; p++) {

        sTerm = Thesauri.getTerm (oConn, iDomain, oTerms.getInt(p+4, 0), p);

        if (sTerm!=null) {
          aParents[p] = new Term();
          aParents[p].load(oConn, new Object[]{sTerm});
        }
        else
          aParents[p] = null;
      }
    } else {
      for (int p=0; p<iLevel; p++)
        aParents[p] = null;
    }

    oConn.close("thesauri_listing");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"thesauri_listing");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML LANG="<% out.write(sLanguage); %>">
  <HEAD>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
    <!--
      function choose(vlstr,nmstr) {
        var prnt = window.parent;

	var frm = prnt.opener.document.forms[<%=nullif(request.getParameter("id_form"),"0")%>];

        <% 
           out.write("	frm." + nm_control + ".value = nmstr;\n");           
           out.write("  frm." + nm_coding + ".value = vlstr;\n");
        %>        

        prnt.close();
      }
      
      // ----------------------------------------------------------------------
      
      function deleteTerm(gu,sc) {
        if (confirm("Are you sure that you want to delete the thesauri entry and all its childs?")) {
          window.parent.frames[1].document.location = "term_edit_delete.jsp?gu_term=" + gu + "&id_scope=" + sc + "&id_domain=" + getURLParam("domainid") + "&workarea=" + getURLParam("workarea");
        }
      }
      
    //-->
    </SCRIPT>
  </HEAD>
  <BODY  TOPMARGIN="8" MARGINHEIGHT="8" LEFTMARGIN="8">
    <FORM METHOD="post">

      <TABLE CELLSPACING="2" CELLPADDING="2">
        <TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
          <TD><A HREF="#" CLASS="linkplain">Delete</A></TD>
          <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
          <TD VALIGN="middle">
            <SELECT NAME="sel_searched" CLASS="combomini"></SELECT>
            <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
  	  &nbsp;<A HREF="#" CLASS="linkplain" TITLE="Find">Search</A>	  
          </TD>
          <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Search"></TD>
          <TD VALIGN="bottom">
            <A HREF="javascript:document.forms[0].find.value='';findInstance();" CLASS="linkplain" TITLE="Discard Search">Discard</A>
          </TD>
        </TR>
        <TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <FONT CLASS="linkplain">
      <A HREF="thesauri_f.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&id_scope=<%=id_scope%>&nm_control=<%=nm_control%>&nm_coding=<%=nm_coding%>&skip=0" TARGET="_top" CLASS="linkplain">Root terms</A>
<% for (int a=0; a<iLevel; a++) {
     if (aParents[a]!=null)
       if (iLevel-1==a)
         out.write("&nbsp;&nbsp;<B>" + aParents[a].getString(DB.tx_term) + "</B>");
       else
         out.write("&nbsp;&nbsp;<A HREF=\"thesauri_f.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&id_scope=" + id_scope + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding + "&skip=0&id_level=" + String.valueOf(a+1) + "&id_term=" + String.valueOf(aParents[a].getInt(DB.id_term + String.valueOf(a))) + "\" TARGET=\"_top\" CLASS=\"linkplain\">" + aParents[a].getString(DB.tx_term) + "</A>");
   }
%>
      </FONT>
<% if (iLevel==1)
     out.write("&nbsp;&nbsp;<A HREF=\"thesauri_f.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&id_scope=" + id_scope + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding + "&skip=0\" TARGET=\"_top\"><IMG SRC=\"../images/images/up18x22.gif\" WIDTH=\"18\" HEIGHT=\"22\" BORDER=\"0\"></A>");
   else if (iLevel>1 && aParents[iLevel-2]!=null)
     out.write("&nbsp;&nbsp;<A HREF=\"thesauri_f.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&id_scope=" + id_scope + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding + "&skip=0&id_level=" + String.valueOf(iLevel-1) + "&id_term=" + String.valueOf(aParents[iLevel-2].getInt(DB.id_term + String.valueOf(iLevel-2))) + "\" TARGET=\"_top\"><IMG SRC=\"../images/images/up18x22.gif\" WIDTH=\"18\" HEIGHT=\"22\" BORDER=\"0\"></A>");
%>
      <HR>
      <TABLE WIDTH="100%">
<% String sStrip;
   for (int t=0; t<iTerms; t++) {
   
     sStrip = String.valueOf((t%2)+1);
%>
        <TR>
          <TD CLASS="strip<%out.write(sStrip);%>" WIDTH="16px">
<% if (iLevel!=9) {
            out.write ("            <A HREF=\"thesauri_f.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + (id_language!=null ? "&id_language=" + id_language : "") + (nm_control!=null ? "&nm_control=" + nm_control : "") + (nm_coding!=null ? "&nm_coding=" + nm_coding : "") + "&id_scope=" + id_scope + "&gu_term=" + oTerms.getString(0, t) + "&id_term=" + String.valueOf(oTerms.getInt(iLevel+4, t)) + "&id_level=" + String.valueOf(iLevel+1) + (bo_mainterm!=null ? "&bo_mainterm=" + bo_mainterm : "") + "\" CLASS=\"linknodecor\" TARGET=\"_top\" TITLE=\"Expand\">[+]</A>\n");
} %>
          </TD>
          <TD CLASS="strip<%out.write(sStrip);%>"> <A HREF="#" onclick="choose('<%=oTerms.getString(0, t)%>','<%=oTerms.getString(2, t)%>')" CLASS="linkplain" TITLE="<%=oTerms.getStringNull(3, t,"")%>"><%=oTerms.getString(2, t)%></A></TD>
          <TD CLASS="strip<%out.write(sStrip);%>" WIDTH="50px" ALIGN="right"><A HREF="term_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_term=<%=oTerms.getString(0, t)%>" CLASS="linksmall" TARGET="thesauriedit">modificar</A></TD>
          <TD CLASS="strip<%out.write(sStrip);%>" WIDTH="40px" ALIGN="right"><A HREF="term_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_parent=<%=oTerms.getString(0, t)%>" CLASS="linksmall" TARGET="thesauriedit">agregar</A></TD>
	  <TD CLASS="strip<%out.write(sStrip);%>" WIDTH="16px"><INPUT TYPE="checkbox" NAME="t_<%=oTerms.getString(0, t)%>"></TD>
<% if (bIsAdmin) { %>
	  <TD CLASS="strip<%out.write(sStrip);%>" WIDTH="16px"><A HREF="#" onclick="deleteTerm('<%=oTerms.getString(0, t)%>','<%=oTerms.getStringNull(14, t, "all")%>')"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0"></A></TD>
<% } %>
        </TR>
<% } %>      
      </TABLE>
    </FORM>
  </BODY>
</HTML>