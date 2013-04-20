<%@ page import="java.rmi.RemoteException,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.cache.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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

  final int Sales=17;
  final int CollaborativeTools=17;

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sDomainId = getCookie(request,"domainid","");
  String sDomainNm = getCookie(request,"domainnm","");   
  String sWorkArea = getCookie(request,"workarea", "");
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

  String id_language = request.getParameter("id_language");
  String tp_control = request.getParameter("tp_control");
  String nm_control = request.getParameter("nm_control");
  String nm_coding = request.getParameter("nm_coding");

  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);  
  String sQryStr = "?nm_table=k_duties_lookup&id_language=" + id_language + "&id_section=nm_resource&tp_control=" + tp_control + "&nm_control=" + nm_control + "&nm_coding=" + nm_coding + "&id_form=" + nullif(request.getParameter("id_form"),"0");
  String sTr,sGu;
  
%>
<!-- +-----------------------+ -->
<!-- | Listado de Recurso    | -->
<!-- | KnowGate 2002-2008    | -->
<!-- +-----------------------+ -->
<HTML>
  <HEAD>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/combobox.js"></SCRIPT>    
    <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/findit.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');

<% if (bIsAdmin) { %>
      function viewUser(gu) {
	      self.open ("../vdisk/usredit.jsp?id_domain=<%=sDomainId%>&n_domain=" + escape("<%=sDomainNm%>") + "&gu_user=" + gu, "edituser", "directories=no,toolbar=no,menubar=no,width=600,height=600");
      }
<% } %>

<% if ((iAppMask & (1<<Sales))!=0) { %>
      function viewContact(gu) {
	      self.open ("../crm/contact_edit.jsp?id_domain=<%=sDomainId%>&n_domain=" + escape("<%=sDomainNm%>") + "&gu_contact=" + gu, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));
      }
      function viewCompany(gu,tr) {
	      self.open ("../crm/company_edit.jsp?id_domain=<%=sDomainId%>&n_domain=" + escape("<%=sDomainNm%>") + "&gu_company=" + gu + "&n_company=" + escape(tr) + "&gu_workarea=<%=sWorkArea%>", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=" + String(screen.height-80));
      }
<% } %>

