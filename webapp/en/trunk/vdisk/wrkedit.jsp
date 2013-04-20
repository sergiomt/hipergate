<%@ page import="java.net.URLDecoder,java.sql.Connection,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.workareas.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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
  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");  
  String sLanguage = getNavigatorLanguage(request);
  String sHeadStrip= "";
  String gu_workarea = request.getParameter("gu_workarea")!=null ? request.getParameter("gu_workarea") : "";
  String n_workarea = request.getParameter("n_workarea");
  Integer id_domain = new Integer(request.getParameter("id_domain"));
  String n_domain = request.getParameter("n_domain");
  WorkArea oWrkA = null;
  Object  aDom[] = { id_domain } ;
  JDCConnection oConn; // Conexion con la BB.DD.
  DBSubset oGrps = null;
  DBSubset oApps = null;
  DBSubset oAppw = null;
  String sAppId;
  String sGrpVals = "\"\"";
  String sGrpTxts = "\"\"";
  int iGrps = 0;
  int iApps = 0;
  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
  
  oConn = GlobalDBBind.getConnection("wrkedit1");
  
  try {

    if (!bIsAdmin) {
      throw new SQLException("Administrator role is required for editing workareas", "28000", 28000);
    }   
      
    if (0!=gu_workarea.length()) {
      sHeadStrip = "Edit WorkArea";    
    
      oWrkA = new WorkArea(oConn, gu_workarea);
  
      oApps = new DBSubset(DB.k_apps + " a, " + DB.k_x_app_workarea + " w",
      			   "a." + DB.id_app + ",a." + DB.nm_app + ",w." + DB.gu_workarea + ",w." + DB.gu_admins + ",w." + DB.gu_powusers + ",w." + DB.gu_users + ",w." + DB.gu_guests + ",w." + DB.gu_other + ",w." + DB.path_files,
      			   "a." + DB.id_app + "=w." + DB.id_app + " AND w." + DB.gu_workarea + "=?", 32);

      oAppw = new DBSubset(DB.k_apps + " p", "p." + DB.id_app + ",p." + DB.nm_app + ",NULL,NULL,NULL,NULL,NULL,NULL,NULL",
                           "p." + DB.id_app + " NOT IN (SELECT x." + DB.id_app + " FROM " + DB.k_x_app_workarea + " x WHERE x." + DB.gu_workarea + "=?)", 32);

      oApps.load(oConn, new Object[]{gu_workarea});
      oAppw.load(oConn, new Object[]{gu_workarea});
      
      oApps.union(oAppw);
      oApps.sortBy(0);

      iApps = oApps.getRowCount();      
    }
    else {    
      sHeadStrip = "New WorkArea";
      oWrkA = new WorkArea();
      oApps = new DBSubset(DB.k_apps ,
    			   DB.id_app + "," + DB.nm_app + ",NULL,NULL,NULL,NULL,NULL,NULL,NULL",
      			   "1=1 ORDER BY 2", 10);
      iApps = oApps.load(oConn);
    }
    
    oGrps = new DBSubset(DB.k_acl_groups, DB.gu_acl_group + "," + DB.nm_acl_group,
      			 DB.id_domain + "=" + request.getParameter("id_domain") + " AND bo_active>=1 ORDER BY 2", 100);
    iGrps = oGrps.load(oConn);
      
    for (int g=0;g<iGrps; g++) {
      sGrpVals += ",\"" + oGrps.getString(0,g) + "\"";
      sGrpTxts += ",\"" + oGrps.getString(1,g) + "\"";
    }
    
    oConn.close("wrkedit1");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("wrkedit1");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DB Access Error&desc=" +
    			   e.getLocalizedMessage() + "&resume=_close"));
  }

  oConn = null;  
