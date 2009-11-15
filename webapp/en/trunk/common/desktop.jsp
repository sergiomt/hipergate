<%@ page import="java.util.Properties,java.io.IOException,java.io.File,javax.portlet.GenericPortlet,javax.portlet.PortletException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.ResultSet,java.sql.CallableStatement,java.sql.Types,org.jibx.runtime.JiBXException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.debug.StackTraceUtil,com.knowgate.debug.DebugFile,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipermail.MailAccount,com.knowgate.dataxslt.StylesheetCache,com.knowgate.acl.*,com.knowgate.http.portlets.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña 107 1º2 28050 Madrid (Spain)

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
%><%!
  public static boolean isActive(String sPortletName, int iAppMask) {

    final int BugTracker=10,DutyManager=11,ProjectManager=12,Mailwire=13,WebBuilder=14,VirtualDisk=15,Sales=16,CollaborativeTools=17,MarketingTools=18,Directory=19,Shop=20,Hipermail=21,Config=30;
  
    if (sPortletName.endsWith("CalendarTab"))
      return ((iAppMask & (1<<CollaborativeTools))!=0);
      
    if (sPortletName.endsWith("CallsTab"))
      return ((iAppMask & (1<<CollaborativeTools))!=0);

    if (sPortletName.endsWith("RecentContactsTab"))
      return ((iAppMask & (1<<Sales))!=0);

    if (sPortletName.endsWith("NewMail"))
      return ((iAppMask & (1<<Hipermail))!=0);
    
    return true;
  }