<% if ((iAppMask & (1<<CollaborativeTools))!=0) { %>
      function viewFellow(gu) {
	      self.open ("../addrbook/fellow_edit.jsp?id_domain=<%=sDomainId%>&n_domain=" + escape("<%=sDomainNm%>") + "&gu_fellow=" + gu + "&gu_workarea=<%=sWorkArea%>", "editfellow", "directories=no,toolbar=no,menubar=no,width=640,height=" + (screen.height<=600 ? "520" : "600"));
      }
<% } %>
    
      function choose(vlstr,nmstr) {
        var prnt = window.parent;
	      var frm = prnt.opener.document.forms[<%=nullif(request.getParameter("id_form"),"0")%>];
	      var opt;	
        <% if (tp_control.equals("1"))
             // El control de entrada es de tipo TEXT
             out.write("	frm." + nm_control + ".value = nmstr;\n");           
           else {
             // El control de entrada es de tipo SELECT
             out.write("if (-1==comboIndexOf(frm." + nm_control + ",vlstr)) {\n");             
             out.write("            opt = prnt.opener.document.createElement(\"OPTION\");\n");
             out.write("            opt.text = nmstr;\n");
             out.write("            opt.value = vlstr;\n");
             out.write("            frm." + nm_control + ".options.add(opt);\n");                          
             out.write("        } // fi(comboIndexOf())\n");
             out.write("        setCombo(frm." + nm_control + ",nmstr);\n");
           }           
           out.write("        frm." + nm_coding + ".value = vlstr;\n");
        %>        
        prnt.close();
      }      
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  SCROLL="yes" TOPMARGIN="4" MARGINHEIGHT="4" LEFTMARGIN="4" RIGHTMARGIN="4">
    <FORM METHOD="POST" ACTION="../common/lookup_delete.jsp<%=sQryStr%>">
    <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<%  
  int iOdPos = 0;
  JDCConnection oConn = null;
  Object aParams[] = { sWorkArea };
  DBSubset oLookup;
  int iLookup = -1;
  String sVlResourceSelect = "(SELECT "+DB.vl_lookup+" FROM "+DB.k_duties_lookup+" WHERE "+DB.gu_owner + "=? AND " + DB.id_section + "='nm_resource')";
  DBKeySet oUsers,oFellows,oContacts,oCompanies,oSuppliers;
  oUsers=oFellows=oContacts=oCompanies=oSuppliers=null;
  
  try {

    oConn = GlobalDBBind.getConnection("resource_lookup_mid");

    oUsers = new DBKeySet(DB.k_users, DB.gu_user, DB.gu_workarea + "=? AND " + DB.gu_user + " IN " + sVlResourceSelect, iLookup);
    oFellows = new DBKeySet(DB.k_fellows, DB.gu_fellow, DB.gu_workarea + "=? AND " + DB.gu_fellow + " IN " + sVlResourceSelect, iLookup);
    oContacts = new DBKeySet(DB.k_contacts, DB.gu_contact, DB.gu_workarea + "=? AND " + DB.gu_contact + " IN " + sVlResourceSelect, iLookup);
    oCompanies = new DBKeySet(DB.k_companies, DB.gu_company, DB.gu_workarea + "=? AND " + DB.gu_company + " IN " + sVlResourceSelect, iLookup);

    oLookup = GlobalCacheClient.getDBSubset("k_duties_lookup.nm_resource#"  + id_language + "[" + sWorkArea + "]");
    
    if (null==oLookup) {

      oLookup = new DBSubset (DB.k_duties_lookup,
       			      DB.vl_lookup + "," + DB.tr_ + id_language + "," + DB.pg_lookup,
      			      DB.gu_owner + "=? AND " + DB.id_section + "='nm_resource' ORDER BY 2", 50);
      iLookup = oLookup.load (oConn, aParams);

      GlobalCacheClient.putDBSubset(DB.k_duties_lookup, "k_duties_lookup.nm_resource#" + id_language + "[" + sWorkArea + "]", oLookup); 

    } // fi(oLookup)
    else
      iLookup = oLookup.getRowCount();

    if ((iAppMask & (1<<Sales))!=0) {
      oContacts.load(oConn, new Object[]{sWorkArea,sWorkArea});
      oCompanies.load(oConn, new Object[]{sWorkArea,sWorkArea});
    }
    if ((iAppMask & (1<<CollaborativeTools))!=0) {
      oFellows.load(oConn, new Object[]{sWorkArea,sWorkArea});
    }
    if (bIsAdmin) {
      oUsers.load(oConn, new Object[]{sWorkArea,sWorkArea});
    }
    
    oConn.close("resource_lookup_mid");
    oConn = null;
                    
    for (iOdPos=0; iOdPos<iLookup; iOdPos++) {
      
      sGu = oLookup.getString(0,iOdPos);
      sTr = oLookup.getStringNull(1,iOdPos,sGu);
      if (sTr.length()==0) sTr = oLookup.getString(0,iOdPos);
      
      out.write ("      <TR><TD WIDTH=\"16\"><INPUT TYPE=\"checkbox\" NAME=\"chkbox" + String.valueOf(iOdPos) + "\" VALUE=\"" + String.valueOf(oLookup.getInt(2,iOdPos)) + "\"></TD>");
      out.write ("<TD CLASS=\"strip" + String.valueOf(iOdPos%2+1) + "\"><A HREF='javascript:choose(\"" + sGu + "\",\""+ sTr + "\")' CLASS='linkplain'>" + sTr + "<A></TD><TD CLASS=\"strip" + String.valueOf(iOdPos%2+1) + "\">");
      
      if ((iAppMask & (1<<Sales))!=0 && oContacts.contains(sGu)) {
			  out.write ("<A HREF=# onclick=\"viewContact('"+sGu+"')\"><IMG SRC=\"../images/images/viewtxt.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"View Contact\"></A>");
      } else if ((iAppMask & (1<<Sales))!=0 && oCompanies.contains(sGu)) {
			  out.write ("<A HREF=# onclick=\"viewCompany('"+sGu+"','"+sTr.replace((char)39,'´')+"')\"><IMG SRC=\"../images/images/viewtxt.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"View Company\"></A>");
      } else if ((iAppMask & (1<<CollaborativeTools))!=0 && oFellows.contains(sGu)) {
			  out.write ("<A HREF=# onclick=\"viewFellow('"+sGu+"')\"><IMG SRC=\"../images/images/viewtxt.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"View Employee\"></A>");
      } else if (bIsAdmin && oUsers.contains(sGu)) {
			  out.write ("<A HREF=# onclick=\"viewUser('"+sGu+"')\"><IMG SRC=\"../images/images/viewtxt.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"View User\"></A>");
      }      
      out.write ("</TD></TR>\n");
    } // next (i)
    
  }
  catch (SQLException e) {
    if (null!=oConn)
      if (!oConn.isClosed()) {
        oConn.close("resource_lookup_mid");
        oConn = null;
      }        
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  catch (RemoteException r) {
    if (null!=oConn)
      if (!oConn.isClosed()) {
        oConn.close("resource_lookup_mid");
        oConn = null;
      }        
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=AppServer Access Error&desc=" + r.getMessage() + "&resume=_back"));
  }
%>
    </TABLE>
    <INPUT TYPE="hidden" NAME="chkcount" VALUE="<%=iOdPos%>">
    </FORM>
  </BODY>
</HTML>