%>

  <!-- +-------------------------------+ -->
  <!-- | Edición de Areas de Trabajo   | -->
  <!-- | © KnowGate 2001-2008          | -->
  <!-- +-------------------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=sHeadStrip%></TITLE>  
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
   
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
  <!--
    function validate() {
      var frm = document.forms[0];
      var txt;
      
      if (frm.nm_workarea.value.length==0) {
        alert ("WorkArea name is mandatory");
        return false;
      }

      txt = frm.nm_workarea.value;
      if (txt.indexOf(";")>=0 || txt.indexOf(",")>=0 || txt.indexOf("&")>=0 || txt.indexOf("?")>=0 || txt.indexOf("$")>=0 || txt.indexOf("%")>=0 || txt.indexOf("¨")>=0 || txt.indexOf("`")>=0 || txt.indexOf(".")>=0 || txt.indexOf("*")>=0 || txt.indexOf(" ")>=0) {
        alert ("WorkArea name contains invalid characters");
        return false;        
      }
      else
        frm.nm_workarea.value = txt.toLowerCase();
           
      return true;
    }
    
    // --------------------------------------------------------
    
    function setCombos() {
      var frm = document.forms[0];
      var val = Array(<%=sGrpVals%>);
      var txt = Array(<%=sGrpTxts%>);
      var len = txt.length;
      var grp;
<%	
	for (int c=0; c<iApps; c++) {
	    sAppId = String.valueOf(oApps.getInt(0,c));
	
	    out.write ("      for (grp=0; grp<len; grp++) { \n");
	    out.write ("        comboPush(frm.a" + sAppId + "admins,txt[grp],val[grp]);\n");
	    out.write ("        comboPush(frm.a" + sAppId + "powusers,txt[grp],val[grp]);\n");
	    out.write ("        comboPush(frm.a" + sAppId + "users,txt[grp],val[grp]);\n");
	    out.write ("        comboPush(frm.a" + sAppId + "guests,txt[grp],val[grp]);\n");
	    out.write ("      }\n\n");
	  
	    if (null!=oApps.get(2,c)) {      	    
              out.write ("      setCombo(frm.a" + sAppId + "admins,'" + oApps.getStringNull(3,c,"") + "');\n");
              out.write ("      setCombo(frm.a" + sAppId + "powusers,'" + oApps.getStringNull(4,c,"") + "');\n");
              out.write ("      setCombo(frm.a" + sAppId + "users,'" + oApps.getStringNull(5,c,"") + "');\n");
              out.write ("      setCombo(frm.a" + sAppId + "guests,'" + oApps.getStringNull(6,c,"") + "');\n");
            } // fi(gu_workarea)
        }
        // next (c)
%>
    }
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="yes" TOPMARGIN="4" MARGINHEIGHT="4" onLoad="setCombos()">
   <TABLE><TR><TD WIDTH="100%" CLASS="striptitle"><FONT CLASS="title1">Active Applications for WorkArea</FONT></TD></TR></TABLE>  

  <TABLE WIDTH="100%"><TR><TD CLASS="strip1"><FONT CLASS="title1"><%=sHeadStrip + (null!=n_workarea ? " " + n_workarea : "")%> for domain &nbsp;<I><%=n_domain%></I></FONT></TD></TR></TABLE>
  <FORM NAME="wrkedit" ENCTYPE="multipart/form-data" METHOD="post" ACTION="wrkedit_store.jsp" onsubmit="return validate();">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain.toString()%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="activated" VALUE="1">
    <INPUT TYPE="hidden" NAME="is_new" VALUE="<%=(request.getParameter("gu_workarea")==null ? "1" : "0")%>">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="nm_workarea" MAXLENGTH="32" SIZE="32" STYLE="text-transform:lowercase" VALUE="<%=(null!=n_workarea ? n_workarea : "")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Logotype:</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="file" SIZE="32" NAME="path_logo"></TD>
          </TR>