%><%
  if (autenticateSession (GlobalDBBind, request, response)<0) return;

  try {
    int iDomain = Integer.parseInt(getCookie (request, "domainid", null));
  }
  catch (NumberFormatException nfe) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Invalid Domain&desc=The session cookie could not be readed please ensure that cookies are enabled at your browser&resume=_back")); 
    return;
  }  
  
  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
    
  String id_domain = getCookie(request, "domainid", "0");
  String n_domain = getCookie(request, "domainnm", "");
  String gu_user = getCookie(request, "userid", "");
  String gu_workarea = getCookie(request, "workarea", "");
  MailAccount oMacc = null;

  DBSubset oApps;
  Statement oStmt;
  ResultSet oRSet;
  int iApps = 0;
  Object aWrkA[] = { gu_workarea };
  JDCConnection oConn = null;
  boolean AccessRights[] = null;
  String sGrp;
  String sGrps = null;
  String sApps = "";
  
  boolean bShowPortlets = !id_domain.equals("1024");
  boolean bIsGuest = true;
  
  DBSubset oLeft = null;
  DBSubset oRight = null;
  
  try {
    oConn = GlobalDBBind.getConnection("desktop");
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
	  oMacc = MailAccount.forUser(oConn, gu_user);
	  if (null!=oMacc) if (oMacc.isNull(DB.incoming_server)) oMacc = null;
  }
  catch (SQLException e) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=hipergate: Impossible to get connection to database&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }

  if (null==oConn) return;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  try {
    // Recuperar las aplicaciones que son accesibles desde el area de trabajo
    // que ha especificado el usuario en la peticion de login.
    oApps = new DBSubset("k_x_app_workarea", "*", DB.gu_workarea + "=?", 16);
    iApps = oApps.load(oConn, aWrkA, 0);
    
    if (iApps>0) {

      AccessRights = new boolean[iApps];

      oStmt = oConn.createStatement();
      
      for (int a=0; a<iApps; a++) {
        sGrps = null;
        for (int c=2; c<6; c++) {
          sGrp = oApps.getStringNull(c,a,null);
          if (sGrp!=null)
            if (sGrps==null)
              sGrps = "'" + sGrp + "'";
            else
              sGrps += ",'" + sGrp + "'";
        } // next (c)
      
        // Verificar si el usuario pertenece a alguno de los grupos de permisos  

        if (sGrps!=null) {

          if (DebugFile.trace)
            DebugFile.writeln ("Statement.executeQuery(SELECT NULL FROM " + DB.k_x_group_user + " WHERE " + DB.gu_user + "='" + gu_user + "' AND " +  DB.gu_acl_group + " IN (" + sGrps + "))");
            
          oRSet = oStmt.executeQuery("SELECT NULL FROM " + DB.k_x_group_user + " WHERE " + DB.gu_user + "='" + gu_user + "' AND " +  DB.gu_acl_group + " IN (" + sGrps + ")");
	        AccessRights[a] = oRSet.next();
	        oRSet.close();
        } 
        else
	        AccessRights[a] = false;
	      // fi (sGrps)
	
	      if (AccessRights[a]) {
	        sApps += "," + String.valueOf(oApps.getInt(0,a));
	      }
      } // next (a)

      oStmt.close();
    } // fi (iApps)
    
    if (bShowPortlets) {
      bShowPortlets = GlobalDBBind.exists(oConn, DB.k_x_portlet_user, "U");
    
      if (bShowPortlets) {
        oLeft = GlobalCacheClient.getDBSubset("["+gu_user+",left]");
        if (null==oLeft) {
          oLeft = new DBSubset(DB.k_x_portlet_user, "nm_portlet,od_position,id_state,dt_modified,nm_template", "nm_page='desktop.jsp' AND gu_user=? AND gu_workarea=? AND nm_zone=? ORDER BY 2", 5);
          oLeft.load (oConn, new Object[]{gu_user,gu_workarea,"left"});
          GlobalCacheClient.putDBSubset(DB.k_x_portlet_user, "["+gu_user+",left]", oLeft);
        }
        
        oRight = GlobalCacheClient.getDBSubset("["+gu_user+",right]");
        if (null==oRight) {
          oRight = new DBSubset(DB.k_x_portlet_user, "nm_portlet,od_position,id_state,dt_modified,nm_template", "nm_page='desktop.jsp' AND gu_user=? AND gu_workarea=? AND nm_zone=? ORDER BY 2", 5);
          oRight.load (oConn, new Object[]{gu_user,gu_workarea,"right"});
          GlobalCacheClient.putDBSubset(DB.k_x_portlet_user, "["+gu_user+",right]", oRight);
        }
        
        bShowPortlets = ((oLeft.getRowCount()>0) || (oRight.getRowCount()>0));
      }
    } // fi (bShowPortlets)
    
    oConn.close("desktop");      
  }
  catch (Exception e) {    
    oApps = null;
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("desktop");
    oConn = null;    
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));    
  }
  
  if (null==oConn) return;
  oConn = null;  

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <META NAME="robots" CONTENT="noindex,nofollow">
  <TITLE>hipergate :: Main Menu</TITLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
  <!--

    // ------------------------------------------------------
      
    function modifyMeeting(gu) {
      window.open("../addrbook/meeting_edit_f.htm?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid") + "&gu_meeting=" + gu, null, "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
    }

    // ------------------------------------------------------

    function viewContact(id) {
      window.open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));
    }	

    // ------------------------------------------------------

    function modifyContact(id) {
      window.open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));
    }	

    // ----------------------------------------------------

    function modifyCompany(id,nm) {
      window.open ("../crm/company_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_company=" + id + "&n_company=" + escape(nm) + "&gu_workarea=<%=gu_workarea%>", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=" + String(screen.height-80));
    }	

    // ----------------------------------------------------

    function createContact() {
<%    if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<%    } else { %>
      self.open ("../crm/contact_new_f.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>", null, "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=" + (screen.height<=600 ? "520" : "600"));
<%    } %>
    } // createContact()

    // ----------------------------------------------------

    function newOportunity() {
<%    if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<%    } else { %>
	  self.open ("oportunity_new.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "newoportunity", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));	  
<%    } %>
    } // newOportunity()

    // ----------------------------------------------------

    function searchContact() {
      var frm = document.forms[0];
      var nmc = frm.full_name.value;

      if (nmc.length==0) {
        alert ("Type name or surname of individual to find");
        return false;
      }  
      
      if (nmc.indexOf("'")>0 || nmc.indexOf('"')>0 || nmc.indexOf("?")>0 || nmc.indexOf("%")>0 || nmc.indexOf("*")>0 || nmc.indexOf("&")>0 || nmc.indexOf("/")>0) {
	alert ("Name contains invalid characters");
	return false;
      }
      window.location = "../crm/contact_listing_f.jsp?selected=2&subselected=1&field=tx_name&find=" + escape(nmc);
    }

    // ----------------------------------------------------

    function reportBug() {
<%    if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<%    } else { %>
        self.open("../projtrack/bug_new.jsp",null,"menubar=no,toolbar=no,width=700,height=520");
<%    } %>
    }

    // ----------------------------------------------------

    function editBug(guBug) {
      self.open("../projtrack/bug_edit.jsp?gu_bug=" + guBug, guBug, "width=780,height=480");
    }  

    // ----------------------------------------------------

    function readMessage(grp,id) {	  
      window.open ("../forums/msg_read.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&gu_newsgrp=" + grp + "&nm_newsgrp=&gu_msg=" + id, null);
    }

    // ----------------------------------------------------

    setCookie ("apps", "<%=sApps%>", null);
  //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="0" MARGINHEIGHT="0">
