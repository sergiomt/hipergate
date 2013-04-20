<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.sql.ResultSet,java.sql.PreparedStatement,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%
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
  String sSkin = getCookie(request, "skin", "default");
  String sUserId = getCookie(request, "userid", "");   
  String sDomainId = getCookie(request, "domainid", "");
  String sLanguage = getNavigatorLanguage(request);
  String sParentId; 
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Select Category</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>   
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function dipuClick() {
       var diputree = window.document.diputree;
                 
       // event
       var docElement = "#/1";
       var pEvent = "#xpointer(hasevent/*)";
       var event = diputree.lookup (docElement, pEvent);

       // source
       var pSourceURI = diputree.lookup(event,"#xpointer(hassource/uri/s)");
       var pSource = diputree.getValue( pSourceURI );
       var source = diputree.lookup(docElement, pSource);

       // destination category identifier
       var pDestination = diputree.lookup(source,"#xpointer(haslink/link/hasdestination/target/s)");
       var id_category = diputree.getValue(pDestination);

       // category text
       var pText = diputree.lookup(source,"#xpointer(lt)");
       var tr_category = diputree.getValue( pText );

       var pLocation = diputree.lookup(event,"#xpointer(haslocation/*)");
       
       // solo cargar los hijos cuando se pincha en el handle 
       if ("handle"==diputree.getName(pLocation)) {      
	 // handle state
         var pState = diputree.lookup(source,"#xpointer(hasstate)");
	 	 
	 if ("closed"==diputree.getName(pState+"/1")) {
           
           // si el id de la categoria empieza por una almohadilla
           // entonces es que sus hijos ya han sido cargados
           if ('#'!=id_category.charAt(0)) {
             if (navigator.appName=="Microsoft Internet Explorer")
               window.document.body.style.cursor = "wait";
         
             window.status = "Cargando...";
             diputree.loadFromURI (source, "pickchilds.jsp?Parent=" + id_category + "&Label=" + escape(tr_category) + "&Lang=" + getUserLanguage() + "&Skin=" + getCookie("skin") +  "&Uid=" + getCookie("userid"));
             window.status = "";
                          
             if (navigator.appName=="Microsoft Internet Explorer")
               window.document.body.style.cursor = "auto";
           } // endif (loaded)
         } // endif (closed)
       } // endif (handle)       
    
       document.forms[0].id_selected.value = ('#'!=id_category.charAt(0) ? id_category : id_category.substr(1));
       document.forms[0].tr_selected.value = tr_category;
    }
      
    function selectNode() {
      var q = '"';
      var opn = window.opener.document.forms[0];
      var frm = document.forms[0];                  
      var iid = getURLParam("inputid");                  
      var itr = getURLParam("inputtr");      
            
      if (null!=iid)
        eval ("opn." + iid + ".value=" + q + frm.id_selected.value + q + ";");
      if (null!=itr)
        eval ("opn." + itr + ".value=" + q + frm.tr_selected.value + q + ";");
      
      window.close();
    }
    
  //-->
  </SCRIPT>
</HEAD>

<BODY  TOPMARGIN="4" MARGINHEIGHT="4" WIDTH="100%">
  <FORM>
    <TABLE BORDER="2" CELLSPACING="0" CELLPADDING="0">
      <TR>
        <TD>
          <APPLET NAME="diputree" CODE="diputree.class" ARCHIVE="diputree3.jar" CODEBASE="../applets" WIDTH="300" HEIGHT="350" MAYSCRIPT>

<%    if (sDomainId.equals("1024")) { sParentId = ""; %>
	<PARAM NAME="xmlsource" VALUE="pickchilds.jsp?Skin=<%=sSkin%>&Lang=<%=sLanguage%>&Uid=<%=sUserId%>">
<%    } else if (sDomainId.equals("1025")) { sParentId = ""; %>
	<PARAM NAME="xmlsource" VALUE="pickchilds.jsp?Skin=<%=sSkin%>&Lang=<%=sLanguage%>&Parent=ecd80abbb4b24668aa75d45a58c830a6&Label=root&Uid=<%=sUserId%>">
<%    } else {
	JDCConnection oConn = GlobalDBBind.getConnection("pickdipu");
	PreparedStatement oStmt = oConn.prepareStatement("SELECT " +  DB.gu_category + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	oStmt.setString(1,sUserId);	
	ResultSet oRSet = oStmt.executeQuery();
	if (oRSet.next())
	  sParentId = oRSet.getString(1);
	else
	  sParentId = "000000000000000000000000000000000";
	oRSet.close();
	oRSet = null;
	oStmt.close();
	oStmt = null;
	oConn.close("pickdipu");
	oConn = null;	
	}
%>
            <PARAM NAME="xmlsource" VALUE="pickchilds.jsp?Skin=<%=sSkin%>&Lang=<%=sLanguage%>&Parent=<%=sParentId%>&Label=root&Uid=<%=sUserId%>">
          </APPLET>
        </TD>
      </TR>
    </TABLE>
    <TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0"><TR><TD HEIGHT="4"></TD></TR></TABLE>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE CLASS="formfront" CELLSPACING="2" CELLPADDING="2" WIDTH="300">
          <TR>
            <TD ALIGN="right">
    	      <INPUT TYPE="hidden" NAME="id_selected">
    	      <INPUT TYPE="text" NAME="tr_selected" MAXLENGTH="30" SIZE="30">    
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right">
              <INPUT TYPE="button" ACCESSKEY="o" VALUE="Actions" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+o" onClick="selectNode()">&nbsp;
              <INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onClick="window.close()">
            </TD>
          </TR>
        </TABLE></TD></TR></TABLE><A HREF="../common/nojava.html" TARGET="_blank" CLASS="linksmall" TITLE="Click here if you have problems for displaying the Java applet">Problems displaying this page?</A></FORM>
</BODY>

</HTML>