<%
	String sDefWrkArGet = request.getRequestURI();
	sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
	sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
	sDefWrkArGet = sDefWrkArGet + "/workareas";

 	     if (oWrkA!=null)
               if (!oWrkA.isNull(DB.path_logo)) {
	         out.write("          <TR VALIGN=\"middle\">\n");
	         out.write("            <TD VALIGN=\"middle\" ALIGN=\"right\" WIDTH=\"90\"></TD>\n");
	         out.write("            <TD VALIGN=\"middle\" ALIGN=\"left\" WIDTH=\"370\">\n");
	         out.write("	          <A HREF=\"" + Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasget", sDefWrkArGet) + "/" + oWrkA.getString(DB.gu_workarea) + "/" + oWrkA.getString(DB.path_logo) + "\" target=\"_blank\"><IMG SRC=\"../images/images/viewtxt.gif\" BORDER=\"0\"></A>&nbsp;");
	         out.write("	          <A HREF=\"" + Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasget", sDefWrkArGet) + "/" + oWrkA.getString(DB.gu_workarea) + "/" + oWrkA.getString(DB.path_logo) + "\" target=\"_blank\" CLASS=\"linkplain\">View logotype</A>");
	         out.write("	          &nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE=\"checkbox\" NAME=\"erase\" VALUE=\"1\">&nbsp;<FONT CLASS=\"textplain\">Eliminar logotipo</FONT>\n");
	         out.write("          </TD>\n");
	         out.write("          </TR>\n");
               } // fi (path_logo!=null)
%>
<% if (request.getParameter("gu_workarea")==null) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="checkbox" NAME="load_lookups" VALUE="1" CHECKED>&nbsp;<FONT CLASS="formplain">Load default values for lookup tables.</FONT></TD>
          </TR>
<% } %>          
          <TR>
            <TD COLSPAN="2">
      	      <TABLE CELLSPACING="1" CELLPADDING="0">
      	        <TR>
      	          <TD CLASS="tableheader">&nbsp;</TD>
          	  <TD CLASS="tableheader">&nbsp;<B>Application</B></TD>
      	          <TD CLASS="tableheader" COLSPAN="2"><B>Associated Permissions Groups</B></TD>
	        </TR>
      	        <% for (int a=0; a<iApps; a++) {
      	             sAppId = String.valueOf(oApps.getInt(0,a));
      	        %>
        	<TR>
                  <TD CLASS="tabletd" ROWSPAN="4"><INPUT TYPE="checkbox" NAME="c<%=sAppId%>" VALUE="1" <%=oApps.get(2,a)!=null ? "CHECKED" : ""%>></TD>
                  <TD CLASS="tabletd" ROWSPAN="4"><FONT CLASS="textplain">&nbsp;<B><%=oApps.getString(1,a)%></B>&nbsp;&nbsp;&nbsp;</FONT></TD>
          	  <TD CLASS="tabletr">&nbsp;Administrators</TD>
          	  <TD CLASS="tabletr">&nbsp;Power Users</TD>
                </TR>
                <TR>
                  <TD CLASS="tabletd"><SELECT CLASS="selectsmall" NAME="a<%=sAppId%>admins"></SELECT></TD>
                  <TD CLASS="tabletd"><SELECT CLASS="selectsmall" NAME="a<%=sAppId%>powusers"></SELECT></TD>
                </TR>
        	<TR>
          	  <TD CLASS="tabletr">&nbsp;Users</TD>                    
          	  <TD CLASS="tabletr">&nbsp;Guests</TD>
                </TR>
                <TR>
                  <TD CLASS="tabletd"><SELECT CLASS="selectsmall" NAME="a<%=sAppId%>users"></SELECT></TD>
                  <TD CLASS="tabletd"><SELECT CLASS="selectsmall" NAME="a<%=sAppId%>guests"></SELECT></TD>
                </TR>
      	        <TR>
          	  <TD CLASS="tableheader" COLSPAN="4"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="4" BORDER="0"></TD>
	        </TR>
                <% } // next (a) %>
              </TABLE>
            </TD>
          </TR>          
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
    	      <BR>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	    
          </TR>           
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>