<%@ include file="tabmenu.jspf" %>
<FORM>
  <TABLE SUMMARY="Page Title Strip"><TR><TD WIDTH="<% out.write(String.valueOf(iTabWidth*iActive)); %>" CLASS="striptitle"><FONT CLASS="title1">Main Page</FONT></TD></TR></TABLE>
  <TABLE>
    <TR>
<% if (bShowPortlets) {
     
     try {
     
%><%@ include file="../methods/globalportletconfig.jspf" %><%

     Properties EnvPros = new Properties();
    
     EnvPros.put("domain", id_domain);
     EnvPros.put("workarea", gu_workarea);
     EnvPros.put("user", gu_user);
     EnvPros.put("language", sLanguage);
     EnvPros.put("skin", sSkin);
     EnvPros.put("storage", Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage"));
     if (oMacc!=null) EnvPros.put("account", oMacc.getString(DB.gu_account)); else EnvPros.put("account", "");
     
     String sRealPath = request.getRealPath(request.getServletPath());
     	    sRealPath = sRealPath.substring(0, sRealPath.lastIndexOf(File.separator));
            sRealPath = sRealPath.substring(0, sRealPath.lastIndexOf(File.separator)+1);
     
     HipergateRenderRequest  portletRequest = new com.knowgate.http.portlets.HipergateRenderRequest(request);

     portletRequest.setProperties (EnvPros);

     HipergateRenderResponse portletResponse = new HipergateRenderResponse(response);

     Class oPorletCls;
     GenericPortlet oPorlet;

     out.write("<TD VALIGN=\"top\">\n<!-- Left Column Portlets -->\n");
     out.flush(); // Do not remove this flush() statement or else page is not properly painted

     EnvPros.put("zone", "left");
     
     for (int l=0; l<oLeft.getRowCount(); l++) {

	if (isActive(oLeft.getString(0,l), iAppMask)) {
          EnvPros.put("template", sRealPath+"includes"+File.separator+oLeft.getString(4,l));

	  portletRequest.setWindowState(oLeft.getString(2,l));

	  portletRequest.setAttribute("modified", oLeft.getDate(3,l));
	
	  try {
	    if (!oLeft.getString(0,l).equals("com.knowgate.http.portlets.NewMail") || oMacc!=null) {
	      oPorletCls = Class.forName (oLeft.getString(0,l));
	      oPorlet = (GenericPortlet) oPorletCls.newInstance();
 	      oPorlet.init(GlobalPortletConfig); 	    
 	      oPorlet.render(portletRequest, portletResponse); 	    
	    }
	  } catch (ClassNotFoundException cnfe) {
	    out.write("ClassNotFoundException "+oLeft.getString(0,l));
	  }
	  catch (PortletException pe) {
	    if (pe.getCause()==null)
	      out.write(StylesheetCache.transform (sRealPath+"includes"+File.separator+"home_exception.xsl", "<?xml version=\"1.0\" encoding=\"UTF-8\"?><exception><nm_class>"+oLeft.getString(0,l)+"</nm_class><tx_message>"+pe.getClass().getName()+" "+pe.getMessage()+"</tx_message></exception>", EnvPros));
	    else
	      out.write(StylesheetCache.transform (sRealPath+"includes"+File.separator+"home_exception.xsl", "<?xml version=\"1.0\" encoding=\"UTF-8\"?><exception><nm_class>"+oLeft.getString(0,l)+"</nm_class><tx_message>"+pe.getCause().getClass().getName()+" "+pe.getMessage()+"</tx_message></exception>", EnvPros));
	  }
	} // fi (isActive())
     } // next
     
     out.write("</TD>\n<TD VALIGN=\"top\">\n<!-- Right Column Portlets -->\n");
     out.flush(); // Do not remove this flush() statement or else page is not properly painted

     EnvPros.put("zone", "right");
     
     for (int r=0; r<oRight.getRowCount(); r++) {

	if (isActive(oRight.getString(0,r), iAppMask)) {

          EnvPros.put("template", sRealPath+"includes"+File.separator+oRight.getString(4,r));

	  portletRequest.setWindowState(oRight.getString(2,r));

	  portletRequest.setAttribute("modified", oRight.getDate(3,r));
	
	  try {
	    if (!oRight.getString(0,r).equals("com.knowgate.http.portlets.NewMail") || oMacc!=null) {
	      oPorletCls = Class.forName (oRight.getString(0,r));
	      oPorlet = (GenericPortlet) oPorletCls.newInstance();	  
 	      oPorlet.init(GlobalPortletConfig);
 	      oPorlet.render(portletRequest, portletResponse);
	    }
	  }
	  catch (ClassNotFoundException cnfe) {
	    out.write("ClassNotFoundException "+oRight.getString(0,r));
	  }
	  catch (PortletException pe) {
	    if (pe.getCause()==null)
	      out.write(StylesheetCache.transform (sRealPath+"includes"+File.separator+"home_exception.xsl", "<?xml version=\"1.0\" encoding=\"UTF-8\"?><exception><nm_class>"+oRight.getString(0,r)+"</nm_class><tx_message>"+pe.getClass().getName()+" "+pe.getMessage()+"</tx_message></exception>", EnvPros));
	    else
	      out.write(StylesheetCache.transform (sRealPath+"includes"+File.separator+"home_exception.xsl", "<?xml version=\"1.0\" encoding=\"UTF-8\"?><exception><nm_class>"+oRight.getString(0,r)+"</nm_class><tx_message>"+pe.getCause().getClass().getName()+" "+pe.getMessage()+"</tx_message></exception>", EnvPros));
	  }
	  
	} // fi (isActive())
     } // next

     out.write("</TD>");

     } catch (Exception e) {
       out.write(e.getClass().getName()+" "+e.getMessage()+"<BR>");
       out.write(Gadgets.replace(StackTraceUtil.getStackTrace(e),"\n","<BR>"));
     }
} else { %>
      <TD>
        <IMG SRC="../images/images/orangefish2.jpg"  BORDER="0">
      </TD>
      <TD WIDTH="20px"></TD>
      <TD VALIGN="top" WIDTH="240px">
        <FONT SIZE="5" FACE="Arial,Helvetica,sans-serif" COLOR="#EAE5E1"><B><I>Welcome</I></B></FONT>        
        <BR>
        <FONT FACE="Verdana" SIZE="1" COLOR="#404040">&nbsp;&nbsp;Welcome to hipergate, from the above menu you can navigate  through the different applications of this suite.<BR>On each module you will find a welcome page with search functionalities and quick links to access to the most common tasks of hipergate.<BR></FONT>
	<BR>
	<IMG SRC="../images/images/bienvenido_linea.gif" WIDTH="214" HEIGHT="15" BORDER="0">
      </TD>
<% } %>
    </TR>
  </TABLE>
  <TABLE>
    <TR><TD WIDTH="<%=iTabWidth*iActive%>" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  </TABLE>
<% if (!id_domain.equals("1024")) { %>  
  <A HREF="desktop_custom.jsp" CLASS="linkplain">Customize this page</A>
<% } %>
  </FORM>
</BODY>
</HTML>
